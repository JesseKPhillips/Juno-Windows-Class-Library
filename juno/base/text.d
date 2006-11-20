module juno.base.text;

private import juno.base.core,
  juno.base.string,
  juno.base.win32,
  juno.com.core;
private import std.string : icmp;

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
  int DoConversion(ubyte* pSrcStr, inout uint pcSrcSize, ubyte* pDstStr, inout uint pcDstSize);
  int DoConversionToUnicode(ubyte* pSrcStr, inout uint pcSrcSize, wchar* pDstStr, inout uint pcDstSize);
  int DoConversionFromUnicode(wchar* pSrcStr, inout uint pcSrcSize, ubyte* pDstStr, inout uint pcDstSize);
}

interface IMultiLanguage : IUnknown {
  static GUID IID = { 0x275c23e1, 0x3747, 0x11d0, 0x9f, 0xea, 0x00, 0xaa, 0x00, 0x3f, 0x86, 0x46 };
  int GetNumberOfCodePageInfo(out uint pcCodePage);
  int GetCodePageInfo(uint uiCodePage, out MIMECPINFO pCodePageInfo);
  int GetFamilyCodePage(uint uiCodePage, out uint puiFamilyCodePage);
  int EnumCodePages(uint grfFlags, out IEnumCodePage ppEnumCodePage);
  int GetCharsetInfo(wchar* Charset, out MIMECSETINFO pCharsetInfo);
  int IsConvertible(uint dwSrcEncoding, uint dwDstEncoding);
  int ConvertString(inout uint pdwMode, uint dwSrcEncoding, uint dwDstEncoding, ubyte* pSrcStr, inout uint pcSrcSize, ubyte* pDstStr, inout uint pcDstSize);
  int ConvertStringToUnicode(inout uint pdwMode, uint dwEncoding, ubyte* pSrcStr, inout uint pcSrcSize, wchar* pDstStr, inout uint pcDstSize);
  int ConvertStringFromUnicode(inout uint pdwMode, uint dwEncoding, wchar* pSrcStr, inout uint pcSrcSize, ubyte* pDstStr, inout uint pcDstSize);
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
  int ConvertString(inout uint pdwMode, uint dwSrcEncoding, uint dwDstEncoding, ubyte* pSrcStr, inout uint pcSrcSize, ubyte* pDstStr, inout uint pcDstSize);
  int ConvertStringToUnicode(inout uint pdwMode, uint dwEncoding, ubyte* pSrcStr, inout uint pcSrcSize, wchar* pDstStr, inout uint pcDstSize);
  int ConvertStringFromUnicode(inout uint pdwMode, uint dwEncoding, wchar* pSrcStr, inout uint pcSrcSize, ubyte* pDstStr, inout uint pcDstSize);
  int ConvertStringReset();
  int GetRfc1766FromLcid(uint Locale, out wchar* pbstrRfc1766);
  int GetLcidFromRfc1766(out uint Locale, wchar* bstrRfc1766);
  int EnumRfc1766(out IEnumRfc1766 ppEnumRfc1766);
  int GetRfc1766Info(uint Locale, out RFC1766INFO pRfc1766Info);
  int CreateConvertCharset(uint uiSrcCodePage, uint uiDstCodePage, uint dwProperty, out IMLangConvertCharset ppMLangConvertCharset);
  int ConvertStringInIStream(inout uint pdwMode, uint dwFlag, wchar* lpFallBack, uint dwSrcEncoding, uint dwDstEncoding, IStream pstmIn, IStream pstmOut);
  int ConvertStringToUnicodeEx(uint dwEncoding, ubyte* pSrcStr, inout uint pcSrcSize, wchar* pDstStr, inout uint pcDstSize, uint dwFlag, wchar* lpFallBack);
  int ConvertStringFromUnicodeEx(uint dwEncoding, wchar* pSrcStr, inout uint pcSrcSize, ubyte* pDstStr, inout uint pcDstSize, uint dwFlag, wchar* lpFallBack);
  int DetectCodepageInIStream(uint dwFlag, uint dwPrefWinCodePage, IStream pstmIn, inout DetectEncodingInfo lpEncoding, inout int pcScores);
  int DetectInputCodepage(uint dwFlag, uint dwPrefWinCodePage, ubyte* pSrcStr, inout int pcSrcSize, inout DetectEncodingInfo lpEncoding, inout int pcScores);
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
  int DetectOutboundCodePage(uint dwFlags, wchar* lpWideCharStr, int cchWideChar, uint* puiPreferredCodePages, uint nPreferredCodePages, uint* puiDetectedCodePages, inout uint pnDetectedCodePages, wchar* lpSpecialChar);
  int DetectOutboundCodePageInIStream(uint dwFlags, IStream pStrIn, uint* puiPreferredCodePages, uint nPreferredCodePages, uint* puiDetectedCodePages, wchar* lpSpecialChar);
}

abstract class CMultiLanguage {
  static GUID CLSID = { 0x275c23e2, 0x3747, 0x11d0, 0x9f, 0xea, 0x00, 0xaa, 0x00, 0x3f, 0x86, 0x46 };
  mixin CoInterfaces!(IMultiLanguage2);
}

// Equivalent to IMultiLanguage.ConvertString
extern (Windows)
alias DllImport!("mlang.dll", "ConvertINetString", int function(uint* lpdwMode, uint dwSrcEncoding, uint dwDstEncoding, ubyte* lpSrcStr, uint* lpnSrcSize, ubyte* lpDstStr, uint* lpnDstSize)) ConvertINetString;

// Equivalent to IMultiLanguage.IsConvertible
extern (Windows)
alias DllImport!("mlang.dll", "IsConvertINetStringAvailable", int function(uint dwSrcEncoding, uint dwDstEncoding)) IsConvertINetStringAvailable;

private struct CodePageInfo {
  uint codePage;
  uint familyCodePage;
  char[] webName;
  char[] headerName;
  char[] bodyName;
  char[] description;
  uint flags;
}

private CodePageInfo[] codePageInfoTable_;
private CodePageInfo[uint] codePageInfoByCodePage_;
private uint[char[]] codePageByName_;

static ~this() {
  codePageInfoByCodePage_ = null;
  codePageByName_ = null;
  codePageInfoTable_ = null;
}

void initCodePageInfo() {
  synchronized {
    IMultiLanguage2 mlang = CMultiLanguage.coCreate!(IMultiLanguage2);
    releaseAfter (mlang, {
      IEnumCodePage enumCodePage;
      if (mlang.EnumCodePages(MIMECONTF_MIME_LATEST, LANGIDFROMLCID(GetThreadLocale()), enumCodePage) == S_OK) {
        releaseAfter (enumCodePage, {
          uint fetched;
          int hr;
          MIMECPINFO cp;
          while ((hr = enumCodePage.Next(1, &cp, fetched)) == S_OK) {
            CodePageInfo info;
            info.codePage = cp.uiCodePage;
            info.familyCodePage = cp.uiFamilyCodePage;
            info.webName = cp.wszWebCharset.toUtf8();
            info.headerName = cp.wszHeaderCharset.toUtf8();
            info.bodyName = cp.wszBodyCharset.toUtf8();
            info.description = cp.wszDescription.toUtf8();

            codePageInfoTable_ ~= info;
          }
        });
      }
    });
  }
}

private CodePageInfo* getCodePageInfo(uint codePage) {
  if (codePageInfoTable_ == null)
    initCodePageInfo();

  if (auto ret = codePage in codePageInfoByCodePage_)
    return ret;
  uint cp;
  for (int i = 0; i < codePageInfoTable_.length && (cp = codePageInfoTable_[i].codePage) != 0; i++) {
    if (cp == codePage) {
      codePageInfoByCodePage_[codePage] = codePageInfoTable_[i];
      return &codePageInfoByCodePage_[codePage];
    }
  }
  return null;
}

private uint getCodePageFromName(char[] name) {
  if (codePageInfoTable_ == null)
    initCodePageInfo();

  if (auto ret = name in codePageByName_)
    return *ret;

  for (int i = 0; i < codePageInfoTable_.length; i++) {
    if (icmp(codePageInfoTable_[i].webName, name) == 0 ||
      (codePageInfoTable_[i].codePage == 1200 && icmp("utf-16", name) == 0)) {
      uint codePage = codePageInfoTable_[i].codePage;
      codePageByName_[name] = codePage;
      return codePage;
    }
  }

  throw new ArgumentException("'" ~ name ~ "' not a supported encoding name.", "name");
}

/**
 * <a name="Encoding" />
 * Represents a character encoding.
 */
public abstract class Encoding {

  private const uint CP_DEFAULT = 0;
  private const uint CP_ASCII = 20127;
  private const uint CP_UTF16 = 1200;
  private const uint CP_UTF16BE = 1201;
  private const uint CP_WINDOWS_1252 = 1252;
  private const uint ISO_8859_1 = 28591;

  private static Encoding[uint] encodings_;
  private static Encoding defaultEncoding_;
  private static Encoding asciiEncoding_;
  private static Encoding utf7Encoding_;
  private static Encoding utf8Encoding_;
  private static Encoding utf16Encoding_;
  private static Encoding bigEndianUtf16Encoding_;

  protected uint codePage_;

  static ~this() {
    defaultEncoding_ = null;
    asciiEncoding_ = null;
    defaultEncoding_ = null;
    utf7Encoding_ = null;
    utf8Encoding_ = null;
    utf16Encoding_ = null;
    bigEndianUtf16Encoding_ = null;
    encodings_ = null;
  }

  /**
   * <a name="convert" />
   * Converts an array of _bytes from one encoding to another.
   * Params:
   *        srcEncoding = The encoding format of bytes.
   *        dstEncoding = The target encoding format.
   *        bytes = The _bytes to _convert.
   */
  public static ubyte[] convert(Encoding srcEncoding, Encoding dstEncoding, ubyte[] bytes) {
    return dstEncoding.encode(srcEncoding.decode(bytes));
  }

  /**
   * <a name="encode" />
   * Encodes the characters in the specified character array into a sequence of bytes.
   * Params: chars = The character array containing the characters to _encode.
   */
  public abstract ubyte[] encode(char[] chars);

  /**
   * <a name="decode" />
   * Decodes the _bytes in the specified byte array into a set of characters.
   * Params: bytes = The byte array containing the sequence of _bytes to _decode.
   */
  public abstract char[] decode(ubyte[] bytes);

  /** 
   * <a name="getEncoding(uint)" />
   * Returns the encoding associated with the specified code page identifier.
   * Params: codePage = The code page identifer of the preferred encoding.
   */
  public static Encoding getEncoding(uint codePage) {
    if (auto enc = codePage in encodings_)
      return *enc;

    synchronized {
      Encoding enc = null;
      switch (codePage) {
        case CP_ASCII:
        case CP_OEMCP:
        case CP_MACCP:
        case CP_THREAD_ACP:
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
        case CP_UTF16BE:
          enc = Encoding.UTF16BE;
          break;
        case CP_DEFAULT:
          enc = Encoding.DEFAULT;
          break;
        case CP_WINDOWS_1252:
        case 50227:
        case 54936:
        case 38598:
        case 57002:
        case 57003:
        case 57004:
        case 57005:
        case 57006:
        case 57007:
        case 57008:
        case 57009:
        case 57010:
        case 57011:
          enc = new MLangCodePageEncoding(codePage);
          break;
        default:
          CPINFO cpInfo;
          GetCPInfo(codePage, cpInfo);
          if (cpInfo.MaxCharSize == 1 || cpInfo.MaxCharSize == 2) {
            enc = new MLangCodePageEncoding(codePage);
            break;
          }
          throw new ArgumentException("Not a supported code page.", "codePage");
      }
      return encodings_[codePage] = enc;
    }
  }

  /** 
   * <a name="getEncoding(char[])" />
   * Returns the encoding associated with the specified code page _name.
   * Params: name = The code page _name of the preferred encoding.
   */
  public static Encoding getEncoding(char[] name) {
    return getEncoding(getCodePageFromName(name));
  }

  /**
   * <a name="getEncodings" />
   * Returns an array of all encodings.
   */
  public static EncodingInfo[] getEncodings() {
    if (codePageInfoTable_ == null)
      initCodePageInfo();

    EncodingInfo[] list = new EncodingInfo[codePageInfoTable_.length];
    for (int i = 0; i < codePageInfoTable_.length; i++)
      list[i] = new EncodingInfo(codePageInfoTable_[i].codePage, codePageInfoTable_[i].webName, codePageInfoTable_[i].description);
    return list;
  }

  /**
   * <a name="DEFAULT" />
   * <i>Property.</i>
   * Retrieves an encoding for the systems' current code page.
   */
  public static Encoding DEFAULT() {
    if (defaultEncoding_ is null)
      defaultEncoding_ = getEncoding(GetACP());
    return defaultEncoding_;
  }

  /**
   * <a name="ASCII" />
   * <i>Property.</i>
   * Retrieves an encoding for the _ASCII character set.
   */
  public static Encoding ASCII() {
    if (asciiEncoding_ is null)
      asciiEncoding_ = new AscIIEncoding;
    return asciiEncoding_;
  }

  /**
   * <a name="UTF7" />
   * <i>Property.</i>
   * Retrieves an encoding for the UTF-7 format.
   */
  public static Encoding UTF7() {
    if (utf7Encoding_ is null)
      utf7Encoding_ = new Utf7Encoding;
    return utf7Encoding_;
  }

  /**
   * <a name="UTF8" />
   * <i>Property.</i>
   * Retrieves an encoding for the UTF-8 format.
   */
  public static Encoding UTF8() {
    if (utf8Encoding_ is null)
      utf8Encoding_ = new Utf8Encoding;
    return utf8Encoding_;
  }

  /**
   * <a name="UTF16" />
   * <i>Property.</i>
   * Retrieves an encoding for the UTF-16 format using the little-endian byte order.
   */
  public static Encoding UTF16() {
    if (utf16Encoding_ is null)
      utf16Encoding_ = new Utf16Encoding;
    return utf16Encoding_;
  }

  /**
   * <a name="UTF16BE" />
   * <i>Property.</i>
   * Retrieves an encoding for the UTF-16 format using the big-endian byte order.
   */
  public static Encoding UTF16BE() {
    if (bigEndianUtf16Encoding_ is null)
      bigEndianUtf16Encoding_ = new Utf16Encoding(true);
    return bigEndianUtf16Encoding_;
  }

  /**
   * <a name="codePage" />
   * <i>Property.</i>
   * Retrieves the code page identifier of the current encoding.
   */
  public uint codePage() {
    return codePage_;
  }

  /**
   * <a name="windowsCodePage" />
   * <i>Property.</i>
   * Retrieves the Windows operating system code page identifier of the current encoding.
   */
  public uint windowsCodePage() {
    return getCodePageInfo(codePage_).familyCodePage;
  }

  /**
   * <a name="displayName" />
   * <i>Property.</i>
   * Retrieves the human-readable description of the current encoding.
   */
  public char[] displayName() {
    return getCodePageInfo(codePage_).description;
  }

  /**
   * <a name="webName" />
   * <i>Property.</i>
   * Retrieves the name of the current encoding in a form that can be used with browser clients.
   */
  public char[] webName() {
    return getCodePageInfo(codePage_).webName;
  }

  /**
   * <a name="headerName" />
   * <i>Property.</i>
   * Retrieves the name of the current encoding in a form that can be used with mail agent header tags.
   */
  public char[] headerName() {
    return getCodePageInfo(codePage_).headerName;
  }

  /**
   * <a name="bodyName" />
   * <i>Property.</i>
   * Retrieves the name of the current encoding in a form that can be used with mail agent body tags.
   */
  public char[] bodyName() {
    return getCodePageInfo(codePage_).bodyName;
  }

  /**
   * <a name="isBrowserDisplay" />
   * Retrieves a value indicating whether the current encoding can be used by browser clients for displaying content.
   */
  public bool isBrowserDisplay() {
    return (getCodePageInfo(codePage_).flags & MIMECONTF_BROWSER) != 0;
  }

  /**
   * <a name="isMailNewsDisplay" />
   * Retrieves a value indicating whether the current encoding can be used by mail and news clients for displaying content.
   */
  public bool isMailNewsDisplay() {
    return (getCodePageInfo(codePage_).flags & MIMECONTF_MAILNEWS) != 0;
  }

  /**
   * <a name="isBrowserSave" />
   * Retrieves a value indicating whether the current encoding can be used by browser clients for saving content.
   */
  public bool isBrowserSave() {
    return (getCodePageInfo(codePage_).flags & MIMECONTF_SAVABLE_BROWSER) != 0;
  }

  /**
   * <a name="isMailNewsSave" />
   * Retrieves a value indicating whether the current encoding can be used by mail and news clients for saving content.
   */
  public bool isMailNewsSave() {
    return (getCodePageInfo(codePage_).flags & MIMECONTF_SAVABLE_MAILNEWS) != 0;
  }

  /**
   * <a name="this" />
   * <i>Protected.</i>
   * Creates a new instance corresponding to the specified code page.
   * Params: codePage = The code page identifier of the preferred encoding.
   */
  protected this(uint codePage) {
    codePage_ = codePage;
  }

}

/**
 * <a name="EncodingInfo" />
 * Provides information about an encoding.
 */
public class EncodingInfo {

  private uint codePage_;
  private char[] name_;
  private char[] displayName_;

  /**
   * <i>Property.</i>
   * Retrieves the code page identifier of the encoding.
   */
  public final uint codePage() {
    return codePage_;
  }

  /**
   * <i>Property.</i>
   * Retrieves the _name of the encoding.
   */
  public final char[] name() {
    return name_;
  }

  /**
   * <i>Property.</i>
   * Retrieves the human-readable descriptions of the encoding.
   */
  public final char[] displayName() {
    return displayName_;
  }

  package this(uint codePage, char[] name, char[] displayName) {
    codePage_ = codePage;
    name_ = name;
    displayName_ = displayName;
  }

}

private class MLangCodePageEncoding : Encoding {

  public override ubyte[] encode(char[] chars) {
    if (IsConvertINetStringAvailable(CP_UTF8, codePage_) == S_FALSE)
      return null;

    uint dwMode;
    uint bytesLength;
    uint charsLength = chars.length;
    ConvertINetString(&dwMode, CP_UTF8, codePage_, cast(ubyte*)chars.ptr, &charsLength, null, &bytesLength);

    ubyte[] bytes = new ubyte[bytesLength];
    ConvertINetString(&dwMode, CP_UTF8, codePage_, cast(ubyte*)chars.ptr, &charsLength, bytes, &bytesLength);

    bytes.length = bytesLength;

    return bytes.dup;
  }

  public override char[] decode(ubyte[] bytes) {
    if (IsConvertINetStringAvailable(CP_UTF8, codePage_) == S_FALSE)
      return null;

    uint dwMode;
    uint bytesLength = bytes.length;
    uint charsLength;
    ConvertINetString(&dwMode, codePage_, CP_UTF8, bytes, &bytesLength, null, &charsLength);

    char[] chars = new char[charsLength];
    ConvertINetString(&dwMode, codePage_, CP_UTF8, bytes, &bytesLength, cast(ubyte*)chars.ptr, &charsLength);

    chars.length = charsLength;

    return chars;
  }

  package this(uint codePage) {
    super(codePage);
  }

}

/**
 * <a name="AscIIEncoding" />
 * Represents an ASCII character encoding of Unicode characters.
 */
public class AscIIEncoding : Encoding {

  private Encoding mlangEncoding_;

  public this() {
    super(CP_ASCII);
    mlangEncoding_ = new MLangCodePageEncoding(codePage_);
  }

  /**
   * <i>Overidden.</i>
   * Encodes the characters in the specified character array into a sequence of bytes.
   * Params: chars = The character array containing the characters to _encode.
   */
  public override ubyte[] encode(char[] chars) {
    return mlangEncoding_.encode(chars);
  }

  /**
   * <i>Overidden.</i>
   * Decodes the _bytes in the specified byte array into a set of characters.
   * Params: bytes = The byte array containing the sequence of _bytes to _decode.
   */
  public override char[] decode(ubyte[] bytes) {
    return mlangEncoding_.decode(bytes);
  }

}

/**
 * <a name="Utf7Encoding" />
 * Represents a UTF-7 encoding of Unicode characters.
 */
public class Utf7Encoding : Encoding {

  private Encoding mlangEncoding_;

  public this() {
    super(CP_UTF7);
    mlangEncoding_ = new MLangCodePageEncoding(codePage_);
  }

  /**
   * <i>Overidden.</i>
   * Encodes the characters in the specified character array into a sequence of bytes.
   * Params: chars = The character array containing the characters to _encode.
   */
  public override ubyte[] encode(char[] chars) {
    return mlangEncoding_.encode(chars);
  }

  /**
   * <i>Overidden.</i>
   * Decodes the _bytes in the specified byte array into a set of characters.
   * Params: bytes = The byte array containing the sequence of _bytes to _decode.
   */
  public override char[] decode(ubyte[] bytes) {
    return mlangEncoding_.decode(bytes);
  }

}

/**
 * <a name="Utf8Encoding" />
 * Represents a UTF-8 encoding of Unicode characters.
 */
public class Utf8Encoding : Encoding {

  private Encoding mlangEncoding_;

  public this() {
    super(CP_UTF8);
    mlangEncoding_ = new MLangCodePageEncoding(codePage_);
  }

  /**
   * <i>Overidden.</i>
   * Encodes the characters in the specified character array into a sequence of bytes.
   * Params: chars = The character array containing the characters to _encode.
   */
  public override ubyte[] encode(char[] chars) {
    return mlangEncoding_.encode(chars);
  }

  /**
   * <i>Overidden.</i>
   * Decodes the _bytes in the specified byte array into a set of characters.
   * Params: bytes = The byte array containing the sequence of _bytes to _decode.
   */
  public override char[] decode(ubyte[] bytes) {
    return mlangEncoding_.decode(bytes);
  }

}

/**
 * <a name="Utf16Encoding" />
 * Represents a UTF-16 encoding of Unicode characters.
 */
public class Utf16Encoding : Encoding {

  private Encoding mlangEncoding_;

  public this(bool bigEndian = false) {
    super(bigEndian ? CP_UTF16BE : CP_UTF16);
    mlangEncoding_ = new MLangCodePageEncoding(codePage_);
  }

  /**
   * <i>Overidden.</i>
   * Encodes the characters in the specified character array into a sequence of bytes.
   * Params: chars = The character array containing the characters to _encode.
   */
  public override ubyte[] encode(char[] chars) {
    return mlangEncoding_.encode(chars);
  }

  /**
   * <i>Overidden.</i>
   * Decodes the _bytes in the specified byte array into a set of characters.
   * Params: bytes = The byte array containing the sequence of _bytes to _decode.
   */
  public override char[] decode(ubyte[] bytes) {
    return mlangEncoding_.decode(bytes);
  }

}