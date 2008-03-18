/**
 * Copyright: (c) 2008 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.com.bstr;

private import std.utf : toUTF8, toUTF16z;

pragma(lib, "oleaut32.lib");

extern(Windows):

wchar* SysAllocString(in wchar* psz);
int SysReAllocString(ref wchar* pbstr, wchar* psz);
wchar* SysAllocStringLen(in wchar* strIn, uint ui);
int SysReAllocStringLen(ref wchar* pbstr, wchar* psz, uint len);
void SysFreeString(in wchar* bstr);
uint SysStringLen(in wchar* bstr);
uint SysStringByteLen(in wchar* bstr);
wchar* SysAllocStringByteLen(in wchar* psz, uint len);

extern(D):

/**
 * Allocates a BSTR equivalent to s.
 * Params: s = The string with which to initialize the BSTR.
 * Returns: The BSTR equivalent to s.
 */
wchar* fromString(string s) {
  if (s == null)
    return null;

  return SysAllocString(s.toUTF16z());
}

uint getLength(wchar* s) {
  return SysStringLen(s);
}

/**
 * Converts a BSTR to a string, freeing the original BSTR.
 * Params: bstr = The BSTR to convert.
 * Returns: A string equivalent to bstr.
 */
string toString(wchar* s) {
  if (s == null)
    return null;

  uint len = SysStringLen(s);
  if (len == 0)
    return null;

  string ret = s[0 .. len].toUTF8();
  SysFreeString(s);
  return ret;
}

/**
 * Frees the memory occupied by the specified BSTR.
 * Params: bstr = The BSTR to free.
 */
void free(wchar* s) {
  if (s != null)
    SysFreeString(s);
}