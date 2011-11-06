/**
 * Provides support for COM (Component Object Model).
 *
 * Copyright: (c) 2008 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.com.core;

private import juno.base.core,
  juno.base.native,
  std.stdarg,
  std.string,
  std.utf,
  std.stream;

private import bstr = juno.com.bstr;

private import std.algorithm;
private import std.array;
private import std.traits;
private import std.typetuple : IndexOf, NoDuplicates, TypeTuple, MostDerived;
private import core.exception;
private static import core.memory, std.c.stdlib;

debug private import std.stdio;

pragma(lib, "ole32.lib");
pragma(lib, "oleaut32.lib");

static this() {
  startupCOM();
}

static ~this() {
  shutdownCOM();
}

/*//////////////////////////////////////////////////////////////////////////////////////////
// Structs, Enums                                                                         //
//////////////////////////////////////////////////////////////////////////////////////////*/

enum /* HRESULT */ {
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

/**
 * Determines whether the operation was successful.
 */
bool SUCCEEDED(int hr) {
  return hr >= 0;
}

/**
 * Determines whether the operation was unsuccessful.
 */
bool FAILED(int hr) {
  return hr < 0;
}

/**
 * Represents a globally unique identifier.
 */
struct GUID {

  // Slightly different layout from the Windows SDK, but means we can use fewer brackets
  // when defining GUIDs.
  uint a;
  ushort b, c;
  ubyte d, e, f, g, h, i, j, k;

  /**
   * A GUID whose value is all zeros.
   */
  static GUID empty = { 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0 };

  /**
   * Initializes _a new instance using the specified integers and bytes.
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
  static GUID opCall(uint a, ushort b, ushort c, ubyte d, ubyte e, ubyte f, ubyte g, ubyte h, ubyte i, ubyte j, ubyte k) {
    GUID self;
    self.a = a, self.b = b, self.c = c, self.d = d, self.e = e, self.f = f, self.g = g, self.h = h, self.i = i, self.j = j, self.k = k;
    return self;
  }

  /**
   * Initializes _a new instance using the specified integers and byte array.
   * Params:
   *   a = The first 4 bytes.
   *   b = The next 2 bytes.
   *   c = The next 2 bytes.
   *   d = The remaining 8 bytes.
   * Returns: The resulting GUID.
   * Throws: IllegalArgumentException if d is not 8 bytes long.
   */
  static GUID opCall(uint a, ushort b, ushort c, ubyte[] d) {
    if (d.length != 8)
      throw new ArgumentException("Byte array for GUID must be 8 bytes long.");

    GUID self;
    self.a = a, self.b = b, self.c = c, self.d = d[0], self.e = d[1], self.f = d[2], self.g = d[3], self.h = d[4], self.i = d[5], self.j = d[6], self.k = d[7];
    return self;
  }

  /**
   * Initializes a new instance using the value represented by the specified string.
   * Params: s = A string containing a GUID in groups of 8, 4, 4, 4 and 12 digits with hyphens between the groups. The GUID can optionally be enclosed in braces.
   * Returns: The resulting GUID.
   */
  static GUID opCall(string s) {

    ulong parse(string s) {

      bool hexToInt(char c, out uint result) {
        if (c >= '0' && c <= '9') result = c - '0';
        else if (c >= 'A' && c <= 'F') result = c - 'A' + 10;
        else if (c >= 'a' && c <= 'f') result = c - 'a' + 10;
        else result = -1;
        return (cast(int)result >= 0);
      }

      ulong result;
      uint value, index;
      while (index < s.length && hexToInt(s[index], value)) {
        result = result * 16 + value;
        index++;
      }
      return result;
    }

    s = s.strip();

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

    if (s.find('-').empty)
      throw new FormatException("Unrecognised GUID format.");

    GUID self;
    self.a = cast(uint)parse(s[0 .. 8]);
    self.b = cast(ushort)parse(s[9 .. 13]);
    self.c = cast(ushort)parse(s[14 .. 18]);
    uint m = cast(uint)parse(s[19 .. 23]);
    self.d = cast(ubyte)(m >> 8);
    self.e = cast(ubyte)m;
    ulong n = parse(s[24 .. $]);
    m = cast(uint)(n >> 32);
    self.f = cast(ubyte)(m >> 8);
    self.g = cast(ubyte)m;
    m = cast(uint)n;
    self.h = cast(ubyte)(m >> 24);
    self.i = cast(ubyte)(m >> 16);
    self.j = cast(ubyte)(m >> 8);
    self.k = cast(ubyte)m;
    return self;
  }

  /**
   * Initializes a new instance of the GUID struct.
   */
  static GUID create() {
    GUID self;

    int hr = CoCreateGuid(self);
    if (FAILED(hr))
      throw exceptionForHR(hr);

    return self;
  }

  /**
   * Returns a value indicating whether two instances represent the same value.
   * Params: other = A GUID to compare to this instance.
   * Returns: true if other is equal to this instance; otherwise, false.
   */
  bool opEquals(GUID other) {
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
   * Compares this instance to a specified GUID and returns an indication of their relative values.
   * Params: other = A GUID to compare to this instance.
   * Returns: A number indicating the relative values of this instance and other.
   */
  int opCmp(GUID other) {
    if (a != other.a)
      return (a < other.a) ? -1 : 1;
    if (b != other.b)
      return (b < other.b) ? -1 : 1;
    if (c != other.c)
      return (c < other.c) ? -1 : 1;
    if (d != other.d)
      return (d < other.d) ? -1 : 1;
    if (e != other.e)
      return (e < other.e) ? -1 : 1;
    if (f != other.f)
      return (f < other.f) ? -1 : 1;
    if (g != other.g)
      return (g < other.g) ? -1 : 1;
    if (h != other.h)
      return (h < other.h) ? -1 : 1;
    if (i != other.i)
      return (i < other.i) ? -1 : 1;
    if (j != other.j)
      return (j < other.j) ? -1 : 1;
    if (k != other.k)
      return (k < other.k) ? -1 : 1;
    return 0;
  }

  /**
   * Returns a string representation of the value of this instance in registry format.
   * Returns: A string formatted in this pattern: {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx} where the GUID is represented as a series of lowercase hexadecimal digits in groups of 8, 4, 4, 4 and 12 and separated by hyphens.
   */
  string toString(string format = "D") {

    void hexToString(ref char[] s, ref uint index, uint a, uint b) {

      char hexToChar(uint a) {
        a = a & 0x0F;
        return cast(char)((a > 9) ? a - 10 + 0x61 : a + 0x30);
      }

      s[index++] = hexToChar(a >> 4);
      s[index++] = hexToChar(a);
      s[index++] = hexToChar(b >> 4);
      s[index++] = hexToChar(b);
    }

    char[] s;
    uint index = 0;
    if (format == "D" || format == "d")
      s = new char[36];
    else if (format == "P" || format == "p") {
      s = new char[38];
      s[index++] = '{';
      s[$ - 1] = '}';
    }

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

    return cast(string)s;
  }

  /**
   * Retrieves the hash code for this instance.
   * Returns: The hash code for this instance.
   */
  hash_t toHash() {
    return a ^ ((b >> 16) | c) ^ ((f << 24) | k);
  }

}

/**
 * Associates a GUID with an interface.
 * Params: g = A string representing the GUID in normal registry format with or without the { } delimiters.
 * Examples:
 * ---
 * interface IXMLDOMDocument2 : IDispatch {
 *   mixin(uuid("2933bf95-7b36-11d2-b20e-00c04f983e60"));
 * }
 *
 * // Expands to the following code:
 * //
 * // interface IXMLDOMDocument2 : IDispatch {
 * //   static GUID IID = { 0x2933bf95, 0x7b36, 0x11d2, 0xb2, 0x0e, 0x00, 0xc0, 0x4f, 0x98, 0x3e, 0x60 };
 * // }
 * ---
 */
string uuid(string g) {
  if (g.length == 38) {
    assert(g[0] == '{' && g[$-1] == '}', "Incorrect format for GUID.");
    return uuid(g[1..$-1]);
  }
  else if (g.length == 36) {
    assert(g[8] == '-' && g[13] == '-' && g[18] == '-' && g[23] == '-', "Incorrect format for GUID.");
    return "static const GUID IID = { 0x" ~ g[0..8] ~ ",0x" ~ g[9..13] ~ ",0x" ~ g[14..18] ~ ",0x" ~ g[19..21] ~ ",0x" ~ g[21..23] ~ ",0x" ~ g[24..26] ~ ",0x" ~ g[26..28] ~ ",0x" ~ g[28..30] ~ ",0x" ~ g[30..32] ~ ",0x" ~ g[32..34] ~ ",0x" ~ g[34..36] ~ " };";
  }
  else assert(false, "Incorrect format for GUID.");
}

string uuid(string type, string g) {
  // Alternative form for module-level (global) declarations, eg: 
  //   mixin(uuid("IUnknown", "00000000-0000-0000-c000-000000000046"));
  // produces:
  //   GUID IID_IUnknown = { ... };
  //   template uuidof(T : IUnknown) { const GUID uuidof = IID_IUnknown; }

  if (g.length == 38) {
    assert(g[0] == '{' && g[$-1] == '}', "Incorrect format for GUID.");
    return uuid(type, g[1..$-1]);
  }
  else if (g.length == 36) {
    assert(g[8] == '-' && g[13] == '-' && g[18] == '-' && g[23] == '-', "Incorrect format for GUID.");
    return "const GUID IID_" ~ type ~ " = { 0x" ~ g[0..8] ~ ",0x" ~ g[9..13] ~ ",0x" ~ g[14..18] ~ ",0x" ~ g[19..21] ~ ",0x" ~ g[21..23] ~ ",0x" ~ g[24..26] ~ ",0x" ~ g[26..28] ~ ",0x" ~ g[28..30] ~ ",0x" ~ g[30..32] ~ ",0x" ~ g[32..34] ~ ",0x" ~ g[34..36] ~ " };\n" ~
      "template uuidof(T : " ~ type ~ ") { const GUID uuidof = IID_" ~ type ~ "; }";
  }
  else assert(false, "Incorrect format for GUID.");
}

/**
 * Retrieves the GUID associated with the specified variable or type.
 * Examples:
 * ---
 * import juno.com.core, 
 *   std.stdio;
 *
 * void main() {
 *   writefln("The GUID of IXMLDOMDocument2 is %s", uuidof!(IXMLDOMDocument2));
 * }
 *
 * // Produces:
 * // The GUID of IXMLDOMDocument2 is {2933bf95-7b36-11d2-b20e-00c04f983e60}
 * ---
 */
template uuidof(alias T) {
  const GUID uuidof = uuidofT!(typeof(T));
}

/**
 * ditto
 */
template uuidof(T) {
  const GUID uuidof = uuidofT!(T);
}

template uuidofT(T : T) {
  static if (is(typeof(mixin("IID_" ~ T.stringof))))
    const GUID uuidofT = mixin("IID_" ~ T.stringof); // e.g., IID_IShellFolder
  else static if (is(typeof(mixin("CLSID_" ~ T.stringof))))
    const GUID uuidofT = mixin("CLSID_" ~ T.stringof); // e.g., CLSID_Shell
  else static if (is(typeof(T.IID)))
    const GUID uuidofT = T.IID;
  else
    static assert(false, "No GUID has been associated with '" ~ T.stringof ~ "'.");
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

struct SAFEARRAYBOUND {
  uint cElements;
  int lLbound;
}

struct SAFEARRAY {

  ushort cDims;
  ushort fFeatures;
  uint cbElements;
  uint cLocks;
  void* pvData;
  SAFEARRAYBOUND[1] rgsabound;

  static SAFEARRAY* opCall(T...)(T values) {
    static if (T.length == 1 && isArray!(T)) {
      return fromArray(values, false);
    }
    else {
      auto bound = SAFEARRAYBOUND(values.length);
      auto sa = SafeArrayCreate(VT_VARIANT, 1, &bound);

      VARIANT* data;
      SafeArrayAccessData(sa, outval(data));
      foreach (i, value; values)
        data[i] = VARIANT(value);
      SafeArrayUnaccessData(sa);

      return sa;
    }
  }

  static SAFEARRAY* fromArray(T)(T[] array, bool wrap = false) {
    VARTYPE vt;
    if (wrap) vt = VT_VARIANT;
    else      vt = VariantType!(T);

    auto bound = SAFEARRAYBOUND(array.length);
    auto sa = SafeArrayCreate(vt, 1, &bound);

    if (wrap) {
      VARIANT* data;
      SafeArrayAccessData(sa, outval(data));
      for (int i = 0; i < array.length; i++) {
        data[i] = VARIANT(array[i]);
      }
      SafeArrayUnaccessData(sa);
    }
    else {
      // Strings are stored as BSTRs
      static if (is(T : string))  alias wchar* Type;
      else                        alias T Type;

      Type* data;
      SafeArrayAccessData(sa, outval(data));
      for (int i = 0; i < array.length; i++) {
        static if (is(T : string))  data[i] = bstr.fromString(array[i]);
        else                        data[i] = array[i];
      }
      SafeArrayUnaccessData(sa);
    }

    return sa;
  }

  void destroy() {
    SafeArrayDestroy(&this);
  }

  void resize(int newSize) {
    auto bound = SAFEARRAYBOUND(newSize);
    SafeArrayRedim(&this, &bound);
  }

  T[] toArray(T)() {
    int upperBound, lowerBound;
    SafeArrayGetUBound(this, 1, upperBound);
    SafeArrayGetLBound(this, 1, lowerBound);
    int count = upperBound - lowerBound + 1;

    if (count == 0) return null;

    T[] result = new T[count];

    if ((fFeatures & FADF_VARIANT) != 0) {
      VARIANT* data;
      SafeArrayAccessData(this, outval(data));
      for (int i = lowerBound; i <= upperBound; i++) {
        static if (is(T == VARIANT)) result[i] = data[i];
        else {
          auto val = data[i];
          if (val.vt != VariantType!(T))
            val = val.changeTo(VariantType!(T));
          result[i] = val.value!(T);
        }
      }
      SafeArrayUnaccessData(this);
    }
    else {
      static if (is(T : string))  alias wchar* Type;
      else                        alias T Type;

      Type* data;
      SafeArrayAccessData(this, outval(data));
      for (int i = lowerBound; i <= upperBound; i++) {
        static if (is(T : string))
          result[i] = bstr.toString(data[i]);
        else
          result[i] = data[i];
      }
      SafeArrayUnaccessData(this);
    }

    return result;
  }

  void lock() {
    SafeArrayLock(&this);
  }

  void unlock() {
    SafeArrayUnlock(&this);
  }

  int length() {
    int upperBound, lowerBound;
    SafeArrayGetUBound(&this, 1, upperBound);
    SafeArrayGetLBound(&this, 1, lowerBound);
    return upperBound - lowerBound + 1;
  }

}

deprecated SAFEARRAY* toSafeArray(T)(T[] array) {
  return SAFEARRAY.fromArray(array, true);
}

deprecated T[] toArray(T)(SAFEARRAY* safeArray) {
  return safeArray.toArray!(T)();
}

const ubyte DECIMAL_NEG = 0x80;

struct DECIMAL {

  ushort wReserved;
  ubyte scale;
  ubyte sign;
  uint Hi32;
  uint Lo32;
  uint Mid32;

  static DECIMAL min = { 0, 0, DECIMAL_NEG, uint.max, uint.max, uint.max };
  static DECIMAL max = { 0, 0, 0, uint.max, uint.max, uint.max };
  static DECIMAL minusOne = { 0, 0, DECIMAL_NEG, 0, 1, 0 };
  static DECIMAL zero = { 0, 0, 0, 0, 0, 0 };
  static DECIMAL one = { 0, 0, 0, 0, 1, 0 };

  static DECIMAL opCall(T)(T value) {
    DECIMAL self;

    static if (is(T == uint)) VarDecFromUI4(value, self);
    else static if (is(T == int)) VarDecFromI4(value, self);
    else static if (is(T == ulong)) VarDecFromUI8(value, self);
    else static if (is(T == long)) VarDecFromI8(value, self);
    else static if (is(T == float)) VarDecFromR4(value, self);
    else static if (is(T == double)) VarDecFromR8(value, self);
    else static assert(false);

    return self;
  }

  static DECIMAL opCall(T = void)(uint lo, uint mid, uint hi, bool isNegative, ubyte scale) {
    DECIMAL self;
    self.Hi32 = hi, self.Mid32 = mid, self.Lo32 = lo, self.scale = scale, self.sign = isNegative ? DECIMAL_NEG : 0;
    return self;
  }

  int opCmp(DECIMAL d) {
    return VarDecCmp(&this, &d) - 1;
  }

  bool opEquals(DECIMAL d) {
    return opCmp(d) == 0;
  }

  DECIMAL opBinary(string op)(const inout DECIMAL d) {
    DECIMAL ret;
    static if(op == "+")
        VarDecAdd(&this, &d, &ret);
    else static if(op == "-")
        VarDecSub(&this, &d, &ret);
    else static if(op == "*")
        VarDecMul(&this, &d, &ret);
    else static if(op == "/")
        VarDecDiv(&this, &d, &ret);
    else static if(op == "%")
        return remainder(this, d);
    return ret;
  }

  DECIMAL opUnary(string op)() {
    DECIMAL ret;
    static if(op == "+")
        return this;
    else static if(op == "-")
        VarDecNeg(this, &ret);
    else static if(op == "--")
        return this = this - cast(DECIMAL)1;
    else static if(op == "++")
        return this = this + cast(DECIMAL)1;
    return ret;
  }

  DECIMAL opOpAssign(string op)(const inout DECIMAL d) {
    mixin("this = this " ~ op ~ "d;");
    return this;
  }

  static DECIMAL abs(DECIMAL d) {
    DECIMAL ret;
    VarDecAbs(&d, &ret);
    return ret;
  }

  static DECIMAL round(DECIMAL d, int decimals = 0) {
    DECIMAL ret;
    VarDecRound(&d, decimals, &ret);
    return ret;
  }

  static DECIMAL floor(DECIMAL d) {
    DECIMAL ret;
    VarDecInt(&d, &ret);
    return ret;
  }

  static DECIMAL truncate(DECIMAL d) {
    DECIMAL ret;
    VarDecFix(&d, &ret);
    return ret;
  }

  static DECIMAL remainder(DECIMAL d1, DECIMAL d2) {
    if (abs(d1) < abs(d2))
      return d1;

    d1 -= d2;

    DECIMAL dr = truncate(d1 / d2);
    DECIMAL mr = dr * d2;
    DECIMAL r = d1 - mr;

    if (d1.sign != r.sign && r != cast(DECIMAL)0)
      r += d2;

    return r;
  }

  static DECIMAL parse(string s) {
    DECIMAL d;
    VarDecFromStr(s.toUTF16z(), 0, 0, d);
    return d;
  }

  hash_t toHash() {
    double d;
    VarR8FromDec(&this, d);
    if (d == 0)
      return 0;
    return (cast(int*)&d)[0] ^ (cast(int*)&d)[1];
  }

  string toString() {
    wchar* str;
    if (VarBstrFromDec(&this, 0, 0, str) != S_OK)
      return null;
    return bstr.toString(str);
  }

}

enum : short {
  VARIANT_TRUE = -1,
  VARIANT_FALSE = 0
} alias short VARIANT_BOOL;

enum : VARIANT_BOOL {
  com_true = VARIANT_TRUE,
  com_false = VARIANT_FALSE
} alias VARIANT_BOOL com_bool;

enum /* VARENUM */ : ushort {
  VT_EMPTY            = 0,
  VT_NULL             = 1,
  VT_I2               = 2,
  VT_I4               = 3,
  VT_R4               = 4,
  VT_R8               = 5,
  VT_CY               = 6,
  VT_DATE             = 7,
  VT_BSTR             = 8,
  VT_DISPATCH         = 9,
  VT_ERROR            = 10,
  VT_BOOL             = 11,
  VT_VARIANT          = 12,
  VT_UNKNOWN          = 13,
  VT_DECIMAL          = 14,
  VT_I1               = 16,
  VT_UI1              = 17,
  VT_UI2              = 18,
  VT_UI4              = 19,
  VT_I8               = 20,
  VT_UI8              = 21,
  VT_INT              = 22,
  VT_UINT             = 23,
  VT_VOID             = 24,
  VT_HRESULT          = 25,
  VT_PTR              = 26,
  VT_SAFEARRAY        = 27,
  VT_CARRAY           = 28,
  VT_USERDEFINED      = 29,
  VT_LPSTR            = 30,
  VT_LPWSTR           = 31,
  VT_RECORD           = 36,
  VT_INT_PTR          = 37,
  VT_UINT_PTR         = 38,
  VT_FILETIME         = 64,
  VT_BLOB             = 65,
  VT_STREAM           = 66,
  VT_STORAGE          = 67,
  VT_STREAMED_OBJECT  = 68,
  VT_STORED_OBJECT    = 69,
  VT_BLOB_OBJECT      = 70,
  VT_CF               = 71,
  VT_CLSID            = 72,
  VT_VERSIONED_STREAM = 73,
  VT_BSTR_BLOB        = 0x0fff,
  VT_VECTOR           = 0x1000,
  VT_ARRAY            = 0x2000,
  VT_BYREF            = 0x4000,
  VT_RESERVED         = 0x8000
} alias ushort VARTYPE;

// From D 2.0
template isStaticArray(T : U[N], U, size_t N) {
  const isStaticArray = true;
}

template isStaticArray(T) {
  const isStaticArray = false;
}

template isDynamicArray(T, U = void) {
  const isDynamicArray = false;
}

template isDynamicArray(T : U[], U) {
  const isDynamicArray = !isStaticArray!(T);
}

template isArray(T) {
  const isArray = isStaticArray!(T) || isDynamicArray!(T);
}

template isPointer(T) {
  const isPointer = is(T : void*);
}

/**
 * Determines the equivalent COM type of a built-in type at compile-time.
 * Examples:
 * ---
 * VARTYPE a = VariantType!(string);          // VT_BSTR
 * VARTYPE b = VariantType!(bool);            // VT_BOOL
 * VARTYPE c = VariantType!(typeof([1,2,3])); // VT_ARRAY | VT_I4
 * ---
 */
template VariantType(T) {
  static if (is(T == VARIANT_BOOL))
    const VariantType = VT_BOOL;
  else static if (is(T == bool))
    const VariantType = VT_BOOL;
  else static if (is(T == char))
    const VariantType = VT_UI1;
  else static if (is(T == ubyte))
    const VariantType = VT_UI1;
  else static if (is(T == byte))
    const VariantType = VT_I1;
  else static if (is(T == ushort))
    const VariantType = VT_UI2;
  else static if (is(T == short))
    const VariantType = VT_I2;
  else static if (is(T == uint))
    const VariantType = VT_UI4;
  else static if (is(T == int))
    const VariantType = VT_I4;
  else static if (is(T == ulong))
    const VariantType = VT_UI8;
  else static if (is(T == long))
    const VariantType = VT_I8;
  else static if (is(T == float))
    const VariantType = VT_R4;
  else static if (is(T == double))
    const VariantType = VT_R8;
  else static if (is(T == DECIMAL))
    const VariantType = VT_DECIMAL;
  else static if (is(T E == enum))
    const VariantType = VariantType!(E);
  else static if (is(T : string))
    const VariantType = VT_BSTR;
  else static if (is(T == wchar*))
    const VariantType = VT_BSTR;
  else static if (is(T == SAFEARRAY*))
    const VariantType = VT_ARRAY;
  else static if (is(T == VARIANT))
    const VariantType = VT_VARIANT;
  else static if (is(T : IDispatch))
    const VariantType = VT_DISPATCH;
  else static if (is(T : IUnknown))
    const VariantType = VT_UNKNOWN;
  else static if (isArray!(T))
    const VariantType = VariantType!(typeof(*T)) | VT_ARRAY;
  else static if (isPointer!(T))
    const VariantType = VariantType!(typeof(*T)) | VT_BYREF;
  else
    const VariantType = VT_VOID;
}

/**
 * A container for many different types.
 */
struct VARIANT {

  union {
    struct {
      /// Describes the type of the instance.
      VARTYPE vt;
      private {
        ushort wReserved1;
        ushort wReserved2;
        ushort wReserved3;
      }
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
        SAFEARRAY** pparray;
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
  static VARIANT opCall(T)(T value, VARTYPE type = VariantType!(T)) {
    static if (is(T E == enum)) {
      return opCall(cast(E)value, type);
    }
    else {
      VARIANT self;
      self = value;
      if (type != self.vt)
        VariantChangeType(&self, &self, VARIANT_ALPHABOOL, type);

      return self;
    }
  }

  void opAssign(T)(T value) {
    if (vt != VT_EMPTY)
      clear();

    static if (is(T == VARIANT_BOOL)) boolVal = value;
    else static if (is(T == bool)) boolVal = value ? VARIANT_TRUE : VARIANT_FALSE;
    else static if (is(T == ubyte)) bVal = value;
    else static if (is(T == byte)) cVal = value;
    else static if (is(T == ushort)) uiVal = value;
    else static if (is(T == short)) iVal = value;
    else static if (is(T == uint)) ulVal = value;
    else static if (is(T == int)) lVal = value;
    else static if (is(T == ulong)) ullVal = value;
    else static if (is(T == long)) llVal = value;
    else static if (is(T == float)) fltVal = value;
    else static if (is(T == double)) dblVal = value;
    else static if (is(T == DECIMAL)) decVal = value;
    else static if (is(T : string)) bstrVal = bstr.fromString(value);
    else static if (is(T : IDispatch)) pdispVal = value, value.AddRef();
    else static if (is(T : IUnknown)) punkVal = value, value.AddRef();
    else static if (is(T : Object)) byref = cast(void*)value;
    else static if (is(T == VARIANT*)) pvarVal = value;
    else static if (is(T == VARIANT)) this = value;
    else static if (is(T == SAFEARRAY*)) parray = value;
    else static if (isArray!(T)) parray = SAFEARRAY.from(value);
    else static assert(false, "'" ~ T.stringof ~ "' is not one of the allowed types.");

    vt = VariantType!(T);

    static if (is(T == SAFEARRAY*)) {
      VARTYPE type;
      SafeArrayGetVartype(value, type);
      vt |= type;
    }
  }

  /**
   * Clears the value of this instance and releases any associated memory.
   * See_Also: $(LINK2 http://msdn2.microsoft.com/en-us/library/ms221165.aspx, VariantClear).
   */
  void clear() {
    if (isCOMAlive && !(vt == VT_NULL || vt == VT_EMPTY))
      VariantClear(&this);
  }

  void copyTo(out VARIANT dest) {
    VariantCopy(&dest, &this);
  }

  VARIANT changeTo(VARTYPE newType) {
    VARIANT ret;
    if (FAILED(VariantChangeType(&ret, &this, VARIANT_ALPHABOOL, newType)))
      throw new InvalidCastException("Invalid cast.");
    return ret;
  }

  /**
   * Converts the value contained in this instance to a string.
   * Returns: A string representation of the value contained in this instance.
   */
  string toString() {
    if (vt == VT_NULL || vt == VT_EMPTY)
      return null;

    if (vt == VT_BSTR)
      return bstr.toString(bstrVal);

    VARIANT temp;
    if (SUCCEEDED(VariantChangeType(&temp, &this, VARIANT_ALPHABOOL | VARIANT_LOCALBOOL, VT_BSTR)))
      return bstr.toString(temp.bstrVal);

    return null;
  }
  
  /**
   * Returns the _value contained in this instance.
   */
  V value(V)() {
    //if (vt != VariantType!(V)) assert(false);

    static if (is(V == bool)) return (boolVal == VARIANT_TRUE) ? true : false;
    else static if (is(V == VARIANT_BOOL)) return boolVal;
    else static if (is(V == ubyte)) return bVal;
    else static if (is(V == byte)) return cVal;
    else static if (is(V == ushort)) return uiVal;
    else static if (is(V == short)) return iVal;
    else static if (is(V == uint)) return ulVal;
    else static if (is(V == int)) return lVal;
    else static if (is(V == ulong)) return ullVal;
    else static if (is(V == long)) return llVal;
    else static if (is(V == float)) return fltVal;
    else static if (is(V == double)) return dblVal;
    else static if (is(V == DECIMAL)) return decVal;
    else static if (is(V : string)) return bstr.toString(bstrVal);
    else static if (is(V : IDispatch)) return cast(V)pdispVal;
    else static if (is(V : IUnknown)) return cast(V)punkVal;
    else static if (is(V : Object)) return cast(V)byref;
    else static if (is(V == VARIANT*)) return pvarVal;
    else static if (is(V == SAFEARRAY*)) return parray;
    else static if (isArray!(V)) return parray.toArray!(typeof(*V))();
    else static assert(false, "'" ~ V.stringof ~ "' is not one of the allowed types.");
  }

}

VARIANT toVariant(T)(T value, bool heapAlloc = false) {
  if (heapAlloc)
    return VARIANT(value);
  else return (new class(value) {
    VARIANT var;
    this(T value) { var = VARIANT(value); }
    ~this() { var.clear(); }
  }).var;
}

/*//////////////////////////////////////////////////////////////////////////////////////////
// Interfaces                                                                             //
//////////////////////////////////////////////////////////////////////////////////////////*/

extern(Windows):

interface IUnknown {
  mixin(uuid("00000000-0000-0000-c000-000000000046"));
  int QueryInterface(ref GUID riid, void** ppvObject);
  uint AddRef();
  uint Release();
}

enum {
  CLASS_E_NOAGGREGATION       = 0x80040110,
  CLASS_E_CLASSNOTAVAILABLE   = 0x80040111
}

enum {
  SELFREG_E_FIRST     = tMAKE_SCODE!(SEVERITY_ERROR, FACILITY_ITF, 0x0200),
  SELFREG_E_LAST      = tMAKE_SCODE!(SEVERITY_ERROR, FACILITY_ITF, 0x020F),
  SELFREG_S_FIRST     = tMAKE_SCODE!(SEVERITY_SUCCESS, FACILITY_ITF, 0x0200),
  SELFREG_S_LAST      = tMAKE_SCODE!(SEVERITY_SUCCESS, FACILITY_ITF, 0x020F),
  SELFREG_E_TYPELIB   = SELFREG_E_FIRST,
  SELFREG_E_CLASS     = SELFREG_E_FIRST + 1
}

interface IClassFactory : IUnknown {
  mixin(uuid("00000001-0000-0000-c000-000000000046"));
  int CreateInstance(IUnknown pUnkOuter, ref GUID riid, void** ppvObject);
  int LockServer(int fLock);
}

interface IMalloc : IUnknown {
  mixin(uuid("00000002-0000-0000-c000-000000000046"));
  void* Alloc(size_t cb);
  void* Realloc(void* pv, size_t cb);
  void Free(void* pv);
  size_t GetSize(void* pv);
  int DidAlloc(void* pv);
  void HeapMinimize();
}

struct COSERVERINFO {
  uint dwReserved1;
  wchar* pwszName;
  COAUTHINFO* pAutInfo;
  uint dwReserved2;
}

interface IMarshal : IUnknown {
  mixin(uuid("00000003-0000-0000-c000-000000000046"));
  int GetUnmarshalClass(ref GUID riid, void* pv, uint dwDestContext, void* pvDestContext, uint mshlflags, out GUID pCid);
  int GetMarshalSizeMax(ref GUID riid, void* pv, uint dwDestContext, void* pvDestContext, uint mshlflags, out uint pSize);
  int MarshalInterface(IStream pStm, ref GUID riid, void* pv, uint dwDestContext, void* pvDestContext, uint mshlflags);
  int UnmarshalInterface(IStream pStm, ref GUID riid, void** ppv);
  int ReleaseMarshalData(IStream pStm);
  int DisconnectObject(uint dwReserved);
}

interface ISequentialStream : IUnknown {
  mixin(uuid("0c733a30-2a1c-11ce-ade5-00aa0044773d"));
  int Read(void* pv, uint cb, ref uint pcbRead);
  int Write(void* pv, uint cb, ref uint pcbWritten);
}

enum : uint {
  STGTY_STORAGE = 1,
  STGTY_STREAM = 2,
  STGTY_LOCKBYTES = 3,
  STGTY_PROPERTY = 4
}

enum : uint {
  STREAM_SEEK_SET,
  STREAM_SEEK_CUR,
  STREAM_SEEK_END
}

enum : uint {
  STATFLAG_DEFAULT,
  STATFLAG_NONAME,
  STATFLAG_NOOPEN
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

interface IStorage : IUnknown {
  mixin(uuid("0000000b-0000-0000-c000-000000000046"));
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

struct STGOPTIONS {
  ushort usVersion;
  ushort reserved;
  uint ulSectorSize;
  wchar* pwcsTemplateFile;
}

enum : uint {
  STGFMT_STORAGE = 0,
  STGFMT_FILE = 3,
  STGFMT_ANY = 4,
  STGFMT_DOCFILE = 5
}

int StgOpenStorage(in wchar* pwcsName, IStorage pstgPriority, uint grfMode, wchar** snbExclude, uint reserved, out IStorage ppstgOpen);
int StgOpenStorageEx(in wchar* pwcsName, uint grfMode, uint stgfmt, uint grfAttrs, STGOPTIONS* pStgOptions, SECURITY_DESCRIPTOR* pSecurityDescriptor, ref GUID riid, void** ppObjectOpen);

interface IStream : ISequentialStream {
  mixin(uuid("0000000c-0000-0000-c000-000000000046"));
  int Seek(long dlibMove, uint dwOrigin, ref ulong plibNewPosition);
  int SetSize(ulong libNewSize);
  int CopyTo(IStream stm, ulong cb, ref ulong pcbRead, ref ulong pcbWritten);
  int Commit(uint hrfCommitFlags);
  int Revert();
  int LockRegion(ulong libOffset, ulong cb, uint dwLockType);
  int UnlockRegion(ulong libOffset, ulong cb, uint dwLockType);
  int Stat(out STATSTG pstatstg, uint grfStatFlag);
  int Clone(out IStream ppstm);
}

interface IEnumSTATSTG : IUnknown {
  mixin(uuid("0000000d-0000-0000-c000-000000000046"));
  int Next(uint celt, STATSTG* rgelt, out uint pceltFetched);
  int Skip(uint celt);
  int Reset();
  int Clone(out IEnumSTATSTG ppenum);
}

enum : uint {
  STGM_DIRECT           = 0x00000000,
  STGM_TRANSACTED       = 0x00010000,
  STGM_SIMPLE           = 0x08000000,
  STGM_READ             = 0x00000000,
  STGM_WRITE            = 0x00000001,
  STGM_READWRITE        = 0x00000002,
  STGM_SHARE_DENY_NONE  = 0x00000040,
  STGM_SHARE_DENY_READ  = 0x00000030,
  STGM_SHARE_DENY_WRITE = 0x00000020,
  STGM_SHARE_EXCLUSIVE  = 0x00000010,
  STGM_CREATE           = 0x00001000
}

enum : uint {
  BIND_MAYBOTHERUSER = 1,
  BIND_JUSTTESTEXISTENCE = 2
}

struct BIND_OPTS {
  uint cbStruct = BIND_OPTS.sizeof;
  uint grfFlags;
  uint grfMode;
  uint dwTickCountDeadline;
}

struct BIND_OPTS2 {
  uint cbStruct = BIND_OPTS2.sizeof;
  uint grfFlags;
  uint grfMode;
  uint dwTickCountDeadline;
  uint dwTrackFlags;
  uint dwClassContext;
  uint locale;
  COSERVERINFO* pServerInfo;
}

interface IBindCtx : IUnknown {
  mixin(uuid("0000000e-0000-0000-c000-000000000046"));
  int RegisterObjectBound(IUnknown punk);
  int RevokeObjectBound(IUnknown punk);
  int ReleaseBoundObjects();
  int SetBindOptions(ref BIND_OPTS pbindopts);
  int GetBindOptions(ref BIND_OPTS pbindopts);
  int GetRunningObjectTable(out IRunningObjectTable pprot);
  int RegisterObjectParam(wchar* pszKey, IUnknown punk);
  int GetObjectParam(wchar* pszKey, out IUnknown ppunk);
  int EnumObjectParam(out IEnumString ppenum);
  int RemoveObjectParam(wchar* pszKey);
}

int CreateBindCtx(uint reserved, out IBindCtx ppbc);

interface IMoniker : IPersistStream {
  mixin(uuid("0000000f-0000-0000-c000-000000000046"));
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

int CreateFileMoniker(in wchar* lpszPathName, out IMoniker ppmk);

interface IRunningObjectTable : IUnknown {
  mixin(uuid("00000010-0000-0000-c000-000000000046"));
  int Register(uint grfFlags, IUnknown punkObject, IMoniker pmkObjectName, out uint pdwRegister);
  int Revoke(uint dwRegister);
  int IsRunning(IMoniker pmkObjectName);
  int GetObject(IMoniker pmkObjectName, out IUnknown ppunkObject);
  int NoteChangeTime(uint dwRegister, ref FILETIME pfiletime);
  int GetTimeOfLastChange(IMoniker pmkObjectName, out FILETIME pfiletime);
  int EnumRunning(out IEnumMoniker ppenumMoniker);
}

interface IRecordInfo : IUnknown {
  mixin(uuid("0000002f-0000-0000-c000-000000000046"));
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
  mixin(uuid("00000100-0000-0000-c000-000000000046"));
  int Next(uint celt, IUnknown* rgelt, out uint pceltFetched);
  int Skip(uint celt);
  int Reset();
  int Clone(out IEnumUnknown ppenum);
}

interface IEnumString : IUnknown {
  mixin(uuid("00000101-0000-0000-c000-000000000046"));
  int Next(uint celt, wchar** rgelt, out uint pceltFetched);
  int Skip(uint celt);
  int Reset();
  int Clone(out IEnumString ppenum);
}

interface IEnumMoniker : IUnknown {
  mixin(uuid("00000102-0000-0000-c000-000000000046"));
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
  mixin(uuid("00000103-0000-0000-c000-000000000046"));
  int Next(uint celt, FORMATETC* rgelt, ref uint pceltFetched);
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
  mixin(uuid("00000104-0000-0000-c000-000000000046"));
  int Next(uint celt, OLEVERB* rgelt, out uint pceltFetched);
  int Skip(uint celt);
  int Reset();
  int Clone(out IEnumOLEVERB ppenum);
}

enum DVASPECT : uint {
  DVASPECT_CONTENT = 1,
  DVASPECT_THUMBNAIL = 2,
  DVASPECT_ICON = 4,
  DVASPECT_DOCPRINT = 8
}

enum TYMED : uint {
  TYMED_NULL = 0,
  TYMED_HGLOBAL = 1,
  TYMED_FILE = 2,
  TYMED_ISTREAM = 4,
  TYMED_ISTORAGE = 8,
  TYMED_GDI = 16,
  TYMED_MFPICT = 32,
  TYMED_ENHMF = 64
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
  mixin(uuid("00000105-0000-0000-c000-000000000046"));
  int Next(uint celt, STATDATA* rgelt, out uint pceltFetched);
  int Skip(uint celt);
  int Reset();
  int Clone(out IEnumSTATDATA ppenum);
}

interface IPersist : IUnknown {
  mixin(uuid("0000010c-0000-0000-c000-000000000046"));
  int GetClassID(out GUID pClassID);
}

interface IPersistStream : IPersist {
  mixin(uuid("00000109-0000-0000-c000-000000000046"));
  int IsDirty();
  int Load(IStream pStm);
  int Save(IStream pStm, int fClearDirty);
  int GetSizeMax(out ulong pcbSize);
}

interface IPersistStreamInit : IPersist {
  mixin(uuid("7FD52380-4E07-101B-AE2D-08002B2EC713"));
  int IsDirty();
  int Load(IStream pStm);
  int Save(IStream pStm, int fClearDirty);
  int GetSizeMax(out ulong pcbSize);
  int InitNew();
}

enum {
  DV_E_FORMATETC = 0x80040064,
  DV_E_DVTARGETDEVICE = 0x80040065,
  DV_E_STGMEDIUM = 0x80040066,
  DV_E_STATDATA = 0x80040067,
  DV_E_LINDEX = 0x80040068,
  DV_E_TYMED = 0x80040069,
  DV_E_CLIPFORMAT = 0x8004006A,
  DV_E_DVASPECT = 0x8004006B
}

interface IDataObject : IUnknown {
  mixin(uuid("0000010e-0000-0000-c000-000000000046"));
  int GetData(ref FORMATETC pformatetcIn, out STGMEDIUM pmedium);
  int GetDataHere(ref FORMATETC pformatetc, ref STGMEDIUM pmedium);
  int QueryGetData(ref FORMATETC pformatetc);
  int GetCanonicalFormatEtc(ref FORMATETC pformatetcIn, out FORMATETC pformatetcOut);
  int SetData(ref FORMATETC pformatetc, ref STGMEDIUM pmedium, int fRelease);
  int EnumFormatEtc(uint dwDirection, out IEnumFORMATETC ppenumFormatEtc);
  int DAdvise(ref FORMATETC pformatetc, uint advf, IAdviseSink pAdvSink, out uint pdwConnection);
  int DUnadvise(uint dwConnection);
  int EnumDAdvise(out IEnumSTATDATA ppenumAdvise);
}

int OleSetClipboard(IDataObject pDataObj);
int OleGetClipboard(out IDataObject ppDataObj);
int OleFlushClipboard();
int OleIsCurrentClipboard(IDataObject pDataObj);

interface IAdviseSink : IUnknown {
  mixin(uuid("0000010f-0000-0000-c000-000000000046"));
  int OnDataChange(ref FORMATETC pFormatetc, ref STGMEDIUM pStgmed);
  int OnViewChange(uint dwAspect, int lindex);
  int OnRename(IMoniker pmk);
  int OnSave();
  int OnClose();
}

interface IDropSource : IUnknown {
  mixin(uuid("00000121-0000-0000-c000-000000000046"));
  int QueryContinueDrag(int fEscapePressed, uint grfKeyState);
  int GiveFeedback(uint dwEffect);
}

enum : uint {
  DROPEFFECT_NONE = 0,
  DROPEFFECT_COPY = 1,
  DROPEFFECT_MOVE = 2,
  DROPEFFECT_LINK = 4,
  DROPEFFECT_SCROLL = 0x80000000
}

interface IDropTarget : IUnknown {
  mixin(uuid("00000122-0000-0000-c000-000000000046"));
  int DragEnter(IDataObject pDataObj, uint grfKeyState, POINT pt, ref uint pdwEffect);
  int DragOver(uint grfKeyState, POINT pt, ref uint pdwEffect);
  int DragLeave();
  int Drop(IDataObject pDataObj, uint grfKeyState, POINT pt, ref uint pdwEffect);
}

enum {
  DRAGDROP_E_NOTREGISTERED = 0x80040100,
  DRAGDROP_E_ALREADYREGISTERED = 0x80040101,
  DRAGDROP_E_INVALIDHWND = 0x80040102
}

int RegisterDragDrop(Handle hwnd, IDropTarget pDropTarget);
int RevokeDragDrop(Handle hwnd);
int DoDragDrop(IDataObject pDataObject, IDropSource pDropSource, uint dwOKEffects, out uint pdwEffect);

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

enum : ushort {
  DISPATCH_METHOD         = 0x1,
  DISPATCH_PROPERTYGET    = 0x2,
  DISPATCH_PROPERTYPUT    = 0x4,
  DISPATCH_PROPERTYPUTREF = 0x8
}

enum {
  DISPID_UNKNOWN     = -1,
  DISPID_VALUE       = 0,
  DISPID_PROPERTYPUT = -3,
  DISPID_NEWENUM     = -4,
  DISPID_EVALUATE    = -5,
  DISPID_CONSTRUCTOR = -6,
  DISPID_DESTRUCTOR  = -7,
  DISPID_COLLECT     = -8
}

enum {
  DISP_E_UNKNOWNINTERFACE = 0x80020001,
  DISP_E_MEMBERNOTFOUND   = 0x80020003,
  DISP_E_PARAMNOTFOUND    = 0x80020004,
  DISP_E_TYPEMISMATCH     = 0x80020005,
  DISP_E_UNKNOWNNAME      = 0x80020006,
  DISP_E_NONAMEDARGS      = 0x80020007,
  DISP_E_BADVARTYPE       = 0x80020008,
  DISP_E_EXCEPTION        = 0x80020009,
  DISP_E_BADPARAMCOUNT    = 0x8002000E
}

interface IDispatch : IUnknown {
  mixin(uuid("00020400-0000-0000-c000-000000000046"));
  int GetTypeInfoCount(out uint pctinfo);
  int GetTypeInfo(uint iTInfo, uint lcid, out ITypeInfo ppTInfo);
  int GetIDsOfNames(ref GUID riid, wchar** rgszNames, uint cNames, uint lcid, int* rgDispId);
  int Invoke(int dispIdMember, ref GUID riid, uint lcid, ushort wFlags, DISPPARAMS* pDispParams, VARIANT* pVarResult, EXCEPINFO* pExcepInfo, uint* puArgError);
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

enum {
  TYPE_E_ELEMENTNOTFOUND      = 0x8002802B
}

interface ITypeInfo : IUnknown {
  mixin(uuid("00020401-0000-0000-c000-000000000046"));
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

interface ITypeLib : IUnknown {
  mixin(uuid("00020402-0000-0000-c000-000000000046"));
  uint GetTypeInfoCount();
  int GetTypeInfo(uint index, out ITypeInfo ppTInfo);
  int GetTypeInfoType(uint index, out TYPEKIND pTKind);
  int GetTypeInfoOfGuid(ref GUID guid, out ITypeInfo ppTInfo);
  int GetLibAttr(out TLIBATTR* ppTLibAttr);
  int GetTypeComp(out ITypeComp ppTComp);
  int GetDocumentation(int index, wchar** pBstrName, wchar** pBstrDocString, uint* pBstrHelpContext, wchar** pBstrHelpFile);
  int IsName(wchar* szNameBuf, uint lHashVal, out bool pfName);
  int FindName(wchar* szNameBuf, uint lHashVal, ITypeInfo* ppTInfo, int* rgMemId, ref ushort pcFound);
  int ReleaseTLibAttr(TLIBATTR* pTLibAttr);
}

interface ITypeComp : IUnknown {
  mixin(uuid("00020403-0000-0000-c000-000000000046"));
  int Bind(wchar* szName, uint lHashVal, ushort wFlags, out ITypeInfo ppTInfo, out DESCKIND pDescKind, out BINDPTR pBindPtr);
  int BindType(wchar* szName, uint lHashVal, out ITypeInfo ppTInfo, out ITypeComp ppTComp);
}

interface ICreateTypeInfo : IUnknown {
  mixin(uuid("00020405-0000-0000-c000-000000000046"));
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

interface ICreateTypeLib : IUnknown {
  mixin(uuid("00020406-0000-0000-c000-000000000046"));
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

interface ICreateTypeInfo2 : ICreateTypeInfo {
  mixin(uuid("0002040e-0000-0000-c000-000000000046"));
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

interface ICreateTypeLib2 : ICreateTypeLib {
  mixin(uuid("0002040f-0000-0000-c000-000000000046"));
  int DeleteTypeInfo(wchar* szName);
  int SetCustData(ref GUID guid, ref VARIANT pVarVal);
  int SetHelpStringContext(uint dwHelpStringContext);
  int SetHelpStringDll(wchar* szFileName);
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

interface ITypeChangeEvents : IUnknown {
  mixin(uuid("00020410-0000-0000-c000-000000000046"));
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
  mixin(uuid("00020411-0000-0000-c000-000000000046"));
  int GetCustData(ref GUID guid, out VARIANT pVarVal);
  int GetLibStatistics(out uint pcUniqueNames, out uint pcchUniqueNames);
  int GetDocumentation2(int index, uint lcid, wchar** pBstrHelpString, uint* pdwHelpContext, wchar** pBstrHelpStringDll);
  int GetAllCustData(out CUSTDATA pCustData);
}

interface ITypeInfo2 : ITypeInfo {
  mixin(uuid("00020412-0000-0000-c000-000000000046"));
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

interface IEnumGUID : IUnknown {
  mixin(uuid("0002E000-0000-0000-c000-000000000046"));
  int Next(uint celt, GUID* rgelt, out uint pceltFetched);
  int Skip(uint celt);
  int Reset();
  int Clone(out IEnumGUID ppenum);
}

struct CATEGORYINFO {
  GUID catid;
  uint lcid;
  wchar[128] szDescription;
}

interface IEnumCATEGORYINFO : IUnknown {
  mixin(uuid("0002E011-0000-0000-c000-000000000046"));
  int Next(uint celt, CATEGORYINFO* rgelt, out uint pceltFetched);
  int Skip(uint celt);
  int Reset();
  int Clone(out IEnumGUID ppenum);
}

interface ICatInformation : IUnknown {
  mixin(uuid("0002E013-0000-0000-c000-000000000046"));
  int EnumCategories(uint lcid, out IEnumCATEGORYINFO ppenumCategoryInfo);
  int GetCategoryDesc(inout GUID rcatid, uint lcid, out wchar* pszDesc);
  int EnumClassesOfCategories(uint cImplemented, GUID* rgcatidImpl, uint cRequired, GUID* rgcatidReq, out IEnumGUID ppenumClsid);
  int IsClassOfCategories(inout GUID rclsid, uint cImplemented, GUID* rgcatidImpl, uint cRequired, GUID* rgcatidReq);
  int EnumImplCategoriesOfClass(inout GUID rclsid, out IEnumGUID ppenumCatid);
  int EnumReqCategoriesOfClass(inout GUID rclsid, out IEnumGUID ppenumCatid);
}

abstract final class StdComponentCategoriesMgr {
  mixin(uuid("0002E005-0000-0000-c000-000000000046"));
  mixin Interfaces!(ICatInformation);
}

interface IConnectionPointContainer : IUnknown {
  mixin(uuid("b196b284-bab4-101a-b69c-00aa00341d07"));
  int EnumConnectionPoints(out IEnumConnectionPoints ppEnum);
  int FindConnectionPoint(ref GUID riid, out IConnectionPoint ppCP);
}

interface IEnumConnectionPoints : IUnknown {
  mixin(uuid("b196b285-bab4-101a-b69c-00aa00341d07"));
  int Next(uint cConnections, IConnectionPoint* ppCP, out uint pcFetched);
  int Skip(uint cConnections);
  int Reset();
  int Clone(out IEnumConnectionPoints ppEnum);
}

interface IConnectionPoint : IUnknown {
  mixin(uuid("b196b286-bab4-101a-b69c-00aa00341d07"));
  int GetConnectionInterface(out GUID pIID);
  int GetConnectionPointContainer(out IConnectionPointContainer ppCPC);
  int Advise(IUnknown pUnkSink, out uint pdwCookie);
  int Unadvise(uint dwCookie);
  int EnumConnections(out IEnumConnections ppEnum);
}

struct CONNECTDATA {
  IUnknown pUnk;
  uint dwCookie;
}

interface IEnumConnections : IUnknown {
  mixin(uuid("b196b287-bab4-101a-b69c-00aa00341d07"));
  int Next(uint cConnections, CONNECTDATA* rgcd, out uint pcFetched);
  int Skip(uint cConnections);
  int Reset();
  int Clone(out IEnumConnections ppEnum);
}

interface IErrorInfo : IUnknown {
  mixin(uuid("1cf2b120-547d-101b-8e65-08002b2bd119"));
  int GetGUID(out GUID pGUID);
  int GetSource(out wchar* pBstrSource);
  int GetDescription(out wchar* pBstrDescription);
  int GetHelpFile(out wchar* pBstrHelpFile);
  int GetHelpContext(out uint pdwHelpContext);
}

int SetErrorInfo(uint dwReserved, IErrorInfo perrinfo);
int GetErrorInfo(uint dwReserved, out IErrorInfo pperrinfo);
int CreateErrorInfo(out IErrorInfo pperrinfo);

interface ISupportErrorInfo : IUnknown {
  mixin(uuid("df0b3d60-548f-101b-8e65-08002b2bd119"));
  int InterfaceSupportsErrorInfo(ref GUID riid);
}

struct LICINFO {
  int cbLicInfo = LICINFO.sizeof;
  int fRuntimeKeyAvail;
  int fLicVerified;
}

interface IClassFactory2 : IClassFactory {
  mixin(uuid("b196b28f-bab4-101a-b69c-00aa00341d07"));
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
  mixin(uuid("BEF6E002-A874-101A-8BBA-00AA00300CAB"));
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
  mixin(uuid("7BF80980-BF32-101A-8BBB-00AA00300CAB"));
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
  mixin(uuid("4EF6100A-AF88-11D0-9846-00C04FC29993"));
}

interface IFontDisp : IDispatch {
  mixin(uuid("BEF6E003-A874-101A-8BBA-00AA00300CAB"));
}

interface IPictureDisp : IDispatch {
  mixin(uuid("7BF80981-BF32-101A-8BBB-00AA00300CAB"));
}

/*//////////////////////////////////////////////////////////////////////////////////////////
// Ole32 API                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////*/

int OleInitialize(void* pvReserved);
void OleUninitialize();

enum : uint {
  COINIT_MULTITHREADED = 0x0,
  COINIT_APARTMENTTHREADED = 0x2,
  COINIT_DISABLE_OLE1DDE = 0x4,
  COINIT_SPEED_OVER_MEMORY = 0x8
}

int CoInitialize(void*);
void CoUninitialize();
int CoInitializeEx(void*, uint dwCoInit);

int CoCreateGuid(out GUID pGuid);

void* CoTaskMemAlloc(size_t cb);
void* CoTaskMemRealloc(void* pv, size_t cb);
void CoTaskMemFree(void* pv);

int CoGetMalloc(uint dwMemContext/* = 1*/, out IMalloc ppMalloc);

enum : uint {
  CLSCTX_INPROC_SERVER = 0x1,
  CLSCTX_INPROC_HANDLER = 0x2,
  CLSCTX_LOCAL_SERVER = 0x4,
  CLSCTX_INPROC_SERVER16 = 0x8,
  CLSCTX_REMOTE_SERVER = 0x10,
  CLSCTX_INPROC_HANDLER16 = 0x20,
  CLSCTX_INPROC = CLSCTX_INPROC_SERVER | CLSCTX_INPROC_HANDLER,
  CLSCTX_SERVER = CLSCTX_INPROC_SERVER | CLSCTX_LOCAL_SERVER | CLSCTX_REMOTE_SERVER,
  CLSCTX_ALL = CLSCTX_INPROC_SERVER | CLSCTX_INPROC_HANDLER | CLSCTX_LOCAL_SERVER | CLSCTX_REMOTE_SERVER
}

int CoCreateInstance(ref GUID rclsid, IUnknown pUnkOuter, uint dwClsContext, ref GUID riid, void** ppv);
int CoGetClassObject(ref GUID rclsid, uint dwClsContext, void* pvReserved, ref GUID riid, void** ppv);

struct MULTI_QI {
  GUID* pIID;
  IUnknown pItf;
  int hr;
}

int CoCreateInstanceEx(ref GUID rclsid, IUnknown pUnkOuter, uint dwClsContext, COSERVERINFO* pServerInfo, uint dwCount, MULTI_QI* pResults);

interface IMultiQI : IUnknown {
  mixin(uuid("00000020-0000-0000-c000-000000000046"));
  int QueryMultipleInterfaces(uint cMQIs, MULTI_QI* pMQIs);
}

enum : uint {
  ACTIVEOBJECT_STRONG,
  ACTIVEOBJECT_WEAK
}

int RegisterActiveObject(IUnknown punk, ref GUID rclsid, uint dwFlags, out uint pdwRegister);
int RevokeActiveObject(uint dwRegister, void* pvReserved);
int GetActiveObject(ref GUID rclsid, void* pvReserved, out IUnknown ppunk);

enum : uint {
  MSHLFLAGS_NORMAL = 0x0,
  MSHLFLAGS_TABLESTRONG = 0x1,
  MSHLFLAGS_TABLEWEAK = 0x2,
  MSHLFLAGS_NOPING = 0x4
}

enum : uint {
  MSHCTX_LOCAL,
  MSHCTX_NOSHAREDMEM,
  MSHCTX_DIFFERENTMACHINE,
  MSHCTX_INPROC,
  MSHCTX_CROSSCTX
}

int CoMarshalInterface(IStream pStm, ref GUID riid, IUnknown pUnk, uint dwDestContext, void* pvDestContext, uint mshlflags);
int CoUnmarshalInterface(IStream pStm, ref GUID riid, void** ppv);

int ProgIDFromCLSID(ref GUID clsid, out wchar* lplpszProgID);
int CLSIDFromProgID(in wchar* lpszProgID, out GUID lpclsid);
int CLSIDFromProgIDEx(in wchar* lpszProgID, out GUID lpclsid);

void VariantInit(VARIANT* pvarg);
int VariantClear(VARIANT* pvarg);
int VariantCopy(VARIANT* pvargDest, in VARIANT* pvargSrc);

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

int VariantChangeType(VARIANT* pvargDest, in VARIANT* pvarSrc, ushort wFlags, ushort vt);
int VariantChangeTypeEx(VARIANT* pvargDest, in VARIANT* pvarSrc, uint lcid, ushort wFlags, ushort vt);

int LoadTypeLib(in wchar* szFile, out ITypeLib pptlib);

enum REGKIND {
  REGKIND_DEFAULT,
  REGKIND_REGISTER,
  REGKIND_NONE
}

int LoadTypeLibEx(in wchar* szFile, REGKIND regkind, out ITypeLib pptlib);
int LoadRegTypeLib(ref GUID rgiud, ushort wVerMajor, ushort wVerMinor, uint lcid, out ITypeLib pptlib);
int QueryPathOfRegTypeLib(ref GUID guid, ushort wVerMajor, ushort wVerMinor, uint lcid, out wchar* lpbstrPathName);
int RegisterTypeLib(ITypeLib ptlib, in wchar* szFullPath, in wchar* szHelpDir);
int UnRegisterTypeLib(ref GUID libID, ushort wVerMajor, ushort wVerMinor, uint lcid, SYSKIND syskind);
int RegisterTypeLibForUser(ITypeLib ptlib, wchar* szFullPath, wchar* szHelpDir);
int UnRegisterTypeLibForUser(ref GUID libID, ushort wVerMajor, ushort wVerMinor, uint lcid, SYSKIND syskind);
int CreateTypeLib(SYSKIND syskind, in wchar* szFile, out ICreateTypeLib ppctlib);
int CreateTypeLib2(SYSKIND syskind, in wchar* szFile, out ICreateTypeLib2 ppctlib);

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

int VarDecFromUI4(uint ulIn, out DECIMAL pdecOut);
int VarDecFromI4(int lIn, out DECIMAL pdecOut);
int VarDecFromUI8(ulong ui64In, out DECIMAL pdecOut);
int VarDecFromI8(long i64In, out DECIMAL pdecOut);
int VarDecFromR4(float dlbIn, out DECIMAL pdecOut);
int VarDecFromR8(double dlbIn, out DECIMAL pdecOut);
int VarDecFromStr(in wchar* StrIn, uint lcid, uint dwFlags, out DECIMAL pdecOut);
int VarBstrFromDec(in DECIMAL* pdecIn, uint lcid, uint dwFlags, out wchar* pbstrOut);
int VarUI4FromDec(in DECIMAL* pdecIn, out uint pulOut);
int VarI4FromDec(in DECIMAL* pdecIn, out int plOut);
int VarUI8FromDec(in DECIMAL* pdecIn, out ulong pui64Out);
int VarI8FromDec(in DECIMAL* pdecIn, out long pi64Out);
int VarR8FromDec(in DECIMAL* pdecIn, out double pdblOut);

int VarDecAdd(DECIMAL* pdecLeft, DECIMAL* pdecRight, DECIMAL* pdecResult);
int VarDecSub(DECIMAL* pdecLeft, DECIMAL* pdecRight, DECIMAL* pdecResult);
int VarDecMul(DECIMAL* pdecLeft, DECIMAL* pdecRight, DECIMAL* pdecResult);
int VarDecDiv(DECIMAL* pdecLeft, DECIMAL* pdecRight, DECIMAL* pdecResult);
int VarDecRound(DECIMAL* pdecIn, int cDecimals, DECIMAL* pdecResult);
int VarDecAbs(DECIMAL* pdecIn, DECIMAL* pdecResult);
int VarDecFix(DECIMAL* pdecIn, DECIMAL* pdecResult);
int VarDecInt(DECIMAL* pdecIn, DECIMAL* pdecResult);
int VarDecNeg(DECIMAL* pdecIn, DECIMAL* pdecResult);
int VarDecCmp(DECIMAL* pdecLeft, DECIMAL* pdecRight);

int CreateStreamOnHGlobal(Handle hGlobal, int fDeleteOnRelease, out IStream ppstm);

struct PICTDESC {
  uint cbSizeofStruct = PICTDESC.sizeof;
  uint picType;
  Handle handle;
}

int OleCreatePictureIndirect(PICTDESC* lpPictDesc, ref GUID riid, int fOwn, void** lplpvObj);
int OleLoadPicture(IStream lpstream, int lSize, int fRunmode, ref GUID riid, void** lplpvObj);

/*//////////////////////////////////////////////////////////////////////////////////////////
// Helpers                                                                                //
//////////////////////////////////////////////////////////////////////////////////////////*/

extern(D):

package bool isCOMAlive;

private void startupCOM() {
  isCOMAlive = SUCCEEDED(CoInitializeEx(null, COINIT_APARTMENTTHREADED));
}

private void shutdownCOM() {
  // Before we shut down COM, give classes a chance to release any COM resources.
  try {
    core.memory.GC.collect();
  }
  finally {
    isCOMAlive = false;
    CoUninitialize();
  }
}

// BSTR
// http://msdn2.microsoft.com/en-us/library/ms221069.aspx

/*wchar* allocBSTR(string s) {
  if (s == null)
    return null;

  return bstr.SysAllocString(s.toUTF16z());
}

void freeBSTR(wchar* s) {
  if (s != null)
    bstr.SysFreeString(s);
}*/

/**
 * Speciifes whether to throw exceptions or return null when COM operations fail.
 */
enum ExceptionPolicy {
  NoThrow, /// Returns null on failure.
  Throw    /// Throws an exception on failure.
}

template com_cast_impl(T, ExceptionPolicy policy) {

  T com_cast_impl(U)(U obj) {
    static if (is(U : IUnknown)) {
      if (obj is null) {
        static if (policy == ExceptionPolicy.Throw)
          throw new ArgumentNullException("obj");
        else
          return null;
      }

      T result;
      if (SUCCEEDED(obj.QueryInterface(uuidof!(T), outval(result))))
        return result;

      static if (policy == ExceptionPolicy.Throw)
        throw new InvalidCastException("Invalid cast from '" ~ U.stringof ~ "' to '" ~ T.stringof ~ "'.");
      else
        return null;
    }
    else static if (is(U == VARIANT)) {
      const type = VariantType!(T);
      static if (type != VT_VOID) {
        VARIANT temp;
        if (VariantChangeType(&temp, &obj, VARIANT_ALPHABOOL, type) == S_OK) {
          with (temp) {
            static if (type == VT_BOOL) {
              static if (is(T == bool)) return (boolVal == VARIANT_TRUE) ? true : false;
              else return boolVal;
            }
            else static if (type == VT_UI1) return bVal;
            else static if (type == VT_I1) return cVal;
            else static if (type == VT_UI2) return uiVal;
            else static if (type == VT_I2) return iVal;
            else static if (type == VT_UI4) return ulVal;
            else static if (type == VT_I4) return lVal;
            else static if (type == VT_UI8) return ullVal;
            else static if (type == VT_I8) return llVal;
            else static if (type == VT_R4) return fltVal;
            else static if (type == VT_R8) return dblVal;
            else static if (type == VT_DECIMAL) return decVal;
            else static if (type == VT_BSTR) {
              static if (is(T : string)) return bstr.toString(bstrVal);
              else return bstrVal;
            }
            else static if (type == VT_UNKNOWN) return com_cast_impl(obj.punkVal);
            else static if (type == VT_DISPATCH) return com_cast_impl(obj.pdispVal);
            else return T.init;
          }
        }
        else static if (policy == ExceptionPolicy.Throw)
          throw new InvalidCastException("Invalid cast from '" ~ U.stringof ~ "' to '" ~ T.stringof ~ "'.");
        else return T.init;
      }
      else static assert(false, "Cannot cast from '" ~ U.stringof ~ "' to '" ~ T.stringof ~ "'.");
    }
    else static assert(false, "Cannot cast from '" ~ U.stringof ~ "' to '" ~ T.stringof ~ "'.");
  }

}

/**
 * Invokes the conversion operation to convert from one COM type to another.
 *
 * If the operand is a VARIANT, this function converts its value to the type represented by $(I T). If the operand is an IUnknown-derived object, this function 
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
  alias com_cast_impl!(T, ExceptionPolicy.NoThrow) com_cast;
}

/**
 */
template safe_com_cast(T) {
  alias com_cast_impl!(T, ExceptionPolicy.Throw) safe_com_cast;
}

/**
 * Indicates the execution contexts in which a COM object is to be run.
 */
enum ExecutionContext : uint {
  InProcessServer = CLSCTX_INPROC_SERVER,   ///
  InProcessHandler = CLSCTX_INPROC_HANDLER, ///
  LocalServer = CLSCTX_LOCAL_SERVER,        ///
  RemoteServer = CLSCTX_REMOTE_SERVER,      ///
  All = CLSCTX_ALL                          ///
}

private void** outval(T)(out T ppv)
in {
  assert(&ppv != null);
}
body {
  return cast(void**)&ppv;
}

IUnknown coCreateInstance(GUID clsid, IUnknown outer, ExecutionContext context, GUID iid) {
  IUnknown ret;
  if (SUCCEEDED(CoCreateInstance(clsid, outer, cast(uint)context, iid, outval(ret))))
    return ret;
  return null;
}

/**
 * Returns a reference to a running object that has been registered with OLE.
 * See_Also: $(LINK2 http://msdn2.microsoft.com/en-us/library/ms221467.aspx, GetActiveObject).
 */
IUnknown getActiveObject(string progId) {
  GUID clsid;
  wchar* str = bstr.fromString(progId);
  CLSIDFromProgID(str, clsid);
  bstr.free(str);

  IUnknown obj = null;
  if (SUCCEEDED(GetActiveObject(clsid, null, obj)))
    return obj;

  return null;
}

///
template coCreate(T, ExceptionPolicy policy = ExceptionPolicy.NoThrow) {

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
  T coCreate(U)(U clsid, ExecutionContext context = ExecutionContext.InProcessServer) {
    GUID guid;
    static if (is(U == GUID))
      guid = clsid;
    else static if (is(U : string)) {
      try {
        guid = GUID(clsid);
      }
      catch (FormatException) {
        int hr = CLSIDFromProgID(clsid.toUTF16z(), guid);
        if (FAILED(hr)) {
          static if (policy == ExceptionPolicy.Throw)
            throw new COMException(hr);
          else
            return null;
        }
      }
    }

    T ret;
    int hr = CoCreateInstance(guid, null, context, uuidof!(T), outval(ret));

    if (FAILED(hr)) {
      static if (policy == ExceptionPolicy.Throw)
        throw new COMException(hr);
      else
        return null;
    }

    return ret;
  }

}

template coCreateEx(T, ExceptionPolicy policy = ExceptionPolicy.NoThrow) {

  T coCreateEx(U)(U clsid, string server, ExecutionContext context = ExecutionContext.InProcessServer) {
    GUID guid;
    static if (is(U == GUID))
      guid = clsid;
    else static if (is(U : string)) {
      try {
        guid = GUID(clsid);
      }
      catch (FormatException) {
        int hr = CLSIDFromProgID(clsid.toUTF16z(), guid);
        if (FAILED(hr)) {
          static if (policy == ExceptionPolicy.Throw)
            throw new COMException(hr);
          else
            return null;
        }
      }
    }

    COSERVERINFO csi;
    csi.pwszName = server.toUTF16z();

    MULTI_QI ret;
    ret.pIID = &uuidof!(T);
    int hr = CoCreateInstanceEx(guid, null, context, &csi, 1, &ret);

    if (FAILED(hr)) {
      static if (policy == ExceptionPolicy.Throw)
        throw new COMException(hr);
      else
        return null;
    }

    return cast(T)ret.pItf;
  }

}

template Interfaces(TList...) {

  deprecated {
    static GUID CLSID(); // Use IID instead.
  }

  static T coCreate(T, ExceptionPolicy policy = ExceptionPolicy.NoThrow)(ExecutionContext context = ExecutionContext.InProcessServer) {
    static if (IndexOf!(T, TList) == -1)
      static assert(false, "'" ~ typeof(this).stringof ~ "' does not support '" ~ T.stringof ~ "'.");
    else
      return .coCreate!(T, policy)(uuidof!(typeof(this)), context);
  }

}

template QueryInterfaceImpl(TList...) {

  int QueryInterface(ref GUID riid, void** ppvObject) {
    if (ppvObject is null)
      return E_POINTER;

    *ppvObject = null;

    if (riid == uuidof!(IUnknown))
      *ppvObject = cast(void*)cast(IUnknown)this;
    else foreach (T; TList) {
      // Search the specified list of types to see if we support the interface we're being asked for.
      if (riid == uuidof!(T)) {
        // This is the one, so we need look no further.
        *ppvObject = cast(void*)cast(T)this;
        break;
      }
    }

    if (*ppvObject is null)
      return E_NOINTERFACE;

    (cast(IUnknown)this).AddRef();
    return S_OK;
  }

}

// DMD prevents destructors from running on COM objects.
private void runFinalizer(Object obj) {
  if (obj) {
    ClassInfo** ci = cast(ClassInfo**)cast(void*)obj;
    if (*ci) {
      if (auto c = **ci) {
        do {
          if (c.destructor) {
            auto finalizer = cast(void function(Object))c.destructor;
            finalizer(obj);
          }
          c = c.base;
        } while (c);
      }
    }
  }
}

// Implements AddRef & Release for IUnknown subclasses.
template ReferenceCountImpl() {

  private int refCount = 1;
  private bool finalized;

  uint AddRef() {
    return InterlockedIncrement(&refCount);
  }

  uint Release() {
    if (InterlockedDecrement(&refCount) == 0) {
      if (!finalized) {
        finalized = true;
        runFinalizer(this); // calls destructor (~this) if implemented.
      }

      core.memory.GC.removeRange(cast(void*)this);
      std.c.stdlib.free(cast(void*)this);
    }
    return refCount;
  }

  extern(D):

  // IUnknown subclasses must manage their memory manually.
  new(size_t sz) {
    void* p = std.c.stdlib.malloc(sz);
    if (p is null)
      throw new OutOfMemoryError;

    core.memory.GC.addRange(p, sz);
    return p;
  }

}

template IUnknownImpl(T...) {

  mixin QueryInterfaceImpl!(T);
  mixin ReferenceCountImpl;

}

template IDispatchImpl(T...) {

  mixin IUnknownImpl!(T);

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
    return E_NOTIMPL;
  }

  int Invoke(int dispIdMember, ref GUID riid, uint lcid, ushort wFlags, DISPPARAMS* pDispParams, VARIANT* pVarResult, EXCEPINFO* pExcepInfo, uint* puArgError) {
    return DISP_E_UNKNOWNNAME;
  }

}

template DerivesFrom(T, TList...) {
  const bool DerivesFrom = is(MostDerived!(T, TList) : T);
}

template AllBaseTypesOfImpl(T...) {
  static if (T.length == 0)
    alias TypeTuple!() AllBaseTypesOfImpl;
  else
    alias TypeTuple!(T[0], 
      AllBaseTypesOfImpl!(BaseTypeTuple!(T[0])), 
        AllBaseTypesOfImpl!(T[1 .. $])) 
    AllBaseTypesOfImpl;
}

template AllBaseTypesOf(T) {
  alias NoDuplicates!(AllBaseTypesOfImpl!(BaseTypeTuple!(T))) AllBaseTypesOf;
}

/**
 * The abstract base class for COM objects that derive from IUnknown or IDispatch.
 *
 * The Implements class provides default implementations of methods required by those interfaces. Therefore, subclasses need only override them when they 
 * specifically need to provide extra functionality. This class also overrides the new operator so that instances are not garbage collected.
 * Examples:
 * ---
 * class MyImpl : Implements!(IUnknown) {
 * }
 * ---
 */
abstract class Implements(T...) : T {

  static if (DerivesFrom!(IDispatch, T))
    mixin IDispatchImpl!(AllBaseTypesOf!(T));
  else
    mixin IUnknownImpl!(AllBaseTypesOf!(T));

}

/**
 * Indicates whether the specified object represents a COM object.
 * Params: obj = The object to check.
 * Returns: true if obj is a COM type; otherwise, false.
 */
bool isCOMObject(Object obj) {
  ClassInfo** ci = cast(ClassInfo**)cast(void*)obj;
  if (*ci !is null) {
    ClassInfo c = **ci;
    if (c !is null)
      return (c.flags & 1) != 0;
  }
  return false;
}

// Deprecate? You should really use the scope(exit) pattern.
void releaseAfter(IUnknown obj, void delegate() block) {
  try {
    block();
  }
  finally {
    if (obj)
      obj.Release();
  }
}

// Deprecate? You should really use the scope(exit) pattern.
void clearAfter(VARIANT var, void delegate() block) {
  try {
    block();
  }
  finally {
    var.clear();
  }
}

void tryRelease(IUnknown obj) {
  if (obj) {
    try {
      obj.Release();
    }
    catch {
    }
  }
}

void finalRelease(IUnknown obj) {
  if (obj) {
    while (obj.Release() > 0) {
    }
  }
}

/+version (D_Version2) {

/**
 * Wraps a COM interface in a smart pointer.
 */
struct com_ptr(T) {

  private T ptr_;

  this(this) {
    addRef();
  }

  ~this() {
    release();
  }

  static com_ptr opCall(GUID clsid) {
    com_ptr self;
    self.ptr_ = coCreate!(T)(clsid);
    return self;
  }

  static com_ptr opCall(string progId) {
    com_ptr self;
    //self.ptr_ = coCreate!(T)(progId);
    return self;
  }

  static com_ptr opCall(T ptr) {
    com_ptr self;
    self.ptr_ = ptr;
    return self;
  }

  com_ptr* opAssign(ref com_ptr other) {
    ptr_ = other.ptr_;
    addRef();
    return this;
  }

  com_ptr* opAssign(T ptr) {
    ptr_ = ptr;
    addRef();
    return this;
  }

  void addRef() {
    if (ptr_ !is null)
      ptr_.AddRef();
  }

  void release() {
    if (ptr_ !is null) {
      ptr_.Release();
      ptr_ = null;
    }
  }

  T ptr() {
    return ptr_;
  }

  bool opEquals(void*) {
    return ptr_ is null;
  }

}

}+/

/**
 * The exception thrown when an unrecognized HRESULT is returned from a COM operation.
 */
class COMException : Exception {

  int errorCode_;

  /**
   * Initializes a new instance with a specified error code.
   * Params: errorCode = The error code (HRESULT) value associated with this exception.
   */
  this(int errorCode) {
    super(getErrorMessage(errorCode));
    errorCode_ = errorCode;
  }

  /**
   * Initializes a new instance with a specified message and error code.
   * Params:
   *   message = The error _message that explains this exception.
   *   errorCode = The error code (HRESULT) value associated with this exception.
   */
  this(string message, int errorCode) {
    super(message);
    errorCode_ = errorCode;
  }

  /**
   * Gets the HRESULT of the error.
   * Returns: The HRESULT of the error.
   */
  int errorCode() {
    return errorCode_;
  }

  private static string getErrorMessage(int errorCode) {
    wchar[256] buffer;
    uint result = FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS, null, errorCode, 0, buffer.ptr, buffer.length + 1, null);
    if (result != 0) {
      string s = .toUTF8(buffer[0 .. result]);

      // Remove trailing characters
      while (result > 0) {
        char c = s[result - 1];
        if (c > ' ' && c != '.')
          break;
        result--;
      }

      return format("%s. (Exception from HRESULT: 0x%08X)", s[0 .. result], cast(uint)errorCode);
    }

    return format("Unspecified error (0x%08X)", cast(uint)errorCode);
  }

}

Exception exceptionForHR(int errorCode) {
  switch (errorCode) {
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
  return new COMException(errorCode);
}

void throwExceptionForHR(int errorCode)
in {
  assert(FAILED(errorCode));
}
body {
  if (FAILED(errorCode))
    throw exceptionForHR(errorCode);
}

class COMStream : Implements!(IStream) {

  private Stream stream_;

  this(Stream stream) {
    if (stream is null)
      throw new ArgumentNullException("stream");
    stream_ = stream;
  }

  int Read(void* pv, uint cb, ref uint pcbRead) {
    uint ret = stream_.readBlock(pv, cb);
    if (&pcbRead)
      pcbRead = ret;
    return S_OK;
  }

  int Write(void* pv, uint cb, ref uint pcbWritten) {
    uint ret = stream_.writeBlock(pv, cb);
    if (&pcbWritten)
      pcbWritten = ret;
    return S_OK;
  }

  int Seek(long dlibMove, uint dwOrigin, ref ulong plibNewPosition) {
    SeekPos whence;
    if (dwOrigin == STREAM_SEEK_SET)
      whence = SeekPos.Set;
    else if (dwOrigin == STREAM_SEEK_CUR)
      whence = SeekPos.Current;
    else if (dwOrigin == STREAM_SEEK_END)
      whence = SeekPos.End;

    ulong ret = stream_.seek(dlibMove, whence);
    if (&plibNewPosition)
      plibNewPosition = ret;
    return S_OK;
  }

  int SetSize(ulong libNewSize) {
    return E_NOTIMPL;
  }

  int CopyTo(IStream stream, ulong cb, ref ulong pcbRead, ref ulong pcbWritten) {
    if (&pcbRead)
      pcbRead = 0;
    if (&pcbWritten)
      pcbWritten = 0;
    return E_NOTIMPL;
  }

  int Commit(uint hrfCommitFlags) {
    return E_NOTIMPL;
  }

  int Revert() {
    return E_NOTIMPL;
  }

  int LockRegion(ulong libOffset, ulong cb, uint dwLockType) {
    return E_NOTIMPL;
  }

  int UnlockRegion(ulong libOffset, ulong cb, uint dwLockType) {
    return E_NOTIMPL;
  }

  int Stat(out STATSTG pstatstg, uint grfStatFlag) {
    pstatstg.type = STGTY_STREAM;
    pstatstg.cbSize = stream_.size;
    return S_OK;
  }

  int Clone(out IStream ppstm) {
    ppstm = null;
    return E_NOTIMPL;
  }

}

class StreamFromCOMStream : Stream {

  private IStream stream_;

  this(IStream stream) {
    stream_ = stream;
  }

  ~this() {
    close();
  }

  override void close() {
    if (stream_ !is null) {
      try {
        stream_.Commit(0);
      }
      catch {
      }

      tryRelease(stream_);
      stream_ = null;
    }
  }

  override uint readBlock(void* buffer, size_t size) {
    uint ret;
    stream_.Read(buffer, size, ret);
    return ret;
  }

  override uint writeBlock(void* buffer, size_t size) {
    uint ret;
    stream_.Write(buffer, size, ret);
    return ret;
  }

  override ulong seek(long offset, SeekPos origin) {
    uint dwOrigin;
    if (origin == SeekPos.Set)
      dwOrigin = STREAM_SEEK_SET;
    else if (origin == SeekPos.Current)
      dwOrigin = STREAM_SEEK_CUR;
    else if (origin == SeekPos.End)
      dwOrigin = STREAM_SEEK_END;

    ulong ret;
    stream_.Seek(offset, dwOrigin, ret);
    return ret;
  }

  override void position(ulong value) {
    seek(cast(long)value, SeekPos.Set);
  }

  override ulong position() {
    return seek(0, SeekPos.Current);
  }

  override ulong size() {
    ulong oldPos = position;
    ulong newPos = seek(0, SeekPos.End);
    position = oldPos;
    return newPos - oldPos;
  }

}

enum DispatchFlags : ushort {
  InvokeMethod    = DISPATCH_METHOD,
  GetProperty     = DISPATCH_PROPERTYGET,
  PutProperty     = DISPATCH_PROPERTYPUT,
  PutRefProperty  = DISPATCH_PROPERTYPUTREF
}

class MissingMemberException : Exception {

  this(string message = "Member not found.") {
    super(message);
  }

  this(string className, string memberName) {
    super("Member '" ~ className ~ "." ~ memberName ~ "' not found.");
  }

}

VARIANT invokeMemberById(int dispId, DispatchFlags flags, IDispatch target, VARIANT[] args...) {
  args.reverse;

  DISPPARAMS params;
  if (args.length > 0) {
    params.rgvarg = args.ptr;
    params.cArgs = args.length;

    if (flags & DispatchFlags.PutProperty) {
      int dispIdNamed = DISPID_PROPERTYPUT;
      params.rgdispidNamedArgs = &dispIdNamed;
      params.cNamedArgs = 1;
    }
  }

  VARIANT result;
  EXCEPINFO excep;
  int hr = target.Invoke(dispId, GUID.empty, LOCALE_SYSTEM_DEFAULT, flags, &params, &result, &excep, null);

  for (uint i = 0; i < params.cArgs; i++) {
    params.rgvarg[i].clear();
  }

  if (FAILED(hr)) {
    throw new COMException(bstr.toString(excep.bstrDescription), hr);
  }

  return result;
}

VARIANT invokeMember(string name, DispatchFlags flags, IDispatch target, VARIANT[] args...) {
  int dispId = DISPID_UNKNOWN;
  wchar* bstrName = bstr.fromString(name);
  scope(exit) bstr.free(bstrName);

  if (SUCCEEDED(target.GetIDsOfNames(GUID.empty, &bstrName, 1, LOCALE_SYSTEM_DEFAULT, &dispId)) && dispId != DISPID_UNKNOWN)
    return invokeMemberById(dispId, flags, target, args);

  string typeName;
  ITypeInfo typeInfo;
  if (SUCCEEDED(target.GetTypeInfo(0, 0, typeInfo))) {
    scope(exit) typeInfo.Release();

    wchar* bstrTypeName;
    typeInfo.GetDocumentation(-1, &bstrTypeName, null, null, null);
    typeName = bstr.toString(bstrTypeName);
  }

  throw new MissingMemberException(typeName, name);
}

private VARIANT[] argsToVariants(TypeInfo[] types, va_list argptr) {
  VARIANT[] list;

  foreach (type; types) {
    //debug writefln(type);
    if (type == typeid(bool)) list ~= VARIANT(va_arg!(bool)(argptr));
    else if (type == typeid(ubyte)) list ~= VARIANT(va_arg!(ubyte)(argptr));
    else if (type == typeid(byte)) list ~= VARIANT(va_arg!(byte)(argptr));
    else if (type == typeid(ushort)) list ~= VARIANT(va_arg!(ushort)(argptr));
    else if (type == typeid(short)) list ~= VARIANT(va_arg!(short)(argptr));
    else if (type == typeid(uint)) list ~= VARIANT(va_arg!(uint)(argptr));
    else if (type == typeid(int)) list ~= VARIANT(va_arg!(int)(argptr));
    else if (type == typeid(ulong)) list ~= VARIANT(va_arg!(ulong)(argptr));
    else if (type == typeid(long)) list ~= VARIANT(va_arg!(long)(argptr));
    else if (type == typeid(float)) list ~= VARIANT(va_arg!(float)(argptr));
    else if (type == typeid(double)) list ~= VARIANT(va_arg!(double)(argptr));
    else if (type == typeid(string)) list ~= VARIANT(va_arg!(string)(argptr));
    else if (type == typeid(IDispatch)) list ~= VARIANT(va_arg!(IDispatch)(argptr));
    else if (type == typeid(IUnknown)) list ~= VARIANT(va_arg!(IUnknown)(argptr));
    else if (type == typeid(VARIANT*)) list ~= VARIANT(va_arg!(VARIANT*)(argptr));
    else if (type == typeid(VARIANT)) list ~= va_arg!(VARIANT)(argptr);
  }

  return list;
}

private void fixArgs(ref TypeInfo[] args, ref va_list argptr) {
  if (args[0] == typeid(TypeInfo[]) && args[1] == typeid(va_list)) {
    args = va_arg!(TypeInfo[])(argptr);
    argptr = *cast(va_list*)(argptr);
  }
}

R invokeMethod(R = VARIANT)(IDispatch target, string name, ...) {
  auto args = _arguments;
  auto argptr = _argptr;
  if (args.length == 2) fixArgs(args, argptr);

  VARIANT ret = invokeMember(name, DispatchFlags.InvokeMethod, target, argsToVariants(args, argptr));
  static if (is(R == VARIANT))
    return ret;
  else
    return com_cast!(R)(ret);
}

R getProperty(R = VARIANT)(IDispatch target, string name, ...) {
  auto args = _arguments;
  auto argptr = _argptr;
  if (args.length == 2) fixArgs(args, argptr);

  VARIANT ret = invokeMember(name, DispatchFlags.GetProperty, target, argsToVariants(args, argptr));
  static if (is(R == VARIANT))
    return ret;
  else
    return com_cast!(R)(ret);
}

void setProperty(IDispatch target, string name, ...) {
  auto args = _arguments;
  auto argptr = _argptr;
  if (args.length == 2) fixArgs(args, argptr);

  if (args.length > 1) {
    VARIANT v = invokeMember(name, DispatchFlags.GetProperty, target);
    if (auto indexer = v.pdispVal) {
      scope(exit) indexer.Release();
      v = invokeMemberById(0, DispatchFlags.GetProperty, indexer, argsToVariants(args[0 .. 1], argptr));
      if (auto value = v.pdispVal) {
        scope(exit) value.Release();
        invokeMemberById(0, DispatchFlags.PutProperty, value, argsToVariants(args[1 .. $], argptr + args[0].tsize()));
        return;
      }
    }
  }
  else {
    invokeMember(name, DispatchFlags.PutProperty, target, argsToVariants(args, argptr));
  }
}

deprecated {
  alias bstr.fromString toBStr;
  alias bstr.toString fromBStr;
  alias bstr.free freeBStr;
  // 0.3
  alias bstr.toString BSTRtoUTF8;
  alias bstr.fromString UTF8toBSTR;
}