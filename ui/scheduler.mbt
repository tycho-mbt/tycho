// AppRunner (live interactive window loop) and WidgetTester (headless automated testing).

///|
const K_MOD_SHIFT : Int = 1

///|
const K_MOD_CTRL : Int = 4

///|
fn route_key_to_text_ctrl(
  tree : UiTree,
  key : Int,
  mods : Int,
  sc : @tycho.Swapchain?,
) -> Bool {
  let shift = (mods & K_MOD_SHIFT) != 0
  let ctrl = (mods & K_MOD_CTRL) != 0
  if key == @tycho.KEY_TAB {
    tree.cycle_text_focus(shift)
    return true
  }
  match tree.focused_text_controller() {
    Some(tc) => {
      if ctrl {
        if key == @tycho.KEY_A {
          tc.select_all()
          return true
        }
        if key == @tycho.KEY_C {
          let sel = tc.selected_text()
          if sel != "" {
            match sc {
              Some(s) => s.set_clipboard_text(sel)
              None => ()
            }
          }
          return true
        }
        if key == @tycho.KEY_X {
          let sel = tc.selected_text()
          if sel != "" {
            match sc {
              Some(s) => s.set_clipboard_text(sel)
              None => ()
            }
            let _ = tc.delete_selection()
          }
          return true
        }
        if key == @tycho.KEY_V {
          match sc {
            Some(s) => tc.insert_text(s.clipboard_text())
            None => ()
          }
          return true
        }
        if key == @tycho.KEY_Z {
          if shift { tc.redo() } else { tc.undo() }
          return true
        }
        if key == @tycho.KEY_Y {
          tc.redo()
          return true
        }
      }
      if key == @tycho.KEY_BACKSPACE {
        tc.backspace()
        return true
      }
      if key == 0xffff {
        tc.delete_forward()
        return true
      }
      if key == @tycho.KEY_LEFT {
        tc.move_left(select=shift)
        return true
      }
      if key == @tycho.KEY_RIGHT {
        tc.move_right(select=shift)
        return true
      }
      if key == 0xff50 {
        tc.move_home(select=shift)
        return true
      }
      if key == 0xff57 {
        tc.move_end(select=shift)
        return true
      }
      if key == @tycho.KEY_RETURN && tc.multiline {
        tc.insert_char('\n')
        return true
      }
      false
    }
    None => tree.focus.dispatch_key(key, mods)
  }
}

///|
pub struct AppRunner {
  dev : @tycho.Device
  renderer : @g2d.Renderer2D
  tree : UiTree
  arena : GestureArena
  controllers : Array[AnimationController]
  mut inspector_enabled : Bool
  priv mut last_stats : FrameStats
  priv mut last_gpu_ms : Double
  priv clear_color : @g2d.Color
}

///|
pub fn AppRunner::new(
  dev : @tycho.Device,
  root : Widget,
  theme? : ThemeData = ThemeData::dark(),
  clear_color? : @g2d.Color = ColorScheme::dark().background,
) -> AppRunner raise @tycho.RhiError {
  let renderer = @g2d.Renderer2D::new(dev)
  let tree = UiTree::new(theme~)
  tree.mount_root(root)
  {
    dev,
    renderer,
    tree,
    arena: GestureArena::new(),
    controllers: [],
    inspector_enabled: false,
    last_stats: {
      build_ms: 0.0,
      layout_ms: 0.0,
      paint_ms: 0.0,
      gpu_ms: 0.0,
      element_count: 0,
      render_count: 0,
    },
    last_gpu_ms: 0.0,
    clear_color,
  }
}

///|
pub fn AppRunner::add_animation(self : AppRunner, ctrl : AnimationController) -> Unit {
  self.controllers.push(ctrl)
}

///|
pub fn AppRunner::set_inspector(self : AppRunner, enabled : Bool) -> Unit {
  self.inspector_enabled = enabled
}

///|
pub fn AppRunner::stats(self : AppRunner) -> FrameStats {
  self.last_stats
}

///|
pub fn AppRunner::pump_frame(
  self : AppRunner,
  width : Float,
  height : Float,
  dt_sec? : Double = 0.016,
) -> @g2d.DisplayList {
  for c in self.controllers {
    let _ = c.tick(dt_sec)
  }
  let _ = tick_implicit_animations(dt_sec)
  let t0 = @tycho.Swapchain::time()
  self.tree.flush_builds()
  let t1 = @tycho.Swapchain::time()
  self.tree.layout_root(width, height)
  if self.tree.sync_list_viewports() {
    self.tree.flush_builds()
    self.tree.layout_root(width, height)
  }
  let t2 = @tycho.Swapchain::time()
  let base_dl = self.tree.build_display_list()
  let dl = if self.inspector_enabled {
    let c = @g2d.Canvas::new()
    c.draw_display_list(base_dl)
    self.tree.debug_paint_inspector(c)
    c.finish()
  } else {
    base_dl
  }
  let t3 = @tycho.Swapchain::time()
  self.last_stats = {
    build_ms: (t1 - t0) * 1000.0,
    layout_ms: (t2 - t1) * 1000.0,
    paint_ms: (t3 - t2) * 1000.0,
    gpu_ms: self.last_gpu_ms,
    element_count: self.tree.element_count(),
    render_count: self.tree.render_count(),
  }
  dl
}

///|
pub fn AppRunner::has_active_animations(self : AppRunner) -> Bool {
  for c in self.controllers {
    if c.is_animating() {
      return true
    }
  }
  has_active_implicit_animations()
}

///|
pub fn AppRunner::run_window(
  self : AppRunner,
  title : String,
  width : Int,
  height : Int,
  dirty_driven? : Bool = true,
) -> Unit raise @tycho.RhiError {
  let sc = self.dev.create_swapchain_desc(
    @tycho.SwapchainDesc::new(title, width, height, depth=false),
  )
  let mut prev_t = @tycho.Swapchain::time()
  let mut quit = false
  let mut needs_render = true
  let mut prev_w = sc.width()
  let mut prev_h = sc.height()
  while !quit && !sc.should_close() {
    let now_t = @tycho.Swapchain::time()
    let dt = if now_t > prev_t { now_t - prev_t } else { 0.016 }
    prev_t = now_t
    match self.tree.focused_text_controller() {
      Some(tc) => {
        let prev_vis = tc.blink_phase < 0.55
        tc.blink_phase = (tc.blink_phase + dt) % 1.0
        if (tc.blink_phase < 0.55) != prev_vis {
          needs_render = true
        }
      }
      None => ()
    }
    let dpr = Float::from_double(sc.content_scale())
    let inv_dpr = if dpr > (0.0 : Float) { (1.0 : Float) / dpr } else { (1.0 : Float) }
    let (mx_d, my_d) = sc.mouse_pos()
    let cur_pos = @g2d.Point::new(
      Float::from_double(mx_d) * inv_dpr,
      Float::from_double(my_d) * inv_dpr,
    )
    let hover_hits = self.tree.hit_test(cur_pos)
    self.arena.update_hover(hover_hits)
    sc.set_cursor_shape(self.arena.desired_cursor())

    for ev in sc.poll_events() {
      needs_render = true
      match ev {
        @tycho.Event::CloseRequested => quit = true
        @tycho.Event::KeyDown(k, mods) => {
          if k == @tycho.KEY_ESCAPE {
            if !self.tree.focus.dispatch_key(k, mods) {
              quit = true
            }
          } else {
            let _ = route_key_to_text_ctrl(self.tree, k, mods, Some(sc))
          }
        }
        @tycho.Event::TextInput(txt) =>
          match self.tree.focused_text_controller() {
            Some(tc) => tc.insert_text(txt)
            None => ()
          }
        @tycho.Event::KeyUp(_k, _mods) => ()
        @tycho.Event::MouseMove(x, y) => {
          let p = @g2d.Point::new(
            Float::from_int(x) * inv_dpr,
            Float::from_int(y) * inv_dpr,
          )
          self.arena.handle_move(0, p)
        }
        @tycho.Event::MouseDown(_btn, x, y) => {
          let p = @g2d.Point::new(
            Float::from_int(x) * inv_dpr,
            Float::from_int(y) * inv_dpr,
          )
          let hits = self.tree.hit_test(p)
          self.tree.clear_text_focus_except(None)
          self.arena.handle_down(0, p, hits)
        }
        @tycho.Event::MouseUp(_btn, x, y) => {
          let p = @g2d.Point::new(
            Float::from_int(x) * inv_dpr,
            Float::from_int(y) * inv_dpr,
          )
          let hits = self.tree.hit_test(p)
          self.arena.handle_up(0, p, hits.length() > 0)
        }
        @tycho.Event::MouseScroll(dx, dy) => {
          let hits = self.tree.hit_test(cur_pos)
          self.arena.handle_scroll(hits, Float::from_int(dx), Float::from_int(dy))
        }
        _ => ()
      }
    }
    let cur_w = sc.width()
    let cur_h = sc.height()
    if cur_w != prev_w || cur_h != prev_h {
      prev_w = cur_w
      prev_h = cur_h
      needs_render = true
    }
    if !dirty_driven ||
      needs_render ||
      self.has_active_animations() ||
      self.tree.has_pending_dirty() {
      let vw = Float::from_int(cur_w) * inv_dpr
      let vh = Float::from_int(cur_h) * inv_dpr
      let dl = self.pump_frame(vw, vh, dt_sec=dt)
      let scaled_canvas = @g2d.Canvas::new()
      if dpr != (1.0 : Float) && dpr > (0.0 : Float) {
        scaled_canvas.scale(dpr, dpr)
      }
      scaled_canvas.draw_display_list(dl)
      let g0 = @tycho.Swapchain::time()
      self.renderer.render_swapchain(
        sc,
        scaled_canvas.finish(),
        clear_color=self.clear_color,
      )
      let g1 = @tycho.Swapchain::time()
      self.last_gpu_ms = (g1 - g0) * 1000.0
      needs_render = false
    }
  }
  sc.destroy()
}

///|
pub fn AppRunner::destroy(self : AppRunner) -> Unit {
  self.renderer.destroy()
}

///|
// Headless WidgetTester for deterministic synthetic event & pixel Golden tests.
pub struct WidgetTester {
  tree : UiTree
  arena : GestureArena
  width : Float
  height : Float
}

///|
pub fn WidgetTester::new(
  root : Widget,
  width? : Float = (800.0 : Float),
  height? : Float = (600.0 : Float),
  theme? : ThemeData = ThemeData::dark(),
) -> WidgetTester {
  let tree = UiTree::new(theme~)
  tree.mount_root(root)
  let tester : WidgetTester = { tree, arena: GestureArena::new(), width, height }
  let _ = tester.pump_frame()
  tester
}

///|
pub fn WidgetTester::pump_frame(self : WidgetTester) -> @g2d.DisplayList {
  self.tree.flush_builds()
  self.tree.layout_root(self.width, self.height)
  if self.tree.sync_list_viewports() {
    self.tree.flush_builds()
    self.tree.layout_root(self.width, self.height)
  }
  self.tree.build_display_list()
}

///|
pub fn WidgetTester::move_mouse(self : WidgetTester, x : Float, y : Float) -> Unit {
  let pos = @g2d.Point::new(x, y)
  let hits = self.tree.hit_test(pos)
  self.arena.update_hover(hits)
  self.arena.handle_move(0, pos)
  let _ = self.pump_frame()
}

///|
pub fn WidgetTester::tap(self : WidgetTester, x : Float, y : Float) -> Unit {
  let pos = @g2d.Point::new(x, y)
  let hits = self.tree.hit_test(pos)
  self.tree.clear_text_focus_except(None)
  self.arena.handle_down(0, pos, hits)
  let hits_up = self.tree.hit_test(pos)
  self.arena.handle_up(0, pos, hits_up.length() > 0)
  let _ = self.pump_frame()
}

///|
pub fn WidgetTester::scroll(
  self : WidgetTester,
  x : Float,
  y : Float,
  dx : Float,
  dy : Float,
) -> Unit {
  let hits = self.tree.hit_test(@g2d.Point::new(x, y))
  self.arena.handle_scroll(hits, dx, dy)
  let _ = self.pump_frame()
}

///|
pub fn WidgetTester::send_key(
  self : WidgetTester,
  key : Int,
  shift? : Bool = false,
  ctrl? : Bool = false,
) -> Unit {
  let mods = (if shift { K_MOD_SHIFT } else { 0 }) | (if ctrl { K_MOD_CTRL } else { 0 })
  let _ = route_key_to_text_ctrl(self.tree, key, mods, None)
  let _ = self.pump_frame()
}

///|
pub fn WidgetTester::send_text(self : WidgetTester, text : String) -> Unit {
  match self.tree.focused_text_controller() {
    Some(tc) => tc.insert_text(text)
    None => ()
  }
  let _ = self.pump_frame()
}

///|
pub fn WidgetTester::element_count(self : WidgetTester) -> Int {
  self.tree.element_count()
}

///|
pub fn WidgetTester::render_to_texture(
  self : WidgetTester,
  renderer : @g2d.Renderer2D,
  target : @tycho.Texture,
  clear_color? : @g2d.Color = ColorScheme::dark().background,
) -> Unit raise @tycho.RhiError {
  let dl = self.pump_frame()
  renderer.render_offscreen(dl, target, clear_color~)
}
