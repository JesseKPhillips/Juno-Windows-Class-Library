/**
 * Copyright: (c) 2009 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.media.constants;

/// Specifies the known system colors.
enum KnownColor {
  ActiveBorder = 1,        /// A system-defined color.
  ActiveCaption,           /// ditto
  ActiveCaptionText,       /// ditto
  AppWorkspace,            /// ditto
  Control,                 /// ditto
  ControlDark,             /// ditto
  ControlDarkDark,         /// ditto
  ControlLight,            /// ditto
  ControlLightLight,       /// ditto
  ControlText,             /// ditto
  Desktop,                 /// ditto
  GrayText,                /// ditto
  Highlight,               /// ditto
  HighlightText,           /// ditto
  HotTrack,                /// ditto
  InactiveBorder,          /// ditto
  InactiveCaption,         /// ditto
  InactiveCaptionText,     /// ditto
  Info,                    /// ditto
  InfoText,                /// ditto
  Menu,                    /// ditto
  MenuText,                /// ditto
  ScrollBar,               /// ditto
  Window,                  /// ditto
  WindowFrame,             /// ditto
  WindowText,              /// ditto
  Transparent,             /// ditto
  AliceBlue,               /// ditto
  AntiqueWhite,            /// ditto
  Aqua,                    /// ditto
  Aquamarine,              /// ditto
  Azure,                   /// ditto
  Beige,                   /// ditto
  Bisque,                  /// ditto
  Black,                   /// ditto
  BlanchedAlmond,          /// ditto
  Blue,                    /// ditto
  BlueViolet,              /// ditto
  Brown,                   /// ditto
  BurlyWood,               /// ditto
  CadetBlue,               /// ditto
  Chartreuse,              /// ditto
  Chocolate,               /// ditto
  Coral,                   /// ditto
  CornflowerBlue,          /// ditto
  Cornsilk,                /// ditto
  Crimson,                 /// ditto
  Cyan,                    /// ditto
  DarkBlue,                /// ditto
  DarkCyan,                /// ditto
  DarkGoldenrod,           /// ditto
  DarkGray,                /// ditto
  DarkGreen,               /// ditto
  DarkKhaki,               /// ditto
  DarkMagenta,             /// ditto
  DarkOliveGreen,          /// ditto
  DarkOrange,              /// ditto
  DarkOrchid,              /// ditto
  DarkRed,                 /// ditto
  DarkSalmon,              /// ditto
  DarkSeaGreen,            /// ditto
  DarkSlateBlue,           /// ditto
  DarkSlateGray,           /// ditto
  DarkTurquoise,           /// ditto
  DarkViolet,              /// ditto
  DeepPink,                /// ditto
  DeepSkyBlue,             /// ditto
  DimGray,                 /// ditto
  DodgerBlue,              /// ditto
  Firebrick,               /// ditto
  FloralWhite,             /// ditto
  ForestGreen,             /// ditto
  Fuchsia,                 /// ditto
  Gainsboro,               /// ditto
  GhostWhite,              /// ditto
  Gold,                    /// ditto
  Goldenrod,               /// ditto
  Gray,                    /// ditto
  Green,                   /// ditto
  GreenYellow,             /// ditto
  Honeydew,                /// ditto
  HotPink,                 /// ditto
  IndianRed,               /// ditto
  Indigo,                  /// ditto
  Ivory,                   /// ditto
  Khaki,                   /// ditto
  Lavender,                /// ditto
  LavenderBlush,           /// ditto
  LawnGreen,               /// ditto
  LemonChiffon,            /// ditto
  LightBlue,               /// ditto
  LightCoral,              /// ditto
  LightCyan,               /// ditto
  LightGoldenrodYellow,    /// ditto
  LightGray,               /// ditto
  LightGreen,              /// ditto
  LightPink,               /// ditto
  LightSalmon,             /// ditto
  LightSeaGreen,           /// ditto
  LightSkyBlue,            /// ditto
  LightSlateGray,          /// ditto
  LightSteelBlue,          /// ditto
  LightYellow,             /// ditto
  Lime,                    /// ditto
  LimeGreen,               /// ditto
  Linen,                   /// ditto
  Magenta,                 /// ditto
  Maroon,                  /// ditto
  MediumAquamarine,        /// ditto
  MediumBlue,              /// ditto
  MediumOrchid,            /// ditto
  MediumPurple,            /// ditto
  MediumSeaGreen,          /// ditto
  MediumSlateBlue,         /// ditto
  MediumSpringGreen,       /// ditto
  MediumTurquoise,         /// ditto
  MediumVioletRed,         /// ditto
  MidnightBlue,            /// ditto
  MintCream,               /// ditto
  MistyRose,               /// ditto
  Moccasin,                /// ditto
  NavajoWhite,             /// ditto
  Navy,                    /// ditto
  OldLace,                 /// ditto
  Olive,                   /// ditto
  OliveDrab,               /// ditto
  Orange,                  /// ditto
  OrangeRed,               /// ditto
  Orchid,                  /// ditto
  PaleGoldenrod,           /// ditto
  PaleGreen,               /// ditto
  PaleTurquoise,           /// ditto
  PaleVioletRed,           /// ditto
  PapayaWhip,              /// ditto
  PeachPuff,               /// ditto
  Peru,                    /// ditto
  Pink,                    /// ditto
  Plum,                    /// ditto
  PowderBlue,              /// ditto
  Purple,                  /// ditto
  Red,                     /// ditto
  RosyBrown,               /// ditto
  RoyalBlue,               /// ditto
  SaddleBrown,             /// ditto
  Salmon,                  /// ditto
  SandyBrown,              /// ditto
  SeaGreen,                /// ditto
  SeaShell,                /// ditto
  Sienna,                  /// ditto
  Silver,                  /// ditto
  SkyBlue,                 /// ditto
  SlateBlue,               /// ditto
  SlateGray,               /// ditto
  Snow,                    /// ditto
  SpringGreen,             /// ditto
  SteelBlue,               /// ditto
  Tan,                     /// ditto
  Teal,                    /// ditto
  Thistle,                 /// ditto
  Tomato,                  /// ditto
  Turquoise,               /// ditto
  Violet,                  /// ditto
  Wheat,                   /// ditto
  White,                   /// ditto
  WhiteSmoke,              /// ditto
  Yellow,                  /// ditto
  YellowGreen,             /// ditto
  ButtonFace,              /// ditto
  ButtonHighlight,         /// ditto
  ButtonShadow,            /// ditto
  GradientActiveCaption,   /// ditto
  GradientInactiveCaption, /// ditto
  MenuBar,                 /// ditto
  MenuHighlight            /// ditto
}

enum ImageType {
  Unknown,
  Bitmap,
  Metafile
}

/// Specifies how different clipping regions can be combined.
enum CombineMode {
  Replace,    /// One clipping region is replaced by another.
  Intersect,  /// Two clipping regions are combined by taking their intersection.
  Union,      /// Two clipping regions are combined by taking the union of both.
  Xor,        /// Two clipping regions are combined by taking only the areas enclosed by one or other region.
  Exclude,    /// The existing region is excluded from the new region.
  Complement  /// The new region is excluded from the existing region.
}

/// Specifies whether commands in the graphics stack are flushed immediately.
enum FlushIntention {
  Flush, /// The stack of all graphics operations in flushed immediately.
  Sync   /// All graphics operations on the stack are executed as soon as possible, thus synchronizing the graphics state.
}

/// Specifies the order for matrix transform operations.
enum MatrixOrder {
  Prepend,  /// The new operation is applied before the old operation.
  Append    /// The new operation is applied after the old operation.
}

/// Specifies the unit of measure for given data.
enum GraphicsUnit {
  World,      /// Specifies the world unit as the unit of measure.
  Display,    /// Specifies 1/75 inch as the unit of measure.
  Pixel,      /// Specifies a device pixel as the unit of measure.
  Point,      /// Specifies a printer's point (1/72 inch) as the unit of measure.
  Inch,       /// Specifies the inch as the unit of measure.
  Document,   /// Specifies the document unit (1/300 inch) as the unit of measure.
  Millimeter  /// Specifies the millimeter as the unit of measure.
}

/// Specifies the quality when rendering GDI+ objects.
enum QualityMode {
  Invalid = -1, /// Specifies an invalid mode.
  Default,      /// Specifies the default mode.
  Low,          /// Specifies low quality, high speed rendering.
  High          /// Specifies high quality, low speed rendering.
}

/// Specifies whether smoothing (antialiasing) is applied to lines, curves and the edges of filled areas.
enum SmoothingMode {
  Invalid = cast(int)QualityMode.Invalid,  /// Specifies an invalid mode.
  Default = QualityMode.Default,  /// Specifies the default mode.
  HighSpeed,                      /// Specifies high speed, low quality rendering.
  HighQuality,                    /// Specifies high quality, low speed rendering.
  None,                           /// Specifies no antialiasing.
  AntiAlias                       /// Specifies antialiased rendering.
}

/// Specifies how data is interpolated between endpoints.
enum InterpolationMode {
  Invalid = cast(int)QualityMode.Invalid,  /// Specifies an invalid mode.
  Default = QualityMode.Default,  /// Specifies the default mode.
  Low = QualityMode.Low,          /// Specifies low quality interpolation.
  High = QualityMode.High,        /// Specifies high quality interpolation.
  Bilinear,                       /// Specifies bilinear interpolation.
  Bicubic,                        /// Specifies bicubic interpolation.
  NearestNeighbor,                /// Specifies nearest-neighbor interpolation.
  HighQualityBilinear,            /// Specifies high quality bilinear interpolation.
  HighQualityBicubic              /// Specifies high quality bicubic interpolation.
}

/// Specifies how the source colors are combined with the background colors.
enum CompositingMode {
  SourceOver, /// Specifies that the color is blended with the background color.
  SourceCopy  /// Specifies that the color overwrites the background color.
}

/// Specifies the quality level to use during compositing.
enum CompositingQuality {
  Invalid = cast(int)QualityMode.Invalid,  /// Invalid quality.
  Default = QualityMode.Default,  /// Default quality.
  HighSpeed = QualityMode.Low,    /// High speed, low quality.
  HighQuality = QualityMode.High, /// High quality, low speed.
  GammaCorrected,                 /// Gamma correction is used.
  AssumeLinear                    /// Assume linear values.
}

/// Specifies how pixels are offset during rendering.
enum PixelOffsetMode {
  Invalid = cast(int)QualityMode.Invalid,  /// Specifies an invalid mode.
  Default = QualityMode.Default,  /// Specifies the default mode.
  HighSpeed = QualityMode.Low,    /// Specifies high speed, low quality rendering.
  HighQuality = QualityMode.High, /// Specifies high quality, low speed rendering.
  None,                           /// Specifies no pixel offset.
  Half                            /// Specifies that pixels are offset by -.5 units for high speed antialiasing.
}

/// Specifies the format of the color data for each pixel in the image.
enum PixelFormat {
  Undefined = 0,                                                    /// The pixel format is undefined.
  DontCare = 0,                                                     /// No pixel format is specified.
  Indexed = 0x00010000,                                             /// The pixel data contains color-indexed values.
  Gdi = 0x00020000,                                                 /// The pixel data contains GDI colors.
  Alpha = 0x00040000,                                               /// The pixel data contains alpha values that are not premultiplied.
  PAlpha = 0x00080000,                                              /// The pixel data contains premultiplied alpha values.
  Extended = 0x00100000,                                            /// Reserved.
  Canonical = 0x00200000,                                           /// Reserved.
  Format1bppIndexed = 1 | (1 << 8) | Indexed | Gdi,                 /// Specifies that the pixel format is 1 bit per pixel and that it uses indexed color.
  Format4bppIndexed = 2 | (4 << 8) | Indexed | Gdi,                 /// Specifies that the format is 4 bits per pixel, indexed.
  Format8bppIndexed = 3 | (8 << 8) | Indexed | Gdi,                 /// Specifies that the format is 8 bits per pixel, indexed.
  Format16bppGrayScale = 4 | (16 << 8) | Extended,                  /// The pixel format is 16 bits per pixel. The color information specifies 65536 shades of gray.
  Format16bppRgb555 = 5 | (16 << 8) | Gdi,                          /// Specifies that the format is 16 bits per pixel; 5 bits each are used for the red, green, and blue components.
  Format16bppRgb565 = 6 | (16 << 8) | Gdi,                          /// Specifies that the format is 16 bits per pixel; 5 bits are used for the red component, 6 bits are used for the green component, and 5 bits are used for the blue component.
  Format16bppArgb1555 = 7 | (16 << 8) | Alpha | Gdi,                /// The pixel format is 16 bits per pixel. The color information specifies 32,768 shades of color, of which 5 bits are red, 5 bits are green, 5 bits are blue, and 1 bit is alpha.
  Format24bppRgb = 8 | (24 << 8) | Gdi,                             /// Specifies that the format is 24 bits per pixel; 8 bits each are used for the red, green, and blue components.
  Format32bppRgb = 9 | (32 << 8) | Gdi,                             /// Specifies that the format is 32 bits per pixel; 8 bits each are used for the red, green, and blue components.
  Format32bppArgb = 10 | (32 << 8) | Alpha | Gdi | Canonical,       /// Specifies that the format is 32 bits per pixel; 8 bits each are used for the alpha, red, green, and blue components.
  Format32bppPArgb = 11 | (32 << 8) | Alpha | PAlpha | Gdi,         /// Specifies that the format is 32 bits per pixel; 8 bits each are used for the alpha, red, green, and blue components. The red, green, and blue components are premultiplied according to the alpha component.
  Format48bppRgb = 12 | (48 << 8) | Extended,                       /// Specifies that the format is 48 bits per pixel; 16 bits each are used for the red, green, and blue components.
  Format64bppArgb = 13 | (64 << 8) | Alpha | Canonical | Extended,  /// Specifies that the format is 64 bits per pixel; 16 bits each are used for the alpha, red, green, and blue components.
  Format64bppPArgb = 14 | (64 << 8) | Alpha | PAlpha | Extended     /// Specifies that the format is 64 bits per pixel; 16 bits each are used for the alpha, red, green, and blue components. The red, green, and blue components are premultiplied according to the alpha component.
}

enum RotateFlipType {
  RotateNoneFlipNone = 0,
  Rotate90FlipNone = 1,
  Rotate180FlipNone = 2,
  Rotate270FlipNone = 3,
  RotateNoneFlipX = 4,
  Rotate90FlipX = 5,
  Rotate180FlipX = 6,
  Rotate270FlipX = 7,
  RotateNoneFlipY = Rotate180FlipX,
  Rotate90FlipY = Rotate270FlipX,
  Rotate180FlipY = RotateNoneFlipX,
  Rotate270FlipY = Rotate90FlipX,
  RotateNoneFlipXY = Rotate180FlipNone,
  Rotate90FlipXY = Rotate270FlipNone,
  Rotate180FlipXY = RotateNoneFlipNone,
  Rotate270FlipXY = Rotate90FlipNone
}

enum CoordinateSpace {
  World,
  Page,
  Device
}

enum WarpMode {
  Perspective,
  Bilinear
}

enum WrapMode {
  Tile,
  TileFlipX,
  TileFlipY,
  FileFlipXY,
  Clamp
}

enum FillMode {
  Alternate,
  Winding
}

enum LineJoin {
  Miter,
  Bevel,
  Round,
  MiterClipped
}

enum LineCap {
  Flat = 0,
  Square = 1,
  Round = 2,
  Triangle = 3,
  NoAnchor = 0x10,
  SquareAnchor = 0x11,
  RoundAnchor = 0x12,
  DiamondAnchor = 0x13,
  ArrowAnchor = 0x14,
  Custom = 0xff,
  AnchorMask = 0xf0
}

enum DashCap {
  Flat = 0,
  Round = 2,
  Triangle = 3
}

enum DashStyle {
  Solid,
  Dash,
  Dot,
  DashDot,
  DashDotDot,
  Custom
}

enum PenAlignment {
  Center,
  Inset,
  Outset,
  Left,
  Right
}

enum ColorMatrixFlag {
  Default,
  SkipGrays,
  AltGrays
}

enum ColorAdjustType {
  Default,
  Bitmap,
  Brush,
  Pen,
  Text,
  Count,
  Any
}

enum ColorChannelFlag {
  ColorChannelC,
  ColorChannelM,
  ColorChannelY,
  ColorChannelK,
  ColorChannelLast
}

enum ImageLockMode {
  Read = 0x0001,
  Write = 0x0002,
  ReadWrite = Read | Write,
  UserInputBuffer = 0x0004
}

enum ImageCodecFlags {
  Encoder = 0x00000001,
  Decoder = 0x00000002,
  SupportBitmap = 0x00000004,
  SupportVector = 0x00000008,
  SeekableEncode = 0x00000010,
  BlockingDecode = 0x00000020,
  Builtin = 0x00010000,
  System = 0x00020000,
  User = 0x00040000
}

enum EncoderParameterValueType {
  ValueTypeByte = 1,
  ValueTypeAscii,
  ValueTypeShort,
  ValueTypeLong,
  ValueTypeRational,
  ValueTypeLongRange,
  ValueTypeRationalRange
}

enum MetafileFrameUnit {
  Pixel = 2,
  Point = 3,
  Inch = 4,
  Document = 5,
  Millimeter = 6,
  GdiCompatible = 7
}

enum EmfType {
  EmfOnly = 3,
  EmfPlusOnly = 4,
  EmfPlusDual = 5
}

enum GenericFontFamilies {
  Serif,
  SansSerif,
  Monospace
}

enum FontStyle {
  Regular = 0,
  Bold = 1,
  Italic = 2,
  Underline = 4,
  Strikeout = 8
}

enum StringFormatFlags {
  DirectionRightToLeft = 0x1,
  DirectionVertical = 0x2,
  FitBlackBox = 0x4,
  DisplayFormatControl = 0x20,
  NoFontFallback = 0x400,
  MeasureTrailingSpaces = 0x800,
  NoWrap = 0x1000,
  LineLimit = 0x2000,
  NoClip = 0x4000
}

enum StringAlignment {
  Near,
  Center,
  Far
}

enum StringTrimming {
  None,
  Character,
  Word,
  EllipsisCharacter,
  EllipsisWord,
  EllipsisPath
}

enum TextRenderingHint {
  SystemDefault,
  SingleBitPerPixelGridFit,
  SingleBitPerPixel,
  AntiAliasGridFit,
  AntiAlias,
  ClearTypeGridFit
}

enum PenType {
  SolidColor,
  HatchFill,
  TextureFill,
  PathGradient,
  LinearGradient
}

enum HatchStyle {
  Horizontal,
  Vertical,
  ForwardDiagonal,
  BackwardDiagonal,
  Cross,
  DiagonalCross,
  Percent05,
  Percent10,
  Percent20,
  Percent25,
  Percent30,
  Percent40,
  Percent50,
  Percent60,
  Percent70,
  Percent75,
  Percent80,
  Percent90,
  LightDownwardDiagonal,
  LightUpwardDiagonal,
  DarkDownwardDiagonal,
  DarkUpwardDiagonal,
  LightVertical,
  LightHorizontal,
  NarrowVertical,
  NarrowHorizontal,
  DarkVertical,
  DarkHorizontal,
  DashedDownwardDiagonal,
  DashedUpwardDiagonal,
  DashedHorizontal,
  DashedVertical,
  SmallConfetti,
  LargeConfetti,
  ZigZag,
  Wave,
  DiagonalBrick,
  HorizontalBrick,
  Weave,
  Plaid,
  Divot,
  DottedGrid,
  DottedDiamond,
  Shingle,
  Trellis,
  Sphere,
  SmallGrid,
  SmallCheckerBoard,
  LargeCheckerBoard,
  OutlinedDiamond,
  SolidDiamond
}

enum LinearGradientMode {
  Horizontal,
  Vertical,
  ForwardDiagonal,
  BackwardDiagonal
}

enum PaletteFlags {
  HasAlpha = 0x1,
  GrayScale = 0x2,
  Halftone = 0x4
}

enum ColorMapType {
  Default,
  Brush
}

enum ImageFlags {
  None = 0x0,
  Scalable = 0x1,
  HasAlpha = 0x2,
  HasTranslucent = 0x4,
  PartiallyScalable = 0x8,
  ColorSpaceRgb = 0x10,
  ColorSpaceCmyk = 0x20,
  ColorSpaceGray = 0x40,
  ColorSpaceYcbcr = 0x80,
  ColorSpaceYcck = 0x100,
  HasRealDpi = 0x1000,
  HasRealPixelSize = 0x2000,
  ReadOnly = 0x10000,
  Caching = 0x20000
}

enum HotkeyPrefix {
  None,
  Show,
  Hide
}
