// 4-component single-precision vector. Layout-compatible with a 128-bit SIMD
// lane (`f32x4`) and with `std140`/`std430` `vec4` on the GPU.

///|
#valtype
#derive(Eq, Debug)
pub(all) struct Vec4 {
  x : Float
  y : Float
  z : Float
  w : Float
}

///|
pub impl Show for Vec4 with to_string(self) {
  "(\{self.x}, \{self.y}, \{self.z}, \{self.w})"
}

///|
pub fn Vec4::new(x : Float, y : Float, z : Float, w : Float) -> Vec4 {
  { x, y, z, w }
}

///|
pub fn Vec4::splat(v : Float) -> Vec4 {
  { x: v, y: v, z: v, w: v }
}

///|
pub fn Vec4::zero() -> Vec4 {
  { x: 0.0, y: 0.0, z: 0.0, w: 0.0 }
}

///|
pub fn Vec4::one() -> Vec4 {
  { x: 1.0, y: 1.0, z: 1.0, w: 1.0 }
}

///|
pub fn Vec4::unit_x() -> Vec4 {
  { x: 1.0, y: 0.0, z: 0.0, w: 0.0 }
}

///|
pub fn Vec4::unit_y() -> Vec4 {
  { x: 0.0, y: 1.0, z: 0.0, w: 0.0 }
}

///|
pub fn Vec4::unit_z() -> Vec4 {
  { x: 0.0, y: 0.0, z: 1.0, w: 0.0 }
}

///|
pub fn Vec4::unit_w() -> Vec4 {
  { x: 0.0, y: 0.0, z: 0.0, w: 1.0 }
}

///|
pub impl Add for Vec4 with add(self, other) {
  {
    x: self.x + other.x,
    y: self.y + other.y,
    z: self.z + other.z,
    w: self.w + other.w,
  }
}

///|
pub impl Sub for Vec4 with sub(self, other) {
  {
    x: self.x - other.x,
    y: self.y - other.y,
    z: self.z - other.z,
    w: self.w - other.w,
  }
}

///|
/// Component-wise (Hadamard) product; use `scale` for scalar multiplication.
pub impl Mul for Vec4 with mul(self, other) {
  {
    x: self.x * other.x,
    y: self.y * other.y,
    z: self.z * other.z,
    w: self.w * other.w,
  }
}

///|
pub impl Div for Vec4 with div(self, other) {
  {
    x: self.x / other.x,
    y: self.y / other.y,
    z: self.z / other.z,
    w: self.w / other.w,
  }
}

///|
pub impl Neg for Vec4 with neg(self) {
  { x: -self.x, y: -self.y, z: -self.z, w: -self.w }
}

///|
pub fn Vec4::scale(self : Vec4, s : Float) -> Vec4 {
  { x: self.x * s, y: self.y * s, z: self.z * s, w: self.w * s }
}

///|
pub fn Vec4::dot(self : Vec4, other : Vec4) -> Float {
  self.x * other.x + self.y * other.y + self.z * other.z + self.w * other.w
}

///|
pub fn Vec4::length_sq(self : Vec4) -> Float {
  self.dot(self)
}

///|
pub fn Vec4::length(self : Vec4) -> Float {
  self.length_sq().sqrt()
}

///|
/// Normalize, returning the zero vector for zero-length input (never `NaN`).
pub fn Vec4::normalize(self : Vec4) -> Vec4 {
  match self.try_normalize() {
    Some(n) => n
    None => Vec4::zero()
  }
}

///|
pub fn Vec4::try_normalize(self : Vec4) -> Vec4? {
  let len = self.length()
  if len > EPSILON {
    Some({
      x: self.x / len,
      y: self.y / len,
      z: self.z / len,
      w: self.w / len,
    })
  } else {
    None
  }
}

///|
pub fn Vec4::lerp(self : Vec4, other : Vec4, t : Float) -> Vec4 {
  {
    x: lerp_f(self.x, other.x, t),
    y: lerp_f(self.y, other.y, t),
    z: lerp_f(self.z, other.z, t),
    w: lerp_f(self.w, other.w, t),
  }
}

///|
pub fn Vec4::min(self : Vec4, other : Vec4) -> Vec4 {
  {
    x: if self.x < other.x { self.x } else { other.x },
    y: if self.y < other.y { self.y } else { other.y },
    z: if self.z < other.z { self.z } else { other.z },
    w: if self.w < other.w { self.w } else { other.w },
  }
}

///|
pub fn Vec4::max(self : Vec4, other : Vec4) -> Vec4 {
  {
    x: if self.x > other.x { self.x } else { other.x },
    y: if self.y > other.y { self.y } else { other.y },
    z: if self.z > other.z { self.z } else { other.z },
    w: if self.w > other.w { self.w } else { other.w },
  }
}

///|
pub fn Vec4::abs(self : Vec4) -> Vec4 {
  { x: self.x.abs(), y: self.y.abs(), z: self.z.abs(), w: self.w.abs() }
}

///|
pub fn Vec4::truncate(self : Vec4) -> Vec3 {
  { x: self.x, y: self.y, z: self.z }
}

///|
pub fn Vec4::xyz(self : Vec4) -> Vec3 {
  { x: self.x, y: self.y, z: self.z }
}

///|
pub fn Vec4::xy(self : Vec4) -> Vec2 {
  { x: self.x, y: self.y }
}

///|
/// Perspective divide. Returns `self` unchanged when `|w| <= EPSILON`.
pub fn Vec4::perspective_divide(self : Vec4) -> Vec4 {
  if self.w.abs() > EPSILON {
    {
      x: self.x / self.w,
      y: self.y / self.w,
      z: self.z / self.w,
      w: 1.0,
    }
  } else {
    self
  }
}

///|
/// Component by index (`0..=3`); out-of-range indices yield `0`.
pub fn Vec4::component(self : Vec4, i : Int) -> Float {
  if i == 0 {
    self.x
  } else if i == 1 {
    self.y
  } else if i == 2 {
    self.z
  } else if i == 3 {
    self.w
  } else {
    0.0
  }
}

///|
pub fn Vec4::to_array(self : Vec4) -> FixedArray[Float] {
  let out : FixedArray[Float] = FixedArray::make(4, 0.0)
  out[0] = self.x
  out[1] = self.y
  out[2] = self.z
  out[3] = self.w
  out
}

///|
pub fn Vec4::from_array(arr : FixedArray[Float]) -> Vec4 {
  { x: arr[0], y: arr[1], z: arr[2], w: arr[3] }
}

///|
pub fn Vec4::approx_eq(self : Vec4, other : Vec4, eps? : Float = EPSILON) -> Bool {
  approx_eq_f(self.x, other.x, eps~) &&
  approx_eq_f(self.y, other.y, eps~) &&
  approx_eq_f(self.z, other.z, eps~) &&
  approx_eq_f(self.w, other.w, eps~)
}

///|
pub fn Vec4::is_finite(self : Vec4) -> Bool {
  self.x.is_finite() && self.y.is_finite() && self.z.is_finite() && self.w.is_finite()
}
