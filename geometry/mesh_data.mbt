// `MeshData` — the canonical CPU-side mesh container of laplaceliu/tycho_geometry.
//
// The layout is fixed on purpose: positions / normals / uv / u32 indices, plus
// optional tangents and vertex colors. Renderers (tycho_3d) can therefore
// upload a mesh without any vertex-layout negotiation. Applications that need
// a custom vertex format are expected to go through the raw RHI instead.

///|
/// One contiguous material range inside the index buffer.
/// `material_slot` is an application-defined index (three.js `geometry.groups`).
pub(all) struct MeshGroup {
  start : Int
  count : Int
  material_slot : Int
}

///|
pub fn MeshGroup::new(start : Int, count : Int, material_slot : Int) -> MeshGroup {
  { start, count, material_slot }
}

///|
///|
/// One additive morph target: per-vertex position deltas in mesh-local space.
pub(all) struct MorphTarget {
  positions : FixedArray[@tmath.Vec3]
}

///|
pub(all) struct MeshData {
  // Every per-vertex array except `indices` must match `vertex_count()`; the
  // fields are private so that invariant can only be broken inside this package
  // (or through the validated setters below).
  priv positions : FixedArray[@tmath.Vec3]
  priv mut normals : FixedArray[@tmath.Vec3]
  priv uvs : FixedArray[@tmath.Vec2]
  // Always 32-bit. `tycho_3d` may narrow to 16-bit on upload when possible.
  priv indices : FixedArray[UInt]
  // Filled by `compute_tangents`; `w` is the bitangent handedness sign.
  priv mut tangents : FixedArray[@tmath.Vec4]?
  // Optional linear-space vertex colors.
  priv mut colors : FixedArray[@tmath.Vec4]?
  // Optional GPU skinning: four joint indices and weights per vertex.
  priv mut skin_joints : FixedArray[@tmath.Vec4]?
  priv mut skin_weights : FixedArray[@tmath.Vec4]?
  // Additive position deltas; `tycho_3d` supports the first two on the GPU.
  priv morph_targets : Array[MorphTarget]
  priv mut groups : Array[MeshGroup]
}

///|
pub fn MeshData::new(
  positions : FixedArray[@tmath.Vec3],
  normals : FixedArray[@tmath.Vec3],
  uvs : FixedArray[@tmath.Vec2],
  indices : FixedArray[UInt],
) -> MeshData {
  {
    positions,
    normals,
    uvs,
    indices,
    tangents: None,
    colors: None,
    skin_joints: None,
    skin_weights: None,
    morph_targets: [],
    groups: [],
  }
}

///|
/// Per-vertex positions (`vertex_count()` entries).
pub fn MeshData::positions(self : MeshData) -> FixedArray[@tmath.Vec3] {
  self.positions
}

///|
/// Per-vertex normals, always the same length as `positions()`.
pub fn MeshData::normals(self : MeshData) -> FixedArray[@tmath.Vec3] {
  self.normals
}

///|
/// Per-vertex texture coordinates.
pub fn MeshData::uvs(self : MeshData) -> FixedArray[@tmath.Vec2] {
  self.uvs
}

///|
/// 32-bit triangle indices.
pub fn MeshData::indices(self : MeshData) -> FixedArray[UInt] {
  self.indices
}

///|
/// Tangents (`w` is the bitangent handedness sign), when computed.
pub fn MeshData::tangents(self : MeshData) -> FixedArray[@tmath.Vec4]? {
  self.tangents
}

///|
/// Optional linear-space vertex colours.
pub fn MeshData::colors(self : MeshData) -> FixedArray[@tmath.Vec4]? {
  self.colors
}

///|
/// Four joint indices per vertex, when skinned.
pub fn MeshData::skin_joints(self : MeshData) -> FixedArray[@tmath.Vec4]? {
  self.skin_joints
}

///|
/// Four joint weights per vertex, when skinned.
pub fn MeshData::skin_weights(self : MeshData) -> FixedArray[@tmath.Vec4]? {
  self.skin_weights
}

///|
/// Additive per-vertex position deltas.
pub fn MeshData::morph_targets(self : MeshData) -> Array[MorphTarget] {
  self.morph_targets
}

///|
/// Material ranges inside the index buffer.
pub fn MeshData::groups(self : MeshData) -> Array[MeshGroup] {
  self.groups
}

///|
/// Replace the normals, rejecting an array whose length disagrees with the
/// vertex count.
pub fn MeshData::set_normals(
  self : MeshData,
  normals : FixedArray[@tmath.Vec3],
) -> Unit raise GeometryError {
  if normals.length() != self.vertex_count() {
    raise GeometryError::InvalidMesh(
      "MeshData::set_normals: normal count must match the vertex count",
    )
  }
  self.normals = normals
}

///|
/// Replace the tangents, rejecting a length mismatch.
pub fn MeshData::set_tangents(
  self : MeshData,
  tangents : FixedArray[@tmath.Vec4]?,
) -> Unit raise GeometryError {
  match tangents {
    Some(t) =>
      if t.length() != self.vertex_count() {
        raise GeometryError::InvalidMesh(
          "MeshData::set_tangents: tangent count must match the vertex count",
        )
      }
    None => ()
  }
  self.tangents = tangents
}

///|
/// Replace the vertex colours, rejecting a length mismatch.
pub fn MeshData::set_colors(
  self : MeshData,
  colors : FixedArray[@tmath.Vec4]?,
) -> Unit raise GeometryError {
  match colors {
    Some(c) =>
      if c.length() != self.vertex_count() {
        raise GeometryError::InvalidMesh(
          "MeshData::set_colors: colour count must match the vertex count",
        )
      }
    None => ()
  }
  self.colors = colors
}

///|
/// Append a material range, rejecting one that runs past the index buffer.
pub fn MeshData::add_group(
  self : MeshData,
  group : MeshGroup,
) -> Unit raise GeometryError {
  if group.start < 0 || group.count < 0 || group.start + group.count > self.index_count() {
    raise GeometryError::InvalidMesh(
      "MeshData::add_group: group range must stay inside the index buffer",
    )
  }
  self.groups.push(group)
}

///|
pub fn MeshData::vertex_count(self : MeshData) -> Int {
  self.positions.length()
}

///|
pub fn MeshData::index_count(self : MeshData) -> Int {
  self.indices.length()
}

///|
pub fn MeshData::triangle_count(self : MeshData) -> Int {
  self.indices.length() / 3
}

///|
pub fn MeshData::has_tangents(self : MeshData) -> Bool {
  match self.tangents {
    Some(_) => true
    None => false
  }
}

///|
pub fn MeshData::has_colors(self : MeshData) -> Bool {
  match self.colors {
    Some(_) => true
    None => false
  }
}

///|
/// Tight AABB of the positions. Empty meshes return a zero box at the origin.
pub fn MeshData::bounds(self : MeshData) -> @tmath.Aabb3 {
  if self.positions.length() == 0 {
    @tmath.Aabb3::new(@tmath.Vec3::zero(), @tmath.Vec3::zero())
  } else {
    @tmath.Aabb3::from_points(self.positions)
  }
}

///|
/// Failures raised by the geometry builders and the glTF parser.
pub suberror GeometryError {
  InvalidMesh(String)
  InvalidGltf(String)
}

///|
/// Replace the groups array (builder support; avoids a second constructor).
///|
pub fn MeshData::add_morph_target(
  self : MeshData,
  positions : FixedArray[@tmath.Vec3],
) -> Unit raise GeometryError {
  if positions.length() != self.vertex_count() {
    raise GeometryError::InvalidMesh(
      "MeshData::add_morph_target: delta count must match the vertex count",
    )
  }
  self.morph_targets.push(MorphTarget::{ positions })
}

///|
pub fn MeshData::has_morph(self : MeshData) -> Bool {
  self.morph_targets.length() > 0
}

///|
/// Attach four joint influences per vertex (indices into a skeleton palette).
pub fn MeshData::set_skin(
  self : MeshData,
  joints : FixedArray[@tmath.Vec4],
  weights : FixedArray[@tmath.Vec4],
) -> Unit raise GeometryError {
  if joints.length() != self.vertex_count() || weights.length() != self.vertex_count() {
    raise GeometryError::InvalidMesh(
      "MeshData::set_skin: joints/weights must match the vertex count",
    )
  }
  self.skin_joints = Some(joints)
  self.skin_weights = Some(weights)
}

///|
pub fn MeshData::has_skin(self : MeshData) -> Bool {
  match (self.skin_joints, self.skin_weights) {
    (Some(_), Some(_)) => true
    _ => false
  }
}

///|
pub fn MeshData::with_groups(self : MeshData, groups : Array[MeshGroup]) -> MeshData {
  self.groups = groups
  self
}

///|
fn transform_normals(
  src : FixedArray[@tmath.Vec3],
  affine : @tmath.Affine3,
) -> FixedArray[@tmath.Vec3] {
  let n = src.length()
  let out : FixedArray[@tmath.Vec3] = FixedArray::make(n, @tmath.Vec3::zero())
  // Fall back to the linear part when the affine is singular: normals may be
  // stretched, but they stay finite and are re-normalized below.
  let m = match affine.normal_matrix() {
    Some(m) => m
    None => affine.matrix3
  }
  for i = 0; i < n; i = i + 1 {
    out[i] = m.mul_vec3(src[i]).normalize()
  }
  out
}

///|
fn transform_tangents(
  src : FixedArray[@tmath.Vec4],
  affine : @tmath.Affine3,
) -> FixedArray[@tmath.Vec4] {
  let n = src.length()
  let out : FixedArray[@tmath.Vec4] = FixedArray::make(
    n,
    @tmath.Vec4::new(0.0, 0.0, 0.0, 1.0),
  )
  for i = 0; i < n; i = i + 1 {
    let t = src[i]
    let v = affine.matrix3.mul_vec3(@tmath.Vec3::new(t.x, t.y, t.z)).normalize()
    out[i] = @tmath.Vec4::new(v.x, v.y, v.z, t.w)
  }
  out
}

///|
/// Rigid + affine transform. Positions use the full affine; normals use the
/// inverse-transpose (non-uniform scale safe); tangents use the linear part.
pub fn MeshData::transformed(self : MeshData, affine : @tmath.Affine3) -> MeshData {
  let n = self.positions.length()
  let pos : FixedArray[@tmath.Vec3] = FixedArray::make(n, @tmath.Vec3::zero())
  for i = 0; i < n; i = i + 1 {
    pos[i] = affine.transform_point3(self.positions[i])
  }
  let nor = transform_normals(self.normals, affine)
  let out = MeshData::new(pos, nor, self.uvs, self.indices).with_groups(self.groups)
  match self.tangents {
    Some(t) => out.tangents = Some(transform_tangents(t, affine))
    None => ()
  }
  out.colors = self.colors
  out
}

///|
/// Concatenate meshes. Indices and groups are rebased by each part's vertex
/// offset. Optional attributes are kept only when every part provides them.
pub fn MeshData::merge(parts : Array[MeshData]) -> MeshData {
  let mut total_v = 0
  let mut total_i = 0
  for p in parts {
    total_v = total_v + p.vertex_count()
    total_i = total_i + p.index_count()
  }
  let pos : FixedArray[@tmath.Vec3] = FixedArray::make(total_v, @tmath.Vec3::zero())
  let nor : FixedArray[@tmath.Vec3] = FixedArray::make(total_v, @tmath.Vec3::zero())
  let uv : FixedArray[@tmath.Vec2] = FixedArray::make(total_v, @tmath.Vec2::zero())
  let idx : FixedArray[UInt] = FixedArray::make(total_i, (0 : UInt))
  let tan : FixedArray[@tmath.Vec4] = FixedArray::make(
    total_v,
    @tmath.Vec4::new(0.0, 0.0, 0.0, 1.0),
  )
  let col : FixedArray[@tmath.Vec4] = FixedArray::make(
    total_v,
    @tmath.Vec4::new(1.0, 1.0, 1.0, 1.0),
  )
  let groups : Array[MeshGroup] = []
  let mut keep_tangents = parts.length() > 0
  let mut keep_colors = parts.length() > 0
  for p in parts {
    if !p.has_tangents() {
      keep_tangents = false
    }
    if !p.has_colors() {
      keep_colors = false
    }
  }
  let mut vbase = 0
  let mut ibase = 0
  for p in parts {
    let vn = p.vertex_count()
    for i = 0; i < vn; i = i + 1 {
      pos[vbase + i] = p.positions[i]
      nor[vbase + i] = p.normals[i]
      uv[vbase + i] = p.uvs[i]
    }
    match p.tangents {
      Some(t) => {
        for i = 0; i < vn; i = i + 1 {
          tan[vbase + i] = t[i]
        }
      }
      None => ()
    }
    match p.colors {
      Some(c) => {
        for i = 0; i < vn; i = i + 1 {
          col[vbase + i] = c[i]
        }
      }
      None => ()
    }
    let in_count = p.index_count()
    for i = 0; i < in_count; i = i + 1 {
      idx[ibase + i] = p.indices[i] + vbase.reinterpret_as_uint()
    }
    for g in p.groups {
      groups.push(MeshGroup::new(ibase + g.start, g.count, g.material_slot))
    }
    vbase = vbase + vn
    ibase = ibase + in_count
  }
  let out = MeshData::new(pos, nor, uv, idx).with_groups(groups)
  if keep_tangents {
    out.tangents = Some(tan)
  }
  if keep_colors {
    out.colors = Some(col)
  }
  out
}

///|
/// Expand into a non-indexed mesh (every three indices become three vertices).
/// Groups stay valid because each index becomes one vertex.
pub fn MeshData::to_non_indexed(self : MeshData) -> MeshData {
  let n = self.indices.length()
  let pos : FixedArray[@tmath.Vec3] = FixedArray::make(n, @tmath.Vec3::zero())
  let nor : FixedArray[@tmath.Vec3] = FixedArray::make(n, @tmath.Vec3::zero())
  let uv : FixedArray[@tmath.Vec2] = FixedArray::make(n, @tmath.Vec2::zero())
  let idx : FixedArray[UInt] = FixedArray::make(n, (0 : UInt))
  let tan : FixedArray[@tmath.Vec4] = FixedArray::make(
    n,
    @tmath.Vec4::new(0.0, 0.0, 0.0, 1.0),
  )
  let col : FixedArray[@tmath.Vec4] = FixedArray::make(
    n,
    @tmath.Vec4::new(1.0, 1.0, 1.0, 1.0),
  )
  for i = 0; i < n; i = i + 1 {
    let k = self.indices[i].reinterpret_as_int()
    pos[i] = self.positions[k]
    nor[i] = self.normals[k]
    uv[i] = self.uvs[k]
    idx[i] = i.reinterpret_as_uint()
    match self.tangents {
      Some(t) => tan[i] = t[k]
      None => ()
    }
    match self.colors {
      Some(c) => col[i] = c[k]
      None => ()
    }
  }
  let out = MeshData::new(pos, nor, uv, idx).with_groups(self.groups)
  if self.has_tangents() {
    out.tangents = Some(tan)
  }
  if self.has_colors() {
    out.colors = Some(col)
  }
  out
}

///|
/// Reverse triangle winding and flip normals (e.g. to turn an outside-out
/// mesh into an inside-out one). Positions and UVs are shared, not copied.
pub fn MeshData::flipped(self : MeshData) -> MeshData {
  let n = self.indices.length()
  let idx : FixedArray[UInt] = FixedArray::make(n, (0 : UInt))
  let mut i = 0
  while i + 2 < n {
    idx[i] = self.indices[i]
    idx[i + 1] = self.indices[i + 2]
    idx[i + 2] = self.indices[i + 1]
    i = i + 3
  }
  let nor : FixedArray[@tmath.Vec3] = FixedArray::make(
    self.normals.length(),
    @tmath.Vec3::zero(),
  )
  for j = 0; j < self.normals.length(); j = j + 1 {
    nor[j] = -self.normals[j]
  }
  MeshData::new(self.positions, nor, self.uvs, idx).with_groups(self.groups)
}
