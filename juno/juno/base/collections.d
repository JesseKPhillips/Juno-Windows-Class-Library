module juno.base.collections;

private import juno.base.core;

template indexOf(T) {

  int indexOf(T[] array, T value, int startIndex, int count) {
    if (startIndex > array.length)
      throw new ArgumentOutOfRangeException("index");
    int endIndex = startIndex + count;
    for (int i = startIndex; i < endIndex; i++) {
      static if (is(T == class)) {
        if (array[i] is value || (array[i] !is null && array[i] == value))
          return i;
      }
      else {
        if (array[i] == value)
          return i;
      }
    }
    return -1;
  }

}

template lastIndexOf(T) {

  int lastIndexOf(T[] array, T value, int startIndex, int count) {
    if (startIndex >= array.length)
      throw new ArgumentOutOfRangeException("index");
    int endIndex = (startIndex - count) + 1;
    for (int i = startIndex; i >= endIndex; i--) {
      static if (is(T == class)) {
        if (array[i] is value || (array[i] !is null && array[i] == value))
          return i;
      }
      else {
        if (array[i] == value)
          return i;
      }
    }
    return -1;
  }

}

template removeAt(T) {

  void removeAt(T[] array, int index) {
    T[] temp = array.dup;
    array[index .. $ - 1] = temp[index + 1 .. $];
  }

}

public interface IEqualityComparer(T) {
  bool equals(T x, T y);
  int hashCode(T value);
}

public class EqualityComparer(T) : IEqualityComparer!(T) {

  public bool equals(T x, T y) {
    static if (is(T == class) || is(T == interface)) {
      if (x !is null) {
        if (y !is null)
          return cast(bool)(x == y);
        return false;
      }
      if (y !is null)
        return false;
      return true;
    }
    else
      return x == y;
  }

  public int hashCode(T value) {
    return typeid(T).getHash(&value);
  }

}

public class List(T) {

  private T[] items_;
  private int size_;

  public this(int capacity = 0) {
    if (capacity > 0)
      items_ = new T[capacity];
  }

  public void add(T item) {
    if (size_ == items_.length)
      setCapacity(size_ + 1);
    items_[size_++] = item;
  }

  public void clear() {
    items_ = null;
    size_ = 0;
  }

  public bool contains(T item) {
    auto comparer = new EqualityComparer!(T);
    for (int i = 0; i < size_; i++) {
      if (comparer.equals(items_[i], item))
        return true;
    }
    return false;
  }
 
  public int indexOf(T item) {
    return .indexOf(items_, item, 0, size_);
  }

  public int lastIndexOf(T item) {
    if (size_ == 0)
      return -1;
    return .lastIndexOf(items_, item, size_ - 1, size_);
  }

  public bool remove(T item) {
    int i = indexOf(item);
    if (i >= 0) {
      removeAt(i);
      return true;
    }
    return false;
  }

  public void removeAt(int index) {
    if (index >= size_)
      throw new ArgumentOutOfRangeException("index");
    size_--;
    if (index < size_)
      .removeAt(items_, index);
    items_[size_] = T.init;
  }

  public T[] toArray() {
    return items_[0 .. size_].dup;
  }

  public int capacity() {
    return items_.length;
  }
  public void capacity(int value) {
    if (value != items_.length)
      items_.length = value;
  }

  public int count() {
    return size_;
  }

  public int opApply(int delegate(inout T) del) {
    int r;
    for (int i = 0; i < size_; i++) {
      T item = items_[i];
      if ((r = del(item)) != 0)
        break;
    }
    return r;
  }

  public int opApply(int delegate(inout int, inout T) del) {
    int r;
    for (int i = 0; i < size_; i++) {
      T item = items_[i];
      if ((r = del(i, item)) != 0)
        break;
    }
    return r;
  }

  public T opIndex(int index) {
    if (index >= size_)
      throw new ArgumentOutOfRangeException("index");
    return items_[index];
  }
  public void opIndexAssign(T value, int index) {
    if (index >= size_)
      throw new ArgumentOutOfRangeException("index");
    items_[index] = value;
  }

  private void setCapacity(int minimum) {
    if (items_.length < minimum) {
      int newCapacity = (items_.length == 0) ? 4 : items_.length * 2;
      if (newCapacity < minimum)
        newCapacity = minimum;
      capacity = newCapacity;
    }
  }

}