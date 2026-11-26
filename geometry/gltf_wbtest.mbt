// glTF parsing contracts: a single embedded triangle with all core attributes.

///|
pub let triangle_gltf : String = "{\"asset\": {\"version\": \"2.0\", \"generator\": \"tycho-fixture\"}, \"scene\": 0, \"scenes\": [{\"nodes\": [0]}], \"nodes\": [{\"name\": \"tri\", \"mesh\": 0}], \"meshes\": [{\"primitives\": [{\"attributes\": {\"POSITION\": 0, \"NORMAL\": 1, \"TEXCOORD_0\": 2}, \"indices\": 3, \"material\": 0}]}], \"materials\": [{\"name\": \"red\", \"pbrMetallicRoughness\": {\"baseColorFactor\": [0.8, 0.2, 0.2, 1.0], \"metallicFactor\": 0.1, \"roughnessFactor\": 0.6}}], \"buffers\": [{\"byteLength\": 102, \"uri\": \"data:application/octet-stream;base64,AAAAAAAAAAAAAAAAAACAPwAAAAAAAAAAAAAAAAAAgD8AAAAAAAAAAAAAAAAAAIA/AAAAAAAAAAAAAIA/AAAAAAAAAAAAAIA/AAAAAAAAAAAAAIA/AAAAAAAAAAAAAIA/AAABAAIA\"}], \"bufferViews\": [{\"buffer\": 0, \"byteOffset\": 0, \"byteLength\": 36}, {\"buffer\": 0, \"byteOffset\": 36, \"byteLength\": 36}, {\"buffer\": 0, \"byteOffset\": 72, \"byteLength\": 24}, {\"buffer\": 0, \"byteOffset\": 96, \"byteLength\": 6}], \"accessors\": [{\"bufferView\": 0, \"componentType\": 5126, \"count\": 3, \"type\": \"VEC3\", \"max\": [1, 1, 0], \"min\": [0, 0, 0]}, {\"bufferView\": 1, \"componentType\": 5126, \"count\": 3, \"type\": \"VEC3\"}, {\"bufferView\": 2, \"componentType\": 5126, \"count\": 3, \"type\": \"VEC2\"}, {\"bufferView\": 3, \"componentType\": 5123, \"count\": 3, \"type\": \"SCALAR\"}]}"

///|
test "parse gltf triangle" {
  let g = parse_gltf(triangle_gltf)
  need(g.meshes.length() == 1, "mesh count")
  let m = g.meshes[0]
  need(m.vertex_count() == 3, "vertex count")
  need(m.index_count() == 3, "index count")
  need(m.groups.length() == 1, "group count")
  need(m.groups[0].count == 3, "group range")
  need(m.has_tangents() == false, "tangents are generated later")
  need_vec3(m.positions[0], @tmath.Vec3::new(0.0, 0.0, 0.0))
  need_vec3(m.positions[1], @tmath.Vec3::new(1.0, 0.0, 0.0))
  need_vec3(m.normals[0], @tmath.Vec3::new(0.0, 0.0, 1.0))
  need(close(m.uvs[1].x, 1.0), "uv x")
  need(close(m.uvs[2].y, 1.0), "uv y")
  need(g.materials.length() == 1, "material count")
  need(close(g.materials[0].metallic, 0.1), "metallic")
  need(close(g.materials[0].roughness, 0.6), "roughness")
  need(g.materials[0].base_color.x > 0.7, "base colour")
  need(g.nodes.length() == 1, "node count")
  need(g.nodes[0].mesh == 0, "node mesh")
  need(g.roots.length() == 1 && g.roots[0] == 0, "scene roots")
}
