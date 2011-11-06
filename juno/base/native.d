/**
 * Copyright: (c) 2008 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.base.native;

private import juno.base.core,
  juno.base.string;

private import std.string : format;
private import std.conv : to;
private import std.traits, std.typetuple;

private import std.c.windows.windows :
  FILETIME,
  SYSTEMTIME,
  GetSystemTimeAsFileTime,
  FileTimeToLocalFileTime,
  InterlockedIncrement,
  InterlockedDecrement;

pragma(lib, "shell32.lib");
pragma(lib, "advapi32.lib");

extern(Windows):

version(D_Version2) {
Handle INVALID_HANDLE_VALUE = cast(Handle)-1;
} else {
extern Handle INVALID_HANDLE_VALUE;
}

const uint MAX_PATH = 260;

enum : uint {
  ERROR_SUCCESS                         = 0,
  ERROR_INVALID_FUNCTION                = 1,
  ERROR_FILE_NOT_FOUND                  = 2,
  ERROR_PATH_NOT_FOUND                  = 3,
  ERROR_TOO_MANY_OPEN_FILES             = 4,
  ERROR_ACCESS_DENIED                   = 5,
  ERROR_INVALID_HANDLE                  = 6,
  ERROR_BAD_IMPERSONATION_LEVEL         = 1346,
  ERROR_CLASS_ALREADY_EXISTS            = 1410
}

enum : uint {
  FACILITY_NULL                   = 0,
  FACILITY_RPC                    = 1,
  FACILITY_DISPATCH               = 2,
  FACILITY_STORAGE                = 3,
  FACILITY_ITF                    = 4,
  FACILITY_WIN32                  = 7,
  FACILITY_WINDOWS                = 8,
  FACILITY_SSPI                   = 9,
  FACILITY_SECURITY               = 9,
  FACILITY_CONTROL                = 10,
  FACILITY_CERT                   = 11,
  FACILITY_INTERNET               = 12,
  FACILITY_MEDIASERVER            = 13,
  FACILITY_MSMQ                   = 14,
  FACILITY_SETUPAPI               = 15,
  FACILITY_SCARD                  = 16,
  FACILITY_COMPLUS                = 17,
  FACILITY_AAF                    = 18,
  FACILITY_URT                    = 19,
  FACILITY_ACS                    = 20,
  FACILITY_DPLAY                  = 21,
  FACILITY_UMI                    = 22,
  FACILITY_SXS                    = 23,
  FACILITY_WINDOWS_CE             = 24,
  FACILITY_HTTP                   = 25,
  FACILITY_BACKGROUNDCOPY         = 32,
  FACILITY_CONFIGURATION          = 33,
  FACILITY_STATE_MANAGEMENT       = 34,
  FACILITY_METADIRECTORY          = 35,
  FACILITY_WINDOWSUPDATE          = 36,
  FACILITY_DIRECTORYSERVICE       = 37
}

enum {
  SEVERITY_SUCCESS = 0,
  SEVERITY_ERROR = 1
}

template tMAKE_SCODE(uint sev, uint fac, uint code) {
  const tMAKE_SCODE = ((sev << 31) | (fac << 16) | code);
}

enum : uint {
  FORMAT_MESSAGE_ALLOCATE_BUFFER  = 0x00000100,
  FORMAT_MESSAGE_ARGUMENT_ARRAY   = 0x00002000,
  FORMAT_MESSAGE_FROM_HMODULE     = 0x00000800,
  FORMAT_MESSAGE_FROM_STRING      = 0x00000400,
  FORMAT_MESSAGE_FROM_SYSTEM      = 0x00001000,
  FORMAT_MESSAGE_IGNORE_INSERTS   = 0x00000200
}

int FormatMessageW(uint dwFlags, void* lpSource, uint dwMessageId, uint dwLanguageId, wchar* lpBuffer, uint nSize, void** Arguments);
alias FormatMessageW FormatMessage;

enum : uint {
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

Handle LocalAlloc(uint uFlags, size_t cb);

Handle LocalFree(Handle hMem);

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

Handle GlobalReAlloc(Handle hMem, size_t dwBytes, uint uFlags);

size_t GlobalSize(Handle hMem);

void* GlobalLock(Handle hMem);

int GlobalUnlock(Handle hMem);

Handle GlobalFree(Handle hMem);

enum : uint {
  HEAP_NO_SERIALIZE               = 0x00000001,
  HEAP_GROWABLE                   = 0x00000002,
  HEAP_GENERATE_EXCEPTIONS        = 0x00000004,
  HEAP_ZERO_MEMORY                = 0x00000008,
  HEAP_REALLOC_IN_PLACE_ONLY      = 0x00000010,
  HEAP_TAIL_CHECKING_ENABLED      = 0x00000020,
  HEAP_FREE_CHECKING_ENABLED      = 0x00000040,
  HEAP_DISABLE_COALESCE_ON_FREE   = 0x00000080,
  HEAP_CREATE_ALIGN_16            = 0x00010000,
  HEAP_CREATE_ENABLE_TRACING      = 0x00020000,
  HEAP_CREATE_ENABLE_EXECUTE      = 0x00040000,
  HEAP_MAXIMUM_TAG                = 0x0FFF,
  HEAP_PSEUDO_TAG_FLAG            = 0x8000,
  HEAP_TAG_SHIFT                  = 18
}

Handle HeapCreate(uint flOptions, size_t dwInitialSize, size_t dwMaximumSize);

int HeapDestroy(Handle hHeap);

Handle GetProcessHeap();

void* HeapAlloc(Handle hHeap, uint dwFlags, size_t dwBytes);

int HeapFree(Handle hHeap, uint dwFlags, void* lpMem);

uint GetLastError();

Handle LoadLibraryW(in wchar* lpLibFileName);
alias LoadLibraryW LoadLibrary;

void* GetProcAddress(Handle hModule, in char* lpProcName);

uint GetVersion();

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

enum {
  GENERIC_READ = 0x80000000,
  GENERIC_WRITE = 0x40000000,
  GENERIC_EXECUTE = 0x20000000,
  GENERIC_ALL = 0x10000000
}

enum : uint {
  FILE_SHARE_READ = 0x00000001,
  FILE_SHARE_WRITE = 0x00000002,
  FILE_SHARE_DELETE = 0x00000004
}

enum : uint {
  CREATE_NEW = 1,
  CREATE_ALWAYS = 2,
  OPEN_EXISTING = 3,
  OPEN_ALWAYS = 4,
  TRUNCATE_EXISTING = 5
}

Handle CreateFileW(in wchar* lpFileName, uint dwDesiredAccess, uint dwShareMode, SECURITY_ATTRIBUTES* lpSecurityAttributes, uint dwCreationDisposition, uint dwFlagsAndAttributes, Handle hTemplateFile);
alias CreateFileW CreateFile;

int WriteFile(Handle hFile, in void* lpBuffer, uint nNumberOfBytesToWrite, out uint lpNumberOfBytesWritten, OVERLAPPED* lpOverlapped);

int ReadFile(Handle hFile, void* lpBuffer, uint nNumberOfBytesToRead, out uint lpNumberOfBytesRead, OVERLAPPED* lpOverlapped);

enum : uint {
  FILE_BEGIN,
  FILE_CURRENT,
  FILE_END
}

uint SetFilePointer(Handle hFile, int lDistanceToMove, ref uint lpDistanceToMoveHigh, uint dwMoveMethod);

int SetFilePointerEx(Handle hFile, long lDistanceToMove, out long lpNewFilePointer, uint dwMoveMethod);

int GetFileSizeEx(Handle hFile, out long lpFileSize);

int CloseHandle(Handle hObject);

Handle GetModuleHandleW(in wchar* lpModuleName);
alias GetModuleHandleW GetModuleHandle;

uint GetModuleFileNameW(Handle hModule, wchar* lpFilename, uint nSize);
alias GetModuleFileNameW GetModuleFileName;

Handle LoadResource(Handle hModule, Handle hResInfo);

uint SizeofResource(Handle hModule, Handle hResInfo);

void* LockResource(Handle hResData);

Handle FindResourceW(Handle hModule, in wchar* lpName, in wchar* lpType);
alias FindResourceW FindResource;

alias int function(Handle hModule, wchar* lpType, int lParam) ENUMRESTYPEPROCW;
alias ENUMRESTYPEPROCW ENUMRESTYPEPROC;

int EnumResourceTypesW(Handle hModule, ENUMRESTYPEPROCW lpEnumFunc, int lParam);
alias EnumResourceTypesW EnumResourceTypes;

alias int function(Handle hModule, wchar* lpType, wchar* lpName, int lParam) ENUMRESNAMEPROCW;
alias ENUMRESNAMEPROCW ENUMRESNAMEPROC;

int EnumResourceNamesW(Handle hModule, in wchar* lpType, ENUMRESNAMEPROCW lpEnumFunc, int lParam);
alias EnumResourceNamesW EnumResourceNames;

const uint TLS_OUT_OF_INDEXES = 0xFFFFFFFF;

uint TlsAlloc();

int TlsFree(uint dwTlsIndex);

void* TlsGetValue(uint dwTlsIndex);

int TlsSetValue(uint dwTlsIndex, void* lpTlsValue);

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
}

template tMAKELCID(ushort lgid, ushort srtid) {
  const tMAKELCID = (srtid << 16) | lgid;
}

template tMAKELANGID(ushort p, ushort s) {
  const tMAKELANGID = (s << 10)  | p;
}

extern ushort SUBLANGID(ushort lgid);

enum : uint {
  LCID_INSTALLED          = 0x00000001,
  LCID_SUPPORTED          = 0x00000002,
  LCID_ALTERNATE_SORTS    = 0x00000004
}

enum : ushort {
  SUBLANG_NEUTRAL                            = 0x00,
  SUBLANG_DEFAULT                            = 0x01,
  SUBLANG_SYS_DEFAULT                        = 0x02,
}

enum : ushort {
  LANG_NEUTRAL                    = 0x00,
  LANG_INVARIANT                  = 0x7f,
  LANG_SYSTEM_DEFAULT             = tMAKELANGID!(LANG_NEUTRAL, SUBLANG_SYS_DEFAULT),
  LANG_USER_DEFAULT               = tMAKELANGID!(LANG_NEUTRAL, SUBLANG_DEFAULT)
}

enum : ushort {
  SORT_DEFAULT                    = 0x0
}

enum : uint {
  LOCALE_USER_DEFAULT = tMAKELCID!(LANG_USER_DEFAULT, SORT_DEFAULT),
  LOCALE_SYSTEM_DEFAULT = tMAKELCID!(LANG_SYSTEM_DEFAULT, SORT_DEFAULT),
  LOCALE_NEUTRAL = tMAKELCID!(tMAKELANGID!(LANG_NEUTRAL, SUBLANG_NEUTRAL), SORT_DEFAULT),
  LOCALE_INVARIANT = tMAKELCID!(tMAKELANGID!(LANG_INVARIANT, SUBLANG_NEUTRAL), SORT_DEFAULT)
}

enum : uint {
  LOCALE_NOUSEROVERRIDE        = 0x80000000,
  LOCALE_USE_CP_ACP            = 0x40000000,
  LOCALE_RETURN_NUMBER         = 0x20000000,
  LOCALE_ILANGUAGE             = 0x00000001,
  LOCALE_SLANGUAGE             = 0x00000002,
  LOCALE_SENGLANGUAGE          = 0x00001001,
  LOCALE_SABBREVLANGNAME       = 0x00000003,
  LOCALE_SNATIVELANGNAME       = 0x00000004,
  LOCALE_ICOUNTRY              = 0x00000005,
  LOCALE_SCOUNTRY              = 0x00000006,
  LOCALE_SENGCOUNTRY           = 0x00001002,
  LOCALE_SABBREVCTRYNAME       = 0x00000007,
  LOCALE_SNATIVECTRYNAME       = 0x00000008,
  LOCALE_IGEOID                = 0x0000005B,
  LOCALE_IDEFAULTLANGUAGE      = 0x00000009,
  LOCALE_IDEFAULTCOUNTRY       = 0x0000000A,
  LOCALE_IDEFAULTCODEPAGE      = 0x0000000B,
  LOCALE_IDEFAULTANSICODEPAGE  = 0x00001004,
  LOCALE_IDEFAULTMACCODEPAGE   = 0x00001011,
  LOCALE_SLIST                 = 0x0000000C,
  LOCALE_IMEASURE              = 0x0000000D,
  LOCALE_SDECIMAL              = 0x0000000E,
  LOCALE_STHOUSAND             = 0x0000000F,
  LOCALE_SGROUPING             = 0x00000010,
  LOCALE_IDIGITS               = 0x00000011,
  LOCALE_ILZERO                = 0x00000012,
  LOCALE_INEGNUMBER            = 0x00001010,
  LOCALE_SNATIVEDIGITS         = 0x00000013,
  LOCALE_SCURRENCY             = 0x00000014,
  LOCALE_SINTLSYMBOL           = 0x00000015,
  LOCALE_SMONDECIMALSEP        = 0x00000016,
  LOCALE_SMONTHOUSANDSEP       = 0x00000017,
  LOCALE_SMONGROUPING          = 0x00000018,
  LOCALE_ICURRDIGITS           = 0x00000019,
  LOCALE_IINTLCURRDIGITS       = 0x0000001A,
  LOCALE_ICURRENCY             = 0x0000001B,
  LOCALE_INEGCURR              = 0x0000001C,
  LOCALE_SDATE                 = 0x0000001D,
  LOCALE_STIME                 = 0x0000001E,
  LOCALE_SSHORTDATE            = 0x0000001F,
  LOCALE_SLONGDATE             = 0x00000020,
  LOCALE_STIMEFORMAT           = 0x00001003,
  LOCALE_IDATE                 = 0x00000021,
  LOCALE_ILDATE                = 0x00000022,
  LOCALE_ITIME                 = 0x00000023,
  LOCALE_ITIMEMARKPOSN         = 0x00001005,
  LOCALE_ICENTURY              = 0x00000024,
  LOCALE_ITLZERO               = 0x00000025,
  LOCALE_IDAYLZERO             = 0x00000026,
  LOCALE_IMONLZERO             = 0x00000027,
  LOCALE_S1159                 = 0x00000028,
  LOCALE_S2359                 = 0x00000029,
  LOCALE_ICALENDARTYPE         = 0x00001009,
  LOCALE_IOPTIONALCALENDAR     = 0x0000100B,
  LOCALE_IFIRSTDAYOFWEEK       = 0x0000100C,
  LOCALE_IFIRSTWEEKOFYEAR      = 0x0000100D,
  LOCALE_SDAYNAME1             = 0x0000002A,
  LOCALE_SDAYNAME2             = 0x0000002B,
  LOCALE_SDAYNAME3             = 0x0000002C,
  LOCALE_SDAYNAME4             = 0x0000002D,
  LOCALE_SDAYNAME5             = 0x0000002E,
  LOCALE_SDAYNAME6             = 0x0000002F,
  LOCALE_SDAYNAME7             = 0x00000030,
  LOCALE_SABBREVDAYNAME1       = 0x00000031,
  LOCALE_SABBREVDAYNAME2       = 0x00000032,
  LOCALE_SABBREVDAYNAME3       = 0x00000033,
  LOCALE_SABBREVDAYNAME4       = 0x00000034,
  LOCALE_SABBREVDAYNAME5       = 0x00000035,
  LOCALE_SABBREVDAYNAME6       = 0x00000036,
  LOCALE_SABBREVDAYNAME7       = 0x00000037,
  LOCALE_SMONTHNAME1           = 0x00000038,
  LOCALE_SMONTHNAME2           = 0x00000039,
  LOCALE_SMONTHNAME3           = 0x0000003A,
  LOCALE_SMONTHNAME4           = 0x0000003B,
  LOCALE_SMONTHNAME5           = 0x0000003C,
  LOCALE_SMONTHNAME6           = 0x0000003D,
  LOCALE_SMONTHNAME7           = 0x0000003E,
  LOCALE_SMONTHNAME8           = 0x0000003F,
  LOCALE_SMONTHNAME9           = 0x00000040,
  LOCALE_SMONTHNAME10          = 0x00000041,
  LOCALE_SMONTHNAME11          = 0x00000042,
  LOCALE_SMONTHNAME12          = 0x00000043,
  LOCALE_SMONTHNAME13          = 0x0000100E,
  LOCALE_SABBREVMONTHNAME1     = 0x00000044,
  LOCALE_SABBREVMONTHNAME2     = 0x00000045,
  LOCALE_SABBREVMONTHNAME3     = 0x00000046,
  LOCALE_SABBREVMONTHNAME4     = 0x00000047,
  LOCALE_SABBREVMONTHNAME5     = 0x00000048,
  LOCALE_SABBREVMONTHNAME6     = 0x00000049,
  LOCALE_SABBREVMONTHNAME7     = 0x0000004A,
  LOCALE_SABBREVMONTHNAME8     = 0x0000004B,
  LOCALE_SABBREVMONTHNAME9     = 0x0000004C,
  LOCALE_SABBREVMONTHNAME10    = 0x0000004D,
  LOCALE_SABBREVMONTHNAME11    = 0x0000004E,
  LOCALE_SABBREVMONTHNAME12    = 0x0000004F,
  LOCALE_SABBREVMONTHNAME13    = 0x0000100F,
  LOCALE_SPOSITIVESIGN         = 0x00000050,
  LOCALE_SNEGATIVESIGN         = 0x00000051,
  LOCALE_IPOSSIGNPOSN          = 0x00000052,
  LOCALE_INEGSIGNPOSN          = 0x00000053,
  LOCALE_IPOSSYMPRECEDES       = 0x00000054,
  LOCALE_IPOSSEPBYSPACE        = 0x00000055,
  LOCALE_INEGSYMPRECEDES       = 0x00000056,
  LOCALE_INEGSEPBYSPACE        = 0x00000057,
  LOCALE_FONTSIGNATURE         = 0x00000058,
  LOCALE_SISO639LANGNAME       = 0x00000059,
  LOCALE_SISO3166CTRYNAME      = 0x0000005A,
  LOCALE_IDEFAULTEBCDICCODEPAGE= 0x00001012,
  LOCALE_IPAPERSIZE            = 0x0000100A,
  LOCALE_SENGCURRNAME          = 0x00001007,
  LOCALE_SNATIVECURRNAME       = 0x00001008,
  LOCALE_SYEARMONTH            = 0x00001006,
  LOCALE_SSORTNAME             = 0x00001013,
  LOCALE_IDIGITSUBSTITUTION    = 0x00001014,
  LOCALE_SNAME                 = 0x0000005c,
  LOCALE_SDURATION             = 0x0000005d,
  LOCALE_SKEYBOARDSTOINSTALL   = 0x0000005e,
  LOCALE_SSHORTESTDAYNAME1     = 0x00000060,
  LOCALE_SSHORTESTDAYNAME2     = 0x00000061,
  LOCALE_SSHORTESTDAYNAME3     = 0x00000062,
  LOCALE_SSHORTESTDAYNAME4     = 0x00000063,
  LOCALE_SSHORTESTDAYNAME5     = 0x00000064,
  LOCALE_SSHORTESTDAYNAME6     = 0x00000065,
  LOCALE_SSHORTESTDAYNAME7     = 0x00000066,
  LOCALE_SISO639LANGNAME2      = 0x00000067,
  LOCALE_SISO3166CTRYNAME2     = 0x00000068,
  LOCALE_SNAN                  = 0x00000069,
  LOCALE_SPOSINFINITY          = 0x0000006a,
  LOCALE_SNEGINFINITY          = 0x0000006b,
  LOCALE_SSCRIPTS              = 0x0000006c,
  LOCALE_SPARENT               = 0x0000006d,
  LOCALE_SCONSOLEFALLBACKNAME  = 0x0000006e,
  LOCALE_SLANGDISPLAYNAME      = 0x0000006f
}

int GetLocaleInfoW(uint Locale, uint LCType, wchar* lpLCData, int cchData);
alias GetLocaleInfoW GetLocaleInfo;

alias int function(wchar*) LOCALE_ENUMPROCW;
alias LOCALE_ENUMPROCW LOCALE_ENUMPROC;

int EnumSystemLocalesW(LOCALE_ENUMPROCW lpLocaleEnumProc, uint dwFlags);
alias EnumSystemLocalesW EnumSystemLocales;

enum : uint {
  CAL_NOUSEROVERRIDE = LOCALE_NOUSEROVERRIDE,
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
  CAL_GREGORIAN                = 1,
  CAL_GREGORIAN_US             = 2,
  CAL_JAPAN                    = 3,
  CAL_TAIWAN                   = 4,
  CAL_KOREA                    = 5,
  CAL_HIJRI                    = 6,
  CAL_THAI                     = 7,
  CAL_HEBREW                   = 8,
  CAL_GREGORIAN_ME_FRENCH      = 9,
  CAL_GREGORIAN_ARABIC         = 10,
  CAL_GREGORIAN_XLIT_ENGLISH   = 11,
  CAL_GREGORIAN_XLIT_FRENCH    = 12,
  CAL_UMALQURA                 = 23
}

int GetCalendarInfoW(uint Locale, uint Calendar, uint CalType, wchar* lpCalData, int cchData, uint* lpValue);
alias GetCalendarInfoW GetCalendarInfo;

enum : uint {
  DATE_SHORTDATE           = 0x00000001,
  DATE_LONGDATE            = 0x00000002,
  DATE_USE_ALT_CALENDAR    = 0x00000004
}

int GetDateFormatW(uint Locale, uint dwFlags, SYSTEMTIME* lpDate, in wchar* lpFormat, wchar* lpDateStr, int cchDate);
alias GetDateFormatW GetDateFormat;

enum : uint {
  GEO_NATION            = 0x0001,
  GEO_LATITUDE          = 0x0002,
  GEO_LONGITUDE         = 0x0003,
  GEO_ISO2              = 0x0004,
  GEO_ISO3              = 0x0005,
  GEO_RFC1766           = 0x0006,
  GEO_LCID              = 0x0007,
  GEO_FRIENDLYNAME      = 0x0008,
  GEO_OFFICIALNAME      = 0x0009,
  GEO_TIMEZONES         = 0x000A,
  GEO_OFFICIALLANGUAGES = 0x000B
}

//int GetGeoInfoW(uint Location, uint GeoType, wchar* lpGeoData, int cchData, ushort LangId);
//alias GetGeoInfoW GetGeoInfo;

alias int function(wchar* lpCalendarInfoString) CALINFO_ENUMPROCW;
alias int function(wchar* lpCalendarInfoString, uint Calendar) CALINFO_ENUMPROCEXW;

int EnumCalendarInfoW(CALINFO_ENUMPROCW lpCalInfoEnumProc, uint Locale, uint Calendar, uint CalType);
alias EnumCalendarInfoW EnumCalendarInfo;

int EnumCalendarInfoExW(CALINFO_ENUMPROCEXW lpCalInfoEnumProcEx, uint Locale, uint Calendar, uint CalType);
alias EnumCalendarInfoExW EnumCalendarInfoEx;

alias int function(wchar* lpDateFormatString, uint CalendarId) DATEFMT_ENUMPROCEXW;

int EnumDateFormatsExW(DATEFMT_ENUMPROCEXW lpDateFmtEnumProcEx, uint Locale, uint dwFlags);
alias EnumDateFormatsExW EnumDateFormatsEx;

alias int function(wchar* lpTimeFormatString) TIMEFMT_ENUMPROCW;

int EnumTimeFormatsW(TIMEFMT_ENUMPROCW lpTimeFmtEnumProc, uint Locale, uint dwFlags);
alias EnumTimeFormatsW EnumTimeFormats;

uint GetThreadLocale();

int SetThreadLocale(uint Locale);

uint GetUserDefaultLCID();

ushort GetUserDefaultLangID();

ushort GetSystemDefaultLangID();

enum : uint {
  NORM_IGNORECASE          = 0x00000001,
  NORM_IGNORENONSPACE      = 0x00000002,
  NORM_IGNORESYMBOLS       = 0x00000004,
  NORM_IGNOREKANATYPE      = 0x00010000,
  NORM_IGNOREWIDTH         = 0x00020000,
  NORM_LINGUISTIC_CASING   = 0x08000000
}

enum {
  CP_ACP                   = 0,
  CP_OEMCP                 = 1,
  CP_MACCP                 = 2,
  CP_THREAD_ACP            = 3,
  CP_SYMBOL                = 42,
  CP_UTF7                  = 65000,
  CP_UTF8                  = 65001
}

struct CPINFO {
  uint MaxCharSize;
  ubyte[2] DefaultChar;
  ubyte[12] LeadByte;
}

int GetCPInfo(uint CodePage, out CPINFO lpCPInfo);

uint GetACP();

int CompareStringW(uint Locale, uint dwCmpFlags, in wchar* lpString1, int cchCount1, in wchar* lpString2, int cchCount2);
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

int MultiByteToWideChar(uint CodePage, uint dwFlags, in char* lpMultiByteStr, int cbMultiByte, wchar* lpWideCharStr, int cchWideChar);
int WideCharToMultiByte(uint CodePage, uint dwFlags, wchar* lpWideCharStr, int cchWideChar, char* lpMultiByteStr, int cbMultiByte, char* lpDefaultChar, int* lpUseDefaultChar);

struct SECURITY_ATTRIBUTES {
  uint nLength;
  void* lpSecurityDescriptor;
  int bInheritHandle;
}

struct ACL {
  ubyte AclRevision;
  ubyte Sbsz1;
  ushort AclSize;
  ushort AceCount;
  ushort Sbsz2;
}

struct SECURITY_DESCRIPTOR {
  ubyte Revision;
  ubyte Sbz1;
  ushort Control;
  void* Owner;
  void* Group;
  ACL* Sacl;
  ACL* Dacl;
}

struct COAUTHIDENTITY {
  wchar* User;
  uint UserLength;
  wchar* Domain;
  uint DomainLength;
  wchar* Password;
  uint PasswordLength;
  uint Flags;
}

struct COAUTHINFO {
  uint dwAuthnSvc;
  uint dwAuthzSvc;
  wchar* pwszServerPrincName;
  uint dwAuthnLevel;
  uint dwImpersonationLevel;
  COAUTHIDENTITY* pAuthIdentityData;
  uint dwCapabilities;
}

uint GetFullPathNameW(in wchar* lpFileName, uint nBufferLength, wchar* lpBuffer, wchar** lpFilePart);
alias GetFullPathNameW GetFullPathName;

uint GetLongPathNameW(in wchar* lpszShortPath, wchar* lpszLongPath, uint cchBuffer);
alias GetLongPathNameW GetLongPathName;

int GetComputerNameW(in wchar* lpBuffer, ref uint nSize);
alias GetComputerNameW GetComputerName;

int SetComputerNameW(in wchar* lpComputerName);
alias SetComputerNameW SetComputerName;

int GetUserNameW(in wchar* lpBuffer, ref uint nSize);
alias GetUserNameW GetUserName;

wchar* GetCommandLineW();
alias GetCommandLineW GetCommandLine;

wchar** CommandLineToArgvW(in wchar* lpCmdLine, out int pNumArgs);
alias CommandLineToArgvW CommandLineToArgv;

version(D_Version2) {

Handle HKEY_CLASSES_ROOT = cast(Handle)0x80000000;
Handle HKEY_CURRENT_USER = cast(Handle)0x80000000;
Handle HKEY_LOCAL_MACHINE = cast(Handle)0x80000000;
Handle HKEY_USERS = cast(Handle)0x80000000;
Handle HKEY_PERFORMANCE_DATA = cast(Handle)0x80000000;
Handle HKEY_CURRENT_CONFIG = cast(Handle)0x80000000;
Handle HKEY_DYN_DATA = cast(Handle)0x80000000;

} else {

extern Handle HKEY_CLASSES_ROOT;
extern Handle HKEY_CURRENT_USER;
extern Handle HKEY_LOCAL_MACHINE;
extern Handle HKEY_USERS;
extern Handle HKEY_PERFORMANCE_DATA;
extern Handle HKEY_CURRENT_CONFIG;
extern Handle HKEY_DYN_DATA;

}

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

int RegCloseKey(Handle hKey);

int RegFlushKey(Handle hKey);

int RegOpenKeyExW(Handle hKey, in wchar* lpSubKey, uint ulOptions, uint samDesired, out Handle phkResult);
alias RegOpenKeyExW RegOpenKeyEx;

int RegCreateKeyExW(Handle hKey, in wchar* lpSubKey, uint Reserved, wchar* lpClass, uint dwOptions, uint samDesired, SECURITY_ATTRIBUTES* lpSecurityAttributes, out Handle phkResult, uint* lpdwDisposition);
alias RegCreateKeyExW RegCreateKeyEx;

int RegQueryValueExW(Handle hKey, in wchar* lpValueName, uint* lpReserved, uint* lpType, ubyte* lpData, uint* lpcbData);
alias RegQueryValueExW RegQueryValueEx;

int RegSetValueExW(Handle hKey, in wchar* lpValueName, uint Reserved, uint dwType, in ubyte* lpData, uint cbData);
alias RegSetValueExW RegSetValueEx;

int RegEnumKeyW(Handle hKey, uint dwIndex, wchar* lpName, uint cchName);
alias RegEnumKeyW RegEnumKey;

int RegEnumKeyExW(Handle hKey, uint dwIndex, wchar* lpName, uint* lpcchName, uint* lpReserved, wchar* lpClass, uint* lpcchClass, FILETIME* lpftWriteTime);
alias RegEnumKeyExW RegEnumKeyEx;

int RegEnumValueW(Handle hKey, uint dwIndex, wchar* lpValueName, uint* lpcchValueName, uint* lpReserved, uint* lpType, ubyte* lpData, uint* lpcbData);
alias RegEnumValueW RegEnumValue;

int RegQueryInfoKeyW(Handle hKey, wchar* lpClass, uint* lpcchClass, uint* lpReserved, uint* lpcSubKeys, uint* lpcbMaxSubKeyLen, uint* lpcbMaxClassLen, uint* lpcValues, uint* lpcbMaxValueNameLen, uint* lpcbMaxValueLen, uint* lpcbSecurityDescriptor, FILETIME* lpftLastWriteTime);
alias RegQueryInfoKeyW RegQueryInfoKey;

int RegDeleteKeyW(Handle hKey, in wchar* lpSubKey);
alias RegDeleteKeyW RegDeleteKey;

int RegDeleteValueW(Handle hKey, in wchar* lpValueName);
alias RegDeleteValueW RegDeleteValue;

int RegSaveKeyW(Handle hKey, in wchar* lpFile, SECURITY_ATTRIBUTES* lpSecurityAttributes);
alias RegSaveKeyW RegSaveKey;

uint ExpandEnvironmentStringsW(in wchar* lpSrc, wchar* lpDst, uint nSize);
alias ExpandEnvironmentStringsW ExpandEnvironmentStrings;

int Beep(uint dwFreq, uint dwDuration);

uint GetTickCount();

class Win32Exception : Exception {

  private uint errorCode_;

  this(uint errorCode = GetLastError()) {
    this(errorCode, getErrorMessage(errorCode));
  }

  this(uint errorCode, string message) {
    super(message);
    errorCode_ = errorCode;
  }

  uint errorCode() {
    return errorCode_;
  }

  private static string getErrorMessage(uint errorCode) {
    wchar[256] buffer;
    uint result = FormatMessageW(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS, null, errorCode, 0, buffer.ptr, buffer.length + 1, null);
    if (result != 0) {
      string s = .toUTF8(buffer[0 .. result]);

      while (result > 0) {
        char c = s[result - 1];
        if (c > ' ' && c != '.')
          break;
        result--;
      }
      return s[0 .. result];
    }
    return format("Unspecified error (0x%08X)", errorCode);
  }

}

// Runtime DLL support.

class DllNotFoundException : Exception {

  this(string message = "Dll was not found.") {
    super(message);
  }

}

class EntryPointNotFoundException : Exception {

  this(string message = "Entry point was not found.") {
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
    moduleStore[dllName] = moduleHandle = LoadLibrary(dllName.toUtf16z());

  if (moduleHandle == Handle.init)
    throw new DllNotFoundException("Unable to load DLL '" ~ dllName ~ "'.");

  T func = null;

  // '#' denotes an ordinal entry.
  if (entryPoint[0] == '#')
    func = cast(T)GetProcAddress(moduleHandle, cast(char*).to!ushort(entryPoint[1 .. $]));
  else
    func = cast(T)GetProcAddress(moduleHandle, entryPoint.toUtf8z());

  if (func == null) {
    CharSet linkType = charSet;
    if (charSet == CharSet.Auto)
      linkType = ((GetVersion() & 0x80000000) == 0) ? CharSet.Unicode : CharSet.Ansi;

    string entryPointName = entryPoint.dup ~ ((linkType == CharSet.Ansi) ? 'A' : 'W');

    func = cast(T)GetProcAddress(moduleHandle, entryPointName.toUtf8z());

    if (func == null)
      throw new EntryPointNotFoundException("Unable to find an entry point named '" ~ entryPoint ~ "' in DLL '" ~ dllName ~ "'.");
  }

  return func;
}

struct DllImport(string dllName, string entryPoint, TFunction, CharSet charSet = CharSet.Auto) {
  static ReturnType!(TFunction) opCall(ParameterTypeTuple!(TFunction) args) {
    return AddressOfFunction!(TFunction)(dllName, entryPoint, charSet)(args);
  }
}

// XP
alias DllImport!("kernel32.dll", "GetGeoInfo", 
  int function(uint Location, uint GeoType, wchar* lpGeoData, int cchData, ushort LangId)) 
  GetGeoInfo;

enum : uint {
  FIND_STARTSWITH          = 0x00100000,
  FIND_ENDSWITH            = 0x00200000,
  FIND_FROMSTART           = 0x00400000,
  FIND_FROMEND             = 0x00800000
}

// Vista
alias DllImport!("kernel32", "FindNLSString",
  int function(uint Locale, uint dwFindNLSStringFlags, in wchar* lpStringSource, int cchSource, in wchar* lpStringValue, int cchValue, int* pcchFound))
  FindNLSString;