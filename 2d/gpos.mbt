// Minimal GPOS reader for the default `kern` feature.
//
// Supports lookup type 2 (PairPos format 1/2) and type 9 extension wrappers.
// Only xAdvance is applied; placements/devices are ignored. This covers the
// class-based kerning used by DejaVu/Noto Latin fonts.

///|
priv struct GposData {
  bytes : Bytes
  base : Int
  kern_lookups : Array[Int]
}

///|
fn gpos_u16(b : Bytes, off : Int) -> Int {
  if off < 0 || off + 2 > b.length() {
    0
  } else {
    be_u16(b, off)
  }
}

///|
fn gpos_find_record(g : GposData, list_off : Int, tag : String) -> Int? {
  let b = g.bytes
  let count = gpos_u16(b, list_off)
  for i = 0; i < count; i = i + 1 {
    let rec = list_off + 2 + i * 6
    if rec + 6 > b.length() {
      return None
    }
    if tag_eq(b, rec, tag) {
      return Some(list_off + gpos_u16(b, rec + 4))
    }
  }
  None
}

///|
fn gpos_feature_lookups(
  g : GposData,
  script_tag : String,
  feature_tag : String,
) -> Array[Int] {
  let b = g.bytes
  let out : Array[Int] = []
  let script_list = g.base + gpos_u16(b, g.base + 4)
  let feature_list = g.base + gpos_u16(b, g.base + 6)
  let script = match gpos_find_record(g, script_list, script_tag) {
    Some(v) => v
    None => return out
  }
  let default_off = gpos_u16(b, script)
  if default_off == 0 {
    return out
  }
  let langsys = script + default_off
  let feature_count = gpos_u16(b, langsys + 4)
  for fi = 0; fi < feature_count; fi = fi + 1 {
    let idx_off = langsys + 6 + fi * 2
    if idx_off + 2 > b.length() {
      break
    }
    let feature_idx = gpos_u16(b, idx_off)
    let rec = feature_list + 2 + feature_idx * 6
    if rec + 6 > b.length() {
      continue
    }
    if tag_eq(b, rec, feature_tag) {
      let ft = feature_list + gpos_u16(b, rec + 4)
      let lookup_count = gpos_u16(b, ft + 2)
      for li = 0; li < lookup_count; li = li + 1 {
        let lo = ft + 4 + li * 2
        if lo + 2 > b.length() {
          break
        }
        out.push(gpos_u16(b, lo))
      }
    }
  }
  out
}

///|
fn GposData::parse(bytes : Bytes, base : Int) -> GposData? {
  if base + 10 > bytes.length() {
    return None
  }
  let tmp : GposData = { bytes, base, kern_lookups: [] }
  let mut lookups = gpos_feature_lookups(tmp, "latn", "kern")
  if lookups.length() == 0 {
    lookups = gpos_feature_lookups(tmp, "DFLT", "kern")
  }
  Some({ bytes, base, kern_lookups: lookups })
}

///|
fn gpos_coverage_index(g : GposData, cov_off : Int, gid : Int) -> Int? {
  let b = g.bytes
  let fmt = gpos_u16(b, cov_off)
  if fmt == 1 {
    let count = gpos_u16(b, cov_off + 2)
    let mut lo = 0
    let mut hi = count - 1
    while lo <= hi {
      let mid = (lo + hi) / 2
      let off = cov_off + 4 + mid * 2
      if off + 2 > b.length() {
        return None
      }
      let v = gpos_u16(b, off)
      if gid < v {
        hi = mid - 1
      } else if gid > v {
        lo = mid + 1
      } else {
        return Some(mid)
      }
    }
    return None
  }
  if fmt == 2 {
    let count = gpos_u16(b, cov_off + 2)
    for i = 0; i < count; i = i + 1 {
      let rec = cov_off + 4 + i * 6
      if rec + 6 > b.length() {
        return None
      }
      let start = gpos_u16(b, rec)
      let end = gpos_u16(b, rec + 2)
      if gid >= start && gid <= end {
        return Some(gpos_u16(b, rec + 4) + gid - start)
      }
    }
  }
  None
}

///|
fn gpos_class(g : GposData, class_def : Int, gid : Int) -> Int {
  let b = g.bytes
  let fmt = gpos_u16(b, class_def)
  if fmt == 1 {
    let start = gpos_u16(b, class_def + 2)
    let count = gpos_u16(b, class_def + 4)
    if gid >= start && gid < start + count {
      return gpos_u16(b, class_def + 6 + (gid - start) * 2)
    }
    return 0
  }
  if fmt == 2 {
    let count = gpos_u16(b, class_def + 2)
    for i = 0; i < count; i = i + 1 {
      let rec = class_def + 4 + i * 6
      if rec + 6 > b.length() {
        return 0
      }
      let start = gpos_u16(b, rec)
      let end = gpos_u16(b, rec + 2)
      if gid >= start && gid <= end {
        return gpos_u16(b, rec + 4)
      }
    }
  }
  0
}

///|
fn gpos_value_size(vf : Int) -> Int {
  let mut bits = vf & 0xFF
  let mut n = 0
  while bits != 0 {
    n = n + (bits & 1)
    bits = bits >> 1
  }
  n * 2
}

///|
// Read xAdvance from a ValueRecord with `vf`; `off` is the record start.
fn gpos_value_x_advance(b : Bytes, vf : Int, off : Int) -> Int {
  let mut p = off
  if (vf & 0x0001) != 0 {
    p = p + 2
  }
  if (vf & 0x0002) != 0 {
    p = p + 2
  }
  if (vf & 0x0004) != 0 {
    be_i16(b, p)
  } else {
    0
  }
}

///|
fn gpos_pair_pos_format2(g : GposData, sub : Int, g1 : Int, g2 : Int) -> Int {
  let b = g.bytes
  let cov = sub + gpos_u16(b, sub + 2)
  match gpos_coverage_index(g, cov, g1) {
    Some(_) => ()
    None => return 0
  }
  let vf1 = gpos_u16(b, sub + 4)
  let vf2 = gpos_u16(b, sub + 6)
  let class1 = gpos_class(g, sub + gpos_u16(b, sub + 8), g1)
  let class2 = gpos_class(g, sub + gpos_u16(b, sub + 10), g2)
  let c1_count = gpos_u16(b, sub + 12)
  let c2_count = gpos_u16(b, sub + 14)
  if class1 >= c1_count || class2 >= c2_count {
    return 0
  }
  let v1_size = gpos_value_size(vf1)
  let v2_size = gpos_value_size(vf2)
  let rec_size = v1_size + v2_size
  let rec = sub + 16 + class1 * c2_count * rec_size + class2 * rec_size
  if rec + v1_size > b.length() {
    return 0
  }
  gpos_value_x_advance(b, vf1, rec)
}

///|
fn gpos_pair_pos_format1(g : GposData, sub : Int, g1 : Int, g2 : Int) -> Int {
  let b = g.bytes
  let cov = sub + gpos_u16(b, sub + 2)
  let cov_idx = match gpos_coverage_index(g, cov, g1) {
    Some(v) => v
    None => return 0
  }
  let vf1 = gpos_u16(b, sub + 4)
  let vf2 = gpos_u16(b, sub + 6)
  let set_count = gpos_u16(b, sub + 8)
  if cov_idx >= set_count {
    return 0
  }
  let set = sub + gpos_u16(b, sub + 10 + cov_idx * 2)
  if set + 2 > b.length() {
    return 0
  }
  let count = gpos_u16(b, set)
  let v1_size = gpos_value_size(vf1)
  let v2_size = gpos_value_size(vf2)
  let rec_size = 2 + v1_size + v2_size
  for i = 0; i < count; i = i + 1 {
    let rec = set + 2 + i * rec_size
    if rec + rec_size > b.length() {
      return 0
    }
    if gpos_u16(b, rec) == g2 {
      return gpos_value_x_advance(b, vf1, rec + 2)
    }
  }
  0
}

///|
fn gpos_apply_pair_pos(g : GposData, sub : Int, g1 : Int, g2 : Int) -> Int {
  let b = g.bytes
  let fmt = gpos_u16(b, sub)
  if fmt == 1 {
    gpos_pair_pos_format1(g, sub, g1, g2)
  } else if fmt == 2 {
    gpos_pair_pos_format2(g, sub, g1, g2)
  } else {
    0
  }
}

///|
fn gpos_apply_lookup(g : GposData, lookup_off : Int, g1 : Int, g2 : Int) -> Int {
  let b = g.bytes
  let typ = gpos_u16(b, lookup_off)
  let sub_count = gpos_u16(b, lookup_off + 4)
  for si = 0; si < sub_count; si = si + 1 {
    let sub = lookup_off + gpos_u16(b, lookup_off + 6 + si * 2)
    if typ == 2 {
      let v = gpos_apply_pair_pos(g, sub, g1, g2)
      if v != 0 {
        return v
      }
    } else if typ == 9 {
      // Extension: format u16, extensionLookupType u16, extensionOffset u32.
      if gpos_u16(b, sub) == 1 {
        let ext_type = gpos_u16(b, sub + 2)
        let ext_off = be_u32(b, sub + 4).reinterpret_as_int()
        if ext_type == 2 {
          let v = gpos_apply_pair_pos(g, sub + ext_off, g1, g2)
          if v != 0 {
            return v
          }
        }
      }
    }
  }
  0
}

///|
fn GposData::kern(self : GposData, g1 : Int, g2 : Int) -> Int {
  let b = self.bytes
  let lookup_list = self.base + gpos_u16(b, self.base + 8)
  for idx in self.kern_lookups {
    let off = lookup_list + gpos_u16(b, lookup_list + 2 + idx * 2)
    if off + 6 > b.length() {
      continue
    }
    let v = gpos_apply_lookup(self, off, g1, g2)
    if v != 0 {
      return v
    }
  }
  0
}

///|
pub fn FontFace::has_gpos_kern(self : FontFace) -> Bool {
  match self.gpos {
    Some(g) => g.kern_lookups.length() > 0
    None => false
  }
}

///|
pub fn FontFace::gpos_kern(
  self : FontFace,
  g1 : Int,
  g2 : Int,
  size_px : Float,
) -> Float {
  if g1 <= 0 || g2 <= 0 {
    return (0.0 : Float)
  }
  match self.gpos {
    Some(g) => {
      let units = g.kern(g1, g2)
      match self.ttf {
        Some(t) => Float::from_int(units) * size_px / Float::from_int(t.units_per_em)
        None => (0.0 : Float)
      }
    }
    None => (0.0 : Float)
  }
}
