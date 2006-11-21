/**
 * Provides support for the Component Object Model (COM).
 *
 * To ensure COM objects are freed before COM is shut down, place this file last on your command line.
 */
module juno.com.core;

private import juno.base.core, 
  juno.base.meta, 
  juno.base.string, 
  juno.base.win32;
private static import std.gc, 
  std.c.stdlib, 
  std.typetuple;

pragma(lib, "ole32.lib");
pragma(lib, "oleaut32.lib");

version (Ansi) {
}
else {
  version = Unicode;
}

static this() {
  startupCOM();
}

static ~this() {
  shutdownCOM();
}

enum /*HRESULT*/ {
  S_OK                        = 0x0,
  S_FALSE                     = 0x1,
  E_NOTIMPL                   = 0x80004001,
  E_NOINTERFACE               = 0x80004002,
  E_POINTER                   = 0x80004003,
  E_ABORT                     = 0x80004004,
  E_FAIL                      = 0x80004005,
}

enum {
  TYPE_E_ELEMENTNOTFOUND      = 0x8002802B
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

enum COINIT : uint {
  COINIT_MULTITHREADED      = 0x0,
  COINIT_APARTMENTTHREADED  = 0x2,
  COINIT_DISABLE_OLE1DDE    = 0x4,
  COINIT_SPEED_OVER_MEMORY  = 0x8
}

/**
 * Represents a globally unique identifier.
 */
struct GUID {

  uint a;
  ushort b, c;
  ubyte d, e, f, g, h, i, j, k;

  /**
   * <i>Constructor.</i>
   * Initializes a GUID using the value represented by the specified string.
   * Params: s = A string containing a GUID in the formats dddddddd-dddd-dddd-dddd-dddddddddddd or {dddddddd-dddd-dddd-dddd-dddddddddddd}.
   * Throws: FormatException if the format of s is invalid.
   */
  static GUID opCall(char[] s) {

    ulong parse(char[] s) {

      bool hexToInt(char c, out uint result) {
        if (c >= '0' && c <= '9')
          result = c - '0';
        else if (c >= 'A' && c <= 'F')
          result = c - 'A' + 10;
        else if (c >= 'a' && c <= 'f')
          result = c - 'a' + 10;
        else
          result = -1;
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

    if (s.indexOf('-') < 0)
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

  static GUID opCall(uint a, ushort b, ushort c, ubyte d, ubyte e, ubyte f, ubyte g, ubyte h, ubyte i, ubyte j, ubyte k) {
    GUID ret;
    return ret.a = a, ret.b = b, ret.c = c, ret.d = d, ret.e = e, ret.f = f, ret.g = g, ret.h = h, ret.i = i, ret.j = j, ret.k = k,
      ret;
  }

  /**
   * Initializes a new instance.
   */
  static GUID newGuid() {
    GUID result;
    CoCreateGuid(result);
    return result;
  }

  static GUID fromProgID(char[] progID) {
    GUID result;
    int hr;
    if ((hr = CLSIDFromProgID(progID.toLPStr(), result)) != S_OK)
      throw new COMException(hr);
    return result;
  }

  bool opEquals(GUID other) {
    return a == other.a &&
      b == other.b &&
      c == other.c &&
      d == other.d &&
      e == other.e &&
      f == other.f &&
      g == other.g &&
      h == other.h &&
      i == other.i &&
      j == other.j &&
      k == other.k;
  }

  /**
   * Returns a string representation of the value in the format {dddddddd-dddd-dddd-dddd-dddddddddddd}.
   */
  char[] toString() {

    void hexToString(inout char[] s, inout uint index, uint a, uint b) {

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

  hash_t toHash() {
    return (a ^ ((b << 16) | c)) ^ ((f << 24) | k);
  }

}

struct DECIMAL {

  ushort wReserved;
  union {
    struct {
      ubyte scale;
      ubyte sign;
    }
    ushort signscale;
  }
  uint Hi32;
  union {
    struct {
      uint Lo32;
      uint Mid32;
    }
    ulong Lo64;
  }

}

enum /*VARENUM*/ : ushort {
  VT_EMPTY              = 0,
  VT_NULL               = 1,
  VT_I2                 = 2,
  VT_I4                 = 3,
  VT_R4                 = 4,
  VT_R8                 = 5,
  VT_CY                 = 6,
  VT_DATE               = 7,
  VT_BSTR               = 8,
  VT_DISPATCH           = 9,
  VT_ERROR              = 10,
  VT_BOOL               = 11,
  VT_VARIANT            = 12,
  VT_UNKNOWN            = 13,
  VT_DECIMAL            = 14,
  VT_I1                 = 16,
  VT_UI1                = 17,
  VT_UI2                = 18,
  VT_UI4                = 19,
  VT_I8                 = 20,
  VT_UI8                = 21,
  VT_INT                = 22,
  VT_UINT               = 23,
  VT_VOID               = 24,
  VT_HRESULT            = 25,
  VT_PTR                = 26,
  VT_SAFEARRAY          = 27,
  VT_CARRAY             = 28,
  VT_USERDEFINED        = 29,
  VT_LPSTR              = 30,
  VT_LPWSTR             = 31,
  VT_RECORD             = 36,
  VT_INT_PTR            = 37,
  VT_UINT_PTR           = 38,
  VT_FILETIME           = 64,
  VT_BLOB               = 65,
  VT_STREAM             = 66,
  VT_STORAGE            = 67,
  VT_STREAMED_OBJECT    = 68,
  VT_STORED_OBJECT      = 69,
  VT_BLOB_OBJECT        = 70,
  VT_CF                 = 71,
  VT_CLSID              = 72,
  VT_VERSIONED_STREAM   = 73,
  VT_BSTR_BLOB          = 0xfff,
  VT_VECTOR             = 0x1000,
  VT_ARRAY              = 0x2000,
  VT_BYREF              = 0x4000,
  VT_RESERVED           = 0x8000,
  VT_ILLEGAL            = 0xffff,
  VT_ILLEGALMASKED      = 0xfff,
  VT_TYPEMASK           = 0xfff
}

typedef short VARIANT_BOOL;

enum : VARIANT_BOOL {
  VARIANT_TRUE = -1,
  VARIANT_FALSE = 0
}

typedef short com_bool;

enum : com_bool {
  com_true = -1,
  com_false = 0
}

/**
 * Represents a variable type that can be passed to COM methods.
 */
struct VARIANT {

  union {
    struct {
      ushort vt;
      ushort[3] wReserved;
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
        long* pullVal;
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
   * Initializes the VARIANT with the specified value.
   */
  static VARIANT opCall(bool value) {
    VARIANT v;
    return v.vt = VT_BOOL,
      v.boolVal = cast(VARIANT_BOOL)(value ? VARIANT_TRUE : VARIANT_FALSE),
      v;
  }

  /**
   * Ditto
   */
  static VARIANT opCall(ubyte value) {
    VARIANT v;
    return v.vt = VT_UI1,
      v.bVal = value,
      v;
  }

  /**
   * Ditto
   */
  static VARIANT opCall(byte value) {
    VARIANT v;
    return v.vt = VT_I1,
      v.cVal = value,
      v;
  }

  /**
   * Ditto
   */
  static VARIANT opCall(ushort value) {
    VARIANT v;
    return v.vt = VT_UI2,
      v.uiVal = value,
      v;
  }

  /**
   * Ditto
   */
  static VARIANT opCall(short value) {
    VARIANT v;
    return v.vt = VT_I2,
      v.iVal = value,
      v;
  }

  /**
   * Ditto
   */
  static VARIANT opCall(uint value) {
    VARIANT v;
    return v.vt = VT_UI4,
      v.ulVal = value,
      v;
  }

  /**
   * Ditto
   */
  static VARIANT opCall(int value) {
    VARIANT v;
    return v.vt = VT_I4,
      v.lVal = value,
      v;
  }

  /**
   * Ditto
   */
  static VARIANT opCall(ulong value) {
    VARIANT v;
    return v.vt = VT_UI8,
      v.ullVal = value,
      v;
  }

  /**
   * Ditto
   */
  static VARIANT opCall(long value) {
    VARIANT v;
    return v.vt = VT_I8,
      v.llVal = value,
      v;
  }

  /**
   * Ditto
   */
  static VARIANT opCall(float value) {
    VARIANT v;
    return v.vt = VT_R4,
      v.fltVal = value,
      v;
  }

  /**
   * Ditto
   */
  static VARIANT opCall(double value) {
    VARIANT v;
    return v.vt = VT_R8,
      v.dblVal = value,
      v;
  }

  /**
   * Ditto
   */
  static VARIANT opCall(char[] value) {
    VARIANT v;
    return v.vt = VT_BSTR,
      v.bstrVal = utf8ToBstr(value),
      v;
  }

  /**
   * Ditto
   */
  static VARIANT opCall(DECIMAL value) {
    VARIANT v;
    return v.vt = VT_DECIMAL,
      v.decVal = value,
      v;
  }

  /**
   * Ditto
   */
  static VARIANT opCall(IUnknown value) {
    VARIANT v;
    if (auto disp = com_cast!(IDispatch)(value)) {
      return v.vt = VT_DISPATCH,
        v.pdispVal = disp,
        v;
    }
    else {
      return v.vt = VT_UNKNOWN,
        v.punkVal = value,
        v;
    }
  }

  /**
   * Ditto
   */
  static VARIANT opCall(Object value) {
    VARIANT v;
    return v.vt = VT_BYREF,
      v.byref = value,
      v;
  }

  /**
   * Ditto
   */
  static VARIANT opCall(SAFEARRAY* value) {
    VARIANT v;
    ushort vt;
    SafeArrayGetVartype(value, vt);
    return v.vt = cast(ushort)(VT_ARRAY | vt),
      v.parray = value,
      v;
  }

  /**
   * Releases any resources held by the VARIANT.
   */
  void clear() {
    if (comInitialised) {
      if (vt == VT_ARRAY && parray != null) {
        SafeArrayDestroy(parray);
        parray = null;
      }
      VariantClear(this);
    }
  }

  /**
   * Makes an exact copy of the current instance.
   */
  void copyTo(out VARIANT dest) {
    VariantCopy(&dest, this);
  }

  /**
   * Returns a string representation of the current instance.
   *
   * If the VARIANT is of type VT_BSTR, the value is converted to a UTF-8 string and the BSTR's memory freed. For all other types, the value of the VARIANT is 
   * first converted to a BSTR, then to a UTF-8 string.
   */
  char[] toString() {
    switch (vt) {
      case VT_BOOL:
        return (boolVal == VARIANT_TRUE) ? "True" : "False";
      case VT_BSTR:
        return bstrToUtf8(bstrVal);
      default:
    }

    VARIANT temp;
    if (VariantChangeTypeEx(&temp, this, GetThreadLocale(), 0, VT_BSTR) == S_OK)
      return bstrToUtf8(temp.bstrVal);

    return null;
  }

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
}

enum TYPEKIND {
  TKIND_ENUM,
  TKIND_RECORD,
  TKIND_MODULE,
  TKIND_INTERFACE,
  TKIND_DISPATCH,
  TKIND_COCLASS,
  TKIND_ALIAS,
  TKIND_UNION,
  TKIND_MAX
}

struct TYPEDESC {
  union {
    TYPEDESC* lptdesc;
    ARRAYDESC* lpadesc;
    uint hreftype;
  }
  ushort vt;
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

enum : ushort {
  IDLFLAG_NONE = PARAMFLAG_NONE,
  IDLFLAG_FIN = PARAMFLAG_FIN,
  IDLFLAG_FOUT = PARAMFLAG_FOUT,
  IDLFLAG_FLCID = PARAMFLAG_FLCID,
  IDLFLAG_FRETVAL = PARAMFLAG_FRETVAL
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
  extern (Windows) int function(EXCEPINFO*) pfnDeferredFillIn;
  int scode;
}

enum CALLCONV {
  CC_FASTCALL,
  CC_CDESCL,
  CC_MSCPASCAL,
  CC_PASCAL = CC_MSCPASCAL,
  CC_STDCALL,
  CC_FPFASTCALL,
  CC_SYSCALL,
  CC_MPWCDECL,
  CC_MPWPASCAL,
  CC_MAX
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
  ushort oVft;
  short cScodes;
  ELEMDESC elemdescFunc;
  ushort wFuncFlags;
}

enum VARKIND {
  VAR_PERINSTANCE,
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

struct CUSTDATAITEM {
  GUID guid;
  VARIANT varValue;
}

struct CUSTDATA {
  uint cCustData;
  CUSTDATAITEM* prgCustData;
}

enum DESCKIND {
  DESCKIND_NONE,
  DESCKIND_FUNCDESC,
  DESCKIND_VARDESC,
  DESCKIND_TYPECOMP,
  DESCKIND_IMPLICITAPPOBJ,
  DESCKIND_MAX
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

enum /*LIBFLAGS*/ : ushort {
  LIBFLAG_FRESTRICTED = 0x1, // The type library is restricted, and should not be displayed to users.
  LIBFLAG_FCONTROL = 0x2, // The type library describes controls, and should not be displayed in type browsers intended for nonvisual objects.
  LIBFLAG_FHIDDEN = 0x4, // The type library should not be displayed to users, although its use is not restricted.
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

struct CONNECTDATA {
  IUnknown pUnk;
  uint dwCookie;
}

struct LICINFO {
  int cbLicInfo = LICINFO.sizeof;
  int fRuntimeKeyAvail;
  int fLicVerified;
}

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

enum REGKIND {
  REGKIND_DEFAULT,
  REGKIND_REGISTER,
  REGKIND_NONE
}

extern (Windows):

interface INull {
  static GUID IID = { 0x00000000, 0x0000, 0x0000, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
}

interface IUnknown {
  static GUID IID = { 0x00000000, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int QueryInterface(inout GUID riid, void** ppvObject);
  uint AddRef();
  uint Release();
}

interface IClassFactory : IUnknown {
  static GUID IID = { 0x00000001, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int CreateInstance(IUnknown pUnkOuter, inout GUID riid, void** ppvObject);
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

interface ISequentialStream : IUnknown {
  static GUID IID = { 0x0c733a30, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d };
  int Read(void* pv, uint cb, out uint pcbRead);
  int Write(void* pv, uint cb, out uint pcbWritten);
}

interface IStream : ISequentialStream {
  static GUID IID = { 0x0000000C, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int Seek(long dlibMove, uint dwOrigin, out long plibNewPosition);
  int SetSize(long libNewSize);
  int CopyTo(IStream stm, long cb, out long pcbRead, out long pcbWritten);
  int Commit(uint hrfCommitFlags);
  int Revert();
  int LockRegion(long libOffset, long cb, uint dwLockType);
  int UnlockRegion(long libOffset, long cb, uint dwLockType);
  int Stat(out STATSTG pstatstg, uint gfrStatFlag);
  int Clone(out IStream ppstm);
}

interface ITypeMarshal : IUnknown {
  static GUID IID = { 0x0000002D, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int Size(void* pvType, uint dwDestContext, void* pvDestContext, out uint pSize);
  int Marshal(void* pvType, uint dwDestContext, void* pvDestContext, uint cbBufferLength, ubyte* pBuffer, out uint pcbWritten);
  int Unmarshal(void* pvType, uint dwFlags, uint cbBufferLength, ubyte* pBuffer, out uint pcbRead);
  int Free(void* pvType);
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
  int PutField(uint wFlags, void* pvData, wchar* szFieldName, inout VARIANT pvarField);
  int PutFieldNoCopy(uint wFlags, void* pvData, wchar* szFieldName, inout VARIANT pvarField);
  int GetFieldNames(out uint pcNames, wchar** rgBstrNames);
  bool IsMatchingType(IRecordInfo pRecordInfo);
  void* RecordCreate();
  int RecordCreateCopy(void* pvSource, out void* ppvDest);
  int RecordDestroy(void* pvRecord);
}

interface ITypeFactory : IUnknown {
  static GUID IID = { 0x0000002E, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int CreateFromTypeInfo(ITypeInfo pTypeInfo, inout GUID riid, out IUnknown ppv);
}

interface IPersist : IUnknown {
  static GUID IID = { 0x0000010c, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int GetClassID(out GUID pClassID);
}

interface IEnumUnknown : IUnknown {
  static GUID IID = { 0x00000100, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int Next(uint celt, IUnknown* rgelt, out uint pceltFetched);
  int Skip(uint celt);
  int Reset();
  int Clone(out IEnumUnknown ppEnum);
}

interface IEnumString : IUnknown {
  static GUID IID = { 0x00000101, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int Next(uint celt, wchar** rgelt, out uint pceltFetched);
  int Skip(uint celt);
  int Reset();
  int Clone(out IEnumString ppEnum);
}

interface IDispatch : IUnknown {
  static GUID IID = { 0x00020400, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int GetTypeInfoCount(out uint pctinfo);
  int GetTypeInfo(uint iTInfo, uint lcid, out ITypeInfo ppTInfo);
  int GetIDsOfNames(inout GUID riid, wchar** rgszNames, uint cNames, uint lcid, int* rgDispId);
  int Invoke(int dispIdMember, inout GUID riid, uint lcid, ushort wFlags, DISPPARAMS* pDispParams, VARIANT* pVarResult, EXCEPINFO* pExcepInfo, uint* puArgErr);
}

interface ITypeInfo : IUnknown {
  static GUID IID = { 0x00020401, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int GetTypeAttr(out TYPEATTR* ppTypeAttr);
  int GetTypeComp(out ITypeComp ppTComp);
  int GetFuncDesc(uint index, out FUNCDESC* ppFuncDesc);
  int GetVarDesc(uint index, out VARDESC* ppFuncDesc);
  int GetNames(int memid, wchar** rgBstrNames, uint cMaxNames, out uint pcNames);
  int GetRefTypeOfImplType(uint index, out uint pRefType);
  int GetImplTypeFlags(uint index, out int pImplTypeFlags);
  int GetIDsOfNames(wchar** rgszNames, uint cNames, int* pMemId);
  int Invoke(void* pvInstance, int memid, ushort wFlags, DISPPARAMS* pDispParams, VARIANT* pVarResult, EXCEPINFO* pExcepInfo, uint* puArgErr);
  int GetDocumentation(int memid, wchar** pBstrName, wchar** pBstrDocString, uint* pdwHelpContext, wchar** pBstrHelpFile);
  int GetDllEntry(int memid, INVOKEKIND invKind, wchar** pBstrDllName, wchar** pBstrName, ushort* pwOrdinal);
  int GetRefTypeInfo(uint hRefType, out ITypeInfo ppTInfo);
  int AddressOfMember(int memid, INVOKEKIND invKind, out void* ppv);
  int CreateInstance(IUnknown pUnkOther, inout GUID riid, out void* ppvObj);
  int GetMops(int memid, out wchar* pBstrMops);
  int GetContainingTypeLib(out ITypeLib ppTLib, out uint pIndex);
  int ReleaseTypeAttr(TYPEATTR* pTypeAttr);
  int ReleaseFuncDesc(FUNCDESC* pFuncDesc);
  int ReleaseVarDesc(VARDESC* pVarDesc);
}

interface ITypeLib : IUnknown {
  static GUID IID = { 0x00020402, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  uint GetTypeInfoCount();
  int GetTypeInfo(uint index, out ITypeInfo ppTInfo);
  int GetTypeInfoType(uint index, out TYPEKIND pTKind);
  int GetTypeInfoOfGuid(inout GUID guid, out ITypeInfo ppTInfo);
  int GetLibAttr(out TLIBATTR* ppTLibAttr);
  int GetTypeComp(out ITypeComp ppTComp);
  int GetDocumentation(int index, wchar** pBstrName, wchar** pBstrDocString, uint* pdwHelpContext, wchar** pBstrHelpFile);
  int IsName(wchar* szNameBuf, uint lHashVal, out int pfName);
  int FindName(wchar* szNameBuf, uint lHashVal, ITypeInfo* ppTInfo, int* rgMemId, inout ushort pcFound);
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
  int SetGuid(inout GUID guid);
  int SetTypeFlags(uint uTypeFlags);
  int SetDocString(wchar* szStrDoc);
  int SetHelpContext(uint dwHelpContext);
  int SetVersion(ushort wMajorVerNum, ushort wMinorVerNum);
  int AddRefTypeInfo(ITypeInfo pTInfo, inout uint phRefType);
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
  int SetCustData(inout GUID guid, inout VARIANT pVarVal);
  int SetFuncCustData(uint index, inout GUID guid, inout VARIANT pVarVal);
  int SetParamCustData(uint indexFunc, uint indexParam, inout GUID guid, inout VARIANT pVarVal);
  int SetVarCustData(uint index, inout GUID guid, inout VARIANT pVarVal);
  int SetImplTypeCustData(uint index, inout GUID guid, inout VARIANT pVarVal);
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
  int SetGuid(inout GUID guid);
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
  int SetCustData(inout GUID guid, inout VARIANT pVarVal);
  int SetHelpStringContext(uint dwHelpStringContext);
  int SetHelpStringDll(wchar* szFileName);
}

interface ITypeChangeEvents : IUnknown {
  static GUID IID = { 0x00020410, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int RequestTypeChange(CHANGEKIND changeKind, ITypeInfo pTInfoBefore, wchar* pStrName, out int pfCancel);
  int AfterTypeChange(CHANGEKIND changeKind, ITypeInfo pTInfoAfter, wchar* pStrName);
}

interface ITypeLib2 : ITypeLib {
  static GUID IID = { 0x00020411, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int GetCustData(inout GUID guid, out VARIANT pVarVal);
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
  int GetCustData(inout GUID guid, out VARIANT pVarVal);
  int GetFuncCustData(uint index, inout GUID guid, out VARIANT pVarVal);
  int GetParamCustData(uint indexFunc, uint indexParam, inout GUID guid, out VARIANT pVarVal);
  int GetVarCustData(uint index, inout GUID guid, out VARIANT pVarVal);
  int GetImplTypeCustData(uint index, inout GUID guid, out VARIANT pVarVal);
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
  int RegisterClassImplCategories(inout GUID rclsid, uint cCategories, GUID* rgcatid);
  int UnRegisterClassImplCategories(inout GUID rclsid, uint cCategories, GUID* rgcatid);
  int RegisterClassReqCategories(inout GUID rclsid, uint cCategories, GUID* rgcatid);
  int UnRegisterClassReqCategories(inout GUID rclsid, uint cCategories, GUID* rgcatid);
}

interface IErrorInfo : IUnknown {
  static GUID IID = { 0x1CF2B120, 0x547D, 0x101B, 0x8E, 0x65, 0x08, 0x00, 0x2B, 0x2B, 0xD1, 0x19 };
  int GetGUID(out GUID pGUID);
  int GetSource(out wchar* pBstrSource);
  int GetDescription(out wchar* pBstrDescription);
  int GetHelpFile(out wchar* pBstrHelpFile);
  int GetHelpContext(out uint pdwHelpContext);
}

interface IConnectionPointContainer : IUnknown {
  static GUID IID = { 0xB196B284, 0xBAB4, 0x101A, 0xB6, 0x9C, 0x00, 0xAA, 0x00, 0x34, 0x1D, 0x07 };
  int EnumConnectionPoints(out IEnumConnectionPoints ppEnum);
  int FindConnectionPoint(inout GUID riid, out IConnectionPoint ppCP);
}

interface IEnumConnectionPoints : IUnknown {
  static GUID IID = { 0xB196B285, 0xBAB4, 0x101A, 0xB6, 0x9C, 0x00, 0xAA, 0x00, 0x34, 0x1D, 0x07 };
  int Next(uint cConnections, IConnectionPoint* ppCP, out uint pcFetched);
  int Skip(uint cConnections);
  int Reset();
  int Clone(out IEnumConnectionPoints ppEnum);
}

interface IConnectionPoint : IUnknown {
  static GUID IID = { 0xB196B286, 0xBAB4, 0x101A, 0xB6, 0x9C, 0x00, 0xAA, 0x00, 0x34, 0x1D, 0x07 };
  int GetConnectionInterface(inout GUID pIID);
  int GetConnectionPointContainer(out IConnectionPointContainer ppCPC);
  int Advise(IUnknown pUnkSink, out uint pdwCookie);
  int Unadvise(uint dwCookie);
  int EnumConnections(out IEnumConnections ppEnum);
}

interface IEnumConnections : IUnknown {
  static GUID IID = { 0xB196B287, 0xBAB4, 0x101A, 0xB6, 0x9C, 0x00, 0xAA, 0x00, 0x34, 0x1D, 0x07 };
  int Next(uint cConnections, CONNECTDATA* rgcd, out uint pcFetched);
  int Skip(uint cConnections);
  int Reset();
  int Clone(out IEnumConnections ppEnum);
}

interface IClassFactory2 : IClassFactory {
  static GUID IID = { 0xB196B28F, 0xBAB4, 0x101A, 0xB6, 0x9C, 0x00, 0xAA, 0x00, 0x34, 0x1D, 0x07 };
  int GetLicInfo(out LICINFO pLicInfo);
  int RequestLicKey(uint dwReserved, out wchar* pBstrKey);
  int CreateInstanceLic(IUnknown pUnkOuter, IUnknown pUnkReserved, inout GUID riid, wchar* bstrKey, out void* ppvObj);
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
version (Ansi) {
  ubyte tmFirstChar;
  ubyte tmLastChar;
  ubyte tmDefaultChar;
  ubyte tmBreakChar;
}
else version (Unicode) {
  wchar tmFirstChar;
  wchar tmLastChar;
  wchar tmDefaultChar;
  wchar tmBreakChar;
}
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

int CoInitialize(void* pvReserved);
void CoUninitialize();
int CoInitializeEx(void* pvReserved, uint dwCoInit);

int CoCreateGuid(out GUID pguid);
int CLSIDFromProgID(wchar* lpszProgID, out GUID lpclsid);

int CoCreateInstance(inout GUID rclsid, IUnknown pUnkOuter, uint dwClsContext, inout GUID riid, void** ppv);
int CoCreateInstanceEx(inout GUID Clsid, IUnknown punkOuter, uint dwClsCtx, COSERVERINFO* pServerInfo, uint dwCount, MULTI_QI* pResults);

wchar* SysAllocString(wchar* psz);
wchar* SysAllocStringLen(wchar* psz, uint len);
wchar* SysAllocStringByteLen(wchar* psz, uint len);
int SysReAllocString(wchar** pbstr, wchar* psz);
int SysReAllocStringLen(wchar** pbstr, wchar* psz, uint cch);
void SysFreeString(wchar* bstr);
uint SysStringLen(wchar* bstr);
uint SysStringByteLen(wchar* bstr);

int VariantClear(VARIANT* pvarg);
int VariantCopy(VARIANT* pvargDest, VARIANT* pvargSrc);
int VariantChangeType(VARIANT* pvargDest, VARIANT* pvarSrc, ushort wFlags, ushort vt);
int VariantChangeTypeEx(VARIANT* pvargDest, VARIANT* pvarSrc, uint lcid, ushort wFlags, ushort vt);

int CreateStreamOnHGlobal(Handle hGlobal, int fDeleteOnRelease, out IStream ppstm);
int SHCreateStreamOnFileW(wchar* pszFile, uint grfMode, out IStream ppstm);

int SafeArrayAllocDescriptor(uint cDims, out SAFEARRAY* ppsaOut);
int SafeArrayAllocDescriptorEx(ushort vt, uint cDims, out SAFEARRAY* ppsaOut);
int SafeArrayAllocData(SAFEARRAY* psa);
SAFEARRAY* SafeArrayCreate(ushort vt, uint cDims, SAFEARRAYBOUND* rgsabound);
SAFEARRAY* SafeArrayCreateEx(ushort vt, uint cDims, SAFEARRAYBOUND* rgsabound, void* pvExtra);
int SafeArrayCopyData(SAFEARRAY* psaSource, SAFEARRAY* psaTarget);
int SafeArrayDestroyDescriptor(SAFEARRAY* psa);
int SafeArrayDestroyData(SAFEARRAY* psa);
int SafeArrayDestroy(SAFEARRAY* psa);
int SafeArrayRedim(SAFEARRAY* psa, SAFEARRAYBOUND* psaboundNew);
uint SafeArrayGetDim(SAFEARRAY* psa);
uint SafeArrayGetElemsize(SAFEARRAY* psa);
int SafeArrayGetUBound(SAFEARRAY* psa, uint nDim, out int plUbound);
int SafeArrayGetLBound(SAFEARRAY* psa, uint nDim, out int plLbound);
int SafeArrayLock(SAFEARRAY* psa);
int SafeArrayUnlock(SAFEARRAY* psa);
int SafeArrayAccessData(SAFEARRAY* psa, void** ppvData);
int SafeArrayUnaccessData(SAFEARRAY* psa);
int SafeArrayPutElement(SAFEARRAY* psa, int* rgIndices, void* pv);
int SafeArrayGetElement(SAFEARRAY* psa, int* rgIndices, void* pv);
int SafeArrayCopy(SAFEARRAY* psa, out SAFEARRAY* ppsaOut);
int SafeArrayPtrOfIndex(SAFEARRAY* psa, int* rgIndices, void** ppvData);
int SafeArrayGetVartype(SAFEARRAY* psa, out ushort pvt);
SAFEARRAY* SafeArrayCreateVector(ushort vt, int lLbound, uint cElements);
SAFEARRAY* SafeArrayCreateVectorEx(ushort vt, int lLbound, uint cElements, void* pvExtra);

int VectorFromBstr(wchar* bstr, out SAFEARRAY* ppsa);
int BstrFromVector(SAFEARRAY* psa, out wchar* pbstr);

int VarBstrFromDec(inout DECIMAL pdecIn, uint lcid, uint dwFlags, out wchar* pbstrOut);
int VarI4FromDec(inout DECIMAL pdecIn, out int plOut);
int VarUI4FromDec(inout DECIMAL pdecIn, out uint pulOut);
int VarI8FromDec(inout DECIMAL pdecIn, out long pi64Out);
int VarUI8FromDec(inout DECIMAL pdecIn, out ulong pui64Out);
int VarR4FromDec(inout DECIMAL pdecIn, out float pfltOut);
int VarR8FromDec(inout DECIMAL pdecIn, out double pdblOut);

int VarDecFromStr(wchar* strIn, uint lcid, uint dwFlags, out DECIMAL pdecOut);
int VarDecFromUI4(uint ulIn, out DECIMAL pdecOut);
int VarDecFromI4(int lIn, out DECIMAL pdecOut);
int VarDecFromUI8(ulong ui64In, out DECIMAL pdecOut);
int VarDecFromI8(long i64In, out DECIMAL pdecOut);
int VarDecFromR4(float fltIn, out DECIMAL pdecOut);
int VarDecFromR8(double dblIn, out DECIMAL pdecOut);
int VarDecNeg(inout DECIMAL pdecIn, out DECIMAL pdecResult);
int VarDecAdd(inout DECIMAL pdecLeft, inout DECIMAL pdecRight, out DECIMAL pdecResult);
int VarDecSub(inout DECIMAL pdecLeft, inout DECIMAL pdecRight, out DECIMAL pdecResult);
int VarDecMul(inout DECIMAL pdecLeft, inout DECIMAL pdecRight, out DECIMAL pdecResult);
int VarDecDiv(inout DECIMAL pdecLeft, inout DECIMAL pdecRight, out DECIMAL pdecResult);
int VarDecRound(inout DECIMAL pdecIn, int cDecimals, out DECIMAL pdecResult);
int VarDecCmp(inout DECIMAL pdecLeft, inout DECIMAL pdecRight);
int VarDecFix(inout DECIMAL pdecIn, inout DECIMAL pdecResult);
int VarDecInt(inout DECIMAL pdecIn, inout DECIMAL pdecResult);

void* CoTaskMemAlloc(uint cb);
void* CoTaskMemRealloc(void* pv, uint cb);
void CoTaskMemFree(void* pv);

int CoGetMalloc(uint dwMemContext/* = 1*/, out IMalloc ppMalloc);

int LoadTypeLib(wchar* szFile, out ITypeLib pptlib);
int LoadTypeLibEx(wchar* szFile, REGKIND regkind, out ITypeLib pptlib);
int LoadRegTypeLib(inout GUID rguid, ushort wVerMajor, ushort wVerMajor, uint lcid, out ITypeLib pptlib);
int RegisterTypeLib(ITypeLib ptlib, wchar* szFullPath, char* szHelpPath);
int UnRegisterTypeLib(inout GUID libID, ushort wVerMajor, ushort wVerMinor, uint lcid, SYSKIND syskind);
int CreateTypeLib(SYSKIND syskind, wchar* szFile, out ICreateTypeLib ppctlib);
int CreateTypeLib2(SYSKIND syskind, wchar* szFile, out ICreateTypeLib2 ppctlib);

extern (D):

private bool comInitialised = false;

private void startupCOM() {
  synchronized {
    if (!comInitialised) {
      comInitialised = true;
      // STA because a lot of COM objects aren't happy in MTA.
      CoInitializeEx(null, COINIT.COINIT_APARTMENTTHREADED);
    }
  }
}

private void shutdownCOM() {
  synchronized {
    if (comInitialised) {
      std.gc.fullCollect();

      // Even forcing the GC to do a collection before shutting down COM may leave some objects alive. When the GC next runs
      // we won't be able to call Release on those objects, since COM has already terminated. One solution is to make this 
      // module (juno\com\core.d) the last file on the dmd command line, meaning this module will be the last to have its destructor run.

      CoUninitialize();
      comInitialised = false;
    }
  }
}

/**
 * Determines whether the operation on a COM method succeeded.
 * Returns: true if the operation succeeded; otherwise, false.
 */
public bool SUCCEEDED(int hr) {
  return hr >= S_OK;
}

/**
 * Determines whether the operation on a COM method failed.
 * Returns: true if the operation failed; otherwise, false.
 */
public bool FAILED(int hr) {
  return hr < S_OK;
}

/**
 * The exception thrown when a COM error occurs.
 */
public class COMException : Throwable {

  private int errorCode_;

  /**
   * Creates an instance with the specified error _message.
   */
  public this(char[] message) {
    super(message);
    errorCode_ = E_FAIL;
  }

  /**
   * Creates an instance with the specified _error code (HRESULT). The default is E_FAIL.
   */
  public this(int error = E_FAIL) {
    errorCode_ = E_FAIL;
    super(getErrorMessage(error));
  }

  /**
   * Creates an instance with the specified HRESULT of the _error and the _error _message.
   */
  public this(int error, char[] message) {
    super(message);
    errorCode_ = error;
  }

  /**
   * Retrieves the HRESULT of the error.
   */
  public int errorCode() {
    return errorCode_;
  }

  private static char[] getErrorMessage(int error) {
    wchar[256] buffer;
    uint r = FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS, null, error, 0, buffer, buffer.length + 1, null);
    if (r != 0)
      return buffer.toUtf8(0, r - 1);
    return "Unspecified Error";
  }

}

template QueryInterfaceImpl(T ...) {

  int QueryInterface(inout GUID riid, void** ppvObject) {
    *ppvObject = null;

    if (riid == IUnknown.IID)
      *ppvObject = cast(IUnknown)this;
    else foreach (i,_; T) {
      if (riid == T[i].IID) {
        *ppvObject = cast(T[i])this;
        break;
      }
    }

    if (*ppvObject is null)
      return E_NOINTERFACE;

    (cast(IUnknown)this).AddRef();
    return S_OK;
  }

}

template IUnknownRefImpl() {

  private int ref = 1;
  private bool finalized = false;

  uint AddRef() {
    synchronized {
      return InterlockedIncrement(ref);
    }
  }

  uint Release() {
    synchronized {
      int refCount = InterlockedDecrement(ref);
      if (refCount == 0) {
        if (!finalized) {
          finalized = true;
          finalize();
        }
        std.gc.removeRange(this);
        std.c.stdlib.free(this);
        return 0;
      }
      return refCount;
    }
  }

  extern (D):

  new(size_t sz) {
    void* p = std.c.stdlib.malloc(sz);
    if (p == null)
      throw new OutOfMemoryException;
    std.gc.addRange(p, p + sz);
    return p;
  }

  protected void finalize() {
  }

}

template IUnknownImpl(T ...) {
  mixin QueryInterfaceImpl!(T);
  mixin IUnknownRefImpl;
}

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

  int GetIDsOfNames(inout GUID riid, wchar** rgszNames, uint cNames, uint lcid, int* rgDispId) {
    rgDispId = null;
    return DISP_E_UNKNOWNNAME;
  }

  int Invoke(int dispIdMember, inout GUID riid, uint lcid, ushort wFlags, DISPPARAMS* pDispParams, VARIANT* pVarResult, EXCEPINFO* pExcepInfo, uint* puArgErr) {
    return DISP_E_MEMBERNOTFOUND;
  }

}

/**
 * An abstract base class for classes that implement one or more COM interfaces.
 *
 * Subclasses do not need to implement their own QueryInterface, AddRef and Release methods, as the class provides default implementations of those methods.
 * Examples:
 * ---
 * class XmlDocumentEvents : Implements!(XMLDOMDocumentEvents) {
 * }
 *
 * MyComObject docEvents = new MyComObject;
 * docEvents.Invoke();
 * ---
 */
public abstract class Implements(I0) : I0 {
  static if (is(I0 : IDispatch))
    mixin IDispatchImpl!(I0);
  else
    mixin IUnknownImpl!(I0);
}
/**
 * Ditto
 */
public abstract class Implements(I0, I1) : I0, I1 {
  mixin IUnknownImpl!(I0, I1);
}
/**
 * Ditto
 */
public abstract class Implements(I0, I1, I2) : I0, I1, I2 {
  mixin IUnknownImpl!(I0, I1, I2);
}
/**
 * Ditto
 */
public abstract class Implements(I0, I1, I2, I3) : I0, I1, I2, I3 {
  mixin IUnknownImpl!(I0, I1, I2, I3);
}
/**
 * Ditto
 */
public abstract class Implements(I0, I1, I2, I3, I4) : I0, I1, I2, I3, I4 {
  mixin IUnknownImpl!(I0, I1, I2, I3, I4);
}
/**
 * Ditto
 */
public abstract class Implements(I0, I1, I2, I3, I4, I5) : I0, I1, I2, I3, I4, I5 {
  mixin IUnknownImpl!(I0, I1, I2, I3, I4, I5);
}
/**
 * Ditto
 */
public abstract class Implements(I0, I1, I2, I3, I4, I5, I6) : I0, I1, I2, I3, I4, I5, I6 {
  mixin IUnknownImpl!(I0, I1, I2, I3, I4, I5, I6);
}
/**
 * Ditto
 */
public abstract class Implements(I0, I1, I2, I3, I4, I5, I6, I7) : I0, I1, I2, I3, I4, I5, I6, I7 {
  mixin IUnknownImpl!(I0, I1, I2, I3, I4, I5, I6, I7);
}
/**
 * Ditto
 */
public abstract class Implements(I0, I1, I2, I3, I4, I5, I6, I7, I8) : I0, I1, I2, I3, I4, I5, I6, I7, I8 {
  mixin IUnknownImpl!(I0, I1, I2, I3, I4, I5, I6, I7, I8);
}
/**
 * Ditto
 */
public abstract class Implements(I0, I1, I2, I3, I4, I5, I6, I7, I8, I9) : I0, I1, I2, I3, I4, I5, I6, I7, I8, I9 {
  mixin IUnknownImpl!(I0, I1, I2, I3, I4, I5, I6, I7, I8, I9);
}

public enum CoClassContext {
  InProcessServer = CLSCTX.CLSCTX_INPROC_SERVER,
  InProcessHandler = CLSCTX.CLSCTX_INPROC_HANDLER,
  LocalServer = CLSCTX.CLSCTX_LOCAL_SERVER,
  RemoteServer = CLSCTX.CLSCTX_REMOTE_SERVER,
  All = InProcessServer | InProcessHandler | LocalServer | RemoteServer
}

/**
 * Implements CoCreateInstance.
 * Params:
 *        T = The type of interface to instantiate.
 *        throws = true to indicate that an exception is thrown if the instantiation failed; otherwise, false.
 * Examples:
 * ---
 * IXMLDOMDocument3 doc = DOMDocument60.coCreate!(IXMLDOMDocument3);
 * ---
 */
template coCreate(T, bool throws = false) {

  public T coCreate(U)(U clsid, CoClassContext context = CoClassContext.InProcessServer) {
    GUID guid;
    static if (is(U == GUID))
      guid = clsid;
    else static if (is(U : char[])) {
      try {
        guid = GUID(clsid);
      }
      catch (FormatException) {
        try {
          guid = GUID.fromProgID(clsid);
        }
        catch (COMException e) {
          static if (throws)
            throw e;
          else
            return null;
        }
      }
    }

    T pv = null;
    int hr = CoCreateInstance(guid, null, context, T.IID, cast(void**)&pv);
    if (SUCCEEDED(hr))
      return pv;

    static if (throws)
      throw new COMException(hr);
    else
      return null;
  }

}

/**
 * Defines a list of interfaces that a coclass implements and provides a method for instantiating instances of those interfaces. Intended to be used as a mixin.
 */
template CoInterfaces(T ...) {

  /**
   * Implements CoCreateInstance.
   * Params:
   *        I = The type of interface to instantiate.
   *        throws = true to indicate that an exception is thrown if the instantiation failed; otherwise, false.
   *
   * Examples:
   * ---
   * // Declare the DOMDocument60 coclass.
   * abstract class DOMDocument60 {
   *   static GUID CLSID = { 0x88d96a05, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5 };
   *   mixin CoInterfaces!(IXMLDOMDocument3);
   * }
   *
   * // Create an instance.
   * IXMLDOMDocument3 doc = DOMDocument60.coCreate!(IXMLDOMDocument3);
   * ---
   */
  public static I coCreate(I, bool throws = false)(CoClassContext context = CoClassContext.InProcessServer) {
    static if (std.typetuple.IndexOf!(I, T) == -1)
      static assert(false, "'" ~ juno.base.meta.nameof!(typeof(this)) ~ "' does not support '" ~ juno.base.meta.nameof!(I) ~ "'.");
    else
      return .coCreate!(I, throws)(typeof(this).CLSID, context);
  }

}

/**
 * Calls IUnknown.Release and returns the object's reference count.
 *
 * The call to Release is wrapped in a try-catch block to prevent access violations from being thrown if the object's reference count has reached zero.
 */
public int tryRelease(IUnknown obj) {
  int refCount = 0;
  try {
    refCount = obj.Release();
  }
  catch {
  }
  return refCount;
}

/**
 * Calls tryRelease after the delegate has been executed.
 * Examples:
 * ---
 * IXMLDOMDocument3 doc = DOMDocument60.coCreate!(IXMLDOMDocument3);
 * releaseAfter (doc, {
 *   com_bool loaded;
 *   doc.load("books.xml".toVariant(true), loaded);
 * });
 * ---
 */
void releaseAfter(IUnknown obj, void delegate() block) {
  try {
    block();
  }
  finally {
    tryRelease(obj);
  }
}

/**
 * Clears the VARIANT and releases any resources held after the delegate has been executed.
 * Examples:
 * ---
 * VARIANT dest = "books.xml".toVariant();
 * clearAfter (dest, {
 *   xmldoc.save(dest);
 * });
 * ---
 */
void clearAfter(inout VARIANT var, void delegate() block) {
  try {
    block();
  }
  finally {
    var.clear();
  }
}

template com_cast_impl(T, bool throws, bool release) {

  public T com_cast_impl(U)(U obj) {
    if (obj is null) {
      return null;
    }

    T pv = null;
    int hr;
    if ((hr = obj.QueryInterface(T.IID, cast(void**)&pv)) == S_OK) {
      static if (release)
        tryRelease(obj);
      return pv;
    }

    static if (throws)
      throw new InvalidCastException("Invalid cast from '" ~ juno.base.meta.nameof!(U) ~ "' to '" ~ juno.base.meta.nameof!(T) ~ "'.");
    else
      return T.init;
  }

}

/**
 * Converts from one COM type to another COM type. If the conversion is not possible, returns null.
 *
 * com_cast (and the variants below) calls the object's QueryInterface method, which in turn is required to call the AddRef method,
 * incrementing the object's reference count.
 */
template com_cast(T) {
  alias com_cast_impl!(T, false, false) com_cast;
}

/**
 * Converts from one COM type to another COM type. If the conversion is not possible, throws an exception.
 * Throws: InvalidCastException if the conversion is not possible.
 */
template com_safe_cast(T) {
  alias com_cast_impl!(T, true, false) com_safe_cast;
}

/**
 * Converts from one COM type to another COM type. If the conversion is not possible, returns null.
 *
 * After the conversion, this function calls the specified object's Release method, decrementing the reference count.
 */
template com_release_cast(T) {
  alias com_cast_impl!(T, false, true) com_release_cast;
}

/**
 * Converts a UTF-8 string to a BSTR.
 */
wchar* utf8ToBstr(char[] str) {
  if (str == null)
    return null;

  return SysAllocString(str.toLPStr());
}

/**
 * Converts a BSTR to a UTF-8 string and frees the BSTR.
 */
char[] bstrToUtf8(wchar* bstr) {
  if (bstr == null)
    return null;

  uint len = SysStringLen(bstr);
  char[] str = bstr[0 .. len].toUtf8();
  SysFreeString(bstr);
  return str;
}

/**
 * Returns the length in characters of the BSTR.
 */
uint bstrLength(wchar* bstr) {
  return SysStringLen(bstr);
}

/**
 * Frees a BSTR previously allocated by utf8ToBstr.
 */
void freeBstr(wchar* bstr) {
  if (bstr != null)
    SysFreeString(bstr);
}

template VariantType(T) {
  static if (is(T == VARIANT_BOOL) || is(T == bool))
    const VariantType = VT_BOOL;
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
  else static if (is(T == wchar*) || is(T : char[]))
    const VariantType = VT_BSTR;
  else static if (is(T == char*))
    const VariantType = VT_LPSTR;
  else static if (is(T == SAFEARRAY*))
    const VariantType = VT_ARRAY;
  else static if (is(T == VARIANT))
    const VariantType = VT_VARIANT;
  else static if (is(T : IDispatch))
    const VariantType = VT_DISPATCH;
  else static if (is(T : IUnknown))
    const VariantType = VT_UNKNOWN;
  else static if (is(T == void*))
    const VariantType = VT_VOID | VT_BYREF;
  else static if (isPointer!(T))
    const VariantType = variantType!(typeof(*T)) | VT_BYREF;
  else
    const VariantType = VT_VOID;
}

/**
 * Converts a basic type to a COM variant.
 * Params:
 *        value = The _value to convert.
 *        collectable = true if the resulting VARIANT is to be freed when the GC runs; otherwise, false.
 */
public VARIANT toVariant(T)(T value, bool collectable = false) {
  static if (is(T == bool) ||
    is(T == ubyte) ||
    is(T == byte) ||
    is(T == ushort) ||
    is(T == short) ||
    is(T == uint) ||
    is(T == int) ||
    is(T == ulong) ||
    is(T == long) ||
    is(T == float) ||
    is(T == double))
    return VARIANT(value);
  else static if (is(T == enum))
    return VARIANT(cast(int)value);
  else static if (is(T : char[]) || is(T : IUnknown) || is(T == class)) {
    if (!collectable)
      return VARIANT(value);
    else {
      return (new class(value) {
        VARIANT var;
        this(T value) {
          var = VARIANT(value);
        }
        ~this() {
          try {
            var.clear();
          }
          catch {
          }
        }
      }).var;
    }
  }
}

/**
 * Converts a dynamic array to a COM safe array.
 *
 * Examples:
 * ---
 * int[] list = [ 1, 2, 3, 4 ];
 * SAFEARRAY* sa = list.toSafeArray();
 * ---
 */
public SAFEARRAY* toSafeArray(T)(T array) {
  static if (isArray!(T) && (!isMultiDimArray!(T))) {
    SAFEARRAY* safeArray = SafeArrayCreateVector(VT_VARIANT, 0, array.length);

    VARIANT* data;
    SafeArrayAccessData(safeArray, cast(void**)&data);
    foreach (index, element; array)
      data[index] = toVariant(element);
    SafeArrayUnaccessData(safeArray);

    return safeArray;
  }
  else
    static assert(false, "Specified argument must be a one-dimensional array.");
}

/**
 * Converts a COM safe array to a dynamic array.
 *
 * Examples:
 * ---
 * void test(SAFEARRAY* sa) {
 *   int[] list = toArray(sa);
 * }
 * ---
 */
public T[] toArray(T)(SAFEARRAY* array)
in {
  if (array != null)
    assert(array.cDims == 1, "Specified array must be of a single dimension only.");
}
body {
  if (array == null)
    return null;

  int upperBound = 0, lowerBound = 0;
  SafeArrayGetUBound(array, 1, upperBound);
  SafeArrayGetLBound(array, 1, lowerBound);
  int count = upperBound - lowerBound + 1;

  if (count == 0)
    return null;

  T[] result = new T[count];

  VARIANT* data;
  SafeArrayAccessData(array, cast(void**)&data);
  for (int i = lowerBound; i <= upperBound; i++)
    result[i] = com_cast!(T)(data[i]);
  SafeArrayUnaccessData(array);

  return result;
}