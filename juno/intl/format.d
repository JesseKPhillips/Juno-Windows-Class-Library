module juno.intl.format;

private import juno.base.core,
  juno.base.math,
  juno.intl.constants,
  juno.intl.core,
  juno.base.win32;
private import juno.base.string : strlen;

private char[] uintToString(uint value, int digits) {
  if (digits < 1)
    digits = 1;

  char[100] buffer;
  int n = 100;
  while (--digits >= 0 || value != 0) {
    buffer[--n] = value % 10 + '0';
    value /= 10;
  };

  return buffer[n .. $].dup;
}

private char[] intToString(int value, int digits, char[] negativeSign) {
  if (digits < 1)
    digits = 1;

  char[100] buffer;
  uint uv = (value >= 0) ? value : cast(uint)-value;
  int n = 100;
  while (--digits >= 0 || uv != 0) {
    buffer[--n] = uv % 10 + '0';
    uv /= 10;
  };

  if (value < 0) {
    for (int i = negativeSign.length - 1; i >= 0; i--)
      buffer[--n] = negativeSign[i];
  }

  return buffer[n .. $].dup;
}

private char[] intToHexString(uint value, int digits, char format) {
  if (digits < 1)
    digits = 1;

  char[100] buffer;
  int n = 100;
  while (--digits >= 0 || value != 0) {
    ulong v = value & 0xF;
    buffer[--n] = (v < 10) ? v + '0' : v + format - ('X' - 'A' + 10);
    value >>= 4;
  }

  return buffer[n .. $].dup;
}

private char[] ulongToString(ulong value, int digits) {
  if (digits < 1)
    digits = 1;

  char[100] buffer;
  int n = 100;
  while (--digits >= 0 || value != 0) {
    buffer[--n] = value % 10 + '0';
    value /= 10;
  };

  return buffer[n .. $].dup;
}

private char[] longToString(long value, int digits, char[] negativeSign) {
  if (digits < 1)
    digits = 1;

  char[100] buffer;
  ulong uv = (value >= 0) ? value : cast(ulong)-value;
  int n = 100;
  while (--digits >= 0 || uv != 0) {
    buffer[--n] = uv % 10 + '0';
    uv /= 10;
  };

  if (value < 0) {
    for (int i = negativeSign.length - 1; i >= 0; i--)
      buffer[--n] = negativeSign[i];
  }

  return buffer[n .. $].dup;
}

private char[] longToHexString(ulong value, int digits, char format) {
  if (digits < 1)
    digits = 1;

  char[100] buffer;
  int n = 100;
  while (--digits >= 0 || value != 0) {
    ulong v = value & 0xF;
    buffer[--n] = (v < 10) ? v + '0' : v + format - ('X' - 'A' + 10);
    value >>= 4;
  }

  return buffer[n .. $].dup;
}

private char parseFormatSpecifier(char[] format, out int length) {
  length = -1;
  char specifier = 'G';

  if (format != null) {
    int pos = 0;
    char c = format[pos];

    if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')) {
      specifier = c;

      pos++;
      if (pos == format.length)
        return specifier;
      c = format[pos];

      if (c >= '0' && c <= '9') {
        length = c - '0';

        pos++;
        if (pos == format.length)
          return specifier;
        c = format[pos];

        while (c >= '0' && c <= '9') {
          length = length * 10 + c - '0';

          pos++;
          if (pos == format.length)
            return specifier;
          c = format[pos];
        }
      }
    }
    return char.init;
  }
  return specifier;
}

public char[] formatUInt(uint value, char[] format, IProvidesFormat provider) {
  NumberFormat nf = NumberFormat.getInstance(provider);

  int length;
  char specifier = parseFormatSpecifier(format, length);

  switch (specifier) {
    case 'g': case 'G':
      if (length > 0)
        break;
      // fall through
    case 'd': case 'D':
      return uintToString(value, length);
    case 'x': case 'X':
      return intToHexString(value, length, specifier);
    default:
  }

  Number number = Number(cast(ulong)value);
  if (specifier != char.init)
    return number.toString(specifier, length, nf);
  return number.toStringFormat(format, nf);
}

public char[] formatInt(int value, char[] format, IProvidesFormat provider) {
  NumberFormat nf = NumberFormat.getInstance(provider);

  int length;
  char specifier = parseFormatSpecifier(format, length);

  switch (specifier) {
    case 'g': case 'G':
      if (length > 0)
        break;
      // fall through
    case 'd': case 'D':
      return intToString(value, length, nf.negativeSign);
    case 'x': case 'X':
      return intToHexString(cast(uint)value, length, specifier);
    default:
  }

  Number number = Number(cast(long)value);
  if (specifier != char.init)
    return number.toString(specifier, length, nf);
  return number.toStringFormat(format, nf);
}

public char[] formatULong(ulong value, char[] format, IProvidesFormat provider) {
  NumberFormat nf = NumberFormat.getInstance(provider);

  int length;
  char specifier = parseFormatSpecifier(format, length);

  switch (specifier) {
    case 'g': case 'G':
      if (length > 0)
        break;
      // fall through
    case 'd': case 'D':
      return ulongToString(value, length);
    case 'x': case 'X':
      return longToHexString(value, length, specifier);
    default:
  }

  Number number = Number(value);
  if (specifier != char.init)
    return number.toString(specifier, length, nf);
  return number.toStringFormat(format, nf);
}

public char[] formatLong(long value, char[] format, IProvidesFormat provider) {
  NumberFormat nf = NumberFormat.getInstance(provider);

  int length;
  char specifier = parseFormatSpecifier(format, length);

  switch (specifier) {
    case 'g': case 'G':
      if (length > 0)
        break;
      // fall through
    case 'd': case 'D':
      return longToString(value, length, nf.negativeSign);
    case 'x': case 'X':
      return longToHexString(cast(ulong)value, length, specifier);
    default:
  }

  Number number = Number(value);
  if (specifier != char.init)
    return number.toString(specifier, length, nf);
  return number.toStringFormat(format, nf);
}

public char[] formatFloat(float value, char[] format, IProvidesFormat provider) {

  // This should prevent the compiler from optimising away the double-to-float cast.
  void convertToFloat(double d, out float f) {
    f = cast(float)d;
  }

  NumberFormat nf = NumberFormat.getInstance(provider);
  int length;
  char specifier = parseFormatSpecifier(format, length);
  int precision = 7;

  switch (specifier) {
    // Round trip
    case 'r': case 'R':
      Number number = Number(value, 7);

      if (number.scale == NAN_FLAG)
        return nf.nanSymbol;
      if (number.scale == INFINITY_FLAG)
        return number.sign ? nf.negativeInfinitySymbol : nf.positiveInfinitySymbol;

      double d;
      number.toDouble(d);

      float f;
      convertToFloat(d, f);
      if (f == value)
        return number.toString('G', 7, nf);

      number = Number(value, 9);
      return number.toString('G', 9, nf);
    case 'e': case 'E':
      if (length > 6)
        precision = 9;
      break;
    case 'g': case 'G':
      if (length > 7)
        precision = 9;
      // Fall through.
    default:
      break;
  }

  Number number = Number(value, precision);

  if (number.scale == NAN_FLAG)
    return nf.nanSymbol;
  if (number.scale == INFINITY_FLAG)
    return number.sign ? nf.negativeInfinitySymbol : nf.positiveInfinitySymbol;

  if (specifier != char.init)
    return number.toString(specifier, length, nf);
  return number.toStringFormat(format, nf);
}

public char[] formatDouble(double value, char[] format, IProvidesFormat provider) {
  NumberFormat nf = NumberFormat.getInstance(provider);
  int length;
  char specifier = parseFormatSpecifier(format, length);
  int precision = 15;

  switch (specifier) {
    // Round trip
    case 'r': case 'R':
      Number number = Number(value, 15);

      if (number.scale == NAN_FLAG)
        return nf.nanSymbol;
      if (number.scale == INFINITY_FLAG)
        return number.sign ? nf.negativeInfinitySymbol : nf.positiveInfinitySymbol;

      double d;
      number.toDouble(d);
      if (d == value)
        return number.toString('G', 15, nf);

      number = Number(value, 17);
      return number.toString('G', 17, nf);
    case 'e': case 'E':
      if (length > 14)
        precision = 17;
      break;
    case 'g': case 'G':
      if (length > 15)
        precision = 17;
      // Fall through.
    default:
      break;
  }

  Number number = Number(value, precision);

  if (number.scale == NAN_FLAG)
    return nf.nanSymbol;
  if (number.scale == INFINITY_FLAG)
    return number.sign ? nf.negativeInfinitySymbol : nf.positiveInfinitySymbol;

  if (specifier != char.init)
    return number.toString(specifier, length, nf);
  return number.toStringFormat(format, nf);
}

public uint parseUInt(char[] s, NumberStyles style, NumberFormat format) {
  Number number = Number.fromString(s, style, format);
  long value;
  if (!number.toLong(value) || (value < uint.min || value > uint.max))
    throw new OverflowException("Value was either too large or too small for a uint.");
  return cast(uint)value;
}

public int parseInt(char[] s, NumberStyles style, NumberFormat format) {
  Number number = Number.fromString(s, style, format);
  long value;
  if (!number.toLong(value) || (value < int.min || value > int.max))
    throw new OverflowException("Value was either too large or too small for an int.");
  return cast(int)value;
}

public ulong parseULong(char[] s, NumberStyles style, NumberFormat format) {
  Number number = Number.fromString(s, style, format);
  long value;
  if (!number.toLong(value) || (value < ulong.min || value > ulong.max))
    throw new OverflowException("Value was either too large or too small for a ulong.");
  return cast(ulong)value;
}

public long parseLong(char[] s, NumberStyles style, NumberFormat format) {
  Number number = Number.fromString(s, style, format);
  long value;
  if (!number.toLong(value) || (value < long.min || value > long.max))
    throw new OverflowException("Value was either too large or too small for a long.");
  return value;
}

public float parseFloat(char[] s, NumberStyles style, NumberFormat format) {
  try {
    Number number = Number.fromString(s, style, format);
    double value;
    if (!number.toDouble(value))
      throw new OverflowException("Value was either too large or too small for a float.");
    float result = cast(float)value;
    if (isInfinity(result))
      throw new OverflowException("Value was either too large or too small for a float.");
    return result;
  }
  catch (FormatException e) {
    if (s == format.positiveInfinitySymbol)
      return float.infinity;
    else if (s == format.negativeInfinitySymbol)
      return -float.infinity;
    else if (s == format.nanSymbol)
      return float.nan;
    throw e;
  }
}

public double parseDouble(char[] s, NumberStyles style, NumberFormat format) {
  try {
    Number number = Number.fromString(s, style, format);
    double value;
    if (!number.toDouble(value))
      throw new OverflowException("Value was either too large or too small for a double.");
    return value;
  }
  catch (FormatException e) {
    if (s == format.positiveInfinitySymbol)
      return double.infinity;
    else if (s == format.negativeInfinitySymbol)
      return -double.infinity;
    else if (s == format.nanSymbol)
      return double.nan;
    throw e;
  }
}

private enum {
  NAN_FLAG = 0x80000000,
  INFINITY_FLAG = 0x7FFFFFFF,
  EXP = 0x07FF
}

extern (C)
private char* ecvt(double d, int digits, out int decpt, out int sign);

private struct Number {

  int precision;
  int scale;
  int sign;
  char[long.sizeof * 8] digits = void;

  static Number opCall(ulong value) {
    Number number;
    number.precision = 20;

    char[20] buffer;
    int n = buffer.length;
    while (value != 0) {
      buffer[--n] = value % 10 + '0';
      value /= 10;
    }

    int end = number.scale = -(n - buffer.length);
    number.digits[0 .. end] = buffer[n .. n + end];
    number.digits[end] = '\0';

    return number;
  }

  static Number opCall(long value) {
    Number number;
    number.precision = 20;
    if (value < 0) {
      number.sign = true;
      value = -value;
    }

    char[20] buffer;
    int n = buffer.length;
    while (value != 0) {
      buffer[--n] = value % 10 + '0';
      value /= 10;
    }

    int end = number.scale = -(n - buffer.length);
    number.digits[0 .. end] = buffer[n .. n + end];
    number.digits[end] = '\0';

    return number;
  }

  static Number opCall(double value, int precision) {
    Number number;
    number.precision = precision;

    char* p = number.digits;
    long bits = *cast(long*)&value;
    long mant = bits & 0x000FFFFFFFFFFFFF;
    int exp = cast(int)((bits >> 52) & EXP);

    if (exp == EXP) {
      number.scale = (mant != 0) ? NAN_FLAG : INFINITY_FLAG;
      if (((bits >> 63) & 1) != 0)
        number.sign = true;
    }
    else {
      // Get the digits, decimal point and sign.
      char* chars = ecvt(value, number.precision, number.scale, number.sign);
      if (*chars != '\0') {
        while (*chars != '\0')
          *p++ = *chars++;
      }
    }
    *p = '\0';

    return number;
  }

  void round(int pos) {
    int index;
    while (index < pos && digits[index] != '\0')
      index++;
    if (index == pos && digits[index] >= '5') {
      while (index > 0 && digits[index - 1] == '9')
        index--;
      if (index > 0)
        digits[index - 1]++;
      else {
        scale++;
        digits[0] = '1';
        index = 1;
      }
    }
    else while (index > 0 && digits[index - 1] == '0')
      index--;

    if (index == 0) {
      scale = 0;
      sign = false;
    }

    digits[index] = '\0';
  }

  private static Number fromString(char[] s, NumberStyles styles, NumberFormat nf) {
    Number number;
    if (!parseNumber(number, s, styles, nf))
      throw new FormatException("Input string was not valid.");
    return number;
  }
  
  private bool toLong(out long value) {
    int i = scale;
    if (i > 20 || i < precision)
      return false;

    long v = 0;
    char* p = digits.ptr;
    while (--i >= 0) {
      if (cast(ulong)v > (ulong.max / 10))
        return false;
      v *= 10;
      if (*p != '\0')
        v += *p++ - '0';
    }

    if (sign)
      v = -v;
    else if (v < 0)
      return false;

    value = v;
    return true;
  }

  private bool toDouble(out double value) {

    const ulong[] pow10 = [
      0xa000000000000000UL,
      0xc800000000000000UL,
      0xfa00000000000000UL,
      0x9c40000000000000UL,
      0xc350000000000000UL,
      0xf424000000000000UL,
      0x9896800000000000UL,
      0xbebc200000000000UL,
      0xee6b280000000000UL,
      0x9502f90000000000UL,
      0xba43b74000000000UL,
      0xe8d4a51000000000UL,
      0x9184e72a00000000UL,
      0xb5e620f480000000UL,
      0xe35fa931a0000000UL,
      0xcccccccccccccccdUL,
      0xa3d70a3d70a3d70bUL,
      0x83126e978d4fdf3cUL,
      0xd1b71758e219652eUL,
      0xa7c5ac471b478425UL,
      0x8637bd05af6c69b7UL,
      0xd6bf94d5e57a42beUL,
      0xabcc77118461ceffUL,
      0x89705f4136b4a599UL,
      0xdbe6fecebdedd5c2UL,
      0xafebff0bcb24ab02UL,
      0x8cbccc096f5088cfUL,
      0xe12e13424bb40e18UL,
      0xb424dc35095cd813UL,
      0x901d7cf73ab0acdcUL,
      0x8e1bc9bf04000000UL,
      0x9dc5ada82b70b59eUL,
      0xaf298d050e4395d6UL,
      0xc2781f49ffcfa6d4UL,
      0xd7e77a8f87daf7faUL,
      0xefb3ab16c59b14a0UL,
      0x850fadc09923329cUL,
      0x93ba47c980e98cdeUL,
      0xa402b9c5a8d3a6e6UL,
      0xb616a12b7fe617a8UL,
      0xca28a291859bbf90UL,
      0xe070f78d39275566UL,
      0xf92e0c3537826140UL,
      0x8a5296ffe33cc92cUL,
      0x9991a6f3d6bf1762UL,
      0xaa7eebfb9df9de8aUL,
      0xbd49d14aa79dbc7eUL,
      0xd226fc195c6a2f88UL,
      0xe950df20247c83f8UL,
      0x81842f29f2cce373UL,
      0x8fcac257558ee4e2UL,
    ];

    const uint[] pow10Exp = [ 
      4, 7, 10, 14, 17, 20, 24, 27, 30, 34, 
      37, 40, 44, 47, 50, 54, 107, 160, 213, 266, 
      319, 373, 426, 479, 532, 585, 638, 691, 745, 798, 
      851, 904, 957, 1010, 1064, 1117 ];

    uint getDigits(char* p, int len) {
      char* end = p + len;
      uint r = *p - '0';
      p++;
      while (p < end) {
        r = 10 * r + *p - '0';
        p++;
      }
      return r;
    }

    ulong mult64(uint val1, uint val2) {
      return cast(ulong)val1 * cast(ulong)val2;
    }

    ulong mult64L(ulong val1, ulong val2) {
      ulong v = mult64(cast(uint)(val1 >> 32), cast(uint)(val2 >> 32));
      v += mult64(cast(uint)(val1 >> 32), cast(uint)val2) >> 32;
      v += mult64(cast(uint)val1, cast(uint)(val2 >> 32)) >> 32;
      return v;
    }

    char* p = digits;
    int count = strlen(p);
    int left = count;

    while (*p == '0') {
      left--;
      p++;
    }
    // If the digits consist of nothing but zeros...
    if (left == 0) {
      value = 0.0;
      return true;
    }

    // Get digits, 9 at a time.
    int n = (left > 9) ? 9 : left;
    left -= n;
    ulong bits = getDigits(p, n);
    if (left > 0) {
      n = (left > 9) ? 9 : left;
      left -= n;
      bits = mult64(cast(uint)bits, cast(uint)(pow10[n - 1] >>> (64 - pow10Exp[n - 1])));
      bits += getDigits(p + 9, n);
    }

    int scale = this.scale - (count - left);
    int s = (scale < 0) ? -scale : scale;
    if (s >= 352) {
      *cast(long*)&value = (scale > 0) ? 0x7FF0000000000000 : 0;
      return false;
    }

    // Normalise mantissa and bits.
    int bexp = 64;
    int nzero;
    if ((bits >> 32) != 0)
      nzero = 32;
    if ((bits >> (16 + nzero)) != 0)
      nzero += 16;
    if ((bits >> (8 + nzero)) != 0)
      nzero += 8;
    if ((bits >> (4 + nzero)) != 0)
      nzero += 4;
    if ((bits >> (2 + nzero)) != 0)
      nzero += 2;
    if ((bits >> (1 + nzero)) != 0)
      nzero++;
    if ((bits >> nzero) != 0)
      nzero++;
    bits <<= 64 - nzero;
    bexp -= 64 - nzero;

    // Get decimal exponent.
    if ((s & 15) != 0) {
      int expMult = pow10Exp[(s & 15) - 1];
      bexp += (scale < 0) ? (-expMult + 1) : expMult;
      bits = mult64L(bits, pow10[(s & 15) + ((scale < 0) ? 15 : 0) - 1]);
      if ((bits & 0x8000000000000000) == 0) {
        bits <<= 1;
        bexp--;
      }
    }
    if ((s >> 4) != 0) {
      int expMult = pow10Exp[15 + ((s >> 4) - 1)];
      bexp += (scale < 0) ? (-expMult + 1) : expMult;
      bits = mult64L(bits, pow10[30 + ((s >> 4) + ((scale < 0) ? 21 : 0) - 1)]);
      if ((bits & 0x8000000000000000) == 0) {
        bits <<= 1;
        bexp--;
      }
    }
    
    // Round and scale.
    if (cast(uint)bits & (1 << 10) != 0) {
      bits += (1 << 10) - 1 + (bits >>> 11) & 1;
      bits >>= 11;
      if (bits == 0)
        bexp++;
    }
    else
      bits >>= 11;
    bexp += 1022;
    if (bexp <= 0) {
      if (bexp < -53)
        bits = 0;
      else
        bits >>= (-bexp + 1);
    }
    bits = (cast(ulong)bexp << 52) + (bits & 0x000FFFFFFFFFFFFF);

    if (sign)
      bits |= 0x8000000000000000;

    value = *cast(double*)&bits;
    return true;
  }

  char[] toString(char format, int length, NumberFormat nf) {
    char[] result;

    switch (format) {
      case 'f': case 'F':
        // Fixed
        if (length < 0)
          length = nf.numberDecimalDigits;
        round(scale + length);
        if (sign)
          result ~= nf.negativeSign;
        formatFixed(this, result, length, null, nf.numberDecimalSeparator, null);
        break;
      case 'n': case 'N':
        // Number
        if (length < 0)
          length = nf.numberDecimalDigits;
        round(scale + length);
        formatNumber(this, result, length, nf);
        break;
      case 'e': case 'E':
        // Scientific
        if (length < 0)
          length = 6;
        length++;
        round(length);
        if (sign)
          result ~= nf.negativeSign;
        formatScientific(this, result, length, format, nf);
        break;
      case 'g': case 'G':
        // General
        if (length < 0)
          length = precision;
        round(length);
        if (sign)
          result ~= nf.negativeSign;
        formatGeneral(this, result, length, (format == 'g') ? 'e' : 'E', nf);
        break;
      case 'c': case 'C':
        // Currency
        if (length < 0)
          length = nf.currencyDecimalDigits;
        round(scale + length);
        formatCurrency(this, result, length, nf);
        break;
      case 'p': case 'P':
        // Percent
        if (length < 0)
          length = nf.percentDecimalDigits;
        scale += 2;
        round(scale + length);
        formatPercent(this, result, length, nf);
        break;
      default:
        throw new FormatException("Invalid format specifier.");
    }

    return result;
  }

  char[] toStringFormat(char[] format, NumberFormat nf) {
    bool hasGroups = false, scientific = false;
    int groupCount = 0, groupPos = -1, pointPos = -1;
    int first = int.max, last = 0, count = 0, adjust;

    int n = 0;
    char c;
    while (n < format.length) {
      c = format[n++];
      switch (c) {
        case '#':
          count++;
          break;
        case '0':
          if (first == int.max)
            first = count;
          count++;
          last = count;
          break;
        case '%':
          adjust += 2;
          break;
        case '.':
          if (pointPos < 0)
            pointPos = count;
          break;
        case ',':
          if (count > 0 && pointPos < 0) {
            if (groupPos >= 0) {
              if (groupPos == count) {
                groupCount++;
                break;
              }
              hasGroups = true;
            }
            groupPos = count;
            groupCount = 1;
          }
          break;
        case '\'':
        case '\"':
          while (n < format.length && format[n++] != c) {}
          break;
        case '\\':
          if (n < format.length)
            n++;
          break;
        case 'e': case 'E':
          if (format[n] == '0' || format[n] == '+' || format[n] == '-') {
            if (n < format.length && format[n++] == '0') {}
            scientific = true;
          }
          break;
        default:
          break;
      }
    }

    if (pointPos < 0)
      pointPos = count;

    if (groupPos >= 0) {
      if (groupPos == pointPos)
        adjust -= groupCount * 3;
      else
        hasGroups = true;
    }

    if (digits[0] != '\0') {
      scale += adjust;
      round(scientific ? count : scale + count - pointPos);
    }

    first = (first < pointPos) ? pointPos - first : 0;
    last = (last > pointPos) ? pointPos - last : 0;

    int pos = pointPos;
    int extra = 0;
    if (!scientific) {
      pos = (scale > pointPos) ? scale : pointPos;
      extra = scale - pointPos;
    }

    char[] groupSeparator = nf.numberGroupSeparator;
    char[] decimalSeparator = nf.numberDecimalSeparator;

    int[] groupPositions;
    int groupIndex = -1;
    if (hasGroups) {
      if (nf.numberGroupSizes.length == 0)
        hasGroups = false;
      else {
        int groupSizesTotal = nf.numberGroupSizes[0];
        int groupSize = groupSizesTotal;
        int digitsTotal = pos + ((extra < 0) ? extra : 0);
        int digitCount = (first > digitsTotal) ? first : digitsTotal;

        int sizeIndex = 0;
        while (digitCount > groupSizesTotal) {
          if (groupSize == 0)
            break;
          groupPositions ~= groupSizesTotal;
          groupIndex++;
          if (sizeIndex < nf.numberGroupSizes.length - 1)
            groupSize = nf.numberGroupSizes[++sizeIndex];
          groupSizesTotal += groupSize;
        }
      }
    }

    char[] result;
    if (sign)
      result ~= nf.negativeSign;

    char* p = digits;
    n = 0;
    bool pointWritten = false;
    while (n < format.length) {
      c = format[n++];
      if (extra > 0 && (c == '#' || c == '0' || c == '.')) {
        while (extra > 0) {
          result ~= (*p != '\0') ? *p++ : '0';

          if (hasGroups && pos > 1 && groupIndex >= 0) {
            if (pos == groupPositions[groupIndex] + 1) {
              result ~= groupSeparator;
              groupIndex--;
            }
          }
          pos--;
          extra--;
        }
      }

      switch (c) {
        case '#':
        case '0':
          if (extra < 0) {
            extra++;
            c = (pos <= first) ? '0' : char.init;
          }
          else
            c = (*p != '\0') ? *p++ : (pos > last) ? '0' : char.init;

          if (c != char.init) {
            result ~= c;

            if (hasGroups && pos > 1 && groupIndex >= 0) {
              if (pos == groupPositions[groupIndex] + 1) {
                result ~= groupSeparator;
                groupIndex--;
              }
            }
          }
          pos--;
          break;
        case '%':
          result ~= nf.percentSymbol;
          break;
        case '.':
          if (pos != 0 || pointWritten)
            break;
          if (last < 0 || (pointPos < count && *p++ != '\0')) {
            result ~= decimalSeparator;
            pointWritten = true;
          }
          break;
        case ',':
          break;
        case '\'':
        case '\"':
          if (n < format.length)
            n++;
          break;
        case '\\':
          if (n < format.length)
            result ~= format[n++];
          break;
        case 'e': case 'E':
          char[] positiveSign;
          int length;
          if (scientific) {
            if (format[n] == '0')
              length++;
            else if (format[n] == '+' && (n + 1 < format.length && format[n + 1] == '0'))
              positiveSign = nf.positiveSign;
            else if (!(format[n] == '-' && (n + 1 < format.length && format[n + 1] == '0'))) {
              result ~= c;
              break;
            }
            n++;
            while (n < format.length) {
              if (format[n++] == '0')
                length++;
            }
            formatExponent(result, (digits[0] == '\0') ? 0 : scale - pointPos, c, positiveSign, nf.negativeSign, length);
            scientific = false;
          }
          else {
            result ~= c;
          }
          break;
        default:
          result ~= c;
          break;
      }
    }
    return result;
  }

}

// Must match NumberFormat.decimalPositivePattern
private const char[] positiveNumberFormat = "#";
// Must match NumberFormat.decimalNegativePattern
private const char[][] negativeNumberFormats = [ "(#)", "-#", "- #", "#-", "# -" ];
// Must match NumberFormat.currencyPositivePattern
private const char[][] positiveCurrencyFormats = [ "$#", "#$", "$ #", "# $" ];
// Must match NumberFormat.currencyNegativePattern
private const char[][] negativeCurrencyFormats = [ "($#)", "-$#", "$-#", "$#-", "(#$)", "-#$", "#-$", "#$-", "-# $", "-$ #", "# $-", "$ #-", "$ -#", "#- $", "($ #)", "(# $)" ];
// Must match NumberFormat.percentPositivePattern
private const char[][] positivePercentFormats = [ "# %", "#%", "%#", "% #" ];
// Must match NumberFormat.percentNegativePattern
private const char[][] negativePercentFormats = [ "-# %", "-#%", "-%#", "%-#", "%#-", "#-%", "#%-", "-% #", "# %-", "% #-", "% -#", "#- %" ];

private void formatGeneral(Number* number, inout char[] dst, int length, char format, NumberFormat nf) {
  int pos = number.scale;

  bool scientific = false;
  if (pos > length || pos < -3) {
    pos = 1;
    scientific = true;
  }

  char* p = number.digits;
  if (pos > 0) {
    while (pos > 0) {
      dst ~= (*p != '\0') ? *p++ : '0';
      pos--;
    }
  }
  else
    dst ~= '0';

  if (*p != '\0') {
    dst ~= nf.numberDecimalSeparator;
    while (pos < 0) {
      dst ~= '0';
      pos++;
    }
    while (*p != '\0')
      dst ~= *p++;
  }

  if (scientific)
    formatExponent(dst, number.scale - 1, format, nf.positiveSign, nf.negativeSign, 2);
}

private void formatNumber(Number* number, inout char[] dst, int length, NumberFormat nf) {
  char[] format = number.sign ? negativeNumberFormats[nf.currencyNegativePattern] : positiveNumberFormat;

  foreach (c; format) {
    switch (c) {
      case '#':
        formatFixed(number, dst, length, nf.numberGroupSizes, nf.numberDecimalSeparator, nf.numberGroupSeparator);
        break;
      case '-':
        dst ~= nf.negativeSign;
        break;
      default:
        dst ~= c;
        break;
    }
  }
}

private void formatPercent(Number* number, inout char[] dst, int length, NumberFormat nf) {
  char[] format = number.sign ? negativePercentFormats[nf.percentNegativePattern] : positivePercentFormats[nf.percentPositivePattern];

  foreach (c; format) {
    switch (c) {
      case '#':
        formatFixed(number, dst, length, nf.percentGroupSizes, nf.percentDecimalSeparator, nf.percentGroupSeparator);
        break;
      case '-':
        dst ~= nf.negativeSign;
        break;
      case '%':
        dst ~= nf.percentSymbol;
        break;
      default:
        dst ~= c;
        break;
    }
  }
}

private void formatScientific(Number* number, inout char[] dst, int length, char exponent, NumberFormat nf) {
  char* p = number.digits;
  dst ~= (*p != '\0') ? *p++ : '0';

  if (length != 1)
    dst ~= nf.numberDecimalSeparator;

  while (--length > 0)
    dst ~= (*p != '\0') ? *p++ : '0';

  formatExponent(dst, (number.digits[0] == '\0') ? 0 : number.scale - 1, exponent, nf.positiveSign, nf.negativeSign, 3);
}

private void formatCurrency(Number* number, inout char[] dst, int length, NumberFormat nf) {
  char[] format = number.sign ? negativeCurrencyFormats[nf.currencyNegativePattern] : positiveCurrencyFormats[nf.currencyPositivePattern];

  foreach (c; format) {
    switch (c) {
      case '#':
        formatFixed(number, dst, length, nf.currencyGroupSizes, nf.currencyDecimalSeparator, nf.currencyGroupSeparator);
        break;
      case '-':
        dst ~= nf.negativeSign;
        break;
      case '$':
        dst ~= nf.currencySymbol;
        break;
      default:
        dst ~= c;
        break;
    }
  }
}

private void formatFixed(Number* number, inout char[] dst, int length, int[] groupSizes, char[] decimalSeparator, char[] groupSeparator) {
  int pos = number.scale;
  char* p = number.digits;

  if (pos > 0) {
    if (groupSizes.length != 0) {
      // Calculate whether we have enough digits to format.
      int count = groupSizes[0];
      int index, size;
      while (pos > count) {
        size = groupSizes[index];
        if (size == 0)
          break;
        if (index < groupSizes.length - 1)
          index++;
        count += groupSizes[index];
      }
      size = (count == 0) ? 0 : groupSizes[0];

      // Now insert the separator at the positions specified by groupSizes.
      int end = strlen(p);
      int start = (pos < end) ? pos : end;
      char[] separator = groupSeparator.reverse;
      index = 0;
      char[] temp;

      for (int c, i = pos - 1; i >= 0; i--) {
        temp ~= (i < start) ? number.digits[i] : '0';
        if (size > 0) {
          c++;
          if (c == size && i != 0) {
            temp ~= separator;
            if (index < groupSizes.length - 1)
              size = groupSizes[++index];
            c = 0;
          }
        }
      }

      // Because we built the string backwards, reverse it.
      dst ~= temp.reverse;
      p += start;
    }
    else {
      while (pos > 0) {
        dst ~= (*p != '\0') ? *p++ : '0';
        pos--;
      }
    }
  }
  else
    dst ~= '0'; // Negative scale.

  if (length > 0) {
    dst ~= decimalSeparator;
    while (pos < 0 && length > 0) {
      dst ~= '0';
      pos++;
      length--;
    }
    while (length > 0) {
      dst ~= (*p != '\0') ? *p++ : '0';
      length--;
    }
  }
}

private void formatExponent(inout char[] dst, int value, char exponent, char[] positiveSign, char[] negativeSign, int length) {
  dst ~= exponent;
  if (value < 0) {
    dst ~= negativeSign;
    value = -value;
  }
  else
    dst ~= positiveSign;

  char[10] digits = '0';
  int n = 10;
  while (--length >= 0 || value != 0) {
    digits[--n] = value % 10 + '0';
    value /= 10;
  }

  while (n < 10)
    dst ~= digits[n++];
}

private static bool parseNumber(out Number number, char[] s, NumberStyles styles, NumberFormat nf) {

  enum ParseState {
    None = 0x0,
    Sign = 0x1,
    Parens = 0x2,
    Digits = 0x4,
    NonZero = 0x8,
    Decimal = 0x10,
    Currency = 0x20
  }

  int consume(char[] what, char[] within, int at) {
    if (at >= within.length)
      return -1;
    int i;
    while (at < within.length && i < what.length) {
      if (within[at] != what[i])
        return -1;
      i++;
      at++;
    }
    return i;
  }

  bool isWhitespace(char c) {
    return c == 0x20 || (c >= '\t' && c <= '\r');
  }

  char[] currencySymbol = ((styles & NumberStyles.CurrencySymbol) != 0) ? nf.currencySymbol : null;
  char[] decimalSeparator = ((styles & NumberStyles.CurrencySymbol) != 0) ? nf.currencyDecimalSeparator : nf.numberDecimalSeparator;
  char[] groupSeparator = ((styles & NumberStyles.CurrencySymbol) != 0) ? nf.currencyGroupSeparator : nf.numberGroupSeparator;
  char[] altDecimalSeparator = ((styles & NumberStyles.CurrencySymbol) != 0) ? nf.numberDecimalSeparator : null;
  char[] altGroupSeparator = ((styles & NumberStyles.CurrencySymbol) != 0) ? nf.numberGroupSeparator : null;

  number.scale = 0;
  number.sign = false;

  ParseState state;
  int count, end, pos, eaten;
  bool isSigned;

  // Parse leading part: sign, currency symbol, parentheses, whitespace.
  while (true) {
    if (pos == s.length)
      break;
    char c = s[pos];
    if ((isSigned = ((styles & NumberStyles.LeadingSign) != 0 && ((state & ParseState.Sign) == 0))) != 0
      && (eaten = consume(nf.positiveSign, s, pos)) != -1) {
        state |= ParseState.Sign;
        pos += eaten;
    }
    else if (isSigned && (eaten = consume(nf.negativeSign, s, pos)) != -1) {
      state |= ParseState.Sign;
      pos += eaten;
      number.sign = true;
    }
    else if (c == '('
      && (styles & NumberStyles.Parentheses) != 0 && ((state & ParseState.Sign) == 0)) {
        state |= ParseState.Sign | ParseState.Parens;
        number.sign = true;
        pos++;
    }
    else if ((currencySymbol != null && (eaten = consume(currencySymbol, s, pos)) != -1)) {
      state |= ParseState.Currency;
      currencySymbol = null;
      pos += eaten;
    }
    else if (!(isWhitespace(c) && ((styles & NumberStyles.LeadingWhite) != 0)
      && ((state & ParseState.Sign) == 0 ||
      ((state & ParseState.Sign) != 0 && ((state & ParseState.Currency) != 0 || nf.numberNegativePattern == 2)))))
      break;
    else
      pos++;
  }

  // Parse the digits, including any separators and decimal points.
  while (true) {
    if (pos == s.length)
      break;
    char c = s[pos];
    if (c >= '0' && c <= '9') {
      state |= ParseState.Digits;
      if (c != '0' || (state & ParseState.NonZero) != 0) {
        if (count < number.digits.length - 1) {
          number.digits[count++] = c;
          if (c != '0')
            end = count;
        }
        if ((state & ParseState.Decimal) == 0)
          number.scale++;
        state |= ParseState.NonZero;
      }
      else if ((state & ParseState.Decimal) != 0)
        number.scale--;
      pos++;
    }
    else if ((styles & NumberStyles.DecimalPoint) != 0 && (state & ParseState.Decimal) == 0 && (eaten = consume(decimalSeparator, s, pos)) != -1
      || (state & ParseState.Currency) != 0 && (eaten = consume(altDecimalSeparator, s, pos)) != -1) {
        state |= ParseState.Decimal;
        pos += eaten;
    }
    else if ((styles & NumberStyles.Thousands) != 0 && (state & ParseState.Digits) != 0 && (state & ParseState.Decimal) == 0
      && ((eaten = consume(groupSeparator, s, pos)) != -1 || (state & ParseState.Currency) != 0
      && (eaten = consume(altGroupSeparator, s, pos)) != -1))
      pos += eaten;
    else
      break;
  }

  number.precision = end;
  number.digits[end] = '\0';

  bool negativeExp;

  // Parse trailing part: sign, currency, parentheses, exponent, whitespace.
  if ((state & ParseState.Digits) != 0) {
    while (true) {
      if (pos >= s.length)
        break;

      char c = s[pos];
      if ((c == 'E' || c == 'e') && ((styles & NumberStyles.Exponent) != 0)) {
        int p = pos;
        pos++;
        if (pos == s.length)
          break;

        c = s[pos];
        if ((eaten = consume(nf.positiveSign, s, pos)) != -1) {
          pos += eaten;
          c = s[pos];
        }
        else if ((eaten = consume(nf.negativeSign, s, pos)) != -1) {
          pos += eaten;
          c = s[pos];
          negativeExp = true;
        }

        int exp;
        if (c >= '0' && c <= '9') {
          while (c >= '0' && c <= '9') {
            exp = exp * 10 + c - '0';
            pos++;
            if (pos == s.length)
              break;
            c = s[pos];
          }
          number.scale += negativeExp ? -exp : exp;
        }
        else
          pos = p;
      }

      if ((isSigned = ((styles & NumberStyles.TrailingSign) != 0 && (state & ParseState.Sign) == 0)) != 0
        && (eaten = consume(nf.positiveSign, s, pos)) != -1) {
          state |= ParseState.Sign;
          pos += eaten;
      }
      else if (isSigned && (eaten = consume(nf.negativeSign, s, pos)) != -1) {
        state |= ParseState.Sign;
        number.sign = true;
        pos += eaten;
      }
      else if (c == ')' && (state & ParseState.Parens) != 0)
        state &= ~ParseState.Parens;
      else if (currencySymbol != null && (eaten = consume(currencySymbol, s, pos)) != -1) {
        currencySymbol = null;
        pos += eaten;
      }
      else if (!(isWhitespace(c) && (styles & NumberStyles.TrailingWhite) != 0))
        break;
      else
        pos++;
    }

    // We must have found matching pairs of parentheses, if any.
    if ((state & ParseState.Parens) == 0) {
      // If no non-zero digits were found.
      if ((state & ParseState.NonZero) == 0) {
        number.scale = 0;
        if ((state & ParseState.Decimal) == 0)
          number.sign = false;
      }
      return true;
    }
    return false;
  }
  return false;
}

package char[] formatDateTime(DateTime dateTime, char[] format, DateTimeFormat dtf) {

  char[] expandKnownFormat(char[] format, inout DateTime dateTime, inout DateTimeFormat dtf) {
    switch (format[0]) {
      case 'd':
        return dtf.shortDatePattern;
      case 'D':
        return dtf.longDatePattern;
      case 'f':
        return dtf.longDatePattern ~ " " ~ dtf.shortTimePattern;
      case 'F':
        return dtf.fullDateTimePattern;
      case 'g':
        return dtf.generalShortTimePattern;
      case 'G':
        return dtf.generalLongTimePattern;
      /*case 'o': case 'O':
        dtf = DateTimeFormat.invariantFormat;
        return "yyyy'-'MM'-'dd'T'HH':'mm':'ss.fffffffK";*/
      case 'r': case 'R':
        dtf = DateTimeFormat.invariantFormat;
        return dtf.rfc1123Pattern;
      case 's':
        dtf = DateTimeFormat.invariantFormat;
        return dtf.sortableDateTimePattern;
      case 't':
        return dtf.shortTimePattern;
      case 'T':
        return dtf.longTimePattern;
      case 'u':
        return dtf.universalSortableDateTimePattern;
      case 'U':
        dtf = cast(DateTimeFormat)dtf.clone();
        if (typeid(typeof(dtf.calendar)) !is typeid(GregorianCalendar))
          dtf.calendar = GregorianCalendar.getDefaultInstance();
        dateTime = dateTime.toUtcTime();
        return dtf.fullDateTimePattern;
      case 'y': case 'Y':
        return dtf.yearMonthPattern;
      default:
    }
    throw new FormatException("Input string was not valid.");
  }

  int parseRepeat(char[] format, int pos, char c) {
    int n = pos + 1;
    while (n < format.length && format[n] == c)
      n++;
    return n - pos;
  }

  int parseQuote(char[] format, int pos, out char[] result) {
    int start = pos;
    char quote = format[pos++];
    bool found;
    while (pos < format.length) {
      char c = format[pos++];
      if (c == quote) {
        found = true;
        break;
      }
      else if (c == '\\') { // escaped
        if (pos < format.length)
          result ~= format[pos++];
      }
      else
        result ~= c;
    }
    return pos - start;
  }

    int parseNext(inout char[] format, int pos) {
      if (pos < format.length - 1)
        return cast(int)format[pos + 1];
      return -1;
    }

  char[] formatDayOfWeek(DayOfWeek dayOfWeek, int rpt) {
    if (rpt == 3)
      return dtf.getAbbreviatedDayName(dayOfWeek);
    return dtf.getDayName(dayOfWeek);
  }

  char[] formatMonth(int month, int rpt) {
    if (rpt == 3)
      return dtf.getAbbreviatedMonthName(month);
    return dtf.getMonthName(month);
  }

  void formatDigits(inout char[] output, int value, int length) {
    if (length > 2)
      length = 2;

    char[16] buffer;
    char* p = buffer.ptr + 16;

    int n = value;
    do {
      *--p = cast(char)(n % 10 + '0');
      n /= 10;
    } while (n != 0 && p > buffer.ptr);

    int c = cast(int)(buffer.ptr + 16 - p);
    while (c < length && p > buffer.ptr) {
      *--p = '0';
      c++;
    }
    output ~= p[0 .. c];
  }

  if (format == null)
    format = "G"; // Default to generalLongTimePattern.

  if (format.length == 1)
    format = expandKnownFormat(format, dateTime, dtf);

  char[] result;
  Calendar cal = dtf.calendar;
  bool justTime = true;
  int index, len;

  while (index < format.length) {
    char c = format[index];
    int next;

    switch (c) {
      case 'd': // day
        len = parseRepeat(format, index, c);
        if (len <= 2) {
          int day = cal.getDayOfMonth(dateTime);
          formatDigits(result, day, len);
        }
        else
          result ~= formatDayOfWeek(dateTime.dayOfWeek, len);
        justTime = false;
        break;
      case 'M': // month
        len = parseRepeat(format, index, c);
        int month = cal.getMonth(dateTime);
        if (len <= 2)
          formatDigits(result, month, len);
        else
          result ~= formatMonth(month, len);
        justTime = false;
        break;
      case 'y': // year
        len = parseRepeat(format, index, c);
        int year = cal.getYear(dateTime);
        if (cal.id == CAL_JAPAN || cal.id == CAL_TAIWAN)
          formatDigits(result, year, (len <= 2) ? len : 2);
        else if (len <= 2)
          formatDigits(result, year % 100, len);
        else
          formatDigits(result, year, len);
        justTime = false;
        break;
      case 'h': // hour (12-hour clock)
        len = parseRepeat(format, index, c);
        int hour = dateTime.hour % 12;
        if (hour == 0)
          hour = 12;
        formatDigits(result, hour, len);
        break;
      case 'H': // hour (24-hour clock)
        len = parseRepeat(format, index, c);
        formatDigits(result, dateTime.hour, len);
        break;
      case 'm': // minute
        len = parseRepeat(format, index, c);
        formatDigits(result, dateTime.minute, len);
        break;
      case 's': // second
        len = parseRepeat(format, index, c);
        formatDigits(result, dateTime.second, len);
        break;
      case 't': // AM/PM
        len = parseRepeat(format, index, c);
        if (len == 1) {
          if (dateTime.hour < 12) {
            if (dtf.amDesignator.length >= 1)
              result ~= dtf.amDesignator[0];
          }
          else if (dtf.pmDesignator.length >= 1)
            result ~= dtf.pmDesignator[0];
        }
        else
          result ~= (dateTime.hour < 12) ? dtf.amDesignator : dtf.pmDesignator;
        break;
      //case 'z': // time zone
      case ':':
        len = 1;
        result ~= dtf.timeSeparator;
        break;
      case '/':
        len = 1;
        result ~= dtf.dateSeparator;
        break;
      case '\'':
      case '\"':
        char[] quote;
        len = parseQuote(format, index, quote);
        result ~= quote;
        break;
      case '\\':
        next = parseNext(format, index);
        if (next >= 0) {
          result ~= cast(char)next;
          len = 2;
        }
        else
          throw new FormatException("Input string was not valid.");
        break;
      default:
        len = 1;
        result ~= c;
        break;
    }
    index += len;
  }

  return result;
}

/*private struct DateTimeParseResult {

  int year = -1;
  int month = -1;
  int day = -1;
  int hour;
  int minute;
  int second;
  double fraction;
  int timeMark;
  Calendar calendar;
  TimeSpan timeZoneOffset;
  DateTime parsedDate;

}

package DateTime parseDateTime(char[] s, DateTimeFormat dtf) {
  DateTimeParseResult result;
  if (!tryParseExactMultiple(s, dtf.getAllDateTimePatterns(), dtf, result))
    throw new FormatException("String was not a valid DateTime.");
  return result.parsedDate;
}

package DateTime parseDateTimeExact(char[] s, char[] format, DateTimeFormat dtf) {
  DateTimeParseResult result;
  if (!tryParseExact(s, format, dtf, result))
    throw new FormatException("String was not a valid DateTime.");
  return result.parsedDate;
}

package bool tryParseDateTime(char[] s, DateTimeFormat dtf, out DateTime result) {
  result = DateTime.min;
  DateTimeParseResult resultRecord;
  if (!tryParseExactMultiple(s, dtf.getAllDateTimePatterns(), dtf, resultRecord))
    return false;
  result = resultRecord.parsedDate;
  return true;
}

package bool tryParseDateTimeExact(char[] s, char[] format, DateTimeFormat dtf, out DateTime result) {
  result = DateTime.min;
  DateTimeParseResult resultRecord;
  if (!tryParseExact(s, format, dtf, resultRecord))
    return false;
  result = resultRecord.parsedDate;
  return true;
}

private bool tryParseExactMultiple(char[] s, char[][] formats, DateTimeFormat dtf, inout DateTimeParseResult result) {
  foreach (format; formats) {
  //std.stdio.writefln(format);
    if (tryParseExact(s, format, dtf, result))
      return true;
  }
  return false;
}

private bool tryParseExact(char[] s, char[] pattern, DateTimeFormat dtf, inout DateTimeParseResult result) {

  bool doParse() {

    int parseDigits(char[] s, inout int pos, int max) {
      int result = s[pos++] - '0';
      while (max > 1 && pos < s.length && s[pos] >= '0' && s[pos] <= '9') {
        result = result * 10 + s[pos++] - '0';
        --max;
      }
      return result;
    }

    bool parseOne(char[] s, inout int pos, char[] value) {
      if (s[pos .. pos + value.length] != value)
        return false;
      pos += value.length;
      return true;
    }

    int parseMultiple(char[] s, inout int pos, char[][] values ...) {
      int result = -1, max;
      foreach (int i, char[] value; values) {
        if (value.length == 0 || s.length - pos < value.length)
          continue;

        if (s[pos .. pos + value.length] == value) {
          if (result == 0 || value.length > max) {
            result = i + 1;
            max = value.length;
          }
        }
      }
      pos += max;
      return result;
    }

    TimeSpan parseTimeZoneOffset(char[] s, inout int pos) {
      bool sign;
      if (pos < s.length) {
        if (s[pos] == '-') {
          sign = true;
          pos++;
        }
        else if (s[pos] == '+')
          pos++;
      }
      int hour = parseDigits(s, pos, 2);
      int minute;
      if (pos < s.length && s[pos] == ':') {
        pos++;
        minute = parseDigits(s, pos, 2);
      }
      TimeSpan result = TimeSpan(hour, minute, 0);
      if (sign)
        result = result.negate();
      return result;
    }
      
    char[] stringOf(char c, int count = 1) {
      char[] s = new char[count];
      s[0 .. count] = c;
      return s;
    }

    result.calendar = dtf.calendar;
    result.year = result.month = result.day = -1;
    result.hour = result.minute = result.second = 0;
    result.fraction = 0.0;

    int pos, i, count;
    char c;

    while (pos < pattern.length && i < s.length) {
      c = pattern[pos++];

      if (c == ' ') {
        i++;
        while (i < s.length && s[i] == ' ')
          i++;
        if (i >= s.length)
          break;
        continue;
      }

      count = 1;

      switch (c) {
        case 'd': case 'm': case 'M': case 'y':
        case 'h': case 'H': case 's':
        case 't': case 'z':
          while (pos < pattern.length && pattern[pos] == c) {
            pos++;
            count++;
          }
          break;
        case ':':
          if (!parseOne(s, i, dtf.timeSeparator))
            return false;
          continue;
        case '/':
          if (!parseOne(s, i, dtf.dateSeparator))
            return false;
          continue;
        case '\\':
          if (pos < pattern.length) {
            c = pattern[pos++];
            if (s[i++] != c)
              return false;
          }
          else
            return false;
          continue;
        case '\'':
          while (pos < pattern.length) {
            c = pattern[pos++];
            if (c == '\'')
              break;
            if (s[i++] != c)
              return false;
          }
          continue;
        default:
          if (s[i++] != c)
            return false;
          continue;
      }

      switch (c) {
        case 'd': // day
          if (count == 1 || count == 2)
            result.day = parseDigits(s, i, 2);
          else if (count == 3)
            result.day = parseMultiple(s, i, dtf.abbreviatedDayNames);
          else
            result.day = parseMultiple(s, i, dtf.dayNames);
          if (result.day == -1)
            return false;
          break;
        case 'M': // month
          if (count == 1 || count == 2)
            result.month = parseDigits(s, i, 2);
          else if (count == 3)
            result.month = parseMultiple(s, i, dtf.abbreviatedMonthNames);
          else
            result.month = parseMultiple(s, i, dtf.monthNames);
          if (result.month == -1)
            return false;
          break;
        case 'y': // year
          if (count == 1 || count == 2)
            result.year = parseDigits(s, i, 2);
          else
            result.year = parseDigits(s, i, 4);
          if (result.year == -1)
            return false;
          break;
        case 'h': // 12-hour clock
        case 'H': // 24-hour clock
          result.hour = parseDigits(s, i, 2);
          break;
        case 'm': // minute
          result.minute = parseDigits(s, i, 2);
          break;
        case 's': // second
          result.second = parseDigits(s, i, 2);
          break;
        case 't': // time mark
          if (count == 1)
            result.timeMark = parseMultiple(s, i, stringOf(dtf.amDesignator[0]), stringOf(dtf.pmDesignator[0]));
          else
            result.timeMark = parseMultiple(s, i, dtf.amDesignator, dtf.pmDesignator);
          break;
        case 'z':
          result.timeZoneOffset = parseTimeZoneOffset(s, i);
          break;
        default:
          break;
      }
    }

    if (pos < pattern.length || i < s.length)
      return false;

    if (result.timeMark == 1) { // am
      if (result.hour == 12)
        result.hour = 0;
    }
    else if (result.timeMark == 2) { // pm
      if (result.hour < 12)
        result.hour += 12;
    }

    // If the input string didn't specify a date part, try to return something meaningful.
    if (result.year == -1 || result.month == -1 || result.day == -1) {
      DateTime now = DateTime.now;
      if (result.month == -1 && result.day == -1) {
        if (result.year == -1) {
          result.year = result.calendar.getYear(now);
          result.month = result.calendar.getMonth(now);
          result.day = result.calendar.getDayOfMonth(now);
        }
        else
          result.month = result.day = 1;
      }
      else {
        if (result.year == -1)
          result.year = result.calendar.getYear(now);
        if (result.month == -1)
          result.month = 1;
        if (result.day == -1)
          result.day = 1;
      }
    }
    return true;
  }

  if (doParse()) {
    result.parsedDate = result.calendar.getDateTime(result.year, result.month, result.day, result.hour, result.minute, result.second, 0);
    return true;
  }
  return false;
}*/