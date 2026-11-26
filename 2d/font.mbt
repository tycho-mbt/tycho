// Pure-MoonBit TrueType (.ttf) parser + analytical scanline rasterizer + built-in crisp bitmap fallback font.

///|
fn be_u16(b : Bytes, off : Int) -> Int {
  (b[off].to_int() << 8) | b[off + 1].to_int()
}

///|
fn be_i16(b : Bytes, off : Int) -> Int {
  let v = be_u16(b, off)
  if v >= 0x8000 { v - 0x10000 } else { v }
}

///|
fn be_u32(b : Bytes, off : Int) -> UInt {
  ((b[off].to_int() & 0xFF).reinterpret_as_uint() << 24) |
  ((b[off + 1].to_int() & 0xFF).reinterpret_as_uint() << 16) |
  ((b[off + 2].to_int() & 0xFF).reinterpret_as_uint() << 8) |
  (b[off + 3].to_int() & 0xFF).reinterpret_as_uint()
}

///|
fn be_i32(b : Bytes, off : Int) -> Int {
  be_u32(b, off).reinterpret_as_int()
}

///|
fn tag_eq(b : Bytes, off : Int, s : String) -> Bool {
  if off + 4 > b.length() || s.length() != 4 {
    return false
  }
  b[off].to_int() == s[0].to_int() &&
  b[off + 1].to_int() == s[1].to_int() &&
  b[off + 2].to_int() == s[2].to_int() &&
  b[off + 3].to_int() == s[3].to_int()
}

///|
priv struct TtfData {
  bytes : Bytes
  units_per_em : Int
  ascent : Int
  descent : Int
  line_gap : Int
  num_glyphs : Int
  num_hmetrics : Int
  index_to_loc_format : Int
  loca_off : Int
  glyf_off : Int
  hmtx_off : Int
  cmap_subtable_off : Int
  cmap_format : Int
}

///|
fn parse_ttf(bytes : Bytes) -> TtfData? {
  if bytes.length() < 12 {
    return None
  }
  let num_tables = be_u16(bytes, 4)
  if bytes.length() < 12 + num_tables * 16 {
    return None
  }
  let mut head_off = -1
  let mut hhea_off = -1
  let mut maxp_off = -1
  let mut loca_off = -1
  let mut glyf_off = -1
  let mut hmtx_off = -1
  let mut cmap_off = -1
  for i = 0; i < num_tables; i = i + 1 {
    let rec = 12 + i * 16
    let off = be_i32(bytes, rec + 8)
    if tag_eq(bytes, rec, "head") { head_off = off }
    else if tag_eq(bytes, rec, "hhea") { hhea_off = off }
    else if tag_eq(bytes, rec, "maxp") { maxp_off = off }
    else if tag_eq(bytes, rec, "loca") { loca_off = off }
    else if tag_eq(bytes, rec, "glyf") { glyf_off = off }
    else if tag_eq(bytes, rec, "hmtx") { hmtx_off = off }
    else if tag_eq(bytes, rec, "cmap") { cmap_off = off }
  }
  if head_off < 0 || hhea_off < 0 || maxp_off < 0 || loca_off < 0 ||
    glyf_off < 0 || hmtx_off < 0 || cmap_off < 0 {
    return None
  }
  let units_per_em = be_u16(bytes, head_off + 18)
  if units_per_em <= 0 {
    return None
  }
  let index_to_loc_format = be_i16(bytes, head_off + 50)
  let ascent = be_i16(bytes, hhea_off + 4)
  let descent = be_i16(bytes, hhea_off + 6)
  let line_gap = be_i16(bytes, hhea_off + 8)
  let num_hmetrics = be_u16(bytes, hhea_off + 34)
  let num_glyphs = be_u16(bytes, maxp_off + 4)

  // Pick best cmap subtable: prefer Format 12 (3,10) then Format 4 (3,1 / 0,3 / 0,4).
  let n_sub = be_u16(bytes, cmap_off + 2)
  let mut best_off = -1
  let mut best_fmt = 0
  for i = 0; i < n_sub; i = i + 1 {
    let rec = cmap_off + 4 + i * 8
    let pid = be_u16(bytes, rec)
    let eid = be_u16(bytes, rec + 2)
    let sub = cmap_off + be_i32(bytes, rec + 4)
    if sub + 4 > bytes.length() {
      continue
    }
    let fmt = be_u16(bytes, sub)
    if fmt == 12 && ((pid == 3 && eid == 10) || pid == 0) {
      best_off = sub
      best_fmt = 12
      break
    } else if fmt == 4 && ((pid == 3 && eid == 1) || pid == 0) && best_fmt != 12 {
      best_off = sub
      best_fmt = 4
    }
  }
  if best_off < 0 {
    return None
  }
  Some({
    bytes,
    units_per_em,
    ascent,
    descent,
    line_gap,
    num_glyphs,
    num_hmetrics,
    index_to_loc_format,
    loca_off,
    glyf_off,
    hmtx_off,
    cmap_subtable_off: best_off,
    cmap_format: best_fmt,
  })
}

///|
fn ttf_glyph_id(t : TtfData, cp : Int) -> Int {
  let b = t.bytes
  let sub = t.cmap_subtable_off
  if t.cmap_format == 12 {
    let n_groups = be_i32(b, sub + 12)
    let mut lo = 0
    let mut hi = n_groups - 1
    while lo <= hi {
      let mid = (lo + hi) / 2
      let rec = sub + 16 + mid * 12
      let start_c = be_i32(b, rec)
      let end_c = be_i32(b, rec + 4)
      if cp < start_c {
        hi = mid - 1
      } else if cp > end_c {
        lo = mid + 1
      } else {
        let start_gid = be_i32(b, rec + 8)
        return start_gid + (cp - start_c)
      }
    }
    return 0
  }
  if t.cmap_format == 4 && cp <= 0xFFFF {
    let seg_count = be_u16(b, sub + 6) / 2
    let end_base = sub + 14
    let start_base = end_base + seg_count * 2 + 2
    let delta_base = start_base + seg_count * 2
    let range_base = delta_base + seg_count * 2
    let mut lo = 0
    let mut hi = seg_count - 1
    while lo <= hi {
      let mid = (lo + hi) / 2
      let end_c = be_u16(b, end_base + mid * 2)
      let start_c = be_u16(b, start_base + mid * 2)
      if cp > end_c {
        lo = mid + 1
      } else if cp < start_c {
        hi = mid - 1
      } else {
        let delta = be_i16(b, delta_base + mid * 2)
        let roff = be_u16(b, range_base + mid * 2)
        if roff == 0 {
          return (cp + delta) & 0xFFFF
        }
        let gid_off = range_base + mid * 2 + roff + (cp - start_c) * 2
        if gid_off + 2 > b.length() {
          return 0
        }
        let gid = be_u16(b, gid_off)
        if gid == 0 {
          return 0
        }
        return (gid + delta) & 0xFFFF
      }
    }
  }
  0
}

///|
fn ttf_advance_units(t : TtfData, gid : Int) -> Int {
  let b = t.bytes
  if gid < t.num_hmetrics {
    be_u16(b, t.hmtx_off + gid * 4)
  } else if t.num_hmetrics > 0 {
    be_u16(b, t.hmtx_off + (t.num_hmetrics - 1) * 4)
  } else {
    t.units_per_em / 2
  }
}

///|
fn ttf_glyf_range(t : TtfData, gid : Int) -> (Int, Int) {
  if gid < 0 || gid >= t.num_glyphs {
    return (0, 0)
  }
  let b = t.bytes
  if t.index_to_loc_format == 0 {
    let o0 = be_u16(b, t.loca_off + gid * 2) * 2
    let o1 = be_u16(b, t.loca_off + (gid + 1) * 2) * 2
    (t.glyf_off + o0, t.glyf_off + o1)
  } else {
    let o0 = be_i32(b, t.loca_off + gid * 4)
    let o1 = be_i32(b, t.loca_off + (gid + 1) * 4)
    (t.glyf_off + o0, t.glyf_off + o1)
  }
}

///|
// Flattened edge segments for analytical scanline AA rasterization.
priv struct RasterEdge {
  x0 : Double
  y0 : Double
  x1 : Double
  y1 : Double
}

///|
fn flatten_ttf_quad(
  edges : Array[RasterEdge],
  ax : Double,
  ay : Double,
  bx : Double,
  by : Double,
  cx : Double,
  cy : Double,
  depth : Int,
) -> Unit {
  let mx = (ax + cx) * 0.5
  let my = (ay + cy) * 0.5
  let dx = bx - mx
  let dy = by - my
  if depth >= 6 || dx * dx + dy * dy <= 0.04 {
    edges.push({ x0: ax, y0: ay, x1: cx, y1: cy })
    return
  }
  let abx = (ax + bx) * 0.5
  let aby = (ay + by) * 0.5
  let bcx = (bx + cx) * 0.5
  let bcy = (by + cy) * 0.5
  let midx = (abx + bcx) * 0.5
  let midy = (aby + bcy) * 0.5
  flatten_ttf_quad(edges, ax, ay, abx, aby, midx, midy, depth + 1)
  flatten_ttf_quad(edges, midx, midy, bcx, bcy, cx, cy, depth + 1)
}

///|
fn collect_ttf_edges(
  t : TtfData,
  gid : Int,
  scale : Double,
  ox : Double,
  oy : Double,
  edges : Array[RasterEdge],
  depth : Int,
) -> Unit {
  if depth > 4 {
    return
  }
  let (g_start, g_end) = ttf_glyf_range(t, gid)
  if g_end <= g_start + 10 || g_end > t.bytes.length() {
    return
  }
  let b = t.bytes
  let n_contours = be_i16(b, g_start)
  if n_contours < 0 {
    // Compound glyph
    let mut p = g_start + 10
    while p + 4 <= g_end {
      let flags = be_u16(b, p)
      let sub_gid = be_u16(b, p + 2)
      p = p + 4
      let args_are_words = (flags & 1) != 0
      let args_are_xy = (flags & 2) != 0
      let mut dx = 0.0
      let mut dy = 0.0
      if args_are_words {
        if args_are_xy {
          dx = be_i16(b, p).to_double()
          dy = be_i16(b, p + 2).to_double()
        }
        p = p + 4
      } else {
        if args_are_xy {
          let x_u = b[p].to_int()
          let y_u = b[p + 1].to_int()
          dx = (if x_u >= 128 { x_u - 256 } else { x_u }).to_double()
          dy = (if y_u >= 128 { y_u - 256 } else { y_u }).to_double()
        }
        p = p + 2
      }
      if (flags & 0x0008) != 0 {
        p = p + 2
      } else if (flags & 0x0040) != 0 {
        p = p + 4
      } else if (flags & 0x0080) != 0 {
        p = p + 8
      }
      collect_ttf_edges(t, sub_gid, scale, ox + dx * scale, oy - dy * scale, edges, depth + 1)
      if (flags & 0x0020) == 0 {
        break
      }
    }
    return
  }
  if n_contours == 0 {
    return
  }
  let end_pts : Array[Int] = []
  let mut p = g_start + 10
  for i = 0; i < n_contours; i = i + 1 {
    end_pts.push(be_u16(b, p))
    p = p + 2
  }
  let n_pts = end_pts[n_contours - 1] + 1
  let instr_len = be_u16(b, p)
  p = p + 2 + instr_len

  let flags : Array[Int] = Array::make(n_pts, 0)
  let mut fi = 0
  while fi < n_pts && p < g_end {
    let fl = b[p].to_int()
    p = p + 1
    flags[fi] = fl
    fi = fi + 1
    if (fl & 8) != 0 && p < g_end {
      let rep = b[p].to_int()
      p = p + 1
      for _r = 0; _r < rep && fi < n_pts; _r = _r + 1 {
        flags[fi] = fl
        fi = fi + 1
      }
    }
  }
  let xs : Array[Double] = Array::make(n_pts, 0.0)
  let ys : Array[Double] = Array::make(n_pts, 0.0)
  let mut cx = 0
  for i = 0; i < n_pts && p <= g_end; i = i + 1 {
    let fl = flags[i]
    let dx = if (fl & 2) != 0 {
      let v = b[p].to_int()
      p = p + 1
      if (fl & 16) != 0 { v } else { -v }
    } else if (fl & 16) != 0 {
      0
    } else {
      let v = be_i16(b, p)
      p = p + 2
      v
    }
    cx = cx + dx
    xs[i] = ox + cx.to_double() * scale
  }
  let mut cy = 0
  for i = 0; i < n_pts && p <= g_end; i = i + 1 {
    let fl = flags[i]
    let dy = if (fl & 4) != 0 {
      let v = b[p].to_int()
      p = p + 1
      if (fl & 32) != 0 { v } else { -v }
    } else if (fl & 32) != 0 {
      0
    } else {
      let v = be_i16(b, p)
      p = p + 2
      v
    }
    cy = cy + dy
    ys[i] = oy - cy.to_double() * scale
  }

  let mut start = 0
  for c = 0; c < n_contours; c = c + 1 {
    let end = end_pts[c]
    let count = end - start + 1
    if count >= 2 {
      // Find first on-curve point or synthesize midpoint
      let mut s_x = 0.0
      let mut s_y = 0.0
      let mut idx0 = 0
      if (flags[start] & 1) != 0 {
        s_x = xs[start]
        s_y = ys[start]
        idx0 = 1
      } else if (flags[end] & 1) != 0 {
        s_x = xs[end]
        s_y = ys[end]
        idx0 = 0
      } else {
        s_x = (xs[start] + xs[end]) * 0.5
        s_y = (ys[start] + ys[end]) * 0.5
        idx0 = 0
      }
      let mut px = s_x
      let mut py = s_y
      let mut has_ctrl = false
      let mut ctrl_x = 0.0
      let mut ctrl_y = 0.0
      for step = 0; step < count; step = step + 1 {
        let pt_i = start + (idx0 + step) % count
        let x = xs[pt_i]
        let y = ys[pt_i]
        let on_curve = (flags[pt_i] & 1) != 0
        if on_curve {
          if has_ctrl {
            flatten_ttf_quad(edges, px, py, ctrl_x, ctrl_y, x, y, 0)
            has_ctrl = false
          } else {
            edges.push({ x0: px, y0: py, x1: x, y1: y })
          }
          px = x
          py = y
        } else if has_ctrl {
          let mid_x = (ctrl_x + x) * 0.5
          let mid_y = (ctrl_y + y) * 0.5
          flatten_ttf_quad(edges, px, py, ctrl_x, ctrl_y, mid_x, mid_y, 0)
          px = mid_x
          py = mid_y
          ctrl_x = x
          ctrl_y = y
        } else {
          ctrl_x = x
          ctrl_y = y
          has_ctrl = true
        }
      }
      if has_ctrl {
        flatten_ttf_quad(edges, px, py, ctrl_x, ctrl_y, s_x, s_y, 0)
      } else if px != s_x || py != s_y {
        edges.push({ x0: px, y0: py, x1: s_x, y1: s_y })
      }
    }
    start = end + 1
  }
}

///|
fn rasterize_ttf_glyph(
  t : TtfData,
  cp : Int,
  size_px : Float,
) -> (Int, Int, Int, Int, Bytes) {
  let gid = ttf_glyph_id(t, cp)
  let scale = size_px.to_double() / t.units_per_em.to_double()
  let edges : Array[RasterEdge] = []
  collect_ttf_edges(t, gid, scale, 0.0, 0.0, edges, 0)
  if edges.length() == 0 {
    return (0, 0, 0, 0, b"")
  }
  let mut min_x = 1.0e9
  let mut min_y = 1.0e9
  let mut max_x = -1.0e9
  let mut max_y = -1.0e9
  for e in edges {
    if e.x0 < min_x { min_x = e.x0 }
    if e.x1 < min_x { min_x = e.x1 }
    if e.x0 > max_x { max_x = e.x0 }
    if e.x1 > max_x { max_x = e.x1 }
    if e.y0 < min_y { min_y = e.y0 }
    if e.y1 < min_y { min_y = e.y1 }
    if e.y0 > max_y { max_y = e.y0 }
    if e.y1 > max_y { max_y = e.y1 }
  }
  let ix0 = min_x.floor().to_int() - 1
  let iy0 = min_y.floor().to_int() - 1
  let ix1 = max_x.ceil().to_int() + 1
  let iy1 = max_y.ceil().to_int() + 1
  let w = if ix1 > ix0 { ix1 - ix0 } else { 1 }
  let h = if iy1 > iy0 { iy1 - iy0 } else { 1 }
  let pixels = Array::make(w * h, (0 : Byte))
  // 4x4 supersampled non-zero winding rasterizer for clean crisp anti-aliasing
  let subs = 4
  let inv_sub = 1.0 / subs.to_double()
  let xs : Array[Double] = []
  let dirs : Array[Int] = []
  for py = 0; py < h; py = py + 1 {
    let row_acc = Array::make(w, 0)
    for sy = 0; sy < subs; sy = sy + 1 {
      let sample_y = (iy0 + py).to_double() + (sy.to_double() + 0.5) * inv_sub
      xs.clear()
      dirs.clear()
      for e in edges {
        let up = e.y0 <= sample_y && e.y1 > sample_y
        let dn = e.y1 <= sample_y && e.y0 > sample_y
        if up || dn {
          let x_hit = e.x0 + (sample_y - e.y0) * (e.x1 - e.x0) / (e.y1 - e.y0)
          xs.push(x_hit)
          dirs.push(if up { 1 } else { -1 })
        }
      }
      // Sort intersections by x (tiny N per scanline)
      for i = 1; i < xs.length(); i = i + 1 {
        let kx = xs[i]
        let kd = dirs[i]
        let mut j = i - 1
        while j >= 0 && xs[j] > kx {
          xs[j + 1] = xs[j]
          dirs[j + 1] = dirs[j]
          j = j - 1
        }
        xs[j + 1] = kx
        dirs[j + 1] = kd
      }
      for px = 0; px < w; px = px + 1 {
        for sx = 0; sx < subs; sx = sx + 1 {
          let sample_x = (ix0 + px).to_double() + (sx.to_double() + 0.5) * inv_sub
          let mut winding = 0
          for k = 0; k < xs.length(); k = k + 1 {
            if xs[k] <= sample_x {
              winding = winding + dirs[k]
            } else {
              break
            }
          }
          if winding != 0 {
            row_acc[px] = row_acc[px] + 1
          }
        }
      }
    }
    for px = 0; px < w; px = px + 1 {
      let a = (row_acc[px] * 255) / (subs * subs)
      pixels[py * w + px] = (if a > 255 { 255 } else { a }).to_byte()
    }
  }
  (ix0, iy0, w, h, Bytes::from_array(pixels[:]))
}

///|
// Embedded crisp 5x7 ASCII bitmap font rows (each char is 7 rows of 5 bits, packed MSB left).
fn builtin_glyph_rows(cp : Int) -> FixedArray[Int] {
  match cp {
    32 => [0, 0, 0, 0, 0, 0, 0] // ' '
    33 => [4, 4, 4, 4, 4, 0, 4] // '!'
    34 => [10, 10, 10, 0, 0, 0, 0] // '"'
    35 => [10, 31, 10, 10, 31, 10, 0] // '#'
    36 => [4, 15, 20, 14, 5, 30, 4] // '$'
    37 => [24, 25, 2, 4, 8, 19, 3] // '%'
    38 => [8, 20, 20, 8, 21, 18, 13] // '&'
    39 => [4, 4, 8, 0, 0, 0, 0] // '\''
    40 => [2, 4, 8, 8, 8, 4, 2] // '('
    41 => [8, 4, 2, 2, 2, 4, 8] // ')'
    42 => [0, 4, 21, 14, 21, 4, 0] // '*'
    43 => [0, 4, 4, 31, 4, 4, 0] // '+'
    44 => [0, 0, 0, 0, 4, 4, 8] // ','
    45 => [0, 0, 0, 31, 0, 0, 0] // '-'
    46 => [0, 0, 0, 0, 0, 12, 12] // '.'
    47 => [0, 1, 2, 4, 8, 16, 0] // '/'
    48 => [14, 17, 19, 21, 25, 17, 14] // '0'
    49 => [4, 12, 4, 4, 4, 4, 14] // '1'
    50 => [14, 17, 1, 6, 8, 16, 31] // '2'
    51 => [31, 2, 4, 6, 1, 17, 14] // '3'
    52 => [2, 6, 10, 18, 31, 2, 2] // '4'
    53 => [31, 16, 30, 1, 1, 17, 14] // '5'
    54 => [6, 8, 16, 30, 17, 17, 14] // '6'
    55 => [31, 1, 2, 4, 8, 8, 8] // '7'
    56 => [14, 17, 17, 14, 17, 17, 14] // '8'
    57 => [14, 17, 17, 15, 1, 2, 12] // '9'
    58 => [0, 12, 12, 0, 12, 12, 0] // ':'
    59 => [0, 12, 12, 0, 12, 4, 8] // ';'
    60 => [2, 4, 8, 16, 8, 4, 2] // '<'
    61 => [0, 0, 31, 0, 31, 0, 0] // '='
    62 => [8, 4, 2, 1, 2, 4, 8] // '>'
    63 => [14, 17, 1, 2, 4, 0, 4] // '?'
    64 => [14, 17, 23, 21, 23, 16, 14] // '@'
    65 => [14, 17, 17, 31, 17, 17, 17] // 'A'
    66 => [30, 17, 17, 30, 17, 17, 30] // 'B'
    67 => [14, 17, 16, 16, 16, 17, 14] // 'C'
    68 => [28, 18, 17, 17, 17, 18, 28] // 'D'
    69 => [31, 16, 16, 30, 16, 16, 31] // 'E'
    70 => [31, 16, 16, 30, 16, 16, 16] // 'F'
    71 => [14, 17, 16, 23, 17, 17, 15] // 'G'
    72 => [17, 17, 17, 31, 17, 17, 17] // 'H'
    73 => [14, 4, 4, 4, 4, 4, 14] // 'I'
    74 => [7, 2, 2, 2, 2, 18, 12] // 'J'
    75 => [17, 18, 20, 24, 20, 18, 17] // 'K'
    76 => [16, 16, 16, 16, 16, 16, 31] // 'L'
    77 => [17, 27, 21, 21, 17, 17, 17] // 'M'
    78 => [17, 25, 21, 19, 17, 17, 17] // 'N'
    79 => [14, 17, 17, 17, 17, 17, 14] // 'O'
    80 => [30, 17, 17, 30, 16, 16, 16] // 'P'
    81 => [14, 17, 17, 17, 21, 18, 13] // 'Q'
    82 => [30, 17, 17, 30, 20, 18, 17] // 'R'
    83 => [15, 16, 16, 14, 1, 1, 30] // 'S'
    84 => [31, 4, 4, 4, 4, 4, 4] // 'T'
    85 => [17, 17, 17, 17, 17, 17, 14] // 'U'
    86 => [17, 17, 17, 17, 17, 10, 4] // 'V'
    87 => [17, 17, 17, 21, 21, 27, 17] // 'W'
    88 => [17, 17, 10, 4, 10, 17, 17] // 'X'
    89 => [17, 17, 10, 4, 4, 4, 4] // 'Y'
    90 => [31, 1, 2, 4, 8, 16, 31] // 'Z'
    91 => [14, 8, 8, 8, 8, 8, 14] // '['
    92 => [0, 16, 8, 4, 2, 1, 0] // '\'
    93 => [14, 2, 2, 2, 2, 2, 14] // ']'
    94 => [4, 10, 17, 0, 0, 0, 0] // '^'
    95 => [0, 0, 0, 0, 0, 0, 31] // '_'
    96 => [8, 4, 2, 0, 0, 0, 0] // '`'
    97 => [0, 0, 14, 1, 15, 17, 15] // 'a'
    98 => [16, 16, 22, 25, 17, 17, 30] // 'b'
    99 => [0, 0, 14, 16, 16, 17, 14] // 'c'
    100 => [1, 1, 13, 19, 17, 17, 15] // 'd'
    101 => [0, 0, 14, 17, 31, 16, 14] // 'e'
    102 => [6, 9, 8, 28, 8, 8, 8] // 'f'
    103 => [0, 15, 17, 17, 15, 1, 14] // 'g'
    104 => [16, 16, 22, 25, 17, 17, 17] // 'h'
    105 => [4, 0, 12, 4, 4, 4, 14] // 'i'
    106 => [2, 0, 6, 2, 2, 18, 12] // 'j'
    107 => [16, 16, 18, 20, 24, 20, 18] // 'k'
    108 => [12, 4, 4, 4, 4, 4, 14] // 'l'
    109 => [0, 0, 26, 21, 21, 17, 17] // 'm'
    110 => [0, 0, 22, 25, 17, 17, 17] // 'n'
    111 => [0, 0, 14, 17, 17, 17, 14] // 'o'
    112 => [0, 0, 30, 17, 30, 16, 16] // 'p'
    113 => [0, 0, 13, 19, 15, 1, 1] // 'q'
    114 => [0, 0, 22, 25, 16, 16, 16] // 'r'
    115 => [0, 0, 14, 16, 14, 1, 30] // 's'
    116 => [8, 8, 28, 8, 8, 9, 6] // 't'
    117 => [0, 0, 17, 17, 17, 19, 13] // 'u'
    118 => [0, 0, 17, 17, 17, 10, 4] // 'v'
    119 => [0, 0, 17, 17, 21, 21, 10] // 'w'
    120 => [0, 0, 17, 10, 4, 10, 17] // 'x'
    121 => [0, 0, 17, 17, 15, 1, 14] // 'y'
    122 => [0, 0, 31, 2, 4, 8, 31] // 'z'
    123 => [6, 8, 8, 16, 8, 8, 6] // '{'
    124 => [4, 4, 4, 4, 4, 4, 4] // '|'
    125 => [12, 2, 2, 1, 2, 2, 12] // '}'
    126 => [0, 0, 8, 21, 2, 0, 0] // '~'
    _ => [31, 17, 21, 21, 21, 17, 31] // fallback tofu box
  }
}

///|
fn rasterize_builtin_glyph(cp : Int, size_px : Float) -> (Int, Int, Int, Int, Bytes) {
  if cp == 32 || cp == 9 || cp == 10 || cp == 13 {
    return (0, 0, 0, 0, b"")
  }
  let rows = builtin_glyph_rows(cp)
  let gw = @tmath.max_f((5.0 : Float), size_px * (0.58 : Float)).to_int()
  let gh = @tmath.max_f((7.0 : Float), size_px * (0.78 : Float)).to_int()
  let pixels = Array::make(gw * gh, (0 : Byte))
  for py = 0; py < gh; py = py + 1 {
    let sy = (py * 7) / gh
    let row_bits = rows[if sy < 0 { 0 } else if sy > 6 { 6 } else { sy }]
    for px = 0; px < gw; px = px + 1 {
      let sx = (px * 5) / gw
      let bit = (row_bits >> (4 - sx)) & 1
      if bit != 0 {
        pixels[py * gw + px] = (255 : Byte)
      }
    }
  }
  let ox = 1
  let oy = -gh
  (ox, oy, gw, gh, Bytes::from_array(pixels[:]))
}

///|
let g_next_font_id : Ref[Int] = Ref(1)

///|
fn alloc_font_id() -> Int {
  let id = g_next_font_id.val
  g_next_font_id.val = id + 1
  id
}

///|
pub struct FontFace {
  priv id : Int
  priv ttf : TtfData?
}

///|
pub fn FontFace::builtin() -> FontFace {
  { id: 0, ttf: None }
}

///|
pub fn FontFace::from_ttf_bytes(bytes : Bytes) -> FontFace? {
  match parse_ttf(bytes) {
    Some(ttf) => Some({ id: alloc_font_id(), ttf: Some(ttf) })
    None => None
  }
}

///|
pub fn FontFace::id(self : FontFace) -> Int {
  self.id
}

///|
pub fn FontFace::advance_width(self : FontFace, cp : Int, size_px : Float) -> Float {
  match self.ttf {
    Some(t) => {
      let gid = ttf_glyph_id(t, cp)
      let adv = ttf_advance_units(t, gid)
      Float::from_double(adv.to_double() * size_px.to_double() / t.units_per_em.to_double())
    }
    None => size_px * (0.62 : Float)
  }
}

///|
pub fn FontFace::metrics(self : FontFace, size_px : Float) -> (Float, Float, Float) {
  // Returns (ascent, descent, line_height)
  match self.ttf {
    Some(t) => {
      let s = size_px.to_double() / t.units_per_em.to_double()
      let asc = Float::from_double(t.ascent.to_double() * s)
      let desc = Float::from_double((-t.descent).to_double() * s)
      let gap = Float::from_double(t.line_gap.to_double() * s)
      (asc, desc, asc + desc + gap)
    }
    None => {
      let asc = size_px * (0.82 : Float)
      let desc = size_px * (0.20 : Float)
      (asc, desc, size_px * (1.25 : Float))
    }
  }
}

///|
pub(all) struct GlyphEntry {
  uv_x0 : Float
  uv_y0 : Float
  uv_x1 : Float
  uv_y1 : Float
  offset_x : Int
  offset_y : Int
  width : Int
  height : Int
  advance : Float
}

///|
pub struct GlyphCache {
  atlas : DynamicAtlas
  priv entries : Map[String, GlyphEntry]
  priv mut atlas_reset_count : Int
  priv mut atlas_overflow_count : Int
}

///|
pub fn GlyphCache::new(
  dev : @tycho.Device,
  width? : Int = 2048,
  height? : Int = 2048,
) -> GlyphCache raise @tycho.RhiError {
  {
    atlas: DynamicAtlas::new(dev, width, height, @tycho.TextureFormat::R8),
    entries: {},
    atlas_reset_count: 0,
    atlas_overflow_count: 0,
  }
}

///|
// Number of times the atlas had to be reset because it ran out of space.
pub fn GlyphCache::atlas_reset_count(self : GlyphCache) -> Int {
  self.atlas_reset_count
}

///|
// Number of glyphs that could not be rasterized even after a reset (e.g. a
// single glyph bitmap larger than the atlas page).
pub fn GlyphCache::atlas_overflow_count(self : GlyphCache) -> Int {
  self.atlas_overflow_count
}

///|
pub fn GlyphCache::entry_count(self : GlyphCache) -> Int {
  self.entries.length()
}

///|
pub fn GlyphCache::atlas_size(self : GlyphCache) -> (Int, Int) {
  (self.atlas.width, self.atlas.height)
}

///|
pub fn GlyphCache::get_or_rasterize(
  self : GlyphCache,
  font : FontFace,
  cp : Int,
  size_px : Float,
) -> GlyphEntry raise @tycho.RhiError {
  // Quantize the requested size to 1/4 px. This keeps animated/zoomed text from
  // re-rasterizing on every integer step while staying small enough to be
  // visually smooth.
  let clamped = @tmath.max_f((6.0 : Float), size_px)
  let q4 = (clamped * (4.0 : Float) + (0.5 : Float)).to_int()
  let px_size = Float::from_int(q4) * (0.25 : Float)
  let key = "\{font.id}:\{cp}:\{q4}"
  match self.entries.get(key) {
    Some(e) => return e
    None => ()
  }
  let adv = font.advance_width(cp, px_size)
  let (ox, oy, gw, gh, pixels) = match font.ttf {
    Some(t) => rasterize_ttf_glyph(t, cp, px_size)
    None => rasterize_builtin_glyph(cp, px_size)
  }
  let mut cacheable = true
  let (ux0, uy0, ux1, uy1) = if gw > 0 && gh > 0 {
    if gw > self.atlas.width || gh > self.atlas.height {
      self.atlas_overflow_count = self.atlas_overflow_count + 1
      cacheable = false
      ((0.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float))
    } else {
      match self.atlas.alloc_and_upload(gw, gh, pixels) {
        Some((ax, ay)) => self.atlas.uv_rect(ax, ay, gw, gh)
        None => {
          // Atlas full: reset once and retry. Only truly-full pages trigger
          // this; the old behaviour cleared entries for every overflow, so we
          // track it explicitly for tests and diagnostics.
          self.atlas_reset_count = self.atlas_reset_count + 1
          self.atlas.reset()
          self.entries.clear()
          match self.atlas.alloc_and_upload(gw, gh, pixels) {
            Some((ax2, ay2)) => self.atlas.uv_rect(ax2, ay2, gw, gh)
            None => {
              self.atlas_overflow_count = self.atlas_overflow_count + 1
              cacheable = false
              ((0.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float))
            }
          }
        }
      }
    }
  } else {
    ((0.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float))
  }
  let entry : GlyphEntry = {
    uv_x0: ux0,
    uv_y0: uy0,
    uv_x1: ux1,
    uv_y1: uy1,
    offset_x: ox,
    offset_y: oy,
    width: gw,
    height: gh,
    advance: adv,
  }
  if cacheable {
    self.entries[key] = entry
  }
  entry
}

///|
pub fn GlyphCache::destroy(self : GlyphCache) -> Unit {
  self.atlas.destroy()
}
