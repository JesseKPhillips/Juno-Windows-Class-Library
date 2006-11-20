module juno.com.client;

private import juno.base.core,
  juno.base.meta,
  juno.base.string,
  juno.utils.registry,
  juno.com.core;
private import std.traits;
private import std.c.stdlib : malloc, free;
private import std.c.string : memcpy;

/**
 * Binds a delegate to a COM event handler.
 *
 * Examples:
 * ---
 * void main() {
 *   // Create an XML document.
 *   IXMLDOMDocument3 doc = DOMDocument60.coCreate!(IXMLDOMDocument3);
 *   releaseAfter (doc, {
 *     // Connect to the COM object's event interface.
 *     auto events = new EventProvider!(XMLDOMDocumentEvents)(doc);
 *     releaseAfter (events, {
 *       // Hook the onreadystatechange event using named binding.
 *       events.attach("onreadystatechange", {
 *         // Display the document's state.
 *         int readyState;
 *         doc.get_readyState(readyState);
 *         Console.writeln("state changed: {0}", readyState);
 *       });
 *       // Hook the ondataavailable event using named binding.
 *       events.attach("ondataavailable", {
 *         Console.writeln("data available");
 *       });
 *       // Load the document asynchronously.
 *       com_bool success;
 *       doc.load("books.xml".toVariant(true), success);
 *     });
 *   });
 * }
 * ---
 */
public class EventProvider(T) : Implements!(T) {

  extern (D):

  struct HandlerInfo {
    int delegate() handler;
    ushort returnType;
    ushort[] paramTypes;
  }

  private int[char[]] nameTable_;
  private HandlerInfo[int] handlerTable_;

  private IConnectionPoint connectionPoint_;
  private uint cookie_;

  /**
   * Creates a new instance and connects to the event _source's event interface.
   */
  public this(IUnknown source) {
    auto cpc = com_safe_cast!(IConnectionPointContainer)(source);
    if (cpc !is null) {
      releaseAfter (cpc, {
        if (cpc.FindConnectionPoint(T.IID, connectionPoint_) != S_OK)
          throw new ArgumentException("Source object does not expose '" ~ juno.base.meta.nameof!(T) ~ "' event interface.");

        if (connectionPoint_.Advise(this, cookie_) != S_OK) {
          cookie_ = 0;
          tryRelease(connectionPoint_);
          throw new InvalidOperationException("Could not Advise() the event interface '" ~ juno.base.meta.nameof!(T) ~ "'.");
        }
      });
    }

    if (connectionPoint_ is null || cookie_ == 0) {
      if (connectionPoint_ !is null)
        tryRelease(connectionPoint_);
      throw new ArgumentException("Connection point for event interface '" ~ juno.base.meta.nameof!(T) ~ "' cannot be created.");
    }
  }

  /**
   * Maps a delegate to a member identifier (DISPID).
   * Params:
   *   member = The name or identifier of the member.
   *   handler = The delegate to map to member.
   */
  public void attach(ID, U)(ID member, U handler) {
    // If the member was specified as a string, used named binding and look up the dispid in the type library.
    // Otherwise, we expect an integer and use id binding. No checking is done here to verify whether the method exists.
    static if (is(ID : char[])) {
      bool found;
      int memid = findMemberId(member, found);
      if (found)
        attach(memid, handler);
      else
        throw new ArgumentException("Member '" ~ member ~ "' not found in type '" ~ typeid(T).toString() ~ "'.");
    }
    else static if (is(ID : int)) {
      HandlerInfo hi;
      hi.handler = cast(int delegate())handler;

      // Store the return and parameter types of the delegate as VARTYPEs, which we need when Invoke is called.
      hi.returnType = VariantType!(ReturnType!(U));
      hi.paramTypes.length = ParameterTypeTuple!(U).length;
      foreach (i, paramType; ParameterTypeTuple!(U))
        hi.paramTypes[i] = VariantType!(paramType);

      handlerTable_[member] = hi;
    }
  }

  public void detach(ID, U)(ID member, U handler) {
    static if (is(ID : char[])) {
      bool found;
      int memid = findMemberId(member, found);
      if (found)
        sink(memid, handler);
      else
        throw new ArgumentException("Member '" ~ member ~ "' not found in type '" ~ typeid(T).toString() ~ "'.");
    }
    else static if (is(ID : int)) {
      handlerTable_.remove(member);
    }
  }

  protected override void finalize() {
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

  extern (Windows):

  protected override int Invoke(int dispidMember, inout GUID riid, uint lcid, ushort wFlags, DISPPARAMS* pdispparams, VARIANT* pvarResult, EXCEPINFO* pexcepinfo, uint* puArgErr) {

    int invokeImpl(inout HandlerInfo handlerInfo, ushort resultType, VARIANT*[] args, VARIANT* result) {

      int invokeHandler(int delegate() handler, uint length, uint* p) {
        switch (length) {
          case 0:
            return handler();
          case 1:
            return (cast(int delegate(uint))handler)(p[0]);
          case 2:
            return (cast(int delegate(uint, uint))handler)(p[0], p[1]);
          case 3:
            return (cast(int delegate(uint, uint, uint))handler)(p[0], p[1], p[2]);
          case 4:
            return (cast(int delegate(uint, uint, uint, uint))handler)(p[0], p[1], p[2], p[3]);
          case 5:
            return (cast(int delegate(uint, uint, uint, uint, uint))handler)(p[0], p[1], p[2], p[3], p[4]);
          case 6:
            return (cast(int delegate(uint, uint, uint, uint, uint, uint))handler)(p[0], p[1], p[2], p[3], p[4], p[5]);
          case 7:
            return (cast(int delegate(uint, uint, uint, uint, uint, uint, uint))handler)(p[0], p[1], p[2], p[3], p[4], p[5], p[6]);
          case 8:
            return (cast(int delegate(uint, uint, uint, uint, uint, uint, uint, uint))handler)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7]);
          case 9:
            return (cast(int delegate(uint, uint, uint, uint, uint, uint, uint, uint, uint))handler)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8]);
          case 10:
            return (cast(int delegate(uint, uint, uint, uint, uint, uint, uint, uint, uint, uint))handler)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9]);
          case 11:
            return (cast(int delegate(uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint))handler)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10]);
          case 12:
            return (cast(int delegate(uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint))handler)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11]);
          default:
        }
        return DISP_E_BADPARAMCOUNT;
      }

      uint sizeOf(ushort vt) {
        switch (vt) {
          case VT_UI8: case VT_I8: case VT_CY:
            return long.sizeof / uint.sizeof;
          case VT_R8:
            return double.sizeof / uint.sizeof;
          case VT_VARIANT:
            return (VARIANT.sizeof + 3) / uint.sizeof;
          default:
        }
        return 1;
      }

      bool copyVariant(uint* p, VARIANT* var, ushort vt) {
        uint size = sizeOf(vt) * uint.sizeof;
        if (var.vt == vt) {
          memcpy(p, &var.lVal, size);
          return true;
        }
        if (vt == VT_VARIANT) {
          memcpy(p, var, size);
          return true;
        }
        if ((var.vt & VT_BYREF) && (var.vt & ~VT_BYREF) == vt) {
          memcpy(p, cast(void*)var.lVal, size);
          return true;
        }
        if (vt == VT_UNKNOWN && var.vt == VT_DISPATCH) {
          memcpy(p, &var.lVal, size);
          return true;
        }
        VARIANT va;
        if (VariantChangeType(&va, var, 0, vt) == S_OK) {
          memcpy(p, &var.lVal, size);
          return true;
        }
        return false;
      }

      uint cb = 0;
      for (uint i = 0; i < handlerInfo.paramTypes.length; i++)
        cb += sizeOf(handlerInfo.paramTypes[i]);

      uint offset = 0;
      uint* ptr = cast(uint*)malloc(cb * uint.sizeof);
      for (uint i = 0; i < handlerInfo.paramTypes.length; i++) {
        VARIANT* p = args[i];
        copyVariant(&ptr[offset], p, handlerInfo.paramTypes[i]);
        offset += sizeOf(handlerInfo.paramTypes[i]);
      }

      int hr = invokeHandler(handlerInfo.handler, cb, ptr);

      if (result != null && (resultType != VT_VOID || resultType != VT_EMPTY)) {
        result.vt = resultType;
        result.lVal = hr;
      }

      free(ptr);
      return hr;
    }

    if (auto h = dispidMember in handlerTable_) {
      auto handlerInfo = *h;

      VARIANT*[8] args;
      for (uint i = 0; i < handlerInfo.paramTypes.length && i < 8; i++)
        args[i] = &pdispparams.rgvarg[handlerInfo.paramTypes.length - i - 1];

      VARIANT result;
      if (pvarResult == null)
        pvarResult = &result;

      return invokeImpl(handlerInfo, VT_VOID, args, &result);
    }
    return DISP_E_MEMBERNOTFOUND;
  }

  extern (D):

  private int findMemberId(char[] name, out bool found) {

    void initNameTable() {
      scope RegistryKey clsidKey = RegistryKey.classesRoot.openSubKey("Interface\\" ~ T.IID.toString());
      if (clsidKey !is null) {
        scope RegistryKey typeLibRefKey = clsidKey.openSubKey("TypeLib");
        if (typeLibRefKey !is null) {
          char[] typeLibVersion = typeLibRefKey.getStringValue("Version");
          if (typeLibVersion == null) {
            scope RegistryKey versionKey = clsidKey.openSubKey("Version");
            if (versionKey !is null)
              typeLibVersion = versionKey.getStringValue(null);
          }

          // To get the path: HKCR\TypeLib\<TypeLibID>\<VersionMajor>.<VersionMinor>\<LCID>\win32
          // Turns out very few type libraries are locale-specific, so using 0 for the LCID will work for most.
          scope RegistryKey typeLibKey = RegistryKey.classesRoot.openSubKey("TypeLib\\" ~ typeLibRefKey.getStringValue(null));
          if (typeLibKey !is null) {
            scope RegistryKey pathKey = typeLibKey.openSubKey(typeLibVersion ~ "\\0\\win32");
            if (pathKey !is null) {
              ITypeLib typeLib = null;
              if (SUCCEEDED(LoadTypeLib(pathKey.getStringValue(null).toLPStr(), typeLib))) {
                releaseAfter (typeLib, {
                  ITypeInfo typeInfo;
                  if (SUCCEEDED(typeLib.GetTypeInfoOfGuid(T.IID, typeInfo))) {
                    releaseAfter (typeInfo, {
                      TYPEATTR* typeAttr;
                      if (SUCCEEDED(typeInfo.GetTypeAttr(typeAttr))) {
                        for (uint i = 0; i < typeAttr.cFuncs; i++) {
                          FUNCDESC* funcDesc;
                          if (SUCCEEDED(typeInfo.GetFuncDesc(i, funcDesc))) {
                            wchar* bstrName;
                            if (SUCCEEDED(typeInfo.GetDocumentation(funcDesc.memid, &bstrName, null, null, null))) {
                              char[] memberName = bstrToUtf8(bstrName);
                              nameTable_[memberName.toLower()] = funcDesc.memid;
                            }
                            typeInfo.ReleaseFuncDesc(funcDesc);
                          }
                        }
                        typeInfo.ReleaseTypeAttr(typeAttr);
                      }
                    });
                  }
                });
              }
            }
          }
        }
      }
    }

    found = false;

    if (nameTable_ == null)
      initNameTable();

    if (auto memid = name.toLower() in nameTable_) {
      found = true;
      return *memid;
    }
    return -1;
  }

}