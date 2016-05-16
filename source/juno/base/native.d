/**
 * Copyright: (c) 2009 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.base.native;

import juno.base.core,
  std.traits,
  std.typetuple;
import std.utf : toUTF8, toUTF16z;
import std.string : toStringz;
import core.sys.windows.windows : 
  HIWORD, LOWORD;
static import std.string,
  std.conv;

pragma(lib, "kernel32.lib");
pragma(lib, "advapi32.lib");
pragma(lib, "shell32.lib");
//pragma(lib, "version.lib");

extern(Windows):

const uint _WIN32_WINNT = 0x601;
const uint _WIN32_WINDOWS = uint.max;
const uint _WIN32_IE = 0x700;

const uint WINVER = _WIN32_WINDOWS < _WIN32_WINNT ? _WIN32_WINDOWS : _WIN32_WINNT;

const uint MAX_PATH = 260;

alias int BOOL;

enum : BOOL {
  FALSE,
  TRUE
}

enum : uint {
  ERROR_SUCCESS                 = 0,
  ERROR_INVALID_FUNCTION        = 1,
  ERROR_FILE_NOT_FOUND          = 2,
  ERROR_PATH_NOT_FOUND          = 3,
  ERROR_TOO_MANY_OPEN_FILES     = 4,
  ERROR_ACCESS_DENIED           = 5,
  ERROR_INVALID_HANDLE          = 6,
  ERROR_NO_MORE_FILES           = 18,
  ERROR_BAD_LENGTH              = 24,
  ERROR_INSUFFICIENT_BUFFER     = 122,
  ERROR_ALREADY_EXISTS          = 183,
  ERROR_MORE_DATA               = 234,
  ERROR_NO_MORE_ITEMS           = 259,
  ERROR_IO_PENDING              = 997,
  ERROR_CANCELLED               = 1223,
  ERROR_BAD_IMPERSONATION_LEVEL = 1346,
  ERROR_CLASS_ALREADY_EXISTS    = 1410,
  NTE_BAD_DATA                  = 0x80090005,
  NTE_BAD_SIGNATURE             = 0x80090006
}

enum : uint {
  FACILITY_NULL             = 0,
  FACILITY_RPC              = 1,
  FACILITY_DISPATCH         = 2,
  FACILITY_STORAGE          = 3,
  FACILITY_ITF              = 4,
  FACILITY_WIN32            = 7,
  FACILITY_WINDOWS          = 8,
  FACILITY_SSPI             = 9,
  FACILITY_SECURITY         = 9,
  FACILITY_CONTROL          = 10,
  FACILITY_CERT             = 11,
  FACILITY_INTERNET         = 12,
  FACILITY_MEDIASERVER      = 13,
  FACILITY_MSMQ             = 14,
  FACILITY_SETUPAPI         = 15,
  FACILITY_SCARD            = 16,
  FACILITY_COMPLUS          = 17,
  FACILITY_AAF              = 18,
  FACILITY_URT              = 19,
  FACILITY_ACS              = 20,
  FACILITY_DPLAY            = 21,
  FACILITY_UMI              = 22,
  FACILITY_SXS              = 23,
  FACILITY_WINDOWS_CE       = 24,
  FACILITY_HTTP             = 25,
  FACILITY_BACKGROUNDCOPY   = 32,
  FACILITY_CONFIGURATION    = 33,
  FACILITY_STATE_MANAGEMENT = 34,
  FACILITY_METADIRECTORY    = 35,
  FACILITY_WINDOWSUPDATE    = 36,
  FACILITY_DIRECTORYSERVICE = 37
}

enum {
  SEVERITY_SUCCESS = 0,
  SEVERITY_ERROR = 1
}

template MAKE_SCODE(uint sev, uint fac, uint code) {
  const MAKE_SCODE = ((sev << 31) | (fac << 16) | code);
}

enum Handle INVALID_HANDLE_VALUE = cast(Handle)-1;

ubyte HIBYTE(ushort w) {
  return cast(ubyte)((w >> 8) & 0xFF);
}

ubyte LOBYTE(ushort w) {
  return cast(ubyte)(w & 0xFF);
}

short signedHIWORD(int n) {
  return cast(short)((n >> 16) & 0xFFFF);
}

short signedLOWORD(int n) {
  return cast(short)(n & 0xFFFF);
}

int MAKELPARAM(int a, int b) {
  return (a & 0xFFFF) | (b << 16);
}

ushort MAKEWORD(ubyte a, ubyte b) {
  return (a & 0xFF) | (b << 8);
}

const(wchar)* MAKEINTRESOURCEW(int i) {
  return cast(wchar*)cast(uint)cast(ushort)i;
}

alias MAKEINTRESOURCEW MAKEINTRESOURCE;

const wchar* RT_CURSOR       = MAKEINTRESOURCE(1);
const wchar* RT_BITMAP       = MAKEINTRESOURCE(2);
const wchar* RT_ICON         = MAKEINTRESOURCE(3);
const wchar* RT_MENU         = MAKEINTRESOURCE(4);
const wchar* RT_DIALOG       = MAKEINTRESOURCE(5);
const wchar* RT_STRING       = MAKEINTRESOURCE(6);
const wchar* RT_FONTDIR      = MAKEINTRESOURCE(7);
const wchar* RT_FONT         = MAKEINTRESOURCE(8);
const wchar* RT_ACCELERATOR  = MAKEINTRESOURCE(9);
const wchar* RT_RCDATA       = MAKEINTRESOURCE(10);
const wchar* RT_MESSAGETABLE = MAKEINTRESOURCE(11);
const wchar* RT_VERSION      = MAKEINTRESOURCE(16);
const wchar* RT_DLGINCLUDE   = MAKEINTRESOURCE(17);
const wchar* RT_PLUGPLAY     = MAKEINTRESOURCE(19);
const wchar* RT_VXD          = MAKEINTRESOURCE(20);
const wchar* RT_ANICURSOR    = MAKEINTRESOURCE(21);
const wchar* RT_ANIICON      = MAKEINTRESOURCE(22);
const wchar* RT_HTML         = MAKEINTRESOURCE(23);
const wchar* RT_MANIFEST     = MAKEINTRESOURCE(24);

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

void GetSystemTimeAsFileTime(out FILETIME lpSystemTimeAsFileTime);

int FileTimeToLocalFileTime(ref FILETIME lpFileTime, out FILETIME lpLocalFileTime);

int LocalFileTimeToFileTime(ref FILETIME lpLocalFileTime, out FILETIME lpFileTime);

int SystemTimeToFileTime(ref SYSTEMTIME lpSystemTime, out FILETIME lpFileTime);

int FileTimeToSystemTime(ref FILETIME lpFileTime, out SYSTEMTIME lpSystemTime);

enum : uint {
  FORMAT_MESSAGE_ALLOCATE_BUFFER = 0x00000100,
  FORMAT_MESSAGE_ARGUMENT_ARRAY  = 0x00002000,
  FORMAT_MESSAGE_FROM_HMODULE    = 0x00000800,
  FORMAT_MESSAGE_FROM_STRING     = 0x00000400,
  FORMAT_MESSAGE_FROM_SYSTEM     = 0x00001000,
  FORMAT_MESSAGE_IGNORE_INSERTS  = 0x00000200
}

int FormatMessageW(uint dwFlags, in void* lpSource, uint dwMessageId, uint dwLanguageId, wchar* lpBuffer, uint nSize, void** Arguments);
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
void* GlobalFree(void* hMem);

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

void SetLastError(uint);

Handle LoadLibraryW(in wchar* lpLibFileName);
alias LoadLibraryW LoadLibrary;

int FreeLibrary(Handle hModule);

enum : uint {
  DONT_RESOLVE_DLL_REFERENCES = 0x00000001,
  LOAD_LIBRARY_AS_DATAFILE = 0x00000002,
  LOAD_WITH_ALTERED_SEARCH_PATH = 0x00000008,
  LOAD_IGNORE_CODE_AUTHZ_LEVEL = 0x00000010,
  LOAD_LIBRARY_AS_IMAGE_RESOURCE = 0x00000020,
  LOAD_LIBRARY_AS_DATAFILE_EXCLUSIVE = 0x00000040
}

Handle LoadLibraryExW(in wchar* lpLibFileName, Handle hFile, uint dwFlags);
alias LoadLibraryExW LoadLibraryEx;

void* GetProcAddress(Handle hModule, in char* lpProcName);

uint GetVersion();

struct OSVERSIONINFOW {
  uint dwOSVersionInfoSize = OSVERSIONINFOW.sizeof;
  uint dwMajorVersion;
  uint dwMinorVersion;
  uint dwBuildNumber;
  uint dwPlatformId;
  wchar[128] szCSDVersion;
}
alias OSVERSIONINFOW OSVERSIONINFO;

struct OSVERSIONINFOEXW {
  uint dwOSVersionInfoSize = OSVERSIONINFOEXW.sizeof;
  uint dwMajorVersion;
  uint dwMinorVersion;
  uint dwBuildNumber;
  uint dwPlatformId;
  wchar[128] szCSDVersion;
  ushort wServicePackMajor;
  ushort wServicePackMinor;
  ushort wSuiteMask;
  ubyte wProductType;
  ubyte wReserved;
}
alias OSVERSIONINFOEXW OSVERSIONINFOEX;

int GetVersionExW(ref OSVERSIONINFOW lpVersionInformation);
int GetVersionExW(ref OSVERSIONINFOEXW lpVersionInformation);
alias GetVersionExW GetVersionEx;

uint GetFileVersionInfoSizeW(in wchar* lpstrFilename, uint* lpdwHandle);
alias GetFileVersionInfoSizeW GetFileVersionInfoSize;

int GetFileVersionInfoW(in wchar* lpstrFilename, uint dwHandle, uint dwLen, void* lpData);
alias GetFileVersionInfoW GetFileVersionInfo;

int VerQueryValueW(in void* pBlock, in wchar* lpSubBlock, void** lplpBuffer, out uint puLen);
alias VerQueryValueW VerQueryValue;

struct VS_FIXEDFILEINFO {
  uint dwSignature;
  uint dwStrucVersion;
  uint dwFileVersionMS;
  uint dwFileVersionLS;
  uint dwProductVersionMS;
  uint dwProductVersionLS;
  uint dwFileFlagsMask;
  uint dwFileFlags;
  uint dwFileOS;
  uint dwFileType;
  uint dwFileSubtype;
  uint dwFileDateMS;
  uint dwFileDateLS;
}

struct SECURITY_ATTRIBUTES {
  uint nLength;
  void* lpSecurityDescriptor;
  int bInheritHandle;
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

enum : uint {
  FILE_LIST_DIRECTORY = 0x0001
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
  FILE_FLAG_WRITE_THROUGH       = 0x80000000,
  FILE_FLAG_OVERLAPPED          = 0x40000000,
  FILE_FLAG_NO_BUFFERING        = 0x20000000,
  FILE_FLAG_RANDOM_ACCESS       = 0x10000000,
  FILE_FLAG_SEQUENTIAL_SCAN     = 0x08000000,
  FILE_FLAG_DELETE_ON_CLOSE     = 0x04000000,
  FILE_FLAG_BACKUP_SEMANTICS    = 0x02000000,
  FILE_FLAG_POSIX_SEMANTICS     = 0x01000000,
  FILE_FLAG_OPEN_REPARSE_POINT  = 0x00200000,
  FILE_FLAG_OPEN_NO_RECALL      = 0x00100000,
  FILE_FLAG_FIRST_PIPE_INSTANCE = 0x00080000
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

int ReadFile(Handle hFile, in void* lpBuffer, uint nNumberOfBytesToRead, out uint lpNumberOfBytesRead, OVERLAPPED* lpOverlapped);

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

Handle FindResourceExW(Handle hModule, in wchar* lpName, in wchar* lpType, ushort wLanguage);
alias FindResourceExW FindResourceEx;

alias int function(Handle hModule, in wchar* lpType, int lParam) ENUMRESTYPEPROCW;
alias ENUMRESTYPEPROCW ENUMRESTYPEPROC;

int EnumResourceTypesW(Handle hModule, ENUMRESTYPEPROCW lpEnumFunc, int lParam);
alias EnumResourceTypesW EnumResourceTypes;

alias int function(Handle hModule, in wchar* lpType, wchar* lpName, int lParam) ENUMRESNAMEPROCW;
alias ENUMRESNAMEPROCW ENUMRESNAMEPROC;

int EnumResourceNamesW(Handle hModule, in wchar* lpType, ENUMRESNAMEPROCW lpEnumFunc, int lParam);
alias EnumResourceNamesW EnumResourceNames;

const uint TLS_OUT_OF_INDEXES = 0xFFFFFFFF;

uint TlsAlloc();

int TlsFree(uint dwTlsIndex);

void* TlsGetValue(uint dwTlsIndex);

int TlsSetValue(uint dwTlsIndex, void* lpTlsValue);

void Sleep(uint dwMilliseconds);

uint SleepEx(uint dwMilliseconds, int bAlertable);

int CancelIo(Handle hFile);

Handle GetCurrentProcess();

uint GetCurrentProcessId();

Handle GetCurrentThread();

uint GetCurrentThreadId();

Handle CreateIoCompletionPort(Handle FileHandle, Handle ExistingCompletionPort, uint CompletionKey, uint NumberOfConcurrentThreads);

int GetQueuedCompletionStatus(Handle CompletionPort, out uint lpNumberOfBytes, out uint lpCompletionKey, out OVERLAPPED* lpOverlapped, uint dwMilliseconds);

const uint INFINITE = 0xFFFFFFFF;

enum : uint {
  WAIT_OBJECT_0 = 0,
  WAIT_ABANDONED = 0x80,
  WAIT_ABANDONED_0 = 0x80,
  WAIT_TIMEOUT = 258
}

uint WaitForSingleObject(Handle hHandle, uint dwMilliseconds);

uint WaitForSingleObjectEx(Handle hHandle, uint dwMilliseconds, BOOL bAlertable);

uint WaitForMultipleObjects(uint nCount, in Handle* lpHandles, BOOL bWaitAll, uint dwMilliseconds);

uint WaitForMultipleObjectsEx(uint nCount, in Handle* lpHandles, BOOL bWaitAll, uint dwMilliseconds, BOOL bAlertable);

uint SignalObjectAndWait(Handle hObjectToSignal, Handle hObjectToWaitOn, uint dwMilliseconds, BOOL bAlertable);

enum : uint {
  QS_KEY             = 0x0001,
  QS_MOUSEMOVE       = 0x0002,
  QS_MOUSEBUTTON     = 0x0004,
  QS_POSTMESSAGE     = 0x0008,
  QS_TIMER           = 0x0010,
  QS_PAINT           = 0x0020,
  QS_SENDMESSAGE     = 0x0040,
  QS_HOTKEY          = 0x0080,
  QS_ALLPOSTMESSAGE  = 0x0100,
  QS_MOUSE           = QS_MOUSEMOVE | QS_MOUSEBUTTON,
  QS_INPUT           = QS_MOUSE | QS_KEY,
  QS_ALLEVENTS       = QS_INPUT | QS_POSTMESSAGE | QS_TIMER | QS_PAINT | QS_HOTKEY,
  QS_ALLINPUT        = QS_INPUT | QS_POSTMESSAGE | QS_TIMER | QS_PAINT | QS_HOTKEY | QS_SENDMESSAGE
}

uint MsgWaitForMultipleObjects(uint nCount, in Handle* pHandles, BOOL fWaitAll, uint dwMilliseconds, uint dwWakeMask);

enum : uint {
  MWMO_WAITALL        = 0x0001,
  MWMO_ALERTABLE      = 0x0002,
  MWMO_INPUTAVAILABLE = 0x0004
}

//uint MsgWaitForMultipleObjectsEx(uint nCount, in Handle* pHandles, BOOL fWaitAll, uint dwMilliseconds, uint dwWakeMask, uint dwFlags);

Handle CreateEventW(SECURITY_ATTRIBUTES* lpEventAttributes, int bManualReset, int bInitialState, in wchar* lpName);
alias CreateEventW CreateEvent;

int SetEvent(Handle hEvent);

int ResetEvent(Handle hEvent);

Handle CreateMutexW(SECURITY_ATTRIBUTES* lpMutexAttributes, int bInitialOwner, in wchar* lpName);
alias CreateMutexW CreateMutex;

enum : uint {
  MUTEX_MODIFY_STATE = 0x0001
}

Handle OpenMutexW(uint dwDesiredAccess, int bInheritHandle, in wchar* lpName);
alias OpenMutexW OpenMutex;

int ReleaseMutex(Handle hMutex);

Handle CreateSemaphoreW(SECURITY_ATTRIBUTES* lpSemaphoreAttributes, int lInitialCount, int lMaximumCount, in wchar* lpName);
alias CreateSemaphoreW CreateSemaphore;

int ReleaseSemaphore(Handle hSemaphore, int lReleaseCount, out int lpPreviousCount);

alias void function(void* lpParameter, int TimerOrWaitFired) WAITORTIMERCALLBACK;

int CreateTimerQueueTimer(out Handle phNewTimer, Handle TimerQueue, WAITORTIMERCALLBACK Callback, void* Parameter, uint DueTime, uint Period, uint Flags);

int DeleteTimerQueueTimer(Handle TimerQueue, Handle Timer, Handle CompletionEvent);

int ChangeTimerQueueTimer(Handle TimerQueue, Handle Timer, uint DueTime, uint Period);

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

template MAKELCID(ushort lgid, ushort srtid) {
  const MAKELCID = (srtid << 16) | lgid;
}

template MAKELANGID(ushort p, ushort s) {
  const MAKELANGID = (s << 10)  | p;
}

extern ushort SUBLANGID(ushort lgid);

enum : uint {
  LCID_INSTALLED       = 0x00000001,
  LCID_SUPPORTED       = 0x00000002,
  LCID_ALTERNATE_SORTS = 0x00000004
}

enum : ushort {
  SUBLANG_NEUTRAL     = 0x00,
  SUBLANG_DEFAULT     = 0x01,
  SUBLANG_SYS_DEFAULT = 0x02,
}

enum : ushort {
  LANG_NEUTRAL             = 0x00,
  LANG_INVARIANT           = 0x7f,
  LANG_SYSTEM_DEFAULT      = MAKELANGID!(LANG_NEUTRAL, SUBLANG_SYS_DEFAULT),
  LANG_USER_DEFAULT        = MAKELANGID!(LANG_NEUTRAL, SUBLANG_DEFAULT),

  LANG_AFRIKAANS           = 0x36,
  LANG_ALBANIAN            = 0x1c,
  LANG_ALSATIAN            = 0x84,
  LANG_AMHARIC             = 0x5e,
  LANG_ARABIC              = 0x01,
  LANG_ARMENIAN            = 0x2b,
  LANG_ASSAMESE            = 0x4d,
  LANG_AZERI               = 0x2c,
  LANG_BASHKIR             = 0x6d,
  LANG_BASQUE              = 0x2d,
  LANG_BELARUSIAN          = 0x23,
  LANG_BENGALI             = 0x45,
  LANG_BRETON              = 0x7e,
  LANG_BOSNIAN             = 0x1a,
  LANG_BOSNIAN_NEUTRAL     = 0x781a,
  LANG_BULGARIAN           = 0x02,
  LANG_CATALAN             = 0x03,
  LANG_CHINESE             = 0x04,
  LANG_CHINESE_SIMPLIFIED  = 0x04,
  LANG_CHINESE_TRADITIONAL = 0x7c04,
  LANG_CORSICAN            = 0x83,
  LANG_CROATIAN            = 0x1a,
  LANG_CZECH               = 0x05,
  LANG_DANISH              = 0x06,
  LANG_DARI                = 0x8c,
  LANG_DIVEHI              = 0x65,
  LANG_DUTCH               = 0x13,
  LANG_ENGLISH             = 0x09,
  LANG_ESTONIAN            = 0x25,
  LANG_FAEROESE            = 0x38,
  LANG_FARSI               = 0x29,
  LANG_FILIPINO            = 0x64,
  LANG_FINNISH             = 0x0b,
  LANG_FRENCH              = 0x0c,
  LANG_FRISIAN             = 0x62,
  LANG_GALICIAN            = 0x56,
  LANG_GEORGIAN            = 0x37,
  LANG_GERMAN              = 0x07,
  LANG_GREEK               = 0x08,
  LANG_GREENLANDIC         = 0x6f,
  LANG_GUJARATI            = 0x47,
  LANG_HAUSA               = 0x68,
  LANG_HEBREW              = 0x0d,
  LANG_HINDI               = 0x39,
  LANG_HUNGARIAN           = 0x0e,
  LANG_ICELANDIC           = 0x0f,
  LANG_IGBO                = 0x70,
  LANG_INDONESIAN          = 0x21,
  LANG_INUKTITUT           = 0x5d,
  LANG_IRISH               = 0x3c,
  LANG_ITALIAN             = 0x10,
  LANG_JAPANESE            = 0x11,
  LANG_KANNADA             = 0x4b,
  LANG_KASHMIRI            = 0x60,
  LANG_KAZAK               = 0x3f,
  LANG_KHMER               = 0x53,
  LANG_KICHE               = 0x86,
  LANG_KINYARWANDA         = 0x87,
  LANG_KONKANI             = 0x57,
  LANG_KOREAN              = 0x12,
  LANG_KYRGYZ              = 0x40,
  LANG_LAO                 = 0x54,
  LANG_LATVIAN             = 0x26,
  LANG_LITHUANIAN          = 0x27,
  LANG_LOWER_SORBIAN       = 0x2e,
  LANG_LUXEMBOURGISH       = 0x6e,
  LANG_MACEDONIAN          = 0x2f,
  LANG_MALAY               = 0x3e,
  LANG_MALAYALAM           = 0x4c,
  LANG_MALTESE             = 0x3a,
  LANG_MANIPURI            = 0x58,
  LANG_MAORI               = 0x81,
  LANG_MAPUDUNGUN          = 0x7a,
  LANG_MARATHI             = 0x4e,
  LANG_MOHAWK              = 0x7c,
  LANG_MONGOLIAN           = 0x50,
  LANG_NEPALI              = 0x61,
  LANG_NORWEGIAN           = 0x14,
  LANG_OCCITAN             = 0x82,
  LANG_ORIYA               = 0x48,
  LANG_PASHTO              = 0x63,
  LANG_PERSIAN             = 0x29,
  LANG_POLISH              = 0x15,
  LANG_PORTUGUESE          = 0x16,
  LANG_PUNJABI             = 0x46,
  LANG_QUECHUA             = 0x6b,
  LANG_ROMANIAN            = 0x18,
  LANG_ROMANSH             = 0x17,
  LANG_RUSSIAN             = 0x19,
  LANG_SAMI                = 0x3b,
  LANG_SANSKRIT            = 0x4f,
  LANG_SERBIAN             = 0x1a,
  LANG_SERBIAN_NEUTRAL     = 0x7c1a,
  LANG_SINDHI              = 0x59,
  LANG_SINHALESE           = 0x5b,
  LANG_SLOVAK              = 0x1b,
  LANG_SLOVENIAN           = 0x24,
  LANG_SOTHO               = 0x6c,
  LANG_SPANISH             = 0x0a,
  LANG_SWAHILI             = 0x41,
  LANG_SWEDISH             = 0x1d,
  LANG_SYRIAC              = 0x5a,
  LANG_TAJIK               = 0x28,
  LANG_TAMAZIGHT           = 0x5f,
  LANG_TAMIL               = 0x49,
  LANG_TATAR               = 0x44,
  LANG_TELUGU              = 0x4a,
  LANG_THAI                = 0x1e,
  LANG_TIBETAN             = 0x51,
  LANG_TIGRIGNA            = 0x73,
  LANG_TSWANA              = 0x32,
  LANG_TURKISH             = 0x1f,
  LANG_TURKMEN             = 0x42,
  LANG_UIGHUR              = 0x80,
  LANG_UKRAINIAN           = 0x22,
  LANG_UPPER_SORBIAN       = 0x2e,
  LANG_URDU                = 0x20,
  LANG_UZBEK               = 0x43,
  LANG_VIETNAMESE          = 0x2a,
  LANG_WELSH               = 0x52,
  LANG_WOLOF               = 0x88,
  LANG_XHOSA               = 0x34,
  LANG_YAKUT               = 0x85,
  LANG_YI                  = 0x78,
  LANG_YORUBA              = 0x6a,
  LANG_ZULU                = 0x35
}

enum : ushort {
  SORT_DEFAULT = 0x0
}

enum : uint {
  LOCALE_USER_DEFAULT   = MAKELCID!(LANG_USER_DEFAULT, SORT_DEFAULT),
  LOCALE_SYSTEM_DEFAULT = MAKELCID!(LANG_SYSTEM_DEFAULT, SORT_DEFAULT),
  LOCALE_NEUTRAL        = MAKELCID!(MAKELANGID!(LANG_NEUTRAL, SUBLANG_NEUTRAL), SORT_DEFAULT),
  LOCALE_INVARIANT      = MAKELCID!(MAKELANGID!(LANG_INVARIANT, SUBLANG_NEUTRAL), SORT_DEFAULT)
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
  CAL_NOUSEROVERRIDE     = LOCALE_NOUSEROVERRIDE,
  CAL_ICALINTVALUE       = 0x00000001,
  CAL_SCALNAME           = 0x00000002,
  CAL_IYEAROFFSETRANGE   = 0x00000003,
  CAL_SERASTRING         = 0x00000004,
  CAL_SSHORTDATE         = 0x00000005,
  CAL_SLONGDATE          = 0x00000006,
  CAL_SDAYNAME1          = 0x00000007,
  CAL_SDAYNAME2          = 0x00000008,
  CAL_SDAYNAME3          = 0x00000009,
  CAL_SDAYNAME4          = 0x0000000a,
  CAL_SDAYNAME5          = 0x0000000b,
  CAL_SDAYNAME6          = 0x0000000c,
  CAL_SDAYNAME7          = 0x0000000d,
  CAL_SABBREVDAYNAME1    = 0x0000000e,
  CAL_SABBREVDAYNAME2    = 0x0000000f,
  CAL_SABBREVDAYNAME3    = 0x00000010,
  CAL_SABBREVDAYNAME4    = 0x00000011,
  CAL_SABBREVDAYNAME5    = 0x00000012,
  CAL_SABBREVDAYNAME6    = 0x00000013,
  CAL_SABBREVDAYNAME7    = 0x00000014,
  CAL_SMONTHNAME1        = 0x00000015,
  CAL_SMONTHNAME2        = 0x00000016,
  CAL_SMONTHNAME3        = 0x00000017,
  CAL_SMONTHNAME4        = 0x00000018,
  CAL_SMONTHNAME5        = 0x00000019,
  CAL_SMONTHNAME6        = 0x0000001a,
  CAL_SMONTHNAME7        = 0x0000001b,
  CAL_SMONTHNAME8        = 0x0000001c,
  CAL_SMONTHNAME9        = 0x0000001d,
  CAL_SMONTHNAME10       = 0x0000001e,
  CAL_SMONTHNAME11       = 0x0000001f,
  CAL_SMONTHNAME12       = 0x00000020,
  CAL_SMONTHNAME13       = 0x00000021,
  CAL_SABBREVMONTHNAME1  = 0x00000022,
  CAL_SABBREVMONTHNAME2  = 0x00000023,
  CAL_SABBREVMONTHNAME3  = 0x00000024,
  CAL_SABBREVMONTHNAME4  = 0x00000025,
  CAL_SABBREVMONTHNAME5  = 0x00000026,
  CAL_SABBREVMONTHNAME6  = 0x00000027,
  CAL_SABBREVMONTHNAME7  = 0x00000028,
  CAL_SABBREVMONTHNAME8  = 0x00000029,
  CAL_SABBREVMONTHNAME9  = 0x0000002a,
  CAL_SABBREVMONTHNAME10 = 0x0000002b,
  CAL_SABBREVMONTHNAME11 = 0x0000002c,
  CAL_SABBREVMONTHNAME12 = 0x0000002d,
  CAL_SABBREVMONTHNAME13 = 0x0000002e,
  CAL_SYEARMONTH         = 0x0000002f,
  CAL_ITWODIGITYEARMAX   = 0x00000030,
  CAL_SSHORTESTDAYNAME1  = 0x00000031,
  CAL_SSHORTESTDAYNAME2  = 0x00000032,
  CAL_SSHORTESTDAYNAME3  = 0x00000033,
  CAL_SSHORTESTDAYNAME4  = 0x00000034,
  CAL_SSHORTESTDAYNAME5  = 0x00000035,
  CAL_SSHORTESTDAYNAME6  = 0x00000036,
  CAL_SSHORTESTDAYNAME7  = 0x00000037,
  ENUM_ALL_CALENDARS     = 0xffffffff
}

enum : uint {
  CAL_GREGORIAN              = 1,
  CAL_GREGORIAN_US           = 2,
  CAL_JAPAN                  = 3,
  CAL_TAIWAN                 = 4,
  CAL_KOREA                  = 5,
  CAL_HIJRI                  = 6,
  CAL_THAI                   = 7,
  CAL_HEBREW                 = 8,
  CAL_GREGORIAN_ME_FRENCH    = 9,
  CAL_GREGORIAN_ARABIC       = 10,
  CAL_GREGORIAN_XLIT_ENGLISH = 11,
  CAL_GREGORIAN_XLIT_FRENCH  = 12,
  CAL_UMALQURA               = 23 // Vista+
}

int GetCalendarInfoW(uint Locale, uint Calendar, uint CalType, wchar* lpCalData, int cchData, uint* lpValue);
alias GetCalendarInfoW GetCalendarInfo;

int SetCalendarInfoW(uint Locale, uint Calendar, uint CalType, wchar* lpCalData);
alias SetCalendarInfoW SetCalendarInfo;

enum : uint {
  DATE_SHORTDATE        = 0x00000001,
  DATE_LONGDATE         = 0x00000002,
  DATE_USE_ALT_CALENDAR = 0x00000004
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

enum : uint {
  TIME_ZONE_ID_INVALID = cast(uint)0xffffffff
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

uint GetTimeZoneInformation(out TIME_ZONE_INFORMATION lpTimeZoneInformation);

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

int LCMapStringW(uint Locale, uint dwMapFlags, in wchar* lpSrcStr, int cchSrc, wchar* lpDestStr, int cchDest);
alias LCMapStringW LCMapString;

int MultiByteToWideChar(uint CodePage, uint dwFlags, in char* lpMultiByteStr, int cbMultiByte, wchar* lpWideCharStr, int cchWideChar);

enum : uint {
  WC_DISCARDNS = 0x00000010,
  WC_SEPCHARS = 0x00000020,
  WC_DEFAULTCHAR = 0x00000040,
  WC_COMPOSITECHECK = 0x00000200
}

int WideCharToMultiByte(uint CodePage, uint dwFlags, in wchar* lpWideCharStr, int cchWideChar, char* lpMultiByteStr, int cbMultiByte, char* lpDefaultChar, int* lpUseDefaultChar);

int InterlockedIncrement(ref int Addend);

int InterlockedDecrement(ref int Addend);

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

enum : uint {
  FILE_ATTRIBUTE_READONLY            = 0x00000001,
  FILE_ATTRIBUTE_HIDDEN              = 0x00000002,
  FILE_ATTRIBUTE_SYSTEM              = 0x00000004,
  FILE_ATTRIBUTE_DIRECTORY           = 0x00000010,
  FILE_ATTRIBUTE_ARCHIVE             = 0x00000020,
  FILE_ATTRIBUTE_DEVICE              = 0x00000040,
  FILE_ATTRIBUTE_NORMAL              = 0x00000080,
  FILE_ATTRIBUTE_TEMPORARY           = 0x00000100,
  FILE_ATTRIBUTE_SPARSE_FILE         = 0x00000200,
  FILE_ATTRIBUTE_REPARSE_POINT       = 0x00000400,
  FILE_ATTRIBUTE_COMPRESSED          = 0x00000800,
  FILE_ATTRIBUTE_OFFLINE             = 0x00001000,
  FILE_ATTRIBUTE_NOT_CONTENT_INDEXED = 0x00002000,
  FILE_ATTRIBUTE_ENCRYPTED           = 0x00004000,
  FILE_ATTRIBUTE_VIRTUAL             = 0x00010000
}

int FindClose(Handle hFindFile);

struct WIN32_FIND_DATAW {
  uint dwFileAttributes;
  FILETIME ftCreationTime;
  FILETIME ftLastAccessTime;
  FILETIME ftLastWriteTime;
  uint nFileSizeHigh;
  uint nFileSizeLow;
  uint dwReserved0;
  uint dwReserved1;
  wchar[MAX_PATH] cFileName;
  wchar[14] cAlternateFileName;
}
alias WIN32_FIND_DATAW WIN32_FIND_DATA;

Handle FindFirstFileW(in wchar* lpFileName, out WIN32_FIND_DATA lpFileFileData);
alias FindFirstFileW FindFirstFile;

int FindNextFileW(Handle hFindFile, out WIN32_FIND_DATA lpFindFileData);
alias FindNextFileW FindNextFile;

struct WIN32_FILE_ATTRIBUTE_DATA {
  uint dwFileAttributes;
  FILETIME ftCreationTime;
  FILETIME ftLastAccessTime;
  FILETIME ftLastWriteTime;
  uint nFileSizeHigh;
  uint nFileSizeLow;
}

enum : uint {
  STD_INPUT_HANDLE = -10,
  STD_OUTPUT_HANDLE = -11,
  STD_ERROR_HANDLE = -12
}

Handle GetStdHandle(uint nStdHandle);

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

int SetConsoleWindowInfo(Handle hConsoleOutput, int bAbsolute, ref SMALL_RECT lpConsoleWindow);

int SetConsoleScreenBufferSize(Handle hConsoleOutput, COORD dwSize);

int SetConsoleTextAttribute(Handle hConsoleOutput, ushort wAttributes);

int FillConsoleOutputCharacterW(Handle hConsoleOutput, wchar cCharacter, uint nLength, COORD dwWriteCoord, out uint lpNumberOfCharsWritten);
alias FillConsoleOutputCharacterW FillConsoleOutputCharacter;

int FillConsoleOutputAttribute(Handle hConsoleOutput, ushort wAttribute, int nLength, COORD dwWriteCoord, out uint lpNumberOfAttrsWritten);

int SetConsoleCursorPosition(Handle hConsoleOutput, COORD dwCursorPosition);

uint GetConsoleTitleW(wchar* lpConsoleTitle, uint nSize);
alias GetConsoleTitleW GetConsoleTitle;

int SetConsoleTitleW(in wchar* lpConsoleTitle);
alias SetConsoleTitleW SetConsoleTitle;

uint GetConsoleOutputCP();

int SetConsoleOutputCP(uint wCodePageID);

// wFunc
enum : uint {
  FO_MOVE                   = 0x0001,
  FO_COPY                   = 0x0002,
  FO_DELETE                 = 0x0003,
  FO_RENAME                 = 0x0004
}

// fFlag
enum : uint {
  FOF_MULTIDESTFILES        = 0x0001,
  FOF_CONFIRMMOUSE          = 0x0002,
  FOF_SILENT                = 0x0004,
  FOF_RENAMEONCOLLISION     = 0x0008,
  FOF_NOCONFIRMATION        = 0x0010,
  FOF_WANTMAPPINGHANDLE     = 0x0020,
  FOF_ALLOWUNDO             = 0x0040,
  FOF_FILESONLY             = 0x0080,
  FOF_SIMPLEPROGRESS        = 0x0100,
  FOF_NOCONFIRMMKDIR        = 0x0200,
  FOF_NOERRORUI             = 0x0400,
  FOF_NOCOPYSECURITYATTRIBS = 0x0800,
  FOF_NORECURSION           = 0x1000,
  FOF_NO_CONNECTED_ELEMENTS = 0x2000,
  FOF_WANTNUKEWARNING       = 0x4000,
  FOF_NORECURSEREPARSE      = 0x8000
}

struct SHFILEOPSTRUCTW {
  Handle hwnd;
  uint wFunc;
  const(wchar)* pFrom;
  const(wchar)* pTo;
  uint fFlags;
  BOOL fAnyOperationsAborted;
  void* hNameMappings;
  wchar* lpszProgressTitle;
}
alias SHFILEOPSTRUCTW SHFILEOPSTRUCT;

int SHFileOperationW(ref SHFILEOPSTRUCTW lpFileOp);
alias SHFileOperationW SHFileOperation;

int SetFileAttributesW(in wchar* lpFileName, uint dwFileAttributes);
alias SetFileAttributesW SetFileAttributes;

int GetFileAttributesExW(in wchar* lpFileName, int fInfoLevelId, ref WIN32_FILE_ATTRIBUTE_DATA lpFileInformation);
alias GetFileAttributesExW GetFileAttributesEx;

enum : uint {
  REPLACEFILE_WRITE_THROUGH       = 0x00000001,
  REPLACEFILE_IGNORE_MERGE_ERRORS = 0x00000002,
  REPLACEFILE_IGNORE_ACL_ERRORS   = 0x00000004
}

int ReplaceFileW(in wchar* lpReplacedFileName, in wchar* lpReplacementFileName, in wchar* lpBackupFileName, uint dwReplaceFlags, void* lpExclude, void* lpReserved);
alias ReplaceFileW ReplaceFile;

uint GetCurrentDirectoryW(uint nBufferLength, wchar* lpBuffer);
alias GetCurrentDirectoryW GetCurrentDirectory;

uint GetSystemDirectoryW(wchar* lpBuffer, uint nSize);
alias GetSystemDirectoryW GetSystemDirectory;

int CreateDirectoryW(in wchar* lpPathName, SECURITY_ATTRIBUTES* lpSecurityAttributes);
alias CreateDirectoryW CreateDirectory;

int GetDiskFreeSpaceExW(in wchar* lpDirectoryName, ref ulong lpFreeBytesAvailable, ref ulong lpTotalNumberOfBytes, ref ulong lpTotalNumberOfFreeBytes);
alias GetDiskFreeSpaceExW GetDiskFreeSpaceEx;

int GetVolumeInformationW(in wchar* lpRootPathName, wchar* lpVolumeNameBuffer, uint nVolumeNameSize, out uint lpVolumeSerialNumber, out uint lpMaximumComponentLength, out uint lpFileSystemFlags, wchar* lpFileSystemNameBuffer, uint nFileSystemNameSize);
alias GetVolumeInformationW GetVolumeInformation;

int SetVolumeLabelW(in wchar* lpRootPathName, in wchar* lpVolumeName);
alias SetVolumeLabelW SetVolumeLabel;

uint GetLogicalDrives();

alias void function(uint dwErrorCode, uint dwNumberOfBytesTransferred, OVERLAPPED* lpOverlapped) LPOVERLAPPED_COMPLETION_ROUTINE;

enum : uint {
  FILE_NOTIFY_CHANGE_FILE_NAME   = 0x00000001,
  FILE_NOTIFY_CHANGE_DIR_NAME    = 0x00000002,
  FILE_NOTIFY_CHANGE_ATTRIBUTES  = 0x00000004,
  FILE_NOTIFY_CHANGE_SIZE        = 0x00000008,
  FILE_NOTIFY_CHANGE_LAST_WRITE  = 0x00000010,
  FILE_NOTIFY_CHANGE_LAST_ACCESS = 0x00000020,
  FILE_NOTIFY_CHANGE_CREATION    = 0x00000040,
  FILE_NOTIFY_CHANGE_SECURITY    = 0x00000100
}

enum : uint {
  FILE_ACTION_ADDED            = 0x00000001,
  FILE_ACTION_REMOVED          = 0x00000002,
  FILE_ACTION_MODIFIED         = 0x00000003,
  FILE_ACTION_RENAMED_OLD_NAME = 0x00000004,
  FILE_ACTION_RENAMED_NEW_NAME = 0x00000005
}

struct FILE_NOTIFY_INFORMATION {
  uint NextEntryOffset;
  uint Action;
  uint FileNameLength;
  wchar[1] FileName;
}

int ReadDirectoryChangesW(Handle hDirectory, void* lpBuffer, uint nBufferLength, int bWatchSubtree, uint dwNotifyFiler, uint* lpdwBytesReturned, OVERLAPPED* lpOverlapped, LPOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine);

int GetOverlappedResult(Handle hFile, OVERLAPPED* lpOverlapped, ref uint lpNumberOfBytesTransferred, int bWait);

int DeleteFileW(in wchar* lpFileName);
alias DeleteFileW DeleteFile;

int RemoveDirectoryW(in wchar* lpPathName);
alias RemoveDirectoryW RemoveDirectory;

int MoveFileW(in wchar* lpExistingFileName, in wchar* lpNewFileName);
alias MoveFileW MoveFile;

int CopyFileW(in wchar* lpExistingFileName, in wchar* lpNewFileName, int bFailIfExists);
alias CopyFileW CopyFile;

int EncryptFileW(in wchar* lpFileName);
alias EncryptFileW EncryptFile;

int DecryptFileW(in wchar* lpFileName, uint dwReserved);
alias DecryptFileW DecryptFile;

uint GetTempPathW(uint nBufferLength, wchar* lpBuffer);
alias GetTempPathW GetTempPath;

uint GetTempFileNameW(in wchar* lpPathName, in wchar* lpPrefixString, uint uUnique, wchar* lpTempFileName);
alias GetTempFileNameW GetTempFileName;

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

enum : Handle {
  HKEY_CLASSES_ROOT     = cast(Handle)0x80000000,
  HKEY_CURRENT_USER     = cast(Handle)0x80000001,
  HKEY_LOCAL_MACHINE    = cast(Handle)0x80000002,
  HKEY_USERS            = cast(Handle)0x80000003,
  HKEY_PERFORMANCE_DATA = cast(Handle)0x80000004,
  HKEY_CURRENT_CONFIG   = cast(Handle)0x80000005,
  HKEY_DYN_DATA         = cast(Handle)0x80000006
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

enum : uint {
  REG_OPTION_NON_VOLATILE   = 0x00000000,
  REG_OPTION_VOLATILE       = 0x00000001,
  REG_OPTION_CREATE_LINK    = 0x00000002,
  REG_OPTION_BACKUP_RESTORE = 0x00000004,
  REG_OPTION_OPEN_LINK      = 0x00000008
}

int RegOpenKeyExW(Handle hKey, in wchar* lpSubKey, uint ulOptions, uint samDesired, out Handle phkResult);
alias RegOpenKeyExW RegOpenKeyEx;

int RegCreateKeyExW(Handle hKey, in wchar* lpSubKey, uint Reserved, wchar* lpClass, uint dwOptions, uint samDesired, SECURITY_ATTRIBUTES* lpSecurityAttributes, out Handle phkResult, out uint lpdwDisposition);
alias RegCreateKeyExW RegCreateKeyEx;

int RegQueryValueExW(Handle hKey, in wchar* lpValueName, uint* lpReserved, uint* lpdwType, ubyte* lpData, uint* lpcbData);
alias RegQueryValueExW RegQueryValueEx;

int RegQueryInfoKeyW(Handle hKey, wchar* lpClass, uint* lpcchClass, uint* lpReserved, uint* lpcSubKeys, uint* lpcbMaxSubKeyLen, uint* lpcbMaxClassLen, uint* lpcValues, uint* lpcbMaxValueNameLen, uint* lpcbMaxValueLen, uint* lpcbSecurityDescriptor, FILETIME* lpftLastWriteTime);
alias RegQueryInfoKeyW RegQueryInfoKey;

int RegEnumValueW(Handle hKey, uint dwIndex, wchar* lpValueName, ref uint lpcchValueName, uint* lpReserved, uint* lpType, ubyte* lpData, uint* lpcbData);
alias RegEnumValueW RegEnumValue;

int RegEnumKeyExW(Handle hKey, uint dwIndex, wchar* lpName, ref uint lpcchName, uint* lpReserved, wchar* lpClass, uint* lpcchClass, FILETIME* lpftLastWriteTime);
alias RegEnumKeyExW RegEnumKeyEx;

int RegSetValueExW(Handle hKey, in wchar* lpValueName, uint Reserved, uint dwType, in ubyte* lpData, uint cbData);
alias RegSetValueExW RegSetValueEx;

int RegDeleteKeyW(Handle hKey, in wchar* lpSubKey);
alias RegDeleteKeyW RegDeleteKey;

int RegDeleteValueW(Handle hKey, in wchar* lpValueName);
alias RegDeleteValueW RegDeleteValue;

int RegFlushKey(Handle hKey);

int RegCloseKey(Handle hKey);

uint ExpandEnvironmentStringsW(in wchar* lpSrc, wchar* lpDst, uint nSize);
alias ExpandEnvironmentStringsW ExpandEnvironmentStrings;

int Beep(uint dwFreq, uint dwDuration);

uint GetTickCount();

int MulDiv(int nNumber, int nNumerator, int nDenominator);

enum : uint {
  PROCESS_TERMINATE   = 0x0001,
  PROCESS_ALL_ACCESS  = STANDARD_RIGHTS_REQUIRED | SYNCHRONIZE | 0xFFF
}

Handle OpenProcess(uint dwDesiredAccess, BOOL bInheritHandle, uint dwProcessId);

BOOL TerminateProcess(Handle hProcess, uint nExitCode);

enum : uint {
  DUPLICATE_CLOSE_SOURCE = 0x01,
  DUPLICATE_SAME_ACCESS  = 0x02
}

BOOL DuplicateHandle(Handle hSourceProcessHandle, Handle hSourceHandle, Handle hTargetProcessHandle, out Handle lpTargetHandle, uint dwDesiredAccess, BOOL bInheritHandle, uint dwOptions);

struct STARTUPINFOW {
  uint cb = STARTUPINFOW.sizeof;
  wchar* lpReserved;
  wchar* lpDesktop;
  wchar* lpTitle;
  uint dwX;
  uint dwY;
  uint dwXSize;
  uint dwYSize;
  uint dwXCountChars;
  uint dwYCountChars;
  uint dwFillAttribute;
  uint dwFlags;
  ushort wShowWindow;
  ushort cbReserved2;
  ubyte* lpReserved2;
  Handle hStdInput;
  Handle hStdOutput;
  Handle hStdError;
}
alias STARTUPINFOW STARTUPINFO;

struct PROCESS_INFORMATION {
  Handle hProcess;
  Handle hThread;
  uint dwProcessId;
  uint dwThreadId;
}

BOOL CreateProcessW(in wchar* lpApplicationName, in wchar* lpCommandLine, SECURITY_ATTRIBUTES* lpProcessAttributes, SECURITY_ATTRIBUTES* lpThreadAttributes, BOOL bInheritHandle, uint dwCreationFlags, void* lpEnvironment, in wchar* lpCurrentDirectory, ref STARTUPINFOW lpStartupInfo, ref PROCESS_INFORMATION lpProcessInformation);
alias CreateProcessW CreateProcess;

enum : uint {
  SC_MANAGER_CONNECT            = 0x0001,
  SC_MANAGER_CREATE_SERVICE     = 0x0002,
  SC_MANAGER_ENUMERATE_SERVICE  = 0x0004,
  SC_MANAGER_LOCK               = 0x0008,
  SC_MANAGER_QUERY_LOCK_STATUS  = 0x0010,
  SC_MANAGER_MODIFY_BOOT_CONFIG = 0x0020
}

Handle OpenSCManagerW(in wchar* lpMachineName, in wchar* lpDatabaseName, uint dwDesiredAccess);
alias OpenSCManagerW OpenSCManager;

enum : uint {
  SERVICE_QUERY_CONFIG          = 0x0001,
  SERVICE_CHANGE_CONFIG         = 0x0002,
  SERVICE_QUERY_STATUS          = 0x0004,
  SERVICE_ENUMERATE_DEPENDENTS  = 0x0008,
  SERVICE_START                 = 0x0010,
  SERVICE_STOP                  = 0x0020,
  SERVICE_PAUSE_CONTINUE        = 0x0040,
  SERVICE_INTERROGATE           = 0x0080,
  SERVICE_USER_DEFINED_CONTROL  = 0x0100
}

Handle OpenServiceW(Handle hSCManager, in wchar* lpServiceName, uint dwDesiredAccess);
alias OpenServiceW OpenService;

BOOL CloseServiceHandle(Handle hSCObject);

BOOL StartServiceW(Handle hService, uint dwNumServiceArgs, in wchar** lpServiceArgVectors);
alias StartServiceW StartService;

enum : uint {
  SERVICE_STOPPED          = 0x00000001,
  SERVICE_START_PENDING    = 0x00000002,
  SERVICE_STOP_PENDING     = 0x00000003,
  SERVICE_RUNNING          = 0x00000004,
  SERVICE_CONTINUE_PENDING = 0x00000005,
  SERVICE_PAUSE_PENDING    = 0x00000006,
  SERVICE_PAUSED           = 0x00000007
}

struct SERVICE_STATUS {
  uint dwServiceType;
  uint dwCurrentState;
  uint dwControlsAccepted;
  uint dwWin32ExitCode;
  uint dwServiceSpecificExitCode;
  uint dwCheckPoint;
  uint dwWaitHint;
}

enum : uint {
  SERVICE_CONTROL_STOP                  = 0x00000001,
  SERVICE_CONTROL_PAUSE                 = 0x00000002,
  SERVICE_CONTROL_CONTINUE              = 0x00000003,
  SERVICE_CONTROL_INTERROGATE           = 0x00000004,
  SERVICE_CONTROL_SHUTDOWN              = 0x00000005,
  SERVICE_CONTROL_PARAMCHANGE           = 0x00000006,
  SERVICE_CONTROL_NETBINDADD            = 0x00000007,
  SERVICE_CONTROL_NETBINDREMOVE         = 0x00000008,
  SERVICE_CONTROL_NETBINDENABLE         = 0x00000009,
  SERVICE_CONTROL_NETBINDDISABLE        = 0x0000000A,
  SERVICE_CONTROL_DEVICEEVENT           = 0x0000000B,
  SERVICE_CONTROL_HARDWAREPROFILECHANGE = 0x0000000C,
  SERVICE_CONTROL_POWEREVENT            = 0x0000000D,
  SERVICE_CONTROL_SESSIONCHANGE         = 0x0000000E,
  SERVICE_CONTROL_PRESHUTDOWN           = 0x0000000F
}

BOOL ControlService(Handle hService, uint dwControl, ref SERVICE_STATUS lpServiceStatus);

BOOL QueryServiceStatus(Handle hService, out SERVICE_STATUS lpServiceStatus);

enum : uint {
  LOGON_WITH_PROFILE         = 0x00000001,
  LOGON_NETCREDENTIALS_ONLY  = 0x00000002,
  LOGON_ZERO_PASSWORD_BUFFER = 0x80000000
}

enum {
  CSIDL_DESKTOP                 = 0x0000,
  CSIDL_INTERNET                = 0x0001,
  CSIDL_PROGRAMS                = 0x0002,
  CSIDL_CONTROLS                = 0x0003,
  CSIDL_PRINTERS                = 0x0004,
  CSIDL_PERSONAL                = 0x0005,
  CSIDL_FAVORITES               = 0x0006,
  CSIDL_STARTUP                 = 0x0007,
  CSIDL_RECENT                  = 0x0008,
  CSIDL_SENDTO                  = 0x0009,
  CSIDL_BITBUCKET               = 0x000a,
  CSIDL_STARTMENU               = 0x000b,
  CSIDL_MYDOCUMENTS             = CSIDL_PERSONAL,
  CSIDL_MYMUSIC                 = 0x000d,
  CSIDL_MYVIDEO                 = 0x000e,
  CSIDL_DESKTOPDIRECTORY        = 0x0010,
  CSIDL_DRIVES                  = 0x0011,
  CSIDL_NETWORK                 = 0x0012,
  CSIDL_NETHOOD                 = 0x0013,
  CSIDL_FONTS                   = 0x0014,
  CSIDL_TEMPLATES               = 0x0015,
  CSIDL_COMMON_STARTMENU        = 0x0016,
  CSIDL_COMMON_PROGRAMS         = 0X0017,
  CSIDL_COMMON_STARTUP          = 0x0018,
  CSIDL_COMMON_DESKTOPDIRECTORY = 0x0019,
  CSIDL_APPDATA                 = 0x001a,
  CSIDL_PRINTHOOD               = 0x001b,
  CSIDL_LOCAL_APPDATA           = 0x001c,
  CSIDL_ALTSTARTUP              = 0x001d,
  CSIDL_COMMON_ALTSTARTUP       = 0x001e,
  CSIDL_COMMON_FAVORITES        = 0x001f,
  CSIDL_INTERNET_CACHE          = 0x0020,
  CSIDL_COOKIES                 = 0x0021,
  CSIDL_HISTORY                 = 0x0022,
  CSIDL_COMMON_APPDATA          = 0x0023,
  CSIDL_WINDOWS                 = 0x0024,
  CSIDL_SYSTEM                  = 0x0025,
  CSIDL_PROGRAM_FILES           = 0x0026,
  CSIDL_MYPICTURES              = 0x0027,
  CSIDL_PROFILE                 = 0x0028,
  CSIDL_SYSTEMX86               = 0x0029,
  CSIDL_PROGRAM_FILESX86        = 0x002a,
  CSIDL_PROGRAM_FILES_COMMON    = 0x002b,
  CSIDL_PROGRAM_FILES_COMMONX86 = 0x002c,
  CSIDL_COMMON_TEMPLATES        = 0x002d,
  CSIDL_COMMON_DOCUMENTS        = 0x002e,
  CSIDL_COMMON_ADMINTOOLS       = 0x002f,
  CSIDL_ADMINTOOLS              = 0x0030,
  CSIDL_CONNECTIONS             = 0x0031,
  CSIDL_COMMON_MUSIC            = 0x0035,
  CSIDL_COMMON_PICTURES         = 0x0036,
  CSIDL_COMMON_VIDEO            = 0x0037,
  CSIDL_RESOURCES               = 0x0038,
  CSIDL_RESOURCES_LOCALIZED     = 0x0039,
  CSIDL_COMMON_OEM_LINKS        = 0x003a,
  CSIDL_CDBURN_AREA             = 0x003b,
  CSIDL_COMPUTERSNEARME         = 0x003d,
  CSIDL_FLAG_CREATE             = 0x8000,
  CSIDL_FLAG_DONT_VERIFY        = 0x4000,
  CSIDL_FLAG_DONT_UNEXPAND      = 0x2000,
  CSIDL_FLAG_NO_ALIAS           = 0x1000,
  CSIDL_FLAG_PER_USER_INIT      = 0x0800,
  CSIDL_FLAG_MASK               = 0xFF00
}

enum : uint {
  SHGFP_TYPE_CURRENT = 0,
  SHGFP_TYPE_DEFAULT = 1
}

int SHGetFolderPathW(Handle hwnd, int csidl, Handle hToken, uint dwFlags, wchar* pszPath);
alias SHGetFolderPathW SHGetFolderPath;

enum {
  SHCNE_RENAMEITEM       = 0x00000001,
  SHCNE_CREATE           = 0x00000002,
  SHCNE_DELETE           = 0x00000004,
  SHCNE_MKDIR            = 0x00000008,
  SHCNE_RMDIR            = 0x00000010,
  SHCNE_MEDIAINSERTED    = 0x00000020,
  SHCNE_MEDIAREMOVED     = 0x00000040,
  SHCNE_DRIVEREMOVED     = 0x00000080,
  SHCNE_DRIVEADD         = 0x00000100,
  SHCNE_NETSHARE         = 0x00000200,
  SHCNE_NETUNSHARE       = 0x00000400,
  SHCNE_ATTRIBUTES       = 0x00000800,
  SHCNE_UPDATEDIR        = 0x00001000,
  SHCNE_UPDATEITEM       = 0x00002000,
  SHCNE_SERVERDISCONNECT = 0x00004000,
  SHCNE_UPDATEIMAGE      = 0x00008000,
  SHCNE_DRIVEADDGUI      = 0x00010000,
  SHCNE_RENAMEFOLDER     = 0x00020000,
  SHCNE_FREESPACE        = 0x00040000,
  SHCNE_EXTENDED_EVENT   = 0x04000000,
  SHCNE_ASSOCCHANGED     = 0x08000000,
  SHCNE_DISKEVENTS       = 0x0002381F,
  SHCNE_GLOBALEVENTS     = 0x0C0581E0,
  SHCNE_ALLEVENTS        = 0x7FFFFFFF,
  SHCNE_INTERRUPT        = 0x80000000,
}

enum : uint {
  SHCNF_IDLIST          = 0x0000,
  SHCNF_PATHA           = 0x0001,
  SHCNF_PRINTERA        = 0x0002,
  SHCNF_DWORD           = 0x0003,
  SHCNF_PATHW           = 0x0005,
  SHCNF_PRINTERW        = 0x0006,
  SHCNF_TYPE            = 0x00FF,
  SHCNF_FLUSH           = 0x1000,
  SHCNF_FLUSHNOWAIT     = 0x2000,
  SHCNF_NOTIFYRECURSIVE = 0x10000
}

void SHChangeNotify(int wEventId, uint uFlags, in void* dwItem1, in void* dwItem2);

enum : uint {
  SEE_MASK_CLASSNAME         = 0x00000001,
  SEE_MASK_CLASSKEY          = 0x00000003,
  SEE_MASK_IDLIST            = 0x00000004,
  SEE_MASK_INVOKEIDLIST      = 0x0000000c,
  SEE_MASK_ICON              = 0x00000010,
  SEE_MASK_HOTKEY            = 0x00000020,
  SEE_MASK_NOCLOSEPROCESS    = 0x00000040,
  SEE_MASK_CONNECTNETDRV     = 0x00000080,
  SEE_MASK_NOASYNC           = 0x00000100,
  SEE_MASK_FLAG_DDEWAIT      = SEE_MASK_NOASYNC,
  SEE_MASK_DOENVSUBST        = 0x00000200,
  SEE_MASK_FLAG_NO_UI        = 0x00000400,
  SEE_MASK_UNICODE           = 0x00004000,
  SEE_MASK_NO_CONSOLE        = 0x00008000,
  SEE_MASK_ASYNCOK           = 0x00100000,
  SEE_MASK_HMONITOR          = 0x00200000,
  SEE_MASK_NOZONECHECKS      = 0x00800000,
  SEE_MASK_NOQUERYCLASSSTORE = 0x01000000,
  SEE_MASK_WAITFORINPUTIDLE  = 0x02000000,
  SEE_MASK_FLAG_LOG_USAGE    = 0x04000000
}

struct SHELLEXECUTEINFOW {
  uint cbSize = SHELLEXECUTEINFOW.sizeof;
  uint fMask;
  Handle hwnd;
  const(wchar)* lpVerb;
  const(wchar)* lpFile;
  const(wchar)* lpParameters;
  const(wchar)* lpDirectory;
  int nShow;
  Handle hInstApp;
  void* lpIDList;
  const(wchar)* lpClass;
  Handle hkeyClass;
  uint dwHotKey;
  union {
    Handle hIcon;
    Handle hMonitor;
  }
  Handle hProcess;
}
alias SHELLEXECUTEINFOW SHELLEXECUTEINFO;

BOOL ShellExecuteExW(ref SHELLEXECUTEINFOW lpExecInfo);
alias ShellExecuteExW ShellExecuteEx;

enum {
  STATUS_BUFFER_TOO_SMALL = 0xC0000023
}

uint LsaNtStatusToWinError(int status);

// Security

struct LUID {
  uint LowPart;
  int HighPart;
}

const LUID SYSTEM_LUID          = { 0x3e7, 0x0 };
const LUID ANONYMOUS_LOGON_LUID = { 0x3e6, 0x0 };
const LUID LOCALSERVICE_LUID    = { 0x3e5, 0x0 };
const LUID NETWORKSERVICE_LUID  = { 0x3e4, 0x0 };
const LUID IUSER_LUID           = { 0x3e4, 0x0 };

int AllocateLocallyUniqueId(out LUID Luid);

struct QUOTA_LIMITS {
  uint PagedPoolLimit;
  uint NonPagedPoolLimit;
  uint MinimumWorkingSetSize;
  uint MaximumWorkingSetSize;
  uint PagefileLimit;
  long TimeLimit;
}

enum : uint {
  SECURITY_NULL_SID_AUTHORITY         = 0,
  SECURITY_WORLD_SID_AUTHORITY        = 1,
  SECURITY_LOCAL_SID_AUTHORITY        = 2,
  SECURITY_CREATOR_SID_AUTHORITY      = 3,
  SECURITY_NON_UNIQUE_AUTHORITY       = 4,
  SECURITY_NT_AUTHORITY               = 5,
  SECURITY_RESOURCE_MANAGER_AUTHORITY = 9
}

enum {
  SECURITY_DIALUP_RID                           = 0x00000001,
  SECURITY_NETWORK_RID                          = 0x00000002,
  SECURITY_BATCH_RID                            = 0x00000003,
  SECURITY_INTERACTIVE_RID                      = 0x00000004,
  SECURITY_LOGON_IDS_RID                        = 0x00000005,
  SECURITY_LOGON_IDS_RID_COUNT                  = 3,
  SECURITY_SERVICE_RID                          = 0x00000006,
  SECURITY_ANONYMOUS_LOGON_RID                  = 0x00000007,
  SECURITY_PROXY_RID                            = 0x00000008,
  SECURITY_ENTERPRISE_CONTROLLERS_RID           = 0x00000009,
  SECURITY_SERVER_LOGON_RID                     = SECURITY_ENTERPRISE_CONTROLLERS_RID,
  SECURITY_PRINCIPAL_SELF_RID                   = 0x0000000A,
  SECURITY_AUTHENTICATED_USER_RID               = 0x0000000B,
  SECURITY_RESTRICTED_CODE_RID                  = 0x0000000C,
  SECURITY_TERMINAL_SERVER_RID                  = 0x0000000D,
  SECURITY_REMOTE_LOGON_RID                     = 0x0000000E,
  SECURITY_THIS_ORGANIZATION_RID                = 0x0000000F,
  SECURITY_IUSER_RID                            = 0x00000011,
  SECURITY_LOCAL_SYSTEM_RID                     = 0x00000012,
  SECURITY_LOCAL_SERVICE_RID                    = 0x00000013,
  SECURITY_NETWORK_SERVICE_RID                  = 0x00000014,
  SECURITY_NT_NON_UNIQUE                        = 0x00000015,
  SECURITY_NT_NON_UNIQUE_SUB_AUTH_COUNT         = 3,
  SECURITY_ENTERPRISE_READONLY_CONTROLLERS_RID  = 0x00000016,
  SECURITY_BUILTIN_DOMAIN_RID                   = 0x00000020,
  SECURITY_WRITE_RESTRICTED_CODE_RID            = 0x00000021,
  SECURITY_PACKAGE_BASE_RID                     = 0x00000040,
  SECURITY_PACKAGE_RID_COUNT                    = 2,
  SECURITY_PACKAGE_NTLM_RID                     = 0x0000000A,
  SECURITY_PACKAGE_SCHANNEL_RID                 = 0x0000000E,
  SECURITY_PACKAGE_DIGEST_RID                   = 0x00000015,
  DOMAIN_USER_RID_ADMIN                         = 0x000001F4,
  DOMAIN_USER_RID_GUEST                         = 0x000001F5,
  DOMAIN_USER_RID_KRBTGT                        = 0x000001F6
}

struct SID_IDENTIFIER_AUTHORITY {
  ubyte[6] Value;
}

struct SID {
  ubyte Revision;
  ubyte SubAuthorityCount;
  SID_IDENTIFIER_AUTHORITY IdentifierAuthority;
  uint[1] SubAuthority;
}

struct SID_AND_ATTRIBUTES {
  SID* Sid;
  uint Attributes;
}

struct TOKEN_USER {
  SID_AND_ATTRIBUTES User;
}

struct TOKEN_SOURCE {
  char[8] SourceName;
  LUID SourceIdentifier;
}

enum SECURITY_IMPERSONATION_LEVEL : uint {
  SecurityAnonymous,
  SecurityIdentification,
  SecurityImpersonation,
  SecurityDelegation
}

enum TOKEN_TYPE : uint {
  TokenPrimary = 1,
  TokenImpersonation
}

struct TOKEN_STATISTICS {
  LUID TokenId;
  LUID AuthenticationId;
  long ExpirationTime;
  TOKEN_TYPE TokenType;
  SECURITY_IMPERSONATION_LEVEL ImpersonationLevel;
  uint DynamicCharged;
  uint DynamicAvailable;
  uint GroupCount;
  uint PriviledgeCount;
  LUID ModifiedId;
}

enum : uint {
  TOKEN_ASSIGN_PRIMARY    = 0x0001,
  TOKEN_DUPLICATE         = 0x0002,
  TOKEN_IMPERSONATE       = 0x0004,
  TOKEN_QUERY             = 0x0008,
  TOKEN_QUERY_SOURCE      = 0x0010,
  TOKEN_ADJUST_PRIVILEGES = 0x0020,
  TOKEN_ADJUST_GROUPS     = 0x0040,
  TOKEN_ADJUST_DEFAULT    = 0x0080,
  TOKEN_ADJUST_SESSIONID  = 0x0100,
  TOKEN_ALL_ACCESS        = STANDARD_RIGHTS_REQUIRED | TOKEN_ASSIGN_PRIMARY | TOKEN_DUPLICATE | TOKEN_IMPERSONATE | 
    TOKEN_QUERY | TOKEN_QUERY_SOURCE | TOKEN_ADJUST_PRIVILEGES | TOKEN_ADJUST_GROUPS | TOKEN_ADJUST_DEFAULT | TOKEN_ADJUST_SESSIONID,
  TOKEN_READ              = STANDARD_RIGHTS_READ | TOKEN_QUERY,
  TOKEN_WRITE             = STANDARD_RIGHTS_WRITE | TOKEN_ADJUST_PRIVILEGES | TOKEN_ADJUST_GROUPS | TOKEN_ADJUST_DEFAULT,
  TOKEN_EXECUTE           = STANDARD_RIGHTS_EXECUTE
}

int OpenProcessToken(Handle ProcessHandle, uint DesiredAccess, out Handle TokenHandle);

int OpenThreadToken(Handle ThreadHandle, uint DesiredAccess, int OpenAsSelf, out Handle TokenHandle);

int DuplicateTokenEx(Handle hExistingToken, uint dwDesiredAccess, SECURITY_ATTRIBUTES* lpTokenAttributes, SECURITY_IMPERSONATION_LEVEL ImpersonationLevel, TOKEN_TYPE TokenType, out Handle phNewToken);

int CheckTokenMembership(Handle TokenHandle, SID* SidToCheck, out BOOL IsMember);

enum TOKEN_INFORMATION_CLASS : uint {
  TokenUser = 1,
  TokenGroups,
  TokenPrivileges,
  TokenOwner,
  TokenPrimaryGroup,
  TokenDefaultDacl,
  TokenSource,
  TokenType,
  TokenImpersonationLevel,
  TokenStatistics,
  TokenRestrictedSids,
  TokenSessionId,
  TokenGroupsAndPrivileges,
  TokenSessionReference,
  TokenSandBoxInert,
  TokenAuditPolicy,
  TokenOrigin,
  TokenElevationType,
  TokenLinkedToken,
  TokenElevation,
  TokenHasRestrictions,
  TokenAccessInformation,
  TokenVirtualizationAllowed,
  TokenVirtualizationEnabled,
  TokenIntegrityLevel,
  TokenUIAccess,
  TokenMandatoryPolicy,
  TokenLogonSid,
  MaxTokenInfoCla
}

int GetTokenInformation(Handle TokenHandle, TOKEN_INFORMATION_CLASS TokenInformationClass, void* TokenInformation, uint TokenInformationLength, ref uint ReturnLength);

int ConvertStringSidToSidW(in wchar* StringSid, out SID* Sid);
alias ConvertStringSidToSidW ConvertStringSidToSid;

enum : uint {
  SidTypeUser = 1,
  SidTypeGroup,
  SidTypeDomain,
  SidTypeAlias,
  SidTypeWellKnownGroup,
  SidTypeDeletedAccount,
  SidTypeInvalid,
  SidTypeUnknown,
  SidTypeComputer,
  SidTypeLabel
}

int LookupAccountSidW(in wchar* lpSystemName, SID* Sid, wchar* Name, ref uint cchName, wchar* ReferencedDomainName, ref uint cchReferencedDomainName, out uint peUse);
alias LookupAccountSidW LookupAccountSid;

int IsValidSid(SID* pSid);

// CryptoAPI

struct DATA_BLOB {
  uint cbData;
  ubyte* pbData;
}
alias DATA_BLOB CERT_BLOB;

struct CRYPT_BIT_BLOB {
  uint cbData;
  ubyte* pbData;
  uint cUnusedBits;
}

struct CRYPT_ALGORITHM_IDENTIFIER {
  char* pszObjId;
  CERT_BLOB Parameters;
}

struct CERT_PUBLIC_KEY_INFO {
  CRYPT_ALGORITHM_IDENTIFIER Algorithm;
  CRYPT_BIT_BLOB PublicKey;
}

struct CERT_EXTENSION {
  char* pszObjId;
  int fCritical;
  CERT_BLOB Value;
}

struct CERT_INFO {
  uint dwVersion;
  CERT_BLOB SerialNumber;
  CRYPT_ALGORITHM_IDENTIFIER SignatureAlgorithm;
  CERT_BLOB Issuer;
  FILETIME NotBefore;
  FILETIME NotAfter;
  CERT_BLOB Subject;
  CERT_PUBLIC_KEY_INFO SubjectPublicKeyInfo;
  CRYPT_BIT_BLOB IssuerUniqueId;
  CRYPT_BIT_BLOB SubjectUniqueId;
  uint cExtension;
  CERT_EXTENSION* rgExtension;
}

struct CERT_CONTEXT {
  uint dwCertEncodingType;
  ubyte* pbCertEncoded;
  uint cbCertEncoded;
  CERT_INFO* pCertInfo;
  Handle hCertStore;
}

const char* CERT_STORE_PROV_MEMORY = cast(char*)2;
const char* CERT_STORE_PROV_FILE = cast(char*)3;
const char* CERT_STORE_PROV_PKCS7 = cast(char*)5;
const char* CERT_STORE_PROV_SERIALIZED = cast(char*)6;
const char* CERT_STORE_PROV_FILENAME_A = cast(char*)7;
const char* CERT_STORE_PROV_FILENAME_W = cast(char*)8;
alias CERT_STORE_PROV_FILENAME_W CERT_STORE_PROV_FILENAME;
const char* CERT_STORE_PROV_SYSTEM_A = cast(char*)9;
const char* CERT_STORE_PROV_SYSTEM_W = cast(char*)10;
alias CERT_STORE_PROV_SYSTEM_W CERT_STORE_PROV_SYSTEM;

enum : uint {
  CRYPT_ASN_ENCODING  = 0x00000001,
  CRYPT_NDR_ENCODING  = 0x00000002,
  X509_ASN_ENCODING   = 0x00000001,
  X509_NDR_ENCODING   = 0x00000002,
  PKCS_7_ASN_ENCODING = 0x00010000,
  PKCS_7_NDR_ENCODING = 0x00020000
}

enum : uint {
  CERT_STORE_NO_CRYPT_RELEASE_FLAG            = 0x00000001,
  CERT_STORE_SET_LOCALIZED_NAME_FLAG          = 0x00000002,
  CERT_STORE_DEFER_CLOSE_UNTIL_LAST_FREE_FLAG = 0x00000004,
  CERT_STORE_DELETE_FLAG                      = 0x00000010,
  CERT_STORE_UNSAFE_PHYSICAL_FLAG             = 0x00000020,
  CERT_STORE_SHARE_STORE_FLAG                 = 0x00000040,
  CERT_STORE_SHARE_CONTEXT_FLAG               = 0x00000080,
  CERT_STORE_MANIFOLD_FLAG                    = 0x00000100,
  CERT_STORE_ENUM_ARCHIVED_FLAG               = 0x00000200,
  CERT_STORE_UPDATE_KEYID_FLAG                = 0x00000400,
  CERT_STORE_BACKUP_RESTORE_FLAG              = 0x00000800,
  CERT_STORE_READONLY_FLAG                    = 0x00008000,
  CERT_STORE_OPEN_EXISTING_FLAG               = 0x00004000,
  CERT_STORE_CREATE_NEW_FLAG                  = 0x00002000,
  CERT_STORE_MAXIMUM_ALLOWED_FLAG             = 0x00001000
}

enum : uint {
  CERT_SYSTEM_STORE_LOCATION_MASK    = 0x00FF0000,
  CERT_SYSTEM_STORE_LOCATION_SHIFT   = 16,
  CERT_SYSTEM_STORE_CURRENT_USER_ID  = 1,
  CERT_SYSTEM_STORE_LOCAL_MACHINE_ID = 2,
  CERT_SYSTEM_STORE_CURRENT_USER     = CERT_SYSTEM_STORE_CURRENT_USER_ID << CERT_SYSTEM_STORE_LOCATION_SHIFT,
  CERT_SYSTEM_STORE_LOCAL_MACHINE    = CERT_SYSTEM_STORE_LOCAL_MACHINE_ID << CERT_SYSTEM_STORE_LOCATION_SHIFT
}

Handle CertOpenStore(in char* lpszStoreProvider, uint dwMsgAndCertEncodingType, Handle hCryptProv, uint dwFlags, in void* pvPara);

int CertCloseStore(Handle hCertStore, uint dwFlags);

Handle CertDuplicateStore(Handle hCertStore);

enum : uint {
  CERT_STORE_ADD_NEW                                 = 1,
  CERT_STORE_ADD_USE_EXISTING                        = 2,
  CERT_STORE_ADD_REPLACE_EXISTING                    = 3,
  CERT_STORE_ADD_ALWAYS                              = 4,
  CERT_STORE_ADD_REPLACE_EXISTING_INHERIT_PROPERTIES = 5,
  CERT_STORE_ADD_NEWER                               = 6,
  CERT_STORE_ADD_NEWER_INHERIT_PROPERTIES            = 7
}

int CertAddCertificateContextToStore(Handle hCertStore, CERT_CONTEXT* pCertContext, uint dwAddDisposition, CERT_CONTEXT** ppStoreContext);

int CertAddCertificateLinkToStore(Handle hCertStore, CERT_CONTEXT* pCertContext, uint dwAddDisposition, CERT_CONTEXT** ppStoreContext);

enum : uint {
  CERT_STORE_CERTIFICATE_CONTEXT = 1,
  CERT_STORE_CRL_CONTEXT         = 2,
  CERT_STORE_CTL_CONTEXT         = 3,
  CERT_STORE_CERTIFICATE_CONTEXT_FLAG = 1 << CERT_STORE_CERTIFICATE_CONTEXT,
  CERT_STORE_CRL_CONTEXT_FLAG = 1 << CERT_STORE_CRL_CONTEXT,
  CERT_STORE_CTL_CONTEXT_FLAG = 1 << CERT_STORE_CTL_CONTEXT
}

int CertAddSerializedElementToStore(Handle hCertStore, in ubyte* pbElement, uint cbElement, uint dwAddDisposition, uint dwFlags, uint dwContextTypeFlags, uint* pdwContextType, void** ppvContext);

CERT_CONTEXT* CertGetSubjectCertificateFromStore(Handle hCertStore, uint dwCertEncodingType, CERT_INFO* pCertId);

int CertSerializeCertificateStoreElement(CERT_CONTEXT* pCertContext, uint dwFlags, ubyte* pbElement, ref uint pcbElement);

enum : uint {
  CERT_STORE_SAVE_AS_STORE  = 1,
  CERT_STORE_SAVE_AS_PKCS7  = 2,
  CERT_STORE_SAVE_AS_PKCS12 = 3
}

enum : uint {
  CERT_STORE_SAVE_TO_FILE       = 1,
  CERT_STORE_SAVE_TO_MEMORY     = 2,
  CERT_STORE_SAVE_TO_FILENAME_A = 3,
  CERT_STORE_SAVE_TO_FILENAME_W = 4
}

int CertSaveStore(Handle hCertStore, uint dwMsgAndCertEncodingType, uint dwSaveAs, uint dwSaveTo, in void* pvSaveToPara, uint dwFlags);

enum : uint {
  REPORT_NO_PRIVATE_KEY                 = 0x0001,
  REPORT_NOT_ABLE_TO_EXPORT_PRIVATE_KEY = 0x0002,
  EXPORT_PRIVATE_KEYS                   = 0x0004,
  PKCS12_INCLUDE_EXTENDED_PROPERTIES    = 0x0010
}

int PFXExportCertStore(Handle hStore, CERT_BLOB* pPFX, in wchar* szPassword, uint dwFlags);

Handle PFXImportCertStore(CERT_BLOB* pPFX, in wchar* szPassword, uint dwFlags);

CERT_CONTEXT* CertEnumCertificatesInStore(Handle hCertStore, CERT_CONTEXT* pPrevCertContext);

enum : uint {
  CERT_COMPARE_MASK                   = 0xFFFF,
  CERT_COMPARE_SHIFT                  = 16,
  CERT_COMPARE_ANY                    = 0,
  CERT_COMPARE_SHA1_HASH              = 1,
  CERT_COMPARE_NAME                   = 2,
  CERT_COMPARE_ATTR                   = 3,
  CERT_COMPARE_MD5_HASH               = 4,
  CERT_COMPARE_PROPERTY               = 5,
  CERT_COMPARE_PUBLIC_KEY             = 6,
  CERT_COMPARE_HASH                   = CERT_COMPARE_SHA1_HASH,
  CERT_COMPARE_NAME_STR_A             = 7,
  CERT_COMPARE_NAME_STR_W             = 8,
  CERT_COMPARE_KEY_SPEC               = 9,
  CERT_COMPARE_ENHKEY_USAGE           = 10,
  CERT_COMPARE_CTL_USAGE              = CERT_COMPARE_ENHKEY_USAGE,
  CERT_COMPARE_SUBJECT_CERT           = 11,
  CERT_COMPARE_ISSUER_OF              = 12,
  CERT_COMPARE_EXISTING               = 13,
  CERT_COMPARE_SIGNATURE_HASH         = 14,
  CERT_COMPARE_KEY_IDENTIFIER         = 15,
  CERT_COMPARE_CERT_ID                = 16,
  CERT_COMPARE_CROSS_CERT_DIST_POINTS = 17,
  CERT_COMPARE_PUBKEY_MD5_HASH        = 18,
  CERT_COMPARE_SUBJECT_INFO_ACCESS    = 19
}

enum : uint {
  CERT_FIND_ANY       = CERT_COMPARE_ANY << CERT_COMPARE_SHIFT,
  CERT_FIND_EXISTING  = CERT_COMPARE_EXISTING << CERT_COMPARE_SHIFT
}

CERT_CONTEXT* CertFindCertificateInStore(Handle hCertStore, uint dwCertEncodingType, uint dwFindFlags, uint dwFindType, in void* pvFindPara, CERT_CONTEXT* pPrevCertContext);

CERT_CONTEXT* CertDuplicateCertificateContext(CERT_CONTEXT* pCertContext);

int CertFreeCertificateContext(CERT_CONTEXT* pCertContext);

int CertDeleteCertificateFromStore(CERT_CONTEXT* pCertContext);

CERT_CONTEXT* CertCreateCertificateContext(uint dwCertEncodingType, in ubyte* pbCertEncoded, uint cbCertEncoded);

enum : uint {
  CERT_NAME_EMAIL_TYPE            = 1,
  CERT_NAME_RDN_TYPE              = 2,
  CERT_NAME_ATTR_TYPE             = 3,
  CERT_NAME_SIMPLE_DISPLAY_TYPE   = 4,
  CERT_NAME_FRIENDLY_DISPLAY_TYPE = 5,
  CERT_NAME_DNS_TYPE              = 6,
  CERT_NAME_URL_TYPE              = 7,
  CERT_NAME_UPN_TYPE              = 8
}

enum : uint {
  CERT_NAME_ISSUER_FLAG           = 0x1,
  CERT_NAME_DISABLE_IE4_UTF8_FLAG = 0x00010000
}

uint CertGetNameStringW(CERT_CONTEXT* pCertContext, uint dwType, uint dwFlags, void* pvTypePara, wchar* pszNameString, uint cchNameString);
alias CertGetNameStringW CertGetNameString;

enum : uint {
  CERT_SIMPLE_NAME_STR = 1,
  CERT_OID_NAME_STR    = 2,
  CERT_X500_NAME_STR   = 3,
  CERT_XML_NAME_STR    = 4
}

enum : uint {
  CERT_NAME_STR_SEMICOLON_FLAG            = 0x40000000,
  CERT_NAME_STR_NO_PLUS_FLAG              = 0x20000000,
  CERT_NAME_STR_NO_QUOTING_FLAG           = 0x10000000,
  CERT_NAME_STR_CRLF_FLAG                 = 0x08000000,
  CERT_NAME_STR_COMMA_FLAG                = 0x04000000,
  CERT_NAME_STR_REVERSE_FLAG              = 0x02000000,
  CERT_NAME_STR_FORWARD_FLAG              = 0x01000000,
  CERT_NAME_STR_DISABLE_IE4_UTF8_FLAG     = 0x00010000,
  CERT_NAME_STR_ENABLE_T61_UNICODE_FLAG   = 0x00020000,
  CERT_NAME_STR_ENABLE_UTF8_UNICODE_FLAG  = 0x00040000,
  CERT_NAME_STR_FORCE_UTF8_DIR_STR_FLAG   = 0x00080000,
  CERT_NAME_STR_DISABLE_UTF8_DIR_STR_FLAG = 0x00100000
}

uint CertNameToStrW(uint dwCertEncodingType, CERT_BLOB* pName, uint dwStrType, wchar* psz, uint csz);
alias CertNameToStrW CertNameToStr;

uint CertStrToNameW(uint dwCertEncodingType, in wchar* pszX500, uint dwStrType, void* pvReserved, ubyte* pbEncoded, ref uint pcbEncoded, wchar** ppszError);
alias CertStrToNameW CertStrToName;

enum : uint {
  CERT_KEY_PROV_HANDLE_PROP_ID = 1,
  CERT_KEY_PROV_INFO_PROP_ID = 2,
  CERT_SHA1_HASH_PROP_ID = 3,
  CERT_HASH_PROP_ID = CERT_SHA1_HASH_PROP_ID,
  CERT_FRIENDLY_NAME_PROP_ID = 11
}

int CertGetCertificateContextProperty(CERT_CONTEXT* pCertContext, uint dwPropId, void* pvData, ref uint pcbData);

int CertSetCertificateContextProperty(CERT_CONTEXT* pCertContext, uint dwPropId, uint dwFlags, in void* pvData);

const wchar* MS_DEF_PROV = "Microsoft Base Cryptographic Provider v1.0";
const wchar* MS_ENHANCED_PROV = "Microsoft Enhanced Cryptographic Provider v1.0";
const wchar* MS_STRONG_PROV = "Microsoft Strong Cryptographic Provider";
const wchar* MS_DEF_RSA_SIG_PROV = "Microsoft RSA Signature Cryptographic Provider";
const wchar* MS_DEF_RSA_SCHANNEL_PROV = "Microsoft RSA SChannel Cryptographic Provider";
const wchar* MS_DEF_DSS_PROV = "Microsoft Base DSS Cryptographic Provider";
const wchar* MS_DEF_DSS_DH_PROV = "Microsoft Base DSS and Diffie-Hellman Cryptographic Provider";
const wchar* MS_ENH_DSS_DH_PROV = "Microsoft Enhanced DSS and Diffie-Hellman Cryptographic Provider";
const wchar* MS_DEF_DH_SCHANNEL_PROV = "Microsoft DH SChannel Cryptographic Provider";
const wchar* MS_SCARD_PROV = "Microsoft Base Smart Card Crypto Provider";
const wchar* MS_ENH_RSA_AES_PROV = "Microsoft Enhanced RSA and AES Cryptographic Provider";
const wchar* MS_ENH_RSA_AES_PROV_XP = "Microsoft Enhanced RSA and AES Cryptographic Provider (Prototype)";

enum : uint {
  PROV_RSA_FULL      = 1,
  PROV_RSA_SIG       = 2,
  PROV_DSS           = 3,
  PROV_FORTEZZA      = 4,
  PROV_MS_EXCHANGE   = 5,
  PROV_SSL           = 6,
  PROV_RSA_SCHANNEL  = 12,
  PROV_DSS_DH        = 13,
  PROV_EC_ECDSA_SIG  = 14,
  PROV_EC_ECNRA_SIG  = 15,
  PROV_EC_ECDSA_FULL = 16,
  PROV_EC_ECNRA_FULL = 17,
  PROV_DH_SCHANNEL   = 18,
  PROV_SPYRUS_LYNKS  = 20,
  PROV_RNG           = 21,
  PROV_INTEL_SEC     = 22,
  PROV_REPLACE_OWF   = 23,
  PROV_RSA_AES       = 24
}

enum : uint {
  CRYPT_VERIFYCONTEXT    = 0xF0000000,
  CRYPT_NEWKEYSET        = 0x00000008,
  CRYPT_DELETEKEYSET     = 0x00000010,
  CRYPT_MACHINE_KEYSET   = 0x00000020,
  CRYPT_SILENT           = 0x00000040
}

int CryptAcquireContextW(out Handle phProv, in wchar* szContainer, in wchar* szProvider, uint dwProvType, uint dwFlags);
alias CryptAcquireContextW CryptAcquireContext;

int CryptReleaseContext(Handle hProv, uint dwFlags);

enum : uint {
  PP_ENUMALGS            = 1,
  PP_ENUMCONTAINERS      = 2,
  PP_IMPTYPE             = 3,
  PP_NAME                = 4,
  PP_VERSION             = 5,
  PP_CONTAINER           = 6,
  PP_CHANGE_PASSWORD     = 7,
  PP_KEYSET_SEC_DESCR    = 8,
  PP_CERTCHAIN           = 9,
  PP_KEY_TYPE_SUBTYPE    = 10,
  PP_PROVTYPE            = 16,
  PP_KEYSTORAGE          = 17,
  PP_APPLI_CERT          = 18,
  PP_SYM_KEYSIZE         = 19,
  PP_SESSION_KEYSIZE     = 20,
  PP_UI_PROMPT           = 21,
  PP_ENUMALGS_EX         = 22,
  PP_ENUMMANDROOTS       = 25,
  PP_ENUMELECTROOTS      = 26,
  PP_KEYSET_TYPE         = 27,
  PP_ADMIN_PIN           = 31,
  PP_KEYEXCHANGE_PIN     = 32,
  PP_SIGNATURE_PIN       = 33,
  PP_SIG_KEYSIZE_INC     = 34,
  PP_KEYX_KEYSIZE_INC    = 35,
  PP_UNIQUE_CONTAINER    = 36,
  PP_SGC_INFO            = 37,
  PP_USE_HARDWARE_RNG    = 38,
  PP_KEYSPEC             = 39,
  PP_ENUMEX_SIGNING_PROT = 40,
  PP_CRYPT_COUNT_KEY_USE = 41,
  PP_USER_CERTSTORE      = 42,
  PP_SMARTCARD_READER    = 43,
  PP_SMARTCARD_GUID      = 45,
  PP_ROOT_CERTSTORE      = 46
}

struct PROV_ENUMALGS {
  uint aiAlgid;
  uint dwBitLen;
  uint dwNameLen;
  char[20] szName;
}

enum : uint {
  CRYPT_FIRST    = 1,
  CRYPT_NEXT     = 2,
  CRYPT_SGC_ENUM = 4
}

int CryptGetProvParam(Handle hProv, uint dwParam, ubyte* pbData, ref uint pdwDataLen, uint dwFlags);

enum : uint {
  ALG_CLASS_ANY          = 0,
  ALG_CLASS_SIGNATURE    = 1 << 13,
  ALG_CLASS_MSG_ENCRYPT  = 2 << 13,
  ALG_CLASS_DATA_ENCRYPT = 3 << 13,
  ALG_CLASS_HASH         = 4 << 13,
  ALG_CLASS_KEY_EXCHANGE = 5 << 13,
  ALG_CLASS_ALL          = 7 << 13
}

enum : uint {
  ALG_TYPE_ANY           = 0,
  ALG_TYPE_DSS           = 1 << 9,
  ALG_TYPE_RSA           = 2 << 9,
  ALG_TYPE_BLOCK         = 3 << 9,
  ALG_TYPE_STREAM        = 4 << 9,
  ALG_TYPE_DH            = 5 << 9,
  ALG_TYPE_SECURECHANNEL = 6 << 9
}

enum : uint {
  ALG_SID_RSA_ANY                = 0,
  ALG_SID_RSA_PKCS               = 1,
  ALG_SID_RSA_MSATWORK           = 2,
  ALG_SID_RSA_ENTRUST            = 3,
  ALG_SID_RSA_PGP                = 4,

  ALG_SID_DSS_ANY                = 0,

  ALG_SID_DSS_PKCS               = 1,
  ALG_SID_DSS_DMS                = 2,

  ALG_SID_MD2                    = 1,
  ALG_SID_MD4                    = 2,
  ALG_SID_MD5                    = 3,
  ALG_SID_SHA                    = 4,
  ALG_SID_SHA1                   = 4,
  ALG_SID_MAC                    = 5,
  ALG_SID_RIPEMD                 = 6,
  ALG_SID_RIPEMD160              = 7,
  ALG_SID_SSL3SHAMD5             = 8,
  ALG_SID_HMAC                   = 9,
  ALG_SID_TLS1PRF                = 10,
  ALG_SID_HASH_REPLACE_OWF       = 11,
  ALG_SID_SHA_256                = 12,
  ALG_SID_SHA_384                = 13,
  ALG_SID_SHA_512                = 14,

  ALG_SID_DES                    = 1,
  ALG_SID_3DES                   = 3,
  ALG_SID_DESX                   = 4,
  ALG_SID_IDEA                   = 5,
  ALG_SID_CAST                   = 6,
  ALG_SID_SAFERSK64              = 7,
  ALG_SID_SAFERSK128             = 8,
  ALG_SID_3DES_112               = 9,
  ALG_SID_CYLINK_MEK             = 12,
  ALG_SID_RC5                    = 13,
  ALG_SID_AES_128                = 14,
  ALG_SID_AES_192                = 15,
  ALG_SID_AES_256                = 16,
  ALG_SID_AES                    = 17,

  ALG_SID_SKIPJACK               = 10,
  ALG_SID_TEK                    = 11,

  ALG_SID_RC2                    = 2,

  ALG_SID_RC4                    = 1,
  ALG_SID_SEAL                   = 2,

  ALG_SID_DH_SANDF               = 1,
  ALG_SID_DH_EPHEM               = 2,
  ALG_SID_AGREED_KEY_ANY         = 3,
  ALG_SID_KEA                    = 4,

  ALG_SID_SSL3_MASTER            = 1,
  ALG_SID_SCHANNEL_MASTER_HASH   = 2,
  ALG_SID_SCHANNEL_MAC_KEY       = 3,
  ALG_SID_PCT1_MASTER            = 4,
  ALG_SID_SSL2_MASTER            = 5,
  ALG_SID_TLS1_MASTER            = 6,
  ALG_SID_SCHANNEL_ENC_KEY       = 7
}

enum : uint {
  CALG_MD2                    = ALG_CLASS_HASH | ALG_TYPE_ANY | ALG_SID_MD2,
  CALG_MD4                    = ALG_CLASS_HASH | ALG_TYPE_ANY | ALG_SID_MD4,
  CALG_MD5                    = ALG_CLASS_HASH | ALG_TYPE_ANY | ALG_SID_MD5,
  CALG_SHA                    = ALG_CLASS_HASH | ALG_TYPE_ANY | ALG_SID_SHA,
  CALG_SHA1                   = ALG_CLASS_HASH | ALG_TYPE_ANY | ALG_SID_SHA1,
  CALG_MAC                    = ALG_CLASS_HASH | ALG_TYPE_ANY | ALG_SID_MAC,
  CALG_RSA_SIGN               = ALG_CLASS_SIGNATURE | ALG_TYPE_RSA | ALG_SID_RSA_ANY,
  CALG_DSS_SIGN               = ALG_CLASS_SIGNATURE | ALG_TYPE_DSS | ALG_SID_DSS_ANY,
  CALG_RSA_KEYX               = ALG_CLASS_KEY_EXCHANGE | ALG_TYPE_RSA | ALG_SID_RSA_ANY,
  CALG_DES                    = ALG_CLASS_DATA_ENCRYPT | ALG_TYPE_BLOCK | ALG_SID_DES,
  CALG_3DES_112               = ALG_CLASS_DATA_ENCRYPT | ALG_TYPE_BLOCK | ALG_SID_3DES_112,
  CALG_3DES                   = ALG_CLASS_DATA_ENCRYPT | ALG_TYPE_BLOCK | ALG_SID_3DES,
  CALG_DESX                   = ALG_CLASS_DATA_ENCRYPT | ALG_TYPE_BLOCK | ALG_SID_DESX,
  CALG_RC2                    = ALG_CLASS_DATA_ENCRYPT | ALG_TYPE_BLOCK | ALG_SID_RC2,
  CALG_RC4                    = ALG_CLASS_DATA_ENCRYPT | ALG_TYPE_STREAM | ALG_SID_RC4,
  CALG_SEAL                   = ALG_CLASS_DATA_ENCRYPT | ALG_TYPE_STREAM | ALG_SID_SEAL,
  CALG_DH_SF                  = ALG_CLASS_KEY_EXCHANGE | ALG_TYPE_DH | ALG_SID_DH_SANDF,
  CALG_DH_EPHEM               = ALG_CLASS_KEY_EXCHANGE | ALG_TYPE_DH | ALG_SID_DH_EPHEM,
  CALG_AGREEDKEY_ANY          = ALG_CLASS_KEY_EXCHANGE | ALG_TYPE_DH | ALG_SID_AGREED_KEY_ANY,
  CALG_KEA_KEYX               = ALG_CLASS_KEY_EXCHANGE | ALG_TYPE_DH | ALG_SID_KEA,
  CALG_HUGHES_MD5             = ALG_CLASS_KEY_EXCHANGE | ALG_TYPE_ANY | ALG_SID_MD5,
  CALG_SKIPJACK               = ALG_CLASS_DATA_ENCRYPT | ALG_TYPE_BLOCK | ALG_SID_SKIPJACK,
  CALG_TEK                    = ALG_CLASS_DATA_ENCRYPT | ALG_TYPE_BLOCK | ALG_SID_TEK,
  CALG_CYLINK_MEK             = ALG_CLASS_DATA_ENCRYPT | ALG_TYPE_BLOCK | ALG_SID_CYLINK_MEK,
  CALG_SSL3_SHAMD5            = ALG_CLASS_HASH | ALG_TYPE_ANY | ALG_SID_SSL3SHAMD5,
  CALG_SSL3_MASTER            = ALG_CLASS_MSG_ENCRYPT | ALG_TYPE_SECURECHANNEL | ALG_SID_SSL3_MASTER,
  CALG_SCHANNEL_MASTER_HASH   = ALG_CLASS_MSG_ENCRYPT | ALG_TYPE_SECURECHANNEL | ALG_SID_SCHANNEL_MASTER_HASH,
  CALG_SCHANNEL_MAC_KEY       = ALG_CLASS_MSG_ENCRYPT | ALG_TYPE_SECURECHANNEL | ALG_SID_SCHANNEL_MAC_KEY,
  CALG_SCHANNEL_ENC_KEY       = ALG_CLASS_MSG_ENCRYPT | ALG_TYPE_SECURECHANNEL | ALG_SID_SCHANNEL_ENC_KEY,
  CALG_PCT1_MASTER            = ALG_CLASS_MSG_ENCRYPT | ALG_TYPE_SECURECHANNEL | ALG_SID_PCT1_MASTER,
  CALG_SSL2_MASTER            = ALG_CLASS_MSG_ENCRYPT | ALG_TYPE_SECURECHANNEL | ALG_SID_SSL2_MASTER,
  CALG_TLS1_MASTER            = ALG_CLASS_MSG_ENCRYPT | ALG_TYPE_SECURECHANNEL | ALG_SID_TLS1_MASTER,
  CALG_RC5                    = ALG_CLASS_DATA_ENCRYPT | ALG_TYPE_BLOCK | ALG_SID_RC5,
  CALG_HMAC                   = ALG_CLASS_HASH | ALG_TYPE_ANY | ALG_SID_HMAC,
  CALG_TLS1PRF                = ALG_CLASS_HASH | ALG_TYPE_ANY | ALG_SID_TLS1PRF,
  CALG_AES_128                = ALG_CLASS_DATA_ENCRYPT| ALG_TYPE_BLOCK| ALG_SID_AES_128,
  CALG_AES_192                = ALG_CLASS_DATA_ENCRYPT| ALG_TYPE_BLOCK| ALG_SID_AES_192,
  CALG_AES_256                = ALG_CLASS_DATA_ENCRYPT| ALG_TYPE_BLOCK| ALG_SID_AES_256,
  CALG_AES                    = ALG_CLASS_DATA_ENCRYPT| ALG_TYPE_BLOCK| ALG_SID_AES,
  CALG_SHA_256                = ALG_CLASS_HASH | ALG_TYPE_ANY | ALG_SID_SHA_256,
  CALG_SHA_384                = ALG_CLASS_HASH | ALG_TYPE_ANY | ALG_SID_SHA_384,
  CALG_SHA_512                = ALG_CLASS_HASH | ALG_TYPE_ANY | ALG_SID_SHA_512
}

int CryptCreateHash(Handle hProv, uint Algid, Handle hKey, uint dwFlags, out Handle phHash);

int CryptHashData(Handle hHash, in ubyte* pbData, uint dwDataLen, uint dwFlags);

int CryptSignHashW(Handle hHash, uint dwKeySpec, in wchar* sDescription, uint dwFlags, ubyte* pbSignature, ref uint pdwSignLen);
alias CryptSignHashW CryptSignHash;

enum : uint {
  HP_ALGID         = 0x0001,
  HP_HASHVAL       = 0x0002,
  HP_HASHSIZE      = 0x0004,
  HP_HMAC_INFO     = 0x0005,
  HP_TLS1PRF_LABEL = 0x0006,
  HP_TLS1PRF_SEED  = 0x0007
}

int CryptGetHashParam(Handle hHash, uint dwParam, ubyte* pbData, ref uint pswDataLen, uint dwFlags);

int CryptDestroyHash(Handle hHash);

int CryptVerifySignatureW(Handle hHash, ubyte* pbSignature, uint dwSigLen, Handle hPubKey, in wchar* sDescription, uint dwFlags);
alias CryptVerifySignatureW CryptVerifySignature;

enum : uint {
  KP_IV                  = 1,
  KP_SALT                = 2,
  KP_PADDING             = 3,
  KP_MODE                = 4,
  KP_MODE_BITS           = 5,
  KP_PERMISSIONS         = 6,
  KP_ALGID               = 7,
  KP_BLOCKLEN            = 8,
  KP_KEYLEN              = 9,
  KP_SALT_EX             = 10,
  KP_P                   = 11,
  KP_G                   = 12,
  KP_Q                   = 13,
  KP_X                   = 14,
  KP_Y                   = 15,
  KP_RA                  = 16,
  KP_RB                  = 17,
  KP_INFO                = 18,
  KP_EFFECTIVE_KEYLEN    = 19,
  KP_SCHANNEL_ALG        = 20,
  KP_CLIENT_RANDOM       = 21,
  KP_SERVER_RANDOM       = 22,
  KP_RP                  = 23,
  KP_PRECOMP_MD5         = 24,
  KP_PRECOMP_SHA         = 25,
  KP_CERTIFICATE         = 26,
  KP_CLEAR_KEY           = 27,
  KP_PUB_EX_LEN          = 28,
  KP_PUB_EX_VAL          = 29,
  KP_KEYVAL              = 30,
  KP_ADMIN_PIN           = 31,
  KP_KEYEXCHANGE_PIN     = 32,
  KP_SIGNATURE_PIN       = 33,
  KP_PREHASH             = 34
}

int CryptSetKeyParam(Handle hKey, uint dwParam, in ubyte* pbData, uint dwFlags);

int CryptGetKeyParam(Handle hKey, uint dwParam, ubyte* pbData, ref uint pdwDataLen, uint dwFlags);

enum : uint {
  CRYPT_EXPORTABLE                = 0x00000001,
  CRYPT_USER_PROTECTED            = 0x00000002,
  CRYPT_CREATE_SALT               = 0x00000004,
  CRYPT_UPDATE_KEY                = 0x00000008,
  CRYPT_NO_SALT                   = 0x00000010,
  CRYPT_PREGEN                    = 0x00000040,
  CRYPT_RECIPIENT                 = 0x00000010,
  CRYPT_INITIATOR                 = 0x00000040,
  CRYPT_ONLINE                    = 0x00000080,
  CRYPT_SF                        = 0x00000100,
  CRYPT_CREATE_IV                 = 0x00000200,
  CRYPT_KEK                       = 0x00000400,
  CRYPT_DATA_KEY                  = 0x00000800,
  CRYPT_VOLATILE                  = 0x00001000,
  CRYPT_SGCKEY                    = 0x00002000,
  CRYPT_ARCHIVABLE                = 0x00004000,
  CRYPT_FORCE_KEY_PROTECTION_HIGH = 0x00008000,
  CRYPT_SERVER                    = 0x00000400
}

enum : uint {
  CRYPT_Y_ONLY           = 0x00000001,
  CRYPT_SSL2_FALLBACK    = 0x00000002,
  CRYPT_DESTROYKEY       = 0x00000004,
  CRYPT_OAEP             = 0x00000040
}

int CryptDeriveKey(Handle hProv, uint Algid, Handle hBaseData, uint dwFlags, out Handle phKey);

// bType
enum : ubyte {
  SIMPLEBLOB           = 0x1,
  PUBLICKEYBLOB        = 0x6,
  PRIVATEKEYBLOB       = 0x7,
  PLAINTEXTKEYBLOB     = 0x8,
  OPAQUEKEYBLOB        = 0x9,
  PUBLICKEYBLOBEX      = 0xA,
  SYMMETRICWRAPKEYBLOB = 0xB
}

enum : ubyte {
  CUR_BLOB_VERSION = 2
}

struct BLOBHEADER {
  ubyte bType;
  ubyte bVersion;
  ushort reserved;
  uint aiKeyAlg;
}

struct RSAPUBKEY {
  uint magic;
  uint bitlen;
  uint pubexp;
}

struct DSSPUBKEY {
  uint magic;
  uint bitlen;
}

int CryptImportKey(Handle hProv, ubyte* pbData, uint dwDataLen, Handle hPubKey, uint dwFlags, out Handle phKey);

int CryptExportKey(Handle hprov, Handle hExpKey, uint dwBlobType, uint dwFlags, ubyte* pbData, ref uint pdwDataLen);

enum : uint {
  AT_KEYEXCHANGE         = 1,
  AT_SIGNATURE           = 2
}

int CryptGetUserKey(Handle hProv, uint dwKeySpec, out Handle phUserKey);

int CryptGenKey(Handle hProv, uint Algid, uint dwFlags, out Handle phKey);

int CryptDestroyKey(Handle hKey);

int CryptGenRandom(Handle hProv, uint dwLen, ubyte* lpBuffer);

int CryptEncrypt(Handle hKey, Handle hHash, int Final, uint dwFlags, ubyte* pbData, ref uint pdwDataLen, uint dwBufLen);

int CryptDecrypt(Handle hKey, Handle hHash, int Final, uint dwFlags, ubyte* pbData, ref uint pdwDataLen);

enum : uint {
  CRYPT_OID_INFO_OID_KEY       = 1,
  CRYPT_OID_INFO_NAME_KEY      = 2,
  CRYPT_OID_INFO_ALGID_KEY     = 3,
  CRYPT_OID_INFO_SIGN_KEY      = 4,
  CRYPT_OID_INFO_CNG_ALGID_KEY = 5,
  CRYPT_OID_INFO_CNG_SIGN_KEY  = 6
}

enum : uint {
  CRYPT_OID_INFO_PUBKEY_SIGN_KEY_FLAG    = 0x80000000,
  CRYPT_OID_INFO_PUBKEY_ENCRYPT_KEY_FLAG = 0x40000000
}

enum : uint {
  CRYPT_HASH_ALG_OID_GROUP_ID     = 1,
  CRYPT_ENCRYPT_ALG_OID_GROUP_ID  = 2,
  CRYPT_PUBKEY_ALG_OID_GROUP_ID   = 3,
  CRYPT_SIGN_ALG_OID_GROUP_ID     = 4,
  CRYPT_RDN_ATTR_OID_GROUP_ID     = 5,
  CRYPT_EXT_OR_ATTR_OID_GROUP_ID  = 6,
  CRYPT_ENHKEY_USAGE_OID_GROUP_ID = 7,
  CRYPT_POLICY_OID_GROUP_ID       = 8,
  CRYPT_TEMPLATE_OID_GROUP_ID     = 9
}

struct CRYPT_OID_INFO {
  uint cbSize = CRYPT_OID_INFO.sizeof;
  char* pszOID;
  wchar* pwszName;
  uint dwGroupId;
  union {
    uint dwValue;
    uint Algid;
    uint dwLength;
  }
  DATA_BLOB ExtraInfo;
}

CRYPT_OID_INFO* CryptFindOIDInfo(uint dwKeyType, in void* pvKey, uint dwGroupId);

enum : uint {
  CRYPT_FORMAT_STR_MULTI_LINE = 0x0001,
  CRYPT_FORMAT_STR_NO_HEX     = 0x0010
}

const char* X509_NAME             = cast(char*)7;
const char* RSA_CSP_PUBLICKEYBLOB = cast(char*)19;
const char* X509_MULTI_BYTE_UINT  = cast(char*)38;
const char* X509_DSS_PUBLICKEY    = X509_MULTI_BYTE_UINT;

int CryptFormatObject(uint dwCertEncodingType, uint dwFormatType, uint dwFormatStrType, void* pFormatStruct, in char* lpszStructType, ubyte* pbEncoded, uint cbEncoded, wchar* pbFormat, uint* pcbFormat);

int CryptDecodeObject(uint dwCertEncodingType, in char* lpszStructType, in ubyte* pbEncoded, uint cbEncoded, uint dwFlags, void* pvStructInfo, ref uint pcbStructInfo);

struct CRYPTPROTECT_PROMPTSTRUCT {
  uint cbSize = CRYPTPROTECT_PROMPTSTRUCT.sizeof;
  uint dwPromptFlags;
  Handle hwndApp;
  wchar* szPrompt;
}

enum : uint {
  CRYPTPROTECT_UI_FORBIDDEN = 0x1,
  CRYPTPROTECT_LOCAL_MACHINE = 0x4
}

int CryptProtectData(DATA_BLOB* pDataIn, in wchar* szDataDescr, DATA_BLOB* pOptionalEntropy, void* pvReserved, CRYPTPROTECT_PROMPTSTRUCT* pPromptStruct, uint dwFlags, DATA_BLOB* pDataOut);

int CryptUnprotectData(DATA_BLOB* pDataIn, wchar** ppszDataDescr, DATA_BLOB* pOptionalEntropy, void* pvReserved, CRYPTPROTECT_PROMPTSTRUCT* pPromptStruct, uint dwFlags, DATA_BLOB* pDataOut);

// dwObjectType
enum : uint {
  CERT_QUERY_OBJECT_FILE = 0x00000001,
  CERT_QUERY_OBJECT_BLOB = 0x00000002
}

// dwContentType
enum : uint {
  CERT_QUERY_CONTENT_CERT               = 1,
  CERT_QUERY_CONTENT_SERIALIZED_STORE   = 4,
  CERT_QUERY_CONTENT_SERIALIZED_CERT    = 5,
  CERT_QUERY_CONTENT_PKCS7_SIGNED       = 8,
  CERT_QUERY_CONTENT_PKCS7_UNSIGNED     = 9,
  CERT_QUERY_CONTENT_PKCS7_SIGNED_EMBED = 10,
  CERT_QUERY_CONTENT_PFX                = 12
}

// dwExpectedConentTypeFlag
enum : uint {
  CERT_QUERY_CONTENT_FLAG_CERT = 1 << CERT_QUERY_CONTENT_CERT,
  CERT_QUERY_CONTENT_FLAG_SERIALIZED_STORE = 1 << CERT_QUERY_CONTENT_SERIALIZED_STORE,
  CERT_QUERY_CONTENT_FLAG_SERIALIZED_CERT = 1 << CERT_QUERY_CONTENT_SERIALIZED_CERT,
  CERT_QUERY_CONTENT_FLAG_PKCS7_SIGNED = 1 << CERT_QUERY_CONTENT_PKCS7_SIGNED,
  CERT_QUERY_CONTENT_FLAG_PKCS7_UNSIGNED = 1 << CERT_QUERY_CONTENT_PKCS7_UNSIGNED,
  CERT_QUERY_CONTENT_FLAG_PKCS7_SIGNED_EMBED = 1 << CERT_QUERY_CONTENT_PKCS7_SIGNED_EMBED,
  CERT_QUERY_CONTENT_FLAG_PFX = 1 << CERT_QUERY_CONTENT_PFX,
  CERT_QUERY_CONTENT_FLAG_ALL = CERT_QUERY_CONTENT_FLAG_CERT | 
    CERT_QUERY_CONTENT_FLAG_SERIALIZED_STORE | 
    CERT_QUERY_CONTENT_FLAG_SERIALIZED_CERT | 
    CERT_QUERY_CONTENT_FLAG_PKCS7_SIGNED | 
    CERT_QUERY_CONTENT_FLAG_PKCS7_UNSIGNED | 
    CERT_QUERY_CONTENT_FLAG_PKCS7_SIGNED_EMBED |
    CERT_QUERY_CONTENT_FLAG_PFX
}

// dwFormatType
enum : uint {
  CERT_QUERY_FORMAT_BINARY                = 1,
  CERT_QUERY_FORMAT_BASE64_ENCODED        = 2,
  CERT_QUERY_FORMAT_ASN_ASCII_HEX_ENCODED = 3
}

// dwExpectedFormatTypeFlag
enum : uint {
  CERT_QUERY_FORMAT_FLAG_BINARY = 1 << CERT_QUERY_FORMAT_BINARY,
  CERT_QUERY_FORMAT_FLAG_BASE64_ENCODED = 1 << CERT_QUERY_FORMAT_BASE64_ENCODED,
  CERT_QUERY_FORMAT_FLAG_ASN_ASCII_HEX_ENCODED = 1 << CERT_QUERY_FORMAT_ASN_ASCII_HEX_ENCODED,
  CERT_QUERY_FORMAT_FLAG_ALL = CERT_QUERY_FORMAT_FLAG_BINARY |
    CERT_QUERY_FORMAT_FLAG_BASE64_ENCODED |
    CERT_QUERY_FORMAT_FLAG_ASN_ASCII_HEX_ENCODED
}

int CryptQueryObject(uint dwObjectType, in void* pvObject, uint dwExpectedContentTypeFlags, uint dwExpectedFormatTypeFlags, uint dwFlags, uint* pdwMsgAndCertEncodingType, uint* pdwContentType, uint* pdwFormatType, Handle* phCertStore, Handle* phMsg, void** ppvContext);

extern(D):

static string getErrorMessage(uint errorCode) {
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
  return std.string.format("Unspecified error (0x%08X)", errorCode);
}

/**
 * Generic Win32 Exception.
 *
 * The default contructor obtains the last error code and message.
 */
class Win32Exception : Exception {

  private uint errorCode_;

  this(uint errorCode = GetLastError()) {
    this(errorCode, getErrorMessage(errorCode));
  }

  this(uint errorCode, string message) {
    super(message);
    errorCode_ = errorCode;
  }

  @property uint errorCode() {
    return errorCode_;
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

private void* addressOfFunction(string dllName, string entryPoint, CharSet charSet) {
  static Handle[string] moduleStore;

  Handle moduleHandle;
  if (auto value = dllName in moduleStore)
    moduleHandle = *value;
  else
    moduleStore[dllName] = moduleHandle = LoadLibrary(dllName.toUTF16z());

  if (moduleHandle == Handle.init)
    throw new DllNotFoundException("Unable to load DLL '" ~ dllName ~ "'.");

  void* func = null;

  // '#' denotes an ordinal entry.
  if (entryPoint[0] == '#') {
    func = GetProcAddress(moduleHandle, cast(char*)std.conv.to!(ushort)(entryPoint[1 .. $]));
  }    
  else {
    func = GetProcAddress(moduleHandle, entryPoint.toStringz());
  }

  if (func == null) {
    CharSet linkType = charSet;
    if (charSet == CharSet.Auto)
      linkType = ((GetVersion() & 0x80000000) == 0) ? CharSet.Unicode : CharSet.Ansi;

    string entryPointName = entryPoint.idup ~ ((linkType == CharSet.Ansi) ? 'A' : 'W');

    func = GetProcAddress(moduleHandle, entryPointName.toStringz());

    if (func == null)
      throw new EntryPointNotFoundException("Unable to find an entry point named '" ~ entryPoint ~ "' in DLL '" ~ dllName ~ "'.");
  }

  return func;
}

struct DllImport(string dllName, string entryPoint, TFunction, CharSet charSet = CharSet.Auto) {

  static ReturnType!(TFunction) opCall(ParameterTypeTuple!(TFunction) args) {
    return (cast(TFunction)addressOfFunction(dllName, entryPoint, charSet))(args);
  }

}

extern(Windows):

alias DllImport!("kernel32.dll", "LCIDToLocaleName",
  int function(uint Locale, wchar* lpName, int cchName, uint dwFlags)) LCIDToLocaleName;

alias DllImport!("nlsmap.dll", "DownlevelLCIDToLocaleName",
  int function(uint Locale, wchar* lpName, int cchName, uint dwFlags)) DownlevelLCIDToLocaleName;

alias DllImport!("nlsdl.dll", "DownlevelGetParentLocaleName", 
  uint function(uint Locale, wchar* lpName, int cchName)) DownlevelGetParentLocaleName;

// XP
alias DllImport!("kernel32.dll", "GetGeoInfo", 
  int function(uint Location, uint GeoType, wchar* lpGeoData, int cchData, ushort LangId)) GetGeoInfo;

enum : uint {
  FIND_STARTSWITH = 0x00100000,
  FIND_ENDSWITH   = 0x00200000,
  FIND_FROMSTART  = 0x00400000,
  FIND_FROMEND    = 0x00800000
}

// Vista
alias DllImport!("kernel32.dll", "FindNLSString",
  int function(uint Locale, uint dwFindNLSStringFlags, in wchar* lpStringSource, int cchSource, in wchar* lpStringValue, int cchValue, int* pcchFound)) FindNLSString;

alias DllImport!("kernel32.dll", "GetThreadIOPendingFlag",
  int function(Handle hThread, int* lpIOIsPending)) GetThreadIOPendingFlag;

enum SYSTEM_INFORMATION_CLASS : uint {
  SystemProcessInformation = 5
}

struct SYSTEM_PROCESS_INFORMATION {
  int nextEntryOffset;
  uint numberOfThreads;
  long spareLi1;
  long spareLi2;
  long spareLi3;
  long createTime;
  long userTime;
  long kernelTime;
  ushort nameLength;
  ushort maximumNameLength;
  wchar* nameBuffer;
  int basePriority;
  uint uniqueProcessId;
}

enum {
  STATUS_INFO_LENGTH_MISMATCH = 0xC0000004
}

alias DllImport!("ntdll.dll", "NtQuerySystemInformation",
  int function(SYSTEM_INFORMATION_CLASS systemInformationClass, void* systemInformation, uint systemInformationLength, uint* returnLength)) NtQuerySystemInformation;

enum PROCESS_INFORMATION_CLASS : uint {
  ProcessBasicInformation = 0
}

struct PROCESS_BASIC_INFORMATION {
  void* reserved1;
  void* pebBaseAddress;
  void*[2] reserved2;
  uint uniqueProcessId;
  void* reserved3;
}

alias DllImport!("ntdll.dll", "NtQueryInformationProcess",
  int function(Handle processHandle, PROCESS_INFORMATION_CLASS processInformationClass, void* processInformation, uint processInformationLength, uint* returnLength)) NtQueryInformationProcess;

alias DllImport!("advapi32.dll", "CreateProcessWithLogonW",
  BOOL function(in wchar* lpUserName, in wchar* lpDomain, in wchar* lpPassword, uint dwLogonFlags, in wchar* lpApplicationName, in wchar* lpCommandLine, uint dwCreationFlags, void* lpEnvironment, in wchar* lpCurrentDirectory, STARTUPINFOW* lpStartupInfo, PROCESS_INFORMATION* lpProcessInformation)) CreateProcessWithLogonW;
