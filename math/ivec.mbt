// Integer vectors (`Int`, 32-bit) and unsigned integer vectors (`UInt`,
// 32-bit). Useful for pixel sizes, tile/grid coordinates, and GPU index math
// where floating point rounding must be exact.

// ---------------------------------------------------------------------------
// IVec2 / IVec3 / IVec4
// ---------------------------------------------------------------------------

///|
#valtype
#derive(Eq, Debug)
pub(all) struct IVec2 {
  x : Int
  y : Int
}

///|
pub impl Show for IVec2 with to_string(self) {
  "(\{self.x}, \{self.y})"
}

///|
pub fn IVec2::new(x : Int, y : Int) -> IVec2 {
  { x, y }
}

///|
pub fn IVec2::splat(v : Int) -> IVec2 {
  { x: v, y: v }
}

///|
pub fn IVec2::zero() -> IVec2 {
  { x: 0, y: 0 }
}

///|
pub fn IVec2::one() -> IVec2 {
  { x: 1, y: 1 }
}

///|
pub impl Add for IVec2 with add(self, other) {
  { x: self.x + other.x, y: self.y + other.y }
}

///|
pub impl Sub for IVec2 with sub(self, other) {
  { x: self.x - other.x, y: self.y - other.y }
}

///|
pub impl Mul for IVec2 with mul(self, other) {
  { x: self.x * other.x, y: self.y * other.y }
}

///|
pub impl Div for IVec2 with div(self, other) {
  { x: self.x / other.x, y: self.y / other.y }
}

///|
pub impl Neg for IVec2 with neg(self) {
  { x: -self.x, y: -self.y }
}

///|
pub fn IVec2::dot(self : IVec2, other : IVec2) -> Int {
  self.x * other.x + self.y * other.y
}

///|
pub fn IVec2::length_sq(self : IVec2) -> Int {
  self.dot(self)
}

///|
pub fn IVec2::as_vec2(self : IVec2) -> Vec2 {
  { x: Float::from_double(self.x.to_double()), y: Float::from_double(self.y.to_double()) }
}

///|
pub fn IVec2::as_uvec2(self : IVec2) -> UVec2 {
  { x: self.x.reinterpret_as_uint(), y: self.y.reinterpret_as_uint() }
}

///|
pub fn IVec2::to_array(self : IVec2) -> FixedArray[Int] {
  let out : FixedArray[Int] = FixedArray::make(2, 0)
  out[0] = self.x
  out[1] = self.y
  out
}

///|
#valtype
#derive(Eq, Debug)
pub(all) struct IVec3 {
  x : Int
  y : Int
  z : Int
}

///|
pub impl Show for IVec3 with to_string(self) {
  "(\{self.x}, \{self.y}, \{self.z})"
}

///|
pub fn IVec3::new(x : Int, y : Int, z : Int) -> IVec3 {
  { x, y, z }
}

///|
pub fn IVec3::splat(v : Int) -> IVec3 {
  { x: v, y: v, z: v }
}

///|
pub fn IVec3::zero() -> IVec3 {
  { x: 0, y: 0, z: 0 }
}

///|
pub fn IVec3::one() -> IVec3 {
  { x: 1, y: 1, z: 1 }
}

///|
pub impl Add for IVec3 with add(self, other) {
  { x: self.x + other.x, y: self.y + other.y, z: self.z + other.z }
}

///|
pub impl Sub for IVec3 with sub(self, other) {
  { x: self.x - other.x, y: self.y - other.y, z: self.z - other.z }
}

///|
pub impl Mul for IVec3 with mul(self, other) {
  { x: self.x * other.x, y: self.y * other.y, z: self.z * other.z }
}

///|
pub impl Div for IVec3 with div(self, other) {
  { x: self.x / other.x, y: self.y / other.y, z: self.z / other.z }
}

///|
pub impl Neg for IVec3 with neg(self) {
  { x: -self.x, y: -self.y, z: -self.z }
}

///|
pub fn IVec3::dot(self : IVec3, other : IVec3) -> Int {
  self.x * other.x + self.y * other.y + self.z * other.z
}

///|
pub fn IVec3::length_sq(self : IVec3) -> Int {
  self.dot(self)
}

///|
pub fn IVec3::as_vec3(self : IVec3) -> Vec3 {
  {
    x: Float::from_double(self.x.to_double()),
    y: Float::from_double(self.y.to_double()),
    z: Float::from_double(self.z.to_double()),
  }
}

///|
pub fn IVec3::as_uvec3(self : IVec3) -> UVec3 {
  { x: self.x.reinterpret_as_uint(), y: self.y.reinterpret_as_uint(), z: self.z.reinterpret_as_uint() }
}

///|
pub fn IVec3::to_array(self : IVec3) -> FixedArray[Int] {
  let out : FixedArray[Int] = FixedArray::make(3, 0)
  out[0] = self.x
  out[1] = self.y
  out[2] = self.z
  out
}

///|
#valtype
#derive(Eq, Debug)
pub(all) struct IVec4 {
  x : Int
  y : Int
  z : Int
  w : Int
}

///|
pub impl Show for IVec4 with to_string(self) {
  "(\{self.x}, \{self.y}, \{self.z}, \{self.w})"
}

///|
pub fn IVec4::new(x : Int, y : Int, z : Int, w : Int) -> IVec4 {
  { x, y, z, w }
}

///|
pub fn IVec4::splat(v : Int) -> IVec4 {
  { x: v, y: v, z: v, w: v }
}

///|
pub fn IVec4::zero() -> IVec4 {
  { x: 0, y: 0, z: 0, w: 0 }
}

///|
pub fn IVec4::one() -> IVec4 {
  { x: 1, y: 1, z: 1, w: 1 }
}

///|
pub impl Add for IVec4 with add(self, other) {
  {
    x: self.x + other.x,
    y: self.y + other.y,
    z: self.z + other.z,
    w: self.w + other.w,
  }
}

///|
pub impl Sub for IVec4 with sub(self, other) {
  {
    x: self.x - other.x,
    y: self.y - other.y,
    z: self.z - other.z,
    w: self.w - other.w,
  }
}

///|
pub impl Mul for IVec4 with mul(self, other) {
  {
    x: self.x * other.x,
    y: self.y * other.y,
    z: self.z * other.z,
    w: self.w * other.w,
  }
}

///|
pub impl Div for IVec4 with div(self, other) {
  {
    x: self.x / other.x,
    y: self.y / other.y,
    z: self.z / other.z,
    w: self.w / other.w,
  }
}

///|
pub impl Neg for IVec4 with neg(self) {
  { x: -self.x, y: -self.y, z: -self.z, w: -self.w }
}

///|
pub fn IVec4::dot(self : IVec4, other : IVec4) -> Int {
  self.x * other.x + self.y * other.y + self.z * other.z + self.w * other.w
}

///|
pub fn IVec4::length_sq(self : IVec4) -> Int {
  self.dot(self)
}

///|
pub fn IVec4::as_vec4(self : IVec4) -> Vec4 {
  {
    x: Float::from_double(self.x.to_double()),
    y: Float::from_double(self.y.to_double()),
    z: Float::from_double(self.z.to_double()),
    w: Float::from_double(self.w.to_double()),
  }
}

///|
pub fn IVec4::as_uvec4(self : IVec4) -> UVec4 {
  {
    x: self.x.reinterpret_as_uint(),
    y: self.y.reinterpret_as_uint(),
    z: self.z.reinterpret_as_uint(),
    w: self.w.reinterpret_as_uint(),
  }
}

///|
#valtype
#derive(Eq, Debug)
pub(all) struct UVec2 {
  x : UInt
  y : UInt
}

///|
pub impl Show for UVec2 with to_string(self) {
  "(\{self.x}, \{self.y})"
}

///|
pub fn UVec2::new(x : UInt, y : UInt) -> UVec2 {
  { x, y }
}

///|
pub fn UVec2::splat(v : UInt) -> UVec2 {
  { x: v, y: v }
}

///|
pub fn UVec2::zero() -> UVec2 {
  { x: 0, y: 0 }
}

///|
pub fn UVec2::one() -> UVec2 {
  { x: 1, y: 1 }
}

///|
pub impl Add for UVec2 with add(self, other) {
  { x: self.x + other.x, y: self.y + other.y }
}

///|
pub impl Sub for UVec2 with sub(self, other) {
  { x: self.x - other.x, y: self.y - other.y }
}

///|
pub impl Mul for UVec2 with mul(self, other) {
  { x: self.x * other.x, y: self.y * other.y }
}

///|
pub impl Div for UVec2 with div(self, other) {
  { x: self.x / other.x, y: self.y / other.y }
}

///|
pub fn UVec2::dot(self : UVec2, other : UVec2) -> UInt {
  self.x * other.x + self.y * other.y
}

///|
pub fn UVec2::as_ivec2(self : UVec2) -> IVec2 {
  { x: self.x.reinterpret_as_int(), y: self.y.reinterpret_as_int() }
}

///|
/// Integer size as `(width, height)` in pixels.
pub fn UVec2::to_vec2(self : UVec2) -> Vec2 {
  { x: Float::from_double(self.x.to_double()), y: Float::from_double(self.y.to_double()) }
}

///|
#valtype
#derive(Eq, Debug)
pub(all) struct UVec3 {
  x : UInt
  y : UInt
  z : UInt
}

///|
pub impl Show for UVec3 with to_string(self) {
  "(\{self.x}, \{self.y}, \{self.z})"
}

///|
pub fn UVec3::new(x : UInt, y : UInt, z : UInt) -> UVec3 {
  { x, y, z }
}

///|
pub fn UVec3::splat(v : UInt) -> UVec3 {
  { x: v, y: v, z: v }
}

///|
pub fn UVec3::zero() -> UVec3 {
  { x: 0, y: 0, z: 0 }
}

///|
pub impl Add for UVec3 with add(self, other) {
  { x: self.x + other.x, y: self.y + other.y, z: self.z + other.z }
}

///|
pub impl Sub for UVec3 with sub(self, other) {
  { x: self.x - other.x, y: self.y - other.y, z: self.z - other.z }
}

///|
pub impl Mul for UVec3 with mul(self, other) {
  { x: self.x * other.x, y: self.y * other.y, z: self.z * other.z }
}

///|
pub fn UVec3::dot(self : UVec3, other : UVec3) -> UInt {
  self.x * other.x + self.y * other.y + self.z * other.z
}

///|
#valtype
#derive(Eq, Debug)
pub(all) struct UVec4 {
  x : UInt
  y : UInt
  z : UInt
  w : UInt
}

///|
pub impl Show for UVec4 with to_string(self) {
  "(\{self.x}, \{self.y}, \{self.z}, \{self.w})"
}

///|
pub fn UVec4::new(x : UInt, y : UInt, z : UInt, w : UInt) -> UVec4 {
  { x, y, z, w }
}

///|
pub fn UVec4::splat(v : UInt) -> UVec4 {
  { x: v, y: v, z: v, w: v }
}

///|
pub fn UVec4::zero() -> UVec4 {
  { x: 0, y: 0, z: 0, w: 0 }
}

///|
pub impl Add for UVec4 with add(self, other) {
  {
    x: self.x + other.x,
    y: self.y + other.y,
    z: self.z + other.z,
    w: self.w + other.w,
  }
}

///|
pub impl Sub for UVec4 with sub(self, other) {
  {
    x: self.x - other.x,
    y: self.y - other.y,
    z: self.z - other.z,
    w: self.w - other.w,
  }
}

///|
pub impl Mul for UVec4 with mul(self, other) {
  {
    x: self.x * other.x,
    y: self.y * other.y,
    z: self.z * other.z,
    w: self.w * other.w,
  }
}

///|
pub fn UVec4::dot(self : UVec4, other : UVec4) -> UInt {
  self.x * other.x + self.y * other.y + self.z * other.z + self.w * other.w
}

///|
/// Convert a normalized `Vec4` colour to 8-bit RGBA (rounds, then clamps).
pub fn UVec4::from_vec4_rgba8(v : Vec4) -> UVec4 {
  fn q(x : Float) -> UInt {
    (saturate(x) * 255.0 + 0.5).to_int().reinterpret_as_uint()
  }

  { x: q(v.x), y: q(v.y), z: q(v.z), w: q(v.w) }
}
