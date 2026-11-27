// 3d/env-quality — environment quality.
// Builds the PMREM chain at 512^2 with 256 GGX samples per texel and shows a
// metallic roughness ladder so the mip chain is easy to inspect.

///|
fn main {
  try {
    let opts = @exwin.Options::parse("3d/env-quality")
    let show_win = opts.window
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "3d/env-quality",
        validation=true,
        headless=!show_win,
      ),
    )
    let renderer = @t3d.Renderer3D::new(dev)
    let scene = @t3d.Scene::new()

    let ground_mat = renderer.create_material(
      @t3d.MaterialDesc::pbr(@t3d.srgb(0.22, 0.24, 0.28), metallic=0.0, roughness=0.9),
    )
    let ground_mesh = renderer.upload_mesh(@tgeo.box(width=26.0, height=0.2, depth=26.0))
    let ground = scene.create_node(
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, -0.6, 0.0)),
      payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(ground_mesh, ground_mat)),
    )
    scene.set_local_bounds(ground, renderer.mesh_bounds(ground_mesh))

    let sphere_mesh = renderer.upload_mesh(
      @tgeo.sphere(radius=0.78, width_segments=48, height_segments=24),
    )
    let sphere_bounds = renderer.mesh_bounds(sphere_mesh)
    let roughnesses : Array[Float] = [0.0, 0.25, 0.5, 0.75, 1.0]
    let probes : Array[(@t3d.NodeId, Float)] = []
    for i = 0; i < roughnesses.length(); i = i + 1 {
      let mat = renderer.create_material(
        @t3d.MaterialDesc::pbr(
          @t3d.srgb(0.92, 0.92, 0.94),
          metallic=1.0,
          roughness=roughnesses[i],
        ),
      )
      let x : Float = -3.0 + 1.5 * Float::from_double(i.to_double())
      let node = scene.create_node(
        transform=@tmath.Transform::from_translation(@tmath.Vec3::new(x, 0.8, 0.0)),
        payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(sphere_mesh, mat)),
      )
      scene.set_local_bounds(node, sphere_bounds)
      probes.push((node, roughnesses[i]))
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
          3.4,
          shadow=Some(@t3d.ShadowDesc::default()),
        ),
      ),
    )
    let _ambient = scene.create_node(
      payload=@t3d.NodePayload::Light(@t3d.Light::ambient(@tmath.Vec3::one(), 0.2)),
    )
    let env_size = 512
    let env_samples = 256
    let env_cube = @t3d.procedural_environment_cubemap(
      dev,
      sun,
      size=env_size,
      samples=env_samples,
    )
    renderer.set_environment(env_cube, sun)

    let orbit = @t3d.OrbitCamera::new(
      target=@tmath.Vec3::new(0.0, 0.8, 0.0),
      distance=9.5,
      yaw=0.28,
      pitch=0.20,
    )
    let cam = @t3d.Camera::perspective(1.0, (800.0 : Float) / (600.0 : Float), near=0.1)
    let cam_node = scene.create_node(
      transform=orbit.transform(),
      payload=@t3d.NodePayload::Camera(cam),
    )

    if !show_win {
      let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8Srgb)
      renderer.render_offscreen(scene, cam_node, rt)
      let px = rt.readback()
      opts.capture(800, 600, px)
      let mut lit = 0
      let mut bright = 0
      let mut i = 0
      while i + 3 < px.length() {
        let s = px[i].to_int() + px[i + 1].to_int() + px[i + 2].to_int()
        if s > 30 {
          lit = lit + 1
        }
        if s > 720 {
          bright = bright + 1
        }
        i = i + 4
      }
      let st = renderer.stats()
      // A mirror sphere shows the sky horizon as a hard band; a fully rough
      // one averages it away. Compare luminance ranges at the two centres.
      let ranges : Array[Float] = []
      match cam.view_proj(orbit.transform().to_affine3()) {
        Some(vp) => {
          for probe in probes {
            let (node, _r) = probe
            let c = scene.world_transform(node).translation
            let clip = vp.mul_vec4(@tmath.Vec4::new(c.x, c.y, c.z, 1.0))
            let cx = ((clip.x / clip.w * 0.5 + 0.5) * 800.0).to_int()
            let cy_f : Float = 1.0 - (clip.y / clip.w * 0.5 + 0.5)
            let cy = (cy_f * 600.0).to_int()
            let mut lo = 255
            let mut hi = 0
            for dy = -16; dy <= 16; dy = dy + 1 {
              for dx = -16; dx <= 16; dx = dx + 1 {
                let x = cx + dx
                let y = cy + dy
                if x >= 0 && x < 800 && y >= 0 && y < 600 {
                  let v = px[(y * 800 + x) * 4].to_int()
                  if v < lo {
                    lo = v
                  }
                  if v > hi {
                    hi = v
                  }
                }
              }
            }
            ranges.push(Float::from_double((hi - lo).to_double()))
          }
        }
        None => ()
      }
      let mirror_range = if ranges.length() > 0 { ranges[0] } else { 0.0 }
      let rough_range = if ranges.length() > 0 { ranges[ranges.length() - 1] } else { 0.0 }
      let mip_ok = rough_range < mirror_range * 0.85 && mirror_range > 15.0
      let errs = dev.validation_errors()
      println(
        "[3d/env-quality] env=\{env_size}^2x\{env_samples} \{st.summary()} lit=\{lit} bright=\{bright} mirror_range=\{mirror_range} rough_range=\{rough_range} validation=\{errs}",
      )
      if errs == 0 && lit > 20000 && st.draw_calls == 5 && st.visible_nodes == 6 && mip_ok {
        println("[3d/env-quality] OK — roughness ladder from the \{env_size}^2 PMREM chain")
      } else {
        println(
          "[3d/env-quality] FAIL — lit=\{lit} draws=\{st.draw_calls} visible=\{st.visible_nodes} mirror_range=\{mirror_range} rough_range=\{rough_range} errs=\{errs}",
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
      println("[3d/env-quality] LEAK — \{leaks} bytes after destroy")
    }
    if errs != 0 {
      println("[3d/env-quality] validation errors: \{errs}")
    }
  } catch {
    err => println("[3d/env-quality] FAIL — \{err}")
  }
}
