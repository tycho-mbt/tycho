// 3d/gltf-animation — glTF animation → AnimationClip.
//
// The document animates a node's rotation through three quaternion keys. The
// example converts it with load_gltf_animations, plays it, checks the sampled
// rotation and asserts that t=0 and t=1 render differently.

///|
fn gltf_json78() -> String {
  "{\"asset\":{\"version\":\"2.0\"},\"scene\":0,\"scenes\":[{\"nodes\":[0]}],\"nodes\":[{\"mesh\":0,\"name\":\"spin\"}],\"meshes\":[{\"name\":\"box\",\"primitives\":[{\"attributes\":{\"POSITION\":0,\"NORMAL\":1,\"TEXCOORD_0\":2},\"indices\":3,\"material\":0}]}],\"materials\":[{\"name\":\"blue\",\"pbrMetallicRoughness\":{\"baseColorFactor\":[0.25,0.55,0.95,1.0],\"metallicFactor\":0.6,\"roughnessFactor\":0.3}}],\"accessors\":[{\"bufferView\":0,\"componentType\":5126,\"count\":24,\"type\":\"VEC3\",\"min\":[-0.85,-0.85,-0.85],\"max\":[0.85,0.85,0.85]},{\"bufferView\":1,\"componentType\":5126,\"count\":24,\"type\":\"VEC3\"},{\"bufferView\":2,\"componentType\":5126,\"count\":24,\"type\":\"VEC2\"},{\"bufferView\":3,\"componentType\":5123,\"count\":36,\"type\":\"SCALAR\"},{\"bufferView\":4,\"componentType\":5126,\"count\":3,\"type\":\"SCALAR\"},{\"bufferView\":5,\"componentType\":5126,\"count\":3,\"type\":\"VEC4\"}],\"bufferViews\":[{\"buffer\":0,\"byteOffset\":0,\"byteLength\":288},{\"buffer\":0,\"byteOffset\":288,\"byteLength\":288},{\"buffer\":0,\"byteOffset\":576,\"byteLength\":192},{\"buffer\":0,\"byteOffset\":768,\"byteLength\":72},{\"buffer\":0,\"byteOffset\":840,\"byteLength\":12},{\"buffer\":0,\"byteOffset\":852,\"byteLength\":48}],\"buffers\":[{\"byteLength\":900,\"uri\":\"data:application/octet-stream;base64,mplZP5qZWb+amVk/mplZP5qZWT+amVk/mplZv5qZWT+amVk/mplZv5qZWb+amVk/mplZv5qZWb+amVm/mplZv5qZWT+amVm/mplZP5qZWT+amVm/mplZP5qZWb+amVm/mplZP5qZWb+amVm/mplZP5qZWT+amVm/mplZP5qZWT+amVk/mplZP5qZWb+amVk/mplZv5qZWb+amVk/mplZv5qZWT+amVk/mplZv5qZWT+amVm/mplZv5qZWb+amVm/mplZP5qZWT+amVk/mplZP5qZWT+amVm/mplZv5qZWT+amVm/mplZv5qZWT+amVk/mplZv5qZWb+amVk/mplZv5qZWb+amVm/mplZP5qZWb+amVm/mplZP5qZWb+amVk/AAAAAAAAAAAAAIA/AAAAAAAAAAAAAIA/AAAAAAAAAAAAAIA/AAAAAAAAAAAAAIA/AAAAAAAAAAAAAIC/AAAAAAAAAAAAAIC/AAAAAAAAAAAAAIC/AAAAAAAAAAAAAIC/AACAPwAAAAAAAAAAAACAPwAAAAAAAAAAAACAPwAAAAAAAAAAAACAPwAAAAAAAAAAAACAvwAAAAAAAAAAAACAvwAAAAAAAAAAAACAvwAAAAAAAAAAAACAvwAAAAAAAAAAAAAAAAAAgD8AAAAAAAAAAAAAgD8AAAAAAAAAAAAAgD8AAAAAAAAAAAAAgD8AAAAAAAAAAAAAgL8AAAAAAAAAAAAAgL8AAAAAAAAAAAAAgL8AAAAAAAAAAAAAgL8AAAAAAAAAAAAAAAAAAAAAAACAPwAAgD8AAIA/AACAPwAAAAAAAAAAAAAAAAAAAAAAAIA/AACAPwAAgD8AAIA/AAAAAAAAAAAAAAAAAAAAAAAAgD8AAIA/AACAPwAAgD8AAAAAAAAAAAAAAAAAAAAAAACAPwAAgD8AAIA/AACAPwAAAAAAAAAAAAAAAAAAAAAAAIA/AACAPwAAgD8AAIA/AAAAAAAAAAAAAAAAAAAAAAAAgD8AAIA/AACAPwAAgD8AAAAAAAABAAIAAAACAAMABAAFAAYABAAGAAcACAAJAAoACAAKAAsADAANAA4ADAAOAA8AEAARABIAEAASABMAFAAVABYAFAAWABcAAAAAAAAAgD8AAABAAAAAAAAAAAAAAAAAAACAPwAAAAAV78M+AAAAAF6DbD8AAAAA8wQ1PwAAAADzBDU/\"}],\"animations\":[{\"name\":\"spin\",\"samplers\":[{\"input\":4,\"output\":5,\"interpolation\":\"LINEAR\"}],\"channels\":[{\"sampler\":0,\"target\":{\"node\":0,\"path\":\"rotation\"}}]}]}"
}

///|
fn close78(a : Float, b : Float, eps : Float) -> Bool {
  let d = if a > b { a - b } else { b - a }
  d <= eps
}

///|
fn diff78(a : FixedArray[Byte], b : FixedArray[Byte]) -> Int {
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
    let opts = @exwin.Options::parse("3d/gltf-animation")
    let show_win = opts.window
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("3d/gltf-animation", validation=true, headless=!show_win),
    )
    let renderer = @t3d.Renderer3D::new(dev)
    let scene = @t3d.Scene::new()

    let gltf = @tgeo.parse_gltf(gltf_json78())
    let node_map = @t3d.load_gltf_with_nodes(renderer, scene, gltf)
    let clips = @t3d.load_gltf_animations(gltf, node_map)
    let clip_ok = clips.length() == 1 && clips[0].channels.length() == 1
    let model = if node_map.length() > 0 {
      match node_map[0] {
        Some(id) => id
        None => fail("glTF node 0 was not instantiated")
      }
    } else {
      fail("glTF has no nodes")
    }
    let player = @t3d.AnimationPlayer::new(
      if clips.length() > 0 {
        clips[0]
      } else {
        @t3d.AnimationClip::new("empty", [])
      },
    )

    let ground = renderer.upload_mesh(@tgeo.box(width=10.0, height=0.2, depth=10.0))
    let _ = renderer.create_pbr_node(
      scene,
      ground,
      @t3d.MaterialDesc::pbr(@t3d.srgb(0.28, 0.30, 0.34), roughness=0.8),
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, -0.75, 0.0)),
    )
    let sun = @tmath.Vec3::new(-0.4, 0.8, -0.35).normalize()
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
          shadow=Some(@t3d.ShadowDesc::default()),
        ),
      ),
    )
    let _ambient = scene.create_node(
      payload=@t3d.NodePayload::Light(@t3d.Light::ambient(@tmath.Vec3::one(), 0.15)),
    )
    let env = @t3d.procedural_environment_cubemap(dev, sun, size=128, samples=32)
    renderer.set_environment(env, sun, intensity=0.8)

    let orbit = @t3d.OrbitCamera::new(
      target=@tmath.Vec3::new(0.0, 0.1, 0.0),
      distance=4.6,
      yaw=0.35,
      pitch=0.30,
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

      player.seek(1.0)
      player.apply(scene)
      let spin_axis = scene.transform(model).rotation.mul_vec3(
        @tmath.Vec3::new(0.0, 0.0, 1.0),
      )
      let anim_ok = clip_ok && close78(spin_axis.x, 0.7071, 1.0e-2)
      renderer.render_offscreen(scene, cam_node, rt)
      let px1 = rt.readback()

      let frame_diff = diff78(px0, px1)
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
      println(
        "[3d/gltf-animation] \{renderer.stats().summary()} clips=\{clips.length()} anim=\{anim_ok} frame_diff=\{frame_diff} lit=\{lit} validation=\{errs}",
      )
      if errs == 0 && anim_ok && frame_diff > 5000 && lit > 10000 {
        println("[3d/gltf-animation] OK — glTF animation drives the scene")
      } else {
        println(
          "[3d/gltf-animation] FAIL — anim=\{anim_ok} diff=\{frame_diff} lit=\{lit} errs=\{errs}",
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
      println("[3d/gltf-animation] validation errors: \{errs}")
    }
    if leaks != (0 : UInt64) {
      println("[3d/gltf-animation] LEAK — \{leaks} bytes after destroy")
    }
  } catch {
    err => println("[3d/gltf-animation] FAIL — \{err}")
  }
}
