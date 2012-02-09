/**
 * Contains classes that define culture-related information.
 *
 * Copyright: (c) 2009 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.locale.core;

import juno.base.core,
  juno.base.native,
  juno.locale.constants;
import juno.locale.time : Calendar,
  CalendarData,
  GregorianCalendar,
  JapaneseCalendar,
  TaiwanCalendar,
  KoreanCalendar,
  ThaiBuddhistCalendar;
import std.utf : toUTF8;
import std.string : icmp, toLower, toUpper, wcslen;
import std.c.stdio : sprintf;
import std.c.string : memcmp, memicmp;
import std.exception;
import std.range;
import std.conv;

import std.string : indexOf, lastIndexOf;

debug import std.stdio : writefln;

extern(C) int swscanf(in wchar*, in wchar*, ...);

private uint[string] nameToLcidMap;
private string[uint] lcidToNameMap;
private uint[string] regionNameToLcidMap;

static ~this() {
  nameToLcidMap = null;
  lcidToNameMap = null;
  regionNameToLcidMap = null;
}

package wchar* toUTF16zNls(string s, int offset, int length, out int translated) {
  translated = 0;
  if (s.length == 0)
    return null;

  auto pChars = s.ptr + offset;
  int cch = MultiByteToWideChar(CP_UTF8, 0, pChars, length, null, 0);
  if (cch == 0)
    return null;

  wchar[] result = new wchar[cch];
  translated = MultiByteToWideChar(CP_UTF8, 0, pChars, length, result.ptr, cch);
  return result.ptr;
}

package string toUTF8Nls(in wchar* pChars, int cch, out int translated) {
  translated = 0;

  int cb = WideCharToMultiByte(CP_UTF8, 0, pChars, cch, null, 0, null, null);
  if (cb == 0)
    return null;

  char[] result = new char[cb];
  translated = WideCharToMultiByte(CP_UTF8, 0, pChars, cch, result.ptr, cb, null, null);
  return cast(string)result;
}

package string getLocaleInfo(uint locale, uint field, bool userOverride = true) {
  wchar[80] buffer;
  int cch = GetLocaleInfo(locale, field | (!userOverride ? LOCALE_NOUSEROVERRIDE : 0), buffer.ptr, buffer.length);
  if (cch == 0)
    return null;

  return toUTF8(buffer[0 .. cch - 1]);
}

package int getLocaleInfoI(uint locale, uint field, bool userOverride = true) {
  int result;
  GetLocaleInfo(locale, field | LOCALE_RETURN_NUMBER | (!userOverride ? LOCALE_NOUSEROVERRIDE : 0), cast(wchar*)&result, int.sizeof);
  return result;
}

package string getCalendarInfo(uint locale, uint calendar, uint field, bool userOverride = true) {
  wchar[80] buffer;
  int cch = GetCalendarInfo(locale, calendar, field | (!userOverride ? CAL_NOUSEROVERRIDE : 0), buffer.ptr, buffer.length, null);
  if (cch == 0)
    return null;

  return toUTF8(buffer[0 .. cch - 1]);
}

package string getGeoInfo(uint geoId, uint geoType) {
  int cch = GetGeoInfo(geoId, geoType, null, 0, 0);
  wchar[] buffer = new wchar[cch];
  cch = GetGeoInfo(geoId, geoType, buffer.ptr, cast(int)buffer.length, 0);
  if (cch == 0)
    return null;

  return toUTF8(buffer[0 .. cch - 1]);
}

private void ensureNameMapping() {

  bool enumSystemLocales(out uint[] locales) {
    static uint[uint] temp;

    extern(Windows)
    static int enumLocalesProc(wchar* lpLocaleString) {
      uint locale;
      if (swscanf(lpLocaleString, "%x", &locale) > 0) {
        if (!(locale in temp)) {
          temp[locale] = locale;

          // Also add neutrals.
          uint lang = locale & 0x3FF;
          if (!(lang in temp) && (lang != 0x0014 && lang != 0x002C && lang != 0x003B && lang != 0x0043))
            temp[lang] = lang;
        }
      }
      return true;
    }

    temp = null;
    if (!EnumSystemLocales(&enumLocalesProc, LCID_SUPPORTED))
      return false;

    locales = temp.values;
    return true;
  }

  string getLocaleName(uint locale) {
    string name, language, script, country;

    // Get the name from NLS, natively on Vista and above, or via the downlevel package for XP.
    try {
      wchar[85] buffer;
      int cch = LCIDToLocaleName(locale, buffer.ptr, buffer.length, 0); // Vista and above
      if (cch != 0)
        name = toUTF8(buffer[0 .. cch - 1]);
    }
    catch (EntryPointNotFoundException) {
      try {
        wchar[85] buffer;
        int cch = DownlevelLCIDToLocaleName(locale, buffer.ptr, buffer.length, 0); // nlsmap.dll
        if (cch != 0)
          name = toUTF8(buffer[0 .. cch - 1]);
      }
      catch (DllNotFoundException) {
      }
      catch (EntryPointNotFoundException) {
      }
    }

    // NLS doesn't return names for neutral locales.
    if (name != null) {
      if ((locale & 0x3FF) == locale) {
        name = getLocaleInfo(locale, LOCALE_SPARENT); // Vista and above

        if (name == null) {
          try {
            wchar[85] buffer;
            int cch = DownlevelGetParentLocaleName(locale, buffer.ptr, buffer.length); // nlsmap.dll
            if (cch != 0)
              name = toUTF8(buffer[0 .. cch - 1]);
          }
          catch (DllNotFoundException) {
          }
          catch (EntryPointNotFoundException) {
          }
        }
      }
    }

    // If we haven't got the name from the above methods, manually build it.
    if (name == null) {
      if (locale == 0x243B)
        language = "smn";
      else if (locale == 0x203B)
        language = "sms";
      else if (locale == 0x1C3B || locale == 0x183B)
        language = "sma";
      else if (locale == 0x143B || locale == 0x103B)
        language = "smj";
      else if (locale == 0x046B || locale == 0x086B || locale == 0x0C6B)
        language = "quz";
      else
        language = getLocaleInfo(locale, LOCALE_SISO639LANGNAME);

      if ((locale & 0x3FF) != locale) {
        if (locale == 0x181A || locale == 0x081A || locale == 0x042C || locale == 0x0443 || locale == 0x141A)
          script = "Latn";
        else if (locale == 0x1C1A || locale == 0x0C1A || locale == 0x082C || locale == 0x0843 || locale == 0x085D || locale == 0x085F)
          script = "Cyrl";
        else if (locale == 0x0850)
          script = "Mong";

        if (locale == 0x2409)
          country = "029";
        else if (locale == 0x081A || locale == 0x0C1A)
          country = "CS";
        else if (locale == 0x040A)
          country ~= "ES_tradnl";
        else
          country = getLocaleInfo(locale, LOCALE_SISO3166CTRYNAME);
      }

      name = language;
      if (script != null)
        name ~= '-' ~ script;
      if (country != null)
        name ~= '-' ~ country;
    }

    return name;
  }

  if (nameToLcidMap == null) {
    synchronized {
      uint[] locales;
      if (enumSystemLocales(locales)) {
        locales.sort;
        foreach (lcid; locales) {
          string name = getLocaleName(lcid);
          if (name != null) {
            nameToLcidMap[name] = lcid;
            lcidToNameMap[lcid] = name;
          }
        }

        nameToLcidMap[""] = LOCALE_INVARIANT;
        lcidToNameMap[LOCALE_INVARIANT] = "";
      }
    }
  }

}

private void ensureRegionMapping() {

  bool enumSystemLocales(out uint[] locales) {
    static uint[uint] temp;

    extern(Windows)
    static int enumLocalesProc(wchar* lpLocaleString) {
      uint locale;
      if (swscanf(lpLocaleString, "%x", &locale) > 0) {
        if (!(locale in temp))
          temp[locale] = locale;
      }
      return true;
    }

    temp = null;
    if (!EnumSystemLocales(&enumLocalesProc, LCID_SUPPORTED))
      return false;

    locales = temp.values;
    return true;
  }

  if (regionNameToLcidMap == null) {
    synchronized {
      uint[] locales;
      if (enumSystemLocales(locales)) {
        foreach (lcid; locales) {
          string name = getLocaleInfo(lcid, LOCALE_SISO3166CTRYNAME);
          regionNameToLcidMap[name] = lcid;
        }
      }
    }
  }
}

package bool findCultureByName(string cultureName, out string actualName, out uint culture) {
  ensureNameMapping();

  foreach (name, lcid; nameToLcidMap) {
    if (icmp(cultureName, name) == 0) {
      actualName = name;
      culture = lcid;
      return true;
    }
  }

  return false;
}

package bool findCultureById(uint culture, out string cultureName, out uint actualCulture) {
  if (culture != LOCALE_INVARIANT) {
    ensureNameMapping();

    if (auto value = culture in lcidToNameMap)
      return findCultureByName(*value, cultureName, actualCulture);

    return false;
  }

  return findCultureByName("", cultureName, actualCulture);
}

package bool findCultureFromRegionName(string regionName, out uint culture) {
  ensureRegionMapping();

  foreach (name, lcid; regionNameToLcidMap) {
    if (icmp(regionName, name) == 0) {
      culture = lcid;
      return true;
    }
  }

  foreach (name, lcid; nameToLcidMap) {
    if (icmp(regionName, name) == 0) {
      culture = lcid;
      return true;
    }
  }

  return false;
}

private bool isNeutralCulture(uint culture) {
  return (culture != LOCALE_INVARIANT) && ((culture & 0x3FF) == culture);
}

/**
 * Retrieves an object that controls formatting.
 */
interface IFormatProvider {

  /**
   * Gets an object that provides formatting services for the specified type.
   * Params: formatType = An object that identifies the type of format to get.
   * Returns: The current instance if formatType is the same type as the current instance; otherwise, null.
   */
  Object getFormat(TypeInfo formatType);

}

/**
 * Provides information about a specific culture (locale).
 */
class Culture : IFormatProvider {

  private static Culture[string] nameCultures_;
  private static Culture[uint] lcidCultures_;

  private static Culture userDefault_;
  private static Culture userDefaultUI_;
  private static Culture constant_;
  private static Culture current_;
  private static Culture currentUI_;

  private uint cultureId_;
  private string cultureName_;

  package bool isReadOnly_;
  package bool isInherited_;
  private string listSeparator_;

  private Culture parent_;

  private NumberFormat numberFormat_;
  private DateTimeFormat dateTimeFormat_;
  private Calendar calendar_;
  private CalendarData[] calendars_;
  private Collator collator_;

  static this() {
    constant_ = new Culture(LOCALE_INVARIANT);
    constant_.isReadOnly_ = true;

    userDefault_ = initUserDefault();
    userDefaultUI_ = initUserDefaultUI();
  }

  static ~this() {
    userDefault_ = null;
    userDefaultUI_ = null;
    constant_ = null;
    current_ = null;
    currentUI_ = null;
    nameCultures_ = null;
    lcidCultures_ = null;
  }

  /**
   * Initializes a new instance based on the _culture specified by the _culture identifier.
   * Params: culture = A predefined Culture identifier.
   */
  this(uint culture) {
    if ((culture == LOCALE_NEUTRAL ||
      culture == LOCALE_SYSTEM_DEFAULT ||
      culture == LOCALE_USER_DEFAULT) ||
      !findCultureById(culture, cultureName_, cultureId_)) {
      scope buffer = new char[100];
      int len = sprintf(buffer.ptr, "Culture ID %d (0x%04x) is not a supported culture.", culture, culture);
      throw new ArgumentException(assumeUnique(buffer[0 .. len]), "culture");
    }

    isInherited_ = (typeid(typeof(this)) != typeid(Culture));
  }

  /**
   * Initializes a new instance based on the culture specified by name.
   * Params: name = A predefined culture _name.
   */
  this(string name) {
    if (!findCultureByName(name, cultureName_, cultureId_))
      throw new ArgumentException("Culture name '" ~ name ~ "' not supported.", "name");

    isInherited_ = (typeid(typeof(this)) != typeid(Culture));
  }

  /**
   * Gets an object that defines how to format the specified type.
   * Params: formatType = The type to get a formatting object for. Supports NumberFormat and DateTimeFormat.
   * Returns: The value of the numberFormat property or the value of the dateTimeFormat property, depending on formatType.
   */
  Object getFormat(TypeInfo formatType) {
    if (formatType == typeid(NumberFormat))
      return numberFormat;
    else if (formatType == typeid(DateTimeFormat))
      return dateTimeFormat;
    return null;
  }

  /**
   * Retrieves a cached, read-only instance of a _culture using the specified _culture identifier.
   * Params: culture = A _culture identifier.
   * Returns: A read-only Culture object.
   */
  static Culture get(uint culture) {
    if (culture <= 0)
      throw new ArgumentException("Number greater than zero required.", "culture");

    Culture ret = getCultureWorker(culture, null);

    if (ret is null) {
      scope buffer = new char[100];
      int len = sprintf(buffer.ptr, "Culture ID %d (0x%04x) is not a supported culture.", culture, culture);
      throw new ArgumentException(assumeUnique(buffer[0 .. len]), "culture");
    }

    return ret;
  }

  /**
   * Retrieves a cached, read-only instance of a culture using the specified culture _name.
   * Params: name = The _name of the culture.
   * Returns: A read-only Culture object.
   */
  static Culture get(string name) {
    Culture ret = getCultureWorker(0, name);

    if (ret is null)
      throw new ArgumentException("Culture name '" ~ name ~ "' not supported.", "name");

    return ret;
  }

  private static Culture getCultureWorker(uint lcid, string name) {
    if (name != null)
      name = name.toLower();

    if (lcid == 0) {
      if (auto value = name in nameCultures_)
        return *value;
    }
    else if (lcid > 0) {
      if (auto value = lcid in lcidCultures_)
        return *value;
    }

    Culture culture = null;

    try {
      if (lcid == 0)
        culture = new Culture(name);
      else if (userDefault_ !is null && userDefault_.lcid == lcid)
        culture = userDefault_;
      else
        culture = new Culture(lcid);
    }
    catch (ArgumentException) {
      return null;
    }

    culture.isReadOnly_ = true;

    nameCultures_[culture.name] = culture;
    lcidCultures_[culture.lcid] = culture;

    return culture;
  }

  /**
   * Gets the list of supported cultures filtered by the specified CultureTypes parameter.
   * Params: types = A bitwise combination of CultureTypes values.
   * Returns: An array of type Culture.
   */
  static Culture[] getCultures(CultureTypes types) {
    bool includeSpecific = (types & CultureTypes.Specific) != 0;
    bool includeNeutral = (types & CultureTypes.Neutral) != 0;

    Culture[] list;

    if (includeNeutral || includeSpecific) {
      if (lcidToNameMap == null)
        ensureNameMapping();

      foreach (name; lcidToNameMap.keys.sort) {
        Culture c = new Culture(lcidToNameMap[name]);
        CultureTypes ct = c.types;

        if ((includeSpecific && c.name.length > 0 && (ct & CultureTypes.Specific) != 0) ||
          (includeNeutral && ((ct & CultureTypes.Neutral) != 0 || c.name.length == 0)))
          list ~= c;
      }
    }

    return list.dup;
  }

  /**
   * Gets the Culture that is culture-independent.
   * Returns: The Culture that is culture-independent.
   */
  static @property Culture constant() {
    return constant_;
  }

  /**
   * Gets or sets the Culture that represents the culture used by the _current thread.
   * Returns: The Culture that represents the culture used by the _current thread.
   */
  static @property void current(Culture value) {
    if (value is null)
      throw new ArgumentNullException("value");

    checkNeutral(value);
    SetThreadLocale(value.lcid);
    current_ = value;
  }

  /**
   * ditto
   */
  static @property Culture current() {
    if (current_ !is null)
      return current_;

    return userDefault;
  }

  /**
   * Gets or sets the Culture that represents the current culture used to look up resources.
   * Returns: The Culture that represents the current culture used to look up resources.
   */
  static @property void currentUI(Culture value) {
    if (value is null)
      throw new ArgumentNullException("value");

    currentUI_ = value;
  }

  /**
   * ditto
   */
  static @property Culture currentUI() {
    if (currentUI_ !is null)
      return currentUI_;

    return userDefaultUI;
  }

  /**
   * Gets the Culture that represents the _parent culture of the current instance.
   * Returns: The Culture that represents the _parent culture.
   */
  Culture parent() {
    if (parent_ is null) {
      try {
        uint parentCultureLcid = isNeutral ? LOCALE_INVARIANT : cultureId_ & 0x3ff;
        if (parentCultureLcid == LOCALE_INVARIANT)
          parent_ = Culture.constant;
        else
          parent_ = new Culture(parentCultureLcid);
      }
      catch (ArgumentException) {
        parent_ = Culture.constant;
      }
    }
    return parent_;
  }

  /**
   * Gets the culture identifier of the current instance.
   * Returns: The culture identifier.
   */
  @property uint lcid() {
    return cultureId_;
  }

  /**
   * Gets the culture _name in the format "&lt;language&gt;-&lt;region&gt;".
   * Returns: The culture _name.
   */
  @property string name() {
    return cultureName_;
  }

  /**
   * Gets the culture name in the format "&lt;language&gt; (&lt;region&gt;)" in
   * the language of the culture.
   * Returns: The culture name in the language of the culture.
   */
  @property string nativeName() {
    string s = getLocaleInfo(cultureId_, LOCALE_SNATIVELANGNAME);
    if (!isNeutral)
      s ~= " (" ~ getLocaleInfo(cultureId_, LOCALE_SNATIVECTRYNAME) ~ ")";
    else {
      int i = s.lastIndexOf("(");
      if (i != -1 && s.lastIndexOf(")") != -1)
        s.length = i - 1;
    }
    return s;
  }
  // May reuse this implementation but behavior is different
  // so I will go with this other form
  version(none)
  string nativeName() {
    string s = getLocaleInfo(cultureId_, LOCALE_SNATIVELANGNAME);
    if (!isNeutral)
      s ~= " (" ~ getLocaleInfo(cultureId_, LOCALE_SNATIVECTRYNAME) ~ ")";
    else {
      s = removeCountry(s);
    }
    return s;
  }

  /**
   * Gets the culture name in the format "&lt;language&gt; (&lt;region&gt;)" in English.
   * Returns: The culture name in English.
   */
  @property string englishName() {
    string s = getLocaleInfo(cultureId_, LOCALE_SENGLANGUAGE);
    if (!isNeutral)
      s ~= " (" ~ getLocaleInfo(cultureId_, LOCALE_SENGCOUNTRY) ~ ")";
    else {
      int i = s.lastIndexOf("(");
      if (i != -1 && s.lastIndexOf(")") != -1)
        s.length = i - 1;
    }
    return s;
  }
  // May reuse this implementation but behavior is different
  // so I will go with this other form
  version(none)
  string englishName() {
    string s = getLocaleInfo(cultureId_, LOCALE_SENGLANGUAGE);
    if (!isNeutral)
      s ~= " (" ~ getLocaleInfo(cultureId_, LOCALE_SENGCOUNTRY) ~ ")";
    else {
      s = removeCountry(s);
    }
    return s;
  }

  /**
   * Gets the culture name in the format "&lt;language&gt; (&lt;region&gt;)" in the localised version of Windows.
   * Returns: The culture name in the localised version of Windows.
   */
  @property string displayName() {
    string s = getLocaleInfo(cultureId_, LOCALE_SLANGUAGE);
    if (s != null && isNeutral && cultureId_ != LOCALE_INVARIANT) {
      // Remove country from neutral cultures.
      int i = s.lastIndexOf("(");
      if (i != -1 && s.lastIndexOf(")") != -1)
        s.length = i - 1;
    }

    if (s != null && !isNeutral && cultureId_ != LOCALE_INVARIANT) {
      // Add country to specific cultures.
      if (s.indexOf("(") == -1 && s.indexOf(")") == -1)
        s ~= " (" ~ getLocaleInfo(cultureId_, LOCALE_SCOUNTRY) ~ ")";
    }

    if (s != null)
      return s;
    return nativeName;
  }
  // May reuse this implementation but behavior is different
  // so I will go with this other form
  version(none)
  string displayName() {
    string s = getLocaleInfo(cultureId_, LOCALE_SLANGUAGE);
    if (s != null && isNeutral && cultureId_ != LOCALE_INVARIANT) {
      s = removeCountry(s);
    }

    if (s != null && !isNeutral && cultureId_ != LOCALE_INVARIANT) {
      s = addCountry(s);
    }

    if (s != null)
      return s;
    return nativeName;
  }

  // May reuse this implementation but behavior is different
  // so I will go with this other form
  version(none) {
  // Remove country from neutral cultures.
  private string removeCountry(string s) {
      auto s2 = find(s.retro, "(");
      s2.popFront;
      return to!string(retro(s2));
  }

  // Add country to specific cultures.
  private string addCountry(string s) {
      if (s.indexOf("(").empty && s.indexOf(")").empty)
          s ~= " (" ~ getLocaleInfo(cultureId_, LOCALE_SCOUNTRY) ~ ")";

      return s;
  }
  }

  /**
   * Gets or sets the string that separates items in a list.
   * Params: value = The string that separates items in a list.
   */
  @property void listSeparator(string value) {
    checkReadOnly();

    listSeparator_ = value;
  }

  /// ditto
  @property string listSeparator() {
    if (listSeparator_ == null)
      listSeparator_ = getLocaleInfo(cultureId_, LOCALE_SLIST);
    return listSeparator_;
  }

  /**
   * Gets a value indictating whether the current instance represents a neutral culture.
   * Returns: true if the current instance represents a neutral culture; otherwise, false.
   */
  @property bool isNeutral() {
    return isNeutralCulture(cultureId_);
  }

  /**
   * Gets a value indicating whether the current instance is read-only.
   * Returns: true if the current instance is read-only; otherwise, false.
   */
  @property final bool isReadOnly() {
    return isReadOnly_;
  }

  /**
   * Gets the culture _types that pertain to the current instance.
   * Returns: A bitwise combination of CultureTypes values.
   */
  @property CultureTypes types() {
    CultureTypes ret = cast(CultureTypes)0;
    if (isNeutral)
      ret |= CultureTypes.Neutral;
    else
      ret |= CultureTypes.Specific;
    return ret;
  }

  /**
   * $(I Property.) Gets or sets a NumberFormat that defines the culturally appropriate format of displaying numbers and currency.
   */
  @property void numberFormat(NumberFormat value) {
    checkReadOnly();

    if (value is null)
      throw new ArgumentNullException("value");

    numberFormat_ = value;
  }
  /// ditto
  @property NumberFormat numberFormat() {
    if (numberFormat_ is null) {
      checkNeutral(this);

      numberFormat_ = new NumberFormat(cultureId_);
      numberFormat_.isReadOnly_ = isReadOnly_;
    }
    return numberFormat_;
  }

  /**
   *$(I Property.) Gets or sets a DateTimeFormat that defines the culturally appropriate format of displaying dates and times.
   */
  @property void dateTimeFormat(DateTimeFormat value) {
    checkReadOnly();

    if (value is null)
      throw new ArgumentNullException("value");

    dateTimeFormat_ = value;
  }
  /// ditto
  @property DateTimeFormat dateTimeFormat() {
    if (dateTimeFormat_ is null) {
      checkNeutral(this);

      dateTimeFormat_ = new DateTimeFormat(cultureId_, calendar);
      dateTimeFormat_.isReadOnly_ = isReadOnly_;
    }
    return dateTimeFormat_;
  }

  /**
   * Gets the default _calendar used by the culture.
   * Returns: A Calendar that represents the default _calendar used by a culture.
   */
  @property Calendar calendar() {
    if (calendar_ is null) {
      calendar_ = getCalendar(getLocaleInfoI(cultureId_, LOCALE_ICALENDARTYPE));
      calendar_.isReadOnly_ = isReadOnly_;
    }
    return calendar_;
  }

  @property Calendar[] optionalCalendars() {
    static int[] temp;

    extern(Windows)
    static int enumCalendarsProc(wchar* lpCalendarInfoString, uint Calendar) {
      temp ~= Calendar;
      return 1;
    }

    temp = null;
    if (!EnumCalendarInfoEx(&enumCalendarsProc, cultureId_, ENUM_ALL_CALENDARS, CAL_ICALINTVALUE))
      return null;

    auto cals = new Calendar[temp.length];
    for (int i = 0; i < cals.length; i++)
      cals[i] = getCalendar(temp[i]);
    return cals;
  }

  /**
   * Gets the Collator that defines how to compare strings for the culture.
   * Returns: The Collator that defines how to compare strings for the culture.
   */
  @property Collator collator() {
    if (collator_ is null)
      collator_ = Collator.get(cultureId_);
    return collator_;
  }

  /**
   * Returns a string containing the name of the current instance.
   * Returns: A string containing the name of the current instance.
   */
  override string toString() {
    return cultureName_;
  }

  private static void checkNeutral(Culture culture) {
    if (culture.isNeutral)
      throw new NotSupportedException("Culture '" ~ culture.name ~ "' is a neutral culture and cannot be used in formatting.");
  }

  private void checkReadOnly() {
    if (isReadOnly_)
      throw new InvalidOperationException("Instance is read-only.");
  }

  private static Calendar getCalendar(int calendarId) {
    // We only implement calendars that Windows supports.
    switch (calendarId) {
      case CAL_GREGORIAN,
        CAL_GREGORIAN_US,
        CAL_GREGORIAN_ME_FRENCH,
        CAL_GREGORIAN_ARABIC,
        CAL_GREGORIAN_XLIT_ENGLISH,
        CAL_GREGORIAN_XLIT_FRENCH:
        return new GregorianCalendar(cast(GregorianCalendarType)calendarId);
      case CAL_JAPAN:
        return new JapaneseCalendar;
      case CAL_TAIWAN:
        return new TaiwanCalendar;
      case CAL_KOREA:
        return new KoreanCalendar;
      /*case CAL_HIJRI:
        return new HijriCalendar;*/
      case CAL_THAI:
        return new ThaiBuddhistCalendar;
      /*case CAL_HEBREW:
        return new HebrewCalendar;
      case CAL_UMALQURA:
        return new UmAlQuraCalendar;*/
      default:
    }
    return new GregorianCalendar;
  }

  private CalendarData calendarData(int calendarId) {
    // A culture might use many calendars.
    if (calendars_.length == 0)
      calendars_.length = /*CAL_UMALQURA*/ 23;

    auto calendarData = calendars_[calendarId - 1];
    if (calendarData is null)
      calendarData = calendars_[calendarId - 1] = new CalendarData(cultureName_, calendarId);
    return calendarData;
  }

  private static Culture initUserDefault() {
    Culture culture = null;

    try {
      culture = new Culture(GetUserDefaultLCID());
    }
    catch (ArgumentException) {
    }

    if (culture is null)
      return Culture.constant;

    culture.isReadOnly_ = true;
    return culture;
  }

  private static Culture initUserDefaultUI() {
    uint lcid = GetUserDefaultLangID();
    if (lcid == Culture.userDefault.lcid)
      return Culture.userDefault;

    Culture culture = null;

    try {
      culture = new Culture(GetSystemDefaultLangID());
    }
    catch (ArgumentException) {
    }

    if (culture is null)
      return Culture.constant;

    culture.isReadOnly_ = true;
    return culture;
  }

  private static @property Culture userDefault() {
    if (userDefault_ is null)
      userDefault_ = initUserDefault();
    return userDefault_;
  }

  private static @property Culture userDefaultUI() {
    if (userDefaultUI_ is null)
      userDefaultUI_ = initUserDefaultUI();
    return userDefaultUI_;
  }

}

/**
 * Defines how numeric values are formatted and displayed.
 */
class NumberFormat : IFormatProvider {

  private static NumberFormat constant_;
  private static NumberFormat current_;

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

  /**
   * Initializes a new instance.
   */
  this() {
    this(LOCALE_INVARIANT);
  }

  /**
   */
  Object getFormat(TypeInfo formatType) {
    if (formatType == typeid(NumberFormat))
      return this;
    return null;
  }

  /**
   */
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

  /**
   */
  static @property NumberFormat constant() {
    if (constant_ is null) {
      constant_ = new NumberFormat;
      constant_.isReadOnly_ = true;
    }
    return constant_;
  }

  /**
   */
  static @property NumberFormat current() {
    Culture culture = Culture.current;
    if (!culture.isInherited_) {
      if (auto result = culture.numberFormat_)
        return result;
    }
    return cast(NumberFormat)culture.getFormat(typeid(NumberFormat));
  }

  /**
   */
  @property void numberGroupSizes(int[] value) {
    checkReadOnly();
    numberGroupSizes_ = value;
  }

  /**
   * ditto
   */
  @property int[] numberGroupSizes() {
    return numberGroupSizes_;
  }

  /**
   */
  @property void currencyGroupSizes(int[] value) {
    checkReadOnly();
    currencyGroupSizes_ = value;
  }

  /**
   * ditto
   */
  @property int[] currencyGroupSizes() {
    return currencyGroupSizes_;
  }

  /**
   */
  @property void positiveSign(string value) {
    checkReadOnly();
    positiveSign_ = value;
  }

  /**
   * ditto
   */
  @property string positiveSign() {
    return positiveSign_;
  }

  /**
   */
  @property void negativeSign(string value) {
    checkReadOnly();
    negativeSign_ = value;
  }

  /**
   * ditto
   */
  @property string negativeSign() {
    return negativeSign_;
  }

  /**
   */
  @property void numberDecimalSeparator(string value) {
    checkReadOnly();
    numberDecimalSeparator_ = value;
  }

  /**
   * ditto
   */
  @property string numberDecimalSeparator() {
    return numberDecimalSeparator_;
  }

  /**
   */
  @property void currencyDecimalSeparator(string value) {
    checkReadOnly();
    currencyDecimalSeparator_ = value;
  }

  /**
   * ditto
   */
  @property string currencyDecimalSeparator() {
    return currencyDecimalSeparator_;
  }

  /**
   */
  @property void numberGroupSeparator(string value) {
    checkReadOnly();
    numberGroupSeparator_ = value;
  }

  /**
   * ditto
   */
  @property string numberGroupSeparator() {
    return numberGroupSeparator_;
  }

  /**
   */
  @property void currencyGroupSeparator(string value) {
    checkReadOnly();
    currencyGroupSeparator_ = value;
  }

  /**
   * ditto
   */
  @property string currencyGroupSeparator() {
    return currencyGroupSeparator_;
  }

  /**
   */
  @property void currencySymbol(string value) {
    checkReadOnly();
    currencySymbol_ = value;
  }

  /**
   * ditto
   */
  @property string currencySymbol() {
    return currencySymbol_;
  }

  /**
   */
  @property void nanSymbol(string value) {
    checkReadOnly();
    nanSymbol_ = value;
  }

  /**
   * ditto
   */
  @property string nanSymbol() {
    return nanSymbol_;
  }

  /**
   */
  @property void positiveInfinitySymbol(string value) {
    checkReadOnly();
    positiveInfinitySymbol_ = value;
  }

  /**
   * ditto
   */
  @property string positiveInfinitySymbol() {
    return positiveInfinitySymbol_;
  }

  /**
   */
  @property void negativeInfinitySymbol(string value) {
    checkReadOnly();
    negativeInfinitySymbol_ = value;
  }

  /**
   * ditto
   */
  @property string negativeInfinitySymbol() {
    return negativeInfinitySymbol_;
  }

  /**
   */
  @property void numberDecimalDigits(int value) {
    checkReadOnly();
    numberDecimalDigits_ = value;
  }

  /**
   * ditto
   */
  @property int numberDecimalDigits() {
    return numberDecimalDigits_;
  }

  /**
   */
  @property void currencyDecimalDigits(int value) {
    checkReadOnly();
    currencyDecimalDigits_ = value;
  }

  /**
   * ditto
   */
  @property int currencyDecimalDigits() {
    return currencyDecimalDigits_;
  }

  /**
   */
  @property void currencyPositivePattern(int value) {
    checkReadOnly();
    currencyPositivePattern_ = value;
  }

  /**
   * ditto
   */
  @property int currencyPositivePattern() {
    return currencyPositivePattern_;
  }

  /**
   */
  @property void currencyNegativePattern(int value) {
    checkReadOnly();
    currencyNegativePattern_ = value;
  }

  /**
   * ditto
   */
  @property int currencyNegativePattern() {
    return currencyNegativePattern_;
  }

  /**
   */
  @property void numberNegativePattern(int value) {
    checkReadOnly();
    numberNegativePattern_ = value;
  }

  /**
   * ditto
   */
  @property int numberNegativePattern() {
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

/**
 * Defines how dates and times are formatted and displayed.
 */
class DateTimeFormat : IFormatProvider {

  private static const string RFC1123_PATTERN = "ddd, dd MMM yyyy HH':'mm':'ss 'GMT'";
  private static const string SORTABLE_DATETIME_PATTERN = "yyyy'-'MM'-'dd'T'HH':'mm':'ss";
  private static const string UNIVERSAL_SORTABLE_DATETIME_PATTERN = "yyyy'-'MM'-'dd HH':'mm':'ss'Z'";

  private static DateTimeFormat constant_;
  private static DateTimeFormat current_;

  private uint cultureId_;
  private Calendar calendar_;
  private bool isDefaultCalendar_;
  private int[] optionalCalendars_;
  private string amDesignator_;
  private string pmDesignator_;
  private string dateSeparator_;
  private string timeSeparator_;
  private int firstDayOfWeek_ = -1;
  private int calendarWeekRule_ = -1;
  private string[] dayNames_;
  private string[] abbrevDayNames_;
  private string[] monthNames_;
  private string[] abbrevMonthNames_;
  private string[] eraNames_;
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

  static ~this() {
    constant_ = null;
    current_ = null;
  }

  /**
   * Initializes a new instance.
   */
  this() {
    cultureId_ = LOCALE_INVARIANT;
    isDefaultCalendar_ = true;
    calendar_ = GregorianCalendar.defaultInstance;

    //initializeProperties();
  }

  /**
   */
  Object getFormat(TypeInfo formatType) {
    if (formatType == typeid(DateTimeFormat))
      return this;
    return null;
  }

  /**
   */
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

  /**
   */
  final string getAbbreviatedDayName(DayOfWeek dayOfWeek) {
    return getAbbreviatedDayNames()[dayOfWeek];
  }

  /**
   */
  final string getDayName(DayOfWeek dayOfWeek) {
    return getDayNames()[dayOfWeek];
  }

  /**
   */
  final string getMonthName(int month) {
    return getMonthNames()[month - 1];
  }

  /**
   */
  final string getAbbreviatedMonthName(int month) {
    return getAbbreviatedMonthNames()[month - 1];
  }

  /**
   */
  final string getEraName(int era) {
    if (era == 0)
      era = Culture.get(cultureId_).calendarData(calendar.internalId).currentEra;

    if (--era >= getEraNames().length)
      throw new ArgumentOutOfRangeException("era");

    return eraNames_[era];
  }

  /**
   */
  final string[] getAllDateTimePatterns() {
    string[] ret;
    foreach (format; allStandardFormats)
      ret ~= getAllDateTimePatterns(format);
    return ret;
  }

  /**
   */
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

  /**
   */
  static @property DateTimeFormat constant() {
    if (constant_ is null) {
      constant_ = new DateTimeFormat;
      constant_.calendar.isReadOnly_ = true;
      constant_.isReadOnly_ = true;
    }
    return constant_;
  }

  /**
   */
  static @property DateTimeFormat current() {
    Culture culture = Culture.current;
    if (auto value = culture.dateTimeFormat_)
      return value;
    return cast(DateTimeFormat)culture.getFormat(typeid(DateTimeFormat));
  }

  /**
   */
  final @property void calendar(Calendar value) {
    if (value !is calendar_) {
      for (auto i = 0; i < optionalCalendars.length; i++) {
        if (optionalCalendars[i] == value.internalId) {
          isDefaultCalendar_ = (value.internalId == CAL_GREGORIAN);

          if (calendar_ !is null) {
            // Clear current values.
            eraNames_ = null;
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
            dateSeparator_ = null;
          }

          calendar_ = value;
          //initializeProperties();

          return;
        }
      }
      throw new ArgumentException("Not a valid calendar for the given culture.", "value");
    }
  }

  /**
   * ditto
   */
  final @property Calendar calendar() {
    return calendar_;
  }

  /**
   */
  final @property void amDesignator(string value) {
    checkReadOnly();
    amDesignator_ = value;
  }

  /**
   * ditto
   */
  final @property string amDesignator() {
    if (amDesignator_ == null)
      amDesignator_ = getLocaleInfo(cultureId_, LOCALE_S1159);
    return amDesignator_;
  }

  /**
   */
  final @property void pmDesignator(string value) {
    checkReadOnly();
    pmDesignator_ = value;
  }

  /**
   * ditto
   */
  final @property string pmDesignator() {
    if (pmDesignator_ == null)
      pmDesignator_ = getLocaleInfo(cultureId_, LOCALE_S2359);
    return pmDesignator_;
  }

  /**
   */
  final @property void dateSeparator(string value) {
    checkReadOnly();
    dateSeparator_ = value;
  }

  /**
   * ditto
   */
  final @property string dateSeparator() {
    if (dateSeparator_ == null)
      dateSeparator_ = getLocaleInfo(cultureId_, LOCALE_SDATE);
    return dateSeparator_;
  }

  /**
   */
  final @property void timeSeparator(string value) {
    checkReadOnly();
    timeSeparator_ = value;
  }

  /**
   * ditto
   */
  final @property string timeSeparator() {
    if (timeSeparator_ == null)
      timeSeparator_ = getLocaleInfo(cultureId_, LOCALE_STIME);
    return timeSeparator_;
  }

  /**
   */
  final @property void firstDayOfWeek(DayOfWeek value) {
    checkReadOnly();
    firstDayOfWeek_ = cast(int)value;
  }
  /**
   * ditto
   */
  final @property DayOfWeek firstDayOfWeek() {
    if (firstDayOfWeek_ == -1) {
      firstDayOfWeek_ = getLocaleInfoI(cultureId_, LOCALE_IFIRSTDAYOFWEEK);
      // 0 = Monday, 1 = Tuesday ... 6 = Sunday
      if (firstDayOfWeek_ < 6)
        firstDayOfWeek_++;
      else
        firstDayOfWeek_ = 0;
    }
    return cast(DayOfWeek)firstDayOfWeek_;
  }

  /**
   */
  final @property void calendarWeekRule(CalendarWeekRule value) {
    checkReadOnly();
    calendarWeekRule_ = cast(int)value;
  }
  /**
   * ditto
   */
  final @property CalendarWeekRule calendarWeekRule() {
    if (calendarWeekRule_ == -1)
      calendarWeekRule_ = getLocaleInfoI(cultureId_, LOCALE_IFIRSTWEEKOFYEAR);
    return cast(CalendarWeekRule)calendarWeekRule_;
  }

  /**
   */
  final @property string rfc1123Pattern() {
    return RFC1123_PATTERN;
  }

  /**
   */
  final @property string sortableDateTimePattern() {
    return SORTABLE_DATETIME_PATTERN;
  }

  /**
   */
  final @property string universalSortableDateTimePattern() {
    return UNIVERSAL_SORTABLE_DATETIME_PATTERN;
  }

  /**
   */
  final @property void shortDatePattern(string value) {
    checkReadOnly();
    shortDatePattern_ = value;
    generalShortTimePattern_ = null;
    generalLongTimePattern_ = null;
  }

  /**
   * ditto
   */
  final @property string shortDatePattern() {
    if (shortDatePattern_ == null)
      shortDatePattern_ = getShortDatePattern(calendar_.internalId);
    return shortDatePattern_;
  }

  /**
   */
  final @property void longDatePattern(string value) {
    checkReadOnly();
    longDatePattern_ = value;
    fullDateTimePattern_ = null;
  }

  /**
   * ditto
   */
  final @property string longDatePattern() {
    if (longDatePattern_ == null)
      longDatePattern_ = getLongDatePattern(calendar_.internalId);
    return longDatePattern_;
  }

  /**
   */
  final @property void shortTimePattern(string value) {
    checkReadOnly();
    shortTimePattern_ = value;
    generalShortTimePattern_ = null;
  }

  /**
   * ditto
   */
  final @property string shortTimePattern() {
    if (shortTimePattern_ == null)
      shortTimePattern_ = getShortTime(cultureId_);
    return shortTimePattern_;
  }

  /**
   */
  final @property void longTimePattern(string value) {
    checkReadOnly();
    longTimePattern_ = value;
    fullDateTimePattern_ = null;
    generalLongTimePattern_ = null;
  }

  /**
   * ditto
   */
  final @property string longTimePattern() {
    if (longTimePattern_ == null)
      longTimePattern_ = getLocaleInfo(cultureId_, LOCALE_STIMEFORMAT);
    return longTimePattern_;
  }

  /**
   */
  final @property void yearMonthPattern(string value) {
    checkReadOnly();
    yearMonthPattern_ = value;
  }

  /**
   * ditto
   */
  final @property string yearMonthPattern() {
    if (yearMonthPattern_ == null)
      yearMonthPattern_ = getLocaleInfo(cultureId_, LOCALE_SYEARMONTH);
    return yearMonthPattern_;
  }

  /**
   */
  final @property string fullDateTimePattern() {
    if (fullDateTimePattern_ == null)
      fullDateTimePattern_ = longDatePattern ~ " " ~ longTimePattern;
    return fullDateTimePattern_;
  }

  package @property string generalShortTimePattern() {
    if (generalShortTimePattern_ == null)
      generalShortTimePattern_ = shortDatePattern ~ " " ~ shortTimePattern;
    return generalShortTimePattern_;
  }

  package @property string generalLongTimePattern() {
    if (generalLongTimePattern_ == null)
      generalLongTimePattern_ = shortDatePattern ~ " " ~ longTimePattern;
    return generalLongTimePattern_;
  }

  /**
   */
  final @property void dayNames(string[] value) {
    checkReadOnly();
    dayNames_ = value;
  }

  /**
   * ditto
   */
  final @property string[] dayNames() {
    return getDayNames().dup;
  }

  /**
   */
  final @property void abbreviatedDayNames(string[] value) {
    checkReadOnly();
    abbrevDayNames_ = value;
  }

  /**
   * ditto
   */
  final @property string[] abbreviatedDayNames() {
    return getAbbreviatedDayNames().dup;
  }

  /**
   */
  final @property void monthNames(string[] value) {
    checkReadOnly();
    monthNames_ = value;
  }

  /**
   * ditto
   */
  final @property string[] monthNames() {
    return getMonthNames().dup;
  }

  /**
   */
  final @property void abbreviatedMonthNames(string[] value) {
    checkReadOnly();
    abbrevMonthNames_ = value;
  }

  final @property string[] abbreviatedMonthNames() {
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

  /*private void initializeProperties() {
    amDesignator_ = getLocaleInfo(cultureId_, LOCALE_S1159);
    pmDesignator_ = getLocaleInfo(cultureId_, LOCALE_S2359);

    firstDayOfWeek_ = getLocaleInfoI(cultureId_, LOCALE_IFIRSTDAYOFWEEK);
    // 0 = Monday, 1 = Tuesday ... 6 = Sunday
    if (firstDayOfWeek_ < 6)
      firstDayOfWeek_++;
    else
      firstDayOfWeek_ = 0;

    calendarWeekRule_ = getLocaleInfoI(cultureId_, LOCALE_IFIRSTWEEKOFYEAR);

    shortDatePattern_ = getShortDatePattern(calendar_.internalId);
    longDatePattern_ = getLongDatePattern(calendar_.internalId);
    longTimePattern_ = getLocaleInfo(cultureId_, LOCALE_STIMEFORMAT);
    yearMonthPattern_ = getLocaleInfo(cultureId_, LOCALE_SYEARMONTH);
  }*/

  private @property string[] allShortDatePatterns() {
    if (allShortDatePatterns_ == null) {
      if (!isDefaultCalendar_)
        allShortDatePatterns_ = [ getShortDatePattern(calendar_.internalId) ];
      if (allShortDatePatterns_ == null)
        allShortDatePatterns_ = getShortDates(cultureId_, calendar_.internalId);
    }
    return allShortDatePatterns_.dup;
  }

  private @property string[] allLongDatePatterns() {
    if (allLongDatePatterns_ == null) {
      if (!isDefaultCalendar_)
        allLongDatePatterns_ = [ getLongDatePattern(calendar_.internalId) ];
      if (allLongDatePatterns_ == null)
        allLongDatePatterns_ = getLongDates(cultureId_, calendar_.internalId);
    }
    return allLongDatePatterns_.dup;
  }

  private @property string[] allShortTimePatterns() {
    if (allShortTimePatterns_ == null)
      allShortTimePatterns_ = getShortTimes(cultureId_);
    return allShortTimePatterns_.dup;
  }

  private @property string[] allLongTimePatterns() {
    if (allLongTimePatterns_ == null)
      allLongTimePatterns_ = getLongTimes(cultureId_);
    return allLongTimePatterns_.dup;
  }

  private @property string[] allYearMonthPatterns() {
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
    int i = s.lastIndexOf(getLocaleInfo(culture, LOCALE_STIME));
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
      int i = s.lastIndexOf(getLocaleInfo(culture, LOCALE_STIME));
      int j = -1;
      if (i != -1)
        j = s.lastIndexOf(' ');
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

  /*private static bool enumCalendarInfo(uint culture, uint calendar, uint calType, out string[] result) {
    static string[] temp;

    extern(Windows)
    static int enumCalendarsProc(wchar* lpCalendarInfoString, uint Calendar) {
      temp ~= toUTF8(lpCalendarInfoString[0 .. wcslen(lpCalendarInfoString)]);
      return 1;
    }

    temp = null;
    if (!EnumCalendarInfoEx(&enumCalendarsProc, culture, calendar, calType))
      return false;
    result = temp.reverse;
    return true;
  }*/

  private string[] getEraNames() {
    if (eraNames_ == null) {
      eraNames_ = Culture.get(cultureId_).calendarData(calendar.internalId).eraNames;
      //enumCalendarInfo(cultureId_, calendar.internalId, CAL_SERASTRING, eraNames_);
    }
    return eraNames_;
  }

  private @property int[] optionalCalendars() {
    if (optionalCalendars_ == null)
      optionalCalendars_ = getOptionalCalendars(cultureId_);
    return optionalCalendars_;
  }

  private static bool enumCalendarInfo(uint culture, uint calendar, uint calType, out int[] result) {
    static int[] temp;

    extern(Windows)
    static int enumCalendarsProc(wchar* lpCalendarInfoString, uint Calendar) {
      temp ~= Calendar;
      return 1;
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

/**
 * Implements methods for culture-sensitive string comparisons.
 */
class Collator {

  private static Collator[uint] cache_;

  private uint cultureId_;
  private uint sortingId_;
  private string name_;

  static ~this() {
    cache_ = null;
  }

  private this(uint culture) {
    cultureId_ = culture;
    sortingId_ = getSortingId(culture);
  }

  private uint getSortingId(uint culture) {
    uint sortId = (culture >> 16) & 0xF;
    return (sortId == 0) ? culture : (culture | (sortId << 16));
  }

  /**
   */
  static Collator get(uint culture) {
    synchronized {
      if (auto value = culture in cache_)
        return *value;

      return cache_[culture] = new Collator(culture);
    }
  }

  /**
   */
  static Collator get(string name) {
    Culture culture = Culture.get(name);
    Collator collator = get(culture.lcid);
    collator.name_ = culture.name;
    return collator;
  }

  /**
   */
  int compare(string string1, int offset1, int length1, string string2, int offset2, int length2, CompareOptions options = CompareOptions.None) {
    if (string1 == null) {
      if (string2 == null)
        return 0;
      return -1;
    }
    if (string2 == null)
      return 1;

    //if ((options & CompareOptions.Ordinal) != 0 || (options & CompareOptions.OrdinalIgnoreCase) != 0)
    //  return compareStringOrdinal(string1, offset1, length1, string2, offset2, length2, (options & CompareOptions.OrdinalIgnoreCase) != 0);

    return compareString(sortingId_, string1, offset1, length1, string2, offset2, length2, getCompareFlags(options));
  }

  /// ditto
  int compare(string string1, int offset1, string string2, int offset2, CompareOptions options = CompareOptions.None) {
    return compare(string1, offset1, string1.length - offset1, string2, offset2, string2.length - offset2, options);
  }

  /// ditto
  int compare(string string1, string string2, CompareOptions options = CompareOptions.None) {
    if (string1 == null) {
      if (string2 == null)
        return 0;
      return -1;
    }
    if (string2 == null)
      return 1;

    //if ((options & CompareOptions.Ordinal) != 0 || (options & CompareOptions.OrdinalIgnoreCase) != 0)
    //  return compareStringOrdinal(string1, 0, string1.length, string2, 0, string2.length, (options & CompareOptions.OrdinalIgnoreCase) != 0);

    return compareString(sortingId_, string1, 0, string1.length, string2, 0, string2.length, getCompareFlags(options));
  }

  /**
   */
  int indexOf(string source, string value, int index, int count, CompareOptions options = CompareOptions.None) {
    uint flags = getCompareFlags(options);

    int n = findString(sortingId_, flags | FIND_FROMSTART, source, index, count, value, value.length);
    if (n > -1)
      return n + index;
    if (n == -1)
      return n;

    for (uint i = 0; i < count; i++) {
      if (isPrefix(source, index + i, count - i, value, flags))
        return index + i;
    }
    return -1;
  }

  /// ditto
  int indexOf(string source, string value, int index, CompareOptions options = CompareOptions.None) {
    return indexOf(source, value, index, source.length - index, options);
  }

  /// ditto
  int indexOf(string source, string value, CompareOptions options = CompareOptions.None) {
    return indexOf(source, value, 0, source.length, options);
  }

  /**
   */
  int lastIndexOf(string source, string value, int index, int count, CompareOptions options = CompareOptions.None) {
    if (source.length == 0 && (index == -1 || index == 0)) {
      if (value.length != 0)
        return -1;
      return 0;
    }

    if (index == source.length) {
      index++;
      if (count > 0)
        count--;
      if (value.length == 0 && count >= 0 && (index - count) + 1 >= 0)
        return index;
    }

    uint flags = getCompareFlags(options);

    int n = findString(sortingId_, flags | FIND_FROMEND, source, (index - count) + 1, count, value, value.length);
    if (n > -1)
      return n + (index - count) + 1;
    if (n == -1)
      return n;

    for (uint i = 0; i < count; i++) {
      if (isSuffix(source, index - i, count - i, value, flags))
        return i + (index - count) + 1;
    }
    return -1;
  }

  /// ditto
  int lastIndexOf(string source, string value, int index, CompareOptions options = CompareOptions.None) {
    return lastIndexOf(source, value, index, index + 1, options);
  }

  /// ditto
  int lastIndexOf(string source, string value, CompareOptions options = CompareOptions.None) {
    return lastIndexOf(source, value, source.length - 1, source.length, options);
  }

  /**
   */
  bool isPrefix(string source, string prefix, CompareOptions options = CompareOptions.None) {
    if (prefix.length == 0)
      return true;
    return isPrefix(source, 0, source.length, prefix, getCompareFlags(options));
  }

  /**
   */
  bool isSuffix(string source, string suffix, CompareOptions options = CompareOptions.None) {
    if (suffix.length == 0)
      return true;
    return isSuffix(source, source.length - 1, source.length, suffix, getCompareFlags(options));
  }

  /**
   */
  char toLower(char c) {
    return changeCaseChar(cultureId_, c, false);
  }

  /**
   */
  string toLower(string str) {
    return changeCaseString(cultureId_, str, false);
  }

  /**
   */
  char toUpper(char c) {
    return changeCaseChar(cultureId_, c, true);
  }

  /**
   */
  string toUpper(string str) {
    return changeCaseString(cultureId_, str, true);
  }

  /**
   */
  uint lcid() {
    return cultureId_;
  }

  /**
   */
  string name() {
    if (name_ == null)
      name_ = Culture.get(cultureId_).name;
    return name_;
  }

  private static uint getCompareFlags(CompareOptions options) {
    uint flags;
    if ((options & CompareOptions.IgnoreCase) != 0)
      flags |= NORM_IGNORECASE;
    if ((options & CompareOptions.IgnoreNonSpace) != 0)
      flags |= NORM_IGNORENONSPACE;
    if ((options & CompareOptions.IgnoreSymbols) != 0)
      flags |= NORM_IGNORESYMBOLS;
    if ((options & CompareOptions.IgnoreWidth) != 0)
      flags |= NORM_IGNOREWIDTH;
    return flags;
  }

  private static int compareString(uint lcid, string string1, int offset1, int length1, string string2, int offset2, int length2, uint flags) {
    int cch1, cch2;
    wchar* lpString1 = toUTF16zNls(string1, offset1, length1, cch1);
    wchar* lpString2 = toUTF16zNls(string2, offset2, length2, cch2);
    return CompareString(lcid, flags, lpString1, cch1, lpString2, cch2) - 2;
  }

  private static int compareStringOrdinal(string string1, int offset1, int length1, string string2, int offset2, int length2, bool ignoreCase) {
    int count = (length2 < length1)
      ? length2
      : length1;
    int ret = ignoreCase
      ? memicmp(string1.ptr + offset1, string2.ptr + offset2, count)
      : memcmp(string1.ptr + offset1, string2.ptr + offset2, count);
    if (ret == 0)
      ret = length1 - length2;
    return ret;
  }

  private bool isPrefix(string source, int start, int length, string prefix, uint flags) {
    // Call FindNLSString if the API is present on the system, otherwise call CompareString.
    int i = findString(sortingId_, 0, source, start, length, prefix, prefix.length);
    if (i >= -1)
      return (i != -1);

    for (i = 1; i <= length; i++) {
      if (compareString(sortingId_, prefix, 0, prefix.length, source, start, i, flags) == 0)
        return true;
    }
    return false;
  }

  private bool isSuffix(string source, int end, int length, string suffix, uint flags) {
    // Call FindNLSString if the API is present on the system, otherwise call CompareString.
    int i = findString(sortingId_, flags | FIND_ENDSWITH, source, 0, length, suffix, suffix.length);
    if (i >= -1)
      return (i != -1);

    for (i = 0; i < length; i++) {
      if (compareString(sortingId_, suffix, 0, suffix.length, source, end - i, i + 1, flags))
        return true;
    }
    return false;
  }

  private static char changeCaseChar(uint lcid, char ch, bool upperCase) {
    wchar wch;
    MultiByteToWideChar(CP_UTF8, 0, &ch, 1, &wch, 1);
    LCMapString(lcid, (upperCase ? LCMAP_UPPERCASE : LCMAP_LOWERCASE) | LCMAP_LINGUISTIC_CASING, &wch, 1, &wch, 1);
    WideCharToMultiByte(CP_UTF8, 0, &wch, 1, &ch, 1, null, null);
    return ch;
  }

  private static string changeCaseString(uint lcid, string string, bool upperCase) {
    int cch, cb;
    wchar* pChars = toUTF16zNls(string, 0, string.length, cch);
    LCMapString(lcid, (upperCase ? LCMAP_UPPERCASE : LCMAP_LOWERCASE) | LCMAP_LINGUISTIC_CASING, pChars, cch, pChars, cch);
    return toUTF8Nls(pChars, cch, cb);
  }

  private static int findString(uint lcid, uint flags, string source, int start, int sourceLen, string value, int valueLen) {
    // Return value:
    // -2 FindNLSString unavailable
    // -1 function failed
    //  0-based index if successful

    int result = -1;

    int cchSource, cchValue;
    wchar* lpSource = toUTF16zNls(source, 0, sourceLen, cchSource);
    wchar* lpValue = toUTF16zNls(value, 0, valueLen, cchValue);

    try {
      result = FindNLSString(lcid, flags, lpSource + start, cchSource, lpValue, cchValue, null);
    }
    catch (EntryPointNotFoundException) {
      result = -2;
    }
    return result;
  }

}

/**
 * Contains information about the country/region.
 */
class Region {

  private static Region current_;

  private uint cultureId_;
  private string name_;

  static ~this() {
    current_ = null;
  }

  /**
   */
  this(uint culture) {
    if (culture == LOCALE_INVARIANT)
      throw new ArgumentException("There is no region associated with the invariant culture (Culture ID: 0x7F).");

    if (SUBLANGID(cast(ushort)culture) == 0) {
      scope buffer = new char[100];
      int len = sprintf(buffer.ptr, "Culture ID %d (0x%04X) is a neutral culture; a region cannot be created from it.", culture, culture);
      throw new ArgumentException(cast(string)buffer[0 .. len], "culture");
    }

    cultureId_ = culture;
    name_ = getLocaleInfo(culture, LOCALE_SISO3166CTRYNAME);
  }

  /**
   */
  this(string name) {
    name_ = name.toUpper();

    if (!findCultureFromRegionName(name, cultureId_))
      throw new ArgumentException("Region name '" ~ name ~ "' is not supported.", "name");

    if (isNeutralCulture(cultureId_))
      throw new ArgumentException("Region name '" ~ name ~ "' should not correspond to a neutral culture; a specific culture name is required.", "name");
  }

  override string toString() {
    return name;
  }

  /**
   */
  static @property Region current() {
    if (current_ is null)
      current_ = new Region(Culture.current.lcid);
    return current_;
  }

  /**
   */
  @property int geoId() {
    return getLocaleInfoI(cultureId_, LOCALE_IGEOID);
  }

  /**
   */
  @property string name() {
    if (name_ == null)
      name_ = getLocaleInfo(cultureId_, LOCALE_SISO3166CTRYNAME);
    return name_;
  }

  /**
   */
  @property string nativeName() {
    return getLocaleInfo(cultureId_, LOCALE_SNATIVECTRYNAME);
  }

  /**
   */
  @property string displayName() {
    return getLocaleInfo(cultureId_, LOCALE_SCOUNTRY);
  }

  /**
   */
  @property string englishName() {
    return getLocaleInfo(cultureId_, LOCALE_SENGCOUNTRY);
  }

  /**
   */
  @property string isoRegionName() {
    return getGeoInfo(geoId, GEO_ISO2);
  }

  /**
   */
  @property bool isMetric() {
    return getLocaleInfoI(cultureId_, LOCALE_IMEASURE) == 0;
  }

  /**
   */
  @property string currencySymbol() {
    return getLocaleInfo(cultureId_, LOCALE_SCURRENCY);
  }

  /**
   */
  @property string isoCurrencySymbol() {
    return getLocaleInfo(cultureId_, LOCALE_SINTLSYMBOL);
  }

  /**
   */
  @property string currencyNativeName() {
    return getLocaleInfo(cultureId_, LOCALE_SNATIVECURRNAME);
  }

  /**
   */
  @property string currencyEnglishName() {
    return getLocaleInfo(cultureId_, LOCALE_SENGCURRNAME);
  }

  /**
   */
  @property double latitude() {
    return std.conv.to!(double)(getGeoInfo(geoId, GEO_LATITUDE));
  }

  /**
   */
  @property double longitude() {
    return std.conv.to!(double)(getGeoInfo(geoId, GEO_LONGITUDE));
  }

}
