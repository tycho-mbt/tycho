// Swept / knot generator invariants: counts, unit normals, CCW winding, and
// the geometric property each generator promises (lathe radius, tube radius,
// knot tube distance).

///|
test "torus knot" {
  let m = torus_knot(
    radius=1.0,
    tube=0.1,
    tubular_segments=12,
    radial_segments=4,
    p=2,
    q=3,
  )
  need(m.vertex_count() == 13 * 5, "torus knot verts")
  need(m.triangle_count() == 12 * 4 * 2, "torus knot tris")
  need(all_units(m), "torus knot normals")
  need(winding_consistent(m), "torus knot winding")
  // Every ring lies on a circle of radius `tube` around the knot curve.
  for i = 0; i <= 12; i = i + 1 {
    let u : Float = f_of_int(i) / 12.0 * 2.0 * @tmath.TAU
    let center = torus_knot_point(u, 2, 3, 1.0)
    for j = 0; j <= 4; j = j + 1 {
      let k = i * 5 + j
      need(
        close(m.positions[k].distance(center), 0.1, eps=1.0e-3),
        "torus knot tube distance",
      )
    }
  }
}

///|
test "lathe" {
  // Vertical cylinder wall: radius 1 from y = -1 to y = 1.
  let profile : Array[@tmath.Vec2] = [
    @tmath.Vec2::new(1.0, -1.0),
    @tmath.Vec2::new(1.0, 1.0),
  ]
  let m = lathe(profile, segments=8)
  need(m.vertex_count() == 9 * 2, "lathe verts")
  need(m.triangle_count() == 8 * 2, "lathe tris")
  need(all_units(m), "lathe normals")
  need(winding_consistent(m), "lathe winding")
  for i = 0; i < m.vertex_count(); i = i + 1 {
    let p = m.positions[i]
    need(close(@tmath.sqrt(p.x * p.x + p.z * p.z), 1.0, eps=1.0e-3), "lathe radius")
    // Outward radial normals for a cylinder wall.
    need(close(m.normals[i].y, 0.0, eps=1.0e-3), "lathe normal y")
  }
  // Degenerate profile: fewer than two points yields an empty mesh.
  let empty_profile : Array[@tmath.Vec2] = []
  let empty = lathe(empty_profile, segments=4)
  need(empty.vertex_count() == 0, "lathe empty profile")
}

///|
test "tube along a straight path" {
  let path : Array[@tmath.Vec3] = [
    @tmath.Vec3::new(0.0, 0.0, 0.0),
    @tmath.Vec3::new(2.0, 0.0, 0.0),
  ]
  let m = tube(path, tubular_segments=4, radius=0.5, radial_segments=8)
  need(m.vertex_count() == 5 * 9, "tube verts")
  need(m.triangle_count() == 4 * 8 * 2, "tube tris")
  need(all_units(m), "tube normals")
  need(winding_consistent(m), "tube winding")
  for i = 0; i < m.vertex_count(); i = i + 1 {
    let p = m.positions[i]
    need(
      close(@tmath.sqrt(p.y * p.y + p.z * p.z), 0.5, eps=1.0e-3),
      "tube cross-section radius",
    )
  }
  let b = m.bounds()
  need_vec3(b.min, @tmath.Vec3::new(0.0, -0.5, -0.5), eps=1.0e-3)
  need_vec3(b.max, @tmath.Vec3::new(2.0, 0.5, 0.5), eps=1.0e-3)
  // A path with a single point cannot sweep a surface.
  let degenerate = tube([@tmath.Vec3::zero()], tubular_segments=4)
  need(degenerate.vertex_count() == 0, "tube single point")
}

///|
test "closed tube seam" {
  // Square loop in the XY plane; the seam row must duplicate row 0.
  let ring_path : Array[@tmath.Vec3] = [
    @tmath.Vec3::new(1.0, 0.0, 0.0),
    @tmath.Vec3::new(0.0, 1.0, 0.0),
    @tmath.Vec3::new(-1.0, 0.0, 0.0),
    @tmath.Vec3::new(0.0, -1.0, 0.0),
  ]
  let m = tube(ring_path, tubular_segments=8, radius=0.2, radial_segments=4, closed=true)
  need(m.vertex_count() == 9 * 5, "closed tube verts")
  need(m.triangle_count() == 8 * 4 * 2, "closed tube tris")
  need(all_units(m), "closed tube normals")
  need(winding_consistent(m), "closed tube winding")
  for j = 0; j <= 4; j = j + 1 {
    need_vec3(m.positions[j], m.positions[8 * 5 + j], eps=1.0e-5)
    need_vec3(m.normals[j], m.normals[8 * 5 + j], eps=1.0e-5)
  }
}

///|
test "catmull rom sampling" {
  let control : Array[@tmath.Vec3] = [
    @tmath.Vec3::new(0.0, 0.0, 0.0),
    @tmath.Vec3::new(1.0, 0.0, 0.0),
    @tmath.Vec3::new(2.0, 0.0, 0.0),
  ]
  let samples = catmull_rom_chain(control, samples_per_segment=4)
  // 2 segments x 4 samples + the final point.
  need(samples.length() == 9, "catmull rom sample count")
  need_vec3(samples[0], control[0], eps=1.0e-5)
  need_vec3(samples[8], control[2], eps=1.0e-5)
  // A straight control polygon must stay on the X axis.
  for i = 0; i < samples.length(); i = i + 1 {
    need(close(samples[i].y, 0.0, eps=1.0e-5), "catmull rom y")
    need(close(samples[i].z, 0.0, eps=1.0e-5), "catmull rom z")
  }
  // The sampled chain is a valid tube path.
  let m = tube(samples, tubular_segments=6, radius=0.2, radial_segments=5)
  need(m.triangle_count() == 6 * 5 * 2, "catmull rom tube tris")
  need(all_units(m), "catmull rom tube normals")
}
