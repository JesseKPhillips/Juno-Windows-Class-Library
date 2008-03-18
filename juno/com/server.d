/**
 * Copyright: (c) 2008 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
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
 * // This is the interface.
 *
 * private import juno.com.all;
 *
 * interface ISaysHello : IUnknown {
 *   mixin(uuid("ae0dd4b7-e817-44ff-9e11-d1cffae11f16"));
 *
 *   int sayHello();
 * }
 *
 * // coclass
 * abstract class SaysHello {
 *   mixin(uuid("35115e92-33f5-4e14-9d0a-bd43c80a75af"));
 *
 *   mixin Interfaces!(ISaysHello);
 * }
 *
 * --- server.d ---
 * module server;
 *
 * // This is the DLL's private implementation.
 *
 * import juno.com.all, juno.utils.registry, hello;
 *
 * mixin COMExport!(SaysHelloClass);
 *
 * // Implements ISaysHello
 * class SaysHelloClass : Implements!(ISaysHello) {
 *   // Note: must have the same CLSID as the SaysHello coclass above.
 *   mixin(uuid("35115e92-33f5-4e14-9d0a-bd43c80a75af"));
 *
 *   int sayHello() {
 *     writefln("Hello there!");
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

Handle getHInstance() {
  return moduleHandle_;
}

void setHInstance(Handle value) {
  moduleHandle_ = value;
}

string getLocation() {
  if (location_ == null) {
    wchar[MAX_PATH] buffer;
    uint len = GetModuleFileName(moduleHandle_, buffer.ptr, buffer.length);
    location_ = juno.base.string.toUtf8(buffer.ptr, 0, len);
  }
  return location_;
}

int getLockCount() {
  return lockCount_;
}

void lock() {
  InterlockedIncrement(&lockCount_);
}

void unlock() {
  InterlockedDecrement(&lockCount_);
}

class ClassFactory(T) : Implements!(IClassFactory) {

  int CreateInstance(IUnknown pUnkOuter, ref GUID riid, void** ppvObject) {
    if (pUnkOuter !is null && riid != uuidof!(IUnknown))
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

template COMExport(T...) {

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

  extern(Windows)
  int DllGetClassObject(ref GUID rclsid, ref GUID riid, void** ppv) {
    int hr = CLASS_E_CLASSNOTAVAILABLE;
    *ppv = null;

    foreach (coclass; T) {
      if (rclsid == uuidof!(coclass)) {
        IClassFactory factory = new ClassFactory!(coclass);
        if (factory is null)
          return E_OUTOFMEMORY;
        scope(exit) tryRelease(factory);

        hr = factory.QueryInterface(riid, ppv);
      }
    }

    return hr;
  }

  extern(Windows)
  int DllCanUnloadNow() {
    return (getLockCount() == 0) ? S_OK : S_FALSE;
  }

  bool registerCoClass(CoClass)() {
    bool success;

    try {
      scope clsidKey = RegistryKey.classesRoot.createSubKey("CLSID\\" ~ uuidof!(CoClass).toString("P"));
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
                clsidSubKey.setValue!(string)(null, uuidof!(CoClass).toString("P"));
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
        clsidKey.deleteSubKeyTree(uuidof!(CoClass).toString("P"));

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