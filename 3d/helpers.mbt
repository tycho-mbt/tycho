// Scene helpers built from plain line lists.
//
// These are the three.js `GridHelper` / `AxesHelper` equivalents. The geometry
// stays in `tycho_geometry::LineData` (pure data, no GPU), so the same builders
// are usable headless and testable without a device; the renderer entry points
// only upload and attach a node.

///|
/// Build a `LineData` from a position / index pair.
fn line_data_of(
  positions : Array[@tmath.Vec3],
  indices : Array[UInt],
) -> @tgeo.LineData {
  @tgeo.LineData::new(FixedArray::from_array(positions), FixedArray::from_array(indices))
}

///|
/// Square grid on the XZ plane, centred on the origin (three.js `GridHelper`).
/// `size` is the full edge length; `divisions` is the number of cells per side.
pub fn grid_line_data(
  size? : Float = 10.0,
  divisions? : Int = 10,
) -> @tgeo.LineData {
  let n = if divisions < 1 { 1 } else { divisions }
  let s : Float = if size <= 0.0 { 1.0 } else { size }
  let half : Float = s * 0.5
  let step : Float = s / f_of_int(n)
  let pos : Array[@tmath.Vec3] = []
  let idx : Array[UInt] = []
  for i = 0; i <= n; i = i + 1 {
    let p = -half + f_of_int(i) * step
    let a = pos.length().reinterpret_as_uint()
    pos.push(@tmath.Vec3::new(p, 0.0, -half))
    pos.push(@tmath.Vec3::new(p, 0.0, half))
    idx.push(a)
    idx.push(a + (1 : UInt))
    let b = pos.length().reinterpret_as_uint()
    pos.push(@tmath.Vec3::new(-half, 0.0, p))
    pos.push(@tmath.Vec3::new(half, 0.0, p))
    idx.push(b)
    idx.push(b + (1 : UInt))
  }
  line_data_of(pos, idx)
}

///|
/// One segment from the origin along +Z (the reference axis that `add_axes`
/// rotates into X and Y).
pub fn axis_line_data(size? : Float = 1.0) -> @tgeo.LineData {
  let s : Float = if size <= 0.0 { 1.0 } else { size }
  line_data_of(
    [@tmath.Vec3::zero(), @tmath.Vec3::new(0.0, 0.0, s)],
    [(0 : UInt), (1 : UInt)],
  )
}

///|
/// The twelve edges of an axis-aligned box, as a line list.
pub fn aabb_line_data(box : @tmath.Aabb3) -> @tgeo.LineData {
  let mn = box.min
  let mx = box.max
  let c : Array[@tmath.Vec3] = [
    @tmath.Vec3::new(mn.x, mn.y, mn.z),
    @tmath.Vec3::new(mx.x, mn.y, mn.z),
    @tmath.Vec3::new(mx.x, mx.y, mn.z),
    @tmath.Vec3::new(mn.x, mx.y, mn.z),
    @tmath.Vec3::new(mn.x, mn.y, mx.z),
    @tmath.Vec3::new(mx.x, mn.y, mx.z),
    @tmath.Vec3::new(mx.x, mx.y, mx.z),
    @tmath.Vec3::new(mn.x, mx.y, mx.z),
  ]
  let edges : Array[(Int, Int)] = [
    (0, 1), (1, 2), (2, 3), (3, 0),
    (4, 5), (5, 6), (6, 7), (7, 4),
    (0, 4), (1, 5), (2, 6), (3, 7),
  ]
  let idx : Array[UInt] = []
  for e in edges {
    idx.push(e.0.reinterpret_as_uint())
    idx.push(e.1.reinterpret_as_uint())
  }
  line_data_of(c, idx)
}

///|
/// Closed circle of segments on the XZ plane (a ground ring / radius gizmo).
pub fn circle_line_data(
  radius? : Float = 1.0,
  segments? : Int = 32,
) -> @tgeo.LineData {
  let r : Float = if radius <= 0.0 { 1.0 } else { radius }
  let n = if segments < 3 { 3 } else { segments }
  let pos : Array[@tmath.Vec3] = []
  let idx : Array[UInt] = []
  for i = 0; i < n; i = i + 1 {
    let a = f_of_int(i) / f_of_int(n) * (2.0 : Float) * @tmath.PI
    pos.push(@tmath.Vec3::new(@tmath.cos(a) * r, 0.0, @tmath.sin(a) * r))
  }
  for i = 0; i < n; i = i + 1 {
    idx.push(i.reinterpret_as_uint())
    idx.push(((i + 1) % n).reinterpret_as_uint())
  }
  line_data_of(pos, idx)
}

///|
/// Upload `grid_line_data` and attach it as a line node (three.js
/// `GridHelper`). Returns the scene node.
pub fn Renderer3D::add_grid(
  self : Renderer3D,
  scene : Scene,
  size? : Float = 10.0,
  divisions? : Int = 10,
  color? : @tmath.Vec4 = @tmath.Vec4::new(0.16, 0.16, 0.16, 1.0),
  parent? : NodeId,
  name? : String = "grid",
) -> NodeId raise {
  let lines = self.upload_lines(grid_line_data(size~, divisions~))
  self.create_line_node(
    scene,
    lines,
    material=LineMaterial::new(color=color.truncate()),
    parent?=parent,
    name=name,
  )
}

///|
/// Attach a red/green/blue axis triad at the origin (three.js `AxesHelper`).
/// One line list is uploaded and shared by three nodes rotated into place;
/// returns the X, Y and Z axis nodes.
pub fn Renderer3D::add_axes(
  self : Renderer3D,
  scene : Scene,
  size? : Float = 1.0,
  parent? : NodeId,
) -> (NodeId, NodeId, NodeId) raise {
  let lines = self.upload_lines(axis_line_data(size~))
  let x = self.create_line_node(
    scene,
    lines,
    material=LineMaterial::new(color=srgb(1.0, 0.2, 0.2).truncate()),
    transform=@tmath.Transform::from_rotation(
      @tmath.Quat::from_rotation_y(@tmath.FRAC_PI_2),
    ),
    parent?=parent,
    name="axis+x",
  )
  let y = self.create_line_node(
    scene,
    lines,
    material=LineMaterial::new(color=srgb(0.3, 1.0, 0.3).truncate()),
    transform=@tmath.Transform::from_rotation(
      @tmath.Quat::from_rotation_x(-@tmath.FRAC_PI_2),
    ),
    parent?=parent,
    name="axis+y",
  )
  let z = self.create_line_node(
    scene,
    lines,
    material=LineMaterial::new(color=srgb(0.3, 0.5, 1.0).truncate()),
    parent?=parent,
    name="axis+z",
  )
  (x, y, z)
}
