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
  fallback : FontFallbackChain?
}

///|
pub fn TextStyle::new(
  font? : FontFace = FontFace::builtin(),
  font_size? : Float = (16.0 : Float),
  color? : Color = Color::white(),
  letter_spacing? : Float = (0.0 : Float),
  underline? : Bool = false,
  fallback? : FontFallbackChain? = None,
) -> TextStyle {
  { font, font_size, color, letter_spacing, underline, fallback }
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
}

///|
pub fn TextSpan::new(text : String, style? : TextStyle = TextStyle::new()) -> TextSpan {
  { text, style }
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
pub(all) struct TextPosition {
  offset : Int
  line : Int
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
  font : FontFace
  font_size : Float
  x : Float
  baseline_y : Float
  advance : Float
  color : Color
  char_index : Int
}

///|
priv struct LayoutChar {
  cp : Int
  style : TextStyle
  font : FontFace
  mut advance : Float
  char_index : Int
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
// Strong RTL ranges for the bidi subset (Hebrew + Arabic blocks).
fn is_rtl(cp : Int) -> Bool {
  (cp >= 0x0590 && cp <= 0x05FF) ||
  (cp >= 0x0600 && cp <= 0x06FF) ||
  (cp >= 0x0700 && cp <= 0x074F) ||
  (cp >= 0x0750 && cp <= 0x077F) ||
  (cp >= 0x08A0 && cp <= 0x08FF) ||
  (cp >= 0xFB1D && cp <= 0xFB4F) ||
  (cp >= 0xFB50 && cp <= 0xFDFF) ||
  (cp >= 0xFE70 && cp <= 0xFEFF)
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
  self.spans.push({ text, style })
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
  let mut idx = 0
  for sp in self.spans {
    for ch in sp.text {
      let cp = ch.to_int()
      let is_nl = cp == 10
      let is_sp = cp == 32 || cp == 9
      let face = style_face(sp.style, cp)
      let adv = if is_nl {
        (0.0 : Float)
      } else if cp == 9 {
        // Tab: four spaces. A position-dependent tab stop needs line-break
        // feedback; this keeps the char advance precomputable.
        face.advance_width(32, sp.style.font_size) * (4.0 : Float) +
        sp.style.letter_spacing
      } else {
        face.advance_width(cp, sp.style.font_size) + sp.style.letter_spacing
      }
      chars.push({
        cp,
        style: sp.style,
        font: face,
        advance: adv,
        char_index: idx,
        is_newline: is_nl,
        is_space: is_sp,
      })
      self.char_x.push((0.0 : Float))
      self.char_line.push(0)
      idx = idx + 1
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
      let k = a.font.kern(a.cp, b.cp, a.style.font_size)
      if k != (0.0 : Float) {
        chars[i].advance = chars[i].advance + k
      }
    }
  }

  let raw_lines : Array[(Int, Int)] = []
  let mut line_start = 0
  let mut cur_w = (0.0 : Float)
  let mut last_break = -1
  let n = chars.length()
  let mut i = 0
  while i < n {
    let c = chars[i]
    if c.is_newline {
      raw_lines.push((line_start, i))
      line_start = i + 1
      cur_w = (0.0 : Float)
      last_break = -1
      i = i + 1
      continue
    }
    let prev_cp = if i > 0 { chars[i - 1].cp } else { -1 }
    if c.is_space {
      last_break = i
    } else if is_cjk(c.cp) {
      if !is_no_start(c.cp) && !is_no_end(prev_cp) {
        last_break = i
      }
    }
    if cur_w + c.advance > mw && i > line_start {
      if last_break > line_start {
        let brk = last_break
        raw_lines.push((line_start, if chars[brk].is_space { brk } else { brk + 1 }))
        line_start = if chars[brk].is_space { brk + 1 } else { brk + 1 }
        cur_w = (0.0 : Float)
        last_break = -1
        i = line_start
        continue
      } else {
        raw_lines.push((line_start, i))
        line_start = i
        cur_w = (0.0 : Float)
        last_break = -1
        continue
      }
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
        let (asc, _desc, lh) = ch.font.metrics(ch.style.font_size)
        if asc > max_asc { max_asc = asc }
        let sh = lh * self.pstyle.line_height_scale
        if sh > max_h { max_h = sh }
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
    // Visual order: reverse contiguous RTL runs. This is a UAX #9 subset
    // (strong RTL ranges only); Arabic joining still depends on GSUB.
    let order : Array[Int] = []
    let mut oi = rs
    while oi < end_idx {
      if is_rtl(chars[oi].cp) {
        let st = oi
        while oi < end_idx && is_rtl(chars[oi].cp) {
          oi = oi + 1
        }
        let mut j = oi - 1
        while j >= st {
          order.push(j)
          j = j - 1
        }
      } else {
        order.push(oi)
        oi = oi + 1
      }
    }
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
      self.char_x[ch.char_index] = cx
      self.char_line[ch.char_index] = li
      let add_gap = is_justify &&
        oi2 < order.length() - 1 &&
        (if space_gaps > 0 { ch.is_space } else { true })
      if !ch.is_space && !ch.is_newline {
        self.glyphs.push({
          codepoint: ch.cp,
          font: ch.font,
          font_size: ch.style.font_size,
          x: cx,
          baseline_y: baseline,
          advance: ch.advance,
          color: ch.style.color,
          char_index: ch.char_index,
        })
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
      for ech in ell {
        let ecp = ech.to_int()
        let eadv = est.font.advance_width(ecp, est.font_size)
        self.glyphs.push({
          codepoint: ecp,
          font: est.font,
          font_size: est.font_size,
          x: cx,
          baseline_y: baseline,
          advance: eadv,
          color: est.color,
          char_index: end_idx - 1,
        })
        cx = cx + eadv
      }
    }
    let reported_w = if is_justify { mw } else { line_w }
    if reported_w > max_w { max_w = reported_w }
    self.lines.push({
      start_index: rs,
      end_index: end_idx,
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
    return { offset: 0, line: 0 }
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
  { offset: best_off, line: target_line }
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
    lm.width
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
