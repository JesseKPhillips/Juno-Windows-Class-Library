/**
 * Provides a _streaming API for reading and writing XML data.
 *
 * Copyright: (c) 2008 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.xml.streaming;

private import juno.base.core,
  juno.base.text,
  juno.base.string,
  juno.base.native,
  juno.locale.convert,
  juno.com.core,
  juno.xml.core;

private import std.stream : Stream, File, FileMode;
private import std.base64;

debug private import std.stdio;

extern(Windows):

enum XmlReaderProperty : uint {
  MultiLanguage,
  ConformanceLevel,
  RandomAccess,
  XmlResolver,
  DtdProcessing,
  ReadState,
  MaxElementLength,
  MaxEntityExpansion
}

enum XmlWriterProperty : uint {
  MultiLanguage,
  Indent,
  ByteOrderMark,
  OmitXmlDeclaration,
  ConformanceLevel
}

alias DllImport!("xmllite.dll", "CreateXmlReader",
  int function(ref GUID riid, void** ppvObject, IMalloc pMalloc))
  CreateXmlReader;

alias DllImport!("xmllite.dll", "CreateXmlReaderInputWithEncodingCodePage",
  int function(IUnknown pInputStream, IMalloc pMalloc, uint nEncodingCodePage, int fEncodingHint, in wchar* pswzBaseUri, IUnknown* ppInput))
  CreateXmlReaderInputWithEncodingCodePage;

alias DllImport!("xmllite.dll", "CreateXmlReaderInputWithEncodingName",
  int function(IUnknown pInputStream, IMalloc pMalloc, in wchar* pwszEncodingName, int fEncodingHint, in wchar* pswzBaseUri, IUnknown* ppInput))
  CreateXmlReaderInputWithEncodingName;

alias DllImport!("xmllite.dll", "CreateXmlWriter",
  int function(ref GUID riid, void** ppvObject, IMalloc pMalloc))
  CreateXmlWriter;

alias DllImport!("xmllite.dll", "CreateXmlWriterOutputWithEncodingName",
  int function(IUnknown pOutputStream, IMalloc pMalloc, in wchar* pwszEncodingName, IUnknown* ppOutput))
  CreateXmlWriterOutputWithEncodingName;

interface IXmlReader : IUnknown {
  mixin(uuid("7279FC81-709D-4095-B63D-69FE4B0D9030"));
  int SetInput(IUnknown pInput);
  int GetProperty(uint nProperty, out int ppValue);
  int SetProperty(uint nProperty, int pValue);
  int Read(out XmlNodeType pNodeType);
  int GetNodeType(out XmlNodeType pNodeType);
  int MoveToFirstAttribute();
  int MoveToNextAttribute();
  int MoveToAttributeByName(in wchar* pwszLocalName, in wchar* pwszNamespaceUri);
  int MoveToElement();
  int GetQualifiedName(out wchar* ppwszQualifiedName, out uint pcwchQualifiedName);
  int GetNamespaceUri(out wchar* ppwszNamespaceUri, out uint pcwchNamespaceUri);
  int GetLocalName(out wchar* ppwszLocalName, out uint pcwchLocalName);
  int GetPrefix(out wchar* ppwszPrefix, out uint pcwchPrefix);
  int GetValue(out wchar* ppwszValue, out uint pcwchValue);
  int ReadValueChunk(wchar* pwchBuffer, uint cwchChunkSize, ref uint pcwchRead);
  int GetBaseUri(out wchar* pwchBaseUri, out uint pcwchBaseUri);
  int IsDefault();
  int IsEmptyElement();
  int GetLineNumber(out uint pnLineNumber);
  int GetLinePosition(out uint pnLinePosition);
  int GetAttributeCount(out uint pnAttributeCount);
  int GetDepth(out uint pnDepth);
  int IsEOF();
}

interface IXmlResolver : IUnknown {
  mixin(uuid("7279FC82-709D-4095-B63D-69FE4B0D9030"));
  int ResolveUri(in wchar* pwszBaseUri, in wchar* pwszPublicIdentifier, in wchar* pwszSystemIdentifier, out IUnknown ppResolvedInput);
}

interface IXmlWriter : IUnknown {
  mixin(uuid("7279FC88-709D-4095-B63D-69FE4B0D9030"));
  int SetOutput(IUnknown pOutput);
  int GetProperty(uint nProperty, out int ppValue);
  int SetProperty(uint nProperty, int pValue);
  int WriteAttributes(IXmlReader pReader, int fWriteDefaultAttributes);
  int WriteAttributeString(in wchar* pwszPrefix, in wchar* pwszLocalName, in wchar* pwszNamespaceUri, in wchar* pwszValue);
  int WriteCData(in wchar* pwszText);
  int WriteCharEntity(wchar wch);
  int WriteChars(in wchar* pwch, uint cwch);
  int WriteComment(in wchar* pwszComment);
  int WriteDocType(in wchar* pwszName, in wchar* pwszPublicId, in wchar* pwszSystemId, in wchar* pwszSubset);
  int WriteElementString(in wchar* pwszPrefix, in wchar* pwszLocalName, in wchar* pwszNamespaceUri, in wchar* pwszValue);
  int WriteEndDocument();
  int WriteEndElement();
  int WriteEntityRef(in wchar* pwszName);
  int WriteFullEndElement();
  int WriteName(in wchar* pwszName);
  int WriteNmToken(in wchar* pwszNmToken);
  int WriteNode(IXmlReader pReader, int fWriteDefaultAttributes);
  int WriteNodeShallow(IXmlReader pReader, int fWriteDefaultAttributes);
  int WriteProcessingInstruction(in wchar* pwszName, in wchar* pszValue);
  int WriteQualifiedName(in wchar* pwszLocalName, in wchar* pwszNamespaceUri);
  int WriteRaw(in wchar* pwszData);
  int WriteRawChars(in wchar* pwch, uint cwch);
  int WriteStartDocument(XmlStandalone standalone);
  int WriteStartElement(in wchar* pwszPrefix, in wchar* pwszLocalName, in wchar* pwszNamespaceUri);
  int WriteString(in wchar* pwszText);
  int WriteSurrogateCharEntity(wchar wchLow, wchar wchHigh);
  int WriteWhitespace(in wchar* pwszWhitespace);
  int Flush();
}

extern(D):

abstract class XmlResolver {

  abstract Object resolveUri(string baseUri, string publicId, string systemId);

}

/*class XmlUrlResolver : XmlResolver {

  override Object resolveUri(string baseUri, string publicId, string systemId) {
    return null;
  }

}

private class XmlResolverWrapper : Implements!(IXmlResolver) {

  private XmlResolver resolver_;

  this(XmlResolver resolver) {
    resolver_ = resolver;
  }

  int ResolveUri(in wchar* pwszBaseUri, in wchar* pwszPublicIdentifier, in wchar* pwszSystemIdentifier, out IUnknown ppResolvedInput) {
    return S_OK;
  }

}*/

/**
 */
final class XmlReaderSettings {

  private XmlConformanceLevel conformanceLevel_;
  private bool prohibitDtd_;
  //private XmlResolver xmlResolver_;

  /**
   */
  this() {
    reset();
  }

  /**
   */
  void reset() {
    conformanceLevel_ = XmlConformanceLevel.Document;
    prohibitDtd_ = true;
    //xmlResolver_ = new XmlUrlResolver;
  }

  /**
   */
  void conformanceLevel(XmlConformanceLevel value) {
    conformanceLevel_ = value;
  }

  /**
   * ditto
   */
  XmlConformanceLevel conformanceLevel() {
    return conformanceLevel_;
  }

  /**
   */
  void prohibitDtd(bool value) {
    prohibitDtd_ = value;
  }

  /**
   * ditto
   */
  bool prohibitDtd() {
    return prohibitDtd_;
  }

  /*void xmlResolver(XmlResolver value) {
    xmlResolver_ = value;
  }

  XmlResolver xmlResolver() {
    return xmlResolver_;
  }*/

}

/**
 */
class XmlParserContext {

  private string baseURI_;
  private Encoding encoding_;

  /**
   */
  this(string baseURI, Encoding encoding = null) {
    baseURI_ = baseURI;
    encoding_ = encoding;
  }
  
  /**
   */
  final void baseURI(string value) {
    baseURI_ = value;
  }

  /**
   * ditto
   */
  final string baseURI() {
    return baseURI_;
  }

  /**
   */
  final void encoding(Encoding value) {
    encoding_ = value;
  }
  
  /**
   * ditto
   */
  final Encoding encoding() {
    return encoding_;
  }

}

/*extern(Windows)
alias DllImport!("shlwapi.dll", "SHCreateStreamOnFile",
  int function(in wchar* pszFile, uint grfMode, IStream* ppstm))
  SHCreateStreamOnFile;*/

private int createStreamOnFile(string fileName, uint flags, out IStream result) {

  class FileStream : Implements!(IStream) {

    private Handle handle_;

    this(string fileName, uint mode, uint access, uint share) {
      handle_ = CreateFile(fileName.toUtf16z(), access, share, null, mode, 0, Handle.init);
    }

    ~this() {
      if (handle_ != Handle.init) {
        CloseHandle(handle_);
        handle_ = Handle.init;
      }
    }

    int Read(void* pv, uint cb, ref uint pcbRead) {
      uint bytesRead;
      uint ret = ReadFile(handle_, pv, cb, bytesRead, null);
      if (&pcbRead)
        pcbRead = bytesRead;
      return S_OK;
    }

    int Write(void* pv, uint cb, ref uint pcbWritten) {
      uint bytesWritten;
      uint ret = WriteFile(handle_, pv, cb, bytesWritten, null);
      if (&pcbWritten)
        pcbWritten = bytesWritten;
      return S_OK;
    }

    int Seek(long dlibMove, uint dwOrigin, ref ulong plibNewPosition) {
      uint whence;
      if (dwOrigin == STREAM_SEEK_SET)
        whence = FILE_BEGIN;
      else if (dwOrigin == STREAM_SEEK_CUR)
        whence = FILE_CURRENT;
      else if (dwOrigin == STREAM_SEEK_END)
        whence = FILE_END;

      long ret;
      SetFilePointerEx(handle_, dlibMove, ret, whence);
      if (&plibNewPosition)
        plibNewPosition = cast(ulong)ret;
      return S_OK;
    }

    int SetSize(ulong libNewSize) {
      return E_NOTIMPL;
    }

    int CopyTo(IStream stream, ulong cb, ref ulong pcbRead, ref ulong pcbWritten) {
      if (&pcbRead)
        pcbRead = 0;
      if (&pcbWritten)
        pcbWritten = 0;
      return E_NOTIMPL;
    }

    int Commit(uint hrfCommitFlags) {
      return E_NOTIMPL;
    }

    int Revert() {
      return E_NOTIMPL;
    }

    int LockRegion(ulong libOffset, ulong cb, uint dwLockType) {
      return E_NOTIMPL;
    }

    int UnlockRegion(ulong libOffset, ulong cb, uint dwLockType) {
      return E_NOTIMPL;
    }

    int Stat(out STATSTG pstatstg, uint grfStatFlag) {
      long size;
      if (GetFileSizeEx(handle_, size) != 0)
        pstatstg.cbSize = cast(ulong)size;
      return S_OK;
    }

    int Clone(out IStream ppstm) {
      ppstm = null;
      return E_NOTIMPL;
    }

  }

  result = null;

  uint mode = (flags & STGM_CREATE) ? CREATE_ALWAYS : OPEN_EXISTING;
  uint access = GENERIC_READ;
  if (flags & STGM_WRITE)
    access |= GENERIC_WRITE;
  if (flags & STGM_READWRITE)
    access = GENERIC_READ | GENERIC_WRITE;
  uint share = FILE_SHARE_READ;

  result = new FileStream(fileName, mode, access, share);
  return result ? S_OK : E_FAIL;
}

extern(Windows)
alias DllImport!("urlmon.dll", "CreateURLMonikerEx",
  int function(IMoniker pMkCtx, in wchar* szURL, IMoniker* ppmk, uint dwFlags))
  CreateURLMonikerEx;

/*extern(Windows)
alias DllImport!("urlmon.dll", "URLOpenBlockingStream",
 int function(IUnknown, in wchar*, IStream*, uint, void*))
 URLOpenBlockingStream;*/

private int createStreamOnUrl(string uri, out IStream result) {

  result = null;

  IMoniker url;
  int hr = CreateURLMonikerEx(null, uri.toUtf16z(), &url, 1);
  scope(exit) tryRelease(url);

  if (hr != S_OK)
    return hr;

  IBindCtx context;
  hr = CreateBindCtx(0, context);
  scope(exit) tryRelease(context);

  if (hr != S_OK)
    return hr;

  hr = url.BindToStorage(context, null, uuidof!(IStream), cast(void**)&result);
  return (hr != S_OK) 
    ? E_FAIL 
    : hr;
}

/**
 * Represents a reader that provides forward-only access to XML data.
 */
abstract class XmlReader {

  /**
   * Creates a new XmlReader instance with the specified URI, XmlReaderSettings and XmlParserContext objects.
   */
  static XmlReader create(string inputUri, XmlReaderSettings settings = null, XmlParserContext context = null) {

    IStream getStream(string uri) {
      if (uri.indexOf(":\\") == 1) {
        // eg: C:\...
        IStream ret;
        createStreamOnFile(uri, STGM_READ, ret);
        return ret;
      }
      else if (uri.indexOf(':') > 0
        && (uri.startsWith("http") || uri.startsWith("https") || uri.startsWith("ftp"))) {
        IStream ret;
        createStreamOnUrl(uri, ret);
        return ret;
      }
      return null;
    }

    if (settings is null)
      settings = new XmlReaderSettings;

    return createImpl(getStream(inputUri), settings, inputUri, context);
  }

  /**
   * Creates a new XmlReader instance with the specified stream, XmlReaderSettings and XmlParserContext objects.
   */
  static XmlReader create(Stream input, XmlReaderSettings settings = null, XmlParserContext context = null) {
    if (settings is null)
      settings = new XmlReaderSettings;

    return createImpl(new COMStream(input), settings, null, context);
  }

  /**
   * Creates a new XmlReader instance with the specified stream, XmlReaderSettings and base URI.
   */
  static XmlReader create(Stream input, XmlReaderSettings settings, string baseUri) {
    if (settings is null)
      settings = new XmlReaderSettings;

    return createImpl(new COMStream(input), settings, baseUri, null);
  }

  private static XmlReader createImpl(IStream input, XmlReaderSettings settings, string baseUri, XmlParserContext context) {
    if (input is null)
      throw new ArgumentNullException("input");

    if (settings is null)
      settings = new XmlReaderSettings;

    return new XmlLiteReader(input, settings, baseUri, context);
  }

  /**
   * Closes the reader.
   */
  abstract void close();

  /**
   * Reads the next node from the stream.
   * Returns: true if the next node was _read successfully; false if there are no more nodes to _read.
   */
  abstract bool read();

  /**
   */
  void readStartElement(string localName, string ns) {
    if (moveToContent() != XmlNodeType.Element)
      throw new XmlException(XmlNodeTypeString[nodeType] ~ " is an invalid XmlNodeType.", lineNumber, linePosition);
    if (localName != this.localName || ns != namespaceURI)
      throw new XmlException("Element '"~ localName ~ "' with namespace name '" ~ ns ~ "' not found.", lineNumber, linePosition);
    read();
  }

  /**
   * ditto
   */
  void readStartElement(string name) {
    if (moveToContent() != XmlNodeType.Element)
      throw new XmlException(XmlNodeTypeString[nodeType] ~ " is an invalid XmlNodeType.", lineNumber, linePosition);
    if (name != this.name)
      throw new XmlException("Element '"~ name ~ "' not found.", lineNumber, linePosition);
    read();
  }

  /**
   * ditto
   */
  void readStartElement() {
    if (moveToContent() != XmlNodeType.Element)
      throw new XmlException(XmlNodeTypeString[nodeType] ~ " is an invalid XmlNodeType.", lineNumber, linePosition);
    read();
  }

  /**
   */
  void readEndElement() {
    if (moveToContent() != XmlNodeType.EndElement)
      throw new XmlException(XmlNodeTypeString[nodeType] ~ " is an invalid XmlNodeType.", lineNumber, linePosition);
    read();
  }

  /**
   */
  string readElementString(string localName, string ns) {
    if (moveToContent() != XmlNodeType.Element)
      throw new XmlException(XmlNodeTypeString[nodeType] ~ " is an invalid XmlNodeType.", lineNumber, linePosition);
    if (localName != this.localName || ns != namespaceURI)
      throw new XmlException("Element '"~ localName ~ "' with namespace name '" ~ ns ~ "' not found.", lineNumber, linePosition);
    string result = "";
    if (!isEmptyElement) {
      result = readString();
      if (nodeType != XmlNodeType.EndElement)
        throw new XmlException(XmlNodeTypeString[nodeType] ~ " is an invalid XmlNodeType.", lineNumber, linePosition);
      read();
    }
    else
      read();
    return result;
  }

  /**
   * ditto
   */
  string readElementString(string name) {
    if (moveToContent() != XmlNodeType.Element)
      throw new XmlException(XmlNodeTypeString[nodeType] ~ " is an invalid XmlNodeType.", lineNumber, linePosition);
    if (name != this.name)
      throw new XmlException("Element '"~ name ~ "' not found.", lineNumber, linePosition);
    string result = "";
    if (!isEmptyElement) {
      result = readString();
      if (nodeType != XmlNodeType.EndElement)
        throw new XmlException(XmlNodeTypeString[nodeType] ~ " is an invalid XmlNodeType.", lineNumber, linePosition);
      read();
    }
    else
      read();
    return result;
  }

  /**
   * ditto
   */
  string readElementString() {
    if (moveToContent() != XmlNodeType.Element)
      throw new XmlException(XmlNodeTypeString[nodeType] ~ " is an invalid XmlNodeType.", lineNumber, linePosition);
    string result = "";
    if (!isEmptyElement) {
      read();
      result = readString();
      if (nodeType != XmlNodeType.EndElement)
        throw new XmlException("Unexpected node type '" ~ XmlNodeTypeString[nodeType] ~ "'. 'readElementString' method can only be called on elements with simple content.", lineNumber, linePosition);
      read();
    }
    else
      read();
    return result;
  }

  /**
   */
  bool readToDescendant(string localName, string namespaceURI) {
    int depth = this.depth;
    if (nodeType != XmlNodeType.Element) {
      if (readState != XmlReadState.Interactive)
        return false;
      depth--;
    }
    else if (isEmptyElement)
      return false;
    while (read() && this.depth > depth) {
      if (nodeType == XmlNodeType.Element && localName == this.localName && namespaceURI == this.namespaceURI)
        return true;
    }
    return false;
  }

  /**
   * ditto
   */
  bool readToDescendant(string name) {
    int depth = this.depth;
    if (nodeType != XmlNodeType.Element) {
      if (readState != XmlReadState.Interactive)
        return false;
      depth--;
    }
    else if (isEmptyElement)
      return false;
    while (read() && this.depth > depth) {
      if (nodeType == XmlNodeType.Element && name == this.name)
        return true;
    }
    return false;
  }

  /**
   */
  bool readToFollowing(string localName, string namespaceURI) {
    while (read()) {
      if (nodeType == XmlNodeType.Element && localName == this.localName && namespaceURI == this.namespaceURI)
        return true;
    }
    return false;
  }

  /**
   * ditto
   */
  bool readToFollowing(string name) {
    while (read()) {
      if (nodeType == XmlNodeType.Element && name == this.name)
        return true;
    }
    return false;
  }

  /**
   */
  bool readToNextSibling(char[] localName, char[] namespaceURI) {
    XmlNodeType nt;
    do {
      skip();
      nt = nodeType;
      if (nt == XmlNodeType.Element && localName == this.localName && namespaceURI != this.namespaceURI)
        return true;
    } while (nt != XmlNodeType.EndElement && !isEOF);
    return false;
  }
  
  /**
   * ditto
   */
  bool readToNextSibling(string name) {
    XmlNodeType nt;
    do {
      skip();
      nt = nodeType;
      if (nt == XmlNodeType.Element && name == this.name)
        return true;
    } while (nt != XmlNodeType.EndElement && !isEOF);
    return false;
  }

  /**
   */
  XmlNodeType moveToContent() {
    do {
      switch (nodeType) {
        case XmlNodeType.Attribute:
          moveToElement();
          // Fall through
        case XmlNodeType.Element, 
          XmlNodeType.EndElement, 
          XmlNodeType.CDATA, 
          XmlNodeType.Text, 
          XmlNodeType.EntityReference, 
          XmlNodeType.EndEntity:
          return nodeType;
        default:
      }
    } while (read());
    return nodeType;
  }

  /**
   */
  string readString() {
    if (readState != XmlReadState.Interactive)
      return "";

    moveToElement();
    if (nodeType == XmlNodeType.Element) {
      if (isEmptyElement)
        return "";
      if (!read())
        throw new InvalidOperationException;
      if (nodeType == XmlNodeType.EndElement)
        return "";
    }

    string result = "";
    if (0b000110000000011000 & (1 << nodeType)) {
      result ~= value;
      if (!read())
        return result;
    }
    return result;
  }

  /**
   */
  void skip() {
    if (readState == XmlReadState.Interactive) {
      moveToElement();
      if (nodeType == XmlNodeType.Element && !isEmptyElement) {
        int depth = this.depth;
        while (read() && depth < this.depth) {
          // do nothing
        }
        if (nodeType == XmlNodeType.EndElement)
          read();
      }
      else
        read();
    }
  }

  /**
   */
  abstract bool moveToFirstAttribute();

  /**
   */
  abstract bool moveToNextAttribute();

  /**
   */
  abstract bool moveToAttribute(string localName, string namespaceURI);

  /**
   * ditto
   */
  abstract bool moveToAttribute(string name);

  /**
   */
  abstract bool moveToElement();

  /**
   */
  abstract string getAttribute(string localName, string namespaceURI);

  /**
   * ditto
   */
  abstract string getAttribute(string name);

  /**
   */
  abstract XmlReadState readState();

  /**
   */
  abstract int depth();

  /**
   */
  abstract bool isEOF();

  /**
   */
  abstract bool isEmptyElement();

  /**
   */
  bool isDefault() {
    return false;
  }

  /**
   */
  abstract XmlNodeType nodeType();

  /**
   */
  abstract string baseURI();

  /**
   */
  abstract string name();

  /**
   */
  abstract string prefix();

  /**
   */
  abstract string localName();

  /**
   */
  abstract string namespaceURI();

  /**
   */
  abstract bool hasValue();

  /**
   */
  abstract string value();

  /**
   */
  bool hasAttributes() {
    return attributeCount > 0;
  }

  /**
   */
  abstract int attributeCount();

  /**
   */
  abstract int lineNumber();

  /**
   */
  abstract int linePosition();

  /**
   */
  string opIndex(string name, string namespaceURI) {
    return getAttribute(name, namespaceURI);
  }

  /**
   * ditto
   */
  string opIndex(string name) {
    return getAttribute(name);
  }

  private this() {
  }

}

private final class XmlLiteReader : XmlReader {

  private IXmlReader readerImpl_;
  private IStream stream_;
  private IMultiLanguage2 mlang_;

  this(IStream input, XmlReaderSettings settings, string baseUri, XmlParserContext context) {
    int hr = CreateXmlReader(uuidof!(IXmlReader), cast(void**)&readerImpl_, null);
    if (hr != S_OK)
      throw new COMException(hr);

    mlang_ = CMultiLanguage.coCreate!(IMultiLanguage2);
    readerImpl_.SetProperty(XmlReaderProperty.MultiLanguage, cast(int)cast(void*)mlang_);
    readerImpl_.SetProperty(XmlReaderProperty.ConformanceLevel, cast(int)settings.conformanceLevel);
    readerImpl_.SetProperty(XmlReaderProperty.DtdProcessing, settings.prohibitDtd ? 0 : 1);

    Encoding encoding;
    if (context !is null) {
      encoding = context.encoding;
      if (context.baseURI != null && context.baseURI != baseUri)
        baseUri = context.baseURI;
    }
    if (encoding is null)
      encoding = Encoding.UTF8;

    stream_ = input;

    IUnknown readerInput;
    hr = CreateXmlReaderInputWithEncodingName(stream_, null, encoding.webName().toUtf16z(), 0, baseUri.toUtf16z(), &readerInput);
    if (hr != S_OK)
      throw new COMException(hr);
    hr = readerImpl_.SetInput(readerInput);
    if (hr != S_OK)
      throw new COMException(hr);
  }

  ~this() {
    close();
  }

  override void close() {
    if (stream_ !is null) {
      tryRelease(stream_);
      stream_ = null;
    }
    if (readerImpl_ !is null) {
      tryRelease(readerImpl_);
      readerImpl_ = null;
    }
    if (mlang_ !is null) {
      tryRelease(mlang_);
      mlang_ = null;
    }
  }

  override bool read() {
    XmlNodeType nodeType;
    return readerImpl_.Read(nodeType) == S_OK;
  }

  override bool moveToFirstAttribute() {
    return readerImpl_.MoveToFirstAttribute() != S_FALSE;
  }

  override bool moveToNextAttribute() {
    return readerImpl_.MoveToNextAttribute() != S_FALSE;
  }

  override bool moveToAttribute(string name) {
    return readerImpl_.MoveToAttributeByName(name.toUtf16z(), null) != S_FALSE;
  }

  override bool moveToAttribute(string localName, string namespaceURI) {
    return readerImpl_.MoveToAttributeByName(localName.toUtf16z(), namespaceURI.toUtf16z()) != S_FALSE;
  }

  override bool moveToElement() {
    return readerImpl_.MoveToElement() != S_FALSE;
  }

  override string getAttribute(string name) {
    if (moveToAttribute(name))
      return value;
    return null;
  }

  override string getAttribute(string localName, string namespaceURI) {
    if (moveToAttribute(localName, namespaceURI))
      return value;
    return null;
  }

  override XmlReadState readState() {
    int value;
    readerImpl_.GetProperty(XmlReaderProperty.ReadState, value);
    return cast(XmlReadState)value;
  }

  override int depth() {
    uint value;
    readerImpl_.GetDepth(value);
    return cast(uint)value;
  }

  override bool isEOF() {
    return readerImpl_.IsEOF() != 0;
  }

  override bool isEmptyElement() {
    return readerImpl_.IsEmptyElement() != 0;
  }

  override bool isDefault() {
    return readerImpl_.IsDefault() != 0;
  }

  override XmlNodeType nodeType() {
    XmlNodeType nodeType;
    readerImpl_.GetNodeType(nodeType);
    return nodeType;
  }

  override string baseURI() {
    wchar* pwsz;
    uint cwch;
    readerImpl_.GetBaseUri(pwsz, cwch);
    return toUtf8(pwsz, 0, cwch);
  }

  override string name() {
    wchar* pwsz;
    uint cwch;
    readerImpl_.GetQualifiedName(pwsz, cwch);
    return toUtf8(pwsz, 0, cwch);
  }

  override string prefix() {
    wchar* pwsz;
    uint cwch;
    readerImpl_.GetPrefix(pwsz, cwch);
    return toUtf8(pwsz, 0, cwch);
  }

  override string localName() {
    wchar* pwsz;
    uint cwch;
    readerImpl_.GetLocalName(pwsz, cwch);
    return toUtf8(pwsz, 0, cwch);
  }

  override string namespaceURI() {
    wchar* pwsz;
    uint cwch;
    readerImpl_.GetNamespaceUri(pwsz, cwch);
    return toUtf8(pwsz, 0, cwch);
  }

  override bool hasValue() {
    return (0b100110010110011100 & (1 << nodeType)) != 0;
  }

  override string value() {
    wchar* pwsz;
    uint cwch;
    readerImpl_.GetValue(pwsz, cwch);
    return toUtf8(pwsz, 0, cwch);
  }

  override int attributeCount() {
    uint value;
    readerImpl_.GetAttributeCount(value);
    return value;
  }

  override int lineNumber() {
    uint value;
    readerImpl_.GetLineNumber(value);
    return cast(int)value;
  }

  override int linePosition() {
    uint value;
    readerImpl_.GetLinePosition(value);
    return cast(uint)value;
  }

}

/**
 */
final class XmlWriterSettings {

  private Encoding encoding_;
  private XmlConformanceLevel conformanceLevel_;
  private int indent_;
  private bool omitXmlDeclaration_;

  /**
   */
  this() {
    reset();
  }

  /**
   */
  void reset() {
    encoding_ = Encoding.UTF8;
    conformanceLevel_ = XmlConformanceLevel.Document;
    indent_ = -1;
    omitXmlDeclaration_ = false;
  }

  /**
   */
  void encoding(Encoding value) {
    encoding_ = value;
  }

  /**
   * ditto
   */
  Encoding encoding() {
    return encoding_;
  }

  /**
   */
  void conformanceLevel(XmlConformanceLevel value) {
    conformanceLevel_ = value;
  }

  /**
   * ditto
   */
  XmlConformanceLevel conformanceLevel() {
    return conformanceLevel_;
  }

  /**
   */
  void indent(bool value) {
    indent_ = value ? 1 : 0;
  }

  /**
   * ditto
   */
  bool indent() {
    return indent_ == 1;
  }

  /**
   */
  bool omitXmlDeclaration() {
    return omitXmlDeclaration_;
  }

  /**
   * ditto
   */
  void omitXmlDeclaration(bool value) {
    omitXmlDeclaration_ = value;
  }

}

/**
 */
abstract class XmlWriter {

  /**
   */
  static XmlWriter create(string outputFileName, XmlWriterSettings settings = null) {
    if (settings is null)
      settings = new XmlWriterSettings;

    IStream output;
    createStreamOnFile(outputFileName, STGM_CREATE | STGM_WRITE, output);
    return createImpl(output, settings.encoding, settings);
  }

  /**
   */
  static XmlWriter create(Stream output, XmlWriterSettings settings = null) {
    if (output is null)
      throw new ArgumentNullException("output");

    if (settings is null)
      settings = new XmlWriterSettings;

    return createImpl(new COMStream(output), settings.encoding, settings);
  }

  /**
   */
  private static XmlWriter createImpl(IStream output, Encoding encoding, XmlWriterSettings settings) {
    return new XmlLiteWriter(output, encoding, settings);
  }

  /**
   */
  abstract void close();

  /**
   */
  abstract void writeAttributes(XmlReader reader, bool defattr);

  /**
   */
  abstract void writeAttributeString(string prefix, string localname, string ns, string value);

  /**
   * ditto
   */
  final void writeAttributeString(string localName, string ns, string value) {
    writeAttributeString(null, localName, ns, value);
  }

  /**
   * ditto
   */
  final void writeAttributeString(string localName, string value) {
    writeAttributeString(localName, null, value);
  }

  /**
   */
  abstract void writeCData(string text);

  /**
   */
  abstract void writeCharEntity(char ch);

  /**
   */
  abstract void writeChars(char[] buffer, int index, int count);

  /**
   */
  abstract void writeComment(string text);

  /**
   */
  abstract void writeDocType(string name, string pubid, string sysid, string subset);

  /**
   */
  abstract void writeElementString(string prefix, string localName, string ns, string value);

  /**
   * ditto
   */
  final void writeElementString(string localName, string ns, string value) {
    writeElementString(null, localName, ns, value);
  }

  /**
   * ditto
   */
  final void writeElementString(string localName, string value) {
    writeElementString(localName, null, value);
  }

  /**
   */
  abstract void writeEndDocument();

  /**
   */
  abstract void writeEndElement();

  /**
   */
  abstract void writeEntityRef(string name);

  /**
   */
  abstract void writeFullEndElement();

  /**
   */
  abstract void writeName(string name);

  /**
   */
  abstract void writeNmToken(string name);

  /**
   */
  abstract void writeNode(XmlReader reader, bool defattr);

  /**
   */
  abstract void writeProcessingInstruction(string name, string text);

  /**
   */
  abstract void writeQualifiedName(string localName, string ns);

  /**
   */
  abstract void writeRaw(string data);

  /**
   */
  abstract void writeRaw(char[] buffer, int index, int count);

  /**
   */
  abstract void writeStartDocument(bool standalone);

  /**
   * ditto
   */
  abstract void writeStartDocument();

  /**
   */
  abstract void writeStartElement(string prefix, string localName, string ns);

  /**
   * ditto
   */
  final void writeStartElement(string localName, string ns) {
    writeStartElement(null, localName, ns);
  }

  /**
   * ditto
   */
  final void writeStartElement(string localName) {
    writeStartElement(null, localName, null);
  }

  /**
   */
  abstract void writeString(string text);

  /**
   */
  abstract void writeWhitespace(string ws);

  /**
   */
  abstract void flush();

  /**
   */
  abstract void writeBase64(void[] buffer, int index, int count);

}

private final class XmlLiteWriter : XmlWriter {

  private IXmlWriter writerImpl_;
  private IMultiLanguage2 mlang_;
  private IStream stream_;

  this(IStream output, Encoding encoding, XmlWriterSettings settings) {
    int hr = CreateXmlWriter(uuidof!(IXmlWriter), cast(void**)&writerImpl_, null);

    if (encoding is null)
      encoding = Encoding.UTF8;

    mlang_ = CMultiLanguage.coCreate!(IMultiLanguage2);
    writerImpl_.SetProperty(XmlWriterProperty.MultiLanguage, cast(int)cast(void*)mlang_);
    writerImpl_.SetProperty(XmlWriterProperty.ConformanceLevel, cast(int)settings.conformanceLevel);
    writerImpl_.SetProperty(XmlWriterProperty.OmitXmlDeclaration, settings.omitXmlDeclaration ? 1 : 0);
    writerImpl_.SetProperty(XmlWriterProperty.Indent, settings.indent ? 1 : 0);

    stream_ = output;

    IUnknown writerOutput;
    hr = CreateXmlWriterOutputWithEncodingName(stream_, null, encoding.webName().toUtf16z(), &writerOutput);
    if (hr != S_OK)
      throw new COMException(hr);
    hr = writerImpl_.SetOutput(writerOutput);
    if (hr != S_OK)
      throw new COMException(hr);
  }

  ~this() {
    close();
  }

  override void close() {
    if (stream_ !is null) {
      tryRelease(stream_);
      stream_ = null;
    }
    if (mlang_ !is null) {
      tryRelease(mlang_);
      mlang_ = null;
    }
    if (writerImpl_ !is null) {
      tryRelease(writerImpl_);
      writerImpl_ = null;
    }
  }

  override void writeAttributes(XmlReader reader, bool defattr) {
    if (reader is null)
      throw new ArgumentNullException("reader");

    if (auto r = cast(XmlLiteReader)reader)
      writerImpl_.WriteAttributes(r.readerImpl_, defattr ? 1 : 0);
  }

  override void writeAttributeString(string prefix, string localName, string ns, string value) {
    writerImpl_.WriteAttributeString(prefix.toUtf16z(), localName.toUtf16z(), ns.toUtf16z(), value.toUtf16z());
  }

  override void writeCData(string text) {
    writerImpl_.WriteCData(text.toUtf16z());
  }

  override void writeCharEntity(char ch) {
    writerImpl_.WriteCharEntity(ch);
  }

  override void writeChars(char[] buffer, int index, int count) {
    writerImpl_.WriteChars(buffer.toUtf16z(index), count);
  }

  override void writeComment(string text) {
    writerImpl_.WriteComment(text.toUtf16z());
  }

  override void writeDocType(string name, string pubid, string sysid, string subset) {
    writerImpl_.WriteDocType(name.toUtf16z(), pubid.toUtf16z(), sysid.toUtf16z(), subset.toUtf16z());
  }

  override void writeElementString(string prefix, string localName, string ns, string value) {
    writerImpl_.WriteElementString(prefix.toUtf16z(), localName.toUtf16z(), ns.toUtf16z(), value.toUtf16z());
  }

  override void writeEndDocument() {
    writerImpl_.WriteEndDocument();
  }

  override void writeEndElement() {
    writerImpl_.WriteEndElement();
  }

  override void writeEntityRef(string name) {
    writerImpl_.WriteEntityRef(name.toUtf16z());
  }

  override void writeFullEndElement() {
    writerImpl_.WriteFullEndElement();
  }

  override void writeName(string name) {
    writerImpl_.WriteName(name.toUtf16z());
  }

  override void writeNmToken(string name) {
    writerImpl_.WriteNmToken(name.toUtf16z());
  }

  override void writeNode(XmlReader reader, bool defattr) {
    if (reader is null)
      throw new ArgumentNullException("reader");

    if (auto r = cast(XmlLiteReader)reader)
      writerImpl_.WriteNode(r.readerImpl_, defattr ? 1 : 0);
  }

  override void writeProcessingInstruction(string name, string text) {
    writerImpl_.WriteProcessingInstruction(name.toUtf16z(), text.toUtf16z());
  }

  override void writeQualifiedName(string localName, string ns) {
    writerImpl_.WriteQualifiedName(localName.toUtf16z(), ns.toUtf16z());
  }

  override void writeRaw(string data) {
    writerImpl_.WriteRaw(data.toUtf16z());
  }

  override void writeRaw(char[] buffer, int index, int count) {
    writerImpl_.WriteRawChars(buffer.toUtf16z(index), count);
  }

  override void writeStartDocument() {
    writerImpl_.WriteStartDocument(XmlStandalone.Omit);
  }

  override void writeStartDocument(bool standalone) {
    writerImpl_.WriteStartDocument(standalone ? XmlStandalone.Yes : XmlStandalone.No);
  }
  
  override void writeStartElement(string prefix, string localName, string ns) {
    writerImpl_.WriteStartElement(prefix.toUtf16z(), localName.toUtf16z(), ns.toUtf16z());
  }

  override void writeString(string text) {
    writerImpl_.WriteString(text.toUtf16z());
  }

  override void writeWhitespace(string ws) {
    writerImpl_.WriteWhitespace(ws.toUtf16z());
  }

  override void flush() {
    writerImpl_.Flush();
  }

  override void writeBase64(void[] buffer, int index, int count) {
    writeChars(std.base64.encode(cast(char[])buffer), index, count);
  }

}