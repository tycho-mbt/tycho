// 2D geometry primitives, affine transforms, and colors for laplaceliu/tycho_2d.

///|
fn min_f(a : Float, b : Float) -> Float {
  if a < b { a } else { b }
}

///|
fn max_f(a : Float, b : Float) -> Float {
  if a > b { a } else { b }
}

///|
fn clamp_f(v : Float, lo : Float, hi : Float) -> Float {
  if v < lo { lo } else if v > hi { hi } else { v }
}

///|
fn abs_f(v : Float) -> Float {
  if v < (0.0 : Float) { -v } else { v }
}

///|
fn sin_cos_d(theta : Double) -> (Double, Double) {
  let pi = 3.141592653589793
  let two_pi = 6.283185307179586
  let mut x = theta % two_pi
  if x > pi {
    x = x - two_pi
  } else if x < -pi {
    x = x + two_pi
  }
  let half_pi = 1.5707963267948966
  let mut cos_sign = 1.0
  let mut sx = x
  if sx > half_pi {
    sx = pi - sx
    cos_sign = -1.0
  } else if sx < -half_pi {
    sx = -pi - sx
    cos_sign = -1.0
  }
  let x2 = sx * sx
  let s = sx *
    (1.0 - x2 / 6.0 * (1.0 - x2 / 20.0 * (1.0 - x2 / 42.0 * (1.0 - x2 / 72.0))))
  let c = cos_sign *
    (1.0 - x2 / 2.0 * (1.0 - x2 / 12.0 * (1.0 - x2 / 30.0 * (1.0 - x2 / 56.0))))
  (s, c)
}

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
    width: max_f((0.0 : Float), r - l),
    height: max_f((0.0 : Float), b - t),
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
  let l = max_f(self.x, other.x)
  let t = max_f(self.y, other.y)
  let r = min_f(self.right(), other.right())
  let b = min_f(self.bottom(), other.bottom())
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
  let l = min_f(self.x, other.x)
  let t = min_f(self.y, other.y)
  let r = max_f(self.right(), other.right())
  let b = max_f(self.bottom(), other.bottom())
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
#derive(Eq, Debug)
pub(all) struct RRect {
  rect : Rect
  tl : Float
  tr : Float
  br : Float
  bl : Float
}

///|
pub fn RRect::from_rect(rect : Rect) -> RRect {
  { rect, tl: (0.0 : Float), tr: (0.0 : Float), br: (0.0 : Float), bl: (0.0 : Float) }
}

///|
pub fn RRect::uniform(rect : Rect, radius : Float) -> RRect {
  let r = max_f((0.0 : Float), radius)
  { rect, tl: r, tr: r, br: r, bl: r }
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
    tl: max_f((0.0 : Float), tl),
    tr: max_f((0.0 : Float), tr),
    br: max_f((0.0 : Float), br),
    bl: max_f((0.0 : Float), bl),
  }
}

///|
pub fn RRect::offset(self : RRect, dx : Float, dy : Float) -> RRect {
  { ..self, rect: self.rect.offset(dx, dy) }
}

///|
pub fn RRect::is_rect(self : RRect) -> Bool {
  self.tl <= (0.0 : Float) &&
  self.tr <= (0.0 : Float) &&
  self.br <= (0.0 : Float) &&
  self.bl <= (0.0 : Float)
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
  let (s_d, c_d) = sin_cos_d(radians.to_double())
  let s = Float::from_double(s_d)
  let c = Float::from_double(c_d)
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
  if abs_f(det) < (1.0e-7 : Float) {
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
  let l = min_f(min_f(p0.x, p1.x), min_f(p2.x, p3.x))
  let t = min_f(min_f(p0.y, p1.y), min_f(p2.y, p3.y))
  let r = max_f(max_f(p0.x, p1.x), max_f(p2.x, p3.x))
  let b = max_f(max_f(p0.y, p1.y), max_f(p2.y, p3.y))
  { x: l, y: t, width: r - l, height: b - t }
}

///|
pub fn Matrix3::is_axis_aligned(self : Matrix3) -> Bool {
  abs_f(self.b) < (1.0e-5 : Float) &&
  abs_f(self.c) < (1.0e-5 : Float) &&
  self.a >= (0.0 : Float) &&
  self.d >= (0.0 : Float)
}

///|
pub fn Matrix3::is_pure_translation(self : Matrix3) -> Bool {
  abs_f(self.a - (1.0 : Float)) < (1.0e-5 : Float) &&
  abs_f(self.d - (1.0 : Float)) < (1.0e-5 : Float) &&
  abs_f(self.b) < (1.0e-5 : Float) &&
  abs_f(self.c) < (1.0e-5 : Float)
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
    r: clamp_f(r, (0.0 : Float), (1.0 : Float)),
    g: clamp_f(g, (0.0 : Float), (1.0 : Float)),
    b: clamp_f(b, (0.0 : Float), (1.0 : Float)),
    a: clamp_f(a, (0.0 : Float), (1.0 : Float)),
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
  let k = clamp_f(t, (0.0 : Float), (1.0 : Float))
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
