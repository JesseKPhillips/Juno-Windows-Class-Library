module juno.base.core;

typedef int Handle = 0;

public struct Version {

  private int major_;
  private int minor_;
  private int build_;
  private int revision_;

  public static Version opCall(int major = 0, int minor = 0, int build = -1, int revision = -1) {
    Version ver;
    return ver.major_ = major,
      ver.minor_ = minor,
      ver.build_ = build,
      ver.revision_ = revision,
      ver;
  }

  public int major() {
    return major_;
  }

  public int minor() {
    return minor_;
  }

  public int build() {
    return build_;
  }

  public int revision() {
    return revision_;
  }

}

// Used by cloneObject.
extern (C) 
private Object _d_newclass(ClassInfo info);

// Creates a shallow copy of an object.
public Object cloneObject(Object obj) {
  if (obj is null)
    return null;

  ClassInfo ci = obj.classinfo;
  size_t start = Object.classinfo.init.length;
  size_t end = ci.init.length;

  Object clone = _d_newclass(ci);
  (cast(void*)clone)[start .. end] = (cast(void*)obj)[start .. end];
  return clone;
}

public void closeAfter(T)(T obj, void delegate() block) {
  try {
    block();
  }
  finally {
    static if (is(typeof(T.close)))
      obj.close();
  }
}

public class Throwable : object.Exception {

  public this(char[] message = null) {
    super(message);
  }

  public override char[] toString() {
    char[] result = this.classinfo.name;
    if (message != null)
      result ~= ": " ~ message;
    return result;
  }

  public char[] message() {
    if (msg != null)
      return msg;
    return "An exception of type " ~ this.classinfo.name ~ " was thrown.";
  }

}

public class ArgumentException : Throwable {

  private char[] paramName_;

  public this(char[] message = "Value did not fall within the expected range.") {
    super(message);
  }

  public this(char[] message, char[] paramName) {
    super(message);
    paramName_ = paramName;
  }

  public override char[] message() {
    char[] ret = super.message;
    if (paramName_ != null)
      ret ~= \r\n ~ "Parameter: " ~ paramName_;
    return ret;
  }

  public char[] paramName() {
    return paramName_;
  }

}

public class ArgumentNullException : ArgumentException {

  public this() {
    super("Value cannot be null.");
  }

  public this(char[] paramName, char[] message = "Value cannot be null.") {
    super(message, paramName);
  }

}

public class ArgumentOutOfRangeException : ArgumentException {

  public this() {
    super("Specified argument was out of the range of valid values.");
  }

  public this(char[] paramName, char[] message = "Specified argument was out of the range of valid values.") {
    super(message, paramName);
  }

}

public class InvalidOperationException : Throwable {

  public this(char[] message = "Operation is not valid.") {
    super(message);
  }

}

public class NotSupportedException : Throwable {

  public this(char[] message = "Specified method is not supported.") {
    super(message);
  }

}

public class InvalidCastException : Throwable {

  public this(char[] message = "Specified cast is not valid.") {
    super(message);
  }

}

public class FormatException : Throwable {

  public this(char[] message = "The value was in an invalid format.") {
    super(message);
  }

}

public class OutOfMemoryException : Throwable {

  public this(char[] message = "Insufficient memory to continue the execution of the program.") {
    super(message);
  }

}

public class ArithmeticException : Throwable {

  public this(char[] message = "Operation results in an overflow or underflow.") {
    super(message);
  }

}

public class OverflowException : Throwable {

  public this(char[] message = "Operation resulted in an overflow.") {
    super(message);
  }

}