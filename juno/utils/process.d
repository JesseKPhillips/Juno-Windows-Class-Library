module juno.utils.process;

import juno.base.core,
  juno.base.string,
  juno.base.threading,
  juno.base.native,
  juno.com.core,
  juno.security.crypto;
static import juno.io.path;
import std.c.stdlib : malloc, realloc, free;

debug import std.stdio : writefln;

private extern(C) int _wcsicmp(in wchar*, in wchar*);

private class ProcessInfo {

  uint processId;
  string processName;

}

class ProcessStart {

  string fileName;
  string arguments;
  string userName;
  string password;
  string domain;
  bool useShellExecute = true;

  this() {
  }

  this(string fileName, string arguments) {
    this.fileName = fileName;
    this.arguments = arguments;
  }

}

class Process {

  private Optional!(Handle) handle_;
  private string machineName_;
  private bool isRemote_;
  private Optional!(uint) id_;
  private string processName_;
  private ProcessInfo processInfo_;

  // Process.start parameters
  ProcessStart start_;

  this() {
    machineName_ = ".";
  }

  private this(string machineName, bool isRemote, uint id, ProcessInfo processInfo) {
    machineName_ = machineName;
    isRemote_ = isRemote;
    id_ = id;
    processInfo_ = processInfo;
  }

  ~this() {
    close();
  }

  final void close() {
    if (handle_.hasValue && (handle_.value != Handle.init)) {
      CloseHandle(handle_.value);
      // Re-initialize so handle_.hasValue returns false.
      //handle_ = (Optional!(Handle)).init;
    }
    processInfo_ = null;
  }

  static Process start(string fileName) {
    return start(fileName, null);
  }

  static Process start(string fileName, string arguments) {
    return start(new ProcessStart(fileName, arguments));
  }

  static Process start(ProcessStart start) {
    auto process = new Process;
    process.start_ = start;
    if (process.start())
      return process;
    return null;
  }

  final bool start() {
    close();

    if (start_.useShellExecute) {
      SHELLEXECUTEINFO sei;
      sei.fMask = SEE_MASK_NOCLOSEPROCESS | SEE_MASK_FLAG_NO_UI | SEE_MASK_FLAG_DDEWAIT;
      sei.nShow = /*SW_SHOWNORMAL*/ 1;

      sei.lpFile = start_.fileName.toUtf16z();
      sei.lpParameters = start_.arguments.toUtf16z();

      if (!ShellExecuteEx(sei))
        throw new Win32Exception;

      if (sei.hProcess != Handle.init) {
        handle_ = sei.hProcess;
        return true;
      }

      return false;
    }

    STARTUPINFO startupInfo;
    PROCESS_INFORMATION processInfo;
    Handle processHandle;

    string commandLine = "\"" ~ start_.fileName ~ "\"";
    if (start_.arguments != null)
      commandLine ~= " " ~ start_.arguments;
    auto pCommandLine = commandLine.toUtf16z();
    auto pWorkingDirectory = juno.io.path.currentDirectory().toUtf16z();
    uint creationFlags = 0;

    /*if (start_.userName != null) {
      wchar* pPassword;
      if (start_.password !is null)
        pPassword = secureStringToUnicode(start_.password);

      uint logonFlags = 0;
      if (!CreateProcessWithLogonW(start_.userName.toUtf16z(), pPassword, start_.domain.toUtf16z(), logonFlags, null, pCommandLine, creationFlags, null, pWorkingDirectory, &startupInfo, &processInfo))
        throw new Win32Exception;

      processHandle = processInfo.hProcess;
      // Not interested in the returned thread.
      CloseHandle(processInfo.hThread);

      if (pPassword != null)
        CoTaskMemFree(pPassword);
    }
    else*/ {
      if (!CreateProcess(null, pCommandLine, null, null, TRUE, creationFlags, null, pWorkingDirectory, startupInfo, processInfo))
        throw new Win32Exception;

      processHandle = processInfo.hProcess;
      // Not interested in the returned thread.
      CloseHandle(processInfo.hThread);
    }

    if (processHandle != Handle.init) {
      handle_ = processHandle;
      id_ = processInfo.dwProcessId;
    }
    return false;
  }

  final void kill() {
    ensureProcessId();

    Handle handle;
    if (!handle_.hasValue) {
      handle = OpenProcess(PROCESS_TERMINATE, FALSE, id_.value);
      if (handle_.value == Handle.init)
        throw new Win32Exception;
    }
    else {
      /*Handle waitHandle;
      DuplicateHandle(GetCurrentProcess(), handle_.value, GetCurrentProcess(), waitHandle, 0, FALSE, DUPLICATE_SAME_ACCESS);
      WaitForSingleObjectEx(waitHandle, 0, 1);
      CloseHandle(waitHandle);*/

      handle = handle_.value;
    }
    if (!TerminateProcess(handle, -1))
      throw new Win32Exception;
    CloseHandle(handle);
  }

  static Process current() {
    return new Process(".", false, GetCurrentProcessId(), null);
  }

  static Process[] getProcesses() {
    auto processInfos = getProcessInfos();
    auto processes = new Process[processInfos.length];

    foreach (i, processInfo; processInfos)
      processes[i] = new Process(".", false, processInfo.processId, processInfo);

    return processes;
  }

  private void ensureProcessId() {
    if (!id_.hasValue) {
      PROCESS_BASIC_INFORMATION info;
      int status = NtQueryInformationProcess(handle_.value, PROCESS_INFORMATION_CLASS.ProcessBasicInformation, &info, info.sizeof, null);
      if (status != 0)
        throw new InvalidOperationException;

      id_ = info.uniqueProcessId;
    }
  }

  private void ensureProcessInfo() {
    ensureProcessId();

    if (processInfo_ is null) {
      auto processInfos = getProcessInfos();
      foreach (processInfo; processInfos) {
        if (processInfo.processId == id_.value) {
          processInfo_ = processInfo;
          break;
        }
      }
    }
  }

  final Handle handle() {
    ensureProcessId();

    if (!handle_.hasValue) {
      handle_ = OpenProcess(PROCESS_ALL_ACCESS, FALSE, id_.value);
      if (handle_.value == Handle.init)
        throw new Win32Exception;
    }
    return handle_.value;
  }

  final string processName() {
    if (processName_ == null) {
      ensureProcessInfo();
      return processInfo_.processName;
    }
    return processName_;
  }

  final string machineName() {
    return machineName_;
  }

  final uint id() {
    ensureProcessId();
    return id_.value;
  }

  private static ProcessInfo[] getProcessInfos() {

    string getProcessName(wchar* name, uint length) {
      wchar* str = name, period = name, slash = name;

      int i;
      while (*str != 0) {
        if (*str == '.') period = str;
        if (*str == '\\') slash = str;
        str++, i++;
        if (i >= length)
          break;
      }

      if (period == name) period = str;
      else if (_wcsicmp(period, ".exe") != 0) period = str;

      if (*slash == '\\') slash++;

      return toUtf8(slash, 0, period - slash);
    }

    ProcessInfo[uint] processInfos;

    uint bufferSize = 128 * 1024;
    uint neededSize;
    ubyte* buffer;

    int status;
    do {
      buffer = cast(ubyte*)realloc(buffer, bufferSize);
      status = NtQuerySystemInformation(SYSTEM_INFORMATION_CLASS.SystemProcessInformation, buffer, bufferSize, &neededSize);
      if (status == STATUS_INFO_LENGTH_MISMATCH)
        bufferSize = neededSize + 10 * 1024;
    } while (status == STATUS_INFO_LENGTH_MISMATCH);
    if (status < 0)
      throw new InvalidOperationException;

    scope(exit) free(buffer);

    int offset;
    while (true) {
      auto pProcessInfo = cast(SYSTEM_PROCESS_INFORMATION*)(buffer + offset);

      auto processInfo = new ProcessInfo;
      processInfo.processId = cast(uint)pProcessInfo.uniqueProcessId;
      if (pProcessInfo.nameBuffer != null)
        processInfo.processName = getProcessName(pProcessInfo.nameBuffer, pProcessInfo.nameLength / 2);

      processInfos[processInfo.processId] = processInfo;

      if (pProcessInfo.nextEntryOffset == 0)
        break;
      offset += pProcessInfo.nextEntryOffset;
    }

    return processInfos.values;
  }

}

/+enum ServiceControllerStatus {
  Stopped         = SERVICE_STOPPED,
  StartPending    = SERVICE_START_PENDING,
  StopPending     = SERVICE_STOP_PENDING,
  Running         = SERVICE_RUNNING,
  ContinuePending = SERVICE_CONTINUE_PENDING,
  PausePending    = SERVICE_PAUSE_PENDING,
  Paused          = SERVICE_PAUSED
}

class ServiceController {

  private Handle serviceManagerHandle_;
  private string name_;
  private string machineName_ = ".";
  private Optional!(ServiceControllerStatus) status_;

  this() {
  }

  this(string name) {
    name_ = name;
  }

  this(string name, string machineName) {
    name_ = name;
    machineName_ = machineName;
  }

  final void close() {
    if (serviceManagerHandle_ != Handle.init) {
      CloseServiceHandle(serviceManagerHandle_);
      serviceManagerHandle_ = Handle.init;
    }
  }

  final void start(string[] args = null) {
    ensureServiceManagerHandle();

    Handle serviceHandle = getServiceHandle(SERVICE_START);
    scope(exit) CloseServiceHandle(serviceHandle);

    auto pArgs = cast(wchar**)LocalAlloc(LMEM_FIXED, args.length * (wchar*).sizeof);
    foreach (i, arg; args)
      pArgs[i] = arg.toUtf16z();
    scope(exit) LocalFree(pArgs);

    if (StartService(serviceHandle, args.length, pArgs) != TRUE)
      throw new Win32Exception;
  }

  final void pause() {
    ensureServiceManagerHandle();

    Handle serviceHandle = getServiceHandle(SERVICE_PAUSE_CONTINUE);
    scope(exit) CloseServiceHandle(serviceHandle);

    SERVICE_STATUS status;
    if (ControlService(serviceHandle, SERVICE_CONTROL_PAUSE, status) != TRUE)
      throw new Win32Exception;
  }

  final void stop() {
    ensureServiceManagerHandle();

    Handle serviceHandle = getServiceHandle(SERVICE_STOP);
    scope(exit) CloseServiceHandle(serviceHandle);

    SERVICE_STATUS status;
    if (ControlService(serviceHandle, SERVICE_CONTROL_STOP, status) != TRUE)
      throw new Win32Exception;
  }

  final void refresh() {
    status_ = (Optional!(ServiceControllerStatus)).init;
  }

  final void waitForStatus(ServiceControllerStatus desiredStatus) {
    refresh();
    while (status != desiredStatus) {
      sleep(250);
      refresh();
    }
  }

  final string serviceName() {
    return name_;
  }

  final ServiceControllerStatus status() {
    if (!status_.hasValue) {
      ensureServiceManagerHandle();

      Handle serviceHandle = getServiceHandle(SERVICE_QUERY_STATUS);
      scope(exit) CloseServiceHandle(serviceHandle);

      SERVICE_STATUS status;
      if (QueryServiceStatus(serviceHandle, status) != TRUE)
        throw new Win32Exception;
      status_ = cast(ServiceControllerStatus)status.dwCurrentState;
    }
    return status_.value;
  }

  private void ensureServiceManagerHandle() {
    if (serviceManagerHandle_ == Handle.init) {
      if (machineName_ == "." || machineName_ == null)
        serviceManagerHandle_ = OpenSCManager(null, null, SC_MANAGER_CONNECT);
      else
        serviceManagerHandle_ = OpenSCManager(machineName_.toUtf16z(), null, SC_MANAGER_CONNECT);

      if (serviceManagerHandle_ == Handle.init)
        throw new Win32Exception;
    }
  }

  private Handle getServiceHandle(uint access) {
    ensureServiceManagerHandle();
    Handle serviceHandle = OpenService(serviceManagerHandle_, serviceName().toUtf16z(), access);
    if (serviceHandle == Handle.init)
      throw new Win32Exception;
    return serviceHandle;
  }

}+/