// Example 64 — textured PBR: albedo maps, normal maps and alpha masking.
// Textures are generated procedurally, then three renders verify that the
// normal map and the alpha mask actually change the image.

///|
fn to_f(i : Int) -> Float {
  Float::from_double(i.to_double())
}

///|
fn byte_of(v : Int) -> Byte {
  (v.to_uint() & (0xFF : UInt)).to_byte()
}

///|
fn fbyte(v : Float) -> Byte {
  let c : Float = if v < 0.0 {
    0.0
  } else if v > 255.0 {
    255.0
  } else {
    v
  }
  byte_of(c.to_double().to_int())
}

///|
fn checker_texture(size : Int, cells : Int) -> FixedArray[Byte] {
  let px : FixedArray[Byte] = FixedArray::make(size * size * 4, (0 : Byte))
  let cell = size / cells
  for y = 0; y < size; y = y + 1 {
    for x = 0; x < size; x = x + 1 {
      let o = (y * size + x) * 4
      let on = ((x / cell + y / cell) % 2) == 0
      px[o] = byte_of(if on { 230 } else { 40 })
      px[o + 1] = byte_of(if on { 145 } else { 95 })
      px[o + 2] = byte_of(if on { 75 } else { 150 })
      px[o + 3] = byte_of(255)
    }
  }
  px
}

///|
fn ripple_normal_texture(size : Int) -> FixedArray[Byte] {
  let px : FixedArray[Byte] = FixedArray::make(size * size * 4, (0 : Byte))
  let kx : Float = 0.45
  let ky : Float = 0.33
  let amp : Float = 1.5
  for y = 0; y < size; y = y + 1 {
    for x = 0; x < size; x = x + 1 {
      let fx = to_f(x)
      let fy = to_f(y)
      let dhx = -amp * kx * @tmath.sin(fx * kx) * @tmath.sin(fy * ky)
      let dhy = -amp * ky * @tmath.cos(fx * kx) * @tmath.cos(fy * ky)
      let inv : Float = 1.0 / @tmath.sqrt(dhx * dhx + dhy * dhy + (1.0 : Float))
      let o = (y * size + x) * 4
      px[o] = fbyte((dhx * inv + (1.0 : Float)) * (127.5 : Float))
      px[o + 1] = fbyte((dhy * inv + (1.0 : Float)) * (127.5 : Float))
      px[o + 2] = fbyte((inv + (1.0 : Float)) * (127.5 : Float))
      px[o + 3] = byte_of(255)
    }
  }
  px
}

///|
fn hole_texture(w : Int, h : Int) -> FixedArray[Byte] {
  let px : FixedArray[Byte] = FixedArray::make(w * h * 4, (0 : Byte))
  for y = 0; y < h; y = y + 1 {
    for x = 0; x < w; x = x + 1 {
      let o = (y * w + x) * 4
      let solid_band = (x / 16) % 2 == 0
      px[o] = byte_of(if solid_band { 235 } else { 250 })
      px[o + 1] = byte_of(if solid_band { 150 } else { 235 })
      px[o + 2] = byte_of(if solid_band { 60 } else { 205 })
      px[o + 3] = byte_of(if solid_band { 255 } else { 0 })
    }
  }
  px
}

///|
fn diff_pixels(a : FixedArray[Byte], b : FixedArray[Byte]) -> Int {
  let mut n = 0
  let mut i = 0
  while i + 3 < a.length() && i + 3 < b.length() {
    let d = (a[i].to_int() - b[i].to_int()).abs() + (a[i + 1].to_int() - b[i + 1].to_int()).abs() + (a[i + 2].to_int() - b[i + 2].to_int()).abs()
    if d > 12 {
      n = n + 1
    }
    i = i + 4
  }
  n
}

///|
fn main {
  try {
    let show_win = @tycho.want_window()
    let shot = @tycho.screenshot_path()
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "64-tycho-3d-textures",
        validation=true,
        headless=!show_win,
      ),
    )
    let renderer = @t3d.Renderer3D::new(dev)
    let scene = @t3d.Scene::new()

    let checker = renderer.create_texture(128, 128, checker_texture(128, 8))
    let ripples = renderer.create_texture(128, 128, ripple_normal_texture(128), srgb=false)
    let holes = renderer.create_texture(256, 128, hole_texture(256, 128))

    let ground_mat = renderer.create_material(
      @t3d.MaterialDesc::pbr(@t3d.srgb(1.0, 1.0, 1.0), metallic=0.0, roughness=0.92)
      .with_albedo_tex(checker),
    )
    let ground_mesh = renderer.upload_mesh(@tgeo.box(width=26.0, height=0.2, depth=26.0))
    let ground = scene.create_node(
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, -0.6, 0.0)),
      payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(ground_mesh, ground_mat)),
    )
    scene.set_local_bounds(ground, renderer.mesh_bounds(ground_mesh))

    let sphere_desc = @t3d.MaterialDesc::pbr(
      @t3d.srgb(1.0, 1.0, 1.0),
      metallic=0.25,
      roughness=0.30,
    )
      .with_albedo_tex(checker)
      .with_normal_tex(ripples)
    let sphere_mat = renderer.create_material(sphere_desc)
    let sphere_mesh = renderer.upload_mesh(
      @tgeo.sphere(radius=1.1, width_segments=48, height_segments=24),
    )
    let sphere = scene.create_node(
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(1.05, 0.6, 0.0)),
      payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(sphere_mesh, sphere_mat)),
    )
    scene.set_local_bounds(sphere, renderer.mesh_bounds(sphere_mesh))

    let hole_desc = @t3d.MaterialDesc::pbr(
      @t3d.srgb(1.0, 1.0, 1.0),
      metallic=0.0,
      roughness=0.85,
    )
      .with_albedo_tex(holes)
      .with_alpha(@t3d.AlphaMode::Mask(0.5))
    let panel_mat = renderer.create_material(hole_desc)
    let panel_mesh = renderer.upload_mesh(@tgeo.plane(width=3.4, height=1.7))
    let panel = scene.create_node(
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(-1.95, 0.82, -0.8)),
      payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(panel_mesh, panel_mat)),
    )
    scene.set_local_bounds(panel, renderer.mesh_bounds(panel_mesh))

    let sun = @tmath.Vec3::new(4.0, 4.5, -2.0).normalize()
    let _sun_node = scene.create_node(
      transform=@tmath.Transform::new(
        @tmath.Vec3::zero(),
        @tmath.Quat::from_rotation_arc(@tmath.Vec3::neg_z(), sun),
        @tmath.Vec3::one(),
      ),
      payload=@t3d.NodePayload::Light(
        @t3d.Light::directional(
          @tmath.Vec3::new(1.0, 0.97, 0.9),
          3.8,
          shadow=Some(@t3d.ShadowDesc::default()),
        ),
      ),
    )
    let _ambient = scene.create_node(
      payload=@t3d.NodePayload::Light(@t3d.Light::ambient(@tmath.Vec3::one(), 0.22)),
    )
    let env_cube = @t3d.procedural_environment_cubemap(dev, sun)
    renderer.set_environment(env_cube, sun)

    let orbit = @t3d.OrbitCamera::new(
      target=@tmath.Vec3::new(0.3, 0.9, 0.0),
      distance=7.6,
      yaw=0.30,
      pitch=0.28,
    )
    let cam = @t3d.Camera::perspective(1.0, (800.0 : Float) / (600.0 : Float), near=0.1)
    let cam_node = scene.create_node(
      transform=orbit.transform(),
      payload=@t3d.NodePayload::Camera(cam),
    )

    if !show_win {
      let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8Srgb)
      renderer.render_offscreen(scene, cam_node, rt)
      let base = rt.readback()
      let mut lit = 0
      let mut i = 0
      while i + 3 < base.length() {
        if base[i].to_int() + base[i + 1].to_int() + base[i + 2].to_int() > 30 {
          lit = lit + 1
        }
        i = i + 4
      }
      if shot != "" {
        let _ = @tycho.save_png(shot, 800, 600, base)
      }
      // Swap the sphere to an untextured-normal material: the difference proves
      // the normal map path is live.
      let sphere_flat = @t3d.MaterialDesc::pbr(
        @t3d.srgb(1.0, 1.0, 1.0),
        metallic=0.25,
        roughness=0.30,
      )
        .with_albedo_tex(checker)
      renderer.update_material(sphere_mat, sphere_flat)
      renderer.render_offscreen(scene, cam_node, rt)
      let no_normal = rt.readback()
      let normal_diff = diff_pixels(base, no_normal)
      // A cutoff above 1 discards every alpha value, removing the panel.
      let panel_gone = @t3d.MaterialDesc::pbr(
        @t3d.srgb(1.0, 1.0, 1.0),
        metallic=0.0,
        roughness=0.85,
      )
        .with_albedo_tex(holes)
        .with_alpha(@t3d.AlphaMode::Mask(2.0))
      renderer.update_material(panel_mat, panel_gone)
      renderer.render_offscreen(scene, cam_node, rt)
      let no_panel = rt.readback()
      let mask_diff = diff_pixels(no_normal, no_panel)
      let errs = dev.validation_errors()
      println(
        "[64-tycho-3d-textures] \{renderer.stats().summary()} lit=\{lit} normal_diff=\{normal_diff} mask_diff=\{mask_diff} validation=\{errs}",
      )
      if errs == 0 && lit > 20000 && normal_diff > 1200 && mask_diff > 1500 {
        println(
          "[64-tycho-3d-textures] OK — albedo + normal map + alpha mask (normal_diff=\{normal_diff} mask_diff=\{mask_diff})",
        )
      } else {
        println(
          "[64-tycho-3d-textures] FAIL — lit=\{lit} normal_diff=\{normal_diff} mask_diff=\{mask_diff} errs=\{errs}",
        )
      }
      rt.destroy()
    } else {
      let sc = dev.create_swapchain("64-tycho-3d-textures", 800, 600)
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
    env_cube.destroy()
    let leaks = dev.allocator_used_bytes()
    dev.destroy()
    if leaks != (0 : UInt64) {
      println("[64-tycho-3d-textures] LEAK — \{leaks} bytes after destroy")
    }
    if errs != 0 {
      println("[64-tycho-3d-textures] validation errors: \{errs}")
    }
  } catch {
    err => println("[64-tycho-3d-textures] FAIL — \{err}")
  }
}
