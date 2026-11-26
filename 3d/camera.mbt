// Camera component: projection parameters + clip-space convention.
//
// The node's world `Affine3` supplies the view transform. The default
// perspective projection is infinite reversed-Z (best depth precision), which
// tycho_3d renders with `GreaterEqual` and a zero clear value.

///|
pub(all) struct PerspectiveParams {
  fov_y_rad : Float
  aspect : Float
  near : Float
  // `None` selects an infinite reversed-Z projection.
  far : Float?
}

///|
pub(all) struct OrthoParams {
  left : Float
  right : Float
  bottom : Float
  top : Float
  near : Float
  far : Float
}

///|
pub(all) enum Projection {
  Perspective(PerspectiveParams)
  Orthographic(OrthoParams)
}

///|
pub(all) struct Camera {
  projection : Projection
  clip : @tmath.ClipSpace
}

///|
pub fn Camera::perspective(
  fov_y_rad : Float,
  aspect : Float,
  near? : Float = 0.1,
  far? : Float? = None,
  clip? : @tmath.ClipSpace = @tmath.ClipSpace::Vulkan,
) -> Camera {
  {
    projection: Projection::Perspective({ fov_y_rad, aspect, near, far }),
    clip,
  }
}

///|
pub fn Camera::orthographic(
  left : Float,
  right : Float,
  bottom : Float,
  top : Float,
  near? : Float = 0.1,
  far? : Float = 100.0,
  clip? : @tmath.ClipSpace = @tmath.ClipSpace::Vulkan,
) -> Camera {
  {
    projection: Projection::Orthographic({ left, right, bottom, top, near, far }),
    clip,
  }
}

///|
pub fn Camera::projection_matrix(self : Camera) -> @tmath.Mat4 {
  match self.projection {
    Perspective(p) =>
      match p.far {
        Some(f) => @tmath.perspective_rh(p.fov_y_rad, p.aspect, p.near, f, clip=self.clip)
        None => @tmath.perspective_infinite_reverse_rh(p.fov_y_rad, p.aspect, p.near, clip=self.clip)
      }
    Orthographic(o) =>
      @tmath.orthographic_rh(o.left, o.right, o.bottom, o.top, o.near, o.far, clip=self.clip)
  }
}

///|
pub fn Camera::view_matrix(_self : Camera, world : @tmath.Affine3) -> @tmath.Mat4? {
  match world.inverse() {
    Some(inv) => Some(inv.to_mat4())
    None => None
  }
}

///|
pub fn Camera::view_proj(self : Camera, world : @tmath.Affine3) -> @tmath.Mat4? {
  match self.view_matrix(world) {
    Some(v) => Some(self.projection_matrix() * v)
    None => None
  }
}

///|
/// Ray through a normalized-device-coordinate point, for picking. Perspective
/// rays start at the eye; orthographic rays start on the near plane along the
/// camera forward axis (-Z).
pub fn Camera::screen_ray(
  self : Camera,
  world : @tmath.Affine3,
  ndc_x : Float,
  ndc_y : Float,
) -> @tmath.Ray? {
  match self.view_proj(world) {
    Some(vp) =>
      match @tmath.invert_view_proj(vp) {
        Some(inv) => {
          let eye = world.translation
          match self.projection {
            Perspective(_) => {
              let p = @tmath.unproject(inv, @tmath.Vec3::new(ndc_x, ndc_y, 0.5))
              Some(@tmath.Ray::new_normalized(eye, p - eye))
            }
            Orthographic(_) => {
              let p = @tmath.unproject(inv, @tmath.Vec3::new(ndc_x, ndc_y, 0.5))
              let forward = -world.matrix3.z_axis.normalize()
              Some(@tmath.Ray::new_normalized(p, forward))
            }
          }
        }
        None => None
      }
    None => None
  }
}

///|
/// Rotation-only matrix that reconstructs a world-space view direction from
/// an NDC direction (skybox). Equivalent to the hand-derived `invRotProj` in
/// `examples/49-rhi-pbr-showcase`; scaled camera nodes are normalized first.
pub fn Camera::sky_ray_matrix(self : Camera, world : @tmath.Affine3) -> @tmath.Mat3? {
  let proj = self.projection_matrix()
  match proj.to_mat3().inverse() {
    Some(pinv) => {
      let m = world.matrix3
      Some(
        @tmath.Mat3::from_cols(
          m.x_axis.normalize(),
          m.y_axis.normalize(),
          m.z_axis.normalize(),
        ) * pinv,
      )
    }
    None => None
  }
}

///|
/// Convenience for window resize: returns a copy with a new aspect ratio.
pub fn Camera::with_aspect(self : Camera, aspect : Float) -> Camera {
  match self.projection {
    Perspective(p) => {
      projection: Projection::Perspective({ ..p, aspect }),
      clip: self.clip,
    }
    Orthographic(_) => self
  }
}
