// Example 40 — Pure-MoonBit SPIR-V reflection (`PipelineDesc::from_spirv`),
// GPU-generated mipmap chain (`create_texture_mipmapped`), mip level readback,
// and sampler LOD control (`SamplerDesc` min_lod/max_lod).

///|
fn should_quit(sc : @tycho.Swapchain) -> Bool {
  if sc.should_close() {
    return true
  }
  for ev in sc.poll_events() {
    match ev {
      @tycho.Event::KeyDown(k, _) => if k == @tycho.KEY_ESCAPE { return true }
      _ => ()
    }
  }
  false
}

///|
fn main {
  try {
    let show_win = @tycho.want_window()
    let shot = @tycho.screenshot_path()
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "Tycho RHI Reflection & Mipmaps",
        validation=true,
        headless=!show_win,
      ),
    )

    let vert = @tycho.compile_glsl(
      "examples/40-rhi-reflection-mipmaps/shader.vert",
      @tycho.ShaderStage::Vertex,
    )
    let frag = @tycho.compile_glsl(
      "examples/40-rhi-reflection-mipmaps/shader.frag",
      @tycho.ShaderStage::Fragment,
    )

    // Verify SPIR-V bytecode reflection directly
    let vr = @tycho.reflect_spirv(vert)
    let fr = @tycho.reflect_spirv(frag)
    let refl_ok = vr.vertex_inputs.length() == 2 &&
      fr.bindings.length() == 1 &&
      fr.bindings[0].binding == 0 &&
      fr.push_constant_size == 16 &&
      fr.color_output_count == 1

    // 16x16 4-quadrant RGBA8 image: Red, Green, Blue, White -> 1x1 mip average ≈ (127, 127, 127, 255)
    let w = 16
    let h = 16
    let tex_bytes = Bytes::makei(w * h * 4, fn(idx) {
      let p = idx / 4
      let ch = idx % 4
      let x = p % w
      let y = p / w
      let (r, g, b) = if x < 8 && y < 8 {
        (255, 0, 0)
      } else if x >= 8 && y < 8 {
        (0, 255, 0)
      } else if x < 8 && y >= 8 {
        (0, 0, 255)
      } else {
        (255, 255, 255)
      }
      if ch == 0 {
        r.to_byte()
      } else if ch == 1 {
        g.to_byte()
      } else if ch == 2 {
        b.to_byte()
      } else {
        (255 : Byte)
      }
    })
    let tex = dev.create_texture_mipmapped(
      w,
      h,
      @tycho.TextureFormat::RGBA8,
      tex_bytes,
    )
    let levels = tex.mip_levels()
    let mip4 = tex.readback_mip(4)
    let mr = mip4[0].to_int()
    let mg = mip4[1].to_int()
    let mb = mip4[2].to_int()
    let mip_ok = levels == 5 &&
      mip4.length() == 4 &&
      mr >= 115 &&
      mr <= 140 &&
      mg >= 115 &&
      mg <= 140 &&
      mb >= 115 &&
      mb <= 140

    // Sampler locked to mip level 4 (1x1 average)
    let samp = dev.create_sampler_desc(
      @tycho.SamplerDesc::new(
        mag=@tycho.Filter::Linear,
        min=@tycho.Filter::Linear,
        mipmap=@tycho.Filter::Linear,
        address=@tycho.AddressMode::ClampToEdge,
        min_lod=(4.0 : Float),
        max_lod=(4.0 : Float),
      ),
    )

    // Fullscreen quad: (vec2 pos, vec2 uv)
    let verts : FixedArray[Float] = [
      -1.0, -1.0, 0.0, 0.0,
      1.0, -1.0, 1.0, 0.0,
      1.0, 1.0, 1.0, 1.0,
      -1.0, -1.0, 0.0, 0.0,
      1.0, 1.0, 1.0, 1.0,
      -1.0, 1.0, 0.0, 1.0,
    ]
    let vbuf = dev.create_buffer(verts.length() * 4, @tycho.BufferKind::Vertex)
    vbuf.upload_floats(verts)
    let tint : FixedArray[Float] = [1.0, 1.0, 1.0, 1.0]

    let mut pixels : FixedArray[Byte] = []
    let mut frames = 0
    let mut is_bgra = false
    if show_win {
      let sc = dev.create_swapchain_desc(
        @tycho.SwapchainDesc::new(
          "Tycho RHI Reflection & Mipmaps",
          800,
          600,
          enable_readback=true,
        ),
      )
      is_bgra = sc.color_format() == @tycho.TextureFormat::BGRA8
      let pipe = sc.create_pipeline_desc(@tycho.PipelineDesc::from_spirv(vert, frag))
      while !should_quit(sc) {
        let cmd = sc.begin_frame()
        cmd.bind_pipeline(pipe)
        cmd.bind_texture(pipe, 0, tex, samp)
        cmd.push_constants_floats(pipe, tint)
        cmd.bind_vertex(0, vbuf)
        cmd.draw(6, 1)
        sc.end_frame(cmd)
        if frames == 0 {
          pixels = sc.readback()
          if shot != "" {
            let _ = @tycho.save_png(shot, 800, 600, pixels, bgra=is_bgra)
          }
        }
        frames = frames + 1
      }
      pipe.destroy()
      sc.destroy()
    } else {
      let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8)
      let pipe = dev.create_graphics_pipeline(
        @tycho.PipelineDesc::from_spirv(
          vert,
          frag,
          color_format=Some(@tycho.TextureFormat::RGBA8),
        ),
      )
      let cmd = dev.begin_commands()
      cmd.begin_render_pass([@tycho.RenderTargetDesc::new(rt)])
      cmd.bind_pipeline(pipe)
      cmd.bind_texture(pipe, 0, tex, samp)
      cmd.push_constants_floats(pipe, tint)
      cmd.bind_vertex(0, vbuf)
      cmd.draw(6, 1)
      cmd.end_render_pass()
      dev.end_commands(cmd)
      pixels = rt.readback()
      frames = 1
      if shot != "" {
        let _ = @tycho.save_png(shot, 800, 600, pixels)
      }
      pipe.destroy()
      rt.destroy()
    }

    let c = (300 * 800 + 400) * 4
    let (sr, sg, sb) = if is_bgra {
      (pixels[c + 2].to_int(), pixels[c + 1].to_int(), pixels[c].to_int())
    } else {
      (pixels[c].to_int(), pixels[c + 1].to_int(), pixels[c + 2].to_int())
    }
    let sc_ok = sr >= 115 &&
      sr <= 140 &&
      sg >= 115 &&
      sg <= 140 &&
      sb >= 115 &&
      sb <= 140
    let errs = dev.validation_errors()

    vbuf.destroy()
    samp.destroy()
    tex.destroy()
    dev.destroy()

    println(
      "[40-rhi-reflection-mipmaps] refl_ok=\{refl_ok} mip_levels=\{levels} mip4=(\{mr},\{mg},\{mb}) centre=(\{sr},\{sg},\{sb}) frames=\{frames}",
    )
    if refl_ok && mip_ok && sc_ok && errs == 0 {
      println(
        "[40-rhi-reflection-mipmaps] OK — auto-reflected pipeline + 5-level GPU mipmap chain + LOD-4 sampling, 0 validation errors",
      )
    } else {
      println(
        "[40-rhi-reflection-mipmaps] FAIL — refl_ok=\{refl_ok} mip_ok=\{mip_ok} sc_ok=\{sc_ok} errs=\{errs}",
      )
    }
  } catch {
    err => println("[40-rhi-reflection-mipmaps] FAIL — \{err}")
  }
}
