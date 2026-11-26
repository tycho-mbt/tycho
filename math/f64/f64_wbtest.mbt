// Double-precision invariants: matrix inversion, quaternion/matrix
// equivalence, and large-world precision that the `Float` package cannot hold.

///|
fn need(cond : Bool, what : StringView) -> Unit raise {
  if !cond {
    fail(what)
  }
}

///|
fn need_dvec3(a : DVec3, b : DVec3, eps? : Double = 1.0e-9) -> Unit raise {
  if !a.approx_eq(b, eps~) {
    fail("DVec3 mismatch")
  }
}

///|
test "dvec algebra" {
  let a = DVec3::new(1.0, 2.0, 3.0)
  let b = DVec3::new(-4.0, 5.0, 6.0)
  need(a.dot(b) == 24.0, "DVec3 dot")
  need_dvec3(a.cross(b), DVec3::new(-3.0, -18.0, 13.0), eps=1.0e-12)
  need((DVec3::new(3.0, 4.0, 0.0).length() - 5.0).abs() < 1.0e-15, "DVec3 length")
  need_dvec3(DVec3::zero().normalize(), DVec3::zero())
  need(DVec3::zero().try_normalize() is None, "DVec3 zero try_normalize")
  let n = DVec3::new(0.3, -0.4, 0.5).normalize()
  need((n.length() - 1.0).abs() < 1.0e-15, "DVec3 normalize unit")
  need_dvec3(DVec3::from_vec3(n.to_vec3()), n, eps=1.0e-6)
  need(DVec2::new(3.0, 4.0).normalize().approx_eq(DVec2::new(0.6, 0.8)), "DVec2 normalize")
  need(DVec4::new(0.0, 0.0, 3.0, 4.0).length() == 5.0, "DVec4 length")
}

///|
test "dquat and dmat3 equivalence" {
  let q = DQuat::from_axis_angle(DVec3::new(1.0, 2.0, 3.0), 0.7)
  need((q.length() - 1.0).abs() < 1.0e-15, "DQuat unit")
  let m = q.to_dmat3()
  let v = DVec3::new(0.3, -0.7, 1.1)
  need_dvec3(q.mul_vec3(v), m.mul_vec3(v))
  let back = DQuat::from_mat3(m)
  need(back.approx_eq(q), "DQuat round trip")
  need_dvec3(q.conjugate().mul_vec3(q.mul_vec3(v)), v)
  // SLERP at 45 degrees, accurate to ~1e-15.
  let a = DQuat::from_rotation_z(0.0)
  let b = DQuat::from_rotation_z(1.5707963267948966)
  let half = a.slerp(b, 0.5)
  let expected = DQuat::from_rotation_z(0.7853981633974483)
  need(half.approx_eq(expected, eps=1.0e-12), "DQuat slerp")
  // Euler order agreement.
  let e = DQuat::from_euler(@tmath.EulerOrder::XYZ, 0.2, 0.4, 0.6)
  let manual = DQuat::from_rotation_x(0.2) *
    DQuat::from_rotation_y(0.4) *
    DQuat::from_rotation_z(0.6)
  need(e.approx_eq(manual), "DQuat from_euler")
  // Orthonormal matrix stays orthonormal to double precision.
  let mt = m * m.transpose()
  need(mt.approx_eq(DMat3::identity(), eps=1.0e-15), "DMat3 orthonormal")
}

///|
test "dmat4 inverse" {
  let m = DMat4::from_scale_rotation_translation(
    DVec3::new(2.0, 0.5, 3.0),
    DQuat::from_euler(@tmath.EulerOrder::YXZ, 0.3, -1.1, 0.7),
    DVec3::new(1.0e6, -2.0e6, 1.5e6),
  )
  let inv = match m.inverse() {
    Some(i) => i
    None => fail("DMat4 must be invertible")
  }
  // Entries reach 1e6, so the identity check is limited by cancellation.
  need((m * inv).approx_eq(DMat4::identity(), eps=1.0e-9), "DMat4 inverse product")
  need((inv * m).approx_eq(DMat4::identity(), eps=1.0e-9), "DMat4 inverse product other side")
  need(((m.determinant() - 3.0) / 3.0).abs() < 1.0e-15, "DMat4 determinant")
  // Singular matrices report None.
  let singular = DMat4::from_cols(
    DVec4::new(1.0, 0.0, 0.0, 0.0),
    DVec4::new(1.0, 0.0, 0.0, 0.0),
    DVec4::new(0.0, 0.0, 1.0, 0.0),
    DVec4::new(0.0, 0.0, 0.0, 1.0),
  )
  need(singular.inverse() is None, "DMat4 singular")
  // Down-cast agrees with the single-precision matrix to f32 precision.
  let down = m.to_mat4()
  let p = DVec3::new(0.25, -1.5, 2.0)
  need(
    down.transform_point3(p.to_vec3()).approx_eq(
      m.transform_point3(p).to_vec3(),
      eps=1.0e-3,
    ),
    "DMat4 to_mat4",
  )
}

///|
test "daffine3 inverse" {
  let a = DAffine3::from_dmat4(
    DMat4::from_scale_rotation_translation(
      DVec3::new(1.0, 2.0, 3.0),
      DQuat::from_rotation_y(0.9),
      DVec3::new(-4.0, 5.0, 6.0),
    ),
  )
  let p = DVec3::new(10.0, -20.0, 30.0)
  let inv = match a.inverse() {
    Some(i) => i
    None => fail("DAffine3 invertible")
  }
  need_dvec3(inv.transform_point3(a.transform_point3(p)), p, eps=1.0e-9)
  need_dvec3(a.to_dmat4().transform_point3(p), a.transform_point3(p))
  need_dvec3(DVec3::from_vec3(a.to_affine3().transform_point3(p.to_vec3())), a.transform_point3(p), eps=1.0e-4)
}

///|
test "double projection precision" {
  // Camera 1e6 units away from the origin: the f32 pipeline loses decimetres
  // here, the double pipeline still round-trips to millimetres.
  let eye = DVec3::new(1.0e6, 2.0e6, 3.0e6)
  let view = dlook_at_rh(eye, DVec3::zero(), DVec3::unit_y())
  let proj = dperspective_rh(0.9272952180016122, 1.7, 1.0, 1.0e7)
  let vp = proj * view
  let world = DVec3::new(0.3, -0.4, 0.5)
  let ndc = dproject(vp, world)
  let inv = match vp.inverse() {
    Some(i) => i
    None => fail("view-projection invertible")
  }
  let back = dunproject(inv, ndc)
  // 3.7e6 units from the camera the homogeneous round trip keeps ~1e-10
  // relative precision (the f32 pipeline is ~1e-7, i.e. decimetres here).
  need(back.distance(world) < 1.0e-2, "large-world round trip precision")
  need(ndc.x.abs() < 1.0 && ndc.y.abs() < 1.0, "ndc inside frustum")
  // Clip-space boundaries.
  let near = dperspective_rh(1.0, 1.0, 0.1, 100.0, clip=@tmath.ClipSpace::Vulkan)
  need((near.project_point3(DVec3::new(0.0, 0.0, -0.1)).z).abs() < 1.0e-12, "d near z")
  need((near.project_point3(DVec3::new(0.0, 0.0, -100.0)).z - 1.0).abs() < 1.0e-12, "d far z")
  let gl = dperspective_rh(1.0, 1.0, 0.1, 100.0, clip=@tmath.ClipSpace::NegOneToOne)
  need((gl.project_point3(DVec3::new(0.0, 0.0, -0.1)).z + 1.0).abs() < 1.0e-12, "d gl near z")
  let rev = dperspective_infinite_reverse_rh(1.0, 1.0, 0.1)
  need((rev.project_point3(DVec3::new(0.0, 0.0, -0.1)).z - 1.0).abs() < 1.0e-12, "d infinite reverse near")
  let ortho = dorthographic_rh(-2.0, 2.0, -1.0, 1.0, 0.1, 10.0)
  need(ortho.project_point3(DVec3::new(2.0, 1.0, -0.1)).approx_eq(DVec3::new(1.0, -1.0, 0.0), eps=1.0e-12), "d ortho near")
  need(ortho.project_point3(DVec3::new(2.0, 1.0, -10.0)).approx_eq(DVec3::new(1.0, -1.0, 1.0), eps=1.0e-12), "d ortho far")
}
