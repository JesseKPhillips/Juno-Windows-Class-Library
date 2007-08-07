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

module juno.base.collections;

private import juno.base.core;

private import std.c.string : memset, memmove;
private import std.math : sqrt;
private import std.array : ArrayBoundsError;

public void clear(T)(T[] array, uint index, uint length) {
  if (array == null)
    throw new ArgumentNullException("array");
  memset(array.ptr + index, 0, length * T.sizeof);
}

public void copy(T)(T[] source, uint sourceIndex, T[] target, uint targetIndex, uint length) {
  if (source == null)
    throw new ArgumentNullException("source");
  if (target == null)
    throw new ArgumentNullException("target");
  if (length < 0)
    throw new ArgumentOutOfRangeException("length", "Value cannot be negative.");
  if (sourceIndex + length > source.length)
    throw new ArgumentException("Source array was not long enough.");
  if (targetIndex + length > target.length)
    throw new ArgumentException("Target array was not long enough.");
  memmove(target.ptr + targetIndex, source.ptr + sourceIndex, length + T.sizeof);
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
  static if (is(T == class) || is(T == interface)) {
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

public void sort(T, TIndex = int, TLength = int)(T[] array, TIndex index = 0, TLength length = -1, int delegate(T a, T b) comparison = null) {
  if (length == -1)
    length = array.length;
  quickSort(array, index, length, comparison);
}

public void quickSort(T, TIndex = int, TLength = int)(T[] array, TIndex index, TLength length, int delegate(T, T) comparison = null) {

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

  /*void quickSortImpl(int left, int right) {

    do {
      int i = left, j = right;
      T pivot = array[i + ((j - i) >> 1)];

      do {
        try {
          while (comparison(array[i], pivot) < 0) i++;
          while (comparison(pivot, array[j]) < 0) j--;
        }
        catch (ArrayBoundsError) {
          throw new ArgumentException(juno.base.string.format("Comparison did not return zero when sort compared x with x. x: '{0}'. x's type: '{1}'.", pivot, T.stringof));
        }
        catch (Exception e) {
          throw new InvalidOperationException("Failed to compare two elements in the array.", e);
        }

        assert(i >= left && j <= right);

        if (i > j) break;
        if (i < j) {
          T temp = array[i];
          array[i] = array[j];
          array[j] = temp;
        }

        i++;
        j--;
      } while (i <= j);

      if (j - left <= right - i) {
        if (left < j) quickSortImpl(left, j);
        left = i;
      }
      else {
        if (i < right) quickSortImpl(i, right);
        right = j;
      }
    } while (left < right);
  }*/

  /*void quickSortImpl(int start, int end) {
    if (end - start < 1)
      return;

    T pivot = array[start];
    int j = start;

    for (int i = start + 1; i <= end; i++) {
      if (comparison(array[i], pivot) < 0) {
        ++j;

        T temp = array[j];
        array[j] = array[i];
        array[i] = temp;
      }
    }

    array[start] = array[j];
    array[j] = pivot;

    quickSortImpl(start, j - 1);
    quickSortImpl(j + 1, end);
  }*/

  /*void quickSortImpl(int left, int right) {

    void swap(int i, int j) {
      T temp = array[i];
      array[i] = array[j];
      array[j] = temp;
    }

    if (left >= right) return;

    int median = (left + right) / 2;

    if (comparison(array[median], array[left]) < 0)
      swap(median, left);
    if (comparison(array[right], array[left]) < 0)
      swap(right, left);
    if (comparison(array[right], array[median]) < 0)
      swap(right, median);

    if (right - left + 1 <= 3) return;

    swap(right - 1, median);

    T pivot = array[right - 1];

    int i = left;
    int j = right - 1;
    for (;;) {
      while (comparison(array[++i], pivot) < 0) {}
      while (comparison(array[--j], pivot) > 0) {}

      if (i < j) swap(i, j);
      else break;
    }

    swap(right - 1, i);

    quickSortImpl(left, i - 1);
    quickSortImpl(i + 1, right);
  }*/

  if (comparison is null) {
    comparison = (T a, T b) {
      return comparisonImpl(a, b);
    };
  }

  quickSortImpl(index, index + length - 1);
}

public void bubbleSort(T)(T[] array, int delegate(T, T) comparison = null) {

  if (comparison is null) {
    comparison = (T a, T b) {
      return comparisonImpl(a, b);
    };
  }

  for (int i = array.length - 1; i > 0; i--) {
    for (int j = 0; j < i; j++) {
      if (comparison(array[j], array[j + 1]) > 0) {
        T temp = array[j];
        array[j] = array[j + 1];
        array[j + 1] = temp;
      }
    }
  }
}

public void reverse(T)(T[] array, int index, int length) {
  if (array == null)
    throw new ArgumentNullException("array");
  uint i = index;
  uint j = index + length - 1;
  while (i < j) {
    T temp = array[i];
    array[i] = array[j];
    array[j] = temp;
    i++, j--;
  }
}

public int binarySearch(T)(T[] array, T value, int index, int length, int delegate(T, T) comparison = null) {
  if (comparison == null) {
    comparison = (T a, T b) {
      return comparisonImpl(a, b);
    };
  }

  int lo = index;
  int hi = (index + length) - 1;
  while (lo <= hi) {
    int n = lo + ((hi - lo) >> 1);
    int order = comparison(array[n], value);
    if (order == 0)
      return n;
    if (order < 0)
      lo = n + 1;
    else
      hi = n - 1;
  }
  return ~lo;
}

public TOutput[] convertAll(TInput, TOutput)(TInput[] array, TOutput delegate(TInput input) converter) {
  TOutput[] result = new TOutput[array.length];
  for (int i = 0; i < array.length; i++)
    result[i] = converter(array[i]);
  return result;
}

public interface IEqualityComparer(T) {
  bool equals(T a, T b);
  hash_t getHash(T value);
}

public abstract class EqualityComparer(T) : IEqualityComparer!(T) {

  private static EqualityComparer instance_;

  public abstract bool equals(T a, T b);
  public abstract hash_t getHash(T value);

  public static EqualityComparer instance() {
    if (instance_ is null) {
      instance_ = new class EqualityComparer {
        bool equals(T a, T b) {
          return equalityComparisonImpl(a, b);
        }
        hash_t getHash(T value) {
          return typeid(T).getHash(&value);
        }
      };
    }
    return instance_;
  }

}

public interface IEnumerable(T) {
  int opApply(int delegate(ref T) action);
}

public interface ICollection(T) : IEnumerable!(T) {
  void add(T item);
  void clear();
  bool contains(T item);
  bool remove(T item);
  void copyTo(T[] array);
  int count();
}

public interface IList(T) : ICollection!(T) {
  int indexOf(T item);
  void insert(int index, T item);
  void removeAt(int index);
  T opIndex(int index);
  void opIndexAssign(T item, int index);
}

public class List(T) : IList!(T) {

  private const int DEFAULT_CAPACITY = 4;

  private T[] items_;
  private int size_;

  public this(int capacity = 0) {
    items_.length = capacity;
  }

  public this(T[] array) {
    items_ = array.dup;
    size_ = array.length;
  }

  public final void add(T item) {
    if (size_ == items_.length)
      items_.length = (items_.length == 0)
      ? DEFAULT_CAPACITY
      : items_.length * 2;

    items_[size_++] = item;
  }

  public final void addRange(T[] array) {
    insertRange(size_, array);
  }

  public final void insert(int index, T item) {
    if (size_ == items_.length)
      items_.length = items_.length + 1;

    if (index < size_) {
      T[] temp = items_[index .. size_].dup;
      items_[index + 1 .. size_ + 1] = temp;
    }

    items_[index] = item;
    size_++;
  }

  public final void insertRange(int index, T[] array) {
    foreach (item; array)
      insert(index++, item);
  }

  public final bool contains(T item) {
    return indexOf(item) != -1;
  }

  public final int binarySearch(T item, int delegate(T, T) comparison) {
    return .binarySearch!(T)(items_, item, 0, size_, comparison);
  }

  public final int indexOf(T item) {
    return indexOf(item, null);
  }
  
  public final int indexOf(T item, bool delegate(T, T) comparison) {
    if (comparison == null) {
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

  public final int lastIndexOf(T item) {
    return lastIndexOf(item, null);
  }

  public final int lastIndexOf(T item, bool delegate(T, T) comparison) {
    if (comparison == null) {
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

  public final bool remove(T item) {
    int i = indexOf(item);
    if (i >= 0) {
      removeAt(i);
      return true;
    }
    return false;
  }

  public final void removeAt(int index) {
    size_--;
    if (index < size_)
      .copy!(T)(items_, index + 1, items_, index, size_ - index);
    items_[size_] = T.init;
  }

  public final void sort(int delegate(T, T) comparison) {
    .sort(items_, 0, size_, comparison);
  }

  public final void clear() {
    .clear!(T)(items_, 0, size_);
    size_ = 0;
  }

  public final void copyTo(T[] array) {
    array[0 .. size_] = items_[0 .. size_];
  }

  public final ReadOnlyList!(T) asReadOnly() {
    return new ReadOnlyList!(T)(this);
  }

  public final T opIndex(int index) {
    return items_[index];
  }

  public final void opIndexAssign(T value, int index) {
    items_[index] = value;
  }

  public final int opApply(int delegate(ref T) action) {
    int r = 0;
    for (int i = 0; i < size_; i++) {
      if ((r = action(items_[i])) != 0)
        break;
    }
    return r;
  }

  public final int opApply(int delegate(ref int, ref T) action) {
    int r = 0;
    for (int i = 0; i < size_; i++) {
      if ((r = action(i, items_[i])) != 0)
        break;
    }
    return r;
  }

  public final int count() {
    return size_;
  }

  public final int capacity() {
    return items_.length;
  }
  public final void capacity(int value) {
    if (items_.length != value)
      items_.length = value;
  }

}

public class ReadOnlyList(T) : IList!(T) {

  private IList!(T) list_;

  public this(List!(T) list) {
    list_ = list;
  }

  public final int indexOf(T item) {
    return list_.indexOf(item);
  }

  public final bool contains(T item) {
    return list_.contains(item);
  }

  public final void clear() {
    list_.clear();
  }

  public final void copyTo(T[] array) {
    list_.copyTo(array);
  }

  public final int count() {
    return list_.count;
  }

  public final T opIndex(int index) {
    return list_[index];
  }

  public final int opApply(int delegate(inout T) action) {
    return list_.opApply(action);
  }

  protected void add(T item) {
    throw new NotSupportedException;
  }

  protected void insert(int index, T item) {
    throw new NotSupportedException;
  }

  protected bool remove(T item) {
    throw new NotSupportedException;
  }

  protected void removeAt(int index) {
    throw new NotSupportedException;
  }

  protected void opIndexAssign(T item, int index) {
    throw new NotSupportedException;
  }

  protected final IList!(T) list() {
    return list_;
  }

}

public class Collection(T) : IList!(T) {

  private IList!(T) items_;

  public this() {
    items_ = new List!(T);
  }

  public final void add(T item) {
    insertItem(items_.count, item);
  }

  public final void clear() {
    clearItems();
  }

  public final bool contains(T item) {
    return items_.contains(item);
  }

  public final void copyTo(T[] array) {
    items_.copyTo(array);
  }

  public final int indexOf(T item) {
    return items_.indexOf(item);
  }

  public final void insert(int index, T item) {
    insertItem(index, item);
  }

  public final bool remove(T item) {
    int index = indexOf(item);
    if (index < 0)
      return false;
    removeItem(index);
    return true;
  }

  public final void removeAt(int index) {
    removeItem(index);
  }

  public final int count() {
    return items_.count;
  }

  public final int opApply(int delegate(ref T) action) {
    return items_.opApply(action);
  }

  public final void opIndexAssign(T value, int index) {
    setItem(index, value);
  }

  public final T opIndex(int index) {
    return items_[index];
  }

  protected void insertItem(int index, T item) {
    items_.insert(index, item);
  }

  protected void setItem(int index, T item) {
    items_[index] = item;
  }

  protected void clearItems() {
    items_.clear();
  }

  protected void removeItem(int index) {
    items_.removeAt(index);
  }

  protected final IList!(T) items() {
    return items_;
  }

}



private const int[] PRIMES = [ 
  3, 7, 11, 17, 23, 29, 37, 47, 59, 71, 89, 107, 131, 163, 197, 239, 293, 353, 431, 521, 631, 761, 919, 
  1103, 1327, 1597, 1931, 2333, 2801, 3371, 4049, 4861, 5839, 7013, 8419, 10103, 12143, 14591, 
  17519, 21023, 25229, 30293, 36353, 43627, 52361, 62851, 75431, 90523, 108631, 130363, 156437, 
  187751, 225307, 270371, 324449, 389357, 467237, 560689, 672827, 807403, 968897, 1162687, 1395263, 
  1674319, 2009191, 2411033, 2893249, 3471899, 4166287, 4999559, 5999471, 7199369 ];

private int getPrime(int min) {
  
  bool isPrime(int candidate) {
    if ((candidate & 1) == 0)
      return candidate == 2;

    int limit = cast(int)sqrt(cast(double)candidate);
    for (int div = 3; div <= limit; div += 2) {
      if ((candidate % div) == 0)
        return false;
    }

    return true;
  }

  foreach (p; PRIMES) {
    if (p >= min)
      return p;
  }

  for (int p = min | 1; p < int.max; p += 2) {
    if (isPrime(p))
      return p;
  }

  return min;
}

public struct Pair(K, V) {

  public K key;
  public V value;

}

public interface IMap(K, V) : ICollection!(Pair!(K, V)) {
  void add(K key, V value);
  bool remove(K key);
  bool tryGetValue(K key, out V value);
  V opIndex(K key);
  void opIndexAssign(V value, K key);
  ICollection!(K) keys();
  ICollection!(V) values();
}

public class KeyNotFoundException : BaseException {

  public this(string message = "The key was not present.", Exception cause = null) {
    super(message, cause);
  }

}

public class Map(K, V) : IMap!(K, V) {

  private struct Entry {
    int hash; // -1 if not used
    int next; // -1 if last
    K key;
    V value;
  }

  private const int BITMASK = 0x7FFFFFFF;

  private IEqualityComparer!(K) comparer_;
  private int[] buckets_;
  private Entry[] entries_;
  private int count_;
  private int freeList_;
  private int freeCount_;
  private ICollection!(K) keys_;
  private ICollection!(V) values_;

  public this(int capacity = 0, IEqualityComparer!(K) comparer = null) {
    if (capacity > 0)
      initialize(capacity);
    if (comparer is null)
      comparer = EqualityComparer!(K).instance;
    comparer_ = comparer;
  }

  public this(IEqualityComparer!(K) comparer) {
    this(0, comparer);
  }

  public final void add(K key, V value) {
    insert(key, value, true);
  }

  public final bool containsKey(K key) {
    return findEntry(key) >= 0;
  }

  public final bool containsValue(V value) {
    auto comparer = EqualityComparer!(V).instance;
    for (int i = 0; i < count_; i++) {
      if (entries_[i].hash >= 0 && comparer.equals(entries_[i].value, value))
        return true;
    }
    return false;
  }

  public final bool remove(K key) {
    if (buckets_ != null) {
      int hash = comparer_.getHash(key) & BITMASK;
      int bucket = hash % buckets_.length;
      int last = -1;
      for (int i = buckets_[bucket]; i >= 0; last = i, i = entries_[i].next) {
        if (entries_[i].hash == hash && comparer_.equals(entries_[i].key, key)) {
          if (last < 0)
            buckets_[bucket] = entries_[i].next;
          else
            entries_[last].next = entries_[i].next;
          entries_[i].hash = i;
          entries_[i].next = freeList_;
          entries_[i].key = K.init;
          entries_[i].value = V.init;
          freeList_ = i;
          freeCount_++;
          return true;
        }
      }
    }
    return false;
  }

  public final void clear() {
    if (count_ != 0) {
      buckets_[] = -1;
      entries_[0 .. count_] = Entry.init;
      freeList_ = -1;
      count_ = freeCount_ = 0;
    }
  }

  public final bool tryGetValue(K key, out V value) {
    int index = findEntry(key);
    if (index >= 0) {
      value = entries_[index].value;
      return true;
    }
    value = V.init;
    return false;
  }

  public final int count() {
    return count_ - freeCount_;
  }

  public final ICollection!(K) keys() {
    if (keys_ is null) {
      keys_ = new class ICollection!(K) {
        int count() {
          return this.outer.count;
        }
        int opApply(int delegate(ref K) action) {
          int r = 0;
          for (int i = 0; i < count_; i++) {
            if (entries_[i].hash >= 0) {
              if ((r = action(entries_[i].key)) != 0)
                break;
            }
          }
          return r;
        }
        void copyTo(K[] array) {
          for (int i = 0; i < this.outer.count_; i++) {
            if (this.outer.entries_[i].hash >= 0)
              array[i] = entries_[i].key;
          }
        }
        void add(K item) {
          throw new NotSupportedException;
        }
        void clear() {
          throw new NotSupportedException;
        }
        bool contains(K item) {
          return this.outer.containsKey(item);
        }
        bool remove(K item) {
          throw new NotSupportedException;
        }
      };
    }
    return keys_;
  }

  public final ICollection!(V) values() {
    if (values_ is null) {
      values_ = new class ICollection!(V) {
        int count() {
          return this.outer.count;
        }
        int opApply(int delegate(ref V) action) {
          int r = 0;
          for (int i = 0; i < count_; i++) {
            if (entries_[i].hash >= 0) {
              if ((r = action(entries_[i].value)) != 0)
                break;
            }
          }
          return r;
        }
        void copyTo(V[] array) {
          for (int i = 0; i < this.outer.count_; i++) {
            if (this.outer.entries_[i].hash >= 0)
              array[i] = entries_[i].value;
          }
        }
        void add(V item) {
          throw new NotSupportedException;
        }
        void clear() {
          throw new NotSupportedException;
        }
        bool contains(V item) {
          return this.outer.containsValue(item);
        }
        bool remove(V item) {
          throw new NotSupportedException;
        }
      };
    }
    return values_;
  }

  public final V opIndex(K key) {
    int index = findEntry(key);
    if (index >= 0)
      return entries_[index].value;
    throw new KeyNotFoundException;
  }
  public final void opIndexAssign(V value, K key) {
    insert(key, value, false);
  }

  public final int opApply(int delegate(ref K, ref V) action) {
    int r = 0;
    for (int i = 0; i < count_; i++) {
      if (entries_[i].hash >= 0) {
        if ((r = action(entries_[i].key, entries_[i].value)) != 0)
          break;
      }
    }
    return r;
  }

  protected final void add(Pair!(K, V) pair) {
    add(pair.key, pair.value);
  }

  protected final bool remove(Pair!(K, V) pair) {
    int index = findEntry(pair.key);
    if (index >= 0 && EqualityComparer!(V).instance.equals(entries_[index].value, pair.value)) {
      remove(pair.key);
      return true;
    }
    return false;
  }

  protected final bool contains(Pair!(K, V) pair) {
    int index = findEntry(pair.key);
    return index >= 0 && EqualityComparer!(V).instance.equals(entries_[index].value, pair.value);
  }

  protected final void copyTo(Pair!(K, V)[] array) {
    for (int i = 0; i < count_; i++) {
      if (entries_[i].hash >= 0)
        array[i] = Pair!(K, V)(entries_[i].key, entries_[i].value);
    }
  }

  protected final int opApply(int delegate(ref Pair!(K, V)) action) {
    int r = 0;

    for (int i = 0; i < count_; i++) {
      if (entries_[i].hash >= 0) {
        auto pair = Pair!(K, V)(entries_[i].key, entries_[i].value);
        if ((r = action(pair)) != 0)
          break;
      }
    }

    return r;
  }

  private void initialize(int capacity) {
    buckets_.length = entries_.length = getPrime(capacity);
    buckets_[] = -1;
  }

  private void insert(K key, V value, bool add) {
    if (buckets_ == null)
      initialize(0);
    int hash = comparer_.getHash(key) & BITMASK;
    for (int i = buckets_[hash % $]; i >= 0; i = entries_[i].next) {
      if (entries_[i].hash == hash && comparer_.equals(entries_[i].key, key)) {
        if (add)
          throw new ArgumentException("An item with the same key has already been added.");
        entries_[i].value = value;
        return;
      }
    }

    int index;
    if (freeCount_ > 0) {
      index = freeList_;
      freeList_ = entries_[index].next;
      freeCount_--;
    }
    else {
      if (count_ == entries_.length)
        increaseCapacity();
      index = count_;
      count_++;
    }

    int bucket = hash % buckets_.length;
    entries_[index].hash = hash;
    entries_[index].next = buckets_[bucket];
    entries_[index].key = key;
    entries_[index].value = value;
    buckets_[bucket] = index;
  }

  private void increaseCapacity() {
    int newSize = getPrime(count_ * 2);
    int[] newBuckets = new int[newSize];
    Entry[] newEntries = new Entry[newSize];

    newBuckets[] = -1;
    newEntries[0 .. count_] = entries_[0 .. count_];

    for (int i = 0; i < count_; i++) {
      int bucket = newEntries[i].hash % newSize;
      newEntries[i].next = newBuckets[bucket];
      newBuckets[bucket] = i;
    }

    buckets_ = newBuckets;
    entries_ = newEntries;
  }

  private int findEntry(K key) {
    if (buckets_ != null) {
      int hash = comparer_.getHash(key) & BITMASK;
      for (int i = buckets_[hash % $]; i >= 0; i = entries_[i].next) {
        if (entries_[i].hash == hash && comparer_.equals(entries_[i].key, key))
          return i;
      }
    }
    return -1;
  }

}

public class Set(T) : ICollection!(T) {

  private struct Entry {
    int hash;
    T value;
    int next;
  }

  private const int BITMASK = 0x7FFFFFFF;

  private int count_;
  private int freeList_;
  private int lastIndex_;
  private int[] buckets_;
  private Entry[] entries_;
  private IEqualityComparer!(T) comparer_;

  public this(IEqualityComparer!(T) comparer = null) {
    if (comparer is null)
      comparer = EqualityComparer!(T).instance;
    comparer_ = comparer;
    freeList_ = -1;
  }

  public final void add(T item) {
    if (buckets_ == null)
      initialize(0);

    int hash = comparer_.getHash(item) & BITMASK;
    for (int i = buckets_[hash % buckets_.length] - 1; i >= 0; i = entries_[i].next) {
      if (entries_[i].hash == hash && comparer_.equals(entries_[i].value, item))
        return;
    }

    int index;
    int bucket = hash % buckets_.length;
    if (freeList_ >= 0) {
      index = freeList_;
      freeList_ = entries_[index].next;
    }
    else {
      if (lastIndex_ == entries_.length) {
        increaseCapacity();
        bucket = hash % buckets_.length;
      }
      index = lastIndex_;
      lastIndex_++;
    }

    entries_[index].hash = hash;
    entries_[index].value = item;
    entries_[index].next = buckets_[bucket] - 1;
    buckets_[bucket] = index + 1;
    count_++;
  }

  public final bool remove(T item) {
    if (buckets_ != null) {
      int hash = comparer_.getHash(item) & BITMASK;
      int bucket = hash % buckets_.length;
      int last = -1;
      for (int i = buckets_[bucket] - 1; i >= 0; last = i, i = entries_[i].next) {
        if (entries_[i].hash == hash && comparer_.equals(entries_[i].value, item)) {
          if (last < 0)
            buckets_[bucket] = entries_[i].next + 1;
          else
            entries_[last].next = entries_[i].next;
          entries_[i].hash = -1;
          entries_[i].value = T.init;
          entries_[i].next = freeList_;
          freeList_ = i;
          count_--;
          return true;
        }
      }
    }
    return false;
  }

  public final int removeWhere(bool delegate(T) match) {
    int n = 0;

    for (int i = 0; i < lastIndex_; i++) {
      if (entries_[i].hash >= 0) {
        T item = entries_[i].value;
        if (match(item) && remove(item))
          n++;
      }
    }

    return n;
  }

  public final bool contains(T item) {
    if (buckets_ != null) {
      int hash = comparer_.getHash(item) & BITMASK;
      for (int i = buckets_[hash % buckets_.length] - 1; i >= 0; i = entries_[i].next) {
        if (entries_[i].hash == hash && comparer_.equals(entries_[i].value, item))
          return true;
      }
    }
    return false;
  }

  public final bool overlaps(T[] other) {
    if (count_ != 0) {
      foreach (item; other) {
        if (contains(item))
          return true;
      }
    }
    return false;
  }

  public final bool overlaps(IEnumerable!(T) other) {
    if (count_ != 0) {
      foreach (item; other) {
        if (contains(item))
          return true;
      }
    }
    return false;
  }

  public final void clear() {
    if (lastIndex_ > 0) {
      entries_[0 .. lastIndex_] = Entry.init;
      buckets_ = null;
      lastIndex_ = 0;
      count_ = 0;
      freeList_ = 0;
    }
  }

  public final void copyTo(T[] array) {
    for (int i = 0, j = 0; i < lastIndex_ && j < count_; i++, j++) {
      if (entries_[i].hash >= 0)
        array[j] = entries_[i].value;
    }
  }

  public final void exceptWith(T[] other) {
    if (count_ != 0) {
      foreach (item; other)
        remove(item);
    }
  }

  public final void exceptWith(IEnumerable!(T) other) {
    if (count_ != 0) {
      if (other is this)
        clear();
      else {
        foreach (item; other)
          remove(item);
      }
    }
  }

  public final void unionWith(T[] other) {
    foreach (value; other)
      add(value);
  }

  public final void unionWith(IEnumerable!(T) other) {
    foreach (value; other)
      add(value);
  }

  public final int count() {
    return count_;
  }

  public final int opApply(int delegate(ref T) action) {
    int r = 0;

    for (int i = 0; i < lastIndex_; i++) {
      if (entries_[i].hash >= 0) {
        if ((r = action(entries_[i].value)) != 0)
          break;
      }
    }

    return r;
  }

  private void initialize(int capacity) {
    buckets_.length = entries_.length = getPrime(capacity);
  }

  private void increaseCapacity() {
    int min = count_ * 2;
    if (min < 0)
      min = count_;
    int newSize = getPrime(min);

    Entry[] newEntries = new Entry[newSize];
    if (entries_ != null)
      newEntries[0 .. lastIndex_] = entries_[0 .. lastIndex_];

    int[] newBuckets = new int[newSize];
    for (int i = 0; i < lastIndex_; i++) {
      int bucket = newEntries[i].hash % newSize;
      newEntries[i].next = newBuckets[bucket] - 1;
      newBuckets[bucket] = i + 1;
    }

    entries_ = newEntries;
    buckets_ = newBuckets;
  }

}

public class Queue(T) : IEnumerable!(T) {

  private T[] array_;
  private int head_;
  private int tail_;
  private int size_;

  public this(int capacity = 0) {
    array_.length = capacity;
  }

  public void enqueue(T item) {
    if (size_ == array_.length) {
      int newCapacity = array_.length * 200 / 100;
      if (newCapacity < array_.length + 4)
        newCapacity = array_.length + 4;

      T[] newItems = new T[newCapacity];
      if (size_ > 0) {
        if (head_ < tail_)
          copy!(T)(array_, head_, newItems, 0, size_);
        else {
          copy!(T)(array_, head_, newItems, 0, array_.length - head_);
          copy!(T)(array_, 0, newItems, array_.length - head_, tail_);
        }
      }
      array_ = newItems;
      head_ = 0;
      tail_ = (size_ == newCapacity) ? 0 : size_;
    }

    array_[tail_] = item;
    tail_ = (tail_ + 1) % array_.length;
    size_++;
  }

  public T dequeue() {
    T ret = array_[head_];
    array_[head_] = T.init;
    head_ = (head_ + 1) % array_.length;
    size_--;
    return ret;
  }

  public T peek() {
    return array_[head_];
  }

  public void clear() {
    if (head_ < tail_)
      .clear!(T)(array_, head_, size_);
    else {
      .clear!(T)(array_, head_, array_.length - head_);
      .clear!(T)(array_, 0, tail_);
    }

    head_ = 0;
    tail_ = 0;
    size_ = 0;
  }

  public int count() {
    return size_;
  }

  public int opApply(int delegate(ref T) action) {
    int result = 0;
    for (int i = 0; i < size_; i++) {
      T item = array_[(head_ + i) % array_.length];
      if ((result = action(item)) != 0)
        break;
    }
    return result;
  }

}