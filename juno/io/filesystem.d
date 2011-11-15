module juno.io.filesystem;

import juno.base.core,
  juno.base.string,
  juno.base.events,
  juno.base.native,
  juno.locale.time,
  juno.io.core,
  juno.io.path;
version(D_Version2) {
  import core.thread;
}
else {
  import std.thread;
}
static import std.path;

/// Returns an array of strings containing the names of the logical drives on the current computer.
string[] logicalDrives() {
  uint drives = GetLogicalDrives();
  if (drives == 0)
    ioError(GetLastError(), null);

  char[] root = [ 'A', ':', '\\' ];

  string[] ret;
  while (drives != 0) {
    if ((drives & 1) != 0)
      ret ~= cast(string)root.dup;
    drives >>>= 1;
    root[0]++;
  }
  return ret;
}

/// Returns the volume and/or root information for the specified _path.
string getDirectoryRoot(string path) {
  string fullPath = getFullPath(path);
  return getDirectoryRootImpl(fullPath);
}

private string getDirectoryRootImpl(string path) {
  if (path == null)
    return null;
  return path[0 .. getRootLength(path)];
}

/// Determines whether the specified _path refers to an existing directory on disk.
bool directoryExists(string path) {
  if (path == null)
    return false;
  string fullPath = getFullPath(path);
  return directoryExistsImpl(path);
}

private bool directoryExistsImpl(string path) {
  WIN32_FILE_ATTRIBUTE_DATA data;
  if (GetFileAttributesEx(path.toUtf16z(), 0, data) != 0)
    return (data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
  return false;
}

/// Creates all the directories in the specified _path.
void createDirectory(string path) {
  string fullPath = getFullPath(path);

  int len = fullPath.length;
  if (len >= 2 && (fullPath[len - 1] == std.path.sep[0] || fullPath[len - 1] == std.path.altsep[0]))
    len--;

  string[] list;
  bool pathExists;

  int rootLen = getRootLength(fullPath);
  if (len > rootLen) {
    for (int i = len - 1; i >= rootLen; i--) {
      string dir = fullPath[0 .. i + 1];

      if (!directoryExistsImpl(dir))
        list ~= dir;
      else
        pathExists = true;
      while (i > rootLen && fullPath[i] != std.path.sep[0] && fullPath[i] != std.path.altsep[0]) i--;
    }
  }

  bool result = true;
  uint firstError;
  string errorPath;

  foreach_reverse (name; list) {
    result = CreateDirectory(name.toUtf16z(), null) != 0;
    if (!result && firstError == 0) {
      uint lastError = GetLastError();
      if (lastError != ERROR_ALREADY_EXISTS) {
        firstError = lastError;
      }
      else {
        if (fileExistsImpl(name)) {
          firstError = lastError;
          errorPath = name;
        }
      }
    }
  }

  if (list.length == 0 && !pathExists) {
    string root = getDirectoryRoot(fullPath);
    if (!directoryExistsImpl(root))
      ioError(ERROR_PATH_NOT_FOUND, root);
    return;
  }

  if (!result && firstError != 0)
    ioError(firstError, errorPath);
}

/// Specifies whether a file or directory should be deleted permanently or placed in the Recycle Bin.
enum DeleteOption {
  DeletePermanently, /// Delete the file or directory permanently. Default.
  AllowUndo          /// Allow the delete operation to be undone.
}

/// Deletes the directory from the specified _path.
void deleteDirectory(string path, DeleteOption option = DeleteOption.DeletePermanently) {
  string fullPath = getFullPath(path);

  /*if (RemoveDirectory(path.toUtf16z()) == 0) {
    uint errorCode = GetLastError();
    ioError(errorCode, path);
  }*/

  SHFILEOPSTRUCT fileOp;
  fileOp.wFunc = FO_DELETE;
  fileOp.fFlags = FOF_SILENT | FOF_NOCONFIRMATION | FOF_NOERRORUI;
  if (option == DeleteOption.AllowUndo)
    fileOp.fFlags |= FOF_ALLOWUNDO;
  fileOp.pFrom = (fullPath ~ '\0').toUtf16z();

  int errorCode = SHFileOperation(fileOp);
  SHChangeNotify(SHCNE_DISKEVENTS, SHCNF_DWORD, null, null);
  if (errorCode != 0 && errorCode != ERROR_FILE_NOT_FOUND)
    ioError(errorCode, fullPath);
}

/// Moves a file or a directory and its contents to a new location.
void moveDirectory(string sourceDirName, string destDirName) {
  string fullSourceDirName = getFullPath(sourceDirName);
  string fullDestDirName = getFullPath(destDirName);

  if (MoveFile(fullSourceDirName.toUtf16z(), fullDestDirName.toUtf16z()) == 0) {
    uint errorCode = GetLastError();
    if (errorCode == ERROR_FILE_NOT_FOUND) {
      ioError(ERROR_PATH_NOT_FOUND, fullSourceDirName);
    }
    ioError(errorCode, null);
  }
}

/// Returns the creation date and time of a directory or file.
DateTime getCreationTime(string path) {
  string fullPath = getFullPath(path);

  WIN32_FILE_ATTRIBUTE_DATA data;
  if (!GetFileAttributesEx(fullPath.toUtf16z(), 0, data)) {
    uint errorCode = GetLastError();
    if (errorCode != ERROR_FILE_NOT_FOUND)
      ioError(errorCode, fullPath);
  }

  return DateTime.fromFileTime((cast(long)data.ftCreationTime.dwHighDateTime << 32) | data.ftCreationTime.dwLowDateTime);
}

/// Returns the date and time a directory or file was last accessed.
DateTime getLastAccessTime(string path) {
  string fullPath = getFullPath(path);

  WIN32_FILE_ATTRIBUTE_DATA data;
  if (!GetFileAttributesEx(fullPath.toUtf16z(), 0, data)) {
    uint errorCode = GetLastError();
    if (errorCode != ERROR_FILE_NOT_FOUND)
      ioError(errorCode, fullPath);
  }

  return DateTime.fromFileTime((cast(long)data.ftLastAccessTime.dwHighDateTime << 32) | data.ftLastAccessTime.dwLowDateTime);
}

/// Returns the date and time a directory or file was last written to.
DateTime getLastWriteTime(string path) {
  string fullPath = getFullPath(path);

  WIN32_FILE_ATTRIBUTE_DATA data;
  if (!GetFileAttributesEx(fullPath.toUtf16z(), 0, data)) {
    uint errorCode = GetLastError();
    if (errorCode != ERROR_FILE_NOT_FOUND)
      ioError(errorCode, fullPath);
  }

  return DateTime.fromFileTime((cast(long)data.ftLastWriteTime.dwHighDateTime << 32) | data.ftLastWriteTime.dwLowDateTime);
}

/// Returns the attributes of the file on the specified _path.
FileAttributes getFileAttributes(string path) {
  string fullPath = getFullPath(path);

  WIN32_FILE_ATTRIBUTE_DATA data;
  if (!GetFileAttributesEx(fullPath.toUtf16z(), 0, data))
    ioError(GetLastError(), fullPath);
  return cast(FileAttributes)data.dwFileAttributes;
}

/// Determines whether the specified file exists.
bool fileExists(string path) {
  if (path == null)
    return false;

  string fullPath = getFullPath(path);
  return fileExistsImpl(fullPath);
}

private bool fileExistsImpl(string path) {
  WIN32_FILE_ATTRIBUTE_DATA data;
  if (GetFileAttributesEx(path.toUtf16z(), 0, data) != 0)
    return (data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == 0;
  return false;
}

/// Deletes the specified file.
void deleteFile(string path, DeleteOption option = DeleteOption.DeletePermanently) {
  string fullPath = getFullPath(path);

  /*if (DeleteFile(fullPath.toUtf16z()) == 0) {
    uint errorCode = GetLastError();
    if (errorCode != ERROR_FILE_NOT_FOUND)
      ioError(errorCode, fullPath);
  }*/
  SHFILEOPSTRUCT fileOp;
  fileOp.wFunc = FO_DELETE;
  fileOp.fFlags = FOF_SILENT | FOF_NOCONFIRMATION | FOF_NOERRORUI;
  if (option == DeleteOption.AllowUndo)
    fileOp.fFlags |= FOF_ALLOWUNDO;
  fileOp.pFrom = (fullPath ~ '\0').toUtf16z();

  int errorCode = SHFileOperation(fileOp);
  SHChangeNotify(SHCNE_DISKEVENTS, SHCNF_DWORD, null, null);
  if (errorCode != 0 && errorCode != ERROR_FILE_NOT_FOUND)
    ioError(errorCode, fullPath);
}

/// Moves the specified file to a new location.
void moveFile(string sourceFileName, string destFileName) {
  string fullSourceFileName = getFullPath(sourceFileName);
  string fullDestFileName = getFullPath(destFileName);

  if (!fileExistsImpl(fullSourceFileName))
    ioError(ERROR_FILE_NOT_FOUND, fullSourceFileName);

  if (MoveFile(fullSourceFileName.toUtf16z(), fullDestFileName.toUtf16z()) == 0)
    ioError(GetLastError(), null);
}

/// Copies an existing file to a new file, with the option to _overwrite a file of the same name.
void copyFile(string sourceFileName, string destFileName, bool overwrite = false) {
  string fullSourceFileName = getFullPath(sourceFileName);
  string fullDestFileName = getFullPath(destFileName);

  if (CopyFile(fullSourceFileName.toUtf16z(), fullDestFileName.toUtf16z(), overwrite ? 0 : 1) == 0) {
    uint errorCode = GetLastError();
    ioError(errorCode, destFileName);
  }
}

/// Replaces the contents of the specified file with the contents of another, deleting the original, and creating a backup of the replaced file and optionally ignores merge errors.
void replaceFile(string sourceFileName, string destFileName, string backupFileName, bool ignoreMergeErrors = false) {
  string fullSourceFileName = getFullPath(sourceFileName);
  string fullDestFileName = getFullPath(destFileName);
  string fullBackupFileName;
  if (backupFileName != null)
    fullBackupFileName = getFullPath(backupFileName);

  uint flags = REPLACEFILE_WRITE_THROUGH;
  if (ignoreMergeErrors)
    flags |= REPLACEFILE_IGNORE_MERGE_ERRORS;

  if (ReplaceFile(fullDestFileName.toUtf16z(), fullSourceFileName.toUtf16z(), fullBackupFileName.toUtf16z(), flags, null, null) == 0)
    ioError(GetLastError(), null);
}

/// Encrypts a file so that only the user account used to encrypt the file can decrypt it.
void encryptFile(string path) {
  string fullPath = getFullPath(path);

  if (EncryptFile(fullPath.toUtf16z()) == 0) {
    uint errorCode = GetLastError();
    ioError(errorCode, fullPath);
  }
}

/// Decrypts a file that was encrypted by the current user account using the encryptFile method.
void decryptFile(string path) {
  string fullPath = getFullPath(path);

  if (DecryptFile(fullPath.toUtf16z(), 0) == 0) {
    uint errorCode = GetLastError();
    ioError(errorCode, fullPath);
  }
}

/**
 * Examples:
 * Converts a numeric value into a human-readable string representing the number expressed in bytes, kilobytes, megabytes or gigabytes.
 * ---
 * string[] orders = [ "GB", "MB", "KB", " bytes" ];
 * const real scale = 1024;
 * auto max = std.math.pow(scale, orders.length - 1);
 *
 * string drive = r"C:\";
 * auto freeSpace = getAvailableFreeSpace(drive);
 * string s = "0 bytes";
 *
 * foreach (order; orders) {
 *   if (freeSpace > max) {
 *     s = std.string.format("%.2f%s", cast(real)freeSpace / max, order);
 *     break;
 *   }
 *   max /= scale;
 * }
 *
 * std.stdio.writefln("Available free space on drive %s: %s", drive, s);
 * ---
 */
ulong getAvailableFreeSpace(string driveName) {
  string name = getPathRoot(driveName);

  ulong freeSpace, totalSize, totalFreeSpace;
  if (!GetDiskFreeSpaceEx(name.toUtf16z(), freeSpace, totalSize, totalFreeSpace)) {
    uint errorCode = GetLastError();
    ioError(errorCode, name);
  }
  return freeSpace;
}

/**
 */
ulong getTotalSize(string driveName) {
  string name = getPathRoot(driveName);

  ulong freeSpace, totalSize, totalFreeSpace;
  if (!GetDiskFreeSpaceEx(name.toUtf16z(), freeSpace, totalSize, totalFreeSpace)) {
    uint errorCode = GetLastError();
    ioError(errorCode, name);
  }
  return totalSize;
}

/**
 */
ulong getTotalFreeSpace(string driveName) {
  string name = getPathRoot(driveName);

  ulong freeSpace, totalSize, totalFreeSpace;
  if (!GetDiskFreeSpaceEx(name.toUtf16z(), freeSpace, totalSize, totalFreeSpace)) {
    uint errorCode = GetLastError();
    ioError(errorCode, name);
  }
  return totalFreeSpace;
}

/**
 */
string getVolumeLabel(string driveName) {
  string name = getPathRoot(driveName);

  wchar[MAX_PATH + 1] volumeBuffer;
  uint serialNumber, maxComponentLength, fileSystemFlags;
  if (!GetVolumeInformation(name.toUtf16z(), volumeBuffer.ptr, volumeBuffer.length, serialNumber, maxComponentLength, fileSystemFlags, null, 0)) {
    uint errorCode = GetLastError();
    ioError(errorCode, name);
  }
  return toUtf8(volumeBuffer.ptr);
}

/**
 */
void setVolumeLabel(string driveName, string volumeLabel) {
  string name = getPathRoot(driveName);

  if (!SetVolumeLabel(name.toUtf16z(), volumeLabel.toUtf16z())) {
    uint errorCode = GetLastError();
    ioError(errorCode, name);
  }
}

/**
 */
enum NotifyFilters {
  FileName      = FILE_NOTIFY_CHANGE_FILE_NAME,
  DirectoryName = FILE_NOTIFY_CHANGE_DIR_NAME,
  Attributes    = FILE_NOTIFY_CHANGE_ATTRIBUTES,
  Size          = FILE_NOTIFY_CHANGE_SIZE,
  LastWrite     = FILE_NOTIFY_CHANGE_LAST_WRITE,
  LastAccess    = FILE_NOTIFY_CHANGE_LAST_ACCESS,
  CreationTime  = FILE_NOTIFY_CHANGE_CREATION,
  Security      = FILE_NOTIFY_CHANGE_SECURITY
}

/**
 */
enum WatcherChange {
  Created = 0x1,
  Deleted = 0x2,
  Changed = 0x4,
  Renamed = 0x8,
  All     = Created | Deleted | Changed | Renamed
}

/**
 */
class FileSystemEventArgs : EventArgs {

  private WatcherChange change_;
  private string name_;
  private string fullPath_;

  this(WatcherChange change, string directory, string name) {
    change_ = change;
    name_ = name;
    if (directory[$ - 1] != '\\')
      directory ~= '\\';
    fullPath_ = directory ~ name;
  }

  WatcherChange change() {
    return change_;
  }

  string name() {
    return name_;
  }

  string fullPath() {
    return fullPath_;
  }

}

/**
 */
alias TEventHandler!(FileSystemEventArgs) FileSystemEventHandler;

/**
 */
class RenamedEventArgs : FileSystemEventArgs {

  private string oldName_;
  private string oldFullPath_;

  this(WatcherChange change, string directory, string name, string oldName) {
    super(change, directory, name);

    if (directory[$ - 1] != '\\')
      directory ~= '\\';
    oldName_ = oldName;
    oldFullPath_ = directory ~ oldName;
  }

  string oldName() {
    return oldName_;
  }

  string oldFullPath() {
    return oldFullPath_;
  }

}

/**
 */
alias TEventHandler!(RenamedEventArgs) RenamedEventHandler;

/**
 */
class ErrorEventArgs : EventArgs {

  private Exception exception_;

  this(Exception exception) {
    exception_ = exception;
  }

  Exception getException() {
    return exception_;
  }

}

/**
 */
alias TEventHandler!(ErrorEventArgs) ErrorEventHandler;

alias void delegate(uint errorCode, uint numBytes, OVERLAPPED* overlapped) IOCompletionCallback;

// Wraps a native OVERLAPPED and associates a callback with each object.
private class Overlapped {

  static Overlapped[OVERLAPPED*] overlappedCache;

  IOCompletionCallback callback;
  OVERLAPPED* overlapped;

  static ~this() {
    overlappedCache = null;
  }

  OVERLAPPED* pack(IOCompletionCallback iocb) {
    callback = iocb;

    overlapped = new OVERLAPPED;
    overlappedCache[overlapped] = this;
    return overlapped;
  }

  static Overlapped unpack(OVERLAPPED* lpOverlapped) {
    return getOverlapped(lpOverlapped);
  }

  static void free(OVERLAPPED* lpOverlapped) {
    auto overlapped = getOverlapped(lpOverlapped);
    overlappedCache.remove(lpOverlapped);
    delete lpOverlapped;
    overlapped.overlapped = null;
  }

  static Overlapped getOverlapped(OVERLAPPED* lpOverlapped) {
    if (auto overlapped = lpOverlapped in overlappedCache)
      return *overlapped;
    return null;
  }

}

extern(Windows)
private void bindCompletionCallback(uint errorCode, uint numBytes, OVERLAPPED* lpOverlapped) {
  //debug writefln("bindCompletionCallback");
  auto overlapped = Overlapped.getOverlapped(lpOverlapped);
  overlapped.callback(errorCode, numBytes, overlapped.overlapped);
}

/**
 * Listens to file system change notifications and raises events when a directory, or file in a directory, changes.
 * Examples:
 * ---
 * import juno.io.filesystem, std.stdio;
 *
 * void main() {
 *   // Create a Watcher object and set its properties.
 *   scope watcher = new Watcher;
 *   watcher.path = r"C:\";
 *
 *   // Add event handlers.
 *   watcher.created += (Object, FileSystemEventArgs e) {
 *     writefln("File %s changed", e.fullPath);
 *   };
 *   watcher.deleted += (Object, FileSystemEventArgs e) {
 *     writefln("File %s deleted", e.fullPath);
 *   };
 *   watcher.changed += (Object, FileSystemEventArgs e) {
 *     writefln("File %s changed", e.fullPath);
 *   };
 *   watcher.renamed += (Object, RenamedEventArgs e) {
 *     writefln("File %s renamed to %s", e.oldFullPath, e.fullPath);
 *   };
 *
 *   // Start listening.
 *   watcher.enableEvents = true;
 *
 *   writefln("Press 'q' to quit.");
 *   while (std.c.stdio.getch() != 'q') {
 *   }
 * }
 * ---
 */
class Watcher {

  private string directory_;
  private string filter_ = "*";
  private bool includeSubDirs_;
  private NotifyFilters notifyFilters_ = NotifyFilters.FileName | NotifyFilters.DirectoryName | NotifyFilters.LastWrite;
  private Handle directoryHandle_;
  private uint bufferSize_ = 8192;
  private bool enabled_;
  private bool stopWatching_;
  private static Handle completionPort_;
  private static int completionPortThreadCount_;

  ///
  FileSystemEventHandler created;
  ///
  FileSystemEventHandler deleted;
  ///
  FileSystemEventHandler changed;
  ///
  RenamedEventHandler renamed;
  ///
  ErrorEventHandler error;

  static ~this() {
    if (completionPort_ != Handle.init)
      CloseHandle(completionPort_);
  }

  /**
   */
  this(string path = null, string filter = "*") {
    directory_ = path;
    filter_ = filter;
  }

  ~this() {
    stopEvents();
    created.clear();
    deleted.clear();
    changed.clear();
    renamed.clear();
    error.clear();
  }

  /**
   */
  final void bufferSize(uint value) {
    if (bufferSize_ != value) {
      if (value < 4096)
        value = 4096;

      bufferSize_ = value;
      restart();
    }
  }
  /// ditto
  final uint bufferSize() {
    return bufferSize_;
  }

  /**
   */
  final void path(string value) {
    if (std.string.icmp(directory_, value) != 0) {
      directory_ = value;
      restart();
    }
  }
  /// ditto
  final string path() {
    return directory_;
  }

  /**
   */
  final void filter(string value) {
    if (std.string.icmp(filter_, value) != 0)
      filter_ = value;
  }
  /// ditto
  final string filter() {
    return filter_;
  }

  /**
   */
  final void notifyFilters(NotifyFilters value) {
    if (notifyFilters_ != value) {
      notifyFilters_ = value;
      restart();
    }
  }
  /// ditto
  final NotifyFilters notifyFilters() {
    return notifyFilters_;
  }

  /**
   */
  final void enableEvents(bool value) {
    if (enabled_ != value) {
      enabled_ = value;

      if (enabled_)
        startEvents();
      else
        stopEvents();
    }
  }
  final bool enableEvents() {
    return enabled_;
  }

  /**
   */
  protected void onCreated(FileSystemEventArgs e) {
    if (!created.isEmpty)
      created(this, e);
  }

  /**
   */
  protected void onDeleted(FileSystemEventArgs e) {
    if (!deleted.isEmpty)
      deleted(this, e);
  }

  /**
   */
  protected void onChanged(FileSystemEventArgs e) {
    if (!changed.isEmpty)
      changed(this, e);
  }

  /**
   */
  protected void onRenamed(RenamedEventArgs e) {
    if (!renamed.isEmpty)
      renamed(this, e);
  }

  /**
   */
  protected void onError(ErrorEventArgs e) {
    if (!error.isEmpty)
      error(this, e);
  }

  private void startEvents() {
    if (!isHandleInvalid)
      return;

    stopWatching_ = false;

    directoryHandle_ = CreateFile(
      directory_.toUtf16z(), 
      FILE_LIST_DIRECTORY, 
      FILE_SHARE_READ | FILE_SHARE_DELETE | FILE_SHARE_WRITE, 
      null, 
      OPEN_EXISTING,
      FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OVERLAPPED/**/,
      Handle.init);
    if (isHandleInvalid)
      throw new FileNotFoundException("Unable to find the specified file.", directory_);

    auto completionPortThread = new Thread({
      uint errorCode;
      uint numBytes;
      uint key;
      OVERLAPPED* overlapped;

      while (true) {
        errorCode = 0;
        if (!GetQueuedCompletionStatus(completionPort_, numBytes, key, overlapped, 15000))
          errorCode = GetLastError();

        if (errorCode == juno.base.native.WAIT_TIMEOUT) {
          BOOL isIOPending;
          /*if (!GetThreadIOPendingFlag(GetCurrentThread(), &isIOPending))
            isIOPending = FALSE;*/
          if (!isIOPending)
            break;
        }

        if (overlapped != null && key != 0) {
          (cast(LPOVERLAPPED_COMPLETION_ROUTINE)key)(errorCode, numBytes, overlapped);
        }
      }
      InterlockedDecrement(completionPortThreadCount_);
      version(D_Version2) {}
      else {
        return 0;
      }
    });
    InterlockedIncrement(completionPortThreadCount_);
    completionPortThread.start();

    if (completionPort_ == Handle.init)
      completionPort_ = CreateIoCompletionPort(INVALID_HANDLE_VALUE, Handle.init, 0, 0);

    if (CreateIoCompletionPort(directoryHandle_, completionPort_, cast(uint)&bindCompletionCallback, 0) == Handle.init)
      throw new Win32Exception;

    enabled_ = true;
    watch(null);
  }

  private void stopEvents() {
    if (isHandleInvalid)
      return;

    stopWatching_ = true;

    CloseHandle(directoryHandle_);
    directoryHandle_ = Handle.init;

    enabled_ = false;
  }

  private void restart() {
    if (enabled_) {
      stopEvents();
      startEvents();
    }
  }

  private void watch(void* buffer) {
    if (!enabled_ || isHandleInvalid)
      return;

    if (buffer == null)
      buffer = std.c.stdlib.malloc(bufferSize_);

    auto overlapped = new Overlapped;
    auto lpOverlapped = overlapped.pack(&completionCallback);
    lpOverlapped.Pointer = buffer;

    BOOL result = ReadDirectoryChangesW(directoryHandle_, 
      buffer, 
      bufferSize_, 
      includeSubDirs_ ? TRUE : FALSE, 
      cast(uint)notifyFilters_, 
      null, 
      lpOverlapped, 
      null);

    if (!result) {
      Overlapped.free(lpOverlapped);
      std.c.stdlib.free(buffer);

      if (!isHandleInvalid)
        onError(new ErrorEventArgs(new Win32Exception));
    }
  }

  private bool isMatch(string path) {

    /*string escape(string str) {
      string ret;
      foreach (i, ch; str) {
        switch (ch) {
          case '\\', '*', '+', '?', '|', '{', '[', '(', ')', '^', '$', '.', '#', ' ':
            ret ~= "\\" ~ ch;
            break;
          case '\n':
            ret ~= "\\n";
            break;
          case '\r':
            ret ~= "\\r";
            break;
          case '\t':
            ret ~= "\\t";
            break;
          case '\f':
            ret ~= "\\f";
            break;
          default:
            ret ~= ch;
            break;
        }
      }
      return ret;
    }*/

    string name = std.path.getBaseName(path);

    if (name == null || filter_ == null)
      return false;

    if (filter_ == "*")
      return true;

    /*if (filter_[0] == '*' && filter_.indexOf('*', 1) == -1) {
      uint n = filter_.length - 1;
      if (name.length >= n && juno.base.string.compare(filter_, 1, name, name.length - n, n, true) == 0)
        return true;
    }

    // Should probably use a custom pattern matcher, but this is adequate for most cases.
    string pattern = "^" ~ escape(filter_.toUpper()).replace(r"\*", ".*").replace(r"\?", ".") ~ "$";
    return std.regexp.find(name.toUpper(), pattern) != -1;*/
    // Actually, fnmatch appears to do what we want.
    return std.path.fnmatch(name, filter_) != 0;
  }

  private void notifyRename(WatcherChange action, string name, string oldName) {
    if (isMatch(name) || isMatch(oldName))
      onRenamed(new RenamedEventArgs(action, directory_, name, oldName));
  }

  private void notifyFileSystem(uint action, string name) {
    if (isMatch(name)) {
      switch (action) {
        case FILE_ACTION_ADDED:
          onCreated(new FileSystemEventArgs(WatcherChange.Created, directory_, name));
          break;
        case FILE_ACTION_REMOVED:
          onDeleted(new FileSystemEventArgs(WatcherChange.Deleted, directory_, name));
          break;
        case FILE_ACTION_MODIFIED:
          onChanged(new FileSystemEventArgs(WatcherChange.Changed, directory_, name));
          break;
        default:
      }
    }
  }

  private void completionCallback(uint errorCode, uint numBytes, OVERLAPPED* lpOverlapped) {
    //debug writefln("completionCallback");
    auto overlapped = Overlapped.unpack(lpOverlapped);
    void* buffer = overlapped.overlapped.Pointer;
    try {
      if (stopWatching_)
        return;

      if (errorCode != 0) {
        onError(new ErrorEventArgs(new Win32Exception(errorCode)));
        enableEvents = false;
        return;
      }

      if (numBytes > 0) {
        uint offset;
        string oldName;
        FILE_NOTIFY_INFORMATION* notify;
        do {
          notify = cast(FILE_NOTIFY_INFORMATION*)(buffer + offset);
          offset += notify.NextEntryOffset;

          string name = toUtf8(notify.FileName.ptr, 0, notify.FileNameLength / 2);

          // Like System.IO.FileSystemWatcher, we just want one rename notification.
          if (notify.Action == FILE_ACTION_RENAMED_OLD_NAME) {
            oldName = name;
          }
          else if (notify.Action == FILE_ACTION_RENAMED_NEW_NAME) {
            if (oldName != null) {
              notifyRename(WatcherChange.Renamed, name, oldName);
              oldName = null;
            }
            else {
              notifyRename(WatcherChange.Renamed, name, oldName);
            }
          }
          else {
            if (oldName != null) {
              notifyRename(WatcherChange.Renamed, null, oldName);
              oldName = null;
            }
            notifyFileSystem(notify.Action, name);
          }
        } while (notify.NextEntryOffset != 0);

        if (oldName != null) {
          notifyRename(WatcherChange.Renamed, null, oldName);
          oldName = null;
        }
      }
    }
    finally {
      Overlapped.free(lpOverlapped);

      if (stopWatching_) {
        if (buffer != null)
          std.c.stdlib.free(buffer);
      }
      else {
        watch(buffer);
        //restart();
      }
    }
  }

  private bool isHandleInvalid() {
    return (directoryHandle_ == Handle.init 
      || directoryHandle_ == INVALID_HANDLE_VALUE);
  }

}

///
interface Iterator(T) {

  ///
  int opApply(int delegate(ref T) action);

}

class FileSystemIterator : Iterator!(string) {

  private string path_;
  private string searchPattern_;
  private bool includeFiles_;
  private bool includeDirs_;

  this(string path, string searchPattern, bool includeFiles, bool includeDirs) {
    path_ = path;
    searchPattern_ = searchPattern;
    includeFiles_ = includeFiles;
    includeDirs_ = includeDirs;
  }

  int opApply(int delegate(ref string) action) {

    bool isDir(WIN32_FIND_DATA findData) {
      return ((findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0);
    }

    bool isFile(WIN32_FIND_DATA findData) {
      return ((findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == 0);
    }

    string getSearchResult(string path, WIN32_FIND_DATA findData) {
      return combine(path, toUtf8(findData.cFileName[0 .. std.string.wcslen(findData.cFileName.ptr)]));
    }

    int ret = 0;

    string fullPath = getFullPath(path_);

    string searchPattern = searchPattern_.trimEnd('\t', '\n', '\v', '\f', '\r', '\u0085', '\u00a0');
    if (searchPattern == ".")
      searchPattern = "*";
    if (searchPattern.length == 0)
      return ret;

    string searchPath = combine(fullPath, searchPattern);
    if (searchPath[$ - 1] == std.path.sep[0] 
      || searchPath[$ - 1] == std.path.altsep[0] 
      || searchPath[$ - 1] == ':')
      searchPath ~= '*';

    string userPath = path_;
    string tempPath = getDirectoryName(searchPattern);
    if (tempPath.length != 0)
      userPath = combine(userPath, tempPath);

    WIN32_FIND_DATA findData;
    uint lastError;

    Handle hFind = FindFirstFile(searchPath.toUtf16z(), findData);
    if (hFind != INVALID_HANDLE_VALUE) {
      scope(exit) FindClose(hFind);

      do {
        if (std.string.wcscmp(findData.cFileName.ptr, ".") == 0
          || std.string.wcscmp(findData.cFileName.ptr, "..") == 0)
          continue;

        string result = getSearchResult(userPath, findData);

        if ((includeDirs_ && isDir(findData)) 
          || (includeFiles_ && isFile(findData))) {
          if ((ret = action(result)) != 0)
            break;
        }
      } while (FindNextFile(hFind, findData));

      lastError = GetLastError();
    }

    if (lastError != ERROR_SUCCESS 
      && lastError != ERROR_NO_MORE_FILES 
      && lastError != ERROR_FILE_NOT_FOUND)
      ioError(lastError, userPath);

    return ret;
  }

}

/**
 * Returns an iterable collection of directory names in the specified _path.
 */
Iterator!(string) enumDirectories(string path, string searchPattern = "*") {
  return enumFileSystemNames(path, searchPattern, false, true);
}

/**
 * Returns an iterable collection of file names in the specified _path.
 */
Iterator!(string) enumFiles(string path, string searchPattern = "*") {
  return enumFileSystemNames(path, searchPattern, true, false);
}

/**
 * Returns an iterable collection of file-system entries in the specified _path.
 */
Iterator!(string) enumFileSystemEntries(string path, string searchPattern = "*") {
  return enumFileSystemNames(path, searchPattern, true, true);
}

private Iterator!(string) enumFileSystemNames(string path, string searchPattern, bool includeFiles, bool includeDirs) {
  return new FileSystemIterator(path, searchPattern, includeFiles, includeDirs);
}
