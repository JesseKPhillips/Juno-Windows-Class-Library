module juno.base.environment;

private import juno.base.core,
  juno.base.string,
  juno.base.native;

private static import std.gc;

public string commandLine() {
  wchar* cmdLine = GetCommandLine();
  return .toUtf8(cmdLine);
}

public string[] commandLineArgs() {
  int argc = 0;
  wchar** argv = CommandLineToArgv(GetCommandLine(), argc);
  if (argc == 0) return null;
  string* a = cast(string*)std.gc.malloc(argc * string.sizeof);
  for (int i = 0; i < argc; i++) {
    a[i] = .toUtf8(argv[i]);
  }
  LocalFree(cast(Handle)argv);
  return a[0 .. argc];
}

public static void machineName(string value) {
  SetComputerName(value.toUtf16z());
}

public string machineName() {
  wchar[256] buffer;
  uint size = buffer.length;
  if (!GetComputerName(buffer.ptr, size))
    throw new InvalidOperationException;
  return .toUtf8(buffer.ptr, 0, size);
}

public string userName() {
  wchar[256] buffer;
  uint size = buffer.length;
  GetUserName(buffer.ptr, size);
  return .toUtf8(buffer.ptr, 0, size - 1);
}

public int tickCount() {
  return GetTickCount();
}

public string expandEnvironmentVariables(string name) {
  string[] parts = name.split(['%']);

  int c = 100;
  wchar[] buffer = new wchar[c];
  for (int i = 1; i < parts.length - 1; i++) {
    if (parts[i].length > 0) {
      string temp = "%" ~ parts[i] ~ "%";
      uint n = ExpandEnvironmentStrings(temp.toUtf16z(), buffer.ptr, c);
      while (n > c) {
        c = n;
        buffer.length = c;
        n = ExpandEnvironmentStrings(temp.toUtf16z(), buffer.ptr, c);
      }
    }
  }
  int n = ExpandEnvironmentStrings(name.toUtf16z(), buffer.ptr, c);
  while (n > c) {
    c = n;
    buffer.length = c;
    n = ExpandEnvironmentStrings(name.toUtf16z(), buffer.ptr, c);
  }

  return .toUtf8(buffer.ptr);
}