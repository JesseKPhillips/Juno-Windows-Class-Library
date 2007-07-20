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

module juno.io.core;

private import juno.base.core,
  juno.base.string,
  juno.base.text,
  juno.base.native,
  juno.locale.core;

private import std.stdarg;
private import std.stream : Stream, SeekPos;
private import std.c.string : strncpy;

public abstract class Reader {

  ~this() {
    close();
  }

  public void close() {
  }

  public int peek() {
    return -1;
  }

  public int read() {
    return -1;
  }

  public int read(char[] buffer, int index, int count) {
    int n = 0;
    do {
      int c = read();
      if (c == -1)
        return 0;
      buffer[index + n++] = cast(char)c;
    } while (n < count);
    return n;
  }

  public string readToEnd() {
    char[] buffer = new char[4096];
    int n;
    string s;

    while ((n = read(buffer, 0, buffer.length)) != 0) {
      s ~= buffer[0 .. n];
    }

    return s;
  }

}

public abstract class Writer {

  protected char[] newLine_ = [ '\r', '\n' ];

  protected this() {
  }

  ~this() {
    close();
  }

  public void close() {
  }

  public void flush() {
  }

  public void write(...) {
  }

  public void writeln(...) {
    write(_arguments, _argptr);
    write(newLine);
  }

  public void newLine(string value) {
    if (value == null)
      value = "\r\n";
    newLine_ = value.dup;
  }

  public string newLine() {
    return newLine_;
  }

  public abstract Encoding encoding();

}

private void copyTo(in char[] source, int sourceIndex, char[] dest, int destIndex, int count) {
  strncpy(dest.ptr + destIndex, source.ptr + sourceIndex, count);
}

public class StringReader : Reader {

  private int pos_;
  private int length_;
  private string s_;

  public this(string s) {
    s_ = s;
    length_ = s.length;
  }

  public override void close() {
    s_ = null;
    pos_ = 0;
    length_ = 0;
  }

  public override int peek() {
    return (pos_ == length_) ? -1 : s_[pos_];
  }

  public override int read() {
    return (pos_ == length_) ? -1 : s_[pos_++];
  }

  public override int read(char[] buffer, int index, int count) {
    int n = length_ - pos_;
    if (n > 0) {
      if (n > count)
        n = count;
      strncpy(buffer.ptr + index, s_.ptr + pos_, n);
      pos_ += n;
    }
    return n;
  }

  public override string readToEnd() {
    string s = (pos_ == 0) ? s_ : s_[pos_ .. length_];
    pos_ = length_;
    return s;
  }

}

private bool isStringOrCharArray(TypeInfo ti) {
  return cast(bool)(ti == typeid(string) 
    || ti == typeid(char[]));
}

private void resolveArgList(ref TypeInfo[] args, ref void* argptr, out string format) {
  if (args.length == 2 && args[0] == typeid(TypeInfo[]) && args[1] == typeid(va_list)) {
    args = va_arg!(TypeInfo[])(argptr);
    argptr = *cast(va_list*)argptr;

    if (args.length > 1 && isStringOrCharArray(args[0])) {
      format = va_arg!(string)(argptr);
      args = args[1 .. $];
    }

    if (args.length == 2 && args[0] == typeid(TypeInfo[]) && args[1] == typeid(va_list))
      resolveArgList(args, argptr, format);
  }
  else if (args.length > 1 && isStringOrCharArray(args[0])) {
    format = va_arg!(string)(argptr);
    args = args[1 .. $];
  }
}

public class StringWriter : Writer {

  private char[] sb_;
  private Encoding encoding_;

  public this() {
  }

  public override void write(...) {
    TypeInfo[] args = _arguments;
    void* argptr = _argptr;
    string fmt = null;

    resolveArgList(args, argptr, fmt);

    if (fmt == null && args.length == 1 && isStringOrCharArray(args[0])) {
      sb_ ~= va_arg!(string)(argptr);
    }
    else if (args.length > 0) {
      write(format(NumberFormat.current, (fmt == null) ? "{0}" : fmt, args, argptr));
    }
  }

  public override string toString() {
    return sb_.dup;
  }

  public override Encoding encoding() {
    if (encoding_ is null)
      encoding_ = new Utf8Encoding;
    return encoding_;
  }

}

public class StreamReader : Reader {

  private Stream stream_;
  private Encoding encoding_;
  private ubyte[] byteBuffer_;
  private bool closable_;

  public this(Stream stream, Encoding encoding = Encoding.UTF8) {
    stream_ = stream;
    encoding_ = encoding;
    byteBuffer_.length = 4096;
  }

  private this(Stream stream, Encoding encoding, bool closable) {
    stream_ = stream;
    encoding_ = encoding;
    closable_ = closable;
  }

}

public class StreamWriter : Writer {

  private Stream stream_;
  private Encoding encoding_;
  private bool closable_ = true;

  public this(Stream stream, Encoding encoding = Encoding.UTF8) {
    stream_ = stream;
    encoding_ = encoding;
  }

  public override void close() {
    if (closable_ && stream_ !is null) {
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
    string fmt = null;

    resolveArgList(args, argptr, fmt);

    if (fmt == null && args.length == 1 && isStringOrCharArray(args[0])) {
      string s = va_arg!(string)(argptr);
      ubyte[] bytes = encoding_.encode(s.dup);
      stream_.write(bytes);
    }
    else if (args.length > 0) {
      write(format(NumberFormat.current, (fmt == null) ? "{0}" : fmt, args, argptr));
    }
  }

  public override Encoding encoding() {
    return encoding_;
  }

  private this(Stream stream, Encoding encoding, bool closable) {
    stream_ = stream;
    encoding_ = encoding;
    closable_ = closable;
  }

}

private class ConsoleStream : Stream {

  private Handle handle_;

  public override void close() {
  }

  public override void flush() {
  }

  public override uint read(ubyte[] buffer) {
    return readBlock(buffer.ptr, buffer.length);
  }

  public override uint write(ubyte[] buffer) {
    return writeBlock(buffer.ptr, buffer.length);
  }

  public override ulong seek(long offset, SeekPos origin) {
    return 0;
  }

  protected override uint readBlock(void* buffer, uint size) {
    uint bytesRead = 0;
    ReadFile(handle_, buffer, size, bytesRead, null);
    return bytesRead;
  }

  protected override uint writeBlock(void* buffer, uint size) {
    uint bytesWritten = 0;
    WriteFile(handle_, buffer, size, bytesWritten, null);
    return bytesWritten;
  }

  package this(Handle handle) {
    handle_ = handle;
  }

}

public enum ConsoleColor {
  Black,
  DarkBlue,
  DarkGreen,
  DarkCyan,
  DarkRed,
  DarkMagenta,
  DarkYello,
  Gray,
  DarkGray,
  Blue,
  Green,
  Cyan,
  Red,
  Magenta,
  Yellow,
  White
}

public abstract final class Console {

  private static Writer out_;
  private static Handle outputHandle_;

  private static Writer error_;

  private static Reader input_;

  static ~this() {
    out_ = null;
    error_ = null;
  }

  public static void beep(uint frequency = 800, uint duration = 200) {
    Beep(frequency, duration);
  }

  public static void clear() {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    if (GetConsoleScreenBufferInfo(outputHandle, csbi)) {
      COORD coord;
      uint written;
      if (FillConsoleOutputCharacter(outputHandle, ' ', csbi.dwSize.X * csbi.dwSize.Y, coord, written)) {
        if (FillConsoleOutputAttribute(outputHandle, csbi.wAttributes, csbi.dwSize.X * csbi.dwSize.Y, coord, written))
          SetConsoleCursorPosition(outputHandle, coord);
      }
    }
  }

  public static void setCursorPosition(int left, int top) {
    SetConsoleCursorPosition(outputHandle, COORD(cast(short)left, cast(short)top));
  }

  public static void backgroundColor(ConsoleColor value) {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    if (GetConsoleScreenBufferInfo(outputHandle, csbi)) {
      ushort attribute = cast(ushort)(csbi.wAttributes & ~BACKGROUND_MASK);
      attribute |= cast(ushort)value << 4;
      SetConsoleTextAttribute(outputHandle, attribute);
    }
  }

  public static ConsoleColor backgroundColor() {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    if (!GetConsoleScreenBufferInfo(outputHandle, csbi))
      return ConsoleColor.Black;
    return cast(ConsoleColor)((csbi.wAttributes & BACKGROUND_MASK) >> 4);
  }

  public static void foregroundColor(ConsoleColor value) {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    if (GetConsoleScreenBufferInfo(outputHandle, csbi)) {
      ushort attribute = cast(ushort)(csbi.wAttributes & ~FOREGROUND_MASK);
      attribute |= cast(ushort)value;
      SetConsoleTextAttribute(outputHandle, attribute);
    }
  }

  public static ConsoleColor foregroundColor() {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    if (!GetConsoleScreenBufferInfo(outputHandle, csbi))
      return ConsoleColor.Gray;
    return cast(ConsoleColor)(csbi.wAttributes & FOREGROUND_MASK);
  }

  public static void cursorLeft(int value) {
    setCursorPosition(value, cursorTop);
  }

  public static int cursorLeft() {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    GetConsoleScreenBufferInfo(outputHandle, csbi);
    return csbi.dwCursorPosition.X;
  }

  public static void cursorTop(int value) {
    setCursorPosition(cursorLeft, value);
  }

  public static int cursorTop() {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    GetConsoleScreenBufferInfo(outputHandle, csbi);
    return csbi.dwCursorPosition.Y;
  }

  public static void title(string value) {
    SetConsoleTitle(value.toUtf16z());
  }

  public static string title() {
    wchar[24500] buffer;
    uint len = GetConsoleTitle(buffer.ptr, buffer.length);
    return .toUtf8(buffer.ptr, 0, len);
  }

  public static void outputEncoding(Encoding value) {
    if (value is null)
      throw new ArgumentNullException("value");
    synchronized {
      out_ = null;

      SetConsoleOutputCP(cast(uint)value.codePage);
    }
  }

  public static Encoding outputEncoding() {
    return Encoding.get(GetConsoleOutputCP());
  }

  public static void write(...) {
    Console.output.write(_arguments, _argptr);
  }

  public static void writeln(...) {
    Console.output.writeln(_arguments, _argptr);
  }

  public static int read() {
    return input.read();
  }

  public static Reader input() {
    synchronized {
      if (input_ is null) {
        Stream s = new ConsoleStream(GetStdHandle(STD_INPUT_HANDLE));
        input_ = new StreamReader(s, Encoding.get(GetConsoleCP()), false);
      }
      return input_;
    }
  }

  public static Writer output() {
    synchronized {
      if (out_ is null) {
        Stream s = new ConsoleStream(GetStdHandle(STD_OUTPUT_HANDLE));
        out_ = new StreamWriter(s, Encoding.get(GetConsoleOutputCP()), false);
      }
      return out_;
    }
  }

  public static Writer error() {
    synchronized {
      if (error_ is null) {
        Stream s = new ConsoleStream(GetStdHandle(STD_ERROR_HANDLE));
        error_ = new StreamWriter(s, Encoding.get(GetConsoleOutputCP()), false);
      }
      return error_;
    }
  }

  private static Handle outputHandle() {
    if (outputHandle_ == Handle.init)
      outputHandle_ = GetStdHandle(STD_OUTPUT_HANDLE);
    return outputHandle_;
  }

}