/**
 * Copyright: (c) 2008 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.locale.convert;

private import juno.base.core,
  juno.locale.constants,
  juno.locale.core,
  juno.locale.time,
  juno.locale.format;

private import std.string : icmp;

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
  else static if (is(T == bool))
    return value ? "True" : "False";
  else static if (is(T == char))
    return [value];
  else static if (is(T : string))
    return value;
  else static if (is(T == class))
    return value.toString();
  else static if (is(T == struct)) {
    static if (is(T == DateTime))
      return value.toString(format, DateTimeFormat.get(provider));
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

T parse(T)(string s, NumberStyles style = NumberStyles.None, IFormatProvider provider = null) {
  static if (is(T == ubyte)) {
    uint value = parseUInt(s, (style == NumberStyles.None) ? NumberStyles.Integer : style, NumberFormat.get(provider));
    if (value < ubyte.min || value > ubyte.max)
      throw new OverflowException("Value was either too large or too small for a ubyte.");
    return cast(ubyte)value;
  }
  else static if (is(T == byte)) {
    uint value = parseUInt(s, (style == NumberStyles.None) ? NumberStyles.Integer : style, NumberFormat.get(provider));
    if (value < byte.min || value > byte.max)
      throw new OverflowException("Value was either too large or too small for a byte.");
    return cast(byte)value;
  }
  else static if (is(T == ushort)) {
    uint value = parseUInt(s, (style == NumberStyles.None) ? NumberStyles.Integer : style, NumberFormat.get(provider));
    if (value < ushort.min || value > ushort.max)
      throw new OverflowException("Value was either too large or too small for a ushort.");
    return cast(ushort)value;
  }
  else static if (is(T == short)) {
    uint value = parseUInt(s, (style == NumberStyles.None) ? NumberStyles.Integer : style, NumberFormat.get(provider));
    if (value < short.min || value > short.max)
      throw new OverflowException("Value was either too large or too small for a short.");
    return cast(short)value;
  }
  else static if (is(T == uint))
    return parseUInt(s, (style == NumberStyles.None) ? NumberStyles.Integer : style, NumberFormat.get(provider));
  else static if (is(T == int))
    return parseInt(s, (style == NumberStyles.None) ? NumberStyles.Integer : style, NumberFormat.get(provider));
  else static if (is(T == ulong))
    return parseULong(s, (style == NumberStyles.None) ? NumberStyles.Integer : style, NumberFormat.get(provider));
  else static if (is(T == long))
    return parseLong(s, (style == NumberStyles.None) ? NumberStyles.Integer : style, NumberFormat.get(provider));
  // Floating-point code is buggy and needs re-writing.
  /*else static if (is(T == float))
    return parseFloat(s, (style == NumberStyles.None) ? NumberStyles.Float : style, NumberFormat.get(provider));
  else static if (is(T == double))
    return parseDouble(s, (style == NumberStyles.None) ? NumberStyles.Float : style, NumberFormat.get(provider));*/
  /*else static if (is(T == char)) {
    if (s.length != 1)
      throw new FormatException("String must be exactly one character long.");
    return s[0];
  }
  else static if (is(T == bool)) {
    if (icmp(s, "True") == 0)
      return true;
    else if (icmp(s, "False") == 0)
      return false;
    else
      throw new FormatException("String was not recognised as a bool.");
  }*/
  else
    static assert(false, "Cannot convert string to '" ~ T.stringof ~ "'.");
}