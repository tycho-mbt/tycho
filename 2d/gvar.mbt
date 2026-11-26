// gvar tuple-variation deltas for simple TrueType glyphs.

///|
fn gvar_f2(v : Int) -> Float {
  Float::from_double(v.to_double() / 16384.0)
}

///|
// Packed point numbers. An empty result means "all points" (the first byte is
// zero), otherwise the numbers are deltas from the previous point.
fn gvar_read_points(b : Bytes, start : Int, end : Int) -> (Array[Int], Int) {
  let out : Array[Int] = []
  if start >= end {
    return (out, start)
  }
  let first = b[start].to_int()
  let mut p = start + 1
  if first == 0 {
    return (out, p)
  }
  let mut count = first & 0x7F
  if (first & 0x80) != 0 && p < end {
    count = (count << 8) | b[p].to_int()
    p = p + 1
  }
  let mut prev = 0
  while out.length() < count && p < end {
    let control = b[p].to_int()
    p = p + 1
    let run = (control & 0x7F) + 1
    if (control & 0x80) != 0 {
      for _r = 0; _r < run && out.length() < count && p + 2 <= end; _r = _r + 1 {
        prev = prev + be_u16(b, p)
        p = p + 2
        out.push(prev)
      }
    } else {
      for _r = 0; _r < run && out.length() < count && p < end; _r = _r + 1 {
        prev = prev + b[p].to_int()
        p = p + 1
        out.push(prev)
      }
    }
  }
  (out, p)
}

///|
fn gvar_read_deltas(
  b : Bytes,
  start : Int,
  end : Int,
  count : Int,
) -> (Array[Float], Int) {
  let out = Array::make(count, (0.0 : Float))
  let mut p = start
  let mut i = 0
  while i < count && p < end {
    let control = b[p].to_int()
    p = p + 1
    let run = (control & 0x3F) + 1
    if (control & 0x80) != 0 {
      i = i + run
    } else if (control & 0x40) != 0 {
      for _r = 0; _r < run && i < count && p + 2 <= end; _r = _r + 1 {
        out[i] = Float::from_int(be_i16(b, p))
        p = p + 2
        i = i + 1
      }
    } else {
      for _r = 0; _r < run && i < count && p < end; _r = _r + 1 {
        out[i] = Float::from_int(be_i8(b, p))
        p = p + 1
        i = i + 1
      }
    }
  }
  (out, p)
}

///|
fn gvar_scalar(
  peak : Array[Int],
  start : Array[Int],
  end : Array[Int],
  coords : Array[Float],
) -> Float {
  let mut scalar : Float = 1.0
  for a = 0; a < peak.length(); a = a + 1 {
    if peak[a] == 0 {
      continue
    }
    let pk = gvar_f2(peak[a])
    let v = if a < coords.length() { coords[a] } else { (0.0 : Float) }
    if v == pk {
      continue
    }
    let st = gvar_f2(start[a])
    let en = gvar_f2(end[a])
    if v <= st || v >= en {
      return (0.0 : Float)
    }
    if v < pk {
      scalar = scalar * (v - st) / (pk - st)
    } else {
      scalar = scalar * (en - v) / (en - pk)
    }
  }
  scalar
}

///|
fn gvar_deltas(
  t : TtfData,
  gid : Int,
  coords : Array[Float],
  n_pts : Int,
) -> (Array[Float], Array[Float]) {
  let dx = Array::make(n_pts, (0.0 : Float))
  let dy = Array::make(n_pts, (0.0 : Float))
  if t.gvar_off < 0 || gid < 0 || n_pts <= 0 {
    return (dx, dy)
  }
  let b = t.bytes
  let gv = t.gvar_off
  if gv + 20 > b.length() {
    return (dx, dy)
  }
  let axis_count = be_u16(b, gv + 4)
  let shared_count = be_u16(b, gv + 6)
  let shared_off = gv + be_u32(b, gv + 8).reinterpret_as_int()
  let glyph_count = be_u16(b, gv + 12)
  let flags = be_u16(b, gv + 14)
  if gid >= glyph_count {
    return (dx, dy)
  }
  let data_base = gv + be_u32(b, gv + 16).reinterpret_as_int()
  let offs = gv + 20
  let (o0, o1) = if (flags & 1) != 0 {
    (
      be_u32(b, offs + gid * 4).reinterpret_as_int(),
      be_u32(b, offs + (gid + 1) * 4).reinterpret_as_int(),
    )
  } else {
    (
      be_u16(b, offs + gid * 2) * 2,
      be_u16(b, offs + (gid + 1) * 2) * 2,
    )
  }
  if o1 <= o0 {
    return (dx, dy)
  }
  let gvd = data_base + o0
  if gvd + 4 > b.length() {
    return (dx, dy)
  }
  let tuple_count_raw = be_u16(b, gvd)
  let tuple_count = tuple_count_raw & 0x0FFF
  let data_off = gvd + be_u16(b, gvd + 2)
  let mut data_ptr = data_off
  // 0x8000: one shared packed-point list precedes all tuple deltas.
  let shared_points : Array[Int] = []
  if (tuple_count_raw & 0x8000) != 0 {
    let (pts, p) = gvar_read_points(b, data_ptr, b.length())
    for v in pts {
      shared_points.push(v)
    }
    data_ptr = p
  }
  let mut hdr = gvd + 4
  for _ti = 0; _ti < tuple_count; _ti = _ti + 1 {
    if hdr + 4 > b.length() {
      break
    }
    let size = be_u16(b, hdr)
    let idx = be_u16(b, hdr + 2)
    hdr = hdr + 4
    let peak : Array[Int] = []
    if (idx & 0x8000) != 0 {
      for a = 0; a < axis_count; a = a + 1 {
        peak.push(be_i16(b, hdr + a * 2))
      }
      hdr = hdr + axis_count * 2
    } else {
      let si = idx & 0x0FFF
      if si < shared_count {
        let base = shared_off + si * axis_count * 2
        for a = 0; a < axis_count; a = a + 1 {
          peak.push(be_i16(b, base + a * 2))
        }
      } else {
        for _a = 0; _a < axis_count; _a = _a + 1 {
          peak.push(0)
        }
      }
    }
    let start : Array[Int] = []
    let end : Array[Int] = []
    if (idx & 0x4000) != 0 {
      for a = 0; a < axis_count; a = a + 1 {
        start.push(be_i16(b, hdr + a * 2))
      }
      hdr = hdr + axis_count * 2
      for a = 0; a < axis_count; a = a + 1 {
        end.push(be_i16(b, hdr + a * 2))
      }
      hdr = hdr + axis_count * 2
    } else {
      for a = 0; a < axis_count; a = a + 1 {
        start.push(if peak[a] < 0 { peak[a] } else { 0 })
        end.push(if peak[a] > 0 { peak[a] } else { 0 })
      }
    }
    let tuple_end = data_ptr + size
    let scalar = gvar_scalar(peak, start, end, coords)
    let mut p = data_ptr
    let points : Array[Int] = []
    if (idx & 0x2000) != 0 {
      let (own, after) = gvar_read_points(b, p, tuple_end)
      for v in own {
        points.push(v)
      }
      p = after
    } else {
      for v in shared_points {
        points.push(v)
      }
    }
    if scalar != 0.0 {
      let count = if points.length() > 0 { points.length() } else { n_pts + 4 }
      let (ddx, after_x) = gvar_read_deltas(b, p, tuple_end, count)
      let (ddy, _after_y) = gvar_read_deltas(b, after_x, tuple_end, count)
      for k = 0; k < count; k = k + 1 {
        let point = if points.length() > 0 { points[k] } else { k }
        if point >= 0 && point < n_pts {
          dx[point] = dx[point] + scalar * ddx[k]
          dy[point] = dy[point] + scalar * ddy[k]
        }
      }
    }
    data_ptr = tuple_end
  }
  (dx, dy)
}
