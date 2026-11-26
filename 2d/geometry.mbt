// 2D geometry primitives, affine transforms, and colors for laplaceliu/tycho_2d.

///|
#derive(Eq, Debug)
pub(all) struct Point {
  x : Float
  y : Float
}

///|
pub fn Point::new(x : Float, y : Float) -> Point {
  { x, y }
}

///|
pub fn Point::zero() -> Point {
  { x: (0.0 : Float), y: (0.0 : Float) }
}

///|
pub fn Point::add(self : Point, other : Point) -> Point {
  { x: self.x + other.x, y: self.y + other.y }
}

///|
pub fn Point::sub(self : Point, other : Point) -> Point {
  { x: self.x - other.x, y: self.y - other.y }
}

///|
pub fn Point::scale(self : Point, s : Float) -> Point {
  { x: self.x * s, y: self.y * s }
}

///|
pub fn Point::distance_to(self : Point, other : Point) -> Float {
  let dx = (self.x - other.x).to_double()
  let dy = (self.y - other.y).to_double()
  Float::from_double((dx * dx + dy * dy).sqrt())
}

///|
pub fn Point::lerp(self : Point, other : Point, t : Float) -> Point {
  {
    x: self.x + (other.x - self.x) * t,
    y: self.y + (other.y - self.y) * t,
  }
}

///|
#derive(Eq, Debug)
pub(all) struct Size {
  width : Float
  height : Float
}

///|
pub fn Size::new(width : Float, height : Float) -> Size {
  { width, height }
}

///|
pub fn Size::zero() -> Size {
  { width: (0.0 : Float), height: (0.0 : Float) }
}

///|
#derive(Eq, Debug)
pub(all) struct Rect {
  x : Float
  y : Float
  width : Float
  height : Float
}

///|
pub fn Rect::new(x : Float, y : Float, width : Float, height : Float) -> Rect {
  { x, y, width, height }
}

///|
pub fn Rect::from_ltrb(l : Float, t : Float, r : Float, b : Float) -> Rect {
  {
    x: l,
    y: t,
    width: @tmath.max_f((0.0 : Float), r - l),
    height: @tmath.max_f((0.0 : Float), b - t),
  }
}

///|
pub fn Rect::from_size(size : Size) -> Rect {
  { x: (0.0 : Float), y: (0.0 : Float), width: size.width, height: size.height }
}

///|
pub fn Rect::zero() -> Rect {
  { x: (0.0 : Float), y: (0.0 : Float), width: (0.0 : Float), height: (0.0 : Float) }
}

///|
pub fn Rect::right(self : Rect) -> Float {
  self.x + self.width
}

///|
pub fn Rect::bottom(self : Rect) -> Float {
  self.y + self.height
}

///|
pub fn Rect::center(self : Rect) -> Point {
  { x: self.x + self.width * (0.5 : Float), y: self.y + self.height * (0.5 : Float) }
}

///|
pub fn Rect::is_empty(self : Rect) -> Bool {
  self.width <= (0.0 : Float) || self.height <= (0.0 : Float)
}

///|
pub fn Rect::contains(self : Rect, pt : Point) -> Bool {
  pt.x >= self.x &&
  pt.x < self.x + self.width &&
  pt.y >= self.y &&
  pt.y < self.y + self.height
}

///|
pub fn Rect::intersect(self : Rect, other : Rect) -> Rect {
  let l = @tmath.max_f(self.x, other.x)
  let t = @tmath.max_f(self.y, other.y)
  let r = @tmath.min_f(self.right(), other.right())
  let b = @tmath.min_f(self.bottom(), other.bottom())
  if r <= l || b <= t {
    { x: l, y: t, width: (0.0 : Float), height: (0.0 : Float) }
  } else {
    { x: l, y: t, width: r - l, height: b - t }
  }
}

///|
pub fn Rect::union(self : Rect, other : Rect) -> Rect {
  if self.is_empty() {
    return other
  }
  if other.is_empty() {
    return self
  }
  let l = @tmath.min_f(self.x, other.x)
  let t = @tmath.min_f(self.y, other.y)
  let r = @tmath.max_f(self.right(), other.right())
  let b = @tmath.max_f(self.bottom(), other.bottom())
  { x: l, y: t, width: r - l, height: b - t }
}

///|
pub fn Rect::offset(self : Rect, dx : Float, dy : Float) -> Rect {
  { x: self.x + dx, y: self.y + dy, width: self.width, height: self.height }
}

///|
pub fn Rect::inset(self : Rect, dx : Float, dy : Float) -> Rect {
  Rect::from_ltrb(self.x + dx, self.y + dy, self.right() - dx, self.bottom() - dy)
}

///|
pub fn Rect::inflate(self : Rect, delta : Float) -> Rect {
  self.inset(-delta, -delta)
}

///|
// Per-corner radii are stored as (x, y) pairs so elliptical corners (e.g. a
// 24x12 capsule corner) can be represented. `tl..bl` keep the horizontal (x)
// radius for source compatibility; `tl_y..bl_y` are the vertical radii.
#derive(Eq, Debug)
pub(all) struct RRect {
  rect : Rect
  tl : Float
  tl_y : Float
  tr : Float
  tr_y : Float
  br : Float
  br_y : Float
  bl : Float
  bl_y : Float
}

///|
pub fn RRect::from_rect(rect : Rect) -> RRect {
  {
    rect,
    tl: (0.0 : Float),
    tl_y: (0.0 : Float),
    tr: (0.0 : Float),
    tr_y: (0.0 : Float),
    br: (0.0 : Float),
    br_y: (0.0 : Float),
    bl: (0.0 : Float),
    bl_y: (0.0 : Float),
  }
}

///|
pub fn RRect::uniform(rect : Rect, radius : Float) -> RRect {
  let r = @tmath.max_f((0.0 : Float), radius)
  {
    rect,
    tl: r,
    tl_y: r,
    tr: r,
    tr_y: r,
    br: r,
    br_y: r,
    bl: r,
    bl_y: r,
  }
}

///|
pub fn RRect::per_corner(
  rect : Rect,
  tl : Float,
  tr : Float,
  br : Float,
  bl : Float,
) -> RRect {
  {
    rect,
    tl: @tmath.max_f((0.0 : Float), tl),
    tl_y: @tmath.max_f((0.0 : Float), tl),
    tr: @tmath.max_f((0.0 : Float), tr),
    tr_y: @tmath.max_f((0.0 : Float), tr),
    br: @tmath.max_f((0.0 : Float), br),
    br_y: @tmath.max_f((0.0 : Float), br),
    bl: @tmath.max_f((0.0 : Float), bl),
    bl_y: @tmath.max_f((0.0 : Float), bl),
  }
}

///|
// Elliptical per-corner radii: each corner takes an explicit (rx, ry).
pub fn RRect::per_corner_xy(
  rect : Rect,
  tl_x : Float,
  tl_y : Float,
  tr_x : Float,
  tr_y : Float,
  br_x : Float,
  br_y : Float,
  bl_x : Float,
  bl_y : Float,
) -> RRect {
  {
    rect,
    tl: @tmath.max_f((0.0 : Float), tl_x),
    tl_y: @tmath.max_f((0.0 : Float), tl_y),
    tr: @tmath.max_f((0.0 : Float), tr_x),
    tr_y: @tmath.max_f((0.0 : Float), tr_y),
    br: @tmath.max_f((0.0 : Float), br_x),
    br_y: @tmath.max_f((0.0 : Float), br_y),
    bl: @tmath.max_f((0.0 : Float), bl_x),
    bl_y: @tmath.max_f((0.0 : Float), bl_y),
  }
}

///|
pub fn RRect::offset(self : RRect, dx : Float, dy : Float) -> RRect {
  { ..self, rect: self.rect.offset(dx, dy) }
}

///|
pub fn RRect::is_rect(self : RRect) -> Bool {
  self.tl <= (0.0 : Float) &&
  self.tl_y <= (0.0 : Float) &&
  self.tr <= (0.0 : Float) &&
  self.tr_y <= (0.0 : Float) &&
  self.br <= (0.0 : Float) &&
  self.br_y <= (0.0 : Float) &&
  self.bl <= (0.0 : Float) &&
  self.bl_y <= (0.0 : Float)
}

///|
// True when every corner is circular (rx == ry). The Tier-1 SDF pipeline only
// handles circular corners; elliptical RRect falls back to the Tier-2 path
// pipeline (see Renderer2D::replay_ops).
pub fn RRect::is_circular(self : RRect) -> Bool {
  let eps = (1.0e-4 : Float)
  @tmath.abs_f(self.tl - self.tl_y) <= eps &&
  @tmath.abs_f(self.tr - self.tr_y) <= eps &&
  @tmath.abs_f(self.br - self.br_y) <= eps &&
  @tmath.abs_f(self.bl - self.bl_y) <= eps
}

///|
// 2D affine matrix: [a c tx; b d ty; 0 0 1]
#derive(Eq, Debug)
pub(all) struct Matrix3 {
  a : Float
  c : Float
  tx : Float
  b : Float
  d : Float
  ty : Float
}

///|
pub fn Matrix3::identity() -> Matrix3 {
  {
    a: (1.0 : Float),
    c: (0.0 : Float),
    tx: (0.0 : Float),
    b: (0.0 : Float),
    d: (1.0 : Float),
    ty: (0.0 : Float),
  }
}

///|
pub fn Matrix3::translate(dx : Float, dy : Float) -> Matrix3 {
  {
    a: (1.0 : Float),
    c: (0.0 : Float),
    tx: dx,
    b: (0.0 : Float),
    d: (1.0 : Float),
    ty: dy,
  }
}

///|
pub fn Matrix3::scale(sx : Float, sy : Float) -> Matrix3 {
  {
    a: sx,
    c: (0.0 : Float),
    tx: (0.0 : Float),
    b: (0.0 : Float),
    d: sy,
    ty: (0.0 : Float),
  }
}

///|
pub fn Matrix3::rotate(radians : Float) -> Matrix3 {
  let (s, c) = @tmath.sin_cos(radians)
  {
    a: c,
    c: -s,
    tx: (0.0 : Float),
    b: s,
    d: c,
    ty: (0.0 : Float),
  }
}

///|
pub fn Matrix3::concat(self : Matrix3, other : Matrix3) -> Matrix3 {
  {
    a: self.a * other.a + self.c * other.b,
    c: self.a * other.c + self.c * other.d,
    tx: self.a * other.tx + self.c * other.ty + self.tx,
    b: self.b * other.a + self.d * other.b,
    d: self.b * other.c + self.d * other.d,
    ty: self.b * other.tx + self.d * other.ty + self.ty,
  }
}

///|
pub fn Matrix3::invert(self : Matrix3) -> Matrix3? {
  let det = self.a * self.d - self.c * self.b
  if @tmath.abs_f(det) < (1.0e-7 : Float) {
    return None
  }
  let inv = (1.0 : Float) / det
  Some({
    a: self.d * inv,
    c: -self.c * inv,
    tx: (self.c * self.ty - self.d * self.tx) * inv,
    b: -self.b * inv,
    d: self.a * inv,
    ty: (self.b * self.tx - self.a * self.ty) * inv,
  })
}

///|
pub fn Matrix3::map_point(self : Matrix3, pt : Point) -> Point {
  {
    x: self.a * pt.x + self.c * pt.y + self.tx,
    y: self.b * pt.x + self.d * pt.y + self.ty,
  }
}

///|
pub fn Matrix3::map_rect(self : Matrix3, rect : Rect) -> Rect {
  let p0 = self.map_point({ x: rect.x, y: rect.y })
  let p1 = self.map_point({ x: rect.right(), y: rect.y })
  let p2 = self.map_point({ x: rect.right(), y: rect.bottom() })
  let p3 = self.map_point({ x: rect.x, y: rect.bottom() })
  let l = @tmath.min_f(@tmath.min_f(p0.x, p1.x), @tmath.min_f(p2.x, p3.x))
  let t = @tmath.min_f(@tmath.min_f(p0.y, p1.y), @tmath.min_f(p2.y, p3.y))
  let r = @tmath.max_f(@tmath.max_f(p0.x, p1.x), @tmath.max_f(p2.x, p3.x))
  let b = @tmath.max_f(@tmath.max_f(p0.y, p1.y), @tmath.max_f(p2.y, p3.y))
  { x: l, y: t, width: r - l, height: b - t }
}

///|
pub fn Matrix3::is_axis_aligned(self : Matrix3) -> Bool {
  @tmath.abs_f(self.b) < (1.0e-5 : Float) &&
  @tmath.abs_f(self.c) < (1.0e-5 : Float) &&
  self.a >= (0.0 : Float) &&
  self.d >= (0.0 : Float)
}

///|
pub fn Matrix3::is_pure_translation(self : Matrix3) -> Bool {
  @tmath.abs_f(self.a - (1.0 : Float)) < (1.0e-5 : Float) &&
  @tmath.abs_f(self.d - (1.0 : Float)) < (1.0e-5 : Float) &&
  @tmath.abs_f(self.b) < (1.0e-5 : Float) &&
  @tmath.abs_f(self.c) < (1.0e-5 : Float)
}

///|
/// Convert to the unified 2D affine type from `laplaceliu/tycho_math`, e.g. to
/// promote a UI transform into a 3D scene with `Affine2::to_mat4()`.
pub fn Matrix3::to_affine2(self : Matrix3) -> @tmath.Affine2 {
  {
    x_axis: @tmath.Vec2::new(self.a, self.b),
    y_axis: @tmath.Vec2::new(self.c, self.d),
    translation: @tmath.Vec2::new(self.tx, self.ty),
  }
}

///|
pub fn Matrix3::from_affine2(affine : @tmath.Affine2) -> Matrix3 {
  {
    a: affine.x_axis.x,
    c: affine.y_axis.x,
    tx: affine.translation.x,
    b: affine.x_axis.y,
    d: affine.y_axis.y,
    ty: affine.translation.y,
  }
}

///|
#derive(Eq, Debug)
pub(all) struct Color {
  r : Float
  g : Float
  b : Float
  a : Float
}

///|
pub fn Color::rgba(r : Float, g : Float, b : Float, a : Float) -> Color {
  {
    r: @tmath.clamp_f(r, (0.0 : Float), (1.0 : Float)),
    g: @tmath.clamp_f(g, (0.0 : Float), (1.0 : Float)),
    b: @tmath.clamp_f(b, (0.0 : Float), (1.0 : Float)),
    a: @tmath.clamp_f(a, (0.0 : Float), (1.0 : Float)),
  }
}

///|
pub fn Color::rgb(r : Float, g : Float, b : Float) -> Color {
  Color::rgba(r, g, b, (1.0 : Float))
}

///|
pub fn Color::from_rgba8(r : Int, g : Int, b : Int, a? : Int = 255) -> Color {
  let inv = (1.0 : Float) / (255.0 : Float)
  Color::rgba(
    Float::from_int(r) * inv,
    Float::from_int(g) * inv,
    Float::from_int(b) * inv,
    Float::from_int(a) * inv,
  )
}

///|
pub fn Color::from_argb32(argb : UInt) -> Color {
  let a = ((argb >> 24) & (0xFF : UInt)).reinterpret_as_int()
  let r = ((argb >> 16) & (0xFF : UInt)).reinterpret_as_int()
  let g = ((argb >> 8) & (0xFF : UInt)).reinterpret_as_int()
  let b = (argb & (0xFF : UInt)).reinterpret_as_int()
  Color::from_rgba8(r, g, b, a~)
}

///|
pub fn Color::transparent() -> Color {
  Color::rgba((0.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float))
}

///|
pub fn Color::black() -> Color {
  Color::rgb((0.0 : Float), (0.0 : Float), (0.0 : Float))
}

///|
pub fn Color::white() -> Color {
  Color::rgb((1.0 : Float), (1.0 : Float), (1.0 : Float))
}

///|
pub fn Color::with_alpha(self : Color, a : Float) -> Color {
  Color::rgba(self.r, self.g, self.b, a)
}

///|
pub fn Color::lerp(self : Color, other : Color, t : Float) -> Color {
  let k = @tmath.clamp_f(t, (0.0 : Float), (1.0 : Float))
  {
    r: self.r + (other.r - self.r) * k,
    g: self.g + (other.g - self.g) * k,
    b: self.b + (other.b - self.b) * k,
    a: self.a + (other.a - self.a) * k,
  }
}

///|
pub fn Color::to_premul(self : Color) -> (Float, Float, Float, Float) {
  (self.r * self.a, self.g * self.a, self.b * self.a, self.a)
}

///|
pub fn Color::to_clear_color(self : Color) -> @tycho.ClearColor {
  let (pr, pg, pb, pa) = self.to_premul()
  @tycho.ClearColor::rgba(pr, pg, pb, pa)
}
