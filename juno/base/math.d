module juno.base.math;

private import juno.base.win32;

public const double PI = 3.14159265358979323846;
public const double E = 2.71828182845904523536;

extern (C) {
private float fabsf(float d);

private double fabs(double d);

private double ceil(double d);

public double acos(double d);

public double asin(double d);

public double atan(double d);

public double atan2(double y, double x);

public double cos(double d);

public double cosh(double d);

public double exp(double d);

public double floor(double d);

public double log(double d);

public double log10(double d);

public double pow(double x, double y);

public double round(double d);

public double sin(double d);

public double sinh(double d);

public double sqrt(double d);

public double tan(double d);

public double tanh(double d);
}

public T abs(T)(T value) {
  static if (is(T : long))
    return (value < 0) ? -value : value;
  else static if (is(T == float))
    return fabsf(value);
  else static if (is(T == double))
    return fabs(value);
  else
    static assert(false, "Operation not supported." ~ T.mangleof);
}

public double ceiling(double d) {
  return ceil(d);
}

public T sign(T)(T value) {
  return (value < 0) ? -1 : (value > 0) ? 1 : 0;
}

public double IEEEremainder(double x, double y) {

  double bitsToDouble(long bits) {
    return *cast(double*)&bits;
  }

  double value = x - (y * round(x / y));
  if (value == 0 && x < 0)
    return bitsToDouble(0x8000000000000000);
  return value;
}

public bool isNaN(float f) {
  return (f != f);
}

public bool isNaN(double d) {
  return (d != d);
}

public bool isInfinity(float f) {
  return ((*cast(int*)&f) & 0x07FFFFFFF) == 0x7F800000;
}

public bool isInfinity(double d) {
  return ((*cast(long*)&d) & 0x07FFFFFFFFFFFFFFF) == 0x7FF0000000000000;
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
    if (++next_ == 56)
      next_ = 1;
    if (++nextp_ == 56)
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