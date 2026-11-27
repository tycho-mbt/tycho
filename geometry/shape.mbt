// 2D shapes and their flat triangulation (three.js `ShapeGeometry`).
//
// A `Shape2D` is data only: an outer contour plus hole contours, both given as
// already-flattened polylines in the XY plane. Curve flattening belongs to the
// producer (`tycho_2d` paths, importers); this module never sees a curve type.

///|
/// A planar polygon with holes. The contour is closed implicitly (the last
/// point must not repeat the first).
pub(all) struct Shape2D {
  contour : Array[@tmath.Vec2]
  holes : Array[Array[@tmath.Vec2]]
}

///|
pub fn Shape2D::new(
  contour : Array[@tmath.Vec2],
  holes? : Array[Array[@tmath.Vec2]] = [],
) -> Shape2D {
  { contour, holes }
}

///|
pub fn Shape2D::is_empty(self : Shape2D) -> Bool {
  self.contour.length() < 3
}

///|
/// Signed shoelace area: positive for counter-clockwise rings.
pub fn polygon_area(points : Array[@tmath.Vec2]) -> Float {
  let n = points.length()
  if n < 3 {
    return 0.0
  }
  let mut sum : Float = 0.0
  let mut j = n - 1
  for i = 0; i < n; i = i + 1 {
    sum = sum + (points[j].x * points[i].y - points[i].x * points[j].y)
    j = i
  }
  sum * 0.5
}

///|
pub fn is_clockwise(points : Array[@tmath.Vec2]) -> Bool {
  polygon_area(points) < 0.0
}

///|
fn reversed_ring(points : Array[@tmath.Vec2]) -> Array[@tmath.Vec2] {
  let out : Array[@tmath.Vec2] = []
  for i = points.length() - 1; i >= 0; i = i - 1 {
    out.push(points[i])
  }
  out
}

///|
/// Force a ring into the requested winding order.
fn normalize_ring(
  points : Array[@tmath.Vec2],
  clockwise : Bool,
) -> Array[@tmath.Vec2] {
  if is_clockwise(points) == clockwise {
    points
  } else {
    reversed_ring(points)
  }
}

///|
/// Triangulate one shape. Returns positions (z = 0), UVs (planar, equal to the
/// shape coordinates) and CCW indices into them.
fn shape_parts(
  s : Shape2D,
) -> (Array[@tmath.Vec3], Array[@tmath.Vec2], Array[UInt]) {
  let positions : Array[@tmath.Vec3] = []
  let uvs : Array[@tmath.Vec2] = []
  if s.is_empty() {
    return (positions, uvs, [])
  }
  let contour = normalize_ring(s.contour, false)
  let holes : Array[Array[@tmath.Vec2]] = []
  for hole in s.holes {
    holes.push(normalize_ring(hole, true))
  }
  let verts : Array[@tmath.Vec2] = []
  for p in contour {
    verts.push(p)
  }
  for hole in holes {
    for p in hole {
      verts.push(p)
    }
  }
  for p in verts {
    positions.push(@tmath.Vec3::new(p.x, p.y, 0.0))
    uvs.push(p)
  }
  let faces = triangulate(contour, holes)
  let indices : Array[UInt] = []
  let mut t = 0
  while t + 2 < faces.length() {
    let i0 = faces[t].reinterpret_as_int()
    let i1 = faces[t + 1].reinterpret_as_int()
    let i2 = faces[t + 2].reinterpret_as_int()
    let a = verts[i0]
    let b = verts[i1]
    let c = verts[i2]
    let cross = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
    if cross >= 0.0 {
      indices.push(faces[t])
      indices.push(faces[t + 1])
      indices.push(faces[t + 2])
    } else {
      // Normalize winding so every face points at +Z regardless of how the
      // caller ordered the rings.
      indices.push(faces[t])
      indices.push(faces[t + 2])
      indices.push(faces[t + 1])
    }
    t = t + 3
  }
  (positions, uvs, indices)
}

///|
/// Flat triangulation of one shape in the XY plane, facing +Z.
pub fn shape(s : Shape2D) -> MeshData {
  let (positions, uvs, indices) = shape_parts(s)
  let normals : FixedArray[@tmath.Vec3] = FixedArray::make(
    positions.length(),
    @tmath.Vec3::unit_z(),
  )
  MeshData::new(
    FixedArray::from_array(positions),
    normals,
    FixedArray::from_array(uvs),
    FixedArray::from_array(indices),
  )
}

///|
/// Triangulate several shapes into one mesh; each shape becomes one group
/// (`material_slot` = its index), matching three.js `ShapeGeometry`.
pub fn shapes(items : Array[Shape2D]) -> MeshData {
  let positions : Array[@tmath.Vec3] = []
  let uvs : Array[@tmath.Vec2] = []
  let indices : Array[UInt] = []
  let groups : Array[MeshGroup] = []
  for k = 0; k < items.length(); k = k + 1 {
    let (part_pos, part_uv, part_idx) = shape_parts(items[k])
    if part_idx.length() > 0 {
      let base = positions.length()
      let start = indices.length()
      for p in part_pos {
        positions.push(p)
      }
      for uv in part_uv {
        uvs.push(uv)
      }
      for index in part_idx {
        indices.push(index + base.reinterpret_as_uint())
      }
      groups.push(MeshGroup::new(start, indices.length() - start, k))
    }
  }
  let normals : FixedArray[@tmath.Vec3] = FixedArray::make(
    positions.length(),
    @tmath.Vec3::unit_z(),
  )
  MeshData::new(
    FixedArray::from_array(positions),
    normals,
    FixedArray::from_array(uvs),
    FixedArray::from_array(indices),
  ).with_groups(groups)
}
