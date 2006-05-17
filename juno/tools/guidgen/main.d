import juno.com.all,
  std.stdio;

private char[] formatGuid(GUID guid) {

  void hexToChars(inout char[] chars, uint a, uint b = -1) {

    char hexToChar(uint a) {
      a = a & 0xf;
      return cast(char)((a > 9) ? a - 10 + 0x61 : a + 0x30);
    }

    chars ~= hexToChar(a >> 4);
    chars ~= hexToChar(a);
    if (b != -1) {
    chars ~= hexToChar(b >> 4);
    chars ~= hexToChar(b);
    }
  }

  char[] chars = "{ 0x";
  hexToChars(chars, guid.a >> 24, guid.a >> 16);
  hexToChars(chars, guid.a >> 8, guid.a);
  chars ~= ", 0x";
  hexToChars(chars, guid.b >> 8, guid.b);
  chars ~= ", 0x";
  hexToChars(chars, guid.c >> 8, guid.c);
  chars ~= ", 0x";
  hexToChars(chars, guid.d);
  chars ~= ", 0x";
  hexToChars(chars, guid.e);
  chars ~= ", 0x";
  hexToChars(chars, guid.f);
  chars ~= ", 0x";
  hexToChars(chars, guid.g);
  chars ~= ", 0x";
  hexToChars(chars, guid.h);
  chars ~= ", 0x";
  hexToChars(chars, guid.i);
  chars ~= ", 0x";
  hexToChars(chars, guid.j);
  chars ~= ", 0x";
  hexToChars(chars, guid.k);
  chars ~= " }";
  return chars;
}

void main() {
  GUID guid = GUID.newGuid();
  writefln(guid.toString());
  writefln(formatGuid(guid));
}