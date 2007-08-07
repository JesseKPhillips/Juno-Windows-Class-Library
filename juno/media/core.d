/**
 * Provides access to basic graphics functionality.
 */
module juno.media.core;

private import juno.base.core,
  juno.base.string,
  juno.base.math,
  juno.base.collections,
  juno.base.threading,
  juno.base.native,
  juno.io.path,
  juno.locale.core,
  juno.com.core,
  juno.media.geometry,
  juno.media.constants,
  juno.media.imaging,
  juno.media.native;

private import std.stream : Stream, MemoryStream;
private import std.math : ceil;
//private static import std.base64;

/+private int hexToInt(char[] value, int fromBase) {
  if (value.length == 0)
    goto L_ERR;

  uint startIndex;
  if (fromBase == 16 && value.length >= 2 && (value[0 .. 1] == "0x" || value[0 .. 1] == "0X"))
    startIndex = 2;

  int sign, n;

  for (uint i = startIndex; i < value.length; i++) {
    char ch = value[i];
    if (ch >= '0' && ch <= '9') {
      uint n1 = n;
      n = n * fromBase + (ch - '0');
      if (cast(uint)n < n1) goto L_OVERFLOW;
    }
    else if (ch >= 'A' && ch <= 'F') {
      uint n1 = n;
      n = n * fromBase + (ch - 'A' + 10);
      if (cast(uint)n < n1) goto L_OVERFLOW;
    }
    else if (ch >= 'a' && ch <= 'f') {
      uint n1 = n;
      n = n * fromBase + (ch - 'a' + 10);
      if (cast(uint)n < n1) goto L_OVERFLOW;
    }
    else if (fromBase == 10 && ch == '-' && i == 0) {
      sign = -1;
      if (value.length == 1) goto L_ERR;
    }
    else if (fromBase == 10 && ch == '+' && i == 0)  {
      if (value.length == 1) goto L_ERR;
    }
    else
      goto L_ERR;
  }
  if (sign == -1) {
    if (cast(uint)n > 0x80000000)
      goto L_OVERFLOW;
    n = -n;
  }
  else if (cast(uint)n > 0x7FFFFFFF)
    goto L_OVERFLOW;

  return n;

L_OVERFLOW:
  throw new OverflowException;

L_ERR:
  throw new BaseException;
}+/

/**
 * Represents an ARGB color.
 */
public struct Color {

  private static int[] colorTable_;
  private static string[] nameTable_;

  /*private static Color[string] htmlSystemColorTable_;
  private static Color[string] namedColorTable_;
  private static Color[string] namedSystemColorTable_;*/

  private const int STATE_KNOWNCOLOR_VALID = 1;
  private const int STATE_VALUE_VALID = 2;
  private const int STATE_NAME_VALID = 4;

  private const int ARGB_ALPHA_SHIFT = 24;
  private const int ARGB_RED_SHIFT = 16;
  private const int ARGB_GREEN_SHIFT = 8;
  private const int ARGB_BLUE_SHIFT = 0;

  private const int WIN32_RED_SHIFT = 0;
  private const int WIN32_GREEN_SHIFT = 8;
  private const int WIN32_BLUE_SHIFT = 16;

  private long value_;
  private int state_;
  private string name_;
  private short knownColor_;

  /// Represents the color that is _null.
  public static const Color empty = { 0, 0, null, cast(KnownColor)0 };

  /**
   * Creates a new Color structure from a 32-bit ARGB value.
   * Params: argb = A value specifying the 32-bit ARGB value.
   * Returns: The Color structure that this method creates.
   */
  public static Color fromArgb(int argb) {
    return Color(argb & 0xFFFFFFFF, STATE_VALUE_VALID, null, cast(KnownColor)0);
  }

  /**
   * Creates a new Color structure from the specified 8-bit values (_red, _green and _blue).
   * Params:
   *   red = The _red component value for the new Color. Valid values are 0 to 255.
   *   green = The _green component value for the new Color. Valid values are 0 to 255.
   *   blue = The _blue component value for the new Color. Valid values are 0 to 255.
   * Returns: The Color structure that this method creates.
   */
  public static Color fromArgb(ubyte red, ubyte green, ubyte blue) {
    return fromArgb(255, red, green, blue);
  }

  /**
   * Creates a new Color structure from the four ARGB component values (_alpha, _red, _green and _blue).
   * Params:
   *   alpha = The _alpha component for the new Color. Valid values are 0 to 255.
   *   red = The _red component value for the new Color. Valid values are 0 to 255.
   *   green = The _green component value for the new Color. Valid values are 0 to 255.
   *   blue = The _blue component value for the new Color. Valid values are 0 to 255.
   * Returns: The Color structure that this method creates.
   */
  public static Color fromArgb(ubyte alpha, ubyte red, ubyte green, ubyte blue) {
    return Color(makeArgb(alpha, red, green, blue), STATE_VALUE_VALID, null, cast(KnownColor)0);
  }

  /**
   * Creates a new Color structure from the specified Color structure, but with the new specified _alpha value.
   * Params:
   *   alpha = The _alpha component value. Valid values are 0 to 255.
   *   baseColor = The Color from which to create the new Color structure.
   * Returns: The Color structure that this method creates.
   */
  public static Color fromArgb(ubyte alpha, Color baseColor) {
    return Color(makeArgb(alpha, baseColor.r, baseColor.g, baseColor.b), STATE_VALUE_VALID, null, cast(KnownColor)0);
  }

  /**
   * Creates a new Color structure from the specified predefined color.
   * Params: color = An element of the KnownColor enumeration.
   * Returns: The Color structure that this method creates.
   */
  public static Color fromKnownColor(KnownColor color) {
    return Color(color);
  }

  /**
   * Creates a Color structure from the specified _name of a predefined color.
   * Params: name = The _name of a predefined color. Valid names are the same as the names of the KnownColor enumeration.
   * Returns: The Color structure that this method creates.
   */
  public static Color fromName(string name) {
    /*if (namedColorTable_ == null)
      initNamedColorTable();
    if (auto value = name.toLower(Culture.constant) in namedColorTable_)
      return *value;

    if (namedSystemColorTable_ == null)
      initNamedSystemColorTable();
    if (auto value = name.toLower(Culture.constant) in namedSystemColorTable_)
      return *value;*/

    if (nameTable_ == null)
      initNameTable();
    foreach (key, value; nameTable_) {
      if (value.toLower(Culture.constant) == name.toLower(Culture.constant))
        return Color.fromKnownColor(cast(KnownColor)key);
    }

    return Color(0, STATE_NAME_VALID, name, cast(KnownColor)0);
  }

  /+/**
   * Creates a Color structure from the specified HTML color representation.
   * Params: htmlColor = The string representation of the HTML color to create.
   * Returns: The Color structure that this method creates.
   */
  public static Color fromHtml(string htmlColor) {
    Color ret = Color.empty;

    if (htmlColor != null) {
      // #RRGGBB, or #RGB
      if (htmlColor[0] == '#' && (htmlColor.length == 7 || htmlColor.length == 4)) {
        if (htmlColor.length == 7)
          ret = Color.fromArgb(cast(ubyte)hexToInt(htmlColor[1 .. 3], 16), cast(ubyte)hexToInt(htmlColor[3 .. 5], 16), cast(ubyte)hexToInt(htmlColor[5 .. 7], 16));
        else {
          string r = [ htmlColor[1] ];
          string g = [ htmlColor[2] ];
          string b = [ htmlColor[3] ];
          ret = Color.fromArgb(cast(ubyte)hexToInt(r ~ r, 16), cast(ubyte)hexToInt(g ~ g, 16), cast(ubyte)hexToInt(b ~ b, 16));
        }
      }

      if (ret.isEmpty && htmlColor == "LightGrey") // Common spelling alternative
        ret = Color.lightGray;

      if (ret.isEmpty) {
        if (htmlSystemColorTable_ == null)
          initHtmlSystemColorTable();
        if (auto value = htmlColor.toLower(Culture.constant) in htmlSystemColorTable_)
          ret = *value;
      }

      if (ret.isEmpty) {
        if (namedColorTable_ == null)
          initNamedColorTable();

        if (auto value = htmlColor.toLower(Culture.constant) in namedColorTable_)
          ret = *value;
      }

      if (ret.isEmpty) {
        if (namedSystemColorTable_ == null)
          initNamedSystemColorTable();

        if (auto value = htmlColor.toLower(Culture.constant) in namedSystemColorTable_)
          ret = *value;
      }

      if (ret.isEmpty) {
        string separator = Culture.current.listSeparator;

        if (htmlColor.indexOf(separator[0]) == -1) {
          // 0xRRGGBB, 0XRRGGBB, &hRRGGBB, &HRRGGBB
          if ((htmlColor.length == 8 
              && (htmlColor.startsWith("0x") 
                || htmlColor.startsWith("0X") || htmlColor.startsWith("&h") || htmlColor.startsWith("&H")))) {
            ret = Color.fromArgb(0xFF000000 | parse!(int)(htmlColor));
          }
        }

        // "A,R,G,B"
        string[] parts = htmlColor.split(separator[]);
        ubyte[] argb = new ubyte[parts.length];
        for (int i = 0; i < argb.length; i++) {
          argb[i] = parse!(ubyte)(parts[i]);
        }

        if (argb.length == 1)
          ret = Color.fromArgb(argb[0]);
        else if (argb.length == 3)
          ret = Color.fromArgb(argb[0], argb[1], argb[2]);
        else if (argb.length == 4)
          ret = Color.fromArgb(argb[0], argb[1], argb[2], argb[3]);

        if (!ret.isEmpty) {
          // If the colour value matches one of the named colours, return that instead.
          int value = ret.toArgb();
          if (namedColorTable_ == null) initNamedColorTable();
          foreach (color; namedColorTable_.values) {
            if (color.toArgb() == value) {
              ret = color;
              break;
            }
          }
        }

        if (ret.isEmpty)
          throw new ArgumentException("Color '" ~ htmlColor ~ "' is not valid.");
      }
    }

    return ret;
  }+/

  /**
   * Gets the HSB brightness value.
   * Returns: The brightness, which ranges from 0.0 to 1.0, where 0.0 represents black and 1.0 represents white.
   */
  public float getBrightness() {
    ubyte minVal = min(r, min(g, b));
    ubyte maxVal = max(r, max(g, b));
    return cast(float)(minVal + maxVal) / 510;
  }

  /**
   * Gets the HSB saturation value.
   * Returns: The saturation, which ranges from 0.0 to 1.0, where 0.0 is grayscale and 1.0 is the most saturated.
   */
  public float getSaturation() {
    ubyte minVal = min(r, min(g, b));
    ubyte maxVal = max(r, max(g, b));

    if (maxVal == minVal)
      return 0;

    int sum = minVal + maxVal;
    if (sum > 255)
      sum = 510 - sum;
    return cast(float)(maxVal - minVal) / sum;
  }

  /**
   * Gets the HSB hue value.
   * Returns: The hue, in degrees ranging from 0.0 to 360.0, in HSB color space.
   */
  public float getHue() {
    ubyte r = this.r;
    ubyte g = this.g;
    ubyte b = this.b;
    ubyte minVal = min(r, min(g, b));
    ubyte maxVal = max(r, max(g, b));

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
   * Gets the ARGB value.
   * Returns: A 32-bit integer representing the ARGB value.
   */
  public int toArgb() {
    return cast(int)value;
  }

  /**
   * Gets a Windows color value from this Color structure.
   * Returns: The Windows color value.
   */
  public uint toRgb() {
    return cast(uint)((r << WIN32_RED_SHIFT) | (g << WIN32_GREEN_SHIFT) | (b << WIN32_BLUE_SHIFT));
  }

  /**
   * Gets the KnownColor of this Color structure.
   * Returns: An element in the KnownColor enumeration.
   */
  public KnownColor toKnownColor() {
    return cast(KnownColor)knownColor_;
  }

  public bool opEquals(Color other) {
    return other.value_ == value_ && other.state_ == state_ && other.knownColor_ == knownColor_ && other.name_ == name_;
  }

  public hash_t toHash() {
    return cast(int)value_ ^ cast(int)state_ ^ cast(int)knownColor_;
  }

  /**
   * Converts this Color structure to a human-readable string.
   * Returns: A string that is the name if the Color is created from a predefined color; otherwise, a string that consists of the ARGB component names and values.
   */
  public string toString() {
    string s = Color.stringof.trim() ~ " [";
    if ((state_ & STATE_NAME_VALID) != 0 || (state_ & STATE_KNOWNCOLOR_VALID) != 0)
      s ~= name;
    else if ((state_ & STATE_VALUE_VALID) != 0)
      s ~= format("A={0}, R={1}, G={2}, B={3}", a, r, g, b);
    else
      s ~= "Empty";
    s ~= "]";
    return s;
  }

  /**
   * Specifies whether this Color structure is uninitialized.
   */
  public bool isEmpty() {
    return state_ == 0;
  }

  /**
   * Gets the alpha component value.
   */
  public ubyte a() {
    return cast(ubyte)((value >> ARGB_ALPHA_SHIFT) & 255);
  }

  /**
   * Gets the red component value.
   */
  public ubyte r() {
    return cast(ubyte)((value >> ARGB_RED_SHIFT) & 255);
  }

  /**
   * Gets the green component value.
   */
  public ubyte g() {
    return cast(ubyte)((value >> ARGB_GREEN_SHIFT) & 255);
  }

  /**
   * Gets the blue component value.
   */
  public ubyte b() {
    return cast(ubyte)((value >> ARGB_BLUE_SHIFT) & 255);
  }

  /**
   * Gets the _name of this Color structure.
   */
  public string name() {
    if ((state_ & STATE_NAME_VALID) != 0)
      return name_;
    if ((state_ & STATE_KNOWNCOLOR_VALID) == 0)
      return format("{0:x}", value_);
    return knownColorToName(cast(KnownColor)knownColor_);
  }

  /// Gets a system-defined color.
  public static Color transparent() { return Color(KnownColor.Transparent); }
  /// Gets a system-defined color.
  public static Color aliceBlue() { return Color(KnownColor.AliceBlue); }
  /// Gets a system-defined color.
  public static Color antiqueWhite() { return Color(KnownColor.AntiqueWhite); }
  /// Gets a system-defined color.
  public static Color aqua() { return Color(KnownColor.Aqua); }
  /// Gets a system-defined color.
  public static Color aquamarine() { return Color(KnownColor.Aquamarine); }
  /// Gets a system-defined color.
  public static Color azure() { return Color(KnownColor.Azure); }
  /// Gets a system-defined color.
  public static Color beige() { return Color(KnownColor.Beige); }
  /// Gets a system-defined color.
  public static Color bisque() { return Color(KnownColor.Bisque); }
  /// Gets a system-defined color.
  public static Color black() { return Color(KnownColor.Black); }
  /// Gets a system-defined color.
  public static Color blanchedAlmond() { return Color(KnownColor.BlanchedAlmond); }
  /// Gets a system-defined color.
  public static Color blue() { return Color(KnownColor.Blue); }
  /// Gets a system-defined color.
  public static Color blueViolet() { return Color(KnownColor.BlueViolet); }
  /// Gets a system-defined color.
  public static Color brown() { return Color(KnownColor.Brown); }
  /// Gets a system-defined color.
  public static Color burlyWood() { return Color(KnownColor.BurlyWood); }
  /// Gets a system-defined color.
  public static Color cadetBlue() { return Color(KnownColor.CadetBlue); }
  /// Gets a system-defined color.
  public static Color chartreuse() { return Color(KnownColor.Chartreuse); }
  /// Gets a system-defined color.
  public static Color chocolate() { return Color(KnownColor.Chocolate); }
  /// Gets a system-defined color.
  public static Color coral() { return Color(KnownColor.Coral); }
  /// Gets a system-defined color.
  public static Color cornflowerBlue() { return Color(KnownColor.CornflowerBlue); }
  /// Gets a system-defined color.
  public static Color cornsilk() { return Color(KnownColor.Cornsilk); }
  /// Gets a system-defined color.
  public static Color crimson() { return Color(KnownColor.Crimson); }
  /// Gets a system-defined color.
  public static Color cyan() { return Color(KnownColor.Cyan); }
  /// Gets a system-defined color.
  public static Color darkBlue() { return Color(KnownColor.DarkBlue); }
  /// Gets a system-defined color.
  public static Color darkCyan() { return Color(KnownColor.DarkCyan); }
  /// Gets a system-defined color.
  public static Color darkGoldenrod() { return Color(KnownColor.DarkGoldenrod); }
  /// Gets a system-defined color.
  public static Color darkGray() { return Color(KnownColor.DarkGray); }
  /// Gets a system-defined color.
  public static Color darkGreen() { return Color(KnownColor.DarkGreen); }
  /// Gets a system-defined color.
  public static Color darkKhaki() { return Color(KnownColor.DarkKhaki); }
  /// Gets a system-defined color.
  public static Color darkMagenta() { return Color(KnownColor.DarkMagenta); }
  /// Gets a system-defined color.
  public static Color darkOliveGreen() { return Color(KnownColor.DarkOliveGreen); }
  /// Gets a system-defined color.
  public static Color darkOrange() { return Color(KnownColor.DarkOrange); }
  /// Gets a system-defined color.
  public static Color darkOrchid() { return Color(KnownColor.DarkOrchid); }
  /// Gets a system-defined color.
  public static Color darkRed() { return Color(KnownColor.DarkRed); }
  /// Gets a system-defined color.
  public static Color darkSalmon() { return Color(KnownColor.DarkSalmon); }
  /// Gets a system-defined color.
  public static Color darkSeaGreen() { return Color(KnownColor.DarkSeaGreen); }
  /// Gets a system-defined color.
  public static Color darkSlateBlue() { return Color(KnownColor.DarkSlateBlue); }
  /// Gets a system-defined color.
  public static Color darkSlateGray() { return Color(KnownColor.DarkSlateGray); }
  /// Gets a system-defined color.
  public static Color darkTurquoise() { return Color(KnownColor.DarkTurquoise); }
  /// Gets a system-defined color.
  public static Color darkViolet() { return Color(KnownColor.DarkViolet); }
  /// Gets a system-defined color.
  public static Color deepPink() { return Color(KnownColor.DeepPink); }
  /// Gets a system-defined color.
  public static Color deepSkyBlue() { return Color(KnownColor.DeepSkyBlue); }
  /// Gets a system-defined color.
  public static Color dimGray() { return Color(KnownColor.DimGray); }
  /// Gets a system-defined color.
  public static Color dodgerBlue() { return Color(KnownColor.DodgerBlue); }
  /// Gets a system-defined color.
  public static Color firebrick() { return Color(KnownColor.Firebrick); }
  /// Gets a system-defined color.
  public static Color floralWhite() { return Color(KnownColor.FloralWhite); } 
  /// Gets a system-defined color.
  public static Color forestGreen() { return Color(KnownColor.ForestGreen); } 
  /// Gets a system-defined color.
  public static Color fuchsia() { return Color(KnownColor.Fuchsia); } 
  /// Gets a system-defined color.
  public static Color gainsboro() { return Color(KnownColor.Gainsboro); } 
  /// Gets a system-defined color.
  public static Color ghostWhite() { return Color(KnownColor.GhostWhite); } 
  /// Gets a system-defined color.
  public static Color gold() { return Color(KnownColor.Gold); } 
  /// Gets a system-defined color.
  public static Color goldenrod() { return Color(KnownColor.Goldenrod); } 
  /// Gets a system-defined color.
  public static Color gray() { return Color(KnownColor.Gray); } 
  /// Gets a system-defined color.
  public static Color green() { return Color(KnownColor.Green); } 
  /// Gets a system-defined color.
  public static Color greenYellow() { return Color(KnownColor.GreenYellow); } 
  /// Gets a system-defined color.
  public static Color honeydew() { return Color(KnownColor.Honeydew); } 
  /// Gets a system-defined color.
  public static Color hotPink() { return Color(KnownColor.HotPink); } 
  /// Gets a system-defined color.
  public static Color indianRed() { return Color(KnownColor.IndianRed); } 
  /// Gets a system-defined color.
  public static Color indigo() { return Color(KnownColor.Indigo); } 
  /// Gets a system-defined color.
  public static Color ivory() { return Color(KnownColor.Ivory); } 
  /// Gets a system-defined color.
  public static Color khaki() { return Color(KnownColor.Khaki); } 
  /// Gets a system-defined color.
  public static Color lavender() { return Color(KnownColor.Lavender); } 
  /// Gets a system-defined color.
  public static Color lavenderBlush() { return Color(KnownColor.LavenderBlush); } 
  /// Gets a system-defined color.
  public static Color lawnGreen() { return Color(KnownColor.LawnGreen); } 
  /// Gets a system-defined color.
  public static Color lemonChiffon() { return Color(KnownColor.LemonChiffon); } 
  /// Gets a system-defined color.
  public static Color lightBlue() { return Color(KnownColor.LightBlue); } 
  /// Gets a system-defined color.
  public static Color lightCoral() { return Color(KnownColor.LightCoral); } 
  /// Gets a system-defined color.
  public static Color lightCyan() { return Color(KnownColor.LightCyan); } 
  /// Gets a system-defined color.
  public static Color lightGoldenrodYellow() { return Color(KnownColor.LightGoldenrodYellow); } 
  /// Gets a system-defined color.
  public static Color lightGreen() { return Color(KnownColor.LightGreen); } 
  /// Gets a system-defined color.
  public static Color lightGray() { return Color(KnownColor.LightGray); } 
  /// Gets a system-defined color.
  public static Color lightPink() { return Color(KnownColor.LightPink); } 
  /// Gets a system-defined color.
  public static Color lightSalmon() { return Color(KnownColor.LightSalmon); } 
  /// Gets a system-defined color.
  public static Color lightSeaGreen() { return Color(KnownColor.LightSeaGreen); } 
  /// Gets a system-defined color.
  public static Color lightSkyBlue() { return Color(KnownColor.LightSkyBlue); } 
  /// Gets a system-defined color.
  public static Color lightSlateGray() { return Color(KnownColor.LightSlateGray); } 
  /// Gets a system-defined color.
  public static Color lightSteelBlue() { return Color(KnownColor.LightSteelBlue); } 
  /// Gets a system-defined color.
  public static Color lightYellow() { return Color(KnownColor.LightYellow); } 
  /// Gets a system-defined color.
  public static Color lime() { return Color(KnownColor.Lime); } 
  /// Gets a system-defined color.
  public static Color limeGreen() { return Color(KnownColor.LimeGreen); } 
  /// Gets a system-defined color.
  public static Color linen() { return Color(KnownColor.Linen); } 
  /// Gets a system-defined color.
  public static Color magenta() { return Color(KnownColor.Magenta); } 
  /// Gets a system-defined color.
  public static Color maroon() { return Color(KnownColor.Maroon); } 
  /// Gets a system-defined color.
  public static Color mediumAquamarine() { return Color(KnownColor.MediumAquamarine); } 
  /// Gets a system-defined color.
  public static Color mediumBlue() { return Color(KnownColor.MediumBlue); } 
  /// Gets a system-defined color.
  public static Color mediumOrchid() { return Color(KnownColor.MediumOrchid); } 
  /// Gets a system-defined color.
  public static Color mediumPurple() { return Color(KnownColor.MediumPurple); } 
  /// Gets a system-defined color.
  public static Color mediumSeaGreen() { return Color(KnownColor.MediumSeaGreen); } 
  /// Gets a system-defined color.
  public static Color mediumSlateBlue() { return Color(KnownColor.MediumSlateBlue); } 
  /// Gets a system-defined color.
  public static Color mediumSpringGreen() { return Color(KnownColor.MediumSpringGreen); } 
  /// Gets a system-defined color.
  public static Color mediumTurquoise() { return Color(KnownColor.MediumTurquoise); } 
  /// Gets a system-defined color.
  public static Color mediumVioletRed() { return Color(KnownColor.MediumVioletRed); } 
  /// Gets a system-defined color.
  public static Color midnightBlue() { return Color(KnownColor.MidnightBlue); } 
  /// Gets a system-defined color.
  public static Color mintCream() { return Color(KnownColor.MintCream); } 
  /// Gets a system-defined color.
  public static Color mistyRose() { return Color(KnownColor.MistyRose); } 
  /// Gets a system-defined color.
  public static Color moccasin() { return Color(KnownColor.Moccasin); } 
  /// Gets a system-defined color.
  public static Color navajoWhite() { return Color(KnownColor.NavajoWhite); } 
  /// Gets a system-defined color.
  public static Color navy() { return Color(KnownColor.Navy); } 
  /// Gets a system-defined color.
  public static Color oldLace() { return Color(KnownColor.OldLace); } 
  /// Gets a system-defined color.
  public static Color olive() { return Color(KnownColor.Olive); } 
  /// Gets a system-defined color.
  public static Color oliveDrab() { return Color(KnownColor.OliveDrab); } 
  /// Gets a system-defined color.
  public static Color orange() { return Color(KnownColor.Orange); } 
  /// Gets a system-defined color.
  public static Color orangeRed() { return Color(KnownColor.OrangeRed); } 
  /// Gets a system-defined color.
  public static Color orchid() { return Color(KnownColor.Orchid); } 
  /// Gets a system-defined color.
  public static Color paleGoldenrod() { return Color(KnownColor.PaleGoldenrod); } 
  /// Gets a system-defined color.
  public static Color paleGreen() { return Color(KnownColor.PaleGreen); } 
  /// Gets a system-defined color.
  public static Color paleTurquoise() { return Color(KnownColor.PaleTurquoise); } 
  /// Gets a system-defined color.
  public static Color paleVioletRed() { return Color(KnownColor.PaleVioletRed); } 
  /// Gets a system-defined color.
  public static Color papayaWhip() { return Color(KnownColor.PapayaWhip); } 
  /// Gets a system-defined color.
  public static Color peachPuff() { return Color(KnownColor.PeachPuff); } 
  /// Gets a system-defined color.
  public static Color peru() { return Color(KnownColor.Peru); } 
  /// Gets a system-defined color.
  public static Color pink() { return Color(KnownColor.Pink); } 
  /// Gets a system-defined color.
  public static Color plum() { return Color(KnownColor.Plum); } 
  /// Gets a system-defined color.
  public static Color powderBlue() { return Color(KnownColor.PowderBlue); } 
  /// Gets a system-defined color.
  public static Color purple() { return Color(KnownColor.Purple); } 
  /// Gets a system-defined color.
  public static Color red() { return Color(KnownColor.Red); } 
  /// Gets a system-defined color.
  public static Color rosyBrown() { return Color(KnownColor.RosyBrown); } 
  /// Gets a system-defined color.
  public static Color royalBlue() { return Color(KnownColor.RoyalBlue); } 
  /// Gets a system-defined color.
  public static Color saddleBrown() { return Color(KnownColor.SaddleBrown); } 
  /// Gets a system-defined color.
  public static Color salmon() { return Color(KnownColor.Salmon); } 
  /// Gets a system-defined color.
  public static Color sandyBrown() { return Color(KnownColor.SandyBrown); } 
  /// Gets a system-defined color.
  public static Color seaGreen() { return Color(KnownColor.SeaGreen); } 
  /// Gets a system-defined color.
  public static Color seaShell() { return Color(KnownColor.SeaShell); } 
  /// Gets a system-defined color.
  public static Color sienna() { return Color(KnownColor.Sienna); } 
  /// Gets a system-defined color.
  public static Color silver() { return Color(KnownColor.Silver); } 
  /// Gets a system-defined color.
  public static Color skyBlue() { return Color(KnownColor.SkyBlue); } 
  /// Gets a system-defined color.
  public static Color slateBlue() { return Color(KnownColor.SlateBlue); } 
  /// Gets a system-defined color.
  public static Color slateGray() { return Color(KnownColor.SlateGray); } 
  /// Gets a system-defined color.
  public static Color snow() { return Color(KnownColor.Snow); } 
  /// Gets a system-defined color.
  public static Color springGreen() { return Color(KnownColor.SpringGreen); } 
  /// Gets a system-defined color.
  public static Color steelBlue() { return Color(KnownColor.SteelBlue); } 
  /// Gets a system-defined color.
  public static Color tan() { return Color(KnownColor.Tan); } 
  /// Gets a system-defined color.
  public static Color teal() { return Color(KnownColor.Teal); } 
  /// Gets a system-defined color.
  public static Color thistle() { return Color(KnownColor.Thistle); } 
  /// Gets a system-defined color.
  public static Color tomato() { return Color(KnownColor.Tomato); } 
  /// Gets a system-defined color.
  public static Color turquoise() { return Color(KnownColor.Turquoise); } 
  /// Gets a system-defined color.
  public static Color violet() { return Color(KnownColor.Violet); } 
  /// Gets a system-defined color.
  public static Color wheat() { return Color(KnownColor.Wheat); } 
  /// Gets a system-defined color.
  public static Color white() { return Color(KnownColor.White); } 
  /// Gets a system-defined color.
  public static Color whiteSmoke() { return Color(KnownColor.WhiteSmoke); } 
  /// Gets a system-defined color.
  public static Color yellow() { return Color(KnownColor.Yellow); } 
  /// Gets a system-defined color.
  public static Color yellowGreen() { return Color(KnownColor.YellowGreen); } 

  // System colors
  /// Gets a Color structure that is the color of the active window's border.
  public static Color activeBorder() { return Color(KnownColor.ActiveBorder); } 
  /// Gets a Color structure that is the color of the active window's title bar.
  public static Color activeCaption() { return Color(KnownColor.ActiveCaption); } 
  /// Gets a Color structure that is the color of the text in the active window's title bar.
  public static Color activeCaptionText() { return Color(KnownColor.ActiveCaptionText); } 
  /// Gets a Color structure that is the color of the application workspace.
  public static Color appWorkspace() { return Color(KnownColor.AppWorkspace); } 
  /// Gets a Color structure that is the face color of a 3-D element.
  public static Color control() { return Color(KnownColor.Control); } 
  /// Gets a Color structure that is the shadow color of a 3-D element.
  public static Color controlDark() { return Color(KnownColor.ControlDark); } 
  /// Gets a Color structure that is the dark shadow color of a 3-D element.
  public static Color controlDarkDark() { return Color(KnownColor.ControlDarkDark); } 
  /// Gets a Color structure that is the light color of a 3-D element.
  public static Color controlLight() { return Color(KnownColor.ControlLight); } 
  /// Gets a Color structure that is the highlight color of a 3-D element.
  public static Color controlLightLight() { return Color(KnownColor.ControlLightLight); } 
  /// Gets a Color structure that is the color of text int a 3-D element.
  public static Color controlText() { return Color(KnownColor.ControlText); } 
  /// Gets a Color structure that is the color of the _desktop.
  public static Color desktop() { return Color(KnownColor.Desktop); } 
  /// Gets a Color structure that is the color of dimmed text.
  public static Color grayText() { return Color(KnownColor.GrayText); } 
  /// Gets a Color structure that is the color of the background of selected items.
  public static Color highlight() { return Color(KnownColor.Highlight); } 
  /// Gets a Color structure that is the color of the text of selected items.
  public static Color highlightText() { return Color(KnownColor.HighlightText); } 
  /// Gets a Color structure that is the color used to designate a hot-tracked item.
  public static Color hotTrack() { return Color(KnownColor.HotTrack); } 
  /// Gets a Color structure that is the color of an inactive window's border.
  public static Color inactiveBorder() { return Color(KnownColor.InactiveBorder); } 
  /// Gets a Color structure that is the color of an inactive window's title bar.
  public static Color inactiveCaption() { return Color(KnownColor.InactiveCaption); } 
  /// Gets a Color structure that is the color of the text in an inactive window's title bar.
  public static Color inactiveCaptionText() { return Color(KnownColor.InactiveCaptionText); } 
  /// Gets a Color structure that is the color of the backgroud of a tool tip.
  public static Color info() { return Color(KnownColor.Info); } 
  /// Gets a Color structure that is the color of the text of a tool tip.
  public static Color infoText() { return Color(KnownColor.InfoText); } 
  /// Gets a Color structure that is the color of a menu's background.
  public static Color menu() { return Color(KnownColor.Menu); } 
  /// Gets a Color structure that is the color of a menu's text.
  public static Color menuText() { return Color(KnownColor.MenuText); } 
  /// Gets a Color structure that is the color of the background of a scroll bar.
  public static Color scrollBar() { return Color(KnownColor.ScrollBar); } 
  /// Gets a Color structure that is the color of the background in the client area of a _window.
  public static Color window() { return Color(KnownColor.Window); } 
  /// Gets a Color structure that is the color of a window frame.
  public static Color windowFrame() { return Color(KnownColor.WindowFrame); } 
  /// Gets a Color structure that is the color of the text in the client aread of a window.
  public static Color windowText() { return Color(KnownColor.WindowText); } 
  /// Gets a Color structure that is the face color of a 3-D element.
  public static Color buttonFace() { return Color(KnownColor.ButtonFace); } 
  /// Gets a Color structure that is the highlight color of a 3-D element.
  public static Color buttonHighlight() { return Color(KnownColor.ButtonHighlight); } 
  /// Gets a Color structure that is the shadow color of a 3-D element.
  public static Color buttonShadow() { return Color(KnownColor.ButtonShadow); } 
  /// Gets a Color structure that is the lightest color in the color gradient of an active window's title bar.
  public static Color gradientActiveCaption() { return Color(KnownColor.GradientActiveCaption); } 
  /// Gets a Color structure that is the lightest color in the color gradient of an inactive window's title bar.
  public static Color gradientInactiveCaption() { return Color(KnownColor.GradientInactiveCaption); } 
  /// Gets a Color structure that is the color of the background of a menu bar.
  public static Color menuBar() { return Color(KnownColor.MenuBar); } 
  /// Gets a Color structure that is the color used to highlight menu items.
  public static Color menuHighlight() { return Color(KnownColor.MenuHighlight); } 

  private static Color opCall(KnownColor knownColor) {
    Color c;
    c.state_ = STATE_KNOWNCOLOR_VALID;
    c.knownColor_ = cast(short)knownColor;
    return c;
  }

  private static Color opCall(long value, int state, string name, KnownColor knownColor) {
    Color c;
    c.value_ = value;
    c.state_ = state;
    c.name_ = name;
    c.knownColor_ = cast(short)knownColor;
    return c;
  }

  private static long makeArgb(ubyte alpha, ubyte red, ubyte green, ubyte blue) {
    return cast(long)(((red << ARGB_RED_SHIFT) | (green << ARGB_GREEN_SHIFT) | (blue << ARGB_BLUE_SHIFT) | (alpha << ARGB_ALPHA_SHIFT)) & 0xffffffff);
  }

  private long value() {
    if (state_ == STATE_VALUE_VALID)
      return value_;
    if (state_ == STATE_KNOWNCOLOR_VALID)
      return cast(long)knownColorToArgb(cast(KnownColor)knownColor_);
    return 0;
  }

  private static int knownColorToArgb(KnownColor color) {
    if (colorTable_ == null)
      initColorTable();

    if (color <= KnownColor.MenuHighlight)
      return colorTable_[color];
    return 0;
  }

  private static string knownColorToName(KnownColor color) {
    if (nameTable_ == null)
      initNameTable();

    if (color <= KnownColor.MenuHighlight)
      return nameTable_[color];
    return null;
  }

  private static int argbFromSystemColor(int index) {
    return fromRgbValue(GetSysColor(index));
  }

  private static int fromRgbValue(uint value) {
    return encode(255, (value >> WIN32_RED_SHIFT) & 255, (value >> WIN32_GREEN_SHIFT) & 255, (value >> WIN32_BLUE_SHIFT) & 255);
  }

  private static int encode(int alpha, int red, int green, int blue) {
    return (red << ARGB_RED_SHIFT) | (green << ARGB_GREEN_SHIFT) | (blue << ARGB_BLUE_SHIFT) | (alpha << ARGB_ALPHA_SHIFT);
  }

  private static void initColorTable() {
    colorTable_.length = KnownColor.max + 1;

    colorTable_[KnownColor.ActiveBorder] = argbFromSystemColor(COLOR_ACTIVEBORDER);
    colorTable_[KnownColor.ActiveCaption] = argbFromSystemColor(COLOR_ACTIVECAPTION);
    colorTable_[KnownColor.ActiveCaptionText] = argbFromSystemColor(COLOR_CAPTIONTEXT);
    colorTable_[KnownColor.AppWorkspace] = argbFromSystemColor(COLOR_APPWORKSPACE);
    colorTable_[KnownColor.Control] = argbFromSystemColor(COLOR_BTNFACE);
    colorTable_[KnownColor.ControlDark] = argbFromSystemColor(COLOR_BTNSHADOW);
    colorTable_[KnownColor.ControlDarkDark] = argbFromSystemColor(COLOR_3DDKSHADOW);
    colorTable_[KnownColor.ControlLight] = argbFromSystemColor(COLOR_3DLIGHT);
    colorTable_[KnownColor.ControlLightLight] = argbFromSystemColor(COLOR_BTNHIGHLIGHT);
    colorTable_[KnownColor.ControlText] = argbFromSystemColor(COLOR_BTNTEXT);
    colorTable_[KnownColor.Desktop] = argbFromSystemColor(COLOR_BACKGROUND);
    colorTable_[KnownColor.GrayText] = argbFromSystemColor(COLOR_GRAYTEXT);
    colorTable_[KnownColor.Highlight] = argbFromSystemColor(COLOR_HIGHLIGHT);
    colorTable_[KnownColor.HighlightText] = argbFromSystemColor(COLOR_HIGHLIGHTTEXT);
    colorTable_[KnownColor.HotTrack] = argbFromSystemColor(COLOR_HOTLIGHT);
    colorTable_[KnownColor.InactiveBorder] = argbFromSystemColor(COLOR_INACTIVEBORDER);
    colorTable_[KnownColor.InactiveCaption] = argbFromSystemColor(COLOR_INACTIVECAPTION);
    colorTable_[KnownColor.InactiveCaptionText] = argbFromSystemColor(COLOR_INACTIVECAPTIONTEXT);
    colorTable_[KnownColor.Info] = argbFromSystemColor(COLOR_INFOBK);
    colorTable_[KnownColor.InfoText] = argbFromSystemColor(COLOR_INFOTEXT);
    colorTable_[KnownColor.Menu] = argbFromSystemColor(COLOR_MENU);
    colorTable_[KnownColor.MenuText] = argbFromSystemColor(COLOR_MENUTEXT);
    colorTable_[KnownColor.ScrollBar] = argbFromSystemColor(COLOR_SCROLLBAR);
    colorTable_[KnownColor.Window] = argbFromSystemColor(COLOR_WINDOW);
    colorTable_[KnownColor.WindowFrame] = argbFromSystemColor(COLOR_WINDOWFRAME);
    colorTable_[KnownColor.WindowText] = argbFromSystemColor(COLOR_WINDOWTEXT);
    colorTable_[KnownColor.ButtonFace] = argbFromSystemColor(COLOR_BTNFACE);
    colorTable_[KnownColor.ButtonHighlight] = argbFromSystemColor(COLOR_BTNHIGHLIGHT);
    colorTable_[KnownColor.ButtonShadow] = argbFromSystemColor(COLOR_BTNSHADOW);
    colorTable_[KnownColor.GradientActiveCaption] = argbFromSystemColor(COLOR_GRADIENTACTIVECAPTION);
    colorTable_[KnownColor.GradientInactiveCaption] = argbFromSystemColor(COLOR_GRADIENTINACTIVECAPTION);
    colorTable_[KnownColor.MenuBar] = argbFromSystemColor(COLOR_MENUBAR);
    colorTable_[KnownColor.MenuHighlight] = argbFromSystemColor(COLOR_MENUHILIGHT);

    colorTable_[KnownColor.Transparent] = 0x00FFFFFF;
    colorTable_[KnownColor.AliceBlue] = 0xFFF0F8FF;
    colorTable_[KnownColor.AntiqueWhite] = 0xFFFAEBD7;
    colorTable_[KnownColor.Aqua] = 0xFF00FFFF;
    colorTable_[KnownColor.Aquamarine] = 0xFF7FFFD4;
    colorTable_[KnownColor.Azure] = 0xFFF0FFFF;
    colorTable_[KnownColor.Beige] = 0xFFF5F5DC;
    colorTable_[KnownColor.Bisque] = 0xFFFFE4C4;
    colorTable_[KnownColor.Black] = 0xFF000000;
    colorTable_[KnownColor.BlanchedAlmond] = 0xFFFFEBCD;
    colorTable_[KnownColor.Blue] = 0xFF0000FF;
    colorTable_[KnownColor.BlueViolet] = 0xFF8A2BE2;
    colorTable_[KnownColor.Brown] = 0xFFA52A2A;
    colorTable_[KnownColor.BurlyWood] = 0xFFDEB887;
    colorTable_[KnownColor.CadetBlue] = 0xFF5F9EA0;
    colorTable_[KnownColor.Chartreuse] = 0xFF7FFF00;
    colorTable_[KnownColor.Chocolate] = 0xFFD2691E;
    colorTable_[KnownColor.Coral] = 0xFFFF7F50;
    colorTable_[KnownColor.CornflowerBlue] = 0xFF6495ED;
    colorTable_[KnownColor.Cornsilk] = 0xFFFFF8DC;
    colorTable_[KnownColor.Crimson] = 0xFFDC143C;
    colorTable_[KnownColor.Cyan] = 0xFF00FFFF;
    colorTable_[KnownColor.DarkBlue] = 0xFF00008B;
    colorTable_[KnownColor.DarkCyan] = 0xFF008B8B;
    colorTable_[KnownColor.DarkGoldenrod] = 0xFFB8860B;
    colorTable_[KnownColor.DarkGray] = 0xFFA9A9A9;
    colorTable_[KnownColor.DarkGreen] = 0xFF006400;
    colorTable_[KnownColor.DarkKhaki] = 0xFFBDB76B;
    colorTable_[KnownColor.DarkMagenta] = 0xFF8B008B;
    colorTable_[KnownColor.DarkOliveGreen] = 0xFF556B2F;
    colorTable_[KnownColor.DarkOrange] = 0xFFFF8C00;
    colorTable_[KnownColor.DarkOrchid] = 0xFF9932CC;
    colorTable_[KnownColor.DarkRed] = 0xFF8B0000;
    colorTable_[KnownColor.DarkSalmon] = 0xFFE9967A;
    colorTable_[KnownColor.DarkSeaGreen] = 0xFF8FBC8B;
    colorTable_[KnownColor.DarkSlateBlue] = 0xFF483D8B;
    colorTable_[KnownColor.DarkSlateGray] = 0xFF2F4F4F;
    colorTable_[KnownColor.DarkTurquoise] = 0xFF00CED1;
    colorTable_[KnownColor.DarkViolet] = 0xFF9400D3;
    colorTable_[KnownColor.DeepPink] = 0xFFFF1493;
    colorTable_[KnownColor.DeepSkyBlue] = 0xFF00BFFF;
    colorTable_[KnownColor.DimGray] = 0xFF696969;
    colorTable_[KnownColor.DodgerBlue] = 0xFF1E90FF;
    colorTable_[KnownColor.Firebrick] = 0xFFB22222;
    colorTable_[KnownColor.FloralWhite] = 0xFFFFFAF0;
    colorTable_[KnownColor.ForestGreen] = 0xFF228B22;
    colorTable_[KnownColor.Fuchsia] = 0xFFFF00FF;
    colorTable_[KnownColor.Gainsboro] = 0xFFDCDCDC;
    colorTable_[KnownColor.GhostWhite] = 0xFFF8F8FF;
    colorTable_[KnownColor.Gold] = 0xFFFFD700;
    colorTable_[KnownColor.Goldenrod] = 0xFFDAA520;
    colorTable_[KnownColor.Gray] = 0xFF808080;
    colorTable_[KnownColor.Green] = 0xFF008000;
    colorTable_[KnownColor.GreenYellow] = 0xFFADFF2F;
    colorTable_[KnownColor.Honeydew] = 0xFFF0FFF0;
    colorTable_[KnownColor.HotPink] = 0xFFFF69B4;
    colorTable_[KnownColor.IndianRed] = 0xFFCD5C5C;
    colorTable_[KnownColor.Indigo] = 0xFF4B0082;
    colorTable_[KnownColor.Ivory] = 0xFFFFFFF0;
    colorTable_[KnownColor.Khaki] = 0xFFF0E68C;
    colorTable_[KnownColor.Lavender] = 0xFFE6E6FA;
    colorTable_[KnownColor.LavenderBlush] = 0xFFFFF0F5;
    colorTable_[KnownColor.LawnGreen] = 0xFF7CFC00;
    colorTable_[KnownColor.LemonChiffon] = 0xFFFFFACD;
    colorTable_[KnownColor.LightBlue] = 0xFFADD8E6;
    colorTable_[KnownColor.LightCoral] = 0xFFF08080;
    colorTable_[KnownColor.LightCyan] = 0xFFE0FFFF;
    colorTable_[KnownColor.LightGoldenrodYellow] = 0xFFFAFAD2;
    colorTable_[KnownColor.LightGray] = 0xFFD3D3D3;
    colorTable_[KnownColor.LightGreen] = 0xFF90EE90;
    colorTable_[KnownColor.LightPink] = 0xFFFFB6C1;
    colorTable_[KnownColor.LightSalmon] = 0xFFFFA07A;
    colorTable_[KnownColor.LightSeaGreen] = 0xFF20B2AA;
    colorTable_[KnownColor.LightSkyBlue] = 0xFF87CEFA;
    colorTable_[KnownColor.LightSlateGray] = 0xFF778899;
    colorTable_[KnownColor.LightSteelBlue] = 0xFFB0C4DE;
    colorTable_[KnownColor.LightYellow] = 0xFFFFFFE0;
    colorTable_[KnownColor.Lime] = 0xFF00FF00;
    colorTable_[KnownColor.LimeGreen] = 0xFF32CD32;
    colorTable_[KnownColor.Linen] = 0xFFFAF0E6;
    colorTable_[KnownColor.Magenta] = 0xFFFF00FF;
    colorTable_[KnownColor.Maroon] = 0xFF800000;
    colorTable_[KnownColor.MediumAquamarine] = 0xFF66CDAA;
    colorTable_[KnownColor.MediumBlue] = 0xFF0000CD;
    colorTable_[KnownColor.MediumOrchid] = 0xFFBA55D3;
    colorTable_[KnownColor.MediumPurple] = 0xFF9370DB;
    colorTable_[KnownColor.MediumSeaGreen] = 0xFF3CB371;
    colorTable_[KnownColor.MediumSlateBlue] = 0xFF7B68EE;
    colorTable_[KnownColor.MediumSpringGreen] = 0xFF00FA9A;
    colorTable_[KnownColor.MediumTurquoise] = 0xFF48D1CC;
    colorTable_[KnownColor.MediumVioletRed] = 0xFFC71585;
    colorTable_[KnownColor.MidnightBlue] = 0xFF191970;
    colorTable_[KnownColor.MintCream] = 0xFFF5FFFA;
    colorTable_[KnownColor.MistyRose] = 0xFFFFE4E1;
    colorTable_[KnownColor.Moccasin] = 0xFFFFE4B5;
    colorTable_[KnownColor.NavajoWhite] = 0xFFFFDEAD;
    colorTable_[KnownColor.Navy] = 0xFF000080;
    colorTable_[KnownColor.OldLace] = 0xFFFDF5E6;
    colorTable_[KnownColor.Olive] = 0xFF808000;
    colorTable_[KnownColor.OliveDrab] = 0xFF6B8E23;
    colorTable_[KnownColor.Orange] = 0xFFFFA500;
    colorTable_[KnownColor.OrangeRed] = 0xFFFF4500;
    colorTable_[KnownColor.Orchid] = 0xFFDA70D6;
    colorTable_[KnownColor.PaleGoldenrod] = 0xFFEEE8AA;
    colorTable_[KnownColor.PaleGreen] = 0xFF98FB98;
    colorTable_[KnownColor.PaleTurquoise] = 0xFFAFEEEE;
    colorTable_[KnownColor.PaleVioletRed] = 0xFFDB7093;
    colorTable_[KnownColor.PapayaWhip] = 0xFFFFEFD5;
    colorTable_[KnownColor.PeachPuff] = 0xFFFFDAB9;
    colorTable_[KnownColor.Peru] = 0xFFCD853F;
    colorTable_[KnownColor.Pink] = 0xFFFFC0CB;
    colorTable_[KnownColor.Plum] = 0xFFDDA0DD;
    colorTable_[KnownColor.PowderBlue] = 0xFFB0E0E6;
    colorTable_[KnownColor.Purple] = 0xFF800080;
    colorTable_[KnownColor.Red] = 0xFFFF0000;
    colorTable_[KnownColor.RosyBrown] = 0xFFBC8F8F;
    colorTable_[KnownColor.RoyalBlue] = 0xFF4169E1;
    colorTable_[KnownColor.SaddleBrown] = 0xFF8B4513;
    colorTable_[KnownColor.Salmon] = 0xFFFA8072;
    colorTable_[KnownColor.SandyBrown] = 0xFFF4A460;
    colorTable_[KnownColor.SeaGreen] = 0xFF2E8B57;
    colorTable_[KnownColor.SeaShell] = 0xFFFFF5EE;
    colorTable_[KnownColor.Sienna] = 0xFFA0522D;
    colorTable_[KnownColor.Silver] = 0xFFC0C0C0;
    colorTable_[KnownColor.SkyBlue] = 0xFF87CEEB;
    colorTable_[KnownColor.SlateBlue] = 0xFF6A5ACD;
    colorTable_[KnownColor.SlateGray] = 0xFF708090;
    colorTable_[KnownColor.Snow] = 0xFFFFFAFA;
    colorTable_[KnownColor.SpringGreen] = 0xFF00FF7F;
    colorTable_[KnownColor.SteelBlue] = 0xFF4682B4;
    colorTable_[KnownColor.Tan] = 0xFFD2B48C;
    colorTable_[KnownColor.Teal] = 0xFF008080;
    colorTable_[KnownColor.Thistle] = 0xFFD8BFD8;
    colorTable_[KnownColor.Tomato] = 0xFFFF6347;
    colorTable_[KnownColor.Turquoise] = 0xFF40E0D0;
    colorTable_[KnownColor.Violet] = 0xFFEE82EE;
    colorTable_[KnownColor.Wheat] = 0xFFF5DEB3;
    colorTable_[KnownColor.White] = 0xFFFFFFFF;
    colorTable_[KnownColor.WhiteSmoke] = 0xFFF5F5F5;
    colorTable_[KnownColor.Yellow] = 0xFFFFFF00;
    colorTable_[KnownColor.YellowGreen] = 0xFF9ACD32;
  }

  private static void initNameTable() {
    nameTable_.length = KnownColor.max + 1;
    
    nameTable_[KnownColor.ActiveBorder] = "ActiveBorder";
    nameTable_[KnownColor.ActiveCaption] = "ActiveCaption";
    nameTable_[KnownColor.ActiveCaptionText] = "ActiveCaptionText";
    nameTable_[KnownColor.AppWorkspace] = "AppWorkspace";
    nameTable_[KnownColor.ButtonFace] = "ButtonFace";
    nameTable_[KnownColor.ButtonHighlight] = "ButtonHighlight";
    nameTable_[KnownColor.ButtonShadow] = "ButtonShadow";
    nameTable_[KnownColor.Control] = "Control";
    nameTable_[KnownColor.ControlDark] = "ControlDark";
    nameTable_[KnownColor.ControlDarkDark] = "ControlDarkDark";
    nameTable_[KnownColor.ControlLight] = "ControlLight";
    nameTable_[KnownColor.ControlLightLight] = "ControlLightLight";
    nameTable_[KnownColor.ControlText] = "ControlText";
    nameTable_[KnownColor.Desktop] = "Desktop";
    nameTable_[KnownColor.GradientActiveCaption] = "GradientActiveCaption";
    nameTable_[KnownColor.GradientInactiveCaption] = "GradientInactiveCaption";
    nameTable_[KnownColor.GrayText] = "GrayText";
    nameTable_[KnownColor.Highlight] = "Highlight";
    nameTable_[KnownColor.HighlightText] = "HighlightText";
    nameTable_[KnownColor.HotTrack] = "HotTrack";
    nameTable_[KnownColor.InactiveBorder] = "InactiveBorder";
    nameTable_[KnownColor.InactiveCaption] = "InactiveCaption";
    nameTable_[KnownColor.InactiveCaptionText] = "InactiveCaptionText";
    nameTable_[KnownColor.Info] = "Info";
    nameTable_[KnownColor.InfoText] = "InfoText";
    nameTable_[KnownColor.Menu] = "Menu";
    nameTable_[KnownColor.MenuBar] = "MenuBar";
    nameTable_[KnownColor.MenuHighlight] = "MenuHighlight";
    nameTable_[KnownColor.MenuText] = "MenuText";
    nameTable_[KnownColor.ScrollBar] = "ScrollBar";
    nameTable_[KnownColor.Window] = "Window";
    nameTable_[KnownColor.WindowFrame] = "WindowFrame";
    nameTable_[KnownColor.WindowText] = "WindowText";

    nameTable_[KnownColor.Transparent] = "Transparent";
    nameTable_[KnownColor.AliceBlue] = "AliceBlue";
    nameTable_[KnownColor.AntiqueWhite] = "AntiqueWhite";
    nameTable_[KnownColor.Aqua] = "Aqua";
    nameTable_[KnownColor.Aquamarine] = "Aquamarine";
    nameTable_[KnownColor.Azure] = "Azure";
    nameTable_[KnownColor.Beige] = "Beige";
    nameTable_[KnownColor.Bisque] = "Bisque";
    nameTable_[KnownColor.Black] = "Black";
    nameTable_[KnownColor.BlanchedAlmond] = "BlanchedAlmond";
    nameTable_[KnownColor.Blue] = "Blue";
    nameTable_[KnownColor.BlueViolet] = "BlueViolet";
    nameTable_[KnownColor.Brown] = "Brown";
    nameTable_[KnownColor.BurlyWood] = "BurlyWood";
    nameTable_[KnownColor.CadetBlue] = "CadetBlue";
    nameTable_[KnownColor.Chartreuse] = "Chartreuse";
    nameTable_[KnownColor.Chocolate] = "Chocolate";
    nameTable_[KnownColor.Coral] = "Coral";
    nameTable_[KnownColor.CornflowerBlue] = "CornflowerBlue";
    nameTable_[KnownColor.Cornsilk] = "Cornsilk";
    nameTable_[KnownColor.Crimson] = "Crimson";
    nameTable_[KnownColor.Cyan] = "Cyan";
    nameTable_[KnownColor.DarkBlue] = "DarkBlue";
    nameTable_[KnownColor.DarkCyan] = "DarkCyan";
    nameTable_[KnownColor.DarkGoldenrod] = "DarkGoldenrod";
    nameTable_[KnownColor.DarkGray] = "DarkGray";
    nameTable_[KnownColor.DarkGreen] = "DarkGreen";
    nameTable_[KnownColor.DarkKhaki] = "DarkKhaki";
    nameTable_[KnownColor.DarkMagenta] = "DarkMagenta";
    nameTable_[KnownColor.DarkOliveGreen] = "DarkOliveGreen";
    nameTable_[KnownColor.DarkOrange] = "DarkOrange";
    nameTable_[KnownColor.DarkOrchid] = "DarkOrchid";
    nameTable_[KnownColor.DarkRed] = "DarkRed";
    nameTable_[KnownColor.DarkSalmon] = "DarkSalmon";
    nameTable_[KnownColor.DarkSeaGreen] = "DarkSeaGreen";
    nameTable_[KnownColor.DarkSlateBlue] = "DarkSlateBlue";
    nameTable_[KnownColor.DarkSlateGray] = "DarkSlateGray";
    nameTable_[KnownColor.DarkTurquoise] = "DarkTurquoise";
    nameTable_[KnownColor.DarkViolet] = "DarkViolet";
    nameTable_[KnownColor.DeepPink] = "DeepPink";
    nameTable_[KnownColor.DeepSkyBlue] = "DeepSkyBlue";
    nameTable_[KnownColor.DimGray] = "DimGray";
    nameTable_[KnownColor.DodgerBlue] = "DodgerBlue";
    nameTable_[KnownColor.Firebrick] = "Firebrick";
    nameTable_[KnownColor.FloralWhite] = "FloralWhite";
    nameTable_[KnownColor.ForestGreen] = "ForestGreen";
    nameTable_[KnownColor.Fuchsia] = "Fuchsia";
    nameTable_[KnownColor.Gainsboro] = "Gainsboro";
    nameTable_[KnownColor.GhostWhite] = "GhostWhite";
    nameTable_[KnownColor.Gold] = "Gold";
    nameTable_[KnownColor.Goldenrod] = "Goldenrod";
    nameTable_[KnownColor.Gray] = "Gray";
    nameTable_[KnownColor.Green] = "Green";
    nameTable_[KnownColor.GreenYellow] = "GreenYellow";
    nameTable_[KnownColor.Honeydew] = "Honeydew";
    nameTable_[KnownColor.HotPink] = "HotPink";
    nameTable_[KnownColor.IndianRed] = "IndianRed";
    nameTable_[KnownColor.Indigo] = "Indigo";
    nameTable_[KnownColor.Ivory] = "Ivory";
    nameTable_[KnownColor.Khaki] = "Khaki";
    nameTable_[KnownColor.Lavender] = "Lavender";
    nameTable_[KnownColor.LavenderBlush] = "LavenderBlush";
    nameTable_[KnownColor.LawnGreen] = "LawnGreen";
    nameTable_[KnownColor.LemonChiffon] = "LemonChiffon";
    nameTable_[KnownColor.LightBlue] = "LightBlue";
    nameTable_[KnownColor.LightCoral] = "LightCoral";
    nameTable_[KnownColor.LightCyan] = "LightCyan";
    nameTable_[KnownColor.LightGoldenrodYellow] = "LightGoldenrodYellow";
    nameTable_[KnownColor.LightGreen] = "LightGreen";
    nameTable_[KnownColor.LightGray] = "LightGray";
    nameTable_[KnownColor.LightPink] = "LightPink";
    nameTable_[KnownColor.LightSalmon] = "LightSalmon";
    nameTable_[KnownColor.LightSeaGreen] = "LightSeaGreen";
    nameTable_[KnownColor.LightSkyBlue] = "LightSkyBlue";
    nameTable_[KnownColor.LightSlateGray] = "LightSlateGray";
    nameTable_[KnownColor.LightSteelBlue] = "LightSteelBlue";
    nameTable_[KnownColor.LightYellow] = "LightYellow";
    nameTable_[KnownColor.Lime] = "Lime";
    nameTable_[KnownColor.LimeGreen] = "LimeGreen";
    nameTable_[KnownColor.Linen] = "Linen";
    nameTable_[KnownColor.Magenta] = "Magenta";
    nameTable_[KnownColor.Maroon] = "Maroon";
    nameTable_[KnownColor.MediumAquamarine] = "MediumAquamarine";
    nameTable_[KnownColor.MediumBlue] = "MediumBlue";
    nameTable_[KnownColor.MediumOrchid] = "MediumOrchid";
    nameTable_[KnownColor.MediumPurple] = "MediumPurple";
    nameTable_[KnownColor.MediumSeaGreen] = "MediumSeaGreen";
    nameTable_[KnownColor.MediumSlateBlue] = "MediumSlateBlue";
    nameTable_[KnownColor.MediumSpringGreen] = "MediumSpringGreen";
    nameTable_[KnownColor.MediumTurquoise] = "MediumTurquoise";
    nameTable_[KnownColor.MediumVioletRed] = "MediumVioletRed";
    nameTable_[KnownColor.MidnightBlue] = "MidnightBlue";
    nameTable_[KnownColor.MintCream] = "MintCream";
    nameTable_[KnownColor.MistyRose] = "MistyRose";
    nameTable_[KnownColor.Moccasin] = "Moccasin";
    nameTable_[KnownColor.NavajoWhite] = "NavajoWhite";
    nameTable_[KnownColor.Navy] = "Navy";
    nameTable_[KnownColor.OldLace] = "OldLace";
    nameTable_[KnownColor.Olive] = "Olive";
    nameTable_[KnownColor.OliveDrab] = "OliveDrab";
    nameTable_[KnownColor.Orange] = "Orange";
    nameTable_[KnownColor.OrangeRed] = "OrangeRed";
    nameTable_[KnownColor.Orchid] = "Orchid";
    nameTable_[KnownColor.PaleGoldenrod] = "PaleGoldenrod";
    nameTable_[KnownColor.PaleGreen] = "PaleGreen";
    nameTable_[KnownColor.PaleTurquoise] = "PaleTurquoise";
    nameTable_[KnownColor.PaleVioletRed] = "PaleVioletRed";
    nameTable_[KnownColor.PapayaWhip] = "PapayaWhip";
    nameTable_[KnownColor.PeachPuff] = "PeachPuff";
    nameTable_[KnownColor.Peru] = "Peru";
    nameTable_[KnownColor.Pink] = "Pink";
    nameTable_[KnownColor.Plum] = "Plum";
    nameTable_[KnownColor.PowderBlue] = "PowderBlue";
    nameTable_[KnownColor.Purple] = "Purple";
    nameTable_[KnownColor.Red] = "Red";
    nameTable_[KnownColor.RosyBrown] = "RosyBrown";
    nameTable_[KnownColor.RoyalBlue] = "RoyalBlue";
    nameTable_[KnownColor.SaddleBrown] = "SaddleBrown";
    nameTable_[KnownColor.Salmon] = "Salmon";
    nameTable_[KnownColor.SandyBrown] = "SandyBrown";
    nameTable_[KnownColor.SeaGreen] = "SeaGreen";
    nameTable_[KnownColor.SeaShell] = "SeaShell";
    nameTable_[KnownColor.Sienna] = "Sienna";
    nameTable_[KnownColor.Silver] = "Silver";
    nameTable_[KnownColor.SkyBlue] = "SkyBlue";
    nameTable_[KnownColor.SlateBlue] = "SlateBlue";
    nameTable_[KnownColor.SlateGray] = "SlateGray";
    nameTable_[KnownColor.Snow] = "Snow";
    nameTable_[KnownColor.SpringGreen] = "SpringGreen";
    nameTable_[KnownColor.SteelBlue] = "SteelBlue";
    nameTable_[KnownColor.Tan] = "Tan";
    nameTable_[KnownColor.Teal] = "Teal";
    nameTable_[KnownColor.Thistle] = "Thistle";
    nameTable_[KnownColor.Tomato] = "Tomato";
    nameTable_[KnownColor.Turquoise] = "Turquoise";
    nameTable_[KnownColor.Violet] = "Violet";
    nameTable_[KnownColor.Wheat] = "Wheat";
    nameTable_[KnownColor.White] = "White";
    nameTable_[KnownColor.WhiteSmoke] = "WhiteSmoke";
    nameTable_[KnownColor.Yellow] = "Yellow";
    nameTable_[KnownColor.YellowGreen] = "YellowGreen";
  }

  /*private static void initHtmlSystemColorTable() {
    htmlSystemColorTable_["activeborder"] = Color.fromKnownColor(KnownColor.ActiveBorder);
    htmlSystemColorTable_["activecaption"] = Color.fromKnownColor(KnownColor.ActiveCaption);
    htmlSystemColorTable_["appworkspace"] = Color.fromKnownColor(KnownColor.AppWorkspace);
    htmlSystemColorTable_["background"] = Color.fromKnownColor(KnownColor.Desktop);
    htmlSystemColorTable_["buttonface"] = Color.fromKnownColor(KnownColor.Control);
    htmlSystemColorTable_["buttonhighlight"] = Color.fromKnownColor(KnownColor.ControlLightLight);
    htmlSystemColorTable_["buttonshadow"] = Color.fromKnownColor(KnownColor.ControlDark);
    htmlSystemColorTable_["buttontext"] = Color.fromKnownColor(KnownColor.ControlText);
    htmlSystemColorTable_["captiontext"] = Color.fromKnownColor(KnownColor.ActiveCaptionText);
    htmlSystemColorTable_["graytext"] = Color.fromKnownColor(KnownColor.GrayText);
    htmlSystemColorTable_["highlight"] = Color.fromKnownColor(KnownColor.Highlight);
    htmlSystemColorTable_["highlighttext"] = Color.fromKnownColor(KnownColor.HighlightText);
    htmlSystemColorTable_["inactiveborder"] = Color.fromKnownColor(KnownColor.InactiveBorder);
    htmlSystemColorTable_["inactivecaption"] = Color.fromKnownColor(KnownColor.InactiveCaption);
    htmlSystemColorTable_["inactivecaptiontext"] = Color.fromKnownColor(KnownColor.InactiveCaptionText);
    htmlSystemColorTable_["infobackground"] = Color.fromKnownColor(KnownColor.Info);
    htmlSystemColorTable_["infotext"] = Color.fromKnownColor(KnownColor.InfoText);
    htmlSystemColorTable_["menu"] = Color.fromKnownColor(KnownColor.Menu);
    htmlSystemColorTable_["menutext"] = Color.fromKnownColor(KnownColor.MenuText);
    htmlSystemColorTable_["scrollbar"] = Color.fromKnownColor(KnownColor.ScrollBar);
    htmlSystemColorTable_["threeddarkshadow"] = Color.fromKnownColor(KnownColor.ControlDarkDark);
    htmlSystemColorTable_["threedface"] = Color.fromKnownColor(KnownColor.Control);
    htmlSystemColorTable_["threedhighlight"] = Color.fromKnownColor(KnownColor.ControlLight);
    htmlSystemColorTable_["threedlightshadow"] = Color.fromKnownColor(KnownColor.ControlLightLight);
    htmlSystemColorTable_["window"] = Color.fromKnownColor(KnownColor.Window);
    htmlSystemColorTable_["windowframe"] = Color.fromKnownColor(KnownColor.WindowFrame);
    htmlSystemColorTable_["windowtext"] = Color.fromKnownColor(KnownColor.WindowText);
  }

  private static void initNamedColorTable() {
    namedColorTable_["transparent"] = Color.transparent;
    namedColorTable_["aliceblue"] = Color.aliceBlue;
    namedColorTable_["antiquewhite"] = Color.antiqueWhite;
    namedColorTable_["aqua"] = Color.aqua;
    namedColorTable_["aquamarine"] = Color.aquamarine;
    namedColorTable_["azure"] = Color.azure;
    namedColorTable_["beige"] = Color.beige;
    namedColorTable_["bisque"] = Color.bisque;
    namedColorTable_["black"] = Color.black;
    namedColorTable_["blanchedalmond"] = Color.blanchedAlmond;
    namedColorTable_["blue"] = Color.blue;
    namedColorTable_["blueviolet"] = Color.blueViolet;
    namedColorTable_["brown"] = Color.brown;
    namedColorTable_["burlywood"] = Color.burlyWood;
    namedColorTable_["cadetblue"] = Color.cadetBlue;
    namedColorTable_["chartreuse"] = Color.chartreuse;
    namedColorTable_["chocolate"] = Color.chocolate;
    namedColorTable_["coral"] = Color.coral;
    namedColorTable_["cornflowerblue"] = Color.cornflowerBlue;
    namedColorTable_["cornsilk"] = Color.cornsilk;
    namedColorTable_["crimson"] = Color.crimson;
    namedColorTable_["cyan"] = Color.cyan;
    namedColorTable_["darkblue"] = Color.darkBlue;
    namedColorTable_["darkcyan"] = Color.darkCyan;
    namedColorTable_["darkgoldenrod"] = Color.darkGoldenrod;
    namedColorTable_["darkgray"] = Color.darkGray;
    namedColorTable_["darkgreen"] = Color.darkGreen;
    namedColorTable_["darkkhaki"] = Color.darkKhaki;
    namedColorTable_["darkmagenta"] = Color.darkMagenta;
    namedColorTable_["darkolivegreen"] = Color.darkOliveGreen;
    namedColorTable_["darkorange"] = Color.darkOrange;
    namedColorTable_["darkorchid"] = Color.darkOrchid;
    namedColorTable_["darkred"] = Color.darkRed;
    namedColorTable_["darksalmon"] = Color.darkSalmon;
    namedColorTable_["darkseagreen"] = Color.darkSeaGreen;
    namedColorTable_["darkslateblue"] = Color.darkSlateBlue;
    namedColorTable_["darkslategray"] = Color.darkSlateGray;
    namedColorTable_["darkturquoise"] = Color.darkTurquoise;
    namedColorTable_["darkviolet"] = Color.darkViolet;
    namedColorTable_["deeppink"] = Color.deepPink;
    namedColorTable_["deepskyblue"] = Color.deepSkyBlue;
    namedColorTable_["dimgray"] = Color.dimGray;
    namedColorTable_["dodgerblue"] = Color.dodgerBlue;
    namedColorTable_["firebrick"] = Color.firebrick;
    namedColorTable_["floralwhite"] = Color.floralWhite;
    namedColorTable_["forestgreen"] = Color.forestGreen;
    namedColorTable_["fuchsia"] = Color.fuchsia;
    namedColorTable_["gainsboro"] = Color.gainsboro;
    namedColorTable_["ghostwhite"] = Color.ghostWhite;
    namedColorTable_["gold"] = Color.gold;
    namedColorTable_["goldenrod"] = Color.goldenrod;
    namedColorTable_["gray"] = Color.gray;
    namedColorTable_["green"] = Color.green;
    namedColorTable_["greenyellow"] = Color.greenYellow;
    namedColorTable_["honeydew"] = Color.honeydew;
    namedColorTable_["hotpink"] = Color.hotPink;
    namedColorTable_["indianred"] = Color.indianRed;
    namedColorTable_["indigo"] = Color.indigo;
    namedColorTable_["ivory"] = Color.ivory;
    namedColorTable_["khaki"] = Color.khaki;
    namedColorTable_["lavender"] = Color.lavender;
    namedColorTable_["lavenderblush"] = Color.lavenderBlush;
    namedColorTable_["lawngreen"] = Color.lawnGreen;
    namedColorTable_["lemonchiffon"] = Color.lemonChiffon;
    namedColorTable_["lightblue"] = Color.lightBlue;
    namedColorTable_["lightcoral"] = Color.lightCoral;
    namedColorTable_["lightcyan"] = Color.lightCyan;
    namedColorTable_["lightgoldenrodyellow"] = Color.lightGoldenrodYellow;
    namedColorTable_["lightgreen"] = Color.lightGreen;
    namedColorTable_["lightgray"] = Color.lightGray;
    namedColorTable_["lightpink"] = Color.lightPink;
    namedColorTable_["lightsalmon"] = Color.lightSalmon;
    namedColorTable_["lightseagreen"] = Color.lightSeaGreen;
    namedColorTable_["lightskyblue"] = Color.lightSkyBlue;
    namedColorTable_["lightslategray"] = Color.lightSlateGray;
    namedColorTable_["lightsteelblue"] = Color.lightSteelBlue;
    namedColorTable_["lightyellow"] = Color.lightYellow;
    namedColorTable_["lime"] = Color.lime;
    namedColorTable_["limegreen"] = Color.limeGreen;
    namedColorTable_["linen"] = Color.linen;
    namedColorTable_["magenta"] = Color.magenta;
    namedColorTable_["maroon"] = Color.maroon;
    namedColorTable_["mediumaquamarine"] = Color.mediumAquamarine;
    namedColorTable_["mediumblue"] = Color.mediumBlue;
    namedColorTable_["mediumorchid"] = Color.mediumOrchid;
    namedColorTable_["mediumpurple"] = Color.mediumPurple;
    namedColorTable_["mediumseagreen"] = Color.mediumSeaGreen;
    namedColorTable_["mediumslateblue"] = Color.mediumSlateBlue;
    namedColorTable_["mediumspringgreen"] = Color.mediumSpringGreen;
    namedColorTable_["mediumturquoise"] = Color.mediumTurquoise;
    namedColorTable_["mediumvioletred"] = Color.mediumVioletRed;
    namedColorTable_["midnightblue"] = Color.midnightBlue;
    namedColorTable_["mintcream"] = Color.mintCream;
    namedColorTable_["mistyrose"] = Color.mistyRose;
    namedColorTable_["moccasin"] = Color.moccasin;
    namedColorTable_["navajowhite"] = Color.navajoWhite;
    namedColorTable_["navy"] = Color.navy;
    namedColorTable_["oldlace"] = Color.oldLace;
    namedColorTable_["olive"] = Color.olive;
    namedColorTable_["olivedrab"] = Color.oliveDrab;
    namedColorTable_["orange"] = Color.orange;
    namedColorTable_["orangered"] = Color.orangeRed;
    namedColorTable_["orchid"] = Color.orchid;
    namedColorTable_["palegoldenrod"] = Color.paleGoldenrod;
    namedColorTable_["palegreen"] = Color.paleGreen;
    namedColorTable_["paleturquoise"] = Color.paleTurquoise;
    namedColorTable_["palevioletred"] = Color.paleVioletRed;
    namedColorTable_["papayawhip"] = Color.papayaWhip;
    namedColorTable_["peachpuff"] = Color.peachPuff;
    namedColorTable_["peru"] = Color.peru;
    namedColorTable_["pink"] = Color.pink;
    namedColorTable_["plum"] = Color.plum;
    namedColorTable_["powderblue"] = Color.powderBlue;
    namedColorTable_["purple"] = Color.purple;
    namedColorTable_["red"] = Color.red;
    namedColorTable_["rosybrown"] = Color.rosyBrown;
    namedColorTable_["royalblue"] = Color.royalBlue;
    namedColorTable_["saddlebrown"] = Color.saddleBrown;
    namedColorTable_["salmon"] = Color.salmon;
    namedColorTable_["sandybrown"] = Color.sandyBrown;
    namedColorTable_["seagreen"] = Color.seaGreen;
    namedColorTable_["seashell"] = Color.seaShell;
    namedColorTable_["sienna"] = Color.sienna;
    namedColorTable_["silver"] = Color.silver;
    namedColorTable_["skyblue"] = Color.skyBlue;
    namedColorTable_["slateblue"] = Color.slateBlue;
    namedColorTable_["slategray"] = Color.slateGray;
    namedColorTable_["snow"] = Color.snow;
    namedColorTable_["springgreen"] = Color.springGreen;
    namedColorTable_["steelblue"] = Color.steelBlue;
    namedColorTable_["tan"] = Color.tan;
    namedColorTable_["teal"] = Color.teal;
    namedColorTable_["thistle"] = Color.thistle;
    namedColorTable_["tomato"] = Color.tomato;
    namedColorTable_["turquoise"] = Color.turquoise;
    namedColorTable_["violet"] = Color.violet;
    namedColorTable_["wheat"] = Color.wheat;
    namedColorTable_["white"] = Color.white;
    namedColorTable_["whitesmoke"] = Color.whiteSmoke;
    namedColorTable_["yellow"] = Color.yellow;
    namedColorTable_["yellowgreen"] = Color.yellowGreen;
  }

  private static void initNamedSystemColorTable() {
    namedSystemColorTable_["activeborder"] = Color.activeBorder;
    namedSystemColorTable_["activecaption"] = Color.activeCaption;
    namedSystemColorTable_["activecaptiontext"] = Color.activeCaptionText;
    namedSystemColorTable_["appworkspace"] = Color.appWorkspace;
    namedSystemColorTable_["buttonface"] = Color.buttonFace;
    namedSystemColorTable_["buttonhighlight"] = Color.buttonHighlight;
    namedSystemColorTable_["buttonshadow"] = Color.buttonShadow;
    namedSystemColorTable_["control"] = Color.control;
    namedSystemColorTable_["controldark"] = Color.controlDark;
    namedSystemColorTable_["controldarkdark"] = Color.controlDarkDark;
    namedSystemColorTable_["controllight"] = Color.controlLight;
    namedSystemColorTable_["controllightlight"] = Color.controlLightLight;
    namedSystemColorTable_["controltext"] = Color.controlText;
    namedSystemColorTable_["desktop"] = Color.desktop;
    namedSystemColorTable_["gradientactivecaption"] = Color.gradientActiveCaption;
    namedSystemColorTable_["gradientinactivecaption"] = Color.gradientInactiveCaption;
    namedSystemColorTable_["graytext"] = Color.grayText;
    namedSystemColorTable_["highlight"] = Color.highlight;
    namedSystemColorTable_["highlighttext"] = Color.highlightText;
    namedSystemColorTable_["hottrack"] = Color.hotTrack;
    namedSystemColorTable_["inactiveborder"] = Color.inactiveBorder;
    namedSystemColorTable_["inactivecaption"] = Color.inactiveCaption;
    namedSystemColorTable_["inactivecaptiontext"] = Color.inactiveCaptionText;
    namedSystemColorTable_["info"] = Color.info;
    namedSystemColorTable_["infotext"] = Color.infoText;
    namedSystemColorTable_["menu"] = Color.menu;
    namedSystemColorTable_["menubar"] = Color.menuBar;
    namedSystemColorTable_["menuhighlight"] = Color.menuHighlight;
    namedSystemColorTable_["menutext"] = Color.menuText;
    namedSystemColorTable_["scrollbar"] = Color.scrollBar;
    namedSystemColorTable_["window"] = Color.window;
    namedSystemColorTable_["windowframe"] = Color.windowFrame;
    namedSystemColorTable_["windowtext"] = Color.windowText;
  }*/

}

/**
 */
public final class Matrix {

  private Handle nativeMatrix_;

  /**
   */
  public this() {
    Status status = GdipCreateMatrix(nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public this(float m11, float m12, float m21, float m22, float dx, float dy) {
    Status status = GdipCreateMatrix2(m11, m12, m21, m22, dx, dy, nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public this(Rect rect, Point[] plgpts) {
    if (plgpts.length != 3)
      throw statusException(Status.InvalidParameter);

    Status status = GdipCreateMatrix3I(rect, plgpts.ptr, nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public this(RectF rect, PointF[] plgpts) {
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
  public void dispose() {
    if (nativeMatrix_ != Handle.init) {
      GdipDeleteMatrixSafe(nativeMatrix_);
      nativeMatrix_ = Handle.init;
    }
  }

  /**
   */
  public void clone() {
    Handle cloneMatrix;
    Status status = GdipCloneMatrix(nativeMatrix_, cloneMatrix);
    if (status != Status.OK)
      throw statusException(status);
    return new Matrix(cloneMatrix);
  }

  /**
   */
  public void invert() {
    Status status = GdipInvertMatrix(nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void reset() {
    Status status = GdipSetMatrixElements(nativeMatrix_, 1, 0, 0, 1, 0, 0);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void multiply(Matrix matrix, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipMultiplyMatrix(nativeMatrix_, matrix.nativeMatrix_, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void scale(float scaleX, float scaleY, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipScaleMatrix(nativeMatrix_, scaleX, scaleY, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void shear(float shearX, float shearY, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipShearMatrix(nativeMatrix_, shearX, shearY, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void rotate(float angle, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipRotateMatrix(nativeMatrix_, angle, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void translate(float offsetX, float offsetY, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipTranslateMatrix(nativeMatrix_, offsetX, offsetY, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public float[] elements() {
    float[] m = new float[6];
    Status status = GdipGetMatrixElements(nativeMatrix_, m.ptr);
    if (status != Status.OK)
      throw statusException(status);
    return m;
  }

  /**
   */
  public float offsetX() {
    return elements[4];
  }

  /**
   */
  public float offsetY() {
    return elements[5];
  }

  /**
   */
  public bool isIdentity() {
    int result;
    Status status = GdipIsMatrixIdentity(nativeMatrix_, result);
    if (status != Status.OK)
      throw statusException(status);
    return result == 1;
  }

  /**
   */
  public bool isInvertible() {
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
 */
public final class GraphicsState {

  private int nativeState_;

  package this(int nativeState) {
    nativeState_ = nativeState;
  }

}

/**
 */
public final class GraphicsContainer {

  private int nativeContainer_;

  package this(int nativeContainer) {
    nativeContainer_ = nativeContainer;
  }

}

/**
 * Encapsulates a drawing surface.
 */
public final class Graphics {

  /// $(I bool delegate(void* callbackData)) $(BR)$(BR)A callback method for deciding when the drawImage method should prematurely cancel execution and stop drawing an image.
  public alias bool delegate(void* callbackData) DrawImageAbort;

  private Handle nativeGraphics_;
  private Handle nativeHdc_;

  /**
   * Releases all resources used.
   */
  public void dispose() {
    if (nativeGraphics_ != Handle.init) {
      if (nativeHdc_ != Handle.init)
        releaseHdc();

      GdipDeleteGraphicsSafe(nativeGraphics_);
      nativeGraphics_ = Handle.init;
    }
  }

  /**
   * Creates a new instance from the specified handle to a device context.
   * Params: hdc = Handle to a device context.
   * Returns: A new instance for the specified device context.
   */
  public static Graphics fromHdc(Handle hdc) {
    Handle nativeGraphics;

    Status status = GdipCreateFromHDC(hdc, nativeGraphics);
    if (status != Status.OK)
      throw statusException(status);

    return new Graphics(nativeGraphics);
  }

  /**
   */
  public static Graphics fromHdc(Handle hdc, Handle hdevice) {
    Handle graphics;

    Status status = GdipCreateFromHDC2(hdc, hdevice, graphics);
    if (status != Status.OK)
      throw statusException(status);

    return new Graphics(graphics);
  }

  /**
   * Creates a new instance from the specified handle to a window.
   * Params: hwnd = Handle to a window.
   * Returns: A new instance for the specified window.
   */
  public static Graphics fromHwnd(Handle hwnd) {
    Handle nativeGraphics;

    Status status = GdipCreateFromHWND(hwnd, nativeGraphics);
    if (status != Status.OK)
      throw statusException(status);

    return new Graphics(nativeGraphics);
  }

  /**
   * Creates a new instance from the specified Image.
   * Params: image = The Image from which to create the new instance.
   * Returns: A new instance for the specified Image.
   */
  public static Graphics fromImage(Image image) {
    if (image is null)
      throw new ArgumentNullException("image");

    Handle nativeGraphics;

    Status status = GdipGetImageGraphicsContext(image.nativeImage_, nativeGraphics);
    if (status != Status.OK)
      throw statusException(status);

    return new Graphics(nativeGraphics);
  }

  /**
   * Gets a handle to the device context associated with this instance.
   * Returns: Handle to the device context associated with this instance.
   */
  public Handle getHdc() {
    Handle hdc;

    Status status = GdipGetDC(nativeGraphics_, hdc);
    if (status != Status.OK)
      throw statusException(status);

    return nativeHdc_ = hdc;
  }

  /**
   * Releases a device context handle obtained by a previous call to the getHdc method of this instance.
   */
  public void releaseHdc() {
    releaseHdc(nativeHdc_);
  }

  /**
   * Releases a device context handle obtained by a previous call to the getHdc method of this instance.
   * Params: hdc = Handle to a device context obtained by a previous call to getHdc.
   */
  public void releaseHdc(Handle hdc) {
    Status status = GdipReleaseDC(nativeGraphics_, hdc);
    if (status != Status.OK)
      throw statusException(status);
    nativeHdc_ = Handle.init;
  }

  /**
   */
  public void setClip(Graphics g, CombineMode combineMode = CombineMode.Replace) {
    if (g is null)
      throw new ArgumentNullException("g");

    Status status = GdipSetClipGraphics(nativeGraphics_, g.nativeGraphics_, combineMode);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void setClip(Rect rect, CombineMode combineMode = CombineMode.Replace) {
    Status status = GdipSetClipRectI(nativeGraphics_, rect.x, rect.y, rect.width, rect.height, combineMode);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void setClip(RectF rect, CombineMode combineMode = CombineMode.Replace) {
    Status status = GdipSetClipRect(nativeGraphics_, rect.x, rect.y, rect.width, rect.height, combineMode);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void setClip(GraphicsPath path, CombineMode combineMode = CombineMode.Replace) {
    if (path is null)
      throw new ArgumentNullException("path");

    Status status = GdipSetClipPath(nativeGraphics_, path.nativePath, combineMode);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void setClip(Region region, CombineMode combineMode) {
    if (region is null)
      throw new ArgumentNullException("region");

    Status status = GdipSetClipRegion(nativeGraphics_, region.nativeRegion, combineMode);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void intersectClip(RectF rect) {
    Status status = GdipSetClipRect(nativeGraphics_, rect.x, rect.y, rect.width, rect.height, CombineMode.Intersect);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void intersectClip(Rect rect) {
    Status status = GdipSetClipRectI(nativeGraphics_, rect.x, rect.y, rect.width, rect.height, CombineMode.Intersect);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void intersectClip(Region region) {
    if (region is null)
      throw new ArgumentNullException("region");

    Status status = GdipSetClipRegion(nativeGraphics_, region.nativeRegion, CombineMode.Intersect);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void excludeClip(RectF rect) {
    Status status = GdipSetClipRect(nativeGraphics_, rect.x, rect.y, rect.width, rect.height, CombineMode.Exclude);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void excludeClip(Rect rect) {
    Status status = GdipSetClipRectI(nativeGraphics_, rect.x, rect.y, rect.width, rect.height, CombineMode.Exclude);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void excludeClip(Region region) {
    if (region is null)
      throw new ArgumentNullException("region");

    Status status = GdipSetClipRegion(nativeGraphics_, region.nativeRegion, CombineMode.Exclude);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void resetClip() {
    Status status = GdipResetClip(nativeGraphics_);
    if (status != Status.OK)
      throw statusException(status);
  }

  public bool isVisible(int x, int y) {
    return isVisible(Point(x, y));
  }

  public bool isVisible(Point point) {
    int result = 0;
    Status status = GdipIsVisiblePointI(nativeGraphics_, point.x, point.y, result);
    if (status != Status.OK)
      throw statusException(status);
    return result == 1;
  }

  public bool isVisible(int x, int y, int width, int height) {
    return isVisible(Rect(x, y, width, height));
  }

  public bool isVisible(Rect rect) {
    int result = 0;
    Status status = GdipIsVisibleRectI(nativeGraphics_, rect.x, rect.y, rect.width, rect.height, result);
    if (status != Status.OK)
      throw statusException(status);
    return result == 1;
  }

  public bool isVisible(float x, float y) {
    return isVisible(PointF(x, y));
  }

  public bool isVisible(PointF point) {
    int result = 0;
    Status status = GdipIsVisiblePoint(nativeGraphics_, point.x, point.y, result);
    if (status != Status.OK)
      throw statusException(status);
    return result == 1;
  }

  public bool isVisible(float x, float y, float width, float height) {
    return isVisible(RectF(x, y, width, height));
  }

  public bool isVisible(RectF rect) {
    int result = 0;
    Status status = GdipIsVisibleRect(nativeGraphics_, rect.x, rect.y, rect.width, rect.height, result);
    if (status != Status.OK)
      throw statusException(status);
    return result == 1;
  }

  public void addMetafileComment(ubyte[] data) {
    Status status = GdipComment(nativeGraphics_, data.length, data.ptr);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public GraphicsState save() {
    int state;
    Status status = GdipSaveGraphics(nativeGraphics_, state);
    if (status != Status.OK)
      throw statusException(status);
    return new GraphicsState(state);
  }

  /**
   */
  public void restore(GraphicsState state) {
    Status status = GdipRestoreGraphics(nativeGraphics_, state.nativeState_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void flush(FlushIntention intention = FlushIntention.Flush) {
    Status status = GdipFlush(nativeGraphics_, intention);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void scaleTransform(float sx, float sy, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipScaleWorldTransform(nativeGraphics_, sx, sy, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void rotateTransform(float angle, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipRotateWorldTransform(nativeGraphics_, angle, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void translateTransform(float dx, float dy, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipTranslateWorldTransform(nativeGraphics_, dx, dy, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void multiplyTransform(Matrix matrix, MatrixOrder order = MatrixOrder.Prepend) {
    if (matrix is null)
      throw new ArgumentNullException("matrix");

    Status status = GdipMultiplyWorldTransform(nativeGraphics_, matrix.nativeMatrix_, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void resetTransform() {
    Status status = GdipResetWorldTransform(nativeGraphics_);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void transformPoints(CoordinateSpace destSpace, CoordinateSpace srcSpace, PointF[] points) {
    Status status = GdipTransformPoints(nativeGraphics_, destSpace, srcSpace, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void transformPoints(CoordinateSpace destSpace, CoordinateSpace srcSpace, Point[] points) {
    Status status = GdipTransformPointsI(nativeGraphics_, destSpace, srcSpace, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public GraphicsContainer beginContainer() {
    int state;
    Status status = GdipBeginContainer2(nativeGraphics_, state);
    if (status != Status.OK)
      throw statusException(status);
    return new GraphicsContainer(state);
  }

  /**
   */
  public GraphicsContainer beginContainer(RectF dstrect, RectF srcrect, GraphicsUnit unit) {
    int state;
    Status status = GdipBeginContainer(nativeGraphics_, dstrect, srcrect, unit, state);
    if (status != Status.OK)
      throw statusException(status);
    return new GraphicsContainer(state);
  }

  /**
   */
  public GraphicsContainer beginContainer(Rect dstrect, Rect srcrect, GraphicsUnit unit) {
    int state;
    Status status = GdipBeginContainerI(nativeGraphics_, dstrect, srcrect, unit, state);
    if (status != Status.OK)
      throw statusException(status);
    return new GraphicsContainer(state);
  }

  /**
   */
  public void endContainer(GraphicsContainer container) {
    Status status = GdipEndContainer(nativeGraphics_, container.nativeContainer_);
    if (status != Status.OK)
      throw statusException(status);
  }

  public Color getNearestColor(Color color) {
    int argb = color.toArgb();
    Status status = GdipGetNearestColor(nativeGraphics_, argb);
    if (status != Status.OK)
      throw statusException(status);
    return Color.fromArgb(argb);
  }

  public void drawLine(Pen pen, float x1, float y1, float x2, float y2) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawLine(nativeGraphics_, pen.nativePen, x1, y1, x2, y2);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawLine(Pen pen, PointF pt1, PointF pt2) {
    drawLine(pen, pt1.x, pt1.y, pt2.x, pt2.y);
  }

  public void drawLines(Pen pen, PointF[] points) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawLines(nativeGraphics_, pen.nativePen, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawLine(Pen pen, int x1, int y1, int x2, int y2) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawLineI(nativeGraphics_, pen.nativePen, x1, y1, x2, y2);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawLine(Pen pen, Point pt1, Point pt2) {
    drawLine(pen, pt1.x, pt1.y, pt2.x, pt2.y);
  }

  public void drawLines(Pen pen, Point[] points) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawLinesI(nativeGraphics_, pen.nativePen, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawArc(Pen pen, float x, float y, float width, float height, float startAngle, float sweepAngle) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawArc(nativeGraphics_, pen.nativePen, x, y, width, height, startAngle, sweepAngle);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawArc(Pen pen, RectF rect, float startAngle, float sweepAngle) {
    drawArc(pen, rect.x, rect.y, rect.width, rect.height, startAngle, sweepAngle);
  }

  public void drawArc(Pen pen, int x, int y, int width, int height, float startAngle, float sweepAngle) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawArcI(nativeGraphics_, pen.nativePen, x, y, width, height, startAngle, sweepAngle);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawArc(Pen pen, Rect rect, float startAngle, float sweepAngle) {
    drawArc(pen, rect.x, rect.y, rect.width, rect.height, startAngle, sweepAngle);
  }

  public void drawBezier(Pen pen, float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawBezier(nativeGraphics_, pen.nativePen, x1, y1, x2, y2, x3, y3, x4, y4);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawBezier(Pen pen, PointF pt1, PointF pt2, PointF pt3, PointF pt4) {
    drawBezier(pen, pt1.x, pt1.y, pt2.x, pt2.y, pt3.x, pt3.y, pt4.x, pt4.y);
  }

  public void drawBeziers(Pen pen, PointF[] points) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawBeziers(nativeGraphics_, pen.nativePen, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawBezier(Pen pen, int x1, int y1, int x2, int y2, int x3, int y3, int x4, int y4) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawBezierI(nativeGraphics_, pen.nativePen, x1, y1, x2, y2, x3, y3, x4, y4);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawBezier(Pen pen, Point pt1, Point pt2, Point pt3, Point pt4) {
    drawBezier(pen, pt1.x, pt1.y, pt2.x, pt2.y, pt3.x, pt3.y, pt4.x, pt4.y);
  }

  public void drawBeziers(Pen pen, Point[] points) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawBeziersI(nativeGraphics_, pen.nativePen, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawRectangle(Pen pen, float x, float y, float width, float height) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawRectangle(nativeGraphics_, pen.nativePen, x, y, width, height);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawRectangle(Pen pen, RectF rect) {
    drawRectangle(pen, rect.x, rect.y, rect.width, rect.height);
  }

  public void drawRectangles(Pen pen, RectF[] rects) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawRectangles(nativeGraphics_, pen.nativePen, rects.ptr, rects.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawRectangle(Pen pen, int x, int y, int width, int height) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawRectangleI(nativeGraphics_, pen.nativePen, x, y, width, height);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawRectangle(Pen pen, Rect rect) {
    drawRectangle(pen, rect.x, rect.y, rect.width, rect.height);
  }

  public void drawRectangles(Pen pen, Rect[] rects) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawRectanglesI(nativeGraphics_, pen.nativePen, rects.ptr, rects.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawEllipse(Pen pen, float x, float y, float width, float height) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawEllipse(nativeGraphics_, pen.nativePen, x, y, width, height);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawEllipse(Pen pen, RectF rect) {
    drawEllipse(pen, rect.x, rect.y, rect.width, rect.height);
  }

  public void drawEllipse(Pen pen, int x, int y, int width, int height) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawEllipseI(nativeGraphics_, pen.nativePen, x, y, width, height);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawEllipse(Pen pen, Rect rect) {
    drawEllipse(pen, rect.x, rect.y, rect.width, rect.height);
  }

  public void drawPie(Pen pen, float x, float y, float width, float height, float startAngle, float sweepAngle) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawPie(nativeGraphics_, pen.nativePen, x, y, width, height, startAngle, sweepAngle);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawPie(Pen pen, RectF rect, float startAngle, float sweepAngle) {
    drawPie(pen, rect.x, rect.y, rect.width, rect.height, startAngle, sweepAngle);
  }

  public void drawPie(Pen pen, int x, int y, int width, int height, float startAngle, float sweepAngle) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawPieI(nativeGraphics_, pen.nativePen, x, y, width, height, startAngle, sweepAngle);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawPie(Pen pen, Rect rect, float startAngle, float sweepAngle) {
    drawPie(pen, rect.x, rect.y, rect.width, rect.height, startAngle, sweepAngle);
  }

  public void drawPolygon(Pen pen, PointF[] points) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawPolygon(nativeGraphics_, pen.nativePen, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawPolygon(Pen pen, Point[] points) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawPolygonI(nativeGraphics_, pen.nativePen, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawCurve(Pen pen, PointF[] points) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawCurve(nativeGraphics_, pen.nativePen, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawCurve(Pen pen, PointF[] points, float tension) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawCurve2(nativeGraphics_, pen.nativePen, points.ptr, points.length, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawCurve(Pen pen, PointF[] points, int offset, int numberOfSegments, float tension = 0.5f) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawCurve3(nativeGraphics_, pen.nativePen, points.ptr, points.length, offset, numberOfSegments, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawCurve(Pen pen, Point[] points) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawCurveI(nativeGraphics_, pen.nativePen, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawCurve(Pen pen, Point[] points, float tension) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawCurve2I(nativeGraphics_, pen.nativePen, points.ptr, points.length, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawCurve(Pen pen, Point[] points, int offset, int numberOfSegments, float tension = 0.5f) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawCurve3I(nativeGraphics_, pen.nativePen, points.ptr, points.length, offset, numberOfSegments, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawClosedCurve(Pen pen, PointF[] points) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawClosedCurve(nativeGraphics_, pen.nativePen, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawClosedCurve(Pen pen, PointF[] points, float tension) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawClosedCurve2(nativeGraphics_, pen.nativePen, points.ptr, points.length, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawClosedCurve(Pen pen, Point[] points) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawClosedCurveI(nativeGraphics_, pen.nativePen, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawClosedCurve(Pen pen, Point[] points, float tension) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipDrawClosedCurve2I(nativeGraphics_, pen.nativePen, points.ptr, points.length, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void clear(Color color) {
    Status status = GdipGraphicsClear(nativeGraphics_, color.toArgb());
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void fillRectangle(Brush brush, int x, int y, int width, int height) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillRectangleI(nativeGraphics_, brush.nativeBrush, x, y, width, height);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void fillRectangle(Brush brush, Rect rect) {
    fillRectangle(brush, rect.x, rect.y, rect.width, rect.height);
  }

  public void fillRectangles(Brush brush, Rect[] rects) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillRectanglesI(nativeGraphics_, brush.nativeBrush, rects.ptr, rects.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void fillRectangle(Brush brush, float x, float y, float width, float height) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillRectangle(nativeGraphics_, brush.nativeBrush, x, y, width, height);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void fillRectangle(Brush brush, RectF rect) {
    fillRectangle(brush, rect.x, rect.y, rect.width, rect.height);
  }

  public void fillRectangles(Brush brush, RectF[] rects) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillRectangles(nativeGraphics_, brush.nativeBrush, rects.ptr, rects.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void fillPolygon(Brush brush, PointF[] points, FillMode fillMode = FillMode.Alternate) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillPolygon(nativeGraphics_, brush.nativeBrush, points.ptr, points.length, fillMode);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void fillPolygon(Brush brush, Point[] points, FillMode fillMode = FillMode.Alternate) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillPolygonI(nativeGraphics_, brush.nativeBrush, points.ptr, points.length, fillMode);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void fillEllipse(Brush brush, float x, float y, float width, float height) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillEllipse(nativeGraphics_, brush.nativeBrush, x, y, width, height);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void fillEllipse(Brush brush, RectF rect) {
    fillEllipse(brush, rect.x, rect.y, rect.width, rect.height);
  }

  public void fillEllipse(Brush brush, int x, int y, int width, int height) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillEllipseI(nativeGraphics_, brush.nativeBrush, x, y, width, height);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void fillEllipse(Brush brush, Rect rect) {
    fillEllipse(brush, rect.x, rect.y, rect.width, rect.height);
  }

  public void fillPie(Brush brush, float x, float y, float width, float height, float startAngle, float sweepAngle) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillPie(nativeGraphics_, brush.nativeBrush, x, y, width, height, startAngle, sweepAngle);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void fillPie(Brush brush, RectF rect, float startAngle, float sweepAngle) {
    fillPie(brush, rect.x, rect.y, rect.width, rect.height, startAngle, sweepAngle);
  }

  public void fillPie(Brush brush, int x, int y, int width, int height, float startAngle, float sweepAngle) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillPieI(nativeGraphics_, brush.nativeBrush, x, y, width, height, startAngle, sweepAngle);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void fillPath(Brush brush, GraphicsPath path) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    if (path is null)
      throw new ArgumentNullException("path");

    Status status = GdipFillPath(nativeGraphics_, brush.nativeBrush, path.nativePath);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void fillClosedCurve(Brush brush, PointF[] points) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillClosedCurve(nativeGraphics_, brush.nativeBrush, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void fillClosedCurve(Brush brush, PointF[] points, FillMode fillMode, float tension = 0.5f) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillClosedCurve2(nativeGraphics_, brush.nativeBrush, points.ptr, points.length, fillMode, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void fillClosedCurve(Brush brush, Point[] points) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillClosedCurveI(nativeGraphics_, brush.nativeBrush, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void fillClosedCurve(Brush brush, Point[] points, FillMode fillMode, float tension = 0.5f) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipFillClosedCurve2I(nativeGraphics_, brush.nativeBrush, points.ptr, points.length, fillMode, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void fillRegion(Brush brush, Region region) {
    if (brush is null)
      throw new ArgumentNullException("brush");
    if (region is null)
      throw new ArgumentNullException("region");

    Status status = GdipFillRegion(nativeGraphics_, brush.nativeBrush, region.nativeRegion);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void drawString(string s, Font font, Brush brush, RectF layoutRect, StringFormat format = null) {
    if (brush is null)
      throw new ArgumentNullException("brush");
    if (s != null) {
      if (font is null)
        throw new ArgumentNullException("font");

      Status status = GdipDrawString(nativeGraphics_, s.toUtf16z(), s.length, font.nativeFont, layoutRect, (format is null ? Handle.init : format.nativeFormat), brush.nativeBrush);
      if (status != Status.OK)
        throw statusException(status);
    }
  }

  /**
   */
  public void drawString(string s, Font font, Brush brush, PointF point, StringFormat format = null) {
    drawString(s, font, brush, RectF(point.x, point.y, 0, 0), format);
  }

  /**
   */
  public void drawString(string s, Font font, Brush brush, float x, float y, StringFormat format = null) {
    drawString(s, font, brush, RectF(x, y, 0, 0), format);
  }

  public SizeF measureString(string s, Font font, SizeF layoutArea, StringFormat format = null) {
    if (s == null)
      return SizeF(0, 0);

    if (font is null)
      throw new ArgumentNullException("font");

    RectF layoutRect = RectF(0, 0, layoutArea.width, layoutArea.height);
    RectF boundingBox;
    int codePointsFitted, linesFitted;

    Status status = GdipMeasureString(nativeGraphics_, s.toUtf16z(), s.length, font.nativeFont, layoutRect, (format is null ? Handle.init : format.nativeFormat), boundingBox, codePointsFitted, linesFitted);
    if (status != Status.OK)
      throw statusException(status);

    return boundingBox.size;
  }

  public SizeF measureString(string s, Font font, SizeF layoutArea, StringFormat format, out int codePointsFitted, out int linesFitted) {
    if (s == null) {
      codePointsFitted = 0;
      linesFitted = 0;
      return SizeF(0, 0);
    }

    if (font is null)
      throw new ArgumentNullException("font");

    RectF layoutRect = RectF(0, 0, layoutArea.width, layoutArea.height);
    RectF boundingBox;

    Status status = GdipMeasureString(nativeGraphics_, s.toUtf16z(), s.length, font.nativeFont, layoutRect, (format is null ? Handle.init : format.nativeFormat), boundingBox, codePointsFitted, linesFitted);
    if (status != Status.OK)
      throw statusException(status);

    return boundingBox.size;
  }

  public SizeF measureString(string s, Font font) {
    return measureString(s, font, SizeF(0, 0));
  }

  public SizeF measureString(string s, Font font, PointF origin, StringFormat format) {
    if (s == null)
      return SizeF(0, 0);

    if (font is null)
      throw new ArgumentNullException("font");

    RectF layoutRect = RectF(origin.x, origin.y, 0, 0);
    RectF boundingBox;
    int codePointsFitted, linesFitted;

    Status status = GdipMeasureString(nativeGraphics_, s.toUtf16z(), s.length, font.nativeFont, layoutRect, (format is null ? Handle.init : format.nativeFormat), boundingBox, codePointsFitted, linesFitted);
    if (status != Status.OK)
      throw statusException(status);

    return boundingBox.size;
  }

  public Region[] measureCharacterRanges(string s, Font font, RectF layoutRect, StringFormat format) {
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

    status = GdipMeasureCharacterRanges(nativeGraphics_, s.toUtf16z(), s.length, font.nativeFont, layoutRect, (format is null ? Handle.init : format.nativeFormat), count, nativeRegions.ptr);
    if (status != Status.OK)
      throw statusException(status);

    return regions;
  }

  public void drawImage(Image image, PointF point) {
    drawImage(image, point.x, point.y);
  }

  public void drawImage(Image image, float x, float y) {
    if (image is null)
      throw new ArgumentNullException("image");

    Status status = GdipDrawImage(nativeGraphics_, image.nativeImage, x, y);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Draws the specified Image at the specified location and with the specified size.
   * Params:
   *   image = The Image to draw.
   *   rect = The location and size of the drawn _image.
   */
  public void drawImage(Image image, RectF rect) {
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
  public void drawImage(Image image, float x, float y, float width, float height) {
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
  public void drawImage(Image image, float x, float y, Rect srcRect, GraphicsUnit srcUnit) {
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
  public void drawImage(Image image, RectF destRect, float srcX, float srcY, float srcWidth, float srcHeight, GraphicsUnit srcUnit, ImageAttributes imageAttrs = null, DrawImageAbort callback = null, void* callbackData = null) {

    static DrawImageAbort callbackDelegate;

    extern(Windows) static int drawImageAbortCallback(void* callbackData) {
      return callbackDelegate(callbackData) ? 1 : 0;
    }

    if (image is null)
      throw new ArgumentNullException("image");

    callbackDelegate = callback;
    Status status = GdipDrawImageRectRect(nativeGraphics_, image.nativeImage, destRect.x, destRect.y, destRect.width, destRect.height, srcX, srcY, srcWidth, srcHeight, srcUnit, (imageAttrs is null ? Handle.init : imageAttrs.nativeImageAttributes), (callback == null ? null : &drawImageAbortCallback), callbackData);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawImage(Image image, PointF[] destPoints) {
    if (image is null)
      throw new ArgumentNullException("image");

    if (destPoints.length != 3 && destPoints.length != 4)
      throw new ArgumentException("Destination points must be an array with a length of 3 or 4.");

    Status status = GdipDrawImagePoints(nativeGraphics_, image.nativeImage, destPoints.ptr, destPoints.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawImage(Image image, PointF[] destPoints, RectF srcRect, GraphicsUnit srcUnit, ImageAttributes imageAttrs = null, DrawImageAbort callback = null, void* callbackData = null) {
    static DrawImageAbort callbackDelegate;

    extern(Windows) static int drawImageAbortCallback(void* callbackData) {
      return callbackDelegate(callbackData) ? 1 : 0;
    }

    if (image is null)
      throw new ArgumentNullException("image");

    if (destPoints.length != 3 && destPoints.length != 4)
      throw new ArgumentException("Destination points must be an array with a length of 3 or 4.");

   callbackDelegate = callback;
   Status status = GdipDrawImagePointsRect(nativeGraphics_, image.nativeImage, destPoints.ptr, destPoints.length, srcRect.x, srcRect.y, srcRect.width, srcRect.height, srcUnit, (imageAttrs is null ? Handle.init : imageAttrs.nativeImageAttributes), (callback == null ? null : &drawImageAbortCallback), callbackData);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Draws the specified Image, using its original physical size, at the specified location.
   * Params:
   *   image = The Image to draw.
   *   point = The location of the upper-left corner of the drawn _image.
   */
  public void drawImage(Image image, Point point) {
    drawImage(image, point.x, point.y);
  }

  /**
   * Draws the specified Image, using its original physical size, at the location specified by a coordinate pair.
   * Params:
   *   image = The Image to _draw.
   *   x = The x-coordinate of the upper-left corner of the drawn _image.
   *   y = The y-coordinate of the upper-left corner of the drawn _image.
   */
  public void drawImage(Image image, int x, int y) {
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
  public void drawImage(Image image, Rect rect) {
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
  public void drawImage(Image image, int x, int y, int width, int height) {
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
  public void drawImage(Image image, int x, int y, Rect srcRect, GraphicsUnit srcUnit) {
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
  public void drawImage(Image image, Rect destRect, int srcX, int srcY, int srcWidth, int srcHeight, GraphicsUnit srcUnit, ImageAttributes imageAttrs = null, DrawImageAbort callback = null, void* callbackData = null) {

    static DrawImageAbort callbackDelegate;

    extern(Windows) static int drawImageAbortCallback(void* callbackData) {
      return callbackDelegate(callbackData) ? 1 : 0;
    }

    if (image is null)
      throw new ArgumentNullException("image");

    callbackDelegate = callback;
    Status status = GdipDrawImageRectRectI(nativeGraphics_, image.nativeImage, destRect.x, destRect.y, destRect.width, destRect.height, srcX, srcY, srcWidth, srcHeight, srcUnit, (imageAttrs is null ? Handle.init : imageAttrs.nativeImageAttributes), (callback == null ? null : &drawImageAbortCallback), callbackData);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawImage(Image image, Point[] destPoints) {
    if (image is null)
      throw new ArgumentNullException("image");

    if (destPoints.length != 3 && destPoints.length != 4)
      throw new ArgumentException("Destination points must be an array with a length of 3 or 4.");

    Status status = GdipDrawImagePointsI(nativeGraphics_, image.nativeImage, destPoints.ptr, destPoints.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void drawImage(Image image, Point[] destPoints, Rect srcRect, GraphicsUnit srcUnit, ImageAttributes imageAttrs = null, DrawImageAbort callback = null, void* callbackData = null) {
    static DrawImageAbort callbackDelegate;

    extern(Windows) static int drawImageAbortCallback(void* callbackData) {
      return callbackDelegate(callbackData) ? 1 : 0;
    }

    if (image is null)
      throw new ArgumentNullException("image");

    if (destPoints.length != 3 && destPoints.length != 4)
      throw new ArgumentException("Destination points must be an array with a length of 3 or 4.");

   callbackDelegate = callback;
   Status status = GdipDrawImagePointsRectI(nativeGraphics_, image.nativeImage, destPoints.ptr, destPoints.length, srcRect.x, srcRect.y, srcRect.width, srcRect.height, srcUnit, (imageAttrs is null ? Handle.init : imageAttrs.nativeImageAttributes), (callback == null ? null : &drawImageAbortCallback), callbackData);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public float dpiX() {
    float dpi;
    Status status = GdipGetDpiX(nativeGraphics_, dpi);
    if (status != Status.OK)
      throw statusException(status);
    return dpi;
  }

  /**
   */
  public float dpiY() {
    float dpi;
    Status status = GdipGetDpiY(nativeGraphics_, dpi);
    if (status != Status.OK)
      throw statusException(status);
    return dpi;
  }

  /**
   */
  public void pageUnit(GraphicsUnit value) {
    Status status = GdipSetPageUnit(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Ditto
   */
  public GraphicsUnit pageUnit() {
    GraphicsUnit unit;
    Status status = GdipGetPageUnit(nativeGraphics_, unit);
    if (status != Status.OK)
      throw statusException(status);
    return unit;
  }

  /**
   */
  public void pageScale(float value) {
    Status status = GdipSetPageScale(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Ditto
   */
  public float pageScale() {
    float scale;
    Status status = GdipGetPageScale(nativeGraphics_, scale);
    if (status != Status.OK)
      throw statusException(status);
    return scale;
  }

  /**
   */
  public void transform(Matrix value) {
    Status status = GdipSetWorldTransform(nativeGraphics_, value.nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Ditto
   */
  public Matrix transform() {
    Matrix m = new Matrix;
    Status status = GdipGetWorldTransform(nativeGraphics_, m.nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
    return m;
  }

  public void compositingMode(CompositingMode value) {
    Status status = GdipSetCompositingMode(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  public CompositingMode compositingMode() {
    CompositingMode mode;
    Status status = GdipGetCompositingMode(nativeGraphics_, mode);
    if (status != Status.OK)
      throw statusException(status);
    return mode;
  }

  public void compositingQuality(CompositingQuality value) {
    Status status = GdipSetCompositingQuality(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  public CompositingQuality compositingQuality() {
    CompositingQuality value;
    Status status = GdipGetCompositingQuality(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  public void interpolationMode(InterpolationMode value) {
    Status status = GdipSetInterpolationMode(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Ditto
   */
  public InterpolationMode interpolationMode() {
    InterpolationMode mode = InterpolationMode.Default;
    Status status = GdipGetInterpolationMode(nativeGraphics_, mode);
    if (status != Status.OK)
      throw statusException(status);
    return mode;
  }

  /**
   */
  public void smoothingMode(SmoothingMode value) {
    Status status = GdipSetSmoothingMode(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Ditto
   */
  public SmoothingMode smoothingMode() {
    SmoothingMode mode = SmoothingMode.Default;
    Status status = GdipGetSmoothingMode(nativeGraphics_, mode);
    if (status != Status.OK)
      throw statusException(status);
    return mode;
  }

  public void pixelOffsetMode(PixelOffsetMode value) {
    Status status = GdipSetPixelOffsetMode(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  public PixelOffsetMode pixelOffsetMode() {
    PixelOffsetMode value;
    Status status = GdipGetPixelOffsetMode(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  public void textContrast(uint value) {
    Status status = GdipSetTextContrast(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Ditto
   */
  public uint textContrast() {
    uint contrast;
    Status status = GdipGetTextContrast(nativeGraphics_, contrast);
    if (status != Status.OK)
      throw statusException(status);
    return contrast;
  }

  /**
   */
  public void textRenderingHint(TextRenderingHint value) {
    Status status = GdipSetTextRenderingHint(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Ditto
   */
  public TextRenderingHint textRenderingHint() {
    TextRenderingHint value;
    Status status = GdipGetTextRenderingHint(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  public bool isClipEmpty() {
    int value;
    Status status = GdipIsClipEmpty(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value == 1;
  }

  /**
   */
  public bool isVisibleClipEmpty() {
    int value;
    Status status = GdipIsVisibleClipEmpty(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value == 1;
  }

  public void clip(Region value) {
    setClip(value, CombineMode.Replace);
  }

  public Region clip() {
    Region region = new Region;
    Status status = GdipGetClip(nativeGraphics_, region.nativeRegion_);
    if (status != Status.OK)
      throw statusException(status);
    return region;
  }

  /**
   */
  public RectF clipBounds() {
    RectF value;
    Status status = GdipGetClipBounds(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  public RectF visibleClipBounds() {
    RectF value;
    Status status = GdipGetVisibleClipBounds(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  public void renderingOrigin(Point value) {
    Status status = GdipGetRenderingOrigin(nativeGraphics_, value.x, value.y);
    if (status != Status.OK)
      throw statusException(status);
  }

  public Point renderingOrigin() {
    int x, y;
    Status status = GdipGetRenderingOrigin(nativeGraphics_, x, y);
    if (status != Status.OK)
      throw statusException(status);
    return Point(x, y);
  }

  private this(Handle nativeGraphics) {
    nativeGraphics_ = nativeGraphics;
  }

  ~this() {
    dispose();
  }

  package Handle nativeGraphics() {
    return nativeGraphics_;
  }

}

/**
 */
public abstract class Image {

  public alias bool delegate(void* callbackData) GetThumbnailImageAbort;

  private Handle nativeImage_;

  package Handle nativeImage() {
    return nativeImage_;
  }

  /**
   */
  private static Image createImage(Handle nativeImage) {
    int imageType = -1;
    Status status = GdipGetImageType(nativeImage, imageType);
    if (status != Status.OK)
      throw statusException(status);

    if (imageType == 1)
      return new Bitmap(nativeImage);
    else if (imageType == 2)
      return new Metafile(nativeImage);

    throw new ArgumentException("Image type is unknown.");
  }

  /**
   */
  public static Image fromFile(string fileName, bool useEmbeddedColorManagement = false) {
    string fullPath = getFullPath(fileName);

    Handle nativeImage;
    Status status = (useEmbeddedColorManagement ? GdipLoadImageFromFileICM(fileName.toUtf16z(), nativeImage) : GdipLoadImageFromFile(fileName.toUtf16z(), nativeImage));
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
  public static Image fromStream(Stream stream, bool useEmbeddedColorManagement = false) {
    auto s = new COMStream(stream);
    scope(exit) tryRelease(s);

    Handle nativeImage;
    Status status = (useEmbeddedColorManagement ? GdipLoadImageFromStreamICM(s, nativeImage) : GdipLoadImageFromStream(s, nativeImage));
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
  public static Bitmap fromHbitmap(Handle hbitmap, Handle hpalette = Handle.init) {
    Handle bitmap;
    Status status = GdipCreateBitmapFromHBITMAP(hbitmap, hpalette, bitmap);
    if (status != Status.OK)
      throw statusException(status);
    return new Bitmap(bitmap);
  }

  ~this() {
    dispose();
  }

  /**
   */
  public final void dispose() {
    if (nativeImage_ != Handle.init) {
      GdipDisposeImageSafe(nativeImage_);
      nativeImage_ = Handle.init;
    }
  }

  /**
   */
  public final Object clone() {
    Handle cloneImage;
    Status status = GdipCloneImage(nativeImage_, cloneImage);
    if (status != Status.OK)
      throw statusException(status);

    status = GdipImageForceValidation(cloneImage);
    if (status != Status.OK) {
      GdipDisposeImage(cloneImage);
      throw statusException(status);
    }

    return createImage(cloneImage);
  }

  public EncoderParameters getEncoderParameterList(GUID encoder) {
    uint size;
    Status status = GdipGetEncoderParameterListSize(nativeImage_, encoder, size);
    if (status != Status.OK)
      throw statusException(status);

    if (size <= 0)
      return null;

    GpEncoderParameters* ptr = cast(GpEncoderParameters*)HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, size);

    status = GdipGetEncoderParameterList(nativeImage_, encoder, size, ptr);
    if (status != Status.OK)
      throw statusException(status);

    EncoderParameters ret = new EncoderParameters(ptr);

    HeapFree(GetProcessHeap(), 0, ptr);

    return ret;
  }

  /**
   */
  public final void save(string fileName) {
    save(fileName, rawFormat);
  }

  /**
   */
  public final void save(string fileName, ImageFormat format) {
    ImageCodecInfo encoder = null;
    foreach (enc; ImageCodecInfo.getImageEncoders()) {
      if (enc.formatID == format.guid) {
        encoder = enc;
        break;
      }
    }
    if (encoder is null) {
      foreach (enc; ImageCodecInfo.getImageEncoders()) {
        if (enc.formatID == ImageFormat.png.guid) {
          encoder = enc;
          break;
        }
      }
    }
    save(fileName, encoder, null);
  }

  /**
   */
  public final void save(string fileName, ImageCodecInfo encoder, EncoderParameters encoderParams) {
    if (encoder is null)
      throw new ArgumentNullException("encoder");

    GpEncoderParameters* pEncoderParams = null;
    if (encoderParams !is null)
      pEncoderParams = encoderParams.forGDIplus();

    GUID clsidEncoder = encoder.clsid;
    Status status = GdipSaveImageToFile(nativeImage_, fileName.toUtf16z(), clsidEncoder, pEncoderParams);

    if (pEncoderParams !is null)
      HeapFree(GetProcessHeap(), 0, pEncoderParams);

    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public final void save(Stream stream, ImageFormat format) {
    if (format is null)
      throw new ArgumentNullException("format");

    ImageCodecInfo encoder = null;
    foreach (enc; ImageCodecInfo.getImageEncoders()) {
      if (enc.formatID == format.guid) {
        encoder = enc;
        break;
      }
    }

    save(stream, encoder, null);
  }

  /**
   */
  public final void save(Stream stream, ImageCodecInfo encoder, EncoderParameters encoderParams) {
    if (stream is null)
      throw new ArgumentNullException("stream");
    if (encoder is null)
      throw new ArgumentNullException("encoder");

    GpEncoderParameters* pEncoderParams = null;
    if (encoderParams !is null)
      pEncoderParams = encoderParams.forGDIplus();

    auto s = new COMStream(stream);
    scope(exit) tryRelease(s);

    GUID clsidEncoder = encoder.clsid;
    Status status = GdipSaveImageToStream(nativeImage_, s, clsidEncoder, pEncoderParams);

    if (pEncoderParams !is null)
      HeapFree(GetProcessHeap(), 0, pEncoderParams);

    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public final void saveAdd(EncoderParameters encoderParams) {
    GpEncoderParameters* pEncoderParams = null;
    if (encoderParams !is null)
      pEncoderParams = encoderParams.forGDIplus();

    Status status = GdipSaveAdd(nativeImage_, pEncoderParams);

    if (pEncoderParams !is null)
      HeapFree(GetProcessHeap(), 0, pEncoderParams);

    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public final void saveAdd(Image image, EncoderParameters encoderParams) {
    if (image is null)
      throw new ArgumentNullException("image");

    GpEncoderParameters* pEncoderParams = null;
    if (encoderParams !is null)
      pEncoderParams = encoderParams.forGDIplus();

    Status status = GdipSaveAddImage(nativeImage_, image.nativeImage_, pEncoderParams);

    if (pEncoderParams !is null)
      HeapFree(GetProcessHeap(), 0, pEncoderParams);

    if (status != Status.OK)
      throw statusException(status);
  }

  public RectF getBounds(ref GraphicsUnit pageUnit) {
    RectF rect;
    Status status = GdipGetImageBounds(nativeImage_, rect, pageUnit);
    if (status != Status.OK)
      throw statusException(status);
    return rect;
  }

  /**
   */
  public final Image getThumbnailImage(int thumbWidth, int thumbHeight, GetThumbnailImageAbort callback, void* callbackData) {

    static GetThumbnailImageAbort callbackDelegate;

    extern(Windows) static int getThumbnailImageCallback(void* callbackData) {
      return callbackDelegate(callbackData) ? 1 : 0;
    }

    callbackDelegate = callback;

    Handle thumbImage;
    Status status = GdipGetImageThumbnail(nativeImage_, thumbWidth, thumbHeight, thumbImage, (callback == null ? null : &getThumbnailImageCallback), callbackData);
    if (status != Status.OK)
      throw statusException(status);

    return createImage(thumbImage);
  }

  /**
   */
  public final int getFrameCount(FrameDimension dimension) {
    GUID dimensionID = dimension.guid;
    int count;
    Status status = GdipImageGetFrameCount(nativeImage_, dimensionID, count);
    if (status != Status.OK)
      throw statusException(status);
    return count;
  }

  /**
   */
  public final void selectActiveFrame(FrameDimension dimension, int frameIndex) {
    GUID dimensionID = dimension.guid;
    Status status = GdipImageSelectActiveFrame(nativeImage_, dimensionID, frameIndex);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public final void rotateFlip(RotateFlipType rotateFlipType) {
    Status status = GdipImageRotateFlip(nativeImage_, rotateFlipType);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public final PropertyItem getPropertyItem(int propId) {
    uint sz;
    Status status = GdipGetPropertyItemSize(nativeImage_, propId, sz);
    if (status != Status.OK)
      throw statusException(status);

    if (sz == 0)
      return null;

    GpPropertyItem* buffer = cast(GpPropertyItem*)HeapAlloc(GetProcessHeap(), 0, sz);
    status = GdipGetPropertyItem(nativeImage_, propId, sz, buffer);
    if (status != Status.OK)
      throw statusException(status);

    PropertyItem item = new PropertyItem;
    item.id = buffer.id;
    item.length = buffer.length;
    item.type = buffer.type;
    item.value = cast(ubyte[])buffer.value[0 .. buffer.length];

    HeapFree(GetProcessHeap(), 0, buffer);

    return item;
  }

  public final void removePropertyItem(int propId) {
    Status status = GdipRemovePropertyItem(nativeImage_, propId);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public final void setPropertyItem(PropertyItem propItem) {
    GpPropertyItem item;
    item.id = propItem.id;
    item.length = propItem.length;
    item.type = propItem.type;
    item.value = propItem.value.ptr;

    Status status = GdipSetPropertyItem(nativeImage_, item);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public final SizeF physicalDimension() {
    float width, height;
    Status status = GdipGetImageDimension(nativeImage_, width, height);
    if (status != Status.OK)
      throw statusException(status);
    return SizeF(width, height);
  }

  /**
   */
  public final int width() {
    int value;
    Status status = GdipGetImageWidth(nativeImage_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  public final int height() {
    int value;
    Status status = GdipGetImageHeight(nativeImage_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  public final Size size() {
    return Size(width, height);
  }

  /**
   */
  public final float horizontalResolution() {
    float resolution;
    Status status = GdipGetImageHorizontalResolution(nativeImage_, resolution);
    if (status != Status.OK)
      throw statusException(status);
    return resolution;
  }

  /**
   */
  public final float verticalResolution() {
    float resolution;
    Status status = GdipGetImageVerticalResolution(nativeImage_, resolution);
    if (status != Status.OK)
      throw statusException(status);
    return resolution;
  }

  /**
   */
  public final int flags() {
    int value;
    Status status = GdipGetImageFlags(nativeImage_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  public final ImageFormat rawFormat() {
    GUID format;
    Status status = GdipGetImageRawFormat(nativeImage_, format);
    if (status != Status.OK)
      throw statusException(status);
    return new ImageFormat(format);
  }

  /**
   */
  public final PixelFormat pixelFormat() {
    PixelFormat value;
    Status status = GdipGetImagePixelFormat(nativeImage_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  public final void palette(ColorPalette value) {
    GpColorPalette* p = value.forGDIplus();
    Status status = GdipSetImagePalette(nativeImage_, p);
    if (status != Status.OK)
      throw statusException(status);
    if (p != null)
      HeapFree(GetProcessHeap(), 0, p);
  }

  public final ColorPalette palette() {
    int size;
    Status status = GdipGetImagePaletteSize(nativeImage_, size);
    if (status != Status.OK)
      throw statusException(status);

    GpColorPalette* ptr = cast(GpColorPalette*)HeapAlloc(GetProcessHeap(), 0, size);

    status = GdipGetImagePalette(nativeImage_, ptr, size);
    if (status != Status.OK)
      throw statusException(status);

    ColorPalette ret = new ColorPalette(ptr);
    HeapFree(GetProcessHeap(), 0, ptr);
    return ret;
  }

  /**
   */
  public final GUID[] frameDimensionsList() {
    int count;
    Status status = GdipImageGetFrameDimensionsCount(nativeImage_, count);
    if (status != Status.OK)
      throw statusException(status);

    if (count <= 0) return new GUID[0];

    GUID[] dimensionIDs = new GUID[count];

    status = GdipImageGetFrameDimensionsList(nativeImage_, dimensionIDs.ptr, count);
    if (status != Status.OK)
      throw statusException(status);

    return dimensionIDs;
  }

  /**
   */
  public final int[] propertyIdList() {
    int num;
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
  public final PropertyItem[] propertyItems() {
    int num;
    Status status = GdipGetPropertyCount(nativeImage_, num);
    if (status != Status.OK)
      throw statusException(status);

    uint sz;
    status = GdipGetPropertySize(nativeImage_, sz, num);
    if (status != Status.OK)
      throw statusException(status);

    if (num == 0 || sz == 0)
      return new PropertyItem[0];

    GpPropertyItem* allItems = cast(GpPropertyItem*)HeapAlloc(GetProcessHeap(), 0, sz);
    status = GdipGetAllPropertyItems(nativeImage_, sz, num, allItems);
    if (status != Status.OK)
      throw statusException(status);

    PropertyItem[] ret = new PropertyItem[num];

    for (int i = 0; i < num; i++) {
      ret[i] = new PropertyItem;
      ret[i].id = allItems[i].id;
      ret[i].length = allItems[i].length;
      ret[i].type = allItems[i].type;
      ret[i].value = cast(ubyte[])allItems[i].value[0 .. allItems[i].length];
    }

    HeapFree(GetProcessHeap(), 0, allItems);

    return ret;
  }

}

/**
 */
public final class Bitmap : Image {

  /**
   */
  public this(string fileName, bool useEmbeddedColorManagement = false) {
    string fullPath = getFullPath(fileName);

    Status status = (useEmbeddedColorManagement ? GdipCreateBitmapFromFileICM(fullPath.toUtf16z(), nativeImage_) : GdipCreateBitmapFromFile(fullPath.toUtf16z(), nativeImage_));
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
  public this(Stream stream, bool useEmbeddedColorManagement = false) {
    if (stream is null)
      throw new ArgumentNullException("stream");

    auto s = new COMStream(stream);
    scope(exit) tryRelease(s);

    Status status = (useEmbeddedColorManagement ? GdipCreateBitmapFromStreamICM(s, nativeImage_) : GdipCreateBitmapFromStream(s, nativeImage_));
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
  public this(Image original) {
    this(original, original.width, original.height);
  }

  /**
   */
  public this(Image original, int width, int height) {
    this(width, height);

    scope g = Graphics.fromImage(this);
    g.clear(Color.transparent);
    g.drawImage(original, 0, 0, width, height);
  }

  /**
   */
  public this(Image original, Size size) {
    this(original, size.width, size.height);
  }

  /**
   */
  public this(int width, int height, PixelFormat format = PixelFormat.Format32bppArgb) {
    Status status = GdipCreateBitmapFromScan0(width, height, 0, format, null, nativeImage_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public this(Size size) {
    this(size.width, size.height);
  }

  /**
   */
  public this(int width, int height, int stride, PixelFormat format, ubyte* scan0) {
    Status status = GdipCreateBitmapFromScan0(width, height, stride, format, scan0, nativeImage_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public this(int width, int height, Graphics g) {
    if (g is null)
      throw new ArgumentNullException("g");

    Status status = GdipCreateBitmapFromGraphics(width, height, g.nativeGraphics_, nativeImage_);
    if (status != Status.OK)
      throw statusException(status);
  }

  public static Bitmap fromHicon(Handle hicon) {
    Handle bitmap;
    Status status = GdipCreateBitmapFromHICON(hicon, bitmap);
    if (status != Status.OK)
      throw statusException(status);
    return new Bitmap(bitmap);
  }

  public Handle getHicon() {
    Handle hicon;
    Status status = GdipCreateHICONFromBitmap(nativeImage_, hicon);
    if (status != Status.OK)
      throw statusException(status);
    return hicon;
  }

  /**
   */
  public Handle getHbitmap(Color background = Color.lightGray) {
    Handle hbitmap;
    Status status = GdipCreateHBITMAPFromBitmap(nativeImage_, hbitmap, background.toRgb());
    if (status != Status.OK)
      throw statusException(status);
    return hbitmap;
  }

  /**
   */
  public Bitmap clone(Rect rect, PixelFormat format) {
    Handle bitmap;
    Status status = GdipCloneBitmapAreaI(rect.x, rect.y, rect.width, rect.height, format, nativeImage_, bitmap);
    if (status != Status.OK)
      throw statusException(status);

    return new Bitmap(bitmap);
  }

  /**
   */
  public Bitmap clone(RectF rect, PixelFormat format) {
    Handle bitmap;
    Status status = GdipCloneBitmapArea(rect.x, rect.y, rect.width, rect.height, format, nativeImage_, bitmap);
    if (status != Status.OK)
      throw statusException(status);

    return new Bitmap(bitmap);
  }

  /**
   */
  public BitmapData lockBits(Rect rect, ImageLockMode flags, PixelFormat format, BitmapData bitmapData = null) {
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
  public void unlockBits(BitmapData bitmapData) {
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
  public Color getPixel(int x, int y) {
    int color;
    Status status = GdipBitmapGetPixel(nativeImage_, x, y, color);
    if (status != Status.OK)
      throw statusException(status);
    return Color.fromArgb(color);
  }

  /**
   */
  public void setPixel(int x, int y, Color color) {
    Status status = GdipBitmapSetPixel(nativeImage_, x, y, color.toArgb());
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void setResolution(float xdpi, float ydpi) {
    Status status = GdipBitmapSetResolution(nativeImage_, xdpi, ydpi);
    if (status != Status.OK)
      throw statusException(status);
  }

  package this(Handle handle) {
    nativeImage_ = handle;
  }

}

public final class Metafile : Image {

  package this(Handle handle) {
    nativeImage_ = handle;
  }

}

/**
 */
public abstract class Brush {

  private static Brush[Color] brushes_;
  private static Brush[] systemBrushes_;

  private Handle nativeBrush_;

  static ~this() {
    brushes_ = null;
    systemBrushes_ = null;
  }

  ~this() {
    dispose();
  }

  /**
   */
  public final void dispose() {
    if (nativeBrush_ != Handle.init) {
      GdipDeleteBrushSafe(nativeBrush_);
      nativeBrush_ = Handle.init;
    }
  }
  
  ///
  public static Brush transparent() {
    if (!(Color.transparent in brushes_))
      brushes_[Color.transparent] = new SolidBrush(Color.transparent);
    return brushes_[Color.transparent];
  }
  ///
  public static Brush aliceBlue() {
    if (!(Color.aliceBlue in brushes_))
      brushes_[Color.aliceBlue] = new SolidBrush(Color.aliceBlue);
    return brushes_[Color.aliceBlue];
  }
  ///
  public static Brush antiqueWhite() {
    if (!(Color.antiqueWhite in brushes_))
      brushes_[Color.antiqueWhite] = new SolidBrush(Color.antiqueWhite);
    return brushes_[Color.antiqueWhite];
  }
  ///
  public static Brush aqua() {
    if (!(Color.aqua in brushes_))
      brushes_[Color.aqua] = new SolidBrush(Color.aqua);
    return brushes_[Color.aqua];
  }
  ///
  public static Brush aquamarine() {
    if (!(Color.aquamarine in brushes_))
      brushes_[Color.aquamarine] = new SolidBrush(Color.aquamarine);
    return brushes_[Color.aquamarine];
  }
  ///
  public static Brush azure() {
    if (!(Color.azure in brushes_))
      brushes_[Color.azure] = new SolidBrush(Color.azure);
    return brushes_[Color.azure];
  }
  ///
  public static Brush beige() {
    if (!(Color.beige in brushes_))
      brushes_[Color.beige] = new SolidBrush(Color.beige);
    return brushes_[Color.beige];
  }
  ///
  public static Brush bisque() {
    if (!(Color.bisque in brushes_))
      brushes_[Color.bisque] = new SolidBrush(Color.bisque);
    return brushes_[Color.bisque];
  }
  ///
  public static Brush black() {
    if (!(Color.black in brushes_))
      brushes_[Color.black] = new SolidBrush(Color.black);
    return brushes_[Color.black];
  }
  ///
  public static Brush blanchedAlmond() {
    if (!(Color.blanchedAlmond in brushes_))
      brushes_[Color.blanchedAlmond] = new SolidBrush(Color.blanchedAlmond);
    return brushes_[Color.blanchedAlmond];
  }
  ///
  public static Brush blue() {
    if (!(Color.blue in brushes_))
      brushes_[Color.blue] = new SolidBrush(Color.blue);
    return brushes_[Color.blue];
  }
  ///
  public static Brush blueViolet() {
    if (!(Color.blueViolet in brushes_))
      brushes_[Color.blueViolet] = new SolidBrush(Color.blueViolet);
    return brushes_[Color.blueViolet];
  }
  ///
  public static Brush brown() {
    if (!(Color.brown in brushes_))
      brushes_[Color.brown] = new SolidBrush(Color.brown);
    return brushes_[Color.brown];
  }
  ///
  public static Brush burlyWood() {
    if (!(Color.burlyWood in brushes_))
      brushes_[Color.burlyWood] = new SolidBrush(Color.burlyWood);
    return brushes_[Color.burlyWood];
  }
  ///
  public static Brush cadetBlue() {
    if (!(Color.cadetBlue in brushes_))
      brushes_[Color.cadetBlue] = new SolidBrush(Color.cadetBlue);
    return brushes_[Color.cadetBlue];
  }
  ///
  public static Brush chartreuse() {
    if (!(Color.chartreuse in brushes_))
      brushes_[Color.chartreuse] = new SolidBrush(Color.chartreuse);
    return brushes_[Color.chartreuse];
  }
  ///
  public static Brush chocolate() {
    if (!(Color.chocolate in brushes_))
      brushes_[Color.chocolate] = new SolidBrush(Color.chocolate);
    return brushes_[Color.chocolate];
  }
  ///
  public static Brush coral() {
    if (!(Color.coral in brushes_))
      brushes_[Color.coral] = new SolidBrush(Color.coral);
    return brushes_[Color.coral];
  }
  ///
  public static Brush cornflowerBlue() {
    if (!(Color.cornflowerBlue in brushes_))
      brushes_[Color.cornflowerBlue] = new SolidBrush(Color.cornflowerBlue);
    return brushes_[Color.cornflowerBlue];
  }
  ///
  public static Brush cornsilk() {
    if (!(Color.cornsilk in brushes_))
      brushes_[Color.cornsilk] = new SolidBrush(Color.cornsilk);
    return brushes_[Color.cornsilk];
  }
  ///
  public static Brush crimson() {
    if (!(Color.crimson in brushes_))
      brushes_[Color.crimson] = new SolidBrush(Color.crimson);
    return brushes_[Color.crimson];
  }
  ///
  public static Brush cyan() {
    if (!(Color.cyan in brushes_))
      brushes_[Color.cyan] = new SolidBrush(Color.cyan);
    return brushes_[Color.cyan];
  }
  ///
  public static Brush darkBlue() {
    if (!(Color.darkBlue in brushes_))
      brushes_[Color.darkBlue] = new SolidBrush(Color.darkBlue);
    return brushes_[Color.darkBlue];
  }
  ///
  public static Brush darkCyan() {
    if (!(Color.darkCyan in brushes_))
      brushes_[Color.darkCyan] = new SolidBrush(Color.darkCyan);
    return brushes_[Color.darkCyan];
  }
  ///
  public static Brush darkGoldenrod() {
    if (!(Color.darkGoldenrod in brushes_))
      brushes_[Color.darkGoldenrod] = new SolidBrush(Color.darkGoldenrod);
    return brushes_[Color.darkGoldenrod];
  }
  ///
  public static Brush darkGray() {
    if (!(Color.darkGray in brushes_))
      brushes_[Color.darkGray] = new SolidBrush(Color.darkGray);
    return brushes_[Color.darkGray];
  }
  ///
  public static Brush darkGreen() {
    if (!(Color.darkGreen in brushes_))
      brushes_[Color.darkGreen] = new SolidBrush(Color.darkGreen);
    return brushes_[Color.darkGreen];
  }
  ///
  public static Brush darkKhaki() {
    if (!(Color.darkKhaki in brushes_))
      brushes_[Color.darkKhaki] = new SolidBrush(Color.darkKhaki);
    return brushes_[Color.darkKhaki];
  }
  ///
  public static Brush darkMagenta() {
    if (!(Color.darkMagenta in brushes_))
      brushes_[Color.darkMagenta] = new SolidBrush(Color.darkMagenta);
    return brushes_[Color.darkMagenta];
  }
  ///
  public static Brush darkOliveGreen() {
    if (!(Color.darkOliveGreen in brushes_))
      brushes_[Color.darkOliveGreen] = new SolidBrush(Color.darkOliveGreen);
    return brushes_[Color.darkOliveGreen];
  }
  ///
  public static Brush darkOrange() {
    if (!(Color.darkOrange in brushes_))
      brushes_[Color.darkOrange] = new SolidBrush(Color.darkOrange);
    return brushes_[Color.darkOrange];
  }
  ///
  public static Brush darkOrchid() {
    if (!(Color.darkOrchid in brushes_))
      brushes_[Color.darkOrchid] = new SolidBrush(Color.darkOrchid);
    return brushes_[Color.darkOrchid];
  }
  ///
  public static Brush darkRed() {
    if (!(Color.darkRed in brushes_))
      brushes_[Color.darkRed] = new SolidBrush(Color.darkRed);
    return brushes_[Color.darkRed];
  }
  ///
  public static Brush darkSalmon() {
    if (!(Color.darkSalmon in brushes_))
      brushes_[Color.darkSalmon] = new SolidBrush(Color.darkSalmon);
    return brushes_[Color.darkSalmon];
  }
  ///
  public static Brush darkSeaGreen() {
    if (!(Color.darkSeaGreen in brushes_))
      brushes_[Color.darkSeaGreen] = new SolidBrush(Color.darkSeaGreen);
    return brushes_[Color.darkSeaGreen];
  }
  ///
  public static Brush darkSlateBlue() {
    if (!(Color.darkSlateBlue in brushes_))
      brushes_[Color.darkSlateBlue] = new SolidBrush(Color.darkSlateBlue);
    return brushes_[Color.darkSlateBlue];
  }
  ///
  public static Brush darkSlateGray() {
    if (!(Color.darkSlateGray in brushes_))
      brushes_[Color.darkSlateGray] = new SolidBrush(Color.darkSlateGray);
    return brushes_[Color.darkSlateGray];
  }
  ///
  public static Brush darkTurquoise() {
    if (!(Color.darkTurquoise in brushes_))
      brushes_[Color.darkTurquoise] = new SolidBrush(Color.darkTurquoise);
    return brushes_[Color.darkTurquoise];
  }
  ///
  public static Brush darkViolet() {
    if (!(Color.darkViolet in brushes_))
      brushes_[Color.darkViolet] = new SolidBrush(Color.darkViolet);
    return brushes_[Color.darkViolet];
  }
  ///
  public static Brush deepPink() {
    if (!(Color.deepPink in brushes_))
      brushes_[Color.deepPink] = new SolidBrush(Color.deepPink);
    return brushes_[Color.deepPink];
  }
  ///
  public static Brush deepSkyBlue() {
    if (!(Color.deepSkyBlue in brushes_))
      brushes_[Color.deepSkyBlue] = new SolidBrush(Color.deepSkyBlue);
    return brushes_[Color.deepSkyBlue];
  }
  ///
  public static Brush dimGray() {
    if (!(Color.dimGray in brushes_))
      brushes_[Color.dimGray] = new SolidBrush(Color.dimGray);
    return brushes_[Color.dimGray];
  }
  ///
  public static Brush dodgerBlue() {
    if (!(Color.dodgerBlue in brushes_))
      brushes_[Color.dodgerBlue] = new SolidBrush(Color.dodgerBlue);
    return brushes_[Color.dodgerBlue];
  }
  ///
  public static Brush firebrick() {
    if (!(Color.firebrick in brushes_))
      brushes_[Color.firebrick] = new SolidBrush(Color.firebrick);
    return brushes_[Color.firebrick];
  }
  ///
  public static Brush floralWhite() {
    if (!(Color.floralWhite in brushes_))
      brushes_[Color.floralWhite] = new SolidBrush(Color.floralWhite);
    return brushes_[Color.floralWhite];
  }
  ///
  public static Brush forestGreen() {
    if (!(Color.forestGreen in brushes_))
      brushes_[Color.forestGreen] = new SolidBrush(Color.forestGreen);
    return brushes_[Color.forestGreen];
  }
  ///
  public static Brush fuchsia() {
    if (!(Color.fuchsia in brushes_))
      brushes_[Color.fuchsia] = new SolidBrush(Color.fuchsia);
    return brushes_[Color.fuchsia];
  }
  ///
  public static Brush gainsboro() {
    if (!(Color.gainsboro in brushes_))
      brushes_[Color.gainsboro] = new SolidBrush(Color.gainsboro);
    return brushes_[Color.gainsboro];
  }
  ///
  public static Brush ghostWhite() {
    if (!(Color.ghostWhite in brushes_))
      brushes_[Color.ghostWhite] = new SolidBrush(Color.ghostWhite);
    return brushes_[Color.ghostWhite];
  }
  ///
  public static Brush gold() {
    if (!(Color.gold in brushes_))
      brushes_[Color.gold] = new SolidBrush(Color.gold);
    return brushes_[Color.gold];
  }
  ///
  public static Brush gray() {
    if (!(Color.gray in brushes_))
      brushes_[Color.gray] = new SolidBrush(Color.gray);
    return brushes_[Color.gray];
  }
  ///
  public static Brush green() {
    if (!(Color.green in brushes_))
      brushes_[Color.green] = new SolidBrush(Color.green);
    return brushes_[Color.green];
  }
  ///
  public static Brush greenYellow() {
    if (!(Color.greenYellow in brushes_))
      brushes_[Color.greenYellow] = new SolidBrush(Color.greenYellow);
    return brushes_[Color.greenYellow];
  }
  ///
  public static Brush honeydew() {
    if (!(Color.honeydew in brushes_))
      brushes_[Color.honeydew] = new SolidBrush(Color.honeydew);
    return brushes_[Color.honeydew];
  }
  ///
  public static Brush hotPink() {
    if (!(Color.hotPink in brushes_))
      brushes_[Color.hotPink] = new SolidBrush(Color.hotPink);
    return brushes_[Color.hotPink];
  }
  ///
  public static Brush indianRed() {
    if (!(Color.indianRed in brushes_))
      brushes_[Color.indianRed] = new SolidBrush(Color.indianRed);
    return brushes_[Color.indianRed];
  }
  ///
  public static Brush indigo() {
    if (!(Color.indigo in brushes_))
      brushes_[Color.indigo] = new SolidBrush(Color.indigo);
    return brushes_[Color.indigo];
  }
  ///
  public static Brush ivory() {
    if (!(Color.ivory in brushes_))
      brushes_[Color.ivory] = new SolidBrush(Color.ivory);
    return brushes_[Color.ivory];
  }
  ///
  public static Brush khaki() {
    if (!(Color.khaki in brushes_))
      brushes_[Color.khaki] = new SolidBrush(Color.khaki);
    return brushes_[Color.khaki];
  }
  ///
  public static Brush lavender() {
    if (!(Color.lavender in brushes_))
      brushes_[Color.lavender] = new SolidBrush(Color.lavender);
    return brushes_[Color.lavender];
  }
  ///
  public static Brush lavenderBlush() {
    if (!(Color.lavenderBlush in brushes_))
      brushes_[Color.lavenderBlush] = new SolidBrush(Color.lavenderBlush);
    return brushes_[Color.lavenderBlush];
  }
  ///
  public static Brush lawnGreen() {
    if (!(Color.lawnGreen in brushes_))
      brushes_[Color.lawnGreen] = new SolidBrush(Color.lawnGreen);
    return brushes_[Color.lawnGreen];
  }
  ///
  public static Brush lemonChiffon() {
    if (!(Color.lemonChiffon in brushes_))
      brushes_[Color.lemonChiffon] = new SolidBrush(Color.lemonChiffon);
    return brushes_[Color.lemonChiffon];
  }
  ///
  public static Brush lightBlue() {
    if (!(Color.lightBlue in brushes_))
      brushes_[Color.lightBlue] = new SolidBrush(Color.lightBlue);
    return brushes_[Color.lightBlue];
  }
  ///
  public static Brush lightCoral() {
    if (!(Color.lightCoral in brushes_))
      brushes_[Color.lightCoral] = new SolidBrush(Color.lightCoral);
    return brushes_[Color.lightCoral];
  }
  ///
  public static Brush lightCyan() {
    if (!(Color.lightCyan in brushes_))
      brushes_[Color.lightCyan] = new SolidBrush(Color.lightCyan);
    return brushes_[Color.lightCyan];
  }
  ///
  public static Brush lightGoldenrodYellow() {
    if (!(Color.lightGoldenrodYellow in brushes_))
      brushes_[Color.lightGoldenrodYellow] = new SolidBrush(Color.lightGoldenrodYellow);
    return brushes_[Color.lightGoldenrodYellow];
  }
  ///
  public static Brush lightGreen() {
    if (!(Color.lightGreen in brushes_))
      brushes_[Color.lightGreen] = new SolidBrush(Color.lightGreen);
    return brushes_[Color.lightGreen];
  }
  ///
  public static Brush lightGray() {
    if (!(Color.lightGray in brushes_))
      brushes_[Color.lightGray] = new SolidBrush(Color.lightGray);
    return brushes_[Color.lightGray];
  }
  ///
  public static Brush lightPink() {
    if (!(Color.lightPink in brushes_))
      brushes_[Color.lightPink] = new SolidBrush(Color.lightPink);
    return brushes_[Color.lightPink];
  }
  ///
  public static Brush lightSalmon() {
    if (!(Color.lightSalmon in brushes_))
      brushes_[Color.lightSalmon] = new SolidBrush(Color.lightSalmon);
    return brushes_[Color.lightSalmon];
  }
  ///
  public static Brush lightSeaGreen() {
    if (!(Color.lightSeaGreen in brushes_))
      brushes_[Color.lightSeaGreen] = new SolidBrush(Color.lightSeaGreen);
    return brushes_[Color.lightSeaGreen];
  }
  ///
  public static Brush lightSkyBlue() {
    if (!(Color.lightSkyBlue in brushes_))
      brushes_[Color.lightSkyBlue] = new SolidBrush(Color.lightSkyBlue);
    return brushes_[Color.lightSkyBlue];
  }
  ///
  public static Brush lightSlateGray() {
    if (!(Color.lightSlateGray in brushes_))
      brushes_[Color.lightSlateGray] = new SolidBrush(Color.lightSlateGray);
    return brushes_[Color.lightSlateGray];
  }
  ///
  public static Brush lightSteelBlue() {
    if (!(Color.lightSteelBlue in brushes_))
      brushes_[Color.lightSteelBlue] = new SolidBrush(Color.lightSteelBlue);
    return brushes_[Color.lightSteelBlue];
  }
  ///
  public static Brush lightYellow() {
    if (!(Color.lightYellow in brushes_))
      brushes_[Color.lightYellow] = new SolidBrush(Color.lightYellow);
    return brushes_[Color.lightYellow];
  }
  ///
  public static Brush lime() {
    if (!(Color.lime in brushes_))
      brushes_[Color.lime] = new SolidBrush(Color.lime);
    return brushes_[Color.lime];
  }
  ///
  public static Brush limeGreen() {
    if (!(Color.limeGreen in brushes_))
      brushes_[Color.limeGreen] = new SolidBrush(Color.limeGreen);
    return brushes_[Color.limeGreen];
  }
  ///
  public static Brush linen() {
    if (!(Color.linen in brushes_))
      brushes_[Color.linen] = new SolidBrush(Color.linen);
    return brushes_[Color.linen];
  }
  ///
  public static Brush magenta() {
    if (!(Color.magenta in brushes_))
      brushes_[Color.magenta] = new SolidBrush(Color.magenta);
    return brushes_[Color.magenta];
  }
  ///
  public static Brush maroon() {
    if (!(Color.maroon in brushes_))
      brushes_[Color.maroon] = new SolidBrush(Color.maroon);
    return brushes_[Color.maroon];
  }
  ///
  public static Brush mediumAquamarine() {
    if (!(Color.mediumAquamarine in brushes_))
      brushes_[Color.mediumAquamarine] = new SolidBrush(Color.mediumAquamarine);
    return brushes_[Color.mediumAquamarine];
  }
  ///
  public static Brush mediumBlue() {
    if (!(Color.mediumBlue in brushes_))
      brushes_[Color.mediumBlue] = new SolidBrush(Color.mediumBlue);
    return brushes_[Color.mediumBlue];
  }
  ///
  public static Brush mediumOrchid() {
    if (!(Color.mediumOrchid in brushes_))
      brushes_[Color.mediumOrchid] = new SolidBrush(Color.mediumOrchid);
    return brushes_[Color.mediumOrchid];
  }
  ///
  public static Brush mediumPurple() {
    if (!(Color.mediumPurple in brushes_))
      brushes_[Color.mediumPurple] = new SolidBrush(Color.mediumPurple);
    return brushes_[Color.mediumPurple];
  }
  ///
  public static Brush mediumSeaGreen() {
    if (!(Color.mediumSeaGreen in brushes_))
      brushes_[Color.mediumSeaGreen] = new SolidBrush(Color.mediumSeaGreen);
    return brushes_[Color.mediumSeaGreen];
  }
  ///
  public static Brush mediumSlateBlue() {
    if (!(Color.mediumSlateBlue in brushes_))
      brushes_[Color.mediumSlateBlue] = new SolidBrush(Color.mediumSlateBlue);
    return brushes_[Color.mediumSlateBlue];
  }
  ///
  public static Brush mediumSpringGreen() {
    if (!(Color.mediumSpringGreen in brushes_))
      brushes_[Color.mediumSpringGreen] = new SolidBrush(Color.mediumSpringGreen);

    return brushes_[Color.mediumSpringGreen];
  }
  ///
  public static Brush mediumTurquoise() {
    if (!(Color.mediumTurquoise in brushes_))
      brushes_[Color.mediumTurquoise] = new SolidBrush(Color.mediumTurquoise);
    return brushes_[Color.mediumTurquoise];
  }
  ///
  public static Brush mediumVioletRed() {
    if (!(Color.mediumVioletRed in brushes_))
      brushes_[Color.mediumVioletRed] = new SolidBrush(Color.mediumVioletRed);
    return brushes_[Color.mediumVioletRed];
  }
  ///
  public static Brush midnightBlue() {
    if (!(Color.midnightBlue in brushes_))
      brushes_[Color.midnightBlue] = new SolidBrush(Color.midnightBlue);
    return brushes_[Color.midnightBlue];
  }
  ///
  public static Brush mintCream() {
    if (!(Color.mintCream in brushes_))
      brushes_[Color.mintCream] = new SolidBrush(Color.mintCream);
    return brushes_[Color.mintCream];
  }
  ///
  public static Brush mistyRose() {
    if (!(Color.mistyRose in brushes_))
      brushes_[Color.mistyRose] = new SolidBrush(Color.mistyRose);
    return brushes_[Color.mistyRose];
  }
  ///
  public static Brush moccasin() {
    if (!(Color.moccasin in brushes_))
      brushes_[Color.moccasin] = new SolidBrush(Color.moccasin);
    return brushes_[Color.moccasin];
  }
  ///
  public static Brush navajoWhite() {
    if (!(Color.navajoWhite in brushes_))
      brushes_[Color.navajoWhite] = new SolidBrush(Color.navajoWhite);
    return brushes_[Color.navajoWhite];
  }
  ///
  public static Brush navy() {
    if (!(Color.navy in brushes_))
      brushes_[Color.navy] = new SolidBrush(Color.navy);
    return brushes_[Color.navy];
  }
  ///
  public static Brush oldLace() {
    if (!(Color.oldLace in brushes_))
      brushes_[Color.oldLace] = new SolidBrush(Color.oldLace);
    return brushes_[Color.oldLace];
  }
  ///
  public static Brush olive() {
    if (!(Color.olive in brushes_))
      brushes_[Color.olive] = new SolidBrush(Color.olive);
    return brushes_[Color.olive];
  }
  ///
  public static Brush oliveDrab() {
    if (!(Color.oliveDrab in brushes_))
      brushes_[Color.oliveDrab] = new SolidBrush(Color.oliveDrab);
    return brushes_[Color.oliveDrab];
  }
  ///
  public static Brush orangeRed() {
    if (!(Color.orangeRed in brushes_))
      brushes_[Color.orangeRed] = new SolidBrush(Color.orangeRed);
    return brushes_[Color.orangeRed];
  }
  ///
  public static Brush orchid() {
    if (!(Color.orchid in brushes_))
      brushes_[Color.orchid] = new SolidBrush(Color.orchid);
    return brushes_[Color.orchid];
  }
  ///
  public static Brush paleGoldenrod() {
    if (!(Color.paleGoldenrod in brushes_))
      brushes_[Color.paleGoldenrod] = new SolidBrush(Color.paleGoldenrod);
    return brushes_[Color.paleGoldenrod];
  }
  ///
  public static Brush paleGreen() {
    if (!(Color.paleGreen in brushes_))
      brushes_[Color.paleGreen] = new SolidBrush(Color.paleGreen);
    return brushes_[Color.paleGreen];
  }
  ///
  public static Brush paleTurquoise() {
    if (!(Color.paleTurquoise in brushes_))
      brushes_[Color.paleTurquoise] = new SolidBrush(Color.paleTurquoise);
    return brushes_[Color.paleTurquoise];
  }
  ///
  public static Brush paleVioletRed() {
    if (!(Color.paleVioletRed in brushes_))
      brushes_[Color.paleVioletRed] = new SolidBrush(Color.paleVioletRed);
    return brushes_[Color.paleVioletRed];
  }
  ///
  public static Brush papayaWhip() {
    if (!(Color.papayaWhip in brushes_))
      brushes_[Color.papayaWhip] = new SolidBrush(Color.papayaWhip);
    return brushes_[Color.papayaWhip];
  }
  ///
  public static Brush peachPuff() {
    if (!(Color.peachPuff in brushes_))
      brushes_[Color.peachPuff] = new SolidBrush(Color.peachPuff);
    return brushes_[Color.peachPuff];
  }
  ///
  public static Brush peru() {
    if (!(Color.peru in brushes_))
      brushes_[Color.peru] = new SolidBrush(Color.peru);
    return brushes_[Color.peru];
  }
  ///
  public static Brush pink() {
    if (!(Color.pink in brushes_))
      brushes_[Color.pink] = new SolidBrush(Color.pink);
    return brushes_[Color.pink];
  }
  ///
  public static Brush plum() {
    if (!(Color.plum in brushes_))
      brushes_[Color.plum] = new SolidBrush(Color.plum);
    return brushes_[Color.plum];
  }
  ///
  public static Brush powderBlue() {
    if (!(Color.powderBlue in brushes_))
      brushes_[Color.powderBlue] = new SolidBrush(Color.powderBlue);
    return brushes_[Color.powderBlue];
  }
  ///
  public static Brush purple() {
    if (!(Color.purple in brushes_))
      brushes_[Color.purple] = new SolidBrush(Color.purple);
    return brushes_[Color.purple];
  }
  ///
  public static Brush red() {
    if (!(Color.red in brushes_))
      brushes_[Color.red] = new SolidBrush(Color.red);
    return brushes_[Color.red];
  }
  ///
  public static Brush rosyBrown() {
    if (!(Color.rosyBrown in brushes_))
      brushes_[Color.rosyBrown] = new SolidBrush(Color.rosyBrown);
    return brushes_[Color.rosyBrown];
  }
  ///
  public static Brush royalBlue() {
    if (!(Color.royalBlue in brushes_))
      brushes_[Color.royalBlue] = new SolidBrush(Color.royalBlue);
    return brushes_[Color.royalBlue];
  }
  ///
  public static Brush saddleBrown() {
    if (!(Color.saddleBrown in brushes_))
      brushes_[Color.saddleBrown] = new SolidBrush(Color.saddleBrown);
    return brushes_[Color.saddleBrown];
  }
  ///
  public static Brush salmon() {
    if (!(Color.salmon in brushes_))
      brushes_[Color.salmon] = new SolidBrush(Color.salmon);
    return brushes_[Color.salmon];
  }
  ///
  public static Brush sandyBrown() {
    if (!(Color.sandyBrown in brushes_))
      brushes_[Color.sandyBrown] = new SolidBrush(Color.sandyBrown);
    return brushes_[Color.sandyBrown];
  }
  ///
  public static Brush seaGreen() {
    if (!(Color.seaGreen in brushes_))
      brushes_[Color.seaGreen] = new SolidBrush(Color.seaGreen);
    return brushes_[Color.seaGreen];
  }
  ///
  public static Brush seaShell() {
    if (!(Color.seaShell in brushes_))
      brushes_[Color.seaShell] = new SolidBrush(Color.seaShell);
    return brushes_[Color.seaShell];
  }
  ///
  public static Brush sienna() {
    if (!(Color.sienna in brushes_))
      brushes_[Color.sienna] = new SolidBrush(Color.sienna);
    return brushes_[Color.sienna];
  }
  ///
  public static Brush silver() {
    if (!(Color.silver in brushes_))
      brushes_[Color.silver] = new SolidBrush(Color.silver);
    return brushes_[Color.silver];
  }
  ///
  public static Brush skyBlue() {
    if (!(Color.skyBlue in brushes_))
      brushes_[Color.skyBlue] = new SolidBrush(Color.skyBlue);
    return brushes_[Color.skyBlue];
  }
  ///
  public static Brush slateBlue() {
    if (!(Color.slateBlue in brushes_))
      brushes_[Color.slateBlue] = new SolidBrush(Color.slateBlue);
    return brushes_[Color.slateBlue];
  }
  ///
  public static Brush slateGray() {
    if (!(Color.slateGray in brushes_))
      brushes_[Color.slateGray] = new SolidBrush(Color.slateGray);
    return brushes_[Color.slateGray];
  }
  ///
  public static Brush snow() {
    if (!(Color.snow in brushes_))
      brushes_[Color.snow] = new SolidBrush(Color.snow);
    return brushes_[Color.snow];
  }
  ///
  public static Brush springGreen() {
    if (!(Color.springGreen in brushes_))
      brushes_[Color.springGreen] = new SolidBrush(Color.springGreen);
    return brushes_[Color.springGreen];
  }
  ///
  public static Brush steelBlue() {
    if (!(Color.steelBlue in brushes_))
      brushes_[Color.steelBlue] = new SolidBrush(Color.steelBlue);
    return brushes_[Color.steelBlue];
  }
  ///
  public static Brush tan() {
    if (!(Color.tan in brushes_))
      brushes_[Color.tan] = new SolidBrush(Color.tan);
    return brushes_[Color.tan];
  }
  ///
  public static Brush teal() {
    if (!(Color.teal in brushes_))
      brushes_[Color.teal] = new SolidBrush(Color.teal);
    return brushes_[Color.teal];
  }
  ///
  public static Brush thistle() {
    if (!(Color.thistle in brushes_))
      brushes_[Color.thistle] = new SolidBrush(Color.thistle);
    return brushes_[Color.thistle];
  }
  ///
  public static Brush tomato() {
    if (!(Color.tomato in brushes_))
      brushes_[Color.tomato] = new SolidBrush(Color.tomato);
    return brushes_[Color.tomato];
  }
  ///
  public static Brush turquoise() {
    if (!(Color.turquoise in brushes_))
      brushes_[Color.turquoise] = new SolidBrush(Color.turquoise);
    return brushes_[Color.turquoise];
  }
  ///
  public static Brush violet() {
    if (!(Color.violet in brushes_))
      brushes_[Color.violet] = new SolidBrush(Color.violet);
    return brushes_[Color.violet];
  }
  ///
  public static Brush wheat() {
    if (!(Color.wheat in brushes_))
      brushes_[Color.wheat] = new SolidBrush(Color.wheat);
    return brushes_[Color.wheat];
  }
  ///
  public static Brush white() {
    if (!(Color.white in brushes_))
      brushes_[Color.white] = new SolidBrush(Color.white);
    return brushes_[Color.white];
  }
  ///
  public static Brush whiteSmoke() {
    if (!(Color.whiteSmoke in brushes_))
      brushes_[Color.whiteSmoke] = new SolidBrush(Color.whiteSmoke);
    return brushes_[Color.whiteSmoke];
  }
  ///
  public static Brush yellow() {
    if (!(Color.yellow in brushes_))
      brushes_[Color.yellow] = new SolidBrush(Color.yellow);
    return brushes_[Color.yellow];
  }
  ///
  public static Brush yellowGreen() {
    if (!(Color.yellowGreen in brushes_))
      brushes_[Color.yellowGreen] = new SolidBrush(Color.yellowGreen);
    return brushes_[Color.yellowGreen];
  }

  private static Brush fromSystemColor(Color color) {
    if (systemBrushes_ == null)
      systemBrushes_ = new Brush[33];
    int i = cast(int)color.toKnownColor();
    if (i > 167) i -= 141;
    i--;
    if (systemBrushes_[i] is null)
      systemBrushes_[i] = new SolidBrush(color, true);
    return systemBrushes_[i];
  }
  ///
  public static Brush activeBorder() {
    return fromSystemColor(Color.activeBorder);
  }
  ///
  public static Brush activeCaption() {
    return fromSystemColor(Color.activeCaption);
  }
  ///
  public static Brush activeCaptionText() {
    return fromSystemColor(Color.activeCaptionText);
  }
  ///
  public static Brush appWorkspace() {
    return fromSystemColor(Color.appWorkspace);
  }
  ///
  public static Brush buttonFace() {
    return fromSystemColor(Color.buttonFace);
  }
  ///
  public static Brush buttonHighlight() {
    return fromSystemColor(Color.buttonHighlight);
  }
  ///
  public static Brush buttonShadow() {
    return fromSystemColor(Color.buttonShadow);
  }
  ///
  public static Brush control() {
    return fromSystemColor(Color.control);
  }
  ///
  public static Brush controlText() {
    return fromSystemColor(Color.controlText);
  }
  ///
  public static Brush controlDark() {
    return fromSystemColor(Color.controlDark);
  }
  ///
  public static Brush controlDarkDark() {
    return fromSystemColor(Color.controlDarkDark);
  }
  ///
  public static Brush controlLight() {
    return fromSystemColor(Color.controlLight);
  }
  ///
  public static Brush controlLightLight() {
    return fromSystemColor(Color.controlLightLight);
  }
  ///
  public static Brush desktop() {
    return fromSystemColor(Color.desktop);
  }
  ///
  public static Brush gradientActiveCaption() {
    return fromSystemColor(Color.gradientActiveCaption);
  }
  ///
  public static Brush gradientInactiveCaption() {
    return fromSystemColor(Color.gradientInactiveCaption);
  }
  ///
  public static Brush grayText() {
    return fromSystemColor(Color.grayText);
  }
  ///
  public static Brush highlight() {
    return fromSystemColor(Color.highlight);
  }
  ///
  public static Brush highlightText() {
    return fromSystemColor(Color.highlightText);
  }
  ///
  public static Brush hotTrack() {
    return fromSystemColor(Color.hotTrack);
  }
  ///
  public static Brush inactiveBorder() {
    return fromSystemColor(Color.inactiveBorder);
  }
  ///
  public static Brush inactiveCaption() {
    return fromSystemColor(Color.inactiveCaption);
  }
  ///
  public static Brush inactiveCaptionText() {
    return fromSystemColor(Color.inactiveCaptionText);
  }
  ///
  public static Brush info() {
    return fromSystemColor(Color.info);
  }
  ///
  public static Brush infoText() {
    return fromSystemColor(Color.infoText);
  }
  ///
  public static Brush menu() {
    return fromSystemColor(Color.menu);
  }
  ///
  public static Brush menuBar() {
    return fromSystemColor(Color.menuBar);
  }
  ///
  public static Brush menuHighlight() {
    return fromSystemColor(Color.menuHighlight);
  }
  ///
  public static Brush menuText() {
    return fromSystemColor(Color.menuText);
  }
  ///
  public static Brush scrollBar() {
    return fromSystemColor(Color.scrollBar);
  }
  ///
  public static Brush window() {
    return fromSystemColor(Color.window);
  }
  ///
  public static Brush windowFrame() {
    return fromSystemColor(Color.windowFrame);
  }
  ///
  public static Brush windowText() {
    return fromSystemColor(Color.windowText);
  }

  package Handle nativeBrush() {
    return nativeBrush_;
  }

}

/**
 */
public final class SolidBrush : Brush {

  private Color color_;
  private bool immutable_;

  package this(Color color, bool immutable) {
    this(color);
    immutable_ = immutable;
  }

  /**
   */
  public this(Color color) {
    color_ = color;

    Status status = GdipCreateSolidFill(color.toArgb(), nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void color(Color value) {
    if (color_ != value) {
      Status status = GdipSetSolidFillColor(nativeBrush_, value.toArgb());
      if (status != Status.OK)
        throw statusException(status);
      color_ = value;
    }
  }

  /**
   * Ditto
   */
  public Color color() {
    if (color_.isEmpty) {
      int value;
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
public final class TextureBrush : Brush {

  /**
   */
  public this(Image image, WrapMode wrapMode = WrapMode.Tile) {
    if (image is null)
      throw new ArgumentNullException("image");

    Status status = GdipCreateTexture(image.nativeImage_, wrapMode, nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public this(Image image, WrapMode wrapMode, Rect rect) {
    if (image is null)
      throw new ArgumentNullException("image"); 

    Status status = GdipCreateTexture2I(image.nativeImage_, wrapMode, rect.x, rect.y, rect.width, rect.height, nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public this(Image image, WrapMode wrapMode, RectF rect) {
    if (image is null)
      throw new ArgumentNullException("image"); 

    Status status = GdipCreateTexture2(image.nativeImage_, wrapMode, rect.x, rect.y, rect.width, rect.height, nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public Image image() {
    Handle nativeImage;
    Status status = GdipGetTextureImage(nativeBrush_, nativeImage);
    if (status != Status.OK)
      throw statusException(status);
    return Image.createImage(nativeImage);
  }

  /**
   */
  public void transform(Matrix value) {
    if (value is null)
      throw new ArgumentNullException("value");

    Status status = GdipSetTextureTransform(nativeBrush_, value.nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Ditto
   */
  public Matrix transform() {
    Matrix m = new Matrix;
    Status status = GdipGetTextureTransform(nativeBrush_, m.nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
    return m;
  }

  /**
   */
  public void wrapMode(WrapMode value) {
    Status status = GdipSetTextureWrapMode(nativeBrush_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Ditto
   */
  public WrapMode wrapMode() {
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
public final class HatchBrush : Brush {

  /**
   */
  public this(HatchStyle hatchStyle, Color foreColor) {
    this(hatchStyle, foreColor, Color.black);
  }

  /**
   */
  public this(HatchStyle hatchStyle, Color foreColor, Color backColor) {
    Status status = GdipCreateHatchBrush(hatchStyle, foreColor.toArgb(), backColor.toArgb(), nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public HatchStyle hatchStyle() {
    HatchStyle value;
    Status status = GdipGetHatchStyle(nativeBrush_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  public Color foregroundColor() {
    int argb;
    Status status = GdipGetHatchForegroundColor(nativeBrush_, argb);
    if (status != Status.OK)
      throw statusException(status);
    return Color.fromArgb(argb);
  }

  /**
   */
  public Color backgroundColor() {
    int argb;
    Status status = GdipGetHatchBackgroundColor(nativeBrush_, argb);
    if (status != Status.OK)
      throw statusException(status);
    return Color.fromArgb(argb);
  }

}

/**
 */
public final class Blend {

  ///
  public float[] factors;

  ///
  public float[] positions;

  /**
   */
  public this(int count = 1) {
    factors.length = count;
    positions.length = count;
  }

}

/**
 */
public final class ColorBlend {

  ///
  public Color[] colors;

  ///
  public float[] positions;

  /**
   */
  public this(int count = 1) {
    colors.length = count;
    positions.length = count;
  }

}

/**
 */
public final class LinearGradientBrush : Brush {

  /**
   */
  public this(Point startPoint, Point endPoint, Color startColor, Color endColor) {
    Status status = GdipCreateLineBrushI(startPoint, endPoint, startColor.toArgb(), endColor.toArgb(), WrapMode.Tile, nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public this(PointF startPoint, PointF endPoint, Color startColor, Color endColor) {
    Status status = GdipCreateLineBrush(startPoint, endPoint, startColor.toArgb(), endColor.toArgb(), WrapMode.Tile, nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public this(Rect rect, Color startColor, Color endColor, LinearGradientMode mode) {
    Status status = GdipCreateLineBrushFromRectI(rect, startColor.toArgb(), endColor.toArgb(), mode, WrapMode.Tile, nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public this(RectF rect, Color startColor, Color endColor, LinearGradientMode mode) {
    Status status = GdipCreateLineBrushFromRect(rect, startColor.toArgb(), endColor.toArgb(), mode, WrapMode.Tile, nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public this(Rect rect, Color startColor, Color endColor, float angle, bool isAngleScalable = false) {
    Status status = GdipCreateLineBrushFromRectWithAngleI(rect, startColor.toArgb(), endColor.toArgb(), angle, (isAngleScalable ? 1 : 0), WrapMode.Tile, nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public this(RectF rect, Color startColor, Color endColor, float angle, bool isAngleScalable = false) {
    Status status = GdipCreateLineBrushFromRectWithAngle(rect, startColor.toArgb(), endColor.toArgb(), angle, (isAngleScalable ? 1 : 0), WrapMode.Tile, nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void setSigmaBellShape(float focus, float scale = 1.0f) {
    Status status = GdipSetLineSigmaBlend(nativeBrush_, focus, scale);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void setBlendTriangularShape(float focus, float scale = 1.0f) {
    Status status = GdipSetLineLinearBlend(nativeBrush_, focus, scale);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void resetTransform() {
    Status status = GdipResetLineTransform(nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void multiplyTransform(Matrix matrix, MatrixOrder order = MatrixOrder.Prepend) {
    if (matrix is null)
      throw new ArgumentNullException("matrix");

    Status status = GdipMultiplyLineTransform(nativeBrush_, matrix.nativeMatrix, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void translateTransform(float dx, float dy, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipTranslateLineTransform(nativeBrush_, dx, dy, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void scaleTransform(float sx, float sy, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipScaleLineTransform(nativeBrush_, sx, sy, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void rorateTransform(float angle, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipRotateLineTransform(nativeBrush_, angle, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void linearColors(Color[] value) {
    Status status = GdipSetLineColors(nativeBrush_, value[0].toArgb(), value[1].toArgb());
    if (status != Status.OK)
      throw statusException(status);
  }

  public Color[] linearColors() {
    int[] colors = new int[2];
    Status status = GdipGetLineColors(nativeBrush_, colors.ptr);
    if (status != Status.OK)
      throw statusException(status);
    return [ Color.fromArgb(colors[0]), Color.fromArgb(colors[1]) ];
  }

  public void gammaCorrection(bool value) {
    Status status = GdipSetLineGammaCorrection(nativeBrush_, (value ? 1 : 0));
    if (status != Status.OK)
      throw statusException(status);
  }

  public bool gammaCorrection() {
    int value;
    Status status = GdipGetLineGammaCorrection(nativeBrush_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value != 0;
  }

  /**
   */
  public void blend(Blend value) {
    Status status = GdipSetLineBlend(nativeBrush_, value.factors.ptr, value.positions.ptr, value.factors.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Ditto
   */
  public Blend blend() {
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
  public void interpolationColors(ColorBlend value) {
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

    int[] colors = new int[value.colors.length];
    foreach (i, ref argb; colors) {
      argb = value.colors[i].toArgb();
    }
    Status status = GdipSetLinePresetBlend(nativeBrush_, colors.ptr, value.positions.ptr, value.colors.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Ditto
   */
  public ColorBlend interpolationColors() {
    int count;
    Status status = GdipGetLinePresetBlendCount(nativeBrush_, count);
    if (status != Status.OK)
      throw statusException(status);

    if (count <= 0)
      return null;

    int[] colors = new int[count];
    float[] positions = new float[count];
    status = GdipGetLinePresetBlend(nativeBrush_, colors.ptr, positions.ptr, count);
    if (status != Status.OK)
      throw statusException(status);

    ColorBlend blend = new ColorBlend(count);
    blend.colors = new Color[count];
    foreach (i, ref color; blend.colors) {
      color = Color.fromArgb(colors[i]);
    }
    blend.positions = positions.dup;
    return blend;
  }

  public void transform(Matrix value) {
    if (value is null)
      throw new ArgumentNullException("value");

    Status status = GdipSetLineTransform(nativeBrush_, value.nativeMatrix);
    if (status != Status.OK)
      throw statusException(status);
  }

  public Matrix transform() {
    Matrix m = new Matrix;
    Status status = GdipGetLineTransform(nativeBrush_, m.nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
    return m;
  }

  /**
   */
  public RectF rectangle() {
    RectF value;
    Status status = GdipGetLineRect(nativeBrush_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  public void wrapMode(WrapMode value) {
    Status status = GdipSetLineWrapMode(nativeBrush_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Ditto
   */
  public WrapMode wrapMode() {
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
public final class Pen {

  private static Pen[Color] pens_;
  private static Pen[] systemPens_;

  private Handle nativePen_;
  private Color color_;
  private bool immutable_;

  static ~this() {
    pens_ = null;
    systemPens_ = null;
  }

  private this(Color color, bool immutable) {
    this(color);
    immutable_ = immutable;
  }

  /**
   */
  public this(Color color, float width = 1f) {
    color_ = color;
    Status status = GdipCreatePen1(color.toArgb(), width, GraphicsUnit.Pixel, nativePen_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public this(Brush brush, float width = 1f) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    Status status = GdipCreatePen2(brush.nativeBrush, width, GraphicsUnit.Pixel, nativePen_);
    if (status != Status.OK)
      throw statusException(status);
  }

  ~this() {
    dispose();
  }

  /**
   */
  public void dispose() {
    if (nativePen_ != Handle.init) {
      GdipDeletePenSafe(nativePen_);
      nativePen_ = Handle.init;
    }
  }

  public Object clone() {
    Handle clonePen;
    Status status = GdipClonePen(nativePen_, clonePen);
    if (status != Status.OK)
      throw statusException(status);
    return new Pen(clonePen);
  }

  public void setLineCap(LineCap startCap, LineCap endCap, DashCap dashCap) {
    Status status = GdipSetPenLineCap197819(nativePen_, startCap, endCap, dashCap);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void resetTransform() {
    Status status = GdipResetPenTransform(nativePen_);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void multiplyTransform(Matrix matrix, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipMultiplyPenTransform(nativePen_, matrix.nativeMatrix, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void translateTransform(float dx, float dy, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipTranslatePenTransform(nativePen_, dx, dy, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void scaleTransform(float sx, float sy, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipScalePenTransform(nativePen_, sx, sy, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void rotateTransform(float angle, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipRotatePenTransform(nativePen_, angle, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void width(float value) {
    Status status = GdipSetPenWidth(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Ditto
   */
  public float width() {
    float value = 0;
    Status status = GdipGetPenWidth(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  public void startCap(LineCap value) {
    Status status = GdipSetPenStartCap(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  public LineCap startCap() {
    LineCap value;
    Status status = GdipGetPenStartCap(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  public void endCap(LineCap value) {
    Status status = GdipSetPenEndCap(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  public LineCap endCap() {
    LineCap value;
    Status status = GdipGetPenEndCap(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  public void dashCap(DashCap value) {
    Status status = GdipSetPenDashCap197819(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  public DashCap dashCap() {
    DashCap value;
    Status status = GdipGetPenDashCap197819(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  public void lineJoin(LineJoin value) {
    Status status = GdipSetPenLineJoin(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  public LineJoin lineJoin() {
    LineJoin value;
    Status status = GdipGetPenLineJoin(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  public void miterLimit(float value) {
    Status status = GdipSetPenMiterLimit(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  public float miterLimit() {
    float value = 0.0f;
    Status status = GdipGetPenMiterLimit(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  public void alignment(PenAlignment value) {
    Status status = GdipSetPenMode(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  public PenAlignment alignment() {
    PenAlignment value;
    Status status = GdipGetPenMode(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  public void transform(Matrix value) {
    if (value is null)
      throw new ArgumentNullException("value");

    Status status = GdipSetPenTransform(nativePen_, value.nativeMatrix);
    if (status != Status.OK)
      throw statusException(status);
  }

  public Matrix transform() {
    Matrix m = new Matrix;
    Status status = GdipGetPenTransform(nativePen_, m.nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
    return m;
  }

  /**
   */
  public PenType penType() {
    PenType type = cast(PenType)-1;
    Status status = GdipGetPenFillType(nativePen_, type);
    if (status != Status.OK)
      throw statusException(status);
    return type;
  }

  /**
   */
  public void color(Color value) {
    if (value != color_) {
      color_ = value;

      Status status = GdipSetPenColor(nativePen_, value.toArgb());
      if (status != Status.OK)
        throw statusException(status);
    }
  }

  /**
   * Ditto
   */
  public Color color() {
    if (color_.isEmpty) {
      int argb;
      Status status = GdipGetPenColor(nativePen_, argb);
      if (status != Status.OK)
        throw statusException(status);
      color_ = Color.fromArgb(argb);
    }
    return color_;
  }

  /**
   */
  public void brush(Brush value) {
    if (value is null)
      throw new ArgumentNullException("value");

    Status status = GdipSetPenBrushFill(nativePen_, value.nativeBrush);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Ditto
   */
  public Brush brush() {
    switch (penType) {
      case PenType.SolidColor:
        return new SolidBrush(nativeBrush);
      case PenType.TextureFill:
        return new TextureBrush(nativeBrush);
      case PenType.LinearGradient:
        return new LinearGradientBrush(nativeBrush);
      case PenType.PathGradient:
        return new PathGradientBrush(nativeBrush);
      default:
    }
    return null;
  }

  public void dashStyle(DashStyle value) {
    Status status = GdipSetPenDashStyle(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  public DashStyle dashStyle() {
    DashStyle value;
    Status status = GdipGetPenDashStyle(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  public void dashOffset(float value) {
    Status status = GdipSetPenDashOffset(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  public float dashOffset() {
    float value = 0.0f;
    Status status = GdipGetPenDashOffset(nativePen_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  public void dashPattern(float[] value) {
    if (value == null)
      throw statusException(Status.InvalidParameter);

    Status status = GdipSetPenDashArray(nativePen_, value.ptr, value.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public float[] dashPattern() {
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

  public void compoundArray(float[] value) {
    if (value == null)
      throw statusException(Status.InvalidParameter);

    Status status = GdipSetPenCompoundArray(nativePen_, value.ptr, value.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public float[] compoundArray() {
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

  private this(Handle nativePen) {
    nativePen_ = nativePen;
  }

  package Handle nativePen() {
    return nativePen_;
  }

  private Handle nativeBrush() {
    Handle brush;
    Status status = GdipGetPenBrushFill(nativePen_, brush);
    if (status != Status.OK)
      throw statusException(status);
    return brush;
  }
  
  ///
  public static Pen transparent() {
    if (!(Color.transparent in pens_))
      pens_[Color.transparent] = new Pen(Color.transparent);
    return pens_[Color.transparent];
  }
  ///
  public static Pen aliceBlue() {
    if (!(Color.aliceBlue in pens_))
      pens_[Color.aliceBlue] = new Pen(Color.aliceBlue);
    return pens_[Color.aliceBlue];
  }
  ///
  public static Pen antiqueWhite() {
    if (!(Color.antiqueWhite in pens_))
      pens_[Color.antiqueWhite] = new Pen(Color.antiqueWhite);
    return pens_[Color.antiqueWhite];
  }
  ///
  public static Pen aqua() {
    if (!(Color.aqua in pens_))
      pens_[Color.aqua] = new Pen(Color.aqua);
    return pens_[Color.aqua];
  }
  ///
  public static Pen aquamarine() {
    if (!(Color.aquamarine in pens_))
      pens_[Color.aquamarine] = new Pen(Color.aquamarine);
    return pens_[Color.aquamarine];
  }
  ///
  public static Pen azure() {
    if (!(Color.azure in pens_))
      pens_[Color.azure] = new Pen(Color.azure);
    return pens_[Color.azure];
  }
  ///
  public static Pen beige() {
    if (!(Color.beige in pens_))
      pens_[Color.beige] = new Pen(Color.beige);
    return pens_[Color.beige];
  }
  ///
  public static Pen bisque() {
    if (!(Color.bisque in pens_))
      pens_[Color.bisque] = new Pen(Color.bisque);
    return pens_[Color.bisque];
  }
  ///
  public static Pen black() {
    if (!(Color.black in pens_))
      pens_[Color.black] = new Pen(Color.black);
    return pens_[Color.black];
  }
  ///
  public static Pen blanchedAlmond() {
    if (!(Color.blanchedAlmond in pens_))
      pens_[Color.blanchedAlmond] = new Pen(Color.blanchedAlmond);
    return pens_[Color.blanchedAlmond];
  }
  ///
  public static Pen blue() {
    if (!(Color.blue in pens_))
      pens_[Color.blue] = new Pen(Color.blue);
    return pens_[Color.blue];
  }
  ///
  public static Pen blueViolet() {
    if (!(Color.blueViolet in pens_))
      pens_[Color.blueViolet] = new Pen(Color.blueViolet);
    return pens_[Color.blueViolet];
  }
  ///
  public static Pen brown() {
    if (!(Color.brown in pens_))
      pens_[Color.brown] = new Pen(Color.brown);
    return pens_[Color.brown];
  }
  ///
  public static Pen burlyWood() {
    if (!(Color.burlyWood in pens_))
      pens_[Color.burlyWood] = new Pen(Color.burlyWood);
    return pens_[Color.burlyWood];
  }
  ///
  public static Pen cadetBlue() {
    if (!(Color.cadetBlue in pens_))
      pens_[Color.cadetBlue] = new Pen(Color.cadetBlue);
    return pens_[Color.cadetBlue];
  }
  ///
  public static Pen chartreuse() {
    if (!(Color.chartreuse in pens_))
      pens_[Color.chartreuse] = new Pen(Color.chartreuse);
    return pens_[Color.chartreuse];
  }
  ///
  public static Pen chocolate() {
    if (!(Color.chocolate in pens_))
      pens_[Color.chocolate] = new Pen(Color.chocolate);
    return pens_[Color.chocolate];
  }
  ///
  public static Pen coral() {
    if (!(Color.coral in pens_))
      pens_[Color.coral] = new Pen(Color.coral);
    return pens_[Color.coral];
  }
  ///
  public static Pen cornflowerBlue() {
    if (!(Color.cornflowerBlue in pens_))
      pens_[Color.cornflowerBlue] = new Pen(Color.cornflowerBlue);
    return pens_[Color.cornflowerBlue];
  }
  ///
  public static Pen cornsilk() {
    if (!(Color.cornsilk in pens_))
      pens_[Color.cornsilk] = new Pen(Color.cornsilk);
    return pens_[Color.cornsilk];
  }
  ///
  public static Pen crimson() {
    if (!(Color.crimson in pens_))
      pens_[Color.crimson] = new Pen(Color.crimson);
    return pens_[Color.crimson];
  }
  ///
  public static Pen cyan() {
    if (!(Color.cyan in pens_))
      pens_[Color.cyan] = new Pen(Color.cyan);
    return pens_[Color.cyan];
  }
  ///
  public static Pen darkBlue() {
    if (!(Color.darkBlue in pens_))
      pens_[Color.darkBlue] = new Pen(Color.darkBlue);
    return pens_[Color.darkBlue];
  }
  ///
  public static Pen darkCyan() {
    if (!(Color.darkCyan in pens_))
      pens_[Color.darkCyan] = new Pen(Color.darkCyan);
    return pens_[Color.darkCyan];
  }
  ///
  public static Pen darkGoldenrod() {
    if (!(Color.darkGoldenrod in pens_))
      pens_[Color.darkGoldenrod] = new Pen(Color.darkGoldenrod);
    return pens_[Color.darkGoldenrod];
  }
  ///
  public static Pen darkGray() {
    if (!(Color.darkGray in pens_))
      pens_[Color.darkGray] = new Pen(Color.darkGray);
    return pens_[Color.darkGray];
  }
  ///
  public static Pen darkGreen() {
    if (!(Color.darkGreen in pens_))
      pens_[Color.darkGreen] = new Pen(Color.darkGreen);
    return pens_[Color.darkGreen];
  }
  ///
  public static Pen darkKhaki() {
    if (!(Color.darkKhaki in pens_))
      pens_[Color.darkKhaki] = new Pen(Color.darkKhaki);
    return pens_[Color.darkKhaki];
  }
  ///
  public static Pen darkMagenta() {
    if (!(Color.darkMagenta in pens_))
      pens_[Color.darkMagenta] = new Pen(Color.darkMagenta);
    return pens_[Color.darkMagenta];
  }
  ///
  public static Pen darkOliveGreen() {
    if (!(Color.darkOliveGreen in pens_))
      pens_[Color.darkOliveGreen] = new Pen(Color.darkOliveGreen);
    return pens_[Color.darkOliveGreen];
  }
  ///
  public static Pen darkOrange() {
    if (!(Color.darkOrange in pens_))
      pens_[Color.darkOrange] = new Pen(Color.darkOrange);
    return pens_[Color.darkOrange];
  }
  ///
  public static Pen darkOrchid() {
    if (!(Color.darkOrchid in pens_))
      pens_[Color.darkOrchid] = new Pen(Color.darkOrchid);
    return pens_[Color.darkOrchid];
  }
  ///
  public static Pen darkRed() {
    if (!(Color.darkRed in pens_))
      pens_[Color.darkRed] = new Pen(Color.darkRed);
    return pens_[Color.darkRed];
  }
  ///
  public static Pen darkSalmon() {
    if (!(Color.darkSalmon in pens_))
      pens_[Color.darkSalmon] = new Pen(Color.darkSalmon);
    return pens_[Color.darkSalmon];
  }
  ///
  public static Pen darkSeaGreen() {
    if (!(Color.darkSeaGreen in pens_))
      pens_[Color.darkSeaGreen] = new Pen(Color.darkSeaGreen);
    return pens_[Color.darkSeaGreen];
  }
  ///
  public static Pen darkSlateBlue() {
    if (!(Color.darkSlateBlue in pens_))
      pens_[Color.darkSlateBlue] = new Pen(Color.darkSlateBlue);
    return pens_[Color.darkSlateBlue];
  }
  ///
  public static Pen darkSlateGray() {
    if (!(Color.darkSlateGray in pens_))
      pens_[Color.darkSlateGray] = new Pen(Color.darkSlateGray);
    return pens_[Color.darkSlateGray];
  }
  ///
  public static Pen darkTurquoise() {
    if (!(Color.darkTurquoise in pens_))
      pens_[Color.darkTurquoise] = new Pen(Color.darkTurquoise);
    return pens_[Color.darkTurquoise];
  }
  ///
  public static Pen darkViolet() {
    if (!(Color.darkViolet in pens_))
      pens_[Color.darkViolet] = new Pen(Color.darkViolet);
    return pens_[Color.darkViolet];
  }
  ///
  public static Pen deepPink() {
    if (!(Color.deepPink in pens_))
      pens_[Color.deepPink] = new Pen(Color.deepPink);
    return pens_[Color.deepPink];
  }
  ///
  public static Pen deepSkyBlue() {
    if (!(Color.deepSkyBlue in pens_))
      pens_[Color.deepSkyBlue] = new Pen(Color.deepSkyBlue);
    return pens_[Color.deepSkyBlue];
  }
  ///
  public static Pen dimGray() {
    if (!(Color.dimGray in pens_))
      pens_[Color.dimGray] = new Pen(Color.dimGray);
    return pens_[Color.dimGray];
  }
  ///
  public static Pen dodgerBlue() {
    if (!(Color.dodgerBlue in pens_))
      pens_[Color.dodgerBlue] = new Pen(Color.dodgerBlue);
    return pens_[Color.dodgerBlue];
  }
  ///
  public static Pen firebrick() {
    if (!(Color.firebrick in pens_))
      pens_[Color.firebrick] = new Pen(Color.firebrick);
    return pens_[Color.firebrick];
  }
  ///
  public static Pen floralWhite() {
    if (!(Color.floralWhite in pens_))
      pens_[Color.floralWhite] = new Pen(Color.floralWhite);
    return pens_[Color.floralWhite];
  }
  ///
  public static Pen forestGreen() {
    if (!(Color.forestGreen in pens_))
      pens_[Color.forestGreen] = new Pen(Color.forestGreen);
    return pens_[Color.forestGreen];
  }
  ///
  public static Pen fuchsia() {
    if (!(Color.fuchsia in pens_))
      pens_[Color.fuchsia] = new Pen(Color.fuchsia);
    return pens_[Color.fuchsia];
  }
  ///
  public static Pen gainsboro() {
    if (!(Color.gainsboro in pens_))
      pens_[Color.gainsboro] = new Pen(Color.gainsboro);
    return pens_[Color.gainsboro];
  }
  ///
  public static Pen ghostWhite() {
    if (!(Color.ghostWhite in pens_))
      pens_[Color.ghostWhite] = new Pen(Color.ghostWhite);
    return pens_[Color.ghostWhite];
  }
  ///
  public static Pen gold() {
    if (!(Color.gold in pens_))
      pens_[Color.gold] = new Pen(Color.gold);
    return pens_[Color.gold];
  }
  ///
  public static Pen gray() {
    if (!(Color.gray in pens_))
      pens_[Color.gray] = new Pen(Color.gray);
    return pens_[Color.gray];
  }
  ///
  public static Pen green() {
    if (!(Color.green in pens_))
      pens_[Color.green] = new Pen(Color.green);
    return pens_[Color.green];
  }
  ///
  public static Pen greenYellow() {
    if (!(Color.greenYellow in pens_))
      pens_[Color.greenYellow] = new Pen(Color.greenYellow);
    return pens_[Color.greenYellow];
  }
  ///
  public static Pen honeydew() {
    if (!(Color.honeydew in pens_))
      pens_[Color.honeydew] = new Pen(Color.honeydew);
    return pens_[Color.honeydew];
  }
  ///
  public static Pen hotPink() {
    if (!(Color.hotPink in pens_))
      pens_[Color.hotPink] = new Pen(Color.hotPink);
    return pens_[Color.hotPink];
  }
  ///
  public static Pen indianRed() {
    if (!(Color.indianRed in pens_))
      pens_[Color.indianRed] = new Pen(Color.indianRed);
    return pens_[Color.indianRed];
  }
  ///
  public static Pen indigo() {
    if (!(Color.indigo in pens_))
      pens_[Color.indigo] = new Pen(Color.indigo);
    return pens_[Color.indigo];
  }
  ///
  public static Pen ivory() {
    if (!(Color.ivory in pens_))
      pens_[Color.ivory] = new Pen(Color.ivory);
    return pens_[Color.ivory];
  }
  ///
  public static Pen khaki() {
    if (!(Color.khaki in pens_))
      pens_[Color.khaki] = new Pen(Color.khaki);
    return pens_[Color.khaki];
  }
  ///
  public static Pen lavender() {
    if (!(Color.lavender in pens_))
      pens_[Color.lavender] = new Pen(Color.lavender);
    return pens_[Color.lavender];
  }
  ///
  public static Pen lavenderBlush() {
    if (!(Color.lavenderBlush in pens_))
      pens_[Color.lavenderBlush] = new Pen(Color.lavenderBlush);
    return pens_[Color.lavenderBlush];
  }
  ///
  public static Pen lawnGreen() {
    if (!(Color.lawnGreen in pens_))
      pens_[Color.lawnGreen] = new Pen(Color.lawnGreen);
    return pens_[Color.lawnGreen];
  }
  ///
  public static Pen lemonChiffon() {
    if (!(Color.lemonChiffon in pens_))
      pens_[Color.lemonChiffon] = new Pen(Color.lemonChiffon);
    return pens_[Color.lemonChiffon];
  }
  ///
  public static Pen lightBlue() {
    if (!(Color.lightBlue in pens_))
      pens_[Color.lightBlue] = new Pen(Color.lightBlue);
    return pens_[Color.lightBlue];
  }
  ///
  public static Pen lightCoral() {
    if (!(Color.lightCoral in pens_))
      pens_[Color.lightCoral] = new Pen(Color.lightCoral);
    return pens_[Color.lightCoral];
  }
  ///
  public static Pen lightCyan() {
    if (!(Color.lightCyan in pens_))
      pens_[Color.lightCyan] = new Pen(Color.lightCyan);
    return pens_[Color.lightCyan];
  }
  ///
  public static Pen lightGoldenrodYellow() {
    if (!(Color.lightGoldenrodYellow in pens_))
      pens_[Color.lightGoldenrodYellow] = new Pen(Color.lightGoldenrodYellow);
    return pens_[Color.lightGoldenrodYellow];
  }
  ///
  public static Pen lightGreen() {
    if (!(Color.lightGreen in pens_))
      pens_[Color.lightGreen] = new Pen(Color.lightGreen);
    return pens_[Color.lightGreen];
  }
  ///
  public static Pen lightGray() {
    if (!(Color.lightGray in pens_))
      pens_[Color.lightGray] = new Pen(Color.lightGray);
    return pens_[Color.lightGray];
  }
  ///
  public static Pen lightPink() {
    if (!(Color.lightPink in pens_))
      pens_[Color.lightPink] = new Pen(Color.lightPink);
    return pens_[Color.lightPink];
  }
  ///
  public static Pen lightSalmon() {
    if (!(Color.lightSalmon in pens_))
      pens_[Color.lightSalmon] = new Pen(Color.lightSalmon);
    return pens_[Color.lightSalmon];
  }
  ///
  public static Pen lightSeaGreen() {
    if (!(Color.lightSeaGreen in pens_))
      pens_[Color.lightSeaGreen] = new Pen(Color.lightSeaGreen);
    return pens_[Color.lightSeaGreen];
  }
  ///
  public static Pen lightSkyBlue() {
    if (!(Color.lightSkyBlue in pens_))
      pens_[Color.lightSkyBlue] = new Pen(Color.lightSkyBlue);
    return pens_[Color.lightSkyBlue];
  }
  ///
  public static Pen lightSlateGray() {
    if (!(Color.lightSlateGray in pens_))
      pens_[Color.lightSlateGray] = new Pen(Color.lightSlateGray);
    return pens_[Color.lightSlateGray];
  }
  ///
  public static Pen lightSteelBlue() {
    if (!(Color.lightSteelBlue in pens_))
      pens_[Color.lightSteelBlue] = new Pen(Color.lightSteelBlue);
    return pens_[Color.lightSteelBlue];
  }
  ///
  public static Pen lightYellow() {
    if (!(Color.lightYellow in pens_))
      pens_[Color.lightYellow] = new Pen(Color.lightYellow);
    return pens_[Color.lightYellow];
  }
  ///
  public static Pen lime() {
    if (!(Color.lime in pens_))
      pens_[Color.lime] = new Pen(Color.lime);
    return pens_[Color.lime];
  }
  ///
  public static Pen limeGreen() {
    if (!(Color.limeGreen in pens_))
      pens_[Color.limeGreen] = new Pen(Color.limeGreen);
    return pens_[Color.limeGreen];
  }
  ///
  public static Pen linen() {
    if (!(Color.linen in pens_))
      pens_[Color.linen] = new Pen(Color.linen);
    return pens_[Color.linen];
  }
  ///
  public static Pen magenta() {
    if (!(Color.magenta in pens_))
      pens_[Color.magenta] = new Pen(Color.magenta);
    return pens_[Color.magenta];
  }
  ///
  public static Pen maroon() {
    if (!(Color.maroon in pens_))
      pens_[Color.maroon] = new Pen(Color.maroon);
    return pens_[Color.maroon];
  }
  ///
  public static Pen mediumAquamarine() {
    if (!(Color.mediumAquamarine in pens_))
      pens_[Color.mediumAquamarine] = new Pen(Color.mediumAquamarine);
    return pens_[Color.mediumAquamarine];
  }
  ///
  public static Pen mediumBlue() {
    if (!(Color.mediumBlue in pens_))
      pens_[Color.mediumBlue] = new Pen(Color.mediumBlue);
    return pens_[Color.mediumBlue];
  }
  ///
  public static Pen mediumOrchid() {
    if (!(Color.mediumOrchid in pens_))
      pens_[Color.mediumOrchid] = new Pen(Color.mediumOrchid);
    return pens_[Color.mediumOrchid];
  }
  ///
  public static Pen mediumPurple() {
    if (!(Color.mediumPurple in pens_))
      pens_[Color.mediumPurple] = new Pen(Color.mediumPurple);
    return pens_[Color.mediumPurple];
  }
  ///
  public static Pen mediumSeaGreen() {
    if (!(Color.mediumSeaGreen in pens_))
      pens_[Color.mediumSeaGreen] = new Pen(Color.mediumSeaGreen);
    return pens_[Color.mediumSeaGreen];
  }
  ///
  public static Pen mediumSlateBlue() {
    if (!(Color.mediumSlateBlue in pens_))
      pens_[Color.mediumSlateBlue] = new Pen(Color.mediumSlateBlue);
    return pens_[Color.mediumSlateBlue];
  }
  ///
  public static Pen mediumSpringGreen() {
    if (!(Color.mediumSpringGreen in pens_))
      pens_[Color.mediumSpringGreen] = new Pen(Color.mediumSpringGreen);

    return pens_[Color.mediumSpringGreen];
  }
  ///
  public static Pen mediumTurquoise() {
    if (!(Color.mediumTurquoise in pens_))
      pens_[Color.mediumTurquoise] = new Pen(Color.mediumTurquoise);
    return pens_[Color.mediumTurquoise];
  }
  ///
  public static Pen mediumVioletRed() {
    if (!(Color.mediumVioletRed in pens_))
      pens_[Color.mediumVioletRed] = new Pen(Color.mediumVioletRed);
    return pens_[Color.mediumVioletRed];
  }
  ///
  public static Pen midnightBlue() {
    if (!(Color.midnightBlue in pens_))
      pens_[Color.midnightBlue] = new Pen(Color.midnightBlue);
    return pens_[Color.midnightBlue];
  }
  ///
  public static Pen mintCream() {
    if (!(Color.mintCream in pens_))
      pens_[Color.mintCream] = new Pen(Color.mintCream);
    return pens_[Color.mintCream];
  }
  ///
  public static Pen mistyRose() {
    if (!(Color.mistyRose in pens_))
      pens_[Color.mistyRose] = new Pen(Color.mistyRose);
    return pens_[Color.mistyRose];
  }
  ///
  public static Pen moccasin() {
    if (!(Color.moccasin in pens_))
      pens_[Color.moccasin] = new Pen(Color.moccasin);
    return pens_[Color.moccasin];
  }
  ///
  public static Pen navajoWhite() {
    if (!(Color.navajoWhite in pens_))
      pens_[Color.navajoWhite] = new Pen(Color.navajoWhite);
    return pens_[Color.navajoWhite];
  }
  ///
  public static Pen navy() {
    if (!(Color.navy in pens_))
      pens_[Color.navy] = new Pen(Color.navy);
    return pens_[Color.navy];
  }
  ///
  public static Pen oldLace() {
    if (!(Color.oldLace in pens_))
      pens_[Color.oldLace] = new Pen(Color.oldLace);
    return pens_[Color.oldLace];
  }
  ///
  public static Pen olive() {
    if (!(Color.olive in pens_))
      pens_[Color.olive] = new Pen(Color.olive);
    return pens_[Color.olive];
  }
  ///
  public static Pen oliveDrab() {
    if (!(Color.oliveDrab in pens_))
      pens_[Color.oliveDrab] = new Pen(Color.oliveDrab);
    return pens_[Color.oliveDrab];
  }
  ///
  public static Pen orangeRed() {
    if (!(Color.orangeRed in pens_))
      pens_[Color.orangeRed] = new Pen(Color.orangeRed);
    return pens_[Color.orangeRed];
  }
  ///
  public static Pen orchid() {
    if (!(Color.orchid in pens_))
      pens_[Color.orchid] = new Pen(Color.orchid);
    return pens_[Color.orchid];
  }
  ///
  public static Pen paleGoldenrod() {
    if (!(Color.paleGoldenrod in pens_))
      pens_[Color.paleGoldenrod] = new Pen(Color.paleGoldenrod);
    return pens_[Color.paleGoldenrod];
  }
  ///
  public static Pen paleGreen() {
    if (!(Color.paleGreen in pens_))
      pens_[Color.paleGreen] = new Pen(Color.paleGreen);
    return pens_[Color.paleGreen];
  }
  ///
  public static Pen paleTurquoise() {
    if (!(Color.paleTurquoise in pens_))
      pens_[Color.paleTurquoise] = new Pen(Color.paleTurquoise);
    return pens_[Color.paleTurquoise];
  }
  ///
  public static Pen paleVioletRed() {
    if (!(Color.paleVioletRed in pens_))
      pens_[Color.paleVioletRed] = new Pen(Color.paleVioletRed);
    return pens_[Color.paleVioletRed];
  }
  ///
  public static Pen papayaWhip() {
    if (!(Color.papayaWhip in pens_))
      pens_[Color.papayaWhip] = new Pen(Color.papayaWhip);
    return pens_[Color.papayaWhip];
  }
  ///
  public static Pen peachPuff() {
    if (!(Color.peachPuff in pens_))
      pens_[Color.peachPuff] = new Pen(Color.peachPuff);
    return pens_[Color.peachPuff];
  }
  ///
  public static Pen peru() {
    if (!(Color.peru in pens_))
      pens_[Color.peru] = new Pen(Color.peru);
    return pens_[Color.peru];
  }
  ///
  public static Pen pink() {
    if (!(Color.pink in pens_))
      pens_[Color.pink] = new Pen(Color.pink);
    return pens_[Color.pink];
  }
  ///
  public static Pen plum() {
    if (!(Color.plum in pens_))
      pens_[Color.plum] = new Pen(Color.plum);
    return pens_[Color.plum];
  }
  ///
  public static Pen powderBlue() {
    if (!(Color.powderBlue in pens_))
      pens_[Color.powderBlue] = new Pen(Color.powderBlue);
    return pens_[Color.powderBlue];
  }
  ///
  public static Pen purple() {
    if (!(Color.purple in pens_))
      pens_[Color.purple] = new Pen(Color.purple);
    return pens_[Color.purple];
  }
  ///
  public static Pen red() {
    if (!(Color.red in pens_))
      pens_[Color.red] = new Pen(Color.red);
    return pens_[Color.red];
  }
  ///
  public static Pen rosyBrown() {
    if (!(Color.rosyBrown in pens_))
      pens_[Color.rosyBrown] = new Pen(Color.rosyBrown);
    return pens_[Color.rosyBrown];
  }
  ///
  public static Pen royalBlue() {
    if (!(Color.royalBlue in pens_))
      pens_[Color.royalBlue] = new Pen(Color.royalBlue);
    return pens_[Color.royalBlue];
  }
  ///
  public static Pen saddleBrown() {
    if (!(Color.saddleBrown in pens_))
      pens_[Color.saddleBrown] = new Pen(Color.saddleBrown);
    return pens_[Color.saddleBrown];
  }
  ///
  public static Pen salmon() {
    if (!(Color.salmon in pens_))
      pens_[Color.salmon] = new Pen(Color.salmon);
    return pens_[Color.salmon];
  }
  ///
  public static Pen sandyBrown() {
    if (!(Color.sandyBrown in pens_))
      pens_[Color.sandyBrown] = new Pen(Color.sandyBrown);
    return pens_[Color.sandyBrown];
  }
  ///
  public static Pen seaGreen() {
    if (!(Color.seaGreen in pens_))
      pens_[Color.seaGreen] = new Pen(Color.seaGreen);
    return pens_[Color.seaGreen];
  }
  ///
  public static Pen seaShell() {
    if (!(Color.seaShell in pens_))
      pens_[Color.seaShell] = new Pen(Color.seaShell);
    return pens_[Color.seaShell];
  }
  ///
  public static Pen sienna() {
    if (!(Color.sienna in pens_))
      pens_[Color.sienna] = new Pen(Color.sienna);
    return pens_[Color.sienna];
  }
  ///
  public static Pen silver() {
    if (!(Color.silver in pens_))
      pens_[Color.silver] = new Pen(Color.silver);
    return pens_[Color.silver];
  }
  ///
  public static Pen skyBlue() {
    if (!(Color.skyBlue in pens_))
      pens_[Color.skyBlue] = new Pen(Color.skyBlue);
    return pens_[Color.skyBlue];
  }
  ///
  public static Pen slateBlue() {
    if (!(Color.slateBlue in pens_))
      pens_[Color.slateBlue] = new Pen(Color.slateBlue);
    return pens_[Color.slateBlue];
  }
  ///
  public static Pen slateGray() {
    if (!(Color.slateGray in pens_))
      pens_[Color.slateGray] = new Pen(Color.slateGray);
    return pens_[Color.slateGray];
  }
  ///
  public static Pen snow() {
    if (!(Color.snow in pens_))
      pens_[Color.snow] = new Pen(Color.snow);
    return pens_[Color.snow];
  }
  ///
  public static Pen springGreen() {
    if (!(Color.springGreen in pens_))
      pens_[Color.springGreen] = new Pen(Color.springGreen);
    return pens_[Color.springGreen];
  }
  ///
  public static Pen steelBlue() {
    if (!(Color.steelBlue in pens_))
      pens_[Color.steelBlue] = new Pen(Color.steelBlue);
    return pens_[Color.steelBlue];
  }
  ///
  public static Pen tan() {
    if (!(Color.tan in pens_))
      pens_[Color.tan] = new Pen(Color.tan);
    return pens_[Color.tan];
  }
  ///
  public static Pen teal() {
    if (!(Color.teal in pens_))
      pens_[Color.teal] = new Pen(Color.teal);
    return pens_[Color.teal];
  }
  ///
  public static Pen thistle() {
    if (!(Color.thistle in pens_))
      pens_[Color.thistle] = new Pen(Color.thistle);
    return pens_[Color.thistle];
  }
  ///
  public static Pen tomato() {
    if (!(Color.tomato in pens_))
      pens_[Color.tomato] = new Pen(Color.tomato);
    return pens_[Color.tomato];
  }
  ///
  public static Pen turquoise() {
    if (!(Color.turquoise in pens_))
      pens_[Color.turquoise] = new Pen(Color.turquoise);
    return pens_[Color.turquoise];
  }
  ///
  public static Pen violet() {
    if (!(Color.violet in pens_))
      pens_[Color.violet] = new Pen(Color.violet);
    return pens_[Color.violet];
  }
  ///
  public static Pen wheat() {
    if (!(Color.wheat in pens_))
      pens_[Color.wheat] = new Pen(Color.wheat);
    return pens_[Color.wheat];
  }
  ///
  public static Pen white() {
    if (!(Color.white in pens_))
      pens_[Color.white] = new Pen(Color.white);
    return pens_[Color.white];
  }
  ///
  public static Pen whiteSmoke() {
    if (!(Color.whiteSmoke in pens_))
      pens_[Color.whiteSmoke] = new Pen(Color.whiteSmoke);
    return pens_[Color.whiteSmoke];
  }
  ///
  public static Pen yellow() {
    if (!(Color.yellow in pens_))
      pens_[Color.yellow] = new Pen(Color.yellow);
    return pens_[Color.yellow];
  }
  ///
  public static Pen yellowGreen() {
    if (!(Color.yellowGreen in pens_))
      pens_[Color.yellowGreen] = new Pen(Color.yellowGreen);
    return pens_[Color.yellowGreen];
  }

  private static Pen fromSystemColor(Color color) {
    if (systemPens_ == null)
      systemPens_ = new Pen[33];
    int i = cast(int)color.toKnownColor();
    if (i > 167) i -= 141;
    i--;
    if (systemPens_[i] is null)
      systemPens_[i] = new Pen(color, true);
    return systemPens_[i];
  }

  ///
  public static Pen activeBorder() {
    return fromSystemColor(Color.activeBorder);
  }
  ///
  public static Pen activeCaption() {
    return fromSystemColor(Color.activeCaption);
  }
  ///
  public static Pen activeCaptionText() {
    return fromSystemColor(Color.activeCaptionText);
  }
  ///
  public static Pen appWorkspace() {
    return fromSystemColor(Color.appWorkspace);
  }
  ///
  public static Pen buttonFace() {
    return fromSystemColor(Color.buttonFace);
  }
  ///
  public static Pen buttonHighlight() {
    return fromSystemColor(Color.buttonHighlight);
  }
  ///
  public static Pen buttonShadow() {
    return fromSystemColor(Color.buttonShadow);
  }
  ///
  public static Pen control() {
    return fromSystemColor(Color.control);
  }
  ///
  public static Pen controlText() {
    return fromSystemColor(Color.controlText);
  }
  ///
  public static Pen controlDark() {
    return fromSystemColor(Color.controlDark);
  }
  ///
  public static Pen controlDarkDark() {
    return fromSystemColor(Color.controlDarkDark);
  }
  ///
  public static Pen controlLight() {
    return fromSystemColor(Color.controlLight);
  }
  ///
  public static Pen controlLightLight() {
    return fromSystemColor(Color.controlLightLight);
  }
  ///
  public static Pen desktop() {
    return fromSystemColor(Color.desktop);
  }
  ///
  public static Pen gradientActiveCaption() {
    return fromSystemColor(Color.gradientActiveCaption);
  }
  ///
  public static Pen gradientInactiveCaption() {
    return fromSystemColor(Color.gradientInactiveCaption);
  }
  ///
  public static Pen grayText() {
    return fromSystemColor(Color.grayText);
  }
  ///
  public static Pen highlight() {
    return fromSystemColor(Color.highlight);
  }
  ///
  public static Pen highlightText() {
    return fromSystemColor(Color.highlightText);
  }
  ///
  public static Pen hotTrack() {
    return fromSystemColor(Color.hotTrack);
  }
  ///
  public static Pen inactiveBorder() {
    return fromSystemColor(Color.inactiveBorder);
  }
  ///
  public static Pen inactiveCaption() {
    return fromSystemColor(Color.inactiveCaption);
  }
  ///
  public static Pen inactiveCaptionText() {
    return fromSystemColor(Color.inactiveCaptionText);
  }
  ///
  public static Pen info() {
    return fromSystemColor(Color.info);
  }
  ///
  public static Pen infoText() {
    return fromSystemColor(Color.infoText);
  }
  ///
  public static Pen menu() {
    return fromSystemColor(Color.menu);
  }
  ///
  public static Pen menuBar() {
    return fromSystemColor(Color.menuBar);
  }
  ///
  public static Pen menuHighlight() {
    return fromSystemColor(Color.menuHighlight);
  }
  ///
  public static Pen menuText() {
    return fromSystemColor(Color.menuText);
  }
  ///
  public static Pen scrollBar() {
    return fromSystemColor(Color.scrollBar);
  }
  ///
  public static Pen window() {
    return fromSystemColor(Color.window);
  }
  ///
  public static Pen windowFrame() {
    return fromSystemColor(Color.windowFrame);
  }
  ///
  public static Pen windowText() {
    return fromSystemColor(Color.windowText);
  }

}

/**
 */
public abstract class FontCollection {

  private Handle nativeCollection_;

  ~this() {
    dispose(false);
  }

  /**
   */
  public final void dispose() {
    dispose(true);
  }

  /**
   */
  public final FontFamily[] families() {
    int sought, found;
    Status status = GdipGetFontCollectionFamilyCount(nativeCollection_, sought);
    if (status != Status.OK)
      throw statusException(status);

    Handle[] gpfamilies = new Handle[found];
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
public final class InstalledFontCollection : FontCollection {

  /**
   */
  public this() {
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
public final class PrivateFontCollection : FontCollection {

  /**
   */
  public this() {
    Status status = GdipNewPrivateFontCollection(nativeCollection_);
    if (status != Status.OK)
      throw statusException(status);
  }

  alias FontCollection.dispose dispose;

  /**
   */
  public void addFontFile(string fileName) {
    Status status = GdipPrivateAddFontFile(nativeCollection_, fileName.toUtf16z());
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void addMemoryFont(void* memory, int length) {
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

/**
 */
public final class FontFamily {

  private Handle nativeFamily_;

  /**
   */
  public this(GenericFontFamilies genericFamily) {
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
  public this(string name, FontCollection fontCollection = null) {
    Status status = GdipCreateFontFamilyFromName(name.toUtf16z(), (fontCollection is null ? Handle.init : fontCollection.nativeCollection_), nativeFamily_);
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
  public void dispose() {
    if (nativeFamily_ != Handle.init) {
      GdipDeleteFontFamilySafe(nativeFamily_);
      nativeFamily_ = Handle.init;
    }
  }

  public Object clone() {
    Handle clonedFamily;
    Status status = GdipCloneFontFamily(nativeFamily_, clonedFamily);
    if (status != Status.OK)
      throw statusException(status);
    return new FontFamily(clonedFamily);
  }

  /**
   */
  public bool isStyleAvailable(FontStyle style) {
    int result;
    Status status = GdipIsStyleAvailable(nativeFamily_, style, result);
    if (status != Status.OK)
      throw statusException(status);
    return result == 1;
  }

  /**
   */
  public short getEmHeight(FontStyle style) {
    short emHeight;
    Status status = GdipGetEmHeight(nativeFamily_, style, emHeight);
    if (status != Status.OK)
      throw statusException(status);
    return emHeight;
  }

  /**
   */
  public short getCellAscent(FontStyle style) {
    short cellAcscent;
    Status status = GdipGetCellAscent(nativeFamily_, style, cellAcscent);
    if (status != Status.OK)
      throw statusException(status);
    return cellAcscent;
  }

  /**
   */
  public short getCellDescent(FontStyle style) {
    short cellDescent;
    Status status = GdipGetCellDescent(nativeFamily_, style, cellDescent);
    if (status != Status.OK)
      throw statusException(status);
    return cellDescent;
  }

  /**
   */
  public short getLineSpacing(FontStyle style) {
    short lineSpacing;
    Status status = GdipGetLineSpacing(nativeFamily_, style, lineSpacing);
    if (status != Status.OK)
      throw statusException(status);
    return lineSpacing;
  }

  /**
   */
  public string getName(int language) {
    wchar[32] buffer;
    Status status = GdipGetFamilyName(nativeFamily_, buffer.ptr, language);
    if (status != Status.OK)
      throw statusException(status);

    return toUtf8(buffer.ptr);
  }

  /**
   */
  public string name() {
    return getName(Culture.currentUI.lcid);
  }

  /**
   */
  public static FontFamily genericSerif() {
    return new FontFamily(GenericFontFamilies.Serif);
  }

  /**
   */
  public static FontFamily genericSansSerif() {
    return new FontFamily(GenericFontFamilies.SansSerif);
  }

  /**
   */
  public static FontFamily genericMonospace() {
    return new FontFamily(GenericFontFamilies.Monospace);
  }

  private this(Handle family) {
    nativeFamily_ = family;
  }

  package Handle nativeFamily() {
    return nativeFamily_;
  }

}

package const string[FontStyle.max + 1] FontStyleName = [
  FontStyle.Regular: "Regular",
  FontStyle.Bold: "Bold",
  FontStyle.Italic: "Italic",
  FontStyle.Underline: "Underline",
  FontStyle.Strikeout: "Strikeout"
];

/**
 */
public final class Font {

  private Handle nativeFont_;
  private float size_;
  private FontStyle style_;
  private GraphicsUnit unit_;
  private FontFamily fontFamily_;

  /**
   */
  public this(string familyName, float emSize, FontStyle style = FontStyle.Regular, GraphicsUnit unit = GraphicsUnit.Point) {
    this(new FontFamily(familyName), emSize, style, unit);
  }

  /**
   */
  public this(string familyName, float emSize, GraphicsUnit unit) {
    this(familyName, emSize, FontStyle.Regular, unit);
  }

  /**
   */
  public this(FontFamily family, float emSize, GraphicsUnit unit) {
    this(family, emSize, FontStyle.Regular, unit);
  }

  /**
   */
  public this(FontFamily family, float emSize, FontStyle style = FontStyle.Regular, GraphicsUnit unit = GraphicsUnit.Point) {
    if (family is null)
      throw new ArgumentNullException("family");

    size_ = emSize;
    style_ = style;
    unit_ = unit;

    if (fontFamily_ is null)
      fontFamily_ = new FontFamily(family.nativeFamily);

    Status status = GdipCreateFont(fontFamily_.nativeFamily, size_, style_, unit_, nativeFont_);
    if (status != Status.OK) {
      if (status == Status.FontStyleNotFound)
        throw new ArgumentException("Font '" ~ fontFamily_.name ~ "' does not support style '" ~ FontStyleName[style_] ~ "'.");
      throw statusException(status);
    }

    // Sync size
    status = GdipGetFontSize(nativeFont_, size_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public this(Font prototype, FontStyle newStyle) {
    this(prototype.fontFamily, prototype.size, newStyle, prototype.unit);
  }

  ~this() {
    dispose();
  }

  /**
   */
  public void dispose() {
    fontFamily_ = null;
    if (nativeFont_ != Handle.init) {
      GdipDeleteFontSafe(nativeFont_);
      nativeFont_ = Handle.init;
    }
  }

  public static Font fromHdc(Handle hdc) {
    Handle font;
    Status status = GdipCreateFontFromDC(hdc, font);
    if (status != Status.OK)
      throw statusException(status);
    return new Font(font);
  }

  /**
   */
  public static Font fromHfont(Handle hfont) {
    Font font = null;

    LOGFONT logFont;
    GetObject(hfont, LOGFONT.sizeof, &logFont);

    Handle hdc = GetDC(Handle.init);
    try {
      font = fromLogFont(logFont, hdc);
    }
    finally {
      ReleaseDC(Handle.init, hdc);
    }

    return font;
  }

  /**
   */
  public static Font fromLogFont(ref LOGFONT logFont, Handle hdc) {
    Handle nativeFont;
    Status status = GdipCreateFontFromLogfontW(hdc, logFont, nativeFont);
    if (status != Status.OK)
      throw statusException(status);
    return new Font(nativeFont);
  }

  /**
   */
  public Handle toHfont() {
    LOGFONT logFont;
    toLogFont(logFont);
    return CreateFontIndirect(logFont);
  }

  /**
   */
  public void toLogFont(ref LOGFONT logFont) {
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
  public void toLogFont(ref LOGFONT logFont, Graphics graphics) {
    if (graphics is null)
      throw new ArgumentNullException("graphics");

    Status status = GdipGetLogFontW(nativeFont_, graphics.nativeGraphics, logFont);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  public void clone() {
    Handle cloneFont;
    Status status = GdipCloneFont(nativeFont_, cloneFont);
    if (status != Status.OK)
      throw statusException(status);
    return new Font(cloneFont);
  }

  /**
   */
  public float getHeight(float dpi) {
    float height = 0f;
    Status status = GdipGetFontHeightGivenDPI(nativeFont_, dpi, height);
    if (status != Status.OK)
      throw statusException(status);
    return height;
  }

  /**
   */
  public float getHeight() {
    float height = 0f;
    Handle hdc = GetDC(Handle.init);
    try {
      scope g = Graphics.fromHdc(hdc);
      height = getHeight(g);
    }
    finally {
      ReleaseDC(Handle.init, hdc);
    }
    return height;
  }

  /**
   */
  public float getHeight(Graphics graphics) {
    if (graphics is null)
      throw new ArgumentNullException("graphics");

    float height = 0f;
    Status status = GdipGetFontHeight(nativeFont_, graphics.nativeGraphics, height);
    if (status != Status.OK)
      throw statusException(status);
    return height;
  }

  /**
   */
  public FontFamily fontFamily() {
    return fontFamily_;
  }

  /**
   */
  public string name() {
    return fontFamily.name;
  }

  /**
   */
  public float size() {
    return size_;
  }

  /**
   */
  public FontStyle style() {
    return style_;
  }

  /**
   */
  public GraphicsUnit unit() {
    return unit_;
  }

  public int height() {
    return cast(int)std.math.ceil(getHeight());
  }

  package Handle nativeFont() {
    return nativeFont_;
  }

  private this(Handle nativeFont) {
    nativeFont_ = nativeFont;

    float size = 0f;
    FontStyle style = FontStyle.Regular;
    GraphicsUnit unit = GraphicsUnit.Point;

    Status status = GdipGetFontSize(nativeFont, size);
    if (status != Status.OK)
      throw statusException(status);

    status = GdipGetFontStyle(nativeFont, style);
    if (status != Status.OK)
      throw statusException(status);

    status = GdipGetFontUnit(nativeFont, unit);
    if (status != Status.OK)
      throw statusException(status);

    Handle family;
    status = GdipGetFamily(nativeFont_, family);
    if (status != Status.OK)
      throw statusException(status);
    fontFamily_ = new FontFamily(family);

    this(fontFamily_, size, style, unit);
  }

}

/**
 */
public final class StringFormat {

  private Handle nativeFormat_;

  /**
   */
  public this(StringFormatFlags options = cast(StringFormatFlags)0, int language = 0 /*LANG_NEUTRAL*/) {
    Status status = GdipCreateStringFormat(options, language, nativeFormat_);
    if (status != Status.OK)
      throw statusException(status);
  }

  ~this() {
    dispose();
  }

  /**
   */
  public void dispose() {
    if (nativeFormat_ != Handle.init) {
      GdipDeleteStringFormatSafe(nativeFormat_);
      nativeFormat_ = Handle.init;
    }
  }

  /**
   */
  public void formatFlags(StringFormatFlags value) {
    Status status = GdipSetStringFormatFlags(nativeFormat_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Ditto
   */
  public StringFormatFlags formatFlags() {
    StringFormatFlags value = cast(StringFormatFlags)0;
    Status status = GdipGetStringFormatFlags(nativeFormat_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  public void alignment(StringAlignment value) {
    Status status = GdipSetStringFormatAlign(nativeFormat_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Ditto
   */
  public StringAlignment alignment() {
    StringAlignment value;
    Status status = GdipGetStringFormatAlign(nativeFormat_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  public void lineAlignment(StringAlignment value) {
    Status status = GdipSetStringFormatLineAlign(nativeFormat_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Ditto
   */
  public StringAlignment lineAlignment() {
    StringAlignment value;
    Status status = GdipGetStringFormatLineAlign(nativeFormat_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  public void trimming(StringTrimming value) {
    Status status = GdipSetStringFormatTrimming(nativeFormat_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Ditto
   */
  public StringTrimming trimming() {
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

public final class GraphicsPath {

  private Handle nativePath_;

  private const float FlatnessDefault = 1.0f / 4.0f;

  public this(FillMode fillMode = FillMode.Alternate) {
    Status status = GdipCreatePath(fillMode, nativePath_);
    if (status != Status.OK)
      throw statusException(status);
  }

  public this(PointF[] points, ubyte[] types, FillMode fillMode = FillMode.Alternate) {
    if (points.length != types.length)
      throw statusException(Status.InvalidParameter);

    Status status = GdipCreatePath2(points.ptr, types.ptr, types.length, fillMode, nativePath_);
    if (status != Status.OK)
      throw statusException(status);
  }

  public this(Point[] points, ubyte[] types, FillMode fillMode = FillMode.Alternate) {
    if (points.length != types.length)
      throw statusException(Status.InvalidParameter);

    Status status = GdipCreatePath2I(points.ptr, types.ptr, types.length, fillMode, nativePath_);
    if (status != Status.OK)
      throw statusException(status);
  }

  ~this() {
    dispose();
  }

  public void dispose() {
    if (nativePath_ != Handle.init) {
      GdipDeletePathSafe(nativePath_);
      nativePath_ = Handle.init;
    }
  }

  public void clone() {
    Handle clonepath;
    Status status = GdipClonePath(nativePath_, clonepath);
    if (status != Status.OK)
      throw statusException(status);
    return new GraphicsPath(clonepath);
  }

  public void reset() {
    Status status = GdipResetPath(nativePath_);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void startFigure() {
    Status status = GdipStartPathFigure(nativePath_);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void closeFigure() {
    Status status = GdipClosePathFigure(nativePath_);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void closeAllFigures() {
    Status status = GdipClosePathFigures(nativePath_);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void setMarkers() {
    Status status = GdipSetPathMarker(nativePath_);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void clearMarkers() {
    Status status = GdipClearPathMarkers(nativePath_);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void reverse() {
    Status status = GdipReversePath(nativePath_);
    if (status != Status.OK)
      throw statusException(status);
  }

  public PointF getLastPoint() {
    PointF lastPoint;
    Status status = GdipGetPathLastPoint(nativePath_, lastPoint);
    if (status != Status.OK)
      throw statusException(status);
    return lastPoint;
  }

  public void addLine(PointF pt1, PointF pt2) {
    addLine(pt1.x, pt1.y, pt2.x, pt2.y);
  }

  public void addLine(float x1, float y1, float x2, float y2) {
    Status status = GdipAddPathLine(nativePath_, x1, y1, x2, y2);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addLines(PointF[] points) {
    Status status = GdipAddPathLine2(nativePath_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addLine(Point pt1, Point pt2) {
    addLine(pt1.x, pt1.y, pt2.x, pt2.y);
  }

  public void addLine(int x1, int y1, int x2, int y2) {
    Status status = GdipAddPathLineI(nativePath_, x1, y1, x2, y2);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addLines(Point[] points) {
    Status status = GdipAddPathLine2I(nativePath_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addArc(RectF rect, float startAngle, float sweepAngle) {
    addArc(rect.x, rect.y, rect.width, rect.height, startAngle, sweepAngle);
  }

  public void addArc(float x, float y, float width, float height, float startAngle, float sweepAngle) {
    Status status = GdipAddPathArc(nativePath_, x, y, width, height, startAngle, sweepAngle);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addArc(Rect rect, float startAngle, float sweepAngle) {
    addArc(rect.x, rect.y, rect.width, rect.height, startAngle, sweepAngle);
  }

  public void addArc(int x, int y, int width, int height, float startAngle, float sweepAngle) {
    Status status = GdipAddPathArcI(nativePath_, x, y, width, height, startAngle, sweepAngle);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addBezier(PointF pt1, PointF pt2, PointF pt3, PointF pt4) {
    addBezier(pt1.x, pt1.y, pt2.x, pt2.y, pt3.x, pt3.y, pt4.x, pt4.y);
  }

  public void addBezier(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) {
    Status status = GdipAddPathBezier(nativePath_, x2, y1, x2, y2, x3, y3, x4, y4);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addBeziers(PointF[] points) {
    Status status = GdipAddPathBeziers(nativePath_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addBezier(Point pt1, Point pt2, Point pt3, Point pt4) {
    addBezier(pt1.x, pt1.y, pt2.x, pt2.y, pt3.x, pt3.y, pt4.x, pt4.y);
  }

  public void addBezier(int x1, int y1, int x2, int y2, int x3, int y3, int x4, int y4) {
    Status status = GdipAddPathBezierI(nativePath_, x2, y1, x2, y2, x3, y3, x4, y4);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addBeziers(Point[] points) {
    Status status = GdipAddPathBeziersI(nativePath_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addCurve(PointF[] points) {
    Status status = GdipAddPathCurve(nativePath_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addCurve(PointF[] points, float tension) {
    Status status = GdipAddPathCurve2(nativePath_, points.ptr, points.length, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addCurve(PointF[] points, int offset, int numberOfSegments, float tension) {
    Status status = GdipAddPathCurve3(nativePath_, points.ptr, points.length, offset, numberOfSegments, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addCurve(Point[] points) {
    Status status = GdipAddPathCurveI(nativePath_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addCurve(Point[] points, float tension) {
    Status status = GdipAddPathCurve2I(nativePath_, points.ptr, points.length, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addCurve(Point[] points, int offset, int numberOfSegments, float tension) {
    Status status = GdipAddPathCurve3I(nativePath_, points.ptr, points.length, offset, numberOfSegments, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addClosedCurve(PointF[] points) {
    Status status = GdipAddPathClosedCurve(nativePath_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addClosedCurve(PointF[] points, float tension) {
    Status status = GdipAddPathClosedCurve2(nativePath_, points.ptr, points.length, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addClosedCurve(Point[] points) {
    Status status = GdipAddPathClosedCurveI(nativePath_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addClosedCurve(Point[] points, float tension) {
    Status status = GdipAddPathClosedCurve2I(nativePath_, points.ptr, points.length, tension);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addRectangle(RectF rect) {
    Status status = GdipAddPathRectangle(nativePath_, rect.x, rect.y, rect.width, rect.height);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addRectangles(RectF[] rects) {
    Status status = GdipAddPathRectangles(nativePath_, rects.ptr, rects.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addRectangle(Rect rect) {
    Status status = GdipAddPathRectangleI(nativePath_, rect.x, rect.y, rect.width, rect.height);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addRectangles(Rect[] rects) {
    Status status = GdipAddPathRectanglesI(nativePath_, rects.ptr, rects.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addEllipse(RectF rect) {
    addEllipse(rect.x, rect.y, rect.width, rect.height);
  }

  public void addEllipse(float x, float y, float width, float height) {
    Status status = GdipAddPathEllipse(nativePath_, x, y, width, height);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addEllipse(Rect rect) {
    addEllipse(rect.x, rect.y, rect.width, rect.height);
  }

  public void addEllipse(int x, int y, int width, int height) {
    Status status = GdipAddPathEllipseI(nativePath_, x, y, width, height);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addPie(RectF rect, float startAngle, float sweepAngle) {
    addPie(rect.x, rect.y, rect.width, rect.height, startAngle, sweepAngle);
  }

  public void addPie(float x, float y, float width, float height, float startAngle, float sweepAngle) {
    Status status = GdipAddPathPie(nativePath_, x, y, width, height, startAngle, sweepAngle);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addPie(Rect rect, float startAngle, float sweepAngle) {
    addPie(rect.x, rect.y, rect.width, rect.height, startAngle, sweepAngle);
  }

  public void addPie(int x, int y, int width, int height, float startAngle, float sweepAngle) {
    Status status = GdipAddPathPieI(nativePath_, x, y, width, height, startAngle, sweepAngle);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addPolygon(PointF[] points) {
    Status status = GdipAddPathPolygon(nativePath_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addPolygon(Point[] points) {
    Status status = GdipAddPathPolygonI(nativePath_, points.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addPath(GraphicsPath addingPath, bool connect) {
    if (addingPath is null)
      throw new ArgumentNullException("addingPath");

    Status status = GdipAddPathPath(nativePath_, addingPath.nativePath, (connect ? 1 : 0));
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addString(string s, FontFamily family, FontStyle style, float emSize, PointF origin, StringFormat format) {
    RectF layoutRect = RectF(origin.x, origin.y, 0, 0);
    Status status = GdipAddPathString(nativePath_, s.toUtf16z(), s.length, (family is null ? Handle.init : family.nativeFamily), style, emSize, layoutRect, (format is null ? Handle.init : format.nativeFormat));
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addString(string s, FontFamily family, FontStyle style, float emSize, RectF layoutRect, StringFormat format) {
    Status status = GdipAddPathString(nativePath_, s.toUtf16z(), s.length, (family is null ? Handle.init : family.nativeFamily), style, emSize, layoutRect, (format is null ? Handle.init : format.nativeFormat));
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addString(string s, FontFamily family, FontStyle style, float emSize, Point origin, StringFormat format) {
    Rect layoutRect = Rect(origin.x, origin.y, 0, 0);
    Status status = GdipAddPathStringI(nativePath_, s.toUtf16z(), s.length, (family is null ? Handle.init : family.nativeFamily), style, emSize, layoutRect, (format is null ? Handle.init : format.nativeFormat));
    if (status != Status.OK)
      throw statusException(status);
  }

  public void addString(string s, FontFamily family, FontStyle style, float emSize, Rect layoutRect, StringFormat format) {
    Status status = GdipAddPathStringI(nativePath_, s.toUtf16z(), s.length, (family is null ? Handle.init : family.nativeFamily), style, emSize, layoutRect, (format is null ? Handle.init : format.nativeFormat));
    if (status != Status.OK)
      throw statusException(status);
  }

  public void transform(Matrix matrix) {
    if (matrix is null)
      throw new ArgumentNullException("matrix");

    if (matrix.nativeMatrix != Handle.init) {
      Status status = GdipTransformPath(nativePath_, matrix.nativeMatrix);
      if (status != Status.OK)
        throw statusException(status);
    }
  }

  public RectF getBounds(Matrix matrix = null, Pen pen = null) {
    Handle nativeMatrix, nativePen;
    if (matrix !is null) nativeMatrix = matrix.nativeMatrix;
    if (pen !is null) nativePen = pen.nativePen;

    RectF bounds;
    Status status = GdipGetPathWorldBounds(nativePath_, bounds, nativeMatrix, nativePen);
    if (status != Status.OK)
      throw statusException(status);
    return bounds;
  }

  public void flatten(Matrix matrix = null, float flatness = FlatnessDefault) {
    Status status = GdipFlattenPath(nativePath_, (matrix is null ? Handle.init : matrix.nativeMatrix), flatness);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void widen(Pen pen, Matrix matrix = null, float flatness = FlatnessDefault) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    Status status = GdipWidenPath(nativePath_, pen.nativePen, (matrix is null ? Handle.init : matrix.nativeMatrix), flatness);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void outline(Matrix matrix = null, float flatness = FlatnessDefault) {
    Status status = GdipWindingModeOutline(nativePath_, (matrix is null ? Handle.init : matrix.nativeMatrix), flatness);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void warp(PointF[] destPoints, RectF srcRect, Matrix matrix = null, WarpMode warpMode = WarpMode.Perspective, float flatness = FlatnessDefault) {
    Status status = GdipWarpPath(nativePath_, (matrix is null ? Handle.init : matrix.nativeMatrix), destPoints.ptr, destPoints.length, srcRect.x, srcRect.y, srcRect.width, srcRect.height, warpMode, flatness);
    if (status != Status.OK)
      throw statusException(status);
  }

  public bool isVisible(PointF pt, Graphics graphics = null) {
    int result;
    Status status = GdipIsVisiblePathPoint(nativePath_, pt.x, pt.y, (graphics is null ? Handle.init : graphics.nativeGraphics), result);
    if (status != Status.OK)
      throw statusException(status);
    return result != 0;
  }

  public bool isVisible(float x, float y, Graphics graphics = null) {
    return isVisible(PointF(x, y), graphics);
  }

  public bool isVisible(Point pt, Graphics graphics = null) {
    int result;
    Status status = GdipIsVisiblePathPointI(nativePath_, pt.x, pt.y, (graphics is null ? Handle.init : graphics.nativeGraphics), result);
    if (status != Status.OK)
      throw statusException(status);
    return result != 0;
  }

  public bool isVisible(int x, int y, Graphics graphics = null) {
    return isVisible(Point(x, y), graphics);
  }

  public bool isOutlineVisible(PointF pt, Pen pen, Graphics graphics = null) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    int result;
    Status status = GdipIsOutlineVisiblePathPoint(nativePath_, pt.x, pt.y, pen.nativePen, (graphics is null ? Handle.init : graphics.nativeGraphics), result);
    if (status != Status.OK)
      throw statusException(status);
    return result != 0;
  }

  public bool isOutlineVisible(float x, float y, Pen pen, Graphics graphics = null) {
    return isOutlineVisible(PointF(x, y), pen, graphics);
  }

  public bool isOutlineVisible(Point pt, Pen pen, Graphics graphics = null) {
    if (pen is null)
      throw new ArgumentNullException("pen");

    int result;
    Status status = GdipIsOutlineVisiblePathPointI(nativePath_, pt.x, pt.y, pen.nativePen, (graphics is null ? Handle.init : graphics.nativeGraphics), result);
    if (status != Status.OK)
      throw statusException(status);
    return result != 0;
  }

  public bool isOutlineVisible(int x, int y, Pen pen, Graphics graphics = null) {
    return isOutlineVisible(Point(x, y), pen, graphics);
  }

  public void fillMode(FillMode value) {
    Status status = GdipSetPathFillMode(nativePath_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  public FillMode fillMode() {
    FillMode value;
    Status status = GdipGetPathFillMode(nativePath_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  public int pointCount() {
    int value;
    Status status = GdipGetPointCount(nativePath_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  public ubyte[] pathTypes() {  
    int count = pointCount;
    ubyte[] types = new ubyte[count];
    Status status = GdipGetPathTypes(nativePath_, types.ptr, count);
    if (status != Status.OK)
      throw statusException(status);
    return types;
  }

  public PointF[] pathPoints() {
    int count = pointCount;
    PointF[] points = new PointF[count];
    Status status = GdipGetPathPoints(nativePath_, points.ptr, count);
    if (status != Status.OK)
      throw statusException(status);
    return points;
  }

  private this(Handle nativePath) {
    nativePath_ = nativePath;
  }

  package Handle nativePath() {
    return nativePath_;
  }

}

public final class GraphicsPathIterator {

  private Handle nativeIter_;

  public this(GraphicsPath path) {
    Status status = GdipCreatePathIter(nativeIter_, (path is null ? Handle.init : path.nativePath));
    if (status != Status.OK)
      throw statusException(status);
  }

  ~this() {
    dispose();
  }

  public void dispose() {
    if (nativeIter_ != Handle.init) {
      GdipDeletePathIterSafe(nativeIter_);
      nativeIter_ = Handle.init;
    }
  }

  public int nextSubpath(out int startIndex, out int endIndex, out bool isClosed) {
    int resultCount, closed;
    Status status = GdipPathIterNextSubpath(nativeIter_, resultCount, startIndex, endIndex, closed);
    if (status != Status.OK)
      throw statusException(status);
    isClosed = (closed != 0);
    return resultCount;
  }

  public int nextSubpath(GraphicsPath path, out bool isClosed) {
    int resultCount, closed;
    Status status = GdipPathIterNextSubpathPath(nativeIter_, resultCount, (path is null ? Handle.init : path.nativePath), closed);
    if (status != Status.OK)
      throw statusException(status);
    isClosed = (closed != 0);
    return resultCount;
  }

  public int nextPathType(out ubyte pathType, out int startIndex, out int endIndex) {
    int resultCount;
    Status status = GdipPathIterNextPathType(nativeIter_, resultCount, pathType, startIndex, endIndex);
    if (status != Status.OK)
      throw statusException(status);
    return resultCount;
  }

  public int nextMarker(out int startIndex, out int endIndex) {
    int resultCount;
    Status status = GdipPathIterNextMarker(nativeIter_, resultCount, startIndex, endIndex);
    if (status != Status.OK)
      throw statusException(status);
    return resultCount;
  }

  public int nextMarker(GraphicsPath path) {
    int resultCount;
    Status status = GdipPathIterNextMarkerPath(nativeIter_, resultCount, (path is null ? Handle.init : path.nativePath));
    if (status != Status.OK)
      throw statusException(status);
    return resultCount;
  }

  public void rewind() {
    Status status = GdipPathIterRewind(nativeIter_);
    if (status != Status.OK)
      throw statusException(status);
  }

  public int enumerate(ref PointF[] points, ref ubyte[] types) {
    if (points.length != types.length)
      throw statusException(Status.InvalidParameter);

    int resultCount;
    Status status = GdipPathIterEnumerate(nativeIter_, resultCount, points.ptr, types.ptr, points.length);
    if (status != Status.OK)
      throw statusException(status);
    return resultCount;
  }

  public int copyData(ref PointF[] points, ref ubyte[] types, int startIndex, int endIndex) {
    if (points.length != types.length)
      throw statusException(Status.InvalidParameter);

    int resultCount;
    Status status = GdipPathIterCopyData(nativeIter_, resultCount, points.ptr, types.ptr, startIndex, endIndex);
    if (status != Status.OK)
      throw statusException(status);
    return resultCount;
  }

  public int count() {
    int result;
    Status status = GdipPathIterGetCount(nativeIter_, result);
    if (status != Status.OK)
      throw statusException(status);
    return result;
  }

  public int subpathCount() {
    int result;
    Status status = GdipPathIterGetSubpathCount(nativeIter_, result);
    if (status != Status.OK)
      throw statusException(status);
    return result;
  }

  public bool hasCurve() {
    int result;
    Status status = GdipPathIterHasCurve(nativeIter_, result);
    if (status != Status.OK)
      throw statusException(status);
    return result != 0;
  }

}

public final class PathGradientBrush : Brush {

  package this(Handle nativeBrush) {
    nativeBrush_ = nativeBrush;
  }

  public this(PointF[] points, WrapMode wrapMode = WrapMode.Clamp) {
    Status status = GdipCreatePathGradient(points.ptr, points.length, wrapMode, nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  public this(Point[] points, WrapMode wrapMode = WrapMode.Clamp) {
    Status status = GdipCreatePathGradientI(points.ptr, points.length, wrapMode, nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  public this(GraphicsPath path) {
    if (path is null)
      throw new ArgumentNullException("path");

    Status status = GdipCreatePathGradientFromPath(path.nativePath, nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void setSigmaBellShape(float focus, float scale = 1.0) {
    Status status = GdipSetPathGradientSigmaBlend(nativeBrush_, focus, scale);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void setBlendTriangularShape(float focus, float scale = 1.0) {
    Status status = GdipSetPathGradientLinearBlend(nativeBrush_, focus, scale);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void resetTransform() {
    Status status = GdipResetPathGradientTransform(nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void multiplyTransform(Matrix matrix, MatrixOrder order = MatrixOrder.Prepend) {
    if (matrix is null)
      throw new ArgumentNullException("matrix");

    Status status = GdipMultiplyPathGradientTransform(nativeBrush_, matrix.nativeMatrix, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void translateTransform(float dx, float dy, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipTranslatePathGradientTransform(nativeBrush_, dx, dy, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void scaleTransform(float sx, float sy, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipScalePathGradientTransform(nativeBrush_, sx, sy, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void rotateTransform(float angle, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipRotatePathGradientTransform(nativeBrush_, angle, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void centerColor(Color value) {
    Status status = GdipSetPathGradientCenterColor(nativeBrush_, value.toArgb());
    if (status != Status.OK)
      throw statusException(status);
  }

  public Color centerColor() {
    int color;
    Status status = GdipGetPathGradientCenterColor(nativeBrush_, color);
    if (status != Status.OK)
      throw statusException(status);
    return Color.fromArgb(color);
  }

  public void surroundColors(Color[] value) {
    int count;
    Status status = GdipGetPathGradientSurroundColorCount(nativeBrush_, count);
    if (status != Status.OK)
      throw statusException(status);

    if (value.length > count || count <= 0)
      throw statusException(Status.InvalidParameter);

    count = value.length;
    int[] colors = new int[count];
    for (int i = 0; i < count; i++) {
      colors[i] = value[i].toArgb();
    }
    status = GdipSetPathGradientSurroundColorsWithCount(nativeBrush_, colors.ptr, count);
    if (status != Status.OK)
      throw statusException(status);
  }

  public Color[] surroundColors() {
    int count;
    Status status = GdipGetPathGradientSurroundColorCount(nativeBrush_, count);
    if (status != Status.OK)
      throw statusException(status);

    int[] colors = new int[count];
    status = GdipGetPathGradientSurroundColorsWithCount(nativeBrush_, colors.ptr, count);
    if (status != Status.OK)
      throw statusException(status);

    Color[] result = new Color[count];
    for (int i = 0; i < count; i++) {
      result[i] = Color.fromArgb(colors[i]);
    }
    return result;
  }

  public void centerPoint(PointF value) {
    Status status = GdipSetPathGradientCenterPoint(nativeBrush_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  public PointF centerPoint() {
    PointF point;
    Status status = GdipGetPathGradientCenterPoint(nativeBrush_, point);
    if (status != Status.OK)
      throw statusException(status);
    return point;
  }

  public RectF rectangle() {
    RectF rect;
    Status status = GdipGetPathGradientRect(nativeBrush_, rect);
    if (status != Status.OK)
      throw statusException(status);
    return rect;
  }

  public void blend(Blend value) {
    Status status = GdipSetPathGradientBlend(nativeBrush_, value.factors.ptr, value.positions.ptr, value.factors.length);
    if (status != Status.OK)
      throw statusException(status);
  }

  public Blend blend() {
    int count;
    Status status = GdipGetPathGradientBlendCount(nativeBrush_, count);
    if (status != Status.OK)
      throw statusException(status);

    float[] factors = new float[count];
    float[] positions = new float[count];

    status = GdipGetPathGradientBlend(nativeBrush_, factors.ptr, positions.ptr, count);
    if (status != Status.OK)
      throw statusException(status);

    Blend blend = new Blend(count);
    blend.factors = factors.dup;
    blend.positions = positions.dup;
    return blend;
  }

  public void interpolationColors(ColorBlend value) {
    int count = value.colors.length;
    int[] colors = new int[count];
    for (int i = 0; i < count; i++) {
      colors[i] = value.colors[i].toArgb();
    }

    Status status = GdipSetPathGradientPresetBlend(nativeBrush_, colors.ptr, value.positions.ptr, count);
    if (status != Status.OK)
      throw statusException(status);
  }

  public ColorBlend interpolationColors() {
    int count;
    Status status = GdipGetPathGradientPresetBlendCount(nativeBrush_, count);
    if (status != Status.OK)
      throw statusException(status);

    if (count == 0)
      return new ColorBlend;

    int[] colors = new int[count];
    float[] positions = new float[count];

    status = GdipGetPathGradientPresetBlend(nativeBrush_, colors.ptr, positions.ptr, count);
    if (status != Status.OK)
      throw statusException(status);

    ColorBlend blend = new ColorBlend(count);
    blend.positions = positions.dup;
    blend.colors = new Color[count];
    for (int i = 0; i < count; i++) {
      blend.colors[i] = Color.fromArgb(colors[i]);
    }
    return blend;
  }

  public void transform(Matrix value) {
    if (value is null)
      throw new ArgumentNullException("value");

    Status status = GdipSetPathGradientTransform(nativeBrush_, value.nativeMatrix);
    if (status != Status.OK)
      throw statusException(status);
  }

  public Matrix transform() {
    Matrix m = new Matrix;
    Status status = GdipGetPathGradientTransform(nativeBrush_, m.nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
    return m;
  }

  public void focusScales(PointF value) {
    Status status = GdipSetPathGradientFocusScales(nativeBrush_, value.x, value.y);
    if (status != Status.OK)
      throw statusException(status);
  }

  public PointF focusScales() {
    float xScale = 0.0, yScale = 0.0;
    Status status = GdipGetPathGradientFocusScales(nativeBrush_, xScale, yScale);
    if (status != Status.OK)
      throw statusException(status);
    return PointF(xScale, yScale);
  }

  public WrapMode wrapMode() {
    WrapMode value;
    Status status = GdipGetPathGradientWrapMode(nativeBrush_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

}

public final class Region {

  private Handle nativeRegion_;

  public this() {
    Status status = GdipCreateRegion(nativeRegion_);
    if (status != Status.OK)
      throw statusException(status);
  }

  public this(RectF rect) {
    Status status = GdipCreateRegionRect(rect, nativeRegion_);
    if (status != Status.OK)
      throw statusException(status);
  }

  public this(Rect rect) {
    Status status = GdipCreateRegionRectI(rect, nativeRegion_);
    if (status != Status.OK)
      throw statusException(status);
  }

  public this(GraphicsPath path) {
    if (path is null)
      throw new ArgumentNullException("path");

    Status status = GdipCreateRegionPath(path.nativePath, nativeRegion_);
    if (status != Status.OK)
      throw statusException(status);
  }

  ~this() {
    dispose();
  }

  public void dispose() {
    if (nativeRegion_ != Handle.init) {
      GdipDeleteRegionSafe(nativeRegion_);
      nativeRegion_ = Handle.init;
    }
  }

  public static Region fromHrgn(Handle hrgn) {
    Handle region;
    Status status = GdipCreateRegionHrgn(hrgn, region);
    if (status != Status.OK)
      throw statusException(status);
    return new Region(region);
  }

  public void makeInfinite() {
    Status status = GdipSetInfinite(nativeRegion_);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void makeEmpty() {
    Status status = GdipSetEmpty(nativeRegion_);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void intersect(RectF rect) {
    Status status = GdipCombineRegionRect(nativeRegion_, rect, CombineMode.Intersect);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void intersect(Rect rect) {
    Status status = GdipCombineRegionRectI(nativeRegion_, rect, CombineMode.Intersect);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void intersect(GraphicsPath path) {
    if (path is null)
      throw new ArgumentNullException("path");

    Status status = GdipCombineRegionPath(nativeRegion_, path.nativePath, CombineMode.Intersect);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void intersect(Region region) {
    if (region is null)
      throw new ArgumentNullException("region");

    Status status = GdipCombineRegionRegion(nativeRegion_, region.nativeRegion, CombineMode.Intersect);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void unionWith(RectF rect) {
    Status status = GdipCombineRegionRect(nativeRegion_, rect, CombineMode.Union);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void unionWith(Rect rect) {
    Status status = GdipCombineRegionRectI(nativeRegion_, rect, CombineMode.Union);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void unionWith(GraphicsPath path) {
    if (path is null)
      throw new ArgumentNullException("path");

    Status status = GdipCombineRegionPath(nativeRegion_, path.nativePath, CombineMode.Union);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void unionWith(Region region) {
    if (region is null)
      throw new ArgumentNullException("region");

    Status status = GdipCombineRegionRegion(nativeRegion_, region.nativeRegion, CombineMode.Union);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void xor(RectF rect) {
    Status status = GdipCombineRegionRect(nativeRegion_, rect, CombineMode.Xor);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void xor(Rect rect) {
    Status status = GdipCombineRegionRectI(nativeRegion_, rect, CombineMode.Xor);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void xor(GraphicsPath path) {
    if (path is null)
      throw new ArgumentNullException("path");

    Status status = GdipCombineRegionPath(nativeRegion_, path.nativePath, CombineMode.Xor);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void xor(Region region) {
    if (region is null)
      throw new ArgumentNullException("region");

    Status status = GdipCombineRegionRegion(nativeRegion_, region.nativeRegion, CombineMode.Xor);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void exclude(RectF rect) {
    Status status = GdipCombineRegionRect(nativeRegion_, rect, CombineMode.Exclude);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void exclude(Rect rect) {
    Status status = GdipCombineRegionRectI(nativeRegion_, rect, CombineMode.Exclude);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void exclude(GraphicsPath path) {
    if (path is null)
      throw new ArgumentNullException("path");

    Status status = GdipCombineRegionPath(nativeRegion_, path.nativePath, CombineMode.Exclude);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void exclude(Region region) {
    if (region is null)
      throw new ArgumentNullException("region");

    Status status = GdipCombineRegionRegion(nativeRegion_, region.nativeRegion, CombineMode.Exclude);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void complement(RectF rect) {
    Status status = GdipCombineRegionRect(nativeRegion_, rect, CombineMode.Complement);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void complement(Rect rect) {
    Status status = GdipCombineRegionRectI(nativeRegion_, rect, CombineMode.Complement);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void complement(GraphicsPath path) {
    if (path is null)
      throw new ArgumentNullException("path");

    Status status = GdipCombineRegionPath(nativeRegion_, path.nativePath, CombineMode.Complement);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void complement(Region region) {
    if (region is null)
      throw new ArgumentNullException("region");

    Status status = GdipCombineRegionRegion(nativeRegion_, region.nativeRegion, CombineMode.Complement);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void translate(float dx, float dy) {
    Status status = GdipTranslateRegion(nativeRegion_, dx, dy);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void translate(int dx, int dy) {
    Status status = GdipTranslateRegionI(nativeRegion_, dx, dy);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void transform(Matrix matrix) {
    if (matrix is null)
      throw new ArgumentNullException("matrix");

    Status status = GdipTransformRegion(nativeRegion_, matrix.nativeMatrix);
    if (status != Status.OK)
      throw statusException(status);
  }

  public RectF getBounds(Graphics g) {
    if (g is null)
      throw new ArgumentNullException("g");

    RectF rect;
    Status status = GdipGetRegionBounds(nativeRegion_, g.nativeGraphics, rect);
    if (status != Status.OK)
      throw statusException(status);
    return rect;
  }

  public Handle getHrgn(Graphics g) {
    if (g is null)
      throw new ArgumentNullException("g");

    Handle hrgn;
    Status status = GdipGetRegionHRgn(nativeRegion_, g.nativeGraphics, hrgn);
    if (status != Status.OK)
      throw statusException(status);
    return hrgn;
  }

  public bool isEmpty(Graphics g) {
    if (g is null)
      throw new ArgumentNullException("g");

    int result;
    Status status = GdipIsEmptyRegion(nativeRegion_, g.nativeGraphics, result);
    if (status != Status.OK)
      throw statusException(status);
    return result != 0;
  }

  public bool isInfinite(Graphics g) {
    if (g is null)
      throw new ArgumentNullException("g");

    int result;
    Status status = GdipIsInfiniteRegion(nativeRegion_, g.nativeGraphics, result);
    if (status != Status.OK)
      throw statusException(status);
    return result != 0;
  }

  public bool equals(Region region, Graphics g) {
    if (g is null)
      throw new ArgumentNullException("g");
    if (region is null)
      throw new ArgumentNullException("region");

    int result;
    Status status = GdipIsEqualRegion(nativeRegion_, region.nativeRegion_, g.nativeGraphics, result);
    if (status != Status.OK)
      throw statusException(status);
    return result != 0;
  }

  public bool isVisible(PointF point, Graphics g = null) {
    int result;
    Status status = GdipIsVisibleRegionPoint(nativeRegion_, point.x, point.y, (g is null ? Handle.init : g.nativeGraphics), result);
    if (status != Status.OK)
      throw statusException(status);
    return result != 0;
  }

  public bool isVisible(float x, float y, Graphics g = null) {
    return isVisible(PointF(x, y), g);
  }

  public bool isVisible(RectF rect, Graphics g = null) {
    int result;
    Status status = GdipIsVisibleRegionRect(nativeRegion_, rect.x, rect.y, rect.width, rect.height, (g is null ? Handle.init : g.nativeGraphics), result);
    if (status != Status.OK)
      throw statusException(status);
    return result != 0;
  }

  public bool isVisible(float x, float y, float width, float height, Graphics g = null) {
    return isVisible(RectF(x, y, width, height), g);
  }

  public bool isVisible(Point point, Graphics g = null) {
    int result;
    Status status = GdipIsVisibleRegionPointI(nativeRegion_, point.x, point.y, (g is null ? Handle.init : g.nativeGraphics), result);
    if (status != Status.OK)
      throw statusException(status);
    return result != 0;
  }

  public bool isVisible(int x, int y, Graphics g = null) {
    return isVisible(Point(x, y), g);
  }

  public bool isVisible(Rect rect, Graphics g = null) {
    int result;
    Status status = GdipIsVisibleRegionRectI(nativeRegion_, rect.x, rect.y, rect.width, rect.height, (g is null ? Handle.init : g.nativeGraphics), result);
    if (status != Status.OK)
      throw statusException(status);
    return result != 0;
  }

  public bool isVisible(int x, int y, int width, int height, Graphics g = null) {
    return isVisible(Rect(x, y, width, height), g);
  }

  public RectF[] getRegionScans(Matrix matrix) {
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

  package Handle nativeRegion() {
    return nativeRegion_;
  }

}

public final abstract class ImageAnimator {

  private static class ImageInfo {

    private Image image_;
    private bool animated_;
    private int frameCount_;
    private int[] frameDelay_;
    private int frame_;
    private bool frameDirty_;

    public int frameTimer;
    public void delegate() frameChangedHandler;

    this(Image image) {
      image_ = image;
      // Is it an animated image?
      animated_ = canAnimate(image);

      if (animated_) {
        frameCount_ = image.getFrameCount(FrameDimension.time);
        if (auto frameDelayProp = image.getPropertyItem(PropertyTagFrameDelay)) {
          frameDelay_.length = frameCount_;
          for (int i = 0; i < frameCount_; i++)
            frameDelay_[i] = frameDelayProp.value[i * 4] + 0x100 * frameDelayProp.value[(i * 4) + 1] + 0x10000 * frameDelayProp.value[(i * 4) + 2] + 0x1000000 * frameDelayProp.value[(i * 4) + 3];
        }
      }
      else
        frameCount_ = 1;

      if (frameDelay_ == null)
        frameDelay_.length = frameCount_;
    }

    public int frameDelay(int frame) {
      return frameDelay_[frame];
    }

    public Image image() {
      return image_;
    }

    public bool animated() {
      return animated_;
    }

    public int frameCount() {
      return frameCount_;
    }

    public void frame(int value) {
      if (frame_ != value) {
        if (animated) {
          frame_ = value;
          frameDirty_ = true;

          onFrameChanged();
        }
      }
    }

    public int frame() {
      return frame_;
    }

    public bool frameDirty() {
      return frameDirty_;
    }

    private void onFrameChanged() {
      if (frameChangedHandler !is null)
        frameChangedHandler();
    }

    private void updateFrame() {
      if (frameDirty_) {
        // Move onto the specified frame.
        image_.selectActiveFrame(FrameDimension.time, frame);
        frameDirty_ = false;
      }
    }

  }

  private static ImageInfo[] list_;
  private static Thread animationThread_;

  static ~this() {
    list_ = null;
    animationThread_ = null;
  }

  private this() {
  }

  public static void animate(Image image, void delegate() frameChangedHandler) {

    static int animateWorker(void* unused) {
      while (true) {
        synchronized {
          for (int i = 0; i < list_.length; i++) {
            ImageInfo ii = list_[i];
            ii.frameTimer += 5;

            if (ii.frameTimer >= ii.frameDelay(ii.frame)) {
              ii.frameTimer = 0;
              // If the next frame index is less than the number of frames, select it.
              if (ii.frame + 1 < ii.frameCount)
                ii.frame = ii.frame + 1;
              // Otherwise go back to the first frame.
              else
                ii.frame = 0;
            }
          }
        }
        juno.base.threading.sleep(50);
      }
      return 0;
    }

    if (image !is null) {
      ImageInfo ii;
      synchronized (image) {
        ii = new ImageInfo(image);
      }

      stopAnimate(image, frameChangedHandler);

      synchronized {
        if (ii.animated) {
          ii.frameChangedHandler = frameChangedHandler;
          list_ ~= ii;

          if (animationThread_ is null) {
            animationThread_ = new Thread(&animateWorker, null);
            animationThread_.start();
          }
        }
      }
    }
  }

  public static void stopAnimate(Image image, void delegate() frameChangedHandler) {
    if (image !is null && list_ != null) {
      synchronized {
        for (int i = 0; i < list_.length; i++) {
          ImageInfo ii = list_[i];
          if (image is ii.image) {
            if (frameChangedHandler is ii.frameChangedHandler) {
              // Remove the image from the list.
              juno.base.collections.copy!(ImageInfo)(list_, i + 1, list_, i, list_.length - i);
              list_[i] = null;
            }
            break;
          }
        }
      }
    }
  }

  public static void updateFrames() {
    if (list_ != null) {
      synchronized {
        foreach (ii; list_) {
          synchronized (ii.image) {
            ii.updateFrame();
            continue;
          }
        }
      }
    }
  }

  public static void updateFrames(Image image) {
    if (image !is null && list_ != null) {
      synchronized {
        foreach (ii; list_) {
          if (ii.image is image) {
            if (ii.frameDirty) {
              synchronized (ii.image) {
                ii.updateFrame();
              }
            }
            break;
          }
        }
      }
    }
  }

  public static bool canAnimate(Image image) {
    if (image !is null) {
      synchronized (image) {
        foreach (guid; image.frameDimensionsList) {
          auto frame = new FrameDimension(guid);
          if (frame.guid == FrameDimension.time.guid)
            // We can only animate images with more than a single frame.
            return image.getFrameCount(FrameDimension.time) > 1;
        }
      }
    }
    return false;
  }

}

unittest {


/*public const string[KnownColor] KnownColorNames;

static this() {
  KnownColorNames = [
    KnownColor.ActiveBorder: "ActiveBorder"[],
    KnownColor.ActiveCaption: "ActiveCaption",
    KnownColor.ActiveCaptionText: "ActiveCaptionText",
    KnownColor.AppWorkspace: "AppWorkspace",
    KnownColor.Control: "Control",
    KnownColor.ControlDark: "ControlDark",
    KnownColor.ControlDarkDark: "ControlDarkDark",
    KnownColor.ControlLight: "ControlLight",
    KnownColor.ControlLightLight: "ControlLightLight",
    KnownColor.ControlText: "ControlText",
    KnownColor.Desktop: "Desktop",
    KnownColor.GrayText: "GrayText",
    KnownColor.Highlight: "Highlight",
    KnownColor.HighlightText: "HighlightText",
    KnownColor.HotTrack: "HotTrack",
    KnownColor.InactiveBorder: "InactiveBorder",
    KnownColor.InactiveCaption: "InactiveCaption",
    KnownColor.InactiveCaptionText: "InactiveCaptionText",
    KnownColor.Info: "Info",
    KnownColor.InfoText: "InfoText",
    KnownColor.Menu: "Menu",
    KnownColor.MenuText: "MenuText",
    KnownColor.ScrollBar: "ScrollBar",
    KnownColor.Window: "Window",
    KnownColor.WindowFrame: "WindowFrame",
    KnownColor.WindowText: "WindowText",
    KnownColor.Transparent: "Transparent",
    KnownColor.AliceBlue: "AliceBlue",
    KnownColor.AntiqueWhite: "AntiqueWhite",
    KnownColor.Aqua: "Aqua",
    KnownColor.Aquamarine: "Aquamarine",
    KnownColor.Azure: "Azure",
    KnownColor.Beige: "Beige",
    KnownColor.Bisque: "Bisque",
    KnownColor.Black: "Black",
    KnownColor.BlanchedAlmond: "BlanchedAlmond",
    KnownColor.Blue: "Blue",
    KnownColor.BlueViolet: "BlueViolet",
    KnownColor.Brown: "Brown",
    KnownColor.BurlyWood: "BurlyWood",
    KnownColor.CadetBlue: "CadetBlue",
    KnownColor.Chartreuse: "Chartreuse",
    KnownColor.Chocolate: "Chocolate",
    KnownColor.Coral: "Coral",
    KnownColor.CornflowerBlue: "CornflowerBlue",
    KnownColor.Cornsilk: "Cornsilk",
    KnownColor.Crimson: "Crimson",
    KnownColor.Cyan: "Cyan",
    KnownColor.DarkBlue: "DarkBlue",
    KnownColor.DarkCyan: "DarkCyan",
    KnownColor.DarkGoldenrod: "DarkGoldenrod",
    KnownColor.DarkGray: "DarkGray",
    KnownColor.DarkGreen: "DarkGreen",
    KnownColor.DarkKhaki: "DarkKhaki",
    KnownColor.DarkMagenta: "DarkMagenta",
    KnownColor.DarkOliveGreen: "DarkOliveGreen",
    KnownColor.DarkOrange: "DarkOrange",
    KnownColor.DarkOrchid: "DarkOrchid",
    KnownColor.DarkRed: "DarkRed",
    KnownColor.DarkSalmon: "DarkSalmon",
    KnownColor.DarkSeaGreen: "DarkSeaGreen",
    KnownColor.DarkSlateBlue: "DarkSlateBlue",
    KnownColor.DarkSlateGray: "DarkSlateGray",
    KnownColor.DarkTurquoise: "DarkTurquoise",
    KnownColor.DarkViolet: "DarkViolet",
    KnownColor.DeepPink: "DeepPink",
    KnownColor.DeepSkyBlue: "DeepSkyBlue",
    KnownColor.DimGray: "DimGray",
    KnownColor.DodgerBlue: "DodgerBlue",
    KnownColor.Firebrick: "Firebrick",
    KnownColor.FloralWhite: "FloralWhite",
    KnownColor.ForestGreen: "ForestGreen",
    KnownColor.Fuchsia: "Fuchsia",
    KnownColor.Gainsboro: "Gainsboro",
    KnownColor.GhostWhite: "GhostWhite",
    KnownColor.Gold: "Gold",
    KnownColor.Goldenrod: "Goldenrod",
    KnownColor.Gray: "Gray",
    KnownColor.Green: "Green",
    KnownColor.GreenYellow: "GreenYellow",
    KnownColor.Honeydew: "Honeydew",
    KnownColor.HotPink: "HotPink",
    KnownColor.IndianRed: "IndianRed",
    KnownColor.Indigo: "Indigo",
    KnownColor.Ivory: "Ivory",
    KnownColor.Khaki: "Khaki",
    KnownColor.Lavender: "Lavender",
    KnownColor.LavenderBlush: "LavenderBlush",
    KnownColor.LawnGreen: "LawnGreen",
    KnownColor.LemonChiffon: "LemonChiffon",
    KnownColor.LightBlue: "LightBlue",
    KnownColor.LightCoral: "LightCoral",
    KnownColor.LightCyan: "LightCyan",
    KnownColor.LightGoldenrodYellow: "LightGoldenrodYellow",
    KnownColor.LightGray: "LightGray",
    KnownColor.LightGreen: "LightGreen",
    KnownColor.LightPink: "LightPink",
    KnownColor.LightSalmon: "LightSalmon",
    KnownColor.LightSeaGreen: "LightSeaGreen",
    KnownColor.LightSkyBlue: "LightSkyBlue",
    KnownColor.LightSlateGray: "LightSlateGray",
    KnownColor.LightSteelBlue: "LightSteelBlue",
    KnownColor.LightYellow: "LightYellow",
    KnownColor.Lime: "Lime",
    KnownColor.LimeGreen: "LimeGreen",
    KnownColor.Linen: "Linen",
    KnownColor.Magenta: "Magenta",
    KnownColor.Maroon: "Maroon",
    KnownColor.MediumAquamarine: "MediumAquamarine",
    KnownColor.MediumBlue: "MediumBlue",
    KnownColor.MediumOrchid: "MediumOrchid",
    KnownColor.MediumPurple: "MediumPurple",
    KnownColor.MediumSeaGreen: "MediumSeaGreen",
    KnownColor.MediumSlateBlue: "MediumSlateBlue",
    KnownColor.MediumSpringGreen: "MediumSpringGreen",
    KnownColor.MediumTurquoise: "MediumTurquoise",
    KnownColor.MediumVioletRed: "MediumVioletRed",
    KnownColor.MidnightBlue: "MidnightBlue",
    KnownColor.MintCream: "MintCream",
    KnownColor.MistyRose: "MistyRose",
    KnownColor.Moccasin: "Moccasin",
    KnownColor.NavajoWhite: "NavajoWhite",
    KnownColor.Navy: "Navy",
    KnownColor.OldLace: "OldLace",
    KnownColor.Olive: "Olive",
    KnownColor.OliveDrab: "OliveDrab",
    KnownColor.Orange: "Orange",
    KnownColor.OrangeRed: "OrangeRed",
    KnownColor.Orchid: "Orchid",
    KnownColor.PaleGoldenrod: "PaleGoldenrod",
    KnownColor.PaleGreen: "PaleGreen",
    KnownColor.PaleTurquoise: "PaleTurquoise",
    KnownColor.PaleVioletRed: "PaleVioletRed",
    KnownColor.PapayaWhip: "PapayaWhip",
    KnownColor.PeachPuff: "PeachPuff",
    KnownColor.Peru: "Peru",
    KnownColor.Pink: "Pink",
    KnownColor.Plum: "Plum",
    KnownColor.PowderBlue: "PowderBlue",
    KnownColor.Purple: "Purple",
    KnownColor.Red: "Red",
    KnownColor.RosyBrown: "RosyBrown",
    KnownColor.RoyalBlue: "RoyalBlue",
    KnownColor.SaddleBrown: "SaddleBrown",
    KnownColor.Salmon: "Salmon",
    KnownColor.SandyBrown: "SandyBrown",
    KnownColor.SeaGreen: "SeaGreen",
    KnownColor.SeaShell: "SeaShell",
    KnownColor.Sienna: "Sienna",
    KnownColor.Silver: "Silver",
    KnownColor.SkyBlue: "SkyBlue",
    KnownColor.SlateBlue: "SlateBlue",
    KnownColor.SlateGray: "SlateGray",
    KnownColor.Snow: "Snow",
    KnownColor.SpringGreen: "SpringGreen",
    KnownColor.SteelBlue: "SteelBlue",
    KnownColor.Tan: "Tan",
    KnownColor.Teal: "Teal",
    KnownColor.Thistle: "Thistle",
    KnownColor.Tomato: "Tomato",
    KnownColor.Turquoise: "Turquoise",
    KnownColor.Violet: "Violet",
    KnownColor.Wheat: "Wheat",
    KnownColor.White: "White",
    KnownColor.WhiteSmoke: "WhiteSmoke",
    KnownColor.Yellow: "Yellow",
    KnownColor.YellowGreen: "YellowGreen",
    KnownColor.ButtonFace: "ButtonFace",
    KnownColor.ButtonHighlight: "ButtonHighlight",
    KnownColor.ButtonShadow: "ButtonShadow",
    KnownColor.GradientActiveCaption: "GradientActiveCaption",
    KnownColor.GradientInactiveCaption: "GradientInactiveCaption",
    KnownColor.MenuBar: "MenuBar",
    KnownColor.MenuHighlight: "MenuHighlight"
  ];
}*/
  /*int count = KnownColorNames.values.length;
  int width = count * 110;

  scope bitmap = new Bitmap(width, 145);
  scope graphics = Graphics.fromImage(bitmap);
  graphics.clear(Color.white);

  Color[] colors = new Color[count];
  for (int i = 0; i < count; i++) {
    colors[i] = Color.fromName(KnownColorNames.values[i]);
  }
  colors.sort;

  scope font = new Font(FontFamily.genericSansSerif, 9);

  RectF rect = RectF(0, 0, 110, 110);
  for (int i = 0; i < colors.length; i++) {
    scope brush = new SolidBrush(colors[i]);
    graphics.fillRectangle(brush, rect);

    scope format = new StringFormat(StringFormatFlags.NoWrap);
    format.trimming = StringTrimming.EllipsisCharacter;

    graphics.drawString(colors[i].name, font, Brush.black, RectF(rect.x, rect.y + 115, 110, 110), format);
    rect.x += 110;
  }

  bitmap.save("palette.png");

  auto ms = new MemoryStream(std.base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAACdRJREFUWEe1VwlQk9cWzpu32NbXxVZcEEEtIPtmoCLSKpbiSq0WlCcispW1gBTQKFUREQiLiCioLLJTQAIiAQHZFQTCHogEEpaE/YGoCCp8vTCD1Wdrta/NzJ0/M/893/nO+c655/5/o/yFv41asiYrls6TGRkda1GSXpzoeeHOs7/Q3S/QEss/mhcW7Nj7aISFkYEa5GSGYPcWpccGW6QN34qA+KKFGz75eIGxkuzyVW9jGBbk3AfwMf2Uh8nHbADDeDRajaDTJlBXEr36WiyRTxYuWEeVSgzwtsPt4kiU5IXDzuwraKsuyXwTEq4OeokAFxMP2zA6xMKDYRaG+0ox+aiFEGnDuTMHICe17PtfxRJdIrLpfIA98PQe2dxBlpCsIbLGEHfFHRrKi+peR0JLUWYVuy6J7O/Gg/9WY+pRJR4O38ZQbxH6ewoxNlyF7rY06OtIj7yCIyIi8ml6gjcxHsf0Mx7GRmrxcLSJpI6FJ5MzZHpx5pghpFcuM/4tEib7Np+fiR5gkVWJm4VpyMnwxx3mcbQ1pqFfUIaJ+3dx1GkHVkuuUHoJx8pUr3rGydPH7Xgw2oyHI3eBSULgfjXGxxqAaR7qKiJJFpaV/xaBvNTjJF3NuFGcD3XnRlDWZmHHD5dRkmIHRrQ9Gu9GYmyoFBf87CC5SnTfcxz51aKKFbfCCGsuhgeKiH7N5D8b6dlZcPFwx3B3Nh4/asJofwm2b5If/zUChzasfO+nzHDo0btA0ajGgm1x2OVAx54QDrIKMlDGcERyuAVaq8IRHuQARbnljs9xdm2WdR0QFODJRBOmx++QaCuRWlKBpTYFyGPQUU4i4HEyME0ycnDvBoiJiYv8Lwl9O5cTFIt+UDan43iAH6YGGXg2kAJ9WgoMzjWjJMcPKaFGuBHngBAfC2xaJ+X8HMPoG43EqSccEnUz7gvzYB5Zjb878bDEhgmDqBbcvnECVdluGOzKxCG7XVgqKib5IgFbK0NNyn4hdBwuo6MuEtPDieCxr0LQFIygMF9IONXj6IV4VDMPIzXcDGeO7IKWupTZcwwbU51coBNdHTch5dkOygEBzE+EIC0lEBTLFsh4sVFX4I2W0tNwsdkBUVEx1RcJiBgVda4wuIzx9mD0tyeipvgcassvglUShK76UFBtk7H5aA6EzdGoyPGEi5UuqCqSXzzHcLfRvYWpcqzzv0ecV+OU30lgJI20400YHw0A5T9C6Howcb/ZFy7WekSCFcpzxtsNFTTfdQO279/b3FZ2HKU53qgo8AerLAx1t0Mx0h4OV58giBtEY5CfgJ7WeOzerAq9jQq/yBjgplNwLKkclK+zkEEKCShGXycTQi4DT/vSIG90FpStQvhHp4D+gw5WrVguNUdA97vD9HcOAwct97RWZDijMMsTtcRxU1UYOA3R6GqJgOBeIhR30tDeFAVWeRyUVi+peKmGzPZ8liJuHIHbt6OJ87vo5qagpTYWLTUxeNh/Hd3NVzDPMBn/dBzBZl0qNqqLz58DWG/lmz3PHbC2NnpWmmKD2rJQ3KuLAJeku7M1Ae3seEwNJ+MHH18w82Jxyn0fZKVFd79EYI3WetpOD5JylGBAwASrNJCk7zxa60gEbdeAiZvIzyVSbMnFv7ZmgO6o8v4cgLaNT9471hwE0nSnK5hH0N4cgx5uKnEeDQEvHZ33kjE1kokTFy/B/sez0NUU73uljT/T1jaWcijCs5F09PFSUcL0RGNVxCxYJycGQn4q8CQLWYxQIkU1Nln4xMyBaBz0TZWwLURu+M5pVok/eC2XiE0kOtuiZlPPb40iASTjTGQcVDS1oaUmbvkKAaqqnOb7FlWonzkuieEMgYY7/gQoHgJ+CjlCmZgYK0VndRjmKRvi39aVmANRN/e6uNi+C4nB+mgo90QvLwmCjlj0kpYVkI54MhiFzIKrkNzhBRWZj/t/9RT9kir2wQem+XCLLcB4x1mU53qDQ9pHyE9DHz99Vpbx4WsoSPeCFlW85j3zfPi5rputYn1TO9o8xzGE0o3QywlFT0cMIZECPicCj4XBSGUEY+neXCyQoEJvnYTpbw4z6n5P/p7UKdSQImKX+YDbdBlCEk1PeywhcB1PxwuRdskWaprUqvnmVQhwXTtL4Fsjo0rKN/VgZhzDMC8MHewLszJMDCag9m4wJA/m4cM1NtBS/LDxdZOUoqBGPbv6IvCVdxHY+U7gtUZgsCcDPUQSISGB8Sxci7AG5asofHTwzqwEvoc0TRjx9thm7oi+9kvouneFOA8Hnx2AoY5QbKLlQ84kCSqyS2BvrPbS4fUKGTXphZKyJsFY4AmEBNqhr+UcmeNZGOhOw0APg1wJ4mDkxwDFEZDd5lo0AxBx1gjsiiPkhPMBrzEU3IbzpPqv4IEwAg4eNKz6Nhg/ulti6+cSCa+Nfu7l9+YbhAvdBrCdFodh9hmiZTRpqWiMdp9HVaU/KMZ8vKt7EQ57pZfRaXrZ3IZAVBedRHGWM3l6obqYBnY1HZwaT5TnOYHfFAnDrerYuUV56RsRoFmujbfw9IW6uS8me8PRy4+BgBuFid5A7DrkhXe+8IH+hpVN3++VXV2WdwrtDSHIT3dAdpI1csnEvEVGbkX+cdy95YwxQTgSIk9DXkrk4hs5n9mkoSpjyq05iU52IAScAPBbQoim5zDYSe6GBX7oZdNxYLdGt5G+8rGOpkAycI4jM2YfGFfNcC3KGOnRxshNtUVNkQuRjontX6pDRUn6ozcmoPe5vFxVsTf6eUEklX5oqw9ER9MFcBvPQ9AWgiF+COzNtkwabFG60cqio7HcDfnX7HEjwQqMqP3IirckWbAnAyeY3CG9oSAtEvLGzmc2WhiQq+9PR0hB+aKq6BRJ5UncyaOhNNsJFXmHSWbo8KIZ4OuNK1NDfK3IoeWL+lIXFGXZEyK2KMx0ItE7kwAY+FpPA6rKbxH9LAFDtfmxpNc5NT8Sbe2R85Mt0dYBzITvUHDNgRDzx6VzDtBZ96mptrrkWQ9XE3S2xGC4k/R//UkiWyAmR4vg5eEAZZnFAW8V/dxmT/ftA1zWERRmHELG1QNIj9xHniZgJpqivd4L15NOQGzZUrfZmlESP6azXgUe7taIveKJmEveMNmzDVSFhXV/yPmM0f5vv4jj1HqiMt8VOcmWyIzdTzJhRWSwweOhVNBPO+NTiUXucw5MjBTm62qvcFSSWZwsJ7kohaosbv6Hnc8YfqOnuCb6gjO6Gg8TPR3BKjpEUh+ARwPZuJ4WhTVyIqCqKSz7v5z8nvGGtfLhkaFuaK2NI98CiWAkhcDGbDdxvgA662V3/p79n/JeXma50xrFlWxVOTGhvOQnZZ+pLHelqin9408BfwHkZ3imvBk7RbY9AAAAAElFTkSuQmCC"));
  scope img = new Bitmap(ms);
  img.save("testimage.png");*/
}