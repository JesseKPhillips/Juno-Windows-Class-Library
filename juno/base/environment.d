/**
 * Provides information about the current _environment.
 *
 * Copyright: (c) 2009 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.base.environment;

import juno.base.core,
  juno.base.string,
  juno.base.native;

import core.memory;

/**
 * Gets the command line.
 */
string getCommandLine() {
  return .toUtf8(GetCommandLine());
}

/**
 * Gets an array containing the command-line arguments.
 */
string[] getCommandLineArgs() {
  int argc;
  wchar** argv = CommandLineToArgv(GetCommandLine(), argc);
  if (argc == 0) return null;

  string* a = cast(string*)GC.malloc(argc * string.sizeof);
  for (int i = 0; i < argc; i++) {
    a[i] = .toUtf8(argv[i]);
  }

  LocalFree(cast(Handle)argv);
  return a[0 .. argc];
}

/**
 * Gets or sets the NetBIOS name of the local computer.
 */
void getMachineName(string value) {
  SetComputerName(value.toUtf16z());
}
/// ditto
string getMachineName() {
  wchar[256] buffer;
  uint size = buffer.length;

  if (!GetComputerName(buffer.ptr, size))
    throw new InvalidOperationException;

  return .toUtf8(buffer.ptr, 0, size);
}

/**
 * Gets the user name of the person currently logged on to Windows.
 */
string getUserName() {
  wchar[256] buffer;
  uint size = buffer.length;

  GetUserName(buffer.ptr, size);

  return .toUtf8(buffer.ptr, 0, size);
}

/**
 * Gets the number of milliseconds elapsed since the system started.
 */
int getTickCount() {
  return GetTickCount();
}

/**
 * Replaces the name of each environment variable embedded in the specified string with the string equivalent of the value of the variable.
 * Params: name = A string containing the names of zero or more environment variables. Environment variables are quoted with the percent sign.
 * Returns: A string with each environment variable replaced by its value.
 * Examples:
 * ---
 * writefln(expandEnvironmentVariables("My system drive is %SystemDrive% and my system root is %SystemRoot%"));
 * ---
 */
string expandEnvironmentVariables(string name) {
  string[] parts = name.split('%');

  int c = 100;
  wchar[] buffer = new wchar[c];
  for (int i = 1; i < parts.length - 1; i++) {
    if (parts[i].length > 0) {
      string temp = "%" ~ parts[i] ~ "%";
      uint n = ExpandEnvironmentStrings(temp.toUtf16z(), buffer.ptr, c);
      while (n > c) {
        c = n;
        buffer.length = c;
        n = ExpandEnvironmentStrings(temp.toUtf16z(), buffer.ptr, c);
      }
    }
  }

  uint n = ExpandEnvironmentStrings(name.toUtf16z(), buffer.ptr, c);
  while (n > c) {
    c = n;
    buffer.length = c;
    n = ExpandEnvironmentStrings(name.toUtf16z(), buffer.ptr, c);
  }

  return .toUtf8(buffer.ptr);
}

/**
 * Represents a version number.
 */
final class Version {

  private int major_;
  private int minor_;
  private int build_;
  private int revision_;

  /**
   * Initializes a new instance.
   */
  this(int major, int minor, int build = -1, int revision = -1) {
    major_ = major;
    minor_ = minor;
    build_ = build;
    revision_ = revision;
  }

  /**
   * Gets the value of the _major component.
   */
  int major() {
    return major_;
  }

  /**
   * Gets the value of the _minor component.
   */
  int minor() {
    return minor_;
  }

  /**
   * Gets the value of the _build component.
   */
  int build() {
    return build_;
  }

  /**
   * Gets the value of the _revision component.
   */
  int revision() {
    return revision_;
  }

  override int opCmp(Object other) {
    if (other is null)
      return 1;

    auto v = cast(Version)other;
    if (v is null)
      throw new ArgumentException("Argument must be of type Version.");

    if (major_ != v.major_) {
      if (major_ > v.major_)
        return 1;
      return -1;
    }
    if (minor_ != v.minor_) {
      if (minor_ > v.minor_)
        return 1;
      return -1;
    }
    if (build_ != v.build_) {
      if (build_ > v.build_)
        return 1;
      return -1;
    }
    if (revision_ != v.revision_) {
      if (revision_ > v.revision_)
        return 1;
      return -1;
    }
    return 0;
  }

  override typeof(super.opEquals(Object)) opEquals(Object other) {
    auto v = cast(Version)other;
    if (v is null)
      return false;

    return (major_ == v.major_
      && minor_ == v.minor_
      && build_ == v.build_
      && revision_ == v.revision_);
  }

  uint toHash() {
    uint hash = (major_ & 0x0000000F) << 28;
    hash |= (minor_ & 0x000000FF) << 20;
    hash |= (build_ & 0x000000FF) << 12;
    hash |= revision_ & 0x00000FFF;
    return hash;
  }

  override string toString() {
    string s = std.string.format("%d.%d", major_, minor_);
    if (build_ != -1) {
      s ~= std.string.format(".%d", build_);
      if (revision_ != -1)
        s ~= std.string.format(".%d", revision_);
    }
    return s;
  }

}

/+enum PlatformId {
  Win32s,
  Win32Windows,
  Win32NT
}

PlatformId osPlatform() {
  static Optional!(PlatformId) osPlatform_;

  if (!osPlatform_.hasValue) {
    OSVERSIONINFOEX osvi;
    if (GetVersionEx(osvi) == 0)
      throw new InvalidOperationException("GetVersion failed.");

    osPlatform_ = cast(PlatformId)osvi.dwPlatformId;
  }

  return osPlatform_.value;
}+/

/**
 * Gets a Version object describing the major, minor, build and revision numbers of the operating system.
 */
Version osVersion() {
  static Version osVersion_;

  if (osVersion_ is null) {
    OSVERSIONINFOEX osvi;
    if (GetVersionEx(osvi) == 0)
      throw new InvalidOperationException("GetVersion failed.");

    osVersion_ = new Version(
      osvi.dwMajorVersion, 
      osvi.dwMinorVersion, 
      osvi.dwBuildNumber, 
      (osvi.wServicePackMajor << 16) | osvi.wServicePackMinor
    );
  }

  return osVersion_;
}
