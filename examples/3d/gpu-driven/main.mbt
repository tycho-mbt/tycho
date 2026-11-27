// 3d/gpu-driven — GPU-driven culling and indirect draws.
// The GPU path submits all 10k instances and lets a compute shader compact the
// visible ones and grow the indirect instance count. The CPU path frustum-
// culls nodes first. Both must produce the same image.

///|
fn to_f(i : Int) -> Float {
  Float::from_double(i.to_double())
}

///|
fn build_field(
  renderer : @t3d.Renderer3D,
  dev : @tycho.Device,
) -> (@t3d.Scene, @t3d.NodeId, @tycho.Texture) raise {
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
  let env = @t3d.procedural_environment_cubemap(dev, sun, size=64, samples=32)
  renderer.set_environment(env, sun)

  let orbit = @t3d.OrbitCamera::new(
    target=@tmath.Vec3::new(0.0, 1.0, 0.0),
    distance=122.0,
    yaw=0.5,
    pitch=0.62,
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
        "3d/gpu-driven",
        validation=true,
        headless=!show_win,
      ),
    )
    let desc_gpu : @t3d.RendererDesc = {
      max_objects: 24000,
      max_lights: 16,
      max_materials: 64,
      max_textures: 64,
      msaa: true,
      bloom: true,
      shadows: true,
      shadow_map_size: 1024,
      shadow_cascades: 2,
      gpu_culling: true,
      bindless: true,
    }
    let desc_cpu : @t3d.RendererDesc = {
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
      bindless: true,
    }
    let r_gpu = @t3d.Renderer3D::new(dev, desc=desc_gpu)
    let r_cpu = @t3d.Renderer3D::new(dev, desc=desc_cpu)
    let (scene_gpu, cam_gpu, env_gpu) = build_field(r_gpu, dev)
    let (scene_cpu, cam_cpu, env_cpu) = build_field(r_cpu, dev)

    if !show_win {
      let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8Srgb)
      r_gpu.render_offscreen(scene_gpu, cam_gpu, rt)
      let px_gpu = rt.readback()
      if shot != "" {
        let _ = @tycho.save_png(shot, 800, 600, px_gpu)
      }
      r_cpu.render_offscreen(scene_cpu, cam_cpu, rt)
      let px_cpu = rt.readback()
      let diff = diff_pixels(px_gpu, px_cpu)
      let sg = r_gpu.stats()
      let sc = r_cpu.stats()
      let errs = dev.validation_errors()
      let ok = errs == 0 &&
        diff < 500 &&
        sg.draw_calls == 5 &&
        sc.draw_calls == 5 &&
        sg.instance_batches == 1 &&
        sg.visible_nodes == 10001 &&
        sc.visible_nodes < sg.visible_nodes
      println(
        "[3d/gpu-driven] gpu: \{sg.summary()}",
      )
      println(
        "[3d/gpu-driven] cpu: \{sc.summary()}",
      )
      println(
        "[3d/gpu-driven] diff=\{diff} validation=\{errs}",
      )
      if ok {
        println("[3d/gpu-driven] OK — compute culling + indirect draw match the CPU path")
      } else {
        println("[3d/gpu-driven] FAIL — see counters above")
      }
      rt.destroy()
    } else {
      let sc = dev.create_swapchain("3d/gpu-driven", 800, 600)
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
        r_gpu.render_swapchain(sc, scene_gpu, cam_gpu)
      }
      sc.destroy()
    }

    let errs = dev.validation_errors()
    r_gpu.destroy()
    r_cpu.destroy()
    env_gpu.destroy()
    env_cpu.destroy()
    let leaks = dev.allocator_used_bytes()
    dev.destroy()
    if leaks != (0 : UInt64) {
      println("[3d/gpu-driven] LEAK — \{leaks} bytes after destroy")
    }
    if errs != 0 {
      println("[3d/gpu-driven] validation errors: \{errs}")
    }
  } catch {
    err => println("[3d/gpu-driven] FAIL — \{err}")
  }
}
