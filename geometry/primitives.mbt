// Planar parametric primitives: box, plane, circle, ring.
//
// Conventions (lifelong, see roadmap/adr-003):
//   - right-handed, +Y up, -Z forward;
//   - CCW is the front face;
//   - UV (0,0) is the top-left of the image (glTF / Vulkan convention).

///|
fn f_of_int(i : Int) -> Float {
  Float::from_double(i.to_double())
}

///|
fn clamp_segs(v : Int, lo : Int) -> Int {
  if v < lo {
    lo
  } else {
    v
  }
}

///|
/// Internal mesh accumulator. Generators append vertices / triangles and then
/// call `build` once; arrays are converted to `FixedArray` at the end.
priv struct MeshBuilder {
  positions : Array[@tmath.Vec3]
  normals : Array[@tmath.Vec3]
  uvs : Array[@tmath.Vec2]
  indices : Array[UInt]
  groups : Array[MeshGroup]
}

///|
fn MeshBuilder::new() -> MeshBuilder {
  { positions: [], normals: [], uvs: [], indices: [], groups: [] }
}

///|
fn MeshBuilder::vertex(
  self : MeshBuilder,
  p : @tmath.Vec3,
  n : @tmath.Vec3,
  uv : @tmath.Vec2,
) -> UInt {
  let idx = self.positions.length().reinterpret_as_uint()
  self.positions.push(p)
  self.normals.push(n)
  self.uvs.push(uv)
  idx
}

///|
fn MeshBuilder::tri(self : MeshBuilder, a : UInt, b : UInt, c : UInt) -> Unit {
  self.indices.push(a)
  self.indices.push(b)
  self.indices.push(c)
}

///|
/// Quad `(a, b, c, d)` laid out CCW: `a` -> `+u` -> `+u+v` -> `+v`.
fn MeshBuilder::quad(self : MeshBuilder, a : UInt, b : UInt, c : UInt, d : UInt) -> Unit {
  self.tri(a, b, c)
  self.tri(a, c, d)
}

///|
fn MeshBuilder::group_start(self : MeshBuilder, material_slot : Int) -> Int {
  self.groups.push(MeshGroup::new(self.indices.length(), 0, material_slot))
  self.groups.length() - 1
}

///|
fn MeshBuilder::group_end(self : MeshBuilder, gi : Int) -> Unit {
  let g = self.groups[gi]
  self.groups[gi] = MeshGroup::new(g.start, self.indices.length() - g.start, g.material_slot)
}

///|
fn MeshBuilder::build(self : MeshBuilder) -> MeshData {
  MeshData::new(
    FixedArray::from_array(self.positions),
    FixedArray::from_array(self.normals),
    FixedArray::from_array(self.uvs),
    FixedArray::from_array(self.indices),
  ).with_groups(self.groups)
}

///|
/// Helper: add a subdivided rectangle with `cross(u_axis, v_axis) == normal`,
/// centered at `center`. Emits CCW triangles and (u, 1-v) UVs. No groups.
fn add_grid_face(
  builder : MeshBuilder,
  u_axis : @tmath.Vec3,
  v_axis : @tmath.Vec3,
  normal : @tmath.Vec3,
  u_size : Float,
  v_size : Float,
  u_segs : Int,
  v_segs : Int,
  center : @tmath.Vec3,
) -> Unit {
  let usize = clamp_segs(u_segs, 1)
  let vseg = clamp_segs(v_segs, 1)
  let base = builder.positions.length()
  let row = usize + 1
  for iy = 0; iy <= vseg; iy = iy + 1 {
    let v = f_of_int(iy) / f_of_int(vseg)
    for ix = 0; ix <= usize; ix = ix + 1 {
      let u = f_of_int(ix) / f_of_int(usize)
      let p = center + u_axis.scale((u - 0.5) * u_size) + v_axis.scale((v - 0.5) * v_size)
      let _ = builder.vertex(p, normal, @tmath.Vec2::new(u, 1.0 - v))
    }
  }
  for iy = 0; iy < vseg; iy = iy + 1 {
    for ix = 0; ix < usize; ix = ix + 1 {
      let a = base + iy * row + ix
      let b = a + 1
      let d = a + row
      let c = d + 1
      builder.quad(a.reinterpret_as_uint(), b.reinterpret_as_uint(), c.reinterpret_as_uint(), d.reinterpret_as_uint())
    }
  }
}

///|
/// Axis-aligned box centered at the origin.
/// Group layout matches three.js `BoxGeometry`: +X, -X, +Y, -Y, +Z, -Z.
pub fn box(
  width? : Float = 1.0,
  height? : Float = 1.0,
  depth? : Float = 1.0,
  width_segments? : Int = 1,
  height_segments? : Int = 1,
  depth_segments? : Int = 1,
) -> MeshData {
  let builder = MeshBuilder::new()
  let hw = width * 0.5
  let hh = height * 0.5
  let hd = depth * 0.5
  let x = @tmath.Vec3::unit_x()
  let y = @tmath.Vec3::unit_y()
  let z = @tmath.Vec3::unit_z()
  let nx = @tmath.Vec3::neg_x()
  let nz = @tmath.Vec3::neg_z()
  // +X: u = -Z, v = +Y
  let g0 = builder.group_start(0)
  add_grid_face(builder, nz, y, x, depth, height, depth_segments, height_segments, @tmath.Vec3::new(hw, 0.0, 0.0))
  builder.group_end(g0)
  // -X: u = +Z, v = +Y
  let g1 = builder.group_start(1)
  add_grid_face(builder, z, y, nx, depth, height, depth_segments, height_segments, @tmath.Vec3::new(-hw, 0.0, 0.0))
  builder.group_end(g1)
  // +Y: u = +X, v = -Z
  let g2 = builder.group_start(2)
  add_grid_face(builder, x, nz, y, width, depth, width_segments, depth_segments, @tmath.Vec3::new(0.0, hh, 0.0))
  builder.group_end(g2)
  // -Y: u = +X, v = +Z
  let g3 = builder.group_start(3)
  add_grid_face(builder, x, z, @tmath.Vec3::neg_y(), width, depth, width_segments, depth_segments, @tmath.Vec3::new(0.0, -hh, 0.0))
  builder.group_end(g3)
  // +Z: u = +X, v = +Y
  let g4 = builder.group_start(4)
  add_grid_face(builder, x, y, z, width, height, width_segments, height_segments, @tmath.Vec3::new(0.0, 0.0, hd))
  builder.group_end(g4)
  // -Z: u = -X, v = +Y
  let g5 = builder.group_start(5)
  add_grid_face(builder, nx, y, nz, width, height, width_segments, height_segments, @tmath.Vec3::new(0.0, 0.0, -hd))
  builder.group_end(g5)
  builder.build()
}

///|
/// Plane in the XY plane facing +Z, centered at the origin.
pub fn plane(
  width? : Float = 1.0,
  height? : Float = 1.0,
  width_segments? : Int = 1,
  height_segments? : Int = 1,
) -> MeshData {
  let builder = MeshBuilder::new()
  add_grid_face(
    builder,
    @tmath.Vec3::unit_x(),
    @tmath.Vec3::unit_y(),
    @tmath.Vec3::unit_z(),
    width,
    height,
    width_segments,
    height_segments,
    @tmath.Vec3::zero(),
  )
  builder.build()
}

///|
/// Disc (or disc sector) in the XY plane facing +Z. The seam vertex is
/// duplicated so UVs stay in `[0, 1]` without wrapping.
pub fn circle(
  radius? : Float = 1.0,
  segments? : Int = 32,
  theta_start? : Float = 0.0,
  theta_length? : Float = @tmath.TAU,
) -> MeshData {
  let segs = clamp_segs(segments, 3)
  let builder = MeshBuilder::new()
  let normal = @tmath.Vec3::unit_z()
  let center = builder.vertex(
    @tmath.Vec3::zero(),
    normal,
    @tmath.Vec2::new(0.5, 0.5),
  )
  let rim : Array[UInt] = []
  for i = 0; i <= segs; i = i + 1 {
    let u = f_of_int(i) / f_of_int(segs)
    let theta = theta_start + u * theta_length
    let (s, c) = @tmath.sin_cos(theta)
    let p = @tmath.Vec3::new(c * radius, s * radius, 0.0)
    let uv = @tmath.Vec2::new(0.5 + 0.5 * c, 0.5 + 0.5 * s)
    rim.push(builder.vertex(p, normal, uv))
  }
  for i = 0; i < segs; i = i + 1 {
    builder.tri(center, rim[i], rim[i + 1])
  }
  builder.build()
}

///|
/// Flat annulus (or annulus sector) in the XY plane facing +Z. `phi_segments`
/// subdivides radially between `inner` and `outer`.
pub fn ring(
  inner? : Float = 0.5,
  outer? : Float = 1.0,
  theta_segments? : Int = 32,
  phi_segments? : Int = 1,
  theta_start? : Float = 0.0,
  theta_length? : Float = @tmath.TAU,
) -> MeshData {
  let segs = clamp_segs(theta_segments, 3)
  let bands = clamp_segs(phi_segments, 1)
  let builder = MeshBuilder::new()
  let normal = @tmath.Vec3::unit_z()
  let inv_outer : Float = if outer.abs() > (1.0e-12 : Float) {
    1.0 / outer
  } else {
    0.0
  }
  let radial_step = (outer - inner) / f_of_int(bands)
  for j = 0; j <= bands; j = j + 1 {
    let radius = inner + radial_step * f_of_int(j)
    for i = 0; i <= segs; i = i + 1 {
      let u = f_of_int(i) / f_of_int(segs)
      let theta = theta_start + u * theta_length
      let (s, c) = @tmath.sin_cos(theta)
      let p = @tmath.Vec3::new(c * radius, s * radius, 0.0)
      let uv = @tmath.Vec2::new(
        0.5 + 0.5 * p.x * inv_outer,
        0.5 + 0.5 * p.y * inv_outer,
      )
      let _ = builder.vertex(p, normal, uv)
    }
  }
  let row = segs + 1
  for j = 0; j < bands; j = j + 1 {
    for i = 0; i < segs; i = i + 1 {
      let a = (i + j * row).reinterpret_as_uint()
      let b = (i + (j + 1) * row).reinterpret_as_uint()
      let c = (i + 1 + (j + 1) * row).reinterpret_as_uint()
      let d = (i + 1 + j * row).reinterpret_as_uint()
      builder.tri(a, b, d)
      builder.tri(b, c, d)
    }
  }
  builder.build()
}
