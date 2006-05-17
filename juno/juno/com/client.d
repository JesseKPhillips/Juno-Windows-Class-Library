module juno.com.client;

private import juno.base.core,
  juno.base.text,
  juno.com.core,
  juno.utils.registry;

class SimpleEventProvider : COMDispatchImpl!() {

  override int Invoke(int dispidMember, inout GUID riid, uint lcid, ushort wFlags, DISPPARAMS* pdispparams, VARIANT* pvarResult, EXCEPINFO* pexcepinfo, uint* puArgErr) {
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

}

/**
 * The base class for COM events.
 */
class EventProviderBase(T, char[] libIID = null, char[] libVersion = null) : COMDispatchImpl!(T) {

  extern (D) :

  private ITypeLib typeLib_;
  private ITypeInfo typeInfo_;
  private uint cookie_;
  private int[char[]] names_;
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

  protected int dispIdFromName(char[] name, out bool success) {
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

//private struct FunctionInfo {
//  ushort returnType;
//  ushort[] paramTypes;
//}

private struct DelegateProxy {
  void delegate() method;
  bool hasReturn;
  //FunctionInfo* methodInfo;
}

/*struct StdCallThunk {
  extern (Windows) alias void function() HFN;
  extern (Windows) alias void function() TMFP;
  extern (Windows) alias void delegate() TMFPM;
  void* vtbl;
  void* pthis;
  TMFP pfn;
  HFN pfnHelper;
  void init(TMFP pf, void* p) {
    pfnHelper = &StdCallThunkHelper;
    vtbl = &pfnHelper;
    pthis = p;
    pfn = pf;
  }
}
extern (Windows)

extern (Windows)
void StdCallThunkHelper() {
  asm {
    mov EAX, [ESP + 4];
    mov EDX, [EAX + 4];
    mov [ESP + 4], EDX;
    mov EAX, [EAX + 8];
    jmp EAX;
  }
}
  union Union {
    StdCallThunk.TMFPM delegate_;
    struct {
      void* p;
      StdCallThunk.TMFP function_;
    }
  }
          VARIANT result;
          StdCallThunk thunk;
          Union u;
          u.delegate_ = cast(StdCallThunk.TMFPM)&test;
          u.p = cast(T)this;
          thunk.init(cast(StdCallThunk.TMFP)u.function_, cast(T)this);
          ushort[1] vvv;
          vvv[0] = VT_I4;
          VARIANT x = VARIANT(100);
          VARIANT*[1] rgVarArgs;
          rgVarArgs[0] = &x;
          int hr = DispCallFunc(&thunk, 0, CALLCONV.CC_STDCALL, VT_EMPTY, 1, vvv, rgVarArgs, &result);
          writefln("%x", hr);
          */

/**
 * Handles COM events.
 */
class EventProvider(T, char[] libIID = null, char[] libVersion = null) : EventProviderBase!(T, libIID, libVersion) {

  extern (D) :

  private DelegateProxy[int][int] handlers_;

  public this(IUnknown source) {
    super(source);
  }

  // Late name binding methods.

  public void bind(char[] name, void delegate() handler) {
    bool result;
    bind(dispIdFromName(name, result), handler);
  }

  public void bind(char[] name, void delegate(VARIANT) handler) {
    bool result;
    bind(dispIdFromName(name, result), handler);
  }

  public void bind(char[] name, void delegate(VARIANT, VARIANT) handler) {
    bool result;
    bind(dispIdFromName(name, result), handler);
  }

  public void bind(char[] name, void delegate(VARIANT, VARIANT, VARIANT) handler) {
    bool result;
    bind(dispIdFromName(name, result), handler);
  }

  public void bind(char[] name, void delegate(VARIANT, VARIANT, VARIANT, VARIANT) handler) {
    bool result;
    bind(dispIdFromName(name, result), handler);
  }

  public void bind(char[] name, void delegate(VARIANT, VARIANT, VARIANT, VARIANT, VARIANT) handler) {
    bool result;
    bind(dispIdFromName(name, result), handler);
  }

  public void bind(char[] name, void delegate(VARIANT, VARIANT, VARIANT, VARIANT, VARIANT, VARIANT) handler) {
    bool result;
    bind(dispIdFromName(name, result), handler);
  }

  public void bind(char[] name, void delegate(VARIANT, VARIANT, VARIANT, VARIANT, VARIANT, VARIANT, VARIANT) handler) {
    bool result;
    bind(dispIdFromName(name, result), handler);
  }

  public void bind(char[] name, VARIANT delegate() handler) {
    bool result;
    bind(dispIdFromName(name, result), handler);
  }

  public void bind(char[] name, VARIANT delegate(VARIANT) handler) {
    bool result;
    bind(dispIdFromName(name, result), handler);
  }

  public void bind(char[] name, VARIANT delegate(VARIANT, VARIANT) handler) {
    bool result;
    bind(dispIdFromName(name, result), handler);
  }

  public void bind(char[] name, VARIANT delegate(VARIANT, VARIANT, VARIANT) handler) {
    bool result;
    bind(dispIdFromName(name, result), handler);
  }

  public void bind(char[] name, VARIANT delegate(VARIANT, VARIANT, VARIANT, VARIANT) handler) {
    bool result;
    bind(dispIdFromName(name, result), handler);
  }

  public void bind(char[] name, VARIANT delegate(VARIANT, VARIANT, VARIANT, VARIANT, VARIANT) handler) {
    bool result;
    bind(dispIdFromName(name, result), handler);
  }

  public void bind(char[] name, VARIANT delegate(VARIANT, VARIANT, VARIANT, VARIANT, VARIANT, VARIANT) handler) {
    bool result;
    bind(dispIdFromName(name, result), handler);
  }

  public void bind(char[] name, VARIANT delegate(VARIANT, VARIANT, VARIANT, VARIANT, VARIANT, VARIANT, VARIANT) handler) {
    bool result;
    bind(dispIdFromName(name, result), handler);
  }

  // ID binding methods.

  public void bind(int id, void delegate() handler) {
    DelegateProxy proxy;
    proxy.method = handler;
    bindInternal(id, 0 << 16, proxy);
  }

  public void bind(int id, void delegate(VARIANT) handler) {
    DelegateProxy proxy;
    proxy.method = cast(void delegate())handler;
    bindInternal(id, 1 << 16, proxy);
  }

  public void bind(int id, void delegate(VARIANT, VARIANT) handler) {
    DelegateProxy proxy;
    proxy.method = cast(void delegate())handler;
    bindInternal(id, 2 << 16, proxy);
  }

  public void bind(int id, void delegate(VARIANT, VARIANT, VARIANT) handler) {
    DelegateProxy proxy;
    proxy.method = cast(void delegate())handler;
    bindInternal(id, 3 << 16, proxy);
  }

  public void bind(int id, void delegate(VARIANT, VARIANT, VARIANT, VARIANT) handler) {
    DelegateProxy proxy;
    proxy.method = cast(void delegate())handler;
    bindInternal(id, 4 << 16, proxy);
  }

  public void bind(int id, void delegate(VARIANT, VARIANT, VARIANT, VARIANT, VARIANT) handler) {
    DelegateProxy proxy;
    proxy.method = cast(void delegate())handler;
    bindInternal(id, 5 << 16, proxy);
  }

  public void bind(int id, void delegate(VARIANT, VARIANT, VARIANT, VARIANT, VARIANT, VARIANT) handler) {
    DelegateProxy proxy;
    proxy.method = cast(void delegate())handler;
    bindInternal(id, 6 << 16, proxy);
  }

  public void bind(int id, void delegate(VARIANT, VARIANT, VARIANT, VARIANT, VARIANT, VARIANT, VARIANT) handler) {
    DelegateProxy proxy;
    proxy.method = cast(void delegate())handler;
    bindInternal(id, 7 << 16, proxy);
  }

  public void bind(int id, VARIANT delegate() handler) {
    DelegateProxy proxy;
    proxy.method = cast(void delegate())handler;
    bindInternal(id, 0 << 16, proxy);
  }

  public void bind(int id, VARIANT delegate(VARIANT) handler) {
    DelegateProxy proxy;
    proxy.method = cast(void delegate())handler;
    bindInternal(id, 1 << 16, proxy);
  }

  public void bind(int id, VARIANT delegate(VARIANT, VARIANT) handler) {
    DelegateProxy proxy;
    proxy.method = cast(void delegate())handler;
    bindInternal(id, 2 << 16, proxy);
  }

  public void bind(int id, VARIANT delegate(VARIANT, VARIANT, VARIANT) handler) {
    DelegateProxy proxy;
    proxy.method = cast(void delegate())handler;
    bindInternal(id, 3 << 16, proxy);
  }

  public void bind(int id, VARIANT delegate(VARIANT, VARIANT, VARIANT, VARIANT) handler) {
    DelegateProxy proxy;
    proxy.method = cast(void delegate())handler;
    bindInternal(id, 4 << 16, proxy);
  }

  public void bind(int id, VARIANT delegate(VARIANT, VARIANT, VARIANT, VARIANT, VARIANT) handler) {
    DelegateProxy proxy;
    proxy.method = cast(void delegate())handler;
    bindInternal(id, 5 << 16, proxy);
  }

  public void bind(int id, VARIANT delegate(VARIANT, VARIANT, VARIANT, VARIANT, VARIANT, VARIANT) handler) {
    DelegateProxy proxy;
    proxy.method = cast(void delegate())handler;
    bindInternal(id, 6 << 16, proxy);
  }

  public void bind(int id, VARIANT delegate(VARIANT, VARIANT, VARIANT, VARIANT, VARIANT, VARIANT, VARIANT) handler) {
    DelegateProxy proxy;
    proxy.method = cast(void delegate())handler;
    bindInternal(id, 7 << 16, proxy);
  }

  private void bindInternal(int id, int type, DelegateProxy proxy) {
    synchronized (this) {
      connectEvents();
      handlers_[id][type] = proxy;
    }
  }

  extern (Windows) :

  override int Invoke(int dispidMember, inout GUID riid, uint lcid, ushort wFlags, DISPPARAMS* pdispparams, VARIANT* pvarResult, EXCEPINFO* pexcepinfo, uint* puArgErr) {

     /*void getFunctionInfo(int id, inout FunctionInfo info) {

      ushort getUserDefinedType(ITypeInfo typeInfo, uint userDefinedType) {
        ushort result = VT_USERDEFINED;
        ITypeInfo ti;
        typeInfo.GetRefTypeInfo(userDefinedType, ti);
        TYPEATTR* typeAttr;
        ti.GetTypeAttr(typeAttr);
        if (typeAttr != null && typeAttr.typekind == TYPEKIND.TKIND_ALIAS) {
          if (typeAttr.tdescAlias.vt == VT_USERDEFINED)
            getUserDefinedType(ti, typeAttr.tdescAlias.hreftype);
          else
            result = typeAttr.tdescAlias.vt;
        }
        if (typeAttr != null)
          ti.ReleaseTypeAttr(typeAttr);
        return result;
      }

      FUNCDESC* funcDesc;
      using (com_cast!(ITypeInfo2)(typeInfo_), delegate(ITypeInfo2 ti) {
        if (ti !is null) {
          uint index;
          ti.GetFuncIndexOfMemId(id, INVOKEKIND.INVOKE_FUNC, index);
          typeInfo_.GetFuncDesc(index, funcDesc);
        }
        for (short i = 0; i < funcDesc.cParams; i++) {
          info.paramTypes ~= funcDesc.lprgelemdescParam[i].tdesc.vt;
          if (info.paramTypes[i] == VT_PTR)
            info.paramTypes[i] = funcDesc.lprgelemdescParam[i].tdesc.lptdesc.vt | VT_BYREF;
          if (info.paramTypes[i] == VT_USERDEFINED)
            info.paramTypes[i] = getUserDefinedType(typeInfo_, funcDesc.lprgelemdescParam[i].tdesc.hreftype);
        }

        ushort returnType = funcDesc.elemdescFunc.tdesc.vt;
        if (returnType == VT_INT)
          returnType = VT_I4;
        else if (returnType == VT_UINT)
          returnType = VT_UI4;
        info.returnType = returnType;
        typeInfo_.ReleaseFuncDesc(funcDesc);
      });
    }*/

    int type = pdispparams.cArgs << 16;// | (wFlags & 15);
    if (auto entry = dispidMember in handlers_) {
      if (auto proxy = type in *entry) {

        /*FunctionInfo functionInfo;
        auto pFunctionInfo = proxy.methodInfo;
        if (pFunctionInfo == null) {
          pFunctionInfo = &functionInfo;
          getFunctionInfo(dispidMember, functionInfo);
        }
        bool hasReturn = functionInfo.returnType != VT_VOID;*/
        bool hasReturn = proxy.hasReturn;
        VARIANT result;

        try {

          switch (pdispparams.cArgs) {
            case 0:
              if (hasReturn)
                result = (cast(VARIANT delegate())proxy.method)();
              else
                proxy.method();
              break;
            case 1:
              if (hasReturn)
                result = (cast(VARIANT delegate(VARIANT))proxy.method)(pdispparams.rgvarg[0]);
              else
                (cast(void delegate(VARIANT))proxy.method)(pdispparams.rgvarg[0]);
              break;
            case 2:
              if (hasReturn)
                result = (cast(VARIANT delegate(VARIANT, VARIANT))proxy.method)(pdispparams.rgvarg[1], pdispparams.rgvarg[0]);
              else
                (cast(void delegate(VARIANT, VARIANT))proxy.method)(pdispparams.rgvarg[1], pdispparams.rgvarg[0]);
              break;
            case 3:
              if (hasReturn)
                result = (cast(VARIANT delegate(VARIANT, VARIANT, VARIANT))proxy.method)(pdispparams.rgvarg[2], pdispparams.rgvarg[1], pdispparams.rgvarg[0]);
              else
                (cast(void delegate(VARIANT, VARIANT, VARIANT))proxy.method)(pdispparams.rgvarg[2], pdispparams.rgvarg[1], pdispparams.rgvarg[0]);
              break;
            case 4:
              if (hasReturn)
                result = (cast(VARIANT delegate(VARIANT, VARIANT, VARIANT, VARIANT))proxy.method)(pdispparams.rgvarg[3], pdispparams.rgvarg[2], pdispparams.rgvarg[1], pdispparams.rgvarg[0]);
              else
                (cast(void delegate(VARIANT, VARIANT, VARIANT, VARIANT))proxy.method)(pdispparams.rgvarg[3], pdispparams.rgvarg[2], pdispparams.rgvarg[1], pdispparams.rgvarg[0]);
              break;
            case 5:
              if (hasReturn)
                result = (cast(VARIANT delegate(VARIANT, VARIANT, VARIANT, VARIANT, VARIANT))proxy.method)(pdispparams.rgvarg[4], pdispparams.rgvarg[3], pdispparams.rgvarg[2], pdispparams.rgvarg[1], pdispparams.rgvarg[0]);
              else
                (cast(void delegate(VARIANT, VARIANT, VARIANT, VARIANT, VARIANT))proxy.method)(pdispparams.rgvarg[4], pdispparams.rgvarg[3], pdispparams.rgvarg[2], pdispparams.rgvarg[1], pdispparams.rgvarg[0]);
              break;
            case 6:
              if (hasReturn)
                result = (cast(VARIANT delegate(VARIANT, VARIANT, VARIANT, VARIANT, VARIANT, VARIANT))proxy.method)(pdispparams.rgvarg[5], pdispparams.rgvarg[4], pdispparams.rgvarg[3], pdispparams.rgvarg[2], pdispparams.rgvarg[1], pdispparams.rgvarg[0]);
              else
                (cast(void delegate(VARIANT, VARIANT, VARIANT, VARIANT, VARIANT, VARIANT))proxy.method)(pdispparams.rgvarg[5], pdispparams.rgvarg[4], pdispparams.rgvarg[3], pdispparams.rgvarg[2], pdispparams.rgvarg[1], pdispparams.rgvarg[0]);
              break;
            case 7:
              if (hasReturn)
                result = (cast(VARIANT delegate(VARIANT, VARIANT, VARIANT, VARIANT, VARIANT, VARIANT, VARIANT))proxy.method)(pdispparams.rgvarg[6], pdispparams.rgvarg[5], pdispparams.rgvarg[4], pdispparams.rgvarg[3], pdispparams.rgvarg[2], pdispparams.rgvarg[1], pdispparams.rgvarg[0]);
              else
                (cast(void delegate(VARIANT, VARIANT, VARIANT, VARIANT, VARIANT, VARIANT, VARIANT))proxy.method)(pdispparams.rgvarg[6], pdispparams.rgvarg[5], pdispparams.rgvarg[4], pdispparams.rgvarg[3], pdispparams.rgvarg[2], pdispparams.rgvarg[1], pdispparams.rgvarg[0]);
              break;
            default:
              return super.Invoke(dispidMember, riid, lcid, wFlags, pdispparams, pvarResult, pexcepinfo, puArgErr);
          }
          if (pvarResult != null)
            *pvarResult = result;
        }
        catch {
          return E_FAIL;
        }
        return S_OK;
      }
    }
    return super.Invoke(dispidMember, riid, lcid, wFlags, pdispparams, pvarResult, pexcepinfo, puArgErr);
  }

}

private import std.stdio, std.conv, std.string;

/* Late Binding */

class Automator {

  private IDispatch obj_;
  private int[char[]] names_;

  private this(IDispatch obj) {
    obj_ = obj;
  }

  ~this() {
    if (obj_ !is null) {
      try {
        obj_.Release();
      }
      catch {
      }
    }
  }

  public static Automator createInstance(char[] className) {
    GUID clsid;
    CLSIDFromProgID(className.toUtf16z(), clsid);

    void* p;
    int hr;
    if ((hr = CoCreateInstance(clsid, null, CLSCTX_INPROC_SERVER | CLSCTX_LOCAL_SERVER, IDispatch.IID, p)) != S_OK)
      throw new COMException(hr);

    return new Automator(cast(IDispatch)p);
  }

  public static Automator getInstance(char[] className) {
    GUID clsid;
    CLSIDFromProgID(className.toUtf16z(), clsid);

    void* p;
    int hr;
    if ((hr = GetActiveObject(clsid, null, p)) != S_OK)
      throw new COMException(hr);

    return new Automator(cast(IDispatch)p);
  }

  public VARIANT invokeMethod(char[] member, ...) {
    int dispId;
    if (findMemberId(member, dispId)) {
      auto it = ArgumentIterator(_arguments, _argptr);
      VARIANT[] args = variantsFromVarArgs(it);
      DISPPARAMS params;
      params.rgvarg = args;
      params.cArgs = args.length;

      VARIANT result;
      obj_.Invoke(dispId, INull.IID, 0, DISPATCH_METHOD, &params, &result, null, null);

      foreach (VARIANT arg; args)
        arg.clear();

      return result;
    }
    else
      throw new Exception("Method '" ~ member ~ "' is not supported.");
    return VARIANT.init;
  }

  public VARIANT getProperty(char[] member) {
    int dispId;
    if (findMemberId(member, dispId)) {
      DISPPARAMS params;
      VARIANT result;
      obj_.Invoke(dispId, INull.IID, 0, DISPATCH_PROPERTYGET, &params, &result, null, null);
      return result;
    }
    else
      throw new Exception("Method '" ~ member ~ "' is not supported.");
  }

  public void setProperty(char[] member, ...) {
    assert(_arguments.length == 1);

    int dispId;
    findMemberId(member, dispId);
    if (findMemberId(member, dispId)) {
      auto it = ArgumentIterator(_arguments, _argptr);
      VARIANT[] args = variantsFromVarArgs(it);
      if (args != null) {
        VARIANT arg = args[0];
        int dispIdPut = DISPID_PROPERTYPUT;
        DISPPARAMS params;
        params.rgvarg = &arg;
        params.cArgs = 1;
        params.cNamedArgs = 1;
        params.rgdispidNamedArgs = &dispIdPut;

        ushort flags = (arg.vt == VT_UNKNOWN || arg.vt == VT_DISPATCH) ? DISPATCH_PROPERTYPUTREF : DISPATCH_PROPERTYPUT;
        obj_.Invoke(dispId, INull.IID, 0, flags, &params, null, null, null);

        arg.clear();
      }
      else
        throw new Exception("Argument cannot be null.");
    }
    else
      throw new Exception("Method '" ~ member ~ "' is not supported.");
  }

  private bool findMemberId(char[] name, out int result) {
    char[] n = name.tolower();
    if (auto id = n in names_) {
      result = *id;
      return true;
    }

    wchar* pszName = n.toUtf16z();
    if (obj_.GetIDsOfNames(INull.IID, &pszName, 1, 0, &result) == S_OK) {
      names_[n] = result;
      return true;
    }
    return false;
  } 

  private VARIANT[] variantsFromVarArgs(inout ArgumentIterator it) {
    VARIANT[] result;
    foreach (Argument arg; it) {
      TypeInfo type = arg.getType();
      if (type !is null) {
        if (type is typeid(bool))
          result ~= VARIANT(*cast(bool*)arg.getValue());
        else if (type is typeid(byte))
          result ~= VARIANT(*cast(byte*)arg.getValue());
        else if (type is typeid(ubyte))
          result ~= VARIANT(*cast(ubyte*)arg.getValue());
        else if (type is typeid(short))
          result ~= VARIANT(*cast(short*)arg.getValue());
        else if (type is typeid(ushort))
          result ~= VARIANT(*cast(ushort*)arg.getValue());
        else if (type is typeid(int))
          result ~= VARIANT(*cast(int*)arg.getValue());
        else if (type is typeid(uint))
          result ~= VARIANT(*cast(uint*)arg.getValue());
        else if (type is typeid(long))
          result ~= VARIANT(*cast(long*)arg.getValue());
        else if (type is typeid(ulong))
          result ~= VARIANT(*cast(ulong*)arg.getValue());
        else if (type is typeid(float))
          result ~= VARIANT(*cast(float*)arg.getValue());
        else if (type is typeid(double))
          result ~= VARIANT(*cast(double*)arg.getValue());
        else if (type is typeid(char[]))
          result ~= VARIANT(*cast(char[]*)arg.getValue());
        else if (type is typeid(IUnknown))
          result ~= VARIANT(*cast(IUnknown*)arg.getValue());
        else if (type is typeid(IDispatch))
          result ~= VARIANT(*cast(IDispatch*)arg.getValue());
        else if (type is typeid(Object)) {
          if (auto disp = *cast(IDispatch*)arg.getValue())
            result ~= VARIANT(disp);
        }
        else if (type is typeid(VARIANT))
          result ~= *cast(VARIANT*)arg.getValue();
      }
    }
    return result;
  }

}

interface IReleasable(T) {
  void release();
  bool isReleased();
  T opCast();
}

template releasingRef(I) {

  IReleasable!(I) releasingRef(I obj) {
    return new class(obj) IReleasable!(I) {
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
      bool isReleased() {
        return released;
      }
      I opCast() {
        return obj;
      }
    };
  }

}

VARIANT simpleHandler(void delegate() del) {
  return (new class(new SimpleEventProvider(del)) Object {
    VARIANT v;
    this(SimpleEventProvider func) {
      v = VARIANT(func);
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

struct safearray(T, int R = 1) {

  SafeArray!(T, R) array_;

  const uint rank = R;

  static safearray opCall(uint[] lengths ...) {
    safearray a;
    a.array_ = new SafeArray!(T, R)(lengths);
    return a;
  }

  T opIndex(int[] indices ...) {
    return array_.opIndex(indices);
  }

  void opIndexAssign(T value, int[] indices ...) {
    array_.opIndexAssign(value, indices);
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