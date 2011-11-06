/**
 * Copyright: (c) 2008 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.media.geometry;

private import juno.base.math, // min, max
  std.math; // ceil, round

/**
 */
struct Point {

  int x; ///
  int y; ///

  /**
   */
  static Point empty = { 0, 0 };

  /**
   */
  static Point opCall(int x, int y) {
    Point self;
    self.x = x, self.y = y;
    return self;
  }

  bool opEquals(Point other) {
    return x == other.x && y == other.y;
  }

  hash_t toHash() {
    return x ^ y;
  }

  /**
   */
  static Point ceiling(PointF value) {
    return Point(cast(int).ceil(value.x), cast(int).ceil(value.y));
  }

  /**
   */
  static Point round(PointF value) {
    return Point(cast(int).round(value.x), cast(int).round(value.y));
  }

  /**
   */
  void offset(Point p) {
    offset(p.x, p.y);
  }

  /**
   */
  void offset(int x, int y) {
    this.x += x;
    this.y += y;
  }

  /**
   */
  bool isEmpty() {
    return x == 0 && y == 0;
  }

  /**
   */
  Point opAdd(Size sz) {
    return Point(x + sz.width, y + sz.height);
  }

  void opAddAssign(Size sz) {
    x += sz.width;
    y += sz.height;
  }

  /**
   */
  Point opSub(Size sz) {
    return Point(x - sz.width, y - sz.height);
  }

  void opSubAssign(Size sz) {
    x -= sz.width;
    y -= sz.height;
  }

}

/**
 */
struct PointF {

  float x = 0; ///
  float y = 0; ///

  /**
   */
  static PointF empty = { 0f, 0f };

  /**
   */
  static PointF opCall(float x, float y) {
    PointF self;
    self.x = x, self.y = y;
    return self;
  }

  /**
   */
  static PointF opCall(Point p) {
    return PointF(cast(float)p.x, cast(float)p.y);
  }

  bool opEquals(PointF other) {
    return x == other.x && y == other.y;
  }

  /**
   */
  bool isEmpty() {
    return x == 0f && y == 0f;
  }

  /**
   */
  PointF opAdd(SizeF sz) {
    return PointF(x + sz.width, y + sz.height);
  }

  void opAddAssign(SizeF sz) {
    x += sz.width;
    y += sz.height;
  }

  /**
   */
  PointF opSub(SizeF sz) {
    return PointF(x - sz.width, y - sz.height);
  }

  void opSubAssign(SizeF sz) {
    x -= sz.width;
    y -= sz.height;
  }

}

/**
 */
struct Size {

  int width; ///
  int height; ///

  /**
   */
  static Size empty = { 0, 0 };

  /**
   */
  static Size opCall(int width, int height) {
    Size self;
    self.width = width, self.height = height;
    return self;
  }

  bool opEquals(Size other) {
    return width == other.width && height == other.height;
  }

  hash_t toHash() {
    return width ^ height;
  }

  /**
   */
  static Size ceiling(SizeF value) {
    return Size(cast(int).ceil(value.height), cast(int).ceil(value.height));
  }

  /**
   */
  static Size round(SizeF value) {
    return Size(cast(int).round(value.width), cast(int).round(value.height));
  }

  /**
   */
  static Size truncate(SizeF value) {
    return Size(cast(int)value.width, cast(int)value.height);
  }

  /**
   */
  bool isEmpty() {
    return width == 0 && height == 0;
  }

  /**
   */
  Size opAdd(Size other) {
    return Size(width + other.width, height + other.height);
  }

  void opAddAssign(Size other) {
    width += other.width;
    height += other.height;
  }

  /**
   */
  Size opSub(Size other) {
    return Size(width - other.width, height - other.height);
  }

  void opSubAssign(Size other) {
    width -= other.width;
    height -= other.height;
  }

}

/**
 */
struct SizeF {

  float width = 0; ///
  float height = 0; ///

  /**
   */
  static SizeF empty = { 0f, 0f };

  /**
   */
  static SizeF opCall(float width, float height) {
    SizeF self;
    self.width = width, self.height = height;
    return self;
  }

  /**
   */
  static SizeF opCall(Size sz) {
    return SizeF(cast(float)sz.width, cast(float)sz.height);
  }

  bool opEquals(SizeF other) {
    return width == other.width && height == other.height;
  }

  /**
   */
  SizeF opAdd(SizeF sz) {
    return SizeF(width + sz.width, height + sz.height);
  }

  void opAddAssign(SizeF sz) {
    width += sz.width;
    height += sz.height;
  }

  /**
   */
  SizeF opSub(SizeF sz) {
    return SizeF(width - sz.width, height - sz.height);
  }

  void opSubAssign(SizeF sz) {
    width -= sz.width;
    height -= sz.height;
  }

  /**
   */
  bool isEmpty() {
    return width == 0f && height == 0f;
  }

}

/**
 */
struct Rect {

  int x; ///
  int y; ///
  int width; ///
  int height; ///

  /**
   */
  static Rect empty = { 0, 0, 0, 0 };

  /**
   */
  static Rect opCall(int x, int y, int width, int height) {
    Rect this_;
    this_.x = x, this_.y = y, this_.width = width, this_.height = height;
    return this_;
  }

  /**
   */
  static Rect opCall(Point location, Size size) {
    return Rect(location.x, location.y, size.width, size.height);
  }

  bool opEquals(Rect other) {
    return x == other.x && y == other.y && width == other.width && height == other.height;
  }

  hash_t toHash() {
    return x | ((y << 13) | (y >> 19)) ^ ((width << 26) | (width >> 6)) | ((height << 7) | (height >> 25));
  }

  /**
   */
  static Rect fromLTRB(int left, int top, int right, int bottom) {
    return Rect(left, top, right - left, bottom - top);
  }

  /**
   */
  static Rect ceiling(RectF value) {
    return Rect(cast(int).ceil(value.x), cast(int).ceil(value.y), cast(int).ceil(value.width), cast(int).ceil(value.height));
  }

  /**
   */
  static Rect round(RectF value) {
    return Rect(cast(int).round(value.x), cast(int).round(value.y), cast(int).round(value.width), cast(int).round(value.height));
  }

  /**
   */
  static Rect truncate(RectF value) {
    return Rect(cast(int)value.x, cast(int)value.y, cast(int)value.width, cast(int)value.height);
  }

  /**
   */
  static Rect unionRects(Rect a, Rect b) {
    int left = min(a.x, b.x);
    int right = max(a.x + a.width, b.x + b.width);
    int top = min(a.y, b.y);
    int bottom = max(a.y + a.height, b.y + b.height);
    return Rect(left, top, right - left, bottom - top);
  }

  /**
   */
  bool contains(Point pt) {
    return contains(pt.x, pt.y);
  }

  /**
   */
  bool contains(int x, int y) {
    return this.x <= x && x < this.right && this.y <= y && y < this.bottom;
  }

  /**
   */
  bool contains(Rect rect) {
    return x <= rect.x && rect.x + rect.width <= x + width && y <= rect.y && rect.y + rect.height <= y + height;
  }

  /**
   */
  static Rect inflate(Rect rect, int x, int y) {
    Rect r = rect;
    r.inflate(x, y);
    return r;
  }

  /**
   */
  void inflate(Size size) {
    inflate(size.width, size.height);
  }

  /**
   */
  void inflate(int width, int height) {
    this.x -= width;
    this.y -= height;
    this.width += width * 2;
    this.height += height * 2;
  }

  /**
   */
  void offset(Point pos) {
    offset(pos.x, pos.y);
  }

  /**
   */
  void offset(int x, int y) {
    this.x += x;
    this.y += y;
  }

  /**
   */
  bool intersectsWith(Rect rect) {
    return rect.x < x + width && x < rect.x + rect.width && rect.y < y + height && y < rect.y + rect.height;
  }

  /**
   */
  static Rect intersect(Rect a, Rect b) {
    int left = max(a.x, b.x);
    int right = min(a.x + a.width, b.x + b.width);
    int top = max(a.y, b.y);
    int bottom = min(a.y + a.height, b.y + b.height);
    if (right >= left && bottom >= top)
      return Rect(left, top, right - left, bottom - top);
    return Rect.empty;
  }

  /**
   */
  void intersect(Rect rect) {
    Rect r = intersect(rect, this);
    x = r.x;
    y = r.y;
    width = r.width;
    height = r.height;
  }

  /**
   */
  int left() {
    return x;
  }

  /**
   */
  int top() {
    return y;
  }

  /**
   */
  int bottom() {
    return y + height;
  }

  /**
   */
  int right() {
    return x + width;
  }

  /**
   */
  void location(Point value) {
    x = value.x;
    y = value.y;
  }

  /**
   * ditto
   */
  Point location() {
    return Point(x, y);
  }

  /**
   */
  void size(Size value) {
    width = value.width;
    height = value.height;
  }

  /**
   * ditto
   */
  Size size() {
    return Size(width, height);
  }

  /**
   */
  bool isEmpty() {
    return x == 0 && y == 0 && width == 0 && height == 0;
  }

}

/**
 */
struct RectF {

  float x = 0f; ///
  float y = 0f; ///
  float width = 0f; ///
  float height = 0f; ///

  /**
   */
  static RectF empty = { 0f, 0f, 0f, 0f };

  /**
   */
  static RectF opCall(float x, float y, float width, float height) {
    RectF self;
    self.x = x, self.y = y, self.width = width, self.height = height;
    return self;
  }

  /**
   */
  static RectF fromLTRB(float left, float top, float right, float bottom) {
    return RectF(left, top, right - left, bottom - top);
  }

  /**
   */
  bool contains(PointF pt) {
    return contains(pt.x, pt.y);
  }

  /**
   */
  bool contains(float x, float y) {
    return this.x <= x && x < this.x + this.width && this.y <= y && y < this.y + this.height;
  }

  /**
   */
  bool contains(RectF rect) {
    return x <= rect.x && rect.x + rect.width <= x + width && y <= rect.y && rect.y + rect.height <= y + height;
  }

  /**
   */
  static RectF inflate(RectF rect, float x, float y) {
    RectF r = rect;
    r.inflate(x, y);
    return r;
  }

  /**
   */
  void inflate(SizeF size) {
    inflate(size.width, size.height);
  }

  /**
   */
  void inflate(float width, float height) {
    this.x -= width;
    this.y -= height;
    this.width += width * 2f;
    this.height += height * 2f;
  }

  /**
   */
  void offset(PointF pos) {
    offset(pos.x, pos.y);
  }

  /**
   */
  void offset(float x, float y) {
    this.x += x;
    this.y += y;
  }

  /**
   */
  bool intersectsWith(RectF rect) {
    return rect.x < x + width && x < rect.x + rect.width && rect.y < y + height && y < rect.y + rect.height;
  }

  /**
   */
  static RectF intersect(RectF a, RectF b) {
    float left = max(a.x, b.x);
    float right = min(a.x + a.width, b.x + b.width);
    float top = max(a.y, b.y);
    float bottom = min(a.y + a.height, b.y + b.height);
    if (right >= left && bottom >= top)
      return RectF(left, top, right - left, bottom - top);
    return RectF.empty;
  }

  /**
   */
  void intersect(RectF rect) {
    RectF r = intersect(rect, this);
    x = r.x;
    y = r.y;
    width = r.width;
    height = r.height;
  }

  /**
   */
  float left() {
    return x;
  }

  /**
   */
  float top() {
    return y;
  }

  /**
   */
  float right() {
    return x + width;
  }

  /**
   */
  float bottom() {
    return y + height;
  }

  /**
   */
  PointF location() {
    return PointF(x, y);
  }

  /**
   * ditto
   */
  void location(PointF value) {
    x = value.x;
    y = value.y;
  }

  /**
   */
  SizeF size() {
    return SizeF(width, height);
  }

  /**
   * ditto
   */
  void size(SizeF value) {
    width = value.width;
    height = value.height;
  }

}
