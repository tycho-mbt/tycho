// 3d/iridescence-lamp — port of the three.js `webgl_loader_gltf_iridescence`
// example (github.com/mrdoob/three.js, snapshot `refs/three.js` 0.187.0).
//
// The reference scene is one designer lamp floating in front of the Venice
// sunset HDR: a gold shade, a chrome sphere and two iridescent glass films. It
// is the official showcase for KHR_materials_iridescence, and it runs on four
// engine capabilities this port had to add or complete:
//
//   * binary glTF (`parse_glb`): the model ships as a GLB container with its
//     textures in buffer views, not as a JSON document with data URIs;
//   * glTF metallic-roughness textures (G roughness, B metallic), which is what
//     makes the painted shade and the chrome read as metal;
//   * `KHR_materials_transmission` / `ior` / `iridescence` / `clearcoat` mapped
//     onto `MaterialDesc`, so the film thicknesses are the authored ones;
//   * an equirectangular HDR as both the background sky and the IBL source.
//
// The headless gate parses the GLB, renders the lamp against the sunset, then
// disables the film to prove the iridescence actually changes pixels.

///|
pub let asset_glb : String = "examples/assets/iridescence-lamp/IridescenceLamp.glb"

///|
pub let asset_hdr : String = "examples/assets/iridescence-lamp/venice_sunset_1k.hdr"

///|
fn lamp_f(i : Int) -> Float {
  Float::from_double(i.to_double())
}

///|
/// Direction of the brightest texel of an equirectangular HDR, i.e. the sun.
/// Scanning beats hard-coding a heading that depends on how the photographer
/// oriented the panorama.
fn hdr_sun(dir_image : @t3d.HdrImage) -> @tmath.Vec3 {
  let mut best : Float = -1.0
  let mut bu : Float = 0.5
  let mut bv : Float = 0.25
  let width = dir_image.width
  let height = dir_image.height
  for y = 0; y < height; y = y + 1 {
    for x = 0; x < width; x = x + 1 {
      let (r, g, b) = dir_image.pixel(x, y)
      let lum = r * 0.2126 + g * 0.7152 + b * 0.0722
      if lum > best {
        best = lum
        bu = (lamp_f(x) + 0.5) / lamp_f(width)
        bv = (lamp_f(y) + 0.5) / lamp_f(height)
      }
    }
  }
  // Inverse of `@t3d.equirect_uv`: u wraps around +Y, v is 0 at the zenith.
  let phi = (bu - 0.5) * @tmath.TAU
  let theta = bv * @tmath.PI
  let (sin_t, cos_t) = @tmath.sin_cos(theta)
  let (sin_p, cos_p) = @tmath.sin_cos(phi)
  @tmath.Vec3::new(sin_t * sin_p, cos_t, sin_t * cos_p)
}

///|
fn main {
  try {
    let opts = @exwin.Options::parse("3d/iridescence-lamp")
    let show_win = opts.window
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "3d/iridescence-lamp",
        validation=true,
        headless=!show_win,
      ),
    )
    let renderer = @t3d.Renderer3D::new(
      dev,
      desc=@t3d.RendererDesc::default().with_msaa(true),
    )
    let scene = @t3d.Scene::new()

    // ---- environment: the same Venice sunset is the sky and the IBL --------
    let hdr = match @t3d.decode_hdr(@image.read_file_bytes(asset_hdr)) {
      Some(img) => img
      None => {
        println("[3d/iridescence-lamp] FAIL — could not decode \{asset_hdr}")
        return
      }
    }
    let sun = hdr_sun(hdr)
    // 512^2 keeps the Venice facades sharp in the chrome sphere; the prefilter
    // chain still resolves the rough IBL mips the shade needs.
    let env = @t3d.equirect_environment_cubemap(dev, hdr, size=512, samples=128)
    renderer.set_environment(env, sun, intensity=1.0)

    // ---- the lamp: a binary glTF with textures in buffer views ------------
    let glb = @image.read_file_bytes(asset_glb)
    let gltf = @tgeo.parse_glb(glb)
    let model = @t3d.load_gltf_instance(renderer, scene, gltf)
    let mut textured = 0
    let mut map_materials = 0
    let mut transmissive = 0
    let mut iridescent = 0
    for m in gltf.materials {
      if m.base_color_tex >= 0 {
        textured = textured + 1
      }
      if m.metallic_roughness_tex >= 0 {
        map_materials = map_materials + 1
      }
      if m.transmission > 0.0 {
        transmissive = transmissive + 1
      }
      if m.iridescence > 0.0 {
        iridescent = iridescent + 1
      }
    }

    // ---- camera: the reference framing, a hair above the shade ------------
    let orbit = @t3d.OrbitCamera::new(
      target=@tmath.Vec3::new(0.0, 0.24, 0.0),
      distance=0.82,
      yaw=0.78,
      // Slightly below the target, like the reference: the camera looks up into
      // the shade, so the iridescent rim is visible.
      pitch=-0.14,
    )
    let fov : Float = @tmath.deg_to_rad(50.0)
    let cam = @t3d.Camera::perspective(
      fov,
      (800.0 : Float) / (600.0 : Float),
      near=0.05,
      far=20.0,
    )
    let cam_node = scene.add_camera(cam, transform=orbit.transform())

    if !show_win {
      let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8Srgb)
      renderer.render_offscreen(rt, scene, cam_node)
      let with_film = rt.readback()
      let st = renderer.stats()
      let mut lit = 0
      let mut bright = 0
      let mut warm = 0
      let mut i = 0
      while i + 3 < with_film.length() {
        let r = with_film[i].to_int()
        let g = with_film[i + 1].to_int()
        let b = with_film[i + 2].to_int()
        if r + g + b > 40 {
          lit = lit + 1
        }
        if r > 235 && g > 235 && b > 235 {
          bright = bright + 1
        }
        if r > 120 && r > b + 40 {
          warm = warm + 1
        }
        i = i + 4
      }

      // Turn every film off and prove the render changes: the authored
      // thickness tint must reach the frame.
      let films : Array[@t3d.MaterialHandle] = []
      let saved : Array[@t3d.MaterialDesc] = []
      for mi = 0; mi < gltf.materials.length(); mi = mi + 1 {
        if gltf.materials[mi].iridescence > 0.0 && mi < model.materials.length() {
          match renderer.material(model.materials[mi]) {
            Some(desc) => {
              saved.push(desc)
              films.push(model.materials[mi])
              renderer.update_material(model.materials[mi], desc.with_iridescence(0.0))
            }
            None => ()
          }
        }
      }
      let mut film_changed = 0
      let mut film_diff = 0
      if films.length() > 0 {
        renderer.render_offscreen(rt, scene, cam_node)
        let bare = rt.readback()
        let mut k = 0
        while k + 3 < with_film.length() {
          let d = (bare[k].to_int() - with_film[k].to_int()).abs() +
            (bare[k + 1].to_int() - with_film[k + 1].to_int()).abs() +
            (bare[k + 2].to_int() - with_film[k + 2].to_int()).abs()
          if d > 2 {
            film_changed = film_changed + 1
          }
          if d > film_diff {
            film_diff = d
          }
          k = k + 4
        }
        for fi = 0; fi < films.length(); fi = fi + 1 {
          renderer.update_material(films[fi], saved[fi])
        }
      }

      opts.capture(800, 600, with_film)
      let errs = dev.validation_errors()
      println(
        "[3d/iridescence-lamp] \{st.summary()} meshes=\{gltf.meshes.length()} images=\{gltf.images.length()} textured=\{textured} mr_maps=\{map_materials} transmissive=\{transmissive} iridescent=\{iridescent} roots=\{model.roots.length()} lit=\{lit} bright=\{bright} warm=\{warm} film_changed=\{film_changed} film_diff=\{film_diff} validation=\{errs}",
      )
      if errs == 0 &&
        gltf.meshes.length() == 3 &&
        gltf.images.length() == 3 &&
        textured == 3 &&
        map_materials == 3 &&
        transmissive >= 1 &&
        iridescent >= 2 &&
        lit > 400000 &&
        bright > 60 &&
        warm > 10000 &&
        film_changed > 500 {
        println(
          "[3d/iridescence-lamp] OK — GLB lamp + HDR sky, film tints \{film_changed} px",
        )
      } else {
        println(
          "[3d/iridescence-lamp] FAIL — textured=\{textured} maps=\{map_materials} transmissive=\{transmissive} iridescent=\{iridescent} lit=\{lit} bright=\{bright} warm=\{warm} film_changed=\{film_changed} errs=\{errs}",
        )
      }
      rt.destroy()
    } else {
      let sc = @exwin_rhi.open(dev, opts)
      let clock = @t3d.Clock::new()
      let mut yaw : Float = 0.78
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
        // The reference auto-rotates slowly; drag still wins while in use.
        let dt = clock.tick(
          Float::from_double(@tycho.Swapchain::time()),
        )
        yaw = yaw + dt * 0.18
        orbit.set_yaw(yaw)
        scene.set_transform(cam_node.node(), orbit.transform())
        renderer.render_swapchain(sc, scene, cam_node)
      }
      sc.destroy()
    }

    let errs = dev.validation_errors()
    renderer.destroy()
    env.destroy()
    let leaks = dev.allocator_used_bytes()
    dev.destroy()
    if leaks != (0 : UInt64) {
      println("[3d/iridescence-lamp] LEAK — \{leaks} bytes after destroy")
    }
    if errs != 0 {
      println("[3d/iridescence-lamp] validation errors: \{errs}")
    }
  } catch {
    err => println("[3d/iridescence-lamp] FAIL — \{err}")
  }
}
