// Double-precision unit quaternion. Use it while authoring high-precision
// camera rigs, then down-cast with `to_quat()` for GPU-facing types.

///|
#valtype
#derive(Eq, Debug)
pub(all) struct DQuat {
  x : Double
  y : Double
  z : Double
  w : Double
}

///|
pub impl Show for DQuat with to_string(self) {
  "(\{self.x}, \{self.y}, \{self.z}, \{self.w})"
}

///|
pub fn DQuat::identity() -> DQuat {
  { x: 0.0, y: 0.0, z: 0.0, w: 1.0 }
}

///|
pub fn DQuat::from_xyzw(x : Double, y : Double, z : Double, w : Double) -> DQuat {
  { x, y, z, w }
}

///|
fn dsin_cos(radians : Double) -> (Double, Double) {
  (@math.sin(radians), @math.cos(radians))
}

///|
pub fn DQuat::from_axis_angle(axis : DVec3, angle : Double) -> DQuat {
  let a = match axis.try_normalize() {
    Some(n) => n
    None => return DQuat::identity()
  }
  let half = angle * 0.5
  let (s, c) = dsin_cos(half)
  { x: a.x * s, y: a.y * s, z: a.z * s, w: c }
}

///|
pub fn DQuat::from_rotation_x(angle : Double) -> DQuat {
  let (s, c) = dsin_cos(angle * 0.5)
  { x: s, y: 0.0, z: 0.0, w: c }
}

///|
pub fn DQuat::from_rotation_y(angle : Double) -> DQuat {
  let (s, c) = dsin_cos(angle * 0.5)
  { x: 0.0, y: s, z: 0.0, w: c }
}

///|
pub fn DQuat::from_rotation_z(angle : Double) -> DQuat {
  let (s, c) = dsin_cos(angle * 0.5)
  { x: 0.0, y: 0.0, z: s, w: c }
}

///|
pub fn DQuat::from_euler(
  order : @tmath.EulerOrder,
  a : Double,
  b : Double,
  c : Double,
) -> DQuat {
  match order {
    @tmath.EulerOrder::XYZ =>
      DQuat::from_rotation_x(a) * DQuat::from_rotation_y(b) * DQuat::from_rotation_z(c)
    @tmath.EulerOrder::XZY =>
      DQuat::from_rotation_x(a) * DQuat::from_rotation_z(b) * DQuat::from_rotation_y(c)
    @tmath.EulerOrder::YXZ =>
      DQuat::from_rotation_y(a) * DQuat::from_rotation_x(b) * DQuat::from_rotation_z(c)
    @tmath.EulerOrder::YZX =>
      DQuat::from_rotation_y(a) * DQuat::from_rotation_z(b) * DQuat::from_rotation_x(c)
    @tmath.EulerOrder::ZXY =>
      DQuat::from_rotation_z(a) * DQuat::from_rotation_x(b) * DQuat::from_rotation_y(c)
    @tmath.EulerOrder::ZYX =>
      DQuat::from_rotation_z(a) * DQuat::from_rotation_y(b) * DQuat::from_rotation_x(c)
  }
}

///|
pub fn DQuat::from_mat3(m : DMat3) -> DQuat {
  let m00 = m.x_axis.x
  let m11 = m.y_axis.y
  let m22 = m.z_axis.z
  let trace = m00 + m11 + m22
  let q : DQuat = if trace > 0.0 {
    let s = (trace + 1.0).sqrt() * 2.0
    {
      x: (m.y_axis.z - m.z_axis.y) / s,
      y: (m.z_axis.x - m.x_axis.z) / s,
      z: (m.x_axis.y - m.y_axis.x) / s,
      w: 0.25 * s,
    }
  } else if m00 > m11 && m00 > m22 {
    let s = (1.0 + m00 - m11 - m22).sqrt() * 2.0
    {
      x: 0.25 * s,
      y: (m.y_axis.x + m.x_axis.y) / s,
      z: (m.z_axis.x + m.x_axis.z) / s,
      w: (m.y_axis.z - m.z_axis.y) / s,
    }
  } else if m11 > m22 {
    let s = (1.0 + m11 - m00 - m22).sqrt() * 2.0
    {
      x: (m.y_axis.x + m.x_axis.y) / s,
      y: 0.25 * s,
      z: (m.z_axis.y + m.y_axis.z) / s,
      w: (m.z_axis.x - m.x_axis.z) / s,
    }
  } else {
    let s = (1.0 + m22 - m00 - m11).sqrt() * 2.0
    {
      x: (m.z_axis.x + m.x_axis.z) / s,
      y: (m.z_axis.y + m.y_axis.z) / s,
      z: 0.25 * s,
      w: (m.x_axis.y - m.y_axis.x) / s,
    }
  }
  q.normalize()
}

///|
pub fn DQuat::from_rotation_arc(from : DVec3, to : DVec3) -> DQuat {
  let a = from.normalize()
  let b = to.normalize()
  let d = a.dot(b)
  if d > 0.999999999 {
    return DQuat::identity()
  }
  if d < -0.999999999 {
    let axis = if a.x.abs() < 0.5 {
      DVec3::unit_x()
    } else {
      DVec3::unit_y()
    }
    let perp = (axis - a.scale(axis.dot(a))).normalize()
    return DQuat::from_xyzw(perp.x, perp.y, perp.z, 0.0)
  }
  let c = a.cross(b)
  DQuat::from_xyzw(c.x, c.y, c.z, 1.0 + d).normalize()
}

///|
pub impl Mul for DQuat with mul(self, other) {
  {
    x: self.w * other.x + self.x * other.w + self.y * other.z - self.z * other.y,
    y: self.w * other.y - self.x * other.z + self.y * other.w + self.z * other.x,
    z: self.w * other.z + self.x * other.y - self.y * other.x + self.z * other.w,
    w: self.w * other.w - self.x * other.x - self.y * other.y - self.z * other.z,
  }
}

///|
pub impl Add for DQuat with add(self, other) {
  {
    x: self.x + other.x,
    y: self.y + other.y,
    z: self.z + other.z,
    w: self.w + other.w,
  }
}

///|
pub impl Sub for DQuat with sub(self, other) {
  {
    x: self.x - other.x,
    y: self.y - other.y,
    z: self.z - other.z,
    w: self.w - other.w,
  }
}

///|
pub impl Neg for DQuat with neg(self) {
  { x: -self.x, y: -self.y, z: -self.z, w: -self.w }
}

///|
pub fn DQuat::scale(self : DQuat, s : Double) -> DQuat {
  { x: self.x * s, y: self.y * s, z: self.z * s, w: self.w * s }
}

///|
pub fn DQuat::dot(self : DQuat, other : DQuat) -> Double {
  self.x * other.x + self.y * other.y + self.z * other.z + self.w * other.w
}

///|
pub fn DQuat::length_sq(self : DQuat) -> Double {
  self.dot(self)
}

///|
pub fn DQuat::length(self : DQuat) -> Double {
  self.length_sq().sqrt()
}

///|
pub fn DQuat::normalize(self : DQuat) -> DQuat {
  let len = self.length()
  if len <= EPSILON {
    DQuat::identity()
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
pub fn DQuat::conjugate(self : DQuat) -> DQuat {
  { x: -self.x, y: -self.y, z: -self.z, w: self.w }
}

///|
pub fn DQuat::inverse(self : DQuat) -> DQuat {
  let n = self.length_sq()
  if n <= EPSILON {
    DQuat::identity()
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
pub fn DQuat::mul_vec3(self : DQuat, v : DVec3) -> DVec3 {
  let qv = DVec3::new(self.x, self.y, self.z)
  let t = qv.cross(v).scale(2.0)
  v + t.scale(self.w) + qv.cross(t)
}

///|
pub fn DQuat::nlerp(self : DQuat, other : DQuat, t : Double) -> DQuat {
  let end = if self.dot(other) < 0.0 { -other } else { other }
  let blended : DQuat = {
    x: self.x + (end.x - self.x) * t,
    y: self.y + (end.y - self.y) * t,
    z: self.z + (end.z - self.z) * t,
    w: self.w + (end.w - self.w) * t,
  }
  blended.normalize()
}

///|
pub fn DQuat::slerp(self : DQuat, other : DQuat, t : Double) -> DQuat {
  let mut cosom = self.dot(other)
  let end = if cosom < 0.0 {
    cosom = -cosom
    -other
  } else {
    other
  }
  if cosom > 0.999999999999 {
    return self.nlerp(end, t)
  }
  let omega = @math.acos(cosom)
  let sinom = @math.sin(omega)
  if sinom.abs() <= EPSILON {
    return self.nlerp(end, t)
  }
  let a = @math.sin((1.0 - t) * omega) / sinom
  let b = @math.sin(t * omega) / sinom
  {
    x: self.x * a + end.x * b,
    y: self.y * a + end.y * b,
    z: self.z * a + end.z * b,
    w: self.w * a + end.w * b,
  }
}

///|
pub fn DQuat::to_dmat3(self : DQuat) -> DMat3 {
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
    x_axis: { x: 1.0 - (yy + zz), y: xy + wz, z: xz - wy },
    y_axis: { x: xy - wz, y: 1.0 - (xx + zz), z: yz + wx },
    z_axis: { x: xz + wy, y: yz - wx, z: 1.0 - (xx + yy) },
  }
}

///|
pub fn DQuat::to_mat3(self : DQuat) -> @tmath.Mat3 {
  self.to_dmat3().to_mat3()
}

///|
/// Down-cast to the single-precision quaternion used by `tycho_math`.
pub fn DQuat::to_quat(self : DQuat) -> @tmath.Quat {
  {
    x: Float::from_double(self.x),
    y: Float::from_double(self.y),
    z: Float::from_double(self.z),
    w: Float::from_double(self.w),
  }
}

///|
pub fn DQuat::from_quat(q : @tmath.Quat) -> DQuat {
  { x: q.x.to_double(), y: q.y.to_double(), z: q.z.to_double(), w: q.w.to_double() }
}

///|
pub fn DQuat::approx_eq(self : DQuat, other : DQuat, eps? : Double = EPSILON) -> Bool {
  let direct = (self.x - other.x).abs() <= eps &&
    (self.y - other.y).abs() <= eps &&
    (self.z - other.z).abs() <= eps &&
    (self.w - other.w).abs() <= eps
  if direct {
    return true
  }
  (self.x + other.x).abs() <= eps &&
  (self.y + other.y).abs() <= eps &&
  (self.z + other.z).abs() <= eps &&
  (self.w + other.w).abs() <= eps
}
