// Rich-text Paragraph layout engine (wrapping, alignment, ellipsis, caret & selection boxes).

///|
#derive(Eq, Debug)
pub(all) enum TextAlign {
  Left
  Center
  Right
  Justify
}

///|
pub(all) struct TextStyle {
  font : FontFace
  font_size : Float
  color : Color
  letter_spacing : Float
  underline : Bool
  bold : Bool
  italic : Bool
  fallback : FontFallbackChain?
  variations : Array[(String, Float)]
}

///|
pub fn TextStyle::new(
  font? : FontFace = FontFace::builtin(),
  font_size? : Float = (16.0 : Float),
  color? : Color = Color::white(),
  letter_spacing? : Float = (0.0 : Float),
  underline? : Bool = false,
  bold? : Bool = false,
  italic? : Bool = false,
  fallback? : FontFallbackChain? = None,
  variations? : Array[(String, Float)] = [],
) -> TextStyle {
  {
    font,
    font_size,
    color,
    letter_spacing,
    underline,
    bold,
    italic,
    fallback,
    variations,
  }
}

///|
fn variation_value(style : TextStyle, tag : String) -> Float? {
  for pair in style.variations {
    let (t, v) = pair
    if t == tag {
      return Some(v)
    }
  }
  None
}

///|
fn default_axis_value(style : TextStyle, tag : String, fallback : Float) -> Float {
  for axis in style.font.variation_axes() {
    if axis.tag == tag {
      return axis.default_value
    }
  }
  fallback
}

///|
fn resolve_bold(style : TextStyle) -> Bool {
  if style.bold {
    return true
  }
  match variation_value(style, "wght") {
    Some(w) => {
      let base = default_axis_value(style, "wght", (400.0 : Float))
      w >= base + (100.0 : Float)
    }
    None => false
  }
}

///|
fn resolve_italic(style : TextStyle) -> Bool {
  if style.italic {
    return true
  }
  match variation_value(style, "ital") {
    Some(v) => v >= (0.5 : Float)
    None =>
      match variation_value(style, "slnt") {
        Some(v) => @tmath.abs_f(v) > (0.01 : Float)
        None => false
      }
  }
}

///|
fn style_face(style : TextStyle, cp : Int) -> FontFace {
  match style.fallback {
    Some(chain) => chain.face_for(cp)
    None => style.font
  }
}

///|
pub(all) struct TextSpan {
  text : String
  style : TextStyle
  image : Image2D?
  image_w : Float
  image_h : Float
}

///|
pub fn TextSpan::new(text : String, style? : TextStyle = TextStyle::new()) -> TextSpan {
  { text, style, image: None, image_w: (0.0 : Float), image_h: (0.0 : Float) }
}

///|
pub fn TextSpan::inline_image(
  image : Image2D,
  width : Float,
  height : Float,
  style? : TextStyle = TextStyle::new(),
) -> TextSpan {
  { text: "", style, image: Some(image), image_w: width, image_h: height }
}

///|
pub(all) struct ParagraphStyle {
  align : TextAlign
  max_lines : Int
  ellipsis : String
  line_height_scale : Float
}

///|
pub fn ParagraphStyle::new(
  align? : TextAlign = TextAlign::Left,
  max_lines? : Int = 0,
  ellipsis? : String = "",
  line_height_scale? : Float = (1.15 : Float),
) -> ParagraphStyle {
  { align, max_lines, ellipsis, line_height_scale }
}

///|
#derive(Eq, Debug)
pub(all) enum TextAffinity {
  Upstream
  Downstream
}

///|
#derive(Eq, Debug)
pub(all) struct TextPosition {
  offset : Int
  line : Int
  affinity : TextAffinity
}

///|
pub fn TextPosition::new(
  offset : Int,
  line : Int,
  affinity? : TextAffinity = TextAffinity::Downstream,
) -> TextPosition {
  { offset, line, affinity }
}

///|
pub(all) struct LineMetrics {
  start_index : Int
  end_index : Int
  y : Float
  height : Float
  baseline : Float
  width : Float
}

///|
pub(all) struct PlacedGlyph {
  codepoint : Int
  // Resolved glyph id (0 = builtin rasterizer / codepoint path).
  glyph_id : Int
  font : FontFace
  font_size : Float
  x : Float
  baseline_y : Float
  advance : Float
  color : Color
  char_index : Int
  bold : Bool
  italic : Bool
  image : Image2D?
  image_w : Float
  image_h : Float
}

///|
priv struct LayoutChar {
  cp : Int
  glyph_id : Int
  style : TextStyle
  font : FontFace
  bold : Bool
  italic : Bool
  image : Image2D?
  image_w : Float
  image_h : Float
  mut advance : Float
  char_index : Int
  source_start : Int
  source_end : Int
  is_newline : Bool
  is_space : Bool
}

///|
fn is_cjk(cp : Int) -> Bool {
  (cp >= 0x4E00 && cp <= 0x9FFF) ||
  (cp >= 0x3040 && cp <= 0x30FF) ||
  (cp >= 0xAC00 && cp <= 0xD7AF)
}

///|
// Kinsoku: closing punctuation may not start a line.
fn is_no_start(cp : Int) -> Bool {
  match cp {
    0x3001 | 0x3002 | 0xFF0C | 0xFF1B | 0xFF1A | 0xFF01 | 0xFF1F |
    0xFF09 | 0x300B | 0x3009 | 0x300D | 0x3011 | 0x3015 | 0x2026 |
    0x201D | 0x2019 => true
    _ => false
  }
}

///|
// Kinsoku: opening punctuation may not end a line.
fn is_no_end(cp : Int) -> Bool {
  match cp {
    0xFF08 | 0x300A | 0x3008 | 0x300C | 0x3010 | 0x3014 | 0x201C |
    0x2018 => true
    _ => false
  }
}

///|
pub struct Paragraph {
  priv spans : Array[TextSpan]
  priv pstyle : ParagraphStyle
  priv mut laid_out : Bool
  priv mut layout_max_width : Float
  priv mut total_width : Float
  priv mut total_height : Float
  priv lines : Array[LineMetrics]
  priv glyphs : Array[PlacedGlyph]
  priv char_x : Array[Float]
  priv char_line : Array[Int]
  priv underlines : Array[(Float, Float, Float, Float, Color)]
}

///|
pub fn ParagraphBuilder::new(
  style? : ParagraphStyle = ParagraphStyle::new(),
) -> ParagraphBuilder {
  { pstyle: style, spans: [] }
}

///|
pub struct ParagraphBuilder {
  priv pstyle : ParagraphStyle
  priv spans : Array[TextSpan]
}

///|
pub fn ParagraphBuilder::add_text(
  self : ParagraphBuilder,
  text : String,
  style? : TextStyle = TextStyle::new(),
) -> ParagraphBuilder {
  self.spans.push({
    text,
    style,
    image: None,
    image_w: (0.0 : Float),
    image_h: (0.0 : Float),
  })
  self
}

///|
pub fn ParagraphBuilder::add_span(
  self : ParagraphBuilder,
  span : TextSpan,
) -> ParagraphBuilder {
  self.spans.push(span)
  self
}

///|
pub fn ParagraphBuilder::add_inline_image(
  self : ParagraphBuilder,
  image : Image2D,
  width : Float,
  height : Float,
  style? : TextStyle = TextStyle::new(),
) -> ParagraphBuilder {
  self.spans.push(TextSpan::inline_image(image, width, height, style~))
  self
}

///|
pub fn ParagraphBuilder::build(self : ParagraphBuilder) -> Paragraph {
  {
    spans: self.spans,
    pstyle: self.pstyle,
    laid_out: false,
    layout_max_width: (-1.0 : Float),
    total_width: (0.0 : Float),
    total_height: (0.0 : Float),
    lines: [],
    glyphs: [],
    char_x: [],
    char_line: [],
    underlines: [],
  }
}

///|
pub fn Paragraph::layout(self : Paragraph, max_width : Float) -> Unit {
  let mw = if max_width <= (0.0 : Float) { (1.0e9 : Float) } else { max_width }
  if self.laid_out && @tmath.abs_f(self.layout_max_width - mw) < (0.01 : Float) {
    return
  }
  self.laid_out = true
  self.layout_max_width = mw
  self.lines.clear()
  self.glyphs.clear()
  self.char_x.clear()
  self.char_line.clear()
  self.underlines.clear()

  let chars : Array[LayoutChar] = []
  for sp in self.spans {
    // Shape with the face that owns the first strong character, not blindly
    // the primary face (Devanagari/Arabic live in fallback faces).
    let mut first_cp = -1
    for ch in sp.text {
      let cp = ch.to_int()
      if cp > 32 {
        first_cp = cp
        break
      }
    }
    let run_font = if first_cp >= 0 {
      style_face(sp.style, first_cp)
    } else {
      sp.style.font
    }
    let bold = resolve_bold(sp.style)
    let italic = resolve_italic(sp.style)
    match sp.image {
      Some(img) => {
        let idx = self.char_x.length()
        chars.push({
          cp: -1,
          glyph_id: 0,
          style: sp.style,
          font: sp.style.font,
          bold,
          italic,
          image: Some(img),
          image_w: sp.image_w,
          image_h: sp.image_h,
          advance: sp.image_w,
          char_index: idx,
          source_start: idx,
          source_end: idx + 1,
          is_newline: false,
          is_space: false,
        })
        self.char_x.push((0.0 : Float))
        self.char_line.push(0)
        continue
      }
      None => ()
    }
    for sc in shape_run(run_font, sp.text) {
      let cp = sc.cp
      let is_nl = sc.is_newline
      let is_sp = sc.is_space
      // Shaped presentation forms/ligatures stay on the primary face because
      // shape_run only substitutes glyphs the face has; emoji still goes
      // through the fallback chain (color faces are preferred there).
      let face = style_face(sp.style, cp)
      let adv = if is_nl {
        (0.0 : Float)
      } else if cp == 9 {
        // Tab: four spaces. A position-dependent tab stop needs line-break
        // feedback; this keeps the char advance precomputable.
        face.advance_width(32, sp.style.font_size) * (4.0 : Float) +
        sp.style.letter_spacing
      } else if cp == 0x00AD {
        // Soft hyphen is zero-width unless it becomes a break opportunity.
        (0.0 : Float)
      } else if sc.glyph_id > 0 {
        face.glyph_advance(sc.glyph_id, sp.style.font_size) +
        sp.style.letter_spacing
      } else {
        face.advance_width(cp, sp.style.font_size) + sp.style.letter_spacing
      }
      chars.push({
        cp,
        glyph_id: sc.glyph_id,
        style: sp.style,
        font: face,
        bold,
        italic,
        image: None,
        image_w: (0.0 : Float),
        image_h: (0.0 : Float),
        advance: adv,
        char_index: sc.source_start,
        source_start: sc.source_start,
        source_end: sc.source_end,
        is_newline: is_nl,
        is_space: is_sp,
      })
      while self.char_x.length() < sc.source_end {
        self.char_x.push((0.0 : Float))
        self.char_line.push(0)
      }
    }
  }

  // Legacy kern pairs, applied only within the same face and size.
  for i = 0; i + 1 < chars.length(); i = i + 1 {
    let a = chars[i]
    let b = chars[i + 1]
    if !a.is_newline &&
      !b.is_newline &&
      a.cp != 9 &&
      b.cp != 9 &&
      a.font.id() == b.font.id() &&
      a.style.font_size == b.style.font_size {
      let k = if a.glyph_id > 0 && b.glyph_id > 0 {
        let gp = a.font.gpos_kern(a.glyph_id, b.glyph_id, a.style.font_size)
        if gp != (0.0 : Float) {
          gp
        } else {
          a.font.kern_gid(a.glyph_id, b.glyph_id, a.style.font_size)
        }
      } else {
        a.font.kern(a.cp, b.cp, a.style.font_size)
      }
      if k != (0.0 : Float) {
        chars[i].advance = chars[i].advance + k
      }
    }
  }

  let raw_lines : Array[(Int, Int)] = []
  let mut line_start = 0
  let mut cur_w = (0.0 : Float)
  let mut last_break = -1
  let mut break_after = false
  let n = chars.length()
  let mut i = 0
  while i < n {
    let c = chars[i]
    if c.is_newline {
      raw_lines.push((line_start, i))
      line_start = i + 1
      cur_w = (0.0 : Float)
      last_break = -1
      break_after = false
      i = i + 1
      continue
    }
    let prev_cp = if i > 0 { chars[i - 1].cp } else { -1 }
    if c.is_space {
      last_break = i
      break_after = true
    } else if c.cp == 45 {
      // Break after a visible hyphen.
      last_break = i
      break_after = true
    } else if c.cp == 0x00AD {
      // Break before a soft hyphen; it stays invisible.
      last_break = i
      break_after = false
    } else if is_cjk(c.cp) {
      if !is_no_start(c.cp) && !is_no_end(prev_cp) {
        last_break = i
        break_after = false
      }
    }
    if cur_w + c.advance > mw && i > line_start {
      if last_break > line_start {
        let brk = last_break
        let end = if break_after { brk + 1 } else { brk }
        if end > line_start {
          raw_lines.push((line_start, end))
          line_start = end
          cur_w = (0.0 : Float)
          last_break = -1
          break_after = false
          i = line_start
          continue
        }
      }
      raw_lines.push((line_start, i))
      line_start = i
      cur_w = (0.0 : Float)
      last_break = -1
      break_after = false
      continue
    }
    cur_w = cur_w + c.advance
    i = i + 1
  }
  if line_start < n || raw_lines.length() == 0 {
    raw_lines.push((line_start, n))
  }

  let limit = if self.pstyle.max_lines > 0 &&
    raw_lines.length() > self.pstyle.max_lines {
    self.pstyle.max_lines
  } else {
    raw_lines.length()
  }
  let truncated = self.pstyle.max_lines > 0 &&
    raw_lines.length() > self.pstyle.max_lines

  let mut cur_y = (0.0 : Float)
  let mut max_w = (0.0 : Float)
  for li = 0; li < limit; li = li + 1 {
    let (rs, re) = raw_lines[li]
    let mut line_w = (0.0 : Float)
    let mut max_asc = (0.0 : Float)
    let mut max_h = (0.0 : Float)
    let ell = if truncated && li == limit - 1 && self.pstyle.ellipsis != "" {
      self.pstyle.ellipsis
    } else {
      ""
    }
    let mut end_idx = re
    if rs == re {
      let fallback_st = if self.spans.length() > 0 {
        self.spans[0].style
      } else {
        TextStyle::new()
      }
      let (asc, _desc, lh) = fallback_st.font.metrics(fallback_st.font_size)
      max_asc = asc
      max_h = lh * self.pstyle.line_height_scale
    } else {
      for k = rs; k < re; k = k + 1 {
        let ch = chars[k]
        match ch.image {
          Some(_) => {
            if ch.image_h > max_asc {
              max_asc = ch.image_h
            }
            let sh = ch.image_h * (1.1 : Float)
            if sh > max_h {
              max_h = sh
            }
          }
          None => {
            let (asc, _desc, lh) = ch.font.metrics(ch.style.font_size)
            if asc > max_asc { max_asc = asc }
            let sh = lh * self.pstyle.line_height_scale
            if sh > max_h { max_h = sh }
          }
        }
        line_w = line_w + ch.advance
      }
      if ell != "" {
        let last_st = chars[re - 1].style
        let mut ell_w = (0.0 : Float)
        for ech in ell {
          ell_w = ell_w + style_face(last_st, ech.to_int()).advance_width(
            ech.to_int(),
            last_st.font_size,
          )
        }
        while end_idx > rs && line_w + ell_w > mw {
          end_idx = end_idx - 1
          line_w = line_w - chars[end_idx].advance
        }
        line_w = line_w + ell_w
      }
    }

    let is_justify = self.pstyle.align == TextAlign::Justify &&
      li < limit - 1 &&
      mw < (1.0e8 : Float) &&
      end_idx > rs
    let line_extra = if is_justify {
      @tmath.max_f((0.0 : Float), mw - line_w)
    } else {
      (0.0 : Float)
    }
    let mut space_gaps = 0
    for k = rs; k < end_idx; k = k + 1 {
      if chars[k].is_space {
        space_gaps = space_gaps + 1
      }
    }
    let gap_count = if space_gaps > 0 {
      space_gaps
    } else if end_idx > rs {
      end_idx - rs - 1
    } else {
      0
    }
    let gap_extra = if gap_count > 0 {
      line_extra / Float::from_int(gap_count)
    } else {
      (0.0 : Float)
    }
    // UAX #9 subset: weak/neutral resolution + implicit levels + reorder.
    let order = bidi_visual_order(chars, rs, end_idx)
    let x_start = match self.pstyle.align {
      TextAlign::Left => (0.0 : Float)
      TextAlign::Justify => (0.0 : Float)
      TextAlign::Center =>
        if mw < (1.0e8 : Float) { @tmath.max_f((0.0 : Float), (mw - line_w) * (0.5 : Float)) } else { (0.0 : Float) }
      TextAlign::Right =>
        if mw < (1.0e8 : Float) { @tmath.max_f((0.0 : Float), mw - line_w) } else { (0.0 : Float) }
    }
    let baseline = cur_y + max_asc
    let mut cx = x_start
    for oi2 = 0; oi2 < order.length(); oi2 = oi2 + 1 {
      let k = order[oi2]
      let ch = chars[k]
      for si = ch.source_start; si < ch.source_end; si = si + 1 {
        self.char_x[si] = cx
        self.char_line[si] = li
      }
      let add_gap = is_justify &&
        oi2 < order.length() - 1 &&
        (if space_gaps > 0 { ch.is_space } else { true })
      match ch.image {
        Some(img) =>
          self.glyphs.push({
            codepoint: -1,
            glyph_id: 0,
            font: ch.font,
            font_size: ch.style.font_size,
            x: cx,
            baseline_y: baseline,
            advance: ch.advance,
            color: ch.style.color,
            char_index: ch.char_index,
            bold: ch.bold,
            italic: ch.italic,
            image: Some(img),
            image_w: ch.image_w,
            image_h: ch.image_h,
          })
        None =>
          if !ch.is_space && !ch.is_newline && ch.cp != 0x00AD {
            self.glyphs.push({
              codepoint: ch.cp,
              glyph_id: ch.glyph_id,
              font: ch.font,
              font_size: ch.style.font_size,
              x: cx,
              baseline_y: baseline,
              advance: ch.advance,
              color: ch.style.color,
              char_index: ch.char_index,
              bold: ch.bold,
              italic: ch.italic,
              image: None,
              image_w: (0.0 : Float),
              image_h: (0.0 : Float),
            })
          }
      }
      if ch.style.underline {
        self.underlines.push((
          cx,
          baseline + (2.0 : Float),
          ch.advance + (if add_gap { gap_extra } else { (0.0 : Float) }),
          @tmath.max_f((1.0 : Float), ch.style.font_size * (0.07 : Float)),
          ch.style.color,
        ))
      }
      cx = cx + ch.advance + (if add_gap { gap_extra } else { (0.0 : Float) })
    }
    if ell != "" && end_idx > rs {
      let est = chars[end_idx - 1].style
      let last_src = chars[end_idx - 1].source_start
      let ebold = resolve_bold(est)
      let eitalic = resolve_italic(est)
      for ech in ell {
        let ecp = ech.to_int()
        let eadv = est.font.advance_width(ecp, est.font_size)
        self.glyphs.push({
          codepoint: ecp,
          glyph_id: est.font.glyph_id(ecp),
          font: est.font,
          font_size: est.font_size,
          x: cx,
          baseline_y: baseline,
          advance: eadv,
          color: est.color,
          char_index: last_src,
          bold: ebold,
          italic: eitalic,
          image: None,
          image_w: (0.0 : Float),
          image_h: (0.0 : Float),
        })
        cx = cx + eadv
      }
    }
    let reported_w = if is_justify { mw } else { line_w }
    if reported_w > max_w { max_w = reported_w }
    let src_start = if rs < chars.length() { chars[rs].source_start } else { rs }
    let src_end = if end_idx > rs {
      chars[end_idx - 1].source_end
    } else {
      src_start
    }
    self.lines.push({
      start_index: src_start,
      end_index: src_end,
      y: cur_y,
      height: max_h,
      baseline,
      width: reported_w,
    })
    cur_y = cur_y + max_h
  }
  self.total_width = max_w
  self.total_height = cur_y
}

///|
pub fn Paragraph::width(self : Paragraph) -> Float {
  self.total_width
}

///|
pub fn Paragraph::height(self : Paragraph) -> Float {
  self.total_height
}

///|
pub fn Paragraph::line_count(self : Paragraph) -> Int {
  self.lines.length()
}

///|
pub fn Paragraph::line_metrics(self : Paragraph) -> Array[LineMetrics] {
  self.lines
}

///|
pub fn Paragraph::placed_glyphs(self : Paragraph) -> Array[PlacedGlyph] {
  self.glyphs
}

///|
pub fn Paragraph::underline_rects(
  self : Paragraph,
) -> Array[(Float, Float, Float, Float, Color)] {
  self.underlines
}

///|
pub fn Paragraph::get_position_for_offset(
  self : Paragraph,
  pt : Point,
) -> TextPosition {
  if self.lines.length() == 0 {
    return { offset: 0, line: 0, affinity: TextAffinity::Downstream }
  }
  let mut target_line = self.lines.length() - 1
  for li = 0; li < self.lines.length(); li = li + 1 {
    let lm = self.lines[li]
    if pt.y < lm.y + lm.height || li == self.lines.length() - 1 {
      target_line = li
      break
    }
  }
  let lm = self.lines[target_line]
  let mut best_off = lm.end_index
  let mut best_dist = (1.0e9 : Float)
  for idx = lm.start_index; idx <= lm.end_index; idx = idx + 1 {
    let gx = if idx < self.char_x.length() && idx < lm.end_index {
      self.char_x[idx]
    } else {
      lm.width
    }
    let d = @tmath.abs_f(pt.x - gx)
    if d < best_dist {
      best_dist = d
      best_off = idx
    }
  }
  { offset: best_off, line: target_line, affinity: TextAffinity::Downstream }
}

///|
pub fn Paragraph::get_caret_rect(self : Paragraph, pos : TextPosition) -> Rect {
  if self.lines.length() == 0 {
    return Rect::new((0.0 : Float), (0.0 : Float), (2.0 : Float), (18.0 : Float))
  }
  let li = if pos.line >= 0 && pos.line < self.lines.length() {
    pos.line
  } else {
    let mut found = 0
    for k = 0; k < self.lines.length(); k = k + 1 {
      if pos.offset >= self.lines[k].start_index && pos.offset <= self.lines[k].end_index {
        found = k
        break
      }
    }
    found
  }
  let lm = self.lines[li]
  let cx = if pos.offset >= lm.end_index {
    if pos.affinity == TextAffinity::Upstream &&
      lm.end_index > lm.start_index &&
      lm.end_index - 1 < self.char_x.length() {
      self.char_x[lm.end_index - 1]
    } else {
      lm.width
    }
  } else if pos.offset >= 0 && pos.offset < self.char_x.length() {
    self.char_x[pos.offset]
  } else {
    (0.0 : Float)
  }
  Rect::new(cx, lm.y, (2.0 : Float), lm.height)
}

///|
pub fn Paragraph::get_boxes_for_range(
  self : Paragraph,
  start : Int,
  end : Int,
) -> Array[Rect] {
  let out : Array[Rect] = []
  if end <= start {
    return out
  }
  for lm in self.lines {
    let s = if start > lm.start_index { start } else { lm.start_index }
    let e = if end < lm.end_index { end } else { lm.end_index }
    if e > s {
      let x0 = if s < self.char_x.length() { self.char_x[s] } else { (0.0 : Float) }
      let x1 = if e < lm.end_index && e < self.char_x.length() {
        self.char_x[e]
      } else {
        lm.width
      }
      out.push(Rect::from_ltrb(x0, lm.y, x1, lm.y + lm.height))
    }
  }
  out
}
