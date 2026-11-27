// 3d/shadow-atlas — multi-light shadow atlas.
//
// One directional light and two spot lights each own a tile of the 2x2 depth
// atlas. The scene renders with and without shadows; the extra shadow passes
// must darken the ground and the spheres without validation errors.

///|
fn f75(i : Int) -> Float {
  Float::from_int(i)
}

///|
fn spot_node75(
  scene : @t3d.Scene,
  pos : @tmath.Vec3,
  target : @tmath.Vec3,
  light : @t3d.Light,
) -> Unit {
  let dir = (target - pos).normalize()
  let _ = scene.create_node(
    transform=@tmath.Transform::new(
      pos,
      @tmath.Quat::from_rotation_arc(@tmath.Vec3::neg_z(), dir),
      @tmath.Vec3::one(),
    ),
    payload=@t3d.NodePayload::Light(light),
  )
}

///|
fn build_scene75(
  renderer : @t3d.Renderer3D,
  dev : @tycho.Device,
) -> (@t3d.Scene, @t3d.CameraId, @tycho.Texture) raise {
  let scene = @t3d.Scene::new()
  let ground = renderer.upload_mesh(@tgeo.box(width=22.0, height=0.2, depth=22.0))
  let _ = renderer.create_pbr_node(
    scene,
    ground,
    @t3d.MaterialDesc::pbr(@t3d.srgb(0.38, 0.38, 0.41), roughness=0.85),
    transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, -0.95, 0.0)),
  )
  let sphere = renderer.upload_mesh(
    @tgeo.sphere(radius=0.85, width_segments=40, height_segments=20),
  )
  let xs : Array[Float] = [-3.0, 0.0, 3.0]
  for i = 0; i < 3; i = i + 1 {
    let _ = renderer.create_pbr_node(
      scene,
      sphere,
      @t3d.MaterialDesc::pbr(@t3d.srgb(0.85, 0.85, 0.88), metallic=0.2, roughness=0.35),
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(xs[i], -0.05, 0.0)),
    )
  }

  // Directional tile 0.
  let sun = @tmath.Vec3::new(-0.45, 0.8, -0.55).normalize()
  let _sun = scene.create_node(
    transform=@tmath.Transform::new(
      @tmath.Vec3::zero(),
      @tmath.Quat::from_rotation_arc(@tmath.Vec3::neg_z(), sun),
      @tmath.Vec3::one(),
    ),
    payload=@t3d.NodePayload::Light(
      @t3d.Light::directional(
        @tmath.Vec3::new(1.0, 0.97, 0.9),
        0.8,
        shadow=@t3d.ShadowDesc::default(),
      ),
    ),
  )
  // Tiles 1 and 2: warm and cool spots aimed at the outer spheres.
  spot_node75(
    scene,
    @tmath.Vec3::new(-5.2, 5.0, -3.0),
    @tmath.Vec3::new(-3.0, 0.0, 0.0),
    @t3d.Light::spot(
      @tmath.Vec3::new(1.0, 0.35, 0.2),
      90.0,
      range=18.0,
      inner_angle=0.36,
      outer_angle=0.50,
      shadow=@t3d.ShadowDesc::default(),
    ),
  )
  spot_node75(
    scene,
    @tmath.Vec3::new(5.2, 5.0, -3.0),
    @tmath.Vec3::new(3.0, 0.0, 0.0),
    @t3d.Light::spot(
      @tmath.Vec3::new(0.3, 0.6, 1.0),
      90.0,
      range=18.0,
      inner_angle=0.36,
      outer_angle=0.50,
      shadow=@t3d.ShadowDesc::default(),
    ),
  )
  let _ambient = scene.create_node(
    payload=@t3d.NodePayload::Light(@t3d.Light::ambient(@tmath.Vec3::one(), 0.03)),
  )
  let env = @t3d.procedural_environment_cubemap(dev, sun, size=128, samples=32)
  renderer.set_environment(env, sun, intensity=0.25)

  let orbit = @t3d.OrbitCamera::new(
    target=@tmath.Vec3::new(0.0, 0.2, 0.0),
    distance=12.5,
    yaw=0.30,
    pitch=0.42,
  )
  let fov : Float = 2.0 * @tmath.atan((1.0 : Float) / (1.8 : Float))
  let cam = @t3d.Camera::perspective(fov, (800.0 : Float) / (600.0 : Float), near=0.1)
  let cam_node = scene.add_camera(cam, transform=orbit.transform())
  (scene, cam_node, env)
}

///|
fn diff75(a : FixedArray[Byte], b : FixedArray[Byte]) -> Int {
  let mut n = 0
  let mut i = 0
  while i + 3 < a.length() {
    let d = (a[i].to_int() - b[i].to_int()).abs() +
      (a[i + 1].to_int() - b[i + 1].to_int()).abs() +
      (a[i + 2].to_int() - b[i + 2].to_int()).abs()
    if d > 24 {
      n = n + 1
    }
    i = i + 4
  }
  n
}

///|
fn main {
  try {
    let opts = @exwin.Options::parse("3d/shadow-atlas")
    let show_win = opts.window
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("3d/shadow-atlas", validation=true, headless=!show_win),
    )
    let r_on = @t3d.Renderer3D::new(dev)
    let r_off = @t3d.Renderer3D::new(
      dev,
      desc=@t3d.RendererDesc::default().with_shadows(false),
    )
    let (scene_on, cam_on, env_on) = build_scene75(r_on, dev)
    let (scene_off, cam_off, env_off) = build_scene75(r_off, dev)

    if !show_win {
      let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8Srgb)
      r_on.render_offscreen( rt,scene_on, cam_on)
      let px_on = rt.readback()
      let passes = r_on.stats().shadow_passes
      r_off.render_offscreen( rt,scene_off, cam_off)
      let px_off = rt.readback()

      let shadow_diff = diff75(px_on, px_off)
      let mut lit = 0
      let mut i = 0
      while i + 3 < px_on.length() {
        if px_on[i].to_int() + px_on[i + 1].to_int() + px_on[i + 2].to_int() > 30 {
          lit = lit + 1
        }
        i = i + 4
      }
      opts.capture(800, 600, px_on)
      let errs = dev.validation_errors()
      println(
        "[3d/shadow-atlas] \{r_on.stats().summary()} shadow_diff=\{shadow_diff} lit=\{lit} validation=\{errs}",
      )
      if errs == 0 && shadow_diff > 8000 && passes >= 6 && lit > 20000 {
        println("[3d/shadow-atlas] OK — directional + 2 spot shadows in one atlas")
      } else {
        println(
          "[3d/shadow-atlas] FAIL — diff=\{shadow_diff} passes=\{passes} lit=\{lit} errs=\{errs}",
        )
      }
      rt.destroy()
    } else {
      let sc = @exwin_rhi.open(dev, opts)
      while @exwin_rhi.next_frame(sc) {
        r_on.render_swapchain(sc, scene_on, cam_on)
      }
      sc.destroy()
    }

    let errs = dev.validation_errors()
    r_on.destroy()
    r_off.destroy()
    env_on.destroy()
    env_off.destroy()
    let leaks = dev.allocator_used_bytes()
    dev.destroy()
    if errs != 0 {
      println("[3d/shadow-atlas] validation errors: \{errs}")
    }
    if leaks != (0 : UInt64) {
      println("[3d/shadow-atlas] LEAK — \{leaks} bytes after destroy")
    }
  } catch {
    err => println("[3d/shadow-atlas] FAIL — \{err}")
  }
}
