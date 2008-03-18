/**
 * Copyright: (c) 2008 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.locale.text;

private import juno.base.native,
  juno.locale.constants;

private import juno.locale.core : Culture, toUTF16zNls, toUTF8Nls;

private import std.c.string : memcmp, memicmp;

class Collator {

  private static Collator[uint] cache_;

  private uint cultureId_;
  private uint sortingId_;
  private string name_;

  static Collator get(uint culture) {
    synchronized {
      if (auto value = culture in cache_)
        return *value;

      return cache_[culture] = new Collator(culture);
    }
  }

  static Collator get(string name) {
    Culture culture = Culture.get(name);
    Collator collator = get(culture.lcid);
    collator.name_ = culture.name;
    return collator;
  }

  int compare(string string1, int offset1, int length1, string string2, int offset2, int length2, CompareOptions options = CompareOptions.None) {
    if (string1 == null) {
      if (string2 == null)
        return 0;
      return -1;
    }
    if (string2 == null)
      return 1;

    //if ((options & CompareOptions.Ordinal) != 0 || (options & CompareOptions.OrdinalIgnoreCase) != 0)
    //  return compareStringOrdinal(string1, offset1, length1, string2, offset2, length2, (options & CompareOptions.OrdinalIgnoreCase) != 0);

    return compareString(sortingId_, string1, offset1, length1, string2, offset2, length2, getCompareFlags(options));
  }

  int compare(string string1, int offset1, string string2, int offset2, CompareOptions options = CompareOptions.None) {
    return compare(string1, offset1, string1.length - offset1, string2, offset2, string2.length - offset2, options);
  }

  int compare(string string1, string string2, CompareOptions options = CompareOptions.None) {
    if (string1 == null) {
      if (string2 == null)
        return 0;
      return -1;
    }
    if (string2 == null)
      return 1;

    //if ((options & CompareOptions.Ordinal) != 0 || (options & CompareOptions.OrdinalIgnoreCase) != 0)
    //  return compareStringOrdinal(string1, 0, string1.length, string2, 0, string2.length, (options & CompareOptions.OrdinalIgnoreCase) != 0);

    return compareString(sortingId_, string1, 0, string1.length, string2, 0, string2.length, getCompareFlags(options));
  }

  int indexOf(string source, string value, int index, int count, CompareOptions options = CompareOptions.None) {
    uint flags = getCompareFlags(options);

    int n = findString(sortingId_, flags | FIND_FROMSTART, source, index, count, value, value.length);
    if (n > -1)
      return n + index;
    if (n == -1)
      return n;

    for (uint i = 0; i < count; i++) {
      if (isPrefix(source, index + i, count - i, value, flags))
        return index + i;
    }
    return -1;
  }

  int indexOf(string source, string value, int index, CompareOptions options = CompareOptions.None) {
    return indexOf(source, value, index, source.length - index, options);
  }

  int indexOf(string source, string value, CompareOptions options = CompareOptions.None) {
    return indexOf(source, value, 0, source.length, options);
  }

  int lastIndexOf(string source, string value, int index, int count, CompareOptions options = CompareOptions.None) {
    if (source.length == 0 && (index == -1 || index == 0)) {
      if (value.length != 0)
        return -1;
      return 0;
    }

    if (index == source.length) {
      index++;
      if (count > 0)
        count--;
      if (value.length == 0 && count >= 0 && (index - count) + 1 >= 0)
        return index;
    }

    uint flags = getCompareFlags(options);

    int n = findString(sortingId_, flags | FIND_FROMEND, source, (index - count) + 1, count, value, value.length);
    if (n > -1)
      return n + (index - count) + 1;
    if (n == -1)
      return n;

    for (uint i = 0; i < count; i++) {
      if (isSuffix(source, index - i, count - i, value, flags))
        return i + (index - count) + 1;
    }
    return -1;
  }

  int lastIndexOf(string source, string value, int index, CompareOptions options = CompareOptions.None) {
    return lastIndexOf(source, value, index, index + 1, options);
  }

  int lastIndexOf(string source, string value, CompareOptions options = CompareOptions.None) {
    return lastIndexOf(source, value, source.length - 1, source.length, options);
  }

  bool isPrefix(string source, string prefix, CompareOptions options = CompareOptions.None) {
    if (prefix.length == 0)
      return true;
    return isPrefix(source, 0, source.length, prefix, getCompareFlags(options));
  }

  bool isSuffix(string source, string suffix, CompareOptions options = CompareOptions.None) {
    if (suffix.length == 0)
      return true;
    return isSuffix(source, source.length - 1, source.length, suffix, getCompareFlags(options));
  }

  string toLower(string str) {
    return changeCaseString(cultureId_, str, false);
  }

  string toUpper(string str) {
    return changeCaseString(cultureId_, str, true);
  }

  uint lcid() {
    return cultureId_;
  }

  string name() {
    if (name_ == null)
      name_ = Culture.get(cultureId_).name;
    return name_;
  }

  private this(uint culture) {
    cultureId_ = culture;
    sortingId_ = getSortingId(culture);
  }

  private uint getSortingId(uint culture) {
    uint sortId = (culture >> 16) & 0xF;
    return (sortId == 0) ? culture : (culture | (sortId << 16));
  }

  private static uint getCompareFlags(CompareOptions options) {
    uint flags;
    if ((options & CompareOptions.IgnoreCase) != 0)
      flags |= NORM_IGNORECASE;
    if ((options & CompareOptions.IgnoreNonSpace) != 0)
      flags |= NORM_IGNORENONSPACE;
    if ((options & CompareOptions.IgnoreSymbols) != 0)
      flags |= NORM_IGNORESYMBOLS;
    if ((options & CompareOptions.IgnoreWidth) != 0)
      flags |= NORM_IGNOREWIDTH;
    return flags;
  }

  private static int compareString(uint lcid, string string1, int offset1, int length1, string string2, int offset2, int length2, uint flags) {
    int cch1, cch2;
    wchar* lpString1 = toUTF16zNls(string1, offset1, length1, cch1);
    wchar* lpString2 = toUTF16zNls(string2, offset2, length2, cch2);
    return CompareString(lcid, flags, lpString1, cch1, lpString2, cch2) - 2;
  }

  private static int compareStringOrdinal(string string1, int offset1, int length1, string string2, int offset2, int length2, bool ignoreCase) {
    int count = (length2 < length1) 
      ? length2 
      : length1;
    int ret = ignoreCase
      ? memicmp(string1.ptr + offset1, string2.ptr + offset2, count)
      : memcmp(string1.ptr + offset1, string2.ptr + offset2, count);
    if (ret == 0)
      ret = length1 - length2;
    return ret;
  }

  private bool isPrefix(string source, int start, int length, string prefix, uint flags) {
    // Call FindNLSString if the API is present on the system, otherwise call CompareString. 
    int i = findString(sortingId_, flags | FIND_STARTSWITH, source, start, length, prefix, prefix.length);
    if (i == -1)
      return false;
    else if (i > -1)
      return true;

    for (i = 1; i <= length; i++) {
      if (compareString(sortingId_, prefix, 0, prefix.length, source, start, i, flags) == 0)
        return true;
    }
    return false;
  }

  private bool isSuffix(string source, int end, int length, string suffix, uint flags) {
    // Call FindNLSString if the API is present on the system, otherwise call CompareString. 
    int i = findString(sortingId_, flags | FIND_ENDSWITH, source, 0, length, suffix, suffix.length);
    if (i == -1)
      return false;
    else if (i > -1)
      return true;

    for (i = 0; i < length; i++) {
      if (compareString(sortingId_, suffix, 0, suffix.length, source, end - i, i + 1, flags))
        return true;
    }
    return false;
  }

  private static string changeCaseString(uint lcid, string string, bool upperCase) {
    int cch, cb;
    wchar* pChars = toUTF16zNls(string, 0, string.length, cch);
    LCMapString(lcid, (upperCase ? LCMAP_UPPERCASE : LCMAP_LOWERCASE) | LCMAP_LINGUISTIC_CASING, pChars, cch, pChars, cch);
    return toUTF8Nls(pChars, cch, cb);
  }

  private static int findString(uint lcid, uint flags, string source, int start, int sourceLen, string value, int valueLen) {
    // Return value:
    // -2 FindNLSString unavailable
    // -1 less than
    //  0 equal
    //  1 greater than

    int result = -1;

    int cchSource, cchValue;
    wchar* lpSource = toUTF16zNls(source, 0, sourceLen, cchSource);
    wchar* lpValue = toUTF16zNls(value, 0, valueLen, cchValue);

    try {
      result = FindNLSString(lcid, flags, lpSource + start, cchSource, lpValue, cchValue, null);
    }
    catch (EntryPointNotFoundException) {
      result = -2;
    }
    return result;
  }

}