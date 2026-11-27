// 3d/point-shadow — point-light cube shadows.
//
// A single point light sits above six pillars. Its shadow renders six cube faces
// into the 4x2 atlas; toggling to an identical light without a shadow isolates
// the effect. The gate requires >= 6 shadow draws and a large pixel delta.

///|
fn f89(i : Int) -> Float {
  Float::from_int(i)
}

///|
fn diff89(a : FixedArray[Byte], b : FixedArray[Byte]) -> Int {
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
    let show_win = @tycho.want_window()
    let shot = @tycho.screenshot_path()
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("3d/point-shadow", validation=true, headless=!show_win),
    )
    let renderer = @t3d.Renderer3D::new(dev)
    let scene = @t3d.Scene::new()

    let ground = renderer.upload_mesh(@tgeo.box(width=22.0, height=0.2, depth=22.0))
    let _ = renderer.create_pbr_node(
      scene,
      ground,
      @t3d.MaterialDesc::pbr(@t3d.srgb(0.36, 0.38, 0.42), roughness=0.9),
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, -0.1, 0.0)),
    )
    let pillar = renderer.upload_mesh(@tgeo.box(width=0.6, height=2.6, depth=0.6))
    for i = 0; i < 6; i = i + 1 {
      let ang = f89(i) * (@tmath.PI / 3.0)
      let x = @tmath.cos(ang) * 2.9
      let z = @tmath.sin(ang) * 2.9
      let _ = renderer.create_pbr_node(
        scene,
        pillar,
        @t3d.MaterialDesc::pbr(@t3d.srgb(0.82, 0.55, 0.30), roughness=0.45),
        transform=@tmath.Transform::from_translation(@tmath.Vec3::new(x, 1.2, z)),
      )
    }

    let light_pos = @tmath.Vec3::new(0.0, 3.6, 0.0)
    let with_shadow = scene.create_node(
      transform=@tmath.Transform::from_translation(light_pos),
      payload=@t3d.NodePayload::Light(
        @t3d.Light::point(
          @tmath.Vec3::new(1.0, 0.82, 0.55),
          52.0,
          range=16.0,
          shadow=Some(@t3d.ShadowDesc::default()),
        ),
      ),
    )
    let _ambient = scene.create_node(
      payload=@t3d.NodePayload::Light(@t3d.Light::ambient(@tmath.Vec3::new(0.3, 0.35, 0.45), 0.10)),
    )
    let sun = @tmath.Vec3::new(-0.3, 0.9, -0.25).normalize()
    let env = @t3d.procedural_environment_cubemap(dev, sun, size=64, samples=16)
    renderer.set_environment(env, sun, intensity=0.25)

    let orbit = @t3d.OrbitCamera::new(
      target=@tmath.Vec3::new(0.0, 1.0, 0.0),
      distance=12.0,
      yaw=0.6,
      pitch=0.33,
    )
    let fov : Float = 2.0 * @tmath.atan((1.0 : Float) / (2.0 : Float))
    let cam = @t3d.Camera::perspective(fov, (800.0 : Float) / (600.0 : Float), near=0.1)
    let cam_node = scene.create_node(
      transform=orbit.transform(),
      payload=@t3d.NodePayload::Camera(cam),
    )

    if !show_win {
      let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8Srgb)
      renderer.render_offscreen(scene, cam_node, rt)
      let px_on = rt.readback()
      let stats_on = renderer.stats()

      scene.set_payload(
        with_shadow,
        @t3d.NodePayload::Light(
          @t3d.Light::point(@tmath.Vec3::new(1.0, 0.82, 0.55), 52.0, range=16.0),
        ),
      )
      renderer.render_offscreen(scene, cam_node, rt)
      let px_off = rt.readback()

      let diff = diff89(px_on, px_off)
      if shot != "" {
        let _ = @tycho.save_png(shot, 800, 600, px_on)
      }
      let errs = dev.validation_errors()
      println(
        "[3d/point-shadow] \{stats_on.summary()} cube_diff=\{diff} validation=\{errs}",
      )
      if errs == 0 && stats_on.shadow_passes >= 6 && diff > 5000 {
        println("[3d/point-shadow] OK — six cube faces occlude the point light")
      } else {
        println(
          "[3d/point-shadow] FAIL — shadow_passes=\{stats_on.shadow_passes} diff=\{diff} errs=\{errs}",
        )
      }
      rt.destroy()
    } else {
      let sc = dev.create_swapchain("3d/point-shadow", 800, 600)
      let mut quit = false
      while !sc.should_close() && !quit {
        for ev in sc.poll_events() {
          match ev {
            @tycho.Event::CloseRequested => quit = true
            @tycho.Event::KeyDown(k, _) => if k == @tycho.KEY_ESCAPE {
              quit = true
            }
            _ => ()
          }
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
      println("[3d/point-shadow] validation errors: \{errs}")
    }
    if leaks != (0 : UInt64) {
      println("[3d/point-shadow] LEAK — \{leaks} bytes after destroy")
    }
  } catch {
    err => println("[3d/point-shadow] FAIL — \{err}")
  }
}
