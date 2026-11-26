// TRS keyframe animation.
//
// Tracks store sorted keyframes for translation / rotation / scale, sample with
// linear (Vec3) or slerp (Quat) interpolation, and channels bind one track to a
// scene node. `AnimationPlayer` advances a clip and writes local transforms, so
// the renderer needs no animation awareness.

///|
pub(all) enum Interpolation {
  Linear
  Step
}

///|
/// Sorted keyframe times. Returns the segment start and its [0, 1] fraction.
fn sample_segment(times : Array[Float], t : Float) -> (Int, Float) {
  let n = times.length()
  if n == 0 {
    return (0, 0.0)
  }
  if n == 1 || t <= times[0] {
    return (0, 0.0)
  }
  if t >= times[n - 1] {
    return (n - 1, 0.0)
  }
  let mut lo = 0
  let mut hi = n - 1
  while lo + 1 < hi {
    let mid = (lo + hi) / 2
    if times[mid] <= t {
      lo = mid
    } else {
      hi = mid
    }
  }
  let span = times[hi] - times[lo]
  let alpha = if span > 0.0 { (t - times[lo]) / span } else { 0.0 }
  (lo, alpha)
}

///|
pub(all) struct Vec3Track {
  times : Array[Float]
  values : Array[@tmath.Vec3]
  interpolation : Interpolation
}

///|
pub fn Vec3Track::new(
  times : Array[Float],
  values : Array[@tmath.Vec3],
  interpolation? : Interpolation = Interpolation::Linear,
) -> Vec3Track {
  { times, values, interpolation }
}

///|
pub fn Vec3Track::sample(self : Vec3Track, t : Float) -> @tmath.Vec3 {
  if self.values.length() == 0 {
    return @tmath.Vec3::zero()
  }
  let (i, a) = sample_segment(self.times, t)
  match self.interpolation {
    Step => self.values[i]
    Linear =>
      if i + 1 < self.values.length() {
        self.values[i].lerp(self.values[i + 1], a)
      } else {
        self.values[i]
      }
  }
}

///|
pub fn Vec3Track::duration(self : Vec3Track) -> Float {
  if self.times.length() == 0 {
    0.0
  } else {
    self.times[self.times.length() - 1]
  }
}

///|
pub(all) struct QuatTrack {
  times : Array[Float]
  values : Array[@tmath.Quat]
  interpolation : Interpolation
}

///|
pub fn QuatTrack::new(
  times : Array[Float],
  values : Array[@tmath.Quat],
  interpolation? : Interpolation = Interpolation::Linear,
) -> QuatTrack {
  { times, values, interpolation }
}

///|
pub fn QuatTrack::sample(self : QuatTrack, t : Float) -> @tmath.Quat {
  if self.values.length() == 0 {
    return @tmath.Quat::identity()
  }
  let (i, a) = sample_segment(self.times, t)
  match self.interpolation {
    Step => self.values[i]
    Linear =>
      if i + 1 < self.values.length() {
        self.values[i].slerp(self.values[i + 1], a)
      } else {
        self.values[i]
      }
  }
}

///|
pub fn QuatTrack::duration(self : QuatTrack) -> Float {
  if self.times.length() == 0 {
    0.0
  } else {
    self.times[self.times.length() - 1]
  }
}

///|
/// Any subset of the three channels; missing channels keep the node's value.
pub(all) struct TransformTrack {
  translation : Vec3Track?
  rotation : QuatTrack?
  scale : Vec3Track?
}

///|
pub fn TransformTrack::new(
  translation? : Vec3Track? = None,
  rotation? : QuatTrack? = None,
  scale? : Vec3Track? = None,
) -> TransformTrack {
  { translation, rotation, scale }
}

///|
pub fn TransformTrack::duration(self : TransformTrack) -> Float {
  let mut d : Float = 0.0
  match self.translation {
    Some(t) =>
      if t.duration() > d {
        d = t.duration()
      }
    None => ()
  }
  match self.rotation {
    Some(r) =>
      if r.duration() > d {
        d = r.duration()
      }
    None => ()
  }
  match self.scale {
    Some(s) =>
      if s.duration() > d {
        d = s.duration()
      }
    None => ()
  }
  d
}

///|
/// Sample over `base`: channels that the track does not animate are preserved.
pub fn TransformTrack::sample_with(
  self : TransformTrack,
  base : @tmath.Transform,
  t : Float,
) -> @tmath.Transform {
  let translation = match self.translation {
    Some(v) => v.sample(t)
    None => base.translation
  }
  let rotation = match self.rotation {
    Some(q) => q.sample(t)
    None => base.rotation
  }
  let scale = match self.scale {
    Some(s) => s.sample(t)
    None => base.scale
  }
  @tmath.Transform::new(translation, rotation, scale)
}

///|
pub(all) struct AnimationChannel {
  node : NodeId
  track : TransformTrack
}

///|
pub fn AnimationChannel::new(node : NodeId, track : TransformTrack) -> AnimationChannel {
  { node, track }
}

///|
pub(all) struct AnimationClip {
  name : String
  channels : Array[AnimationChannel]
}

///|
pub fn AnimationClip::new(
  name : String,
  channels : Array[AnimationChannel],
) -> AnimationClip {
  { name, channels }
}

///|
pub fn AnimationClip::duration(self : AnimationClip) -> Float {
  let mut d : Float = 0.0
  for ch in self.channels {
    let cd = ch.track.duration()
    if cd > d {
      d = cd
    }
  }
  d
}

///|
pub(all) struct AnimationPlayer {
  clip : AnimationClip
  priv mut time : Float
  priv mut speed : Float
  priv mut looping : Bool
  priv mut playing : Bool
}

///|
pub fn AnimationPlayer::new(clip : AnimationClip) -> AnimationPlayer {
  { clip, time: 0.0, speed: 1.0, looping: true, playing: true }
}

///|
pub fn AnimationPlayer::time(self : AnimationPlayer) -> Float {
  self.time
}

///|
pub fn AnimationPlayer::duration(self : AnimationPlayer) -> Float {
  self.clip.duration()
}

///|
pub fn AnimationPlayer::is_playing(self : AnimationPlayer) -> Bool {
  self.playing
}

///|
pub fn AnimationPlayer::set_speed(self : AnimationPlayer, speed : Float) -> Unit {
  self.speed = speed
}

///|
pub fn AnimationPlayer::set_looping(self : AnimationPlayer, looping : Bool) -> Unit {
  self.looping = looping
}

///|
pub fn AnimationPlayer::play(self : AnimationPlayer) -> Unit {
  self.playing = true
}

///|
pub fn AnimationPlayer::pause(self : AnimationPlayer) -> Unit {
  self.playing = false
}

///|
pub fn AnimationPlayer::seek(self : AnimationPlayer, t : Float) -> Unit {
  self.time = if t < 0.0 { 0.0 } else { t }
}

///|
/// Advance by `dt * speed`, wrap (or clamp) to the clip duration and apply.
pub fn AnimationPlayer::update(
  self : AnimationPlayer,
  scene : Scene,
  dt : Float,
) -> Unit {
  if !self.playing {
    return
  }
  let d = self.clip.duration()
  let mut t = self.time + dt * self.speed
  if d > 0.0 {
    if self.looping {
      while t >= d {
        t = t - d
      }
      while t < 0.0 {
        t = t + d
      }
    } else if t > d {
      t = d
    } else if t < 0.0 {
      t = 0.0
    }
  }
  self.time = t
  self.apply(scene)
}

///|
/// Write the sampled local transforms without advancing time.
pub fn AnimationPlayer::apply(self : AnimationPlayer, scene : Scene) -> Unit {
  for ch in self.clip.channels {
    let base = scene.transform(ch.node)
    scene.set_transform(ch.node, ch.track.sample_with(base, self.time))
  }
}
