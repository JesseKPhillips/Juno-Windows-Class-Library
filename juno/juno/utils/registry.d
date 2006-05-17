module juno.utils.registry;

private import juno.base.core,
  juno.base.text,
  juno.base.win32;

public class Registry {

  public static const RegistryKey classesRoot;

  static this() {
    classesRoot = RegistryKey.getBaseKey(RegistryKey.HKEY_CLASSES_ROOT);
  }

}

public class RegistryKey {

  private enum State {
    Dirty = 0x1,
    SystemKey = 0x2,
    Writable = 0x4
  }

  private static const Handle HKEY_CLASSES_ROOT = cast(Handle)0x80000000;

  private static const char[][] hkeyNames_ = [ "HKEY_CLASSES_ROOT" ];

  private Handle hkey_;
  private char[] keyName_;
  private State state_;

  ~this() {
    close();
  }

  public void close() {
    if (hkey_ != Handle.init && (state_ & State.SystemKey) == 0) {
      RegCloseKey(hkey_);
      hkey_ = Handle.init;
    }
  }

  public RegistryKey openSubKey(char[] name, bool writable = false) {
    Handle hkey;
    if (RegOpenKeyExW(hkey_, name.toUtf16z(), 0, getKeyAccess(writable), hkey) == 0 && hkey != Handle.init) {
      RegistryKey newKey = new RegistryKey(hkey, writable);
      newKey.keyName_ = keyName_ ~ "\\" ~ name;
      return newKey;
    }
    return null;
  }

  public char[] getStringValue(char[] name, char[] defaultValue = null) {
    uint cb, type;
    if (RegQueryValueExW(hkey_, name.toUtf16z(), null, type, null, cb) == 0 && type == REG_SZ) {
      wchar[] b = new wchar[cb / 2];
      RegQueryValueExW(hkey_, name.toUtf16z(), null, type, b, cb);
      return .toUtf8(b.ptr);
    }
    return defaultValue;
  }

  public char[] getExpandStringValue(char[] name, char[] defaultValue = null) {
    uint cb, type;
    if (RegQueryValueExW(hkey_, name.toUtf16z(), null, type, null, cb) == 0 && type == REG_EXPAND_SZ) {
      wchar[] b = new wchar[cb / 2];
      RegQueryValueExW(hkey_, name.toUtf16z(), null, type, b, cb);
      return .toUtf8(b.ptr);
    }
    return defaultValue;
  }

  public ubyte[] getBinaryValue(char[] name, ubyte[] defaultValue = null) {
    uint cb, type;
    if (RegQueryValueExW(hkey_, name.toUtf16z(), null, type, null, cb) == 0 && type == REG_BINARY) {
      ubyte[] b = new ubyte[cb];
      RegQueryValueExW(hkey_, name.toUtf16z(), null, type, b, cb);
      return b;
    }
    return defaultValue;
  }

  public int getIntValue(char[] name, int defaultValue = int.init) {
    uint cb, type;
    if (RegQueryValueExW(hkey_, name.toUtf16z(), null, type, null, cb) == 0 && type == REG_DWORD) {
      int value;
      RegQueryValueExW(hkey_, name.toUtf16z(), null, type, &value, cb);
      return value;
    }
    return defaultValue;
  }

  public long getLongValue(char[] name, long defaultValue = long.init) {
    uint cb, type;
    if (RegQueryValueExW(hkey_, name.toUtf16z(), null, type, null, cb) == 0 && type == REG_QWORD) {
      long value;
      RegQueryValueExW(hkey_, name.toUtf16z(), null, type, &value, cb);
      return value;
    }
    return defaultValue;
  }

  public void setStringValue(char[] name, char[] value) {
    RegSetValueExW(hkey_, name.toUtf16z(), 0, REG_SZ, value.toUtf16z(), (value.length * 2) + 2);
  }

  public void setExpandStringValue(char[] name, char[] value) {
    RegSetValueExW(hkey_, name.toUtf16z(), 0, REG_EXPAND_SZ, value.toUtf16z(), (value.length * 2) + 2);
  }

  public void setBinaryValue(char[] name, ubyte[] value) {
    RegSetValueExW(hkey_, name.toUtf16z(), 0, REG_BINARY, value, value.length);
  }

  public void setIntValue(char[] name, int value) {
    RegSetValueExW(hkey_, name.toUtf16z(), 0, REG_DWORD, &value, int.sizeof);
  }

  public void setLongValue(char[] name, long value) {
    RegSetValueExW(hkey_, name.toUtf16z(), 0, REG_QWORD, &value, long.sizeof);
  }

  public char[] name() {
    return keyName_;
  }

  public int valueCount() {
    uint value;
    RegQueryInfoKeyW(hkey_, null, null, null, null, null, &value, null, null, null, null, null);
    return value;
  }

  public uint subKeyCount() {
    uint value;
    RegQueryInfoKeyW(hkey_, null, null, null, &value, null, null, null, null, null, null, null);
    return value;
  }

  private this(Handle hkey, bool writable, bool systemKey = false) {
    hkey_ = hkey;
    if (systemKey)
      state_ |= State.SystemKey;
    if (writable)
      state_ |= State.Writable;
  }

  private static RegistryKey getBaseKey(Handle hkey) {
    RegistryKey key = new RegistryKey(hkey, true, true);
    key.keyName_ = hkeyNames_[cast(int)hkey & 0xfffffff];
    return key;
  }

  private static uint getKeyAccess(bool writable) {
    return writable ? KEY_READ | KEY_WRITE : KEY_READ;
  }

}