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

/**
 * Contains methods for working with strings.
 */
module juno.base.string;

private import juno.base.numeric,
  juno.locale.constants;
private import juno.locale.core : IFormatProvider, Culture, DateTime;

private import std.utf : toUTF8, toUTF16z;
private import std.string : toStringz;
private import std.stdarg;
private import std.c.string : memcpy;

public size_t strlen(char* s) {
  char* p = s;
  while (p[0] != '\0')
    p++;
  return p - s;
}

public size_t wcslen(wchar* s) {
  wchar* p = s;
  while (p[0] != '\0')
    p++;
  return p - s;
}

public char* toUtf8z(string s, int start = 0, int count = -1) {
  if (s == null)
    return null;
  if (count == -1)
    count = s.length;
  return s[start .. count].toStringz();
}

public wchar* toUtf16z(string s, int start = 0, int count = -1) {
  if (s == null)
    return null;
  if (count == -1)
    count = s.length;
  return s[start .. count].toUTF16z();
}

public string toUtf8(wchar* s, int start = 0, int count = -1) {
  if (s == null)
    return null;
  if (count == -1)
    count = wcslen(s);
  return s[start .. count].toUTF8();
}

public string toUtf8(wstring s, int start = 0, int count = -1) {
  if (s == null)
    return null;
  if (count == -1)
    count = s.length;
  return s[start .. count].toUTF8();
}

public string toUtf8(dstring s, int start = 0, int count = -1) {
  if (s == null)
    return null;
  if (count == -1)
    count = s.length;
  return s[start .. count].toUTF8();
}

/**
 * Compares two specified strings, ignoring or honouring their case.
 * Params:
 *   stringA = The first string.
 *   stringB = The second string.
 *   ignoreCase = A value indicating a case- sensitive or insensitive comparison.
 * Returns: An integer indicating the lexical relationship between the two strings (less than zero if stringA is less then stringB; zero if stringA equals stringB; greater than zero if stringA is greater than stringB).
 */
public int compare(string stringA, string stringB, bool ignoreCase = false) {
  if (stringA != stringB) {
    if (stringA == null)
      return -1;
    if (stringB == null)
      return -1;

    return Culture.current.collator.compare(stringA, stringB, ignoreCase ? CompareOptions.IgnoreCase : CompareOptions.None);
  }
  return 0;
}

/**
 * Compares two specified strings, ignoring or honouring their case.
 * Params:
 *   stringA = The first string.
 *   indexA = The position of the substring withing stringA.
 *   stringB = The second string.
 *   indexB = The position of the substring withing stringB.
 *   ignoreCase = A value indicating a case- sensitive or insensitive comparison.
 * Returns: An integer indicating the lexical relationship between the two strings (less than zero if the substring in stringA is less then the substring in stringB; zero if the substrings are equal; greater than zero if the substring in stringA is greater than the substring in stringB).
 */
public int compare(string stringA, int indexA, string stringB, int indexB, int length, bool ignoreCase = false) {
  if (length != 0 && (stringA != stringB || indexA != indexB)) {
    int lengthA = length, lengthB = length;
    if (stringA.length - indexA < lengthA)
      lengthA = stringA.length - indexA;
    if (stringB.length - indexB < lengthB)
      lengthB = stringB.length - indexB;

    return Culture.current.collator.compare(stringA, indexA, lengthA, stringB, indexB, lengthB, ignoreCase ? CompareOptions.IgnoreCase : CompareOptions.None);
  }
  return 0;
}

/**
 * Determines whether the two strings are the same.
 * Params:
 *   stringA = The first string.
 *   stringB = The second string.
 * Returns: true if stringA is the same as stringB; otherwise, false.
 */
public bool equals(string stringA, string stringB) {
  return stringA == stringB;
}

/**
 * Determines whether two specified strings are the same, ignoring or honouring their case.
 * Params:
 *   stringA = The first string.
 *   stringB = The second string.
 *   ignoreCase = A value indicating a case- sensitive or insensitive comparison.
 * Returns: true if stringA is the same as stringB; otherwise, false.
 */
public bool equals(string stringA, string stringB, bool ignoreCase) {
  return Culture.current.collator.compare(stringA, stringB, ignoreCase ? CompareOptions.IgnoreCase : CompareOptions.None) == 0;
}

/**
 * Determines whether the value parameter occurs within the s parameter.
 * Params:
 *   s = The string to search within.
 *   value = The string to find.
 * Returns: true if the value parameter occurs within the s parameter; otherwise, false.
 */
public bool contains(string s, string value) {
  return s.indexOf(value) >= 0;
}

/**
 * Retrieves the index of the first occurrence of the specified character within the specified string.
 * Params:
 *   s = The string to search within.
 *   value = The character to find.
 *   index = The start position of the search.
 *   count = The number of characters to examine.
 * Returns: The index of value if that character is found, or -1 if it is not.
 */
public int indexOf(string s, char value, int index = 0, int count = -1) {
  if (count == -1)
    count = s.length - index;

  int end = index + count;
  for (int i = index; i < end; i++) {
    if (s[i] == value)
      return i;
  }

  return -1;
}

/**
 * Retrieves the index of the first occurrence of the specified value in the specified string s.
 * Params:
 *   s = The string to search within.
 *   value = The string to find.
 *   index = The start position of the search.
 *   count = The number of characters to examine.
 *   ignoreCase = A value indicating a case- sensitive or insensitive comparison.
 * Returns: The index of value if that string is found, or -1 if it is not.
 */
public int indexOf(string s, string value, int index, int count, bool ignoreCase = false) {
  return Culture.current.collator.indexOf(s, value, index, count, ignoreCase ? CompareOptions.IgnoreCase : CompareOptions.None);
}

/**
 * Ditto
 */
public int indexOf(string s, string value, int index, bool ignoreCase = false) {
  return indexOf(s, value, index, s.length - index, ignoreCase);
}

/**
 * Ditto
 */
public int indexOf(string s, string value, bool ignoreCase = false) {
  return indexOf(s, value, 0, s.length, ignoreCase);
}

/**
 * Retrieves the index of the last occurrence of the specified character within the specified string.
 * Params:
 *   s = The string to search within.
 *   value = The character to find.
 *   index = The start position of the search.
 *   count = The number of characters to examine.
 * Returns: The index of value if that character is found, or -1 if it is not.
 */
public int lastIndexOf(string s, char value, int index = 0, int count = -1) {
  if (s.length == 0)
    return -1;
  if (count == -1) {
    index = s.length - 1;
    count = s.length;
  }

  int end = index - count + 1;
  for (int i = index; i >= end; i--) {
    if (s[i] == value)
      return i;
  }

  return -1;
}

/**
 * Retrieves the index of the last occurrence of value within the specified string s.
 * Params:
 *   s = The string to search within.
 *   value = The string to find.
 *   index = The start position of the search.
 *   count = The number of characters to examine.
 *   ignoreCase = A value indicating a case- sensitive or insensitive comparison.
 * Returns: The index of value if that character is found, or -1 if it is not.
 */
public int lastIndexOf(string s, string value, int index, int count, bool ignoreCase = false) {
  if (s.length == 0 && (index == -1 || index == 0)) {
    if (value.length != 0)
      return -1;
    return 0;
  }

  if (index == s.length) {
    index--;
    if (count > 0)
      count--;
    if (value.length == 0 && count >= 0 && (index - count) + 1 >= 0)
      return index;
  }

  return Culture.current.collator.lastIndexOf(s, value, index, count, ignoreCase ? CompareOptions.IgnoreCase : CompareOptions.None);
}

/**
 * Ditto
 */
public int lastIndexOf(string s, string value, int index, bool ignoreCase = false) {
  return lastIndexOf(s, value, index, index + 1, ignoreCase);
}

/**
 * Ditto
 */
public int lastIndexOf(string s, string value, bool ignoreCase = false) {
  return lastIndexOf(s, value, s.length - 1, s.length, ignoreCase);
}

/**
 * Determines whether the beginning of s matches value.
 * Params:
 *   s = The string to search.
 *   value = The string to compare.
 *   ignoreCase = A value indicating a case- sensitive or insensitive comparison.
 * Returns: true if value matches the beginning of s; otherwise, false.
 */
public bool startsWith(string s, string value, bool ignoreCase = false) {
  if (s == value)
    return true;
  return Culture.current.collator.isPrefix(s, value, ignoreCase ? CompareOptions.IgnoreCase : CompareOptions.None);
}

/**
 * Determines whether the end of s matches value.
 * Params:
 *   s = The string to search.
 *   value = The string to compare.
 *   ignoreCase = A value indicating a case- sensitive or insensitive comparison.
 * Returns: true if value matches the end of s; otherwise, false.
 */
public bool endsWith(string s, string value, bool ignoreCase = false) {
  if (s == value)
    return true;
  return Culture.current.collator.isSuffix(s, value, ignoreCase ? CompareOptions.IgnoreCase : CompareOptions.None);
}

/**
 * Inserts value at the specified index in s.
 * Params:
 *   s = The string in which to insert value.
 *   index = The position of the insertion.
 *   value = The string to _insert.
 * Returns: A new string with value inserted at index.
 */
public string insert(string s, int index, string value) {
  if (value.length == 0 || s.length == 0)
    return s.dup;

  int newLength = s.length + value.length;
  char[] newString = new char[newLength];

  newString[0 .. index] = s[0 .. index];
  newString[index .. index + value.length] = value;
  newString[index + value.length .. $] = s[index .. $];
  return newString.dup;
}

private final char[] WhiteSpaceChars = [ '\t', '\n', '\v', '\f', '\r', ' ' ];

/**
 * Indicates whether the specified character is white space.
 * Params: c = A character.
 * Returns: true if c is white space; otherwise, false.
 */
public bool isWhiteSpace(char c) {
  foreach (ch; WhiteSpaceChars) {
    if (ch == c)
      return true;
  }
  return false;
}

/**
 * Returns a string array containing the substrings in s that are delimited by elements of the specified char array.
 * Params:
 *   s = The string to _split.
 *   separator = An array of characters that delimit the substrings in s.
 *   count = The maximum number of substrings to return.
 *   removeEmptyEntries = true to omit empty array elements from the array returned, or false to include empty array elements in the array returned.
 * Returns: An array whose elements contain the substrings in s that are delimited by one or more characters in separator.
 */
public string[] split(string s, char[] separator, int count = int.max, bool removeEmptyEntries = false) {

  int createSeparatorList(ref int[] sepList) {
    int foundCount;
    if (separator.length == 0) {
      for (int i = 0; i < s.length && foundCount < sepList.length; i++) {
        if (isWhiteSpace(s[i]))
          sepList[foundCount++] = i;
      }
    }
    else {
      for (int i = 0; i < s.length && foundCount < sepList.length; i++) {
        for (int j = 0; j < separator.length; j++) {
          if (s[i] == separator[j]) {
            sepList[foundCount++] = i;
            break;
          }
        }
      }
    }
    return foundCount;
  }

  if (count == 0 || (removeEmptyEntries && s.length == 0))
    return new string[0];

  int[] sepList = new int[s.length];
  int replaceCount = createSeparatorList(sepList);

  if (replaceCount == 0 || count == 1)
    return [ s ];

  string[] splitStrings;
  int arrayIndex, currentIndex;

  if (removeEmptyEntries) {
    int max = (replaceCount < count) ? replaceCount + 1 : count;
    splitStrings.length = max;
    for (int i = 0; i < replaceCount && currentIndex < s.length; i++) {
      if (sepList[i] - currentIndex > 0)
        splitStrings[arrayIndex++] = s[currentIndex .. sepList[i]];
      currentIndex = sepList[i] + 1;
      if (arrayIndex == count - 1) {
        while (i < replaceCount - 1 && currentIndex == sepList[++i]) {
          currentIndex += 1;
        }
        break;
      }
    }

    if (currentIndex < s.length)
      splitStrings[arrayIndex++] = s[currentIndex .. $];

    string[] strings = splitStrings;
    if (arrayIndex != max) {
      strings.length = arrayIndex;
      for (int j = 0; j < arrayIndex; j++)
        strings[j] = splitStrings[j];
    }
    splitStrings = strings;
  }
  else {
    count--;
    int max = (replaceCount < count) ? replaceCount : count;
    splitStrings.length = max + 1;
    for (int i = 0; i < max && currentIndex < s.length; i++) {
      splitStrings[arrayIndex++] = s[currentIndex .. sepList[i]];
      currentIndex = sepList[i] + 1;
    }

    if (currentIndex < s.length && max >= 0)
      splitStrings[arrayIndex] = s[currentIndex .. $];
    else if (arrayIndex == max)
      splitStrings[arrayIndex] = null;
  }

  return splitStrings;
}

/**
 * Ditto
 */
public string[] split(string s, char[] separator, bool removeEmptyEntries) {
  return split(s, separator, int.max, removeEmptyEntries);
}

/**
 * Concatenates separator between each element of value, returning a single concatenated string.
 * Params:
 *   separator = A string.
 *   value = An array of strings.
 *   index = The first element in value to use.
 *   count = The number of elements of value to use.
 * Returns: A string containing the strings in value joined by separator.
 */
public string join(string separator, string[] value, int index = 0, int count = -1) {
  if (count == -1)
    count = value.length;
  if (count == 0)
    return "";

  int end = index + count - 1;
  string result = value[index];
  for (int i = index + 1; i <= end; i++) {
    result ~= separator;
    result ~= value[i];
  }
  return result;
}

/**
 * Replaces all instances of oldChar with newChar in s.
 * Params:
 *   s = A string containing oldChar.
 *   oldChar = The character to be replaced.
 *   newChar = The character to replace all instances of oldChar.
 * Returns: A string equivalent to s but with all instances of oldChar replaced with newChar.
 */
public string replace(string s, char oldChar, char newChar) {
  int len = s.length;
  int firstFound = -1;
  for (int i = 0; i < len; i++) {
    if (oldChar == s[i]) {
      firstFound = i;
      break;
    }
  }

  if (firstFound == -1)
    return s.dup;

  char[] ret = s[0 .. firstFound].dup;
  ret.length = len;
  for (int i = firstFound; i < len; i++)
    ret[i] = (s[i] == oldChar) ? newChar : s[i];
  return ret.dup;
}

/**
 * Replaces all instances of oldValue with newValue in s.
 * Params:
 *   s = A string containing oldValue.
 *   oldValue = The string to be replaced.
 *   newValue = The string to replace all instances of oldValue.
 * Returns: A string equivalent to s but with all instances of oldValue replaced with newValue.
 */
public string replace(string s, string oldValue, string newValue) {
  int[] indices = new int[s.length + oldValue.length];

  int index, count;
  while (((index = indexOf(s, oldValue, index, s.length - index)) > -1) &&
    (index <= s.length - oldValue.length)) {
    indices[count++] = index;
    index += oldValue.length;
  }

  char[] ret;
  if (count != 0) {
    ret.length = s.length - ((oldValue.length - newValue.length) * count);
    int limit = count;
    count = 0;
    int i, j;
    while (i < s.length) {
      if (count < limit && i == indices[count]) {
        count++;
        i += oldValue.length;
        ret[j .. j + newValue.length] = newValue;
        j += newValue.length;
      }
      else
        ret[j++] = s[i++];
    }
  }
  else
    return s.dup;
  return ret.dup;
}

/**
 * Right-aligns the characters in s, padding on the left with paddingChar for a specified total length.
 * Params:
 *   s = The string to pad.
 *   totalWidth = The number of characters in the resulting string.
 *   paddingChar = A padding character.
 * Returns: A string equivalent to s but right-aligned and padded on the left with paddingChar.
 */
public string padLeft(string s, int totalWidth, char paddingChar = ' ') {
  if (totalWidth < s.length)
    return s.dup;
  char[] ret = new char[totalWidth];
  ret[totalWidth - s.length .. $] = s;
  ret[0 .. totalWidth - s.length] = paddingChar;
  return ret.dup;
}

/**
 * Left-aligns the characters in s, padding on the right with paddingChar for a specified total length.
 * Params:
 *   s = The string to pad.
 *   totalWidth = The number of characters in the resulting string.
 *   paddingChar = A padding character.
 * Returns: A string equivalent to s but left-aligned and padded on the right with paddingChar.
 */
public string padRight(string s, int totalWidth, char paddingChar = ' ') {
  if (totalWidth < s.length)
    return s.dup;
  char[] ret = s.dup;
  ret.length = totalWidth;
  ret[s.length .. $] = paddingChar;
  return ret.dup;
}

private enum Trim {
  Head,
  Tail,
  Both
}

/**
 * Removes all leading and trailing occurrences of a set of characters specified in trimChars from s.
 * Returns: The string that remains after all occurrences of the characters in trimChars are removed from the start and end of s.
 */
public string trim(string s, char[] trimChars ...) {
  if (trimChars.length == 0)
    trimChars = WhiteSpaceChars;
  return trimHelper(s, trimChars, Trim.Both);
}

/**
 * Removes all leading occurrences of a set of characters specified in trimChars from s.
 * Returns: The string that remains after all occurrences of the characters in trimChars are removed from the start of s.
 */
public string trimStart(string s, char[] trimChars ...) {
  if (trimChars.length == 0)
    trimChars = WhiteSpaceChars;
  return trimHelper(s, trimChars, Trim.Head);
}

/**
 * Removes all trailing occurrences of a set of characters specified in trimChars from s.
 * Returns: The string that remains after all occurrences of the characters in trimChars are removed from the end of s.
 */
public string trimEnd(string s, char[] trimChars ...) {
  if (trimChars.length == 0)
    trimChars = WhiteSpaceChars;
  return trimHelper(s, trimChars, Trim.Tail);
}

private string trimHelper(string s, char[] trimChars, Trim trimType) {
  int right = s.length - 1;
  int left;

  if (trimType != Trim.Tail) {
    for (left = 0; left < s.length; left++) {
      char ch = s[left];
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
  if (trimType != Trim.Head) {
    for (right = s.length - 1; right >= left; right--) {
      char ch = s[right];
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
  if (len == s.length)
    return s.dup;
  if (len == 0)
    return null;
  return s[left .. right + 1].dup;
}

/**
 * Retrieves a _substring from s starting at the specified character position.
 * Params:
 *   s = A string.
 *   index = The starting character position of a _substring in s.
 * Returns: The _substring that begins at index in s.
 */
public string substring(string s, int index) {
  return substring(s, index, s.length - index);
}

/**
 * Retrieves a _substring from s starting at the specified character position and has a specified length.
 * Params:
 *   s = A string.
 *   index = The starting character position of a _substring in s.
 *   length = The number of characters in the _substring.
 * Returns: The _substring of length that begins at index in s.
 */
public string substring(string s, int index, int length) {
  if (length == 0)
    return null;

  if (index == 0 && length == s.length)
    return s.dup;

  char[] ret = new char[length];
  memcpy(ret.ptr, s.ptr + index, length * char.sizeof);
  return ret.dup;
}

/**
 * Returns a copy of s converted to lowercase.
 * Params: s = The string to convert.
 * Returns: a string in lowercase.
 */
public string toLower(string s) {
  return Culture.current.collator.toLower(s);
}

/**
 * Returns a copy of s converted to uppercase.
 * Params: s = The string to convert.
 * Returns: a string in uppercase.
 */
public string toUpper(string s) {
  return Culture.current.collator.toUpper(s);
}

/**
 * Replaces the _format items in a specified string with the text equivalents of the specified values in the specified arguments.
 * Params:
 *   provider = Specifies culture-specific formatting information.
 *   format = A _format string.
 * Returns: A copy of format in which the _format items have been replaced by the text equivalents of the values in the specified arguments.
 */
public string format(IFormatProvider provider, string format, ...) {

  enum TypeCode {
    Empty,
    Void = 'v',
    Bool = 'b',
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
    Typedef = 'T'
  }

  struct Argument {

    TypeInfo type;
    TypeCode typeCode;
    void* value;

    static Argument opCall(TypeInfo type, void* value) {
      Argument a;
      a.type = type;
      a.value = value;
      a.typeCode = cast(TypeCode)type.classinfo.name[9];

      if (a.typeCode == TypeCode.Enum) {
        a.type = (cast(TypeInfo_Enum)type).base;
        a.typeCode = cast(TypeCode)a.type.classinfo.name[9];
      }

      if (a.typeCode == TypeCode.Typedef) {
        a.type = (cast(TypeInfo_Typedef)type).base;
        a.typeCode = cast(TypeCode)a.type.classinfo.name[9];
      }

      return a;
    }

    string toString(string format, IFormatProvider provider) {
      
      TypeInfo skipConstOrInvariant(TypeInfo ti) {
        while (true) {
          if (ti.classinfo.name.length == 18 && ti.classinfo.name[9 .. 18] == "Invariant")
            ti = (cast(TypeInfo_Invariant)ti).next;
          else if (ti.classinfo.name.length == 14 && ti.classinfo.name[9 .. 14] == "Const")
            ti = (cast(TypeInfo_Const)ti).next;
          else
            break;
        }
        return ti;
      }

      switch (typeCode) {
        case TypeCode.Array:
          TypeInfo ti = type;
          TypeCode tc = typeCode;

          // strings (invariant char arrays)
          if (ti.classinfo.name.length == 14 && ti.classinfo.name[9 .. 14] == "Array") {
            ti = skipConstOrInvariant((cast(TypeInfo_Array)ti).next);
            tc = cast(TypeCode)ti.classinfo.name[9];

            if (tc == TypeCode.Char)
              return *cast(string*)value;
            if (tc == TypeCode.WChar)
              return (*cast(wstring*)value).toUtf8();
            if (tc == TypeCode.DChar)
              return (*cast(dstring*)value).toUtf8();
          }

          // char arrays
          tc = cast(TypeCode)ti.classinfo.name[10];
          if (tc == TypeCode.Char)
            return *cast(string*)value;
          else if (tc == TypeCode.WChar)
            return (*cast(wstring*)value).toUtf8();
          else if (tc == TypeCode.DChar)
            return (*cast(dstring*)value).toUtf8();

          // arrays
          return type.toString();
        case TypeCode.Bool:
          return *cast(bool*)value ? "True" : "False";
        case TypeCode.UByte:
          return .toString(*cast(ubyte*)value, format, provider);
        case TypeCode.Byte:
          return .toString(*cast(byte*)value, format, provider);
        case TypeCode.UShort:
          return .toString(*cast(ushort*)value, format, provider);
        case TypeCode.Short:
          return .toString(*cast(short*)value, format, provider);
        case TypeCode.UInt:
          return .toString(*cast(uint*)value, format, provider);
        case TypeCode.Int:
          return .toString(*cast(int*)value, format, provider);
        case TypeCode.ULong:
          return .toString(*cast(ulong*)value, format, provider);
        case TypeCode.Long:
          return .toString(*cast(long*)value, format, provider);
        case TypeCode.Float:
          return .toString(*cast(float*)value, format, provider);
        case TypeCode.Double:
          return .toString(*cast(double*)value, format, provider);
        case TypeCode.Class:
          if (auto value = *cast(Object*)value)
            return value.toString();
          break;
        case TypeCode.Struct:
          if (type == typeid(DateTime))
            return .toString(*cast(DateTime*)value, format, provider);
          if (auto ti = cast(TypeInfo_Struct)type) {
            if (ti.xtoString != null) {
              return ti.xtoString(value);
            }
          }
          // fall through
        case TypeCode.Function, TypeCode.Delegate, TypeCode.Typedef:
          return type.toString();
        default:
      }
      return null;
    }

  }

  struct ArgumentList {

    Argument[] args;
    int count;

    static ArgumentList opCall(TypeInfo[] types, va_list argptr) {
      ArgumentList list;
      foreach (type; types) {
        auto arg = Argument(type, argptr);
        list.args ~= arg;
        if (arg.typeCode == TypeCode.Struct)
          argptr += (type.tsize() + 3) & ~3;
        else
          argptr += (type.tsize() + int.sizeof - 1) & ~(int.sizeof - 1);
        list.count++;
      }
      return list;
    }

    Argument opIndex(int index) {
      return args[index];
    }

  }

  void formatError() {
  }

  void append(ref char[] s, char value, int count) {
    int n = s.length;
    s.length = s.length + count;
    for (int i = 0; i < count; i++)
      s[n + i] = value;
  }

  TypeInfo[] types = _arguments;
  va_list argptr = _argptr;

  if (types.length == 2 && types[0] == typeid(TypeInfo[]) && types[1] == typeid(va_list)) {
    types = va_arg!(TypeInfo[])(argptr);
    argptr = *cast(va_list*)argptr;
  }

  auto args = ArgumentList(types, argptr);

  char[] result, chars = format.dup;
  int pos, len = format.length;
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

    if (i > p) result ~= chars[p .. i];
    if (pos == len) break;
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

    while (pos < len && (ch = chars[pos]) == ' ') pos++;

    int width = 0;
    bool leftAlign = false;
    if (ch == ',') {
      pos++;
      while (pos < len && (ch = chars[pos]) == ' ') pos++;
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

    while (pos < len && (ch = chars[pos]) == ' ') pos++;

    auto arg = args[index];
    string fmt = null;

    if (ch == ':') {
      pos++;
      p = pos, i = pos;
      while (true) {
        ch = chars[pos];
        pos++;
        if (ch == '{') {
          if (pos < len && chars[pos] == '{')
            pos++;
          else formatError();
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

    string s = arg.toString(fmt, provider);

    int padding = width - s.length;
    if (!leftAlign && padding > 0)
      result.append(' ', padding);

    result ~= s;

    if (leftAlign && padding > 0)
      result.append(' ', padding);
  }

  return result.dup;
}

/**
 * Ditto
 */
public string format(string format, ...) {
  return .format(cast(IFormatProvider)null, format, _arguments, _argptr);
}