/**
 * Copyright: (c) 2009 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.locale.convert;

private import juno.base.core,
  juno.locale.constants,
  juno.locale.core,
  juno.locale.time,
  juno.locale.numeric;

/**
 * Converts the specified _value to its equivalent string representation.
 */
string toString(T)(T value, string format = null, IFormatProvider provider = null) {
  static if (is(T == ubyte)
    || is(T == ushort)
    || is(T == uint))
    return formatUInt(cast(uint)value, format, NumberFormat.get(provider));
  else static if (is(T == ulong))
    return formatULong(value, format, NumberFormat.get(provider));
  else static if (is(T == byte)
    || is(T == short)
    || is(T == int))
    return formatInt(cast(int)value, format, NumberFormat.get(provider));
  else static if (is(T == long))
    return formatLong(value, format, NumberFormat.get(provider));
  else static if (is(T == float))
    return formatFloat(value, format, NumberFormat.get(provider));
  else static if (is(T == double))
    return formatFloat(value, format, NumberFormat.get(provider));
  else static if (is(T == bool))
    return value ? "True" : "False";
  else static if (is(T == char))
    return [value];
  else static if (is(T == wchar))
    return std.utf.toUTF8([value]);
  else static if (is(T == string))
    return value;
  static if (is(T == struct)) {
    static if (is(T == DateTime))
      return value.toString(format, DateTimeFormat.get(provider));
    else static if (is(T == juno.com.core.Decimal))
      return formatDecimal(value, format, NumberFormat.get(provider));
    else static if (is(typeof(T.toString)))
      return value.toString();
    else
      return typeid(T).toString();
  }
  else static if (is(T E == enum))
    return toString(cast(E)value, format, provider);
  else
    throw new InvalidCastException("Cannot convert from '" ~ T.stringof ~ "' to 'string'.");
}

/**
 * Converts a string representation of a number to its numeric equivalent.
 */
T parse(T)(string s, NumberStyles style = NumberStyles.None, IFormatProvider provider = null) {
  static if (is(T == ubyte)
    || is(T == ushort)
    || is(T == uint))
    return cast(T)parseUInt(s, (style == NumberStyles.None) ? NumberStyles.Integer : style, NumberFormat.get(provider));
  else static if (is(T == byte)
    || is(T == short)
    || is(T == int))
    return cast(T)parseInt(s, (style == NumberStyles.None) ? NumberStyles.Integer : style, NumberFormat.get(provider));
  else static if (is(T == ulong))
    return parseULong(s, (style == NumberStyles.None) ? NumberStyles.Integer : style, NumberFormat.get(provider));
  else static if (is(T == long))
    return parseLong(s, (style == NumberStyles.None) ? NumberStyles.Integer : style, NumberFormat.get(provider));
  else static if (is(T == float))
    return parseFloat(s, (style == NumberStyles.None) ? NumberStyles.Float | NumberStyles.Thousands : style, NumberFormat.get(provider));
  else static if (is(T == double))
    return parseDouble(s, (style == NumberStyles.None) ? NumberStyles.Float | NumberStyles.Thousands : style, NumberFormat.get(provider));
  else static if (is(T == juno.com.core.Decimal))
    return parseDecimal(s, (style == NumberStyles.None) ? NumberStyles.Number : style, NumberFormat.get(provider));
  else
    static assert(false, "Cannot convert string to '" ~ T.stringof ~ "'.");
}

/**
 * Converts a string representation of a number to its numeric equivalent. The return value indicates whether the conversion succeeded or failed.
 */
bool tryParse(T)(string s, out T result, NumberStyles style = NumberStyles.None, IFormatProvider provider = null) {
  static if (is(T == uint))
    return tryParseUInt(s, (style == NumberStyles.None) ? NumberStyles.Integer : style, NumberFormat.get(provider), result);
  else static if (is(T == int))
    return tryParseInt(s, (style == NumberStyles.None) ? NumberStyles.Integer : style, NumberFormat.get(provider), result);
  else static if (is(T == ulong))
    return tryParseULong(s, (style == NumberStyles.None) ? NumberStyles.Integer : style, NumberFormat.get(provider), result);
  else static if (is(T == long))
    return tryParseLong(s, (style == NumberStyles.None) ? NumberStyles.Integer : style, NumberFormat.get(provider), result);
  else static if (is(T == float))
    return tryParseFloat(s, (style == NumberStyles.None) ? NumberStyles.Float | NumberStyles.Thousands : style, NumberFormat.get(provider), result);
  else static if (is(T == double))
    return tryParseDouble(s, (style == NumberStyles.None) ? NumberStyles.Float | NumberStyles.Thousands : style, NumberFormat.get(provider), result);
  else static if (is(T == juno.com.core.Decimal))
    return tryParseDecimal(s, (style == NumberStyles.None) ? NumberStyles.Number : style, NumberFormat.get(provider), result);
  return false;
}
