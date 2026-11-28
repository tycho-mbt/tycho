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
/// Crate-internal: handles are only produced by `Renderer3D` so callers cannot
/// fabricate an id that aliases another resource.
fn TextureHandle::from_id(id : Int) -> TextureHandle {
  { id, }
}

///|
pub fn TextureHandle::id(self : TextureHandle) -> Int {
  self.id
}

///|
/// Renderer-owned material slot.
#derive(Eq, Debug)
pub(all) struct MaterialHandle {
  priv id : Int
}

///|
/// Crate-internal: see `TextureHandle::from_id`.
fn MaterialHandle::from_id(id : Int) -> MaterialHandle {
  { id, }
}

///|
pub fn MaterialHandle::id(self : MaterialHandle) -> Int {
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
  // Physical extension: a second specular lobe on top of the base layer.
  clearcoat : Float
  clearcoat_roughness : Float
  // Linear HDR emissive, may exceed 1.
  emissive : @tmath.Vec3
  // Physical sheen: a low-grazing-angle fabric lobe (glTF KHR_materials_sheen
  // / three.js `sheenColor` + `sheenRoughness`). A zero colour disables it.
  sheen_color : @tmath.Vec3
  sheen_roughness : Float
  // Screen-space transmission (three.js `transmission` + `ior`): a fraction in
  // `[0, 1]` of the surface that shows the scene behind it, refracted by `ior`.
  // Requires the static-mesh PBR path; skinned/morph meshes ignore it.
  transmission : Float
  ior : Float
  // Thin-film iridescence (three.js `iridescence` / glTF
  // `KHR_materials_iridescence`). `amount` in `[0, 1]`, `iridescence_ior` is
  // the film's index of refraction and `iridescence_thickness` its thickness in
  // nanometres; the two-beam interference is evaluated per pixel, so thin
  // (~200-800 nm) films tint the specular reflection by view angle.
  iridescence : Float
  iridescence_ior : Float
  iridescence_thickness : Float
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
    clearcoat: 0.0,
    clearcoat_roughness: 0.04,
    emissive: @tmath.Vec3::zero(),
    sheen_color: @tmath.Vec3::zero(),
    sheen_roughness: 0.5,
    transmission: 0.0,
    ior: 1.5,
    iridescence: 0.0,
    iridescence_ior: 1.3,
    iridescence_thickness: 400.0,
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
    clearcoat: 0.0,
    clearcoat_roughness: 0.04,
    emissive: @tmath.Vec3::zero(),
    sheen_color: @tmath.Vec3::zero(),
    sheen_roughness: 0.5,
    transmission: 0.0,
    ior: 1.5,
    iridescence: 0.0,
    iridescence_ior: 1.3,
    iridescence_thickness: 400.0,
    alpha_mode: AlphaMode::Opaque,
    double_sided: false,
    albedo_tex: None,
    normal_tex: None,
    metallic_roughness_tex: None,
    emissive_tex: None,
  }
}

///|
/// Physical sheen lobe (three.js `sheenColor` / `sheenRoughness`, glTF
/// `KHR_materials_sheen`). Use a light colour such as `srgb(1, 1, 1).truncate()`
/// for fabric-like grazing highlights; a zero colour disables the lobe.
pub fn MaterialDesc::with_sheen(
  self : MaterialDesc,
  color : @tmath.Vec3,
  roughness? : Float = 0.5,
) -> MaterialDesc {
  { ..self, sheen_color: color, sheen_roughness: roughness }
}

///|
/// Screen-space transmission (three.js `transmission` / `ior`, glTF
/// `KHR_materials_transmission` / `KHR_materials_ior`).
///
/// `amount` is the fraction of the surface that shows the scene behind it
/// (0 = opaque, 1 = fully transmissive) and `ior` bends that view. The renderer
/// draws transmissive static meshes in a second pass against a copy of the
/// opaque color, so the background is genuinely refracted instead of merely
/// alpha-blended. Skinned and morph meshes ignore transmission for now.
pub fn MaterialDesc::with_transmission(
  self : MaterialDesc,
  amount : Float,
  ior? : Float = 1.5,
) -> MaterialDesc {
  { ..self, transmission: @tmath.saturate(amount), ior }
}

///|
/// Thin-film iridescence (three.js `iridescence` / `iridescenceIOR` /
/// `iridescenceThicknessRange`, glTF `KHR_materials_iridescence`).
///
/// The fragment shader evaluates two-beam interference for the R/G/B
/// wavelengths of a film `thickness_nm` thick with index `ior`, and blends the
/// resulting view-dependent reflectance into the base specular F0. Typical
/// values: `with_iridescence(1.0, thickness_nm=350)` gives a soap-bubble /
/// beetle-shell shift; `amount = 0` disables it.
pub fn MaterialDesc::with_iridescence(
  self : MaterialDesc,
  amount : Float,
  ior? : Float = 1.3,
  thickness_nm? : Float = 400.0,
) -> MaterialDesc {
  {
    ..self,
    iridescence: @tmath.saturate(amount),
    iridescence_ior: if ior < 1.0 { 1.0 } else { ior },
    iridescence_thickness: if thickness_nm < 0.0 { 0.0 } else { thickness_nm },
  }
}

///|
/// three.js-style name for `pbr`: `MeshStandardMaterial`.
/// `standard(hex(0xFF8800), roughness=0.4)` reads like the three.js original.
pub fn MaterialDesc::standard(
  base_color : @tmath.Vec4,
  metallic? : Float = 0.0,
  roughness? : Float = 0.5,
) -> MaterialDesc {
  MaterialDesc::pbr(base_color, metallic~, roughness~)
}

///|
/// three.js-style name for `unlit`: `MeshBasicMaterial` — a solid color with
/// no lighting, IBL or shadow response.
pub fn MaterialDesc::basic(color : @tmath.Vec4) -> MaterialDesc {
  MaterialDesc::unlit(color)
}

///|
/// Replace the linear base color, keeping the rest of the material.
pub fn MaterialDesc::with_base_color(
  self : MaterialDesc,
  color : @tmath.Vec4,
) -> MaterialDesc {
  { ..self, base_color: color }
}

///|
/// Replace the metallic factor (0..1).
pub fn MaterialDesc::with_metallic(
  self : MaterialDesc,
  metallic : Float,
) -> MaterialDesc {
  { ..self, metallic }
}

///|
/// Replace the roughness factor (0..1).
pub fn MaterialDesc::with_roughness(
  self : MaterialDesc,
  roughness : Float,
) -> MaterialDesc {
  { ..self, roughness }
}

///|
/// Physical clearcoat layer (0 disables it).
pub fn MaterialDesc::with_clearcoat(
  self : MaterialDesc,
  clearcoat : Float,
  roughness? : Float = 0.04,
) -> MaterialDesc {
  { ..self, clearcoat, clearcoat_roughness: roughness }
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
