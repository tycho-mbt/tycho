// `extrude` — turn a flat `Shape2D` into a solid (three.js `ExtrudeGeometry`).
//
// Straight extrusion moves the shape along +Z in `steps` slices; path
// extrusion moves it along a sampled 3D polyline using the same
// parallel-transport frames as `tube`, so the cross-section does not twist.
//
// Bevels follow three.js: `bevel_segments` rings expand the outline from the
// lid contour (offset by `bevel_offset`) out to the body contour (offset by
// `bevel_size + bevel_offset`) across `bevel_thickness` at both ends. Unlike
// three.js the bevel is opt-in (`bevel_enabled = false` by default) so existing
// callers keep their exact geometry; path extrusion ignores it, as in three.js.
//
// Groups follow three.js: `0` = both lids, `1` = side walls.

///|
/// Extrusion parameters. When `extrude_path` is set it wins over `depth` and
/// disables the bevel.
pub(all) struct ExtrudeOptions {
  depth : Float
  steps : Int
  extrude_path : Array[@tmath.Vec3]?
  bevel_enabled : Bool
  bevel_thickness : Float
  bevel_size : Float
  bevel_offset : Float
  bevel_segments : Int
}

///|
pub fn ExtrudeOptions::new(
  depth? : Float = 1.0,
  steps? : Int = 1,
  extrude_path? : Array[@tmath.Vec3]? = None,
  bevel_enabled? : Bool = false,
  bevel_thickness? : Float = 0.2,
  bevel_size? : Float = 0.1,
  bevel_offset? : Float = 0.0,
  bevel_segments? : Int = 3,
) -> ExtrudeOptions {
  {
    depth,
    steps,
    extrude_path,
    bevel_enabled,
    bevel_thickness,
    bevel_size,
    bevel_offset,
    bevel_segments,
  }
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
/// Miter direction for one outline vertex, ported from three.js
/// `ExtrudeGeometry.getBevelVec`.
///
/// The result offsets the **left** side of the contour (three.js normalizes the
/// contour to clockwise); callers walking a CCW ring negate it.
fn bevel_movement(
  current : @tmath.Vec2,
  prev : @tmath.Vec2,
  next : @tmath.Vec2,
) -> @tmath.Vec2 {
  let vpx = current.x - prev.x
  let vpy = current.y - prev.y
  let vnx = next.x - current.x
  let vny = next.y - current.y
  let prev_len_sq = vpx * vpx + vpy * vpy
  let next_len_sq = vnx * vnx + vny * vny
  // Degenerate neighbours would divide by zero; fall back to one edge's left
  // normal so the mesh stays finite (three.js does not guard this).
  if prev_len_sq <= (1.0e-12 : Float) || next_len_sq <= (1.0e-12 : Float) {
    let (dx, dy) = if prev_len_sq > (1.0e-12 : Float) {
      (vpx, vpy)
    } else {
      (vnx, vny)
    }
    let len = @tmath.sqrt(dx * dx + dy * dy)
    if len <= (1.0e-12 : Float) {
      return @tmath.Vec2::zero()
    }
    return @tmath.Vec2::new(-dy / len, dx / len)
  }
  let prev_len = @tmath.sqrt(prev_len_sq)
  let next_len = @tmath.sqrt(next_len_sq)
  let cross = vpx * vny - vpy * vnx
  if cross.abs() > (1.0e-12 : Float) {
    // Intersection of the two edges shifted one unit to the left.
    let shift_prev_x = prev.x - vpy / prev_len
    let shift_prev_y = prev.y + vpx / prev_len
    let shift_next_x = next.x - vny / next_len
    let shift_next_y = next.y + vnx / next_len
    let sf = ((shift_next_x - shift_prev_x) * vny -
      (shift_next_y - shift_prev_y) * vnx) /
      cross
    let tx = shift_prev_x + vpx * sf - current.x
    let ty = shift_prev_y + vpy * sf - current.y
    let trans_len_sq = tx * tx + ty * ty
    if trans_len_sq <= 2.0 {
      // Deliberately not normalized: sharp corners get a longer miter.
      return @tmath.Vec2::new(tx, ty)
    }
    let shrink = @tmath.sqrt(trans_len_sq / 2.0)
    return @tmath.Vec2::new(tx / shrink, ty / shrink)
  }
  // Collinear edges: straight sequence (unit normal) or a spike.
  let direction_eq = if vpx > (1.0e-6 : Float) {
    vnx > (1.0e-6 : Float)
  } else if vpx < (-1.0e-6 : Float) {
    vnx < (-1.0e-6 : Float)
  } else {
    @tmath.sign_f(vpy) == @tmath.sign_f(vny)
  }
  if direction_eq {
    return @tmath.Vec2::new(-vpy / prev_len, vpx / prev_len)
  }
  let shrink = @tmath.sqrt(prev_len_sq / 2.0)
  @tmath.Vec2::new(vpx / shrink, vpy / shrink)
}

///|
/// Outward miter vectors for a normalized ring (contour CCW / holes CW).
fn bevel_movements(ring : Array[@tmath.Vec2]) -> Array[@tmath.Vec2] {
  let out : Array[@tmath.Vec2] = []
  let n = ring.length()
  for i = 0; i < n; i = i + 1 {
    let prev = ring[(i + n - 1) % n]
    let next = ring[(i + 1) % n]
    let m = bevel_movement(ring[i], prev, next)
    // three.js pushes the left side (clockwise contours); ours are CCW, where
    // the material boundary grows along -left.
    out.push(@tmath.Vec2::new(-m.x, -m.y))
  }
  out
}

///|
/// One flat slice at height `z`, with every vertex offset by
/// `movement * offset` (bevel shrink/expand).
fn offset_layer(
  base : Array[@tmath.Vec2],
  movements : Array[@tmath.Vec2],
  offset : Float,
  z : Float,
) -> Array[@tmath.Vec3] {
  let row : Array[@tmath.Vec3] = []
  for i = 0; i < base.length(); i = i + 1 {
    row.push(
      @tmath.Vec3::new(
        base[i].x + movements[i].x * offset,
        base[i].y + movements[i].y * offset,
        z,
      ),
    )
  }
  row
}

///|
/// Slices for a straight extrusion without bevel.
fn extrude_plain_layers(
  base : Array[@tmath.Vec2],
  steps : Int,
  depth : Float,
) -> Array[Array[@tmath.Vec3]] {
  let layers : Array[Array[@tmath.Vec3]] = []
  for l = 0; l <= steps; l = l + 1 {
    let z = depth * f_of_int(l) / f_of_int(steps)
    let row : Array[@tmath.Vec3] = []
    for p in base {
      row.push(@tmath.Vec3::new(p.x, p.y, z))
    }
    layers.push(row)
  }
  layers
}

///|
/// Slices for a beveled straight extrusion: front bevel, body, back bevel.
fn extrude_beveled_layers(
  base : Array[@tmath.Vec2],
  movements : Array[@tmath.Vec2],
  steps : Int,
  depth : Float,
  thickness : Float,
  size : Float,
  offset : Float,
  bands : Int,
) -> Array[Array[@tmath.Vec3]] {
  let layers : Array[Array[@tmath.Vec3]] = []
  for b = 0; b < bands; b = b + 1 {
    let t = f_of_int(b) / f_of_int(bands)
    let (sin_t, cos_t) = @tmath.sin_cos(t * @tmath.FRAC_PI_2)
    layers.push(
      offset_layer(base, movements, size * sin_t + offset, -thickness * cos_t),
    )
  }
  let body_offset = size + offset
  for l = 0; l <= steps; l = l + 1 {
    let z = depth * f_of_int(l) / f_of_int(steps)
    layers.push(offset_layer(base, movements, body_offset, z))
  }
  for b = bands - 1; b >= 0; b = b - 1 {
    let t = f_of_int(b) / f_of_int(bands)
    let (sin_t, cos_t) = @tmath.sin_cos(t * @tmath.FRAC_PI_2)
    layers.push(
      offset_layer(base, movements, size * sin_t + offset, depth + thickness * cos_t),
    )
  }
  layers
}

///|
/// Slices along a sampled path (frames from `sweep.mbt`). Bevel is not
/// supported on this path, matching three.js.
fn extrude_path_layers(
  base : Array[@tmath.Vec2],
  steps : Int,
  path : Array[@tmath.Vec3],
) -> Array[Array[@tmath.Vec3]] {
  let layers : Array[Array[@tmath.Vec3]] = []
  let points = polyline_resample(path, steps, false)
  let (normals, binormals) = polyline_frames(points, false)
  for l = 0; l <= steps; l = l + 1 {
    let row : Array[@tmath.Vec3] = []
    for p in base {
      row.push(points[l] + normals[l].scale(p.x) + binormals[l].scale(p.y))
    }
    layers.push(row)
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
/// Emit one shape's lids (group slot 0) and walls (group slot 1) into
/// `builder`. Empty shapes are skipped so multi-shape extrusion can share one
/// accumulator.
fn extrude_shape_into(
  builder : MeshBuilder,
  s : Shape2D,
  options : ExtrudeOptions,
) -> Unit {
  if s.is_empty() {
    return
  }
  let steps = if options.steps < 1 { 1 } else { options.steps }
  let path = match options.extrude_path {
    Some(p) => p
    None => ([] : Array[@tmath.Vec3])
  }
  let use_path = path.length() >= 2
  let bevel = options.bevel_enabled && !use_path
  let bands = if bevel { clamp_segs(options.bevel_segments, 1) } else { 0 }
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
  // Outward miter vectors and the lid outline (offset by `bevel_offset`).
  let movements : Array[@tmath.Vec2] = []
  for ring in rings {
    if bevel {
      for m in bevel_movements(ring) {
        movements.push(m)
      }
    } else {
      for i = 0; i < ring.length(); i = i + 1 {
        movements.push(@tmath.Vec2::zero())
      }
    }
  }
  let lid_offset = if bevel { options.bevel_offset } else { 0.0 }
  let lid_verts : Array[@tmath.Vec2] = []
  for i = 0; i < verts.length(); i = i + 1 {
    lid_verts.push(
      @tmath.Vec2::new(
        verts[i].x + movements[i].x * lid_offset,
        verts[i].y + movements[i].y * lid_offset,
      ),
    )
  }
  let lid_contour : Array[@tmath.Vec2] = []
  for i = 0; i < contour.length(); i = i + 1 {
    lid_contour.push(lid_verts[i])
  }
  let lid_holes : Array[Array[@tmath.Vec2]] = []
  let mut lid_offset_index = contour.length()
  for hole in holes {
    let ring : Array[@tmath.Vec2] = []
    for i = 0; i < hole.length(); i = i + 1 {
      ring.push(lid_verts[lid_offset_index + i])
    }
    lid_holes.push(ring)
    lid_offset_index = lid_offset_index + hole.length()
  }
  let layers = if use_path {
    extrude_path_layers(verts, steps, path)
  } else if bevel {
    extrude_beveled_layers(
      verts,
      movements,
      steps,
      options.depth,
      options.bevel_thickness,
      options.bevel_size,
      options.bevel_offset,
      bands,
    )
  } else {
    extrude_plain_layers(verts, steps, options.depth)
  }
  // Faces in shape space, forced to CCW so lids point at +Z / +T.
  let faces = triangulate(lid_contour, lid_holes)
  let lids : Array[UInt] = []
  let mut t = 0
  while t + 2 < faces.length() {
    let i0 = faces[t].reinterpret_as_int()
    let i1 = faces[t + 1].reinterpret_as_int()
    let i2 = faces[t + 2].reinterpret_as_int()
    let a = lid_verts[i0]
    let b = lid_verts[i1]
    let c = lid_verts[i2]
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
  let top = layers[layers.length() - 1]
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
      lid_verts[i2],
      lid_verts[i1],
      lid_verts[i0],
    )
    extrude_triangle(
      builder,
      top[i0],
      top[i1],
      top[i2],
      lid_verts[i0],
      lid_verts[i1],
      lid_verts[i2],
    )
    f = f + 3
  }
  builder.group_end(lid_group)
  // Side walls: one quad per ring edge per layer gap (bevel rings included).
  let side_group = builder.group_start(1)
  let gaps = layers.length() - 1
  let mut ring_offset = 0
  for ring in rings {
    let n = ring.length()
    let arc = ring_arc_lengths(ring)
    for i = 0; i < n; i = i + 1 {
      let j = (i + 1) % n
      let u0 = arc[i]
      let u1 = arc[i + 1]
      for l = 0; l < gaps; l = l + 1 {
        let v0 = f_of_int(l) / f_of_int(gaps)
        let v1 = f_of_int(l + 1) / f_of_int(gaps)
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
}

///|
/// Extrude one shape into a closed solid.
///
/// The contour is normalized to CCW and holes to CW, so lids face +Z and side
/// walls face outwards regardless of the caller's ring order. Groups match
/// three.js: `0` = lids, `1` = walls.
pub fn extrude(s : Shape2D, options? : ExtrudeOptions = ExtrudeOptions::new()) -> MeshData {
  let builder = MeshBuilder::new()
  extrude_shape_into(builder, s, options)
  let mesh = builder.build()
  mesh.compute_vertex_normals()
  mesh
}

///|
/// Extrude several shapes into one mesh (three.js `ExtrudeGeometry` accepts a
/// `Shape[]` too). Every shape contributes a lid group (`material_slot` 0) and
/// a wall group (`material_slot` 1), so one two-material setup covers them all.
pub fn extrude_shapes(
  items : Array[Shape2D],
  options? : ExtrudeOptions = ExtrudeOptions::new(),
) -> MeshData {
  let builder = MeshBuilder::new()
  for s in items {
    extrude_shape_into(builder, s, options)
  }
  let mesh = builder.build()
  mesh.compute_vertex_normals()
  mesh
}
