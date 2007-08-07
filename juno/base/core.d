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

module juno.base.core;

private import juno.base.string : split;
private import juno.base.numeric : parse, toString;
private import std.c.stdlib : malloc, free;

typedef void* Handle = null;

template istypeof(T1 : Object) {

  public bool istypeof(T2)(T2 other) {
    return cast(T1)other !is null;
  }

}

public class WeakRef {

  private Object** obj_;

  public this(Object target) {
    if (target !is null) {
      Object* p = cast(Object*)target;
      obj_ = cast(Object**)malloc(p.sizeof);
      *obj_ = p;

      target.notifyRegister(&unhook);
    }
  }

  ~this() {
    if (*obj_ !is null) {
      (cast(Object)*obj_).notifyUnRegister(&unhook);
      *obj_ = null;
    }

    if (obj_ !is null) {
      free(obj_);
      obj_ = null;
    }
  }

  public final void target(Object value) {
    Object* p = cast(Object*)value;
    obj_ = cast(Object**)malloc(p.sizeof);
    *obj_ = p;

    value.notifyRegister(&unhook);
  }

  public final Object target() {
    if (obj_ !is null)
      return cast(Object)*obj_;
    return null;
  }

  public final bool isAlive() {
    if (obj_ !is null)
      return *obj_ !is null;
    return false;
  }

  private void unhook(Object obj) {
    *obj_ = null;
  }

}

public final class Version {

  private int major_;
  private int minor_;
  private int build_;
  private int revision_;

  public this(int major = 0, int minor = 0, int build = -1, int revision = -1) {
    major_ = major;
    minor_ = minor;
    build_ = build;
    revision_ = revision;
  }

  public this(string strVersion) {
    build_ = -1;
    revision_ = -1;

    string[] parts = strVersion.split(['.']);
    int count = parts.length;
    major_ = parse!(int)(parts[0]);
    minor_ = parse!(int)(parts[1]);
    count -= 2;
    if (count > 0) {
      build_ = parse!(int)(parts[2]);
      count--;
      if (count > 0)
        revision_ = parse!(int)(parts[3]);
    }
  }

  public override string toString() {
    string s = .toString(major_) ~ '.' ~ .toString(minor_);
    if (build_ != -1) {
      s ~= '.' ~ .toString(build_);
      if (revision_ != -1)
        s ~= '.' ~ .toString(revision_);
    }
    return s;
  }

  public override hash_t toHash() {
    hash_t hash = (major_ & 0x0000000F) << 28;
    hash |= (minor_ & 0x000000FF) << 20;
    hash |= (build_ & 0x000000FF) << 12;
    hash |= revision_ & 0x00000FFF;
    return hash;
  }

  public override int opEquals(Object other) {
    Version that = cast(Version)other;
    if (that is null)
      return false;
    return major_ == that.major_ && minor_ == that.minor_ && build_ == that.build_ && revision_ == that.revision_;
  }

  public override int opCmp(Object other) {
    if (other is null)
      return 1;
    Version that = cast(Version)other;
    if (that is null)
      throw new ArgumentException("Obejct must be of type Version.");

    if (major_ != that.major_) {
      if (major_ > that.major_)
        return 1;
      else
        return -1;
    }
    if (minor_ != that.minor_) {
      if (minor_ > that.minor_)
        return 1;
      else
        return -1;
    }
    if (build_ != that.build_) {
      if (build_ > that.build_)
        return 1;
      else
        return -1;
    }
    if (revision_ != that.revision_) {
      if (revision_ > that.revision_)
        return 1;
      else
        return -1;
    }
    return 0;
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

  public short majorRevision() {
    return cast(short)(revision_ >> 0x10);
  }

  public short minorRevision() {
    return cast(short)(revision_ & 0xFFFF);
  }

}

public class BaseException : Exception {

  private Exception cause_;

  public this(string message = null, Exception cause = null) {
    super(message);
    cause_ = cause;
  }

  public override string toString() {
    string s = message;

    if (s != null)
      s = className ~ ": " ~ s;
    if (cause_ !is null)
      s ~= " ---> " ~ cause_.toString();

    return s;
  }

  public final Exception cause() {
    return cause_;
  }

  public string message() {
    if (msg != null)
      return msg;

    return "An exception of type " ~ className ~ " was thrown.";
  }

  private string className() {
    string s = this.classinfo.name;
    for (auto i = s.length - 1; i >= 0; i--) {
      if (s[i] == '.' && i + 1 < s.length)
        return s[i + 1 .. $];
    }
    return null;
  }

}

public class ArgumentException : BaseException {

  private string paramName_;

  public this(string message = "Value does not fall within the expected range.") {
    super(message);
  }

  public this(string message, string paramName, Exception cause = null) {
    super(message, cause);
    paramName_ = paramName;
  }

  public final string paramName() {
    return paramName_;
  }

}

public class ArgumentNullException : ArgumentException {

  public this() {
    super("Value cannot be null.");
  }

  public this(string paramName, string message = "Value cannot be null.") {
    super(message, paramName);
  }

}

public class ArgumentOutOfRangeException : ArgumentException {

  public this() {
    super("Specified argument was out of the range of valid values.");
  }

  public this(string paramName, string message = "Specified argument was out of the range of valid values.") {
    super(message, paramName);
  }

}

public class FormatException : BaseException {

  public this(string message = "The value was in an invalid format.", Exception cause = null) {
    super(message, cause);
  }

}

public class ArithmeticException : BaseException {

  public this(string message = "Overflow or underflow in arithmetic operation.", Exception cause = null) {
    super(message, cause);
  }

}

public class OverflowException : ArithmeticException {

  public this(string message = "Arithmetic operation resulted in an overflow.", Exception cause = null) {
    super(message, cause);
  }

}

public class InvalidCastException : BaseException {

  public this(string message = "Specified cast is not valid.", Exception cause = null) {
    super(message, cause);
  }

}

public class OutOfMemoryException : BaseException {

  public this(string message = "Insufficient memory to continue.", Exception cause = null) {
    super(message, cause);
  }

}

public class InvalidOperationException : BaseException {

  public this(string message = "Operation is not valid.", Exception cause = null) {
    super(message, cause);
  }

}

public class NotImplementedException : BaseException {

  public this(string message = "The operation is not implemented.", Exception cause = null) {
    super(message, cause);
  }

}

public class NotSupportedException : BaseException {

  public this(string message = "The specified method is not supported.", Exception cause = null) {
    super(message, cause);
  }

}

public class NullReferenceException : BaseException {

  public this(string message = "Object reference not set to an instance of an object.", Exception cause = null) {
    super(message, cause);
  }

}

public class UnauthorizedAccessException : BaseException {

  public this(string message = "Access is denied.", Exception cause = null) {
    super(message, cause);
  }

}

public class ObjectDisposedException : InvalidOperationException {

  private string objectName_;

  public this(string objectName, string message = "Cannot access a disposed object.") {
    super(message);
    objectName_ = objectName;
  }

  public override string message() {
    if (objectName_ == null)
      return super.message;
    return super.message ~ '\n' ~ "Cannot access a disposed object named '" ~ objectName_ ~ "'.";
  }

  public final string objectName() {
    return objectName_;
  }

}