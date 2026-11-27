// Polyhedron family: tetrahedron / octahedron / dodecahedron / icosahedron.
//
// All of them share one kernel, ported from three.js `PolyhedronGeometry`:
// a base vertex/face table is subdivided `detail` times, every generated
// vertex is projected onto the sphere of `radius`, and UVs come from the
// spherical angles (azimuth / inclination).
//
// The result is non-indexed, exactly like three.js: `detail == 0` therefore
// gets flat face normals, `detail > 0` smooth spherical normals.

///|
/// Subdivide one base triangle into `(detail + 1)^2` smaller ones, appending
/// the resulting non-indexed vertices (CCW, same orientation as the input).
fn polyhedron_lattice(
  out : Array[@tmath.Vec3],
  a : @tmath.Vec3,
  b : @tmath.Vec3,
  c : @tmath.Vec3,
  detail : Int,
) -> Unit {
  let cols = detail + 1
  let lattice : Array[Array[@tmath.Vec3]] = []
  for i = 0; i <= cols; i = i + 1 {
    let t = f_of_int(i) / f_of_int(cols)
    let aj = a.lerp(c, t)
    let bj = b.lerp(c, t)
    let count = cols - i
    let row : Array[@tmath.Vec3] = []
    for j = 0; j <= count; j = j + 1 {
      if j == 0 && i == cols {
        row.push(aj)
      } else {
        row.push(aj.lerp(bj, f_of_int(j) / f_of_int(count)))
      }
    }
    lattice.push(row)
  }
  for i = 0; i < cols; i = i + 1 {
    let limit = 2 * (cols - i) - 1
    for j = 0; j < limit; j = j + 1 {
      let k = j / 2
      if j % 2 == 0 {
        out.push(lattice[i][k + 1])
        out.push(lattice[i + 1][k])
        out.push(lattice[i][k])
      } else {
        out.push(lattice[i][k + 1])
        out.push(lattice[i + 1][k + 1])
        out.push(lattice[i + 1][k])
      }
    }
  }
}

///|
/// Angle around the +Y axis (three.js `azimuth`).
fn polyhedron_azimuth(p : @tmath.Vec3) -> Float {
  @tmath.atan2(p.z, -p.x)
}

///|
/// Spherical UV. V grows downwards because the package UV origin is the
/// top-left corner, so the north pole lands on v = 0.
fn polyhedron_uv(p : @tmath.Vec3) -> @tmath.Vec2 {
  let azimuth = polyhedron_azimuth(p)
  let inclination = @tmath.atan2(
    -p.y,
    @tmath.sqrt(p.x * p.x + p.z * p.z),
  )
  @tmath.Vec2::new(
    azimuth / (2.0 * @tmath.PI) + 0.5,
    inclination / @tmath.PI + 0.5,
  )
}

///|
fn polyhedron_correct_uv(
  uv : @tmath.Vec2,
  p : @tmath.Vec3,
  azimuth : Float,
) -> @tmath.Vec2 {
  let mut u = uv.x
  if azimuth < 0.0 && u == 1.0 {
    u = u - 1.0
  }
  if p.x == 0.0 && p.z == 0.0 {
    u = azimuth / (2.0 * @tmath.PI) + 0.5
  }
  @tmath.Vec2::new(u, uv.y)
}

///|
/// Spherical UVs with the two seam fixes from three.js: per-face pole
/// correction, then a shift for faces that straddle the azimuth seam.
fn polyhedron_uvs(positions : FixedArray[@tmath.Vec3]) -> FixedArray[@tmath.Vec2] {
  let n = positions.length()
  let uvs : FixedArray[@tmath.Vec2] = FixedArray::make(n, @tmath.Vec2::zero())
  for i = 0; i < n; i = i + 1 {
    uvs[i] = polyhedron_uv(positions[i])
  }
  let mut i = 0
  while i + 2 < n {
    let centroid = (positions[i] + positions[i + 1] + positions[i + 2]).scale(
      1.0 / 3.0,
    )
    let azimuth = polyhedron_azimuth(centroid)
    uvs[i] = polyhedron_correct_uv(uvs[i], positions[i], azimuth)
    uvs[i + 1] = polyhedron_correct_uv(uvs[i + 1], positions[i + 1], azimuth)
    uvs[i + 2] = polyhedron_correct_uv(uvs[i + 2], positions[i + 2], azimuth)
    i = i + 3
  }
  let mut i = 0
  while i + 2 < n {
    let x0 = uvs[i].x
    let x1 = uvs[i + 1].x
    let x2 = uvs[i + 2].x
    let high = if x0 > x1 { if x0 > x2 { x0 } else { x2 } } else if x1 > x2 {
      x1
    } else {
      x2
    }
    let low = if x0 < x1 { if x0 < x2 { x0 } else { x2 } } else if x1 < x2 {
      x1
    } else {
      x2
    }
    if high > 0.9 && low < 0.1 {
      if x0 < 0.2 {
        uvs[i] = @tmath.Vec2::new(x0 + 1.0, uvs[i].y)
      }
      if x1 < 0.2 {
        uvs[i + 1] = @tmath.Vec2::new(x1 + 1.0, uvs[i + 1].y)
      }
      if x2 < 0.2 {
        uvs[i + 2] = @tmath.Vec2::new(x2 + 1.0, uvs[i + 2].y)
      }
    }
    i = i + 3
  }
  uvs
}

///|
/// Generic polyhedron builder: `vertices` / `indices` describe the base solid,
/// `detail` subdivides every face, and all vertices are projected onto the
/// sphere of `radius`.
pub fn polyhedron(
  vertices : Array[@tmath.Vec3],
  indices : Array[Int],
  radius? : Float = 1.0,
  detail? : Int = 0,
) -> MeshData {
  let level = if detail < 0 { 0 } else { detail }
  let generated : Array[@tmath.Vec3] = []
  let vertex_count = vertices.length()
  let mut i = 0
  while i + 2 < indices.length() {
    let ia = indices[i]
    let ib = indices[i + 1]
    let ic = indices[i + 2]
    if ia >= 0 &&
      ia < vertex_count &&
      ib >= 0 &&
      ib < vertex_count &&
      ic >= 0 &&
      ic < vertex_count {
      polyhedron_lattice(
        generated,
        vertices[ia],
        vertices[ib],
        vertices[ic],
        level,
      )
    }
    i = i + 3
  }
  let n = generated.length()
  let positions : FixedArray[@tmath.Vec3] = FixedArray::make(
    n,
    @tmath.Vec3::zero(),
  )
  let normals : FixedArray[@tmath.Vec3] = FixedArray::make(n, @tmath.Vec3::zero())
  for k = 0; k < n; k = k + 1 {
    let dir = generated[k].normalize()
    positions[k] = dir.scale(radius)
    normals[k] = dir
  }
  let uvs = polyhedron_uvs(positions)
  let idx : FixedArray[UInt] = FixedArray::make(n, (0 : UInt))
  for k = 0; k < n; k = k + 1 {
    idx[k] = k.reinterpret_as_uint()
  }
  let mesh = MeshData::new(positions, normals, uvs, idx)
  // detail == 0: hard faceted solid. detail > 0: smooth sphere projection.
  if level == 0 {
    mesh.compute_vertex_normals()
  }
  mesh
}

///|
/// Regular tetrahedron (`detail > 0` rounds it into a subdivided sphere).
pub fn tetrahedron(radius? : Float = 1.0, detail? : Int = 0) -> MeshData {
  let vertices : Array[@tmath.Vec3] = [
    @tmath.Vec3::new(1.0, 1.0, 1.0),
    @tmath.Vec3::new(-1.0, -1.0, 1.0),
    @tmath.Vec3::new(-1.0, 1.0, -1.0),
    @tmath.Vec3::new(1.0, -1.0, -1.0),
  ]
  let indices : Array[Int] = [2, 1, 0, 0, 3, 2, 1, 3, 0, 2, 3, 1]
  polyhedron(vertices, indices, radius~, detail~)
}

///|
/// Regular octahedron.
pub fn octahedron(radius? : Float = 1.0, detail? : Int = 0) -> MeshData {
  let vertices : Array[@tmath.Vec3] = [
    @tmath.Vec3::new(1.0, 0.0, 0.0),
    @tmath.Vec3::new(-1.0, 0.0, 0.0),
    @tmath.Vec3::new(0.0, 1.0, 0.0),
    @tmath.Vec3::new(0.0, -1.0, 0.0),
    @tmath.Vec3::new(0.0, 0.0, 1.0),
    @tmath.Vec3::new(0.0, 0.0, -1.0),
  ]
  let indices : Array[Int] = [
    0, 2, 4, 0, 4, 3, 0, 3, 5, 0, 5, 2, 1, 2, 5, 1, 5, 3, 1, 3, 4, 1, 4, 2,
  ]
  polyhedron(vertices, indices, radius~, detail~)
}

///|
/// Regular dodecahedron (pentagonal faces triangulated as in three.js).
pub fn dodecahedron(radius? : Float = 1.0, detail? : Int = 0) -> MeshData {
  let t : Float = (1.0 + @tmath.sqrt(5.0)) / 2.0
  let r : Float = 1.0 / t
  let vertices : Array[@tmath.Vec3] = [
    @tmath.Vec3::new(-1.0, -1.0, -1.0),
    @tmath.Vec3::new(-1.0, -1.0, 1.0),
    @tmath.Vec3::new(-1.0, 1.0, -1.0),
    @tmath.Vec3::new(-1.0, 1.0, 1.0),
    @tmath.Vec3::new(1.0, -1.0, -1.0),
    @tmath.Vec3::new(1.0, -1.0, 1.0),
    @tmath.Vec3::new(1.0, 1.0, -1.0),
    @tmath.Vec3::new(1.0, 1.0, 1.0),
    @tmath.Vec3::new(0.0, -r, -t),
    @tmath.Vec3::new(0.0, -r, t),
    @tmath.Vec3::new(0.0, r, -t),
    @tmath.Vec3::new(0.0, r, t),
    @tmath.Vec3::new(-r, -t, 0.0),
    @tmath.Vec3::new(-r, t, 0.0),
    @tmath.Vec3::new(r, -t, 0.0),
    @tmath.Vec3::new(r, t, 0.0),
    @tmath.Vec3::new(-t, 0.0, -r),
    @tmath.Vec3::new(t, 0.0, -r),
    @tmath.Vec3::new(-t, 0.0, r),
    @tmath.Vec3::new(t, 0.0, r),
  ]
  let indices : Array[Int] = [
    3, 11, 7, 3, 7, 15, 3, 15, 13, 7, 19, 17, 7, 17, 6, 7, 6, 15, 17, 4, 8, 17,
    8, 10, 17, 10, 6, 8, 0, 16, 8, 16, 2, 8, 2, 10, 0, 12, 1, 0, 1, 18, 0, 18,
    16, 6, 10, 2, 6, 2, 13, 6, 13, 15, 2, 16, 18, 2, 18, 3, 2, 3, 13, 18, 1, 9,
    18, 9, 11, 18, 11, 3, 4, 14, 12, 4, 12, 0, 4, 0, 8, 11, 9, 5, 11, 5, 19, 11,
    19, 7, 19, 5, 14, 19, 14, 4, 19, 4, 17, 1, 12, 14, 1, 14, 5, 1, 5, 9,
  ]
  polyhedron(vertices, indices, radius~, detail~)
}

///|
/// Regular icosahedron.
pub fn icosahedron(radius? : Float = 1.0, detail? : Int = 0) -> MeshData {
  let t : Float = (1.0 + @tmath.sqrt(5.0)) / 2.0
  let vertices : Array[@tmath.Vec3] = [
    @tmath.Vec3::new(-1.0, t, 0.0),
    @tmath.Vec3::new(1.0, t, 0.0),
    @tmath.Vec3::new(-1.0, -t, 0.0),
    @tmath.Vec3::new(1.0, -t, 0.0),
    @tmath.Vec3::new(0.0, -1.0, t),
    @tmath.Vec3::new(0.0, 1.0, t),
    @tmath.Vec3::new(0.0, -1.0, -t),
    @tmath.Vec3::new(0.0, 1.0, -t),
    @tmath.Vec3::new(t, 0.0, -1.0),
    @tmath.Vec3::new(t, 0.0, 1.0),
    @tmath.Vec3::new(-t, 0.0, -1.0),
    @tmath.Vec3::new(-t, 0.0, 1.0),
  ]
  let indices : Array[Int] = [
    0, 11, 5, 0, 5, 1, 0, 1, 7, 0, 7, 10, 0, 10, 11, 1, 5, 9, 5, 11, 4, 11, 10,
    2, 10, 7, 6, 7, 1, 8, 3, 9, 4, 3, 4, 2, 3, 2, 6, 3, 6, 8, 3, 8, 9, 4, 9,
    5, 2, 4, 11, 6, 2, 10, 8, 6, 7, 9, 8, 1,
  ]
  polyhedron(vertices, indices, radius~, detail~)
}
