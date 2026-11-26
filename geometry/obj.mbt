// Minimal Wavefront OBJ importer: positions, UVs, normals, polygons (fan
// triangulated), `o` / `g` part splitting, positive and negative indices.
// Materials (`usemtl`) and smoothing groups are intentionally ignored: this
// module only produces geometry, materials belong to tycho_3d.

///|
/// Split a byte range into `(start, end)` token ranges.
fn split_tokens(data : Bytes, start : Int, end : Int) -> Array[(Int, Int)] {
  let out : Array[(Int, Int)] = []
  let mut i = start
  while i < end {
    while i < end && (data[i] == b' ' || data[i] == b'\t' || data[i] == b'\r') {
      i = i + 1
    }
    if i < end {
      let s = i
      while i < end && data[i] != b' ' && data[i] != b'\t' && data[i] != b'\r' {
        i = i + 1
      }
      out.push((s, i))
    }
  }
  out
}

///|
fn parse_int_slice(data : Bytes, start : Int, end : Int) -> Int {
  let mut i = start
  let mut sign = 1
  if i < end && data[i] == b'-' {
    sign = -1
    i = i + 1
  }
  let mut acc = 0
  while i < end {
    let c = data[i].to_int()
    if c >= 48 && c <= 57 {
      acc = acc * 10 + (c - 48)
    }
    i = i + 1
  }
  acc * sign
}

///|
fn parse_float_slice(data : Bytes, start : Int, end : Int) -> Float {
  let mut i = start
  let mut sign = 1.0
  if i < end && data[i] == b'-' {
    sign = -1.0
    i = i + 1
  } else if i < end && data[i] == b'+' {
    i = i + 1
  }
  let mut int_part = 0.0
  while i < end && data[i] != b'.' && data[i] != b'e' && data[i] != b'E' {
    let c = data[i].to_int()
    if c >= 48 && c <= 57 {
      int_part = int_part * 10.0 + (c - 48).to_double()
    }
    i = i + 1
  }
  let mut frac_part = 0.0
  let mut scale = 1.0
  if i < end && data[i] == b'.' {
    i = i + 1
    while i < end && data[i] != b'e' && data[i] != b'E' {
      let c = data[i].to_int()
      if c >= 48 && c <= 57 {
        frac_part = frac_part * 10.0 + (c - 48).to_double()
        scale = scale * 10.0
      }
      i = i + 1
    }
  }
  let mut value = sign * (int_part + frac_part / scale)
  if i < end && (data[i] == b'e' || data[i] == b'E') {
    i = i + 1
    let mut exp_sign = 1
    if i < end && data[i] == b'-' {
      exp_sign = -1
      i = i + 1
    } else if i < end && data[i] == b'+' {
      i = i + 1
    }
    let mut exp = 0
    while i < end {
      let c = data[i].to_int()
      if c >= 48 && c <= 57 {
        exp = exp * 10 + (c - 48)
      }
      i = i + 1
    }
    let mut k = 0
    let factor = if exp_sign > 0 { 10.0 } else { 0.1 }
    while k < exp {
      value = value * factor
      k = k + 1
    }
  }
  Float::from_double(value)
}

///|
fn is_kw(data : Bytes, s : Int, e : Int, kw : String) -> Bool {
  let kb = @utf8.encode(kw)
  if e - s != kb.length() {
    return false
  }
  let mut i = 0
  while i < kb.length() {
    if data[s + i] != kb[i] {
      return false
    }
    i = i + 1
  }
  true
}

///|
/// Resolve one OBJ index (1-based positive, or negative from the end) to a
/// 0-based index, or -1 when absent/out of range.
fn resolve_index(raw : Int, count : Int) -> Int {
  if raw > 0 {
    let i = raw - 1
    if i < count {
      i
    } else {
      -1
    }
  } else if raw < 0 {
    let i = count + raw
    if i >= 0 && i < count {
      i
    } else {
      -1
    }
  } else {
    -1
  }
}

///|
/// Parse one `v`, `v/vt`, `v//vn` or `v/vt/vn` face corner into 0-based indices.
/// Returns (-1, -1, -1) when the position index is invalid.
fn parse_face_corner(
  data : Bytes,
  s : Int,
  e : Int,
  position_count : Int,
  uv_count : Int,
  normal_count : Int,
) -> (Int, Int, Int) {
  let mut s1 = s
  while s1 < e && data[s1] != b'/' {
    s1 = s1 + 1
  }
  let vi = resolve_index(parse_int_slice(data, s, s1), position_count)
  if vi < 0 {
    return (-1, -1, -1)
  }
  if s1 >= e {
    return (vi, -1, -1)
  }
  let mut s2 = s1 + 1
  while s2 < e && data[s2] != b'/' {
    s2 = s2 + 1
  }
  let vti = if s2 > s1 + 1 {
    resolve_index(parse_int_slice(data, s1 + 1, s2), uv_count)
  } else {
    -1
  }
  let vni = if s2 < e - 1 {
    resolve_index(parse_int_slice(data, s2 + 1, e), normal_count)
  } else {
    -1
  }
  (vi, vti, vni)
}

///|
fn finish_part(builder : MeshBuilder, has_normals : Bool) -> MeshData {
  let mesh = builder.build()
  if !has_normals {
    mesh.compute_vertex_normals()
  }
  mesh
}

///|
/// Parse OBJ text (as bytes) into named parts. Parts without `vn` get
/// area-weighted normals; parts without `vt` get zero UVs.
pub fn parse_obj(data : Bytes) -> Array[(String, MeshData)] {
  let positions : Array[@tmath.Vec3] = []
  let uvs : Array[@tmath.Vec2] = []
  let normals : Array[@tmath.Vec3] = []
  let result : Array[(String, MeshData)] = []
  let mut builder = MeshBuilder::new()
  let mut name : String = ""
  let mut part_has_normals = true
  let mut part_dirty = false
  let n = data.length()
  let mut line = 0
  while line < n {
    let mut end = line
    while end < n && data[end] != b'\n' {
      end = end + 1
    }
    let toks = split_tokens(data, line, end)
    if toks.length() > 0 {
      let (s0, e0) = toks[0]
      if is_kw(data, s0, e0, "v") && toks.length() >= 4 {
        let (s1, e1) = toks[1]
        let (s2, e2) = toks[2]
        let (s3, e3) = toks[3]
        positions.push(
          @tmath.Vec3::new(
            parse_float_slice(data, s1, e1),
            parse_float_slice(data, s2, e2),
            parse_float_slice(data, s3, e3),
          ),
        )
      } else if is_kw(data, s0, e0, "vt") && toks.length() >= 3 {
        let (s1, e1) = toks[1]
        let (s2, e2) = toks[2]
        uvs.push(
          @tmath.Vec2::new(parse_float_slice(data, s1, e1), parse_float_slice(data, s2, e2)),
        )
      } else if is_kw(data, s0, e0, "vn") && toks.length() >= 4 {
        let (s1, e1) = toks[1]
        let (s2, e2) = toks[2]
        let (s3, e3) = toks[3]
        normals.push(
          @tmath.Vec3::new(
            parse_float_slice(data, s1, e1),
            parse_float_slice(data, s2, e2),
            parse_float_slice(data, s3, e3),
          ),
        )
      } else if is_kw(data, s0, e0, "o") || is_kw(data, s0, e0, "g") {
        if part_dirty {
          result.push((name, finish_part(builder, part_has_normals)))
          builder = MeshBuilder::new()
          part_has_normals = true
          part_dirty = false
        }
        if toks.length() >= 2 {
          let (s1, e1) = toks[1]
          name = @utf8.decode_lossy(data.clamped_view(start=s1, end=e1))
        } else {
          name = ""
        }
      } else if is_kw(data, s0, e0, "f") && toks.length() >= 4 {
        let corners : Array[(Int, Int, Int)] = []
        let mut valid = true
        let mut k = 1
        while k < toks.length() {
          let (ts, te) = toks[k]
          let c = parse_face_corner(data, ts, te, positions.length(), uvs.length(), normals.length())
          if c.0 < 0 {
            valid = false
            break
          }
          corners.push(c)
          k = k + 1
        }
        if valid && corners.length() >= 3 {
          let vidx : Array[Int] = []
          for c in corners {
            let uv = if c.1 >= 0 { uvs[c.1] } else { @tmath.Vec2::zero() }
            let nrm = if c.2 >= 0 { normals[c.2] } else { @tmath.Vec3::zero() }
            if c.2 < 0 {
              part_has_normals = false
            }
            vidx.push(builder.vertex(positions[c.0], nrm, uv).reinterpret_as_int())
          }
          for t = 1; t + 1 < vidx.length(); t = t + 1 {
            builder.tri(vidx[0].reinterpret_as_uint(), vidx[t].reinterpret_as_uint(), vidx[t + 1].reinterpret_as_uint())
          }
          part_dirty = true
        }
      }
    }
    line = end + 1
  }
  if part_dirty {
    result.push((name, finish_part(builder, part_has_normals)))
  }
  result
}

///|
/// Convenience wrapper for callers that already hold a `String`.
pub fn parse_obj_text(text : String) -> Array[(String, MeshData)] {
  parse_obj(@utf8.encode(text))
}
