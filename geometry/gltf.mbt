// Minimal glTF 2.0 loader.
//
// Supported subset: JSON documents whose buffers are base64 data URIs,
// triangle-list primitives with POSITION / NORMAL / TEXCOORD_0 and optional
// 8/16/32-bit indices, sparse accessors, node TRS or matrix transforms, and
// pbrMetallicRoughness factors plus base-colour / normal textures whose images
// are embedded `data:` URIs.

///|
pub(all) enum GltfAlphaMode {
  Opaque
  Mask(Float)
  Blend
}

///|
pub(all) struct GltfMaterial {
  name : String
  base_color : @tmath.Vec4
  metallic : Float
  roughness : Float
  alpha_mode : GltfAlphaMode
  double_sided : Bool
  // Indices into `GltfScene::textures`, or -1.
  base_color_tex : Int
  normal_tex : Int
}

///|
pub(all) struct GltfTexture {
  source : Int
}

///|
pub(all) struct GltfNode {
  name : String
  mesh : Int
  translation : @tmath.Vec3
  rotation : @tmath.Quat
  scale : @tmath.Vec3
  children : Array[Int]
}

///|
pub(all) struct GltfScene {
  meshes : Array[MeshData]
  materials : Array[GltfMaterial]
  nodes : Array[GltfNode]
  roots : Array[Int]
  textures : Array[GltfTexture]
  // Decoded image bytes (embedded `data:` URIs; empty for external files).
  images : Array[Bytes]
}

///|
priv struct Accessor {
  buffer : Int
  byte_offset : Int
  count : Int
  stride : Int
  comp : Int
  // Sparse override (glTF 2.0 §3.6.2.3); count 0 means dense.
  sparse_count : Int
  s_idx_buffer : Int
  s_idx_offset : Int
  s_idx_comp : Int
  s_val_buffer : Int
  s_val_offset : Int
}

///|
fn jget(j : @json.Json, key : String) -> @json.Json? {
  if j is Object(obj) {
    obj.get(key)
  } else {
    None
  }
}

///|
fn jnum(j : @json.Json, key : String, d : Double) -> Double {
  match jget(j, key) {
    Some(Number(n, ..)) => n
    _ => d
  }
}

///|
fn jint(j : @json.Json, key : String, d : Int) -> Int {
  jnum(j, key, d.to_double()).to_int()
}

///|
fn jstr(j : @json.Json, key : String, d : String) -> String {
  match jget(j, key) {
    Some(String(s)) => s
    _ => d
  }
}

///|
fn jarr(j : @json.Json, key : String) -> Array[@json.Json] {
  match jget(j, key) {
    Some(Array(a)) => a
    _ => []
  }
}

///|
fn jnum_at(j : @json.Json, d : Float) -> Float {
  match j {
    Number(n, ..) => Float::from_double(n)
    _ => d
  }
}

///|
fn jvec3(j : @json.Json, key : String, d : @tmath.Vec3) -> @tmath.Vec3 {
  let arr = jarr(j, key)
  if arr.length() >= 3 {
    @tmath.Vec3::new(jnum_at(arr[0], 0.0), jnum_at(arr[1], 0.0), jnum_at(arr[2], 0.0))
  } else {
    d
  }
}

///|
fn jvec4(j : @json.Json, key : String, d : @tmath.Vec4) -> @tmath.Vec4 {
  let arr = jarr(j, key)
  if arr.length() >= 4 {
    @tmath.Vec4::new(
      jnum_at(arr[0], 1.0),
      jnum_at(arr[1], 1.0),
      jnum_at(arr[2], 1.0),
      jnum_at(arr[3], 1.0),
    )
  } else {
    d
  }
}

///|
/// Decode one little-endian f32 without relying on bit reinterpretation.
fn f32_at(bytes : Bytes, off : Int) -> Float {
  if off < 0 || off + 3 >= bytes.length() {
    return 0.0
  }
  let b0 = bytes[off].to_int()
  let b1 = bytes[off + 1].to_int()
  let b2 = bytes[off + 2].to_int()
  let b3 = bytes[off + 3].to_int()
  let u : UInt = b0.reinterpret_as_uint() |
    (b1.reinterpret_as_uint() << 8) |
    (b2.reinterpret_as_uint() << 16) |
    (b3.reinterpret_as_uint() << 24)
  let sign : Float = if ((u >> 31) & (1 : UInt)) == 1 { -1.0 } else { 1.0 }
  let exp = ((u >> 23) & (0xFF : UInt)).reinterpret_as_int()
  let mant = (u & (0x7FFFFF : UInt)).reinterpret_as_int().to_double()
  if exp == 0 {
    if mant == 0.0 {
      return 0.0 * sign
    }
    let sub : Float = Float::from_double(mant * 1.1754943508222875e-38 / 8388608.0)
    return sub * sign
  }
  if exp == 255 {
    return 0.0
  }
  let mm : Float = 1.0 + Float::from_double(mant / 8388608.0)
  let e = exp - 127
  let scale : Float = if e >= 0 {
    @tmath.pow(2.0, Float::from_double(e.to_double()))
  } else {
    1.0 / @tmath.pow(2.0, Float::from_double((-e).to_double()))
  }
  mm * scale * sign
}

///|
fn view_base(
  views : Array[(Int, Int, Int)],
  index : Int,
) -> (Int, Int) {
  if index >= 0 && index < views.length() {
    let (b, off, _) = views[index]
    (b, off)
  } else {
    (-1, 0)
  }
}

///|
fn u32_at(bytes : Bytes, off : Int, comp : Int) -> Int {
  if comp == 5121 {
    bytes[off].to_int()
  } else if comp == 5123 {
    bytes[off].to_int() | (bytes[off + 1].to_int() << 8)
  } else {
    bytes[off].to_int() |
    (bytes[off + 1].to_int() << 8) |
    (bytes[off + 2].to_int() << 16) |
    (bytes[off + 3].to_int() << 24)
  }
}

///|
fn sparse_index_stride(comp : Int) -> Int {
  if comp == 5121 {
    1
  } else if comp == 5123 {
    2
  } else {
    4
  }
}

///|
fn apply_sparse_floats(
  acc : Accessor,
  buffers : Array[Bytes],
  comps : Int,
  out : FixedArray[Float],
) -> Unit {
  if acc.sparse_count <= 0 || acc.s_idx_buffer < 0 || acc.s_val_buffer < 0 {
    return
  }
  if acc.s_idx_buffer >= buffers.length() || acc.s_val_buffer >= buffers.length() {
    return
  }
  let ib = buffers[acc.s_idx_buffer]
  let vb = buffers[acc.s_val_buffer]
  let istride = sparse_index_stride(acc.s_idx_comp)
  for i = 0; i < acc.sparse_count; i = i + 1 {
    let idx = u32_at(ib, acc.s_idx_offset + i * istride, acc.s_idx_comp)
    if idx < 0 || idx >= acc.count {
      continue
    }
    for c = 0; c < comps; c = c + 1 {
      out[idx * comps + c] = f32_at(vb, acc.s_val_offset + (i * comps + c) * 4)
    }
  }
}

///|
fn apply_sparse_indices(
  acc : Accessor,
  buffers : Array[Bytes],
  out : FixedArray[UInt],
) -> Unit {
  if acc.sparse_count <= 0 || acc.s_idx_buffer < 0 || acc.s_val_buffer < 0 {
    return
  }
  if acc.s_idx_buffer >= buffers.length() || acc.s_val_buffer >= buffers.length() {
    return
  }
  let ib = buffers[acc.s_idx_buffer]
  let vb = buffers[acc.s_val_buffer]
  let istride = sparse_index_stride(acc.s_idx_comp)
  let vstride = sparse_index_stride(acc.comp)
  for i = 0; i < acc.sparse_count; i = i + 1 {
    let idx = u32_at(ib, acc.s_idx_offset + i * istride, acc.s_idx_comp)
    if idx < 0 || idx >= acc.count {
      continue
    }
    out[idx] = u32_at(vb, acc.s_val_offset + i * vstride, acc.comp).reinterpret_as_uint()
  }
}

///|
fn read_floats(acc : Accessor, buffers : Array[Bytes], comps : Int) -> FixedArray[Float] {
  let out = FixedArray::make(acc.count * comps, (0.0 : Float))
  if acc.count <= 0 {
    return out
  }
  if acc.buffer >= 0 && acc.buffer < buffers.length() {
    let buf = buffers[acc.buffer]
    let stride = if acc.stride > 0 { acc.stride } else { comps * 4 }
    for e = 0; e < acc.count; e = e + 1 {
      for c = 0; c < comps; c = c + 1 {
        out[e * comps + c] = f32_at(buf, acc.byte_offset + e * stride + c * 4)
      }
    }
  }
  apply_sparse_floats(acc, buffers, comps, out)
  out
}

///|
fn read_indices(acc : Accessor, buffers : Array[Bytes]) -> FixedArray[UInt] {
  let out = FixedArray::make(acc.count, (0 : UInt))
  if acc.buffer < 0 || acc.buffer >= buffers.length() {
    return out
  }
  let buf = buffers[acc.buffer]
  let bpp = if acc.comp == 5121 {
    1
  } else if acc.comp == 5123 {
    2
  } else {
    4
  }
  let stride = if acc.stride > 0 { acc.stride } else { bpp }
  for e = 0; e < acc.count; e = e + 1 {
    let off = acc.byte_offset + e * stride
    let v = if bpp == 1 {
      buf[off].to_int()
    } else if bpp == 2 {
      buf[off].to_int() | (buf[off + 1].to_int() << 8)
    } else {
      buf[off].to_int() |
      (buf[off + 1].to_int() << 8) |
      (buf[off + 2].to_int() << 16) |
      (buf[off + 3].to_int() << 24)
    }
    out[e] = v.reinterpret_as_uint()
  }
  apply_sparse_indices(acc, buffers, out)
  out
}

///|
/// Parse a glTF document. Buffers must be base64 `data:` URIs.
pub fn parse_gltf(text : String) -> GltfScene raise {
  let root = @json.parse(text)
  let buffers : Array[Bytes] = []
  for b in jarr(root, "buffers") {
    let uri = jstr(b, "uri", "")
    let bytes = match uri.split_once(",") {
      Some((head, data)) =>
        if head.has_prefix("data:") {
          @base64.decode(data)
        } else {
          Bytes::make(0, b'\x00')
        }
      None => Bytes::make(0, b'\x00')
    }
    buffers.push(bytes)
  }
  let views : Array[(Int, Int, Int)] = []
  for v in jarr(root, "bufferViews") {
    views.push((jint(v, "buffer", 0), jint(v, "byteOffset", 0), jint(v, "byteStride", 0)))
  }
  let accessors : Array[Accessor] = []
  for a in jarr(root, "accessors") {
    let bv = jint(a, "bufferView", -1)
    let mut buffer = -1
    let mut byte_offset = 0
    let mut stride = 0
    if bv >= 0 && bv < views.length() {
      let (b, view_off, view_stride) = views[bv]
      buffer = b
      byte_offset = view_off + jint(a, "byteOffset", 0)
      stride = view_stride
    }
    let mut sp_count = 0
    let mut sp_ib = -1
    let mut sp_ioff = 0
    let mut sp_icomp = 5125
    let mut sp_vb = -1
    let mut sp_voff = 0
    match jget(a, "sparse") {
      Some(sp) => {
        sp_count = jint(sp, "count", 0)
        match jget(sp, "indices") {
          Some(si) => {
            let (b, off) = view_base(views, jint(si, "bufferView", -1))
            sp_ib = b
            sp_ioff = off + jint(si, "byteOffset", 0)
            sp_icomp = jint(si, "componentType", 5125)
          }
          None => ()
        }
        match jget(sp, "values") {
          Some(sv) => {
            let (b, off) = view_base(views, jint(sv, "bufferView", -1))
            sp_vb = b
            sp_voff = off + jint(sv, "byteOffset", 0)
          }
          None => ()
        }
      }
      None => ()
    }
    accessors.push({
      buffer,
      byte_offset,
      count: jint(a, "count", 0),
      stride,
      comp: jint(a, "componentType", 5126),
      sparse_count: sp_count,
      s_idx_buffer: sp_ib,
      s_idx_offset: sp_ioff,
      s_idx_comp: sp_icomp,
      s_val_buffer: sp_vb,
      s_val_offset: sp_voff,
    })
  }

  let meshes : Array[MeshData] = []
  for mj in jarr(root, "meshes") {
    let positions : Array[@tmath.Vec3] = []
    let normals : Array[@tmath.Vec3] = []
    let uvs : Array[@tmath.Vec2] = []
    let indices : Array[UInt] = []
    let groups : Array[MeshGroup] = []
    let mut has_normals = true
    for pj in jarr(mj, "primitives") {
      let attrs = match jget(pj, "attributes") {
        Some(a) => a
        None => @json.Json::empty_object()
      }
      let pos_i = jint(attrs, "POSITION", -1)
      if pos_i < 0 || pos_i >= accessors.length() {
        continue
      }
      let base = positions.length()
      let pf = read_floats(accessors[pos_i], buffers, 3)
      let n = pf.length() / 3
      for i = 0; i < n; i = i + 1 {
        positions.push(@tmath.Vec3::new(pf[i * 3], pf[i * 3 + 1], pf[i * 3 + 2]))
      }
      let n_i = jint(attrs, "NORMAL", -1)
      if n_i >= 0 && n_i < accessors.length() {
        let nf = read_floats(accessors[n_i], buffers, 3)
        for i = 0; i < n; i = i + 1 {
          normals.push(@tmath.Vec3::new(nf[i * 3], nf[i * 3 + 1], nf[i * 3 + 2]))
        }
      } else {
        has_normals = false
        for i = 0; i < n; i = i + 1 {
          normals.push(@tmath.Vec3::zero())
        }
      }
      let uv_i = jint(attrs, "TEXCOORD_0", -1)
      if uv_i >= 0 && uv_i < accessors.length() {
        let tf = read_floats(accessors[uv_i], buffers, 2)
        for i = 0; i < n; i = i + 1 {
          uvs.push(@tmath.Vec2::new(tf[i * 2], tf[i * 2 + 1]))
        }
      } else {
        for i = 0; i < n; i = i + 1 {
          uvs.push(@tmath.Vec2::zero())
        }
      }
      let start = indices.length()
      let ix_i = jint(pj, "indices", -1)
      if ix_i >= 0 && ix_i < accessors.length() {
        let src = read_indices(accessors[ix_i], buffers)
        for i = 0; i < src.length(); i = i + 1 {
          indices.push(src[i] + base.reinterpret_as_uint())
        }
      } else {
        for i = 0; i < n; i = i + 1 {
          indices.push((base + i).reinterpret_as_uint())
        }
      }
      let mat = jint(pj, "material", -1)
      groups.push(
        MeshGroup::new(start, indices.length() - start, if mat >= 0 { mat } else { 0 }),
      )
    }
    let md = MeshData::new(
      FixedArray::from_array(positions),
      FixedArray::from_array(normals),
      FixedArray::from_array(uvs),
      FixedArray::from_array(indices),
    )
    md.groups = groups
    if !has_normals {
      md.compute_vertex_normals()
    }
    meshes.push(md)
  }

  let images : Array[Bytes] = []
  for im in jarr(root, "images") {
    let uri = jstr(im, "uri", "")
    let bytes = match uri.split_once(",") {
      Some((head, data)) =>
        if head.has_prefix("data:") {
          @base64.decode(data)
        } else {
          Bytes::make(0, b'\x00')
        }
      None => Bytes::make(0, b'\x00')
    }
    images.push(bytes)
  }
  let textures : Array[GltfTexture] = []
  for tj in jarr(root, "textures") {
    textures.push({ source: jint(tj, "source", -1) })
  }

  let materials : Array[GltfMaterial] = []
  for mj in jarr(root, "materials") {
    let pbr = match jget(mj, "pbrMetallicRoughness") {
      Some(p) => p
      None => @json.Json::empty_object()
    }
    let alpha_mode : GltfAlphaMode = match jstr(mj, "alphaMode", "OPAQUE") {
      "MASK" => Mask(Float::from_double(jnum(mj, "alphaCutoff", 0.5)))
      "BLEND" => Blend
      _ => Opaque
    }
    let base_color_tex = match jget(pbr, "baseColorTexture") {
      Some(t) => jint(t, "index", -1)
      None => -1
    }
    let normal_tex = match jget(mj, "normalTexture") {
      Some(t) => jint(t, "index", -1)
      None => -1
    }
    materials.push({
      name: jstr(mj, "name", ""),
      base_color: jvec4(pbr, "baseColorFactor", @tmath.Vec4::new(1.0, 1.0, 1.0, 1.0)),
      metallic: Float::from_double(jnum(pbr, "metallicFactor", 1.0)),
      roughness: Float::from_double(jnum(pbr, "roughnessFactor", 1.0)),
      alpha_mode,
      double_sided: jget(mj, "doubleSided") is Some(True),
      base_color_tex,
      normal_tex,
    })
  }

  let nodes : Array[GltfNode] = []
  for nj in jarr(root, "nodes") {
    let mut translation = @tmath.Vec3::zero()
    let mut rotation = @tmath.Quat::identity()
    let mut scale = @tmath.Vec3::one()
    match jget(nj, "matrix") {
      Some(Array(arr)) => {
        let vals = FixedArray::make(16, (0.0 : Float))
        for i = 0; i < 16 && i < arr.length(); i = i + 1 {
          vals[i] = jnum_at(arr[i], 0.0)
        }
        match @tmath.Transform::from_mat4(@tmath.Mat4::from_cols_array(vals)) {
          Some(tr) => {
            translation = tr.translation
            rotation = tr.rotation
            scale = tr.scale
          }
          None => ()
        }
      }
      _ => {
        translation = jvec3(nj, "translation", @tmath.Vec3::zero())
        let q = jarr(nj, "rotation")
        if q.length() >= 4 {
          rotation = @tmath.Quat::from_xyzw(
            jnum_at(q[0], 0.0),
            jnum_at(q[1], 0.0),
            jnum_at(q[2], 0.0),
            jnum_at(q[3], 1.0),
          )
        }
        scale = jvec3(nj, "scale", @tmath.Vec3::one())
      }
    }
    let children : Array[Int] = []
    for c in jarr(nj, "children") {
      children.push(jnum_at(c, 0.0).to_double().to_int())
    }
    nodes.push({
      name: jstr(nj, "name", ""),
      mesh: jint(nj, "mesh", -1),
      translation,
      rotation,
      scale,
      children,
    })
  }

  let roots : Array[Int] = []
  match jget(root, "scenes") {
    Some(Array(scenes)) =>
      if scenes.length() > 0 {
        for n in jarr(scenes[0], "nodes") {
          roots.push(jnum_at(n, 0.0).to_double().to_int())
        }
      }
    _ => ()
  }
  if roots.length() == 0 {
    let referenced : Array[Bool] = []
    for i = 0; i < nodes.length(); i = i + 1 {
      referenced.push(false)
    }
    for n in nodes {
      for c in n.children {
        if c >= 0 && c < referenced.length() {
          referenced[c] = true
        }
      }
    }
    for i = 0; i < nodes.length(); i = i + 1 {
      if !referenced[i] {
        roots.push(i)
      }
    }
  }
  { meshes, materials, nodes, roots, textures, images }
}
