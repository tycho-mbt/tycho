// geometry/primitives — geometry primitive gallery.
// Eleven tycho_geometry generators plus edges/wireframe line overlays rendered
// through tycho_3d, with an OrbitCamera controller and a picker assertion at
// the projected centre sphere.

///|
fn square_ring(half : Float) -> Array[@tmath.Vec2] {
  [
    @tmath.Vec2::new(-half, -half),
    @tmath.Vec2::new(half, -half),
    @tmath.Vec2::new(half, half),
    @tmath.Vec2::new(-half, half),
  ]
}

///|
/// Concave L outline (exercises the ear-cut triangulation).
fn l_ring() -> Array[@tmath.Vec2] {
  [
    @tmath.Vec2::new(-0.6, -0.6),
    @tmath.Vec2::new(0.6, -0.6),
    @tmath.Vec2::new(0.6, 0.0),
    @tmath.Vec2::new(0.0, 0.0),
    @tmath.Vec2::new(0.0, 0.6),
    @tmath.Vec2::new(-0.6, 0.6),
  ]
}

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
  rot_x : Float
}

///|
fn main {
  try {
    let opts = @exwin.Options::parse("geometry/primitives")
    let show_win = opts.window
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "geometry/primitives",
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
        x: -2.4, y: 0.90, z: -2.0, rot_x: 0.0,
      },
      {
        name: "circle",
        mesh: @tgeo.circle(radius=0.85),
        r: 0.92, g: 0.45, b: 0.18, metallic: 0.0, roughness: 0.50,
        x: 0.0, y: 0.90, z: -2.0, rot_x: 0.0,
      },
      {
        name: "ring",
        mesh: @tgeo.ring(inner=0.35, outer=0.85),
        r: 0.30, g: 0.70, b: 0.95, metallic: 1.0, roughness: 0.20,
        x: 2.4, y: 0.90, z: -2.0, rot_x: 0.0,
      },
      {
        name: "box",
        mesh: @tgeo.box(width=1.5, height=1.5, depth=1.5),
        r: 0.86, g: 0.20, b: 0.20, metallic: 0.0, roughness: 0.45,
        x: -2.4, y: 0.25, z: 0.0, rot_x: 0.0,
      },
      {
        name: "sphere",
        mesh: @tgeo.sphere(radius=0.75, width_segments=32, height_segments=16),
        r: 0.95, g: 0.95, b: 0.95, metallic: 0.2, roughness: 0.15,
        x: 0.0, y: 0.25, z: 0.0, rot_x: 0.0,
      },
      {
        name: "cylinder",
        mesh: @tgeo.cylinder(radius_top=0.6, radius_bottom=0.6, height=1.5, radial_segments=32),
        r: 0.95, g: 0.75, b: 0.30, metallic: 1.0, roughness: 0.30,
        x: 2.4, y: 0.25, z: 0.0, rot_x: 0.0,
      },
      {
        name: "cone",
        mesh: @tgeo.cone(radius=0.75, height=1.6, radial_segments=32),
        r: 0.25, g: 0.75, b: 0.45, metallic: 0.0, roughness: 0.40,
        x: -2.4, y: 0.30, z: 2.0, rot_x: 0.0,
      },
      {
        name: "capsule",
        mesh: @tgeo.capsule(radius=0.42, length=0.9, radial_segments=32),
        r: 0.35, g: 0.50, b: 0.95, metallic: 0.1, roughness: 0.25,
        x: 0.0, y: 0.37, z: 2.0, rot_x: 0.0,
      },
      {
        name: "torus",
        mesh: @tgeo.torus(radius=0.62, tube=0.20, radial_segments=16, tubular_segments=48),
        r: 0.90, g: 0.30, b: 0.70, metallic: 1.0, roughness: 0.20,
        x: 2.4, y: -0.30, z: 2.0, rot_x: @tmath.FRAC_PI_2,
      },
      {
        name: "shape",
        mesh: @tgeo.shape(
          @tgeo.Shape2D::new(square_ring(0.85), holes=[square_ring(0.35)]),
        ),
        r: 0.90, g: 0.62, b: 0.25, metallic: 0.0, roughness: 0.45,
        x: -2.4, y: 0.90, z: -4.0, rot_x: 0.0,
      },
      {
        name: "extrude",
        mesh: @tgeo.extrude(
          @tgeo.Shape2D::new(l_ring()),
          options=@tgeo.ExtrudeOptions::new(
            depth=0.8,
            bevel_enabled=true,
            bevel_thickness=0.06,
            bevel_size=0.05,
            bevel_segments=2,
          ),
        ),
        r: 0.30, g: 0.80, b: 0.70, metallic: 0.1, roughness: 0.35,
        x: 0.0, y: -0.5, z: -4.0, rot_x: -@tmath.FRAC_PI_2,
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
      let rot = if s.rot_x != 0.0 {
        @tmath.Quat::from_rotation_x(s.rot_x)
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

    // Line scene nodes: local-space line lists drawn with the node transform
    // and a per-node colour (box creases, torus-knot wireframe).
    let box_edges = renderer.upload_lines(
      @tgeo.edges(@tgeo.box(width=1.5, height=1.5, depth=1.5)),
    )
    let _edge_node = renderer.create_line_node(
      scene,
      box_edges,
      material=@t3d.LineMaterial::new(color=@tmath.Vec3::new(1.0, 0.85, 0.2)),
      transform=@tmath.Transform::from_translation(
        @tmath.Vec3::new(-2.4, 0.25, 0.0),
      ),
      name="box_edges",
    )
    let knot_wire = renderer.upload_lines(
      @tgeo.wireframe(
        @tgeo.torus_knot(
          radius=0.5,
          tube=0.16,
          tubular_segments=64,
          radial_segments=6,
        ),
      ),
    )
    let _wire_node = renderer.create_line_node(
      scene,
      knot_wire,
      material=@t3d.LineMaterial::new(color=@tmath.Vec3::new(0.3, 0.95, 1.0)),
      transform=@tmath.Transform::from_translation(
        @tmath.Vec3::new(2.4, 0.9, -4.0),
      ),
      name="knot_wireframe",
    )

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
      target=@tmath.Vec3::new(0.0, 0.6, 0.0),
      distance=11.5,
      yaw=0.35,
      pitch=0.38,
    )
    let fov : Float = 2.0 * @tmath.atan((1.0 : Float) / (1.8 : Float))
    let cam = @t3d.Camera::perspective(fov, (800.0 : Float) / (600.0 : Float), near=0.1)
    let cam_node = scene.add_camera(cam, transform=orbit.transform())

    if !show_win {
      let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8Srgb)
      renderer.render_offscreen( rt,scene, cam_node)
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
              let hit = renderer.pick(scene, cam_node.node(), clip.x / clip.w, clip.y / clip.w)
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
      opts.capture(800, 600, px)
      let errs = dev.validation_errors()
      println(
        "[geometry/primitives] \{renderer.stats().summary()} lit=\{lit} pick=\{pick_ok} validation=\{errs}",
      )
      let line_segments = renderer.stats().line_segments
      if errs == 0 && lit > 10000 && pick_ok && line_segments > 0 {
        println(
          "[geometry/primitives] OK — 11 generators + \{line_segments} line segments + orbit + picking",
        )
      } else {
        println(
          "[geometry/primitives] FAIL — lit=\{lit} pick=\{pick_ok} lines=\{line_segments} errs=\{errs}",
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
            scene.set_transform(cam_node.node(), orbit.transform())
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
      println("[geometry/primitives] LEAK — \{leaks} bytes after destroy")
    }
    if errs != 0 {
      println("[geometry/primitives] validation errors: \{errs}")
    }
  } catch {
    err => println("[geometry/primitives] FAIL — \{err}")
  }
}
