// Example 65 — transparent ordering.
// Two 50%-alpha quads over a near-black backdrop. The renderer sorts blended
// nodes back-to-front, so swapping the red quad's depth must flip which colour
// dominates the centre pixel.

///|
fn main {
  try {
    let show_win = @tycho.want_window()
    let shot = @tycho.screenshot_path()
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "65-tycho-3d-transparency",
        validation=true,
        headless=!show_win,
      ),
    )
    let renderer = @t3d.Renderer3D::new(dev)
    let scene = @t3d.Scene::new()

    let quad = renderer.upload_mesh(@tgeo.plane(width=5.0, height=5.0))
    let quad_bounds = renderer.mesh_bounds(quad)
    let backdrop_mat = renderer.create_material(
      @t3d.MaterialDesc::unlit(@tmath.Vec4::new(0.02, 0.02, 0.02, 1.0)),
    )
    let blue_mat = renderer.create_material(
      @t3d.MaterialDesc::unlit(@tmath.Vec4::new(0.10, 0.20, 0.90, 0.5))
      .with_alpha(@t3d.AlphaMode::Blend),
    )
    let red_mat = renderer.create_material(
      @t3d.MaterialDesc::unlit(@tmath.Vec4::new(0.90, 0.10, 0.10, 0.5))
      .with_alpha(@t3d.AlphaMode::Blend),
    )
    let backdrop = scene.create_node(
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, 0.0, -4.0)),
      payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(quad, backdrop_mat)),
    )
    scene.set_local_bounds(backdrop, quad_bounds)
    let blue = scene.create_node(
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, 0.0, -1.5)),
      payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(quad, blue_mat)),
    )
    scene.set_local_bounds(blue, quad_bounds)
    let red = scene.create_node(
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, 0.0, 0.0)),
      payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(quad, red_mat)),
    )
    scene.set_local_bounds(red, quad_bounds)

    let _ambient = scene.create_node(
      payload=@t3d.NodePayload::Light(@t3d.Light::ambient(@tmath.Vec3::one(), 0.0)),
    )
    let cam = @t3d.Camera::perspective(1.0, (800.0 : Float) / (600.0 : Float), near=0.1)
    let cam_node = scene.create_node(
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, 0.0, 6.0)),
      payload=@t3d.NodePayload::Camera(cam),
    )

    if !show_win {
      let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8Srgb)
      let centre = (300 * 800 + 400) * 4
      renderer.render_offscreen(scene, cam_node, rt)
      let front = rt.readback()
      let fr = front[centre].to_int()
      let fg = front[centre + 1].to_int()
      let fb = front[centre + 2].to_int()
      if shot != "" {
        let _ = @tycho.save_png(shot, 800, 600, front)
      }
      // Push the red quad behind the blue one; sorting must reverse the blend.
      scene.set_transform(red, @tmath.Transform::from_translation(@tmath.Vec3::new(0.0, 0.0, -3.0)))
      renderer.render_offscreen(scene, cam_node, rt)
      let back = rt.readback()
      let br = back[centre].to_int()
      let bg = back[centre + 1].to_int()
      let bb = back[centre + 2].to_int()
      let red_ok = fr > fb + 20
      let blue_ok = bb > br + 20
      let blend_ok = fr < 240 && bb > 20
      let errs = dev.validation_errors()
      let st = renderer.stats()
      println(
        "[65-tycho-3d-transparency] \{st.summary()} front=(\{fr},\{fg},\{fb}) back=(\{br},\{bg},\{bb}) validation=\{errs}",
      )
      if errs == 0 && red_ok && blue_ok && blend_ok {
        println("[65-tycho-3d-transparency] OK — back-to-front blending verified")
      } else {
        println(
          "[65-tycho-3d-transparency] FAIL — red_ok=\{red_ok} blue_ok=\{blue_ok} blend_ok=\{blend_ok} errs=\{errs}",
        )
      }
      rt.destroy()
    } else {
      let sc = dev.create_swapchain("65-tycho-3d-transparency", 800, 600)
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
        renderer.render_swapchain(sc, scene, cam_node)
      }
      sc.destroy()
    }

    let errs = dev.validation_errors()
    renderer.destroy()
    let leaks = dev.allocator_used_bytes()
    dev.destroy()
    if leaks != (0 : UInt64) {
      println("[65-tycho-3d-transparency] LEAK — \{leaks} bytes after destroy")
    }
    if errs != 0 {
      println("[65-tycho-3d-transparency] validation errors: \{errs}")
    }
  } catch {
    err => println("[65-tycho-3d-transparency] FAIL — \{err}")
  }
}
