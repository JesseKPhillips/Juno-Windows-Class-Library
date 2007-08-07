module juno.base.threading;

private import juno.base.core,
  juno.base.string,
  juno.base.native;

public import std.thread;
private import std.gc;

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

public abstract class WaitHandle {

  private Handle handle_;

  ~this() {
    close();
  }

  public final void close() {
    if (handle_ != Handle.init) {
      CloseHandle(handle_);
      handle_ = Handle.init;
    }
  }

  public bool waitOne(int millisecondsTimeout = -1) {
    uint ret = WaitForSingleObject(handle_, cast(uint)millisecondsTimeout);
    if (ret == WAIT_ABANDONED)
      throw new BaseException("The wait completed due to an abandoned mutex.");

    return ret != STATUS_TIMEOUT;
  }

  public void handle(Handle value) {
    if (value == Handle.init)
      handle_ = INVALID_HANDLE_VALUE;
    else
      handle_ = value;
  }

  public Handle handle() {
    if (handle_ == Handle.init)
      return INVALID_HANDLE_VALUE;
    return handle_;
  }

  protected this() {
    handle_ = INVALID_HANDLE_VALUE;
  }

}

public final class Mutex : WaitHandle {

  public this(bool initiallyOwned = false, string name = null) {
    Handle hMutex = CreateMutex(null, (initiallyOwned ? 1 : 0), name.toUtf16z());
    uint error = GetLastError();

    if (error == ERROR_ACCESS_DENIED && (hMutex == Handle.init || hMutex == INVALID_HANDLE_VALUE))
      hMutex = OpenMutex(MUTEX_MODIFY_STATE | SYNCHRONIZE, 0, name.toUtf16z());

    handle_ = hMutex;
  }

  public void release() {
    ReleaseMutex(handle_);
  }

}

public class Semaphore : WaitHandle {

  public this(int initialCount, int maximumCount, string name = null) {
    handle_ = CreateSemaphore(null, initialCount, maximumCount, name.toUtf16z());
  }

  public int release(int releaseCount = 1) {
    int prevCount;
    if (!ReleaseSemaphore(handle_, releaseCount, prevCount))
      throw new BaseException("Adding the given count to the semaphore would cause it to exceed its maximum count.");
    return prevCount;
  }

}

public enum EventResetMode {
  Auto,
  Manual
}

public class EventWaitHandle : WaitHandle {

  public this(bool initialState, EventResetMode mode, string name = null) {
    handle_ = CreateEvent(null, (mode == EventResetMode.Auto ? 0 : 1), (initialState ? 1 : 0), name.toUtf16z());
  }

  public final bool set() {
    return SetEvent(handle_) != 0;
  }

  public final bool reset() {
    return ResetEvent(handle_) != 0;
  }

}

public final class AutoResetEvent : EventWaitHandle {

  public this(bool initialState) {
    super(initialState, EventResetMode.Auto);
  }

}

public final class ManualResetEvent : EventWaitHandle {

  public this(bool initialState) {
    super(initialState, EventResetMode.Manual);
  }

}