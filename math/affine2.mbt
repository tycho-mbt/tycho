// 2D affine transform: a 2x2 linear part plus a translation.
//
// Layout `[x_axis | y_axis | translation]` is the same 3x2 affine form used by
// `tycho_2d`'s `Matrix3`, so the two can be converted without cost, and
// `to_mat4` upgrades a 2D UI transform into the 3D pipeline.

///|
#valtype
#derive(Eq, Debug)
pub(all) struct Affine2 {
  x_axis : Vec2
  y_axis : Vec2
  translation : Vec2
}

///|
pub impl Show for Affine2 with to_string(self) {
  let r0 = "[\{self.x_axis.x}, \{self.y_axis.x}, \{self.translation.x}]"
  let r1 = "[\{self.x_axis.y}, \{self.y_axis.y}, \{self.translation.y}]"
  "[\{r0}, \{r1}]"
}

///|
pub fn Affine2::identity() -> Affine2 {
  {
    x_axis: { x: 1.0, y: 0.0 },
    y_axis: { x: 0.0, y: 1.0 },
    translation: { x: 0.0, y: 0.0 },
  }
}

///|
pub fn Affine2::from_cols(x_axis : Vec2, y_axis : Vec2, translation : Vec2) -> Affine2 {
  { x_axis, y_axis, translation }
}

///|
pub fn Affine2::from_translation(t : Vec2) -> Affine2 {
  { ..Affine2::identity(), translation: t }
}

///|
pub fn Affine2::from_scale(s : Vec2) -> Affine2 {
  {
    x_axis: { x: s.x, y: 0.0 },
    y_axis: { x: 0.0, y: s.y },
    translation: { x: 0.0, y: 0.0 },
  }
}

///|
pub fn Affine2::from_scale_uniform(s : Float) -> Affine2 {
  Affine2::from_scale({ x: s, y: s })
}

///|
/// Rotation by `radians` (counter-clockwise).
pub fn Affine2::from_angle(radians : Float) -> Affine2 {
  let (s, c) = sin_cos(radians)
  {
    x_axis: { x: c, y: s },
    y_axis: { x: -s, y: c },
    translation: { x: 0.0, y: 0.0 },
  }
}

///|
/// Compose as `T * R * S` (scale applied first, then rotation, then
/// translation).
pub fn Affine2::from_scale_angle_translation(
  s : Vec2,
  radians : Float,
  t : Vec2,
) -> Affine2 {
  let (sn, cs) = sin_cos(radians)
  {
    x_axis: { x: cs * s.x, y: sn * s.x },
    y_axis: { x: -sn * s.y, y: cs * s.y },
    translation: t,
  }
}

///|
pub fn Affine2::determinant(self : Affine2) -> Float {
  self.x_axis.x * self.y_axis.y - self.y_axis.x * self.x_axis.y
}

///|
pub impl Mul for Affine2 with mul(self, other) {
  {
    x_axis: self.transform_vector2(other.x_axis),
    y_axis: self.transform_vector2(other.y_axis),
    translation: self.transform_point2(other.translation),
  }
}

///|
pub fn Affine2::transform_point2(self : Affine2, p : Vec2) -> Vec2 {
  self.x_axis.scale(p.x) + self.y_axis.scale(p.y) + self.translation
}

///|
pub fn Affine2::transform_vector2(self : Affine2, v : Vec2) -> Vec2 {
  self.x_axis.scale(v.x) + self.y_axis.scale(v.y)
}

///|
/// Inverse, or `None` when the linear part is singular.
pub fn Affine2::inverse(self : Affine2) -> Affine2? {
  let a = self.x_axis.x
  let b = self.x_axis.y
  let c = self.y_axis.x
  let d = self.y_axis.y
  let det = a * d - c * b
  if det == 0.0 || !det.is_finite() {
    return None
  }
  let inv : Float = 1.0 / det
  Some({
    x_axis: { x: d * inv, y: -b * inv },
    y_axis: { x: -c * inv, y: a * inv },
    translation: {
      x: (c * self.translation.y - d * self.translation.x) * inv,
      y: (b * self.translation.x - a * self.translation.y) * inv,
    },
  })
}

///|
/// `true` when the transform is a pure axis-aligned scale + translation
/// (no rotation or shear), which lets 2D rasterizers take a fast path.
pub fn Affine2::is_axis_aligned(self : Affine2, eps? : Float = 1.0e-5) -> Bool {
  self.x_axis.y.abs() <= eps &&
  self.y_axis.x.abs() <= eps &&
  self.x_axis.x >= 0.0 &&
  self.y_axis.y >= 0.0
}

///|
pub fn Affine2::is_pure_translation(self : Affine2, eps? : Float = 1.0e-5) -> Bool {
  approx_eq_f(self.x_axis.x, 1.0, eps~) &&
  approx_eq_f(self.y_axis.y, 1.0, eps~) &&
  self.x_axis.y.abs() <= eps &&
  self.y_axis.x.abs() <= eps
}

///|
pub fn Affine2::is_identity(self : Affine2, eps? : Float = 1.0e-5) -> Bool {
  self.is_pure_translation(eps~) &&
  self.translation.x.abs() <= eps &&
  self.translation.y.abs() <= eps
}

///|
/// Promote to a 4x4 matrix for the 3D pipeline (z is untouched).
pub fn Affine2::to_mat4(self : Affine2) -> Mat4 {
  {
    x_axis: { x: self.x_axis.x, y: self.x_axis.y, z: 0.0, w: 0.0 },
    y_axis: { x: self.y_axis.x, y: self.y_axis.y, z: 0.0, w: 0.0 },
    z_axis: { x: 0.0, y: 0.0, z: 1.0, w: 0.0 },
    w_axis: { x: self.translation.x, y: self.translation.y, z: 0.0, w: 1.0 },
  }
}

///|
pub fn Affine2::to_mat3(self : Affine2) -> Mat3 {
  {
    x_axis: { x: self.x_axis.x, y: self.x_axis.y, z: 0.0 },
    y_axis: { x: self.y_axis.x, y: self.y_axis.y, z: 0.0 },
    z_axis: { x: 0.0, y: 0.0, z: 1.0 },
  }
}

///|
/// The six floats of the 3x2 affine form, column-major
/// (`[a, b, c, d, tx, ty]`).
pub fn Affine2::to_cols_array(self : Affine2) -> FixedArray[Float] {
  let out : FixedArray[Float] = FixedArray::make(6, 0.0)
  out[0] = self.x_axis.x
  out[1] = self.x_axis.y
  out[2] = self.y_axis.x
  out[3] = self.y_axis.y
  out[4] = self.translation.x
  out[5] = self.translation.y
  out
}

///|
pub fn Affine2::to_mat4_array(self : Affine2) -> FixedArray[Float] {
  self.to_mat4().to_cols_array()
}

///|
pub fn Affine2::approx_eq(self : Affine2, other : Affine2, eps? : Float = EPSILON) -> Bool {
  self.x_axis.approx_eq(other.x_axis, eps~) &&
  self.y_axis.approx_eq(other.y_axis, eps~) &&
  self.translation.approx_eq(other.translation, eps~)
}
