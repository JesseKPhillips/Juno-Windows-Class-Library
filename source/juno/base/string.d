/**
 * Contains methods for working with strings.
 *
 * Methods that perform comparisons are culturally sensitive.
 *
 * Copyright: (c) 2009 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.base.string;

import std.conv;
import std.string;
import std.typecons;
import std.traits;
import std.uni;

import juno.base.core,
  juno.locale.constants,
  juno.locale.core,
  juno.locale.time,
  juno.locale.convert;
import std.utf : toUTF8, toUTF16, toUTF16z;
import std.string : toStringz;
import core.stdc.string : strlen, memcpy, memcmp;
import core.stdc.wchar_ : wcslen;
import core.vararg;
import std.exception;

//debug import std.stdio : writeln;

alias const(char)* stringz;
alias const(wchar*) wstringz;

/**
 * Provides convenience to turn an character pointer
 * into an array.
 *
 * Finish conversion using to!string(toArray(myPtr))
 *
 * Second optional parameter is useful for performance
 * if the string length is already known. Or the string
 * is not null teminated.
 */
const(T)[] toArray(T)(in T* s, size_t len = 0) if(isSomeChar!T
                                               && !is(T == dchar)) {
  if(len)
    return s[0..len];
  else
  static if(is(T == char))
    return s[0..strlen(s)];
  else static if(is(T == wchar))
    return s[0..wcslen(s)];
}

unittest {
  char[] arr = to!(char[])("My test\0");
  char* test = arr.ptr;
  assert("My test" == toArray(test));

  wchar[] arr2 = to!(wchar[])("My test\0"w);
  wchar* test2 = arr2.ptr;
  assert("My test"w == toArray(test2));
  assert(is(typeof(toArray(test2)) == const(wchar)[]));
}

/**
 * Compares two specified strings, ignoring or honouring their case.
 * Params:
 *   stringA = The first string.
 *   stringB = The second string.
 *   ignoreCase = A value indicating a case- sensitive or insensitive comparison.
 * Returns: An integer indicating the lexical relationship between the two strings (less than zero if stringA is less then stringB; zero if stringA equals stringB; greater than zero if stringA is greater than stringB).
 */
int compare(string stringA, string stringB, bool ignoreCase, Culture culture = null) {
  if (culture is null)
    culture = Culture.current;

  if (stringA != stringB) {
    if (stringA == null)
      return -1;
    if (stringB == null)
      return -1;

    return culture.collator.compare(stringA, stringB, ignoreCase ? CompareOptions.IgnoreCase : CompareOptions.None);
  }
  return 0;
}

/**
 * ditto
 */
int compare(string stringA, string stringB, Culture culture) {
  if (culture is null)
    throw new ArgumentNullException("culture");
  return compare(stringA, stringB, false, culture);
}

/**
 * ditto
 */
int compare(string stringA, string stringB) {
  return compare(stringA, stringB, false, Culture.current);
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
int compare(string stringA, int indexA, string stringB, int indexB, int length, bool ignoreCase = false, Culture culture = null) {
  if (culture is null)
    culture = Culture.current;

  if (length != 0 && (stringA != stringB || indexA != indexB)) {
    int lengthA = length, lengthB = length;
    if (stringA.length - indexA < lengthA)
      lengthA = stringA.length - indexA;
    if (stringB.length - indexB < lengthB)
      lengthB = stringB.length - indexB;

    return culture.collator.compare(stringA, indexA, lengthA, stringB, indexB, lengthB, ignoreCase ? CompareOptions.IgnoreCase : CompareOptions.None);
  }
  return 0;
}

/**
 * ditto
 */
int compare(string stringA, int indexA, string stringB, int indexB, int length, Culture culture) {
  if (culture is null)
    throw new ArgumentNullException("culture");
  return compare(stringA, indexA, stringB, indexB, length, false, culture);
}

/**
 * Determines whether two specified strings are the same, ignoring or honouring their case.
 * Params:
 *   stringA = The first string.
 *   stringB = The second string.
 *   ignoreCase = A value indicating a case- sensitive or insensitive comparison.
 * Returns: true if stringA is the same as stringB; otherwise, false.
 */
bool equals(string stringA, string stringB, bool ignoreCase = false) {
  return compare(stringA, stringB, ignoreCase) == 0;
}

/**
 * Determines whether the value parameter occurs within the s parameter.
 * Params:
 *   s = The string to search within.
 *   value = The string to find.
 * Returns: true if the value parameter occurs within the s parameter; otherwise, false.
 */
bool contains(string s, string value) {
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
int indexOf(string s, char value, int index = 0, int count = -1) {
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
int indexOf(string s, string value, int index, int count, bool ignoreCase = false, Culture culture = null) {
  if (culture is null)
    culture = Culture.current;
  return culture.collator.indexOf(s, value, index, count, ignoreCase ? CompareOptions.IgnoreCase : CompareOptions.None);
}

/**
 * ditto
 */
int indexOf(string s, string value, int index, bool ignoreCase = false, Culture culture = null) {
  return indexOf(s, value, index, s.length - index, ignoreCase, culture);
}

/**
 * ditto
 */
int indexOf(string s, string value, bool ignoreCase = false, Culture culture = null) {
  return indexOf(s, value, 0, s.length, ignoreCase, culture);
}

int indexOfAny(string s, in char[] anyOf, int index = 0, int count = -1) {
  if (count == -1)
    count = s.length - index;

  int end = index + count;
  for (int i = index; i < end; i++) {
    int k = -1;
    for (int j = 0; j < anyOf.length; j++) {
      if (s[i] == anyOf[j]) {
        k = j;
        break;
      }
    }
    if (k != -1)
      return i;
  }

  return -1;
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
int lastIndexOf(string s, char value, int index = 0, int count = -1) {
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
int lastIndexOf(string s, string value, int index, int count, bool ignoreCase = false, Culture culture = null) {
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

  if (culture is null)
    culture = Culture.current;
  return culture.collator.lastIndexOf(s, value, index, count, ignoreCase ? CompareOptions.IgnoreCase : CompareOptions.None);
}

/**
 * ditto
 */
int lastIndexOf(string s, string value, int index, bool ignoreCase = false, Culture culture = null) {
  return lastIndexOf(s, value, index, index + 1, ignoreCase, culture);
}

/**
 * ditto
 */
int lastIndexOf(string s, string value, bool ignoreCase = false, Culture culture = null) {
  return lastIndexOf(s, value, s.length - 1, s.length, ignoreCase, culture);
}

int lastIndexOfAny(string s, in char[] anyOf, int index = -1, int count = -1) {
  if (s.length == 0)
    return -1;
  if (count == -1) {
    index = s.length - 1;
    count = s.length;
  }

  int end = index - count + 1;
  for (int i = index; i >= end; i--) {
    int k = -1;
    for (int j = 0; j < anyOf.length; j++) {
      if (s[i] == anyOf[j]) {
        k = j;
        break;
      }
    }
    if (k != -1)
      return i;
  }
  return -1;
}

/**
 * Determines whether the beginning of s matches value.
 * Params:
 *   s = The string to search.
 *   value = The string to compare.
 *   ignoreCase = A value indicating a case- sensitive or insensitive comparison.
 * Returns: true if value matches the beginning of s; otherwise, false.
 */
bool startsWith(string s, string value, bool ignoreCase = false, Culture culture = null) {
  if (s == value)
    return true;

  if (culture is null)
    culture = Culture.current;
  return culture.collator.isPrefix(s, value, ignoreCase ? CompareOptions.IgnoreCase : CompareOptions.None);
}

/**
 * Determines whether the end of s matches value.
 * Params:
 *   s = The string to search.
 *   value = The string to compare.
 *   ignoreCase = A value indicating a case- sensitive or insensitive comparison.
 * Returns: true if value matches the end of s; otherwise, false.
 */
bool endsWith(string s, string value, bool ignoreCase = false, Culture culture = null) {
  if (s == value)
    return true;

  if (culture is null)
    culture = Culture.current;
  return culture.collator.isSuffix(s, value, ignoreCase ? CompareOptions.IgnoreCase : CompareOptions.None);
}

/**
 * Inserts value at the specified index in s.
 * Params:
 *   s = The string in which to _insert value.
 *   index = The position of the insertion.
 *   value = The string to _insert.
 * Returns: A new string with value inserted at index.
 */
//@@TODO@@ The currently disabled std.array.insert is pretty much the same as this
string insert(string s, size_t index, string value) {
  if (value.length == 0 || s.length == 0) {
    return s.idup;
  }

  size_t newLength = s.length + value.length;
  char[] newString = new char[newLength];

  newString[0 .. index] = s[0 .. index];
  newString[index .. index + value.length] = value;
  newString[index + value.length .. $] = s[index .. $];
  return assumeUnique(newString);
}

/**
 * Deletes characters from s beginning at the specified position.
 * Params:
 *   s = The string from which to delete characters.
 *   index = The position to begin deleting characters.
 *   count = The number of characters to delete.
 * Returns: A new string equivalent to s less count number of characters.
 */
string remove(string s, int index, int count) {
  char[] ret = new char[s.length - count];
  memcpy(ret.ptr, s.ptr, index);
  memcpy(ret.ptr + index, s.ptr + (index + count), s.length - (index + count));
  return assumeUnique(ret);
}

/**
 * ditto
 */
string remove(string s, int index) {
  return s[0 .. index];
}

private char[] WhitespaceChars = [ '\t', '\n', '\v', '\f', '\r', ' ' ];

/**
 * Indicates whether the specified character is white space.
 * Params: c = A character.
 * Returns: true if c is white space; otherwise, false.
 */
bool isWhitespace(char c) @safe nothrow pure{
  return isWhite(c);
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
string[] split(string s, char[] separator, int count, bool removeEmptyEntries = false) {

  int createSeparatorList(ref int[] sepList) {
    int foundCount;

    if (separator.length == 0) {
      for (int i = 0; i < s.length && foundCount < sepList.length; i++) {
        if (isWhitespace(s[i]))
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

  return splitImpl(s, sepList, null, replaceCount, count, removeEmptyEntries);
}

/// ditto
string[] split(string s, char[] separator, bool removeEmptyEntries) {
  return split(s, separator, int.max, removeEmptyEntries);
}

/// ditto
string[] split(string s, char[] separator...) {
  return split(s, separator, int.max, false);
}

/**
 * Returns a string array containing the substrings in s that are delimited by elements of the specified string array.
 * Params:
 *   s = The string to _split.
 *   separator = An array of strings that delimit the substrings in s.
 *   count = The maximum number of substrings to return.
 *   removeEmptyEntries = true to omit empty array elements from the array returned, or false to include empty array elements in the array returned.
 * Returns: An array whose elements contain the substrings in s that are delimited by one or more strings in separator.
 */
string[] split(string s, string[] separator, int count = int.max, bool removeEmptyEntries = false) {

  int createSeparatorList(ref int[] sepList, ref int[] lengthList) {
    int foundCount;

    for (int i = 0; i < s.length && foundCount < sepList.length; i++) {
      for (int j = 0; j < separator.length; j++) {
        string sep = separator[j];
        if (sep.length != 0) {
          if (s[i] == sep[0] && sep.length <= s.length - i) {
            if (sep.length == 1 || memcmp(s.ptr + i, sep.ptr, sep.length) == 0) {
              sepList[foundCount] = i;
              lengthList[foundCount] = sep.length;
              foundCount++;
              i += sep.length - 1;
            }
          }
        }
      }
    }

    return foundCount;
  }

  if (count == 0 || (removeEmptyEntries && s.length == 0))
    return new string[0];

  int[] sepList = new int[s.length];
  int[] lengthList = new int[s.length];
  int replaceCount = createSeparatorList(sepList, lengthList);

  if (replaceCount == 0 || count == 1)
    return [ s ];

  return splitImpl(s, sepList, lengthList, replaceCount, count, removeEmptyEntries);
}

/**
 * ditto
 */
string[] split(string s, string[] separator, bool removeEmptyEntries) {
  return split(s, separator, int.max, removeEmptyEntries);
}

private string[] splitImpl(string s, int[] sepList, int[] lengthList, int replaceCount, int count, bool removeEmptyEntries) {
  string[] splitStrings;
  int arrayIndex, currentIndex;

  if (removeEmptyEntries) {
    int max = (replaceCount < count) ? replaceCount + 1 : count;
    splitStrings.length = max;
    for (int i = 0; i < replaceCount && currentIndex < s.length; i++) {
      if (sepList[i] - currentIndex > 0)
        splitStrings[arrayIndex++] = s[currentIndex .. sepList[i]];
      currentIndex = sepList[i] + ((lengthList == null) ? 1 : lengthList[i]);
      if (arrayIndex == count - 1) {
        while (i < replaceCount - 1 && currentIndex == sepList[++i]) {
          currentIndex += ((lengthList == null) ? 1 : lengthList[i]);
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
      currentIndex = sepList[i] + ((lengthList == null) ? 1 : lengthList[i]);
    }

    if (currentIndex < s.length && max >= 0)
      splitStrings[arrayIndex] = s[currentIndex .. $];
    else if (arrayIndex == max)
      splitStrings[arrayIndex] = null;
  }

  return splitStrings;
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
string join(string separator, string[] value, int index = 0, int count = -1) {
  if (count == -1)
    count = value.length;
  if (count == 0)
    return "";

  int end = index + count - 1;
  string ret = value[index];
  for (int i = index + 1; i <= end; i++) {
    ret ~= separator;
    ret ~= value[i];
  }
  return ret;
}

/**
 * Replaces all instances of oldChar with newChar in s.
 * Params:
 *   s = A string containing oldChar.
 *   oldChar = The character to be replaced.
 *   newChar = The character to replace all instances of oldChar.
 * Returns: A string equivalent to s but with all instances of oldChar replaced with newChar.
 */
string replace(string s, char oldChar, char newChar) {
  int len = s.length;
  int firstFound = -1;
  for (int i = 0; i < len; i++) {
    if (oldChar == s[i]) {
      firstFound = i;
      break;
    }
  }

  if (firstFound == -1)
    return s;

  char[] ret = s[0 .. firstFound].dup;
  ret.length = len;
  for (int i = firstFound; i < len; i++)
    ret[i] = (s[i] == oldChar) ? newChar : s[i];
  return assumeUnique(ret);
}

/**
 * Replaces all instances of oldValue with newValue in s.
 * Params:
 *   s = A string containing oldValue.
 *   oldValue = The string to be replaced.
 *   newValue = The string to replace all instances of oldValue.
 * Returns: A string equivalent to s but with all instances of oldValue replaced with newValue.
 */
string replace(string s, string oldValue, string newValue) {
  int[] indices = new int[s.length + oldValue.length];

  int index, count;
  while (((index = indexOf(s, oldValue, index, s.length)) > -1) &&
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
    return s;
  return assumeUnique(ret);
}

/**
 * Right-aligns the characters in s, padding on the left with paddingChar for a specified total length.
 * Params:
 *   s = The string to pad.
 *   totalWidth = The number of characters in the resulting string.
 *   paddingChar = A padding character.
 * Returns: A string equivalent to s but right-aligned and padded on the left with paddingChar.
 */
string padLeft(string s, int totalWidth, char paddingChar = ' ') {
  if (totalWidth < s.length)
    return s;
  char[] ret = new char[totalWidth];
  ret[totalWidth - s.length .. $] = s;
  ret[0 .. totalWidth - s.length] = paddingChar;
  return assumeUnique(ret);
}

/**
 * Left-aligns the characters in s, padding on the right with paddingChar for a specified total length.
 * Params:
 *   s = The string to pad.
 *   totalWidth = The number of characters in the resulting string.
 *   paddingChar = A padding character.
 * Returns: A string equivalent to s but left-aligned and padded on the right with paddingChar.
 */
string padRight(string s, int totalWidth, char paddingChar = ' ') {
  if (totalWidth < s.length)
    return s;
  char[] ret = s.dup;
  ret.length = totalWidth;
  ret[s.length .. $] = paddingChar;
  return assumeUnique(ret);
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
string trim(string s, char[] trimChars ...) {
  if (trimChars.length == 0)
    return strip(s);
  return trimHelper(s, trimChars, Trim.Both);
}

/**
 * Removes all leading occurrences of a set of characters specified in trimChars from s.
 * Returns: The string that remains after all occurrences of the characters in trimChars are removed from the start of s.
 */
string trimStart(string s, char[] trimChars ...) {
  if (trimChars.length == 0)
    return stripLeft(s);
  return trimHelper(s, trimChars, Trim.Head);
}

/**
 * Removes all trailing occurrences of a set of characters specified in trimChars from s.
 * Returns: The string that remains after all occurrences of the characters in trimChars are removed from the end of s.
 */
string trimEnd(string s, char[] trimChars ...) {
  if (trimChars.length == 0)
    return stripRight(s);
  return trimHelper(s, trimChars, Trim.Tail);
}

@safe nothrow pure
private string trimHelper(string s, in char[] trimChars, Trim trimType) {
  int right = s.length - 1;
  int left;

  // Trim head
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
  // Trim tail
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
    return s;
  if (len == 0)
    return null;
    
  return s[left .. right + 1];
}

/**
 *   $(RED Deprecated.
 *         Please use string slicing instead.)
 * Retrieves a _substring from s starting at the specified character position and has a specified length.
 * Params:
 *   s = A string.
 *   index = The starting character position of a _substring in s.
 *   length = The number of characters in the _substring.
 * Returns: The _substring of length that begins at index in s.
 */
deprecated
@safe nothrow pure
string substring(string s, int index, int len) {
  return s[index..index+len];
}

/**
 * ditto
 */
deprecated
@safe nothrow pure
string substring(string s, int index) {
  return s[index..$];
}

/**
 * Returns a copy of s converted to lowercase.
 * Params: s = The string to convert.
 * Returns: a string in lowercase.
 */
public string toLower(string s, Culture culture = null) {
  if (culture is null)
    culture = Culture.current;
  return culture.collator.toLower(s);
}

/**
 * Returns a copy of s converted to uppercase.
 * Params: s = The string to convert.
 * Returns: a string in uppercase.
 */
public string toUpper(string s, Culture culture = null) {
  if (culture is null)
    culture = Culture.current;
  return culture.collator.toUpper(s);
}

private enum TypeCode {
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
  Typedef = 'T',
  Const = 'x',
  Invariant = 'y'
}

nothrow pure
private const(TypeInfo) skipConstOrInvariant(const TypeInfo t) {
  Rebindable!(typeof(return)) anst = t;
  while (true) {
    if (anst.classinfo.name.length == 18 && anst.classinfo.name[9 .. 18]
            == "Invariant")
      anst = (cast(TypeInfo_Invariant)anst).next;
    else if (anst.classinfo.name.length == 18 && anst.classinfo.name[9 .. 18]
            == "Immutable") // In case class name is changed
      anst = (cast(TypeInfo_Invariant)anst).next;
    else if (anst.classinfo.name.length == 14 && anst.classinfo.name[9 .. 14]
            == "Const")
      anst = (cast(TypeInfo_Const)anst).next;
    else
      break;
  }
  return anst;
}

unittest {
  assert(typeid(immutable Argument) != typeid(Argument));
  assert(skipConstOrInvariant(typeid(Argument))
          == typeid(Argument));
  assert(skipConstOrInvariant(typeid(const Argument))
          == typeid(Argument));
  assert(skipConstOrInvariant(typeid(immutable Argument))
          == typeid(Argument));
}

private struct Argument {

  Rebindable!(const TypeInfo) type;
  TypeCode typeCode;
  void* value;

  nothrow pure
  static Argument opCall(const TypeInfo type, void* value) {
    Argument self;

    self.type = type;
    self.value = value;
    self.typeCode = cast(TypeCode)type.classinfo.name[9];

    if (self.typeCode == TypeCode.Enum) {
      self.type = (cast(TypeInfo_Enum)type).base;
      self.typeCode = cast(TypeCode)self.type.classinfo.name[9];
    }

    if (self.typeCode == TypeCode.Typedef) {
      self.type = (cast(TypeInfo_Typedef)type).base;
      self.typeCode = cast(TypeCode)self.type.classinfo.name[9];
    }

    return self;
  }

  string toString(string format, IFormatProvider provider) {
    switch (typeCode) {
      case TypeCode.Array:
        Rebindable!(const TypeInfo) ti = type;
        TypeCode tc = typeCode;

        if (ti.classinfo.name.length == 14 && ti.classinfo.name[9 .. 14] == "Array") {
          ti = skipConstOrInvariant((cast(TypeInfo_Array)ti).next);
          tc = cast(TypeCode)ti.classinfo.name[9];

          if (tc == TypeCode.Char)
            return *cast(string*)value;
        }

        int i = 10;
        while (true) {
          tc = cast(TypeCode)ti.classinfo.name[i];
          switch (tc) {
            case TypeCode.Char:
              return *cast(string*)value;
            case TypeCode.Const, TypeCode.Invariant:
              i++;
              continue;
            default:
          }
          break;
        }

        return to!string(type);

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
        if (auto obj = *cast(Object*)value)
          return obj.toString();
        break;

      case TypeCode.Struct:
        static if (is(DateTime)) {
          if (to!(const TypeInfo)(type) == typeid(DateTime))
            return (*cast(DateTime*)value).toString(format, provider);
        }
        if (auto ti = cast(TypeInfo_Struct)type) {
          if (ti.xtoString != null)
            return ti.xtoString(value);
        }
        // Fall through
        goto case;

      case TypeCode.Function, TypeCode.Delegate, TypeCode.Typedef:
        return to!string(type);

      default:
        break;
    }
    return null;
  }

}

private struct ArgumentList {

  Argument[] args;
  int size;

  nothrow pure
  static ArgumentList opCall(TypeInfo[] types, va_list argptr) {
    ArgumentList self;

    foreach (Rebindable!(const TypeInfo) type; types) {
      type = skipConstOrInvariant(type);
      auto arg = Argument(type, argptr);
      self.args ~= arg;
      if (arg.typeCode == TypeCode.Struct)
        argptr += (type.tsize() + 3) & ~3;
      else
        argptr += (type.tsize() + int.sizeof - 1) & ~(int.sizeof - 1);
      self.size++;
    }

    return self;
  }

  nothrow pure
  Argument opIndex(int index) {
    return args[index];
  }

}

pure
private void append(ref string s, char value, int count) {
  char[] d = s.dup;
  int n = d.length;
  d.length = d.length + count;
  d[n..$] = value;

  s = assumeUnique(d);
}
unittest {
  string a = "Hello";
  append(a, 'n', 5);
  assert(a == "Hellonnnnn");
}


/**
 * Replaces the _format items in the specified string with string representations of the corresponding items in the specified argument list.
 * Params:
 *   provider = An object supplying culture-specific formatting information.
 *   format = A _format string.
 *   _argptr = An argument list containing zero or more items to _format.
 * Returns: A copy of format in which the _format items have been replaced by string representations of the corresponding items in the argument list.
 */
string format(IFormatProvider provider, string format, ...) {

  void formatError() {
    throw new FormatException("Input string was not in correct format.");
  }

  auto types = _arguments;
  auto argptr = _argptr;

  void resolveArgs() {
    if (types.length == 2 && types[0] == typeid(TypeInfo[]) && types[1] == typeid(va_list)) {
      types = va_arg!(TypeInfo[])(argptr);
      argptr = *cast(va_list*)argptr;

      if (types.length == 2 && types[0] == typeid(TypeInfo[]) && types[1] == typeid(va_list)) {
        resolveArgs();
      }
    }
  }
  resolveArgs();

  auto args = ArgumentList(types, argptr);

  string result;
  char[] chars = format.dup;
  int pos, len = format.length;
  char c;

  while (true) {
    int p = pos, i = pos;
    while (pos < len) {
      c = chars[pos];
      pos++;
      if (c == '}') {
        if (pos < len && chars[pos] == '}')
          pos++;
        else
          formatError();
      }
      if (c == '{') {
        if (pos < len && chars[pos] == '{')
          pos++;
        else {
          pos--;
          break;
        }
      }
      chars[i++] = c;
    }

    if (i > p) result ~= chars[p .. i];
    if (pos == len) break;
    pos++;

    if (pos == len || (c = chars[pos]) < '0' || c > '9')
      formatError();

    int index = 0;

    do {
      index = index * 10 + c - '0';
      pos++;
      if (pos == len)
        formatError();
      c = chars[pos];
    } while (c >= '0' && c <= '9');

    if (index >= args.size)
      throw new FormatException("Index must be less than the size of the argument list.");

    while (pos < len && (c = chars[pos]) == ' ') pos++;

    int width = 0;
    bool leftAlign = false;
    if (c == ',') {
      pos++;
      while (pos < len && (c = chars[pos]) == ' ') pos++;
      if (pos == len)
        formatError();
      c = chars[pos];
      if (c == '-') {
        leftAlign = true;
        pos++;
        if (pos == len)
          formatError();
        c = chars[pos];
      }
      if (c < '0' || c > '9')
        formatError();

      do {
        width = width * 10 + c - '0';
        pos++;
        if (pos == len)
          formatError();
        c = chars[pos];
      } while (c >= '0' && c <= '9');
    }

    while (pos < len && (c = chars[pos]) == ' ') pos++;

    auto arg = args[index];
    string fmt = null;

    if (c == ':') {
      pos++;
      p = pos, i = pos;
      while (true) {
        c = chars[pos];
        pos++;
        if (c == '{') {
          if (pos < len && chars[pos] == '{')
            pos++;
          else formatError();
        }
        if (c == '}') {
          if (pos < len && chars[pos] == '}')
            pos++;
          else {
            pos--;
            break;
          }
        }
        chars[i++] = c;
      }
      if (i > p) {
        fmt = chars[p .. i].idup;
      }
    }

    if (c != '}')
      formatError();
    pos++;

    string s = arg.toString(fmt, provider);

    int padding = width - s.length;
    if (!leftAlign && padding > 0)
      append(result, ' ', padding);

    result ~= s;

    if (leftAlign && padding > 0)
      append(result, ' ', padding);
  }

  return result;
}

/**
 * ditto
 */
string format(string format, ...) {
  return .format(cast(IFormatProvider)null, format, _arguments, _argptr);
}
