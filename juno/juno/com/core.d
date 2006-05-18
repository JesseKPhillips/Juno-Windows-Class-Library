module juno.com.core;

private import juno.base.core,
  juno.base.text,
  juno.base.memory,
  juno.base.win32;

pragma(lib, "ole32.lib");
pragma(lib, "oleaut32.lib");

extern (Windows) :

struct GUID {

  uint a;
  ushort b;
  ushort c;
  ubyte d;
  ubyte e;
  ubyte f;
  ubyte g;
  ubyte h;
  ubyte i;
  ubyte j;
  ubyte k;

  static GUID opCall(char[] s) {

    ulong parse(char[] s) {

      bool hexToInt(char c, out uint result) {
        if (c >= '0' && c <= '9')
          result = c - '0';
        else if (c >= 'A' && c <= 'Z')
          result = c - 'A' + 10;
        else if (c >= 'a' && c <= 'z')
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

    if (s[0] == '{')
      s = s[1 .. $];
    if (s[$ - 1] == '}')
      s = s[0 .. $ - 1];

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

  //bool opEquals(GUID other) {
  //  return other.a == a && other.b == b && other.c == c && other.d == d && other.e == e && other.f == f && other.g == g && other.i == i && other.j == j && other.k == k;
  //}

  char[] toString() {

    void hexToString(inout char[] s, inout uint index, uint a, uint b) {

      char hexToChar(uint a) {
        a = a & 0xf;
        return cast(char)((a > 9) ? a - 10 + 0x61 : a + 0x30);
      }

      s[index++] = hexToChar(a >> 4);
      s[index++] = hexToChar(a);
      s[index++] = hexToChar(b >> 4);
      s[index++] = hexToChar(b);
    }

    char[] s = new char[38];
    s[0] = '{';
    s[$ - 1] = '}';

    uint index = 1;
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

    return s;
  }

  static GUID newGuid() {
    GUID g;
    CoCreateGuid(g);
    return g;
  }

}

enum : ushort {
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

enum : short {
  VARIANT_TRUE    = -1,
  VARIANT_FALSE   = 0
}

struct VARIANT {

  static VARIANT opCall(bool value) {
    VARIANT v;
    v.vt = VT_BOOL;
    v.boolVal = value ? VARIANT_TRUE : VARIANT_FALSE;
    return v;
  }

  static VARIANT opCall(ubyte value) {
    VARIANT v;
    v.vt = VT_UI1;
    v.bVal = value;
    return v;
  }

  static VARIANT opCall(byte value) {
    VARIANT v;
    v.vt = VT_I1;
    v.cVal = value;
    return v;
  }

  static VARIANT opCall(ushort value) {
    VARIANT v;
    v.vt = VT_UI2;
    v.uiVal = value;
    return v;
  }

  static VARIANT opCall(short value) {
    VARIANT v;
    v.vt = VT_I2;
    v.iVal = value;
    return v;
  }

  static VARIANT opCall(uint value) {
    VARIANT v;
    v.vt = VT_UI4;
    v.ulVal = value;
    return v;
  }

  static VARIANT opCall(int value) {
    VARIANT v;
    v.vt = VT_I4;
    v.lVal = value;
    return v;
  }

  static VARIANT opCall(ulong value) {
    VARIANT v;
    v.vt = VT_UI8;
    v.ullVal = value;
    return v;
  }

  static VARIANT opCall(long value) {
    VARIANT v;
    v.vt = VT_I8;
    v.llVal = value;
    return v;
  }

  static VARIANT opCall(float value) {
    VARIANT v;
    v.vt = VT_R4;
    v.fltVal = value;
    return v;
  }

  static VARIANT opCall(double value) {
    VARIANT v;
    v.vt = VT_R8;
    v.dblVal = value;
    return v;
  }

  static VARIANT opCall(char[] value) {
    VARIANT v;
    v.vt = VT_BSTR;
    v.bstrVal = utf8ToBstr(value);
    return v;
  }

  static VARIANT opCall(IUnknown value) {
    VARIANT v;
    if (IDispatch disp = com_cast!(IDispatch)(value)) {
      v.vt = VT_DISPATCH;
      v.pdispVal = disp;
    }
    else {
      v.vt = VT_UNKNOWN;
      v.punkVal = value;
    }
    return v;
  }

  void clear() {
    VariantClear(this);
  }

  TypeInfo getType() {
    switch (vt) {
      case VT_UI1:
        return typeid(ubyte);
      case VT_UI1 | VT_BYREF:
        return typeid(ubyte*);
      case VT_I1:
        return typeid(byte);
      case VT_I1 | VT_BYREF:
        return typeid(byte*);
      case VT_UI2:
        return typeid(ushort);
      case VT_UI2 | VT_BYREF:
        return typeid(ushort*);
      case VT_I2:
        return typeid(short);
      case VT_I2 | VT_BYREF:
        return typeid(short*);
      case VT_UI4:
        return typeid(uint);
      case VT_UI4 | VT_BYREF:
        return typeid(uint*);
      case VT_I4:
        return typeid(int);
      case VT_I4 | VT_BYREF:
        return typeid(int*);
      case VT_UI8:
        return typeid(ulong);
      case VT_UI8 | VT_BYREF:
        return typeid(ulong*);
      case VT_I8:
        return typeid(long);
      case VT_I8 | VT_BYREF:
        return typeid(long*);
      case VT_R4:
        return typeid(float);
      case VT_R4 | VT_BYREF:
        return typeid(float*);
      case VT_R8:
        return typeid(double);
      case VT_R8 | VT_BYREF:
        return typeid(double*);
      case VT_BOOL:
        return typeid(bool);
      case VT_BOOL | VT_BYREF:
        return typeid(bool*);
      case VT_BSTR:
        return typeid(char[]);
      case VT_BSTR | VT_BYREF:
        return typeid(char[]*);
      case VT_UNKNOWN:
        return typeid(IUnknown);
      case VT_UNKNOWN | VT_BYREF:
        return typeid(IUnknown*);
      case VT_DISPATCH:
        return typeid(IDispatch);
      case VT_DISPATCH | VT_BYREF:
        return typeid(IDispatch*);
      default:
        break;
    }
    return null;
  }

  union {
    struct {
      ushort vt;
      ushort wReserved1;
      ushort wReserved2;
      ushort wReserved3;
      union {
        long llVal;           // VT_I8
        int lVal;             // VT_I4
        ubyte bVal;           // VT_UI1
        short iVal;           // VT_I2
        float fltVal;         // VT_R4
        double dblVal;        // VT_R8
        short boolVal;        // VT_BOOL
        int scode;            // VT_ERROR
        long cyVal;           // VT_CY
        double date;          // VT_DATE
        wchar* bstrVal;       // VT_BSTR
        IUnknown punkVal;     // VT_UNKNOWN
        IDispatch pdispVal;   // VT_DISPATCH
        SAFEARRAY* parray;    // VT_ARRAY | VT_*
        ubyte* pbVal;         // VT_BYREF | VT_UI1
        short* piVal;         // VT_BYREF | VT_I2
        int* plVal;           // VT_BYREF | VT_I4
        long* pllVal;         // VT_BYREF | VT_I8
        float* pfltVal;       // VT_BYREF | VT_R4
        double* pdblVal;      // VT_BYREF | VT_R8
        short* pboolVal;      // VT_BYREF | VT_BOOL
        int* pscode;          // VT_BYREF | VT_ERROR
        long* pcyVal;         // VT_BYREF | VT_CY
        double* pdate;        // VT_BYREF | VT_DATE
        wchar** pbstrVal;     // VT_BYREF | VT_BSTR
        IUnknown* ppunkVal;   // VT_BYREF | VT_UNKNOWN
        IDispatch* ppdispVal; // VT_BYREF | VT_DISPATCH
        SAFEARRAY** pparray;  // VT_BYREF | VT_ARRAY | VT_*
        VARIANT* pvarVal;     // VT_BYREF | VT_VARIANT
        void* byref;
        byte cVal;            // VT_I1
        ushort uiVal;         // VT_UI2
        uint ulVal;           // VT_UI4
        ulong ullVal;         // VT_UI8
        int intVal;           // VT_INT
        uint uintVal;         // VT_UINT
        DECIMAL* pdecVal;     // VT_BYREF | VT_DECIMAL
        byte* pcVal;          // VT_BYREF | VT_I1
        ushort* puiVal;       // VT_BYREF | VT_UI2
        uint* pulVal;         // VT_BYREF | VT_UI4
        ulong* pullVal;       // VT_BYREF | VT_UI8
        int* pintVal;         // VT_BYREF | VT_INT
        uint* puintVal;       // VT_BYREF | VT_UINT
        struct {
          void* pvRecord;
          IRecordInfo pRecInfo;
        }
      }
    }
    DECIMAL decVal;
  }

}

enum : uint {
  FADF_AUTO         = 0x1,
  FADF_STATIC       = 0x2,
  FADF_EMBEDDED     = 0x4,
  FADF_FIXEDSIZE    = 0x10,
  FADF_RECORD       = 0x20,
  FADF_HAVEIID      = 0x40,
  FADF_HAVEVARTYPE  = 0x80,
  FADF_BSTR         = 0x100,
  FADF_UNKNOWN      = 0x200,
  FADF_DISPATCH     = 0x400,
  FADF_VARIANT      = 0x800,
  FADF_RESERVED     = 0xF008
}

struct SAFEARRAYBOUND {
  uint cElements;
  int lLbound;
}

struct SAFEARRAY {
  ushort cDims;
  ushort cFeatures;
  uint cbElements;
  uint cLocks;
  void* pvData;
  SAFEARRAYBOUND[1] rgsabound;
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
  ushort wMajorVersionNum;
  ushort wMinorVersionNum;
  TYPEDESC tdescAlias;
  IDLDESC idldescType;
}

struct PARAMDESCEX {
  uint cBytes;
  VARIANT varDefaultValue;
}

enum : ushort {
  PARAMFLAG_NONE          = 0x0,
  PARAMFLAG_FIN           = 0x1,
  PARAMFLAG_FOUT          = 0x2,
  PARAMFLAG_FLCID         = 0x4,
  PARAMFLAG_FRETVAL       = 0x8,
  PARAMFLAG_FOPT          = 0x10,
  PARAMFLAG_FHASDEFAULT   = 0x20
}

struct PARAMDESC {
  PARAMDESCEX* pparamdescex;
  ushort wParamFlags;
}

struct ELEMDESC {
  TYPEDESC tdesc;
  union {
    IDLDESC idldesc;
    PARAMDESC paramdesc;
  }
}

enum : ushort {
  IDLFLAG_NONE    = PARAMFLAG_NONE,
  IDLFLAG_FIN     = PARAMFLAG_FIN,
  IDLFLAG_FOUT    = PARAMFLAG_FOUT,
  IDLFLAG_FLCID   = PARAMFLAG_FLCID,
  IDLFLAG_FRETVAL = PARAMFLAG_FRETVAL
}

struct IDLDESC {
  uint dwReserved;
  ushort wIDLFlags;
}

struct ARRAYDESC {
  TYPEDESC tdescElem;
  ushort cDims;
  SAFEARRAYBOUND[1] rgbounds;
}

struct TYPEDESC {
  union {
    TYPEDESC* lptdesc;
    ARRAYDESC* lpadesc;
    uint hreftype;
  }
  ushort vt;
}

enum CALLCONV {
  CC_FASTCALL,
  CC_CDECL,
  CC_MSCPASCAL,
  CC_PASCAL = CC_MSCPASCAL,
  CC_MACPASCAL,
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
  INVOKE_FUNC           = 1,
  INVOKE_PROPERTYGET    = 2,
  INVOKE_PROPERTYPUT    = 4,
  INVOKE_PROPERTYPUTREF = 8
}

struct FUNCDESC {
  int memid;
  long* lprgscode;
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
  VAR_PERINSTANCE,
  VAR_STATIC,
  VAR_CONST,
  VAR_DISPATCH
}

enum : ushort {
  IMPLTYPEFLAG_FDEFAULT       = 0x1,
  IMPLTYPEFLAG_FSOURCE        = 0x2,
  IMPLTYPEFLAG_FRESTRICTED    = 0x4,
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

enum SYSKIND {
  SYS_WIN16,
  SYS_WIN32,
  SYS_MAC,
  SYS_WIN64
}

struct TLIBATTR {
  GUID guid;
  uint lcid;
  SYSKIND syskind;
  ushort wMajorVerNum;
  ushort wMinorVerNum;
  ushort wLibFlags;
}

struct CUSTDATAITEM {
  GUID guid;
  VARIANT varValue;
}

struct CUSTDATA {
  uint cCustData;
  CUSTDATAITEM* prgCustData;
}

enum {
  DISPID_PROPERTYPUT = -3
}

interface INull {
  static GUID IID = { 0x00000000, 0x0000, 0x0000, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
}

interface IUnknown {
  static GUID IID = { 0x00000000, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int QueryInterface(inout GUID riid, out void* ppvObj);
  uint AddRef();
  uint Release();
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

interface IDispatch : IUnknown {
  static GUID IID = { 0x00020400, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int GetTypeInfoCount(out uint pctinfo);
  int GetTypeInfo(uint itinfo, uint lcid, out ITypeInfo pptinfo);
  int GetIDsOfNames(inout GUID riid, wchar** rgszNames, uint cNames, uint lcid, int* rgdispid);
  int Invoke(int dispidMember, inout GUID riid, uint lcid, ushort wFlags, DISPPARAMS* pdispparams, VARIANT* pvarResult, EXCEPINFO* pexcepinfo, uint* puArgErr);
}

interface ITypeInfo : IUnknown {
  static GUID IID = { 0x00020401, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int GetTypeAttr(out TYPEATTR* ppTypeAttr);
  int GetTypeComp(out ITypeComp ppTComp);
  int GetFuncDesc(uint index, out FUNCDESC* ppFuncDesc);
  int GetVarDesc(uint index, out VARDESC* ppVarDesc);
  int GetNames(int memid, wchar** rgBstrNames, uint cMaxNames, uint* pcNames);
  int GetRefTypeOfImplType(uint index, out uint pRefType);
  int GetImplTypeFlags(uint index, out int pImplTypeFlags);
  int GetIDsOfNames(wchar** rgszNames, uint cNames, int* pMemId);
  int Invoke(void* pvInstance, int memid, ushort wFlags, DISPPARAMS* pDispParams, VARIANT* pVarResult, EXCEPINFO* pExcepInfo, uint* puArgError);
  int GetDocumentation(int memid, wchar** pBstrName, wchar** pBstrDocString, uint* pdwHelpContext, wchar** pBstrHelpFile);
  int GetDllEntry(int memid, INVOKEKIND invKind, out wchar* pBstrDllName, out wchar* pBstrName, out ushort pwOrdinal);
  int GetRefTypeInfo(uint hRefType, out ITypeInfo ppTInfo);
  int AddressOfMember(int memid, INVOKEKIND invKind, void** ppv);
  int CreateInstance(IUnknown pUnkOuter, inout GUID riid, void** ppvObj);
  int GetMops(int memid, out wchar* pBstrMops);
  int GetContainingTypeLib(out ITypeLib ppTLib, out uint pIndex);
  void ReleaseTypeAttr(TYPEATTR* pTypeAttr);
  void ReleaseFuncDesc(FUNCDESC* pFuncDesc);
  void ReleaseVarDesc(VARDESC* pVarDesc);
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
  int IsName(wchar* szNameBuf, uint lHashVal, out bool pfName);
  int FindName(wchar* szNameBuf, uint lHashVal, ITypeInfo* ppTInfo, int* rgMemId, out ushort pcFound);
  int ReleaseTLibAttr(TLIBATTR* pTLibAttr);
}

enum DESCKIND {
  DESCKIND_NONE,
  DESCKIND_FUNCDESC,
  DESCKIND_VARDESC,
  DESCKIND_TYPECOMP,
  DESCKIND_IMPLICITAPPOBJ,
  DESCKIND_MAX
}

union BINDPTR {
  FUNCDESC* lpfuncdesc;
  VARDESC* lpcardesc;
  ITypeComp lptcomp;
}

interface ITypeComp : IUnknown {
  static GUID IID = { 0x00020403, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int Bind(wchar* szName, uint lHashVal, ushort wFlags, out ITypeInfo ppTInfo, out DESCKIND pDescKind, out BINDPTR pBindPtr);
  int BindType(wchar* szName, uint lHashVal, out ITypeInfo ppTInfo, out ITypeComp ppTComp);
}

interface IEnumVARIANT : IUnknown {
  static GUID IID = { 0x00020404, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int Next(uint celt, VARIANT* rgvar, out uint pceltFetched);
  int Skip(uint celt);
  int Reset();
  int Clone(out IEnumVARIANT ppenum);
}

interface ICreateTypeInfo : IUnknown {
  static GUID IID = { 0x00020404, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
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

interface ITypeLib2 : ITypeLib {
  static GUID IID = { 0x00020411, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int GetCustData(inout GUID guid, out VARIANT pVarVal);
  int GetLibStatistics(out uint pcUniqueNames, out uint pcchUniqueNames);
  int GetDocumentation2(int index, int lcid, out wchar* pbstrHelpString, out uint pdwHelpStringContext, out wchar* pbstrHelpStringDll);
  int GetAllCustData(out CUSTDATA pCustData);
}

interface ITypeInfo2 : ITypeInfo {
  static GUID IID = { 0x00020412, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 };
  int GetTypeKind(out TYPEKIND pTypeKind);
  int GetTypeFlags(out uint pTypeFlags);
  int GetFuncIndexOfMemId(int memid, INVOKEKIND invKind, out uint pFuncIndex);
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

struct CONNECTDATA {
  IUnknown pUnk;
  uint dwCookie;
}

interface IEnumConnections : IUnknown {
  static GUID IID = { 0xB196B287, 0xBAB4, 0x101A, 0xB6, 0x9C, 0x00, 0xAA, 0x00, 0x34, 0x1D, 0x07 };
  int Next(uint cConnections, CONNECTDATA* rgcd, out uint pcFetched);
  int Skip(uint cConnections);
  int Reset();
  int Clone(out IEnumConnections ppEnum);
}

enum {
  S_OK                    = 0x00000000,
  S_FALSE                 = 0x00000001,
  E_NOTIMPL               = 0x80004001,
  E_NOINTERFACE           = 0x80004002,
  E_FAIL                  = 0x80004005,
  DISP_E_MEMBERNOTFOUND   = 0x80020003,
  DISP_E_UNKNOWNNAME      = 0x80020006,
  TYPE_E_ELEMENTNOTFOUND  = 0x8002802B
}

enum : uint {
  CLSCTX_INPROC_SERVER          = 0x1,
  CLSCTX_INPROC_HANDLER         = 0x2,
  CLSCTX_LOCAL_SERVER           = 0x4,
  CLSCTX_INPROC_SERVER16        = 0x8,
  CLSCTX_REMOTE_SERVER          = 0x10,
  CLSCTX_INPROC_HANDLER16       = 0x20
}

enum : uint {
  COINIT_MULTITHREADED        = 0x0,
  COINIT_APARTMENTTHREADED    = 0x2,
  COINIT_DISABLE_OLE1DDE      = 0x4,
  COINIT_SPEED_OVER_MEMORY    = 0x8
}

enum {
  DISPATCH_METHOD         = 0x1,
  DISPATCH_PROPERTYGET    = 0x2,
  DISPATCH_PROPERTYPUT    = 0x4,
  DISPATCH_PROPERTYPUTREF = 0x8
}

int CoInitialize(void* pvReserved);
int CoInitializeEx(void* pvReserved, uint dwCoInit);
int CoUninitialize();

int CoCreateInstance(inout GUID rclsid, IUnknown pUnkOther, uint dwClsContext, inout GUID riid, out void* pv);
int CoGetClassObject(inout GUID rclsid, uint dwClsContext, void* pvReserved, inout GUID riid, out void* pv);
int GetActiveObject(inout GUID rclsid, void* pvReserved, out void* pv);

int CLSIDFromProgID(wchar* lpszProgID, out GUID lpclsid);
int CoCreateGuid(out GUID pguid);

int DispCallFunc(void* pvInstance, uint oVft, CALLCONV cc, ushort vtReturn, uint cActuals, ushort* prgvt, VARIANT** prgpvarg, VARIANT* pvargResult);

void VariantInit(VARIANT* pvarg);
int VariantClear(VARIANT* pvarg);
int VariantChangeType(VARIANT* pvargDest, VARIANT* pvarSrc, ushort wFlags, ushort vt);
int VariantCopy(VARIANT* pvargDest, VARIANT* pvargSrc);

int SafeArrayAllocDescriptor(uint cDims, SAFEARRAY** ppsaOut);
int SafeArrayAllocDescriptorEx(ushort vt, uint cDims, SAFEARRAY** ppsaOut);
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
int SafeArrayGetElement(SAFEARRAY* psa, int* rgIndices, void* pv);
int SafeArrayPutElement(SAFEARRAY* psa, int* rgIndices, void* pv);
int SafeArrayCopy(SAFEARRAY* psa, SAFEARRAY** ppsaOut);
int SafeArrayPtrOfIndex(SAFEARRAY* psa, int* rgIncides, void** ppvData);
int SafeArraySetRecordInfo(SAFEARRAY* psa, IRecordInfo prinfo);
int SafeArrayGetRecordInfo(SAFEARRAY* psa, out IRecordInfo prinfo);
int SafeArrayGetVartype(SAFEARRAY* psa, out ushort pvt);
SAFEARRAY* SafeArrayCreateVector(ushort vt, int lLbound, uint cElements);
SAFEARRAY* SafeArrayCreateVectorEx(ushort vt, int lLbound, uint cElements, void* pvExtra);

wchar* SysAllocString(wchar*);
wchar* SysAllocStringLen(wchar*, uint);
void SysFreeString(wchar*);
int SysStringLen(wchar*);

int LoadTypeLib(wchar* szFile, out ITypeLib pptlib);
int LoadRegTypeLib(inout GUID rguid, ushort wVerMajor, ushort wVerMinor, uint lcid, out ITypeLib pptlib);
int RegisterTypeLib(ITypeLib ptlib, wchar* szFullPath, wchar* szHelpDir);
int UnRegisterTypeLib(inout GUID libID, ushort wVerMajor, ushort wVerMinor, uint lcid, SYSKIND syskind);
int CreateTypeLib(SYSKIND syskind, wchar* szFile, out ICreateTypeLib ppctlib);
int CreateTypeLib2(SYSKIND syskind, wchar* szFile, out ICreateTypeLib2 ppctlib);

extern (D) :

static this() {
  CoInitializeEx(null, COINIT_APARTMENTTHREADED);
}

static ~this() {
  GC.collect();
  CoUninitialize();
}

template deduceVarType(T) {
  static if (is(T == ubyte))
    const deduceVarType = VT_UI1;
  else static if (is(T == byte))
    const deduceVarType = VT_I1;
  else static if (is(T == ushort))
    const deduceVarType = VT_UI2;
  else static if (is(T == short))
    const deduceVarType = VT_I2;
  else static if (is(T == uint))
    const deduceVarType = VT_UI4;
  else static if (is(T == int))
    const deduceVarType = VT_I4;
  else static if (is(T == ulong))
    const deduceVarType = VT_UI8;
  else static if (is(T == long))
    const deduceVarType = VT_I8;
  else static if (is(T == float))
    const deduceVarType = VT_R4;
  else static if (is(T == double))
    const deduceVarType = VT_R8;
  else static if (is(T == bool))
    const deduceVarType = VT_BOOL;
  else static if (is(T == char[]))
    const deduceVarType = VT_BSTR;
  else static if (is(T : IDispatch)) // must go before IUnknown
    const deduceVarType = VT_DISPATCH;
  else static if (is(T : IUnknown))
    const deduceVarType = VT_UNKNOWN;
  else
    const deduceVarType = VT_VOID;
}

// For coclasses
template CoClassInterfaces(I1, I2 = void, I3 = void, I4 = void, I5 = void, I6 = void, I7 = void, I8 = void, I9 = void, I10 = void, I11 = void, I12 = void, I13 = void, I14 = void, I15 = void, I16 = void, I17 = void, I18 = void, I19 = void, I20 = void) {

  template createInstance(T, bool throws = false) {

    static T createInstance() {
      void* pv = null;
      int errorCode;
      if ((errorCode = CoCreateInstance(IID, null, CLSCTX_INPROC_SERVER, T.IID, pv)) == S_OK)
        return cast(T)pv;
      if (throws)
        throw new COMException(errorCode);
      return null;
    }

  }

}

template QueryInterfaceImpl(I1, I2 = void, I3 = void, I4 = void, I5 = void, I6 = void, I7 = void, I8 = void, I9 = void, I10 = void, I11 = void, I12 = void, I13 = void, I14 = void, I15 = void, I16 = void, I17 = void, I18 = void, I19 = void, I20 = void) {

  int QueryInterface(inout GUID riid, out void* ppvObj) {
    ppvObj = null;

    if (riid == IUnknown.IID)
      ppvObj = cast(IUnknown)this;
    static if (!is(I1 == void)) {
      if (riid == I1.IID)
        ppvObj = cast(I1)this;
    }
    static if (!is(I2 == void)) {
      if (riid == I2.IID)
        ppvObj = cast(I2)this;
    }
    static if (!is(I3 == void)) {
      if (riid == I3.IID)
        ppvObj = cast(I3)this;
    }
    static if (!is(I4 == void)) {
      if (riid == I4.IID)
        ppvObj = cast(I4)this;
    }
    static if (!is(I5 == void)) {
      if (riid == I5.IID)
        ppvObj = cast(I5)this;
    }
    static if (!is(I6 == void)) {
      if (riid == I6.IID)
        ppvObj = cast(I6)this;
    }
    static if (!is(I7 == void)) {
      if (riid == I7.IID)
        ppvObj = cast(I7)this;
    }
    static if (!is(I8 == void)) {
      if (riid == I8.IID)
        ppvObj = cast(I8)this;
    }
    static if (!is(I9 == void)) {
      if (riid == I9.IID)
        ppvObj = cast(I9)this;
    }
    static if (!is(I10 == void)) {
      if (riid == I10.IID)
        ppvObj = cast(I10)this;
    }
    static if (!is(I11 == void)) {
      if (riid == I11.IID)
        ppvObj = cast(I11)this;
    }
    static if (!is(I12 == void)) {
      if (riid == I12.IID)
        ppvObj = cast(I12)this;
    }
    static if (!is(I13 == void)) {
      if (riid == I13.IID)
        ppvObj = cast(I13)this;
    }
    static if (!is(I14 == void)) {
      if (riid == I14.IID)
        ppvObj = cast(I14)this;
    }
    static if (!is(I15 == void)) {
      if (riid == I15.IID)
        ppvObj = cast(I15)this;
    }
    static if (!is(I16 == void)) {
      if (riid == I16.IID)
        ppvObj = cast(I16)this;
    }
    static if (!is(I17 == void)) {
      if (riid == I17.IID)
        ppvObj = cast(I17)this;
    }
    static if (!is(I18 == void)) {
      if (riid == I18.IID)
        ppvObj = cast(I18)this;
    }
    static if (!is(I19 == void)) {
      if (riid == I19.IID)
        ppvObj = cast(I19)this;
    }
    static if (!is(I20 == void)) {
      if (riid == I20.IID)
        ppvObj = cast(I20)this;
    }

    if (ppvObj is null)
      return E_NOINTERFACE;

    (cast(IUnknown)ppvObj).AddRef();
    return S_OK;
  }

}

template ReferenceCountImpl() {

  private int refCount_;
  private bool finalized_;

  new(size_t sz) {
    void* p = juno.base.memory.malloc(sz);
    GC.addRange(p, p + sz);
    return p;
  }

  uint AddRef() {
    return juno.base.win32.InterlockedIncrement(refCount_);
  }

  uint Release() {
    if (juno.base.win32.InterlockedDecrement(refCount_) == 0) {
      if (!finalized_) {
        finalize();
        finalized_ = true;
      }
      GC.removeRange(this);
      juno.base.memory.free(this);
    }
    return refCount_;
  }

  ~this() {
    Release();
  }

  extern (D)
  protected void finalize() {
  }

}

template COMInterface(I1, I2 = void, I3 = void, I4 = void, I5 = void, I6 = void, I7 = void, I8 = void, I9 = void, I10 = void, I11 = void, I12 = void, I13 = void, I14 = void, I15 = void, I16 = void, I17 = void, I18 = void, I19 = void, I20 = void) {

  mixin QueryInterfaceImpl!(I1, I2, I3, I4, I5, I6, I7, I8, I9, I10, I11, I12, I13, I14, I15, I16, I17, I18, I19, I20);
  mixin ReferenceCountImpl;

}

abstract class COMImplements(I1, I2 = INull, I3 = INull, I4 = INull, I5 = INull, I6 = INull, I7 = INull, I8 = INull, I9 = INull, I10 = INull, I11 = INull, I12 = INull, I13 = INull, I14 = INull, I15 = INull, I16 = INull, I17 = INull, I18 = INull, I19 = INull, I20 = INull)
  : I1, I2, I3, I4, I5, I6, I7, I8, I9, I10, I11, I12, I13, I14, I15, I16, I17, I18, I19, I20 {

  mixin COMInterface!(I1, I2, I3, I4, I5, I6, I7, I8, I9, I10, I11, I12, I13, I14, I15, I16, I17, I18, I19, I20);

}

template COMDispatch(/*TDispatch*/) {

  //mixin ComInterface!(IDispatch, TDispatch);

  int GetTypeInfoCount(out uint pctinfo) {
    pctinfo = 0;
    return E_NOTIMPL;
  }

  int GetTypeInfo(uint itinfo, uint lcid, out ITypeInfo pptinfo) {
    pptinfo = null;
    return E_NOTIMPL;
  }

  int GetIDsOfNames(inout GUID riid, wchar** rgszNames, uint cNames, uint lcid, int* rgdispid) {
    *rgdispid = 0;
    return DISP_E_UNKNOWNNAME;
  }

  int Invoke(int dispidMember, inout GUID riid, uint lcid, ushort wFlags, DISPPARAMS* pdispparams, VARIANT* pvarResult, EXCEPINFO* pexcepinfo, uint* puArgErr) {
    return DISP_E_MEMBERNOTFOUND;
  }

}

abstract class COMDispatchImpl(T = IDispatch) : COMImplements!(IDispatch, T) {

  //mixin ComDispatch!(TDispatch);
  mixin COMDispatch;

}

private template Assertion(char[] message) {
  pragma(msg, "Error: " ~ message);
  const bool Assertion = false;
}

template com_cast_impl(T, bool throws = false) {

  template com_cast(U) {

    T com_cast(U u) {

      static if (is(U : IUnknown)) {
        if (u is null)
          return null;

        void* pv = null;
        int errorCode;
        if ((errorCode = u.QueryInterface(T.IID, pv)) == S_OK)
          return cast(T)pv;
        if (throws)
          throw new COMException(errorCode);
        return null; // E_NOINTERFACE;
      }
      else static if (is(U == VARIANT)) {

        bool changeType(VARIANT* dst, VARIANT* src, ushort vt) {
          return VariantChangeType(dst, src, 0, vt) == S_OK;
        }

        const ushort vt = deduceVarType!(T);
        static if (vt != VT_VOID) {
          VARIANT v;
          if (changeType(&v, &u, vt)) {
            static if (vt == VT_BOOL)
              return (v.boolVal == VARIANT_TRUE) ? true : false;
            else static if (vt == VT_UI1)
              return v.bVal;
            else static if (vt == VT_I1)
              return v.cVal;
            else static if (vt == VT_UI2)
              return v.uiVal;
            else static if (vt == VT_I2)
              return v.iVal;
            else static if (vt == VT_UI4)
               return v.ulVal;
            else static if (vt == VT_I4)
              return v.lVal;
            else static if (vt == VT_UI8)
              return v.ullVal;
            else static if (vt == VT_I8)
              return v.llVal;
            else static if (vt == VT_R4)
              return v.fltVal;
            else static if (vt == VT_R8)
              return v.dblVal;
            else static if (vt == VT_BSTR)
              return bstrToUtf8(v.bstrVal);
            else static if (vt == VT_UNKNOWN)
              return com_cast!(T)(u.punkVal);
            else static if (vt == VT_DISPATCH)
              return com_cast!(T)(u.pdispVal);
          }
          else {
            if (throws)
              throw new COMException;
            return T.init;
          }
        }
        else
          assert(Assertion!("Cannot cast to the specified type."));
      }
      else
        assert(Assertion!("Cannot cast to the specified type."));
    }

  }

}

template com_cast(T) {
  alias com_cast_impl!(T, false).com_cast com_cast;
}

template com_cast_throws(T) {
  alias com_cast_impl!(T, true).com_cast com_cast;
}

wchar* utf8ToBstr(char[] value) {
  if (value == null)
    return null;
  return SysAllocString(value.toUtf16z());
}

char[] bstrToUtf8(wchar* value) {
  if (value == null)
    return "";
  char[] ret = toUtf8(value[0 .. SysStringLen(value)]);
  SysFreeString(value);
  return ret;
}

enum : com_bool {
  com_true = -1,
  com_false = 0
}

typedef short com_bool = com_false;

// Is this the best we can do?
alias VARIANT Variant;

template toVariant(T) {

  VARIANT toVariant(T value) {
    // We just want the VARIANT cleaned up when the GC runs.
    return (new class(value) Object {
      VARIANT v;
      this(T value) {
        v = VARIANT(value);
      }
      ~this() {
        try {
          v.clear();
        }
        catch {
        }
      }
    }).v;
  }

}

class COMException : Exception {

  private int errorCode_;

  public this(char[] message) {
    super(message);
    errorCode_ = E_FAIL;
  }

  public this(int error = E_FAIL) {
    this(error, createErrorMessage(error));
  }

  public this(int error, char[] message) {
    super(message);
    errorCode_ = error;
  }

  public int errorCode() {
    return errorCode_;
  }

  private static char[] createErrorMessage(int error) {
    wchar[256] buffer;
    uint r = FormatMessageW(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS, null, error, 0, buffer, buffer.length + 1, null);
    if (r != 0)
      return .toUtf8(buffer[0 .. r]);
    return "Unspecified Error";
  }
}

/*class SimpleDispEvent : COMDispatchImpl!() {

  int Invoke(int dispidMember, inout GUID riid, uint lcid, ushort wFlags, DISPPARAMS* pdispparams, VARIANT* pvarResult, EXCEPINFO* pexcepinfo, uint* puArgErr) {
    if (dispidMember == 0 && handler != null) {
      handler();
      return S_OK;
    }
    return super.Invoke(dispidMember, riid, lcid, wFlags, pdispparams, pvarResult, pexcepinfo, puArgErr);
  }

  extern (D) :

  private void delegate() handler;

  this(void delegate() handler) {
    this.handler = handler;
  }

}*/