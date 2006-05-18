module juno.base.core;

typedef int Handle = 0;

public struct Version {

  public int major;
  public int minor;
  public int build = -1;
  public int revision = -1;

  public static Version opCall(int major, int minor, int build = -1, int revision = -1) {
    Version v;
    return v.major = major, v.minor = minor, v.build = build, v.revision = revision, v;
  }

  public bool opEquals(Version other) {
    return major == other.major && minor == other.minor && build == other.build && revision == other.revision;
  }

  public int opCmp(Version other) {
    if (major != other.major) {
      if (major > other.major)
        return 1;
      return -1;
    }
    if (minor != other.minor) {
      if (minor > other.minor)
        return 1;
      return -1;
    }
    if (build != other.build) {
      if (build > other.build)
        return 1;
      return -1;
    }
    if (revision != other.revision) {
      if (revision > other.revision)
        return 1;
      return -1;
    }
    return 0;
  }

  public uint toHash() {
    return ((major & 0x000F) << 28) | ((minor & 0x00FF) << 20) | ((build & 0x00FF) << 12) | (revision & 0x0FFF);
  }

}

public enum TypeCode {
  EMPTY = 0,
  BOOL = 'x',
  UBYTE = 'h',
  BYTE = 'g',
  USHORT = 't',
  SHORT = 's',
  UINT = 'k',
  INT = 'i',
  ULONG = 'm',
  LONG = 'l',
  FLOAT = 'f',
  DOUBLE = 'd',
  CHAR = 'a',
  ARRAY = 'A',
  CLASS = 'C',
  STRUCT = 'S',
  ENUM = 'E',
  POINTER = 'P'
}

// Wraps a variadic argument.
public struct Argument {

  private TypeInfo type_;
  private void* value_;
  private TypeCode typeCode_;

  public static Argument opCall(TypeInfo type, void* value) {
    Argument arg;
    return arg.type_ = type, arg.value_ = value, arg.typeCode_ = cast(TypeCode)type.classinfo.name[9], arg;
  }

  public final TypeInfo getType() {
    return type_;
  }

  public final TypeCode getTypeCode() {
    return typeCode_;
  }

  public final void* getValue() {
    return value_;
  }

}

// Wraps variadic arguments.
public struct ArgumentIterator {

  private Argument[] args_;
  private int size_;

  public static ArgumentIterator opCall(TypeInfo[] types, void* argptr) {
    ArgumentIterator it;
    foreach (TypeInfo type; types) {
      it.args_ ~= Argument(type, argptr);
      argptr += (type.tsize() + int.sizeof - 1) & ~(int.sizeof - 1);
      it.size_++;
    }
    return it;
  }

  public Argument opIndex(int index) {
    return args_[index];
  }

  public int count() {
    return size_;
  }

  public int opApply(int delegate(inout Argument) del) {
    int r;
    foreach (Argument arg; args_) {
      if ((r == del(arg)) != 0)
        break;
    }
    return r;
  }

}