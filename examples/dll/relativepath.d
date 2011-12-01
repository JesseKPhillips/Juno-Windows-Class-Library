import std.stdio;

import juno.base.native;

// Actual function name is "PathIsRelativeW"
extern (Windows)
alias DllImport!("shlwapi.dll", "PathIsRelative", int function(const wchar* path), CharSet.Auto) PathIsRelative;

void main() {
  writeln(PathIsRelative("file.txt"w.ptr));
}
