/**
 * Copyright: (c) 2008 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.media.native;

private import juno.base.core,
  juno.com.core,
  juno.media.constants,
  juno.media.geometry;

private static import core.memory;
private import core.exception;

pragma(lib, "user32.lib");
pragma(lib, "gdi32.lib");
pragma(lib, "gdiplus.lib");

static this() {
  startupGdiplus();
}

static ~this() {
  shutdownGdiplus();
}

extern(Windows):

enum {
  COLOR_SCROLLBAR               = 0,
  COLOR_BACKGROUND              = 1,
  COLOR_ACTIVECAPTION           = 2,
  COLOR_INACTIVECAPTION         = 3,
  COLOR_MENU                    = 4,
  COLOR_WINDOW                  = 5,
  COLOR_WINDOWFRAME             = 6,
  COLOR_MENUTEXT                = 7,
  COLOR_WINDOWTEXT              = 8,
  COLOR_CAPTIONTEXT             = 9,
  COLOR_ACTIVEBORDER            = 10,
  COLOR_INACTIVEBORDER          = 11,
  COLOR_APPWORKSPACE            = 12,
  COLOR_HIGHLIGHT               = 13,
  COLOR_HIGHLIGHTTEXT           = 14,
  COLOR_BTNFACE                 = 15,
  COLOR_BTNSHADOW               = 16,
  COLOR_GRAYTEXT                = 17,
  COLOR_BTNTEXT                 = 18,
  COLOR_INACTIVECAPTIONTEXT     = 19,
  COLOR_BTNHIGHLIGHT            = 20,
  COLOR_3DDKSHADOW              = 21,
  COLOR_3DLIGHT                 = 22,
  COLOR_INFOTEXT                = 23,
  COLOR_INFOBK                  = 24,
  COLOR_HOTLIGHT                = 26,
  COLOR_GRADIENTACTIVECAPTION   = 27,
  COLOR_GRADIENTINACTIVECAPTION = 28,
  COLOR_MENUHILIGHT             = 29,
  COLOR_MENUBAR                 = 30,
  COLOR_DESKTOP                 = COLOR_BACKGROUND,
  COLOR_3DFACE                  = COLOR_BTNFACE,
  COLOR_3DSHADOW                = COLOR_BTNSHADOW,
  COLOR_3DHIGHLIGHT             = COLOR_BTNHIGHLIGHT,
  COLOR_3DHILIGHT               = COLOR_BTNHIGHLIGHT,
  COLOR_BTNHILIGHT              = COLOR_BTNHIGHLIGHT
}

uint GetSysColor(int nIndex);

struct LOGFONTW {
  int lfHeight;
  int lfWidth;
  int lfEscapement;
  int lfOrientation;
  int lfWeight;
  ubyte lfItalic;
  ubyte lfUnderline;
  ubyte lfStrikeOut;
  ubyte lfCharSet;
  ubyte lfOutPrecision;
  ubyte lfClipPrecision;
  ubyte lfQuality;
  ubyte lfPitchAndFamily;
  wchar[32] lfFaceName;
}
alias LOGFONTW LOGFONT;

Handle CreateFontIndirectW(ref LOGFONTW lplf);
alias CreateFontIndirectW CreateFontIndirect;

Handle GetDC(Handle hWnd);

int ReleaseDC(Handle hWnd, Handle hDC);

Handle SelectObject(Handle hdc, Handle hObject);

int DeleteObject(Handle hObject);

int GetObjectW(Handle h, int c, void* pv);
alias GetObjectW GetObject;

// GDI+

alias int function(void*) GpDrawImageAbort;
alias GpDrawImageAbort GpGetThumbnailImageAbort;

enum Status {
  OK,
  GenericError,
  InvalidParameter,
  OutOfMemory,
  ObjectBusy,
  InsufficientBuffer,
  NotImplemented,
  Win32Error,
  WrongState,
  Aborted,
  FileNotFound,
  ValueOverflow,
  AccessDenied,
  UnknownImageFormat,
  FontFamilyNotFound,
  FontStyleNotFound,
  NotTrueTypeFont,
  UnsupportedGdiplusVersion,
  GdiplusNotInitialized,
  PropertyNotFound,
  PropertyNotSupported
}

enum DebugEventLevel {
  Fatal,
  Warning
}

alias void function(DebugEventLevel level, char* message) DebugEventProc;

alias Status function(out uint token) NotificationHookProc;
alias void function(uint token) NotificationUnhookProc;

struct GdiplusStartupInput {
  uint GdiplusVersion;
  DebugEventProc DebugEventCallback;
  int SuppressBackgroundThread;
  int SuppressExternalCodecs;
}

struct GdiplusStartupOutput {
  NotificationHookProc NotificationHook;
  NotificationUnhookProc NotificationUnhook;
}

Status GdiplusStartup(out uint token, ref GdiplusStartupInput input, out GdiplusStartupOutput output);
void GdiplusShutdown(uint token);

struct GpImageCodecInfo {
  GUID Clsid;
  GUID FormatID;
  wchar* CodecName;
  wchar* DllName;
  wchar* FormatDescription;
  wchar* FilenameExtension;
  wchar* MimeType;
  uint Flags;
  uint Version;
  uint SigCount;
  uint SigSize;
  ubyte* SigPattern;
  ubyte* SigMask;
}

struct GpBitmapData {
  int Width;
  int Height;
  int Stride;
  juno.media.constants.PixelFormat PixelFormat;
  void* Scan0;
  int Reserved;
}

struct GpColorMatrix {
  float[5][5] m;
}

struct GpEncoderParameter {
  GUID Guid;
  int NumberOfValues;
  int Type;
  void* Value;
}

struct GpEncoderParameters {
  int Count;
  GpEncoderParameter[1] Parameter;
}

struct GpPropertyItem {
  int id;
  uint len;
  ushort type;
  void* value;
}

struct GpColorPalette {
  PaletteFlags Flags;
  uint Count;
  uint[1] Entries;
}

Handle GdipCreateHalftonePalette();

Status GdipCreateFromHDC(Handle hdc, out Handle graphics);
Status GdipCreateFromHDC2(Handle hdc, Handle hDevice, out Handle graphics);
Status GdipCreateFromHWND(Handle hwnd, out Handle graphics);
Status GdipGetImageGraphicsContext(Handle image, out Handle graphics);
Status GdipDeleteGraphics(Handle graphics);
Status GdipGetDC(Handle graphics, out Handle hdc);
Status GdipReleaseDC(Handle graphics, Handle hdc);
Status GdipSetClipGraphics(Handle graphics, Handle srcgraphics, CombineMode combineMode);
Status GdipSetClipRectI(Handle graphics, int x, int y, int width, int height, CombineMode combineMode);
Status GdipSetClipRect(Handle graphics, float x, float y, float width, float height, CombineMode combineMode);
Status GdipSetClipPath(Handle graphics, Handle path, CombineMode combineMode);
Status GdipSetClipRegion(Handle graphics, Handle region, CombineMode combineMode);
Status GdipGetClip(Handle graphics, out Handle region);
Status GdipResetClip(Handle graphics);
Status GdipSaveGraphics(Handle graphics, out int state);
Status GdipRestoreGraphics(Handle graphics, int state);
Status GdipFlush(Handle graphics, FlushIntention intention);
Status GdipScaleWorldTransform(Handle graphics, float sx, float sy, MatrixOrder order);
Status GdipRotateWorldTransform(Handle graphics, float angle, MatrixOrder order);
Status GdipTranslateWorldTransform(Handle graphics, float dx, float dy, MatrixOrder order);
Status GdipMultiplyWorldTransform(Handle graphics, Handle matrix, MatrixOrder order);
Status GdipResetWorldTransform(Handle graphics);
Status GdipBeginContainer(Handle graphics, ref RectF dstrect, ref RectF srcrect, GraphicsUnit unit, out int state);
Status GdipBeginContainerI(Handle graphics, ref Rect dstrect, ref Rect srcrect, GraphicsUnit unit, out int state);
Status GdipBeginContainer2(Handle graphics, out int state);
Status GdipEndContainer(Handle graphics, int state);
Status GdipGetDpiX(Handle graphics, out float dpi);
Status GdipGetDpiY(Handle graphics, out float dpi);
Status GdipGetPageUnit(Handle graphics, out GraphicsUnit unit);
Status GdipSetPageUnit(Handle graphics, GraphicsUnit unit);
Status GdipGetPageScale(Handle graphics, out float scale);
Status GdipSetPageScale(Handle graphics, float scale);
Status GdipGetWorldTransform(Handle graphics, out Handle matrix);
Status GdipSetWorldTransform(Handle graphics, Handle matrix);
Status GdipGetCompositingMode(Handle graphics, out CompositingMode compositingMode);
Status GdipSetCompositingMode(Handle graphics, CompositingMode compositingMode);
Status GdipGetCompositingQuality(Handle graphics, out CompositingQuality compositingQuality);
Status GdipSetCompositingQuality(Handle graphics, CompositingQuality compositingQuality);
Status GdipGetInterpolationMode(Handle graphics, out InterpolationMode interpolationMode);
Status GdipSetInterpolationMode(Handle graphics, InterpolationMode interpolationMode);
Status GdipGetSmoothingMode(Handle graphics, out SmoothingMode smoothingMode);
Status GdipSetSmoothingMode(Handle graphics, SmoothingMode smoothingMode);
Status GdipGetPixelOffsetMode(Handle graphics, out PixelOffsetMode pixelOffsetMode);
Status GdipSetPixelOffsetMode(Handle graphics, PixelOffsetMode pixelOffsetMode);
Status GdipGetTextContrast(Handle graphics, out uint textContrast);
Status GdipSetTextContrast(Handle graphics, uint textContrast);
Status GdipGraphicsClear(Handle graphics, int color);
Status GdipDrawLine(Handle graphics, Handle pen, float x1, float y1, float x2, float y2);
Status GdipDrawLines(Handle graphics, Handle pen, PointF* points, int count);
Status GdipDrawLineI(Handle graphics, Handle pen, int x1, int y1, int x2, int y2);
Status GdipDrawLinesI(Handle graphics, Handle pen, Point* points, int count);
Status GdipDrawArc(Handle graphics, Handle pen, float x, float y, float width, float height, float startAngle, float sweepAngle);
Status GdipDrawArcI(Handle graphics, Handle pen, int x, int y, int width, int height, float startAngle, float sweepAngle);
Status GdipDrawBezier(Handle graphics, Handle pen, float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4);
Status GdipDrawBeziers(Handle graphics, Handle pen, PointF* points, int count);
Status GdipDrawBezierI(Handle graphics, Handle pen, int x1, int y1, int x2, int y2, int x3, int y3, int x4, int y4);
Status GdipDrawBeziersI(Handle graphics, Handle pen, Point* points, int count);
Status GdipDrawRectangle(Handle graphics, Handle pen, float x, float y, float width, float height);
Status GdipDrawRectangles(Handle graphics, Handle pen, RectF* rects, int count);
Status GdipDrawRectangleI(Handle graphics, Handle pen, int x, int y, int width, int height);
Status GdipDrawRectanglesI(Handle graphics, Handle pen, Rect* rects, int count);
Status GdipDrawEllipse(Handle graphics, Handle pen, float x, float y, float width, float height);
Status GdipDrawEllipseI(Handle graphics, Handle pen, int x, int y, int width, int height);
Status GdipDrawPie(Handle graphics, Handle pen, float x, float y, float width, float height, float startAngle, float sweepAngle);
Status GdipDrawPieI(Handle graphics, Handle pen, int x, int y, int width, int height, float startAngle, float sweepAngle);
Status GdipDrawPolygon(Handle graphics, Handle pen, PointF* points, int count);
Status GdipDrawPolygonI(Handle graphics, Handle pen, Point* points, int count);
Status GdipDrawCurve(Handle graphics, Handle pen, PointF* points, int count);
Status GdipDrawCurve2(Handle graphics, Handle pen, PointF* points, int count, float tension);
Status GdipDrawCurve3(Handle graphics, Handle pen, PointF* points, int count, int offset, int numberOfSegments, float tension);
Status GdipDrawCurveI(Handle graphics, Handle pen, Point* points, int count);
Status GdipDrawCurve2I(Handle graphics, Handle pen, Point* points, int count, float tension);
Status GdipDrawCurve3I(Handle graphics, Handle pen, Point* points, int count, int offset, int numberOfSegments, float tension);
Status GdipDrawClosedCurve(Handle graphics, Handle pen, PointF* points, int count);
Status GdipDrawClosedCurve2(Handle graphics, Handle pen, PointF* points, int count, float tension);
Status GdipDrawClosedCurveI(Handle graphics, Handle pen, Point* points, int count);
Status GdipDrawClosedCurve2I(Handle graphics, Handle pen, Point* points, int count, float tension);
Status GdipDrawPath(Handle graphics, Handle pen, Handle path);
Status GdipFillRectangleI(Handle graphics, Handle brush, int x, int y, int width, int height);
Status GdipFillRectangle(Handle graphics, Handle brush, float x, float y, float width, float height);
Status GdipFillRectanglesI(Handle graphics, Handle brush, Rect* rects, int count);
Status GdipFillRectangles(Handle graphics, Handle brush, RectF* rects, int count);
Status GdipFillPolygon(Handle graphics, Handle brush, PointF* rects, int count, FillMode fillMode);
Status GdipFillPolygonI(Handle graphics, Handle brush, Point* rects, int count, FillMode fillMode);
Status GdipFillEllipse(Handle graphics, Handle brush, float x, float y, float width, float height);
Status GdipFillEllipseI(Handle graphics, Handle brush, int x, int y, int width, int height);
Status GdipFillPie(Handle graphics, Handle brush, float x, float y, float width, float height, float startAngle, float sweepAngle);
Status GdipFillPieI(Handle graphics, Handle brush, int x, int y, int width, int height, float startAngle, float sweepAngle);
Status GdipFillPath(Handle graphics, Handle brush, Handle path);
Status GdipFillClosedCurve(Handle graphics, Handle brush, PointF* points, int count);
Status GdipFillClosedCurveI(Handle graphics, Handle brush, Point* points, int count);
Status GdipFillClosedCurve2(Handle graphics, Handle brush, PointF* points, int count, FillMode fillMode, float tension);
Status GdipFillClosedCurve2I(Handle graphics, Handle brush, Point* points, int count, FillMode fillMode, float tension);
Status GdipFillRegion(Handle graphics, Handle brush, Handle region);
Status GdipDrawString(Handle graphics, in wchar* string, int length, Handle font, ref RectF layoutRect, Handle stringFormat, Handle brush);
Status GdipMeasureString(Handle graphics, in wchar* string, int length, Handle font, ref RectF layoutRect, Handle stringFormat, ref RectF boundingBox, out int codepointsFitted, out int linesFitted);
Status GdipGetStringFormatMeasurableCharacterRangeCount(Handle format, out int count);
Status GdipMeasureCharacterRanges(Handle graphics, in wchar* string, int length, Handle font, ref RectF layoutRect, Handle stringFormat, int regionCount, Handle* regions);
Status GdipDrawImage(Handle graphics, Handle image, float x, float y);
Status GdipDrawImageI(Handle graphics, Handle image, int x, int y);
Status GdipDrawImageRect(Handle graphics, Handle image, float x, float y, float width, float height);
Status GdipDrawImageRectI(Handle graphics, Handle image, int x, int y, int width, int height);
Status GdipDrawImagePointRect(Handle graphics, Handle image, float x, float y, float srcx, float srcy, float srcwidth, float srcheight, GraphicsUnit srcUnit);
Status GdipDrawImagePointRectI(Handle graphics, Handle image, int x, int y, int srcx, int srcy, int srcwidth, int srcheight, GraphicsUnit srcUnit);
Status GdipDrawImageRectRect(Handle graphics, Handle image, float dstx, float dsty, float dstwidth, float dstheight, float srcx, float srcy, float srcwidth, float srcheight, GraphicsUnit srcUnit, Handle imageAttributes, GpDrawImageAbort callback, void* callbakcData);
Status GdipDrawImageRectRectI(Handle graphics, Handle image, int dstx, int dsty, int dstwidth, int dstheight, int srcx, int srcy, int srcwidth, int srcheight, GraphicsUnit srcUnit, Handle imageAttributes, GpDrawImageAbort callback, void* callbakcData);
Status GdipDrawImagePoints(Handle graphics, Handle image, PointF* dstpoints, int count);
Status GdipDrawImagePointsI(Handle graphics, Handle image, Point* dstpoints, int count);
Status GdipDrawImagePointsRect(Handle graphics, Handle image, PointF* dstpoints, int count, float srcx, float srcy, float srcwidth, float srcheight, GraphicsUnit srcUnit, Handle imageAttributes, GpDrawImageAbort callback, void* callbakcData);
Status GdipDrawImagePointsRectI(Handle graphics, Handle image, Point* dstpoints, int count, int srcx, int srcy, int srcwidth, int srcheight, GraphicsUnit srcUnit, Handle imageAttributes, GpDrawImageAbort callback, void* callbakcData);
Status GdipIsVisiblePoint(Handle graphics, float x, float y, out int result);
Status GdipIsVisiblePointI(Handle graphics, int x, int y, out int result);
Status GdipIsVisibleRect(Handle graphics, float x, float y, float width, float height, out int result);
Status GdipIsVisibleRectI(Handle graphics, int x, int y, int width, int height, out int result);
Status GdipGetTextRenderingHint(Handle graphics, out TextRenderingHint mode);
Status GdipSetTextRenderingHint(Handle graphics, TextRenderingHint mode);
Status GdipGetClipBounds(Handle graphics, out RectF rect);
Status GdipGetVisibleClipBounds(Handle graphics, out RectF rect);
Status GdipIsClipEmpty(Handle graphics, out int result);
Status GdipIsVisibleClipEmpty(Handle graphics, out int result);
Status GdipGetRenderingOrigin(Handle graphics, out int x, out int y);
Status GdipSetRenderingOrigin(Handle graphics, int x, int y);
Status GdipGetNearestColor(Handle graphics, ref uint argb);
Status GdipComment(Handle graphics, uint sizeData, ubyte* data);
Status GdipTransformPoints(Handle graphics, CoordinateSpace destSpace, CoordinateSpace srcSpace, PointF* points, int count);
Status GdipTransformPointsI(Handle graphics, CoordinateSpace destSpace, CoordinateSpace srcSpace, Point* points, int count);

Status GdipCreateMatrix(out Handle matrix);
Status GdipCreateMatrix2(float m11, float m12, float m21, float m22, float dx, float dy, out Handle matrix);
Status GdipCreateMatrix3(ref RectF rect, PointF* dstplg, out Handle matrix);
Status GdipCreateMatrix3I(ref Rect rect, Point* dstplg, out Handle matrix);
Status GdipDeleteMatrix(Handle matrix);
Status GdipCloneMatrix(Handle matrix, out Handle cloneMatrix);
Status GdipGetMatrixElements(Handle matrix, float* matrixOut);
Status GdipSetMatrixElements(Handle matrix, float m11, float m12, float m21, float m22, float xy, float dy);
Status GdipInvertMatrix(Handle matrix);
Status GdipMultiplyMatrix(Handle matrix, Handle matrix2, MatrixOrder order);
Status GdipScaleMatrix(Handle matrix, float scaleX, float scaleY, MatrixOrder order);
Status GdipShearMatrix(Handle matrix, float shearX, float shearY, MatrixOrder order);
Status GdipRotateMatrix(Handle matrix, float angle, MatrixOrder order);
Status GdipTranslateMatrix(Handle matrix, float offsetX, float offsetY, MatrixOrder order);
Status GdipIsMatrixIdentity(Handle matrix, out int result);
Status GdipIsMatrixInvertible(Handle matrix, out int result);

Status GdipDeleteBrush(Handle brush);

Status GdipCreateSolidFill(uint color, out Handle brush);
Status GdipGetSolidFillColor(Handle brush, out uint color);
Status GdipSetSolidFillColor(Handle brush, uint color);

Status GdipCreateTexture(Handle image, WrapMode wrapMode, out Handle texture);
Status GdipCreateTexture2(Handle image, WrapMode wrapMode, float x, float y, float width, float height, out Handle texture);
Status GdipCreateTexture2I(Handle image, WrapMode wrapMode, int x, int y, int width, int height, out Handle texture);
Status GdipGetTextureImage(Handle brush, out Handle image);
Status GdipGetTextureTransform(Handle brush, out Handle matrix);
Status GdipSetTextureTransform(Handle brush, Handle matrix);
Status GdipGetTextureWrapMode(Handle brush, out WrapMode wrapmode);
Status GdipSetTextureWrapMode(Handle brush, WrapMode wrapmode);

Status GdipCreateHatchBrush(HatchStyle hatchstyle, uint forecol, uint backcol, out Handle brush);
Status GdipGetHatchStyle(Handle brush, out HatchStyle hatchstyle);
Status GdipGetHatchForegroundColor(Handle brush, out uint forecol);
Status GdipGetHatchBackgroundColor(Handle brush, out uint backcol);

Status GdipCreateLineBrushI(ref Point point1, ref Point point2, uint color1, uint color2, WrapMode wrapMode, out Handle lineGradient);
Status GdipCreateLineBrush(ref PointF point1, ref PointF point2, uint color1, uint color2, WrapMode wrapMode, out Handle lineGradient);
Status GdipCreateLineBrushFromRectI(ref Rect rect, uint color1, uint color2, LinearGradientMode mode, WrapMode wrapMode, out Handle lineGradient);
Status GdipCreateLineBrushFromRect(ref RectF rect, uint color1, uint color2, LinearGradientMode mode, WrapMode wrapMode, out Handle lineGradient);
Status GdipCreateLineBrushFromRectWithAngleI(ref Rect rect, uint color1, uint color2, float angle, int isAngleScalable, WrapMode wrapMode, out Handle lineGradient);
Status GdipCreateLineBrushFromRectWithAngle(ref RectF rect, uint color1, uint color2, float angle, int isAngleScalable, WrapMode wrapMode, out Handle lineGradient);
Status GdipGetLineBlendCount(Handle brush, out int count);
Status GdipGetLineBlend(Handle brush, float* blend, float* positions, int count);
Status GdipSetLineBlend(Handle brush, float* blend, float* positions, int count);
Status GdipGetLinePresetBlendCount(Handle brush, out int count);
Status GdipGetLinePresetBlend(Handle brush, uint* blend, float* positions, int count);
Status GdipSetLinePresetBlend(Handle brush, uint* blend, float* positions, int count);
Status GdipGetLineWrapMode(Handle brush, out WrapMode wrapmode);
Status GdipSetLineWrapMode(Handle brush, WrapMode wrapmode);
Status GdipGetLineRect(Handle brush, out RectF rect);
Status GdipGetLineColors(Handle brush, uint* colors);
Status GdipSetLineColors(Handle brush, uint color1, uint color2);
Status GdipGetLineGammaCorrection(Handle brush, out int useGammaCorrection);
Status GdipSetLineGammaCorrection(Handle brush, int useGammaCorrection);
Status GdipSetLineSigmaBlend(Handle brush, float focus, float scale);
Status GdipSetLineLinearBlend(Handle brush, float focus, float scale);
Status GdipGetLineTransform(Handle brush, out Handle matrix);
Status GdipSetLineTransform(Handle brush, Handle matrix);
Status GdipResetLineTransform(Handle brush);
Status GdipMultiplyLineTransform(Handle brush, Handle matrix, MatrixOrder order);
Status GdipTranslateLineTransform(Handle brush, float dx, float dy, MatrixOrder order);
Status GdipScaleLineTransform(Handle brush, float sx, float sy, MatrixOrder order);
Status GdipRotateLineTransform(Handle brush, float angle, MatrixOrder order);

Status GdipCreatePen1(int argb, float width, GraphicsUnit unit, out Handle pen);
Status GdipCreatePen2(Handle brush, float width, GraphicsUnit unit, out Handle pen);
Status GdipDeletePen(Handle pen);
Status GdipClonePen(Handle pen, out Handle clonepen);
Status GdipSetPenLineCap197819(Handle pen, LineCap startCap, LineCap endCap, DashCap dashCap);
Status GdipGetPenStartCap(Handle pen, out LineCap startCap);
Status GdipSetPenStartCap(Handle pen, LineCap startCap);
Status GdipGetPenEndCap(Handle pen, out LineCap endCap);
Status GdipSetPenEndCap(Handle pen, LineCap endCap);
Status GdipGetPenDashCap197819(Handle pen, out DashCap endCap);
Status GdipSetPenDashCap197819(Handle pen, DashCap endCap);
Status GdipGetPenLineJoin(Handle pen, out LineJoin lineJoin);
Status GdipSetPenLineJoin(Handle pen, LineJoin lineJoin);
Status GdipGetPenMiterLimit(Handle pen, out float miterLimit);
Status GdipSetPenMiterLimit(Handle pen, float miterLimit);
Status GdipGetPenMode(Handle pen, out PenAlignment penMode);
Status GdipSetPenMode(Handle pen, PenAlignment penMode);
Status GdipGetPenTransform(Handle pen, out Handle matrix);
Status GdipSetPenTransform(Handle pen, Handle matrix);
Status GdipResetPenTransform(Handle pen);
Status GdipMultiplyPenTransform(Handle pen, Handle matrix, MatrixOrder order);
Status GdipTranslatePenTransform(Handle pen, float dx, float dy, MatrixOrder order);
Status GdipScalePenTransform(Handle pen, float sx, float sy, MatrixOrder order);
Status GdipRotatePenTransform(Handle pen, float angle, MatrixOrder order);
Status GdipGetPenColor(Handle pen, out uint argb);
Status GdipSetPenColor(Handle pen, int argb);
Status GdipGetPenWidth(Handle pen, out float width);
Status GdipSetPenWidth(Handle pen, float width);
Status GdipGetPenFillType(Handle pen, out PenType type);
Status GdipGetPenBrushFill(Handle pen, out Handle brush);
Status GdipSetPenBrushFill(Handle pen, Handle brush);
Status GdipGetPenDashStyle(Handle pen, out DashStyle dashstyle);
Status GdipSetPenDashStyle(Handle pen, DashStyle dashstyle);
Status GdipGetPenDashOffset(Handle pen, out float offset);
Status GdipSetPenDashOffset(Handle pen, float offset);
Status GdipGetPenDashCount(Handle pen, out int count);
Status GdipGetPenDashArray(Handle pen, float* dash, int count);
Status GdipSetPenDashArray(Handle pen, float* dash, int count);
Status GdipGetPenCompoundCount(Handle pen, out int count);
Status GdipGetPenCompoundArray(Handle pen, float* dash, int count);
Status GdipSetPenCompoundArray(Handle pen, float* dash, int count);

Status GdipCreateRegion(out Handle region);
Status GdipCreateRegionRect(ref RectF rect, out Handle region);
Status GdipCreateRegionRectI(ref Rect rect, out Handle region);
Status GdipCreateRegionPath(Handle path, out Handle region);
Status GdipCreateRegionHrgn(Handle hRgn, out Handle region);
Status GdipDeleteRegion(Handle region);
Status GdipSetInfinite(Handle region);
Status GdipSetEmpty(Handle region);
Status GdipCombineRegionRect(Handle region, ref RectF rect, CombineMode combineMode);
Status GdipCombineRegionRectI(Handle region, ref Rect rect, CombineMode combineMode);
Status GdipCombineRegionPath(Handle region, Handle path, CombineMode combineMode);
Status GdipCombineRegionRegion(Handle region, Handle region, CombineMode combineMode);
Status GdipTranslateRegion(Handle region, float dx, float dy);
Status GdipTranslateRegionI(Handle region, int dx, int dy);
Status GdipTransformRegion(Handle region, Handle matrix);
Status GdipGetRegionBounds(Handle region, Handle graphics, out RectF rect);
Status GdipGetRegionHRgn(Handle region, Handle graphics, out Handle hRgn);
Status GdipIsEmptyRegion(Handle region, Handle graphics, out int result);
Status GdipIsInfiniteRegion(Handle region, Handle graphics, out int result);
Status GdipIsEqualRegion(Handle region1, Handle region2, Handle graphics, out int result);
Status GdipIsVisibleRegionPoint(Handle region, float x, float y, Handle graphics, out int result);
Status GdipIsVisibleRegionRect(Handle region, float x, float y, float width, float height, Handle graphics, out int result);
Status GdipIsVisibleRegionPointI(Handle region, int x, int y, Handle graphics, out int result);
Status GdipIsVisibleRegionRectI(Handle region, int x, int y, int width, int height, Handle graphics, out int result);
Status GdipGetRegionScansCount(Handle region, out int count, Handle matrix);
Status GdipGetRegionScans(Handle region, RectF* rects, out int count, Handle matrix);

Status GdipDisposeImage(Handle image);
Status GdipImageForceValidation(Handle image);
Status GdipLoadImageFromFileICM(in wchar* filename, out Handle image);
Status GdipLoadImageFromFile(in wchar* filename, out Handle image);
Status GdipLoadImageFromStreamICM(IStream stream, out Handle image);
Status GdipLoadImageFromStream(IStream stream, out Handle image);
Status GdipGetImageRawFormat(Handle image, out GUID format);
Status GdipGetImageEncodersSize(out int numEncoders, out int size);
Status GdipGetImageEncoders(int numEncoders, int size, GpImageCodecInfo* encoders);
Status GdipGetImageDecodersSize(out int numDecoders, out int size);
Status GdipGetImageDecoders(int numDecoders, int size, GpImageCodecInfo* decoders);
Status GdipSaveImageToFile(Handle image, in wchar* filename, ref GUID clsidEncoder, GpEncoderParameters* encoderParams);
Status GdipSaveImageToStream(Handle image, IStream stream, ref GUID clsidEncoder, GpEncoderParameters* encoderParams);
Status GdipSaveAdd(Handle image, GpEncoderParameters* encoderParams);
Status GdipSaveAddImage(Handle image, Handle newImage, GpEncoderParameters* encoderParams);
Status GdipCloneImage(Handle image, out Handle cloneImage);
Status GdipGetImageType(Handle image, out int type);
Status GdipGetImageFlags(Handle image, out uint flags);
Status GdipGetImageWidth(Handle image, out int width);
Status GdipGetImageHeight(Handle image, out int height);
Status GdipGetImageHorizontalResolution(Handle image, out float resolution);
Status GdipGetImageVerticalResolution(Handle image, out float resolution);
Status GdipGetPropertyCount(Handle image, out uint numOfProperty);
Status GdipGetPropertyIdList(Handle image, int numOfProperty, int* list);
Status GdipGetImagePixelFormat(Handle image, out PixelFormat format);
Status GdipGetImageDimension(Handle image, out float width, out float height);
Status GdipGetImageThumbnail(Handle image, int thumbWidth, int thumbHeight, out Handle thumbImage, GpGetThumbnailImageAbort callback, void* callbackData);
Status GdipImageGetFrameCount(Handle image, ref GUID dimensionID, out uint count);
Status GdipImageSelectActiveFrame(Handle image, ref GUID dimensionID, uint frameCount);
Status GdipImageGetFrameDimensionsCount(Handle image, out uint count);
Status GdipImageGetFrameDimensionsList(Handle image, GUID* dimensionIDs, uint count);
Status GdipImageRotateFlip(Handle image, RotateFlipType rotateFlipType);
Status GdipGetPropertyItemSize(Handle image, int propId, out uint propSize);
Status GdipGetPropertyItem(Handle image, int propId, uint propSize, GpPropertyItem* buffer);
Status GdipSetPropertyItem(Handle image, ref GpPropertyItem buffer);
Status GdipRemovePropertyItem(Handle image, int propId);
Status GdipGetPropertySize(Handle image, out uint totalBufferSize, ref int numProperties);
Status GdipGetAllPropertyItems(Handle image, uint totalBufferSize, int numProperties, GpPropertyItem* allItems);
Status GdipGetImageBounds(Handle image, out RectF srcRect, out GraphicsUnit srcUnit);
Status GdipGetEncoderParameterListSize(Handle image, ref GUID clsidEncoder, out uint size);
Status GdipGetEncoderParameterList(Handle image, ref GUID clsidEncoder, uint size, GpEncoderParameters* buffer);
Status GdipGetImagePaletteSize(Handle image, out int size);
Status GdipGetImagePalette(Handle image, GpColorPalette* palette, int size);
Status GdipSetImagePalette(Handle image, GpColorPalette* palette);

Status GdipCreateBitmapFromScan0(int width, int height, int stride, PixelFormat format, ubyte* scan0, out Handle bitmap);
Status GdipCreateBitmapFromHBITMAP(Handle hbitmap, Handle hpalette, out Handle bitmap);
Status GdipCreateBitmapFromHICON(Handle hicon, out Handle bitmap);
Status GdipCreateBitmapFromFileICM(in wchar* fileName, out Handle bitmap);
Status GdipCreateBitmapFromFile(in wchar* fileName, out Handle bitmap);
Status GdipCreateBitmapFromStreamICM(IStream stream, out Handle bitmap);
Status GdipCreateBitmapFromStream(IStream stream, out Handle bitmap);
Status GdipCreateBitmapFromGraphics(int width, int height, Handle graphics, out Handle bitmap);
Status GdipCloneBitmapArea(float x, float y, float width, float height, PixelFormat format, Handle srcbitmap, out Handle dstbitmap);
Status GdipCloneBitmapAreaI(int x, int y, int width, int height, PixelFormat format, Handle srcbitmap, out Handle dstbitmap);
Status GdipBitmapGetPixel(Handle bitmap, int x, int y, out int color);
Status GdipBitmapSetPixel(Handle bitmap, int x, int y, int color);
Status GdipBitmapLockBits(Handle bitmap, ref Rect rect, ImageLockMode flags, PixelFormat format, out GpBitmapData lockedBitmapData);
Status GdipBitmapUnlockBits(Handle bitmap, ref GpBitmapData lockedBitmapData);
Status GdipBitmapSetResolution(Handle bitmap, float xdpi, float ydpi);
Status GdipCreateHICONFromBitmap(Handle bitmap, out Handle hbmReturn);
Status GdipCreateHBITMAPFromBitmap(Handle bitmap, out Handle hbmReturn, int background);
Status GdipCreateBitmapFromResource(Handle hInstance, in wchar* lpBitmapName, out Handle bitmap);

Status GdipCreateImageAttributes(out Handle imageattr);
Status GdipDisposeImageAttributes(Handle imageattr);
Status GdipSetImageAttributesColorMatrix(Handle imageattr, ColorAdjustType type, int enableFlag, GpColorMatrix* colorMatrix, GpColorMatrix* grayMatrix, ColorMatrixFlag flags);
Status GdipSetImageAttributesThreshold(Handle imageattr, ColorAdjustType type, int enableFlag, float threshold);
Status GdipSetImageAttributesGamma(Handle imageattr, ColorAdjustType type, int enableFlag, float gamma);
Status GdipSetImageAttributesNoOp(Handle imageattr, ColorAdjustType type, int enableFlag);
Status GdipSetImageAttributesColorKeys(Handle imageattr, ColorAdjustType type, int enableFlag, int colorLow, int colorHigh);
Status GdipSetImageAttributesOutputChannel(Handle imageattr, ColorAdjustType type, int enableFlag, ColorChannelFlag flags);
Status GdipSetImageAttributesOutputChannelColorProfile(Handle imageattr, ColorAdjustType type, int enableFlag, in wchar* colorProfileFilename);
Status GdipSetImageAttributesWrapMode(Handle imageattr, WrapMode wrap, int argb, int clamp);
Status GdipSetImageAttributesRemapTable(Handle imageattr, ColorAdjustType type, int enableFlag, uint mapSize, void* map);

Status GdipNewInstalledFontCollection(out Handle fontCollection);
Status GdipNewPrivateFontCollection(out Handle fontCollection);
Status GdipDeletePrivateFontCollection(Handle fontCollection);
Status GdipPrivateAddFontFile(Handle fontCollection, in wchar* filename);
Status GdipPrivateAddMemoryFont(Handle fontCollection, void* memory, int length);
Status GdipGetFontCollectionFamilyCount(Handle fontCollection, out int numFound);
Status GdipGetFontCollectionFamilyList(Handle fontCollection, int numSought, Handle* gpfamilies, out int numFound);

Status GdipCreateFontFamilyFromName(in wchar* name, Handle fontCollection, out Handle FontFamily);
Status GdipDeleteFontFamily(Handle FontFamily);
Status GdipCloneFontFamily(Handle FontFamily, out Handle clonedFontFamily);
Status GdipGetFamilyName(Handle family, in wchar* name, int language);
Status GdipGetGenericFontFamilyMonospace(out Handle nativeFamily);
Status GdipGetGenericFontFamilySerif(out Handle nativeFamily);
Status GdipGetGenericFontFamilySansSerif(out Handle nativeFamily);
Status GdipGetEmHeight(Handle family, FontStyle style, out short EmHeight);
Status GdipGetCellAscent(Handle family, FontStyle style, out short CellAscent);
Status GdipGetCellDescent(Handle family, FontStyle style, out short CellDescent);
Status GdipGetLineSpacing(Handle family, FontStyle style, out short LineSpacing);
Status GdipIsStyleAvailable(Handle family, FontStyle style, out int IsStyleAvailable);

Status GdipCreateFont(Handle fontFamily, float emSize, int style, int unit, out Handle font);
Status GdipCreateFontFromDC(Handle hdc, out Handle font);
Status GdipDeleteFont(Handle font);
Status GdipCloneFont(Handle font, out Handle cloneFont);
Status GdipGetFontSize(Handle font, out float size);
Status GdipGetFontHeight(Handle font, Handle graphics, out float height);
Status GdipGetFontHeightGivenDPI(Handle font, float dpi, out float height);
Status GdipGetFontStyle(Handle font, out FontStyle style);
Status GdipGetFontUnit(Handle font, out GraphicsUnit unit);
Status GdipGetFamily(Handle font, out Handle family);
Status GdipCreateFontFromLogfontW(Handle hdc, ref LOGFONTW logfont, out Handle font);
Status GdipGetLogFontW(Handle font, Handle graphics, out LOGFONTW logfontW);

Status GdipCreateStringFormat(StringFormatFlags formatAttributes, int language, out Handle format);
Status GdipDeleteStringFormat(Handle format);
Status GdipGetStringFormatFlags(Handle format, out StringFormatFlags flags);
Status GdipSetStringFormatFlags(Handle format, StringFormatFlags flags);
Status GdipGetStringFormatAlign(Handle format, out StringAlignment alignment);
Status GdipSetStringFormatAlign(Handle format, StringAlignment alignment);
Status GdipGetStringFormatLineAlign(Handle format, out StringAlignment alignment);
Status GdipSetStringFormatLineAlign(Handle format, StringAlignment alignment);
Status GdipGetStringFormatTrimming(Handle format, out StringTrimming trimming);
Status GdipSetStringFormatTrimming(Handle format, StringTrimming trimming);
Status GdipSetStringFormatMeasurableCharacterRanges(Handle format, int rangeCount, void* ranges);

Status GdipCreatePath(FillMode brushMode, out Handle path);
Status GdipCreatePath2(PointF*, ubyte*, int, FillMode, out Handle);
Status GdipCreatePath2I(Point*, ubyte*, int, FillMode, out Handle);
Status GdipDeletePath(Handle path);
Status GdipClonePath(Handle path, out Handle clonepath);
Status GdipResetPath(Handle path);
Status GdipGetPathFillMode(Handle path, out FillMode fillmode);
Status GdipSetPathFillMode(Handle path, FillMode fillmode);
Status GdipStartPathFigure(Handle path);
Status GdipClosePathFigure(Handle path);
Status GdipClosePathFigures(Handle path);
Status GdipSetPathMarker(Handle path);
Status GdipClearPathMarkers(Handle path);
Status GdipReversePath(Handle path);
Status GdipGetPathLastPoint(Handle path, out PointF lastPoint);
Status GdipAddPathLine(Handle path, float x2, float y1, float x2, float y2);
Status GdipAddPathLineI(Handle path, int x2, int y1, int x2, int y2);
Status GdipAddPathLine2(Handle path, PointF* points, int count);
Status GdipAddPathLine2I(Handle path, Point* points, int count);
Status GdipAddPathArc(Handle path, float x, float y, float width, float height, float startAngle, float sweepAngle);
Status GdipAddPathArcI(Handle path, int x, int y, int width, int height, float startAngle, float sweepAngle);
Status GdipAddPathBezier(Handle path, float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4);
Status GdipAddPathBezierI(Handle path, int x1, int y1, int x2, int y2, int x3, int y3, int x4, int y4);
Status GdipAddPathBeziers(Handle path, PointF* points, int count);
Status GdipAddPathBeziersI(Handle path, Point* points, int count);
Status GdipAddPathCurve(Handle path, PointF* points, int count);
Status GdipAddPathCurveI(Handle path, Point* points, int count);
Status GdipAddPathCurve2(Handle path, PointF* points, int count, float tension);
Status GdipAddPathCurve2I(Handle path, Point* points, int count, float tension);
Status GdipAddPathCurve3(Handle path, PointF* points, int count, int offset, int numberOfSegments, float tension);
Status GdipAddPathCurve3I(Handle path, Point* points, int count, int offset, int numberOfSegments, float tension);
Status GdipAddPathClosedCurve(Handle path, PointF* points, int count);
Status GdipAddPathClosedCurveI(Handle path, Point* points, int count);
Status GdipAddPathClosedCurve2(Handle path, PointF* points, int count, float tension);
Status GdipAddPathClosedCurve2I(Handle path, Point* points, int count, float tension);
Status GdipAddPathRectangle(Handle path, float x, float y, float width, float height);
Status GdipAddPathRectangleI(Handle path, int x, int y, int width, int height);
Status GdipAddPathRectangles(Handle path, RectF* rects, int count);
Status GdipAddPathRectanglesI(Handle path, Rect* rects, int count);
Status GdipAddPathEllipse(Handle path, float x, float y, float width, float height);
Status GdipAddPathEllipseI(Handle path, int x, int y, int width, int height);
Status GdipAddPathPie(Handle path, float x, float y, float width, float height, float startAngle, float sweepAngle);
Status GdipAddPathPieI(Handle path, int x, int y, int width, int height, float startAngle, float sweepAngle);
Status GdipAddPathPolygon(Handle path, PointF* points, int count);
Status GdipAddPathPolygonI(Handle path, Point* points, int count);
Status GdipAddPathPath(Handle path, Handle addingPath, int connect);
Status GdipAddPathString(Handle path, in wchar* str, int length, Handle family, FontStyle style, float emSize, ref RectF layoutRect, Handle format);
Status GdipAddPathStringI(Handle path, in wchar* str, int length, Handle family, FontStyle style, float emSize, ref Rect layoutRect, Handle format);
Status GdipTransformPath(Handle path, Handle matrix);
Status GdipGetPathWorldBounds(Handle path, out RectF bounds, Handle matrix, Handle pen);
Status GdipFlattenPath(Handle path, Handle matrix, float flatness);
Status GdipWidenPath(Handle path, Handle pen, Handle matrix, float flatness);
Status GdipWindingModeOutline(Handle path, Handle matrix, float flatness);
Status GdipWarpPath(Handle path, Handle matrix, PointF* points, int count, float srcx, float srcy, float srcwidth, float srcwidth, WarpMode warpMode, float flatness);
Status GdipGetPointCount(Handle path, out int count);
Status GdipGetPathTypes(Handle path, ubyte* types, int count);
Status GdipGetPathPoints(Handle path, PointF* points, int count);
Status GdipIsVisiblePathPoint(Handle path, float x, float y, Handle graphics, out int result);
Status GdipIsVisiblePathPointI(Handle path, int x, int y, Handle graphics, out int result);
Status GdipIsOutlineVisiblePathPoint(Handle path, float x, float y, Handle pen, Handle graphics, out int result);
Status GdipIsOutlineVisiblePathPointI(Handle path, int x, int y, Handle pen, Handle graphics, out int result);

Status GdipCreatePathIter(out Handle iterator, Handle path);
Status GdipDeletePathIter(Handle iterator);
Status GdipPathIterNextSubpath(Handle iterator, out int resultCount, out int startIndex, out int endIndex, out int isClosed);
Status GdipPathIterNextSubpathPath(Handle iterator, out int resultCount, Handle path, out int isClosed);
Status GdipPathIterNextPathType(Handle iterator, out int resultCount, out ubyte pathType, out int startIndex, out int endIndex);
Status GdipPathIterNextMarker(Handle iterator, out int resultCount, out int startIndex, out int endIndex);
Status GdipPathIterNextMarkerPath(Handle iterator, out int resultCount, Handle path);
Status GdipPathIterGetCount(Handle iterator, out int count);
Status GdipPathIterGetSubpathCount(Handle iterator, out int count);
Status GdipPathIterHasCurve(Handle iterator, out int hasCurve);
Status GdipPathIterRewind(Handle iterator);
Status GdipPathIterEnumerate(Handle iterator, out int resultCount, PointF* points, ubyte* types, int count);
Status GdipPathIterCopyData(Handle iterator, out int resultCount, PointF* points, ubyte* types, int startIndex, int endIndex);

Status GdipCreatePathGradient(PointF* points, int count, WrapMode wrapMode, out Handle polyGradient);
Status GdipCreatePathGradientI(Point* points, int count, WrapMode wrapMode, out Handle polyGradient);
Status GdipCreatePathGradientFromPath(Handle path, out Handle polyGradient);
Status GdipGetPathGradientCenterColor(Handle brush, out int colors);
Status GdipSetPathGradientCenterColor(Handle brush, int colors);
Status GdipGetPathGradientSurroundColorCount(Handle brush, out int count);
Status GdipGetPathGradientSurroundColorsWithCount(Handle brush, int* color, ref int count);
Status GdipSetPathGradientSurroundColorsWithCount(Handle brush, int* color, ref int count);
Status GdipGetPathGradientCenterPoint(Handle brush, ref PointF point);
Status GdipSetPathGradientCenterPoint(Handle brush, ref PointF point);
Status GdipGetPathGradientRect(Handle brush, ref RectF rect);
Status GdipGetPathGradientBlendCount(Handle brush, out int count);
Status GdipGetPathGradientBlend(Handle brush, float* blend, float* positions, int count);
Status GdipSetPathGradientBlend(Handle brush, float* blend, float* positions, int count);
Status GdipGetPathGradientPresetBlendCount(Handle brush, out int count);
Status GdipGetPathGradientPresetBlend(Handle brush, int* blend, float* positions, int count);
Status GdipSetPathGradientPresetBlend(Handle brush, int* blend, float* positions, int count);
Status GdipSetPathGradientSigmaBlend(Handle brush, float focus, float scale);
Status GdipSetPathGradientLinearBlend(Handle brush, float focus, float scale);
Status GdipGetPathGradientTransform(Handle brush, out Handle matrix);
Status GdipSetPathGradientTransform(Handle brush, Handle matrix);
Status GdipResetPathGradientTransform(Handle brush);
Status GdipMultiplyPathGradientTransform(Handle brush, Handle matrix, MatrixOrder order);
Status GdipRotatePathGradientTransform(Handle brush, float angle, MatrixOrder order);
Status GdipTranslatePathGradientTransform(Handle brush, float dx, float dy, MatrixOrder order);
Status GdipScalePathGradientTransform(Handle brush, float sx, float sy, MatrixOrder order);
Status GdipGetPathGradientFocusScales(Handle brush, out float xScale, out float yScale);
Status GdipSetPathGradientFocusScales(Handle brush, float xScale, float yScale);
Status GdipGetPathGradientWrapMode(Handle brush, out WrapMode wrapMode);
Status GdipSetPathGradientWrapMode(Handle brush, WrapMode wrapMode);

extern(D):

void GdipDeleteMatrixSafe(Handle matrix) {
  if (!isShutdown)
    GdipDeleteMatrix(matrix);
}

void GdipDeleteGraphicsSafe(Handle graphics) {
  if (!isShutdown)
    GdipDeleteGraphics(graphics);
}

void GdipDeletePenSafe(Handle pen) {
  if (!isShutdown)
    GdipDeletePen(pen);
}

void GdipDeleteBrushSafe(Handle brush) {
  if (!isShutdown)
    GdipDeleteBrush(brush);
}

void GdipDisposeImageSafe(Handle image) {
  if (!isShutdown)
    GdipDisposeImage(image);
}

void GdipDisposeImageAttributesSafe(Handle imageattr) {
  if (!isShutdown)
    GdipDisposeImageAttributes(imageattr);
}

void GdipDeletePathSafe(Handle path) {
  if (!isShutdown)
    GdipDeletePath(path);
}

void GdipDeletePathIterSafe(Handle iterator) {
  if (!isShutdown)
    GdipDeletePathIter(iterator);
}

void GdipDeleteRegionSafe(Handle region) {
  if (!isShutdown)
    GdipDeleteRegion(region);
}

void GdipDeleteFontFamilySafe(Handle family) {
  if (!isShutdown)
    GdipDeleteFontFamily(family);
}

void GdipDeletePrivateFontCollectionSafe(Handle fontCollection) {
  if (!isShutdown)
    GdipDeletePrivateFontCollection(fontCollection);
}

void GdipDeleteFontSafe(Handle font) {
  if (!isShutdown)
    GdipDeleteFont(font);
}

void GdipDeleteStringFormatSafe(Handle format) {
  if (!isShutdown)
    GdipDeleteStringFormat(format);
}

private uint initToken;
private bool isShutdown;

private void startupGdiplus() {
  static GdiplusStartupInput input = { 1, null, 0, 0 };
  static GdiplusStartupOutput output;

  GdiplusStartup(initToken, input, output);
}

private void shutdownGdiplus() {
  core.memory.GC.collect();
  isShutdown = true;

  GdiplusShutdown(initToken);
}

package Throwable statusException(Status status) {
  switch (status) {
    case Status.GenericError:
      return new Exception("A generic error occurred in GDI+.");
    case Status.InvalidParameter:
      return new ArgumentException("Parameter is not valid.");
    case Status.OutOfMemory:
      return new OutOfMemoryError;
    case Status.ObjectBusy:
      return new InvalidOperationException("Object is currently in use elsewhere.");
    case Status.InsufficientBuffer:
      return new OutOfMemoryError;
    case Status.NotImplemented:
      return new NotImplementedException("Not implemented.");
    case Status.Win32Error:
      return new Exception("A generic error occurred in GDI+.");
    case Status.WrongState:
      return new InvalidOperationException("Bitmap region is already locked.");
    case Status.Aborted:
      return new Exception("Function was ended.");
    case Status.AccessDenied:
      return new Exception("File access is denied.");
    case Status.UnknownImageFormat:
      return new ArgumentException("Image format is unknown.");
    case Status.FontFamilyNotFound:
      return new ArgumentException("Font cannot be found.");
    case Status.FontStyleNotFound:
      return new ArgumentException("Font does not support style.");
    case Status.NotTrueTypeFont:
      return new ArgumentException("Only true type fonts are supported.");
    case Status.UnsupportedGdiplusVersion:
      return new Exception("Current version of GDI+ does not support this feature.");
    case Status.GdiplusNotInitialized:
      return new Exception("GDI+ is not initialized.");
    case Status.PropertyNotFound:
      return new ArgumentException("Property cannot be found.");
    case Status.PropertyNotSupported:
      return new ArgumentException("Property is not supported.");
    default:
  }
  return new Exception("Unknown GDI+ error occurred.");
}
