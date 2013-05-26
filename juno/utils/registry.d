/**
 * Contains classes that manipulate the Windows _registry.
 *
 * Copyright: (c) 2009 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.utils.registry;

import juno.base.core,
  juno.base.string,
  juno.base.native,
  std.utf;
static import std.c.stdlib;

import std.conv;

/// Specifies the data types to use when storing values in the registry.
enum RegistryValueKind {
  Unknown      = 0,  /// Indicates an unsupported registry data type.
  String       = 1,  /// Specifies a string. Equivalent to REG_SZ.
  ExpandString = 2,  /// Specifies a string containing references to environment vaariables. Equivalent to REG_EXPAND_SZ.
  Binary       = 3,  /// Specifies binary data in any form. Equivalent to REG_BINARY.
  DWord        = 4,  /// Specifies a 32-bit binary number. Equivalent to REG_DWORD.
  MultiString  = 7,  /// Specifies an array of strings. Equivalent to REG_MULTI_SZ.
  QWord        = 11  /// Specifies a 64-bit binary number. Equivalent to REG_QWORD.
}

///
enum RegistryValueOptions {
  None,                       ///
  DoNotExpandEnvironmentNames ///
}

///
enum RegistryOptions {
  None,    ///
  Volatile ///
}

/**
 * Represents a node in the Windows registry.
 * Examples:
 * ---
 * import juno.utils.registry, std.stdio;
 *
 * void main() {
 *   // Create a subkey named TestKey under "HKEY_CURRENT_USER".
 *   scope key = RegistryKey.currentUser.createSubKey("TestKey");
 *   if (key) {
 *     // Create data for the TestKey subkey.
 *     key.setValue("StringValue", "Hello, World");
 *     key.setValue("DWordValue", 123);
 *     key.setValue("BinaryValue", cast(ubyte[])[1, 2, 3]);
 *     key.setValue("MultiStringValue", ["Hello", "World"]);
 *
 *     // Print the data in the TestKey subkey.
 *     writefln("There are %s values for %s", key.valueCount, key.name);
 *     foreach (valueName; key.valueNames) {
 *       writefln("%s: %s", valueName, key.getValue!(string)(valueName));
 *     }
 *   }
 * }
 * ---
 */
final class RegistryKey {

  private static const string[] keyNames_ = [
    "HKEY_CLASSES_ROOT",
    "HKEY_CURRENT_USER",
    "HKEY_LOCAL_MACHINE",
    "HKEY_USERS",
    "HKEY_PERFORMANCE_DATA",
    "HKEY_CURRENT_CONFIG",
    "HKEY_DYN_DATA"
  ];

  private static RegistryKey classesRoot_;
  private static RegistryKey currentUser_;
  private static RegistryKey localMachine_;
  private static RegistryKey users_;
  private static RegistryKey performanceData_;
  private static RegistryKey currentConfig_;
  private static RegistryKey dynData_; // Win9x only

/*
  static ~this() {
    classesRoot_ = null;
    currentUser_ = null;
    localMachine_ = null;
    users_ = null;
    performanceData_ = null;
    currentConfig_ = null;
    dynData_ = null;
  }
*/

  private Handle hkey_;
  private string name_;
  private bool writable_;
  private bool systemKey_;
  private bool perfData_;
  private bool dirty_;

  /// Defines the types of documents and properties associated with those types. Reads HKEY_CLASSES_ROOT.
  static @property RegistryKey classesRoot() {
    if (classesRoot_ is null)
      classesRoot_ = getSystemKey(HKEY_CLASSES_ROOT);
    return classesRoot_;
  }

  /// Contains information about the current user preferences. Reads HKEY_CURRENT_USER.
  static @property RegistryKey currentUser() {
    if (currentUser_ is null)
      currentUser_ = getSystemKey(HKEY_CURRENT_USER);
    return currentUser_;
  }

  /// Contains configuration data for the local machine. Reads HKEY_LOCAL_MACHINE.
  static @property RegistryKey localMachine() {
    if (localMachine_ is null)
      localMachine_ = getSystemKey(HKEY_LOCAL_MACHINE);
    return localMachine_;
  }
  
  /// Contains information about the default user configuration. Reads HKEY_USERS.
  static @property RegistryKey users() {
    if (users_ is null)
      users_ = getSystemKey(HKEY_USERS);
    return users_;
  }
  
  /// Contains performance information for software components. Reads HKEY_PERFORMANCE_DATA.
  static @property RegistryKey performanceData() {
    if (performanceData_ is null)
      performanceData_ = getSystemKey(HKEY_PERFORMANCE_DATA);
    return performanceData_;
  }
  
  /// Contains configuration information about hardware that is not specifiec to the user. Reads HKEY_CURRENT_CONFIG.
  static @property RegistryKey currentConfig() {
    if (currentConfig_ is null)
      currentConfig_ = getSystemKey(HKEY_CURRENT_CONFIG);
    return currentConfig_;
  }
  
  /// Contains dynamic registry data. Reads HKEY_DYN_DATA.
  static @property RegistryKey dynData() {
    if (dynData_ is null)
      dynData_ = getSystemKey(HKEY_DYN_DATA);
    return dynData_;
  }

  private static RegistryKey getSystemKey(Handle hkey) {
    auto key = new RegistryKey(hkey, true, true, (hkey == HKEY_PERFORMANCE_DATA));
    key.name_ = keyNames_[cast(int)hkey & 0x0FFFFFFF];
    return key;
  }

  private this(Handle hkey, bool writable, bool systemKey = false, bool remoteKey = false, bool perfData = false) {
    hkey_ = hkey;
    writable_ = writable;
    systemKey_ = systemKey;
    perfData_ = perfData;
  }

  ~this() {
    close();
  }

  /**
   */
  static RegistryKey fromHandle(Handle handle) {
    return new RegistryKey(handle, true);
  }

  /**
   * Closes the key.
   */
  void close() {
    if (hkey_ != Handle.init) {
      if (!systemKey_) {
        RegCloseKey(hkey_);
        hkey_ = Handle.init;
      }
    }
  }
  
  /**
   * Writes all attributes of the current key into the registry.
   */
  void flush() {
    if (hkey_ != Handle.init) {
      if (dirty_)
        RegFlushKey(hkey_);
    }
  }

  /**
   * Retrieves a subkey.
   * Params:
   *   name = Name or path of the subkey to open.
   *   writable = true if you need write access to the key.
   * Returns: The subkey requested, or null if the operation failed.
   */
  RegistryKey openSubKey(string name, bool writable = false) {
    name = fixName(name);

    Handle result;
    int ret = RegOpenKeyEx(hkey_, name.toUTF16z(), 0, (writable ? (KEY_READ | KEY_WRITE) : KEY_READ), result);

    if (ret == ERROR_SUCCESS && result != INVALID_HANDLE_VALUE) {
      auto key = new RegistryKey(result, writable, false);
      key.name_ = name_ ~ "\\" ~ name;
      return key;
    }
    else if (ret == ERROR_ACCESS_DENIED || ret == ERROR_BAD_IMPERSONATION_LEVEL)
      throw new SecurityException("Requested registry access is not allowed.");

    return null;
  }

  /**
   * Creates a new subkey or opens an existing subkey.
   * Params:
   *   name = The _name or path of the subkey to create or open.
   *   writable = true if you need write access to the key.
   * Returns: The newly created subkey.
   */
  RegistryKey createSubKey(string name, bool writable, RegistryOptions options = RegistryOptions.None) {
    checkOptions(options);

    name = fixName(name);

    uint disposition;
    Handle result;
    int ret = RegCreateKeyEx(hkey_, name.toUTF16z(), 0, null, cast(uint)options, (writable ? (KEY_READ | KEY_WRITE) : KEY_READ), null, result, disposition);

    if (ret == ERROR_SUCCESS && result != INVALID_HANDLE_VALUE) {
      auto key = new RegistryKey(result, writable, false);

      if (name.length == 0)
        key.name_ = name;
      else
        key.name_ ~= "\\" ~ name;
      return key;
    }
    else if (ret != ERROR_SUCCESS)
      throw new Win32Exception(ret);

    return null;
  }

  /**
   * ditto
   */
  RegistryKey createSubKey(string name) {
    return createSubKey(name, writable_);
  }

  /**
   * Deletes the specified subkey.
   * Params:
   *   name = The _name of the subkey to delete.
   *   throwOnMissingSubKey = true to raise an exception if the subkey does not exist.
   */
  void deleteSubKey(string name, bool throwOnMissingSubKey = true) {
    if (!writable_)
      throw new UnauthorizedAccessException("Cannot write to the registry key.");

    if (auto key = openSubKey(name, false)) {
      try {
        if (key.subKeyCount > 0)
          throw new InvalidOperationException("Registry key has subkeys and recursive removes are not supported by this method.");
      }
      finally {
        key.close();
      }

      int ret = RegDeleteKey(hkey_, name.toUTF16z());
      if (ret != ERROR_SUCCESS) {
        if (ret == ERROR_FILE_NOT_FOUND && throwOnMissingSubKey)
          throw new ArgumentException("Cannot delete a subkey tree because the subkey does not exist.");
        else
          throw new Win32Exception(ret);
      }
    }
    else
      throw new ArgumentException("Cannot delete a subkey tree because the subkey does not exist.");
  }

  /**
   * Deletes a subkey and child subkeys recursively.
   * Params: name = The _name of the subkey to delete.
   * Throws:
   *   UnauthorizedAccessException if the user does not have the necessary rights.$(BR)
   *   ArgumentException if name does not specify a valid subkey.
   */
  void deleteSubKeyTree(string name) {
    if (name.length == 0 && systemKey_)
      throw new ArgumentException("Cannot delete a registry hive's subtree.");

    if (!writable_)
      throw new UnauthorizedAccessException("Cannot write to the registry key.");

    deleteSubKeyTreeImpl(name);
  }

  private void deleteSubKeyTreeImpl(string name) {
    if (auto key = openSubKey(name)) {
      try {
        if (key.subKeyCount > 0) {
          foreach (subKey; key.subKeyNames) {
            key.deleteSubKeyTreeImpl(subKey);
          }
        }
      }
      finally {
        key.close();
      }

      int ret = RegDeleteKey(hkey_, name.toUTF16z());
      if (ret != ERROR_SUCCESS)
        throw new Win32Exception(ret);
    }
    else
      throw new ArgumentException("Cannot delete a subkey tree because the subkey does not exist.");
  }

  /**
   * Deletes the specified value from this key.
   * Params:
   *   name = The _name of the value to delete.
   *   throwOnMissingValue = true to raise an exception if the specified value does not exist.
   */
  void deleteValue(string name, bool throwOnMissingValue = true) {
    if (!writable_)
      throw new UnauthorizedAccessException("Cannot write to the registry key.");

    int ret = RegDeleteValue(hkey_, name.toUTF16z());
    if (ret == ERROR_FILE_NOT_FOUND && throwOnMissingValue)
      throw new ArgumentException("Cannot delete a subkey tree because the subkey does not exist.");
  }

  /**
   * Retrieves the registry data type of the value associated with the specified _name.
   * Params: name = The _name of the value whose registry data type is to be retrieved.
   * Returns: A value representing the registry data type of the value associated with name.
   */
  RegistryValueKind getValueKind(string name) {
    uint type;
    int ret = RegQueryValueEx(hkey_, name.toUTF16z(), null, &type, null, null);
    return cast(RegistryValueKind)type;
  }

  /**
   * Retrieves the value associated with the specified _name.
   * Params:
   *   name = The _name of the value to retrieve.
   *   defaultValue = The value to return if name does not exist.
   *   expandEnvironmentNames = Specify true to expand environment values.
   * Returns: The value associated with name, or defaultValue if name is not found.
   */
  T getValue(T)(string name, T defaultValue = T.init, RegistryValueOptions options = RegistryValueOptions.None) {

    string expandEnvironmentVariables(string name) {
      auto src = name.toUTF16z();
      uint size = ExpandEnvironmentStringsW(src, null, 0);

      wchar[] dst = new wchar[size];
      size = ExpandEnvironmentStrings(src, dst.ptr, cast(uint)dst.length);
      if (size == 0)
        throw new Win32Exception(GetLastError());
      return to!string(dst[0 .. size - 1]);
    }

    bool expandEnvironmentNames = (options != RegistryValueOptions.DoNotExpandEnvironmentNames);
    auto lpName = name.toUTF16z();

    uint type, size;
    int ret = RegQueryValueEx(hkey_, lpName, null, &type, null, &size);

    static if (is(T : uint)) {
      if (type == REG_DWORD) {
        uint b;
        ret = RegQueryValueEx(hkey_, lpName, null, &type, cast(ubyte*)&b, &size);
        return cast(T)b;
      }
    }
    else static if (is(T : ulong)) {
      if (type == REG_QWORD) {
        ulong b;
        ret = RegQueryValueEx(hkey_, lpName, null, &type, cast(ubyte*)&b, &size);
        return cast(T)b;
      }
    }
    else static if (is(T : string)) {
      if (type == REG_SZ || type == REG_EXPAND_SZ) {
        wchar[] b = new wchar[size / wchar.sizeof];
        ret = RegQueryValueEx(hkey_, lpName, null, &type, cast(ubyte*)b.ptr, &size);
        auto data = to!string(b[0 .. (size / wchar.sizeof) - 1]);

        if (type == REG_EXPAND_SZ && expandEnvironmentNames)
          data = expandEnvironmentVariables(data);

        return data;
      }
    }
    else static if (is(T : string[])) {
      if (type == REG_MULTI_SZ) {
        string[] data;

        wchar[] b = new wchar[size / wchar.sizeof];
        RegQueryValueEx(hkey_, lpName, null, &type, cast(ubyte*)b.ptr, &size);

        uint index;
        uint end = b.length;

        while (index < end) {
          uint pos = index;
          while (pos < end && b[pos] != 0)
            pos++;

          if (pos < end) {
            if (pos - index > 0)
              data ~= .toUtf8(b[index .. end].ptr);
            else if (pos != end - 1)
              data ~= "";
          }
          else
            data ~= .toUtf8(b[index .. end].ptr);

          index = pos + 1;
        }

        return data;
      }
    }
    else static if (is(T : ubyte[])) {
      if (type == REG_BINARY || type == REG_DWORD_BIG_ENDIAN) {
        ubyte[] b = new ubyte[size];
        ret = RegQueryValueEx(hkey_, lpName, null, &type, b.ptr, &size);
        return b;
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
  void setValue(T)(string name, T value, RegistryValueKind valueKind = RegistryValueKind.Unknown) {
    if (!writable_)
      throw new UnauthorizedAccessException("Cannot write to the registry key.");

    if (valueKind == RegistryValueKind.Unknown) {
      static if (is(T == int) || is(T == uint))
        valueKind = RegistryValueKind.DWord;
      else static if (is(T == long) || is(T == ulong))
        valueKind = RegistryValueKind.QWord;
      else static if (is(T : string))
        valueKind = RegistryValueKind.String;
      else static if (is(T : string[]))
        valueKind = RegistryValueKind.MultiString;
      else static if (is(T == ubyte[]))
        valueKind = RegistryValueKind.Binary;
      else
        valueKind = RegistryValueKind.String;
    }

    auto lpName = name.toUTF16z();

    int ret = ERROR_SUCCESS;
    try {
      switch (valueKind) {
        case RegistryValueKind.DWord:
          uint data;
          static if (is(T : uint))
            data = cast(uint)value;
          else
            throw new InvalidCastException;

          ret = RegSetValueEx(hkey_, lpName, 0, cast(uint)valueKind, cast(ubyte*)&data, uint.sizeof);
          break;

        case RegistryValueKind.QWord:
          ulong data;
          static if (is(T : ulong))
            data = cast(ulong)value;
          else
            throw new InvalidCastException;

          ret = RegSetValueEx(hkey_, lpName, 0, cast(uint)valueKind, cast(ubyte*)&data, ulong.sizeof);
          break;

        case RegistryValueKind.String, RegistryValueKind.ExpandString:
          string data;
          static if (is(T : string))
            data = value;
          else
            data = std.string.format("%s", value);

          ret = RegSetValueEx(hkey_, lpName, 0, cast(uint)valueKind, cast(ubyte*)data.toUTF16z(), (data.length * wchar.sizeof) + 2);
          break;

        case RegistryValueKind.MultiString:
          static if (is(T : string[])) {
            uint size;
            foreach (s; value) {
              size += (s.length + 1) * wchar.sizeof;
            }

            wchar[] buffer = new wchar[size];
            int index;
            foreach (s; value) {
              wstring ws = s.toUTF16();

              int pos = index + ws.length;
              buffer[index .. pos] = ws;
              buffer[pos] = '\0';

              index = pos + 1;
            }

            ret = RegSetValueEx(hkey_, lpName, 0, cast(uint)valueKind, cast(ubyte*)buffer.ptr, buffer.length);
          }
          else
            throw new InvalidCastException;
          break;

        case RegistryValueKind.Binary:
          static if (is(T : ubyte[]))
            ret = RegSetValueEx(hkey_, lpName, 0, cast(uint)valueKind, (cast(ubyte[])value).ptr, value.length);
          else
            throw new InvalidCastException;
          break;

        default:
      }
    }
    catch (InvalidCastException) {
      throw new ArgumentException("The type of the value argument did not match the specified RegistryValueKind or the value could not be properly converted.");
    }

    if (ret != ERROR_SUCCESS)
      throw new Win32Exception(ret);
    else
      dirty_ = true;
  }

  /**
   * Retrieves a string representation of this key.
   */
  override string toString() {
    return name_;
  }

  /**
   * Retrieves the _name of this key.
   */
  @property string name() {
    return name_;
  }

  /**
   * Retrieves the count of values in the key.
   */
  @property uint valueCount() {
    uint values;
    int ret = RegQueryInfoKey(hkey_, null, null, null, null, null, null, &values, null, null, null, null);
    if (ret != ERROR_SUCCESS)
      throw new Win32Exception(ret);
    return values;
  }

  /**
   * Retrieves an array of strings containing all the value names.
   */
  @property string[] valueNames() {
    uint values = valueCount;
    string[] names = new string[values];

    if (values > 0) {
      wchar[256] name;
      for (auto i = 0; i < values; i++) {
        uint nameLen = name.length;
        int ret = RegEnumValue(hkey_, i, name.ptr, nameLen, null, null, null, null);
        if (ret != ERROR_SUCCESS)
          throw new Win32Exception(ret);
        names[i] = to!string(name[0 .. nameLen]);
      }
    }

    return names;
  }

  /**
   * Retrieves the count of subkeys of the current key.
   */
  @property uint subKeyCount() {
    uint subKeys;
    int ret = RegQueryInfoKey(hkey_, null, null, null, &subKeys, null, null, null, null, null, null, null);
    if (ret != ERROR_SUCCESS)
      throw new Win32Exception(ret);
    return subKeys;
  }

  /**
   * Retrieves an array of strings containing all the subkey names.
   */
  @property string[] subKeyNames() {
    uint values = subKeyCount;
    string[] names = new string[values];

    if (values > 0) {
      wchar[256] name;
      for (auto i = 0; i < values; i++) {
        uint nameLen = name.length;
        int ret = RegEnumKeyEx(hkey_, i, name.ptr, nameLen, null, null, null, null);
        if (ret != ERROR_SUCCESS)
          throw new Win32Exception(ret);
        names[i] = to!string(name[0 .. nameLen]);
      }
    }

    return names;
  }

  /**
   */
  @property Handle handle() {
    if (!systemKey_)
      return hkey_;

    Handle hkey;
    switch (name_) {
      case "HKEY_CLASSES_ROOT":
        hkey = HKEY_CLASSES_ROOT;
        break;
      case "HKEY_CURRENT_USER":
        hkey = HKEY_CURRENT_USER;
        break;
      case "HKEY_LOCAL_MACHINE":
        hkey = HKEY_LOCAL_MACHINE;
        break;
      case "HKEY_USERS":
        hkey = HKEY_USERS;
        break;
      case "HKEY_PERFORMANCE_DATA":
        hkey = HKEY_PERFORMANCE_DATA;
        break;
      case "HKEY_CURRENT_CONFIG":
        hkey = HKEY_CURRENT_CONFIG;
        break;
      case "HKEY_DYN_DATA":
        hkey = HKEY_DYN_DATA;
        break;
      default:
        throw new Win32Exception(ERROR_INVALID_HANDLE);
    }
    Handle result;
    uint ret = RegOpenKeyEx(hkey, null, 0, (writable_ ? (KEY_READ | KEY_WRITE) : KEY_READ), result);
    if (ret == ERROR_SUCCESS && result != INVALID_HANDLE_VALUE)
      return result;
    throw new Win32Exception(ret);
  }

  private static string fixName(string name) {
    if (name[name.length - 1] == '\\')
      name.length = name.length - 1;
    return name;
  }

  private static void checkOptions(RegistryOptions options) {
    if (options < RegistryOptions.None || options > RegistryOptions.Volatile)
      throw new ArgumentException("The specified RegistryOptions value is invalid", "options");
  }

}
