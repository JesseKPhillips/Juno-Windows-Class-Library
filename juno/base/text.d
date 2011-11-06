/**
 * Contains classes representing ASCII, UTF-8 and UTF-16 character encodings.
 *
 * Copyright: (c) 2008 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.base.text;

private import juno.base.core,
  juno.base.string,
  juno.base.native,
  juno.com.core;

private import std.string : icmp, wcslen, format;

// MLang

enum : uint {
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
  mixin(uuid("275c23e3-3747-11d0-9fea-00aa003f8646"));
  int Clone(out IEnumCodePage ppEnum);
  int Next(uint celt, MIMECPINFO* rgelt, out uint pceltFetched);
  int Reset();
  int Skip(uint celt);
}

interface IEnumRfc1766 : IUnknown {
  mixin(uuid("3dc39d1d-c030-11d0-b81b-00c04fc9b31f"));
  int Clone(out IEnumRfc1766 ppEnum);
  int Next(uint celt, RFC1766INFO* rgelt, out uint pceltFetched);
  int Reset();
  int Skip(uint celt);
}

interface IEnumScript : IUnknown {
  mixin(uuid("AE5F1430-388B-11d2-8380-00C04F8F5DA1"));
  int Clone(out IEnumScript ppEnum);
  int Next(uint celt, SCRIPTINFO* rgelt, out uint pceltFetched);
  int Reset();
  int Skip(uint celt);
}

interface IMLangConvertCharset : IUnknown {
  mixin(uuid("d66d6f98-cdaa-11d0-b822-00c04fc9b31f"));
  int Initialize(uint uiSrcCodePage, uint uiDstCodePage, uint dwProperty);
  int GetSourceCodePage(out uint puiSrcCodePage);
  int GetDestinationCodePage(out uint puiDstCodePage);
  int GetProperty(out uint pdwProperty);
  int DoConversion(ubyte* pSrcStr, ref uint pcSrcSize, ubyte* pDstStr, ref uint pcDstSize);
  int DoConversionToUnicode(ubyte* pSrcStr, ref uint pcSrcSize, wchar* pDstStr, ref uint pcDstSize);
  int DoConversionFromUnicode(wchar* pSrcStr, ref uint pcSrcSize, ubyte* pDstStr, ref uint pcDstSize);
}

interface IMultiLanguage : IUnknown {
  mixin(uuid("275c23e1-3747-11d0-9fea-00aa003f8646"));
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
  mixin(uuid("DCCFC164-2B38-11d2-B7EC-00C04F8F5D9A"));
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
  mixin(uuid("4e5868ab-b157-4623-9acc-6a1d9caebe04"));
  int DetectOutboundCodePage(uint dwFlags, wchar* lpWideCharStr, int cchWideChar, uint* puiPreferredCodePages, uint nPreferredCodePages, uint* puiDetectedCodePages, ref uint pnDetectedCodePages, wchar* lpSpecialChar);
  int DetectOutboundCodePageInIStream(uint dwFlags, IStream pStrIn, uint* puiPreferredCodePages, uint nPreferredCodePages, uint* puiDetectedCodePages, wchar* lpSpecialChar);
}

abstract final class CMultiLanguage {
  mixin(uuid("275c23e2-3747-11d0-9fea-00aa003f8646"));
  mixin Interfaces!(IMultiLanguage2);
}

extern(Windows)
alias DllImport!("mlang.dll", "ConvertINetString",
  int function(uint* lpdwMode, uint dwSrcEncoding, uint dwDstEncoding, const(ubyte)* lpSrcStr, uint* lpnSrcSize, ubyte* lpDstStr, uint* lpnDstSize))
  ConvertINetString;

extern(Windows)
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
      scope(exit) tryRelease(mlang);

      IEnumCodePage cp;
      if (SUCCEEDED(mlang.EnumCodePages(MIMECONTF_MIME_LATEST, 0, cp))) {
        scope(exit) tryRelease(cp);

        uint num = 0;
        if (SUCCEEDED(mlang.GetNumberOfCodePageInfo(num)) && num > 0) {
          MIMECPINFO* cpInfo = cast(MIMECPINFO*)CoTaskMemAlloc(num * MIMECPINFO.sizeof);

          uint count = 0;
          if (SUCCEEDED(cp.Next(num, cpInfo, count)) && count > 0) {
            codePageInfoTable.length = count;

            for (uint index = 0; index < count; index++) {
              with (cpInfo[index]) {
                codePageInfoTable[index] = CodePageInfo(
                  uiCodePage, 
                  uiFamilyCodePage, 
                  toUtf8(wszWebCharset.ptr), 
                  toUtf8(wszHeaderCharset.ptr), 
                  toUtf8(wszBodyCharset.ptr), 
                  toUtf8(wszDescription.ptr), 
                  dwFlags);
              }
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
 * Represents a character encoding.
 */
abstract class Encoding {

  private const uint CP_DEFAULT = 0;
  private const uint CP_ASCII = 20127;
  private const uint CP_UTF16 = 1200;
  private const uint CP_UTF16BE = 1201;
  private const uint CP_UTF32 = 12000;
  private const uint CP_UTF32BE = 12001;
  private const uint CP_WINDOWS_1252 = 1252;
  private const uint ISO_8859_1 = 28591;

  private const uint ISO_SIMPLIFIED_CN = 50227;
  private const uint GB18030 = 54936;
  private const uint ISO_8859_8I = 38598;
  private const uint ISCII_DEVANAGARI = 57002;
  private const uint ISCII_BENGALI = 57003;
  private const uint ISCII_TAMIL = 57004;
  private const uint ISCII_TELUGU = 57005;
  private const uint ISCII_ASSEMESE = 57006;
  private const uint ISCII_ORIYA = 57007;
  private const uint ISCII_KANNADA = 57008;
  private const uint ISCII_MALAYALAM = 57009;
  private const uint ISCII_GUJARATHI = 57010;
  private const uint ISCII_PUNJABI = 507011;

  private static Encoding[uint] encodings_;
  private static Encoding defaultEncoding_;
  private static Encoding asciiEncoding_;
  private static Encoding utf8Encoding_;
  private static Encoding utf16Encoding_;

  protected uint codePage_;
  private CodePageInfo* cpInfo_;

  static ~this() {
    defaultEncoding_ = null;
    asciiEncoding_ = null;
    utf8Encoding_ = null;
    utf16Encoding_ = null;
    encodings_ = null;
  }

  /**
   * Converts a byte array from one encoding to another.
   * Params:
   *   sourceEncoding = The encoding format of bytes.
   *   destEncoding = The target encoding format.
   *   bytes = The _bytes to _convert.
   * Returns: A byte array containing the results of converting bytes from srcEncoding to destEncoding.
   */
  static ubyte[] convert(Encoding sourceEncoding, Encoding destEncoding, in ubyte[] bytes) {
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
  static ubyte[] convert(Encoding sourceEncoding, Encoding destEncoding, in ubyte[] bytes, int index, int count) {
    return destEncoding.encode(sourceEncoding.decode(bytes, index, count));
  }

  /**
   * Encodes a set of characters from the specified character array into a sequence of bytes.
   * Params: 
   *   chars = The character array containing the set of characters to _encode.
   *   index = The _index of the first character to _encode.
   *   count = The number of characters to _encode.
   * Returns: A byte array containing the results of encoding the specified set of characters.
   */
  abstract ubyte[] encode(in char[] chars, int index, int count);

  /**
   * ditto
   */
  ubyte[] encode(in char[] chars) {
    return encode(chars, 0, chars.length);
  }

  /**
   * Decodes a sequence of _bytes from the specified byte array into a set of characters.
   * Params:
   *   bytes = The byte array containing the sequence of _bytes to _decode.
   *   index = The _index of the first byte to _decode.
   *   count = The number of _bytes to _decode.
   * Returns: A character array containing the results of decoding the specified sequence of _bytes.
   */
  abstract char[] decode(in ubyte[] bytes, int index, int count);

  /**
   * ditto
   */
  char[] decode(in ubyte[] bytes) {
    return decode(bytes, 0, bytes.length);
  }

  /**
   * Returns an encoding associated with the specified code page identifier.
   * Params: codePage = The code page identifier of the encoding.
   * Returns: The encoding associated with the specified code page.
   */
  static Encoding get(uint codePage) {
    if (auto value = codePage in encodings_)
      return *value;

    synchronized {
      Encoding enc = null;

      switch (codePage) {
        case CP_DEFAULT:
          enc = DEFAULT;
          break;
        case CP_ASCII:
          enc = Encoding.ASCII;
          break;
        case CP_UTF8:
          enc = Encoding.UTF8;
          break;
        case CP_UTF16:
          enc = Encoding.UTF16;
          break;
        case CP_UTF16BE:
          enc = new Utf16Encoding(true);
          break;
        case CP_WINDOWS_1252,
          ISO_SIMPLIFIED_CN, GB18030, ISO_8859_8I, ISCII_DEVANAGARI,
          ISCII_BENGALI, ISCII_TAMIL, ISCII_TELUGU, ISCII_ASSEMESE,
          ISCII_ORIYA, ISCII_KANNADA, ISCII_MALAYALAM, ISCII_GUJARATHI,
          ISCII_PUNJABI:
          enc = new MLangEncoding(codePage);
          break;
        default:
          CPINFO cpi;
          GetCPInfo(codePage, cpi);
          if (cpi.MaxCharSize == 1 || cpi.MaxCharSize == 2) {
            enc = new MLangEncoding(codePage);
            break;
          }
          throw new NotSupportedException(format("%s is not a supported code page.", codePage));
      }

      return encodings_[codePage] = enc;
    }
  }

  /**
   * Returns an encoding associated with the specified code page name.
   * Params: name = The code page name of the encoding.
   * Returns: The encoding associated with the specified code page.
   */
  static Encoding get(string name) {
    return Encoding.get(getCodePageFromName(name));
  }

  /**
   * Gets an encoding for the system's ANSI code page.
   * Returns: An encoding for the system's ANSI code page.
   */
  static Encoding DEFAULT() {
    if (defaultEncoding_ is null)
      defaultEncoding_ = Encoding.get(GetACP());
    return defaultEncoding_;
  }

  /**
   * Gets an encoding for the ASCII character set.
   * Returns: An encoding for the ASCII character set.
   */
  static Encoding ASCII() {
    if (asciiEncoding_ is null)
      asciiEncoding_ = new AscIIEncoding;
    return asciiEncoding_;
  }

  /**
   * Gets an encoding for the UTF-8 format.
   * Returns: An encoding for the UTF-8 format.
   */
  static Encoding UTF8() {
    if (utf8Encoding_ is null)
      utf8Encoding_ = new Utf8Encoding;
    return utf8Encoding_;
  }

  /**
   * Gets an encoding for the UTF-16 format using the little endian byte order.
   * Returns: An encoding for the UTF-16 format using the little endian byte order.
   */
  static Encoding UTF16() {
    if (utf16Encoding_ is null)
      utf16Encoding_ = new Utf16Encoding;
    return utf16Encoding_;
  }

  uint codePage() {
    return codePage_;
  }

  /** 
   * Gets a _description of the encoding.
   * Returns: A _description of the encoding.
   */
  string description() {
    if (cpInfo_ == null)
      cpInfo_ = getCodePageInfo(codePage_);
    return cpInfo_.description;
  }

  /**
   * Gets the name registered with the IANA.
   * Returns: The IANA name.
   */
  string webName() {
    if (cpInfo_ == null)
      cpInfo_ = getCodePageInfo(codePage_);
    return cpInfo_.webName;
  }

  /** 
   * Gets a name that can be used with mail agent header tags.
   * Returns: A name that can be used with mail agent header tags.
   */
  string headerName() {
    if (cpInfo_ == null)
      cpInfo_ = getCodePageInfo(codePage_);
    return cpInfo_.headerName;
  }

  /** 
   * Gets a name that can be used with mail agent body tags.
   * Returns: A name that can be used with mail agent body tags.
   */
  string bodyName() {
    if (cpInfo_ == null)
      cpInfo_ = getCodePageInfo(codePage_);
    return cpInfo_.bodyName;
  }

  bool isBrowserDisplay() {
    if (cpInfo_ == null)
      cpInfo_ = getCodePageInfo(codePage_);
    return (cpInfo_.flags & MIMECONTF_BROWSER) != 0;
  }

  bool isMailNewsDisplay() {
    if (cpInfo_ == null)
      cpInfo_ = getCodePageInfo(codePage_);
    return (cpInfo_.flags & MIMECONTF_MAILNEWS) != 0;
  }

  bool isBrowserSave() {
    if (cpInfo_ == null)
      cpInfo_ = getCodePageInfo(codePage_);
    return (cpInfo_.flags & MIMECONTF_SAVABLE_BROWSER) != 0;
  }

  bool isMailNewsSave() {
    if (cpInfo_ == null)
      cpInfo_ = getCodePageInfo(codePage_);
    return (cpInfo_.flags & MIMECONTF_SAVABLE_MAILNEWS) != 0;
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

  this(uint codePage) {
    super(codePage == 0 ? GetACP() : codePage);
  }

  alias Encoding.encode encode;

  override ubyte[] encode(in char[] chars, int index, int count) {
    if (IsConvertINetStringAvailable(CP_UTF8, codePage_) == S_FALSE)
      throw new ArgumentException("Could not encode.");

    uint dwMode;
    uint bytesLength;
    uint charsLength = count;
    ConvertINetString(&dwMode, CP_UTF8, codePage_, cast(ubyte*)(chars.ptr + index), &charsLength, null, &bytesLength);

    ubyte[] bytes = new ubyte[bytesLength];
    ConvertINetString(&dwMode, CP_UTF8, codePage_, cast(ubyte*)(chars.ptr + index), &charsLength, bytes.ptr, &bytesLength);

    bytes.length = bytesLength;
    return bytes.dup;
  }

  alias Encoding.decode decode;

  override char[] decode(in ubyte[] bytes, int index, int count) {
    if (IsConvertINetStringAvailable(codePage_, CP_UTF8) == S_FALSE)
      throw new ArgumentException("Could not decode.");

    uint dwMode;
    uint charsLength;
    uint bytesLength = count;
    ConvertINetString(&dwMode, codePage_, CP_UTF8, bytes.ptr + index, &bytesLength, null, &charsLength);

    char[] chars = new char[charsLength];
    ConvertINetString(&dwMode, codePage_, CP_UTF8, bytes.ptr + index, &bytesLength, cast(ubyte*)chars.ptr, &charsLength);

    chars.length = charsLength;
    return chars.dup;
  }

}

/**
 * Represents an ASCII encoding of characters.
 */
class AscIIEncoding : Encoding {

  private Encoding baseEncoding_;

  /**
   * Creates a new instance.
   */
  this() {
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
  public override ubyte[] encode(in char[] chars, int index, int count) {
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
  public override char[] decode(in ubyte[] bytes, int index, int count) {
    return baseEncoding_.decode(bytes, index, count);
  }

}

/**
 * Represents a UTF-8 encoding of characters.
 */
class Utf8Encoding : Encoding {

  private Encoding baseEncoding_;

  /**
   * Creates a new instance.
   */
  this() {
    super(CP_UTF8);
    baseEncoding_ = new MLangEncoding(CP_UTF8);
  }

  alias Encoding.encode encode;

  /**
   * Encodes a set of characters from the specified character array into a sequence of bytes.
   * Params: 
   *   chars = The character array containing the set of characters to _encode.
   *   index = The _index of the first character to _encode.
   *   count = The number of characters to _encode.
   * Returns: A byte array containing the results of encoding the specified set of characters.
   */
  override ubyte[] encode(in char[] chars, int index, int count) {
    return baseEncoding_.encode(chars, index, count);
  }

  alias Encoding.decode decode;

  /**
   * Decodes a sequence of _bytes from the specified byte array into a set of characters.
   * Params:
   *   bytes = The byte array containing the sequence of _bytes to _decode.
   *   index = The _index of the first byte to _decode.
   *   count = The number of _bytes to _decode.
   * Returns: A character array containing the results of decoding the specified sequence of _bytes.
   */
  override char[] decode(in ubyte[] bytes, int index, int count) {
    return baseEncoding_.decode(bytes, index, count);
  }

}

/**
 * Represents a UTF-16 encoding of characters.
 */
class Utf16Encoding : Encoding {

  private Encoding baseEncoding_;

  /**
   * Creates a new instance.
   * Params: bigEndian = true to use the big-endian byte order, or false to use the little-endian byte order.
   */
  this(bool bigEndian = false) {
    super(bigEndian ? CP_UTF16BE : CP_UTF16);
    baseEncoding_ = new MLangEncoding(codePage_);
  }

  alias Encoding.encode encode;

  /**
   * Encodes a set of characters from the specified character array into a sequence of bytes.
   * Params: 
   *   chars = The character array containing the set of characters to _encode.
   *   index = The _index of the first character to _encode.
   *   count = The number of characters to _encode.
   * Returns: A byte array containing the results of encoding the specified set of characters.
   */
  override ubyte[] encode(in char[] chars, int index, int count) {
    return baseEncoding_.encode(chars, index, count);
  }

  alias Encoding.decode decode;

  /**
   * Decodes a sequence of _bytes from the specified byte array into a set of characters.
   * Params:
   *   bytes = The byte array containing the sequence of _bytes to _decode.
   *   index = The _index of the first byte to _decode.
   *   count = The number of _bytes to _decode.
   * Returns: A character array containing the results of decoding the specified sequence of _bytes.
   */
  override char[] decode(in ubyte[] bytes, int index, int count) {
    return baseEncoding_.decode(bytes, index, count);
  }

}
