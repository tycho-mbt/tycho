// High-level desktop UI controls (buttons, checkbox, switch, slider, card, dialog, performance overlay).

///|
pub fn divider(
  key? : Key,
  height? : Float = (1.0 : Float),
  color? : @g2d.Color,
) -> Widget {
  builder(key?=key, tag=301, fn(ctx) {
    let col = match color {
      Some(c) => c
      None => ctx.colors().border
    }
    constrained_box(
      BoxConstraints::new(min_width=INF, max_width=INF, min_height=height, max_height=height),
      container(decoration=DecoratedProps::new(fill=col)),
    )
  })
}

///|
pub fn card(
  key? : Key,
  pad? : EdgeInsets = EdgeInsets::all((16.0 : Float)),
  radius? : Float,
  color? : @g2d.Color,
  border_color? : @g2d.Color,
  shadow_blur? : Float = (12.0 : Float),
  child : Widget,
) -> Widget {
  builder(key?=key, tag=302, fn(ctx) {
    let th = ctx.theme()
    let bg = match color { Some(c) => c; None => th.colors.surface }
    let bc = match border_color { Some(c) => c; None => th.colors.border }
    let rad = match radius { Some(r) => r; None => th.radius_md }
    container(
      pad=pad,
      child=child,
      decoration=DecoratedProps::new(
        fill=bg,
        border_color=bc,
        border_width=(1.5 : Float),
        radius=rad,
        shadow_blur=shadow_blur,
        shadow_dy=(6.0 : Float),
        shadow_color=@g2d.Color::rgba((0.0 : Float), (0.0 : Float), (0.02 : Float), (0.45 : Float)),
      )
    )
  })
}

///|
pub fn filled_button(
  key? : Key,
  label : String,
  on_pressed : () -> Unit,
  color? : @g2d.Color,
  pad? : EdgeInsets = EdgeInsets::symmetric(horizontal=(16.0 : Float), vertical=(10.0 : Float)),
) -> Widget {
  let hovered = Signal::new(false)
  builder(key?=key, tag=303, fn(ctx) {
    let th = ctx.theme()
    let is_h = hovered.get(ctx)
    let base = match color { Some(c) => c; None => th.colors.primary }
    let bg = if is_h { base.lerp(@g2d.Color::white(), (0.16 : Float)) } else { base }
    mouse_region(
      on_enter=fn() { hovered.set(true) },
      on_exit=fn() { hovered.set(false) },
      gesture_detector(
        on_tap=on_pressed,
        container(
          pad=pad,
          child=text(label, size=(14.0 : Float), color=th.colors.on_primary),
          decoration=DecoratedProps::new(
            fill=bg,
            radius=th.radius_sm,
          )
        ),
      ),
    )
  })
}

///|
pub fn outlined_button(
  key? : Key,
  label : String,
  on_pressed : () -> Unit,
  pad? : EdgeInsets = EdgeInsets::symmetric(horizontal=(16.0 : Float), vertical=(10.0 : Float)),
) -> Widget {
  let hovered = Signal::new(false)
  builder(key?=key, tag=304, fn(ctx) {
    let th = ctx.theme()
    let is_h = hovered.get(ctx)
    let bg = if is_h { th.colors.surface_variant } else { th.colors.surface }
    mouse_region(
      on_enter=fn() { hovered.set(true) },
      on_exit=fn() { hovered.set(false) },
      gesture_detector(
        on_tap=on_pressed,
        container(
          pad=pad,
          child=text(label, size=(14.0 : Float), color=th.colors.primary),
          decoration=DecoratedProps::new(
            fill=bg,
            border_color=th.colors.primary,
            border_width=(1.5 : Float),
            radius=th.radius_sm,
          )
        ),
      ),
    )
  })
}

///|
pub fn checkbox(
  key? : Key,
  checked : Signal[Bool],
  label? : String = "",
  on_changed? : ((Bool) -> Unit),
) -> Widget {
  builder(key?=key, tag=305, fn(ctx) {
    let th = ctx.theme()
    let val = checked.get(ctx)
    let box_bg = if val { th.colors.primary } else { th.colors.surface_variant }
    let box_border = if val { th.colors.primary } else { th.colors.border }
    let check_mark = if val {
      Some(
        container(
          width=(10.0 : Float),
          height=(10.0 : Float),
          decoration=DecoratedProps::new(
            fill=th.colors.on_primary,
            radius=(2.0 : Float),
          )
        ),
      )
    } else {
      None
    }
    let box_w = container(
      width=(20.0 : Float),
      height=(20.0 : Float),
      alignment=Alignment::center(),
      child?=check_mark,
      decoration=DecoratedProps::new(
        fill=box_bg,
        border_color=box_border,
        border_width=(1.5 : Float),
        radius=(5.0 : Float),
      )
    )
    let kids : Array[Widget] = [box_w]
    if label != "" {
      kids.push(text(label, size=(14.0 : Float), color=th.colors.text_primary))
    }
    gesture_detector(
      on_tap=fn() {
        let nv = !checked.peek()
        checked.set(nv)
        match on_changed {
          Some(f) => f(nv)
          None => ()
        }
      },
      row(gap=(10.0 : Float), main_size=MainAxisSize::Min, kids),
    )
  })
}

///|
pub fn switch_toggle(
  key? : Key,
  value : Signal[Bool],
  label? : String = "",
  on_changed? : ((Bool) -> Unit),
) -> Widget {
  builder(key?=key, tag=306, fn(ctx) {
    let th = ctx.theme()
    let on = value.get(ctx)
    let track_bg = if on { th.colors.secondary } else { th.colors.surface_variant }
    let track_w = (44.0 : Float)
    let track_h = (24.0 : Float)
    let knob_x = if on { (22.0 : Float) } else { (3.0 : Float) }
    let track = container(
      width=track_w,
      height=track_h,
      child=
        stack([
          positioned(
            left=knob_x,
            top=(3.0 : Float),
            width=(18.0 : Float),
            height=(18.0 : Float),
            container(decoration=DecoratedProps::new(fill=@g2d.Color::white(), radius=(9.0 : Float))),
          ),
        ]),
      decoration=DecoratedProps::new(
        fill=track_bg,
        border_color=if on { th.colors.secondary } else { th.colors.border },
        border_width=(1.0 : Float),
        radius=(12.0 : Float),
      )
    )
    let kids : Array[Widget] = [track]
    if label != "" {
      kids.push(text(label, size=(14.0 : Float), color=th.colors.text_primary))
    }
    gesture_detector(
      on_tap=fn() {
        let nv = !value.peek()
        value.set(nv)
        match on_changed {
          Some(f) => f(nv)
          None => ()
        }
      },
      row(gap=(10.0 : Float), main_size=MainAxisSize::Min, kids),
    )
  })
}

///|
pub fn progress_bar(
  key? : Key,
  value : Float,
  width? : Float = (200.0 : Float),
  height? : Float = (10.0 : Float),
  color? : @g2d.Color,
) -> Widget {
  builder(key?=key, tag=307, fn(ctx) {
    let th = ctx.theme()
    let t = @tmath.clamp_f(value, (0.0 : Float), (1.0 : Float))
    let fill = match color { Some(c) => c; None => th.colors.primary }
    let rad = height * (0.5 : Float)
    container(
      width=width,
      height=height,
      child=
        stack([
          positioned(
            left=(0.0 : Float),
            top=(0.0 : Float),
            width=@tmath.max_f(height, width * t),
            height=height,
            container(decoration=DecoratedProps::new(fill=fill, radius=rad)),
          ),
        ]),
      decoration=DecoratedProps::new(
        fill=th.colors.surface_variant,
        radius=rad,
      )
    )
  })
}

///|
pub fn slider(
  key? : Key,
  value : Signal[Float],
  width? : Float = (220.0 : Float),
) -> Widget {
  builder(key?=key, tag=308, fn(ctx) {
    let th = ctx.theme()
    let v = @tmath.clamp_f(value.get(ctx), (0.0 : Float), (1.0 : Float))
    let h = (24.0 : Float)
    let knob_r = (9.0 : Float)
    let usable = @tmath.max_f((1.0 : Float), width - knob_r * (2.0 : Float))
    let kx = v * usable
    mouse_region(
      cursor=@tycho.CursorShape::Pointer,
      gesture_detector(
        on_drag_start=fn(pos) {
          let nv = @tmath.clamp_f((pos.x - knob_r) / usable, (0.0 : Float), (1.0 : Float))
          value.set(nv)
        },
        on_drag_update=fn(pos, _d) {
          let nv = @tmath.clamp_f((pos.x - knob_r) / usable, (0.0 : Float), (1.0 : Float))
          value.set(nv)
        },
        container(
        width=width,
        height=h,
        child=
          stack([
            positioned(
              left=(0.0 : Float),
              top=(8.0 : Float),
              width=width,
              height=(8.0 : Float),
              container(decoration=DecoratedProps::new(fill=th.colors.surface_variant, radius=(4.0 : Float))),
            ),
            positioned(
              left=(0.0 : Float),
              top=(8.0 : Float),
              width=@tmath.max_f((8.0 : Float), kx + knob_r),
              height=(8.0 : Float),
              container(decoration=DecoratedProps::new(fill=th.colors.primary, radius=(4.0 : Float))),
            ),
            positioned(
              left=kx,
              top=(3.0 : Float),
              width=knob_r * (2.0 : Float),
              height=knob_r * (2.0 : Float),
              container(decoration=DecoratedProps::new(
                fill=@g2d.Color::white(),
                border_color=th.colors.primary,
                border_width=(2.0 : Float),
                radius=knob_r,
              )
              ),
            ),
          ]),
      ),
      ),
    )
  })
}

///|
pub fn frosted_dialog(
  key? : Key,
  title : String,
  body : Widget,
  on_close : () -> Unit,
  width? : Float = (360.0 : Float),
) -> Widget {
  builder(key?=key, tag=309, fn(ctx) {
    let th = ctx.theme()
    stack([
      gesture_detector(
        on_tap=on_close,
        container(decoration=DecoratedProps::new(fill=@g2d.Color::rgba((0.0 : Float), (0.0 : Float), (0.0 : Float), (0.45 : Float)))),
      ),
      center(
        container(
          width=width,
          child=
            backdrop_filter(
              blur_sigma=(16.0 : Float),
              radius=th.radius_lg,
              tint=if th.colors.is_dark {
                @g2d.Color::rgba((0.10 : Float), (0.14 : Float), (0.24 : Float), (0.78 : Float))
              } else {
                @g2d.Color::rgba((0.96 : Float), (0.97 : Float), (1.0 : Float), (0.82 : Float))
              },
              container(
                pad=EdgeInsets::all((20.0 : Float)),
                child=column(gap=(12.0 : Float), [
                  text(title, size=(18.0 : Float), color=th.colors.text_primary),
                  divider(),
                  body,
                  row(main_axis=MainAxisAlignment::End, [
                    filled_button("Close", on_close),
                  ]),
                ]),
                decoration=DecoratedProps::new(
                  border_color=th.colors.border,
                  border_width=(1.5 : Float),
                  radius=th.radius_lg,
                )
              ),
            ),
        ),
      ),
    ])
  })
}

///|
fn format_ms(v : Double) -> String {
  let tenths = (v * 10.0 + 0.5).to_int()
  let whole = tenths / 10
  let frac = tenths % 10
  "\{whole}.\{frac}"
}

///|
pub fn performance_overlay(stats : FrameStats) -> Widget {
  builder(tag=310, fn(ctx) {
    let th = ctx.theme()
    let info_str = "B:\{format_ms(stats.build_ms)}ms L:\{format_ms(stats.layout_ms)}ms P:\{format_ms(stats.paint_ms)}ms GPU:\{format_ms(stats.gpu_ms)}ms | E:\{stats.element_count} R:\{stats.render_count}"
    let bar = fn(ms : Double, col : @g2d.Color) -> Widget {
      let w = @tmath.clamp_f(Float::from_double(ms) * (6.0 : Float), (2.0 : Float), (120.0 : Float))
      container(width=w, height=(4.0 : Float),
decoration=DecoratedProps::new(
  fill=col,
  radius=(2.0 : Float),
))
    }
    container(
      pad=EdgeInsets::symmetric(horizontal=(10.0 : Float), vertical=(6.0 : Float)),
      child=
        column(gap=(3.0 : Float), [
          text(info_str, size=(11.0 : Float), color=@g2d.Color::from_rgba8(120, 236, 175)),
          row(gap=(4.0 : Float), [
            bar(stats.build_ms, @g2d.Color::from_rgba8(96, 165, 250)),
            bar(stats.layout_ms, @g2d.Color::from_rgba8(250, 204, 21)),
            bar(stats.paint_ms, @g2d.Color::from_rgba8(244, 114, 182)),
            bar(stats.gpu_ms, @g2d.Color::from_rgba8(74, 222, 128)),
          ]),
        ]),
      decoration=DecoratedProps::new(
        fill=@g2d.Color::rgba((0.05 : Float), (0.07 : Float), (0.12 : Float), (0.85 : Float)),
        border_color=th.colors.border,
        border_width=(1.0 : Float),
        radius=(6.0 : Float),
      )
    )
  })
}

///|
pub fn layout_inspector(
  key? : Key,
  enabled : Signal[Bool],
  child : Widget,
) -> Widget {
  builder(key?=key, tag=326, fn(ctx) {
    let on = enabled.get(ctx)
    if !on {
      return child
    }
    stack([
      child,
      container(decoration=DecoratedProps::new(
        border_color=@g2d.Color::from_rgba8(80, 220, 255, a=180),
        border_width=(1.0 : Float),
      )
      ),
    ])
  })
}

///|
pub(all) struct RichSpan {
  text : String
  size : Float?
  color : @g2d.Color?
  bold : Bool
  italic : Bool
  underline : Bool
}

///|
pub fn RichSpan::new(
  text : String,
  size? : Float,
  color? : @g2d.Color,
  bold? : Bool = false,
  italic? : Bool = false,
  underline? : Bool = false,
) -> RichSpan {
  { text, size, color, bold, italic, underline }
}

///|
pub fn rich_text(
  key? : Key,
  spans : Array[RichSpan],
  align? : @g2d.TextAlign = @g2d.TextAlign::Left,
  max_lines? : Int = 0,
  ellipsis? : String = "...",
  max_width? : Float = (600.0 : Float),
) -> Widget {
  builder(key?=key, tag=311, fn(ctx) {
    let th = ctx.theme()
    let pb = @g2d.ParagraphBuilder::new(
      style=@g2d.ParagraphStyle::new(align~, max_lines~, ellipsis~),
    )
    for sp in spans {
      let sz = match sp.size { Some(s) => s; None => (14.0 : Float) }
      let col = match sp.color { Some(c) => c; None => th.colors.text_primary }
      let _ = pb.add_text(
        sp.text,
        style=@g2d.TextStyle::new(
          font=th.font,
          font_size=sz,
          color=col,
          underline=sp.underline,
        ),
      )
    }
    let para = pb.build()
    para.layout(max_width)
    let pw = if para.width() > (1.0 : Float) { para.width() } else { (1.0 : Float) }
    let ph = if para.height() > (1.0 : Float) { para.height() } else { (18.0 : Float) }
    custom_paint(@g2d.Size::new(pw, ph), fn(canvas, _sz) {
      canvas.draw_paragraph(para, @g2d.Point::zero())
    })
  })
}

///|
pub(all) enum IconKind {
  Check
  Close
  Add
  Search
  Menu
  ArrowBack
  ArrowForward
  ChevronDown
  Star
  Settings
  Info
  Warning
}

///|
pub fn icon(
  key? : Key,
  kind : IconKind,
  size? : Float = (20.0 : Float),
  color? : @g2d.Color,
) -> Widget {
  builder(key?=key, tag=312, fn(ctx) {
    let th = ctx.theme()
    let col = match color { Some(c) => c; None => th.colors.text_primary }
    let sw = @tmath.max_f((1.5 : Float), size * (0.1 : Float))
    custom_paint(@g2d.Size::new(size, size), fn(c, sz) {
      let w = sz.width
      let h = sz.height
      let st = @g2d.Paint::stroke(col, sw, cap=@g2d.StrokeCap::Round, join=@g2d.StrokeJoin::Round)
      let fl = @g2d.Paint::fill(col)
      match kind {
        IconKind::Check => {
          let p = @g2d.PathBuilder::new()
            .move_to(w * (0.2 : Float), h * (0.52 : Float))
            .line_to(w * (0.42 : Float), h * (0.74 : Float))
            .line_to(w * (0.82 : Float), h * (0.28 : Float))
            .build()
          c.draw_path(p, st)
        }
        IconKind::Close => {
          c.draw_line(@g2d.Point::new(w * (0.22 : Float), h * (0.22 : Float)), @g2d.Point::new(w * (0.78 : Float), h * (0.78 : Float)), st)
          c.draw_line(@g2d.Point::new(w * (0.78 : Float), h * (0.22 : Float)), @g2d.Point::new(w * (0.22 : Float), h * (0.78 : Float)), st)
        }
        IconKind::Add => {
          c.draw_line(@g2d.Point::new(w * (0.5 : Float), h * (0.2 : Float)), @g2d.Point::new(w * (0.5 : Float), h * (0.8 : Float)), st)
          c.draw_line(@g2d.Point::new(w * (0.2 : Float), h * (0.5 : Float)), @g2d.Point::new(w * (0.8 : Float), h * (0.5 : Float)), st)
        }
        IconKind::Search => {
          c.draw_circle(@g2d.Point::new(w * (0.42 : Float), h * (0.42 : Float)), w * (0.24 : Float), st)
          c.draw_line(@g2d.Point::new(w * (0.6 : Float), h * (0.6 : Float)), @g2d.Point::new(w * (0.82 : Float), h * (0.82 : Float)), st)
        }
        IconKind::Menu => {
          c.draw_line(@g2d.Point::new(w * (0.18 : Float), h * (0.28 : Float)), @g2d.Point::new(w * (0.82 : Float), h * (0.28 : Float)), st)
          c.draw_line(@g2d.Point::new(w * (0.18 : Float), h * (0.5 : Float)), @g2d.Point::new(w * (0.82 : Float), h * (0.5 : Float)), st)
          c.draw_line(@g2d.Point::new(w * (0.18 : Float), h * (0.72 : Float)), @g2d.Point::new(w * (0.82 : Float), h * (0.72 : Float)), st)
        }
        IconKind::ArrowBack => {
          c.draw_line(@g2d.Point::new(w * (0.8 : Float), h * (0.5 : Float)), @g2d.Point::new(w * (0.22 : Float), h * (0.5 : Float)), st)
          let p = @g2d.PathBuilder::new()
            .move_to(w * (0.46 : Float), h * (0.26 : Float))
            .line_to(w * (0.22 : Float), h * (0.5 : Float))
            .line_to(w * (0.46 : Float), h * (0.74 : Float))
            .build()
          c.draw_path(p, st)
        }
        IconKind::ArrowForward => {
          c.draw_line(@g2d.Point::new(w * (0.2 : Float), h * (0.5 : Float)), @g2d.Point::new(w * (0.78 : Float), h * (0.5 : Float)), st)
          let p = @g2d.PathBuilder::new()
            .move_to(w * (0.54 : Float), h * (0.26 : Float))
            .line_to(w * (0.78 : Float), h * (0.5 : Float))
            .line_to(w * (0.54 : Float), h * (0.74 : Float))
            .build()
          c.draw_path(p, st)
        }
        IconKind::ChevronDown => {
          let p = @g2d.PathBuilder::new()
            .move_to(w * (0.24 : Float), h * (0.36 : Float))
            .line_to(w * (0.5 : Float), h * (0.64 : Float))
            .line_to(w * (0.76 : Float), h * (0.36 : Float))
            .build()
          c.draw_path(p, st)
        }
        IconKind::Star => {
          let pts : Array[(Float, Float)] = [
            ((0.5 : Float), (0.12 : Float)),
            ((0.6 : Float), (0.38 : Float)),
            ((0.88 : Float), (0.4 : Float)),
            ((0.66 : Float), (0.58 : Float)),
            ((0.74 : Float), (0.85 : Float)),
            ((0.5 : Float), (0.7 : Float)),
            ((0.26 : Float), (0.85 : Float)),
            ((0.34 : Float), (0.58 : Float)),
            ((0.12 : Float), (0.4 : Float)),
            ((0.4 : Float), (0.38 : Float)),
          ]
          let pb = @g2d.PathBuilder::new()
          for i = 0; i < pts.length(); i = i + 1 {
            let (px, py) = pts[i]
            if i == 0 {
              let _ = pb.move_to(w * px, h * py)
            } else {
              let _ = pb.line_to(w * px, h * py)
            }
          }
          c.draw_path(pb.close().build(), fl)
        }
        IconKind::Settings => {
          c.draw_circle(@g2d.Point::new(w * (0.5 : Float), h * (0.5 : Float)), w * (0.24 : Float), st)
          c.draw_circle(@g2d.Point::new(w * (0.5 : Float), h * (0.5 : Float)), w * (0.08 : Float), fl)
        }
        IconKind::Info => {
          c.draw_circle(@g2d.Point::new(w * (0.5 : Float), h * (0.5 : Float)), w * (0.38 : Float), st)
          c.draw_circle(@g2d.Point::new(w * (0.5 : Float), h * (0.33 : Float)), sw * (0.6 : Float), fl)
          c.draw_line(@g2d.Point::new(w * (0.5 : Float), h * (0.46 : Float)), @g2d.Point::new(w * (0.5 : Float), h * (0.7 : Float)), st)
        }
        IconKind::Warning => {
          let p = @g2d.PathBuilder::new()
            .move_to(w * (0.5 : Float), h * (0.16 : Float))
            .line_to(w * (0.86 : Float), h * (0.82 : Float))
            .line_to(w * (0.14 : Float), h * (0.82 : Float))
            .close()
            .build()
          c.draw_path(p, st)
          c.draw_line(@g2d.Point::new(w * (0.5 : Float), h * (0.4 : Float)), @g2d.Point::new(w * (0.5 : Float), h * (0.62 : Float)), st)
          c.draw_circle(@g2d.Point::new(w * (0.5 : Float), h * (0.72 : Float)), sw * (0.55 : Float), fl)
        }
      }
    })
  })
}

///|
pub fn badge(
  key? : Key,
  label? : String = "",
  color? : @g2d.Color,
  child : Widget,
) -> Widget {
  builder(key?=key, tag=313, fn(ctx) {
    let th = ctx.theme()
    let bg = match color { Some(c) => c; None => th.colors.danger }
    let pill = if label == "" {
      container(width=(10.0 : Float), height=(10.0 : Float),
decoration=DecoratedProps::new(
  fill=bg,
  radius=(5.0 : Float),
))
    } else {
      container(
        pad=EdgeInsets::symmetric(horizontal=(6.0 : Float), vertical=(2.0 : Float)),
        child=text(label, size=(10.0 : Float), color=@g2d.Color::white()),
        decoration=DecoratedProps::new(
          fill=bg,
          radius=(9.0 : Float),
        )
      )
    }
    stack([
      child,
      positioned(right=(-4.0 : Float), top=(-4.0 : Float), pill),
    ])
  })
}

///|
pub fn text_button(
  key? : Key,
  label : String,
  on_pressed : () -> Unit,
  color? : @g2d.Color,
  pad? : EdgeInsets = EdgeInsets::symmetric(horizontal=(12.0 : Float), vertical=(8.0 : Float)),
) -> Widget {
  let hovered = Signal::new(false)
  builder(key?=key, tag=314, fn(ctx) {
    let th = ctx.theme()
    let is_h = hovered.get(ctx)
    let fg = match color { Some(c) => c; None => th.colors.primary }
    let bg = if is_h {
      @g2d.Color::rgba(fg.r, fg.g, fg.b, (0.12 : Float))
    } else {
      @g2d.Color::transparent()
    }
    mouse_region(
      on_enter=fn() { hovered.set(true) },
      on_exit=fn() { hovered.set(false) },
      cursor=@tycho.CursorShape::Pointer,
      gesture_detector(
        on_tap=on_pressed,
        container(
          pad=pad,
          child=text(label, size=(14.0 : Float), color=fg),
          decoration=DecoratedProps::new(
            fill=bg,
            radius=th.radius_sm,
          )
        ),
      ),
    )
  })
}

///|
pub fn icon_button(
  key? : Key,
  kind : IconKind,
  on_pressed : () -> Unit,
  size? : Float = (20.0 : Float),
  color? : @g2d.Color,
) -> Widget {
  let hovered = Signal::new(false)
  builder(key?=key, tag=315, fn(ctx) {
    let th = ctx.theme()
    let is_h = hovered.get(ctx)
    let bg = if is_h { th.colors.surface_variant } else { @g2d.Color::transparent() }
    mouse_region(
      on_enter=fn() { hovered.set(true) },
      on_exit=fn() { hovered.set(false) },
      cursor=@tycho.CursorShape::Pointer,
      gesture_detector(
        on_tap=on_pressed,
        container(
          pad=EdgeInsets::all((6.0 : Float)),
          child=icon(kind, size=size, color?=color),
          decoration=DecoratedProps::new(
            fill=bg,
            radius=th.radius_sm,
          )
        ),
      ),
    )
  })
}

///|
pub fn[T : Eq] radio(
  key? : Key,
  value : T,
  group_value : Signal[T],
  label? : String = "",
  on_changed? : ((T) -> Unit),
) -> Widget {
  builder(key?=key, tag=316, fn(ctx) {
    let th = ctx.theme()
    let selected = group_value.get(ctx) == value
    let outer_col = if selected { th.colors.primary } else { th.colors.border }
    let ring = container(
      width=(20.0 : Float),
      height=(20.0 : Float),
      child?=if selected {
        Some(
          center(
            container(
              width=(10.0 : Float),
              height=(10.0 : Float),
              decoration=DecoratedProps::new(
                fill=th.colors.primary,
                radius=(5.0 : Float),
              )
            ),
          ),
        )
      } else {
        None
      },
      decoration=DecoratedProps::new(
        fill=th.colors.surface,
        border_color=outer_col,
        border_width=(2.0 : Float),
        radius=(10.0 : Float),
      )
    )
    let content = if label == "" {
      ring
    } else {
      row(gap=(8.0 : Float), cross_axis=CrossAxisAlignment::Center, [
        ring,
        text(label, size=(14.0 : Float), color=th.colors.text_primary),
      ])
    }
    gesture_detector(
      on_tap=fn() {
        group_value.set(value)
        match on_changed {
          Some(f) => f(value)
          None => ()
        }
      },
      content,
    )
  })
}

///|
pub fn animated_opacity(
  key? : Key,
  target : Float,
  duration_sec? : Double = 0.25,
  curve? : Curve = Curve::EaseInOut,
  child : Widget,
) -> Widget {
  let ctrl = AnimationController::new(initial=target, duration_sec~, curve~)
  register_implicit_controller(ctrl)
  let prev = Ref(target)
  builder(key?=key, tag=317, fn(ctx) {
    if prev.val != target {
      prev.val = target
      ctrl.animate_to(target)
    }
    let cur_op = ctrl.value.get(ctx)
    opacity(cur_op, child)
  })
}

///|
pub fn animated_padding(
  key? : Key,
  pad : EdgeInsets,
  duration_sec? : Double = 0.25,
  curve? : Curve = Curve::EaseInOut,
  child : Widget,
) -> Widget {
  let ctrl = AnimationController::new(initial=(1.0 : Float), duration_sec~, curve~)
  register_implicit_controller(ctrl)
  let from_p = Ref(pad)
  let to_p = Ref(pad)
  builder(key?=key, tag=318, fn(ctx) {
    if to_p.val.left != pad.left ||
      to_p.val.top != pad.top ||
      to_p.val.right != pad.right ||
      to_p.val.bottom != pad.bottom {
      let cur_t = ctrl.value.peek()
      from_p.val = lerp_edge_insets(from_p.val, to_p.val, cur_t)
      to_p.val = pad
      ctrl.value.set((0.0 : Float))
      ctrl.animate_to((1.0 : Float))
    }
    let t = ctrl.value.get(ctx)
    padding(lerp_edge_insets(from_p.val, to_p.val, t), child)
  })
}

///|
pub fn animated_container(
  key? : Key,
  width? : Float,
  height? : Float,
  color? : @g2d.Color,
  radius? : Float = (0.0 : Float),
  pad? : EdgeInsets,
  duration_sec? : Double = 0.25,
  curve? : Curve = Curve::EaseInOut,
  child? : Widget,
) -> Widget {
  let ctrl = AnimationController::new(initial=(1.0 : Float), duration_sec~, curve~)
  register_implicit_controller(ctrl)
  let from_w = Ref(width)
  let to_w = Ref(width)
  let from_h = Ref(height)
  let to_h = Ref(height)
  let from_c = Ref(color)
  let to_c = Ref(color)
  let from_r = Ref(radius)
  let to_r = Ref(radius)
  builder(key?=key, tag=319, fn(ctx) {
    let changed = to_w.val != width ||
      to_h.val != height ||
      to_c.val != color ||
      to_r.val != radius
    if changed {
      let cur_t = ctrl.value.peek()
      from_w.val = match (from_w.val, to_w.val) {
        (Some(a), Some(b)) => Some(lerp_float(a, b, cur_t))
        _ => to_w.val
      }
      from_h.val = match (from_h.val, to_h.val) {
        (Some(a), Some(b)) => Some(lerp_float(a, b, cur_t))
        _ => to_h.val
      }
      from_c.val = match (from_c.val, to_c.val) {
        (Some(a), Some(b)) => Some(lerp_color(a, b, cur_t))
        _ => to_c.val
      }
      from_r.val = lerp_float(from_r.val, to_r.val, cur_t)
      to_w.val = width
      to_h.val = height
      to_c.val = color
      to_r.val = radius
      ctrl.value.set((0.0 : Float))
      ctrl.animate_to((1.0 : Float))
    }
    let t = ctrl.value.get(ctx)
    let w_now = match (from_w.val, to_w.val) {
      (Some(a), Some(b)) => Some(lerp_float(a, b, t))
      _ => to_w.val
    }
    let h_now = match (from_h.val, to_h.val) {
      (Some(a), Some(b)) => Some(lerp_float(a, b, t))
      _ => to_h.val
    }
    let c_now = match (from_c.val, to_c.val) {
      (Some(a), Some(b)) => Some(lerp_color(a, b, t))
      _ => to_c.val
    }
    let r_now = lerp_float(from_r.val, to_r.val, t)
    container(
      width?=w_now,
      height?=h_now,
      pad?=pad,
      child?=child,
      decoration=DecoratedProps::new(fill?=c_now, radius=r_now),
    )
  })
}

///|
pub fn scrollbar(
  key? : Key,
  controller : ScrollController,
  thickness? : Float = (8.0 : Float),
  child : Widget,
) -> Widget {
  let hovered = Signal::new(false)
  builder(key?=key, tag=320, fn(ctx) {
    let th = ctx.theme()
    let off = controller.offset.get(ctx)
    let vp = @tmath.max_f((1.0 : Float), controller.viewport_extent)
    let max_e = controller.max_extent
    let total = vp + max_e
    if max_e <= (0.5 : Float) {
      return child
    }
    let ratio = @tmath.clamp_f(vp / total, (0.12 : Float), (1.0 : Float))
    let thumb_h = @tmath.max_f((24.0 : Float), vp * ratio)
    let track_avail = @tmath.max_f((1.0 : Float), vp - thumb_h)
    let thumb_y = (off / max_e) * track_avail
    let is_h = hovered.get(ctx)
    let thumb_col = if is_h {
      th.colors.primary
    } else {
      @g2d.Color::rgba(th.colors.text_secondary.r, th.colors.text_secondary.g, th.colors.text_secondary.b, (0.55 : Float))
    }
    let thumb = mouse_region(
      on_enter=fn() { hovered.set(true) },
      on_exit=fn() { hovered.set(false) },
      cursor=@tycho.CursorShape::Pointer,
      gesture_detector(
        on_drag_update=fn(_p, delta) {
          let scale = max_e / track_avail
          controller.scroll_by(delta.y * scale)
        },
        container(
          width=thickness,
          height=thumb_h,
          decoration=DecoratedProps::new(
            fill=thumb_col,
            radius=thickness * (0.5 : Float),
          )
        ),
      ),
    )
    stack([
      child,
      positioned(
        right=(2.0 : Float),
        top=thumb_y,
        thumb,
      ),
    ])
  })
}

///|
pub(all) struct OverlayEntry {
  id : Int
  builder : (BuildContext) -> Widget
}

///|
pub struct OverlayController {
  entries : Signal[Array[OverlayEntry]]
  priv mut next_id : Int
}

///|
pub fn OverlayController::new() -> OverlayController {
  { entries: Signal::new([]), next_id: 1 }
}

///|
pub fn OverlayController::insert(
  self : OverlayController,
  entry_builder : (BuildContext) -> Widget,
) -> Int {
  let id = self.next_id
  self.next_id = id + 1
  self.entries.update(fn(arr) {
    let next = arr.copy()
    next.push({ id, builder: entry_builder })
    next
  })
  id
}

///|
pub fn OverlayController::remove(self : OverlayController, id : Int) -> Unit {
  self.entries.update(fn(arr) {
    let next : Array[OverlayEntry] = []
    for e in arr {
      if e.id != id {
        next.push(e)
      }
    }
    next
  })
}

///|
pub fn OverlayController::clear(self : OverlayController) -> Unit {
  self.entries.set([])
}

///|
pub fn overlay(
  key? : Key,
  controller : OverlayController,
  child : Widget,
) -> Widget {
  builder(key?=key, tag=321, fn(ctx) {
    let entries = controller.entries.get(ctx)
    let layers : Array[Widget] = [child]
    for e in entries {
      layers.push((e.builder)(ctx))
    }
    stack(layers)
  })
}

///|
pub fn tooltip(
  key? : Key,
  message : String,
  child : Widget,
) -> Widget {
  let hovered = Signal::new(false)
  builder(key?=key, tag=322, fn(ctx) {
    let th = ctx.theme()
    let show = hovered.get(ctx)
    let base = mouse_region(
      on_enter=fn() { hovered.set(true) },
      on_exit=fn() { hovered.set(false) },
      child,
    )
    if !show {
      return stack([base])
    }
    stack([
      base,
      positioned(
        left=(0.0 : Float),
        bottom=(-28.0 : Float),
        container(
          pad=EdgeInsets::symmetric(horizontal=(8.0 : Float), vertical=(4.0 : Float)),
          child=text(message, size=(11.0 : Float), color=@g2d.Color::white()),
          decoration=DecoratedProps::new(
            fill=@g2d.Color::rgba((0.08 : Float), (0.1 : Float), (0.14 : Float), (0.94 : Float)),
            border_color=th.colors.border,
            border_width=(1.0 : Float),
            radius=(4.0 : Float),
          )
        ),
      ),
    ])
  })
}

///|
pub(all) struct MenuItem {
  label : String
  icon : IconKind?
  on_selected : () -> Unit
}

///|
pub fn MenuItem::new(
  label : String,
  on_selected : () -> Unit,
  icon? : IconKind,
) -> MenuItem {
  { label, icon, on_selected }
}

///|
fn build_menu_card(
  th : ThemeData,
  items : Array[MenuItem],
  on_dismiss : () -> Unit,
) -> Widget {
  let rows : Array[Widget] = []
  for item in items {
    let item_cb = item.on_selected
    let row_child = match item.icon {
      Some(ic) =>
        row(gap=(8.0 : Float), cross_axis=CrossAxisAlignment::Center, [
          icon(ic, size=(15.0 : Float), color=th.colors.text_secondary),
          text(item.label, size=(13.0 : Float), color=th.colors.text_primary),
        ])
      None => text(item.label, size=(13.0 : Float), color=th.colors.text_primary)
    }
    rows.push(
      mouse_region(
        cursor=@tycho.CursorShape::Pointer,
        gesture_detector(
          on_tap=fn() {
            on_dismiss()
            item_cb()
          },
          container(
            pad=EdgeInsets::symmetric(horizontal=(12.0 : Float), vertical=(7.0 : Float)),
            child=row_child,
          ),
        ),
      ),
    )
  }
  container(
    pad=EdgeInsets::symmetric(vertical=(4.0 : Float)),
    child=column(gap=(2.0 : Float), rows),
    decoration=DecoratedProps::new(
      fill=th.colors.surface,
      border_color=th.colors.border,
      border_width=(1.0 : Float),
      radius=th.radius_sm,
      shadow_blur=(12.0 : Float),
      shadow_dy=(4.0 : Float),
      shadow_color=@g2d.Color::rgba((0.0 : Float), (0.0 : Float), (0.0 : Float), (0.45 : Float)),
    )
  )
}

///|
pub fn popup_menu(
  key? : Key,
  is_open : Signal[Bool],
  items : Array[MenuItem],
  anchor : Widget,
) -> Widget {
  builder(key?=key, tag=323, fn(ctx) {
    let th = ctx.theme()
    if !is_open.get(ctx) {
      return anchor
    }
    stack([
      anchor,
      positioned(
        left=(0.0 : Float),
        top=(38.0 : Float),
        build_menu_card(th, items, fn() { is_open.set(false) }),
      ),
    ])
  })
}

///|
pub fn context_menu(
  key? : Key,
  is_open : Signal[Bool],
  pos : Signal[@g2d.Point],
  items : Array[MenuItem],
  child : Widget,
) -> Widget {
  builder(key?=key, tag=324, fn(ctx) {
    let th = ctx.theme()
    if !is_open.get(ctx) {
      return child
    }
    let pt = pos.get(ctx)
    stack([
      child,
      positioned(
        left=pt.x,
        top=pt.y,
        build_menu_card(th, items, fn() { is_open.set(false) }),
      ),
    ])
  })
}

///|
pub(all) struct RouteEntry {
  name : String
  builder : (BuildContext) -> Widget
}

///|
pub struct NavigatorController {
  stack : Signal[Array[RouteEntry]]
  transition : AnimationController
}

///|
pub fn NavigatorController::new(
  initial_name : String,
  initial_builder : (BuildContext) -> Widget,
) -> NavigatorController {
  let trans = AnimationController::new(initial=(1.0 : Float), duration_sec=0.22, curve=Curve::EaseOut)
  register_implicit_controller(trans)
  { stack: Signal::new([{ name: initial_name, builder: initial_builder }]), transition: trans }
}

///|
pub fn NavigatorController::push(
  self : NavigatorController,
  name : String,
  route_builder : (BuildContext) -> Widget,
) -> Unit {
  self.stack.update(fn(arr) {
    let next = arr.copy()
    next.push({ name, builder: route_builder })
    next
  })
  self.transition.value.set((0.0 : Float))
  self.transition.animate_to((1.0 : Float))
}

///|
pub fn NavigatorController::replace(
  self : NavigatorController,
  name : String,
  route_builder : (BuildContext) -> Widget,
) -> Unit {
  self.stack.update(fn(arr) {
    let next = arr.copy()
    if next.length() > 0 {
      let _ = next.pop()
    }
    next.push({ name, builder: route_builder })
    next
  })
  self.transition.value.set((0.0 : Float))
  self.transition.animate_to((1.0 : Float))
}

///|
pub fn NavigatorController::can_pop(self : NavigatorController) -> Bool {
  self.stack.peek().length() > 1
}

///|
pub fn NavigatorController::pop(self : NavigatorController) -> Bool {
  if !self.can_pop() {
    return false
  }
  self.stack.update(fn(arr) {
    let next = arr.copy()
    let _ = next.pop()
    next
  })
  self.transition.value.set((0.0 : Float))
  self.transition.animate_to((1.0 : Float))
  true
}

///|
pub fn NavigatorController::current_name(self : NavigatorController) -> String {
  let s = self.stack.peek()
  if s.length() > 0 { s[s.length() - 1].name } else { "" }
}

///|
pub fn navigator(
  key? : Key,
  controller : NavigatorController,
) -> Widget {
  builder(key?=key, tag=325, fn(ctx) {
    let s = controller.stack.get(ctx)
    if s.length() == 0 {
      return sized_box()
    }
    let top = s[s.length() - 1]
    let t = controller.transition.value.get(ctx)
    let dx = ((1.0 : Float) - t) * (24.0 : Float)
    opacity(
      t,
      transform(
        @g2d.Matrix3::translate(dx, (0.0 : Float)),
        (top.builder)(ctx),
      ),
    )
  })
}
