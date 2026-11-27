// 3d/showcase — laplaceliu/tycho_3d showcase: the 49 PBR scene (2x5 metallic /
// dielectric spheres, ground, emissive orb, PCF shadow, PMREM IBL, bloom,
// ACES) rebuilt through the scene graph. Headless by default; --window uses
// FlyCamera.

///|
fn main {
  try {
    let opts = @exwin.Options::parse("3d/showcase")
    let show_win = opts.window
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("3d/showcase", validation=true, headless=!show_win),
    )
    let renderer = @t3d.Renderer3D::new(dev)
    let scene = @t3d.Scene::new()

    let sphere = renderer.upload_mesh(
      @tgeo.sphere(radius=0.38, width_segments=32, height_segments=16),
    )
    let ground = renderer.upload_mesh(@tgeo.box(width=12.0, height=0.2, depth=12.0))
    let _ = renderer.create_pbr_node(
      scene,
      ground,
      @t3d.MaterialDesc::pbr(@t3d.srgb(0.30, 0.32, 0.36), roughness=0.85),
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, -0.85, 0.0)),
    )

    let xs : Array[Float] = [-2.0, -1.0, 0.0, 1.0, 2.0]
    let roughs : Array[Float] = [0.12, 0.28, 0.48, 0.70, 0.90]
    let metals : Array[(Float, Float, Float)] = [
      (1.0, 0.78, 0.30), (0.95, 0.52, 0.36), (0.92, 0.94, 0.96),
      (0.35, 0.65, 0.98), (0.28, 0.90, 0.56),
    ]
    let diels : Array[(Float, Float, Float)] = [
      (0.86, 0.14, 0.14), (0.94, 0.54, 0.10), (0.90, 0.88, 0.82),
      (0.14, 0.34, 0.88), (0.14, 0.74, 0.36),
    ]
    for i = 0; i < 5; i = i + 1 {
      let (mr, mg, mb) = metals[i]
      let _ = renderer.create_pbr_node(
        scene,
        sphere,
        @t3d.MaterialDesc::pbr(@t3d.srgb(mr, mg, mb), metallic=1.0, roughness=roughs[i]),
        transform=@tmath.Transform::from_translation(@tmath.Vec3::new(xs[i], -0.42, -0.75)),
      )
      let (dr, dg, db) = diels[i]
      let _ = renderer.create_pbr_node(
        scene,
        sphere,
        @t3d.MaterialDesc::pbr(@t3d.srgb(dr, dg, db), roughness=roughs[i]),
        transform=@tmath.Transform::from_translation(@tmath.Vec3::new(xs[i], -0.42, 0.75)),
      )
    }

    let _ = renderer.create_pbr_node(
      scene,
      sphere,
      @t3d.MaterialDesc::pbr(@t3d.srgb(1.0, 0.9, 0.7), roughness=0.2)
      .with_emissive(@tmath.Vec3::new(6.0, 4.6, 2.4)),
      transform=@tmath.Transform::new(
        @tmath.Vec3::new(2.3, 1.35, -1.45),
        @tmath.Quat::identity(),
        @tmath.Vec3::splat(0.63),
      ),
    )
    let _ = renderer.create_pbr_node(
      scene,
      sphere,
      @t3d.MaterialDesc::pbr(@t3d.srgb(0.45, 0.70, 1.0, a=0.45), roughness=0.08)
      .with_alpha(@t3d.AlphaMode::Blend),
      transform=@tmath.Transform::new(
        @tmath.Vec3::new(-2.3, 1.05, -1.2),
        @tmath.Quat::identity(),
        @tmath.Vec3::splat(0.7),
      ),
    )

    let sun = @tmath.Vec3::new(4.0, 3.6, -2.2).normalize()
    let _ = @t3d.add_sun(scene, sun, color=@tmath.Vec3::new(1.0, 0.95, 0.85), intensity=4.2)
    let _ = @t3d.add_ambient(scene, intensity=0.25)
    renderer.set_procedural_environment(sun)

    let fov : Float = 2.0 * @tmath.atan((1.0 : Float) / (1.65 : Float))
    let cam = @t3d.Camera::perspective(fov, (800.0 : Float) / (600.0 : Float), near=0.1)
    let fly = @t3d.FlyCamera::new(
      position=@tmath.Vec3::new(0.0, 1.75, 4.3),
      yaw=0.0,
      pitch=-0.46,
    )
    let cam_node = scene.add_camera(cam, transform=fly.transform())

    if !show_win {
      let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8Srgb)
      renderer.render_offscreen( rt,scene, cam_node)
      let px = rt.readback()
      let mut lit = 0
      for i = 0; i + 3 < px.length(); i = i + 4 {
        if px[i].to_int() + px[i + 1].to_int() + px[i + 2].to_int() > 30 {
          lit = lit + 1
        }
      }
      opts.capture(800, 600, px)
      let errs = dev.validation_errors()
      println("[3d/showcase] \{renderer.stats().summary()} lit=\{lit} validation=\{errs}")
      if errs == 0 && lit > 10000 {
        println("[3d/showcase] OK — scene graph + PBR + shadow + HDR bloom/ACES")
      } else {
        println("[3d/showcase] FAIL — errs=\{errs} lit=\{lit}")
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
          let _ = fly.apply(ev)
        }
        scene.set_transform(cam_node.node(), fly.transform())
        renderer.render_swapchain(sc, scene, cam_node)
      }
      sc.destroy()
    }

    let errs = dev.validation_errors()
    renderer.destroy()
    let leaks = dev.allocator_used_bytes()
    dev.destroy()
    if errs != 0 {
      println("[3d/showcase] validation errors: \{errs}")
    }
    if leaks != (0 : UInt64) {
      println("[3d/showcase] LEAK — \{leaks} bytes after destroy")
    }
  } catch {
    err => println("[3d/showcase] FAIL — \{err}")
  }
}
