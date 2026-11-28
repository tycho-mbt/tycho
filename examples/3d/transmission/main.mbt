// 3d/transmission — screen-space transmission (`MaterialDesc::with_transmission`).
//
// A glass sphere sits in front of a row of colored blocks. With transmission 0
// the sphere is an opaque PBR ball; raising transmission makes the renderer
// copy the opaque color and re-render the sphere against it, refracting the
// blocks behind it through `ior`. The example renders both and asserts the
// pixels changed, with zero validation errors.

///|
fn pixel_diff(
  a : FixedArray[Byte],
  b : FixedArray[Byte],
  threshold : Int,
) -> Int {
  let n = if a.length() < b.length() { a.length() } else { b.length() }
  let mut count = 0
  for i = 0; i + 3 < n; i = i + 4 {
    let mut sum = 0
    for c = 0; c < 3; c = c + 1 {
      let mut d = a[i + c].to_int() - b[i + c].to_int()
      if d < 0 {
        d = -d
      }
      sum = sum + d
    }
    if sum > threshold {
      count = count + 1
    }
  }
  count
}

///|
fn main {
  try {
    let opts = @exwin.Options::parse("3d/transmission")
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("3d/transmission", validation=true, headless=true),
    )
    let renderer = @t3d.Renderer3D::new(dev)
    let scene = @t3d.Scene::new()

    // Backdrop: a dark ground plus a row of saturated blocks so refraction is
    // visible as a shifted, tinted copy of the background.
    let ground = renderer.add(
      scene,
      @tgeo.box(width=14.0, height=0.2, depth=8.0),
      @t3d.MaterialDesc::standard(@t3d.hex(0x2B2F36), roughness=0.9),
    )
    scene.set_position(ground, @tmath.Vec3::new(0.0, -1.2, -1.0))

    let colors : Array[Int] = [0xD94A4A, 0xE0A32E, 0x4CBB6C, 0x3E7BD9, 0x9A5BD6]
    let xs : Array[Float] = [-2.4, -1.2, 0.0, 1.2, 2.4]
    for i = 0; i < 5; i = i + 1 {
      let block = renderer.add(
        scene,
        @tgeo.box(width=0.8, height=2.2, depth=0.5),
        @t3d.MaterialDesc::standard(@t3d.hex(colors[i]), roughness=0.55),
      )
      scene.set_position(block, @tmath.Vec3::new(xs[i], 0.1, -3.2))
    }

    // The glass sphere. It starts opaque so the first frame is a reference.
    let glass_material = @t3d.MaterialDesc::standard(
      @t3d.hex(0xBFD8E6),
      metallic=0.0,
      roughness=0.05,
    )
    let glass = renderer.add(
      scene,
      @tgeo.sphere(radius=1.1, width_segments=48, height_segments=32),
      glass_material,
    )
    scene.set_position(glass, @tmath.Vec3::new(0.0, 0.15, 0.4))

    let sun_dir = @tmath.Vec3::new(-0.4, -1.0, -0.6)
    let _sun = scene.add_directional_light(direction=sun_dir, intensity=3.2)
    let _ambient = scene.add_ambient_light(intensity=0.25)
    renderer.set_procedural_environment(sun_dir.normalize(), size=64, samples=32)

    let cam = scene.add_camera(
      @t3d.Camera::perspective_deg(50.0, 800.0 / 600.0, near=0.1),
    )
    scene.set_position(cam.node(), @tmath.Vec3::new(0.0, 0.45, 5.2))
    scene.look_at(cam.node(), @tmath.Vec3::new(0.0, 0.1, -1.0))

    let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8Srgb)
    renderer.render_offscreen(rt, scene, cam)
    let opaque_px = rt.readback()

    // Enable transmission on the same material handle.
    let handle = match scene.mesh_of(glass) {
      Some(inst) => inst.material
      None => {
        println("[3d/transmission] FAIL — glass node has no mesh")
        return
      }
    }
    match renderer.material(handle) {
      Some(base) =>
        renderer.update_material(handle, base.with_transmission(0.92, ior=1.45))
      None => println("[3d/transmission] FAIL — material handle")
    }
    renderer.render_offscreen(rt, scene, cam)
    let glass_px = rt.readback()
    let changed = pixel_diff(opaque_px, glass_px, 24)
    // The sphere centre must see the background through the glass.
    let centre = (300 * 800 + 400) * 4
    let small = if opaque_px.length() < glass_px.length() {
      opaque_px.length()
    } else {
      glass_px.length()
    }
    let mut centre_delta = 0
    if centre + 2 < small {
      for c = 0; c < 3; c = c + 1 {
        let mut v = opaque_px[centre + c].to_int() - glass_px[centre + c].to_int()
        if v < 0 {
          v = -v
        }
        centre_delta = centre_delta + v
      }
    }
    let centre_changed = centre_delta > 20

    let errs = dev.validation_errors()
    println(
      "[3d/transmission] \{renderer.stats().summary()} changed=\{changed} centre=\{centre_changed} validation=\{errs}",
    )
    if errs == 0 && changed > 20000 && centre_changed {
      println("[3d/transmission] OK — screen-space transmission refracts the scene")
    } else {
      println("[3d/transmission] FAIL — errs=\{errs} changed=\{changed} centre=\{centre_changed}")
    }
    rt.destroy()
    renderer.destroy()
    dev.destroy()
  } catch {
    err => println("[3d/transmission] FAIL — \{err}")
  }
}
