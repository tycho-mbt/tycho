// Light components. Colors are linear RGB and may exceed 1 for HDR emitters.
// A light's direction is the node's world -Z axis (same convention as cameras).

///|
pub(all) struct ShadowDesc {
  map_size : Int
  // Raster depth bias and slope-scaled bias (49's verified defaults).
  bias : Float
  normal_bias : Float
  pcf_radius : Int
  // Orthographic half extent; `None` auto-fits the caster bounds.
  half_extents : Float?
}

///|
pub fn ShadowDesc::default() -> ShadowDesc {
  {
    map_size: 1024,
    bias: 1.5,
    normal_bias: 1.75,
    pcf_radius: 3,
    half_extents: None,
  }
}

///|
pub(all) struct DirectionalLight {
  color : @tmath.Vec3
  intensity : Float
  shadow : ShadowDesc?
}

///|
pub(all) struct PointLight {
  color : @tmath.Vec3
  intensity : Float
  range : Float
  decay : Float
  // Six-face cube shadow rendered into the atlas when present.
  shadow : ShadowDesc?
}

///|
pub(all) struct SpotLight {
  color : @tmath.Vec3
  intensity : Float
  range : Float
  inner_angle : Float
  outer_angle : Float
  // Spot shadows render into the shared atlas (one tile per light).
  shadow : ShadowDesc?
}

///|
pub(all) struct AmbientLight {
  color : @tmath.Vec3
  intensity : Float
}

///|
pub(all) struct HemisphereLight {
  sky : @tmath.Vec3
  ground : @tmath.Vec3
  intensity : Float
}

///|
pub(all) enum Light {
  Directional(DirectionalLight)
  Point(PointLight)
  Spot(SpotLight)
  Ambient(AmbientLight)
  Hemisphere(HemisphereLight)
}

///|
pub fn Light::directional(
  color : @tmath.Vec3,
  intensity : Float,
  shadow? : ShadowDesc? = None,
) -> Light {
  Light::Directional({ color, intensity, shadow })
}

///|
pub fn Light::point(
  color : @tmath.Vec3,
  intensity : Float,
  range? : Float = 10.0,
  decay? : Float = 2.0,
  shadow? : ShadowDesc? = None,
) -> Light {
  Light::Point({ color, intensity, range, decay, shadow })
}

///|
pub fn Light::spot(
  color : @tmath.Vec3,
  intensity : Float,
  range? : Float = 10.0,
  inner_angle? : Float = 0.35,
  outer_angle? : Float = 0.55,
  shadow? : ShadowDesc? = None,
) -> Light {
  Light::Spot({ color, intensity, range, inner_angle, outer_angle, shadow })
}

///|
pub fn Light::ambient(color : @tmath.Vec3, intensity : Float) -> Light {
  Light::Ambient({ color, intensity })
}

///|
pub fn Light::hemisphere(
  sky : @tmath.Vec3,
  ground : @tmath.Vec3,
  intensity : Float,
) -> Light {
  Light::Hemisphere({ sky, ground, intensity })
}

///|
pub fn Light::cast_shadow(self : Light) -> Bool {
  match self {
    Directional(l) =>
      match l.shadow {
        Some(_) => true
        None => false
      }
    Spot(l) =>
      match l.shadow {
        Some(_) => true
        None => false
      }
    _ => false
  }
}

///|
/// Add a directional light node whose -Z axis points along `direction`
/// (the same convention as cameras). Absorbs the repeated rotation boilerplate.
pub fn add_sun(
  scene : Scene,
  direction : @tmath.Vec3,
  color? : @tmath.Vec3 = @tmath.Vec3::one(),
  intensity? : Float = 1.0,
  shadow? : Bool = true,
) -> NodeId {
  scene.create_node(
    transform=@tmath.Transform::new(
      @tmath.Vec3::zero(),
      @tmath.Quat::from_rotation_arc(@tmath.Vec3::neg_z(), direction.normalize()),
      @tmath.Vec3::one(),
    ),
    payload=NodePayload::Light(
      Light::directional(
        color,
        intensity,
        shadow=if shadow { Some(ShadowDesc::default()) } else { None },
      ),
    ),
  )
}

///|
pub fn add_ambient(
  scene : Scene,
  color? : @tmath.Vec3 = @tmath.Vec3::one(),
  intensity? : Float = 0.2,
) -> NodeId {
  scene.create_node(payload=NodePayload::Light(Light::ambient(color, intensity)))
}
