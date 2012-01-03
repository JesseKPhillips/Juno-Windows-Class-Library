/**
 * Provides access to basic GDI+ graphics functionality.
 *
 * For detailed information, refer to MSDN's documentation for the $(LINK2 http://msdn2.microsoft.com/en-us/library/system.drawing.aspx, System.Drawing) namespace.
 *
 * Copyright: (c) 2009 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.media.core;

import juno.base.core,
  juno.base.string,
  juno.base.threading,
  juno.base.native,
  juno.io.core,
  juno.io.path,
  juno.com.core,
  juno.media.constants,
  juno.media.geometry,
  juno.media.imaging,
  juno.media.native,
  std.string,
  std.stream;

import std.algorithm : min, max;
import std.ascii;
static import std.file,
  std.math,
  std.conv;

version(D_Version2) {
  debug import std.stdio : writeln;
}

private int stringToInt(string value, int fromBase) {
  int sign = 1;
  int i;
  int len = value.length;

  if (value[0] == '-') {
    sign = -1;
    i++;
  }
  else if (value[0] == '+') {
    i++;
  }

  if (fromBase == 16) {
    if (len >= i + 2
      && (value[i .. i + 2] == "0x" || value[i .. i + 2] == "0X"))
      i += 2;
  }

  int result;
  int n;

  while (i < len) {
    char c = value[i++];
    if (isDigit(c))
      n = c - '0';
    else if (isAlpha(c))
      n = toLower(c) - 'a' + 10;

    result = fromBase * result + n;
  }

  if (fromBase == 10)
    result *= sign;

  return result;
}

/**
 * Represents an ARGB color.
 */
struct Color {

  @property
  {
    /// Gets a system-defined color.
    static Color activeBorder() {
      return Color(KnownColor.ActiveBorder);
    }
    
    /// ditto 
    static Color activeCaption() {
      return Color(KnownColor.ActiveCaption);
    }
    
    /// ditto 
    static Color activeCaptionText() {
      return Color(KnownColor.ActiveCaptionText);
    }
    
    /// ditto 
    static Color appWorkspace() {
      return Color(KnownColor.AppWorkspace);
    }
    
    /// ditto 
    static Color control() {
      return Color(KnownColor.Control);
    }
    
    /// ditto 
    static Color controlDark() {
      return Color(KnownColor.ControlDark);
    }
    
    /// ditto 
    static Color controlDarkDark() {
      return Color(KnownColor.ControlDarkDark);
    }
    
    /// ditto 
    static Color controlLight() {
      return Color(KnownColor.ControlLight);
    }
    
    /// ditto 
    static Color controlLightLight() {
      return Color(KnownColor.ControlLightLight);
    }
    
    /// ditto 
    static Color controlText() {
      return Color(KnownColor.ControlText);
    }
    
    /// ditto 
    static Color desktop() {
      return Color(KnownColor.Desktop);
    }
    
    /// ditto 
    static Color grayText() {
      return Color(KnownColor.GrayText);
    }
    
    /// ditto 
    static Color highlight() {
      return Color(KnownColor.Highlight);
    }
    
    /// ditto 
    static Color highlightText() {
      return Color(KnownColor.HighlightText);
    }
    
    /// ditto 
    static Color hotTrack() {
      return Color(KnownColor.HotTrack);
    }
    
    /// ditto 
    static Color inactiveBorder() {
      return Color(KnownColor.InactiveBorder);
    }
    
    /// ditto 
    static Color inactiveCaption() {
      return Color(KnownColor.InactiveCaption);
    }
    
    /// ditto 
    static Color inactiveCaptionText() {
      return Color(KnownColor.InactiveCaptionText);
    }
    
    /// ditto 
    static Color info() {
      return Color(KnownColor.Info);
    }
    
    /// ditto 
    static Color infoText() {
      return Color(KnownColor.InfoText);
    }
    
    /// ditto 
    static Color menu() {
      return Color(KnownColor.Menu);
    }
    
    /// ditto 
    static Color menuText() {
      return Color(KnownColor.MenuText);
    }
    
    /// ditto 
    static Color scrollBar() {
      return Color(KnownColor.ScrollBar);
    }
    
    /// ditto 
    static Color window() {
      return Color(KnownColor.Window);
    }
    
    /// ditto 
    static Color windowFrame() {
      return Color(KnownColor.WindowFrame);
    }
    
    /// ditto 
    static Color windowText() {
      return Color(KnownColor.WindowText);
    }
    
    /// ditto 
    static Color transparent() {
      return Color(KnownColor.Transparent);
    }
    
    /// ditto 
    static Color aliceBlue() {
      return Color(KnownColor.AliceBlue);
    }
    
    /// ditto 
    static Color antiqueWhite() {
      return Color(KnownColor.AntiqueWhite);
    }
    
    /// ditto 
    static Color aqua() {
      return Color(KnownColor.Aqua);
    }
    
    /// ditto 
    static Color aquamarine() {
      return Color(KnownColor.Aquamarine);
    }
    
    /// ditto 
    static Color azure() {
      return Color(KnownColor.Azure);
    }
    
    /// ditto 
    static Color beige() {
      return Color(KnownColor.Beige);
    }
    
    /// ditto 
    static Color bisque() {
      return Color(KnownColor.Bisque);
    }
    
    /// ditto 
    static Color black() {
      return Color(KnownColor.Black);
    }
    
    /// ditto 
    static Color blanchedAlmond() {
      return Color(KnownColor.BlanchedAlmond);
    }
    
    /// ditto 
    static Color blue() {
      return Color(KnownColor.Blue);
    }
    
    /// ditto 
    static Color blueViolet() {
      return Color(KnownColor.BlueViolet);
    }
    
    /// ditto 
    static Color brown() {
      return Color(KnownColor.Brown);
    }
    
    /// ditto 
    static Color burlyWood() {
      return Color(KnownColor.BurlyWood);
    }
    
    /// ditto 
    static Color cadetBlue() {
      return Color(KnownColor.CadetBlue);
    }
    
    /// ditto 
    static Color chartreuse() {
      return Color(KnownColor.Chartreuse);
    }
    
    /// ditto 
    static Color chocolate() {
      return Color(KnownColor.Chocolate);
    }
    
    /// ditto 
    static Color coral() {
      return Color(KnownColor.Coral);
    }
    
    /// ditto 
    static Color cornflowerBlue() {
      return Color(KnownColor.CornflowerBlue);
    }
    
    /// ditto 
    static Color cornsilk() {
      return Color(KnownColor.Cornsilk);
    }
    
    /// ditto 
    static Color crimson() {
      return Color(KnownColor.Crimson);
    }
    
    /// ditto 
    static Color cyan() {
      return Color(KnownColor.Cyan);
    }
    
    /// ditto 
    static Color darkBlue() {
      return Color(KnownColor.DarkBlue);
    }
    
    /// ditto 
    static Color darkCyan() {
      return Color(KnownColor.DarkCyan);
    }
    
    /// ditto 
    static Color darkGoldenrod() {
      return Color(KnownColor.DarkGoldenrod);
    }
    
    /// ditto 
    static Color darkGray() {
      return Color(KnownColor.DarkGray);
    }
    
    /// ditto 
    static Color darkGreen() {
      return Color(KnownColor.DarkGreen);
    }
    
    /// ditto 
    static Color darkKhaki() {
      return Color(KnownColor.DarkKhaki);
    }
    
    /// ditto 
    static Color darkMagenta() {
      return Color(KnownColor.DarkMagenta);
    }
    
    /// ditto 
    static Color darkOliveGreen() {
      return Color(KnownColor.DarkOliveGreen);
    }
    
    /// ditto 
    static Color darkOrange() {
      return Color(KnownColor.DarkOrange);
    }
    
    /// ditto 
    static Color darkOrchid() {
      return Color(KnownColor.DarkOrchid);
    }
    
    /// ditto 
    static Color darkRed() {
      return Color(KnownColor.DarkRed);
    }
    
    /// ditto 
    static Color darkSalmon() {
      return Color(KnownColor.DarkSalmon);
    }
    
    /// ditto 
    static Color darkSeaGreen() {
      return Color(KnownColor.DarkSeaGreen);
    }
    
    /// ditto 
    static Color darkSlateBlue() {
      return Color(KnownColor.DarkSlateBlue);
    }
    
    /// ditto 
    static Color darkSlateGray() {
      return Color(KnownColor.DarkSlateGray);
    }
    
    /// ditto 
    static Color darkTurquoise() {
      return Color(KnownColor.DarkTurquoise);
    }
    
    /// ditto 
    static Color darkViolet() {
      return Color(KnownColor.DarkViolet);
    }
    
    /// ditto 
    static Color deepPink() {
      return Color(KnownColor.DeepPink);
    }
    
    /// ditto 
    static Color deepSkyBlue() {
      return Color(KnownColor.DeepSkyBlue);
    }
    
    /// ditto 
    static Color dimGray() {
      return Color(KnownColor.DimGray);
    }
    
    /// ditto 
    static Color dodgerBlue() {
      return Color(KnownColor.DodgerBlue);
    }
    
    /// ditto 
    static Color firebrick() {
      return Color(KnownColor.Firebrick);
    }
    
    /// ditto 
    static Color floralWhite() {
      return Color(KnownColor.FloralWhite);
    }
    
    /// ditto 
    static Color forestGreen() {
      return Color(KnownColor.ForestGreen);
    }
    
    /// ditto 
    static Color fuchsia() {
      return Color(KnownColor.Fuchsia);
    }
    
    /// ditto 
    static Color gainsboro() {
      return Color(KnownColor.Gainsboro);
    }
    
    /// ditto 
    static Color ghostWhite() {
      return Color(KnownColor.GhostWhite);
    }
    
    /// ditto 
    static Color gold() {
      return Color(KnownColor.Gold);
    }
    
    /// ditto 
    static Color goldenrod() {
      return Color(KnownColor.Goldenrod);
    }
    
    /// ditto 
    static Color gray() {
      return Color(KnownColor.Gray);
    }
    
    /// ditto 
    static Color green() {
      return Color(KnownColor.Green);
    }
    
    /// ditto 
    static Color greenYellow() {
      return Color(KnownColor.GreenYellow);
    }
    
    /// ditto 
    static Color honeydew() {
      return Color(KnownColor.Honeydew);
    }
    
    /// ditto 
    static Color hotPink() {
      return Color(KnownColor.HotPink);
    }
    
    /// ditto 
    static Color indianRed() {
      return Color(KnownColor.IndianRed);
    }
    
    /// ditto 
    static Color indigo() {
      return Color(KnownColor.Indigo);
    }
    
    /// ditto 
    static Color ivory() {
      return Color(KnownColor.Ivory);
    }
    
    /// ditto 
    static Color khaki() {
      return Color(KnownColor.Khaki);
    }
    
    /// ditto 
    static Color lavender() {
      return Color(KnownColor.Lavender);
    }
    
    /// ditto 
    static Color lavenderBlush() {
      return Color(KnownColor.LavenderBlush);
    }
    
    /// ditto 
    static Color lawnGreen() {
      return Color(KnownColor.LawnGreen);
    }
    
    /// ditto 
    static Color lemonChiffon() {
      return Color(KnownColor.LemonChiffon);
    }
    
    /// ditto 
    static Color lightBlue() {
      return Color(KnownColor.LightBlue);
    }
    
    /// ditto 
    static Color lightCoral() {
      return Color(KnownColor.LightCoral);
    }
    
    /// ditto 
    static Color lightCyan() {
      return Color(KnownColor.LightCyan);
    }
    
    /// ditto 
    static Color lightGoldenrodYellow() {
      return Color(KnownColor.LightGoldenrodYellow);
    }
    
    /// ditto 
    static Color lightGray() {
      return Color(KnownColor.LightGray);
    }
    
    /// ditto 
    static Color lightGreen() {
      return Color(KnownColor.LightGreen);
    }
    
    /// ditto 
    static Color lightPink() {
      return Color(KnownColor.LightPink);
    }
    
    /// ditto 
    static Color lightSalmon() {
      return Color(KnownColor.LightSalmon);
    }
    
    /// ditto 
    static Color lightSeaGreen() {
      return Color(KnownColor.LightSeaGreen);
    }
    
    /// ditto 
    static Color lightSkyBlue() {
      return Color(KnownColor.LightSkyBlue);
    }
    
    /// ditto 
    static Color lightSlateGray() {
      return Color(KnownColor.LightSlateGray);
    }
    
    /// ditto 
    static Color lightSteelBlue() {
      return Color(KnownColor.LightSteelBlue);
    }
    
    /// ditto 
    static Color lightYellow() {
      return Color(KnownColor.LightYellow);
    }
    
    /// ditto 
    static Color lime() {
      return Color(KnownColor.Lime);
    }
    
    /// ditto 
    static Color limeGreen() {
      return Color(KnownColor.LimeGreen);
    }
    
    /// ditto 
    static Color linen() {
      return Color(KnownColor.Linen);
    }
    
    /// ditto 
    static Color magenta() {
      return Color(KnownColor.Magenta);
    }
    
    /// ditto 
    static Color maroon() {
      return Color(KnownColor.Maroon);
    }
    
    /// ditto 
    static Color mediumAquamarine() {
      return Color(KnownColor.MediumAquamarine);
    }
    
    /// ditto 
    static Color mediumBlue() {
      return Color(KnownColor.MediumBlue);
    }
    
    /// ditto 
    static Color mediumOrchid() {
      return Color(KnownColor.MediumOrchid);
    }
    
    /// ditto 
    static Color mediumPurple() {
      return Color(KnownColor.MediumPurple);
    }
    
    /// ditto 
    static Color mediumSeaGreen() {
      return Color(KnownColor.MediumSeaGreen);
    }
    
    /// ditto 
    static Color mediumSlateBlue() {
      return Color(KnownColor.MediumSlateBlue);
    }
    
    /// ditto 
    static Color mediumSpringGreen() {
      return Color(KnownColor.MediumSpringGreen);
    }
    
    /// ditto 
    static Color mediumTurquoise() {
      return Color(KnownColor.MediumTurquoise);
    }
    
    /// ditto 
    static Color mediumVioletRed() {
      return Color(KnownColor.MediumVioletRed);
    }
    
    /// ditto 
    static Color midnightBlue() {
      return Color(KnownColor.MidnightBlue);
    }
    
    /// ditto 
    static Color mintCream() {
      return Color(KnownColor.MintCream);
    }
    
    /// ditto 
    static Color mistyRose() {
      return Color(KnownColor.MistyRose);
    }
    
    /// ditto 
    static Color moccasin() {
      return Color(KnownColor.Moccasin);
    }
    
    /// ditto 
    static Color navajoWhite() {
      return Color(KnownColor.NavajoWhite);
    }
    
    /// ditto 
    static Color navy() {
      return Color(KnownColor.Navy);
    }
    
    /// ditto 
    static Color oldLace() {
      return Color(KnownColor.OldLace);
    }
    
    /// ditto 
    static Color olive() {
      return Color(KnownColor.Olive);
    }
    
    /// ditto 
    static Color oliveDrab() {
      return Color(KnownColor.OliveDrab);
    }
    
    /// ditto 
    static Color orange() {
      return Color(KnownColor.Orange);
    }
    
    /// ditto 
    static Color orangeRed() {
      return Color(KnownColor.OrangeRed);
    }
    
    /// ditto 
    static Color orchid() {
      return Color(KnownColor.Orchid);
    }
    
    /// ditto 
    static Color paleGoldenrod() {
      return Color(KnownColor.PaleGoldenrod);
    }
    
    /// ditto 
    static Color paleGreen() {
      return Color(KnownColor.PaleGreen);
    }
    
    /// ditto 
    static Color paleTurquoise() {
      return Color(KnownColor.PaleTurquoise);
    }
    
    /// ditto 
    static Color paleVioletRed() {
      return Color(KnownColor.PaleVioletRed);
    }
    
    /// ditto 
    static Color papayaWhip() {
      return Color(KnownColor.PapayaWhip);
    }
    
    /// ditto 
    static Color peachPuff() {
      return Color(KnownColor.PeachPuff);
    }
    
    /// ditto 
    static Color peru() {
      return Color(KnownColor.Peru);
    }
    
    /// ditto 
    static Color pink() {
      return Color(KnownColor.Pink);
    }
    
    /// ditto 
    static Color plum() {
      return Color(KnownColor.Plum);
    }
    
    /// ditto 
    static Color powderBlue() {
      return Color(KnownColor.PowderBlue);
    }
    
    /// ditto 
    static Color purple() {
      return Color(KnownColor.Purple);
    }
    
    /// ditto 
    static Color red() {
      return Color(KnownColor.Red);
    }
    
    /// ditto 
    static Color rosyBrown() {
      return Color(KnownColor.RosyBrown);
    }
    
    /// ditto 
    static Color royalBlue() {
      return Color(KnownColor.RoyalBlue);
    }
    
    /// ditto 
    static Color saddleBrown() {
      return Color(KnownColor.SaddleBrown);
    }
    
    /// ditto 
    static Color salmon() {
      return Color(KnownColor.Salmon);
    }
    
    /// ditto 
    static Color sandyBrown() {
      return Color(KnownColor.SandyBrown);
    }
    
    /// ditto 
    static Color seaGreen() {
      return Color(KnownColor.SeaGreen);
    }
    
    /// ditto 
    static Color seaShell() {
      return Color(KnownColor.SeaShell);
    }
    
    /// ditto 
    static Color sienna() {
      return Color(KnownColor.Sienna);
    }
    
    /// ditto 
    static Color silver() {
      return Color(KnownColor.Silver);
    }
    
    /// ditto 
    static Color skyBlue() {
      return Color(KnownColor.SkyBlue);
    }
    
    /// ditto 
    static Color slateBlue() {
      return Color(KnownColor.SlateBlue);
    }
    
    /// ditto 
    static Color slateGray() {
      return Color(KnownColor.SlateGray);
    }
    
    /// ditto 
    static Color snow() {
      return Color(KnownColor.Snow);
    }
    
    /// ditto 
    static Color springGreen() {
      return Color(KnownColor.SpringGreen);
    }
    
    /// ditto 
    static Color steelBlue() {
      return Color(KnownColor.SteelBlue);
    }
    
    /// ditto 
    static Color tan() {
      return Color(KnownColor.Tan);
    }
    
    /// ditto 
    static Color teal() {
      return Color(KnownColor.Teal);
    }
    
    /// ditto 
    static Color thistle() {
      return Color(KnownColor.Thistle);
    }
    
    /// ditto 
    static Color tomato() {
      return Color(KnownColor.Tomato);
    }
    
    /// ditto 
    static Color turquoise() {
      return Color(KnownColor.Turquoise);
    }
    
    /// ditto 
    static Color violet() {
      return Color(KnownColor.Violet);
    }
    
    /// ditto 
    static Color wheat() {
      return Color(KnownColor.Wheat);
    }
    
    /// ditto 
    static Color white() {
      return Color(KnownColor.White);
    }
    
    /// ditto 
    static Color whiteSmoke() {
      return Color(KnownColor.WhiteSmoke);
    }
    
    /// ditto 
    static Color yellow() {
      return Color(KnownColor.Yellow);
    }
    
    /// ditto 
    static Color yellowGreen() {
      return Color(KnownColor.YellowGreen);
    }
    
    /// ditto 
    static Color buttonFace() {
      return Color(KnownColor.ButtonFace);
    }
    
    /// ditto 
    static Color buttonHighlight() {
      return Color(KnownColor.ButtonHighlight);
    }
    
    /// ditto 
    static Color buttonShadow() {
      return Color(KnownColor.ButtonShadow);
    }
    
    /// ditto 
    static Color gradientActiveCaption() {
      return Color(KnownColor.GradientActiveCaption);
    }
    
    /// ditto 
    static Color gradientInactiveCaption() {
      return Color(KnownColor.GradientInactiveCaption);
    }
    
    /// ditto 
    static Color menuBar() {
      return Color(KnownColor.MenuBar);
    }
    
    /// ditto 
    static Color menuHighlight() {
      return Color(KnownColor.MenuHighlight);
    }
  } //@property

  private enum : ubyte {
    ARGB_ALPHA_SHIFT = 24,
    ARGB_RED_SHIFT = 16,
    ARGB_GREEN_SHIFT = 8,
    ARGB_BLUE_SHIFT = 0
  }

  private enum : uint {
    RGB_RED_SHIFT = 0,
    RGB_GREEN_SHIFT = 8,
    RGB_BLUE_SHIFT = 16
  }

  private enum : ushort {
    STATE_KNOWNCOLOR_VALID = 0x01,
    STATE_VALUE_VALID = 0x02,
    STATE_NAME_VALID = 0x04
  }

  private static ulong UNDEFINED_VALUE = 0;

  private static uint[] colorTable_;
  private static string[] nameTable_;
  private static Color[string] htmlTable_;

  private ulong value_;
  private ushort state_;
  private string name_;
  private ushort knownColor_;

  /**
   * Represents an uninitialized color.
   */
  static Color empty = { 0, 0, null, 0 };

  /**
   * Creates a Color structure from the ARGB component values.
   */
  static Color fromArgb(uint argb) {
    return Color(cast(ulong)argb & 0xffffffff, STATE_VALUE_VALID, null, cast(KnownColor)0);
  }

  /**
   * ditto
   */
  static Color fromArgb(ubyte alpha, ubyte red, ubyte green, ubyte blue) {
    return Color(makeArgb(alpha, red, green, blue), STATE_VALUE_VALID, null, cast(KnownColor)0);
  }

  /**
   * ditto
   */
  static Color fromArgb(ubyte red, ubyte green, ubyte blue) {
    return fromArgb(255, red, green, blue);
  }

  /**
   * ditto
   */
  static Color fromArgb(ubyte alpha, Color baseColor) {
    return Color(makeArgb(alpha, baseColor.r, baseColor.g, baseColor.b), STATE_VALUE_VALID, null, cast(KnownColor)0);
  }

  /**
   * Creates a GDI+ color structure from a Windows color _value.
   */
  static Color fromRgb(uint value) {

    Color knownColorFromArgb(uint argb) {
      if (colorTable_ == null)
        initColorTable();

      for (int i = 0; i < colorTable_.length; i++) {
        int c = colorTable_[i];
        if (c == argb) {
          Color color = Color(cast(KnownColor)i);
          if (!color.isSystemColor)
            return color;
        }
      }

      return fromArgb(argb);
    }

    Color c = fromArgb(cast(ubyte)((value >> RGB_RED_SHIFT) & 0xff), cast(ubyte)((value >> RGB_GREEN_SHIFT) & 0xff), cast(ubyte)((value >> RGB_BLUE_SHIFT) & 0xff));
    return knownColorFromArgb(c.toArgb());
  }

  static Color fromHtml(string value) {
    Color c = Color.empty;

    if (value == null)
      return c;

    if (value[0] == '#') {
      if (value.length == 4 || value.length == 7) {
        if (value.length == 7) {
          c = fromArgb(cast(ubyte)stringToInt(value[1 .. 3], 16), cast(ubyte)stringToInt(value[3 .. 5], 16), cast(ubyte)stringToInt(value[5 .. 7], 16));
        }
        else {
          version(D_Version2) {
            string r = std.conv.to!(string)(value[1]);
            string g = std.conv.to!(string)(value[2]);
            string b = std.conv.to!(string)(value[3]);
          }
          else {
            string r = .toString(value[1]);
            string g = .toString(value[2]);
            string b = .toString(value[3]);
          }
          c = Color.fromArgb(cast(ubyte)stringToInt(r ~ r, 16), cast(ubyte)stringToInt(g ~ g, 16), cast(ubyte)stringToInt(b ~ b, 16));
        }
      }
    }

    if (c.isEmpty && std.string.icmp("LightGrey", value) == 0)
      c = Color.lightGray;

    if (c.isEmpty) {
      if (htmlTable_ == null)
        initHtmlTable();

      if (auto v = value.tolower() in htmlTable_)
        c = *v;
    }

    if (c.isEmpty)
      c = fromName(value);

    return c;
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
      if (value.tolower() == name.tolower())
        return fromKnownColor(cast(KnownColor)key);
    }

    return Color(0, STATE_NAME_VALID, name, cast(KnownColor)0);
  }

  /**
   * Gets the alpha component.
   */
  @property ubyte a() {
    return cast(ubyte)((value >> ARGB_ALPHA_SHIFT) & 255);
  }

  /**
   * Gets the red component.
   */
  @property ubyte r() {
    return cast(ubyte)((value >> ARGB_RED_SHIFT) & 255);
  }

  /**
   * Gets the green component.
   */
  @property ubyte g() {
    return cast(ubyte)((value >> ARGB_GREEN_SHIFT) & 255);
  }

  /**
   * Gets the blue component.
   */
  @property ubyte b() {
    return cast(ubyte)((value >> ARGB_BLUE_SHIFT) & 255);
  }

  /**
   * Gets the KnownColor value.
   */
  KnownColor toKnownColor() {
    return cast(KnownColor)knownColor_;
  }

  /**
   * Gets the ARGB value.
   */
  uint toArgb() {
    return cast(uint)value;
  }

  /**
   * Converts the value to a Windows color value.
   */
  uint toRgb() {
    return r << RGB_RED_SHIFT | g << RGB_GREEN_SHIFT | b << RGB_BLUE_SHIFT;
  }

  /**
   * Determines whether this Color structure is uninitialized.
   */
  @property bool isEmpty() {
    return (state_ == 0);
  }

  /**
   * Determines whether this Color structure is predefined.
   */
  @property bool isKnownColor() {
    return (state_ & STATE_KNOWNCOLOR_VALID) != 0;
  }

  /**
   * Determines whether this Color structure is a system color.
   */
  @property bool isSystemColor() {
    return isKnownColor && (knownColor_ <= KnownColor.WindowText || knownColor_ >= KnownColor.ButtonFace);
  }

  @property bool isNamedColor() {
    return (isKnownColor || (state_ & STATE_NAME_VALID) != 0);
  }

  /**
   * Determines whether the specified instance _equals this instance.
   * Returns: true if other is equivalent to the instance; otherwise, false.
   * Remarks: To compare colors based solely on their ARGB values, use the toArgb method.
   */
  bool equals(Color other) {
    return value_ == other.value_ && state_ == other.state_ && knownColor_ == other.knownColor_ && name_ == other.name_;
  }

  /// ditto
  bool opEquals(Color other) {
    return this.equals(other);
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
  @property string name() {
    if ((state_ & STATE_NAME_VALID) != 0)
      return name_;

    if ((state_ & STATE_KNOWNCOLOR_VALID) == 0) {
      version(D_Version2) {
        return std.conv.to!(string)(value_, 16u);
      }
      else {
        return std.string.toString(value_, 16u);
      }
    }

    if (nameTable_ == null)
      initNameTable();
    return nameTable_[knownColor_];
  }

  /**
   * Converts this Color to a human-readable string.
   */
  string toString() {
    string s = "Color [";
    if ((state_ & STATE_KNOWNCOLOR_VALID) != 0)
      s ~= name;
    else if ((state_ & STATE_VALUE_VALID) != 0)
      s ~= std.string.format("A=%s, R=%s, G=%s, B=%s", a, r, g, b);
    else
      s ~= "Empty";
    s ~= "]";
    return s;
  }

  string toHtml() {
    if (isEmpty)
      return "";

    if (isSystemColor) {
      switch (toKnownColor()) {
        case KnownColor.ActiveBorder: return "activeborder";
        case KnownColor.ActiveCaption, KnownColor.GradientActiveCaption: return "activecaption";
        case KnownColor.AppWorkspace: return "appworkspace";
        case KnownColor.Desktop: return "background";
        case KnownColor.Control, KnownColor.ControlLight: return "buttonface";
        case KnownColor.ControlDark: return "buttonshadow";
        case KnownColor.ControlText: return "buttontext";
        case KnownColor.ActiveCaptionText: return "captiontext";
        case KnownColor.GrayText: return "graytext";
        case KnownColor.HotTrack, KnownColor.Highlight: return "highlight";
        case KnownColor.MenuHighlight, KnownColor.HighlightText: return "highlighttext";
        case KnownColor.InactiveBorder: return "inactiveborder";
        case KnownColor.InactiveCaption, KnownColor.GradientInactiveCaption: return "inactioncaption";
        case KnownColor.InactiveCaptionText: return "inactivecaptiontext";
        case KnownColor.Info: return "infobackground";
        case KnownColor.InfoText: return "infotext";
        case KnownColor.MenuBar, KnownColor.Menu: return "menu";
        case KnownColor.MenuText: return "menutext";
        case KnownColor.ScrollBar: return "scrollbar";
        case KnownColor.ControlDarkDark: return "threeddarkshadow";
        case KnownColor.ControlLightLight: return "buttonhighlight";
        case KnownColor.Window: return "window";
        case KnownColor.WindowFrame: return "windowframe";
        case KnownColor.WindowText: return "windowtext";
        default:
      }
    }
    else if (isNamedColor) {
      version(D_Version2) {
        if (this == Color.lightGray)
          return "LightGrey";
      }
      else {
        if (*this == Color.lightGray)
          return "LightGrey";
      }
      return name;
    }

    return "#" ~ std.string.format("%02X", r) ~ std.string.format("%02X", g) ~ std.string.format("%02X", b);
  }

  private static Color opCall(KnownColor knownColor) {
    Color self;
    self.state_ = STATE_KNOWNCOLOR_VALID;
    self.knownColor_ = cast(ushort)knownColor;
    return self;
  }

  private static Color opCall(ulong value, ushort state, string name, KnownColor knownColor) {
    Color self;
    self.value_ = value;
    self.state_ = state;
    self.knownColor_ = cast(ushort)knownColor;
    self.name_ = name;
    return self;
  }

  private static ulong makeArgb(ubyte alpha, ubyte red, ubyte green, ubyte blue) {
    return cast(ulong)(red << ARGB_RED_SHIFT | green << ARGB_GREEN_SHIFT | blue << ARGB_BLUE_SHIFT | alpha << ARGB_ALPHA_SHIFT) & 0xffffffff;
  }

  private @property ulong value() {
    if ((state_ & STATE_VALUE_VALID) != 0)
      return value_;
    if ((state_ & STATE_KNOWNCOLOR_VALID) != 0)
      return knownColorToArgb(cast(KnownColor)knownColor_);
    return UNDEFINED_VALUE;
  }

  private static ulong knownColorToArgb(KnownColor color) {
    if (colorTable_ == null)
      initColorTable();

    if (color <= KnownColor.MenuHighlight)
      return colorTable_[color];
    return 0;
  }

  private static uint systemColorToArgb(int index) {
    uint fromRgb(uint value) {
      uint encode(uint alpha, uint red, uint green, uint blue) {
        return red << ARGB_RED_SHIFT | green << ARGB_GREEN_SHIFT | blue << ARGB_BLUE_SHIFT | alpha << ARGB_ALPHA_SHIFT;
      }
      return encode(255, (value >> RGB_RED_SHIFT) & 255, (value >> RGB_GREEN_SHIFT) & 255, (value >> RGB_BLUE_SHIFT) & 255);
    }
    return fromRgb(GetSysColor(index));
  }

  private static void initColorTable() {
    colorTable_.length = KnownColor.max + 1;

    colorTable_[KnownColor.ActiveBorder] = systemColorToArgb(COLOR_ACTIVEBORDER); 
    colorTable_[KnownColor.ActiveCaption] = systemColorToArgb(COLOR_ACTIVECAPTION);
    colorTable_[KnownColor.ActiveCaptionText] = systemColorToArgb(COLOR_CAPTIONTEXT); 
    colorTable_[KnownColor.AppWorkspace] = systemColorToArgb(COLOR_APPWORKSPACE); 
    colorTable_[KnownColor.ButtonFace] = systemColorToArgb(COLOR_BTNFACE);
    colorTable_[KnownColor.ButtonHighlight] = systemColorToArgb(COLOR_BTNHIGHLIGHT); 
    colorTable_[KnownColor.ButtonShadow] = systemColorToArgb(COLOR_BTNSHADOW);
    colorTable_[KnownColor.Control] = systemColorToArgb(COLOR_BTNFACE);
    colorTable_[KnownColor.ControlDark] = systemColorToArgb(COLOR_BTNSHADOW);
    colorTable_[KnownColor.ControlDarkDark] = systemColorToArgb(COLOR_3DDKSHADOW); 
    colorTable_[KnownColor.ControlLight] = systemColorToArgb(COLOR_BTNHIGHLIGHT);
    colorTable_[KnownColor.ControlLightLight] = systemColorToArgb(COLOR_3DLIGHT); 
    colorTable_[KnownColor.ControlText] = systemColorToArgb(COLOR_BTNTEXT); 
    colorTable_[KnownColor.Desktop] = systemColorToArgb(COLOR_BACKGROUND);
    colorTable_[KnownColor.GradientActiveCaption] = systemColorToArgb(COLOR_GRADIENTACTIVECAPTION); 
    colorTable_[KnownColor.GradientInactiveCaption] = systemColorToArgb(COLOR_GRADIENTINACTIVECAPTION);
    colorTable_[KnownColor.GrayText] = systemColorToArgb(COLOR_GRAYTEXT);
    colorTable_[KnownColor.Highlight] = systemColorToArgb(COLOR_HIGHLIGHT);
    colorTable_[KnownColor.HighlightText] = systemColorToArgb(COLOR_HIGHLIGHTTEXT); 
    colorTable_[KnownColor.HotTrack] = systemColorToArgb(COLOR_HOTLIGHT);
    colorTable_[KnownColor.InactiveBorder] = systemColorToArgb(COLOR_INACTIVEBORDER); 
    colorTable_[KnownColor.InactiveCaption] = systemColorToArgb(COLOR_INACTIVECAPTION); 
    colorTable_[KnownColor.InactiveCaptionText] = systemColorToArgb(COLOR_INACTIVECAPTIONTEXT);
    colorTable_[KnownColor.Info] = systemColorToArgb(COLOR_INFOBK); 
    colorTable_[KnownColor.InfoText] = systemColorToArgb(COLOR_INFOTEXT);
    colorTable_[KnownColor.Menu] = systemColorToArgb(COLOR_MENU);
    colorTable_[KnownColor.MenuBar] = systemColorToArgb(COLOR_MENUBAR);
    colorTable_[KnownColor.MenuHighlight] = systemColorToArgb(COLOR_MENUHILIGHT); 
    colorTable_[KnownColor.MenuText] = systemColorToArgb(COLOR_MENUTEXT);
    colorTable_[KnownColor.ScrollBar] = systemColorToArgb(COLOR_SCROLLBAR); 
    colorTable_[KnownColor.Window] = systemColorToArgb(COLOR_WINDOW); 
    colorTable_[KnownColor.WindowFrame] = systemColorToArgb(COLOR_WINDOWFRAME);
    colorTable_[KnownColor.WindowText] = systemColorToArgb(COLOR_WINDOWTEXT); 

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

  private static void initHtmlTable() {
    htmlTable_["activeborder"] = Color.fromKnownColor(KnownColor.ActiveBorder);
    htmlTable_["activecaption"] = Color.fromKnownColor(KnownColor.ActiveCaption);
    htmlTable_["appworkspace"] = Color.fromKnownColor(KnownColor.AppWorkspace); 
    htmlTable_["background"] = Color.fromKnownColor(KnownColor.Desktop);
    htmlTable_["buttonface"] = Color.fromKnownColor(KnownColor.Control); 
    htmlTable_["buttonhighlight"] = Color.fromKnownColor(KnownColor.ControlLightLight); 
    htmlTable_["buttonshadow"] = Color.fromKnownColor(KnownColor.ControlDark);
    htmlTable_["buttontext"] = Color.fromKnownColor(KnownColor.ControlText); 
    htmlTable_["captiontext"] = Color.fromKnownColor(KnownColor.ActiveCaptionText);
    htmlTable_["graytext"] = Color.fromKnownColor(KnownColor.GrayText);
    htmlTable_["highlight"] = Color.fromKnownColor(KnownColor.Highlight);
    htmlTable_["highlighttext"] = Color.fromKnownColor(KnownColor.HighlightText); 
    htmlTable_["inactiveborder"] = Color.fromKnownColor(KnownColor.InactiveBorder);
    htmlTable_["inactivecaption"] = Color.fromKnownColor(KnownColor.InactiveCaption); 
    htmlTable_["inactivecaptiontext"] = Color.fromKnownColor(KnownColor.InactiveCaptionText); 
    htmlTable_["infobackground"] = Color.fromKnownColor(KnownColor.Info);
    htmlTable_["infotext"] = Color.fromKnownColor(KnownColor.InfoText); 
    htmlTable_["menu"] = Color.fromKnownColor(KnownColor.Menu);
    htmlTable_["menutext"] = Color.fromKnownColor(KnownColor.MenuText);
    htmlTable_["scrollbar"] = Color.fromKnownColor(KnownColor.ScrollBar);
    htmlTable_["threeddarkshadow"] = Color.fromKnownColor(KnownColor.ControlDarkDark); 
    htmlTable_["threedface"] = Color.fromKnownColor(KnownColor.Control);
    htmlTable_["threedhighlight"] = Color.fromKnownColor(KnownColor.ControlLight); 
    htmlTable_["threedlightshadow"] = Color.fromKnownColor(KnownColor.ControlLightLight); 
    htmlTable_["window"] = Color.fromKnownColor(KnownColor.Window);
    htmlTable_["windowframe"] = Color.fromKnownColor(KnownColor.WindowFrame); 
    htmlTable_["windowtext"] = Color.fromKnownColor(KnownColor.WindowText);
  }

}

/**
 * Encapsulates a 3x3 affine matrix the represents a geometric transform.
 */
final class Matrix : IDisposable {

  private Handle nativeMatrix_;

  /**
   * Initializes a new instance.
   */
  this() {
    Status status = GdipCreateMatrix(nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  this(float m11, float m12, float m21, float m22, float dx, float dy) {
    Status status = GdipCreateMatrix2(m11, m12, m21, m22, dx, dy, nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  this(Rect rect, Point[] plgpts) {
    if (plgpts.length != 3)
      throw statusException(Status.InvalidParameter);

    Status status = GdipCreateMatrix3I(rect, plgpts.ptr, nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
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
   * Releases all resources used by this instance.
   */
  void dispose() {
    if (nativeMatrix_ != Handle.init) {
      GdipDeleteMatrixSafe(nativeMatrix_);
      nativeMatrix_ = Handle.init;
    }
  }

  /**
   * Creates an exact copy of this object.
   * Returns: The object that this method creates.
   */
  Object clone() {
    Handle cloneMatrix;

    Status status = GdipCloneMatrix(nativeMatrix_, cloneMatrix);
    if (status != Status.OK)
      throw statusException(status);

    return new Matrix(cloneMatrix);
  }

  /**
   * Inverts this object, if it is invertible.
   */
  void invert() {
    Status status = GdipInvertMatrix(nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Resets this object to have the elements of the identity matrix.
   */
  void reset() {
    Status status = GdipSetMatrixElements(nativeMatrix_, 1, 0, 0, 1, 0, 0);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Multiplies this object by the specified object in the specified _order.
   * Params:
   *   matrix = The object by which this instance is to be multiplied.
   *   order = The _order of the multiplication.
   */
  void multiply(Matrix matrix, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipMultiplyMatrix(nativeMatrix_, matrix.nativeMatrix_, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Applies the specified _scale vector to this oject in the specified _order.
   * Params:
   *   scaleX = The value by which to _scale this object in the x-axis direction.
   *   scaleY = The value by which to _scale this object in the y-axis direction.
   *   order = The _order in which the _scale vector is applied.
   */
  void scale(float scaleX, float scaleY, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipScaleMatrix(nativeMatrix_, scaleX, scaleY, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Applies the specified _shear vector to this oject in the specified _order.
   * Params:
   *   scaleX = The horizontal _shear.
   *   scaleY = The vertical _shear.
   *   order = The _order in which the _shear vector is applied.
   */
  void shear(float shearX, float shearY, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipShearMatrix(nativeMatrix_, shearX, shearY, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Applies a clockwise rotation of the specified _angle about the origin to this object.
   * Params:
   *   angle = The _angle of the rotation.
   *   order = The _order in which the rotation is applied.
   */
  void rotate(float angle, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipRotateMatrix(nativeMatrix_, angle, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Applies the specified translation vector to this object.
   * params:
   *   offsetX = The x value by which to _translate this object.
   *   offsetY = The y value by which to _translate this object.
   *   order = The _order in which the translation is applied.
   */
  void translate(float offsetX, float offsetY, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipTranslateMatrix(nativeMatrix_, offsetX, offsetY, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Gets an array of floating-point values that represents the _elements of this object.
   */
  @property float[] elements() {
    float[] m = new float[6];
    Status status = GdipGetMatrixElements(nativeMatrix_, m.ptr);
    if (status != Status.OK)
      throw statusException(status);
    return m;
  }

  /**
   * Gets the x translation value.
   */
  @property float offsetX() {
    return elements[4];
  }

  /**
   * Gets the y translation value.
   */
  @property float offsetY() {
    return elements[5];
  }

  /**
   * Gets a value indicating whether this object is the identity matrix.
   * Returns: true if this object is identity; otherwise, false.
   */
  @property bool isIdentity() {
    int result;
    Status status = GdipIsMatrixIdentity(nativeMatrix_, result);
    if (status != Status.OK)
      throw statusException(status);
    return result == 1;
  }

  /**
   * Gets a value indicating whether this object is invertible.
   * Returns: true if this matrix is invertible; otherwise, false.
   */
  @property bool isInvertible() {
    int result;
    Status status = GdipIsMatrixInvertible(nativeMatrix_, result);
    if (status != Status.OK)
      throw statusException(status);
    return result == 1;
  }

  private this(Handle nativeMatrix) {
    nativeMatrix_ = nativeMatrix;
  }

}

/**
 * Represents the state of a Graphics object.
 */
final class GraphicsState {

  private int nativeState_;

  private this(int state) {
    nativeState_ = state;
  }

}

/**
 * Represents the internal data of a graphics container.
 */
final class GraphicsContainer {

  private int nativeContainer_;

  private this(int container) {
    nativeContainer_ = container;
  }

}

/**
 * Encapsualtes a GDI+ drawing surface.
 */
final class Graphics : IDisposable {

  /**
   * <code>bool delegate(void* callbackData)</code>
   *
   * Provides a callback method for deciding when the drawImage method should prematurely cancel execution.
   * Params: callbackData = Pointer specifying data for the callback method.
   * Returns: true if the method decides that the drawImage method should prematurely cancel execution; otherwise, false.
   */
  alias bool delegate(void* callbackData) DrawImageAbort;

  private Handle nativeGraphics_;
  private Handle nativeHdc_;

  private static Handle halftonePalette_;

  static ~this() {
    if (halftonePalette_ != Handle.init) {
      DeleteObject(halftonePalette_);
      halftonePalette_ = Handle.init;
    }
  }

  private this(Handle nativeGraphics) {
    nativeGraphics_ = nativeGraphics;
  }

  ~this() {
    dispose();
  }

  /**
   * Releases all the resources used by this instance.
   */
  final void dispose() {
    if (nativeGraphics_ != Handle.init) {
      if (nativeHdc_ != Handle.init)
        releaseHdc();

      GdipDeleteGraphicsSafe(nativeGraphics_);
      nativeGraphics_ = Handle.init;
    }
  }

  /**
   * Gets a handle to the current Windows halftone palette.
   */
  static Handle getHalftonePalette() {
    synchronized {
      if (halftonePalette_ == Handle.init)
        halftonePalette_ = GdipCreateHalftonePalette();
      return halftonePalette_;
    }
  }

  /**
   * Creates a new instance from the specified Image object.
   * Params: image = The Image object on which to create the new instance.
   */
  static Graphics fromImage(Image image) {
    if (image is null)
      throw new ArgumentNullException("image");

    Handle nativeGraphics;

    Status status = GdipGetImageGraphicsContext(image.nativeImage_, nativeGraphics);
    if (status != Status.OK)
      throw statusException(status);

    return new Graphics(nativeGraphics);
  }

  /**
   * Creates a new instance from the specified handle to a window.
   * Params: hwnd = Handle to a window.
   */
  static Graphics fromHwnd(Handle hwnd) {
    Handle nativeGraphics;

    Status status = GdipCreateFromHWND(hwnd, nativeGraphics);
    if (status != Status.OK)
      throw statusException(status);

    return new Graphics(nativeGraphics);
  }

  /**
   * Creates a new instance from the specified handle to a device context.
   * Params: hdc = Handle to a device context.
   */
  static Graphics fromHdc(Handle hdc) {
    Handle nativeGraphics;

    Status status = GdipCreateFromHDC(hdc, nativeGraphics);
    if (status != Status.OK)
      throw statusException(status);

    return new Graphics(nativeGraphics);
  }

  /**
   * Creates a new instance from the specified handle to a device context and handle to a device.
   * Params: 
   *   hdc = Handle to a device context.
   *   hdevice = Handle to a device.
   */
  static Graphics fromHdc(Handle hdc, Handle hdevice) {
    Handle nativeGraphics;

    Status status = GdipCreateFromHDC2(hdc, hdevice, nativeGraphics);
    if (status != Status.OK)
      throw statusException(status);

    return new Graphics(nativeGraphics);
  }

  /**
   * Gets the handle to the device context associated with this instance.
   */
  Handle getHdc() {
    Handle hdc;

    Status status = GdipGetDC(nativeGraphics_, hdc);
    if (status != Status.OK)
      throw statusException(status);

    return nativeHdc_ = hdc;
  }

  /**
   * Releases a device context handle obtained by a previous call to the getHdc method.
   * Params: hdc = Handle to a device context obtained by a previous call to the getHdc method.
   */
  void releaseHdc(Handle hdc) {
    Status status = GdipReleaseDC(nativeGraphics_, nativeHdc_);
    if (status != Status.OK)
      throw statusException(status);

    nativeHdc_ = Handle.init;
  }

  /**
   * ditto
   */
  void releaseHdc() {
    releaseHdc(nativeHdc_);
  }

  /**
   * Saves the current state of this instance and identifies the saved state with a GraphicsState object.
   */
  GraphicsState save() {
    int state;
    Status status = GdipSaveGraphics(nativeGraphics_, state);
    if (status != Status.OK)
      throw statusException(status);
    return new GraphicsState(state);
  }
  
  /**
   * Restores the state of this instance to the _state represented by a GraphicsState object.
   * Params: state = The _state to which to _restore this instance.
   */
  void restore(GraphicsState state) {
    Status status = GdipRestoreGraphics(nativeGraphics_, state.nativeState_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  GraphicsContainer beginContainer() {
    int state;
    Status status = GdipBeginContainer2(nativeGraphics_, state);
    if (status != Status.OK)
      throw statusException(status);
    return new GraphicsContainer(state);
  }

  /**
   */
  GraphicsContainer beginContainer(Rect dstrect, Rect srcrect, GraphicsUnit unit) {
    int state;
    Status status = GdipBeginContainerI(nativeGraphics_, dstrect, srcrect, unit, state);
    if (status != Status.OK)
      throw statusException(status);
    return new GraphicsContainer(state);
  }

  /**
   */
  GraphicsContainer beginContainer(RectF dstrect, RectF srcrect, GraphicsUnit unit) {
    int state;
    Status status = GdipBeginContainer(nativeGraphics_, dstrect, srcrect, unit, state);
    if (status != Status.OK)
      throw statusException(status);
    return new GraphicsContainer(state);
  }

  /**
   */
  void endContainer(GraphicsContainer container) {
    if (container is null)
      throw new ArgumentNullException("container");

    Status status = GdipEndContainer(nativeGraphics_, container.nativeContainer_);
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
  void translateClip(int dx, int dy) {
    Status status = GdipTranslateClip(nativeGraphics_, cast(float)dx, cast(float)dy);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void translateClip(float dx, float dy) {
    Status status = GdipTranslateClip(nativeGraphics_, dx, dy);
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
  void clear(Color color) {
    Status status = GdipGraphicsClear(nativeGraphics_, color.toArgb());
    if (status != Status.OK)
      throw statusException(status);
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
   */
  void drawImage(Image image, RectF destRect, RectF srcRect, GraphicsUnit srcUnit) {
    if (image is null)
      throw new ArgumentNullException("image");

    Status status = GdipDrawImageRectRect(nativeGraphics_, image.nativeImage_, destRect.x, destRect.y, destRect.width, destRect.y, srcRect.x, srcRect.y, srcRect.width, srcRect.height, srcUnit, Handle.init, null, null);
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
   */
  void drawImage(Image image, Point point) {
    drawImage(image, point.x, point.y);
  }

  /**
   */
  void drawImage(Image image, int x, int y) {
    if (image is null)
      throw new ArgumentNullException("image");

    Status status = GdipDrawImageI(nativeGraphics_, image.nativeImage_, x, y);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawImage(Image image, Rect rect) {
    drawImage(image, rect.x, rect.y, rect.width, rect.height);
  }

  /**
   */
  void drawImage(Image image, int x, int y, int width, int height) {
    if (image is null)
      throw new ArgumentNullException("image");

    Status status = GdipDrawImageRectI(nativeGraphics_, image.nativeImage_, x, y, width, height);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawImage(Image image, int x, int y, Rect srcRect, GraphicsUnit srcUnit) {
    if (image is null)
      throw new ArgumentNullException("image");

    Status status = GdipDrawImagePointRectI(nativeGraphics_, image.nativeImage_, x, y, srcRect.x, srcRect.y, srcRect.width, srcRect.height, srcUnit);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void drawImage(Image image, Rect destRect, Rect srcRect, GraphicsUnit srcUnit) {
    if (image is null)
      throw new ArgumentNullException("image");

    Status status = GdipDrawImageRectRectI(nativeGraphics_, image.nativeImage_, 
      destRect.x, destRect.y, destRect.width, destRect.height, 
      srcRect.x, srcRect.y, srcRect.width, srcRect.height, srcUnit, Handle.init, null, null);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
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
  void drawString(string s, Font font, Brush brush, float x, float y, StringFormat format = null) {
    drawString(s, font, brush, RectF(x, y, 0, 0), format);
  }

  /**
   */
  void drawString(string s, Font font, Brush brush, PointF point, StringFormat format = null) {
    drawString(s, font, brush, RectF(point.x, point.y, 0, 0), format);
  }

  /**
   */
  void drawString(string s, Font font, Brush brush, RectF layoutRect, StringFormat format = null) {
    if (brush is null)
      throw new ArgumentNullException("brush");

    if (s != null) {
      if (font is null)
        throw new ArgumentNullException("font");

      Status status = GdipDrawString(nativeGraphics_, s.toUtf16z(), s.length, font.nativeFont_, layoutRect, (format is null) ? Handle.init : format.nativeFormat_, brush.nativeBrush_);
      if (status != Status.OK)
        throw statusException(status);
    }
  }

  /**
   */
  SizeF measureString(string s, Font font) {
    return measureString(s, font, SizeF.empty);
  }

  /**
   */
  SizeF measureString(string s, Font font, PointF origin, StringFormat format = null) {
    if (s == null)
      return SizeF.empty;

    if (font is null)
      throw new ArgumentNullException("font");

    RectF layoutRect = RectF(origin.x, origin.y, 0f, 0f);
    RectF boundingBox;
    int codepointsFitted, linesFilled;

    Status status = GdipMeasureString(nativeGraphics_, s.toUtf16z(), s.length, font.nativeFont_, layoutRect, (format is null) ? Handle.init : format.nativeFormat_, boundingBox, codepointsFitted, linesFilled);
    if (status != Status.OK)
      throw statusException(status);

    return boundingBox.size;
  }

  /**
   */
  SizeF measureString(string s, Font font, SizeF layoutArea, StringFormat format = null) {
    if (s == null)
      return SizeF.empty;

    if (font is null)
      throw new ArgumentNullException("font");

    RectF layoutRect = RectF(0f, 0f, layoutArea.width, layoutArea.height);
    RectF boundingBox;
    int codepointsFitted, linesFilled;

    Status status = GdipMeasureString(nativeGraphics_, s.toUtf16z(), s.length, font.nativeFont_, layoutRect, (format is null) ? Handle.init : format.nativeFormat_, boundingBox, codepointsFitted, linesFilled);
    if (status != Status.OK)
      throw statusException(status);

    return boundingBox.size;
  }

  /**
   */
  SizeF measureString(string s, Font font, SizeF layoutArea, StringFormat format, out int codepointsFitted, out int linesFilled) {
    if (s == null)
      return SizeF.empty;

    if (font is null)
      throw new ArgumentNullException("font");

    RectF layoutRect = RectF(0, 0, layoutArea.width, layoutArea.height);
    RectF boundingBox;

    Status status = GdipMeasureString(nativeGraphics_, s.toUtf16z(), s.length, font.nativeFont_, layoutRect, (format is null) ? Handle.init : format.nativeFormat_, boundingBox, codepointsFitted, linesFilled);
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

    int regionCount;
    Status status = GdipGetStringFormatMeasurableCharacterRangeCount((format is null) ? Handle.init : format.nativeFormat_, regionCount);
    if (status != Status.OK)
      throw statusException(status);

    auto nativeRegions = new Handle[regionCount];
    auto regions = new Region[regionCount];

    for (int i = 0; i < regionCount; i++) {
      regions[i] = new Region;
      nativeRegions[i] = regions[i].nativeRegion_;
    }

    status = GdipMeasureCharacterRanges(nativeGraphics_, s.toUtf16z(), s.length, font.nativeFont_, layoutRect, (format is null) ? Handle.init : format.nativeFormat_, regionCount, nativeRegions.ptr);
    if (status != Status.OK)
      throw statusException(status);

    return regions;
  }

  /**
   */
  @property float dpiX() {
    float dpi = 0f;
    Status status = GdipGetDpiX(nativeGraphics_, dpi);
    if (status != Status.OK)
      throw statusException(status);
    return dpi;
  }

  /**
   */
  @property float dpiY() {
    float dpi = 0f;
    Status status = GdipGetDpiY(nativeGraphics_, dpi);
    if (status != Status.OK)
      throw statusException(status);
    return dpi;
  }

  /**
   */
  @property void pageScale(float value) {
    Status status = GdipSetPageScale(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /// ditto
  @property float pageScale() {
    float scale = 0f;
    Status status = GdipGetPageScale(nativeGraphics_, scale);
    if (status != Status.OK)
      throw statusException(status);
    return scale;
  }

  /**
   */
  @property void pageUnit(GraphicsUnit value) {
    Status status = GdipSetPageUnit(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /// ditto
  @property GraphicsUnit pageUnit() {
    GraphicsUnit value;
    Status status = GdipGetPageUnit(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  @property void compositingMode(CompositingMode value) {
    Status status = GdipSetCompositingMode(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /// ditto
  @property CompositingMode compositingMode() {
    CompositingMode mode;
    Status status = GdipGetCompositingMode(nativeGraphics_, mode);
    if (status != Status.OK)
      throw statusException(status);
    return mode;
  }

  /**
   */
  @property void compositingQuality(CompositingQuality value) {
    Status status = GdipSetCompositingQuality(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /// ditto
  @property CompositingQuality compositingQuality() {
    CompositingQuality value;
    Status status = GdipGetCompositingQuality(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  @property InterpolationMode interpolationMode() {
    InterpolationMode value;
    Status status = GdipGetInterpolationMode(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }
  /// ditto
  @property void interpolationMode(InterpolationMode value) {
    Status status = GdipSetInterpolationMode(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  @property void smoothingMode(SmoothingMode value) {
    Status status = GdipSetSmoothingMode(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /// ditto
  @property SmoothingMode smoothingMode() {
    SmoothingMode mode;
    Status status = GdipGetSmoothingMode(nativeGraphics_, mode);
    if (status != Status.OK)
      throw statusException(status);
    return mode;
  }

  /**
   */
  @property void pixelOffsetMode(PixelOffsetMode value) {
    Status status = GdipSetPixelOffsetMode(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /// ditto
  @property PixelOffsetMode pixelOffsetMode() {
    PixelOffsetMode value;
    Status status = GdipGetPixelOffsetMode(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  @property void textContrast(uint value) {
    Status status = GdipSetTextContrast(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /// ditto
  @property uint textContrast() {
    uint contrast;
    Status status = GdipGetTextContrast(nativeGraphics_, contrast);
    if (status != Status.OK)
      throw statusException(status);
    return contrast;
  }

  /**
   */
  @property void textRenderingHint(TextRenderingHint value) {
    Status status = GdipSetTextRenderingHint(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /// ditto
  @property TextRenderingHint textRenderingHint() {
    TextRenderingHint value;
    Status status = GdipGetTextRenderingHint(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  @property bool isClipEmpty() {
    int value;
    Status status = GdipIsClipEmpty(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value == 1;
  }

  /**
   */
  @property bool isVisibleClipEmpty() {
    int value;
    Status status = GdipIsVisibleClipEmpty(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value == 1;
  }

  /**
   */
  @property RectF clipBounds() {
    RectF value;
    Status status = GdipGetClipBounds(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  @property RectF visibleClipBounds() {
    RectF value;
    Status status = GdipGetVisibleClipBounds(nativeGraphics_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  @property void renderingOrigin(Point value) {
    Status status = GdipGetRenderingOrigin(nativeGraphics_, value.x, value.y);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  @property Point renderingOrigin() {
    int x, y;
    Status status = GdipGetRenderingOrigin(nativeGraphics_, x, y);
    if (status != Status.OK)
      throw statusException(status);
    return Point(x, y);
  }

  /**
   */
  @property void transform(Matrix value) {
    Status status = GdipSetWorldTransform(nativeGraphics_, value.nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
  }
  /**
   * ditto
   */
 @property  Matrix transform() {
    Matrix matrix = new Matrix;
    Status status = GdipGetWorldTransform(nativeGraphics_, matrix.nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);
    return matrix;
  }

}

/**
 */
struct CharacterRange {

  int first;  ///
  int length; ///

  /**
   */
  static CharacterRange opCall(int first, int length) {
    CharacterRange cr;
    cr.first = first;
    cr.length = length;
    return cr;
  }

  bool opEquals(CharacterRange other) {
    return first == other.first && length == other.length;
  }

}

/**
 */
final class StringFormat : IDisposable {

  private Handle nativeFormat_;

  private this(Handle nativeFormat) {
    nativeFormat_ = nativeFormat;
  }

  /**
   */
  this(StringFormatFlags options = cast(StringFormatFlags)0, uint language = 0) {
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
  Object clone() {
    Handle newFormat;

    Status status = GdipCloneStringFormat(nativeFormat_, newFormat);
    if (status != Status.OK)
      throw statusException(status);

    return new StringFormat(newFormat);
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
  float[] getTabStops(out float firstTabOffset) {
    int count;
    Status status = GdipGetStringFormatTabStopCount(nativeFormat_, count);
    if (status != Status.OK)
      throw statusException(status);

    float[] tabStops = new float[count];
    status = GdipGetStringFormatTabStops(nativeFormat_, count, firstTabOffset, tabStops.ptr);
    if (status != Status.OK)
      throw statusException(status);

    return tabStops;
  }

  /**
   */
  void setTabStops(float firstTabOffset, float[] tabStops) {
    Status status = GdipSetStringFormatTabStops(nativeFormat_, firstTabOffset, tabStops.length, tabStops.ptr);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  static StringFormat genericDefault() {
    Handle format;
    Status status = GdipStringFormatGetGenericDefault(format);
    if (status != Status.OK)
      throw statusException(status);
    return new StringFormat(format);
  }

  /**
   */
  static StringFormat genericTypographic() {
    Handle format;
    Status status = GdipStringFormatGetGenericTypographic(format);
    if (status != Status.OK)
      throw statusException(status);
    return new StringFormat(format);
  }

  /**
   */
  void formatFlags(StringFormatFlags value) {
    Status status = GdipSetStringFormatFlags(nativeFormat_, value);
    if (status != Status.OK)
      throw statusException(status);
  }
  /// ditto
  StringFormatFlags formatFlags() {
    StringFormatFlags flags;
    Status status = GdipGetStringFormatFlags(nativeFormat_, flags);
    if (status != Status.OK)
      throw statusException(status);
    return flags;
  }

  /**
   */
  void alignment(StringAlignment value) {
    Status status = GdipSetStringFormatAlign(nativeFormat_, value);
    if (status != Status.OK)
      throw statusException(status);
  }
  /// ditto
  StringAlignment alignment() {
    StringAlignment alignment;
    Status status = GdipGetStringFormatAlign(nativeFormat_, alignment);
    if (status != Status.OK)
      throw statusException(status);
    return alignment;
  }

  /**
   */
  void lineAlignment(StringAlignment value) {
    Status status = GdipSetStringFormatLineAlign(nativeFormat_, value);
    if (status != Status.OK)
      throw statusException(status);
  }
  /// ditto
  StringAlignment lineAlignment() {
    StringAlignment alignment;
    Status status = GdipGetStringFormatLineAlign(nativeFormat_, alignment);
    if (status != Status.OK)
      throw statusException(status);
    return alignment;
  }

  /**
   */
  void trimming(StringTrimming value) {
    Status status = GdipSetStringFormatTrimming(nativeFormat_, value);
    if (status != Status.OK)
      throw statusException(status);
  }
  /// ditto
  StringTrimming trimming() {
    StringTrimming trimming;
    Status status = GdipGetStringFormatTrimming(nativeFormat_, trimming);
    if (status != Status.OK)
      throw statusException(status);
    return trimming;
  }

  /**
   */
  void hotkeyPrefix(HotkeyPrefix value) {
    Status status = GdipSetStringFormatHotkeyPrefix(nativeFormat_, value);
    if (status != Status.OK)
      throw statusException(status);
  }
  /// ditto
  HotkeyPrefix hotkeyPrefix() {
    HotkeyPrefix hotkeyPrefix;
    Status status = GdipGetStringFormatHotkeyPrefix(nativeFormat_, hotkeyPrefix);
    if (status != Status.OK)
      throw statusException(status);
    return hotkeyPrefix;
  }

}

/**
 * Defines objects used to fill the interior of graphical shapes such as rectangles, ellipses, pies, polygons and paths.
 */
abstract class Brush : IDisposable {

  private Handle nativeBrush_;

  /**
   * Initializes a new instance.
   */
  protected this() {
  }

  ~this() {
    dispose(false);
  }

  /**
   * Releases all resources used by the Brush.
   */
  final void dispose() {
    dispose(true);
  }

  /**
   */
  protected void dispose(bool disposing) {
    if (nativeBrush_ != Handle.init) {
      GdipDeleteBrushSafe(nativeBrush_);
      nativeBrush_ = Handle.init;
    }
  }

  version(D_Version2) {
    private static Brush[KnownColor] brushes_; // TLS by default
  }
  else {
    private static ThreadLocal!(Brush[KnownColor]) brushes_;
  }

  static ~this() {
    brushes_ = null;
  }

  private static Brush fromKnownColor(KnownColor c) {
    version(D_Version2) {
      Brush brush;
      if (auto value = c in brushes_) {
        brush = *value;
      }
      else {
        brush = brushes_[c] = new SolidBrush(Color.fromKnownColor(c));
      }
      return brush;
    }
    else {
      if (brushes_ is null)
        brushes_ = new ThreadLocal!(Brush[KnownColor]);

      auto brushes = brushes_.get();

      Brush brush;
      if (auto value = c in brushes) {
        brush = *value;
      }
      else {
        brush = brushes[c] = new SolidBrush(Color.fromKnownColor(c));
        brushes_.set(brushes);
      }
      return brush;
    }
  }

  /// Gets a system-defined Brush object.
  static Brush activeBorder() {
    return fromKnownColor(KnownColor.ActiveBorder);
  }

  /// ditto 
  static Brush activeCaption() {
    return fromKnownColor(KnownColor.ActiveCaption);
  }

  /// ditto 
  static Brush activeCaptionText() {
    return fromKnownColor(KnownColor.ActiveCaptionText);
  }

  /// ditto 
  static Brush appWorkspace() {
    return fromKnownColor(KnownColor.AppWorkspace);
  }

  /// ditto 
  static Brush control() {
    return fromKnownColor(KnownColor.Control);
  }

  /// ditto 
  static Brush controlDark() {
    return fromKnownColor(KnownColor.ControlDark);
  }

  /// ditto 
  static Brush controlDarkDark() {
    return fromKnownColor(KnownColor.ControlDarkDark);
  }

  /// ditto 
  static Brush controlLight() {
    return fromKnownColor(KnownColor.ControlLight);
  }

  /// ditto 
  static Brush controlLightLight() {
    return fromKnownColor(KnownColor.ControlLightLight);
  }

  /// ditto 
  static Brush controlText() {
    return fromKnownColor(KnownColor.ControlText);
  }

  /// ditto 
  static Brush desktop() {
    return fromKnownColor(KnownColor.Desktop);
  }

  /// ditto 
  static Brush grayText() {
    return fromKnownColor(KnownColor.GrayText);
  }

  /// ditto 
  static Brush highlight() {
    return fromKnownColor(KnownColor.Highlight);
  }

  /// ditto 
  static Brush highlightText() {
    return fromKnownColor(KnownColor.HighlightText);
  }

  /// ditto 
  static Brush hotTrack() {
    return fromKnownColor(KnownColor.HotTrack);
  }

  /// ditto 
  static Brush inactiveBorder() {
    return fromKnownColor(KnownColor.InactiveBorder);
  }

  /// ditto 
  static Brush inactiveCaption() {
    return fromKnownColor(KnownColor.InactiveCaption);
  }

  /// ditto 
  static Brush inactiveCaptionText() {
    return fromKnownColor(KnownColor.InactiveCaptionText);
  }

  /// ditto 
  static Brush info() {
    return fromKnownColor(KnownColor.Info);
  }

  /// ditto 
  static Brush infoText() {
    return fromKnownColor(KnownColor.InfoText);
  }

  /// ditto 
  static Brush menu() {
    return fromKnownColor(KnownColor.Menu);
  }

  /// ditto 
  static Brush menuText() {
    return fromKnownColor(KnownColor.MenuText);
  }

  /// ditto 
  static Brush scrollBar() {
    return fromKnownColor(KnownColor.ScrollBar);
  }

  /// ditto 
  static Brush window() {
    return fromKnownColor(KnownColor.Window);
  }

  /// ditto 
  static Brush windowFrame() {
    return fromKnownColor(KnownColor.WindowFrame);
  }

  /// ditto 
  static Brush windowText() {
    return fromKnownColor(KnownColor.WindowText);
  }

  /// ditto 
  static Brush transparent() {
    return fromKnownColor(KnownColor.Transparent);
  }

  /// ditto 
  static Brush aliceBlue() {
    return fromKnownColor(KnownColor.AliceBlue);
  }

  /// ditto 
  static Brush antiqueWhite() {
    return fromKnownColor(KnownColor.AntiqueWhite);
  }

  /// ditto 
  static Brush aqua() {
    return fromKnownColor(KnownColor.Aqua);
  }

  /// ditto 
  static Brush aquamarine() {
    return fromKnownColor(KnownColor.Aquamarine);
  }

  /// ditto 
  static Brush azure() {
    return fromKnownColor(KnownColor.Azure);
  }

  /// ditto 
  static Brush beige() {
    return fromKnownColor(KnownColor.Beige);
  }

  /// ditto 
  static Brush bisque() {
    return fromKnownColor(KnownColor.Bisque);
  }

  /// ditto 
  static Brush black() {
    return fromKnownColor(KnownColor.Black);
  }

  /// ditto 
  static Brush blanchedAlmond() {
    return fromKnownColor(KnownColor.BlanchedAlmond);
  }

  /// ditto 
  static Brush blue() {
    return fromKnownColor(KnownColor.Blue);
  }

  /// ditto 
  static Brush blueViolet() {
    return fromKnownColor(KnownColor.BlueViolet);
  }

  /// ditto 
  static Brush brown() {
    return fromKnownColor(KnownColor.Brown);
  }

  /// ditto 
  static Brush burlyWood() {
    return fromKnownColor(KnownColor.BurlyWood);
  }

  /// ditto 
  static Brush cadetBlue() {
    return fromKnownColor(KnownColor.CadetBlue);
  }

  /// ditto 
  static Brush chartreuse() {
    return fromKnownColor(KnownColor.Chartreuse);
  }

  /// ditto 
  static Brush chocolate() {
    return fromKnownColor(KnownColor.Chocolate);
  }

  /// ditto 
  static Brush coral() {
    return fromKnownColor(KnownColor.Coral);
  }

  /// ditto 
  static Brush cornflowerBlue() {
    return fromKnownColor(KnownColor.CornflowerBlue);
  }

  /// ditto 
  static Brush cornsilk() {
    return fromKnownColor(KnownColor.Cornsilk);
  }

  /// ditto 
  static Brush crimson() {
    return fromKnownColor(KnownColor.Crimson);
  }

  /// ditto 
  static Brush cyan() {
    return fromKnownColor(KnownColor.Cyan);
  }

  /// ditto 
  static Brush darkBlue() {
    return fromKnownColor(KnownColor.DarkBlue);
  }

  /// ditto 
  static Brush darkCyan() {
    return fromKnownColor(KnownColor.DarkCyan);
  }

  /// ditto 
  static Brush darkGoldenrod() {
    return fromKnownColor(KnownColor.DarkGoldenrod);
  }

  /// ditto 
  static Brush darkGray() {
    return fromKnownColor(KnownColor.DarkGray);
  }

  /// ditto 
  static Brush darkGreen() {
    return fromKnownColor(KnownColor.DarkGreen);
  }

  /// ditto 
  static Brush darkKhaki() {
    return fromKnownColor(KnownColor.DarkKhaki);
  }

  /// ditto 
  static Brush darkMagenta() {
    return fromKnownColor(KnownColor.DarkMagenta);
  }

  /// ditto 
  static Brush darkOliveGreen() {
    return fromKnownColor(KnownColor.DarkOliveGreen);
  }

  /// ditto 
  static Brush darkOrange() {
    return fromKnownColor(KnownColor.DarkOrange);
  }

  /// ditto 
  static Brush darkOrchid() {
    return fromKnownColor(KnownColor.DarkOrchid);
  }

  /// ditto 
  static Brush darkRed() {
    return fromKnownColor(KnownColor.DarkRed);
  }

  /// ditto 
  static Brush darkSalmon() {
    return fromKnownColor(KnownColor.DarkSalmon);
  }

  /// ditto 
  static Brush darkSeaGreen() {
    return fromKnownColor(KnownColor.DarkSeaGreen);
  }

  /// ditto 
  static Brush darkSlateBlue() {
    return fromKnownColor(KnownColor.DarkSlateBlue);
  }

  /// ditto 
  static Brush darkSlateGray() {
    return fromKnownColor(KnownColor.DarkSlateGray);
  }

  /// ditto 
  static Brush darkTurquoise() {
    return fromKnownColor(KnownColor.DarkTurquoise);
  }

  /// ditto 
  static Brush darkViolet() {
    return fromKnownColor(KnownColor.DarkViolet);
  }

  /// ditto 
  static Brush deepPink() {
    return fromKnownColor(KnownColor.DeepPink);
  }

  /// ditto 
  static Brush deepSkyBlue() {
    return fromKnownColor(KnownColor.DeepSkyBlue);
  }

  /// ditto 
  static Brush dimGray() {
    return fromKnownColor(KnownColor.DimGray);
  }

  /// ditto 
  static Brush dodgerBlue() {
    return fromKnownColor(KnownColor.DodgerBlue);
  }

  /// ditto 
  static Brush firebrick() {
    return fromKnownColor(KnownColor.Firebrick);
  }

  /// ditto 
  static Brush floralWhite() {
    return fromKnownColor(KnownColor.FloralWhite);
  }

  /// ditto 
  static Brush forestGreen() {
    return fromKnownColor(KnownColor.ForestGreen);
  }

  /// ditto 
  static Brush fuchsia() {
    return fromKnownColor(KnownColor.Fuchsia);
  }

  /// ditto 
  static Brush gainsboro() {
    return fromKnownColor(KnownColor.Gainsboro);
  }

  /// ditto 
  static Brush ghostWhite() {
    return fromKnownColor(KnownColor.GhostWhite);
  }

  /// ditto 
  static Brush gold() {
    return fromKnownColor(KnownColor.Gold);
  }

  /// ditto 
  static Brush goldenrod() {
    return fromKnownColor(KnownColor.Goldenrod);
  }

  /// ditto 
  static Brush gray() {
    return fromKnownColor(KnownColor.Gray);
  }

  /// ditto 
  static Brush green() {
    return fromKnownColor(KnownColor.Green);
  }

  /// ditto 
  static Brush greenYellow() {
    return fromKnownColor(KnownColor.GreenYellow);
  }

  /// ditto 
  static Brush honeydew() {
    return fromKnownColor(KnownColor.Honeydew);
  }

  /// ditto 
  static Brush hotPink() {
    return fromKnownColor(KnownColor.HotPink);
  }

  /// ditto 
  static Brush indianRed() {
    return fromKnownColor(KnownColor.IndianRed);
  }

  /// ditto 
  static Brush indigo() {
    return fromKnownColor(KnownColor.Indigo);
  }

  /// ditto 
  static Brush ivory() {
    return fromKnownColor(KnownColor.Ivory);
  }

  /// ditto 
  static Brush khaki() {
    return fromKnownColor(KnownColor.Khaki);
  }

  /// ditto 
  static Brush lavender() {
    return fromKnownColor(KnownColor.Lavender);
  }

  /// ditto 
  static Brush lavenderBlush() {
    return fromKnownColor(KnownColor.LavenderBlush);
  }

  /// ditto 
  static Brush lawnGreen() {
    return fromKnownColor(KnownColor.LawnGreen);
  }

  /// ditto 
  static Brush lemonChiffon() {
    return fromKnownColor(KnownColor.LemonChiffon);
  }

  /// ditto 
  static Brush lightBlue() {
    return fromKnownColor(KnownColor.LightBlue);
  }

  /// ditto 
  static Brush lightCoral() {
    return fromKnownColor(KnownColor.LightCoral);
  }

  /// ditto 
  static Brush lightCyan() {
    return fromKnownColor(KnownColor.LightCyan);
  }

  /// ditto 
  static Brush lightGoldenrodYellow() {
    return fromKnownColor(KnownColor.LightGoldenrodYellow);
  }

  /// ditto 
  static Brush lightGray() {
    return fromKnownColor(KnownColor.LightGray);
  }

  /// ditto 
  static Brush lightGreen() {
    return fromKnownColor(KnownColor.LightGreen);
  }

  /// ditto 
  static Brush lightPink() {
    return fromKnownColor(KnownColor.LightPink);
  }

  /// ditto 
  static Brush lightSalmon() {
    return fromKnownColor(KnownColor.LightSalmon);
  }

  /// ditto 
  static Brush lightSeaGreen() {
    return fromKnownColor(KnownColor.LightSeaGreen);
  }

  /// ditto 
  static Brush lightSkyBlue() {
    return fromKnownColor(KnownColor.LightSkyBlue);
  }

  /// ditto 
  static Brush lightSlateGray() {
    return fromKnownColor(KnownColor.LightSlateGray);
  }

  /// ditto 
  static Brush lightSteelBlue() {
    return fromKnownColor(KnownColor.LightSteelBlue);
  }

  /// ditto 
  static Brush lightYellow() {
    return fromKnownColor(KnownColor.LightYellow);
  }

  /// ditto 
  static Brush lime() {
    return fromKnownColor(KnownColor.Lime);
  }

  /// ditto 
  static Brush limeGreen() {
    return fromKnownColor(KnownColor.LimeGreen);
  }

  /// ditto 
  static Brush linen() {
    return fromKnownColor(KnownColor.Linen);
  }

  /// ditto 
  static Brush magenta() {
    return fromKnownColor(KnownColor.Magenta);
  }

  /// ditto 
  static Brush maroon() {
    return fromKnownColor(KnownColor.Maroon);
  }

  /// ditto 
  static Brush mediumAquamarine() {
    return fromKnownColor(KnownColor.MediumAquamarine);
  }

  /// ditto 
  static Brush mediumBlue() {
    return fromKnownColor(KnownColor.MediumBlue);
  }

  /// ditto 
  static Brush mediumOrchid() {
    return fromKnownColor(KnownColor.MediumOrchid);
  }

  /// ditto 
  static Brush mediumPurple() {
    return fromKnownColor(KnownColor.MediumPurple);
  }

  /// ditto 
  static Brush mediumSeaGreen() {
    return fromKnownColor(KnownColor.MediumSeaGreen);
  }

  /// ditto 
  static Brush mediumSlateBlue() {
    return fromKnownColor(KnownColor.MediumSlateBlue);
  }

  /// ditto 
  static Brush mediumSpringGreen() {
    return fromKnownColor(KnownColor.MediumSpringGreen);
  }

  /// ditto 
  static Brush mediumTurquoise() {
    return fromKnownColor(KnownColor.MediumTurquoise);
  }

  /// ditto 
  static Brush mediumVioletRed() {
    return fromKnownColor(KnownColor.MediumVioletRed);
  }

  /// ditto 
  static Brush midnightBlue() {
    return fromKnownColor(KnownColor.MidnightBlue);
  }

  /// ditto 
  static Brush mintCream() {
    return fromKnownColor(KnownColor.MintCream);
  }

  /// ditto 
  static Brush mistyRose() {
    return fromKnownColor(KnownColor.MistyRose);
  }

  /// ditto 
  static Brush moccasin() {
    return fromKnownColor(KnownColor.Moccasin);
  }

  /// ditto 
  static Brush navajoWhite() {
    return fromKnownColor(KnownColor.NavajoWhite);
  }

  /// ditto 
  static Brush navy() {
    return fromKnownColor(KnownColor.Navy);
  }

  /// ditto 
  static Brush oldLace() {
    return fromKnownColor(KnownColor.OldLace);
  }

  /// ditto 
  static Brush olive() {
    return fromKnownColor(KnownColor.Olive);
  }

  /// ditto 
  static Brush oliveDrab() {
    return fromKnownColor(KnownColor.OliveDrab);
  }

  /// ditto 
  static Brush orange() {
    return fromKnownColor(KnownColor.Orange);
  }

  /// ditto 
  static Brush orangeRed() {
    return fromKnownColor(KnownColor.OrangeRed);
  }

  /// ditto 
  static Brush orchid() {
    return fromKnownColor(KnownColor.Orchid);
  }

  /// ditto 
  static Brush paleGoldenrod() {
    return fromKnownColor(KnownColor.PaleGoldenrod);
  }

  /// ditto 
  static Brush paleGreen() {
    return fromKnownColor(KnownColor.PaleGreen);
  }

  /// ditto 
  static Brush paleTurquoise() {
    return fromKnownColor(KnownColor.PaleTurquoise);
  }

  /// ditto 
  static Brush paleVioletRed() {
    return fromKnownColor(KnownColor.PaleVioletRed);
  }

  /// ditto 
  static Brush papayaWhip() {
    return fromKnownColor(KnownColor.PapayaWhip);
  }

  /// ditto 
  static Brush peachPuff() {
    return fromKnownColor(KnownColor.PeachPuff);
  }

  /// ditto 
  static Brush peru() {
    return fromKnownColor(KnownColor.Peru);
  }

  /// ditto 
  static Brush pink() {
    return fromKnownColor(KnownColor.Pink);
  }

  /// ditto 
  static Brush plum() {
    return fromKnownColor(KnownColor.Plum);
  }

  /// ditto 
  static Brush powderBlue() {
    return fromKnownColor(KnownColor.PowderBlue);
  }

  /// ditto 
  static Brush purple() {
    return fromKnownColor(KnownColor.Purple);
  }

  /// ditto 
  static Brush red() {
    return fromKnownColor(KnownColor.Red);
  }

  /// ditto 
  static Brush rosyBrown() {
    return fromKnownColor(KnownColor.RosyBrown);
  }

  /// ditto 
  static Brush royalBlue() {
    return fromKnownColor(KnownColor.RoyalBlue);
  }

  /// ditto 
  static Brush saddleBrown() {
    return fromKnownColor(KnownColor.SaddleBrown);
  }

  /// ditto 
  static Brush salmon() {
    return fromKnownColor(KnownColor.Salmon);
  }

  /// ditto 
  static Brush sandyBrown() {
    return fromKnownColor(KnownColor.SandyBrown);
  }

  /// ditto 
  static Brush seaGreen() {
    return fromKnownColor(KnownColor.SeaGreen);
  }

  /// ditto 
  static Brush seaShell() {
    return fromKnownColor(KnownColor.SeaShell);
  }

  /// ditto 
  static Brush sienna() {
    return fromKnownColor(KnownColor.Sienna);
  }

  /// ditto 
  static Brush silver() {
    return fromKnownColor(KnownColor.Silver);
  }

  /// ditto 
  static Brush skyBlue() {
    return fromKnownColor(KnownColor.SkyBlue);
  }

  /// ditto 
  static Brush slateBlue() {
    return fromKnownColor(KnownColor.SlateBlue);
  }

  /// ditto 
  static Brush slateGray() {
    return fromKnownColor(KnownColor.SlateGray);
  }

  /// ditto 
  static Brush snow() {
    return fromKnownColor(KnownColor.Snow);
  }

  /// ditto 
  static Brush springGreen() {
    return fromKnownColor(KnownColor.SpringGreen);
  }

  /// ditto 
  static Brush steelBlue() {
    return fromKnownColor(KnownColor.SteelBlue);
  }

  /// ditto 
  static Brush tan() {
    return fromKnownColor(KnownColor.Tan);
  }

  /// ditto 
  static Brush teal() {
    return fromKnownColor(KnownColor.Teal);
  }

  /// ditto 
  static Brush thistle() {
    return fromKnownColor(KnownColor.Thistle);
  }

  /// ditto 
  static Brush tomato() {
    return fromKnownColor(KnownColor.Tomato);
  }

  /// ditto 
  static Brush turquoise() {
    return fromKnownColor(KnownColor.Turquoise);
  }

  /// ditto 
  static Brush violet() {
    return fromKnownColor(KnownColor.Violet);
  }

  /// ditto 
  static Brush wheat() {
    return fromKnownColor(KnownColor.Wheat);
  }

  /// ditto 
  static Brush white() {
    return fromKnownColor(KnownColor.White);
  }

  /// ditto 
  static Brush whiteSmoke() {
    return fromKnownColor(KnownColor.WhiteSmoke);
  }

  /// ditto 
  static Brush yellow() {
    return fromKnownColor(KnownColor.Yellow);
  }

  /// ditto 
  static Brush yellowGreen() {
    return fromKnownColor(KnownColor.YellowGreen);
  }

  /// ditto 
  static Brush buttonFace() {
    return fromKnownColor(KnownColor.ButtonFace);
  }

  /// ditto 
  static Brush buttonHighlight() {
    return fromKnownColor(KnownColor.ButtonHighlight);
  }

  /// ditto 
  static Brush buttonShadow() {
    return fromKnownColor(KnownColor.ButtonShadow);
  }

  /// ditto 
  static Brush gradientActiveCaption() {
    return fromKnownColor(KnownColor.GradientActiveCaption);
  }

  /// ditto 
  static Brush gradientInactiveCaption() {
    return fromKnownColor(KnownColor.GradientInactiveCaption);
  }

  /// ditto 
  static Brush menuBar() {
    return fromKnownColor(KnownColor.MenuBar);
  }

  /// ditto 
  static Brush menuHighlight() {
    return fromKnownColor(KnownColor.MenuHighlight);
  }

}

/**
 * Defines a brush of a single color.
 */
final class SolidBrush : Brush {

  private Color color_;

  private this(Handle nativeBrush) {
    nativeBrush_ = nativeBrush;
  }

  /**
   * Initializes a new SolidBrush object of the specified _color.
   * Params: color = The _color of this brush.
   */
  this(Color color) {
    color_ = color;

    Status status = GdipCreateSolidFill(color.toArgb(), nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Creates an exact copy of this brush.
   * Returns: The SolidBrush object that this method creates.
   */
  Object clone() {
    Handle cloneBrush;
    Status status = GdipCloneBrush(nativeBrush_, cloneBrush);
    if (status != Status.OK)
      throw statusException(status);
    return new SolidBrush(cloneBrush);
  }

  /**
   * Gets or sets the _color of this SolidBrush object.
   * Params: value = The _color of this brush.
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
  this(Image image, Rect rect, ImageAttributes imageAttr) {
    if (image is null)
      throw new ArgumentNullException("image"); 

    Status status = GdipCreateTextureIAI(image.nativeImage_, (imageAttr is null) ? Handle.init : imageAttr.nativeImageAttributes, rect.x, rect.y, rect.width, rect.height, nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(Image image, RectF rect, ImageAttributes imageAttr) {
    if (image is null)
      throw new ArgumentNullException("image"); 

    Status status = GdipCreateTextureIA(image.nativeImage_, (imageAttr is null) ? Handle.init : imageAttr.nativeImageAttributes, rect.x, rect.y, rect.width, rect.height, nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * Creates an exact copy of this brush.
   * Returns: The TextureBrush object that this method creates.
   */
  Object clone() {
    Handle cloneBrush;
    Status status = GdipCloneBrush(nativeBrush_, cloneBrush);
    if (status != Status.OK)
      throw statusException(status);
    return new SolidBrush(cloneBrush);
  }

  /**
   */
  void translateTransform(float dx, float dy, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipTranslateTextureTransform(nativeBrush_, dx, dy, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void rotateTransform(float angle, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipRotateTextureTransform(nativeBrush_, angle, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void scaleTransform(float sx, float sy, MatrixOrder order = MatrixOrder.Prepend) {
    Status status = GdipScaleTextureTransform(nativeBrush_, sx, sy, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void multiplyTransform(Matrix matrix, MatrixOrder order = MatrixOrder.Prepend) {
    if (matrix is null)
      throw new ArgumentNullException("matrix");

    Status status = GdipMultiplyTextureTransform(nativeBrush_, matrix.nativeMatrix_, order);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void resetTransform() {
    Status status = GdipResetTextureTransform(nativeBrush_);
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
  void rotateTransform(float angle, MatrixOrder order = MatrixOrder.Prepend) {
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

    return (value != 0);
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

}

/**
 */
final class PathGradientBrush : Brush {

  private this(Handle nativeBrush) {
    nativeBrush_ = nativeBrush;
  }

  /**
   */
  this(PointF[] points, WrapMode wrapMode = WrapMode.Clamp) {
    Status status = GdipCreatePathGradient(points.ptr, points.length, wrapMode, nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(Point[] points, WrapMode wrapMode = WrapMode.Clamp) {
    Status status = GdipCreatePathGradientI(points.ptr, points.length, wrapMode, nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(Path path) {
    if (path is null)
      throw new ArgumentNullException("path");

    Status status = GdipCreatePathGradientFromPath(path.nativePath_, nativeBrush_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  Object clone() {
    Handle cloneBrush;
    Status status = GdipCloneBrush(nativeBrush_, cloneBrush);
    if (status != Status.OK)
      throw statusException(status);
    return new PathGradientBrush(cloneBrush);
  }

}

/**
 */
final class Pen : IDisposable {

  private Handle nativePen_;
  private Color color_;

  /**
   */
  this(Color color, float width = 1f) {
    color_ = color;

    Status status = GdipCreatePen1(color.toArgb(), width, cast(GraphicsUnit)0, nativePen_);
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
    float value = 0f;

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
  PenType penType() {
    PenType type = cast(PenType)-1;

    Status status = GdipGetPenFillType(nativePen_, type);
    if (status != Status.OK)
      throw statusException(status);

    return type;
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

  /**
   */
  void color(Color value) {
    if (color_ != value) {
      color_ = value;

      Status status = GdipSetPenColor(nativePen_, color_.toArgb());
      if (status != Status.OK)
        throw statusException(status);
    }
  }
  /// ditto
  Color color() {
    if (color_ == Color.empty) {
      uint argb;

      Status status = GdipGetPenColor(nativePen_, argb);
      if (status != Status.OK)
        throw statusException(status);

      color_ = Color.fromArgb(argb);
    }
    return color_;
  }

  version(D_Version2) {
    private static Pen[KnownColor] pens_;
  }
  else {
    private static ThreadLocal!(Pen[KnownColor]) pens_;
  }

  static ~this() {
    pens_ = null;
  }

  private static Pen fromKnownColor(KnownColor c) {
    version(D_Version2) {
      Pen pen;
      if (auto value = c in pens_) {
        pen = *value;
      }
      else {
        pen = pens_[c] = new Pen(Color.fromKnownColor(c));
      }
      return pen;
    }
    else {
      if (pens_ is null)
        pens_ = new ThreadLocal!(Pen[KnownColor]);

      auto pens = pens_.get();

      Pen pen;
      if (auto value = c in pens) {
        pen = *value;
      }
      else {
        pen = pens[c] = new Pen(Color.fromKnownColor(c));
        pens_.set(pens);
      }
      return pen;
    }
  }

  /// Gets a system-defined Pen object.
  static Pen activeBorder() {
    return fromKnownColor(KnownColor.ActiveBorder);
  }

  /// ditto 
  static Pen activeCaption() {
    return fromKnownColor(KnownColor.ActiveCaption);
  }

  /// ditto 
  static Pen activeCaptionText() {
    return fromKnownColor(KnownColor.ActiveCaptionText);
  }

  /// ditto 
  static Pen appWorkspace() {
    return fromKnownColor(KnownColor.AppWorkspace);
  }

  /// ditto 
  static Pen control() {
    return fromKnownColor(KnownColor.Control);
  }

  /// ditto 
  static Pen controlDark() {
    return fromKnownColor(KnownColor.ControlDark);
  }

  /// ditto 
  static Pen controlDarkDark() {
    return fromKnownColor(KnownColor.ControlDarkDark);
  }

  /// ditto 
  static Pen controlLight() {
    return fromKnownColor(KnownColor.ControlLight);
  }

  /// ditto 
  static Pen controlLightLight() {
    return fromKnownColor(KnownColor.ControlLightLight);
  }

  /// ditto 
  static Pen controlText() {
    return fromKnownColor(KnownColor.ControlText);
  }

  /// ditto 
  static Pen desktop() {
    return fromKnownColor(KnownColor.Desktop);
  }

  /// ditto 
  static Pen grayText() {
    return fromKnownColor(KnownColor.GrayText);
  }

  /// ditto 
  static Pen highlight() {
    return fromKnownColor(KnownColor.Highlight);
  }

  /// ditto 
  static Pen highlightText() {
    return fromKnownColor(KnownColor.HighlightText);
  }

  /// ditto 
  static Pen hotTrack() {
    return fromKnownColor(KnownColor.HotTrack);
  }

  /// ditto 
  static Pen inactiveBorder() {
    return fromKnownColor(KnownColor.InactiveBorder);
  }

  /// ditto 
  static Pen inactiveCaption() {
    return fromKnownColor(KnownColor.InactiveCaption);
  }

  /// ditto 
  static Pen inactiveCaptionText() {
    return fromKnownColor(KnownColor.InactiveCaptionText);
  }

  /// ditto 
  static Pen info() {
    return fromKnownColor(KnownColor.Info);
  }

  /// ditto 
  static Pen infoText() {
    return fromKnownColor(KnownColor.InfoText);
  }

  /// ditto 
  static Pen menu() {
    return fromKnownColor(KnownColor.Menu);
  }

  /// ditto 
  static Pen menuText() {
    return fromKnownColor(KnownColor.MenuText);
  }

  /// ditto 
  static Pen scrollBar() {
    return fromKnownColor(KnownColor.ScrollBar);
  }

  /// ditto 
  static Pen window() {
    return fromKnownColor(KnownColor.Window);
  }

  /// ditto 
  static Pen windowFrame() {
    return fromKnownColor(KnownColor.WindowFrame);
  }

  /// ditto 
  static Pen windowText() {
    return fromKnownColor(KnownColor.WindowText);
  }

  /// ditto 
  static Pen transparent() {
    return fromKnownColor(KnownColor.Transparent);
  }

  /// ditto 
  static Pen aliceBlue() {
    return fromKnownColor(KnownColor.AliceBlue);
  }

  /// ditto 
  static Pen antiqueWhite() {
    return fromKnownColor(KnownColor.AntiqueWhite);
  }

  /// ditto 
  static Pen aqua() {
    return fromKnownColor(KnownColor.Aqua);
  }

  /// ditto 
  static Pen aquamarine() {
    return fromKnownColor(KnownColor.Aquamarine);
  }

  /// ditto 
  static Pen azure() {
    return fromKnownColor(KnownColor.Azure);
  }

  /// ditto 
  static Pen beige() {
    return fromKnownColor(KnownColor.Beige);
  }

  /// ditto 
  static Pen bisque() {
    return fromKnownColor(KnownColor.Bisque);
  }

  /// ditto 
  static Pen black() {
    return fromKnownColor(KnownColor.Black);
  }

  /// ditto 
  static Pen blanchedAlmond() {
    return fromKnownColor(KnownColor.BlanchedAlmond);
  }

  /// ditto 
  static Pen blue() {
    return fromKnownColor(KnownColor.Blue);
  }

  /// ditto 
  static Pen blueViolet() {
    return fromKnownColor(KnownColor.BlueViolet);
  }

  /// ditto 
  static Pen brown() {
    return fromKnownColor(KnownColor.Brown);
  }

  /// ditto 
  static Pen burlyWood() {
    return fromKnownColor(KnownColor.BurlyWood);
  }

  /// ditto 
  static Pen cadetBlue() {
    return fromKnownColor(KnownColor.CadetBlue);
  }

  /// ditto 
  static Pen chartreuse() {
    return fromKnownColor(KnownColor.Chartreuse);
  }

  /// ditto 
  static Pen chocolate() {
    return fromKnownColor(KnownColor.Chocolate);
  }

  /// ditto 
  static Pen coral() {
    return fromKnownColor(KnownColor.Coral);
  }

  /// ditto 
  static Pen cornflowerBlue() {
    return fromKnownColor(KnownColor.CornflowerBlue);
  }

  /// ditto 
  static Pen cornsilk() {
    return fromKnownColor(KnownColor.Cornsilk);
  }

  /// ditto 
  static Pen crimson() {
    return fromKnownColor(KnownColor.Crimson);
  }

  /// ditto 
  static Pen cyan() {
    return fromKnownColor(KnownColor.Cyan);
  }

  /// ditto 
  static Pen darkBlue() {
    return fromKnownColor(KnownColor.DarkBlue);
  }

  /// ditto 
  static Pen darkCyan() {
    return fromKnownColor(KnownColor.DarkCyan);
  }

  /// ditto 
  static Pen darkGoldenrod() {
    return fromKnownColor(KnownColor.DarkGoldenrod);
  }

  /// ditto 
  static Pen darkGray() {
    return fromKnownColor(KnownColor.DarkGray);
  }

  /// ditto 
  static Pen darkGreen() {
    return fromKnownColor(KnownColor.DarkGreen);
  }

  /// ditto 
  static Pen darkKhaki() {
    return fromKnownColor(KnownColor.DarkKhaki);
  }

  /// ditto 
  static Pen darkMagenta() {
    return fromKnownColor(KnownColor.DarkMagenta);
  }

  /// ditto 
  static Pen darkOliveGreen() {
    return fromKnownColor(KnownColor.DarkOliveGreen);
  }

  /// ditto 
  static Pen darkOrange() {
    return fromKnownColor(KnownColor.DarkOrange);
  }

  /// ditto 
  static Pen darkOrchid() {
    return fromKnownColor(KnownColor.DarkOrchid);
  }

  /// ditto 
  static Pen darkRed() {
    return fromKnownColor(KnownColor.DarkRed);
  }

  /// ditto 
  static Pen darkSalmon() {
    return fromKnownColor(KnownColor.DarkSalmon);
  }

  /// ditto 
  static Pen darkSeaGreen() {
    return fromKnownColor(KnownColor.DarkSeaGreen);
  }

  /// ditto 
  static Pen darkSlateBlue() {
    return fromKnownColor(KnownColor.DarkSlateBlue);
  }

  /// ditto 
  static Pen darkSlateGray() {
    return fromKnownColor(KnownColor.DarkSlateGray);
  }

  /// ditto 
  static Pen darkTurquoise() {
    return fromKnownColor(KnownColor.DarkTurquoise);
  }

  /// ditto 
  static Pen darkViolet() {
    return fromKnownColor(KnownColor.DarkViolet);
  }

  /// ditto 
  static Pen deepPink() {
    return fromKnownColor(KnownColor.DeepPink);
  }

  /// ditto 
  static Pen deepSkyBlue() {
    return fromKnownColor(KnownColor.DeepSkyBlue);
  }

  /// ditto 
  static Pen dimGray() {
    return fromKnownColor(KnownColor.DimGray);
  }

  /// ditto 
  static Pen dodgerBlue() {
    return fromKnownColor(KnownColor.DodgerBlue);
  }

  /// ditto 
  static Pen firebrick() {
    return fromKnownColor(KnownColor.Firebrick);
  }

  /// ditto 
  static Pen floralWhite() {
    return fromKnownColor(KnownColor.FloralWhite);
  }

  /// ditto 
  static Pen forestGreen() {
    return fromKnownColor(KnownColor.ForestGreen);
  }

  /// ditto 
  static Pen fuchsia() {
    return fromKnownColor(KnownColor.Fuchsia);
  }

  /// ditto 
  static Pen gainsboro() {
    return fromKnownColor(KnownColor.Gainsboro);
  }

  /// ditto 
  static Pen ghostWhite() {
    return fromKnownColor(KnownColor.GhostWhite);
  }

  /// ditto 
  static Pen gold() {
    return fromKnownColor(KnownColor.Gold);
  }

  /// ditto 
  static Pen goldenrod() {
    return fromKnownColor(KnownColor.Goldenrod);
  }

  /// ditto 
  static Pen gray() {
    return fromKnownColor(KnownColor.Gray);
  }

  /// ditto 
  static Pen green() {
    return fromKnownColor(KnownColor.Green);
  }

  /// ditto 
  static Pen greenYellow() {
    return fromKnownColor(KnownColor.GreenYellow);
  }

  /// ditto 
  static Pen honeydew() {
    return fromKnownColor(KnownColor.Honeydew);
  }

  /// ditto 
  static Pen hotPink() {
    return fromKnownColor(KnownColor.HotPink);
  }

  /// ditto 
  static Pen indianRed() {
    return fromKnownColor(KnownColor.IndianRed);
  }

  /// ditto 
  static Pen indigo() {
    return fromKnownColor(KnownColor.Indigo);
  }

  /// ditto 
  static Pen ivory() {
    return fromKnownColor(KnownColor.Ivory);
  }

  /// ditto 
  static Pen khaki() {
    return fromKnownColor(KnownColor.Khaki);
  }

  /// ditto 
  static Pen lavender() {
    return fromKnownColor(KnownColor.Lavender);
  }

  /// ditto 
  static Pen lavenderBlush() {
    return fromKnownColor(KnownColor.LavenderBlush);
  }

  /// ditto 
  static Pen lawnGreen() {
    return fromKnownColor(KnownColor.LawnGreen);
  }

  /// ditto 
  static Pen lemonChiffon() {
    return fromKnownColor(KnownColor.LemonChiffon);
  }

  /// ditto 
  static Pen lightBlue() {
    return fromKnownColor(KnownColor.LightBlue);
  }

  /// ditto 
  static Pen lightCoral() {
    return fromKnownColor(KnownColor.LightCoral);
  }

  /// ditto 
  static Pen lightCyan() {
    return fromKnownColor(KnownColor.LightCyan);
  }

  /// ditto 
  static Pen lightGoldenrodYellow() {
    return fromKnownColor(KnownColor.LightGoldenrodYellow);
  }

  /// ditto 
  static Pen lightGray() {
    return fromKnownColor(KnownColor.LightGray);
  }

  /// ditto 
  static Pen lightGreen() {
    return fromKnownColor(KnownColor.LightGreen);
  }

  /// ditto 
  static Pen lightPink() {
    return fromKnownColor(KnownColor.LightPink);
  }

  /// ditto 
  static Pen lightSalmon() {
    return fromKnownColor(KnownColor.LightSalmon);
  }

  /// ditto 
  static Pen lightSeaGreen() {
    return fromKnownColor(KnownColor.LightSeaGreen);
  }

  /// ditto 
  static Pen lightSkyBlue() {
    return fromKnownColor(KnownColor.LightSkyBlue);
  }

  /// ditto 
  static Pen lightSlateGray() {
    return fromKnownColor(KnownColor.LightSlateGray);
  }

  /// ditto 
  static Pen lightSteelBlue() {
    return fromKnownColor(KnownColor.LightSteelBlue);
  }

  /// ditto 
  static Pen lightYellow() {
    return fromKnownColor(KnownColor.LightYellow);
  }

  /// ditto 
  static Pen lime() {
    return fromKnownColor(KnownColor.Lime);
  }

  /// ditto 
  static Pen limeGreen() {
    return fromKnownColor(KnownColor.LimeGreen);
  }

  /// ditto 
  static Pen linen() {
    return fromKnownColor(KnownColor.Linen);
  }

  /// ditto 
  static Pen magenta() {
    return fromKnownColor(KnownColor.Magenta);
  }

  /// ditto 
  static Pen maroon() {
    return fromKnownColor(KnownColor.Maroon);
  }

  /// ditto 
  static Pen mediumAquamarine() {
    return fromKnownColor(KnownColor.MediumAquamarine);
  }

  /// ditto 
  static Pen mediumBlue() {
    return fromKnownColor(KnownColor.MediumBlue);
  }

  /// ditto 
  static Pen mediumOrchid() {
    return fromKnownColor(KnownColor.MediumOrchid);
  }

  /// ditto 
  static Pen mediumPurple() {
    return fromKnownColor(KnownColor.MediumPurple);
  }

  /// ditto 
  static Pen mediumSeaGreen() {
    return fromKnownColor(KnownColor.MediumSeaGreen);
  }

  /// ditto 
  static Pen mediumSlateBlue() {
    return fromKnownColor(KnownColor.MediumSlateBlue);
  }

  /// ditto 
  static Pen mediumSpringGreen() {
    return fromKnownColor(KnownColor.MediumSpringGreen);
  }

  /// ditto 
  static Pen mediumTurquoise() {
    return fromKnownColor(KnownColor.MediumTurquoise);
  }

  /// ditto 
  static Pen mediumVioletRed() {
    return fromKnownColor(KnownColor.MediumVioletRed);
  }

  /// ditto 
  static Pen midnightBlue() {
    return fromKnownColor(KnownColor.MidnightBlue);
  }

  /// ditto 
  static Pen mintCream() {
    return fromKnownColor(KnownColor.MintCream);
  }

  /// ditto 
  static Pen mistyRose() {
    return fromKnownColor(KnownColor.MistyRose);
  }

  /// ditto 
  static Pen moccasin() {
    return fromKnownColor(KnownColor.Moccasin);
  }

  /// ditto 
  static Pen navajoWhite() {
    return fromKnownColor(KnownColor.NavajoWhite);
  }

  /// ditto 
  static Pen navy() {
    return fromKnownColor(KnownColor.Navy);
  }

  /// ditto 
  static Pen oldLace() {
    return fromKnownColor(KnownColor.OldLace);
  }

  /// ditto 
  static Pen olive() {
    return fromKnownColor(KnownColor.Olive);
  }

  /// ditto 
  static Pen oliveDrab() {
    return fromKnownColor(KnownColor.OliveDrab);
  }

  /// ditto 
  static Pen orange() {
    return fromKnownColor(KnownColor.Orange);
  }

  /// ditto 
  static Pen orangeRed() {
    return fromKnownColor(KnownColor.OrangeRed);
  }

  /// ditto 
  static Pen orchid() {
    return fromKnownColor(KnownColor.Orchid);
  }

  /// ditto 
  static Pen paleGoldenrod() {
    return fromKnownColor(KnownColor.PaleGoldenrod);
  }

  /// ditto 
  static Pen paleGreen() {
    return fromKnownColor(KnownColor.PaleGreen);
  }

  /// ditto 
  static Pen paleTurquoise() {
    return fromKnownColor(KnownColor.PaleTurquoise);
  }

  /// ditto 
  static Pen paleVioletRed() {
    return fromKnownColor(KnownColor.PaleVioletRed);
  }

  /// ditto 
  static Pen papayaWhip() {
    return fromKnownColor(KnownColor.PapayaWhip);
  }

  /// ditto 
  static Pen peachPuff() {
    return fromKnownColor(KnownColor.PeachPuff);
  }

  /// ditto 
  static Pen peru() {
    return fromKnownColor(KnownColor.Peru);
  }

  /// ditto 
  static Pen pink() {
    return fromKnownColor(KnownColor.Pink);
  }

  /// ditto 
  static Pen plum() {
    return fromKnownColor(KnownColor.Plum);
  }

  /// ditto 
  static Pen powderBlue() {
    return fromKnownColor(KnownColor.PowderBlue);
  }

  /// ditto 
  static Pen purple() {
    return fromKnownColor(KnownColor.Purple);
  }

  /// ditto 
  static Pen red() {
    return fromKnownColor(KnownColor.Red);
  }

  /// ditto 
  static Pen rosyBrown() {
    return fromKnownColor(KnownColor.RosyBrown);
  }

  /// ditto 
  static Pen royalBlue() {
    return fromKnownColor(KnownColor.RoyalBlue);
  }

  /// ditto 
  static Pen saddleBrown() {
    return fromKnownColor(KnownColor.SaddleBrown);
  }

  /// ditto 
  static Pen salmon() {
    return fromKnownColor(KnownColor.Salmon);
  }

  /// ditto 
  static Pen sandyBrown() {
    return fromKnownColor(KnownColor.SandyBrown);
  }

  /// ditto 
  static Pen seaGreen() {
    return fromKnownColor(KnownColor.SeaGreen);
  }

  /// ditto 
  static Pen seaShell() {
    return fromKnownColor(KnownColor.SeaShell);
  }

  /// ditto 
  static Pen sienna() {
    return fromKnownColor(KnownColor.Sienna);
  }

  /// ditto 
  static Pen silver() {
    return fromKnownColor(KnownColor.Silver);
  }

  /// ditto 
  static Pen skyBlue() {
    return fromKnownColor(KnownColor.SkyBlue);
  }

  /// ditto 
  static Pen slateBlue() {
    return fromKnownColor(KnownColor.SlateBlue);
  }

  /// ditto 
  static Pen slateGray() {
    return fromKnownColor(KnownColor.SlateGray);
  }

  /// ditto 
  static Pen snow() {
    return fromKnownColor(KnownColor.Snow);
  }

  /// ditto 
  static Pen springGreen() {
    return fromKnownColor(KnownColor.SpringGreen);
  }

  /// ditto 
  static Pen steelBlue() {
    return fromKnownColor(KnownColor.SteelBlue);
  }

  /// ditto 
  static Pen tan() {
    return fromKnownColor(KnownColor.Tan);
  }

  /// ditto 
  static Pen teal() {
    return fromKnownColor(KnownColor.Teal);
  }

  /// ditto 
  static Pen thistle() {
    return fromKnownColor(KnownColor.Thistle);
  }

  /// ditto 
  static Pen tomato() {
    return fromKnownColor(KnownColor.Tomato);
  }

  /// ditto 
  static Pen turquoise() {
    return fromKnownColor(KnownColor.Turquoise);
  }

  /// ditto 
  static Pen violet() {
    return fromKnownColor(KnownColor.Violet);
  }

  /// ditto 
  static Pen wheat() {
    return fromKnownColor(KnownColor.Wheat);
  }

  /// ditto 
  static Pen white() {
    return fromKnownColor(KnownColor.White);
  }

  /// ditto 
  static Pen whiteSmoke() {
    return fromKnownColor(KnownColor.WhiteSmoke);
  }

  /// ditto 
  static Pen yellow() {
    return fromKnownColor(KnownColor.Yellow);
  }

  /// ditto 
  static Pen yellowGreen() {
    return fromKnownColor(KnownColor.YellowGreen);
  }

  /// ditto 
  static Pen buttonFace() {
    return fromKnownColor(KnownColor.ButtonFace);
  }

  /// ditto 
  static Pen buttonHighlight() {
    return fromKnownColor(KnownColor.ButtonHighlight);
  }

  /// ditto 
  static Pen buttonShadow() {
    return fromKnownColor(KnownColor.ButtonShadow);
  }

  /// ditto 
  static Pen gradientActiveCaption() {
    return fromKnownColor(KnownColor.GradientActiveCaption);
  }

  /// ditto 
  static Pen gradientInactiveCaption() {
    return fromKnownColor(KnownColor.GradientInactiveCaption);
  }

  /// ditto 
  static Pen menuBar() {
    return fromKnownColor(KnownColor.MenuBar);
  }

  /// ditto 
  static Pen menuHighlight() {
    return fromKnownColor(KnownColor.MenuHighlight);
  }

}

/**
 */
final class ImageAttributes {

  private Handle nativeImageAttributes_;

  /**
   */
  this() {
    Status status = GdipCreateImageAttributes(nativeImageAttributes_);
    if (status != Status.OK)
      throw statusException(status);
  }

  ~this() {
    dispose();
  }
  
  /**
   */
  void dispose() {
    if (nativeImageAttributes_ != Handle.init) {
      GdipDisposeImageAttributesSafe(nativeImageAttributes_);
      nativeImageAttributes_ = Handle.init;
    }
  }

  /**
   */
  void setColorKey(Color colorLow, Color colorHigh, ColorAdjustType type = ColorAdjustType.Default) {
    Status status = GdipSetImageAttributesColorKeys(nativeImageAttributes_, type, 1, colorLow.toArgb(), colorHigh.toArgb());
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void clearColorKey(ColorAdjustType type = ColorAdjustType.Default) {
    Status status = GdipSetImageAttributesColorKeys(nativeImageAttributes_, type, 0, 0, 0);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void setColorMatrix(ColorMatrix newColorMatrix, ColorMatrixFlag mode = ColorMatrixFlag.Default, ColorAdjustType type = ColorAdjustType.Default) {
    GpColorMatrix m;
    for (int j = 0; j < 5; j++) {
      for (int i = 0; i < 5; i++)
        m.m[j][i] = newColorMatrix[j, i];
    }

    Status status = GdipSetImageAttributesColorMatrix(nativeImageAttributes_, type, 1, &m, null, mode);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void clearColorMatrix(ColorAdjustType type = ColorAdjustType.Default) {
    Status status = GdipSetImageAttributesColorMatrix(nativeImageAttributes_, type, 0, null, null, ColorMatrixFlag.Default);
    if (status != Status.OK)
      throw statusException(status);
  }

  package @property Handle nativeImageAttributes() {
    return nativeImageAttributes_;
  }

}

/**
 */
abstract class Image : IDisposable {

  alias bool delegate(void* callbackData) GetThumbnailImageAbort;

  private Handle nativeImage_;

  private this() {
  }

  private this(Handle nativeImage) {
    nativeImage_ = nativeImage;
  }

  ~this() {
    dispose(false);
  }

  final void dispose() {
    dispose(true);
  }

  /**
   */
  protected void dispose(bool disposing) {
    if (nativeImage_ != Handle.init) {
      GdipDisposeImageSafe(nativeImage_);
      nativeImage_ = Handle.init;
    }
  }

  /**
   */
  final Object clone() {
    Handle cloneImage;

    Status status = GdipCloneImage(nativeImage_, cloneImage);
    if (status != Status.OK)
      throw statusException(status);

    return createImage(cloneImage);
  }

  /**
   */
  static Image fromFile(string fileName, bool useEmbeddedColorManagement = false) {
    if (!std.file.exists(fileName))
      throw new FileNotFoundException(fileName);

    fileName = juno.io.path.getFullPath(fileName);

    Handle nativeImage;

    Status status = useEmbeddedColorManagement 
      ? GdipLoadImageFromFileICM(fileName.toUtf16z(), nativeImage)
      : GdipLoadImageFromFile(fileName.toUtf16z(), nativeImage);
    if (status != Status.OK)
      throw statusException(status);

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

    return createImage(nativeImage);
  }

  /**
   */
  private static Image createImage(Handle nativeImage) {
    ImageType type;

    Status status = GdipGetImageType(nativeImage, type);
    if (status != Status.OK)
      throw statusException(status);

    Image image;
    switch (type) {
      case ImageType.Bitmap:
        image = new Bitmap(nativeImage);
        break;
      case ImageType.Metafile:
        image = new Metafile(nativeImage);
        break;
      default:
        throw new ArgumentException("nativeImage");
    }
    return image;
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

    Guid g = encoder.clsid;
    Status status = GdipSaveImageToFile(nativeImage_, fileName.toUtf16z(), g, pParams);

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

    Guid g = encoder.clsid;
    Status status = GdipSaveImageToStream(nativeImage_, s, g, pParams);

    if (pParams !is null)
      LocalFree(cast(Handle)pParams);

    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  final Image getThumbnailImage(int thumbWidth, int thumbHeight, GetThumbnailImageAbort callback, void* callbackData) {
    static GetThumbnailImageAbort callbackDelegate;

    extern(Windows) static int getThumbnailImageAbortCallback(void* callbackData) {
      return callbackDelegate(callbackData) ? 1 : 0;
    }

    callbackDelegate = callback;

    Handle thumbImage;
    Status status = GdipGetImageThumbnail(nativeImage_, thumbWidth, thumbHeight, thumbImage, (callback is null) ? null : &getThumbnailImageAbortCallback, callbackData);
    if (status != Status.OK)
      throw statusException(status);

    return createImage(thumbImage);
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
  final void rotateFlip(RotateFlipType rotateFlipType) {
    Status status = GdipImageRotateFlip(nativeImage_, rotateFlipType);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  final @property SizeF physicalDimension() {
    float width, height;
    Status status = GdipGetImageDimension(nativeImage_, width, height);
    if (status != Status.OK)
      throw statusException(status);
    return SizeF(width, height);
  }

  /**
   */
  final @property int width() {
    int value;
    Status status = GdipGetImageWidth(nativeImage_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  final @property int height() {
    int value;
    Status status = GdipGetImageHeight(nativeImage_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  final @property Size size() {
    return Size(width, height);
  }

  /**
   */
  final @property float horizontalResolution() {
    float resolution;
    Status status = GdipGetImageHorizontalResolution(nativeImage_, resolution);
    if (status != Status.OK)
      throw statusException(status);
    return resolution;
  }

  /**
   */
  final @property float verticalResolution() {
    float resolution;
    Status status = GdipGetImageVerticalResolution(nativeImage_, resolution);
    if (status != Status.OK)
      throw statusException(status);
    return resolution;
  }

  /**
   */
  final @property ImageFormat rawFormat() {
    Guid format;
    Status status = GdipGetImageRawFormat(nativeImage_, format);
    if (status != Status.OK)
      throw statusException(status);
    return new ImageFormat(format);
  }

  /**
   */
  final @property PixelFormat pixelFormat() {
    PixelFormat value;
    Status status = GdipGetImagePixelFormat(nativeImage_, value);
    if (status != Status.OK)
      return PixelFormat.Undefined;
    return value;
  }

  /**
   */
  final @property Guid[] frameDimensionsList() {
    uint count;
    Status status = GdipImageGetFrameDimensionsCount(nativeImage_, count);
    if (status != Status.OK)
      throw statusException(status);

    if (count == 0)
      return new Guid[0];

    Guid[] dimensionIDs = new Guid[count];

    status = GdipImageGetFrameDimensionsList(nativeImage_, dimensionIDs.ptr, count);
    if (status != Status.OK)
      throw statusException(status);

    return dimensionIDs;
  }

  /**
   */
  final uint getFrameCount(FrameDimension dimension) {
    uint count;
    Guid dimensionId = dimension.guid;
    Status status = GdipImageGetFrameCount(nativeImage_, dimensionId, count);
    if (status != Status.OK)
      throw statusException(status);

    return count;
  }

  /**
   */
  final void selectActiveFrame(FrameDimension dimension, uint frameIndex) {
    Guid dimensionId = dimension.guid;
    Status status = GdipImageSelectActiveFrame(nativeImage_, dimensionId, frameIndex);
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
    if (buffer is null)
      throw statusException(Status.OutOfMemory);

    scope(exit) LocalFree(buffer);

    status = GdipGetPropertyItem(nativeImage_, propId, size, buffer);
    if (status != Status.OK)
      throw statusException(status);

    auto item = new PropertyItem;
    item.id = buffer.id;
    item.len = buffer.len;
    item.type = buffer.type;
    item.value = cast(ubyte[])buffer.value[0 .. buffer.len];
    return item;
  }

}

/**
 */
final class Bitmap : Image {

  private this() {
  }

  private this(Handle nativeImage) {
    nativeImage_ = nativeImage;
  }

  /**
   */
  this(string fileName, bool useEmbeddedColorManagement = false) {
    //fileName = juno.io.path.getFullPath(fileName);

    Status status = useEmbeddedColorManagement
      ? GdipCreateBitmapFromFileICM(fileName.toUtf16z(), nativeImage_)
      : GdipCreateBitmapFromFile(fileName.toUtf16z(), nativeImage_);
    if (status != Status.OK)
      throw statusException(status);
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
    Status status = GdipCreateBitmapFromResource(hinstance, bitmapName.toUtf16z(), nativeImage);
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
  Handle getHbitmap(Color background = Color.lightGray) {
    Handle hbitmap;
    Status status = GdipCreateHBITMAPFromBitmap(nativeImage_, hbitmap, background.toRgb());
    if (status != Status.OK)
      throw statusException(status);
    return hbitmap;
  }

  /**
   */
  Handle getHicon() {
    Handle hicon;
    Status status = GdipCreateHICONFromBitmap(nativeImage_, hicon);
    if (status != Status.OK)
      throw statusException(status);
    return hicon;
  }

  /**
   */
  BitmapData lockBits(Rect rect, ImageLockMode flags, PixelFormat format, BitmapData bitmapData = null) {
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
  void unlockBits(BitmapData bitmapData) {
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
  Color getPixel(int x, int y) {
    int color;
    Status status = GdipBitmapGetPixel(nativeImage_, x, y, color);
    if (status != Status.OK)
      throw statusException(status);
    return Color.fromArgb(color);
  }

  /**
   */
  void setPixel(int x, int y, Color color) {
    Status status = GdipBitmapSetPixel(nativeImage_, x, y, color.toArgb());
    if (status != Status.OK)
      throw statusException(status);
  }
  
  /**
   */
  void setResolution(float xdpi, float ydpi) {
    Status status = GdipBitmapSetResolution(nativeImage_, xdpi, ydpi);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void makeTransparent() {
    Color transparentColor = Color.lightGray;
    if (width > 0 && height > 0)
      transparentColor = getPixel(0, height - 1);
    if (transparentColor.a >= 255)
      makeTransparent(transparentColor);
  }

  /**
   */
  void makeTransparent(Color transparentColor) {
    Size size = this.size;

    scope bmp = new Bitmap(size.width, size.height, PixelFormat.Format32bppArgb);
    scope g = Graphics.fromImage(bmp);
    g.clear(Color.transparent);

    scope attrs = new ImageAttributes;
    attrs.setColorKey(transparentColor, transparentColor);
    g.drawImage(this, Rect(0, 0, size.width, size.height), 0, 0, size.width, size.height, GraphicsUnit.Pixel, attrs);

    Handle temp = nativeImage_;
    nativeImage_ = bmp.nativeImage_;
    bmp.nativeImage_ = temp;
  }

}

/**
 */
final class WmfPlaceableFileHeader {
  uint key;
  short hmf;
  short boundingBoxLeft;
  short boundingBoxTop;
  short boundingBoxRight;
  short boundingBoxBottom;
  short inch;
  uint reserved;
  short checksum;
}

/**
 */
final class Metafile : Image {

  private this() {
  }

  private this(Handle nativeImage) {
    nativeImage_ = nativeImage;
  }

  /**
   */
  this(Handle hmetafile, WmfPlaceableFileHeader wmfHeader, bool deleteEmf = false) {
    GdipWmfPlaceableFileHeader gpheader;
    with (gpheader) {
      with (wmfHeader) {
        Key = key;
        Hmf = hmf;
        BoundingBoxLeft = boundingBoxLeft;
        BoundingBoxTop = boundingBoxTop;
        BoundingBoxRight = boundingBoxRight;
        BoundingBoxBottom = boundingBoxBottom;
        Inch = inch;
        Reserved = reserved;
        Checksum = checksum;
      }
    }

    Status status = GdipCreateMetafileFromWmf(hmetafile, deleteEmf ? 1 : 0, gpheader, nativeImage_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(Handle henhmetafile, bool deleteEmf) {
    Status status = GdipCreateMetafileFromEmf(henhmetafile, deleteEmf ? 1 : 0, nativeImage_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(string fileName) {
    if (!std.file.exists(fileName))
      throw new FileNotFoundException(fileName);

    Status status = GdipCreateMetafileFromFile(fileName.toUtf16z(), nativeImage_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(string fileName, WmfPlaceableFileHeader wmfHeader) {
    GdipWmfPlaceableFileHeader gpheader;
    with (gpheader) {
      with (wmfHeader) {
        Key = key;
        Hmf = hmf;
        BoundingBoxLeft = boundingBoxLeft;
        BoundingBoxTop = boundingBoxTop;
        BoundingBoxRight = boundingBoxRight;
        BoundingBoxBottom = boundingBoxBottom;
        Inch = inch;
        Reserved = reserved;
        Checksum = checksum;
      }
    }

    Status status = GdipCreateMetafileFromWmfFile(fileName.toUtf16z(), gpheader, nativeImage_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(Stream stream) {
    if (stream is null)
      throw new ArgumentNullException("stream");

    auto s = new COMStream(stream);
    scope(exit) tryRelease(s);

    Status status = GdipCreateMetafileFromStream(s, nativeImage_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(Handle referenceHdc, EmfType emfType, string description = null) {
    Status status = GdipRecordMetafile(referenceHdc, emfType, null, MetafileFrameUnit.GdiCompatible, description.toUtf16z(), nativeImage_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(Handle referenceHdc, RectF frameRect, MetafileFrameUnit frameUnit = MetafileFrameUnit.GdiCompatible, EmfType emfType = EmfType.EmfPlusDual, string description = null) {
    Status status = GdipRecordMetafile(referenceHdc, emfType, &frameRect, frameUnit, description.toUtf16z(), nativeImage_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(Handle referenceHdc, Rect frameRect, MetafileFrameUnit frameUnit = MetafileFrameUnit.GdiCompatible, EmfType emfType = EmfType.EmfPlusDual, string description = null) {
    Status status = GdipRecordMetafileI(referenceHdc, emfType, &frameRect, frameUnit, description.toUtf16z(), nativeImage_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(string fileName, Handle referenceHdc, EmfType emfType = EmfType.EmfPlusDual, string description = null) {
    Status status = GdipRecordMetafileFileName(fileName.toUtf16z(), referenceHdc, emfType, null, MetafileFrameUnit.GdiCompatible, description.toUtf16z(), nativeImage_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(string fileName, Handle referenceHdc, RectF frameRect, MetafileFrameUnit frameUnit = MetafileFrameUnit.GdiCompatible, EmfType emfType = EmfType.EmfPlusDual, string description = null) {
    Status status = GdipRecordMetafileFileName(fileName.toUtf16z(), referenceHdc, emfType, &frameRect, frameUnit, description.toUtf16z(), nativeImage_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(string fileName, Handle referenceHdc, Rect frameRect, MetafileFrameUnit frameUnit = MetafileFrameUnit.GdiCompatible, EmfType emfType = EmfType.EmfPlusDual, string description = null) {
    Status status = GdipRecordMetafileFileNameI(fileName.toUtf16z(), referenceHdc, emfType, &frameRect, frameUnit, description.toUtf16z(), nativeImage_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(Stream stream, Handle referenceHdc, EmfType emfType = EmfType.EmfPlusDual, string description = null) {
    auto s = new COMStream(stream);
    scope(exit) tryRelease(s);

    Status status = GdipRecordMetafileStream(s, referenceHdc, emfType, null, MetafileFrameUnit.GdiCompatible, description.toUtf16z(), nativeImage_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  this(Stream stream, Handle referenceHdc, RectF frameRect, MetafileFrameUnit frameUnit = MetafileFrameUnit.GdiCompatible, EmfType emfType = EmfType.EmfPlusDual, string description = null) {
    auto s = new COMStream(stream);
    scope(exit) tryRelease(s);

    Status status = GdipRecordMetafileStream(s, referenceHdc, emfType, &frameRect, frameUnit, description.toUtf16z(), nativeImage_);
    if (status != Status.OK)
      throw statusException(status);
  }

  this(Stream stream, Handle referenceHdc, Rect frameRect, MetafileFrameUnit frameUnit = MetafileFrameUnit.GdiCompatible, EmfType emfType = EmfType.EmfPlusDual, string description = null) {
    auto s = new COMStream(stream);
    scope(exit) tryRelease(s);

    Status status = GdipRecordMetafileStreamI(s, referenceHdc, emfType, &frameRect, frameUnit, description.toUtf16z(), nativeImage_);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  Handle getHenhmetafile() {
    Handle hemf;
    Status status = GdipGetHemfFromMetafile(nativeImage_, hemf);
    if (status != Status.OK)
      throw statusException(status);
    return hemf;
  }

  /*void playRecord(EmfPlusRecordType recordType, uint flags, uint dataSize, ubyte[] data) {
    Status status = GdipPlayMetafileRecord(nativeImage_, recordType, flags, dataSize, data.ptr);
    if (status != Status.OK)
      throw statusException(status);
  }*/

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
    Status status = GdipAddPathString(nativePath_, s.toUtf16z(), s.length, (family is null ? Handle.init : family.nativeFamily_), style, emSize, layoutRect, (format is null ? Handle.init : format.nativeFormat_));
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addString(string s, FontFamily family, FontStyle style, float emSize, RectF layoutRect, StringFormat format) {
    Status status = GdipAddPathString(nativePath_, s.toUtf16z(), s.length, (family is null ? Handle.init : family.nativeFamily_), style, emSize, layoutRect, (format is null ? Handle.init : format.nativeFormat_));
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addString(string s, FontFamily family, FontStyle style, float emSize, Point origin, StringFormat format) {
    Rect layoutRect = Rect(origin.x, origin.y, 0, 0);
    Status status = GdipAddPathStringI(nativePath_, s.toUtf16z(), s.length, (family is null ? Handle.init : family.nativeFamily_), style, emSize, layoutRect, (format is null ? Handle.init : format.nativeFormat_));
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addString(string s, FontFamily family, FontStyle style, float emSize, Rect layoutRect, StringFormat format) {
    Status status = GdipAddPathStringI(nativePath_, s.toUtf16z(), s.length, (family is null ? Handle.init : family.nativeFamily_), style, emSize, layoutRect, (format is null ? Handle.init : format.nativeFormat_));
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void transform(Matrix matrix) {
    if (matrix is null)
      throw new ArgumentNullException("matrix");

    if (matrix.nativeMatrix_ != Handle.init) {
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
  @property void fillMode(FillMode value) {
    Status status = GdipSetPathFillMode(nativePath_, value);
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   * ditto
   */
  @property FillMode fillMode() {
    FillMode value;
    Status status = GdipGetPathFillMode(nativePath_, value);
    if (status != Status.OK)
      throw statusException(status);
    return value;
  }

  /**
   */
  @property int pointCount() {
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
    Status status = GdipGetRegionScansCount(nativeRegion_, count, matrix.nativeMatrix_);
    if (status != Status.OK)
      throw statusException(status);

    RectF[] rects = new RectF[count];

    status = GdipGetRegionScans(nativeRegion_, rects.ptr, count, matrix.nativeMatrix_);
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
abstract class FontCollection : IDisposable {

  private Handle nativeFontCollection_;

  private this() {
  }

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
  protected void dispose(bool disposing) {
  }

  /**
   */
  final FontFamily[] families() {
    int numSought;
    Status status = GdipGetFontCollectionFamilyCount(nativeFontCollection_, numSought);
    if (status != Status.OK)
      throw statusException(status);

    auto gpfamilies = new Handle[numSought];

    int numFound;
    status = GdipGetFontCollectionFamilyList(nativeFontCollection_, numSought, gpfamilies.ptr, numFound);
    if (status != Status.OK)
      throw statusException(status);

    auto families = new FontFamily[numFound];
    for (auto i = 0; i < numFound; i++) {
      Handle family;
      GdipCloneFontFamily(gpfamilies[i], family);
      families[i] = new FontFamily(family);
    }

    return families;
  }

}

/**
 */
final class InstalledFontCollection : FontCollection {

  this() {
    Status status = GdipNewInstalledFontCollection(nativeFontCollection_);
    if (status != Status.OK)
      throw statusException(status);
  }

}

/**
 */
final class PrivateFontCollection : FontCollection {

  this() {
    Status status = GdipNewPrivateFontCollection(nativeFontCollection_);
    if (status != Status.OK)
      throw statusException(status);
  }

  alias FontCollection.dispose dispose;
  protected override void dispose(bool disposing) {
    if (nativeFontCollection_ != Handle.init) {
      GdipDeletePrivateFontCollectionSafe(nativeFontCollection_);
      nativeFontCollection_ = Handle.init;
    }
    super.dispose(disposing);
  }

  /**
   */
  void addFontFile(string fileName) {
    Status status = GdipPrivateAddFontFile(nativeFontCollection_, fileName.toUtf16z());
    if (status != Status.OK)
      throw statusException(status);
  }

  /**
   */
  void addMemoryFont(Handle memory, int length) {
    Status status = GdipPrivateAddMemoryFont(nativeFontCollection_, memory, length);
    if (status != Status.OK)
      throw statusException(status);
  }

}

/**
 */
final class FontFamily : IDisposable {

  private Handle nativeFamily_;
  private bool createDefaultOnFail_;

  private this(Handle family) {
    nativeFamily_ = family;
  }

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
    Status status = GdipCreateFontFamilyFromName(name.toUtf16z(), (fontCollection is null) ? Handle.init : fontCollection.nativeFontCollection_, nativeFamily_);
    if (status != Status.OK) {
      if (createDefaultOnFail_) {
        status = GdipGetGenericFontFamilySansSerif(nativeFamily_);
        if (status != Status.OK)
          throw statusException(status);
      }
      else {
        throw statusException(status);
      }
    }
  }

  /**
   */
  private this(string name, bool createDefaultOnFail) {
    createDefaultOnFail_ = createDefaultOnFail;
    this(name);
  }

  ~this() {
    dispose();
  }

  /**
   */
  final void dispose() {
    if (nativeFamily_ != Handle.init) {
      GdipDeleteFontFamilySafe(nativeFamily_);
      nativeFamily_ = Handle.init;
    }
  }

  bool equals(Object obj) {
    if (this is obj)
      return true;
    if (auto other = cast(FontFamily)obj)
      return other.nativeFamily_ == nativeFamily_;
    return false;
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
  string getName(int language) {
    wchar[32] buffer;
    Status status = GdipGetFamilyName(nativeFamily_, buffer.ptr, language);
    if (status != Status.OK)
      throw statusException(status);
    return toUtf8(buffer.ptr);
  }

  /**
   */
  @property string name() {
    return getName(0);
  }

  /**
   */
  static @property FontFamily genericSerif() {
    return new FontFamily(GenericFontFamilies.Serif);
  }

  /**
   */
  static @property FontFamily genericSansSerif() {
    return new FontFamily(GenericFontFamilies.SansSerif);
  }

  /**
   */
  static @property FontFamily genericMonospace() {
    return new FontFamily(GenericFontFamilies.Monospace);
  }

}

/**
 */
final class Font : IDisposable {

  private Handle nativeFont_;
  private float size_;
  private FontStyle style_;
  private GraphicsUnit unit_;
  private FontFamily fontFamily_;

  private this(Handle nativeFont) {
    nativeFont_ = nativeFont;

    float size;
    Status status = GdipGetFontSize(nativeFont, size);
    if (status != Status.OK)
      throw statusException(status);

    FontStyle style;
    status = GdipGetFontStyle(nativeFont, style);
    if (status != Status.OK)
      throw statusException(status);

    GraphicsUnit unit;
    status = GdipGetFontUnit(nativeFont, unit);
    if (status != Status.OK)
      throw statusException(status);

    Handle family;
    status = GdipGetFamily(nativeFont, family);
    if (status != Status.OK)
      throw statusException(status);

    fontFamily_ = new FontFamily(family);

    this(fontFamily_, size, style, unit);
  }

  /**
   */
  this(Font prototype, FontStyle newStyle) {
    this(prototype.fontFamily, prototype.size, newStyle, prototype.unit);
  }

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

    string stripVerticalName(string name) {
      if (name.length > 1 && name[0] == '@')
        return name[1 .. $];
      return name;
    }

    fontFamily_ = new FontFamily(stripVerticalName(familyName), true);
    this(fontFamily_, emSize, style, unit);
  }

  /**
   */
  this(FontFamily family, float emSize, FontStyle style = FontStyle.Regular, GraphicsUnit unit = GraphicsUnit.Point) {
    if (family is null)
      throw new ArgumentNullException("family");

    size_ = emSize;
    style_ = style;
    unit_ = unit;
    if (fontFamily_ is null)
      fontFamily_ = new FontFamily(family.nativeFamily_);

    Status status = GdipCreateFont(fontFamily_.nativeFamily_, size_, style_, unit_, nativeFont_);
    if (status != Status.OK)
      throw statusException(status);
  }

  ~this() {
    dispose();
  }

  /**
   */
  final void dispose() {
    if (nativeFont_ != Handle.init) {
      GdipDeleteFontSafe(nativeFont_);
      nativeFont_ = Handle.init;
    }
  }

  bool equals(Object obj) {
    if (this is obj)
      return true;
    if (auto other = cast(Font)obj)
      return other.fontFamily_.equals(fontFamily_) 
      && other.style_ == style_ 
      && other.size_ == size_ 
      && other.unit_ == unit_;
    return false;
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
    float height = 0;
    Status status = GdipGetFontHeight(nativeFont_, graphics.nativeGraphics_, height);
    if (status != Status.OK)
      throw statusException(status);
    return height;
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
  @property FontFamily fontFamily() {
    return fontFamily_;
  }

  /**
   */
  @property float size() {
    return size_;
  }

  /**
   */
  @property float sizeInPoints() {
    if (unit == GraphicsUnit.Point)
      return size;

    Handle hdc = GetDC(Handle.init);
    scope(exit) ReleaseDC(Handle.init, hdc);

    scope g = Graphics.fromHdc(hdc);
    float pixelsPerPoint = g.dpiY / 72.0;
    float lineSpacing = getHeight(g);
    float emHeight = lineSpacing * fontFamily.getEmHeight(style) / fontFamily.getLineSpacing(style);

    return emHeight / pixelsPerPoint;
  }

  /**
   */
  @property FontStyle style() {
    return style_;
  }

  /**
   */
  @property GraphicsUnit unit() {
    return unit_;
  }

  /**
   */
  @property int height() {
    return cast(int)std.math.ceil(getHeight());
  }

  /**
   */
  @property string name() {
    return fontFamily.name;
  }

  /**
   */
  @property bool bold() {
    return (style & FontStyle.Bold) != 0;
  }

  /**
   */
  @property bool italic() {
    return (style & FontStyle.Italic) != 0;
  }

  /**
   */
  @property bool underline() {
    return (style & FontStyle.Underline) != 0;
  }

  /**
   */
  @property bool strikeout() {
    return (style & FontStyle.Strikeout) != 0;
  }

}
