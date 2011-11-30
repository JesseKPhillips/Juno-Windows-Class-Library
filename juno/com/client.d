/**
 * Provides additional support for COM (Component Object Model).
 *
 * Copyright: (c) 2009 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.com.client;

import juno.base.core,
  juno.base.string,
  juno.base.native,
  juno.utils.registry,
  juno.com.core;
import std.traits : ParameterTypeTuple;

/**
 * Represents a late-bound COM object.
 *
 * Examples:
 * Automating CDOSYS:
 * ---
 * // Create an instance of the Message object
 * scope message = new DispatchObject("CDO.Message");
 *
 * // Build the mail message
 * message.set("Subject", "Hello, World!");
 * message.set("TextBody", "Just saying hello.");
 * message.set("From", "me@home.com"); // Replace 'me@home.com' with your email address
 * message.set("To", "world@large.com"); // Replace 'world@large.com' with the recipient's email address
 *
 * // Configure CDOSYS to send via a remote SMTP server
 * scope config = message.get("Configuration");
 * // Set the appropriate values
 * config.set("Fields", "http://schemas.microsoft.com/cdo/configuration/sendusing", 2); // cdoSendUsingPort = 2
 * config.set("Fields", "http://schemas.microsoft.com/cdo/configuration/smtpserverport", 25);
 * config.set("Fields", "http://schemas.microsoft.com/cdo/configuration/smtpserver", "mail.remote.com"); // Replace 'mail.remote.com' with your remote server's address
 * config.set("Fields", "http://schemas.microsoft.com/cdo/configuration/smtpauthenticate", 1); // cdoBasic = 1
 * config.set("Fields", "http://schemas.microsoft.com/cdo/configuration/sendusername", "username"); // Replace 'username' with your account's user name
 * config.set("Fields", "http://schemas.microsoft.com/cdo/configuration/sendpassword", "password"); // Replace 'password' with your account's password
 *
 * scope fields = config.get("Fields");
 * fields.call("Update");
 *
 * message.call("Send");
 * ---
 * Automating Microsoft Office Excel:
 * ---
 * void main() {
 *   // Create an instance of the Excel application object and set the Visible property to true.
 *   scope excel = new DispatchObject("Excel.Application");
 *   excel.set("Visible", true);
 *
 *   // Get the Workbooks property, then call the Add method.
 *   scope workbooks = excel.get("Workbooks");
 *   scope workbook = workbooks.call("Add");
 *
 *   // Get the Worksheet at index 1, then set the Cells at column 5, row 3 to a string.
 *   scope worksheet = excel.get("Worksheets", 1);
 *   worksheet.set("Cells", 5, 3, "data");
 * }
 * ---
 * Automating Internet Explorer:
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
class DispatchObject {

  private IDispatch target_;
  private VARIANT result_;

  /**
   */
  this(Guid clsid, ExecutionContext context = ExecutionContext.InProcessServer | ExecutionContext.LocalServer) {
    target_ = coCreate!(IDispatch)(clsid, context);
    if (target_ is null)
      throw new InvalidOperationException;
  }

  /**
   */
  this(Guid clsid, string server, ExecutionContext context = ExecutionContext.InProcessServer | ExecutionContext.RemoteServer) {
    target_ = coCreateEx!(IDispatch)(clsid, server, context);
    if (target_ is null)
      throw new InvalidOperationException;
  }

  /**
   */
  this(string progId, ExecutionContext context = ExecutionContext.InProcessServer | ExecutionContext.LocalServer) {
    target_ = coCreate!(IDispatch)(progId, context);
    if (target_ is null)
      throw new InvalidOperationException;
  }

  /**
   */
  this(string progId, string server, ExecutionContext context = ExecutionContext.InProcessServer | ExecutionContext.RemoteServer) {
    target_ = coCreateEx!(IDispatch)(progId, server, context);
    if (target_ is null)
      throw new InvalidOperationException;
  }

  /**
   */
  this(IDispatch target) {
    if (target is null)
      throw new ArgumentNullException("target");

    target.AddRef();
    target_ = target;
  }

  /**
   * ditto
   */
  this(VARIANT result) {
    if (auto target = com_cast!(IDispatch)(result)) {
      target_ = target;
    }
  }

  private this(VARIANT result, uint ignore) {
    if (auto target = com_cast!(IDispatch)(result)) {
      target_ = target;
    }
    result_ = result;
  }

  ~this() {
    release();
  }

  /**
   */
  final void release() {
    if (!(result_.isNull || result_.isEmpty))
      result_.clear();

    if (target_ !is null) {
      tryRelease(target_);
      target_ = null;
    }
  }

  /**
   */
  R call(R = DispatchObject)(string name, ...) {
    static if (is(R == DispatchObject)) {
      return new DispatchObject(invokeMethod(target_, name, _arguments, _argptr), 0);
    }
    else {
      R ret = invokeMethod!(R)(target_, name, _arguments, _argptr);
      result_ = ret;
      return ret;
    }
  }

  /**
   */
  R get(R = DispatchObject)(string name, ...) {
    static if (is(R == DispatchObject)) {
      return new DispatchObject(getProperty(target_, name, _arguments, _argptr), 0);
    }
    else {
      R ret = getProperty!(R)(target_, name, _arguments, _argptr);
      result_ = ret;
      return ret;
    }
  }

  /**
   */
  void set(string name, ...) {
    setProperty(target_, name, _arguments, _argptr);
  }

  /**
   */
  void setRef(string name, ...) {
    setRefProperty(target_, name, _arguments, _argptr);
  }

  /**
   */
  final IDispatch target() {
    return target_;
  }

  /**
   */
  final VARIANT result() {
    return result_;
  }

}

/**
 */
class EventCookie(T) {

  private IConnectionPoint cp_;
  private uint cookie_;

  /**
   */
  this(IUnknown source) {
    auto cpc = com_cast!(IConnectionPointContainer)(source);
    if (cpc !is null) {
      scope(exit) tryRelease(cpc);

      if (cpc.FindConnectionPoint(uuidof!(T), cp_) != S_OK)
        throw new ArgumentException("Source object does not expose '" ~ T.stringof ~ "' event interface.");
    }
  }

  ~this() {
    disconnect();
  }

  /**
   */
  void connect(IUnknown sink) {
    if (cp_.Advise(sink, cookie_) != S_OK) {
      cookie_ = 0;
      tryRelease(cp_);
      throw new InvalidOperationException("Could not Advise() the event interface '" ~ T.stringof ~ "'.");
    }

    if (cp_ is null || cookie_ == 0) {
      if (cp_ !is null)
        tryRelease(cp_);
      throw new ArgumentException("Connection point for event interface '" ~ T.stringof ~ "' cannot be created.");
    }
  }

  /**
   */
  void disconnect() {
    if (cp_ !is null && cookie_ != 0) {
      try {
        cp_.Unadvise(cookie_);
      }
      finally {
        tryRelease(cp_);
        cp_ = null;
        cookie_ = 0;
      }
    }
  }

}

private struct MethodProxy {

  int delegate() method;
  VARTYPE returnType;
  VARTYPE[] paramTypes;

  static MethodProxy opCall(R, T...)(R delegate(T) method) {
    MethodProxy self;
    self = method;
    return self;
  }

  void opAssign()(MethodProxy mp) {
	  this = mp;
  }

  void opAssign(R, T...)(R delegate(T) dg) {
    alias ParameterTypeTuple!(dg) params;

    method = cast(int delegate())dg;
    returnType = VariantType!(R);
    paramTypes.length = params.length;
    foreach (i, paramType; params) {
      paramTypes[i] = VariantType!(paramType);
    }
  }

  int invoke(VARIANT*[] args, VARIANT* result) {

    size_t variantSize(VARTYPE vt) {
      switch (vt) {
        case VT_UI8, VT_I8, VT_CY:
          return long.sizeof / int.sizeof;
        case VT_R8, VT_DATE:
          return double.sizeof / int.sizeof;
        case VT_VARIANT:
          return (VARIANT.sizeof + 3) / int.sizeof;
        default:
      }

      return 1;
    }

    // Like DispCallFunc, but using delegates

    size_t paramCount;
    for (int i = 0; i < paramTypes.length; i++) {
      paramCount += variantSize(paramTypes[i]);
    }

    auto argptr = cast(int*)HeapAlloc(GetProcessHeap(), 0, paramCount * int.sizeof);

    uint pos;
    for (int i = 0; i < paramTypes.length; i++) {
      VARIANT* p = args[i];
      if (paramTypes[i] == VT_VARIANT)
        memcpy(&argptr[pos], p, variantSize(paramTypes[i]) * int.sizeof);
      else
        memcpy(&argptr[pos], &p.lVal, variantSize(paramTypes[i]) * int.sizeof);
      pos += variantSize(paramTypes[i]);
    }

    int ret = 0;

    switch (paramCount) {
      case 0: ret = method(); break;
      case 1: ret = (cast(int delegate(int))method)(argptr[0]); break;
      case 2: ret = (cast(int delegate(int, int))method)(argptr[0], argptr[1]); break;
      case 3: ret = (cast(int delegate(int, int, int))method)(argptr[0], argptr[1], argptr[2]); break;
      case 4: ret = (cast(int delegate(int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3]); break;
      case 5: ret = (cast(int delegate(int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4]); break;
      case 6: ret = (cast(int delegate(int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5]); break;
      case 7: ret = (cast(int delegate(int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6]); break;
      case 8: ret = (cast(int delegate(int, int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6], argptr[7]); break;
      case 9: ret = (cast(int delegate(int, int, int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6], argptr[7], argptr[8]); break;
      case 10: ret = (cast(int delegate(int, int, int, int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6], argptr[7], argptr[8], argptr[9]); break;
      case 11: ret = (cast(int delegate(int, int, int, int, int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6], argptr[7], argptr[8], argptr[9], argptr[10]); break;
      case 12: ret = (cast(int delegate(int, int, int, int, int, int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6], argptr[7], argptr[8], argptr[9], argptr[10], argptr[11]); break;
      case 13: ret = (cast(int delegate(int, int, int, int, int, int, int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6], argptr[7], argptr[8], argptr[9], argptr[10], argptr[11], argptr[12]); break;
      case 14: ret = (cast(int delegate(int, int, int, int, int, int, int, int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6], argptr[7], argptr[8], argptr[9], argptr[10], argptr[11], argptr[12], argptr[13]); break;
      case 15: ret = (cast(int delegate(int, int, int, int, int, int, int, int, int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6], argptr[7], argptr[8], argptr[9], argptr[10], argptr[11], argptr[12], argptr[13], argptr[14]); break;
      case 16: ret = (cast(int delegate(int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6], argptr[7], argptr[8], argptr[9], argptr[10], argptr[11], argptr[12], argptr[13], argptr[14], argptr[15]); break;
      case 17: ret = (cast(int delegate(int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6], argptr[7], argptr[8], argptr[9], argptr[10], argptr[11], argptr[12], argptr[13], argptr[14], argptr[15], argptr[16]); break;
      case 18: ret = (cast(int delegate(int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6], argptr[7], argptr[8], argptr[9], argptr[10], argptr[11], argptr[12], argptr[13], argptr[14], argptr[15], argptr[16], argptr[17]); break;
      case 19: ret = (cast(int delegate(int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6], argptr[7], argptr[8], argptr[9], argptr[10], argptr[11], argptr[12], argptr[13], argptr[14], argptr[15], argptr[16], argptr[17], argptr[18]); break;
      case 20: ret = (cast(int delegate(int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6], argptr[7], argptr[8], argptr[9], argptr[10], argptr[11], argptr[12], argptr[13], argptr[14], argptr[15], argptr[16], argptr[17], argptr[18], argptr[19]); break;
      default:
        return DISP_E_BADPARAMCOUNT;
    }

    if (result !is null && returnType != VT_VOID) {
      result.vt = returnType;
      result.lVal = ret;
    }

    HeapFree(GetProcessHeap(), 0, argptr);
    return S_OK;
  }

}

/**
 */
class EventProvider(T) : Implements!(T) {

  extern(D):

  private MethodProxy[int] methodTable_;
  private int[string] nameTable_;

  private IConnectionPoint connectionPoint_;
  private uint cookie_;

  /**
   */
  this(IUnknown source) {
    auto cpc = com_cast!(IConnectionPointContainer)(source);
    if (cpc !is null) {
      scope(exit) tryRelease(cpc);

      if (cpc.FindConnectionPoint(uuidof!(T), connectionPoint_) != S_OK)
        throw new ArgumentException("Source object does not expose '" ~ T.stringof ~ "' event interface.");

      if (connectionPoint_.Advise(this, cookie_) != S_OK) {
        cookie_ = 0;
        tryRelease(connectionPoint_);
        throw new InvalidOperationException("Could not Advise() the event interface '" ~ T.stringof ~ "'.");
      }
    }

    if (connectionPoint_ is null || cookie_ == 0) {
      if (connectionPoint_ !is null)
        tryRelease(connectionPoint_);
      throw new ArgumentException("Connection point for event interface '" ~ T.stringof ~ "' cannot be created.");
    }
  }

/*
  ~this() {
    //disconnect();
  }
*/
  
  void disconnect() {
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

  /**
   */
  void bind(ID, R, P...)(ID member, R delegate(P) handler) {
    static if (is(ID : string)) {
      bool found;
      int dispId = DISPID_UNKNOWN;
      if (tryFindDispId(member, dispId))
        bind(dispId, handler);
      else
        throw new ArgumentException("Member '" ~ member ~ "' not found in type '" ~ T.stringof ~ "'.");
    }
    else static if (is(ID : int)) {
      MethodProxy m = handler;
      methodTable_[member] = m;
    }
  }

  private bool tryFindDispId(string name, out int dispId) {

    void ensureNameTable() {
      if (nameTable_ == null) {
        scope clsidKey = RegistryKey.classesRoot.openSubKey("Interface\\" ~ uuidof!(T).toString("P"));
        if (clsidKey !is null) {
          scope typeLibRefKey = clsidKey.openSubKey("TypeLib");
          if (typeLibRefKey !is null) {
            string typeLibVersion = typeLibRefKey.getValue!(string)("Version");
            if (typeLibVersion == null) {
              scope versionKey = clsidKey.openSubKey("Version");
              if (versionKey !is null)
                typeLibVersion = versionKey.getValue!(string)(null);
            }

            scope typeLibKey = RegistryKey.classesRoot.openSubKey("TypeLib\\" ~ typeLibRefKey.getValue!(string)(null));
            if (typeLibKey !is null) {
              scope pathKey = typeLibKey.openSubKey(typeLibVersion ~ "\\0\\Win32");
              if (pathKey !is null) {
                ITypeLib typeLib;
                if (LoadTypeLib(pathKey.getValue!(string)(null).toUtf16z(), typeLib) == S_OK) {
                  scope(exit) tryRelease(typeLib);

                  ITypeInfo typeInfo;
                  if (typeLib.GetTypeInfoOfGuid(uuidof!(T), typeInfo) == S_OK) {
                    scope(exit) tryRelease(typeInfo);

                    TYPEATTR* typeAttr;
                    if (typeInfo.GetTypeAttr(typeAttr) == S_OK) {
                      scope(exit) typeInfo.ReleaseTypeAttr(typeAttr);

                      for (uint i = 0; i < typeAttr.cFuncs; i++) {
                        FUNCDESC* funcDesc;
                        if (typeInfo.GetFuncDesc(i, funcDesc) == S_OK) {
                          scope(exit) typeInfo.ReleaseFuncDesc(funcDesc);

                          wchar* bstrName;
                          if (typeInfo.GetDocumentation(funcDesc.memid, &bstrName, null, null, null) == S_OK) {
                            string memberName = fromBstr(bstrName);
                            nameTable_[memberName.toLower()] = funcDesc.memid;
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
    }

    dispId = DISPID_UNKNOWN;

    ensureNameTable();

    if (auto value = name.toLower() in nameTable_) {
      dispId = *value;
      return true;
    }

    return false;
  }

  extern(Windows):

  override int Invoke(int dispIdMember, ref GUID riid, uint lcid, ushort wFlags, DISPPARAMS* pDispParams, VARIANT* pVarResult, EXCEPINFO* pExcepInfo, uint* puArgError) {
    if (riid != GUID.empty)
      return DISP_E_UNKNOWNINTERFACE;

    try {
      if (auto handler = dispIdMember in methodTable_) {
        VARIANT*[8] args;
        for (int i = 0; i < handler.paramTypes.length && i < 8; i++) {
          args[i] = &pDispParams.rgvarg[handler.paramTypes.length - i - 1];
        }

        VARIANT result;
        if (pVarResult == null)
          pVarResult = &result;

        int hr = handler.invoke(args, pVarResult);

        for (int i = 0; i < handler.paramTypes.length; i++) {
          if (args[i].vt == (VT_BYREF | VT_BOOL)) {
            // Fix bools to VARIANT_BOOL
            *args[i].pboolVal = (*args[i].pboolVal == 0) ? VARIANT_FALSE : VARIANT_TRUE;
          }
        }

        return hr;
      }
      else
        return DISP_E_MEMBERNOTFOUND;
    }
    catch {
      return E_FAIL;
    }

    return S_OK;
  }

}
