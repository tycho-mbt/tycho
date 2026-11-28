// 3d/hello — the smallest complete tycho_3d scene written with the
// three.js-style authoring layer: `renderer.add` object creation, hex colors,
// transform / look_at helpers, inherited visibility, light + grid + axes
// helpers, a degree camera, pixel-space picking, the frame Clock, fog and the
// physical sheen lobe.

///|
/// Number of pixels whose summed RGB difference exceeds `threshold`.
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
    let opts = @exwin.Options::parse("3d/hello")
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("3d/hello", validation=true, headless=true),
    )
    let renderer = @t3d.Renderer3D::new(dev)
    let scene = @t3d.Scene::new()

    let ground = renderer.add(
      scene,
      @tgeo.box(width=12.0, height=0.2, depth=12.0),
      @t3d.MaterialDesc::standard(@t3d.hex(0x4C5157), roughness=0.85),
    )
    scene.set_position(ground, @tmath.Vec3::new(0.0, -0.7, 0.0))

    let ball = renderer.add(
      scene,
      @tgeo.sphere(radius=0.6, width_segments=32, height_segments=16),
      @t3d.MaterialDesc::standard(@t3d.hex(0xFF8800), metallic=1.0, roughness=0.25),
    )
    scene.set_position(ball, @tmath.Vec3::new(-0.9, -0.05, 0.0))

    let pivot = scene.add_group(name="pivot")
    scene.set_position(pivot, @tmath.Vec3::new(1.1, 0.15, 0.0))
    let cube = renderer.add(
      scene,
      @tgeo.box(width=0.7, height=0.7, depth=0.7),
      @t3d.MaterialDesc::standard(@t3d.hex(0x37A2FF), roughness=0.4),
      parent=pivot,
    )
    scene.look_at(cube, @tmath.Vec3::new(4.0, 0.0, 3.0))

    // Hidden subtree: this emissive ball must not contribute to the image.
    let hidden_group = scene.add_group()
    scene.set_visible(hidden_group, false)
    let _hidden = renderer.add(
      scene,
      @tgeo.sphere(radius=2.0),
      @t3d.MaterialDesc::standard(@tmath.Vec4::one()).with_emissive(@tmath.Vec3::splat(50.0)),
      parent=hidden_group,
    )

    let sun_dir = @tmath.Vec3::new(-0.5, -1.0, -0.6)
    let _sun = scene.add_directional_light(
      direction=sun_dir,
      intensity=4.0,
      color=@tmath.Vec3::new(1.0, 0.95, 0.85),
    )
    let _ambient = scene.add_ambient_light(intensity=0.25)
    renderer.set_procedural_environment(sun_dir.normalize(), size=64, samples=32)

    let grid = renderer.add_grid(scene, size=12.0, divisions=12)
    scene.set_position(grid, @tmath.Vec3::new(0.0, -0.59, 0.0))
    let _axes = renderer.add_axes(scene, size=1.0)

    let cam_id = scene.add_camera(
      @t3d.Camera::perspective_deg(60.0, 800.0 / 600.0, near=0.1),
    )
    scene.set_position(cam_id.node(), @tmath.Vec3::new(0.0, 1.3, 4.2))
    scene.look_at(cam_id.node(), @tmath.Vec3::new(0.0, 0.1, 0.0))

    let clock = @t3d.Clock::new()
    let dt0 = clock.tick(0.0)
    let dt1 = clock.tick(0.016)
    if dt0 != 0.0 || dt1 <= 0.0 {
      println("[3d/hello] FAIL — clock")
    }

    let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8Srgb)
    renderer.render_offscreen(rt, scene, cam_id)
    let px = rt.readback()
    opts.capture(800, 600, px)
    let mut lit = 0
    for i = 0; i + 3 < px.length(); i = i + 4 {
      if px[i].to_int() + px[i + 1].to_int() + px[i + 2].to_int() > 30 {
        lit = lit + 1
      }
    }

    // Pixel-space picking must hit the visible sphere: project its centre to
    // pixels first, then pick with the same top-left origin pointer events use.
    let cam = match scene.camera_component(cam_id.node()) {
      Some(c) => c
      None => @t3d.Camera::perspective_deg(60.0, 800.0 / 600.0)
    }
    let vp = match cam.view_proj(scene.world_transform(cam_id.node())) {
      Some(v) => v
      None => @tmath.Mat4::identity()
    }
    let centre = scene.world_transform(ball).translation
    let clip = vp.mul_vec4(@tmath.Vec4::new(centre.x, centre.y, centre.z, 1.0))
    let ndc_x = clip.x / clip.w
    let ndc_y = clip.y / clip.w
    let px_x = (ndc_x + 1.0) * 0.5 * 800.0
    let px_y = if cam.clip.is_y_down() {
      (ndc_y + 1.0) * 0.5 * 600.0
    } else {
      (1.0 - ndc_y) * 0.5 * 600.0
    }
    let hit = renderer.pick_pixels(scene, cam_id, px_x, px_y, 800.0, 600.0)
    let hit_ok = match hit {
      Some(h) => h.node == ball
      None => false
    }
    // The hidden subtree must be absent from the drawable list.
    let visible = scene.collect_visible(@tmath.Frustum::from_view_proj(vp), (0xFFFFFFFF : UInt))
    let mut hidden_drawn = false
    for id in visible {
      if scene.parent_of(id) is Some(p) {
        if p == hidden_group {
          hidden_drawn = true
        }
      }
    }

    // Flat background: the sky pass is replaced by a clear colour while the
    // environment keeps lighting the materials, so the corner is no longer the
    // dark sky but the authored colour.
    renderer.set_background(@t3d.hex(0xFF0000))
    renderer.render_offscreen(rt, scene, cam_id)
    let bg_px = rt.readback()
    // The sky is blue-ish, so a red-dominant corner proves the clear color won.
    let bg_lit = match bg_px.length() {
      0 => false
      _ => bg_px[0].to_int() > bg_px[2].to_int() + 20
    }
    renderer.clear_background()

    // Fog lives in the frame UBO (no pipeline variant), so enabling it must
    // change the rendered pixels of the same scene.
    renderer.set_fog(@t3d.fog_exp2(@tmath.Vec3::new(0.85, 0.2, 0.15), density=0.5))
    renderer.render_offscreen(rt, scene, cam_id)
    let fog_px = rt.readback()
    let fog_diff = pixel_diff(px, fog_px, 30)
    renderer.clear_fog()

    // Physical sheen: rebuild the ball material with a grazing-angle lobe and
    // confirm it changes the shaded pixels (packed in the material SSBO only).
    match scene.mesh_of(ball) {
      Some(inst) =>
        match renderer.material(inst.material) {
          Some(base) =>
            renderer.update_material(
              inst.material,
              base.with_sheen(@tmath.Vec3::one(), roughness=0.15),
            )
          None => ()
        }
      None => ()
    }
    renderer.render_offscreen(rt, scene, cam_id)
    let sheen_px = rt.readback()
    let sheen_diff = pixel_diff(px, sheen_px, 24)

    renderer.release_node(ground)
    let errs = dev.validation_errors()
    println(
      "[3d/hello] \{renderer.stats().summary()} meshes=\{renderer.mesh_count()} materials=\{renderer.material_count()} drawable=\{visible.length()} lit=\{lit} pick=\{hit_ok} hidden=\{hidden_drawn} background=\{bg_lit} fog_diff=\{fog_diff} sheen_diff=\{sheen_diff}",
    )
    if errs == 0 &&
      lit > 10000 &&
      hit_ok &&
      !hidden_drawn &&
      bg_lit &&
      fog_diff > 10000 &&
      sheen_diff > 500 {
      println("[3d/hello] OK — ergonomic layer renders, picks, fogs and sheens")
    } else {
      println(
        "[3d/hello] FAIL — errs=\{errs} lit=\{lit} pick=\{hit_ok} hidden=\{hidden_drawn} background=\{bg_lit} fog_diff=\{fog_diff} sheen_diff=\{sheen_diff}",
      )
    }
    rt.destroy()
    renderer.destroy()
    dev.destroy()
  } catch {
    err => println("[3d/hello] FAIL — \{err}")
  }
}
