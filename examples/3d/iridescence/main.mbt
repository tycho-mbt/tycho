// 3d/iridescence — thin-film iridescence on a physical material.
//
// A polished white metal sphere reflects the procedural sky. With iridescence
// off the reflection is neutral; with a ~380 nm film the specular tint shifts
// with view angle, and changing the thickness to ~650 nm changes that tint.
// The example asserts all three: pixels changed, chroma shifted (not just
// brightness), and thickness matters.

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
/// Summed absolute change of the red-minus-blue chroma. A pure brightness
/// change leaves this near zero; a thin-film hue shift does not.
fn chroma_shift(a : FixedArray[Byte], b : FixedArray[Byte]) -> Int {
  let n = if a.length() < b.length() { a.length() } else { b.length() }
  let mut total = 0
  for i = 0; i + 3 < n; i = i + 4 {
    let chroma_a = a[i].to_int() - a[i + 2].to_int()
    let chroma_b = b[i].to_int() - b[i + 2].to_int()
    let d = chroma_a - chroma_b
    total = total + (if d < 0 { -d } else { d })
  }
  total
}

///|
fn main {
  try {
    let opts = @exwin.Options::parse("3d/iridescence")
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("3d/iridescence", validation=true, headless=true),
    )
    let renderer = @t3d.Renderer3D::new(dev)
    let scene = @t3d.Scene::new()

    // A dark dielectric keeps the specular lobe dominant: a perfect mirror
    // would reflect everything and, correctly, show no film interference.
    let base = @t3d.MaterialDesc::standard(
      @t3d.hex(0x101418),
      metallic=0.0,
      roughness=0.1,
    )
    let ball = renderer.add(
      scene,
      @tgeo.sphere(radius=1.2, width_segments=64, height_segments=48),
      base,
    )
    scene.set_position(ball, @tmath.Vec3::new(0.0, 0.1, 0.0))

    let floor = renderer.add(
      scene,
      @tgeo.box(width=12.0, height=0.2, depth=12.0),
      @t3d.MaterialDesc::standard(@t3d.hex(0x2B3038), roughness=0.85),
    )
    scene.set_position(floor, @tmath.Vec3::new(0.0, -1.2, 0.0))

    let sun_dir = @tmath.Vec3::new(-0.45, -1.0, -0.55)
    let _sun = scene.add_directional_light(direction=sun_dir, intensity=3.2)
    let _ambient = scene.add_ambient_light(intensity=0.15)
    renderer.set_procedural_environment(sun_dir.normalize(), size=96, samples=48)

    let cam = scene.add_camera(
      @t3d.Camera::perspective_deg(45.0, 800.0 / 600.0, near=0.1),
    )
    scene.set_position(cam.node(), @tmath.Vec3::new(0.0, 0.7, 5.2))
    scene.look_at(cam.node(), @tmath.Vec3::new(0.0, 0.0, 0.0))

    let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8Srgb)
    let handle = match scene.mesh_of(ball) {
      Some(inst) => inst.material
      None => {
        println("[3d/iridescence] FAIL — ball has no mesh")
        return
      }
    }

    // Reference: no film.
    renderer.render_offscreen(rt, scene, cam)
    let plain = rt.readback()

    // 380 nm film.
    renderer.update_material(
      handle,
      base.with_iridescence(1.0, ior=1.35, thickness_nm=380.0),
    )
    renderer.render_offscreen(rt, scene, cam)
    let film_a = rt.readback()
    // 650 nm film: same geometry, different interference colour.
    renderer.update_material(
      handle,
      base.with_iridescence(1.0, ior=1.35, thickness_nm=650.0),
    )
    renderer.render_offscreen(rt, scene, cam)
    let film_b = rt.readback()

    let changed = pixel_diff(plain, film_a, 18)
    let chroma = chroma_shift(plain, film_a)
    let thickness = pixel_diff(film_a, film_b, 18)
    opts.capture(800, 600, film_a)

    let errs = dev.validation_errors()
    println(
      "[3d/iridescence] \{renderer.stats().summary()} changed=\{changed} chroma=\{chroma} thickness=\{thickness} validation=\{errs}",
    )
    if errs == 0 && changed > 5000 && chroma > 20000 && thickness > 2000 {
      println("[3d/iridescence] OK — thin-film interference tints the specular by view angle")
    } else {
      println(
        "[3d/iridescence] FAIL — errs=\{errs} changed=\{changed} chroma=\{chroma} thickness=\{thickness}",
      )
    }
    rt.destroy()
    renderer.destroy()
    dev.destroy()
  } catch {
    err => println("[3d/iridescence] FAIL — \{err}")
  }
}
