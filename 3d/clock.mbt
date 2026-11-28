// Frame-time bookkeeping.
//
// `tycho_3d` deliberately does not own the frame loop or a platform clock
// (§2.2: it must embed in engines that already have one), so `Clock` consumes
// the caller's monotonic timestamp and only owns the arithmetic every 3D app
// would otherwise repeat: first-frame suppression, pause-spike clamping and
// elapsed/delta/FPS accumulation.

///|
/// Delta-time accumulator fed by a caller-supplied monotonic timestamp in
/// seconds (three.js `Clock`, minus the global `performance.now()`).
///
/// The first `tick` returns `0` (there is no previous sample to subtract), and
/// a delta larger than `max_delta` — a debugger pause, a backgrounded window,
/// or a stalled frame — is clamped instead of teleporting every animation.
pub struct Clock {
  priv mut last : Float?
  priv mut elapsed : Float
  priv mut delta : Float
  priv mut frames : Int
  priv max_delta : Float
}

///|
/// `max_delta` is the largest accepted frame step, in seconds.
pub fn Clock::new(max_delta? : Float = 0.25) -> Clock {
  {
    last: None,
    elapsed: 0.0,
    delta: 0.0,
    frames: 0,
    max_delta: if max_delta <= 0.0 { 0.25 } else { max_delta },
  }
}

///|
/// Advance the clock to `now` (monotonic seconds) and return the clamped delta.
pub fn Clock::tick(self : Clock, now : Float) -> Float {
  let dt : Float = match self.last {
    Some(prev) => {
      let raw = now - prev
      if raw < 0.0 {
        0.0
      } else if raw > self.max_delta {
        self.max_delta
      } else {
        raw
      }
    }
    None => 0.0
  }
  self.last = Some(now)
  self.delta = dt
  self.elapsed = self.elapsed + dt
  self.frames = self.frames + 1
  dt
}

///|
/// Forget the previous sample so the next `tick` starts at delta `0`.
pub fn Clock::reset(self : Clock) -> Unit {
  self.last = None
  self.elapsed = 0.0
  self.delta = 0.0
  self.frames = 0
}

///|
/// Last returned delta, in seconds.
pub fn Clock::delta(self : Clock) -> Float {
  self.delta
}

///|
/// Total non-clamped time accumulated so far, in seconds.
pub fn Clock::elapsed(self : Clock) -> Float {
  self.elapsed
}

///|
/// Number of `tick` calls since construction or `reset`.
pub fn Clock::frames(self : Clock) -> Int {
  self.frames
}

///|
/// Instantaneous frames per second derived from the last delta (`0` before the
/// second sample).
pub fn Clock::fps(self : Clock) -> Float {
  if self.delta > 0.0 {
    1.0 / self.delta
  } else {
    0.0
  }
}
