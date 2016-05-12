/**
 * Copyright: (c) 2009 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.locale.time;

import juno.base.core,
  juno.base.time,
  juno.base.native,
  juno.utils.registry,
  juno.locale.constants,
  juno.locale.core;

import std.algorithm : reverse;

debug import std.stdio : writefln;

// This module or classes contained within must not have any 
// static ctors/dtors, otherwise there will be circular references 
// with juno.locale.core.

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

/*//////////////////////////////////////////////////////////////////////////////////////////
// Calendars                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////*/

/**
 * Represents time in divisions such as weeks, months and years.
 */
abstract class Calendar {

  /// Represents the current era.
  static const CurrentEra = 0;

  package bool isReadOnly_;

  /**
   * Returns a DateTime that is the specified number of milliseconds away from the specified DateTime.
   * Params:
   *   time = The DateTime to add to.
   *   value = The number of milliseconds to add.
   */
  DateTime addMilliseconds(DateTime time, int value) {
    long millis = cast(long)(cast(double)value + (value >= 0 ? 0.5 : -0.5));
    return DateTime(time.ticks + (millis * TicksPerMillisecond));
  }

  /**
   * Returns a DateTime that is the specified number of seconds away from the specified DateTime.
   * Params:
   *   time = The DateTime to add to.
   *   value = The number of seconds to add.
   */
  DateTime addSeconds(DateTime time, int value) {
    long millis = cast(long)(cast(double)value * MillisPerSecond + (value >= 0 ? 0.5 : -0.5));
    return DateTime(time.ticks + (millis * TicksPerMillisecond));
  }

  /**
   * Returns a DateTime that is the specified number of minutes away from the specified DateTime.
   * Params:
   *   time = The DateTime to add to.
   *   value = The number of minutes to add.
   */
  DateTime addMinutes(DateTime time, int value) {
    long millis = cast(long)(cast(double)value * MillisPerMinute + (value >= 0 ? 0.5 : -0.5));
    return DateTime(time.ticks + (millis * TicksPerMillisecond));
  }

  /**
   * Returns a DateTime that is the specified number of hours away from the specified DateTime.
   * Params:
   *   time = The DateTime to add to.
   *   value = The number of hours to add.
   */
  DateTime addHours(DateTime time, int value) {
    long millis = cast(long)(cast(double)value * MillisPerHour + (value >= 0 ? 0.5 : -0.5));
    return DateTime(time.ticks + (millis * TicksPerMillisecond));
  }

  /**
   * Returns a DateTime that is the specified number of days away from the specified DateTime.
   * Params:
   *   time = The DateTime to add to.
   *   value = The number of days to add.
   */
  DateTime addDays(DateTime time, int value) {
    long millis = cast(long)(cast(double)value * MillisPerDay + (value >= 0 ? 0.5 : -0.5));
    return DateTime(time.ticks + (millis * TicksPerMillisecond));
  }

  /**
   * Returns a DateTime that is the specified number of weeks away from the specified DateTime.
   * Params:
   *   time = The DateTime to add to.
   *   value = The number of weeks to add.
   */
  DateTime addWeeks(DateTime time, int value) {
    return addDays(time, value * 7);
  }

  /**
   * Returns a DateTime that is the specified number of months away from the specified DateTime.
   * Params:
   *   time = The DateTime to add to.
   *   value = The number of months to add.
   */
  abstract DateTime addMonths(DateTime time, int value);

  /**
   * Returns a DateTime that is the specified number of years away from the specified DateTime.
   * Params:
   *   time = The DateTime to add to.
   *   value = The number of years to add.
   */
  abstract DateTime addYears(DateTime time, int value);

  /**
   * Returns the day of the week in the specified DateTime.
   * Params: time = The DateTime to read.
   */
  abstract DayOfWeek getDayOfWeek(DateTime time);

  /**
   * Returns the day of the month in the specified DateTime.
   * Params: time = The DateTime to read.
   */
  abstract int getDayOfMonth(DateTime time);

  /**
   * Returns the day of the year in the specified DateTime.
   * Params: time = The DateTime to read.
   */
  abstract int getDayOfYear(DateTime time);

  /**
   * Returns the week of the year in the specified DateTime.
   * Params:
   *   time = The DateTime to read.
   *   rule = A value that defines a calendar week.
   *   firstDayOfWeek = A value that represents the first day of the week.
   */
  int getWeekOfYear(DateTime time, CalendarWeekRule rule, DayOfWeek firstDayOfWeek) {

    int getWeekOfYearFirstDay() {
      int dayOfYear = getDayOfYear(time) - 1;
      int dayOfFirstDay = cast(int)getDayOfWeek(time) - (dayOfYear % 7);
      return (dayOfYear + ((dayOfFirstDay - cast(int)firstDayOfWeek + 14) % 7)) / 7 + 1;
    }

    int getWeekOfYearFullDays(int fullDays) {
      int dayOfYear = getDayOfYear(time) - 1;
      int dayOfFirstDay = cast(int)getDayOfWeek(time) - (dayOfYear % 7);
      int offset = (cast(int)firstDayOfWeek - dayOfFirstDay + 14) % 7;
      if (offset != 0 && offset >= fullDays) offset -= 7;
      return (dayOfYear - offset) / 7 + 1;
    }

    switch (rule) {
      case CalendarWeekRule.FirstDay:
        return getWeekOfYearFirstDay();

      case CalendarWeekRule.FirstFullWeek:
        return getWeekOfYearFullDays(7);

      case CalendarWeekRule.FirstFourDayWeek:
        return getWeekOfYearFullDays(4);

      default:
        break;
    }
    throw new ArgumentException("rule");
  }

  /**
   * Returns the hours value in the specified DateTime.
   */
  int getHour(DateTime time) {
    return cast(int)((time.ticks / TicksPerHour) % 24);
  }

  /**
   * Returns the minutes value in the specified DateTime.
   */
  int getMinute(DateTime time) {
    return cast(int)((time.ticks / TicksPerMinute) % 60);
  }

  /**
   * Returns the seconds value in the specified DateTime.
   */
  int getSecond(DateTime time) {
    return cast(int)((time.ticks / TicksPerSecond) % 60);
  }

  /**
   * Returns the milliseconds value in the specified DateTime.
   */
  double getMilliseconds(DateTime time) {
    return cast(double)((time.ticks / TicksPerMillisecond) % 1000);
  }

  /**
   * Returns the era in the specified DateTime.
   */
  abstract int getEra(DateTime time);

  /**
   * Returns the year in the specified DateTime.
   */
  abstract int getYear(DateTime time);

  /**
   * Returns the month in the specified DateTime.
   */
  abstract int getMonth(DateTime time);

  /**
   * Returns the number of days in the specified year and era.
   */
  abstract int getDaysInYear(int year, int era);

  /// ditto
  int getDaysInYear(int year) {
    return getDaysInYear(year, CurrentEra);
  }

  /**
   * Returns the number of days in the specified year, month and era.
   */
  abstract int getDaysInMonth(int year, int month, int era);

  /// ditto
  int getDaysInMonth(int year, int month) {
    return getDaysInMonth(year, month, CurrentEra);
  }

  /**
   * Returns the number of months in the specified year and era.
   */
  abstract int getMonthsInYear(int year, int era);

  /// ditto
  int getMonthsInYear(int year) {
    return getMonthsInYear(year, CurrentEra);
  }

  /**
   * Returns the leap month for the specified year and era.
   */
  int getLeapMonth(int year, int era) {
    if (isLeapYear(year)) {
      int months = getMonthsInYear(year, era);
      for (int month = 1; month <= months; month++) {
        if (isLeapMonth(year, month, era))
          return month;
      }
    }
    return 0;
  }

  /// ditto
  int getLeapMonth(int year) {
    return getLeapMonth(year, CurrentEra);
  }

  /**
   * Determines whether a day is a leap day.
   */
  abstract bool isLeapDay(int year, int month, int day, int era);

  /// ditto
  bool isLeapDay(int year, int month, int day) {
    return isLeapDay(year, month, day, CurrentEra);
  }

  /**
   * Determines whether a month is a leap month.
   */
  abstract bool isLeapMonth(int year, int month, int era);

  /// ditto
  bool isLeapMonth(int year, int month) {
    return isLeapMonth(year, month, CurrentEra);
  }

  /**
   * Determines whether a year is a leap year.
   */
  abstract bool isLeapYear(int year, int era);

  /// ditto
  bool isLeapYear(int year) {
    return isLeapYear(year, CurrentEra);
  }

  /**
   * Gets a value indicating whether the Calendar object is read-only.
   */
  final @property bool isReadOnly() {
    return isReadOnly_;
  }

  abstract @property int[] eras();

  protected @property int id() {
    return -1;
  }

  package @property int internalId() {
    return id;
  }

}

// We can only query NLS for the yearOffset, but certain calendars need a bit more info.
private struct EraInfo {

  int era;
  long startTicks;
  int yearOffset;

}

private EraInfo[] initEraInfo(int cal) {
  switch (cal) {
    case CAL_JAPAN:
      return [ EraInfo(4, DateTime(1989, 1, 8).ticks, 1988),
        EraInfo(3, DateTime(1926, 12, 25).ticks, 1925),
        EraInfo(2, DateTime(1912, 7, 30).ticks, 1911),
        EraInfo(1, DateTime(1868, 1, 1).ticks, 1867) ];
    case CAL_TAIWAN:
      return [ EraInfo(1, DateTime(1912, 1, 1).ticks, 1911) ];
    case CAL_KOREA:
      return [ EraInfo(1, DateTime(1, 1, 1).ticks, -2333) ];
    case CAL_THAI:
      return [ EraInfo(1, DateTime(1, 1, 1).ticks, -543) ];
    default:
  }
  return null;
}

// Defaults for calendars.
package class CalendarData {

  string[] eraNames;
  int currentEra;

  this(string localeName, uint calendarId) {
    getCalendarData(localeName, calendarId);

    switch (calendarId) {
      case CAL_GREGORIAN:
        if (eraNames.length == 0)
          eraNames = [ "A.D." ];
        break;
      case CAL_GREGORIAN_US:
        eraNames = [ "A.D." ];
        break;
      case CAL_JAPAN:
        eraNames = [ "\u660e\u6cbb", "\u5927\u6b63", "\u662d\u548c", "\u5e73\u6210" ];
        break;
      case CAL_TAIWAN:
        eraNames = [ "\u4e2d\u83ef\u6c11\u570b" ];
        break;
      case CAL_KOREA:
        eraNames = [ "\ub2e8\uae30" ];
        break;
      case CAL_HIJRI:
        if (localeName == "dv-MV")
          eraNames = [ "\u0780\u07a8\u0796\u07b0\u0783\u07a9" ];
        else
          eraNames = [ "\u0629\u0631\u062c\u0647\u0644\u0627\u062f\u0639\u0628" ];
        break;
      case CAL_THAI:
        eraNames = [ "\u0e1e.\u0e28." ];
        break;
      case CAL_HEBREW:
        eraNames = [ "C.E." ];
        break;
      case CAL_GREGORIAN_ME_FRENCH:
        eraNames = [ "ap. J.-C." ];
        break;
      case CAL_GREGORIAN_ARABIC, CAL_GREGORIAN_XLIT_ENGLISH, CAL_GREGORIAN_XLIT_FRENCH:
        eraNames = [ "\u0645" ];
        break;
      default:
        eraNames = [ "A.D." ];
        break;
    }

    currentEra = eraNames.length;
  }

  private bool getCalendarData(string localeName, uint calendarId) {
    return enumCalendarInfo(localeName, calendarId, CAL_SERASTRING, eraNames);
  }
  
  private static bool enumCalendarInfo(string localeName, uint calendar, uint calType, out string[] result) {
    static string[] temp;

    extern(Windows)
    static int enumCalendarsProc(wchar* lpCalendarInfoString) {
      import std.string, std.utf;
      temp ~= toUTF8(lpCalendarInfoString[0 .. wcslen(lpCalendarInfoString)]);
      return true;
    }

    uint culture;
    if (!findCultureByName(localeName, localeName, culture))
      return false;

    temp = null;
    if (!EnumCalendarInfo(&enumCalendarsProc, culture, calendar, calType))
      return false;
    reverse(temp);
    result = temp;
    return true;
  }

}

/**
 * Represents the Gregorian calendar.
 */
class GregorianCalendar : Calendar {

  /// Represents the current era.
  static const ADEra = 1;

  private static GregorianCalendar defaultInstance_;

  private GregorianCalendarType type_;
  private int[] eras_;
  private EraInfo[] eraInfo_;

  /**
   */
  this(GregorianCalendarType type = GregorianCalendarType.Localized) {
    type_ = type;
  }

  // Used internally by Japan, Taiwai, Korea, Thai calendars.
  private this(EraInfo[] eraInfo) {
    eraInfo_ = eraInfo;
  }

  override DateTime addMonths(DateTime time, int value) {
    int y = getDatePart(time.ticks, DatePart.Year);
    int m = getDatePart(time.ticks, DatePart.Month);
    int d = getDatePart(time.ticks, DatePart.Day);

    int n = m - 1 + value;
    if (n < 0) {
      m = 12 + (n + 1) % 12;
      y += (n - 11) / 12;
    }
    else {
      m = n % 12 + 1;
      y += n / 12;
    }

    auto daysToMonth = (y % 4 == 0 && (y % 100 != 0 || y % 400 == 0)) ? DaysToMonth366 : DaysToMonth365;
    int days = daysToMonth[m] - daysToMonth[m - 1];
    if (d > days)
      d = days;

    return DateTime(dateToTicks(y, m, d) + time.ticks % TicksPerDay);
  }

  override DateTime addYears(DateTime time, int value) {
    return addMonths(time, value * 12);
  }

  override DayOfWeek getDayOfWeek(DateTime time) {
    return cast(DayOfWeek)(cast(int)((time.ticks / TicksPerDay) + 1) % 7);
  }

  override int getDayOfMonth(DateTime time) {
    return getDatePart(time.ticks, DatePart.Month);
  }

  override int getDayOfYear(DateTime time) {
    return getDatePart(time.ticks, DatePart.DayOfYear);
  }

  override int getEra(DateTime time) {
    long ticks = time.ticks;
    for (int i = 0; i < eraInfo_.length; i++) {
      if (ticks >= eraInfo_[i].startTicks)
        return eraInfo_[i].era;
    }

    return ADEra;
  }

  override int getYear(DateTime time) {
    long ticks = time.ticks;
    int year = getDatePart(ticks, DatePart.Year);

    for (int i = 0; i < eraInfo_.length; i++) {
      if (ticks >= eraInfo_[i].startTicks)
        return year - eraInfo_[i].yearOffset;
    }

    return year;
  }

  override int getMonth(DateTime time) {
    return getDatePart(time.ticks, DatePart.Month);
  }

  alias Calendar.getDaysInYear getDaysInYear;
  override int getDaysInYear(int year, int era) {
    return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? 366 : 365;
  }

  alias Calendar.getDaysInMonth getDaysInMonth;
  override int getDaysInMonth(int year, int month, int era) {
    auto days = (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? DaysToMonth366 : DaysToMonth365;
    return days[month] - days[month - 1];
  }

  alias Calendar.getMonthsInYear getMonthsInYear;
  override int getMonthsInYear(int year, int era) {
    return 12;
  }

  alias Calendar.isLeapDay isLeapDay;
  override bool isLeapDay(int year, int month, int day, int era) {
    if (!isLeapYear(year))
      return false;
    return (month == 2 && day == 29);
  }

  alias Calendar.isLeapMonth isLeapMonth;
  override bool isLeapMonth(int year, int month, int era) {
    return false;
  }

  alias Calendar.isLeapYear isLeapYear;
  override bool isLeapYear(int year, int era) {
    return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0));
  }

  override @property int[] eras() {
    if (eras_ == null) {
      if (eraInfo_ == null) eras_ = [ ADEra ];
      else for (int i = 0; i < eraInfo_.length; i++)
        eras_[i] = eraInfo_[i].era;
    }
    return eras_;
  }

  protected override int id() {
    return cast(int)type_;
  }

  package static @property GregorianCalendar defaultInstance() {
    if (defaultInstance_ is null)
      defaultInstance_ = new GregorianCalendar;
    return defaultInstance_;
  }

  private static long dateToTicks(int year, int month, int day) {
    auto days = (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? DaysToMonth366 : DaysToMonth365;
    int y = year - 1;
    int n = y * 365 + y / 4 - y / 100 + y / 400 + days[month - 1] + day - 1;
    return n * TicksPerDay;
  }

}

/**
 * Represents the Japanese calendar.
 */
class JapaneseCalendar : Calendar {

  private static EraInfo[] eraInfo_;
  private GregorianCalendar base_;

  /**
   */
  this() {
    if (eraInfo_ == null)
      eraInfo_ = initEraInfo(CAL_JAPAN);

    base_ = new GregorianCalendar(eraInfo_);
  }

  override DateTime addMonths(DateTime time, int value) {
    return base_.addMonths(time, value);
  }

  override DateTime addYears(DateTime time, int value) {
    return base_.addYears(time, value);
  }

  override DayOfWeek getDayOfWeek(DateTime time) {
    return base_.getDayOfWeek(time);
  }

  override int getDayOfMonth(DateTime time) {
    return base_.getDayOfMonth(time);
  }

  override int getDayOfYear(DateTime time) {
    return base_.getDayOfYear(time);
  }

  override int getEra(DateTime time) {
    return base_.getEra(time);
  }

  override int getYear(DateTime time) {
    return base_.getYear(time);
  }

  override int getMonth(DateTime time) {
    return base_.getMonth(time);
  }

  alias Calendar.getDaysInYear getDaysInYear;
  override int getDaysInYear(int year, int era) {
    return base_.getDaysInYear(year, era);
  }

  alias Calendar.getDaysInMonth getDaysInMonth;
  override int getDaysInMonth(int year, int month, int era) {
    return base_.getDaysInMonth(year, month, era);
  }

  alias Calendar.getMonthsInYear getMonthsInYear;
  override int getMonthsInYear(int year, int era) {
    return base_.getMonthsInYear(year, era);
  }

  alias Calendar.isLeapDay isLeapDay;
  override bool isLeapDay(int year, int month, int day, int era) {
    return base_.isLeapDay(year, month, day, era);
  }

  alias Calendar.isLeapMonth isLeapMonth;
  override bool isLeapMonth(int year, int month, int era) {
    return base_.isLeapMonth(year, month, era);
  }

  alias Calendar.isLeapYear isLeapYear;
  override bool isLeapYear(int year, int era) {
    return base_.isLeapYear(year, era);
  }

  override @property int[] eras() {
    return base_.eras;
  }

  protected override @property int id() {
    return CAL_JAPAN;
  }

}

/**
 * Represents the Taiwan calendar.
 */
class TaiwanCalendar : Calendar {

  private static EraInfo[] eraInfo_;
  private GregorianCalendar base_;

  /**
   */
  this() {
    if (eraInfo_ == null)
      eraInfo_ = initEraInfo(CAL_TAIWAN);

    base_ = new GregorianCalendar(eraInfo_);
  }

  override DateTime addMonths(DateTime time, int value) {
    return base_.addMonths(time, value);
  }

  override DateTime addYears(DateTime time, int value) {
    return base_.addYears(time, value);
  }

  override DayOfWeek getDayOfWeek(DateTime time) {
    return base_.getDayOfWeek(time);
  }

  override int getDayOfMonth(DateTime time) {
    return base_.getDayOfMonth(time);
  }

  override int getDayOfYear(DateTime time) {
    return base_.getDayOfYear(time);
  }

  override int getEra(DateTime time) {
    return base_.getEra(time);
  }

  override int getYear(DateTime time) {
    return base_.getYear(time);
  }

  override int getMonth(DateTime time) {
    return base_.getMonth(time);
  }

  alias Calendar.getDaysInYear getDaysInYear;
  override int getDaysInYear(int year, int era) {
    return base_.getDaysInYear(year, era);
  }

  alias Calendar.getDaysInMonth getDaysInMonth;
  override int getDaysInMonth(int year, int month, int era) {
    return base_.getDaysInMonth(year, month, era);
  }

  alias Calendar.getMonthsInYear getMonthsInYear;
  override int getMonthsInYear(int year, int era) {
    return base_.getMonthsInYear(year, era);
  }

  alias Calendar.isLeapDay isLeapDay;
  override bool isLeapDay(int year, int month, int day, int era) {
    return base_.isLeapDay(year, month, day, era);
  }

  alias Calendar.isLeapMonth isLeapMonth;
  override bool isLeapMonth(int year, int month, int era) {
    return base_.isLeapMonth(year, month, era);
  }

  alias Calendar.isLeapYear isLeapYear;
  override bool isLeapYear(int year, int era) {
    return base_.isLeapYear(year, era);
  }

  override int[] eras() {
    return base_.eras;
  }

  protected override int id() {
    return CAL_TAIWAN;
  }

}

/**
 * Represents the Korean calendar.
 */
class KoreanCalendar : Calendar {

  private static EraInfo[] eraInfo_;
  private GregorianCalendar base_;

  static const KoreanEra = 1;

  /**
   */
  this() {
    if (eraInfo_ == null)
      eraInfo_ = initEraInfo(CAL_KOREA);

    base_ = new GregorianCalendar(eraInfo_);
  }

  override DateTime addMonths(DateTime time, int value) {
    return base_.addMonths(time, value);
  }

  override DateTime addYears(DateTime time, int value) {
    return base_.addYears(time, value);
  }

  override DayOfWeek getDayOfWeek(DateTime time) {
    return base_.getDayOfWeek(time);
  }

  override int getDayOfMonth(DateTime time) {
    return base_.getDayOfMonth(time);
  }

  override int getDayOfYear(DateTime time) {
    return base_.getDayOfYear(time);
  }

  override int getEra(DateTime time) {
    return base_.getEra(time);
  }

  override int getYear(DateTime time) {
    return base_.getYear(time);
  }

  override int getMonth(DateTime time) {
    return base_.getMonth(time);
  }

  alias Calendar.getDaysInYear getDaysInYear;
  override int getDaysInYear(int year, int era) {
    return base_.getDaysInYear(year, era);
  }

  alias Calendar.getDaysInMonth getDaysInMonth;
  override int getDaysInMonth(int year, int month, int era) {
    return base_.getDaysInMonth(year, month, era);
  }

  alias Calendar.getMonthsInYear getMonthsInYear;
  override int getMonthsInYear(int year, int era) {
    return base_.getMonthsInYear(year, era);
  }

  alias Calendar.isLeapDay isLeapDay;
  override bool isLeapDay(int year, int month, int day, int era) {
    return base_.isLeapDay(year, month, day, era);
  }

  alias Calendar.isLeapMonth isLeapMonth;
  override bool isLeapMonth(int year, int month, int era) {
    return base_.isLeapMonth(year, month, era);
  }

  alias Calendar.isLeapYear isLeapYear;
  override bool isLeapYear(int year, int era) {
    return base_.isLeapYear(year, era);
  }

  override int[] eras() {
    return base_.eras;
  }

  protected override int id() {
    return CAL_KOREA;
  }

}

/**
 * Represents the Korean calendar.
 */
class ThaiBuddhistCalendar : Calendar {

  private static EraInfo[] eraInfo_;
  private GregorianCalendar base_;

  static const ThaiBuddhistEra = 1;

  /**
   */
  this() {
    if (eraInfo_ == null)
      eraInfo_ = initEraInfo(CAL_THAI);

    base_ = new GregorianCalendar(eraInfo_);
  }

  override DateTime addMonths(DateTime time, int value) {
    return base_.addMonths(time, value);
  }

  override DateTime addYears(DateTime time, int value) {
    return base_.addYears(time, value);
  }

  override DayOfWeek getDayOfWeek(DateTime time) {
    return base_.getDayOfWeek(time);
  }

  override int getDayOfMonth(DateTime time) {
    return base_.getDayOfMonth(time);
  }

  override int getDayOfYear(DateTime time) {
    return base_.getDayOfYear(time);
  }

  override int getEra(DateTime time) {
    return base_.getEra(time);
  }

  override int getYear(DateTime time) {
    return base_.getYear(time);
  }

  override int getMonth(DateTime time) {
    return base_.getMonth(time);
  }

  alias Calendar.getDaysInYear getDaysInYear;
  override int getDaysInYear(int year, int era) {
    return base_.getDaysInYear(year, era);
  }

  alias Calendar.getDaysInMonth getDaysInMonth;
  override int getDaysInMonth(int year, int month, int era) {
    return base_.getDaysInMonth(year, month, era);
  }

  alias Calendar.getMonthsInYear getMonthsInYear;
  override int getMonthsInYear(int year, int era) {
    return base_.getMonthsInYear(year, era);
  }

  alias Calendar.isLeapDay isLeapDay;
  override bool isLeapDay(int year, int month, int day, int era) {
    return base_.isLeapDay(year, month, day, era);
  }

  alias Calendar.isLeapMonth isLeapMonth;
  override bool isLeapMonth(int year, int month, int era) {
    return base_.isLeapMonth(year, month, era);
  }

  alias Calendar.isLeapYear isLeapYear;
  override bool isLeapYear(int year, int era) {
    return base_.isLeapYear(year, era);
  }

  override int[] eras() {
    return base_.eras;
  }

  protected override int id() {
    return CAL_THAI;
  }

}

/*//////////////////////////////////////////////////////////////////////////////////////////
// Date/Time                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////*/

enum DateTimeKind {
  Unspecified,
  Utc,
  Local
}

/**
 * Represents an instant in time.
 */
struct DateTime {

  private static const ulong KindUnspecified = 0x0000000000000000;
  private static const ulong KindUtc         = 0x4000000000000000;
  private static const ulong KindLocal       = 0x8000000000000000;
  private static const ulong KindMask        = 0xC000000000000000;
  private static const ulong TicksMask       = 0x3FFFFFFFFFFFFFFF;
  private static const int KindShift         = 0x3E;

  /// Represents the smallest possible DateTime value.
  static DateTime min = { 0 };

  /// Represents the largest possible DateTime value.
  static DateTime max = { DaysTo10000 * TicksPerDay - 1 };

  private ulong data_;

  /**
   * Initializes a new instance.
   */
  static DateTime opCall(long ticks, DateTimeKind kind = DateTimeKind.Unspecified) {
    DateTime self;
    self.data_ = cast(ulong)ticks | (cast(ulong)kind << KindShift);
    return self;
  }

  /**
   * Initializes a new instance.
   */
  static DateTime opCall(int year, int month, int day, DateTimeKind kind = DateTimeKind.Unspecified) {
    DateTime self;
    self.data_ = cast(ulong)dateToTicks(year, month, day) | (cast(ulong)kind << KindShift);
    return self;
  }

  /**
   * Initializes a new instance.
   */
  static DateTime opCall(int year, int month, int day, int hour, int minute, int second, DateTimeKind kind = DateTimeKind.Unspecified) {
    DateTime self;
    self.data_ = (cast(ulong)dateToTicks(year, month, day) + timeToTicks(hour, minute, second)) | (cast(ulong)kind << KindShift);
    return self;
  }

  /**
   * Initializes a new instance.
   */
  static DateTime opCall(int year, int month, int day, int hour, int minute, int second, int millisecond, DateTimeKind kind = DateTimeKind.Unspecified) {
    DateTime self;
    self.data_ = (cast(ulong)dateToTicks(year, month, day) + timeToTicks(hour, minute, second) + (millisecond * TicksPerMillisecond)) | (cast(ulong)kind << KindShift);
    return self;
  }

  /**
   * Adds the specified TimeSpan to the value of this instance.
   */
  DateTime add(TimeSpan value) {
    return DateTime(ticks + value.ticks);
  }

  /// ditto
  DateTime opAdd(TimeSpan value) {
    return DateTime(ticks + value.ticks);
  }

  /// ditto
  void opAddAssign(TimeSpan value) {
    data_ += cast(ulong)value.ticks;
  }

  /**
   * Subtracts the specified number of ticks from the value of this instance.
   */
  DateTime subtract(TimeSpan value) {
    return DateTime(ticks - value.ticks);
  }

  /// ditto
  DateTime opSub(TimeSpan value) {
    return DateTime(ticks - value.ticks);
  }

  /// ditto
  void opSubAssign(TimeSpan value) {
    data_ -= cast(ulong)value.ticks;
  }

  /**
   * Adds the specified number of ticks to the value of this instance.
   */
  DateTime addTicks(long value) {
    return DateTime(ticks + value);
  }

  /**
   * Adds the specfied number of milliseconds to the value of this instance.
   * Params: value = A number of whole a fractional milliseconds.
   */
  DateTime addMilliseconds(double value) {
    long millis = cast(long)(value + (value >= 0 ? 0.5 : -0.5));
    return addTicks(millis * TicksPerMillisecond);
  }

  /**
   * Adds the specfied number of seconds to the value of this instance.
   * Params: value = A number of whole a fractional seconds.
   */
  DateTime addSeconds(double value) {
    long millis = cast(long)(value * MillisPerSecond + (value >= 0 ? 0.5 : -0.5));
    return addTicks(millis * TicksPerMillisecond);
  }

  /**
   * Adds the specfied number of minutes to the value of this instance.
   * Params: value = A number of whole a fractional minutes.
   */
  DateTime addMinutes(double value) {
    long millis = cast(long)(value * MillisPerMinute + (value >= 0 ? 0.5 : -0.5));
    return addTicks(millis * TicksPerMillisecond);
  }

  /**
   * Adds the specfied number of hours to the value of this instance.
   * Params: value = A number of whole a fractional hours.
   */
  DateTime addHours(double value) {
    long millis = cast(long)(value * MillisPerHour + (value >= 0 ? 0.5 : -0.5));
    return addTicks(millis * TicksPerMillisecond);
  }

  /**
   * Adds the specfied number of days to the value of this instance.
   * Params: value = A number of whole a fractional days.
   */
  DateTime addDays(double value) {
    long millis = cast(long)(value * MillisPerDay + (value >= 0 ? 0.5 : -0.5));
    return addTicks(millis * TicksPerMillisecond);
  }

  /**
   * Adds the specified number of months to the value of this instance.
   * Params: value = A number of months.
   */
  DateTime addMonths(int value) {
    int y = getDatePart(ticks, DatePart.Year);
    int m = getDatePart(ticks, DatePart.Month);
    int d = getDatePart(ticks, DatePart.Day);

    int n = m - 1 + value;
    if (n < 0) {
      m = 12 + (n + 1) % 12;
      y += (n - 11) / 12;
    }
    else {
      m = n % 12 + 1;
      y += n / 12;
    }

    int days = daysInMonth(y, m);
    if (d > days)
      d = days;

    return DateTime(dateToTicks(y, m, d) + ticks % TicksPerDay);
  }

  /**
   * Adds the specified number of years to the value of this instance.
   * Params: value = A number of years.
   */
  DateTime addYears(int value) {
    return addMonths(value * 12);
  }

  /**
   * Converts the specified string representation of a date and time to its DateTime equivalent.
   * Params:
   *   s = A string containing a date and time to convert.
   *   provider = An object that supplies culture-specific information about s.
   */
  static DateTime parse(string s, IFormatProvider provider = null) {
    return parseDateTime(s, DateTimeFormat.get(provider));
  }

  /**
   * Converts the specified string representation of a date and time to its DateTime equivalent.
   * Params:
   *   s = A string containing a date and time to convert.
   *   format = A _format specifier that defines the required _format of s.
   *   provider = An object that supplies culture-specific information about s.
   */
  static DateTime parseExact(string s, string format, IFormatProvider provider = null) {
    return parseDateTimeExact(s, format, DateTimeFormat.get(provider));
  }

  /**
   * Converts the specified string representation of a date and time to its DateTime equivalent.
   * Params:
   *   s = A string containing a date and time to convert.
   *   formats = An array of allowable _formats of s.
   *   provider = An object that supplies culture-specific information about s.
   */
  static DateTime parseExact(string s, string[] formats, IFormatProvider provider = null) {
    return parseDateTimeExactMultiple(s, formats, DateTimeFormat.get(provider));
  }

  /**
   * Converts the specified string representation of a date and time to its DateTime equivalent.
   * Params:
   *   s = A string containing a date and time to convert.
   *   result = The DateTime equivalent to the date and time specified in s.
   */
  static bool tryParse(string s, out DateTime result) {
    return tryParseDateTime(s, DateTimeFormat.current, result);
  }

  /**
   * Converts the specified string representation of a date and time to its DateTime equivalent.
   * Params:
   *   s = A string containing a date and time to convert.
   *   provider = An object that supplies culture-specific formatting information.
   *   result = The DateTime equivalent to the date and time specified in s.
   */
  static bool tryParse(string s, IFormatProvider provider, out DateTime result) {
    return tryParseDateTime(s, DateTimeFormat.get(provider), result);
  }

  /**
   * Converts the specified string representation of a date and time to its DateTime equivalent.
   * Params:
   *   s = A string containing a date and time to convert.
   *   format = A _format specifier that defines the required _format of s.
   *   provider = An object that supplies culture-specific formatting information.
   *   result = The DateTime equivalent to the date and time specified in s.
   */
  static bool tryParseExact(string s, string format, IFormatProvider provider, out DateTime result) {
    return tryParseDateTimeExact(s, format, DateTimeFormat.get(provider), result);
  }

  /**
   * Converts the specified string representation of a date and time to its DateTime equivalent.
   * Params:
   *   s = A string containing a date and time to convert.
   *   formats = An array of allowable _formats of s.
   *   provider = An object that supplies culture-specific formatting information.
   *   result = The DateTime equivalent to the date and time specified in s.
   */
  static bool tryParseExact(string s, string[] formats, IFormatProvider provider, out DateTime result) {
    return tryParseDateTimeExactMultiple(s, formats, DateTimeFormat.get(provider), result);
  }

  /**
   * Converts the value of this instance to its equivalent string representation.
   * Params:
   *   format = A DateTime _format string.
   *   provider = An object that supplies culture-specific formatting information.
   */
  string toString(string format, IFormatProvider provider) {
    return formatDateTime(this, format, DateTimeFormat.get(provider));
  }

  /// ditto
  string toString(string format) {
    return formatDateTime(this, format, DateTimeFormat.current);
  }

  /// ditto
  string toString() {
    return formatDateTime(this, null, DateTimeFormat.current);
  }

  /**
   */
  string toShortDateString() {
    return formatDateTime(this, "d", DateTimeFormat.current);
  }

  /**
   */
  string toLongDateString() {
    return formatDateTime(this, "D", DateTimeFormat.current);
  }

  /**
   */
  string toShortTimeString() {
    return formatDateTime(this, "t", DateTimeFormat.current);
  }

  /**
   */
  string toLongTimeString() {
    return formatDateTime(this, "T", DateTimeFormat.current);
  }

  /**
   * Compares two DateTime instances and returns in integer that determines whether the first 
   * is earlier than, the same as, or later than the second.
   * Params:
   *   d1 = The first instance.
   *   d2 = The second instance.
   */
  static int compare(DateTime d1, DateTime d2) {
    if (d1.ticks > d2.ticks)
      return 1;
    else if (d1.ticks < d2.ticks)
      return -1;
    return 0;
  }

  /**
   * Compares the value of this instance to a specified DateTime value and indicates whether this 
   * instance is earlier than, the same as, or later than the specified DateTime value.
   * Params: other = The instance to _compare.
   */
  int compareTo(DateTime other) {
    if (ticks > other.ticks)
      return 1;
    else if (ticks < other.ticks)
      return -1;
    return 0;
  }

  /// ditto
  int opCmp(DateTime other) {
    return compare(this, other);
  }

  /**
   * Indicates whether this instance is equal to the specified DateTime instance.
   * Params: other = The instance to compare to this instance.
   */
  bool equals(DateTime other) {
    return ticks == other.ticks;
  }

  /// ditto
  bool opEquals(DateTime other) {
    return equals(other);
  }

  hash_t toHash() {
    return cast(int)ticks ^ cast(int)(ticks >> 32);
  }

  /**
   */
  DateTime toLocal() {
    return SystemTimeZone.current.toLocal(this);
  }

  /**
   */
  DateTime toUtc() {
    return SystemTimeZone.current.toUtc(this);
  }

  /**
   * Gets the _hour component.
   */
  @property int hour() {
    return cast(int)((ticks / TicksPerHour) % 24);
  }

  /**
   * Gets the _minute component.
   */
  @property int minute() {
    return cast(int)((ticks / TicksPerMinute) % 60);
  }

  /**
   * Gets the _seconds component.
   */
  @property int second() {
    return cast(int)((ticks / TicksPerSecond) % 60);
  }

  /**
   * Gets the _milliseconds component.
   */
  @property int millisecond() {
    return cast(int)((ticks / TicksPerMillisecond) % 1000);
  }

  /**
   * Gets the _day of the month.
   */
  @property int day() {
    return getDatePart(ticks, DatePart.Day);
  }

  /**
   * Gets the day of the week.
   */
  @property DayOfWeek dayOfWeek() {
    return cast(DayOfWeek)(cast(int)((ticks / TicksPerDay) + 1) % 7);
  }

  /**
   * Gets the day of the year.
   */
  @property int dayOfYear() {
    return getDatePart(ticks, DatePart.DayOfYear);
  }

  /**
   * Gets the _month component.
   */
  @property int month() {
    return getDatePart(ticks, DatePart.Month);
  }

  /**
   * Gets the _year component.
   */
  @property int year() {
    return getDatePart(ticks, DatePart.Year);
  }

  /**
   * Gets the _date component.
   */
  @property DateTime date() {
    long ticks = this.ticks;
    return DateTime(ticks - ticks % TicksPerDay);
  }

  /**
   * Gets the number of ticks that represent the date and time.
   */
  @property long ticks() {
    return cast(long)(data_ & TicksMask);
  }

  @property DateTimeKind kind() {
    switch (data_ & KindMask) {
      case KindUtc:
        return DateTimeKind.Utc;
      case KindLocal:
        return DateTimeKind.Local;
      default:
    }
    return DateTimeKind.Unspecified;
  }

  /**
   * Gets the number of days in the specified _month and _year.
   * Params:
   *   year = The _year.
   *   month = The _month.
   */
  static int daysInMonth(int year, int month) {
    auto days = isLeapYear(year) ? DaysToMonth366 : DaysToMonth365;
    return days[month] - days[month - 1];
  }

  /**
   * Indicates whether the specified _year is a leap _year.
   */
  static bool isLeapYear(int year) {
    return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
  }

  @property bool isDaylightSavingTime() {
    return SystemTimeZone.current.isDaylightSavingTime(this);
  }

  /**
   * Gets a DateTime that is set to the current date and time, expressed as the local time.
   */
  static @property DateTime now() {
    FILETIME utcFileTime, localFileTime;
    GetSystemTimeAsFileTime(utcFileTime);
    FileTimeToLocalFileTime(utcFileTime, localFileTime);

    long ticks = (cast(long)localFileTime.dwHighDateTime << 32) | localFileTime.dwLowDateTime;
    return DateTime(ticks + (DaysTo1601 * TicksPerDay), DateTimeKind.Local);
  }

  /**
   * Gets a DateTime that is set to the current date and time, expressed as the Coordinated Universal Time (UTC).
   */
  static @property DateTime utcNow() {
    FILETIME utcFileTime;
    GetSystemTimeAsFileTime(utcFileTime);

    long ticks = (cast(long)utcFileTime.dwHighDateTime << 32) | utcFileTime.dwLowDateTime;
    return DateTime(ticks + (DaysTo1601 * TicksPerDay), DateTimeKind.Utc);
  }

  /**
   * Converts the specified Windows file time to an equivalent local time.
   * Params: fileTime = A Windows file time expressed in ticks.
   */
  static DateTime fromFileTime(long fileTime) {
    long utcTicks = fileTime + (DaysTo1601 * TicksPerDay);

    FILETIME utcFileTime, localFileTime;
    utcFileTime.dwHighDateTime = (utcTicks >> 32) & 0xFFFFFFFF;
    utcFileTime.dwLowDateTime = utcTicks & 0xFFFFFFFF;

    FileTimeToLocalFileTime(utcFileTime, localFileTime);

    long ticks = (cast(long)localFileTime.dwHighDateTime << 32) | localFileTime.dwLowDateTime;
    return DateTime(ticks, DateTimeKind.Local);
  }

  /**
   * Converts the specified Windows file time to an equivalent UTC time.
   * Params: fileTime = A Windows file time expressed in ticks.
   */
  static DateTime fromFileTimeUtc(long fileTime) {
    long ticks = fileTime + (DaysTo1601 * TicksPerDay);
    return DateTime(ticks, DateTimeKind.Utc);
  }

  /**
   */
  long toFileTime() {
    return toUtc().toFileTimeUtc();
  }

  /**
   */
  long toFileTimeUtc() {
    long ticks = (kind == DateTimeKind.Local) ? toUtc().ticks : ticks;
    ticks -= (DaysTo1601 * TicksPerDay);
    return ticks;
  }

  /+long toFileTime() {
    long utcTicks = ticks - (DaysTo1601 * TicksPerDay);

    FILETIME utcFileTime, localFileTime;
    utcFileTime.dwHighDateTime = (utcTicks >> 32) & 0xFFFFFFFF;
    utcFileTime.dwLowDateTime = utcTicks & 0xFFFFFFFF;

    FileTimeToLocalFileTime(utcFileTime, localFileTime);

    return (cast(long)localFileTime.dwHighDateTime << 32) | localFileTime.dwLowDateTime;
  }

  long toFileTimeUtc() {
    return ticks - (DaysTo1601 * TicksPerDay);
  }+/

  /**
   * Converts an OLE Automation date to a DateTime.
   * Params: d = An OLE Automation date.
   */
  static DateTime fromOleDate(double d) {
    return DateTime(oleDateToTicks(d));
  }

  /**
   * Converts the value of this instance to an OLE Automation date.
   */
  double toOleDate() {
    return ticksToOleDate(ticks);
  }

  private static long dateToTicks(int year, int month, int day) {
    auto days = isLeapYear(year) ? DaysToMonth366 : DaysToMonth365;
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

class DaylightTime {

  private DateTime start_;
  private DateTime end_;
  private TimeSpan delta_;

  this(DateTime start, DateTime end, TimeSpan delta) {
    start_ = start;
    end_ = end;
    delta_ = delta;
  }

  @property DateTime start() {
    return start_;
  }

  @property DateTime end() {
    return end_;
  }

  @property TimeSpan delta() {
    return delta_;
  }

}

// Not public because it only represents the current time zone on the computer.
// Its primary purpose is to convert between Local and Utc time.
private class SystemTimeZone {

  private static SystemTimeZone current_;

  private long ticksOffset_;
  private DaylightTime[int] daylightChanges_;

  static @property SystemTimeZone current() {
    synchronized (SystemTimeZone.classinfo) {
      if (current_ is null)
        current_ = new SystemTimeZone;
      return current_;
    }
  }

  private this() {
    TIME_ZONE_INFORMATION timeZoneInfo;
    GetTimeZoneInformation(timeZoneInfo);
    ticksOffset_ = (-timeZoneInfo.Bias) * TicksPerMinute;
  }

  bool isDaylightSavingTime(DateTime time) {
    return isDaylightSavingTime(time, getDaylightChanges(time.year));
  }

  bool isDaylightSavingTime(DateTime time, DaylightTime daylightTime) {
    return getUtcOffset(time, daylightTime) != TimeSpan.zero;
  }

  DateTime toLocal(DateTime time) {
    if (time.kind == DateTimeKind.Local)
      return time;

    long ticks = time.ticks + getUtcOffsetFromUtc(time, getDaylightChanges(time.year)).ticks;
    if (ticks > DateTime.max.ticks)
      return DateTime(DateTime.max.ticks, DateTimeKind.Local);
    if (ticks < DateTime.min.ticks)
      return DateTime(DateTime.min.ticks, DateTimeKind.Local);
    return DateTime(ticks, DateTimeKind.Local);
  }

  DateTime toUtc(DateTime time) {
    if (time.kind == DateTimeKind.Utc)
      return time;

    long ticks = time.ticks - getUtcOffset(time, getDaylightChanges(time.year)).ticks + ticksOffset_;
    if (ticks > DateTime.max.ticks)
      return DateTime(DateTime.max.ticks, DateTimeKind.Utc);
    if (ticks < DateTime.min.ticks)
      return DateTime(DateTime.min.ticks, DateTimeKind.Utc);
    return DateTime(ticks, DateTimeKind.Utc);
  }

  DaylightTime getDaylightChanges(int year) {

    DateTime getDayOfSunday(int year, bool fixed, int month, int dayOfWeek, int day, int hour, int minute, int second, int millisecond) {
      if (fixed) {
        int d = DateTime.daysInMonth(year, month);
        return DateTime(year, month, (d < day) ? d : day, hour, minute, second, millisecond);
      }
      else if (day <= 4) {
        DateTime time = DateTime(year, month, 1, hour, minute, second, millisecond);
        int delta = dayOfWeek - cast(int)time.dayOfWeek;
        if (delta < 0)
          delta += 7;
        delta += 7 * (day - 1);
        if (delta > 0)
          time = time.addDays(delta);
        return time;
      }
      else {
        auto cal = GregorianCalendar.defaultInstance;
        DateTime time = DateTime(year, month, cal.getDaysInMonth(year, month), hour, minute, second, millisecond);
        int delta = cast(int)time.dayOfWeek - dayOfWeek;
        if (delta < 0)
          delta += 7;
        if (delta > 0)
          time = time.addDays(-delta);
        return time;
      }
    }

    synchronized (SystemTimeZone.classinfo) {
      if (!(year in daylightChanges_)) {
        TIME_ZONE_INFORMATION timeZoneInfo;
        uint r = GetTimeZoneInformation(timeZoneInfo);
        if (r == TIME_ZONE_ID_INVALID || timeZoneInfo.DaylightBias == 0) {
          daylightChanges_[year] = new DaylightTime(DateTime.min, DateTime.max, TimeSpan.zero);
        }
        else {
          DateTime start = getDayOfSunday(
            year, 
            (timeZoneInfo.DaylightDate.wYear != 0), 
            timeZoneInfo.DaylightDate.wMonth, 
            timeZoneInfo.DaylightDate.wDayOfWeek, 
            timeZoneInfo.DaylightDate.wDay, 
            timeZoneInfo.DaylightDate.wHour,
            timeZoneInfo.DaylightDate.wMinute,
            timeZoneInfo.DaylightDate.wSecond,
            timeZoneInfo.DaylightDate.wMilliseconds);
          DateTime end = getDayOfSunday(
            year, 
            (timeZoneInfo.StandardDate.wYear != 0), 
            timeZoneInfo.StandardDate.wMonth, 
            timeZoneInfo.StandardDate.wDayOfWeek, 
            timeZoneInfo.StandardDate.wDay, 
            timeZoneInfo.StandardDate.wHour,
            timeZoneInfo.StandardDate.wMinute,
            timeZoneInfo.StandardDate.wSecond,
            timeZoneInfo.StandardDate.wMilliseconds);
          TimeSpan delta = TimeSpan((-timeZoneInfo.DaylightBias) * TicksPerMinute);

          daylightChanges_[year] = new DaylightTime(start, end, delta);
        }
      }

      return daylightChanges_[year];
    }
  }

  private TimeSpan getUtcOffsetFromUtc(DateTime time, DaylightTime daylightTime) {
    TimeSpan offset = TimeSpan(ticksOffset_);

    if (daylightTime is null || daylightTime.delta.ticks == 0)
      return offset;

    DateTime start = daylightTime.start - offset;
    DateTime end = daylightTime.end - offset - daylightTime.delta;

    bool isDaylightSavingTime;
    if (start > end)
      isDaylightSavingTime = (time < end || time >= start);
    else
      isDaylightSavingTime = (time >= start && time < end);

    if (isDaylightSavingTime)
      offset += daylightTime.delta;

    return offset;
  }

  private TimeSpan getUtcOffset(DateTime time, DaylightTime daylightTime) {
    if (daylightTime is null || time.kind == DateTimeKind.Utc)
      return TimeSpan.zero;

    DateTime start = daylightTime.start + daylightTime.delta;
    DateTime end = daylightTime.end;

    bool isDaylightSavingTime;
    if (start > end)
      isDaylightSavingTime = (time < end || time >= start);
    else
      isDaylightSavingTime = (time >= start && time < end);

    return (isDaylightSavingTime ? daylightTime.delta : TimeSpan.zero);
  }

}

package string formatDateTime(DateTime dateTime, string format, DateTimeFormat dtf) {

  string expandKnownFormat(string format, ref DateTime dateTime, ref DateTimeFormat dtf) {
    switch (format[0]) {
      case 'd':
        return dtf.shortDatePattern;
      case 'D':
        return dtf.longDatePattern;
      case 'f':
        return dtf.longDatePattern ~ " " ~ dtf.shortTimePattern;
      case 'F':
        return dtf.fullDateTimePattern;
      case 'g':
        return dtf.generalShortTimePattern;
      case 'G':
        return dtf.generalLongTimePattern;
      case 'r', 'R':
        return dtf.rfc1123Pattern;
      case 's':
        return dtf.sortableDateTimePattern;
      case 't':
        return dtf.shortTimePattern;
      case 'T':
        return dtf.longTimePattern;
      case 'u':
        return dtf.universalSortableDateTimePattern;
      case 'y', 'Y':
        return dtf.yearMonthPattern;
      default:
    }
    throw new FormatException("Input string was invalid.");
  }

  int parseRepeat(string format, int pos, char c) {
    int n = pos + 1;
    while (n < format.length && format[n] == c)
      n++;
    return n - pos;
  }

  int parseQuote(string format, int pos, out string result) {
    int start = pos;
    char quote = format[pos++];
    bool found;
    while (pos < format.length) {
      char c = format[pos++];
      if (c == quote) {
        found = true;
        break;
      }
      else if (c == '\\') { // escaped
        if (pos < format.length)
          result ~= format[pos++];
      }
      else
        result ~= c;
    }
    return pos - start;
  }

  int parseNext(string format, int pos) {
    if (pos >= format.length - 1)
      return -1;
    return cast(int)format[pos + 1];
  }

  void formatDigits(ref string output, int value, int length) {
    if (length > 2)
      length = 2;

    char[16] buffer;
    char* p = buffer.ptr + 16;

    int n = value;
    do {
      *--p = cast(char)(n % 10 + '0');
      n /= 10;
    } while (n != 0 && p > buffer.ptr);

    int c = cast(int)(buffer.ptr + 16 - p);
    while (c < length && p > buffer.ptr) {
      *--p = '0';
      c++;
    }
    output ~= p[0 .. c];
  }

  string formatDayOfWeek(DayOfWeek dayOfWeek, int rpt) {
    if (rpt == 3)
      return dtf.getAbbreviatedDayName(dayOfWeek);
    return dtf.getDayName(dayOfWeek);
  }

  string formatMonth(int month, int rpt) {
    if (rpt == 3)
      return dtf.getAbbreviatedMonthName(month);
    return dtf.getMonthName(month);
  }

  if (format == null)
    format = "G";

  if (format.length == 1)
    format = expandKnownFormat(format, dateTime, dtf);

  auto cal = dtf.calendar;
  string result;
  int index, len;

  while (index < format.length) {
    char c = format[index];
    int next;

    switch (c) {
      case 'd':
        len = parseRepeat(format, index, c);
        if (len <= 2)
          formatDigits(result, dateTime.day, len);
        else
          result ~= formatDayOfWeek(dateTime.dayOfWeek, len);
        break;

      case 'M':
        len = parseRepeat(format, index, c);
        int month = dateTime.month;
        if (len <= 2)
          formatDigits(result, month, len);
        else
          result ~= formatMonth(dateTime.month, len);
        break;

      case 'y':
        len = parseRepeat(format, index, c);
        int year = dateTime.year;
        if (len <= 2)
          formatDigits(result, year % 100, len);
        else
          formatDigits(result, year, len);
        break;

      case 'g':
        len = parseRepeat(format, index, c);
        result ~= dtf.getEraName(cal.getEra(dateTime));
        break;

      case 'h':
        len = parseRepeat(format, index, c);
        int hour = dateTime.hour % 12;
        if (hour == 0)
          hour = 12;
        formatDigits(result, hour, len);
        break;

      case 'H':
        len = parseRepeat(format, index, c);
        formatDigits(result, dateTime.hour, len);
        break;

      case 'm':
        len = parseRepeat(format, index, c);
        formatDigits(result, dateTime.minute, len);
        break;

      case 's':
        len = parseRepeat(format, index, c);
        formatDigits(result, dateTime.second, len);
        break;

      case 'f', 'F':
        const string[] fixedFormats = [
          "0", "00", "000", "0000", "00000", "000000", "0000000"
        ];

        len = parseRepeat(format, index, c);
        if (len <= 7) {
          import std.math;
            
          long frac = dateTime.ticks % TicksPerSecond;
          frac /= cast(long)std.math.pow(cast(real)10, 7 - len);
          result ~= juno.locale.numeric.formatInt(cast(int)frac, fixedFormats[len - 1], Culture.constant);
        }
        else
          throw new FormatException("Input string was invalid.");
        break;

      case 't':
        len = parseRepeat(format, index, c);
        if (len == 1) {
          if (dateTime.hour < 12) {
            if (dtf.amDesignator.length >= 1)
              result ~= dtf.amDesignator[0];
          }
          else if (dtf.pmDesignator.length >= 1)
            result ~= dtf.pmDesignator[0];
        }
        else
          result ~= (dateTime.hour < 12) ? dtf.amDesignator : dtf.pmDesignator;
        break;

      case ':':
        len = 1;
        result ~= dtf.timeSeparator;
        break;

      case '/':
        len = 1;
        result ~= dtf.dateSeparator;
        break;

      case '\'', '\"':
        string quote;
        len = parseQuote(format, index, quote);
        result ~= quote;
        break;

      case '\\':
        next = parseNext(format, index);
        if (next >= 0) {
          result ~= cast(char)next;
          len = 2;
        }
        else
          throw new FormatException("Input string was invalid.");
        break;

      default:
        len = 1;
        result ~= c;
        break;
    }

    index += len;
  }

  return result;
}

struct DateTimeParseResult {
  int year = -1;
  int month = -1;
  int day = -1;
  int hour;
  int minute;
  int second;
  double fraction;
  int timeMark;
  Calendar calendar;
  TimeSpan timeZoneOffset;
  DateTime parsedDate;
}

package DateTime parseDateTime(string s, DateTimeFormat dtf) {
  DateTimeParseResult result;
  if (!tryParseExactMultiple(s, dtf.getAllDateTimePatterns(), dtf, result))
    throw new FormatException("String was not a valid DateTime.");
  return result.parsedDate;
}

package DateTime parseDateTimeExact(string s, string format, DateTimeFormat dtf) {
  DateTimeParseResult result;
  if (!tryParseExact(s, format, dtf, result))
    throw new FormatException("String was not a valid DateTime.");  
  return result.parsedDate;
}

package DateTime parseDateTimeExactMultiple(string s, string[] formats, DateTimeFormat dtf) {
  DateTimeParseResult result;
  if (!tryParseExactMultiple(s, formats, dtf, result))
    throw new FormatException("String was not a valid DateTime.");  
  return result.parsedDate;
}

package bool tryParseDateTime(string s, DateTimeFormat dtf, out DateTime result) {
  result = DateTime.min;
  DateTimeParseResult r;
  if (!tryParseExactMultiple(s, dtf.getAllDateTimePatterns(), dtf, r))
    return false;
  result = r.parsedDate;
  return true;
}

package bool tryParseDateTimeExact(string s, string format, DateTimeFormat dtf, out DateTime result) {
  result = DateTime.min;
  DateTimeParseResult r;
  if (!tryParseExact(s, format, dtf, r))
    return false;
  result = r.parsedDate;
  return true;
}

package bool tryParseDateTimeExactMultiple(string s, string[] formats, DateTimeFormat dtf, out DateTime result) {
  result = DateTime.min;
  DateTimeParseResult r;
  if (!tryParseExactMultiple(s, formats, dtf, r))
    return false;
  result = r.parsedDate;
  return true;
}

private bool tryParseExactMultiple(string s, string[] formats, DateTimeFormat dtf, ref DateTimeParseResult result) {
  foreach (format; formats) {
    if (tryParseExact(s, format, dtf, result))
      return true;
  }
  return false;
}

private bool tryParseExact(string s, string pattern, DateTimeFormat dtf, ref DateTimeParseResult result) {

  bool doParse() {

    int parseDigits(string s, ref int pos, int max) {
      int result = s[pos++] - '0';
      while (max > 1 && pos < s.length && s[pos] >= '0' && s[pos] <= '9') {
        result = result * 10 + s[pos++] - '0';
        --max;
      }
      return result;
    }

    bool parseOne(string s, ref int pos, string value) {
      if (s[pos .. pos + value.length] != value)
        return false;
      pos += value.length;
      return true;
    }

    int parseMultiple(string s, ref int pos, string[] values ...) {
      int result = -1, max;
      foreach (i, value; values) {
        if (value.length == 0 || s.length - pos < value.length)
          continue;

        if (s[pos .. pos + value.length] == value) {
          if (result == 0 || value.length > max) {
            result = i + 1;
            max = value.length;
          }
        }
      }
      pos += max;
      return result;
    }

    TimeSpan parseTimeZoneOffset(string s, ref int pos) {
      bool sign;
      if (pos < s.length) {
        if (s[pos] == '-') {
          sign = true;
          pos++;
        }
        else if (s[pos] == '+')
          pos++;
      }
      int hour = parseDigits(s, pos, 2);
      int minute;
      if (pos < s.length) {
        if (s[pos] == ':')
          pos++;
        minute = parseDigits(s, pos, 2);
      }
      TimeSpan result = TimeSpan(hour, minute, 0);
      if (sign)
        result = -result;
      return result;
    }

    result.calendar = dtf.calendar;
    result.year = result.month = result.day = -1;
    result.hour = result.minute = result.second = 0;
    result.fraction = 0.0;

    int pos, i, count;
    char c;

    while (pos < pattern.length && i < s.length) {
      c = pattern[pos++];

      if (c == ' ') {
        i++;
        while (i < s.length && s[i] == ' ')
          i++;
        if (i >= s.length)
          break;
        continue;
      }

      count = 1;

      switch (c) {
        case 'd', 'm', 'M', 'y', 'h', 'H', 's', 't', 'f', 'F', 'z':
          while (pos < pattern.length && pattern[pos] == c) {
            pos++;
            count++;
          }
          break;
        case ':':
          if (!parseOne(s, i, ":"))
            return false;
          continue;
        case '/':
          if (!parseOne(s, i, "/"))
            return false;
          continue;
        case '\\':
          if (pos < pattern.length) {
            c = pattern[pos++];
            if (s[i++] != c)
              return false;
          }
          else
            return false;
          continue;
        case '\'':
          while (pos < pattern.length) {
            c = pattern[pos++];
            if (c == '\'')
              break;
            if (s[i++] != c)
              return false;
          }
          continue;
        default:
          if (s[i++] != c)
            return false;
          continue;
      }

      switch (c) {
        case 'd':
          if (count == 1 || count == 2)
            result.day = parseDigits(s, i, 2);
          else if (count == 3)
            result.day = parseMultiple(s, i, dtf.abbreviatedDayNames);
          else
            result.day = parseMultiple(s, i, dtf.dayNames);
          if (result.day == -1)
            return false;
          break;
        case 'M':
          if (count == 1 || count == 2)
            result.month = parseDigits(s, i, 2);
          else if (count == 3)
            result.month = parseMultiple(s, i, dtf.abbreviatedMonthNames);
          else
            result.month = parseMultiple(s, i, dtf.monthNames);
          if (result.month == -1)
            return false;
          break;
        case 'y':
          if (count == 1 || count == 2)
            result.year = parseDigits(s, i, 2);
          else
            result.year = parseDigits(s, i, 4);
          if (result.year == -1)
            return false;
          break;
        case 'h', 'H':
          result.hour = parseDigits(s, i, 2);
          break;
        case 'm':
          result.minute = parseDigits(s, i, 2);
          break;
        case 's':
          result.second = parseDigits(s, i, 2);
          break;
        case 't':
          if (count == 1)
            result.timeMark = parseMultiple(s, i, [ dtf.amDesignator[0] ], [ dtf.pmDesignator[0] ]);
          else
            result.timeMark = parseMultiple(s, i, dtf.amDesignator, dtf.pmDesignator);
          break;
        case 'f', 'F':
          parseDigits(s, i, 7);
          break;
        case 'z':
          result.timeZoneOffset = parseTimeZoneOffset(s, i);
          break;
        default:
      }
    }

    if (pos < pattern.length || i < s.length)
      return false;

    if (result.timeMark == 1) { // am
      if (result.hour == 12)
        result.hour = 0;
    }
    else if (result.timeMark == 2) { // pm
      if (result.hour < 12)
        result.hour += 12;
    }

    if (result.year == -1 || result.month == -1 || result.day == -1) {
      DateTime now = DateTime.now;
      if (result.month == -1 && result.day == -1) {
        if (result.year == -1) {
          result.year = now.year;
          result.month = now.month;
          result.day = now.day;
        }
        else
          result.month = result.day = 1;
      }
      else {
        if (result.year == -1)
          result.year = now.year;
        if (result.month == -1)
          result.month = 1;
        if (result.day == -1)
          result.day = 1;
      }
    }
    return true;
  }

  if (doParse()) {
    result.parsedDate = DateTime(result.year, result.month, result.day, result.hour, result.minute, result.second);
    return true;
  }
  return false;
}
