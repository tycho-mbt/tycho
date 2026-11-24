// Example 42 — Multiple Render Targets (MRT) G-Buffer + Deferred Lighting Composite
// using pure-MoonBit @tycho:
//   Pass 1: Offscreen MRT (albedo RGBA8 + world normal RGBA8 + Depth32F) timed via TimestampPool,
//           auto-reflected via PipelineDesc::from_spirv (3 vertex inputs, 64B push constant, 2 color targets).
//   Pass 2: Fullscreen deferred directional lighting sampling both G-Buffer textures to swapchain.

///|
fn sin_cos_approx(theta : Float) -> (Float, Float) {
  let pi : Double = 3.141592653589793
  let two_pi : Double = 6.283185307179586
  let mut x = theta.to_double() % two_pi
  if x > pi {
    x = x - two_pi
  } else if x < -pi {
    x = x + two_pi
  }
  let mut cos_sign : Double = 1.0
  let half_pi : Double = 1.5707963267948966
  let mut sx = x
  if sx > half_pi {
    sx = pi - sx
    cos_sign = -1.0
  } else if sx < -half_pi {
    sx = -pi - sx
    cos_sign = -1.0
  }
  let x2 = sx * sx
  let s = sx *
    (1.0 - x2 / 6.0 * (1.0 - x2 / 20.0 * (1.0 - x2 / 42.0 * (1.0 - x2 / 72.0))))
  let c = cos_sign *
    (1.0 - x2 / 2.0 * (1.0 - x2 / 12.0 * (1.0 - x2 / 30.0 * (1.0 - x2 / 56.0))))
  (Float::from_double(s), Float::from_double(c))
}

///|
fn mat4_mul(a : FixedArray[Float], b : FixedArray[Float]) -> FixedArray[Float] {
  let out = FixedArray::make(16, (0.0 : Float))
  for col = 0; col < 4; col = col + 1 {
    for row = 0; row < 4; row = row + 1 {
      let mut sum : Float = (0.0 : Float)
      for k = 0; k < 4; k = k + 1 {
        sum = sum + a[k * 4 + row] * b[col * 4 + k]
      }
      out[col * 4 + row] = sum
    }
  }
  out
}

///|
fn make_mvp(angle : Float, aspect : Float) -> FixedArray[Float] {
  let f : Float = (1.7320508 : Float)
  let near : Float = (0.1 : Float)
  let far : Float = (10.0 : Float)
  let proj = FixedArray::make(16, (0.0 : Float))
  proj[0] = f / aspect
  proj[5] = -f
  proj[10] = far / (near - far)
  proj[11] = (-1.0 : Float)
  proj[14] = near * far / (near - far)

  let view = FixedArray::make(16, (0.0 : Float))
  view[0] = (1.0 : Float)
  view[5] = (1.0 : Float)
  view[10] = (1.0 : Float)
  view[14] = (-2.2 : Float)
  view[15] = (1.0 : Float)

  let (sy, cy) = sin_cos_approx(angle)
  let (sx, cx) = sin_cos_approx(angle * (0.5 : Float))
  let ry = FixedArray::make(16, (0.0 : Float))
  ry[0] = cy
  ry[2] = -sy
  ry[5] = (1.0 : Float)
  ry[8] = sy
  ry[10] = cy
  ry[15] = (1.0 : Float)

  let rx = FixedArray::make(16, (0.0 : Float))
  rx[0] = (1.0 : Float)
  rx[5] = cx
  rx[6] = sx
  rx[9] = -sx
  rx[10] = cx
  rx[15] = (1.0 : Float)

  mat4_mul(proj, mat4_mul(view, mat4_mul(ry, rx)))
}

///|
fn main {
  try {
    let dev = @tycho.Device::new("Tycho RHI MRT Deferred", true)
    let sc = dev.create_swapchain_desc(
      @tycho.SwapchainDesc::new(
        "Tycho RHI MRT Deferred",
        800,
        600,
        enable_readback=true,
      ),
    )

    let albedo_rt = dev.create_render_target(256, 256, @tycho.TextureFormat::RGBA8)
    let normal_rt = dev.create_render_target(256, 256, @tycho.TextureFormat::RGBA8)
    let depth_rt = dev.create_depth_texture(256, 256)
    let ts = dev.create_timestamp_pool(2)

    let gvert = @tycho.compile_glsl(
      "examples/42-rhi-mrt-postprocess/gbuffer.vert",
      @tycho.ShaderStage::Vertex,
    )
    let gfrag = @tycho.compile_glsl(
      "examples/42-rhi-mrt-postprocess/gbuffer.frag",
      @tycho.ShaderStage::Fragment,
    )
    // Auto-reflects 3 vertex inputs (Float3 pos, Float3 normal, Float3 color),
    // 64B push constant, and 2 MRT RGBA8 color targets!
    let gbuf_desc = @tycho.PipelineDesc::from_spirv(
      gvert,
      gfrag,
      depth_test=true,
      depth_write=true,
      cull_mode=@tycho.CullMode::Back,
      front_face=@tycho.FrontFace::CounterClockwise,
    )
    let mrt_refl_ok = gbuf_desc.vertex_formats.length() == 3 &&
      gbuf_desc.push_constant_size == 64 &&
      gbuf_desc.color_formats.length() == 2
    let gbuf_pipe = dev.create_graphics_pipeline(gbuf_desc)

    let cvert = @tycho.compile_glsl(
      "examples/42-rhi-mrt-postprocess/composite.vert",
      @tycho.ShaderStage::Vertex,
    )
    let cfrag = @tycho.compile_glsl(
      "examples/42-rhi-mrt-postprocess/composite.frag",
      @tycho.ShaderStage::Fragment,
    )
    let comp_desc = @tycho.PipelineDesc::from_spirv(cvert, cfrag)
    let comp_refl_ok = comp_desc.texture_slots == 2 &&
      comp_desc.texture_bindings.length() == 2 &&
      comp_desc.texture_bindings[0] == 0 &&
      comp_desc.texture_bindings[1] == 1
    let comp_pipe = sc.create_pipeline_desc(comp_desc)
    let samp = dev.create_sampler()

    // 24 cube vertices: (vec3 pos, vec3 normal, vec3 albedo)
    let verts : FixedArray[Float] = [
      // +Z front (Red albedo, normal +Z)
      -0.5, -0.5, 0.5, 0.0, 0.0, 1.0, 1.0, 0.2, 0.2,
      0.5, -0.5, 0.5, 0.0, 0.0, 1.0, 1.0, 0.2, 0.2,
      0.5, 0.5, 0.5, 0.0, 0.0, 1.0, 1.0, 0.2, 0.2,
      -0.5, 0.5, 0.5, 0.0, 0.0, 1.0, 1.0, 0.2, 0.2,
      // -Z back (Blue albedo, normal -Z)
      0.5, -0.5, -0.5, 0.0, 0.0, -1.0, 0.2, 0.3, 1.0,
      -0.5, -0.5, -0.5, 0.0, 0.0, -1.0, 0.2, 0.3, 1.0,
      -0.5, 0.5, -0.5, 0.0, 0.0, -1.0, 0.2, 0.3, 1.0,
      0.5, 0.5, -0.5, 0.0, 0.0, -1.0, 0.2, 0.3, 1.0,
      // +X right (Green albedo, normal +X)
      0.5, -0.5, 0.5, 1.0, 0.0, 0.0, 0.2, 0.9, 0.3,
      0.5, -0.5, -0.5, 1.0, 0.0, 0.0, 0.2, 0.9, 0.3,
      0.5, 0.5, -0.5, 1.0, 0.0, 0.0, 0.2, 0.9, 0.3,
      0.5, 0.5, 0.5, 1.0, 0.0, 0.0, 0.2, 0.9, 0.3,
      // -X left (Yellow albedo, normal -X)
      -0.5, -0.5, -0.5, -1.0, 0.0, 0.0, 0.9, 0.9, 0.2,
      -0.5, -0.5, 0.5, -1.0, 0.0, 0.0, 0.9, 0.9, 0.2,
      -0.5, 0.5, 0.5, -1.0, 0.0, 0.0, 0.9, 0.9, 0.2,
      -0.5, 0.5, -0.5, -1.0, 0.0, 0.0, 0.9, 0.9, 0.2,
      // +Y top (Cyan albedo, normal +Y)
      -0.5, 0.5, 0.5, 0.0, 1.0, 0.0, 0.2, 0.9, 0.9,
      0.5, 0.5, 0.5, 0.0, 1.0, 0.0, 0.2, 0.9, 0.9,
      0.5, 0.5, -0.5, 0.0, 1.0, 0.0, 0.2, 0.9, 0.9,
      -0.5, 0.5, -0.5, 0.0, 1.0, 0.0, 0.2, 0.9, 0.9,
      // -Y bottom (Magenta albedo, normal -Y)
      -0.5, -0.5, -0.5, 0.0, -1.0, 0.0, 0.9, 0.2, 0.9,
      0.5, -0.5, -0.5, 0.0, -1.0, 0.0, 0.9, 0.2, 0.9,
      0.5, -0.5, 0.5, 0.0, -1.0, 0.0, 0.9, 0.2, 0.9,
      -0.5, -0.5, 0.5, 0.0, -1.0, 0.0, 0.9, 0.2, 0.9,
    ]
    let indices : FixedArray[UInt16] = [
      0, 1, 2, 0, 2, 3,
      4, 5, 6, 4, 6, 7,
      8, 9, 10, 8, 10, 11,
      12, 13, 14, 12, 14, 15,
      16, 17, 18, 16, 18, 19,
      20, 21, 22, 20, 22, 23,
    ]
    let vbuf = dev.create_buffer(verts.length() * 4, @tycho.BufferKind::Vertex)
    vbuf.upload_floats(verts)
    let ibuf = dev.create_buffer(indices.length() * 2, @tycho.BufferKind::Index)
    ibuf.upload_uint16(indices)

    // Pass 1 + Pass 2 in a single command buffer per frame (no mid-frame vkQueueWaitIdle)
    let mvp0 = make_mvp((0.0 : Float), (1.0 : Float))
    let start = @tycho.Swapchain::time()
    let mut pixels : FixedArray[Byte] = []
    let mut gbuf_ms = 0.0
    let mut frames = 0
    while !sc.should_close() && frames < 10 && @tycho.Swapchain::time() - start < 0.8 {
      let cmd = sc.begin_frame_commands()
      if frames == 0 {
        cmd.reset_timestamps(ts)
        cmd.write_timestamp(ts, 0, at_start=true)
      }
      cmd.begin_render_pass(
        [
          @tycho.RenderTargetDesc::new(
            albedo_rt,
            clear_color=@tycho.ClearColor::rgba(0.0, 0.0, 0.0, 0.0),
          ),
          @tycho.RenderTargetDesc::new(
            normal_rt,
            clear_color=@tycho.ClearColor::rgba(0.5, 0.5, 0.5, 1.0),
          ),
        ],
        depth=Some(@tycho.DepthTargetDesc::new(depth_rt)),
      )
      cmd.bind_pipeline(gbuf_pipe)
      cmd.push_constants_floats(gbuf_pipe, mvp0)
      cmd.bind_vertex(0, vbuf)
      cmd.bind_index(ibuf, @tycho.IndexType::Uint16)
      cmd.draw_indexed(36)
      cmd.end_render_pass()
      if frames == 0 {
        cmd.write_timestamp(ts, 1)
      }
      cmd.begin_swapchain_pass(sc)
      cmd.bind_pipeline(comp_pipe)
      cmd.bind_texture(comp_pipe, 0, albedo_rt, samp)
      cmd.bind_texture(comp_pipe, 1, normal_rt, samp)
      cmd.draw(6, 1)
      cmd.end_swapchain_pass()
      sc.end_frame(cmd)
      if frames == 0 {
        pixels = sc.readback()
        gbuf_ms = ts.elapsed_ms(0, 1)
      }
      frames = frames + 1
    }

    let alb_px = albedo_rt.readback()
    let nrm_px = normal_rt.readback()
    let gc = (128 * 256 + 128) * 4
    let ar = alb_px[gc].to_int()
    let ag = alb_px[gc + 1].to_int()
    let ab = alb_px[gc + 2].to_int()
    let nr = nrm_px[gc].to_int()
    let ng = nrm_px[gc + 1].to_int()
    let nb = nrm_px[gc + 2].to_int()
    let gbuf_ok = ar > 200 &&
      ag < 70 &&
      ab < 70 &&
      nr >= 115 &&
      nr <= 140 &&
      ng >= 115 &&
      ng <= 140 &&
      nb > 240

    let c = (300 * 800 + 400) * 4
    let (sr, sg, sb) = if sc.color_format() == @tycho.TextureFormat::BGRA8 {
      (pixels[c + 2].to_int(), pixels[c + 1].to_int(), pixels[c].to_int())
    } else {
      (pixels[c].to_int(), pixels[c + 1].to_int(), pixels[c + 2].to_int())
    }
    let lit_ok = sr > 150 && sr > sg + 80 && sr > sb + 80
    let errs = dev.validation_errors()

    ibuf.destroy()
    vbuf.destroy()
    samp.destroy()
    comp_pipe.destroy()
    gbuf_pipe.destroy()
    ts.destroy()
    depth_rt.destroy()
    normal_rt.destroy()
    albedo_rt.destroy()
    sc.destroy()
    dev.destroy()

    println(
      "[42-rhi-mrt-postprocess] refl=(mrt:\{mrt_refl_ok},comp:\{comp_refl_ok}) gbuf_ms=\{gbuf_ms} albedo=(\{ar},\{ag},\{ab}) normal=(\{nr},\{ng},\{nb}) lit=(\{sr},\{sg},\{sb}) frames=\{frames}",
    )
    if mrt_refl_ok && comp_refl_ok && gbuf_ok && lit_ok && gbuf_ms >= 0.0 && errs == 0 {
      println(
        "[42-rhi-mrt-postprocess] OK — 2-target MRT G-Buffer + deferred lighting composite in \{gbuf_ms} ms, 0 validation errors",
      )
    } else {
      println(
        "[42-rhi-mrt-postprocess] FAIL — mrt_refl=\{mrt_refl_ok} comp_refl=\{comp_refl_ok} gbuf_ok=\{gbuf_ok} lit_ok=\{lit_ok} errs=\{errs}",
      )
    }
  } catch {
    err => println("[42-rhi-mrt-postprocess] FAIL — \{err}")
  }
}
