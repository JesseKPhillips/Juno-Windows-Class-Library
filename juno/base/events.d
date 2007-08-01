/*
 * Copyright (c) 2007 John Chapman
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

module juno.base.events;

// Extends delegates so they can invoke more than one method.

extern (C)
private Object _d_toObject(void*);

// Wraps a delegate or function pointer.
private struct EventInfo(R, T ...) {

  alias R delegate(T) TDelegate;
  alias R function(T) TFunction;

  TDelegate d;
  TFunction f;

  static EventInfo opCall(TDelegate d) {
    EventInfo e;
    e.d = d;
    return e;
  }

  static EventInfo opCall(TFunction f) {
    EventInfo e;
    e.f = f;
    return e;
  }

  R opCall(T args) {
    if (f !is null) return f(args);
    else if (d !is null) return d(args);
    else static if (!is(R == void)) return R.init;
  }

}

public struct Event(R, T ...) {

  alias EventInfo!(R, T)      TEventInfo;
  alias TEventInfo.TDelegate  TDelegate;
  alias TEventInfo.TFunction  TFunction;

  private TEventInfo[] list_;
  private int count_;

  public static Event opCall(TDelegate d) {
    Event ev;
    ev.add(d);
    return ev;
  }

  public static Event opCall(TFunction f) {
    Event ev;
    ev.add(f);
    return ev;
  }

  public void add(TDelegate d) {
    add(cast(TEventInfo)d);

    if (auto obj = _d_toObject(d.ptr))
      obj.notifyRegister(&cleanup);
  }

  public void add(TFunction f) {
    add(cast(TEventInfo)f);
  }

  public Event opAddAssign(TDelegate d) {
    add(d);
    return *this;
  }

  public Event opAddAssign(TFunction f) {
    add(f);
    return *this;
  }

  public void remove(TDelegate d) {
    for (int i = 0; i < count_;) {
      if (list_[i].d is d) {
        removeFromList(i);

        if (auto obj = _d_toObject(d.ptr))
          obj.notifyUnRegister(&cleanup);
      }
      else i++;
    }
  }

  public void remove(TFunction f) {
    for (int i = 0; i < count_;) {
      if (list_[i].f is f)
        removeFromList(i);
      else i++;
    }
  }

  public Event opSubAssign(TDelegate d) {
    remove(d);
    return *this;
  }

  public Event opSubAssign(TFunction f) {
    remove(f);
    return *this;
  }

  public R invoke(T args) {
    if (count_ == 0) {
      static if (!is(R == void))
        return R.init;
    }
    else {
      static if (!is(R == void)) {
        for (int i = 0; i < count_ - 1; i++)
          list_[i](args);
        return list_[count_ - 1].invoke(args);
      }
      else {
        for (int i = 0; i < count_; i++)
          list_[i](args);
      }
    }
  }

  public R opCall(T args) {
    return invoke(args);
  }

  public bool isEmpty() {
    return count_ == 0;
  }

  private void add(TEventInfo e) {
    int n = list_.length;

    if (n == 0)
      list_.length = 4;
    else if (n == count_)
      list_.length = list_.length * 2;

    list_[n .. $] = TEventInfo.init;
    list_[count_++] = e;
  }

  private void removeFromList(int index) {
    count_--;
    if (index < count_) {
      TEventInfo[] temp = list_.dup;
      list_[index .. count_] = temp[index + 1 .. count_ + 1];
    }
    list_[count_] = TEventInfo.init;
  }

  private void cleanup(Object obj) {
    foreach (i, ref e; list_) {
      if (i < count_ && _d_toObject(e.d.ptr) is obj) {
        obj.notifyUnRegister(&cleanup);
        e.d = null;
      }
    }
  }

}

public class EventArgs {

  public static const EventArgs empty;

  static this() {
    empty = new EventArgs;
  }

}

public class CancelEventArgs : EventArgs {

  public bool cancel;

  public this(bool cancel = false) {
    this.cancel = cancel;
  }

}

template TEventHandler(TEventArgs : EventArgs) {
  alias Event!(void, Object, TEventArgs) TEventHandler;
}

alias TEventHandler!(EventArgs) EventHandler;
alias TEventHandler!(CancelEventArgs) CancelEventHandler;