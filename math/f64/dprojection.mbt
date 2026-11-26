// Double-precision view / projection construction.
//
// Build large-world cameras and shadow frusta here, then down-cast once with
// `to_mat4()` right before uploading to the GPU. The clip-space contract is
// identical to the parent package: `@tmath.ClipSpace::{Vulkan, ZeroToOne,
// NegOneToOne}`.

///|
fn dclip_y_sign(clip : @tmath.ClipSpace) -> Double {
  if clip.is_y_down() {
    -1.0
  } else {
    1.0
  }
}

///|
pub fn dlook_to_rh(eye : DVec3, dir : DVec3, up : DVec3) -> DMat4 {
  let f = match dir.try_normalize() {
    Some(f) => f
    None => return DMat4::identity()
  }
  let right = match f.cross(up).try_normalize() {
    Some(r) => r
    None => {
      let axis = if f.x.abs() < 0.5 { DVec3::unit_x() } else { DVec3::unit_y() }
      (axis - f.scale(axis.dot(f))).normalize()
    }
  }
  let u = right.cross(f)
  {
    x_axis: DVec4::new(right.x, u.x, -f.x, 0.0),
    y_axis: DVec4::new(right.y, u.y, -f.y, 0.0),
    z_axis: DVec4::new(right.z, u.z, -f.z, 0.0),
    w_axis: DVec4::new(-right.dot(eye), -u.dot(eye), f.dot(eye), 1.0),
  }
}

///|
pub fn dlook_at_rh(eye : DVec3, target : DVec3, up : DVec3) -> DMat4 {
  dlook_to_rh(eye, target - eye, up)
}

///|
pub fn dlook_to_lh(eye : DVec3, dir : DVec3, up : DVec3) -> DMat4 {
  let f = match dir.try_normalize() {
    Some(f) => f
    None => return DMat4::identity()
  }
  let right = match up.cross(f).try_normalize() {
    Some(r) => r
    None => {
      let axis = if f.x.abs() < 0.5 { DVec3::unit_x() } else { DVec3::unit_y() }
      (axis - f.scale(axis.dot(f))).normalize()
    }
  }
  let u = f.cross(right)
  {
    x_axis: DVec4::new(right.x, u.x, f.x, 0.0),
    y_axis: DVec4::new(right.y, u.y, f.y, 0.0),
    z_axis: DVec4::new(right.z, u.z, f.z, 0.0),
    w_axis: DVec4::new(-right.dot(eye), -u.dot(eye), -f.dot(eye), 1.0),
  }
}

///|
pub fn dlook_at_lh(eye : DVec3, target : DVec3, up : DVec3) -> DMat4 {
  dlook_to_lh(eye, target - eye, up)
}

///|
fn dperspective_impl(
  fov_y_rad : Double,
  aspect : Double,
  z_near : Double,
  z_far : Double,
  clip : @tmath.ClipSpace,
  reversed : Bool,
  infinite : Bool,
  left_handed : Bool,
) -> DMat4 {
  let f = 1.0 / @math.tan(fov_y_rad * 0.5)
  let ys = dclip_y_sign(clip)
  let zero_to_one = clip.depth_zero_to_one()
  let d = z_far - z_near
  let (m22, m32) : (Double, Double) = if zero_to_one {
    if reversed {
      if infinite {
        (0.0, z_near)
      } else {
        (z_near / d, z_near * z_far / d)
      }
    } else if infinite {
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
    (-1.0, -2.0 * z_near)
  } else {
    (-(z_far + z_near) / d, -2.0 * z_near * z_far / d)
  }
  let w_sign : Double = if left_handed { 1.0 } else { -1.0 }
  let depth_z : Double = if left_handed { -m22 } else { m22 }
  {
    x_axis: DVec4::new(f / aspect, 0.0, 0.0, 0.0),
    y_axis: DVec4::new(0.0, f * ys, 0.0, 0.0),
    z_axis: DVec4::new(0.0, 0.0, depth_z, w_sign),
    w_axis: DVec4::new(0.0, 0.0, m32, 0.0),
  }
}

///|
pub fn dperspective_rh(
  fov_y_rad : Double,
  aspect : Double,
  z_near : Double,
  z_far : Double,
  clip? : @tmath.ClipSpace = @tmath.ClipSpace::Vulkan,
) -> DMat4 {
  dperspective_impl(fov_y_rad, aspect, z_near, z_far, clip, false, false, false)
}

///|
pub fn dperspective_lh(
  fov_y_rad : Double,
  aspect : Double,
  z_near : Double,
  z_far : Double,
  clip? : @tmath.ClipSpace = @tmath.ClipSpace::Vulkan,
) -> DMat4 {
  dperspective_impl(fov_y_rad, aspect, z_near, z_far, clip, false, false, true)
}

///|
pub fn dperspective_rh_reverse(
  fov_y_rad : Double,
  aspect : Double,
  z_near : Double,
  z_far : Double,
  clip? : @tmath.ClipSpace = @tmath.ClipSpace::Vulkan,
) -> DMat4 {
  dperspective_impl(fov_y_rad, aspect, z_near, z_far, clip, true, false, false)
}

///|
pub fn dperspective_infinite_reverse_rh(
  fov_y_rad : Double,
  aspect : Double,
  z_near : Double,
  clip? : @tmath.ClipSpace = @tmath.ClipSpace::Vulkan,
) -> DMat4 {
  dperspective_impl(fov_y_rad, aspect, z_near, 1.0e30, clip, true, true, false)
}

///|
fn dorthographic_impl(
  left : Double,
  right : Double,
  bottom : Double,
  top : Double,
  z_near : Double,
  z_far : Double,
  clip : @tmath.ClipSpace,
  reversed : Bool,
) -> DMat4 {
  let ys = dclip_y_sign(clip)
  let zero_to_one = clip.depth_zero_to_one()
  let d = z_far - z_near
  let (m22, m32) : (Double, Double) = if zero_to_one {
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
    x_axis: DVec4::new(2.0 / (right - left), 0.0, 0.0, 0.0),
    y_axis: DVec4::new(0.0, ys * 2.0 / (top - bottom), 0.0, 0.0),
    z_axis: DVec4::new(0.0, 0.0, m22, 0.0),
    w_axis: DVec4::new(
      -(right + left) / (right - left),
      -(top + bottom) / (top - bottom),
      m32,
      1.0,
    ),
  }
}

///|
pub fn dorthographic_rh(
  left : Double,
  right : Double,
  bottom : Double,
  top : Double,
  z_near : Double,
  z_far : Double,
  clip? : @tmath.ClipSpace = @tmath.ClipSpace::Vulkan,
) -> DMat4 {
  dorthographic_impl(left, right, bottom, top, z_near, z_far, clip, false)
}

///|
pub fn dorthographic_rh_reverse(
  left : Double,
  right : Double,
  bottom : Double,
  top : Double,
  z_near : Double,
  z_far : Double,
  clip? : @tmath.ClipSpace = @tmath.ClipSpace::Vulkan,
) -> DMat4 {
  dorthographic_impl(left, right, bottom, top, z_near, z_far, clip, true)
}

///|
/// Project with the perspective divide in double precision.
pub fn dproject(view_proj : DMat4, world : DVec3) -> DVec3 {
  view_proj.project_point3(world)
}

///|
/// Inverse of `dproject`.
pub fn dunproject(view_proj_inverse : DMat4, ndc : DVec3) -> DVec3 {
  view_proj_inverse.project_point3(ndc)
}
