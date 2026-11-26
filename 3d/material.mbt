// Material description. Colors are linear RGB(A); use `srgb()` for authored
// values. Material parameters are packed into an SSBO by the renderer, so the
// pipeline family stays bounded (no pipeline per material).

///|
/// Renderer-owned GPU texture. The material only carries the handle.
#derive(Eq, Debug)
pub(all) struct TextureHandle {
  priv id : Int
}

///|
pub fn TextureHandle::from_id(id : Int) -> TextureHandle {
  { id, }
}

///|
pub fn TextureHandle::id(self : TextureHandle) -> Int {
  self.id
}

///|
pub(all) enum Shading {
  Pbr
  Unlit
}

///|
pub(all) enum AlphaMode {
  Opaque
  Mask(Float)
  Blend
}

///|
pub(all) struct MaterialDesc {
  shading : Shading
  // Linear-space base color, alpha = opacity.
  base_color : @tmath.Vec4
  metallic : Float
  roughness : Float
  // Linear HDR emissive, may exceed 1.
  emissive : @tmath.Vec3
  alpha_mode : AlphaMode
  double_sided : Bool
  albedo_tex : TextureHandle?
  normal_tex : TextureHandle?
  metallic_roughness_tex : TextureHandle?
  emissive_tex : TextureHandle?
}

///|
pub fn MaterialDesc::pbr(
  base_color : @tmath.Vec4,
  metallic? : Float = 0.0,
  roughness? : Float = 0.5,
) -> MaterialDesc {
  {
    shading: Shading::Pbr,
    base_color,
    metallic,
    roughness,
    emissive: @tmath.Vec3::zero(),
    alpha_mode: AlphaMode::Opaque,
    double_sided: false,
    albedo_tex: None,
    normal_tex: None,
    metallic_roughness_tex: None,
    emissive_tex: None,
  }
}

///|
pub fn MaterialDesc::unlit(color : @tmath.Vec4) -> MaterialDesc {
  {
    shading: Shading::Unlit,
    base_color: color,
    metallic: 0.0,
    roughness: 1.0,
    emissive: @tmath.Vec3::zero(),
    alpha_mode: AlphaMode::Opaque,
    double_sided: false,
    albedo_tex: None,
    normal_tex: None,
    metallic_roughness_tex: None,
    emissive_tex: None,
  }
}

///|
pub fn MaterialDesc::with_emissive(self : MaterialDesc, emissive : @tmath.Vec3) -> MaterialDesc {
  { ..self, emissive }
}

///|
pub fn MaterialDesc::with_alpha(self : MaterialDesc, mode : AlphaMode) -> MaterialDesc {
  { ..self, alpha_mode: mode }
}

///|
pub fn MaterialDesc::with_double_sided(self : MaterialDesc, double_sided : Bool) -> MaterialDesc {
  { ..self, double_sided }
}

///|
pub fn MaterialDesc::with_albedo_tex(self : MaterialDesc, tex : TextureHandle) -> MaterialDesc {
  { ..self, albedo_tex: Some(tex) }
}

///|
pub fn MaterialDesc::with_normal_tex(self : MaterialDesc, tex : TextureHandle) -> MaterialDesc {
  { ..self, normal_tex: Some(tex) }
}

///|
/// sRGB (IEC 61966-2-1) to linear.
pub fn srgb_to_linear(c : Float) -> Float {
  let v : Float = if c < 0.0 {
    0.0
  } else if c > 1.0 {
    1.0
  } else {
    c
  }
  if v <= (0.04045 : Float) {
    v / (12.92 : Float)
  } else {
    @tmath.pow((v + (0.055 : Float)) / (1.055 : Float), (2.4 : Float))
  }
}

///|
/// Author a color in familiar sRGB space; returns a linear `Vec4`.
pub fn srgb(r : Float, g : Float, b : Float, a? : Float = 1.0) -> @tmath.Vec4 {
  @tmath.Vec4::new(srgb_to_linear(r), srgb_to_linear(g), srgb_to_linear(b), a)
}
