// 3d/morph — GPU morph targets.
//
// A sphere carries two additive deltas (inflate, ripple). Rendering with (0,0),
// (1,0) and (0,1) must produce three distinct images, and the morph shadow path
// must stay valid.

///|
fn diff88(a : FixedArray[Byte], b : FixedArray[Byte]) -> Int {
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
fn make_morph_sphere() -> @tgeo.MeshData raise {
  let mesh = @tgeo.sphere(radius=1.0, width_segments=48, height_segments=32)
  let n = mesh.vertex_count()
  let inflate = FixedArray::make(n, @tmath.Vec3::zero())
  let ripple = FixedArray::make(n, @tmath.Vec3::zero())
  for i = 0; i < n; i = i + 1 {
    let p = mesh.positions[i]
    inflate[i] = p.normalize().scale(0.35)
    let wave = @tmath.sin(p.y * 7.0)
    ripple[i] = @tmath.Vec3::new(wave * 0.22, 0.0, wave * 0.12)
  }
  mesh.add_morph_target(inflate)
  mesh.add_morph_target(ripple)
  mesh
}

///|
fn main {
  try {
    let opts = @exwin.Options::parse("3d/morph")
    let show_win = opts.window
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("3d/morph", validation=true, headless=!show_win),
    )
    let renderer = @t3d.Renderer3D::new(dev)
    let scene = @t3d.Scene::new()

    let blob = renderer.upload_mesh(make_morph_sphere())
    let ground = renderer.upload_mesh(@tgeo.box(width=14.0, height=0.2, depth=14.0))
    let _ = renderer.create_pbr_node(
      scene,
      ground,
      @t3d.MaterialDesc::pbr(@t3d.srgb(0.24, 0.26, 0.30), roughness=0.85),
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, -1.25, 0.0)),
    )
    let node = renderer.create_morph_node(
      scene,
      blob,
      @t3d.MaterialDesc::pbr(@t3d.srgb(0.82, 0.42, 0.30), metallic=0.1, roughness=0.38),
      [0.0, 0.0],
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, 0.0, 0.0)),
    )

    let sun = @tmath.Vec3::new(-0.45, 0.78, -0.42).normalize()
    let _sun = scene.create_node(
      transform=@tmath.Transform::new(
        @tmath.Vec3::zero(),
        @tmath.Quat::from_rotation_arc(@tmath.Vec3::neg_z(), sun),
        @tmath.Vec3::one(),
      ),
      payload=@t3d.NodePayload::Light(
        @t3d.Light::directional(
          @tmath.Vec3::new(1.0, 0.97, 0.92),
          2.6,
          shadow=Some(@t3d.ShadowDesc::default()),
        ),
      ),
    )
    let _ambient = scene.create_node(
      payload=@t3d.NodePayload::Light(@t3d.Light::ambient(@tmath.Vec3::one(), 0.16)),
    )
    let env = @t3d.procedural_environment_cubemap(dev, sun, size=128, samples=32)
    renderer.set_environment(env, sun, intensity=0.9)

    let orbit = @t3d.OrbitCamera::new(
      target=@tmath.Vec3::new(0.0, 0.0, 0.0),
      distance=5.6,
      yaw=0.35,
      pitch=0.2,
    )
    let fov : Float = 2.0 * @tmath.atan((1.0 : Float) / (2.3 : Float))
    let cam = @t3d.Camera::perspective(fov, (800.0 : Float) / (600.0 : Float), near=0.1)
    let cam_node = scene.create_node(
      transform=orbit.transform(),
      payload=@t3d.NodePayload::Camera(cam),
    )

    if !show_win {
      let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8Srgb)
      renderer.render_offscreen(scene, cam_node, rt)
      let rest = rt.readback()

      renderer.set_morph_weights(node, [1.0, 0.0])
      renderer.render_offscreen(scene, cam_node, rt)
      let inflated = rt.readback()

      renderer.set_morph_weights(node, [0.0, 1.0])
      renderer.render_offscreen(scene, cam_node, rt)
      let rippled = rt.readback()

      let d_inflate = diff88(rest, inflated)
      let d_ripple = diff88(rest, rippled)
      let d_both = diff88(inflated, rippled)
      opts.capture(800, 600, rippled)
      let errs = dev.validation_errors()
      let stats = renderer.stats()
      println(
        "[3d/morph] \{stats.summary()} inflate_diff=\{d_inflate} ripple_diff=\{d_ripple} cross_diff=\{d_both} validation=\{errs}",
      )
      if errs == 0 &&
        d_inflate > 6000 &&
        d_ripple > 6000 &&
        d_both > 4000 &&
        stats.shadow_passes >= 2 {
        println("[3d/morph] OK — two morph targets deform geometry and shadows on the GPU")
      } else {
        println(
          "[3d/morph] FAIL — inflate=\{d_inflate} ripple=\{d_ripple} cross=\{d_both} errs=\{errs}",
        )
      }
      rt.destroy()
    } else {
      let sc = @exwin_rhi.open(dev, opts)
      let mut quit = false
      let mut t : Float = 0.0
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
        t = t + (1.0 : Float) / 60.0
        let w0 : Float = 0.5 + 0.5 * @tmath.sin(t * 1.3)
        let w1 : Float = 0.5 + 0.5 * @tmath.sin(t * 1.9 + 1.4)
        renderer.set_morph_weights(node, [w0, w1])
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
      println("[3d/morph] validation errors: \{errs}")
    }
    if leaks != (0 : UInt64) {
      println("[3d/morph] LEAK — \{leaks} bytes after destroy")
    }
  } catch {
    err => println("[3d/morph] FAIL — \{err}")
  }
}
