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
        let i0 = mesh.indices[t * 3].reinterpret_as_int()
        let i1 = mesh.indices[t * 3 + 1].reinterpret_as_int()
        let i2 = mesh.indices[t * 3 + 2].reinterpret_as_int()
        let p0 = mesh.positions[i0]
        let p1 = mesh.positions[i1]
        let p2 = mesh.positions[i2]
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
/// Nearest mesh node under an NDC point. Uses the frustum-culled mesh list, so
/// nodes behind the camera or past the far plane are not pickable.
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
          match ray_mesh_hit(ray, self.meshes[mi].mesh(), scene.world_transform(id)) {
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
