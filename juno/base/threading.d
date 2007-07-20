module juno.base.threading;

private import juno.base.core,
  juno.base.events,
  juno.base.native;

private import std.gc, std.thread;

public void sleep(int milliseconds) {
  .Sleep(milliseconds);
}

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

  public final T get() {
    synchronized {
      return (cast(TlsData*)TlsGetValue(slot_)).value;
    }
  }

  public final void set(T value) {
    synchronized {
      TlsData* tlsData = new TlsData;
      tlsData.value = value;
      std.gc.addRoot(tlsData);

      TlsSetValue(slot_, tlsData);
    }
  }

}

public abstract class Lock {

  public abstract void enter();

  public abstract bool tryEnter();

  public abstract void leave();

}

public class SyncLock : Lock {

  private CRITICAL_SECTION critSect_;

  public this() {
    InitializeCriticalSection(critSect_);
  }

  public ~this() {
    DeleteCriticalSection(critSect_);
  }

  public override void enter() {
    EnterCriticalSection(critSect_);
  }

  public override bool tryEnter() {
    return TryEnterCriticalSection(critSect_) != 0;
  }

  public override void leave() {
    LeaveCriticalSection(critSect_);
  }

}

public void withLock(Lock lock, void delegate() block) {
  lock.enter();
  try {
    block();
  }
  finally {
    lock.leave();
  }
}