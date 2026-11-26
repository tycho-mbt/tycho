// Double-precision vectors for large-world cameras, shadow frusta, and any
// construction that must not lose precision before being down-cast to `Float`
// for GPU upload.

///|
pub const EPSILON : Double = 1.0e-12

///|
#valtype
#derive(Eq, Debug)
pub(all) struct DVec2 {
  x : Double
  y : Double
}

///|
pub impl Show for DVec2 with to_string(self) {
  "(\{self.x}, \{self.y})"
}

///|
pub fn DVec2::new(x : Double, y : Double) -> DVec2 {
  { x, y }
}

///|
pub fn DVec2::splat(v : Double) -> DVec2 {
  { x: v, y: v }
}

///|
pub fn DVec2::zero() -> DVec2 {
  { x: 0.0, y: 0.0 }
}

///|
pub fn DVec2::one() -> DVec2 {
  { x: 1.0, y: 1.0 }
}

///|
pub impl Add for DVec2 with add(self, other) {
  { x: self.x + other.x, y: self.y + other.y }
}

///|
pub impl Sub for DVec2 with sub(self, other) {
  { x: self.x - other.x, y: self.y - other.y }
}

///|
pub impl Mul for DVec2 with mul(self, other) {
  { x: self.x * other.x, y: self.y * other.y }
}

///|
pub impl Div for DVec2 with div(self, other) {
  { x: self.x / other.x, y: self.y / other.y }
}

///|
pub impl Neg for DVec2 with neg(self) {
  { x: -self.x, y: -self.y }
}

///|
pub fn DVec2::scale(self : DVec2, s : Double) -> DVec2 {
  { x: self.x * s, y: self.y * s }
}

///|
pub fn DVec2::dot(self : DVec2, other : DVec2) -> Double {
  self.x * other.x + self.y * other.y
}

///|
pub fn DVec2::cross(self : DVec2, other : DVec2) -> Double {
  self.x * other.y - self.y * other.x
}

///|
pub fn DVec2::length_sq(self : DVec2) -> Double {
  self.dot(self)
}

///|
pub fn DVec2::length(self : DVec2) -> Double {
  self.length_sq().sqrt()
}

///|
pub fn DVec2::normalize(self : DVec2) -> DVec2 {
  let len = self.length()
  if len > EPSILON {
    { x: self.x / len, y: self.y / len }
  } else {
    DVec2::zero()
  }
}

///|
pub fn DVec2::lerp(self : DVec2, other : DVec2, t : Double) -> DVec2 {
  {
    x: self.x + (other.x - self.x) * t,
    y: self.y + (other.y - self.y) * t,
  }
}

///|
pub fn DVec2::to_vec2(self : DVec2) -> @tmath.Vec2 {
  { x: Float::from_double(self.x), y: Float::from_double(self.y) }
}

///|
pub fn DVec2::from_vec2(v : @tmath.Vec2) -> DVec2 {
  { x: v.x.to_double(), y: v.y.to_double() }
}

///|
pub fn DVec2::approx_eq(self : DVec2, other : DVec2, eps? : Double = EPSILON) -> Bool {
  (self.x - other.x).abs() <= eps && (self.y - other.y).abs() <= eps
}

///|
#valtype
#derive(Eq, Debug)
pub(all) struct DVec3 {
  x : Double
  y : Double
  z : Double
}

///|
pub impl Show for DVec3 with to_string(self) {
  "(\{self.x}, \{self.y}, \{self.z})"
}

///|
pub fn DVec3::new(x : Double, y : Double, z : Double) -> DVec3 {
  { x, y, z }
}

///|
pub fn DVec3::splat(v : Double) -> DVec3 {
  { x: v, y: v, z: v }
}

///|
pub fn DVec3::zero() -> DVec3 {
  { x: 0.0, y: 0.0, z: 0.0 }
}

///|
pub fn DVec3::one() -> DVec3 {
  { x: 1.0, y: 1.0, z: 1.0 }
}

///|
pub fn DVec3::unit_x() -> DVec3 {
  { x: 1.0, y: 0.0, z: 0.0 }
}

///|
pub fn DVec3::unit_y() -> DVec3 {
  { x: 0.0, y: 1.0, z: 0.0 }
}

///|
pub fn DVec3::unit_z() -> DVec3 {
  { x: 0.0, y: 0.0, z: 1.0 }
}

///|
pub impl Add for DVec3 with add(self, other) {
  { x: self.x + other.x, y: self.y + other.y, z: self.z + other.z }
}

///|
pub impl Sub for DVec3 with sub(self, other) {
  { x: self.x - other.x, y: self.y - other.y, z: self.z - other.z }
}

///|
pub impl Mul for DVec3 with mul(self, other) {
  { x: self.x * other.x, y: self.y * other.y, z: self.z * other.z }
}

///|
pub impl Div for DVec3 with div(self, other) {
  { x: self.x / other.x, y: self.y / other.y, z: self.z / other.z }
}

///|
pub impl Neg for DVec3 with neg(self) {
  { x: -self.x, y: -self.y, z: -self.z }
}

///|
pub fn DVec3::scale(self : DVec3, s : Double) -> DVec3 {
  { x: self.x * s, y: self.y * s, z: self.z * s }
}

///|
pub fn DVec3::dot(self : DVec3, other : DVec3) -> Double {
  self.x * other.x + self.y * other.y + self.z * other.z
}

///|
pub fn DVec3::cross(self : DVec3, other : DVec3) -> DVec3 {
  {
    x: self.y * other.z - self.z * other.y,
    y: self.z * other.x - self.x * other.z,
    z: self.x * other.y - self.y * other.x,
  }
}

///|
pub fn DVec3::length_sq(self : DVec3) -> Double {
  self.dot(self)
}

///|
pub fn DVec3::length(self : DVec3) -> Double {
  self.length_sq().sqrt()
}

///|
pub fn DVec3::distance(self : DVec3, other : DVec3) -> Double {
  (self - other).length()
}

///|
pub fn DVec3::normalize(self : DVec3) -> DVec3 {
  let len = self.length()
  if len > EPSILON {
    { x: self.x / len, y: self.y / len, z: self.z / len }
  } else {
    DVec3::zero()
  }
}

///|
pub fn DVec3::try_normalize(self : DVec3) -> DVec3? {
  let len = self.length()
  if len > EPSILON {
    Some({ x: self.x / len, y: self.y / len, z: self.z / len })
  } else {
    None
  }
}

///|
pub fn DVec3::lerp(self : DVec3, other : DVec3, t : Double) -> DVec3 {
  {
    x: self.x + (other.x - self.x) * t,
    y: self.y + (other.y - self.y) * t,
    z: self.z + (other.z - self.z) * t,
  }
}

///|
pub fn DVec3::min(self : DVec3, other : DVec3) -> DVec3 {
  {
    x: if self.x < other.x { self.x } else { other.x },
    y: if self.y < other.y { self.y } else { other.y },
    z: if self.z < other.z { self.z } else { other.z },
  }
}

///|
pub fn DVec3::max(self : DVec3, other : DVec3) -> DVec3 {
  {
    x: if self.x > other.x { self.x } else { other.x },
    y: if self.y > other.y { self.y } else { other.y },
    z: if self.z > other.z { self.z } else { other.z },
  }
}

///|
pub fn DVec3::extend_w(self : DVec3, w : Double) -> DVec4 {
  { x: self.x, y: self.y, z: self.z, w }
}

///|
pub fn DVec3::truncate(self : DVec3) -> DVec2 {
  { x: self.x, y: self.y }
}

///|
/// Down-cast to the single-precision vector used on the GPU.
pub fn DVec3::to_vec3(self : DVec3) -> @tmath.Vec3 {
  {
    x: Float::from_double(self.x),
    y: Float::from_double(self.y),
    z: Float::from_double(self.z),
  }
}

///|
pub fn DVec3::from_vec3(v : @tmath.Vec3) -> DVec3 {
  { x: v.x.to_double(), y: v.y.to_double(), z: v.z.to_double() }
}

///|
pub fn DVec3::approx_eq(self : DVec3, other : DVec3, eps? : Double = EPSILON) -> Bool {
  (self.x - other.x).abs() <= eps &&
  (self.y - other.y).abs() <= eps &&
  (self.z - other.z).abs() <= eps
}

///|
pub fn DVec3::is_finite(self : DVec3) -> Bool {
  self.x.is_finite() && self.y.is_finite() && self.z.is_finite()
}

///|
#valtype
#derive(Eq, Debug)
pub(all) struct DVec4 {
  x : Double
  y : Double
  z : Double
  w : Double
}

///|
pub impl Show for DVec4 with to_string(self) {
  "(\{self.x}, \{self.y}, \{self.z}, \{self.w})"
}

///|
pub fn DVec4::new(x : Double, y : Double, z : Double, w : Double) -> DVec4 {
  { x, y, z, w }
}

///|
pub fn DVec4::splat(v : Double) -> DVec4 {
  { x: v, y: v, z: v, w: v }
}

///|
pub fn DVec4::zero() -> DVec4 {
  { x: 0.0, y: 0.0, z: 0.0, w: 0.0 }
}

///|
pub fn DVec4::one() -> DVec4 {
  { x: 1.0, y: 1.0, z: 1.0, w: 1.0 }
}

///|
pub fn DVec4::unit_w() -> DVec4 {
  { x: 0.0, y: 0.0, z: 0.0, w: 1.0 }
}

///|
pub impl Add for DVec4 with add(self, other) {
  {
    x: self.x + other.x,
    y: self.y + other.y,
    z: self.z + other.z,
    w: self.w + other.w,
  }
}

///|
pub impl Sub for DVec4 with sub(self, other) {
  {
    x: self.x - other.x,
    y: self.y - other.y,
    z: self.z - other.z,
    w: self.w - other.w,
  }
}

///|
pub impl Mul for DVec4 with mul(self, other) {
  {
    x: self.x * other.x,
    y: self.y * other.y,
    z: self.z * other.z,
    w: self.w * other.w,
  }
}

///|
pub impl Neg for DVec4 with neg(self) {
  { x: -self.x, y: -self.y, z: -self.z, w: -self.w }
}

///|
pub fn DVec4::scale(self : DVec4, s : Double) -> DVec4 {
  { x: self.x * s, y: self.y * s, z: self.z * s, w: self.w * s }
}

///|
pub fn DVec4::dot(self : DVec4, other : DVec4) -> Double {
  self.x * other.x + self.y * other.y + self.z * other.z + self.w * other.w
}

///|
pub fn DVec4::length_sq(self : DVec4) -> Double {
  self.dot(self)
}

///|
pub fn DVec4::length(self : DVec4) -> Double {
  self.length_sq().sqrt()
}

///|
pub fn DVec4::normalize(self : DVec4) -> DVec4 {
  let len = self.length()
  if len > EPSILON {
    {
      x: self.x / len,
      y: self.y / len,
      z: self.z / len,
      w: self.w / len,
    }
  } else {
    DVec4::zero()
  }
}

///|
pub fn DVec4::truncate(self : DVec4) -> DVec3 {
  { x: self.x, y: self.y, z: self.z }
}

///|
pub fn DVec4::xyz(self : DVec4) -> DVec3 {
  { x: self.x, y: self.y, z: self.z }
}

///|
pub fn DVec4::to_vec4(self : DVec4) -> @tmath.Vec4 {
  {
    x: Float::from_double(self.x),
    y: Float::from_double(self.y),
    z: Float::from_double(self.z),
    w: Float::from_double(self.w),
  }
}

///|
pub fn DVec4::approx_eq(self : DVec4, other : DVec4, eps? : Double = EPSILON) -> Bool {
  (self.x - other.x).abs() <= eps &&
  (self.y - other.y).abs() <= eps &&
  (self.z - other.z).abs() <= eps &&
  (self.w - other.w).abs() <= eps
}
