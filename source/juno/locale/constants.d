/**
 * Copyright: (c) 2009 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.locale.constants;

/// Defines the types of culture lists that can be retrieved by Culture.getCultures.
enum CultureTypes {
  Neutral  = 0x1,               /// Cultures associated with a language but not a country/region.
  Specific = 0x2,               /// Cultures specific to a country/region.
  All      = Neutral | Specific /// _All cultures, including neutral and specific cultures.
}

/// Defines the string comparison options to use with Collator.
enum CompareOptions {
  None                = 0x0,        /// Indicates the default option for string comparisons.
  IgnoreCase          = 0x1,        /// Indicates that the string comparison must ignore case.
  IgnoreNonSpace      = 0x2,        /// Indicates that the string comparison must ignore nonspacing combining characters, such as diacritics.
  IgnoreSymbols       = 0x4,        /// Indicates that the string comparison must ignore symbols, such as white-space characters and punctuation.
  IgnoreWidth         = 0x10,       /// Indicates that the string comparison must ignore the character width.
  //Ordinal           = 0x10000000,
  //OrdinalIgnoreCase = 0x20000000
}

/// Specifies the day of the week.
enum DayOfWeek {
  Sunday,    /// Indicates _Sunday.
  Monday,    /// Indicates _Monday.
  Tuesday,   /// Indicates _Tuesday.
  Wednesday, /// Indicates _Wednesday.
  Thursday,  /// Indicates _Thursday.
  Friday,    /// Indicates _Friday.
  Saturday   /// Indicates _Saturday.
}

/// Defines rules for determining the first week of the year.
enum CalendarWeekRule {
  FirstDay,        ///
  FirstFullWeek,   ///
  FirstFourDayWeek ///
}

/// Defines the different language versions of the Gregorian calendar.
enum GregorianCalendarType {
  Localized             = 1,  /// The localized version of the Gregorian calendar.
  USEnglish             = 2,  /// The U.S. English version of the Gregorian calendar.
  MiddleEastFrench      = 9,  /// The Middle East French version of the Gregorian calendar.
  Arabic                = 10, /// The _Arabic version of the Gregorian calendar.
  TransliteratedEnglish = 11, /// The transliterated English version of the Gregorian calendar.
  TransliteratedFrench  = 12  /// The transliterated French version of the Gregorian calendar.
}

/// Determines the styles allowed in numeric string arguments passed to parse and tryParse methods.
enum NumberStyles {
  None           = 0x0,   ///
  LeadingWhite   = 0x1,   ///
  TrailingWhite  = 0x2,   ///
  LeadingSign    = 0x4,   ///
  TrailingSign   = 0x8,   ///
  Parentheses    = 0x10,  ///
  DecimalPoint   = 0x20,  ///
  Thousands      = 0x40,  ///
  Exponent       = 0x80,  ///
  CurrencySymbol = 0x100, ///
  HexSpecifier   = 0x200, ///
  Integer        = LeadingWhite | TrailingWhite | LeadingSign,                                          ///
  Float          = LeadingWhite | TrailingWhite | LeadingSign | DecimalPoint | Exponent,                ///
  Number         = LeadingWhite | TrailingWhite | LeadingSign | TrailingSign | DecimalPoint | Thousands ///
}