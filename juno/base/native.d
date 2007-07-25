module juno.base.native;

private import juno.base.string : toUtf8, format;

private import juno.base.core;
private import std.string : toStringz, toUTF16z;
private import std.conv : toUshort;
private import std.traits : ReturnType, ParameterTypeTuple;
private import std.c.string : memcpy;

pragma (lib, "advapi32.lib");
pragma (lib, "shell32.lib");

extern(Windows):

const uint MAX_PATH = 260;

enum {
  ERROR_SUCCESS = 0,
  ERROR_INVALID_FUNCTION = 1,
  ERROR_FILE_NOT_FOUND = 2,
  ERROR_PATH_NOT_FOUND = 3,
  ERROR_TOO_MANY_OPEN_FILES = 4,
  ERROR_ACCESS_DENIED = 5,
  ERROR_INVALID_HANDLE = 6,
  ERROR_CLASS_ALREADY_EXISTS = 1410
}

enum {
  FACILITY_ITF = 4
}

template MAKELANGID_T(ushort p, ushort s) {
  const MAKELANGID_T = cast(ushort)((s << 10) | p);
}

template PRIMARYLANGID_T(ushort lgid) {
  const PRIMARYLANGID_T = cast(ushort)(lgid & 0x3ff);
}

template SUBLANGID_T(ushort lgid) {
  const SUBLANGID_T = cast(ushort)(lgid >> 10);
}

template MAKELCID_T(ushort lgid, ushort srtid) {
  const MAKELCID_T = cast(uint)((srtid << 16) | lgid);
}

enum : ushort {
  LANG_NEUTRAL = 0x0,
  LANG_INVARIANT = 0x7f
}

enum : ushort {
  SUBLANG_NEUTRAL = 0x0,
  SUBLANG_DEFAULT = 0x1,
  SUBLANG_SYS_DEFAULT = 0x2
}

enum : ushort {
  SORT_DEFAULT = 0x0
}

enum : ushort {
  LANG_SYSTEM_DEFAULT = MAKELANGID_T!(LANG_NEUTRAL, SUBLANG_SYS_DEFAULT),
  LANG_USER_DEFAULT = MAKELANGID_T!(LANG_NEUTRAL, SUBLANG_NEUTRAL)
}

enum : uint {
  LOCALE_SYSTEM_DEFAULT = MAKELCID_T!(LANG_SYSTEM_DEFAULT, SORT_DEFAULT),
  LOCALE_USER_DEFAULT = MAKELCID_T!(LANG_USER_DEFAULT, SORT_DEFAULT),
  LOCALE_NEUTRAL = MAKELCID_T!(MAKELANGID_T!(LANG_NEUTRAL, SUBLANG_NEUTRAL), SORT_DEFAULT),
  LOCALE_INVARIANT = MAKELCID_T!(MAKELANGID_T!(LANG_INVARIANT, SUBLANG_NEUTRAL), SORT_DEFAULT)
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
  STD_INPUT_HANDLE = -10,
  STD_OUTPUT_HANDLE = -11,
  STD_ERROR_HANDLE = -12
}

struct POINT {
  int x;
  int y;
}

struct SIZE {
  int cx;
  int cy;
}

struct RECT {
  int left;
  int top;
  int right;
  int bottom;

  static RECT fromXYWH(int x, int y, int width, int height) {
    return RECT(x, y, x + width, y + height);
  }
}

struct OSVERSIONINFOW {
  uint dwOSVersionInfoSize = OSVERSIONINFOW.sizeof;
  uint dwMajorVersion;
  uint dwMinorVersion;
  uint dwBuildNumber;
  uint dwPlatformId;
  wchar[128] szCDVersion;
}

alias OSVERSIONINFOW OSVERSIONINFO;

enum : uint {
  VER_PLATFORM_WIN32s            = 0,
  VER_PLATFORM_WIN32_WINDOWS     = 1,
  VER_PLATFORM_WIN32_NT          = 2
}

struct FILETIME {
  uint dwLowDateTime;
  uint dwHighDateTime;
}

struct CPINFO {
  uint MaxCharSize;
  ubyte[2] DefaultChar;
  ubyte[12] LeadByte;
}

extern final Handle HKEY_CLASSES_ROOT;
extern final Handle HKEY_CURRENT_USER;
extern final Handle HKEY_LOCAL_MACHINE;
extern final Handle HKEY_USERS;
extern final Handle HKEY_PERFORMANCE_DATA;
extern final Handle HKEY_CURRENT_CONFIG;
extern final Handle HKEY_DYN_DATA;

enum : uint {
  DELETE                          = 0x00010000,
  READ_CONTROL                    = 0x00020000,
  WRITE_DAC                       = 0x00040000,
  WRITE_OWNER                     = 0x00080000,
  SYNCHRONIZE                     = 0x00100000,
  STANDARD_RIGHTS_REQUIRED        = 0x000F0000,
  STANDARD_RIGHTS_READ            = READ_CONTROL,
  STANDARD_RIGHTS_WRITE           = READ_CONTROL,
  STANDARD_RIGHTS_EXECUTE         = READ_CONTROL,
  STANDARD_RIGHTS_ALL             = 0x001F0000,
  SPECIFIC_RIGHTS_ALL             = 0x0000FFFF
}

enum : uint {
  KEY_QUERY_VALUE        = 0x0001,
  KEY_SET_VALUE          = 0x0002,
  KEY_CREATE_SUB_KEY     = 0x0004,
  KEY_ENUMERATE_SUB_KEYS = 0x0008,
  KEY_NOTIFY             = 0x0010,
  KEY_CREATE_LINK        = 0x0020,

  KEY_READ               = (STANDARD_RIGHTS_READ | KEY_QUERY_VALUE | KEY_ENUMERATE_SUB_KEYS | KEY_NOTIFY) & ~SYNCHRONIZE,
  KEY_WRITE              = (STANDARD_RIGHTS_WRITE | KEY_SET_VALUE | KEY_CREATE_SUB_KEY) & ~SYNCHRONIZE,
  KEY_EXECUTE            = KEY_READ & ~SYNCHRONIZE,
  KEY_ALL_ACCESS         = (STANDARD_RIGHTS_ALL | KEY_QUERY_VALUE | KEY_SET_VALUE | KEY_CREATE_SUB_KEY | KEY_ENUMERATE_SUB_KEYS | KEY_NOTIFY | KEY_CREATE_LINK) & ~SYNCHRONIZE,
}

enum : uint {
  REG_NONE                        = 0,
  REG_SZ                          = 1,
  REG_EXPAND_SZ                   = 2,
  REG_BINARY                      = 3,
  REG_DWORD                       = 4,
  REG_DWORD_LITTLE_ENDIAN         = 4,
  REG_DWORD_BIG_ENDIAN            = 5,
  REG_LINK                        = 6,
  REG_MULTI_SZ                    = 7,
  REG_RESOURCE_LIST               = 8,
  REG_FULL_RESOURCE_DESCRIPTOR    = 9,
  REG_RESOURCE_REQUIREMENTS_LIST  = 10,
  REG_QWORD                       = 11,
  REG_QWORD_LITTLE_ENDIAN         = 11
}

extern final Handle INVALID_HANDLE_VALUE; // Already defined by Phobos

extern ushort SUBLANGID(uint lgid);

extern ushort LOWORD(uint);
extern ushort HIWORD(uint);

int SignedLOWORD(int n) {
  return cast(short)(n & 0xffff);
}

int SignedHIWORD(int n) {
  return cast(short)((n >> 16) & 0xffff);
}

ubyte LOBYTE(uint w) {
  return cast(ubyte)(w & 0xff);
}

ubyte HIBYTE(uint w) {
  return cast(ubyte)(w >> 8);
}

struct LARGE_INTEGER {
  long QuadPart;
}

struct ULARGE_INTEGER {
  ulong QuadPart;
}

int InterlockedIncrement(ref int Addend);
int InterlockedDecrement(ref int Addend);

enum : uint {
  FORMAT_MESSAGE_ALLOCATE_BUFFER  = 0x00000100,
  FORMAT_MESSAGE_ARGUMENT_ARRAY   = 0x00002000,
  FORMAT_MESSAGE_FROM_HMODULE     = 0x00000800,
  FORMAT_MESSAGE_FROM_STRING      = 0x00000400,
  FORMAT_MESSAGE_FROM_SYSTEM      = 0x00001000,
  FORMAT_MESSAGE_IGNORE_INSERTS   = 0x00000200
}

int InterlockedCompareExchange(int* Destination, int ExChange, int Comparand);

Handle GetProcessHeap();
void* HeapAlloc(Handle hHeap, uint dwFlags, size_t dwBytes);
int HeapFree(Handle hHeap, uint dwFlags, void* lpMem);

void Sleep(uint dwMilliseconds);

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
  uint Flags;
  ushort CreatorBackTraceIndexHigh;
  ushort SpareWORD;
}

struct CRITICAL_SECTION {
  CRITICAL_SECTION_DEBUG DebugInfo;
  int LockCount;
  int RecursionCount;
  Handle OwningThread;
  Handle LockSemaphore;
  uint SpinCount;
}

void InitializeCriticalSection(out CRITICAL_SECTION lpCriticalSection);
void EnterCriticalSection(ref CRITICAL_SECTION lpCriticalSection);
void LeaveCriticalSection(ref CRITICAL_SECTION lpCriticalSection);
int TryEnterCriticalSection(ref CRITICAL_SECTION lpCriticalSection);
void DeleteCriticalSection(ref CRITICAL_SECTION lpCriticalSection);
uint TlsAlloc();
int TlsFree(uint dwTlsIndex);
void* TlsGetValue(uint dwTlsIndex);
int TlsSetValue(uint dwTlsIndex, void* lpTlsValue);

Handle GetModuleHandleW(wchar* lpModuleName);
alias GetModuleHandleW GetModuleHandle;

uint GetModuleFileNameW(Handle hModule, wchar* lpFilename, uint nSize);
alias GetModuleFileNameW GetModuleFileName;

int FormatMessageW(uint dwFlags, void* lpSource, uint dwMessageId, uint dwLanguageId, wchar* lpBuffer, uint nSize, void** Arguments);
alias FormatMessageW FormatMessage;

uint GetLastError();

Handle LoadLibraryW(wchar* lpLibFileName);
alias LoadLibraryW LoadLibrary;

void* GetProcAddress(Handle hModule, char* lpProcName);
uint GetVersion();

uint ExpandEnvironmentStringsW(wchar* lpSrc, wchar* lpDst, uint nSize);
alias ExpandEnvironmentStringsW ExpandEnvironmentStrings;

uint GetFullPathNameW(wchar* lpFileName, uint nBufferLength, wchar* lpBuffer, wchar** lpFilePart);
alias GetFullPathNameW GetFullPathName;

uint GetLongPathNameW(wchar* lpszShortPath, wchar* lpszLongPath, uint cchBuffer);
alias GetLongPathNameW GetLongPathName;

uint GetTempPathW(uint nBufferLength, wchar* lpBuffer);
alias GetTempPathW GetTempPath;

uint GetTempFileNameW(wchar* lpPathName, wchar* lpPrefixString, uint uUnique, wchar* lpTempFileName);
alias GetTempFileNameW GetTempFileName;

uint GetACP();
Handle GetStdHandle(uint nStdHandle);
int GetCPInfo(uint CodePage, out CPINFO lpCPInfo);

uint GetThreadLocale();
int SetThreadLocale(uint Locale);
uint GetUserDefaultLCID();
ushort GetUserDefaultLangID();
ushort GetSystemDefaultLangID();
int MultiByteToWideChar(uint CodePage, uint dwFlags, char* lpMultiByteStr, int cbMultiByte, wchar* lpWideCharStr, int cchWideChar);
int WideCharToMultiByte(uint CodePage, uint dwFlags, wchar* lpWideCharStr, int cchWideChar, char* lpMultiByteStr, int cbMultiByte, char* lpDefaultChar, int* lpUseDefaultChar);

enum : uint {
  SORT_STRINGSORT           = 0x00001000
}

enum : uint {
  NORM_IGNORECASE           = 0x00000001,
  NORM_IGNORENONSPACE       = 0x00000002,
  NORM_IGNORESYMBOLS        = 0x00000004,
  NORM_IGNOREKANATYPE       = 0x00010000,
  NORM_IGNOREWIDTH          = 0x00020000,
  NORM_LINGUISTIC_CASING    = 0x08000000
}

int CompareStringW(uint Locale, uint dwCmpFlags, wchar* lpString1, int cchCount1, wchar* lpString2, int cchCount2);
alias CompareStringW CompareString;

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

int LCMapStringW(uint Locale, uint dwMapFlags, wchar* lpSrcStr, int cchSrc, wchar* lpDestStr, int cchDest);
alias LCMapStringW LCMapString;

alias int function(wchar*) LOCALE_ENUMPROCW;
alias LOCALE_ENUMPROCW LOCALE_ENUMPROC;

enum : uint {
  LCID_INSTALLED           = 0x00000001,
  LCID_SUPPORTED           = 0x00000002,
  LCID_ALTERNATE_SORTS     = 0x00000004
}

int EnumSystemLocalesW(LOCALE_ENUMPROCW lpLocaleEnumProc, uint dwFlags);
alias EnumSystemLocalesW EnumSystemLocales;

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
  LOCALE_IGEOID                 = 0x0000005B,
  
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
  LOCALE_IDEFAULTEBCDICCODEPAGE = 0x00001012,
  LOCALE_IPAPERSIZE             = 0x0000100A,
  LOCALE_SENGCURRNAME           = 0x00001007,
  LOCALE_SNATIVECURRNAME        = 0x00001008,
  LOCALE_SYEARMONTH             = 0x00001006,
  LOCALE_SSORTNAME              = 0x00001013,
  LOCALE_IDIGITSUBSTITUTION     = 0x00001014,

  // Vista
  LOCALE_SNAME                  = 0x0000005c,
  LOCALE_SDURATION              = 0x0000005d,
  LOCALE_SKEYBOARDSTOINSTALL    = 0x0000005e,
  LOCALE_SSHORTESTDAYNAME1      = 0x00000060,
  LOCALE_SSHORTESTDAYNAME2      = 0x00000061,
  LOCALE_SSHORTESTDAYNAME3      = 0x00000062,
  LOCALE_SSHORTESTDAYNAME4      = 0x00000063,
  LOCALE_SSHORTESTDAYNAME5      = 0x00000064,
  LOCALE_SSHORTESTDAYNAME6      = 0x00000065,
  LOCALE_SSHORTESTDAYNAME7      = 0x00000066,
  LOCALE_SISO639LANGNAME2       = 0x00000067,
  LOCALE_SISO3166CTRYNAME2      = 0x00000068,
  LOCALE_SNAN                   = 0x00000069,
  LOCALE_SPOSINFINITY           = 0x0000006a,
  LOCALE_SNEGINFINITY           = 0x0000006b,
  LOCALE_SSCRIPTS               = 0x0000006c,
  LOCALE_SPARENT                = 0x0000006d,
  LOCALE_SCONSOLEFALLBACKNAME   = 0x0000006e,
  LOCALE_SLANGDISPLAYNAME       = 0x0000006f
}

int GetLocaleInfoW(uint Locale, uint LCType, wchar* lpLCData, int cchData);
alias GetLocaleInfoW GetLocaleInfo;

enum : uint {
  CAL_NOUSEROVERRIDE        = LOCALE_NOUSEROVERRIDE,
  CAL_USE_CP_ACP            = LOCALE_USE_CP_ACP,
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

  CAL_SSHORTESTDAYNAME1     = 0x00000031,
  CAL_SSHORTESTDAYNAME2     = 0x00000032,
  CAL_SSHORTESTDAYNAME3     = 0x00000033,
  CAL_SSHORTESTDAYNAME4     = 0x00000034,
  CAL_SSHORTESTDAYNAME5     = 0x00000035,
  CAL_SSHORTESTDAYNAME6     = 0x00000036,
  CAL_SSHORTESTDAYNAME7     = 0x00000037,

  ENUM_ALL_CALENDARS        = 0xffffffff
}

enum : uint {
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
  CAL_GREGORIAN_XLIT_FRENCH     = 12,
  CAL_UMALQURA                  = 23
}

int GetCalendarInfoW(uint Locale, uint Calendar, uint CalType, wchar* lpCalData, int cchData, uint* lpValue);
alias GetCalendarInfoW GetCalendarInfo;

alias int function(wchar*, uint) CALINFO_ENUMPROCEXW;
alias CALINFO_ENUMPROCEXW CALINFO_ENUMPROCEX;

int EnumCalendarInfoExW(CALINFO_ENUMPROCEXW lpCalInfoEnumProcEx, uint Locale, uint Calendar, uint CalType);
alias EnumCalendarInfoExW EnumCalendarInfoEx;

enum : uint {
  DATE_SHORTDATE            = 0x00000001,
  DATE_LONGDATE             = 0x00000002,
  DATE_USE_ALT_CALENDAR     = 0x00000004
}

alias int function(wchar*, uint) DATEFMT_ENUMPROCEXW;
alias DATEFMT_ENUMPROCEXW DATEFMT_ENUMPROCEX;

int EnumDateFormatsExW(DATEFMT_ENUMPROCEXW lpDateFmtEnumProcEx, uint Locale, uint dwFlags);
alias EnumDateFormatsExW EnumDateFormatsEx;

enum : uint {
  TIME_NOMINUTESORSECONDS   = 0x00000001,
  TIME_NOSECONDS            = 0x00000002,
  TIME_NOTIMEMARKER         = 0x00000004,
  TIME_FORCE24HOURFORMAT    = 0x00000008
}

alias int function(wchar*) TIMEFMT_ENUMPROCW;
alias TIMEFMT_ENUMPROCW TIMEFMT_ENUMPROC;

int EnumTimeFormatsW(TIMEFMT_ENUMPROCW lpTimeFmtEnumProc, uint Locale, uint dwFlags);
alias EnumTimeFormatsW EnumTimeFormats;

enum : uint {
  GEO_NATION = 0x1,
  GEO_LATITUDE = 0x2,
  GEO_LONGITUDE = 0x3,
  GEO_ISO2 = 0x4,
  GEO_ISO3 = 0x5,
  GEO_RFC1766 = 0x6,
  GEO_LCID = 0x7,
  GEO_FRIENDLYNAME = 0x8,
  GEO_OFFICIALNAME = 0x9,
  GEO_TIMEZONES = 0xA,
  GEO_OFFICALLANGUAGES = 0xB
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

  static REG_TIME_ZONE_INFORMATION opCall(ubyte[] bytes) {
    REG_TIME_ZONE_INFORMATION value;
    memcpy(&value, bytes.ptr, REG_TIME_ZONE_INFORMATION.sizeof);
    return value;
  }

  static REG_TIME_ZONE_INFORMATION opCall(TIME_ZONE_INFORMATION timeZoneInfo) {
    REG_TIME_ZONE_INFORMATION value;
    value.Bias = timeZoneInfo.Bias;
    value.StandardBias = timeZoneInfo.StandardBias;
    value.DaylightBias = timeZoneInfo.DaylightBias;
    value.StandardDate = timeZoneInfo.StandardDate;
    value.DaylightDate = timeZoneInfo.DaylightDate;
    return value;
  }
}

void GetSystemTimeAsFileTime(out FILETIME lpSystemTimeAsFileTime);

int FileTimeToLocalFileTime(ref FILETIME lpFileTime, out FILETIME lpLocalFileTime);

uint GetTimeZoneInformation(out TIME_ZONE_INFORMATION lpTimeZoneInformation);

int GetVersionInfoW(out OSVERSIONINFO lpVersionInformation);
alias GetVersionInfoW GetVersionInfo;

enum : uint {
  GMEM_FIXED          = 0x0000,
  GMEM_MOVEABLE       = 0x0002,
  GMEM_NOCOMPACT      = 0x0010,
  GMEM_NODISCARD      = 0x0020,
  GMEM_ZEROINIT       = 0x0040,
  GMEM_MODIFY         = 0x0080,
  GMEM_DISCARDABLE    = 0x0100,
  GMEM_NOT_BANKED     = 0x1000,
  GMEM_SHARE          = 0x2000,
  GMEM_DDESHARE       = 0x2000,
  GMEM_NOTIFY         = 0x4000,
  GMEM_LOWER          = GMEM_NOT_BANKED,
  GMEM_VALID_FLAGS    = 0x7F72,
  GMEM_INVALID_HANDLE = 0x8000
}

Handle GlobalAlloc(uint uFlags, size_t dwBytes);

void* GlobalLock(Handle hMem);

int GlobalUnlock(Handle hMem);

enum {
  LMEM_FIXED          = 0x0000,
  LMEM_MOVEABLE       = 0x0002,
  LMEM_NOCOMPACT      = 0x0010,
  LMEM_NODISCARD      = 0x0020,
  LMEM_ZEROINIT       = 0x0040,
  LMEM_MODIFY         = 0x0080,
  LMEM_DISCARDABLE    = 0x0F00,
  LMEM_VALID_FLAGS    = 0x0F72,
  LMEM_INVALID_HANDLE = 0x8000
}

Handle LocalAlloc(uint uFlags, size_t uBytes);

Handle LocalFree(Handle hMem);

enum {
  GENERIC_READ                     = 0x80000000,
  GENERIC_WRITE                    = 0x40000000,
  GENERIC_EXECUTE                  = 0x20000000,
  GENERIC_ALL                      = 0x10000000
}

enum {
  CREATE_NEW         = 1,
  CREATE_ALWAYS      = 2,
  OPEN_EXISTING      = 3,
  OPEN_ALWAYS        = 4,
  TRUNCATE_EXISTING  = 5
}

enum : uint {
  FILE_ATTRIBUTE_READONLY             = 0x00000001,
  FILE_ATTRIBUTE_HIDDEN               = 0x00000002,
  FILE_ATTRIBUTE_SYSTEM               = 0x00000004,
  FILE_ATTRIBUTE_DIRECTORY            = 0x00000010,
  FILE_ATTRIBUTE_ARCHIVE              = 0x00000020,
  FILE_ATTRIBUTE_DEVICE               = 0x00000040,
  FILE_ATTRIBUTE_NORMAL               = 0x00000080,
  FILE_ATTRIBUTE_TEMPORARY            = 0x00000100,
  FILE_ATTRIBUTE_SPARSE_FILE          = 0x00000200,
  FILE_ATTRIBUTE_REPARSE_POINT        = 0x00000400,
  FILE_ATTRIBUTE_COMPRESSED           = 0x00000800,
  FILE_ATTRIBUTE_OFFLINE              = 0x00001000,
  FILE_ATTRIBUTE_NOT_CONTENT_INDEXED  = 0x00002000,
  FILE_ATTRIBUTE_ENCRYPTED            = 0x00004000,
  FILE_ATTRIBUTE_VIRTUAL              = 0x00010000
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

enum : uint {
  FILE_READ_DATA                = 0x0001,
  FILE_LIST_DIRECTORY           = 0x0001,
  FILE_WRITE_DATA               = 0x0002,
  FILE_ADD_FILE                 = 0x0002,
}

enum : uint {
  FILE_SHARE_READ                = 0x00000001,
  FILE_SHARE_WRITE               = 0x00000002,
  FILE_SHARE_DELETE              = 0x00000004  
}

enum : uint {
  FILE_FLAG_WRITE_THROUGH         = 0x80000000,
  FILE_FLAG_OVERLAPPED            = 0x40000000,
  FILE_FLAG_NO_BUFFERING          = 0x20000000,
  FILE_FLAG_RANDOM_ACCESS         = 0x10000000,
  FILE_FLAG_SEQUENTIAL_SCAN       = 0x08000000,
  FILE_FLAG_DELETE_ON_CLOSE       = 0x04000000,
  FILE_FLAG_BACKUP_SEMANTICS      = 0x02000000,
  FILE_FLAG_POSIX_SEMANTICS       = 0x01000000,
  FILE_FLAG_OPEN_REPARSE_POINT    = 0x00200000,
  FILE_FLAG_OPEN_NO_RECALL        = 0x00100000,
  FILE_FLAG_FIRST_PIPE_INSTANCE   = 0x00080000
}

Handle CreateFileW(wchar* lpFileName, uint dwDesiredAccess, uint dwShareMode, SECURITY_ATTRIBUTES* lpSecurityAttributes, uint dwCreationDisposition, uint dwFlagsAndAttributes, Handle hTemplateFile);
alias CreateFileW CreateFile;

uint GetFileSize(Handle hFile, uint* lpFileSizeHigh);

int ReadFile(Handle hFile, void* lpBuffer, uint nNumberOfBytesToRead, out uint lpNumberOfBytesRead, OVERLAPPED* lpOverlapped);
int WriteFile(Handle hFile, void* lpBuffer, uint nNumberOfBytesToWrite, out uint lpNumberOfBytesWritten, OVERLAPPED* lpOverlapped);

int EncryptFileW(wchar* lpFileName);
alias EncryptFileW EncryptFile;

int DecryptFileW(wchar* lpFileName, uint dwReserved);
alias DecryptFileW DecryptFile;

int MoveFileW(wchar* lpExistingFileName, wchar* lpNewFileName);
alias MoveFileW MoveFile;

struct WIN32_FILE_ATTRIBUTE_DATA {
  uint dwFileAttributes;
  FILETIME ftCreationTime;
  FILETIME ftLastAccessTime;
  FILETIME ftLastWriteTime;
  uint nFileSizeHigh;
  uint nFileSizeLow;
}

int GetFileAttributesExW(wchar* lpFileName, int fInfoLevelId, void* lpFileInformation);
alias GetFileAttributesExW GetFileAttributesEx;

enum : uint {
  REPLACEFILE_WRITE_THROUGH       = 0x00000001,
  REPLACEFILE_IGNORE_MERGE_ERRORS = 0x00000002
}

int ReplaceFileW(wchar* lpReplacedFileName, wchar* lpReplacementFileName, wchar* lpBackupFileName, uint dwReplaceFlags, void* lpExclude, void* lpReserved);
alias ReplaceFileW ReplaceFile;

uint GetCurrentDirectoryW(uint nBufferLength, wchar* lpBuffer);
alias GetCurrentDirectoryW GetCurrentDirectory;

uint GetSystemDirectoryW(wchar* lpBuffer, uint nSize);
alias GetSystemDirectoryW GetSystemDirectory;

int CreateDirectoryW(wchar* lpPathName, SECURITY_ATTRIBUTES* lpSecurityAttributes);
alias CreateDirectoryW CreateDirectory;

int CloseHandle(Handle hObject);

alias void function(uint dwErrorCode, uint dwNumberOfBytesTransferred, OVERLAPPED* lpOverlapped) OVERLAPPED_COMPLETION_ROUTINE;

int ReadDirectoryChangesW(Handle hDirectory, void* lpBuffer, uint nBufferLength, int bWatchSubtree, uint dwNotifyFilter, ref uint lpBytesReturned, OVERLAPPED* lpOverlapped, OVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine);
alias ReadDirectoryChangesW ReadDirectoryChanges;

int RegOpenKeyExW(Handle hKey, wchar* lpSubKey, uint ulOptions, uint samDesired, out Handle phkResult);
alias RegOpenKeyExW RegOpenKeyEx;

int RegQueryValueExW(Handle hKey, wchar* lpValueName, uint* lpReserved, uint* lpType, ubyte* lpData, uint* lpcbData);
alias RegQueryValueExW RegQueryValueEx;

int RegQueryInfoKeyW(Handle hKey, wchar* lpClass, uint* lpcchClass, uint* lpReserved, uint* lpcSubKeys, uint* lpcbMaxSubKeyLen, uint* lpcbMaxClassLen, uint* lpcValues, uint* lpcbMaxValueNameLen, uint* lpcMaxValueLen, uint* lpcbSecurityDescriptor, FILETIME* lpftLastWriteTime);
alias RegQueryInfoKeyW RegQueryInfoKey;

int RegEnumKeyExW(Handle hKey, uint dwIndex, wchar* lpName, uint* lpcchName, uint* lpReserved, wchar* lpClass, uint* lpcchClass, FILETIME* lpftLastWriteTime);
alias RegEnumKeyExW RegEnumKeyEx;

int RegEnumValueW(Handle hKey, uint dwIndex, wchar* lpValueName, uint* lpcchValueName, uint* lpReserved, uint* lpType, ubyte* lpData, uint* lpcbData);
alias RegEnumValueW RegEnumValue;

int RegCloseKey(Handle hKey);

int RegFlushKey(Handle hKey);

int RegDeleteKeyW(Handle hKey, wchar* lpName);
alias RegDeleteKeyW RegDeleteKey;

int RegDeleteValueW(Handle hKey, wchar* lpValueName);
alias RegDeleteValueW RegDeleteValue;

int RegSetValueExW(Handle hKey, wchar* lpValueName, uint Reserved, uint dwType, ubyte* lpData, uint cbData);
alias RegSetValueExW RegSetValueEx;

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
  SMALL_RECT dwMaximumWindowSize;
  COORD dwMaximumSize;
}

enum : ushort {
  FOREGROUND_BLUE      = 0x0001,
  FOREGROUND_GREEN     = 0x0002,
  FOREGROUND_RED       = 0x0004,
  FOREGROUND_INTENSITY = 0x0008,
  FOREGROUND_MASK      = 0x000F,
  BACKGROUND_BLUE      = 0x0010,
  BACKGROUND_GREEN     = 0x0020,
  BACKGROUND_RED       = 0x0040,
  BACKGROUND_INTENSITY = 0x0080,
  BACKGROUND_MASK      = 0x00F0
}

int GetConsoleScreenBufferInfo(Handle hConsoleOutput, out CONSOLE_SCREEN_BUFFER_INFO lpConsoleScreenBufferInfo);

int SetConsoleTextAttribute(Handle hConsoleOutput, ushort wAttributes);

int FillConsoleOutputCharacterW(Handle hConsoleOutput, wchar cCharacter, uint nLength, COORD dwWriteCoord, out uint lpNumberOfCharsWritten);
alias FillConsoleOutputCharacterW FillConsoleOutputCharacter;

int FillConsoleOutputAttribute(Handle hConsoleOutput, ushort wAttribute, int nLength, COORD dwWriteCoord, out uint lpNumberOfAttrsWritten);

int SetConsoleCursorPosition(Handle hConsoleOutput, COORD dwCursorPosition);

uint GetConsoleCP();

int SetConsoleCP(uint wCodePageID);

uint GetConsoleOutputCP();

int SetConsoleOutputCP(uint wCodePageID);

uint GetConsoleTitleW(wchar* lpConsoleTitle, uint nSize);
alias GetConsoleTitleW GetConsoleTitle;

int SetConsoleTitleW(wchar* lpConsoleTitle);
alias SetConsoleTitleW SetConsoleTitle;

int Beep(uint dwFreq, uint dwDuration);

uint GetTickCount();

int GetComputerNameW(wchar* lpBuffer, ref uint nSize);
alias GetComputerNameW GetComputerName;

int SetComputerNameW(wchar* lpComputerName);
alias SetComputerNameW SetComputerName;

int GetUserNameW(wchar* lpBuffer, ref uint nSize);
alias GetUserNameW GetUserName;

wchar* GetCommandLineW();
alias GetCommandLineW GetCommandLine;

wchar** CommandLineToArgvW(wchar* lpCmdLine, out int pNumArgs);
alias CommandLineToArgvW CommandLineToArgv;

enum : uint {
  SHGFP_TYPE_CURRENT = 0,
  SHGFP_TYPE_DEFAULT = 1
}

int SHGetFolderPathW(Handle hwnd, int csidl, Handle hToken, uint dwFlags, wchar* pszPath);
alias SHGetFolderPathW SHGetFolderPath;

extern (D):

bool isWindowsVista() {
  return (LOBYTE(LOWORD(GetVersion())) >= 6);
}

public class Win32Exception : BaseException {

  private uint errorCode_;

  public this(uint error = GetLastError()) {
    this(error, getErrorMessage(error));
  }

  public this(uint error, string message) {
    super(message);
    errorCode_ = error;
  }

  public uint errorCode() {
    return errorCode_;
  }

  private static string getErrorMessage(uint error) {
    wchar[256] buffer;
    uint r = FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS, null, error, LOCALE_USER_DEFAULT, buffer.ptr, buffer.length + 1, null);
    if (r != 0) {
      string s = toUtf8(buffer.ptr, 0, r);
      while (r > 0) {
        char ch = s[r - 1];
        if (ch > ' ' && ch != '.')
          break;
        r--;
      }
      return s[0 .. r];
    }
    return format("Unspecified error (0x{0:X8})", error);
  }

}

// Runtime DLL support.

public class DllNotFoundException : BaseException {

  public this(string message = "Dll was not found.") {
    super(message);
  }

}

public class EntryPointNotFoundException : BaseException {

  public this(string message = "Entry point was not found.") {
    super(message);
  }

}

public enum CharSet {
  None,
  Ansi,
  Unicode,
  Auto
}

private Handle[string] moduleStore;

private T AddressOfFunction(T)(string dllName, string entryPoint, CharSet charSet) {
  Handle moduleHandle;
  if (auto value = dllName in moduleStore)
    moduleHandle = *value;
  else
    moduleStore[dllName] = moduleHandle = LoadLibrary(dllName.toUTF16z());

  if (moduleHandle == Handle.init)
    throw new DllNotFoundException("Unable to load DLL '" ~ dllName ~ "'.");

  T func = null;

  // '#' denotes an ordinal entry.
  if (entryPoint[0] == '#')
    func = cast(T)GetProcAddress(moduleHandle, cast(char*).toUshort(entryPoint[1 .. $]));
  else
    func = cast(T)GetProcAddress(moduleHandle, entryPoint.toStringz());

  if (func == null) {
    CharSet linkType = charSet;
    if (charSet == CharSet.Auto)
      linkType = ((GetVersion() & 0x80000000) == 0) ? CharSet.Unicode : CharSet.Ansi;

    string entryPointName = entryPoint.dup ~ ((linkType == CharSet.Ansi) ? 'A' : 'W');

    func = cast(T)GetProcAddress(moduleHandle, entryPointName.toStringz());

    if (func == null)
      throw new EntryPointNotFoundException("Unable to find an entry point named '" ~ entryPoint ~ "' in DLL '" ~ dllName ~ "'.");
  }

  return func;
}

public struct DllImport(string dllName, string entryPoint, TFunction, CharSet charSet = CharSet.Auto) {
  public static ReturnType!(TFunction) opCall(ParameterTypeTuple!(TFunction) args) {
    return AddressOfFunction!(TFunction)(dllName, entryPoint, charSet)(args);
  }
}

extern (Windows):

// XP and above
alias DllImport!("kernel32.dll", "GetGeoInfo",
  int function(int Location, uint GeoType, wchar* lpGeoData, int cchData, ushort LangId))
  GetGeoInfo;

alias DllImport!("nlsdl.dll", "DownlevelLCIDToLocaleName",
  int function(uint Locale, wchar* lpName, int cchName, uint dwFlags))
  DownlevelLCIDToLocaleName;

// Vista
alias DllImport!("kernel32.dll", "LCIDToLocaleName",
  int function(uint Locale, wchar* lpName, int cchName, uint dwFlags))
  LCIDToLocaleName;

enum : uint {
  FIND_STARTSWITH          = 0x00100000,
  FIND_ENDSWITH            = 0x00200000,
  FIND_FROMSTART           = 0x00400000,
  FIND_FROMEND             = 0x00800000
}

// Vista
alias DllImport!("kernel32.dll", "FindNLSString",
  int function(uint Locale, uint dwFindNLSStringFlags, wchar* lpStringSource, int cchSource, wchar* lpStringValue, int cchValue, int* pcchFound))
  FindNLSString;