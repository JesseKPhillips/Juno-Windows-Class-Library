/**
 * Copyright: (c) 2008 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.locale.format;

private import juno.base.core,
  juno.base.native,
  juno.locale.constants;

private import juno.locale.core : 
  IFormatProvider, Culture, getLocaleInfo, getLocaleInfoI, getCalendarInfo;

private import juno.locale.time : 
  Calendar, GregorianCalendar, DateTime;

private import std.c.string;
private import std.algorithm;
private import std.range;
private import std.utf : toUTF8;
private import std.c.wcharh;

debug private import std.stdio;

class NumberFormat : IFormatProvider {

  private static NumberFormat current_;
  private static NumberFormat constant_;

  package bool isReadOnly_;

  private int[] numberGroupSizes_;
  private int[] currencyGroupSizes_;
  private string positiveSign_;
  private string negativeSign_;
  private string numberDecimalSeparator_;
  private string currencyDecimalSeparator_;
  private string numberGroupSeparator_;
  private string currencyGroupSeparator_;
  private string currencySymbol_;
  private string nanSymbol_;
  private string positiveInfinitySymbol_;
  private string negativeInfinitySymbol_;
  private int numberDecimalDigits_;
  private int currencyDecimalDigits_;
  private int currencyPositivePattern_;
  private int numberNegativePattern_;
  private int currencyNegativePattern_;

  this() {
    this(LOCALE_INVARIANT);
  }

  Object getFormat(TypeInfo formatType) {
    if (formatType == typeid(NumberFormat))
      return this;
    return null;
  }

  static NumberFormat get(IFormatProvider provider) {
    if (auto culture = cast(Culture)provider) {
      if (!culture.isInherited_) {
        if (auto value = culture.numberFormat_)
          return value;
        return culture.numberFormat;
      }
    }

    if (auto value = cast(NumberFormat)provider)
      return value;

    if (provider !is null) {
      if (auto value = cast(NumberFormat)provider.getFormat(typeid(NumberFormat)))
        return value;
    }

    return current;
  }

  static NumberFormat constant() {
    if (constant_ is null) {
      constant_ = new NumberFormat;
      constant_.isReadOnly_ = true;
    }
    return constant_;
  }

  static NumberFormat current() {
    Culture culture = Culture.current;
    if (!culture.isInherited_) {
      if (auto result = culture.numberFormat_)
        return result;
    }
    return cast(NumberFormat)culture.getFormat(typeid(NumberFormat));
  }

  void numberGroupSizes(int[] value) {
    checkReadOnly();
    numberGroupSizes_ = value;
  }

  int[] numberGroupSizes() {
    return numberGroupSizes_;
  }

  void currencyGroupSizes(int[] value) {
    checkReadOnly();
    currencyGroupSizes_ = value;
  }

  int[] currencyGroupSizes() {
    return currencyGroupSizes_;
  }

  void positiveSign(string value) {
    checkReadOnly();
    positiveSign_ = value;
  }

  string positiveSign() {
    return positiveSign_;
  }

  void negativeSign(string value) {
    checkReadOnly();
    negativeSign_ = value;
  }

  string negativeSign() {
    return negativeSign_;
  }

  void numberDecimalSeparator(string value) {
    checkReadOnly();
    numberDecimalSeparator_ = value;
  }

  string numberDecimalSeparator() {
    return numberDecimalSeparator_;
  }

  void currencyDecimalSeparator(string value) {
    checkReadOnly();
    currencyDecimalSeparator_ = value;
  }

  string currencyDecimalSeparator() {
    return currencyDecimalSeparator_;
  }

  void numberGroupSeparator(string value) {
    checkReadOnly();
    numberGroupSeparator_ = value;
  }

  string numberGroupSeparator() {
    return numberGroupSeparator_;
  }

  void currencyGroupSeparator(string value) {
    checkReadOnly();
    currencyGroupSeparator_ = value;
  }

  string currencyGroupSeparator() {
    return currencyGroupSeparator_;
  }

  void currencySymbol(string value) {
    checkReadOnly();
    currencySymbol_ = value;
  }

  string currencySymbol() {
    return currencySymbol_;
  }

  void nanSymbol(string value) {
    checkReadOnly();
    nanSymbol_ = value;
  }

  string nanSymbol() {
    return nanSymbol_;
  }

  void positiveInfinitySymbol(string value) {
    checkReadOnly();
    positiveInfinitySymbol_ = value;
  }

  string positiveInfinitySymbol() {
    return positiveInfinitySymbol_;
  }

  void negativeInfinitySymbol(string value) {
    checkReadOnly();
    negativeInfinitySymbol_ = value;
  }

  string negativeInfinitySymbol() {
    return negativeInfinitySymbol_;
  }

  void numberDecimalDigits(int value) {
    checkReadOnly();
    numberDecimalDigits_ = value;
  }

  int numberDecimalDigits() {
    return numberDecimalDigits_;
  }

  void currencyDecimalDigits(int value) {
    checkReadOnly();
    currencyDecimalDigits_ = value;
  }

  int currencyDecimalDigits() {
    return currencyDecimalDigits_;
  }

  void currencyPositivePattern(int value) {
    checkReadOnly();
    currencyPositivePattern_ = value;
  }

  int currencyPositivePattern() {
    return currencyPositivePattern_;
  }

  void currencyNegativePattern(int value) {
    checkReadOnly();
    currencyNegativePattern_ = value;
  }

  int currencyNegativePattern() {
    return currencyNegativePattern_;
  }

  void numberNegativePattern(int value) {
    checkReadOnly();
    numberNegativePattern_ = value;
  }

  int numberNegativePattern() {
    return numberNegativePattern_;
  }

  package this(uint culture) {

    int[] convertGroupString(string s) {
      // eg 3;2;0
      if (s.length == 0 || s[0] == '0')
        return [ 3 ];
      int[] group;
      if (s[$ - 1] == '0')
        group = new int[s.length / 2];
      else {
        group = new int[(s.length / 2) + 2];
        group[$ - 1] = 0;
      }
      int n;
      for (int i = 0; i < s.length && i < group.length; i++) {
        if (s[n] < '1' || s[n] > '9')
          return [ 3 ];
        group[i] = s[n] - '0';
        // skip ';'
        n += 2;
      }
      return group;
    }

    numberGroupSizes_ = [ 3 ];
    currencyGroupSizes_ = [ 3 ];
    positiveSign_ = "+";
    negativeSign_ = "-";
    numberDecimalSeparator_ = ".";
    currencyDecimalSeparator_ = ".";
    numberGroupSeparator_ = ",";
    currencyGroupSeparator_ = ",";
    currencySymbol_ = "\u00a4";
    nanSymbol_ = "NaN";
    positiveInfinitySymbol_ = "Infinity";
    negativeInfinitySymbol_ = "-Infinity";
    numberDecimalDigits_ = 2;
    currencyDecimalDigits_ = 2;
    numberNegativePattern_ = 1;

    if (culture != LOCALE_INVARIANT) {
      numberGroupSizes_ = convertGroupString(getLocaleInfo(culture, LOCALE_SGROUPING));
      currencyGroupSizes_ = convertGroupString(getLocaleInfo(culture, LOCALE_SMONGROUPING));
      negativeSign_ = getLocaleInfo(culture, LOCALE_SNEGATIVESIGN);
      numberDecimalSeparator_ = getLocaleInfo(culture, LOCALE_SDECIMAL);
      currencyDecimalSeparator_ = getLocaleInfo(culture, LOCALE_SMONDECIMALSEP);
      numberGroupSeparator_ = getLocaleInfo(culture, LOCALE_STHOUSAND);
      currencyGroupSeparator_ = getLocaleInfo(culture, LOCALE_SMONTHOUSANDSEP);
      currencySymbol_ = getLocaleInfo(culture, LOCALE_SCURRENCY);
      nanSymbol_ = getLocaleInfo(culture, LOCALE_SNAN);
      positiveInfinitySymbol_ = getLocaleInfo(culture, LOCALE_SPOSINFINITY);
      negativeInfinitySymbol_ = getLocaleInfo(culture, LOCALE_SNEGINFINITY);
      numberDecimalDigits_ = getLocaleInfoI(culture, LOCALE_IDIGITS);
      currencyDecimalDigits_ = getLocaleInfoI(culture, LOCALE_ICURRDIGITS);
      currencyPositivePattern_ = getLocaleInfoI(culture, LOCALE_ICURRENCY);
      currencyNegativePattern_ = getLocaleInfoI(culture, LOCALE_INEGCURR);
      numberNegativePattern_ = getLocaleInfoI(culture, LOCALE_INEGNUMBER);

      if (positiveSign_ == null)
        positiveSign_ = "+";

      // The following will be null on XP and earlier.
      if (nanSymbol_ == null)
        nanSymbol_ = "NaN";
      if (positiveInfinitySymbol_ == null)
        positiveInfinitySymbol_ = "Infinity";
      if (negativeInfinitySymbol_ == null)
        negativeInfinitySymbol_ = "-Infinity";
    }
  }

  private void checkReadOnly() {
    if (isReadOnly_)
      throw new InvalidOperationException("The instance is read-only.");
  }

}

package const char[] allStandardFormats = [ 'd', 'D', 'f', 'F', 'g', 'G', 'r', 'R', 's', 't', 'T', 'u', 'U', 'y', 'Y' ];

class DateTimeFormat : IFormatProvider {

  private static const string RFC1123_PATTERN = "ddd, dd MMM yyyy HH':'mm':'ss 'GMT'";
  private static const string SORTABLE_DATETIME_PATTERN = "yyyy'-'MM'-'dd'T'HH':'mm':'ss";
  private static const string UNIVERSAL_SORTABLE_DATETIME_PATTERN = "yyyy'-'MM'-'dd HH':'mm':'ss'Z'";

  private static DateTimeFormat current_;
  private static DateTimeFormat constant_;

  private uint cultureId_;
  private Calendar calendar_;
  private bool isDefaultCalendar_;
  private int[] optionalCalendars_;
  private string amDesignator_;
  private string pmDesignator_;
  private string dateSeparator_;
  private string timeSeparator_;
  private int firstDayOfWeek_ = -1;
  private string[] dayNames_;
  private string[] abbrevDayNames_;
  private string[] monthNames_;
  private string[] abbrevMonthNames_;
  private string shortDatePattern_;
  private string longDatePattern_;
  private string shortTimePattern_;
  private string longTimePattern_;
  private string yearMonthPattern_;
  private string fullDateTimePattern_;
  private string[] allShortDatePatterns_;
  private string[] allShortTimePatterns_;
  private string[] allLongDatePatterns_;
  private string[] allLongTimePatterns_;
  private string[] allYearMonthPatterns_;
  private string generalShortTimePattern_;
  private string generalLongTimePattern_;

  package bool isReadOnly_;

  this() {
    cultureId_ = LOCALE_INVARIANT;
    isDefaultCalendar_ = true;
    calendar_ = GregorianCalendar.defaultInstance;

    initializeProperties();
  }

  Object getFormat(TypeInfo formatType) {
    if (formatType == typeid(DateTimeFormat))
      return this;
    return null;
  }

  static DateTimeFormat get(IFormatProvider provider) {
    if (auto culture = cast(Culture)provider) {
      return culture.dateTimeFormat;
    }

    if (auto value = cast(DateTimeFormat)provider)
      return value;

    if (provider !is null) {
      if (auto value = cast(DateTimeFormat)provider.getFormat(typeid(DateTimeFormat)))
        return value;
    }

    return current;
  }

  final string getAbbreviatedDayName(DayOfWeek dayOfWeek) {
    return getAbbreviatedDayNames()[dayOfWeek];
  }

  final string getDayName(DayOfWeek dayOfWeek) {
    return getDayNames()[dayOfWeek];
  }

  final string getMonthName(int month) {
    return getMonthNames()[month - 1];
  }

  final string getAbbreviatedMonthName(int month) {
    return getAbbreviatedMonthNames()[month - 1];
  }

  final string[] getAllDateTimePatterns() {
    string[] ret;
    foreach (format; allStandardFormats)
      ret ~= getAllDateTimePatterns(format);
    return ret;
  }

  final string[] getAllDateTimePatterns(char format) {

    string[] combinePatterns(string[] patterns1, string[] patterns2) {
      string[] result = new string[patterns1.length * patterns2.length];
      for (int i = 0; i < patterns1.length; i++) {
        for (int j = 0; j < patterns2.length; j++)
          result[i * patterns2.length + j] = patterns1[i] ~ " " ~ patterns2[j];
      }
      return result;
    }

    string[] ret;

    switch (format) {
      case 'd':
        ret ~= allShortDatePatterns;
        break;
      case 'D':
        ret ~= allLongDatePatterns;
        break;
      case 'f':
        ret ~= combinePatterns(allLongDatePatterns, allShortTimePatterns);
        break;
      case 'F':
        ret ~= combinePatterns(allLongDatePatterns, allLongTimePatterns);
        break;
      case 'g':
        ret ~= combinePatterns(allShortDatePatterns, allShortTimePatterns);
        break;
      case 'G':
        ret ~= combinePatterns(allShortDatePatterns, allLongTimePatterns);
        break;
      case 'r', 'R':
        ret ~= RFC1123_PATTERN;
        break;
      case 's':
        ret ~= SORTABLE_DATETIME_PATTERN;
        break;
      case 't':
        ret ~= allShortTimePatterns;
        break;
      case 'T':
        ret ~= allLongTimePatterns;
        break;
      case 'u':
        ret ~= UNIVERSAL_SORTABLE_DATETIME_PATTERN;
        break;
      case 'U':
        ret ~= combinePatterns(allLongDatePatterns, allLongTimePatterns);
        break;
      case 'y', 'Y':
        ret ~= allYearMonthPatterns;
        break;
      default:
        throw new ArgumentException("The specified format was not valid.", "format");
    }

    return ret;
  }

  static DateTimeFormat constant() {
    if (constant_ is null) {
      constant_ = new DateTimeFormat;
      constant_.calendar.isReadOnly_ = true;
      constant_.isReadOnly_ = true;
    }
    return constant_;
  }

  static DateTimeFormat current() {
    Culture culture = Culture.current;
    if (auto value = culture.dateTimeFormat_)
      return value;
    return cast(DateTimeFormat)culture.getFormat(typeid(DateTimeFormat));
  }

  final void calendar(Calendar value) {
    if (value !is calendar_) {
      for (int i = 0; i < optionalCalendars.length; i++) {
        if (optionalCalendars[i] == value.internalId) {
          isDefaultCalendar_ = (value.internalId == CAL_GREGORIAN);

          if (calendar_ !is null) {
            // Clear current values.
            abbrevDayNames_ = null;
            dayNames_ = null;
            abbrevMonthNames_ = null;
            monthNames_ = null;
            shortDatePattern_ = null;
            longDatePattern_ = null;
            yearMonthPattern_ = null;
            fullDateTimePattern_ = null;
            allShortDatePatterns_ = null;
            allLongDatePatterns_ = null;
            allYearMonthPatterns_ = null;
            generalShortTimePattern_ = null;
            generalLongTimePattern_ = null;
          }

          calendar_ = value;
          initializeProperties();

          return;
        }
      }
      throw new ArgumentException("Not a valid calendar for the given culture.", "value");
    }
  }

  final Calendar calendar() {
    return calendar_;
  }

  final string calendarName() {
    return getCalendarInfo(cultureId_, calendar.internalId, CAL_SCALNAME);
  }

  /++string currentEraName() {
    return getCalendarInfo(cultureId_, calendar.internalId, CAL_SERASTRING);
    /*wchar[64] buffer;
    int cch = GetDateFormat(cultureId_, DATE_USE_ALT_CALENDAR, null, "gg", buffer.ptr, buffer.length);
    if (cch == 0)
      return null;

    return toUTF8(buffer[0 .. cch - 1]);*/
  }++/

  final void amDesignator(string value) {
    checkReadOnly();
    amDesignator_ = value;
  }

  final string amDesignator() {
    return amDesignator_;
  }

  final void pmDesignator(string value) {
    checkReadOnly();
    pmDesignator_ = value;
  }

  final string pmDesignator() {
    return pmDesignator_;
  }

  final void dateSeparator(string value) {
    checkReadOnly();
    dateSeparator_ = value;
  }

  final string dateSeparator() {
    if (dateSeparator_ == null)
      dateSeparator_ = getLocaleInfo(cultureId_, LOCALE_SDATE);
    return dateSeparator_;
  }

  final void timeSeparator(string value) {
    checkReadOnly();
    timeSeparator_ = value;
  }

  final string timeSeparator() {
    if (timeSeparator_ == null)
      timeSeparator_ = getLocaleInfo(cultureId_, LOCALE_STIME);
    return timeSeparator_;
  }

  final void firstDayOfWeek(DayOfWeek value) {
    checkReadOnly();
    firstDayOfWeek_ = cast(int)value;
  }

  final DayOfWeek firstDayOfWeek() {
    return cast(DayOfWeek)firstDayOfWeek_;
  }

  final string rfc1123Pattern() {
    return RFC1123_PATTERN;
  }

  final string sortableDateTimePattern() {
    return SORTABLE_DATETIME_PATTERN;
  }

  final string universalSortableDateTimePattern() {
    return UNIVERSAL_SORTABLE_DATETIME_PATTERN;
  }

  final void shortDatePattern(string value) {
    checkReadOnly();
    shortDatePattern_ = value;
    generalShortTimePattern_ = null;
    generalLongTimePattern_ = null;
  }

  final string shortDatePattern() {
    return shortDatePattern_;
  }

  final void longDatePattern(string value) {
    checkReadOnly();
    longDatePattern_ = value;
    fullDateTimePattern_ = null;
  }

  final string longDatePattern() {
    return longDatePattern_;
  }

  final void shortTimePattern(string value) {
    checkReadOnly();
    shortTimePattern_ = value;
    generalShortTimePattern_ = null;
  }

  final string shortTimePattern() {
    if (shortTimePattern_ == null)
      shortTimePattern_ = getShortTime(cultureId_);
    return shortTimePattern_;
  }

  final void longTimePattern(string value) {
    checkReadOnly();
    longTimePattern_ = value;
    fullDateTimePattern_ = null;
    generalLongTimePattern_ = null;
  }

  final string longTimePattern() {
    return longTimePattern_;
  }

  final void yearMonthPattern(string value) {
    checkReadOnly();
    yearMonthPattern_ = value;
  }

  final string yearMonthPattern() {
    return yearMonthPattern_;
  }

  final string fullDateTimePattern() {
    if (fullDateTimePattern_ == null)
      fullDateTimePattern_ = longDatePattern ~ " " ~ longTimePattern;
    return fullDateTimePattern_;
  }

  package string generalShortTimePattern() {
    if (generalShortTimePattern_ == null)
      generalShortTimePattern_ = shortDatePattern ~ " " ~ shortTimePattern;
    return generalShortTimePattern_;
  }

  package string generalLongTimePattern() {
    if (generalLongTimePattern_ == null)
      generalLongTimePattern_ = shortDatePattern ~ " " ~ longTimePattern;
    return generalLongTimePattern_;
  }

  final void dayNames(string[] value) {
    checkReadOnly();
    dayNames_ = value;
  }

  final string[] dayNames() {
    return getDayNames().dup;
  }

  final void abbreviatedDayNames(string[] value) {
    checkReadOnly();
    abbrevDayNames_ = value;
  }

  final string[] abbreviatedDayNames() {
    return getAbbreviatedDayNames().dup;
  }

  final void monthNames(string[] value) {
    checkReadOnly();
    monthNames_ = value;
  }

  final string[] monthNames() {
    return getMonthNames().dup;
  }

  final void abbreviatedMonthNames(string[] value) {
    checkReadOnly();
    abbrevMonthNames_ = value;
  }

  final string[] abbreviatedMonthNames() {
    return getAbbreviatedMonthNames().dup;
  }

  package this(uint culture, Calendar cal) {
    cultureId_ = culture;
    calendar = cal;
  }

  private void checkReadOnly() {
    if (isReadOnly_)
      throw new InvalidOperationException("The instance is read-only.");
  }

  private void initializeProperties() {
    amDesignator_ = getLocaleInfo(cultureId_, LOCALE_S1159);
    pmDesignator_ = getLocaleInfo(cultureId_, LOCALE_S2359);

    firstDayOfWeek_ = getLocaleInfoI(cultureId_, LOCALE_IFIRSTDAYOFWEEK);
    // 0 = Monday, 1 = Tuesday ... 6 = Sunday
    if (firstDayOfWeek_ < 6)
      firstDayOfWeek_++;
    else
      firstDayOfWeek_ = 0;

    shortDatePattern_ = getShortDatePattern(calendar_.internalId);
    longDatePattern_ = getLongDatePattern(calendar_.internalId);
    longTimePattern_ = getLocaleInfo(cultureId_, LOCALE_STIMEFORMAT);
    yearMonthPattern_ = getLocaleInfo(cultureId_, LOCALE_SYEARMONTH);
  }

  private string[] allShortDatePatterns() {
    if (allShortDatePatterns_ == null) {
      if (!isDefaultCalendar_)
        allShortDatePatterns_ = [ getShortDatePattern(calendar_.internalId) ];
      if (allShortDatePatterns_ == null)
        allShortDatePatterns_ = getShortDates(cultureId_, calendar_.internalId);
    }
    return allShortDatePatterns_.dup;
  }

  private string[] allLongDatePatterns() {
    if (allLongDatePatterns_ == null) {
      if (!isDefaultCalendar_)
        allLongDatePatterns_ = [ getLongDatePattern(calendar_.internalId) ];
      if (allLongDatePatterns_ == null)
        allLongDatePatterns_ = getLongDates(cultureId_, calendar_.internalId);
    }
    return allLongDatePatterns_.dup;
  }

  private string[] allShortTimePatterns() {
    if (allShortTimePatterns_ == null)
      allShortTimePatterns_ = getShortTimes(cultureId_);
    return allShortTimePatterns_.dup;
  }

  private string[] allLongTimePatterns() {
    if (allLongTimePatterns_ == null)
      allLongTimePatterns_ = getLongTimes(cultureId_);
    return allLongTimePatterns_.dup;
  }

  private string[] allYearMonthPatterns() {
    if (allYearMonthPatterns_ == null) {
      if (!isDefaultCalendar_)
        allYearMonthPatterns_ = [ getCalendarInfo(cultureId_, calendar_.internalId, CAL_SYEARMONTH) ];
      if (allYearMonthPatterns_ == null)
        allYearMonthPatterns_ = [ getLocaleInfo(cultureId_, LOCALE_SYEARMONTH) ];
    }
    return allYearMonthPatterns_.dup;
  }

  private static bool enumDateFormats(uint culture, uint calendar, uint flags, out string[] formats) {
    static string[] temp;
    static uint cal;

    extern(Windows)
    static int enumDateFormatsProc(wchar* lpDateFormatString, uint CalendarID) {
      if (cal == CalendarID)
        temp ~= toUTF8(lpDateFormatString[0 .. wcslen(lpDateFormatString)]);
      return true;
    }

    temp = null;
    cal = calendar;
    if (!EnumDateFormatsEx(&enumDateFormatsProc, culture, flags))
      return false;

    formats = temp.dup;
    return true;
  }

  private static string[] getShortDates(uint culture, uint calendar) {
    string[] formats;
    synchronized {
      if (!enumDateFormats(culture, calendar, DATE_SHORTDATE, formats))
        return null;
    }
    if (formats == null)
      formats = [ getCalendarInfo(culture, calendar, CAL_SSHORTDATE) ];
    return formats;
  }

  private string getShortDatePattern(uint cal) {
    if (!isDefaultCalendar_)
      return getShortDates(cultureId_, cal)[0];
    return getLocaleInfo(cultureId_, LOCALE_SSHORTDATE);
  }

  private static string getShortTime(uint culture) {
    // There is no LOCALE_SSHORTTIME, so we simulate one based on the long time pattern.
    string s = getLocaleInfo(culture, LOCALE_STIMEFORMAT);
    int i = s.rfind(getLocaleInfo(culture, LOCALE_STIME));
    if (i != -1)
      s.length = i;
    return s;
  }

  private static string[] getLongDates(uint culture, uint calendar) {
    string[] formats;
    synchronized {
      if (!enumDateFormats(culture, calendar, DATE_LONGDATE, formats))
        return null;
    }
    if (formats == null)
      formats = [ getCalendarInfo(culture, calendar, CAL_SLONGDATE) ];
    return formats;
  }

  private string getLongDatePattern(uint cal) {
    if (!isDefaultCalendar_)
      return getLongDates(cultureId_, cal)[0];
    return getLocaleInfo(cultureId_, LOCALE_SLONGDATE);
  }

  private static bool enumTimeFormats(uint culture, uint flags, out string[] formats) {
    static string[] temp;

    extern(Windows)
    static int enumTimeFormatsProc(wchar* lpTimeFormatString) {
      temp ~= toUTF8(lpTimeFormatString[0 .. wcslen(lpTimeFormatString)]);
      return true;
    }

    temp = null;
    if (!EnumTimeFormats(&enumTimeFormatsProc, culture, flags))
      return false;

    formats = temp.dup;
    return true;
  }

  private static string[] getShortTimes(uint culture) {
    string[] formats;

    synchronized {
      if (!enumTimeFormats(culture, 0, formats))
        return null;
    }

    foreach (ref s; formats) {
      int i = s.rfind(getLocaleInfo(culture, LOCALE_STIME));
      int j = -1;
      if (i != -1)
        j = s.rfind(' ');
      if (i != -1 && j != -1) {
        string temp = s[0 .. j];
        temp ~= s[j .. $];
        s = temp;
      }
      else if (i != -1)
        s.length = i;
    }

    return formats;
  }

  private static string[] getLongTimes(uint culture) {
    string[] formats;
    synchronized {
      if (!enumTimeFormats(culture, 0, formats))
        return null;
    }
    return formats;
  }

  private string[] getDayNames() {
    if (dayNames_ == null) {
      dayNames_.length = 7;
      for (uint i = LOCALE_SDAYNAME1; i <= LOCALE_SDAYNAME7; i++) {
        uint j = (i != LOCALE_SDAYNAME7) ? i - LOCALE_SDAYNAME1 + 1 : 0;
        dayNames_[j] = getLocaleInfo(cultureId_, i);
      }
    }
    return dayNames_;
  }

  private string[] getAbbreviatedDayNames() {
    if (abbrevDayNames_ == null) {
      abbrevDayNames_.length = 7;
      for (uint i = LOCALE_SABBREVDAYNAME1; i <= LOCALE_SABBREVDAYNAME7; i++) {
        uint j = (i != LOCALE_SABBREVDAYNAME7) ? i - LOCALE_SABBREVDAYNAME1 + 1 : 0;
        abbrevDayNames_[j] = getLocaleInfo(cultureId_, i);
      }
    }
    return abbrevDayNames_;
  }

  private string[] getMonthNames() {
    if (monthNames_ == null) {
      monthNames_.length = 13;
      for (uint i = LOCALE_SMONTHNAME1; i <= LOCALE_SMONTHNAME12; i++) {
        monthNames_[i - LOCALE_SMONTHNAME1] = getLocaleInfo(cultureId_, i);
      }
    }
    return monthNames_;
  }

  private string[] getAbbreviatedMonthNames() {
    if (abbrevMonthNames_ == null) {
      abbrevMonthNames_.length = 13;
      for (uint i = LOCALE_SABBREVMONTHNAME1; i <= LOCALE_SABBREVMONTHNAME12; i++) {
        abbrevMonthNames_[i - LOCALE_SABBREVMONTHNAME1] = getLocaleInfo(cultureId_, i);
      }
    }
    return abbrevMonthNames_;
  }

  private int[] optionalCalendars() {
    if (optionalCalendars_ == null)
      optionalCalendars_ = getOptionalCalendars(cultureId_);
    return optionalCalendars_;
  }

  private static bool enumCalendarInfo(uint culture, uint calendar, uint calType, out int[] result) {
    static int[] temp;

    extern(Windows)
    static int enumCalendarsProc(wchar* lpCalendarInfoString, uint Calendar) {
      temp ~= Calendar;
      return true;
    }

    temp = null;
    if (!EnumCalendarInfoEx(&enumCalendarsProc, culture, calendar, calType))
      return false;
    result = temp.dup;
    return true;
  }

  private static int[] getOptionalCalendars(uint culture) {
    int[] cals;
    synchronized {
      if (!enumCalendarInfo(culture, ENUM_ALL_CALENDARS, CAL_ICALINTVALUE, cals))
        return null;
    }
    return cals;
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
        return dtf.sortableDateTimePattern;
      case 't':
        return dtf.shortTimePattern;
      case 'T':
        return dtf.longTimePattern;
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

      /*case 'z':
        len = parseRepeat(format, index, c);
        TimeSpan offset = TimeZone.local.getUtcOffset(dateTime);
        if (offset >= TimeSpan.zero)
          result ~= "+";
        else {
          result ~= "-";
          offset = -offset;
        }
        if (len <= 1)
          result ~= .format("{0:0}", offset.hours);
        else {
          result ~= .format("{0:00}", offset.hours);
          if (len >= 3)
            result ~= .format(":{0:00}", offset.minutes);
        }
        break;*/

      case ':':
        len = 1;
        result ~= dtf.timeSeparator;
        break;

      case '/':
        len = 1;
        result ~= dtf.dateSeparator;
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

private struct DateTimeParseResult {
  int year = -1;
  int month = -1;
  int day = -1;
  int hour;
  int minute;
  int second;
  double fraction;
  int timeMark;
  Calendar calendar;
  //TimeSpan timeZoneOffset;
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

    /*TimeSpan parseTimeZoneOffset(string s, ref int pos) {
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
      if (pos < s.length && s[pos] == ':') {
        pos++;
        minute = parseDigits(s, pos, 2);
      }
      TimeSpan result = TimeSpan(hour, minute, 0);
      if (sign)
        result = -result;
      return result;
    }*/

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
        case 'd', 'm', 'M', 'y', 'h', 'H', 's', 't', 'z':
          while (pos < pattern.length && pattern[pos] == c) {
            pos++;
            count++;
          }
          break;
        case ':':
          if (!parseOne(s, i, dtf.timeSeparator))
            return false;
          continue;
        case '/':
          if (!parseOne(s, i, dtf.dateSeparator))
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
        /*case 'z':
          result.timeZoneOffset = parseTimeZoneOffset(s, i);
          break;*/
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
      DateTime now = DateTime.localNow;
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

package struct Number {

  int precision;
  int scale;
  int sign;
  char[long.sizeof * 8] digits = void;

  static Number opCall(long value, int precision) {
    Number n;
    n.precision = precision;
    if (value < 0) {
      n.sign = 1;
      value = -value;
    }

    char[20] buffer;
    int i = buffer.length;
    while (value != 0) {
      buffer[--i] = value % 10 + '0';
      value /= 10;
    }

    int end = n.scale = -(i - buffer.length);
    n.digits[0 .. end] = buffer[i .. i + end];
    n.digits[end] = '\0';

    return n;
  }

  void round(int pos) {
    int index;
    while (index < pos && digits[index] != '\0') index++;

    if (index == pos && digits[index] >= '5') {
      while (index > 0 && digits[index - 1] == '9') index--;

      if (index > 0)
        digits[index - 1]++;
      else {
        scale++;
        digits[0] = '1';
        index = 1;
      }
    }
    else
      while (index > 0 && digits[index - 1] == '0') index--;

    if (index == 0) {
      scale = 0;
      sign = 0;
    }

    digits[index] = '\0';
  }

  bool toLong(out long value) {
    int i = scale;
    if (i > 20 || i < precision)
      return false;

    long v = 0;
    char* p = digits.ptr;
    while (--i >= 0) {
      if (cast(ulong)v > (ulong.max / 10))
        return false;
      v *= 10;
      if (*p != '\0')
        v += *p++ - '0';
    }

    if (sign)
      v = -v;
    else if (v < 0)
      return false;

    value = v;
    return true;
  }

  static bool tryParse(string s, NumberStyles styles, NumberFormat nf, out Number result) {

    enum ParseState {
      None = 0x0,
      Sign = 0x1,
      Parens = 0x2,
      Digits = 0x4,
      NonZero = 0x8,
      Decimal = 0x10,
      Currency = 0x20
    }

    int eat(string what, string within, int at) {
      if (at >= within.length)
        return -1;
      int i;
      while (at < within.length && i < what.length) {
        if (within[at] != what[i])
          return -1;
        i++;
        at++;
      }
      return i;
    }

    bool isWhitespace(char c) {
      return c == 0x20 || (c >= '\t' && c <= '\r');
    }

    string currencySymbol = ((styles & NumberStyles.CurrencySymbol) != 0) ? nf.currencySymbol : null;
    string decimalSeparator = ((styles & NumberStyles.CurrencySymbol) != 0) ? nf.currencyDecimalSeparator : nf.numberDecimalSeparator;
    string groupSeparator = ((styles & NumberStyles.CurrencySymbol) != 0) ? nf.currencyGroupSeparator : nf.numberGroupSeparator;
    string altDecimalSeparator = ((styles & NumberStyles.CurrencySymbol) != 0) ? nf.numberDecimalSeparator : null;
    string altGroupSeparator = ((styles & NumberStyles.CurrencySymbol) != 0) ? nf.numberGroupSeparator : null;

    result.scale = 0;
    result.sign = 0;

    ParseState state;
    int count, end, pos, eaten;
    bool isSigned;

    while (true) {
      if (pos == s.length) break;
      char c = s[pos];
      if ((isSigned = (((styles & NumberStyles.LeadingSign) != 0) && ((state & ParseState.Sign) == 0))) != 0 
        && (eaten = eat(nf.positiveSign, s, pos)) != -1) {
        state |= ParseState.Sign;
        pos += eaten;
      }
      else if (isSigned && (eaten = eat(nf.negativeSign, s, pos)) != -1) {
        state |= ParseState.Sign;
        pos += eaten;
        result.sign = 1;
      }
      else if (c == '(' &&
        (styles & NumberStyles.Parentheses) != 0 && ((state & ParseState.Sign) == 0)) {
        state |= ParseState.Sign | ParseState.Parens;
        result.sign = 1;
        pos++;
      }
      else if ((currencySymbol != null && (eaten = eat(currencySymbol, s, pos)) != -1)) {
        state |= ParseState.Currency;
        currencySymbol = null;
        pos += eaten;
      }
      else if (!(isWhitespace(c) && ((styles & NumberStyles.LeadingWhite) != 0)
        && ((state & ParseState.Sign) == 0 
        || ((state & ParseState.Sign) != 0 && ((state & ParseState.Currency) != 0 || nf.numberNegativePattern == 2)))))
        break;
      else pos++;
    }

    while (true) {
      if (pos == s.length) break;

      char c = s[pos];
      if (c >= '0' && c <= '9') {
        state |= ParseState.Digits;
        if (c != '0' || (state & ParseState.NonZero) != 0) {
          if (count < result.digits.length - 1) {
            result.digits[count++] = c;
            if (c != '0')
              end = count;
          }
          if ((state & ParseState.Decimal) == 0)
            result.scale++;
          state |= ParseState.NonZero;
        }
        else if ((state & ParseState.Decimal) != 0)
          result.scale--;
        pos++;
      }
      else if ((styles & NumberStyles.DecimalPoint) != 0 && (state & ParseState.Decimal) == 0 && (eaten = eat(decimalSeparator, s, pos)) != -1 
        || (state & ParseState.Currency) != 0 && (eaten = eat(altDecimalSeparator, s, pos)) != -1) {
        state |= ParseState.Decimal;
        pos += eaten;
      }
      else if ((styles & NumberStyles.Thousands) != 0 && (state & ParseState.Digits) != 0 && (state & ParseState.Decimal) == 0 
        && ((eaten = eat(groupSeparator, s, pos)) != -1 || (state & ParseState.Currency) != 0 
        && (eaten = eat(altGroupSeparator, s, pos)) != -1))
        pos += eaten;
      else break;
    }

    result.precision = end;
    result.digits[end] = '\0';

    if ((state & ParseState.Digits) != 0) {
      while (true) {
        if (pos >= s.length) break;

        char c = s[pos];
        if ((isSigned = ((styles & NumberStyles.TrailingSign) != 0 && (state & ParseState.Sign) == 0)) != 0 
          && (eaten = eat(nf.positiveSign, s, pos)) != -1) {
          state |= ParseState.Sign;
          pos += eaten;
        }
        else if (isSigned && (eaten = eat(nf.negativeSign, s, pos)) != -1) {
          state |= ParseState.Sign;
          result.sign = 1;
          pos += eaten;
        }
        else if (c == ')' && (state & ParseState.Parens) != 0)
          state &= ~ParseState.Parens;
        else if (currencySymbol != null && (eaten = eat(currencySymbol, s, pos)) != -1) {
          currencySymbol = null;
          pos += eaten;
        }
        else if (!(isWhitespace(c) & (styles & NumberStyles.TrailingWhite) != 0))
          break;
        else pos++;
      }

      if ((state & ParseState.Parens) == 0) {
        if ((state & ParseState.NonZero) == 0) {
          result.scale = 0;
          if ((state & ParseState.Decimal) == 0)
            result.sign = 0;
        }
        return true;
      }
      return false;
    }
    return false;
  }

  string toString(char format, int length, NumberFormat nf) {
    string ret;

    switch (format) {
      case 'n', 'N':
        if (length < 0)
          length = nf.numberDecimalDigits;
        round(scale + length);
        formatNumber(*this, ret, length, nf);
        break;
      case 'g', 'G':
        if (length < 0)
          length = precision;
        round(scale + length);
        if (sign)
          ret ~= nf.negativeSign;
        formatGeneral(*this, ret, length, (format == 'g') ? 'e' : 'E', nf);
        break;
      case 'c', 'C':
        if (length < 0)
          length = nf.currencyDecimalDigits;
        round(scale + length);
        formatCurrency(*this, ret, length, nf);
        break;
      default:
    }

    return ret;
  }

  string toStringFormat(string format, NumberFormat nf) {
    bool hasGroups = false, scientific = false;
    int groupCount = 0, groupPos = -1, pointPos = -1;
    int first = int.max, last, count, adjust;

    int n = 0;
    char c;
    while (n < format.length) {
      c = format[n++];

      switch (c) {
        case '#':
          count++;
          break;
        case '0':
          if (first == int.max)
            first = count;
          count++;
          last = count;
          break;
        case '%':
          adjust += 2;
          break;
        case '.':
          if (pointPos < 0)
            pointPos = count;
          break;
        case ',':
          if (count > 0 && pointPos < 0) {
            if (groupPos >= 0) {
              if (groupPos == count) {
                groupCount++;
                break;
              }
              hasGroups = true;
            }
            groupPos = count;
            groupCount = 1;
          }
          break;
        case '\'', '\"':
          while (n < format.length && format[n++] != c) {}
          break;
        case '\\':
          if (n < format.length) n++;
          break;
        default:
          break;
      }
    }

    if (pointPos < 0)
      pointPos = count;

    if (groupPos >= 0) {
      if (groupPos == pointPos)
        adjust -= groupCount * 3;
      else
        hasGroups = true;
    }

    if (digits[0] != '\0') {
      scale += adjust;
      round(scientific ? count : scale + count - pointPos);
    }

    first = (first < pointPos) ? pointPos - first : 0;
    last = (last > pointPos) ? pointPos - last : 0;

    int pos = pointPos;
    int extra = 0;
    if (!scientific) {
      pos = (scale > pointPos) ? scale : pointPos;
      extra = scale - pointPos;
    }

    string groupSeparator = nf.numberGroupSeparator;
    string decimalSeparator = nf.numberDecimalSeparator;

    int[] groupPositions;
    int groupIndex = -1;
    if (hasGroups) {
      if (nf.numberGroupSizes.length == 0)
        hasGroups = false;
      else {
        int groupSizesTotal = nf.numberGroupSizes[0];
        int groupSize = groupSizesTotal;
        int digitsTotal = pos + ((extra < 0) ? extra : 0);
        int digitCount = (first > digitsTotal) ? first : digitsTotal;

        int sizeIndex = 0;
        while (digitCount > groupSizesTotal) {
          if (groupSize == 0)
            break;
          groupPositions ~= groupSizesTotal;
          groupIndex++;
          if (sizeIndex < nf.numberGroupSizes.length - 1)
            groupSize = nf.numberGroupSizes[++sizeIndex];
          groupSizesTotal += groupSize;
        }
      }
    }

    string ret;
    if (sign)
      ret ~= nf.negativeSign;

    char* p = digits.ptr;
    n = 0;
    bool pointWritten = false;
    while (n < format.length) {
      c = format[n++];
      if (extra > 0 && (c == '#' || c == '0' || c == '.')) {
        while (extra > 0) {
          ret ~= (*p != '\0') ? *p++ : '0';

          if (hasGroups && pos > 1 && groupIndex >= 0) {
            if (pos == groupPositions[groupIndex] + 1) {
              ret ~= groupSeparator;
              groupIndex--;
            }
          }
          pos--;
          extra--;
        }
      }

      switch (c) {
        case '#', '0':
          if (extra < 0) {
            extra++;
            c = (pos <= first) ? '0' : char.init;
          }
          else c = (*p != '\0') ? *p++ : (pos > last) ? '0' : char.init;

          if (c != char.init) {
            ret ~= c;

            if (hasGroups && pos > 1 && groupIndex >= 0) {
              if (pos == groupPositions[groupIndex] + 1) {
                ret ~= groupSeparator;
                groupIndex--;
              }
            }
          }
          pos--;
          break;
        case '.':
          if (pos != 0 || pointWritten)
            break;
          if (last < 0 || (pointPos < count && *p++ != '\0')) {
            ret ~= decimalSeparator;
            pointWritten = true;
          }
          break;
        case ',':
          break;
        case '\'', '\"':
          if (n < format.length) n++;
          break;
        case '\\':
          if (n < format.length) ret ~= format[n++];
          break;
        default:
          ret ~= c;
          break;
      }
    }

    return ret;
  }

}

private string ulongToString(ulong value, int digits) {
  if (digits < 1)
    digits = 1;

  char[100] buffer;
  int n = 100;
  while (--digits >= 0 || value != 0) {
    buffer[--n] = value % 10 + '0';
    value /= 10;
  }

  return buffer[n .. $].dup;
}

private string longToString(long value, int digits, string negativeSign) {
  if (digits < 1)
    digits = 1;

  char[100] buffer;
  ulong uv = (value >= 0) ? value : cast(ulong)-value;
  int n = 100;
  while (--digits >= 0 || uv != 0) {
    buffer[--n] = uv % 10 + '0';
    uv /= 10;
  }

  if (value < 0) {
    n -= negativeSign.length;
    buffer[n .. n + negativeSign.length] = negativeSign;
  }

  return buffer[n .. $].dup;
}

private string intToHexString(uint value, int digits, char format) {
  if (digits < 1)
    digits = 1;

  char[100] buffer;
  int n = 100;
  while (--digits >= 0 || value != 0) {
    uint v = value & 0xF;
    buffer[--n] = (v < 10) ? v + '0' : v + format - ('X' - 'A' + 10);
    value >>= 4;
  }

  return buffer[n .. $].dup;
}

private string longToHexString(ulong value, int digits, char format) {
  if (digits < 1)
    digits = 1;

  char[100] buffer;
  int n = 100;
  while (--digits >= 0 || value != 0) {
    ulong v = value & 0xF;
    buffer[--n] = (v < 10) ? v + '0' : v + format - ('X' - 'A' + 10);
    value >>= 4;
  }

  return buffer[n .. $].dup;
}

private char parseFormatSpecifier(string format, out int length) {
  length = -1;
  char specifier = 'G';

  if (format != null) {
    int pos = 0;
    char c = format[pos];

    if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')) {
      specifier = c;

      pos++;
      if (pos == format.length)
        return specifier;
      c = format[pos];

      if (c >= '0' && c <= '9') {
        length = c - '0';

        pos++;
        if (pos == format.length)
          return specifier;
        c = format[pos];

        while (c >= '0' && c <= '9') {
          length = length * 10 + c - '0';

          pos++;
          if (pos == format.length)
            return specifier;
          c = format[pos];
        }
      }
    }
    return char.init;
  }
  return specifier;
}

package string formatUInt(uint value, string format, IFormatProvider provider) {
  auto nf = NumberFormat.get(provider);

  int length;
  char specifier = parseFormatSpecifier(format, length);

  switch (specifier) {
    case 'g', 'G':
      if (length > 0)
        break;
      // fall through
    case 'd', 'D':
      return ulongToString(cast(ulong)value, length);
    case 'x', 'X':
      return intToHexString(value, length, specifier);
    default:
  }

  auto number = Number(cast(long)value, 10);
  if (specifier != char.init)
    return number.toString(specifier, length, nf);
  return number.toStringFormat(format, nf);
}

package string formatInt(int value, string format, IFormatProvider provider) {
  auto nf = NumberFormat.get(provider);

  int length;
  char specifier = parseFormatSpecifier(format, length);

  switch (specifier) {
    case 'g', 'G':
      if (length > 0)
        break;
      // fall through
    case 'd', 'D':
      return longToString(cast(long)value, length, nf.negativeSign);
    case 'x', 'X':
      return intToHexString(cast(uint)value, length, specifier);
    default:
  }

  auto number = Number(cast(long)value, 10);
  if (specifier != char.init)
    return number.toString(specifier, length, nf);
  return number.toStringFormat(format, nf);
}

package string formatULong(ulong value, string format, IFormatProvider provider) {
  auto nf = NumberFormat.get(provider);

  int length;
  char specifier = parseFormatSpecifier(format, length);

  switch (specifier) {
    case 'g', 'G':
      if (length > 0)
        break;
      // fall through
    case 'd', 'D':
      return ulongToString(value, length);
    case 'x', 'X':
      return longToHexString(value, length, specifier);
    default:
  }

  auto number = Number(cast(long)value, 20);
  if (specifier != char.init)
    return number.toString(specifier, length, nf);
  return number.toStringFormat(format, nf);
}

package string formatLong(long value, string format, IFormatProvider provider) {
  auto nf = NumberFormat.get(provider);

  int length;
  char specifier = parseFormatSpecifier(format, length);

  switch (specifier) {
    case 'g', 'G':
      if (length > 0)
        break;
      // fall through
    case 'd', 'D':
      return longToString(value, length, nf.negativeSign);
    case 'x', 'X':
      return longToHexString(cast(ulong)value, length, specifier);
    default:
  }

  auto number = Number(cast(long)value, 20);
  if (specifier != char.init)
    return number.toString(specifier, length, nf);
  return number.toStringFormat(format, nf);
}

// Must match NumberFormat.decimalPositivePattern
private const string positiveNumberFormat = "#";
// Must match NumberFormat.decimalNegativePattern
private const string[] negativeNumberFormats = [ "(#)", "-#", "- #", "#-", "# -" ];
// Must match NumberFormat.currencyPositivePattern
private const string[] positiveCurrencyFormats = [ "$#", "#$", "$ #", "# $" ];
// Must match NumberFormat.currencyNegativePattern
private const string[] negativeCurrencyFormats = [ "($#)", "-$#", "$-#", "$#-", "(#$)", "-#$", "#-$", "#$-", "-# $", "-$ #", "# $-", "$ #-", "$ -#", "#- $", "($ #)", "(# $)" ];
// Must match NumberFormat.percentPositivePattern
private const string[] positivePercentFormats = [ "# %", "#%", "%#", "% #" ];
// Must match NumberFormat.percentNegativePattern
private const string[] negativePercentFormats = [ "-# %", "-#%", "-%#", "%-#", "%#-", "#-%", "#%-", "-% #", "# %-", "% #-", "% -#", "#- %" ];


private void formatNumber(ref Number number, ref string dst, int length, NumberFormat nf) {
  string format = number.sign ? negativeNumberFormats[1] : positiveNumberFormat;

  foreach (ch; format) {
    switch (ch) {
      case '#':
        formatFixed(number, dst, length, nf.numberGroupSizes, nf.numberDecimalSeparator, nf.numberGroupSeparator);
        break;
      case '-':
        dst ~= nf.negativeSign;
        break;
      default:
        dst ~= ch;
        break;
    }
  }
}

private void formatGeneral(ref Number number, ref string dst, int length, char format, NumberFormat nf) {
  int pos = number.scale;

  char* p = number.digits.ptr;
  if (pos > 0) {
    while (pos > 0) {
      dst ~= (*p != '\0') ? *p++ : '0';
      pos--;
    }
  }
  else
    dst ~= '0';

  if (*p != '\0' || pos < 0) {
    dst ~= nf.numberDecimalSeparator;
    while (pos < 0) {
      dst ~= '0';
      pos++;
    }
    while (*p != '\0') dst ~= *p++;
  }
}

private void formatCurrency(ref Number number, ref char[] dst, int length, NumberFormat nf) {
  string format = number.sign ? negativeCurrencyFormats[nf.currencyNegativePattern] : positiveCurrencyFormats[nf.currencyPositivePattern];

  foreach (ch; format) {
    switch (ch) {
      case '#':
        formatFixed(number, dst, length, nf.currencyGroupSizes, nf.currencyDecimalSeparator, nf.currencyGroupSeparator);
        break;
      case '-':
        dst ~= nf.negativeSign;
        break;
      case '$':
        dst ~= nf.currencySymbol;
        break;
      default:
        dst ~= ch;
        break;
    }
  }
}

private void formatFixed(ref Number number, ref string dst, int length, int[] groupSizes, string decimalSeparator, string groupSeparator) {
  int pos = number.scale;
  char* p = number.digits.ptr;

  if (pos > 0) {
    if (groupSizes.length != 0) {
      // Are there enough digits to format?
      int count = groupSizes[0];
      int index, size;

      while (pos > count) {
        size = groupSizes[index];
        if (size == 0)
          break;
        if (index < groupSizes.length - 1)
          index++;
        count += groupSizes[index];
      }

      size = (count == 0) ? 0 : groupSizes[0];

      // Insert separator at positions specified by groupSizes.
      int end = strlen(p);
      int start = (pos < end) ? pos : end;
      string separator = groupSeparator.reverse;
      char[] temp;

      index = 0;
      for (int c, i = pos - 1; i >= 0; i--) {
        temp ~= (i < start) ? number.digits[i] : '0';
        if (size > 0) {
          c++;
          if (c == size && i != 0) {
            temp ~= separator;
            if (index < groupSizes.length - 1)
              size = groupSizes[++index];
            c = 0;
          }
        }
      }

      // Because we built the string backwards, reverse it.
      dst ~= temp.reverse;
      p += start;
    }
    else while (pos > 0) {
      dst ~= (*p != '\0') ? *p++ : '0';
      pos--;
    }
  }
  else
    dst ~= '0'; //  Negative scale.

  if (length > 0) {
    dst ~= decimalSeparator;
    while (pos < 0 && length > 0) {
      dst ~= '0';
      pos++;
      length--;
    }
    while (length > 0) {
      dst ~= (*p != '\0') ? *p++ : '0';
      length--;
    }
  }
}

package uint parseUInt(string s, NumberStyles style, NumberFormat nf) {
  Number n;
  if (!Number.tryParse(s, style, nf, n))
    throw new FormatException("Input string was not valid.");

  long value;
  if (!n.toLong(value) || (value < uint.min || value > uint.max))
    throw new OverflowException("Value was either too small or too large for a uint.");
  return cast(uint)value;
}

package int parseInt(string s, NumberStyles style, NumberFormat nf) {
  Number n;
  if (!Number.tryParse(s, style, nf, n))
    throw new FormatException("Input string was not valid.");

  long value;
  if (!n.toLong(value) || (value < int.min || value > int.max))
    throw new OverflowException("Value was either too small or too large for an int.");
  return cast(int)value;
}

package ulong parseULong(string s, NumberStyles style, NumberFormat nf) {
  Number n;
  if (!Number.tryParse(s, style, nf, n))
    throw new FormatException("Input string was not valid.");

  long value;
  if (!n.toLong(value) || (value < ulong.min || value > ulong.max))
    throw new OverflowException("Value was either too small or too large for a ulong.");
  return cast(ulong)value;
}

package long parseLong(string s, NumberStyles style, NumberFormat nf) {
  Number n;
  if (!Number.tryParse(s, style, nf, n))
    throw new FormatException("Input string was not valid.");

  long value;
  if (!n.toLong(value) || (value < long.min || value > long.max))
    throw new OverflowException("Value was either too small or too large for a long.");
  return value;
}