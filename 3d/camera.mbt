// Camera component: projection parameters + clip-space convention.
//
// The node's world `Affine3` supplies the view transform. Every projection is
// reversed-Z (infinite far by default), which tycho_3d renders with
// `GreaterEqual` and a zero depth clear.

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
  far? : Float,
  clip? : @tmath.ClipSpace = @tmath.ClipSpace::Vulkan,
) -> Camera {
  {
    projection: Projection::Perspective({ fov_y_rad, aspect, near, far }),
    clip,
  }
}

///|
/// Perspective camera taking the vertical field of view in **degrees**, which
/// is how three.js `PerspectiveCamera` authors it. Composition is left
/// unchanged: the value is converted once, at this boundary.
pub fn Camera::perspective_deg(
  fov_y_deg : Float,
  aspect : Float,
  near? : Float = 0.1,
  far? : Float,
  clip? : @tmath.ClipSpace = @tmath.ClipSpace::Vulkan,
) -> Camera {
  Camera::perspective(@tmath.deg_to_rad(fov_y_deg), aspect, near~, far?=far, clip~)
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
        Some(f) => @tmath.perspective_rh_reverse(p.fov_y_rad, p.aspect, p.near, f, clip=self.clip)
        None => @tmath.perspective_infinite_reverse_rh(p.fov_y_rad, p.aspect, p.near, clip=self.clip)
      }
    Orthographic(o) =>
      @tmath.orthographic_rh_reverse(o.left, o.right, o.bottom, o.top, o.near, o.far, clip=self.clip)
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
/// an NDC direction (skybox). Built analytically from the FOV instead of
/// inverting `mat3(proj)`, because the infinite reversed-Z projection has a
/// zero `m22` and is therefore singular in 3x3. Equivalent to the hand-derived
/// `invRotProj` in `examples/rhi/pbr-showcase`; scaled camera nodes are
/// normalized first.
pub fn Camera::sky_ray_matrix(self : Camera, world : @tmath.Affine3) -> @tmath.Mat3? {
  match self.projection {
    Perspective(p) => {
      let focal : Float = 1.0 / @tmath.tan(p.fov_y_rad * 0.5)
      let y_sign : Float = if self.clip.is_y_down() { -1.0 } else { 1.0 }
      let sx : Float = p.aspect / focal
      let sy : Float = y_sign / focal
      let m = world.matrix3
      Some(
        @tmath.Mat3::from_cols(
          m.x_axis.normalize(),
          m.y_axis.normalize(),
          m.z_axis.normalize(),
        ) * @tmath.Mat3::from_diagonal(@tmath.Vec3::new(sx, sy, -1.0)),
      )
    }
    Orthographic(_) => Some(@tmath.Mat3::identity())
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

///|
/// Resize helper taking the viewport in pixels: aspect is recomputed from
/// `width / height`; non-positive sizes are ignored.
pub fn Camera::with_viewport(
  self : Camera,
  width : Float,
  height : Float,
) -> Camera {
  if width <= 0.0 || height <= 0.0 {
    self
  } else {
    self.with_aspect(width / height)
  }
}

///|
/// Vertical field of view in radians; `0` for an orthographic camera.
pub fn Camera::fov_y(self : Camera) -> Float {
  match self.projection {
    Perspective(p) => p.fov_y_rad
    Orthographic(_) => 0.0
  }
}

///|
/// Viewport aspect ratio (width / height); `0` for an orthographic camera.
pub fn Camera::aspect(self : Camera) -> Float {
  match self.projection {
    Perspective(p) => p.aspect
    Orthographic(_) => 0.0
  }
}

///|
/// Near plane distance.
pub fn Camera::near(self : Camera) -> Float {
  match self.projection {
    Perspective(p) => p.near
    Orthographic(o) => o.near
  }
}

///|
/// Far plane distance; `None` for an infinite reversed-Z perspective camera.
pub fn Camera::far(self : Camera) -> Float? {
  match self.projection {
    Perspective(p) => p.far
    Orthographic(o) => Some(o.far)
  }
}

///|
/// `true` for an orthographic projection.
pub fn Camera::is_orthographic(self : Camera) -> Bool {
  match self.projection {
    Orthographic(_) => true
    Perspective(_) => false
  }
}

///|
/// Ray through a pixel coordinate, with the conventional top-left window
/// origin that pointer events report (three.js `Raycaster.setFromCamera`
/// after `setFromWindow`). `width` / `height` are the viewport size in pixels.
///
/// The NDC mapping honours the camera's `ClipSpace`, so a Vulkan (y-down NDC)
/// camera and a Metal/WebGPU (y-up NDC) camera both put the top-left pixel at
/// the top-left of the image.
pub fn Camera::screen_ray_pixels(
  self : Camera,
  world : @tmath.Affine3,
  x : Float,
  y : Float,
  width : Float,
  height : Float,
) -> @tmath.Ray? {
  if width <= 0.0 || height <= 0.0 {
    return None
  }
  let ndc_x = (2.0 : Float) * x / width - 1.0
  let ndc_y = (2.0 : Float) * y / height - 1.0
  let ndc_y = if self.clip.is_y_down() { ndc_y } else { -ndc_y }
  self.screen_ray(world, ndc_x, ndc_y)
}
