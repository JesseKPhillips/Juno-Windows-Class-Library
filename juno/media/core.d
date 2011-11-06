/**
 * Provides access to basic GDI+ graphics functionality.
 *
 * For detailed information, refer to MSDN's documentation for the $(LINK2 http://msdn2.microsoft.com/en-us/library/system.drawing.aspx, System.Drawing) namespace.
 *
 * Copyright: (c) 2008 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.media.core;

private import juno.base.core,
  juno.base.string,
  juno.base.math,
  juno.base.native,
  juno.com.core,
  juno.media.constants,
  juno.media.geometry,
  juno.media.imaging,
  juno.media.native;

//NOTE: Workaround for bug 314
alias juno.com.core.GUID GUID;

private import std.math : ceil;
private import std.string : toLower, format;
private import std.utf : toUTF16z;
private import std.stream : Stream, SeekPos;

debug private import std.stdio : writefln;

/**
 * Represents an ARGB color.
 */
struct Color {

  private const ulong UNDEFINED_COLOR_VALUE = 0;

  private enum : ushort {
    STATE_VALUE_VALID = 1,
    STATE_KNOWNCOLOR_VALID = 2,
    STATE_NAME_VALID = 4
  }

  private enum {
    ARGB_ALPHA_SHIFT = 24,
    ARGB_RED_SHIFT = 16,
    ARGB_GREEN_SHIFT = 8,
    ARGB_BLUE_SHIFT = 0
  }

  private enum {
    WIN32_RED_SHIFT = 0,
    WIN32_GREEN_SHIFT = 8,
    WIN32_BLUE_SHIFT = 16
  }

  private static uint[] colorTable_;
  private static string[] nameTable_;

  private ulong value_;
  private ushort state_;
  private ushort knownColor_;
  private string name_;

  /**
   * Represents an uninitialized color.
   */
  static Color empty = { UNDEFINED_COLOR_VALUE, 0, 0 };

  /**
   * Creates a Color structure from the ARGB component values.
   */
  static Color fromArgb(ubyte alpha, Color baseColor) {
    return Color(makeArgb(alpha, baseColor.r, baseColor.g, baseColor.b), STATE_VALUE_VALID, null, cast(KnownColor)0);
  }

  /**
   * ditto
   */
  static Color fromArgb(ubyte a, ubyte r, ubyte g, ubyte b) {
    return Color(makeArgb(a, r, g, b), STATE_VALUE_VALID, null, cast(KnownColor)0);
  }

  /**
   * ditto
   */
  static Color fromArgb(ubyte r, ubyte g, ubyte b) {
    return fromArgb(255, r, g, b);
  }

  /**
   * ditto
   */
  static Color fromArgb(uint argb) {
    return Color(argb & 0xFFFFFFFF, STATE_VALUE_VALID, null, cast(KnownColor)0);
  }

  static Color fromRgb(uint color) {
    Color ret = fromArgb(cast(ubyte)((color >> WIN32_RED_SHIFT) & 255), cast(ubyte)((color >> WIN32_GREEN_SHIFT) & 255), cast(ubyte)((color >> WIN32_BLUE_SHIFT) & 255));
    uint argb = ret.toArgb();

    if (colorTable_ == null)
      initColorTable();

    for (int i = 0; i < colorTable_.length; i++) {
      uint c = colorTable_[i];
      if (c == argb) {
        ret = fromKnownColor(cast(KnownColor)i);
        if (!ret.isSystemColor)
          return ret;
      }
    }
    return ret;
  }

  /**
   * Creates a Color structure from the specified predefined _color.
   */
  static Color fromKnownColor(KnownColor color) {
    return Color(color);
  }

  /**
   * Creates a Color structure from the specified _name of a predefined _color.
   */
  static Color fromName(string name) {
    if (nameTable_ == null)
      initNameTable();

    foreach (key, value; nameTable_) {
      if (value.toLower() == name.toLower())
        return fromKnownColor(cast(KnownColor)key);
    }

    return Color(0, STATE_NAME_VALID, name, cast(KnownColor)0);
  }

  /**
   * Gets the ARGB value.
   */
  uint toArgb() {
    return cast(uint)value;
  }

  /**
   * Gets the KnownColor value.
   */
  KnownColor toKnownColor() {
    return cast(KnownColor)knownColor_;
  }

  uint toRgb() {
    return (r << WIN32_RED_SHIFT) | (g << WIN32_GREEN_SHIFT) | (b << WIN32_BLUE_SHIFT);
  }

  /**
   * Converts this Color to a human-readable string.
   */
  string toString() {
    string s = "Color [";
    if ((state_ & STATE_KNOWNCOLOR_VALID) != 0)
      s ~= name;
    else if ((state_ & STATE_VALUE_VALID) != 0)
      s ~= format("A={0}, R={1}, G={2}, B={3}", a, r, g, b);
    else
      s ~= "Empty";
    s ~= "]";
    return s;
  }

  hash_t toHash() {
    return cast(int)value_ ^ cast(int)state_ ^ cast(int)knownColor_;
  }

  bool opEquals(Color other) {
    return value_ == other.value_ && state_ == other.state_ && knownColor_ == other.knownColor_ && name_ == other.name_;
  }

  /**
   * Gets the HSB brightness value.
   */
  float getBrightness() {
    ubyte minVal = cast(ubyte)min(cast(int)r, min(cast(int)g, cast(int)b));
    ubyte maxVal = cast(ubyte)max(cast(int)r, max(cast(int)g, cast(int)b));
    return cast(float)(minVal + maxVal) / 510;
  }

  /**
   * Gets the HSB saturation value.
   */
  float getSaturation() {
    ubyte minVal = cast(ubyte)min(cast(int)r, min(cast(int)g, cast(int)b));
    ubyte maxVal = cast(ubyte)max(cast(int)r, max(cast(int)g, cast(int)b));

    if (maxVal == minVal)
      return 0;

    int sum = minVal + maxVal;
    if (sum > 255)
      sum = 510 - sum;
    return cast(float)(maxVal - minVal) / sum;
  }

  /**
   * Gets the HSB hue value.
   */
  float getHue() {
    ubyte r = this.r;
    ubyte g = this.g;
    ubyte b = this.b;
    ubyte minVal = cast(ubyte)min(cast(int)r, min(cast(int)g, cast(int)b));
    ubyte maxVal = cast(ubyte)max(cast(int)r, max(cast(int)g, cast(int)b));

    if (maxVal == minVal)
      return 0;

    float diff = cast(float)(maxVal - minVal);
    float rnorm = (maxVal - r) / diff;
    float gnorm = (maxVal - g) / diff;
    float bnorm = (maxVal - b) / diff;

    float hue = 0.0;
    if (r == maxVal)
      hue = 60.0f * (6.0f + bnorm - gnorm);
    if (g == maxVal)
      hue = 60.0f * (2.0f + rnorm - bnorm);
    if (b == maxVal)
      hue = 60.0f * (4.0f + gnorm - rnorm);
    if (hue > 360.0f)
      hue -= 360.0f;
    return hue;
  }

  /**
   * Gets the _name.
   */
  string name() {
    if ((state_ & STATE_NAME_VALID) != 0)
      return name_;

    if ((state_ & STATE_KNOWNCOLOR_VALID) == 0)
      return format("%x", value_);

    if (nameTable_ == null)
      initNameTable();
    return nameTable_[knownColor_];
  }

  /**
   * Determines whether this Color structure is uninitialized.
   */
  bool isEmpty() {
    return state_ == 0;
  }

  /**
   * Determines whether this Color structure is predefined.
   */
  bool isKnownColor() {
    return (state_ & STATE_KNOWNCOLOR_VALID) != 0;
  }

  /**
   * Determines whether this Color structure is a system color.
   */
  bool isSystemColor() {
    return isKnownColor 
      && (knownColor_ <= KnownColor.WindowText 
        || knownColor_ >= KnownColor.ButtonFace);
  }

  /**
   * Gets the alpha component.
   */
  ubyte a() {
    return cast(ubyte)((value >> ARGB_ALPHA_SHIFT) & 255);
  }

  /**
   * Gets the red component.
   */
  ubyte r() {
    return cast(ubyte)((value >> ARGB_RED_SHIFT) & 255);
  }

  /**
   * Gets the green component.
   */
  ubyte g() {
    return cast(ubyte)((value >> ARGB_GREEN_SHIFT) & 255);
  }

  /**
   * Gets the blue component.
   */
  ubyte b() {
    return cast(ubyte)((value >> ARGB_BLUE_SHIFT) & 255);
  }
  
  /// Gets a system-defined color.
  static Color activeBorder() { return Color(KnownColor.ActiveBorder); }

  /// ditto
  static Color activeCaption() { return Color(KnownColor.ActiveCaption); }

	/// ditto
  static Color activeCaptionText() { return Color(KnownColor.ActiveCaptionText); }

	/// ditto
  static Color appWorkspace() { return Color(KnownColor.AppWorkspace); }

	/// ditto
  static Color control() { return Color(KnownColor.Control); }

	/// ditto
  static Color controlDark() { return Color(KnownColor.ControlDark); }

	/// ditto
  static Color controlDarkDark() { return Color(KnownColor.ControlDarkDark); }

	/// ditto
  static Color controlLight() { return Color(KnownColor.ControlLight); }

	/// ditto
  static Color controlLightLight() { return Color(KnownColor.ControlLightLight); }

	/// ditto
  static Color controlText() { return Color(KnownColor.ControlText); }

	/// ditto
  static Color desktop() { return Color(KnownColor.Desktop); }

	/// ditto
  static Color grayText() { return Color(KnownColor.GrayText); }

  /// ditto
	static Color highlight() { return Color(KnownColor.Highlight); }

  /// ditto
	static Color highlightText() { return Color(KnownColor.HighlightText); }

  /// ditto
	static Color hotTrack() { return Color(KnownColor.HotTrack); }

  /// ditto
	static Color inactiveBorder() { return Color(KnownColor.InactiveBorder); }

  /// ditto
	static Color inactiveCaption() { return Color(KnownColor.InactiveCaption); }

  /// ditto
	static Color inactiveCaptionText() { return Color(KnownColor.InactiveCaptionText); }

  /// ditto
	static Color info() { return Color(KnownColor.Info); }

  /// ditto
	static Color infoText() { return Color(KnownColor.InfoText); }

  /// ditto
	static Color menu() { return Color(KnownColor.Menu); }

  /// ditto
	static Color menuText() { return Color(KnownColor.MenuText); }

  /// ditto
	static Color scrollBar() { return Color(KnownColor.ScrollBar); }

  /// ditto
	static Color window() { return Color(KnownColor.Window); }

  /// ditto
	static Color windowFrame() { return Color(KnownColor.WindowFrame); }

  /// ditto
	static Color windowText() { return Color(KnownColor.WindowText); }

  /// ditto
	static Color transparent() { return Color(KnownColor.Transparent); }

  /// ditto
	static Color aliceBlue() { return Color(KnownColor.AliceBlue); }

  /// ditto
	static Color antiqueWhite() { return Color(KnownColor.AntiqueWhite); }

  /// ditto
	static Color aqua() { return Color(KnownColor.Aqua); }

  /// ditto
	static Color aquamarine() { return Color(KnownColor.Aquamarine); }

  /// ditto
	static Color azure() { return Color(KnownColor.Azure); }

  /// ditto
	static Color beige() { return Color(KnownColor.Beige); }

  /// ditto
	static Color bisque() { return Color(KnownColor.Bisque); }

  /// ditto
	static Color black() { return Color(KnownColor.Black); }

  /// ditto
	static Color blanchedAlmond() { return Color(KnownColor.BlanchedAlmond); }

  /// ditto
	static Color blue() { return Color(KnownColor.Blue); }

  /// ditto
	static Color blueViolet() { return Color(KnownColor.BlueViolet); }

  /// ditto
	static Color brown() { return Color(KnownColor.Brown); }

  /// ditto
	static Color burlyWood() { return Color(KnownColor.BurlyWood); }

  /// ditto
	static Color cadetBlue() { return Color(KnownColor.CadetBlue); }

  /// ditto
	static Color chartreuse() { return Color(KnownColor.Chartreuse); }

  /// ditto
	static Color chocolate() { return Color(KnownColor.Chocolate); }

  /// ditto
	static Color coral() { return Color(KnownColor.Coral); }

  /// ditto
	static Color cornflowerBlue() { return Color(KnownColor.CornflowerBlue); }

  /// ditto
	static Color cornsilk() { return Color(KnownColor.Cornsilk); }

  /// ditto
	static Color crimson() { return Color(KnownColor.Crimson); }

  /// ditto
	static Color cyan() { return Color(KnownColor.Cyan); }

  /// ditto
	static Color darkBlue() { return Color(KnownColor.DarkBlue); }

  /// ditto
	static Color darkCyan() { return Color(KnownColor.DarkCyan); }

  /// ditto
	static Color darkGoldenrod() { return Color(KnownColor.DarkGoldenrod); }

  /// ditto
	static Color darkGray() { return Color(KnownColor.DarkGray); }

  /// ditto
	static Color darkGreen() { return Color(KnownColor.DarkGreen); }

  /// ditto
	static Color darkKhaki() { return Color(KnownColor.DarkKhaki); }

  /// ditto
	static Color darkMagenta() { return Color(KnownColor.DarkMagenta); }

  /// ditto
	static Color darkOliveGreen() { return Color(KnownColor.DarkOliveGreen); }

  /// ditto
	static Color darkOrange() { return Color(KnownColor.DarkOrange); }

  /// ditto
	static Color darkOrchid() { return Color(KnownColor.DarkOrchid); }

  /// ditto
	static Color darkRed() { return Color(KnownColor.DarkRed); }

  /// ditto
	static Color darkSalmon() { return Color(KnownColor.DarkSalmon); }

  /// ditto
	static Color darkSeaGreen() { return Color(KnownColor.DarkSeaGreen); }

  /// ditto
	static Color darkSlateBlue() { return Color(KnownColor.DarkSlateBlue); }

  /// ditto
	static Color darkSlateGray() { return Color(KnownColor.DarkSlateGray); }

  /// ditto
	static Color darkTurquoise() { return Color(KnownColor.DarkTurquoise); }

  /// ditto
	static Color darkViolet() { return Color(KnownColor.DarkViolet); }

  /// ditto
	static Color deepPink() { return Color(KnownColor.DeepPink); }

  /// ditto
	static Color deepSkyBlue() { return Color(KnownColor.DeepSkyBlue); }

  /// ditto
	static Color dimGray() { return Color(KnownColor.DimGray); }

  /// ditto
	static Color dodgerBlue() { return Color(KnownColor.DodgerBlue); }

  /// ditto
	static Color firebrick() { return Color(KnownColor.Firebrick); }

  /// ditto
	static Color floralWhite() { return Color(KnownColor.FloralWhite); }

  /// ditto
	static Color forestGreen() { return Color(KnownColor.ForestGreen); }

  /// ditto
	static Color fuchsia() { return Color(KnownColor.Fuchsia); }

  /// ditto
	static Color gainsboro() { return Color(KnownColor.Gainsboro); }

  /// ditto
	static Color ghostWhite() { return Color(KnownColor.GhostWhite); }

  /// ditto
	static Color gold() { return Color(KnownColor.Gold); }

  /// ditto
	static Color goldenrod() { return Color(KnownColor.Goldenrod); }

  /// ditto
	static Color gray() { return Color(KnownColor.Gray); }

  /// ditto
	static Color green() { return Color(KnownColor.Green); }

  /// ditto
	static Color greenYellow() { return Color(KnownColor.GreenYellow); }

  /// ditto
	static Color honeydew() { return Color(KnownColor.Honeydew); }

  /// ditto
	static Color hotPink() { return Color(KnownColor.HotPink); }

  /// ditto
	static Color indianRed() { return Color(KnownColor.IndianRed); }

  /// ditto
	static Color indigo() { return Color(KnownColor.Indigo); }

  /// ditto
	static Color ivory() { return Color(KnownColor.Ivory); }

  /// ditto
	static Color khaki() { return Color(KnownColor.Khaki); }

  /// ditto
	static Color lavender() { return Color(KnownColor.Lavender); }

  /// ditto
	static Color lavenderBlush() { return Color(KnownColor.LavenderBlush); }

  /// ditto
	static Color lawnGreen() { return Color(KnownColor.LawnGreen); }

  /// ditto
	static Color lemonChiffon() { return Color(KnownColor.LemonChiffon); }

  /// ditto
	static Color lightBlue() { return Color(KnownColor.LightBlue); }

  /// ditto
	static Color lightCoral() { return Color(KnownColor.LightCoral); }

  /// ditto
	static Color lightCyan() { return Color(KnownColor.LightCyan); }

  /// ditto
	static Color lightGoldenrodYellow() { return Color(KnownColor.LightGoldenrodYellow); }

  /// ditto
	static Color lightGray() { return Color(KnownColor.LightGray); }

  /// ditto
	static Color lightGreen() { return Color(KnownColor.LightGreen); }

  /// ditto
	static Color lightPink() { return Color(KnownColor.LightPink); }

  /// ditto
	static Color lightSalmon() { return Color(KnownColor.LightSalmon); }

  /// ditto
	static Color lightSeaGreen() { return Color(KnownColor.LightSeaGreen); }

  /// ditto
	static Color lightSkyBlue() { return Color(KnownColor.LightSkyBlue); }

  /// ditto
	static Color lightSlateGray() { return Color(KnownColor.LightSlateGray); }

  /// ditto
	static Color lightSteelBlue() { return Color(KnownColor.LightSteelBlue); }

  /// ditto
	static Color lightYellow() { return Color(KnownColor.LightYellow); }

  /// ditto
	static Color lime() { return Color(KnownColor.Lime); }

  /// ditto
	static Color limeGreen() { return Color(KnownColor.LimeGreen); }

  /// ditto
	static Color linen() { return Color(KnownColor.Linen); }

  /// ditto
	static Color magenta() { return Color(KnownColor.Magenta); }

  /// ditto
	static Color maroon() { return Color(KnownColor.Maroon); }

  /// ditto
	static Color mediumAquamarine() { return Color(KnownColor.MediumAquamarine); }

  /// ditto
	static Color mediumBlue() { return Color(KnownColor.MediumBlue); }

  /// ditto
	static Color mediumOrchid() { return Color(KnownColor.MediumOrchid); }

  /// ditto
	static Color mediumPurple() { return Color(KnownColor.MediumPurple); }

  /// ditto
	static Color mediumSeaGreen() { return Color(KnownColor.MediumSeaGreen); }

  /// ditto
	static Color mediumSlateBlue() { return Color(KnownColor.MediumSlateBlue); }

  /// ditto
	static Color mediumSpringGreen() { return Color(KnownColor.MediumSpringGreen); }

  /// ditto
	static Color mediumTurquoise() { return Color(KnownColor.MediumTurquoise); }

  /// ditto
	static Color mediumVioletRed() { return Color(KnownColor.MediumVioletRed); }

  /// ditto
	static Color midnightBlue() { return Color(KnownColor.MidnightBlue); }

  /// ditto
	static Color mintCream() { return Color(KnownColor.MintCream); }

  /// ditto
	static Color mistyRose() { return Color(KnownColor.MistyRose); }

  /// ditto
	static Color moccasin() { return Color(KnownColor.Moccasin); }

  /// ditto
	static Color navajoWhite() { return Color(KnownColor.NavajoWhite); }

  /// ditto
	static Color navy() { return Color(KnownColor.Navy); }

  /// ditto
	static Color oldLace() { return Color(KnownColor.OldLace); }

  /// ditto
	static Color olive() { return Color(KnownColor.Olive); }

  /// ditto
	static Color oliveDrab() { return Color(KnownColor.OliveDrab); }

  /// ditto
	static Color orange() { return Color(KnownColor.Orange); }

  /// ditto
	static Color orangeRed() { return Color(KnownColor.OrangeRed); }

  /// ditto
	static Color orchid() { return Color(KnownColor.Orchid); }

  /// ditto
	static Color paleGoldenrod() { return Color(KnownColor.PaleGoldenrod); }

  /// ditto
	static Color paleGreen() { return Color(KnownColor.PaleGreen); }

  /// ditto
	static Color paleTurquoise() { return Color(KnownColor.PaleTurquoise); }

  /// ditto
	static Color paleVioletRed() { return Color(KnownColor.PaleVioletRed); }

  /// ditto
	static Color papayaWhip() { return Color(KnownColor.PapayaWhip); }

  /// ditto
	static Color peachPuff() { return Color(KnownColor.PeachPuff); }

  /// ditto
	static Color peru() { return Color(KnownColor.Peru); }

  /// ditto
	static Color pink() { return Color(KnownColor.Pink); }

  /// ditto
	static Color plum() { return Color(KnownColor.Plum); }

  /// ditto
	static Color powderBlue() { return Color(KnownColor.PowderBlue); }

  /// ditto
	static Color purple() { return Color(KnownColor.Purple); }

  /// ditto
	static Color red() { return Color(KnownColor.Red); }

  /// ditto
	static Color rosyBrown() { return Color(KnownColor.RosyBrown); }

  /// ditto
	static Color royalBlue() { return Color(KnownColor.RoyalBlue); }

  /// ditto
	static Color saddleBrown() { return Color(KnownColor.SaddleBrown); }

  /// ditto
	static Color salmon() { return Color(KnownColor.Salmon); }

  /// ditto
	static Color sandyBrown() { return Color(KnownColor.SandyBrown); }

  /// ditto
	static Color seaGreen() { return Color(KnownColor.SeaGreen); }

  /// ditto
	static Color seaShell() { return Color(KnownColor.SeaShell); }

  /// ditto
	static Color sienna() { return Color(KnownColor.Sienna); }

  /// ditto
	static Color silver() { return Color(KnownColor.Silver); }

  /// ditto
	static Color skyBlue() { return Color(KnownColor.SkyBlue); }

  /// ditto
	static Color slateBlue() { return Color(KnownColor.SlateBlue); }

  /// ditto
	static Color slateGray() { return Color(KnownColor.SlateGray); }

  /// ditto
	static Color snow() { return Color(KnownColor.Snow); }

  /// ditto
	static Color springGreen() { return Color(KnownColor.SpringGreen); }

  /// ditto
	static Color steelBlue() { return Color(KnownColor.SteelBlue); }

  /// ditto
	static Color tan() { return Color(KnownColor.Tan); }

  /// ditto
	static Color teal() { return Color(KnownColor.Teal); }

  /// ditto
	static Color thistle() { return Color(KnownColor.Thistle); }

  /// ditto
	static Color tomato() { return Color(KnownColor.Tomato); }

  /// ditto
	static Color turquoise() { return Color(KnownColor.Turquoise); }

  /// ditto
	static Color violet() { return Color(KnownColor.Violet); }

  /// ditto
	static Color wheat() { return Color(KnownColor.Wheat); }

  /// ditto
	static Color white() { return Color(KnownColor.White); }

  /// ditto
	static Color whiteSmoke() { return Color(KnownColor.WhiteSmoke); }

  /// ditto
	static Color yellow() { return Color(KnownColor.Yellow); }

  /// ditto
	static Color yellowGreen() { return Color(KnownColor.YellowGreen); }

  /// ditto
	static Color buttonFace() { return Color(KnownColor.ButtonFace); }

  /// ditto
	static Color buttonHighlight() { return Color(KnownColor.ButtonHighlight); }

  /// ditto
	static Color buttonShadow() { return Color(KnownColor.ButtonShadow); }

  /// ditto
	static Color gradientActiveCaption() { return Color(KnownColor.GradientActiveCaption); }

  /// ditto
	static Color gradientInactiveCaption() { return Color(KnownColor.GradientInactiveCaption); }

  /// ditto
	static Color menuBar() { return Color(KnownColor.MenuBar); }

  /// ditto
	static Color menuHighlight() { return Color(KnownColor.MenuHighlight); }

  private static Color opCall(KnownColor knownColor) {
    Color c;
    c.value_ = UNDEFINED_COLOR_VALUE;
    c.state_ = STATE_KNOWNCOLOR_VALID;
    c.knownColor_ = cast(ushort)knownColor;
    return c;
  }

  private static Color opCall(ulong value, ushort state, string name, KnownColor knownColor) {
    Color c;
    c.value_ = value;
    c.state_ = state;
    c.name_ = name;
    c.knownColor_ = cast(ushort)knownColor;
    return c;
  }

  private static ulong makeArgb(ubyte a, ubyte r, ubyte g, ubyte b) {
    return cast(ulong)((r << ARGB_RED_SHIFT) | (g << ARGB_GREEN_SHIFT) | (b << ARGB_BLUE_SHIFT) | (a << ARGB_ALPHA_SHIFT)) & 0xFFFFFFFF;
  }

  private static uint argbFromKnownColor(KnownColor color) {
    if (colorTable_ == null)
      initColorTable();
    return colorTable_[color];
  }

  private static uint argbFromSystemColor(int index) {

    uint encode(ubyte alpha, ubyte red, ubyte green, ubyte blue) {
      return (red << ARGB_RED_SHIFT) | (green << ARGB_GREEN_SHIFT) | (blue << ARGB_BLUE_SHIFT) | (alpha << ARGB_ALPHA_SHIFT);
    }

    uint fromRgbValue(uint value) {
      return encode(255, cast(ubyte)((value >> WIN32_RED_SHIFT) & 255), cast(ubyte)((value >> WIN32_GREEN_SHIFT) & 255), cast(ubyte)((value >> WIN32_BLUE_SHIFT) & 255));
    }

    return fromRgbValue(GetSysColor(index));
  }

  private static void initColorTable() {
    colorTable_ = [ 
      0x00000000, argbFromSystemColor(COLOR_ACTIVEBORDER), argbFromSystemColor(COLOR_ACTIVECAPTION), argbFromSystemColor(COLOR_CAPTIONTEXT), argbFromSystemColor(COLOR_APPWORKSPACE), argbFromSystemColor(COLOR_BTNFACE), argbFromSystemColor(COLOR_BTNSHADOW), argbFromSystemColor(COLOR_3DDKSHADOW), argbFromSystemColor(COLOR_BTNHIGHLIGHT), argbFromSystemColor(COLOR_3DLIGHT), argbFromSystemColor(COLOR_BTNTEXT), 
      argbFromSystemColor(COLOR_DESKTOP), argbFromSystemColor(COLOR_GRAYTEXT), argbFromSystemColor(COLOR_HIGHLIGHT), argbFromSystemColor(COLOR_HIGHLIGHTTEXT), argbFromSystemColor(COLOR_HOTLIGHT), argbFromSystemColor(COLOR_INACTIVEBORDER), argbFromSystemColor(COLOR_INACTIVECAPTION), argbFromSystemColor(COLOR_INACTIVECAPTIONTEXT), argbFromSystemColor(COLOR_INFOBK), argbFromSystemColor(COLOR_INFOTEXT), 
      argbFromSystemColor(COLOR_MENU), argbFromSystemColor(COLOR_MENUTEXT), argbFromSystemColor(COLOR_SCROLLBAR), argbFromSystemColor(COLOR_WINDOW), argbFromSystemColor(COLOR_WINDOWFRAME), argbFromSystemColor(COLOR_WINDOWTEXT), 0x00FFFFFF, 0xFFF0F8FF, 0xFFFAEBD7, 
      0xFF00FFFF, 0xFF7FFFD4, 0xFFF0FFFF, 0xFFF5F5DC, 0xFFFFE4C4, 0xFF000000, 0xFFFFEBCD, 0xFF0000FF, 0xFF8A2BE2, 0xFFA52A2A, 
      0xFFDEB887, 0xFF5F9EA0, 0xFF7FFF00, 0xFFD2691E, 0xFFFF7F50, 0xFF6495ED, 0xFFFFF8DC, 0xFFDC143C, 0xFF00FFFF, 0xFF00008B, 
      0xFF008B8B, 0xFFB8860B, 0xFFA9A9A9, 0xFF006400, 0xFFBDB76B, 0xFF8B008B, 0xFF556B2F, 0xFFFF8C00, 0xFF9932CC, 0xFF8B0000, 
      0xFFE9967A, 0xFF8FBC8B, 0xFF483D8B, 0xFF2F4F4F, 0xFF00CED1, 0xFF9400D3, 0xFFFF1493, 0xFF00BFFF, 0xFF696969, 0xFF1E90FF, 
      0xFFB22222, 0xFFFFFAF0, 0xFF228B22, 0xFFFF00FF, 0xFFDCDCDC, 0xFFF8F8FF, 0xFFFFD700, 0xFFDAA520, 0xFF808080, 0xFF008000, 
      0xFFADFF2F, 0xFFF0FFF0, 0xFFFF69B4, 0xFFCD5C5C, 0xFF4B0082, 0xFFFFFFF0, 0xFFF0E68C, 0xFFE6E6FA, 0xFFFFF0F5, 0xFF7CFC00, 
      0xFFFFFACD, 0xFFADD8E6, 0xFFF08080, 0xFFE0FFFF, 0xFFFAFAD2, 0xFFD3D3D3, 0xFF90EE90, 0xFFFFB6C1, 0xFFFFA07A, 0xFF20B2AA, 
      0xFF87CEFA, 0xFF778899, 0xFFB0C4DE, 0xFFFFFFE0, 0xFF00FF00, 0xFF32CD32, 0xFFFAF0E6, 0xFFFF00FF, 0xFF800000, 0xFF66CDAA, 
      0xFF0000CD, 0xFFBA55D3, 0xFF9370DB, 0xFF3CB371, 0xFF7B68EE, 0xFF00FA9A, 0xFF48D1CC, 0xFFC71585, 0xFF191970, 0xFFF5FFFA, 
      0xFFFFE4E1, 0xFFFFE4B5, 0xFFFFDEAD, 0xFF000080, 0xFFFDF5E6, 0xFF808000, 0xFF6B8E23, 0xFFFFA500, 0xFFFF4500, 0xFFDA70D6, 
      0xFFEEE8AA, 0xFF98FB98, 0xFFAFEEEE, 0xFFDB7093, 0xFFFFEFD5, 0xFFFFDAB9, 0xFFCD853F, 0xFFFFC0CB, 0xFFDDA0DD, 0xFFB0E0E6, 
      0xFF800080, 0xFFFF0000, 0xFFBC8F8F, 0xFF4169E1, 0xFF8B4513, 0xFFFA8072, 0xFFF4A460, 0xFF2E8B57, 0xFFFFF5EE, 0xFFA0522D, 
      0xFFC0C0C0, 0xFF87CEEB, 0xFF6A5ACD, 0xFF708090, 0xFFFFFAFA, 0xFF00FF7F, 0xFF4682B4, 0xFFD2B48C, 0xFF008080, 0xFFD8BFD8, 
      0xFFFF6347, 0xFF40E0D0, 0xFFEE82EE, 0xFFF5DEB3, 0xFFFFFFFF, 0xFFF5F5F5, 0xFFFFFF00, 0xFF9ACD32, argbFromSystemColor(COLOR_3DFACE), argbFromSystemColor(COLOR_3DHIGHLIGHT), 
      argbFromSystemColor(COLOR_3DSHADOW), argbFromSystemColor(COLOR_GRADIENTACTIVECAPTION), argbFromSystemColor(COLOR_GRADIENTINACTIVECAPTION), argbFromSystemColor(COLOR_MENUBAR), argbFromSystemColor(COLOR_MENUHILIGHT) 
    ];
  }

  private static void initNameTable() {
    nameTable_ = [ 
      "", "ActiveBorder", "ActiveCaption", "ActiveCaptionText", "AppWorkspace", "Control", "ControlDark", "ControlDarkDark", 
      "ControlLight", "ControlLightLight", "ControlText", "Desktop", "GrayText", "Highlight", "HighlightText", "HotTrack", 
      "InactiveBorder", "InactiveCaption", "InactiveCaptionText", "Info", "InfoText", "Menu", "MenuText", "ScrollBar", "Window", 
      "WindowFrame", "WindowText", "Transparent", "AliceBlue", "AntiqueWhite", "Aqua", "Aquamarine", "Azure", "Beige", "Bisque", 
      "Black", "BlanchedAlmond", "Blue", "BlueViolet", "Brown", "BurlyWood", "CadetBlue", "Chartreuse", "Chocolate", "Coral", 
      "CornflowerBlue", "Cornsilk", "Crimson", "Cyan", "DarkBlue", "DarkCyan", "DarkGoldenrod", "DarkGray", "DarkGreen", "DarkKhaki", 
      "DarkMagenta", "DarkOliveGreen", "DarkOrange", "DarkOrchid", "DarkRed", "DarkSalmon", "DarkSeaGreen", "DarkSlateBlue", 
      "DarkSlateGray", "DarkTurquoise", "DarkViolet", "DeepPink", "DeepSkyBlue", "DimGray", "DodgerBlue", "Firebrick", "FloralWhite", 
      "ForestGreen", "Fuchsia", "Gainsboro", "GhostWhite", "Gold", "Goldenrod", "Gray", "Green", "GreenYellow", "Honeydew", "HotPink", 
      "IndianRed", "Indigo", "Ivory", "Khaki", "Lavender", "LavenderBlush", "LawnGreen", "LemonChiffon", "LightBlue", "LightCoral", 
      "LightCyan", "LightGoldenrodYellow", "LightGray", "LightGreen", "LightPink", "LightSalmon", "LightSeaGreen", "LightSkyBlue", 
      "LightSlateGray", "LightSteelBlue", "LightYellow", "Lime", "LimeGreen", "Linen", "Magenta", "Maroon", "MediumAquamarine", 
      "MediumBlue", "MediumOrchid", "MediumPurple", "MediumSeaGreen", "MediumSlateBlue", "MediumSpringGreen", "MediumTurquoise", 
      "MediumVioletRed", "MidnightBlue", "MintCream", "MistyRose", "Moccasin", "NavajoWhite", "Navy", "OldLace", "Olive", "OliveDrab", 
      "Orange", "OrangeRed", "Orchid","PaleGoldenrod", "PaleGreen", "PaleTurquoise", "PaleVioletRed", "PapayaWhip", "PeachPuff", "Peru", 
      "Pink", "Plum", "PowderBlue", "Purple", "Red", "RosyBrown", "RoyalBlue", "SaddleBrown", "Salmon", "SandyBrown", "SeaGreen", 
      "SeaShell", "Sienna", "Silver", "SkyBlue", "SlateBlue", "SlateGray", "Snow", "SpringGreen", "SteelBlue", "Tan", "Teal", "Thistle", 
      "Tomato", "Turquoise", "Violet", "Wheat", "White", "WhiteSmoke", "Yellow", "YellowGreen", "ButtonFace", "ButtonHighlight", 
      "ButtonShadow", "GradientActiveCaption", "GradientInactiveCaption", "MenuBar", "MenuHighlight"
    ];
  }

  private ulong value() {
    if ((state_ & STATE_VALUE_VALID) != 0)
      return value_;
    if ((state_ & STATE_KNOWNCOLOR_VALID) != 0)
      return cast(ulong)argbFromKnownColor(cast(KnownColor)knownColor_);
    return UNDEFINED_COLOR_VALUE;
  }

}

/**
 */
final class Matrix {

  private Handle nativeMatrix_;

  /**
   */
  this() {
    Status status = GdipCreateMatrix(nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(float m11, float m12, float m21, float m22, float dx, float dy) {
    Status status = GdipCreateMatrix2(m11, m12, m21, m22, dx, dy, nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(Rect rect, Point[] plgpts) {
    if (plgpts.length != 3)
      throw statusException(Status.InvalidParameter);

    Status status = GdipCreateMatrix3I(rect, plgpts.ptr, nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(RectF rect, PointF[] plgpts) {
    if (plgpts.length != 3)
      throw statusException(Status.InvalidParameter);

    Status status = GdipCreateMatrix3(rect, plgpts.ptr, nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
  }

  ~this() {
    dispose();
  }

  /**
   */
  void dispose() {
    if (nativeMatrix_ != Handle.init) {
      GdipDeleteMatrixSafe(nativeMatrix_);
      nativeMatrix_ = Handle.init;
    }
  }

  /**
   */
  Matrix clone() {
    Handle cloneMatrix;
    Status status = GdipCloneMatrix(nativeMatrix_, cloneMatrix);
    if (status != Status.OK)
      throw statusException(status);
    return new Matrix(cloneMatrix);
  }

  /**
   */
  void invert() {
    Status status = GdipInvertMatrix(nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void reset() {
    Status status = GdipSetMatrixElements(nativeMatrix_, 1, 0, 0, 1, 0, 0);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void multiply(Matrix matrix, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipMultiplyMatrix(nativeMatrix_, matrix.nativeMatrix_, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void scale(float scaleX, float scaleY, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipScaleMatrix(nativeMatrix_, scaleX, scaleY, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void shear(float shearX, float shearY, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipShearMatrix(nativeMatrix_, shearX, shearY, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void rotate(float angle, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipRotateMatrix(nativeMatrix_, angle, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void translate(float offsetX, float offsetY, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipTranslateMatrix(nativeMatrix_, offsetX, offsetY, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  float[] elements() {
    float[] m = new float[6];
    Status status = GdipGetMatrixElements(nativeMatrix_, m.ptr);
    if (status != Status.OK)
      throw statusException(status);
    return m;
  }

  /**
   */
  float offsetX() {
    return elements[4];
  }

  /**
   */
  float offsetY() {
    return elements[5];
  }

  /**
   */
  bool isIdentity() {
    int result;
    Status status = GdipIsMatrixIdentity(nativeMatrix_, result);
    if (status != Status.OK)
      throw statusException(status);
    return result == 1;
  }

  /**
   */
  bool isInvertible() {
    int result;
    Status status = GdipIsMatrixInvertible(nativeMatrix_, result);
    if (status != Status.OK)
      throw statusException(status);
    return result == 1;
  }

  private this(Handle nativeMatrix) {
    nativeMatrix_ = nativeMatrix;
  }

  package Handle nativeMatrix() {
    return nativeMatrix_;
  }

}

/**
 * Encapsulates a GDI+ drawing surface.
 */
final class Graphics {

  private Handle nativeGraphics_;
  private Handle hdc_;
  private static Handle halftonePalette_;

  /**
   * $(I bool delegate(void* callbackData));$(BR)$(BR)Provides a callback method for deciding when the DrawImage method should cancel execution.
   */
  alias bool delegate(void* callbackData) DrawImageAbort;

  static ~this() {
    if (halftonePalette_ != Handle.init) {
      DeleteObject(halftonePalette_);
      halftonePalette_ = Handle.init;
    }
  }

  ~this() {
    dispose();
  }

  /**
   * Releases all resources.
   */
  void dispose() {
    if (nativeGraphics_ != Handle.init) {
      if (hdc_ != Handle.init)
        releaseHdc();

      GdipDeleteGraphicsSafe(nativeGraphics_);
      nativeGraphics_ = Handle.init;
    }
  }

  /**
   * Gets a handle to the current halftone palette.
   */
  static Handle getHalftonePalette() {
    synchronized {
      if (halftonePalette_ == Handle.init)
        halftonePalette_ = GdipCreateHalftonePalette();
      return halftonePalette_;
    }
  }

  /**
   * Creates a new instance from the specified Image.
   * Params: image = The Image from which to create the new instance.
   * Returns: A new instance for the specified Image.
   */
  static Graphics fromImage(Image image) {
    if (image is null)
      throw new ArgumentNullException("image");

    if ((image.pixelFormat & PixelFormat.Indexed) != 0)
      throw new Exception("A Graphics object cannot be created from an image that has an indexed pixel format.");

    Handle nativeGraphics;

    Status status = GdipGetImageGraphicsContext(image.nativeImage_, nativeGraphics);
    if (status != Status.OK)
      throw statusException(status);

    return new Graphics(nativeGraphics);
  }

  /**
   * Creates a new instance from the specified window handle.
   * Params: hwnd = Handle to a window.
   * Returns: A new instance for the specified window.
   */
  static Graphics fromHwnd(Handle hwnd) {
    Handle nativeGraphics;

    Status status = GdipCreateFromHWND(hwnd, nativeGraphics);
    if (status != Status.OK)
      throw statusException(status);

    return new Graphics(nativeGraphics);
  }

  /**
   * Creates a new instance from the specified device context.
   * Params: hwnd = Handle to a device context.
   * Returns: A new instance for the specified device context.
   */
  static Graphics fromHdc(Handle hdc) {
    Handle nativeGraphics;

    Status status = GdipCreateFromHDC(hdc, nativeGraphics);
    if (status != Status.OK)
      throw statusException(status);

    return new Graphics(nativeGraphics);
  }

  /**
   * Gets a handle to the device context associated with this instance.
   * Returns: Handle to the device context associated with this instance.
   */
  Handle getHdc() {
    Handle hdc;
    Status status = GdipGetDC(nativeGraphics_, hdc);
    if (status != Status.OK)
      throw statusException(status);
    return hdc_ = hdc;
  }

  /**
   * Releases a device context handle obtained by a previous call to the getHdc method of this instance.
   * Params: hdc = Handle to a device context obtained by a previous call to getHdc.
   */
  void releaseHdc(Handle hdc) {
    Status status = GdipReleaseDC(nativeGraphics_, hdc_);
    if (status != Status.OK)
      throw statusException(status);
    hdc_ = Handle.init;
  }

  /// ditto
  void releaseHdc() {
    releaseHdc(hdc_);
  }

  /**
   * Saves the current state and associates the saved state with a GraphicsState.
   */
  GraphicsState save() {
    int state;
    Status status = GdipSaveGraphics(nativeGraphics_, state);
    if (status != Status.OK)
      throw statusException(status);
    return new GraphicsState(state);
  }

  /**
   * Restores the _state to the _state represented by a GraphicsState.
   */
  void restore(GraphicsState state) {
    Status status = GdipRestoreGraphics(nativeGraphics_, state.nativeState_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void setClip(Graphics g, CombineMode combineMode = CombineMode.Replace) {
    if (g is null)
      throw new ArgumentNullException("g");

    Status status = GdipSetClipGraphics(nativeGraphics_, g.nativeGraphics_, combineMode);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Sets the clipping region.
   */
  void setClip(Rect rect, CombineMode combineMode = CombineMode.Replace) {
    Status status = GdipSetClipRectI(nativeGraphics_, rect.x, rect.y, rect.width, rect.height, combineMode);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void setClip(RectF rect, CombineMode combineMode = CombineMode.Replace) {
    Status status = GdipSetClipRect(nativeGraphics_, rect.x, rect.y, rect.width, rect.height, combineMode);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void setClip(Path path, CombineMode combineMode = CombineMode.Replace) {
    if (path is null)
      throw new ArgumentNullException("path");

    Status status = GdipSetClipPath(nativeGraphics_, path.nativePath_, combineMode);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void setClip(Region region, CombineMode combineMode) {
    if (region is null)
      throw new ArgumentNullException("region");

    Status status = GdipSetClipRegion(nativeGraphics_, region.nativeRegion_, combineMode);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void intersectClip(RectF rect) {
    Status status = GdipSetClipRect(nativeGraphics_, rect.x, rect.y, rect.width, rect.height, CombineMode.Intersect);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void intersectClip(Rect rect) {
    Status status = GdipSetClipRectI(nativeGraphics_, rect.x, rect.y, rect.width, rect.height, CombineMode.Intersect);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void intersectClip(Region region) {
    if (region is null)
      throw new ArgumentNullException("region");

    Status status = GdipSetClipRegion(nativeGraphics_, region.nativeRegion_, CombineMode.Intersect);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void excludeClip(RectF rect) {
    Status status = GdipSetClipRect(nativeGraphics_, rect.x, rect.y, rect.width, rect.height, CombineMode.Exclude);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void excludeClip(Rect rect) {
    Status status = GdipSetClipRectI(nativeGraphics_, rect.x, rect.y, rect.width, rect.height, CombineMode.Exclude);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void excludeClip(Region region) {
    if (region is null)
      throw new ArgumentNullException("region");

    Status status = GdipSetClipRegion(nativeGraphics_, region.nativeRegion_, CombineMode.Exclude);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void resetClip() {
    Status status = GdipResetClip(nativeGraphics_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  bool isVisible(int x, int y) {
    return isVisible(Point(x, y));
  }

  /**
   */
  bool isVisible(Point point) {
    int result = 0;
    Status status = GdipIsVisiblePointI(nativeGraphics_, point.x, point.y, result);
    if (status != Status.OK)
      throw statusException(status);
    return result == 1;
  }

  /**
   */
  bool isVisible(int x, int y, int width, int height) {
    return isVisible(Rect(x, y, width, height));
  }

  /**
   */
  bool isVisible(Rect rect) {
    int result = 0;
    Status status = GdipIsVisibleRectI(nativeGraphics_, rect.x, rect.y, rect.width, rect.height, result);
    if (status != Status.OK)
      throw statusException(status);
    return result == 1;
  }

  /**
   */
  bool isVisible(float x, float y) {
    return isVisible(PointF(x, y));
  }

  /**
   */
  bool isVisible(PointF point) {
    int result = 0;
    Status status = GdipIsVisiblePoint(nativeGraphics_, point.x, point.y, result);
    if (status != Status.OK)
      throw statusException(status);
    return result == 1;
  }

  /**
   */
  bool isVisible(float x, float y, float width, float height) {
    return isVisible(RectF(x, y, width, height));
  }

  /**
   */
  bool isVisible(RectF rect) {
    int result = 0;
    Status status = GdipIsVisibleRect(nativeGraphics_, rect.x, rect.y, rect.width, rect.height, result);
    if (status != Status.OK)
      throw statusException(status);
    return result == 1;
  }

  /**
   */
  void addMetafileComment(ubyte[] data) {
    Status status = GdipComment(nativeGraphics_, data.length, data.ptr);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void flush(FlushIntention intention = FlushIntention.Flush) {
    Status status = GdipFlush(nativeGraphics_, intention);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void scaleTransform(float sx, float sy, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipScaleWorldTransform(nativeGraphics_, sx, sy, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void rotateTransform(float angle, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipRotateWorldTransform(nativeGraphics_, angle, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void translateTransform(float dx, float dy, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipTranslateWorldTransform(nativeGraphics_, dx, dy, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void multiplyTransform(Matrix matrix, MatrixOrder order = MatrixOrder.Prepend) {
    if (matrix is null)
      throw new ArgumentNullException("matrix");

    Status status = GdipMultiplyWorldTransform(nativeGraphics_, matrix.nativeMatrix_, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void resetTransform() {
    Status status = GdipResetWorldTransform(nativeGraphics_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void transformPoints(CoordinateSpace destSpace, CoordinateSpace srcSpace, PointF[] points) {
    Status status = GdipTransformPoints(nativeGraphics_, destSpace, srcSpace, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void transformPoints(CoordinateSpace destSpace, CoordinateSpace srcSpace, Point[] points) {
    Status status = GdipTransformPointsI(nativeGraphics_, destSpace, srcSpace, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  Color getNearestColor(Color color) {
    uint argb = color.toArgb();
    Status status = GdipGetNearestColor(nativeGraphics_, argb);
    if (status != Status.OK)
      throw statusException(status);
    return Color.fromArgb(argb);
  }

  /**
   */
  void drawLine(Pen pen, float x1, float y1, float x2, float y2) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawLine(nativeGraphics_, pen.nativePen_, x1, y1, x2, y2);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawLine(Pen pen, PointF pt1, PointF pt2) {
    drawLine(pen, pt1.x, pt1.y, pt2.x, pt2.y);
  }

  /**
   */
  void drawLines(Pen pen, PointF[] points) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawLines(nativeGraphics_, pen.nativePen_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawLine(Pen pen, int x1, int y1, int x2, int y2) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawLineI(nativeGraphics_, pen.nativePen_, x1, y1, x2, y2);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawLine(Pen pen, Point pt1, Point pt2) {
    drawLine(pen, pt1.x, pt1.y, pt2.x, pt2.y);
  }

  /**
   */
  void drawLines(Pen pen, Point[] points) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawLinesI(nativeGraphics_, pen.nativePen_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawArc(Pen pen, float x, float y, float width, float height, float startAngle, float sweepAngle) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawArc(nativeGraphics_, pen.nativePen_, x, y, width, height, startAngle, sweepAngle);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawArc(Pen pen, RectF rect, float startAngle, float sweepAngle) {
    drawArc(pen, rect.x, rect.y, rect.width, rect.height, startAngle, sweepAngle);
  }

  /**
   */
  void drawArc(Pen pen, int x, int y, int width, int height, float startAngle, float sweepAngle) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawArcI(nativeGraphics_, pen.nativePen_, x, y, width, height, startAngle, sweepAngle);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawArc(Pen pen, Rect rect, float startAngle, float sweepAngle) {
    drawArc(pen, rect.x, rect.y, rect.width, rect.height, startAngle, sweepAngle);
  }

  /**
   */
  void drawBezier(Pen pen, float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawBezier(nativeGraphics_, pen.nativePen_, x1, y1, x2, y2, x3, y3, x4, y4);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawBezier(Pen pen, PointF pt1, PointF pt2, PointF pt3, PointF pt4) {
    drawBezier(pen, pt1.x, pt1.y, pt2.x, pt2.y, pt3.x, pt3.y, pt4.x, pt4.y);
  }

  /**
   */
  void drawBeziers(Pen pen, PointF[] points) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawBeziers(nativeGraphics_, pen.nativePen_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawBezier(Pen pen, int x1, int y1, int x2, int y2, int x3, int y3, int x4, int y4) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawBezierI(nativeGraphics_, pen.nativePen_, x1, y1, x2, y2, x3, y3, x4, y4);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawBezier(Pen pen, Point pt1, Point pt2, Point pt3, Point pt4) {
    drawBezier(pen, pt1.x, pt1.y, pt2.x, pt2.y, pt3.x, pt3.y, pt4.x, pt4.y);
  }

  /**
   */
  void drawBeziers(Pen pen, Point[] points) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawBeziersI(nativeGraphics_, pen.nativePen_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawRectangle(Pen pen, float x, float y, float width, float height) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawRectangle(nativeGraphics_, pen.nativePen_, x, y, width, height);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawRectangle(Pen pen, RectF rect) {
    drawRectangle(pen, rect.x, rect.y, rect.width, rect.height);
  }

  /**
   */
  void drawRectangles(Pen pen, RectF[] rects) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawRectangles(nativeGraphics_, pen.nativePen_, rects.ptr, rects.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawRectangle(Pen pen, int x, int y, int width, int height) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawRectangleI(nativeGraphics_, pen.nativePen_, x, y, width, height);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawRectangle(Pen pen, Rect rect) {
    drawRectangle(pen, rect.x, rect.y, rect.width, rect.height);
  }

  /**
   */
  void drawRectangles(Pen pen, Rect[] rects) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawRectanglesI(nativeGraphics_, pen.nativePen_, rects.ptr, rects.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawEllipse(Pen pen, float x, float y, float width, float height) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawEllipse(nativeGraphics_, pen.nativePen_, x, y, width, height);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawEllipse(Pen pen, RectF rect) {
    drawEllipse(pen, rect.x, rect.y, rect.width, rect.height);
  }

  /**
   */
  void drawEllipse(Pen pen, int x, int y, int width, int height) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawEllipseI(nativeGraphics_, pen.nativePen_, x, y, width, height);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawEllipse(Pen pen, Rect rect) {
    drawEllipse(pen, rect.x, rect.y, rect.width, rect.height);
  }

  /**
   */
  void drawPie(Pen pen, float x, float y, float width, float height, float startAngle, float sweepAngle) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawPie(nativeGraphics_, pen.nativePen_, x, y, width, height, startAngle, sweepAngle);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawPie(Pen pen, RectF rect, float startAngle, float sweepAngle) {
    drawPie(pen, rect.x, rect.y, rect.width, rect.height, startAngle, sweepAngle);
  }

  /**
   */
  void drawPie(Pen pen, int x, int y, int width, int height, float startAngle, float sweepAngle) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawPieI(nativeGraphics_, pen.nativePen_, x, y, width, height, startAngle, sweepAngle);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawPie(Pen pen, Rect rect, float startAngle, float sweepAngle) {
    drawPie(pen, rect.x, rect.y, rect.width, rect.height, startAngle, sweepAngle);
  }

  /**
   */
  void drawPolygon(Pen pen, PointF[] points) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawPolygon(nativeGraphics_, pen.nativePen_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawPolygon(Pen pen, Point[] points) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawPolygonI(nativeGraphics_, pen.nativePen_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawCurve(Pen pen, PointF[] points) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawCurve(nativeGraphics_, pen.nativePen_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawCurve(Pen pen, PointF[] points, float tension) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawCurve2(nativeGraphics_, pen.nativePen_, points.ptr, points.length, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawCurve(Pen pen, PointF[] points, int offset, int numberOfSegments, float tension = 0.5f) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawCurve3(nativeGraphics_, pen.nativePen_, points.ptr, points.length, offset, numberOfSegments, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawCurve(Pen pen, Point[] points) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawCurveI(nativeGraphics_, pen.nativePen_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawCurve(Pen pen, Point[] points, float tension) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawCurve2I(nativeGraphics_, pen.nativePen_, points.ptr, points.length, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawCurve(Pen pen, Point[] points, int offset, int numberOfSegments, float tension = 0.5f) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawCurve3I(nativeGraphics_, pen.nativePen_, points.ptr, points.length, offset, numberOfSegments, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawClosedCurve(Pen pen, PointF[] points) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawClosedCurve(nativeGraphics_, pen.nativePen_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawClosedCurve(Pen pen, PointF[] points, float tension) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawClosedCurve2(nativeGraphics_, pen.nativePen_, points.ptr, points.length, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawClosedCurve(Pen pen, Point[] points) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawClosedCurveI(nativeGraphics_, pen.nativePen_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawClosedCurve(Pen pen, Point[] points, float tension) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawClosedCurve2I(nativeGraphics_, pen.nativePen_, points.ptr, points.length, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawPath(Pen pen, Path path) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    if (path is null)
      throw new ArgumentNullException("path");

    Status status = GdipDrawPath(nativeGraphics_, pen.nativePen_, path.nativePath_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void clear(Color color) {
    Status status = GdipGraphicsClear(nativeGraphics_, color.toArgb());
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void fillRectangle(Brush brush, int x, int y, int width, int height) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillRectangleI(nativeGraphics_, brush.nativeBrush_, x, y, width, height);
  }

  void fillRectangle(Brush brush, Rect rect) {
    fillRectangle(brush, rect.x, rect.y, rect.width, rect.height);
  }

  /**
   */
  void fillRectangles(Brush brush, Rect[] rects) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillRectanglesI(nativeGraphics_, brush.nativeBrush_, rects.ptr, rects.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void fillRectangle(Brush brush, float x, float y, float width, float height) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillRectangle(nativeGraphics_, brush.nativeBrush_, x, y, width, height);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void fillRectangle(Brush brush, RectF rect) {
    fillRectangle(brush, rect.x, rect.y, rect.width, rect.height);
  }

  /**
   */
  void fillRectangles(Brush brush, RectF[] rects) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillRectangles(nativeGraphics_, brush.nativeBrush_, rects.ptr, rects.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void fillPolygon(Brush brush, PointF[] points, FillMode fillMode = FillMode.Alternate) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillPolygon(nativeGraphics_, brush.nativeBrush_, points.ptr, points.length, fillMode);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void fillPolygon(Brush brush, Point[] points, FillMode fillMode = FillMode.Alternate) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillPolygonI(nativeGraphics_, brush.nativeBrush_, points.ptr, points.length, fillMode);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void fillEllipse(Brush brush, float x, float y, float width, float height) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillEllipse(nativeGraphics_, brush.nativeBrush_, x, y, width, height);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void fillEllipse(Brush brush, RectF rect) {
    fillEllipse(brush, rect.x, rect.y, rect.width, rect.height);
  }

  /**
   */
  void fillEllipse(Brush brush, int x, int y, int width, int height) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillEllipseI(nativeGraphics_, brush.nativeBrush_, x, y, width, height);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void fillEllipse(Brush brush, Rect rect) {
    fillEllipse(brush, rect.x, rect.y, rect.width, rect.height);
  }

  /**
   */
  void fillPie(Brush brush, float x, float y, float width, float height, float startAngle, float sweepAngle) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillPie(nativeGraphics_, brush.nativeBrush_, x, y, width, height, startAngle, sweepAngle);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void fillPie(Brush brush, RectF rect, float startAngle, float sweepAngle) {
    fillPie(brush, rect.x, rect.y, rect.width, rect.height, startAngle, sweepAngle);
  }

  /**
   */
  void fillPie(Brush brush, int x, int y, int width, int height, float startAngle, float sweepAngle) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillPieI(nativeGraphics_, brush.nativeBrush_, x, y, width, height, startAngle, sweepAngle);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void fillPath(Brush brush, Path path) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    if (path is null)
      throw new ArgumentNullException("path");

    Status status = GdipFillPath(nativeGraphics_, brush.nativeBrush_, path.nativePath_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void fillClosedCurve(Brush brush, PointF[] points) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillClosedCurve(nativeGraphics_, brush.nativeBrush_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void fillClosedCurve(Brush brush, PointF[] points, FillMode fillMode, float tension = 0.5f) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillClosedCurve2(nativeGraphics_, brush.nativeBrush_, points.ptr, points.length, fillMode, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void fillClosedCurve(Brush brush, Point[] points) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillClosedCurveI(nativeGraphics_, brush.nativeBrush_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void fillClosedCurve(Brush brush, Point[] points, FillMode fillMode, float tension = 0.5f) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillClosedCurve2I(nativeGraphics_, brush.nativeBrush_, points.ptr, points.length, fillMode, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void fillRegion(Brush brush, Region region) {
    if (brush is null)
      throw new ArgumentNullException("brush");
    if (region is null)
      throw new ArgumentNullException("region");

    Status status = GdipFillRegion(nativeGraphics_, brush.nativeBrush_, region.nativeRegion_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawString(string s, Font font, Brush brush, RectF layoutRect, StringFormat format = null) {
    if (brush is null)
      throw new ArgumentNullException("brush");
    if (s != null) {
      if (font is null)
        throw new ArgumentNullException("font");

      Status status = GdipDrawString(nativeGraphics_, s.toUTF16z(), s.length, font.nativeFont_, layoutRect, (format is null ? Handle.init : format.nativeFormat_), brush.nativeBrush_);
      if (status != Status.OK)
        throw statusException(status);
    }
  }

  /**
   */
  void drawString(string s, Font font, Brush brush, PointF point, StringFormat format = null) {
    drawString(s, font, brush, RectF(point.x, point.y, 0, 0), format);
  }

  /**
   */
  void drawString(string s, Font font, Brush brush, float x, float y, StringFormat format = null) {
    drawString(s, font, brush, RectF(x, y, 0, 0), format);
  }

  /**
   */
  SizeF measureString(string s, Font font, SizeF layoutArea, StringFormat format = null) {
    if (s == null)
      return SizeF(0, 0);

    if (font is null)
      throw new ArgumentNullException("font");

    RectF layoutRect = RectF(0, 0, layoutArea.width, layoutArea.height);
    RectF boundingBox;
    int codePointsFitted, linesFitted;

    Status status = GdipMeasureString(nativeGraphics_, s.toUTF16z(), s.length, font.nativeFont_, layoutRect, (format is null ? Handle.init : format.nativeFormat_), boundingBox, codePointsFitted, linesFitted);
    if (status != Status.OK)
      throw statusException(status);

    return boundingBox.size;
  }

  /**
   */
  SizeF measureString(string s, Font font, SizeF layoutArea, StringFormat format, out int codePointsFitted, out int linesFitted) {
    if (s == null) {
      codePointsFitted = 0;
      linesFitted = 0;
      return SizeF(0, 0);
    }

    if (font is null)
      throw new ArgumentNullException("font");

    RectF layoutRect = RectF(0, 0, layoutArea.width, layoutArea.height);
    RectF boundingBox;

    Status status = GdipMeasureString(nativeGraphics_, s.toUTF16z(), s.length, font.nativeFont_, layoutRect, (format is null ? Handle.init : format.nativeFormat_), boundingBox, codePointsFitted, linesFitted);
    if (status != Status.OK)
      throw statusException(status);

    return boundingBox.size;
  }

  /**
   */
  SizeF measureString(string s, Font font) {
    return measureString(s, font, SizeF(0, 0));
  }

  /**
   */
  SizeF measureString(string s, Font font, PointF origin, StringFormat format) {
    if (s == null)
      return SizeF(0, 0);

    if (font is null)
      throw new ArgumentNullException("font");

    RectF layoutRect = RectF(origin.x, origin.y, 0, 0);
    RectF boundingBox;
    int codePointsFitted, linesFitted;

    Status status = GdipMeasureString(nativeGraphics_, s.toUTF16z(), s.length, font.nativeFont_, layoutRect, (format is null ? Handle.init : format.nativeFormat_), boundingBox, codePointsFitted, linesFitted);
    if (status != Status.OK)
      throw statusException(status);

    return boundingBox.size;
  }

  /**
   */
  Region[] measureCharacterRanges(string s, Font font, RectF layoutRect, StringFormat format) {
    if (s == null)
      return new Region[0];
    if (font is null)
      throw new ArgumentNullException("font");

    int count;
    Status status = GdipGetStringFormatMeasurableCharacterRangeCount((format is null ? Handle.init : format.nativeFormat), count);
    if (status != Status.OK)
      throw statusException(status);

    Region[] regions = new Region[count];

    Handle[] nativeRegions = new Handle[count];
    for (int i = 0; i < count; i++) {
      regions[i] = new Region;
      nativeRegions[i] = regions[i].nativeRegion_;
    }

    status = GdipMeasureCharacterRanges(nativeGraphics_, s.toUTF16z(), s.length, font.nativeFont_, layoutRect, (format is null ? Handle.init : format.nativeFormat_), count, nativeRegions.ptr);
    if (status != Status.OK)
      throw statusException(status);

    return regions;
  }

  /**
   */
  void drawImage(Image image, PointF point) {
    drawImage(image, point.x, point.y);
  }

  /**
   */
  void drawImage(Image image, float x, float y) {
    if (image is null)
      throw new ArgumentNullException("image");

    Status status = GdipDrawImage(nativeGraphics_, image.nativeImage_, x, y);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Draws the specified Image at the specified location and with the specified size.
   * Params:
   *   image = The Image to draw.
   *   rect = The location and size of the drawn _image.
   */
  void drawImage(Image image, RectF rect) {
    drawImage(image, rect.x, rect.y, rect.width, rect.height);
  }

  /**
   * Draws the specified Image at the specified location and with the specified size.
   * Params:
   *   image = The Image to draw.
   *   x = The x-coordinate of the upper-left corner of the drawn _image.
   *   y = The y-coordinate of the upper-left corner of the drawn _image.
   *   width = The _width of the drawn _image.
   *   height = The _height of the drawn _image.
   */
  void drawImage(Image image, float x, float y, float width, float height) {
    if (image is null)
      throw new ArgumentNullException("image");

    Status status = GdipDrawImageRect(nativeGraphics_, image.nativeImage_, x, y, width, height);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Draws a portion of an _image at a specified location.
   * Params:
   *   image = The Image to draw.
   *   x = The x-coordinate of the upper-left corner of the drawn _image.
   *   y = The y-coordinate of the upper-left corner of the drawn _image.
   *   srcRect = The portion of the _image to draw.
   *   srcUnit = A member of the GraphicsUnit enumeration that specifies the units of measure used by srcRect.
   */
  void drawImage(Image image, float x, float y, Rect srcRect, GraphicsUnit srcUnit) {
    if (image is null)
      throw new ArgumentNullException("image");

    Status status = GdipDrawImagePointRect(nativeGraphics_, image.nativeImage_, x, y, srcRect.x, srcRect.y, srcRect.width, srcRect.height, srcUnit);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Draws the specified portion of the specified Image at the specified location and with the specified size.
   * Params:
   *   image = The Image to draw.
   *   destRect = The location and size of the drawn _image. The _image is scaled to fit the rectangle.
   *   srcX = The x-coordinate of the upper-left corner of the portion of the source _image to draw.
   *   srcY = The y-coordinate of the upper-left corner of the portion of the source _image to draw.
   *   srcWidth = The width of the portion of the source _image to draw.
   *   srcHeight = The height of the portion of the source _image to draw.
   *   srcUnit = A member of the GraphicsUnit enumeration that specifies the units of measure used by srcRect.
   *   imageAttrs = Specifies recoloring and gamma information.
   *   callback = A delegate that specifies a method to call during the drawing of the _image to check whether to stop execution of the method.
   *   callbackData = Value specifying additional data for the callback to use when checking whether to stop execution of the method.
   */
  void drawImage(Image image, RectF destRect, float srcX, float srcY, float srcWidth, float srcHeight, GraphicsUnit srcUnit, ImageAttributes imageAttrs = null, DrawImageAbort callback = null, void* callbackData = null) {

    static DrawImageAbort callbackDelegate;

    extern(Windows) static int drawImageAbortCallback(void* callbackData) {
      return callbackDelegate(callbackData) ? 1 : 0;
    }

    if (image is null)
      throw new ArgumentNullException("image");

    callbackDelegate = callback;
    Status status = GdipDrawImageRectRect(nativeGraphics_, image.nativeImage_, destRect.x, destRect.y, destRect.width, destRect.height, srcX, srcY, srcWidth, srcHeight, srcUnit, (imageAttrs is null ? Handle.init : imageAttrs.nativeImageAttributes), (callback == null ? null : &drawImageAbortCallback), callbackData);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawImage(Image image, PointF[] destPoints) {
    if (image is null)
      throw new ArgumentNullException("image");

    if (destPoints.length != 3 && destPoints.length != 4)
      throw new ArgumentException("Destination points must be an array with a length of 3 or 4.");

    Status status = GdipDrawImagePoints(nativeGraphics_, image.nativeImage_, destPoints.ptr, destPoints.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawImage(Image image, PointF[] destPoints, RectF srcRect, GraphicsUnit srcUnit, ImageAttributes imageAttrs = null, DrawImageAbort callback = null, void* callbackData = null) {
    static DrawImageAbort callbackDelegate;

    extern(Windows) static int drawImageAbortCallback(void* callbackData) {
      return callbackDelegate(callbackData) ? 1 : 0;
    }

    if (image is null)
      throw new ArgumentNullException("image");

    if (destPoints.length != 3 && destPoints.length != 4)
      throw new ArgumentException("Destination points must be an array with a length of 3 or 4.");

   callbackDelegate = callback;
   Status status = GdipDrawImagePointsRect(nativeGraphics_, image.nativeImage_, destPoints.ptr, destPoints.length, srcRect.x, srcRect.y, srcRect.width, srcRect.height, srcUnit, (imageAttrs is null ? Handle.init : imageAttrs.nativeImageAttributes), (callback == null ? null : &drawImageAbortCallback), callbackData);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Draws the specified Image, using its original physical size, at the specified location.
   * Params:
   *   image = The Image to draw.
   *   point = The location of the upper-left corner of the drawn _image.
   */
  void drawImage(Image image, Point point) {
    drawImage(image, point.x, point.y);
  }

  /**
   * Draws the specified Image, using its original physical size, at the location specified by a coordinate pair.
   * Params:
   *   image = The Image to _draw.
   *   x = The x-coordinate of the upper-left corner of the drawn _image.
   *   y = The y-coordinate of the upper-left corner of the drawn _image.
   */
  void drawImage(Image image, int x, int y) {
    if (image is null)
      throw new ArgumentNullException("image");

    Status status = GdipDrawImageI(nativeGraphics_, image.nativeImage_, x, y);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Draws the specified Image at the specified location and with the specified size.
   * Params:
   *   image = The Image to draw.
   *   rect = The location and size of the drawn _image.
   */
  void drawImage(Image image, Rect rect) {
    drawImage(image, rect.x, rect.y, rect.width, rect.height);
  }

  /**
   * Draws the specified Image at the specified location and with the specified size.
   * Params:
   *   image = The Image to draw.
   *   x = The x-coordinate of the upper-left corner of the drawn _image.
   *   y = The y-coordinate of the upper-left corner of the drawn _image.
   *   width = The _width of the drawn _image.
   *   height = The _height of the drawn _image.
   */
  void drawImage(Image image, int x, int y, int width, int height) {
    if (image is null)
      throw new ArgumentNullException("image");

    Status status = GdipDrawImageRectI(nativeGraphics_, image.nativeImage_, x, y, width, height);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Draws a portion of an _image at a specified location.
   * Params:
   *   image = The Image to draw.
   *   x = The x-coordinate of the upper-left corner of the drawn _image.
   *   y = The y-coordinate of the upper-left corner of the drawn _image.
   *   srcRect = The portion of the _image to draw.
   *   srcUnit = A member of the GraphicsUnit enumeration that specifies the units of measure used by srcRect.
   */
  void drawImage(Image image, int x, int y, Rect srcRect, GraphicsUnit srcUnit) {
    if (image is null)
      throw new ArgumentNullException("image");

    Status status = GdipDrawImagePointRectI(nativeGraphics_, image.nativeImage_, x, y, srcRect.x, srcRect.y, srcRect.width, srcRect.height, srcUnit);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Draws the specified portion of the specified Image at the specified location and with the specified size.
   * Params:
   *   image = The Image to draw.
   *   destRect = The location and size of the drawn _image. The _image is scaled to fit the rectangle.
   *   srcX = The x-coordinate of the upper-left corner of the portion of the source _image to draw.
   *   srcY = The y-coordinate of the upper-left corner of the portion of the source _image to draw.
   *   srcWidth = The width of the portion of the source _image to draw.
   *   srcHeight = The height of the portion of the source _image to draw.
   *   srcUnit = A member of the GraphicsUnit enumeration that specifies the units of measure used by srcRect.
   *   imageAttrs = Specifies recoloring and gamma information.
   *   callback = A delegate that specifies a method to call during the drawing of the _image to check whether to stop execution of the method.
   *   callbackData = Value specifying additional data for the callback to use when checking whether to stop execution of the method.
   */
  void drawImage(Image image, Rect destRect, int srcX, int srcY, int srcWidth, int srcHeight, GraphicsUnit srcUnit, ImageAttributes imageAttrs = null, DrawImageAbort callback = null, void* callbackData = null) {

    static DrawImageAbort callbackDelegate;

    extern(Windows) static int drawImageAbortCallback(void* callbackData) {
      return callbackDelegate(callbackData) ? 1 : 0;
    }

    if (image is null)
      throw new ArgumentNullException("image");

    callbackDelegate = callback;
    Status status = GdipDrawImageRectRectI(nativeGraphics_, image.nativeImage_, destRect.x, destRect.y, destRect.width, destRect.height, srcX, srcY, srcWidth, srcHeight, srcUnit, (imageAttrs is null ? Handle.init : imageAttrs.nativeImageAttributes), (callback == null ? null : &drawImageAbortCallback), callbackData);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawImage(Image image, Point[] destPoints) {
    if (image is null)
      throw new ArgumentNullException("image");

    if (destPoints.length != 3 && destPoints.length != 4)
      throw new ArgumentException("Destination points must be an array with a length of 3 or 4.");

    Status status = GdipDrawImagePointsI(nativeGraphics_, image.nativeImage_, destPoints.ptr, destPoints.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawImage(Image image, Point[] destPoints, Rect srcRect, GraphicsUnit srcUnit, ImageAttributes imageAttrs = null, DrawImageAbort callback = null, void* callbackData = null) {
    static DrawImageAbort callbackDelegate;

    extern(Windows) static int drawImageAbortCallback(void* callbackData) {
      return callbackDelegate(callbackData) ? 1 : 0;
    }

    if (image is null)
      throw new ArgumentNullException("image");

    if (destPoints.length != 3 && destPoints.length != 4)
      throw new ArgumentException("Destination points must be an array with a length of 3 or 4.");

   callbackDelegate = callback;
   Status status = GdipDrawImagePointsRectI(nativeGraphics_, image.nativeImage_, destPoints.ptr, destPoints.length, srcRect.x, srcRect.y, srcRect.width, srcRect.height, srcUnit, (imageAttrs is null ? Handle.init : imageAttrs.nativeImageAttributes), (callback == null ? null : &drawImageAbortCallback), callbackData);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  float dpiX() {
    float dpi;
    Status status = GdipGetDpiX(nativeGraphics_, dpi);
    if (status != Status.OK)
      throw statusException(status);
    return dpi;
  }

  /**
   */
  float dpiY() {
    float dpi;
    Status status = GdipGetDpiY(nativeGraphics_, dpi);
    if (status != Status.OK)
      throw statusException(status);
    return dpi;
  }

  /**
   */
  void pageScale(float value) {
    Status status = GdipSetPageScale(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  float pageScale() {
    float scale;
    Status status = GdipGetPageScale(nativeGraphics_, scale);
    if (status != Status.OK)
      throw statusException(status);
    return scale;
  }

  /**
   */
  void pageUnit(GraphicsUnit value) {
    Status status = GdipSetPageUnit(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  GraphicsUnit pageUnit() {
    GraphicsUnit value;
    Status status = GdipGetPageUnit(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  void transform(Matrix value) {
    Status status = GdipSetWorldTransform(nativeGraphics_, value.nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  Matrix transform() {
    Matrix m = new Matrix;
    Status status = GdipGetWorldTransform(nativeGraphics_, m.nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
    return m;
  }

  /**
   */
  void compositingMode(CompositingMode value) {
    Status status = GdipSetCompositingMode(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  CompositingMode compositingMode() {
    CompositingMode mode;
    Status status = GdipGetCompositingMode(nativeGraphics_, mode);
    if (status != Status.OK)
      throw statusException(status);
    return mode;
  }

  /**
   */
  void compositingQuality(CompositingQuality value) {
    Status status = GdipSetCompositingQuality(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  CompositingQuality compositingQuality() {
    CompositingQuality value;
    Status status = GdipGetCompositingQuality(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  void interpolationMode(InterpolationMode value) {
    Status status = GdipSetInterpolationMode(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  InterpolationMode interpolationMode() {
    InterpolationMode mode;
    Status status = GdipGetInterpolationMode(nativeGraphics_, mode);
    if (status != Status.OK)
      throw statusException(status);
    return mode;
  }

  /**
   */
  void smoothingMode(SmoothingMode value) {
    Status status = GdipSetSmoothingMode(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  SmoothingMode smoothingMode() {
    SmoothingMode mode;
    Status status = GdipGetSmoothingMode(nativeGraphics_, mode);
    if (status != Status.OK)
      throw statusException(status);
    return mode;
  }

  /**
   */
  void pixelOffsetMode(PixelOffsetMode value) {
    Status status = GdipSetPixelOffsetMode(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  PixelOffsetMode pixelOffsetMode() {
    PixelOffsetMode value;
    Status status = GdipGetPixelOffsetMode(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  void textContrast(uint value) {
    Status status = GdipSetTextContrast(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  uint textContrast() {
    uint contrast;
    Status status = GdipGetTextContrast(nativeGraphics_, contrast);
    if (status != Status.OK)
      throw statusException(status);
    return contrast;
  }

  /**
   */
  void textRenderingHint(TextRenderingHint value) {
    Status status = GdipSetTextRenderingHint(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  TextRenderingHint textRenderingHint() {
    TextRenderingHint value;
    Status status = GdipGetTextRenderingHint(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  bool isClipEmpty() {
    int value;
    Status status = GdipIsClipEmpty(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value == 1;
  }

  /**
   */
  bool isVisibleClipEmpty() {
    int value;
    Status status = GdipIsVisibleClipEmpty(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value == 1;
  }

  /**
   */
  void clip(Region value) {
    setClip(value, CombineMode.Replace);
  }

  /**
   * ditto
   */
  Region clip() {
    Region region = new Region;
    Status status = GdipGetClip(nativeGraphics_, region.nativeRegion_);
    if (status != Status.OK)
      throw statusException(status);
    return region;
  }

  /**
   */
  RectF clipBounds() {
    RectF value;
    Status status = GdipGetClipBounds(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  RectF visibleClipBounds() {
    RectF value;
    Status status = GdipGetVisibleClipBounds(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  void renderingOrigin(Point value) {
    Status status = GdipGetRenderingOrigin(nativeGraphics_, value.x, value.y);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  Point renderingOrigin() {
    int x, y;
    Status status = GdipGetRenderingOrigin(nativeGraphics_, x, y);
    if (status != Status.OK)
      throw statusException(status);
    return Point(x, y);
  }

  private this(Handle nativeGraphics) {
    nativeGraphics_ = nativeGraphics;
  }

}

/**
 */
final class GraphicsState {

  private int nativeState_;

  private this(int state) {
    nativeState_ = state;
  }

}

/**
 */
abstract class Image {

  alias bool delegate(void*) GetThumbnailImageAbort;

  private Handle nativeImage_;

  ~this() {
    dispose();
  }

  /**
   */
  void dispose() {
    if (nativeImage_ != Handle.init) {
      GdipDisposeImageSafe(nativeImage_);
      nativeImage_ = Handle.init;
    }
  }

  /**
   */
  final void save(string fileName) {
    save(fileName, rawFormat);
  }

  /**
   */
  final void save(string fileName, ImageFormat format) {
    if (format is null)
      throw new ArgumentNullException("format");

    ImageCodecInfo codec = null;

    foreach (item; ImageCodecInfo.getImageEncoders()) {
      if (item.formatId == format.guid) {
        codec = item;
        break;
      }
    }

    if (codec is null) {
      foreach (item; ImageCodecInfo.getImageEncoders()) {
        if (item.formatId == ImageFormat.png.guid) {
          codec = item;
          break;
        }
      }
    }

    save(fileName, codec, null);
  }

  /**
   */
  final void save(string fileName, ImageCodecInfo encoder, EncoderParameters encoderParams) {
    if (encoder is null)
      throw new ArgumentNullException("encoder");

    GpEncoderParameters* pParams = null;
    if (encoderParams !is null)
      pParams = encoderParams.forGDIplus();

    GUID g = encoder.clsid;
    Status status = GdipSaveImageToFile(nativeImage_, fileName.toUTF16z(), g, pParams);

    if (pParams !is null)
      LocalFree(cast(Handle)pParams);

    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  final void save(Stream stream, ImageFormat format) {
    if (stream is null)
      throw new ArgumentNullException("stream");

    if (format is null)
      throw new ArgumentNullException("format");

    ImageCodecInfo codec = null;
    foreach (item; ImageCodecInfo.getImageEncoders()) {
      if (item.formatId == format.guid) {
        codec = item;
        break;
      }
    }

    save(stream, codec, null);
  }

  /**
   */
  final void save(Stream stream, ImageCodecInfo encoder, EncoderParameters encoderParams) {
    if (stream is null)
      throw new ArgumentNullException("stream");

    if (encoder is null)
      throw new ArgumentNullException("encoder");

    auto s = new COMStream(stream);
    scope(exit) tryRelease(s);

    GpEncoderParameters* pParams = null;
    if (encoderParams !is null)
      pParams = encoderParams.forGDIplus();

    GUID g = encoder.clsid;
    Status status = GdipSaveImageToStream(nativeImage_, s, g, pParams);

    if (pParams !is null)
      LocalFree(cast(Handle)pParams);

    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  static Image fromFile(string fileName, bool useEmbeddedColorManagement = false) {
    Handle nativeImage;
    Status status = useEmbeddedColorManagement 
      ? GdipLoadImageFromFileICM(fileName.toUTF16z(), nativeImage)
      : GdipLoadImageFromFile(fileName.toUTF16z(), nativeImage);
    if (status != Status.OK)
      throw statusException(status);

    status = GdipImageForceValidation(nativeImage);
    if (status != Status.OK) {
      GdipDisposeImage(nativeImage);
      throw statusException(status);
    }

    return createImage(nativeImage);
  }

  /**
   */
  static Image fromStream(Stream stream, bool useEmbeddedColorManagement = false) {
    auto s = new COMStream(stream);
    scope(exit) tryRelease(s);

    Handle nativeImage;
    Status status = useEmbeddedColorManagement
      ? GdipLoadImageFromStreamICM(s, nativeImage)
      : GdipLoadImageFromStream(s, nativeImage);
    if (status != Status.OK)
      throw statusException(status);

    status = GdipImageForceValidation(nativeImage);
    if (status != Status.OK) {
      GdipDisposeImage(nativeImage);
      throw statusException(status);
    }

    return createImage(nativeImage);
  }

  /**
   */
  static Bitmap fromHbitmap(Handle hbitmap, Handle hpalette = Handle.init) {
    Handle bitmap;
    Status status = GdipCreateBitmapFromHBITMAP(hbitmap, hpalette, bitmap);
    if (status != Status.OK)
      throw statusException(status);
    return new Bitmap(bitmap);
  }

  /**
   */
  final RectF getBounds(ref GraphicsUnit pageUnit) {
    RectF rect;
    Status status = GdipGetImageBounds(nativeImage_, rect, pageUnit);
    if (status != Status.OK)
      throw statusException(status);
    return rect;
  }

  /**
   */
  final Image getThumbnailImage(int width, int height, GetThumbnailImageAbort callback, void* callbackData) {

    static GetThumbnailImageAbort callbackDelegate;

    extern(Windows) static int thumbnailImageAbortCallback(void* callbackData) {
      return callbackDelegate(callbackData) ? 1 : 0;
    }

    callbackDelegate = callback;
    Handle thumbnail;
    Status status = GdipGetImageThumbnail(nativeImage_, width, height, thumbnail, ((callback is null) ? null : &thumbnailImageAbortCallback), callbackData);
    if (status != Status.OK)
      throw statusException(status);
    return createImage(thumbnail);
  }

  /**
   */
  final void rotateFlip(RotateFlipType rotateFlipType) {
    Status status = GdipImageRotateFlip(nativeImage_, rotateFlipType);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  final void selectActiveFrame(FrameDimension dimension, int frameIndex) {
    GUID id = dimension.guid;
    Status status = GdipImageSelectActiveFrame(nativeImage_, id, frameIndex);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  final PropertyItem getPropertyItem(int propId) {
    uint size;
    Status status = GdipGetPropertyItemSize(nativeImage_, propId, size);
    if (status != Status.OK)
      throw statusException(status);

    if (size == 0)
      return null;

    GpPropertyItem* buffer = cast(GpPropertyItem*)LocalAlloc(LMEM_FIXED, size);
    status = GdipGetPropertyItem(nativeImage_, propId, size, buffer);
    if (status != Status.OK)
      throw statusException(status);

    auto item = new PropertyItem;
    item.id = buffer.id;
    item.len = buffer.len;
    item.type = buffer.type;
    item.value = cast(ubyte[])buffer.value[0 .. buffer.len];

    LocalFree(cast(Handle)buffer);

    return item;
  }

  /**
   */
  final void removePropertyItem(int propId) {
    Status status = GdipRemovePropertyItem(nativeImage_, propId);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  final void setPropertyItem(PropertyItem propItem) {
    GpPropertyItem item;
    item.id = propItem.id;
    item.len = propItem.len;
    item.type = propItem.type;
    item.value = propItem.value.ptr;

    Status status = GdipSetPropertyItem(nativeImage_, item);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  final uint getFrameCount(FrameDimension dimension) {
    uint count;
    GUID dimensionId = dimension.guid;
    Status status = GdipImageGetFrameCount(nativeImage_, dimensionId, count);
    if (status != Status.OK)
      throw statusException(status);

    return count;
  }

  /**
   */
  final SizeF physicalDimension() {
    float width, height;
    Status status = GdipGetImageDimension(nativeImage_, width, height);
    if (status != Status.OK)
      throw statusException(status);
    return SizeF(width, height);
  }

  /**
   */
  final int width() {
    int value;
    Status status = GdipGetImageWidth(nativeImage_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  final int height() {
    int value;
    Status status = GdipGetImageHeight(nativeImage_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  final Size size() {
    return Size(width, height);
  }

  /**
   */
  final ImageFlags flags() {
    uint value;
    Status status = GdipGetImageFlags(nativeImage_, value);
    if (status != Status.OK)
      throw statusException(status);
    return cast(ImageFlags)value;
  }

  /**
   */
  final float horizontalResolution() {
    float resolution;
    Status status = GdipGetImageHorizontalResolution(nativeImage_, resolution);
    if (status != Status.OK)
      throw statusException(status);
    return resolution;
  }

  /**
   */
  final float verticalResolution() {
    float resolution;
    Status status = GdipGetImageVerticalResolution(nativeImage_, resolution);
    if (status != Status.OK)
      throw statusException(status);
    return resolution;
  }

  /**
   */
  final ImageFormat rawFormat() {
    GUID format;
    Status status = GdipGetImageRawFormat(nativeImage_, format);
    if (status != Status.OK)
      throw statusException(status);
    return new ImageFormat(format);
  }

  /**
   */
  final PixelFormat pixelFormat() {
    PixelFormat value;
    Status status = GdipGetImagePixelFormat(nativeImage_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  final GUID[] frameDimensionsList() {
    uint count;
    Status status = GdipImageGetFrameDimensionsCount(nativeImage_, count);
    if (status != Status.OK)
      throw statusException(status);

    if (count == 0)
      return new GUID[0];

    GUID[] dimensionIDs = new GUID[count];

    status = GdipImageGetFrameDimensionsList(nativeImage_, dimensionIDs.ptr, count);
    if (status != Status.OK)
      throw statusException(status);

    return dimensionIDs;
  }

  /**
   */
  final int[] propertyIdList() {
    uint num;
    Status status = GdipGetPropertyCount(nativeImage_, num);
    if (status != Status.OK)
      throw statusException(status);

    int[] list = new int[num];
    if (num != 0) {
      status = GdipGetPropertyIdList(nativeImage_, num, list.ptr);
      if (status != Status.OK)
        throw statusException(status);
    }
    return list;
  }

  /**
   */
  final void palette(ColorPalette value) {
    auto p = value.forGDIplus();
    Status status = GdipSetImagePalette(nativeImage_, p);
    LocalFree(cast(Handle)p);

    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  final ColorPalette palette() {
    int size = -1;
    Status status = GdipGetImagePaletteSize(nativeImage_, size);
    if (status != Status.OK)
      throw statusException(status);

    GpColorPalette* p = cast(GpColorPalette*)LocalAlloc(LMEM_FIXED, size);
    status = GdipGetImagePalette(nativeImage_, p, size);
    if (status != Status.OK)
      throw statusException(status);

    auto ret = new ColorPalette(p);
    LocalFree(cast(Handle)p);
    return ret;
  }

  private static Image createImage(Handle nativeImage) {
    int imageType = -1;
    Status status = GdipGetImageType(nativeImage, imageType);
    if (status != Status.OK)
      throw statusException(status);

    if (imageType == 1)
      return new Bitmap(nativeImage);
    /*else if (imageType == 2)
      return new Metafile(nativeImage);*/

    throw new ArgumentException("Image type is unknown.");
  }

}

/**
 */
final class Bitmap : Image {

  this(string fileName, bool useEmbeddedColorManagement = false) {
    Status status = useEmbeddedColorManagement
      ? GdipCreateBitmapFromFileICM(fileName.toUTF16z(), nativeImage_)
      : GdipCreateBitmapFromFile(fileName.toUTF16z(), nativeImage_);
    if (status != Status.OK)
      throw statusException(status);

    status = GdipImageForceValidation(nativeImage_);
    if (status != Status.OK) {
      GdipDisposeImage(nativeImage_);
      throw statusException(status);
    }
  }

  /**
   */
  this(Stream stream) {
    if (stream is null)
      throw new ArgumentNullException("stream");

    auto s = new COMStream(stream);
    scope(exit) tryRelease(s);

    Status status = GdipCreateBitmapFromStream(s, nativeImage_);
    if (status != Status.OK)
      throw statusException(status);

    status = GdipImageForceValidation(nativeImage_);
    if (status != Status.OK) {
      GdipDisposeImage(nativeImage_);
      throw statusException(status);
    }
  }

  /**
   */
  this(Image original) {
    this(original, original.width, original.height);
  }

  /**
   */
  this(Image original, int width, int height) {
    this(width, height);

    scope g = Graphics.fromImage(this);
    g.clear(Color.transparent);
    g.drawImage(original, 0, 0, width, height);
  }

  /**
   */
  this(Image original, Size size) {
    this(original, size.width, size.height);
  }

  /**
   */
  this(int width, int height, PixelFormat format = PixelFormat.Format32bppArgb) {
    Status status = GdipCreateBitmapFromScan0(width, height, 0, format, null, nativeImage_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(Size size) {
    this(size.width, size.height);
  }

  /**
   */
  this(int width, int height, int stride, PixelFormat format, ubyte* scan0) {
    Status status = GdipCreateBitmapFromScan0(width, height, stride, format, scan0, nativeImage_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(int width, int height, Graphics g) {
    if (g is null)
      throw new ArgumentNullException("g");

    Status status = GdipCreateBitmapFromGraphics(width, height, g.nativeGraphics_, nativeImage_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  static Bitmap fromResource(Handle hinstance, string bitmapName) {
    // Poorly documented, but the resource type in your .rc script must be BITMAP, eg
    //   splash BITMAP "images\\splash.bmp"
    // where bitmapName is "splash". 
    // Does not appear to load any other image type such as JPEG, GIF or PNG, so of limited utility. 
    // A more flexible way would be to call LoadResource/LockResource to copy the data into a 
    // MemoryStream which Image.fromStream can use.

    Handle nativeImage;
    Status status = GdipCreateBitmapFromResource(hinstance, bitmapName.toUTF16z(), nativeImage);
    if (status != Status.OK)
      throw statusException(status);
    return new Bitmap(nativeImage);
  }

  /**
   */
  static Bitmap fromHicon(Handle hicon) {
    Handle bitmap;
    Status status = GdipCreateBitmapFromHICON(hicon, bitmap);
    if (status != Status.OK)
      throw statusException(status);
    return new Bitmap(bitmap);
  }

  /**
   */
  final Handle getHicon() {
    Handle hicon;
    Status status = GdipCreateHICONFromBitmap(nativeImage_, hicon);
    if (status != Status.OK)
      throw statusException(status);
    return hicon;
  }

  /**
   */
  final Handle getHbitmap(Color background = Color.lightGray) {
    Handle hbitmap;
    Status status = GdipCreateHBITMAPFromBitmap(nativeImage_, hbitmap, background.toRgb());
    if (status != Status.OK)
      throw statusException(status);
    return hbitmap;
  }

  /**
   */
  final BitmapData lockBits(Rect rect, ImageLockMode flags, PixelFormat format, BitmapData bitmapData = null) {
    if (bitmapData is null)
      bitmapData = new BitmapData;

    GpBitmapData data;
    if (bitmapData !is null) {
      data.Width = bitmapData.width;
      data.Height = bitmapData.height;
      data.Stride = bitmapData.stride;
      data.Scan0 = bitmapData.scan0;
      data.Reserved = bitmapData.reserved;
    }

    Status status = GdipBitmapLockBits(nativeImage_, rect, flags, format, data);
    if (status != Status.OK)
      throw statusException(status);

    bitmapData.width = data.Width;
    bitmapData.height = data.Height;
    bitmapData.stride = data.Stride;
    bitmapData.scan0 = data.Scan0;
    bitmapData.reserved = data.Reserved;

    return bitmapData;
  }

  /**
   */
  final public void unlockBits(BitmapData bitmapData) {
    GpBitmapData data;
    data.Width = bitmapData.width;
    data.Height = bitmapData.height;
    data.Stride = bitmapData.stride;
    data.Scan0 = bitmapData.scan0;
    data.Reserved = bitmapData.reserved;

    Status status = GdipBitmapUnlockBits(nativeImage_, data);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  final Color getPixel(int x, int y) {
    int color;
    Status status = GdipBitmapGetPixel(nativeImage_, x, y, color);
    if (status != Status.OK)
      throw statusException(status);
    return Color.fromArgb(color);
  }

  /**
   */
  final void setPixel(int x, int y, Color color) {
    Status status = GdipBitmapSetPixel(nativeImage_, x, y, color.toArgb());
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  final void setResolution(float xdpi, float ydpi) {
    Status status = GdipBitmapSetResolution(nativeImage_, xdpi, ydpi);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  final void makeTransparent() {
    Color transparentColor = Color.lightGray;
    if (width > 0 && height > 0)
      transparentColor = getPixel(0, height - 1);
    if (transparentColor.a >= 255)
      makeTransparent(transparentColor);
  }

  /**
   */
  final void makeTransparent(Color transparentColor) {
    Size sz = size;

    scope bmp = new Bitmap(sz.width, sz.height, PixelFormat.Format32bppArgb);
    scope g = Graphics.fromImage(bmp);
    g.clear(Color.transparent);

    scope attrs = new ImageAttributes;
    attrs.setColorKey(transparentColor, transparentColor);
    g.drawImage(this, Rect(0, 0, sz.width, sz.height), 0, 0, sz.width, sz.height, GraphicsUnit.Pixel, attrs);

    Handle temp = nativeImage_;
    nativeImage_ = bmp.nativeImage_;
    bmp.nativeImage_ = temp;
  }

  private this() {
  }

  private this(Handle nativeImage) {
    nativeImage_ = nativeImage;
  }

}

/**
 */
abstract class Brush {

  private Handle nativeBrush_;

  ~this() {
    dispose();
  }

  /**
   */
  final void dispose() {
    if (nativeBrush_ != Handle.init) {
      GdipDeleteBrushSafe(nativeBrush_);
      nativeBrush_ = Handle.init;
    }
  }

}

/**
 */
final class SolidBrush : Brush {

  private Color color_;
  private bool immutable_;

  package this(Color color, bool immu) {
    this(color);
    immutable_ = immu;
  }

  /**
   */
  this(Color color) {
    color_ = color;

    Status status = GdipCreateSolidFill(color.toArgb(), nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void color(Color value) {
    if (color_ != value) {
      Status status = GdipSetSolidFillColor(nativeBrush_, value.toArgb());
      if (status != Status.OK)
        throw statusException(status);
      color_ = value;
    }
  }

  /**
   * ditto
   */
  Color color() {
    if (color_.isEmpty) {
      uint value;
      Status status = GdipGetSolidFillColor(nativeBrush_, value);
      if (status != Status.OK)
        throw statusException(status);
      color_ = Color.fromArgb(value);
    }
    return color_;
  }

  package this(Handle nativeBrush) {
    nativeBrush_ = nativeBrush;
  }

}

/**
 */
final class TextureBrush : Brush {

  /**
   */
  this(Image image, WrapMode wrapMode = WrapMode.Tile) {
    if (image is null)
      throw new ArgumentNullException("image");

    Status status = GdipCreateTexture(image.nativeImage_, wrapMode, nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(Image image, WrapMode wrapMode, Rect rect) {
    if (image is null)
      throw new ArgumentNullException("image"); 

    Status status = GdipCreateTexture2I(image.nativeImage_, wrapMode, rect.x, rect.y, rect.width, rect.height, nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(Image image, WrapMode wrapMode, RectF rect) {
    if (image is null)
      throw new ArgumentNullException("image"); 

    Status status = GdipCreateTexture2(image.nativeImage_, wrapMode, rect.x, rect.y, rect.width, rect.height, nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  Image image() {
    Handle nativeImage;
    Status status = GdipGetTextureImage(nativeBrush_, nativeImage);
    if (status != Status.OK)
      throw statusException(status);
    return Image.createImage(nativeImage);
  }

  /**
   */
  void transform(Matrix value) {
    if (value is null)
      throw new ArgumentNullException("value");

    Status status = GdipSetTextureTransform(nativeBrush_, value.nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  Matrix transform() {
    Matrix m = new Matrix;
    Status status = GdipGetTextureTransform(nativeBrush_, m.nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
    return m;
  }

  /**
   */
  void wrapMode(WrapMode value) {
    Status status = GdipSetTextureWrapMode(nativeBrush_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  WrapMode wrapMode() {
    WrapMode result;
    Status status = GdipGetTextureWrapMode(nativeBrush_, result);
    if (status != Status.OK)
      throw statusException(status);
    return result;
  }

  package this(Handle nativeBrush) {
    nativeBrush_ = nativeBrush;
  }

}

/**
 */
final class HatchBrush : Brush {

  /**
   */
  this(HatchStyle hatchStyle, Color foreColor) {
    this(hatchStyle, foreColor, Color.black);
  }

  /**
   */
  this(HatchStyle hatchStyle, Color foreColor, Color backColor) {
    Status status = GdipCreateHatchBrush(hatchStyle, foreColor.toArgb(), backColor.toArgb(), nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  HatchStyle hatchStyle() {
    HatchStyle value;
    Status status = GdipGetHatchStyle(nativeBrush_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  Color foregroundColor() {
    uint argb;
    Status status = GdipGetHatchForegroundColor(nativeBrush_, argb);
    if (status != Status.OK)
      throw statusException(status);
    return Color.fromArgb(argb);
  }

  /**
   */
  Color backgroundColor() {
    uint argb;
    Status status = GdipGetHatchBackgroundColor(nativeBrush_, argb);
    if (status != Status.OK)
      throw statusException(status);
    return Color.fromArgb(argb);
  }

}

/**
 */
final class Blend {

  ///
  float[] factors;

  ///
  float[] positions;

  /**
   */
  this(int count = 1) {
    factors.length = count;
    positions.length = count;
  }

}

/**
 */
final class ColorBlend {

  ///
  Color[] colors;

  ///
  float[] positions;

  /**
   */
  this(int count = 1) {
    colors.length = count;
    positions.length = count;
  }

}

/**
 */
final class LinearGradientBrush : Brush {

  /**
   */
  this(Point startPoint, Point endPoint, Color startColor, Color endColor) {
    Status status = GdipCreateLineBrushI(startPoint, endPoint, startColor.toArgb(), endColor.toArgb(), WrapMode.Tile, nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(PointF startPoint, PointF endPoint, Color startColor, Color endColor) {
    Status status = GdipCreateLineBrush(startPoint, endPoint, startColor.toArgb(), endColor.toArgb(), WrapMode.Tile, nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(Rect rect, Color startColor, Color endColor, LinearGradientMode mode) {
    Status status = GdipCreateLineBrushFromRectI(rect, startColor.toArgb(), endColor.toArgb(), mode, WrapMode.Tile, nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(RectF rect, Color startColor, Color endColor, LinearGradientMode mode) {
    Status status = GdipCreateLineBrushFromRect(rect, startColor.toArgb(), endColor.toArgb(), mode, WrapMode.Tile, nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(Rect rect, Color startColor, Color endColor, float angle, bool isAngleScalable = false) {
    Status status = GdipCreateLineBrushFromRectWithAngleI(rect, startColor.toArgb(), endColor.toArgb(), angle, (isAngleScalable ? 1 : 0), WrapMode.Tile, nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(RectF rect, Color startColor, Color endColor, float angle, bool isAngleScalable = false) {
    Status status = GdipCreateLineBrushFromRectWithAngle(rect, startColor.toArgb(), endColor.toArgb(), angle, (isAngleScalable ? 1 : 0), WrapMode.Tile, nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void setSigmaBellShape(float focus, float scale = 1.0f) {
    Status status = GdipSetLineSigmaBlend(nativeBrush_, focus, scale);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void setBlendTriangularShape(float focus, float scale = 1.0f) {
    Status status = GdipSetLineLinearBlend(nativeBrush_, focus, scale);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void resetTransform() {
    Status status = GdipResetLineTransform(nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void multiplyTransform(Matrix matrix, MatrixOrder order = MatrixOrder.Prepend) {
    if (matrix is null)
      throw new ArgumentNullException("matrix");

    Status status = GdipMultiplyLineTransform(nativeBrush_, matrix.nativeMatrix, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void translateTransform(float dx, float dy, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipTranslateLineTransform(nativeBrush_, dx, dy, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void scaleTransform(float sx, float sy, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipScaleLineTransform(nativeBrush_, sx, sy, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void rorateTransform(float angle, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipRotateLineTransform(nativeBrush_, angle, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void linearColors(Color[] value) {
    Status status = GdipSetLineColors(nativeBrush_, value[0].toArgb(), value[1].toArgb());
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  Color[] linearColors() {
    uint[] colors = new uint[2];
    Status status = GdipGetLineColors(nativeBrush_, colors.ptr);
    if (status != Status.OK)
      throw statusException(status);
    return [ Color.fromArgb(colors[0]), Color.fromArgb(colors[1]) ];
  }

  /**
   */
  void gammaCorrection(bool value) {
    Status status = GdipSetLineGammaCorrection(nativeBrush_, (value ? 1 : 0));
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  bool gammaCorrection() {
    int value;
    Status status = GdipGetLineGammaCorrection(nativeBrush_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value != 0;
  }

  /**
   */
  void blend(Blend value) {
    Status status = GdipSetLineBlend(nativeBrush_, value.factors.ptr, value.positions.ptr, value.factors.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  Blend blend() {
    int count;
    Status status = GdipGetLineBlendCount(nativeBrush_, count);
    if (status != Status.OK)
      throw statusException(status);

    if (count <= 0)
      return null;

    float[] factors = new float[count];
    float[] positions = new float[count];
    status = GdipGetLineBlend(nativeBrush_, factors.ptr, positions.ptr, count);
    if (status != Status.OK)
      throw statusException(status);

    Blend blend = new Blend(count);
    blend.factors = factors.dup;
    blend.positions = positions.dup;
    return blend;
  }

  /**
   */
  void interpolationColors(ColorBlend value) {
    if (value is null)
      throw new ArgumentNullException("value");
    if (value.colors.length < 2)
      throw new ArgumentException("Array of colors must contain at least two elements.");
    if (value.colors.length != value.positions.length)
      throw new ArgumentException("Colors and positions do not have the same number of elements.");
    if (value.positions[0] != 0)
      throw new ArgumentException("Position's first element must be equal to 0.");
    if (value.positions[$ - 1] != 1f)
      throw new ArgumentException("Position's last element must be equal to 1.0.");

    uint[] colors = new uint[value.colors.length];
    foreach (i, ref argb; colors)
      argb = value.colors[i].toArgb();

    Status status = GdipSetLinePresetBlend(nativeBrush_, colors.ptr, value.positions.ptr, value.colors.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  ColorBlend interpolationColors() {
    int count;
    Status status = GdipGetLinePresetBlendCount(nativeBrush_, count);
    if (status != Status.OK)
      throw statusException(status);

    if (count <= 0)
      return null;

    uint[] colors = new uint[count];
    float[] positions = new float[count];
    status = GdipGetLinePresetBlend(nativeBrush_, colors.ptr, positions.ptr, count);
    if (status != Status.OK)
      throw statusException(status);

    ColorBlend blend = new ColorBlend(count);
    blend.colors = new Color[count];
    foreach (i, ref color; blend.colors)
      color = Color.fromArgb(colors[i]);
    blend.positions = positions.dup;
    return blend;
  }

  /**
   */
  void transform(Matrix value) {
    if (value is null)
      throw new ArgumentNullException("value");

    Status status = GdipSetLineTransform(nativeBrush_, value.nativeMatrix);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  Matrix transform() {
    Matrix m = new Matrix;
    Status status = GdipGetLineTransform(nativeBrush_, m.nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
    return m;
  }

  /**
   */
  RectF rectangle() {
    RectF value;
    Status status = GdipGetLineRect(nativeBrush_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  void wrapMode(WrapMode value) {
    Status status = GdipSetLineWrapMode(nativeBrush_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  WrapMode wrapMode() {
    WrapMode value;
    Status status = GdipGetLineWrapMode(nativeBrush_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  package this(Handle nativeBrush) {
    nativeBrush_ = nativeBrush;
  }

}

/**
 */
final class Pen {

  private Handle nativePen_;
  private Color color_;

  /**
   */
  this(Color color, float width = 1f) {
    color_ = color;
    Status status = GdipCreatePen1(color.toArgb(), width, GraphicsUnit.World, nativePen_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(Brush brush, float width = 1f) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipCreatePen2(brush.nativeBrush_, width, GraphicsUnit.Pixel, nativePen_);
    if (status != Status.OK)
      throw statusException(status);
  }

  ~this() {
    dispose();
  }

  /**
   */
  final void dispose() {
    if (nativePen_ != Handle.init) {
      GdipDeletePenSafe(nativePen_);
      nativePen_ = Handle.init;
    }
  }

  /**
   */
  void setLineCap(LineCap startCap, LineCap endCap, DashCap dashCap) {
    Status status = GdipSetPenLineCap197819(nativePen_, startCap, endCap, dashCap);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void resetTransform() {
    Status status = GdipResetPenTransform(nativePen_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void multiplyTransform(Matrix matrix, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipMultiplyPenTransform(nativePen_, matrix.nativeMatrix, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void translateTransform(float dx, float dy, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipTranslatePenTransform(nativePen_, dx, dy, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void scaleTransform(float sx, float sy, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipScalePenTransform(nativePen_, sx, sy, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void rotateTransform(float angle, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipRotatePenTransform(nativePen_, angle, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void width(float value) {
    Status status = GdipSetPenWidth(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  float width() {
    float value = 0;
    Status status = GdipGetPenWidth(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  void startCap(LineCap value) {
    Status status = GdipSetPenStartCap(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  LineCap startCap() {
    LineCap value;
    Status status = GdipGetPenStartCap(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  void endCap(LineCap value) {
    Status status = GdipSetPenEndCap(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  LineCap endCap() {
    LineCap value;
    Status status = GdipGetPenEndCap(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  void dashCap(DashCap value) {
    Status status = GdipSetPenDashCap197819(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  DashCap dashCap() {
    DashCap value;
    Status status = GdipGetPenDashCap197819(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  void lineJoin(LineJoin value) {
    Status status = GdipSetPenLineJoin(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  LineJoin lineJoin() {
    LineJoin value;
    Status status = GdipGetPenLineJoin(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  void miterLimit(float value) {
    Status status = GdipSetPenMiterLimit(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  float miterLimit() {
    float value = 0.0f;
    Status status = GdipGetPenMiterLimit(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  void alignment(PenAlignment value) {
    Status status = GdipSetPenMode(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  PenAlignment alignment() {
    PenAlignment value;
    Status status = GdipGetPenMode(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  void transform(Matrix value) {
    if (value is null)
      throw new ArgumentNullException("value");

    Status status = GdipSetPenTransform(nativePen_, value.nativeMatrix);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  Matrix transform() {
    Matrix m = new Matrix;
    Status status = GdipGetPenTransform(nativePen_, m.nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
    return m;
  }

  /**
   */
  PenType penType() {
    PenType type = cast(PenType)-1;
    Status status = GdipGetPenFillType(nativePen_, type);
    if (status != Status.OK)
      throw statusException(status);
    return type;
  }

  /**
   */
  void color(Color value) {
    if (value != color_) {
      color_ = value;

      Status status = GdipSetPenColor(nativePen_, value.toArgb());
      if (status != Status.OK)
        throw statusException(status);
    }
  }

  /**
   * ditto
   */
  Color color() {
    if (color_.isEmpty) {
      uint argb;
      Status status = GdipGetPenColor(nativePen_, argb);
      if (status != Status.OK)
        throw statusException(status);
      color_ = Color.fromArgb(argb);
    }
    return color_;
  }

  /**
   */
  void brush(Brush value) {
    if (value is null)
      throw new ArgumentNullException("value");

    Status status = GdipSetPenBrushFill(nativePen_, value.nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  Brush brush() {
    switch (penType) {
      case PenType.SolidColor:
        return new SolidBrush(nativeBrush);
      case PenType.TextureFill:
        return new TextureBrush(nativeBrush);
      case PenType.LinearGradient:
        return new LinearGradientBrush(nativeBrush);
      //case PenType.PathGradient:
      //  return new PathGradientBrush(nativeBrush);
      default:
    }
    return null;
  }

  /**
   */
  void dashStyle(DashStyle value) {
    Status status = GdipSetPenDashStyle(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  DashStyle dashStyle() {
    DashStyle value;
    Status status = GdipGetPenDashStyle(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  void dashOffset(float value) {
    Status status = GdipSetPenDashOffset(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  float dashOffset() {
    float value = 0.0f;
    Status status = GdipGetPenDashOffset(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  void dashPattern(float[] value) {
    if (value == null)
      throw statusException(Status.InvalidParameter);

    Status status = GdipSetPenDashArray(nativePen_, value.ptr, value.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  float[] dashPattern() {
    int count;
    Status status = GdipGetPenDashCount(nativePen_, count);
    if (status != Status.OK)
      throw statusException(status);

    float[] dashArray = new float[count];

    status = GdipGetPenDashArray(nativePen_, dashArray.ptr, count);
    if (status != Status.OK)
      throw statusException(status);

    return dashArray;
  }

  /**
   */
  void compoundArray(float[] value) {
    if (value == null)
      throw statusException(Status.InvalidParameter);

    Status status = GdipSetPenCompoundArray(nativePen_, value.ptr, value.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  float[] compoundArray() {
    int count;
    Status status = GdipGetPenCompoundCount(nativePen_, count);
    if (status != Status.OK)
      throw statusException(status);

    float[] array = new float[count];

    status = GdipGetPenCompoundArray(nativePen_, array.ptr, count);
    if (status != Status.OK)
      throw statusException(status);

    return array;
  }

  private Handle nativeBrush() {
    Handle brush;
    Status status = GdipGetPenBrushFill(nativePen_, brush);
    if (status != Status.OK)
      throw statusException(status);
    return brush;
  }

}

/**
 */
final class Path {

  private Handle nativePath_;

  private const float FlatnessDefault = 1.0f / 4.0f;

  /**
   */
  this(FillMode fillMode = FillMode.Alternate) {
    Status status = GdipCreatePath(fillMode, nativePath_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(PointF[] points, ubyte[] types, FillMode fillMode = FillMode.Alternate) {
    if (points.length != types.length)
      throw statusException(Status.InvalidParameter);

    Status status = GdipCreatePath2(points.ptr, types.ptr, types.length, fillMode, nativePath_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(Point[] points, ubyte[] types, FillMode fillMode = FillMode.Alternate) {
    if (points.length != types.length)
      throw statusException(Status.InvalidParameter);

    Status status = GdipCreatePath2I(points.ptr, types.ptr, types.length, fillMode, nativePath_);
    if (status != Status.OK)
      throw statusException(status);
  }

  ~this() {
    dispose();
  }

  /**
   */
  void dispose() {
    if (nativePath_ != Handle.init) {
      GdipDeletePathSafe(nativePath_);
      nativePath_ = Handle.init;
    }
  }

  /**
   */
  void reset() {
    Status status = GdipResetPath(nativePath_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void startFigure() {
    Status status = GdipStartPathFigure(nativePath_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void closeFigure() {
    Status status = GdipClosePathFigure(nativePath_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void closeAllFigures() {
    Status status = GdipClosePathFigures(nativePath_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void setMarkers() {
    Status status = GdipSetPathMarker(nativePath_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void clearMarkers() {
    Status status = GdipClearPathMarkers(nativePath_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void reverse() {
    Status status = GdipReversePath(nativePath_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  PointF getLastPoint() {
    PointF lastPoint;
    Status status = GdipGetPathLastPoint(nativePath_, lastPoint);
    if (status != Status.OK)
      throw statusException(status);
    return lastPoint;
  }

  /**
   */
  void addLine(PointF pt1, PointF pt2) {
    addLine(pt1.x, pt1.y, pt2.x, pt2.y);
  }

  /**
   */
  void addLine(float x1, float y1, float x2, float y2) {
    Status status = GdipAddPathLine(nativePath_, x1, y1, x2, y2);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addLines(PointF[] points) {
    Status status = GdipAddPathLine2(nativePath_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addLine(Point pt1, Point pt2) {
    addLine(pt1.x, pt1.y, pt2.x, pt2.y);
  }

  /**
   */
  void addLine(int x1, int y1, int x2, int y2) {
    Status status = GdipAddPathLineI(nativePath_, x1, y1, x2, y2);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addLines(Point[] points) {
    Status status = GdipAddPathLine2I(nativePath_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addArc(RectF rect, float startAngle, float sweepAngle) {
    addArc(rect.x, rect.y, rect.width, rect.height, startAngle, sweepAngle);
  }

  /**
   */
  void addArc(float x, float y, float width, float height, float startAngle, float sweepAngle) {
    Status status = GdipAddPathArc(nativePath_, x, y, width, height, startAngle, sweepAngle);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addArc(Rect rect, float startAngle, float sweepAngle) {
    addArc(rect.x, rect.y, rect.width, rect.height, startAngle, sweepAngle);
  }

  /**
   */
  void addArc(int x, int y, int width, int height, float startAngle, float sweepAngle) {
    Status status = GdipAddPathArcI(nativePath_, x, y, width, height, startAngle, sweepAngle);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addBezier(PointF pt1, PointF pt2, PointF pt3, PointF pt4) {
    addBezier(pt1.x, pt1.y, pt2.x, pt2.y, pt3.x, pt3.y, pt4.x, pt4.y);
  }

  /**
   */
  void addBezier(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) {
    Status status = GdipAddPathBezier(nativePath_, x2, y1, x2, y2, x3, y3, x4, y4);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addBeziers(PointF[] points) {
    Status status = GdipAddPathBeziers(nativePath_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addBezier(Point pt1, Point pt2, Point pt3, Point pt4) {
    addBezier(pt1.x, pt1.y, pt2.x, pt2.y, pt3.x, pt3.y, pt4.x, pt4.y);
  }

  /**
   */
  void addBezier(int x1, int y1, int x2, int y2, int x3, int y3, int x4, int y4) {
    Status status = GdipAddPathBezierI(nativePath_, x2, y1, x2, y2, x3, y3, x4, y4);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addBeziers(Point[] points) {
    Status status = GdipAddPathBeziersI(nativePath_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addCurve(PointF[] points) {
    Status status = GdipAddPathCurve(nativePath_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addCurve(PointF[] points, float tension) {
    Status status = GdipAddPathCurve2(nativePath_, points.ptr, points.length, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addCurve(PointF[] points, int offset, int numberOfSegments, float tension) {
    Status status = GdipAddPathCurve3(nativePath_, points.ptr, points.length, offset, numberOfSegments, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addCurve(Point[] points) {
    Status status = GdipAddPathCurveI(nativePath_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addCurve(Point[] points, float tension) {
    Status status = GdipAddPathCurve2I(nativePath_, points.ptr, points.length, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addCurve(Point[] points, int offset, int numberOfSegments, float tension) {
    Status status = GdipAddPathCurve3I(nativePath_, points.ptr, points.length, offset, numberOfSegments, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addClosedCurve(PointF[] points) {
    Status status = GdipAddPathClosedCurve(nativePath_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addClosedCurve(PointF[] points, float tension) {
    Status status = GdipAddPathClosedCurve2(nativePath_, points.ptr, points.length, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addClosedCurve(Point[] points) {
    Status status = GdipAddPathClosedCurveI(nativePath_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addClosedCurve(Point[] points, float tension) {
    Status status = GdipAddPathClosedCurve2I(nativePath_, points.ptr, points.length, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addRectangle(RectF rect) {
    Status status = GdipAddPathRectangle(nativePath_, rect.x, rect.y, rect.width, rect.height);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addRectangles(RectF[] rects) {
    Status status = GdipAddPathRectangles(nativePath_, rects.ptr, rects.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addRectangle(Rect rect) {
    Status status = GdipAddPathRectangleI(nativePath_, rect.x, rect.y, rect.width, rect.height);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addRectangles(Rect[] rects) {
    Status status = GdipAddPathRectanglesI(nativePath_, rects.ptr, rects.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addEllipse(RectF rect) {
    addEllipse(rect.x, rect.y, rect.width, rect.height);
  }

  /**
   */
  void addEllipse(float x, float y, float width, float height) {
    Status status = GdipAddPathEllipse(nativePath_, x, y, width, height);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addEllipse(Rect rect) {
    addEllipse(rect.x, rect.y, rect.width, rect.height);
  }

  /**
   */
  void addEllipse(int x, int y, int width, int height) {
    Status status = GdipAddPathEllipseI(nativePath_, x, y, width, height);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addPie(RectF rect, float startAngle, float sweepAngle) {
    addPie(rect.x, rect.y, rect.width, rect.height, startAngle, sweepAngle);
  }

  /**
   */
  void addPie(float x, float y, float width, float height, float startAngle, float sweepAngle) {
    Status status = GdipAddPathPie(nativePath_, x, y, width, height, startAngle, sweepAngle);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addPie(Rect rect, float startAngle, float sweepAngle) {
    addPie(rect.x, rect.y, rect.width, rect.height, startAngle, sweepAngle);
  }

  /**
   */
  void addPie(int x, int y, int width, int height, float startAngle, float sweepAngle) {
    Status status = GdipAddPathPieI(nativePath_, x, y, width, height, startAngle, sweepAngle);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addPolygon(PointF[] points) {
    Status status = GdipAddPathPolygon(nativePath_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addPolygon(Point[] points) {
    Status status = GdipAddPathPolygonI(nativePath_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addPath(Path addingPath, bool connect) {
    if (addingPath is null)
      throw new ArgumentNullException("addingPath");

    Status status = GdipAddPathPath(nativePath_, addingPath.nativePath_, (connect ? 1 : 0));
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addString(string s, FontFamily family, FontStyle style, float emSize, PointF origin, StringFormat format) {
    RectF layoutRect = RectF(origin.x, origin.y, 0, 0);
    Status status = GdipAddPathString(nativePath_, s.toUTF16z(), s.length, (family is null ? Handle.init : family.nativeFamily_), style, emSize, layoutRect, (format is null ? Handle.init : format.nativeFormat_));
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addString(string s, FontFamily family, FontStyle style, float emSize, RectF layoutRect, StringFormat format) {
    Status status = GdipAddPathString(nativePath_, s.toUTF16z(), s.length, (family is null ? Handle.init : family.nativeFamily_), style, emSize, layoutRect, (format is null ? Handle.init : format.nativeFormat_));
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addString(string s, FontFamily family, FontStyle style, float emSize, Point origin, StringFormat format) {
    Rect layoutRect = Rect(origin.x, origin.y, 0, 0);
    Status status = GdipAddPathStringI(nativePath_, s.toUTF16z(), s.length, (family is null ? Handle.init : family.nativeFamily_), style, emSize, layoutRect, (format is null ? Handle.init : format.nativeFormat_));
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addString(string s, FontFamily family, FontStyle style, float emSize, Rect layoutRect, StringFormat format) {
    Status status = GdipAddPathStringI(nativePath_, s.toUTF16z(), s.length, (family is null ? Handle.init : family.nativeFamily_), style, emSize, layoutRect, (format is null ? Handle.init : format.nativeFormat_));
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void transform(Matrix matrix) {
    if (matrix is null)
      throw new ArgumentNullException("matrix");

    if (matrix.nativeMatrix != Handle.init) {
      Status status = GdipTransformPath(nativePath_, matrix.nativeMatrix_);
      if (status != Status.OK)
        throw statusException(status);
    }
  }

  /**
   */
  RectF getBounds(Matrix matrix = null, Pen pen = null) {
    Handle nativeMatrix, nativePen;
    if (matrix !is null) nativeMatrix = matrix.nativeMatrix_;
    if (pen !is null) nativePen = pen.nativePen_;

    RectF bounds;
    Status status = GdipGetPathWorldBounds(nativePath_, bounds, nativeMatrix, nativePen);
    if (status != Status.OK)
      throw statusException(status);
    return bounds;
  }

  /**
   */
  void flatten(Matrix matrix = null, float flatness = FlatnessDefault) {
    Status status = GdipFlattenPath(nativePath_, (matrix is null ? Handle.init : matrix.nativeMatrix_), flatness);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void widen(Pen pen, Matrix matrix = null, float flatness = FlatnessDefault) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipWidenPath(nativePath_, pen.nativePen_, (matrix is null ? Handle.init : matrix.nativeMatrix_), flatness);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void outline(Matrix matrix = null, float flatness = FlatnessDefault) {
    Status status = GdipWindingModeOutline(nativePath_, (matrix is null ? Handle.init : matrix.nativeMatrix_), flatness);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void warp(PointF[] destPoints, RectF srcRect, Matrix matrix = null, WarpMode warpMode = WarpMode.Perspective, float flatness = FlatnessDefault) {
    Status status = GdipWarpPath(nativePath_, (matrix is null ? Handle.init : matrix.nativeMatrix_), destPoints.ptr, destPoints.length, srcRect.x, srcRect.y, srcRect.width, srcRect.height, warpMode, flatness);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  bool isVisible(PointF pt, Graphics graphics = null) {
    int result;
    Status status = GdipIsVisiblePathPoint(nativePath_, pt.x, pt.y, (graphics is null ? Handle.init : graphics.nativeGraphics_), result);
    if (status != Status.OK)
      throw statusException(status);
    return result != 0;
  }

  /**
   */
  bool isVisible(float x, float y, Graphics graphics = null) {
    return isVisible(PointF(x, y), graphics);
  }

  /**
   */
  bool isVisible(Point pt, Graphics graphics = null) {
    int result;
    Status status = GdipIsVisiblePathPointI(nativePath_, pt.x, pt.y, (graphics is null ? Handle.init : graphics.nativeGraphics_), result);
    if (status != Status.OK)
      throw statusException(status);
    return result != 0;
  }

  /**
   */
  bool isVisible(int x, int y, Graphics graphics = null) {
    return isVisible(Point(x, y), graphics);
  }

  /**
   */
  bool isOutlineVisible(PointF pt, Pen pen, Graphics graphics = null) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    int result;
    Status status = GdipIsOutlineVisiblePathPoint(nativePath_, pt.x, pt.y, pen.nativePen_, (graphics is null ? Handle.init : graphics.nativeGraphics_), result);
    if (status != Status.OK)
      throw statusException(status);
    return result != 0;
  }

  /**
   */
  bool isOutlineVisible(float x, float y, Pen pen, Graphics graphics = null) {
    return isOutlineVisible(PointF(x, y), pen, graphics);
  }

  /**
   */
  bool isOutlineVisible(Point pt, Pen pen, Graphics graphics = null) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    int result;
    Status status = GdipIsOutlineVisiblePathPointI(nativePath_, pt.x, pt.y, pen.nativePen_, (graphics is null ? Handle.init : graphics.nativeGraphics_), result);
    if (status != Status.OK)
      throw statusException(status);
    return result != 0;
  }

  /**
   */
  bool isOutlineVisible(int x, int y, Pen pen, Graphics graphics = null) {
    return isOutlineVisible(Point(x, y), pen, graphics);
  }

  /**
   */
  void fillMode(FillMode value) {
    Status status = GdipSetPathFillMode(nativePath_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  FillMode fillMode() {
    FillMode value;
    Status status = GdipGetPathFillMode(nativePath_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  int pointCount() {
    int value;
    Status status = GdipGetPointCount(nativePath_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  ubyte[] pathTypes() {  
    int count = pointCount;
    ubyte[] types = new ubyte[count];
    Status status = GdipGetPathTypes(nativePath_, types.ptr, count);
    if (status != Status.OK)
      throw statusException(status);
    return types;
  }

  /**
   * ditto
   */
  PointF[] pathPoints() {
    int count = pointCount;
    PointF[] points = new PointF[count];
    Status status = GdipGetPathPoints(nativePath_, points.ptr, count);
    if (status != Status.OK)
      throw statusException(status);
    return points;
  }

}

/**
 */
final class PathIterator {

  private Handle nativeIter_;

  /**
   */
  this(Path path) {
    Status status = GdipCreatePathIter(nativeIter_, (path is null ? Handle.init : path.nativePath_));
    if (status != Status.OK)
      throw statusException(status);
  }

  ~this() {
    dispose();
  }

  /**
   */
  void dispose() {
    if (nativeIter_ != Handle.init) {
      GdipDeletePathIterSafe(nativeIter_);
      nativeIter_ = Handle.init;
    }
  }

  /**
   */
  int nextSubpath(out int startIndex, out int endIndex, out bool isClosed) {
    int resultCount, closed;
    Status status = GdipPathIterNextSubpath(nativeIter_, resultCount, startIndex, endIndex, closed);
    if (status != Status.OK)
      throw statusException(status);
    isClosed = (closed != 0);
    return resultCount;
  }

  /**
   */
  int nextSubpath(Path path, out bool isClosed) {
    int resultCount, closed;
    Status status = GdipPathIterNextSubpathPath(nativeIter_, resultCount, (path is null ? Handle.init : path.nativePath_), closed);
    if (status != Status.OK)
      throw statusException(status);
    isClosed = (closed != 0);
    return resultCount;
  }

  /**
   */
  int nextPathType(out ubyte pathType, out int startIndex, out int endIndex) {
    int resultCount;
    Status status = GdipPathIterNextPathType(nativeIter_, resultCount, pathType, startIndex, endIndex);
    if (status != Status.OK)
      throw statusException(status);
    return resultCount;
  }

  /**
   */
  int nextMarker(out int startIndex, out int endIndex) {
    int resultCount;
    Status status = GdipPathIterNextMarker(nativeIter_, resultCount, startIndex, endIndex);
    if (status != Status.OK)
      throw statusException(status);
    return resultCount;
  }

  /**
   */
  int nextMarker(Path path) {
    int resultCount;
    Status status = GdipPathIterNextMarkerPath(nativeIter_, resultCount, (path is null ? Handle.init : path.nativePath_));
    if (status != Status.OK)
      throw statusException(status);
    return resultCount;
  }

  /**
   */
  void rewind() {
    Status status = GdipPathIterRewind(nativeIter_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  int enumerate(ref PointF[] points, ref ubyte[] types) {
    if (points.length != types.length)
      throw statusException(Status.InvalidParameter);

    int resultCount;
    Status status = GdipPathIterEnumerate(nativeIter_, resultCount, points.ptr, types.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
    return resultCount;
  }

  /**
   */
  int copyData(ref PointF[] points, ref ubyte[] types, int startIndex, int endIndex) {
    if (points.length != types.length)
      throw statusException(Status.InvalidParameter);

    int resultCount;
    Status status = GdipPathIterCopyData(nativeIter_, resultCount, points.ptr, types.ptr, startIndex, endIndex);
    if (status != Status.OK)
      throw statusException(status);
    return resultCount;
  }

  /**
   */
  int count() {
    int result;
    Status status = GdipPathIterGetCount(nativeIter_, result);
    if (status != Status.OK)
      throw statusException(status);
    return result;
  }

  /**
   */
  int subpathCount() {
    int result;
    Status status = GdipPathIterGetSubpathCount(nativeIter_, result);
    if (status != Status.OK)
      throw statusException(status);
    return result;
  }

  /**
   */
  bool hasCurve() {
    int result;
    Status status = GdipPathIterHasCurve(nativeIter_, result);
    if (status != Status.OK)
      throw statusException(status);
    return result != 0;
  }

}

/**
 */
final class Region {

  private Handle nativeRegion_;

  /**
   */
  this() {
    Status status = GdipCreateRegion(nativeRegion_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(RectF rect) {
    Status status = GdipCreateRegionRect(rect, nativeRegion_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(Rect rect) {
    Status status = GdipCreateRegionRectI(rect, nativeRegion_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(Path path) {
    if (path is null)
      throw new ArgumentNullException("path");

    Status status = GdipCreateRegionPath(path.nativePath_, nativeRegion_);
    if (status != Status.OK)
      throw statusException(status);
  }

  ~this() {
    dispose();
  }

  /**
   */
  void dispose() {
    if (nativeRegion_ != Handle.init) {
      GdipDeleteRegionSafe(nativeRegion_);
      nativeRegion_ = Handle.init;
    }
  }

  /**
   */
  static Region fromHrgn(Handle hrgn) {
    Handle region;
    Status status = GdipCreateRegionHrgn(hrgn, region);
    if (status != Status.OK)
      throw statusException(status);
    return new Region(region);
  }

  /**
   */
  void makeInfinite() {
    Status status = GdipSetInfinite(nativeRegion_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void makeEmpty() {
    Status status = GdipSetEmpty(nativeRegion_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void intersect(RectF rect) {
    Status status = GdipCombineRegionRect(nativeRegion_, rect, CombineMode.Intersect);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void intersect(Rect rect) {
    Status status = GdipCombineRegionRectI(nativeRegion_, rect, CombineMode.Intersect);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void intersect(Path path) {
    if (path is null)
      throw new ArgumentNullException("path");

    Status status = GdipCombineRegionPath(nativeRegion_, path.nativePath_, CombineMode.Intersect);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void intersect(Region region) {
    if (region is null)
      throw new ArgumentNullException("region");

    Status status = GdipCombineRegionRegion(nativeRegion_, region.nativeRegion_, CombineMode.Intersect);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void unionWith(RectF rect) {
    Status status = GdipCombineRegionRect(nativeRegion_, rect, CombineMode.Union);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void unionWith(Rect rect) {
    Status status = GdipCombineRegionRectI(nativeRegion_, rect, CombineMode.Union);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void unionWith(Path path) {
    if (path is null)
      throw new ArgumentNullException("path");

    Status status = GdipCombineRegionPath(nativeRegion_, path.nativePath_, CombineMode.Union);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void unionWith(Region region) {
    if (region is null)
      throw new ArgumentNullException("region");

    Status status = GdipCombineRegionRegion(nativeRegion_, region.nativeRegion_, CombineMode.Union);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void xor(RectF rect) {
    Status status = GdipCombineRegionRect(nativeRegion_, rect, CombineMode.Xor);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void xor(Rect rect) {
    Status status = GdipCombineRegionRectI(nativeRegion_, rect, CombineMode.Xor);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void xor(Path path) {
    if (path is null)
      throw new ArgumentNullException("path");

    Status status = GdipCombineRegionPath(nativeRegion_, path.nativePath_, CombineMode.Xor);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void xor(Region region) {
    if (region is null)
      throw new ArgumentNullException("region");

    Status status = GdipCombineRegionRegion(nativeRegion_, region.nativeRegion_, CombineMode.Xor);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void exclude(RectF rect) {
    Status status = GdipCombineRegionRect(nativeRegion_, rect, CombineMode.Exclude);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void exclude(Rect rect) {
    Status status = GdipCombineRegionRectI(nativeRegion_, rect, CombineMode.Exclude);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void exclude(Path path) {
    if (path is null)
      throw new ArgumentNullException("path");

    Status status = GdipCombineRegionPath(nativeRegion_, path.nativePath_, CombineMode.Exclude);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void exclude(Region region) {
    if (region is null)
      throw new ArgumentNullException("region");

    Status status = GdipCombineRegionRegion(nativeRegion_, region.nativeRegion_, CombineMode.Exclude);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void complement(RectF rect) {
    Status status = GdipCombineRegionRect(nativeRegion_, rect, CombineMode.Complement);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void complement(Rect rect) {
    Status status = GdipCombineRegionRectI(nativeRegion_, rect, CombineMode.Complement);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void complement(Path path) {
    if (path is null)
      throw new ArgumentNullException("path");

    Status status = GdipCombineRegionPath(nativeRegion_, path.nativePath_, CombineMode.Complement);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void complement(Region region) {
    if (region is null)
      throw new ArgumentNullException("region");

    Status status = GdipCombineRegionRegion(nativeRegion_, region.nativeRegion_, CombineMode.Complement);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void translate(float dx, float dy) {
    Status status = GdipTranslateRegion(nativeRegion_, dx, dy);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void translate(int dx, int dy) {
    Status status = GdipTranslateRegionI(nativeRegion_, dx, dy);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void transform(Matrix matrix) {
    if (matrix is null)
      throw new ArgumentNullException("matrix");

    Status status = GdipTransformRegion(nativeRegion_, matrix.nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  RectF getBounds(Graphics g) {
    if (g is null)
      throw new ArgumentNullException("g");

    RectF rect;
    Status status = GdipGetRegionBounds(nativeRegion_, g.nativeGraphics_, rect);
    if (status != Status.OK)
      throw statusException(status);
    return rect;
  }

  /**
   */
  Handle getHrgn(Graphics g) {
    if (g is null)
      throw new ArgumentNullException("g");

    Handle hrgn;
    Status status = GdipGetRegionHRgn(nativeRegion_, g.nativeGraphics_, hrgn);
    if (status != Status.OK)
      throw statusException(status);
    return hrgn;
  }

  /**
   */
  bool isEmpty(Graphics g) {
    if (g is null)
      throw new ArgumentNullException("g");

    int result;
    Status status = GdipIsEmptyRegion(nativeRegion_, g.nativeGraphics_, result);
    if (status != Status.OK)
      throw statusException(status);
    return result != 0;
  }

  /**
   */
  bool isInfinite(Graphics g) {
    if (g is null)
      throw new ArgumentNullException("g");

    int result;
    Status status = GdipIsInfiniteRegion(nativeRegion_, g.nativeGraphics_, result);
    if (status != Status.OK)
      throw statusException(status);
    return result != 0;
  }

  /**
   */
  bool equals(Region region, Graphics g) {
    if (g is null)
      throw new ArgumentNullException("g");
    if (region is null)
      throw new ArgumentNullException("region");

    int result;
    Status status = GdipIsEqualRegion(nativeRegion_, region.nativeRegion_, g.nativeGraphics_, result);
    if (status != Status.OK)
      throw statusException(status);
    return result != 0;
  }

  /**
   */
  bool isVisible(PointF point, Graphics g = null) {
    int result;
    Status status = GdipIsVisibleRegionPoint(nativeRegion_, point.x, point.y, (g is null ? Handle.init : g.nativeGraphics_), result);
    if (status != Status.OK)
      throw statusException(status);
    return result != 0;
  }

  /**
   */
  bool isVisible(float x, float y, Graphics g = null) {
    return isVisible(PointF(x, y), g);
  }

  /**
   */
  bool isVisible(RectF rect, Graphics g = null) {
    int result;
    Status status = GdipIsVisibleRegionRect(nativeRegion_, rect.x, rect.y, rect.width, rect.height, (g is null ? Handle.init : g.nativeGraphics_), result);
    if (status != Status.OK)
      throw statusException(status);
    return result != 0;
  }

  /**
   */
  bool isVisible(float x, float y, float width, float height, Graphics g = null) {
    return isVisible(RectF(x, y, width, height), g);
  }

  /**
   */
  bool isVisible(Point point, Graphics g = null) {
    int result;
    Status status = GdipIsVisibleRegionPointI(nativeRegion_, point.x, point.y, (g is null ? Handle.init : g.nativeGraphics_), result);
    if (status != Status.OK)
      throw statusException(status);
    return result != 0;
  }

  /**
   */
  bool isVisible(int x, int y, Graphics g = null) {
    return isVisible(Point(x, y), g);
  }

  /**
   */
  bool isVisible(Rect rect, Graphics g = null) {
    int result;
    Status status = GdipIsVisibleRegionRectI(nativeRegion_, rect.x, rect.y, rect.width, rect.height, (g is null ? Handle.init : g.nativeGraphics_), result);
    if (status != Status.OK)
      throw statusException(status);
    return result != 0;
  }

  /**
   */
  bool isVisible(int x, int y, int width, int height, Graphics g = null) {
    return isVisible(Rect(x, y, width, height), g);
  }

  /**
   */
  RectF[] getRegionScans(Matrix matrix) {
    if (matrix is null)
      throw new ArgumentNullException("matrix");

    int count;
    Status status = GdipGetRegionScansCount(nativeRegion_, count, matrix.nativeMatrix);
    if (status != Status.OK)
      throw statusException(status);

    RectF[] rects = new RectF[count];

    status = GdipGetRegionScans(nativeRegion_, rects.ptr, count, matrix.nativeMatrix);
    if (status != Status.OK)
      throw statusException(status);

    return rects[0 .. count];
  }

  private this(Handle nativeRegion) {
    nativeRegion_ = nativeRegion;
  }

}

/**
 */
abstract class FontCollection {

  private Handle nativeCollection_;

  ~this() {
    dispose(false);
  }

  /**
   */
  final void dispose() {
    dispose(true);
  }

  /**
   */
  final FontFamily[] families() {
    int sought, found;
    Status status = GdipGetFontCollectionFamilyCount(nativeCollection_, sought);
    if (status != Status.OK)
      throw statusException(status);

    Handle[] gpfamilies = new Handle[sought];
    status = GdipGetFontCollectionFamilyList(nativeCollection_, sought, gpfamilies.ptr, found);
    if (status != Status.OK)
      throw statusException(status);

    FontFamily[] ret = new FontFamily[found];
    for (int i = 0; i < found; i++) {
      Handle family;
      GdipCloneFontFamily(gpfamilies[i], family);
      ret[i] = new FontFamily(family);
    }
    return ret;
  }

  /**
   */
  protected this() {
  }

  /**
   */
  protected void dispose(bool disposing) {
  }

}

/**
 */
final class InstalledFontCollection : FontCollection {

  /**
   */
  this() {
    Status status = GdipNewInstalledFontCollection(nativeCollection_);
    if (status != Status.OK)
      throw statusException(status);
  }

  alias FontCollection.dispose dispose;

  /**
   */
  protected override void dispose(bool disposing) {
    // GDI+ owns the installed font collection.
  }

}

/**
 */
final class PrivateFontCollection : FontCollection {

  /**
   */
  this() {
    Status status = GdipNewPrivateFontCollection(nativeCollection_);
    if (status != Status.OK)
      throw statusException(status);
  }

  alias FontCollection.dispose dispose;

  /**
   */
  void addFontFile(string fileName) {
    Status status = GdipPrivateAddFontFile(nativeCollection_, fileName.toUTF16z());
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addMemoryFont(void* memory, int length) {
    Status status = GdipPrivateAddMemoryFont(nativeCollection_, memory, length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  protected override void dispose(bool disposing) {
    if (nativeCollection_ != Handle.init) {
      GdipDeletePrivateFontCollectionSafe(nativeCollection_);
      nativeCollection_ = Handle.init;
    }
  }

}

final class FontFamily {

  private Handle nativeFamily_;

  /**
   */
  this(GenericFontFamilies genericFamily) {
    Status status;

    if (genericFamily == GenericFontFamilies.Serif)
      status = GdipGetGenericFontFamilySerif(nativeFamily_);
    else if (genericFamily == GenericFontFamilies.SansSerif)
      status = GdipGetGenericFontFamilySansSerif(nativeFamily_);
    else if (genericFamily == GenericFontFamilies.Monospace)
      status = GdipGetGenericFontFamilyMonospace(nativeFamily_);
    
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(string name, FontCollection fontCollection = null) {
    Status status = GdipCreateFontFamilyFromName(name.toUTF16z(), (fontCollection is null ? Handle.init : fontCollection.nativeCollection_), nativeFamily_);
    if (status != Status.OK) {
      if (status == Status.FontFamilyNotFound)
        throw new ArgumentException("Font '" ~ name ~ "' cannot be found.");
      if (status == Status.NotTrueTypeFont)
        throw new ArgumentException("Only true type fonts are supported. '" ~ name ~ "' is not a true type font.");

      throw statusException(status);
    }
  }

  ~this() {
    dispose();
  }

  /**
   */
  void dispose() {
    if (nativeFamily_ != Handle.init) {
      GdipDeleteFontFamilySafe(nativeFamily_);
      nativeFamily_ = Handle.init;
    }
  }

  /**
   */
  bool isStyleAvailable(FontStyle style) {
    int result;
    Status status = GdipIsStyleAvailable(nativeFamily_, style, result);
    if (status != Status.OK)
      throw statusException(status);
    return result == 1;
  }

  /**
   */
  short getEmHeight(FontStyle style) {
    short emHeight;
    Status status = GdipGetEmHeight(nativeFamily_, style, emHeight);
    if (status != Status.OK)
      throw statusException(status);
    return emHeight;
  }

  /**
   */
  short getCellAscent(FontStyle style) {
    short cellAcscent;
    Status status = GdipGetCellAscent(nativeFamily_, style, cellAcscent);
    if (status != Status.OK)
      throw statusException(status);
    return cellAcscent;
  }

  /**
   */
  short getCellDescent(FontStyle style) {
    short cellDescent;
    Status status = GdipGetCellDescent(nativeFamily_, style, cellDescent);
    if (status != Status.OK)
      throw statusException(status);
    return cellDescent;
  }

  /**
   */
  short getLineSpacing(FontStyle style) {
    short lineSpacing;
    Status status = GdipGetLineSpacing(nativeFamily_, style, lineSpacing);
    if (status != Status.OK)
      throw statusException(status);
    return lineSpacing;
  }

  /**
   */
  string getName(uint language) {
    wchar[32] buffer;
    Status status = GdipGetFamilyName(nativeFamily_, buffer.ptr, language);
    return .toUTF8(buffer);
  }

  /**
   */
  string name() {
    return getName(GetUserDefaultLangID());
  }

  /**
   */
  static FontFamily genericSerif() {
    return new FontFamily(GenericFontFamilies.Serif);
  }

  /**
   */
  static FontFamily genericSansSerif() {
    return new FontFamily(GenericFontFamilies.SansSerif);
  }

  /**
   */
  static FontFamily genericMonospace() {
    return new FontFamily(GenericFontFamilies.Monospace);
  }

  private this(Handle nativeFamily) {
    nativeFamily_ = nativeFamily;
  }

}

/**
 */
final class Font {

  private Handle nativeFont_;
  private FontFamily fontFamily_;
  private float size_;
  private FontStyle style_;
  private GraphicsUnit unit_;

  /**
   */
  this(string familyName, float emSize, GraphicsUnit unit) {
    this(familyName, emSize, FontStyle.Regular, unit);
  }

  /**
   */
  this(FontFamily family, float emSize, GraphicsUnit unit) {
    this(family, emSize, FontStyle.Regular, unit);
  }

  /**
   */
  this(string familyName, float emSize, FontStyle style = FontStyle.Regular, GraphicsUnit unit = GraphicsUnit.Point) {
    fontFamily_ = new FontFamily(familyName);
    this(fontFamily_, emSize, style, unit);
  }

  /**
   */
  this(FontFamily family, float emSize, FontStyle style = FontStyle.Regular, GraphicsUnit unit = GraphicsUnit.Point) {
    if (fontFamily_ is null)
      fontFamily_ = new FontFamily(family.nativeFamily_);
    size_ = emSize;
    style_ = style;
    unit_ = unit;

    Status status = GdipCreateFont(fontFamily_.nativeFamily_, size_, style_, unit_, nativeFont_);
    if (status != Status.OK)
      throw statusException(status);

    status = GdipGetFontSize(nativeFont_, size_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(Font prototype, FontStyle style) {
    this(prototype.fontFamily, prototype.size, style, prototype.unit);
  }

  ~this() {
    dispose();
  }
  /**
   */
  void dispose() {
    if (nativeFont_ != Handle.init) {
      GdipDeleteFontSafe(nativeFont_);
      nativeFont_ = Handle.init;
    }
    fontFamily_ = null;
  }

  /**
   */
  static Font fromHdc(Handle hdc) {
    Handle font;
    Status status = GdipCreateFontFromDC(hdc, font);
    if (status != Status.OK)
      throw statusException(status);
    return new Font(font);
  }

  /**
   */
  static Font fromHfont(Handle hfont) {
    LOGFONT lf;
    GetObject(hfont, LOGFONT.sizeof, &lf);

    Handle hdc = GetDC(Handle.init);
    scope(exit) ReleaseDC(Handle.init, hdc);
    return fromLogFont(lf, hdc);
  }

  /**
   */
  static Font fromLogFont(ref LOGFONT logFont) {
    Handle hdc = GetDC(Handle.init);
    scope(exit) ReleaseDC(Handle.init, hdc);
    return fromLogFont(logFont, hdc);
  }

  /**
   */
  static Font fromLogFont(ref LOGFONT logFont, Handle hdc) {
    Handle nativeFont;
    Status status = GdipCreateFontFromLogfontW(hdc, logFont, nativeFont);
    if (status != Status.OK)
      throw statusException(status);
    return new Font(nativeFont);
  }

  /**
   */
  Handle toHfont() {
    LOGFONT lf;
    toLogFont(lf);
    return CreateFontIndirect(lf);
  }

  /**
   */
  void toLogFont(out LOGFONT logFont) {
    Handle hdc = GetDC(Handle.init);
    try {
      scope g = Graphics.fromHdc(hdc);
      toLogFont(logFont, g);
    }
    finally {
      ReleaseDC(Handle.init, hdc);
    }
  }

  /**
   */
  void toLogFont(out LOGFONT logFont, Graphics graphics) {
    Status status = GdipGetLogFontW(nativeFont_, graphics.nativeGraphics_, logFont);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  float getHeight() {
    Handle hdc = GetDC(Handle.init);
    try {
      scope g = Graphics.fromHdc(hdc);
      return getHeight(g);
    }
    finally {
      ReleaseDC(Handle.init, hdc);
    }
  }

  /**
   */
  float getHeight(Graphics graphics) {
    if (graphics is null)
      throw new ArgumentNullException("graphics");

    float value = 0f;
    Status status = GdipGetFontHeight(nativeFont_, graphics.nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  int height() {
    return cast(int)ceil(getHeight());
  }

  /**
   */
  float size() {
    return size_;
  }

  /**
   */
  FontStyle style() {
    return style_;
  }

  /**
   */
  GraphicsUnit unit() {
    return unit_;
  }

  /**
   */
  FontFamily fontFamily() {
    return fontFamily_;
  }

  /**
   */
  string name() {
    return fontFamily_.name;
  }

  private this(Handle nativeFont) {
    nativeFont_ = nativeFont;

    Status status = GdipGetFontSize(nativeFont, size_);
    if (status != Status.OK)
      throw statusException(status);

    status = GdipGetFontUnit(nativeFont, unit_);
    if (status != Status.OK)
      throw statusException(status);

    status = GdipGetFontSize(nativeFont, size_);
    if (status != Status.OK)
      throw statusException(status);

    Handle nativeFamily;
    status = GdipGetFamily(nativeFont, nativeFamily);
    if (status != Status.OK)
      throw statusException(status);

    fontFamily_ = new FontFamily(nativeFamily);
  }

}

/**
 */
struct CharacterRange {

  /**
   */
  int first;

  /**
   */
  int length;

  /**
   */
  static CharacterRange opCall(int first, int length) {
    CharacterRange this_;
    this_.first = first;
    this_.length = length;
    return this_;
  }

  bool opEquals(CharacterRange other) {
    return first == other.first && length == other.length;
  }

}

/**
 */
final class StringFormat {

  private Handle nativeFormat_;

  /**
   */
  this(StringFormatFlags options = cast(StringFormatFlags)0, int language = 0 /*LANG_NEUTRAL*/) {
    Status status = GdipCreateStringFormat(options, language, nativeFormat_);
    if (status != Status.OK)
      throw statusException(status);
  }

  ~this() {
    dispose();
  }

  /**
   */
  void dispose() {
    if (nativeFormat_ != Handle.init) {
      GdipDeleteStringFormatSafe(nativeFormat_);
      nativeFormat_ = Handle.init;
    }
  }

  /**
   */
  void setMeasurableCharacterRanges(CharacterRange[] ranges) {
    Status status = GdipSetStringFormatMeasurableCharacterRanges(nativeFormat_, ranges.length, ranges.ptr);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void formatFlags(StringFormatFlags value) {
    Status status = GdipSetStringFormatFlags(nativeFormat_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  StringFormatFlags formatFlags() {
    StringFormatFlags value = cast(StringFormatFlags)0;
    Status status = GdipGetStringFormatFlags(nativeFormat_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  void alignment(StringAlignment value) {
    Status status = GdipSetStringFormatAlign(nativeFormat_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  StringAlignment alignment() {
    StringAlignment value;
    Status status = GdipGetStringFormatAlign(nativeFormat_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  void lineAlignment(StringAlignment value) {
    Status status = GdipSetStringFormatLineAlign(nativeFormat_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  StringAlignment lineAlignment() {
    StringAlignment value;
    Status status = GdipGetStringFormatLineAlign(nativeFormat_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  void trimming(StringTrimming value) {
    Status status = GdipSetStringFormatTrimming(nativeFormat_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  StringTrimming trimming() {
    StringTrimming value;
    Status status = GdipGetStringFormatTrimming(nativeFormat_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  package Handle nativeFormat() {
    return nativeFormat_;
  }

}
