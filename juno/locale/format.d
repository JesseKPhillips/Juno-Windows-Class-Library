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

module juno.locale.format;

private import juno.base.core,
  juno.base.math,
  juno.locale.constants;
private import juno.locale.core : IFormatProvider, NumberFormat, DateTimeFormat, DayOfWeek, Calendar, DateTime, TimeSpan;
private import juno.base.string : strlen;

extern (C)
private char* ecvt(double d, int digits, out int decpt, out int sign);

private string ulongToString(ulong value, int digits) {
  if (digits < 1)
    digits = 1;

  char[100] buffer;
  int n = 100;
  while (--digits >= 0 || value != 0) {
    buffer[--n] = value % 10 + '0';
    value /= 10;
  }

  return buffer[n .. $].dup;
}

private string longToString(long value, int digits, string negativeSign) {
  if (digits < 1)
    digits = 1;

  char[100] buffer;
  ulong uv = (value >= 0) ? value : cast(ulong)-value;
  int n = 100;
  while (--digits >= 0 || uv != 0) {
    buffer[--n] = uv % 10 + '0';
    uv /= 10;
  }

  if (value < 0) {
    n -= negativeSign.length;
    buffer[n .. n + negativeSign.length] = negativeSign;
  }

  return buffer[n .. $].dup;
}

private string intToHexString(uint value, int digits, char format) {
  if (digits < 1)
    digits = 1;

  char[100] buffer;
  int n = 100;
  while (--digits >= 0 || value != 0) {
    uint v = value & 0xF;
    buffer[--n] = (v < 10) ? v + '0' : v + format - ('X' - 'A' + 10);
    value >>= 4;
  }

  return buffer[n .. $].dup;
}

private string longToHexString(ulong value, int digits, char format) {
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

private char parseFormatSpecifier(string format, out int length) {
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

public string formatUInt(uint value, string format, IFormatProvider provider) {
  auto nf = NumberFormat.get(provider);

  int length;
  char specifier = parseFormatSpecifier(format, length);

  switch (specifier) {
    case 'g', 'G':
      if (length > 0)
        break;
      // fall through
    case 'd', 'D':
      return ulongToString(value, length);
    case 'x', 'X':
      return intToHexString(value, length, specifier);
    default:
  }

  auto number = Number(cast(ulong)value);
  if (specifier != char.init)
    return number.toString(specifier, length, nf);
  return number.toStringFormat(format, nf);
}

public string formatInt(int value, string format, IFormatProvider provider) {
  auto nf = NumberFormat.get(provider);

  int length;
  char specifier = parseFormatSpecifier(format, length);

  switch (specifier) {
    case 'g', 'G':
      if (length > 0)
        break;
      // fall through
    case 'd', 'D':
      return longToString(cast(long)value, length, nf.negativeSign);
    case 'x', 'X':
      return intToHexString(cast(uint)value, length, specifier);
    default:
  }

  auto number = Number(cast(long)value);
  if (specifier != char.init)
    return number.toString(specifier, length, nf);
  return number.toStringFormat(format, nf);
}

public string formatULong(ulong value, string format, IFormatProvider provider) {
  auto nf = NumberFormat.get(provider);

  int length;
  char specifier = parseFormatSpecifier(format, length);

  switch (specifier) {
    case 'g', 'G':
      if (length > 0)
        break;
      // fall through
    case 'd', 'D':
      return ulongToString(value, length);
    case 'x', 'X':
      return longToHexString(value, length, specifier);
    default:
  }

  auto number = Number(value);
  if (specifier != char.init)
    return number.toString(specifier, length, nf);
  return number.toStringFormat(format, nf);
}

public string formatLong(long value, string format, IFormatProvider provider) {
  auto nf = NumberFormat.get(provider);

  int length;
  char specifier = parseFormatSpecifier(format, length);

  switch (specifier) {
    case 'g', 'G':
      if (length > 0)
        break;
      // fall through
    case 'd', 'D':
      return longToString(value, length, nf.negativeSign);
    case 'x', 'X':
      return longToHexString(cast(ulong)value, length, specifier);
    default:
  }

  auto number = Number(value);
  if (specifier != char.init)
    return number.toString(specifier, length, nf);
  return number.toStringFormat(format, nf);
}

public string formatFloat(float value, string format, IFormatProvider provider) {
  auto nf = NumberFormat.get(provider);

  int length;
  char specifier = parseFormatSpecifier(format, length);
  int precision = 7;

  switch (specifier) {
    case 'g', 'G':
      if (length > 7)
        precision = 9;
      // fall through
    default:
  }

  auto number = Number(value, precision);

  if (specifier != char.init)
    return number.toString(specifier, length, nf);
  return number.toStringFormat(format, nf);
}

public string formatDouble(double value, string format, IFormatProvider provider) {
  auto nf = NumberFormat.get(provider);

  int length;
  char specifier = parseFormatSpecifier(format, length);
  int precision = 15;

  switch (specifier) {
    case 'g', 'G':
      if (length > 15)
        precision = 17;
      // fall through
    default:
  }

  auto number = Number(value, precision);

  if (specifier != char.init)
    return number.toString(specifier, length, nf);
  return number.toStringFormat(format, nf);
}

public uint parseUInt(string s, NumberStyles style, NumberFormat format) {
  auto number = Number(s, style, format);
  long value;
  if (!number.toLong(value) || (value < uint.min || value > uint.max))
    throw new OverflowException("Value was either too small or too large for a uint.");
  return cast(uint)value;
}

public int parseInt(string s, NumberStyles style, NumberFormat format) {
  auto number = Number(s, style, format);
  long value;
  if (!number.toLong(value) || (value < int.min || value > int.max))
    throw new OverflowException("Value was either too small or too large for an int.");
  return cast(int)value;
}

public ulong parseULong(string s, NumberStyles style, NumberFormat format) {
  auto number = Number(s, style, format);
  long value;
  if (!number.toLong(value) || (value < ulong.min || value > ulong.max))
    throw new OverflowException("Value was either too small or too large for a ulong.");
  return cast(ulong)value;
}

public long parseLong(string s, NumberStyles style, NumberFormat format) {
  auto number = Number(s, style, format);
  long value;
  if (!number.toLong(value) || (value < long.min || value > long.max))
    throw new OverflowException("Value was either too small or too large for a long.");
  return value;
}

public float parseFloat(string s, NumberStyles style, NumberFormat format) {
  try {
    auto number = Number(s, style, format);
    double value;
    if (!number.toDouble(value))
      throw new OverflowException("Value was either too small or too large for a float.");
    float result = cast(float)value;
    if (isInfinity(result))
      throw new OverflowException("Value was either too small or too large for a float.");
    return result;
  }
  catch (FormatException ex) {
    if (s == format.positiveInfinitySymbol)
      return float.infinity;
    else if (s == format.negativeInfinitySymbol)
      return -float.infinity;
    else if (s == format.nanSymbol)
      return float.nan;
    throw ex;
  }
}

public double parseDouble(string s, NumberStyles style, NumberFormat format) {
  try {
    auto number = Number(s, style, format);
    double result;
    if (!number.toDouble(result))
      throw new OverflowException("Value was either too small or too large for a double.");
    return result;
  }
  catch (FormatException ex) {
    if (s == format.positiveInfinitySymbol)
      return double.infinity;
    else if (s == format.negativeInfinitySymbol)
      return -double.infinity;
    else if (s == format.nanSymbol)
      return double.nan;
    throw ex;
  }
}

private const int NAN_FLAG      = 0x80000000;
private const int INFINITY_FLAG = 0x7FFFFFFF;
private const int EXP           = 0x07FF;

private struct Number {

  int precision;
  int scale;
  int sign;
  char[long.sizeof * 8] digits = void;

  static Number opCall(ulong value) {
    Number n;
    n.precision = 20;

    char[20] buffer;
    int i = buffer.length;
    while (value != 0) {
      buffer[--i] = value % 10 + '0';
      value /= 10;
    }

    int end = n.scale = -(i - buffer.length);
    n.digits[0 .. end] = buffer[i .. i + end];
    n.digits[end] = '\0';

    return n;
  }

  static Number opCall(long value) {
    Number n;
    n.precision = 20;
    if (value < 0) {
      n.sign = 1;
      value = -value;
    }

    char[20] buffer;
    int i = buffer.length;
    while (value != 0) {
      buffer[--i] = value % 10 + '0';
      value /= 10;
    }

    int end = n.scale = -(i - buffer.length);
    n.digits[0 .. end] = buffer[i .. i + end];
    n.digits[end] = '\0';

    return n;
  }

  static Number opCall(double value, int precision) {
    Number n;
    n.precision = precision;

    char* p = n.digits.ptr;
    long bits = *cast(long*)&value;
    long mant = bits & 0x000FFFFFFFFFFFFF;
    int exp = cast(int)((bits >> 52) & EXP);

    if (exp == EXP) {
      n.scale = (mant != 0) ? NAN_FLAG : INFINITY_FLAG;
      if (((bits >> 63) & 1) != 0)
        n.sign = 1;
    }
    else {
      char* chars = ecvt(value, n.precision, n.scale, n.sign);
      if (*chars != '\0') {
        while (*chars != '\0')
          *p++ = *chars++;
      }
    }
    *p = '\0';

    return n;
  }

  static Number opCall(string s, NumberStyles styles, NumberFormat nf) {
    Number n;
    if (!parseNumber(n, s, styles, nf))
      throw new FormatException("Input string was not valid.");
    return n;
  }

  void round(int pos) {
    int index;
    while (index < pos && digits[index] != '\0') index++;

    if (index == pos && digits[index] >= '5') {
      while (index > 0 && digits[index - 1] == '9') index--;

      if (index > 0)
        digits[index - 1]++;
      else {
        scale++;
        digits[0] = '1';
        index = 1;
      }
    }
    else while (index > 0 && digits[index - 1] == '0') index--;

    if (index == 0) {
      scale = 0;
      sign = 0;
    }

    digits[index] = '\0';
  }

  bool toLong(out long value) {
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

  bool toDouble(out double value) {

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

    char* p = digits.ptr;
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

  string toString(char format, int length, NumberFormat nf) {
    char[] ret = null;

    switch (format) {
      case 'n', 'N':
        // Number
        if (length < 0)
          length = nf.numberDecimalDigits;
        round(scale + length);
        formatNumber(*this, ret, length, nf);
        break;
      case 'g', 'G':
        // General
        if (length < 0)
          length = precision;
        round(length);
        if (sign)
          ret ~= nf.negativeSign;
        formatGeneral(*this, ret, length, (format == 'g') ? 'e' : 'E', nf);
        break;
      case 'c', 'C':
        // Currency
        if (length < 0)
          length = nf.currencyDecimalDigits;
        round(scale + length);
        formatCurrency(*this, ret, length, nf);
        break;
      default:
    }

    return ret.dup;
  }

  string toStringFormat(string format, NumberFormat nf) {
    bool hasGroups = false, scientific = false;
    int groupCount = 0, groupPos = -1, pointPos = -1;
    int first = int.max, last, count, adjust;

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
        case '\'', '\"':
          while (n < format.length && format[n++] != c) {}
          break;
        case '\\':
          if (n < format.length) n++;
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

    string groupSeparator = nf.numberGroupSeparator;
    string decimalSeparator = nf.numberDecimalSeparator;

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

    string ret;
    if (sign)
      ret ~= nf.negativeSign;

    char* p = digits.ptr;
    n = 0;
    bool pointWritten = false;
    while (n < format.length) {
      c = format[n++];
      if (extra > 0 && (c == '#' || c == '0' || c == '.')) {
        while (extra > 0) {
          ret ~= (*p != '\0') ? *p++ : '0';

          if (hasGroups && pos > 1 && groupIndex >= 0) {
            if (pos == groupPositions[groupIndex] + 1) {
              ret ~= groupSeparator;
              groupIndex--;
            }
          }
          pos--;
          extra--;
        }
      }

      switch (c) {
        case '#', '0':
          if (extra < 0) {
            extra++;
            c = (pos <= first) ? '0' : char.init;
          }
          else c = (*p != '\0') ? *p++ : (pos > last) ? '0' : char.init;

          if (c != char.init) {
            ret ~= c;

            if (hasGroups && pos > 1 && groupIndex >= 0) {
              if (pos == groupPositions[groupIndex] + 1) {
                ret ~= groupSeparator;
                groupIndex--;
              }
            }
          }
          pos--;
          break;
        case '.':
          if (pos != 0 || pointWritten)
            break;
          if (last < 0 || (pointPos < count && *p++ != '\0')) {
            ret ~= decimalSeparator;
            pointWritten = true;
          }
          break;
        case ',':
          break;
        case '\'', '\"':
          if (n < format.length) n++;
          break;
        case '\\':
          if (n < format.length) ret ~= format[n++];
          break;
        default:
          ret ~= c;
          break;
      }
    }

    return ret;
  }

}

// Must match NumberFormat.decimalPositivePattern
private final string positiveNumberFormat = "#";
// Must match NumberFormat.decimalNegativePattern
private final string[] negativeNumberFormats = [ "(#)", "-#", "- #", "#-", "# -" ];
// Must match NumberFormat.currencyPositivePattern
private final string[] positiveCurrencyFormats = [ "$#", "#$", "$ #", "# $" ];
// Must match NumberFormat.currencyNegativePattern
private final string[] negativeCurrencyFormats = [ "($#)", "-$#", "$-#", "$#-", "(#$)", "-#$", "#-$", "#$-", "-# $", "-$ #", "# $-", "$ #-", "$ -#", "#- $", "($ #)", "(# $)" ];
// Must match NumberFormat.percentPositivePattern
private final string[] positivePercentFormats = [ "# %", "#%", "%#", "% #" ];
// Must match NumberFormat.percentNegativePattern
private final string[] negativePercentFormats = [ "-# %", "-#%", "-%#", "%-#", "%#-", "#-%", "#%-", "-% #", "# %-", "% #-", "% -#", "#- %" ];

private void formatNumber(ref Number number, ref char[] dst, int length, NumberFormat nf) {
  string format = number.sign ? negativeNumberFormats[nf.numberNegativePattern] : positiveNumberFormat;

  foreach (ch; format) {
    switch (ch) {
      case '#':
        formatFixed(number, dst, length, nf.numberGroupSizes, nf.numberDecimalSeparator, nf.numberGroupSeparator);
        break;
      case '-':
        dst ~= nf.negativeSign;
        break;
      default:
        dst ~= ch;
        break;
    }
  }
}

private void formatGeneral(ref Number number, ref char[] dst, int length, char format, NumberFormat nf) {
  int pos = number.scale;

  char* p = number.digits.ptr;
  if (pos > 0) {
    while (pos > 0) {
      dst ~= (*p != '\0') ? *p++ : '0';
      pos--;
    }
  }
  else
    dst ~= '0';

  if (*p != '\0' || pos < 0) {
    dst ~= nf.numberDecimalSeparator;
    while (pos < 0) {
      dst ~= '0';
      pos++;
    }
    while (*p != '\0') dst ~= *p++;
  }
}

private void formatCurrency(ref Number number, ref char[] dst, int length, NumberFormat nf) {
  string format = number.sign ? negativeCurrencyFormats[nf.currencyNegativePattern] : positiveCurrencyFormats[nf.currencyPositivePattern];

  foreach (ch; format) {
    switch (ch) {
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
        dst ~= ch;
        break;
    }
  }
}

private void formatFixed(ref Number number, ref char[] dst, int length, int[] groupSizes, string decimalSeparator, string groupSeparator) {
  int pos = number.scale;
  char* p = number.digits.ptr;

  if (pos > 0) {
    if (groupSizes.length != 0) {
      // Are there enough digits to format?
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

      // Insert separator at positions specified by groupSizes.
      int end = strlen(p);
      int start = (pos < end) ? pos : end;
      string separator = groupSeparator.reverse;
      char[] temp;

      index = 0;
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
    else while (pos > 0) {
      dst ~= (*p != '\0') ? *p++ : '0';
      pos--;
    }
  }
  else
    dst ~= '0'; //  Negative scale.

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

private bool parseNumber(out Number number, string s, NumberStyles styles, NumberFormat nf) {

  enum ParseState {
    None = 0x0,
    Sign = 0x1,
    Parens = 0x2,
    Digits = 0x4,
    NonZero = 0x8,
    Decimal = 0x10,
    Currency = 0x20
  }

  int eat(string what, string within, int at) {
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

  string currencySymbol = ((styles & NumberStyles.CurrencySymbol) != 0) ? nf.currencySymbol : null;
  string decimalSeparator = ((styles & NumberStyles.CurrencySymbol) != 0) ? nf.currencyDecimalSeparator : nf.numberDecimalSeparator;
  string groupSeparator = ((styles & NumberStyles.CurrencySymbol) != 0) ? nf.currencyGroupSeparator : nf.numberGroupSeparator;
  string altDecimalSeparator = ((styles & NumberStyles.CurrencySymbol) != 0) ? nf.numberDecimalSeparator : null;
  string altGroupSeparator = ((styles & NumberStyles.CurrencySymbol) != 0) ? nf.numberGroupSeparator : null;

  number.scale = 0;
  number.sign = 0;

  ParseState state;
  int count, end, pos, eaten;
  bool isSigned;

  while (true) {
    if (pos == s.length) break;
    char c = s[pos];
    if ((isSigned = ((styles & NumberStyles.LeadingSign) != 0 && ((state & ParseState.Sign) == 0))) != 0 
      && (eaten = eat(nf.positiveSign, s, pos)) != -1) {
      state |= ParseState.Sign;
      pos += eaten;
    }
    else if (isSigned && (eaten = eat(nf.negativeSign, s, pos)) != -1) {
      state |= ParseState.Sign;
      pos += eaten;
      number.sign = 1;
    }
    else if (c == '(' &&
      (styles & NumberStyles.Parentheses) != 0 && ((state & ParseState.Sign) == 0)) {
      state |= ParseState.Sign | ParseState.Parens;
      number.sign = 1;
      pos++;
    }
    else if ((currencySymbol != null && (eaten = eat(currencySymbol, s, pos)) != -1)) {
      state |= ParseState.Currency;
      currencySymbol = null;
      pos += eaten;
    }
    else if (!(isWhitespace(c) && ((styles & NumberStyles.LeadingWhite) != 0)
      && ((state & ParseState.Sign) == 0 
      || ((state & ParseState.Sign) != 0 && ((state & ParseState.Currency) != 0 || nf.numberNegativePattern == 2)))))
      break;
    else pos++;
  }

  while (true) {
    if (pos == s.length) break;

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
    else if ((styles & NumberStyles.DecimalPoint) != 0 && (state & ParseState.Decimal) == 0 && (eaten = eat(decimalSeparator, s, pos)) != -1 
      || (state & ParseState.Currency) != 0 && (eaten = eat(altDecimalSeparator, s, pos)) != -1) {
      state |= ParseState.Decimal;
      pos += eaten;
    }
    else if ((styles & NumberStyles.Thousands) != 0 && (state & ParseState.Digits) != 0 && (state & ParseState.Decimal) == 0 
      && ((eaten = eat(groupSeparator, s, pos)) != -1 || (state & ParseState.Currency) != 0 
      && (eaten = eat(altGroupSeparator, s, pos)) != -1))
      pos += eaten;
    else break;
  }

  number.precision = end;
  number.digits[end] = '\0';

  if ((state & ParseState.Digits) != 0) {
    while (true) {
      if (pos >= s.length) break;

      char c = s[pos];
      if ((isSigned = ((styles & NumberStyles.TrailingSign) != 0 && (state & ParseState.Sign) == 0)) != 0 
        && (eaten = eat(nf.positiveSign, s, pos)) != -1) {
        state |= ParseState.Sign;
        pos += eaten;
      }
      else if (isSigned && (eaten = eat(nf.negativeSign, s, pos)) != -1) {
        state |= ParseState.Sign;
        number.sign = 1;
        pos += eaten;
      }
      else if (c == ')' && (state & ParseState.Parens) != 0)
        state &= ~ParseState.Parens;
      else if (currencySymbol != null && (eaten = eat(currencySymbol, s, pos)) != -1) {
        currencySymbol = null;
        pos += eaten;
      }
      else if (!(isWhitespace(c) & (styles & NumberStyles.TrailingWhite) != 0))
        break;
      else pos++;
    }

    if ((state & ParseState.Parens) == 0) {
      if ((state & ParseState.NonZero) == 0) {
        number.scale = 0;
        if ((state & ParseState.Decimal) == 0)
          number.sign = 0;
      }
      return true;
    }
    return false;
  }
  return false;
}

package string formatDateTime(DateTime dateTime, string format, DateTimeFormat dtf) {

  string expandKnownFormat(string format, ref DateTime dateTime, ref DateTimeFormat dtf) {
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
      case 'r', 'R':
        dtf = DateTimeFormat.constant;
        return dtf.rfc1123Pattern;
      case 's':
        dtf = DateTimeFormat.constant;
        return dtf.sortableDateTimePattern;
      case 't':
        return dtf.shortTimePattern;
      case 'T':
        return dtf.longTimePattern;
      case 'y', 'Y':
        return dtf.yearMonthPattern;
      default:
    }
    throw new FormatException("Input string was not valid.");
  }

  int parseRepeat(string format, int pos, char c) {
    int n = pos + 1;
    while (n < format.length && format[n] == c)
      n++;
    return n - pos;
  }

  int parseQuote(string format, int pos, out char[] result) {
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

  int parseNext(string format, int pos) {
    if (pos < format.length - 1)
      return cast(int)format[pos + 1];
    return -1;
  }

  string formatDayOfWeek(DayOfWeek dayOfWeek, int rpt) {
    if (rpt == 3)
      return dtf.getAbbreviatedDayName(dayOfWeek);
    return dtf.getDayName(dayOfWeek);
  }

  string formatMonth(int month, int rpt) {
    if (rpt == 3)
      return dtf.getAbbreviatedMonthName(month);
    return dtf.getMonthName(month);
  }

  void formatDigits(ref char[] output, int value, int length) {
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
          int day = dateTime.day;//cal.getDayOfMonth(dateTime);
          formatDigits(result, day, len);
        }
        else
          result ~= formatDayOfWeek(dateTime.dayOfWeek, len);
        justTime = false;
        break;
      case 'M': // month
        len = parseRepeat(format, index, c);
        int month = dateTime.month;//cal.getMonth(dateTime);
        if (len <= 2)
          formatDigits(result, month, len);
        else
          result ~= formatMonth(month, len);
        justTime = false;
        break;
      case 'y': // year
        len = parseRepeat(format, index, c);
        int year = dateTime.year;//cal.getYear(dateTime);
        /*if (cal.id == CAL_JAPAN || cal.id == CAL_TAIWAN)
          formatDigits(result, year, (len <= 2) ? len : 2);
        else */if (len <= 2)
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

  return result.dup;
}

private struct DateTimeParseResult {
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

package DateTime parseDateTime(string s, DateTimeFormat dtf) {
  DateTimeParseResult result;
  if (!tryParseExactMultiple(s, dtf.getAllDateTimePatterns(), dtf, result))
    throw new FormatException("String was not a valid DateTime.");
  return result.parsedDate;
}

package DateTime parseDateTimeExact(string s, string format, DateTimeFormat dtf) {
  DateTimeParseResult result;
  if (!tryParseExact(s, format, dtf, result))
    throw new FormatException("String was not a valid DateTime.");  
  return result.parsedDate;
}

private bool tryParseExactMultiple(string s, string[] formats, DateTimeFormat dtf, ref DateTimeParseResult result) {
  foreach (format; formats) {
    if (tryParseExact(s, format, dtf, result))
      return true;
  }
  return false;
}

private bool tryParseExact(string s, string pattern, DateTimeFormat dtf, ref DateTimeParseResult result) {

  bool doParse() {

    int parseDigits(string s, ref int pos, int max) {
      int result = s[pos++] - '0';
      while (max > 1 && pos < s.length && s[pos] >= '0' && s[pos] <= '9') {
        result = result * 10 + s[pos++] - '0';
        --max;
      }
      return result;
    }

    bool parseOne(string s, ref int pos, string value) {
      if (s[pos .. pos + value.length] != value)
        return false;
      pos += value.length;
      return true;
    }

    int parseMultiple(string s, ref int pos, string[] values ...) {
      int result = -1, max;
      foreach (i, value; values) {
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

    TimeSpan parseTimeZoneOffset(string s, ref int pos) {
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
        result = -result;
      return result;
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
        case 'd', 'm', 'M', 'y', 'h', 'H', 's', 't', 'z':
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
        case 'd':
          if (count == 1 || count == 2)
            result.day = parseDigits(s, i, 2);
          else if (count == 3)
            result.day = parseMultiple(s, i, dtf.abbreviatedDayNames);
          else
            result.day = parseMultiple(s, i, dtf.dayNames);
          if (result.day == -1)
            return false;
          break;
        case 'M':
          if (count == 1 || count == 2)
            result.month = parseDigits(s, i, 2);
          else if (count == 3)
            result.month = parseMultiple(s, i, dtf.abbreviatedMonthNames);
          else
            result.month = parseMultiple(s, i, dtf.monthNames);
          if (result.month == -1)
            return false;
          break;
        case 'y':
          if (count == 1 || count == 2)
            result.year = parseDigits(s, i, 2);
          else
            result.year = parseDigits(s, i, 4);
          if (result.year == -1)
            return false;
          break;
        case 'h', 'H':
          result.hour = parseDigits(s, i, 2);
          break;
        case 'm':
          result.minute = parseDigits(s, i, 2);
          break;
        case 's':
          result.second = parseDigits(s, i, 2);
          break;
        case 't':
          if (count == 1)
            result.timeMark = parseMultiple(s, i, [ dtf.amDesignator[0] ], [ dtf.pmDesignator[0] ]);
          else
            result.timeMark = parseMultiple(s, i, dtf.amDesignator, dtf.pmDesignator);
          break;
        case 'z':
          result.timeZoneOffset = parseTimeZoneOffset(s, i);
          break;
        default:
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

    if (result.year == -1 || result.month == -1 || result.day == -1) {
      DateTime now = DateTime.localNow;
      if (result.month == -1 && result.day == -1) {
        if (result.year == -1) {
          result.year = now.year;
          result.month = now.month;
          result.day = now.day;
        }
        else
          result.month = result.day = 1;
      }
      else {
        if (result.year == -1)
          result.year = now.year;
        if (result.month == -1)
          result.month = 1;
        if (result.day == -1)
          result.day = 1;
      }
    }
    return true;
  }

  if (doParse()) {
    result.parsedDate = DateTime(result.year, result.month, result.day, result.hour, result.minute, result.second);
    return true;
  }
  return false;
}