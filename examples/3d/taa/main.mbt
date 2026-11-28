// 3d/taa — temporal anti-aliasing.
//
// A static grid of thin bars gives lots of sub-pixel edges. The renderer
// jitters the projection every frame and resolves against a reprojected
// history buffer. The gate renders all eight jitter phases without history and
// averages them on the CPU (a supersampled reference), then checks on the edge
// pixels — where jitter and TAA actually differ — that the warmed-up TAA frame
// is closer to that reference than a single jittered frame.

///|
fn fi(i : Int) -> Float {
  Float::from_double(i.to_double())
}

///|
/// Mean absolute channel difference on edge pixels of the reference image
/// (pixels whose right neighbour differs), where TAA's benefit is measurable.
fn edge_mae(
  img : FixedArray[Byte],
  sum : FixedArray[Int],
  frames : Int,
  px_len : Int,
) -> Float {
  let mut total : Float = 0.0
  let mut channels = 0
  let mut i = 0
  while i + 7 < px_len {
    let mut contrast = 0
    for c = 0; c < 3; c = c + 1 {
      let a = sum[i + c]
      let b = sum[i + 4 + c]
      contrast = contrast + (if a > b { a - b } else { b - a })
    }
    if contrast > 90 * frames {
      for c = 0; c < 3; c = c + 1 {
        let avg : Float = fi(sum[i + c]) / fi(frames)
        let v : Float = fi(img[i + c].to_int())
        total = total + (if v > avg { v - avg } else { avg - v })
        channels = channels + 1
      }
    }
    i = i + 4
  }
  if channels == 0 {
    0.0
  } else {
    total / fi(channels)
  }
}

///|
fn main {
  try {
    let opts = @exwin.Options::parse("3d/taa")
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("3d/taa", validation=true, headless=true),
    )
    let desc = @t3d.RendererDesc::default().with_taa(true).with_msaa(false)
    let renderer = @t3d.Renderer3D::new(dev, desc=desc)
    let scene = @t3d.Scene::new()

    let floor = renderer.add(
      scene,
      @tgeo.box(width=16.0, height=0.2, depth=16.0),
      @t3d.MaterialDesc::standard(@t3d.hex(0x55595F), roughness=0.9),
    )
    scene.set_position(floor, @tmath.Vec3::new(0.0, -1.0, 0.0))

    // Thin vertical bars: high-frequency silhouettes for TAA to resolve.
    let xs : Array[Float] = [-4.5, -3.6, -2.7, -1.8, -0.9, 0.0, 0.9, 1.8, 2.7, 3.6, 4.5]
    for i = 0; i < xs.length(); i = i + 1 {
      let h : Float = if i % 2 == 0 { 2.4 } else { 1.4 }
      let bar = renderer.add(
        scene,
        @tgeo.box(width=0.12, height=h, depth=0.12),
        @t3d.MaterialDesc::standard(
          if i % 2 == 0 { @t3d.hex(0xE8E8E8) } else { @t3d.hex(0x1E2228) },
          roughness=0.6,
        ),
      )
      scene.set_position(bar, @tmath.Vec3::new(xs[i], -1.0 + h * 0.5, -2.0))
    }

    let ball = renderer.add(
      scene,
      @tgeo.sphere(radius=1.0, width_segments=48, height_segments=32),
      @t3d.MaterialDesc::standard(@t3d.hex(0x3E7BD9), metallic=0.4, roughness=0.2),
    )
    scene.set_position(ball, @tmath.Vec3::new(0.0, 0.15, 1.0))

    let sun_dir = @tmath.Vec3::new(-0.5, -1.0, -0.4)
    let _sun = scene.add_directional_light(direction=sun_dir, intensity=3.0)
    let _ambient = scene.add_ambient_light(intensity=0.3)
    renderer.set_procedural_environment(sun_dir.normalize(), size=64, samples=32)

    let cam = scene.add_camera(
      @t3d.Camera::perspective_deg(50.0, 800.0 / 600.0, near=0.1),
    )
    scene.set_position(cam.node(), @tmath.Vec3::new(0.0, 0.6, 6.0))
    scene.look_at(cam.node(), @tmath.Vec3::new(0.0, 0.0, 0.0))

    let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8Srgb)

    // Supersampled reference: average the eight jitter phases with history off.
    renderer.set_taa_history_weight(0.0)
    let px_len = 800 * 600 * 4
    let sum = FixedArray::make(px_len, (0 : Int))
    let mut last_raw = FixedArray::make(px_len, (0 : Byte))
    for i = 0; i < 8; i = i + 1 {
      renderer.render_offscreen(rt, scene, cam)
      last_raw = rt.readback()
      for k = 0; k < px_len; k = k + 1 {
        sum[k] = sum[k] + last_raw[k].to_int()
      }
    }
    let raw_mae = edge_mae(last_raw, sum, 8, px_len)

    // Warm the EMA up, then compare the converged frame with the reference.
    renderer.set_taa_history_weight(0.9)
    renderer.reset_taa()
    for i = 0; i < 12; i = i + 1 {
      renderer.render_offscreen(rt, scene, cam)
    }
    renderer.render_offscreen(rt, scene, cam)
    let taa = rt.readback()
    let taa_mae = edge_mae(taa, sum, 8, px_len)
    opts.capture(800, 600, taa)

    let errs = dev.validation_errors()
    println(
      "[3d/taa] \{renderer.stats().summary()} raw_mae=\{raw_mae} taa_mae=\{taa_mae} validation=\{errs}",
    )
    if errs == 0 && raw_mae > 0.5 && taa_mae < raw_mae * 0.75 {
      println("[3d/taa] OK — TAA approaches the supersampled reference")
    } else {
      println(
        "[3d/taa] FAIL — errs=\{errs} raw_mae=\{raw_mae} taa_mae=\{taa_mae}",
      )
    }
    rt.destroy()
    renderer.destroy()
    dev.destroy()
  } catch {
    err => println("[3d/taa] FAIL — \{err}")
  }
}
