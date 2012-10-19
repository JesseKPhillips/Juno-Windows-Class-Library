module juno.locale.numeric;

import juno.base.core,
  juno.locale.constants,
  juno.locale.core,
  juno.com.core;
import std.algorithm;
import std.conv;
import std.exception;
import std.range;
import core.stdc.string : strlen;
debug import std.stdio : writefln;

private enum {
  NAN_FLAG = 0x80000000,
  INFINITY_FLAG = 0x7FFFFFFF,
  EXP = 0x07FF
}

private extern(C) char* ecvt(double d, int digits, out int decpt, out int sign);

package struct Number {

  int precision;
  int scale;
  int sign;
  char[long.sizeof * 8] digits = void;

  static Number opCall(long value, int precision) {
    Number n;
    n.precision = precision;
    if (value < 0) {
      n.sign = 1;
      value = -value;
    }

    char[20] buffer;
    int i = buffer.length;
    while (value != 0) {
      buffer[--i] = cast(char)(value % 10 + '0');
      value /= 10;
    }

    // buffer is static length 20
    static assert(buffer.length == 20);
    auto end = n.scale = -(i - cast(int)buffer.length);
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

    char* chars = ecvt(value, precision, n.scale, n.sign);
    if (*chars != '0') {
      while (*chars != '\0')
        *p++ = *chars++;
    }
    *p = '\0';

    return n;
  }

  static Number opCall(Decimal value) {

    uint d32DivMod1E9(uint hi32, uint *lo32) {
      ulong n = cast(ulong)hi32 << 32 | *lo32;
      *lo32 = cast(uint)(n / 1000000000);
      return cast(uint)(n % 1000000000);
    }

    uint decDivMod1E9(Decimal* value) {
      return d32DivMod1E9(d32DivMod1E9(d32DivMod1E9(0, &value.Hi32), &value.Mid32), &value.Lo32);
    }

    Number n;
    n.precision = 29;

    if (value.sign)
      n.sign = 1;

    char[30] buffer;
    int i = buffer.length;
    Decimal d = value;
    while (d.Mid32 | d.Hi32) {
      int digits = 9;
      uint x = decDivMod1E9(&d);
      while (--digits >= 0 || x != 0) {
        buffer[--i] = cast(char)(x % 10 + '0');
        x /= 10;
      }
    }
    uint x = d.Lo32;
    while (x != 0) {
      buffer[--i] = cast(char)(x % 10 + '0');
      x /= 10;
    }
    // buffer is static length 30
    static assert(buffer.length == 30);
    auto end = -(i - cast(int)buffer.length);
    n.scale = -(i - cast(int)buffer.length) - d.scale;
    n.digits[0 .. end] = buffer[i .. i + end];
    n.digits[end] = '\0';

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
    else
      while (index > 0 && digits[index - 1] == '0') index--;

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
    int count = to!int(strlen(p));
    auto left = count;

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
    byte n = cast(byte)((left > 9) ? 9 : left);
    left -= n;
    ulong bits = getDigits(p, n);
    if (left > 0) {
      n = cast(byte)((left > 9) ? 9 : left);
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
    if (cast(uint)(bits & (1 << 10)) != 0) {
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

  bool toDecimal(out Decimal value) {

    void decShiftLeft(ref Decimal value) {
      uint c0 = (value.Lo32 & 0x80000000) ? 1 : 0;
      uint c1 = (value.Mid32 & 0x80000000) ? 1 : 0;
      value.Lo32 <<= 1;
      value.Mid32 = value.Mid32 << 1 | c0;
      value.Hi32 = value.Hi32 << 1 | c1;
    }

    bool decAddCarry(ref uint value, uint i) {
      uint v = value;
      uint sum = v + i;
      value = sum;
      return sum < v || sum < i ? true : false;
    }

    void decAdd(ref Decimal value, ref Decimal d) {
      if (decAddCarry(value.Lo32, d.Lo32)) {
        if (decAddCarry(value.Mid32, 1))
          decAddCarry(value.Hi32, 1);
      }
      if (decAddCarry(value.Mid32, d.Mid32))
        decAddCarry(value.Hi32, 1);
      decAddCarry(value.Hi32, d.Hi32);
    }

    void decMul10(ref Decimal value) {
      Decimal d = value;
      decShiftLeft(value);
      decShiftLeft(value);
      decAdd(value, d);
      decShiftLeft(value);
    }

    void decAddInt(ref Decimal value, uint i) {
      if (decAddCarry(value.Lo32, i)) {
        if (decAddCarry(value.Mid32, i))
          decAddCarry(value.Hi32, i);
      }
    }

    char* p = digits.ptr;
    int e = scale;

    if (p != null) {
      if (e > 29 || e < -29)
        return false;

      while ((e > 0 || *p && e > -28) 
        && (value.Hi32 < 0x19999999 || value.Hi32 == 0x19999999
        && (value.Mid32 < 0x99999999 || value.Mid32 == 0x99999999
        && (value.Lo32 < 0x99999999 || value.Lo32 == 0x99999999 && *p <= '5')))) {
        decMul10(value);
        if (*p)
          decAddInt(value, *p++ - '0');
        e--;
      }

      if (*p++ >= '5') {
        bool round = true;

        if (*(p - 1) == '5' && *(p - 2) % 2 == 0) {
          int c = 20;
          while (*p == '0' && c != 0) {
            p++;
            c--;
          }
          if (*p == '\0' || c == 0) {
            round = false;
          }
        }

        if (round) {
          decAddInt(value, 1);
          if ((value.Hi32 | value.Mid32 | value.Lo32) == 0) {
            value.Hi32 = 0x19999999;
            value.Mid32 = 0x99999999;
            value.Lo32 = 0x9999999A;
            e++;
          }
        }
      }
    }

    if (e > 0)
      return false;
    value.scale = cast(ubyte)-e;
    value.sign = sign ? DECIMAL_NEG : 0;
    return true;
  }

  static bool tryParse(string s, NumberStyles styles, NumberFormat nf, out Number result) {

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

    result.scale = 0;
    result.sign = 0;

    ParseState state;
    int count, end, pos, eaten;
    bool isSigned;

    while (true) {
      if (pos == s.length) break;
      char c = s[pos];
      if ((isSigned = (((styles & NumberStyles.LeadingSign) != 0) && ((state & ParseState.Sign) == 0))) != 0 
        && (eaten = eat(nf.positiveSign, s, pos)) != -1) {
        state |= ParseState.Sign;
        pos += eaten;
      }
      else if (isSigned && (eaten = eat(nf.negativeSign, s, pos)) != -1) {
        state |= ParseState.Sign;
        pos += eaten;
        result.sign = 1;
      }
      else if (c == '(' &&
        (styles & NumberStyles.Parentheses) != 0 && ((state & ParseState.Sign) == 0)) {
        state |= ParseState.Sign | ParseState.Parens;
        result.sign = 1;
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
          if (count < result.digits.length - 1) {
            result.digits[count++] = c;
            if (c != '0')
              end = count;
          }
          if ((state & ParseState.Decimal) == 0)
            result.scale++;
          state |= ParseState.NonZero;
        }
        else if ((state & ParseState.Decimal) != 0)
          result.scale--;
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

    result.precision = end;
    result.digits[end] = '\0';

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
          result.sign = 1;
          pos += eaten;
        }
        else if (c == ')' && (state & ParseState.Parens) != 0)
          state &= ~ParseState.Parens;
        else if (currencySymbol != null && (eaten = eat(currencySymbol, s, pos)) != -1) {
          currencySymbol = null;
          pos += eaten;
        }
        else if (!((isWhitespace(c) & (styles & NumberStyles.TrailingWhite)) != 0))
          break;
        else pos++;
      }

      if ((state & ParseState.Parens) == 0) {
        if ((state & ParseState.NonZero) == 0) {
          result.scale = 0;
          if ((state & ParseState.Decimal) == 0)
            result.sign = 0;
        }
        return true;
      }
      return false;
    }
    return false;
  }

  string toString(char format, int length, NumberFormat nf, bool isDecimal = false) {
    string ret;

    switch (format) {
      case 'n', 'N':
        if (length < 0)
          length = nf.numberDecimalDigits;
        round(scale + length);
        formatNumber(this, ret, length, nf);

        break;
      case 'g', 'G':
        bool doRounding = true;
        if (length < 1) {
          if (isDecimal && length == -1) {
            length = 29;
            doRounding = false;
          }
          else
            length = precision;
        }
        if (doRounding)
          round(length);
        else if (isDecimal && digits[0] == '\0')
          sign = 0;
        if (sign)
          ret ~= nf.negativeSign;
        
        formatGeneral(this, ret, length, (format == 'g') ? 'e' : 'E', nf);

        break;
      case 'c', 'C':
        if (length < 0)
          length = nf.currencyDecimalDigits;
        round(scale + length);
        formatCurrency(this, ret, length, nf);
        break;
      case 'f', 'F':
        if (length < 0)
          length = nf.numberDecimalDigits;
        round(scale + length);
        if (sign)
          ret ~= nf.negativeSign;
        formatFixed(this, ret, length, null, nf.numberDecimalSeparator, null);
        break;
      default:
    }

    return ret;
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
    else {
      sign = 0;
      scale = 0;
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
          else {
            c = (*p != '\0') ? *p++ : (pos > last) ? '0' : char.init;
          }

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
          if (last < 0 || (pointPos < count && *p != '\0')) {
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

private string ulongToString(ulong value, int digits) {
  if (digits < 1)
    digits = 1;

  char[100] buffer;
  int n = 100;
  while (--digits >= 0 || value != 0) {
    buffer[--n] = cast(char)(value % 10 + '0');
    value /= 10;
  }

  return buffer[n .. $].idup;
}

private string longToString(long value, int digits, string negativeSign) {
  if (digits < 1)
    digits = 1;

  char[100] buffer;
  ulong uv = (value >= 0) ? value : cast(ulong)-value;
  int n = 100;
  while (--digits >= 0 || uv != 0) {
    buffer[--n] = cast(char)(uv % 10 + '0');
    uv /= 10;
  }

  if (value < 0) {
    n -= negativeSign.length;
    buffer[n .. n + negativeSign.length] = negativeSign;
  }

  return buffer[n .. $].idup;
}

private string intToHexString(uint value, int digits, char format) {
  if (digits < 1)
    digits = 1;

  char[100] buffer;
  int n = 100;
  while (--digits >= 0 || value != 0) {
    uint v = value & 0xF;
    buffer[--n] = (v < 10) ? cast(char)(v + '0') : cast(char)(v + format - ('X' - 'A' + 10));
    value >>= 4;
  }

  return buffer[n .. $].idup;
}

private string longToHexString(ulong value, int digits, char format) {
  if (digits < 1)
    digits = 1;

  char[100] buffer;
  int n = 100;
  while (--digits >= 0 || value != 0) {
    ulong v = value & 0xF;
    buffer[--n] = (v < 10) ? cast(char)(v + '0') : cast(char)(v + format - ('X' - 'A' + 10));
    value >>= 4;
  }

  return buffer[n .. $].idup;
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

package string formatUInt(uint value, string format, IFormatProvider provider) {
  auto nf = NumberFormat.get(provider);

  int length;
  char specifier = parseFormatSpecifier(format, length);

  switch (specifier) {
    case 'g', 'G':
      if (length > 0)
        break;
      // fall through
      goto case;
    case 'd', 'D':
      return ulongToString(cast(ulong)value, length);
    case 'x', 'X':
      return intToHexString(value, length, specifier);
    default:
  }

  auto number = Number(cast(long)value, 10);
  if (specifier != char.init)
    return number.toString(specifier, length, nf);
  return number.toStringFormat(format, nf);
}

package string formatInt(int value, string format, IFormatProvider provider) {
  auto nf = NumberFormat.get(provider);

  int length;
  char specifier = parseFormatSpecifier(format, length);

  switch (specifier) {
    case 'g', 'G':
      if (length > 0)
        break;
      // fall through
      goto case;
    case 'd', 'D':
      return longToString(cast(long)value, length, nf.negativeSign);
    case 'x', 'X':
      return intToHexString(cast(uint)value, length, specifier);
    default:
  }

  auto number = Number(cast(long)value, 10);
  if (specifier != char.init)
    return number.toString(specifier, length, nf);
  return number.toStringFormat(format, nf);
}

package string formatULong(ulong value, string format, IFormatProvider provider) {
  auto nf = NumberFormat.get(provider);

  int length;
  char specifier = parseFormatSpecifier(format, length);

  switch (specifier) {
    case 'g', 'G':
      if (length > 0)
        break;
      // fall through
      goto case;
    case 'd', 'D':
      return ulongToString(value, length);
    case 'x', 'X':
      return longToHexString(value, length, specifier);
    default:
  }

  auto number = Number(cast(long)value, 20);
  if (specifier != char.init)
    return number.toString(specifier, length, nf);
  return number.toStringFormat(format, nf);
}

package string formatLong(long value, string format, IFormatProvider provider) {
  auto nf = NumberFormat.get(provider);

  int length;
  char specifier = parseFormatSpecifier(format, length);

  switch (specifier) {
    case 'g', 'G':
      if (length > 0)
        break;
      // fall through
      goto case;
    case 'd', 'D':
      return longToString(value, length, nf.negativeSign);
    case 'x', 'X':
      return longToHexString(cast(ulong)value, length, specifier);
    default:
  }

  auto number = Number(cast(long)value, 20);
  if (specifier != char.init)
    return number.toString(specifier, length, nf);
  return number.toStringFormat(format, nf);
}

package string formatFloat(float value, string format, IFormatProvider provider) {
  auto nf = NumberFormat.get(provider);

  int length;
  char specifier = parseFormatSpecifier(format, length);

  int precision = 7;

  switch (specifier) {
    case 'g', 'G':
      if (length > 7)
        precision = 9;
      goto default;
    default:
  }

  auto number = Number(cast(double)value, precision);
  if (specifier != char.init)
    return number.toString(specifier, length, nf);
  return number.toStringFormat(format, nf);
}

package string formatDouble(double value, string format, IFormatProvider provider) {
  auto nf = NumberFormat.get(provider);

  int length;
  char specifier = parseFormatSpecifier(format, length);

  int precision = 15;

  switch (specifier) {
    case 'g', 'G':
      if (length > 15)
        precision = 17;
      goto default;
    default:
  }

  auto number = Number(value, precision);
  if (specifier != char.init)
    return number.toString(specifier, length, nf, true);
  return number.toStringFormat(format, nf);
}

package string formatDecimal(Decimal value, string format, IFormatProvider provider) {
  auto nf = NumberFormat.get(provider);

  int length;
  char specifier = parseFormatSpecifier(format, length);

  auto number = Number(value);
  if (specifier != char.init)
    return number.toString(specifier, length, nf, true);
  return number.toStringFormat(format, nf);
}

// Must match NumberFormat.decimalPositivePattern
private const string positiveNumberFormat = "#";
// Must match NumberFormat.decimalNegativePattern
private const string[] negativeNumberFormats = [ "(#)", "-#", "- #", "#-", "# -" ];
// Must match NumberFormat.currencyPositivePattern
private const string[] positiveCurrencyFormats = [ "$#", "#$", "$ #", "# $" ];
// Must match NumberFormat.currencyNegativePattern
private const string[] negativeCurrencyFormats = [ "($#)", "-$#", "$-#", "$#-", "(#$)", "-#$", "#-$", "#$-", "-# $", "-$ #", "# $-", "$ #-", "$ -#", "#- $", "($ #)", "(# $)" ];
// Must match NumberFormat.percentPositivePattern
private const string[] positivePercentFormats = [ "# %", "#%", "%#", "% #" ];
// Must match NumberFormat.percentNegativePattern
private const string[] negativePercentFormats = [ "-# %", "-#%", "-%#", "%-#", "%#-", "#-%", "#%-", "-% #", "# %-", "% #-", "% -#", "#- %" ];


private void formatNumber(ref Number number, ref string dst, int length, NumberFormat nf) {
  string format = number.sign ? negativeNumberFormats[1] : positiveNumberFormat;

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

private void formatGeneral(ref Number number, ref string dst, int length, char format, NumberFormat nf) {
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

private void formatCurrency(ref Number number, ref string dst, int length, NumberFormat nf) {
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

private void formatFixed(ref Number number, ref string dst, int length, int[] groupSizes, string decimalSeparator, string groupSeparator) {
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
      int end = to!int(strlen(p));
      int start = (pos < end) ? pos : end;
      auto separator = array(retro(groupSeparator));
      dchar[] temp;

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
      dst ~= to!string(array(retro(temp)));
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

package uint parseUInt(string s, NumberStyles style, NumberFormat nf) {
  Number n;
  if (!Number.tryParse(s, style, nf, n))
    throw new FormatException("Input string was not valid.");

  long value;
  if (!n.toLong(value) || (value < uint.min || value > uint.max))
    throw new OverflowException("Value was either too small or too large for a uint.");
  return cast(uint)value;
}

package bool tryParseUInt(string s, NumberStyles style, NumberFormat nf, out uint result) {
  if (s == null) {
    result = 0;
    return false;
  }

  Number n;
  if (!Number.tryParse(s, style, nf, n))
    return false;

  long value;
  if (!n.toLong(value) || (value < uint.min || value > uint.max))
    return false;
  result = cast(uint)value;
  return true;
}

package int parseInt(string s, NumberStyles style, NumberFormat nf) {
  Number n;
  if (!Number.tryParse(s, style, nf, n))
    throw new FormatException("Input string was not valid.");

  long value;
  if (!n.toLong(value) || (value < int.min || value > int.max))
    throw new OverflowException("Value was either too small or too large for an int.");
  return cast(int)value;
}

package bool tryParseInt(string s, NumberStyles style, NumberFormat nf, out int result) {
  if (s == null) {
    result = 0;
    return false;
  }

  Number n;
  if (!Number.tryParse(s, style, nf, n))
    return false;

  long value;
  if (!n.toLong(value) || (value < int.min || value > int.max))
    return false;
  result = cast(int)value;
  return true;
}

package ulong parseULong(string s, NumberStyles style, NumberFormat nf) {
  Number n;
  if (!Number.tryParse(s, style, nf, n))
    throw new FormatException("Input string was not valid.");

  long value;
  if (!n.toLong(value) || (value < ulong.min || value > ulong.max))
    throw new OverflowException("Value was either too small or too large for a ulong.");
  return cast(ulong)value;
}

package bool tryParseULong(string s, NumberStyles style, NumberFormat nf, out ulong result) {
  if (s == null) {
    result = 0;
    return false;
  }

  Number n;
  if (!Number.tryParse(s, style, nf, n))
    return false;

  long value;
  if (!n.toLong(value) || (value < ulong.min || value > ulong.max))
    return false;
  result = cast(ulong)value;
  return true;
}

package long parseLong(string s, NumberStyles style, NumberFormat nf) {
  Number n;
  if (!Number.tryParse(s, style, nf, n))
    throw new FormatException("Input string was not valid.");

  long value;
  if (!n.toLong(value) || (value < long.min || value > long.max))
    throw new OverflowException("Value was either too small or too large for a long.");
  return value;
}

package bool tryParseLong(string s, NumberStyles style, NumberFormat nf, out long result) {
  if (s == null) {
    result = 0;
    return false;
  }

  Number n;
  if (!Number.tryParse(s, style, nf, n))
    return false;

  long value;
  if (!n.toLong(value) || (value < long.min || value > long.max))
    return false;
  result = value;
  return true;
}

package float parseFloat(string s, NumberStyles style, NumberFormat nf) {
  try {
    Number n;
    if (!Number.tryParse(s, style, nf, n))
      throw new FormatException("Input string was not valid.");

    double value;
    if (!n.toDouble(value))
      throw new OverflowException("Value was either too small or too large for a float.");
    float result = cast(float)value;
    if (std.math.isinf(result))
      throw new OverflowException("Value was either too small or too large for a float.");
    return result;
  }
  catch (FormatException ex) {
    if (s == nf.positiveInfinitySymbol)
      return float.infinity;
    else if (s == nf.negativeInfinitySymbol)
      return -float.infinity;
    else if (s == nf.nanSymbol)
      return float.nan;
    throw ex;
  }
}

package bool tryParseFloat(string s, NumberStyles style, NumberFormat nf, out float result) {
  if (s == null) {
    result = 0;
    return false;
  }

  Number n;
  double value;
  bool success = Number.tryParse(s, style, nf, n);
  if (success)
    success = n.toDouble(value);
  if (success) {
    result = cast(float)value;
    if (std.math.isinf(result))
      success = false;
  }

  if (!success) {
    if (s == nf.positiveInfinitySymbol)
      result = float.infinity;
    else if (s == nf.negativeInfinitySymbol)
      result = -float.infinity;
    else if (s == nf.nanSymbol)
      result = float.nan;
    else
      return false;
  }
  return true;
}

package double parseDouble(string s, NumberStyles style, NumberFormat nf) {
  try {
    Number n;
    if (!Number.tryParse(s, style, nf, n))
      throw new FormatException("Input string was not valid.");

    double value;
    if (!n.toDouble(value))
      throw new OverflowException("Value was either too small or too large for a float.");
    return value;
  }
  catch (FormatException ex) {
    if (s == nf.positiveInfinitySymbol)
      return double.infinity;
    else if (s == nf.negativeInfinitySymbol)
      return -double.infinity;
    else if (s == nf.nanSymbol)
      return double.nan;
    throw ex;
  }
}

package bool tryParseDouble(string s, NumberStyles style, NumberFormat nf, out double result) {
  if (s == null) {
    result = 0;
    return false;
  }

  Number n;
  bool success = Number.tryParse(s, style, nf, n);
  if (success)
    success = n.toDouble(result);

  if (!success) {
    if (s == nf.positiveInfinitySymbol)
      result = double.infinity;
    else if (s == nf.negativeInfinitySymbol)
      result = -double.infinity;
    else if (s == nf.nanSymbol)
      result = double.nan;
    else
      return false;
  }
  return true;
}

package Decimal parseDecimal(string s, NumberStyles style, NumberFormat nf) {
  try {
    Number n;
    if (!Number.tryParse(s, style, nf, n))
      throw new FormatException("Input string was not valid.");

    Decimal value;
    if (!n.toDecimal(value))
      throw new OverflowException("Value was either too small or too large for a Decimal.");
    return value;
  }
  catch (FormatException ex) {
    throw ex;
  }
}

package bool tryParseDecimal(string s, NumberStyles style, NumberFormat nf, out Decimal result) {
  if (s == null) {
    result = Decimal.zero;
    return false;
  }

  Number n;
  bool success = Number.tryParse(s, style, nf, n);
  if (success)
    success = n.toDecimal(result);
  return success;
}
