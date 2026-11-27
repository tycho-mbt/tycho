// general/3d-hud — 3D scene plus a 2D HUD in one swapchain frame (R-2D1).
//
// The 3D renderer draws into the acquired image without presenting, the 2D
// renderer loads that image and blends a HUD on top, then the application
// presents. Headless mode performs the same composition on a render target and
// asserts that the HUD pixels changed while the rest of the 3D image survived.

///|
fn hud_diff_count(a : FixedArray[Byte], b : FixedArray[Byte]) -> Int {
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
fn pixel_at(
  px : FixedArray[Byte],
  w : Int,
  x : Int,
  y : Int,
) -> (Int, Int, Int) {
  let i = (y * w + x) * 4
  (px[i].to_int(), px[i + 1].to_int(), px[i + 2].to_int())
}

///|
fn build_hud() -> @g2d.DisplayList {
  let canvas = @g2d.Canvas::new()
  // Status panel.
  let panel = @g2d.RRect::uniform(
    @g2d.Rect::new(24.0, 24.0, 320.0, 116.0),
    12.0,
  )
  canvas.draw_rrect(
    panel,
    @g2d.Paint::fill(@g2d.Color::from_rgba8(16, 36, 88, a=210)),
  )
  canvas.draw_rrect(
    panel,
    @g2d.Paint::stroke(@g2d.Color::from_rgba8(120, 200, 255, a=230), 2.0),
  )
  // Two bars inside the panel.
  canvas.draw_rect(
    @g2d.Rect::new(44.0, 96.0, 240.0, 18.0),
    @g2d.Paint::fill(@g2d.Color::from_rgba8(30, 60, 120, a=220)),
  )
  canvas.draw_rect(
    @g2d.Rect::new(44.0, 96.0, 160.0, 18.0),
    @g2d.Paint::fill(@g2d.Color::from_rgba8(80, 220, 140, a=240)),
  )
  // Crosshair.
  let white = @g2d.Color::from_rgba8(255, 255, 255, a=225)
  canvas.draw_line(
    @g2d.Point::new(400.0, 284.0),
    @g2d.Point::new(400.0, 316.0),
    @g2d.Paint::stroke(white, 2.0),
  )
  canvas.draw_line(
    @g2d.Point::new(384.0, 300.0),
    @g2d.Point::new(416.0, 300.0),
    @g2d.Paint::stroke(white, 2.0),
  )
  // Bottom status bar.
  canvas.draw_rect(
    @g2d.Rect::new(0.0, 560.0, 800.0, 40.0),
    @g2d.Paint::fill(@g2d.Color::from_rgba8(8, 12, 20, a=190)),
  )
  canvas.finish()
}

///|
fn main {
  try {
    let opts = @exwin.Options::parse("general/3d-hud")
    let show_win = opts.window
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("general/3d-hud", validation=true, headless=!show_win),
    )
    let renderer = @t3d.Renderer3D::new(dev)
    let g2d = @g2d.Renderer2D::new(dev)
    let scene = @t3d.Scene::new()

    let sphere = renderer.upload_mesh(
      @tgeo.sphere(radius=0.9, width_segments=32, height_segments=16),
    )
    let ground = renderer.upload_mesh(@tgeo.box(width=12.0, height=0.2, depth=12.0))
    let _ = renderer.create_pbr_node(
      scene,
      ground,
      @t3d.MaterialDesc::pbr(@t3d.srgb(0.30, 0.32, 0.36), roughness=0.85),
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, -0.9, 0.0)),
    )
    let colours : Array[(Float, Float, Float)] = [
      (0.90, 0.20, 0.20), (0.20, 0.70, 0.90), (0.95, 0.80, 0.30),
    ]
    for i = 0; i < 3; i = i + 1 {
      let (r, g, b) = colours[i]
      let _ = renderer.create_pbr_node(
        scene,
        sphere,
        @t3d.MaterialDesc::pbr(@t3d.srgb(r, g, b), metallic=0.3, roughness=0.30),
        transform=@tmath.Transform::from_translation(
          @tmath.Vec3::new(-2.2 + Float::from_int(i) * 2.2, -0.1, 0.0),
        ),
      )
    }

    let sun = @tmath.Vec3::new(-0.4, 0.8, 0.45).normalize()
    let _sun_node = scene.create_node(
      transform=@tmath.Transform::new(
        @tmath.Vec3::zero(),
        @tmath.Quat::from_rotation_arc(@tmath.Vec3::neg_z(), sun),
        @tmath.Vec3::one(),
      ),
      payload=@t3d.NodePayload::Light(
        @t3d.Light::directional(
          @tmath.Vec3::new(1.0, 0.96, 0.88),
          3.6,
          shadow=@t3d.ShadowDesc::default(),
        ),
      ),
    )
    let _ambient = scene.create_node(
      payload=@t3d.NodePayload::Light(@t3d.Light::ambient(@tmath.Vec3::one(), 0.22)),
    )
    let env = @t3d.procedural_environment_cubemap(dev, sun)
    renderer.set_environment(env, sun)

    let orbit = @t3d.OrbitCamera::new(
      target=@tmath.Vec3::new(0.0, 0.1, 0.0),
      distance=8.5,
      yaw=0.4,
      pitch=0.32,
    )
    let fov : Float = 2.0 * @tmath.atan((1.0 : Float) / (1.8 : Float))
    let cam = @t3d.Camera::perspective(fov, (800.0 : Float) / (600.0 : Float), near=0.1)
    let cam_node = scene.create_node(
      transform=orbit.transform(),
      payload=@t3d.NodePayload::Camera(cam),
    )
    let hud = build_hud()

    if !show_win {
      let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8)
      renderer.render_offscreen(rt, scene, cam_node)
      let base = rt.readback()
      g2d.render_offscreen(
        rt,
        hud,
        clear_color=@g2d.Color::transparent(),
        load_op=@tycho.LoadOp::Load,
      )
      let mixed = rt.readback()

      let changed = hud_diff_count(base, mixed)
      // Probing outside every HUD element: the Load pass must leave the 3D
      // image byte-identical.
      let probes : Array[(Int, Int)] = [
        (760, 40), (700, 120), (40, 300), (760, 300), (500, 520), (200, 470),
      ]
      let mut preserved = true
      for p in probes {
        let (bx, by, bz) = pixel_at(base, 800, p.0, p.1)
        let (mx, my, mz) = pixel_at(mixed, 800, p.0, p.1)
        if bx != mx || by != my || bz != mz {
          preserved = false
        }
      }
      let (pr, pg, pb) = pixel_at(mixed, 800, 100, 80)
      let (br, bg, bb) = pixel_at(base, 800, 100, 80)
      let panel_delta = (pr - br).abs() + (pg - bg).abs() + (pb - bb).abs()
      let panel_ok = pb > pr + 25 && panel_delta > 25
      let mut lit = 0
      let mut i = 0
      while i + 3 < base.length() {
        if base[i].to_int() + base[i + 1].to_int() + base[i + 2].to_int() > 30 {
          lit = lit + 1
        }
        i = i + 4
      }
      opts.capture(800, 600, mixed)
      let errs = dev.validation_errors()
      println(
        "[general/3d-hud] \{renderer.stats().summary()} hud_diff=\{changed} preserved=\{preserved} panel=\{panel_ok} lit=\{lit} validation=\{errs}",
      )
      if errs == 0 && changed > 4000 && preserved && panel_ok && lit > 10000 {
        println("[general/3d-hud] OK — 2D HUD overlays the 3D scene without clearing it")
      } else {
        println(
          "[general/3d-hud] FAIL — hud_diff=\{changed} preserved=\{preserved} panel=\{panel_ok} lit=\{lit} errs=\{errs}",
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
        let cmd = sc.begin_frame_commands()
        renderer.render_swapchain_into(cmd, sc, scene, cam_node)
        g2d.render_swapchain_pass(
          cmd,
          sc,
          hud,
          clear_color=@g2d.Color::transparent(),
        )
        sc.end_frame(cmd)
      }
      sc.destroy()
    }

    let errs = dev.validation_errors()
    renderer.destroy()
    g2d.destroy()
    env.destroy()
    let leaks = dev.allocator_used_bytes()
    dev.destroy()
    if errs != 0 {
      println("[general/3d-hud] validation errors: \{errs}")
    }
    if leaks != (0 : UInt64) {
      println("[general/3d-hud] LEAK — \{leaks} bytes after destroy")
    }
  } catch {
    err => println("[general/3d-hud] FAIL — \{err}")
  }
}
