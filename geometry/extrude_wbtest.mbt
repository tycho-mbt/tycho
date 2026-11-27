// `extrude` invariants: triangle counts, bounds, signed volume, watertightness
// (every position-quantized edge shared by exactly two triangles) and groups.

///|
fn signed_volume(m : MeshData) -> Float {
  let mut volume : Float = 0.0
  let mut i = 0
  while i + 2 < m.indices.length() {
    let a = m.positions[m.indices[i].reinterpret_as_int()]
    let b = m.positions[m.indices[i + 1].reinterpret_as_int()]
    let c = m.positions[m.indices[i + 2].reinterpret_as_int()]
    volume = volume + a.dot(b.cross(c)) / 6.0
    i = i + 3
  }
  volume
}

///|
/// A closed mesh has every undirected edge used exactly twice.
fn watertight(m : MeshData) -> Bool {
  let (_, ids) = canonical_vertices(m)
  let counts : @hashmap.HashMap[(Int, Int), Int] = @hashmap.HashMap([])
  let mut i = 0
  while i + 2 < m.indices.length() {
    let a = ids[m.indices[i].reinterpret_as_int()]
    let b = ids[m.indices[i + 1].reinterpret_as_int()]
    let c = ids[m.indices[i + 2].reinterpret_as_int()]
    let edges : Array[(Int, Int)] = [(a, b), (b, c), (c, a)]
    for edge in edges {
      let (u, v) = edge
      if u != v {
        let key = if u < v { (u, v) } else { (v, u) }
        counts.set(key, counts.get_or_default(key, 0) + 1)
      }
    }
    i = i + 3
  }
  let entries = counts.to_array()
  if entries.length() == 0 {
    return false
  }
  for entry in entries {
    if entry.1 != 2 {
      return false
    }
  }
  true
}

///|
test "extrude square" {
  let m = extrude(Shape2D::new(ccw_square(0.5)), options=ExtrudeOptions::new(depth=2.0))
  // 2 lids x 2 triangles + 4 wall quads x 2 triangles.
  need(m.triangle_count() == 12, "extrude tris")
  need(m.vertex_count() == 36, "extrude verts (non-indexed)")
  need_vec3(m.bounds().min, @tmath.Vec3::new(-0.5, -0.5, 0.0))
  need_vec3(m.bounds().max, @tmath.Vec3::new(0.5, 0.5, 2.0))
  need(close(signed_volume(m), 2.0, eps=1.0e-3), "extrude volume")
  need(watertight(m), "extrude watertight")
  need(all_units(m), "extrude normals")
  need(m.groups.length() == 2, "extrude groups")
  need(m.groups[0].material_slot == 0, "lid group slot")
  need(m.groups[1].material_slot == 1, "wall group slot")
  need(m.groups[0].count == 12, "lid group count")
  need(m.groups[1].count == 24, "wall group count")
}

///|
test "extrude with hole and steps" {
  let s = Shape2D::new(ccw_square(1.0), holes=[cw_square(0.25)])
  let m = extrude(s, options=ExtrudeOptions::new(depth=1.0))
  // 8 lid triangles per side; 8 ring edges x 1 step x 2 triangles.
  need(m.triangle_count() == 16 + 16, "holed extrude tris")
  need(close(signed_volume(m), 3.75, eps=1.0e-3), "holed extrude volume")
  need(watertight(m), "holed extrude watertight")
  // Splitting the extrusion into slices must not change volume or seal.
  let sliced = extrude(
    Shape2D::new(ccw_square(0.5)),
    options=ExtrudeOptions::new(depth=2.0, steps=3),
  )
  need(close(signed_volume(sliced), 2.0, eps=1.0e-3), "sliced volume")
  need(watertight(sliced), "sliced watertight")
  need(sliced.triangle_count() > 12, "sliced adds wall quads")
}

///|
test "extrude normalizes winding" {
  let m = extrude(
    Shape2D::new(cw_square(0.5), holes=[ccw_square(0.2)]),
    options=ExtrudeOptions::new(depth=1.0),
  )
  // 1.0 (outer) - 0.16 (hole) = 0.84, must stay positive.
  need(close(signed_volume(m), 0.84, eps=1.0e-3), "normalized winding volume")
  need(watertight(m), "normalized winding watertight")
}

///|
test "extrude along a path" {
  // Straight path: identical to a depth extrusion.
  let straight : Array[@tmath.Vec3] = [
    @tmath.Vec3::new(0.0, 0.0, 0.0),
    @tmath.Vec3::new(0.0, 0.0, 2.0),
  ]
  let m = extrude(
    Shape2D::new(ccw_square(0.5)),
    options=ExtrudeOptions::new(steps=2, extrude_path=Some(straight)),
  )
  need_vec3(m.bounds().min, @tmath.Vec3::new(-0.5, -0.5, 0.0), eps=1.0e-3)
  need_vec3(m.bounds().max, @tmath.Vec3::new(0.5, 0.5, 2.0), eps=1.0e-3)
  need(close(signed_volume(m), 2.0, eps=1.0e-2), "straight path volume")
  need(watertight(m), "straight path watertight")
  // Quarter-circle path: the solid bends, keeps a positive volume, and has
  // finite unit normals.
  let curved : Array[@tmath.Vec3] = []
  for i = 0; i <= 8; i = i + 1 {
    let t : Float = f_of_int(i) / 8.0
    let (s, c) = @tmath.sin_cos(t * @tmath.FRAC_PI_2)
    curved.push(@tmath.Vec3::new(s, 0.0, 1.0 - c))
  }
  let bent = extrude(
    Shape2D::new(ccw_square(0.2)),
    options=ExtrudeOptions::new(steps=8, extrude_path=Some(curved)),
  )
  need(watertight(bent), "curved path watertight")
  need(all_units(bent), "curved path normals")
  need(signed_volume(bent) > 0.0, "curved path volume")
  let b = bent.bounds()
  need(b.max.z > 0.5, "curved path reaches the far end")
}

///|
test "extrude empty shape" {
  let empty : Array[@tmath.Vec2] = []
  let m = extrude(Shape2D::new(empty), options=ExtrudeOptions::new(depth=1.0))
  need(m.vertex_count() == 0, "empty extrude")
  need(m.index_count() == 0, "empty extrude indices")
}


///|
fn ccw_square_at(cx : Float, cy : Float, half : Float) -> Array[@tmath.Vec2] {
  [
    @tmath.Vec2::new(cx - half, cy - half),
    @tmath.Vec2::new(cx + half, cy - half),
    @tmath.Vec2::new(cx + half, cy + half),
    @tmath.Vec2::new(cx - half, cy + half),
  ]
}

///|
test "extrude multiple shapes" {
  let m = extrude_shapes(
    [
      Shape2D::new(ccw_square_at(-1.0, 0.0, 0.5)),
      Shape2D::new(ccw_square_at(1.0, 0.0, 0.5)),
    ],
    options=ExtrudeOptions::new(depth=1.0),
  )
  // Two independent 1x1x1 solids.
  need(close(signed_volume(m), 2.0, eps=1.0e-3), "multi extrude volume")
  need(watertight(m), "multi extrude watertight")
  need(m.groups.length() == 4, "multi extrude groups")
  need(m.groups[0].material_slot == 0, "multi lid slot 1")
  need(m.groups[1].material_slot == 1, "multi wall slot 1")
  need(m.groups[2].material_slot == 0, "multi lid slot 2")
  need(m.groups[3].material_slot == 1, "multi wall slot 2")
  need(close(m.bounds().min.x, -1.5, eps=1.0e-3), "multi bounds min")
  need(close(m.bounds().max.x, 1.5, eps=1.0e-3), "multi bounds max")
  // Empty input is a no-op rather than an error.
  let empty : Array[Shape2D] = []
  need(extrude_shapes(empty).vertex_count() == 0, "empty multi extrude")
}

///|
test "extrude bevel" {
  let m = extrude(
    Shape2D::new(ccw_square(0.5)),
    options=ExtrudeOptions::new(depth=1.0, bevel_enabled=true),
  )
  // 3 front + 2 body + 3 back slices -> 7 wall gaps x 4 edges x 2 triangles.
  need(m.triangle_count() == 4 + 56, "bevel tris")
  need(m.vertex_count() == 180, "bevel verts")
  need(watertight(m), "bevel watertight")
  need(all_units(m), "bevel normals")
  // The base volume is 1 (unit square x depth 1); the bevel bulges it out.
  need(signed_volume(m) > 1.0, "bevel adds volume")
  // At a 90 degree corner the miter is diagonal: the axis reach is bevel_size.
  let reach : Float = 0.5 + 0.1
  let b = m.bounds()
  need(close(b.max.x, reach, eps=1.0e-3), "bevel x reach")
  need(close(b.min.x, -reach, eps=1.0e-3), "bevel -x reach")
  need(close(b.min.z, -0.2, eps=1.0e-3), "bevel front")
  need(close(b.max.z, 1.2, eps=1.0e-3), "bevel back")
  need(m.groups.length() == 2, "bevel groups")
  need(m.groups[0].count == 12, "bevel lid group")
  need(m.groups[1].count == 168, "bevel wall group")
}

///|
test "extrude bevel offset" {
  let m = extrude(
    Shape2D::new(ccw_square(0.5)),
    options=ExtrudeOptions::new(depth=1.0, bevel_enabled=true, bevel_offset=0.05),
  )
  need(watertight(m), "bevel offset watertight")
  // The body ring is at bevel_size + offset = 0.15.
  let reach : Float = 0.5 + 0.15
  need(close(m.bounds().max.x, reach, eps=1.0e-3), "bevel offset reach")
}

///|
test "extrude bevel with hole" {
  let m = extrude(
    Shape2D::new(ccw_square(1.0), holes=[cw_square(0.25)]),
    options=ExtrudeOptions::new(depth=1.0, bevel_enabled=true),
  )
  need(watertight(m), "bevel hole watertight")
  need(all_units(m), "bevel hole normals")
  // The bevel grows the solid into the hole, so the volume exceeds 3.75.
  need(signed_volume(m) > 3.75, "bevel hole volume")
}

///|
test "bevel is ignored on path extrusion" {
  let straight : Array[@tmath.Vec3] = [
    @tmath.Vec3::new(0.0, 0.0, 0.0),
    @tmath.Vec3::new(0.0, 0.0, 2.0),
  ]
  let m = extrude(
    Shape2D::new(ccw_square(0.5)),
    options=ExtrudeOptions::new(
      steps=2,
      extrude_path=Some(straight),
      bevel_enabled=true,
    ),
  )
  need_vec3(m.bounds().min, @tmath.Vec3::new(-0.5, -0.5, 0.0), eps=1.0e-3)
  need_vec3(m.bounds().max, @tmath.Vec3::new(0.5, 0.5, 2.0), eps=1.0e-3)
  need(close(signed_volume(m), 2.0, eps=1.0e-2), "path ignores bevel")
}
