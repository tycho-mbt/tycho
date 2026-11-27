// 3d/skinning — GPU skinning.
//
// A 4-bone chain bends a weighted cylinder. The mesh carries four joint
// indices and weights per vertex; the vertex shader applies the palette from
// the bone SSBO. The headless run renders the rest pose and a bent pose and
// asserts a large pixel difference, proving the deformation reaches the GPU.

///|
fn f79(i : Int) -> Float {
  Float::from_int(i)
}

///|
fn clamp79(v : Float, lo : Float, hi : Float) -> Float {
  if v < lo {
    lo
  } else if v > hi {
    hi
  } else {
    v
  }
}

///|
fn make_skinned_column() -> @tgeo.MeshData raise {
  let mesh = @tgeo.cylinder(
    radius_top=0.45,
    radius_bottom=0.45,
    height=4.0,
    radial_segments=20,
    height_segments=16,
    open_ended=false,
  )
  let n = mesh.vertex_count()
  let joints = FixedArray::make(n, @tmath.Vec4::zero())
  let weights = FixedArray::make(n, @tmath.Vec4::zero())
  for i = 0; i < n; i = i + 1 {
    let y = mesh.positions[i].y
    // Three 1.0-unit segments between joints at y = -2, -1, 0, 1.
    let t = clamp79((y + 2.0) / 1.0, 0.0, 3.0)
    let mut s = t.to_int()
    if s > 2 {
      s = 2
    }
    let f = t - f79(s)
    joints[i] = @tmath.Vec4::new(f79(s), f79(s + 1), 0.0, 0.0)
    weights[i] = @tmath.Vec4::new(1.0 - f, f, 0.0, 0.0)
  }
  mesh.set_skin(joints, weights)
  mesh
}

///|
fn diff79(a : FixedArray[Byte], b : FixedArray[Byte]) -> Int {
  let mut n = 0
  let mut i = 0
  while i + 3 < a.length() {
    let d = (a[i].to_int() - b[i].to_int()).abs() +
      (a[i + 1].to_int() - b[i + 1].to_int()).abs() +
      (a[i + 2].to_int() - b[i + 2].to_int()).abs()
    if d > 24 {
      n = n + 1
    }
    i = i + 4
  }
  n
}

///|
fn pose79(scene : @t3d.Scene, bones : Array[@t3d.NodeId], t : Float) -> Unit {
  scene.set_transform(
    bones[0],
    @tmath.Transform::new(
      @tmath.Vec3::new(0.0, -2.0, 0.0),
      @tmath.Quat::identity(),
      @tmath.Vec3::one(),
    ),
  )
  for i = 1; i < bones.length(); i = i + 1 {
    let ang = @tmath.sin(t * 1.7 + f79(i) * 0.55) * 0.52
    scene.set_transform(
      bones[i],
      @tmath.Transform::new(
        @tmath.Vec3::new(0.0, 1.0, 0.0),
        @tmath.Quat::from_rotation_z(ang),
        @tmath.Vec3::one(),
      ),
    )
  }
}

///|
fn main {
  try {
    let opts = @exwin.Options::parse("3d/skinning")
    let show_win = opts.window
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("3d/skinning", validation=true, headless=!show_win),
    )
    let renderer = @t3d.Renderer3D::new(dev)
    let scene = @t3d.Scene::new()

    let mesh = renderer.upload_mesh(make_skinned_column())
    let bones : Array[@t3d.NodeId] = []
    let root = scene.create_node(
      transform=@tmath.Transform::new(
        @tmath.Vec3::new(0.0, -2.0, 0.0),
        @tmath.Quat::identity(),
        @tmath.Vec3::one(),
      ),
    )
    bones.push(root)
    let mut parent = root
    for i = 1; i < 4; i = i + 1 {
      let b = scene.create_node(
        parent=parent,
        transform=@tmath.Transform::new(
          @tmath.Vec3::new(0.0, 1.0, 0.0),
          @tmath.Quat::identity(),
          @tmath.Vec3::one(),
        ),
      )
      bones.push(b)
      parent = b
    }
    let inverse_bind : Array[@tmath.Mat4] = [
      @tmath.Mat4::from_translation(@tmath.Vec3::new(0.0, 2.0, 0.0)),
      @tmath.Mat4::from_translation(@tmath.Vec3::new(0.0, 1.0, 0.0)),
      @tmath.Mat4::identity(),
      @tmath.Mat4::from_translation(@tmath.Vec3::new(0.0, -1.0, 0.0)),
    ]
    let _ = renderer.create_skinned_node(
      scene,
      mesh,
      @t3d.MaterialDesc::pbr(
        @t3d.srgb(0.85, 0.35, 0.28),
        metallic=0.75,
        roughness=0.25,
      ),
      bones,
      inverse_bind,
    )

    let ground = renderer.upload_mesh(@tgeo.box(width=12.0, height=0.2, depth=12.0))
    let _ = renderer.create_pbr_node(
      scene,
      ground,
      @t3d.MaterialDesc::pbr(@t3d.srgb(0.26, 0.28, 0.32), roughness=0.8),
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, -2.05, 0.0)),
    )
    let sun = @tmath.Vec3::new(-0.45, 0.8, -0.4).normalize()
    let _sun = scene.create_node(
      transform=@tmath.Transform::new(
        @tmath.Vec3::zero(),
        @tmath.Quat::from_rotation_arc(@tmath.Vec3::neg_z(), sun),
        @tmath.Vec3::one(),
      ),
      payload=@t3d.NodePayload::Light(
        @t3d.Light::directional(
          @tmath.Vec3::new(1.0, 0.96, 0.9),
          2.2,
          shadow=@t3d.ShadowDesc::default(),
        ),
      ),
    )
    let _ambient = scene.create_node(
      payload=@t3d.NodePayload::Light(@t3d.Light::ambient(@tmath.Vec3::one(), 0.16)),
    )
    let env = @t3d.procedural_environment_cubemap(dev, sun, size=128, samples=32)
    renderer.set_environment(env, sun, intensity=0.8)

    let orbit = @t3d.OrbitCamera::new(
      target=@tmath.Vec3::new(0.0, -0.1, 0.0),
      distance=7.6,
      yaw=0.35,
      pitch=0.22,
    )
    let fov : Float = 2.0 * @tmath.atan((1.0 : Float) / (1.8 : Float))
    let cam = @t3d.Camera::perspective(fov, (800.0 : Float) / (600.0 : Float), near=0.1)
    let cam_node = scene.add_camera(cam, transform=orbit.transform())

    if !show_win {
      let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8Srgb)
      pose79(scene, bones, 0.0)
      renderer.render_offscreen( rt,scene, cam_node)
      let px0 = rt.readback()

      pose79(scene, bones, 1.0)
      renderer.render_offscreen( rt,scene, cam_node)
      let px1 = rt.readback()

      let diff = diff79(px0, px1)
      let mut lit = 0
      let mut i = 0
      while i + 3 < px1.length() {
        if px1[i].to_int() + px1[i + 1].to_int() + px1[i + 2].to_int() > 30 {
          lit = lit + 1
        }
        i = i + 4
      }
      opts.capture(800, 600, px1)
      let errs = dev.validation_errors()
      let stats = renderer.stats()
      println(
        "[3d/skinning] \{stats.summary()} skin_diff=\{diff} lit=\{lit} validation=\{errs}",
      )
      if errs == 0 && diff > 6000 && lit > 10000 && stats.shadow_passes >= 2 {
        println("[3d/skinning] OK — four-bone palette deforms the mesh on the GPU")
      } else {
        println(
          "[3d/skinning] FAIL — diff=\{diff} lit=\{lit} errs=\{errs}",
        )
      }
      rt.destroy()
    } else {
      let sc = @exwin_rhi.open(dev, opts)
      let mut quit = false
      let mut t : Float = 0.0
      while !sc.should_close() && !quit {
        for ev in sc.poll_events() {
          match ev {
            @tycho.Event::CloseRequested => quit = true
            @tycho.Event::KeyDown(k, _) => if k == @tycho.KeyCode::Escape {
              quit = true
            }
            _ => ()
          }
          if orbit.apply(ev) {
            scene.set_transform(cam_node.node(), orbit.transform())
          }
        }
        t = t + (1.0 : Float) / 60.0
        pose79(scene, bones, t)
        renderer.render_swapchain(sc, scene, cam_node)
      }
      sc.destroy()
    }

    let errs = dev.validation_errors()
    renderer.destroy()
    env.destroy()
    let leaks = dev.allocator_used_bytes()
    dev.destroy()
    if errs != 0 {
      println("[3d/skinning] validation errors: \{errs}")
    }
    if leaks != (0 : UInt64) {
      println("[3d/skinning] LEAK — \{leaks} bytes after destroy")
    }
  } catch {
    err => println("[3d/skinning] FAIL — \{err}")
  }
}
