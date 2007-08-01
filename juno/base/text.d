/*
 * Copyright (c) 2007 John Chapman
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

/**
 * Contains classes representing ASCII, UTF-8 and UTF-16 character encodings.
 */
module juno.base.text;

private import juno.base.core,
  juno.base.string,
  juno.base.native,
  juno.com.core;

private import std.string : icmp;

// MLang

enum MIMECONTF : uint {
  MIMECONTF_MAILNEWS = 0x1,
  MIMECONTF_BROWSER = 0x2,
  MIMECONTF_MINIMAL = 0x4,
  MIMECONTF_IMPORT = 0x8,
  MIMECONTF_SAVABLE_MAILNEWS = 0x100,
  MIMECONTF_SAVABLE_BROWSER = 0x200,
  MIMECONTF_EXPORT = 0x400,
  MIMECONTF_PRIVCONVERTER = 0x10000,
  MIMECONTF_VALID = 0x20000,
  MIMECONTF_VALID_NLS = 0x40000,
  MIMECONTF_MIME_IE4 = 0x10000000,
  MIMECONTF_MIME_LATEST = 0x20000000,
  MIMECONTF_MIME_REGISTRY = 0x40000000
}

struct MIMECPINFO {
  uint dwFlags;
  uint uiCodePage;
  uint uiFamilyCodePage;
  wchar[64] wszDescription;
  wchar[50] wszWebCharset;
  wchar[50] wszHeaderCharset;
  wchar[50] wszBodyCharset;
  wchar[32] wszFixedWidthFont;
  wchar[32] wszProportionalFont;
  ubyte bGDICharset;
}

struct MIMECSETINFO {
  uint uiCodePage;
  uint uiInternetEncoding;
  wchar[50] wszCharset;
}

struct RFC1766INFO {
  uint lcid;
  wchar[6] wszRfc1766;
  wchar[32] wszLocaleName;
}

struct SCRIPTINFO {
  ubyte ScriptId;
  uint uiCodePage;
  wchar[64] wszDescription;
  wchar[32] wszFixedWidthFont;
  wchar[32] wszProportionalFont;
}

struct DetectEncodingInfo {
  uint nLangID;
  uint nCodePage;
  int nDocPercent;
  int nConfidence;
}

interface IEnumCodePage : IUnknown {
  static GUID IID = { 0x275c23e3, 0x3747, 0x11d0, 0x9f, 0xea, 0x00, 0xaa, 0x00, 0x3f, 0x86, 0x46 };
  int Clone(out IEnumCodePage ppEnum);
  int Next(uint celt, MIMECPINFO* rgelt, out uint pceltFetched);
  int Reset();
  int Skip(uint celt);
}

interface IEnumRfc1766 : IUnknown {
  static GUID IID = { 0x3dc39d1d, 0xc030, 0x11d0, 0xb8, 0x1b, 0x00, 0xc0, 0x4f, 0xc9, 0xb3, 0x1f };
  int Clone(out IEnumRfc1766 ppEnum);
  int Next(uint celt, RFC1766INFO* rgelt, out uint pceltFetched);
  int Reset();
  int Skip(uint celt);
}

interface IEnumScript : IUnknown {
  static GUID IID = { 0x3dc39d1d, 0xc030, 0x11d0, 0xb8, 0x1b, 0x00, 0xc0, 0x4f, 0xc9, 0xb3, 0x1f };
  int Clone(out IEnumScript ppEnum);
  int Next(uint celt, SCRIPTINFO* rgelt, out uint pceltFetched);
  int Reset();
  int Skip(uint celt);
}

interface IMLangConvertCharset : IUnknown {
  static GUID IID = { 0xd66d6f98, 0xcdaa, 0x11d0, 0xb8, 0x22, 0x00, 0xc0, 0x4f, 0xc9, 0xb3, 0x1f };
  int Initialize(uint uiSrcCodePage, uint uiDstCodePage, uint dwProperty);
  int GetSourceCodePage(out uint puiSrcCodePage);
  int GetDestinationCodePage(out uint puiDstCodePage);
  int GetProperty(out uint pdwProperty);
  int DoConversion(ubyte* pSrcStr, ref uint pcSrcSize, ubyte* pDstStr, ref uint pcDstSize);
  int DoConversionToUnicode(ubyte* pSrcStr, ref uint pcSrcSize, wchar* pDstStr, ref uint pcDstSize);
  int DoConversionFromUnicode(wchar* pSrcStr, ref uint pcSrcSize, ubyte* pDstStr, ref uint pcDstSize);
}

interface IMultiLanguage : IUnknown {
  static GUID IID = { 0x275c23e1, 0x3747, 0x11d0, 0x9f, 0xea, 0x00, 0xaa, 0x00, 0x3f, 0x86, 0x46 };
  int GetNumberOfCodePageInfo(out uint pcCodePage);
  int GetCodePageInfo(uint uiCodePage, out MIMECPINFO pCodePageInfo);
  int GetFamilyCodePage(uint uiCodePage, out uint puiFamilyCodePage);
  int EnumCodePages(uint grfFlags, out IEnumCodePage ppEnumCodePage);
  int GetCharsetInfo(wchar* Charset, out MIMECSETINFO pCharsetInfo);
  int IsConvertible(uint dwSrcEncoding, uint dwDstEncoding);
  int ConvertString(ref uint pdwMode, uint dwSrcEncoding, uint dwDstEncoding, ubyte* pSrcStr, ref uint pcSrcSize, ubyte* pDstStr, ref uint pcDstSize);
  int ConvertStringToUnicode(ref uint pdwMode, uint dwEncoding, ubyte* pSrcStr, ref uint pcSrcSize, wchar* pDstStr, ref uint pcDstSize);
  int ConvertStringFromUnicode(ref uint pdwMode, uint dwEncoding, wchar* pSrcStr, ref uint pcSrcSize, ubyte* pDstStr, ref uint pcDstSize);
  int ConvertStringReset();
  int GetRfc1766FromLcid(uint Locale, out wchar* pbstrRfc1766);
  int GetLcidFromRfc1766(out uint Locale, wchar* bstrRfc1766);
  int EnumRfc1766(out IEnumRfc1766 ppEnumRfc1766);
  int GetRfc1766Info(uint Locale, out RFC1766INFO pRfc1766Info);
  int CreateConvertCharset(uint uiSrcCodePage, uint uiDstCodePage, uint dwProperty, out IMLangConvertCharset ppMLangConvertCharset);
}

interface IMultiLanguage2 : IUnknown {
  static GUID IID = { 0xDCCFC164, 0x2B38, 0x11d2, 0xB7, 0xEC, 0x00, 0xC0, 0x4F, 0x8F, 0x5D, 0x9A };
  int GetNumberOfCodePageInfo(out uint pcCodePage);
  int GetCodePageInfo(uint uiCodePage, ushort LangId, out MIMECPINFO pCodePageInfo);
  int GetFamilyCodePage(uint uiCodePage, out uint puiFamilyCodePage);
  int EnumCodePages(uint grfFlags, ushort LangId, out IEnumCodePage ppEnumCodePage);
  int GetCharsetInfo(wchar* Charset, out MIMECSETINFO pCharsetInfo);
  int IsConvertible(uint dwSrcEncoding, uint dwDstEncoding);
  int ConvertString(ref uint pdwMode, uint dwSrcEncoding, uint dwDstEncoding, ubyte* pSrcStr, ref uint pcSrcSize, ubyte* pDstStr, ref uint pcDstSize);
  int ConvertStringToUnicode(ref uint pdwMode, uint dwEncoding, ubyte* pSrcStr, ref uint pcSrcSize, wchar* pDstStr, ref uint pcDstSize);
  int ConvertStringFromUnicode(ref uint pdwMode, uint dwEncoding, wchar* pSrcStr, ref uint pcSrcSize, ubyte* pDstStr, ref uint pcDstSize);
  int ConvertStringReset();
  int GetRfc1766FromLcid(uint Locale, out wchar* pbstrRfc1766);
  int GetLcidFromRfc1766(out uint Locale, wchar* bstrRfc1766);
  int EnumRfc1766(out IEnumRfc1766 ppEnumRfc1766);
  int GetRfc1766Info(uint Locale, out RFC1766INFO pRfc1766Info);
  int CreateConvertCharset(uint uiSrcCodePage, uint uiDstCodePage, uint dwProperty, out IMLangConvertCharset ppMLangConvertCharset);
  int ConvertStringInIStream(ref uint pdwMode, uint dwFlag, wchar* lpFallBack, uint dwSrcEncoding, uint dwDstEncoding, IStream pstmIn, IStream pstmOut);
  int ConvertStringToUnicodeEx(uint dwEncoding, ubyte* pSrcStr, ref uint pcSrcSize, wchar* pDstStr, ref uint pcDstSize, uint dwFlag, wchar* lpFallBack);
  int ConvertStringFromUnicodeEx(uint dwEncoding, wchar* pSrcStr, ref uint pcSrcSize, ubyte* pDstStr, ref uint pcDstSize, uint dwFlag, wchar* lpFallBack);
  int DetectCodepageInIStream(uint dwFlag, uint dwPrefWinCodePage, IStream pstmIn, ref DetectEncodingInfo lpEncoding, ref int pcScores);
  int DetectInputCodepage(uint dwFlag, uint dwPrefWinCodePage, ubyte* pSrcStr, ref int pcSrcSize, ref DetectEncodingInfo lpEncoding, ref int pcScores);
  int ValidateCodePage(uint uiCodePage, Handle hwnd);
  int GetCodePageDescription(uint uiCodePage, uint lcid, wchar* lpWideCharStr, int cchWideChar);
  int IsCodePageInstallable(uint uiCodePage);
  int SetMimeDBSource(uint dwSource);
  int GetNumberOfScripts(out uint pnScripts);
  int EnumScripts(uint dwFlags, ushort LangId, out IEnumScript ppEnumScript);
  int ValidateCodePageEx(uint uiCodePage, Handle hwnd, uint dwfIODControl);
}

interface IMultiLanguage3 : IMultiLanguage2 {
  static GUID IID = { 0x4e5868ab, 0xb157, 0x4623, 0x9a, 0xcc, 0x6a, 0x1d, 0x9c, 0xae, 0xbe, 0x04 };
  int DetectOutboundCodePage(uint dwFlags, wchar* lpWideCharStr, int cchWideChar, uint* puiPreferredCodePages, uint nPreferredCodePages, uint* puiDetectedCodePages, ref uint pnDetectedCodePages, wchar* lpSpecialChar);
  int DetectOutboundCodePageInIStream(uint dwFlags, IStream pStrIn, uint* puiPreferredCodePages, uint nPreferredCodePages, uint* puiDetectedCodePages, wchar* lpSpecialChar);
}

abstract final class CMultiLanguage {
  static GUID CLSID = { 0x275c23e2, 0x3747, 0x11d0, 0x9f, 0xea, 0x00, 0xaa, 0x00, 0x3f, 0x86, 0x46 };
  mixin CoInterfaces!(IMultiLanguage2);
}

extern (Windows)
alias DllImport!("mlang.dll", "ConvertINetString",
  int function(uint* lpdwMode, uint dwSrcEncoding, uint dwDstEncoding, ubyte* lpSrcStr, uint* lpnSrcSize, ubyte* lpDstStr, uint* lpnDstSize))
  ConvertINetString;

extern (Windows)
alias DllImport!("mlang.dll", "IsConvertINetStringAvailable",
  int function(uint dwSrcEncoding, uint dwDstEncoding))
  IsConvertINetStringAvailable;

private struct CodePageInfo {
  uint codePage;
  uint familyCodePage;
  string webName;
  string headerName;
  string bodyName;
  string description;
  uint flags;
}

private CodePageInfo[] codePageInfoTable;
private CodePageInfo[uint] codePageInfoByCodePage;
private uint[string] codePageByName;

private void initCodePageInfo() {
  synchronized {
    if (auto mlang = CMultiLanguage.coCreate!(IMultiLanguage2)) {
      scope (exit) tryRelease(mlang);

      IEnumCodePage cp;
      if (mlang.EnumCodePages(MIMECONTF.MIMECONTF_MIME_LATEST, 0, cp) == S_OK) {
        scope (exit) tryRelease(cp);

        uint num = 0;
        mlang.GetNumberOfCodePageInfo(num);
        if (num > 0) {
          MIMECPINFO* cpInfo = cast(MIMECPINFO*)CoTaskMemAlloc(num * MIMECPINFO.sizeof);

          uint count = 0;
          cp.Next(num, cpInfo, count);
          codePageInfoTable.length = count;

          for (uint index = 0; index < count; index++) {
            with (cpInfo[index]) {
              codePageInfoTable[index] = CodePageInfo(uiCodePage, uiFamilyCodePage, toUtf8(wszWebCharset.ptr), toUtf8(wszHeaderCharset.ptr), toUtf8(wszBodyCharset.ptr), toUtf8(wszDescription.ptr), dwFlags);
            }
          }

          CoTaskMemFree(cpInfo);
        }
        else assert(false);
      }
    }
    else assert(false);
  }
}

private CodePageInfo* getCodePageInfo(uint codePage) {
  if (codePageInfoTable == null)
    initCodePageInfo();

  if (auto value = codePage in codePageInfoByCodePage)
    return value;

  uint cp;
  for (int i = 0; i < codePageInfoTable.length && (cp = codePageInfoTable[i].codePage) != 0; i++) {
    if (cp == codePage) {
      codePageInfoByCodePage[codePage] = codePageInfoTable[i];
      return &codePageInfoByCodePage[codePage];
    }
  }

  return null;
}

private uint getCodePageFromName(string name) {
  if (codePageInfoTable == null)
    initCodePageInfo();

  if (auto value = name in codePageByName)
    return *value;

  for (int i = 0; i < codePageInfoTable.length; i++) {
    if (icmp(codePageInfoTable[i].webName, name) == 0
      || (codePageInfoTable[i].codePage == 1200 && icmp("utf-16", name) == 0)) {
        uint cp = codePageInfoTable[i].codePage;
        codePageByName[name] = cp;
        return cp;
    }
  }

  throw new ArgumentException("'" ~ name ~ "' is not a supported encoding name.", "name");
}

/**
 * Converts a set of characters into a sequence of bytes.
 */
public abstract class Encoder {

  /**
   * Encodes a set of characters from the specified character array into a sequence of bytes.
   * Params:
   *   chars = The character array containing the characters to _encode.
   *   index = The position of the first character to _encode.
   *   count = The number of characters to _encode.
   * Returns: A byte array containing the resulting sequence of bytes.
   */
  public abstract ubyte[] encode(char[] chars, int index, int count);

}

/**
 * Converts a sequence of encoded bytes into a set of characters.
 */
public abstract class Decoder {

  /** 
   * Decodes a sequence of _bytes from the specified byte array into a set of characters.
   * Params:
   *   bytes = The byte array containing the sequence of _bytes to _decode.
   *   index = The position of the first byte to _decode.
   *   count = The number of _bytes to _decode.
   * Returns: A character array containing the resulting set of characters.
   */
  public abstract char[] decode(ubyte[] bytes, int index, int count);

}

/**
 * Represents a character encoding.
 */
public abstract class Encoding {

  private static class DefaultEncoder : Encoder {

    private Encoding encoding_;

    public this(Encoding encoding) {
      encoding_ = encoding;
    }

    public override ubyte[] encode(char[] chars, int index, int count) {
      return encoding_.encode(chars, index, count);
    }

  }

  private static class DefaultDecoder : Decoder {

    private Encoding encoding_;

    public this(Encoding encoding) {
      encoding_ = encoding;
    }

    public override char[] decode(ubyte[] bytes, int index, int count) {
      return encoding_.decode(bytes, index, count);
    }

  }

  private const uint CP_DEFAULT = 0;
  private const uint CP_ASCII = 20127;
  private const uint CP_UTF16 = 1200;
  private const uint CP_UTF16BE = 1201;
  private const uint CP_WINDOWS_1252 = 1252;
  private const uint ISO_8859_1 = 28591;

  private static Encoding[uint] encodings_;
  private static Encoding defaultEncoding_;
  private static Encoding asciiEncoding_;
  private static Encoding utf8Encoding_;
  private static Encoding utf7Encoding_;
  private static Encoding utf16Encoding_;

  protected uint codePage_;
  private CodePageInfo* cpInfo_;

  static ~this() {
    encodings_ = null;
    defaultEncoding_ = null;
    asciiEncoding_ = null;
    utf7Encoding_ = null;
    utf8Encoding_ = null;
    utf16Encoding_ = null;
  }

  /**
   * Converts a byte array from one encoding to another.
   * Params:
   *   sourceEncoding = The encoding format of bytes.
   *   destEncoding = The target encoding format.
   *   bytes = The _bytes to _convert.
   * Returns: A byte array containing the results of converting bytes from srcEncoding to destEncoding.
   */
  public static ubyte[] convert(Encoding sourceEncoding, Encoding destEncoding, ubyte[] bytes) {
    return convert(sourceEncoding, destEncoding, bytes, 0, bytes.length);
  }

  /**
   * Converts a range of _bytes in a byte array from one encoding to another.
   * Params:
   *   sourceEncoding = The encoding format of bytes.
   *   destEncoding = The target encoding format.
   *   bytes = The _bytes to _convert.
   *   index = The _index of the first element of bytes to _convert.
   *   count = The number of _bytes to _convert.
   * Returns: A byte array containing the results of converting bytes from srcEncoding to destEncoding.
   */
  public static ubyte[] convert(Encoding sourceEncoding, Encoding destEncoding, ubyte[] bytes, int index, int count) {
    return destEncoding.encode(sourceEncoding.decode(bytes, index, count));
  }

  /**
   * Encodes a set of characters from the specified character array into a sequence of bytes.
   * Params: chars = The character array containing the set of characters to _encode.
   * Returns: A byte array containing the results of encoding the specified set of characters.
   */
  public ubyte[] encode(char[] chars) {
    return encode(chars, 0, chars.length);
  }

  /**
   * Encodes a set of characters from the specified character array into a sequence of bytes.
   * Params: 
   *   chars = The character array containing the set of characters to _encode.
   *   index = The _index of the first character to _encode.
   *   count = The number of characters to _encode.
   * Returns: A byte array containing the results of encoding the specified set of characters.
   */
  public abstract ubyte[] encode(char[] chars, int index, int count);

  /**
   * Decodes a sequence of _bytes from the specified byte array into a set of characters.
   * Params: bytes = The byte array containing the sequence of _bytes to _decode.
   * Returns: A character array containing the results of decoding the specified sequence of _bytes.
   */
  public char[] decode(ubyte[] bytes) {
    return decode(bytes, 0, bytes.length);
  }

  /**
   * Decodes a sequence of _bytes from the specified byte array into a set of characters.
   * Params:
   *   bytes = The byte array containing the sequence of _bytes to _decode.
   *   index = The _index of the first byte to _decode.
   *   count = The number of _bytes to _decode.
   * Returns: A character array containing the results of decoding the specified sequence of _bytes.
   */
  public abstract char[] decode(ubyte[] bytes, int index, int count);

  /**
   * Calculates the maximum number of bytes produced by encoding the specified number of characters.
   * Params: chars = The number of characters to encode.
   * Returns: The maximum number of bytes produced by encoding the specified number of characters.
   */
  public abstract int maxBytes(int chars);

  /**
   * Calculates the maximum number of characters produced by decoding the specified number of _bytes.
   * Params: bytes = The number of _bytes to encode.
   * Returns: The maximum number of characters produced by decoding the specified number of _bytes.
   */
  public abstract int maxChars(int bytes);

  /**
   * Returns an encoding associated with the specified code page identifier.
   * Params: codePage = The code page identifier of the encoding.
   * Returns: The encoding associated with the specified code page.
   */
  public static Encoding get(uint codePage) {
    if (auto value = codePage in encodings_)
      return *value;

    synchronized {
      Encoding enc = null;

      switch (codePage) {
        case CP_ASCII,
          CP_OEMCP,
          CP_MACCP,
          CP_THREAD_ACP:
          enc = Encoding.ASCII;
          break;
        case CP_UTF7:
          enc = Encoding.UTF7;
          break;
        case CP_UTF8:
          enc = Encoding.UTF8;
          break;
        case CP_UTF16:
          enc = Encoding.UTF16;
          break;
        case CP_WINDOWS_1252,
          50227, 54936, 38598, 57002,
          57003, 57004, 57005, 57006,
          57007, 57008, 57009, 57010,
          57011:
          enc = new MLangEncoding(codePage);
          break;
        default:
          CPINFO cpInfo;
          GetCPInfo(codePage, cpInfo);
          if (cpInfo.MaxCharSize == 1 || cpInfo.MaxCharSize == 2) {
            enc = new MLangEncoding(codePage);
            break;
          }
          throw new ArgumentException("Not a supported code page.", "codePage");
      }

      return encodings_[codePage] = enc;
    }
  }

  /**
   * Returns an encoding associated with the specified code page name.
   * Params: name = The code page name of the encoding.
   * Returns: The encoding associated with the specified code page.
   */
  public static Encoding get(string name) {
    return Encoding.get(getCodePageFromName(name));
  }

  /**
   * Obtains an encoder that converts a sequence of characters into an encoded sequence of bytes.
   * Returns: An encoder that converts a sequence of characters into an encoded sequence of bytes.
   */
  public Encoder getEncoder() {
    return new DefaultEncoder(this);
  }

  /**
   * Obtains a decoder that converts an encoded sequence of bytes into a sequence of characters.
   * Returns: An decoder that converts an encoded sequence of bytes into a sequence of characters.
   */
  public Decoder getDecoder() {
    return new DefaultDecoder(this);
  }

  /**
   * Gets an encoding for the system's ANSI code page.
   * Returns: An encoding for the system's ANSI code page.
   */
  public static Encoding DEFAULT() {
    if (defaultEncoding_ is null)
      defaultEncoding_ = Encoding.get(GetACP());
    return defaultEncoding_;
  }

  /**
   * Gets an encoding for the ASCII character set.
   * Returns: An encoding for the ASCII character set.
   */
  public static Encoding ASCII() {
    if (asciiEncoding_ is null)
      asciiEncoding_ = new AscIIEncoding;
    return asciiEncoding_;
  }

  /**
   * Gets an encoding for the UTF-7 format.
   * Returns: An encoding for the UTF-7 format.
   */
  public static Encoding UTF7() {
    if (utf7Encoding_ is null)
      utf7Encoding_ = new Utf7Encoding;
    return utf7Encoding_;
  }

  /**
   * Gets an encoding for the UTF-8 format.
   * Returns: An encoding for the UTF-8 format.
   */
  public static Encoding UTF8() {
    if (utf8Encoding_ is null)
      utf8Encoding_ = new Utf8Encoding;
    return utf8Encoding_;
  }

  /**
   * Gets an encoding for the UTF-16 format using the little endian byte order.
   * Returns: An encoding for the UTF-16 format using the little endian byte order.
   */
  public static Encoding UTF16() {
    if (utf16Encoding_ is null)
      utf16Encoding_ = new Utf16Encoding(false);
    return utf16Encoding_;
  }

  public int codePage() {
    return codePage_;
  }

  /** 
   * Gets a _description of the encoding.
   * Returns: A _description of the encoding.
   */
  public string description() {
    if (cpInfo_ == null)
      cpInfo_ = getCodePageInfo(codePage_);
    return cpInfo_.description;
  }

  /**
   * Gets the name registered with the IANA.
   * Returns: The IANA name.
   */
  public string webName() {
    if (cpInfo_ == null)
      cpInfo_ = getCodePageInfo(codePage_);
    return cpInfo_.webName;
  }

  /** 
   * Gets a name that can be used with mail agent header tags.
   * Returns: A name that can be used with mail agent header tags.
   */
  public string headerName() {
    if (cpInfo_ == null)
      cpInfo_ = getCodePageInfo(codePage_);
    return cpInfo_.headerName;
  }

  /** 
   * Gets a name that can be used with mail agent body tags.
   * Returns: A name that can be used with mail agent body tags.
   */
  public string bodyName() {
    if (cpInfo_ == null)
      cpInfo_ = getCodePageInfo(codePage_);
    return cpInfo_.bodyName;
  }

  public bool isBrowserDisplay() {
    if (cpInfo_ == null)
      cpInfo_ = getCodePageInfo(codePage_);
    return (cpInfo_.flags & MIMECONTF.MIMECONTF_BROWSER) != 0;
  }

  public bool isMailNewsDisplay() {
    if (cpInfo_ == null)
      cpInfo_ = getCodePageInfo(codePage_);
    return (cpInfo_.flags & MIMECONTF.MIMECONTF_MAILNEWS) != 0;
  }

  public bool isBrowserSave() {
    if (cpInfo_ == null)
      cpInfo_ = getCodePageInfo(codePage_);
    return (cpInfo_.flags & MIMECONTF.MIMECONTF_SAVABLE_BROWSER) != 0;
  }

  public bool isMailNewsSave() {
    if (cpInfo_ == null)
      cpInfo_ = getCodePageInfo(codePage_);
    return (cpInfo_.flags & MIMECONTF.MIMECONTF_SAVABLE_MAILNEWS) != 0;
  }

  /**
   * Initialize a new instance that corresponds to the specified code page.
   * Params: codePage = The code page identifier of the encoding.
   */
  protected this(uint codePage) {
    codePage_ = codePage;
  }

}

private final class MLangEncoding : Encoding {

  private int maxChars_;

  public this(uint codePage) {
    super(codePage == 0 ? GetACP() : codePage);
    CPINFO cpInfo;
    if (!GetCPInfo(codePage, cpInfo)) {
      if (codePage == CP_UTF8)
        maxChars_ = 4;
      else if (codePage == CP_UTF7)
        maxChars_ = 5;
    }
    else maxChars_ = cpInfo.MaxCharSize;
  }

  public override ubyte[] encode(char[] chars, int index, int count) {
    if (IsConvertINetStringAvailable(CP_UTF8, codePage_) == S_FALSE)
      return null;

    uint dwMode;
    uint bytesLength;
    uint charsLength = count;
    ConvertINetString(&dwMode, CP_UTF8, codePage_, cast(ubyte*)(chars.ptr + index), &charsLength, null, &bytesLength);

    ubyte[] bytes = new ubyte[bytesLength];
    ConvertINetString(&dwMode, CP_UTF8, codePage_, cast(ubyte*)(chars.ptr + index), &charsLength, bytes.ptr, &bytesLength);

    bytes.length = bytesLength;
    return bytes.dup;
  }

  public override char[] decode(ubyte[] bytes, int index, int count) {
    if (IsConvertINetStringAvailable(CP_UTF8, codePage_) == S_FALSE)
      return null;

    uint dwMode;
    uint charsLength;
    uint bytesLength = count;
    ConvertINetString(&dwMode, codePage_, CP_UTF8, bytes.ptr + index, &bytesLength, null, &charsLength);

    char[] chars = new char[charsLength];
    ConvertINetString(&dwMode, codePage_, CP_UTF8, bytes.ptr + index, &bytesLength, cast(ubyte*)chars.ptr, &charsLength);

    chars.length = charsLength;
    return chars.dup;
  }

  public override int maxBytes(int chars) {
    return chars * maxChars_;
  }

  public override int maxChars(int bytes) {
    return bytes;
  }

}

/**
 * Represents an ASCII encoding of characters.
 */
public class AscIIEncoding : Encoding {

  private Encoding baseEncoding_;

  /**
   * Creates a new instance.
   */
  public this() {
    super(CP_ASCII);
    baseEncoding_ = new MLangEncoding(CP_ASCII);
  }

  /**
   * Encodes a set of characters from the specified character array into a sequence of bytes.
   * Params: 
   *   chars = The character array containing the set of characters to _encode.
   *   index = The _index of the first character to _encode.
   *   count = The number of characters to _encode.
   * Returns: A byte array containing the results of encoding the specified set of characters.
   */
  public override ubyte[] encode(char[] chars, int index, int count) {
    return baseEncoding_.encode(chars, index, count);
  }

  /**
   * Decodes a sequence of _bytes from the specified byte array into a set of characters.
   * Params:
   *   bytes = The byte array containing the sequence of _bytes to _decode.
   *   index = The _index of the first byte to _decode.
   *   count = The number of _bytes to _decode.
   * Returns: A character array containing the results of decoding the specified sequence of _bytes.
   */
  public override char[] decode(ubyte[] bytes, int index, int count) {
    return baseEncoding_.decode(bytes, index, count);
  }

  /**
   * Calculates the maximum number of bytes produced by encoding the specified number of characters.
   * Params: chars = The number of characters to encode.
   * Returns: The maximum number of bytes produced by encoding the specified number of characters.
   */
  public override int maxBytes(int chars) {
    return chars + 1;
  }

  /**
   * Calculates the maximum number of characters produced by decoding the specified number of _bytes.
   * Params: bytes = The number of _bytes to encode.
   * Returns: The maximum number of characters produced by decoding the specified number of _bytes.
   */
  public override int maxChars(int bytes) {
    return bytes;
  }

}

/**
 * Represents a UTF-7 encoding of characters.
 */
public class Utf7Encoding : Encoding {

  private Encoding baseEncoding_;

  /**
   * Creates a new instance.
   */
  public this() {
    super(CP_UTF7);
    baseEncoding_ = new MLangEncoding(CP_UTF7);
  }

  /**
   * Encodes a set of characters from the specified character array into a sequence of bytes.
   * Params: 
   *   chars = The character array containing the set of characters to _encode.
   *   index = The _index of the first character to _encode.
   *   count = The number of characters to _encode.
   * Returns: A byte array containing the results of encoding the specified set of characters.
   */
  public override ubyte[] encode(char[] chars, int index, int count) {
    return baseEncoding_.encode(chars, index, count);
  }

  /**
   * Decodes a sequence of _bytes from the specified byte array into a set of characters.
   * Params:
   *   bytes = The byte array containing the sequence of _bytes to _decode.
   *   index = The _index of the first byte to _decode.
   *   count = The number of _bytes to _decode.
   * Returns: A character array containing the results of decoding the specified sequence of _bytes.
   */
  public override char[] decode(ubyte[] bytes, int index, int count) {
    return baseEncoding_.decode(bytes, index, count);
  }

  /**
   * Calculates the maximum number of bytes produced by encoding the specified number of characters.
   * Params: chars = The number of characters to encode.
   * Returns: The maximum number of bytes produced by encoding the specified number of characters.
   */
  public override int maxBytes(int chars) {
    return (chars * 3) + 2;
  }

  /**
   * Calculates the maximum number of characters produced by decoding the specified number of _bytes.
   * Params: bytes = The number of _bytes to encode.
   * Returns: The maximum number of characters produced by decoding the specified number of _bytes.
   */
  public override int maxChars(int bytes) {
    return (bytes == 0) ? 1 : bytes;
  }

}

/**
 * Represents a UTF-8 encoding of characters.
 */
public class Utf8Encoding : Encoding {

  private Encoding baseEncoding_;

  /**
   * Creates a new instance.
   */
  public this() {
    super(CP_UTF8);
    baseEncoding_ = new MLangEncoding(CP_UTF8);
  }

  /**
   * Encodes a set of characters from the specified character array into a sequence of bytes.
   * Params: 
   *   chars = The character array containing the set of characters to _encode.
   *   index = The _index of the first character to _encode.
   *   count = The number of characters to _encode.
   * Returns: A byte array containing the results of encoding the specified set of characters.
   */
  public override ubyte[] encode(char[] chars, int index, int count) {
    return baseEncoding_.encode(chars, index, count);
  }

  /**
   * Decodes a sequence of _bytes from the specified byte array into a set of characters.
   * Params:
   *   bytes = The byte array containing the sequence of _bytes to _decode.
   *   index = The _index of the first byte to _decode.
   *   count = The number of _bytes to _decode.
   * Returns: A character array containing the results of decoding the specified sequence of _bytes.
   */
  public override char[] decode(ubyte[] bytes, int index, int count) {
    return baseEncoding_.decode(bytes, index, count);
  }

  /**
   * Calculates the maximum number of bytes produced by encoding the specified number of characters.
   * Params: chars = The number of characters to encode.
   * Returns: The maximum number of bytes produced by encoding the specified number of characters.
   */
  public override int maxBytes(int chars) {
    return (chars + 1) * 3;
  }

  /**
   * Calculates the maximum number of characters produced by decoding the specified number of _bytes.
   * Params: bytes = The number of _bytes to encode.
   * Returns: The maximum number of characters produced by decoding the specified number of _bytes.
   */
  public override int maxChars(int bytes) {
    return bytes + 1;
  }

}

/**
 * Represents a UTF-16 encoding of characters.
 */
public class Utf16Encoding : Encoding {

  private Encoding baseEncoding_;

  /**
   * Creates a new instance.
   * Params: bigEndian = true to use the big-endian byte order, or false to use the little-endian byte order.
   */
  public this(bool bigEndian = false) {
    super(bigEndian ? CP_UTF16BE : CP_UTF16);
    baseEncoding_ = new MLangEncoding(codePage_);
  }

  /**
   * Encodes a set of characters from the specified character array into a sequence of bytes.
   * Params: 
   *   chars = The character array containing the set of characters to _encode.
   *   index = The _index of the first character to _encode.
   *   count = The number of characters to _encode.
   * Returns: A byte array containing the results of encoding the specified set of characters.
   */
  public override ubyte[] encode(char[] chars, int index, int count) {
    return baseEncoding_.encode(chars, index, count);
  }

  /**
   * Decodes a sequence of _bytes from the specified byte array into a set of characters.
   * Params:
   *   bytes = The byte array containing the sequence of _bytes to _decode.
   *   index = The _index of the first byte to _decode.
   *   count = The number of _bytes to _decode.
   * Returns: A character array containing the results of decoding the specified sequence of _bytes.
   */
  public override char[] decode(ubyte[] bytes, int index, int count) {
    return baseEncoding_.decode(bytes, index, count);
  }

  /**
   * Calculates the maximum number of bytes produced by encoding the specified number of characters.
   * Params: chars = The number of characters to encode.
   * Returns: The maximum number of bytes produced by encoding the specified number of characters.
   */
  public override int maxBytes(int chars) {
    return (chars + 1) << 1;
  }

  /**
   * Calculates the maximum number of characters produced by decoding the specified number of _bytes.
   * Params: bytes = The number of _bytes to encode.
   * Returns: The maximum number of characters produced by decoding the specified number of _bytes.
   */
  public override int maxChars(int bytes) {
    return (bytes >> 1) + (bytes & 1) + 1;
  }

}