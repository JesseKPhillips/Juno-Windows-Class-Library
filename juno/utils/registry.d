module juno.utils.registry;

private import juno.base.core,
  juno.base.string,
  juno.base.environment,
  juno.base.win32;

public final class RegistryKey {

  private Handle hkey_;
  private char[] name_;
  private bool writable_;
  private bool systemKey_;

  private static const char[][] hkeyNames_ = [ "HKEY_CLASSES_ROOT", "HKEY_CURRENT_USER", "HKEY_LOCAL_MACHINE", "HKEY_USERS", "HKEY_PERFORMANCE_DATA", "HKEY_CURRENT_CONFIG", "HKEY_DYN_DATA" ];

  public static const RegistryKey classesRoot;
  public static const RegistryKey currentUser;
  public static const RegistryKey localMachine;
  public static const RegistryKey users;
  public static const RegistryKey performanceData;
  public static const RegistryKey currentConfig;
  public static const RegistryKey dynamicData;

  static this() {
    classesRoot = RegistryKey.getRootKey(HKEY_CLASSES_ROOT);
    currentUser = RegistryKey.getRootKey(HKEY_CURRENT_USER);
    localMachine = RegistryKey.getRootKey(HKEY_LOCAL_MACHINE);
    users = RegistryKey.getRootKey(HKEY_USERS);
    performanceData = RegistryKey.getRootKey(HKEY_PERFORMANCE_DATA);
    currentConfig = RegistryKey.getRootKey(HKEY_CURRENT_CONFIG);
    dynamicData = RegistryKey.getRootKey(HKEY_DYN_DATA);
  }

  ~this() {
    close();
  }

  public void close() {
    if (hkey_ != Handle.init && !systemKey_) {
      RegCloseKey(hkey_);
      hkey_ = Handle.init;
    }
  }

  public RegistryKey openSubKey(char[] name, bool writable = false) {
    Handle hkey;
    int res = RegOpenKeyEx(hkey_, name.toLPStr(), 0, getAccess(writable), hkey);
    if (res == ERROR_SUCCESS && hkey != Handle.init && hkey != INVALID_HANDLE_VALUE) {
      RegistryKey newKey = new RegistryKey(hkey, writable, false);
      newKey.name_ = name_ ~ '\\' ~ name;
      return newKey;
    }
    return null;
  }

  public void deleteSubKey(char[] subkey) {
    RegDeleteKey(hkey_, subkey.toLPStr());
  }

  public void deleteSubKeyTree(char[] subkey) {
    RegistryKey key = openSubKey(subkey);
    if (key !is null) {
      scope (exit) key.close();
      if (key.subKeyCount > 0) {
        char[][] names = key.subKeyNames;
        foreach (name; names)
          key.deleteSubKeyTree(name);
      }
      RegDeleteKey(hkey_, subkey.toLPStr());
    }
    else
      throw new ArgumentException("Cannot delete a subkey tree because the subkey does not exist.");
  }

  public char[] getStringValue(char[] name, char[] defaultValue = null) {
    uint cb, type;
    if (RegQueryValueEx(hkey_, name.toLPStr(), null, type, null, cb) == 0) {
      if (type == REG_SZ || type == REG_EXPAND_SZ) {
        wchar[] b = new wchar[cb / 2];
        RegQueryValueEx(hkey_, name.toLPStr(), null, type, b, cb);
        char[] result = b.toUtf8();
        if (type == REG_EXPAND_SZ)
          result = expandEnvironmentVariables(result);
        return result;
      }
    }
    return defaultValue;
  }

  public char[] getExpandStringValue(char[] name, char[] defaultValue = null) {
    uint cb, type;
    if (RegQueryValueEx(hkey_, name.toLPStr(), null, type, null, cb) == 0) {
      if (type == REG_EXPAND_SZ) {
        wchar[] b = new wchar[cb / 2];
        RegQueryValueEx(hkey_, name.toLPStr(), null, type, b, cb);
        return expandEnvironmentVariables(b.toUtf8());
      }
    }
    return defaultValue;
  }

  public char[][] getMultiStringValue(char[] name, char[][] defaultValue = null) {
    uint cb, type;
    if (RegQueryValueEx(hkey_, name.toLPStr(), null, type, null, cb) == 0) {
      if (type == REG_MULTI_SZ) {
        char[][] result;

        wchar[] b = new wchar[cb / 2];
        RegQueryValueEx(hkey_, name.toLPStr(), null, type, b, cb);

        uint index = 0, end = b.length;
        while (index < end) {
          uint pos = index;
          while (pos < end && b[pos] != '\0')
            pos++;

          if (pos < end) {
            if (pos - index > 0)
              result ~= b[index .. pos].toUtf8();
            else if (pos != end - 1)
              result ~= "";
          }
          else
            result ~= b.toUtf8(index, end);

          index = pos + 1;
        }

        return result;
      }
    }
    return defaultValue;
  }

  public ubyte[] getBinaryValue(char[] name, ubyte[] defaultValue = null) {
    uint cb, type;
    if (RegQueryValueEx(hkey_, name.toLPStr(), null, type, null, cb) == 0) {
      if (type == REG_BINARY) {
        ubyte[] b = new ubyte[cb];
        RegQueryValueEx(hkey_, name.toLPStr(), null, type, b, cb);
        return b;
      }
    }
    return defaultValue;
  }

  public int getIntValue(char[] name, int defaultValue = 0) {
    uint cb, type;
    if (RegQueryValueEx(hkey_, name.toLPStr(), null, type, null, cb) == 0) {
      if (type == REG_DWORD) {
        int b;
        RegQueryValueEx(hkey_, name.toLPStr(), null, type, &b, cb);
        return b;
      }
    }
    return defaultValue;
  }

  public long getLongValue(char[] name, long defaultValue = 0) {
    uint cb, type;
    if (RegQueryValueEx(hkey_, name.toLPStr(), null, type, null, cb) == 0) {
      if (type == REG_QWORD) {
        long b;
        RegQueryValueEx(hkey_, name.toLPStr(), null, type, &b, cb);
        return b;
      }
    }
    return defaultValue;
  }

  public void setStringValue(char[] name, char[] value) {
    RegSetValueEx(hkey_, name.toLPStr(), 0, REG_SZ, value.toLPStr(), (value.length * 2) + 2);
  }

  public void setExpandStringValue(char[] name, char[] value) {
    RegSetValueEx(hkey_, name.toLPStr(), 0, REG_EXPAND_SZ, value.toLPStr(), (value.length * 2) + 2);
  }

  public void setIntValue(char[] name, int value) {
    RegSetValueEx(hkey_, name.toLPStr(), 0, REG_DWORD, &value, int.sizeof);
  }

  public void setLongValue(char[] name, long value) {
    RegSetValueEx(hkey_, name.toLPStr(), 0, REG_DWORD, &value, long.sizeof);
  }

  public void setBinaryValue(char[] name, ubyte[] value) {
    RegSetValueEx(hkey_, name.toLPStr(), 0, REG_DWORD, value, value.length);
  }

  public void deleteValue(char[] name) {
    RegDeleteValue(hkey_, name.toLPStr());
  }

  public override char[] toString() {
    return name_;
  }

  public char[] name() {
    return name_;
  }

  public uint subKeyCount() {
    uint result;
    int res = RegQueryInfoKey(hkey_, null, null, null, &result, null, null, null, null, null, null, null);
    return result;
  }

  public char[][] subKeyNames() {
    uint count = subKeyCount;
    char[][] result = new char[][count];

    if (count > 0) {
      wchar[256] buffer;
      for (uint i = 0; i < count; i++) {
        uint len = buffer.length;
        RegEnumKeyEx(hkey_, i, buffer, len, null, null, null, null);
        result[i] = buffer.toUtf8();
      }
    }

    return result;
  }

  public uint valueCount() {
    uint result;
    int res = RegQueryInfoKey(hkey_, null, null, null, null, null, null, &result, null, null, null, null);
    return result;
  }

  public char[][] valueNames() {
    uint count = valueCount;
    char[][] result = new char[][count];

    if (count > 0) {
      wchar[256] buffer;
      for (uint i = 0; i < count; i++) {
        uint len = buffer.length;
        RegEnumValue(hkey_, i, buffer, len, null, null, null, null);
        result[i] = buffer.toUtf8();
      }
    }

    return result;
  }

  private this(Handle hkey, bool writable, bool systemKey = false) {
    hkey_ = hkey;
    writable_ = writable;
    systemKey_ = systemKey;
  }

  private static uint getAccess(bool writable) {
    return writable ? KEY_READ | KEY_WRITE : KEY_READ;
  }

  private static RegistryKey getRootKey(Handle hkey) {
    RegistryKey key = new RegistryKey(hkey, true, true);
    key.name_ = hkeyNames_[cast(int)hkey & 0x0FFFFFFF];
    return key;
  }

}