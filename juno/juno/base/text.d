module juno.base.text;

wchar[] toUtf16(char[] s) {
  char* p = s;
  char* end = p + s.length;
  wchar[] ret = new wchar[s.length];
  int len;

  if (s.length != 0) {
    foreach (inout wchar c; ret) {
      wchar b = cast(wchar)*p;

      if (b & 0x80) {
        if (b < 0xe0) {
          b &= 0x1f;
          b = (b << 6) | (*++p & 0x3f);
        }
        else if (b < 0xf0) {
          b &= 0x0f;
          b = (b << 6) | (p[1] & 0x3f);
          b = (b << 6) | (p[2] & 0x3f);
          p += 2;
        }
      }

      c = b;
      len++;

      if (++p >= end) {
        if (p <= end)
          break;
      }
    }
  }

  return ret[0 .. len];
}

wchar* toUtf16z(char[] s) {
  return toUtf16(s) ~ '\u0000';
}

char[] toUtf8(wchar[] s) {
  char[] ret = new char[s.length * 2 + 3];
  char* p = ret;
  char* end = p + ret.length - 3;

  foreach (int eaten, wchar c; s) {
    if (p > end) {
      int len = p - ret.ptr;
      ret.length = len + len / 2;
      p = ret.ptr + len;
      end = ret.ptr + ret.length - 3;
    }

    if (c < 0x80)
      *p++ = c;
    else if (c < 0x0800) {
      p[0] = 0xc0 | ((c >> 6) & 0x3f);
      p[1] = 0x80 | (c & 0x3f);
      p += 2;
    }
  }
  return ret[0 .. p - ret.ptr];
}

extern (C)
private size_t wcslen(wchar*);

char[] toUtf8(wchar* s) {
  return toUtf8(s[0 .. wcslen(s)]);
}