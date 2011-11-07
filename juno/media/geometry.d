/**
 * Copyright: (c) 2009 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.media.geometry;

import std.math, // ceil, round
  std.string;
version(D_Version2) {
  import std.algorithm : min, max;
}
else {
  import juno.base.math : min, max;
}

/**
 * Represents a pair of x- and y-coordinates that defines a point in a two-dimensional plane.
 */
struct Point {

  int x; /// Gets or sets the _x-coordinate.
  int y; /// Gets or sets the _y-coordinate.

  static Point empty = { 0, 0 }; // Represents a Point that has x and y values set to zero.

  /**
   * Initializes a new instance with the specified coordintates.
   * Params:
   *   x = The horizontal position.
   *   y = The vertical position.
   */
  static Point opCall(int x, int y) {
    Point self;
    self.x = x, self.y = y;
    return self;
  }

  /**
   * Tests whether the specified Point has the same coordinates as this instance.
   * Params: other = The Point to test.
   * Returns: true if other has the same x- and y-coordinates as this instance; otherwise, false.
   */
  bool equals(Point other) {
    return x == other.x && y == other.y;
  }

  /// ditto
  bool opEquals(Point other) {
    return x == other.x && y == other.y;
  }

  hash_t toHash() {
    return x ^ y;
  }

  /**
   * Converts the specified PointF to a Point by rounding the PointF values to the next highest integer.
   * Params: value = The PointF to convert.
   * Returns: The Point this method converts to.
   */
  static Point ceiling(PointF value) {
    return Point(cast(int).ceil(value.x), cast(int).ceil(value.y));
  }

  /**
   * Converts the specified PointF to a Point by rounding the Point values to the nearest integer.
   * Params: value = The PointF to convert.
   * Returns: The Point this method converts to.
   */
  static Point round(PointF value) {
    return Point(cast(int).round(value.x), cast(int).round(value.y));
  }

  /**
   * Translates this instance by the specified amount.
   * Params: p = The Point used to _offset this instance.
   */
  void offset(Point p) {
    offset(p.x, p.y);
  }

  /**
   * Translates this instance by the specified amount.
   * Params:
   *   x = The amount to _offset the _x-coordinate.
   *   y = The amount to _offset the _y-coordinate.
   */
  void offset(int x, int y) {
    this.x += x;
    this.y += y;
  }

  /**
   * Gets a value indicating whether this instance is empty.
   * Returns: true if both x and y are zero; otherwise, false.
   */
  bool isEmpty() {
    return x == 0 && y == 0;
  }

  /**
   * Adds the specified Size to the specified Point.
   * Params:
   *   pt = The Point to _add.
   *   sz = The Size to _add.
   * Returns: The Point that is the result of the addition operation.
   */
  static Point add(Point pt, Size sz) {
    return Point(pt.x + sz.width, pt.y + sz.height);
  }

  /// ditto
  Point opAdd(Size sz) {
    return Point(x + sz.width, y + sz.height);
  }

  /// ditto
  void opAddAssign(Size sz) {
    x += sz.width;
    y += sz.height;
  }

  /**
   * Subtracts the specified Size from the specified Point.
   * Params:
   *   pt = The Point to be subtracted from.
   *   sz = The Size to _subtract from the Point.
   * Returns: The Point that is the result of the subtraction operation.
   */
  static Point subtract(Point pt, Size sz) {
    return Point(pt.x - sz.width, pt.y - sz.height);
  }

  /// ditto
  Point opSub(Size sz) {
    return Point(x - sz.width, y - sz.height);
  }

  /// ditto
  void opSubAssign(Size sz) {
    x -= sz.width;
    y -= sz.height;
  }

  string toString() {
    return format("{x=%s,y=%s}", x, y);
  }

}

/**
 * Represents a pair of floating-point x- and y-coordinates that defines a point in a two-dimensional plane.
 */
struct PointF {

  float x = 0f; /// Gets or sets the _x-coordinate.
  float y = 0f; /// Gets or sets the _y-coordinate.

  static PointF empty = { 0f, 0f }; // Represents a Point that has x and y values set to zero.

  /**
   * Initializes a new instance with the specified coordintates.
   * Params:
   *   x = The horizontal position.
   *   y = The vertical position.
   */
  static PointF opCall(float x, float y) {
    PointF self;
    self.x = x, self.y = y;
    return self;
  }

  /**
   * Converts the specified Point structure to a PointF structure.
   * Params: p = The Point to be converted.
   * Returns: The PointF that results from the conversion.
   */
  static PointF opCall(Point p) {
    return PointF(cast(float)p.x, cast(float)p.y);
  }

  /**
   * Tests whether the specified PointF has the same coordinates as this instance.
   * Params: other = The PointF to test.
   * Returns: true if other has the same x- and y-coordinates as this instance; otherwise, false.
   */
  bool equals(PointF other) {
    return x == other.x && y == other.y;
  }

  /// ditto
  bool opEquals(PointF other) {
    return x == other.x && y == other.y;
  }

  /**
   * Gets a value indicating whether this instance is empty.
   * Returns: true if both x and y are zero; otherwise, false.
   */
  bool isEmpty() {
    return x == 0f && y == 0f;
  }

  /**
   * Adds the specified SizeF to the specified PointF.
   * Params:
   *   pt = The PointF to _add.
   *   sz = The SizeF to _add.
   * Returns: The PointF that is the result of the addition operation.
   */
  static PointF add(PointF pt, SizeF sz) {
    return PointF(pt.x + sz.width, pt.y + sz.height);
  }

  /// ditto
  PointF opAdd(SizeF sz) {
    return PointF(x + sz.width, y + sz.height);
  }

  /// ditto
  void opAddAssign(SizeF sz) {
    x += sz.width;
    y += sz.height;
  }

  /**
   * Subtracts the specified SizeF from the specified PointF.
   * Params:
   *   pt = The PointF to be subtracted from.
   *   sz = The SizeF to _subtract from the Point.
   * Returns: The PointF that is the result of the subtraction operation.
   */
  static PointF subtract(PointF pt, SizeF sz) {
    return PointF(pt.x - sz.width, pt.y - sz.height);
  }

  /// ditto
  PointF opSub(SizeF sz) {
    return PointF(x - sz.width, y - sz.height);
  }

  /// ditto
  void opSubAssign(SizeF sz) {
    x -= sz.width;
    y -= sz.height;
  }

  string toString() {
    return format("{x=%s,y=%s}", x, y);
  }

}

/**
 * Represents a pair of integers, typically the width and height of a rectangle.
 */
struct Size {

  int width; /// Gets or sets the horizontal component.
  int height; /// Gets or sets the vertical component.

  static Size empty = { 0, 0 }; /// Represents a Size that has width and height values set to zero.

  /**
   * Initializes a new instance from the specified dimensions.
   * Params:
   *   width = The horizontal component.
   *   height = The vertical component.
   */
  static Size opCall(int width, int height) {
    Size self;
    self.width = width, self.height = height;
    return self;
  }

  /**
   * Tests whether the specified Size has the same dimensions as this instance.
   * Params: other = The Size to test.
   * Returns: true if other has the same width and height as this instance; otherwise, false.
   */
  bool equals(Size other) {
    return width == other.width && height == other.height;
  }

  /// ditto
  bool opEquals(Size other) {
    return width == other.width && height == other.height;
  }

  hash_t toHash() {
    return width ^ height;
  }

  /**
   * Converts the specified SizeF structure to a Size structure by rounding the values of the Size structure to the next highest integer.
   * Params: value = The SizeF structure to convert.
   * Returns: The Size structure this method converts to.
   */
  static Size ceiling(SizeF value) {
    return Size(cast(int).ceil(value.height), cast(int).ceil(value.height));
  }

  /**
   * Converts the specified SizeF structure to a Size structure by rounding the values of the SizeF structure to the nearest integer.
   * Params: The SizeF structure to convert.
   * Returns: The Size structure this methods converts to.
   */
  static Size round(SizeF value) {
    return Size(cast(int).round(value.width), cast(int).round(value.height));
  }

  /**
   * Converts the specified SizeF structure to a Size structure by truncating the values of the SizeF structure to the next lowest integer values.
   * Params: value = The SizeF structure to convert.
   * Returns: The Size structure this method converts to.
   */
  static Size truncate(SizeF value) {
    return Size(cast(int)value.width, cast(int)value.height);
  }

  /**
   * Tests whether this instance has width and height set to zero.
   * Returns: true if both width and height are zero; otherwise, false.
   */
  bool isEmpty() {
    return width == 0 && height == 0;
  }

  /**
   * Adds the width and height of one Size structure to the width and height of another.
   * Params:
   *   sz1 = The first Size to _add.
   *   sz2 = The second Size to _add.
   * Returns: A Size structure that is the result of the addition operation.
   */
  static Size add(Size sz1, Size sz2) {
    return Size(sz1.width + sz2.width, sz1.height + sz2.height);
  }

  /// ditto
  Size opAdd(Size other) {
    return Size(width + other.width, height + other.height);
  }

  /// ditto
  void opAddAssign(Size other) {
    width += other.width;
    height += other.height;
  }

  /**
   * Subtracts the width and height of one Size structure from the width and height of another.
   * Params:
   *   sz1 = The first Size to _subtract.
   *   sz2 = The second Size to _subtract.
   * Returns: A Size structure that is the result of the subtraction operation.
   */
  static Size subtract(Size sz1, Size sz2) {
    return Size(sz1.width - sz2.width, sz1.height - sz2.height);
  }

  /// ditto
  Size opSub(Size other) {
    return Size(width - other.width, height - other.height);
  }

  /// ditto
  void opSubAssign(Size other) {
    width -= other.width;
    height -= other.height;
  }

  string toString() {
    return format("{width=%s,height=%s}", width, height);
  }

}

/**
 * Represents a pair of floating-point numbers, typically the width and height of a rectangle.
 */
struct SizeF {

  float width = 0f; /// Gets or sets the horizontal component.
  float height = 0f; /// Gets or sets the vertical component.

  static SizeF empty = { 0f, 0f }; /// Represents a Size that has width and height values set to zero.

  /**
   * Initializes a new instance from the specified dimensions.
   * Params:
   *   width = The horizontal component.
   *   height = The vertical component.
   */
  static SizeF opCall(float width, float height) {
    SizeF self;
    self.width = width, self.height = height;
    return self;
  }

  /**
   * Converts the specified Size to a SizeF.
   * Params: sz = The Size to convert.
   * Returns: The SizeF structure to which this operator converts.
   */
  static SizeF opCall(Size sz) {
    return SizeF(cast(float)sz.width, cast(float)sz.height);
  }

  /**
   * Tests whether the specified SizeF has the same dimensions as this instance.
   * Params: other = The SizeF to test.
   * Returns: true if other has the same width and height as this instance; otherwise, false.
   */
  bool equals(SizeF other) {
    return width == other.width && height == other.height;
  }

  /// ditto
  bool opEquals(SizeF other) {
    return width == other.width && height == other.height;
  }

  /**
   * Tests whether this instance has width and height set to zero.
   * Returns: true if both width and height are zero; otherwise, false.
   */
  bool isEmpty() {
    return width == 0f && height == 0f;
  }

  /**
   * Adds the width and height of one FSize structure to the width and height of another.
   * Params:
   *   sz1 = The first SizeF to _add.
   *   sz2 = The second SizeF to _add.
   * Returns: A SizeF structure that is the result of the addition operation.
   */
  static SizeF add(SizeF sz1, SizeF sz2) {
    return SizeF(sz1.width + sz2.width, sz1.height + sz2.height);
  }

  /// ditto
  SizeF opAdd(SizeF sz) {
    return SizeF(width + sz.width, height + sz.height);
  }

  /// ditto
  void opAddAssign(SizeF sz) {
    width += sz.width;
    height += sz.height;
  }

  /**
   * Subtracts the width and height of one SizeF structure from the width and height of another.
   * Params:
   *   sz1 = The first SizeF to _subtract.
   *   sz2 = The second SizeF to _subtract.
   * Returns: A SizeF structure that is the result of the subtraction operation.
   */
  static SizeF subtract(SizeF sz1, SizeF sz2) {
    return SizeF(sz1.width - sz2.width, sz1.height - sz2.height);
  }

  /// ditto
  SizeF opSub(SizeF sz) {
    return SizeF(width - sz.width, height - sz.height);
  }

  /// ditto
  void opSubAssign(SizeF sz) {
    width -= sz.width;
    height -= sz.height;
  }

  string toString() {
    return format("{width=%s,height=%s}", width, height);
  }

}

/**
 * Represents a set of four integers that define the location and size of a rectangle.
 */
struct Rect {

  int x; /// Gets or sets the _x-coordinate.
  int y; /// Gets of sets the _y-coordinate.
  int width; /// Gets or sets the _width component.
  int height; /// Gets or sets the _height component.

  static Rect empty = { 0, 0, 0, 0 }; /// Represents an uninitialized Rect structure.

  /**
   * Initializes a new instance with the specified location and size.
   * Params:
   *   x = The _x-coordinate.
   *   y = The _y-coordinate.
   *   width = The _width.
   *   height = The _height.
   */
  static Rect opCall(int x, int y, int width, int height) {
    Rect this_;
    this_.x = x, this_.y = y, this_.width = width, this_.height = height;
    return this_;
  }

  /**
   * Initializes a new instance with the specified _location and _size.
   * Params:
   *   location = The upper-left corner.
   *   size = The width and height.
   */
  static Rect opCall(Point location, Size size) {
    return Rect(location.x, location.y, size.width, size.height);
  }

  /**
   * Creates a Rect structure width the specified edge locations.
   * Params:
   *   left = The x-coordinate of the upper-_left corner.
   *   top = The y-coordinate of the upper-_left corner.
   *   right = The x-coordinate of the lower-_right corner.
   *   bottom = The y-coordinate of the lower-_right corner.
   * Returns: The new Rect that this method creates.
   */
  static Rect fromLTRB(int left, int top, int right, int bottom) {
    return Rect(left, top, right - left, bottom - top);
  }

  /**
   * Tests whether the specified Rect structure has the same location and size as this instance.
   * Params: other = The Rect to test.
   * Returns: true if the x, y, width and height properties of other are equal to the corresponding properties of this instance; otherwise, false.
   */
  bool equals(Rect other) {
    return x == other.x && y == other.y && width == other.width && height == other.height;
  }

  /// ditto
  bool opEquals(Rect other) {
    return x == other.x && y == other.y && width == other.width && height == other.height;
  }

  hash_t toHash() {
    return x | ((y << 13) | (y >> 19)) ^ ((width << 26) | (width >> 6)) | ((height << 7) | (height >> 25));
  }

  /**
   * Converts the specified RectF structure to a Rect structure by rounding the RectF values to the next highest integers.
   * Params: value = The RectF to convert.
   * Returns: The Rect structure that this method converts to.
   */
  static Rect ceiling(RectF value) {
    return Rect(cast(int).ceil(value.x), cast(int).ceil(value.y), cast(int).ceil(value.width), cast(int).ceil(value.height));
  }

  /**
   * Converts the specified RectF structure to a Rect structure by rounding the RectF values to the nearest integers.
   * Params: value = The RectF to convert.
   * Returns: The Rect structure that this method converts to.
   */
  static Rect round(RectF value) {
    return Rect(cast(int).round(value.x), cast(int).round(value.y), cast(int).round(value.width), cast(int).round(value.height));
  }

  /**
   * Converts the specified RectF structure to a Rect structure by truncating the RectF values.
   * Params: value = The RectF to convert.
   * Returns: The Rect structure that this method converts to.
   */
  static Rect truncate(RectF value) {
    return Rect(cast(int)value.x, cast(int)value.y, cast(int)value.width, cast(int)value.height);
  }

  /**
   * Gets a Rect structure containing the union of two Rect structures.
   * Params:
   *   a = A Rect to union.
   *   b = A Rect to union.
   * Returns: A Rect structure that bounds the union of the two Rect structures.
   */
  static Rect unionRects(Rect a, Rect b) {
    int left = min(a.x, b.x);
    int right = max(a.x + a.width, b.x + b.width);
    int top = min(a.y, b.y);
    int bottom = max(a.y + a.height, b.y + b.height);
    return Rect(left, top, right - left, bottom - top);
  }

  /**
   * Determines if the specified point is contained within this instance.
   * Params: pt = The Point to test.
   * Returns: true if the point represented by pt is contained within this instance; otherwise, false.
   */
  bool contains(Point pt) {
    return contains(pt.x, pt.y);
  }

  /**
   * Determines if the specified point is contained within this instance.
   * Params:
   *   x = The x-coordinate of the point to test.
   *   y = The y-coordinate of the point to test.
   * Returns: true if the point defined by x and y is contained within this instance; otherwise, false.
   */
  bool contains(int x, int y) {
    return this.x <= x && x < this.right && this.y <= y && y < this.bottom;
  }

  /**
   * Determines if the specified rectangular region is entirely contained within this instance.
   * Params:
   *   rect = The rectangular region to test.
   * Returns: true if the rectangular region represented by rect is entirely contained within this instance; otherwise, false.
   */
  bool contains(Rect rect) {
    return x <= rect.x && rect.x + rect.width <= x + width && y <= rect.y && rect.y + rect.height <= y + height;
  }

  /**
   * Returns an inflated copy of the specified Rect structure.
   * Params:
   *   rect = The Rect to be copied.
   *   x = The amount to _inflate the copy horizontally.
   *   y = The amount to _inflate the copy vertically.
   * Returns: The inflated Rect.
   */
  static Rect inflate(Rect rect, int x, int y) {
    Rect r = rect;
    r.inflate(x, y);
    return r;
  }

  /**
   * Inflates this instance by the specified amount.
   * Params: size = The amount to inflate this instance.
   */
  void inflate(Size size) {
    inflate(size.width, size.height);
  }

  /**
   * Inflates this instance by the specified amount.
   * Params:
   *   x = The amount to _inflate this instance horizontally.
   *   y = The amount to _inflate this instance vertically.
   */
  void inflate(int width, int height) {
    this.x -= width;
    this.y -= height;
    this.width += width * 2;
    this.height += height * 2;
  }

  /**
   * Adjust the location of this instance by the specified amount.
   * Params: pos = The amount to _offset the location.
   */
  void offset(Point pos) {
    offset(pos.x, pos.y);
  }

  /**
   * Adjust the location of this instance by the specified amount.
   * Params:
   *   x = The horizontal _offset.
   *   y = The vertical _offset.
   */
  void offset(int x, int y) {
    this.x += x;
    this.y += y;
  }

  /**
   * Determines whether this instance intersects with rect.
   * Params: rect = The Rect to test.
   * Returns: true if there is any intersection; otherwise, false.
   */
  bool intersectsWith(Rect rect) {
    return rect.x < x + width && x < rect.x + rect.width && rect.y < y + height && y < rect.y + rect.height;
  }

  /**
   * Returns a Rect structure that represents the intersection of two Rect structures.
   * Params:
   *   a = A Rect to _intersect.
   *   b = A Rect to _intersect.
   * Returns: A Rect that represents the intersection of a and b.
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
   * Replaces this instance with the intersection of itself and the specified Rect structure.
   * Params: rect = The Rect with which to _intersect.
   */
  void intersect(Rect rect) {
    version(D_Version2) {
      Rect r = intersect(rect, this);
    }
    else {
      Rect r = intersect(rect, *this);
    }
    x = r.x;
    y = r.y;
    width = r.width;
    height = r.height;
  }

  /**
   * Gets the x-coordinate of the _left edge of this Rect structure.
   */
  int left() {
    return x;
  }

  /**
   * Gets the y-coordinate of the _top edge of this Rect structure.
   */
  int top() {
    return y;
  }

  /**
   * Gets the x-coordinate that is the sum of the x and width values.
   */
  int right() {
    return x + width;
  }

  /**
   * Gets the y-coordinate that is the sum of the y and height values.
   */
  int bottom() {
    return y + height;
  }

  /**
   * Gets or sets the coordinates of the upper-left corner of this Rect structure.
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
   * Gets or sets the _size of this Rect structure.
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
   * Tests whether all numeric values of this Rect structure have values of zero.
   * Returns: true if the x, y, width and height values of this Rect structure all have values of zero; otherwise, false.
   */
  bool isEmpty() {
    return x == 0 && y == 0 && width == 0 && height == 0;
  }

  string toString() {
    return format("{x=%s,y=%s,width=%s,height=%s}", x, y, width, height);
  }

}

/**
 * Represents a set of four floating-point numbers that define the location and size of a rectangle.
 */
struct RectF {

  float x = 0f; /// Gets or sets the _x-coordinate.
  float y = 0f; /// Gets of sets the _y-coordinate.
  float width = 0f; /// Gets or sets the _width component.
  float height = 0f; /// Gets or sets the _height component.

  static RectF empty = { 0f, 0f, 0f, 0f }; /// Represents a RectF structure with its values set to zero.

  /**
   * Initializes a new instance with the specified location and size.
   * Params:
   *   x = The _x-coordinate.
   *   y = The _y-coordinate.
   *   width = The _width.
   *   height = The _height.
   */
  static RectF opCall(float x, float y, float width, float height) {
    RectF self;
    self.x = x, self.y = y, self.width = width, self.height = height;
    return self;
  }

  /**
   * Initializes a new instance with the specified _location and _size.
   * Params:
   *   location = The upper-left corner.
   *   size = The width and height.
   */
  static RectF opCall(PointF location, SizeF size) {
    return RectF(location.x, location.y, size.width, size.height);
  }

  static RectF opCall(Rect r) {
    return RectF(cast(float)r.x, cast(float)r.y, cast(float)r.width, cast(float)r.height);
  }

  /**
   * Creates a RectF structure width the specified edge locations.
   * Params:
   *   left = The x-coordinate of the upper-_left corner.
   *   top = The y-coordinate of the upper-_left corner.
   *   right = The x-coordinate of the lower-_right corner.
   *   bottom = The y-coordinate of the lower-_right corner.
   * Returns: The new RectF that this method creates.
   */
  static RectF fromLTRB(float left, float top, float right, float bottom) {
    return RectF(left, top, right - left, bottom - top);
  }

  /**
   * Tests whether the specified Rect structure has the same location and size as this instance.
   * Params: other = The RectF to test.
   * Returns: true if the x, y, width and height properties of other are equal to the corresponding properties of this instance; otherwise, false.
   */
  bool equals(RectF other) {
    return x == other.x && y == other.y && width == other.width && height == other.height;
  }

  /// ditto
  bool opEquals(RectF other) {
    return x == other.x && y == other.y && width == other.width && height == other.height;
  }

  hash_t toHash() {
    return cast(uint)x | ((cast(uint)y << 13) | (cast(uint)y >> 19)) ^ ((cast(uint)width << 26) | (cast(uint)width >> 6)) | ((cast(uint)height << 7) | (cast(uint)height >> 25));
  }

  /**
   * Gets a Rect structure containing the union of two RectF structures.
   * Params:
   *   a = A RectF to union.
   *   b = A RectF to union.
   * Returns: A RectF structure that bounds the union of the two Rect structures.
   */
  static RectF unionRects(RectF a, RectF b) {
    float left = min(a.x, b.x);
    float right = max(a.x + a.width, b.x + b.width);
    float top = min(a.y, b.y);
    float bottom = max(a.y + a.height, b.y + b.height);
    return RectF(left, top, right - left, bottom - top);
  }

  /**
   * Determines if the specified point is contained within this instance.
   * Params: pt = The PointF to test.
   * Returns: true if the point represented by pt is contained within this instance; otherwise, false.
   */
  bool contains(PointF pt) {
    return contains(pt.x, pt.y);
  }

  /**
   * Determines if the specified point is contained within this instance.
   * Params:
   *   x = The x-coordinate of the point to test.
   *   y = The y-coordinate of the point to test.
   * Returns: true if the point defined by x and y is contained within this instance; otherwise, false.
   */
  bool contains(float x, float y) {
    return this.x <= x && x < this.x + this.width && this.y <= y && y < this.y + this.height;
  }

  /**
   * Determines if the specified rectangular region is entirely contained within this instance.
   * Params:
   *   rect = The rectangular region to test.
   * Returns: true if the rectangular region represented by rect is entirely contained within this instance; otherwise, false.
   */
  bool contains(RectF rect) {
    return x <= rect.x && rect.x + rect.width <= x + width && y <= rect.y && rect.y + rect.height <= y + height;
  }

  /**
   * Returns an inflated copy of the specified RectF structure.
   * Params:
   *   rect = The RectF to be copied.
   *   x = The amount to _inflate the copy horizontally.
   *   y = The amount to _inflate the copy vertically.
   * Returns: The inflated RectF.
   */
  static RectF inflate(RectF rect, float x, float y) {
    RectF r = rect;
    r.inflate(x, y);
    return r;
  }

  /**
   * Inflates this instance by the specified amount.
   * Params: size = The amount to inflate this instance.
   */
  void inflate(SizeF size) {
    inflate(size.width, size.height);
  }

  /**
   * Inflates this instance by the specified amount.
   * Params:
   *   x = The amount to _inflate this instance horizontally.
   *   y = The amount to _inflate this instance vertically.
   */
  void inflate(float width, float height) {
    this.x -= width;
    this.y -= height;
    this.width += width * 2f;
    this.height += height * 2f;
  }

  /**
   * Adjust the location of this instance by the specified amount.
   * Params: pos = The amount to _offset the location.
   */
  void offset(PointF pos) {
    offset(pos.x, pos.y);
  }

  /**
   * Adjust the location of this instance by the specified amount.
   * Params:
   *   x = The horizontal _offset.
   *   y = The vertical _offset.
   */
  void offset(float x, float y) {
    this.x += x;
    this.y += y;
  }

  /**
   * Determines whether this instance intersects with rect.
   * Params: rect = The RectF to test.
   * Returns: true if there is any intersection; otherwise, false.
   */
  bool intersectsWith(RectF rect) {
    return rect.x < x + width && x < rect.x + rect.width && rect.y < y + height && y < rect.y + rect.height;
  }

  /**
   * Returns a RectF structure that represents the intersection of two RectF structures.
   * Params:
   *   a = A RectF to _intersect.
   *   b = A RectF to _intersect.
   * Returns: A RectF that represents the intersection of a and b.
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
   * Replaces this instance with the intersection of itself and the specified RectF structure.
   * Params: rect = The RectF with which to _intersect.
   */
  void intersect(RectF rect) {
    version(D_Version2) {
      RectF r = intersect(rect, this);
    }
    else {
      RectF r = intersect(rect, *this);
    }
    x = r.x;
    y = r.y;
    width = r.width;
    height = r.height;
  }

  /**
   * Gets the x-coordinate of the _left edge of this RectF structure.
   */
  float left() {
    return x;
  }

  /**
   * Gets the y-coordinate of the _top edge of this RectF structure.
   */
  float top() {
    return y;
  }

  /**
   * Gets the x-coordinate that is the sum of the x and width values.
   */
  float right() {
    return x + width;
  }

  /**
   * Gets the y-coordinate that is the sum of the y and height values.
   */
  float bottom() {
    return y + height;
  }

  /**
   * Gets or sets the coordinates of the upper-left corner of this RectF structure.
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
   * Gets or sets the _size of this RectF structure.
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

  string toString() {
    return format("{x=%s,y=%s,width=%s,height=%s}", x, y, width, height);
  }

}