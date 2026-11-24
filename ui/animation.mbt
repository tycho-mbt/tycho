// Curves, Spring physics, and frame-time AnimationController for laplaceliu/tycho_ui.

///|
pub(all) enum Curve {
  Linear
  EaseIn
  EaseOut
  EaseInOut
  CubicBezier(Float, Float, Float, Float)
}

///|
pub fn Curve::eval(self : Curve, t : Float) -> Float {
  let u = clamp_f(t, (0.0 : Float), (1.0 : Float))
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
  }
}

///|
pub fn lerp_float(a : Float, b : Float, t : Float) -> Float {
  a + (b - a) * clamp_f(t, (0.0 : Float), (1.0 : Float))
}

///|
pub fn lerp_color(a : @g2d.Color, b : @g2d.Color, t : Float) -> @g2d.Color {
  a.lerp(b, t)
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
