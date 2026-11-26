// Example 63 — automatic instancing.
// 10,000 scene nodes share one mesh and one material; the renderer groups them
// into a single instanced draw (plus one shadow draw).

///|
fn to_f(i : Int) -> Float {
  Float::from_double(i.to_double())
}

///|
fn main {
  try {
    let show_win = @tycho.want_window()
    let shot = @tycho.screenshot_path()
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "64-tycho-3d-instances",
        validation=true,
        headless=!show_win,
      ),
    )
    let desc : @t3d.RendererDesc = {
      max_objects: 24000,
      max_lights: 16,
      max_materials: 64,
      max_textures: 64,
      msaa: true,
      bloom: true,
      shadows: true,
      shadow_map_size: 1024,
      shadow_cascades: 2,
      gpu_culling: false,
    }
    let renderer = @t3d.Renderer3D::new(dev, desc=desc)
    let scene = @t3d.Scene::new()

    let ground_mat = renderer.create_material(
      @t3d.MaterialDesc::pbr(@t3d.srgb(0.20, 0.22, 0.26), metallic=0.0, roughness=0.95),
    )
    let ground_mesh = renderer.upload_mesh(@tgeo.box(width=140.0, height=0.2, depth=140.0))
    let ground = scene.create_node(
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, -0.6, 0.0)),
      payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(ground_mesh, ground_mat)),
    )
    scene.set_local_bounds(ground, renderer.mesh_bounds(ground_mesh))

    let cube = renderer.upload_mesh(@tgeo.box(width=0.7, height=0.7, depth=0.7))
    let cube_mat = renderer.create_material(
      @t3d.MaterialDesc::pbr(@t3d.srgb(0.52, 0.62, 0.80), metallic=0.15, roughness=0.45),
    )
    let cube_bounds = renderer.mesh_bounds(cube)
    let side : Int = 100
    let count : Int = 10000
    for i = 0; i < count; i = i + 1 {
      let gx = i % side
      let gz = i / side
      let x = to_f(gx) - 50.0
      let z = to_f(gz) - 50.0
      let wave = @tmath.sin(x * 0.33) * @tmath.cos(z * 0.27)
      let h : Float = 0.6 + 1.8 * (0.5 + 0.5 * wave)
      let node = scene.create_node(
        transform=@tmath.Transform::new(
          @tmath.Vec3::new(x * 1.15, -0.5 + h * 0.35, z * 1.15),
          @tmath.Quat::from_rotation_y(x * 0.12 + z * 0.09),
          @tmath.Vec3::new(1.0, h, 1.0),
        ),
        payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(cube, cube_mat)),
      )
      scene.set_local_bounds(node, cube_bounds)
    }

    let sun = @tmath.Vec3::new(3.0, 4.0, -2.0).normalize()
    let _sun_node = scene.create_node(
      transform=@tmath.Transform::new(
        @tmath.Vec3::zero(),
        @tmath.Quat::from_rotation_arc(@tmath.Vec3::neg_z(), sun),
        @tmath.Vec3::one(),
      ),
      payload=@t3d.NodePayload::Light(
        @t3d.Light::directional(
          @tmath.Vec3::new(1.0, 0.97, 0.9),
          3.6,
          shadow=Some(@t3d.ShadowDesc::default()),
        ),
      ),
    )
    let _ambient = scene.create_node(
      payload=@t3d.NodePayload::Light(@t3d.Light::ambient(@tmath.Vec3::one(), 0.20)),
    )
    let env_cube = @t3d.procedural_environment_cubemap(dev, sun)
    renderer.set_environment(env_cube, sun)

    let orbit = @t3d.OrbitCamera::new(
      target=@tmath.Vec3::new(0.0, 1.0, 0.0),
      distance=122.0,
      yaw=0.5,
      pitch=0.62,
    )
    let fov : Float = 1.0
    let cam = @t3d.Camera::perspective(fov, (800.0 : Float) / (600.0 : Float), near=0.1)
    let cam_node = scene.create_node(
      transform=orbit.transform(),
      payload=@t3d.NodePayload::Camera(cam),
    )

    if !show_win {
      let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8Srgb)
      renderer.render_offscreen(scene, cam_node, rt)
      let px = rt.readback()
      let mut lit = 0
      let mut i = 0
      while i + 3 < px.length() {
        if px[i].to_int() + px[i + 1].to_int() + px[i + 2].to_int() > 30 {
          lit = lit + 1
        }
        i = i + 4
      }
      let st = renderer.stats()
      // The camera frustum culls the field's far corners, so `visible` is a
      // large fraction of the 10k nodes rather than all of them.
      let expected_tris = st.visible_nodes * 12
      let draws_ok = st.draw_calls <= 8
      let batch_ok = st.instance_batches >= 1
      let visible_ok = st.visible_nodes > 8000 && st.visible_nodes <= count + 1
      let tris_ok = st.triangles == expected_tris
      if shot != "" {
        let _ = @tycho.save_png(shot, 800, 600, px)
      }
      let errs = dev.validation_errors()
      println(
        "[64-tycho-3d-instances] \{st.summary()} lit=\{lit} nodes=\{count} validation=\{errs}",
      )
      if errs == 0 && lit > 10000 && draws_ok && batch_ok && visible_ok && tris_ok {
        println("[64-tycho-3d-instances] OK — 10000 nodes in \{st.draw_calls} draws")
      } else {
        println(
          "[64-tycho-3d-instances] FAIL — lit=\{lit} draws=\{st.draw_calls} batches=\{st.instance_batches} visible=\{st.visible_nodes} tris=\{st.triangles} errs=\{errs}",
        )
      }
      rt.destroy()
    } else {
      let sc = dev.create_swapchain("64-tycho-3d-instances", 800, 600)
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
      println("[64-tycho-3d-instances] LEAK — \{leaks} bytes after destroy")
    }
    if errs != 0 {
      println("[64-tycho-3d-instances] validation errors: \{errs}")
    }
  } catch {
    err => println("[64-tycho-3d-instances] FAIL — \{err}")
  }
}
