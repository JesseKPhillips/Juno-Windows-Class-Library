/**
 * Copyright: (c) 2008 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.base.threading;

private import juno.base.native;

private static import core.memory;

class ThreadLocal(T) {

  private struct TlsData {
    T value;
  }

  private uint slot_;
  private T defaultValue_;

  this(lazy T defaultValue = T.init) {
    defaultValue_ = cast(T)defaultValue();
    slot_ = TlsAlloc();
  }

  ~this() {
    if (auto tlsData = cast(TlsData*)TlsGetValue(slot_))
      std.gc.removeRoot(tlsData);

    TlsFree(slot_);
    slot_ = cast(uint)-1;
  }

  final T get() {
    if (auto tlsData = cast(TlsData*)TlsGetValue(slot_))
      return tlsData.value;
    return defaultValue_;
  }

  final void set(T value) {
    auto tlsData = new TlsData;
    tlsData.value = value;
    std.gc.addRoot(tlsData);

    TlsSetValue(slot_, tlsData);
  }

}
