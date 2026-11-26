// GDEF subset: glyph classes, mark attachment classes and mark glyph sets.
// These drive GSUB lookup flags (IgnoreMarks/UseMarkFilteringSet).

///|
priv struct GdefData {
  bytes : Bytes
  glyph_class_off : Int
  mark_attach_off : Int
  mark_sets_off : Int
}

///|
fn gdef_class_value(bytes : Bytes, off : Int, gid : Int) -> Int {
  if off <= 0 || off + 4 > bytes.length() {
    return 0
  }
  let fmt = be_u16(bytes, off)
  if fmt == 1 {
    let start = be_u16(bytes, off + 2)
    let count = be_u16(bytes, off + 4)
    if gid >= start && gid < start + count {
      return be_u16(bytes, off + 6 + (gid - start) * 2)
    }
    return 0
  }
  if fmt == 2 {
    let count = be_u16(bytes, off + 2)
    for i = 0; i < count; i = i + 1 {
      let rec = off + 4 + i * 6
      if rec + 6 > bytes.length() {
        return 0
      }
      let start = be_u16(bytes, rec)
      let end = be_u16(bytes, rec + 2)
      if gid >= start && gid <= end {
        return be_u16(bytes, rec + 4)
      }
    }
  }
  0
}

///|
fn GdefData::parse(bytes : Bytes, base : Int) -> GdefData? {
  if base + 12 > bytes.length() {
    return None
  }
  let minor = be_u16(bytes, base + 2)
  let glyph_class = be_u16(bytes, base + 4)
  let mark_attach = be_u16(bytes, base + 10)
  let mark_sets = if minor >= 2 && base + 14 <= bytes.length() {
    be_u16(bytes, base + 12)
  } else {
    0
  }
  Some({
    bytes,
    glyph_class_off: if glyph_class > 0 { base + glyph_class } else { 0 },
    mark_attach_off: if mark_attach > 0 { base + mark_attach } else { 0 },
    mark_sets_off: if mark_sets > 0 { base + mark_sets } else { 0 },
  })
}

///|
fn GdefData::glyph_class(self : GdefData, gid : Int) -> Int {
  gdef_class_value(self.bytes, self.glyph_class_off, gid)
}

///|
fn GdefData::mark_attach_class(self : GdefData, gid : Int) -> Int {
  gdef_class_value(self.bytes, self.mark_attach_off, gid)
}

///|
fn GdefData::in_mark_set(self : GdefData, set_index : Int, gid : Int) -> Bool {
  if self.mark_sets_off <= 0 {
    return false
  }
  let b = self.bytes
  if self.mark_sets_off + 4 > b.length() {
    return false
  }
  // MarkGlyphSetsDef: format u16, markSetCount u16, coverageOffsets u32[].
  if be_u16(b, self.mark_sets_off) != 1 {
    return false
  }
  let count = be_u16(b, self.mark_sets_off + 2)
  if set_index < 0 || set_index >= count {
    return false
  }
  let off = self.mark_sets_off + be_u32(b, self.mark_sets_off + 4 + set_index * 4).reinterpret_as_int()
  gsub_coverage_index_abs(b, off, gid) != None
}

///|
// Coverage lookup shared with GSUB; declared here to avoid a dependency cycle.
fn gsub_coverage_index_abs(b : Bytes, cov_off : Int, gid : Int) -> Int? {
  if cov_off < 0 || cov_off + 4 > b.length() {
    return None
  }
  let fmt = be_u16(b, cov_off)
  if fmt == 1 {
    let count = be_u16(b, cov_off + 2)
    let mut lo = 0
    let mut hi = count - 1
    while lo <= hi {
      let mid = (lo + hi) / 2
      let v = be_u16(b, cov_off + 4 + mid * 2)
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
    let count = be_u16(b, cov_off + 2)
    for i = 0; i < count; i = i + 1 {
      let rec = cov_off + 4 + i * 6
      if rec + 6 > b.length() {
        return None
      }
      let start = be_u16(b, rec)
      let end = be_u16(b, rec + 2)
      if gid >= start && gid <= end {
        return Some(be_u16(b, rec + 4) + gid - start)
      }
    }
  }
  None
}
