// 3d/brdf-fallback — split-sum BRDF LUT + non-bindless material fallback.
//
// Two renderers build the same textured scene: one samples material maps from
// the bindless heap, the other from per-batch albedo/normal bindings. Their
// images must match, and the baked LUT must behave like A + B <= 1 with a
// smooth end near 1 and a rough end near 0.

///|
fn f74(i : Int) -> Float {
  Float::from_int(i)
}

///|
fn checker74(size : Int) -> FixedArray[Byte] {
  let px = FixedArray::make(size * size * 4, (0 : Byte))
  for y = 0; y < size; y = y + 1 {
    for x = 0; x < size; x = x + 1 {
      let warm = ((x / 4) + (y / 4)) % 2 == 0
      let o = (y * size + x) * 4
      px[o] = (if warm { 235 } else { 45 }).to_byte()
      px[o + 1] = (if warm { 150 } else { 70 }).to_byte()
      px[o + 2] = (if warm { 60 } else { 150 }).to_byte()
      px[o + 3] = (255 : Byte)
    }
  }
  px
}

///|
fn ripple_normal74(size : Int) -> FixedArray[Byte] {
  let px = FixedArray::make(size * size * 4, (0 : Byte))
  for y = 0; y < size; y = y + 1 {
    for x = 0; x < size; x = x + 1 {
      let dhx : Float = @tmath.sin(f74(x) * 0.8) * 0.55
      let dhy : Float = @tmath.cos(f74(y) * 0.7) * 0.45
      let inv : Float = 1.0 / @tmath.sqrt(dhx * dhx + dhy * dhy + (1.0 : Float))
      let o = (y * size + x) * 4
      px[o] = ((dhx * inv + 1.0) * 127.5).to_int().to_byte()
      px[o + 1] = ((dhy * inv + 1.0) * 127.5).to_int().to_byte()
      px[o + 2] = ((inv + 1.0) * 127.5).to_int().to_byte()
      px[o + 3] = (255 : Byte)
    }
  }
  px
}

///|
fn build_scene74(
  renderer : @t3d.Renderer3D,
  dev : @tycho.Device,
) -> (@t3d.Scene, @t3d.CameraId, @tycho.Texture) raise {
  let scene = @t3d.Scene::new()
  let albedo = renderer.create_texture(16, 16, checker74(16), srgb=true)
  let normal = renderer.create_texture(16, 16, ripple_normal74(16), srgb=false)

  let ground_mesh = renderer.upload_mesh(@tgeo.box(width=18.0, height=0.2, depth=18.0))
  let _ = renderer.create_pbr_node(
    scene,
    ground_mesh,
    @t3d.MaterialDesc::pbr(@t3d.srgb(0.26, 0.28, 0.32), roughness=0.8),
    transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, -0.95, 0.0)),
  )
  let sphere = renderer.upload_mesh(
    @tgeo.sphere(radius=0.85, width_segments=40, height_segments=20),
  )
  let _ = renderer.create_pbr_node(
    scene,
    sphere,
    @t3d.MaterialDesc::pbr(@t3d.srgb(1.0, 1.0, 1.0), roughness=0.35)
    .with_albedo_tex(albedo),
    transform=@tmath.Transform::from_translation(@tmath.Vec3::new(-2.6, -0.05, 0.0)),
  )
  let _ = renderer.create_pbr_node(
    scene,
    sphere,
    @t3d.MaterialDesc::pbr(@t3d.srgb(1.0, 1.0, 1.0), roughness=0.30)
    .with_albedo_tex(albedo)
    .with_normal_tex(normal),
    transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, -0.05, 0.0)),
  )
  // No textures: exercises the white / flat-normal fallbacks in both paths.
  let _ = renderer.create_pbr_node(
    scene,
    sphere,
    @t3d.MaterialDesc::pbr(@t3d.srgb(0.95, 0.72, 0.30), metallic=1.0, roughness=0.12),
    transform=@tmath.Transform::from_translation(@tmath.Vec3::new(2.6, -0.05, 0.0)),
  )

  let sun = @tmath.Vec3::new(-0.45, 0.75, -0.55).normalize()
  let _sun_node = scene.create_node(
    transform=@tmath.Transform::new(
      @tmath.Vec3::zero(),
      @tmath.Quat::from_rotation_arc(@tmath.Vec3::neg_z(), sun),
      @tmath.Vec3::one(),
    ),
    payload=@t3d.NodePayload::Light(
      @t3d.Light::directional(
        @tmath.Vec3::new(1.0, 0.95, 0.88),
        2.4,
        shadow=@t3d.ShadowDesc::default(),
      ),
    ),
  )
  let _ambient = scene.create_node(
    payload=@t3d.NodePayload::Light(@t3d.Light::ambient(@tmath.Vec3::one(), 0.18)),
  )
  let env = @t3d.procedural_environment_cubemap(dev, sun, size=128, samples=32)
  renderer.set_environment(env, sun)

  let orbit = @t3d.OrbitCamera::new(
    target=@tmath.Vec3::new(0.0, 0.0, 0.0),
    distance=8.0,
    yaw=0.35,
    pitch=0.30,
  )
  let fov : Float = 2.0 * @tmath.atan((1.0 : Float) / (1.8 : Float))
  let cam = @t3d.Camera::perspective(fov, (800.0 : Float) / (600.0 : Float), near=0.1)
  let cam_node = scene.add_camera(cam, transform=orbit.transform())
  (scene, cam_node, env)
}

///|
fn diff74(a : FixedArray[Byte], b : FixedArray[Byte]) -> Int {
  let mut n = 0
  let mut i = 0
  while i + 3 < a.length() {
    let d = (a[i].to_int() - b[i].to_int()).abs() +
      (a[i + 1].to_int() - b[i + 1].to_int()).abs() +
      (a[i + 2].to_int() - b[i + 2].to_int()).abs()
    if d > 12 {
      n = n + 1
    }
    i = i + 4
  }
  n
}

///|
fn le16(px : FixedArray[Byte], i : Int) -> UInt16 {
  (px[i].to_uint() | (px[i + 1].to_uint() << 8)).to_uint16()
}

///|
fn lut_at(px : FixedArray[Byte], x : Int, y : Int) -> (Float, Float) {
  let i = (y * 64 + x) * 4
  (
    @t3d.f16_to_float(le16(px, i)),
    @t3d.f16_to_float(le16(px, i + 2)),
  )
}

///|
fn main {
  try {
    let opts = @exwin.Options::parse("3d/brdf-fallback")
    let show_win = opts.window
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("3d/brdf-fallback", validation=true, headless=!show_win),
    )
    let r_bindless = @t3d.Renderer3D::new(dev)
    let r_fallback = @t3d.Renderer3D::new(
      dev,
      desc=@t3d.RendererDesc::default().with_bindless(false),
    )
    let (scene_a, cam_a, env_a) = build_scene74(r_bindless, dev)
    let (scene_b, cam_b, env_b) = build_scene74(r_fallback, dev)

    if !show_win {
      let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8Srgb)
      r_bindless.render_offscreen( rt,scene_a, cam_a)
      let px_a = rt.readback()
      r_fallback.render_offscreen( rt,scene_b, cam_b)
      let px_b = rt.readback()

      let diff = diff74(px_a, px_b)
      let mut lit = 0
      let mut warm = 0
      let mut i = 0
      while i + 3 < px_a.length() {
        let r = px_a[i].to_int()
        let g = px_a[i + 1].to_int()
        let b = px_a[i + 2].to_int()
        if r + g + b > 30 {
          lit = lit + 1
        }
        if r > 140 && g > 80 && b < 90 {
          warm = warm + 1
        }
        i = i + 4
      }

      // LUT: column NdotV ~ 1, the two extreme roughness rows.
      let lut = r_bindless.brdf_lut().readback()
      let (a0, b0) = lut_at(lut, 63, 0)
      let (a1, b1) = lut_at(lut, 63, 63)
      let (a_mid, b_mid) = lut_at(lut, 32, 32)
      let smooth_end = if a0 > a1 { (a0, b0) } else { (a1, b1) }
      let rough_end = if a0 > a1 { (a1, b1) } else { (a0, b0) }
      let lut_ok = smooth_end.0 > 0.9 &&
        rough_end.0 < smooth_end.0 &&
        smooth_end.1 < rough_end.1 &&
        a_mid >= 0.0 &&
        a_mid + b_mid <= 1.02

      opts.capture(800, 600, px_a)
      let errs = dev.validation_errors()
      println(
        "[3d/brdf-fallback] \{r_bindless.stats().summary()} fallback_diff=\{diff} lut=\{smooth_end.0}/\{rough_end.0} lit=\{lit} warm=\{warm} validation=\{errs}",
      )
      if errs == 0 && diff < 600 && lut_ok && lit > 20000 && warm > 200 {
        println("[3d/brdf-fallback] OK — split-sum LUT + non-bindless material path")
      } else {
        println(
          "[3d/brdf-fallback] FAIL — diff=\{diff} lut_ok=\{lut_ok} lit=\{lit} warm=\{warm} errs=\{errs}",
        )
      }
      rt.destroy()
    } else {
      let sc = @exwin_rhi.open(dev, opts)
      while @exwin_rhi.next_frame(sc) {
        r_bindless.render_swapchain(sc, scene_a, cam_a)
      }
      sc.destroy()
    }

    let errs = dev.validation_errors()
    r_bindless.destroy()
    r_fallback.destroy()
    env_a.destroy()
    env_b.destroy()
    let leaks = dev.allocator_used_bytes()
    dev.destroy()
    if errs != 0 {
      println("[3d/brdf-fallback] validation errors: \{errs}")
    }
    if leaks != (0 : UInt64) {
      println("[3d/brdf-fallback] LEAK — \{leaks} bytes after destroy")
    }
  } catch {
    err => println("[3d/brdf-fallback] FAIL — \{err}")
  }
}
