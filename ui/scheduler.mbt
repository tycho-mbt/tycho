// AppRunner (live interactive window loop) and WidgetTester (headless automated testing).

///|
fn key_to_ascii(key : Int, shift : Bool) -> Char? {
  if key >= @tycho.KEY_A && key <= @tycho.KEY_Z {
    let base = if shift { 65 } else { 97 }
    return (base + (key - @tycho.KEY_A)).to_char()
  }
  if key >= @tycho.KEY_0 && key <= @tycho.KEY_9 {
    return (48 + (key - @tycho.KEY_0)).to_char()
  }
  if key == @tycho.KEY_SPACE {
    return Some(' ')
  }
  None
}

///|
fn route_key_to_text_ctrl(tree : UiTree, key : Int, shift : Bool) -> Bool {
  match tree.focused_text_controller() {
    Some(tc) => {
      if key == @tycho.KEY_BACKSPACE {
        tc.backspace()
        return true
      }
      if key == @tycho.KEY_LEFT {
        tc.move_left()
        return true
      }
      if key == @tycho.KEY_RIGHT {
        tc.move_right()
        return true
      }
      match key_to_ascii(key, shift) {
        Some(ch) => {
          tc.insert_char(ch)
          return true
        }
        None => ()
      }
      false
    }
    None => false
  }
}

///|
pub struct AppRunner {
  dev : @tycho.Device
  renderer : @g2d.Renderer2D
  tree : UiTree
  arena : GestureArena
  controllers : Array[AnimationController]
  priv mut last_stats : FrameStats
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
    last_stats: {
      build_ms: 0.0,
      layout_ms: 0.0,
      paint_ms: 0.0,
      gpu_ms: 0.0,
      element_count: 0,
      render_count: 0,
    },
    clear_color,
  }
}

///|
pub fn AppRunner::add_animation(self : AppRunner, ctrl : AnimationController) -> Unit {
  self.controllers.push(ctrl)
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
  self.tree.flush_builds()
  self.tree.layout_root(width, height)
  if self.tree.sync_list_viewports() {
    self.tree.flush_builds()
    self.tree.layout_root(width, height)
  }
  let dl = self.tree.build_display_list()
  self.last_stats = {
    build_ms: 0.0,
    layout_ms: 0.0,
    paint_ms: 0.0,
    gpu_ms: 0.0,
    element_count: self.tree.element_count(),
    render_count: self.tree.render_count(),
  }
  dl
}

///|
pub fn AppRunner::run_window(
  self : AppRunner,
  title : String,
  width : Int,
  height : Int,
) -> Unit raise @tycho.RhiError {
  let sc = self.dev.create_swapchain_desc(
    @tycho.SwapchainDesc::new(title, width, height, depth=false),
  )
  let mut shift_down = false
  let mut prev_t = @tycho.Swapchain::time()
  let mut quit = false
  while !quit && !sc.should_close() {
    let now_t = @tycho.Swapchain::time()
    let dt = if now_t > prev_t { now_t - prev_t } else { 0.016 }
    prev_t = now_t
    let dpr = Float::from_double(sc.content_scale())
    let inv_dpr = if dpr > (0.0 : Float) { (1.0 : Float) / dpr } else { (1.0 : Float) }
    let (mx_d, my_d) = sc.mouse_pos()
    let cur_pos = @g2d.Point::new(
      Float::from_double(mx_d) * inv_dpr,
      Float::from_double(my_d) * inv_dpr,
    )
    let hover_hits = self.tree.hit_test(cur_pos)
    self.arena.update_hover(hover_hits)

    for ev in sc.poll_events() {
      match ev {
        @tycho.Event::CloseRequested => quit = true
        @tycho.Event::KeyDown(k, _) => {
          if k == @tycho.KEY_ESCAPE {
            quit = true
          } else if k == @tycho.KEY_LSHIFT || k == @tycho.KEY_RSHIFT {
            shift_down = true
          } else {
            let _ = route_key_to_text_ctrl(self.tree, k, shift_down)
          }
        }
        @tycho.Event::KeyUp(k, _) =>
          if k == @tycho.KEY_LSHIFT || k == @tycho.KEY_RSHIFT {
            shift_down = false
          }
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
        @tycho.Event::MouseScroll(delta) => {
          let hits = self.tree.hit_test(cur_pos)
          self.arena.handle_scroll(hits, (0.0 : Float), Float::from_int(delta))
        }
        _ => ()
      }
    }
    let vw = Float::from_int(sc.width()) * inv_dpr
    let vh = Float::from_int(sc.height()) * inv_dpr
    let dl = self.pump_frame(vw, vh, dt_sec=dt)
    let scaled_canvas = @g2d.Canvas::new()
    if dpr != (1.0 : Float) && dpr > (0.0 : Float) {
      scaled_canvas.scale(dpr, dpr)
    }
    scaled_canvas.draw_display_list(dl)
    self.renderer.render_swapchain(
      sc,
      scaled_canvas.finish(),
      clear_color=self.clear_color,
    )
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
) -> Unit {
  let _ = route_key_to_text_ctrl(self.tree, key, shift)
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
