// High-level desktop UI controls (buttons, checkbox, switch, slider, card, dialog, performance overlay).

///|
pub fn divider(
  key? : Key? = None,
  height? : Float = (1.0 : Float),
  color? : @g2d.Color? = None,
) -> Widget {
  builder(key~, tag=301, fn(ctx) {
    let col = match color {
      Some(c) => c
      None => ctx.colors().border
    }
    constrained_box(
      BoxConstraints::new(min_width=INF, max_width=INF, min_height=height, max_height=height),
      container(color=Some(col)),
    )
  })
}

///|
pub fn card(
  key? : Key? = None,
  pad? : EdgeInsets = EdgeInsets::all((16.0 : Float)),
  radius? : Float? = None,
  color? : @g2d.Color? = None,
  border_color? : @g2d.Color? = None,
  shadow_blur? : Float = (12.0 : Float),
  child : Widget,
) -> Widget {
  builder(key~, tag=302, fn(ctx) {
    let th = ctx.theme()
    let bg = match color { Some(c) => c; None => th.colors.surface }
    let bc = match border_color { Some(c) => c; None => th.colors.border }
    let rad = match radius { Some(r) => r; None => th.radius_md }
    container(
      pad=Some(pad),
      color=Some(bg),
      border_color=Some(bc),
      border_width=(1.5 : Float),
      radius=rad,
      shadow_blur~,
      shadow_dy=(6.0 : Float),
      shadow_color=Some(@g2d.Color::rgba((0.0 : Float), (0.0 : Float), (0.02 : Float), (0.45 : Float))),
      child=Some(child),
    )
  })
}

///|
pub fn filled_button(
  key? : Key? = None,
  label : String,
  on_pressed : () -> Unit,
  color? : @g2d.Color? = None,
  pad? : EdgeInsets = EdgeInsets::symmetric(horizontal=(16.0 : Float), vertical=(10.0 : Float)),
) -> Widget {
  let hovered = Signal::new(false)
  builder(key~, tag=303, fn(ctx) {
    let th = ctx.theme()
    let is_h = hovered.get(ctx)
    let base = match color { Some(c) => c; None => th.colors.primary }
    let bg = if is_h { base.lerp(@g2d.Color::white(), (0.16 : Float)) } else { base }
    mouse_region(
      on_enter=Some(fn() { hovered.set(true) }),
      on_exit=Some(fn() { hovered.set(false) }),
      gesture_detector(
        on_tap=Some(on_pressed),
        container(
          pad=Some(pad),
          color=Some(bg),
          radius=th.radius_sm,
          child=Some(text(label, size=(14.0 : Float), color=Some(th.colors.on_primary))),
        ),
      ),
    )
  })
}

///|
pub fn outlined_button(
  key? : Key? = None,
  label : String,
  on_pressed : () -> Unit,
  pad? : EdgeInsets = EdgeInsets::symmetric(horizontal=(16.0 : Float), vertical=(10.0 : Float)),
) -> Widget {
  let hovered = Signal::new(false)
  builder(key~, tag=304, fn(ctx) {
    let th = ctx.theme()
    let is_h = hovered.get(ctx)
    let bg = if is_h { th.colors.surface_variant } else { th.colors.surface }
    mouse_region(
      on_enter=Some(fn() { hovered.set(true) }),
      on_exit=Some(fn() { hovered.set(false) }),
      gesture_detector(
        on_tap=Some(on_pressed),
        container(
          pad=Some(pad),
          color=Some(bg),
          border_color=Some(th.colors.primary),
          border_width=(1.5 : Float),
          radius=th.radius_sm,
          child=Some(text(label, size=(14.0 : Float), color=Some(th.colors.primary))),
        ),
      ),
    )
  })
}

///|
pub fn checkbox(
  key? : Key? = None,
  checked : Signal[Bool],
  label? : String = "",
  on_changed? : ((Bool) -> Unit)? = None,
) -> Widget {
  builder(key~, tag=305, fn(ctx) {
    let th = ctx.theme()
    let val = checked.get(ctx)
    let box_bg = if val { th.colors.primary } else { th.colors.surface_variant }
    let box_border = if val { th.colors.primary } else { th.colors.border }
    let check_mark = if val {
      Some(
        container(
          width=Some((10.0 : Float)),
          height=Some((10.0 : Float)),
          color=Some(th.colors.on_primary),
          radius=(2.0 : Float),
        ),
      )
    } else {
      None
    }
    let box_w = container(
      width=Some((20.0 : Float)),
      height=Some((20.0 : Float)),
      color=Some(box_bg),
      border_color=Some(box_border),
      border_width=(1.5 : Float),
      radius=(5.0 : Float),
      alignment=Some(Alignment::center()),
      child=check_mark,
    )
    let kids : Array[Widget] = [box_w]
    if label != "" {
      kids.push(text(label, size=(14.0 : Float), color=Some(th.colors.text_primary)))
    }
    gesture_detector(
      on_tap=Some(fn() {
        let nv = !checked.peek()
        checked.set(nv)
        match on_changed {
          Some(f) => f(nv)
          None => ()
        }
      }),
      row(gap=(10.0 : Float), main_size=MainAxisSize::Min, kids),
    )
  })
}

///|
pub fn switch_toggle(
  key? : Key? = None,
  value : Signal[Bool],
  label? : String = "",
  on_changed? : ((Bool) -> Unit)? = None,
) -> Widget {
  builder(key~, tag=306, fn(ctx) {
    let th = ctx.theme()
    let on = value.get(ctx)
    let track_bg = if on { th.colors.secondary } else { th.colors.surface_variant }
    let track_w = (44.0 : Float)
    let track_h = (24.0 : Float)
    let knob_x = if on { (22.0 : Float) } else { (3.0 : Float) }
    let track = container(
      width=Some(track_w),
      height=Some(track_h),
      color=Some(track_bg),
      border_color=Some(if on { th.colors.secondary } else { th.colors.border }),
      border_width=(1.0 : Float),
      radius=(12.0 : Float),
      child=Some(
        stack([
          positioned(
            left=Some(knob_x),
            top=Some((3.0 : Float)),
            width=Some((18.0 : Float)),
            height=Some((18.0 : Float)),
            container(color=Some(@g2d.Color::white()), radius=(9.0 : Float)),
          ),
        ]),
      ),
    )
    let kids : Array[Widget] = [track]
    if label != "" {
      kids.push(text(label, size=(14.0 : Float), color=Some(th.colors.text_primary)))
    }
    gesture_detector(
      on_tap=Some(fn() {
        let nv = !value.peek()
        value.set(nv)
        match on_changed {
          Some(f) => f(nv)
          None => ()
        }
      }),
      row(gap=(10.0 : Float), main_size=MainAxisSize::Min, kids),
    )
  })
}

///|
pub fn progress_bar(
  key? : Key? = None,
  value : Float,
  width? : Float = (200.0 : Float),
  height? : Float = (10.0 : Float),
  color? : @g2d.Color? = None,
) -> Widget {
  builder(key~, tag=307, fn(ctx) {
    let th = ctx.theme()
    let t = clamp_f(value, (0.0 : Float), (1.0 : Float))
    let fill = match color { Some(c) => c; None => th.colors.primary }
    let rad = height * (0.5 : Float)
    container(
      width=Some(width),
      height=Some(height),
      color=Some(th.colors.surface_variant),
      radius=rad,
      child=Some(
        stack([
          positioned(
            left=Some((0.0 : Float)),
            top=Some((0.0 : Float)),
            width=Some(max_f(height, width * t)),
            height=Some(height),
            container(color=Some(fill), radius=rad),
          ),
        ]),
      ),
    )
  })
}

///|
pub fn slider(
  key? : Key? = None,
  value : Signal[Float],
  width? : Float = (220.0 : Float),
) -> Widget {
  builder(key~, tag=308, fn(ctx) {
    let th = ctx.theme()
    let v = clamp_f(value.get(ctx), (0.0 : Float), (1.0 : Float))
    let h = (24.0 : Float)
    let knob_r = (9.0 : Float)
    let usable = max_f((1.0 : Float), width - knob_r * (2.0 : Float))
    let kx = v * usable
    gesture_detector(
      on_drag_start=Some(fn(pos) {
        let nv = clamp_f((pos.x - knob_r) / usable, (0.0 : Float), (1.0 : Float))
        value.set(nv)
      }),
      on_drag_update=Some(fn(pos, _d) {
        let nv = clamp_f((pos.x - knob_r) / usable, (0.0 : Float), (1.0 : Float))
        value.set(nv)
      }),
      container(
        width=Some(width),
        height=Some(h),
        child=Some(
          stack([
            positioned(
              left=Some((0.0 : Float)),
              top=Some((8.0 : Float)),
              width=Some(width),
              height=Some((8.0 : Float)),
              container(color=Some(th.colors.surface_variant), radius=(4.0 : Float)),
            ),
            positioned(
              left=Some((0.0 : Float)),
              top=Some((8.0 : Float)),
              width=Some(max_f((8.0 : Float), kx + knob_r)),
              height=Some((8.0 : Float)),
              container(color=Some(th.colors.primary), radius=(4.0 : Float)),
            ),
            positioned(
              left=Some(kx),
              top=Some((3.0 : Float)),
              width=Some(knob_r * (2.0 : Float)),
              height=Some(knob_r * (2.0 : Float)),
              container(
                color=Some(@g2d.Color::white()),
                border_color=Some(th.colors.primary),
                border_width=(2.0 : Float),
                radius=knob_r,
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
  key? : Key? = None,
  title : String,
  body : Widget,
  on_close : () -> Unit,
  width? : Float = (360.0 : Float),
) -> Widget {
  builder(key~, tag=309, fn(ctx) {
    let th = ctx.theme()
    stack([
      gesture_detector(
        on_tap=Some(on_close),
        container(color=Some(@g2d.Color::rgba((0.0 : Float), (0.0 : Float), (0.0 : Float), (0.45 : Float)))),
      ),
      center(
        container(
          width=Some(width),
          child=Some(
            backdrop_filter(
              blur_sigma=(16.0 : Float),
              radius=th.radius_lg,
              tint=if th.colors.is_dark {
                @g2d.Color::rgba((0.10 : Float), (0.14 : Float), (0.24 : Float), (0.78 : Float))
              } else {
                @g2d.Color::rgba((0.96 : Float), (0.97 : Float), (1.0 : Float), (0.82 : Float))
              },
              container(
                pad=Some(EdgeInsets::all((20.0 : Float))),
                border_color=Some(th.colors.border),
                border_width=(1.5 : Float),
                radius=th.radius_lg,
                child=Some(
                  column(gap=(12.0 : Float), [
                    text(title, size=(18.0 : Float), color=Some(th.colors.text_primary)),
                    divider(),
                    body,
                    row(main_axis=MainAxisAlignment::End, [
                      filled_button("Close", on_close),
                    ]),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    ])
  })
}

///|
pub fn performance_overlay(stats : FrameStats) -> Widget {
  builder(tag=310, fn(ctx) {
    let th = ctx.theme()
    let gpu_str = "GPU \{stats.gpu_ms}ms | E:\{stats.element_count} R:\{stats.render_count}"
    container(
      pad=Some(EdgeInsets::symmetric(horizontal=(10.0 : Float), vertical=(6.0 : Float))),
      color=Some(@g2d.Color::rgba((0.05 : Float), (0.07 : Float), (0.12 : Float), (0.85 : Float))),
      border_color=Some(th.colors.border),
      border_width=(1.0 : Float),
      radius=(6.0 : Float),
      child=Some(
        text(gpu_str, size=(11.0 : Float), color=Some(@g2d.Color::from_rgba8(120, 236, 175))),
      ),
    )
  })
}
