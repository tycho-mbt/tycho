// Curves, Spring physics, and frame-time AnimationController for laplaceliu/tycho_ui.

///|
pub(all) enum Curve {
  Linear
  EaseIn
  EaseOut
  EaseInOut
  CubicBezier(Float, Float, Float, Float)
  Spring(Float, Float, Float) // stiffness, damping, mass
}

///|
pub fn Curve::eval(self : Curve, t : Float) -> Float {
  let u = @tmath.clamp_f(t, (0.0 : Float), (1.0 : Float))
  match self {
    Linear => u
    EaseIn => u * u * u
    EaseOut => {
      let inv = (1.0 : Float) - u
      (1.0 : Float) - inv * inv * inv
    }
    EaseInOut =>
      if u < (0.5 : Float) {
        (4.0 : Float) * u * u * u
      } else {
        let f = (-2.0 : Float) * u + (2.0 : Float)
        (1.0 : Float) - f * f * f * (0.5 : Float)
      }
    CubicBezier(_x1, y1, _x2, y2) => {
      let omt = (1.0 : Float) - u
      (3.0 : Float) * omt * omt * u * y1 +
      (3.0 : Float) * omt * u * u * y2 +
      u * u * u
    }
    Spring(stiffness, damping, mass) => {
      if u <= (0.0 : Float) {
        return (0.0 : Float)
      }
      if u >= (1.0 : Float) {
        return (1.0 : Float)
      }
      let m = if mass > (0.01 : Float) { mass } else { (1.0 : Float) }
      let k = if stiffness > (1.0 : Float) { stiffness } else { (180.0 : Float) }
      let c = if damping > (0.1 : Float) { damping } else { (18.0 : Float) }
      let steps = 24
      let dt = u / Float::from_int(steps)
      let mut x = (0.0 : Float)
      let mut v = (0.0 : Float)
      for _i = 0; _i < steps; _i = _i + 1 {
        let a = (k * ((1.0 : Float) - x) - c * v) / m
        v = v + a * dt
        x = x + v * dt
      }
      x
    }
  }
}

///|
pub fn lerp_float(a : Float, b : Float, t : Float) -> Float {
  @tmath.lerp_f(a, b, @tmath.saturate(t))
}

///|
pub fn lerp_color(a : @g2d.Color, b : @g2d.Color, t : Float) -> @g2d.Color {
  a.lerp(b, t)
}

///|
pub fn lerp_rect(a : @g2d.Rect, b : @g2d.Rect, t : Float) -> @g2d.Rect {
  @g2d.Rect::new(
    lerp_float(a.x, b.x, t),
    lerp_float(a.y, b.y, t),
    lerp_float(a.width, b.width, t),
    lerp_float(a.height, b.height, t),
  )
}

///|
pub fn lerp_rrect(a : @g2d.RRect, b : @g2d.RRect, t : Float) -> @g2d.RRect {
  {
    rect: lerp_rect(a.rect, b.rect, t),
    tl: lerp_float(a.tl, b.tl, t),
    tl_y: lerp_float(a.tl_y, b.tl_y, t),
    tr: lerp_float(a.tr, b.tr, t),
    tr_y: lerp_float(a.tr_y, b.tr_y, t),
    br: lerp_float(a.br, b.br, t),
    br_y: lerp_float(a.br_y, b.br_y, t),
    bl: lerp_float(a.bl, b.bl, t),
    bl_y: lerp_float(a.bl_y, b.bl_y, t),
  }
}

///|
pub fn lerp_edge_insets(a : EdgeInsets, b : EdgeInsets, t : Float) -> EdgeInsets {
  {
    left: lerp_float(a.left, b.left, t),
    top: lerp_float(a.top, b.top, t),
    right: lerp_float(a.right, b.right, t),
    bottom: lerp_float(a.bottom, b.bottom, t),
  }
}

///|
pub struct AnimationController {
  value : Signal[Float]
  priv mut start_val : Float
  priv mut target_val : Float
  priv duration_sec : Double
  priv mut elapsed_sec : Double
  priv mut running : Bool
  priv curve : Curve
}

///|
pub fn AnimationController::new(
  initial? : Float = (0.0 : Float),
  duration_sec? : Double = 0.25,
  curve? : Curve = Curve::EaseOut,
) -> AnimationController {
  {
    value: Signal::new(initial),
    start_val: initial,
    target_val: initial,
    duration_sec: if duration_sec > 0.0 { duration_sec } else { 0.001 },
    elapsed_sec: 0.0,
    running: false,
    curve,
  }
}

///|
pub fn AnimationController::animate_to(
  self : AnimationController,
  target : Float,
) -> Unit {
  if self.target_val == target && !self.running {
    return
  }
  self.start_val = self.value.peek()
  self.target_val = target
  self.elapsed_sec = 0.0
  self.running = true
}

///|
pub fn AnimationController::is_animating(self : AnimationController) -> Bool {
  self.running
}

///|
pub fn AnimationController::tick(self : AnimationController, dt_sec : Double) -> Bool {
  if !self.running {
    return false
  }
  self.elapsed_sec = self.elapsed_sec + dt_sec
  let raw_t = Float::from_double(self.elapsed_sec / self.duration_sec)
  let k = self.curve.eval(raw_t)
  self.value.set(lerp_float(self.start_val, self.target_val, k))
  if raw_t >= (1.0 : Float) {
    self.value.set(self.target_val)
    self.running = false
  }
  true
}

///|
let g_implicit_controllers : Array[AnimationController] = []

///|
pub fn register_implicit_controller(ctrl : AnimationController) -> Unit {
  g_implicit_controllers.push(ctrl)
}

///|
pub fn tick_implicit_animations(dt_sec : Double) -> Bool {
  let mut any_active = false
  for c in g_implicit_controllers {
    if c.tick(dt_sec) {
      any_active = true
    }
  }
  any_active
}

///|
pub fn has_active_implicit_animations() -> Bool {
  for c in g_implicit_controllers {
    if c.is_animating() {
      return true
    }
  }
  false
}
