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

/**
 * Contains classes that define culture-related information, including language, region, calendars and format patterns for dates, currency and numbers.
 */
module juno.locale.core;

private import juno.base.core,
  juno.base.native,
  juno.locale.constants;

private import juno.base.string : wcslen, toUtf8;
private import juno.locale.format : formatDateTime, parseDouble, parseDateTime, parseDateTimeExact;

private import std.utf : toUTF8;
private import std.string : icmp, find, rfind;
private import std.c.stdio : swscanf, sprintf;
private import std.c.string : memcpy;

private string getLocaleInfo(uint locale, uint field, bool userOverride = true) {
  wchar[80] buffer;
  int cch = GetLocaleInfo(locale, field | (!userOverride ? LOCALE_NOUSEROVERRIDE : 0), buffer.ptr, buffer.length);
  if (cch == 0) return null;
  return toUTF8(buffer[0 .. cch - 1]);
}

private int getLocaleInfoI(uint locale, uint field, bool userOverride = true) {
  int result;
  GetLocaleInfo(locale, field | LOCALE_RETURN_NUMBER | (!userOverride ? LOCALE_NOUSEROVERRIDE : 0), cast(wchar*)&result, int.sizeof);
  return result;
}

private string getCalendarInfo(uint locale, uint calendar, uint calType, bool userOverride = true) {
  wchar[80] buffer;
  int cch = GetCalendarInfo(locale, calendar, calType | (!userOverride ? CAL_NOUSEROVERRIDE : 0), buffer.ptr, buffer.length, null);
  if (cch == 0) return null;
  return toUTF8(buffer[0 .. cch - 1]);
}

private string getGeoInfo(int geoId, uint geoType) {
  int cch = GetGeoInfo(geoId, geoType, null, 0, 0);
  wchar[] buffer = new wchar[cch];
  cch = GetGeoInfo(geoId, geoType, buffer.ptr, buffer.length, 0);
  if (cch == 0) return null;
  return toUTF8(buffer[0 .. cch - 1]);
}

private uint[string] nameToLcidMap;
private string[uint] lcidToNameMap;
private uint[string] regionNameToLcidMap;

static ~this() {
  nameToLcidMap = null;
  lcidToNameMap = null;
  regionNameToLcidMap = null;
}

private void initNameMapping() {

  bool enumSystemLocales(out uint[] locales) {
    static uint[uint] temp;

    extern (Windows)
    static int enumLocalesProc(wchar* lpLocaleString) {
      uint locale;
      if (swscanf(lpLocaleString, "%x", &locale) > 0) {
        if (!(locale in temp)) {
          temp[locale] = locale;

          // Also add neutral locales.
          uint lang = locale & 0x3ff;
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
    string name = null;

    /*try {
      wchar[80] buffer;
      int cch = LCIDToLocaleName(locale, buffer.ptr, buffer.length, 0);
      if (cch != 0)
        return toUTF8(buffer[0 .. cch - 1]);
    }
    catch (DllNotFoundException) {
    }
    catch (EntryPointNotFoundException) {
    }

    try {
      wchar[80] buffer;
      int cch = DownlevelLCIDToLocaleName(locale, buffer.ptr, buffer.length, 0);
      if (cch != 0)
        return toUTF8(buffer[0 .. cch - 1]);
    }
    catch (DllNotFoundException) {
    }
    catch (EntryPointNotFoundException) {
    }*/

    if (name == null) {
      // Construct a locale name. Tries to be compatible with Vista/RFC 4646.
      string language, script, country;

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

      if ((locale & 0x3ff) != locale) {
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
        name ~= "-" ~ script;
      if (country != null)
        name ~= "-" ~ country;
    }

    return name;
  }

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

private void initRegionMapping() {

  bool enumSystemLocales(out uint[] locales) {
    static uint[uint] temp;

    extern (Windows)
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

private bool findCultureByName(string cultureName, out string actualName, out uint culture) {
  if (lcidToNameMap == null)
    initNameMapping();

  foreach (name, lcid; nameToLcidMap) {
    if (icmp(cultureName, name) == 0) {
      actualName = name;
      culture = lcid;
      return true;
    }
  }

  return false;
}

private bool findCultureById(uint culture, out string cultureName, out uint actualCulture) {
  if (culture != LOCALE_INVARIANT) {
    if (lcidToNameMap == null)
      initNameMapping();

    if (auto value = culture in lcidToNameMap)
      return findCultureByName(*value, cultureName, actualCulture);

    return false;
  }

  return findCultureByName("", cultureName, actualCulture);
}

private bool findCultureFromRegionName(string regionName, out uint culture) {
  if (regionNameToLcidMap == null)
    initRegionMapping();

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
  return (culture != LOCALE_INVARIANT) && ((culture & 0x3ff) == culture);
}

/**
 * Retrieves an object that controls formatting.
 */
public interface IFormatProvider {
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
public class Culture : IFormatProvider {

  private static Culture[string] nameCultures_;
  private static Culture[uint] lcidCultures_;

  private static Culture constant_;
  private static Culture current_;
  private static Culture currentUI_;
  private static Culture userDefault_;
  private static Culture userDefaultUI_;

  private uint cultureId_;
  private string cultureName_;

  private bool isReadOnly_;
  private bool isInherited_;
  private Culture parent_;
  private Calendar calendar_;
  private NumberFormat numberFormat_;
  private DateTimeFormat dateTimeFormat_;
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
  public this(uint culture) {
    if ((culture == LOCALE_NEUTRAL
      || culture == LOCALE_SYSTEM_DEFAULT
      || culture == LOCALE_USER_DEFAULT)
      || !findCultureById(culture, cultureName_, cultureId_)) {
      char[100] buffer;
      int len = sprintf(buffer.ptr, "Culture ID %d (0x%04x) is not a supported culture.", culture, culture);
      throw new ArgumentException(buffer[0 .. len].dup, "culture");
    }

    isInherited_ = this.classinfo != Culture.classinfo;
  }

  /**
   * Initializes a new instance based on the culture specified by name.
   * Params: name = A predefined culture _name.
   */
  public this(string name) {
    if (!findCultureByName(name, cultureName_, cultureId_))
      throw new ArgumentException("Culture name '" ~ name ~ "' not supported.", "name");

    isInherited_ = this.classinfo != Culture.classinfo;
  }

  /**
   * Returns a string containing the name of the current instance.
   * Returns: A string containing the name of the current instance.
   */
  public override string toString() {
    return cultureName_;
  }

  /**
   * Gets an object that defines how to format the specified type.
   * Params: formatType = The type to get a formatting object for. Supports NumberFormat and DateTimeFormat.
   * Returns: The value of the numberFormat property or the value of the dateTimeFormat property, depending on formatType.
   */
  public Object getFormat(TypeInfo formatType) {
    if (formatType == typeid(NumberFormat))
      return numberFormat;
    if (formatType == typeid(DateTimeFormat))
      return dateTimeFormat;
    return null;
  }

  /**
   * Retrieves a cached, read-only instance of a _culture using the specified _culture identifier.
   * Params: culture = A _culture identifier.
   * Returns: A read-only Culture object.
   */
  public static Culture get(uint culture) {
    Culture ret = getCultureWorker(culture, null);

    if (ret is null) {
      char[100] buffer;
      int len = sprintf(buffer.ptr, "Culture ID %d (0x%04X) is not a supported culture.", culture, culture);
      throw new ArgumentException(buffer[0 .. len].dup, "culture");
    }

    return ret;
  }

  /**
   * Retrieves a cached, read-only instance of a culture using the specified culture _name.
   * Params: name = The _name of the culture.
   * Returns: A read-only Culture object.
   */
  public static Culture get(string name) {
    Culture ret = getCultureWorker(0, name);

    if (ret is null)
      throw new ArgumentException("Culture name '" ~ name ~ "' not supported.", "name");

    return ret;
  }

  private static Culture getCultureWorker(uint lcid, string name) {

    string toLower(string s) {
      foreach (ref c; s) {
        if (c <= 'Z' && c >= 'A')
          c = c - 'A' + 'a';
      }
      return s;
    }

    if (name != null)
      name = toLower(name);

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
  public static Culture[] getCultures(CultureTypes types) {
    bool includeSpecific = (types & CultureTypes.Specific) != 0;
    bool includeNeutral = (types & CultureTypes.Neutral) != 0;

    Culture[] list;

    if (includeNeutral || includeSpecific) {
      if (lcidToNameMap == null)
        initNameMapping();

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
   * Gets the culture identifier of the current instance.
   * Returns: The culture identifier.
   */
  public uint lcid() {
    return cultureId_;
  }

  /**
   * Gets the culture _name in the format "&lt;language&gt;-&lt;region&gt;".
   * Returns: The culture _name.
   */
  public string name() {
    return cultureName_;
  }

  /**
   * Gets the culture name in the format "&lt;language&gt; (&lt;region&gt;)" in the language of the culture.
   * Returns: The culture name in the language of the culture.
   */
  public string nativeName() {
    string s = getLocaleInfo(cultureId_, LOCALE_SNATIVELANGNAME);
    if (!isNeutral)
      s ~= " (" ~ getLocaleInfo(cultureId_, LOCALE_SNATIVECTRYNAME) ~ ")";
    else {
      int i = s.rfind("(");
      if (i != -1 && s.rfind(")") != -1)
        s.length = i - 1;
    }
    return s;
  }

  /**
   * Gets the culture name in the format "&lt;language&gt; (&lt;region&gt;)" in English.
   * Returns: The culture name in English.
   */
  public string englishName() {
    string s = getLocaleInfo(cultureId_, LOCALE_SENGLANGUAGE);
    if (!isNeutral)
      s ~= " (" ~ getLocaleInfo(cultureId_, LOCALE_SENGCOUNTRY) ~ ")";
    else {
      int i = s.rfind("(");
      if (i != -1 && s.rfind(")") != -1)
        s.length = i - 1;
    }
    return s;
  }

  /**
   * Gets the culture name in the format "&lt;language&gt; (&lt;region&gt;)" in the localised version of Windows.
   * Returns: The culture name in the localised version of Windows.
   */
  public string displayName() {
    string s = getLocaleInfo(cultureId_, LOCALE_SLANGUAGE);
    if (s != null && isNeutral && cultureId_ != LOCALE_INVARIANT) {
      // Remove country from neutral cultures.
      int i = s.rfind("(");
      if (i != -1 && s.rfind(")") != -1)
        s.length = i - 1;
    }

    if (s != null && !isNeutral && cultureId_ != LOCALE_INVARIANT) {
      // Add country to specific cultures.
      if (s.find("(") == -1 && s.find(")") == -1)
        s ~= " (" ~ getLocaleInfo(cultureId_, LOCALE_SCOUNTRY) ~ ")";
    }

    if (s != null)
      return s;
    return nativeName;
  }

  /**
   * Gets the culture _types that pertain to the current instance.
   * Returns: A bitwise combination of CultureTypes values.
   */
  public CultureTypes types() {
    CultureTypes ret = cast(CultureTypes)0;
    if (isNeutral)
      ret |= CultureTypes.Neutral;
    else
      ret |= CultureTypes.Specific;
    return ret;
  }

  /**
   * Gets the Culture that represents the _parent culture of the current instance.
   * Returns: The Culture that represents the _parent culture.
   */
  public Culture parent() {
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

  public static Culture constant() {
    return constant_;
  }

  /**
   * Gets or sets the Culture that represents the culture used by the _current thread.
   * Returns: The Culture that represents the culture used by the _current thread.
   */
  public static void current(Culture value) {
    if (value is null)
      throw new ArgumentNullException("value");

    checkNeutral(value);
    SetThreadLocale(value.lcid);
    current_ = value;
  }

  /** 
   * Ditto
   */
  public static Culture current() {
    if (current_ !is null)
      return current_;

    return userDefault;
  }

  /**
   * Gets or sets the Culture that represents the current culture used to look up resources.
   * Returns: The Culture that represents the current culture used to look up resources.
   */
  public static void currentUI(Culture value) {
    if (value is null)
      throw new ArgumentNullException("value");

    currentUI_ = value;
  }

  /** 
   * Ditto
   */
  public static Culture currentUI() {
    if (currentUI_ !is null)
      return currentUI_;

    return userDefaultUI;
  }

  /**
   * Gets the default _calendar used by the culture.
   * Returns: A Calendar that represents the default _calendar used by the culture.
   */
  public Calendar calendar() {
    if (calendar_ is null) {
      calendar_ = getCalendar(getLocaleInfoI(cultureId_, LOCALE_ICALENDARTYPE));
      calendar_.isReadOnly_ = isReadOnly_;
    }
    return calendar_;
  }

  /**
   * Gets or sets the NumberFormat that defines the culturally appropriate format for displaying numbers and currency.
   * Returns: The NumberFormat that defines the culturally appropriate format for displaying numbers and currency.
   * Throws: ArgumentNullException if the property is set to null.
   */
  public void numberFormat(NumberFormat value) {
    if (value is null)
      throw new ArgumentNullException("value");

    numberFormat_ = value;
  }

  /**
   * Ditto
   */
  public NumberFormat numberFormat() {
    if (numberFormat_ is null) {
      checkNeutral(this);
      numberFormat_ = new NumberFormat(cultureId_);
      numberFormat_.isReadOnly_ = isReadOnly_;
    }
    return numberFormat_;
  }

  /**
   * Gets or sets the DateTimeFormat that defines the culturally appropriate format for displaying dates and times.
   * Returns: The DateTimeFormat that defines the culturally appropriate format for displaying dates and times.
   * Throws: ArgumentNullException if the property is set to null.
   */
  public void dateTimeFormat(DateTimeFormat value) {
    if (value is null)
      throw new ArgumentNullException("value");

    dateTimeFormat_ = value;
  }

  /**
   * Ditto
   */
  public DateTimeFormat dateTimeFormat() {
    if (dateTimeFormat_ is null) {
      checkNeutral(this);
      dateTimeFormat_ = new DateTimeFormat(cultureId_, calendar);
      dateTimeFormat_.isReadOnly_ = isReadOnly_;
    }
    return dateTimeFormat_;
  }

  public Collator collator() {
    if (collator_ is null)
      collator_ = Collator.get(cultureId_);
    return collator_;
  }

  public bool isNeutral() {
    return isNeutralCulture(cultureId_);
  }

  private static Calendar getCalendar(int cal) {
    switch (cal) {
      case CAL_GREGORIAN:
        return new GregorianCalendar(cast(GregorianCalendarType)cal);
      case CAL_UMALQURA:
        return new UmAlQuraCalendar;
      default:
    }
    return new GregorianCalendar;
  }

  private static void checkNeutral(Culture culture) {
    if (culture.isNeutral)
      throw new NotSupportedException("Culture '" ~ culture.name ~ "' is a neutral culture and cannot be used in formatting.");
  }

  private void checkReadOnly() {
    if (isReadOnly_)
      throw new InvalidOperationException("Instance is read-only.");
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
      culture = new Culture(lcid);
    }
    catch (ArgumentException) {
      try {
        culture = new Culture(GetSystemDefaultLangID());
      }
      catch (ArgumentException) {
      }
    }

    if (culture is null)
      return Culture.constant;

    culture.isReadOnly_ = true;
    return culture;
  }

  private static Culture userDefault() {
    if (userDefault_ is null)
      userDefault_ = initUserDefault();
    return userDefault_;
  }

  private static Culture userDefaultUI() {
    if (userDefaultUI_ is null)
      userDefaultUI_ = initUserDefaultUI();
    return userDefaultUI_;
  }

}

public class Region {

  private static Region current_;

  private uint cultureId_;
  private string name_;

  static ~this() {
    current_ = null;
  }

  public this(uint culture) {
    if (culture == LOCALE_INVARIANT)
      throw new ArgumentException("There is no region associated with the invariant culture (Culture ID: 0x7F).");

    if (SUBLANGID(culture) == 0) {
      char[100] buffer;
      int len = sprintf(buffer.ptr, "Culture ID %d (0x%04X) is a neutral culture; a region cannot be created from it.", culture, culture);
      throw new ArgumentException(buffer[0 .. len].dup, "culture");
    }

    cultureId_ = culture;
    name_ = getLocaleInfo(culture, LOCALE_SISO3166CTRYNAME);
  }

  public this(string name) {
    name_ = Culture.constant.collator.toUpper(name);

    if (!findCultureFromRegionName(name, cultureId_))
      throw new ArgumentException("Region name '" ~ name ~ "' is not supported.", "name");

    if (isNeutralCulture(cultureId_))
      throw new ArgumentException("Region name '" ~ name ~ "' should not correspond to a neutral culture; a specific culture name is required.", "name");
  }

  public override string toString() {
    return name;
  }

  public static Region current() {
    if (current_ is null)
      current_ = new Region(Culture.current.lcid);
    return current_;
  }

  public int geoId() {
    return getLocaleInfoI(cultureId_, LOCALE_IGEOID);
  }

  public string name() {
    if (name_ == null)
      name_ = getLocaleInfo(cultureId_, LOCALE_SISO3166CTRYNAME);
    return name_;
  }

  public string nativeName() {
    return getLocaleInfo(cultureId_, LOCALE_SNATIVECTRYNAME);
  }

  public string displayName() {
    return getLocaleInfo(cultureId_, LOCALE_SCOUNTRY);
  }

  public string englishName() {
    return getLocaleInfo(cultureId_, LOCALE_SENGCOUNTRY);
  }

  public string officialName() {
    return getGeoInfo(geoId, GEO_OFFICIALNAME);
  }

  public string isoRegionName() {
    return getGeoInfo(geoId, GEO_ISO2);
  }

  public bool isMetric() {
    return getLocaleInfoI(cultureId_, LOCALE_IMEASURE) == 0;
  }

  public string currencySymbol() {
    return getLocaleInfo(cultureId_, LOCALE_SCURRENCY);
  }

  public string isoCurrencySymbol() {
    return getLocaleInfo(cultureId_, LOCALE_SINTLSYMBOL);
  }

  public string currencyNativeName() {
    return getLocaleInfo(cultureId_, LOCALE_SNATIVECURRNAME);
  }

  public string currencyEnglishName() {
    return getLocaleInfo(cultureId_, LOCALE_SENGCURRNAME);
  }

  public double latitude() {
    string s = getGeoInfo(geoId, GEO_LATITUDE);
    return parseDouble(s, NumberStyles.Float, NumberFormat.current);
  }

  public double longitude() {
    string s = getGeoInfo(geoId, GEO_LONGITUDE);
    return parseDouble(s, NumberStyles.Float, NumberFormat.current);
  }

}

private wchar* toUtf16Nls(string chars, int offset, int length, out int translated) {
  translated = 0;
  char* pChars = chars.ptr + offset;
  int cch = MultiByteToWideChar(CP_UTF8, 0, pChars, length, null, 0);
  if (cch == 0)
    return null;
  wchar[] result = new wchar[cch];
  translated = MultiByteToWideChar(CP_UTF8, 0, pChars, length, result.ptr, cch);
  return result.ptr;
}

private string toUtf8Nls(wchar* pChars, int cch, out int translated) {
  int cb = WideCharToMultiByte(CP_UTF8, 0, pChars, cch, null, 0, null, null);
  if (cb == 0)
    return null;
  char[] result = new char[cb];
  translated = WideCharToMultiByte(CP_UTF8, 0, pChars, cch, result.ptr, cb, null, null);
  return result.dup;
}

public class Collator {

  private static Collator[uint] cache_;

  private uint cultureId_;
  private uint sortingId_;
  private string name_;

  static ~this() {
    cache_ = null;
  }

  public static Collator get(uint culture) {
    synchronized {
      if (auto value = culture in cache_)
        return *value;

      return cache_[culture] = new Collator(culture);
    }
  }

  public static Collator get(string name) {
    Culture culture = Culture.get(name);
    Collator collator = get(culture.lcid);
    collator.name_ = culture.name;
    return collator;
  }

  public int compare(string string1, int offset1, int length1, string string2, int offset2, int length2, CompareOptions options = CompareOptions.None) {
    if (string1 == null) {
      if (string2 == null)
        return 0;
      return -1;
    }
    if (string2 == null)
      return 1;

    return compareString(sortingId_, string1, offset1, length1, string2, offset2, length2, getCompareFlags(options));
  }

  public int compare(string string1, int offset1, string string2, int offset2, CompareOptions options = CompareOptions.None) {
    return compare(string1, offset1, string1.length - offset1, string2, offset2, string2.length - offset2, options);
  }

  public int compare(string string1, string string2, CompareOptions options = CompareOptions.None) {
    if (string1 == null) {
      if (string2 == null)
        return 0;
      return -1;
    }
    if (string2 == null)
      return 1;

    return compareString(sortingId_, string1, 0, string1.length, string2, 0, string2.length, getCompareFlags(options));
  }

  public int indexOf(string source, string value, int index, int count, CompareOptions options = CompareOptions.None) {
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

  public int indexOf(string source, string value, int index, CompareOptions options = CompareOptions.None) {
    return indexOf(source, value, index, source.length - index, options);
  }

  public int indexOf(string source, string value, CompareOptions options = CompareOptions.None) {
    return indexOf(source, value, 0, source.length, options);
  }

  public int lastIndexOf(string source, string value, int index, int count, CompareOptions options = CompareOptions.None) {
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

  public int lastIndexOf(string source, string value, int index, CompareOptions options = CompareOptions.None) {
    return lastIndexOf(source, value, index, index + 1, options);
  }

  public int lastIndexOf(string source, string value, CompareOptions options = CompareOptions.None) {
    return lastIndexOf(source, value, source.length - 1, source.length, options);
  }

  public bool isPrefix(string source, string prefix, CompareOptions options = CompareOptions.None) {
    if (prefix.length == 0)
      return true;
    return isPrefix(source, 0, source.length, prefix, getCompareFlags(options));
  }

  public bool isSuffix(string source, string suffix, CompareOptions options = CompareOptions.None) {
    if (suffix.length == 0)
      return true;
    return isSuffix(source, source.length - 1, source.length, suffix, getCompareFlags(options));
  }

  public char toLower(char c) {
    return changeCaseChar(cultureId_, c, false);
  }

  public string toLower(string str) {
    return changeCaseString(cultureId_, str, false);
  }

  public char toUpper(char c) {
    return changeCaseChar(cultureId_, c, true);
  }

  public string toUpper(string str) {
    return changeCaseString(cultureId_, str, true);
  }

  public uint lcid() {
    return cultureId_;
  }

  public string name() {
    if (name_ == null)
      name_ = Culture.get(cultureId_).name;
    return name_;
  }

  private this(uint culture) {
    cultureId_ = culture;
    sortingId_ = getSortingId(culture);
  }

  private uint getSortingId(uint culture) {
    uint sortId = (culture >> 16) & 0xf;
    return (sortId == 0) ? culture : (culture | (sortId << 16));
  }

  private static uint getCompareFlags(CompareOptions options) {
    uint flags;
    if (options & CompareOptions.IgnoreCase)
      flags |= NORM_IGNORECASE;
    if (options & CompareOptions.IgnoreNonSpace)
      flags |= NORM_IGNORENONSPACE;
    if (options & CompareOptions.IgnoreSymbols)
      flags |= NORM_IGNORESYMBOLS;
    if (options & CompareOptions.IgnoreKanaType)
      flags |= NORM_IGNOREKANATYPE;
    if (options & CompareOptions.IgnoreWidth)
      flags |= NORM_IGNOREWIDTH;
    if (options & CompareOptions.StringSort)
      flags |= SORT_STRINGSORT;
    return flags;
  }

  private static int compareString(uint lcid, string string1, int offset1, int length1, string string2, int offset2, int length2, uint flags) {
    int cchCount1, cchCount2;
    wchar* lpString1 = toUtf16Nls(string1, offset1, length1, cchCount1);
    wchar* lpString2 = toUtf16Nls(string2, offset2, length2, cchCount2);
    return CompareString(lcid, flags, lpString1, cchCount1, lpString2, cchCount2) - 2;
  }

  private static char changeCaseChar(uint lcid, char c, bool upperCase) {
    wchar wch;
    MultiByteToWideChar(CP_UTF8, 0, &c, 1, &wch, 1);
    LCMapString(lcid, (upperCase ? LCMAP_UPPERCASE : LCMAP_LOWERCASE) | LCMAP_LINGUISTIC_CASING, &wch, 1, &wch, 1);
    char ch;
    WideCharToMultiByte(CP_UTF8, 0, &wch, 1, &ch, 1, null, null);
    return ch;
  }

  private static string changeCaseString(uint lcid, string string, bool upperCase) {
    int cch, cb;
    wchar* pChars = toUtf16Nls(string, 0, string.length, cch);
    LCMapString(lcid, (upperCase ? LCMAP_UPPERCASE : LCMAP_LOWERCASE) | LCMAP_LINGUISTIC_CASING, pChars, cch, pChars, cch);
    return toUtf8Nls(pChars, cch, cb);
  }

  private static int findString(uint lcid, uint flags, string source, int start, int sourceLen, string value, int valueLen) {
    int result = -1;

    int cchSource, cchValue;
    wchar* lpSource = toUtf16Nls(source, 0, sourceLen, cchSource);
    wchar* lpValue = toUtf16Nls(value, 0, valueLen, cchValue);

    try {
      result = FindNLSString(lcid, flags, lpSource + start, cchSource, lpValue, cchValue, null);
    }
    catch (EntryPointNotFoundException) {
      result = -2;
    }
    return result;
  }

  private bool isPrefix(string source, int start, int length, string prefix, uint flags) {
    for (int i = 1; i <= length; i++) {
      if (compareString(sortingId_, prefix, 0, prefix.length, source, start, i, flags) == 0)
        return true;
    }
    return false;
  }

  private bool isSuffix(string source, int end, int length, string suffix, uint flags) {
    int i = findString(sortingId_, flags | FIND_ENDSWITH, source, 0, length, suffix, suffix.length);
    if (i == -1)
      return false;
    else if (i > -1)
      return true;

    for (i = 0; i < length; i++) {
      if (compareString(sortingId_, suffix, 0, suffix.length, source, end - i, i + 1, flags))
        return true;
    }
    return false;
  }

}

public class NumberFormat : IFormatProvider {

  private static NumberFormat current_;
  private static NumberFormat constant_;

  private bool isReadOnly_;

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

  public this() {
    this(LOCALE_INVARIANT);
  }

  public Object getFormat(TypeInfo formatType) {
    if (formatType == typeid(NumberFormat))
      return this;
    return null;
  }

  public static NumberFormat get(IFormatProvider provider) {
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

  public static NumberFormat current() {
    Culture culture = Culture.current;
    if (!culture.isInherited_) {
      if (auto result = culture.numberFormat_)
        return result;
    }
    return cast(NumberFormat)culture.getFormat(typeid(NumberFormat));
  }

  public void numberGroupSizes(int[] value) {
    checkReadOnly();
    numberGroupSizes_ = value;
  }

  public int[] numberGroupSizes() {
    return numberGroupSizes_;
  }

  public void currencyGroupSizes(int[] value) {
    checkReadOnly();
    currencyGroupSizes_ = value;
  }

  public int[] currencyGroupSizes() {
    return currencyGroupSizes_;
  }

  public void positiveSign(string value) {
    checkReadOnly();
    positiveSign_ = value;
  }

  public string positiveSign() {
    return positiveSign_;
  }

  public void negativeSign(string value) {
    checkReadOnly();
    negativeSign_ = value;
  }

  public string negativeSign() {
    return negativeSign_;
  }

  public void numberDecimalSeparator(string value) {
    checkReadOnly();
    numberDecimalSeparator_ = value;
  }

  public string numberDecimalSeparator() {
    return numberDecimalSeparator_;
  }

  public void currencyDecimalSeparator(string value) {
    checkReadOnly();
    currencyDecimalSeparator_ = value;
  }

  public string currencyDecimalSeparator() {
    return currencyDecimalSeparator_;
  }

  public void numberGroupSeparator(string value) {
    checkReadOnly();
    numberGroupSeparator_ = value;
  }

  public string numberGroupSeparator() {
    return numberGroupSeparator_;
  }

  public void currencyGroupSeparator(string value) {
    checkReadOnly();
    currencyGroupSeparator_ = value;
  }

  public string currencyGroupSeparator() {
    return currencyGroupSeparator_;
  }

  public void currencySymbol(string value) {
    checkReadOnly();
    currencySymbol_ = value;
  }

  public string currencySymbol() {
    return currencySymbol_;
  }

  public void nanSymbol(string value) {
    checkReadOnly();
    nanSymbol_ = value;
  }

  public string nanSymbol() {
    return nanSymbol_;
  }

  public void positiveInfinitySymbol(string value) {
    checkReadOnly();
    positiveInfinitySymbol_ = value;
  }

  public string positiveInfinitySymbol() {
    return positiveInfinitySymbol_;
  }

  public void negativeInfinitySymbol(string value) {
    checkReadOnly();
    negativeInfinitySymbol_ = value;
  }

  public string negativeInfinitySymbol() {
    return negativeInfinitySymbol_;
  }

  public void numberDecimalDigits(int value) {
    checkReadOnly();
    numberDecimalDigits_ = value;
  }

  public int numberDecimalDigits() {
    return numberDecimalDigits_;
  }

  public void currencyDecimalDigits(int value) {
    checkReadOnly();
    currencyDecimalDigits_ = value;
  }

  public int currencyDecimalDigits() {
    return currencyDecimalDigits_;
  }

  public void currencyPositivePattern(int value) {
    checkReadOnly();
    currencyPositivePattern_ = value;
  }

  public int currencyPositivePattern() {
    return currencyPositivePattern_;
  }

  public void currencyNegativePattern(int value) {
    checkReadOnly();
    currencyNegativePattern_ = value;
  }

  public int currencyNegativePattern() {
    return currencyNegativePattern_;
  }

  public void numberNegativePattern(int value) {
    checkReadOnly();
    numberNegativePattern_ = value;
  }

  public int numberNegativePattern() {
    return numberNegativePattern_;
  }

  private this(uint culture) {

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

package final char[] allStandardFormats = [ 'd', 'D', 'f', 'F', 'g', 'G', 'r', 'R', 's', 't', 'T', 'u', 'U', 'y', 'Y' ];

/**
 */
public class DateTimeFormat : IFormatProvider {

  private final string RFC1123_PATTERN = "ddd, dd MMM yyyy HH':'mm':'ss 'GMT'";
  private final string SORTABLE_DATETIME_PATTERN = "yyyy'-'MM'-'dd'T'HH':'mm':'ss";
  private final string UNIVERSAL_SORTABLE_DATETIME_PATTERN = "yyyy'-'MM'-'dd HH':'mm':'ss'Z'";

  private static DateTimeFormat current_;
  private static DateTimeFormat constant_;

  private uint cultureId_;
  private bool isReadOnly_;
  private bool isDefaultCalendar_;
  private Calendar calendar_;

  private int calendarWeekRule_ = -1;
  private int firstDayOfWeek_ = -1;
  private string[] dayNames_;
  private string[] abbreviatedDayNames_;
  private string[] monthNames_;
  private string[] abbreviatedMonthNames_;
  private string amDesignator_;
  private string pmDesignator_;
  private string dateSeparator_;
  private string timeSeparator_;
  private string yearMonthPattern_;
  private string shortDatePattern_;
  private string longDatePattern_;
  private string shortTimePattern_;
  private string longTimePattern_;
  private string fullDateTimePattern_;
  private string[] allYearMonthPatterns_;
  private string[] allShortDatePatterns_;
  private string[] allLongDatePatterns_;
  private string[] allShortTimePatterns_;
  private string[] allLongTimePatterns_;
  private string generalShortTimePattern_;
  private string generalLongTimePattern_;
  private int[] optionalCalendars_;

  public this() {
    cultureId_ = LOCALE_INVARIANT;
    isDefaultCalendar_ = true;
    calendar_ = GregorianCalendar.defaultInstance;
    initializeProperties();
  }

  public Object getFormat(TypeInfo formatType) {
    if (formatType == typeid(DateTimeFormat))
      return this;
    return null;
  }

  public static DateTimeFormat get(IFormatProvider provider) {
    if (auto culture = cast(Culture)provider) {
      if (!culture.isInherited_)
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

  public final string getDayName(DayOfWeek dayOfWeek) {
    return getDayNames()[cast(int)dayOfWeek];
  }

  public final string getAbbreviatedDayName(DayOfWeek dayOfWeek) {
    return getAbbreviatedDayNames()[cast(int)dayOfWeek];
  }

  public final string getMonthName(int month) {
    return getMonthNames()[month - 1];
  }
  
  public final string getAbbreviatedMonthName(int month) {
    return getAbbreviatedMonthNames()[month - 1];
  }

  public final string[] getAllDateTimePatterns() {
    string[] ret;
    foreach (format; allStandardFormats)
      ret ~= getAllDateTimePatterns(format);
    return ret;
  }

  public final string[] getAllDateTimePatterns(char format) {

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

  public final void setAllDateTimePatterns(string[] patterns, char format) {
    checkReadOnly();
    switch (format) {
      case 'd':
        shortDatePattern = patterns[0];
        allShortDatePatterns_ = patterns;
        return;
      case 'D':
        longDatePattern = patterns[0];
        allLongDatePatterns_ = patterns;
        return;
      case 't':
        shortTimePattern = patterns[0];
        allShortTimePatterns_ = patterns;
        return;
      case 'T':
        longTimePattern = patterns[0];
        allLongTimePatterns_ = patterns;
        return;
      case 'y', 'Y':
        yearMonthPattern_ = patterns[0];
        allYearMonthPatterns_ = patterns;
        break;
      default:
        throw new ArgumentException("The specified format was not valid.", "format");
    }
  }

  public static DateTimeFormat current() {
    Culture culture = Culture.current;
    if (!culture.isInherited_) {
      if (culture.dateTimeFormat_ !is null)
        return culture.dateTimeFormat_;
    }
    return cast(DateTimeFormat)culture.getFormat(typeid(DateTimeFormat));
  }

  public static DateTimeFormat constant() {
    if (constant_ is null) {
      constant_ = new DateTimeFormat;
      constant_.calendar.isReadOnly_ = true;
      constant_.isReadOnly_ = true;
    }
    return constant_;
  }

  public final void dayNames(string[] value) {
    checkReadOnly();
    dayNames_ = value;
  }

  public final string[] dayNames() {
    return getDayNames().dup;
  }

  public final void abbreviatedDayNames(string[] value) {
    checkReadOnly();
    abbreviatedDayNames_ = value;
  }

  public final string[] abbreviatedDayNames() {
    return getAbbreviatedDayNames().dup;
  }

  public final void monthNames(string[] value) {
    checkReadOnly();
    monthNames_ = value;
  }

  public final string[] monthNames() {
    return getMonthNames().dup;
  }

  public final void abbreviatedMonthNames(string[] value) {
    checkReadOnly();
    abbreviatedMonthNames_ = value;
  }

  public final string[] abbreviatedMonthNames() {
    return getAbbreviatedMonthNames().dup;
  }

  public final void amDesignator(string value) {
    checkReadOnly();
    amDesignator_ = value;
  }

  public final string amDesignator() {
    return amDesignator_;
  }

  public final void pmDesignator(string value) {
    checkReadOnly();
    pmDesignator_ = value;
  }

  public final string pmDesignator() {
    return pmDesignator_;
  }

  public final void dateSeparator(string value) {
    checkReadOnly();
    dateSeparator_ = value;
  }

  public final string dateSeparator() {
    if (dateSeparator_ == null)
      dateSeparator_ = getLocaleInfo(cultureId_, LOCALE_SDATE);
    return dateSeparator_;
  }

  public final void timeSeparator(string value) {
    checkReadOnly();
    timeSeparator_ = value;
  }

  public final string timeSeparator() {
    if (timeSeparator_ == null)
      timeSeparator_ = getLocaleInfo(cultureId_, LOCALE_STIME);
    return timeSeparator_;
  }

  public final string rfc1123Pattern() {
    return RFC1123_PATTERN;
  }

  public final string sortableDateTimePattern() {
    return SORTABLE_DATETIME_PATTERN;
  }

  public final string universalSortableDateTimePattern() {
    return UNIVERSAL_SORTABLE_DATETIME_PATTERN;
  }

  public final void yearMonthPattern(string value) {
    checkReadOnly();
    yearMonthPattern_ = value;
  }

  public final string yearMonthPattern() {
    return yearMonthPattern_;
  }

  public final void shortDatePattern(string value) {
    checkReadOnly();
    shortDatePattern_ = value;
  }

  public final string shortDatePattern() {
    return shortDatePattern_;
  }

  public final void longDatePattern(string value) {
    checkReadOnly();
    longDatePattern_ = value;
  }

  public final string longDatePattern() {
    return longDatePattern_;
  }

  public final void shortTimePattern(string value) {
    checkReadOnly();
    shortTimePattern_ = value;
  }

  public final string shortTimePattern() {
    if (shortTimePattern_ == null)
      shortTimePattern_ = getShortTime(cultureId_);
    return shortTimePattern_;
  }

  public final void longTimePattern(string value) {
    checkReadOnly();
    longTimePattern_ = value;
  }

  public final string longTimePattern() {
    return longTimePattern_;
  }

  public final string fullDateTimePattern() {
    if (fullDateTimePattern_ == null)
      fullDateTimePattern_ = longDatePattern ~ " " ~ longTimePattern_;
    return fullDateTimePattern_;
  }

  public final void calendar(Calendar value) {
    checkReadOnly();

    if (value !is calendar_) {
      for (int i = 0; i < optionalCalendars.length; i++) {
        if (optionalCalendars[i] == value.id) {
          isDefaultCalendar_ = value.id == CAL_GREGORIAN;

          if (calendar_ !is null) {
            dayNames_ = null;
            abbreviatedDayNames_ = null;
            monthNames_ = null;
            abbreviatedMonthNames_ = null;
            yearMonthPattern_ = null;
            shortDatePattern_ = null;
            longDatePattern_ = null;
            fullDateTimePattern_ = null;
            allShortDatePatterns_ = null;
            allLongDatePatterns_ = null;
          }

          calendar_ = value;

          initializeProperties();
          return;
        }
      }
      throw new ArgumentException("Not a valid calendar for the culture.");
    }
  }

  public final Calendar calendar() {
    return calendar_;
  }

  public final string calendarName() {
    return getCalendarInfo(cultureId_, calendar.id, CAL_SCALNAME);
  }

  public final void calendarWeekRule(CalendarWeekRule value) {
    checkReadOnly();
    calendarWeekRule_ = cast(int)value;
  }

  public final CalendarWeekRule calendarWeekRule() {
    return cast(CalendarWeekRule)calendarWeekRule_;
  }

  public final void firstDayOfWeek(DayOfWeek value) {
    checkReadOnly();
    firstDayOfWeek_ = cast(int)value;
  }

  public final DayOfWeek firstDayOfWeek() {
    return cast(DayOfWeek)firstDayOfWeek_;
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

  private this(uint culture, Calendar cal) {
    cultureId_ = culture;
    calendar = cal;
  }

  private void initializeProperties() {
    if (amDesignator_ == null)
      amDesignator_ = getLocaleInfo(cultureId_, LOCALE_S1159);
    if (pmDesignator_ == null)
      pmDesignator_ = getLocaleInfo(cultureId_, LOCALE_S2359);
    if (calendarWeekRule_ == -1)
      calendarWeekRule_ = getLocaleInfoI(cultureId_, LOCALE_IFIRSTWEEKOFYEAR);
    if (firstDayOfWeek_ == -1) {
      firstDayOfWeek_ = getLocaleInfoI(cultureId_, LOCALE_IFIRSTDAYOFWEEK);
      // 0 = Monday, 1 = Tuesday ... 6 = Sunday
      if (firstDayOfWeek_ < 6)
        firstDayOfWeek_++;
      else
        firstDayOfWeek_ = 0;
    }
    if (yearMonthPattern_ == null)
      yearMonthPattern_ = getLocaleInfo(cultureId_, LOCALE_SYEARMONTH);
    if (shortDatePattern_ == null)
      shortDatePattern_ = getShortDatePattern(calendar_.id);
    if (longDatePattern_ == null)
      longDatePattern_ = getLongDatePattern(calendar_.id);
    if (longTimePattern_ == null)
      longTimePattern_ = getLocaleInfo(cultureId_, LOCALE_STIMEFORMAT);
  }

  private string getShortDatePattern(uint cal) {
    if (!isDefaultCalendar_)
      return getShortDates(cultureId_, cal)[0];
    return getLocaleInfo(cultureId_, LOCALE_SSHORTDATE);
  }

  private string getLongDatePattern(uint cal) {
    if (!isDefaultCalendar_)
      return getLongDates(cultureId_, cal)[0];
    return getLocaleInfo(cultureId_, LOCALE_SLONGDATE);
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
    if (abbreviatedDayNames_ == null) {
      abbreviatedDayNames_.length = 7;
      for (uint i = LOCALE_SABBREVDAYNAME1; i <= LOCALE_SABBREVDAYNAME7; i++) {
        uint j = (i != LOCALE_SABBREVDAYNAME7) ? i - LOCALE_SABBREVDAYNAME1 + 1 : 0;
        abbreviatedDayNames_[j] = getLocaleInfo(cultureId_, i);
      }
    }
    return abbreviatedDayNames_;
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
    if (abbreviatedMonthNames_ == null) {
      abbreviatedMonthNames_.length = 13;
      for (uint i = LOCALE_SABBREVMONTHNAME1; i <= LOCALE_SABBREVMONTHNAME12; i++) {
        abbreviatedMonthNames_[i - LOCALE_SABBREVMONTHNAME1] = getLocaleInfo(cultureId_, i);
      }
    }
    return abbreviatedMonthNames_;
  }

  private int[] optionalCalendars() {
    if (optionalCalendars_ == null)
      optionalCalendars_ = getOptionalCalendars(cultureId_);
    return optionalCalendars_;
  }

  private string[] allYearMonthPatterns() {
    if (allYearMonthPatterns_ == null) {
      if (!isDefaultCalendar_)
        allYearMonthPatterns_ = [ getCalendarInfo(cultureId_, calendar_.id, CAL_SYEARMONTH) ];
      if (allYearMonthPatterns_ == null)
        allYearMonthPatterns_ = [ getLocaleInfo(cultureId_, LOCALE_SYEARMONTH) ];
    }
    return allYearMonthPatterns_;
  }

  private string[] allShortDatePatterns() {
    if (allShortDatePatterns_ == null) {
      if (!isDefaultCalendar_)
        allShortDatePatterns_ = [ getShortDatePattern(calendar_.id) ];
      if (allShortDatePatterns_ == null)
        allShortDatePatterns_ = getShortDates(cultureId_, calendar_.id);
    }
    return allShortDatePatterns_.dup;
  }

  private string[] allLongDatePatterns() {
    if (allLongDatePatterns_ == null) {
      if (!isDefaultCalendar_)
        allLongDatePatterns_ = [ getLongDatePattern(calendar_.id) ];
      if (allLongDatePatterns_ == null)
        allLongDatePatterns_ = getLongDates(cultureId_, calendar_.id);
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

  private void checkReadOnly() {
    if (isReadOnly_)
      throw new InvalidOperationException("Instance is read-only.");
  }

  private static bool enumCalendarInfo(uint culture, uint calendar, uint calType, out int[] result) {
    static int[] temp;

    extern (Windows)
    static int enumCalendarsProc(wchar* lpCalendarData, uint Calendar) {
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

  private static bool enumDateFormats(uint culture, uint calendar, uint flags, out string[] formats) {
    static string[] temp;
    static uint cal;

    extern (Windows)
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

  private static bool enumTimeFormats(uint culture, uint flags, out string[] formats) {
    static string[] temp;

    extern (Windows)
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
        string temp = s[0 .. i];
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

  private static string getShortTime(uint culture) {
    // There is no LOCALE_SSHORTTIME, so we simulate one based on the long time pattern.
    string s = getLocaleInfo(culture, LOCALE_STIMEFORMAT);
    int i = s.rfind(getLocaleInfo(culture, LOCALE_STIME));
    if (i != -1)
      s.length = i;
    return s;
  }

}

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

private final int[] DaysToMonthCommon = [ 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365 ];
private final int[] DaysToMonthLeap = [ 0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366 ];

private enum DatePart {
  Year,
  Month,
  Day,
  DayOfYear
}

private void splitDate(long ticks, out int year, out int month, out int day, out int dayOfYear) {
  int numDays = cast(int)(ticks / TicksPerDay);
  int whole400Years = numDays / DaysPer400Years;
  numDays -= whole400Years * DaysPer400Years;
  int whole100Years = numDays / DaysPer100Years;
  if (whole100Years == 4)
    whole100Years = 3;
  numDays -= whole100Years * DaysPer100Years;
  int whole4Years = numDays / DaysPer4Years;
  numDays -= whole4Years * DaysPer4Years;
  int wholeYears = numDays / DaysPerYear;
  if (wholeYears == 4)
    wholeYears = 3;
  year = whole400Years * 400 + whole100Years * 100 + whole4Years * 4 + wholeYears + 1;
  numDays -= wholeYears * DaysPerYear;
  dayOfYear = numDays + 1;
  int[] monthDays = (wholeYears == 3 && (whole4Years != 24 || whole100Years == 3)) ? DaysToMonthLeap : DaysToMonthCommon;
  month = numDays >> 5 + 1;
  while (numDays >= monthDays[month])
    month++;
  day = numDays - monthDays[month - 1] + 1;
}

private int extractPart(long ticks, DatePart part) {
  int year, month, day, dayOfYear;
  splitDate(ticks, year, month, day, dayOfYear);
  if (part == DatePart.Year)
    return year;
  else if (part == DatePart.Month)
    return month;
  else if (part == DatePart.DayOfYear)
    return dayOfYear;
  return day;
}

/**
 */
public abstract class Calendar {

  private bool isReadOnly_;

  protected int id() {
    return -1;
  }

}

/**
 */
public class GregorianCalendar : Calendar {

  private static GregorianCalendar defaultInstance_;

  private GregorianCalendarType type_;

  /**
   */
  public this(GregorianCalendarType type = GregorianCalendarType.Localized) {
    type_ = type;
  }

  protected override final int id() {
    return cast(int)type_;
  }

  private static GregorianCalendar defaultInstance() {
    if (defaultInstance_ is null)
      defaultInstance_ = new GregorianCalendar;
    return defaultInstance_;
  }

}

/**
 * Represents the Saudi Hijri (Umm-Al Qurah) calendar.
 */
public class UmAlQuraCalendar : Calendar {

  /// Represents the current era.
  public const int UmAlQuraEra = 1;

  public this() {
  }

  protected override int id() {
    return CAL_UMALQURA;
  }

}

/**
 */
public struct TimeSpan {

  private long ticks_;

  public static final TimeSpan zero = { 0 };
  public static final TimeSpan min = { long.min };
  public static final TimeSpan max = { long.max };

  public static TimeSpan opCall(long ticks) {
    TimeSpan t;
    t.ticks_ = ticks;
    return t;
  }

  public static TimeSpan opCall(int hours, int minutes, int seconds) {
    TimeSpan t;
    t.ticks_ = (cast(long)hours * 3600 + cast(long)minutes * 60 + cast(long)seconds) * TicksPerSecond;
    return t;
  }

  public static TimeSpan opCall(int days, int hours, int minutes, int seconds) {
    return TimeSpan(days, hours, minutes, seconds, 0);
  }

  public static TimeSpan opCall(int days, int hours, int minutes, int seconds, int milliseconds) {
    TimeSpan t;
    t.ticks_ = ((cast(long)days * 3600 * 24 + cast(long)hours * 3600 + cast(long)minutes * 60 + cast(long)seconds) * MillisPerSecond + milliseconds) + TicksPerMillisecond;
    return t;
  }

  public TimeSpan add(TimeSpan ts) {
    return TimeSpan(ticks_ + ts.ticks_);
  }

  public TimeSpan opAdd(TimeSpan ts) {
    return add(ts);
  }

  public TimeSpan opAddAssign(TimeSpan ts) {
    ticks_ += ts.ticks_;
    return *this;
  }

  public TimeSpan subtract(TimeSpan ts) {
    return TimeSpan(ticks_ - ts.ticks_);
  }

  public TimeSpan opSub(TimeSpan ts) {
    return subtract(ts);
  }

  public TimeSpan opSubAssign(TimeSpan ts) {
    ticks_ -= ts.ticks_;
    return *this;
  }

  public TimeSpan negate() {
    return TimeSpan(-ticks_);
  }

  public TimeSpan opNeg() {
    return TimeSpan(-ticks_);
  }

  public TimeSpan opPos() {
    return *this;
  }

  public int compare(TimeSpan other) {
    if (ticks_ > other.ticks_)
      return 1;
    else if (ticks_ < other.ticks_)
      return -1;
    return 0;
  }

  public int opCmp(TimeSpan other) {
    return compare(other);
  }

  public bool equals(TimeSpan other) {
    return ticks_ == other.ticks_;
  }

  public bool opEquals(TimeSpan other) {
    return equals(other);
  }

  public hash_t toHash() {
    return cast(int)ticks_ ^ cast(int)(ticks_ >> 32);
  }

  public TimeSpan duration() {
    return TimeSpan((ticks_ < 0) ? -ticks_ : ticks_);
  }

  public int days() {
    return cast(int)(ticks_ / TicksPerDay);
  }

  public int hours() {
    return cast(int)((ticks_ / TicksPerHour) % 24);
  }

  public int minutes() {
    return cast(int)((ticks_ / TicksPerMinute) % 60);
  }

  public int seconds() {
    return cast(int)((ticks_ / TicksPerSecond) % 60);
  }

  public long ticks() {
    return ticks_;
  }

}

/**
 */
public struct DateTime {

  public static final DateTime min = { 0 };
  public static final DateTime max = { DaysTo10000 * TicksPerDay - 1 };

  private long data_;

  public static DateTime opCall(long ticks) {
    DateTime d;
    d.data_ = ticks;
    return d;
  }

  public static DateTime opCall(int year, int month, int day) {
    DateTime d;
    d.data_ = dateToTicks(year, month, day);
    return d;
  }

  public static DateTime opCall(int year, int month, int day, int hour, int minute, int second) {
    DateTime d;
    d.data_ = dateToTicks(year, month, day) + timeToTicks(hour, minute, second);
    return d;
  }

  public DateTime addTicks(long value) {
    return DateTime(ticks + value);
  }

  public DateTime add(TimeSpan value) {
    return addTicks(value.ticks_);
  }

  public DateTime opAdd(TimeSpan value) {
    return DateTime(ticks + value.ticks_);
  }

  public DateTime opAddAssign(TimeSpan value) {
    data_ += value.ticks_;
    return *this;
  }

  public DateTime subtract(TimeSpan value) {
    return DateTime(ticks - value.ticks_);
  }

  public DateTime opSub(TimeSpan value) {
    return DateTime(ticks - value.ticks_);
  }

  public DateTime opSubAssign(TimeSpan value) {
    data_ -= value.ticks_;
    return *this;
  }

  public int compare(DateTime other) {
    if (ticks > other.ticks)
      return 1;
    else if (ticks < other.ticks)
      return -1;
    return 0;
  }

  public int opCmp(DateTime other) {
    return compare(other);
  }

  public bool equals(DateTime other) {
    return ticks == other.ticks;
  }

  public bool opEquals(DateTime other) {
    return equals(other);
  }

  public hash_t toHash() {
    return cast(int)ticks ^ cast(int)(ticks >> 32);
  }

  public static bool isLeapYear(int year) {
    return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0));
  }

  public string toString(string format, IFormatProvider provider) {
    return formatDateTime(*this, format, DateTimeFormat.get(provider));
  }

  public string toString(string format) {
    return formatDateTime(*this, format, DateTimeFormat.current);
  }

  public string toString(IFormatProvider provider) {
    return formatDateTime(*this, null, DateTimeFormat.get(provider));
  }

  public string toString() {
    return formatDateTime(*this, null, DateTimeFormat.current);
  }

  public string toShortDateString() {
    return formatDateTime(*this, "d", DateTimeFormat.current);
  }

  public string toLongDateString() {
    return formatDateTime(*this, "D", DateTimeFormat.current);
  }

  public string toShortTimeString() {
    return formatDateTime(*this, "t", DateTimeFormat.current);
  }

  public string toLongTimeString() {
    return formatDateTime(*this, "T", DateTimeFormat.current);
  }

  public static DateTime parse(string s, IFormatProvider provider = null) {
    return parseDateTime(s, DateTimeFormat.get(provider));
  }

  public static DateTime parse(string s, string format, IFormatProvider provider = null) {
    return parseDateTimeExact(s, format, DateTimeFormat.get(provider));
  }

  public static DateTime fromOleDate(double d) {
    return DateTime(oleDateToTicks(d));
  }

  public double toOleDate() {
    return ticksToOleDate(ticks);
  }

  public int year() {
    return extractPart(ticks, DatePart.Year);
  }

  public int month() {
    return extractPart(ticks, DatePart.Month);
  }

  public int day() {
    return extractPart(ticks, DatePart.Day);
  }

  public int dayOfYear() {
    return extractPart(ticks, DatePart.DayOfYear);
  }

  public DayOfWeek dayOfWeek() {
    return cast(DayOfWeek)((ticks / TicksPerDay + 1) % 7);
  }

  public int hour() {
    return cast(int)((ticks / TicksPerHour) % 24);
  }

  public int minute() {
    return cast(int)((ticks / TicksPerMinute) % 60);
  }

  public int second() {
    return cast(int)((ticks / TicksPerSecond) % 60);
  }

  public int millisecond() {
    return cast(int)((ticks / TicksPerMillisecond) % 1000);
  }

  public TimeSpan timeOfDay() {
    return TimeSpan(ticks % TicksPerDay);
  }

  public long ticks() {
    return data_;
  }

  public static DateTime localNow() {
    FILETIME utcFileTime, localFileTime;
    GetSystemTimeAsFileTime(utcFileTime);
    FileTimeToLocalFileTime(utcFileTime, localFileTime);

    long ticks = (cast(long)localFileTime.dwHighDateTime << 32) | localFileTime.dwLowDateTime;
    return DateTime(ticks + (DaysTo1601 * TicksPerDay));
  }

  public static DateTime utcNow() {
    FILETIME utcFileTime;
    GetSystemTimeAsFileTime(utcFileTime);

    long ticks = (cast(long)utcFileTime.dwHighDateTime << 32) | utcFileTime.dwLowDateTime;
    return DateTime(ticks + (DaysTo1601 * TicksPerDay));
  }

  private static long dateToTicks(int year, int month, int day) {
    int[] monthDays = isLeapYear(year) ? DaysToMonthLeap : DaysToMonthCommon;
    year--;
    return (year * 365 + year / 4 - year / 100 + year / 400 + monthDays[month - 1] + day - 1) * TicksPerDay;
  }

  private static long timeToTicks(int hour, int minute, int second) {
    return (cast(long)hour * 3600 + cast(long)minute * 60 + cast(long)second) * TicksPerSecond;
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