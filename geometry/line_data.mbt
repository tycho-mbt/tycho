// `LineData` — the CPU-side line-list container of laplaceliu/tycho_geometry.
//
// `MeshData` is triangle-only, so edge extraction (`edges` / `wireframe`)
// needs a separate container. The layout mirrors `MeshData` minus the vertex
// attributes that a line segment has no use for (normals / uvs / tangents):
// a segment is simply two consecutive indices.
//
// Line data never reaches `tycho_3d::upload_mesh` (which bakes a PBR vertex
// layout); a renderer consumes it through a `LineList` pipeline instead.

///|
pub(all) struct LineData {
  positions : FixedArray[@tmath.Vec3]
  // Always 32-bit; two entries per segment: [a0, b0, a1, b1, ...].
  indices : FixedArray[UInt]
}

///|
pub fn LineData::new(
  positions : FixedArray[@tmath.Vec3],
  indices : FixedArray[UInt],
) -> LineData {
  { positions, indices }
}

///|
/// Empty line list (a useful neutral element for `merge`).
pub fn LineData::empty() -> LineData {
  LineData::new(FixedArray::make(0, @tmath.Vec3::zero()), FixedArray::make(0, 0))
}

///|
pub fn LineData::vertex_count(self : LineData) -> Int {
  self.positions.length()
}

///|
pub fn LineData::segment_count(self : LineData) -> Int {
  self.indices.length() / 2
}

///|
/// Tight AABB of the positions. Empty line data returns a zero box at the
/// origin, same as `MeshData::bounds`.
pub fn LineData::bounds(self : LineData) -> @tmath.Aabb3 {
  if self.positions.length() == 0 {
    @tmath.Aabb3::new(@tmath.Vec3::zero(), @tmath.Vec3::zero())
  } else {
    @tmath.Aabb3::from_points(self.positions)
  }
}

///|
/// Rigid + affine transform of the positions (lines carry no normals).
pub fn LineData::transformed(
  self : LineData,
  affine : @tmath.Affine3,
) -> LineData {
  let n = self.positions.length()
  let out : FixedArray[@tmath.Vec3] = FixedArray::make(n, @tmath.Vec3::zero())
  for i = 0; i < n; i = i + 1 {
    out[i] = affine.transform_point3(self.positions[i])
  }
  LineData::new(out, self.indices)
}

///|
/// Expand to one vertex pair per segment (`indices` becomes 0,1,2,3,...).
pub fn LineData::to_non_indexed(self : LineData) -> LineData {
  let n = self.indices.length()
  let pos : FixedArray[@tmath.Vec3] = FixedArray::make(n, @tmath.Vec3::zero())
  let idx : FixedArray[UInt] = FixedArray::make(n, (0 : UInt))
  for i = 0; i < n; i = i + 1 {
    let k = self.indices[i].reinterpret_as_int()
    pos[i] = self.positions[k]
    idx[i] = i.reinterpret_as_uint()
  }
  LineData::new(pos, idx)
}

///|
/// Concatenate line lists, rebasing indices by each part's vertex offset.
pub fn LineData::merge(parts : Array[LineData]) -> LineData {
  let mut total_v = 0
  let mut total_i = 0
  for p in parts {
    total_v = total_v + p.vertex_count()
    total_i = total_i + p.indices.length()
  }
  let pos : FixedArray[@tmath.Vec3] = FixedArray::make(total_v, @tmath.Vec3::zero())
  let idx : FixedArray[UInt] = FixedArray::make(total_i, (0 : UInt))
  let mut vbase = 0
  let mut ibase = 0
  for p in parts {
    let vn = p.vertex_count()
    for i = 0; i < vn; i = i + 1 {
      pos[vbase + i] = p.positions[i]
    }
    for i = 0; i < p.indices.length(); i = i + 1 {
      idx[ibase + i] = p.indices[i] + vbase.reinterpret_as_uint()
    }
    vbase = vbase + vn
    ibase = ibase + p.indices.length()
  }
  LineData::new(pos, idx)
}
