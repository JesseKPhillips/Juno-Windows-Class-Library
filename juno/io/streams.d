module juno.io.streams;

private import juno.base.all,
  juno.base.win32,
  juno.intl.core;
private import std.stream : Stream, SeekPos;
private static import std.stdarg;

public abstract class TextWriter {

  protected char[] newLine_ = "\r\n";

  public abstract void close();

  public abstract void write(...);

  public abstract void writeln(...);

  public abstract Encoding encoding();

  public char[] newLine() {
    return newLine_;
  }
  public void newLine(char[] value) {
    if (value == null)
      value = "\r\n";
    newLine_ = value;
  }

  protected this() {
  }

}

private void resolveArgs(inout TypeInfo[] args, inout void* argptr, out char[] fmt) {
  if (args.length == 2 && args[0] is typeid(TypeInfo[]) && args[1] is typeid(void*)) {
    args = std.stdarg.va_arg!(TypeInfo[])(argptr);
    argptr = *cast(void**)argptr;

    if (args.length > 1 && args[0] is typeid(char[])) {
      fmt = std.stdarg.va_arg!(char[])(argptr);
      args = args[1 .. $];
    }

    if (args.length == 2 && args[0] is typeid(TypeInfo[]) && args[1] is typeid(void*))
      resolveArgs(args, argptr, fmt);
  }
  else if (args.length > 1 && args[0] is typeid(char[])) {
    fmt = std.stdarg.va_arg!(char[])(argptr);
    args = args[1 .. $];
  }
}

public class StringWriter : TextWriter {

  private char[] string_;
  private bool isOpen_;
  private Encoding encoding_;

  public this() {
    isOpen_ = true;
  }

  public override void close() {
    isOpen_ = false;
  }

  public override void write(...) {
    TypeInfo[] args = _arguments;
    void* argptr = _argptr;
    char[] fmt = null;

    resolveArgs(args, argptr, fmt);

    if (fmt == null && args.length == 1 && args[0] is typeid(char[]))
      string_ ~= std.stdarg.va_arg!(char[])(argptr);
    else if (args.length > 0)
      write(juno.base.string.format(NumberFormat.currentFormat, (fmt == null) ? "{0}" : fmt, args, argptr));
  }

  public override void writeln(...) {
    write(_arguments, _argptr);
    write(newLine);
  }

  public override char[] toString() {
    return string_;
  }

  public override Encoding encoding() {
    if (encoding_ is null)
      encoding_ = new Utf8Encoding;
    return encoding_;
  }

}

public class StreamWriter : TextWriter {

  private Stream stream_;
  private Encoding encoding_;
  private bool disposed_;

  public this(Stream stream, Encoding encoding = Encoding.UTF8) {
    stream_ = stream;
    encoding_ = encoding;
  }

  public override void close() {
    if (stream_ !is null) {
      try {
        stream_.close();
      }
      finally {
        stream_ = null;
      }
    }
  }

  public override void write(...) {
    TypeInfo[] args = _arguments;
    void* argptr = _argptr;
    char[] fmt = null;

    resolveArgs(args, argptr, fmt);

    if (fmt == null && args.length == 1 && args[0] is typeid(char[])) {
      char[] chars = std.stdarg.va_arg!(char[])(argptr);
      ubyte[] bytes = encoding_.encode(chars);
      stream_.write(bytes);
    }
    else if (args.length > 0)
      write(juno.base.string.format(NumberFormat.currentFormat, (fmt == null) ? "{0}" : fmt, args, argptr));
  }

  public override void writeln(...) {
    write(_arguments, _argptr);
    write(newLine);
  }

  public override Encoding encoding() {
    return encoding_;
  }

  public Stream baseStream() {
    return stream_;
  }

}