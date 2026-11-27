// 3d/animation — TRS keyframe animation.
//
// Three cubes animate through translation, rotation and scale tracks. The
// headless run seeks to t=0 and t=1, checks the sampled transforms and asserts
// that the two frames differ, so the animation actually reaches the renderer.

///|
fn f76(i : Int) -> Float {
  Float::from_int(i)
}

///|
fn close76(a : Float, b : Float, eps : Float) -> Bool {
  let d = if a > b { a - b } else { b - a }
  d <= eps
}

///|
fn diff76(a : FixedArray[Byte], b : FixedArray[Byte]) -> Int {
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
fn main {
  try {
    let show_win = @tycho.want_window()
    let shot = @tycho.screenshot_path()
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("3d/animation", validation=true, headless=!show_win),
    )
    let renderer = @t3d.Renderer3D::new(dev)
    let scene = @t3d.Scene::new()

    let cube = renderer.upload_mesh(@tgeo.box(width=1.0, height=1.0, depth=1.0))
    let ground = renderer.upload_mesh(@tgeo.box(width=20.0, height=0.2, depth=20.0))
    let _ = renderer.create_pbr_node(
      scene,
      ground,
      @t3d.MaterialDesc::pbr(@t3d.srgb(0.26, 0.28, 0.33), roughness=0.8),
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, -0.95, 0.0)),
    )

    // Bouncing cube.
    let bouncer = scene.create_node(
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(-2.6, 0.5, 0.0)),
      payload=@t3d.NodePayload::Mesh(
        @t3d.MeshInstance::new(
          cube,
          renderer.create_material(
            @t3d.MaterialDesc::pbr(@t3d.srgb(0.9, 0.35, 0.25), roughness=0.35),
          ),
        ),
      ),
    )
    scene.set_local_bounds(bouncer, renderer.mesh_bounds(cube))

    // Spinning cube.
    let spinner = scene.create_node(
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, 0.5, 0.0)),
      payload=@t3d.NodePayload::Mesh(
        @t3d.MeshInstance::new(
          cube,
          renderer.create_material(
            @t3d.MaterialDesc::pbr(
              @t3d.srgb(0.3, 0.7, 0.95),
              metallic=0.6,
              roughness=0.25,
            ),
          ),
        ),
      ),
    )
    scene.set_local_bounds(spinner, renderer.mesh_bounds(cube))

    // Pulsing cube.
    let pulser = scene.create_node(
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(2.6, 0.5, 0.0)),
      payload=@t3d.NodePayload::Mesh(
        @t3d.MeshInstance::new(
          cube,
          renderer.create_material(
            @t3d.MaterialDesc::pbr(@t3d.srgb(0.95, 0.8, 0.3), roughness=0.4),
          ),
        ),
      ),
    )
    scene.set_local_bounds(pulser, renderer.mesh_bounds(cube))

    let clip = @t3d.AnimationClip::new(
      "demo",
      [
        @t3d.AnimationChannel::new(
          bouncer,
          @t3d.TransformTrack::new(
            translation=Some(
              @t3d.Vec3Track::new(
                [0.0, 0.5, 1.0, 1.5, 2.0],
                [
                  @tmath.Vec3::new(-2.6, 0.5, 0.0),
                  @tmath.Vec3::new(-2.6, 1.6, 0.0),
                  @tmath.Vec3::new(-2.6, 0.5, 0.0),
                  @tmath.Vec3::new(-2.6, 1.6, 0.0),
                  @tmath.Vec3::new(-2.6, 0.5, 0.0),
                ],
              ),
            ),
          ),
        ),
        @t3d.AnimationChannel::new(
          spinner,
          @t3d.TransformTrack::new(
            rotation=Some(
              @t3d.QuatTrack::new(
                [0.0, 0.5, 1.0, 1.5, 2.0],
                [
                  @tmath.Quat::identity(),
                  @tmath.Quat::from_rotation_y(@tmath.PI * 0.25),
                  @tmath.Quat::from_rotation_y(@tmath.PI * 0.5),
                  @tmath.Quat::from_rotation_y(@tmath.PI * 0.75),
                  @tmath.Quat::from_rotation_y(@tmath.PI),
                ],
              ),
            ),
          ),
        ),
        @t3d.AnimationChannel::new(
          pulser,
          @t3d.TransformTrack::new(
            scale=Some(
              @t3d.Vec3Track::new(
                [0.0, 0.5, 1.0, 1.5, 2.0],
                [
                  @tmath.Vec3::one(),
                  @tmath.Vec3::new(1.05, 1.6, 1.05),
                  @tmath.Vec3::one(),
                  @tmath.Vec3::new(1.6, 1.05, 1.6),
                  @tmath.Vec3::one(),
                ],
              ),
            ),
          ),
        ),
      ],
    )
    let player = @t3d.AnimationPlayer::new(clip)

    let sun = @tmath.Vec3::new(-0.5, 0.8, -0.4).normalize()
    let _sun = scene.create_node(
      transform=@tmath.Transform::new(
        @tmath.Vec3::zero(),
        @tmath.Quat::from_rotation_arc(@tmath.Vec3::neg_z(), sun),
        @tmath.Vec3::one(),
      ),
      payload=@t3d.NodePayload::Light(
        @t3d.Light::directional(
          @tmath.Vec3::new(1.0, 0.96, 0.9),
          2.0,
          shadow=Some(@t3d.ShadowDesc::default()),
        ),
      ),
    )
    let _ambient = scene.create_node(
      payload=@t3d.NodePayload::Light(@t3d.Light::ambient(@tmath.Vec3::one(), 0.15)),
    )
    let env = @t3d.procedural_environment_cubemap(dev, sun, size=128, samples=32)
    renderer.set_environment(env, sun, intensity=0.7)

    let orbit = @t3d.OrbitCamera::new(
      target=@tmath.Vec3::new(0.0, 0.8, 0.0),
      distance=10.5,
      yaw=0.28,
      pitch=0.34,
    )
    let fov : Float = 2.0 * @tmath.atan((1.0 : Float) / (1.8 : Float))
    let cam = @t3d.Camera::perspective(fov, (800.0 : Float) / (600.0 : Float), near=0.1)
    let cam_node = scene.create_node(
      transform=orbit.transform(),
      payload=@t3d.NodePayload::Camera(cam),
    )

    if !show_win {
      let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8Srgb)
      player.seek(0.0)
      player.apply(scene)
      renderer.render_offscreen(scene, cam_node, rt)
      let px0 = rt.readback()

      player.seek(0.5)
      player.apply(scene)
      renderer.render_offscreen(scene, cam_node, rt)
      let px1 = rt.readback()

      // Sampled transforms at t=1 (the mid keyframe of every track).
      let b = scene.transform(bouncer)
      let s = scene.transform(pulser)
      let spin_axis = scene.transform(spinner).rotation.mul_vec3(
        @tmath.Vec3::new(0.0, 0.0, 1.0),
      )
      let anim_ok = close76(b.translation.y, 1.6, 1.0e-3) &&
        close76(s.scale.y, 1.6, 1.0e-3) &&
        close76(spin_axis.x, 0.7071, 1.0e-2)
      let frame_diff = diff76(px0, px1)
      let mut lit = 0
      let mut i = 0
      while i + 3 < px1.length() {
        if px1[i].to_int() + px1[i + 1].to_int() + px1[i + 2].to_int() > 30 {
          lit = lit + 1
        }
        i = i + 4
      }
      if shot != "" {
        let _ = @tycho.save_png(shot, 800, 600, px1)
      }
      let errs = dev.validation_errors()
      println(
        "[3d/animation] \{renderer.stats().summary()} anim=\{anim_ok} frame_diff=\{frame_diff} lit=\{lit} t=\{player.time()} validation=\{errs}",
      )
      if errs == 0 && anim_ok && frame_diff > 8000 && lit > 10000 {
        println("[3d/animation] OK — TRS keyframes drive the scene graph")
      } else {
        println(
          "[3d/animation] FAIL — anim=\{anim_ok} diff=\{frame_diff} lit=\{lit} errs=\{errs}",
        )
      }
      rt.destroy()
    } else {
      let sc = dev.create_swapchain("3d/animation", 800, 600)
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
        player.update(scene, (1.0 : Float) / 60.0)
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
      println("[3d/animation] validation errors: \{errs}")
    }
    if leaks != (0 : UInt64) {
      println("[3d/animation] LEAK — \{leaks} bytes after destroy")
    }
  } catch {
    err => println("[3d/animation] FAIL — \{err}")
  }
}
