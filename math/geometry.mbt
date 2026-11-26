// Geometric primitives for culling and intersection queries: `Ray`, `Plane`,
// `Aabb2`, `Aabb3`, `Sphere`, and `Frustum`.
//
// Every "does it intersect" test is conservative: a `true` result may be a
// false positive near the boundary, but `false` is always exact.

///|
#valtype
#derive(Eq, Debug)
pub(all) struct Ray {
  origin : Vec3
  dir : Vec3
}

///|
/// A ray direction does not have to be normalized; `t` values are expressed in
/// `dir` units. Use `Ray::new_normalized` if you want distances.
pub fn Ray::new(origin : Vec3, dir : Vec3) -> Ray {
  { origin, dir }
}

///|
pub fn Ray::new_normalized(origin : Vec3, dir : Vec3) -> Ray {
  { origin, dir: dir.normalize() }
}

///|
pub fn Ray::at(self : Ray, t : Float) -> Vec3 {
  self.origin + self.dir.scale(t)
}

///|
#valtype
#derive(Eq, Debug)
pub(all) struct Plane {
  normal : Vec3
  d : Float
}

///|
/// Plane equation: `dot(normal, p) + d = 0`.
pub fn Plane::new(normal : Vec3, d : Float) -> Plane {
  { normal, d }
}

///|
/// Plane through `point` with the given normal.
pub fn Plane::from_point_normal(point : Vec3, normal : Vec3) -> Plane {
  { normal, d: -normal.dot(point) }
}

///|
pub fn Plane::normalize(self : Plane) -> Plane {
  let len = self.normal.length()
  if len <= EPSILON {
    self
  } else {
    let inv : Float = 1.0 / len
    { normal: self.normal.scale(inv), d: self.d * inv }
  }
}

///|
/// Positive on the side the normal points to.
pub fn Plane::signed_distance(self : Plane, point : Vec3) -> Float {
  self.normal.dot(point) + self.d
}

///|
/// Orthogonal projection of `point` onto the plane.
pub fn Plane::project_point(self : Plane, point : Vec3) -> Vec3 {
  point - self.normal.scale(self.signed_distance(point))
}

///|
#valtype
#derive(Eq, Debug)
pub(all) struct Aabb2 {
  min : Vec2
  max : Vec2
}

///|
pub fn Aabb2::new(min : Vec2, max : Vec2) -> Aabb2 {
  { min, max }
}

///|
pub fn Aabb2::from_center_half_extents(center : Vec2, half_extents : Vec2) -> Aabb2 {
  { min: center - half_extents, max: center + half_extents }
}

///|
pub fn Aabb2::center(self : Aabb2) -> Vec2 {
  (self.min + self.max).scale(0.5)
}

///|
pub fn Aabb2::size(self : Aabb2) -> Vec2 {
  self.max - self.min
}

///|
pub fn Aabb2::contains_point(self : Aabb2, p : Vec2) -> Bool {
  p.x >= self.min.x &&
  p.x <= self.max.x &&
  p.y >= self.min.y &&
  p.y <= self.max.y
}

///|
pub fn Aabb2::intersects(self : Aabb2, other : Aabb2) -> Bool {
  self.min.x <= other.max.x &&
  self.max.x >= other.min.x &&
  self.min.y <= other.max.y &&
  self.max.y >= other.min.y
}

///|
pub fn Aabb2::union(self : Aabb2, other : Aabb2) -> Aabb2 {
  { min: self.min.min(other.min), max: self.max.max(other.max) }
}

///|
pub fn Aabb2::expand(self : Aabb2, by : Vec2) -> Aabb2 {
  { min: self.min - by, max: self.max + by }
}

///|
#valtype
#derive(Eq, Debug)
pub(all) struct Aabb3 {
  min : Vec3
  max : Vec3
}

///|
pub fn Aabb3::new(min : Vec3, max : Vec3) -> Aabb3 {
  { min, max }
}

///|
pub fn Aabb3::from_center_half_extents(center : Vec3, half_extents : Vec3) -> Aabb3 {
  { min: center - half_extents, max: center + half_extents }
}

///|
pub fn Aabb3::from_points(points : FixedArray[Vec3]) -> Aabb3 {
  let mut lo = Vec3::splat(1.0e30)
  let mut hi = Vec3::splat(-1.0e30)
  for i = 0; i < points.length(); i = i + 1 {
    let p = points[i]
    lo = lo.min(p)
    hi = hi.max(p)
  }
  { min: lo, max: hi }
}

///|
pub fn Aabb3::center(self : Aabb3) -> Vec3 {
  (self.min + self.max).scale(0.5)
}

///|
pub fn Aabb3::size(self : Aabb3) -> Vec3 {
  self.max - self.min
}

///|
pub fn Aabb3::half_extents(self : Aabb3) -> Vec3 {
  (self.max - self.min).scale(0.5)
}

///|
pub fn Aabb3::volume(self : Aabb3) -> Float {
  let s = self.size()
  s.x * s.y * s.z
}

///|
pub fn Aabb3::contains_point(self : Aabb3, p : Vec3) -> Bool {
  p.x >= self.min.x &&
  p.x <= self.max.x &&
  p.y >= self.min.y &&
  p.y <= self.max.y &&
  p.z >= self.min.z &&
  p.z <= self.max.z
}

///|
pub fn Aabb3::contains_aabb(self : Aabb3, other : Aabb3) -> Bool {
  other.min.x >= self.min.x &&
  other.max.x <= self.max.x &&
  other.min.y >= self.min.y &&
  other.max.y <= self.max.y &&
  other.min.z >= self.min.z &&
  other.max.z <= self.max.z
}

///|
pub fn Aabb3::intersects(self : Aabb3, other : Aabb3) -> Bool {
  self.min.x <= other.max.x &&
  self.max.x >= other.min.x &&
  self.min.y <= other.max.y &&
  self.max.y >= other.min.y &&
  self.min.z <= other.max.z &&
  self.max.z >= other.min.z
}

///|
pub fn Aabb3::union(self : Aabb3, other : Aabb3) -> Aabb3 {
  { min: self.min.min(other.min), max: self.max.max(other.max) }
}

///|
pub fn Aabb3::expand(self : Aabb3, by : Vec3) -> Aabb3 {
  { min: self.min - by, max: self.max + by }
}

///|
pub fn Aabb3::corners(self : Aabb3) -> FixedArray[Vec3] {
  let out : FixedArray[Vec3] = FixedArray::make(8, Vec3::zero())
  out[0] = Vec3::new(self.min.x, self.min.y, self.min.z)
  out[1] = Vec3::new(self.max.x, self.min.y, self.min.z)
  out[2] = Vec3::new(self.min.x, self.max.y, self.min.z)
  out[3] = Vec3::new(self.max.x, self.max.y, self.min.z)
  out[4] = Vec3::new(self.min.x, self.min.y, self.max.z)
  out[5] = Vec3::new(self.max.x, self.min.y, self.max.z)
  out[6] = Vec3::new(self.min.x, self.max.y, self.max.z)
  out[7] = Vec3::new(self.max.x, self.max.y, self.max.z)
  out
}

///|
/// Tight AABB of the eight transformed corners.
pub fn Aabb3::transform(self : Aabb3, affine : Affine3) -> Aabb3 {
  let cs = self.corners()
  let out : FixedArray[Vec3] = FixedArray::make(8, Vec3::zero())
  for i = 0; i < 8; i = i + 1 {
    out[i] = affine.transform_point3(cs[i])
  }
  Aabb3::from_points(out)
}

///|
/// Transform as directions (ignores translation), e.g. for a normal-space box.
pub fn Aabb3::transform_direction(self : Aabb3, m : Mat3) -> Aabb3 {
  let cs = self.corners()
  let out : FixedArray[Vec3] = FixedArray::make(8, Vec3::zero())
  for i = 0; i < 8; i = i + 1 {
    out[i] = m.mul_vec3(cs[i])
  }
  Aabb3::from_points(out)
}

///|
#valtype
#derive(Eq, Debug)
pub(all) struct Sphere {
  center : Vec3
  radius : Float
}

///|
pub fn Sphere::new(center : Vec3, radius : Float) -> Sphere {
  { center, radius }
}

///|
pub fn Sphere::contains_point(self : Sphere, p : Vec3) -> Bool {
  self.center.distance_sq(p) <= self.radius * self.radius
}

///|
pub fn Sphere::intersects_sphere(self : Sphere, other : Sphere) -> Bool {
  let r = self.radius + other.radius
  self.center.distance_sq(other.center) <= r * r
}

///|
/// Conservative sphere/AABB overlap test.
pub fn Sphere::intersects_aabb(self : Sphere, box : Aabb3) -> Bool {
  let closest = self.center.max(box.min).min(box.max)
  self.center.distance_sq(closest) <= self.radius * self.radius
}

///|
/// Six normalized clipping planes (left, right, bottom, top, near, far).
/// Not a `#valtype` because it owns a heap `FixedArray`.
pub(all) struct Frustum {
  planes : FixedArray[Plane]
}

///|
/// Extract the six clipping planes from a view-projection matrix
/// (Gribb-Hartmann). The `clip` argument selects the depth range; the Y
/// convention does not affect the result because both Y planes are kept.
pub fn Frustum::from_view_proj(
  view_proj : Mat4,
  clip? : ClipSpace = ClipSpace::Vulkan,
) -> Frustum {
  let r0 = view_proj.row0()
  let r1 = view_proj.row1()
  let r2 = view_proj.row2()
  let r3 = view_proj.row3()
  let planes : FixedArray[Plane] = FixedArray::make(6, Plane::new(Vec3::unit_x(), 0.0))
  planes[0] = plane_from_row(r3 + r0)
  planes[1] = plane_from_row(r3 - r0)
  planes[2] = plane_from_row(r3 + r1)
  planes[3] = plane_from_row(r3 - r1)
  if clip.depth_zero_to_one() {
    planes[4] = plane_from_row(r2)
  } else {
    planes[4] = plane_from_row(r3 + r2)
  }
  planes[5] = plane_from_row(r3 - r2)
  { planes, }
}

///|
fn plane_from_row(row : Vec4) -> Plane {
  Plane::new(Vec3::new(row.x, row.y, row.z), row.w).normalize()
}

///|
/// `true` when the box is not fully outside any plane.
pub fn Frustum::intersects_aabb(self : Frustum, box : Aabb3) -> Bool {
  for i = 0; i < self.planes.length(); i = i + 1 {
    let plane = self.planes[i]
    // p-vertex: the box corner furthest along the plane normal.
    let p = Vec3::new(
      if plane.normal.x >= 0.0 { box.max.x } else { box.min.x },
      if plane.normal.y >= 0.0 { box.max.y } else { box.min.y },
      if plane.normal.z >= 0.0 { box.max.z } else { box.min.z },
    )
    if plane.signed_distance(p) < 0.0 {
      return false
    }
  }
  true
}

///|
pub fn Frustum::intersects_sphere(self : Frustum, s : Sphere) -> Bool {
  for i = 0; i < self.planes.length(); i = i + 1 {
    if self.planes[i].signed_distance(s.center) < -s.radius {
      return false
    }
  }
  true
}

///|
pub fn Frustum::contains_point(self : Frustum, p : Vec3) -> Bool {
  for i = 0; i < self.planes.length(); i = i + 1 {
    if self.planes[i].signed_distance(p) < 0.0 {
      return false
    }
  }
  true
}

///|
/// Slab test. Returns `(t_enter, t_exit)` along the ray, or `None`.
pub fn Ray::intersect_aabb(self : Ray, box : Aabb3) -> (Float, Float)? {
  match slab(self.origin.x, self.dir.x, box.min.x, box.max.x, 0.0, 1.0e30) {
    None => None
    Some((t0, t1)) =>
      match slab(self.origin.y, self.dir.y, box.min.y, box.max.y, t0, t1) {
        None => None
        Some((u0, u1)) =>
          match slab(self.origin.z, self.dir.z, box.min.z, box.max.z, u0, u1) {
            None => None
            Some((v0, v1)) => Some((v0, v1))
          }
      }
  }
}

///|
fn slab(
  o : Float,
  d : Float,
  lo : Float,
  hi : Float,
  t0 : Float,
  t1 : Float,
) -> (Float, Float)? {
  if d.abs() < 1.0e-20 {
    if o < lo || o > hi {
      None
    } else {
      Some((t0, t1))
    }
  } else {
    let inv : Float = 1.0 / d
    let a = (lo - o) * inv
    let b = (hi - o) * inv
    let near = if a < b { a } else { b }
    let far = if a < b { b } else { a }
    let n0 = if near > t0 { near } else { t0 }
    let n1 = if far < t1 { far } else { t1 }
    if n0 > n1 {
      None
    } else {
      Some((n0, n1))
    }
  }
}

///|
/// Nearest forward hit distance against a sphere, or `None`.
pub fn Ray::intersect_sphere(self : Ray, center : Vec3, radius : Float) -> Float? {
  let m = self.origin - center
  let a = self.dir.length_sq()
  if a <= 1.0e-20 {
    return None
  }
  let b = m.dot(self.dir)
  let c = m.length_sq() - radius * radius
  let disc = b * b - a * c
  if disc < 0.0 {
    return None
  }
  let sq = disc.sqrt()
  let t0 = (-b - sq) / a
  let t1 = (-b + sq) / a
  if t0 >= 0.0 {
    Some(t0)
  } else if t1 >= 0.0 {
    Some(t1)
  } else {
    None
  }
}

///|
/// Ray/plane intersection distance, or `None` when parallel or behind.
pub fn Ray::intersect_plane(self : Ray, plane : Plane) -> Float? {
  let denom = plane.normal.dot(self.dir)
  if denom.abs() < 1.0e-20 {
    return None
  }
  let t = -plane.signed_distance(self.origin) / denom
  if t >= 0.0 {
    Some(t)
  } else {
    None
  }
}

///|
/// Moller-Trumbore ray/triangle intersection; returns the forward distance.
pub fn Ray::intersect_triangle(
  self : Ray,
  v0 : Vec3,
  v1 : Vec3,
  v2 : Vec3,
) -> Float? {
  let e1 = v1 - v0
  let e2 = v2 - v0
  let pv = self.dir.cross(e2)
  let det = e1.dot(pv)
  if det.abs() < 1.0e-12 {
    return None
  }
  let inv : Float = 1.0 / det
  let tv = self.origin - v0
  let u = tv.dot(pv) * inv
  if u < 0.0 || u > 1.0 {
    return None
  }
  let qv = tv.cross(e1)
  let v = self.dir.dot(qv) * inv
  if v < 0.0 || u + v > 1.0 {
    return None
  }
  let t = e2.dot(qv) * inv
  if t >= 0.0 {
    Some(t)
  } else {
    None
  }
}
