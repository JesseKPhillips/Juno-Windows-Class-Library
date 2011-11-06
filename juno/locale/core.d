/**
 * Contains classes that define culture-related information.
 *
 * Copyright: (c) 2008 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.locale.core;

private import juno.base.core,
  juno.base.native,
  juno.locale.constants;

private import juno.locale.time : Calendar, GregorianCalendar;
private import juno.locale.format : NumberFormat, DateTimeFormat;
private import juno.locale.text : Collator;

private import std.algorithm;
private import std.array;
private import std.c.stdio : sprintf;
private import std.c.wcharh : swscanf; 
private import std.conv : to;
private import std.exception;
private import std.range;
private import std.string : icmp, toUpper;
private import std.utf : toUTF8;
private static import std.ascii;

private uint[string] nameToLcidMap;
private string[uint] lcidToNameMap;
private uint[string] regionNameToLcidMap;

static ~this() {
  nameToLcidMap = null;
  lcidToNameMap = null;
  regionNameToLcidMap = null;
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
  cch = GetGeoInfo(geoId, geoType, buffer.ptr, buffer.length, 0);
  if (cch == 0)
    return null;

  return toUTF8(buffer[0 .. cch - 1]);
}

package wchar* toUTF16zNls(string s, int offset, int length, out int translated) {
  translated = 0;

  immutable(char)* pChars = s.ptr + offset;
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
  return result.idup;
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

private bool findCultureByName(string cultureName, out string actualName, out uint culture) {
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

private bool findCultureById(uint culture, out string cultureName, out uint actualCulture) {
  if (culture != LOCALE_INVARIANT) {
    ensureNameMapping();

    if (auto value = culture in lcidToNameMap)
      return findCultureByName(*value, cultureName, actualCulture);

    return false;
  }

  return findCultureByName("", cultureName, actualCulture);
}

private bool findCultureFromRegionName(string regionName, out uint culture) {
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

  private static Culture constant_;
  private static Culture current_;
  private static Culture currentUI_;
  private static Culture userDefault_;
  private static Culture userDefaultUI_;

  private uint cultureId_;
  private string cultureName_;

  package bool isReadOnly_;
  package bool isInherited_;

  private Calendar calendar_;
  package DateTimeFormat dateTimeFormat_;
  package NumberFormat numberFormat_;
  private Collator collator_;
  private Culture parent_;

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
      char[100] buffer;
      int len = sprintf(buffer.ptr, "Culture ID %d (0x%04x) is not a supported culture.", culture, culture);
      throw new ArgumentException(buffer[0 .. len].idup, "culture");
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
      char[100] buffer;
      int len = sprintf(buffer.ptr, "Culture ID %d (0x%04x) is not a supported culture.", culture, culture);
      throw new ArgumentException(buffer[0 .. len].idup, "culture");
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

    string toLowerAnsi(string s) {
      char[] x = s.dup;
      foreach (ref c; x) {
        if (c <= 'Z' && c >= 'A')
          c = c - 'A' + 'a';
      }
      return assumeUnique(x);
    }

    if (name != null)
      name = toLowerAnsi(name);

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

  static Culture constant() {
    return constant_;
  }

  /**
   * Gets or sets the Culture that represents the culture used by the _current thread.
   * Returns: The Culture that represents the culture used by the _current thread.
   */
  static void current(Culture value) {
    if (value is null)
      throw new ArgumentNullException("value");

    checkNeutral(value);
    SetThreadLocale(value.lcid);
    current_ = value;
  }

  /**
   * ditto
   */
  static Culture current() {
    if (current_ !is null)
      return current_;

    return userDefault;
  }

  /**
   * Gets or sets the Culture that represents the current culture used to look up resources.
   * Returns: The Culture that represents the current culture used to look up resources.
   */
  static void currentUI(Culture value) {
    if (value is null)
      throw new ArgumentNullException("value");

    currentUI_ = value;
  }

  /** 
   * ditto
   */
  static Culture currentUI() {
    if (currentUI_ !is null)
      return currentUI_;

    return userDefaultUI;
  }

  /**
   * Gets the culture identifier of the current instance.
   * Returns: The culture identifier.
   */
  uint lcid() {
    return cultureId_;
  }

  /**
   * Gets the culture _name in the format "&lt;language&gt;-&lt;region&gt;".
   * Returns: The culture _name.
   */
  string name() {
    return cultureName_;
  }

  /**
   * Gets the culture name in the format "&lt;language&gt; (&lt;region&gt;)" in the language of the culture.
   * Returns: The culture name in the language of the culture.
   */
  string nativeName() {
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
  string englishName() {
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
  string displayName() {
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
  CultureTypes types() {
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

  bool isNeutral() {
    return isNeutralCulture(cultureId_);
  }

  final bool isReadOnly() {
    return isReadOnly_;
  }

  /**
   * Gets or sets the NumberFormat that defines the culturally appropriate format for displaying numbers and currency.
   * Returns: The NumberFormat that defines the culturally appropriate format for displaying numbers and currency.
   * Throws: ArgumentNullException if the property is set to null.
   */
  void numberFormat(NumberFormat value) {
    checkReadOnly();

    if (value is null)
      throw new ArgumentNullException("value");

    numberFormat_ = value;
  }

  /**
   * ditto
   */
  NumberFormat numberFormat() {
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
  void dateTimeFormat(DateTimeFormat value) {
    checkReadOnly();

    if (value is null)
      throw new ArgumentNullException("value");

    dateTimeFormat_ = value;
  }

  /**
   * ditto
   */
  DateTimeFormat dateTimeFormat() {
    if (dateTimeFormat_ is null) {
      checkNeutral(this);

      dateTimeFormat_ = new DateTimeFormat(cultureId_, calendar);
      dateTimeFormat_.isReadOnly_ = isReadOnly_;
    }
    return dateTimeFormat_;
  }

  /**
   * Gets the default _calendar used by the culture.
   * Returns: A Calendar that represents the default _calendar used by the culture.
   */
  Calendar calendar() {
    if (calendar_ is null) {
      calendar_ = getCalendar(getLocaleInfoI(cultureId_, LOCALE_ICALENDARTYPE));
      calendar_.isReadOnly_ = isReadOnly_;
    }
    return calendar_;
  }

  Collator collator() {
    if (collator_ is null)
      collator_ = Collator.get(cultureId_);
    return collator_;
  }

  string listSeparator() {
    return getLocaleInfo(cultureId_, LOCALE_SLIST);
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

  private static Calendar getCalendar(int cal) {
    /*switch (cal) {
      case CAL_JAPAN:
        return new JapaneseCalendar;
      default:
    }*/
    return new GregorianCalendar(cast(GregorianCalendarType)cal);
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

class Region {

  private static Region current_;

  private uint cultureId_;
  private string name_;

  static ~this() {
    current_ = null;
  }

  this(uint culture) {
    if (culture == LOCALE_INVARIANT)
      throw new ArgumentException("There is no region associated with the invariant culture (Culture ID: 0x7F).");

    if (SUBLANGID(cast(ushort)culture) == 0) {
      char[100] buffer;
      int len = sprintf(buffer.ptr, "Culture ID %d (0x%04X) is a neutral culture; a region cannot be created from it.", culture, culture);
      throw new ArgumentException(buffer[0 .. len].idup, "culture");
    }

    cultureId_ = culture;
    name_ = getLocaleInfo(culture, LOCALE_SISO3166CTRYNAME);
  }

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

  static Region current() {
    if (current_ is null)
      current_ = new Region(Culture.current.lcid);
    return current_;
  }

  int geoId() {
    return getLocaleInfoI(cultureId_, LOCALE_IGEOID);
  }

  string name() {
    if (name_ == null)
      name_ = getLocaleInfo(cultureId_, LOCALE_SISO3166CTRYNAME);
    return name_;
  }

  string nativeName() {
    return getLocaleInfo(cultureId_, LOCALE_SNATIVECTRYNAME);
  }

  string displayName() {
    return getLocaleInfo(cultureId_, LOCALE_SCOUNTRY);
  }

  string englishName() {
    return getLocaleInfo(cultureId_, LOCALE_SENGCOUNTRY);
  }

  string isoRegionName() {
    return getGeoInfo(geoId, GEO_ISO2);
  }

  bool isMetric() {
    return getLocaleInfoI(cultureId_, LOCALE_IMEASURE) == 0;
  }

  string currencySymbol() {
    return getLocaleInfo(cultureId_, LOCALE_SCURRENCY);
  }

  string isoCurrencySymbol() {
    return getLocaleInfo(cultureId_, LOCALE_SINTLSYMBOL);
  }

  string currencyNativeName() {
    return getLocaleInfo(cultureId_, LOCALE_SNATIVECURRNAME);
  }

  string currencyEnglishName() {
    return getLocaleInfo(cultureId_, LOCALE_SENGCURRNAME);
  }

  double latitude() {
    return getGeoInfo(geoId, GEO_LATITUDE).toDouble();
  }

  double longitude() {
    return getGeoInfo(geoId, GEO_LONGITUDE).toDouble();
  }

}