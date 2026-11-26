// GPU residency for `@tgeo.MeshData`.
//
// The canonical vertex stream is interleaved position(3) + normal(3) + uv(2),
// 32 bytes per vertex, which matches the AOT pipeline's single vertex binding.

///|
pub const MESH_VERTEX_FLOATS : Int = 8

///|
pub const MESH_VERTEX_BYTES : Int = 32

///|
pub struct GpuMesh {
  priv vbuf : @tycho.Buffer
  priv ibuf : @tycho.Buffer
  priv index_type : @tycho.IndexType
  priv index_count : Int
  priv vertex_count : Int
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
pub fn GpuMesh::upload(dev : @tycho.Device, mesh : @tgeo.MeshData) -> GpuMesh raise {
  let n = mesh.vertex_count()
  let floats = FixedArray::make(n * MESH_VERTEX_FLOATS, (0.0 : Float))
  for i = 0; i < n; i = i + 1 {
    let p = mesh.positions[i]
    let nr = mesh.normals[i]
    let uv = mesh.uvs[i]
    let o = i * MESH_VERTEX_FLOATS
    floats[o] = p.x
    floats[o + 1] = p.y
    floats[o + 2] = p.z
    floats[o + 3] = nr.x
    floats[o + 4] = nr.y
    floats[o + 5] = nr.z
    floats[o + 6] = uv.x
    floats[o + 7] = uv.y
  }
  let use_u16 = n <= 65536
  let ic = mesh.index_count()
  let vbuf = dev.create_buffer_with(
    if n == 0 { 4 } else { n * MESH_VERTEX_BYTES },
    @tycho.BufferKind::Vertex,
    location=@tycho.MemoryLocation::GpuOnly,
  )
  if n > 0 {
    vbuf.upload_floats(floats)
  }
  let ibuf = dev.create_buffer_with(
    if ic == 0 { 4 } else if use_u16 { ic * 2 } else { ic * 4 },
    @tycho.BufferKind::Index,
    location=@tycho.MemoryLocation::GpuOnly,
  )
  if ic > 0 {
    if use_u16 {
      let idx : FixedArray[UInt16] = FixedArray::make(ic, (0 : UInt16))
      for i = 0; i < ic; i = i + 1 {
        idx[i] = mesh.indices[i].to_uint16()
      }
      ibuf.upload_uint16(idx)
    } else {
      ibuf.upload_uint32(mesh.indices)
    }
  }
  {
    vbuf,
    ibuf,
    index_type: if use_u16 { @tycho.IndexType::Uint16 } else { @tycho.IndexType::Uint32 },
    index_count: ic,
    vertex_count: n,
    bounds: mesh.bounds(),
    groups: mesh.groups,
    cpu: mesh,
  }
}

///|
pub fn GpuMesh::bind(self : GpuMesh, cmd : @tycho.CommandBuffer) -> Unit {
  cmd.bind_vertex(0, self.vbuf)
  cmd.bind_index(self.ibuf, self.index_type)
}

///|
pub fn GpuMesh::draw(self : GpuMesh, cmd : @tycho.CommandBuffer) -> Unit {
  if self.index_count > 0 {
    cmd.draw_indexed(self.index_count)
  }
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

///|
pub fn GpuMesh::destroy(self : GpuMesh) -> Unit {
  self.vbuf.destroy()
  self.ibuf.destroy()
}
