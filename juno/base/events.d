/**
 * Copyright: (c) 2008 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.base.events;

extern(C) private Object _d_toObject(void*);

private struct EventInfo(R, T...) {

  alias R delegate(T) TDelegate;
  alias R function(T) TFunction;

  enum Type {
    Delegate,
    Function
  }

  union {
    TDelegate dg;
    TFunction fn;
  }
  Type type;

  static EventInfo opCall(TDelegate dg) {
    EventInfo e;
    e.type = Type.Delegate;
    e.dg = dg;
    return e;
  }

  static EventInfo opCall(TFunction fn) {
    EventInfo e;
    e.type = Type.Function;
    e.fn = fn;
    return e;
  }

  R opCall(T args) {
    if (type == Type.Function && fn !is null)
      return fn(args);
    else if (type == Type.Delegate && dg !is null)
      return dg(args);
    static if (!is(R == void))
      return R.init;
  }

}

struct Event(R, T...) {

  alias EventInfo!(R, T) TEventInfo;
  alias TEventInfo.TDelegate TDelegate;
  alias TEventInfo.TFunction TFunction;

  private TEventInfo[] list_;
  private uint size_;

  void delegate() adding;
  void delegate() removing;

  alias opAddAssign add;

  void opAddAssign(TDelegate d) {
    if (adding !is null)
      adding();

    addEventInfo(cast(TEventInfo)d);

    // Delegate literals don't have an object, and _d_toObject will cause a crash.
    scope(failure) return;
    if (auto obj = _d_toObject(d.ptr))
      obj.notifyRegister(&release);
  }

  void opAddAssign(TFunction f) {
    if (adding !is null)
      adding();

    addEventInfo(cast(TEventInfo)f);
  }

  alias opSubAssign remove;

  void opSubAssign(TDelegate dg) {
    if (removing !is null)
      removing();

    for (uint i = 0; i < size_;) {
      if (list_[i].dg is dg) {
        removeFromList(i);

        scope(failure) break;
        if (auto obj = _d_toObject(dg.ptr))
          obj.notifyUnRegister(&release);
      }
      else
        i++;
    }
  }

  void opSubAssign(TFunction fn) {
    if (removing !is null)
      removing();

    for (uint i = 0; i < size_;) {
      if (list_[i].fn is fn)
        removeFromList(i);
      else
        i++;
    }
  }

  alias opCall invoke;

  R opCall(T args) {
    if (size_ == 0) {
      static if (!is(R == void))
        return R.init;
    }
    else {
      static if (!is(R == void)) {
        for (uint i = 0; i < size_ - 1; i++)
          list_[i](args);
        return list_[size_ - 1](args);
      }
      else {
        for (uint i = 0; i < size_; i++)
          list_[i](args);
      }
    }
  }

  bool isEmpty() const {
    return size_ == 0;
  }

  const bool opEquals(ref const(void*) a) {
    return isEmpty;
  }

  private void addEventInfo(TEventInfo e) {
    uint n = list_.length;

    if (n == 0)
      list_.length = 4;
    else if (n == size_)
      list_.length = list_.length * 2;

    list_[n .. $] = TEventInfo.init;
    list_[size_++] = e;
  }

  private void removeFromList(uint index) {
    size_--;
    if (index < size_) {
      auto temp = list_.dup;
      list_[index .. size_] = temp[index + 1 .. size_ + 1];
    }
    list_[size_] = TEventInfo.init;
  }

  private void release(Object obj) {
    scope(failure) return;
    foreach (i, ref e; list_) {
      if (i < size_ && _d_toObject(e.dg.ptr) is obj) {
        obj.notifyUnRegister(&release);
        e.dg = null;
      }
    }
  }

}

class EventArgs {

  private static EventArgs empty;

  static this() {
    empty = new EventArgs;
  }

  this() {
  }

}

class CancelEventArgs : EventArgs {

  bool cancel;

  this(bool cancel = false) {
    this.cancel = cancel;
  }

}

template TEventHandler(TEventArgs = EventArgs) {
  alias Event!(void, Object, TEventArgs) TEventHandler;
}

alias TEventHandler!() EventHandler;
alias TEventHandler!(CancelEventArgs) CancelEventHandler;