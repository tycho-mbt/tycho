// Minimal GSUB reader for the default `liga` feature.
//
// Supported lookups: type 4 (ligature substitution) with coverage formats 1/2
// and LigatureSubst format 1. Lookup flags and mark filtering are intentionally
// ignored; the target is Latin `fi`/`ff`/`fl` style ligatures. Arabic joining
// still uses the presentation-form path in shaping.mbt.

///|
priv struct GsubData {
  bytes : Bytes
  base : Int
  liga_lookups : Array[Int]
  arab_isol : Array[Int]
  arab_init : Array[Int]
  arab_medi : Array[Int]
  arab_fina : Array[Int]
  arab_rlig : Array[Int]
  deva_features : Map[String, Array[Int]]
  gdef : GdefData?
}

///|
fn gsub_u16(b : Bytes, off : Int) -> Int {
  if off < 0 || off + 2 > b.length() {
    0
  } else {
    be_u16(b, off)
  }
}

///|
fn gsub_find_record(
  g : GsubData,
  list_off : Int,
  tag : String,
) -> Int? {
  let b = g.bytes
  let count = gsub_u16(b, list_off)
  for i = 0; i < count; i = i + 1 {
    let rec = list_off + 2 + i * 6
    if rec + 6 > b.length() {
      return None
    }
    if tag_eq(b, rec, tag) {
      return Some(list_off + gsub_u16(b, rec + 4))
    }
  }
  None
}

///|
fn gsub_langsys(g : GsubData, script_off : Int) -> Int? {
  let b = g.bytes
  let default_off = gsub_u16(b, script_off)
  if default_off == 0 {
    return None
  }
  Some(script_off + default_off)
}

///|
fn gsub_feature_lookups(
  g : GsubData,
  script_tag : String,
  feature_tag : String,
) -> Array[Int] {
  let b = g.bytes
  let out : Array[Int] = []
  let script_list = g.base + gsub_u16(b, g.base + 4)
  let feature_list = g.base + gsub_u16(b, g.base + 6)
  let script = match gsub_find_record(g, script_list, script_tag) {
    Some(v) => v
    None => return out
  }
  let langsys = match gsub_langsys(g, script) {
    Some(v) => v
    None => return out
  }
  let feature_count = gsub_u16(b, langsys + 4)
  for fi = 0; fi < feature_count; fi = fi + 1 {
    let idx_off = langsys + 6 + fi * 2
    if idx_off + 2 > b.length() {
      break
    }
    let feature_idx = gsub_u16(b, idx_off)
    let rec = feature_list + 2 + feature_idx * 6
    if rec + 6 > b.length() {
      continue
    }
    if tag_eq(b, rec, feature_tag) {
      let ft = feature_list + gsub_u16(b, rec + 4)
      let lookup_count = gsub_u16(b, ft + 2)
      for li = 0; li < lookup_count; li = li + 1 {
        let lo = ft + 4 + li * 2
        if lo + 2 > b.length() {
          break
        }
        out.push(gsub_u16(b, lo))
      }
    }
  }
  out
}

///|
fn GsubData::parse(
  bytes : Bytes,
  base : Int,
  gdef : GdefData?,
) -> GsubData? {
  if base + 10 > bytes.length() {
    return None
  }
  let tmp : GsubData = {
    bytes,
    base,
    liga_lookups: [],
    arab_isol: [],
    arab_init: [],
    arab_medi: [],
    arab_fina: [],
    arab_rlig: [],
    deva_features: Map([]),
    gdef,
  }
  let mut lookups = gsub_feature_lookups(tmp, "latn", "liga")
  if lookups.length() == 0 {
    lookups = gsub_feature_lookups(tmp, "DFLT", "liga")
  }
  let deva_tags = [
    "akhn", "rphf", "blwf", "half", "cjct", "pres", "abvs", "blws", "psts",
    "haln", "nukt", "vatu",
  ]
  let deva_features : Map[String, Array[Int]] = Map([])
  for tag in deva_tags {
    deva_features[tag] = gsub_feature_lookups(tmp, "deva", tag)
  }
  Some({
    bytes,
    base,
    liga_lookups: lookups,
    arab_isol: gsub_feature_lookups(tmp, "arab", "isol"),
    arab_init: gsub_feature_lookups(tmp, "arab", "init"),
    arab_medi: gsub_feature_lookups(tmp, "arab", "medi"),
    arab_fina: gsub_feature_lookups(tmp, "arab", "fina"),
    arab_rlig: gsub_feature_lookups(tmp, "arab", "rlig"),
    deva_features,
    gdef,
  })
}

///|
fn gsub_coverage_index(
  g : GsubData,
  cov_off : Int,
  gid : Int,
) -> Int? {
  let b = g.bytes
  let fmt = gsub_u16(b, cov_off)
  if fmt == 1 {
    let count = gsub_u16(b, cov_off + 2)
    let mut lo = 0
    let mut hi = count - 1
    while lo <= hi {
      let mid = (lo + hi) / 2
      let off = cov_off + 4 + mid * 2
      if off + 2 > b.length() {
        return None
      }
      let v = gsub_u16(b, off)
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
    let count = gsub_u16(b, cov_off + 2)
    for i = 0; i < count; i = i + 1 {
      let rec = cov_off + 4 + i * 6
      if rec + 6 > b.length() {
        return None
      }
      let start = gsub_u16(b, rec)
      let end = gsub_u16(b, rec + 2)
      if gid >= start && gid <= end {
        return Some(gsub_u16(b, rec + 4) + gid - start)
      }
    }
  }
  None
}

///|
fn gsub_apply_lig_subtable(
  g : GsubData,
  sub : Int,
  input : Array[(Int, Int)],
) -> Array[(Int, Int)] {
  let b = g.bytes
  if gsub_u16(b, sub) != 1 {
    return input
  }
  let cov = sub + gsub_u16(b, sub + 2)
  let set_count = gsub_u16(b, sub + 4)
  let out : Array[(Int, Int)] = []
  let mut i = 0
  while i < input.length() {
    let first = input[i].0
    let mut matched = false
    match gsub_coverage_index(g, cov, first) {
      Some(cov_idx) =>
        if cov_idx < set_count {
          let set = sub + gsub_u16(b, sub + 6 + cov_idx * 2)
          let lig_count = gsub_u16(b, set)
          let mut best_glyph = 0
          let mut best_comps = 0
          for li = 0; li < lig_count; li = li + 1 {
            let lig = set + gsub_u16(b, set + 2 + li * 2)
            let lig_glyph = gsub_u16(b, lig)
            let comp_count = gsub_u16(b, lig + 2)
            if comp_count <= 0 || i + comp_count > input.length() {
              continue
            }
            let mut ok = true
            for k = 1; k < comp_count; k = k + 1 {
              let comp = gsub_u16(b, lig + 4 + (k - 1) * 2)
              if input[i + k].0 != comp {
                ok = false
                break
              }
            }
            if ok && comp_count > best_comps {
              best_glyph = lig_glyph
              best_comps = comp_count
            }
          }
          if best_comps > 0 {
            let mut total = 0
            for k = 0; k < best_comps; k = k + 1 {
              total = total + input[i + k].1
            }
            out.push((best_glyph, total))
            i = i + best_comps
            matched = true
          }
        }
      None => ()
    }
    if !matched {
      out.push(input[i])
      i = i + 1
    }
  }
  out
}

///|
fn gsub_apply_lookup(
  g : GsubData,
  lookup_off : Int,
  input : Array[(Int, Int)],
) -> Array[(Int, Int)] {
  let b = g.bytes
  if gsub_u16(b, lookup_off) != 4 {
    return input
  }
  let sub_count = gsub_u16(b, lookup_off + 4)
  let mut cur = input
  for si = 0; si < sub_count; si = si + 1 {
    let sub = lookup_off + gsub_u16(b, lookup_off + 6 + si * 2)
    cur = gsub_apply_lig_subtable(g, sub, cur)
  }
  cur
}

///|
fn gsub_apply_single_lookup(
  g : GsubData,
  lookup_off : Int,
  gid : Int,
) -> Int {
  let b = g.bytes
  if gsub_u16(b, lookup_off) != 1 {
    return gid
  }
  let sub_count = gsub_u16(b, lookup_off + 4)
  for si = 0; si < sub_count; si = si + 1 {
    let sub = lookup_off + gsub_u16(b, lookup_off + 6 + si * 2)
    let fmt = gsub_u16(b, sub)
    let cov = sub + gsub_u16(b, sub + 2)
    match gsub_coverage_index(g, cov, gid) {
      Some(idx) =>
        if fmt == 1 {
          return (gid + be_i16(b, sub + 4)) & 0xFFFF
        } else if fmt == 2 {
          let count = gsub_u16(b, sub + 4)
          if idx < count {
            return gsub_u16(b, sub + 6 + idx * 2)
          }
        }
      None => ()
    }
  }
  gid
}

///|
fn GsubData::substitute(
  self : GsubData,
  lookups : Array[Int],
  gid : Int,
) -> Int {
  let b = self.bytes
  let lookup_list = self.base + gsub_u16(b, self.base + 8)
  let mut cur = gid
  for idx in lookups {
    let off = lookup_list + gsub_u16(b, lookup_list + 2 + idx * 2)
    if off + 6 > b.length() {
      continue
    }
    cur = gsub_apply_single_lookup(self, off, cur)
  }
  cur
}

///|
// Map an Arabic base codepoint to its joining-form glyph id via GSUB.
// form: 0 isolated, 1 final, 2 initial, 3 medial.
pub fn FontFace::arabic_form_gid(
  self : FontFace,
  cp : Int,
  form : Int,
) -> Int? {
  let g = match self.gsub {
    Some(g) => g
    None => return None
  }
  let gid = self.glyph_id(cp)
  if gid <= 0 {
    return None
  }
  let lookups = if form == 1 {
    g.arab_fina
  } else if form == 2 {
    g.arab_init
  } else if form == 3 {
    g.arab_medi
  } else {
    g.arab_isol
  }
  let out = g.substitute(lookups, gid)
  if out != gid && out > 0 {
    Some(out)
  } else {
    None
  }
}

///|
fn gsub_lookup_flags(g : GsubData, lookup_off : Int) -> Int {
  gsub_u16(g.bytes, lookup_off + 2)
}

///|
fn gsub_glyph_ignored(g : GsubData, gid : Int, flags : Int) -> Bool {
  let gdef = match g.gdef {
    Some(v) => v
    None => return false
  }
  let cls = gdef.glyph_class(gid)
  if (flags & 0x0002) != 0 && cls == 1 {
    return true
  }
  if (flags & 0x0004) != 0 && cls == 2 {
    return true
  }
  if (flags & 0x0008) != 0 && cls == 3 {
    return true
  }
  if cls == 3 {
    let attach = (flags >> 8) & 0xFF
    if attach != 0 && gdef.mark_attach_class(gid) != attach {
      return true
    }
  }
  false
}

///|
fn gsub_next_index(
  g : GsubData,
  input : Array[(Int, Int)],
  from : Int,
  flags : Int,
) -> Int? {
  let mut i = from
  while i < input.length() {
    if !gsub_glyph_ignored(g, input[i].0, flags) {
      return Some(i)
    }
    i = i + 1
  }
  None
}

///|
fn gsub_prev_index(
  g : GsubData,
  input : Array[(Int, Int)],
  from : Int,
  flags : Int,
) -> Int? {
  let mut i = from
  while i >= 0 {
    if !gsub_glyph_ignored(g, input[i].0, flags) {
      return Some(i)
    }
    i = i - 1
  }
  None
}

///|
fn gsub_cov_has(g : GsubData, cov : Int, gid : Int) -> Bool {
  match gsub_coverage_index(g, cov, gid) {
    Some(_) => true
    None => false
  }
}

///|
fn gsub_lig_match(
  g : GsubData,
  sub : Int,
  input : Array[(Int, Int)],
  pos : Int,
) -> (Int, Int, Int)? {
  let b = g.bytes
  if gsub_u16(b, sub) != 1 || pos >= input.length() {
    return None
  }
  let cov = sub + gsub_u16(b, sub + 2)
  let set_count = gsub_u16(b, sub + 4)
  let cov_idx = match gsub_coverage_index(g, cov, input[pos].0) {
    Some(v) => v
    None => return None
  }
  if cov_idx >= set_count {
    return None
  }
  let set = sub + gsub_u16(b, sub + 6 + cov_idx * 2)
  let lig_count = gsub_u16(b, set)
  let mut best_glyph = 0
  let mut best_match = 0
  let mut best_src = 0
  for li = 0; li < lig_count; li = li + 1 {
    let lig = set + gsub_u16(b, set + 2 + li * 2)
    let lig_glyph = gsub_u16(b, lig)
    let comp_count = gsub_u16(b, lig + 2)
    if comp_count <= 0 || pos + comp_count > input.length() {
      continue
    }
    let mut ok = true
    for k = 1; k < comp_count; k = k + 1 {
      if input[pos + k].0 != gsub_u16(b, lig + 4 + (k - 1) * 2) {
        ok = false
        break
      }
    }
    if ok && comp_count > best_match {
      best_glyph = lig_glyph
      best_match = comp_count
      let mut src = 0
      for k = 0; k < comp_count; k = k + 1 {
        src = src + input[pos + k].1
      }
      best_src = src
    }
  }
  if best_match > 0 {
    Some((best_glyph, best_match, best_src))
  } else {
    None
  }
}

///|
fn gsub_apply_lig_lookup_at(
  g : GsubData,
  lookup_off : Int,
  input : Array[(Int, Int)],
  pos : Int,
) -> Array[(Int, Int)] {
  let b = g.bytes
  let sub_count = gsub_u16(b, lookup_off + 4)
  for si = 0; si < sub_count; si = si + 1 {
    let sub = lookup_off + gsub_u16(b, lookup_off + 6 + si * 2)
    match gsub_lig_match(g, sub, input, pos) {
      Some((lig_gid, matched, src)) => {
        let out : Array[(Int, Int)] = []
        for k = 0; k < pos; k = k + 1 {
          out.push(input[k])
        }
        out.push((lig_gid, src))
        for k = pos + matched; k < input.length(); k = k + 1 {
          out.push(input[k])
        }
        return out
      }
      None => ()
    }
  }
  input
}

///|
fn gsub_apply_nested_at(
  g : GsubData,
  lookup_idx : Int,
  input : Array[(Int, Int)],
  pos : Int,
  depth : Int,
) -> Array[(Int, Int)] {
  if depth > 8 || pos < 0 || pos >= input.length() {
    return input
  }
  let b = g.bytes
  let lookup_list = g.base + gsub_u16(b, g.base + 8)
  let off = lookup_list + gsub_u16(b, lookup_list + 2 + lookup_idx * 2)
  let typ = gsub_u16(b, off)
  if typ == 1 {
    let (gid, comps) = input[pos]
    let out : Array[(Int, Int)] = []
    for k = 0; k < input.length(); k = k + 1 {
      if k == pos {
        out.push((gsub_apply_single_lookup(g, off, gid), comps))
      } else {
        out.push(input[k])
      }
    }
    return out
  }
  if typ == 4 {
    return gsub_apply_lig_lookup_at(g, off, input, pos)
  }
  input
}

///|
fn gsub_apply_chain3(
  g : GsubData,
  lookup_off : Int,
  sub : Int,
  input : Array[(Int, Int)],
  depth : Int,
) -> Array[(Int, Int)] {
  let b = g.bytes
  let flags = gsub_lookup_flags(g, lookup_off)
  let back_count = gsub_u16(b, sub + 2)
  let back_cov = sub + 4
  let input_count_at = back_cov + back_count * 2
  let input_count = gsub_u16(b, input_count_at)
  let input_cov = input_count_at + 2
  let look_count_at = input_cov + input_count * 2
  let look_count = gsub_u16(b, look_count_at)
  let look_cov = look_count_at + 2
  let rec_at = look_cov + look_count * 2
  let rec_count = gsub_u16(b, rec_at)
  if input_count <= 0 {
    return input
  }
  let mut cur = input
  let mut i = 0
  while i < cur.length() {
    let positions : Array[Int] = [i]
    let mut cursor = i
    let mut ok = gsub_cov_has(g, sub + gsub_u16(b, input_cov), cur[i].0)
    let mut k = 1
    while ok && k < input_count {
      match gsub_next_index(g, cur, cursor + 1, flags) {
        Some(p) => {
          if gsub_cov_has(g, sub + gsub_u16(b, input_cov + k * 2), cur[p].0) {
            positions.push(p)
            cursor = p
          } else {
            ok = false
          }
        }
        None => ok = false
      }
      k = k + 1
    }
    // Backtrack: immediately preceding non-ignored glyphs.
    let mut bpos = i
    let mut bk = 0
    while ok && bk < back_count {
      match gsub_prev_index(g, cur, bpos - 1, flags) {
        Some(p) => {
          if !gsub_cov_has(g, sub + gsub_u16(b, back_cov + bk * 2), cur[p].0) {
            ok = false
          }
          bpos = p
        }
        None => ok = false
      }
      bk = bk + 1
    }
    // Lookahead: following non-ignored glyphs.
    let mut lpos = cursor
    let mut lk = 0
    while ok && lk < look_count {
      match gsub_next_index(g, cur, lpos + 1, flags) {
        Some(p) => {
          if !gsub_cov_has(g, sub + gsub_u16(b, look_cov + lk * 2), cur[p].0) {
            ok = false
          }
          lpos = p
        }
        None => ok = false
      }
      lk = lk + 1
    }
    if ok {
      // Apply records from the end so earlier ligatures do not shift indices.
      let mut r = rec_count
      while r > 0 {
        r = r - 1
        let rec = rec_at + 2 + r * 4
        let seq = gsub_u16(b, rec)
        let lookup_idx = gsub_u16(b, rec + 2)
        if seq < positions.length() {
          cur = gsub_apply_nested_at(
            g,
            lookup_idx,
            cur,
            positions[seq],
            depth + 1,
          )
        }
      }
    }
    i = i + 1
  }
  cur
}

///|
fn gsub_apply_context3(
  g : GsubData,
  lookup_off : Int,
  sub : Int,
  input : Array[(Int, Int)],
  depth : Int,
) -> Array[(Int, Int)] {
  let b = g.bytes
  let flags = gsub_lookup_flags(g, lookup_off)
  let input_count = gsub_u16(b, sub + 2)
  let input_cov = sub + 4
  let rec_at = input_cov + input_count * 2
  let rec_count = gsub_u16(b, rec_at)
  if input_count <= 0 {
    return input
  }
  let mut cur = input
  let mut i = 0
  while i < cur.length() {
    let positions : Array[Int] = [i]
    let mut cursor = i
    let mut ok = gsub_cov_has(g, sub + gsub_u16(b, input_cov), cur[i].0)
    let mut k = 1
    while ok && k < input_count {
      match gsub_next_index(g, cur, cursor + 1, flags) {
        Some(p) => {
          if gsub_cov_has(g, sub + gsub_u16(b, input_cov + k * 2), cur[p].0) {
            positions.push(p)
            cursor = p
          } else {
            ok = false
          }
        }
        None => ok = false
      }
      k = k + 1
    }
    if ok {
      let mut r = rec_count
      while r > 0 {
        r = r - 1
        let rec = rec_at + 2 + r * 4
        let seq = gsub_u16(b, rec)
        let lookup_idx = gsub_u16(b, rec + 2)
        if seq < positions.length() {
          cur = gsub_apply_nested_at(
            g,
            lookup_idx,
            cur,
            positions[seq],
            depth + 1,
          )
        }
      }
    }
    i = i + 1
  }
  cur
}

///|
fn gsub_apply_lookup_depth(
  g : GsubData,
  lookup_off : Int,
  input : Array[(Int, Int)],
  depth : Int,
) -> Array[(Int, Int)] {
  if depth > 8 {
    return input
  }
  let b = g.bytes
  let typ = gsub_u16(b, lookup_off)
  if typ == 4 {
    return gsub_apply_lookup(g, lookup_off, input)
  }
  if typ == 1 {
    let out : Array[(Int, Int)] = []
    for pair in input {
      let (gid, comps) = pair
      out.push((gsub_apply_single_lookup(g, lookup_off, gid), comps))
    }
    return out
  }
  if typ == 5 || typ == 6 {
    let sub_count = gsub_u16(b, lookup_off + 4)
    let mut cur = input
    for si = 0; si < sub_count; si = si + 1 {
      let sub = lookup_off + gsub_u16(b, lookup_off + 6 + si * 2)
      match gsub_u16(b, sub) {
        3 =>
          if typ == 5 {
            cur = gsub_apply_context3(g, lookup_off, sub, cur, depth)
          } else {
            cur = gsub_apply_chain3(g, lookup_off, sub, cur, depth)
          }
        _ => ()
      }
    }
    return cur
  }
  input
}

///|
fn gsub_apply_lookup_any(
  g : GsubData,
  lookup_off : Int,
  input : Array[(Int, Int)],
) -> Array[(Int, Int)] {
  gsub_apply_lookup_depth(g, lookup_off, input, 0)
}

///|
fn GsubData::apply_feature(
  self : GsubData,
  input : Array[(Int, Int)],
  tag : String,
) -> Array[(Int, Int)] {
  let lookups = match self.deva_features.get(tag) {
    Some(v) => v
    None => return input
  }
  let b = self.bytes
  let lookup_list = self.base + gsub_u16(b, self.base + 8)
  let mut cur = input
  for idx in lookups {
    let off = lookup_list + gsub_u16(b, lookup_list + 2 + idx * 2)
    if off + 6 > b.length() {
      continue
    }
    cur = gsub_apply_lookup_any(self, off, cur)
  }
  cur
}

///|
fn GsubData::apply_features(
  self : GsubData,
  gids : Array[Int],
  tags : Array[String],
) -> Array[(Int, Int)] {
  let mut cur : Array[(Int, Int)] = []
  for gid in gids {
    cur.push((gid, 1))
  }
  for tag in tags {
    cur = self.apply_feature(cur, tag)
  }
  cur
}

///|
pub fn FontFace::india_shape(
  self : FontFace,
  gids : Array[Int],
  tags : Array[String],
) -> Array[(Int, Int)] {
  match self.gsub {
    Some(g) => g.apply_features(gids, tags)
    None => {
      let out : Array[(Int, Int)] = []
      for gid in gids {
        out.push((gid, 1))
      }
      out
    }
  }
}

///|
fn GsubData::ligate_with(
  self : GsubData,
  gids : Array[Int],
  lookups : Array[Int],
) -> Array[(Int, Int)] {
  let b = self.bytes
  let lookup_list = self.base + gsub_u16(b, self.base + 8)
  let mut cur : Array[(Int, Int)] = []
  for gid in gids {
    cur.push((gid, 1))
  }
  for idx in lookups {
    let off = lookup_list + gsub_u16(b, lookup_list + 2 + idx * 2)
    if off + 6 > b.length() {
      continue
    }
    cur = gsub_apply_lookup(self, off, cur)
  }
  cur
}

///|
fn GsubData::ligate(self : GsubData, gids : Array[Int]) -> Array[(Int, Int)] {
  self.ligate_with(gids, self.liga_lookups)
}

///|
pub fn FontFace::rlig_ligate(
  self : FontFace,
  gids : Array[Int],
) -> Array[(Int, Int)] {
  match self.gsub {
    Some(g) => g.ligate_with(gids, g.arab_rlig)
    None => {
      let out : Array[(Int, Int)] = []
      for gid in gids {
        out.push((gid, 1))
      }
      out
    }
  }
}

///|
pub fn FontFace::has_liga(self : FontFace) -> Bool {
  match self.gsub {
    Some(g) => g.liga_lookups.length() > 0
    None => false
  }
}

///|
// Apply Latin `liga` lookups. Each result carries how many source glyphs it
// consumed so shaping can keep cluster/source ranges.
pub fn FontFace::ligate_glyphs(
  self : FontFace,
  gids : Array[Int],
) -> Array[(Int, Int)] {
  match self.gsub {
    Some(g) => g.ligate(gids)
    None => {
      let out : Array[(Int, Int)] = []
      for gid in gids {
        out.push((gid, 1))
      }
      out
    }
  }
}

///|
pub fn FontFace::glyph_id(self : FontFace, cp : Int) -> Int {
  match self.ttf {
    Some(t) => ttf_glyph_id(t, cp)
    None => 0
  }
}

///|
pub fn FontFace::glyph_advance(self : FontFace, gid : Int, size_px : Float) -> Float {
  match self.ttf {
    Some(t) => {
      let adv = ttf_advance_units(t, gid)
      Float::from_double(adv.to_double() * size_px.to_double() / t.units_per_em.to_double())
    }
    None => size_px * (0.62 : Float)
  }
}
