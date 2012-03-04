/**
 * Copyright: (c) 2009 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.base.math;

private import std.math : isnan, abs;
private import std.c.windows.windows : GetTickCount;

double random() {
  synchronized {
    static Random rand;
    if (rand is null)
      rand = new Random;
    return rand.nextDouble();
  }
}

// Based on ran3 algorithm.
class Random {

  private const int SEED = 161803398;
  private const int BITS = 1000000000;

  private int[56] seedList_;
  private int next_, nextp_;

  this() {
    this(GetTickCount());
  }

  this(int seed) {
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

  int next() {
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

  int next(int max) {
    return cast(int)(sample() * max);
  }

  int next(int min, int max) {
    int range = max - min;
    if (range < 0) {
      long lrange = cast(long)(max - min);
      return cast(int)(cast(long)(sample() * cast(double)lrange) + min);
    }
    return cast(int)(sample() * range) + min;
  }

  double nextDouble() {
    return sample();
  }

  protected double sample() {
    return next() * (1.0 / BITS);
  }

}