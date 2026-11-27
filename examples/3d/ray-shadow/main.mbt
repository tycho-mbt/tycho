// 3d/ray-shadow — hardware ray-traced sun shadows (VK_KHR_ray_query).
//
// Shadow maps are disabled, so the only sun occlusion comes from a per-fragment
// ray traced against the scene TLAS. Toggling ray shadows off must remove them.

///|
fn f90(i : Int) -> Float {
  Float::from_int(i)
}

///|
fn diff90(a : FixedArray[Byte], b : FixedArray[Byte]) -> Int {
  let mut n = 0
  let mut i = 0
  while i + 3 < a.length() {
    let d = (a[i].to_int() - b[i].to_int()).abs() +
      (a[i + 1].to_int() - b[i + 1].to_int()).abs() +
      (a[i + 2].to_int() - b[i + 2].to_int()).abs()
    if d > 18 {
      n = n + 1
    }
    i = i + 4
  }
  n
}

///|
fn main {
  try {
    let opts = @exwin.Options::parse("3d/ray-shadow")
    let show_win = opts.window
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("3d/ray-shadow", validation=true, headless=!show_win),
    )
    // No shadow maps: every sun shadow must come from the ray query.
    let desc : @t3d.RendererDesc = {
      max_objects: 1024,
      max_lights: 8,
      max_materials: 64,
      max_textures: 64,
      msaa: false,
      bloom: false,
      shadows: false,
      shadow_map_size: 512,
      shadow_cascades: 1,
      gpu_culling: false,
      bindless: true,
    }
    let renderer = @t3d.Renderer3D::new(dev, desc=desc)
    // Opt in: other scenes keep map shadows only.
    renderer.set_ray_shadows(true)
    let scene = @t3d.Scene::new()

    let ground = renderer.upload_mesh(@tgeo.box(width=18.0, height=0.2, depth=18.0))
    let _ = renderer.create_pbr_node(
      scene,
      ground,
      @t3d.MaterialDesc::pbr(@t3d.srgb(0.40, 0.42, 0.46), roughness=0.9),
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, -0.1, 0.0)),
    )
    let wall = renderer.upload_mesh(@tgeo.box(width=2.4, height=2.6, depth=0.5))
    let ball = renderer.upload_mesh(@tgeo.sphere(radius=0.9, width_segments=24, height_segments=16))
    for i = 0; i < 4; i = i + 1 {
      let x = (f90(i) - 1.5) * 2.6
      let _ = renderer.create_pbr_node(
        scene,
        wall,
        @t3d.MaterialDesc::pbr(@t3d.srgb(0.78, 0.52, 0.30), roughness=0.5),
        transform=@tmath.Transform::from_translation(@tmath.Vec3::new(x, 1.2, 0.0)),
      )
    }
    let _ = renderer.create_pbr_node(
      scene,
      ball,
      @t3d.MaterialDesc::pbr(@t3d.srgb(0.30, 0.55, 0.82), metallic=0.4, roughness=0.25),
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, 3.2, 0.0)),
    )
    let sun = @tmath.Vec3::new(-0.55, 0.75, 0.36).normalize()
    let _sun = scene.create_node(
      transform=@tmath.Transform::new(
        @tmath.Vec3::zero(),
        @tmath.Quat::from_rotation_arc(@tmath.Vec3::neg_z(), sun),
        @tmath.Vec3::one(),
      ),
      payload=@t3d.NodePayload::Light(
        @t3d.Light::directional(@tmath.Vec3::new(1.0, 0.97, 0.92), 3.2),
      ),
    )
    let _ambient = scene.create_node(
      payload=@t3d.NodePayload::Light(@t3d.Light::ambient(@tmath.Vec3::one(), 0.14)),
    )
    let env = @t3d.procedural_environment_cubemap(dev, sun, size=64, samples=16)
    renderer.set_environment(env, sun, intensity=0.4)

    let orbit = @t3d.OrbitCamera::new(
      target=@tmath.Vec3::new(0.0, 1.4, 0.0),
      distance=11.0,
      yaw=0.5,
      pitch=0.3,
    )
    let fov : Float = 2.0 * @tmath.atan((1.0 : Float) / (2.1 : Float))
    let cam = @t3d.Camera::perspective(fov, (640.0 : Float) / (480.0 : Float), near=0.1)
    let cam_node = scene.create_node(
      transform=orbit.transform(),
      payload=@t3d.NodePayload::Camera(cam),
    )

    if !show_win {
      let rt_ok = renderer.ray_shadows_supported()
      let rt = dev.create_render_target(640, 480, @tycho.TextureFormat::RGBA8Srgb)
      renderer.render_offscreen( rt,scene, cam_node)
      let px_rt = rt.readback()

      renderer.set_ray_shadows(false)
      renderer.render_offscreen( rt,scene, cam_node)
      let px_plain = rt.readback()

      let diff = diff90(px_rt, px_plain)
      opts.capture(640, 480, px_rt)
      let errs = dev.validation_errors()
      println(
        "[3d/ray-shadow] rt_supported=\{rt_ok} rt_diff=\{diff} validation=\{errs}",
      )
      if errs == 0 && ((rt_ok && diff > 4000) || !rt_ok) {
        if rt_ok {
          println("[3d/ray-shadow] OK — ray query casts the sun shadows")
        } else {
          println("[3d/ray-shadow] OK — device lacks ray query, skipped")
        }
      } else {
        println(
          "[3d/ray-shadow] FAIL — supported=\{rt_ok} diff=\{diff} errs=\{errs}",
        )
      }
      rt.destroy()
    } else {
      let sc = @exwin_rhi.open(dev, opts)
      while true {
        let (events, stop) = @exwin_rhi.poll(sc)
        if stop {
          break
        }
        for ev in events {
          if orbit.apply(ev) {
            scene.set_transform(cam_node, orbit.transform())
          }
        }
        renderer.render_swapchain(sc, scene, cam_node)
      }
      sc.destroy()
    }

    let errs = dev.validation_errors()
    renderer.destroy()
    env.destroy()
    let leaks = dev.allocator_used_bytes()
    dev.destroy()
    if errs != 0 {
      println("[3d/ray-shadow] validation errors: \{errs}")
    }
    if leaks != (0 : UInt64) {
      println("[3d/ray-shadow] LEAK — \{leaks} bytes after destroy")
    }
  } catch {
    err => println("[3d/ray-shadow] FAIL — \{err}")
  }
}
