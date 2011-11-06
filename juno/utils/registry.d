/**
 * Contains classes that manipulate the Windows _registry.
 *
 * Copyright: (c) 2008 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.utils.registry;

private import juno.base.core,
  juno.base.string,
  juno.locale.convert,
  juno.base.environment,
  juno.base.native;

private import std.string : format;
private import std.format : FormatError;

debug private import std.stdio;

/**
 * Specifies the data types to use when storing values in the registry.
 */
enum RegistryValueKind {
  Unknown           = 0,  /// Indicates an unsupported registry data type.
  String            = 1,  /// Specifies a string. Equivalent to REG_SZ.
  ExpandString      = 2,  /// Specifies a string containing references to environment vaariables. Equivalent to REG_EXPAND_SZ.
  Binary            = 3,  /// Specifies binary data in any form. Equivalent to REG_BINARY.
  DWord             = 4,  /// Specifies a 32-bit binary number. Equivalent to REG_DWORD.
  MultiString       = 7,  /// Specifies an array of strings. Equivalent to REG_MULTI_SZ.
  QWord             = 11  /// Specifies a 64-bit binary number. Equivalent to REG_QWORD.
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

  private const string[] keyNames_ = [
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
  private static RegistryKey dynData_;

  private Handle hkey_;
  private string name_;
  private bool writable_;
  private bool systemKey_;
  private bool perfData_;
  private bool dirty_;

  static ~this() {
    classesRoot_ = null;
    currentUser_ = null;
    localMachine_ = null;
    users_ = null;
    performanceData_ = null;
    currentConfig_ = null;
    dynData_ = null;
  }

  /// Defines the types of documents and properties associated with those types. Reads HKEY_CLASSES_ROOT.
  static RegistryKey classesRoot() {
    if (classesRoot_ is null)
      classesRoot_ = getSystemKey(HKEY_CLASSES_ROOT);
    return classesRoot_;
  }

  /// Contains information about the current user preferences. Reads HKEY_CURRENT_USER.
  static RegistryKey currentUser() {
    if (currentUser_ is null)
      currentUser_ = getSystemKey(HKEY_CURRENT_USER);
    return currentUser_;
  }

  /// Contains configuration data for the local machine. Reads HKEY_LOCAL_MACHINE.
  static RegistryKey localMachine() {
    if (localMachine_ is null)
      localMachine_ = getSystemKey(HKEY_LOCAL_MACHINE);
    return localMachine_;
  }

  /// Contains information about the default user configuration. Reads HKEY_USERS.
  static RegistryKey users() {
    if (users_ is null)
      users_ = getSystemKey(HKEY_USERS);
    return users_;
  }

  /// Contains performance information for software components. Reads HKEY_PERFORMANCE_DATA.
  static RegistryKey performanceData() {
    if (performanceData_ is null)
      performanceData_ = getSystemKey(HKEY_PERFORMANCE_DATA);
    return performanceData_;
  }

  /// Contains configuration information about hardware that is not specifiec to the user. Reads HKEY_CURRENT_CONFIG.
  static RegistryKey currentConfig() {
    if (currentConfig_ is null)
      currentConfig_ = getSystemKey(HKEY_CURRENT_CONFIG);
    return currentConfig_;
  }

  /// Contains dynamic registry data. Reads HKEY_DYN_DATA.
  static RegistryKey dynData() {
    if (dynData_ is null)
      dynData_ = getSystemKey(HKEY_DYN_DATA);
    return dynData_;
  }

  private static RegistryKey getSystemKey(Handle hkey) {
    auto key = new RegistryKey(hkey, true, true, hkey == HKEY_PERFORMANCE_DATA);
    key.name_ = keyNames_[cast(int)hkey & 0x0FFFFFFF];
    return key;
  }

  private this(Handle hkey, bool writable, bool systemKey = false, bool perfData = false) {
    hkey_ = hkey;
    writable_ = writable;
    systemKey_ = systemKey;
    perfData_ = perfData;
  }

  ~this() {
    close();
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

  /+/**
   * Saves the current key and all of its subkeys and values to a file.
   * Params: fileName = The name of the file to which the key and subkeys are to be saved.
   * See_Also: $(LINK2 http://msdn2.microsoft.com/en-us/library/ms724917.aspx, RegSaveKey).
   */
  void save(string fileName) {
    int ret = RegSaveKey(hkey_, fileName.toUtf16z(), null);
  }+/

  /**
   * Retrieves a subkey.
   * Params:
   *   name = Name or path of the subkey to open.
   *   writable = true if you need write access to the key.
   * Returns: The subkey requested, or null if the operation failed.
   */
  RegistryKey openSubKey(string name, bool writable = false) {
    Handle result;
    int ret = RegOpenKeyEx(hkey_, name.toUtf16z(), 0, (writable ? (KEY_READ | KEY_WRITE) : KEY_READ), result);

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
  RegistryKey createSubKey(string name, bool writable) {
    if (auto key = openSubKey(name, writable))
      return key;

    Handle result;
    uint disp;
    int ret = RegCreateKeyEx(hkey_, name.toUtf16z(), 0, null, 0, (writable ? (KEY_READ | KEY_WRITE) : KEY_READ), null, result, &disp);

    if (ret == ERROR_SUCCESS && result != INVALID_HANDLE_VALUE) {
      auto key = new RegistryKey(result, writable, false);
      if (name.length == 0)
        key.name_ = name_;
      else
        key.name_ = name_ ~ "\\" ~ name;
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

      int ret = RegDeleteKey(hkey_, name.toUtf16z());
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
          foreach (s; key.subKeyNames) {
            key.deleteSubKeyTreeImpl(s);
          }
        }
      }
      finally {
        key.close();
      }

      int ret = RegDeleteKey(hkey_, name.toUtf16z());
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

    int ret = RegDeleteValue(hkey_, name.toUtf16z());
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
    int ret = RegQueryValueEx(hkey_, name.toUtf16z(), null, &type, null, null);
    if (ret != ERROR_SUCCESS)
      throw new Win32Exception(ret);

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
  T getValue(T)(string name, T defaultValue = T.init, bool expandEnvironmentNames = true) {

    /*string expandEnvironmentVariables(string name) {
      auto src = name.toUtf16z();
      int size = ExpandEnvironmentStrings(src, null, 0);

      wchar[] dst = new wchar[size];
      size = ExpandEnvironmentStrings(src, dst.ptr, dst.length);
      if (size == 0)
        throw new Win32Exception(GetLastError());

      return dst[0 .. size - 1].toUtf8();
    }*/

    auto lpName = name.toUtf16z();

    uint type, size;
    RegQueryValueEx(hkey_, lpName, null, &type, null, &size);

    static if (is(T : uint)) {
      if (type == REG_DWORD) {
        uint b;
        RegQueryValueEx(hkey_, lpName, null, &type, cast(ubyte*)&b, &size);
        return cast(T)b;
      }
    }
    else static if (is(T : ulong)) {
      if (type == REG_QWORD) {
        ulong b;
        RegQueryValueEx(hkey_, lpName, null, &type, cast(ubyte*)&b, &size);
        return cast(T)b;
      }
    }
    else static if (is(T : string)) {
      if (type == REG_SZ || type == REG_EXPAND_SZ) {
        wchar[] b = new wchar[size / wchar.sizeof];
        RegQueryValueEx(hkey_, lpName, null, &type, cast(ubyte*)b.ptr, &size);
        auto ret = b[0 .. (size / wchar.sizeof) - 1].toUTF8();

        if (type == REG_EXPAND_SZ && expandEnvironmentNames)
          ret = expandEnvironmentVariables(ret);

        return ret;
      }
      // Convert to a string
      else if (type == REG_DWORD)
        return .toString(getValue!(uint)(name));
      else if (type == REG_QWORD)
        return .toString(getValue!(ulong)(name));
      else if (type == REG_MULTI_SZ)
        return .join(", ", getValue!(string[])(name));
      else if (type == REG_BINARY)
        return .format("%s", getValue!(ubyte[])(name));
    }
    else static if (is(T : string[])) {
      if (type == REG_MULTI_SZ) {
        string[] strings;

        wchar[] b = new wchar[size / wchar.sizeof];
        RegQueryValueEx(hkey_, lpName, null, &type, cast(ubyte*)b.ptr, &size);

        uint index;
        uint end = b.length;

        while (index < end) {
          uint pos = index;
          while (pos < end && b[pos] != '\0')
            pos++;

          if (pos < end) {
            if (pos - index > 0)
              strings ~= b[index .. pos].toUTF8();
            else if (pos != end - 1)
              strings ~= "";
          }
          else strings ~= b[index .. end].toUTF8();

          index = pos + 1;
        }

        return strings;
      }
    }
    else static if (is(T : ubyte[])) {
      if (type == REG_BINARY || type == REG_DWORD_BIG_ENDIAN) {
        ubyte[] b = new ubyte[size];
        RegQueryValueEx(hkey_, lpName, null, &type, b.ptr, &size);
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
  void setValue(T)(string name, T value, RegistryValueKind kind = RegistryValueKind.Unknown) {
    if (!writable_)
      throw new UnauthorizedAccessException("Cannot write to the registry key.");

    if (kind == RegistryValueKind.Unknown) {
      static if (is(T == int) || is(T == uint)) kind = RegistryValueKind.DWord;
      else static if (is(T == long) || is(T == ulong)) kind = RegistryValueKind.QWord;
      else static if (is(T : string)) kind = RegistryValueKind.String;
      else static if (is(T : string[])) kind = RegistryValueKind.MultiString;
      else static if (is(T == ubyte[])) kind = RegistryValueKind.Binary;
      else kind = RegistryValueKind.String;
    }

    wchar* lpName = name.toUtf16z();

    int ret = ERROR_SUCCESS;
    try {
      switch (kind) {
        case RegistryValueKind.DWord:
          uint data;
          static if (is(T : uint))
            data = cast(uint)value;
          else static if (is(T : string))
            data = parse!(uint)(value);
          else
            throw new InvalidCastException;

          ret = RegSetValueEx(hkey_, lpName, 0, REG_DWORD, cast(ubyte*)&data, uint.sizeof);
          break;

        case RegistryValueKind.QWord:
          ulong data;
          static if (is(T : ulong))
            data = cast(ulong)value;
          else static if (is(T : string))
            data = parse!(ulong)(value);
          else
            throw new InvalidCastException;

          ret = RegSetValueEx(hkey_, lpName, 0, REG_QWORD, cast(ubyte*)&data, ulong.sizeof);
          break;

        case RegistryValueKind.String, RegistryValueKind.ExpandString:
          string data;
          static if (is(T : string))
            data = value;
          else
            data = format("%s", value);

          ret = RegSetValueEx(hkey_, lpName, 0, REG_SZ, cast(ubyte*)data.toUtf16z(), (data.length * wchar.sizeof) + 2);
          break;

        case RegistryValueKind.MultiString:
          static if (is(T : string[])) {
            uint size;
            foreach (s; value)
              size += (s.length + 1) * wchar.sizeof;

            wchar[] buffer = new wchar[size];
            int cur;
            foreach (s; value) {
              wstring ws = .toUtf16(s);

              int pos = cur + ws.length;
              buffer[cur .. pos] = ws;
              buffer[pos] = '\0';

              cur = pos + 1;
            }

            ret = RegSetValueEx(hkey_, lpName, 0, REG_MULTI_SZ, cast(ubyte*)buffer.ptr, buffer.length);
          }
          else
            throw new InvalidCastException;
          break;

        case RegistryValueKind.Binary:
          static if (is(T : ubyte[]))
            ret = RegSetValueEx(hkey_, lpName, 0, REG_BINARY, (cast(ubyte[])value).ptr, value.length);
          else
            throw new InvalidCastException;
          break;

        default:
      }
    }
    catch (FormatError) {
      throw new ArgumentException("The type of the value argument did not match the specified RegistryValueKind or the value could not be properly converted.");
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
  string name() {
    return name_;
  }

  /**
   * Retrieves the count of values in the key.
   */
  uint valueCount() {
    uint value;
    int ret = RegQueryInfoKey(hkey_, null, null, null, null, null, null, &value, null, null, null, null);
    if (ret != ERROR_SUCCESS)
      throw new Win32Exception(ret);
    return value;
  }

  /**
   * Retrieves an array of strings containing all the value names.
   */
  string[] valueNames() {
    uint count = valueCount;
    string[] names = new string[count];

    if (count > 0) {
      wchar[256] buffer;
      for (uint i = 0; i < count; i++) {
        uint len = buffer.length;
        int ret;
        if ((ret = RegEnumValue(hkey_, i, buffer.ptr, &len, null, null, null, null)) != ERROR_SUCCESS)
          throw new Win32Exception(ret);
        names[i] = buffer[0 .. len].toUTF8();
      }
    }

    return names;
  }

  /**
   * Retrieves the count of subkeys of the current key.
   */
  uint subKeyCount() {
    uint value;
    int ret = RegQueryInfoKey(hkey_, null, null, null, &value, null, null, null, null, null, null, null);
    if (ret != ERROR_SUCCESS)
      throw new Win32Exception(ret);
    return value;
  }

  /**
   * Retrieves an array of strings containing all the subkey names.
   */
  string[] subKeyNames() {
    uint count = subKeyCount;
    string[] names = new string[count];

    if (count > 0) {
      wchar[256] buffer;
      for (uint i = 0; i < count; i++) {
        uint len = buffer.length;
        int ret;
        if ((ret = RegEnumKeyEx(hkey_, i, buffer.ptr, &len, null, null, null, null)) != ERROR_SUCCESS)
          throw new Win32Exception(ret);
        names[i] = buffer[0 .. len].toUTF8();
      }
    }

    return names;
  }

}
