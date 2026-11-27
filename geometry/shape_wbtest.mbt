// `Shape2D` / `shape` / `shapes` invariants.

///|
fn ccw_square(half : Float) -> Array[@tmath.Vec2] {
  [
    @tmath.Vec2::new(-half, -half),
    @tmath.Vec2::new(half, -half),
    @tmath.Vec2::new(half, half),
    @tmath.Vec2::new(-half, half),
  ]
}

///|
fn cw_square(half : Float) -> Array[@tmath.Vec2] {
  reversed_ring(ccw_square(half))
}

///|
/// Signed area of the mesh projected onto XY (positive = +Z facing).
fn mesh_area_z(m : MeshData) -> Float {
  let mut sum : Float = 0.0
  let mut i = 0
  while i + 2 < m.indices.length() {
    let a = m.positions[m.indices[i].reinterpret_as_int()]
    let b = m.positions[m.indices[i + 1].reinterpret_as_int()]
    let c = m.positions[m.indices[i + 2].reinterpret_as_int()]
    sum = sum + ((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)) * 0.5
    i = i + 3
  }
  sum
}

///|
test "shape polygon area and winding" {
  need(close(polygon_area(ccw_square(1.0)), 4.0), "ccw area")
  need(close(polygon_area(cw_square(1.0)), -4.0), "cw area")
  need(!is_clockwise(ccw_square(1.0)), "ccw helper")
  need(is_clockwise(cw_square(1.0)), "cw helper")
}

///|
test "shape triangulation" {
  let m = shape(Shape2D::new(ccw_square(0.5)))
  need(m.vertex_count() == 4, "shape verts")
  need(m.triangle_count() == 2, "shape tris")
  need(m.groups.length() == 0, "single shape has no groups")
  need_vec3(m.bounds().min, @tmath.Vec3::new(-0.5, -0.5, 0.0))
  need_vec3(m.bounds().max, @tmath.Vec3::new(0.5, 0.5, 0.0))
  for i = 0; i < m.vertex_count(); i = i + 1 {
    need_vec3(m.normals[i], @tmath.Vec3::unit_z())
  }
  need(close(mesh_area_z(m), 1.0), "shape area")
  need(winding_consistent(m), "shape winding")
  // UVs are planar world coordinates.
  need(close(m.uvs[0].x, -0.5) && close(m.uvs[0].y, -0.5), "shape uv")
}

///|
test "shape with hole" {
  let s = Shape2D::new(ccw_square(1.0), holes=[cw_square(0.25)])
  let m = shape(s)
  need(m.vertex_count() == 8, "holed shape verts")
  need(m.triangle_count() == 8, "holed shape tris")
  need(close(mesh_area_z(m), 3.75), "holed shape area")
  need(winding_consistent(m), "holed shape winding")
  // Reversed input winding is normalized: the mesh still faces +Z.
  let flipped = shape(Shape2D::new(cw_square(1.0), holes=[ccw_square(0.25)]))
  need(close(mesh_area_z(flipped), 3.75), "normalized winding area")
  need(flipped.triangle_count() == 8, "normalized winding tris")
}

///|
test "multiple shapes become groups" {
  let a = Shape2D::new(ccw_square(1.0))
  let b = Shape2D::new(ccw_square(0.5))
  let m = shapes([a, b])
  need(m.groups.length() == 2, "shape groups")
  need(m.groups[0].material_slot == 0, "group slot 0")
  need(m.groups[1].material_slot == 1, "group slot 1")
  need(m.groups[0].count == 6, "group 0 count")
  need(m.groups[1].count == 6, "group 1 count")
  need(m.triangle_count() == 4, "multi shape tris")
  need(close(mesh_area_z(m), 5.0), "multi shape area")
}
