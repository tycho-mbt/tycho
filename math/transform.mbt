// Translation / rotation / scale (TRS) transform. This is the friendly,
// authoring-facing form; convert to `Affine3` or `Mat4` for the hot path.

///|
#valtype
#derive(Eq, Debug)
pub(all) struct Transform {
  translation : Vec3
  rotation : Quat
  scale : Vec3
}

///|
pub impl Show for Transform with to_string(self) {
  "Transform(t=\{self.translation}, r=\{self.rotation}, s=\{self.scale})"
}

///|
pub fn Transform::identity() -> Transform {
  {
    translation: Vec3::zero(),
    rotation: Quat::identity(),
    scale: Vec3::one(),
  }
}

///|
pub fn Transform::new(translation : Vec3, rotation : Quat, scale : Vec3) -> Transform {
  { translation, rotation, scale }
}

///|
pub fn Transform::from_translation(t : Vec3) -> Transform {
  { ..Transform::identity(), translation: t }
}

///|
pub fn Transform::from_rotation(q : Quat) -> Transform {
  { ..Transform::identity(), rotation: q }
}

///|
pub fn Transform::from_scale(s : Vec3) -> Transform {
  { ..Transform::identity(), scale: s }
}

///|
/// Decompose an affine matrix into TRS. Returns `None` when a scale axis is
/// degenerate. A negative determinant is represented as a negative `z` scale.
pub fn Transform::from_affine3(a : Affine3) -> Transform? {
  let m = a.matrix3
  let sx = m.x_axis.length()
  let sy = m.y_axis.length()
  let sz = m.z_axis.length()
  if sx <= EPSILON || sy <= EPSILON || sz <= EPSILON {
    return None
  }
  let x_axis = m.x_axis.scale((1.0 : Float) / sx)
  let y_axis = m.y_axis.scale((1.0 : Float) / sy)
  let mut z_axis = m.z_axis.scale((1.0 : Float) / sz)
  let mut scale : Vec3 = { x: sx, y: sy, z: sz }
  if x_axis.cross(y_axis).dot(z_axis) < 0.0 {
    // Mirror along z so the rotation part is a proper rotation.
    scale = { ..scale, z: -sz }
    z_axis = -z_axis
  }
  let rot = Quat::from_mat3({ x_axis, y_axis, z_axis })
  Some({ translation: a.translation, rotation: rot, scale })
}

///|
pub fn Transform::from_mat4(m : Mat4) -> Transform? {
  Transform::from_affine3(Affine3::from_mat4(m))
}

///|
pub fn Transform::to_affine3(self : Transform) -> Affine3 {
  Affine3::from_scale_rotation_translation(self.scale, self.rotation, self.translation)
}

///|
pub fn Transform::to_mat4(self : Transform) -> Mat4 {
  Mat4::from_scale_rotation_translation(self.scale, self.rotation, self.translation)
}

///|
/// `T * R * S` applied to a point: scale, then rotate, then translate.
pub fn Transform::transform_point3(self : Transform, p : Vec3) -> Vec3 {
  self.rotation.mul_vec3(p * self.scale) + self.translation
}

///|
pub fn Transform::transform_vector3(self : Transform, v : Vec3) -> Vec3 {
  self.rotation.mul_vec3(v * self.scale)
}

///|
/// Compose two TRS transforms into a general affine (`self` applied after
/// `other`). The result may contain shear, hence `Affine3`.
pub fn Transform::compose(self : Transform, other : Transform) -> Affine3 {
  self.to_affine3() * other.to_affine3()
}

///|
/// Inverse as an affine transform (general, may contain shear).
pub fn Transform::inverse(self : Transform) -> Affine3? {
  self.to_affine3().inverse()
}

///|
/// Interpolate translation and scale linearly, rotation via `slerp`.
pub fn Transform::lerp(self : Transform, other : Transform, t : Float) -> Transform {
  {
    translation: self.translation.lerp(other.translation, t),
    rotation: self.rotation.slerp(other.rotation, t),
    scale: self.scale.lerp(other.scale, t),
  }
}

///|
pub fn Transform::approx_eq(self : Transform, other : Transform, eps? : Float = EPSILON) -> Bool {
  self.translation.approx_eq(other.translation, eps~) &&
  self.rotation.approx_eq(other.rotation, eps~) &&
  self.scale.approx_eq(other.scale, eps~)
}
