module juno.io.core;

private import juno.base.core,
  juno.base.string,
  juno.base.text,
  juno.base.win32,
  juno.io.streams;
private import std.stream : Stream, SeekPos;
private static import std.utf;

package class ConsoleStream : Stream {

  private Handle handle_;

  public override void close() {
  }

  public override void flush() {
  }

  public override uint read(ubyte[] buffer) {
    return readBlock(buffer, buffer.length);
  }

  public override uint write(ubyte[] buffer) {
    return writeBlock(buffer, buffer.length);
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

public enum ConsoleColour {
  Black,
  DarkBlue,
  DarkGreen,
  DarkCyan,
  DarkRed,
  DarkMagenta,
  DarkYellow,
  Grey,
  DarkGrey,
  Blue,
  Green,
  Cyan,
  Red,
  Magenta,
  Yellow,
  White
}

public enum ConsoleSpecialKey {
  ControlC,
  ControlBreak
}

// std.stdio.writef(ln) just wraps the C I/O handle and doesn't handle the Win32 console's code page. Therefore, non-ASCII characters 
// may not display correctly.
// This class encodes and decodes UTF text according to the console's code page and has a bunch of extra functionality for displaying 
// output in the console, such as settings colours.
public final class Console {
  
  private static Object syncObject_;
  private static StreamWriter out_;
  private static StreamWriter error_;
  private static Handle consoleOutputHandle_;
  private static bool delegate(ConsoleSpecialKey) controlHandler_;

  static this() {
    syncObject_ = new Object;
  }

  static ~this() {
    out_ = null;
    error_ = null;
  }

  public static void beep(uint frequency = 800, uint duration = 200) {
    return .Beep(frequency, duration);
  }

  public static void clear() {
    Handle outputHandle = consoleOutputHandle;
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    if (getBuffer(csbi)) {
      COORD pos;
      if (FillConsoleOutputCharacter(outputHandle, ' ', csbi.dwSize.X * csbi.dwSize.Y, pos, null)) {
        if (FillConsoleOutputAttribute(outputHandle, csbi.wAttributes, csbi.dwSize.X * csbi.dwSize.Y, pos, null))
          SetConsoleCursorPosition(outputHandle, pos);
      }
    }
  }

  public static void cancelKeyPress(bool delegate(ConsoleSpecialKey) handler) {

    extern (Windows)
    static bool breakEvent(uint ctrlType) {
      if ((ctrlType != CTRL_C_EVENT && ctrlType != CTRL_BREAK_EVENT) || controlHandler_ == null)
        return false;
      ConsoleSpecialKey key = (ctrlType == CTRL_C_EVENT) ? ConsoleSpecialKey.ControlC : ConsoleSpecialKey.ControlBreak;
      return controlHandler_(key);
    }

    controlHandler_ = handler;
    if (handler == null)
      SetConsoleCtrlHandler(&breakEvent, false);
    else
      SetConsoleCtrlHandler(&breakEvent, true);
  }

  public static void setCursorPosition(int left, int top) {
    COORD pos;
    pos.X = cast(short)left;
    pos.Y = cast(short)top;
    SetConsoleCursorPosition(consoleOutputHandle, pos);
  }

  public static void write(...) {
    Console.stdout.write(_arguments, _argptr);
  }

  public static void writeln(...) {
    Console.stdout.writeln(_arguments, _argptr);
  }

  public static ConsoleColour foregroundColour() {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    if (getBuffer(csbi))
      return cast(ConsoleColour)cast(ushort)(csbi.wAttributes & 15);
    return ConsoleColour.Grey;
  }
  public static void foregroundColour(ConsoleColour value) {
    ushort colour = cast(ushort)value;
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    if (getBuffer(csbi))
      SetConsoleTextAttribute(consoleOutputHandle, cast(ushort)((csbi.wAttributes & ~15) | colour));
  }

  public static ConsoleColour backgroundColour() {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    if (getBuffer(csbi))
      return cast(ConsoleColour)(cast(ushort)(csbi.wAttributes & 240) >> 4);
    return ConsoleColour.Black;
  }
  public static void backgroundColour(ConsoleColour value) {
    ushort colour = cast(ushort)(value << 4);
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    if (getBuffer(csbi))
      SetConsoleTextAttribute(consoleOutputHandle, cast(ushort)((csbi.wAttributes & ~240) | colour));
  }

  public static char[] title() {
    wchar[24500 + 1] buffer;
    uint len = GetConsoleTitle(buffer, buffer.length);
    if (len == 0)
      return "";
    return std.utf.toUTF8(buffer[0 .. len]);
  }
  public static void title(char[] value) {
    SetConsoleTitle(std.utf.toUTF16z(value));
  }

  public static StreamWriter stdout() {
    synchronized(syncObject_) {
      if (out_ is null) {
        Stream s = new ConsoleStream(GetStdHandle(STD_OUTPUT_HANDLE));
        out_ = new StreamWriter(s, Encoding.getEncoding(GetConsoleOutputCP()));
      }
      return out_;
    }
  }

  public static StreamWriter stderr() {
    synchronized(syncObject_) {
      if (error_ is null) {
        Stream s = new ConsoleStream(GetStdHandle(STD_ERROR_HANDLE));
        error_ = new StreamWriter(s, Encoding.getEncoding(GetConsoleOutputCP()));
      }
      return error_;
    }
  }

  private static bool getBuffer(out CONSOLE_SCREEN_BUFFER_INFO buffer) {
    Handle handle = consoleOutputHandle;
    if (handle == INVALID_HANDLE_VALUE)
      return false;
    return GetConsoleScreenBufferInfo(handle, buffer);
  }

  private static Handle consoleOutputHandle() {
    if (consoleOutputHandle_ == Handle.init)
      consoleOutputHandle_ = GetStdHandle(STD_OUTPUT_HANDLE);
    return consoleOutputHandle_;
  }

}