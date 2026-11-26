// Example 62 — geometry primitive gallery.
// Nine tycho_geometry generators rendered through tycho_3d, with an OrbitCamera
// controller and a picker assertion at the projected centre sphere.

///|
struct ShapeSpec {
  name : String
  mesh : @tgeo.MeshData
  r : Float
  g : Float
  b : Float
  metallic : Float
  roughness : Float
  x : Float
  y : Float
  z : Float
  tilt_x : Bool
}

///|
fn main {
  try {
    let show_win = @tycho.want_window()
    let shot = @tycho.screenshot_path()
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "63-tycho-geometry-primitives",
        validation=true,
        headless=!show_win,
      ),
    )
    let renderer = @t3d.Renderer3D::new(dev)
    let scene = @t3d.Scene::new()

    let ground_mat = renderer.create_material(
      @t3d.MaterialDesc::pbr(@t3d.srgb(0.28, 0.30, 0.34), metallic=0.0, roughness=0.9),
    )
    let ground_mesh = renderer.upload_mesh(@tgeo.box(width=16.0, height=0.2, depth=16.0))
    let ground = scene.create_node(
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, -0.6, 0.0)),
      payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(ground_mesh, ground_mat)),
    )
    scene.set_local_bounds(ground, renderer.mesh_bounds(ground_mesh))

    let specs : Array[ShapeSpec] = [
      {
        name: "plane",
        mesh: @tgeo.plane(width=1.7, height=1.7),
        r: 0.85, g: 0.85, b: 0.90, metallic: 0.0, roughness: 0.40,
        x: -2.4, y: 0.90, z: -2.0, tilt_x: false,
      },
      {
        name: "circle",
        mesh: @tgeo.circle(radius=0.85),
        r: 0.92, g: 0.45, b: 0.18, metallic: 0.0, roughness: 0.50,
        x: 0.0, y: 0.90, z: -2.0, tilt_x: false,
      },
      {
        name: "ring",
        mesh: @tgeo.ring(inner=0.35, outer=0.85),
        r: 0.30, g: 0.70, b: 0.95, metallic: 1.0, roughness: 0.20,
        x: 2.4, y: 0.90, z: -2.0, tilt_x: false,
      },
      {
        name: "box",
        mesh: @tgeo.box(width=1.5, height=1.5, depth=1.5),
        r: 0.86, g: 0.20, b: 0.20, metallic: 0.0, roughness: 0.45,
        x: -2.4, y: 0.25, z: 0.0, tilt_x: false,
      },
      {
        name: "sphere",
        mesh: @tgeo.sphere(radius=0.75, width_segments=32, height_segments=16),
        r: 0.95, g: 0.95, b: 0.95, metallic: 0.2, roughness: 0.15,
        x: 0.0, y: 0.25, z: 0.0, tilt_x: false,
      },
      {
        name: "cylinder",
        mesh: @tgeo.cylinder(radius_top=0.6, radius_bottom=0.6, height=1.5, radial_segments=32),
        r: 0.95, g: 0.75, b: 0.30, metallic: 1.0, roughness: 0.30,
        x: 2.4, y: 0.25, z: 0.0, tilt_x: false,
      },
      {
        name: "cone",
        mesh: @tgeo.cone(radius=0.75, height=1.6, radial_segments=32),
        r: 0.25, g: 0.75, b: 0.45, metallic: 0.0, roughness: 0.40,
        x: -2.4, y: 0.30, z: 2.0, tilt_x: false,
      },
      {
        name: "capsule",
        mesh: @tgeo.capsule(radius=0.42, length=0.9, radial_segments=32),
        r: 0.35, g: 0.50, b: 0.95, metallic: 0.1, roughness: 0.25,
        x: 0.0, y: 0.37, z: 2.0, tilt_x: false,
      },
      {
        name: "torus",
        mesh: @tgeo.torus(radius=0.62, tube=0.20, radial_segments=16, tubular_segments=48),
        r: 0.90, g: 0.30, b: 0.70, metallic: 1.0, roughness: 0.20,
        x: 2.4, y: -0.30, z: 2.0, tilt_x: true,
      },
    ]
    let mut centre_node : @t3d.NodeId? = None
    for s in specs {
      let mat = renderer.create_material(
        @t3d.MaterialDesc::pbr(
          @t3d.srgb(s.r, s.g, s.b),
          metallic=s.metallic,
          roughness=s.roughness,
        ),
      )
      let mesh = renderer.upload_mesh(s.mesh)
      let rot = if s.tilt_x {
        @tmath.Quat::from_rotation_x(@tmath.FRAC_PI_2)
      } else {
        @tmath.Quat::identity()
      }
      let node = scene.create_node(
        transform=@tmath.Transform::new(
          @tmath.Vec3::new(s.x, s.y, s.z),
          rot,
          @tmath.Vec3::one(),
        ),
        payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(mesh, mat)),
      )
      scene.set_name(node, s.name)
      scene.set_local_bounds(node, renderer.mesh_bounds(mesh))
      if s.name == "sphere" {
        centre_node = Some(node)
      }
    }

    let sun = @tmath.Vec3::new(4.0, 3.8, -2.4).normalize()
    let _sun_node = scene.create_node(
      transform=@tmath.Transform::new(
        @tmath.Vec3::zero(),
        @tmath.Quat::from_rotation_arc(@tmath.Vec3::neg_z(), sun),
        @tmath.Vec3::one(),
      ),
      payload=@t3d.NodePayload::Light(
        @t3d.Light::directional(
          @tmath.Vec3::new(1.0, 0.96, 0.88),
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
      target=@tmath.Vec3::new(0.0, 0.6, 0.0),
      distance=11.5,
      yaw=0.35,
      pitch=0.38,
    )
    let fov : Float = 2.0 * @tmath.atan((1.0 : Float) / (1.8 : Float))
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
      // End-to-end picking: project the centre sphere and expect that node back.
      let mut pick_ok = false
      match centre_node {
        Some(cn) => {
          let world = orbit.transform().to_affine3()
          match cam.view_proj(world) {
            Some(vp) => {
              let centre = scene.world_transform(cn).translation
              let clip = vp.mul_vec4(
                @tmath.Vec4::new(centre.x, centre.y, centre.z, 1.0),
              )
              let hit = renderer.pick(scene, cam_node, clip.x / clip.w, clip.y / clip.w)
              match hit {
                Some(h) => pick_ok = h.node == cn
                None => ()
              }
            }
            None => ()
          }
        }
        None => ()
      }
      if shot != "" {
        let _ = @tycho.save_png(shot, 800, 600, px)
      }
      let errs = dev.validation_errors()
      println(
        "[63-tycho-geometry-primitives] \{renderer.stats().summary()} lit=\{lit} pick=\{pick_ok} validation=\{errs}",
      )
      if errs == 0 && lit > 10000 && pick_ok {
        println("[63-tycho-geometry-primitives] OK — 9 generators + orbit + picking")
      } else {
        println(
          "[63-tycho-geometry-primitives] FAIL — lit=\{lit} pick=\{pick_ok} errs=\{errs}",
        )
      }
      rt.destroy()
    } else {
      let sc = dev.create_swapchain("63-tycho-geometry-primitives", 800, 600)
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
      println("[63-tycho-geometry-primitives] LEAK — \{leaks} bytes after destroy")
    }
    if errs != 0 {
      println("[63-tycho-geometry-primitives] validation errors: \{errs}")
    }
  } catch {
    err => println("[63-tycho-geometry-primitives] FAIL — \{err}")
  }
}
