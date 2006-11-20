module juno.intl.constants;

/** 
 * Defines options to use with Collation.
 */
public enum CompareOptions {
  /// Indicates default options for string comparisions.
  None = 0x0,
  /// Indicates that the string comparison ignores case.
  IgnoreCase = 0x1,
  /// Indicates that the string comparison ignores non-space characters such as diacritcs.
  IgnoreNonSpace = 0x2,
  /// Indicates that the string comparison ignores symbols such as white-space characters, punctuation, currency symbols etc.
  IgnoreSymbols = 0x4,
  /// Indicates that the string comparison ignores full-width and half-width characters.
  IgnoreWidth = 0x8,
  /// Indicates that the string comparison uses the string sort algorithm where hyphens, apostrophies and other non-alphanumeric symbols take precendence over alphanumeric characters.
  StringSort = 0x10000000
}

public enum NumberStyles {
  None = 0x0,
  LeadingWhite = 0x1,
  TrailingWhite = 0x2,
  LeadingSign = 0x4,
  TrailingSign = 0x8,
  Parentheses = 0x10,
  DecimalPoint = 0x20,
  Thousands = 0x40,
  Exponent = 0x80,
  CurrencySymbol = 0x100,
  HexSpecified = 0x200,
  Integer = LeadingWhite | TrailingWhite | LeadingSign,
  Float = LeadingWhite | TrailingWhite | LeadingSign | DecimalPoint | Exponent,
  Number = LeadingWhite | TrailingWhite | LeadingSign | TrailingSign | DecimalPoint | Thousands,
}

/// Defines the types of culture that can be retrieved using Culture.getCultures(CultureTypes).
public enum CultureTypes {
  /// Cultures that are associated with a language but are not specific to a country.
  Neutral = 0x1,
  /// Cultures that represent a specific language and country.
  Specific = 0x2,
  /// Cultures that are installed in Windows.
  Installed = 0x4,
  /// All cultures including neutral and specific cultures, and those installed in Windows.
  All = Neutral | Specific | Installed
}

/**
 * Specifies the day of the week.
 */
public enum DayOfWeek {
  /// Indicates _Sunday.
  Sunday,
  /// Indicates _Monday.
  Monday,
  /// Indicates _Tuesday.
  Tuesday,
  /// Indicates _Wednesday.
  Wednesday,
  /// Indicates _Thursday.
  Thursday,
  /// Indicates _Friday.
  Friday,
  /// Indicates _Saturday.
  Saturday
}

/**
 * Defines rules for determining the first week of the year.
 */
public enum CalendarWeekRule {
  ///
  FirstDay,
  ///
  FirstFullWeek,
  ///
  FirstFourDayWeek
}