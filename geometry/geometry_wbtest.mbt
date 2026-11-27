// Pure-data invariant tests for laplaceliu/tycho_geometry.
//
// These run headless (no GPU): they pin the contracts the design doc relies
// on — vertex/index counts, unit normals, CCW winding, analytic bounds, and
// OBJ import semantics.

///|
fn need(cond : Bool, what : StringView) -> Unit raise {
  if !cond {
    fail(what)
  }
}

///|
fn close(a : Float, b : Float, eps? : Float = 1.0e-4) -> Bool {
  @tmath.approx_eq_f(a, b, eps~)
}

///|
fn need_vec3(a : @tmath.Vec3, b : @tmath.Vec3, eps? : Float = 1.0e-4) -> Unit raise {
  if !a.approx_eq(b, eps~) {
    fail("Vec3 mismatch: \{a} vs \{b}")
  }
}

///|
fn is_unit(v : @tmath.Vec3, eps? : Float = 1.0e-3) -> Bool {
  close(v.length(), 1.0, eps~)
}

///|
/// Every triangle's geometric normal must agree with the sum of its vertex
/// normals (i.e. the mesh is CCW-outwards and normals are not flipped).
fn winding_consistent(m : MeshData) -> Bool {
  let mut i = 0
  let ic = m.indices.length()
  while i + 2 < ic {
    let i0 = m.indices[i].reinterpret_as_int()
    let i1 = m.indices[i + 1].reinterpret_as_int()
    let i2 = m.indices[i + 2].reinterpret_as_int()
    let p0 = m.positions[i0]
    let g = (m.positions[i1] - p0).cross(m.positions[i2] - p0)
    if g.length_sq() > 1.0e-12 {
      let n = m.normals[i0] + m.normals[i1] + m.normals[i2]
      if g.dot(n) <= 0.0 {
        return false
      }
    }
    i = i + 3
  }
  true
}

///|
fn all_units(m : MeshData) -> Bool {
  for i = 0; i < m.normals.length(); i = i + 1 {
    if !is_unit(m.normals[i]) {
      return false
    }
  }
  true
}

///|
test "box defaults" {
  let m = box()
  need(m.vertex_count() == 24, "box verts")
  need(m.index_count() == 36, "box indices")
  need(m.triangle_count() == 12, "box triangles")
  need(m.groups.length() == 6, "box groups")
  need(all_units(m), "box unit normals")
  need(winding_consistent(m), "box winding")
  let b = m.bounds()
  need_vec3(b.min, @tmath.Vec3::new(-0.5, -0.5, -0.5))
  need_vec3(b.max, @tmath.Vec3::new(0.5, 0.5, 0.5))
  for i = 0; i < 6; i = i + 1 {
    need(m.groups[i].material_slot == i, "box group slot order")
    need(m.groups[i].count == 6, "box group size")
  }
}

///|
test "box segments" {
  let m = box(width_segments=2, height_segments=3, depth_segments=4)
  // +X/-X: (4+1)*(3+1) each; +Y/-Y: (2+1)*(4+1) each; +Z/-Z: (2+1)*(3+1) each.
  need(m.vertex_count() == 2 * 20 + 2 * 15 + 2 * 12, "segmented box verts")
  // +X/-X: 2*4*3 tris each; +Y/-Y: 2*2*4 each; +Z/-Z: 2*2*3 each.
  need(m.triangle_count() == 2 * 24 + 2 * 16 + 2 * 12, "segmented box tris")
  need(winding_consistent(m), "segmented box winding")
  need(all_units(m), "segmented box normals")
}

///|
test "plane" {
  let m = plane(width=2.0, height=4.0)
  need(m.vertex_count() == 4, "plane verts")
  need(m.index_count() == 6, "plane indices")
  need(m.groups.length() == 0, "plane has no groups")
  need_vec3(m.normals[0], @tmath.Vec3::new(0.0, 0.0, 1.0))
  let b = m.bounds()
  need_vec3(b.min, @tmath.Vec3::new(-1.0, -2.0, 0.0))
  need_vec3(b.max, @tmath.Vec3::new(1.0, 2.0, 0.0))
  need(winding_consistent(m), "plane winding")
}

///|
test "circle and ring" {
  let c = circle(radius=2.0, segments=16)
  need(c.vertex_count() == 18, "circle verts")
  need(c.triangle_count() == 16, "circle tris")
  need(winding_consistent(c), "circle winding")
  need(all_units(c), "circle normals")
  let r = ring(inner=1.0, outer=2.0, theta_segments=12)
  need(r.vertex_count() == 26, "ring verts")
  need(r.triangle_count() == 24, "ring tris")
  need(winding_consistent(r), "ring winding")
  need(all_units(r), "ring normals")
}

///|
test "sphere" {
  let m = sphere(radius=2.0, width_segments=16, height_segments=8)
  need(m.vertex_count() == 17 * 9, "sphere verts")
  need(m.triangle_count() == 16 * 2 * 7, "sphere tris")
  for i = 0; i < m.vertex_count(); i = i + 1 {
    need(close(m.positions[i].length(), 2.0, eps=1.0e-3), "sphere radius")
  }
  need(all_units(m), "sphere normals")
  need(winding_consistent(m), "sphere winding")
}

///|
test "cylinder and cone" {
  let m = cylinder(
    radius_top=1.0,
    radius_bottom=1.0,
    height=2.0,
    radial_segments=8,
    height_segments=2,
  )
  need(m.vertex_count() == 27 + 9 + 9, "cylinder verts")
  need(m.triangle_count() == 8 * 2 * 2 + 8 + 8, "cylinder tris")
  need(m.groups.length() == 3, "cylinder groups")
  need(all_units(m), "cylinder normals")
  need(winding_consistent(m), "cylinder winding")
  let b = m.bounds()
  need_vec3(b.min, @tmath.Vec3::new(-1.0, -1.0, -1.0))
  need_vec3(b.max, @tmath.Vec3::new(1.0, 1.0, 1.0))
  // A cone has no top cap, so only side + bottom groups remain.
  let c = cone(radius=1.0, height=2.0, radial_segments=8)
  need(c.groups.length() == 2, "cone groups")
  need(winding_consistent(c), "cone winding")
  need(m.index_count() == 144, "cylinder index count")
}

///|
test "capsule" {
  let m = capsule(radius=0.5, length=1.0, cap_segments=4, radial_segments=8)
  need(m.vertex_count() == 9 * 10, "capsule verts")
  for i = 0; i < m.vertex_count(); i = i + 1 {
    let p = m.positions[i]
    let yc = @tmath.clamp_f(p.y, -0.5, 0.5)
    let d = @tmath.Vec3::new(p.x, p.y - yc, p.z).length()
    need(close(d, 0.5, eps=1.0e-3), "capsule surface distance")
  }
  need(all_units(m), "capsule normals")
  need(winding_consistent(m), "capsule winding")
}

///|
test "torus" {
  let m = torus(radius=2.0, tube=0.5, radial_segments=8, tubular_segments=12)
  need(m.vertex_count() == 13 * 9, "torus verts")
  need(m.triangle_count() == 12 * 8 * 2, "torus tris")
  for i = 0; i < m.vertex_count(); i = i + 1 {
    let p = m.positions[i]
    let radial = @tmath.Vec3::new(p.x, p.y, 0.0).length()
    let d = @tmath.sqrt((radial - 2.0) * (radial - 2.0) + p.z * p.z)
    need(close(d, 0.5, eps=1.0e-3), "torus tube radius")
  }
  need(all_units(m), "torus normals")
  need(winding_consistent(m), "torus winding")
}

///|
test "merge, transform, non-indexed, flipped" {
  let a = box()
  let b = plane()
  let merged = MeshData::merge([a, b])
  need(merged.vertex_count() == a.vertex_count() + b.vertex_count(), "merge verts")
  need(merged.index_count() == a.index_count() + b.index_count(), "merge indices")
  // The plane is the second part: its indices must be rebased by 24.
  let last = merged.indices[merged.index_count() - 1].reinterpret_as_int()
  need(last >= a.vertex_count(), "merge index rebase")
  let moved = a.transformed(@tmath.Affine3::from_translation(@tmath.Vec3::new(10.0, 0.0, 0.0)))
  need_vec3(moved.bounds().min, @tmath.Vec3::new(9.5, -0.5, -0.5))
  let flat = a.to_non_indexed()
  need(flat.vertex_count() == a.index_count(), "non-indexed verts")
  need(flat.index_count() == a.index_count(), "non-indexed indices")
  need(flat.indices[5].reinterpret_as_int() == 5, "non-indexed identity indices")
  let fl = a.flipped()
  need(fl.normals[0].dot(a.normals[0]) < 0.0, "flipped normals")
  need(fl.indices[1] == a.indices[2], "flipped winding")
}

///|
test "compute vertex normals from bare triangles" {
  let m = plane()
  let cleared : FixedArray[@tmath.Vec3] = FixedArray::make(m.vertex_count(), @tmath.Vec3::zero())
  let bare = MeshData::new(m.positions, cleared, m.uvs, m.indices)
  bare.compute_vertex_normals()
  for i = 0; i < bare.vertex_count(); i = i + 1 {
    need_vec3(bare.normals[i], @tmath.Vec3::new(0.0, 0.0, 1.0), eps=1.0e-3)
  }
}

///|
test "compute tangents" {
  let m = plane(width=2.0, height=2.0)
  m.compute_tangents()
  match m.tangents {
    Some(t) => {
      for i = 0; i < t.length(); i = i + 1 {
        let v = @tmath.Vec3::new(t[i].x, t[i].y, t[i].z)
        need(is_unit(v), "tangent unit")
        need(close(v.dot(m.normals[i]), 0.0, eps=1.0e-3), "tangent orthogonal")
        need(t[i].w == 1.0 || t[i].w == -1.0, "tangent handedness")
      }
    }
    None => fail("tangents missing")
  }
}

///|
test "obj import" {
  // Two parts: a quad with v/vt/vn, then a triangle using negative indices.
  let text = "# test asset\no first\nv 0 0 0\nv 1 0 0\nv 1 1 0\nv 0 1 0\nvt 0 0\nvt 1 0\nvt 1 1\nvt 0 1\nvn 0 0 1\nf 1/1/1 2/2/1 3/3/1 4/4/1\no second\nv 0 0 1\nv 1 0 1\nv 1 1 1\nf -3 -2 -1\n"
  let parts = parse_obj_text(text)
  need(parts.length() == 2, "obj part count")
  let (n0, m0) = parts[0]
  let (n1, m1) = parts[1]
  need(n0 == "first", "obj first name")
  need(n1 == "second", "obj second name")
  need(m0.vertex_count() == 4, "obj quad verts")
  need(m0.triangle_count() == 2, "obj quad fan")
  need(winding_consistent(m0), "obj quad winding")
  need_vec3(m0.bounds().min, @tmath.Vec3::new(0.0, 0.0, 0.0))
  need_vec3(m0.bounds().max, @tmath.Vec3::new(1.0, 1.0, 0.0))
  // The second part has no vn: normals must be computed (+Z).
  need(m1.vertex_count() == 3, "obj tri verts")
  need(m1.triangle_count() == 1, "obj tri count")
  for i = 0; i < 3; i = i + 1 {
    need_vec3(m1.normals[i], @tmath.Vec3::new(0.0, 0.0, 1.0), eps=1.0e-3)
  }
}

///|
test "empty mesh safety" {
  let empty = MeshData::new(
    FixedArray::make(0, @tmath.Vec3::zero()),
    FixedArray::make(0, @tmath.Vec3::zero()),
    FixedArray::make(0, @tmath.Vec2::zero()),
    FixedArray::make(0, (0 : UInt)),
  )
  need(empty.vertex_count() == 0, "empty verts")
  need(empty.bounds().volume() == 0.0, "empty bounds")
  empty.compute_vertex_normals()
  empty.compute_tangents()
  need(empty.vertex_count() == 0, "empty normals no-op")
}

///|
test "geometry failures carry a typed error" {
  let mesh = MeshData::new(
    FixedArray::make(2, @tmath.Vec3::zero()),
    FixedArray::make(2, @tmath.Vec3::unit_y()),
    FixedArray::make(2, @tmath.Vec2::zero()),
    FixedArray::make(0, (0 : UInt)),
  )
  let mesh_error = try {
    mesh.add_morph_target(FixedArray::make(1, @tmath.Vec3::zero()))
    false
  } catch {
    GeometryError::InvalidMesh(msg) => msg.length() > 0
    _ => false
  }
  need(mesh_error, "add_morph_target must raise InvalidMesh")
  let gltf_error = try {
    let _ = parse_gltf("{ not json")
    false
  } catch {
    GeometryError::InvalidGltf(msg) => msg.length() > 0
    _ => false
  }
  need(gltf_error, "parse_gltf must raise InvalidGltf")
}


///|
test "circle sector and ring bands" {
  // Half disc: centre + 9 rim vertices, 8 triangles in the upper half.
  let half = circle(
    radius=1.0,
    segments=8,
    theta_start=0.0,
    theta_length=@tmath.PI,
  )
  need(half.vertex_count() == 10, "half circle verts")
  need(half.triangle_count() == 8, "half circle tris")
  let b = half.bounds()
  need_vec3(b.min, @tmath.Vec3::new(-1.0, 0.0, 0.0), eps=1.0e-3)
  need_vec3(b.max, @tmath.Vec3::new(1.0, 1.0, 0.0), eps=1.0e-3)
  need(winding_consistent(half), "half circle winding")
  // Quarter annulus split into two radial bands.
  let quarter = ring(
    inner=0.5,
    outer=1.0,
    theta_segments=8,
    phi_segments=2,
    theta_start=0.0,
    theta_length=@tmath.FRAC_PI_2,
  )
  need(quarter.vertex_count() == 9 * 3, "banded ring verts")
  need(quarter.triangle_count() == 8 * 2 * 2, "banded ring tris")
  need(all_units(quarter), "banded ring normals")
  need(winding_consistent(quarter), "banded ring winding")
  let qb = quarter.bounds()
  need(qb.min.x > -1.0e-4, "quarter ring x")
  need(qb.min.y > -1.0e-4, "quarter ring y")
  need(close(qb.max.x, 1.0, eps=1.0e-3), "quarter ring radius")
}
