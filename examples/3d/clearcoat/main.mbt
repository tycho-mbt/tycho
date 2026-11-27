// 3d/clearcoat — Physical clearcoat.
//
// The same sphere is rendered twice, once with a plain dielectric and once with
// clearcoat=1 at coat roughness 0.25. Only the second lobe differs, so the
// pixel delta isolates the coating and the peak luminance must rise.

///|
fn diff87(a : FixedArray[Byte], b : FixedArray[Byte]) -> Int {
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
fn peak87(px : FixedArray[Byte]) -> Int {
  let mut m = 0
  let mut i = 0
  while i + 3 < px.length() {
    let l = px[i].to_int() + px[i + 1].to_int() + px[i + 2].to_int()
    if l > m {
      m = l
    }
    i = i + 4
  }
  m
}

///|
fn main {
  try {
    let opts = @exwin.Options::parse("3d/clearcoat")
    let show_win = opts.window
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("3d/clearcoat", validation=true, headless=!show_win),
    )
    let renderer = @t3d.Renderer3D::new(dev)
    let scene = @t3d.Scene::new()

    let ball = renderer.upload_mesh(@tgeo.sphere(radius=1.2, width_segments=64, height_segments=40))
    let ground = renderer.upload_mesh(@tgeo.box(width=14.0, height=0.2, depth=14.0))
    let _ = renderer.create_pbr_node(
      scene,
      ground,
      @t3d.MaterialDesc::pbr(@t3d.srgb(0.22, 0.24, 0.28), roughness=0.8),
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, -1.25, 0.0)),
    )
    let base = @t3d.MaterialDesc::pbr(
      @t3d.srgb(0.10, 0.16, 0.30),
      metallic=0.0,
      roughness=0.55,
    )
    let plain = renderer.create_material(base)
    let coated = renderer.create_material(base.with_clearcoat(1.0, roughness=0.22))
    let plain_node = renderer.create_mesh_node(scene, ball, plain)
    let coat_node = renderer.create_mesh_node(scene, ball, coated)
    scene.set_visible(coat_node, false)

    let sun = @tmath.Vec3::new(-0.5, 0.72, -0.45).normalize()
    let _sun = scene.create_node(
      transform=@tmath.Transform::new(
        @tmath.Vec3::zero(),
        @tmath.Quat::from_rotation_arc(@tmath.Vec3::neg_z(), sun),
        @tmath.Vec3::one(),
      ),
      payload=@t3d.NodePayload::Light(
        @t3d.Light::directional(
          @tmath.Vec3::new(1.0, 0.98, 0.94),
          3.0,
          shadow=@t3d.ShadowDesc::default(),
        ),
      ),
    )
    let _ambient = scene.create_node(
      payload=@t3d.NodePayload::Light(@t3d.Light::ambient(@tmath.Vec3::one(), 0.14)),
    )
    let env = @t3d.procedural_environment_cubemap(dev, sun, size=128, samples=48)
    renderer.set_environment(env, sun, intensity=1.1)

    let orbit = @t3d.OrbitCamera::new(
      target=@tmath.Vec3::new(0.0, 0.0, 0.0),
      distance=6.0,
      yaw=0.4,
      pitch=0.22,
    )
    let fov : Float = 2.0 * @tmath.atan((1.0 : Float) / (2.2 : Float))
    let cam = @t3d.Camera::perspective(fov, (800.0 : Float) / (600.0 : Float), near=0.1)
    let cam_node = scene.add_camera(cam, transform=orbit.transform())

    if !show_win {
      let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8Srgb)
      renderer.render_offscreen( rt,scene, cam_node)
      let px_off = rt.readback()

      scene.set_visible(plain_node, false)
      scene.set_visible(coat_node, true)
      renderer.render_offscreen( rt,scene, cam_node)
      let px_on = rt.readback()

      let diff = diff87(px_off, px_on)
      let peak_off = peak87(px_off)
      let peak_on = peak87(px_on)
      opts.capture(800, 600, px_on)
      let errs = dev.validation_errors()
      println(
        "[3d/clearcoat] \{renderer.stats().summary()} coat_diff=\{diff} peak_off=\{peak_off} peak_on=\{peak_on} validation=\{errs}",
      )
      if errs == 0 && diff > 2000 && peak_on > peak_off + 40 {
        println("[3d/clearcoat] OK — clearcoat adds a second specular lobe")
      } else {
        println(
          "[3d/clearcoat] FAIL — diff=\{diff} peak_off=\{peak_off} peak_on=\{peak_on} errs=\{errs}",
        )
      }
      rt.destroy()
    } else {
      let sc = @exwin_rhi.open(dev, opts)
      let mut quit = false
      let mut coated_on = true
      while !sc.should_close() && !quit {
        for ev in sc.poll_events() {
          match ev {
            @tycho.Event::CloseRequested => quit = true
            @tycho.Event::KeyDown(k, _) => {
              if k == @tycho.KeyCode::Escape {
                quit = true
              } else if k == @tycho.KeyCode::Space {
                coated_on = !coated_on
                scene.set_visible(plain_node, !coated_on)
                scene.set_visible(coat_node, coated_on)
              }
            }
            _ => ()
          }
          if orbit.apply(ev) {
            scene.set_transform(cam_node.node(), orbit.transform())
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
      println("[3d/clearcoat] validation errors: \{errs}")
    }
    if leaks != (0 : UInt64) {
      println("[3d/clearcoat] LEAK — \{leaks} bytes after destroy")
    }
  } catch {
    err => println("[3d/clearcoat] FAIL — \{err}")
  }
}
