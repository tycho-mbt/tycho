// Multi-clip animation mixing (three.js `AnimationMixer` / `AnimationAction`).
//
// `AnimationPlayer` plays exactly one clip. Real characters need several at
// once: idle + walk blended by speed, a hit reaction fading in over the base
// locomotion, a loop that ping-pongs. `AnimationMixer` owns any number of
// actions, advances each one's local time (repeat / once / ping-pong), and
// blends their sampled transforms by weight before writing the scene.
//
// Blending is normalized: with a single active action at weight 0.5 the pose is
// the action's full pose, not a half-blend with the rest pose. Translation and
// scale accumulate as weighted sums, rotations as incremental normalized slerp.
// Channels whose node was destroyed are skipped, so an action can outlive part
// of the scene it was built for.

///|
/// Playback loop behaviour of one action (three.js `LoopOnce` / `LoopRepeat` /
/// `LoopPingPong`).
pub(all) enum LoopMode {
  /// Wrap to the start at the end (the default).
  Repeat
  /// Clamp at the last keyframe and stop the action.
  Once
  /// Reverse direction at each end.
  PingPong
}

///|
/// One clip bound to a mixer. Actions are owned by their `AnimationMixer`; the
/// value returned by `AnimationMixer::add` / `action` refers to the live action,
/// so `play` / `fade_in` / `seek` mutate what the mixer will sample next frame.
pub struct AnimationAction {
  clip : AnimationClip
  priv mut time : Float
  priv mut weight : Float
  priv mut speed : Float
  priv mut loop_mode : LoopMode
  priv mut playing : Bool
  priv mut paused : Bool
  priv mut finished : Bool
  priv mut direction : Float
  priv mut fade_weight : Float
  priv mut fade_from : Float
  priv mut fade_to : Float
  priv mut fade_elapsed : Float
  priv mut fade_duration : Float
}

///|
fn AnimationAction::new(clip : AnimationClip) -> AnimationAction {
  {
    clip,
    time: 0.0,
    weight: 1.0,
    speed: 1.0,
    loop_mode: LoopMode::Repeat,
    playing: true,
    paused: false,
    finished: false,
    direction: 1.0,
    fade_weight: 1.0,
    fade_from: 1.0,
    fade_to: 1.0,
    fade_elapsed: 0.0,
    fade_duration: 0.0,
  }
}

///|
/// Clip name this action plays.
pub fn AnimationAction::name(self : AnimationAction) -> String {
  self.clip.name
}

///|
/// Clip duration in seconds.
pub fn AnimationAction::duration(self : AnimationAction) -> Float {
  self.clip.duration()
}

///|
/// Local playback time, in seconds.
pub fn AnimationAction::time(self : AnimationAction) -> Float {
  self.time
}

///|
/// Current user weight in `[0, 1]`; fades multiply it by an internal factor.
pub fn AnimationAction::weight(self : AnimationAction) -> Float {
  self.weight
}

///|
/// Set the user weight (clamped to `[0, 1]`).
pub fn AnimationAction::set_weight(self : AnimationAction, weight : Float) -> Unit {
  self.weight = @tmath.saturate(weight)
}

///|
/// Playback speed multiplier (negative values run the clip backwards).
pub fn AnimationAction::speed(self : AnimationAction) -> Float {
  self.speed
}

///|
/// Set the playback speed multiplier.
pub fn AnimationAction::set_speed(self : AnimationAction, speed : Float) -> Unit {
  self.speed = speed
}

///|
pub fn AnimationAction::loop_mode(self : AnimationAction) -> LoopMode {
  self.loop_mode
}

///|
/// Change the loop behaviour; switching to `Once` clears the finished flag.
pub fn AnimationAction::set_loop(self : AnimationAction, mode : LoopMode) -> Unit {
  self.loop_mode = mode
  match mode {
    Once => self.finished = false
    _ => ()
  }
}

///|
/// Start (or resume) the action. A finished `Once` action restarts from zero.
pub fn AnimationAction::play(self : AnimationAction) -> Unit {
  if self.finished {
    self.time = 0.0
    self.finished = false
  }
  self.playing = true
  self.paused = false
}

///|
/// Freeze the action at its current time; the pose still contributes its weight.
pub fn AnimationAction::pause(self : AnimationAction) -> Unit {
  self.paused = true
}

///|
/// Stop and rewind; the action contributes nothing until `play`.
pub fn AnimationAction::stop(self : AnimationAction) -> Unit {
  self.playing = false
  self.paused = false
  self.finished = false
  self.time = 0.0
  self.direction = 1.0
  self.fade_weight = 1.0
  self.fade_from = 1.0
  self.fade_to = 1.0
  self.fade_elapsed = 0.0
  self.fade_duration = 0.0
}

///|
pub fn AnimationAction::is_playing(self : AnimationAction) -> Bool {
  self.playing
}

///|
pub fn AnimationAction::is_paused(self : AnimationAction) -> Bool {
  self.paused
}

///|
/// `true` after a `Once` action reached its last keyframe.
pub fn AnimationAction::is_finished(self : AnimationAction) -> Bool {
  self.finished
}

///|
/// Jump to `t` seconds (clamped to the clip range); does not change play state.
pub fn AnimationAction::seek(self : AnimationAction, t : Float) -> Unit {
  let d = self.clip.duration()
  let mut v = t
  if v < 0.0 {
    v = 0.0
  }
  if d > 0.0 && v > d {
    v = d
  }
  self.time = v
}

///|
/// Fade the action in over `duration` seconds, starting from its current fade
/// factor. A non-positive duration snaps to full weight.
pub fn AnimationAction::fade_in(self : AnimationAction, duration : Float) -> Unit {
  self.begin_fade(self.fade_weight, 1.0, duration)
}

///|
/// Fade the action out over `duration` seconds. The action keeps running at
/// weight 0 afterwards; call `stop` to release it.
pub fn AnimationAction::fade_out(self : AnimationAction, duration : Float) -> Unit {
  self.begin_fade(self.fade_weight, 0.0, duration)
}

///|
fn AnimationAction::begin_fade(
  self : AnimationAction,
  from : Float,
  to : Float,
  duration : Float,
) -> Unit {
  if duration <= 0.0 {
    self.fade_weight = to
    self.fade_from = to
    self.fade_to = to
    self.fade_elapsed = 0.0
    self.fade_duration = 0.0
  } else {
    self.fade_from = @tmath.saturate(from)
    self.fade_to = @tmath.saturate(to)
    self.fade_weight = self.fade_from
    self.fade_elapsed = 0.0
    self.fade_duration = duration
  }
}

///|
fn AnimationAction::update_fade(self : AnimationAction, dt : Float) -> Unit {
  if self.fade_duration <= 0.0 {
    return
  }
  self.fade_elapsed = self.fade_elapsed + dt
  let a = @tmath.saturate(self.fade_elapsed / self.fade_duration)
  self.fade_weight = @tmath.lerp_f(self.fade_from, self.fade_to, a)
  if a >= 1.0 {
    self.fade_weight = self.fade_to
    self.fade_from = self.fade_to
    self.fade_elapsed = 0.0
    self.fade_duration = 0.0
  }
}

///|
fn AnimationAction::advance_time(self : AnimationAction, dt : Float) -> Unit {
  let d = self.clip.duration()
  if d <= 0.0 {
    self.time = 0.0
    return
  }
  match self.loop_mode {
    Repeat => {
      let t = self.time + dt
      // `floor` also handles negative time (reverse playback).
      self.time = t - d * Float::floor(t / d)
    }
    Once => {
      let mut t = self.time + dt
      if t >= d {
        t = d
        self.finished = true
        self.playing = false
      }
      if t < 0.0 {
        t = 0.0
      }
      self.time = t
    }
    PingPong => {
      let mut t = self.time + dt * self.direction
      if t > d {
        t = d - (t - d)
        self.direction = -1.0
      }
      if t < 0.0 {
        t = -t
        self.direction = 1.0
      }
      // A single reflection is enough for real frame steps; clamp any residual
      // overshoot instead of letting it accumulate.
      t = @tmath.clamp_f(t, 0.0, d)
      self.time = t
    }
  }
}

///|
/// Advance fade + time by `dt` and return the effective blend weight.
fn AnimationAction::advance(self : AnimationAction, dt : Float) -> Float {
  if !self.playing {
    return 0.0
  }
  self.update_fade(dt)
  if !self.paused && dt != 0.0 {
    self.advance_time(dt * self.speed)
  }
  self.weight * self.fade_weight
}

///|
// Per-node blend accumulator. Translation / scale are weighted sums; rotation
// is an incremental normalized slerp so any number of actions can contribute.
priv struct BlendAccum {
  node : NodeId
  mut weight : Float
  mut translation : @tmath.Vec3
  mut scale : @tmath.Vec3
  mut rotation : @tmath.Quat
}

///|
fn AnimationAction::sample_into(
  self : AnimationAction,
  scene : Scene,
  accs : Array[BlendAccum],
  w : Float,
) -> Unit {
  for ch in self.clip.channels {
    if !scene.is_alive(ch.node) {
      continue
    }
    let base = scene.transform(ch.node)
    let sampled = ch.track.sample_with(base, self.time)
    let mut slot = -1
    for i = 0; i < accs.length(); i = i + 1 {
      if accs[i].node == ch.node {
        slot = i
      }
    }
    if slot >= 0 {
      let acc = accs[slot]
      let total = acc.weight + w
      let alpha = w / total
      acc.translation = acc.translation + sampled.translation.scale(w)
      acc.scale = acc.scale + sampled.scale.scale(w)
      acc.rotation = acc.rotation.slerp(sampled.rotation, alpha)
      acc.weight = total
    } else {
      accs.push({
        node: ch.node,
        weight: w,
        translation: sampled.translation.scale(w),
        scale: sampled.scale.scale(w),
        rotation: sampled.rotation,
      })
    }
  }
}

///|
/// Owns every clip action and advances / blends them together.
pub struct AnimationMixer {
  priv actions : Array[AnimationAction]
  priv mut time_scale : Float
}

///|
pub fn AnimationMixer::new() -> AnimationMixer {
  { actions: [], time_scale: 1.0 }
}

///|
/// Add a clip and return its action. The action starts playing at weight 1;
/// call `fade_in` / `set_weight(0)` first when it should blend in.
pub fn AnimationMixer::add(
  self : AnimationMixer,
  clip : AnimationClip,
) -> AnimationAction {
  let action = AnimationAction::new(clip)
  self.actions.push(action)
  action
}

///|
/// Look up an action by clip name (the first match, or `None`).
pub fn AnimationMixer::action(
  self : AnimationMixer,
  name : String,
) -> AnimationAction? {
  for a in self.actions {
    if a.clip.name == name {
      return Some(a)
    }
  }
  None
}

///|
/// Number of actions owned by this mixer.
pub fn AnimationMixer::action_count(self : AnimationMixer) -> Int {
  self.actions.length()
}

///|
/// Fade `from` out and `to` in over `duration` seconds (three.js
/// `AnimationAction.crossFadeTo`). `to` is rewound to weight 0 first, so a
/// crossfade is symmetric even when `to` was already fully faded in.
pub fn AnimationMixer::cross_fade(
  self : AnimationMixer,
  from : AnimationAction,
  to : AnimationAction,
  duration : Float,
) -> Unit {
  let _ = self
  to.play()
  to.fade_weight = 0.0
  to.fade_from = 0.0
  to.fade_to = 1.0
  to.fade_elapsed = 0.0
  to.fade_duration = if duration <= 0.0 { 0.0 } else { duration }
  if duration <= 0.0 {
    to.fade_weight = 1.0
  }
  from.fade_out(duration)
}

///|
/// Stop every action and rewind it.
pub fn AnimationMixer::stop_all(self : AnimationMixer) -> Unit {
  for a in self.actions {
    a.stop()
  }
}

///|
/// Global time multiplier applied to every action's delta.
pub fn AnimationMixer::time_scale(self : AnimationMixer) -> Float {
  self.time_scale
}

///|
/// Set the global time multiplier.
pub fn AnimationMixer::set_time_scale(self : AnimationMixer, scale : Float) -> Unit {
  self.time_scale = scale
}

///|
/// Advance every action by `dt * time_scale` and write the blended local
/// transforms into `scene`. Channels bound to destroyed nodes are ignored; nodes
/// with no active channel keep whatever transform they had.
pub fn AnimationMixer::update(
  self : AnimationMixer,
  scene : Scene,
  dt : Float,
) -> Unit {
  let scaled = dt * self.time_scale
  let accs : Array[BlendAccum] = []
  for a in self.actions {
    let w = a.advance(scaled)
    if w > 0.0 {
      a.sample_into(scene, accs, w)
    }
  }
  for acc in accs {
    if acc.weight > 0.0 {
      let inv : Float = 1.0 / acc.weight
      scene.set_transform(
        acc.node,
        @tmath.Transform::new(
          acc.translation.scale(inv),
          acc.rotation,
          acc.scale.scale(inv),
        ),
      )
    }
  }
}
