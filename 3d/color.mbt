// Authored-color helpers.
//
// `tycho_3d` renders in linear space: `MaterialDesc` stores `Vec4` / `Vec3`
// whose channels are already linear, and sRGB only exists at texture input and
// the tonemap output. This file adds the *authoring* conveniences three.js
// users expect (`0xRRGGBB` and HSL) without introducing a second color state
// type: everything here converts immediately to the same linear `Vec4` that a
// hand-written `srgb(...)` call produces, so the "single linear source of
// truth" invariant is preserved.

///|
/// Linear RGBA from explicit linear channels — the counterpart of `srgb`.
/// Values may exceed 1 for HDR emitters when used as an emissive color.
pub fn linear(r : Float, g : Float, b : Float, a? : Float = 1.0) -> @tmath.Vec4 {
  @tmath.Vec4::new(r, g, b, a)
}

///|
/// Author an sRGB color from a packed `0xRRGGBB` literal, returning linear RGBA.
///
/// `hex(0xFF8800)` is the three.js `new Color(0xff8800)` equivalent, and the
/// result feeds `MaterialDesc::pbr` directly:
///
/// ```moonbit
/// let mat = @t3d.MaterialDesc::standard(@t3d.hex(0xFF8800), roughness=0.4)
/// ```
///
/// Channels above `0xFFFFFF` are ignored; alpha is authored separately and is
/// not gamma-encoded (three.js `Color` behaves the same way).
pub fn hex(rgb : Int, a? : Float = 1.0) -> @tmath.Vec4 {
  let r = (rgb >> 16) & 0xFF
  let g = (rgb >> 8) & 0xFF
  let b = rgb & 0xFF
  srgb(
    f_of_int(r) / (255.0 : Float),
    f_of_int(g) / (255.0 : Float),
    f_of_int(b) / (255.0 : Float),
    a=a,
  )
}

///|
/// Convert an HSL triple to sRGB `(r, g, b)` in `[0, 1]`.
/// `h` is in degrees and wraps; `s` / `l` are clamped to `[0, 1]`.
fn hsl_to_srgb(h : Float, s : Float, l : Float) -> (Float, Float, Float) {
  let hue = @tmath.fract(h / (360.0 : Float)) * (6.0 : Float)
  let sat = @tmath.clamp_f(s, 0.0, 1.0)
  let lig = @tmath.clamp_f(l, 0.0, 1.0)
  let c = ((1.0 : Float) - @tmath.abs_f((2.0 : Float) * lig - (1.0 : Float))) * sat
  let x = c *
    ((1.0 : Float) -
    @tmath.abs_f(@tmath.fract(hue / (2.0 : Float)) * (2.0 : Float) - (1.0 : Float)))
  let sector = hue.to_int()
  let (r1, g1, b1) : (Float, Float, Float) = if sector == 0 {
    (c, x, 0.0)
  } else if sector == 1 {
    (x, c, 0.0)
  } else if sector == 2 {
    (0.0, c, x)
  } else if sector == 3 {
    (0.0, x, c)
  } else if sector == 4 {
    (x, 0.0, c)
  } else {
    (c, 0.0, x)
  }
  // Lift the chroma back to the requested lightness (achromatic offset).
  let m = lig - c * 0.5
  (r1 + m, g1 + m, b1 + m)
}

///|
/// Author an sRGB color from HSL, returning linear RGBA.
///
/// `h` is degrees (`0` = red, `120` = green, `240` = blue, wraps at `360`);
/// `s` / `l` are `0..1`. This is the `Color.setHSL` equivalent; the palette
/// helpers that produce `0xRRGGBB` constants and `hsl(...)` land on identical
/// values for the same color.
pub fn hsl(h : Float, s : Float, l : Float, a? : Float = 1.0) -> @tmath.Vec4 {
  let (r, g, b) = hsl_to_srgb(h, s, l)
  srgb(r, g, b, a=a)
}
