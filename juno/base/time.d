/**
 * Copyright: (c) 2009 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.base.time;

static import std.string;

private const long TicksPerMillisecond = 10_000;
private const long TicksPerSecond = TicksPerMillisecond * 1_000;
private const long TicksPerMinute = TicksPerSecond * 60;
private const long TicksPerHour = TicksPerMinute * 60;
private const long TicksPerDay = TicksPerHour * 24;

private const int MillisPerSecond = 1_000;
private const int MillisPerMinute = MillisPerSecond * 60;
private const int MillisPerHour = MillisPerMinute * 60;
private const int MillisPerDay = MillisPerHour * 24;

private const double MillisecondsPerTick = 1.0 / TicksPerMillisecond;
private const double SecondsPerTick = 1.0 / TicksPerSecond;
private const double MinutesPerTick = 1.0 / TicksPerMinute;

/**
 * Represents a time interval.
 */
struct TimeSpan {

  /// Represents the _zero TimeSpan value.
  static TimeSpan zero = { 0 };
  
  /// Represents the minimum TimeSpan value.
  static TimeSpan min = { long.min };
  
  /// Represents the maximum TimeSpan value.
  static TimeSpan max = { long.max };

  private long ticks_;

  /**
   * Initializes a new instance.
   * Params: ticks = A time period expressed in 100-nanosecond units.
   */
  static TimeSpan opCall(long ticks) {
    TimeSpan self;
    self.ticks_ = ticks;
    return self;
  }

  /**
   * Initializes a new instance.
   * Params:
   *  hours = Number of _hours.
   *  minutes = Number of _minutes.
   *  seconds = Number of _seconds.
   */
  static TimeSpan opCall(int hours, int minutes, int seconds) {
    TimeSpan self;
    self.ticks_ = (hours * 3600 + minutes * 60 + seconds) * TicksPerSecond;
    return self;
  }

  /**
   * Initializes a new instance.
   * Params:
   *  days = Number of _days.
   *  hours = Number of _hours.
   *  minutes = Number of _minutes.
   *  seconds = Number of _seconds.
   *  milliseconds = Number of _milliseconds.
   */
  static TimeSpan opCall(int days, int hours, int minutes, int seconds, int milliseconds = 0) {
    TimeSpan self;
    self.ticks_ = ((days * 3600 * 24 + hours * 3600 + minutes * 60 + seconds) * 1000 + milliseconds) * TicksPerMillisecond;
    return self;
  }

  /// Gets the _hours component.
  int hours() {
    return cast(int)((ticks_ / TicksPerHour) % 24);
  }

  /// Gets the _minutes component.
  int minutes() {
    return cast(int)((ticks_ / TicksPerMinute) % 60);
  }

  /// Gets the _seconds component.
  int seconds() {
    return cast(int)((ticks_ / TicksPerSecond) % 60);
  }

  /// Gets the _milliseconds component.
  int milliseconds() {
    return cast(int)((ticks_ / TicksPerMillisecond) % 1000);
  }

  /// Gets the value of the instance expressed in whole and fractional milliseconds.
  double totalMilliseconds() {
    return cast(double)ticks_ * MillisecondsPerTick;
  }

  /// Gets the value of the instance expressed in whole and fractional seconds.
  double totalSeconds() {
    return cast(double)ticks_ * SecondsPerTick;
  }

  double totalMinutes() {
    return cast(double)ticks_ * MinutesPerTick;
  }

  /// Gets the _days component.
  int days() {
    return cast(int)(ticks_ / TicksPerDay);
  }

  /// Returns a new instance whose value is the absolute value of the current instance.
  TimeSpan duration() {
    return TimeSpan((ticks_ < 0) ? -ticks_ : ticks_);
  }

  /// Gets the number of _ticks.
  long ticks() {
    return ticks_;
  }

  private static TimeSpan interval(double value, int scale) {
    double d = value * scale;
    double millis = d + (value >= 0 ? 0.5 : -0.5);
    return TimeSpan(cast(long)millis * TicksPerMillisecond);
  }

  /// Returns a TimeSpan representing a specified number of seconds.
  static TimeSpan fromSeconds(double value) {
    return interval(value, MillisPerSecond);
  }

  /// Returns a TimeSpan representing a specified number of milliseconds.
  static TimeSpan fromMilliseconds(double value) {
    return interval(value, 1);
  }

  /**
   * Compares two TimeSpan values and returns an integer indicating whether the first is shorter than, equal to, or longer than the second.
   * Returns: -1 if t1 is shorter than t2; 0 if t1 equals t2; 1 if t1 is longer than t2.
   */
  static int compare(TimeSpan t1, TimeSpan t2) {
    if (t1.ticks_ > t2.ticks_)
      return 1;
    else if (t1.ticks_ < t2.ticks_)
      return -1;
    return 0;
  }

  /**
   * Compares this instance to a specified TimeSpan and returns an integer indicating whether the first is shorter than, equal to, or longer than the second.
   * Returns: -1 if t1 is shorter than t2; 0 if t1 equals t2; 1 if t1 is longer than t2.
   */
  int compareTo(TimeSpan other) {
    if (ticks_ > other.ticks_)
      return 1;
    else if (ticks_ < other.ticks_)
      return -1;
    return 0;
  }

  /// ditto
  int opCmp(TimeSpan other) {
    version(D_Version2) {
      return compare(this, other);
    }
    else {
      return compare(*this, other);
    }
  }

  /**
   * Returns a value indicating whether two instances are equal.
   * Params:
   *   t1 = The first TimeSpan.
   *   t2 = The seconds TimeSpan.
   * Returns: true if the values of t1 and t2 are equal; otherwise, false.
   */
  static bool equals(TimeSpan t1, TimeSpan t2) {
    return t1.ticks_ == t2.ticks_;
  }

  /**
   * Returns a value indicating whether this instance is equal to another.
   * Params: other = An TimeSpan to compare with this instance.
   * Returns: true if other represents the same time interval as this instance; otherwise, false.
   */
  bool equals(TimeSpan other) {
    return ticks_ == other.ticks_;
  }

  /// ditto
  bool opEquals(TimeSpan other) {
    return ticks_ == other.ticks_;
  }

  uint toHash() {
    return cast(int)ticks_ ^ cast(int)(ticks_ >> 32);
  }

  /// Returns a string representation of the value of this instance.
  string toString() {
    string s;

    int day = cast(int)(ticks_ / TicksPerDay);
    long time = ticks_ % TicksPerDay;

    if (ticks_ < 0) {
      s ~= "-";
      day = -day;
      time = -time;
    }
    if (day != 0) {
      s ~= std.string.format("%d", day);
      s ~= ".";
    }
    s ~= std.string.format("%0.2d", cast(int)((time / TicksPerHour) % 24));
    s ~= ":";
    s ~= std.string.format("%0.2d", cast(int)((time / TicksPerMinute) % 60));
    s ~= ":";
    s ~= std.string.format("%0.2d", cast(int)((time / TicksPerSecond) % 60));

    int frac = cast(int)(time % TicksPerSecond);
    if (frac != 0) {
      s ~= ".";
      s ~= std.string.format("%0.7d", frac);
    }

    return s;
  }

  /// Adds the specified TimeSpan to this instance.
  TimeSpan add(TimeSpan ts) {
    return TimeSpan(ticks_ + ts.ticks_);
  }

  /// ditto
  TimeSpan opAdd(TimeSpan ts) {
    return add(ts);
  }

  /// ditto
  void opAddAssign(TimeSpan ts) {
    ticks_ += ts.ticks_;
  }

  /// Subtracts the specified TimeSpan from this instance.
  TimeSpan subtract(TimeSpan ts) {
    return TimeSpan(ticks_ - ts.ticks_);
  }

  /// ditto
  TimeSpan opSub(TimeSpan ts) {
    return subtract(ts);
  }

  /// ditto
  void opSubAssign(TimeSpan ts) {
    ticks_ -= ts.ticks_;
  }

  /// Returns a TimeSpan whose value is the negated value of this instance.
  TimeSpan negate() {
    return TimeSpan(-ticks_);
  }

  /// ditto
  TimeSpan opNeg() {
    return negate();
  }

  TimeSpan opPos() {
    version(D_Version2) {
      return this;
    }
    else {
      return *this;
    }
  }

}