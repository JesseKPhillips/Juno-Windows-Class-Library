module juno.base.string;

private import juno.base.core,
  juno.intl.constants,
  juno.intl.core,
  juno.intl.format;
private import juno.base.meta : nameof;
private import std.utf : toUTF8, toUTF16z;
private static import std.stdarg;

public size_t wcslen(wchar* s) {
  wchar* p = s;
  while (p[0] != '\0')
    p++;
  return p - s;
}

public size_t strlen(char* s) {
  char* p = s;
  while (p[0] != '\0')
    p++;
  return p - s;
}

public wchar* toLPStr(char[] s, int i = 0, int len = -1) {
  if (s == null)
    return null;
  if (len == -1)
    len = s.length;
  return s[i .. len].toUTF16z();
}

public char[] toUtf8(wchar* s, int i = 0, int len = -1) {
  if (s == null || len == 0)
    return null;
  if (len == -1)
    len = wcslen(s);
  return s[i .. len].toUTF8();
}

// Overrides the Phobos implementation with a culturally aware version.
// This enables language-appropriate sorting on arrays of strings using the built-in 'sort' property.
// Note that equals is culture-insensitive.
public class TypeInfo_Aa : TypeInfo {

  public override char[] toString() {
    return "char[]";
  }

  public override hash_t getHash(void* p) {
    return .getHash(*cast(char[]*)p);
  }

  public override int equals(void* p1, void* p2) {
    return .equals(*cast(char[]*)p1, *cast(char[]*)p2);
  }

  public override int compare(void* p1, void* p2) {
    return .compare(*cast(char[]*)p1, *cast(char[]*)p2);
  }

  public override size_t tsize() {
    return (char[]).sizeof;
  }

}

public hash_t getHash(char[] string) {
  hash_t hash = 0;
  foreach (char c; string)
    hash = c + (hash << 6) + (hash << 16) - hash;
  return hash & int.max;
}

/**
 * Specifies the culture and case rules to be used for overloads of the string.compare and string.equals methods.
 */
public enum StringCompareOptions {
  /// Compare strings using culture-sensitive sort rules and the current culture.
  CurrentCulture,
  /// Compare strings using culture-sensitive sort rules, the current culture and ignore the case of the strings being compared.
  CultureCultureIgnoreCase,
  /// Compare strings using culture-sensitive sort rules and the invariant culture.
  InvariantCulture,
  /// Compare strings using culture-sensitive sort rules, the invariant culture and ignore the case of the strings being compared.
  InvariantCultureIgnoreCase
}

/**
 * Compares two specified strings.
 * Params:
 *        stringA = The first string.
 *        indexA = The position of the substring within stringA.
 *        stringB = The second string.
 *        indexB = The position of the substring within stringB.
 *        length = The maximum number of characters in the substrings to _compare.
 *        options = One of the StringCompareOptions values.
 * Returns: A value indicating the lexical relationship between the two comparands.
 */
public int compare(char[] stringA, int indexA, char[] stringB, int indexB, int length, StringCompareOptions options = StringCompareOptions.CurrentCulture) {
  if (length != 0 && (stringA != stringB || indexA != indexB)) {
    int lengthA = length, lengthB = length;
    if (stringA.length - indexA < lengthA)
      lengthA = stringA.length - indexA;
    if (stringB.length - indexB < lengthB)
      lengthB = stringB.length - indexB;
    switch (options) {
      case StringCompareOptions.CurrentCulture:
        return Culture.currentCulture.collation.compare(stringA, indexA, lengthA, stringB, indexB, lengthB, CompareOptions.None);
      case StringCompareOptions.CultureCultureIgnoreCase:
        return Culture.currentCulture.collation.compare(stringA, indexA, lengthA, stringB, indexB, lengthB, CompareOptions.IgnoreCase);
      case StringCompareOptions.InvariantCulture:
        return Culture.invariantCulture.collation.compare(stringA, indexA, lengthA, stringB, indexB, lengthB, CompareOptions.None);
      case StringCompareOptions.InvariantCultureIgnoreCase:
        return Culture.invariantCulture.collation.compare(stringA, indexA, lengthA, stringB, indexB, lengthB, CompareOptions.IgnoreCase);
      default:
    }
    throw new ArgumentException("The string comparison option passed in is not supported.", "options");
  }
  return 0;
}

/**
 * Ditto
 */
public int compare(char[] stringA, char[] stringB, StringCompareOptions options = StringCompareOptions.CurrentCulture) {
  if (stringA != stringB) {
    // If the strings don't have the same value, do a collation-based comparison.
    switch (options) {
      case StringCompareOptions.CurrentCulture:
        return Culture.currentCulture.collation.compare(stringA, stringB, CompareOptions.None);
      case StringCompareOptions.CultureCultureIgnoreCase:
        return Culture.currentCulture.collation.compare(stringA, stringB, CompareOptions.IgnoreCase);
      case StringCompareOptions.InvariantCulture:
        return Culture.invariantCulture.collation.compare(stringA, stringB, CompareOptions.None);
      case StringCompareOptions.InvariantCultureIgnoreCase:
        return Culture.invariantCulture.collation.compare(stringA, stringB, CompareOptions.IgnoreCase);
      default:
        throw new ArgumentException("The string comparison option passed in is not supported.", "options");
    }
    return -1;
  }
  return 0;
}

/**
 * Compares two specified strings.
 * Params:
 *        stringA = The first string.
 *        stringB = The second string.
 *        ignoreCase = A value indicating a case-sensitive or case-insensitive comparison (true indicates case-insensitive).
 *        culture = A Culture object that supplies _culture-specific information to influence the comparison.
 * Returns: A value indicating the lexical relationship between the two comparands.
 */
public int compare(char[] stringA, char[] stringB, bool ignoreCase, Culture culture = null) {
  if (culture is null)
    culture = Culture.currentCulture;
  return culture.collation.compare(stringA, stringB, ignoreCase ? CompareOptions.IgnoreCase : CompareOptions.None);
}

public bool equals(char[] stringA, char[] stringB) {
  return stringA == stringB;
}

public bool equals(char[] stringA, char[] stringB, StringCompareOptions options) {
  if (stringA != stringB) {
    // If the strings don't have the same value, do a collation-based comparison.
    switch (options) {
      case StringCompareOptions.CurrentCulture:
        return Culture.currentCulture.collation.compare(stringA, stringB, CompareOptions.None) == 0;
      case StringCompareOptions.CultureCultureIgnoreCase:
        return Culture.currentCulture.collation.compare(stringA, stringB, CompareOptions.IgnoreCase) == 0;
      case StringCompareOptions.InvariantCulture:
        return Culture.invariantCulture.collation.compare(stringA, stringB, CompareOptions.None) == 0;
      case StringCompareOptions.InvariantCultureIgnoreCase:
        return Culture.invariantCulture.collation.compare(stringA, stringB, CompareOptions.IgnoreCase) == 0;
      default:
    }
    throw new ArgumentException("The string comparison option passed in is not supported.", "options");
  }
  return true;
}

public int indexOf(char[] string, char value, int index = 0, int count = -1) {
  if (count == -1)
    count = string.length;
  int end = index + count;
  for (int i = index; i < end; i++) {
    if (string[i] == value)
      return i;
  }
  return -1;
}

public int indexOf(char[] string, char[] value, StringCompareOptions options = StringCompareOptions.CurrentCulture) {
  return indexOf(string, value, 0, string.length, options);
}

public int indexOf(char[] string, char[] value, int index, StringCompareOptions options = StringCompareOptions.CurrentCulture) {
  return indexOf(string, value, index, string.length - index, options);
}

public int indexOf(char[] string, char[] value, int index, int count, StringCompareOptions options = StringCompareOptions.CurrentCulture) {
  switch (options) {
    case StringCompareOptions.CurrentCulture:
      return Culture.currentCulture.collation.indexOf(string, value, index, count, CompareOptions.None);
    case StringCompareOptions.CultureCultureIgnoreCase:
      return Culture.currentCulture.collation.indexOf(string, value, index, count, CompareOptions.IgnoreCase);
    case StringCompareOptions.InvariantCulture:
      return Culture.invariantCulture.collation.indexOf(string, value, index, count, CompareOptions.None);
    case StringCompareOptions.InvariantCultureIgnoreCase:
      return Culture.invariantCulture.collation.indexOf(string, value, index, count, CompareOptions.IgnoreCase);
    default:
  }
  throw new ArgumentException("The string comparison option passed in is not supported.", "options");
}

public int lastIndexOf(char[] string, char[] value, StringCompareOptions options = StringCompareOptions.CurrentCulture) {
  return lastIndexOf(string, value, string.length - 1, string.length, options);
}

public int lastIndexOf(char[] string, char[] value, int index, StringCompareOptions options = StringCompareOptions.CurrentCulture) {
  return lastIndexOf(string, value, index, string.length - index, options);
}

public int lastIndexOf(char[] string, char[] value, int index, int count, StringCompareOptions options = StringCompareOptions.CurrentCulture) {
  if (string.length == 0 && (index == -1 || index == 0)) {
    if (value.length != 0)
      return -1;
    return 0;
  }
  if (index == string.length) {
    index--;
    if (count > 0)
      count--;
    if (value.length == 0 && count >= 0 && index - count + 1 >= 0)
      return index;
  }
  switch (options) {
    case StringCompareOptions.CurrentCulture:
      return Culture.currentCulture.collation.lastIndexOf(string, value, index, count, CompareOptions.None);
    case StringCompareOptions.CultureCultureIgnoreCase:
      return Culture.currentCulture.collation.lastIndexOf(string, value, index, count, CompareOptions.IgnoreCase);
    case StringCompareOptions.InvariantCulture:
      return Culture.invariantCulture.collation.lastIndexOf(string, value, index, count, CompareOptions.None);
    case StringCompareOptions.InvariantCultureIgnoreCase:
      return Culture.invariantCulture.collation.lastIndexOf(string, value, index, count, CompareOptions.IgnoreCase);
    default:
  }
  throw new ArgumentException("The string comparison option passed in is not supported.", "options");
}

public int lastIndexOf(char[] string, char value, int index = -1, int count = -1) {
  if (string.length == 0)
    return -1;
  if (index == -1)
    index = string.length - 1;
  if (count == -1)
    count = index + 1;
  int end = index - count + 1;
  for (int i = index; i >= end; i--) {
    if (string[i] == value)
      return i;
  }
  return -1;
}

public bool startsWith(char[] string, char[] value, bool ignoreCase, Culture culture) {
  if (culture is null)
    culture = Culture.currentCulture;
  return culture.collation.isPrefix(string, value, ignoreCase ? CompareOptions.IgnoreCase : CompareOptions.None);
}

public bool startsWith(char[] string, char[] value, StringCompareOptions options = StringCompareOptions.CurrentCulture) {
  if (string != value) {
    if (value.length != 0) {
      switch (options) {
        case StringCompareOptions.CurrentCulture:
          return Culture.currentCulture.collation.isPrefix(string, value, CompareOptions.None);
        case StringCompareOptions.CultureCultureIgnoreCase:
          return Culture.currentCulture.collation.isPrefix(string, value, CompareOptions.IgnoreCase);
        case StringCompareOptions.InvariantCulture:
          return Culture.invariantCulture.collation.isPrefix(string, value, CompareOptions.None);
        case StringCompareOptions.InvariantCultureIgnoreCase:
          return Culture.invariantCulture.collation.isPrefix(string, value, CompareOptions.IgnoreCase);
        default:
          break;
      }
      throw new ArgumentException("The string comparison option passed in is not supported.", "options");
    }
    return true;
  }
  return false;
}

public bool endsWith(char[] string, char[] value, bool ignoreCase, Culture culture) {
  if (culture is null)
    culture = Culture.currentCulture;
  return culture.collation.isSuffix(string, value, ignoreCase ? CompareOptions.IgnoreCase : CompareOptions.None);
}

public bool endsWith(char[] string, char[] value, StringCompareOptions options = StringCompareOptions.CurrentCulture) {
  if (string != value) {
    if (value.length != 0) {
      switch (options) {
        case StringCompareOptions.CurrentCulture:
          return Culture.currentCulture.collation.isSuffix(string, value, CompareOptions.None);
        case StringCompareOptions.CultureCultureIgnoreCase:
          return Culture.currentCulture.collation.isSuffix(string, value, CompareOptions.IgnoreCase);
        case StringCompareOptions.InvariantCulture:
          return Culture.invariantCulture.collation.isSuffix(string, value, CompareOptions.None);
        case StringCompareOptions.InvariantCultureIgnoreCase:
          return Culture.invariantCulture.collation.isSuffix(string, value, CompareOptions.IgnoreCase);
        default:
          break;
      }
      throw new ArgumentException("The string comparison option passed in is not supported.", "options");
    }
    return true;
  }
  return false;
}

public char[] toLower(char[] string, Culture culture = null) {
  if (culture is null)
    culture = Culture.currentCulture;
  return culture.collation.toLower(string);
}

public char[] toLowerInvariant(char[] string) {
  return toLower(string, Culture.invariantCulture);
}

public char[] toUpper(char[] string, Culture culture = null) {
  if (culture is null)
    culture = Culture.currentCulture;
  return culture.collation.toUpper(string);
}

public char[] toUpperInvariant(char[] string) {
  return toUpper(string, Culture.invariantCulture);
}

public char[] replace(char[] string, char oldChar, char newChar) {
  int len = string.length;
  int firstFound = -1;
  for (int i = 0; i < len; i++) {
    if (oldChar == string[i]) {
      firstFound = i;
      break;
    }
  }

  if (firstFound == -1)
    return string;

  char[] ret = string[0 .. firstFound];
  ret.length = len;
  for (int i = firstFound; i < len; i++)
    ret[i] = (string[i] == oldChar) ? newChar : string[i];

  return ret;
}

public char[] replace(char[] string, char[] oldValue, char[] newValue) {
  int[] indices = new int[string.length + oldValue.length];

  int index, count;
  while (((index = indexOf(string, oldValue, index, string.length - index)) > -1) && (index <= string.length - oldValue.length)) {
    indices[count++] = index;
    index += oldValue.length;
  }

  char[] ret;
  if (count != 0) {
    ret.length = string.length - ((oldValue.length - newValue.length) * count);
    int limit = count;
    count = 0;
    int i, j;
    while (i < string.length) {
      if (count < limit && i == indices[count]) {
        count++;
        i += oldValue.length;
        ret[j .. j + newValue.length] = newValue;
        j += newValue.length;
      }
      else
        ret[j++] = string[i++];
    }
  }
  else
    ret = string;
  return ret;
}

private enum Trim {
  Head,
  Tail,
  Both
}

public char[] trim(char[] string, char[] trimChars ...) {
  if (trimChars.length == 0)
    trimChars = WHITESPACECHARS;
  return trimHelper(string, trimChars, Trim.Both);
}

public char[] trimStart(char[] string, char[] trimChars ...) {
  if (trimChars.length == 0)
    trimChars = WHITESPACECHARS;
  return trimHelper(string, trimChars, Trim.Head);
}

public char[] trimEnd(char[] string, char[] trimChars ...) {
  if (trimChars.length == 0)
    trimChars = WHITESPACECHARS;
  return trimHelper(string, trimChars, Trim.Tail);
}

private char[] trimHelper(char[] string, char[] trimChars, Trim trimType) {
  int right = string.length - 1;
  int left;

  if (trimType == Trim.Head) {
    for (left = 0; left < string.length; left++) {
      char ch = string[left];
      int i;
      while (i < trimChars.length) {
        if (trimChars[i] == ch)
          break;
        i++;
      }
      if (i == trimChars.length)
        break;
    }
  }
  if (trimType == Trim.Tail) {
    for (right = string.length - 1; right >= left; right--) {
      char ch = string[right];
      int i;
      while (i < trimChars.length) {
        if (trimChars[i] == ch)
          break;
        i++;
      }
      if (i == trimChars.length)
        break;
    }
  }

  int len = right - left + 1;
  if (len == string.length)
    return string;
  if (len == 0)
    return "";
  return string[left .. right + 1];
}

public char[] padLeft(char[] string, int totalWidth, char paddingChar = ' ') {
  if (totalWidth < string.length)
    return string;
  char[] ret = new char[totalWidth];
  ret[totalWidth - string.length .. $] = string;
  ret[0 .. totalWidth - string.length] = paddingChar;
  return ret;
}

public char[] padRight(char[] string, int totalWidth, char paddingChar = ' ') {
  if (totalWidth < string.length)
    return string;
  char[] ret = string;
  ret.length = totalWidth;
  ret[string.length .. $] = paddingChar;
  return ret;
}

public char[][] split(char[] string, char[] separator = [' '], bool removeEmptyEntries = false) {

  int createSeparatorList(inout int[] separatorList) {
    int found;
    if (separator.length == 0) {
      for (int i = 0; i < string.length && found < separatorList.length; i++) {
        if (isWhiteSpace(string[i]))
          separatorList[found++] = i;
      }
    }
    else {
      for (int i = 0; i < string.length && found < separatorList.length; i++) {
        for (int j = 0; j < separator.length; j++) {
          if (string[i] == separator[j]) {
            separatorList[found++] = i;
            break;
          }
        }
      }
    }
    return found;
  }

  if (removeEmptyEntries && string.length == 0)
    return new char[][0];

  int[] separatorList = new int[string.length];
  int count = createSeparatorList(separatorList);

  if (count == 0)
    return [string];

  int currentIndex, arrayIndex;
  char[][] ret = new char[][count + 1];

  if (removeEmptyEntries) {
    for (int i = 0; i < count && currentIndex < string.length; i++) {
      if (separatorList[i] - currentIndex > 0)
        ret[arrayIndex++] = string[currentIndex .. separatorList[i]];
      currentIndex = separatorList[i] + 1;
    }
    if (currentIndex < string.length)
      ret[arrayIndex++] = string[currentIndex .. $];

    char[][] temp = ret;
    if (arrayIndex != count + 1) {
      temp.length = arrayIndex;
      for (int j = 0; j < arrayIndex; j++)
        temp[j] = ret[j];
    }
    ret = temp;
  }
  else {
    for (int i = 0; i < count && currentIndex < string.length; i++) {
      ret[arrayIndex++] = string[currentIndex .. separatorList[i]];
      currentIndex = separatorList[i] + 1;
    }

    if (currentIndex < string.length && count >= 0)
      ret[arrayIndex] = string[currentIndex .. $];
    else if (arrayIndex == count)
      ret[arrayIndex] = "";
  }

  return ret;
}

public char[] join(char[] separator, char[][] value, int index = 0, int count = -1) {
  if (count == -1)
    count = value.length;
  if (count == 0)
    return "";
  int end = index + count - 1;
  char[] result = value[index];
  for (int i = index + 1; i <= end; i++) {
    result ~= separator;
    result ~= value[i];
  }
  return result;
}

private const char[] WHITESPACECHARS = [ '\t', '\n', '\v', '\f', '\r', ' ' ];

public bool isWhiteSpace(char c) {
  foreach (char ch; WHITESPACECHARS) {
    if (ch == c)
      return true;
  }
  return false;
}

public T parse(T)(char[] string, NumberStyles style = NumberStyles.None, IProvidesFormat provider = null) {
  static if (is(T == ubyte)) {
    uint value = juno.intl.format.parseUInt(string, (style == NumberStyles.None) ? NumberStyles.Integer : style, NumberFormat.getInstance(provider));
    if (value < ubyte.min || value > ubyte.max)
      throw new OverflowException("Value was either too large or too small for a ubyte.");
    return cast(ubyte)value;
  }
  else static if (is(T == ushort)) {
    uint value = juno.intl.format.parseUInt(string, (style == NumberStyles.None) ? NumberStyles.Integer : style, NumberFormat.getInstance(provider));
    if (value < ushort.min || value > ushort.max)
      throw new OverflowException("Value was either too large or too small for a ushort.");
    return cast(ushort)value;
  }
  else static if (is(T == uint))
    return cast(T)juno.intl.format.parseUInt(string, (style == NumberStyles.None) ? NumberStyles.Integer : style, NumberFormat.getInstance(provider));
  else static if (is(T == byte)) {
    int value = juno.intl.format.parseInt(string, (style == NumberStyles.None) ? NumberStyles.Integer : style, NumberFormat.getInstance(provider));
    if (value < byte.min || value > byte.max)
      throw new OverflowException("Value was either too large or too small for a byte.");
    return cast(byte)value;
  }
  else static if (is(T == short)) {
    int value = juno.intl.format.parseInt(string, (style == NumberStyles.None) ? NumberStyles.Integer : style, NumberFormat.getInstance(provider));
    if (value < short.min || value > short.max)
      throw new OverflowException("Value was either too large or too small for a short.");
    return cast(short)value;
  }
  else static if (is(T == int))
    return juno.intl.format.parseInt(string, (style == NumberStyles.None) ? NumberStyles.Integer : style, NumberFormat.getInstance(provider));
  else static if (is(T == ulong))
    return juno.intl.format.parseULong(string, (style == NumberStyles.None) ? NumberStyles.Integer : style, NumberFormat.getInstance(provider));
  else static if (is(T == long))
    return juno.intl.format.parseLong(string, (style == NumberStyles.None) ? NumberStyles.Integer : style, NumberFormat.getInstance(provider));
  else static if (is(T == float))
    return juno.intl.format.parseFloat(string, (style == NumberStyles.None) ? NumberStyles.Float : style, NumberFormat.getInstance(provider));
  else static if (is(T == double))
    return juno.intl.format.parseDouble(string, (style == NumberStyles.None) ? NumberStyles.Float : style, NumberFormat.getInstance(provider));
  else static if (is(T == char)) {
    if (string.length != 1)
      throw new FormatException("String must be one character long.");
    return string[0];
  }
  else
    static assert(false, "Cannot convert string to " ~ nameof!(T) ~ ".");
}

/**
 * Converts the specified numeric value to its string equivalent.
 * Params:
 *        value = The numeric _value to convert.
 *        format = An optional _format string.
 *        provider = An optional IProvidesFormat that supplies culture-specified formatting information.
 */
public char[] toString(T)(T value, char[] format = null, IProvidesFormat provider = null) {
  static if (is(T == byte) ||
    is(T == short) ||
    is(T == int))
    return juno.intl.format.formatInt(cast(int)value, format, NumberFormat.getInstance(provider));
  else static if (is(T == ubyte) ||
    is(T == ushort) ||
    is(T == uint))
    return juno.intl.format.formatUInt(cast(uint)value, format, NumberFormat.getInstance(provider));
  else static if (is(T == ulong))
    return juno.intl.format.formatULong(value, format, NumberFormat.getInstance(provider));
  else static if (is(T == long))
    return juno.intl.format.formatLong(value, format, NumberFormat.getInstance(provider));
  else static if (is(T == float))
    return juno.intl.format.formatFloat(value, format, NumberFormat.getInstance(provider));
  else static if (is(T == double))
    return juno.intl.format.formatDouble(value, format, NumberFormat.getInstance(provider));
  else static if (is(T == char))
    return [value];
  else static if (is(T : char[]))
    return value;
  else static if (is(T : wchar[]))
    return std.utf.toUTF8(value);
  else static if (is(T : dchar[]))
    return std.utf.toUTF8(value);
  else static if (is(T == class))
    return value.toString();
  else static if (is(T == struct)) {
    static if (is(typeof(T.toString)))
      return value.toString();
    else
      return typeof(T).toString();
  }
  else
    throw new InvalidCastException("Cannot cast from '" ~ typeid(T).toString() ~ "' to 'char[]'.");
}

public enum TypeCode {
  Empty = 0,
  Void = 'v',
  Bool = 'x',
  UByte = 'h',
  Byte = 'g',
  UShort = 't',
  Short = 's',
  UInt = 'k',
  Int = 'i',
  ULong = 'm',
  Long = 'l',
  Float = 'f',
  Double = 'd',
  Real = 'e',
  Char = 'a',
  WChar = 'u',
  DChar = 'w',
  Array = 'A',
  Class = 'C',
  Struct = 'S',
  Enum = 'E',
  Pointer = 'P',
  Function = 'F',
  Delegate = 'D',
  Typedef = 'T',
  COMInterface = 'Z'
}

public struct Argument {

  private TypeInfo type_;
  private void* value_;
  private TypeCode typeCode_;

  public static Argument opCall(TypeInfo type, void* value) {
    Argument arg;
    arg.type_ = type;
    arg.value_ = value;
    arg.typeCode_ = cast(TypeCode)type.classinfo.name[9];

    if (arg.typeCode_ == TypeCode.Class && (cast(TypeInfo_Class)type).info.flags == 1)
      arg.typeCode_ = TypeCode.COMInterface;

    if (arg.typeCode_ == TypeCode.Enum) {
      arg.type_ = (cast(TypeInfo_Enum)type).base;
      arg.typeCode_ = cast(TypeCode)arg.type_.classinfo.name[9];
    }

    return arg;
  }

  public TypeInfo getType() {
    return type_;
  }

  public TypeCode getTypeCode() {
    return typeCode_;
  }

  public void* getValue() {
    return value_;
  }

  public char[] toString(char[] format, IProvidesFormat provider) {
    switch (typeCode_) {
      case TypeCode.Array:
        TypeCode typeCode = cast(TypeCode)type_.classinfo.name[10];
        if (typeCode == TypeCode.Char)
          return *cast(char[]*)value_;
        if (typeCode == TypeCode.WChar)
          return (*cast(wchar[]*)value_).toUTF8();
        if (typeCode == TypeCode.DChar)
          return (*cast(dchar[]*)value_).toUTF8();
        return type_.toString();
      case TypeCode.Bool:
        return *cast(bool*)value_ ? "True" : "False";
      case TypeCode.Char:
        return .toString(*cast(char*)value_, format, provider);
      case TypeCode.UByte:
        return .toString(*cast(ubyte*)value_, format, provider);
      case TypeCode.Byte:
        return .toString(*cast(byte*)value_, format, provider);
      case TypeCode.UShort:
        return .toString(*cast(ushort*)value_, format, provider);
      case TypeCode.Short:
        return .toString(*cast(short*)value_, format, provider);
      case TypeCode.UInt:
        return .toString(*cast(uint*)value_, format, provider);
      case TypeCode.Int:
        return .toString(*cast(int*)value_, format, provider);
      case TypeCode.ULong:
        return .toString(*cast(ulong*)value_, format, provider);
      case TypeCode.Long:
        return .toString(*cast(long*)value_, format, provider);
      case TypeCode.Float:
        return .toString(*cast(float*)value_, format, provider);
      case TypeCode.Double:
        return .toString(*cast(double*)value_, format, provider);
      case TypeCode.Class:
        return (*cast(Object*)value_).toString();
      case TypeCode.Struct:
        TypeInfo_Struct ti = cast(TypeInfo_Struct)type_;
        if (ti.xtoString != null)
          return ti.xtoString(value_);
        // fall through
      case TypeCode.COMInterface:
      case TypeCode.Function:
      case TypeCode.Delegate:
      case TypeCode.Typedef:
        return type_.toString();
      default:
    }
    return null;
  }

}

public struct ArgumentList {

  private Argument[] args_;
  private int size_;

  public static ArgumentList opCall(TypeInfo[] types, void* argptr) {
    ArgumentList argList;
    foreach (type; types) {
      Argument arg = Argument(type, argptr);
      argList.args_ ~= arg;
      if (arg.typeCode_ == TypeCode.Struct)
        argptr += (type.tsize() + 3) & ~3;
      else
        argptr += (type.tsize() + int.sizeof - 1) & ~(int.sizeof - 1);
      argList.size_++;
    }
    return argList;
  }

  public Argument opIndex(int index) {
    return args_[index];
  }

  public int count() {
    return size_;
  }

}

/**
 * Replaces items in the specified _format string with the string equivalent of an argument's value.
 * Params:
 *   provider = Supplies culture-specific formatting information.
 *   format = A _format string.
 *
 * Remarks:
 * Each _format item takes the following form:
 *
 * <b>{</b><i>index</i>[<b>,</b><i>alignment</i>][<b>:</b><i>formatString</i>]<b>}</b>
 *
 * The <i>index</i> identifies a corresponding item in the argument list. Multiple items can refer to the same argument in the list by specifying the same 
 * index. Each item can refer to any argument.
 *
 * The optional <i>alignment</i> indicates the field width.
 *
 * The optional <i>formatString</i> is a _format string appropriate for the type of argument being formatted.
 * Examples:
 * ---
 * void main() {
 *   char[] s = format(
 *     "Currency          {1:C}\n"
 *     "Decimal           {0:D}\n"
 *     "Fixed point       {1:F}\n"
 *     "General           {0:G}\n"
 *     "Number            {0:N}\n"
 *     "Percent           {1:P}\n"
 *     "Hexadecimal       {0:X}\n"
 *     , 123, 123.45);
 *   Console.writeln(s);
 * }
 *
 * /+
 *  Produces the following output:
 *  Currency          £123.45
 *  Decimal           123
 *  Fixed point       123.45
 *  General           123
 *  Number            123.00
 *  Percent           12,345.00 %
 *  Hexadecimal       7B
 *  +/
 * ---
 */
public char[] format(IProvidesFormat provider, char[] format, ...) {

  void formatError() {
    throw new FormatException("Input string was invalid.");
  }

  const char[256] SPACES = ' ';

  TypeInfo[] types = _arguments;
  void* argptr = _argptr;
  if (types.length == 2 && types[0] is typeid(TypeInfo[]) && types[1] is typeid(void*)) {
    types = std.stdarg.va_arg!(TypeInfo[])(argptr);
    argptr = *cast(void**)argptr;
  }

  ArgumentList args = ArgumentList(types, argptr);

  char[] result, chars = format;
  int len = format.length;
  int pos = 0;
  char ch;

  while (true) {
    int p = pos, i = pos;
    while (pos < len) {
      ch = chars[pos];
      pos++;
      if (ch == '}') {
        if (pos < len && chars[pos] == '}')
          pos++;
        else
          formatError();
      }
      if (ch == '{') {
        if (pos < len && chars[pos] == '{')
          pos++;
        else {
          pos--;
          break;
        }
      }
      chars[i++] = ch;
    }

    if (i > p)
      result ~= chars[p .. i];
    if (pos == len)
      break;
    pos++;

    if (pos == len || (ch = chars[pos]) < '0' || ch > '9')
      formatError();

    int index = 0;
    do {
      index = index * 10 + ch - '0';
      pos++;
      if (pos == len)
        formatError();
      ch = chars[pos];
    } while (ch >= '0' && ch <= '9');
    if (index >= args.count)
      throw new FormatException("Index must be greater than zero and less than the length of the argument list.");

    while (pos < len && (ch = chars[pos]) == ' ')
      pos++;

    int width = 0;
    bool leftAlign = false;
    if (ch == ',') {
      pos++;
      while (pos < len && (ch = chars[pos]) == ' ')
        pos++;
      if (pos == len)
        formatError();
      ch = chars[pos];
      if (ch == '-') {
        leftAlign = true;
        pos++;
        if (pos == len)
          formatError();
        ch = chars[pos];
      }
      if (ch < '0' || ch > '9')
        formatError();

      do {
        width = width * 10 + ch - '0';
        pos++;
        if (pos == len)
          formatError();
        ch = chars[pos];
      } while (ch >= '0' && ch <= '9');
    }

    while (pos < len && (ch = chars[pos]) == ' ')
      pos++;

    auto arg = args[index];
    char[] fmt = null;

    if (ch == ':') {
      pos++;
      p = pos, i = pos;
      while (true) {
        ch = chars[pos];
        pos++;
        if (ch == '{') {
          if (pos < len && chars[pos] == '{')
            pos++;
          else
            formatError();
        }
        if (ch == '}') {
          if (pos < len && chars[pos] == '}')
            pos++;
          else {
            pos--;
            break;
          }
        }
        chars[i++] = ch;
      }
      if (i > p)
        fmt = chars[p .. i];
    }

    if (ch != '}')
      formatError();
    pos++;

    char[] s = arg.toString(fmt, provider);

    int padding = width - s.length;
    if (padding > 255)
      padding = 255;
    if (!leftAlign && padding > 0)
      result ~= SPACES[0 .. padding];
    result ~= s;
    if (leftAlign && padding > 0)
      result ~= SPACES[0 .. padding];
  }

  return result;
}

/**
 * Ditto
 */
public char[] format(char[] format, ...) {
  return .format(cast(IProvidesFormat)null, format, _arguments, _argptr);
}