// Scalar helpers and numeric constants for laplaceliu/tycho_math.
//
// All transcendental functions delegate to `moonbitlang/core/math` (the `f`
// variants operate on 32-bit `Float`); no hand-written Taylor series is allowed
// in this package.

///|
pub const PI : Float = 3.14159265358979323846

///|
pub const TAU : Float = 6.28318530717958647692

///|
pub const FRAC_PI_2 : Float = 1.57079632679489661923

///|
pub const FRAC_PI_3 : Float = 1.04719755119659774615

///|
pub const FRAC_PI_4 : Float = 0.78539816339744830962

///|
pub const FRAC_PI_6 : Float = 0.52359877559829887308

///|
pub const SQRT_2 : Float = 1.41421356237309504880

///|
pub const SQRT_1_2 : Float = 0.70710678118654752440

///|
pub const DEG_TO_RAD : Float = 0.01745329251994329577

///|
pub const RAD_TO_DEG : Float = 57.29577951308232087680

///|
/// Default absolute tolerance used by every `approx_eq` in this package.
pub const EPSILON : Float = 1.0e-6

///|
/// Clamp `v` into `[lo, hi]`. If `lo > hi` the bounds are swapped so the
/// function never returns a value outside the closed interval formed by them.
pub fn clamp_f(v : Float, lo : Float, hi : Float) -> Float {
  if lo > hi {
    return clamp_f_ordered(v, hi, lo)
  }
  clamp_f_ordered(v, lo, hi)
}

///|
fn clamp_f_ordered(v : Float, lo : Float, hi : Float) -> Float {
  if v < lo {
    lo
  } else if v > hi {
    hi
  } else {
    v
  }
}

///|
pub fn min_f(a : Float, b : Float) -> Float {
  if a < b {
    a
  } else {
    b
  }
}

///|
pub fn max_f(a : Float, b : Float) -> Float {
  if a > b {
    a
  } else {
    b
  }
}

///|
pub fn abs_f(v : Float) -> Float {
  v.abs()
}

///|
/// Clamp `v` into `[0, 1]`.
pub fn saturate(v : Float) -> Float {
  clamp_f_ordered(v, 0.0, 1.0)
}

///|
/// Linear interpolation, no clamping of `t`.
pub fn lerp_f(a : Float, b : Float, t : Float) -> Float {
  a + (b - a) * t
}

///|
/// Inverse of `lerp_f`: returns where `v` lies between `a` and `b`.
/// Returns `0` when `a == b`.
pub fn inv_lerp_f(a : Float, b : Float, v : Float) -> Float {
  let d = b - a
  if d == 0.0 {
    0.0
  } else {
    (v - a) / d
  }
}

///|
/// GLSL-style `smoothstep`: smooth Hermite interpolation between two edges,
/// clamped to `[0, 1]`. Returns `0` when `edge0 >= edge1`.
pub fn smoothstep(edge0 : Float, edge1 : Float, x : Float) -> Float {
  let d = edge1 - edge0
  if d == 0.0 {
    if x < edge0 {
      0.0
    } else {
      1.0
    }
  } else {
    let t = saturate((x - edge0) / d)
    t * t * ((3.0 : Float) - (2.0 : Float) * t)
  }
}

///|
/// GLSL-style `step`: `0` when `x < edge`, otherwise `1`.
pub fn step(edge : Float, x : Float) -> Float {
  if x < edge {
    0.0
  } else {
    1.0
  }
}

///|
/// Fractional part, always in `[0, 1)` for finite inputs.
pub fn fract(v : Float) -> Float {
  v - Float::floor(v)
}

///|
/// Sign of `v` as `-1`, `0`, or `1`. `NaN` maps to `0`.
pub fn sign_f(v : Float) -> Float {
  if v > 0.0 {
    1.0
  } else if v < 0.0 {
    -1.0
  } else {
    0.0
  }
}

///|
pub fn deg_to_rad(deg : Float) -> Float {
  deg * DEG_TO_RAD
}

///|
pub fn rad_to_deg(rad : Float) -> Float {
  rad * RAD_TO_DEG
}

///|
/// Absolute-tolerance comparison. `NaN` never compares equal, even to itself.
pub fn approx_eq_f(a : Float, b : Float, eps? : Float = EPSILON) -> Bool {
  if a.is_nan() || b.is_nan() {
    return false
  }
  (a - b).abs() <= eps
}

///|
/// `true` when both values are `NaN` (handy for tests that must *reject* NaN).
pub fn is_nan(v : Float) -> Bool {
  v.is_nan()
}

///|
/// `(sin, cos)` of an angle in radians, sharing one range reduction in the
/// underlying libm when available.
pub fn sin_cos(radians : Float) -> (Float, Float) {
  (@math.sinf(radians), @math.cosf(radians))
}

///|
pub fn sin(radians : Float) -> Float {
  @math.sinf(radians)
}

///|
pub fn cos(radians : Float) -> Float {
  @math.cosf(radians)
}

///|
pub fn tan(radians : Float) -> Float {
  @math.tanf(radians)
}

///|
pub fn asin(v : Float) -> Float {
  @math.asinf(v)
}

///|
pub fn acos(v : Float) -> Float {
  @math.acosf(v)
}

///|
pub fn atan(v : Float) -> Float {
  @math.atanf(v)
}

///|
pub fn atan2(y : Float, x : Float) -> Float {
  @math.atan2f(y, x)
}

///|
pub fn sqrt(v : Float) -> Float {
  v.sqrt()
}

///|
pub fn pow(a : Float, b : Float) -> Float {
  @math.powf(a, b)
}

///|
pub fn exp(v : Float) -> Float {
  @math.expf(v)
}

///|
pub fn ln(v : Float) -> Float {
  @math.lnf(v)
}

///|
/// `true` when `v` is finite (not `NaN`, `+inf`, or `-inf`).
pub fn is_finite(v : Float) -> Bool {
  v.is_finite()
}
