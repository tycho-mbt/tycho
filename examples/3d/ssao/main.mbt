// 3d/ssao — screen-space ambient occlusion from the depth buffer.
//
// A corner of two walls, a floor and a few boxes gives clear contact regions.
// The example renders the same frame with `ssao_intensity = 0` (blurred AO is
// all ones, i.e. no effect) and with full strength, then asserts that the
// second image is darker in the creases and never brighter anywhere — an AO
// term can only attenuate light.

///|
fn compare_ao(
  plain : FixedArray[Byte],
  ao : FixedArray[Byte],
) -> (Int, Int, Int) {
  let n = if plain.length() < ao.length() { plain.length() } else { ao.length() }
  let mut darker = 0
  let mut brighter = 0
  let mut total_delta = 0
  for i = 0; i + 3 < n; i = i + 4 {
    let mut d = 0
    for c = 0; c < 3; c = c + 1 {
      d = d + ao[i + c].to_int() - plain[i + c].to_int()
    }
    if d < -6 {
      darker = darker + 1
      total_delta = total_delta - d
    } else if d > 6 {
      brighter = brighter + 1
    }
  }
  (darker, brighter, total_delta)
}

///|
fn main {
  try {
    let opts = @exwin.Options::parse("3d/ssao")
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("3d/ssao", validation=true, headless=true),
    )
    // SSAO needs a single-sample depth buffer, so this also turns MSAA off.
    let desc = @t3d.RendererDesc::default().with_ssao(true)
    let renderer = @t3d.Renderer3D::new(dev, desc=desc)
    let scene = @t3d.Scene::new()

    let stone = @t3d.MaterialDesc::standard(@t3d.hex(0x8A8F98), roughness=0.85)
    let floor = renderer.add(scene, @tgeo.box(width=10.0, height=0.2, depth=10.0), stone)
    scene.set_position(floor, @tmath.Vec3::new(0.0, -1.0, 0.0))
    let back = renderer.add(scene, @tgeo.box(width=10.0, height=4.0, depth=0.2), stone)
    scene.set_position(back, @tmath.Vec3::new(0.0, 1.0, -5.0))
    let side = renderer.add(scene, @tgeo.box(width=0.2, height=4.0, depth=10.0), stone)
    scene.set_position(side, @tmath.Vec3::new(-5.0, 1.0, 0.0))

    // Boxes near the corner produce the occlusion the eye expects.
    let scales : Array[Float] = [0.9, 1.05, 1.2, 1.35]
    let px : Array[Float] = [-3.6, -2.1, -0.6, 0.9]
    let pz : Array[Float] = [-3.8, -2.6, -1.4, -0.2]
    let ry : Array[Float] = [0.0, 0.5, 1.0, 1.5]
    for i = 0; i < 4; i = i + 1 {
      let s = scales[i]
      let box = renderer.add(
        scene,
        @tgeo.box(width=s, height=s, depth=s),
        @t3d.MaterialDesc::standard(@t3d.hex(0xC9A227), roughness=0.5),
      )
      scene.set_position(box, @tmath.Vec3::new(px[i], -1.0 + s * 0.5, pz[i]))
      scene.set_euler(box, 0.0, ry[i], 0.0)
    }

    let _sun = scene.add_directional_light(
      direction=@tmath.Vec3::new(-0.35, -1.0, 0.25),
      intensity=3.0,
    )
    let _ambient = scene.add_ambient_light(
      color=@tmath.Vec3::new(0.55, 0.62, 0.75),
      intensity=0.35,
    )
    renderer.set_procedural_environment(
      @tmath.Vec3::new(-0.35, -1.0, 0.25).normalize(),
      size=64,
      samples=32,
    )
    renderer.set_ssao_radius(1.1)
    renderer.set_ssao_bias(0.02)

    let cam = scene.add_camera(
      @t3d.Camera::perspective_deg(55.0, 800.0 / 600.0, near=0.1),
    )
    scene.set_position(cam.node(), @tmath.Vec3::new(3.2, 1.6, 3.6))
    scene.look_at(cam.node(), @tmath.Vec3::new(-1.6, -0.2, -2.4))

    let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8Srgb)

    // Reference: AO computed but scaled to zero.
    renderer.set_ssao_intensity(0.0)
    renderer.render_offscreen(rt, scene, cam)
    let plain = rt.readback()

    renderer.set_ssao_intensity(1.0)
    renderer.render_offscreen(rt, scene, cam)
    let occluded = rt.readback()

    let (darker, brighter, total_delta) = compare_ao(plain, occluded)
    let errs = dev.validation_errors()
    println(
      "[3d/ssao] \{renderer.stats().summary()} darker=\{darker} brighter=\{brighter} delta=\{total_delta} validation=\{errs}",
    )
    if errs == 0 && darker > 8000 && brighter == 0 && total_delta > 60000 {
      println("[3d/ssao] OK — depth-reconstructed SSAO darkens creases only")
    } else {
      println(
        "[3d/ssao] FAIL — errs=\{errs} darker=\{darker} brighter=\{brighter} delta=\{total_delta}",
      )
    }
    rt.destroy()
    renderer.destroy()
    dev.destroy()
  } catch {
    err => println("[3d/ssao] FAIL — \{err}")
  }
}
