/**
 * Copyright: (c) 2008 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.base.environment;

private import juno.base.core,
  juno.base.string,
  juno.base.native;

private static import std.gc;

string commandLine() {
  return .toUtf8(GetCommandLine());
}

string[] commandLineArgs() {
  int argc;
  wchar** argv = CommandLineToArgv(GetCommandLine(), argc);
  if (argc == 0) return null;

  string* a = cast(string*)std.gc.malloc(argc * string.sizeof);
  for (int i = 0; i < argc; i++) {
    a[i] = .toUtf8(argv[i]);
  }

  LocalFree(cast(Handle)argv);
  return a[0 .. argc];
}

void machineName(string value) {
  SetComputerName(value.toUtf16z());
}

string machineName() {
  wchar[256] buffer;
  uint size = buffer.length;

  if (!GetComputerName(buffer.ptr, size))
    throw new InvalidOperationException;

  return .toUtf8(buffer.ptr, 0, size);
}

string userName() {
  wchar[256] buffer;
  uint size = buffer.length;

  GetUserName(buffer.ptr, size);

  return .toUtf8(buffer.ptr, 0, size);
}

int tickCount() {
  return GetTickCount();
}

/**
 * Replaces the name of each environment variable embedded in the specified string with the string equivalent of the value of the variable.
 * Params: name = A string containing the names of zero or more environment variables. Environment variables are quoted with the percent sign.
 * Returns: A string with each environment variable replaced by its value.
 * Examples:
 * ---
 * writefln(expandEnvironmentVariables("My system drive is %SystemDrive% and my system root is %SystemRoot%"));
 * ---
 */
string expandEnvironmentVariables(string name) {
  string[] parts = name.split([ '%' ]);

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

  uint n = ExpandEnvironmentStrings(name.toUtf16z(), buffer.ptr, c);
  while (n > c) {
    c = n;
    buffer.length = c;
    n = ExpandEnvironmentStrings(name.toUtf16z(), buffer.ptr, c);
  }

  return .toUtf8(buffer.ptr);
}