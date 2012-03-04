/**
 * Copyright: (c) 2009 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.base.core;

alias void* Handle;

size_t offsetof(alias F)() {
  return F.offsetof;
}

struct Struct(T...) {

  T fields;

}

interface IDisposable {

  void dispose();

}

void using(IDisposable obj, void delegate() block) {
  try {
    block();
  }
  finally {
    if (obj !is null)
      obj.dispose();
  }
}

// Used by cloneObject.
extern(C) private Object _d_newclass(ClassInfo info);

// Creates a shallow copy of an object.
Object cloneObject(Object obj) {
  if (obj is null)
    return null;

  ClassInfo ci = obj.classinfo;
  size_t start = Object.classinfo.init.length;
  size_t end = ci.init.length;

  Object clone = _d_newclass(ci);
  (cast(void*)clone)[start .. end] = (cast(void*)obj)[start .. end];
  return clone;
}

struct Optional(T) {

  private T value_;
  private bool hasValue_;

  static Optional opCall(T value) {
    Optional self;
    self.value_ = value;
    self.hasValue_ = true;
    return self;
  }

  void opAssign(T value) {
    value_ = value;
    hasValue_ = true;
  }

  @property T value() {
    if (!hasValue)
      throw new InvalidOperationException;
    return value_;
  }

  @property bool hasValue() {
    return hasValue_;
  }

  int opCmp(Optional other) {
    if (hasValue) {
      if (other.hasValue)
        return typeid(T).compare(&value_, &other.value_);
      return 1;
    }
    if (other.hasValue)
      return -1;
    return 0;
  }

  int opEquals(Optional other) {
    if (hasValue) {
      if (other.hasValue)
        return typeid(T).equals(&value_, &other.value_);
      return false;
    }
    if (other.hasValue)
      return false;
    return true;
  }

}

/**
 * The exception thrown when one of the arguments provided to a method is not valid.
 */
class ArgumentException : Exception {

  private static const E_ARGUMENT = "Value does not fall within the expected range.";

  private string paramName_;

  this() {
    super(E_ARGUMENT);
  }

  this(string message) {
    super(message);
  }

  this(string message, string paramName) {
    super(message);
    paramName_ = paramName;
  }

  final string paramName() {
    return paramName_;
  }

}

/**
 * The exception thrown when a null reference is passed to a method that does not accept it as a valid argument.
 */
class ArgumentNullException : ArgumentException {

  private static const E_ARGUMENTNULL = "Value cannot be null.";

  this() {
    super(E_ARGUMENTNULL);
  }

  this(string paramName) {
    super(E_ARGUMENTNULL, paramName);
  }

  this(string paramName, string message) {
    super(message, paramName);
  }

}

/**
 * The exception that is thrown when the value of an argument passed to a method is outside the allowable range of values.
 */
class ArgumentOutOfRangeException : ArgumentException {

  private static const E_ARGUMENTOUTOFRANGE = "Index was out of range.";

  this() {
    super(E_ARGUMENTOUTOFRANGE);
  }

  this(string paramName) {
    super(E_ARGUMENTOUTOFRANGE, paramName);
  }

  this(string paramName, string message) {
    super(message, paramName);
  }

}

/**
 * The exception thrown when the format of an argument does not meet the parameter specifications of the invoked method.
 */
class FormatException : Exception {

  private static const E_FORMAT = "The value was in an invalid format.";

  this() {
    super(E_FORMAT);
  }

  this(string message) {
    super(message);
  }

}

/**
 * The exception thrown for invalid casting.
 */
class InvalidCastException : Exception {

  private static const E_INVALIDCAST = "Specified cast is not valid.";

  this() {
    super(E_INVALIDCAST);
  }

  this(string message) {
    super(message);
  }

}

/**
 * The exception thrown when a method call is invalid.
 */
class InvalidOperationException : Exception {

  private static const E_INVALIDOPERATION = "Operation is not valid.";

  this() {
    super(E_INVALIDOPERATION);
  }

  this(string message) {
    super(message);
  }

}

/**
 * The exception thrown when a requested method or operation is not implemented.
 */
class NotImplementedException : Exception {

  private static const E_NOTIMPLEMENTED = "The operation is not implemented.";

  this() {
    super(E_NOTIMPLEMENTED);
  }

  this(string message) {
    super(message);
  }

}

/**
 * The exception thrown when an invoked method is not supported.
 */
class NotSupportedException : Exception {

  private static const E_NOTSUPPORTED = "The specified method is not supported.";

  this() {
    super(E_NOTSUPPORTED);
  }

  this(string message) {
    super(message);
  }

}

/**
 * The exception thrown when there is an attempt to dereference a null reference.
 */
class NullReferenceException : Exception {

  private static const E_NULLREFERENCE = "Object reference not set to an instance of an object.";

  this() {
    super(E_NULLREFERENCE);
  }

  this(string message) {
    super(message);
  }

}

/**
 * The exception thrown when the operating system denies access.
 */
class UnauthorizedAccessException : Exception {

  private static const E_UNAUTHORIZEDACCESS = "Access is denied.";

  this() {
    super(E_UNAUTHORIZEDACCESS);
  }

  this(string message) {
    super(message);
  }

}

/**
 * The exception thrown when a security error is detected.
 */
class SecurityException : Exception {

  private static const E_SECURITY = "Security error.";

  this() {
    super(E_SECURITY);
  }

  this(string message) {
    super(message);
  }

}

/**
 * The exception thrown for errors in an arithmetic, casting or conversion operation.
 */
class ArithmeticException : Exception {

  private static const E_ARITHMETIC = "Overflow or underflow in arithmetic operation.";

  this() {
    super(E_ARITHMETIC);
  }

  this(string message) {
    super(message);
  }

}

/**
 * The exception thrown when an arithmetic, casting or conversion operation results in an overflow.
 */
class OverflowException : ArithmeticException {

  private const E_OVERFLOW = "Arithmetic operation resulted in an overflow.";

  this() {
    super(E_OVERFLOW);
  }

  this(string message) {
    super(message);
  }

}

class OutOfMemoryException : Exception {

  private const E_OUTOFMEMORY = "Out of memory.";

  this() {
    super(E_OUTOFMEMORY);
  }

  this(string message) {
    super(message);
  }

}
