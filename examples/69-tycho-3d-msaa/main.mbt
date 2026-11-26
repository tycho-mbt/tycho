// Example 68 — 4x MSAA. Renders the same scene through a multisampled and a
// single-sampled renderer and asserts that geometry edges differ.

///|
fn build_scene(renderer : @t3d.Renderer3D, dev : @tycho.Device) -> (@t3d.Scene, @t3d.NodeId, @tycho.Texture) raise {
  let scene = @t3d.Scene::new()
  let ground_mat = renderer.create_material(
    @t3d.MaterialDesc::pbr(@t3d.srgb(0.26, 0.28, 0.32), metallic=0.0, roughness=0.9),
  )
  let ground_mesh = renderer.upload_mesh(@tgeo.box(width=14.0, height=0.2, depth=14.0))
  let ground = scene.create_node(
    transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, -0.6, 0.0)),
    payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(ground_mesh, ground_mat)),
  )
  scene.set_local_bounds(ground, renderer.mesh_bounds(ground_mesh))

  let box_mesh = renderer.upload_mesh(@tgeo.box(width=1.6, height=1.6, depth=1.6))
  let box_mat = renderer.create_material(
    @t3d.MaterialDesc::pbr(@t3d.srgb(0.85, 0.3, 0.25), metallic=0.1, roughness=0.35),
  )
  let box = scene.create_node(
    transform=@tmath.Transform::new(
      @tmath.Vec3::new(-1.7, 0.2, 0.0),
      @tmath.Quat::from_rotation_y(0.5),
      @tmath.Vec3::one(),
    ),
    payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(box_mesh, box_mat)),
  )
  scene.set_local_bounds(box, renderer.mesh_bounds(box_mesh))

  let sphere_mesh = renderer.upload_mesh(@tgeo.sphere(radius=0.85))
  let sphere_mat = renderer.create_material(
    @t3d.MaterialDesc::pbr(@t3d.srgb(0.35, 0.55, 0.9), metallic=0.5, roughness=0.2),
  )
  let sphere = scene.create_node(
    transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.1, 0.25, 0.0)),
    payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(sphere_mesh, sphere_mat)),
  )
  scene.set_local_bounds(sphere, renderer.mesh_bounds(sphere_mesh))

  let cyl_mesh = renderer.upload_mesh(
    @tgeo.cylinder(radius_top=0.55, radius_bottom=0.55, height=1.7),
  )
  let cyl_mat = renderer.create_material(
    @t3d.MaterialDesc::pbr(@t3d.srgb(0.9, 0.75, 0.3), metallic=0.8, roughness=0.3),
  )
  let cyl = scene.create_node(
    transform=@tmath.Transform::from_translation(@tmath.Vec3::new(1.9, 0.25, 0.0)),
    payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(cyl_mesh, cyl_mat)),
  )
  scene.set_local_bounds(cyl, renderer.mesh_bounds(cyl_mesh))

  let sun = @tmath.Vec3::new(3.0, 4.0, -2.0).normalize()
  let _sun = scene.create_node(
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
    payload=@t3d.NodePayload::Light(@t3d.Light::ambient(@tmath.Vec3::one(), 0.22)),
  )
  let env = @t3d.procedural_environment_cubemap(dev, sun, size=64, samples=32)
  renderer.set_environment(env, sun)

  let orbit = @t3d.OrbitCamera::new(
    target=@tmath.Vec3::new(0.0, 0.3, 0.0),
    distance=6.6,
    yaw=0.32,
    pitch=0.25,
  )
  let cam = @t3d.Camera::perspective(1.0, (800.0 : Float) / (600.0 : Float), near=0.1)
  let cam_node = scene.create_node(
    transform=orbit.transform(),
    payload=@t3d.NodePayload::Camera(cam),
  )
  (scene, cam_node, env)
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
        "69-tycho-3d-msaa",
        validation=true,
        headless=!show_win,
      ),
    )
    let desc_msaa : @t3d.RendererDesc = {
      max_objects: 4096,
      max_lights: 16,
      max_materials: 64,
      max_textures: 64,
      msaa: true,
      bloom: true,
      shadows: true,
      shadow_map_size: 1024,
      shadow_cascades: 2,
      gpu_culling: false,
      bindless: true,
    }
    let desc_plain : @t3d.RendererDesc = {
      max_objects: 4096,
      max_lights: 16,
      max_materials: 64,
      max_textures: 64,
      msaa: false,
      bloom: true,
      shadows: true,
      shadow_map_size: 1024,
      shadow_cascades: 2,
      gpu_culling: false,
      bindless: true,
    }
    let r_msaa = @t3d.Renderer3D::new(dev, desc=desc_msaa)
    let r_plain = @t3d.Renderer3D::new(dev, desc=desc_plain)
    let (scene, cam_node, env1) = build_scene(r_msaa, dev)
    let (scene2, cam_node2, env2) = build_scene(r_plain, dev)

    if !show_win {
      let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8Srgb)
      r_msaa.render_offscreen(scene, cam_node, rt)
      let aa = rt.readback()
      if shot != "" {
        let _ = @tycho.save_png(shot, 800, 600, aa)
      }
      r_plain.render_offscreen(scene2, cam_node2, rt)
      let plain = rt.readback()
      let diff = diff_pixels(aa, plain)
      let errs = dev.validation_errors()
      let draws_ok = r_msaa.stats().draw_calls == r_plain.stats().draw_calls
      println(
        "[69-tycho-3d-msaa] draws=\{r_msaa.stats().draw_calls} edge_diff=\{diff} validation=\{errs}",
      )
      if errs == 0 && diff > 1500 && draws_ok {
        println("[69-tycho-3d-msaa] OK — 4x MSAA resolves edges (diff=\{diff})")
      } else {
        println(
          "[69-tycho-3d-msaa] FAIL — diff=\{diff} draws_ok=\{draws_ok} errs=\{errs}",
        )
      }
      rt.destroy()
    } else {
      let sc = dev.create_swapchain("69-tycho-3d-msaa", 800, 600)
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
        }
        r_msaa.render_swapchain(sc, scene, cam_node)
      }
      sc.destroy()
    }

    let errs = dev.validation_errors()
    r_msaa.destroy()
    r_plain.destroy()
    env1.destroy()
    env2.destroy()
    let leaks = dev.allocator_used_bytes()
    dev.destroy()
    if leaks != (0 : UInt64) {
      println("[69-tycho-3d-msaa] LEAK — \{leaks} bytes after destroy")
    }
    if errs != 0 {
      println("[69-tycho-3d-msaa] validation errors: \{errs}")
    }
  } catch {
    err => println("[69-tycho-3d-msaa] FAIL — \{err}")
  }
}
