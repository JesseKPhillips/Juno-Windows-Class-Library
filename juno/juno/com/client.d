module juno.com.client;

private import juno.base.core,
  juno.base.text,
  juno.base.meta,
  juno.base.win32,
  juno.com.core,
  juno.utils.registry,
  std.string,
  std.conv;

class SafeArray(T, uint R = 1) {

  private SAFEARRAY* safeArray_;

  public const uint rank = R;

  public this(uint[] lengths ...) {
    assert(rank == lengths.length);
    SAFEARRAYBOUND[rank] bounds;
    for (uint i = 0; i < rank; i++)
      bounds[i].cElements = lengths[i];
    safeArray_ = SafeArrayCreate(deduceVarType!(T), R, bounds);
  }

  ~this() {
    if (safeArray_ != null) {
      SafeArrayDestroy(safeArray_);
      safeArray_ = null;
    }
  }

  public T getValue(int[] indices ...) {
    assert(rank == indices.length);
    T value;
    SafeArrayGetElement(safeArray_, indices, &value);
    return value;
  }

  public void setValue(T value, int[] indices ...) {
    assert(rank == indices.length);
    SafeArrayPutElement(safeArray_, indices, &value);
  }

  public T opIndex(int[] indices ...) {
    return getValue(indices);
  }
  public void opIndexAssign(T value, int[] indices ...) {
    setValue(value, indices);
  }

  public int getUpperBound(uint dimension) {
    int bound;
    SafeArrayGetUBound(safeArray_, dimension, bound);
    return bound;
  }

  public int getLowerBound(uint dimension) {
    int bound;
    SafeArrayGetLBound(safeArray_, dimension, bound);
    return bound;
  }

  public uint getLength(uint dimension) {
    int upperBound = getUpperBound(dimension);
    int lowerBound = getLowerBound(dimension);
    return upperBound + 1 - lowerBound;
  }

  public uint length() {
    return getLength(rank - 1);
  }
  public void length(uint value) {
    SAFEARRAYBOUND[rank] bounds;
    for (uint i = 0; i < rank; i++)
      bounds[i].cElements = value;
    SafeArrayRedim(safeArray_, bounds);
  }

}

/**
 * The base class for COM events.
 */
private import std.stdio;
class EventProviderBase(T, char[] libIID = null, char[] libVersion = null) : COMDispatchImpl!(T) {

  extern (D) :

  private ITypeLib typeLib_;
  private ITypeInfo typeInfo_;
  private uint cookie_;
  private int[char[]] names_;
  private IUnknown source_;
  private IConnectionPoint connectionPoint_;
  private IConnectionPointContainer connectionPointContainer_;

  protected this(IUnknown source) {
    connectionPointContainer_ = com_cast!(IConnectionPointContainer)(source);
  }

  /**
   * Allows an object to free resources before the object is deleted. Overridden.
   */
  protected override void finalize() {
    synchronized (this) {
      try {
        if (typeInfo_ !is null) {
          typeInfo_.Release();
          typeInfo_ = null;
        }

        if (typeLib_ !is null) {
          typeLib_.Release();
          typeLib_ = null;
        }

        if (connectionPoint_ !is null) {
          connectionPoint_.Unadvise(cookie_);

          connectionPoint_.Release();
          connectionPoint_ = null;
        }
      }
      catch {
      }
    }
  }

  protected int nameToDispId(char[] name, out bool success) {
    // Late/name binding for named methods.
    char[] n = name.tolower();
    // First, see if we've cached the name.
    if (auto id = n in names_) {
      success = true;
      return *id;
    }

    int id;
    // If the type information hasn't been initialized, do so now.
    if (typeInfo_ is null)
      init();
    // Should be cached now.
    if (auto id = n in names_) {
      success = true;
      return *id;
    }
    // Last resport - query the type library for the named method's identifier.
    if (typeInfo_ !is null) {
      wchar* szName = n.toUtf16z();
      if (typeInfo_.GetIDsOfNames(&szName, 1, &id) != S_OK) {
        success = false;
        return -1;
      }
    }
    names_[n] = id;
    success = true;
    return id;
  }

  /**
   * Connects event interfaces.
   */
  protected void connectEvents() {
    synchronized (this) {
      if (connectionPoint_ is null) {
        connectionPointContainer_.FindConnectionPoint(T.IID, connectionPoint_);
        connectionPoint_.Advise(this, cookie_);
      }
    }
  }

  private void init() {
    // Late name binding.
    // Only runs if methods were named instead of identified.

    GUID libGuid;
    short majorVersion = -1;
    short minorVersion = -1;
    if (libIID == null || libVersion == null) {
      // Get the associated type library and its version info from the Windows registry.
      // Expensive, but it saves clients needing to provide us with this information.
      char[] keyName = "Interface\\" ~ T.IID.toString() ~ "\\TypeLib";
      auto RegistryKey key = Registry.classesRoot.openSubKey(keyName, true);
      if (key !is null) {
        libGuid = GUID(key.getStringValue(null));
        char[][] temp = key.getStringValue("Version").split(".");
        majorVersion = (temp == null) ? -1 : cast(short)toInt(temp[0]);
        minorVersion = (temp == null) ? -1 : cast(short)toInt(temp[1]);
      }
    }
    else {
      libGuid = GUID(libIID);
      char[][] temp = libVersion.split(".");
      majorVersion = (temp == null) ? -1 : cast(short)toInt(temp[0]);
      minorVersion = (temp == null) ? -1 : cast(short)toInt(temp[1]);
    }

    if (majorVersion != -1 && minorVersion != -1 && libGuid != GUID.init) {
      if (LoadRegTypeLib(libGuid, majorVersion, minorVersion, 0, typeLib_) == S_OK) {
        typeLib_.GetTypeInfoOfGuid(T.IID, typeInfo_);

        if (typeInfo_ !is null) {
          TYPEATTR* typeAttr;
          if (typeInfo_.GetTypeAttr(typeAttr) == S_OK) {
            for (uint i = 0; i < typeAttr.cFuncs; i++) {
              FUNCDESC* funcDesc;
              if (typeInfo_.GetFuncDesc(i, funcDesc) == S_OK) {
                wchar* bstrName;
                if (typeInfo_.GetDocumentation(funcDesc.memid, &bstrName, null, null, null) == S_OK)
                  names_[bstrToUtf8(bstrName).tolower()] = funcDesc.memid;
                typeInfo_.ReleaseFuncDesc(funcDesc);
              }
            }
            typeInfo_.ReleaseTypeAttr(typeAttr);
          }
        }
        typeLib_.Release();
        typeLib_ = null;
      }
    }
  }

  extern (Windows) :

  override int GetIDsOfNames(inout GUID riid, wchar** rgszNames, uint cNames, uint lcid, int* rgdispid) {
    if (typeInfo_ !is null) {
      bool found = false;
      if (cNames == 1 && rgszNames != null && rgszNames[0] != null) {
        char[] name = toUtf8(rgszNames[0]).tolower();
        if (auto id = name in names_) {
          rgdispid[0] = *id;
          found = true;
        }
      }
      if (!found)
        return typeInfo_.GetIDsOfNames(rgszNames, cNames, rgdispid);
    }
    return S_OK;
  }

  override int Invoke(int dispidMember, inout GUID riid, uint lcid, ushort wFlags, DISPPARAMS* pdispparams, VARIANT* pvarResult, EXCEPINFO* pexcepinfo, uint* puArgErr) {
    if (typeInfo_ !is null)
      return typeInfo_.Invoke(this, dispidMember, wFlags, pdispparams, pvarResult, pexcepinfo, puArgErr);
    return S_OK;
  }

}

// Signatures for delegates.
private {
alias int delegate() FN0;
alias int delegate(uint) FN1;
alias int delegate(uint, uint) FN2;
alias int delegate(uint, uint, uint) FN3;
alias int delegate(uint, uint, uint, uint) FN4;
alias int delegate(uint, uint, uint, uint, uint) FN5;
alias int delegate(uint, uint, uint, uint, uint, uint) FN6;
alias int delegate(uint, uint, uint, uint, uint, uint, uint) FN7;
alias int delegate(uint, uint, uint, uint, uint, uint, uint, uint) FN8;
alias int delegate(uint, uint, uint, uint, uint, uint, uint, uint, uint) FN9;
alias int delegate(uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) FN10;
alias int delegate(uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) FN11;
alias int delegate(uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) FN12;
alias int delegate(uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) FN13;
alias int delegate(uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) FN14;
alias int delegate(uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) FN15;
alias int delegate(uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) FN16;
alias int delegate(uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) FN17;
alias int delegate(uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) FN18;
alias int delegate(uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) FN19;
alias int delegate(uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) FN20;
alias int delegate(uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) FN21;
alias int delegate(uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) FN22;
alias int delegate(uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) FN23;
alias int delegate(uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) FN24;
}

// Marshals a string representation of a native type to its corresponding (or nearest) COM type.
private ushort getVarType(char[] s) {
  switch (s) {
    case "bool":
      return VT_BOOL;
    case "ubyte":
      return VT_UI1;
    case "byte":
      return VT_I1;
    case "ushort":
      return VT_UI2;
    case "short":
      return VT_I2;
    case "uint":
      return VT_UI4;
    case "int":
      return VT_I4;
    case "ulong":
      return VT_UI8;
    case "long":
      return VT_I8;
    case "float":
      return VT_R4;
    case "double":
      return VT_R8;
    case "wchar*":
      return VT_BSTR;
    case "bool*":
      return VT_BYREF | VT_BOOL;
    case "ubyte*":
      return VT_BYREF | VT_UI1;
    case "byte*":
      return VT_BYREF | VT_I1;
    case "ushort*":
      return VT_BYREF | VT_UI2;
    case "short*":
      return VT_BYREF | VT_I2;
    case "uint*":
      return VT_BYREF | VT_UI4;
    case "int*":
      return VT_BYREF | VT_I4;
    case "ulong*":
      return VT_BYREF | VT_UI8;
    case "long*":
      return VT_BYREF | VT_I8;
    case "float*":
      return VT_BYREF | VT_R4;
    case "double*":
      return VT_BYREF | VT_R8;
    case "wchar**":
      return VT_BYREF | VT_BSTR;
    case "juno.com.core.com_bool":
    case "com_bool":
      return VT_BOOL;
    case "juno.com.core.VARIANT":
    case "VARIANT":
    case "juno.com.core.Variant":
    case "Variant":
      return VT_VARIANT;
    case "juno.com.core.IUnknown":
    case "IUnknown":
      return VT_UNKNOWN;
    case "juno.com.core.IDispatch":
    case "IDispatch":
      return VT_DISPATCH;
    case "juno.com.core.com_bool*":
    case "com_bool*":
      return VT_BYREF | VT_BOOL;
    case "juno.com.core.VARIANT*":
    case "VARIANT*":
    case "juno.com.core.Variant*":
    case "Variant*":
      return VT_BYREF | VT_VARIANT;
    case "juno.com.core.IUnknown*":
    case "IUnknown*":
      return VT_BYREF | VT_UNKNOWN;
    case "juno.com.core.IDispatch*":
    case "IDispatch*":
      return VT_BYREF | VT_DISPATCH;
    default:
      break;
  }
  return VT_VOID;
}

// Marshals a string representation of a D type to its corresponding (or nearest) COM type.
private ushort getVarType(TypeInfo typeInfo) {
  if (typeInfo is typeid(bool))
    return VT_BOOL;
  else if (typeInfo is typeid(ubyte))
    return VT_UI1;
  else if (typeInfo is typeid(byte))
    return VT_I1;
  else if (typeInfo is typeid(ushort))
    return VT_UI2;
  else if (typeInfo is typeid(short))
    return VT_I2;
  else if (typeInfo is typeid(uint))
    return VT_UI4;
  else if (typeInfo is typeid(int))
    return VT_I4;
  else if (typeInfo is typeid(ulong))
    return VT_UI8;
  else if (typeInfo is typeid(long))
    return VT_I8;
  else if (typeInfo is typeid(float))
    return VT_R4;
  else if (typeInfo is typeid(double))
    return VT_R8;
  else if (typeInfo is typeid(wchar*))
    return VT_BSTR;
  else if (typeInfo is typeid(bool*))
    return VT_BYREF | VT_BOOL;
  else if (typeInfo is typeid(ubyte*))
    return VT_BYREF | VT_UI1;
  else if (typeInfo is typeid(byte*))
    return VT_BYREF | VT_I1;
  else if (typeInfo is typeid(ushort*))
    return VT_BYREF | VT_UI2;
  else if (typeInfo is typeid(short*))
    return VT_BYREF | VT_I2;
  else if (typeInfo is typeid(uint*))
    return VT_BYREF | VT_UI4;
  else if (typeInfo is typeid(int*))
    return VT_BYREF | VT_I4;
  else if (typeInfo is typeid(ulong*))
    return VT_BYREF | VT_UI8;
  else if (typeInfo is typeid(long*))
    return VT_BYREF | VT_I8;
  else if (typeInfo is typeid(float*))
    return VT_BYREF | VT_R4;
  else if (typeInfo is typeid(double*))
    return VT_BYREF | VT_R8;
  else if (typeInfo is typeid(wchar**))
    return VT_BYREF | VT_BSTR;
  else if (typeInfo is typeid(VARIANT))
    return VT_VARIANT;
  else if (typeInfo is typeid(IUnknown))
    return VT_UNKNOWN;
  else if (typeInfo is typeid(IDispatch))
    return VT_DISPATCH;
  else if (typeInfo is typeid(VARIANT*))
    return VT_BYREF | VT_VARIANT;
  else if (typeInfo is typeid(IUnknown*))
    return VT_BYREF | VT_UNKNOWN;
  else if (typeInfo is typeid(IDispatch*))
    return VT_BYREF | VT_DISPATCH;
  return VT_VOID;
}

// Marshals a string representation of a type to its corresponding type.
private TypeInfo getTypeFromName(char[] s) {
  switch (s) {
    case "bool":
      return typeid(bool);
    case "ubyte":
      return typeid(ubyte);
    case "byte":
      return typeid(byte);
    case "ushort":
      return typeid(ushort);
    case "short":
      return typeid(short);
    case "uint":
      return typeid(uint);
    case "int":
      return typeid(int);
    case "ulong":
      return typeid(ulong);
    case "long":
      return typeid(long);
    case "float":
      return typeid(float);
    case "double":
      return typeid(double);
    case "wchar*":
      return typeid(wchar*);
    case "bool*":
      return typeid(bool*);
    case "ubyte*":
      return typeid(ubyte*);
    case "byte*":
      return typeid(byte*);
    case "ushort*":
      return typeid(ushort*);
    case "short*":
      return typeid(short*);
    case "uint*":
      return typeid(uint*);
    case "int*":
      return typeid(int*);
    case "ulong*":
      return typeid(ulong*);
    case "long*":
      return typeid(long*);
    case "float*":
      return typeid(float*);
    case "double*":
      return typeid(double*);
    case "wchar**":
      return typeid(wchar**);
    case "juno.com.core.com_bool":
    case "com_bool":
      return typeid(short);
    case "juno.com.core.VARIANT":
    case "VARIANT":
    case "juno.com.core.Variant":
    case "Variant":
      return typeid(VARIANT);
    case "juno.com.core.IUnknown":
    case "IUnknown":
      return typeid(IUnknown);
    case "juno.com.core.IDispatch":
    case "IDispatch":
      return typeid(IDispatch);
    case "juno.com.core.com_bool*":
    case "com_bool*":
      return typeid(short*);
    case "juno.com.core.VARIANT*":
    case "VARIANT*":
    case "juno.com.core.Variant*":
    case "Variant*":
      return typeid(VARIANT*);
    case "juno.com.core.IUnknown*":
    case "IUnknown*":
      return typeid(ubyte);
    case "juno.com.core.IDispatch*":
    case "IDispatch*":
      return typeid(IDispatch*);
    default:
      break;
  }
  return typeid(void);
}

// Holds information about a delegate/function and its COM representation.
private struct FunctionInfo {
  union {
    int delegate() del;
    struct { void* obj; int function() func; }
  }
  ushort returnType;
  ushort[8] paramTypes;
  uint paramCount;
}

interface IEventProvider {
  void bind(char[] name, inout FunctionInfo fi);
  void bind(int id, inout FunctionInfo fi);
}

template sink(TDelegate, TMember) {

  void sink(IEventProvider source, TMember nameOrId, TDelegate d) {
    static if (is(TMember : int) || is(TMember : char[])) {
      // This is the magic that converts a delegate into a list of COM types, preparing it for IDispatch.Invoke.
      // At compile-time, we get a delimited string representing the signature of the delegate (its return type 
      // and parameter types). Then we split the string and extract the COM type (VARIANT descriminator) from the native type.
      // Finally the COM types are stored in a FuncInfo struct.

      // Get a delimited string of the delegate's signature.
      // Form is <return-type>|<param1-type>|<param2-type>|...|<paramN-type>.
      // Note: out/inout <type> becomes <type>*.
      // For example:
      //   int delegate(double, inout bool)
      // becomes
      //   int|double|bool*
      // which in turn becomes an array of VT_I4,VT_R8,VT_BYREF|VT_BOOL
      char[] delegateSignature = juno.base.meta.demangle!(d.mangleof);
      char[][] typeList = delegateSignature.split("|");
      if (typeList[$ - 1] == null)
        typeList.length = typeList.length - 1;

      FunctionInfo fi;
      fi.del = cast(int delegate())d;
      // Convert native types to the COM types.
      fi.returnType = getVarType(typeList[0]);
      for (uint i = 1; i < typeList.length; i++)
        fi.paramTypes[i - 1] = getVarType(typeList[i]);
      fi.paramCount = typeList.length - 1;

      // Bind the information to the event provider.
      source.bind(nameOrId, fi);
    }
    else
      assert(Assertion!("Could not sink to the specified member. Argument must be of a type convertable to 'int' or 'char[]'."));
  }

}

class EventProvider(T, char[] libIID = null, char[] libVersion = null) : EventProviderBase!(T, libIID, libVersion), IEventProvider {

  extern (D) :

  private FunctionInfo[int][int] functionTable;

  public this(IUnknown source) {
    super(source);
  }

  protected void bind(char[] name, inout FunctionInfo fi) {
    synchronized (this) {
      bool result;
      bind(nameToDispId(name, result), fi);
    }
  }

  protected void bind(int id, inout FunctionInfo fi) {
    synchronized (this) {
      connectEvents();
      functionTable[id][fi.paramCount << 16] = fi;
      // We should check what we've been given matches what's in the type library.
    }
  }

  extern (Windows) :

  override int Invoke(int dispidMember, inout GUID riid, uint lcid, ushort wFlags, DISPPARAMS* pdispparams, VARIANT* pvarResult, EXCEPINFO* pexcepinfo, uint* puArgErr) {

    // Marshals COM types to native types.
    int dispInvokeFunction(inout FunctionInfo fi, ushort resultType, VARIANT*[] params, VARIANT* result) {
     
      int invoke(int delegate() func, uint count, uint* p) {
        bool hasReturn = (resultType != VT_VOID && resultType != VT_EMPTY);
        switch (count) {
          case 0:
            if (hasReturn)
              return func();
            (cast(FN0)func)();
            break;
          case 1:
            if (hasReturn)
              return (cast(FN1)func)(p[0]);
            (cast(FN1)func)(p[0]);
            break;
          case 2:
            if (hasReturn)
              return (cast(FN2)func)(p[0], p[1]);
            (cast(FN2)func)(p[0], p[1]);
            break;
          case 3:
            if (hasReturn)
              return (cast(FN3)func)(p[0], p[1], p[2]);
            (cast(FN3)func)(p[0], p[1], p[2]);
            break;
          case 4:
            if (hasReturn)
              return (cast(FN4)func)(p[0], p[1], p[2], p[3]);
            (cast(FN4)func)(p[0], p[1], p[2], p[3]);
            break;
          case 5:
            if (hasReturn)
              return (cast(FN5)func)(p[0], p[1], p[2], p[3], p[4]);
            (cast(FN5)func)(p[0], p[1], p[2], p[3], p[4]);
            break;
          case 6:
            if (hasReturn)
              return (cast(FN6)func)(p[0], p[1], p[2], p[3], p[4], p[5]);
            (cast(FN6)func)(p[0], p[1], p[2], p[3], p[4], p[5]);
            break;
          case 7:
            if (hasReturn)
              return (cast(FN7)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6]);
            (cast(FN7)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6]);
            break;
          case 8:
            if (hasReturn)
              return (cast(FN8)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[6]);
            (cast(FN8)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[6]);
            break;
          case 9:
            if (hasReturn)
              return (cast(FN9)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8]);
            (cast(FN9)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8]);
            break;
          case 10:
            if (hasReturn)
              return (cast(FN10)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9]);
            (cast(FN10)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9]);
            break;
          case 11:
            if (hasReturn)
              return (cast(FN11)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10]);
            (cast(FN11)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10]);
            break;
          case 12:
            if (hasReturn)
              return (cast(FN12)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11]);
            (cast(FN12)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11]);
            break;
          case 13:
            if (hasReturn)
              return (cast(FN13)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12]);
            (cast(FN13)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12]);
            break;
          case 14:
            if (hasReturn)
              return (cast(FN14)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13]);
            (cast(FN14)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13]);
            break;
          case 15:
            if (hasReturn)
              return (cast(FN15)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14]);
            (cast(FN15)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14]);
            break;
          case 16:
            if (hasReturn)
              return (cast(FN16)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15]);
            (cast(FN16)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15]);
            break;
          case 17:
            if (hasReturn)
              return (cast(FN17)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15], p[16]);
            (cast(FN17)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15], p[16]);
            break;
          case 18:
            if (hasReturn)
              return (cast(FN18)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15], p[16], p[17]);
            (cast(FN18)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15], p[16], p[17]);
            break;
          case 19:
            if (hasReturn)
              return (cast(FN19)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15], p[16], p[17], p[18]);
            (cast(FN19)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15], p[16], p[17], p[18]);
            break;
          case 20:
            if (hasReturn)
              return (cast(FN20)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15], p[16], p[17], p[18], p[19]);
            (cast(FN20)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15], p[16], p[17], p[18], p[19]);
            break;
          case 21:
            if (hasReturn)
              return (cast(FN21)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15], p[16], p[17], p[18], p[19], p[20]);
            (cast(FN21)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15], p[16], p[17], p[18], p[19], p[20]);
            break;
          case 22:
            if (hasReturn)
              return (cast(FN22)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15], p[16], p[17], p[18], p[19], p[20], p[21]);
            (cast(FN22)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15], p[16], p[17], p[18], p[19], p[20], p[21]);
            break;
          case 23:
            if (hasReturn)
              return (cast(FN23)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15], p[16], p[17], p[18], p[19], p[20], p[21], p[22]);
            (cast(FN23)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15], p[16], p[17], p[18], p[19], p[20], p[21], p[22]);
            break;
          case 24:
            if (hasReturn)
              return (cast(FN24)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15], p[16], p[17], p[18], p[19], p[20], p[21], p[22], p[23]);
            (cast(FN24)func)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15], p[16], p[17], p[18], p[19], p[20], p[21], p[22], p[23]);
            break;
          default:
            throw new Exception("Too many arguments.");
        }
        return S_OK;
      }

      uint getArgSize(ushort vt) {
        switch (vt) {
          case VT_I8:
          case VT_UI8:
          case VT_CY:
            return long.sizeof / uint.sizeof;
          case VT_R8:
            return double.sizeof / uint.sizeof;
          case VT_VARIANT:
            return (VARIANT.sizeof + 3) / uint.sizeof;
          default:
            break;
        }
        return 1;
      }

      uint totalArgSize;
      if (fi.obj != null)
        totalArgSize++;
      for (uint i = 0; i < fi.paramCount; i++)
        totalArgSize += getArgSize(fi.paramTypes[i]);

      uint* argsPtr = cast(uint*)juno.base.memory.malloc(uint.sizeof * totalArgSize);

      uint index;
      // Hidden 'this' pointer.
      if (fi.obj != null) {
        argsPtr[0] = cast(uint)fi.obj;
        index++;
      }
      for (uint i = 0; i < fi.paramCount; i++) {
        uint argSize = getArgSize(fi.paramTypes[i]);
        VARIANT* p = params[i];
        juno.base.memory.memcpy(&argsPtr[index], &p.iVal, argSize * uint.sizeof);
        index += argSize;
      }

      int hr = E_FAIL;
      if (fi.obj != null)
        hr = invoke(fi.del, totalArgSize, argsPtr);

      if (result != null && (resultType != VT_VOID || resultType != VT_EMPTY)) {
        result.vt = resultType;
        result.lVal = hr;
      }

      juno.base.memory.free(argsPtr);
      return S_OK;
    }

    int type = pdispparams.cArgs << 16;
    if (auto entry = dispidMember in functionTable) {
      if (auto fi = type in *entry) {
        VARIANT*[8] args;
        //VARIANT*[] pargs = (fi.paramCount != 0) ? args : null;

        for (uint i = 0; i < fi.paramCount; i++)
          args[i] = &pdispparams.rgvarg[fi.paramCount - i - 1];

        VARIANT result;
        if (pvarResult is null)
          pvarResult = &result;

        int hr = dispInvokeFunction(*fi, VT_VOID, args, &result);

        // Fix any booleans that returned 1 instead of -1 for true (VARIANT_TRUE).
        for (uint i = 0; i < fi.paramCount; i++) {
          if (args[i].vt == VT_BOOL && args[i].boolVal == 1)
            args[i].boolVal = VARIANT_TRUE;
          else if (args[i].vt == (VT_BYREF | VT_BOOL) && *args[i].pboolVal == 1)
            *args[i].pboolVal = VARIANT_TRUE;
        }
        return hr;
      }
    }
    return super.Invoke(dispidMember, riid, lcid, wFlags, pdispparams, pvarResult, pexcepinfo, puArgErr);
  }

}

template com_auto(I) {

  I com_auto(I obj) {
    return (new class(obj) Object {
      I obj;
      bool released;
      this(I obj) {
        this.obj = obj;
      }
      ~this() {
        release();
      }
      void release() {
        if (!released) {
          try {
            obj.Release();
            released = true;
          }
          catch {
          }
          finally {
            obj = null;
          }
        }
      }
    }).obj;
  }

}

template using(T) {

  void using(T obj, void delegate(T) block) {
    try {
      block(obj);
    }
    finally {
      static if (is(T : IUnknown))
        obj.Release();
      else
        delete obj;
    }
  }

}