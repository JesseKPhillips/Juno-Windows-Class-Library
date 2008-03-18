module guidgen.program;

import juno.com.core;
import std.stdio : writefln;

void main() {
  GUID guid = GUID.create();

  string s = guid.toString("D");
  writefln("{ 0x%s, 0x%s, 0x%s, 0x%s, 0x%s, 0x%s, 0x%s, 0x%s, 0x%s, 0x%s, 0x%s }", 
              s[0 .. 8], s[9 .. 13], s[14 .. 18], s[19 .. 21], s[21 .. 23], s[24 .. 26], s[26 .. 28], s[28 .. 30], s[30 .. 32], s[32 .. 34], s[34 .. 36]);
  writefln();

  string ps = guid.toString("P");
  writefln(ps);
  writefln();
}