// 2-component single-precision vector.

///|
#valtype
#derive(Eq, Debug)
pub(all) struct Vec2 {
  x : Float
  y : Float
}

///|
pub impl Show for Vec2 with to_string(self) {
  "(\{self.x}, \{self.y})"
}

///|
pub fn Vec2::new(x : Float, y : Float) -> Vec2 {
  { x, y }
}

///|
pub fn Vec2::splat(v : Float) -> Vec2 {
  { x: v, y: v }
}

///|
pub fn Vec2::zero() -> Vec2 {
  { x: 0.0, y: 0.0 }
}

///|
pub fn Vec2::one() -> Vec2 {
  { x: 1.0, y: 1.0 }
}

///|
pub fn Vec2::unit_x() -> Vec2 {
  { x: 1.0, y: 0.0 }
}

///|
pub fn Vec2::unit_y() -> Vec2 {
  { x: 0.0, y: 1.0 }
}

///|
pub fn Vec2::neg_x() -> Vec2 {
  { x: -1.0, y: 0.0 }
}

///|
pub fn Vec2::neg_y() -> Vec2 {
  { x: 0.0, y: -1.0 }
}

///|
pub impl Add for Vec2 with add(self, other) {
  { x: self.x + other.x, y: self.y + other.y }
}

///|
pub impl Sub for Vec2 with sub(self, other) {
  { x: self.x - other.x, y: self.y - other.y }
}

///|
/// Component-wise (Hadamard) product; use `scale` for scalar multiplication.
pub impl Mul for Vec2 with mul(self, other) {
  { x: self.x * other.x, y: self.y * other.y }
}

///|
pub impl Div for Vec2 with div(self, other) {
  { x: self.x / other.x, y: self.y / other.y }
}

///|
pub impl Neg for Vec2 with neg(self) {
  { x: -self.x, y: -self.y }
}

///|
pub fn Vec2::scale(self : Vec2, s : Float) -> Vec2 {
  { x: self.x * s, y: self.y * s }
}

///|
pub fn Vec2::dot(self : Vec2, other : Vec2) -> Float {
  self.x * other.x + self.y * other.y
}

///|
/// 2D cross product (perpendicular dot), i.e. the signed area of the
/// parallelogram spanned by the two vectors.
pub fn Vec2::cross(self : Vec2, other : Vec2) -> Float {
  self.x * other.y - self.y * other.x
}

///|
/// Rotate 90 degrees counter-clockwise: `(-y, x)`.
pub fn Vec2::perp(self : Vec2) -> Vec2 {
  { x: -self.y, y: self.x }
}

///|
pub fn Vec2::length_sq(self : Vec2) -> Float {
  self.dot(self)
}

///|
pub fn Vec2::length(self : Vec2) -> Float {
  self.length_sq().sqrt()
}

///|
pub fn Vec2::distance_sq(self : Vec2, other : Vec2) -> Float {
  (self - other).length_sq()
}

///|
pub fn Vec2::distance(self : Vec2, other : Vec2) -> Float {
  self.distance_sq(other).sqrt()
}

///|
/// Normalize, returning the zero vector for zero-length input.
pub fn Vec2::normalize(self : Vec2) -> Vec2 {
  match self.try_normalize() {
    Some(n) => n
    None => Vec2::zero()
  }
}

///|
/// Normalize, returning `None` when the vector is (near) zero length.
pub fn Vec2::try_normalize(self : Vec2) -> Vec2? {
  let len = self.length()
  if len > EPSILON {
    Some({ x: self.x / len, y: self.y / len })
  } else {
    None
  }
}

///|
pub fn Vec2::lerp(self : Vec2, other : Vec2, t : Float) -> Vec2 {
  { x: lerp_f(self.x, other.x, t), y: lerp_f(self.y, other.y, t) }
}

///|
pub fn Vec2::min(self : Vec2, other : Vec2) -> Vec2 {
  { x: if self.x < other.x { self.x } else { other.x }, y: if self.y < other.y {
    self.y
  } else {
    other.y
  } }
}

///|
pub fn Vec2::max(self : Vec2, other : Vec2) -> Vec2 {
  { x: if self.x > other.x { self.x } else { other.x }, y: if self.y > other.y {
    self.y
  } else {
    other.y
  } }
}

///|
pub fn Vec2::abs(self : Vec2) -> Vec2 {
  { x: self.x.abs(), y: self.y.abs() }
}

///|
pub fn Vec2::clamp(self : Vec2, lo : Vec2, hi : Vec2) -> Vec2 {
  { x: clamp_f(self.x, lo.x, hi.x), y: clamp_f(self.y, lo.y, hi.y) }
}

///|
/// Mirror `self` about a (ideally normalized) `normal`.
pub fn Vec2::reflect(self : Vec2, normal : Vec2) -> Vec2 {
  self - normal.scale((2.0 : Float) * self.dot(normal))
}

///|
/// Project `self` onto `other`.
pub fn Vec2::project_onto(self : Vec2, other : Vec2) -> Vec2 {
  let d = other.length_sq()
  if d <= EPSILON {
    Vec2::zero()
  } else {
    other.scale(self.dot(other) / d)
  }
}

///|
/// Rotate around the origin by `radians` (counter-clockwise).
pub fn Vec2::rotate(self : Vec2, radians : Float) -> Vec2 {
  let (s, c) = sin_cos(radians)
  { x: c * self.x - s * self.y, y: s * self.x + c * self.y }
}

///|
/// Angle of the vector from `+X`, in radians, via `atan2`.
pub fn Vec2::angle(self : Vec2) -> Float {
  atan2(self.y, self.x)
}

///|
/// Angle from `self` to `other`, in `[-PI, PI]`.
pub fn Vec2::angle_to(self : Vec2, other : Vec2) -> Float {
  atan2(self.cross(other), self.dot(other))
}

///|
/// Widen to `Vec3` with an explicit `z` (glam calls this `extend`).
pub fn Vec2::extend_z(self : Vec2, z : Float) -> Vec3 {
  { x: self.x, y: self.y, z }
}

///|
pub fn Vec2::to_array(self : Vec2) -> FixedArray[Float] {
  let out : FixedArray[Float] = FixedArray::make(2, 0.0)
  out[0] = self.x
  out[1] = self.y
  out
}

///|
pub fn Vec2::from_array(arr : FixedArray[Float]) -> Vec2 {
  { x: arr[0], y: arr[1] }
}

///|
pub fn Vec2::approx_eq(self : Vec2, other : Vec2, eps? : Float = EPSILON) -> Bool {
  approx_eq_f(self.x, other.x, eps~) && approx_eq_f(self.y, other.y, eps~)
}

///|
pub fn Vec2::is_finite(self : Vec2) -> Bool {
  self.x.is_finite() && self.y.is_finite()
}
