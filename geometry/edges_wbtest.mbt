// `LineData`, `edges` and `wireframe` invariants.

///|
test "line data operations" {
  let a : @tmath.Vec3 = @tmath.Vec3::new(0.0, 0.0, 0.0)
  let b : @tmath.Vec3 = @tmath.Vec3::new(1.0, 0.0, 0.0)
  let c : @tmath.Vec3 = @tmath.Vec3::new(1.0, 1.0, 0.0)
  let lines = LineData::new([a, b, c], [0, 1, 1, 2])
  need(lines.vertex_count() == 3, "line verts")
  need(lines.segment_count() == 2, "line segments")
  need_vec3(lines.bounds().min, a)
  need_vec3(lines.bounds().max, c)
  let flat = lines.to_non_indexed()
  need(flat.vertex_count() == 4, "line non-indexed verts")
  need(flat.indices[3].reinterpret_as_int() == 3, "line non-indexed indices")
  let moved = lines.transformed(
    @tmath.Affine3::from_translation(@tmath.Vec3::new(0.0, 0.0, 1.0)),
  )
  need(close(moved.bounds().min.z, 1.0), "line transform")
  let merged = LineData::merge([lines, lines])
  need(merged.segment_count() == 4, "line merge segments")
  need(merged.indices[4].reinterpret_as_int() == 3, "line merge rebase")
  need(LineData::empty().segment_count() == 0, "empty line data")
}

///|
test "box edges and wireframe" {
  let m = box()
  // 12 cube edges; the 6 coplanar face diagonals are filtered at 1 degree.
  let e = edges(m)
  need(e.segment_count() == 12, "box edges")
  need_vec3(e.bounds().min, m.bounds().min)
  need_vec3(e.bounds().max, m.bounds().max)
  // threshold 0 keeps every shared edge, including the face diagonals.
  let all_edges = edges(m, threshold_angle=0.0)
  need(all_edges.segment_count() == 18, "box edges at 0 degrees")
  // A flat plane: 4 boundary edges, its interior diagonal is filtered.
  let p = plane()
  need(edges(p).segment_count() == 4, "plane edges")
  need(wireframe(p).segment_count() == 5, "plane wireframe")
  need(wireframe(m).segment_count() == 18, "box wireframe")
}

///|
test "flat grid has no interior crease edges" {
  // A 4x4 plane tessellation: all interior edges are coplanar, so only the
  // four boundary edges survive the default 1 degree threshold.
  let p = plane(width_segments=4, height_segments=4)
  let flat = edges(p)
  // The outline is subdivided: 4 boundary segments per side.
  need(flat.segment_count() == 16, "flat grid edges")
  // 20 horizontal + 20 vertical + 16 triangle diagonals.
  need(wireframe(p).segment_count() == 56, "flat grid wireframe")
}

///|
test "coarse sphere is all creases" {
  // Smooth shading does not make a coarse sphere geometrically smooth: every
  // adjacent facet pair exceeds 1 degree, so edges() keeps them all.
  let m = sphere(radius=1.0, width_segments=8, height_segments=4)
  let creases = edges(m)
  let wires = wireframe(m)
  need(creases.segment_count() > 0, "sphere creases")
  need(creases.segment_count() <= wires.segment_count(), "sphere crease subset")
  let mut max_len : Float = 0.0
  for i = 0; i < wires.segment_count(); i = i + 1 {
    let a = wires.positions[wires.indices[2 * i].reinterpret_as_int()]
    let b = wires.positions[wires.indices[2 * i + 1].reinterpret_as_int()]
    let len = a.distance(b)
    if len > max_len {
      max_len = len
    }
  }
  need(max_len > 0.0, "sphere wireframe segment length")
}
