// CPU picking: ray vs `MeshData` triangles, in world space.
//
// The ray is transformed into the mesh's local space without renormalizing the
// direction, so the returned `t` is still the world-space distance along a
// normalized ray. Bounds are tested first to reject most nodes cheaply.

///|
pub(all) struct MeshHit {
  triangle : Int
  distance : Float
  position : @tmath.Vec3
  normal : @tmath.Vec3
}

///|
pub(all) struct PickHit {
  node : NodeId
  distance : Float
  position : @tmath.Vec3
  normal : @tmath.Vec3
  triangle : Int
}

///|
pub fn ray_mesh_hit(
  ray : @tmath.Ray,
  mesh : @tgeo.MeshData,
  world : @tmath.Affine3,
) -> MeshHit? {
  match world.inverse() {
    None => None
    Some(inv) => {
      let local_ray = @tmath.Ray::new(
        inv.transform_point3(ray.origin),
        inv.transform_vector3(ray.dir),
      )
      let limits = match local_ray.intersect_aabb(mesh.bounds()) {
        Some(r) => r
        None => return None
      }
      if limits.1 < 0.0 {
        return None
      }
      let nm = match world.normal_matrix() {
        Some(m) => m
        None => world.matrix3
      }
      let mut best : Float = 1.0e30
      let mut best_triangle = -1
      let mut best_normal = @tmath.Vec3::new(0.0, 1.0, 0.0)
      let count = mesh.triangle_count()
      for t = 0; t < count; t = t + 1 {
        let i0 = mesh.indices()[t * 3].reinterpret_as_int()
        let i1 = mesh.indices()[t * 3 + 1].reinterpret_as_int()
        let i2 = mesh.indices()[t * 3 + 2].reinterpret_as_int()
        let p0 = mesh.positions()[i0]
        let p1 = mesh.positions()[i1]
        let p2 = mesh.positions()[i2]
        match local_ray.intersect_triangle(p0, p1, p2) {
          Some(hit_t) =>
            if hit_t > 1.0e-6 && hit_t < best {
              best = hit_t
              best_triangle = t
              let face_n = (p1 - p0).cross(p2 - p0)
              if face_n.length_sq() > (1.0e-20 : Float) {
                best_normal = nm.mul_vec3(face_n).normalize()
              }
            }
          None => ()
        }
      }
      if best_triangle < 0 {
        None
      } else {
        Some({
          triangle: best_triangle,
          distance: best,
          position: ray.at(best),
          normal: best_normal,
        })
      }
    }
  }
}

///|
/// World-space pick radius for line nodes. Lines have no thickness, so picking
/// accepts segments within this distance of the ray.
pub const LINE_PICK_RADIUS : Float = 0.02

///|
/// Closest approach between a ray and a segment.
/// Returns `(distance, ray_t)`; `ray_t` is the parameter along `ray.dir`
/// (which is expected to be normalized, like `Camera::screen_ray`).
fn ray_segment_closest(
  ray : @tmath.Ray,
  a : @tmath.Vec3,
  b : @tmath.Vec3,
) -> (Float, Float) {
  let u = ray.dir
  let v = b - a
  let w = ray.origin - a
  let aa = u.dot(u)
  let bb = u.dot(v)
  let cc = v.dot(v)
  let dd = u.dot(w)
  let ee = v.dot(w)
  let denom = aa * cc - bb * bb
  let mut s : Float = 0.0
  let mut t : Float = 0.0
  if denom.abs() > (1.0e-9 : Float) {
    s = @tmath.clamp_f((aa * ee - bb * dd) / denom, 0.0, 1.0)
    t = (bb * s - dd) / aa
    if t < 0.0 {
      t = 0.0
      s = if cc > (1.0e-12 : Float) {
        @tmath.clamp_f(ee / cc, 0.0, 1.0)
      } else {
        0.0
      }
    }
  } else {
    // Parallel: the distance is constant over the overlap.
    s = if cc > (1.0e-12 : Float) {
      @tmath.clamp_f(ee / cc, 0.0, 1.0)
    } else {
      0.0
    }
    t = (bb * s - dd) / aa
    if t < 0.0 {
      t = 0.0
    }
  }
  let on_ray = ray.origin + u.scale(t)
  let on_segment = a + v.scale(s)
  (on_ray.distance(on_segment), t)
}

///|
/// Nearest line segment under a ray, in world space.
/// `triangle` in the returned hit carries the segment index.
pub fn ray_lines_hit(
  ray : @tmath.Ray,
  lines : @tgeo.LineData,
  world : @tmath.Affine3,
  radius : Float,
) -> MeshHit? {
  let mut best : Float = 1.0e30
  let mut best_segment = -1
  let mut best_direction = @tmath.Vec3::unit_x()
  let count = lines.segment_count()
  for i = 0; i < count; i = i + 1 {
    let ia = lines.indices[2 * i].reinterpret_as_int()
    let ib = lines.indices[2 * i + 1].reinterpret_as_int()
    let a = world.transform_point3(lines.positions[ia])
    let b = world.transform_point3(lines.positions[ib])
    let (distance, t) = ray_segment_closest(ray, a, b)
    if distance <= radius && t > 1.0e-6 && t < best {
      best = t
      best_segment = i
      best_direction = match (b - a).try_normalize() {
        Some(d) => d
        None => @tmath.Vec3::unit_x()
      }
    }
  }
  if best_segment < 0 {
    None
  } else {
    Some({
      triangle: best_segment,
      distance: best,
      position: ray.at(best),
      normal: best_direction,
    })
  }
}

///|
/// The picking BVH for mesh slot `mi`, built on first use and cached for the
/// renderer's lifetime. Uploaded meshes are immutable, so the tree never needs
/// invalidation; the CPU copy is already retained for picking.
fn Renderer3D::pick_bvh(self : Renderer3D, mi : Int) -> MeshBvh? {
  if mi < 0 || mi >= self.pick_bvhs.length() || mi >= self.meshes.length() {
    return None
  }
  match self.pick_bvhs[mi] {
    Some(b) => Some(b)
    None => {
      let b = MeshBvh::build(self.meshes[mi].mesh())
      self.pick_bvhs[mi] = Some(b)
      Some(b)
    }
  }
}

///|
/// Nearest mesh or line node under an NDC point. Uses the frustum-culled
/// drawable list, so nodes behind the camera or past the far plane are not
/// pickable.
pub fn Renderer3D::pick(
  self : Renderer3D,
  scene : Scene,
  camera : NodeId,
  ndc_x : Float,
  ndc_y : Float,
  layer_mask? : UInt = (0xFFFFFFFF : UInt),
) -> PickHit? {
  scene.update()
  let cam = match scene.payload(camera) {
    Some(NodePayload::Camera(c)) => c
    _ => return None
  }
  let world = scene.world_transform(camera)
  let ray = match cam.screen_ray(world, ndc_x, ndc_y) {
    Some(r) => r
    None => return None
  }
  let vp = match cam.view_proj(world) {
    Some(v) => v
    None => return None
  }
  let frustum = @tmath.Frustum::from_view_proj(vp)
  let ids = scene.collect_visible(frustum, layer_mask)
  let mut best : PickHit? = None
  for id in ids {
    match scene.payload(id) {
      Some(NodePayload::Mesh(inst)) => {
        let mi = inst.mesh.id()
        if mi >= 0 && mi < self.meshes.length() {
          match self.pick_bvh(mi) {
            Some(bvh) =>
              match bvh.ray_hit(ray, scene.world_transform(id)) {
                Some(h) => {
                  let closer = match best {
                    Some(b) => h.distance < b.distance
                    None => true
                  }
                  if closer {
                    best = Some({
                      node: id,
                      distance: h.distance,
                      position: h.position,
                      normal: h.normal,
                      triangle: h.triangle,
                    })
                  }
                }
                None => ()
              }
            None => ()
          }
        }
      }
      Some(NodePayload::Lines(inst)) => {
        let li = inst.lines.id()
        if li >= 0 && li < self.line_sets.length() {
          match ray_lines_hit(
            ray,
            self.line_sets[li].cpu,
            scene.world_transform(id),
            LINE_PICK_RADIUS,
          ) {
            Some(h) => {
              let closer = match best {
                Some(b) => h.distance < b.distance
                None => true
              }
              if closer {
                best = Some({
                  node: id,
                  distance: h.distance,
                  position: h.position,
                  normal: h.normal,
                  triangle: h.triangle,
                })
              }
            }
            None => ()
          }
        }
      }
      _ => ()
    }
  }
  best
}
