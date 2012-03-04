/**
 * Copyright: (c) 2009 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.io.core;

import juno.base.core,
  juno.base.string,
  juno.base.text,
  juno.base.native,
  core.vararg,
  std.stream;
debug import std.stdio : writefln;

enum FileAttributes {
  ReadOnly            = 0x00000001,
  Hidden              = 0x00000002,
  System              = 0x00000004,
  Directory           = 0x00000010,
  Archive             = 0x00000020,
  Device              = 0x00000040,
  Normal              = 0x00000080,
  Temporary           = 0x00000100,
  SparseFile          = 0x00000200,
  ReparsePoint        = 0x00000400,
  Compressed          = 0x00000800,
  Offline             = 0x00001000,
  NotContentIndexed   = 0x00002000,
  Encrypted           = 0x00004000,
  Virtual             = 0x00010000
}

package void ioError(uint errorCode, string path) {

  string getErrorMessage(uint errorCode) {
    wchar[256] buffer;
    uint result = FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM, null, errorCode, 0, buffer.ptr, buffer.length + 1, null);
    if (result != 0)
      return .toUtf8(buffer[0 .. result].ptr);
    return std.string.format("Unspecified error (0x%08X)", errorCode);
  }

  switch (errorCode) {
    case ERROR_FILE_NOT_FOUND:
      throw new FileNotFoundException(getErrorMessage(errorCode), path);
    default:
      throw new IOException(getErrorMessage(errorCode));
  }
}

class IOException : Exception {

  private static const E_IO = "I/O error occurred.";

  this() {
    super(E_IO);
  }

  this(string message) {
    super(message);
  }

}

class FileNotFoundException : Exception {

  private static const E_FILENOTFOUND = "Unable to find the specified file.";

  private string fileName_;

  this() {
    super(E_FILENOTFOUND);
  }

  this(string message) {
    super(message);
  }

  this(string message, string fileName) {
    super(message);
    fileName_ = fileName;
  }

  final string fileName() {
    return fileName_;
  }

}

/**
 * Represents a reade that can read a sequential series of characters.
 */
abstract class Reader {

  protected this() {
  }

  ~this() {
    close();
  }

  /**
   * Closes the Reader and releases any resources associated with the Reader.
   */
  void close() {
  }

  /**
   * Reads the next character from the input stream and advances the character position by one character.
   * Returns: The next character from the input stream, or char.init if no more characters are available.
   */
  char read() {
    return char.init;
  }

  /**
   * Reader a maximum of count characters from the input stream and writes the data to buffer, beginning at index.
   * Params:
   *   buffer = A character array with the values between index and (index + count - 1) replaces by the characters _read from the input stream.
   *   index = The place in buffer at which to begin writing.
   *   count = The maximum number of character to _read.
   * Returns: The number of characters that have been _read.
   */
  int read(char[] buffer, int index, int count) {
    int n = 0;
    do {
      char ch = read();
      if (ch == char.init)
        break;
      buffer[index + n++] = ch;
    } while (n < count);
    return n;
  }

  /**
   * Reads all characters from the current position to the end of the Reader and returns them as a string.
   * Returns: A string containing all characters.
   */
  string readToEnd() {
    string s;
    char[] buffer = new char[4096];
    int len;
    while ((len = read(buffer, 0, buffer.length)) != 0) {
      s ~= buffer[0 .. len];
    }
    return s;
  }

}

/**
 * Represents a writer that can write a sequential series of characters.
 */
abstract class Writer {

  protected string newLine_ = [ '\r', '\n' ];

  protected this() {
  }

  ~this() {
    close();
  }

  /**
   * Closes the current writer and releases any resources associated with the writer.
   */
  void close() {
  }

  /**
   * Clears all buffers for the current writer causing buffered data to be written to the underlying device.
   */
  void flush() {
  }

  /**
   * Writes the text representation of the specified value or values to the stream.
   */
  void write(...) {
  }

  /**
   * Writes the text representation of the specified value or values, followed by a line terminator, to the stream.
   */
  void writeln(...) {
    write(_arguments, _argptr);
    write(newLine);
  }

  /**
   * Gets or sets the line terminator used by the current writer.
   */
  @property void newLine(string value) {
    if (value == null)
      value = "\r\n";
    newLine_ = value.idup;
  }

  /// ditto
  @property string newLine() {
    return newLine_.idup;
  }

  /**
   * Gets the _encoding in which the output is written.
   */
  @property abstract Encoding encoding();

}

private void resolveArgList(ref TypeInfo[] args, ref va_list argptr, out string format) {
  if (args.length == 2 && args[0] == typeid(TypeInfo[]) && args[1] == typeid(va_list)) {
    args = va_arg!(TypeInfo[])(argptr);
    argptr = *cast(va_list*)argptr;

    if (args.length > 1 && args[0] == typeid(string)) {
      format = va_arg!(string)(argptr);
      args = args[1 .. $];
    }

    if (args.length == 2 && args[0] == typeid(TypeInfo[]) && args[1] == typeid(va_list)) {
      resolveArgList(args, argptr, format);
    }
  }
  else if (args.length > 1 && args[0] == typeid(string)) {
    format = va_arg!(string)(argptr);
    args = args[1 .. $];
  }
}

/**
 * Implements a Writer for writing information to a string.
 */
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
      write(format((fmt == null) ? "{0}" : fmt, args, argptr));
    }
  }

  /**
   * Returns a string containing the characters written to so far.
   */
  override string toString() {
    return sb_;
  }

  @property override Encoding encoding() {
    if (encoding_ is null)
      encoding_ = new Utf8Encoding;
    return encoding_;
  }

}

/**
 * Implements a Writer for writing characters to a stream in a particular encoding.
 */
class StreamWriter : Writer {

  private Stream stream_;
  private Encoding encoding_;
  private bool closable_ = true;

  /**
   * Initializes a new instance for the specified _stream, using the specified _encoding.
   * Params:
   *   stream = The _stream to write to.
   *   encoding = The character _encoding to use.
   */
  this(Stream stream, Encoding encoding = Encoding.UTF8()) {
    stream_ = stream;
    encoding_ = encoding;
  }

  package this(Stream stream, Encoding encoding, bool closable) {
    this(stream, encoding);
    closable_ = closable;
  }

  override void close() {
    if (closable_ && stream_ !is null) {
      try {
        stream_.close();
      }
      finally {
        stream_ = null;
      }
    }
  }

  override void write(...) {
    auto args = _arguments;
    auto argptr = _argptr;
    string fmt = null;
    resolveArgList(args, argptr, fmt);

    if (fmt == null && args.length == 1 && args[0] == typeid(string)) {
      ubyte[] bytes = encoding_.encode(va_arg!(string)(argptr));
      stream_.write(bytes);
    }
    else if (args.length > 0) {
      write(format((fmt == null) ? "{0}" : fmt, args, argptr));
    }
  }

  /**
   * Gets the underlying stream.
   */
  Stream baseStream() {
    return stream_;
  }

  override Encoding encoding() {
    return encoding_;
  }

}

private class ConsoleStream : Stream {

  private Handle handle_;

  package this(Handle handle) {
    handle_ = handle;
  }

  override void close() {
  }

  override void flush() {
  }

  override ulong seek(long offset, SeekPos origin) {
    return 0;
  }

  protected override size_t readBlock(void* buffer, size_t size) {
    uint bytesRead = 0;
    ReadFile(handle_, buffer, size, bytesRead, null);
    return bytesRead;
  }

  protected override size_t writeBlock(in void* buffer, size_t size) {
    uint bytesWritten = 0;
    WriteFile(handle_, buffer, size, bytesWritten, null);
    return bytesWritten;
  }

}

/// Specifies constants that define background and foreground colors for the console.
enum ConsoleColor {
  Black,        /// The color black.
  DarkBlue,     /// The color dark blue.
  DarkGreen,    /// The color dark green.
  DarkCyan,     /// The color dark cyan.
  DarkRed,      /// The color dark red.
  DarkMagenta,  /// The color dark magenta.
  DarkYellow,   /// The color dark yellow.
  Gray,         /// The color gray.
  DarkGray,     /// The color dark gray.
  Blue,         /// The color blue.
  Green,        /// The color green.
  Cyan,         /// The color cyan.
  Red,          /// The color red.
  Magenta,      /// The color magenta.
  Yellow,       /// The color yellow.
  White         /// The color white.
}

/**
 * Represents the standard output and error streams for console applications.
 */
struct Console {

  private static Writer out_;
  private static Writer err_;

  private static bool defaultColorsRead_;
  private static ubyte defaultColors_;

  private static Handle outputHandle_;

  static ~this() {
    out_ = null;
    err_ = null;
  }

  /**
   * Writes the text representation of the specified value or values to the standard output stream.
   */
  static void write(...) {
    Console.output.write(_arguments, _argptr);
  }

  /**
   * Writes the text representation of the specified value or values, followed by the current line terminator, to the standard output stream.
   */
  static void writeln(...) {
    Console.output.writeln(_arguments, _argptr);
  }

  /**
   * Gets the standard _output stream.
   */
  static @property Writer output() {
    synchronized {
      if (out_ is null) {
        Stream s = new ConsoleStream(GetStdHandle(STD_OUTPUT_HANDLE));
        out_ = new StreamWriter(s, Encoding.get(GetConsoleOutputCP()), false);
      }
      return out_;
    }
  }

  /**
   * Sets the output property to the specified Writer object.
   * Params: newOutput = The new standard output.
   */
  static void setOutput(Writer newOutput) {
    synchronized {
      out_ = newOutput;
    }
  }

  /**
   * Gets or sets the encoding the console uses to write output.
   * Params: value = The encoding used to write console output.
   */
  static @property void outputEncoding(Encoding value) {
    if (value is null)
      throw new ArgumentNullException("value");

    synchronized {
      out_ = null;
      SetConsoleOutputCP(cast(uint)value.codePage);
    }
  }
  /// ditto
  static @property Encoding outputEncoding() {
    return Encoding.get(GetConsoleOutputCP());
  }

  /**
   * Gets the standard _error output stream.
   */
  static @property Writer error() {
    synchronized {
      if (err_ is null) {
        Stream s = new ConsoleStream(GetStdHandle(STD_ERROR_HANDLE));
        err_ = new StreamWriter(s, Encoding.get(GetConsoleOutputCP()), false);
      }
      return err_;
    }
  }

  /**
   * Sets the error property to the specified Writer object.
   * Params: newError = The new standard error output.
   */
  static void setError(Writer newError) {
    synchronized {
      err_ = newError;
    }
  }

  /**
   * Clears the console buffer and corresponding console window of display information.
   */
  static void clear() {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    if (getBufferInfo(csbi)) {
      COORD coord;
      uint written;
      if (FillConsoleOutputCharacter(outputHandle, ' ', csbi.dwSize.X * csbi.dwSize.Y, coord, written)) {
        if (FillConsoleOutputAttribute(outputHandle, csbi.wAttributes, csbi.dwSize.X * csbi.dwSize.Y, coord, written))
          SetConsoleCursorPosition(outputHandle, coord);
      }
    }
  }

  /**
   * Plays the sound of a _beep of a specified _frequency and _duration through the console speaker.
   * Params:
   *   frequency = The _frequency of the _beep, ranging from 37 to 32767 hertz.
   *   duration = The _duration of the _beep measured in milliseconds.
   */
  static void beep(int frequency = 800, int duration = 200) {
    .Beep(cast(uint)frequency, cast(uint)duration);
  }

  /**
   * Gets or sets the _title to display in the console _title bar.
   * Params: value = The text to be displayed in the _title bar of the console.
   */
  static @property void title(string value) {
    SetConsoleTitle(value.toUtf16z());
  }
  /// ditto
  static @property string title() {
    wchar[24500] buffer;
    uint len = GetConsoleTitle(buffer.ptr, buffer.length);
    return .toUtf8(buffer.ptr, 0, len);
  }

  /**
   * Gets or sets the background color of the console.
   * Params: value = The color that appears behind each character.
   */
  static @property void backgroundColor(ConsoleColor value) {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    if (getBufferInfo(csbi)) {
      ushort attribute = cast(ushort)(csbi.wAttributes & ~BACKGROUND_MASK);
      attribute |= cast(ushort)value << 4;
      SetConsoleTextAttribute(outputHandle, attribute);
    }
  }
  /// ditto
  static @property ConsoleColor backgroundColor() {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    if (!getBufferInfo(csbi))
      return ConsoleColor.Black;
    return cast(ConsoleColor)((csbi.wAttributes & BACKGROUND_MASK) >> 4);
  }

  /**
   * Gets or sets the foreground color of the console.
   * Params: value = The color of each character that is displayed.
   */
  static @property void foregroundColor(ConsoleColor value) {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    if (getBufferInfo(csbi)) {
      ushort attribute = cast(ushort)(csbi.wAttributes & ~FOREGROUND_MASK);
      attribute |= cast(ushort)value;
      SetConsoleTextAttribute(outputHandle, attribute);
    }
  }
  /// ditto
  static @property ConsoleColor foregroundColor() {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    if (!getBufferInfo(csbi))
      return ConsoleColor.Gray;
    return cast(ConsoleColor)(csbi.wAttributes & FOREGROUND_MASK);
  }

  /**
   * Sets the foreground and background console colors to their defaults.
   */
  static void resetColor() {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    if (getBufferInfo(csbi))
      SetConsoleTextAttribute(outputHandle, defaultColors_);
  }

  /**
   * Sets the position of the cursor.
   * Params:
   *   left = The column position.
   *   top = The row position.
   */
  static void setCursorPosition(int left, int top) {
    SetConsoleCursorPosition(outputHandle, COORD(cast(short)left, cast(short)top));
  }

  /**
   * Gets or sets the column position of the cursor.
   */
  static @property void cursorLeft(int value) {
    setCursorPosition(value, cursorTop);
  }
  /// ditto
  static @property int cursorLeft() {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    getBufferInfo(csbi);
    return csbi.dwCursorPosition.X;
  }

  /**
   * Gets or sets the row position of the cursor.
   */
  static @property void cursorTop(int value) {
    setCursorPosition(cursorLeft, value);
  }
  /// ditto
  static @property int cursorTop() {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    getBufferInfo(csbi);
    return csbi.dwCursorPosition.Y;
  }

  /**
   * Gets or sets the left position of the console window area relative to the screen buffer.
   * Params: value = The left console window position measured in columns.
   */
  static @property void windowLeft(int value) {
    setWindowPosition(value, windowTop);
  }
  /// ditto
  static @property int windowLeft() {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    getBufferInfo(csbi);
    return csbi.srWindow.Left;
  }

  /**
   * Gets or sets the top position of the console window area relative to the screen buffer.
   * Params: value = The top console window position measured in rows.
   */
  static @property void windowTop(int value) {
    setWindowPosition(windowLeft, value);
  }
  /// ditto
  static @property int windowTop() {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    getBufferInfo(csbi);
    return csbi.srWindow.Top;
  }

  /**
   * Sets the position of the console window relative to the screen buffer.
   * Params:
   *   left = The column position of the upper-left corner.
   *   top = The row position of the upper-left corner.
   */
  static void setWindowPosition(int left, int top) {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    getBufferInfo(csbi);

    SMALL_RECT rect = csbi.srWindow;
    rect.Bottom -= rect.Top - top;
    rect.Right -= rect.Left - left;
    rect.Left = cast(short)left;
    rect.Top = cast(short)top;

    SetConsoleWindowInfo(outputHandle, 1, rect);
  }

  /**
   * Sets the size of the console window.
   * Params:
   *   width = The _width of the console window measured in columns.
   *   height = The _height of the console window measured in rows.
   */
  static void setWindowSize(int width, int height) {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    getBufferInfo(csbi);

    bool resizeBuffer;

    COORD size = COORD(csbi.dwSize.X, csbi.dwSize.Y);
    if (csbi.dwSize.X < csbi.srWindow.Left + width) {
      size.X = cast(short)(csbi.srWindow.Left + width);
      resizeBuffer = true;
    }
    if (csbi.dwSize.Y < csbi.srWindow.Top + height) {
      size.Y = cast(short)(csbi.srWindow.Top + height);
      resizeBuffer = true;
    }
    if (resizeBuffer)
      SetConsoleScreenBufferSize(outputHandle, size);

    SMALL_RECT rect = csbi.srWindow;
    rect.Bottom = cast(short)(rect.Top + height - 1);
    rect.Right = cast(short)(rect.Left + width - 1);
    if (!SetConsoleWindowInfo(outputHandle, 1, rect)) {
      if (resizeBuffer)
        SetConsoleScreenBufferSize(outputHandle, csbi.dwSize);
    }
  }

  /**
   * Gets or sets the width of the console window.
   * Params: value = The width of the console window measured in columns.
   */
  static @property void windowWidth(int value) {
    setWindowSize(value, windowHeight);
  }
  /// ditto
  static @property int windowWidth() {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    getBufferInfo(csbi);
    return csbi.srWindow.Right - csbi.srWindow.Left + 1;
  }

  /**
   * Gets or sets the height of the console window.
   * Params: value = The height of the console window measured in rows.
   */
  static @property void windowHeight(int value) {
    setWindowSize(windowWidth, value);
  }
  /// ditto
  static @property int windowHeight() {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    getBufferInfo(csbi);
    return csbi.srWindow.Bottom - csbi.srWindow.Top + 1;
  }

  private static bool getBufferInfo(out CONSOLE_SCREEN_BUFFER_INFO csbi) {
    Handle h = outputHandle;
    if (h == INVALID_HANDLE_VALUE)
      return false;

    if (GetConsoleScreenBufferInfo(h, csbi)) {
      if (!defaultColorsRead_) {
        defaultColors_ = cast(ubyte)(csbi.wAttributes & (FOREGROUND_MASK | BACKGROUND_MASK));
        defaultColorsRead_ = true;
      }
      return true;
    }

    return false;
  }

  private @property static Handle outputHandle() {
    if (outputHandle_ == Handle.init)
      outputHandle_ = GetStdHandle(STD_OUTPUT_HANDLE);
    return outputHandle_;
  }

}
