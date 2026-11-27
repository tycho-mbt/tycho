// 3d/debug-lines — debug line channel.
// Draws world-space AABB wireframes and axis lines through the depth-tested
// line pipeline, then verifies that clearing them changes the image.

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
    let opts = @exwin.Options::parse("3d/debug-lines")
    let show_win = opts.window
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "3d/debug-lines",
        validation=true,
        headless=!show_win,
      ),
    )
    let renderer = @t3d.Renderer3D::new(dev)
    let scene = @t3d.Scene::new()

    let ground_mat = renderer.create_material(
      @t3d.MaterialDesc::pbr(@t3d.srgb(0.24, 0.26, 0.30), metallic=0.0, roughness=0.9),
    )
    let ground_mesh = renderer.upload_mesh(@tgeo.box(width=14.0, height=0.2, depth=14.0))
    let ground = scene.create_node(
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, -0.6, 0.0)),
      payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(ground_mesh, ground_mat)),
    )
    scene.set_local_bounds(ground, renderer.mesh_bounds(ground_mesh))

    let box_mat = renderer.create_material(
      @t3d.MaterialDesc::pbr(@t3d.srgb(0.85, 0.30, 0.25), metallic=0.0, roughness=0.5),
    )
    let sphere_mat = renderer.create_material(
      @t3d.MaterialDesc::pbr(@t3d.srgb(0.35, 0.55, 0.90), metallic=0.4, roughness=0.25),
    )
    let cyl_mat = renderer.create_material(
      @t3d.MaterialDesc::pbr(@t3d.srgb(0.90, 0.75, 0.30), metallic=0.8, roughness=0.3),
    )
    let box_mesh = renderer.upload_mesh(@tgeo.box(width=1.2, height=1.2, depth=1.2))
    let box = scene.create_node(
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(-1.8, 0.1, 0.0)),
      payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(box_mesh, box_mat)),
    )
    scene.set_local_bounds(box, renderer.mesh_bounds(box_mesh))
    let sphere_mesh = renderer.upload_mesh(@tgeo.sphere(radius=0.7))
    let sphere = scene.create_node(
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, 0.2, 0.0)),
      payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(sphere_mesh, sphere_mat)),
    )
    scene.set_local_bounds(sphere, renderer.mesh_bounds(sphere_mesh))
    let cyl_mesh = renderer.upload_mesh(
      @tgeo.cylinder(radius_top=0.5, radius_bottom=0.5, height=1.4),
    )
    let cyl = scene.create_node(
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(1.8, 0.2, 0.0)),
      payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(cyl_mesh, cyl_mat)),
    )
    scene.set_local_bounds(cyl, renderer.mesh_bounds(cyl_mesh))

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
          shadow=@t3d.ShadowDesc::default(),
        ),
      ),
    )
    let _ambient = scene.create_node(
      payload=@t3d.NodePayload::Light(@t3d.Light::ambient(@tmath.Vec3::one(), 0.22)),
    )
    let env_cube = @t3d.procedural_environment_cubemap(dev, sun)
    renderer.set_environment(env_cube, sun)

    let orbit = @t3d.OrbitCamera::new(
      target=@tmath.Vec3::new(0.0, 0.4, 0.0),
      distance=6.2,
      yaw=0.35,
      pitch=0.22,
    )
    let cam = @t3d.Camera::perspective(1.0, (800.0 : Float) / (600.0 : Float), near=0.1)
    let cam_node = scene.create_node(
      transform=orbit.transform(),
      payload=@t3d.NodePayload::Camera(cam),
    )

    if !show_win {
      let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8Srgb)
      let wire = @tmath.Vec3::new(0.25, 1.0, 0.35)
      for node in [box, sphere, cyl] {
        match scene.world_bounds(node) {
          Some(b) => {
            // Inflate so the wireframe is not swallowed by the surface it hugs.
            let pad = @tmath.Vec3::new(0.03, 0.03, 0.03)
            renderer.add_debug_aabb(@tmath.Aabb3::new(b.min - pad, b.max + pad), wire)
          }
          None => ()
        }
      }
      renderer.add_debug_line(
        @tmath.Vec3::zero(),
        @tmath.Vec3::new(2.2, 0.0, 0.0),
        @tmath.Vec3::new(1.0, 0.2, 0.2),
      )
      renderer.add_debug_line(
        @tmath.Vec3::zero(),
        @tmath.Vec3::new(0.0, 2.2, 0.0),
        @tmath.Vec3::new(0.2, 1.0, 0.2),
      )
      renderer.add_debug_line(
        @tmath.Vec3::zero(),
        @tmath.Vec3::new(0.0, 0.0, 2.2),
        @tmath.Vec3::new(0.2, 0.4, 1.0),
      )
      renderer.render_offscreen( rt,scene, cam_node)
      let with_lines = rt.readback()
      let st = renderer.stats()
      let lines = st.line_segments
      opts.capture(800, 600, with_lines)
      renderer.clear_debug_lines()
      renderer.render_offscreen( rt,scene, cam_node)
      let without = rt.readback()
      let diff = diff_pixels(with_lines, without)
      let after = renderer.stats().line_segments
      let errs = dev.validation_errors()
      println(
        "[3d/debug-lines] \{st.summary()} after_clear=\{after} diff=\{diff} validation=\{errs}",
      )
      if errs == 0 && lines == 39 && after == 0 && diff > 1000 {
        println("[3d/debug-lines] OK — depth-tested debug lines (\{lines} segments)")
      } else {
        println(
          "[3d/debug-lines] FAIL — segments=\{lines} after_clear=\{after} diff=\{diff} errs=\{errs}",
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
        let wire = @tmath.Vec3::new(0.25, 1.0, 0.35)
        for node in [box, sphere, cyl] {
          match scene.world_bounds(node) {
            Some(b) => {
              let pad = @tmath.Vec3::new(0.03, 0.03, 0.03)
              renderer.add_debug_aabb(@tmath.Aabb3::new(b.min - pad, b.max + pad), wire)
            }
            None => ()
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
      println("[3d/debug-lines] LEAK — \{leaks} bytes after destroy")
    }
    if errs != 0 {
      println("[3d/debug-lines] validation errors: \{errs}")
    }
  } catch {
    err => println("[3d/debug-lines] FAIL — \{err}")
  }
}
