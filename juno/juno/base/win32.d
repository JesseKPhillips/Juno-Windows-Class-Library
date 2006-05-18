module juno.base.win32;

private import juno.base.core;

pragma(lib, "advapi32.lib");

extern (Windows) :

enum : uint {
  CREATE_SUSPENDED = 0x00000004
}

enum {
  THREAD_PRIORITY_LOWEST = -2,
  THREAD_PRIORITY_BELOW_NORMAL = -1,
  THREAD_PRIORITY_NORMAL = 0,
  THREAD_PRIORITY_ABOVE_NORMAL = 1,
  THREAD_PRIORITY_HIGHEST = 2
}

enum : uint {
  DUPLICATE_SAME_ACCESS = 0x00000002
}

enum : uint {
  FILE_ATTRIBUTE_DIRECTORY  = 0x00000010
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

alias uint function(void* lpThreadParameter) PTHREAD_START_ROUTINE;

struct FILETIME {
  uint dwLowDateTime;
  uint dwHighDateTime;
}

struct WIN32_FILE_ATTRIBUTE_DATA {
  uint dwFileAttributes;
  FILETIME ftCreationTime;
  FILETIME ftLastAccessTime;
  FILETIME ftLastWriteTime;
  uint nFileSizeHigh;
  uint nFileSizeLow;
}

Handle CreateThread(void* lpThreadAttributes, size_t dwStackSize, PTHREAD_START_ROUTINE lpStartAddress, void* lpParameter, uint dwCreationFlags, uint* lpThreadId);
uint ResumeThread(Handle hThread);
bool SetThreadPriority(Handle hThread, int nPriority);
Handle GetCurrentProcess();
Handle GetCurrentThread();
uint GetCurrentThreadId();
bool DuplicateHandle(Handle hSourceProcessHandle, Handle hSourceHandle, Handle hTargetProcessHandle, out Handle lpTargetHandle, uint dwDesiredAccess, bool bInheritHandle, uint dwOptions);
bool CloseHandle(Handle hObject);
uint FormatMessageW(uint dwFlags, void* lpSource, uint dwMessageId, uint dwLanguageId, wchar* lpBuffer, uint nSize, void** Arguments);

uint TlsAlloc();
void* TlsGetValue(uint dwTlsIndex);
bool TlsSetValue(uint dwTlsIndex, void* lpTlsValue);
bool TlsFree(uint dwTlsIndex);

uint GetLastError();
bool GetFileAttributesExW(wchar* lpFileName, int fInfoLevelId, out WIN32_FILE_ATTRIBUTE_DATA lpFileInformation);
int InterlockedIncrement(inout int lpAddend);
int InterlockedDecrement(inout int lpAddend);

int RegOpenKeyExW(Handle hKey, wchar* lpSubKey, uint ulOptions, uint samDesired, out Handle phkResult);
int RegSetValueExW(Handle hKey, wchar* lpValueName, uint reserved, uint dwType, void* lpData, uint cbData);
int RegQueryValueExW(Handle hKey, wchar* lpValueName, uint* lpReserved, out uint lpType, void* lpData, inout uint lpcbData);
int RegQueryInfoKeyW(Handle hKey, wchar* lpClass, uint* lpcchClass, uint* lpReserved, uint* lpcSubKeys, uint* lpcbMaxSubKeyLen, uint* lpcbMaxClassLen, uint* lpcValues, uint* lpcbMaxValueNameLen, uint* lpcbMaxValueLen, uint* lpcbSecurityDescriptor, FILETIME* lpftLastWriteTime);
int RegCloseKey(Handle hKey);
int RegEnumKeyExW(Handle hKey, uint dwIndex, wchar* lpName, inout uint lpcchName, uint* lpReserved, wchar* lpClass, uint* lpcchClass, FILETIME* lpftLastWriteTime);