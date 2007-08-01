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

module juno.com.client;

private import juno.base.core,
  juno.base.string,
  juno.base.native,
  juno.com.core,
  juno.utils.registry;

private import std.stdarg;
private import std.string : tolower;
private import std.c.string : memcpy;

public class MissingMemberException : BaseException {

  private string className_;
  private string memberName_;

  public this(string message = "Member not found.") {
    super(message);
  }

  public this(string className, string memberName) {
    className_ = className;
    memberName_ = memberName;
  }

  public override string message() {
    if (className_ == null)
      return super.message;
    return "Member '" ~ className_ ~ "." ~ memberName_ ~ "' not found.";
  }

  public string memberName() {
    return memberName_;
  }

}

public class MissingMethodException : MissingMemberException {

  public this(string message = "Method not found.") {
    super(message);
  }

  public this(string className, string methodName) {
    super(className, methodName);
  }

}

public enum DispatchFlags {
  InvokeMethod = DISPATCH_METHOD,
  GetProperty = DISPATCH_PROPERTYGET,
  PutProperty = DISPATCH_PROPERTYPUT
}

private VARIANT invokeMemberById(int dispId, DispatchFlags flags, IDispatch target, ...) {

  VARIANT[] argsToVariants(TypeInfo[] args, va_list argptr) {
    VARIANT[] list;

    foreach (arg; args) {
      if (arg == typeid(bool))
        list ~= VARIANT(va_arg!(bool)(argptr));
      else if (arg == typeid(ubyte))
        list ~= VARIANT(va_arg!(ubyte)(argptr));
      else if (arg == typeid(byte))
        list ~= VARIANT(va_arg!(byte)(argptr));
      else if (arg == typeid(ushort))
        list ~= VARIANT(va_arg!(ushort)(argptr));
      else if (arg == typeid(short))
        list ~= VARIANT(va_arg!(short)(argptr));
      else if (arg == typeid(uint))
        list ~= VARIANT(va_arg!(uint)(argptr));
      else if (arg == typeid(int))
        list ~= VARIANT(va_arg!(int)(argptr));
      else if (arg == typeid(ulong))
        list ~= VARIANT(va_arg!(ulong)(argptr));
      else if (arg == typeid(long))
        list ~= VARIANT(va_arg!(long)(argptr));
      else if (arg == typeid(float))
        list ~= VARIANT(va_arg!(float)(argptr));
      else if (arg == typeid(double))
        list ~= VARIANT(va_arg!(double)(argptr));
      else if (arg == typeid(string))
        list ~= VARIANT(va_arg!(string)(argptr));
      else if (arg == typeid(IDispatch))
        list ~= VARIANT(va_arg!(IDispatch)(argptr));
      else if (arg == typeid(IUnknown))
        list ~= VARIANT(va_arg!(IUnknown)(argptr));
      else if (arg == typeid(Object))
        list ~= VARIANT(va_arg!(Object)(argptr));
      else if (arg == typeid(VARIANT*)) {
        VARIANT v;
        v.vt = cast(VARTYPE)(VARTYPE.VT_BYREF | VARTYPE.VT_VARIANT);
        v.pvarVal = va_arg!(VARIANT*)(argptr);
        list ~= v;
      }
      else if (arg == typeid(SAFEARRAY*)) {
        VARIANT v;
        v.vt = cast(VARTYPE)(VARTYPE.VT_ARRAY | VARTYPE.VT_VARIANT);
        v.parray = va_arg!(SAFEARRAY*)(argptr);
        list ~= v;
      }
    }

    return list.reverse;
  }

  TypeInfo[] args = _arguments;
  va_list argptr = _argptr;

  if (args.length == 2) {
    if (args[0] == typeid(TypeInfo[]) && args[1] == typeid(va_list)) {
      args = va_arg!(TypeInfo[])(argptr);
      argptr = *cast(va_list*)(argptr);
    }
  }

  if ((flags & DispatchFlags.PutProperty) != 0 && args.length > 1) {
    VARIANT var = invokeMemberById(dispId, DispatchFlags.GetProperty, target);
    if (auto indexer = var.pdispVal) {
      try {
        var = invokeMemberById(0, DispatchFlags.GetProperty, indexer, args[0 .. 1], argptr);
        if (auto value = var.pdispVal) {
          try {
            return invokeMemberById(0, DispatchFlags.PutProperty, value, args[1 .. $], argptr + args[0].tsize());
          }
          finally {
            tryRelease(value);
          }
        }
      }
      finally {
        tryRelease(indexer);
      }
    }
  }

  DISPPARAMS params;
  VARIANT[] vargs = argsToVariants(args, argptr);

  if (vargs.length > 0) {
    params.rgvarg = vargs.ptr;
    params.cArgs = vargs.length;

    if ((flags & DispatchFlags.PutProperty) != 0) {
      int dispIdNamed = DISPID_PROPERTYPUT;
      params.rgdispidNamedArgs = &dispIdNamed;
      params.cNamedArgs = 1;
    }
  }

  VARIANT result;
  EXCEPINFO excep;
  int hr = target.Invoke(dispId, GUID.empty, LOCALE_USER_DEFAULT, cast(ushort)flags, &params, &result, &excep, null);

  if (params.cArgs > 0) {
    for (uint i = 0; i < params.cArgs; i++) {
      params.rgvarg[i].clear();
    }
  }

  return result;
}

public TResult invokeMember(TResult = VARIANT)(string name, DispatchFlags flags, IDispatch target, ...) {
  if (target is null)
    throw new ArgumentNullException("target");

  TypeInfo[] args = _arguments;
  va_list argptr = _argptr;

  if (args.length == 2) {
    if (args[0] == typeid(TypeInfo[]) && args[1] == typeid(va_list)) {
      args = va_arg!(TypeInfo[])(argptr);
      argptr = *cast(va_list*)(argptr);
    }
  }

  int dispId = DISPID_UNKNOWN;
  wchar* bstrMemberName = name.toBStr();
  int hr = target.GetIDsOfNames(GUID.empty, &bstrMemberName, 1, LOCALE_USER_DEFAULT, &dispId);
  freeBStr(bstrMemberName);

  if (SUCCEEDED(hr) && dispId != DISPID_UNKNOWN) {
    VARIANT result = invokeMemberById(dispId, flags, target, args, argptr);
    static if (is(TResult == VARIANT))
      return result;
    else
      return com_cast!(TResult)(result);
  }

  string typeName;
  ITypeInfo typeInfo;

  if (SUCCEEDED(target.GetTypeInfo(0, LOCALE_USER_DEFAULT, typeInfo))) {
    wchar* bstrTypeName;
    typeInfo.GetDocumentation(-1, &bstrTypeName, null, null, null);
    typeName = fromBStr(bstrTypeName);

    tryRelease(typeInfo);
  }

  throw new MissingMemberException(typeName, name);

}

/**
 * Example:
 * ---
 * abstract final class InternetExplorer {
 *
 *   static class Application : DispatchObject {
 *
 *     this() {
 *       super("InternetExplorer.Application");
 *     }
 *
 *     void visible(bool value) {
 *       set("Visible", value);
 *     }
 *
 *     bool visible() {
 *       return get!(bool)("Visible");
 *     }
 *
 *     void navigate(string url) {
 *       call("Navigate", url);
 *     }
 *
 *   }
 *
 * }
 *
 * void main() {
 *   scope ie = new InternetExplorer.Application;
 *   ie.visible = true;
 *   ie.navigate("www.google.com");
 * }
 * ---
 */

public class DispatchObject {

  private IDispatch target_;

  /**
   * Params: progId = The identifier.
   */
  public this(string progId) {
    target_ = coCreate!(IDispatch)(progId, ExecutionContext.InProcessServer | ExecutionContext.LocalServer);
    if (target_ is null)
      throw new InvalidOperationException;
  }

  ~this() {
    release();
  }

  /**
   * Params: target = The object.
   */
  public static DispatchObject attach(IDispatch target) {
    return new DispatchObject(target);
  }

  /**
   * Params: target = The object.
   */
  public static DispatchObject attach(VARIANT target) {
    return new DispatchObject(safe_com_cast!(IDispatch)(target));
  }

  /**
   * Releases the target.
   */
  public final void release() {
    if (target_ !is null) {
      tryRelease(target_);
      target_ = null;
    }
  }

  /**
   * Calls the method specified by name using the specified arguments.
   */
  public TResult call(TResult = VARIANT)(string name, ...) {
    return invokeMember!(TResult)(name, DispatchFlags.InvokeMethod, target_, _arguments, _argptr);
  }

  /**
   * Calls the _get accessor specified by name using the specified arguments.
   */
  public TResult get(TResult = VARIANT)(string name, ...) {
    return invokeMember!(TResult)(name, DispatchFlags.GetProperty, target_, _arguments, _argptr);
  }

  /**
   * Calls the _set accessor specified by name using the specified arguments.
   */
  public void set(string name, ...) {
    invokeMember(name, DispatchFlags.PutProperty, target_, _arguments, _argptr);
  }

  /**
   * Retrieves the _target.
   */
  public final IDispatch target() {
    return target_;
  }

  private this(IDispatch target) {
    target_ = target;
  }

}

private struct SinkInfo {

  int delegate() method;
  VARTYPE returnType;
  VARTYPE[] paramTypes;

  static SinkInfo opCall(R, T ...)(R delegate(T) method) {
    alias ParameterTypeTuple!(method) params;

    SinkInfo si;
    si.method = cast(int delegate())method;
    si.returnType = VariantType!(R);
    si.paramTypes.length = params.length;

    foreach (i, paramType; params) {
      si.paramTypes[i] = VariantType!(paramType);
    }

    return si;
  }

  int invoke(VARIANT*[] args, VARIANT* result) {

    uint sizeOf(VARTYPE vt) {
      switch (vt) {
        case VARTYPE.VT_UI8, VARTYPE.VT_I8, VARTYPE.VT_CY:
          return long.sizeof / uint.sizeof;
        case VARTYPE.VT_R8:
          return double.sizeof / uint.sizeof;
        case VARTYPE.VT_VARIANT:
          return (VARIANT.sizeof + 3) / uint.sizeof;
        default:
      }
      return 1;
    }

    bool copyVariant(uint* ptr, VARIANT* var, VARTYPE vt) {
      uint size = sizeOf(vt) * uint.sizeof;
      if (var.vt == vt) {
        memcpy(ptr, &var.lVal, size);
        return true;
      }
      if (vt == VARTYPE.VT_VARIANT) {
        memcpy(ptr, var, size);
        return true;
      }
      if ((var.vt & VARTYPE.VT_BYREF) && (var.vt & ~VARTYPE.VT_BYREF) == vt) {
        memcpy(ptr, cast(void*)var.lVal, size);
        return true;
      }
      if (vt == VARTYPE.VT_UNKNOWN && var.vt == VARTYPE.VT_DISPATCH) {
        memcpy(ptr, &var.lVal, size);
        return true;
      }
      VARIANT v;
      if (VariantChangeType(&v, var, 0, vt) == S_OK) {
        memcpy(ptr, &var.lVal, size);
        return true;
      }
      return false;
    }

    int invokeMethod(int delegate() method, uint count, uint* ptr) {
      bool hasReturn = (returnType != VARTYPE.VT_VOID);
      int hr = DISP_E_BADPARAMCOUNT;

      switch (count) {
        case 0:
          return hr = method(), hasReturn ? hr : S_OK;
        case 1:
          return hr = (cast(int delegate(uint))method)(ptr[0]), hasReturn ? hr : S_OK;
        case 2:
          return hr = (cast(int delegate(uint, uint))method)(ptr[0], ptr[1]), hasReturn ? hr : S_OK;
        case 3:
          return hr = (cast(int delegate(uint, uint, uint))method)(ptr[0], ptr[1], ptr[2]), hasReturn ? hr : S_OK;
        case 4:
          return hr = (cast(int delegate(uint, uint, uint, uint))method)(ptr[0], ptr[1], ptr[2], ptr[3]), hasReturn ? hr : S_OK;
        case 5:
          return hr = (cast(int delegate(uint, uint, uint, uint, uint))method)(ptr[0], ptr[1], ptr[2], ptr[3], ptr[4]), hasReturn ? hr : S_OK;
        case 6:
          return hr = (cast(int delegate(uint, uint, uint, uint, uint, uint))method)(ptr[0], ptr[1], ptr[2], ptr[3], ptr[4], ptr[5]), hasReturn ? hr : S_OK;
        case 7:
          return hr = (cast(int delegate(uint, uint, uint, uint, uint, uint, uint))method)(ptr[0], ptr[1], ptr[2], ptr[3], ptr[4], ptr[5], ptr[6]), hasReturn ? hr : S_OK;
        case 8:
          return hr = (cast(int delegate(uint, uint, uint, uint, uint, uint, uint, uint))method)(ptr[0], ptr[1], ptr[2], ptr[3], ptr[4], ptr[5], ptr[6], ptr[7]), hasReturn ? hr : S_OK;
        case 9:
          return hr = (cast(int delegate(uint, uint, uint, uint, uint, uint, uint, uint, uint))method)(ptr[0], ptr[1], ptr[2], ptr[3], ptr[4], ptr[5], ptr[6], ptr[7], ptr[8]), hasReturn ? hr : S_OK;
        case 10:
          return hr = (cast(int delegate(uint, uint, uint, uint, uint, uint, uint, uint, uint, uint))method)(ptr[0], ptr[1], ptr[2], ptr[3], ptr[4], ptr[5], ptr[6], ptr[7], ptr[8], ptr[9]), hasReturn ? hr : S_OK;
        case 11:
          return hr = (cast(int delegate(uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint))method)(ptr[0], ptr[1], ptr[2], ptr[3], ptr[4], ptr[5], ptr[6], ptr[7], ptr[8], ptr[9], ptr[10]), hasReturn ? hr : S_OK;
        case 12:
          return hr = (cast(int delegate(uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint))method)(ptr[0], ptr[1], ptr[2], ptr[3], ptr[4], ptr[5], ptr[6], ptr[7], ptr[8], ptr[9], ptr[10], ptr[11]), hasReturn ? hr : S_OK;
        default:
      }

      return hr;
    }

    uint count = 0;
    for (int i = 0; i < paramTypes.length; i++) {
      count += sizeOf(paramTypes[i]);
    }

    auto ptr = cast(uint*)HeapAlloc(GetProcessHeap(), 0, count * uint.sizeof);

    uint offset = 0;
    for (int i = 0; i < paramTypes.length; i++) {
      VARIANT* pArg = args[i];
      copyVariant(ptr + offset, pArg, paramTypes[i]);
      offset += sizeOf(paramTypes[i]);
    }

    int hr = invokeMethod(method, count, ptr);

    if (result != null && returnType != VARTYPE.VT_VOID) {
      result.vt = returnType;
      result.lVal = hr;
    }

    HeapFree(GetProcessHeap(), 0, ptr);
    return S_OK;
  }

}

public class EventProvider(T) : Implements!(T) {

  extern (D):

  private int[string] nameTable_;
  private SinkInfo[int] sinkTable_;

  private IConnectionPoint connectionPoint_;
  private uint cookie_;

  public this(IUnknown source) {
    auto cpc = safe_com_cast!(IConnectionPointContainer)(source);
    if (cpc !is null) {
      releaseAfter (cpc, {
        if (cpc.FindConnectionPoint(T.IID, connectionPoint_) != S_OK)
          throw new ArgumentException("Source object does not expose '" ~ T.stringof ~ "' event interface.");

        if (connectionPoint_.Advise(this, cookie_) != S_OK) {
          cookie_ = 0;
          tryRelease(connectionPoint_);
          throw new InvalidOperationException("Could not Advise() the event interface '" ~ T.stringof ~ "'.");
        }
      });
    }

    if (connectionPoint_ is null || cookie_ == 0) {
      if (connectionPoint_ !is null)
        tryRelease(connectionPoint_);
      throw new ArgumentException("Connection point for event interface '" ~ T.stringof ~ "' cannot be created.");
    }
  }

  ~this() {
    if (connectionPoint_ !is null && cookie_ != 0) {
      try {
        connectionPoint_.Unadvise(cookie_);
      }
      finally {
        tryRelease(connectionPoint_);
        connectionPoint_ = null;
        cookie_ = 0;
      }
    }
  }

  public void attach(ID, TResult, TParams ...)(ID member, TResult delegate(TParams) handler) {
    static if (is(ID : string)) {
      bool found;
      int dispId = DISPID_UNKNOWN;
      if (tryFindDispId(member, dispId))
        attach(dispId, handler);
      else
        throw new ArgumentException("Member '" ~ member ~ "' not found in type '" ~ T.stringof ~ "'.");
    }
    else static if (is(ID : int)) {
      SinkInfo s = handler;
      sinkTable_[member] = s;
    }
  }

  private bool tryFindDispId(string name, out int dispId) {

    void initNameTable() {
      scope clsidKey = RegistryKey.classesRoot.openSubKey("Interface\\" ~ T.IID.toString());
      if (clsidKey !is null) {
        scope typeLibRefKey = clsidKey.openSubKey("TypeLib");
        if (typeLibRefKey !is null) {
          string typeLibVersion = typeLibRefKey.getValue!(string)("Version");
          if (typeLibRefKey == null) {
            scope versionKey = clsidKey.openSubKey("Version");
            if (versionKey !is null)
              typeLibVersion = versionKey.getValue!(string)(null);
          }

          scope typeLibKey = RegistryKey.classesRoot.openSubKey("TypeLib\\" ~ typeLibRefKey.getValue!(string)(null));
          if (typeLibKey !is null) {
            scope pathKey = typeLibKey.openSubKey(typeLibVersion ~ "\\0\\Win32");
            if (pathKey !is null) {
              ITypeLib typeLib = null;
              if (LoadTypeLib(pathKey.getValue!(string)(null).toUtf16z(), typeLib) == S_OK) {
                scope (exit) tryRelease(typeLib);

                ITypeInfo typeInfo = null;
                if (typeLib.GetTypeInfoOfGuid(T.IID, typeInfo) == S_OK) {
                  scope (exit) tryRelease(typeInfo);

                  TYPEATTR* typeAttr;
                  if (typeInfo.GetTypeAttr(typeAttr) == S_OK) {
                    scope (exit) typeInfo.ReleaseTypeAttr(typeAttr);

                    for (uint i = 0; i < typeAttr.cFuncs; i++) {
                      FUNCDESC* funcDesc;
                      if (typeInfo.GetFuncDesc(i, funcDesc) == S_OK) {
                        scope (exit) typeInfo.ReleaseFuncDesc(funcDesc);

                        wchar* bstrName;
                        if (typeInfo.GetDocumentation(funcDesc.memid, &bstrName, null, null, null) == S_OK) {
                          string memberName = fromBStr(bstrName);
                          nameTable_[memberName.tolower()] = funcDesc.memid;
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    dispId = DISPID_UNKNOWN;
    
    if (nameTable_ == null)
      initNameTable();

    if (auto value = name.tolower() in nameTable_) {
      dispId = *value;
      return true;
    }

    return false;
  }

  extern (Windows)
  override int Invoke(int dispIdMember, ref GUID riid, uint lcid, ushort wFlags, DISPPARAMS* pDispParams, VARIANT* pVarResult, EXCEPINFO* pExcepInfo, uint* puArgErr) {
    if (auto handler = dispIdMember in sinkTable_) {
      VARIANT*[8] args;
      for (int i = 0; i < handler.paramTypes.length && i < 8; i++) {
        args[i] = &pDispParams.rgvarg[handler.paramTypes.length - i - 1];
      }

      VARIANT result;
      if (pVarResult == null)
        pVarResult = &result;

      int hr = handler.invoke(args, pVarResult);

      for (int i = 0; i < handler.paramTypes.length; i++) {
        if (args[i].vt == (VARTYPE.VT_BYREF | VARTYPE.VT_BOOL)) {
          // Fix bools to VARIANT_BOOL.
          if (*args[i].pboolVal == 1)
            *args[i].pboolVal = VARIANT_TRUE;
        }
      }

      return hr;
    }
    return DISP_E_MEMBERNOTFOUND;
  }

}