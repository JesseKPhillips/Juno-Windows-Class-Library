module juno.com.server;

private import juno.base.core,
  juno.base.string,
  juno.base.native,
  juno.com.core;

/*
 * Contains boiler-plate code for creating a COM server (a DLL that exports COM classes).
 * Example:
 * --- hello.d ---
 * module hello;
 *
 * // This is the public interface.
 *
 * private import juno.com.all;
 *
 * interface ISaysHello : IUnknown {
 *   // {AE0DD4B7-E817-44ff-9E11-D1CFFAE11F16}
 *   static GUID IID = { 0xae0dd4b7, 0xe817, 0x44ff, 0x9e, 0x11, 0xd1, 0xcf, 0xfa, 0xe1, 0x1f, 0x16 };
 *
 *   int sayHello();
 * }
 *
 * // coclass
 * abstract class SaysHello {
 *   // {35115E92-33F5-4e14-9D0A-BD43C80A75AF}
 *   static GUID CLSID = { 0x35115e92, 0x33f5, 0x4e14, 0x9d, 0xa, 0xbd, 0x43, 0xc8, 0xa, 0x75, 0xaf };
 *   mixin CoInterfaces!(ISaysHello);
 * }
 *
 * --- server.d ---
 * module server;
 *
 * // This is the DLL's private implementation.
 *
 * import juno.com.all, hello;
 *
 * mixin COMExport!(SaysHelloClass);
 *
 * // Implements ISaysHello
 * class SaysHelloClass : Implements!(ISaysHello) {
 *   // Note: must have the same CLSID as the SaysHello coclass above.
 *   static GUID CLSID = { 0x35115e92, 0x33f5, 0x4e14, 0x9d, 0xa, 0xbd, 0x43, 0xc8, 0xa, 0x75, 0xaf };
 *
 *   int sayHello() {
 *     Console.writeln("Hello there!");
 *     return S_OK;
 *   }
 *
 * }
 *
 * --- client.d ---
 * module client;
 *
 * import juno.com.core, hello;
 *
 * void main() {
 *   ISaysHello saysHello = SaysHello.coCreate!(ISaysHello);
 *   saysHello.sayHello(); // Prints "Hello there!"
 *   saysHello.Release();
 * }
 * ---
 *
 * The COM server needs to be registered with the system. Usually, a CLSID is associated with the DLL in the registry 
 * (under HKEY_CLASSES_ROOT\CLSID). On Windows XP and above, an alternative is to deploy an application manifest in the same folder 
 * as the client application. This is an XML file that does the same thing as the registry method. Here's an example:
 *
 * --- client.exe.manifest ---
 * <?xml version="1.0" encoding="utf-8" standalone="yes"?>
 * <assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
 *   <assemblyIdentity name="client.exe" version="1.0.0.0" type="win32"/>
 *   <file name="C:\\Program Files\\My COM Server\\server.dll">
 *     <comClass clsid="{35115e92-33f5-4e14-9d0a-bd43c80a75af}" description="SaysHello" threadingModel="Apartment"/>
 *  </file>
 * </assembly>
 *
 * Alternatively, define a static register and unregister method on each coclass implementation. If the methods exist, the DLL will 
 * register itself in the registry when 'regsvr32' is executed, and unregister itself on 'regsvr32 /u'.
 */

extern (C) void gc_init();
extern (C) void gc_term();
extern (C) void _minit();
extern (C) void _moduleCtor();
extern (C) void _moduleDtor();
extern (C) void _moduleUnitTests();

private Handle moduleHandle_;
private int lockCount_;
private string location_;

public Handle getHInstance() {
  return moduleHandle_;
}

public void setHInstance(Handle value) {
  moduleHandle_ = value;
}

public string getLocation() {
  if (location_ == null) {
    wchar[MAX_PATH] buffer;
    uint len = GetModuleFileName(moduleHandle_, buffer.ptr, buffer.length);
    location_ = juno.base.string.toUtf8(buffer.ptr, 0, len);
  }
  return location_;
}

public int getLockCount() {
  return lockCount_;
}

public void lock() {
  InterlockedIncrement(lockCount_);
}

public void unlock() {
  InterlockedDecrement(lockCount_);
}

public class ClassFactory(T) : Implements!(IClassFactory) {

  int CreateInstance(IUnknown pUnkOuter, ref GUID riid, void** ppvObject) {
    if (pUnkOuter !is null && riid != IUnknown.IID)
      return CLASS_E_NOAGGREGATION;

    ppvObject = null;
    int hr = E_OUTOFMEMORY;

    T obj = new T;
    if (obj !is null) {
      hr = obj.QueryInterface(riid, ppvObject);
      obj.Release();
    }
    return hr;
  }

  int LockServer(int fLock) {
    if (fLock)
      lock();
    else
      unlock();
    return S_OK;
  }

}

template COMExport(T ...) {

  extern(Windows) int DllMain(Handle hInstance, uint dwReason, void* pvReserved) {
    if (dwReason == 1 /*DLL_PROCESS_ATTACH*/) {
      setHInstance(hInstance);

      gc_init();
      _minit();
      _moduleCtor();

      return 1;
    }
    else if (dwReason == 0 /*DLL_PROCESS_DETACH*/) {
      gc_term();
      return 1;
    }
    return 0;
  }

  extern(Windows) int DllGetClassObject(ref GUID rclsid, ref GUID riid, void** ppv) {
    int hr = CLASS_E_CLASSNOTAVAILABLE;
    *ppv = null;

    foreach (coclass; T) {
      if (rclsid == coclass.CLSID) {
        IClassFactory factory = new ClassFactory!(coclass);
        if (factory is null)
          return E_OUTOFMEMORY;

        releaseAfter (factory, {
          hr = factory.QueryInterface(riid, ppv);
        });
      }
    }

    return hr;
  }

  extern(Windows) int DllCanUnloadNow() {
    return (getLockCount() == 0) ? S_OK : S_FALSE;
  }

  bool registerCoClass(CoClass)() {
    bool success;

    try {
      scope clsidKey = RegistryKey.classesRoot.createSubKey("CLSID\\" ~ CoClass.CLSID.toString());
      if (clsidKey !is null) {
        clsidKey.setValue!(string)(null, CoClass.classinfo.name ~ " Class");

        scope subKey = clsidKey.createSubKey("InprocServer32");
        if (subKey !is null) {
          subKey.setValue!(string)(null, getLocation());
          subKey.setValue!(string)("ThreadingModel", "Apartment");

          scope progIDSubKey = clsidKey.createSubKey("ProgID");
          if (progIDSubKey !is null) {
            progIDSubKey.setValue!(string)(null, CoClass.classinfo.name);

            scope progIDKey = RegistryKey.classesRoot.createSubKey(CoClass.classinfo.name);
            if (progIDKey !is null) {
              progIDKey.setValue!(string)(null, CoClass.classinfo.name ~ " Class");

              scope clsidSubKey = progIDKey.createSubKey("CLSID");
              if (clsidSubKey !is null)
                clsidSubKey.setValue!(string)(null, CoClass.CLSID.toString());
            }
          }
        }
      }

      success = true;
    }
    catch {
      success = false;
    }

    return success;
  }

  bool unregisterCoClass(CoClass)() {
    bool success;

    try {
      scope clsidKey = RegistryKey.classesRoot.openSubKey("CLSID");
      if (clsidKey !is null)
        clsidKey.deleteSubKeyTree(CoClass.CLSID.toString());

      RegistryKey.classesRoot.deleteSubKeyTree(CoClass.classinfo.name);

      success = true;
    }
    catch {
      success = false;
    }

    return success;
  }

  extern(Windows) int DllRegisterServer() {
    bool success;

    foreach (coclass; T) {
      static if (is(typeof(coclass.register))) {
        static assert(is(typeof(coclass.unregister)), "'register' must be matched by a corresponding 'unregister' in '" ~ coclass.stringof ~ "'.");

        success = registerCoClass!(coclass)();
        coclass.register();
      }
    }

    return success ? S_OK : SELFREG_E_CLASS;
  }

  extern(Windows) int DllUnregisterServer() {
    bool success;

    foreach (coclass; T) {
      static if (is(typeof(coclass.unregister))) {
        static assert(is(typeof(coclass.register)), "'unregister' must be matched by a corresponding 'register' in '" ~ coclass.stringof ~ "'.");

        success = unregisterCoClass!(coclass)();
        coclass.unregister();
      }
    }

    return success ? S_OK : SELFREG_E_CLASS;
  }

}