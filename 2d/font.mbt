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
fn be_i8(b : Bytes, off : Int) -> Int {
  let v = b[off].to_int()
  if v >= 128 { v - 256 } else { v }
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
  // Color bitmap tables (CBDT/CBLC), -1 when absent.
  cblc_off : Int
  cbdt_off : Int
  // Legacy `kern` table, -1 when absent.
  kern_off : Int
  // GSUB/GPOS tables, -1 when absent.
  gsub_off : Int
  gpos_off : Int
  gdef_off : Int
  // fvar/avar/gvar/HVAR tables, -1 when absent.
  fvar_off : Int
  avar_off : Int
  gvar_off : Int
  hvar_off : Int
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
  let mut cblc_off = -1
  let mut cbdt_off = -1
  let mut kern_off = -1
  let mut gsub_off = -1
  let mut gpos_off = -1
  let mut gdef_off = -1
  let mut fvar_off = -1
  let mut avar_off = -1
  let mut gvar_off = -1
  let mut hvar_off = -1
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
    else if tag_eq(bytes, rec, "CBLC") { cblc_off = off }
    else if tag_eq(bytes, rec, "CBDT") { cbdt_off = off }
    else if tag_eq(bytes, rec, "kern") { kern_off = off }
    else if tag_eq(bytes, rec, "GSUB") { gsub_off = off }
    else if tag_eq(bytes, rec, "GPOS") { gpos_off = off }
    else if tag_eq(bytes, rec, "GDEF") { gdef_off = off }
    else if tag_eq(bytes, rec, "fvar") { fvar_off = off }
    else if tag_eq(bytes, rec, "avar") { avar_off = off }
    else if tag_eq(bytes, rec, "gvar") { gvar_off = off }
    else if tag_eq(bytes, rec, "HVAR") { hvar_off = off }
  }
  if head_off < 0 || hhea_off < 0 || maxp_off < 0 || hmtx_off < 0 ||
    cmap_off < 0 {
    return None
  }
  // Bitmap-only color fonts (CBDT/CBLC) have no glyf/loca.
  if (glyf_off < 0 || loca_off < 0) && (cblc_off < 0 || cbdt_off < 0) {
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
    cblc_off,
    cbdt_off,
    kern_off,
    gsub_off,
    gpos_off,
    gdef_off,
    fvar_off,
    avar_off,
    gvar_off,
    hvar_off,
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
// Synthetic bold (3x3 A8 dilation) and italic (vertical shear with the top
// rows shifted right). Returns adjusted top-left offset and bitmap size.
fn synthesize_glyph_bitmap(
  ox : Int,
  oy : Int,
  gw : Int,
  gh : Int,
  pixels : Bytes,
  bold : Bool,
  italic : Bool,
) -> (Int, Int, Int, Int, Bytes) {
  if gw <= 0 || gh <= 0 {
    return (ox, oy, gw, gh, pixels)
  }
  let mut px = pixels
  let mut w = gw
  let mut h = gh
  let mut x = ox
  let mut y = oy
  if bold {
    let nw = w + 2
    let nh = h + 2
    let out = Array::make(nw * nh, (0 : Byte))
    for row = 0; row < h; row = row + 1 {
      for col = 0; col < w; col = col + 1 {
        let v = px[row * w + col].to_int()
        if v > 0 {
          for dy = -1; dy <= 1; dy = dy + 1 {
            for dx = -1; dx <= 1; dx = dx + 1 {
              let nx = col + 1 + dx
              let ny = row + 1 + dy
              if nx >= 0 && nx < nw && ny >= 0 && ny < nh {
                let idx = ny * nw + nx
                if v > out[idx].to_int() {
                  out[idx] = v.to_byte()
                }
              }
            }
          }
        }
      }
    }
    px = Bytes::from_array(out)
    w = nw
    h = nh
    x = x - 1
    y = y - 1
  }
  if italic {
    let shift_max = (Float::from_int(h - 1) * (0.22 : Float)).ceil().to_int()
    if shift_max > 0 {
      let nw = w + shift_max
      let out = Array::make(nw * h, (0 : Byte))
      for row = 0; row < h; row = row + 1 {
        let shift = (Float::from_int(h - 1 - row) * (0.22 : Float)).ceil().to_int()
        for col = 0; col < w; col = col + 1 {
          out[row * nw + col + shift] = px[row * w + col]
        }
      }
      px = Bytes::from_array(out)
      w = nw
    }
  }
  (x, y, w, h, px)
}

///|
const SDF_SPREAD : Int = 6

///|
fn sdf_distance_pass(d : Array[Float], w : Int, h : Int, forward : Bool) -> Unit {
  let diag = (1.41421356 : Float)
  if forward {
    for y = 0; y < h; y = y + 1 {
      for x = 0; x < w; x = x + 1 {
        let i = y * w + x
        let mut v = d[i]
        if v > (0.0 : Float) {
          if x > 0 {
            v = @tmath.min_f(v, d[i - 1] + (1.0 : Float))
          }
          if y > 0 {
            v = @tmath.min_f(v, d[i - w] + (1.0 : Float))
            if x > 0 {
              v = @tmath.min_f(v, d[i - w - 1] + diag)
            }
            if x + 1 < w {
              v = @tmath.min_f(v, d[i - w + 1] + diag)
            }
          }
          d[i] = v
        }
      }
    }
  } else {
    for y = h - 1; y >= 0; y = y - 1 {
      for x = w - 1; x >= 0; x = x - 1 {
        let i = y * w + x
        let mut v = d[i]
        if v > (0.0 : Float) {
          if x + 1 < w {
            v = @tmath.min_f(v, d[i + 1] + (1.0 : Float))
          }
          if y + 1 < h {
            v = @tmath.min_f(v, d[i + w] + (1.0 : Float))
            if x > 0 {
              v = @tmath.min_f(v, d[i + w - 1] + diag)
            }
            if x + 1 < w {
              v = @tmath.min_f(v, d[i + w + 1] + diag)
            }
          }
          d[i] = v
        }
      }
    }
  }
}

///|
// Encode a signed distance field (inside = 1.0) from an A8 glyph mask.
fn build_sdf(gw : Int, gh : Int, pixels : Bytes) -> (Int, Int, Bytes) {
  if gw <= 0 || gh <= 0 {
    return (0, 0, b"")
  }
  let w = gw + SDF_SPREAD * 2
  let h = gh + SDF_SPREAD * 2
  let n = w * h
  let inside = Array::make(n, false)
  for y = 0; y < gh; y = y + 1 {
    for x = 0; x < gw; x = x + 1 {
      if pixels[y * gw + x].to_int() >= 128 {
        inside[(y + SDF_SPREAD) * w + (x + SDF_SPREAD)] = true
      }
    }
  }
  let d_in = Array::make(n, (1.0e9 : Float))
  let d_out = Array::make(n, (1.0e9 : Float))
  for i = 0; i < n; i = i + 1 {
    if inside[i] {
      d_in[i] = (0.0 : Float)
    } else {
      d_out[i] = (0.0 : Float)
    }
  }
  sdf_distance_pass(d_in, w, h, true)
  sdf_distance_pass(d_in, w, h, false)
  sdf_distance_pass(d_out, w, h, true)
  sdf_distance_pass(d_out, w, h, false)
  let out = Array::make(n, (0 : Byte))
  let inv = (1.0 : Float) / (Float::from_int(SDF_SPREAD) * (2.0 : Float))
  for i = 0; i < n; i = i + 1 {
    let signed = d_out[i] - d_in[i]
    let v = @tmath.max_f(
      (0.0 : Float),
      @tmath.min_f((1.0 : Float), (0.5 : Float) + signed * inv),
    )
    out[i] = (v * (255.0 : Float)).to_int().to_byte()
  }
  (w, h, Bytes::from_array(out))
}

///|
// RGBA distance texture for the MSDF path. The CPU fallback uses the same
// Euclidean signed distance in all three channels; the shader takes the median,
// so future per-corner channel generation can be swapped in without touching
// the atlas or pipeline.
fn build_msdf(gw : Int, gh : Int, pixels : Bytes) -> (Int, Int, Bytes) {
  let (w, h, sdf) = build_sdf(gw, gh, pixels)
  if w <= 0 || h <= 0 {
    return (0, 0, b"")
  }
  let out = Array::make(w * h * 4, (0 : Byte))
  for i = 0; i < w * h; i = i + 1 {
    let d = sdf[i]
    out[i * 4] = d
    out[i * 4 + 1] = d
    out[i * 4 + 2] = d
    out[i * 4 + 3] = (255 : Byte)
  }
  (w, h, Bytes::from_array(out))
}

///|
fn rasterize_ttf_glyph(
  t : TtfData,
  cp : Int,
  size_px : Float,
) -> (Int, Int, Int, Int, Bytes) {
  if t.glyf_off < 0 || t.loca_off < 0 {
    return (0, 0, 0, 0, b"")
  }
  rasterize_ttf_glyph_gid(t, ttf_glyph_id(t, cp), size_px)
}

///|
fn rasterize_ttf_glyph_gid(
  t : TtfData,
  gid : Int,
  size_px : Float,
) -> (Int, Int, Int, Int, Bytes) {
  if t.glyf_off < 0 || t.loca_off < 0 || gid <= 0 {
    return (0, 0, 0, 0, b"")
  }
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
  priv gsub : GsubData?
  priv gpos : GposData?
  priv gdef : GdefData?
  priv hvar : HvarData?
  priv var_values : Map[String, Float]
}

///|
pub fn FontFace::builtin() -> FontFace {
  {
    id: 0,
    ttf: None,
    gsub: None,
    gpos: None,
    gdef: None,
    hvar: None,
    var_values: Map([]),
  }
}

///|
pub fn FontFace::from_ttf_bytes(bytes : Bytes) -> FontFace? {
  match parse_ttf(bytes) {
    Some(ttf) => {
      let gdef = if ttf.gdef_off >= 0 {
        GdefData::parse(bytes, ttf.gdef_off)
      } else {
        None
      }
      let gsub = if ttf.gsub_off >= 0 {
        GsubData::parse(bytes, ttf.gsub_off, gdef)
      } else {
        None
      }
      let gpos = if ttf.gpos_off >= 0 {
        GposData::parse(bytes, ttf.gpos_off)
      } else {
        None
      }
      let hvar = if ttf.hvar_off >= 0 {
        HvarData::parse(bytes, ttf.hvar_off)
      } else {
        None
      }
      Some({
        id: alloc_font_id(),
        ttf: Some(ttf),
        gsub,
        gpos,
        gdef,
        hvar,
        var_values: Map([]),
      })
    }
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
      let mut adv = Float::from_int(ttf_advance_units(t, gid))
      match self.hvar {
        Some(h) => adv = adv + h.advance_delta(gid, self.normalized_coords())
        None => ()
      }
      Float::from_double(adv.to_double() * size_px.to_double() / t.units_per_em.to_double())
    }
    None => size_px * (0.62 : Float)
  }
}

///|
// True when the face can render `cp` (builtin covers printable ASCII, TTF
// consults cmap).
pub(all) struct FontVariationAxis {
  tag : String
  min_value : Float
  default_value : Float
  max_value : Float
}

///|
fn fixed_16_16(v : Int) -> Float {
  Float::from_double(v.to_double() / 65536.0)
}

///|
fn parse_fvar(bytes : Bytes, base : Int) -> Array[FontVariationAxis] {
  let out : Array[FontVariationAxis] = []
  if base + 16 > bytes.length() {
    return out
  }
  let axes_off = base + be_u16(bytes, base + 4)
  let axis_count = be_u16(bytes, base + 8)
  let axis_size = be_u16(bytes, base + 10)
  if axis_size < 20 {
    return out
  }
  for i = 0; i < axis_count; i = i + 1 {
    let r = axes_off + i * axis_size
    if r + 20 > bytes.length() {
      break
    }
    let chars : Array[Char] = []
    for k = 0; k < 4; k = k + 1 {
      chars.push(bytes[r + k].to_int().unsafe_to_char())
    }
    out.push({
      tag: String::from_array(chars),
      min_value: fixed_16_16(be_i32(bytes, r + 4)),
      default_value: fixed_16_16(be_i32(bytes, r + 8)),
      max_value: fixed_16_16(be_i32(bytes, r + 12)),
    })
  }
  out
}

///|
pub fn FontFace::variation_axes(self : FontFace) -> Array[FontVariationAxis] {
  match self.ttf {
    Some(t) => if t.fvar_off >= 0 {
      parse_fvar(t.bytes, t.fvar_off)
    } else {
      []
    }
    None => []
  }
}

///|
// AVAR segment map: piecewise-linear remap of a normalized axis coordinate.
fn avar_map(bytes : Bytes, base : Int, axis_index : Int, n : Float) -> Float {
  if base + 8 > bytes.length() {
    return n
  }
  let axis_count = be_u16(bytes, base + 6)
  if axis_index < 0 || axis_index >= axis_count {
    return n
  }
  let mut pos = base + 8
  for a = 0; a < axis_count; a = a + 1 {
    if pos + 2 > bytes.length() {
      return n
    }
    let count = be_u16(bytes, pos)
    pos = pos + 2
    if a == axis_index {
      if count <= 0 {
        return n
      }
      let mut prev_from : Float = -1.0
      let mut prev_to : Float = -1.0
      for i = 0; i < count; i = i + 1 {
        if pos + 4 > bytes.length() {
          return n
        }
        let f = Float::from_double(be_i16(bytes, pos).to_double() / 16384.0)
        let t = Float::from_double(be_i16(bytes, pos + 2).to_double() / 16384.0)
        pos = pos + 4
        if n == f {
          return t
        }
        if n < f {
          if i == 0 {
            return t
          }
          let span = f - prev_from
          if span <= 0.0 {
            return t
          }
          return prev_to + (t - prev_to) * (n - prev_from) / span
        }
        prev_from = f
        prev_to = t
      }
      return prev_to
    }
    pos = pos + count * 4
  }
  n
}

///|
// HVAR advance-width variation: ItemVariationStore + DeltaSetIndexMap.
priv struct HvarData {
  bytes : Bytes
  ivs : Int
  advance_map : Int
}

///|
fn HvarData::parse(bytes : Bytes, base : Int) -> HvarData? {
  if base + 12 > bytes.length() {
    return None
  }
  let ivs = base + be_u32(bytes, base + 4).reinterpret_as_int()
  let adv = base + be_u32(bytes, base + 8).reinterpret_as_int()
  if ivs <= 0 || adv <= 0 {
    return None
  }
  Some({ bytes, ivs, advance_map: adv })
}

///|
fn hvar_read_entry(b : Bytes, off : Int, size : Int) -> Int {
  let mut v = 0
  for i = 0; i < size; i = i + 1 {
    v = v * 256 + b[off + i].to_int()
  }
  v
}

///|
fn HvarData::delta_set_index(self : HvarData, gid : Int) -> (Int, Int)? {
  let b = self.bytes
  let m = self.advance_map
  if m + 4 > b.length() {
    return None
  }
  let fmt = b[m].to_int()
  let entry_fmt = b[m + 1].to_int()
  let (count, data) = if fmt == 0 {
    (be_u16(b, m + 2), m + 4)
  } else {
    (be_u32(b, m + 2).reinterpret_as_int(), m + 6)
  }
  if gid < 0 || gid >= count {
    return None
  }
  let size = ((entry_fmt >> 4) & 3) + 1
  let bits = (entry_fmt & 0x0F) + 1
  let off = data + gid * size
  if off + size > b.length() {
    return None
  }
  let v = hvar_read_entry(b, off, size)
  Some((v >> bits, v & ((1 << bits) - 1)))
}

///|
fn hvar_region_scalar(
  b : Bytes,
  region_list : Int,
  region_index : Int,
  coords : Array[Float],
) -> Float {
  if region_list + 4 > b.length() {
    return 0.0
  }
  let axis_count = be_u16(b, region_list)
  let region_count = be_u16(b, region_list + 2)
  if region_index < 0 || region_index >= region_count {
    return 0.0
  }
  let base = region_list + 4 + region_index * axis_count * 6
  let mut scalar : Float = 1.0
  for a = 0; a < axis_count; a = a + 1 {
    let r = base + a * 6
    if r + 6 > b.length() {
      return 0.0
    }
    let start = Float::from_double(be_i16(b, r).to_double() / 16384.0)
    let peak = Float::from_double(be_i16(b, r + 2).to_double() / 16384.0)
    let end = Float::from_double(be_i16(b, r + 4).to_double() / 16384.0)
    let v = if a < coords.length() { coords[a] } else { (0.0 : Float) }
    if peak == 0.0 {
      continue
    }
    if v == peak {
      continue
    }
    if v <= start || v >= end {
      return 0.0
    }
    if v < peak {
      scalar = scalar * (v - start) / (peak - start)
    } else {
      scalar = scalar * (end - v) / (end - peak)
    }
  }
  scalar
}

///|
fn HvarData::advance_delta(self : HvarData, gid : Int, coords : Array[Float]) -> Float {
  let b = self.bytes
  let (outer, inner) = match self.delta_set_index(gid) {
    Some(v) => v
    None => return (0.0 : Float)
  }
  let ivs = self.ivs
  if ivs + 8 > b.length() {
    return (0.0 : Float)
  }
  let data_count = be_u16(b, ivs + 6)
  if outer < 0 || outer >= data_count {
    return (0.0 : Float)
  }
  let region_list = ivs + be_u32(b, ivs + 2).reinterpret_as_int()
  let data_off = ivs + be_u32(b, ivs + 8 + outer * 4).reinterpret_as_int()
  if data_off + 6 > b.length() {
    return (0.0 : Float)
  }
  let item_count = be_u16(b, data_off)
  if inner < 0 || inner >= item_count {
    return (0.0 : Float)
  }
  let short_count = be_u16(b, data_off + 2)
  let region_count = be_u16(b, data_off + 4)
  let row_size = short_count * 2 + (region_count - short_count)
  let row = data_off + 6 + region_count * 2 + inner * row_size
  if row + row_size > b.length() {
    return (0.0 : Float)
  }
  let mut sum : Float = 0.0
  for r = 0; r < region_count; r = r + 1 {
    let ridx = be_u16(b, data_off + 6 + r * 2)
    let scalar = hvar_region_scalar(b, region_list, ridx, coords)
    if scalar == 0.0 {
      continue
    }
    let delta = if r < short_count {
      Float::from_int(be_i16(b, row + r * 2))
    } else {
      Float::from_int(be_i8(b, row + short_count * 2 + (r - short_count)))
    }
    sum = sum + scalar * delta
  }
  sum
}

///|
// Set one axis value (design units, e.g. wght=700).
pub fn FontFace::set_variation(self : FontFace, tag : String, value : Float) -> Unit {
  self.var_values[tag] = value
}

///|
pub fn FontFace::clear_variations(self : FontFace) -> Unit {
  self.var_values.clear()
}

///|
pub fn FontFace::variation_value(self : FontFace, tag : String) -> Float {
  match self.var_values.get(tag) {
    Some(v) => v
    None => (0.0 : Float)
  }
}

///|
// Normalized-axis coordinates in fvar order, after avar remapping.
pub fn FontFace::normalized_coords(self : FontFace) -> Array[Float] {
  let out : Array[Float] = []
  let axes = self.variation_axes()
  let avar = match self.ttf {
    Some(t) => if t.avar_off >= 0 { t.avar_off } else { -1 }
    None => -1
  }
  for i = 0; i < axes.length(); i = i + 1 {
    let a = axes[i]
    let v = match self.var_values.get(a.tag) {
      Some(x) => x
      None => a.default_value
    }
    let mut n : Float = if v <= a.min_value {
      -1.0
    } else if v >= a.max_value {
      1.0
    } else if v == a.default_value {
      0.0
    } else if v < a.default_value {
      (v - a.default_value) / (a.default_value - a.min_value)
    } else {
      (v - a.default_value) / (a.max_value - a.default_value)
    }
    if avar >= 0 {
      let t = self.ttf
      match t {
        Some(t) => n = avar_map(t.bytes, avar, i, n)
        None => ()
      }
    }
    out.push(n)
  }
  out
}

///|
pub fn FontFace::normalized_coord(self : FontFace, tag : String) -> Float {
  let axes = self.variation_axes()
  let coords = self.normalized_coords()
  for i = 0; i < axes.length(); i = i + 1 {
    if axes[i].tag == tag {
      return coords[i]
    }
  }
  (0.0 : Float)
}

///|
pub fn FontFace::has_gvar(self : FontFace) -> Bool {
  match self.ttf {
    Some(t) => t.gvar_off >= 0
    None => false
  }
}

///|
pub fn FontFace::rasterize_bitmap(
  self : FontFace,
  gid : Int,
  cp : Int,
  size_px : Float,
  bold : Bool,
  italic : Bool,
) -> (Int, Int, Int, Int, Bytes) {
  let (ox, oy, gw, gh, pixels) = match self.ttf {
    Some(t) => if gid > 0 {
      rasterize_ttf_glyph_gid(t, gid, size_px)
    } else {
      rasterize_ttf_glyph(t, cp, size_px)
    }
    None => rasterize_builtin_glyph(cp, size_px)
  }
  synthesize_glyph_bitmap(ox, oy, gw, gh, pixels, bold, italic)
}

///|
pub fn FontFace::has_glyph(self : FontFace, cp : Int) -> Bool {
  match self.ttf {
    Some(t) => ttf_glyph_id(t, cp) != 0
    None => cp >= 32 && cp <= 126
  }
}

///|
pub fn FontFace::has_color_bitmap(self : FontFace, cp : Int) -> Bool {
  match self.color_bitmap(cp, (16.0 : Float)) {
    Some(_) => true
    None => false
  }
}

///|
fn is_emoji_cp(cp : Int) -> Bool {
  (cp >= 0x1F000 && cp <= 0x1FAFF) ||
  (cp >= 0x2600 && cp <= 0x27BF) ||
  (cp >= 0xFE00 && cp <= 0xFE0F)
}

///|
// Ordered font fallback: color emoji prefer a face with a CBDT bitmap; other
// codepoints take the first face that has a glyph.
pub(all) struct FontFallbackChain {
  priv faces : Array[FontFace]
}

///|
pub fn FontFallbackChain::new(
  primary : FontFace,
  fallbacks? : Array[FontFace] = [],
) -> FontFallbackChain {
  let faces : Array[FontFace] = [primary]
  for f in fallbacks {
    faces.push(f)
  }
  { faces: faces }
}

///|
pub fn FontFallbackChain::face_for(self : FontFallbackChain, cp : Int) -> FontFace {
  if is_emoji_cp(cp) {
    for f in self.faces {
      if f.has_color_bitmap(cp) {
        return f
      }
    }
  }
  for f in self.faces {
    if f.has_glyph(cp) {
      return f
    }
  }
  self.faces[0]
}

///|
pub fn FontFallbackChain::faces(self : FontFallbackChain) -> Array[FontFace] {
  let out : Array[FontFace] = []
  for f in self.faces {
    out.push(f)
  }
  out
}

///|
// A color bitmap glyph from CBDT/CBLC, in the strike's native pixels. Callers
// scale by `size_px / ppem`.
pub(all) struct ColorBitmap {
  width : Int
  height : Int
  bearing_x : Int
  bearing_y : Int
  advance : Int
  ppem : Int
  png : Bytes
}

///|
pub(all) struct DecodedImage {
  width : Int
  height : Int
  rgba : Bytes
}

///|
pub fn DecodedImage::new(width : Int, height : Int, rgba : Bytes) -> DecodedImage {
  { width, height, rgba }
}

///|
// Host-provided PNG decoder (CBDT glyphs store PNG). Kept as a hook so the
// pure-MoonBit 2D package does not depend on a native image library.
let g_png_decoder : Ref[((Bytes) -> DecodedImage?)?] = Ref(None)

///|
pub fn FontFace::set_png_decoder(decoder : (Bytes) -> DecodedImage?) -> Unit {
  g_png_decoder.val = Some(decoder)
}

///|
// Parse the CBDT bitmap record for `cp` at the strike closest to `size_px`.
pub fn FontFace::color_bitmap(self : FontFace, cp : Int, size_px : Float) -> ColorBitmap? {
  let t = match self.ttf {
    Some(t) => t
    None => return None
  }
  if t.cblc_off < 0 || t.cbdt_off < 0 {
    return None
  }
  let gid = ttf_glyph_id(t, cp)
  if gid <= 0 {
    return None
  }
  let b = t.bytes
  let cblc = t.cblc_off
  if cblc + 8 > b.length() {
    return None
  }
  let num_sizes = be_u32(b, cblc + 4).reinterpret_as_int()
  let mut rec = -1
  let mut best_diff = (1.0e9 : Float)
  for si = 0; si < num_sizes; si = si + 1 {
    let r = cblc + 8 + si * 48
    if r + 48 > b.length() {
      continue
    }
    let sg = be_u16(b, r + 40)
    let eg = be_u16(b, r + 42)
    if gid >= sg && gid <= eg {
      let ppem = b[r + 44].to_int()
      let diff = @tmath.abs_f(Float::from_int(ppem) - size_px)
      if diff < best_diff {
        best_diff = diff
        rec = r
      }
    }
  }
  if rec < 0 {
    return None
  }
  let arr = cblc + be_u32(b, rec).reinterpret_as_int()
  let n_idx = be_u32(b, rec + 8).reinterpret_as_int()
  let ppem_x = b[rec + 44].to_int()
  for k = 0; k < n_idx; k = k + 1 {
    let r = arr + k * 8
    if r + 8 > b.length() {
      continue
    }
    let fg = be_u16(b, r)
    let lg = be_u16(b, r + 2)
    if gid < fg || gid > lg {
      continue
    }
    let sub = arr + be_u32(b, r + 4).reinterpret_as_int()
    if sub + 8 > b.length() {
      return None
    }
    let fmt = be_u16(b, sub)
    let img_fmt = be_u16(b, sub + 2)
    let data_off = be_u32(b, sub + 4).reinterpret_as_int()
    // Index format 1: u32 offsets. Other formats are rare in color fonts.
    if fmt != 1 {
      return None
    }
    let o0 = sub + 8 + (gid - fg) * 4
    if o0 + 8 > b.length() {
      return None
    }
    let i0 = be_u32(b, o0).reinterpret_as_int()
    let i1 = be_u32(b, o0 + 4).reinterpret_as_int()
    if i1 <= i0 {
      return None
    }
    let mut off = t.cbdt_off + data_off + i0
    if off + 5 > b.length() {
      return None
    }
    let mut w = 0
    let mut h = 0
    let mut bx = 0
    let mut by = 0
    let mut adv = 0
    if img_fmt == 17 {
      h = b[off].to_int()
      w = b[off + 1].to_int()
      bx = be_i8(b, off + 2)
      by = be_i8(b, off + 3)
      adv = b[off + 4].to_int()
      off = off + 5
    } else if img_fmt == 18 || img_fmt == 19 {
      h = b[off].to_int()
      w = b[off + 1].to_int()
      bx = be_i8(b, off + 2)
      by = be_i8(b, off + 3)
      adv = b[off + 4].to_int()
      off = off + 8
    } else {
      return None
    }
    if off + 4 > b.length() {
      return None
    }
    let data_len = be_u32(b, off).reinterpret_as_int()
    off = off + 4
    if data_len <= 0 || off + data_len > b.length() {
      return None
    }
    return Some({
      width: w,
      height: h,
      bearing_x: bx,
      bearing_y: by,
      advance: adv,
      ppem: ppem_x,
      png: b[off:off + data_len].to_owned(),
    })
  }
  None
}

///|
pub fn FontFace::color_glyph(
  self : FontFace,
  cp : Int,
  size_px : Float,
) -> (ColorBitmap, DecodedImage)? {
  let cb = match self.color_bitmap(cp, size_px) {
    Some(v) => v
    None => return None
  }
  let dec = match g_png_decoder.val {
    Some(f) =>
      match f(cb.png) {
        Some(v) => v
        None => return None
      }
    None => return None
  }
  Some((cb, dec))
}

///|
// Legacy `kern` format-0 pair adjustment, in pixels at `size_px`.
pub fn FontFace::kern(self : FontFace, cp1 : Int, cp2 : Int, size_px : Float) -> Float {
  self.kern_gid(self.glyph_id(cp1), self.glyph_id(cp2), size_px)
}

///|
pub fn FontFace::kern_gid(
  self : FontFace,
  g1 : Int,
  g2 : Int,
  size_px : Float,
) -> Float {
  let t = match self.ttf {
    Some(t) => t
    None => return (0.0 : Float)
  }
  if t.kern_off < 0 {
    return (0.0 : Float)
  }
  if g1 == 0 || g2 == 0 {
    return (0.0 : Float)
  }
  let b = t.bytes
  let n_tables = be_u16(b, t.kern_off + 2)
  let mut off = t.kern_off + 4
  for ti = 0; ti < n_tables; ti = ti + 1 {
    let _ = ti
    if off + 6 > b.length() {
      return (0.0 : Float)
    }
    let length = be_u16(b, off + 2)
    let coverage = be_u16(b, off + 4)
    let fmt = coverage >> 8
    // Horizontal, non-cross-stream only.
    if fmt == 0 && (coverage & 1) != 0 && (coverage & 4) == 0 {
      if off + 14 > b.length() {
        return (0.0 : Float)
      }
      let n_pairs = be_u16(b, off + 6)
      for p = 0; p < n_pairs; p = p + 1 {
        let pr = off + 14 + p * 6
        if pr + 6 > b.length() {
          break
        }
        if be_u16(b, pr) == g1 && be_u16(b, pr + 2) == g2 {
          let v = Float::from_int(be_i16(b, pr + 4))
          return v * size_px / Float::from_int(t.units_per_em)
        }
      }
    }
    if length < 6 {
      return (0.0 : Float)
    }
    off = off + length
  }
  (0.0 : Float)
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
  is_sdf : Bool
  // Base pixel size the SDF was generated at (0 for bitmap entries).
  sdf_base : Float
  // MSDF entries live in the dedicated RGBA atlas and use kind=9.
  is_msdf : Bool
}

///|
fn round_int(x : Float) -> Int {
  if x >= (0.0 : Float) {
    (x + (0.5 : Float)).floor().to_int()
  } else {
    (x - (0.5 : Float)).ceil().to_int()
  }
}

///|
fn scale_glyph_entry(e : GlyphEntry, scale : Float, adv : Float) -> GlyphEntry {
  {
    ..e,
    offset_x: round_int(Float::from_int(e.offset_x) * scale),
    offset_y: round_int(Float::from_int(e.offset_y) * scale),
    width: round_int(Float::from_int(e.width) * scale),
    height: round_int(Float::from_int(e.height) * scale),
    advance: adv,
  }
}

///|
// CPU copy of a rasterized glyph, retained so a full atlas can be compacted
// (reset + re-upload of hot glyphs) without re-rasterizing or clearing the
// whole cache.
priv struct GlyphBitmap {
  pixels : Bytes
  gw : Int
  gh : Int
  mut last_frame : Int
}

///|
pub struct GlyphCache {
  atlas : DynamicAtlas
  msdf_atlas : DynamicAtlas
  priv entries : Map[String, GlyphEntry]
  priv bitmaps : Map[String, GlyphBitmap]
  priv mut atlas_reset_count : Int
  priv mut atlas_overflow_count : Int
  priv mut sdf_entries : Int
  priv mut msdf_entries : Int
  priv mut frame : Int
  // Bumped whenever the atlas is reset; external caches (coverage bitmaps)
  // must invalidate their UVs when this changes.
  priv mut generation : Int
}

///|
pub fn GlyphCache::new(
  dev : @tycho.Device,
  width? : Int = 4096,
  height? : Int = 4096,
) -> GlyphCache raise @tycho.RhiError {
  {
    atlas: DynamicAtlas::new(dev, width, height, @tycho.TextureFormat::R8),
    msdf_atlas: DynamicAtlas::new(dev, 2048, 2048, @tycho.TextureFormat::RGBA8),
    entries: {},
    bitmaps: {},
    atlas_reset_count: 0,
    atlas_overflow_count: 0,
    sdf_entries: 0,
    msdf_entries: 0,
    frame: 0,
    generation: 0,
  }
}

///|
pub fn GlyphCache::generation(self : GlyphCache) -> Int {
  self.generation
}

///|
pub fn GlyphCache::begin_frame(self : GlyphCache, frame : Int) -> Unit {
  self.frame = frame
}

///|
// Reclaim a full atlas without dropping every glyph: keep glyphs used in the
// current or previous frame, reset the packer, and re-upload those survivors
// from their retained CPU bitmaps.
fn GlyphCache::compact(self : GlyphCache) -> Unit raise @tycho.RhiError {
  self.atlas_reset_count = self.atlas_reset_count + 1
  self.generation = self.generation + 1
  self.atlas.reset()
  let survivors : Array[(String, GlyphEntry, GlyphBitmap)] = []
  for k, e in self.entries {
    if e.is_msdf {
      // MSDF entries use a separate RGBA atlas and are re-rasterized on demand.
      continue
    }
    match self.bitmaps.get(k) {
      Some(b) => {
        if b.last_frame + 1 >= self.frame {
          survivors.push((k, e, b))
        }
      }
      None => ()
    }
  }
  self.msdf_atlas.reset()
  self.msdf_entries = 0
  self.entries.clear()
  self.bitmaps.clear()
  for pair in survivors {
    let (k, e, b) = pair
    match self.atlas.alloc_and_upload_padded(b.gw, b.gh, b.pixels, padding=1) {
      Some((ax, ay, pw, ph)) => {
        let (a, c, d, e2) = self.atlas.uv_rect(ax, ay, pw, ph)
        self.entries[k] = { ..e, uv_x0: a, uv_y0: c, uv_x1: d, uv_y1: e2 }
        self.bitmaps[k] = b
      }
      None => ()
    }
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
pub fn GlyphCache::sdf_count(self : GlyphCache) -> Int {
  self.sdf_entries
}

///|
pub fn GlyphCache::msdf_count(self : GlyphCache) -> Int {
  self.msdf_entries
}

///|
pub fn GlyphCache::get_or_rasterize(
  self : GlyphCache,
  font : FontFace,
  cp : Int,
  size_px : Float,
) -> GlyphEntry raise @tycho.RhiError {
  self.get_or_rasterize_impl(font, cp, -1, size_px, false, false)
}

///|
pub fn GlyphCache::get_or_rasterize_gid(
  self : GlyphCache,
  font : FontFace,
  gid : Int,
  cp : Int,
  size_px : Float,
) -> GlyphEntry raise @tycho.RhiError {
  self.get_or_rasterize_impl(font, cp, gid, size_px, false, false)
}

///|
pub fn GlyphCache::get_or_rasterize_styled(
  self : GlyphCache,
  font : FontFace,
  gid : Int,
  cp : Int,
  size_px : Float,
  bold : Bool,
  italic : Bool,
) -> GlyphEntry raise @tycho.RhiError {
  self.get_or_rasterize_impl(font, cp, gid, size_px, bold, italic)
}

///|
fn GlyphCache::glyph_atlas_limit(self : GlyphCache, msdf : Bool) -> (Int, Int) {
  if msdf {
    (self.msdf_atlas.width, self.msdf_atlas.height)
  } else {
    (self.atlas.width, self.atlas.height)
  }
}

///|
// Drop MSDF entries after resetting the dedicated atlas so their UVs do not
// point into freed space.
fn GlyphCache::clear_msdf_entries(self : GlyphCache) -> Unit {
  let dead : Array[String] = []
  for k, e in self.entries {
    if e.is_msdf {
      dead.push(k)
    }
  }
  for k in dead {
    let _ = self.entries.remove(k)
    let _ = self.bitmaps.remove(k)
  }
  self.msdf_entries = 0
}

///|
fn GlyphCache::alloc_glyph(
  self : GlyphCache,
  msdf : Bool,
  gw : Int,
  gh : Int,
  pixels : Bytes,
  pad : Int,
) -> (Int, Int, Int, Int)? raise @tycho.RhiError {
  if msdf {
    let first = self.msdf_atlas.alloc_and_upload_padded(
      gw,
      gh,
      pixels,
      padding=pad,
    )
    match first {
      Some(v) => Some(v)
      None => {
        self.msdf_atlas.reset()
        self.clear_msdf_entries()
        self.msdf_atlas.alloc_and_upload_padded(gw, gh, pixels, padding=pad)
      }
    }
  } else {
    let first = self.atlas.alloc_and_upload_padded(gw, gh, pixels, padding=pad)
    match first {
      Some(v) => Some(v)
      None => {
        self.compact()
        self.atlas.alloc_and_upload_padded(gw, gh, pixels, padding=pad)
      }
    }
  }
}

///|
fn GlyphCache::glyph_uv(
  self : GlyphCache,
  msdf : Bool,
  ax : Int,
  ay : Int,
  pw : Int,
  ph : Int,
) -> (Float, Float, Float, Float) {
  if msdf {
    self.msdf_atlas.uv_rect(ax, ay, pw, ph)
  } else {
    self.atlas.uv_rect(ax, ay, pw, ph)
  }
}

///|
fn GlyphCache::get_or_rasterize_impl(
  self : GlyphCache,
  font : FontFace,
  cp : Int,
  gid : Int,
  size_px : Float,
  bold : Bool,
  italic : Bool,
) -> GlyphEntry raise @tycho.RhiError {
  // Quantize the requested size to 1/4 px. This keeps animated/zoomed text from
  // re-rasterizing on every integer step while staying small enough to be
  // visually smooth.
  let clamped = @tmath.max_f((6.0 : Float), size_px)
  let q4 = (clamped * (4.0 : Float) + (0.5 : Float)).to_int()
  let px_size = Float::from_int(q4) * (0.25 : Float)
  let style_key = if bold && italic {
    ":bi"
  } else if bold {
    ":b"
  } else if italic {
    ":i"
  } else {
    ""
  }
  let use_sdf = gid > 0 && px_size >= (48.0 : Float)
  // SDF entries are generated once at a fixed base size and scaled on read,
  // so zoomed/animated text reuses the distance field.
  let key = if use_sdf {
    "\{font.id}:g\{gid}:msdf\{style_key}"
  } else if gid > 0 {
    "\{font.id}:g\{gid}:\{q4}\{style_key}"
  } else {
    "\{font.id}:\{cp}:\{q4}\{style_key}"
  }
  match self.entries.get(key) {
    Some(e) => {
      match self.bitmaps.get(key) {
        Some(b) => b.last_frame = self.frame
        None => ()
      }
      if e.is_sdf && e.sdf_base > (0.0 : Float) {
        let scale = px_size / e.sdf_base
        return scale_glyph_entry(
          e,
          scale,
          font.glyph_advance(gid, px_size),
        )
      }
      return e
    }
    None => ()
  }
  let raster_size = if use_sdf { (64.0 : Float) } else { px_size }
  let adv = if gid > 0 {
    font.glyph_advance(gid, raster_size)
  } else {
    font.advance_width(cp, raster_size)
  }
  let (ox0, oy0, gw0, gh0, pixels0) = match font.ttf {
    Some(t) => if gid > 0 {
      rasterize_ttf_glyph_gid(t, gid, raster_size)
    } else {
      rasterize_ttf_glyph(t, cp, raster_size)
    }
    None => rasterize_builtin_glyph(cp, raster_size)
  }
  let (ox1, oy1, gw1, gh1, pixels1) = synthesize_glyph_bitmap(
    ox0,
    oy0,
    gw0,
    gh0,
    pixels0,
    bold,
    italic,
  )
  let (ox, oy, gw, gh, pixels) = if use_sdf {
    let (sw, sh, msdf) = build_msdf(gw1, gh1, pixels1)
    (ox1 - SDF_SPREAD, oy1 - SDF_SPREAD, sw, sh, msdf)
  } else {
    (ox1, oy1, gw1, gh1, pixels1)
  }
  // Padding around each glyph so a quad shifted by a fraction of a pixel
  // samples transparent padding at its edges (subpixel positioning) instead of
  // clamping to the glyph's edge pixels.
  let pad = 1
  let mut cacheable = true
  let mut ux0 = (0.0 : Float)
  let mut uy0 = (0.0 : Float)
  let mut ux1 = (0.0 : Float)
  let mut uy1 = (0.0 : Float)
  let mut quad_w = gw
  let mut quad_h = gh
  if gw > 0 && gh > 0 {
    let (aw, ah) = self.glyph_atlas_limit(use_sdf)
    if gw + pad * 2 > aw || gh + pad * 2 > ah {
      self.atlas_overflow_count = self.atlas_overflow_count + 1
      cacheable = false
    } else {
      let placed = self.alloc_glyph(use_sdf, gw, gh, pixels, pad)
      match placed {
        Some((ax, ay, pw, ph)) => {
          let (a, b, c, d) = self.glyph_uv(use_sdf, ax, ay, pw, ph)
          ux0 = a
          uy0 = b
          ux1 = c
          uy1 = d
          quad_w = pw
          quad_h = ph
        }
        None => {
          self.atlas_overflow_count = self.atlas_overflow_count + 1
          cacheable = false
        }
      }
    }
  }
  let entry : GlyphEntry = {
    uv_x0: ux0,
    uv_y0: uy0,
    uv_x1: ux1,
    uv_y1: uy1,
    offset_x: ox - pad,
    offset_y: oy - pad,
    width: quad_w,
    height: quad_h,
    advance: adv,
    is_sdf: use_sdf,
    sdf_base: if use_sdf { (64.0 : Float) } else { (0.0 : Float) },
    is_msdf: use_sdf,
  }
  if cacheable {
    self.entries[key] = entry
    if use_sdf {
      self.sdf_entries = self.sdf_entries + 1
      self.msdf_entries = self.msdf_entries + 1
    }
    if gw > 0 && gh > 0 {
      self.bitmaps[key] = {
        pixels,
        gw,
        gh,
        last_frame: self.frame,
      }
    }
  }
  if use_sdf {
    let scale = px_size / (64.0 : Float)
    return scale_glyph_entry(
      entry,
      scale,
      font.glyph_advance(gid, px_size),
    )
  }
  entry
}

///|
// Allocate an R8 coverage bitmap in the shared glyph atlas and return its UV
// rect. The bitmap is not retained: callers re-rasterize when the atlas
// generation changes.
pub fn GlyphCache::alloc_coverage(
  self : GlyphCache,
  w : Int,
  h : Int,
  pixels : Bytes,
) -> (Float, Float, Float, Float)? raise @tycho.RhiError {
  if w <= 0 || h <= 0 || w + 2 > self.atlas.width || h + 2 > self.atlas.height {
    return None
  }
  match self.atlas.alloc_and_upload(w, h, pixels, padding=1) {
    Some((tx, ty)) => Some(self.atlas.uv_rect(tx, ty, w, h))
    None => {
      self.compact()
      match self.atlas.alloc_and_upload(w, h, pixels, padding=1) {
        Some((tx, ty)) => Some(self.atlas.uv_rect(tx, ty, w, h))
        None => None
      }
    }
  }
}

///|
pub fn GlyphCache::destroy(self : GlyphCache) -> Unit {
  self.atlas.destroy()
  self.msdf_atlas.destroy()
}
