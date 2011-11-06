/**
 * Copyright: (c) 2008 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.locale.time;

private import juno.base.core,
  juno.base.native,
  juno.locale.constants;

private import juno.locale.core : 
  IFormatProvider;

private import juno.locale.format :
  DateTimeFormat,
  NumberFormat,
  formatInt,
  formatDateTime,
  parseDateTime,
  parseDateTimeExact;

/*//////////////////////////////////////////////////////////////////////////////////////////
// Calendars                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////*/

abstract class Calendar {

  package bool isReadOnly_;

  protected int id() {
    return -1;
  }

  package int internalId() {
    return id;
  }

}

class GregorianCalendar : Calendar {

  private static GregorianCalendar defaultInstance_;

  private GregorianCalendarType type_;

  this(GregorianCalendarType type = GregorianCalendarType.Localized) {
    type_ = type;
  }

  protected override int id() {
    return cast(int)type_;
  }

  package static GregorianCalendar defaultInstance() {
    if (defaultInstance_ is null)
      defaultInstance_ = new GregorianCalendar;
    return defaultInstance_;
  }

}

/*//////////////////////////////////////////////////////////////////////////////////////////
// Date/Time                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////*/

private const long TicksPerMillisecond = 10000;
private const long TicksPerSecond = TicksPerMillisecond * 1000;
private const long TicksPerMinute = TicksPerSecond * 60;
private const long TicksPerHour = TicksPerMinute * 60;
private const long TicksPerDay = TicksPerHour * 24;

private const int MillisPerSecond = 1000;
private const int MillisPerMinute = MillisPerSecond * 60;
private const int MillisPerHour = MillisPerMinute * 60;
private const int MillisPerDay = MillisPerHour * 24;

private const int DaysPerYear = 365;
private const int DaysPer4Years = DaysPerYear * 4 + 1;
private const int DaysPer100Years = DaysPer4Years * 25 - 1;
private const int DaysPer400Years = DaysPer100Years * 4 + 1;

private const int DaysTo1601 = DaysPer400Years * 4;
private const int DaysTo1899 = DaysPer400Years * 4 + DaysPer100Years * 3 - 367;
private const int DaysTo10000 = DaysPer400Years * 25 - 366;

private const int[] DaysToMonth365 = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365];
private const int[] DaysToMonth366 = [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366];

private enum DatePart {
  Day,
  DayOfYear,
  Month,
  Year
}

private int getDatePart(long ticks, DatePart part) {
  int n = cast(int)(ticks / TicksPerDay);
  int y400 = n / DaysPer400Years;
  n -= y400 * DaysPer400Years;
  int y100 = n / DaysPer100Years;
  if (y100 == 4) y100 = 3;
  n -= y100 * DaysPer100Years;
  int y4 = n / DaysPer4Years;
  n -= y4 * DaysPer4Years;
  int y1 = n / DaysPerYear;
  if (y1 == 4) y1 = 3;
  if (part == DatePart.Year)
    return y400 * 400 + y100 * 100 + y4 * 4 + y1 + 1;
  n -= y1 * DaysPerYear;
  if (part == DatePart.DayOfYear)
    return n + 1;
  bool leap = y1 == 3 && (y4 != 24 || y100 == 3);
  const(int[]) days = leap ? DaysToMonth366 : DaysToMonth365;
  int m = n >> 5 + 1;
  while (n >= days[m]) m++;
  if (part == DatePart.Month) return m;
  return n - days[m - 1] + 1;
}

struct TimeSpan {

  private long ticks_;

  static const TimeSpan zero = TimeSpan(0);
  static const TimeSpan min =  TimeSpan(long.min);
  static const TimeSpan max =  TimeSpan(long.max);

  static TimeSpan opCall(long ticks) {
    TimeSpan t;
    t.ticks_ = ticks;
    return t;
  }

  static TimeSpan opCall(int hours, int minutes, int seconds) {
    TimeSpan t;
    t.ticks_ = (cast(long)hours * 3600 + cast(long)minutes * 60 + cast(long)seconds) * TicksPerSecond;
    return t;
  }

  static TimeSpan opCall(int days, int hours, int minutes, int seconds) {
    return TimeSpan(days, hours, minutes, seconds, 0);
  }

  static TimeSpan opCall(int days, int hours, int minutes, int seconds, int milliseconds) {
    TimeSpan t;
    t.ticks_ = ((cast(long)days * 3600 * 24 + cast(long)hours * 3600 + cast(long)minutes * 60 + cast(long)seconds) * MillisPerSecond + milliseconds) * TicksPerMillisecond;
    return t;
  }

  TimeSpan add(TimeSpan ts) {
    return TimeSpan(ticks_ + ts.ticks_);
  }

  TimeSpan opAdd(TimeSpan ts) {
    return add(ts);
  }

  TimeSpan opAddAssign(TimeSpan ts) {
    ticks_ += ts.ticks_;
    return this;
  }

  TimeSpan subtract(TimeSpan ts) {
    return TimeSpan(ticks_ - ts.ticks_);
  }

  TimeSpan opSub(TimeSpan ts) {
    return subtract(ts);
  }

  TimeSpan opSubAssign(TimeSpan ts) {
    ticks_ -= ts.ticks_;
    return this;
  }

  TimeSpan negate() {
    return TimeSpan(-ticks_);
  }

  TimeSpan opNeg() {
    return TimeSpan(-ticks_);
  }

  TimeSpan opPos() {
    return this;
  }

  int compare(TimeSpan other) {
    if (ticks_ > other.ticks_)
      return 1;
    else if (ticks_ < other.ticks_)
      return -1;
    return 0;
  }

  int opCmp(TimeSpan other) {
    return compare(other);
  }

  bool equals(ref const(TimeSpan) other) const {
    return ticks_ == other.ticks_;
  }

  bool opEquals(ref const(TimeSpan) other) const {
    return equals(other);
  }

  hash_t toHash() {
    return cast(int)ticks_ ^ cast(int)(ticks_ >> 32);
  }

  string toString() {
    string s;

    if (ticks_ < 0)
      s ~= "-";

    if (days != 0) {
      s ~= formatInt(days, null, null);
      s ~= ".";
    }

    s ~= formatInt(hours, "00", NumberFormat.current);
    s ~= ":";
    s ~= formatInt(minutes, "00", NumberFormat.current);
    s ~= ":";
    s ~= formatInt(seconds, "00", NumberFormat.current);

    int frac = cast(int)(ticks_ % TicksPerSecond);
    if (frac != 0) {
      s ~= ".";
      s ~= formatInt(frac, "0000000", NumberFormat.current);
    }

    return s;
  }

  TimeSpan duration() {
    return TimeSpan((ticks_ < 0) ? -ticks_ : ticks_);
  }

  int days() {
    return cast(int)(ticks_ / TicksPerDay);
  }

  int hours() {
    return cast(int)((ticks_ / TicksPerHour) % 24);
  }

  int minutes() {
    return cast(int)((ticks_ / TicksPerMinute) % 60);
  }

  int seconds() {
    return cast(int)((ticks_ / TicksPerSecond) % 60);
  }

  long ticks() const {
    return ticks_;
  }

}

struct DateTime {

  static DateTime min = { 0 };
  static DateTime max = { DaysTo10000 * TicksPerDay - 1 };

  private ulong data_;

  static DateTime opCall(long ticks) {
    DateTime d;
    d.data_ = cast(ulong)ticks;
    return d;
  }

  static DateTime opCall(int year, int month, int day) {
    DateTime d;
    d.data_ = cast(ulong)dateToTicks(year, month, day);
    return d;
  }

  static DateTime opCall(int year, int month, int day, int hour, int minute, int second) {
    DateTime d;
    d.data_ = cast(ulong)dateToTicks(year, month, day) + timeToTicks(hour, minute, second);
    return d;
  }

  DateTime addTicks(long value) {
    return DateTime(ticks + value);
  }

  DateTime add(TimeSpan value) {
    return addTicks(value.ticks_);
  }

  DateTime opAdd(TimeSpan value) {
    return DateTime(ticks + value.ticks_);
  }

  DateTime opAddAssign(TimeSpan value) {
    data_ += value.ticks_;
    return this;
  }

  DateTime subtract(TimeSpan value) {
    return DateTime(ticks - value.ticks_);
  }

  DateTime opSub(TimeSpan value) {
    return DateTime(ticks - value.ticks_);
  }

  DateTime opSubAssign(TimeSpan value) {
    data_ -= cast(ulong)value.ticks_;
    return this;
  }

  int compare(DateTime other) {
    if (ticks > other.ticks)
      return 1;
    else if (ticks < other.ticks)
      return -1;
    return 0;
  }

  int opCmp(DateTime other) {
    return compare(other);
  }

  bool equals(ref const(DateTime) other) const {
    return ticks == other.ticks;
  }

  bool opEquals(ref const(DateTime) other) const {
    return equals(other);
  }

  hash_t toHash() {
    return cast(int)ticks ^ cast(int)(ticks >> 32);
  }

  static bool isLeapYear(int year) {
    return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
  }

  string toString(string format, IFormatProvider provider) {
    return formatDateTime(this, format, DateTimeFormat.get(provider));
  }

  string toString(string format) {
    return formatDateTime(this, format, DateTimeFormat.current);
  }

  string toString() {
    return formatDateTime(this, null, DateTimeFormat.current);
  }

  string toShortDateString() {
    return formatDateTime(this, "d", DateTimeFormat.current);
  }

  string toLongDateString() {
    return formatDateTime(this, "D", DateTimeFormat.current);
  }

  string toShortTimeString() {
    return formatDateTime(this, "t", DateTimeFormat.current);
  }

  string toLongTimeString() {
    return formatDateTime(this, "T", DateTimeFormat.current);
  }

  static DateTime parse(string s, IFormatProvider provider = null) {
    return parseDateTime(s, DateTimeFormat.get(provider));
  }

  static DateTime parse(string s, string format, IFormatProvider provider = null) {
    return parseDateTimeExact(s, format, DateTimeFormat.get(provider));
  }

  static DateTime fromOleDate(double d) {
    return DateTime(oleDateToTicks(d));
  }

  double toOleDate() {
    return ticksToOleDate(ticks);
  }

  int hour() {
    return cast(int)((ticks / TicksPerHour) % 24);
  }

  int minute() {
    return cast(int)((ticks / TicksPerMinute) % 60);
  }

  int second() {
    return cast(int)((ticks / TicksPerSecond) % 60);
  }

  int millisecond() {
    return cast(int)((ticks / TicksPerMillisecond) % 1000);
  }
  
  TimeSpan timeOfDay() {
    return TimeSpan(ticks % TicksPerDay);
  }

  int day() {
    return getDatePart(ticks, DatePart.Day);
  }

  DayOfWeek dayOfWeek() {
    return cast(DayOfWeek)(cast(int)((ticks / TicksPerDay) + 1) % 7);
  }

  int dayOfYear() {
    return getDatePart(ticks, DatePart.DayOfYear);
  }

  int month() {
    return getDatePart(ticks, DatePart.Month);
  }

  int year() {
    return getDatePart(ticks, DatePart.Year);
  }

  long ticks() const {
    return cast(long)data_;
  }

  static DateTime localNow() {
    FILETIME utcFileTime, localFileTime;
    GetSystemTimeAsFileTime(&utcFileTime);
    FileTimeToLocalFileTime(&utcFileTime, &localFileTime);

    long ticks = (cast(long)localFileTime.dwHighDateTime << 32) | localFileTime.dwLowDateTime;
    return DateTime(ticks + (DaysTo1601 * TicksPerDay));
  }

  static DateTime utcNow() {
    FILETIME utcFileTime;
    GetSystemTimeAsFileTime(&utcFileTime);

    long ticks = (cast(long)utcFileTime.dwHighDateTime << 32) | utcFileTime.dwLowDateTime;
    return DateTime(ticks + (DaysTo1601 * TicksPerDay));
  }

  private static long dateToTicks(int year, int month, int day) {
    const(int[]) days = isLeapYear(year) ? DaysToMonth366 : DaysToMonth365;
    int y = year - 1;
    int n = y * 365 + y / 4 - y / 100 + y / 400 + days[month - 1] + day - 1;
    return n * TicksPerDay;
  }

  private static long timeToTicks(int hour, int minute, int second) {
    return (hour * 3600 + minute * 60 + second) * TicksPerSecond;
  }

  private static long oleDateToTicks(double value) {
    long millis = cast(long)(value * MillisPerDay + (value >= 0 ? 0.5 : -0.5));
    if (millis < 0)
      millis -= (millis % MillisPerDay) * 2;
    millis += (DaysTo1899 * TicksPerDay) / TicksPerMillisecond;
    return millis * TicksPerMillisecond;
  }

  private static double ticksToOleDate(long value) {
    if (value == 0)
      return 0;
    if (value < TicksPerDay)
      value += (DaysTo1899 * TicksPerDay);
    long millis = (value - (DaysTo1899 * TicksPerDay)) / TicksPerMillisecond;
    if (millis < 0) {
      long fraction = millis % MillisPerDay;
      if (fraction != 0)
        millis -= (MillisPerDay + fraction) * 2;
    }
    return cast(double)millis / MillisPerDay;
  }

}
