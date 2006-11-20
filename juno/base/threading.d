module juno.base.threading;

private import juno.base.win32;
private static import std.gc;

public class ThreadLocal(T) {

  private struct TlsData {
    T value;
  }

  private int slot_;

  public this() {
    synchronized {
      slot_ = TlsAlloc();
    }
  }

  ~this() {
    synchronized {
      if (auto tlsData = cast(TlsData*)TlsGetValue(slot_))
        std.gc.removeRoot(tlsData);

      TlsFree(slot_);
      slot_ = -1;
    }
  }

  public T getData() {
    synchronized {
      if (slot_ >= TLS_OUT_OF_INDEXES)
        return T.init;

      return (cast(TlsData*)TlsGetValue(slot_)).value;
    }
  }

  public void setData(T data) {
    synchronized {
      TlsData* tlsData = new TlsData;
      tlsData.value = data;
      std.gc.addRoot(tlsData);

      TlsSetValue(slot_, tlsData);
    }
  }

}

// Ideally, this should be a static method in std.thread.Thread.
public void sleep(uint milliseconds) {
  .Sleep(milliseconds);
}