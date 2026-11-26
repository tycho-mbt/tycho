// Double-precision column-major matrices and 3D affine transform.
//
// Same conventions as the `Float` types in the parent package: columns are
// stored as `DVec3` / `DVec4`, `M * v` applies the matrix to a column vector.

///|
#valtype
#derive(Eq, Debug)
pub(all) struct DMat3 {
  x_axis : DVec3
  y_axis : DVec3
  z_axis : DVec3
}

///|
pub impl Show for DMat3 with to_string(self) {
  let r0 = "[\{self.x_axis.x}, \{self.y_axis.x}, \{self.z_axis.x}]"
  let r1 = "[\{self.x_axis.y}, \{self.y_axis.y}, \{self.z_axis.y}]"
  let r2 = "[\{self.x_axis.z}, \{self.y_axis.z}, \{self.z_axis.z}]"
  "[\{r0}, \{r1}, \{r2}]"
}

///|
pub fn DMat3::identity() -> DMat3 {
  {
    x_axis: DVec3::new(1.0, 0.0, 0.0),
    y_axis: DVec3::new(0.0, 1.0, 0.0),
    z_axis: DVec3::new(0.0, 0.0, 1.0),
  }
}

///|
pub fn DMat3::from_cols(x_axis : DVec3, y_axis : DVec3, z_axis : DVec3) -> DMat3 {
  { x_axis, y_axis, z_axis }
}

///|
pub fn DMat3::from_diagonal(diag : DVec3) -> DMat3 {
  {
    x_axis: DVec3::new(diag.x, 0.0, 0.0),
    y_axis: DVec3::new(0.0, diag.y, 0.0),
    z_axis: DVec3::new(0.0, 0.0, diag.z),
  }
}

///|
pub fn DMat3::from_rotation_x(radians : Double) -> DMat3 {
  let (s, c) = (@math.sin(radians), @math.cos(radians))
  {
    x_axis: DVec3::new(1.0, 0.0, 0.0),
    y_axis: DVec3::new(0.0, c, s),
    z_axis: DVec3::new(0.0, -s, c),
  }
}

///|
pub fn DMat3::from_rotation_y(radians : Double) -> DMat3 {
  let (s, c) = (@math.sin(radians), @math.cos(radians))
  {
    x_axis: DVec3::new(c, 0.0, -s),
    y_axis: DVec3::new(0.0, 1.0, 0.0),
    z_axis: DVec3::new(s, 0.0, c),
  }
}

///|
pub fn DMat3::from_rotation_z(radians : Double) -> DMat3 {
  let (s, c) = (@math.sin(radians), @math.cos(radians))
  {
    x_axis: DVec3::new(c, s, 0.0),
    y_axis: DVec3::new(-s, c, 0.0),
    z_axis: DVec3::new(0.0, 0.0, 1.0),
  }
}

///|
pub fn DMat3::from_dquat(q : DQuat) -> DMat3 {
  q.to_dmat3()
}

///|
pub fn DMat3::row0(self : DMat3) -> DVec3 {
  DVec3::new(self.x_axis.x, self.y_axis.x, self.z_axis.x)
}

///|
pub fn DMat3::row1(self : DMat3) -> DVec3 {
  DVec3::new(self.x_axis.y, self.y_axis.y, self.z_axis.y)
}

///|
pub fn DMat3::row2(self : DMat3) -> DVec3 {
  DVec3::new(self.x_axis.z, self.y_axis.z, self.z_axis.z)
}

///|
pub impl Add for DMat3 with add(self, other) {
  {
    x_axis: self.x_axis + other.x_axis,
    y_axis: self.y_axis + other.y_axis,
    z_axis: self.z_axis + other.z_axis,
  }
}

///|
pub impl Sub for DMat3 with sub(self, other) {
  {
    x_axis: self.x_axis - other.x_axis,
    y_axis: self.y_axis - other.y_axis,
    z_axis: self.z_axis - other.z_axis,
  }
}

///|
pub impl Mul for DMat3 with mul(self, other) {
  {
    x_axis: self.mul_vec3(other.x_axis),
    y_axis: self.mul_vec3(other.y_axis),
    z_axis: self.mul_vec3(other.z_axis),
  }
}

///|
pub fn DMat3::mul_vec3(self : DMat3, v : DVec3) -> DVec3 {
  self.x_axis.scale(v.x) + self.y_axis.scale(v.y) + self.z_axis.scale(v.z)
}

///|
pub fn DMat3::transpose(self : DMat3) -> DMat3 {
  { x_axis: self.row0(), y_axis: self.row1(), z_axis: self.row2() }
}

///|
pub fn DMat3::determinant(self : DMat3) -> Double {
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
pub fn DMat3::inverse(self : DMat3) -> DMat3? {
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
  let inv = 1.0 / det
  Some({
    x_axis: DVec3::new(
      (m11 * m22 - m12 * m21) * inv,
      (m12 * m20 - m10 * m22) * inv,
      (m10 * m21 - m11 * m20) * inv,
    ),
    y_axis: DVec3::new(
      (m02 * m21 - m01 * m22) * inv,
      (m00 * m22 - m02 * m20) * inv,
      (m01 * m20 - m00 * m21) * inv,
    ),
    z_axis: DVec3::new(
      (m01 * m12 - m02 * m11) * inv,
      (m02 * m10 - m00 * m12) * inv,
      (m00 * m11 - m01 * m10) * inv,
    ),
  })
}

///|
pub fn DMat3::inverse_transpose(self : DMat3) -> DMat3? {
  match self.inverse() {
    Some(i) => Some(i.transpose())
    None => None
  }
}

///|
pub fn DMat3::to_dmat4(self : DMat3) -> DMat4 {
  {
    x_axis: self.x_axis.extend_w(0.0),
    y_axis: self.y_axis.extend_w(0.0),
    z_axis: self.z_axis.extend_w(0.0),
    w_axis: DVec4::unit_w(),
  }
}

///|
pub fn DMat3::to_mat3(self : DMat3) -> @tmath.Mat3 {
  {
    x_axis: self.x_axis.to_vec3(),
    y_axis: self.y_axis.to_vec3(),
    z_axis: self.z_axis.to_vec3(),
  }
}

///|
pub fn DMat3::approx_eq(self : DMat3, other : DMat3, eps? : Double = EPSILON) -> Bool {
  self.x_axis.approx_eq(other.x_axis, eps~) &&
  self.y_axis.approx_eq(other.y_axis, eps~) &&
  self.z_axis.approx_eq(other.z_axis, eps~)
}

///|
#valtype
#derive(Eq, Debug)
pub(all) struct DMat4 {
  x_axis : DVec4
  y_axis : DVec4
  z_axis : DVec4
  w_axis : DVec4
}

///|
pub impl Show for DMat4 with to_string(self) {
  let r0 = "[\{self.x_axis.x}, \{self.y_axis.x}, \{self.z_axis.x}, \{self.w_axis.x}]"
  let r1 = "[\{self.x_axis.y}, \{self.y_axis.y}, \{self.z_axis.y}, \{self.w_axis.y}]"
  let r2 = "[\{self.x_axis.z}, \{self.y_axis.z}, \{self.z_axis.z}, \{self.w_axis.z}]"
  let r3 = "[\{self.x_axis.w}, \{self.y_axis.w}, \{self.z_axis.w}, \{self.w_axis.w}]"
  "[\{r0}, \{r1}, \{r2}, \{r3}]"
}

///|
pub fn DMat4::identity() -> DMat4 {
  {
    x_axis: DVec4::new(1.0, 0.0, 0.0, 0.0),
    y_axis: DVec4::new(0.0, 1.0, 0.0, 0.0),
    z_axis: DVec4::new(0.0, 0.0, 1.0, 0.0),
    w_axis: DVec4::new(0.0, 0.0, 0.0, 1.0),
  }
}

///|
pub fn DMat4::from_cols(
  x_axis : DVec4,
  y_axis : DVec4,
  z_axis : DVec4,
  w_axis : DVec4,
) -> DMat4 {
  { x_axis, y_axis, z_axis, w_axis }
}

///|
pub fn DMat4::from_translation(t : DVec3) -> DMat4 {
  {
    ..DMat4::identity(),
    w_axis: DVec4::new(t.x, t.y, t.z, 1.0),
  }
}

///|
pub fn DMat4::from_scale(s : DVec3) -> DMat4 {
  {
    x_axis: DVec4::new(s.x, 0.0, 0.0, 0.0),
    y_axis: DVec4::new(0.0, s.y, 0.0, 0.0),
    z_axis: DVec4::new(0.0, 0.0, s.z, 0.0),
    w_axis: DVec4::new(0.0, 0.0, 0.0, 1.0),
  }
}

///|
pub fn DMat4::from_dmat3(m : DMat3) -> DMat4 {
  m.to_dmat4()
}

///|
pub fn DMat4::from_dquat(q : DQuat) -> DMat4 {
  m_from_dmat3(q.to_dmat3())
}

///|
fn m_from_dmat3(m : DMat3) -> DMat4 {
  {
    x_axis: m.x_axis.extend_w(0.0),
    y_axis: m.y_axis.extend_w(0.0),
    z_axis: m.z_axis.extend_w(0.0),
    w_axis: DVec4::new(0.0, 0.0, 0.0, 1.0),
  }
}

///|
pub fn DMat4::from_axis_angle(axis : DVec3, angle : Double) -> DMat4 {
  DMat4::from_dquat(DQuat::from_axis_angle(axis, angle))
}

///|
pub fn DMat4::from_scale_rotation_translation(
  scale : DVec3,
  rot : DQuat,
  trans : DVec3,
) -> DMat4 {
  let m = rot.to_dmat3()
  {
    x_axis: DVec4::new(
      m.x_axis.x * scale.x,
      m.x_axis.y * scale.x,
      m.x_axis.z * scale.x,
      0.0,
    ),
    y_axis: DVec4::new(
      m.y_axis.x * scale.y,
      m.y_axis.y * scale.y,
      m.y_axis.z * scale.y,
      0.0,
    ),
    z_axis: DVec4::new(
      m.z_axis.x * scale.z,
      m.z_axis.y * scale.z,
      m.z_axis.z * scale.z,
      0.0,
    ),
    w_axis: DVec4::new(trans.x, trans.y, trans.z, 1.0),
  }
}

///|
pub fn DMat4::row0(self : DMat4) -> DVec4 {
  DVec4::new(self.x_axis.x, self.y_axis.x, self.z_axis.x, self.w_axis.x)
}

///|
pub fn DMat4::row1(self : DMat4) -> DVec4 {
  DVec4::new(self.x_axis.y, self.y_axis.y, self.z_axis.y, self.w_axis.y)
}

///|
pub fn DMat4::row2(self : DMat4) -> DVec4 {
  DVec4::new(self.x_axis.z, self.y_axis.z, self.z_axis.z, self.w_axis.z)
}

///|
pub fn DMat4::row3(self : DMat4) -> DVec4 {
  DVec4::new(self.x_axis.w, self.y_axis.w, self.z_axis.w, self.w_axis.w)
}

///|
pub impl Mul for DMat4 with mul(self, other) {
  {
    x_axis: self.mul_vec4(other.x_axis),
    y_axis: self.mul_vec4(other.y_axis),
    z_axis: self.mul_vec4(other.z_axis),
    w_axis: self.mul_vec4(other.w_axis),
  }
}

///|
pub fn DMat4::mul_vec4(self : DMat4, v : DVec4) -> DVec4 {
  self.x_axis.scale(v.x) +
  self.y_axis.scale(v.y) +
  self.z_axis.scale(v.z) +
  self.w_axis.scale(v.w)
}

///|
pub fn DMat4::transform_point3(self : DMat4, p : DVec3) -> DVec3 {
  let v = self.mul_vec4(p.extend_w(1.0))
  DVec3::new(v.x, v.y, v.z)
}

///|
pub fn DMat4::transform_vector3(self : DMat4, v : DVec3) -> DVec3 {
  let r = self.mul_vec4(v.extend_w(0.0))
  DVec3::new(r.x, r.y, r.z)
}

///|
pub fn DMat4::project_point3(self : DMat4, p : DVec3) -> DVec3 {
  let v = self.mul_vec4(p.extend_w(1.0))
  if v.w.abs() > 1.0e-30 {
    DVec3::new(v.x / v.w, v.y / v.w, v.z / v.w)
  } else {
    DVec3::new(v.x, v.y, v.z)
  }
}

///|
pub fn DMat4::transpose(self : DMat4) -> DMat4 {
  { x_axis: self.row0(), y_axis: self.row1(), z_axis: self.row2(), w_axis: self.row3() }
}

///|
pub fn DMat4::determinant(self : DMat4) -> Double {
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
pub fn DMat4::inverse(self : DMat4) -> DMat4? {
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
  let inv = 1.0 / det
  Some({
    x_axis: DVec4::new(
      (a11 * c5 - a12 * c4 + a13 * c3) * inv,
      (-a10 * c5 + a12 * c2 - a13 * c1) * inv,
      (a10 * c4 - a11 * c2 + a13 * c0) * inv,
      (-a10 * c3 + a11 * c1 - a12 * c0) * inv,
    ),
    y_axis: DVec4::new(
      (-a01 * c5 + a02 * c4 - a03 * c3) * inv,
      (a00 * c5 - a02 * c2 + a03 * c1) * inv,
      (-a00 * c4 + a01 * c2 - a03 * c0) * inv,
      (a00 * c3 - a01 * c1 + a02 * c0) * inv,
    ),
    z_axis: DVec4::new(
      (a31 * s5 - a32 * s4 + a33 * s3) * inv,
      (-a30 * s5 + a32 * s2 - a33 * s1) * inv,
      (a30 * s4 - a31 * s2 + a33 * s0) * inv,
      (-a30 * s3 + a31 * s1 - a32 * s0) * inv,
    ),
    w_axis: DVec4::new(
      (-a21 * s5 + a22 * s4 - a23 * s3) * inv,
      (a20 * s5 - a22 * s2 + a23 * s1) * inv,
      (-a20 * s4 + a21 * s2 - a23 * s0) * inv,
      (a20 * s3 - a21 * s1 + a22 * s0) * inv,
    ),
  })
}

///|
pub fn DMat4::to_dmat3(self : DMat4) -> DMat3 {
  {
    x_axis: self.x_axis.truncate(),
    y_axis: self.y_axis.truncate(),
    z_axis: self.z_axis.truncate(),
  }
}

///|
pub fn DMat4::translation(self : DMat4) -> DVec3 {
  DVec3::new(self.w_axis.x, self.w_axis.y, self.w_axis.z)
}

///|
/// Down-cast to the single-precision matrix uploaded to the GPU.
pub fn DMat4::to_mat4(self : DMat4) -> @tmath.Mat4 {
  {
    x_axis: self.x_axis.to_vec4(),
    y_axis: self.y_axis.to_vec4(),
    z_axis: self.z_axis.to_vec4(),
    w_axis: self.w_axis.to_vec4(),
  }
}

///|
pub fn DMat4::approx_eq(self : DMat4, other : DMat4, eps? : Double = EPSILON) -> Bool {
  self.x_axis.approx_eq(other.x_axis, eps~) &&
  self.y_axis.approx_eq(other.y_axis, eps~) &&
  self.z_axis.approx_eq(other.z_axis, eps~) &&
  self.w_axis.approx_eq(other.w_axis, eps~)
}

///|
#valtype
#derive(Eq, Debug)
pub(all) struct DAffine3 {
  matrix3 : DMat3
  translation : DVec3
}

///|
pub impl Show for DAffine3 with to_string(self) {
  let r0 = "[\{self.matrix3.x_axis.x}, \{self.matrix3.y_axis.x}, \{self.matrix3.z_axis.x}, \{self.translation.x}]"
  let r1 = "[\{self.matrix3.x_axis.y}, \{self.matrix3.y_axis.y}, \{self.matrix3.z_axis.y}, \{self.translation.y}]"
  let r2 = "[\{self.matrix3.x_axis.z}, \{self.matrix3.y_axis.z}, \{self.matrix3.z_axis.z}, \{self.translation.z}]"
  "[\{r0}, \{r1}, \{r2}]"
}

///|
pub fn DAffine3::identity() -> DAffine3 {
  { matrix3: DMat3::identity(), translation: DVec3::zero() }
}

///|
pub fn DAffine3::from_cols(matrix3 : DMat3, translation : DVec3) -> DAffine3 {
  { matrix3, translation }
}

///|
pub fn DAffine3::from_translation(t : DVec3) -> DAffine3 {
  { matrix3: DMat3::identity(), translation: t }
}

///|
pub fn DAffine3::from_dmat4(m : DMat4) -> DAffine3 {
  { matrix3: m.to_dmat3(), translation: m.translation() }
}

///|
pub impl Mul for DAffine3 with mul(self, other) {
  {
    matrix3: self.matrix3 * other.matrix3,
    translation: self.transform_point3(other.translation),
  }
}

///|
pub fn DAffine3::transform_point3(self : DAffine3, p : DVec3) -> DVec3 {
  self.matrix3.mul_vec3(p) + self.translation
}

///|
pub fn DAffine3::transform_vector3(self : DAffine3, v : DVec3) -> DVec3 {
  self.matrix3.mul_vec3(v)
}

///|
pub fn DAffine3::determinant(self : DAffine3) -> Double {
  self.matrix3.determinant()
}

///|
pub fn DAffine3::inverse(self : DAffine3) -> DAffine3? {
  match self.matrix3.inverse() {
    Some(i) => Some({ matrix3: i, translation: -i.mul_vec3(self.translation) })
    None => None
  }
}

///|
pub fn DAffine3::to_dmat4(self : DAffine3) -> DMat4 {
  {
    x_axis: self.matrix3.x_axis.extend_w(0.0),
    y_axis: self.matrix3.y_axis.extend_w(0.0),
    z_axis: self.matrix3.z_axis.extend_w(0.0),
    w_axis: self.translation.extend_w(1.0),
  }
}

///|
/// Down-cast to the single-precision affine transform.
pub fn DAffine3::to_affine3(self : DAffine3) -> @tmath.Affine3 {
  { matrix3: self.matrix3.to_mat3(), translation: self.translation.to_vec3() }
}

///|
/// Down-cast directly to the GPU-facing 4x4 matrix.
pub fn DAffine3::to_mat4(self : DAffine3) -> @tmath.Mat4 {
  self.to_dmat4().to_mat4()
}

///|
pub fn DAffine3::approx_eq(self : DAffine3, other : DAffine3, eps? : Double = EPSILON) -> Bool {
  self.matrix3.approx_eq(other.matrix3, eps~) &&
  self.translation.approx_eq(other.translation, eps~)
}
