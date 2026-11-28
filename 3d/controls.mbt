// Pointer/keyboard camera controllers.
//
// Both consume `@tycho.Event` and produce a `Transform` for a camera node, so
// applications do not reimplement orbit/fly input math (M1 requirement).
//
// Orbit convention: `pitch > 0` places the camera above the target; `yaw`
// rotates around +Y. Mouse drag orbits, scroll zooms, both clamped.

///|
fn clamp_pitch(v : Float) -> Float {
  if v > 1.45 {
    1.45
  } else if v < -1.45 {
    -1.45
  } else {
    v
  }
}

///|
pub struct OrbitCamera {
  priv mut target : @tmath.Vec3
  priv mut distance : Float
  priv mut yaw : Float
  priv mut pitch : Float
  priv mut dragging : Bool
  priv mut last_x : Int
  priv mut last_y : Int
  priv min_distance : Float
  priv max_distance : Float
  priv rotate_speed : Float
  priv zoom_step : Float
}

///|
pub fn OrbitCamera::new(
  target? : @tmath.Vec3 = @tmath.Vec3::zero(),
  distance? : Float = 5.0,
  yaw? : Float = 0.0,
  pitch? : Float = 0.35,
) -> OrbitCamera {
  {
    target,
    distance,
    yaw,
    pitch,
    dragging: false,
    last_x: 0,
    last_y: 0,
    min_distance: 0.5,
    max_distance: 200.0,
    rotate_speed: 0.006,
    zoom_step: 0.12,
  }
}

///|
pub fn OrbitCamera::target(self : OrbitCamera) -> @tmath.Vec3 {
  self.target
}

///|
pub fn OrbitCamera::distance(self : OrbitCamera) -> Float {
  self.distance
}

///|
pub fn OrbitCamera::yaw(self : OrbitCamera) -> Float {
  self.yaw
}

///|
pub fn OrbitCamera::pitch(self : OrbitCamera) -> Float {
  self.pitch
}

///|
pub fn OrbitCamera::set_target(self : OrbitCamera, target : @tmath.Vec3) -> Unit {
  self.target = target
}

///|
pub fn OrbitCamera::set_yaw(self : OrbitCamera, yaw : Float) -> Unit {
  self.yaw = yaw
}

///|
pub fn OrbitCamera::set_pitch(self : OrbitCamera, pitch : Float) -> Unit {
  self.pitch = clamp_pitch(pitch)
}

///|
pub fn OrbitCamera::set_distance(self : OrbitCamera, distance : Float) -> Unit {
  self.distance = if distance < self.min_distance {
    self.min_distance
  } else if distance > self.max_distance {
    self.max_distance
  } else {
    distance
  }
}

///|
pub fn OrbitCamera::position(self : OrbitCamera) -> @tmath.Vec3 {
  let cp = @tmath.cos(self.pitch)
  let sp = @tmath.sin(self.pitch)
  let cy = @tmath.cos(self.yaw)
  let sy = @tmath.sin(self.yaw)
  let offset = @tmath.Vec3::new(
    cp * sy * self.distance,
    sp * self.distance,
    cp * cy * self.distance,
  )
  self.target + offset
}

///|
pub fn OrbitCamera::transform(self : OrbitCamera) -> @tmath.Transform {
  let pos = self.position()
  let forward = (self.target - pos).normalize()
  @tmath.Transform::new(
    pos,
    @tmath.Quat::from_rotation_arc(@tmath.Vec3::neg_z(), forward),
    @tmath.Vec3::one(),
  )
}

///|
/// Returns true when the event changed the orbit state.
pub fn OrbitCamera::apply(self : OrbitCamera, ev : @tycho.Event) -> Bool {
  match ev {
    @tycho.Event::MouseDown(btn, mx, my) =>
      if btn == @tycho.MouseButton::Left || btn == @tycho.MouseButton::Right {
        self.dragging = true
        self.last_x = mx
        self.last_y = my
        true
      } else {
        false
      }
    @tycho.Event::MouseUp(btn, _, _) =>
      if btn == @tycho.MouseButton::Left || btn == @tycho.MouseButton::Right {
        self.dragging = false
        true
      } else {
        false
      }
    @tycho.Event::MouseMove(mx, my) =>
      if self.dragging {
        self.yaw = self.yaw - f_of_int(mx - self.last_x) * self.rotate_speed
        self.pitch = clamp_pitch(
          self.pitch + f_of_int(my - self.last_y) * self.rotate_speed,
        )
        self.last_x = mx
        self.last_y = my
        true
      } else {
        false
      }
    @tycho.Event::MouseScroll(_, dy) => {
      let factor : Float = 1.0 - f_of_int(dy) * self.zoom_step
      self.set_distance(self.distance * factor)
      true
    }
    _ => false
  }
}

///|
pub struct FlyCamera {
  priv mut position : @tmath.Vec3
  priv mut yaw : Float
  priv mut pitch : Float
  priv mut dragging : Bool
  priv mut last_x : Int
  priv mut last_y : Int
  priv speed : Float
  priv rotate_speed : Float
}

///|
pub fn FlyCamera::new(
  position? : @tmath.Vec3 = @tmath.Vec3::zero(),
  yaw? : Float = 0.0,
  pitch? : Float = 0.0,
) -> FlyCamera {
  {
    position,
    yaw,
    pitch,
    dragging: false,
    last_x: 0,
    last_y: 0,
    speed: 0.18,
    rotate_speed: 0.006,
  }
}

///|
pub fn FlyCamera::position(self : FlyCamera) -> @tmath.Vec3 {
  self.position
}

///|
pub fn FlyCamera::yaw(self : FlyCamera) -> Float {
  self.yaw
}

///|
pub fn FlyCamera::pitch(self : FlyCamera) -> Float {
  self.pitch
}

///|
pub fn FlyCamera::rotation(self : FlyCamera) -> @tmath.Quat {
  @tmath.Quat::from_rotation_y(self.yaw) * @tmath.Quat::from_rotation_x(self.pitch)
}

///|
pub fn FlyCamera::transform(self : FlyCamera) -> @tmath.Transform {
  @tmath.Transform::new(self.position, self.rotation(), @tmath.Vec3::one())
}

///|
/// Returns true when the event changed the fly state.
pub fn FlyCamera::apply(self : FlyCamera, ev : @tycho.Event) -> Bool {
  match ev {
    @tycho.Event::KeyDown(k, _) => {
      let rot = self.rotation()
      let step = self.speed
      if k == @tycho.KeyCode::W {
        self.position = self.position + rot.mul_vec3(@tmath.Vec3::neg_z()).scale(step)
        true
      } else if k == @tycho.KeyCode::S {
        self.position = self.position - rot.mul_vec3(@tmath.Vec3::neg_z()).scale(step)
        true
      } else if k == @tycho.KeyCode::A {
        self.position = self.position - rot.mul_vec3(@tmath.Vec3::unit_x()).scale(step)
        true
      } else if k == @tycho.KeyCode::D {
        self.position = self.position + rot.mul_vec3(@tmath.Vec3::unit_x()).scale(step)
        true
      } else if k == @tycho.KeyCode::E {
        self.position = self.position + @tmath.Vec3::unit_y().scale(step)
        true
      } else if k == @tycho.KeyCode::Q {
        self.position = self.position - @tmath.Vec3::unit_y().scale(step)
        true
      } else if k == @tycho.KeyCode::Left {
        self.yaw = self.yaw - 0.06
        true
      } else if k == @tycho.KeyCode::Right {
        self.yaw = self.yaw + 0.06
        true
      } else if k == @tycho.KeyCode::Up {
        self.pitch = clamp_pitch(self.pitch + 0.05)
        true
      } else if k == @tycho.KeyCode::Down {
        self.pitch = clamp_pitch(self.pitch - 0.05)
        true
      } else {
        false
      }
    }
    @tycho.Event::MouseDown(btn, mx, my) =>
      if btn == @tycho.MouseButton::Left || btn == @tycho.MouseButton::Right {
        self.dragging = true
        self.last_x = mx
        self.last_y = my
        true
      } else {
        false
      }
    @tycho.Event::MouseUp(btn, _, _) =>
      if btn == @tycho.MouseButton::Left || btn == @tycho.MouseButton::Right {
        self.dragging = false
        true
      } else {
        false
      }
    @tycho.Event::MouseMove(mx, my) =>
      if self.dragging {
        self.yaw = self.yaw + f_of_int(mx - self.last_x) * self.rotate_speed
        self.pitch = clamp_pitch(
          self.pitch - f_of_int(my - self.last_y) * self.rotate_speed,
        )
        self.last_x = mx
        self.last_y = my
        true
      } else {
        false
      }
    _ => false
  }
}
