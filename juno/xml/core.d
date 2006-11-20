/**
 * Contains classes for working with XML.
 */
module juno.xml.core;

private import juno.base.all,
  juno.com.core;
private import std.stream : Stream, SeekPos;

package const char[] S_XML = "{0} An error occurred at {1} ({2}, {3}).";
package const char[] S_XML_ERRORPOSITION = "Line {0}, position {1}.";

public enum XmlNodeType {
  None,
  Element,
  Attribute,
  Text,
  CDATA,
  EntityReference,
  Entity,
  ProcessingInstruction,
  Comment,
  Document,
  DocumentType,
  DocumentFragment,
  Notation,
  Whitespace,
  SignificantWhitespace,
  EndElement,
  EndEntity,
  XmlDeclaration
}

/**
 * The exception thrown when an error occurs when processing XML.
 */
public class XmlException : Throwable {

  private int lineNumber_;
  private int linePosition_;
  private char[] message_;
  private char[] reason_;
  private char[] sourceUri_;

  /**
   * Creates a new instance.
   * Params: message = A description of the error.
   */
  public this(char[] message = null) {
    super(message);
  }

  /**
   * Retrieves the line number indicating where the error occurred.
   */
  public int lineNumber() {
    return lineNumber_;
  }

  /**
   * Retrieves the line position indicating where the error occurred.
   */
  public int linePosition() {
    return linePosition_;
  }

  /**
   * Retrieves the location of the XML file.
   */
  public char[] sourceUri() {
    return sourceUri_;
  }

  package this(char[] reason, int lineNumber, int linePosition, char[] sourceUri) {
    super(createMessage(reason, sourceUri, lineNumber, linePosition));
    reason_ = reason;
    lineNumber_ = lineNumber;
    linePosition_ = linePosition;
    sourceUri_ = sourceUri;
  }

  private static char[] createMessage(char[] reason, char[] sourceUri, int lineNumber, int linePosition) {
    char[] s = reason;
    if (lineNumber != 0)
      s ~= " " ~ format(S_XML_ERRORPOSITION, lineNumber, linePosition);
    return s;
  }

}

public class XPathException : Throwable {

  public this(char[] message = null) {
    super(message);
  }

}

public class XmlQualifiedName {

  private char[] name_;
  private char[] ns_;

  public this(char[] name = "", char[] ns = "") {
    name_ = name;
    ns_ = ns;
  }

  public override int opEquals(Object other) {
    if (this is other)
      return true;
    XmlQualifiedName qname = cast(XmlQualifiedName)other;
    if (qname !is null && qname.name_ == name_)
      return qname.ns_ == ns_;
    return false;
  }

  public override int opCmp(Object other) {
    if (other is null)
      return 1;
    XmlQualifiedName qname = cast(XmlQualifiedName)other;
    int cmp = typeid(char[]).compare(&ns_, &qname.ns_);
    if (cmp == 0)
      cmp = typeid(char[]).compare(&name_, &qname.name_);
    return cmp;
  }

  public override uint toHash() {
    return typeid(char[]).getHash(&name_);
  }

  public override char[] toString() {
    if (namespace.length > 0)
      return namespace ~ ":" ~ name_;
    return name_;
  }

  public final char[] name() {
    return name_;
  }

  public final char[] namespace() {
    return ns_;
  }

  public final bool isEmpty() {
    return name_.length == 0 && ns_.length == 0;
  }

}

package class COMInputStream : Implements!(IStream) {

  private Stream stream_;

  public this(Stream baseStream) {
    stream_ = baseStream;
  }

  int Read(void* pv, uint cb, out uint pcbRead) {
    ubyte[] buffer = new ubyte[cb];
    pcbRead = stream_.readBlock(buffer, cb);
    std.c.string.memcpy(pv, buffer, cb);
    return S_OK;
  }

  int Write(void* pv, uint cb, out uint pcbWritten) {
    pcbWritten = 0;
    return S_OK;
  }

  int Seek(long dlibMove, uint dwOrigin, out long plibNewPosition) {
    plibNewPosition = cast(long)stream_.seek(dlibMove, cast(SeekPos)dwOrigin);
    return S_OK;
  }

  int SetSize(long libNewSize) {
    return S_OK;
  }

  int CopyTo(IStream stm, long cb, out long pcbRead, out long pcbWritten) {
    pcbRead = 0;
    pcbWritten = 0;
    return S_OK;
  }

  int Commit(uint hrfCommitFlags) {
    return S_OK;
  }

  int Revert() {
    return E_NOTIMPL;
  }

  int LockRegion(long libOffset, long cb, uint dwLockType) {
    return S_OK;
  }

  int UnlockRegion(long libOffset, long cb, uint dwLockType) {
    return S_OK;
  }

  int Stat(out STATSTG pstatstg, uint gfrStatFlag) {
    return E_NOTIMPL;
  }

  int Clone(out IStream ppstm) {
    ppstm = null;
    return E_NOTIMPL;
  }

  extern (D)
  override void finalize() {
    if (stream_ !is null) {
      stream_.close();
      stream_ = null;
    }
  }

}

package class COMOutputStream : Implements!(IStream) {

  private Stream stream_;

  public this(Stream baseStream) {
    stream_ = baseStream;
  }

  int Read(void* pv, uint cb, out uint pcbRead) {
    pcbRead = 0;
    return S_OK;
  }

  int Write(void* pv, uint cb, out uint pcbWritten) {
    ubyte[] buffer = new ubyte[cb];
    std.c.string.memcpy(buffer, pv, cb);
    pcbWritten = stream_.writeBlock(buffer, cb);
    return S_OK;
  }

  int Seek(long dlibMove, uint dwOrigin, out long plibNewPosition) {
    plibNewPosition = cast(long)stream_.seek(dlibMove, cast(SeekPos)dwOrigin);
    return S_OK;
  }

  int SetSize(long libNewSize) {
    return S_OK;
  }

  int CopyTo(IStream stm, long cb, out long pcbRead, out long pcbWritten) {
    pcbRead = 0;
    pcbWritten = 0;
    return S_OK;
  }

  int Commit(uint hrfCommitFlags) {
    return S_OK;
  }

  int Revert() {
    return E_NOTIMPL;
  }

  int LockRegion(long libOffset, long cb, uint dwLockType) {
    return S_OK;
  }

  int UnlockRegion(long libOffset, long cb, uint dwLockType) {
    return S_OK;
  }

  int Stat(out STATSTG pstatstg, uint gfrStatFlag) {
    return E_NOTIMPL;
  }

  int Clone(out IStream ppstm) {
    ppstm = null;
    return E_NOTIMPL;
  }

  extern (D)
  override void finalize() {
    if (stream_ !is null) {
      stream_.close();
      stream_ = null;
    }
  }

}