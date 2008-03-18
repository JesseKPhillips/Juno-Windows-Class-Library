/**
 * Copyright: (c) 2008 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.locale.constants;

enum CultureTypes {
  Neutral   = 0x1,
  Specific  = 0x2,
  All       = Neutral | Specific
}

enum DayOfWeek {
  Sunday,
  Monday,
  Tuesday,
  Wednesday,
  Thursday,
  Friday,
  Saturday
}

enum GregorianCalendarType {
  Localized             = 1,
  USEnglish             = 2,
  MiddleEastFrench      = 9,
  Arabic                = 10,
  TransliteratedEnglish = 11,
  TransliteratedFrench  = 12,
}

enum CalendarWeekRule {
  FirstDay,
  FirstFullWeek,
  FirstFourDayWeek
}

enum NumberStyles {
  None            = 0x0,
  LeadingWhite    = 0x1,
  TrailingWhite   = 0x2,
  LeadingSign     = 0x4,
  TrailingSign    = 0x8,
  Parentheses     = 0x10,
  DecimalPoint    = 0x20,
  Thousands       = 0x40,
  Exponent        = 0x80,
  CurrencySymbol  = 0x100,
  HexSpecifier    = 0x200,
  Integer         = LeadingWhite | TrailingWhite | LeadingSign,
  Float           = LeadingWhite | TrailingWhite | LeadingSign | DecimalPoint | Exponent,
  Number          = LeadingWhite | TrailingWhite | LeadingSign | TrailingSign | DecimalPoint | Thousands
}

enum CompareOptions {
  None                = 0x0,
  IgnoreCase          = 0x1,
  IgnoreNonSpace      = 0x2,
  IgnoreSymbols       = 0x4,
  IgnoreWidth         = 0x10,
  //Ordinal           = 0x10000000,
  //OrdinalIgnoreCase = 0x20000000
}