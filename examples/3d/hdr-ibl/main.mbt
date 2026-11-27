// 3d/hdr-ibl — HDR equirectangular environment (M2 IBL).
//
// A synthetic Radiance HDR sky (sun peak ~60) is written as RGBE, decoded back,
// converted to a cubemap and GGX-prefiltered into an RGBA16F mip chain. The
// scene renders once from that HDR chain and once from an LDR-clipped copy;
// the extra sun energy must survive as a measurably brighter specular/bloom
// response.

///|
fn f73(i : Int) -> Float {
  Float::from_int(i)
}

///|
fn soft_spot73(dir : @tmath.Vec3, centre : @tmath.Vec3) -> Float {
  let d = dir.dot(centre)
  if d < 0.86 {
    0.0
  } else {
    let t = (d - 0.86) / 0.14
    t * t
  }
}

///|
fn sky73(
  dir : @tmath.Vec3,
  sun_dir : @tmath.Vec3,
) -> (Float, Float, Float) {
  let t : Float = if dir.y > 0.0 { dir.y } else { 0.0 }
  let r : Float = 0.03 + (0.42 - 0.03) * t
  let g : Float = 0.07 + (0.50 - 0.07) * t
  let b : Float = 0.22 + (0.82 - 0.22) * t
  // Warm horizon band, in linear light.
  let horizon : Float = if dir.y > 0.0 && dir.y < 0.22 {
    (1.0 - dir.y * (1.0 / 0.22)) * 0.55
  } else if dir.y <= 0.0 && dir.y > -0.15 {
    (1.0 + dir.y * (1.0 / 0.15)) * 0.12
  } else {
    0.0
  }
  let ground : Float = if dir.y < 0.0 { 0.04 } else { 0.0 }
  // Two soft studio panels give the specular roughness ladder some structure.
  let p1 = soft_spot73(dir, @tmath.Vec3::new(-0.55, 0.55, -0.50).normalize())
  let p2 = soft_spot73(dir, @tmath.Vec3::new(0.80, 0.30, 0.35).normalize())
  let sd = dir.dot(sun_dir)
  let sun : Float = if sd > 0.998 {
    60.0
  } else if sd > 0.99 {
    5.0
  } else if sd > 0.96 {
    0.6
  } else {
    0.0
  }
  let base : Float = 0.30
  let rr : Float = (r + horizon * 0.9 + ground) * base + sun + p1 * 9.0 + p2 * 3.0
  let gg : Float = (g + horizon * 0.55 + ground) * base + sun * 0.94 + p1 * 9.0 + p2 * 3.0
  let bb : Float = (b + horizon * 0.25 + ground) * base + sun * 0.82 + p1 * 9.5 + p2 * 3.4
  (rr, gg, bb)
}

///|
fn make_equirect73(
  sun_dir : @tmath.Vec3,
  w : Int,
  h : Int,
) -> @t3d.HdrImage {
  let img = @t3d.HdrImage::new(w, h)
  let fw = f73(w)
  let fh = f73(h)
  for y = 0; y < h; y = y + 1 {
    let v = (f73(y) + 0.5) / fh
    let phi = v * @tmath.PI
    let cy = @tmath.cos(phi)
    let sy = @tmath.sin(phi)
    for x = 0; x < w; x = x + 1 {
      let u = (f73(x) + 0.5) / fw
      let theta = (u - 0.5) * 2.0 * @tmath.PI
      let dir = @tmath.Vec3::new(sy * @tmath.sin(theta), cy, sy * @tmath.cos(theta))
      let (r, g, b) = sky73(dir, sun_dir)
      img.set_pixel(x, y, r, g, b)
    }
  }
  img
}

///|
fn clip_ldr73(img : @t3d.HdrImage) -> @t3d.HdrImage {
  let out = @t3d.HdrImage::new(img.width, img.height)
  for i = 0; i < img.width * img.height; i = i + 1 {
    out.rgb[i * 3] = fmin1(img.rgb[i * 3])
    out.rgb[i * 3 + 1] = fmin1(img.rgb[i * 3 + 1])
    out.rgb[i * 3 + 2] = fmin1(img.rgb[i * 3 + 2])
  }
  out
}

///|
fn fmin1(v : Float) -> Float {
  if v > 1.0 {
    1.0
  } else {
    v
  }
}

///|
fn max_channel73(img : @t3d.HdrImage) -> Float {
  let mut m : Float = 0.0
  for i = 0; i < img.width * img.height * 3; i = i + 1 {
    if img.rgb[i] > m {
      m = img.rgb[i]
    }
  }
  m
}

///|
fn diff73(a : FixedArray[Byte], b : FixedArray[Byte]) -> Int {
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
fn hot_pixels73(px : FixedArray[Byte]) -> Int {
  let mut n = 0
  let mut i = 0
  while i + 3 < px.length() {
    if px[i].to_int() > 250 && px[i + 1].to_int() > 250 && px[i + 2].to_int() > 245 {
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
      @tycho.DeviceDesc::new("3d/hdr-ibl", validation=true, headless=!show_win),
    )
    let renderer = @t3d.Renderer3D::new(dev)
    let scene = @t3d.Scene::new()

    let sun = @tmath.Vec3::new(-0.5, 0.45, -0.75).normalize()
    let source = make_equirect73(sun, 512, 256)
    let encoded = @t3d.encode_hdr(source)
    let decoded = match @t3d.decode_hdr(encoded) {
      Some(img) => img
      None => fail("HDR decode failed")
    }
    let peak = max_channel73(decoded)

    let hdr_env = @t3d.equirect_environment_cubemap(dev, decoded, size=128, samples=64)
    let ldr_env = @t3d.equirect_environment_cubemap(
      dev,
      clip_ldr73(decoded),
      size=128,
      samples=64,
    )
    renderer.set_environment(hdr_env, sun)

    let _sun_node = scene.create_node(
      transform=@tmath.Transform::new(
        @tmath.Vec3::zero(),
        @tmath.Quat::from_rotation_arc(@tmath.Vec3::neg_z(), sun),
        @tmath.Vec3::one(),
      ),
      payload=@t3d.NodePayload::Light(
        @t3d.Light::directional(
          @tmath.Vec3::new(1.0, 0.94, 0.86),
          1.4,
          shadow=Some(@t3d.ShadowDesc::default()),
        ),
      ),
    )
    let _ambient = scene.create_node(
      payload=@t3d.NodePayload::Light(@t3d.Light::ambient(@tmath.Vec3::one(), 0.05)),
    )

    let ground_mesh = renderer.upload_mesh(@tgeo.box(width=22.0, height=0.2, depth=22.0))
    let _ground = renderer.create_pbr_node(
      scene,
      ground_mesh,
      @t3d.MaterialDesc::pbr(@t3d.srgb(0.24, 0.26, 0.30), roughness=0.75),
      transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, -0.95, 0.0)),
    )
    let sphere_mesh = renderer.upload_mesh(
      @tgeo.sphere(radius=0.78, width_segments=48, height_segments=24),
    )
    let roughs : Array[Float] = [0.05, 0.2, 0.4, 0.65, 0.9]
    for i = 0; i < 5; i = i + 1 {
      let _ = renderer.create_pbr_node(
        scene,
        sphere_mesh,
        @t3d.MaterialDesc::pbr(
          @t3d.srgb(0.95, 0.95, 0.97),
          metallic=1.0,
          roughness=roughs[i],
        ),
        transform=@tmath.Transform::from_translation(
          @tmath.Vec3::new(-3.2 + f73(i) * 1.6, -0.1, 0.0),
        ),
      )
    }

    let orbit = @t3d.OrbitCamera::new(
      target=@tmath.Vec3::new(0.0, 0.1, 0.0),
      distance=9.5,
      yaw=0.32,
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
      renderer.render_offscreen(scene, cam_node, rt)
      let hdr_px = rt.readback()
      renderer.set_environment(ldr_env, sun)
      renderer.render_offscreen(scene, cam_node, rt)
      let ldr_px = rt.readback()
      renderer.set_environment(hdr_env, sun)

      let energy_diff = diff73(hdr_px, ldr_px)
      let hot_hdr = hot_pixels73(hdr_px)
      let hot_ldr = hot_pixels73(ldr_px)
      let mut lit = 0
      let mut i = 0
      while i + 3 < hdr_px.length() {
        if hdr_px[i].to_int() + hdr_px[i + 1].to_int() + hdr_px[i + 2].to_int() > 30 {
          lit = lit + 1
        }
        i = i + 4
      }
      if shot != "" {
        let _ = @tycho.save_png(shot, 800, 600, hdr_px)
      }
      let errs = dev.validation_errors()
      println(
        "[3d/hdr-ibl] \{renderer.stats().summary()} peak=\{peak} energy_diff=\{energy_diff} hot=\{hot_hdr}/\{hot_ldr} lit=\{lit} validation=\{errs}",
      )
      let ok = errs == 0 &&
        peak > 20.0 &&
        energy_diff > 15000 &&
        hot_hdr > hot_ldr &&
        lit > 10000
      if ok {
        println("[3d/hdr-ibl] OK — RGBE HDR equirect keeps sun energy through the PMREM chain")
      } else {
        println(
          "[3d/hdr-ibl] FAIL — peak=\{peak} diff=\{energy_diff} hot=\{hot_hdr}/\{hot_ldr} lit=\{lit} errs=\{errs}",
        )
      }
      rt.destroy()
    } else {
      let sc = dev.create_swapchain("3d/hdr-ibl", 800, 600)
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
    hdr_env.destroy()
    ldr_env.destroy()
    let leaks = dev.allocator_used_bytes()
    dev.destroy()
    if errs != 0 {
      println("[3d/hdr-ibl] validation errors: \{errs}")
    }
    if leaks != (0 : UInt64) {
      println("[3d/hdr-ibl] LEAK — \{leaks} bytes after destroy")
    }
  } catch {
    err => println("[3d/hdr-ibl] FAIL — \{err}")
  }
}
