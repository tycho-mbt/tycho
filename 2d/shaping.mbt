// Minimal shaping subset:
// - Latin typographic ligatures mapped to the Unicode presentation forms
//   (U+FB00..FB06) when the face has them.
// - Arabic joining forms mapped to Arabic Presentation Forms-B based on
//   neighbouring joining types, also only when the face has the glyph.
//
// This keeps the default pipeline pure MoonBit and 1:1 except for Latin
// ligatures, which carry a source range so caret/selection mapping stays
// monotonic. Full GSUB/GPOS and Indic clusters remain future work.

///|
priv struct ShapedChar {
  cp : Int
  source_start : Int
  source_end : Int
  glyph_id : Int
  is_newline : Bool
  is_space : Bool
}

///|
fn shaping_is_space(cp : Int) -> Bool {
  cp == 32 || cp == 9
}

///|
fn shaping_is_transparent(cp : Int) -> Bool {
  (cp >= 0x064B && cp <= 0x065F) ||
  cp == 0x0670 ||
  (cp >= 0x06D6 && cp <= 0x06ED)
}

///|
// 0 = non-Arabic, 1 = right-joining, 2 = dual-joining, 3 = transparent.
fn arabic_joining_type(cp : Int) -> Int {
  if shaping_is_transparent(cp) {
    return 3
  }
  match cp {
    0x0621 => 0
    0x0622 | 0x0623 | 0x0624 | 0x0625 | 0x0627 | 0x0629 | 0x062F |
    0x0630 | 0x0631 | 0x0632 | 0x0648 | 0x0649 => 1
    0x0626 | 0x0628 | 0x062A | 0x062B | 0x062C | 0x062D | 0x062E |
    0x0633 | 0x0634 | 0x0635 | 0x0636 | 0x0637 | 0x0638 | 0x0639 |
    0x063A | 0x0641 | 0x0642 | 0x0643 | 0x0644 | 0x0645 | 0x0646 |
    0x0647 | 0x064A => 2
    _ => 0
  }
}

///|
fn dual_form(base : Int, form : Int) -> Int? {
  match form {
    0 => Some(base)
    1 => Some(base + 1)
    2 => Some(base + 2)
    3 => Some(base + 3)
    _ => None
  }
}

///|
fn right_form(base : Int, form : Int) -> Int? {
  match form {
    0 => Some(base)
    1 => Some(base + 1)
    _ => None
  }
}

///|
fn arabic_presentation(cp : Int, form : Int) -> Int? {
  match cp {
    0x0621 => if form == 0 { Some(0xFE80) } else { None }
    0x0622 => right_form(0xFE81, form)
    0x0623 => right_form(0xFE83, form)
    0x0624 => right_form(0xFE85, form)
    0x0625 => right_form(0xFE87, form)
    0x0626 => dual_form(0xFE89, form)
    0x0627 => right_form(0xFE8D, form)
    0x0628 => dual_form(0xFE8F, form)
    0x0629 => right_form(0xFE93, form)
    0x062A => dual_form(0xFE95, form)
    0x062B => dual_form(0xFE99, form)
    0x062C => dual_form(0xFE9D, form)
    0x062D => dual_form(0xFEA1, form)
    0x062E => dual_form(0xFEA5, form)
    0x062F => right_form(0xFEA9, form)
    0x0630 => right_form(0xFEAB, form)
    0x0631 => right_form(0xFEAD, form)
    0x0632 => right_form(0xFEAF, form)
    0x0633 => dual_form(0xFEB1, form)
    0x0634 => dual_form(0xFEB5, form)
    0x0635 => dual_form(0xFEB9, form)
    0x0636 => dual_form(0xFEBD, form)
    0x0637 => dual_form(0xFEC1, form)
    0x0638 => dual_form(0xFEC5, form)
    0x0639 => dual_form(0xFEC9, form)
    0x063A => dual_form(0xFECD, form)
    0x0641 => dual_form(0xFED1, form)
    0x0642 => dual_form(0xFED5, form)
    0x0643 => dual_form(0xFED9, form)
    0x0644 => dual_form(0xFEDD, form)
    0x0645 => dual_form(0xFEE1, form)
    0x0646 => dual_form(0xFEE5, form)
    0x0647 => dual_form(0xFEE9, form)
    0x0648 => right_form(0xFEED, form)
    0x0649 => right_form(0xFEEF, form)
    0x064A => dual_form(0xFEF1, form)
    _ => None
  }
}

///|
fn shape_latin_ligature(
  font : FontFace,
  cps : Array[Int],
  i : Int,
) -> (Int, Int)? {
  let n = cps.length()
  if i + 2 < n &&
    cps[i] == 102 &&
    cps[i + 1] == 102 &&
    cps[i + 2] == 105 &&
    font.has_glyph(0xFB03) {
    return Some((0xFB03, 3))
  }
  if i + 2 < n &&
    cps[i] == 102 &&
    cps[i + 1] == 102 &&
    cps[i + 2] == 108 &&
    font.has_glyph(0xFB04) {
    return Some((0xFB04, 3))
  }
  if i + 1 < n && cps[i] == 102 && cps[i + 1] == 102 && font.has_glyph(0xFB00) {
    return Some((0xFB00, 2))
  }
  if i + 1 < n && cps[i] == 102 && cps[i + 1] == 105 && font.has_glyph(0xFB01) {
    return Some((0xFB01, 2))
  }
  if i + 1 < n && cps[i] == 102 && cps[i + 1] == 108 && font.has_glyph(0xFB02) {
    return Some((0xFB02, 2))
  }
  if i + 1 < n && cps[i] == 115 && cps[i + 1] == 116 && font.has_glyph(0xFB06) {
    return Some((0xFB06, 2))
  }
  None
}

///|
fn shape_run(font : FontFace, text : String) -> Array[ShapedChar] {
  let cps : Array[Int] = []
  for ch in text {
    cps.push(ch.to_int())
  }
  let n = cps.length()
  let types = Array::make(n, 0)
  for i = 0; i < n; i = i + 1 {
    types[i] = arabic_joining_type(cps[i])
  }
  let joins_prev = Array::make(n, false)
  let joins_next = Array::make(n, false)
  for i = 0; i < n; i = i + 1 {
    if types[i] == 1 || types[i] == 2 {
      let mut p = i - 1
      while p >= 0 && types[p] == 3 {
        p = p - 1
      }
      if p >= 0 && types[p] == 2 {
        joins_prev[i] = true
      }
      if types[i] == 2 {
        let mut q = i + 1
        while q < n && types[q] == 3 {
          q = q + 1
        }
        if q < n && (types[q] == 1 || types[q] == 2) {
          joins_next[i] = true
        }
      }
    }
  }

  let out : Array[ShapedChar] = []
  let mut i = 0
  while i < n {
    let cp = cps[i]
    let is_nl = cp == 10
    if is_nl || shaping_is_space(cp) {
      out.push({
        cp,
        source_start: i,
        source_end: i + 1,
        glyph_id: 0,
        is_newline: is_nl,
        is_space: shaping_is_space(cp),
      })
      i = i + 1
      continue
    }
    // Real GSUB `liga` for contiguous ASCII segments.
    if types[i] == 0 && cp > 32 && cp < 127 && font.has_liga() {
      let mut j = i
      while j < n && types[j] == 0 && cps[j] > 32 && cps[j] < 127 {
        j = j + 1
      }
      let gids : Array[Int] = []
      for k = i; k < j; k = k + 1 {
        gids.push(font.glyph_id(cps[k]))
      }
      let ligated = font.ligate_glyphs(gids)
      let mut has_multi = false
      for pair in ligated {
        let (_gid, comps) = pair
        if comps > 1 {
          has_multi = true
        }
      }
      if has_multi {
        let mut src = i
        for pair in ligated {
          let (gid, comps) = pair
          let mut ce = src + comps
          if ce > j {
            ce = j
          }
          if ce <= src {
            ce = src + 1
          }
          out.push({
            cp: cps[src],
            source_start: src,
            source_end: ce,
            glyph_id: gid,
            is_newline: false,
            is_space: false,
          })
          src = ce
        }
        i = j
        continue
      }
    }
    if types[i] == 0 {
      match shape_latin_ligature(font, cps, i) {
        Some((lig, len)) => {
          out.push({
            cp: lig,
            source_start: i,
            source_end: i + len,
            glyph_id: font.glyph_id(lig),
            is_newline: false,
            is_space: false,
          })
          i = i + len
          continue
        }
        None => ()
      }
    }
    let mut shaped_cp = cp
    if types[i] == 1 || types[i] == 2 {
      let form = if joins_prev[i] && joins_next[i] {
        3
      } else if joins_prev[i] {
        1
      } else if joins_next[i] {
        2
      } else {
        0
      }
      match arabic_presentation(cp, form) {
        Some(pres) => if font.has_glyph(pres) { shaped_cp = pres }
        None => ()
      }
    }
    out.push({
      cp: shaped_cp,
      source_start: i,
      source_end: i + 1,
      glyph_id: font.glyph_id(shaped_cp),
      is_newline: false,
      is_space: false,
    })
    i = i + 1
  }
  out
}
