// 3D affine transform: a 3x3 linear part plus a translation. Compared to
// `Mat4` this saves 25% of the storage and arithmetic, and it maps 1:1 onto
// `VkTransformMatrixKHR` (the 3x4 row-major matrix used by ray-tracing TLAS
// instance descriptors).

///|
#valtype
#derive(Eq, Debug)
pub(all) struct Affine3 {
  matrix3 : Mat3
  translation : Vec3
}

///|
pub impl Show for Affine3 with to_string(self) {
  let r0 = "[\{self.matrix3.x_axis.x}, \{self.matrix3.y_axis.x}, \{self.matrix3.z_axis.x}, \{self.translation.x}]"
  let r1 = "[\{self.matrix3.x_axis.y}, \{self.matrix3.y_axis.y}, \{self.matrix3.z_axis.y}, \{self.translation.y}]"
  let r2 = "[\{self.matrix3.x_axis.z}, \{self.matrix3.y_axis.z}, \{self.matrix3.z_axis.z}, \{self.translation.z}]"
  "[\{r0}, \{r1}, \{r2}]"
}

///|
pub fn Affine3::identity() -> Affine3 {
  { matrix3: Mat3::identity(), translation: Vec3::zero() }
}

///|
pub fn Affine3::from_cols(matrix3 : Mat3, translation : Vec3) -> Affine3 {
  { matrix3, translation }
}

///|
pub fn Affine3::from_translation(t : Vec3) -> Affine3 {
  { matrix3: Mat3::identity(), translation: t }
}

///|
pub fn Affine3::from_scale(s : Vec3) -> Affine3 {
  { matrix3: Mat3::from_diagonal(s), translation: Vec3::zero() }
}

///|
pub fn Affine3::from_quat(q : Quat) -> Affine3 {
  { matrix3: q.to_mat3(), translation: Vec3::zero() }
}

///|
pub fn Affine3::from_scale_rotation_translation(
  scale : Vec3,
  rot : Quat,
  trans : Vec3,
) -> Affine3 {
  let m = rot.to_mat3()
  {
    matrix3: {
      x_axis: m.x_axis.scale(scale.x),
      y_axis: m.y_axis.scale(scale.y),
      z_axis: m.z_axis.scale(scale.z),
    },
    translation: trans,
  }
}

///|
/// Extract an affine transform from a `Mat4`. The bottom row is assumed to be
/// `(0, 0, 0, 1)`; use `Mat4::project_point3` for true projective matrices.
pub fn Affine3::from_mat4(m : Mat4) -> Affine3 {
  { matrix3: m.to_mat3(), translation: m.translation() }
}

///|
pub impl Mul for Affine3 with mul(self, other) {
  {
    matrix3: self.matrix3 * other.matrix3,
    translation: self.transform_point3(other.translation),
  }
}

///|
pub fn Affine3::transform_point3(self : Affine3, p : Vec3) -> Vec3 {
  self.matrix3.mul_vec3(p) + self.translation
}

///|
pub fn Affine3::transform_vector3(self : Affine3, v : Vec3) -> Vec3 {
  self.matrix3.mul_vec3(v)
}

///|
/// Transform a normal with the inverse-transpose of the linear part, so that
/// non-uniform scale is handled correctly. `None` when singular.
pub fn Affine3::normal_matrix(self : Affine3) -> Mat3? {
  self.matrix3.inverse_transpose()
}

///|
pub fn Affine3::determinant(self : Affine3) -> Float {
  self.matrix3.determinant()
}

///|
/// Inverse, or `None` when the linear part is singular.
pub fn Affine3::inverse(self : Affine3) -> Affine3? {
  match self.matrix3.inverse() {
    Some(inv) => Some({
      matrix3: inv,
      translation: -inv.mul_vec3(self.translation),
    })
    None => None
  }
}

///|
pub fn Affine3::to_mat4(self : Affine3) -> Mat4 {
  {
    x_axis: { x: self.matrix3.x_axis.x, y: self.matrix3.x_axis.y, z: self.matrix3.x_axis.z, w: 0.0 },
    y_axis: { x: self.matrix3.y_axis.x, y: self.matrix3.y_axis.y, z: self.matrix3.y_axis.z, w: 0.0 },
    z_axis: { x: self.matrix3.z_axis.x, y: self.matrix3.z_axis.y, z: self.matrix3.z_axis.z, w: 0.0 },
    w_axis: {
      x: self.translation.x,
      y: self.translation.y,
      z: self.translation.z,
      w: 1.0,
    },
  }
}

///|
/// 12 floats in **row-major** 3x4 order, ready for `VkTransformMatrixKHR`
/// (TLAS instance transform) and for GLTF/assimp-style APIs.
pub fn Affine3::to_vk_transform_3x4(self : Affine3) -> FixedArray[Float] {
  let out : FixedArray[Float] = FixedArray::make(12, 0.0)
  let m = self.matrix3
  let t = self.translation
  out[0] = m.x_axis.x
  out[1] = m.y_axis.x
  out[2] = m.z_axis.x
  out[3] = t.x
  out[4] = m.x_axis.y
  out[5] = m.y_axis.y
  out[6] = m.z_axis.y
  out[7] = t.y
  out[8] = m.x_axis.z
  out[9] = m.y_axis.z
  out[10] = m.z_axis.z
  out[11] = t.z
  out
}

///|
pub fn Affine3::to_mat4_array(self : Affine3) -> FixedArray[Float] {
  self.to_mat4().to_cols_array()
}

///|
pub fn Affine3::approx_eq(self : Affine3, other : Affine3, eps? : Float = EPSILON) -> Bool {
  self.matrix3.approx_eq(other.matrix3, eps~) &&
  self.translation.approx_eq(other.translation, eps~)
}
