// GPU-side range description for `@tgeo.MeshData`.
//
// Every mesh lives in the renderer's shared vertex / index arenas (static batch
// cache), so a mesh is just a range plus its CPU copy for picking. Drawing only
// needs `first_index` / `first_vertex`, which lets all batches share one
// vertex/index binding and one indirect draw call.

///|
pub const MESH_VERTEX_FLOATS : Int = 12

///|
pub const MESH_VERTEX_BYTES : Int = 48

///|
/// Skinned vertices append joints(4) and weights(4): 80 bytes per vertex.
pub const SKIN_VERTEX_FLOATS : Int = 20

///|
pub const SKIN_VERTEX_BYTES : Int = 80

///|
pub struct GpuMesh {
  priv first_vertex : Int
  priv vertex_count : Int
  priv first_index : Int
  priv index_count : Int
  priv skinned : Bool
  bounds : @tmath.Aabb3
  groups : Array[@tgeo.MeshGroup]
  // CPU copy kept for picking; dropped when an acceleration structure lands.
  cpu : @tgeo.MeshData
}

///|
fn f_of_int(i : Int) -> Float {
  Float::from_double(i.to_double())
}

///|
/// Interleaved position(3) + normal(3) + uv(2) + tangent(4) floats. Tangents
/// must already be generated.
pub fn mesh_vertex_floats(mesh : @tgeo.MeshData) -> FixedArray[Float] {
  let n = mesh.vertex_count()
  let floats = FixedArray::make(n * MESH_VERTEX_FLOATS, (0.0 : Float))
  for i = 0; i < n; i = i + 1 {
    let p = mesh.positions[i]
    let nr = mesh.normals[i]
    let uv = mesh.uvs[i]
    let tg = match mesh.tangents {
      Some(t) => t[i]
      None => @tmath.Vec4::new(1.0, 0.0, 0.0, 1.0)
    }
    let o = i * MESH_VERTEX_FLOATS
    floats[o] = p.x
    floats[o + 1] = p.y
    floats[o + 2] = p.z
    floats[o + 3] = nr.x
    floats[o + 4] = nr.y
    floats[o + 5] = nr.z
    floats[o + 6] = uv.x
    floats[o + 7] = uv.y
    floats[o + 8] = tg.x
    floats[o + 9] = tg.y
    floats[o + 10] = tg.z
    floats[o + 11] = tg.w
  }
  floats
}

///|
/// Interleaved skinned vertex stream: the static 12 floats plus joints(4) and
/// weights(4). Vertices without skin data get zero joints and weights.
pub fn mesh_skinned_vertex_floats(mesh : @tgeo.MeshData) -> FixedArray[Float] {
  let n = mesh.vertex_count()
  let base = mesh_vertex_floats(mesh)
  let out = FixedArray::make(n * SKIN_VERTEX_FLOATS, (0.0 : Float))
  for i = 0; i < n; i = i + 1 {
    for c = 0; c < MESH_VERTEX_FLOATS; c = c + 1 {
      out[i * SKIN_VERTEX_FLOATS + c] = base[i * MESH_VERTEX_FLOATS + c]
    }
    let joints = match mesh.skin_joints {
      Some(j) => j[i]
      None => @tmath.Vec4::zero()
    }
    let weights = match mesh.skin_weights {
      Some(w) => w[i]
      None => @tmath.Vec4::zero()
    }
    let o = i * SKIN_VERTEX_FLOATS + MESH_VERTEX_FLOATS
    out[o] = joints.x
    out[o + 1] = joints.y
    out[o + 2] = joints.z
    out[o + 3] = joints.w
    out[o + 4] = weights.x
    out[o + 5] = weights.y
    out[o + 6] = weights.z
    out[o + 7] = weights.w
  }
  out
}

///|
pub fn GpuMesh::range(
  mesh : @tgeo.MeshData,
  first_vertex : Int,
  first_index : Int,
) -> GpuMesh {
  {
    first_vertex,
    vertex_count: mesh.vertex_count(),
    first_index,
    index_count: mesh.index_count(),
    skinned: mesh.has_skin(),
    bounds: mesh.bounds(),
    groups: mesh.groups,
    cpu: mesh,
  }
}

///|
pub fn GpuMesh::skinned(self : GpuMesh) -> Bool {
  self.skinned
}

///|
pub fn GpuMesh::first_vertex(self : GpuMesh) -> Int {
  self.first_vertex
}

///|
pub fn GpuMesh::first_index(self : GpuMesh) -> Int {
  self.first_index
}

///|
pub fn GpuMesh::index_count(self : GpuMesh) -> Int {
  self.index_count
}

///|
pub fn GpuMesh::vertex_count(self : GpuMesh) -> Int {
  self.vertex_count
}

///|
/// CPU-side mesh data retained for picking.
pub fn GpuMesh::mesh(self : GpuMesh) -> @tgeo.MeshData {
  self.cpu
}

///|
pub fn GpuMesh::bounds(self : GpuMesh) -> @tmath.Aabb3 {
  self.bounds
}
