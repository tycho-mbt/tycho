// `extrude` — turn a flat `Shape2D` into a solid (three.js `ExtrudeGeometry`).
//
// Straight extrusion moves the shape along +Z in `steps` slices; path
// extrusion moves it along a sampled 3D polyline using the same
// parallel-transport frames as `tube`, so the cross-section does not twist.
//
// Bevels are intentionally out of scope (see ADR-003 G1 follow-up): the caps
// are always the flat shape and the side walls are straight quads.
//
// Groups follow three.js: `0` = both lids, `1` = side walls.

///|
/// Extrusion parameters. When `extrude_path` is set it wins over `depth`.
pub(all) struct ExtrudeOptions {
  depth : Float
  steps : Int
  extrude_path : Array[@tmath.Vec3]?
}

///|
pub fn ExtrudeOptions::new(
  depth? : Float = 1.0,
  steps? : Int = 1,
  extrude_path? : Array[@tmath.Vec3]? = None,
) -> ExtrudeOptions {
  { depth, steps, extrude_path }
}

///|
/// Perimeter arc length at each ring vertex, plus the closing total.
fn ring_arc_lengths(ring : Array[@tmath.Vec2]) -> Array[Float] {
  let out : Array[Float] = [0.0]
  let mut acc : Float = 0.0
  for i = 0; i < ring.length(); i = i + 1 {
    let j = if i + 1 < ring.length() { i + 1 } else { 0 }
    acc = acc + (ring[j] - ring[i]).length()
    out.push(acc)
  }
  out
}

///|
/// Build one 3D layer per extrusion step: `layers[l][v]` is the world position
/// of shape vertex `v` at slice `l`.
fn extrude_layers(
  verts : Array[@tmath.Vec2],
  steps : Int,
  depth : Float,
  path : Array[@tmath.Vec3],
) -> Array[Array[@tmath.Vec3]] {
  let layers : Array[Array[@tmath.Vec3]] = []
  if path.length() >= 2 {
    let points = polyline_resample(path, steps, false)
    let (normals, binormals) = polyline_frames(points, false)
    for l = 0; l <= steps; l = l + 1 {
      let row : Array[@tmath.Vec3] = []
      for p in verts {
        row.push(
          points[l] + normals[l].scale(p.x) + binormals[l].scale(p.y),
        )
      }
      layers.push(row)
    }
  } else {
    for l = 0; l <= steps; l = l + 1 {
      let z = depth * f_of_int(l) / f_of_int(steps)
      let row : Array[@tmath.Vec3] = []
      for p in verts {
        row.push(@tmath.Vec3::new(p.x, p.y, z))
      }
      layers.push(row)
    }
  }
  layers
}

///|
/// Emit one triangle with per-corner UVs.
fn extrude_triangle(
  builder : MeshBuilder,
  a : @tmath.Vec3,
  b : @tmath.Vec3,
  c : @tmath.Vec3,
  ua : @tmath.Vec2,
  ub : @tmath.Vec2,
  uc : @tmath.Vec2,
) -> Unit {
  let ia = builder.vertex(a, @tmath.Vec3::zero(), ua)
  let ib = builder.vertex(b, @tmath.Vec3::zero(), ub)
  let ic = builder.vertex(c, @tmath.Vec3::zero(), uc)
  builder.tri(ia, ib, ic)
}

///|
/// Extrude `s` into a closed solid.
///
/// The contour is normalized to CCW and holes to CW, so lids face +Z and side
/// walls face outwards regardless of the caller's ring order.
pub fn extrude(s : Shape2D, options? : ExtrudeOptions = ExtrudeOptions::new()) -> MeshData {
  let builder = MeshBuilder::new()
  if s.is_empty() {
    return builder.build()
  }
  let steps = if options.steps < 1 { 1 } else { options.steps }
  let path = match options.extrude_path {
    Some(p) => p
    None => ([] : Array[@tmath.Vec3])
  }
  let contour = normalize_ring(s.contour, false)
  let holes : Array[Array[@tmath.Vec2]] = []
  for hole in s.holes {
    holes.push(normalize_ring(hole, true))
  }
  // Shape vertex array and ring offsets, in the same order earcut sees them.
  let verts : Array[@tmath.Vec2] = []
  let rings : Array[Array[@tmath.Vec2]] = []
  rings.push(contour)
  for hole in holes {
    rings.push(hole)
  }
  for ring in rings {
    for p in ring {
      verts.push(p)
    }
  }
  let layers = extrude_layers(verts, steps, options.depth, path)
  // Faces in shape space, forced to CCW so lids point at +Z / +T.
  let faces = triangulate(contour, holes)
  let lids : Array[UInt] = []
  let mut t = 0
  while t + 2 < faces.length() {
    let i0 = faces[t].reinterpret_as_int()
    let i1 = faces[t + 1].reinterpret_as_int()
    let i2 = faces[t + 2].reinterpret_as_int()
    let a = verts[i0]
    let b = verts[i1]
    let c = verts[i2]
    let cross = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
    lids.push(faces[t])
    if cross >= 0.0 {
      lids.push(faces[t + 1])
      lids.push(faces[t + 2])
    } else {
      lids.push(faces[t + 2])
      lids.push(faces[t + 1])
    }
    t = t + 3
  }
  // Lids: bottom is reversed (faces away from the extrusion direction).
  let lid_group = builder.group_start(0)
  let bottom = layers[0]
  let top = layers[steps]
  let mut f = 0
  while f + 2 < lids.length() {
    let i0 = lids[f].reinterpret_as_int()
    let i1 = lids[f + 1].reinterpret_as_int()
    let i2 = lids[f + 2].reinterpret_as_int()
    extrude_triangle(
      builder,
      bottom[i2],
      bottom[i1],
      bottom[i0],
      verts[i2],
      verts[i1],
      verts[i0],
    )
    extrude_triangle(
      builder,
      top[i0],
      top[i1],
      top[i2],
      verts[i0],
      verts[i1],
      verts[i2],
    )
    f = f + 3
  }
  builder.group_end(lid_group)
  // Side walls: one quad per ring edge per step.
  let side_group = builder.group_start(1)
  let mut ring_offset = 0
  for ring in rings {
    let n = ring.length()
    let arc = ring_arc_lengths(ring)
    for i = 0; i < n; i = i + 1 {
      let j = (i + 1) % n
      let u0 = arc[i]
      let u1 = arc[i + 1]
      for l = 0; l < steps; l = l + 1 {
        let v0 = f_of_int(l) / f_of_int(steps)
        let v1 = f_of_int(l + 1) / f_of_int(steps)
        let a = layers[l][ring_offset + i]
        let b = layers[l][ring_offset + j]
        let c = layers[l + 1][ring_offset + j]
        let d = layers[l + 1][ring_offset + i]
        let ua = @tmath.Vec2::new(u0, v0)
        let ub = @tmath.Vec2::new(u1, v0)
        let uc = @tmath.Vec2::new(u1, v1)
        let ud = @tmath.Vec2::new(u0, v1)
        extrude_triangle(builder, a, b, c, ua, ub, uc)
        extrude_triangle(builder, a, c, d, ua, uc, ud)
      }
    }
    ring_offset = ring_offset + n
  }
  builder.group_end(side_group)
  let mesh = builder.build()
  mesh.compute_vertex_normals()
  mesh
}
