module juno.base.math;

private import juno.base.native : GetTickCount;

extern(C):

private float fabsf(float d);
private double fabs(double d);

extern(D):

public bool isNaN(float f) {
  return f != f;
}

public bool isNaN(double d) {
  return d != d;
}

public bool isPositiveInfinity(float f) {
  return *(cast(int*)&f) == 0x7F800000;
}

public bool isPositiveInfinity(double d) {
  return d == double.infinity;
}

public bool isNegativeInfinity(float f) {
  return *(cast(int*)&f) == 0xFF800000;
}

public bool isNegativeInfinity(double d) {
  return d == -double.infinity;
}

public bool isInfinity(float f) {
  return (*(cast(int*)&f) & 0x7FFFFFFF) == 0x7F800000;
}

public bool isInfinity(double d) {
  return (*(cast(long*)&d) & 0x7FFFFFFFFFFFFFFF) == 0x7FF0000000000000;
}

public T abs(T)(T value) {
  static if (is(T == byte) ||
    is(T == short) ||
    is(T == int) ||
    is(T == long)) {
    return (value < 0) ? -value : value;
  }
  else static if (is(T == float)) {
    return fabsf(value);
  }
  else static if (is(T == double)) {
    return fabs(value);
  }
}

public T min(T)(T val1, T val2) {
  static if (is(T == ubyte) ||
    is(T == byte) ||
    is(T == ushort) ||
    is(T == short) ||
    is(T == uint) ||
    is(T == int) ||
    is(T == ulong) ||
    is(T == long)) {
    return (val1 > val2) ? val2 : val1;
  }
  else static if (is(T == float) ||
    is(T == double)) {
    return (val1 < val2) ? val1 : isNaN(val1) ? val1 : val2;
  }
}

public T max(T)(T val1, T val2) {
  static if (is(T == ubyte) ||
    is(T == byte) ||
    is(T == ushort) ||
    is(T == short) ||
    is(T == uint) ||
    is(T == int)||
    is(T == ulong) ||
    is(T == long)) {
    return (val1 < val2) ? val2 : val1;
  }
  else static if (is(T == float) ||
    is(T == double)) {
    return (val1 > val2) ? val1 : isNaN(val1) ? val1 : val2;
  }
}

public double random() {
  synchronized {
    static Random rand;
    if (rand is null)
      rand = new Random;
    return rand.nextDouble();
  }
}

// Based on ran3 algorithm.
public class Random {

  private const int SEED = 161803398;
  private const int BITS = 1000000000;

  private int[56] seedList_;
  private int next_, nextp_;

  public this() {
    this(GetTickCount());
  }

  public this(int seed) {
    int j = SEED - abs(seed);
    seedList_[55] = j;
    int k = 1;
    for (int c = 1; c < 55; c++) {
      int i = (21 * c) % 55;
      seedList_[i] = k;
      k = j - k;
      if (k < 0)
        k += BITS;
      j = seedList_[i];
    }

    for (int c = 1; c <= 4; c++) {
      for (int d = 1; d <= 55; d++) {
        seedList_[d] -= seedList_[1 + (d + 30) % 55];
        if (seedList_[d] < 0)
          seedList_[d] += BITS;
      }
    }

    nextp_ = 21;
  }

  public int next() {
    if (++next_ >= 56)
      next_ = 1;
    if (++nextp_ >= 56)
      nextp_ = 1;
    int result = seedList_[next_] - seedList_[nextp_];
    if (result < 0)
      result += BITS;
    seedList_[next_] = result;
    return result;
  }

  public int next(int max) {
    return cast(int)(sample() * max);
  }

  public int next(int min, int max) {
    int range = max - min;
    if (range < 0) {
      long lrange = cast(long)(max - min);
      return cast(int)(cast(long)(sample() * cast(double)lrange) + min);
    }
    return cast(int)(sample() * range) + min;
  }

  public double nextDouble() {
    return sample();
  }

  protected double sample() {
    return next() * (1.0 / BITS);
  }

}