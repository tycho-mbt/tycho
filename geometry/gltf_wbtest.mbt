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

///|
pub let sparse_gltf : String = "{\"asset\": {\"version\": \"2.0\"}, \"buffers\": [{\"byteLength\": 56, \"uri\": \"data:application/octet-stream;base64,AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAABBBAAAAQQAA4EA=\"}], \"bufferViews\": [{\"buffer\": 0, \"byteOffset\": 0, \"byteLength\": 36}, {\"buffer\": 0, \"byteOffset\": 40, \"byteLength\": 2}, {\"buffer\": 0, \"byteOffset\": 44, \"byteLength\": 12}], \"accessors\": [{\"bufferView\": 0, \"componentType\": 5126, \"count\": 3, \"type\": \"VEC3\", \"sparse\": {\"count\": 1, \"indices\": {\"bufferView\": 1, \"componentType\": 5123}, \"values\": {\"bufferView\": 2}}}], \"meshes\": [{\"primitives\": [{\"attributes\": {\"POSITION\": 0}}]}], \"nodes\": [{\"mesh\": 0}], \"scenes\": [{\"nodes\": [0]}]}"

///|
test "parse gltf sparse accessor" {
  let g = parse_gltf(sparse_gltf)
  need(g.meshes.length() == 1, "sparse mesh")
  let m = g.meshes[0]
  need(m.vertex_count() == 3, "sparse vertex count")
  need_vec3(m.positions[0], @tmath.Vec3::zero())
  need_vec3(m.positions[1], @tmath.Vec3::new(9.0, 8.0, 7.0))
  need_vec3(m.positions[2], @tmath.Vec3::zero())
}

///|
test "parse gltf textures" {
  let text = "{\"asset\": {\"version\": \"2.0\"}, \"images\": [{\"uri\": \"data:image/png;base64,iVBORw0KGgo=\"}], \"textures\": [{\"source\": 0}], \"materials\": [{\"pbrMetallicRoughness\": {\"baseColorTexture\": {\"index\": 0}}, \"normalTexture\": {\"index\": 0}}]}"
  let g = parse_gltf(text)
  need(g.images.length() == 1, "image count")
  need(g.images[0].length() > 4, "image bytes")
  need(g.textures.length() == 1 && g.textures[0].source == 0, "texture source")
  need(g.materials.length() == 1, "material count")
  need(g.materials[0].base_color_tex == 0, "base colour texture")
  need(g.materials[0].normal_tex == 0, "normal texture")
}

///|
test "parse gltf animation" {
  let text = "{\"asset\": {\"version\": \"2.0\"}, \"buffers\": [{\"byteLength\": 60, \"uri\": \"data:application/octet-stream;base64,AAAAAACGgD8AAABAAAAAAAAAAAAAAAAAAACAPwAAAADzBDU/AAAAAPMENT8AAAAAAACAPwAAAAAyMY0k\"}], \"bufferViews\": [{\"buffer\": 0, \"byteOffset\": 0, \"byteLength\": 12}, {\"buffer\": 0, \"byteOffset\": 12, \"byteLength\": 48}], \"accessors\": [{\"bufferView\": 0, \"componentType\": 5126, \"count\": 3, \"type\": \"SCALAR\"}, {\"bufferView\": 1, \"componentType\": 5126, \"count\": 3, \"type\": \"VEC4\"}], \"nodes\": [{\"name\": \"n\"}], \"animations\": [{\"name\": \"spin\", \"samplers\": [{\"input\": 0, \"output\": 1, \"interpolation\": \"LINEAR\"}], \"channels\": [{\"sampler\": 0, \"target\": {\"node\": 0, \"path\": \"rotation\"}}]}]}"
  let g = parse_gltf(text)
  need(g.animations.length() == 1, "animation count")
  let a = g.animations[0]
  need(a.name == "spin", "animation name")
  need(a.channels.length() == 1, "channel count")
  let ch = a.channels[0]
  need(ch.node == 0, "channel node")
  match ch.path {
    Rotation => ()
    _ => fail("channel path")
  }
  need(ch.times.length() == 3, "key times")
  need(close(ch.times[2], 2.0), "last time")
  need(ch.values.length() == 3, "key values")
  need(close(ch.values[1].y, 0.70710678, eps=1.0e-4), "quat y")
  need(close(ch.values[1].w, 0.70710678, eps=1.0e-4), "quat w")
}

///|
/// Parse `text` and return the extension name when it is rejected as
/// unsupported, or `""` when parsing succeeded.
fn rejected_extension(text : String) -> String {
  try {
    let _ = parse_gltf(text)
    ""
  } catch {
    GeometryError::UnsupportedExtension(name) => name
    _ => ""
  }
}

///|
test "gltf rejects required extensions it cannot decode" {
  let text = "{\"asset\":{\"version\":\"2.0\"},\"extensionsRequired\":[\"KHR_draco_mesh_compression\"]}"
  need(
    rejected_extension(text) == "KHR_draco_mesh_compression",
    "required Draco must be refused with a typed error",
  )
  // KTX2/Basis textures are equally undecodable today.
  let ktx = "{\"asset\":{\"version\":\"2.0\"},\"extensionsRequired\":[\"KHR_texture_basisu\"]}"
  need(rejected_extension(ktx) == "KHR_texture_basisu", "required KTX2 refused")
}

///|
test "gltf rejects compressed primitives without extensionsRequired" {
  // Some exporters forget the top-level declaration; the primitive-level
  // extension is still a hard stop.
  let meshopt = "{\"asset\":{\"version\":\"2.0\"},\"meshes\":[{\"primitives\":[{\"attributes\":{},\"extensions\":{\"EXT_meshopt_compression\":{}}}]}]}"
  need(rejected_extension(meshopt) == "EXT_meshopt_compression", "meshopt refused")
  let draco = "{\"asset\":{\"version\":\"2.0\"},\"meshes\":[{\"primitives\":[{\"attributes\":{},\"extensions\":{\"KHR_draco_mesh_compression\":{\"bufferView\":0}}}]}]}"
  need(rejected_extension(draco) == "KHR_draco_mesh_compression", "primitive Draco refused")
}

///|
test "gltf ignores extensionsUsed because it is not binding" {
  // `extensionsUsed` only advertises optional data; loading must continue.
  let text = "{\"asset\":{\"version\":\"2.0\"},\"extensionsUsed\":[\"KHR_materials_unlit\"],\"meshes\":[]}"
  let g = parse_gltf(text)
  need(g.meshes.length() == 0, "optional extension does not block parsing")
  // The all-core fixture still parses.
  let base = parse_gltf(triangle_gltf)
  need(base.meshes.length() == 1, "core fixture unaffected")
}
///|
/// A GLB container built from the same triangle: buffer 0 has no URI (it is the
/// BIN chunk), the PNG lives in a buffer view, and the material carries every
/// KHR extension the parser maps onto `tycho_3d`'s physical material.
pub let triangle_glb_b64 : String = "Z2xURgIAAAD4BQAAbAUAAEpTT057ImFzc2V0Ijp7InZlcnNpb24iOiIyLjAifSwic2NlbmUiOjAsInNjZW5lcyI6W3sibm9kZXMiOlswXX1dLCJub2RlcyI6W3sibWVzaCI6MCwibmFtZSI6InRyaSJ9XSwibWVzaGVzIjpbeyJwcmltaXRpdmVzIjpbeyJhdHRyaWJ1dGVzIjp7IlBPU0lUSU9OIjowLCJOT1JNQUwiOjEsIlRFWENPT1JEXzAiOjJ9LCJpbmRpY2VzIjozLCJtYXRlcmlhbCI6MH1dfV0sImFjY2Vzc29ycyI6W3siYnVmZmVyVmlldyI6MCwiY29tcG9uZW50VHlwZSI6NTEyNiwiY291bnQiOjMsInR5cGUiOiJWRUMzIiwibWluIjpbMCwwLDBdLCJtYXgiOlsxLDEsMF19LHsiYnVmZmVyVmlldyI6MSwiY29tcG9uZW50VHlwZSI6NTEyNiwiY291bnQiOjMsInR5cGUiOiJWRUMzIn0seyJidWZmZXJWaWV3IjoyLCJjb21wb25lbnRUeXBlIjo1MTI2LCJjb3VudCI6MywidHlwZSI6IlZFQzIifSx7ImJ1ZmZlclZpZXciOjMsImNvbXBvbmVudFR5cGUiOjUxMjMsImNvdW50IjozLCJ0eXBlIjoiU0NBTEFSIn1dLCJidWZmZXJWaWV3cyI6W3siYnVmZmVyIjowLCJieXRlT2Zmc2V0IjowLCJieXRlTGVuZ3RoIjozNn0seyJidWZmZXIiOjAsImJ5dGVPZmZzZXQiOjM2LCJieXRlTGVuZ3RoIjozNn0seyJidWZmZXIiOjAsImJ5dGVPZmZzZXQiOjcyLCJieXRlTGVuZ3RoIjoyNH0seyJidWZmZXIiOjAsImJ5dGVPZmZzZXQiOjk2LCJieXRlTGVuZ3RoIjo2fSx7ImJ1ZmZlciI6MCwiYnl0ZU9mZnNldCI6MTA0LCJieXRlTGVuZ3RoIjo4fV0sImJ1ZmZlcnMiOlt7ImJ5dGVMZW5ndGgiOjExMn1dLCJpbWFnZXMiOlt7ImJ1ZmZlclZpZXciOjQsIm1pbWVUeXBlIjoiaW1hZ2UvcG5nIn1dLCJ0ZXh0dXJlcyI6W3sic291cmNlIjowfV0sIm1hdGVyaWFscyI6W3sibmFtZSI6ImxhbXAiLCJwYnJNZXRhbGxpY1JvdWdobmVzcyI6eyJiYXNlQ29sb3JUZXh0dXJlIjp7ImluZGV4IjowfSwibWV0YWxsaWNSb3VnaG5lc3NUZXh0dXJlIjp7ImluZGV4IjowfX0sIm5vcm1hbFRleHR1cmUiOnsiaW5kZXgiOjB9LCJlbWlzc2l2ZUZhY3RvciI6WzAuNSwwLjI1LDAuMF0sImV4dGVuc2lvbnMiOnsiS0hSX21hdGVyaWFsc190cmFuc21pc3Npb24iOnsidHJhbnNtaXNzaW9uRmFjdG9yIjoxLjB9LCJLSFJfbWF0ZXJpYWxzX2lyaWRlc2NlbmNlIjp7ImlyaWRlc2NlbmNlRmFjdG9yIjoxLjAsImlyaWRlc2NlbmNlSW9yIjoxLjY3LCJpcmlkZXNjZW5jZVRoaWNrbmVzc01pbmltdW0iOjM5NS4wLCJpcmlkZXNjZW5jZVRoaWNrbmVzc01heGltdW0iOjQwNS4wfSwiS0hSX21hdGVyaWFsc19jbGVhcmNvYXQiOnsiY2xlYXJjb2F0RmFjdG9yIjowLjUsImNsZWFyY29hdFJvdWdobmVzc0ZhY3RvciI6MC4xfSwiS0hSX21hdGVyaWFsc19lbWlzc2l2ZV9zdHJlbmd0aCI6eyJlbWlzc2l2ZVN0cmVuZ3RoIjo0LjB9fX1dfXAAAABCSU4AAAAAAAAAAAAAAAAAAACAPwAAAAAAAAAAAAAAAAAAgD8AAAAAAAAAAAAAAAAAAIA/AAAAAAAAAAAAAIA/AAAAAAAAAAAAAIA/AAAAAAAAAAAAAIA/AAAAAAAAAAAAAIA/AAABAAIAAACJUE5HDQoaCg=="

///|
test "parse glb container with bin buffer and buffer-view image" {
  let bytes = @base64.decode(triangle_glb_b64)
  let g = parse_glb(bytes)
  need(g.meshes.length() == 1, "glb mesh count")
  let m = g.meshes[0]
  need(m.vertex_count() == 3 && m.index_count() == 3, "glb geometry")
  need_vec3(m.positions[1], @tmath.Vec3::new(1.0, 0.0, 0.0))
  need_vec3(m.normals[2], @tmath.Vec3::new(0.0, 0.0, 1.0))
  need(close(m.uvs[2].y, 1.0), "glb uv")
  need(g.roots.length() == 1 && g.roots[0] == 0, "glb roots")
  // The image has no URI: it is the buffer-view slice (PNG signature).
  need(g.images.length() == 1, "glb image count")
  need(g.images[0].length() == 8, "image slice length")
  need(g.images[0][0].to_int() == 0x89, "image slice starts with the PNG signature")
  need(g.images[0][1].to_int() == 0x50, "image slice keeps the P-N-G bytes")
}

///|
test "parse glb maps the physical material extensions" {
  let g = parse_glb(@base64.decode(triangle_glb_b64))
  let mat = g.materials[0]
  need(mat.name == "lamp", "material name")
  need(mat.base_color_tex == 0, "base colour texture")
  need(mat.normal_tex == 0, "normal texture")
  need(mat.metallic_roughness_tex == 0, "metallic-roughness texture")
  need(close(mat.transmission, 1.0), "transmission factor")
  need(close(mat.iridescence, 1.0), "iridescence factor")
  need(close(mat.iridescence_ior, 1.67, eps=1.0e-5), "iridescence ior")
  need(close(mat.iridescence_thickness, 400.0), "iridescence thickness midpoint")
  need(close(mat.clearcoat, 0.5), "clearcoat factor")
  need(close(mat.clearcoat_roughness, 0.1, eps=1.0e-6), "clearcoat roughness")
  // emissiveFactor is pre-multiplied by KHR_materials_emissive_strength.
  need(close(mat.emissive.x, 2.0), "emissive strength scales red")
  need(close(mat.emissive.y, 1.0), "emissive strength scales green")
}

///|
test "parse glb rejects containers it cannot read" {
  let mut rejected = false
  try {
    let _ = parse_glb(b"abcdefghijkl")
  } catch {
    GeometryError::InvalidGltf(_) => rejected = true
    _ => ()
  }
  need(rejected, "bad magic is rejected")
  let mut short = false
  try {
    let _ = parse_glb(b"glTF")
  } catch {
    GeometryError::InvalidGltf(_) => short = true
    _ => ()
  }
  need(short, "short header is rejected")
}
