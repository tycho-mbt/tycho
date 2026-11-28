// Pure-CPU tests for `AnimationMixer`: weighted blending, crossfades, loop
// modes, dead-node tolerance and global time scaling.

///|
fn x_clip(
  name : String,
  node : NodeId,
  x0 : Float,
  x1 : Float,
  duration : Float,
) -> AnimationClip {
  AnimationClip::new(name, [
    AnimationChannel::new(
      node,
      TransformTrack::new(
        translation=Vec3Track::new(
          [0.0, duration],
          [@tmath.Vec3::new(x0, 0.0, 0.0), @tmath.Vec3::new(x1, 0.0, 0.0)],
        ),
      ),
    ),
  ])
}

///|
test "mixer blends by normalized weight" {
  let s = Scene::new()
  let n = s.create_node()
  let mixer = AnimationMixer::new()
  let a = mixer.add(x_clip("a", n, 0.0, 10.0, 10.0))
  let b = mixer.add(x_clip("b", n, 0.0, 20.0, 10.0))
  a.set_weight(0.25)
  b.set_weight(0.75)
  a.seek(5.0)
  b.seek(5.0)
  mixer.update(s, 0.0)
  // 0.25 * 5 + 0.75 * 10
  need(close(s.position(n).x, 8.75, eps=1.0e-4), "weighted translation")
  // A single action at weight 0.5 still produces its full (normalized) pose.
  b.stop()
  a.set_weight(0.5)
  mixer.update(s, 0.0)
  need(close(s.position(n).x, 5.0, eps=1.0e-4), "single action normalizes")
  need(mixer.action_count() == 2, "action count")
  match mixer.action("b") {
    Some(_) => ()
    None => fail("action lookup by name")
  }
  match mixer.action("missing") {
    Some(_) => fail("unexpected action")
    None => ()
  }
}

///|
test "mixer crossfade midpoint" {
  let s = Scene::new()
  let n = s.create_node()
  let mixer = AnimationMixer::new()
  // Constant tracks: A holds 0, B holds 10.
  let a = mixer.add(x_clip("idle", n, 0.0, 0.0, 1.0))
  let b = mixer.add(x_clip("walk", n, 10.0, 10.0, 1.0))
  mixer.cross_fade(a, b, 1.0)
  mixer.update(s, 0.5)
  need(close(s.position(n).x, 5.0, eps=1.0e-4), "crossfade midpoint")
  mixer.update(s, 0.5)
  need(close(s.position(n).x, 10.0, eps=1.0e-4), "crossfade completed")
  need(a.weight() > 0.0, "faded action keeps its user weight")
}

///|
test "mixer loop modes" {
  // Repeat wraps past the duration.
  let s1 = Scene::new()
  let n1 = s1.create_node()
  let m1 = AnimationMixer::new()
  let _a1 = m1.add(x_clip("loop", n1, 0.0, 1.0, 1.0))
  m1.update(s1, 1.5)
  need(close(s1.position(n1).x, 0.5, eps=1.0e-4), "repeat wraps")

  // Once clamps at the last keyframe and stops.
  let s2 = Scene::new()
  let n2 = s2.create_node()
  let m2 = AnimationMixer::new()
  let a2 = m2.add(x_clip("once", n2, 0.0, 1.0, 1.0))
  a2.set_loop(LoopMode::Once)
  m2.update(s2, 2.0)
  need(close(s2.position(n2).x, 1.0, eps=1.0e-4), "once clamps")
  need(a2.is_finished(), "once finished")
  need(!a2.is_playing(), "once stops")
  // A finished action no longer drives the node.
  s2.set_position(n2, @tmath.Vec3::new(42.0, 0.0, 0.0))
  m2.update(s2, 1.0)
  need(close(s2.position(n2).x, 42.0, eps=1.0e-4), "finished action releases the node")
  // play() restarts a finished action.
  a2.play()
  need(close(a2.time(), 0.0), "once restarts from zero")
  m2.update(s2, 0.5)
  need(close(s2.position(n2).x, 0.5, eps=1.0e-4), "restarted once samples")

  // PingPong reflects at both ends.
  let s3 = Scene::new()
  let n3 = s3.create_node()
  let m3 = AnimationMixer::new()
  let a3 = m3.add(x_clip("ping", n3, 0.0, 1.0, 1.0))
  a3.set_loop(LoopMode::PingPong)
  m3.update(s3, 1.5)
  need(close(s3.position(n3).x, 0.5, eps=1.0e-4), "pingpong reflects at end")
  m3.update(s3, 0.75)
  need(close(s3.position(n3).x, 0.25, eps=1.0e-4), "pingpong reflects at start")
}

///|
test "mixer skips destroyed nodes" {
  let s = Scene::new()
  let alive = s.create_node()
  let dead = s.create_node()
  let mixer = AnimationMixer::new()
  let _a = mixer.add(x_clip("a", dead, 0.0, 10.0, 10.0))
  let _b = mixer.add(x_clip("b", alive, 0.0, 4.0, 10.0))
  s.destroy_node(dead)
  // Must not crash, and the surviving channel still animates.
  mixer.update(s, 5.0)
  need(close(s.position(alive).x, 2.0, eps=1.0e-4), "alive channel sampled")
}

///|
test "mixer stop releases the node" {
  let s = Scene::new()
  let n = s.create_node()
  let mixer = AnimationMixer::new()
  let a = mixer.add(x_clip("a", n, 0.0, 10.0, 10.0))
  mixer.update(s, 5.0)
  need(close(s.position(n).x, 5.0, eps=1.0e-4), "animated")
  a.stop()
  s.set_position(n, @tmath.Vec3::new(7.0, 0.0, 0.0))
  mixer.update(s, 1.0)
  need(close(s.position(n).x, 7.0, eps=1.0e-4), "stop releases the node")
  // add() defaults to playing, so a fresh action takes over again from t=0.
  let _b = mixer.add(x_clip("b", n, 0.0, 10.0, 10.0))
  mixer.update(s, 0.0)
  need(close(s.position(n).x, 0.0, eps=1.0e-4), "re-added action starts at t=0")
}

///|
test "mixer global time scale and pause" {
  let s = Scene::new()
  let n = s.create_node()
  let mixer = AnimationMixer::new()
  let a = mixer.add(x_clip("a", n, 0.0, 10.0, 10.0))
  mixer.set_time_scale(2.0)
  mixer.update(s, 1.0)
  need(close(a.time(), 2.0, eps=1.0e-4), "time scale advances time")
  need(close(s.position(n).x, 2.0, eps=1.0e-4), "time scale drives the pose")
  // Pausing freezes time but keeps contributing the current pose.
  a.pause()
  mixer.update(s, 1.0)
  need(close(a.time(), 2.0, eps=1.0e-4), "paused time frozen")
  need(close(s.position(n).x, 2.0, eps=1.0e-4), "paused pose retained")
  a.play()
  mixer.update(s, 1.0)
  need(close(a.time(), 4.0, eps=1.0e-4), "resumed")
}
