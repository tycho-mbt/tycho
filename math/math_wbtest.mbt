// Algebraic invariant tests for laplaceliu/tycho_math.
//
// These are the contracts named in the design doc: M * M^-1 ~= I, quaternion
// and rotation-matrix equivalence, clip-space boundary values for all three
// conventions, and no NaN leaking out of zero-vector / singular-matrix input.

///|
fn close(a : Float, b : Float, eps? : Float = 1.0e-5) -> Bool {
  approx_eq_f(a, b, eps~)
}

///|
fn need(cond : Bool, what : StringView) -> Unit raise {
  if !cond {
    fail(what)
  }
}

///|
fn need_vec3(a : Vec3, b : Vec3, eps? : Float = 1.0e-5) -> Unit raise {
  if !a.approx_eq(b, eps~) {
    fail("Vec3 mismatch")
  }
}

///|
fn need_mat4(a : Mat4, b : Mat4, eps? : Float = 1.0e-4) -> Unit raise {
  if !a.approx_eq(b, eps~) {
    fail("Mat4 mismatch")
  }
}

///|
test "scalar helpers" {
  need(close(clamp_f(5.0, 0.0, 1.0), 1.0), "clamp hi")
  need(close(clamp_f(-1.0, 0.0, 1.0), 0.0), "clamp lo")
  need(close(clamp_f(0.5, 0.0, 1.0), 0.5), "clamp mid")
  need(close(clamp_f(0.5, 1.0, 0.0), 0.5), "clamp swapped bounds")
  need(close(saturate(2.0), 1.0), "saturate")
  need(close(lerp_f(0.0, 10.0, 0.25), 2.5), "lerp")
  need(close(inv_lerp_f(0.0, 10.0, 2.5), 0.25), "inv_lerp")
  need(close(inv_lerp_f(3.0, 3.0, 7.0), 0.0), "inv_lerp degenerate")
  need(close(smoothstep(0.0, 1.0, 0.5), 0.5), "smoothstep mid")
  need(close(smoothstep(0.0, 1.0, -3.0), 0.0), "smoothstep lo")
  need(close(deg_to_rad(180.0), PI), "deg_to_rad")
  need(close(rad_to_deg(PI), 180.0), "rad_to_deg")
  need(close(fract(2.75), 0.75), "fract")
  need(close(sign_f(-9.0), -1.0), "sign")
  need(!(approx_eq_f(0.0, 0.5)), "approx_eq rejects")
  let (s, c) = sin_cos(FRAC_PI_2)
  need(close(s, 1.0), "sin_cos sin")
  need(close(c, 0.0), "sin_cos cos")
}

///|
test "vec3 algebra" {
  let a = Vec3::new(1.0, 2.0, 3.0)
  let b = Vec3::new(-4.0, 5.0, 6.0)
  need(close(a.dot(b), 24.0), "dot")
  need_vec3(a + b, Vec3::new(-3.0, 7.0, 9.0))
  need_vec3(a - b, Vec3::new(5.0, -3.0, -3.0))
  need_vec3(a * Vec3::new(2.0, 0.0, 1.0), Vec3::new(2.0, 0.0, 3.0), eps=1.0e-6)
  need_vec3(-a, Vec3::new(-1.0, -2.0, -3.0))
  // cross is perpendicular to both inputs and follows the right-hand rule.
  let c = Vec3::unit_x().cross(Vec3::unit_y())
  need_vec3(c, Vec3::unit_z())
  let ab = a.cross(b)
  need(close(ab.dot(a), 0.0, eps=1.0e-5), "cross perpendicular to a")
  need(close(ab.dot(b), 0.0, eps=1.0e-5), "cross perpendicular to b")
  need(close(Vec3::new(3.0, 4.0, 0.0).length(), 5.0), "length")
  // Normalizing a zero vector must not produce NaN.
  let z = Vec3::zero().normalize()
  need_vec3(z, Vec3::zero())
  need(z.is_finite(), "zero normalize finite")
  need(Vec3::zero().try_normalize() is None, "try_normalize none")
  need(close(Vec3::new(2.0, 0.0, 0.0).normalize().x, 1.0), "try_normalize unit")
  // reflect: 45 degree hit on a floor normal.
  let r = Vec3::new(1.0, -1.0, 0.0).normalize().reflect(Vec3::unit_y())
  need_vec3(r, Vec3::new(0.70710677, 0.70710677, 0.0), eps=1.0e-5)
  // project_onto removes the component along the target axis.
  need_vec3(
    Vec3::new(1.0, 2.0, 3.0).project_onto(Vec3::unit_y()),
    Vec3::new(0.0, 2.0, 0.0),
  )
  // orthonormal helper returns a unit vector perpendicular to the input.
  let n = Vec3::new(0.3, -0.4, 0.5).normalize()
  let t = n.any_orthonormal()
  need(close(t.length(), 1.0), "any_orthonormal unit")
  need(close(t.dot(n), 0.0), "any_orthonormal perpendicular")
}

///|
test "vec2 and vec4" {
  need(close(Vec2::new(3.0, 4.0).length(), 5.0), "vec2 length")
  need(close(Vec2::new(1.0, 0.0).cross(Vec2::new(0.0, 1.0)), 1.0), "vec2 cross")
  let rotated = Vec2::unit_x().rotate(FRAC_PI_2)
  need(rotated.approx_eq(Vec2::new(0.0, 1.0), eps=1.0e-6), "vec2 rotate")
  need(close(Vec4::new(1.0, 2.0, 2.0, 1.0).length(), 3.1622777), "vec4 length")
  need_vec3(Vec4::new(1.0, 2.0, 3.0, 4.0).xyz(), Vec3::new(1.0, 2.0, 3.0))
  need(
    Vec4::new(2.0, 4.0, 6.0, 2.0).perspective_divide().approx_eq(
      Vec4::new(1.0, 2.0, 3.0, 1.0),
      eps=1.0e-6,
    ),
    "perspective divide",
  )
  need_vec3(Vec3::new(1.0, 2.0, 3.0).extend_w(9.0).xyz(), Vec3::new(1.0, 2.0, 3.0))
}

///|
test "integer vectors" {
  need(IVec3::new(1, 2, 3) + IVec3::new(1, 1, 1) == IVec3::new(2, 3, 4), "ivec3 add")
  need(IVec2::splat(3) * IVec2::splat(2) == IVec2::splat(6), "ivec2 mul")
  need(IVec2::new(3, 4).length_sq() == 25, "ivec2 length_sq")
  need(UVec2::new((7 : UInt), (8 : UInt)).to_vec2().approx_eq(Vec2::new(7.0, 8.0)), "uvec2 to vec2")
  need(
    UVec4::from_vec4_rgba8(Vec4::new(1.0, 0.5, 0.0, 1.0)) == UVec4::new((255 : UInt), (128 : UInt), (0 : UInt), (255 : UInt)),
    "rgba8 pack",
  )
}

///|
test "quat basics and matrix equivalence" {
  need(Quat::identity().mul_vec3(Vec3::new(1.0, 2.0, 3.0)).approx_eq(Vec3::new(1.0, 2.0, 3.0)), "identity")
  let q = Quat::from_axis_angle(Vec3::unit_z(), FRAC_PI_2)
  need_vec3(q.mul_vec3(Vec3::unit_x()), Vec3::unit_y(), eps=1.0e-6)
  // Quaternion and its matrix rotate identically.
  let m = q.to_mat3()
  let v = Vec3::new(0.3, -0.7, 1.1)
  need_vec3(q.mul_vec3(v), m.mul_vec3(v))
  // Matrix -> quaternion -> matrix round trip.
  let back = Quat::from_mat3(m)
  need(back.approx_eq(q), "from_mat3 round trip")
  need(q.mul_vec3(Vec3::unit_x()).approx_eq(back.mul_vec3(Vec3::unit_x()), eps=1.0e-5), "quat equiv")
  // Conjugate undoes the rotation.
  need_vec3(q.conjugate().mul_vec3(q.mul_vec3(v)), v)
  // Composition order: q1 * q2 applies q2 first.
  let qx = Quat::from_rotation_x(0.4)
  let qy = Quat::from_rotation_y(-0.9)
  need_vec3((qx * qy).mul_vec3(v), qx.mul_vec3(qy.mul_vec3(v)))
  need(Quat::identity().is_normalized(), "identity normalized")
  // Rotation from one unit axis to another.
  let arc = Quat::from_rotation_arc(Vec3::unit_x(), Vec3::unit_y())
  need_vec3(arc.mul_vec3(Vec3::unit_x()), Vec3::unit_y(), eps=1.0e-5)
  // Opposite vectors must not produce NaN.
  let flip = Quat::from_rotation_arc(Vec3::unit_x(), Vec3::neg_x())
  need(flip.is_normalized(), "flip normalized")
  need_vec3(flip.mul_vec3(Vec3::unit_x()), Vec3::neg_x(), eps=1.0e-5)
  // Euler construction agrees with composed per-axis quaternions.
  let e = Quat::from_euler(EulerOrder::XYZ, 0.2, 0.4, 0.6)
  let manual = Quat::from_rotation_x(0.2) * Quat::from_rotation_y(0.4) * Quat::from_rotation_z(0.6)
  need(e.approx_eq(manual), "from_euler XYZ")
}

///|
test "quat interpolation" {
  let a = Quat::from_rotation_z(0.0)
  let b = Quat::from_rotation_z(FRAC_PI_2)
  need(a.slerp(b, 0.0).approx_eq(a), "slerp t=0")
  need(a.slerp(b, 1.0).approx_eq(b), "slerp t=1")
  let half = a.slerp(b, 0.5)
  need(half.approx_eq(Quat::from_rotation_z(FRAC_PI_4)), "slerp midpoint")
  // Shortest arc: going the other way around is the same endpoint.
  let c = Quat::from_rotation_z(FRAC_PI_2 + TAU)
  need(a.slerp(c, 0.5).approx_eq(Quat::from_rotation_z(FRAC_PI_4)), "slerp shortest arc")
  need(a.nlerp(b, 0.0).approx_eq(a), "nlerp t=0")
  need(a.nlerp(b, 1.0).approx_eq(b), "nlerp t=1")
  // slerp between nearly identical quaternions stays finite.
  let near = a.slerp(a, 0.5)
  need(near.is_normalized(), "slerp identical normalized")
}

///|
test "mat4 core" {
  let m = Mat4::identity()
  need_mat4(m * m, m)
  need(mat4_det(m) == 1.0, "identity determinant")
  let s = Mat4::from_scale(Vec3::new(2.0, 3.0, 4.0))
  need(close(s.determinant(), 24.0, eps=1.0e-4), "scale determinant")
  need_vec3(s.transform_point3(Vec3::new(1.0, 1.0, 1.0)), Vec3::new(2.0, 3.0, 4.0))
  // Translation only affects points, not directions.
  let t = Mat4::from_translation(Vec3::new(5.0, -1.0, 2.0))
  need_vec3(t.transform_point3(Vec3::zero()), Vec3::new(5.0, -1.0, 2.0))
  need_vec3(t.transform_vector3(Vec3::unit_x()), Vec3::unit_x())
  // Transpose twice is identity.
  let r = Mat4::from_quat(Quat::from_axis_angle(Vec3::new(1.0, 2.0, 3.0), 0.8))
  need_mat4(r.transpose().transpose(), r)
  // Column-major memory layout: column 0 comes first.
  let arr = Mat4::from_translation(Vec3::new(7.0, 8.0, 9.0)).to_cols_array()
  need(close(arr[12], 7.0) && close(arr[13], 8.0) && close(arr[14], 9.0) && close(arr[15], 1.0), "column-major translation")
  need(close(arr[0], 1.0) && close(arr[5], 1.0) && close(arr[10], 1.0), "column-major diagonal")
}

///|
fn mat4_det(m : Mat4) -> Float {
  m.determinant()
}

///|
test "mat4 inverse and normal matrix" {
  let trs = Mat4::from_scale_rotation_translation(
    Vec3::new(2.0, 0.5, 3.0),
    Quat::from_euler(EulerOrder::YXZ, 0.3, -1.1, 0.7),
    Vec3::new(4.0, -2.0, 1.5),
  )
  match trs.inverse() {
    Some(inv) => {
      need_mat4(trs * inv, Mat4::identity(), eps=1.0e-3)
      need_mat4(inv * trs, Mat4::identity(), eps=1.0e-3)
    }
    None => fail("TRS matrix must be invertible")
  }
  // Singular matrices return None instead of NaN.
  let singular = Mat4::from_cols(
    Vec4::unit_x(),
    Vec4::unit_x(),
    Vec4::unit_z(),
    Vec4::unit_w(),
  )
  need(singular.inverse() is None, "singular inverse none")
  need(close(singular.determinant(), 0.0, eps=1.0e-6), "singular determinant")
  // Normals under non-uniform scale: n' = transpose(inverse(M3)) * n.
  let nm = match trs.normal_matrix() {
    Some(n) => n
    None => fail("normal matrix must exist")
  }
  let inv3 = match trs.to_mat3().inverse() {
    Some(i) => i
    None => fail("linear part invertible")
  }
  need(nm.approx_eq(inv3.transpose(), eps=1.0e-4), "normal matrix")
  // A plane normal stays perpendicular to the transformed tangent plane.
  let n = Vec3::new(0.0, 1.0, 0.0)
  let tangent = Vec3::new(1.0, 0.0, 0.0)
  let world_tangent = trs.transform_vector3(tangent)
  let world_normal = nm.mul_vec3(n)
  need(close(world_normal.dot(world_tangent), 0.0, eps=1.0e-3), "normal perpendicular")
}

///|
test "mat2 and mat3" {
  let r2 = Mat2::from_angle(FRAC_PI_2)
  need(r2.mul_vec2(Vec2::unit_x()).approx_eq(Vec2::unit_y(), eps=1.0e-6), "mat2 rotate")
  need(close(r2.determinant(), 1.0, eps=1.0e-6), "mat2 det")
  need(r2.mul_vec2(r2.inverse().unwrap().mul_vec2(Vec2::unit_y())).approx_eq(Vec2::unit_y(), eps=1.0e-6), "mat2 inverse")
  let r3 = Mat3::from_rotation_y(FRAC_PI_2)
  need_vec3(r3.mul_vec3(Vec3::unit_x()), Vec3::new(0.0, 0.0, -1.0), eps=1.0e-6)
  need(close(r3.determinant(), 1.0, eps=1.0e-6), "mat3 det")
  let inv = r3.inverse().unwrap()
  need(r3.mul_vec3(inv.mul_vec3(Vec3::new(1.0, 2.0, 3.0))).approx_eq(Vec3::new(1.0, 2.0, 3.0), eps=1.0e-5), "mat3 inverse")
  need(Mat3::identity().inverse().unwrap().approx_eq(Mat3::identity()), "mat3 identity inverse")
}

///|
test "affine2" {
  let a = Affine2::from_scale_angle_translation(
    Vec2::new(2.0, 3.0),
    FRAC_PI_2,
    Vec2::new(10.0, -4.0),
  )
  // scale, then rotate 90 deg, then translate.
  let p = a.transform_point2(Vec2::new(1.0, 0.0))
  need(p.approx_eq(Vec2::new(10.0, -2.0), eps=1.0e-5), "affine2 point")
  // Composing matches applying twice.
  let b = Affine2::from_translation(Vec2::new(1.0, 2.0))
  let composed = b * a
  need(
    composed.transform_point2(Vec2::new(1.0, 0.0)).approx_eq(
      b.transform_point2(a.transform_point2(Vec2::new(1.0, 0.0))),
      eps=1.0e-5,
    ),
    "affine2 composition",
  )
  // Inverse round trip.
  let inv = a.inverse().unwrap()
  need(
    inv.transform_point2(p).approx_eq(Vec2::new(1.0, 0.0), eps=1.0e-5),
    "affine2 inverse",
  )
  // to_mat4 must agree with the 2D path.
  need_vec3(
    a.to_mat4().transform_point3(Vec3::new(1.0, 0.0, 0.0)),
    a.transform_point2(Vec2::new(1.0, 0.0)).extend_z(0.0),
  )
  need(Affine2::from_translation(Vec2::new(3.0, 4.0)).is_pure_translation(), "pure translation")
  need(Affine2::from_translation(Vec2::new(3.0, 4.0)).is_axis_aligned(), "axis aligned")
  need(!(a.is_axis_aligned()), "rotated not axis aligned")
  // Singular affine returns None.
  need(Affine2::from_scale(Vec2::new(0.0, 1.0)).inverse() is None, "affine2 singular")
}

///|
test "affine3 and vk transform" {
  let a = Affine3::from_scale_rotation_translation(
    Vec3::new(1.0, 2.0, 3.0),
    Quat::from_rotation_z(FRAC_PI_2),
    Vec3::new(7.0, 8.0, 9.0),
  )
  // 12 floats, row-major 3x4: last column is the translation.
  let f = a.to_vk_transform_3x4()
  need(f.length() == 12, "3x4 length")
  need(close(f[3], 7.0) && close(f[7], 8.0) && close(f[11], 9.0), "3x4 translation")
  // Row 0 = x_axis.x, y_axis.x, z_axis.x (rotation + scale).
  need(close(f[0], 0.0, eps=1.0e-6), "3x4 row0 col0")
  need(close(f[1], -2.0, eps=1.0e-6), "3x4 row0 col1")
  need(close(f[4], 1.0, eps=1.0e-6), "3x4 row1 col0")
  // to_mat4 agrees with transform_point3.
  let p = Vec3::new(0.5, -1.5, 2.5)
  need_vec3(a.to_mat4().transform_point3(p), a.transform_point3(p), eps=1.0e-4)
  // Inverse round trip.
  let inv = a.inverse().unwrap()
  need_vec3(inv.transform_point3(a.transform_point3(p)), p, eps=1.0e-4)
  // Composition matches matrix composition.
  let b = Affine3::from_translation(Vec3::new(-1.0, 0.0, 4.0))
  need_vec3((a * b).transform_point3(p), a.transform_point3(b.transform_point3(p)), eps=1.0e-4)
}

///|
test "transform trs" {
  let t = Transform::new(
    Vec3::new(3.0, -2.0, 5.0),
    Quat::from_euler(EulerOrder::XYZ, 0.5, -0.25, 1.2),
    Vec3::new(2.0, 2.0, 2.0),
  )
  let p = Vec3::new(1.0, 2.0, -3.0)
  need_vec3(t.transform_point3(p), t.to_mat4().transform_point3(p), eps=1.0e-4)
  // Decompose then recompose reproduces the same matrix.
  let affine = match Transform::from_affine3(t.to_affine3()) {
    Some(x) => x
    None => fail("TRS decomposition must succeed")
  }
  need(affine.approx_eq(t, eps=1.0e-4), "TRS decompose round trip")
  // Inverse undoes the transform.
  let inv = t.inverse().unwrap()
  need_vec3(inv.transform_point3(t.transform_point3(p)), p, eps=1.0e-4)
  // lerp endpoints.
  need(t.lerp(Transform::identity(), 0.0).approx_eq(t), "lerp t=0")
  need(t.lerp(Transform::identity(), 1.0).approx_eq(Transform::identity()), "lerp t=1")
  // Negative scale is represented by a negative axis.
  let mirrored = Transform::from_scale(Vec3::new(1.0, 1.0, -1.0))
  let dec = match Transform::from_mat4(mirrored.to_mat4()) {
    Some(x) => x
    None => fail("mirror decomposition")
  }
  need_vec3(dec.scale, Vec3::new(1.0, 1.0, -1.0), eps=1.0e-5)
}

///|
test "projection clip spaces" {
  let aspect : Float = 1.5
  let near : Float = 0.1
  let far : Float = 100.0
  let fov = deg_to_rad(60.0)
  // Vulkan: Y down, Z in [0, 1].
  let vk = perspective_rh(fov, aspect, near, far, clip=ClipSpace::Vulkan)
  need(close(vk.project_point3(Vec3::new(0.0, 0.0, -near)).z, 0.0), "vk near z")
  need(close(vk.project_point3(Vec3::new(0.0, 0.0, -far)).z, 1.0), "vk far z")
  let y : Float = 0.1
  need(vk.project_point3(Vec3::new(0.0, y, -near)).y < 0.0, "vk y down")
  // ZeroToOne (Metal / DX12): Y up, Z in [0, 1].
  let zo = perspective_rh(fov, aspect, near, far, clip=ClipSpace::ZeroToOne)
  need(close(zo.project_point3(Vec3::new(0.0, 0.0, -near)).z, 0.0), "zo near z")
  need(close(zo.project_point3(Vec3::new(0.0, 0.0, -far)).z, 1.0), "zo far z")
  need(zo.project_point3(Vec3::new(0.0, y, -near)).y > 0.0, "zo y up")
  // NegOneToOne (OpenGL): Z in [-1, 1].
  let gl = perspective_rh(fov, aspect, near, far, clip=ClipSpace::NegOneToOne)
  need(close(gl.project_point3(Vec3::new(0.0, 0.0, -near)).z, -1.0), "gl near z")
  need(close(gl.project_point3(Vec3::new(0.0, 0.0, -far)).z, 1.0), "gl far z")
  // Reversed-Z: near maps to 1, far to 0.
  let rev = perspective_rh_reverse(fov, aspect, near, far, clip=ClipSpace::Vulkan)
  need(close(rev.project_point3(Vec3::new(0.0, 0.0, -near)).z, 1.0), "reverse near z")
  need(close(rev.project_point3(Vec3::new(0.0, 0.0, -far)).z, 0.0), "reverse far z")
  let inf = perspective_infinite_reverse_rh(fov, aspect, near, clip=ClipSpace::Vulkan)
  need(close(inf.project_point3(Vec3::new(0.0, 0.0, -near)).z, 1.0), "infinite reverse near")
  need(close(inf.project_point3(Vec3::new(0.0, 0.0, -1.0e6)).z, 0.0, eps=1.0e-4), "infinite reverse far")
}

///|
test "orthographic and look_at" {
  let o = orthographic_rh(-2.0, 2.0, -1.0, 1.0, 0.1, 10.0, clip=ClipSpace::Vulkan)
  need(o.project_point3(Vec3::new(2.0, 1.0, -0.1)).approx_eq(Vec3::new(1.0, -1.0, 0.0), eps=1.0e-5), "ortho near corner")
  need(o.project_point3(Vec3::new(2.0, 1.0, -10.0)).approx_eq(Vec3::new(1.0, -1.0, 1.0), eps=1.0e-5), "ortho far corner")
  let gl = orthographic_rh(-2.0, 2.0, -1.0, 1.0, 0.1, 10.0, clip=ClipSpace::NegOneToOne)
  need(close(gl.project_point3(Vec3::new(0.0, 0.0, -0.1)).z, -1.0), "ortho gl near")
  need(close(gl.project_point3(Vec3::new(0.0, 0.0, -10.0)).z, 1.0), "ortho gl far")
  let rev = orthographic_rh_reverse(-2.0, 2.0, -1.0, 1.0, 0.1, 10.0, clip=ClipSpace::Vulkan)
  need(close(rev.project_point3(Vec3::new(0.0, 0.0, -0.1)).z, 1.0), "ortho reverse near")
  need(close(rev.project_point3(Vec3::new(0.0, 0.0, -10.0)).z, 0.0), "ortho reverse far")
  // RH view matrix: eye at +Z looking at the origin puts the origin at -Z.
  let view = look_at_rh(Vec3::new(0.0, 0.0, 5.0), Vec3::zero(), Vec3::unit_y())
  need_vec3(view.transform_point3(Vec3::zero()), Vec3::new(0.0, 0.0, -5.0))
  need_vec3(view.transform_point3(Vec3::new(0.0, 0.0, 5.0)), Vec3::zero())
  // LH view matrix: +Z forward.
  let view_lh = look_at_lh(Vec3::new(0.0, 0.0, -5.0), Vec3::zero(), Vec3::unit_y())
  need_vec3(view_lh.transform_point3(Vec3::zero()), Vec3::new(0.0, 0.0, 5.0))
  // Degenerate input does not produce NaN.
  let bad = look_at_rh(Vec3::zero(), Vec3::zero(), Vec3::unit_y())
  need(bad.is_finite(), "degenerate look_at finite")
}

///|
test "project and unproject" {
  let view = look_at_rh(Vec3::new(2.0, 3.0, 6.0), Vec3::zero(), Vec3::unit_y())
  let proj = perspective_rh(deg_to_rad(53.13), 1.7, 0.1, 50.0, clip=ClipSpace::Vulkan)
  let vp = proj * view
  let world = Vec3::new(0.3, -0.4, 0.5)
  let ndc = project(vp, world)
  let inv = invert_view_proj(vp).unwrap()
  need_vec3(unproject(inv, ndc), world, eps=1.0e-2)
}

///|
test "geometry ray and aabb" {
  let box = Aabb3::new(Vec3::splat(-1.0), Vec3::splat(1.0))
  need(box.contains_point(Vec3::zero()), "aabb contains")
  need(close(box.volume(), 8.0), "aabb volume")
  need_vec3(box.center(), Vec3::zero())
  let ray = Ray::new(Vec3::new(0.0, 0.0, 5.0), Vec3::new(0.0, 0.0, -1.0))
  match ray.intersect_aabb(box) {
    Some((t0, t1)) => need(close(t0, 4.0) && close(t1, 6.0), "ray aabb hit")
    None => fail("ray should hit box")
  }
  need(Ray::new(Vec3::new(5.0, 0.0, 5.0), Vec3::new(0.0, 0.0, -1.0)).intersect_aabb(box) is None, "ray aabb miss")
  // Ray/plane.
  let plane = Plane::from_point_normal(Vec3::zero(), Vec3::unit_y())
  need(close(plane.signed_distance(Vec3::new(0.0, 3.0, 0.0)), 3.0), "plane distance")
  match Ray::new(Vec3::new(0.0, 3.0, 0.0), Vec3::new(0.0, -1.0, 0.0)).intersect_plane(plane) {
    Some(t) => need(close(t, 3.0), "ray plane t")
    None => fail("ray should hit plane")
  }
  // Ray/sphere.
  match ray.intersect_sphere(Vec3::zero(), 1.0) {
    Some(t) => need(close(t, 4.0), "ray sphere t")
    None => fail("ray should hit sphere")
  }
  // Ray/triangle (Moller-Trumbore).
  let tri = Ray::new(Vec3::new(0.25, 0.25, 1.0), Vec3::new(0.0, 0.0, -1.0))
  match tri.intersect_triangle(Vec3::zero(), Vec3::unit_x(), Vec3::unit_y()) {
    Some(t) => need(close(t, 1.0), "ray triangle t")
    None => fail("ray should hit triangle")
  }
  need(
    Ray::new(Vec3::new(2.0, 2.0, 1.0), Vec3::new(0.0, 0.0, -1.0)).intersect_triangle(
      Vec3::zero(), Vec3::unit_x(), Vec3::unit_y(),
    ) is None,
    "ray triangle miss",
  )
}

///|
test "geometry aabb transforms and spheres" {
  let box = Aabb3::new(Vec3::new(-1.0, -2.0, -3.0), Vec3::new(1.0, 2.0, 3.0))
  let a = Affine3::from_scale_rotation_translation(
    Vec3::splat(2.0),
    Quat::from_rotation_y(FRAC_PI_2),
    Vec3::new(10.0, 0.0, 0.0),
  )
  let moved = box.transform(a)
  need(moved.contains_point(Vec3::new(10.0, 0.0, 0.0)), "transformed aabb contains center")
  need(moved.contains_aabb(Aabb3::new(Vec3::new(9.0, -1.0, -1.0), Vec3::new(11.0, 1.0, 1.0))), "transformed aabb bounds")
  let s = Sphere::new(Vec3::zero(), 2.0)
  need(s.contains_point(Vec3::new(1.0, 1.0, 0.0)), "sphere contains")
  need(s.intersects_sphere(Sphere::new(Vec3::new(3.0, 0.0, 0.0), 2.0)), "sphere overlap")
  need(s.intersects_aabb(Aabb3::new(Vec3::splat(1.0), Vec3::splat(5.0))), "sphere aabb overlap")
}

///|
test "frustum culling" {
  let view = look_at_rh(Vec3::new(0.0, 0.0, 10.0), Vec3::zero(), Vec3::unit_y())
  let proj = perspective_rh(deg_to_rad(60.0), 1.0, 0.1, 100.0, clip=ClipSpace::Vulkan)
  let frustum = Frustum::from_view_proj(proj * view, clip=ClipSpace::Vulkan)
  need(frustum.planes.length() == 6, "six planes")
  need(frustum.intersects_aabb(Aabb3::new(Vec3::splat(-0.5), Vec3::splat(0.5))), "origin box visible")
  need(frustum.intersects_sphere(Sphere::new(Vec3::zero(), 0.5)), "origin sphere visible")
  need(!(frustum.intersects_aabb(Aabb3::new(Vec3::splat(50.0), Vec3::splat(51.0)))), "far box culled")
  // Behind the camera.
  need(
    !(frustum.intersects_aabb(Aabb3::new(Vec3::new(-1.0, -1.0, 20.0), Vec3::new(1.0, 1.0, 22.0)))),
    "behind camera culled",
  )
  need(frustum.contains_point(Vec3::zero()), "origin inside")
  need(!(frustum.contains_point(Vec3::new(0.0, 0.0, 50.0))), "origin-ish outside")
}

///|
test "gpu pack std140 and std430" {
  // std140 layout: float(1) pad-to-2 vec2(2) pad-to-4 vec3(4) vec4(4) mat4(16).
  let w = GpuPackWriter::std140(64)
  w.push_float(1.0)
  w.push_vec2(Vec2::new(2.0, 3.0))
  w.push_vec3(Vec3::new(4.0, 5.0, 6.0))
  w.push_vec4(Vec4::new(7.0, 8.0, 9.0, 10.0))
  w.push_mat4(Mat4::identity())
  let f = w.as_floats()
  need(f.length() == 28, "std140 total size")
  need(close(f[0], 1.0), "std140 float")
  need(close(f[1], 0.0), "std140 pad before vec2")
  need(close(f[2], 2.0) && close(f[3], 3.0), "std140 vec2")
  need(close(f[4], 4.0) && close(f[5], 5.0) && close(f[6], 6.0), "std140 vec3")
  need(close(f[7], 0.0), "std140 vec3 pad")
  need(close(f[8], 7.0) && close(f[11], 10.0), "std140 vec4")
  need(close(f[12], 1.0) && close(f[15], 0.0), "std140 mat4 col0")
  need(close(f[27], 1.0), "std140 mat4 last")
  // reset reuses the buffer.
  w.reset()
  need(w.length() == 0, "reset")
  // std430 keeps vec3 at 3 floats.
  let s = GpuPackWriter::std430(16)
  s.push_vec3(Vec3::new(1.0, 2.0, 3.0))
  s.push_float(4.0)
  let g = s.as_floats()
  need(g.length() == 4, "std430 vec3 packing")
  need(close(g[2], 3.0) && close(g[3], 4.0), "std430 values")
  // Growing past the initial capacity must preserve data.
  let grow = GpuPackWriter::std430(2)
  for i = 0; i < 8; i = i + 1 {
    grow.push_float(Float::from_double(i.to_double()))
  }
  need(grow.length() == 8, "grow length")
  need(close(grow.as_floats()[7], 7.0), "grow data")
}

///|
test "vk transform 3x4 bytes" {
  let a = Affine3::from_translation(Vec3::new(1.0, 2.0, 3.0))
  let bytes = a.to_vk_transform_3x4_bytes()
  need(bytes.length() == 48, "3x4 byte length")
  // Row-major 3x4: identity basis with the translation in the last column.
  // 1.0f little-endian is 00 00 80 3F, 2.0f is 00 00 00 40, 3.0f is 00 00 40 40.
  need(bytes[2] == (0x80 : Byte) && bytes[3] == (0x3F : Byte), "m00 is 1.0")
  need(bytes[14] == (0x80 : Byte) && bytes[15] == (0x3F : Byte), "tx is 1.0")
  need(bytes[30] == (0x00 : Byte) && bytes[31] == (0x40 : Byte), "ty is 2.0")
  need(bytes[46] == (0x40 : Byte) && bytes[47] == (0x40 : Byte), "tz is 3.0")
  // The byte form must agree with the float form element by element.
  let floats = a.to_vk_transform_3x4()
  let head = bytes[0:4]
  let bits = head[0].to_uint() |
    (head[1].to_uint() << 8) |
    (head[2].to_uint() << 16) |
    (head[3].to_uint() << 24)
  need(Float::reinterpret_from_uint(bits) == floats[0], "byte/float agreement")
}

///|
test "batch kernels" {
  let a : FixedArray[Mat4] = FixedArray::make(3, Mat4::identity())
  let b : FixedArray[Mat4] = FixedArray::make(3, Mat4::from_translation(Vec3::new(1.0, 0.0, 0.0)))
  let dst : FixedArray[Mat4] = FixedArray::make(3, Mat4::identity())
  batch_mul_mat4(dst, a, b, 3)
  need_vec3(dst[2].transform_point3(Vec3::zero()), Vec3::new(1.0, 0.0, 0.0))
  let src : FixedArray[Vec3] = FixedArray::make(4, Vec3::unit_x())
  let out : FixedArray[Vec3] = FixedArray::make(4, Vec3::zero())
  batch_transform_points3(out, Mat4::from_scale(Vec3::splat(3.0)), src, 4)
  need_vec3(out[3], Vec3::new(3.0, 0.0, 0.0))
  // Frustum cull.
  let view = look_at_rh(Vec3::new(0.0, 0.0, 10.0), Vec3::zero(), Vec3::unit_y())
  let proj = perspective_rh(deg_to_rad(60.0), 1.0, 0.1, 100.0, clip=ClipSpace::Vulkan)
  let frustum = Frustum::from_view_proj(proj * view, clip=ClipSpace::Vulkan)
  let boxes : FixedArray[Aabb3] = FixedArray::make(3, Aabb3::new(Vec3::splat(-0.5), Vec3::splat(0.5)))
  boxes[1] = Aabb3::new(Vec3::splat(40.0), Vec3::splat(41.0))
  let visible : FixedArray[Bool] = FixedArray::make(3, false)
  let hits = batch_frustum_cull(visible, frustum, boxes, 3)
  need(hits == 2, "batch cull count")
  need(visible[0] && !(visible[1]) && visible[2], "batch cull flags")
}
