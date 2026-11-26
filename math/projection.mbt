// View and projection matrices, with the clip-space convention made explicit.
//
// There is deliberately no global "current coordinate system" state: every
// projection takes a `ClipSpace` argument (default `Vulkan`, matching the
// laplaceliu/tycho Vulkan backend), so `tycho_metal` / `tycho_dx12` users can
// opt into `ZeroToOne` and OpenGL users into `NegOneToOne` without macros.

///|
/// Clip-space depth and Y conventions of the target graphics API.
///
/// | variant | NDC Y | NDC Z |
/// |---|---|---|
/// | `Vulkan` | down (`m11 < 0`) | `[0, 1]` |
/// | `ZeroToOne` (Metal / DX12 / WebGPU) | up (`m11 > 0`) | `[0, 1]` |
/// | `NegOneToOne` (OpenGL) | up (`m11 > 0`) | `[-1, 1]` |
#derive(Eq, Debug)
pub(all) enum ClipSpace {
  Vulkan
  ZeroToOne
  NegOneToOne
}

///|
pub fn ClipSpace::is_y_down(self : ClipSpace) -> Bool {
  match self {
    Vulkan => true
    _ => false
  }
}

///|
/// `true` when NDC depth spans `[0, 1]` (Vulkan / Metal / DX12 / WebGPU).
pub fn ClipSpace::depth_zero_to_one(self : ClipSpace) -> Bool {
  match self {
    NegOneToOne => false
    _ => true
  }
}

///|
fn clip_y_sign(clip : ClipSpace) -> Float {
  if clip.is_y_down() {
    -1.0
  } else {
    1.0
  }
}

///|
/// Right-handed view matrix looking from `eye` along `dir`.
/// `dir` does not need to be normalized; a zero `dir` yields identity.
pub fn look_to_rh(eye : Vec3, dir : Vec3, up : Vec3) -> Mat4 {
  let f = match dir.try_normalize() {
    Some(f) => f
    None => return Mat4::identity()
  }
  // Right vector: `f x up`, fall back to a stable axis when degenerate.
  let right = match f.cross(up).try_normalize() {
    Some(r) => r
    None => f.any_orthonormal()
  }
  let u = right.cross(f)
  {
    x_axis: { x: right.x, y: u.x, z: -f.x, w: 0.0 },
    y_axis: { x: right.y, y: u.y, z: -f.y, w: 0.0 },
    z_axis: { x: right.z, y: u.z, z: -f.z, w: 0.0 },
    w_axis: {
      x: -right.dot(eye),
      y: -u.dot(eye),
      z: f.dot(eye),
      w: 1.0,
    },
  }
}

///|
/// Right-handed view matrix looking at `target`.
pub fn look_at_rh(eye : Vec3, target : Vec3, up : Vec3) -> Mat4 {
  look_to_rh(eye, target - eye, up)
}

///|
/// Left-handed view matrix looking from `eye` along `dir` (`+Z` forward).
pub fn look_to_lh(eye : Vec3, dir : Vec3, up : Vec3) -> Mat4 {
  let f = match dir.try_normalize() {
    Some(f) => f
    None => return Mat4::identity()
  }
  let right = match up.cross(f).try_normalize() {
    Some(r) => r
    None => f.any_orthonormal()
  }
  let u = f.cross(right)
  {
    x_axis: { x: right.x, y: u.x, z: f.x, w: 0.0 },
    y_axis: { x: right.y, y: u.y, z: f.y, w: 0.0 },
    z_axis: { x: right.z, y: u.z, z: f.z, w: 0.0 },
    w_axis: {
      x: -right.dot(eye),
      y: -u.dot(eye),
      z: -f.dot(eye),
      w: 1.0,
    },
  }
}

///|
/// Left-handed view matrix looking at `target`.
pub fn look_at_lh(eye : Vec3, target : Vec3, up : Vec3) -> Mat4 {
  look_to_lh(eye, target - eye, up)
}

///|
fn perspective_impl(
  fov_y_rad : Float,
  aspect : Float,
  z_near : Float,
  z_far : Float,
  clip : ClipSpace,
  reversed : Bool,
  infinite : Bool,
  left_handed : Bool,
) -> Mat4 {
  let f : Float = 1.0 / tan(fov_y_rad * 0.5)
  let ys = clip_y_sign(clip)
  let zero_to_one = clip.depth_zero_to_one()
  let d = z_far - z_near
  let (m22, m32) : (Float, Float) = if zero_to_one {
    if reversed {
      if infinite {
        (0.0, z_near)
      } else {
        (z_near / d, z_near * z_far / d)
      }
    } else if infinite {
      // Near maps to 0, infinity to 1.
      (-1.0, -z_near)
    } else {
      (-z_far / d, -z_near * z_far / d)
    }
  } else if reversed {
    if infinite {
      (1.0, 2.0 * z_near)
    } else {
      ((z_far + z_near) / d, 2.0 * z_near * z_far / d)
    }
  } else if infinite {
    // Near maps to -1, infinity to +1.
    (-1.0, -2.0 * z_near)
  } else {
    (-(z_far + z_near) / d, -2.0 * z_near * z_far / d)
  }
  // Left-handed projections use `w = +z`; the depth axis flips sign.
  let w_sign : Float = if left_handed { 1.0 } else { -1.0 }
  let depth_z : Float = if left_handed { -m22 } else { m22 }
  {
    x_axis: { x: f / aspect, y: 0.0, z: 0.0, w: 0.0 },
    y_axis: { x: 0.0, y: f * ys, z: 0.0, w: 0.0 },
    z_axis: { x: 0.0, y: 0.0, z: depth_z, w: w_sign },
    w_axis: { x: 0.0, y: 0.0, z: m32, w: 0.0 },
  }
}

///|
/// Right-handed perspective projection. `z_near` / `z_far` are positive
/// distances along `-Z`.
pub fn perspective_rh(
  fov_y_rad : Float,
  aspect : Float,
  z_near : Float,
  z_far : Float,
  clip? : ClipSpace = ClipSpace::Vulkan,
) -> Mat4 {
  perspective_impl(fov_y_rad, aspect, z_near, z_far, clip, false, false, false)
}

///|
/// Left-handed perspective projection (`+Z` forward).
pub fn perspective_lh(
  fov_y_rad : Float,
  aspect : Float,
  z_near : Float,
  z_far : Float,
  clip? : ClipSpace = ClipSpace::Vulkan,
) -> Mat4 {
  perspective_impl(fov_y_rad, aspect, z_near, z_far, clip, false, false, true)
}

///|
/// Reversed-Z right-handed perspective: near plane maps to `1`, far plane to
/// `0`. Solves depth-precision banding in large scenes.
pub fn perspective_rh_reverse(
  fov_y_rad : Float,
  aspect : Float,
  z_near : Float,
  z_far : Float,
  clip? : ClipSpace = ClipSpace::Vulkan,
) -> Mat4 {
  perspective_impl(fov_y_rad, aspect, z_near, z_far, clip, true, false, false)
}

///|
/// Infinite-far-plane reversed-Z right-handed perspective. `z_near` maps to
/// `1` and the far plane to `0` (or `-1` for `NegOneToOne`).
pub fn perspective_infinite_reverse_rh(
  fov_y_rad : Float,
  aspect : Float,
  z_near : Float,
  clip? : ClipSpace = ClipSpace::Vulkan,
) -> Mat4 {
  perspective_impl(fov_y_rad, aspect, z_near, 1.0e30, clip, true, true, false)
}

///|
/// Right-handed orthographic projection.
pub fn orthographic_rh(
  left : Float,
  right : Float,
  bottom : Float,
  top : Float,
  z_near : Float,
  z_far : Float,
  clip? : ClipSpace = ClipSpace::Vulkan,
) -> Mat4 {
  orthographic_impl(left, right, bottom, top, z_near, z_far, clip, false)
}

///|
/// Reversed-Z right-handed orthographic projection (near maps to `1`).
pub fn orthographic_rh_reverse(
  left : Float,
  right : Float,
  bottom : Float,
  top : Float,
  z_near : Float,
  z_far : Float,
  clip? : ClipSpace = ClipSpace::Vulkan,
) -> Mat4 {
  orthographic_impl(left, right, bottom, top, z_near, z_far, clip, true)
}

///|
/// Left-handed orthographic projection.
pub fn orthographic_lh(
  left : Float,
  right : Float,
  bottom : Float,
  top : Float,
  z_near : Float,
  z_far : Float,
  clip? : ClipSpace = ClipSpace::Vulkan,
) -> Mat4 {
  let m = orthographic_impl(left, right, bottom, top, z_near, z_far, clip, false)
  // LH keeps the same XY mapping; the depth axis is positive in eye space.
  { ..m, z_axis: { ..m.z_axis, z: -m.z_axis.z } }
}

///|
fn orthographic_impl(
  left : Float,
  right : Float,
  bottom : Float,
  top : Float,
  z_near : Float,
  z_far : Float,
  clip : ClipSpace,
  reversed : Bool,
) -> Mat4 {
  let ys = clip_y_sign(clip)
  let zero_to_one = clip.depth_zero_to_one()
  let d = z_far - z_near
  let (m22, m32) : (Float, Float) = if zero_to_one {
    if reversed {
      (1.0 / d, z_far / d)
    } else {
      (-1.0 / d, -z_near / d)
    }
  } else if reversed {
    (2.0 / d, (z_near + z_far) / d)
  } else {
    (-2.0 / d, -(z_near + z_far) / d)
  }
  {
    x_axis: { x: (2.0 : Float) / (right - left), y: 0.0, z: 0.0, w: 0.0 },
    y_axis: { x: 0.0, y: ys * (2.0 : Float) / (top - bottom), z: 0.0, w: 0.0 },
    z_axis: { x: 0.0, y: 0.0, z: m22, w: 0.0 },
    w_axis: {
      x: -(right + left) / (right - left),
      y: -(top + bottom) / (top - bottom),
      z: m32,
      w: 1.0,
    },
  }
}

///|
/// Transform a world-space point by `view_proj` and perform the perspective
/// divide, returning normalized device coordinates.
pub fn project(view_proj : Mat4, world : Vec3) -> Vec3 {
  view_proj.project_point3(world)
}

///|
/// Inverse of `project`: `ndc` is in the device range produced by the
/// projection matrix that was used to build `view_proj_inverse`.
pub fn unproject(view_proj_inverse : Mat4, ndc : Vec3) -> Vec3 {
  view_proj_inverse.project_point3(ndc)
}

///|
/// Build an inverse view-projection matrix, or `None` when singular.
pub fn invert_view_proj(view_proj : Mat4) -> Mat4? {
  view_proj.inverse()
}
