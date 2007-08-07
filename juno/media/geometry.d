module juno.media.geometry;

private import juno.base.math;

public struct Point {

  public int x;
  public int y;

  public static const Point empty = { 0, 0 };

  public static Point opCall(int x, int y) {
    Point p;
    p.x = x;
    p.y = y;
    return p;
  }

  // for cast(PointF)p
  public static Point opCall(PointF p) {
    return Point(cast(int)p.x, cast(int)p.y);
  }

  public Point opAdd(Point other) {
    return Point(x + other.x, y + other.y);
  }

  public Point opAddAssign(Point other) {
    x += other.x;
    y += other.y;
    return *this;
  }

  public Point opSub(Point other) {
    return Point(x - other.x, y - other.y);
  }

  public Point opSubAssign(Point other) {
    x -= other.x;
    y -= other.y;
    return *this;
  }

  public bool isEmpty() {
    return x == 0 && y == 0;
  }

}

public struct PointF {

  public float x;
  public float y;

  public static PointF opCall(float x, float y) {
    PointF p;
    p.x = x;
    p.y = y;
    return p;
  }

  // for cast(PointF)p
  public static PointF opCall(Point p) {
    return PointF(cast(float)p.x, cast(float)p.y);
  }

  public PointF opAdd(PointF other) {
    return PointF(x + other.x, y + other.y);
  }

  public PointF opAddAssign(PointF other) {
    x += other.x;
    y += other.y;
    return *this;
  }

  public PointF opSub(PointF other) {
    return PointF(x - other.x, y - other.y);
  }

  public PointF opSubAssign(PointF other) {
    x -= other.x;
    y -= other.y;
    return *this;
  }

  public bool isEmpty() {
    return x == 0 && y == 0;
  }

}

public struct Size {

  public int width;
  public int height;

  public static const Size empty = { 0, 0 };

  public static Size opCall(int width, int height) {
    Size sz;
    sz.width = width;
    sz.height = height;
    return sz;
  }

  // for cast(Size)szf
  public static Size opCall(SizeF sz) {
    return Size(cast(int)sz.width, cast(int)sz.height);
  }

  public Size opAdd(Size other) {
    return Size(width + other.width, height + other.height);
  }

  public Size opAddAssign(Size other) {
    width += other.width;
    height += other.height;
    return *this;
  }

  public Size opSub(Size other) {
    return Size(width - other.width, height - other.height);
  }

  public Size opSubAssign(Size other) {
    width -= other.width;
    height -= other.height;
    return *this;
  }

  public bool isEmpty() {
    return width == 0 && height == 0;
  }

}

public struct SizeF {

  public float width;
  public float height;

  public static const SizeF empty = { 0, 0 };

  public static SizeF opCall(float width, float height) {
    SizeF sz;
    sz.width = width;
    sz.height = height;
    return sz;
  }

  // for cast(SizeF)sz
  public static SizeF opCall(Size sz) {
    return SizeF(cast(float)sz.width, cast(float)sz.height);
  }

  public SizeF opAdd(SizeF other) {
    return SizeF(width + other.width, height + other.height);
  }

  public SizeF opAddAssign(SizeF other) {
    width += other.width;
    height += other.height;
    return *this;
  }

  public SizeF opSub(SizeF other) {
    return SizeF(width - other.width, height - other.height);
  }

  public SizeF opSubAssign(SizeF other) {
    width -= other.width;
    height -= other.height;
    return *this;
  }

  public bool isEmpty() {
    return width == 0 && height == 0;
  }

}

public struct Rect {

  public int x;
  public int y;
  public int width;
  public int height;

  public static const Rect empty = { 0, 0, 0, 0 };

  public static Rect opCall(int x, int y, int width, int height) {
    Rect rc;
    rc.x = x;
    rc.y = y;
    rc.width = width;
    rc.height = height;
    return rc;
  }

  public static Rect opCall(Point location, Size size) {
    return Rect(location.x, location.y, size.width, size.height);
  }

  public static Rect opCall(RectF rect) {
    return Rect(cast(int)rect.x, cast(int)rect.y, cast(int)rect.width, cast(int)rect.height);
  }

  public static Rect fromLTRB(int left, int top, int right, int bottom) {
    return Rect(left, top, right - left, bottom - top);
  }

  public bool contains(Point pt) {
    return contains(pt.x, pt.y);
  }

  public bool contains(int x, int y) {
    return this.x <= x && x < this.x + this.width && this.y <= y && y < this.y + this.height;
  }

  public bool contains(Rect rect) {
    return x <= rect.x && rect. x + rect.width <= x + width && y <= rect.y && rect.y + rect.height <= y + height;
  }

  public void offset(Point pos) {
    offset(pos.x, pos.y);
  }

  public void offset(int x, int y) {
    this.x += x;
    this.y += y;
  }

  public void inflate(Size size) {
    inflate(size.width, size.height);
  }

  public void inflate(int width, int height) {
    x -= width;
    y -= height;
    this.width += width * 2;
    this.height += height * 2;
  }

  public static Rect intersect(Rect a, Rect b) {
    int left = min(a.x, b.x);
    int right = max(a.x + a.width, b.x + b.width);
    int top = min(a.y, b.y);
    int bottom = max(a.y + a.height, b.y + b.height);
    return (right >= left && bottom >= top) 
      ? Rect(left, top, right - left, bottom - top) 
      : Rect.empty;
  }

  public bool intersectsWith(Rect rect) {
    return rect.x < x + width && x < rect.x + rect.width && rect.y < y + height && y < rect.y + rect.height;
  }

  public static Rect unionOf(Rect a, Rect b) {
    int left = min(a.x, b.x);
    int right = max(a.x + a.width, b.x + b.width);
    int top = min(a.y, b.y);
    int bottom = max(a.y + a.height, b.y + b.height);
    return Rect(left, top, right - left, bottom - top);
  }

  public int left() {
    return x;
  }

  public int top() {
    return y;
  }

  public int right() {
    return x + width;
  }

  public int bottom() {
    return y + height;
  }

  public void location(Point value) {
    x = value.x;
    y = value.y;
  }

  public Point location() {
    return Point(x, y);
  }

  public void size(Size value) {
    width = value.width;
    height = value.height;
  }

  public Size size() {
    return Size(width, height);
  }

  public bool isEmpty() {
    return x == 0 && y == 0 && width == 0 && height == 0;
  }

}

public struct RectF {

  public float x;
  public float y;
  public float width;
  public float height;

  public static const RectF empty = { 0, 0, 0, 0 };

  public static RectF opCall(float x, float y, float width, float height) {
    RectF rc;
    rc.x = x;
    rc.y = y;
    rc.width = width;
    rc.height = height;
    return rc;
  }

  public static RectF opCall(PointF location, SizeF size) {
    return RectF(location.x, location.y, size.width, size.height);
  }

  public static RectF opCall(Rect rect) {
    return RectF(cast(float)rect.x, cast(float)rect.y, cast(float)rect.width, cast(float)rect.height);
  }

  public static RectF fromLTRB(float left, float top, float right, float bottom) {
    return RectF(left, top, right - left, bottom - top);
  }

  public bool contains(PointF pt) {
    return contains(pt.x, pt.y);
  }

  public bool contains(float x, float y) {
    return this.x <= x && x < this.x + this.width && this.y <= y && y < this.y + this.height;
  }

  public bool contains(RectF rect) {
    return x <= rect.x && rect. x + rect.width <= x + width && y <= rect.y && rect.y + rect.height <= y + height;
  }

  public void offset(PointF pos) {
    offset(pos.x, pos.y);
  }

  public void offset(float x, float y) {
    this.x += x;
    this.y += y;
  }

  public void inflate(SizeF size) {
    inflate(size.width, size.height);
  }

  public void inflate(float width, float height) {
    x -= width;
    y -= height;
    this.width += width * 2;
    this.height += height * 2;
  }

  public static RectF intersect(RectF a, RectF b) {
    float left = min(a.x, b.x);
    float right = max(a.x + a.width, b.x + b.width);
    float top = min(a.y, b.y);
    float bottom = max(a.y + a.height, b.y + b.height);
    return (right >= left && bottom >= top) 
      ? RectF(left, top, right - left, bottom - top) 
      : RectF.empty;
  }

  public bool intersectsWith(RectF rect) {
    return rect.x < x + width && x < rect.x + rect.width && rect.y < y + height && y < rect.y + rect.height;
  }

  public static RectF unionOf(RectF a, RectF b) {
    float left = min(a.x, b.x);
    float right = max(a.x + a.width, b.x + b.width);
    float top = min(a.y, b.y);
    float bottom = max(a.y + a.height, b.y + b.height);
    return RectF(left, top, right - left, bottom - top);
  }

  public float left() {
    return x;
  }

  public float top() {
    return y;
  }

  public float right() {
    return x + width;
  }

  public float bottom() {
    return y + height;
  }

  public void location(PointF value) {
    x = value.x;
    y = value.y;
  }

  public PointF location() {
    return PointF(x, y);
  }

  public void size(SizeF value) {
    width = value.width;
    height = value.height;
  }

  public SizeF size() {
    return SizeF(width, height);
  }

  public bool isEmpty() {
    return x == 0 && y == 0 && width == 0 && height == 0;
  }

}