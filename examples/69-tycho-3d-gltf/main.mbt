// Example 69 — glTF 2.0. Parses an embedded document (base64 buffer), uploads
// its meshes/materials and instantiates the node hierarchy.

///|
fn main {
  try {
    let show_win = @tycho.want_window()
    let shot = @tycho.screenshot_path()
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "69-tycho-3d-gltf",
        validation=true,
        headless=!show_win,
      ),
    )
    let renderer = @t3d.Renderer3D::new(dev)
    let scene = @t3d.Scene::new()
    let gltf = @tgeo.parse_gltf(box_scene_json)

    let ground_mat = renderer.create_material(
      @t3d.MaterialDesc::pbr(@t3d.srgb(0.24, 0.26, 0.30), metallic=0.0, roughness=0.9),
    )
    let ground_mesh = renderer.upload_mesh(@tgeo.box(width=12.0, height=0.2, depth=12.0))
    let ground = scene.create_node(
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, -0.6, 0.0)),
      payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(ground_mesh, ground_mat)),
    )
    scene.set_local_bounds(ground, renderer.mesh_bounds(ground_mesh))

    let nodes = @t3d.load_gltf(renderer, scene, gltf)

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
      payload=@t3d.NodePayload::Light(@t3d.Light::ambient(@tmath.Vec3::one(), 0.22)),
    )
    let env = @t3d.procedural_environment_cubemap(dev, sun, size=128, samples=64)
    renderer.set_environment(env, sun)

    let orbit = @t3d.OrbitCamera::new(
      target=@tmath.Vec3::new(0.0, 0.4, 0.0),
      distance=6.4,
      yaw=0.35,
      pitch=0.25,
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
      if shot != "" {
        let _ = @tycho.save_png(shot, 800, 600, px)
      }
      let mut lit = 0
      let mut i = 0
      while i + 3 < px.length() {
        if px[i].to_int() + px[i + 1].to_int() + px[i + 2].to_int() > 30 {
          lit = lit + 1
        }
        i = i + 4
      }
      let st = renderer.stats()
      let errs = dev.validation_errors()
      let ok = errs == 0 &&
        gltf.meshes.length() == 1 &&
        gltf.nodes.length() == 3 &&
        nodes.length() == 3 &&
        st.draw_calls == 6 &&
        st.instance_batches == 1 &&
        lit > 20000
      println(
        "[69-tycho-3d-gltf] gltf_meshes=\{gltf.meshes.length()} gltf_nodes=\{gltf.nodes.length()} scene_nodes=\{nodes.length()} \{st.summary()} lit=\{lit} validation=\{errs}",
      )
      if ok {
        println("[69-tycho-3d-gltf] OK — parsed glTF hierarchy and rendered it")
      } else {
        println("[69-tycho-3d-gltf] FAIL — see counts above")
      }
      rt.destroy()
    } else {
      let sc = dev.create_swapchain("69-tycho-3d-gltf", 800, 600)
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
    env.destroy()
    dev.destroy()
    if errs != 0 {
      println("[69-tycho-3d-gltf] validation errors: \{errs}")
    }
  } catch {
    err => println("[69-tycho-3d-gltf] FAIL — \{err}")
  }
}
