// Example 61 — laplaceliu/tycho_3d showcase.
// The 49 PBR scene rebuilt through the scene-graph API: 2x5 metallic /
// dielectric sphere rows, ground, emissive orb, directional PCF shadow,
// procedural sky IBL, HDR bloom and ACES. Default headless PNG verification;
// pass --window for a WASD/QE/mouse fly camera.

///|
fn f_of_int(i : Int) -> Float {
  Float::from_double(i.to_double())
}

///|
fn cam_transform(pos : @tmath.Vec3, yaw : Float, pitch : Float) -> @tmath.Transform {
  @tmath.Transform::new(
    pos,
    @tmath.Quat::from_rotation_y(yaw) * @tmath.Quat::from_rotation_x(pitch),
    @tmath.Vec3::one(),
  )
}

///|
fn main {
  try {
    let show_win = @tycho.want_window()
    let shot = @tycho.screenshot_path()
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("61-tycho-3d-showcase", validation=true, headless=!show_win),
    )
    let renderer = @t3d.Renderer3D::new(dev)
    let scene = @t3d.Scene::new()

    let sphere_mesh = renderer.upload_mesh(
      @tgeo.sphere(radius=0.38, width_segments=32, height_segments=16),
    )
    let ground_mesh = renderer.upload_mesh(@tgeo.box(width=12.0, height=0.2, depth=12.0))

    let ground_mat = renderer.create_material(
      @t3d.MaterialDesc::pbr(@t3d.srgb(0.30, 0.32, 0.36), metallic=0.0, roughness=0.85),
    )
    let ground_node = scene.create_node(
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, -0.85, 0.0)),
      payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(ground_mesh, ground_mat)),
    )
    scene.set_local_bounds(ground_node, renderer.mesh_bounds(ground_mesh))

    let xs : Array[Float] = [-2.0, -1.0, 0.0, 1.0, 2.0]
    let roughs : Array[Float] = [0.12, 0.28, 0.48, 0.70, 0.90]
    let metals : Array[(Float, Float, Float)] = [
      (1.0, 0.78, 0.30),
      (0.95, 0.52, 0.36),
      (0.92, 0.94, 0.96),
      (0.35, 0.65, 0.98),
      (0.28, 0.90, 0.56),
    ]
    let diels : Array[(Float, Float, Float)] = [
      (0.86, 0.14, 0.14),
      (0.94, 0.54, 0.10),
      (0.90, 0.88, 0.82),
      (0.14, 0.34, 0.88),
      (0.14, 0.74, 0.36),
    ]
    for i = 0; i < 5; i = i + 1 {
      let (mr, mg, mb) = metals[i]
      let mm = renderer.create_material(
        @t3d.MaterialDesc::pbr(@t3d.srgb(mr, mg, mb), metallic=1.0, roughness=roughs[i]),
      )
      let mnode = scene.create_node(
        transform=@tmath.Transform::from_translation(@tmath.Vec3::new(xs[i], -0.42, -0.75)),
        payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(sphere_mesh, mm)),
      )
      scene.set_local_bounds(mnode, renderer.mesh_bounds(sphere_mesh))
      let (dr, dg, db) = diels[i]
      let dm = renderer.create_material(
        @t3d.MaterialDesc::pbr(@t3d.srgb(dr, dg, db), metallic=0.0, roughness=roughs[i]),
      )
      let dnode = scene.create_node(
        transform=@tmath.Transform::from_translation(@tmath.Vec3::new(xs[i], -0.42, 0.75)),
        payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(sphere_mesh, dm)),
      )
      scene.set_local_bounds(dnode, renderer.mesh_bounds(sphere_mesh))
    }

    let orb_mat = renderer.create_material(
      @t3d.MaterialDesc::pbr(
        @t3d.srgb(1.0, 0.9, 0.7),
        metallic=0.0,
        roughness=0.2,
      ).with_emissive(@tmath.Vec3::new(6.0, 4.6, 2.4)),
    )
    let orb = scene.create_node(
      transform=@tmath.Transform::new(
        @tmath.Vec3::new(2.3, 1.35, -1.45),
        @tmath.Quat::identity(),
        @tmath.Vec3::splat(0.63),
      ),
      payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(sphere_mesh, orb_mat)),
    )
    scene.set_local_bounds(orb, renderer.mesh_bounds(sphere_mesh))

    let glass_mat = renderer.create_material(
      @t3d.MaterialDesc::pbr(
        @t3d.srgb(0.45, 0.70, 1.0, a=0.45),
        metallic=0.0,
        roughness=0.08,
      ).with_alpha(@t3d.AlphaMode::Blend),
    )
    let glass = scene.create_node(
      transform=@tmath.Transform::new(
        @tmath.Vec3::new(-2.3, 1.05, -1.2),
        @tmath.Quat::identity(),
        @tmath.Vec3::splat(0.7),
      ),
      payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(sphere_mesh, glass_mat)),
    )
    scene.set_local_bounds(glass, renderer.mesh_bounds(sphere_mesh))

    let sun = @tmath.Vec3::new(4.0, 3.6, -2.2).normalize()
    let _sun_node = scene.create_node(
      transform=@tmath.Transform::new(
        @tmath.Vec3::zero(),
        @tmath.Quat::from_rotation_arc(@tmath.Vec3::neg_z(), sun),
        @tmath.Vec3::one(),
      ),
      payload=@t3d.NodePayload::Light(
        @t3d.Light::directional(
          @tmath.Vec3::new(1.0, 0.95, 0.85),
          4.2,
          shadow=Some(@t3d.ShadowDesc::default()),
        ),
      ),
    )
    let _ambient = scene.create_node(
      payload=@t3d.NodePayload::Light(@t3d.Light::ambient(@tmath.Vec3::one(), 0.25)),
    )

    let env_cube = @t3d.procedural_environment_cubemap(dev, sun)
    renderer.set_environment(env_cube, sun)

    let fov : Float = 2.0 * @tmath.atan((1.0 : Float) / (1.65 : Float))
    let cam = @t3d.Camera::perspective(fov, (800.0 : Float) / (600.0 : Float), near=0.1)
    let mut cam_pos = @tmath.Vec3::new(0.0, 1.75, 4.3)
    let mut yaw : Float = 0.0
    let mut pitch : Float = -0.46
    let cam_node = scene.create_node(
      transform=cam_transform(cam_pos, yaw, pitch),
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
      if shot != "" {
        let _ = @tycho.save_png(shot, 800, 600, px)
      }
      let errs = dev.validation_errors()
      println(
        "[61-tycho-3d-showcase] \{renderer.stats().summary()} lit=\{lit} validation=\{errs}",
      )
      if errs == 0 && lit > 10000 {
        println("[61-tycho-3d-showcase] OK — scene graph + PBR + shadow + HDR bloom/ACES")
      } else {
        println("[61-tycho-3d-showcase] FAIL — errs=\{errs} lit=\{lit}")
      }
      rt.destroy()
    } else {
      let sc = dev.create_swapchain("61-tycho-3d-showcase", 800, 600)
      let mut dragging = false
      let mut last_x = 0
      let mut last_y = 0
      let mut quit = false
      while !sc.should_close() && !quit {
        for ev in sc.poll_events() {
          match ev {
            @tycho.Event::CloseRequested => quit = true
            @tycho.Event::KeyDown(k, _) => {
              let rot = @tmath.Quat::from_rotation_y(yaw) *
                @tmath.Quat::from_rotation_x(pitch)
              let step : Float = 0.18
              if k == @tycho.KEY_ESCAPE {
                quit = true
              } else if k == @tycho.KEY_W {
                cam_pos = cam_pos + rot.mul_vec3(@tmath.Vec3::neg_z()).scale(step)
              } else if k == @tycho.KEY_S {
                cam_pos = cam_pos - rot.mul_vec3(@tmath.Vec3::neg_z()).scale(step)
              } else if k == @tycho.KEY_A {
                cam_pos = cam_pos - rot.mul_vec3(@tmath.Vec3::unit_x()).scale(step)
              } else if k == @tycho.KEY_D {
                cam_pos = cam_pos + rot.mul_vec3(@tmath.Vec3::unit_x()).scale(step)
              } else if k == @tycho.KEY_E {
                cam_pos = cam_pos + @tmath.Vec3::unit_y().scale(step)
              } else if k == @tycho.KEY_Q {
                cam_pos = cam_pos - @tmath.Vec3::unit_y().scale(step)
              } else if k == @tycho.KEY_LEFT {
                yaw = yaw - (0.06 : Float)
              } else if k == @tycho.KEY_RIGHT {
                yaw = yaw + (0.06 : Float)
              } else if k == @tycho.KEY_UP {
                pitch = if pitch + 0.05 > 1.2 { 1.2 } else { pitch + 0.05 }
              } else if k == @tycho.KEY_DOWN {
                pitch = if pitch - 0.05 < -1.2 { -1.2 } else { pitch - 0.05 }
              }
            }
            @tycho.Event::MouseDown(btn, mx, my) =>
              if btn == 1 {
                dragging = true
                last_x = mx
                last_y = my
              }
            @tycho.Event::MouseUp(btn, _, _) => if btn == 1 { dragging = false }
            @tycho.Event::MouseMove(mx, my) =>
              if dragging {
                yaw = yaw + f_of_int(mx - last_x) * (0.006 : Float)
                let np = pitch - f_of_int(my - last_y) * (0.006 : Float)
                pitch = if np > 1.2 { 1.2 } else if np < -1.2 { -1.2 } else { np }
                last_x = mx
                last_y = my
              }
            _ => ()
          }
        }
        scene.set_transform(cam_node, cam_transform(cam_pos, yaw, pitch))
        renderer.render_swapchain(sc, scene, cam_node)
      }
      sc.destroy()
    }

    let errs = dev.validation_errors()
    renderer.destroy()
    env_cube.destroy()
    dev.destroy()
    if errs != 0 {
      println("[61-tycho-3d-showcase] validation errors: \{errs}")
    }
  } catch {
    err => println("[61-tycho-3d-showcase] FAIL — \{err}")
  }
}
