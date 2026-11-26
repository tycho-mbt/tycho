// 2x2 single-precision matrix, stored as two column vectors
// (`x_axis`, `y_axis`). Column-major, matching GLSL / WGSL `mat2`.

///|
#valtype
#derive(Eq, Debug)
pub(all) struct Mat2 {
  x_axis : Vec2
  y_axis : Vec2
}

///|
pub impl Show for Mat2 with to_string(self) {
  "[[\{self.x_axis.x}, \{self.y_axis.x}], [\{self.x_axis.y}, \{self.y_axis.y}]]"
}

///|
pub fn Mat2::identity() -> Mat2 {
  { x_axis: { x: 1.0, y: 0.0 }, y_axis: { x: 0.0, y: 1.0 } }
}

///|
pub fn Mat2::from_cols(x_axis : Vec2, y_axis : Vec2) -> Mat2 {
  { x_axis, y_axis }
}

///|
pub fn Mat2::from_cols_array(arr : FixedArray[Float]) -> Mat2 {
  {
    x_axis: { x: arr[0], y: arr[1] },
    y_axis: { x: arr[2], y: arr[3] },
  }
}

///|
pub fn Mat2::from_diagonal(diag : Vec2) -> Mat2 {
  { x_axis: { x: diag.x, y: 0.0 }, y_axis: { x: 0.0, y: diag.y } }
}

///|
pub fn Mat2::from_scale(sx : Float, sy : Float) -> Mat2 {
  { x_axis: { x: sx, y: 0.0 }, y_axis: { x: 0.0, y: sy } }
}

///|
/// Rotation by `radians` (counter-clockwise).
pub fn Mat2::from_angle(radians : Float) -> Mat2 {
  let (s, c) = sin_cos(radians)
  { x_axis: { x: c, y: s }, y_axis: { x: -s, y: c } }
}

///|
pub fn Mat2::row0(self : Mat2) -> Vec2 {
  { x: self.x_axis.x, y: self.y_axis.x }
}

///|
pub fn Mat2::row1(self : Mat2) -> Vec2 {
  { x: self.x_axis.y, y: self.y_axis.y }
}

///|
pub fn Mat2::at(self : Mat2, row : Int, col : Int) -> Float {
  if col == 0 {
    if row == 0 {
      self.x_axis.x
    } else {
      self.x_axis.y
    }
  } else if row == 0 {
    self.y_axis.x
  } else {
    self.y_axis.y
  }
}

///|
pub impl Add for Mat2 with add(self, other) {
  {
    x_axis: self.x_axis + other.x_axis,
    y_axis: self.y_axis + other.y_axis,
  }
}

///|
pub impl Sub for Mat2 with sub(self, other) {
  {
    x_axis: self.x_axis - other.x_axis,
    y_axis: self.y_axis - other.y_axis,
  }
}

///|
/// Matrix product `self * other` (column vectors: `result.columns = self *
/// other.columns`).
pub impl Mul for Mat2 with mul(self, other) {
  { x_axis: self.mul_vec2(other.x_axis), y_axis: self.mul_vec2(other.y_axis) }
}

///|
pub fn Mat2::mul_vec2(self : Mat2, v : Vec2) -> Vec2 {
  self.x_axis.scale(v.x) + self.y_axis.scale(v.y)
}

///|
pub fn Mat2::scale(self : Mat2, s : Float) -> Mat2 {
  { x_axis: self.x_axis.scale(s), y_axis: self.y_axis.scale(s) }
}

///|
pub fn Mat2::transpose(self : Mat2) -> Mat2 {
  { x_axis: self.row0(), y_axis: self.row1() }
}

///|
pub fn Mat2::determinant(self : Mat2) -> Float {
  self.x_axis.x * self.y_axis.y - self.y_axis.x * self.x_axis.y
}

///|
/// Inverse, or `None` when the matrix is singular.
pub fn Mat2::inverse(self : Mat2) -> Mat2? {
  let det = self.determinant()
  if det == 0.0 || !det.is_finite() {
    return None
  }
  let inv : Float = 1.0 / det
  Some({
    x_axis: { x: self.y_axis.y * inv, y: -self.x_axis.y * inv },
    y_axis: { x: -self.y_axis.x * inv, y: self.x_axis.x * inv },
  })
}

///|
pub fn Mat2::to_cols_array(self : Mat2) -> FixedArray[Float] {
  let out : FixedArray[Float] = FixedArray::make(4, 0.0)
  out[0] = self.x_axis.x
  out[1] = self.x_axis.y
  out[2] = self.y_axis.x
  out[3] = self.y_axis.y
  out
}

///|
pub fn Mat2::write_to(self : Mat2, dst : FixedArray[Float], offset : Int) -> Unit {
  dst[offset] = self.x_axis.x
  dst[offset + 1] = self.x_axis.y
  dst[offset + 2] = self.y_axis.x
  dst[offset + 3] = self.y_axis.y
}

///|
pub fn Mat2::to_mat3(self : Mat2) -> Mat3 {
  {
    x_axis: { x: self.x_axis.x, y: self.x_axis.y, z: 0.0 },
    y_axis: { x: self.y_axis.x, y: self.y_axis.y, z: 0.0 },
    z_axis: { x: 0.0, y: 0.0, z: 1.0 },
  }
}

///|
pub fn Mat2::to_mat4(self : Mat2) -> Mat4 {
  {
    x_axis: { x: self.x_axis.x, y: self.x_axis.y, z: 0.0, w: 0.0 },
    y_axis: { x: self.y_axis.x, y: self.y_axis.y, z: 0.0, w: 0.0 },
    z_axis: { x: 0.0, y: 0.0, z: 1.0, w: 0.0 },
    w_axis: { x: 0.0, y: 0.0, z: 0.0, w: 1.0 },
  }
}

///|
pub fn Mat2::approx_eq(self : Mat2, other : Mat2, eps? : Float = EPSILON) -> Bool {
  self.x_axis.approx_eq(other.x_axis, eps~) &&
  self.y_axis.approx_eq(other.y_axis, eps~)
}
