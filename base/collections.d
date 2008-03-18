/**
 * Copyright: (c) 2008 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.base.collections;

private import juno.locale.text;

private import std.c.string : memmove, memset;

private void clearImpl(T, TIndex = int, TLength = IIndex)(T[] array, TIndex index, TLength length) {
  if (length > 0)
    memset(array.ptr + index, 0, length * T.sizeof);
}

private void copyImpl(T, TIndex = int, TLength = TIndex)(T[] source, TIndex sourceIndex, T[] target, TIndex targetIndex, TLength length) {
  if (length > 0)
    memmove(target.ptr + targetIndex, source.ptr + sourceIndex, length * T.sizeof);
}

private bool equalityComparisonImpl(T)(T a, T b) {
  static if (is(T == class) || is(T == interface)) {
    if (a !is null) {
      if (b !is null) {
        static if (is(typeof(T.opEquals)))
          return cast(bool)a.opEquals(b);
        else
          return cast(bool)typeid(T).equals(&a, &b);
      }
      return false;
    }
    if (b !is null)
      return false;
    return true;
  }
  else static if (is(T == struct)) {
    static if (is(typeof(T.opEquals)))
      return cast(bool)a.opEquals(b);
    else
      return cast(bool)typeid(T).equals(&a, &b);
  }
  else
    return cast(bool)typeid(T).equals(&a, &b);
}

private int comparisonImpl(T)(T a, T b) {
  static if (is(T : string)) {
    return Culture.current.collator.compare(a, b);
  }
  else static if (is(T == class) || is(T == interface)) {
    if (a !is b) {
      if (a !is null) {
        if (b !is null) {
          static if (is(typeof(T.opCmp)))
            return a.opCmp(b);
          else
            return typeid(T).compare(&a, &b);
        }
        return 1;
      }
      return -1;
    }
    return 0;
  }
  else static if (is(T == struct)) {
    static if (is(typeof(T.opCmp)))
      return a.opCmp(b);
    else
      return typeid(T).compare(&a, &b);
  }
  else
    return typeid(T).compare(&a, &b);
}

void sort(T, Index = int, Length = TIndex)(T[] array, Index index, Length length, int delegate(T, T) comparison = null) {

  void quickSortImpl(int left, int right) {
    if (left >= right) return;

    int i = left, j = right;

    T pivot = array[i + ((j - i) >> 1)];

    do {
      while (i < right && comparison(array[i], pivot) < 0) i++;
      while (j > left && comparison(pivot, array[j]) < 0) j--;

      assert(i >= left && j <= right);

      if (i <= j) {
        T temp = array[j];
        array[j] = array[i];
        array[i] = temp;

        i++;
        j--;
      }
    } while (i <= j);

    if (left < j) quickSortImpl(left, j);
    if (i < right) quickSortImpl(i, right);
  }

  if (comparison == null) {
    comparison = (T a, T b) {
      return comparisonImpl(a, b);
    };
  }

  quickSortImpl(index, index + length - 1);
}

void sort(T)(T[] array, int delegate(T, T) comparison = null) {
  .sort(array, 0, array.length, comparison);
}

class List(T) {

  private const int DEFAULT_CAPACITY = 4;

  private T[] items_;
  private int size_;

  /**
   */
  this(int capacity = 0) {
    items_.length = capacity;
  }

  /**
   */
  this(T[] items) {
    items_.length = DEFAULT_CAPACITY;
    foreach (item; items) {
      add(item);
    }
  }

  /**
   */
  final void add(T item) {
    if (size_ == items_.length)
      ensureCapacity(size_ + 1);

    items_[size_++] = item;
  }

  /**
   */
  final void addRange(T[] range) {
    insertRange(size_, range);
  }

  /**
   */
  final void insert(int index, T item) {
    if (size_ == items_.length)
      ensureCapacity(size_ + 1);

    if (index < size_)
      .copyImpl(items_, index, items_, index + 1, size_ - index);

    items_[index] = item;
    size_++;
  }

  /**
   */
  final void insertRange(int index, T[] range) {
    foreach (item; range) {
      insert(index++, item);
    }
  }

  /**
   */
  final bool remove(T item) {
    int i = indexOf(item);
    if (i < 0) 
      return false;
    removeAt(i);
    return true;
  }

  /**
   */
  final void removeAt(int index) {
    size_--;
    if (index < size_)
      .copyImpl(items_, index + 1, items_, index, size_ - index);
    items_[size_] = T.init;
  }

  /**
   * Params:
   *   item = The _item to find.
   *   comparison = The delegate to use for _item comparisons.
   */
  final int indexOf(T item, bool delegate(T, T) comparison) {
    if (comparison is null) {
      comparison = (T a, T b) {
        return equalityComparisonImpl(a, b);
      };
    }

    for (int i = 0; i < size_; i++) {
      if (comparison(items_[i], item))
        return i;
    }

    return -1;
  }

  /**
   * Ditto
   */
  final int indexOf(T item) {
    return indexOf(item, null);
  }

  /**
   */
  final int lastIndexOf(T item, bool delegate(T, T) comparison) {
    if (comparison is null) {
      comparison = (T a, T b) {
        return equalityComparisonImpl(a, b);
      };
    }

    for (int i = size_ - 1; i >= 0; i--) {
      if (comparison(items_[i], item))
        return i;
    }

    return -1;
  }

  /**
   * Ditto
   */
  final int lastIndexOf(T item) {
    return lastIndexOf(item, null);
  }

  /**
   */
  final bool contains(T item) {
    for (int i = 0; i < size_; i++) {
      if (equalityComparisonImpl(items_[i], item))
        return true;
    }
    return false;
  }

  /**
   */
  final void sort(int delegate(T, T) comparison = null) {
    .sort(items_, 0, size_, comparison);
  }

  /**
   */
  final void clear() {
    .clearImpl(items_, 0, size_);
    size_ = 0;
  }

  /**
   */
  final T[] toArray() {
    return items_[0 .. size_].dup;
  }

  /**
   */
  final T find(bool delegate(T) match) {
    for (int i = 0; i < size_; i++) {
      if (match(items_[i]))
        return items_[i];
    }
    return T.init;
  }

  /**
   */
  final T findLast(bool delegate(T) match) {
    for (int i = size_ - 1; i >= 0; i--) {
      if (match(items_[i]))
        return items_[i];
    }
    return T.init;
  }

  /**
   */
  final List findAll(bool delegate(T) match) {
    auto list = new List;
    for (int i = 0; i < size_; i++) {
      if (match(items_[i]))
        list.add(items_[i]);
    }
    return list;
  }

  /**
   */
  final int findIndex(bool delegate(T) match) {
    for (int i = 0; i < size_; i++) {
      if (match(items_[i]))
        return i;
    }
    return -1;
  }

  /**
   */
  final int findLastIndex(bool delegate(T) match) {
    for (int i = size_ - 1; i >= 0; i--) {
      if (match(items_[i]))
        return i;
    }
    return -1;
  }

  /**
   */
  final bool exists(bool delegate(T) match) {
    return findIndex(match) != -1;
  }

  /**
   */
  final void forEach(void delegate(T) action) {
    for (int i = 0; i < size_; i++) {
      action(items_[i]);
    }
  }

  /**
   */
  final bool trueForAll(bool delegate(T) match) {
    for (int i = 0; i < size_; i++) {
      if (!match(items_[i]))
        return false;
    }
    return true;
  }

  /**
   */
  final List!(TOutput) convertAll(TOutput)(TOutput delegate(T) converter) {
    auto list = new List!(TOutput)(size_);
    for (int i = 0; i < size_; i++) {
      list.items_[i] = converter(items_[i]);
    }
    list.size_ = size_;
    return list;
  }

  /**
   */
  final int size() {
    return size_;
  }

  /**
   */
  final void capacity(int value) {
    items_.length = value;
  }

  /**
   * Ditto
   */
  final int capacity() {
    return items_.length;
  }

  /**
   */
  final void opIndexAssign(T value, int index)
  in {
    assert(cast(uint)index < cast(uint)size_, "Argument out of range.");
  }
  body {
    items_[index] = value;
  }

  /**
   * Ditto
   */
  final T opIndex(int index)
  in {
    assert(cast(uint)index < cast(uint)size_, "Argument out of range.");
  }
  body {
    return items_[index];
  }

  /**
   */
  final int opApply(int delegate(ref T) action) {
    int r;

    for (auto i = 0; i < size_; i++) {
      if ((r = action(items_[i])) != 0)
        break;
    }

    return r;
  }

  /**
   * Ditto
   */
  final int opApply(int delegate(ref int, ref T) action) {
    int r;

    for (auto i = 0; i < size_; i++) {
      if ((r = action(i, items_[i])) != 0)
        break;
    }

    return r;
  }

  /**
   */
  final bool opIn_r(T item) {
    return contains(item);
  }

  private void ensureCapacity(int min) {
    if (items_.length < min) {
      int n = (items_.length == 0) 
        ? DEFAULT_CAPACITY 
        : items_.length * 2;

      if (n < min)
        n = min;

      capacity = n;
    }
  }

}