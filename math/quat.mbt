// Unit quaternion (x, y, z, w) with `w` the scalar part.
//
// Rotations compose as `q = q1 * q2` (apply `q2` first). All angle-taking
// constructors expect radians.

///|
/// Order in which per-axis rotations are applied by `Quat::from_euler`.
/// `XYZ` means `q = qx * qy * qz`, i.e. `qz` is applied to the vector first.
#derive(Eq, Debug)
pub(all) enum EulerOrder {
  XYZ
  XZY
  YXZ
  YZX
  ZXY
  ZYX
}

///|
#valtype
#derive(Eq, Debug)
pub(all) struct Quat {
  x : Float
  y : Float
  z : Float
  w : Float
}

///|
pub impl Show for Quat with to_string(self) {
  "(\{self.x}, \{self.y}, \{self.z}, \{self.w})"
}

///|
pub fn Quat::identity() -> Quat {
  { x: 0.0, y: 0.0, z: 0.0, w: 1.0 }
}

///|
pub fn Quat::from_xyzw(x : Float, y : Float, z : Float, w : Float) -> Quat {
  { x, y, z, w }
}

///|
pub fn Quat::from_axis_angle(axis : Vec3, angle : Float) -> Quat {
  let a = match axis.try_normalize() {
    Some(n) => n
    None => return Quat::identity()
  }
  let half = angle * 0.5
  let (s, c) = sin_cos(half)
  { x: a.x * s, y: a.y * s, z: a.z * s, w: c }
}

///|
pub fn Quat::from_rotation_x(angle : Float) -> Quat {
  let (s, c) = sin_cos(angle * 0.5)
  { x: s, y: 0.0, z: 0.0, w: c }
}

///|
pub fn Quat::from_rotation_y(angle : Float) -> Quat {
  let (s, c) = sin_cos(angle * 0.5)
  { x: 0.0, y: s, z: 0.0, w: c }
}

///|
pub fn Quat::from_rotation_z(angle : Float) -> Quat {
  let (s, c) = sin_cos(angle * 0.5)
  { x: 0.0, y: 0.0, z: s, w: c }
}

///|
pub fn Quat::from_euler(order : EulerOrder, a : Float, b : Float, c : Float) -> Quat {
  match order {
    XYZ => Quat::from_rotation_x(a) * Quat::from_rotation_y(b) * Quat::from_rotation_z(c)
    XZY => Quat::from_rotation_x(a) * Quat::from_rotation_z(b) * Quat::from_rotation_y(c)
    YXZ => Quat::from_rotation_y(a) * Quat::from_rotation_x(b) * Quat::from_rotation_z(c)
    YZX => Quat::from_rotation_y(a) * Quat::from_rotation_z(b) * Quat::from_rotation_x(c)
    ZXY => Quat::from_rotation_z(a) * Quat::from_rotation_x(b) * Quat::from_rotation_y(c)
    ZYX => Quat::from_rotation_z(a) * Quat::from_rotation_y(b) * Quat::from_rotation_x(c)
  }
}

///|
/// Extract the rotation from a pure rotation matrix (scale is not removed).
pub fn Quat::from_mat3(m : Mat3) -> Quat {
  let m00 = m.x_axis.x
  let m11 = m.y_axis.y
  let m22 = m.z_axis.z
  let trace = m00 + m11 + m22
  let one : Float = 1.0
  let two : Float = 2.0
  let quarter : Float = 0.25
  let q : Quat = if trace > 0.0 {
    let s : Float = (trace + one).sqrt() * two
    {
      x: (m.y_axis.z - m.z_axis.y) / s,
      y: (m.z_axis.x - m.x_axis.z) / s,
      z: (m.x_axis.y - m.y_axis.x) / s,
      w: quarter * s,
    }
  } else if m00 > m11 && m00 > m22 {
    let s : Float = (one + m00 - m11 - m22).sqrt() * two
    {
      x: quarter * s,
      y: (m.y_axis.x + m.x_axis.y) / s,
      z: (m.z_axis.x + m.x_axis.z) / s,
      w: (m.y_axis.z - m.z_axis.y) / s,
    }
  } else if m11 > m22 {
    let s : Float = (one + m11 - m00 - m22).sqrt() * two
    {
      x: (m.y_axis.x + m.x_axis.y) / s,
      y: quarter * s,
      z: (m.z_axis.y + m.y_axis.z) / s,
      w: (m.z_axis.x - m.x_axis.z) / s,
    }
  } else {
    let s : Float = (one + m22 - m00 - m11).sqrt() * two
    {
      x: (m.z_axis.x + m.x_axis.z) / s,
      y: (m.z_axis.y + m.y_axis.z) / s,
      z: quarter * s,
      w: (m.x_axis.y - m.y_axis.x) / s,
    }
  }
  q.normalize()
}

///|
/// Shortest-arc rotation taking direction `from` to direction `to`.
pub fn Quat::from_rotation_arc(from : Vec3, to : Vec3) -> Quat {
  let a = from.normalize()
  let b = to.normalize()
  let d = a.dot(b)
  if d > 0.999999 {
    return Quat::identity()
  }
  if d < -0.999999 {
    // Opposite vectors: rotate 180 degrees about any perpendicular axis.
    let axis = a.any_orthonormal()
    return Quat::from_xyzw(axis.x, axis.y, axis.z, 0.0)
  }
  let c = a.cross(b)
  Quat::from_xyzw(c.x, c.y, c.z, (1.0 : Float) + d).normalize()
}

///|
/// Hamilton product: rotating by `q1 * q2` equals rotating by `q2` then `q1`.
pub impl Mul for Quat with mul(self, other) {
  {
    x: self.w * other.x + self.x * other.w + self.y * other.z - self.z * other.y,
    y: self.w * other.y - self.x * other.z + self.y * other.w + self.z * other.x,
    z: self.w * other.z + self.x * other.y - self.y * other.x + self.z * other.w,
    w: self.w * other.w - self.x * other.x - self.y * other.y - self.z * other.z,
  }
}

///|
pub impl Add for Quat with add(self, other) {
  {
    x: self.x + other.x,
    y: self.y + other.y,
    z: self.z + other.z,
    w: self.w + other.w,
  }
}

///|
pub impl Sub for Quat with sub(self, other) {
  {
    x: self.x - other.x,
    y: self.y - other.y,
    z: self.z - other.z,
    w: self.w - other.w,
  }
}

///|
pub impl Neg for Quat with neg(self) {
  { x: -self.x, y: -self.y, z: -self.z, w: -self.w }
}

///|
pub fn Quat::scale(self : Quat, s : Float) -> Quat {
  { x: self.x * s, y: self.y * s, z: self.z * s, w: self.w * s }
}

///|
pub fn Quat::dot(self : Quat, other : Quat) -> Float {
  self.x * other.x + self.y * other.y + self.z * other.z + self.w * other.w
}

///|
pub fn Quat::length_sq(self : Quat) -> Float {
  self.dot(self)
}

///|
pub fn Quat::length(self : Quat) -> Float {
  self.length_sq().sqrt()
}

///|
/// Rotate a 3D vector by this quaternion (assumed unit length).
pub fn Quat::mul_vec3(self : Quat, v : Vec3) -> Vec3 {
  // v' = v + 2w(q_v x v) + 2 q_v x (q_v x v)
  let qv = Vec3::new(self.x, self.y, self.z)
  let t = qv.cross(v).scale(2.0)
  v + t.scale(self.w) + qv.cross(t)
}

///|
pub fn Quat::conjugate(self : Quat) -> Quat {
  { x: -self.x, y: -self.y, z: -self.z, w: self.w }
}

///|
/// Inverse rotation; for unit quaternions this equals the conjugate.
pub fn Quat::inverse(self : Quat) -> Quat {
  let n = self.length_sq()
  if n <= EPSILON {
    Quat::identity()
  } else {
    {
      x: -self.x / n,
      y: -self.y / n,
      z: -self.z / n,
      w: self.w / n,
    }
  }
}

///|
pub fn Quat::normalize(self : Quat) -> Quat {
  let len = self.length()
  if len <= EPSILON {
    Quat::identity()
  } else {
    {
      x: self.x / len,
      y: self.y / len,
      z: self.z / len,
      w: self.w / len,
    }
  }
}

///|
pub fn Quat::is_normalized(self : Quat, eps? : Float = EPSILON) -> Bool {
  approx_eq_f(self.length_sq(), 1.0, eps~)
}

///|
/// Normalized linear interpolation (cheap, not constant angular velocity).
/// Automatically takes the shortest arc.
pub fn Quat::nlerp(self : Quat, other : Quat, t : Float) -> Quat {
  let end = if self.dot(other) < 0.0 { -other } else { other }
  let blended : Quat = {
    x: lerp_f(self.x, end.x, t),
    y: lerp_f(self.y, end.y, t),
    z: lerp_f(self.z, end.z, t),
    w: lerp_f(self.w, end.w, t),
  }
  blended.normalize()
}

///|
/// Spherical linear interpolation along the shortest arc.
pub fn Quat::slerp(self : Quat, other : Quat, t : Float) -> Quat {
  let mut cosom = self.dot(other)
  let end = if cosom < 0.0 {
    cosom = -cosom
    -other
  } else {
    other
  }
  let nearly_one : Float = 1.0 - 1.0e-6
  if cosom > nearly_one {
    // Quaternions are almost identical: fall back to avoid a division by ~0.
    return self.nlerp(end, t)
  }
  let omega = acos(cosom)
  let sinom = sin(omega)
  if sinom.abs() <= EPSILON {
    return self.nlerp(end, t)
  }
  let a = sin(((1.0 : Float) - t) * omega) / sinom
  let b = sin(t * omega) / sinom
  {
    x: self.x * a + end.x * b,
    y: self.y * a + end.y * b,
    z: self.z * a + end.z * b,
    w: self.w * a + end.w * b,
  }
}

///|
/// Rotation matrix of this (assumed unit) quaternion.
pub fn Quat::to_mat3(self : Quat) -> Mat3 {
  let x = self.x
  let y = self.y
  let z = self.z
  let w = self.w
  let x2 = x + x
  let y2 = y + y
  let z2 = z + z
  let xx = x * x2
  let xy = x * y2
  let xz = x * z2
  let yy = y * y2
  let yz = y * z2
  let zz = z * z2
  let wx = w * x2
  let wy = w * y2
  let wz = w * z2
  {
    x_axis: { x: (1.0 : Float) - (yy + zz), y: xy + wz, z: xz - wy },
    y_axis: { x: xy - wz, y: (1.0 : Float) - (xx + zz), z: yz + wx },
    z_axis: { x: xz + wy, y: yz - wx, z: (1.0 : Float) - (xx + yy) },
  }
}

///|
pub fn Quat::to_mat4(self : Quat) -> Mat4 {
  Mat4::from_mat3(self.to_mat3())
}

///|
/// Decompose into `(axis, angle)` with a unit axis and angle in `[0, PI]`.
pub fn Quat::to_axis_angle(self : Quat) -> (Vec3, Float) {
  let q = if self.w < 0.0 { -self } else { self }
  let v = Vec3::new(q.x, q.y, q.z)
  let s = v.length()
  if s <= EPSILON {
    return (Vec3::unit_x(), 0.0)
  }
  let angle = (2.0 : Float) * atan2(s, q.w)
  (v.scale((1.0 : Float) / s), angle)
}

///|
/// Interpolate towards `other` by at most `max_angle` radians (shortest arc).
pub fn Quat::rotate_towards(self : Quat, other : Quat, max_angle : Float) -> Quat {
  let d = self.dot(other).abs().min(1.0)
  let angle = (2.0 : Float) * acos(d)
  if angle <= max_angle || angle <= EPSILON {
    return other
  }
  self.slerp(other, max_angle / angle)
}

///|
pub fn Quat::approx_eq(self : Quat, other : Quat, eps? : Float = EPSILON) -> Bool {
  // `q` and `-q` describe the same rotation.
  let direct = approx_eq_f(self.x, other.x, eps~) &&
    approx_eq_f(self.y, other.y, eps~) &&
    approx_eq_f(self.z, other.z, eps~) &&
    approx_eq_f(self.w, other.w, eps~)
  if direct {
    return true
  }
  approx_eq_f(self.x, -other.x, eps~) &&
  approx_eq_f(self.y, -other.y, eps~) &&
  approx_eq_f(self.z, -other.z, eps~) &&
  approx_eq_f(self.w, -other.w, eps~)
}

///|
pub fn Quat::to_array(self : Quat) -> FixedArray[Float] {
  let out : FixedArray[Float] = FixedArray::make(4, 0.0)
  out[0] = self.x
  out[1] = self.y
  out[2] = self.z
  out[3] = self.w
  out
}
