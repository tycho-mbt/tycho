// 3-component single-precision vector.

///|
#valtype
#derive(Eq, Debug)
pub(all) struct Vec3 {
  x : Float
  y : Float
  z : Float
}

///|
pub impl Show for Vec3 with to_string(self) {
  "(\{self.x}, \{self.y}, \{self.z})"
}

///|
pub fn Vec3::new(x : Float, y : Float, z : Float) -> Vec3 {
  { x, y, z }
}

///|
pub fn Vec3::splat(v : Float) -> Vec3 {
  { x: v, y: v, z: v }
}

///|
pub fn Vec3::zero() -> Vec3 {
  { x: 0.0, y: 0.0, z: 0.0 }
}

///|
pub fn Vec3::one() -> Vec3 {
  { x: 1.0, y: 1.0, z: 1.0 }
}

///|
pub fn Vec3::unit_x() -> Vec3 {
  { x: 1.0, y: 0.0, z: 0.0 }
}

///|
pub fn Vec3::unit_y() -> Vec3 {
  { x: 0.0, y: 1.0, z: 0.0 }
}

///|
pub fn Vec3::unit_z() -> Vec3 {
  { x: 0.0, y: 0.0, z: 1.0 }
}

///|
pub fn Vec3::neg_x() -> Vec3 {
  { x: -1.0, y: 0.0, z: 0.0 }
}

///|
pub fn Vec3::neg_y() -> Vec3 {
  { x: 0.0, y: -1.0, z: 0.0 }
}

///|
pub fn Vec3::neg_z() -> Vec3 {
  { x: 0.0, y: 0.0, z: -1.0 }
}

///|
pub impl Add for Vec3 with add(self, other) {
  { x: self.x + other.x, y: self.y + other.y, z: self.z + other.z }
}

///|
pub impl Sub for Vec3 with sub(self, other) {
  { x: self.x - other.x, y: self.y - other.y, z: self.z - other.z }
}

///|
/// Component-wise (Hadamard) product; use `scale` for scalar multiplication.
pub impl Mul for Vec3 with mul(self, other) {
  { x: self.x * other.x, y: self.y * other.y, z: self.z * other.z }
}

///|
pub impl Div for Vec3 with div(self, other) {
  { x: self.x / other.x, y: self.y / other.y, z: self.z / other.z }
}

///|
pub impl Neg for Vec3 with neg(self) {
  { x: -self.x, y: -self.y, z: -self.z }
}

///|
pub fn Vec3::scale(self : Vec3, s : Float) -> Vec3 {
  { x: self.x * s, y: self.y * s, z: self.z * s }
}

///|
pub fn Vec3::dot(self : Vec3, other : Vec3) -> Float {
  self.x * other.x + self.y * other.y + self.z * other.z
}

///|
pub fn Vec3::cross(self : Vec3, other : Vec3) -> Vec3 {
  {
    x: self.y * other.z - self.z * other.y,
    y: self.z * other.x - self.x * other.z,
    z: self.x * other.y - self.y * other.x,
  }
}

///|
pub fn Vec3::length_sq(self : Vec3) -> Float {
  self.dot(self)
}

///|
pub fn Vec3::length(self : Vec3) -> Float {
  self.length_sq().sqrt()
}

///|
pub fn Vec3::distance_sq(self : Vec3, other : Vec3) -> Float {
  (self - other).length_sq()
}

///|
pub fn Vec3::distance(self : Vec3, other : Vec3) -> Float {
  self.distance_sq(other).sqrt()
}

///|
/// Normalize, returning the zero vector for zero-length input (never `NaN`).
pub fn Vec3::normalize(self : Vec3) -> Vec3 {
  match self.try_normalize() {
    Some(n) => n
    None => Vec3::zero()
  }
}

///|
/// Normalize, returning `None` when the vector is (near) zero length.
pub fn Vec3::try_normalize(self : Vec3) -> Vec3? {
  let len = self.length()
  if len > EPSILON {
    Some({ x: self.x / len, y: self.y / len, z: self.z / len })
  } else {
    None
  }
}

///|
pub fn Vec3::lerp(self : Vec3, other : Vec3, t : Float) -> Vec3 {
  {
    x: lerp_f(self.x, other.x, t),
    y: lerp_f(self.y, other.y, t),
    z: lerp_f(self.z, other.z, t),
  }
}

///|
pub fn Vec3::min(self : Vec3, other : Vec3) -> Vec3 {
  {
    x: if self.x < other.x { self.x } else { other.x },
    y: if self.y < other.y { self.y } else { other.y },
    z: if self.z < other.z { self.z } else { other.z },
  }
}

///|
pub fn Vec3::max(self : Vec3, other : Vec3) -> Vec3 {
  {
    x: if self.x > other.x { self.x } else { other.x },
    y: if self.y > other.y { self.y } else { other.y },
    z: if self.z > other.z { self.z } else { other.z },
  }
}

///|
pub fn Vec3::abs(self : Vec3) -> Vec3 {
  { x: self.x.abs(), y: self.y.abs(), z: self.z.abs() }
}

///|
pub fn Vec3::clamp(self : Vec3, lo : Vec3, hi : Vec3) -> Vec3 {
  {
    x: clamp_f(self.x, lo.x, hi.x),
    y: clamp_f(self.y, lo.y, hi.y),
    z: clamp_f(self.z, lo.z, hi.z),
  }
}

///|
/// Mirror `self` about a (ideally normalized) `normal`.
pub fn Vec3::reflect(self : Vec3, normal : Vec3) -> Vec3 {
  self - normal.scale((2.0 : Float) * self.dot(normal))
}

///|
/// Refract `self` through a surface with (ideally normalized) `normal` and
/// ratio `eta` of indices of refraction. Returns the zero vector on total
/// internal reflection.
pub fn Vec3::refract(self : Vec3, normal : Vec3, eta : Float) -> Vec3 {
  let d = self.dot(normal)
  let k : Float = 1.0 - eta * eta * (1.0 - d * d)
  if k < 0.0 {
    Vec3::zero()
  } else {
    self.scale(eta) - normal.scale(eta * d + k.sqrt())
  }
}

///|
/// Project `self` onto `other`.
pub fn Vec3::project_onto(self : Vec3, other : Vec3) -> Vec3 {
  let d = other.length_sq()
  if d <= EPSILON {
    Vec3::zero()
  } else {
    other.scale(self.dot(other) / d)
  }
}

///|
/// Any unit vector perpendicular to `self`; depends only on `self`, so two
/// calls with the same input are reproducible (useful for building frames).
pub fn Vec3::any_orthonormal(self : Vec3) -> Vec3 {
  // Pick the world axis least aligned with `self`, then Gram-Schmidt it.
  let axis = if self.x.abs() < 0.5 {
    Vec3::unit_x()
  } else if self.y.abs() < 0.5 {
    Vec3::unit_y()
  } else {
    Vec3::unit_z()
  }
  (axis - self.scale(axis.dot(self))).normalize()
}

///|
pub fn Vec3::extend_w(self : Vec3, w : Float) -> Vec4 {
  { x: self.x, y: self.y, z: self.z, w }
}

///|
pub fn Vec3::truncate(self : Vec3) -> Vec2 {
  { x: self.x, y: self.y }
}

///|
pub fn Vec3::xy(self : Vec3) -> Vec2 {
  { x: self.x, y: self.y }
}

///|
pub fn Vec3::xz(self : Vec3) -> Vec2 {
  { x: self.x, y: self.z }
}

///|
pub fn Vec3::yz(self : Vec3) -> Vec2 {
  { x: self.y, y: self.z }
}

///|
pub fn Vec3::to_array(self : Vec3) -> FixedArray[Float] {
  let out : FixedArray[Float] = FixedArray::make(3, 0.0)
  out[0] = self.x
  out[1] = self.y
  out[2] = self.z
  out
}

///|
pub fn Vec3::from_array(arr : FixedArray[Float]) -> Vec3 {
  { x: arr[0], y: arr[1], z: arr[2] }
}

///|
pub fn Vec3::approx_eq(self : Vec3, other : Vec3, eps? : Float = EPSILON) -> Bool {
  approx_eq_f(self.x, other.x, eps~) &&
  approx_eq_f(self.y, other.y, eps~) &&
  approx_eq_f(self.z, other.z, eps~)
}

///|
pub fn Vec3::is_finite(self : Vec3) -> Bool {
  self.x.is_finite() && self.y.is_finite() && self.z.is_finite()
}

///|
/// Sort the three components ascending (useful for AABB min/max folding).
pub fn Vec3::sort(self : Vec3) -> Vec3 {
  let (a, b, c) = (self.x, self.y, self.z)
  let lo = if a < b { a } else { b }
  let hi = if a < b { b } else { a }
  if c < lo {
    { x: c, y: lo, z: hi }
  } else if c > hi {
    { x: lo, y: hi, z: c }
  } else {
    { x: lo, y: c, z: hi }
  }
}
