module server;

// This is the DLL's private implementation.

import juno.com.all, juno.utils.registry, hello;
import juno.com.server;
import std.stdio;

mixin Export!(SaysHelloClass);

// Implements ISaysHello
class SaysHelloClass : Implements!(ISaysHello) {
  // Note: must have the same CLSID as the SaysHello coclass above.
  mixin(uuid("35115e92-33f5-4e14-9d0a-bd43c80a75af"));

  int sayHello() {
    writefln("Hello there!");
    return S_OK;
  }
}
