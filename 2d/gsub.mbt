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
fn GsubData::parse(bytes : Bytes, base : Int) -> GsubData? {
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
fn gsub_apply_lookup_any(
  g : GsubData,
  lookup_off : Int,
  input : Array[(Int, Int)],
) -> Array[(Int, Int)] {
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
  input
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
