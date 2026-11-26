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
pub struct GpuMesh {
  priv first_vertex : Int
  priv vertex_count : Int
  priv first_index : Int
  priv index_count : Int
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
    bounds: mesh.bounds(),
    groups: mesh.groups,
    cpu: mesh,
  }
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
