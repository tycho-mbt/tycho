// Distance fog (three.js `Fog` / `FogExp2`).
//
// Fog is applied in linear space right before the HDR output is written, so the
// blend happens on radiance values and is then tone-mapped with the rest of the
// frame. The sky pass is not fogged: three.js treats `scene.background` as a
// separate layer too, and a background color or environment is already a
// "far plane" color.
//
// The parameters travel in the frame UBO (two `vec4`s appended after the
// cascade data), so switching fog on or off costs no pipeline variant and no
// per-object state.

///|
/// Fog model for a scene.
///
/// - `Linear(color, near, far)` matches three.js `Fog`: no fog before `near`,
///   fully fogged past `far`, linear in between.
/// - `Exp2(color, density)` matches three.js `FogExp2`: `1 - exp(-(density *
///   distance)^2)`, which scales more naturally with distance.
pub(all) enum Fog {
  Linear(@tmath.Vec3, Float, Float)
  Exp2(@tmath.Vec3, Float)
}

///|
/// three.js `new Fog(color, near, far)`.
pub fn fog_linear(
  color : @tmath.Vec3,
  near? : Float = 1.0,
  far? : Float = 100.0,
) -> Fog {
  let n : Float = if near < 0.0 { 0.0 } else { near }
  let f : Float = if far <= n { n + (1.0 : Float) } else { far }
  Fog::Linear(color, n, f)
}

///|
/// three.js `new FogExp2(color, density)`.
pub fn fog_exp2(color : @tmath.Vec3, density? : Float = 0.02) -> Fog {
  Fog::Exp2(color, if density < 0.0 { 0.0 } else { density })
}

///|
/// The fog color (linear RGB).
pub fn Fog::color(self : Fog) -> @tmath.Vec3 {
  match self {
    Linear(c, _, _) => c
    Exp2(c, _) => c
  }
}
