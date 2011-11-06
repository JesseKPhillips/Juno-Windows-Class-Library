/**
 * Copyright: (c) 2008 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.io.core;

private import juno.base.core,
  juno.base.text;

private import std.stdarg;
private import std.string : format;

debug private import std.stdio;

class IOException : Exception {

  this(string message = "I/O error occurred.") {
    super(message);
  }

}

abstract class Writer {

  protected string newLine_ = [ '\r', '\n' ];

  protected this() {
  }

  ~this() {
    close();
  }

  void close() {
  }

  void flush() {
  }

  void write(...) {
  }

  void writeln(...) {
    write(_arguments, _argptr);
    write(newLine);
  }

  void newLine(string value) {
    if (value == null)
      value = "\r\n";
    newLine_ = value;
  }

  string newLine() {
    return newLine_;
  }

  abstract Encoding encoding();

}

private void resolveArgList(ref TypeInfo[] args, ref va_list argptr, out string format) {
  if (args.length == 2 && args[0] == typeid(TypeInfo[]) && args[1] == typeid(va_list)) {
    args = va_arg!(TypeInfo[])(argptr);
    argptr = *cast(va_list*)argptr;

    if (args.length > 1 && args[0] == typeid(string)) {
      format = va_arg!(string)(argptr);
      args = args[1 .. $];
    }

    if (args.length == 2 && args[0] == typeid(TypeInfo[]) && args[1] == typeid(va_list))
      resolveArgList(args, argptr, format);
  }
  else if (args.length > 1 && args[0] == typeid(string)) {
    format = va_arg!(string)(argptr);
    args = args[1 .. $];
  }
}

class StringWriter : Writer {

  private string sb_;
  private Encoding encoding_;

  this() {
  }

  override void write(...) {
    auto args = _arguments;
    auto argptr = _argptr;
    string fmt = null;

    resolveArgList(args, argptr, fmt);

    if (fmt == null && args.length == 1 && args[0] == typeid(string)) {
      sb_ ~= va_arg!(string)(argptr);
    }
    else if (args.length > 0) {
      write(format((fmt == null) ? "%s" : fmt, args, argptr));
    }
  }

  override string toString() {
    return sb_;
  }

  override Encoding encoding() {
    if (encoding_ is null)
      encoding_ = new Utf8Encoding;
    return encoding_;
  }

}
