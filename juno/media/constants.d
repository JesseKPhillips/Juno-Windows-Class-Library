/**
 * Copyright: (c) 2008 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.media.constants;

enum CombineMode {
  Replace,
  Intersect,
  Union,
  Xor,
  Exclude,
  Complement
}

enum FlushIntention {
  Flush,
  Sync
}

enum MatrixOrder {
  Prepend,
  Append
}

enum GraphicsUnit {
  World,
  Display,
  Pixel,
  Point,
  Inch,
  Document,
  Millimeter
}

enum QualityMode {
  Invalid = -1,
  Default,
  Low,
  High
}

enum SmoothingMode {
  Invalid = QualityMode.Invalid,
  Default = QualityMode.Default,
  HighSpeed,
  HighQuality,
  None,
  AntiAlias
}

enum InterpolationMode {
  Invalid = QualityMode.Invalid,
  Default = QualityMode.Default,
  Low = QualityMode.Low,
  High = QualityMode.High,
  Bilinear,
  Bicubic,
  NearestNeighbor,
  HighQualityBilinear,
  HighQualityBicubic
}

enum CompositingMode {
  SourceOver,
  SourceCopy
}

enum CompositingQuality {
  Invalid = QualityMode.Invalid,
  Default = QualityMode.Default,
  HighSpeed = QualityMode.Low,
  HighQuality = QualityMode.High,
  GammaCorrected,
  AssumeLinear
}

enum PixelOffsetMode {
  Invalid = QualityMode.Invalid,
  Default = QualityMode.Default,
  HighSpeed = QualityMode.Low,
  HighQuality = QualityMode.High,
  None,
  Half
}

enum PixelFormat {
  Undefined = 0,
  DontCare = 0,
  Indexed = 0x00010000,
  Gdi = 0x00020000,
  Alpha = 0x00040000,
  PAlpha = 0x00080000,
  Extended = 0x00100000,
  Canonical = 0x00200000,
  Format1bppIndexed = 1 | (1 << 8) | Indexed | Gdi,
  Format4bppIndexed = 2 | (4 << 8) | Indexed | Gdi,
  Format8bppIndexed = 3 | (8 << 8) | Indexed | Gdi,
  Format16bppGrayScale = 4 | (16 << 8) | Extended,
  Format16bppRgb555 = 5 | (16 << 8) | Gdi,
  Format16bppRgb565 = 6 | (16 << 8) | Gdi,
  Format16bppArgb1555 = 7 | (16 << 8) | Alpha | Gdi,
  Format24bppRgb = 8 | (24 << 8) | Gdi,
  Format32bppRgb = 9 | (32 << 8) | Gdi,
  Format32bppArgb = 10 | (32 << 8) | Alpha | Gdi | Canonical,
  Format32bppPArgb = 11 | (32 << 8) | Alpha | PAlpha | Gdi,
  Format48bppRgb = 12 | (48 << 8) | Extended,
  Format64bppArgb = 13 | (64 << 8) | Alpha | Canonical | Extended,
  Format64bppPArgb = 14 | (64 << 8) | Alpha | PAlpha | Extended
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

enum PaletteFlags : uint {
  HasAlpha = 0x1,
  GrayScale = 0x2,
  Halftone = 0x4
}

enum ColorMapType {
  Default,
  Brush
}

enum ImageFlags : uint {
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

enum KnownColor : uint {
  ActiveBorder = 1,
  ActiveCaption,
  ActiveCaptionText,
  AppWorkspace,
  Control,
  ControlDark,
  ControlDarkDark,
  ControlLight,
  ControlLightLight,
  ControlText,
  Desktop,
  GrayText,
  Highlight,
  HighlightText,
  HotTrack,
  InactiveBorder,
  InactiveCaption,
  InactiveCaptionText,
  Info,
  InfoText,
  Menu,
  MenuText,
  ScrollBar,
  Window,
  WindowFrame,
  WindowText,
  Transparent,
  AliceBlue,
  AntiqueWhite,
  Aqua,
  Aquamarine,
  Azure,
  Beige,
  Bisque,
  Black,
  BlanchedAlmond,
  Blue,
  BlueViolet,
  Brown,
  BurlyWood,
  CadetBlue,
  Chartreuse,
  Chocolate,
  Coral,
  CornflowerBlue,
  Cornsilk,
  Crimson,
  Cyan,
  DarkBlue,
  DarkCyan,
  DarkGoldenrod,
  DarkGray,
  DarkGreen,
  DarkKhaki,
  DarkMagenta,
  DarkOliveGreen,
  DarkOrange,
  DarkOrchid,
  DarkRed,
  DarkSalmon,
  DarkSeaGreen,
  DarkSlateBlue,
  DarkSlateGray,
  DarkTurquoise,
  DarkViolet,
  DeepPink,
  DeepSkyBlue,
  DimGray,
  DodgerBlue,
  Firebrick,
  FloralWhite,
  ForestGreen,
  Fuchsia,
  Gainsboro,
  GhostWhite,
  Gold,
  Goldenrod,
  Gray,
  Green,
  GreenYellow,
  Honeydew,
  HotPink,
  IndianRed,
  Indigo,
  Ivory,
  Khaki,
  Lavender,
  LavenderBlush,
  LawnGreen,
  LemonChiffon,
  LightBlue,
  LightCoral,
  LightCyan,
  LightGoldenrodYellow,
  LightGray,
  LightGreen,
  LightPink,
  LightSalmon,
  LightSeaGreen,
  LightSkyBlue,
  LightSlateGray,
  LightSteelBlue,
  LightYellow,
  Lime,
  LimeGreen,
  Linen,
  Magenta,
  Maroon,
  MediumAquamarine,
  MediumBlue,
  MediumOrchid,
  MediumPurple,
  MediumSeaGreen,
  MediumSlateBlue,
  MediumSpringGreen,
  MediumTurquoise,
  MediumVioletRed,
  MidnightBlue,
  MintCream,
  MistyRose,
  Moccasin,
  NavajoWhite,
  Navy,
  OldLace,
  Olive,
  OliveDrab,
  Orange,
  OrangeRed,
  Orchid,
  PaleGoldenrod,
  PaleGreen,
  PaleTurquoise,
  PaleVioletRed,
  PapayaWhip,
  PeachPuff,
  Peru,
  Pink,
  Plum,
  PowderBlue,
  Purple,
  Red,
  RosyBrown,
  RoyalBlue,
  SaddleBrown,
  Salmon,
  SandyBrown,
  SeaGreen,
  SeaShell,
  Sienna,
  Silver,
  SkyBlue,
  SlateBlue,
  SlateGray,
  Snow,
  SpringGreen,
  SteelBlue,
  Tan,
  Teal,
  Thistle,
  Tomato,
  Turquoise,
  Violet,
  Wheat,
  White,
  WhiteSmoke,
  Yellow,
  YellowGreen,
  ButtonFace,
  ButtonHighlight,
  ButtonShadow,
  GradientActiveCaption,
  GradientInactiveCaption,
  MenuBar,
  MenuHighlight
}