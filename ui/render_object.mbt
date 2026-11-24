// RenderObject tree: single-pass BoxConstraints layout, RepaintBoundary DisplayList caching,
// Layer emission, and reverse-paint-order HitTest.

///|
pub(all) enum RenderKind {
  Box(Float?, Float?)
  Padding(EdgeInsets)
  Align(Alignment)
  Constrained(BoxConstraints)
  Decorated(DecoratedProps)
  Flex(Axis, MainAxisAlignment, CrossAxisAlignment, MainAxisSize, Float)
  FlexChild(Int, FlexFit)
  Stack(Alignment)
  Positioned(Float?, Float?, Float?, Float?, Float?, Float?)
  Wrap(Float, Float)
  ClipRect
  ClipRRect(Float)
  Opacity(Float)
  Transform(@g2d.Matrix3)
  BackdropFilter(Float, Float, @g2d.Color)
  RepaintBoundary
  Text(String, @g2d.TextStyle, @g2d.TextAlign, Int, String)
  Image(@g2d.Image2D, Float, Float)
  CustomPaint(@g2d.Size, (@g2d.Canvas, @g2d.Size) -> Unit)
  Gesture(GestureCallbacks)
  ListView(Int, Float, ScrollController)
  TextField(TextController, String, Float, Float, ThemeData)
}

///|
pub struct RenderNode {
  id : Int
  mut kind : RenderKind
  mut size : @g2d.Size
  mut offset : @g2d.Point
  mut last_constraints : BoxConstraints?
  mut needs_layout : Bool
  mut needs_paint : Bool
  is_repaint_boundary : Bool
  mut cached_dl : @g2d.DisplayList?
  children : Array[RenderNode]
  mut text_para : @g2d.Paragraph?
  // ListView active item metadata: (index -> child index in children)
  list_indices : Array[Int]
  mut active_theme : ThemeData
}

///|
pub fn RenderNode::new(id : Int, kind : RenderKind, theme : ThemeData) -> RenderNode {
  let is_rb = match kind {
    RenderKind::RepaintBoundary | RenderKind::ListView(_, _, _) => true
    _ => false
  }
  {
    id,
    kind,
    size: @g2d.Size::zero(),
    offset: @g2d.Point::zero(),
    last_constraints: None,
    needs_layout: true,
    needs_paint: true,
    is_repaint_boundary: is_rb,
    cached_dl: None,
    children: [],
    text_para: None,
    list_indices: [],
    active_theme: theme,
  }
}

///|
fn compute_main_offsets(
  align : MainAxisAlignment,
  free_space : Float,
  gap : Float,
  count : Int,
) -> (Float, Float) {
  if count <= 0 {
    return ((0.0 : Float), gap)
  }
  let f = max_f((0.0 : Float), free_space)
  match align {
    MainAxisAlignment::Start => ((0.0 : Float), gap)
    MainAxisAlignment::End => (f, gap)
    MainAxisAlignment::Center => (f * (0.5 : Float), gap)
    MainAxisAlignment::SpaceBetween =>
      if count > 1 {
        ((0.0 : Float), gap + f / Float::from_int(count - 1))
      } else {
        ((0.0 : Float), gap)
      }
    MainAxisAlignment::SpaceAround => {
      let step = f / Float::from_int(count)
      (step * (0.5 : Float), gap + step)
    }
    MainAxisAlignment::SpaceEvenly => {
      let step = f / Float::from_int(count + 1)
      (step, gap + step)
    }
  }
}

///|
pub fn RenderNode::layout(self : RenderNode, constraints : BoxConstraints) -> @g2d.Size {
  if !self.needs_layout && self.last_constraints == Some(constraints) {
    return self.size
  }
  self.last_constraints = Some(constraints)
  self.needs_layout = false
  self.needs_paint = true
  self.cached_dl = None

  let sz = match self.kind {
    RenderKind::Box(wo, ho) => {
      let cw = match wo {
        Some(w) => w
        None => if constraints.has_bounded_width() { constraints.max_width } else { (0.0 : Float) }
      }
      let ch = match ho {
        Some(h) => h
        None => if constraints.has_bounded_height() { constraints.max_height } else { (0.0 : Float) }
      }
      if self.children.length() == 0 {
        constraints.constrain(
          @g2d.Size::new(
            match wo { Some(w) => w; None => (0.0 : Float) },
            match ho { Some(h) => h; None => (0.0 : Float) },
          ),
        )
      } else {
        let child_c = BoxConstraints::new(
          min_width=match wo { Some(w) => clamp_f(w, constraints.min_width, constraints.max_width); None => constraints.min_width },
          max_width=match wo { Some(w) => clamp_f(w, constraints.min_width, constraints.max_width); None => constraints.max_width },
          min_height=match ho { Some(h) => clamp_f(h, constraints.min_height, constraints.max_height); None => constraints.min_height },
          max_height=match ho { Some(h) => clamp_f(h, constraints.min_height, constraints.max_height); None => constraints.max_height },
        )
        let csz = self.children[0].layout(child_c)
        self.children[0].offset = @g2d.Point::zero()
        let _ = (cw, ch)
        constraints.constrain(csz)
      }
    }
    RenderKind::Padding(insets) => {
      if self.children.length() == 0 {
        constraints.constrain(@g2d.Size::new(insets.horizontal(), insets.vertical()))
      } else {
        let inner_c = constraints.deflate(insets)
        let csz = self.children[0].layout(inner_c)
        self.children[0].offset = @g2d.Point::new(insets.left, insets.top)
        constraints.constrain(
          @g2d.Size::new(csz.width + insets.horizontal(), csz.height + insets.vertical()),
        )
      }
    }
    RenderKind::Align(al) => {
      if self.children.length() == 0 {
        constraints.constrain(@g2d.Size::zero())
      } else {
        let csz = self.children[0].layout(constraints.loosen())
        let self_sz = constraints.constrain(
          @g2d.Size::new(
            if constraints.has_bounded_width() { constraints.max_width } else { csz.width },
            if constraints.has_bounded_height() { constraints.max_height } else { csz.height },
          ),
        )
        self.children[0].offset = al.along_offset(self_sz, csz)
        self_sz
      }
    }
    RenderKind::Constrained(extra) => {
      let merged = extra.enforce(constraints)
      if self.children.length() == 0 {
        merged.constrain(@g2d.Size::zero())
      } else {
        let csz = self.children[0].layout(merged)
        self.children[0].offset = @g2d.Point::zero()
        csz
      }
    }
    RenderKind::Decorated(_)
    | RenderKind::ClipRect
    | RenderKind::ClipRRect(_)
    | RenderKind::Opacity(_)
    | RenderKind::Transform(_)
    | RenderKind::BackdropFilter(_, _, _)
    | RenderKind::RepaintBoundary
    | RenderKind::Gesture(_)
    | RenderKind::FlexChild(_, _)
    | RenderKind::Positioned(_, _, _, _, _, _) =>
      if self.children.length() == 0 {
        constraints.constrain(@g2d.Size::zero())
      } else {
        let csz = self.children[0].layout(constraints)
        self.children[0].offset = @g2d.Point::zero()
        csz
      }
    RenderKind::Flex(axis, main_align, cross_align, main_size, gap) => {
      let is_horiz = axis == Axis::Horizontal
      let n = self.children.length()
      let max_main = if is_horiz { constraints.max_width } else { constraints.max_height }
      let max_cross = if is_horiz { constraints.max_height } else { constraints.max_width }
      let min_cross = if is_horiz { constraints.min_height } else { constraints.min_width }
      let total_gap = if n > 1 { gap * Float::from_int(n - 1) } else { (0.0 : Float) }

      let mut total_flex = 0
      let mut fixed_main = total_gap
      let mut max_child_cross = min_cross

      let child_cross_min = if cross_align == CrossAxisAlignment::Stretch && max_cross < INF * (0.5 : Float) {
        max_cross
      } else {
        (0.0 : Float)
      }

      // Pass 1: layout non-flex children with unbounded main axis
      for ch in self.children {
        match ch.kind {
          RenderKind::FlexChild(fl, _) => total_flex = total_flex + fl
          _ => {
            let cc = if is_horiz {
              BoxConstraints::new(min_height=child_cross_min, max_height=max_cross)
            } else {
              BoxConstraints::new(min_width=child_cross_min, max_width=max_cross)
            }
            let csz = ch.layout(cc)
            let cm = if is_horiz { csz.width } else { csz.height }
            let cx = if is_horiz { csz.height } else { csz.width }
            fixed_main = fixed_main + cm
            if cx > max_child_cross { max_child_cross = cx }
          }
        }
      }

      // Pass 2: distribute remaining space among flex children
      let has_bound_main = max_main < INF * (0.5 : Float)
      let avail_for_flex = if has_bound_main {
        max_f((0.0 : Float), max_main - fixed_main)
      } else {
        (0.0 : Float)
      }
      let mut used_main = fixed_main
      for ch in self.children {
        match ch.kind {
          RenderKind::FlexChild(fl, fit) => {
            let alloc = if total_flex > 0 && has_bound_main {
              avail_for_flex * Float::from_int(fl) / Float::from_int(total_flex)
            } else {
              (0.0 : Float)
            }
            let min_m = if fit == FlexFit::Tight { alloc } else { (0.0 : Float) }
            let max_m = if has_bound_main { alloc } else { INF }
            let cc = if is_horiz {
              BoxConstraints::new(
                min_width=min_m,
                max_width=max_m,
                min_height=child_cross_min,
                max_height=max_cross,
              )
            } else {
              BoxConstraints::new(
                min_width=child_cross_min,
                max_width=max_cross,
                min_height=min_m,
                max_height=max_m,
              )
            }
            let csz = ch.layout(cc)
            let cm = if is_horiz { csz.width } else { csz.height }
            let cx = if is_horiz { csz.height } else { csz.width }
            used_main = used_main + cm
            if cx > max_child_cross { max_child_cross = cx }
          }
          _ => ()
        }
      }

      let final_main = if main_size == MainAxisSize::Max && has_bound_main {
        max_f(used_main, max_main)
      } else {
        used_main
      }
      let self_sz = constraints.constrain(
        if is_horiz {
          @g2d.Size::new(final_main, max_child_cross)
        } else {
          @g2d.Size::new(max_child_cross, final_main)
        },
      )
      let real_main = if is_horiz { self_sz.width } else { self_sz.height }
      let real_cross = if is_horiz { self_sz.height } else { self_sz.width }
      let free_space = real_main - used_main
      let (start_off, step_gap) = compute_main_offsets(main_align, free_space, gap, n)
      let mut cursor = start_off
      for ch in self.children {
        let cm = if is_horiz { ch.size.width } else { ch.size.height }
        let cx = if is_horiz { ch.size.height } else { ch.size.width }
        let cross_off = match cross_align {
          CrossAxisAlignment::Start | CrossAxisAlignment::Stretch => (0.0 : Float)
          CrossAxisAlignment::Center => (real_cross - cx) * (0.5 : Float)
          CrossAxisAlignment::End => real_cross - cx
        }
        ch.offset = if is_horiz {
          @g2d.Point::new(cursor, cross_off)
        } else {
          @g2d.Point::new(cross_off, cursor)
        }
        cursor = cursor + cm + step_gap
      }
      self_sz
    }
    RenderKind::Stack(al) => {
      let mut max_w = constraints.min_width
      let mut max_h = constraints.min_height
      let loose = constraints.loosen()
      for ch in self.children {
        match ch.kind {
          RenderKind::Positioned(_, _, _, _, wo, ho) => {
            let pc = BoxConstraints::new(
              min_width=match wo { Some(w) => w; None => (0.0 : Float) },
              max_width=match wo { Some(w) => w; None => loose.max_width },
              min_height=match ho { Some(h) => h; None => (0.0 : Float) },
              max_height=match ho { Some(h) => h; None => loose.max_height },
            )
            let csz = ch.layout(pc)
            if csz.width > max_w { max_w = csz.width }
            if csz.height > max_h { max_h = csz.height }
          }
          _ => {
            let csz = ch.layout(loose)
            if csz.width > max_w { max_w = csz.width }
            if csz.height > max_h { max_h = csz.height }
          }
        }
      }
      let self_sz = constraints.constrain(
        @g2d.Size::new(
          if constraints.has_bounded_width() { max_f(max_w, constraints.max_width) } else { max_w },
          if constraints.has_bounded_height() { max_f(max_h, constraints.max_height) } else { max_h },
        ),
      )
      for ch in self.children {
        match ch.kind {
          RenderKind::Positioned(lo, to, ro, bo, wo, ho) => {
            let pw = match (lo, ro, wo) {
              (Some(l), Some(r), None) => Some(max_f((0.0 : Float), self_sz.width - l - r))
              _ => wo
            }
            let ph = match (to, bo, ho) {
              (Some(t), Some(b), None) => Some(max_f((0.0 : Float), self_sz.height - t - b))
              _ => ho
            }
            if pw is Some(_) || ph is Some(_) {
              let pc = BoxConstraints::new(
                min_width=match pw { Some(w) => w; None => (0.0 : Float) },
                max_width=match pw { Some(w) => w; None => self_sz.width },
                min_height=match ph { Some(h) => h; None => (0.0 : Float) },
                max_height=match ph { Some(h) => h; None => self_sz.height },
              )
              let _ = ch.layout(pc)
            }
            let x = match (lo, ro) {
              (Some(l), _) => l
              (None, Some(r)) => self_sz.width - ch.size.width - r
              (None, None) => (0.0 : Float)
            }
            let y = match (to, bo) {
              (Some(t), _) => t
              (None, Some(b)) => self_sz.height - ch.size.height - b
              (None, None) => (0.0 : Float)
            }
            ch.offset = @g2d.Point::new(x, y)
          }
          _ => ch.offset = al.along_offset(self_sz, ch.size)
        }
      }
      self_sz
    }
    RenderKind::Wrap(spacing, run_spacing) => {
      let max_w = if constraints.has_bounded_width() {
        constraints.max_width
      } else {
        (1.0e6 : Float)
      }
      let loose = BoxConstraints::new(max_width=max_w, max_height=constraints.max_height)
      let mut x = (0.0 : Float)
      let mut y = (0.0 : Float)
      let mut row_h = (0.0 : Float)
      let mut max_used_w = (0.0 : Float)
      for ch in self.children {
        let csz = ch.layout(loose)
        if x > (0.0 : Float) && x + csz.width > max_w {
          x = (0.0 : Float)
          y = y + row_h + run_spacing
          row_h = (0.0 : Float)
        }
        ch.offset = @g2d.Point::new(x, y)
        x = x + csz.width + spacing
        if csz.height > row_h { row_h = csz.height }
        let line_right = x - spacing
        if line_right > max_used_w { max_used_w = line_right }
      }
      constraints.constrain(@g2d.Size::new(max_used_w, y + row_h))
    }
    RenderKind::Text(content, style, align, max_lines, ellipsis) => {
      let para = @g2d.ParagraphBuilder::new(
        style=@g2d.ParagraphStyle::new(align~, max_lines~, ellipsis~),
      )
        .add_text(content, style~)
        .build()
      let max_w = if constraints.has_bounded_width() {
        constraints.max_width
      } else {
        (1.0e9 : Float)
      }
      para.layout(max_w)
      self.text_para = Some(para)
      constraints.constrain(@g2d.Size::new(para.width(), para.height()))
    }
    RenderKind::Image(_, w, h) => constraints.constrain(@g2d.Size::new(w, h))
    RenderKind::CustomPaint(pref, _) => constraints.constrain(pref)
    RenderKind::ListView(count, item_extent, ctrl) => {
      let vw = if constraints.has_bounded_width() {
        constraints.max_width
      } else {
        (400.0 : Float)
      }
      let vh = if constraints.has_bounded_height() {
        constraints.max_height
      } else {
        (360.0 : Float)
      }
      let total_h = Float::from_int(count) * item_extent
      ctrl.viewport_extent = vh
      ctrl.max_extent = max_f((0.0 : Float), total_h - vh)
      let scroll_y = clamp_f(ctrl.offset.peek(), (0.0 : Float), ctrl.max_extent)
      for i = 0; i < self.children.length(); i = i + 1 {
        let ch = self.children[i]
        let item_idx = if i < self.list_indices.length() {
          self.list_indices[i]
        } else {
          i
        }
        let _ = ch.layout(
          BoxConstraints::new(
            min_width=vw,
            max_width=vw,
            min_height=item_extent,
            max_height=item_extent,
          ),
        )
        ch.offset = @g2d.Point::new(
          (0.0 : Float),
          Float::from_int(item_idx) * item_extent - scroll_y,
        )
      }
      constraints.constrain(@g2d.Size::new(vw, vh))
    }
    RenderKind::TextField(_, _, pref_w, font_size, _) => {
      let w = if constraints.has_bounded_width() {
        min_f(pref_w, constraints.max_width)
      } else {
        pref_w
      }
      constraints.constrain(@g2d.Size::new(w, font_size + (20.0 : Float)))
    }
  }
  self.size = sz
  sz
}

///|
fn paint_decorated_box(
  canvas : @g2d.Canvas,
  size : @g2d.Size,
  d : DecoratedProps,
) -> Unit {
  let rect = @g2d.Rect::from_size(size)
  let rrect = @g2d.RRect::per_corner(rect, d.tl, d.tr, d.br, d.bl)
  match d.shadow_color {
    Some(sc) =>
      if d.shadow_blur > (0.0 : Float) {
        canvas.draw_rrect_shadow(
          rrect,
          d.shadow_dx,
          d.shadow_dy,
          d.shadow_blur,
          (0.0 : Float),
          sc,
        )
      }
    None => ()
  }
  if d.fill is Some(_) || d.shader is Some(_) || d.border_color is Some(_) {
    let style = match (d.fill is Some(_) || d.shader is Some(_), d.border_color is Some(_) && d.border_width > (0.0 : Float)) {
      (true, true) => @g2d.PaintStyle::StrokeAndFill
      (true, false) => @g2d.PaintStyle::Fill
      (false, true) => @g2d.PaintStyle::Stroke
      (false, false) => @g2d.PaintStyle::Fill
    }
    let fill_col = match d.fill {
      Some(c) => c
      None => @g2d.Color::transparent()
    }
    let bcol = match d.border_color {
      Some(c) => c
      None => fill_col
    }
    let p = @g2d.Paint::new(
      color=if style == @g2d.PaintStyle::Stroke { bcol } else { fill_col },
      style~,
      stroke_width=d.border_width,
      shader=d.shader,
    )
    if style == @g2d.PaintStyle::StrokeAndFill {
      // Pass fill first then crisp border via StrokeAndFill color convention in prim2d
      canvas.draw_rrect(
        rrect,
        @g2d.Paint::new(color=fill_col, style=@g2d.PaintStyle::Fill, shader=d.shader),
      )
      canvas.draw_rrect(
        rrect,
        @g2d.Paint::new(color=bcol, style=@g2d.PaintStyle::Stroke, stroke_width=d.border_width),
      )
    } else {
      canvas.draw_rrect(rrect, p)
    }
  }
}

///|
pub fn RenderNode::build_layer(self : RenderNode) -> Layer {
  if self.is_repaint_boundary && !self.needs_paint {
    match self.cached_dl {
      Some(dl) => return Layer::Picture(dl)
      None => ()
    }
  }
  self.needs_paint = false
  let layer = self.paint_subtree_layer()
  if self.is_repaint_boundary {
    let dl = layer.to_display_list()
    self.cached_dl = Some(dl)
    Layer::Picture(dl)
  } else {
    layer
  }
}

///|
fn RenderNode::paint_children_layers(self : RenderNode) -> Array[Layer] {
  let out : Array[Layer] = []
  for ch in self.children {
    let cl = ch.build_layer()
    if ch.offset.x != (0.0 : Float) || ch.offset.y != (0.0 : Float) {
      out.push(Layer::Offset(ch.offset.x, ch.offset.y, [cl]))
    } else {
      out.push(cl)
    }
  }
  out
}

///|
fn RenderNode::paint_subtree_layer(self : RenderNode) -> Layer {
  match self.kind {
    RenderKind::Decorated(d) => {
      let c = @g2d.Canvas::new()
      paint_decorated_box(c, self.size, d)
      let bg = Layer::Picture(c.finish())
      let kids = self.paint_children_layers()
      let all : Array[Layer] = [bg]
      for k in kids {
        all.push(k)
      }
      Layer::Container(all)
    }
    RenderKind::ClipRect | RenderKind::ListView(_, _, _) => {
      let kids = self.paint_children_layers()
      Layer::ClipRect(@g2d.Rect::from_size(self.size), kids)
    }
    RenderKind::ClipRRect(rad) =>
      Layer::ClipRRect(
        @g2d.RRect::uniform(@g2d.Rect::from_size(self.size), rad),
        self.paint_children_layers(),
      )
    RenderKind::Opacity(a) => Layer::Opacity(a, self.paint_children_layers())
    RenderKind::Transform(mat) => Layer::Transform(mat, self.paint_children_layers())
    RenderKind::BackdropFilter(sigma, rad, tint) => {
      let c = @g2d.Canvas::new()
      c.draw_rrect(
        @g2d.RRect::uniform(@g2d.Rect::from_size(self.size), rad),
        @g2d.Paint::fill(tint),
      )
      let tint_layer = Layer::Picture(c.finish())
      let kids = self.paint_children_layers()
      let all : Array[Layer] = [tint_layer]
      for k in kids {
        all.push(k)
      }
      Layer::ClipRRect(
        @g2d.RRect::uniform(@g2d.Rect::from_size(self.size), rad),
        [
          Layer::BackdropFilter(
            @g2d.Rect::from_size(self.size),
            @g2d.ImageFilter::Blur(sigma, sigma, @g2d.TileMode::Clamp),
            all,
          ),
        ],
      )
    }
    RenderKind::Text(_, _, _, _, _) => {
      let c = @g2d.Canvas::new()
      match self.text_para {
        Some(p) => c.draw_paragraph(p, @g2d.Point::zero())
        None => ()
      }
      Layer::Picture(c.finish())
    }
    RenderKind::Image(img, _, _) => {
      let c = @g2d.Canvas::new()
      c.draw_image_rect(
        img,
        @g2d.Rect::new(
          (0.0 : Float),
          (0.0 : Float),
          Float::from_int(img.width),
          Float::from_int(img.height),
        ),
        @g2d.Rect::from_size(self.size),
      )
      Layer::Picture(c.finish())
    }
    RenderKind::CustomPaint(_, painter) => {
      let c = @g2d.Canvas::new()
      painter(c, self.size)
      Layer::Picture(c.finish())
    }
    RenderKind::TextField(ctrl, placeholder, _, font_size, theme) => {
      let c = @g2d.Canvas::new()
      let rect = @g2d.Rect::from_size(self.size)
      let rrect = @g2d.RRect::uniform(rect, theme.radius_sm)
      let is_foc = ctrl.focused.peek()
      c.draw_rrect(rrect, @g2d.Paint::fill(theme.colors.surface_variant))
      c.draw_rrect(
        rrect,
        @g2d.Paint::stroke(
          if is_foc { theme.colors.primary } else { theme.colors.border },
          if is_foc { (2.0 : Float) } else { (1.0 : Float) },
        ),
      )
      let txt = ctrl.text.peek()
      let shown = if txt == "" { placeholder } else { txt }
      let tcol = if txt == "" { theme.colors.text_secondary } else { theme.colors.text_primary }
      let para = @g2d.ParagraphBuilder::new()
        .add_text(
          shown,
          style=@g2d.TextStyle::new(font=theme.font, font_size~, color=tcol),
        )
        .build()
      para.layout(self.size.width - (20.0 : Float))
      let pad_x = (10.0 : Float)
      let pad_y = max_f((4.0 : Float), (self.size.height - para.height()) * (0.5 : Float))
      c.draw_paragraph(para, @g2d.Point::new(pad_x, pad_y))
      if is_foc {
        let pos : @g2d.TextPosition = {
          offset: if txt == "" { 0 } else { ctrl.cursor.peek() },
          line: 0,
        }
        let cr = para.get_caret_rect(pos)
        c.draw_rect(
          @g2d.Rect::new(pad_x + cr.x, pad_y + cr.y, (2.0 : Float), cr.height),
          @g2d.Paint::fill(theme.colors.primary),
        )
      }
      Layer::Picture(c.finish())
    }
    _ => Layer::Container(self.paint_children_layers())
  }
}

///|
pub fn RenderNode::hit_test(
  self : RenderNode,
  local_pos : @g2d.Point,
  out : Array[HitTestEntry],
) -> Bool {
  if local_pos.x < (0.0 : Float) ||
    local_pos.y < (0.0 : Float) ||
    local_pos.x >= self.size.width ||
    local_pos.y >= self.size.height {
    return false
  }
  let mapped_pos = match self.kind {
    RenderKind::Transform(mat) =>
      match mat.invert() {
        Some(inv) => inv.map_point(local_pos)
        None => return false
      }
    _ => local_pos
  }
  let mut child_hit = false
  let mut i = self.children.length() - 1
  while i >= 0 {
    let ch = self.children[i]
    let child_local = mapped_pos.sub(ch.offset)
    if ch.hit_test(child_local, out) {
      child_hit = true
    }
    i = i - 1
  }
  match self.kind {
    RenderKind::Gesture(cbs) => {
      out.push({ node_id: self.id, local_pos: mapped_pos, callbacks: cbs })
      true
    }
    RenderKind::TextField(ctrl, _, _, font_size, theme) => {
      let cbs : GestureCallbacks = {
        ..GestureCallbacks::empty(),
        on_tap: Some(fn() {
          ctrl.focused.set(true)
          let txt = ctrl.text.peek()
          if txt != "" {
            let p = @g2d.ParagraphBuilder::new()
              .add_text(
                txt,
                style=@g2d.TextStyle::new(font=theme.font, font_size~),
              )
              .build()
            p.layout((1.0e9 : Float))
            let tp = p.get_position_for_offset(
              @g2d.Point::new(mapped_pos.x - (10.0 : Float), (4.0 : Float)),
            )
            ctrl.cursor.set(tp.offset)
          }
        }),
      }
      out.push({ node_id: self.id, local_pos: mapped_pos, callbacks: cbs })
      true
    }
    RenderKind::ListView(_, _, ctrl) => {
      let cbs : GestureCallbacks = {
        ..GestureCallbacks::empty(),
        on_scroll: Some(fn(_dx, dy) { ctrl.scroll_by(-dy * (42.0 : Float)) }),
        on_drag_update: Some(fn(_p, delta) { ctrl.scroll_by(-delta.y) }),
      }
      out.push({ node_id: self.id, local_pos: mapped_pos, callbacks: cbs })
      true
    }
    RenderKind::Decorated(_) => child_hit || true
    _ => child_hit
  }
}

///|
pub fn RenderNode::count_nodes(self : RenderNode) -> Int {
  let mut total = 1
  for ch in self.children {
    total = total + ch.count_nodes()
  }
  total
}
