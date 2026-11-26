// 3x3 single-precision matrix, stored as three column vectors. Column-major,
// matching GLSL / WGSL `mat3`. Also used as the linear part of `Affine3` and
// for normal matrices (`inverse_transpose`).

///|
#valtype
#derive(Eq, Debug)
pub(all) struct Mat3 {
  x_axis : Vec3
  y_axis : Vec3
  z_axis : Vec3
}

///|
pub impl Show for Mat3 with to_string(self) {
  let r0 = "[\{self.x_axis.x}, \{self.y_axis.x}, \{self.z_axis.x}]"
  let r1 = "[\{self.x_axis.y}, \{self.y_axis.y}, \{self.z_axis.y}]"
  let r2 = "[\{self.x_axis.z}, \{self.y_axis.z}, \{self.z_axis.z}]"
  "[\{r0}, \{r1}, \{r2}]"
}

///|
pub fn Mat3::identity() -> Mat3 {
  {
    x_axis: { x: 1.0, y: 0.0, z: 0.0 },
    y_axis: { x: 0.0, y: 1.0, z: 0.0 },
    z_axis: { x: 0.0, y: 0.0, z: 1.0 },
  }
}

///|
pub fn Mat3::from_cols(x_axis : Vec3, y_axis : Vec3, z_axis : Vec3) -> Mat3 {
  { x_axis, y_axis, z_axis }
}

///|
pub fn Mat3::from_cols_array(arr : FixedArray[Float]) -> Mat3 {
  {
    x_axis: { x: arr[0], y: arr[1], z: arr[2] },
    y_axis: { x: arr[3], y: arr[4], z: arr[5] },
    z_axis: { x: arr[6], y: arr[7], z: arr[8] },
  }
}

///|
pub fn Mat3::from_diagonal(diag : Vec3) -> Mat3 {
  {
    x_axis: { x: diag.x, y: 0.0, z: 0.0 },
    y_axis: { x: 0.0, y: diag.y, z: 0.0 },
    z_axis: { x: 0.0, y: 0.0, z: diag.z },
  }
}

///|
pub fn Mat3::from_scale(s : Vec3) -> Mat3 {
  Mat3::from_diagonal(s)
}

///|
pub fn Mat3::from_rotation_x(radians : Float) -> Mat3 {
  let (s, c) = sin_cos(radians)
  {
    x_axis: { x: 1.0, y: 0.0, z: 0.0 },
    y_axis: { x: 0.0, y: c, z: s },
    z_axis: { x: 0.0, y: -s, z: c },
  }
}

///|
pub fn Mat3::from_rotation_y(radians : Float) -> Mat3 {
  let (s, c) = sin_cos(radians)
  {
    x_axis: { x: c, y: 0.0, z: -s },
    y_axis: { x: 0.0, y: 1.0, z: 0.0 },
    z_axis: { x: s, y: 0.0, z: c },
  }
}

///|
pub fn Mat3::from_rotation_z(radians : Float) -> Mat3 {
  let (s, c) = sin_cos(radians)
  {
    x_axis: { x: c, y: s, z: 0.0 },
    y_axis: { x: -s, y: c, z: 0.0 },
    z_axis: { x: 0.0, y: 0.0, z: 1.0 },
  }
}

///|
pub fn Mat3::from_quat(q : Quat) -> Mat3 {
  q.to_mat3()
}

///|
pub fn Mat3::row0(self : Mat3) -> Vec3 {
  { x: self.x_axis.x, y: self.y_axis.x, z: self.z_axis.x }
}

///|
pub fn Mat3::row1(self : Mat3) -> Vec3 {
  { x: self.x_axis.y, y: self.y_axis.y, z: self.z_axis.y }
}

///|
pub fn Mat3::row2(self : Mat3) -> Vec3 {
  { x: self.x_axis.z, y: self.y_axis.z, z: self.z_axis.z }
}

///|
/// Element at `(row, col)`; `0` for out-of-range indices.
pub fn Mat3::at(self : Mat3, row : Int, col : Int) -> Float {
  let v = if col == 0 {
    self.x_axis
  } else if col == 1 {
    self.y_axis
  } else {
    self.z_axis
  }
  if row == 0 {
    v.x
  } else if row == 1 {
    v.y
  } else {
    v.z
  }
}

///|
pub impl Add for Mat3 with add(self, other) {
  {
    x_axis: self.x_axis + other.x_axis,
    y_axis: self.y_axis + other.y_axis,
    z_axis: self.z_axis + other.z_axis,
  }
}

///|
pub impl Sub for Mat3 with sub(self, other) {
  {
    x_axis: self.x_axis - other.x_axis,
    y_axis: self.y_axis - other.y_axis,
    z_axis: self.z_axis - other.z_axis,
  }
}

///|
pub impl Mul for Mat3 with mul(self, other) {
  {
    x_axis: self.mul_vec3(other.x_axis),
    y_axis: self.mul_vec3(other.y_axis),
    z_axis: self.mul_vec3(other.z_axis),
  }
}

///|
pub fn Mat3::mul_vec3(self : Mat3, v : Vec3) -> Vec3 {
  self.x_axis.scale(v.x) + self.y_axis.scale(v.y) + self.z_axis.scale(v.z)
}

///|
pub fn Mat3::scale(self : Mat3, s : Float) -> Mat3 {
  {
    x_axis: self.x_axis.scale(s),
    y_axis: self.y_axis.scale(s),
    z_axis: self.z_axis.scale(s),
  }
}

///|
pub fn Mat3::transpose(self : Mat3) -> Mat3 {
  { x_axis: self.row0(), y_axis: self.row1(), z_axis: self.row2() }
}

///|
pub fn Mat3::determinant(self : Mat3) -> Float {
  let m00 = self.x_axis.x
  let m01 = self.y_axis.x
  let m02 = self.z_axis.x
  let m10 = self.x_axis.y
  let m11 = self.y_axis.y
  let m12 = self.z_axis.y
  let m20 = self.x_axis.z
  let m21 = self.y_axis.z
  let m22 = self.z_axis.z
  m00 * (m11 * m22 - m12 * m21) -
  m01 * (m10 * m22 - m12 * m20) +
  m02 * (m10 * m21 - m11 * m20)
}

///|
/// Inverse, or `None` when the matrix is singular.
pub fn Mat3::inverse(self : Mat3) -> Mat3? {
  let m00 = self.x_axis.x
  let m01 = self.y_axis.x
  let m02 = self.z_axis.x
  let m10 = self.x_axis.y
  let m11 = self.y_axis.y
  let m12 = self.z_axis.y
  let m20 = self.x_axis.z
  let m21 = self.y_axis.z
  let m22 = self.z_axis.z
  let det = m00 * (m11 * m22 - m12 * m21) -
    m01 * (m10 * m22 - m12 * m20) +
    m02 * (m10 * m21 - m11 * m20)
  if det == 0.0 || !det.is_finite() {
    return None
  }
  let inv : Float = 1.0 / det
  Some({
    x_axis: {
      x: (m11 * m22 - m12 * m21) * inv,
      y: (m12 * m20 - m10 * m22) * inv,
      z: (m10 * m21 - m11 * m20) * inv,
    },
    y_axis: {
      x: (m02 * m21 - m01 * m22) * inv,
      y: (m00 * m22 - m02 * m20) * inv,
      z: (m01 * m20 - m00 * m21) * inv,
    },
    z_axis: {
      x: (m01 * m12 - m02 * m11) * inv,
      y: (m02 * m10 - m00 * m12) * inv,
      z: (m00 * m11 - m01 * m10) * inv,
    },
  })
}

///|
/// `transpose(inverse(self))` — the matrix that correctly transforms normals
/// under non-uniform scale. `None` when singular.
pub fn Mat3::inverse_transpose(self : Mat3) -> Mat3? {
  match self.inverse() {
    Some(inv) => Some(inv.transpose())
    None => None
  }
}

///|
pub fn Mat3::to_cols_array(self : Mat3) -> FixedArray[Float] {
  let out : FixedArray[Float] = FixedArray::make(9, 0.0)
  out[0] = self.x_axis.x
  out[1] = self.x_axis.y
  out[2] = self.x_axis.z
  out[3] = self.y_axis.x
  out[4] = self.y_axis.y
  out[5] = self.y_axis.z
  out[6] = self.z_axis.x
  out[7] = self.z_axis.y
  out[8] = self.z_axis.z
  out
}

///|
pub fn Mat3::write_to(self : Mat3, dst : FixedArray[Float], offset : Int) -> Unit {
  dst[offset] = self.x_axis.x
  dst[offset + 1] = self.x_axis.y
  dst[offset + 2] = self.x_axis.z
  dst[offset + 3] = self.y_axis.x
  dst[offset + 4] = self.y_axis.y
  dst[offset + 5] = self.y_axis.z
  dst[offset + 6] = self.z_axis.x
  dst[offset + 7] = self.z_axis.y
  dst[offset + 8] = self.z_axis.z
}

///|
pub fn Mat3::to_mat4(self : Mat3) -> Mat4 {
  {
    x_axis: { x: self.x_axis.x, y: self.x_axis.y, z: self.x_axis.z, w: 0.0 },
    y_axis: { x: self.y_axis.x, y: self.y_axis.y, z: self.y_axis.z, w: 0.0 },
    z_axis: { x: self.z_axis.x, y: self.z_axis.y, z: self.z_axis.z, w: 0.0 },
    w_axis: { x: 0.0, y: 0.0, z: 0.0, w: 1.0 },
  }
}

///|
pub fn Mat3::to_quat(self : Mat3) -> Quat {
  Quat::from_mat3(self)
}

///|
pub fn Mat3::approx_eq(self : Mat3, other : Mat3, eps? : Float = EPSILON) -> Bool {
  self.x_axis.approx_eq(other.x_axis, eps~) &&
  self.y_axis.approx_eq(other.y_axis, eps~) &&
  self.z_axis.approx_eq(other.z_axis, eps~)
}
