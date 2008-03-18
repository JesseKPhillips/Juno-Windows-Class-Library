/**
 * Copyright: (c) 2008 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.base.core;

/**
 */
typedef void* Handle;

struct Struct(T...) {
  T fields;
}

/**
 */
class ArgumentException : Exception {

  private string paramName_;

  this(string message = "Value does not fall within the expected range.") {
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

class ArgumentNullException : ArgumentException {

  this() {
    super("Specified argument was out of the range of valid values.");
  }

  this(string paramName, string message = "Specified argument was out of the range of valid values.") {
    super(message, paramName);
  }

}

class FormatException : Exception {

  this(string message = "The value was in an invalid format.") {
    super(message);
  }

}

class InvalidCastException : Exception {

  this(string message = "Specified cast is not valid.") {
    super(message);
  }

}

class InvalidOperationException : Exception {

  this(string message = "Operation is not valid.") {
    super(message);
  }

}

class NotImplementedException : Exception {

  this(string message = "The operation is not implemented.") {
    super(message);
  }

}

class NotSupportedException : Exception {

  this(string message = "The specified method is not supported.") {
    super(message);
  }

}

class NullReferenceException : Exception {

  this(string message = "Object reference not set to an instance of an object.") {
    super(message);
  }

}

class UnauthorizedAccessException : Exception {

  this(string message = "Access is denied.") {
    super(message);
  }

}

class SecurityException : Exception {

  this(string message = "Security error.") {
    super(message);
  }

}

class ArithmeticException : Exception {

  this(string message = "Overflow or underflow in arithmetic operation.") {
    super(message);
  }

}

class OverflowException : ArithmeticException {

  this(string message = "Arithmetic operation resulted in an overflow.") {
    super(message);
  }

}
