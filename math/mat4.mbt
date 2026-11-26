// 4x4 single-precision matrix, stored as four column vectors
// (`x_axis`, `y_axis`, `z_axis`, `w_axis`).
//
// The in-memory layout is 16 contiguous `Float`s in column-major order
// (`[c0r0, c0r1, c0r2, c0r3, c1r0, ...]`), byte-identical to GLSL / Slang /
// WGSL / SPIR-V / Metal `mat4`, so uploading to a UBO/SSBO needs no transpose.
//
// Column-vector convention: `v' = M * v`, and composite transforms read
// right-to-left (`M_mvp = P * V * M`).

///|
#valtype
#derive(Eq, Debug)
pub(all) struct Mat4 {
  x_axis : Vec4
  y_axis : Vec4
  z_axis : Vec4
  w_axis : Vec4
}

///|
pub impl Show for Mat4 with to_string(self) {
  let r0 = "[\{self.x_axis.x}, \{self.y_axis.x}, \{self.z_axis.x}, \{self.w_axis.x}]"
  let r1 = "[\{self.x_axis.y}, \{self.y_axis.y}, \{self.z_axis.y}, \{self.w_axis.y}]"
  let r2 = "[\{self.x_axis.z}, \{self.y_axis.z}, \{self.z_axis.z}, \{self.w_axis.z}]"
  let r3 = "[\{self.x_axis.w}, \{self.y_axis.w}, \{self.z_axis.w}, \{self.w_axis.w}]"
  "[\{r0}, \{r1}, \{r2}, \{r3}]"
}

///|
pub fn Mat4::identity() -> Mat4 {
  {
    x_axis: { x: 1.0, y: 0.0, z: 0.0, w: 0.0 },
    y_axis: { x: 0.0, y: 1.0, z: 0.0, w: 0.0 },
    z_axis: { x: 0.0, y: 0.0, z: 1.0, w: 0.0 },
    w_axis: { x: 0.0, y: 0.0, z: 0.0, w: 1.0 },
  }
}

///|
pub fn Mat4::from_cols(x_axis : Vec4, y_axis : Vec4, z_axis : Vec4, w_axis : Vec4) -> Mat4 {
  { x_axis, y_axis, z_axis, w_axis }
}

///|
pub fn Mat4::from_cols_array(arr : FixedArray[Float]) -> Mat4 {
  {
    x_axis: { x: arr[0], y: arr[1], z: arr[2], w: arr[3] },
    y_axis: { x: arr[4], y: arr[5], z: arr[6], w: arr[7] },
    z_axis: { x: arr[8], y: arr[9], z: arr[10], w: arr[11] },
    w_axis: { x: arr[12], y: arr[13], z: arr[14], w: arr[15] },
  }
}

///|
pub fn Mat4::from_diagonal(diag : Vec4) -> Mat4 {
  {
    x_axis: { x: diag.x, y: 0.0, z: 0.0, w: 0.0 },
    y_axis: { x: 0.0, y: diag.y, z: 0.0, w: 0.0 },
    z_axis: { x: 0.0, y: 0.0, z: diag.z, w: 0.0 },
    w_axis: { x: 0.0, y: 0.0, z: 0.0, w: diag.w },
  }
}

///|
pub fn Mat4::from_translation(t : Vec3) -> Mat4 {
  { ..Mat4::identity(), w_axis: { x: t.x, y: t.y, z: t.z, w: 1.0 } }
}

///|
pub fn Mat4::from_scale(s : Vec3) -> Mat4 {
  {
    x_axis: { x: s.x, y: 0.0, z: 0.0, w: 0.0 },
    y_axis: { x: 0.0, y: s.y, z: 0.0, w: 0.0 },
    z_axis: { x: 0.0, y: 0.0, z: s.z, w: 0.0 },
    w_axis: { x: 0.0, y: 0.0, z: 0.0, w: 1.0 },
  }
}

///|
pub fn Mat4::from_scale_uniform(s : Float) -> Mat4 {
  Mat4::from_scale({ x: s, y: s, z: s })
}

///|
pub fn Mat4::from_rotation_x(radians : Float) -> Mat4 {
  Mat4::from_mat3(Mat3::from_rotation_x(radians))
}

///|
pub fn Mat4::from_rotation_y(radians : Float) -> Mat4 {
  Mat4::from_mat3(Mat3::from_rotation_y(radians))
}

///|
pub fn Mat4::from_rotation_z(radians : Float) -> Mat4 {
  Mat4::from_mat3(Mat3::from_rotation_z(radians))
}

///|
pub fn Mat4::from_quat(q : Quat) -> Mat4 {
  Mat4::from_mat3(q.to_mat3())
}

///|
pub fn Mat4::from_axis_angle(axis : Vec3, angle : Float) -> Mat4 {
  Mat4::from_quat(Quat::from_axis_angle(axis, angle))
}

///|
pub fn Mat4::from_mat3(m : Mat3) -> Mat4 {
  {
    x_axis: { x: m.x_axis.x, y: m.x_axis.y, z: m.x_axis.z, w: 0.0 },
    y_axis: { x: m.y_axis.x, y: m.y_axis.y, z: m.y_axis.z, w: 0.0 },
    z_axis: { x: m.z_axis.x, y: m.z_axis.y, z: m.z_axis.z, w: 0.0 },
    w_axis: { x: 0.0, y: 0.0, z: 0.0, w: 1.0 },
  }
}

///|
/// `T * R * S` in that multiplication order (scale applied first).
pub fn Mat4::from_scale_rotation_translation(
  scale : Vec3,
  rot : Quat,
  trans : Vec3,
) -> Mat4 {
  let m = rot.to_mat3()
  {
    x_axis: { x: m.x_axis.x * scale.x, y: m.x_axis.y * scale.x, z: m.x_axis.z * scale.x, w: 0.0 },
    y_axis: { x: m.y_axis.x * scale.y, y: m.y_axis.y * scale.y, z: m.y_axis.z * scale.y, w: 0.0 },
    z_axis: { x: m.z_axis.x * scale.z, y: m.z_axis.y * scale.z, z: m.z_axis.z * scale.z, w: 0.0 },
    w_axis: { x: trans.x, y: trans.y, z: trans.z, w: 1.0 },
  }
}

///|
pub fn Mat4::row0(self : Mat4) -> Vec4 {
  {
    x: self.x_axis.x,
    y: self.y_axis.x,
    z: self.z_axis.x,
    w: self.w_axis.x,
  }
}

///|
pub fn Mat4::row1(self : Mat4) -> Vec4 {
  {
    x: self.x_axis.y,
    y: self.y_axis.y,
    z: self.z_axis.y,
    w: self.w_axis.y,
  }
}

///|
pub fn Mat4::row2(self : Mat4) -> Vec4 {
  {
    x: self.x_axis.z,
    y: self.y_axis.z,
    z: self.z_axis.z,
    w: self.w_axis.z,
  }
}

///|
pub fn Mat4::row3(self : Mat4) -> Vec4 {
  {
    x: self.x_axis.w,
    y: self.y_axis.w,
    z: self.z_axis.w,
    w: self.w_axis.w,
  }
}

///|
pub fn Mat4::column(self : Mat4, i : Int) -> Vec4 {
  if i == 0 {
    self.x_axis
  } else if i == 1 {
    self.y_axis
  } else if i == 2 {
    self.z_axis
  } else {
    self.w_axis
  }
}

///|
/// Element at `(row, col)`; out-of-range indices yield `0`.
pub fn Mat4::at(self : Mat4, row : Int, col : Int) -> Float {
  self.column(col).component(row)
}

///|
pub impl Add for Mat4 with add(self, other) {
  {
    x_axis: self.x_axis + other.x_axis,
    y_axis: self.y_axis + other.y_axis,
    z_axis: self.z_axis + other.z_axis,
    w_axis: self.w_axis + other.w_axis,
  }
}

///|
pub impl Sub for Mat4 with sub(self, other) {
  {
    x_axis: self.x_axis - other.x_axis,
    y_axis: self.y_axis - other.y_axis,
    z_axis: self.z_axis - other.z_axis,
    w_axis: self.w_axis - other.w_axis,
  }
}

///|
/// Matrix product `self * other`.
pub impl Mul for Mat4 with mul(self, other) {
  {
    x_axis: self.mul_vec4(other.x_axis),
    y_axis: self.mul_vec4(other.y_axis),
    z_axis: self.mul_vec4(other.z_axis),
    w_axis: self.mul_vec4(other.w_axis),
  }
}

///|
/// Multiply a matrix by a scalar.
pub fn Mat4::scale(self : Mat4, s : Float) -> Mat4 {
  {
    x_axis: self.x_axis.scale(s),
    y_axis: self.y_axis.scale(s),
    z_axis: self.z_axis.scale(s),
    w_axis: self.w_axis.scale(s),
  }
}

///|
pub fn Mat4::mul_vec4(self : Mat4, v : Vec4) -> Vec4 {
  self.x_axis.scale(v.x) +
  self.y_axis.scale(v.y) +
  self.z_axis.scale(v.z) +
  self.w_axis.scale(v.w)
}

///|
/// Transform a point, assuming an affine matrix (`w = 1`, no perspective
/// divide). For projective matrices use `project_point3`.
pub fn Mat4::transform_point3(self : Mat4, p : Vec3) -> Vec3 {
  let v = self.mul_vec4(p.extend_w(1.0))
  { x: v.x, y: v.y, z: v.z }
}

///|
/// Transform a direction/vector (`w = 0`, ignores translation).
pub fn Mat4::transform_vector3(self : Mat4, v : Vec3) -> Vec3 {
  let r = self.mul_vec4(v.extend_w(0.0))
  { x: r.x, y: r.y, z: r.z }
}

///|
/// Full projective transform including the perspective divide.
pub fn Mat4::project_point3(self : Mat4, p : Vec3) -> Vec3 {
  let v = self.mul_vec4(p.extend_w(1.0))
  if v.w.abs() > 1.0e-20 {
    { x: v.x / v.w, y: v.y / v.w, z: v.z / v.w }
  } else {
    { x: v.x, y: v.y, z: v.z }
  }
}

///|
pub fn Mat4::transpose(self : Mat4) -> Mat4 {
  {
    x_axis: self.row0(),
    y_axis: self.row1(),
    z_axis: self.row2(),
    w_axis: self.row3(),
  }
}

///|
pub fn Mat4::determinant(self : Mat4) -> Float {
  let a00 = self.x_axis.x
  let a01 = self.y_axis.x
  let a02 = self.z_axis.x
  let a03 = self.w_axis.x
  let a10 = self.x_axis.y
  let a11 = self.y_axis.y
  let a12 = self.z_axis.y
  let a13 = self.w_axis.y
  let a20 = self.x_axis.z
  let a21 = self.y_axis.z
  let a22 = self.z_axis.z
  let a23 = self.w_axis.z
  let a30 = self.x_axis.w
  let a31 = self.y_axis.w
  let a32 = self.z_axis.w
  let a33 = self.w_axis.w
  let s0 = a00 * a11 - a10 * a01
  let s1 = a00 * a12 - a10 * a02
  let s2 = a00 * a13 - a10 * a03
  let s3 = a01 * a12 - a11 * a02
  let s4 = a01 * a13 - a11 * a03
  let s5 = a02 * a13 - a12 * a03
  let c5 = a22 * a33 - a32 * a23
  let c4 = a21 * a33 - a31 * a23
  let c3 = a21 * a32 - a31 * a22
  let c2 = a20 * a33 - a30 * a23
  let c1 = a20 * a32 - a30 * a22
  let c0 = a20 * a31 - a30 * a21
  s0 * c5 - s1 * c4 + s2 * c3 + s3 * c2 - s4 * c1 + s5 * c0
}

///|
/// Full 4x4 inverse, or `None` for singular / non-finite matrices.
pub fn Mat4::inverse(self : Mat4) -> Mat4? {
  let a00 = self.x_axis.x
  let a01 = self.y_axis.x
  let a02 = self.z_axis.x
  let a03 = self.w_axis.x
  let a10 = self.x_axis.y
  let a11 = self.y_axis.y
  let a12 = self.z_axis.y
  let a13 = self.w_axis.y
  let a20 = self.x_axis.z
  let a21 = self.y_axis.z
  let a22 = self.z_axis.z
  let a23 = self.w_axis.z
  let a30 = self.x_axis.w
  let a31 = self.y_axis.w
  let a32 = self.z_axis.w
  let a33 = self.w_axis.w
  let s0 = a00 * a11 - a10 * a01
  let s1 = a00 * a12 - a10 * a02
  let s2 = a00 * a13 - a10 * a03
  let s3 = a01 * a12 - a11 * a02
  let s4 = a01 * a13 - a11 * a03
  let s5 = a02 * a13 - a12 * a03
  let c5 = a22 * a33 - a32 * a23
  let c4 = a21 * a33 - a31 * a23
  let c3 = a21 * a32 - a31 * a22
  let c2 = a20 * a33 - a30 * a23
  let c1 = a20 * a32 - a30 * a22
  let c0 = a20 * a31 - a30 * a21
  let det = s0 * c5 - s1 * c4 + s2 * c3 + s3 * c2 - s4 * c1 + s5 * c0
  if det == 0.0 || !det.is_finite() {
    return None
  }
  let inv : Float = 1.0 / det
  // The cofactors below are laid out row-major; each column of the result
  // takes one entry from every row (column-major storage).
  Some({
    x_axis: {
      x: (a11 * c5 - a12 * c4 + a13 * c3) * inv,
      y: (-a10 * c5 + a12 * c2 - a13 * c1) * inv,
      z: (a10 * c4 - a11 * c2 + a13 * c0) * inv,
      w: (-a10 * c3 + a11 * c1 - a12 * c0) * inv,
    },
    y_axis: {
      x: (-a01 * c5 + a02 * c4 - a03 * c3) * inv,
      y: (a00 * c5 - a02 * c2 + a03 * c1) * inv,
      z: (-a00 * c4 + a01 * c2 - a03 * c0) * inv,
      w: (a00 * c3 - a01 * c1 + a02 * c0) * inv,
    },
    z_axis: {
      x: (a31 * s5 - a32 * s4 + a33 * s3) * inv,
      y: (-a30 * s5 + a32 * s2 - a33 * s1) * inv,
      z: (a30 * s4 - a31 * s2 + a33 * s0) * inv,
      w: (-a30 * s3 + a31 * s1 - a32 * s0) * inv,
    },
    w_axis: {
      x: (-a21 * s5 + a22 * s4 - a23 * s3) * inv,
      y: (a20 * s5 - a22 * s2 + a23 * s1) * inv,
      z: (-a20 * s4 + a21 * s2 - a23 * s0) * inv,
      w: (a20 * s3 - a21 * s1 + a22 * s0) * inv,
    },
  })
}

///|
/// `transpose(inverse(upper_left_3x3))`, the correct normal transform under
/// non-uniform scale. `None` when the linear part is singular.
pub fn Mat4::normal_matrix(self : Mat4) -> Mat3? {
  self.to_mat3().inverse_transpose()
}

///|
/// Upper-left 3x3 block (rotation / scale).
pub fn Mat4::to_mat3(self : Mat4) -> Mat3 {
  {
    x_axis: self.x_axis.xyz(),
    y_axis: self.y_axis.xyz(),
    z_axis: self.z_axis.xyz(),
  }
}

///|
pub fn Mat4::to_cols_array(self : Mat4) -> FixedArray[Float] {
  let out : FixedArray[Float] = FixedArray::make(16, 0.0)
  self.write_to(out, 0)
  out
}

///|
/// Write the 16 column-major floats into `dst` starting at `offset`.
pub fn Mat4::write_to(self : Mat4, dst : FixedArray[Float], offset : Int) -> Unit {
  dst[offset] = self.x_axis.x
  dst[offset + 1] = self.x_axis.y
  dst[offset + 2] = self.x_axis.z
  dst[offset + 3] = self.x_axis.w
  dst[offset + 4] = self.y_axis.x
  dst[offset + 5] = self.y_axis.y
  dst[offset + 6] = self.y_axis.z
  dst[offset + 7] = self.y_axis.w
  dst[offset + 8] = self.z_axis.x
  dst[offset + 9] = self.z_axis.y
  dst[offset + 10] = self.z_axis.z
  dst[offset + 11] = self.z_axis.w
  dst[offset + 12] = self.w_axis.x
  dst[offset + 13] = self.w_axis.y
  dst[offset + 14] = self.w_axis.z
  dst[offset + 15] = self.w_axis.w
}

///|
pub fn Mat4::translation(self : Mat4) -> Vec3 {
  { x: self.w_axis.x, y: self.w_axis.y, z: self.w_axis.z }
}

///|
pub fn Mat4::is_finite(self : Mat4) -> Bool {
  self.x_axis.is_finite() &&
  self.y_axis.is_finite() &&
  self.z_axis.is_finite() &&
  self.w_axis.is_finite()
}

///|
pub fn Mat4::approx_eq(self : Mat4, other : Mat4, eps? : Float = EPSILON) -> Bool {
  self.x_axis.approx_eq(other.x_axis, eps~) &&
  self.y_axis.approx_eq(other.y_axis, eps~) &&
  self.z_axis.approx_eq(other.z_axis, eps~) &&
  self.w_axis.approx_eq(other.w_axis, eps~)
}
