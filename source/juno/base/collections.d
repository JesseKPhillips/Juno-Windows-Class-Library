/**
 * Copyright: (c) 2009 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.base.collections;
 deprecated:

import juno.base.core,
  juno.locale.core,
  std.math;
import std.c.string : memmove, memset;

/**
 * <code>bool delegate(T a, T b)</code>
 */
template EqualityComparison(T) {
  alias bool delegate(T a, T b) EqualityComparison;
}

/**
 * <code>int delegate(T a, T b)</code>
 */
template Comparison(T) {
  alias int delegate(T a, T b) Comparison;
}

/**
 * <code>bool delegate(T obj)</code>
 */
template Predicate(T) {
  alias bool delegate(T) Predicate;
}

/**
 * <code>TOutput delegate(TInput input)</code>
 */
template Converter(TInput, TOutput) {
  alias TOutput delegate(TInput) Converter;
}

/**
 * <code>void delegate(T obj)</code>
 */
template Action(T) {
  alias void delegate(T obj) Action;
}

private bool equalityComparisonImpl(T)(T a, T b) {
  static if (is(T == class) || is(T == interface)) {
    if (a !is null) {
      if (b !is null) {
        static if (is(typeof(T.opEquals))) {
          return cast(bool)a.opEquals(b);
        }
        else {
          return cast(bool)typeid(T).equals(&a, &b);
        }
      }
      return false;
    }
    if (b !is null) {
      return false;
    }
    return true;
  }
  else static if (is(T == struct)) {
    static if (is(T.opEquals)) {
      return cast(bool)a.opEquals(b);
    }
    else {
      return cast(bool)typeid(T).equals(&a, &b);
    }
  }
  else {
    return cast(bool)typeid(T).equals(&a, &b);
  }
}

private int comparisonImpl(T)(T a, T b) {
  static if (is(T : string)) {
    return Culture.current.collator.compare(a, b);
  }
  else static if (is(T == class) || is(T == interface)) {
    if (a !is b) {
      if (a !is null) {
        if (b !is null) {
          static if (is(typeof(T.opCmp))) {
            return a.opCmp(b);
          }
          else {
            return typeid(T).compare(&a, &b);
          }
        }
        return 1;
      }
      return -1;
    }
    return 0;
  }
  else static if (is(T == struct)) {
    static if (is(typeof(T.opCmp))) {
      return a.opCmp(b);
    }
    else {
      return typeid(T).compare(&a, &b);
    }
  }
  else {
    return typeid(T).compare(&a, &b);
  }
}

/*int indexOf(T)(T[] array, T item, EqualityComparison!(T) comparison = null) {
  if (comparison is null) {
    comparison = (T a, T b) {
      return equalityComparisonImpl(a, b);
    };
  }

  for (auto i = 0; i < array.length; i++) {
    if (comparison(array[i], item))
      return i;
  }

  return -1;
}*/

/**
 * Defines methods that compare two objects for equality.
 */
interface IEqualityComparer(T) {

  /**
   * Determines whether the specified objects are equal.
   * Params:
   *   a = The first object to compare.
   *   b = The second object to compare.
   * Returns: true if the specified objects are equal; otherwise, false.
   */
  bool equals(T a, T b);

  /**
   * Retrieves a hash code for the specified object.
   * Params: value = The object for which a hash code is to be retrieved.
   * Returns: The hash code for the specified object.
   */
  uint getHash(T value);

}

/**
 * Provides a base class for implementations of the IEqualityComparer(T) interface.
 */
abstract class EqualityComparer(T) : IEqualityComparer!(T) {

  /**
   * $(I Property.) Returns a default equality comparer for the type specified by the template parameter.
   */
  static EqualityComparer instance() {
    static EqualityComparer instance_;
    if (instance_ is null) {
      instance_ = new class EqualityComparer {
        bool equals(T a, T b) {
          return equalityComparisonImpl(a, b);
        }
        uint getHash(T value) {
          return typeid(T).getHash(&value);
        }
      };
    }
    return instance_;
  }

  /**
   * Determines whether the specified objects are equal.
   * Params:
   *   a = The first object to compare.
   *   b = The second object to compare.
   * Returns: true if the specified objects are equal; otherwise, false.
   */
  abstract bool equals(T a, T b);

  /**
   * Retrieves a hash code for the specified object.
   * Params: value = The object for which a hash code is to be retrieved.
   * Returns: The hash code for the specified object.
   */
  abstract uint getHash(T value);

}

/**
 * Defines a method that compares two objects.
 */
interface IComparer(T) {

  /**
   * Compares two objects and returns a value indicating whether one is less than, equal to, or greater than the other.
   * Params:
   *   a = The first object to _compare.
   *   b = The second object to _compare.
   * Returns: 
   *   $(TABLE $(TR $(TH Value) $(TH Condition))
   *   $(TR $(TD Less than zero) $(TD a is less than b.))
   *   $(TR $(TD Zero) $(TD a equals b.))
   *   $(TR $(TD Greater than zero) $(TD a is greater than b.)))
   */
  int compare(T a, T b);

}

/**
 * Provides a base class for implementations of the IComparer(T) interface.
 */
abstract class Comparer(T) : IComparer!(T) {

  /**
   * $(I Property.) Retrieves a default comparer for the type specified by the template parameter.
   */
  static Comparer instance() {
    static Comparer instance_;
    if (instance_ is null) {
      instance_ = new class Comparer {
        int compare(T a, T b) {
          return comparisonImpl(a, b);
        }
      };
    }
    return instance_;
  }

  /**
   * Compares two objects and returns a value indicating whether one is less than, equal to, or greater than the other.
   * Params:
   *   a = The first object to _compare.
   *   b = The second object to _compare.
   * Returns: 
   *   $(TABLE $(TR $(TH Value) $(TH Condition))
   *   $(TR $(TD Less than zero) $(TD a is less than b.))
   *   $(TR $(TD Zero) $(TD a equals b.))
   *   $(TR $(TD Greater than zero) $(TD a is greater than b.)))
   */
  abstract int compare(T a, T b);

}

/**
 * Sorts the elements int a range of element in an _array using the specified Comparison(T).
 * Params:
 *   array = The _array to _sort.
 *   index = The starting _index of the range to _sort.
 *   length = The number of elements in the range to _sort.
 *   comparison = The Comparison(T) to use when comparing element.
 */
void sort(T, TIndex = int, TLength = TIndex)(T[] array, TIndex index, TLength length, int delegate(T, T) comparison = null) {

  void quickSortImpl(int left, int right) {
    if (left >= right)
      return;

    int i = left, j = right;
    T pivot = array[i + ((j - i) >> 1)];

    do {
      while (i < right && comparison(array[i], pivot) < 0)
        i++;
      while (j > left && comparison(pivot, array[j]) < 0)
        j--;

      assert(i >= left && j <= right);

      if (i <= j) {
        T temp = array[j];
        array[j] = array[i];
        array[i] = temp;

        i++;
        j--;
      }
    } while (i <= j);

    if (left < j)
      quickSortImpl(left, j);
    if (i < right)
      quickSortImpl(i, right);
  }

  if (comparison is null) {
    comparison = (T a, T b) {
      return comparisonImpl(a, b);
    };
  }

  quickSortImpl(index, index + length - 1);
}

/**
 */
void sort(T)(T[] array, int delegate(T, T) comparison = null) {
  .sort(array, 0, array.length, comparison);
}

/**
 * Searches a range of elements in an _array for a value using the specified Comparison(T).
 * Params:
 *   array = The _array to search.
 *   index = The starting _index of the range to search.
 *   length = The number of elements in the range to search.
 *   comparison = The Comparison(T) to use when comparing elements.
 */
int binarySearch(T, TIndex = int, TLength = TIndex)(T[] array, TIndex index, TLength length, T value, int delegate(T, T) comparison = null) {
  if (comparison is null) {
    comparison = (T a, T b) {
      return comparisonImpl(a, b);
    };
  }

  int lo = cast(int)index;
  int hi = cast(int)(index + length - 1);
  while (lo <= hi) {
    int i = lo + ((hi - lo) >> 1);
    int order = comparison(array[i], value);
    if (order == 0)
      return i;
    if (order < 0)
      lo = i + 1;
    else
      hi = i - 1;
  }
  return ~lo;
}

void reverse(T, TIndex = int, TLength = TIndex)(T[] array, TIndex index, TLength length) {
  auto i = index;
  auto j = index + length - 1;
  while (i < j) {
    T temp = array[i];
    array[i] = array[j];
    array[j] = temp;
    i++, j--;
  }
}

/**
 */
void copy(T, TIndex = int, TLength = TIndex)(T[] source, TIndex sourceIndex, T[] target, TIndex targetIndex, TLength length) {
  if (length > 0)
    memmove(target.ptr + targetIndex, source.ptr + sourceIndex, length * T.sizeof);
}

void clear(T, TIndex = int, TLength = IIndex)(T[] array, TIndex index, TLength length) {
  if (length > 0)
    memset(array.ptr + index, 0, length * T.sizeof);
}

TOutput[] convertAll(TInput, TOutput)(TInput[] array, Converter!(TInput, TOutput) converter) {
  auto ret = new TOutput[array.length];
  for (auto i = 0; i < array.length; i++) {
    ret[i] = converter(array[i]);
  }
  return ret;
}

interface IEnumerable(T) {

  version (UseRanges) {
    bool empty();

    void popFront();

    T front();
  }
  else {
    int opApply(int delegate(ref T) action);
  }

}

/**
 * Defines methods to manipulate collections.
 */
interface ICollection(T) : IEnumerable!(T) {

  /**
   * Adds an _item to the collection.
   * Params: item = The object to _add.
   */
  void add(T item);

  /**
   * Removes the first occurence of the specified object from the collection.
   * Params: item = The object to _remove.
   * Returns: true if item was successfully removed; otherwise, false.
   */
  bool remove(T item);

  /**
   * Determines whether the collection _contains the specified object.
   * Params: item = The object to locate.
   * Returns: true if item was found; otherwise, false.
   */
  bool contains(T item);

  /**
   * Removes all items from the collection.
   */
  void clear();

  /**
   * $(I Property.) Gets the number of elements in the collection.
   */
  @property int count();

}

/**
 * Represents a collection of objects that can be accessed by index.
 */
interface IList(T) : ICollection!(T) {

  int indexOf(T item);

  /**
   * Inserts an _item at the specified _index.
   * Params:
   *   index = The _index at which item should be inserted.
   *   item = The object to insert.
   */
  void insert(int index, T item);

  /**
   * Removes the item at the specified _index.
   * Params: index = The _index of the item to remove.
   */
  void removeAt(int index);

  /**
   * Gets or sets the object at the specified _index.
   * Params:
   *   value = The item at the specified _index.
   *   index = The _index of the item to get or set.
   */
  void opIndexAssign(T value, int index);

  /**
   * ditto
   */
  T opIndex(int index);

}

/**
 * Represents a list of elements that can be accessed by index.
 */
class List(T) : IList!(T) {

  private enum DEFAULT_CAPACITY = 4;

  private T[] items_;
  private int size_;

  private int index_;

  /**
   * Initializes a new instance with the specified _capacity.
   * Params: capacity = The number of elements the new list can store.
   */
  this(int capacity = 0) {
    items_.length = capacity;
  }

  /**
   * Initializes a new instance containing elements copied from the specified _range.
   * Params: range = The _range whose elements are copied to the new list.
   */
  this(T[] range) {
    items_.length = size_ = range.length;
    items_ = range;
  }

  /**
   * ditto
   */
  this(IEnumerable!(T) range) {
    items_.length = DEFAULT_CAPACITY;
    foreach (item; range)
      add(item);
  }

  /**
   * Adds an element to the end of the list.
   * Params: item = The element to be added.
   */
  final void add(T item) {
    if (size_ == items_.length)
      ensureCapacity(size_ + 1);
    items_[size_++] = item;
  }

  /**
   * Adds the elements in the specified _range to the end of the list.
   * Params: The _range whose elements are to be added.
   */
  final void addRange(T[] range) {
    insertRange(size_, range);
  }

  /**
   * ditto
   */
  final void addRange(IEnumerable!(T) range) {
    insertRange(size_, range);
  }

  /**
   * Inserts an element into the list at the specified _index.
   * Params:
   *   index = The _index at which item should be inserted.
   *   item = The element to insert.
   */
  final void insert(int index, T item) {
    if (size_ == items_.length)
      ensureCapacity(size_ + 1);

    if (index < size_)
      .copy(items_, index, items_, index + 1, size_ - index);

    items_[index] = item;
    size_++;
  }

  /**
   * Inserts the elements of a _range into the list at the specified _index.
   * Params:
   *   index = The _index at which the new elements should be inserted.
   *   range = The _range whose elements should be inserted into the list.
   */
  final void insertRange(int index, T[] range) {
    foreach (item; range) {
      insert(index++, item);
    }
  }

  /**
   * ditto
   */
  final void insertRange(int index, IEnumerable!(T) range) {
    foreach (item; range) {
      insert(index++, item);
    }
  }

  /**
   */
  final bool remove(T item) {
    int index = indexOf(item);

    if (index < 0)
      return false;

    removeAt(index);
    return true;
  }

  final void removeAt(int index) {
    size_--;
    if (index < size_)
      .copy(items_, index + 1, items_, index, size_ - index);
    items_[size_] = T.init;
  }

  /**
   */
  final void removeRange(int index, int count) {
    if (count > 0) {
      size_ -= count;
      if (index < size_)
        .copy(items_, index + count, items_, index, size_ - index);
      .clear(items_, size_, count);
    }
  }

  /**
   */
  final bool contains(T item) {
    for (auto i = 0; i < size_; i++) {
      if (equalityComparisonImpl(items_[i], item))
        return true;
    }
    return false;
  }

  /**
   */
  final void clear() {
    if (size_ > 0) {
      .clear(items_, 0, size_);
      size_ = 0;
    }
  }

  /**
   */
  final int indexOf(T item) {
    return indexOf(item, null);
  }

  /**
   */
  final int indexOf(T item, EqualityComparison!(T) comparison) {
    if (comparison is null) {
      comparison = (T a, T b) {
        return equalityComparisonImpl(a, b);
      };
    }

    for (auto i = 0; i < size_; i++) {
      if (comparison(items_[i], item))
        return i;
    }

    return -1;
  }

  /**
   */
  final int lastIndexOf(T item, EqualityComparison!(T) comparison = null) {
    if (comparison is null) {
      comparison = (T a, T b) {
        return equalityComparisonImpl(a, b);
      };
    }

    for (auto i = size_ - 1; i >= 0; i--) {
      if (comparison(items_[i], item))
        return i;
    }

    return -1;
  }

  /**
   */
  final void sort(Comparison!(T) comparison = null) {
    .sort(items_, 0, size_, comparison);
  }

  /**
   */
  final int binarySearch(T item, Comparison!(T) comparison = null) {
    return .binarySearch(items_, 0, size_, item, comparison);
  }

  /**
   */
  final void copyTo(T[] array) {
    .copy(items_, 0, array, 0, size_);
  }

  /**
   */
  final T[] toArray() {
    return items_[0 .. size_].dup;
  }

  /**
   */
  final T find(Predicate!(T) match) {
    for (auto i = 0; i < size_; i++) {
      if (match(items_[i]))
        return items_[i];
    }
    return T.init;
  }

  /**
   */
  final T findLast(Predicate!(T) match) {
    for (auto i = size_ - 1; i >= 0; i--) {
      if (match(items_[i]))
        return items_[i];
    }
    return T.init;
  }

  /**
   */
  final List findAll(Predicate!(T) match) {
    auto list = new List;
    for (auto i = 0; i < size_; i++) {
      if (match(items_[i]))
        list.add(items_[i]);
    }
    return list;
  }

  /**
   */
  final int findIndex(Predicate!(T) match) {
    for (auto i = 0; i < size_; i++) {
      if (match(items_[i]))
        return i;
    }
    return -1;
  }

  /**
   */
  final int findLastIndex(Predicate!(T) match) {
    for (auto i = size_ - 1; i >= 0; i--) {
      if (match(items_[i]))
        return i;
    }
    return -1;
  }

  /**
   */
  final bool exists(Predicate!(T) match) {
    return findIndex(match) != -1;
  }

  /**
   */
  final void forEach(Action!(T) action) {
    for (auto i = 0; i < size_; i++) {
      action(items_[i]);
    }
  }

  /**
   */
  final bool trueForAll(Predicate!(T) match) {
    for (auto i = 0; i < size_; i++) {
      if (!match(items_[i]))
        return false;
    }
    return true;
  }

  /**
   */
  final List!(T) getRange(int index, int count) {
    auto list = new List!(T)(count);
    list.items_[0 .. count] = items_[index .. index + count];
    list.size_ = count;
    return list;
  }

  /**
   */
  final List!(TOutput) convert(TOutput)(Converter!(T, TOutput) converter) {
    auto list = new List!(TOutput)(size_);
    for (auto i = 0; i < size_; i++) {
      list.items_[i] = converter(items_[i]);
    }
    list.size_ = size_;
    return list;
  }

  final int count() {
    return size_;
  }

  final @property void capacity(int value) {
    items_.length = value;
  }
  final @property int capacity() {
    return items_.length;
  }

  final void opIndexAssign(T value, int index) {
    if (index >= size_)
      throw new ArgumentOutOfRangeException("index");

    items_[index] = value;
  }
  final T opIndex(int index) {
    if (index >= size_)
      throw new ArgumentOutOfRangeException("index");

    return items_[index];
  }

  version (UseRanges) {
    final bool empty() {
      bool result = (index_ == size_);
      if (result)
        index_ = 0;
      return result;
    }

    final void popFront() {
      if (index_ < size_)
        index_++;
    }

    final T front() {
      return items_[index_];
    }
  }
  else {
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
  }

  final bool opIn_r(T item) {
    return contains(item);
  }

  private void ensureCapacity(int min) {
    if (items_.length < min) {
      int n = (items_.length == 0) ? DEFAULT_CAPACITY : items_.length * 2;
      if (n < min)
        n = min;
      this.capacity = n;
    }
  }

}

/**
 */
class ReadOnlyList(T) : IList!(T) {

  private List!(T) list_;

  this(List!(T) list) {
    list_ = list;
  }

  final int indexOf(T item) {
    return list_.indexOf(item);
  }

  final bool contains(T item) {
    return list_.contains(item);
  }

  final void clear() {
    list_.clear();
  }

  final int count() {
    return list_.count;
  }

  final T opIndex(int index) {
    return list_[index];
  }

  version (UseRanges) {
    final bool empty() {
      return list_.empty;
    }

    final void popFront() {
      list_.popFront();
    }

    final T front() {
      return list_.front;
    }
  }
  else {
    final int opApply(int delegate(ref T) action) {
      return list_.opApply(action);
    }
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

class Collection(T) : IList!(T) {

  private IList!(T) items_;

  this() {
    this(new List!(T));
  }

  this(IList!(T) list) {
    items_ = list;
  }

  final void add(T item) {
    insertItem(items_.count, item);
  }

  final void insert(int index, T item) {
    insertItem(index, item);
  }

  final bool remove(T item) {
    int index = items_.indexOf(item);
    if (index < 0)
      return false;
    removeItem(index);
    return true;
  }

  final void removeAt(int index) {
    removeItem(index);
  }

  final void clear() {
    clearItems();
  }

  final int indexOf(T item) {
    return items_.indexOf(item);
  }

  final bool contains(T item) {
    return items_.contains(item);
  }

  @property final int count() {
    return items_.count;
  }

  final void opIndexAssign(T value, int index) {
    setItem(index, value);
  }
  final T opIndex(int index) {
    return items_[index];
  }

  version (UseRanges) {
    final bool empty() {
      return items_.empty;
    }

    final void popFront() {
      items_.popFront();
    }

    final T front() {
      return items_.front;
    }
  }
  else {
    final int opApply(int delegate(ref T) action) {
      return items_.opApply(action);
    }
  }

  protected void insertItem(int index, T item) {
    items_.insert(index, item);
  }

  protected void removeItem(int index) {
    items_.removeAt(index);
  }

  protected void clearItems() {
    items_.clear();
  }

  protected void setItem(int index, T value) {
    items_[index] = value;
  }

  protected IList!(T) items() {
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

    int limit = cast(int).sqrt(cast(double)candidate);
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

/**
 */
class KeyNotFoundException : Exception {

  this(string message = "The key was not present.") {
    super(message);
  }

}

/**
 */
struct KeyValuePair(K, V) {

  /**
   */
  K key;
  /**
   */
  V value;

}

/**
 */
interface IDictionary(K, V) : ICollection!(KeyValuePair!(K, V)) {

  /**
   */
  void add(K key, V value);

  /**
   */
  bool containsKey(K key);

  /**
   */
  bool remove(K key);

  /**
   */
  bool tryGetValue(K key, out V value);

  /**
   */
  void opIndexAssign(V value, K key);
  /**
   * ditto
   */
  V opIndex(K key);

  /**
   */
  ICollection!(K) keys();

  /**
   */
  ICollection!(V) values();

}

/**
 */
class Dictionary(K, V) : IDictionary!(K, V) {

  private struct Entry {
    int hash; // -1 if not used
    int next; // -1 if last
    K key;
    V value;
  }

  /**
   */
  class KeyCollection : ICollection!(K) {

    version (UseRanges) {
      private int currentIndex_;
    }

    /**
     */
    int count() {
      return this.outer.count;
    }

    version (UseRanges) {
      bool empty() {
        bool result = (currentIndex_ == this.outer.count_);
        if (result)
          currentIndex_ = 0;
        return result;
      }

      void popFront() {
        currentIndex_++;
      }

      K front() {
        return this.outer.entries_[currentIndex_].key;
      }
    }
    else {
      int opApply(int delegate(ref K) action) {
        int r;

        for (int i = 0; i < this.outer.count_; i++) {
          if (this.outer.entries_[i].hash >= 0) {
            if ((r = action(this.outer.entries_[i].key)) != 0)
              break;
          }
        }

        return r;
      }
    }

    protected void add(K item) {
    }

    protected void clear() {
    }

    protected bool contains(K item) {
      return false;
    }

    protected bool remove(K item) {
      return false;
    }

  }

  /**
   */
  class ValueCollection : ICollection!(V) {

    version (UseRanges) {
      private int currentIndex_;
    }

    /**
     */
    int count() {
      return this.outer.count;
    }

    version (UseRanges) {
      bool empty() {
        bool result = (currentIndex_ == this.outer.count_);
        if (result)
          currentIndex_ = 0;
        return result;
      }

      void popFront() {
        currentIndex_++;
      }

      V front() {
        return this.outer.entries_[currentIndex_].value;
      }
    }
    else {
      int opApply(int delegate(ref V) action) {
        int r;

        for (int i = 0; i < this.outer.count_; i++) {
          if (this.outer.entries_[i].hash >= 0) {
            if ((r = action(this.outer.entries_[i].value)) != 0)
              break;
          }
        }

        return r;
      }
    }

    protected void add(V item) {
    }

    protected void clear() {
    }

    protected bool contains(V item) {
      return false;
    }

    protected bool remove(V item) {
      return false;
    }

  }

  private const int BITMASK = 0x7FFFFFFF;

  private IEqualityComparer!(K) comparer_;
  private int[] buckets_;
  private Entry[] entries_;
  private int count_;
  private int freeList_;
  private int freeCount_;

  private KeyCollection keys_;
  private ValueCollection values_;

  version (UseRanges) {
    private int currentIndex_;
  }

  /**
   */
  this(int capacity = 0, IEqualityComparer!(K) comparer = null) {
    if (capacity > 0)
      initialize(capacity);
    if (comparer is null)
      comparer = EqualityComparer!(K).instance;
    comparer_ = comparer;
  }

  /**
   */
  this(IEqualityComparer!(K) comparer) {
    this(0, comparer);
  }

  /**
   */
  final void add(K key, V value) {
    insert(key, value, true);
  }

  /**
   */
  final bool containsKey(K key) {
    return (findEntry(key) >= 0);
  }

  /**
   */
  final bool containsValue(V value) {
    auto comparer = EqualityComparer!(V).instance;
    for (auto i = 0; i < count_; i++) {
      if (entries_[i].hash >= 0 && comparer.equals(entries_[i].value, value))
        return true;
    }
    return false;
  }

  /**
   */
  final bool remove(K key) {
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

  /**
   */
  final void clear() {
    if (count_ != 0) {
      buckets_[] = -1;
      entries_[0 .. count_] = Entry.init;
      freeList_ = -1;
      count_ = freeCount_ = 0;
    }
  }

  /**
   */
  final bool tryGetValue(K key, out V value) {
    int index = findEntry(key);
    if (index >= 0) {
      value = entries_[index].value;
      return true;
    }
    value = V.init;
    return false;
  }

  /**
   */
  final KeyCollection keys() {
    if (keys_ is null)
      keys_ = new KeyCollection;
    return keys_;
  }

  /**
   */
  final ValueCollection values() {
    if (values_ is null)
      values_ = new ValueCollection;
    return values_;
  }

  /**
   */
  final int count() {
    return count_ - freeCount_;
  }

  /**
   */
  final void opIndexAssign(V value, K key) {
    insert(key, value, false);
  }
  /**
   * ditto
   */
  final V opIndex(K key) {
    int index = findEntry(key);
    if (index >= 0)
      return entries_[index].value;
    throw new KeyNotFoundException;
  }

  version (UseRanges) {
    final bool empty() {
      bool result = (currentIndex_ == count_);
      if (result)
        currentIndex_ = 0;
      return result;
    }

    final void popFront() {
      currentIndex_++;
    }

    final KeyValuePair!(K, V) front() {
      return KeyValuePair!(K, V)(entries_[currentIndex_].key, entries_[currentIndex_].value);
    }
  }
  else {
    final int opApply(int delegate(ref KeyValuePair!(K, V)) action) {
      int r;

      for (auto i = 0; i < count_; i++) {
        if (entries_[i].hash >= 0) {
          auto pair = KeyValuePair!(K, V)(entries_[i].key, entries_[i].value);
          if ((r = action(pair)) != 0)
            break;
        }
      }

      return r;
    }
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
    newEntries = entries_;

    for (auto i = 0; i < count_; i++) {
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

  protected void add(KeyValuePair!(K, V) pair) {
    add(pair.key, pair.value);
  }

  protected bool remove(KeyValuePair!(K, V) pair) {
    int index = findEntry(pair.key);
    if (index >= 0 && EqualityComparer!(V).instance.equals(entries_[index].value, pair.value)) {
      remove(pair.key);
      return true;
    }
    return false;
  }

  protected bool contains(KeyValuePair!(K, V) pair) {
    int index = findEntry(pair.key);
    return index >= 0 && EqualityComparer!(V).instance.equals(entries_[index].value, pair.value);
  }

}

/**
 */
class Queue(T) : IEnumerable!(T) {

  private const int DEFAULT_CAPACITY = 4;

  private T[] array_;
  private int head_;
  private int tail_;
  private int size_;

  version (UseRanges) {
    private int currentIndex_ = -2;
  }

  /**
   */
  this(int capacity = 0) {
    array_.length = capacity;
  }

  /**
   */
  this(T[] range) {
    array_.length = DEFAULT_CAPACITY;
    foreach (item; range) {
      enqueue(item);
    }
  }

  /**
   */
  this(IEnumerable!(T) range) {
    array_.length = DEFAULT_CAPACITY;
    foreach (item; range) {
      enqueue(item);
    }
  }

  /**
   */
  final void enqueue(T item) {
    if (size_ == array_.length) {
      int newCapacity = array_.length * 200 / 100;
      if (newCapacity < array_.length + 4)
        newCapacity = array_.length + 4;
      setCapacity(newCapacity);
    }

    array_[tail_] = item;
    tail_ = (tail_ + 1) % array_.length;
    size_++;
  }

  /**
   */
  final T dequeue() {
    T removed = array_[head_];
    array_[head_] = T.init;
    head_ = (head_ + 1) % array_.length;
    size_--;
    return removed;
  }

  /**
   */
  final T peek() {
    return array_[head_];
  }

  /**
   */
  final bool contains(T item) {
    int index = head_;
    int count = size_;

    auto comparer = EqualityComparer!(T).instance;
    while (count-- > 0) {
      if (comparer.equals(array_[index], item))
        return true;
      index = (index + 1) % array_.length;
    }

    return false;
  }

  /**
   */
  final void clear() {
    if (head_ < tail_) {
      .clear(array_, head_, size_);
    }
    else {
      .clear(array_, head_, array_.length - head_);
      .clear(array_, 0, tail_);
    }

    head_ = 0;
    tail_ = 0;
    size_ = 0;
  }

  /**
   * $(I Property.)
   */
  final int count() {
    return size_;
  }

  version (UseRanges) {
    /**
     */
    final bool empty() {
      bool result = (currentIndex_ == size_);
      // Reset current index.
      if (result)
        currentIndex_ = -2;
      return result;
    }

    /**
     */
    final void popFront() {
      currentIndex_++;
    }

    /**
     */
    final T front() {
      if (currentIndex_ == -2)
        currentIndex_ = 0;
      return array_[currentIndex_];
    }
  }
  else {
    final int opApply(int delegate(ref T) action) {
      int r;

      for (auto i = 0; i < size_; i++) {
        if ((r = action(array_[i])) != 0)
          break;
      }

      return r;
    }
  }

  private void setCapacity(int capacity) {
    T[] newArray = new T[capacity];
    if (size_ > 0) {
      if (head_ < tail_) {
        .copy(array_, head_, newArray, 0, size_);
      }
      else {
        .copy(array_, head_, newArray, 0, array_.length - head_);
        .copy(array_, 0, newArray, cast(int)array_.length - head_, tail_);
      }
    }

    array_ = newArray;
    head_ = 0;
    tail_ = (size_ == capacity) ? 0 : size_;
  }

}

class SortedList(K, V) {

  private const int DEFAULT_CAPACITY = 4;

  private IComparer!(K) comparer_;
  private K[] keys_;
  private V[] values_;
  private int size_;

  this() {
    comparer_ = Comparer!(K).instance;
  }

  this(int capacity) {
    keys_.length = capacity;
    values_.length = capacity;
    comparer_ = Comparer!(K).instance;
  }

  final void add(K key, V value) {
    int index = binarySearch!(K)(keys_, 0, size_, key, &comparer_.compare);
    insert(~index, key, value);
  }

  final bool remove(K key) {
    int index = indexOfKey(key);
    if (index >= 0)
      removeAt(index);
    return index >= 0;
  }

  final void removeAt(int index) {
    size_--;
    if (index < size_) {
      .copy(keys_, index + 1, keys_, index, size_ - index);
      .copy(values_, index + 1, values_, index, size_ - index);
    }
    keys_[size_] = K.init;
    values_[size_] = V.init;
  }

  final void clear() {
    .clear(keys_, 0, size_);
    .clear(values_, 0, size_);
    size_ = 0;
  }

  final int indexOfKey(K key) {
    int index = binarySearch!(K)(keys_, 0, size_, key, &comparer_.compare);
    if (index < 0)
      return -1;
    return index;
  }

  final int indexOfValue(V value) {
    foreach (i, v; values_) {
      if (equalityComparisonImpl(v, value))
        return i;
    }
    return -1;
  }

  final bool containsKey(K key) {
    return indexOfKey(key) >= 0;
  }

  final bool containsValue(V value) {
    return indexOfValue(value) >= 0;
  }

  final int count() {
    return size_;
  }

  final void capacity(int value) {
    if (value != keys_.length) {
      keys_.length = value;
      values_.length = value;
    }
  }
  final int capacity() {
    return keys_.length;
  }

  final K[] keys() {
    return keys_.dup;
  }

  final V[] values() {
    return values_.dup;
  }

  final V opIndex(K key) {
    int index = indexOfKey(key);
    if (index >= 0)
      return values_[index];
    return V.init;
  }

  private void insert(int index, K key, V value) {
    if (size_ == keys_.length)
      ensureCapacity(size_ + 1);

    if (index < size_) {
      .copy(keys_, index, keys_, index + 1, size_ - index);
      .copy(values_, index, values_, index + 1, size_ - index);
    }

    keys_[index] = key;
    values_[index] = value;
    size_++;
  }

  private void ensureCapacity(int min) {
    int n = (keys_.length == 0) ? DEFAULT_CAPACITY : keys_.length * 2;
    if (n < min)
      n = min;
    this.capacity = n;
  }

}
