module juno.base.win32;

private import juno.base.core;
private import std.utf : toUTF16z, toUTF8;
private import std.traits;

pragma(lib, "advapi32.lib");
pragma(lib, "shlwapi.lib");
pragma(lib, "shell32.lib");

version (Ansi) {
}
else version = Unicode;

extern (Windows):

extern const Handle INVALID_HANDLE_VALUE;

template MAKELANGID(uint p, uint s) {
  const uint MAKELANGID = (((cast(ushort)(s)) << 10) | cast(ushort)(p));
}

template MAKELCID(uint lgid, uint srtid) {
  const uint MAKELCID = (cast(uint)(((cast(uint)(cast(ushort)(srtid))) << 16) | (cast(uint)(cast(ushort)(lgid)))));
}

ushort LANGIDFROMLCID(uint lcid) {
  return cast(ushort)lcid;
}

extern ushort SUBLANGID(uint lgid);
extern ushort PRIMARYLANGID(uint lgid);
extern ushort LOWORD(uint);
extern ushort HIWORD(uint);

ubyte LOBYTE(uint w) {
  return cast(ubyte)(w & 0xff);
}

ubyte HIBYTE(uint w) {
  return cast(ubyte)(w >> 8);
}

enum : uint {
  MAX_PATH = 260
}

enum {
  ERROR_SUCCESS = 0
}

enum : uint {
  STD_INPUT_HANDLE = cast(uint)-10,
  STD_OUTPUT_HANDLE = cast(uint)-11,
  STD_ERROR_HANDLE = cast(uint)-12
}

enum : uint {
  LCID_INSTALLED           = 0x00000001,
  LCID_SUPPORTED           = 0x00000002,
  LCID_ALTERNATE_SORTS     = 0x00000004
}

enum : ushort {
  LANG_NEUTRAL                     = 0x00,
  LANG_INVARIANT                   = 0x7f,
  LANG_AFRIKAANS                  = 0x36,
  LANG_ALBANIAN                   = 0x1c,
  LANG_ARABIC                     = 0x01,
  LANG_ARMENIAN                   = 0x2b,
  LANG_ASSAMESE                   = 0x4d,
  LANG_AZERI                      = 0x2c,
  LANG_BASQUE                     = 0x2d,
  LANG_BELARUSIAN                 = 0x23,
  LANG_BENGALI                    = 0x45,
  LANG_BULGARIAN                  = 0x02,
  LANG_CATALAN                    = 0x03,
  LANG_CHINESE                    = 0x04,
  LANG_CROATIAN                   = 0x1a,
  LANG_CZECH                      = 0x05,
  LANG_DANISH                     = 0x06,
  LANG_DIVEHI                     = 0x65,
  LANG_DUTCH                      = 0x13,
  LANG_ENGLISH                    = 0x09,
  LANG_ESTONIAN                   = 0x25,
  LANG_FAEROESE                   = 0x38,
  LANG_FARSI                      = 0x29,
  LANG_FINNISH                    = 0x0b,
  LANG_FRENCH                     = 0x0c,
  LANG_GALICIAN                   = 0x56,
  LANG_GEORGIAN                   = 0x37,
  LANG_GERMAN                     = 0x07,
  LANG_GREEK                      = 0x08,
  LANG_GUJARATI                   = 0x47,
  LANG_HEBREW                     = 0x0d,
  LANG_HINDI                      = 0x39,
  LANG_HUNGARIAN                  = 0x0e,
  LANG_ICELANDIC                  = 0x0f,
  LANG_INDONESIAN                 = 0x21,
  LANG_ITALIAN                    = 0x10,
  LANG_JAPANESE                    = 0x11,
  LANG_KANNADA                     = 0x4b,
  LANG_KASHMIRI                    = 0x60,
  LANG_KAZAK                       = 0x3f,
  LANG_KONKANI                     = 0x57,
  LANG_KOREAN                      = 0x12,
  LANG_KYRGYZ                      = 0x40,
  LANG_LATVIAN                     = 0x26,
  LANG_LITHUANIAN                  = 0x27,
  LANG_MACEDONIAN                  = 0x2f,
  LANG_MALAY                       = 0x3e,
  LANG_MALAYALAM                   = 0x4c,
  LANG_MANIPURI                    = 0x58,
  LANG_MARATHI                     = 0x4e,
  LANG_MONGOLIAN                   = 0x50,
  LANG_NEPALI                      = 0x61,
  LANG_NORWEGIAN                   = 0x14,
  LANG_ORIYA                       = 0x48,
  LANG_POLISH                      = 0x15,
  LANG_PORTUGUESE                  = 0x16,
  LANG_PUNJABI                     = 0x46,
  LANG_ROMANIAN                    = 0x18,
  LANG_RUSSIAN                     = 0x19,
  LANG_SANSKRIT                    = 0x4f,
  LANG_SERBIAN                     = 0x1a,
  LANG_SINDHI                      = 0x59,
  LANG_SLOVAK                      = 0x1b,
  LANG_SLOVENIAN                   = 0x24,
  LANG_SPANISH                     = 0x0a,
  LANG_SWAHILI                     = 0x41,
  LANG_SWEDISH                     = 0x1d,
  LANG_SYRIAC                      = 0x5a,
  LANG_TAMIL                       = 0x49,
  LANG_TATAR                       = 0x44,
  LANG_TELUGU                      = 0x4a,
  LANG_THAI                        = 0x1e,
  LANG_TURKISH                     = 0x1f,
  LANG_UKRAINIAN                   = 0x22,
  LANG_URDU                        = 0x20,
  LANG_UZBEK                       = 0x43,
  LANG_VIETNAMESE                  = 0x2a
}

enum : ushort {
  SUBLANG_NEUTRAL                  = 0x00,
  SUBLANG_DEFAULT                  = 0x01,
  SUBLANG_SYS_DEFAULT              = 0x02,
  SUBLANG_ARABIC_SAUDI_ARABIA      = 0x01,
  SUBLANG_ARABIC_IRAQ              = 0x02,
  SUBLANG_ARABIC_EGYPT             = 0x03,
  SUBLANG_ARABIC_LIBYA             = 0x04,
  SUBLANG_ARABIC_ALGERIA           = 0x05,
  SUBLANG_ARABIC_MOROCCO           = 0x06,
  SUBLANG_ARABIC_TUNISIA           = 0x07,
  SUBLANG_ARABIC_OMAN              = 0x08,
  SUBLANG_ARABIC_YEMEN             = 0x09,
  SUBLANG_ARABIC_SYRIA             = 0x0a,
  SUBLANG_ARABIC_JORDAN            = 0x0b,
  SUBLANG_ARABIC_LEBANON           = 0x0c,
  SUBLANG_ARABIC_KUWAIT            = 0x0d,
  SUBLANG_ARABIC_UAE               = 0x0e,
  SUBLANG_ARABIC_BAHRAIN           = 0x0f,
  SUBLANG_ARABIC_QATAR             = 0x10,
  SUBLANG_AZERI_LATIN              = 0x01,
  SUBLANG_AZERI_CYRILLIC           = 0x02,
  SUBLANG_CHINESE_TRADITIONAL      = 0x01,
  SUBLANG_CHINESE_SIMPLIFIED       = 0x02,
  SUBLANG_CHINESE_HONGKONG         = 0x03,
  SUBLANG_CHINESE_SINGAPORE        = 0x04,
  SUBLANG_CHINESE_MACAU            = 0x05,
  SUBLANG_DUTCH                    = 0x01,
  SUBLANG_DUTCH_BELGIAN            = 0x02,
  SUBLANG_ENGLISH_US               = 0x01,
  SUBLANG_ENGLISH_UK               = 0x02,
  SUBLANG_ENGLISH_AUS              = 0x03,
  SUBLANG_ENGLISH_CAN              = 0x04,
  SUBLANG_ENGLISH_NZ               = 0x05,
  SUBLANG_ENGLISH_EIRE             = 0x06,
  SUBLANG_ENGLISH_SOUTH_AFRICA     = 0x07,
  SUBLANG_ENGLISH_JAMAICA          = 0x08,
  SUBLANG_ENGLISH_CARIBBEAN        = 0x09,
  SUBLANG_ENGLISH_BELIZE           = 0x0a,
  SUBLANG_ENGLISH_TRINIDAD         = 0x0b,
  SUBLANG_ENGLISH_ZIMBABWE         = 0x0c,
  SUBLANG_ENGLISH_PHILIPPINES      = 0x0d,
  SUBLANG_FRENCH                   = 0x01,
  SUBLANG_FRENCH_BELGIAN           = 0x02,
  SUBLANG_FRENCH_CANADIAN          = 0x03,
  SUBLANG_FRENCH_SWISS             = 0x04,
  SUBLANG_FRENCH_LUXEMBOURG        = 0x05,
  SUBLANG_FRENCH_MONACO            = 0x06,
  SUBLANG_GERMAN                   = 0x01,
  SUBLANG_GERMAN_SWISS             = 0x02,
  SUBLANG_GERMAN_AUSTRIAN          = 0x03,
  SUBLANG_GERMAN_LUXEMBOURG        = 0x04,
  SUBLANG_GERMAN_LIECHTENSTEIN     = 0x05,
  SUBLANG_ITALIAN                  = 0x01,
  SUBLANG_ITALIAN_SWISS            = 0x02,
  SUBLANG_KASHMIRI_SASIA           = 0x02,
  SUBLANG_KASHMIRI_INDIA           = 0x02,
  SUBLANG_KOREAN                   = 0x01,
  SUBLANG_LITHUANIAN               = 0x01,
  SUBLANG_MALAY_MALAYSIA           = 0x01,
  SUBLANG_MALAY_BRUNEI_DARUSSALAM  = 0x02,
  SUBLANG_NEPALI_INDIA             = 0x02,
  SUBLANG_NORWEGIAN_BOKMAL         = 0x01,
  SUBLANG_NORWEGIAN_NYNORSK        = 0x02,
  SUBLANG_PORTUGUESE               = 0x02,
  SUBLANG_PORTUGUESE_BRAZILIAN     = 0x01,
  SUBLANG_SERBIAN_LATIN            = 0x02,
  SUBLANG_SERBIAN_CYRILLIC         = 0x03,
  SUBLANG_SPANISH                  = 0x01,
  SUBLANG_SPANISH_MEXICAN          = 0x02,
  SUBLANG_SPANISH_MODERN           = 0x03,
  SUBLANG_SPANISH_GUATEMALA        = 0x04,
  SUBLANG_SPANISH_COSTA_RICA       = 0x05,
  SUBLANG_SPANISH_PANAMA           = 0x06,
  SUBLANG_SPANISH_DOMINICAN_REPUBLIC = 0x07,
  SUBLANG_SPANISH_VENEZUELA        = 0x08,
  SUBLANG_SPANISH_COLOMBIA         = 0x09,
  SUBLANG_SPANISH_PERU             = 0x0a,
  SUBLANG_SPANISH_ARGENTINA        = 0x0b,
  SUBLANG_SPANISH_ECUADOR          = 0x0c,
  SUBLANG_SPANISH_CHILE            = 0x0d,
  SUBLANG_SPANISH_URUGUAY          = 0x0e,
  SUBLANG_SPANISH_PARAGUAY         = 0x0f,
  SUBLANG_SPANISH_BOLIVIA          = 0x10,
  SUBLANG_SPANISH_EL_SALVADOR      = 0x11,
  SUBLANG_SPANISH_HONDURAS         = 0x12,
  SUBLANG_SPANISH_NICARAGUA        = 0x13,
  SUBLANG_SPANISH_PUERTO_RICO      = 0x14,
  SUBLANG_SWEDISH                  = 0x01,
  SUBLANG_SWEDISH_FINLAND          = 0x02,
  SUBLANG_URDU_PAKISTAN            = 0x01,
  SUBLANG_URDU_INDIA               = 0x02,
  SUBLANG_UZBEK_LATIN              = 0x01,
  SUBLANG_UZBEK_CYRILLIC           = 0x02
}

enum : uint {
  SORT_DEFAULT                     = 0x0
}

enum : uint {
  LANG_SYSTEM_DEFAULT = MAKELANGID!(LANG_NEUTRAL, SUBLANG_SYS_DEFAULT),
  LANG_USER_DEFAULT = MAKELANGID!(LANG_NEUTRAL, SUBLANG_DEFAULT),
  LOCALE_SYSTEM_DEFAULT = MAKELCID!(LANG_SYSTEM_DEFAULT, SORT_DEFAULT),
  LOCALE_USER_DEFAULT = MAKELCID!(LANG_USER_DEFAULT, SORT_DEFAULT),
  LOCALE_NEUTRAL = MAKELCID!(MAKELANGID!(LANG_NEUTRAL, SUBLANG_NEUTRAL), SORT_DEFAULT),
  LOCALE_INVARIANT = MAKELCID!(MAKELANGID!(LANG_INVARIANT, SUBLANG_NEUTRAL), SORT_DEFAULT)
}

enum : uint {
  LOCALE_NOUSEROVERRIDE         = 0x80000000,
  LOCALE_USE_CP_ACP             = 0x40000000,
  LOCALE_RETURN_NUMBER          = 0x20000000,
  LOCALE_ILANGUAGE              = 0x00000001,
  LOCALE_SLANGUAGE              = 0x00000002,
  LOCALE_SENGLANGUAGE           = 0x00001001,
  LOCALE_SABBREVLANGNAME        = 0x00000003,
  LOCALE_SNATIVELANGNAME        = 0x00000004,
  LOCALE_ICOUNTRY               = 0x00000005,
  LOCALE_SCOUNTRY               = 0x00000006,
  LOCALE_SENGCOUNTRY            = 0x00001002,
  LOCALE_SABBREVCTRYNAME        = 0x00000007,
  LOCALE_SNATIVECTRYNAME        = 0x00000008,
  LOCALE_IDEFAULTLANGUAGE       = 0x00000009,
  LOCALE_IDEFAULTCOUNTRY        = 0x0000000A,
  LOCALE_IDEFAULTCODEPAGE       = 0x0000000B,
  LOCALE_IDEFAULTANSICODEPAGE   = 0x00001004,
  LOCALE_IDEFAULTMACCODEPAGE    = 0x00001011,
  LOCALE_SLIST                  = 0x0000000C,
  LOCALE_IMEASURE               = 0x0000000D,
  LOCALE_SDECIMAL               = 0x0000000E,
  LOCALE_STHOUSAND              = 0x0000000F,
  LOCALE_SGROUPING              = 0x00000010,
  LOCALE_IDIGITS                = 0x00000011,
  LOCALE_ILZERO                 = 0x00000012,
  LOCALE_INEGNUMBER             = 0x00001010,
  LOCALE_SNATIVEDIGITS          = 0x00000013,
  LOCALE_SCURRENCY              = 0x00000014,
  LOCALE_SINTLSYMBOL            = 0x00000015,
  LOCALE_SMONDECIMALSEP         = 0x00000016,
  LOCALE_SMONTHOUSANDSEP        = 0x00000017,
  LOCALE_SMONGROUPING           = 0x00000018,
  LOCALE_ICURRDIGITS            = 0x00000019,
  LOCALE_IINTLCURRDIGITS        = 0x0000001A,
  LOCALE_ICURRENCY              = 0x0000001B,
  LOCALE_INEGCURR               = 0x0000001C,
  LOCALE_SDATE                  = 0x0000001D,
  LOCALE_STIME                  = 0x0000001E,
  LOCALE_SSHORTDATE             = 0x0000001F,
  LOCALE_SLONGDATE              = 0x00000020,
  LOCALE_STIMEFORMAT            = 0x00001003,
  LOCALE_IDATE                  = 0x00000021,
  LOCALE_ILDATE                 = 0x00000022,
  LOCALE_ITIME                  = 0x00000023,
  LOCALE_ITIMEMARKPOSN          = 0x00001005,
  LOCALE_ICENTURY               = 0x00000024,
  LOCALE_ITLZERO                = 0x00000025,
  LOCALE_IDAYLZERO              = 0x00000026,
  LOCALE_IMONLZERO              = 0x00000027,
  LOCALE_S1159                  = 0x00000028,
  LOCALE_S2359                  = 0x00000029,
  LOCALE_ICALENDARTYPE          = 0x00001009,
  LOCALE_IOPTIONALCALENDAR      = 0x0000100B,
  LOCALE_IFIRSTDAYOFWEEK        = 0x0000100C,
  LOCALE_IFIRSTWEEKOFYEAR       = 0x0000100D,
  LOCALE_SDAYNAME1              = 0x0000002A,
  LOCALE_SDAYNAME2              = 0x0000002B,
  LOCALE_SDAYNAME3              = 0x0000002C,
  LOCALE_SDAYNAME4              = 0x0000002D,
  LOCALE_SDAYNAME5              = 0x0000002E,
  LOCALE_SDAYNAME6              = 0x0000002F,
  LOCALE_SDAYNAME7              = 0x00000030,
  LOCALE_SABBREVDAYNAME1        = 0x00000031,
  LOCALE_SABBREVDAYNAME2        = 0x00000032,
  LOCALE_SABBREVDAYNAME3        = 0x00000033,
  LOCALE_SABBREVDAYNAME4        = 0x00000034,
  LOCALE_SABBREVDAYNAME5        = 0x00000035,
  LOCALE_SABBREVDAYNAME6        = 0x00000036,
  LOCALE_SABBREVDAYNAME7        = 0x00000037,
  LOCALE_SMONTHNAME1            = 0x00000038,
  LOCALE_SMONTHNAME2            = 0x00000039,
  LOCALE_SMONTHNAME3            = 0x0000003A,
  LOCALE_SMONTHNAME4            = 0x0000003B,
  LOCALE_SMONTHNAME5            = 0x0000003C,
  LOCALE_SMONTHNAME6            = 0x0000003D,
  LOCALE_SMONTHNAME7            = 0x0000003E,
  LOCALE_SMONTHNAME8            = 0x0000003F,
  LOCALE_SMONTHNAME9            = 0x00000040,
  LOCALE_SMONTHNAME10           = 0x00000041,
  LOCALE_SMONTHNAME11           = 0x00000042,
  LOCALE_SMONTHNAME12           = 0x00000043,
  LOCALE_SMONTHNAME13           = 0x0000100E,
  LOCALE_SABBREVMONTHNAME1      = 0x00000044,
  LOCALE_SABBREVMONTHNAME2      = 0x00000045,
  LOCALE_SABBREVMONTHNAME3      = 0x00000046,
  LOCALE_SABBREVMONTHNAME4      = 0x00000047,
  LOCALE_SABBREVMONTHNAME5      = 0x00000048,
  LOCALE_SABBREVMONTHNAME6      = 0x00000049,
  LOCALE_SABBREVMONTHNAME7      = 0x0000004A,
  LOCALE_SABBREVMONTHNAME8      = 0x0000004B,
  LOCALE_SABBREVMONTHNAME9      = 0x0000004C,
  LOCALE_SABBREVMONTHNAME10     = 0x0000004D,
  LOCALE_SABBREVMONTHNAME11     = 0x0000004E,
  LOCALE_SABBREVMONTHNAME12     = 0x0000004F,
  LOCALE_SABBREVMONTHNAME13     = 0x0000100F,
  LOCALE_SPOSITIVESIGN          = 0x00000050,
  LOCALE_SNEGATIVESIGN          = 0x00000051,
  LOCALE_IPOSSIGNPOSN           = 0x00000052,
  LOCALE_INEGSIGNPOSN           = 0x00000053,
  LOCALE_IPOSSYMPRECEDES        = 0x00000054,
  LOCALE_IPOSSEPBYSPACE         = 0x00000055,
  LOCALE_INEGSYMPRECEDES        = 0x00000056,
  LOCALE_INEGSEPBYSPACE         = 0x00000057,
  LOCALE_FONTSIGNATURE          = 0x00000058,
  LOCALE_SISO639LANGNAME        = 0x00000059,
  LOCALE_SISO3166CTRYNAME       = 0x0000005A,
  LOCALE_IGEOID                 = 0x0000005B, // XP
  LOCALE_IDEFAULTEBCDICCODEPAGE = 0x00001012,
  LOCALE_IPAPERSIZE             = 0x0000100A,
  LOCALE_SENGCURRNAME           = 0x00001007,
  LOCALE_SNATIVECURRNAME        = 0x00001008,
  LOCALE_SYEARMONTH             = 0x00001006,
  LOCALE_SSORTNAME              = 0x00001013,
  LOCALE_IDIGITSUBSTITUTION     = 0x00001014
}

enum : uint {
  GEO_NATION              = 0x0001,
  GEO_LATITUDE            = 0x0002,
  GEO_LONGITUDE           = 0x0003,
  GEO_ISO2                = 0x0004,
  GEO_ISO3                = 0x0005,
  GEO_RFC1766             = 0x0006,
  GEO_LCID                = 0x0007,
  GEO_FRIENDLYNAME        = 0x0008,
  GEO_OFFICIALNAME        = 0x0009,
  GEO_TIMEZONES           = 0x000A,
  GEO_OFFICIALLANGUAGES   = 0x000B,
}

enum : uint {
  GEOCLASS_NATION = 16,
  GEOCLASS_REGION = 14
}

enum : uint {
  CAL_NOUSEROVERRIDE        = LOCALE_NOUSEROVERRIDE,
  CAL_RETURN_NUMBER         = LOCALE_RETURN_NUMBER,
  CAL_ICALINTVALUE          = 0x00000001,
  CAL_SCALNAME              = 0x00000002,
  CAL_IYEAROFFSETRANGE      = 0x00000003,
  CAL_SERASTRING            = 0x00000004,
  CAL_SSHORTDATE            = 0x00000005,
  CAL_SLONGDATE             = 0x00000006,
  CAL_SDAYNAME1             = 0x00000007,
  CAL_SDAYNAME2             = 0x00000008,
  CAL_SDAYNAME3             = 0x00000009,
  CAL_SDAYNAME4             = 0x0000000a,
  CAL_SDAYNAME5             = 0x0000000b,
  CAL_SDAYNAME6             = 0x0000000c,
  CAL_SDAYNAME7             = 0x0000000d,
  CAL_SABBREVDAYNAME1       = 0x0000000e,
  CAL_SABBREVDAYNAME2       = 0x0000000f,
  CAL_SABBREVDAYNAME3       = 0x00000010,
  CAL_SABBREVDAYNAME4       = 0x00000011,
  CAL_SABBREVDAYNAME5       = 0x00000012,
  CAL_SABBREVDAYNAME6       = 0x00000013,
  CAL_SABBREVDAYNAME7       = 0x00000014,
  CAL_SMONTHNAME1           = 0x00000015,
  CAL_SMONTHNAME2           = 0x00000016,
  CAL_SMONTHNAME3           = 0x00000017,
  CAL_SMONTHNAME4           = 0x00000018,
  CAL_SMONTHNAME5           = 0x00000019,
  CAL_SMONTHNAME6           = 0x0000001a,
  CAL_SMONTHNAME7           = 0x0000001b,
  CAL_SMONTHNAME8           = 0x0000001c,
  CAL_SMONTHNAME9           = 0x0000001d,
  CAL_SMONTHNAME10          = 0x0000001e,
  CAL_SMONTHNAME11          = 0x0000001f,
  CAL_SMONTHNAME12          = 0x00000020,
  CAL_SMONTHNAME13          = 0x00000021,
  CAL_SABBREVMONTHNAME1     = 0x00000022,
  CAL_SABBREVMONTHNAME2     = 0x00000023,
  CAL_SABBREVMONTHNAME3     = 0x00000024,
  CAL_SABBREVMONTHNAME4     = 0x00000025,
  CAL_SABBREVMONTHNAME5     = 0x00000026,
  CAL_SABBREVMONTHNAME6     = 0x00000027,
  CAL_SABBREVMONTHNAME7     = 0x00000028,
  CAL_SABBREVMONTHNAME8     = 0x00000029,
  CAL_SABBREVMONTHNAME9     = 0x0000002a,
  CAL_SABBREVMONTHNAME10    = 0x0000002b,
  CAL_SABBREVMONTHNAME11    = 0x0000002c,
  CAL_SABBREVMONTHNAME12    = 0x0000002d,
  CAL_SABBREVMONTHNAME13    = 0x0000002e,
  CAL_SYEARMONTH            = 0x0000002f,
  CAL_ITWODIGITYEARMAX      = 0x00000030,
  ENUM_ALL_CALENDARS        = 0xffffffff
}

enum {
  CAL_GREGORIAN                 = 1,
  CAL_GREGORIAN_US              = 2,
  CAL_JAPAN                     = 3,
  CAL_TAIWAN                    = 4,
  CAL_KOREA                     = 5,
  CAL_HIJRI                     = 6,
  CAL_THAI                      = 7,
  CAL_HEBREW                    = 8,
  CAL_GREGORIAN_ME_FRENCH       = 9,
  CAL_GREGORIAN_ARABIC          = 10,
  CAL_GREGORIAN_XLIT_ENGLISH    = 11,
  CAL_GREGORIAN_XLIT_FRENCH     = 12
}

enum : uint {
  TIME_NOMINUTESORSECONDS  = 0x00000001,
  TIME_NOSECONDS           = 0x00000002,
  TIME_NOTIMEMARKER        = 0x00000004,
  TIME_FORCE24HOURFORMAT   = 0x00000008
}

enum : uint {
  DATE_SHORTDATE           = 0x00000001,
  DATE_LONGDATE            = 0x00000002,
  DATE_USE_ALT_CALENDAR    = 0x00000004,
  DATE_YEARMONTH           = 0x00000008,
  DATE_LTRREADING          = 0x00000010,
  DATE_RTLREADING          = 0x00000020
}

enum : uint {
  LCMAP_LOWERCASE           = 0x00000100,
  LCMAP_UPPERCASE           = 0x00000200,
  LCMAP_SORTKEY             = 0x00000400,
  LCMAP_BYTEREV             = 0x00000800,
  LCMAP_HIRAGANA            = 0x00100000,
  LCMAP_KATAKANA            = 0x00200000,
  LCMAP_HALFWIDTH           = 0x00400000,
  LCMAP_FULLWIDTH           = 0x00800000,
  LCMAP_LINGUISTIC_CASING   = 0x01000000,
  LCMAP_SIMPLIFIED_CHINESE  = 0x02000000,
  LCMAP_TRADITIONAL_CHINESE = 0x04000000
}

enum : uint {
  NORM_IGNORECASE         = 0x00000001,
  NORM_IGNORENONSPACE     = 0x00000002,
  NORM_IGNORESYMBOLS      = 0x00000004,
  NORM_IGNOREKANATYPE     = 0x00010000,
  NORM_IGNOREWIDTH        = 0x00020000,
  SORT_STRINGSORT         = 0x00001000
}

enum : Handle {
  HKEY_CLASSES_ROOT         = 0x80000000,
  HKEY_CURRENT_USER         = 0x80000001,
  HKEY_LOCAL_MACHINE        = 0x80000002,
  HKEY_USERS                = 0x80000003,
  HKEY_PERFORMANCE_DATA     = 0x80000004,
  HKEY_CURRENT_CONFIG       = 0x80000005,
  HKEY_DYN_DATA             = 0x80000006,
  HKEY_PERFORMANCE_TEXT     = 0x80000050,
  HKEY_PERFORMANCE_NLSTEXT  = 0x80000060
}

enum {
  DELETE                    = 0x00010000,
  READ_CONTROL              = 0x00020000,
  WRITE_DAC                 = 0x00040000,
  WRITE_OWNER               = 0x00080000,
  SYNCHRONIZE               = 0x00100000,
  STANDARD_RIGHTS_REQUIRED  = 0x000F0000,
  STANDARD_RIGHTS_READ      = READ_CONTROL,
  STANDARD_RIGHTS_WRITE     = READ_CONTROL,
  STANDARD_RIGHTS_EXECUTE   = READ_CONTROL,
  STANDARD_RIGHTS_ALL       = 0x001F0000,
  SPECIFIC_RIGHTS_ALL       = 0x0000FFFF
}

enum : uint {
  KEY_QUERY_VALUE         = 0x0001,
  KEY_SET_VALUE           = 0x0002,
  KEY_CREATE_SUB_KEY      = 0x0004,
  KEY_ENUMERATE_SUB_KEYS  = 0x0008,
  KEY_NOTIFY              = 0x0010,
  KEY_CREATE_LINK         = 0x0020,
  KEY_READ                = (STANDARD_RIGHTS_READ | KEY_QUERY_VALUE | KEY_ENUMERATE_SUB_KEYS | KEY_NOTIFY) & ~SYNCHRONIZE,
  KEY_WRITE               = (STANDARD_RIGHTS_WRITE | KEY_SET_VALUE | KEY_CREATE_SUB_KEY) & ~SYNCHRONIZE,
  KEY_ALL_ACCESS          = (STANDARD_RIGHTS_ALL | KEY_QUERY_VALUE | KEY_SET_VALUE | KEY_CREATE_SUB_KEY | KEY_ENUMERATE_SUB_KEYS | KEY_NOTIFY | KEY_CREATE_LINK) & ~SYNCHRONIZE
}

enum : uint {
  REG_NONE,
  REG_SZ,
  REG_EXPAND_SZ,
  REG_BINARY,
  REG_DWORD,
  REG_DWORD_LITTLE_ENDIAN = REG_DWORD,
  REG_DWORD_BIG_ENDIAN,
  REG_LINK,
  REG_MULTI_SZ,
  REG_RESOURCE_LIST,
  REG_FULL_RESOURCE_DESCRIPTOR,
  REG_RESOURCE_REQUIREMENTS_LIST,
  REG_QWORD,
  REG_QWORD_LITTLE_ENDIAN = REG_QWORD
}

enum : uint {
  FORMAT_MESSAGE_ALLOCATE_BUFFER = 0x00000100,
  FORMAT_MESSAGE_IGNORE_INSERTS  = 0x00000200,
  FORMAT_MESSAGE_FROM_STRING     = 0x00000400,
  FORMAT_MESSAGE_FROM_HMODULE    = 0x00000800,
  FORMAT_MESSAGE_FROM_SYSTEM     = 0x00001000,
  FORMAT_MESSAGE_ARGUMENT_ARRAY  = 0x00002000,
  FORMAT_MESSAGE_MAX_WIDTH_MASK  = 0x000000FF 
}

enum : uint {
  CP_ACP                   = 0,
  CP_OEMCP                 = 1,
  CP_MACCP                 = 2,
  CP_THREAD_ACP            = 3,
  CP_UTF7                  = 65000,
  CP_UTF8                  = 65001
}

enum : uint {
  CTRL_C_EVENT = 0,
  CTRL_BREAK_EVENT = 1
}

enum : uint {
  TLS_OUT_OF_INDEXES = 0xFFFFFFFF
}

enum : uint {
  SEE_MASK_CLASSNAME         = 0x00000001,
  SEE_MASK_CLASSKEY          = 0x00000003,
  SEE_MASK_IDLIST            = 0x00000004,
  SEE_MASK_INVOKEIDLIST      = 0x0000000c,
  SEE_MASK_ICON              = 0x00000010,
  SEE_MASK_HOTKEY            = 0x00000020,
  SEE_MASK_NOCLOSEPROCESS    = 0x00000040,
  SEE_MASK_CONNECTNETDRV     = 0x00000080,
  SEE_MASK_FLAG_DDEWAIT      = 0x00000100,
  SEE_MASK_DOENVSUBST        = 0x00000200,
  SEE_MASK_FLAG_NO_UI        = 0x00000400,
  SEE_MASK_UNICODE           = 0x00004000,
  SEE_MASK_NO_CONSOLE        = 0x00008000,
  SEE_MASK_ASYNCOK           = 0x00100000,
  SEE_MASK_HMONITOR          = 0x00200000
}

enum : uint {
  VER_PLATFORM_WIN32s            = 0,
  VER_PLATFORM_WIN32_WINDOWS     = 1,
  VER_PLATFORM_WIN32_NT          = 2
}

struct FILETIME {
  uint dwLowDateTime;
  uint dwHighDateTime;
}

struct SYSTEMTIME {
  ushort wYear;
  ushort wMonth;
  ushort wDayOfWeek;
  ushort wDay;
  ushort wHour;
  ushort wMinute;
  ushort wSecond;
  ushort wMilliseconds;
}

struct TIME_ZONE_INFORMATION {
  int Bias;
  wchar[32] StandardName;
  SYSTEMTIME StandardDate;
  int StandardBias;
  wchar[32] DaylightName;
  SYSTEMTIME DaylightDate;
  int DaylightBias;
}

// Vista
struct DYNAMIC_TIME_ZONE_INFORMATION {
  int Bias;
  wchar[32] StandardName;
  SYSTEMTIME StandardDate;
  int StandardBias;
  wchar[32] DaylightName;
  SYSTEMTIME DaylightDate;
  int DaylightBias;
  wchar[128] TimeZoneKeyName;
  int DynamicDaylightTimeDisabled;
}

struct REG_TIME_ZONE_INFORMATION {
  int Bias;
  int StandardBias;
  int DaylightBias;
  SYSTEMTIME StandardDate;
  SYSTEMTIME DaylightDate;
}

struct OVERLAPPED {
  uint Internal;
  uint InternalHigh;
  union {
    struct {
      uint Offset;
      uint OffsetHigh;
    }
    void* Pointer;
  }
  Handle hEvent;
}

struct SECURITY_ATTRIBUTES {
  uint nLength;
  void* lpSecurityDescriptor;
  int bInheritHandle;
}

struct LIST_ENTRY {
  LIST_ENTRY* Flink;
  LIST_ENTRY* Blink;
}

struct CRITICAL_SECTION_DEBUG {
  ushort Type;
  ushort CreatorBackTraceIndex;
  CRITICAL_SECTION* CriticalSection;
  LIST_ENTRY ProcessLocksList;
  uint EntryCount;
  uint ContentionCount;
  uint[2] Spare;
}

struct CRITICAL_SECTION {
  CRITICAL_SECTION_DEBUG* DebugInfo;
  int LockCount;
  int RecursionCount;
  Handle OwningThread;
  Handle LockSemaphore;
  uint SpinCount;
}

struct RECT {
  int left;
  int top;
  int right;
  int bottom;
}

struct CPINFO {
  uint MaxCharSize;
  ubyte[2] DefaultChar;
  ubyte[12] LeadByte;
}

struct CPINFOEXW {
  uint MaxCharSize;
  ubyte[2] DefaultChar;
  ubyte[12] LeadByte;
  wchar UnicodeDefaultChar;
  uint CodePage;
  wchar[260] CodePageName;
}

struct COORD {
  short X;
  short Y;
}

struct SMALL_RECT {
  short Left;
  short Top;
  short Right;
  short Bottom;
}

struct CONSOLE_SCREEN_BUFFER_INFO {
  COORD dwSize;
  COORD dwCursorPosition;
  ushort wAttributes;
  SMALL_RECT srWindow;
  COORD dwMaximumWindowSize;
}

struct SHELLEXECUTEINFOW {
  uint cbSize = SHELLEXECUTEINFOW.sizeof;
  uint fMask;
  Handle hwnd;
  wchar* lpVerb;
  wchar* lpFile;
  wchar* lpParameters;
  wchar* lpDirectory;
  int nShow;
  Handle hInstApp;
  void* lpIDList;
  wchar* lpClass;
  Handle hkeyClass;
  uint dwHotKey;
  Handle hIcon;
  Handle hProcess;
}

struct OSVERSIONINFOW {
  uint dwOSVersionInfoSize = OSVERSIONINFOW.sizeof;
  uint dwMajorVersion;
  uint dwMinorVersion;
  uint dwBuildNumber;
  uint dwPlatformId;
  wchar[128] szCSDVersion;
}

alias bool function(wchar*) LOCALE_ENUMPROCW;
alias bool function(wchar*) CALINFO_ENUMPROCW;
alias bool function(wchar*, uint) CALINFO_ENUMPROCEXW;
alias bool function(wchar*) CODEPAGE_ENUMPROCW;
alias bool function(int) GEO_ENUMPROC;
alias bool function(wchar*, uint) DATEFMT_ENUMPROCEXW;
alias bool function(Handle, wchar*, int) ENUMRESTYPEPROCW;
alias bool function(Handle, wchar*, wchar*, int) ENUMRESNAMEPROCW;

alias bool function(uint) PHANDLER_ROUTINE;

uint GetLastError();
uint GetVersion();
bool GetVersionExW(inout OSVERSIONINFOW lpVersionInformation);
uint GetTickCount();

uint GetThreadLocale();
bool SetThreadLocale(uint Locale);
uint GetUserDefaultLCID();
uint GetSystemDefaultLCID();
ushort GetSystemDefaultUILanguage();
ushort GetUserDefaultUILanguage();
ushort GetUserDefaultLangID();
ushort GetSystemDefaultLangID();
uint ConvertDefaultLocale(uint Locale);
bool IsValidLocale(uint Locale, uint dwFlags);
bool GetCPInfo(uint CodePage, out CPINFO lpCPInfo);
bool GetCPInfoExW(uint CodePage, uint dwFlags, out CPINFOEXW lpCPInfoEx);
uint GetACP();
int CompareStringW(uint Locale, uint dwCmpFlags, wchar* lpString1, int cchCount1, wchar* lpString2, int cchCount2);
int LCMapStringW(uint Locale, uint dwMapFlags, wchar* lpSrcStr, int cchSrc, wchar* lpDestStr, int cchDest);
int FoldStringW(uint dwMapFlags, wchar* lpSrcStr, int cchSrc, wchar* lpDestStr, int cchDest);
int MultiByteToWideChar(uint CodePage, uint dwFlags, char* lpMultiByteStr, int cbMultiByte, wchar* lpWideCharStr, int cchWideChar);
int WideCharToMultiByte(uint CodePage, uint dwFlags, wchar* lpWideCharStr, int cchWideChar, char* lpMultiByteStr, int cbMultiByte, char* lpDefaultChar, bool* lpUsedDefaultChar);
bool EnumSystemLocalesW(LOCALE_ENUMPROCW lpLocaleEnumProc, uint dwFlags);
bool EnumCalendarInfoW(CALINFO_ENUMPROCW lpCalInfoEnumProc, uint Locale, uint Calendar, uint CalType);
bool EnumCalendarInfoExW(CALINFO_ENUMPROCEXW lpCalInfoEnumProc, uint Locale, uint Calendar, uint CalType);
bool EnumDateFormatsExW(DATEFMT_ENUMPROCEXW lpDateFmtEnumProc, uint Locale, uint dwFlags);
bool EnumSystemCodePagesW(CODEPAGE_ENUMPROCW lpCodePageEnumProc, uint dwFlags);
bool EnumSystemGeoID(uint GeoClass, int ParentGeoId, GEO_ENUMPROC lpGeoEnumProc);
int GetLocaleInfoW(uint Locale, uint LCType, wchar* lpLCData, int cchData);
int GetCalendarInfoW(uint Locale, uint Calendar, uint CalType, wchar* lpCalData, int cchData, uint* lpValue);

void GetSystemTimeAsFileTime(out FILETIME lpSystemTimeAsFileTime);
bool FileTimeToSystemTime(inout FILETIME lpFileTime, out SYSTEMTIME lpSystemTime);
bool SystemTimeToFileTime(inout SYSTEMTIME lpSystemTime, out FILETIME lpFileTime);

uint FormatMessageW(uint dwFlags, void* lpSource, uint dwMessageId, uint dwLanguageId, wchar* lpBuffer, uint nSize, void** Arguments);
Handle LoadLibraryW(wchar* lpLibName);
void* GetProcAddress(Handle hModule, char* lpProcName);
uint ExpandEnvironmentStringsW(wchar* lpSrc, wchar* lpDst, uint nSize);
uint GetEnvironmentVariableW(wchar* lpName, wchar* lpBuffer, uint nSize);
bool SetEnvironmentVariableW(wchar* lpName, wchar* lpValue);

int InterlockedIncrement(inout int Addend);
int InterlockedDecrement(inout int Addend);
int InterlockedCompareExchange(int* Destination, int ExChange, int Comparand);
void InitializeCriticalSection(out CRITICAL_SECTION lpCriticalSection);
bool InitializeCriticalSectionAndSpinCount(out CRITICAL_SECTION lpCriticalSection, uint dwSpinCount);
uint SetCriticalSectionSpinCount(inout CRITICAL_SECTION lpCriticalSection, uint dwSpinCount);
void EnterCriticalSection(inout CRITICAL_SECTION lpCriticalSection);
void LeaveCriticalSection(inout CRITICAL_SECTION lpCriticalSection);
bool TryEnterCriticalSection(inout CRITICAL_SECTION lpCriticalSection);
void DeleteCriticalSection(inout CRITICAL_SECTION lpCriticalSection);
Handle CreateMutexW(SECURITY_ATTRIBUTES* lpMutexAttributes, int bInitialOwner, wchar* lpName);
bool ReleaseMutex(Handle hMutex);
uint WaitForSingleObject(Handle hHandle, uint dwMilliseconds);
Handle CreateEventW(SECURITY_ATTRIBUTES* lpEventAttributes, int bManualReset, int bInitialState, wchar* lpName);
bool ResetEvent(Handle hEvent);
bool SetEvent(Handle hEvent);
void Sleep(uint dwMilliseconds);
uint TlsAlloc();
void* TlsGetValue(uint dwTlsIndex);
bool TlsSetValue(uint dwTlsIndex, void* lpTlsValue);
bool TlsFree(uint dwTlsIndex);

bool ReadFile(Handle hFile, void* lpBuffer, uint nNumberOfBytesToRead, out uint lpNumberOfBytesRead, void* lpOverlapped);
bool WriteFile(Handle hFile, void* lpBuffer, uint nNumberOfBytesToWrite, out uint lpNumberOfBytesWritten, void* lpOverlapped);

Handle GetStdHandle(uint nStdHandle);
uint GetConsoleOutputCP();
bool Beep(uint dwFreq, uint dwDuration);
bool FillConsoleOutputCharacterW(Handle hConsoleOutput, wchar cCharacter, uint nLength, COORD dwWriteCoord, uint* lpNumberOfCharsWritten);
bool FillConsoleOutputAttribute(Handle hConsoleOutput, ushort wAttribute, uint nLength, COORD dwWriteCoord, uint* lpNumberOfAttrsWritten);
bool SetConsoleCursorPosition(Handle hConsoleOutput, COORD dwCursorPosition);
bool GetConsoleScreenBufferInfo(Handle hConsoleOutput, out CONSOLE_SCREEN_BUFFER_INFO lpConsoleScreenBufferInfo);
bool SetConsoleTextAttribute(Handle hConsoleOutput, ushort wAttributes);
uint GetConsoleTitleW(wchar* lpConsoleTitle, uint nSize);
bool SetConsoleTitleW(wchar* lpConsoleTitle);
bool SetConsoleCtrlHandler(PHANDLER_ROUTINE HandlerRoutine, bool add);

bool ShellExecuteExW(inout SHELLEXECUTEINFOW lpExecInfo);
int SHGetFolderPathW(Handle hwndOwner, int nFolder, Handle hToken, uint dwFlags, wchar* pszPath);

int RegOpenKeyExW(Handle hKey, wchar* lpSubKey, uint ulOptions, uint samDesired, out Handle phkResult);
int RegSetValueExW(Handle hKey, wchar* lpValueName, uint reserved, uint dwType, void* lpData, uint cbData);
int RegQueryValueW(Handle hKey, wchar* lpSubKey, wchar* lpData, uint* lpcbData);
int RegQueryValueExW(Handle hKey, wchar* lpValueName, uint* lpReserved, out uint lpType, void* lpData, inout uint lpcbData);
int RegQueryInfoKeyW(Handle hKey, wchar* lpClass, uint* lpcchClass, uint* lpReserved, uint* lpcSubKeys, uint* lpcbMaxSubKeyLen, uint* lpcbMaxClassLen, uint* lpcValues, uint* lpcbMaxValueNameLen, uint* lpcbMaxValueLen, uint* lpcbSecurityDescriptor, FILETIME* lpftLastWriteTime);
int RegCloseKey(Handle hKey);
int RegEnumKeyExW(Handle hKey, uint dwIndex, wchar* lpName, inout uint lpcchName, uint* lpReserved, wchar* lpClass, uint* lpcchClass, FILETIME* lpftLastWriteTime);
int RegEnumValueW(Handle hKey, uint dwIndex, wchar* lpValueName, inout uint lpcchValueName, uint* lpReserved, uint* lpType, ubyte* lpData, uint* lpcbData);
int RegDeleteKeyW(Handle hKey, wchar* lpSubKey);
int RegFlushKey(Handle hKey);
int RegDeleteValueW(Handle hKey, wchar* lpValueName);
int RegCreateKeyExW(Handle hKey, wchar* lpSubKey, uint reserved, wchar* lpClass, uint dwOptions, uint samDesigner, SECURITY_ATTRIBUTES* lpSecurityAttributes, out Handle hkResult, out uint lpdwDisposition);

uint GetLongPathNameW(wchar* lpszShortPath, wchar* lpszLongPath, uint cchBuffer);
uint GetFullPathNameW(wchar* lpFileName, uint nBufferLength, wchar* lpBuffer, wchar** lpFilePart);
bool PathCanonicalizeW(wchar* lpszDst, wchar* lpszSrc);
uint GetTempPathW(uint nBufferLength, wchar* lpBuffer);
uint GetTempFileNameW(wchar* lpPathName, wchar* lpPrefixString, uint uUnique, wchar* lpTempFileName);

version (Unicode) {

alias GetVersionExW GetVersionEx;

alias GetCPInfoExW GetCPInfoEx;
alias EnumSystemLocalesW EnumSystemLocales;
alias EnumDateFormatsExW EnumDateFormatsEx;
alias EnumCalendarInfoExW EnumCalendarInfoEx;
alias GetLocaleInfoW GetLocaleInfo;
alias GetCalendarInfoW GetCalendarInfo;
alias CompareStringW CompareString;
alias LCMapStringW LCMapString;
alias FoldStringW FoldString;

alias FormatMessageW FormatMessage;
alias LoadLibraryW LoadLibrary;
alias ExpandEnvironmentStringsW ExpandEnvironmentStrings;
alias GetEnvironmentVariableW GetEnvironmentVariable;
alias SetEnvironmentVariableW SetEnvironmentVariable;

alias FillConsoleOutputCharacterW FillConsoleOutputCharacter;
alias GetConsoleTitleW GetConsoleTitle;
alias SetConsoleTitleW SetConsoleTitle;

alias ShellExecuteExW ShellExecuteEx;
alias SHGetFolderPathW SHGetFolderPath;

alias RegOpenKeyExW RegOpenKeyEx;
alias RegSetValueExW RegSetValueEx;
alias RegQueryValueW RegQueryValue;
alias RegQueryValueExW RegQueryValueEx;
alias RegQueryInfoKeyW RegQueryInfoKey;
alias RegEnumKeyExW RegEnumKeyEx;
alias RegEnumValueW RegEnumValue;
alias RegDeleteKeyW RegDeleteKey;
alias RegDeleteValueW RegDeleteValue;
alias RegCreateKeyExW RegCreateKeyEx;

alias GetLongPathNameW GetLongPathName;
alias GetFullPathNameW GetFullPathName;
alias PathCanonicalizeW PathCanonicalize;
alias GetTempPathW GetTempPath;
alias GetTempFileNameW GetTempFileName;

alias OSVERSIONINFOW OSVERSIONINFO;
alias CPINFOEXW CPINFOEX;
alias SHELLEXECUTEINFOW SHELLEXECUTEINFO;

}

public class Win32Exception : Throwable {

  private uint errorCode_;

  public this(char[] message) {
    super(message);
    errorCode_ = GetLastError();
  }

  public this(uint error = GetLastError()) {
    this(error, createErrorMessage(error));
  }

  public this(uint error, char[] message) {
    super(message);
    errorCode_ = error;
  }

  public uint errorCode() {
    return errorCode_;
  }

  private static char[] createErrorMessage(uint error) {
    wchar[256] buffer;
    uint r = FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS, null, error, 0, buffer, buffer.length + 1, null);
    if (r != 0)
      return std.utf.toUTF8(buffer[0 .. r - 1]);
    return "Unspecified error";
  }
}

public class DllNotFoundException : Throwable {

  public this(char[] message = "Dll was not found.") {
    super(message);
  }

}

public class EntryPointNotFoundException : Throwable {

  public this(char[] message = "Entry point was not found.") {
    super(message);
  }

}

public enum CharSet {
  None,
  Ansi,
  Unicode,
  Auto
}

private Handle[char[]] moduleStore;

private T functionAddress(T)(char[] dllName, char[] entryPoint, CharSet charSet) {
  Handle moduleHandle;

  if (auto h = dllName in moduleStore)
    moduleHandle = *h;
  else
    moduleStore[dllName] = moduleHandle = LoadLibrary(dllName.toUTF16z());

  if (moduleHandle == Handle.init)
    throw new DllNotFoundException("Unable to load DLL '" ~ dllName ~ "'.");

  T func = cast(T)GetProcAddress(moduleHandle, entryPoint);

  if (func == null) {
    // Try A/W versions.
    CharSet linkType = CharSet.Auto;
    if (charSet == CharSet.Auto) {
      if ((GetVersion() & 0x80000000) == 0)
        linkType = CharSet.Unicode;
      else
        linkType = CharSet.Ansi;
    }

    char[] entryPointName = entryPoint;
    if (linkType == CharSet.Ansi)
      entryPointName ~= 'A';
    else
      entryPointName ~= 'W';

    func = cast(T)GetProcAddress(moduleHandle, entryPointName);

    if (func == null)
      throw new EntryPointNotFoundException("Unable to find entry point '" ~ entryPoint ~ "' in DLL '" ~ dllName ~ "'.");
  }

  return func;
}

public struct DllImport(char[] dllName, char[] entryPoint, T, CharSet charSet = CharSet.Auto) {
  public static ReturnType!(T) opCall(ParameterTypeTuple!(T) args) {
    return functionAddress!(T)(dllName, entryPoint, charSet)(args);
  }
}