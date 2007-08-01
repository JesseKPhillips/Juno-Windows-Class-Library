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
* Provides support for COM (Component Object Model).
*/
module juno.com.core;

pragma (lib, "ole32.lib");
pragma (lib, "oleaut32.lib");

private import juno.base.core,
  juno.base.string,
  juno.base.threading,
  juno.base.native;

private import juno.locale.core : DateTime;

private import std.string : find, stdformat = format;
private import std.stream : Stream, SeekPos;
private import std.c.string : memcpy;
private import std.c.stdlib;
private import std.typetuple : IndexOf, MostDerived;
private import std.traits : ParameterTypeTuple;
private static import std.gc;

static this() {
  startupCOM();
}

static ~this() {
  shutdownCOM();
}

enum {
  S_OK            = 0x0,
  S_FALSE         = 0x1,

  E_NOTIMPL       = 0x80004001,
  E_NOINTERFACE   = 0x80004002,
  E_POINTER       = 0x80004003,
  E_ABORT         = 0x80004004,
  E_FAIL          = 0x80004005,

  E_ACCESSDENIED  = 0x80070005,
  E_OUTOFMEMORY   = 0x8007000E,
  E_INVALIDARG    = 0x80070057,
}

enum {
  TYPE_E_ELEMENTNOTFOUND      = 0x8002802B
}

enum {
  SELFREG_E_FIRST = MAKE_SCODE_T!(SEVERITY_ERROR, FACILITY_ITF, 0x0200),
  SELFREG_E_LAST = MAKE_SCODE_T!(SEVERITY_ERROR, FACILITY_ITF, 0x020F),
  SELFREG_S_FIRST = MAKE_SCODE_T!(SEVERITY_SUCCESS, FACILITY_ITF, 0x0200),
  SELFREG_S_LAST = MAKE_SCODE_T!(SEVERITY_SUCCESS, FACILITY_ITF, 0x020F),
  SELFREG_E_TYPELIB = SELFREG_E_FIRST,
  SELFREG_E_CLASS = SELFREG_E_FIRST + 1
}

enum {
  DISP_E_MEMBERNOTFOUND       = 0x80020003,
  DISP_E_PARAMNOTFOUND        = 0x80020004,
  DISP_E_TYPEMISMATCH         = 0x80020005,
  DISP_E_UNKNOWNNAME          = 0x80020006,
  DISP_E_NONAMEDARGS          = 0x80020007,
  DISP_E_BADVARTYPE           = 0x80020008,
  DISP_E_EXCEPTION            = 0x80020009,
  DISP_E_BADPARAMCOUNT        = 0x8002000E
}

enum {
  CLASS_E_NOAGGREGATION       = 0x80040110,
  CLASS_E_CLASSNOTAVAILABLE   = 0x80040111
}

enum DVASPECT : uint {
  DVASPECT_CONTENT = 1,
  DVASPECT_THUMBNAIL = 2,
  DVASPECT_ICON = 4,
  DVASPECT_DOCPRINT = 8
}

enum OLEMISC : uint {
  OLEMISC_RECOMPOSEONRESIZE = 0x1,
  OLEMISC_ONLYICONIC = 0x2,
  OLEMISC_INSERTNOTREPLACE = 0x4,
  OLEMISC_STATIC = 0x8,
  OLEMISC_CANTLINKINSIDE = 0x10,
  OLEMISC_CANLINKBYOLE1 = 0x20,
  OLEMISC_ISLINKOBJECT = 0x40,
  OLEMISC_INSIDEOUT = 0x80,
  OLEMISC_ACTIVATEWHENVISIBLE = 0x100,
  OLEMISC_RENDERINGISDEVICEINDEPENDENT = 0x200,
  OLEMISC_INVISIBLEATRUNTIME = 0x400,
  OLEMISC_ALWAYSRUN = 0x800,
  OLEMISC_ACTSLIKEBUTTON = 0x1000,
  OLEMISC_ACTSLIKELABEL = 0x2000,
  OLEMISC_NOUIACTIVATE = 0x4000,
  OLEMISC_ALIGNABLE = 0x8000,
  OLEMISC_SIMPLEFRAME = 0x10000,
  OLEMISC_SETCLIENTSITEFIRST = 0x20000,
  OLEMISC_IMEMODE = 0x40000,
  OLEMISC_IGNOREACTIVATEWHENVISIBLE = 0x80000,
  OLEMISC_WANTSTOMENUMERGE = 0x100000,
  OLEMISC_SUPPORTSMULTILEVELUNDO = 0x200000
}

/**
 * Determines whether the operation was successful.
 */
public bool SUCCEEDED(int hr) {
  return hr >= S_OK;
}

/**
 * Determines whether the operation was unsuccessful.
 */
public bool FAILED(int hr) {
  return hr < S_OK;
}

/**
 * Represents a globally unique identifier.
 */
struct GUID {

  uint a;
  ushort b, c;
  ubyte d, e, f, g, h, i, j, k;

  /**
   * A GUID whose value is all zeros.
   */
  static GUID empty = { 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0 };

  /**
   * Initializeds a new instance using the specified integers and bytes.
   * Params:
   *   a = The first 4 bytes.
   *   b = The next 2 bytes.
   *   c = The next 2 bytes.
   *   d = The next byte.
   *   e = The next byte.
   *   f = The next byte.
   *   g = The next byte.
   *   h = The next byte.
   *   i = The next byte.
   *   j = The next byte.
   *   k = The next byte.
   * Returns: The resulting GUID.
   */
  public static GUID opCall(uint a, ushort b, ushort c, ubyte d, ubyte e, ubyte f, ubyte g, ubyte h, ubyte i, ubyte j, ubyte k) {
    GUID result;
    result.a = a, result.b = b, result.c = c, result.d = d, result.e = e, result.f = f, result.g = g, result.h = h, result.i = i, result.j = j, result.k = k;
    return result;
  }

  /**
   * Initializes a new instance using the specified integets and byte array.
   * Params:
   *   a = The first 4 bytes.
   *   b = The next 2 bytes.
   *   c = The next 2 bytes.
   *   d = The remaining 8 bytes.
   * Returns: The resulting GUID.
   * Throws: ArgumentException if d is not 8 bytes long.
   */
  public static GUID opCall(uint a, ushort b, ushort c, ubyte[] d) {
    if (d.length != 8)
      throw new ArgumentException("Byte array for GUID must be 8 bytes long.");

    GUID result;
    result.a = a, result.b = b, result.c = c, result.d = d[0], result.e = d[1], result.f = d[2], result.g = d[3], result.h = d[4], result.i = d[5], result.j = d[6], result.k = d[7];
    return result;
  }

  /**
   * Initializes a new instance using the value represented by the specified string.
   * Params: s = A string containing a GUID in groups of 8, 4, 4, 4 and 12 digits with hyphens between the groups. The GUID can optionally be enclosed in braces.
   * Returns: The resulting GUID.
   */
  public static GUID opCall(string s) {

    ulong parse(string s) {

      bool hexToInt(char c, out uint result) {
        if (c >= '0' && c <= '9') result = c - '0';
        else if (c >= 'A' && c <= 'F') result = c - 'A' + 10;
        else if (c >= 'a' && c <= 'f') result = c - 'a' + 10;
        else result = -1;
        return (result >= 0);
      }

      ulong result;
      uint value, index;
      while (index < s.length && hexToInt(s[index], value)) {
        result = result * 16 + value;
        index++;
      }
      return result;
    }

    if (s[0] == '{') {
      s = s[1 .. $];
      if (s[$ - 1] == '}')
        s = s[0 .. $ - 1];
    }

    if (s[0] == '[') {
      s = s[1 .. $];
      if (s[$ - 1] == ']')
        s = s[0 .. $ - 1];
    }

    if (s.find('-') == -1)
      throw new FormatException("Unrecognised GUID format.");

    GUID g;
    g.a = cast(uint)parse(s[0 .. 8]);
    g.b = cast(ushort)parse(s[9 .. 13]);
    g.c = cast(ushort)parse(s[14 .. 18]);
    uint m = cast(uint)parse(s[19 .. 23]);
    g.d = cast(ubyte)(m >> 8);
    g.e = cast(ubyte)m;
    ulong n = parse(s[24 .. $]);
    m = cast(uint)(n >> 32);
    g.f = cast(ubyte)(m >> 8);
    g.g = cast(ubyte)m;
    m = cast(uint)n;
    g.h = cast(ubyte)(m >> 24);
    g.i = cast(ubyte)(m >> 16);
    g.j = cast(ubyte)(m >> 8);
    g.k = cast(ubyte)m;
    return g;
  }

  public static GUID newGuid() {
    GUID g;

    int hr;
    if ((hr = CoCreateGuid(g)) != S_OK)
      throw new COMException(hr);

    return g;
  }

  public bool opEquals(GUID other) {
    return a == other.a
      && b == other.b
      && c == other.c
      && d == other.d
      && e == other.e
      && f == other.f
      && g == other.g
      && h == other.h
      && i == other.i
      && j == other.j
      && k == other.k;
  }

  /**
   * Retrieves the hash code for this instance.
   * Returns: The hash code for this instance.
   */
  public hash_t toHash() {
    return a ^ ((b << 16) | c) ^ ((f << 24) | k);
  }

  /**
   * Returns a string representation of the value of this instance in registry format.
   * Returns: A string formatted in this pattern: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx where the GUID is represented as a series of lowercase hexadecimal digits in groups of 8, 4, 4, 4 and 12 and separated by hyphens.
   */
  public string toString() {

    void hexToString(ref char[] s, ref uint index, uint a, int b) {

      char hexToChar(uint a) {
        a = a & 0x0F;
        return cast(char)((a > 9) ? a - 10 + 0x61 : a + 0x30);
      }

      s[index++] = hexToChar(a >> 4);
      s[index++] = hexToChar(a);
      s[index++] = hexToChar(b >> 4);
      s[index++] = hexToChar(b);
    }

    char[] s = new char[38];
    uint index = 1;

    s[0] = '{';
    hexToString(s, index, a >> 24, a >> 16);
    hexToString(s, index, a >> 8, a);
    s[index++] = '-';
    hexToString(s, index, b >> 8, b);
    s[index++] = '-';
    hexToString(s, index, c >> 8, c);
    s[index++] = '-';
    hexToString(s, index, d, e);
    s[index++] = '-';
    hexToString(s, index, f, g);
    hexToString(s, index, h, i);
    hexToString(s, index, j, k);
    s[$ - 1] = '}';

    return s;
  }

}

struct SAFEARRAYBOUND {
  uint cElements;
  int lLbound;
}

enum : ushort {
  FADF_AUTO = 0x1,
  FADF_STATIC = 0x2,
  FADF_EMBEDDED = 0x4,
  FADF_FIXEDSIZE = 0x10,
  FADF_RECORD = 0x20,
  FADF_HAVEIID = 0x40,
  FADF_HAVEVARTYPE = 0x80,
  FADF_BSTR = 0x100,
  FADF_UNKNOWN = 0x200,
  FADF_DISPATCH = 0x400,
  FADF_VARIANT = 0x800,
  FADF_RESERVED = 0xF008
}

struct SAFEARRAY {
  ushort cDims;
  ushort fFeatures;
  uint cbElements;
  uint cLocks;
  void* pvData;
  SAFEARRAYBOUND[1] rgsabound;
}

struct DECIMAL {
  ushort wReserved;
  ubyte scale;
  ubyte sign;
  uint Hi32;
  uint Lo32;
  uint Mid32;
}

/**
 * Identifies the type of a VARIANT.
 */
enum VARTYPE : ushort {
  VT_EMPTY = 0,
  VT_NULL = 1,
  VT_I2 = 2,
  VT_I4 = 3,
  VT_R4 = 4,
  VT_R8 = 5,
  VT_CY = 6,
  VT_DATE = 7,
  VT_BSTR = 8,
  VT_DISPATCH = 9,
  VT_ERROR = 10,
  VT_BOOL = 11,
  VT_VARIANT = 12,
  VT_UNKNOWN = 13,
  VT_DECIMAL = 14,
  VT_I1 = 16,
  VT_UI1 = 17,
  VT_UI2 = 18,
  VT_UI4 = 19,
  VT_I8 = 20,
  VT_UI8 = 21,
  VT_INT = 22,
  VT_UINT = 23,
  VT_VOID = 24,
  VT_HRESULT = 25,
  VT_PTR = 26,
  VT_SAFEARRAY = 27,
  VT_CARRAY = 28,
  VT_USERDEFINED = 29,
  VT_LPSTR = 30,
  VT_LPWSTR = 31,
  VT_RECORD = 36,
  VT_INT_PTR = 37,
  VT_UINT_PTR = 38,
  VT_FILETIME = 64,
  VT_BLOB = 65,
  VT_STREAM = 66,
  VT_STORAGE = 67,
  VT_STREAMED_OBJECT = 68,
  VT_STORED_OBJECT = 69,
  VT_BLOB_OBJECT = 70,
  VT_CF = 71,
  VT_CLSID = 72,
  VT_VERSIONED_STREAM = 73,
  VT_BSTR_BLOB        = 0x0fff,
  VT_VECTOR           = 0x1000,
  VT_ARRAY            = 0x2000,
  VT_BYREF            = 0x4000,
  VT_RESERVED         = 0x8000
}

alias short VARIANT_BOOL;

enum : VARIANT_BOOL {
  VARIANT_TRUE = -1,
  VARIANT_FALSE = 0
}

alias VARIANT_BOOL com_bool;

enum : com_bool {
  com_true = VARIANT_TRUE,
  com_false = VARIANT_FALSE
}

/**
 * A container for many different data types.
 */
struct VARIANT {

  union {
    struct {
      /// Describes the type of the instance.
      VARTYPE vt;
      ushort wReserved1;
      ushort wReserved2;
      ushort wReserved3;
      union {
        long llVal;
        int lVal;
        ubyte bVal;
        short iVal;
        float fltVal;
        double dblVal;
        VARIANT_BOOL boolVal;
        int scode;
        long cyVal;
        double date;
        wchar* bstrVal;
        IUnknown punkVal;
        IDispatch pdispVal;
        SAFEARRAY* parray;
        ubyte* pbVal;
        short* piVal;
        int* plVal;
        long* pllVal;
        float* pfltVal;
        double* pdblVal;
        VARIANT_BOOL* pboolVal;
        int* pscode;
        long* pcyVal;
        double* pdate;
        wchar** pbstrVal;
        IUnknown* ppunkVal;
        IDispatch* ppdispVal;
        SAFEARRAY* pparray;
        VARIANT* pvarVal;
        void* byref;
        byte cVal;
        ushort uiVal;
        uint ulVal;
        ulong ullVal;
        int intVal;
        uint uintVal;
        DECIMAL* pdecVal;
        byte* pcVal;
        ushort* puiVal;
        uint* pulVal;
        ulong* pullVal;
        int* pintVal;
        uint* puintVal;
        struct {
          void* pvRecord;
          IRecordInfo pRecInfo;
        }
      }
    }
    DECIMAL decVal;
  }

  /**
   * Initializes a new instance using the specified _value and _type.
   * Params:
   *   value = A _value of one of the acceptable types.
   *   type = The VARTYPE identifying the _type of value.
   * Returns: The resulting VARIANT.
   */
  public static VARIANT opCall(T)(T value, VARTYPE type = VariantType!(T)) {
    VARIANT v;
    v.vt = type;

    static if (is(T == ubyte))
      v.bVal = value;
    else static if (is(T == byte))
      v.cVal = value;
    else static if (is(T == ushort))
      v.uiVal = value;
    else static if (is(T == short))
      v.iVal = value;
    else static if (is(T == uint))
      v.ulVal = value;
    else static if (is(T == int))
      v.lVal = value;
    else static if (is(T == ulong))
      v.ullVal = value;
    else static if (is(T == long))
      v.llVal = value;
    else static if (is(T == float))
      v.fltVal = value;
    else static if (is(T == double))
      v.dblVal = value;
    else static if(is(T == DECIMAL))
      v.decVal = value;
    else static if (is(T : IDispatch))
      v.pdispVal = value, value.AddRef();
    else static if (is(T : IUnknown))
      v.punkVal = value, value.AddRef();
    else static if (is(T : Object))
      v.byref = cast(void*)value;
    else static if(is(T E == enum))
      v = VARIANT(cast(E)value);
    else static if(is(T == bool))
      v.boolVal = (value == true) ? VARIANT_TRUE : VARIANT_FALSE;
    else static if (is(T : string))
      v.bstrVal = value.toBStr();
    else static if (is(T == wchar*))
      v.bstrVal = SysAllocString(value);
    else static if (is(T == DateTime))
      v.date = value.toOleDate();
    else static assert(false, "The type '" ~ typeof(T).stringof ~ "' must be one of the allowed types.");

    return v;
  }

  /**
   * Clears the value of this instance and releases any associated memory.
   * See_Also: $(LINK2 http://msdn2.microsoft.com/en-us/library/ms221165.aspx, VariantClear).
   */
  public void clear() {
    if (isCOMInitialized) {
      VariantClear(this);
    }
  }

  /**
   * Copies this instance to the destination.
   * Params: dest = The destination VARIANT.
   * See_Also: $(LINK2 http://msdn2.microsoft.com/en-us/library/ms221697.aspx, VariantCopy).
   */
  public void copyTo(out VARIANT dest) {
    VariantCopy(&dest, this);
  }

  public T get(T)() {
    static if (is(T == bool)) {
      if (vt == VARTYPE.VT_BOOL)
        return (boolVal == VARIANT_TRUE) ? true : false;
    }
    else static if (is(T == ubyte)) {
      if (vt == VARTYPE.VT_UI1)
        return bVal;
    }
    static if (is(T == byte)) {
      if (vt == VARTYPE.VT_I1)
        return cVal;
    }
    else static if (is(T == ushort)) {
      if (vt == VARTYPE.VT_UI2)
        return uiVal;
    }
    else static if (is(T == short)) {
      if (vt == VARTYPE.VT_I2)
        return iVal;
    }
    else static if (is(T == uint)) {
      if (vt == VARTYPE.VT_UI4)
        return ulVal;
      else if (vt == VARTYPE.VT_UINT)
        return uintVal;
    }
    else static if (is(T == int)) {
      if (vt == VARTYPE.VT_I4)
        return lVal;
      else if (vt == VARTYPE.VT_INT)
        return intVal;
    }
    else static if (is(T == ulong)) {
      if (vt == VARTYPE.VT_UI8)
        return ullVal;
      else if (vt == VARTYPE.VT_I8)
        return llVal;
    }
    else static if (is(T == float)) {
      if (vt == VARTYPE.VT_R4)
        return fltVal;
    }
    else static if (is(T == double)) {
      if (vt == VARTYPE.VT_R8)
        return dblVal;
    }
    else static if (is(T == string)) {
      if (vt == VARTYPE.VT_BSTR)
        return fromBStr(bstrVal);
    }
    else static if (is(T == DECIMAL)) {
      if (vt == VARTYPE.VT_DECIMAL)
        return decVal;
    }
    else static if (is(T : IDispatch)) {
      if (vt == VARTYPE.VT_DISPATCH)
        return pdispVal;
    }
    else static if (is(T : IUnknown)) {
      if (vt == VARTYPE.VT_UNKNOWN)
        return punkVal;
    }
    else static if (is(T == DateTime)) {
      if (vt == VARTYPE.VT_DATE)
        return DateTime.fromOleDate(date);
    }
    else static if (is(T : Object)) {
      if (vt == VARTYPE.VT_BYREF)
        return cast(T)byref;
    }
    return T.init;
  }

  /**
   * Converts the value contained in this instance to a string.
   * Returns: A string representation of the value contained in this instance.
   */
  public string toString() {
    if (vt == VARTYPE.VT_EMPTY || vt == VARTYPE.VT_NULL)
      return null;

    if (vt == VARTYPE.VT_BSTR)
      return fromBStr(bstrVal);

    VARIANT temp;
    if (VariantChangeTypeEx(&temp, this, LOCALE_USER_DEFAULT, 0, VARTYPE.VT_BSTR) == S_OK)
      return fromBStr(temp.bstrVal);

    return null;
  }

}

public VARIANT toVariant(T)(T value, bool heapAlloc = false) {
  if (!heapAlloc)
    return VARIANT(value);
  else return (new class(value) {
    VARIANT var;
    this(T value) {
      var = VARIANT(value);
    }
    ~this() {
      var.clear();
    }
  }).var;
}

struct BSTRBLOB {
  uint cbSize = BSTRBLOB.sizeof;
  ubyte* pBlobData;
}

struct BLOB {
  uint cbSize = BLOB.sizeof;
  ubyte* pBlobData;
}

struct VERSIONEDSTREAM {
  GUID guidVersion;
  IStream pStream;
}

struct CAC {
  uint cElems;
  byte* pElems;
}

struct CAUB {
  uint cElems;
  ubyte* pElems;
}

struct CAI {
  uint cElems;
  short* pElems;
}

struct CAUI {
  uint cElems;
  ushort* pElems;
}

struct CAL {
  uint cElems;
  int* pElems;
}

struct CAUL {
  uint cElems;
  uint* pElems;
}

struct CAFLT {
  uint cElems;
  float* pElems;
}

struct CADBL {
  uint cElems;
  double* pElems;
}

struct CACY {
  uint cElems;
  long* pElems;
}

struct CADATE {
  uint cElems;
  double* pElems;
}

struct CABSTR {
  uint cElems;
  wchar** pElems;
}

struct CABSTRBLOB {
  uint cElems;
  BSTRBLOB* pElems;
}

struct CABOOL {
  uint cElems;
  VARIANT_BOOL* pElems;
}

struct CASCODE {
  uint cElems;
  int* pElems;
}

struct CAPROPVARIANT {
  uint cElems;
  PROPVARIANT* pElems;
}

struct CAH {
  uint cElems;
  long* pElems;
}

struct CAUH {
  uint cElems;
  ulong* pElems;
}

struct CACLSID {
  uint cElems;
  GUID* pElems;
}

struct CAFILETIME {
  uint cElems;
  FILETIME* pElems;
}

struct PROPVARIANT {

  union {
    struct {
      VARTYPE vt;
      ushort wReserved1;
      ushort wReserved2;
      ushort wReserved3;
      union {
        ubyte cVal;
        byte bVal;
        short iVal;
        ushort uiVal;
        int lVal;
        uint ulVal;
        int intVal;
        uint uintVal;
        long hVal;
        ulong uhVal;
        float fltVal;
        double dblVal;
        VARIANT_BOOL boolVal;
        int scode;
        long cyVal;
        double date;
        FILETIME filetime;
        GUID* puuid;
        wchar* bstrVal;
        BSTRBLOB bstrblobVal;
        BLOB blob;
        char* pszVal;
        wchar* pwszVal;
        IUnknown punkVal;
        IDispatch pdispVal;
        IStream pStream;
        IStorage pStorage;
        VERSIONEDSTREAM* pVersionedStream;
        SAFEARRAY* parray;
        CAC cac;
        CAUB caub;
        CAI cai;
        CAUI caui;
        CAL cal;
        CAUL caul;
        CAH cah;
        CAUH cauh;
        CAFLT caflt;
        CADBL cadbl;
        CABOOL cabool;
        CASCODE cascode;
        CACY cacy;
        CADATE cadate;
        CAFILETIME cafiletime;
        CACLSID cauuid;
        CABSTR cabstr;
        CABSTRBLOB cabstrblob;
        CAPROPVARIANT capropvar;
        byte* pcVal;
        ubyte* pbVal;
        short* piVal;
        ushort* puiVal;
        int* plVal;
        uint* pulVal;
        int* pintVal;
        uint* puintVal;
        float* pfltVal;
        double pdblVal;
        VARIANT_BOOL* pboolVal;
        DECIMAL* pdecVal;
        int* pscode;
        long* pcyVal;
        double* pdate;
        wchar** pbstrVal;
        IUnknown* ppunkVal;
        IDispatch* ppdispVal;
        SAFEARRAY** pparray;
        PROPVARIANT* pvarVal;
      }
    }
    DECIMAL decVal;
  }

  public static PROPVARIANT opCall(T)(T value, VARTYPE type = VariantType!(T)) {
    PROPVARIANT v;
    v.vt = type;

    static if (is(T == ubyte))
      v.bVal = value;
    else static if (is(T == byte))
      v.cVal = value;
    else static if (is(T == ushort))
      v.uiVal = value;
    else static if (is(T == short))
      v.iVal = value;
    else static if (is(T == uint))
      v.ulVal = value;
    else static if (is(T == int))
      v.lVal = value;
    else static if (is(T == ulong))
      v.ullVal = value;
    else static if (is(T == long))
      v.llVal = value;
    else static if (is(T == float))
      v.fltValue = value;
    else static if (is(T == double))
      v.dblVal = value;
    else static if(is(T == DECIMAL))
      v.decVal = value;
    else static if (is(T : IDispatch))
      v.pdispVal = value, value.AddRef();
    else static if (is(T : IUnknown))
      v.punkVal = value, value.AddRef();
    else static if (is(T : Object))
      v.byref = cast(void*)value;
    else static if(is(T E == enum))
      v = VARIANT(cast(E)value);
    else static if(is(T == bool))
      v.boolVal = (value == true) ? VARIANT_TRUE : VARIANT_FALSE;
    else static if (is(T : string))
      v.bstrVal = value.toBStr();
    else static assert(false, "The type '" ~ typeof(T).stringof ~ "' must be one of the allowed types.");

    return v;
  }

  public void copyTo(out PROPVARIANT dest) {
    PropVariantCopy(&dest, this);
  }

  public string toString() {
    if (vt == VARTYPE.VT_BSTR)
      return fromBStr(bstrVal);

    wchar* bstr;
    PropVariantToBSTR(this, &bstr);
    return fromBStr(bstr);
  }

}

enum TYPEKIND {
  TKIND_ENUM,
  TKIND_RECORD,
  TKIND_MODULE,
  TKIND_INTERFACE,
  TKIND_DISPATCH,
  TKIND_COCLASS,
  TKIND_ALIAS,
  TKIND_UNION
}

struct TYPEDESC {
  union {
    TYPEDESC* lptdesc;
    ARRAYDESC* lpadesc;
    uint hreftype;
  }
  VARTYPE vt;
}

struct ARRAYDESC {
  TYPEDESC tdescElem;
  ushort cDims;
  SAFEARRAYBOUND[1] rgbounds;
}

struct PARAMDESCEX {
  uint cBytes;
  VARIANT varDefaultValue;
}

struct PARAMDESC {
  PARAMDESCEX* pparamdescex;
  ushort wParamFlags;
}

enum : ushort {
  PARAMFLAG_NONE = 0x0,
  PARAMFLAG_FIN = 0x1,
  PARAMFLAG_FOUT = 0x2,
  PARAMFLAG_FLCID = 0x4,
  PARAMFLAG_FRETVAL = 0x8,
  PARAMFLAG_FOPT = 0x10,
  PARAMFLAG_FHASDEFAULT = 0x20,
  PARAMFLAG_FHASCUSTDATA = 0x40
}

struct IDLDESC {
  uint dwReserved;
  ushort wIDLFlags;
}

struct ELEMDESC {
  TYPEDESC tdesc;
  union {
    IDLDESC idldesc;
    PARAMDESC paramdesc;
  }
}

struct TYPEATTR {
  GUID guid;
  uint lcid;
  uint dwReserved;
  int memidConstructor;
  int memidDestructor;
  wchar* lpstrSchema;
  uint cbSizeInstance;
  TYPEKIND typekind;
  ushort cFuncs;
  ushort cVars;
  ushort cImplTypes;
  ushort cbSizeVft;
  ushort cbAlignment;
  ushort wTypeFlags;
  ushort wMajorVerNum;
  ushort wMinorVerNum;
  TYPEDESC tdescAlias;
  IDLDESC idldescType;
}

struct DISPPARAMS {
  VARIANT* rgvarg;
  int* rgdispidNamedArgs;
  uint cArgs;
  uint cNamedArgs;
}

struct EXCEPINFO {
  ushort wCode;
  ushort wReserved;
  wchar* bstrSource;
  wchar* bstrDescription;
  wchar* bstrHelpFile;
  uint dwHelpContext;
  void* pvReserved;
  int function(EXCEPINFO*) pfnDeferredFillIn;
  int scode;
}

enum CALLCONV {
  CC_FASTCALL,
  CC_CDECL,
  CC_MSPASCAL,
  CC_PASCAL = CC_MSPASCAL,
  CC_MACPASCAL,
  CC_STDCALL,
  CC_FPFASTCALL,
  CC_SYSCALL,
  CC_MPWCDECL,
  CC_MPWPASCAL
}

enum FUNCKIND {
  FUNC_VIRTUAL,
  FUNC_PUREVIRTUAL,
  FUNC_NONVIRTUAL,
  FUNC_STATIC,
  FUNC_DISPATCH
}

enum INVOKEKIND {
  INVOKE_FUNC = 1,
  INVOKE_PROPERTYGET = 2,
  INVOKE_PROPERTYPUT = 4,
  INVOKE_PROPERTYPUTREF = 8
}

struct FUNCDESC {
  int memid;
  int* lprgscode;
  ELEMDESC* lprgelemdescParam;
  FUNCKIND funckind;
  INVOKEKIND invkind;
  CALLCONV callconv;
  short cParams;
  short cParamsOpt;
  short oVft;
  short cScodes;
  ELEMDESC elemdescFunc;
  ushort wFuncFlags;
}

enum VARKIND {
  VAR_PERSISTANCE,
  VAR_STATIC,
  VAR_CONST,
  VAR_DISPATCH
}

enum : ushort {
  IMPLTYPEFLAG_FDEFAULT = 0x1,
  IMPLTYPEFLAG_FSOURCE = 0x2,
  IMPLTYPEFLAG_FRESTRICTED = 0x4,
  IMPLTYPEFLAG_FDEFAULTVTABLE = 0x8
}

struct VARDESC {
  int memid;
  wchar* lpstrSchema;
  union {
    uint oInst;
    VARIANT* lpvarValue;
  }
  ELEMDESC elemdescVar;
  ushort wVarFlags;
  VARKIND varkind;
}

enum TYPEFLAGS : ushort {
  TYPEFLAG_FAPPOBJECT = 0x1,
  TYPEFLAG_FCANCREATE = 0x2,
  TYPEFLAG_FLICENSED = 0x4,
  TYPEFLAG_FPREDECLID = 0x8,
  TYPEFLAG_FHIDDEN = 0x10,
  TYPEFLAG_FCONTROL = 0x20,
  TYPEFLAG_FDUAL = 0x40,
  TYPEFLAG_FNONEXTENSIBLE = 0x80,
  TYPEFLAG_FOLEAUTOMATION = 0x100,
  TYPEFLAG_FRESTRICTED = 0x200,
  TYPEFLAG_FAGGREGATABLE = 0x400,
  TYPEFLAG_FREPLACEABLE = 0x800,
  TYPEFLAG_FDISPATCHABLE = 0x1000,
  TYPEFLAG_FREVERSEBIND = 0x2000,
  TYPEFLAG_FPROXY = 0x4000
}

enum FUNCFLAGS : ushort {
  FUNCFLAG_FRESTRICTED = 0x1,
  FUNCFLAG_FSOURCE = 0x2,
  FUNCFLAG_FBINDABLE = 0x4,
  FUNCFLAG_FREQUESTEDIT = 0x8,
  FUNCFLAG_FDISPLAYBIND = 0x10,
  FUNCFLAG_FDEFAULTBIND = 0x20,
  FUNCFLAG_FHIDDEN = 0x40,
  FUNCFLAG_FUSESGETLASTERROR = 0x80,
  FUNCFLAG_FDEFAULTCOLLELEM = 0x100,
  FUNCFLAG_FUIDEFAULT = 0x200,
  FUNCFLAG_FNONBROWSABLE = 0x400,
  FUNCFLAG_FREPLACEABLE = 0x800,
  FUNCFLAG_FIMMEDIATEBIND = 0x1000
}

enum VARFLAGS : ushort {
  VARFLAG_FREADONLY = 0x1,
  VARFLAG_FSOURCE = 0x2,
  VARFLAG_FBINDABLE = 0x4,
  VARFLAG_FREQUESTEDIT = 0x8,
  VARFLAG_FDISPLAYBIND = 0x10,
  VARFLAG_FDEFAULTBIND = 0x20,
  VARFLAG_FHIDDEN = 0x40,
  VARFLAG_FRESTRICTED = 0x80,
  VARFLAG_FDEFAULTCOLLELEM = 0x100,
  VARFLAG_FUIDEFAULT = 0x200,
  VARFLAG_FNONBROWSABLE = 0x400,
  VARFLAG_FREPLACEABLE = 0x800,
  VARFLAG_FIMMEDIATEBIND = 0x1000
}

enum DESCKIND {
  DESCKIND_NONE,
  DESCKIND_FUNCDESC,
  DESCKIND_VARDESC,
  DESCKIND_TYPECOMP,
  DESCKIND_IMPLICITAPPOBJ
}

struct BINDPTR {
  FUNCDESC* lpfuncdesc;
  VARDESC* lpvardesc;
  ITypeComp lptcomp;
}

enum SYSKIND {
  SYS_WIN16,
  SYS_WIN32,
  SYS_MAC,
  SYS_WIN64
}

enum /* LIBFLAGS */ : ushort {
  LIBFLAG_FRESTRICTED = 0x1,
  LIBFLAG_FCONTROL = 0x2,
  LIBFLAG_FHIDDEN = 0x4,
  LIBFLAG_FHASDISKIMAGE = 0x8
}

struct TLIBATTR {
  GUID guid;
  uint lcid;
  SYSKIND syskind;
  ushort wMajorVerNum;
  ushort wMinorVerNum;
  ushort wLibFlags;
}

enum CHANGEKIND {
  CHANGEKIND_ADDMEMBER,
  CHANGEKIND_DELETEMEMBER,
  CHANGEKIND_SETNAMES,
  CHANGEKIND_SETDOCUMENTATION,
  CHANGEKIND_GENERAL,
  CHANGEKIND_INVALIDATE,
  CHANGEKIND_CHANGEFAILED,
  CHANGEKIND_MAX
}

struct COAUTHIDENTITY {
  wchar* User;
  uint UserLength;
  wchar* Domain;
  uint DomainLength;
  wchar* Password;
  uint PasswordLength;
}

struct COAUTHINFO {
  uint dwAuthnSvc;
  uint dwAuthzSvc;
  wchar* pwszServerPrincName;
  uint dwAuthnLevel;
  uint dwImpersonationLevel;
  COAUTHIDENTITY* pAuthIdentityData;
  uint dwCapabilities;
}

struct COSERVERINFO {
  uint dwReserved1;
  wchar* pwszName;
  COAUTHINFO* pAuthInfo;
  uint dwReserved2;
}

struct MULTI_QI {
  GUID* pIID;
  IUnknown pItf;
  int hr;
}

struct CATEGORYINFO {
  GUID catid;
  uint lcid;
  wchar[128] szDescription;
}

extern(Windows):

//GUID IID_NULL = { 0x00000000, 0x0000, 0x0000, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };

interface IUnknown {
  static GUID IID = { 0x00000000, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int QueryInterface(ref GUID riid, void** ppvObject);
  uint AddRef();
  uint Release();
}

interface IClassFactory : IUnknown {
  static GUID IID = { 0x00000001, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int CreateInstance(IUnknown pUnkOuter, ref GUID riid, void** ppvObject);
  int LockServer(int fLock);
}

interface IMalloc : IUnknown {
  static GUID IID = { 0x00000002, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  void* Alloc(size_t cb);
  void* Realloc(void* pv, size_t cb);
  void Free(void* pv);
  size_t GetSize(void* pv);
  int DidAlloc(void* pv);
  void HeapMinimize();
}

struct STATSTG {
  wchar* pwcsName;
  uint type;
  ulong cbSize;
  FILETIME mtime;
  FILETIME ctime;
  FILETIME atime;
  uint grfMode;
  uint grfLocksSupported;
  GUID clsid;
  uint grfStateBits;
  uint reserved;
}

enum STGTY : uint {
  STGTY_STORAGE = 1,
  STGTY_STREAM = 2,
  STGTY_LOCKBYTES = 3,
  STGTY_PROPERTY = 4
}

enum STREAM_SEEK : uint {
  STREAM_SEEK_SET,
  STREAM_SEEK_CUR,
  STREAM_SEEK_END
}

enum STATFLAG : uint {
  STATFLAG_DEFAULT,
  STATFLAG_NONAME,
  STATFLAG_NOOPEN
}

interface IStorage : IUnknown {
  static GUID IID = { 0x0000000b, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int CreateStream(wchar* pwcsName, uint grfMode, uint reserved1, uint reserved2, out IStream ppstm);
  int OpenStream(wchar* pwcsName, void* reserved1, uint grfMode, uint reserved2, out IStream ppstm);
  int CreateStorage(wchar* pwcsName, uint grfMode, uint reserved1, uint reserved2, out IStorage ppstg);
  int OpenStorage(wchar* pwcsName, IStorage psrgPriority, uint grfMode, wchar** snbExclude, uint reserved, out IStorage ppstg);
  int CopyTo(uint ciidExclude, GUID* rgiidExclude, wchar** snbExclude, IStorage pstgDest);
  int MoveElementTo(wchar* pwcsName, IStorage pstgDest, wchar* pwcsNewName, uint grfFlags);
  int Commit(uint grfCommitFlags);
  int Revert();
  int EnumElements(uint reserved1, void* reserved2, uint reserved3, out IEnumSTATSTG ppenum);
  int DestroyElement(wchar* pwcsName);
  int RenameElement(wchar* pwcsOldName, wchar* pwcsNewName);
  int SetElementTimes(wchar* pwcsName, ref FILETIME pctime, ref FILETIME patime, ref FILETIME pmtime);
  int SetClass(ref GUID clsid);
  int SetStateBits(uint grfStateBits, uint grfMask);
  int Stat(out STATSTG pstatstg, uint grfStatFlag);
}

interface ISequentialStream : IUnknown {
  static GUID IID = { 0x0c733a30, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d };
  int Read(void* pv, uint cb, ref uint pcbRead);
  int Write(void* pv, uint cb, ref uint pcbWritten);
}

interface IStream : ISequentialStream {
  static GUID IID = { 0x0000000C, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int Seek(long dlibMove, uint dwOrigin, ref ulong plibNewPosition);
  int SetSize(ulong libNewSize);
  int CopyTo(IStream stm, ulong cb, ref ulong pcbRead, ref ulong pcbWritten);
  int Commit(uint hrfCommitFlags);
  int Revert();
  int LockRegion(ulong libOffset, ulong cb, uint dwLockType);
  int UnlockRegion(ulong libOffset, ulong cb, uint dwLockType);
  int Stat(out STATSTG pstatstg, uint gfrStatFlag);
  int Clone(out IStream ppstm);
}

interface IEnumSTATSTG : IUnknown {
  static GUID IID = { 0x0000000d, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int Next(uint celt, STATSTG* rgelt, out uint pceltFetched);
  int Skip(uint celt);
  int Reset();
  int Clone(out IEnumSTATSTG ppenum);
}

struct BIND_OPTS {
  uint cbStruct = BIND_OPTS.sizeof;
  uint grfFlags;
  uint grfMode;
  uint dwTickCountDeadline;
}

interface IBindCtx : IUnknown {
  static GUID IID = { 0x0000000e, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int RegisterObjectBound(IUnknown punk);
  int RevokeObjectBound(IUnknown punk);
  int ReleaseBoundObjects();
  int SetBindOptions(ref BIND_OPTS pbindopts);
  int GetRunningObjectTable(out IRunningObjectTable pprot);
  int RegisterObjectParam(wchar* pszKey, IUnknown punk);
  int GetObjectParam(wchar* pszKey, out IUnknown ppunk);
  int EnumObjectParam(out IEnumString ppenum);
  int RemoveObjectParam(wchar* pszKey);
}

interface IMoniker : IUnknown {
  static GUID IID = { 0x0000000f, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int BindToObject(IBindCtx pbc, IMoniker pmkToLeft, ref GUID riidResult, void** ppvResult);
  int BindToStorage(IBindCtx pbc, IMoniker pmkToLeft, ref GUID riid, void** ppv);
  int Reduce(IBindCtx pbc, uint dwReduceHowFar, ref IMoniker ppmkToLeft, out IMoniker ppmkReduced);
  int ComposeWith(IMoniker pmkRight, bool fOnlyIfNotGeneric, out IMoniker ppmkComposite);
  int Enum(bool fForward, out IEnumMoniker ppenumMoniker);
  int IsEqual(IMoniker pmkOtherMoniker);
  int Hash(out uint pdwHash);
  int IsRunning(IBindCtx pbc, IMoniker pmkToLeft, IMoniker pmkNewlyRunning);
  int GetTimeOfLastChange(IBindCtx pbc, IMoniker pmkToLeft, out FILETIME pFileTime);
  int Inverse(out IMoniker ppmk);
  int CommonPrefixWith(IMoniker pmkOther, out IMoniker ppmkPrefix);
  int RelativePathTo(IMoniker pmkOther, out IMoniker ppmkRelPath);
  int GetDisplayName(IBindCtx pbc, IMoniker pmkToLeft, out wchar* ppszDisplayName);
  int ParseDisplayName(IBindCtx pbc, IMoniker pmkToLeft, wchar* pszDisplayName, out uint pchEaten, out IMoniker ppmkOut);
  int IsSystemMoniker(out uint pswMkSys);
}

interface IRunningObjectTable : IUnknown {
  static GUID IID = { 0x00000010, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int Register(uint grfFlags, IUnknown punkObject, IMoniker pmkObjectName, out uint pdwRegister);
  int Revoke(uint dwRegister);
  int IsRunning(IMoniker pmkObjectName);
  int GetObject(IMoniker pmkObjectName, out IUnknown ppunkObject);
  int NoteChangeTime(uint dwRegister, ref FILETIME pfiletime);
  int GetTimeOfLastChange(IMoniker pmkObjectName, out FILETIME pfiletime);
  int EnumRunning(out IEnumMoniker ppenumMoniker);
}

interface ITypeMarshal : IUnknown {
  static GUID IID = { 0x0000002D, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int Size(void* pvType, uint dwDestContext, void* pvDestContext, out uint pSize);
  int Marshal(void* pvType, uint dwDestContext, void* pvDestContext, uint cbBufferLength, ubyte* pBuffer, out uint pcbWritten);
  int Unmarshal(void* pvType, uint dwFlags, uint cbBufferLength, ubyte* pBuffer, out uint pcbRead);
  int Free(void* pvType);
}

interface ITypeFactory : IUnknown {
  static GUID IID = { 0x0000002E, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int CreateFromTypeInfo(ITypeInfo pTypeInfo, ref GUID riid, out IUnknown ppv);
}

interface IRecordInfo : IUnknown {
  static GUID IID = { 0x0000002F, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int RecordInit(void* pvNew);
  int RecordClear(void* pvExisting);
  int RecordCopy(void* pvExisting, void* pvNew);
  int GetGuid(out GUID pguid);
  int GetName(out wchar* pbstrName);
  int GetSize(out uint pcbSize);
  int GetTypeInfo(out ITypeInfo ppTypeInfo);
  int GetField(void* pvData, wchar* szFieldName, out VARIANT pvarField);
  int GetFieldNoCopy(void* pvData, wchar* szFieldName, out VARIANT pvarField, void** ppvDataCArray);
  int PutField(uint wFlags, void* pvData, wchar* szFieldName, ref VARIANT pvarField);
  int PutFieldNoCopy(uint wFlags, void* pvData, wchar* szFieldName, ref VARIANT pvarField);
  int GetFieldNames(out uint pcNames, wchar** rgBstrNames);
  bool IsMatchingType(IRecordInfo pRecordInfo);
  void* RecordCreate();
  int RecordCreateCopy(void* pvSource, out void* ppvDest);
  int RecordDestroy(void* pvRecord);
}

interface IEnumUnknown : IUnknown {
  static GUID IID = { 0x00000100, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int Next(uint celt, IUnknown* rgelt, out uint pceltFetched);
  int Skip(uint celt);
  int Reset();
  int Clone(out IEnumUnknown ppenum);
}

interface IEnumString : IUnknown {
  static GUID IID = { 0x00000101, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int Next(uint celt, wchar** rgelt, out uint pceltFetched);
  int Skip(uint celt);
  int Reset();
  int Clone(out IEnumString ppenum);
}

interface IEnumMoniker : IUnknown {
  static GUID IID = { 0x00000102, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int Next(uint celt, IEnumMoniker* rgelt, out uint pceltFetched);
  int Skip(uint celt);
  int Reset();
  int Clone(out IEnumMoniker ppenum);
}

struct DVTARGETDEVICE {
  uint tdSize;
  ushort tdDriverNameOffset;
  ushort tdDeviceNameOffset;
  ushort tdPortNameOffset;
  ushort tdExtDevmodeOffset;
  ubyte* tdData;
}

struct FORMATETC {
  ushort cfFormat;
  DVTARGETDEVICE* ptd;
  uint dwAspect;
  int lindex;
  uint tymed;
}

interface IEnumFORMATETC : IUnknown {
  static GUID IID = { 0x00000103, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int Next(uint celt, FORMATETC* rgelt, out uint pceltFetched);
  int Skip(uint celt);
  int Reset();
  int Clone(out IEnumFORMATETC ppenum);
}

struct OLEVERB {
  int lVerb;
  wchar* lpszVerbName;
  uint fuFlags;
  uint grfAttribs;
}

interface IEnumOLEVERB : IUnknown {
  static GUID IID = { 0x00000104, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int Next(uint celt, OLEVERB* rgelt, out uint pceltFetched);
  int Skip(uint celt);
  int Reset();
  int Clone(out IEnumOLEVERB ppenum);
}

struct STGMEDIUM {
  uint tymed;
  union {
    Handle hBitmap;
    Handle hMetaFilePict;
    Handle hEnhMetaFile;
    Handle hGlobal;
    wchar* lpszFileName;
    IStream pstm;
    IStorage pstg;
  }
  IUnknown pUnkForRelease;
}

struct STATDATA {
  FORMATETC formatetc;
  uint advf;
  IAdviseSink pAdvSink;
  uint dwConnection;
}

interface IEnumSTATDATA : IUnknown {
  static GUID IID = { 0x00000105, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int Next(uint celt, STATDATA* rgelt, out uint pceltFetched);
  int Skip(uint celt);
  int Reset();
  int Clone(out IEnumSTATDATA ppenum);
}

interface IPersist : IUnknown {
  static GUID IID = { 0x0000010c, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int GetClassID(out GUID pClassID);
}

interface IPersistStream : IPersist {
  static GUID IID = { 0x00000109, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int IsDirty();
  int Load(IStream pStm);
  int Save(IStream pStm, int fClearDirty);
  int GetSizeMax(out ulong pcbSize);
}

interface IDataObject : IUnknown {
  static GUID IID = { 0x0000010e, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int GetData(ref FORMATETC pformatetcIn, out STGMEDIUM pmedium);
  int GetDataHere(ref FORMATETC pformatetc, ref STGMEDIUM pmedium);
  int QueryGetData(ref FORMATETC pformatetc);
  int GetCanonicalFormatEtc(ref FORMATETC pformatetcIn, out FORMATETC pformatetcOut);
  int SetData(ref FORMATETC pformatetc, ref STGMEDIUM pmedium, bool fRelease);
  int EnumFormatEtc(uint dwDirection, out IEnumFORMATETC ppenumFormatEtc);
  int DAdvise(ref FORMATETC pformatetc, uint advf, IAdviseSink pAdvSink, out uint pdwConnection);
  int DUnadvise(uint dwConnection);
  int EnumDAdvise(out IEnumSTATDATA ppenumAdvise);
}

interface IAdviseSink : IUnknown {
  static GUID IID = { 0x0000010f, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int OnDataChange(ref FORMATETC pFormatetc, ref STGMEDIUM pStgmed);
  int OnViewChange(uint dwAspect, int lindex);
  int OnRename(IMoniker pmk);
  int OnSave();
  int OnClose();
}

interface IDropSource : IUnknown {
  static GUID IID = { 0x00000121, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int QueryContinueDrag(int fEscapePressed, uint grfKeyState);
  int GiveFeedback(uint dwEffect);
}

interface IDropTarget : IUnknown {
  static GUID IID = { 0x00000122, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int DragEnter(IDataObject pDataObj, uint grfKeyState, POINT pt, ref uint pdwEffect);
  int DragOver(uint grfKeyState, POINT pt, ref uint pdwEffect);
  int DragLeave();
  int Drop(IDataObject pDataObj, uint grfKeyState, POINT pt, ref uint pdwEffect);
}

int RegisterDragDrop(Handle hwnd, IDropTarget pDropTarget);
int RevokeDragDrop(Handle hwnd);
int DoDragDrop(IDataObject pDataObject, IDropSource pDropSource, uint dwOKEffects, out uint pdwEffect);

enum : ushort {
  DISPATCH_METHOD         = 0x1,
  DISPATCH_PROPERTYGET    = 0x2,
  DISPATCH_PROPERTYPUT    = 0x4,
  DISPATCH_PROPERTYPUTREF = 0x8
}

enum {
  DISPID_UNKNOWN = -1,
  DISPID_VALUE = 0,
  DISPID_PROPERTYPUT = -3,
  DISPID_NEWENUM = -4,
  DISPID_EVALUATE = -5,
  DISPID_CONSTRUCTOR = -6,
  DISPID_DESTRUCTOR = -7,
  DISPID_COLLECT = -8
}

interface IDispatch : IUnknown {
  static GUID IID = { 0x00020400, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int GetTypeInfoCount(out uint pctinfo);
  int GetTypeInfo(uint iTInfo, uint lcid, out ITypeInfo ppTInfo);
  int GetIDsOfNames(ref GUID riid, wchar** rgszNames, uint cNames, uint lcid, int* rgDispId);
  int Invoke(int dispIdMember, ref GUID riid, uint lcid, ushort wFlags, DISPPARAMS* pDispParams, VARIANT* pVarResult, EXCEPINFO* pExcepInfo, uint* puArgErr);
}

interface ITypeInfo : IUnknown {
  static GUID IID = { 0x00020401, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int GetTypeAttr(out TYPEATTR* ppTypeAttr);
  int GetTypeComp(out ITypeComp ppTComp);
  int GetFuncDesc(uint index, out FUNCDESC* ppFuncDesc);
  int GetVarDesc(uint index, out VARDESC* ppVarDesc);
  int GetNames(int memid, wchar** rgBstrNames, uint cMaxNames, out uint pcNames);
  int GetRefTypeOfImplType(uint index, out uint pRefType);
  int GetImplTypeFlags(uint index, out int pImplTypeFlags);
  int GetIDsOfNames(wchar** rgszNames, uint cNames, int* pMemId);
  int Invoke(void* pvInstance, int memid, ushort wFlags, DISPPARAMS* pDispParams, VARIANT* pVarResult, EXCEPINFO* pExcepInfo, uint* puArgErr);
  int GetDocumentation(int memid, wchar** pBstrName, wchar** pBstrDocString, uint* pdwHelpContext, wchar** pBstrHelpFile);
  int GetDllEntry(int memid, INVOKEKIND invKind, wchar** pBstrDllName, wchar** pBstrName, ushort* pwOrdinal);
  int GetRefTypeInfo(uint hRefType, out ITypeInfo ppTInfo);
  int AddressOfMember(int memid, INVOKEKIND invKind, void** ppv);
  int CreateInstance(IUnknown pUnkOuter, ref GUID riid, void** ppvObj);
  int GetMops(int memid, wchar** pBstrMops);
  int GetContainingTypeLib(out ITypeLib ppTLib, out uint pIndex);
  int ReleaseTypeAttr(TYPEATTR* pTypeAttr);
  int ReleaseFuncDesc(FUNCDESC* pFuncDesc);
  int ReleaseVarDesc(VARDESC* pVarDesc);
}

/**
 */
interface ITypeLib : IUnknown {
  static GUID IID = { 0x00020402, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  /**
   * Returns the number of type descriptions in the type library.
   */
  uint GetTypeInfoCount();
  /**
   * Retrieves the specified type description in the library.
   * Params:
   *   index = The _index of the ITypeInfo interface to return.
   *   ppTInfo = When the method returns, the ITypeInfo describing the type referenced by index.
   */
  int GetTypeInfo(uint index, out ITypeInfo ppTInfo);
  /**
   * Retrieves the type of a type description.
   * Params:
   *   index = The _index of the type desciption in the library.
   *   pTKind = When the method returns, the TYPEKIND enumeration for the type description.
   */
  int GetTypeInfoType(uint index, out TYPEKIND pTKind);
  /**
   * Retrieves the type description that corresponds to the specified GUID.
   */
  int GetTypeInfoOfGuid(ref GUID guid, out ITypeInfo ppTInfo);
  int GetLibAttr(out TLIBATTR* ppTLibAttr);
  int GetTypeComp(out ITypeComp ppTComp);
  int GetDocumentation(int index, wchar** pBstrName, wchar** pBstrDocString, uint* pBstrHelpContext, wchar** pBstrHelpFile);
  int IsName(wchar* szNameBuf, uint lHashVal, out bool pfName);
  int FindName(wchar* szNameBuf, uint lHashVal, ITypeInfo* ppTInfo, int* rgMemId, ref ushort pcFound);
  int ReleaseTLibAttr(TLIBATTR* pTLibAttr);
}

interface ITypeComp : IUnknown {
  static GUID IID = { 0x00020403, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int Bind(wchar* szName, uint lHashVal, ushort wFlags, out ITypeInfo ppTInfo, out DESCKIND pDescKind, out BINDPTR pBindPtr);
  int BindType(wchar* szName, uint lHashVal, out ITypeInfo ppTInfo, out ITypeComp ppTComp);
}

interface IEnumVARIANT : IUnknown {
  static GUID IID = { 0x00020404, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int Next(uint celt, VARIANT* rgVar, out uint pCeltFetched);
  int Skip(uint celt);
  int Reset();
  int Clone(out IEnumVARIANT ppEnum);
}

interface ICreateTypeInfo : IUnknown {
  static GUID IID = { 0x00020405, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int SetGuid(ref GUID guid);
  int SetTypeFlags(uint uTypeFlags);
  int SetDocString(wchar* szStrDoc);
  int SetHelpContext(uint dwHelpContext);
  int SetVersion(ushort wMajorVerNum, ushort wMinorVerNum);
  int AddRefTypeInfo(ITypeInfo pTInfo, ref uint phRefType);
  int AddFuncDesc(uint index, FUNCDESC* pFuncDesc);
  int AddImplType(uint index, uint hRefType);
  int SetTypeImplFlags(uint index, int implTypeFlags);
  int SetAlignment(ushort cbAlignment);
  int SetSchema(wchar* pStrSchema);
  int AddVarDesc(uint index, VARDESC* pVarDesc);
  int SetFuncAndParamNames(uint index, wchar** rgszNames, uint cNames);
  int SetVarName(uint index, wchar* szName);
  int SetTypeDescAlias(TYPEDESC* pTDescAlias);
  int DefineFuncAsDllEntry(uint index, wchar* szDllName, wchar* szProcName);
  int SetFuncDocString(uint index, wchar* szDocString);
  int SetVarDocString(uint index, wchar* szDocString);
  int SetFuncHelpContext(uint index, uint dwHelpContext);
  int SetVarHelpContext(uint index, uint dwHelpContext);
  int SetMops(uint index, wchar* bstrMops);
  int SetTypeIdldesc(IDLDESC* pIdlDesc);
  int LayOut();
}

interface ICreateTypeInfo2 : ICreateTypeInfo {
  static GUID IID = { 0x0002040E, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int DeleteFuncDesc(uint index);
  int DeleteFuncDescByMemId(int memid, INVOKEKIND invKind);
  int DeleteVarDesc(uint index);
  int DeleteVarDescByMemId(int memid);
  int DeleteImplType(uint index);
  int SetCustData(ref GUID guid, ref VARIANT pVarVal);
  int SetFuncCustData(uint index, ref GUID guid, ref VARIANT pVarVal);
  int SetParamCustData(uint indexFunc, uint indexParam, ref GUID guid, ref VARIANT pVarVal);
  int SetVarCustData(uint index, ref GUID guid, ref VARIANT pVarVal);
  int SetImplTypeCustData(uint index, ref GUID guid, ref VARIANT pVarVal);
  int SetHelpStringContext(uint dwHelpStringContext);
  int SetFuncHelpStringContext(uint index, uint dwHelpStringContext);
  int SetVarHelpStringContext(uint index, uint dwHelpStringContext);
  int Invalidate();
}

interface ICreateTypeLib : IUnknown {
  static GUID IID = { 0x00020406, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int CreateTypeInfo(wchar* szName, TYPEKIND tkind, out ICreateTypeInfo ppCTInfo);
  int SetName(wchar* szName);
  int SetVersion(ushort wMajorVerNum, ushort wMinorVerNum);
  int SetGuid(ref GUID guid);
  int SetDocString(wchar* szDoc);
  int SetHelpFileName(wchar* szHelpFileName);
  int SetHelpContext(uint dwHelpContext);
  int SetLcid(uint lcid);
  int SetLibFlags(uint uLibFlags);
  int SaveAllChanges();
}

interface ICreateTypeLib2 : ICreateTypeLib {
  static GUID IID = { 0x0002040F, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int DeleteTypeInfo(wchar* szName);
  int SetCustData(ref GUID guid, ref VARIANT pVarVal);
  int SetHelpStringContext(uint dwHelpStringContext);
  int SetHelpStringDll(wchar* szFileName);
}

interface ITypeChangeEvents : IUnknown {
  static GUID IID = { 0x00020410, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int RequestTypeChange(CHANGEKIND changeKind, ITypeInfo pTInfoBefore, wchar* pStrName, out int pfCancel);
  int AfterTypeChange(CHANGEKIND changeKind, ITypeInfo pTInfoAfter, wchar* pStrName);
}

struct CUSTDATAITEM {
  GUID guid;
  VARIANT varValue;
}

struct CUSTDATA {
  uint cCustData;
  CUSTDATAITEM* prgCustData;
}

interface ITypeLib2 : ITypeLib {
  static GUID IID = { 0x00020411, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int GetCustData(ref GUID guid, out VARIANT pVarVal);
  int GetLibStatistics(out uint pcUniqueNames, out uint pcchUniqueNames);
  int GetDocumentation2(int index, uint lcid, wchar** pBstrHelpString, uint* pdwHelpContext, wchar** pBstrHelpStringDll);
  int GetAllCustData(out CUSTDATA pCustData);
}

interface ITypeInfo2 : ITypeInfo {
  static GUID IID = { 0x00020412, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int GetTypeKind(out TYPEKIND pTypeKind);
  int GetTypeFlags(out uint pTypeFlags);
  int GetFuncIndexOfMemId(int memid, INVOKEKIND invKind, out uint pFuncIndex);
  int GetVarIndexOfMemId(int memid, out uint pVarIndex);
  int GetCustData(ref GUID guid, out VARIANT pVarVal);
  int GetFuncCustData(uint index, ref GUID guid, out VARIANT pVarVal);
  int GetParamCustData(uint indexFunc, uint indexParam, ref GUID guid, out VARIANT pVarVal);
  int GetVarCustData(uint index, ref GUID guid, out VARIANT pVarVal);
  int GetImplTypeCustData(uint index, ref GUID guid, out VARIANT pVarVal);
  int GetDocumentation2(int memid, uint lcid, wchar** pBstrHelpString, uint* pdwHelpContext, wchar** pBstrHelpStringDll);
  int GetAllCustData(out CUSTDATA pCustData);
  int GetAllFuncCustData(uint index, out CUSTDATA pCustData);
  int GetAllParamCustData(uint indexFunc, uint indexParam, out CUSTDATA pCustData);
  int GetAllVarCustData(uint index, out CUSTDATA pCustData);
  int GetAllTypeImplCustData(uint index, out CUSTDATA pCustData);
}

interface ICatRegister : IUnknown {
  static GUID IID = { 0x0002E012, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int RegisterCategories(uint cCategories, CATEGORYINFO* rgCategoryInfo);
  int UnRegisterCategories(uint cCategories, GUID* rgcatid);
  int RegisterClassImplCategories(ref GUID rclsid, uint cCategories, GUID* rgcatid);
  int UnRegisterClassImplCategories(ref GUID rclsid, uint cCategories, GUID* rgcatid);
  int RegisterClassReqCategories(ref GUID rclsid, uint cCategories, GUID* rgcatid);
  int UnRegisterClassReqCategories(ref GUID rclsid, uint cCategories, GUID* rgcatid);
}

interface IConnectionPointContainer : IUnknown {
  static GUID IID = { 0xB196B284, 0xBAB4, 0x101A, 0xB6, 0x9C, 0x00, 0xAA, 0x00, 0x34, 0x1D, 0x07 };
  int EnumConnectionPoints(out IEnumConnectionPoints ppEnum);
  int FindConnectionPoint(ref GUID riid, out IConnectionPoint ppCP);
}

interface IEnumConnectionPoints : IUnknown {
  static GUID IID = { 0xB196B285, 0xBAB4, 0x101A, 0xB6, 0x9C, 0x00, 0xAA, 0x00, 0x34, 0x1D, 0x07 };
  int Next(uint celt, IConnectionPoint* ppCP, out uint pceltFetched);
  int Skip(uint celt);
  int Reset();
  int Clone(out IEnumConnectionPoints ppenum);
}

interface IErrorInfo : IUnknown {
  static GUID IID = { 0x1CF2B120, 0x547D, 0x101B, 0x8E, 0x65, 0x08, 0x00, 0x2B, 0x2B, 0xD1, 0x19 };
  int GetGUID(out GUID pGUID);
  int GetSource(out wchar* pBstrSource);
  int GetDescription(out wchar* pBstrDescription);
  int GetHelpFile(out wchar* pBstrHelpFile);
  int GetHelpContext(out uint pdwHelpContext);
}

interface IConnectionPoint : IUnknown {
  static GUID IID = { 0xB196B286, 0xBAB4, 0x101A, 0xB6, 0x9C, 0x00, 0xAA, 0x00, 0x34, 0x1D, 0x07 };
  int GetConnectionInterface(out GUID pIID);
  int GetConnectionPointContainer(out IConnectionPointContainer ppCPC);
  int Advise(IUnknown pUnkSink, out uint pdwCookie);
  int Unadvise(uint dwCookie);
  int EnumConnections(out IEnumConnections ppenum);
}

struct CONNECTDATA {
  IUnknown pUnk;
  uint dwCookie;
}

interface IEnumConnections : IUnknown {
  static GUID IID = { 0xB196B287, 0xBAB4, 0x101A, 0xB6, 0x9C, 0x00, 0xAA, 0x00, 0x34, 0x1D, 0x07 };
  int Next(uint celt, CONNECTDATA* rgcd, out uint pceltFetched);
  int Skip(uint celt);
  int Reset();
  int Clone(out IEnumConnections ppenum);
}

struct LICINFO {
  int cbLicInfo = LICINFO.sizeof;
  int fRuntimeKeyAvail;
  int fLicVerified;
}

interface IClassFactory2 : IClassFactory {
  static GUID IID = { 0xB196B28F, 0xBAB4, 0x101A, 0xB6, 0x9C, 0x00, 0xAA, 0x00, 0x34, 0x1D, 0x07 };
  int GetLicInfo(out LICINFO pLicInfo);
  int RequestLicKey(uint dwReserved, out wchar* pBstrKey);
  int CreateInstanceLic(IUnknown pUnkOuter, IUnknown pUnkReserved, ref GUID riid, wchar* bstrKey, void** ppvObj);
}

struct TEXTMETRICOLE {
  int tmHeight;
  int tmAscent;
  int tmDescent;
  int tmInternalLeading;
  int tmExternalLeading;
  int tmAveCharWidth;
  int tmMaxCharWidth;
  int tmWeight;
  int tmOverhang;
  int tmDigitizedAspectX;
  int tmDigitizedAspectY;
  wchar tmFirstChar;
  wchar tmLastChar;
  wchar tmDefaultChar;
  wchar tmBreakChar;
  ubyte tmItalic;
  ubyte tmUnderlined;
  ubyte tmStruckOut;
  ubyte tmPitchAndFamily;
  ubyte tmCharSet;
}

interface IFont : IUnknown {
  static GUID IID = { 0xBEF6E002, 0xA874, 0x101A, 0x8B, 0xBA, 0x00, 0xAA, 0x00, 0x30, 0x0C, 0xAB };
  int get_Name(out wchar* pName);
  int set_Name(wchar* name);
  int get_Size(out long pSize);
  int set_Size(long size);
  int get_Bold(out int pBold);
  int set_Bold(int bold);
  int get_Italic(out int pItalic);
  int set_Italic(int italic);
  int get_Underline(out int pUnderline);
  int set_Underline(int underline);
  int get_Strikethrough(out int pStrikethrough);
  int set_Strikethrough(int strikethrough);
  int get_Weight(out short pWeight);
  int set_Weight(short weight);
  int get_Charset(out short pCharset);
  int set_Charset(short charset);
  int get_hFont(out Handle phFont);
  int Clone(out IFont ppFont);
  int IsEqual(IFont pFontOther);
  int SetRatio(int cyLogical, int cyHimetric);
  int QueryTextMetrics(out TEXTMETRICOLE pTM);
  int AddRefHfont(Handle hFont);
  int ReleaseHfont(Handle hFont);
  int SetHdc(Handle hDC);
}

interface IPicture : IUnknown {
  static GUID IID = { 0x7BF80980, 0xBF32, 0x101A, 0x8B, 0xBB, 0x00, 0xAA, 0x00, 0x30, 0x0C, 0xAB };
  int get_Handle(out uint pHandle);
  int get_hPal(out uint phPal);
  int get_Type(out short pType);
  int get_Width(out int pWidth);
  int get_Height(out int pHeight);
  int Render(Handle hDC, int x, int y, int cx, int cy, int xSrc, int ySrc, int cxSrc, int cySrc, RECT* pRcBounds);
  int set_hPal(uint hPal);
  int get_CurDC(out Handle phDC);
  int SelectPicture(Handle hDCIn, out Handle phDCOut, out uint phBmpOut);
  int get_KeepOriginalFormat(out int pKeep);
  int put_KeepOriginalFormat(int keep);
  int PictureChanged();
  int SaveAsFile(IStream pStream, int fSaveMemCopy, out int pCbSize);
  int get_Attributes(out uint pDwAttr);
}

interface IFontEventsDisp : IDispatch {
  static GUID IID = { 0x4EF6100A, 0xAF88, 0x11D0, 0x98, 0x46, 0x00, 0xC0, 0x4F, 0xC2, 0x99, 0x93 };
}

interface IFontDisp : IDispatch {
  static GUID IID = { 0xBEF6E003, 0xA874, 0x101A, 0x8B, 0xBA, 0x00, 0xAA, 0x00, 0x30, 0x0C, 0xAB };
}

interface IPictureDisp : IDispatch {
  static GUID IID = { 0x7BF80981, 0xBF32, 0x101A, 0x8B, 0xBB, 0x00, 0xAA, 0x00, 0x30, 0x0C, 0xAB };
}

interface IEnumGUID : IUnknown {
  static GUID IID = { 0x0002E000, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int Next(uint celt, GUID* rgelt, out uint pceltFetched);
  int Skip(uint celt);
  int Reset();
  int Clone(out IEnumGUID ppenum);
}

interface IEnumCATEGORYINFO : IUnknown {
  static GUID IID = { 0x0002E011, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int Next(uint celt, CATEGORYINFO* rgelt, out uint pceltFetched);
  int Skip(uint celt);
  int Reset();
  int Clone(out IEnumGUID ppenum);
}

interface ICatInformation : IUnknown {
  static GUID IID = { 0x0002E013, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int EnumCategories(uint lcid, out IEnumCATEGORYINFO ppenumCategoryInfo);
  int GetCategoryDesc(inout GUID rcatid, uint lcid, out wchar* pszDesc);
  int EnumClassesOfCategories(uint cImplemented, GUID* rgcatidImpl, uint cRequired, GUID* rgcatidReq, out IEnumGUID ppenumClsid);
  int IsClassOfCategories(inout GUID rclsid, uint cImplemented, GUID* rgcatidImpl, uint cRequired, GUID* rgcatidReq);
  int EnumImplCategoriesOfClass(inout GUID rclsid, out IEnumGUID ppenumCatid);
  int EnumReqCategoriesOfClass(inout GUID rclsid, out IEnumGUID ppenumCatid);
}

struct PROPERTYKEY {
  GUID fmtid;
  uint pid;
}

interface IPropertyStore : IUnknown {
  static GUID IID = { 0x886d8eeb, 0x8cf2, 0x4446, 0x8d, 0x02, 0xcd, 0xba, 0x1d, 0xbd, 0xcf, 0x99 };
  int GetCount(out uint cProps);
  int GetAt(uint iProp, out PROPERTYKEY pkey);
  int GetValue(ref PROPERTYKEY key, out PROPVARIANT pv);
  int SetValue(ref PROPERTYKEY key, ref PROPVARIANT propvar);
  int Commit();
}

int CoCreateGuid(out GUID pguid);

enum COINIT : uint {
  COINIT_MULTITHREADED        = 0x0,
  COINIT_APARTMENTTHREADED    = 0x2,
  COINIT_DISABLE_OLE1DDE      = 0x4,
  COINIT_SPEED_OVER_MEMORY    = 0x8
}

int CoInitializeEx(void* pvReserved, uint dwCoInit);
int CoInitialize(void*);
void CoUninitialize();

enum CLSCTX : uint {
  CLSCTX_INPROC_SERVER = 0x1,
  CLSCTX_INPROC_HANDLER = 0x2,
  CLSCTX_LOCAL_SERVER = 0x4,
  CLSCTX_INPROC_SERVER16 = 0x8,
  CLSCTX_REMOTE_SERVER = 0x10,
  CLSCTX_INPROC_HANDLER16 = 0x20,
  CLSCTX_RESERVED1 = 0x40,
  CLSCTX_RESERVED2 = 0x80,
  CLSCTX_RESERVED3 = 0x100,
  CLSCTX_RESERVED4 = 0x200,
  CLSCTX_NO_CODE_DOWNLOAD = 0x400,
  CLSCTX_RESERVED5 = 0x800,
  CLSCTX_NO_CUSTOM_MARSHAL = 0x1000,
  CLSCTX_ENABLE_CODE_DOWNLOAD = 0x2000,
  CLSCTX_NO_FAILURE_LOG = 0x4000,
  CLSCTX_DISABLE_AAA = 0x8000,
  CLSCTX_ENABLE_AAA = 0x10000,
  CLSCTX_FROM_DEFAULT_CONTEXT = 0x20000,
  CLSCTX_ACTIVATE_32_BIT_SERVER = 0x40000,
  CLSCTX_ACTIVATE_64_BIT_SERVER = 0x80000,
  CLSCTX_INPROC = CLSCTX_INPROC_SERVER | CLSCTX_INPROC_HANDLER,
  CLSCTX_ALL = CLSCTX_INPROC_SERVER | CLSCTX_INPROC_HANDLER | CLSCTX_LOCAL_SERVER,
  CLSCTX_SERVER = CLSCTX_INPROC_SERVER | CLSCTX_LOCAL_SERVER
}

int CoCreateInstance(ref GUID rclsid, IUnknown pUnkOuter, uint dwClsContext, ref GUID riid, void** ppv);
int CoGetClassObject(ref GUID rclsid, uint dwClsContext, void* pvReserved, ref GUID riid, void** ppv);

enum : uint {
  ACTIVEOBJECT_STRONG,
  ACTIVEOBJECT_WEAK
}

int RegisterActiveObject(IUnknown punk, ref GUID rclsid, uint dwFlags, out uint pdwRegister);
int RevokeActiveObject(uint dwRegister, void* pvReserved);
int GetActiveObject(ref GUID rclsid, void* pvReserved, out IUnknown ppunk);

int ProgIDFromCLSID(ref GUID clsid, out wchar* lplpszProgID);
int CLSIDFromProgID(wchar* lpszProgID, out GUID lpclsid);

void* CoTaskMemAlloc(size_t cb);
void* CoTaskMemRealloc(void* pv, size_t cb);
void CoTaskMemFree(void* pv);

int CoGetMalloc(uint dwMemContext/* = 1*/, out IMalloc ppMalloc);

int LoadTypeLib(wchar* szFile, out ITypeLib pptlib);

enum REGKIND {
  REGKIND_DEFAULT,
  REGKIND_REGISTER,
  REGKIND_NONE
}

int LoadTypeLibEx(wchar* szFile, REGKIND regkind, out ITypeLib pptlib);
int LoadRegTypeLib(ref GUID rgiud, ushort wVerMajor, ushort wVerMinor, uint lcid, out ITypeLib pptlib);
int QueryPathOfRegTypeLib(ref GUID guid, ushort wVerMajor, ushort wVerMinor, uint lcid, out wchar* lpbstrPathName);
int RegisterTypeLib(ITypeLib ptlib, wchar* szFullPath, wchar* szHelpDir);
int UnRegisterTypeLib(ref GUID libID, ushort wVerMajor, ushort wVerMinor, uint lcid, SYSKIND syskind);
int RegisterTypeLibForUser(ITypeLib ptlib, wchar* szFullPath, wchar* szHelpDir);
int UnRegisterTypeLibForUser(ref GUID libID, ushort wVerMajor, ushort wVerMinor, uint lcid, SYSKIND syskind);
int CreateTypeLib(SYSKIND syskind, wchar* szFile, out ICreateTypeLib ppctlib);
int CreateTypeLib2(SYSKIND syskind, wchar* szFile, out ICreateTypeLib2 ppctlib);

wchar* SysAllocString(wchar* psz);
int SysReAllocString(ref wchar* pbstr, wchar* psz);
wchar* SysAllocStringLen(wchar* strIn, uint ui);
int SysReAllocStringLen(ref wchar* pbstr, wchar* psz, uint len);
void SysFreeString(wchar* bstr);
uint SysStringLen(wchar* bstr);
uint SysStringByteLen(wchar* bstr);
wchar* SysAllocStringByteLen(wchar* psz, uint len);

void VariantInit(VARIANT* pvarg);
int VariantClear(VARIANT* pvarg);
int VariantCopy(VARIANT* pvargDest, in VARIANT* pvargSrc);
int VariantChangeType(VARIANT* pvargDest, in VARIANT* pvarSrc, ushort wFlags, VARTYPE vt);
int VariantChangeTypeEx(VARIANT* pvargDest, in VARIANT* pvarSrc, uint lcid, ushort wFlags, VARTYPE vt);

alias DllImport!("propsys.dll", "PropVariantCopy",
  int function(PROPVARIANT* pvarDest, in PROPVARIANT* pvarSrc))
  PropVariantCopy;

alias DllImport!("propsys.dll", "PropVariantToBSTR",
  int function(PROPVARIANT* propvar, wchar** pbstrOut))
  PropVariantToBSTR;

enum : uint {
  VARIANT_NOVALUEPROP = 0x1,
  VARIANT_ALPHABOOL = 0x2,
  VARIANT_NOUSEROVERRIDE = 0x4,
  VARIANT_CALENDAR_HIJRI = 0x8,
  VARIANT_LOCALBOOL = 0x10,
  VARIANT_CALENDAR_THAI = 0x20,
  VARIANT_CALENDAR_GREGORIAN = 0x40,
  VARIANT_USE_NLS = 0x80
}

int SafeArrayAllocDescriptor(uint cDims, out SAFEARRAY* ppsaOut);
int SafeArrayAllocDescriptorEx(VARTYPE vt, uint cDims, out SAFEARRAY* ppsaOut);
int SafeArrayAllocData(SAFEARRAY* psa);
SAFEARRAY* SafeArrayCreate(VARTYPE vt, uint cDims, SAFEARRAYBOUND* rgsabound);
SAFEARRAY* SafeArrayCreateEx(VARTYPE vt, uint cDims, SAFEARRAYBOUND* rgsabound, void* pvExtra);
int SafeArrayCopyData(SAFEARRAY* psaSource, SAFEARRAY* psaTarget);
int SafeArrayDestroyDescriptor(SAFEARRAY* psa);
int SafeArrayDestroyData(SAFEARRAY* psa);
int SafeArrayDestroy(SAFEARRAY* psa);
int SafeArrayRedim(SAFEARRAY* psa, SAFEARRAYBOUND* psaboundNew);
uint SafeArrayGetDim(SAFEARRAY* psa);
uint SafeArrayGetElemsize(SAFEARRAY* psa);
int SafeArrayGetUBound(SAFEARRAY* psa, uint cDim, out int plUbound);
int SafeArrayGetLBound(SAFEARRAY* psa, uint cDim, out int plLbound);
int SafeArrayLock(SAFEARRAY* psa);
int SafeArrayUnlock(SAFEARRAY* psa);
int SafeArrayAccessData(SAFEARRAY* psa, void** ppvData);
int SafeArrayUnaccessData(SAFEARRAY* psa);
int SafeArrayGetElement(SAFEARRAY* psa, int* rgIndices, void* pv);
int SafeArrayPutElement(SAFEARRAY* psa, int* rgIndices, void* pv);
int SafeArrayCopy(SAFEARRAY* psa, out SAFEARRAY* ppsaOut);
int SafeArrayPtrOfIndex(SAFEARRAY* psa, int* rgIndices, void** ppvData);
int SafeArraySetRecordInfo(SAFEARRAY* psa, IRecordInfo prinfo);
int SafeArrayGetRecordInfo(SAFEARRAY* psa, out IRecordInfo prinfo);
int SafeArraySetIID(SAFEARRAY* psa, ref GUID guid);
int SafeArrayGetIID(SAFEARRAY* psa, out GUID pguid);
int SafeArrayGetVartype(SAFEARRAY* psa, out VARTYPE pvt);
SAFEARRAY* SafeArrayCreateVector(VARTYPE vt, int lLbound, uint cElements);
SAFEARRAY* SafeArrayCreateVectorEx(VARTYPE vt, int lLbound, uint cElements, void* pvExtra);

int CreateStreamOnHGlobal(Handle hGlobal, int fDeleteOnRelease, out IStream ppstm);

struct PICTDESC {
  uint cbSizeofStruct = PICTDESC.sizeof;
  uint picType;
  Handle handle;
}

int OleCreatePictureIndirect(PICTDESC* lpPictDesc, ref GUID riid, int fOwn, void** lplpvObj);
int OleLoadPicture(IStream lpstream, int lSize, int fRunmode, ref GUID riid, void** lplpvObj);

extern(D):

private bool isCOMInitialized = false;

private void startupCOM() {
  synchronized {
    if (!isCOMInitialized) {
      isCOMInitialized = true;
      CoInitialize(null);
    }
  }
}

private void shutdownCOM() {
  synchronized {
    if (isCOMInitialized) {
      std.gc.fullCollect();
      isCOMInitialized = false;
      CoUninitialize();
    }
  }
}

/**
 * The exception thrown when an unrecognized HRESULT is returned from a COM operation.
 */
public class COMException : BaseException {

  private int errorCode_;

  /**
   * Initializes a new instance with a specified error code.
   * Params: errorCode = The error code (HRESULT) value associated with this exception.
   */
  public this(int errorCode = E_FAIL) {
    errorCode_ = errorCode;
    super(getErrorMessage(errorCode));
  }

  /**
   * Initializes a new instance with a specified message and reference to the inner exception that caused this exception.
   * Params:
   *   message = The error _message that explains this exception.
   *   cause = The exception that caused this exception.
   */
  public this(string message, Exception cause = null) {
    super(message, cause);
  }

  /**
   * Gets the HRESULT of the error.
   * Returns: The HRESULT of the error.
   */
  public int errorCode() {
    return errorCode_;
  }

  private static string getErrorMessage(int error) {
    wchar[256] buffer;
    uint r = FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS, null, error, LOCALE_USER_DEFAULT, buffer.ptr, buffer.length + 1, null);
    if (r != 0) {
      string s = toUtf8(buffer.ptr, 0, r);
      while (r > 0) {
        char ch = s[r - 1];
        if (ch > ' ' && ch != '.')
          break;
        r--;
      }
      return format("{0}. (Exception from HRESULT: 0x{1:X8})", s[0 .. r], error);
    }
    return format("Unspecified error (0x{0:X8})", error);
  }

}

template QueryInterfaceImpl(T ...) {

  int QueryInterface(ref GUID riid, void** ppvObject) {
    *ppvObject = null;

    if (riid == IUnknown.IID)
      *ppvObject = cast(void*)cast(IUnknown)this;
    else foreach (I; T) {
      if (riid == I.IID) {
        *ppvObject = cast(void*)cast(I)this;
        break;
      }
    }

    if (*ppvObject is null)
      return E_NOINTERFACE;

    (cast(IUnknown)this).AddRef();
    return S_OK;
  }

}

void runFinalizer(Object obj) {
  if (obj !is null) {
    ClassInfo** ci = cast(ClassInfo**)cast(void*)obj;
    if (*ci !is null) {
      ClassInfo c = **ci;
      if (c !is null) {
        do {
          if (c.destructor) {
            auto finalizer = cast(void function(Object))c.destructor;
            finalizer(obj);
          }
          c = c.base;
        } while (c !is null);
      }
    }
  }
}

template RefCountImpl() {

  private int refCount = 1;
  private bool finalized = false;

  uint AddRef() {
    return InterlockedIncrement(refCount);
  }

  uint Release() {
    if (InterlockedDecrement(refCount) == 0) {
      if (!finalized) {
        runFinalizer(this);
        finalized = true;
      }

      std.gc.removeRange(cast(void*)this);
      std.c.stdlib.free(cast(void*)this);
    }
    return refCount;
  }

  extern(D):

  new(size_t sz) {
    void* p = std.c.stdlib.malloc(sz);

    if (p == null)
      throw new OutOfMemoryException;

    std.gc.addRange(p, p + sz);
    return p;
  }

}

template IUnknownImpl(T ...) {
  mixin RefCountImpl;
  mixin QueryInterfaceImpl!(T);
}

// Only mix this in if you want the default behaviour as declared here implemented. You should subclass the type to override these methods.
template IDispatchImpl(T ...) {

  mixin IUnknownImpl!(IDispatch, T);

  int GetTypeInfoCount(out uint pctinfo) {
    pctinfo = 0;
    return E_NOTIMPL;
  }

  int GetTypeInfo(uint iTInfo, uint lcid, out ITypeInfo ppTInfo) {
    ppTInfo = null;
    return E_NOTIMPL;
  }

  int GetIDsOfNames(ref GUID riid, wchar** rgszNames, uint cNames, uint lcid, int* rgDispId) {
    rgDispId = null;
    return DISP_E_UNKNOWNNAME;
  }

  int Invoke(int dispIdMember, ref GUID riid, uint lcid, ushort wFlags, DISPPARAMS* pDispParams, VARIANT* pVarResult, EXCEPINFO* pExcepInfo, uint* puArgErr) {
    return DISP_E_MEMBERNOTFOUND;
  }

}

template DerivesFrom(T, TList ...) {
  const bool DerivesFrom = is(MostDerived!(T, TList) : T);
}

/**
 * The abstract base class for COM objects that derive from IUnknown or IDispatch.
 *
 * The Implements class provides default implementations of methods required by those interfaces, therefore subclasses need only override them when they 
 * specifically need to provide extra functionality. This class also overrides the new operator so that instances are not garbage collected.
 * Examples:
 * ---
 * class MyImpl : Implements!(IUnknown) {
 * }
 * ---
 */
public abstract class Implements(T ...) : T {
  static if (DerivesFrom!(IDispatch, T))
    mixin IDispatchImpl!(T);
  else
    mixin IUnknownImpl!(T);
}

/**
 * Specified whether to throw exceptions or return null when COM operations fail.
 */
public enum ExceptionPolicy {
  AllowNull,  /// Returns null on failure.
  ThrowIfNull /// Throws a COMException on failure.
}

template com_cast_impl(T, ExceptionPolicy exceptionPolicy) {

  public T com_cast_impl(U)(U obj) {
    static if (is(U : IUnknown)) {
      if (obj is null) {
        static if (exceptionPolicy == ExceptionPolicy.ThrowIfNull)
          throw new ArgumentNullException("obj");
        else
          return null;
      }

      T ret = null;
      if (obj.QueryInterface(T.IID, cast(void**)&ret) == S_OK) {
        return ret;
      }

      static if (exceptionPolicy == ExceptionPolicy.ThrowIfNull)
        throw new InvalidCastException("Invalid cast from '" ~ typeof(U).stringof ~ "' to '" ~ typeof(T).stringof ~ "'.");
      else
        return null;
    }
    else static if (is(U == VARIANT)) {
      const vt = VariantType!(T);
      static if (vt != VARTYPE.VT_VOID) {
        VARIANT v;
        if (VariantChangeTypeEx(&v, &obj, LOCALE_USER_DEFAULT, 0, vt) == S_OK) {
          static if (vt == VARTYPE.VT_BOOL) // bool
            return (v.boolVal == VARIANT_TRUE) ? true : false;
          else static if (vt == VARTYPE.VT_UI1) // ubyte
            return v.bVal;
          else static if (vt == VARTYPE.VT_I1) // byte
            return v.cVal;
          else static if (vt == VARTYPE.VT_UI2) // ushort
            return v.uiVal;
          else static if (vt == VARTYPE.VT_I2) // short
            return v.iVal;
          else static if (vt == VARTYPE.VT_UI4) // uint
            return v.ulVal;
          else static if (vt == VARTYPE.VT_I4) // int
            return v.lVal;
          else static if (vt == VARTYPE.VT_UI8) // ulong
            return v.ullVal;
          else static if (vt == VARTYPE.VT_I8) // long
            return v.llVal;
          else static if (vt == VARTYPE.VT_R4) // float
            return v.fltVal;
          else static if (vt == VARTYPE.VT_R8) // double
            return v.dblVal;
          else static if (vt == VARTYPE.VT_BSTR) {
            static if (is(T == wchar*))
              return v.bstrVal;
            else // string
              return fromBStr(v.bstrVal);
          }
          else static if (vt == VARTYPE.VT_UNKNOWN) // IUnknown
            return com_cast_impl(obj.punkVal);
          else static if (vt == VARTYPE.VT_DISPATCH) // IDispatch
            return com_cast_impl(obj.pdispVal);
          else static if (exceptionPolicy == ExceptionPolicy.ThrowIfNull)
            throw new InvalidCastException("Invalid cast from '" ~ typeof(U).stringof ~ "' to '" ~ typeof(T).stringof ~ "'.");
          else
            return T.init;
        }
        else static if (exceptionPolicy == ExceptionPolicy.ThrowIfNull)
          throw new InvalidCastException("Invalid cast from '" ~ typeof(U).stringof ~ "' to '" ~ typeof(T).stringof ~ "'.");
        else
          return T.init;
      }
      else static assert(false, "Cannot cast from '" ~ typeof(U).stringof ~ "' to '" ~ typeof(T).stringof ~ "'.");
    }
    else static assert(false, "Cannot cast from '" ~ typeof(U).stringof ~ "' to '" ~ typeof(T).stringof ~ "'.");
  }

}

/**
 * Invokes the conversion operation to convert from one COM type to another.

 * If the operand is a VARIANT, this function converts its value to the type represented by T. If the operand is an IUnknown-derived object, this function 
 * calls the object's QueryInterface method. If the conversion operation fails, the function returns T.init.
 *
 * Examples:
 * ---
 * // C++
 * bool tryToMeow(Dog* dog) {
 *   Cat* cat = NULL;
 *   HRESULT hr = dog->QueryInterface(IID_Cat, static_cast<void**>(&cat));
 *   if (hr == S_OK) {
 *     hr = cat->meow();
 *     cat->Release();
 *   }
 *   return hr == S_OK;
 * }
 *
 * // C#
 * bool tryToMeow(Dog dog) {
 *   Cat cat = dog as Cat;
 *   if (cat != null)
 *     return cat.meow();
 *   return false;
 * }
 *
 * // D
 * bool tryToMeow(Dog dog) {
 *   if (auto cat = com_cast!(Cat)(dog)) {
 *     scope(exit) cat.Release();
 *     return cat.meow() == S_OK;
 *   }
 *   return false;
 * }
 * ---
 */
template com_cast(T) {
  alias com_cast_impl!(T, ExceptionPolicy.AllowNull) com_cast;
}

/**
 * Invokes the conversion operation to convert from one COM type to another.

 * If the operand is a VARIANT, this function converts its value to the type represented by T. If the operand is an IUnknown-derived object, this function 
 * calls the object's QueryInterface method.
 * Throws: COMException if the conversion operation fails.
 */
template safe_com_cast(T) {
  alias com_cast_impl!(T, ExceptionPolicy.ThrowIfNull) safe_com_cast;
}

/**
 * Indicates the execution contexts in which a COM object is to be run.
 */
public enum ExecutionContext {
  InProcessServer = CLSCTX.CLSCTX_INPROC_SERVER,    /// Runs in the same process as the caller of the function.
  InProcessHandler = CLSCTX.CLSCTX_INPROC_HANDLER,  /// Runs in the client process.
  LocalServer = CLSCTX.CLSCTX_LOCAL_SERVER,         /// Runs on the same machine but in a separate process.
  RemoteServer = CLSCTX.CLSCTX_REMOTE_SERVER,       /// Runs on a different machine.
  All = CLSCTX.CLSCTX_ALL
}

public IUnknown coCreateInstance(GUID clsid, IUnknown outer, ExecutionContext context, GUID iid) {
  IUnknown ret;
  if (CoCreateInstance(clsid, outer, cast(uint)context, iid, cast(void**)&ret) == S_OK)
    return ret;
  return null;
}

/**
 */
template coCreate(T, ExceptionPolicy exceptionPolicy = ExceptionPolicy.AllowNull) {

  /**
   * Creates a COM object of the class associated with the specified CLSID.
   * Params:
   *   clsid = A CLSID associated with the coclass that will be used to create the object.
   *   context = The _context in which to run the code that manages the new object with run.
   * Returns: A reference to the interface identified by T.
   * Examples:
   * ---
   * if (auto doc = coCreate!(IXMLDOMDocument3)(DOMDocument60.CLSID)) {
   *   scope(exit) doc.Release();
   * }
   * ---
   */
  public T coCreate(U)(U clsid, ExecutionContext context = ExecutionContext.InProcessServer) {
    GUID guid;
    static if (is(U == GUID)) {
      guid = clsid;
    }
    else static if (is(U == string)) {
      try {
        guid = GUID(clsid);
      }
      catch (FormatException) {
        int hr = CLSIDFromProgID(clsid.toUtf16z(), guid);
        if (FAILED(hr)) {
          static if (exceptionPolicy == ExceptionPolicy.ThrowIfNull)
            throw new COMException(hr);
          else
            return null;
        }
      }
    }
    else
      static assert(false, "GUID or string expected.");

    T obj = null;
    int hr = CoCreateInstance(guid, null, context, T.IID, cast(void**)&obj);
    if (SUCCEEDED(hr))
      return obj;

    static if (exceptionPolicy == ExceptionPolicy.ThrowIfNull)
      throw new COMException(hr);
    else
      return null;
  }

}

public IUnknown getActiveObject(string progId) {
  GUID clsid;
  CLSIDFromProgID(progId.toBStr(), clsid);
  IUnknown obj = null;
  if (GetActiveObject(clsid, null, obj) == S_OK)
    return obj;
  return null;
}

/**
 * Indicates whether the specified object represents a COM object.
 * Params: obj = The object to check.
 * Returns: true if obj is a COM type; otherwise, false.
 */
public bool isComObject(Object obj) {
  ClassInfo** ci = cast(ClassInfo**)cast(void*)obj;
  if (*ci !is null) {
    ClassInfo c = **ci;
    if (c !is null)
      return (c.flags & 1) != 0;
  }
  return false;
}

template CoInterfaces(T ...) {
  public static I coCreate(I, ExceptionPolicy exceptionPolicy = ExceptionPolicy.AllowNull)(ExecutionContext context = ExecutionContext.InProcessServer) {
    static if (IndexOf!(I, T) == -1)
      static assert(false, "'" ~ typeof(this).stringof ~ "' does not support '" ~ typeof(I).stringof ~ "'.");
    else
      return .coCreate!(I, exceptionPolicy)(typeof(this).CLSID, context);
  }
}

public void releaseAfter(IUnknown obj, void delegate() block) {
  try {
    block();
  }
  finally {
    if (obj !is null)
      obj.Release();
  }
}

public void clearAfter(VARIANT var, void delegate() block) {
  try {
    block();
  }
  finally {
    var.clear();
  }
}

/**
 * Allocates a BSTR equivalent to s.
 * Params: s = The string with which to initialize the BSTR.
 * Returns: The BSTR equivalent to s.
 */
public wchar* toBStr(string s) {
  if (s == null)
    return null;

  return SysAllocString(s.toUTF16z());
}

/**
 * Converts a BSTR to a string, freeing the original BSTR.
 * Params: bstr = The BSTR to convert.
 * Returns: A string equivalent to bstr.
 */
public string fromBStr(wchar* bstr) {
  if (bstr == null)
    return null;

  uint len = SysStringLen(bstr);
  if (len == 0)
    return null;

  string s = bstr[0 .. len].toUTF8();
  SysFreeString(bstr);
  return s;
}

/**
 * Frees the memory occuppied by the specified BSTR.
 * Params: bstr = The BSTR to free.
 */
public void freeBStr(wchar* bstr) {
  if (bstr != null)
    SysFreeString(bstr);
}

deprecated {
  alias fromBStr BSTRtoUTF8;
  alias toBStr UTF8toBSTR;
}

/**
 * Determines the equivalent VARTYPE of a built-in type.
 * Examples:
 * ---
 * VARTYPE vt = VariantType!(string);
 * ---
 */
template VariantType(T) {
  static if (is(T == VARIANT_BOOL))
    const VariantType = VARTYPE.VT_BOOL;
  else static if (is(T == ubyte))
    const VariantType = VARTYPE.VT_UI1;
  else static if (is(T == byte))
    const VariantType = VARTYPE.VT_I1;
  else static if (is(T == ushort))
    const VariantType = VARTYPE.VT_UI2;
  else static if (is(T == short))
    const VariantType = VARTYPE.VT_I2;
  else static if (is(T == uint))
    const VariantType = VARTYPE.VT_UI4;
  else static if (is(T == int))
    const VariantType = VARTYPE.VT_I4;
  else static if (is(T == ulong))
    const VariantType = VARTYPE.VT_UI8;
  else static if (is(T == long))
    const VariantType = VARTYPE.VT_I8;
  else static if (is(T == float))
    const VariantType = VARTYPE.VT_R4;
  else static if (is(T == double))
    const VariantType = VARTYPE.VT_R8;
  else static if (is(T == bool))
    const VariantType = VARTYPE.VT_BOOL;
  else static if (is(T E == enum))
    const VariantType = VariantType!(E);
  else static if (is(T : string))
    const VariantType = VARTYPE.VT_BSTR;
  else static if (is(T == wchar*))
    const VariantType = VARTYPE.VT_BSTR;
  else static if (is(T == char*))
    const VariantType = VARTYPE.VT_LPSTR;
  else static if (is(T == SAFEARRAY*))
    const VariantType = VARTYPE.VT_ARRAY;
  else static if (is(T == VARIANT))
    const VariantType = VARTYPE.VT_VARIANT;
  else static if (is(T : IDispatch))
    const VariantType = VARTYPE.VT_DISPATCH;
  else static if (is(T : IUnknown))
    const VariantType = VARTYPE.VT_UNKNOWN;
  else static if (is(T : DateTime))
    const VariantType = VARTYPE.VT_DATE;
  else static if (is(T : Object))
    const VariantType = VARTYPE.VT_BYREF;
  else static if (is(T == void*))
    const VariantType = cast(VARTYPE)(VARTYPE.VT_VOID | VARTYPE.VT_BYREF);
  else static if (is(T : void*))
    const VariantType = cast(VARTYPE)(VariantType!(typeof(*T)) | VARTYPE.VT_BYREF);
  else
    const VariantType = VARTYPE.VT_VOID;
}

// Safe Array support

public class ComIterator(TEnum, TItem = void) {

  private TEnum source;

  static if (is(TEnum == SAFEARRAY*) && is(TItem == void))
    static assert(false);

  static if (!is(TEnum == SAFEARRAY*))
    alias typeof(*ParameterTypeTuple!(TEnum.Next)[1]) TItem;

  public this(TEnum source) {
    this.source = source;
  }

  ~this() {
    static if (!is(TEnum == SAFEARRAY*)) {
      if (source !is null) {
        source.Release();
        source = null;
      }
    }
  }

  public int opApply(int delegate(ref TItem) action) {
    int result;

    uint fetched;
    TItem item;

    static if (is(TEnum == SAFEARRAY*)) {
      int lb = 0, ub = 0;
      SafeArrayGetLBound(source, 1, lb);
      SafeArrayGetUBound(source, 1, ub);
      int end = ub - lb + 1;

      int hr = E_FAIL;
      int index = 0;
      while (index < end) {
        hr = SafeArrayGetElement(source, &index, &item);
        if (hr != S_OK || (result = action(item)) != 0)
          break;
        index++;
      }
    }
    else {
      while (source.Next(1, &item, fetched) == S_OK) {
        if (fetched == 0 || (result = action(item)) != 0)
          break;
      }
      source.Reset();
    }

    return result;
  }

  public int opApply(int delegate(ref int, ref TItem) action) {
    int result, index;

    uint fetched;
    TItem item;

    static if (is(TEnum == SAFEARRAY*)) {
      int lb = 0, ub = 0;
      SafeArrayGetLBound(source, 1, lb);
      SafeArrayGetUBound(source, 1, ub);
      int end = ub - lb + 1;

      int hr = E_FAIL;
      while (index < end) {
        hr = SafeArrayGetElement(source, &index, &item);
        if (hr != S_OK || (result = action(index, item)) != 0)
          break;
        index++;
      }
    }
    else {
      while (source.Next(1, &item, fetched) == S_OK) {
        if (fetched == 0 || (result = action(index, item)) != 0)
          break;
        index++;
      }
      source.Reset();
    }

    return result;
  }

}

public ComIterator!(TEnum, TItem) com_enum(TEnum, TItem = void)(TEnum source) {
  return new ComIterator!(TEnum, TItem)(source);
}

public SAFEARRAY* toSafeArray(T)(T array) {
  if (array == null) return null;

  SAFEARRAY* safeArray = SafeArrayCreateVector(VARTYPE.VT_VARIANT, 0, array.length);

  VARIANT* data;
  SafeArrayAccessData(safeArray, cast(void**)&data);
  foreach (index, element; array) {
    data[index] = VARIANT(element);
  }
  SafeArrayUnaccessData(safeArray);

  return safeArray;
}

public T[] toArray(T)(SAFEARRAY* safeArray) {
  int upperBound, lowerBound;
  SafeArrayGetUBound(safeArray, 1, upperBound);
  SafeArrayGetLBound(safeArray, 1, lowerBound);
  int count = upperBound - lowerBound + 1;

  if (count == 0) return null;

  T[] result = new T[count];

  VARIANT* data;
  SafeArrayAccessData(safeArray, cast(void**)&data);
  for (int i = lowerBound; i <= upperBound; i++) {
    result[i] = com_cast!(T)(data[i]);
  }
  SafeArrayUnaccessData(safeArray);

  return result;
}

public struct SafeArray(T/*, int dims = 1*/) {

  private static class Data {

    SAFEARRAY* ptr;

    this(SAFEARRAY* ptr) {
      this.ptr = ptr;
    }

    ~this() {
      if (ptr != null) {
        SafeArrayDestroy(ptr);
        ptr = null;
      }
    }

  }

  private Data data_;

  public static SafeArray opCall(int length) {
    SAFEARRAYBOUND[1] bound;
    bound[0] = SAFEARRAYBOUND(length, 0);

    SAFEARRAY* psa = SafeArrayCreate(VARTYPE.VT_VARIANT, 1, bound.ptr);

    SafeArray arr;
    arr.data_ = new SafeArray.Data(psa);
    return arr;
  }

  public static SafeArray opCall(T[] array) {
    SAFEARRAYBOUND[1] bound;
    bound[0] = SAFEARRAYBOUND(array.length, 0);

    SAFEARRAY* psa = SafeArrayCreate(VARTYPE.VT_VARIANT, 1, bound.ptr);

    SafeArray arr;
    arr.data_ = new SafeArray.Data(psa);

    foreach (index, value; array) {
      arr.set(value, index);
    }

    return arr;
  }

  public int lowerBound(int dimension) {
    int lb;
    SafeArrayGetLBound(ptr, dimension + 1, lb);
    return lb;
  }

  public int upperBound(int dimension) {
    int ub;
    SafeArrayGetUBound(ptr, dimension + 1, ub);
    return ub;
  }

  public void resize(int newSize) {
    SAFEARRAYBOUND[1] bound;
    bound[0] = SAFEARRAYBOUND(newSize, 0);
    SafeArrayRedim(ptr, bound.ptr);
  }

  public T get(int index) {
    VARIANT v;
    SafeArrayGetElement(ptr, &index, &v);
    return v.get!(T);
  }

  public void set(T value, int index) {
    SafeArrayPutElement(ptr, &index, &VARIANT(value));
  }

  public T opIndex(int index) {
    return get(index);
  }

  public void opIndexAssign(T value, int index) {
    set(value, index);
  }

  public int opApply(int delegate(ref T) action) {
    int result = 0;
    for (int i = 0; i < length; i++) {
      T value = get(i);
      if ((result = action(value)) != 0)
        break;
    }
    return result;
  }

  public int opApply(int delegate(ref int, ref T) action) {
    int result = 0;
    for (int i = 0; i < length; i++) {
      T value = get(i);
      if ((result = action(i, value)) != 0)
        break;
    }
    return result;
  }

  public int length() {
    return upperBound(0) - lowerBound(0) + 1;
  }

  public SAFEARRAY* ptr() {
    if (data_ !is null)
      return data_.ptr;
    return null;
  }    

}

public bool tryRelease(IUnknown obj) {
  if (obj !is null) {
    try {
      obj.Release();
    }
    catch {
      return false;
    }
    return true;
  }
  return false;
}

public void finalRelease(IUnknown obj) {
  if (obj !is null) {
    while (obj.Release() > 0) {
    }
  }
}

public Exception getExceptionForHR(int hr) {
  if (hr < S_OK) {
    switch (hr) {
      case E_NOTIMPL:
        return new NotImplementedException;
      case E_NOINTERFACE:
        return new InvalidCastException;
      case E_POINTER:
        return new NullReferenceException;
      case E_ACCESSDENIED:
        return new UnauthorizedAccessException;
      case E_OUTOFMEMORY:
        return new OutOfMemoryException;
      case E_INVALIDARG:
        return new ArgumentException;
      default:
    }
    return new COMException(hr);
  }
  return null;
}

public class COMStream : Implements!(IStream) {

  private Stream stream_;

  public this(Stream stream) {
    if (stream is null)
      throw new ArgumentNullException("stream");
    stream_ = stream;
  }

  int Read(void* buffer, uint size, ref uint result) {
    uint ret = stream_.readBlock(buffer, size);
    if (&result)
      result = ret;
    return S_OK;
  }

  int Write(void* buffer, uint size, ref uint result) {
    uint ret = stream_.writeBlock(buffer, size);
    if (&result)
      result = ret;
    return S_OK;
  }

  int Seek(long offset, uint origin, ref ulong result) {
    SeekPos whence;
    if (origin == STREAM_SEEK.STREAM_SEEK_SET)
      whence = SeekPos.Set;
    else if (origin == STREAM_SEEK.STREAM_SEEK_CUR)
      whence = SeekPos.Current;
    else if (origin == STREAM_SEEK.STREAM_SEEK_END)
      whence = SeekPos.End;
    else
      throw new ArgumentOutOfRangeException("origin");

    ulong ret = stream_.seek(offset, whence);
    if (&result)
      result = ret;
    return S_OK;
  }

  int SetSize(ulong value) {
    return E_NOTIMPL;
  }

  int CopyTo(IStream stream, ulong size, ref ulong read, ref ulong written) {
    read = 0;
    written = 0;
    return E_NOTIMPL;
  }

  int Commit(uint flags) {
    return E_NOTIMPL;
  }

  int Revert() {
    return E_NOTIMPL;
  }

  int LockRegion(ulong offset, ulong size, uint lockType) {
    return E_NOTIMPL;
  }

  int UnlockRegion(ulong offset, ulong size, uint lockType) {
    return E_NOTIMPL;
  }

  int Stat(out STATSTG statstg, uint flag) {
    STATSTG stats;
    stats.type = STGTY.STGTY_STREAM;
    stats.cbSize = stream_.size;
    statstg = stats;
    return S_OK;
  }

  int Clone(out IStream result) {
    result = null;
    return E_NOTIMPL;
  }

}