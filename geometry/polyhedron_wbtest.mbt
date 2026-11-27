// Polyhedron family invariants: non-indexed output, every vertex on the
// sphere of the requested radius, unit normals, CCW winding, and the exact
// face counts of the base solids / detail subdivision.

///|
fn need_on_sphere(m : MeshData, radius : Float) -> Unit raise {
  for i = 0; i < m.vertex_count(); i = i + 1 {
    need(close(m.positions[i].length(), radius, eps=1.0e-3), "polyhedron radius")
  }
}

///|
test "tetrahedron" {
  let m = tetrahedron()
  need(m.vertex_count() == 12, "tetrahedron verts")
  need(m.triangle_count() == 4, "tetrahedron tris")
  need(all_units(m), "tetrahedron normals")
  need(winding_consistent(m), "tetrahedron winding")
  need_on_sphere(m, 1.0)
}

///|
test "octahedron and dodecahedron" {
  let o = octahedron(radius=2.0)
  need(o.vertex_count() == 24, "octahedron verts")
  need(o.triangle_count() == 8, "octahedron tris")
  need(all_units(o), "octahedron normals")
  need(winding_consistent(o), "octahedron winding")
  need_on_sphere(o, 2.0)
  let d = dodecahedron()
  need(d.vertex_count() == 108, "dodecahedron verts")
  need(d.triangle_count() == 36, "dodecahedron tris")
  need(all_units(d), "dodecahedron normals")
  need(winding_consistent(d), "dodecahedron winding")
  need_on_sphere(d, 1.0)
}

///|
test "icosahedron detail subdivision" {
  let base = icosahedron()
  need(base.vertex_count() == 60, "icosahedron verts")
  need(base.triangle_count() == 20, "icosahedron tris")
  need(winding_consistent(base), "icosahedron winding")
  // detail 1 splits every triangle into four.
  let smooth = icosahedron(detail=1)
  need(smooth.vertex_count() == 240, "icosahedron detail verts")
  need(smooth.triangle_count() == 80, "icosahedron detail tris")
  need(all_units(smooth), "icosahedron detail normals")
  need(winding_consistent(smooth), "icosahedron detail winding")
  // detail > 0 uses smooth spherical normals, i.e. normal == direction.
  for i = 0; i < smooth.vertex_count(); i = i + 1 {
    need_vec3(smooth.normals[i], smooth.positions[i].normalize(), eps=1.0e-3)
  }
}
