// 3d/gltf-viewer — glTF viewer with embedded textures.
//
// A self-contained glTF document (base64 buffer plus two PNG data URIs) is
// parsed by @tgeo, mapped by @t3d (decoding the images through the RHI), and
// rendered with a lit environment. The checker albedo must be visible, which
// proves the texture path end to end.

///|
fn gltf_json77() -> String {
  "{\"asset\":{\"version\":\"2.0\"},\"scene\":0,\"scenes\":[{\"nodes\":[0]}],\"nodes\":[{\"mesh\":0,\"name\":\"box\"}],\"meshes\":[{\"name\":\"box\",\"primitives\":[{\"attributes\":{\"POSITION\":0,\"NORMAL\":1,\"TEXCOORD_0\":2},\"indices\":3,\"material\":0}]}],\"accessors\":[{\"bufferView\":0,\"componentType\":5126,\"count\":24,\"type\":\"VEC3\",\"min\":[-0.85,-0.85,-0.85],\"max\":[0.85,0.85,0.85]},{\"bufferView\":1,\"componentType\":5126,\"count\":24,\"type\":\"VEC3\"},{\"bufferView\":2,\"componentType\":5126,\"count\":24,\"type\":\"VEC2\"},{\"bufferView\":3,\"componentType\":5123,\"count\":36,\"type\":\"SCALAR\"}],\"bufferViews\":[{\"buffer\":0,\"byteOffset\":0,\"byteLength\":288},{\"buffer\":0,\"byteOffset\":288,\"byteLength\":288},{\"buffer\":0,\"byteOffset\":576,\"byteLength\":192},{\"buffer\":0,\"byteOffset\":768,\"byteLength\":72}],\"buffers\":[{\"byteLength\":840,\"uri\":\"data:application/octet-stream;base64,mplZP5qZWb+amVk/mplZP5qZWT+amVk/mplZv5qZWT+amVk/mplZv5qZWb+amVk/mplZv5qZWb+amVm/mplZv5qZWT+amVm/mplZP5qZWT+amVm/mplZP5qZWb+amVm/mplZP5qZWb+amVm/mplZP5qZWT+amVm/mplZP5qZWT+amVk/mplZP5qZWb+amVk/mplZv5qZWb+amVk/mplZv5qZWT+amVk/mplZv5qZWT+amVm/mplZv5qZWb+amVm/mplZP5qZWT+amVk/mplZP5qZWT+amVm/mplZv5qZWT+amVm/mplZv5qZWT+amVk/mplZv5qZWb+amVk/mplZv5qZWb+amVm/mplZP5qZWb+amVm/mplZP5qZWb+amVk/AAAAAAAAAAAAAIA/AAAAAAAAAAAAAIA/AAAAAAAAAAAAAIA/AAAAAAAAAAAAAIA/AAAAAAAAAAAAAIC/AAAAAAAAAAAAAIC/AAAAAAAAAAAAAIC/AAAAAAAAAAAAAIC/AACAPwAAAAAAAAAAAACAPwAAAAAAAAAAAACAPwAAAAAAAAAAAACAPwAAAAAAAAAAAACAvwAAAAAAAAAAAACAvwAAAAAAAAAAAACAvwAAAAAAAAAAAACAvwAAAAAAAAAAAAAAAAAAgD8AAAAAAAAAAAAAgD8AAAAAAAAAAAAAgD8AAAAAAAAAAAAAgD8AAAAAAAAAAAAAgL8AAAAAAAAAAAAAgL8AAAAAAAAAAAAAgL8AAAAAAAAAAAAAgL8AAAAAAAAAAAAAAAAAAAAAAACAPwAAgD8AAIA/AACAPwAAAAAAAAAAAAAAAAAAAAAAAIA/AACAPwAAgD8AAIA/AAAAAAAAAAAAAAAAAAAAAAAAgD8AAIA/AACAPwAAgD8AAAAAAAAAAAAAAAAAAAAAAACAPwAAgD8AAIA/AACAPwAAAAAAAAAAAAAAAAAAAAAAAIA/AACAPwAAgD8AAIA/AAAAAAAAAAAAAAAAAAAAAAAAgD8AAIA/AACAPwAAgD8AAAAAAAABAAIAAAACAAMABAAFAAYABAAGAAcACAAJAAoACAAKAAsADAANAA4ADAAOAA8AEAARABIAEAASABMAFAAVABYAFAAWABcA\"}],\"images\":[{\"uri\":\"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAHklEQVR42mN4Pc3mPzI2D1iFghnooABdAF0DHRQAABKHnYGxRhQPAAAAAElFTkSuQmCC\"},{\"uri\":\"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAJElEQVR42mNoafn1H4RroBidz0BYQQ1QAIhroBidT4SCgXcDAAXmvkGebZtRAAAAAElFTkSuQmCC\"}],\"textures\":[{\"source\":0},{\"source\":1}],\"materials\":[{\"name\":\"checker\",\"pbrMetallicRoughness\":{\"baseColorFactor\":[1.0,1.0,1.0,1.0],\"metallicFactor\":0.15,\"roughnessFactor\":0.45,\"baseColorTexture\":{\"index\":0}},\"normalTexture\":{\"index\":1}}]}"
}

///|
fn f77(i : Int) -> Float {
  Float::from_int(i)
}

///|
fn main {
  try {
    let opts = @exwin.Options::parse("3d/gltf-viewer")
    let show_win = opts.window
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("3d/gltf-viewer", validation=true, headless=!show_win),
    )
    let renderer = @t3d.Renderer3D::new(dev)
    let scene = @t3d.Scene::new()

    let gltf = @tgeo.parse_gltf(gltf_json77())
    let image_bytes = if gltf.images.length() > 0 { gltf.images[0].length() } else { 0 }
    let textured = if gltf.materials.length() > 0 {
      gltf.materials[0].base_color_tex >= 0
    } else {
      false
    }
    let nodes = @t3d.load_gltf(renderer, scene, gltf)
    let model = if nodes.length() > 0 {
      nodes[0]
    } else {
      fail("glTF produced no nodes")
    }
    scene.set_transform(
      model,
      @tmath.Transform::new(
        @tmath.Vec3::new(0.0, 0.3, 0.0),
        @tmath.Quat::from_rotation_y(@tmath.PI * 0.25),
        @tmath.Vec3::one(),
      ),
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
          shadow=@t3d.ShadowDesc::default(),
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
    let cam_node = scene.add_camera(cam, transform=orbit.transform())

    if !show_win {
      let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8Srgb)
      renderer.render_offscreen( rt,scene, cam_node)
      let px = rt.readback()
      let mut lit = 0
      let mut warm = 0
      let mut cool = 0
      let mut i = 0
      while i + 3 < px.length() {
        let r = px[i].to_int()
        let g = px[i + 1].to_int()
        let b = px[i + 2].to_int()
        if r + g + b > 30 {
          lit = lit + 1
        }
        if r > 150 && g > 90 && b < 100 {
          warm = warm + 1
        }
        if b > 120 && b > r + 30 {
          cool = cool + 1
        }
        i = i + 4
      }
      opts.capture(800, 600, px)
      let errs = dev.validation_errors()
      println(
        "[3d/gltf-viewer] \{renderer.stats().summary()} image_bytes=\{image_bytes} textured=\{textured} warm=\{warm} cool=\{cool} lit=\{lit} validation=\{errs}",
      )
      if errs == 0 && textured && image_bytes > 50 && warm > 300 && cool > 200 && lit > 10000 {
        println("[3d/gltf-viewer] OK — embedded glTF textures decode and render")
      } else {
        println(
          "[3d/gltf-viewer] FAIL — textured=\{textured} image=\{image_bytes} warm=\{warm} cool=\{cool} errs=\{errs}",
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
    env.destroy()
    let leaks = dev.allocator_used_bytes()
    dev.destroy()
    if errs != 0 {
      println("[3d/gltf-viewer] validation errors: \{errs}")
    }
    if leaks != (0 : UInt64) {
      println("[3d/gltf-viewer] LEAK — \{leaks} bytes after destroy")
    }
  } catch {
    err => println("[3d/gltf-viewer] FAIL — \{err}")
  }
}
