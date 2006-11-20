/**
 * Contains classes defining culture-related information.
 */
module juno.intl.core;

private import juno.base.core,
  juno.base.string,
  juno.base.win32,
  juno.intl.constants,
  juno.utils.registry;
private import juno.intl.format : formatDateTime;
private import juno.base.meta : nameof;
private import std.c.stdio : swscanf;
private import std.utf : toUTF8, toUTF16z;
private import std.c.string : memcpy;
private import std.string : icmp;

// XP/Vista only
extern (Windows)
alias DllImport!("kernel32.dll", "GetGeoInfo", int function(int GeoId, uint GeoType, wchar* lpGeoData, int cchData, ushort language)) GetGeoInfo;

extern (Windows)
alias DllImport!("kernel32.dll", "SystemTimeToTzSpecificLocalTime", bool function(TIME_ZONE_INFORMATION* lpTimeZone, SYSTEMTIME* lpUniversalTime, SYSTEMTIME* lpLocalTime)) SystemTimeToTzSpecificLocalTime;

extern (Windows)
alias DllImport!("kernel32.dll", "TzSpecificLocalTimeToSystemTime", bool function(TIME_ZONE_INFORMATION* lpTimeZone, SYSTEMTIME* lpLocalTime, SYSTEMTIME* lpUniversalTime)) TzSpecificLocalTimeToSystemTime;

// Microsoft National Language Support Downlevel APIs 1.0
// http://www.microsoft.com/downloads/details.aspx?FamilyID=eb72cda0-834e-4c35-9419-ff14bc349c9d&DisplayLang=en
extern (Windows)
alias DllImport!("nlsdl.dll", "DownlevelLCIDToLocaleName", int function(uint Locale, wchar* lpName, int cchName, uint dwFlags)) DownlevelLCIDToLocaleName;

extern (Windows)
alias DllImport!("nlsdl.dll", "DownlevelLocaleNameToLCID", uint function(wchar* lpName, uint dwFlags)) DownlevelLocaleNameToLCID;

// Native Vista NLS APIs
extern (Windows)
alias DllImport!("kernel32.dll", "LCIDToLocaleName", int function(uint Locale, wchar* lpName, int cchName, uint dwFlags)) LCIDToLocaleName;

extern (Windows)
alias DllImport!("kernel32.dll", "LocaleNameToLCID", uint function(wchar* lpName, uint dwFlags)) LocaleNameToLCID;

extern (Windows)
alias DllImport!("kernel32.dll", "GetDynamicTimeZoneInformation", uint function(DYNAMIC_TIME_ZONE_INFORMATION* pTimeZoneInformation)) GetDynamicTimeZoneInformation;

private uint[char[]] nameToLcidTable;
private char[][uint] lcidToNameTable;
private uint[char[]] regionNameToLcidTable;

static ~this() {
  nameToLcidTable = null;
  lcidToNameTable = null;
  regionNameToLcidTable = null;
}

private void initNameMapping() {

  bool enumSystemLocales(out uint[] locales) {
    static uint[uint] temp;

    extern (Windows)
    static bool enumLocalesProc(wchar* lpLocaleString) {
      uint locale;
      if (swscanf(lpLocaleString, "%x", &locale) > 0) {
        if (!(locale in temp)) {
          temp[locale] = locale;
          uint lang = locale & 0x3FF;
          if (!(lang in temp)) {
            // The following LANGIDs don't supply any useful information.
            if (lang != 0x0014 && lang != 0x002C && lang != 0x003B && lang != 0x0043)
              temp[lang] = lang;
          }
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

  // Culture names are of the form "language"-"country", for example en-GB.
  char[] getCultureName(uint culture) {
    // We get the name via one of three ways:
    // 1) On Visa, by calling LCIDToLocaleName, or
    // 2) If the NLS downlevel API is available, by calling DownlevelLCIDToLocaleName, or
    // 3) By combining the ISO 639 name with the ISO 3166 name

    char[] name = null;

    if (LOBYTE(LOWORD(GetVersion())) >= 6) { // Vista
      wchar[80] buffer;
      int cch = LCIDToLocaleName(culture, buffer, buffer.length, 0);
      if (cch != 0)
        name = buffer[0 .. cch - 1].toUTF8();
    }
    else {
      try {
        // DownlevelLCIDToLocaleName returns specific culture names only.
        wchar[80] buffer;
        int cch = DownlevelLCIDToLocaleName(culture, buffer, buffer.length, 0);
        if (cch != 0)
          name = buffer[0 .. cch - 1].toUTF8();
      }
      catch (DllNotFoundException) {
      }
      catch (EntryPointNotFoundException) {
      }
    }

    if (name == null) {
      // Construct a locale name that's compatible with Vista (RFC 4646).
      char[] language, script, country;

      if (culture == 0x243B)
        language = "smn";
      else if (culture == 0x203B)
        language = "sms";
      else if (culture == 0x1C3B || culture == 0x183B)
        language = "sma";
      else if (culture == 0x143B || culture == 0x103B)
        language = "smj";
      else if (culture == 0x046B || culture == 0x086B || culture == 0x0C6B)
        language = "quz";
      else
        language = getLocaleInfo(culture, LOCALE_SISO639LANGNAME);

      if ((culture & 0x3FF) != culture) {
        if (culture == 0x181A || culture == 0x081A || culture == 0x042C || culture == 0x0443 || culture == 0x141A)
          script = "Latn";
        else if (culture == 0x1C1A || culture == 0x0C1A || culture == 0x082C || culture == 0x0843)
          script = "Cyrl";

        if (culture == 0x2409)
          country = "029";
        else if (culture == 0x081A || culture == 0x0C1A)
          country = "CS";
        else if (culture == 0x040A)
          country ~= "ES_tradnl";
        else
          country = getLocaleInfo(culture, LOCALE_SISO3166CTRYNAME);
      }

      name = language;
      if (script != null)
        name ~= "-" ~ script;
      if (country != null)
        name ~= "-" ~ country;
    }

    return name;
  }

  uint[] locales;
  bool success = false;

  synchronized {
    success = enumSystemLocales(locales);
  }

  if (success) {
    foreach (lcid; locales) {
      char[] name = getCultureName(lcid);
      if (name != null) {
        nameToLcidTable[name] = lcid;
        lcidToNameTable[lcid] = name;
      }
    }

    nameToLcidTable[""] = LOCALE_INVARIANT;
    lcidToNameTable[LOCALE_INVARIANT] = "";
  }
}

private bool findCultureFromId(uint culture, out char[] cultureName, out uint actualCulture) {
  if (culture != LOCALE_INVARIANT) {
    if (lcidToNameTable == null)
      initNameMapping();

    if (auto name = culture in lcidToNameTable)
      return findCultureFromName(*name, cultureName, actualCulture);
    return false;
  }
  return findCultureFromName("", cultureName, actualCulture);
}

private bool findCultureFromName(char[] cultureName, out char[] actualName, out uint culture) {
  if (lcidToNameTable == null)
    initNameMapping();

  foreach (name, lcid; nameToLcidTable) {
    if (icmp(cultureName, name) == 0) {
      actualName = name;
      culture = lcid;
      return true;
    }
  }

  return false;
}

private void initRegionMapping() {

  bool enumSystemLocales(out uint[] locales) {
    static uint[uint] temp;

    extern (Windows)
    static bool enumLocalesProc(wchar* lpLocaleString) {
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

  uint[] locales;
  bool success;
  synchronized {
    success = enumSystemLocales(locales);
  }
  if (success) {
    foreach (locale; locales) {
      char[] name = getLocaleInfo(locale, LOCALE_SISO3166CTRYNAME);
      regionNameToLcidTable[name] = locale;
    }
  }

}

private bool findCultureFromRegionName(char[] regionName, out uint culture) {
  if (regionNameToLcidTable == null)
    initRegionMapping();

  // First, do a lookup in the region name table
  foreach (name, lcid; regionNameToLcidTable) {
    if (icmp(regionName, name) == 0) {
      culture = lcid;
      return true;
    }
  }

  // We also accept a culture name, so look there next
  foreach (name, lcid; nameToLcidTable) {
    if (icmp(regionName, name) == 0) {
      culture = lcid;
      return true;
    }
  }
  return false;
}

private char[] getLocaleInfo(uint culture, uint field) {
  wchar[80] buffer;
  int cch = GetLocaleInfo(culture, field, buffer, buffer.length);
  if (cch == 0)
    return null;
  return buffer[0 .. cch - 1].toUTF8();
}

private int getLocaleInfoI(uint culture, uint field) {
  int value;
  GetLocaleInfo(culture, field | LOCALE_RETURN_NUMBER, cast(wchar*)&value, int.sizeof);
  return value;
}

private char[] getGeoInfo(int geoId, uint geoType) {
  wchar[80] buffer;
  int cch = GetGeoInfo(geoId, geoType, buffer, buffer.length, 0);
  return buffer[0 .. cch - 1].toUTF8();
}

private char[] getCalendarInfo(uint culture, uint calendar, uint calType) {
  wchar[80] buffer;
  int cch = GetCalendarInfo(culture, calendar, calType, buffer, buffer.length, null);
  return buffer[0 .. cch - 1].toUTF8();
}

private int getCalendarInfoI(uint culture, uint calendar, uint calType) {
  uint value = -1;
  if (GetCalendarInfo(culture, calendar, calType | CAL_RETURN_NUMBER, null, 0, &value) == 0)
    value = -1;
  return value;
}

private char[][] getNativeDigits(uint culture, uint flags) {
  char[][] result = new char[][10];
  foreach (i, c; getLocaleInfo(culture, LOCALE_SNATIVEDIGITS | flags))
    result[i] = [c];
  return result;
}

private int[] getGrouping(uint culture, uint field) {

  int[] convertGroupString(wchar[] s) {
    if (s == null || s[0] == '0')
      return [3];
    int[] grouping;
    if (s[$ - 1] == '0')
      grouping.length = s.length / 2;
    else {
      grouping.length = (s.length / 2) + 2;
      grouping[$ - 1] = 0;
    }
    int index = 0;
    for (int i = 0; index < s.length && i < grouping.length; i++) {
      if (s[index] < '1' || s[index] > '9')
        return [3];
      grouping[i] = s[index] - '0';
      index += 2;
    }
    return grouping;
  }

  wchar[80] buffer;
  int cch = GetLocaleInfo(culture, field, buffer, buffer.length);
  return convertGroupString(buffer[0 .. cch]);
}

private bool enumCalendarInfo(uint culture, uint calendar, uint calType, out int[] result) {
  static int[] temp;

  extern (Windows)
  static bool enumCalendarsProc(wchar* lpCalendarData, uint Calendar) {
    temp ~= Calendar;
    return true;
  }

  temp = null;
  if (!EnumCalendarInfoEx(&enumCalendarsProc, culture, calendar, calType))
    return false;
  result = temp.dup;
  return true;
}

private int[] getOptionalCalendars(uint culture) {
  static int[] temp;

  extern (Windows)
  static bool enumCalendarsProc(wchar* lpCalendarData, uint Calendar) {
    temp ~= Calendar;
    return true;
  }

  int[] cals;
  synchronized {
    if (!enumCalendarInfo(culture, ENUM_ALL_CALENDARS, CAL_ICALINTVALUE, cals))
      return null;
  }
  return cals;
}

private bool enumDateFormats(uint culture, uint calendar, uint flags, out char[][] formats) {
  static char[][] temp;
  static uint calID;

  extern (Windows)
  static bool enumDateFormatsProc(wchar* lpDateFormatString, uint CalendarID) {
    if (calID == CalendarID)
      temp ~= toUtf8(lpDateFormatString);
    return true;
  }

  temp = null;
  calID = calendar;
  if (!EnumDateFormatsEx(&enumDateFormatsProc, culture, flags))
    return false;
  formats = temp.dup;
  return true;
}

private char[] getShortTime(uint culture) {
  // Simulates a mythical LOCALE_SSHORTTIME.
  char[] s = getLocaleInfo(culture, LOCALE_STIMEFORMAT);
  int i = Culture.invariantCulture.collation.lastIndexOf(s, getLocaleInfo(culture, LOCALE_STIME));
  if (i != -1) {
    char[] temp = s;
    temp = s[0 .. i];
    s = temp;
  }
  return s;
}

private char[][] getShortDates(uint culture, uint calendar) {
  char[][] formats;
  synchronized {
    if (!enumDateFormats(culture, calendar, DATE_SHORTDATE, formats))
      return null;
  }
  if (formats == null)
    return [getCalendarInfo(culture, calendar, CAL_SSHORTDATE)];
  return formats;
}

private char[][] getLongDates(uint culture, uint calendar) {
  char[][] formats;
  synchronized {
    if (!enumDateFormats(culture, calendar, DATE_LONGDATE, formats))
      return null;
  }
  if (formats == null)
    return [getCalendarInfo(culture, calendar, CAL_SLONGDATE)];
  return formats;
}

private char[][] getYearMonths(uint culture, uint calendar) {
  char[][] formats;
  synchronized {
    if (!enumDateFormats(culture, calendar, DATE_YEARMONTH, formats))
      return null;
  }
  return formats;
}

private bool isNeutralCulture(uint culture) {
  return (culture != LOCALE_INVARIANT) && ((culture & 0x3FF) == culture);
}

private char[] getSpecificCulture(char[] name) {
  return lcidToNameTable[ConvertDefaultLocale(nameToLcidTable[name])];
}

private wchar* toUTF16Nls(char[] chars, int offset, int length, out int translated) {
  char* pChars = chars.ptr + offset;
  int cch = MultiByteToWideChar(CP_UTF8, 0, pChars, length, null, 0);
  if (cch == 0)
    return null;
  wchar[] result = new wchar[cch];
  translated = MultiByteToWideChar(CP_UTF8, 0, pChars, length, result, cch);
  return result;
}

// Public API

/**
 * Retrieves an object that controls formatting.
 */
public interface IProvidesFormat {
  /**
   * Returns an object that provices formatting services for the specified _type.
   * Params: type = An object that specifies the _type of format object to return.
   */
  Object getFormat(TypeInfo type);
}

/**
 * Provides information about a specific culture (locale), such as its name and calendar, and formatting for numbers and dates.
 *
 * The _Culture class provides access to instances of $(DDOC_PSYMBOL DateTimeFormat), $(DDOC_PSYMBOL NumberFormat) and $(DDOC_PSYMBOL Collation). These objects 
 * contain information for culture-specific operations, such as formatting dates and numbers and comparing strings.
 *
 * The _Culture class specifies a unique name for each culture, based on the RFC 3066 standard. The name is a combination of an
 * ISO 639 code associated with a language and an ISO 3166 code associated with the country. The culture name is in the format 
 * "&lt;languagecode&gt;-&lt;countrycode&gt;", for example "fr-FR" for French in France and "en-GB" for UK English.
 *
 * Some cultures additionally specify an ISO 15924 script. "Cyrl" specifies a Cyrillic script. "Latn" specifies a Latin script. 
 * For example, "uz-Cyrl-UZ" for Uzbek Cyrillic. In these cases the culture name is in the format "&lt;languagecode&gt;-&lt;scripttag&gt;-&lt;countrycode&gt;".
 *
 * A neutral culture is specified by the language code. For example, "de" specifies the neutral culture for German, and "es" 
 * specifies the neutral culture for Spanish.
 *
 * _Culture names are compatible with those used by Windows Vista (as well as the Windows Vista version of the .NET Framework). 
 * Identifiers are analogous to the Windows LCID type, and can be used in Windows API functions where an LCID is expected.
 *
 * The following predefined culture names and identifers are used by this class.
 *
 * <table>
 * <tr><td><b>_Culture name</b>&nbsp;&nbsp;</td><td><b>_Culture identifier</b>&nbsp;&nbsp;</td><td><b>Language (Country)</b>&nbsp;&nbsp;</td></tr>
 * <tr><td>(empty string)</td><td>0x007F</td><td>Invariant Language (Invariant Country)</td></tr>
 * <tr><td>af</td><td>0x0036</td><td>Afrikaans</td></tr>
 * <tr><td>af-ZA</td><td>0x0436</td><td>Afrikaans (South Africa)</td></tr>
 * <tr><td>sq</td><td>0x001C</td><td>Albanian</td></tr>
 * <tr><td>sq-AL</td><td>0x041C</td><td>Albanian (Albania)</td></tr>
 * <tr><td>ar</td><td>0x0001</td><td>Arabic</td></tr>
 * <tr><td>ar-DZ</td><td>0x1401</td><td>Arabic (Algeria)</td></tr>
 * <tr><td>ar-BH</td><td>0x3C01</td><td>Arabic (Bahrain)</td></tr>
 * <tr><td>ar-EG</td><td>0x0C01</td><td>Arabic (Egypt)</td></tr>
 * <tr><td>ar-IQ</td><td>0x0801</td><td>Arabic (Iraq)</td></tr>
 * <tr><td>ar-JO</td><td>0x2C01</td><td>Arabic (Jordan)</td></tr>
 * <tr><td>ar-KW</td><td>0x3401</td><td>Arabic (Kuwait)</td></tr>
 * <tr><td>ar-LB</td><td>0x3001</td><td>Arabic (Lebanon)</td></tr>
 * <tr><td>ar-LY</td><td>0x1001</td><td>Arabic (Libya)</td></tr>
 * <tr><td>ar-MA</td><td>0x1801</td><td>Arabic (Morocco)</td></tr>
 * <tr><td>ar-OM</td><td>0x2001</td><td>Arabic (Oman)</td></tr>
 * <tr><td>ar-QA</td><td>0x4001</td><td>Arabic (Qatar)</td></tr>
 * <tr><td>ar-SA</td><td>0x0401</td><td>Arabic (Saudi Arabia)</td></tr>
 * <tr><td>ar-SY</td><td>0x2801</td><td>Arabic (Syria)</td></tr>
 * <tr><td>ar-TN</td><td>0x1C01</td><td>Arabic (Tunisia)</td></tr>
 * <tr><td>ar-AE</td><td>0x3801</td><td>Arabic (U.A.E.)</td></tr>
 * <tr><td>ar-YE</td><td>0x2401</td><td>Arabic (Yemen)</td></tr>
 * <tr><td>hy</td><td>0x002B</td><td>Armenian</td></tr>
 * <tr><td>hy-AM</td><td>0x042B</td><td>Armenian (Armenia)</td></tr>
 * <tr><td>az-Cyrl-AZ</td><td>0x082C</td><td>Azeri (Cyrillic) (Azerbaijan)</td></tr>
 * <tr><td>az-Latn-AZ</td><td>0x042C</td><td>Azeri (Latin) (Azerbaijan)</td></tr>
 * <tr><td>eu</td><td>0x002D</td><td>Basque</td></tr>
 * <tr><td>eu-ES</td><td>0x042D</td><td>Basque (Spain)</td></tr>
 * <tr><td>be</td><td>0x0023</td><td>Belarusian</td></tr>
 * <tr><td>be-BY</td><td>0x0423</td><td>Belarusian (Belarus)</td></tr>
 * <tr><td>bs-Latn-BA</td><td>0x141A</td><td>Bosnian (Bosnia and Herzegovina)</td></tr>
 * <tr><td>bg</td><td>0x0002</td><td>Bulgarian</td></tr>
 * <tr><td>bg-BG</td><td>0x0402</td><td>Bulgarian (Bulgaria)</td></tr>
 * <tr><td>ca</td><td>0x0003</td><td>Catalan</td></tr>
 * <tr><td>ca-ES</td><td>0x0403</td><td>Catalan (Spain)</td></tr>
 * <tr><td>zh</td><td>0x0004</td><td>Chinese</td></tr>
 * <tr><td>zh-HK</td><td>0x0C04</td><td>Chinese (Hong Kong S.A.R.)</td></tr>
 * <tr><td>zh-MO</td><td>0x1404</td><td>Chinese (Macau S.A.R.)</td></tr>
 * <tr><td>zh-CN</td><td>0x0804</td><td>Chinese (People's Republic of China)</td></tr>
 * <tr><td>zh-SG</td><td>0x1004</td><td>Chinese (Singapore)</td></tr>
 * <tr><td>zh-TW</td><td>0x0404</td><td>Chinese (Taiwan)</td></tr>
 * <tr><td>hr</td><td>0x001A</td><td>Croatian</td></tr>
 * <tr><td>hr-BA</td><td>0x101A</td><td>Croatian (Bosnia and Herzegovina)</td></tr>
 * <tr><td>hr-HR</td><td>0x041A</td><td>Croatian (Croatia)</td></tr>
 * <tr><td>cs</td><td>0x0005</td><td>Czech</td></tr>
 * <tr><td>cs-CZ</td><td>0x0405</td><td>Czech (Czech Republic)</td></tr>
 * <tr><td>da</td><td>0x0006</td><td>Danish</td></tr>
 * <tr><td>da-DK</td><td>0x0406</td><td>Danish (Denmark)</td></tr>
 * <tr><td>div</td><td>0x0065</td><td>Divehi</td></tr>
 * <tr><td>dv-MV</td><td>0x0465</td><td>Divehi (Maldives)</td></tr>
 * <tr><td>nl</td><td>0x0013</td><td>Dutch</td></tr>
 * <tr><td>nl-BE</td><td>0x0813</td><td>Dutch (Belgium)</td></tr>
 * <tr><td>nl-NL</td><td>0x0413</td><td>Dutch (Netherlands)</td></tr>
 * <tr><td>en</td><td>0x0009</td><td>English</td></tr>
 * <tr><td>en-AU</td><td>0x0C09</td><td>English (Australia)</td></tr>
 * <tr><td>en-BZ</td><td>0x2809</td><td>English (Belize)</td></tr>
 * <tr><td>en-CA</td><td>0x1009</td><td>English (Canada)</td></tr>
 * <tr><td>en-029</td><td>0x2409</td><td>English (Caribbean)</td></tr>
 * <tr><td>en-IE</td><td>0x1809</td><td>English (Ireland)</td></tr>
 * <tr><td>en-JM</td><td>0x2009</td><td>English (Jamaica)</td></tr>
 * <tr><td>en-NZ</td><td>0x1409</td><td>English (New Zealand)</td></tr>
 * <tr><td>en-PH</td><td>0x3409</td><td>English (Republic of the Philippines)</td></tr>
 * <tr><td>en-ZA</td><td>0x1C09</td><td>English (South Africa)</td></tr>
 * <tr><td>en-TT</td><td>0x2C09</td><td>English (Trinidad and Tobago)</td></tr>
 * <tr><td>en-GB</td><td>0x0809</td><td>English (United Kingdom)</td></tr>
 * <tr><td>en-US</td><td>0x0409</td><td>English (United States)</td></tr>
 * <tr><td>en-ZW</td><td>0x3009</td><td>English (Zimbabwe)</td></tr>
 * <tr><td>et</td><td>0x0025</td><td>Estonian</td></tr>
 * <tr><td>et-EE</td><td>0x0425</td><td>Estonian (Estonia)</td></tr>
 * <tr><td>fo</td><td>0x0038</td><td>Faroese</td></tr>
 * <tr><td>fo-FO</td><td>0x0438</td><td>Faroese (Faroe Islands)</td></tr>
 * <tr><td>fa</td><td>0x0029</td><td>Farsi</td></tr>
 * <tr><td>fa-IR</td><td>0x0429</td><td>Farsi (Iran)</td></tr>
 * <tr><td>fi</td><td>0x000B</td><td>Finnish</td></tr>
 * <tr><td>fi-FI</td><td>0x040B</td><td>Finnish (Finland)</td></tr>
 * <tr><td>fr</td><td>0x000C</td><td>French</td></tr>
 * <tr><td>fr-BE</td><td>0x080C</td><td>French (Belgium)</td></tr>
 * <tr><td>fr-CA</td><td>0x0C0C</td><td>French (Canada)</td></tr>
 * <tr><td>fr-FR</td><td>0x040C</td><td>French (France)</td></tr>
 * <tr><td>fr-LU</td><td>0x140C</td><td>French (Luxembourg)</td></tr>
 * <tr><td>fr-MC</td><td>0x180C</td><td>French (Principality of Monaco)</td></tr>
 * <tr><td>fr-CH</td><td>0x100C</td><td>French (Switzerland)</td></tr>
 * <tr><td>mk</td><td>0x002F</td><td>FYRO Macedonian</td></tr>
 * <tr><td>mk-MK</td><td>0x042F</td><td>FYRO Macedonian (Former Yugoslav Republic of Macedonia)</td></tr>
 * <tr><td>gl</td><td>0x0056</td><td>Galician</td></tr>
 * <tr><td>gl-ES</td><td>0x0456</td><td>Galician (Spain)</td></tr>
 * <tr><td>ka</td><td>0x0037</td><td>Georgian</td></tr>
 * <tr><td>ka-GE</td><td>0x0437</td><td>Georgian (Georgia)</td></tr>
 * <tr><td>de</td><td>0x0007</td><td>German</td></tr>
 * <tr><td>de-AT</td><td>0x0C07</td><td>German (Austria)</td></tr>
 * <tr><td>de-DE</td><td>0x0407</td><td>German (Germany)</td></tr>
 * <tr><td>de-LI</td><td>0x1407</td><td>German (Liechtenstein)</td></tr>
 * <tr><td>de-LU</td><td>0x1007</td><td>German (Luxembourg)</td></tr>
 * <tr><td>de-CH</td><td>0x0807</td><td>German (Switzerland)</td></tr>
 * <tr><td>el</td><td>0x0008</td><td>Greek</td></tr>
 * <tr><td>el-GR</td><td>0x0408</td><td>Greek (Greece)</td></tr>
 * <tr><td>gu</td><td>0x0047</td><td>Gujarati</td></tr>
 * <tr><td>gu-IN</td><td>0x0447</td><td>Gujarati (India)</td></tr>
 * <tr><td>he</td><td>0x000D</td><td>Hebrew</td></tr>
 * <tr><td>he-IL</td><td>0x040D</td><td>Hebrew (Israel)</td></tr>
 * <tr><td>hi</td><td>0x0039</td><td>Hindi</td></tr>
 * <tr><td>hi-IN</td><td>0x0439</td><td>Hindi (India)</td></tr>
 * <tr><td>hu</td><td>0x000E</td><td>Hungarian</td></tr>
 * <tr><td>hu-HU</td><td>0x040E</td><td>Hungarian (Hungary)</td></tr>
 * <tr><td>is</td><td>0x000F</td><td>Icelandic</td></tr>
 * <tr><td>is-IS</td><td>0x040F</td><td>Icelandic (Iceland)</td></tr>
 * <tr><td>id</td><td>0x0021</td><td>Indonesian</td></tr>
 * <tr><td>id-ID</td><td>0x0421</td><td>Indonesian (Indonesia)</td></tr>
 * <tr><td>it</td><td>0x0010</td><td>Italian</td></tr>
 * <tr><td>it-IT</td><td>0x0410</td><td>Italian (Italy)</td></tr>
 * <tr><td>it-CH</td><td>0x0810</td><td>Italian (Switzerland)</td></tr>
 * <tr><td>ja</td><td>0x0011</td><td>Japanese</td></tr>
 * <tr><td>ja-JP</td><td>0x0411</td><td>Japanese (Japan)</td></tr>
 * <tr><td>kn</td><td>0x004B</td><td>Kannada</td></tr>
 * <tr><td>kn-IN</td><td>0x044B</td><td>Kannada (India)</td></tr>
 * <tr><td>kk</td><td>0x003F</td><td>Kazakh</td></tr>
 * <tr><td>kk-KZ</td><td>0x043F</td><td>Kazakh (Kazakhstan)</td></tr>
 * <tr><td>kok</td><td>0x0057</td><td>Konkani</td></tr>
 * <tr><td>kok-IN</td><td>0x0457</td><td>Konkani (India)</td></tr>
 * <tr><td>ko</td><td>0x0012</td><td>Korean</td></tr>
 * <tr><td>ko-KR</td><td>0x0412</td><td>Korean (Korea)</td></tr>
 * <tr><td>ky</td><td>0x0040</td><td>Kyrgyz</td></tr>
 * <tr><td>ky-KG</td><td>0x0440</td><td>Kyrgyz (Kyrgyzstan)</td></tr>
 * <tr><td>lv</td><td>0x0026</td><td>Latvian</td></tr>
 * <tr><td>lv-LV</td><td>0x0426</td><td>Latvian (Latvia)</td></tr>
 * <tr><td>lt</td><td>0x0027</td><td>Lithuanian</td></tr>
 * <tr><td>lt-LT</td><td>0x0427</td><td>Lithuanian (Lithuania)</td></tr>
 * <tr><td>ms</td><td>0x003E</td><td>Malay</td></tr>
 * <tr><td>ms-BN</td><td>0x083E</td><td>Malay (Brunei Darussalam)</td></tr>
 * <tr><td>ms-MY</td><td>0x043E</td><td>Malay (Malaysia)</td></tr>
 * <tr><td>mt</td><td>0x003A</td><td>Maltese</td></tr>
 * <tr><td>mt-MT</td><td>0x043A</td><td>Maltese (Malta)</td></tr>
 * <tr><td>mi</td><td>0x0081</td><td>Maori</td></tr>
 * <tr><td>mi-NZ</td><td>0x0481</td><td>Maori (New Zealand)</td></tr>
 * <tr><td>mr</td><td>0x004E</td><td>Marathi</td></tr>
 * <tr><td>mr-IN</td><td>0x044E</td><td>Marathi (India)</td></tr>
 * <tr><td>mn</td><td>0x0050</td><td>Mongolian</td></tr>
 * <tr><td>mn-MN</td><td>0x0450</td><td>Mongolian (Mongolia)</td></tr>
 * <tr><td>ns</td><td>0x006C</td><td>Northern Sotho</td></tr>
 * <tr><td>nso-ZA</td><td>0x046C</td><td>Northern Sotho (South Africa)</td></tr>
 * <tr><td>nb-NO</td><td>0x0414</td><td>Norwegian (Bokmål) (Norway)</td></tr>
 * <tr><td>nn-NO</td><td>0x0814</td><td>Norwegian (Nynorsk) (Norway)</td></tr>
 * <tr><td>pl</td><td>0x0015</td><td>Polish</td></tr>
 * <tr><td>pl-PL</td><td>0x0415</td><td>Polish (Poland)</td></tr>
 * <tr><td>pt</td><td>0x0016</td><td>Portuguese</td></tr>
 * <tr><td>pt-BR</td><td>0x0416</td><td>Portuguese (Brazil)</td></tr>
 * <tr><td>pt-PT</td><td>0x0816</td><td>Portuguese (Portugal)</td></tr>
 * <tr><td>pa</td><td>0x0046</td><td>Punjabi</td></tr>
 * <tr><td>pa-IN</td><td>0x0446</td><td>Punjabi (India)</td></tr>
 * <tr><td>qu</td><td>0x006B</td><td>Quechua</td></tr>
 * <tr><td>quz-BO</td><td>0x046B</td><td>Quechua (Bolivia)</td></tr>
 * <tr><td>quz-EC</td><td>0x086B</td><td>Quechua (Ecuador)</td></tr>
 * <tr><td>quz-PE</td><td>0x0C6B</td><td>Quechua (Peru)</td></tr>
 * <tr><td>ro</td><td>0x0018</td><td>Romanian</td></tr>
 * <tr><td>ro-RO</td><td>0x0418</td><td>Romanian (Romania)</td></tr>
 * <tr><td>ru</td><td>0x0019</td><td>Russian</td></tr>
 * <tr><td>ru-RU</td><td>0x0419</td><td>Russian (Russia)</td></tr>
 * <tr><td>smn-FI</td><td>0x243B</td><td>Sami (Inari) (Finland)</td></tr>
 * <tr><td>smj-NO</td><td>0x103B</td><td>Sami (Lule) (Norway)</td></tr>
 * <tr><td>smj-SE</td><td>0x143B</td><td>Sami (Lule) (Sweden)</td></tr>
 * <tr><td>se-FI</td><td>0x0C3B</td><td>Sami (Northern) (Finland)</td></tr>
 * <tr><td>se-NO</td><td>0x043B</td><td>Sami (Northern) (Norway)</td></tr>
 * <tr><td>se-SE</td><td>0x083B</td><td>Sami (Northern) (Sweden)</td></tr>
 * <tr><td>sms-FI</td><td>0x203B</td><td>Sami (Skolt) (Finland)</td></tr>
 * <tr><td>sma-NO</td><td>0x183B</td><td>Sami (Southern) (Norway)</td></tr>
 * <tr><td>sma-SE</td><td>0x1C3B</td><td>Sami (Southern) (Sweden)</td></tr>
 * <tr><td>sa</td><td>0x004F</td><td>Sanskrit</td></tr>
 * <tr><td>sa-IN</td><td>0x044F</td><td>Sanskrit (India)</td></tr>
 * <tr><td>sr-Cyrl-BA</td><td>0x1C1A</td><td>Serbian (Cyrillic) (Bosnia and Herzegovina)</td></tr>
 * <tr><td>sr-Cyrl-CS</td><td>0x0C1A</td><td>Serbian (Cyrillic) (Serbia and Montenegro)</td></tr>
 * <tr><td>sr-Latn-BA</td><td>0x181A</td><td>Serbian (Latin) (Bosnia and Herzegovina)</td></tr>
 * <tr><td>sr-Latn-CS</td><td>0x081A</td><td>Serbian (Latin) (Serbia and Montenegro)</td></tr>
 * <tr><td>sk</td><td>0x001B</td><td>Slovak</td></tr>
 * <tr><td>sk-SK</td><td>0x041B</td><td>Slovak (Slovakia)</td></tr>
 * <tr><td>sl</td><td>0x0024</td><td>Slovenian</td></tr>
 * <tr><td>sl-SI</td><td>0x0424</td><td>Slovenian (Slovenia)</td></tr>
 * <tr><td>es</td><td>0x000A</td><td>Spanish</td></tr>
 * <tr><td>es-AR</td><td>0x2C0A</td><td>Spanish (Argentina)</td></tr>
 * <tr><td>es-BO</td><td>0x400A</td><td>Spanish (Bolivia)</td></tr>
 * <tr><td>es-CL</td><td>0x340A</td><td>Spanish (Chile)</td></tr>
 * <tr><td>es-CO</td><td>0x240A</td><td>Spanish (Colombia)</td></tr>
 * <tr><td>es-CR</td><td>0x140A</td><td>Spanish (Costa Rica)</td></tr>
 * <tr><td>es-DO</td><td>0x1C0A</td><td>Spanish (Dominican Republic)</td></tr>
 * <tr><td>es-EC</td><td>0x300A</td><td>Spanish (Ecuador)</td></tr>
 * <tr><td>es-SV</td><td>0x440A</td><td>Spanish (El Salvador)</td></tr>
 * <tr><td>es-GT</td><td>0x100A</td><td>Spanish (Guatemala)</td></tr>
 * <tr><td>es-HN</td><td>0x480A</td><td>Spanish (Honduras)</td></tr>
 * <tr><td>es-MX</td><td>0x080A</td><td>Spanish (Mexico)</td></tr>
 * <tr><td>es-NI</td><td>0x4C0A</td><td>Spanish (Nicaragua)</td></tr>
 * <tr><td>es-PA</td><td>0x180A</td><td>Spanish (Panama)</td></tr>
 * <tr><td>es-PY</td><td>0x3C0A</td><td>Spanish (Paraguay)</td></tr>
 * <tr><td>es-PE</td><td>0x280A</td><td>Spanish (Peru)</td></tr>
 * <tr><td>es-PR</td><td>0x500A</td><td>Spanish (Puerto Rico)</td></tr>
 * <tr><td>es-ES</td><td>0x0C0A</td><td>Spanish (Spain)</td></tr>
 * <tr><td>es-ES_tradnl</td><td>0x040A</td><td>Spanish (Spain)</td></tr>
 * <tr><td>es-UY</td><td>0x380A</td><td>Spanish (Uruguay)</td></tr>
 * <tr><td>es-VE</td><td>0x200A</td><td>Spanish (Venezuela)</td></tr>
 * <tr><td>sw</td><td>0x0041</td><td>Swahili</td></tr>
 * <tr><td>sw-KE</td><td>0x0441</td><td>Swahili (Kenya)</td></tr>
 * <tr><td>sv</td><td>0x001D</td><td>Swedish</td></tr>
 * <tr><td>sv-FI</td><td>0x081D</td><td>Swedish (Finland)</td></tr>
 * <tr><td>sv-SE</td><td>0x041D</td><td>Swedish (Sweden)</td></tr>
 * <tr><td>syr</td><td>0x005A</td><td>Syriac</td></tr>
 * <tr><td>syr-SY</td><td>0x045A</td><td>Syriac (Syria)</td></tr>
 * <tr><td>ta</td><td>0x0049</td><td>Tamil</td></tr>
 * <tr><td>ta-IN</td><td>0x0449</td><td>Tamil (India)</td></tr>
 * <tr><td>tt</td><td>0x0044</td><td>Tatar</td></tr>
 * <tr><td>tt-RU</td><td>0x0444</td><td>Tatar (Russia)</td></tr>
 * <tr><td>te</td><td>0x004A</td><td>Telugu</td></tr>
 * <tr><td>te-IN</td><td>0x044A</td><td>Telugu (India)</td></tr>
 * <tr><td>th</td><td>0x001E</td><td>Thai</td></tr>
 * <tr><td>th-TH</td><td>0x041E</td><td>Thai (Thailand)</td></tr>
 * <tr><td>tn</td><td>0x0032</td><td>Tswana</td></tr>
 * <tr><td>tn-ZA</td><td>0x0432</td><td>Tswana (South Africa)</td></tr>
 * <tr><td>tr</td><td>0x001F</td><td>Turkish</td></tr>
 * <tr><td>tr-TR</td><td>0x041F</td><td>Turkish (Turkey)</td></tr>
 * <tr><td>uk</td><td>0x0022</td><td>Ukrainian</td></tr>
 * <tr><td>uk-UA</td><td>0x0422</td><td>Ukrainian (Ukraine)</td></tr>
 * <tr><td>ur</td><td>0x0020</td><td>Urdu</td></tr>
 * <tr><td>ur-PK</td><td>0x0420</td><td>Urdu (Islamic Republic of Pakistan)</td></tr>
 * <tr><td>uz-Cyrl-UZ</td><td>0x0843</td><td>Uzbek (Cyrillic) (Uzbekistan)</td></tr>
 * <tr><td>uz-Latn-UZ</td><td>0x0443</td><td>Uzbek (Latin) (Uzbekistan)</td></tr>
 * <tr><td>vi</td><td>0x002A</td><td>Vietnamese</td></tr>
 * <tr><td>vi-VN</td><td>0x042A</td><td>Vietnamese (Viet Nam)</td></tr>
 * <tr><td>cy</td><td>0x0052</td><td>Welsh</td></tr>
 * <tr><td>cy-GB</td><td>0x0452</td><td>Welsh (United Kingdom)</td></tr>
 * <tr><td>xh</td><td>0x0034</td><td>Xhosa</td></tr>
 * <tr><td>xh-ZA</td><td>0x0434</td><td>Xhosa (South Africa)</td></tr>
 * <tr><td>zu</td><td>0x0035</td><td>Zulu</td></tr>
 * <tr><td>zu-ZA</td><td>0x0435</td><td>Zulu (South Africa)</td></tr>
 * </table>
 *
 * Cultures are split into three divisions: invariant, neutral and specific. The invariant culture is culturally independent. 
 * It is associated with the English language but not with any country. A neutral culture is associated with a language but not 
 * with a country. A specific culture is associated with a language and a country. For example, "nl" by itself is a neutral culture 
 * but "nl-NL" is a specific culture.
 *
 * Examples:
 * ---
 * import std.stdio, juno.intl.all;
 *
 * void main() {
 *   // Create and initialize the Dutch (Netherlands) Culture object.
 *   Culture culture = new Culture("nl-NL");
 *
 *   // Display some properties of the culture.
 *   writefln("%-30s%s", "displayName", culture.displayName);
 *   writefln("%-30s%s", "englishName", culture.englishName);
 *   writefln("%-30s%s", "nativeName", culture.nativeName);
 *   writefln("%-30s%s", "languageName", culture.languageName);
 *   writefln("%-30s%s", "name", culture.name);
 *   writefln("%-30s0x%X", "lcid", culture.lcid);
 *   writefln("%-30s%s", "isNeutral", culture.isNeutral);
 * }
 *
 * /+
 *  Produces the following output:
 * 
 *  displayName                   Dutch (Netherlands)
 *  englishName                   Dutch (Netherlands)
 *  nativeName                    Nederlands (Nederland)
 *  languageName                  nl
 *  name                          nl-NL
 *  lcid                          0x413
 *  isNeutral                     false
 *  +/
 * ---
 *
 * ---
 * import std.stdio, juno.intl.all;
 *
 * void main() {
 *   // Create and initialize the Dutch (Netherlands) Culture object.
 *   Culture culture = new Culture("nl-NL");
 * }
 * ---
 */
public class Culture : IProvidesFormat {

  private uint cultureId_;
  private char[] cultureName_;
  private bool isReadOnly_;
  private bool isInherited_;
  private bool userOverrides_;
  private Culture parent_;
  private Calendar calendar_;

  private NumberFormat numberFormat_;
  private DateTimeFormat dateTimeFormat_;
  private Collation collation_;

  private char[] listSeparator_;

  private static Culture invariantCulture_;
  private static Culture currentCulture_;
  private static Culture currentUICulture_;
  private static Culture userDefaultCulture_;
  private static Culture userDefaultUICulture_;

  private static Culture[char[]] namedCultures_;
  private static Culture[uint] lcidCultures_;

  static this() {
    invariantCulture_ = new Culture(LOCALE_INVARIANT, false);
    invariantCulture_.isReadOnly_ = true;

    userDefaultCulture_ = initUserDefaultCulture();
    userDefaultUICulture_ = initUserDefaultUICulture();
  }

  static ~this() {
    namedCultures_ = null;
    lcidCultures_ = null;
    invariantCulture_ = null;
    currentCulture_ = null;
    currentUICulture_ = null;
    userDefaultCulture_ = null;
    userDefaultUICulture_ = null;
  }

  /**
   * Creates a new instance of the Culture class based on the _culture specified by the culture identifier.
   * Params:
   *   culture = A predefined Culture identifier.
   *   userOverrides = A value denoting whether to use user-selected _culture settings (true) or default _culture settings (false).
   */
  public this(uint culture, bool userOverrides = true) {
    if (culture == LOCALE_NEUTRAL || culture == LOCALE_SYSTEM_DEFAULT || culture == LOCALE_USER_DEFAULT)
      throw new ArgumentException(format("Culture ID {0} (0x{0:X4}) is not a supported culture.", culture), "culture");

    if (!findCultureFromId(culture, cultureName_, cultureId_))
      throw new ArgumentException(format("Culture ID {0} (0x{0:X4}) is not a supported culture.", culture), "culture");

    isInherited_ = typeid(typeof(this)) !is typeid(Culture);
  }

  /**
   * Creates a new instance of the Culture class based on the culture specified by name.
   * Params:
   *   name = A predefined Culture _name.
   *   userOverrides = A value denoting whether to use user-selected culture settings (true) or default culture settings (false).
   */
  public this(char[] name, bool userOverrides = true) {
    if (!findCultureFromName(name, cultureName_, cultureId_))
      throw new ArgumentException("Culture name '" ~ name ~ "' is not supported.", "name");

    userOverrides_ = userOverrides;
    isInherited_ = typeid(typeof(this)) !is typeid(Culture);
  }

  public override char[] toString() {
    return cultureName_;
  }

  /**
   * Returns an object the defines how to format the specified _type.
   * Params: type = The TypeInfo for which to get a formatting object. Supports the NumberFormat and DateTimeFormat types.
   */
  public Object getFormat(TypeInfo type) {
    if (type is typeid(NumberFormat))
      return numberFormat;
    else if (type is typeid(DateTimeFormat))
      return dateTimeFormat;
    return null;
  }

  public Object clone() {
    Culture culture = cast(Culture)cloneObject(this);
    if (!culture.isNeutral) {
      if (dateTimeFormat_ !is null)
        culture.dateTimeFormat_ = cast(DateTimeFormat)dateTimeFormat_.clone();
      if (numberFormat_ !is null)
        culture.numberFormat_ = cast(NumberFormat)numberFormat_.clone();
    }
    if (calendar_ !is null)
      culture.calendar_ = cast(Calendar)calendar_.clone();
    return culture;
  }

  /**
   * Creates a Culture representing the specific culture associated with the specified _name.
   * Params: name = A predefined Culture _name.
   * Returns: A Culture representing the specific culture associated with name.
   */
  public static Culture specificCulture(char[] name) {
    Culture culture = null;
    try {
      culture = new Culture(name);
    }
    catch (ArgumentException ex) {
      foreach (i, c; name) {
        if (c == '-') {
          try {
            culture = new Culture(name[0 .. i]);
          }
          catch (ArgumentException) {
          }
        }
      }
      if (culture is null)
        throw ex;
    }
    if (!culture.isNeutral)
      return culture;
    return new Culture(getSpecificCulture(name));
  }

  /**
   * Retrieves a cached, read-only instance of a _culture using the specified _culture identifier.
   * Params: name = A _culture identifier.
   * Returns: A read-only Culture object.
   */
  public static Culture getCulture(uint culture) {
    Culture result = getCultureWorker(culture, null);
    if (result is null)
      throw new ArgumentException("Culture ID is not supported.", "culture");
    return result;
  }

  /**
   * Retrieves a cached, read-only instance of a culture using the specified culture _name.
   * Params: name = The _name of a culture.
   * Returns: A read-only Culture object.
   */
  public static Culture getCulture(char[] name) {
    Culture result = getCultureWorker(0, name);
    if (result is null)
      throw new ArgumentException("Culture '" ~ name ~ "' is not supported.", "culture");
    return result;
  }

  private static Culture getCultureWorker(uint lcid, char[] name) {

    char[] toLower(char[] s) {
      foreach (inout c; s) {
        if (c <= 'Z' && c >= 'A')
          c = c - 'A' + 'a';
      }
      return s;
    }

    if (name != null)
      name = toLower(name);

    if (lcid == 0) {
      if (auto culture = name in namedCultures_)
        return *culture;
    }
    else if (lcid > 0) {
      if (auto culture = lcid in lcidCultures_)
        return *culture;
    }

    Culture culture = null;

    try {
      if (lcid == 0)
        culture = new Culture(name, false);
      else if (userDefaultCulture_ !is null && userDefaultCulture_.lcid == lcid)
        culture = userDefaultCulture_;
      else
        culture = new Culture(lcid, false);
    }
    catch (ArgumentException) {
      return null;
    }

    culture.isReadOnly_ = true;

    namedCultures_[culture.name] = culture;
    lcidCultures_[culture.lcid] = culture;

    return culture;
  }

  /**
   * Retrieves a list of cultures filtered by the specified CultureTypes parameter.
   * Params: types = A combination of CultureTypes values that filter the cultures to retrieve.
   * Returns: An array of type Culture containing the cultures specified by types.
   */
  public static Culture[] getCultures(CultureTypes types) {
    if (types < CultureTypes.min || types > CultureTypes.max)
      throw new ArgumentOutOfRangeException("types", "Valid values are between Neutral and Installed.");

    bool includeSpecific = (types & CultureTypes.Specific) != 0;
    bool includeNeutral = (types & CultureTypes.Neutral) != 0;
    bool includeInstalled = (types & CultureTypes.Installed) != 0;

    int[] cultures;
    foreach (name, culture; nameToLcidTable) {
      if (((culture >> 16) & 0xf) == 0) {
        if ((includeNeutral && (isNeutralCulture(culture) || name.length == 0)) ||
          (includeSpecific && (!isNeutralCulture(culture) && name.length > 0)) ||
          (includeInstalled && IsValidLocale(culture, LCID_INSTALLED)))
          cultures ~= culture;
      }
    }

    Culture[] result = new Culture[cultures.length];
    foreach (i, culture; cultures)
      result[i] = new Culture(culture);
    return result;
  }

  /**
   * <i>Property.</i>
   * Retrives or assigns the culture used by the current thread.
   */
  public static Culture currentCulture() {
    if (currentCulture_ !is null)
      return currentCulture_;

    return userDefaultCulture;
  }
  /**
   * Ditto
   */
  public static void currentCulture(Culture value) {
    if (value is null)
      throw new ArgumentNullException("value");

    checkNeutral(value);
    SetThreadLocale(value.lcid);
    currentCulture_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves the current culture used by the user interface.
   */
  public static Culture currentUICulture() {
    if (currentUICulture_ !is null)
      return currentUICulture_;

    return userDefaultUICulture;
  }
  public static void currentUICulture(Culture value) {
    if (value is null)
      throw new ArgumentNullException("value");

    currentUICulture_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves the Culture that is culture-independent.
   */
  public static Culture invariantCulture() {
    return invariantCulture_;
  }

  /**
   * <i>Property.</i>
   * Retrieves the Culture representing the _parent culture of the current instance.
   */
  public Culture parent() {
    if (parent_ is null) {
      try {
        // The parent of a specific culture is a neutral culture.
        // The parent of a neutral culture is the invariant culture.
        uint parentCulture = cultureId_ & 0x3FF;
        if (parentCulture == LOCALE_INVARIANT || isNeutralCulture(cultureId_))
          parent_ = invariantCulture;
        else
          parent_ = new Culture(parentCulture, userOverrides_);
      }
      catch (ArgumentException) {
        parent_ = invariantCulture;
      }
    }
    return parent_;
  }

  /**
   * <i>Property.</i>
   * Retrieves the culture _name in the form "&lt;languagecode&gt;-&lt;countrycode&gt;".
   */
  public char[] name() {
    return cultureName_;
  }

  /**
   * <i>Property.</i>
   * Retrives the culture identifier for the current instance.
   */
  public uint lcid() {
    return cultureId_;
  }

  /**
   * <i>Property.</i>
   * Retrieves the culture name in the form "&lt;language&gt; (&lt;country&gt;)" in the language of the localised version of Windows.
   */
  public char[] displayName() {
    if (LANGIDFROMLCID(GetUserDefaultLangID()) == LANGIDFROMLCID(Culture.currentUICulture.lcid)) {
      char[] ret = getLocaleInfo(cultureId_, LOCALE_SLANGUAGE);
      if (ret != null && isNeutralCulture(cultureId_) && cultureId_ != LOCALE_INVARIANT) {
        // Remove country name from neutral cultures.
        int i = Culture.invariantCulture.collation.lastIndexOf(ret, "(");
        if (i != -1 && Culture.invariantCulture.collation.lastIndexOf(ret, "(") != -1)
          ret.length = i - 1;
      }
      if (ret != null && !isNeutralCulture(cultureId_) && cultureId_ != LOCALE_INVARIANT) {
        // Add country name to specific cultures (if not present already).
        if (Culture.invariantCulture.collation.indexOf(ret, "(") == -1 && Culture.invariantCulture.collation.indexOf(ret, ")") == -1)
          ret ~= " (" ~ getLocaleInfo(cultureId_, LOCALE_SCOUNTRY) ~ ")";
      }
      if (ret != null)
        return ret;
    }
    return nativeName;
  }

  /**
   * <i>Property.</i>
   * Retrieves the culture name in the form "&lt;language&gt; (&lt;country&gt;)" in the language that the culture is set to display.
   */
  public char[] nativeName() {
    char[] ret = getLocaleInfo(cultureId_, LOCALE_SNATIVELANGNAME);
    if (!isNeutralCulture(cultureId_))
      ret ~= " (" ~ getLocaleInfo(cultureId_, LOCALE_SNATIVECTRYNAME) ~ ")";
    else {
      int i = Culture.invariantCulture.collation.lastIndexOf(ret, "(");
      if (i != -1 && Culture.invariantCulture.collation.lastIndexOf(ret, ")") != -1)
        ret.length = i - 1;
    }
    return ret;
  }

  /**
   * <i>Property.</i>
   * Retrieves the culture name in the form "&lt;language&gt; (&lt;country&gt;)" in English.
   */
  public char[] englishName() {
    char[] ret = getLocaleInfo(cultureId_, LOCALE_SENGLANGUAGE);
    if (!isNeutralCulture(cultureId_))
      ret ~= " (" ~ getLocaleInfo(cultureId_, LOCALE_SENGCOUNTRY) ~ ")";
    else {
      int i = Culture.invariantCulture.collation.lastIndexOf(ret, "(");
      if (i != -1 && Culture.invariantCulture.collation.lastIndexOf(ret, ")") != -1)
        ret.length = i - 1;
    }
    return ret;
  }

  /**
   * <i>Property.</i>
   * Retrieves the two-letter ISO 639-1 code for the language.
   */
  public char[] languageName() {
    return getLocaleInfo(cultureId_, LOCALE_SISO639LANGNAME);
  }

  /**
   * <i>Property.</i>
   * Retrieves a value indicating whether the current instance is read-only.
   * Returns: true if the current Culture is read-only; otherwise, false.
   */
  public final bool isReadOnly() {
    return isReadOnly_;
  }

  /**
   * <i>Property.</i>
   * Retrieves a value indicating whether the current instance represents a neutral culture.
   * Returns: true if the current Culture represents a neutral culture; otherwise, false.
   */
  public bool isNeutral() {
    return isNeutralCulture(cultureId_);
  }

  /**
   * <i>Property.</i>
   * Retrieves the Collation defining how to compare strings for the culture.
   */
  public Collation collation() {
    if (collation_ is null) {
      collation_ = new Collation(cultureId_);
      collation_.isReadOnly_ = isReadOnly_;
    }
    return collation_;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the NumberFormat defining the culturally appropriate format of displaying numbers, currency and percentage.
   */
  public NumberFormat numberFormat() {
    if (numberFormat_ is null) {
      numberFormat_ = new NumberFormat(cultureId_, userOverrides_);
      numberFormat_.isReadOnly_ = true;
    }
    return numberFormat_;
  }
  /**
   * Ditto
   */
  public void numberFormat(NumberFormat value) {
    checkReadOnly();
    numberFormat_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the DateTimeFormat defining the culturally appropriate format of displaying dates and times.
   */
  public DateTimeFormat dateTimeFormat() {
    if (dateTimeFormat_ is null) {
      dateTimeFormat_ = new DateTimeFormat(cultureId_, userOverrides_, calendar);
      dateTimeFormat_.isReadOnly_ = true;
    }
    return dateTimeFormat_;
  }
  /**
   * Ditto
   */
  public void dateTimeFormat(DateTimeFormat value) {
    checkReadOnly();
    dateTimeFormat_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves the default _calendar used by the culture.
   */
  public Calendar calendar() {
    if (calendar_ is null)
      calendar_ = getCalendarInstance(getLocaleInfoI(cultureId_, LOCALE_ICALENDARTYPE));
    return calendar_;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the string that separates items in a list.
   */
  public char[] listSeparator() {
    if (listSeparator_ == null)
      listSeparator_ = getLocaleInfo(cultureId_, LOCALE_SLIST);
    return listSeparator_;
  }
  /**
   * Ditto
   */
  public void listSeparator(char[] value) {
    checkReadOnly();
    listSeparator_ = value;
  }

  private static Culture initUserDefaultCulture() {
    Culture culture = null;

    try {
      culture = new Culture(GetUserDefaultLCID());
    }
    catch (ArgumentException) {
    }

    if (culture is null)
      culture = invariantCulture;
    culture.isReadOnly_ = true;

    return culture;
  }

  private static Culture initUserDefaultUICulture() {
    Culture culture = null;

    if (GetUserDefaultLangID() == userDefaultCulture.lcid)
      return userDefaultCulture;

    try {
      culture = new Culture(GetSystemDefaultLangID());
    }
    catch (ArgumentException) {
    }

    if (culture is null)
      culture = invariantCulture;
    culture.isReadOnly_ = true;

    return culture;
  }

  // Currently, only GregorianCalendar is implemented.
  private static Calendar getCalendarInstance(int calType) {
    switch (calType) {
      case CAL_GREGORIAN:
      case CAL_GREGORIAN_US:
      case CAL_GREGORIAN_ME_FRENCH:
      case CAL_GREGORIAN_ARABIC:
      case CAL_GREGORIAN_XLIT_ENGLISH:
      case CAL_GREGORIAN_XLIT_FRENCH:
        return new GregorianCalendar(cast(GregorianCalendarTypes)calType);
      case CAL_JAPAN:
      case CAL_TAIWAN:
      case CAL_KOREA:
      case CAL_HIJRI:
      case CAL_THAI:
      case CAL_HEBREW:
        break;
      default:
    }
    return new GregorianCalendar;
  }

  private static void checkNeutral(Culture culture) {
    if (culture.isNeutral)
      throw new NotSupportedException("Culture '" ~ culture.cultureName_ ~ "' is a neutral culture and cannot be used in formatting.");
  }

  private void checkReadOnly() {
    if (isReadOnly_)
      throw new InvalidOperationException("Instance is read-only.");
  }

  private static Culture userDefaultCulture() {
    if (userDefaultCulture_ is null)
      userDefaultCulture_ = initUserDefaultCulture();
    return userDefaultCulture_;
  }

  private static Culture userDefaultUICulture() {
    if (userDefaultUICulture_ is null)
      userDefaultUICulture_ = initUserDefaultUICulture();
    return userDefaultUICulture_;
  }

}
/**
 * Contains information about a country.
 *
 * Region does not represent user preferences and does not depend on the user's language or culture (locale).
 *
 * The region name is one of the two-letter codes defined in ISO 3166 for country. The following is a list of the 
 * predefined Region names accepted and used by this class.
 *
 * <table>
 * <tr><td><b>ISO 3166 code</b>&nbsp;&nbsp;</td><td><b>Country</b></td></tr>
 * <tr><td>AE</td><td>U.A.E.</td></tr>
 * <tr><td>AL</td><td>Albania</td></tr>
 * <tr><td>AM</td><td>Armenia</td></tr>
 * <tr><td>AR</td><td>Argentina</td></tr>
 * <tr><td>AT</td><td>Austria</td></tr>
 * <tr><td>AU</td><td>Australia</td></tr>
 * <tr><td>AZ</td><td>Azerbaijan</td></tr>
 * <tr><td>BA</td><td>Bosnia and Herzegovina</td></tr>
 * <tr><td>BE</td><td>Belgium</td></tr>
 * <tr><td>BG</td><td>Bulgaria</td></tr>
 * <tr><td>BH</td><td>Bahrain</td></tr>
 * <tr><td>BN</td><td>Brunei Darussalam</td></tr>
 * <tr><td>BO</td><td>Bolivia</td></tr>
 * <tr><td>BR</td><td>Brazil</td></tr>
 * <tr><td>BY</td><td>Belarus</td></tr>
 * <tr><td>BZ</td><td>Belize</td></tr>
 * <tr><td>CA</td><td>Canada</td></tr>
 * <tr><td>CB</td><td>Caribbean</td></tr>
 * <tr><td>CH</td><td>Switzerland</td></tr>
 * <tr><td>CL</td><td>Chile</td></tr>
 * <tr><td>CN</td><td>People's Republic of China</td></tr>
 * <tr><td>CO</td><td>Colombia</td></tr>
 * <tr><td>CR</td><td>Costa Rica</td></tr>
 * <tr><td>CZ</td><td>Czech Republic</td></tr>
 * <tr><td>DE</td><td>Germany</td></tr>
 * <tr><td>DK</td><td>Denmark</td></tr>
 * <tr><td>DO</td><td>Dominican Republic</td></tr>
 * <tr><td>DZ</td><td>Algeria</td></tr>
 * <tr><td>EC</td><td>Ecuador</td></tr>
 * <tr><td>EE</td><td>Estonia</td></tr>
 * <tr><td>EG</td><td>Egypt</td></tr>
 * <tr><td>ES</td><td>Spain</td></tr>
 * <tr><td>FI</td><td>Finland</td></tr>
 * <tr><td>FO</td><td>Faroe Islands</td></tr>
 * <tr><td>FR</td><td>France</td></tr>
 * <tr><td>GB</td><td>United Kingdom</td></tr>
 * <tr><td>GE</td><td>Georgia</td></tr>
 * <tr><td>GR</td><td>Greece</td></tr>
 * <tr><td>GT</td><td>Guatemala</td></tr>
 * <tr><td>HK</td><td>Hong Kong S.A.R.</td></tr>
 * <tr><td>HN</td><td>Honduras</td></tr>
 * <tr><td>HR</td><td>Croatia</td></tr>
 * <tr><td>HU</td><td>Hungary</td></tr>
 * <tr><td>ID</td><td>Indonesia</td></tr>
 * <tr><td>IE</td><td>Ireland</td></tr>
 * <tr><td>IL</td><td>Israel</td></tr>
 * <tr><td>IN</td><td>India</td></tr>
 * <tr><td>IQ</td><td>Iraq</td></tr>
 * <tr><td>IR</td><td>Iran</td></tr>
 * <tr><td>IS</td><td>Iceland</td></tr>
 * <tr><td>IT</td><td>Italy</td></tr>
 * <tr><td>JM</td><td>Jamaica</td></tr>
 * <tr><td>JO</td><td>Jordan</td></tr>
 * <tr><td>JP</td><td>Japan</td></tr>
 * <tr><td>KE</td><td>Kenya</td></tr>
 * <tr><td>KG</td><td>Kyrgyzstan</td></tr>
 * <tr><td>KR</td><td>Korea</td></tr>
 * <tr><td>KW</td><td>Kuwait</td></tr>
 * <tr><td>KZ</td><td>Kazakhstan</td></tr>
 * <tr><td>LB</td><td>Lebanon</td></tr>
 * <tr><td>LI</td><td>Liechtenstein</td></tr>
 * <tr><td>LT</td><td>Lithuania</td></tr>
 * <tr><td>LU</td><td>Luxembourg</td></tr>
 * <tr><td>LV</td><td>Latvia</td></tr>
 * <tr><td>LY</td><td>Libya</td></tr>
 * <tr><td>MA</td><td>Morocco</td></tr>
 * <tr><td>MC</td><td>Principality of Monaco</td></tr>
 * <tr><td>MK</td><td>Former Yugoslav Republic of Macedonia</td></tr>
 * <tr><td>MN</td><td>Mongolia</td></tr>
 * <tr><td>MO</td><td>Macau S.A.R.</td></tr>
 * <tr><td>MT</td><td>Malta</td></tr>
 * <tr><td>MV</td><td>Maldives</td></tr>
 * <tr><td>MX</td><td>Mexico</td></tr>
 * <tr><td>MY</td><td>Malaysia</td></tr>
 * <tr><td>NI</td><td>Nicaragua</td></tr>
 * <tr><td>NL</td><td>Netherlands</td></tr>
 * <tr><td>NO</td><td>Norway</td></tr>
 * <tr><td>NZ</td><td>New Zealand</td></tr>
 * <tr><td>OM</td><td>Oman</td></tr>
 * <tr><td>PA</td><td>Panama</td></tr>
 * <tr><td>PE</td><td>Peru</td></tr>
 * <tr><td>PH</td><td>Republic of the Philippines</td></tr>
 * <tr><td>PK</td><td>Islamic Republic of Pakistan</td></tr>
 * <tr><td>PL</td><td>Poland</td></tr>
 * <tr><td>PR</td><td>Puerto Rico</td></tr>
 * <tr><td>PT</td><td>Portugal</td></tr>
 * <tr><td>PY</td><td>Paraguay</td></tr>
 * <tr><td>QA</td><td>Qatar</td></tr>
 * <tr><td>RO</td><td>Romania</td></tr>
 * <tr><td>RU</td><td>Russia</td></tr>
 * <tr><td>SA</td><td>Saudi Arabia</td></tr>
 * <tr><td>SE</td><td>Sweden</td></tr>
 * <tr><td>SG</td><td>Singapore</td></tr>
 * <tr><td>SI</td><td>Slovenia</td></tr>
 * <tr><td>SK</td><td>Slovakia</td></tr>
 * <tr><td>SP</td><td>Serbia and Montenegro</td></tr>
 * <tr><td>SV</td><td>El Salvador</td></tr>
 * <tr><td>SY</td><td>Syria</td></tr>
 * <tr><td>TH</td><td>Thailand</td></tr>
 * <tr><td>TN</td><td>Tunisia</td></tr>
 * <tr><td>TR</td><td>Turkey</td></tr>
 * <tr><td>TT</td><td>Trinidad and Tobago</td></tr>
 * <tr><td>TW</td><td>Taiwan</td></tr>
 * <tr><td>UA</td><td>Ukraine</td></tr>
 * <tr><td>US</td><td>United States</td></tr>
 * <tr><td>UY</td><td>Uruguay</td></tr>
 * <tr><td>UZ</td><td>Uzbekistan</td></tr>
 * <tr><td>VE</td><td>Venezuela</td></tr>
 * <tr><td>VN</td><td>Viet Nam</td></tr>
 * <tr><td>YE</td><td>Yemen</td></tr>
 * <tr><td>ZA</td><td>South Africa</td></tr>
 * <tr><td>ZW</td><td>Zimbabwe</td></tr>
 * </table>
 */
public class Region {

  private static Region currentRegion_;

  private uint cultureId_;
  private char[] name_;

  static ~this() {
    currentRegion_ = null;
  }

  /**
   * Creates a new instance based on the country associated with the specified _culture identifier.
   * Params: culture = A _culture identifier.
   */
  public this(uint culture) {
    if (culture == LOCALE_INVARIANT)
      throw new ArgumentException("No region is associated with the Invariant Culture (Culture ID: 0x7F).");

    if (SUBLANGID(culture) == 0)
      throw new ArgumentException("Culture ID is a neutral culture; a region cannot be created from it.");

    name_ = getLocaleInfo(culture, LOCALE_SISO3166CTRYNAME);
    cultureId_ = culture;
  }

  /**
   * Creates a new instance based on the country or specific culture specified by name.
   * Params:
   *        name = A string containing the two-letter code defined in ISO 3166 for country.$(BR)
   *        -or-$(BR)
   *        A string containing the culture _name for a specific culture.
   */
  public this(char[] name) {
    name_ = Culture.invariantCulture.collation.toUpper(name);
    cultureId_ = 0;

    if (!findCultureFromRegionName(name, cultureId_))
      throw new ArgumentException("Region name '" ~ name ~ "' is not supported.", "name");

    if (isNeutralCulture(cultureId_))
      throw new ArgumentException("Region name '" ~ name ~ "' should not correspond to a neutral culture; a specific culture name is required.", "name");
  }

  /**
   * <i>Property.</i>
   * Retrieves the Region representing the country used by the current culture.
   */
  public static Region currentRegion() {
    if (currentRegion_ is null)
      currentRegion_ = new Region(Culture.currentCulture.lcid);
    return currentRegion_;
  }

  /**
   * <i>Property.</i>
   * Retrieves a unique number identifying a geographical region, country, city or location.
   */
  public int geoId() {
    return getLocaleInfoI(cultureId_, LOCALE_IGEOID);
  }

  /**
   * <i>Property.</i>
   * Retrieves the _name or ISO 3166 two-letter country code.
   */
  public char[] name() {
    if (name_ == null)
      name_ = getLocaleInfo(cultureId_, LOCALE_SISO3166CTRYNAME);
    return name_;
  }

  /**
   * <i>Property.</i>
   * Retrieves the name of the country in the native language of the country.
   */
  public char[] nativeName() {
    return getLocaleInfo(cultureId_, LOCALE_SNATIVECTRYNAME);
  }

  /**
   * <i>Property.</i>
   * Retrieves the full name of the country in the localized Windows version.
   */
  public char[] displayName() {
    if (LANGIDFROMLCID(GetUserDefaultLangID()) == LANGIDFROMLCID(Culture.currentUICulture.lcid))
      return getLocaleInfo(cultureId_, LOCALE_SCOUNTRY);
    return nativeName;
  }

  /**
   * <i>Property.</i>
   * Retrieves the full name of the country in English.
   */
  public char[] englishName() {
    return getLocaleInfo(cultureId_, LOCALE_SENGCOUNTRY);
  }

  /**
   * <i>Property.</i>
   * Retrieves the offical full name of the country.
   */
  public char[] officialName() {
    return getGeoInfo(geoId, GEO_OFFICIALNAME);
  }

  /**
   * <i>Property.</i>
   * Retrieves the two-letter code defined in ISO 3166 for the country.
   */
  public char[] isoRegionName() {
    return getGeoInfo(geoId, GEO_ISO2);
  }

  /**
   * <i>Property.</i>
   * Retrieves a value indicating whether the country uses the metric system for measurements.
   */
  public bool isMetric() {
    return getLocaleInfoI(cultureId_, LOCALE_IMEASURE) == 0;
  }

  /**
   * <i>Property.</i>
   * Retrieves the currency symbol associated with the country.
   */
  public char[] currencySymbol() {
    return getLocaleInfo(cultureId_, LOCALE_SCURRENCY);
  }

  /**
   * <i>Property.</i>
   * Retrieves the ISO 4217 currency symbol associated with the country.
   */
  public char[] isoCurrencySymbol() {
    return getLocaleInfo(cultureId_, LOCALE_SINTLSYMBOL);
  }

  /**
   * <i>Property.</i>
   * Retrieves the name, in the native language of the country, of the currency used in the country.
   */
  public char[] currencyNativeName() {
    return getLocaleInfo(cultureId_, LOCALE_SNATIVECURRNAME);
  }

  /**
   * <i>Property.</i>
   * Retrieves the name, in English, of the currency used in the country.
   */
  public char[] currencyEnglishName() {
    return getLocaleInfo(cultureId_, LOCALE_SENGCURRNAME);
  }

  /**
   * <i>Property.</i>
   * Retrieves the _latitude of the country.
   */
  public double latitude() {
    char[] s = getGeoInfo(geoId, GEO_LATITUDE);
    return juno.base.string.parse!(double)(s);
  }

  /**
   * <i>Property.</i>
   * Retrieves the _longitude of the country.
   */
  public double longitude() {
    char[] s = getGeoInfo(geoId, GEO_LONGITUDE);
    return juno.base.string.parse!(double)(s);
  }

}

/** 
 * Provides methods for culture-sensitive string comparisons.
 *
 * Collation provides getCollation methods instead of public constructors. To create a Collation for a culture, use the Culture.collation property or 
 * the getCollation method.
 */
public class Collation {

  private static Collation[uint] collationCache_;

  private uint culture_;
  private char[] name_;
  private uint sortingId_;
  private bool isReadOnly_;

  static ~this() {
    collationCache_ = null;
  }

  /**
   * Creates a new instance of the Collation class that is associated with the _culture having the specified identifier.
   * Params: culture = A value representing the _culture identifier.
   * Returns: A new instance of the Collation class that is associated with the _culture having the specified identifier.
   */
  public static Collation getCollation(uint culture) {
    if (auto ret = culture in collationCache_)
      return *ret;
    Collation collation = new Collation(culture);
    collationCache_[culture] = collation;
    return collation;
  }

  /**
   * Creates a new instance of the Collation class that is associated with the culture having the specified _name.
   * Params: name = A string representing the culture _name.
   * Returns: A new instance of the Collation class that is associated with the culture having the specified _name.
   */
  public static Collation getCollation(char[] name) {
    Culture culture = Culture.getCulture(name);
    Collation collation = getCollation(culture.lcid);
    collation.name_ = culture.name;
    return collation;
  }

  /**
   * Compares two strings using the optional CompareOptions value.
   * Params:
   *        string1 = The first string to _compare.
   *        offset1 = The zero-based index of the character in string1 at which to start comparing.
   *        length1 = The number of consecutive characters in string1 to _compare.
   *        string2 = The second string to _compare.
   *        offset2 = The zero-based index of the character in string2 at which to start comparing.
   *        length2 = The number of consecutive characters in string2 to _compare.
   *        options = The CompareOptions value defining how string1 and string2 are to be compared. The default is None.
   * Returns:
   * <table>
   * <tr><td><b>Value</b></td><td><b>Condition</b></td></tr>
   * <tr><td>zero</td><td>The two strings are equal.</td></tr>
   * <tr><td>less than zero</td><td>string1 is less than string2</td></tr>
   * <tr><td>greater than zero</td><td>string1 is greater than string2</td></tr>
   * </table>
   */
  public int compare(char[] string1, int offset1, int length1, char[] string2, int offset2, int length2, CompareOptions options = CompareOptions.None) {
    if (string1 == null) {
      if (string2 == null)
        return 0;
      return -1;
    }
    if (string2 == null)
      return 1;

    return compareString(sortingId_, string1, offset1, length1, string2, offset2, length2, getCompareFlags(options));
  }

  /**
   * Ditto
   */
  public int compare(char[] string1, int offset1, char[] string2, int offset2, CompareOptions options = CompareOptions.None) {
    return compare(string1, offset1, string2.length - offset1, string2, offset2, string2.length - offset2, options);
  }

  /**
   * Ditto
   */
  public int compare(char[] string1, char[] string2, CompareOptions options = CompareOptions.None) {
    if (string1 == null) {
      if (string2 == null)
        return 0;
      return -1;
    }
    if (string2 == null)
      return 1;

    return compareString(sortingId_, string1, 0, string1.length, string2, 0, string2.length, getCompareFlags(options));
  }

  /**
   * Searches for the specified substring and returns the zero-based _index of the first occurance within the specified _source string using the optional CompareOptions _value.
   * Params:
   *        source = The string to search.
   *        value = The string to find within source.
   *        index = The zero-based starting _index of the search.
   *        count = The number of elements to search.
   *        options = The CompareOptions _value defining how source and value are to be compared. The default is None.
   * Returns: The zero-based _index of the first occurance of value within source.
  */
  public int indexOf(char[] source, char[] value, int index, int count, CompareOptions options = CompareOptions.None) {
    uint flags = getCompareFlags(options);
    for (int i = 0; i < count; i++) {
      if (isPrefix(source, index + i, count - i, value, flags))
        return index + i;
    }
    return -1;
  }

  /**
   * Ditto
   */
  public int indexOf(char[] source, char[] value, int index, CompareOptions options = CompareOptions.None) {
    return indexOf(source, value, index, source.length - index, options);
  }
  
  /**
   * Ditto
   */
  public int indexOf(char[] source, char[] value, CompareOptions options = CompareOptions.None) {
    return indexOf(source, value, 0, source.length, options);
  }

  /**
   * Searches for the specified substring and returns the zero-based _index of the last occurance within the specified _source string using the optional CompareOptions _value.
   * Params:
   *        source = The string to search.
   *        value = The string to find within source.
   *        index = The zero-based starting _index of the search.
   *        count = The number of elements to search.
   *        options = The CompareOptions _value defining how source and value are to be compared. The default is None.
   * Returns: The zero-based _index of the last occurance of value within source.
   */
  public int lastIndexOf(char[] source, char[] value, int index, int count, CompareOptions options = CompareOptions.None) {
    if (source == null && (index == -1 || index == 0)) {
      if (value != null)
        return -1;
      return 0;
    }
    if (index == source.length) {
      index--;
      if (count > 0)
        count--;
      if (value == null && count >= 0 && index - count + 1 >= 0)
        return index;
    }
    uint flags = getCompareFlags(options);
    for (int i = 0; i < count; i++) {
      int n = isSuffix(source, index - i, count - i, value, flags);
      if (n >= 0)
        return n;
    }
    return -1;
  }

  /**
   * Ditto
   */
  public int lastIndexOf(char[] source, char[] value, int index, CompareOptions options = CompareOptions.None) {
    return lastIndexOf(source, value, index, index + 1, options);
  }

  /**
   * Ditto
   */
  public int lastIndexOf(char[] source, char[] value, CompareOptions options = CompareOptions.None) {
    return lastIndexOf(source, value, source.length - 1, source.length, options);
  }

  /**
   * Determines whether the specified _source string starts with the specified _prefix using the optional CompareOptions value.
   * Params:
   *        source = The string to search.
   *        suffix = The string to compare with the end of source.
   *        options = The CompareOptions value that defined how source and prefix should be compared.
   * Returns: true if the length of prefix is less than or equal to the length of source, and source starts with prefix; otherwise, false;
   */
  public bool isPrefix(char[] source, char[] prefix, CompareOptions options = CompareOptions.None) {
    if (prefix.length == 0)
      return true;
    return isPrefix(source, source.length - 1, source.length, prefix, getCompareFlags(options));
  }

  /**
   * Determines whether the specified _source string ends with the specified _suffix using the optional CompareOptions value.
   * Params:
   *        source = The string to search.
   *        suffix = The string to compare with the end of source.
   *        options = The CompareOptions value that defined how source and suffix should be compared.
   * Returns: true if the length of suffix is less than or equal to the length of source, and source ends with suffix; otherwise, false;
   */
  public bool isSuffix(char[] source, char[] suffix, CompareOptions options = CompareOptions.None) {
    if (suffix.length == 0)
      return true;
    return isSuffix(source, source.length - 1, source.length, suffix, getCompareFlags(options)) >= 0;
  }

  /**
   * Converts the specified string to lowercase.
   * Params: string = The _string to convert to lowercase.
   * Returns: The specified _string converted to lowercase.
   */
  public char[] toLower(char[] string) {
    return changeCaseString(culture_, string, false);
  }

  /**
   * Converts the specified string to uppercase.
   * Params: string = The _string to convert to uppercase.
   * Returns: The specified _string converted to uppercase.
   */
  public char[] toUpper(char[] string) {
    return changeCaseString(culture_, string, true);
  }

  public final uint lcid() {
    return culture_;
  }

  public final char[] name() {
    if (name_ == null)
      name_ = Culture.getCulture(culture_).name;
    return name_;
  }

  package this(uint culture) {
    culture_ = culture;
    sortingId_ = getSortingId(culture);
  }

  private uint getSortingId(uint culture) {
    uint sortId = (culture >> 16) & 0xF;
    return (sortId == 0) ? culture : (culture | (sortId << 16));
  }

  private bool isPrefix(char[] source, int index, int length, char[] prefix, uint flags) {
    for (int i = 1; i <= length; i++) {
      if (compareString(sortingId_, prefix, 0, prefix.length, source, index, i, flags) == 0)
        return true;
    }
    return false;
  }

  private int isSuffix(char[] source, int index, int length, char[] suffix, uint flags) {
    for (int i = 0; i < length; i++) {
      if (compareString(sortingId_, suffix, 0, suffix.length, source, index - i, i + 1, flags) == 0)
        return index - i;
    }
    return -1;
  }

  private uint getCompareFlags(CompareOptions options) {
    uint flags = 0;
    if ((options & CompareOptions.IgnoreCase) != 0)
      flags |= NORM_IGNORECASE;
    if ((options & CompareOptions.IgnoreNonSpace) != 0)
      flags |= NORM_IGNORENONSPACE;
    if ((options & CompareOptions.IgnoreSymbols) != 0)
      flags |= NORM_IGNORESYMBOLS;
    if ((options & CompareOptions.IgnoreWidth) != 0)
      flags |= NORM_IGNOREWIDTH;
    if ((options & CompareOptions.StringSort) != 0)
      flags |= SORT_STRINGSORT;
    return flags;
  }

  private static int compareString(uint lcid, char[] string1, int offset1, int length1, char[] string2, int offset2, int length2, uint flags) {
    int cchCount1, cchCount2;
    wchar* lpString1 = toUTF16Nls(string1, offset1, length1, cchCount1);
    wchar* lpString2 = toUTF16Nls(string2, offset2, length2, cchCount2);
    return CompareString(lcid, flags, lpString1, cchCount1, lpString2, cchCount2) - 2;
  }

  private static char[] changeCaseString(int lcid, char[] string, bool upperCase) {
    int len;
    wchar* pChars = toUTF16Nls(string, 0, string.length, len);
    LCMapString(lcid, (upperCase ? LCMAP_UPPERCASE : LCMAP_LOWERCASE) | LCMAP_LINGUISTIC_CASING, pChars, len, pChars, len);
    return pChars[0 .. len].toUTF8();
  }

}

/**
 * Specifies the culture-specific display of digits.
 */
public enum DigitShapes {
  /// The digit shape is based on the previous text in the same output.
  Context,
  /// The digit shape is not changed.
  None,
  /// The digit shape is the native equivalent of the Western digits 0 to 9.
  NativeNational
}

/**
 * Defines how numeric values are formatted, depending on the culture.
 */
public class NumberFormat : IProvidesFormat {

  private static NumberFormat invariantFormat_;

  private bool isReadOnly_;

  private int[] numberGroupSizes_;
  private int[] currencyGroupSizes_;
  private int[] percentGroupSizes_;
  private char[] positiveSign_;
  private char[] negativeSign_;
  private char[] numberDecimalSeparator_;
  private char[] numberGroupSeparator_;
  private char[] currencyDecimalSeparator_;
  private char[] currencyGroupSeparator_;
  private char[] percentDecimalSeparator_;
  private char[] percentGroupSeparator_;
  private char[] currencySymbol_;
  private char[] percentSymbol_;
  private char[] nanSymbol_;
  private char[] positiveInfinitySymbol_;
  private char[] negativeInfinitySymbol_;
  private char[][] nativeDigits_;
  private int numberDecimalDigits_;
  private int currencyDecimalDigits_;
  private int percentDecimalDigits_;
  private int numberNegativePattern_;
  private int currencyNegativePattern_;
  private int currencyPositivePattern_;
  private int percentNegativePattern_;
  private int percentPositivePattern_;
  private DigitShapes digitSubstitution_;

  /**
   * Creates a new instance of the NumberFormat class that is culture-independent (invariant).
   */
  public this() {
    this(LOCALE_INVARIANT, false);
  }

  /**
   * Creates a copy of the instance.
   */
  public Object clone() {
    NumberFormat copy = cast(NumberFormat)cloneObject(this);
    copy.isReadOnly_ = false;
    return copy;
  }

  public Object getFormat(TypeInfo type) {
    return (type is typeid(NumberFormat)) ? this : null;
  }

  public static NumberFormat getInstance(IProvidesFormat provider) {
    if (auto culture = cast(Culture)provider) {
      if (!culture.isInherited_)
        return culture.numberFormat;
    }
    if (auto ret = cast(NumberFormat)provider)
      return ret;
    if (provider !is null) {
      if (auto ret = cast(NumberFormat)provider.getFormat(typeid(NumberFormat)))
        return ret;
    }
    return currentFormat;
  }

  /**
   * <i>Property.</i>
   * Retrieves the read-only NumberFormat for the current culture.
   */
  public static NumberFormat currentFormat() {
    Culture currentCulture = Culture.currentCulture;
    if (!currentCulture.isInherited_) {
      if (auto ret = currentCulture.numberFormat_)
        return ret;
    }
    return cast(NumberFormat)currentCulture.getFormat(typeid(NumberFormat));
  }

  /** 
   * <i>Property.</i>
   * Retrieves the read-only, culture-independent NumberFormat instance.
   */
  public static NumberFormat invariantFormat() {
    if (invariantFormat_ is null) {
      invariantFormat_ = new NumberFormat;
      invariantFormat_.isReadOnly_ = true;
    }
    return invariantFormat_;
  }

  /** 
   * <i>Property.</i>
   * Retrieves a value indicating whether the NumberFormat is read-only.
   * Returns: true if the NumberFormat is read-only; otherwise, false.
   */
  public final bool isReadOnly() {
    return isReadOnly_;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the number of digits in each group to the left of the decimal in numeric values.
   */
  public final int[] numberGroupSizes() {
    return numberGroupSizes_;
  }
  /**
   * Ditto
   */
  public final void numberGroupSizes(int[] value) {
    checkReadOnly();
    numberGroupSizes_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the number of digits in each group to the left of the decimal in currency values.
   */
  public final int[] currencyGroupSizes() {
    return currencyGroupSizes_;
  }
  /**
   * Ditto
   */
  public final void currencyGroupSizes(int[] value) {
    checkReadOnly();
    currencyGroupSizes_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the number of digits in each group to the left of the decimal in percent values.
   */
  public final int[] percentGroupSizes() {
    return percentGroupSizes_;
  }
  /**
   * Ditto
   */
  public final void percentGroupSizes(int[] value) {
    checkReadOnly();
    percentGroupSizes_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the string denoting that the number is positive.
   */
  public final char[] positiveSign() {
    return positiveSign_;
  }
  /**
   * Ditto
   */
  public final void positionSign(char[] value) {
    checkReadOnly();
    positiveSign_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the string denoting that the number is negative.
   */
  public final char[] negativeSign() {
    return negativeSign_;
  }
  /**
   * Ditto
   */
  public final void negativeSign(char[] value) {
    checkReadOnly();
    negativeSign_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the string to use as the decimal separator in numeric values.
   */
  public final char[] numberDecimalSeparator() {
    return numberDecimalSeparator_;
  }
  /**
   * Ditto
   */
  public final void numberDecimalSeparator(char[] value) {
    checkReadOnly();
    numberDecimalSeparator_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the string to use as the decimal separator in currency values.
   */
  public final char[] currencyDecimalSeparator() {
    return currencyDecimalSeparator_;
  }
  /**
   * Ditto
   */
  public final void currencyDecimalSeparator(char[] value) {
    checkReadOnly();
    currencyDecimalSeparator_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the string to use as the decimal separator in percent values.
   */
  public final char[] percentDecimalSeparator() {
    return percentDecimalSeparator_;
  }
  /**
   * Ditto
   */
  public final void percentDecimalSeparator(char[] value) {
    checkReadOnly();
    percentDecimalSeparator_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the string separating groups of digits to the left of the decimal in numeric values.
   */
  public final char[] numberGroupSeparator() {
    return numberGroupSeparator_;
  }
  /**
   * Ditto
   */
  public final void numberGroupSeparator(char[] value) {
    checkReadOnly();
    numberGroupSeparator_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the string separating groups of digits to the left of the decimal in currency values.
   */
  public final char[] currencyGroupSeparator() {
    return currencyGroupSeparator_;
  }
  /**
   * Ditto
   */
  public final void currencyGroupSeparator(char[] value) {
    checkReadOnly();
    currencyGroupSeparator_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the string separating groups of digits to the left of the decimal in percent values.
   */
  public final char[] percentGroupSeparator() {
    return percentGroupSeparator_;
  }
  /**
   * Ditto
   */
  public final void percentGroupSeparator(char[] value) {
    checkReadOnly();
    percentGroupSeparator_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the string to use as the currency symbol.
   */
  public final char[] currencySymbol() {
    return currencySymbol_;
  }
  /** 
   * Ditto
   */
  public final void currencySymbol(char[] value) {
    checkReadOnly();
    currencySymbol_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the string to use as the percent symbol.
   */
  public final char[] percentSymbol() {
    return percentSymbol_;
  }
  /** 
   * Ditto
   */
  public final void percentSymbol(char[] value) {
    checkReadOnly();
    percentSymbol_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the string representing the NaN (not a number) symbol.
   */
  public final char[] nanSymbol() {
    return nanSymbol_;
  }
  /** 
   * Ditto
   */
  public final void nanSymbol(char[] value) {
    checkReadOnly();
    nanSymbol_ = value;
  }

  public final char[] negativeInfinitySymbol() {
    return negativeInfinitySymbol_;
  }
  public final void negativeInfinitySymbol(char[] value) {
    checkReadOnly();
    negativeInfinitySymbol_ = value;
  }

  public final char[] positiveInfinitySymbol() {
    return positiveInfinitySymbol_;
  }
  public final void positiveInfinitySymbol(char[] value) {
    checkReadOnly();
    positiveInfinitySymbol_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns an array of strings equivalent to the Western digits 0 to 9.
   */
  public final char[][] nativeDigits() {
    return nativeDigits_;
  }
  /** 
   * Ditto
   */
  public final void nativeDigits(char[][] value) {
    checkReadOnly();
    nativeDigits_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the number of decimal places to use in numeric values.
   */
  public final int numberDecimalDigits() {
    return numberDecimalDigits_;
  }
  /** 
   * Ditto
   */
  public final void numberDecimalDigits(int value) {
    checkReadOnly();
    numberDecimalDigits_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the number of decimal places to use in currency values.
   */
  public final int currencyDecimalDigits() {
    return currencyDecimalDigits_;
  }
  /** 
   * Ditto
   */
  public final void currencyDecimalDigits(int value) {
    checkReadOnly();
    currencyDecimalDigits_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the number of decimal places to use in percent values.
   */
  public final int percentDecimalDigits() {
    return percentDecimalDigits_;
  }
  /** 
   * Ditto
   */
  public final void percentDecimalDigits(int value) {
    checkReadOnly();
    percentDecimalDigits_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the format pattern for negative numeric values.
   */
  public final int numberNegativePattern() {
    return numberNegativePattern_;
  }
  /** 
   * Ditto
   */
  public final void numberNegativePattern(int value) {
    checkReadOnly();
    numberNegativePattern_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the format pattern for positive currency values.
   */
  public final int currencyPositivePattern() {
    return currencyPositivePattern_;
  }
  /** 
   * Ditto
   */
  public final void currencyPositivePattern(int value) {
    checkReadOnly();
    currencyPositivePattern_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the format pattern for negative currency values.
   */
  public final int currencyNegativePattern() {
    return currencyNegativePattern_;
  }
  /** 
   * Ditto
   */
  public final void currencyNegativePattern(int value) {
    checkReadOnly();
    currencyNegativePattern_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the format pattern for positive percent values.
   */
  public final int percentPositivePattern() {
    return percentPositivePattern_;
  }
  /** 
   * Ditto
   */
  public final void percentPositivePattern(int value) {
    checkReadOnly();
    percentPositivePattern_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the format pattern for negative percent values.
   */
  public final int percentNegativePattern() {
    return percentNegativePattern_;
  }
  /** 
   * Ditto
   */
  public final void percentNegativePattern(int value) {
    checkReadOnly();
    percentNegativePattern_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns a value determining the display of a digit.
   */
  public final DigitShapes digitSubstitution() {
    return digitSubstitution_;
  }
  /** 
   * Ditto
   */
  public final void digitSubstitution(DigitShapes value) {
    if (value < DigitShapes.min || value > DigitShapes.max)
      throw new ArgumentOutOfRangeException("value", "Valid values are Context, None and NativeNational.");

    checkReadOnly();
    digitSubstitution_ = value;
  }

  package this(uint culture, bool userOverrides) {
    // Set the invariant values.
    numberGroupSizes_ = [3];
    currencyGroupSizes_ = [3];
    percentGroupSizes_ = [3];
    positiveSign_ = "+";
    negativeSign_ = "-";
    numberDecimalSeparator_ = ".";
    numberGroupSeparator_ = ",";
    currencyDecimalSeparator_ = ".";
    currencyGroupSeparator_ = ",";
    percentDecimalSeparator_ = ".";
    percentGroupSeparator_ = ",";
    currencySymbol_ = "\u00A4";
    percentSymbol_ = "%";
    nanSymbol_ = "NaN";
    positiveInfinitySymbol_ = "Infinity";
    negativeInfinitySymbol_ = "-Infinity";
    nativeDigits_ = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
    numberDecimalDigits_ = 2;
    currencyDecimalDigits_ = 2;
    percentDecimalDigits_ = 2;
    digitSubstitution_ = DigitShapes.None;

    if (culture != LOCALE_INVARIANT) {
      uint flags = userOverrides ? 0 : LOCALE_NOUSEROVERRIDE;

      // Get culture-specific values from the Windows API.
      numberGroupSizes_ = getGrouping(culture, LOCALE_SGROUPING | flags);
      currencyGroupSizes_ = getGrouping(culture, LOCALE_SMONGROUPING | flags);
      percentGroupSizes_ = numberGroupSizes_;
      negativeSign_ = getLocaleInfo(culture, LOCALE_SNEGATIVESIGN | flags);
      positiveSign_ = getLocaleInfo(culture, LOCALE_SPOSITIVESIGN | flags);
      numberDecimalSeparator_ = getLocaleInfo(culture, LOCALE_SDECIMAL | flags);
      numberGroupSeparator_ = getLocaleInfo(culture, LOCALE_STHOUSAND | flags);
      currencyDecimalSeparator_ = getLocaleInfo(culture, LOCALE_SMONDECIMALSEP | flags);
      currencyGroupSeparator_ = getLocaleInfo(culture, LOCALE_SMONTHOUSANDSEP | flags);
      percentDecimalSeparator_ = numberDecimalSeparator_;
      percentGroupSeparator_ = numberGroupSeparator_;
      currencySymbol_ = getLocaleInfo(culture, LOCALE_SCURRENCY | flags);
      nativeDigits_ = getNativeDigits(culture, flags);
      numberDecimalDigits_ = getLocaleInfoI(culture, LOCALE_IDIGITS | flags);
      currencyDecimalDigits_ = getLocaleInfoI(culture, LOCALE_ICURRDIGITS | flags);
      percentDecimalDigits_ = numberDecimalDigits_;
      numberNegativePattern_ = getLocaleInfoI(culture, LOCALE_INEGNUMBER | flags);
      currencyPositivePattern_ = getLocaleInfoI(culture, LOCALE_ICURRENCY | flags);
      currencyNegativePattern_ = getLocaleInfoI(culture, LOCALE_INEGCURR | flags);
      digitSubstitution_ = cast(DigitShapes)getLocaleInfoI(culture, LOCALE_IDIGITSUBSTITUTION | flags);

      // Not all locales return a value for the positive sign.
      if (positiveSign_ == null)
        positiveSign_ = "+";
    }
  }

  private void checkReadOnly() {
    if (isReadOnly_)
      throw new InvalidOperationException("Instance is read-only.");
  }

}

package const char[] ALL_STANDARD_FORMATS = [ 'd', 'D', 'f', 'F', 'g', 'G', 'r', 'R', 's', 't', 'T', 'u', 'U', 'y', 'Y' ];

/**
 * Defines how DateTime values are formatted, depending on the culture.
 */
public class DateTimeFormat : IProvidesFormat {

  private const char[] RFC1123_PATTERN = "ddd, dd MMM yyyy HH':'mm':'ss 'GMT'";
  private const char[] SORTABLE_DATETIME_PATTERN = "yyyy'-'MM'-'dd'T'HH':'mm':'ss";
  private const char[] UNIVERSAL_SORTABLE_DATETIME_PATTERN = "yyyy'-'MM'-'dd HH':'mm':'ss'Z'";

  private static DateTimeFormat invariantFormat_;

  private uint culture_;
  private bool userOverrides_;
  private bool isReadOnly_;
  private Calendar calendar_;

  private int firstDayOfWeek_ = -1;
  private int calendarWeekRule_ = -1;
  private char[] amDesignator_;
  private char[] pmDesignator_;
  private char[][] dayNames_;
  private char[][] abbrevDayNames_;
  private char[][] monthNames_;
  private char[][] abbrevMonthNames_;
  private char[] dateSeparator_;
  private char[] timeSeparator_;
  private int[] optionalCalendars_;
  private bool isDefaultCalendar_;

  private char[] shortDatePattern_;
  private char[] longDatePattern_;
  private char[] shortTimePattern_;
  private char[] longTimePattern_;
  private char[] yearMonthPattern_;

  private char[] fullDateTimePattern_;

  /**
   * Creates a new instance of the DateTimeFormat class that is culture-independent (invariant).
   */
  public this() {
    culture_ = LOCALE_INVARIANT;
    userOverrides_ = false;
    isDefaultCalendar_ = true;
    calendar_ = GregorianCalendar.getDefaultInstance();
    initializeProperties();
  }

  public Object clone() {
    DateTimeFormat copy = cast(DateTimeFormat)cloneObject(this);
    copy.calendar_ = cast(Calendar)calendar.clone();
    copy.isReadOnly_ = false;
    return copy;
  }

  public Object getFormat(TypeInfo type) {
    return (type is typeid(DateTimeFormat)) ? this : null;
  }

  public static DateTimeFormat getInstance(IProvidesFormat provider) {
    if (auto culture = cast(Culture)provider) {
      if (!culture.isInherited_)
        return culture.dateTimeFormat;
    }
    if (auto ret = cast(DateTimeFormat)provider)
      return ret;
    if (provider !is null) {
      if (auto ret = cast(DateTimeFormat)provider.getFormat(typeid(DateTimeFormat)))
        return ret;
    }
    return currentFormat;
  }

  /**
   * Retrieves the culture-specific full name of the specified day of the week.
   * Params: dayOfWeek = A DayOfWeek value.
   * Returns: The culture-specific name of the day represented by dayOfWeek.
   */
  public final char[] getDayName(DayOfWeek dayOfWeek) {
    if (dayOfWeek < DayOfWeek.min || dayOfWeek > DayOfWeek.max)
      throw new ArgumentOutOfRangeException("dayOfWeek");
    return getDayNames()[cast(int)dayOfWeek];
  }

  /**
   * Retrieves the culture-specific abbreviated name of the specified day of the week.
   * Params: dayOfWeek = A DayOfWeek value.
   * Returns: The culture-specific abbreviated name of the day represented by dayOfWeek.
   */
  public final char[] getAbbreviatedDayName(DayOfWeek dayOfWeek) {
    if (dayOfWeek < DayOfWeek.min || dayOfWeek > DayOfWeek.max)
      throw new ArgumentOutOfRangeException("dayOfWeek");
    return getAbbreviatedDayNames()[cast(int)dayOfWeek];
  }

  /**
   * Retrieves the culture-specific full name of the specified _month.
   * Params: month = A value between 1 and 13 representing the _month to retrieve.
   * Returns: The culture-specific name of the _month represented by month.
   */
  public final char[] getMonthName(int month) {
    if (month < 1 || month > 13)
      throw new ArgumentOutOfRangeException("month");
    return getMonthNames()[month - 1];
  }

  /**
   * Retrieves the culture-specific abbreviated name of the specified _month.
   * Params: month = A value between 1 and 13 representing the _month to retrieve.
   * Returns: The culture-specific abbreviated name of the _month represented by month.
   */
  public final char[] getAbbreviatedMonthName(int month) {
    if (month < 1 || month > 13)
      throw new ArgumentOutOfRangeException("month");
    return getAbbreviatedMonthNames()[month - 1];
  }

  /*public final char[][] getAllDateTimePatterns() {
    char[][] result;
    foreach (format; ALL_STANDARD_FORMATS)
      result ~= getAllDateTimePatterns(format);
    return result;
  }

  public final char[][] getAllDateTimePatterns(char format) {

    char[][] combinePatterns(char[][] patterns1, char[][] patterns2) {
      char[][] result = new char[][patterns1.length * patterns2.length];
      for (int i = 0; i < patterns1.length; i++) {
        for (int j = 0; j < patterns2.length; j++)
          result[i * patterns2.length + j] = patterns1[i] ~ " " ~ patterns2[j];
      }
      return result;
    }

    char[][] result;
    switch (format) {
      case 'd':
        result ~= shortDatePatterns;
        break;
      case 'D':
        result ~= longDatePatterns;
        break;
      case 'f':
        result ~= combinePatterns(longDatePatterns, shortTimePatterns);
        break;
      case 'F':
        result ~= combinePatterns(longDatePatterns, longTimePatterns);
        break;
      case 'g':
        result ~= combinePatterns(shortDatePatterns, shortTimePatterns);
        break;
      case 'G':
        result ~= combinePatterns(shortDatePatterns, longTimePatterns);
        break;
      case 'r': case 'R':
        result ~= rfc1123Pattern_;
        break;
      case 's':
        result ~= sortableDateTimePattern_;
        break;
      case 't':
        result ~= shortTimePatterns;
        break;
      case 'T':
        result ~= longTimePatterns;
        break;
      case 'u':
        result ~= universalSortableDateTimePattern_;
        break;
      case 'U':
        result ~= combinePatterns(longDatePatterns, longTimePatterns);
        break;
      case 'y': case 'Y':
        result ~= yearMonthPatterns;
        break;
      default:
        throw new ArgumentException("The specified format was not valid.", "format");
    }
    return result;
  }*/

  /**
   * <i>Property.</i>
   * Retrieves the read-only DateTimeFormat for the current culture.
   */
  public static DateTimeFormat currentFormat() {
    Culture currentCulture = Culture.currentCulture;
    if (!currentCulture.isInherited_) {
      if (auto ret = currentCulture.dateTimeFormat_)
        return ret;
    }
    return cast(DateTimeFormat)currentCulture.getFormat(typeid(DateTimeFormat));
  }

  /**
   * <i>Property.</i>
   * Retrieves the read-only DateTimeFormat that is culture-independent.
   */
  public static DateTimeFormat invariantFormat() {
    if (invariantFormat_ is null) {
      invariantFormat_ = new DateTimeFormat;
      invariantFormat_.isReadOnly_ = true;
    }
    return invariantFormat_;
  }

  /**
   * <i>Property.</i>
   * Retrieves a value indicating whether the DateTimeFormat is read-only.
   */
  public final bool isReadOnly() {
    return isReadOnly_;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the _calendar to use for the current culture.
   */
  public final Calendar calendar() {
    return calendar_;
  }
  /**
   * Ditto
   */
  public final void calendar(Calendar value) {
    if (value !is calendar_) {
      for (int i = 0; i < optionalCalendars.length; i++) {
        if (optionalCalendars[i] == value.id) {
          isDefaultCalendar_ = (value.id == CAL_GREGORIAN);

          if (calendar_ !is null) {
            dayNames_ = null;
            abbrevDayNames_ = null;
            monthNames_ = null;
            abbrevMonthNames_ = null;
            shortDatePattern_ = null;
            longDatePattern_ = null;
            yearMonthPattern_ = null;
            fullDateTimePattern_ = null;
          }

          calendar_ = value;

          initializeProperties();
          return;
        }
      }
      throw new ArgumentException("Not a valid calendar for the culture.");
    }
  }

  /**
   * <i>Property.</i>
   * Retrieves the native name of the calendar associated with the current instance.
   */
  public final char[] calendarName() {
    return getCalendarInfo(culture_, calendar.id, CAL_SCALNAME | (userOverrides_ ? 0 : CAL_NOUSEROVERRIDE));
  }

  /**
   * <i>Property.</i>
   * Retrieves the format pattern for a time value, based on the IETF RFC 1123 specification.
   */
  public final char[] rfc1123Pattern() {
    return RFC1123_PATTERN;
  }

  /** 
   * <i>Property.</i>
   * Retrieves the format pattern for a sortable date and time value.
   */
  public final char[] sortableDateTimePattern() {
    return SORTABLE_DATETIME_PATTERN;
  }

  /** 
   * <i>Property.</i>
   * Retrieves the format pattern for a universal sortable date and time value.
   */
  public final char[] universalSortableDateTimePattern() {
    return UNIVERSAL_SORTABLE_DATETIME_PATTERN;
  }

  public final char[] fullDateTimePattern() {
    if (fullDateTimePattern_ == null)
      fullDateTimePattern_ = longDatePattern ~ " " ~ longTimePattern;
    return fullDateTimePattern_;
  }
  public final void fullDateTimePattern(char[] value) {
    checkReadOnly();
    fullDateTimePattern_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the string for hours before noon.
   */
  public final char[] amDesignator() {
    return amDesignator_;
  }
  /** 
   * Ditto
   */
  public final void amDesignator(char[] value) {
    checkReadOnly();
    amDesignator_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the string for hours after noon.
   */
  public final char[] pmDesignator() {
    return pmDesignator_;
  }
  /** 
   * Ditto
   */
  public final void pmDesignator(char[] value) {
    checkReadOnly();
    pmDesignator_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the first day of the week.
   */
  public final DayOfWeek firstDayOfWeek() {
    return cast(DayOfWeek)firstDayOfWeek_;
  }
  /** 
   * Ditto
   */
  public final void firstDayOfWeek(DayOfWeek value) {
    if (value < DayOfWeek.min || value > DayOfWeek.max)
      throw new ArgumentOutOfRangeException("value");
    checkReadOnly();
    firstDayOfWeek_ = cast(int)value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns a value specifying the rule used to determine the first week of the year.
   */
  public final CalendarWeekRule calendarWeekRule() {
    return cast(CalendarWeekRule)calendarWeekRule_;
  }
  /** 
   * Ditto
   */
  public final void calendarWeekRule(CalendarWeekRule value) {
    if (value < CalendarWeekRule.min || value > CalendarWeekRule.max)
      throw new ArgumentOutOfRangeException("value");

    checkReadOnly();
    calendarWeekRule_ = cast(int)value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns an array of strings containing the culture-specific full names of the days of the week.
   */
  public final char[][] dayNames() {
    return getDayNames().dup;
  }
  /** 
   * Ditto
   */
  public final void dayNames(char[][] value) {
    checkReadOnly();
    dayNames_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns an array of strings containing the culture-specific abbreviated names of the days of the week.
   */
  public final char[][] abbreviatedDayNames() {
    return getAbbreviatedDayNames().dup;
  }
  /** 
   * Ditto
   */
  public final void abbreviatedDayNames(char[][] value) {
    checkReadOnly();
    abbrevDayNames_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns an array of strings containing the culture-specific full names of the months.
   *
   * In a 12-month calendar, the 13th element of the array is an empty string.
   */
  public final char[][] monthNames() {
    return getMonthNames().dup;
  }
  /** 
   * Ditto
   */
  public final void monthNames(char[][] value) {
    checkReadOnly();
    monthNames_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns an array of strings containing the culture-specific abbreviated names of the months.
   *
   * In a 12-month calendar, the 13th element of the array is an empty string.
   */
  public final char[][] abbreviatedMonthNames() {
    return getAbbreviatedMonthNames().dup;
  }
  /** 
   * Ditto
   */
  public final void abbreviatedMonthNames(char[][] value) {
    checkReadOnly();
    abbrevMonthNames_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the format pattern for a year and month value.
   */
  public final char[] yearMonthPattern() {
    return yearMonthPattern_;
  }
  /** 
   * Ditto
   */
  public final void yearMonthPattern(char[] value) {
    checkReadOnly();
    yearMonthPattern_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the string separating components of time.
   */
  public final char[] timeSeparator() {
    if (timeSeparator_ == null)
      timeSeparator_ = getLocaleInfo(culture_, LOCALE_STIME | (userOverrides_ ? 0 : LOCALE_NOUSEROVERRIDE));
    return timeSeparator_;
  }
  /** 
   * Ditto
   */
  public final void timeSeparator(char[] value) {
    checkReadOnly();
    timeSeparator_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the string separating components of a date.
   */
  public final char[] dateSeparator() {
    if (dateSeparator_ == null)
      dateSeparator_ = getLocaleInfo(culture_, LOCALE_SDATE | (userOverrides_ ? 0 : LOCALE_NOUSEROVERRIDE));
    return dateSeparator_;
  }
  /** 
   * Ditto
   */
  public final void dateSeparator(char[] value) {
    checkReadOnly();
    dateSeparator_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the format pattern for a short date value.
   */
  public final char[] shortDatePattern() {
    return shortDatePattern_;
  }
  /** 
   * Ditto
   */
  public final void shortDatePattern(char[] value) {
    checkReadOnly();
    shortDatePattern_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the format pattern for a long date value.
   */
  public final char[] longDatePattern() {
    return longDatePattern_;
  }
  /** 
   * Ditto
   */
  public final void longDatePattern(char[] value) {
    checkReadOnly();
    longDatePattern_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the format pattern for a short time value.
   */
  public final char[] shortTimePattern() {
    if (shortTimePattern_ == null)
      shortTimePattern_ = getShortTime(culture_);
    return shortTimePattern_;
  }
  /** 
   * Ditto
   */
  public final void shortTimePattern(char[] value) {
    checkReadOnly();
    shortTimePattern_ = value;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the format pattern for a long time value.
   */
  public final char[] longTimePattern() {
    return longTimePattern_;
  }
  /** 
   * Ditto
   */
  public final void longTimePattern(char[] value) {
    checkReadOnly();
    longTimePattern_ = value;
  }

  package this(uint culture, bool userOverrides, Calendar calendar) {
    culture_ = culture;
    userOverrides_ = userOverrides;
    // Setting the calendar property here causes dependent properties to be populated.
    this.calendar = calendar;
  }

  package char[] generalShortTimePattern() {
    return shortDatePattern ~ " " ~ shortTimePattern;
  }

  package char[] generalLongTimePattern() {
    return shortDatePattern ~ " " ~ longTimePattern;
  }

  package uint cultureId() {
    return culture_;
  }

  private char[] getShortDatePattern(uint calID, uint flags) {
    if (!isDefaultCalendar_)
      return getShortDates(culture_, calID)[0];
    return getLocaleInfo(culture_, LOCALE_SSHORTDATE | flags);
  }

  private char[] getLongDatePattern(uint calID, uint flags) {
    if (!isDefaultCalendar_)
      return getLongDates(culture_, calID)[0];
    return getLocaleInfo(culture_, LOCALE_SLONGDATE | flags);
  }

  private char[] getYearMonthPattern(uint calID, uint flags) {
    if (!isDefaultCalendar_)
      return getYearMonths(culture_, calID)[0];
    return getLocaleInfo(culture_, LOCALE_SYEARMONTH | flags);
  }

  private char[][] getDayNames() {
    if (dayNames_ == null) {
      uint flags = userOverrides_ ? 0 : LOCALE_NOUSEROVERRIDE;
      dayNames_.length = 7;
      for (uint i = LOCALE_SDAYNAME1; i <= LOCALE_SDAYNAME7; i++) {
        uint j = (i != LOCALE_SDAYNAME7) ? i - LOCALE_SDAYNAME1 + 1 : 0;
        dayNames_[j] = getLocaleInfo(culture_, i | flags);
      }
    }
    return dayNames_;
  }

  private char[][] getAbbreviatedDayNames() {
    if (abbrevDayNames_ == null) {
      uint flags = userOverrides_ ? 0 : LOCALE_NOUSEROVERRIDE;
      abbrevDayNames_.length = 7;
      for (uint i = LOCALE_SABBREVDAYNAME1; i <= LOCALE_SABBREVDAYNAME7; i++) {
        uint j = (i != LOCALE_SABBREVDAYNAME7) ? i - LOCALE_SABBREVDAYNAME1 + 1 : 0;
        abbrevDayNames_[j] = getLocaleInfo(culture_, i | flags);
      }
    }
    return abbrevDayNames_;
  }

  private char[][] getMonthNames() {
    if (monthNames_ == null) {
      uint flags = userOverrides_ ? 0 : LOCALE_NOUSEROVERRIDE;
      monthNames_.length = 13;
      for (uint i = LOCALE_SMONTHNAME1; i <= LOCALE_SMONTHNAME12; i++)
        monthNames_[i - LOCALE_SMONTHNAME1] = getLocaleInfo(culture_, i | flags);
    }
    return monthNames_;
  }

  private char[][] getAbbreviatedMonthNames() {
    if (abbrevMonthNames_ == null) {
      uint flags = userOverrides_ ? 0 : LOCALE_NOUSEROVERRIDE;
      abbrevMonthNames_.length = 13;
      for (uint i = LOCALE_SABBREVMONTHNAME1; i <= LOCALE_SABBREVMONTHNAME12; i++)
        abbrevMonthNames_[i - LOCALE_SABBREVMONTHNAME1] = getLocaleInfo(culture_, i | flags);
    }
    return abbrevMonthNames_;
  }

  private int[] optionalCalendars() {
    if (optionalCalendars_ == null)
      optionalCalendars_ = getOptionalCalendars(culture_);
    return optionalCalendars_;
  }

  private void initializeProperties() {
    uint flags = userOverrides_ ? 0 : LOCALE_NOUSEROVERRIDE;

    if (amDesignator_ == null)
      amDesignator_ = getLocaleInfo(culture_, LOCALE_S1159 | flags);
    if (pmDesignator_ == null)
      pmDesignator_ = getLocaleInfo(culture_, LOCALE_S2359 | flags);
    if (firstDayOfWeek_ == -1)
      firstDayOfWeek_ = getLocaleInfoI(culture_, LOCALE_IFIRSTDAYOFWEEK | flags);
    if (calendarWeekRule_ == -1)
      calendarWeekRule_ = getLocaleInfoI(culture_, LOCALE_IFIRSTWEEKOFYEAR | flags);
    if (yearMonthPattern_ == null)
      yearMonthPattern_ = getLocaleInfo(culture_, LOCALE_SYEARMONTH | flags);
    if (shortDatePattern_ == null)
      shortDatePattern_ = getShortDatePattern(calendar_.id, flags);
    if (longDatePattern_ == null)
      longDatePattern_ = getLongDatePattern(calendar_.id, flags);
    if (yearMonthPattern_ == null)
      yearMonthPattern_ = getYearMonthPattern(calendar_.id, flags);
    if (longTimePattern_ == null)
      longTimePattern_ = getLocaleInfo(culture_, LOCALE_STIMEFORMAT | flags);
  }

  private void checkReadOnly() {
    if (isReadOnly_)
      throw new InvalidOperationException("Instance is read-only.");
  }

}

/**
   * <i>Abstract.</i>
 * Represents time in divisions such as weeks, months and years.
 */
public abstract class Calendar {

  /**
   * Represents the current era.
   */
  public const int CURRENT_ERA = 0;

  package int twoDigitYearMax_ = -1;

  public Object clone() {
    return cloneObject(this);
  }

  public int id() {
    return -1;
  }

  /**
   * Returns the day of the week in the specified DateTime.
   * Params: date = A DateTime value.
   */
  public abstract DayOfWeek getDayOfWeek(DateTime time);

  /**
   * Returns the day of the month in the specified DateTime.
   * Params: date = A DateTime value.
   */
  public abstract int getDayOfMonth(DateTime date);

  /**
   * Returns the day of the year in the specified DateTime.
   * Params: date = A DateTime value.
   */
  public abstract int getDayOfYear(DateTime time);

  /**
   * Returns the month in the specified DateTime.
   * Params: date = A DateTime value.
   */
  public abstract int getMonth(DateTime date);

  /**
   * Returns the year in the specified DateTime.
   * Params: date = A DateTime value.
   */
  public abstract int getYear(DateTime date);

  /**
   * Returns the hours value in the specified DateTime.
   */
  public int getHour(DateTime time) {
    return cast(int)((time.ticks / TICKS_PER_HOUR) % 24);
  }

  /**
   * Returns the minutes value in the specified DateTime.
   */
  public int getMinute(DateTime time) {
    return cast(int)((time.ticks / TICKS_PER_MINUTE) % 60);
  }

  /**
   * Returns the seconds value in the specified DateTime.
   */
  public int getSecond(DateTime time) {
    return cast(int)((time.ticks / TICKS_PER_SECOND) % 60);
  }

  /**
   * Returns the milliseconds value in the specified DateTime.
   */
  public int getMilliseconds(DateTime time) {
    return cast(int)((time.ticks / TICKS_PER_MILLISECOND) % 1000);
  }

  /**
   * Returns the number of days in the specified _month and _year in the current era.
   */
  public int getDaysInMonth(int year, int month) {
    return getDaysInMonth(year, month, CURRENT_ERA);
  }

  /**
   * Returns the number of days in the specified _month, _year and _era.
   */
  public abstract int getDaysInMonth(int year, int month, int era);

  /**
   * Returns the number of days in the specified _year in the current era.
   */
  public int getDaysInYear(int year) {
    return getDaysInMonth(year, CURRENT_ERA);
  }

  /**
   * Returns the number of days in the specified _year and _era.
   */
  public abstract int getDaysInYear(int year, int era);

  /**
   * Returns the number of months in the specified _year in the current era.
   */
  public int getMonthsInYear(int year) {
    return getMonthsInYear(year, CURRENT_ERA);
  }

  /**
   * Returns the number of months in the specified _year and _era.
   */
  public abstract int getMonthsInYear(int year, int era);

  /**
   * Determines whether the specified _year in the current era is a leap _year.
   */
  public bool isLeapYear(int year) {
    return isLeapYear(year, CURRENT_ERA);
  }

  /**
   * Determines whether the specified _year in the specified _era is a leap _year.
   */
  public abstract bool isLeapYear(int year, int era);

  /**
   * Returns a DateTime set to the specified date and time in the current era.
   */
  public DateTime getDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond) {
    return getDateTime(year, month, day, hour, minute, second, millisecond, CURRENT_ERA);
  }

  /**
   * Returns a DateTime set to the specified date and time in the specified _era.
   */
  public abstract DateTime getDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond, int era);

  /**
   * Converts the specified two-digit _year to a four-digit _year.
   * Params: year = The two-digit _year to convert.
   */
  public int toFourDigitYear(int year) {
    if (year < 100)
      return (twoDigitYearMaximum / 100 - ((year > twoDigitYearMaximum % 100) ? 1 : 0)) * 100 + year;
    return year;
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns the last year of a 100-year range that can be represented by a two-digit year.
   */
  public int twoDigitYearMaximum() {
    return twoDigitYearMax_;
  }
  /**
   * Ditto
   */
  public void twoDigitYearMaximum(int value) {
    twoDigitYearMax_ = value;
  }

  /**
   * <i>Protected.</i>
   * Creates a new instance of the Calendar class.
   */
  protected this() {
  }

}

/**
 * Defines different language versions of the Gregorian calendar.
 */
public enum GregorianCalendarTypes {
  /// Refers to the localized version of the Gregorian calendar.
  Localized = CAL_GREGORIAN,
  /// Refers to the U.S. English version of the Gregorian calendar.
  USEnglish = CAL_GREGORIAN_US,
  /// Refers to the Middle East French version of the Gregorian calendar.
  MiddleEastFrench = CAL_GREGORIAN_ME_FRENCH,
  /// Refers to the _Arabic version of the Gregorian calendar.
  Arabic = CAL_GREGORIAN_ARABIC,
  /// Refers to the transliterated English version of the Gregorian calendar.
  TransliteratedEnglish = CAL_GREGORIAN_XLIT_ENGLISH,
  /// Refers to the transliterated French version of the Gregorian calendar.
  TransliteratedFrench = CAL_GREGORIAN_XLIT_FRENCH
}

/**
 * Represents the Gregorian calendar.
 *
 * The Gregorian calendar recognizes both B.C. and A.D. eras. However, the GregorianCalendar implementation only recognizes the 
 * current era (A.D.).
 */
public class GregorianCalendar : Calendar {

  /**
   * Represents the current era.
   */
  public const int AD_ERA = 1;

  private static GregorianCalendar defaultInstance_;
  private GregorianCalendarTypes type_;

  /**
   * Creates a new instance of the GregorianCalendar class using the specified GregorianCalendarTypes value.
   * Params: type = The GregorianCalendarTypes value that defines which language version of the calendar to create. The default is Localized.
   */
  public this(GregorianCalendarTypes type = GregorianCalendarTypes.Localized) {
    type_ = type;
  }

  public override int id() {
    return cast(int)type_;
  }

  public override int getDayOfYear(DateTime date) {
    return extractPart(date.ticks, DatePart.DAY_OF_YEAR);
  }

  public override int getDayOfMonth(DateTime date) {
    return extractPart(date.ticks, DatePart.DAY);
  }

  public override DayOfWeek getDayOfWeek(DateTime date) {
    return cast(DayOfWeek)((date.ticks / TICKS_PER_DAY + 1) % 7);
  }

  public override int getMonth(DateTime date) {
    return extractPart(date.ticks, DatePart.MONTH);
  }

  public override int getYear(DateTime date) {
    return extractPart(date.ticks, DatePart.YEAR);
  }

  public override int getDaysInYear(int year, int era) {
    return isLeapYear(year, era) ? 366 : 365;
  }

  public override int getDaysInMonth(int year, int month, int era) {
    int[] monthDays = isLeapYear(year, era) ? DAYS_TO_MONTH_LEAP : DAYS_TO_MONTH_COMMON;
    return monthDays[month] - monthDays[month - 1];
  }

  public override int getMonthsInYear(int year, int era) {
    return 12;
  }

  public override bool isLeapYear(int year, int era) {
    return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0));
  }

  public override DateTime getDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond, int era) {
    return DateTime(year, month, day, hour, minute, second, millisecond);
  }

  public override int twoDigitYearMaximum() {
    if (twoDigitYearMax_ == -1) {
      twoDigitYearMax_ = getCalendarInfoI(LOCALE_USER_DEFAULT, id, CAL_ITWODIGITYEARMAX);
    }
    return twoDigitYearMax_;
  }
  public override void twoDigitYearMaximum(int value) {
    twoDigitYearMax_ = value;
  }

  package static GregorianCalendar getDefaultInstance() {
    if (defaultInstance_ is null)
      defaultInstance_ = new GregorianCalendar;
    return defaultInstance_;
  }

}

// Common date/time data.

package const int[] DAYS_TO_MONTH_COMMON = [ 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365 ];
package const int[] DAYS_TO_MONTH_LEAP = [ 0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366 ];

package const ulong TICKS_PER_MILLISECOND = 10000;
package const ulong TICKS_PER_SECOND = TICKS_PER_MILLISECOND * 1000;
package const ulong TICKS_PER_MINUTE = TICKS_PER_SECOND * 60;
package const ulong TICKS_PER_HOUR = TICKS_PER_MINUTE * 60;
package const ulong TICKS_PER_DAY = TICKS_PER_HOUR * 24;

package const int MILLIS_PER_SECOND = 1000;
package const int MILLIS_PER_MINUTE = MILLIS_PER_SECOND * 60;
package const int MILLIS_PER_HOUR = MILLIS_PER_MINUTE * 60;
package const int MILLIS_PER_DAY = MILLIS_PER_HOUR * 24;

package const int DAYS_PER_YEAR = 365;
package const int DAYS_PER_4_YEARS = DAYS_PER_YEAR * 4 + 1;
package const int DAYS_PER_100_YEARS = DAYS_PER_4_YEARS * 25 - 1;
package const int DAYS_PER_400_YEARS = DAYS_PER_100_YEARS * 4 + 1;

package const int DAYS_TO_1601 = DAYS_PER_400_YEARS * 4;
package const int DAYS_TO_10000 = DAYS_PER_400_YEARS * 25 - 366;

private enum DatePart {
  YEAR,
  MONTH,
  DAY,
  DAY_OF_YEAR
}

private void splitDate(long ticks, out int year, out int month, out int day, out int dayOfYear) {
  int numDays = cast(int)(ticks / TICKS_PER_DAY);
  int whole400Years = numDays / DAYS_PER_400_YEARS;
  numDays -= whole400Years * DAYS_PER_400_YEARS;
  int whole100Years = numDays / DAYS_PER_100_YEARS;
  if (whole100Years == 4)
    whole100Years = 3;
  numDays -= whole100Years * DAYS_PER_100_YEARS;
  int whole4Years = numDays / DAYS_PER_4_YEARS;
  numDays -= whole4Years * DAYS_PER_4_YEARS;
  int wholeYears = numDays / DAYS_PER_YEAR;
  if (wholeYears == 4)
    wholeYears = 3;
  year = whole400Years * 400 + whole100Years * 100 + whole4Years * 4 + wholeYears + 1;
  numDays -= wholeYears * DAYS_PER_YEAR;
  dayOfYear = numDays + 1;
  int[] monthDays = (wholeYears == 3 && (whole4Years != 24 || whole100Years == 3)) ? DAYS_TO_MONTH_LEAP : DAYS_TO_MONTH_COMMON;
  month = numDays >> 5 + 1;
  while (numDays >= monthDays[month])
    month++;
  day = numDays - monthDays[month - 1] + 1;
}

private int extractPart(long ticks, DatePart part) {
  int year, month, day, dayOfYear;
  splitDate(ticks, year, month, day, dayOfYear);
  if (part == DatePart.YEAR)
    return year;
  else if (part == DatePart.MONTH)
    return month;
  else if (part == DatePart.DAY_OF_YEAR)
    return dayOfYear;
  return day;
}

public struct TimeSpan {

  private long ticks_;

  public static TimeSpan opCall(long ticks) {
    TimeSpan t;
    return t.ticks_ = ticks,
      t;
  }

  public static TimeSpan opCall(int hours, int minutes, int seconds) {
    TimeSpan t;
    return t.ticks_ = (hours * 3600 + minutes * 60 + seconds) * cast(long)TICKS_PER_SECOND,
      t;
  }

  public static TimeSpan fromMinutes(double value ) {
    return interval(value, MILLIS_PER_MINUTE);
  }

  public TimeSpan add(TimeSpan t) {
    return TimeSpan(ticks_ + t.ticks_);
  }

  public TimeSpan opApp(TimeSpan t) {
    return TimeSpan(ticks_ + t.ticks_);
  }

  public TimeSpan opAddAssign(TimeSpan t) {
    ticks_ += t.ticks_;
    return *this;
  }

  public TimeSpan subtract(TimeSpan t) {
    return TimeSpan(ticks_ - t.ticks_);
  }

  public TimeSpan opSub(TimeSpan t) {
    return TimeSpan(ticks_ - t.ticks_);
  }

  public TimeSpan opSubAssign(TimeSpan t) {
    ticks_ -= t.ticks_;
    return *this;
  }

  public bool opEquals(TimeSpan t) {
    return ticks_ == t.ticks_;
  }

  public int opCmp(TimeSpan t) {
    if (ticks_ < t.ticks)
      return -1;
    if (ticks_ > t.ticks)
      return 1;
    return 0;
  }

  public TimeSpan opNeg() {
    return TimeSpan(-ticks_);
  }

  public TimeSpan opPos() {
    return TimeSpan(ticks_);
  }

  public TimeSpan duration() {
    return TimeSpan(ticks_ >= 0 ? ticks_ : -ticks_);
  }

  public char[] toString() {

    char[] intToString(int value, int width) {
      bool neg = (value < 0);
      uint l = neg ? cast(uint)-value : cast(uint)value;
      int index = 0;
      char[66] buffer;

      if (l == 0) {
        buffer[0] = '0';
        index = 1;
      }
      else {
        do {
          int v = l % 10;
          l /= 10;
          buffer[index++] = (v < 10) ? cast(char)(v + '0') : cast(char)(v + 'a' - 10);
        } while (l != 0);
      }

      if (neg)
        buffer[index++] = '-';

      int len = (width <= index) ? index : width;
      char[] ret = new char[len];
      int i, j;
      for (i = 0; i < index; i++)
        ret[len - i - 1] = buffer[i];
      for (j = len - i - 1; j >= 0; j--)
        ret[j] = '0';
      return ret;
    }

    int day = cast(int)(ticks_ / cast(long)TICKS_PER_DAY);
    long time = ticks_ % cast(long)TICKS_PER_DAY;
    char[] s;
    if (ticks_ < 0) {
      s ~= '-';
      day = -day;
      time = -time;
    }
    if (day != 0) {
      s ~= .toString(day);
      s ~= '.';
    }
    s ~= intToString(cast(int)(time / TICKS_PER_HOUR % 24), 2);
    s ~= ':';
    s ~= intToString(cast(int)(time / TICKS_PER_MINUTE % 60), 2);
    s ~= ':';
    s ~= intToString(cast(int)(time / TICKS_PER_SECOND % 60), 2);
    int f = cast(int)(time % cast(long)TICKS_PER_SECOND);
    if (f != 0) {
      s ~= '.';
      s ~= intToString(f, 7);
    }
    return s;
  }

  public int days() {
    return cast(int)(ticks_ / cast(long)TICKS_PER_DAY);
  }

  public int hours() {
    return cast(int)((ticks_ / cast(long)TICKS_PER_HOUR) % 24);
  }

  public int minutes() {
    return cast(int)((ticks_ / cast(long)TICKS_PER_MINUTE) % 60);
  }

  public int seconds() {
    return cast(int)((ticks_ / cast(long)TICKS_PER_SECOND) % 60);
  }

  public int milliseconds() {
    return cast(int)((ticks_ / cast(long)TICKS_PER_MILLISECOND) % 1000);
  }

  public long ticks() {
    return ticks_;
  }

  private static TimeSpan interval(double value, int scale) {
    return TimeSpan(cast(long)((value * scale) + ((value >= 0) ? 0.5 : -0.5)) * cast(long)TICKS_PER_MILLISECOND);
  }

}

public struct DateTime {

  private enum Kind : ulong {
    UNKNOWN = 0x0000000000000000,
    UTC = 0x4000000000000000,
    LOCAL = 0x8000000000000000
  }

  private const ulong TICKS_MASK = 0x3FFFFFFFFFFFFFFF;
  private const ulong KIND_MASK = 0xC000000000000000;

  private const ulong MIN_TICKS = 0;
  private const ulong MAX_TICKS = DAYS_TO_10000 * TICKS_PER_DAY - 1;

  private const int KIND_SHIFT = 62;

  private ulong data_;

  public static const DateTime min;
  public static const DateTime max;

  static this() {
    min = DateTime(MIN_TICKS);
    max = DateTime(MAX_TICKS);
  }

  public static DateTime opCall(ulong ticks) {
    DateTime d;
    return d.data_ = ticks,
      d;
  }

  public static DateTime opCall(int year, int month, int day) {
    DateTime d;
    return d.data_ = getDateTicks(year, month, day),
      d;
  }

  public static DateTime opCall(int year, int month, int day, int hour, int minute, int second) {
    DateTime d;
    return d.data_ = getDateTicks(year, month, day) + getTimeTicks(hour, minute, second),
      d;
  }

  public static DateTime opCall(int year, int month, int day, int hour, int minute, int second, int millisecond) {
    DateTime d;
    return d.data_ = getDateTicks(year, month, day) + getTimeTicks(hour, minute, second) + (millisecond * TICKS_PER_MILLISECOND),
      d;
  }

  public bool opEquals(DateTime value) {
    return ticks == value.ticks;
  }

  public bool equals(DateTime value) {
    return ticks == value.ticks;
  }

  public int opCmp(DateTime value) {
    if (ticks < value.ticks)
      return -1;
    if (ticks > value.ticks)
      return 1;
    return 0;
  }

  public int compareTo(DateTime value) {
    if (ticks < value.ticks)
      return -1;
    else if (ticks > value.ticks)
      return 1;
    return 0;
  }

  public DateTime opAdd(TimeSpan t) {
    return add(t);
  }

  public DateTime opAddAssign(TimeSpan t) {
    data_ += t.ticks;
    return *this;
  }

  public DateTime opSub(TimeSpan t) {
    return subtract(t);
  }

  public DateTime opSubAssign(TimeSpan t) {
    data_ -= t.ticks;
    return *this;
  }

  public hash_t toHash() {
    long ticks = this.ticks;
    return (cast(hash_t)ticks ^ cast(hash_t)(ticks >> 32));
  }

  public DateTime add(TimeSpan t) {
    return DateTime(cast(ulong)(ticks + t.ticks));
  }

  public DateTime subtract(TimeSpan t) {
    return DateTime(cast(ulong)(ticks - t.ticks));
  }

  public DateTime addTicks(ulong value) {
    return DateTime((ticks + value) | kind);
  }

  public DateTime addMilliseconds(double value) {
    return addTicks(cast(ulong)cast(long)(value + ((value > 0) ? 0.5 : -0.5)) * TICKS_PER_MILLISECOND);
  }

  public DateTime addSeconds(double value) {
    return addMilliseconds(value * MILLIS_PER_SECOND);
  }

  public DateTime addMinutes(double value) {
    return addMilliseconds(value * MILLIS_PER_MINUTE);
  }

  public DateTime addHours(double value) {
    return addMilliseconds(value * MILLIS_PER_HOUR);
  }

  public DateTime addDays(int value) {
    return addMilliseconds(value * MILLIS_PER_DAY);
  }

  public DateTime addMonths(int value) {
    int year = this.year;
    int month = this.month;
    int day = this.day;
    int n = month - 1 + value;
    if (n >= 0) {
      month = n % 12 + 1;
      year = year + n / 12;
    }
    else {
      month = 12 + (n + 1) % 12;
      year = year + (n - 11) / 12;
    }
    int maxDays = daysInMonth(year, month);
    if (day > maxDays)
      day = maxDays;
    return DateTime((getDateTicks(year, month, day) + (ticks % TICKS_PER_DAY)) | kind);
  }

  public DateTime addYears(int value) {
    return addMonths(value * 12);
  }

  public static int daysInMonth(int year, int month) {
    int[] monthDays = isLeapYear(year) ? DAYS_TO_MONTH_LEAP : DAYS_TO_MONTH_COMMON;
    return monthDays[month] - monthDays[month - 1];
  }

  /**
   * Indicates whether the specified _year is a leap _year.
   * Params: year = A 4-digit _year.
   * Returns: true if year is a leap _year; otherwise, false.
   */
  public static bool isLeapYear(int year) {
    return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0));
  }

  /**
   * Converts the value of this instance to its equivalent string representation using the specified _format and culture-specific formatting information.
   * Params:
   *        format = A _format string.
   *        provider = An IProvidesFormat that supplies culture-specific formatting information.
   */
  public char[] toString(char[] format, IProvidesFormat provider) {
    return formatDateTime(*this, format, DateTimeFormat.getInstance(provider));
  }

  /**
   * Ditto
   */
  public char[] toString(char[] format) {
    return formatDateTime(*this, format, DateTimeFormat.currentFormat);
  }

  /**
   * Ditto
   */
  public char[] toString(IProvidesFormat provider) {
    return formatDateTime(*this, null, DateTimeFormat.getInstance(provider));
  }

  /**
   * Ditto
   */
  public char[] toString() {
    return formatDateTime(*this, null, DateTimeFormat.currentFormat);
  }

  /**
   * Converts the value to local time.
   */
  public DateTime toLocalTime() {
    return TimeZone.convertTimeFromUtc(*this, TimeZone.local);
  }

  /**
   * Converts the value to UTC time.
   */
  public DateTime toUtcTime() {
    return TimeZone.convertTimeToUtc(*this, TimeZone.local);
  }

  /**
   * <i>Property.</i>
   * Returns a DateTime whose value is the current local date and time.
   */
  public static DateTime now() {
    return utcNow.toLocalTime();
  }

  /**
   * <i>Property.</i>
   * Returns a DateTime whose value is the current UTC date and time.
   */
  public static DateTime utcNow() {
    FILETIME ft;
    GetSystemTimeAsFileTime(ft);
    ulong ticks = (cast(ulong)ft.dwHighDateTime << 32) | ft.dwLowDateTime;

    version (BigEndian) {
      ticks = (ticks >> 32) | (ticks << 32);
    }

    return DateTime(cast(ulong)(ticks + (DAYS_TO_1601 * TICKS_PER_DAY)));
  }

  /**
   * Retrives the current date.
   */
  public static DateTime today() {
    return DateTime.now.date;
  }

  /**
   * Retrieves the date.
   */
  public DateTime date() {
    return DateTime(ticks - (ticks % TICKS_PER_DAY));
  }

  /**
   * Retrieves the time of day.
   */
  public TimeSpan timeOfDay() {
    return TimeSpan(cast(long)(ticks % TICKS_PER_DAY));
  }

  /**
   * <i>Property.</i>
   * Retrieves the _year part of the date.
   */
  public int year() {
    return extractPart(ticks, DatePart.YEAR);
  }

  /**
   * <i>Property.</i>
   * Retrieves the _month part of the date.
   */
  public int month() {
    return extractPart(ticks, DatePart.MONTH);
  }

  /**
   * <i>Property.</i>
   * Retrieves the _day of the month.
   */
  public int day() {
    return extractPart(ticks, DatePart.DAY);
  }

  /**
   * <i>Property.</i>
   * Retrieves the day of the year.
   */
  public int dayOfYear() {
    return extractPart(ticks, DatePart.DAY_OF_YEAR);
  }

  /**
   * <i>Property.</i>
   * Retrieves the day of the week.
   */
  public DayOfWeek dayOfWeek() {
    return cast(DayOfWeek)((ticks / TICKS_PER_DAY + 1) % 7);
  }

  /**
   * <i>Property.</i>
   * Retrieves the _hour part of the date.
   */
  public int hour() {
    return cast(int)((ticks / TICKS_PER_HOUR) % 24);
  }

  /**
   * <i>Property.</i>
   * Retrieves the _minute part of the date.
   */
  public int minute() {
    return cast(int)((ticks / TICKS_PER_MINUTE) % 60);
  }

  /**
   * <i>Property.</i>
   * Retrieves the seconds part of the date.
   */
  public int second() {
    return cast(int)((ticks / TICKS_PER_SECOND) % 60);
  }

  /**
   * <i>Property.</i>
   * Retrieves the milliseconds part of the date.
   */
  public int millisecond() {
    return cast(int)((ticks / TICKS_PER_MILLISECOND) % 1000);
  }

  /**
   * <i>Property.</i>
   * Retrieves the number of _ticks representing the date and time.
   */
  public long ticks() {
    return cast(long)(data_ & TICKS_MASK);
  }

  package long kind() {
    return cast(long)(data_ & KIND_MASK);
  }

  private static ulong getDateTicks(int year, int month, int day) {
    int[] monthDays = isLeapYear(year) ? DAYS_TO_MONTH_LEAP : DAYS_TO_MONTH_COMMON;
    year--;
    return (year * 365 + year / 4 - year / 100 + year / 400 + monthDays[month - 1] + day - 1) * TICKS_PER_DAY;
  }

  private static ulong getTimeTicks(int hour, int minute, int second) {
    return (cast(ulong)hour * 3600 + cast(ulong)minute * 60 + cast(ulong)second) * TICKS_PER_SECOND;
  }

}

extern (C)
private wchar* wcscpy(wchar*, wchar*);

/**
 * Represents a time zone.
 *
 * <table>
 * <tr><td><b>Time Zone Identifier</b></td><td width="15%"><b>Offset</b></td><td><b>Location</b></td></tr>
 * <tr><td>Afghanistan Standard Time</td><td>GMT+04:30</td><td>Kabul</td></tr>
 * <tr><td>Alaskan Standard Time</td><td>GMT-09:00</td><td>Alaska</td></tr>
 * <tr><td>Arab Standard Time</td><td>GMT+03:00</td><td>Kuwait, Riyadh</td></tr>
 * <tr><td>Arabian Standard Time</td><td>GMT+04:00</td><td>Abu Dhabi, Muscat</td></tr>
 * <tr><td>Arabic Standard Time</td><td>GMT+03:00</td><td>Baghdad</td></tr>
 * <tr><td>Atlantic Standard Time</td><td>GMT-04:00</td><td>Atlantic Time (Canada)</td></tr>
 * <tr><td>AUS Central Standard Time</td><td>GMT+09:30</td><td>Darwin</td></tr>
 * <tr><td>AUS Eastern Standard Time</td><td>GMT+10:00</td><td>Canberra, Melbourne, Sydney</td></tr>
 * <tr><td>Azores Standard Time</td><td>GMT-01:00</td><td>Azores</td></tr>
 * <tr><td>Canada Central Standard Time</td><td>GMT-06:00</td><td>Saskatchewan</td></tr>
 * <tr><td>Cape Verde Standard Time</td><td>GMT-01:00</td><td>Cape Verde Is.</td></tr>
 * <tr><td>Caucasus Standard Time</td><td>GMT+04:00</td><td>Baku, Tbilisi, Yerevan</td></tr>
 * <tr><td>Cen. Australia Standard Time</td><td>GMT+09:30</td><td>Adelaide</td></tr>
 * <tr><td>Central America Standard Time</td><td>GMT-06:00</td><td>Central America</td></tr>
 * <tr><td>Central Asia Standard Time</td><td>GMT+06:00</td><td>Astana, Dhaka</td></tr>
 * <tr><td>Central Europe Standard Time</td><td>GMT+01:00</td><td>Belgrade, Bratislava, Budapest, Ljubljana, Prague</td></tr>
 * <tr><td>Central European Standard Time</td><td>GMT+01:00</td><td>Sarajevo, Skopje, Warsaw, Zagreb</td></tr>
 * <tr><td>Central Pacific Standard Time</td><td>GMT+11:00</td><td>Magadan, Solomon Is., New Caledonia</td></tr>
 * <tr><td>Central Standard Time</td><td>GMT-06:00</td><td>Central Time (US & Canada)</td></tr>
 * <tr><td>China Standard Time</td><td>GMT+08:00</td><td>Beijing, Chongqing, Hong Kong, Urumqi</td></tr>
 * <tr><td>Dateline Standard Time</td><td>GMT-12:00</td><td>International Date Line West</td></tr>
 * <tr><td>E. Africa Standard Time</td><td>GMT+03:00</td><td>Nairobi</td></tr>
 * <tr><td>E. Australia Standard Time</td><td>GMT+10:00</td><td>Brisbane</td></tr>
 * <tr><td>E. Europe Standard Time</td><td>GMT+02:00</td><td>Bucharest</td></tr>
 * <tr><td>E. South America Standard Time</td><td>GMT-03:00</td><td>Brasilia</td></tr>
 * <tr><td>Eastern Standard Time</td><td>GMT-05:00</td><td>Eastern Time (US & Canada)</td></tr>
 * <tr><td>Egypt Standard Time</td><td>GMT+02:00</td><td>Cairo</td></tr>
 * <tr><td>Ekaterinburg Standard Time</td><td>GMT+05:00</td><td>Ekaterinburg</td></tr>
 * <tr><td>Fiji Standard Time</td><td>GMT+12:00</td><td>Fiji, Kamchatka, Marshall Is.</td></tr>
 * <tr><td>FLE Standard Time</td><td>GMT+02:00</td><td>Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius</td></tr>
 * <tr><td>GMT Standard Time</td><td>GMT</td><td>Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London</td></tr>
 * <tr><td>Greenland Standard Time</td><td>GMT-03:00</td><td>Greenland</td></tr>
 * <tr><td>Greenwich Standard Time</td><td>GMT</td><td>Casablanca, Monrovia</td></tr>
 * <tr><td>GTB Standard Time</td><td>GMT+02:00</td><td>Athens, Beirut, Istanbul, Minsk</td></tr>
 * <tr><td>Hawaiian Standard Time</td><td>GMT-10:00</td><td>Hawaii</td></tr>
 * <tr><td>India Standard Time</td><td>GMT+05:30</td><td>Chennai, Kolkata, Mumbai, New Delhi</td></tr>
 * <tr><td>Iran Standard Time</td><td>GMT+03:30</td><td>Tehran</td></tr>
 * <tr><td>Israel Standard Time</td><td>GMT+02:00</td><td>Jerusalem</td></tr>
 * <tr><td>Korea Standard Time</td><td>GMT+09:00</td><td>Seoul</td></tr>
 * <tr><td>Mexico Standard Time</td><td>GMT-06:00</td><td>Guadalajara, Mexico City, Monterrey</td></tr>
 * <tr><td>Mexico Standard Time 2</td><td>GMT-07:00</td><td>Chihuahua, La Paz, Mazatlan</td></tr>
 * <tr><td>Mid-Atlantic Standard Time</td><td>GMT-02:00</td><td>Mid-Atlantic</td></tr>
 * <tr><td>Mountain Standard Time</td><td>GMT-07:00</td><td>Mountain Time (US & Canada)</td></tr>
 * <tr><td>Myanmar Standard Time</td><td>GMT+06:30</td><td>Rangoon</td></tr>
 * <tr><td>N. Central Asia Standard Time</td><td>GMT+06:00</td><td>Almaty, Novosibirsk</td></tr>
 * <tr><td>Nepal Standard Time</td><td>GMT+05:45</td><td>Kathmandu</td></tr>
 * <tr><td>New Zealand Standard Time</td><td>GMT+12:00</td><td>Auckland, Wellington</td></tr>
 * <tr><td>Newfoundland Standard Time</td><td>GMT-03:30</td><td>Newfoundland</td></tr>
 * <tr><td>North Asia East Standard Time</td><td>GMT+08:00</td><td>Irkutsk, Ulaan Bataar</td></tr>
 * <tr><td>North Asia Standard Time</td><td>GMT+07:00</td><td>Krasnoyarsk</td></tr>
 * <tr><td>Pacific SA Standard Time</td><td>GMT-04:00</td><td>Santiago</td></tr>
 * <tr><td>Pacific Standard Time</td><td>GMT-08:00</td><td>Pacific Time (US & Canada); Tijuana</td></tr>
 * <tr><td>Romance Standard Time</td><td>GMT+01:00</td><td>Brussels, Copenhagen, Madrid, Paris</td></tr>
 * <tr><td>Russian Standard Time</td><td>GMT+03:00</td><td>Moscow, St. Petersburg, Volgograd</td></tr>
 * <tr><td>SA Eastern Standard Time</td><td>GMT-03:00</td><td>Buenos Aires, Georgetown</td></tr>
 * <tr><td>SA Pacific Standard Time</td><td>GMT-05:00</td><td>Bogota, Lima, Quito</td></tr>
 * <tr><td>SA Western Standard Time</td><td>GMT-04:00</td><td>Caracas, La Paz</td></tr>
 * <tr><td>Samoa Standard Time</td><td>GMT-11:00</td><td>Midway Island, Samoa</td></tr>
 * <tr><td>SE Asia Standard Time</td><td>GMT+07:00</td><td>Bangkok, Hanoi, Jakarta</td></tr>
 * <tr><td>Singapore Standard Time</td><td>GMT+08:00</td><td>Kuala Lumpur, Singapore</td></tr>
 * <tr><td>South Africa Standard Time</td><td>GMT+02:00</td><td>Harare, Pretoria</td></tr>
 * <tr><td>Sri Lanka Standard Time</td><td>GMT+06:00</td><td>Sri Jayawardenepura</td></tr>
 * <tr><td>Taipei Standard Time</td><td>GMT+08:00</td><td>Taipei</td></tr>
 * <tr><td>Tasmania Standard Time</td><td>GMT+10:00</td><td>Hobart</td></tr>
 * <tr><td>Tokyo Standard Time</td><td>GMT+09:00</td><td>Osaka, Sapporo, Tokyo</td></tr>
 * <tr><td>Tonga Standard Time</td><td>GMT+13:00</td><td>Nuku'alofa</td></tr>
 * <tr><td>US Eastern Standard Time</td><td>GMT-05:00</td><td>Indiana (East)</td></tr>
 * <tr><td>US Mountain Standard Time</td><td>GMT-07:00</td><td>Arizona</td></tr>
 * <tr><td>Vladivostok Standard Time</td><td>GMT+10:00</td><td>Vladivostok</td></tr>
 * <tr><td>W. Australia Standard Time</td><td>GMT+08:00</td><td>Perth</td></tr>
 * <tr><td>W. Central Africa Standard Time</td><td>GMT+01:00</td><td>West Central Africa</td></tr>
 * <tr><td>W. Europe Standard Time</td><td>GMT+01:00</td><td>Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna</td></tr>
 * <tr><td>West Asia Standard Time</td><td>GMT+05:00</td><td>Islamabad, Karachi, Tashkent</td></tr>
 * <tr><td>West Pacific Standard Time</td><td>GMT+10:00</td><td>Guam, Port Moresby</td></tr>
 * <tr><td>Yakutsk Standard Time</td><td>GMT+09:00</td><td>Yakutsk</td></tr>
 * </table>
 */
public class TimeZone {

  private char[] id_;
  private char[] standardName_;
  private char[] daylightName_;
  private char[] displayName_;
  private TIME_ZONE_INFORMATION timeZoneData_;

  private static const char[] TIME_ZONES_KEY;
  private static TimeZone localTimeZone_;

  static this() {
    OSVERSIONINFO osvi;
    GetVersionEx(osvi);
    if (osvi.dwPlatformId == VER_PLATFORM_WIN32_NT) // Windows 2000 and above
      TIME_ZONES_KEY = "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Time Zones";
    else
      TIME_ZONES_KEY = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Time Zones";
  }

  /**
   * Converts a DateTime from one _time zone to another.
   */
  public static DateTime convertTime(DateTime time, TimeZone fromTimeZone, TimeZone toTimeZone) {
    DateTime utcTime = fromTimeZone.toUniversalTime(time);
    return toTimeZone.toLocalTime(utcTime);
  }

  public static DateTime convertTimeFromUtc(DateTime utcTime, TimeZone timeZone) {
    return timeZone.toLocalTime(utcTime);
  }

  public static DateTime convertTimeToUtc(DateTime localTime, TimeZone timeZone) {
    return timeZone.toUniversalTime(localTime);
  }

  /**
   * Returns a list of time zones supported by the system.
   */
  public static TimeZone[] getSystemTimeZones() {
    synchronized {
      TimeZone[] timeZones = null;

      scope RegistryKey key = RegistryKey.localMachine.openSubKey(TIME_ZONES_KEY);
      if (key !is null) {
        if (key.subKeyCount > 0) {
          // Set the capacity.
          timeZones.length = key.subKeyCount;
          timeZones.length = 0;
          foreach (id; key.subKeyNames)
            timeZones ~= systemTimeZoneById(id);
        }
      }

      return timeZones;
    }
  }

  /**
   * Returns the time zone with the specified time zone identifier.
   */
  public static TimeZone systemTimeZoneById(char[] id) {
    synchronized {
      TimeZone timeZone = null;

      scope RegistryKey key = RegistryKey.localMachine.openSubKey(TIME_ZONES_KEY ~ '\\' ~ id);
      if (key !is null) {
        TIME_ZONE_INFORMATION tzi;
        wcscpy(tzi.StandardName, key.getStringValue("Std").toUTF16z());
        wcscpy(tzi.DaylightName, key.getStringValue("Dlt").toUTF16z());

        REG_TIME_ZONE_INFORMATION rtzi;
        ubyte[] buffer = key.getBinaryValue("TZI");
        memcpy(&rtzi, buffer.ptr, REG_TIME_ZONE_INFORMATION.sizeof);

        tzi.Bias = rtzi.Bias;
        tzi.StandardBias = rtzi.StandardBias;
        tzi.DaylightBias = rtzi.DaylightBias;
        tzi.StandardDate = rtzi.StandardDate;
        tzi.DaylightDate = rtzi.DaylightDate;

        char[] display = key.getStringValue("Display");

        timeZone = new TimeZone(id, display, tzi);
      }
      else
        throw new ArgumentException("'" ~ id ~ "' is not a valid time zone.", "id");

      return timeZone;
    }
  }

  /**
   * Retrieves the _local time zone.
   */
  public static TimeZone local() {
    synchronized {
      if (localTimeZone_ is null) {
        scope RegistryKey key = RegistryKey.localMachine.openSubKey("SYSTEM\\CurrentControlSet\\Control\\TimeZoneInformation");
        if (key !is null) {
          char[] id = key.getStringValue("StandardName");
          localTimeZone_ = systemTimeZoneById(id);
        }
      }
      return localTimeZone_;
    }
  }

  /**
   * Retrieves the time zone identifier.
   */
  public char[] id() {
    return id_;
  }

  /**
   * Retrieves the standard time zone name.
   */
  public char[] standardName() {
    return standardName_;
  }

  /**
   * Retrieves the daylight saving time zone name.
   */
  public char[] daylightName() {
    return daylightName_;
  }

  /**
   * Retrieves the human-readable name of the time zone.
   */
  public char[] displayName() {
    return displayName_;
  }

  public TimeSpan baseUtcOffset() {
    return TimeSpan.fromMinutes(-(timeZoneData_.Bias + timeZoneData_.StandardBias));
  }

  private this(char[] id, char[] displayName, TIME_ZONE_INFORMATION timeZoneData) {
    id_ = id;
    displayName_ = displayName;
    timeZoneData_ = timeZoneData;
  }

  private DateTime toLocalTime(DateTime time) {
    SYSTEMTIME utcTime = dateTimeToSystemTime(time);
    SYSTEMTIME localTime;
    try {
      SystemTimeToTzSpecificLocalTime(&timeZoneData_, &utcTime, &localTime);
    }
    catch (EntryPointNotFoundException) {
      throw new NotSupportedException;
    }
    return systemTimeToDateTime(localTime);
  }

  private DateTime toUniversalTime(DateTime time) {
    SYSTEMTIME localTime = dateTimeToSystemTime(time);
    SYSTEMTIME utcTime;
    try {
      TzSpecificLocalTimeToSystemTime(&timeZoneData_, &localTime, &utcTime);
    }
    catch (EntryPointNotFoundException) {
      throw new NotSupportedException;
    }
    return systemTimeToDateTime(utcTime);
  }

  private static SYSTEMTIME dateTimeToSystemTime(DateTime time) {
    FILETIME ft;
    ft.dwHighDateTime = cast(uint)(time.ticks >> 32);
    ft.dwLowDateTime = cast(uint)(time.ticks & 0xFFFFFFFF);
    SYSTEMTIME st;
    FileTimeToSystemTime(ft, st);
    return st;
  }

  private static DateTime systemTimeToDateTime(inout SYSTEMTIME st) {
    FILETIME ft;
    SystemTimeToFileTime(st, ft);
    return DateTime((cast(ulong)ft.dwHighDateTime << 32) | ft.dwLowDateTime);
  }

}