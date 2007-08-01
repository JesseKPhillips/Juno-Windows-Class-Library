/*
 * Copyright (c) 2007 John Chapman
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

/**
 * Provides classes for working with the Windows _registry.
 */
module juno.utils.registry;

private import juno.base.core,
  juno.base.string,
  juno.base.environment,
  juno.base.numeric,
  juno.base.native,
  juno.io.core;

/**
 * Identifies the data type of a value in the registry.
 */
public enum RegistryValueKind {
  Unknown = 0,        /// Indicates an unsupported registry data type.
  String = 1,         /// Specifies a string. Equivalent to REG_SZ.
  ExpandString = 2,   /// Specifies a string containing references to environment variables. Equivalent to REG_EXPAND_SZ.
  Binary = 3,         /// Specifies binary data in any form. Equivalent to REG_BINARY.
  DWord = 4,          /// Specifies a 32-bit binary number. Equivalent to REG_DWORD.
  MultiString = 7,    /// Specifies an array of strings. Equivalent to REG_MULTI_SZ.
  QWord = 11          /// Specifies a 64-bit binary number. Equivalent to REG_QWORD.
}

/**
 * Represents a node in the Windows registry.
 */
public final class RegistryKey {

  private const string[] HKEY_NAMES = [ 
    "HKEY_CLASSES_ROOT", "HKEY_CURRENT_USER", "HKEY_LOCAL_MACHINE", "HKEY_USERS", "HKEY_PERFORMANCE_DATA", "HKEY_CURRENT_CONFIG", "HKEY_DYN_DATA"
  ];

  public static const RegistryKey classesRoot;      /// Defines the types of documents and properties associated with those types. Reads HKEY_CLASSES_ROOT.
  public static const RegistryKey currentUser;      /// Contains information about the current user preferences. Reads HKEY_CURRENT_USER.
  public static const RegistryKey localMachine;     /// Contains configuration data for the local machine. Reads HKEY_LOCAL_MACHINE.
  public static const RegistryKey users;            /// Contains information about the default user configuration. Reads HKEY_USERS.
  public static const RegistryKey performanceData;  /// Contains performance information for software components. Reads HKEY_PERFORMANCE_DATA.
  public static const RegistryKey currentConfig;    /// Contains configuration information about hardware that is not specifiec to the user. Reads HKEY_CURRENT_CONFIG.
  public static const RegistryKey dynData;          /// Contains dynamic registry data. Reads HKEY_DYN_DATA.

  private Handle hKey_;
  private string name_;
  private bool systemKey_;
  private bool perfDataKey_;
  private bool writable_;
  private bool remoteKey_;
  private bool dirty_;

  static this() {
    classesRoot = get(HKEY_CLASSES_ROOT);
    currentUser = get(HKEY_CURRENT_USER);
    localMachine = get(HKEY_LOCAL_MACHINE);
    users = get(HKEY_USERS);
    performanceData = get(HKEY_PERFORMANCE_DATA);
    currentConfig = get(HKEY_CURRENT_CONFIG);
    dynData = get(HKEY_DYN_DATA);
  }

  ~this() {
    close();
  }

  /**
   * Retrieves a string representation of this key.
   * Returns: A string representing the key.
   */
  public override string toString() {
    return name_;
  }

  /**
   * Closes the key.
   */
  public void close() {
    if (hKey_ != Handle.init) {
      if (!systemKey_) {
        RegCloseKey(hKey_);
        hKey_ = Handle.init;
      }
    }
  }

  /**
   * Writes all the attributes of this key to the registry.
   */
  public void flush() {
    if (hKey_ != Handle.init && dirty_)
      RegFlushKey(hKey_);
  }

  /**
   * Retrieves a subkey.
   * Params:
   *   name = Name or path of the subkey to open.
   *   writable = true if you need write access to the key.
   * Returns: The subkey requested, or null if the operation failed.
   */
  public RegistryKey openSubKey(string name, bool writable = false) {
    Handle hkey;
    int r = RegOpenKeyEx(hKey_, name.toUtf16z(), 0, (writable ? (KEY_READ | KEY_WRITE) : KEY_READ), hkey);
    if (r == ERROR_SUCCESS && hkey != Handle.init && hkey != INVALID_HANDLE_VALUE) {
      auto key = new RegistryKey(hkey, writable, false, false, false);
      key.name_ = this.name_ ~ '\\' ~ name;
      return key;
    }
    if (r == ERROR_ACCESS_DENIED)
      issueError(r, name_ ~ '\\' ~ name);
    return null;
  }

  public RegistryKey createSubKey(string name) {
    Handle hkey;
    uint disposition;
    int r = RegCreateKeyEx(hKey_, name.toUtf16z(), 0, null, 0, KEY_READ | KEY_WRITE, null, hkey, disposition);
    if (r == ERROR_SUCCESS && hkey != Handle.init && hkey != INVALID_HANDLE_VALUE) {
      auto key = new RegistryKey(hkey, true, false, false, false);
      if (name.length == 0)
        key.name_ = name_;
      else
        key.name_ = name_ ~ '\\' ~ name;
      return key;
    }
    if (r != ERROR_SUCCESS)
      issueError(r, name_ ~ '\\' ~ name);
    return null;
  }

  /**
   * Deletes the specified subkey.
   * Params: name = The _name of the subkey to delete.
   */
  public void deleteSubKey(string name) {
    RegDeleteKey(hKey_, name.toUtf16z());
  }

  public void deleteSubKeyTree(string name) {
    scope key = openSubKey(name, true);
    if (key !is null) {
      if (key.subKeyCount > 0) {
        foreach (subkey; key.subKeyNames)
          key.deleteSubKeyTree(subkey);
      }

      key.close();

      int r = RegDeleteKey(hKey_, name.toUtf16z());
      if (r != ERROR_SUCCESS)
        issueError(r, null);
    }
    else
      throw new ArgumentException("Cannot delete a subkey tree because the subkey does not exist.");
  }

  /**
   * Deletes the specified value from the registry.
   * Params: name = The _name of the value to delete.
   */
  public void deleteValue(string name) {
    RegDeleteValue(hKey_, name.toUtf16z());
  }

  /**
   * Retrieves the registry data type of the value associated with the specified _name.
   * Params: name = The _name of the value whose registry data type is to be retrieved.
   * Returns: A value representing the registry data type of the value associated with name.
   */
  public RegistryValueKind getValueKind(string name) {
    uint cb, type;
    RegQueryValueEx(hKey_, name.toUtf16z(), null, &type, null, &cb);
    return cast(RegistryValueKind)type;
  }

  /**
   * Retrieves the value associated with the specified _name.
   * Params:
   *   name = The _name of the value to retrieve.
   *   defaultValue = The value to return if name does not exist.
   *   doNotExpand = Specify false to expand environment values.
   * Returns: The value associated with name, or defaultValue if name is not found.
   */
  public T getValue(T)(string name, T defaultValue = T.init, bool doNotExpand = false) {
    uint cb, type;
    if (RegQueryValueEx(hKey_, name.toUtf16z(), null, &type, null, &cb) == 0) {
      static if (is(T == int)) {
        if (type == REG_DWORD) {
          int b;
          RegQueryValueEx(hKey_, name.toUtf16z(), null, &type, cast(ubyte*)&b, &cb);
          return b;
        }
      }
      else static if (is(T == long)) {
        if (type == REG_QWORD) {
          long b;
          RegQueryValueEx(hKey_, name.toUtf16z(), null, &type, cast(ubyte*)&b, &cb);
          return b;
        }
      }
      else static if (is(T : string)) {
        if (type == REG_SZ || type == REG_EXPAND_SZ) {
          wchar[] b = new wchar[cb / 2];
          RegQueryValueEx(hKey_, name.toUtf16z(), null, &type, cast(ubyte*)b.ptr, &cb);
          string result = .toUtf8(b.ptr);

          if (!doNotExpand && type == REG_EXPAND_SZ)
            return expandEnvironmentVariables(result);

          return result;
        }
      }
      else static if (is(T : string[])) {
        if (type == REG_MULTI_SZ) {
          string[] result;

          wchar[] b = new wchar[cb / 2];
          RegQueryValueEx(hKey_, name.toUtf16z(), null, &type, cast(ubyte*)b.ptr, &cb);

          uint index = 0;
          int end = b.length;
          while (index < end) {
            uint pos = index;
            while (pos < end && b[pos] != '\0') pos++;

            if (pos < end) {
              if (pos - index > 0) result ~= .toUtf8(b.ptr, index, pos);
              else if (pos != end - 1) result ~= "";
            }
            else result ~= .toUtf8(b.ptr, index, end);

            index = pos + 1;
          }

          return result;
        }
      }
      else static if (is(T == ubyte[])) {
        if (type == REG_BINARY || type == REG_DWORD_BIG_ENDIAN) {
          ubyte[] b = new ubyte[cb];
          RegQueryValueEx(hKey_, name.toUtf16z(), null, &type, b.ptr, &cb);
          return b;
        }
      }
    }
    return defaultValue;
  }

  /**
   * Sets the _value of a name/value pair in the registry key using the specified registry data type.
   * Params:
   *   name = The _name of the _value to be stored.
   *   value = The data to be stored.
   *   valueKind = The registry data type to use when storing the data.
   */
  public void setValue(T)(string name, T value, RegistryValueKind valueKind = RegistryValueKind.Unknown) {
    if (valueKind == RegistryValueKind.Unknown) {
      static if (is(T : string))
        valueKind = RegistryValueKind.String;
      else static if (is(T : string[]))
        valueKind = RegistryValueKind.MultiString;
      else static if (is(T == ubyte[]))
        valueKind = RegistryValueKind.Binary;
      else static if (is(T == int))
        valueKind = RegistryValueKind.DWord;
      else static if (is(T == long))
        valueKind = RegistryValueKind.QWord;
      else
        valueKind = RegistryValueKind.String;
    }

    int r = ERROR_SUCCESS;

    switch (valueKind) {
      case RegistryValueKind.String, RegistryValueKind.ExpandString:
        string s;
        static if (!is(T : string))
          s = .toString(value);
        else
          s = value;
        r = RegSetValueEx(hKey_, name.toUtf16z(), 0, REG_SZ, cast(ubyte*)s.toUtf16z(), (s.length * 2) + 2);
        break;
      case RegistryValueKind.MultiString:
        break;
      case RegistryValueKind.Binary:
        r = RegSetValueEx(hKey_, name.toUtf16z(), 0, REG_BINARY, cast(ubyte*)value.ptr, value.length);
        break;
      case RegistryValueKind.DWord:
        r = RegSetValueEx(hKey_, name.toUtf16z(), 0, REG_DWORD, cast(ubyte*)&value, int.sizeof);
        break;
      case RegistryValueKind.QWord:
        r = RegSetValueEx(hKey_, name.toUtf16z(), 0, REG_QWORD, cast(ubyte*)&value, long.sizeof);
        break;
      default:
    }

    if (r == ERROR_SUCCESS)
      dirty_ = true;
  }

  /**
   * Retrieves the _name of the key.
   * Returns: The _name of the key.
   */
  public string name() {
    return name_;
  }

  /**
   * Retrieves the count of subkeys of this key.
   * Returns: The number of subkeys.
   */
  public int subKeyCount() {
    uint result;
    RegQueryInfoKey(hKey_, null, null, null, &result, null, null, null, null, null, null, null);
    return result;
  }

  /** 
   * Retrieves an array of strings containing the subkey names.
   * Returns: An array of strings containing the subkey names.
   */
  public string[] subKeyNames() {
    int count = subKeyCount;
    string[] result = new string[count];

    if (count > 0) {
      wchar[256] buffer;
      for (int index = 0; index < count; index++) {
        uint cch = buffer.length;
        RegEnumKeyEx(hKey_, index, buffer.ptr, &cch, null, null, null, null);
        result[index] = .toUtf8(buffer.ptr);
      }
    }

    return result;
  }

  /**
   * Retrieves the count of values in the key.
   * Returns: The number of values.
   */
  public int valueCount() {
    uint result;
    RegQueryInfoKey(hKey_, null, null, null, null, null, null, &result, null, null, null, null);
    return result;
  }

  /** 
   * Retrieves an array of strings containing the value names associated with this key.
   * Returns: An array of strings containing the value names.
   */
  public string[] valueNames() {
    int count = valueCount;
    string[] result = new string[count];

    if (count > 0) {
      wchar[256] buffer;
      for (int index = 0; index < count; index++) {
        uint cch = buffer.length;
        RegEnumValue(hKey_, index, buffer.ptr, &cch, null, null, null, null);
        result[index] = .toUtf8(buffer.ptr);
      }
    }

    return result;
  }

  private this(Handle hKey, bool writable, bool systemKey = false, bool remoteKey = false, bool perfDataKey = false) {
    hKey_ = hKey;
    writable_ = writable;
    systemKey_ = systemKey;
    perfDataKey_ = perfDataKey;
  }

  private static RegistryKey get(Handle hKey) {
    auto key = new RegistryKey(hKey, true, true, false, hKey == HKEY_PERFORMANCE_DATA);
    key.name_ = HKEY_NAMES[cast(int)hKey & 0x0FFFFFFF];
    return key;
  }

  private void issueError(int errorCode, string s) {

    string getErrorMessage(uint error) {
      wchar[256] buffer;
      uint r = FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ARGUMENT_ARRAY | FORMAT_MESSAGE_IGNORE_INSERTS, null, error, LOCALE_USER_DEFAULT, buffer.ptr, buffer.length + 1, null);
      if (r != 0) {
        return toUtf8(buffer.ptr, 0, r);
      }
      return format("Unspecified error (0x{0:X8})", error);
    }

    switch (errorCode) {
      case ERROR_FILE_NOT_FOUND:
        throw new IOException("The specified registry key does not exist.");
      case ERROR_ACCESS_DENIED:
        throw new UnauthorizedAccessException("Access to the registry key '" ~ s ~ "' is denied.");
      default:
        throw new IOException(getErrorMessage(errorCode));
    }
  }

}