// 3d/lod — distance-based mesh LOD.
//
// 30 spheres share one LOD node each: 48x32 / 20x12 / 8x5 spheres selected by
// camera distance. The gate compares the rendered triangle count against an
// all-LOD0 baseline and requires most far spheres to have switched.

///|
fn f86(i : Int) -> Float {
  Float::from_int(i)
}

///|
fn main {
  try {
    let show_win = @tycho.want_window()
    let shot = @tycho.screenshot_path()
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("3d/lod", validation=true, headless=!show_win),
    )
    let renderer = @t3d.Renderer3D::new(dev)
    let scene = @t3d.Scene::new()

    let l0 = renderer.upload_mesh(@tgeo.sphere(radius=0.8, width_segments=48, height_segments=32))
    let l1 = renderer.upload_mesh(@tgeo.sphere(radius=0.8, width_segments=20, height_segments=12))
    let l2 = renderer.upload_mesh(@tgeo.sphere(radius=0.8, width_segments=8, height_segments=5))
    let levels : Array[@t3d.MeshHandle] = [l0, l1, l2]
    let switches : Array[Float] = [13.0, 19.0]
    let l0_tris = 48 * 32 * 2
    let material = renderer.create_material(
      @t3d.MaterialDesc::pbr(@t3d.srgb(0.35, 0.62, 0.86), metallic=0.2, roughness=0.35),
    )

    let mut count = 0
    for row = 0; row < 5; row = row + 1 {
      for col = 0; col < 6; col = col + 1 {
        let x = (f86(col) - 2.5) * 3.4
        let z = (f86(row) - 2.0) * 3.4
        let _ = renderer.create_lod_node(
          scene,
          levels,
          switches,
          material,
          transform=@tmath.Transform::from_translation(@tmath.Vec3::new(x, 0.8, z)),
        )
        count = count + 1
      }
    }

    let ground = renderer.upload_mesh(@tgeo.box(width=70.0, height=0.2, depth=70.0))
    let _ = renderer.create_pbr_node(
      scene,
      ground,
      @t3d.MaterialDesc::pbr(@t3d.srgb(0.28, 0.30, 0.33), roughness=0.85),
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, -0.1, 0.0)),
    )
    let sun = @tmath.Vec3::new(-0.4, 0.85, -0.35).normalize()
    let _sun = scene.create_node(
      transform=@tmath.Transform::new(
        @tmath.Vec3::zero(),
        @tmath.Quat::from_rotation_arc(@tmath.Vec3::neg_z(), sun),
        @tmath.Vec3::one(),
      ),
      payload=@t3d.NodePayload::Light(
        @t3d.Light::directional(
          @tmath.Vec3::new(1.0, 0.97, 0.92),
          2.4,
          shadow=Some(@t3d.ShadowDesc::default()),
        ),
      ),
    )
    let _ambient = scene.create_node(
      payload=@t3d.NodePayload::Light(@t3d.Light::ambient(@tmath.Vec3::one(), 0.18)),
    )
    let env = @t3d.procedural_environment_cubemap(dev, sun, size=128, samples=32)
    renderer.set_environment(env, sun, intensity=0.9)

    let orbit = @t3d.OrbitCamera::new(
      target=@tmath.Vec3::new(0.0, 0.5, 0.0),
      distance=18.0,
      yaw=0.0,
      pitch=0.42,
    )
    let fov : Float = 2.0 * @tmath.atan((1.0 : Float) / (1.9 : Float))
    let cam = @t3d.Camera::perspective(fov, (800.0 : Float) / (600.0 : Float), near=0.1)
    let cam_node = scene.create_node(
      transform=orbit.transform(),
      payload=@t3d.NodePayload::Camera(cam),
    )

    if !show_win {
      let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8Srgb)
      renderer.render_offscreen(scene, cam_node, rt)
      let px = rt.readback()
      let stats = renderer.stats()
      let baseline = 30 * l0_tris
      let mut lit = 0
      let mut i = 0
      while i + 3 < px.length() {
        if px[i].to_int() + px[i + 1].to_int() + px[i + 2].to_int() > 30 {
          lit = lit + 1
        }
        i = i + 4
      }
      if shot != "" {
        let _ = @tycho.save_png(shot, 800, 600, px)
      }
      let errs = dev.validation_errors()
      println(
        "[3d/lod] \{stats.summary()} tris=\{stats.triangles} baseline=\{baseline} lit=\{lit} validation=\{errs}",
      )
      if errs == 0 &&
        stats.lod_switches >= 10 &&
        stats.instance_batches >= 2 &&
        stats.triangles * 3 < baseline &&
        lit > 10000 {
        println("[3d/lod] OK — distance LOD cuts triangles and switches levels")
      } else {
        println(
          "[3d/lod] FAIL — switches=\{stats.lod_switches} tris=\{stats.triangles} baseline=\{baseline} errs=\{errs}",
        )
      }
      rt.destroy()
    } else {
      let sc = dev.create_swapchain("3d/lod", 800, 600)
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
      println("[3d/lod] validation errors: \{errs}")
    }
    if leaks != (0 : UInt64) {
      println("[3d/lod] LEAK — \{leaks} bytes after destroy")
    }
  } catch {
    err => println("[3d/lod] FAIL — \{err}")
  }
}
