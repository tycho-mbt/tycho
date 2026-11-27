// rhi/reflection-mipmaps — Pure-MoonBit SPIR-V reflection (`PipelineDesc::from_spirv`),
// GPU-generated mipmap chain (`create_texture_mipmapped`), mip level readback,
// and sampler LOD control (`SamplerDesc` min_lod/max_lod).

///|
fn main {
  try {
    let opts = @exwin.Options::parse("rhi/reflection-mipmaps")
    let show_win = opts.window
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "Tycho RHI Reflection & Mipmaps",
        validation=true,
        headless=!show_win,
      ),
    )

    let vert = @tycho.compile_glsl(
      "examples/rhi/reflection-mipmaps/shader.vert",
      @tycho.ShaderStage::Vertex,
    )
    let frag = @tycho.compile_glsl(
      "examples/rhi/reflection-mipmaps/shader.frag",
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

    // 5 samplers locked to mip levels 0..4 (16x16 down to 1x1 average)
    let samps : Array[@tycho.Sampler] = []
    for lod = 0; lod < 5; lod = lod + 1 {
      let lf = Float::from_int(lod)
      samps.push(
        dev.create_sampler_desc(
          @tycho.SamplerDesc::new(
            mag=@tycho.Filter::Nearest,
            min=@tycho.Filter::Nearest,
            mipmap=@tycho.Filter::Nearest,
            address=@tycho.AddressMode::ClampToEdge,
            min_lod=lf,
            max_lod=lf,
          ),
        ),
      )
    }

    // 5 side-by-side 144x144 square panels (x stride 0.39, y in [-0.24, +0.24])
    let vdata : Array[Float] = []
    for lod = 0; lod < 5; lod = lod + 1 {
      let x0 = (-0.96 : Float) + Float::from_int(lod) * (0.39 : Float)
      let x1 = x0 + (0.36 : Float)
      let y0 : Float = -0.24
      let y1 : Float = 0.24
      let q : Array[Float] = [
        x0, y0, 0.0, 0.0,
        x1, y0, 1.0, 0.0,
        x1, y1, 1.0, 1.0,
        x0, y0, 0.0, 0.0,
        x1, y1, 1.0, 1.0,
        x0, y1, 0.0, 1.0,
      ]
      for v in q {
        vdata.push(v)
      }
    }
    let verts = FixedArray::makei(vdata.length(), fn(i) { vdata[i] })
    let vbuf = dev.create_buffer(verts.length() * 4, @tycho.BufferKind::Vertex)
    vbuf.upload_floats(verts)
    let tint : FixedArray[Float] = [1.0, 1.0, 1.0, 1.0]

    let mut pixels : FixedArray[Byte] = []
    let mut frames = 0
    let mut is_bgra = false
    if show_win {
      let sc = @exwin_rhi.open(
        dev,
        opts,
        clear_color=@tycho.ClearColor::rgba(0.08, 0.09, 0.12, 1.0),
      )
      is_bgra = sc.color_format() == @tycho.TextureFormat::BGRA8
      let pipe = sc.create_pipeline_desc(@tycho.PipelineDesc::from_spirv(vert, frag))
      while @exwin_rhi.next_frame(sc) {
        let cmd = sc.begin_frame()
        cmd.bind_pipeline(pipe)
        cmd.push_constants_floats(pipe, tint)
        for lod = 0; lod < 5; lod = lod + 1 {
          cmd.bind_vertex(0, vbuf, offset=lod * 96)
          cmd.bind_texture(pipe, 0, tex, samps[lod])
          cmd.draw(6, 1)
        }
        sc.end_frame(cmd)
        if frames == 0 {
          pixels = sc.readback()
          @exwin_rhi.capture(opts, sc, pixels)
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
          color_format=@tycho.TextureFormat::RGBA8,
        ),
      )
      let cmd = dev.begin_commands()
      cmd.begin_render_pass([
        @tycho.RenderTargetDesc::new(
          rt,
          clear_color=@tycho.ClearColor::rgba(0.08, 0.09, 0.12, 1.0),
        ),
      ])
      cmd.bind_pipeline(pipe)
      cmd.push_constants_floats(pipe, tint)
      for lod = 0; lod < 5; lod = lod + 1 {
        cmd.bind_vertex(0, vbuf, offset=lod * 96)
        cmd.bind_texture(pipe, 0, tex, samps[lod])
        cmd.draw(6, 1)
      }
      cmd.end_render_pass()
      dev.end_commands(cmd)
      pixels = rt.readback()
      frames = 1
      opts.capture(800, 600, pixels)
      pipe.destroy()
      rt.destroy()
    }

    let read_rgb = fn(px_x : Int, px_y : Int) {
      let c = (px_y * 800 + px_x) * 4
      if is_bgra {
        (pixels[c + 2].to_int(), pixels[c + 1].to_int(), pixels[c].to_int())
      } else {
        (pixels[c].to_int(), pixels[c + 1].to_int(), pixels[c + 2].to_int())
      }
    }
    let (r0, g0, b0) = read_rgb(52, 264)
    let (r1, g1, b1) = read_rgb(124, 264)
    let (r2, g2, b2) = read_rgb(52, 336)
    let (sr, sg, sb) = read_rgb(712, 300)
    let lod0_ok = r0 > 220 && g0 < 30 && b0 < 30 &&
      g1 > 220 && r1 < 30 && b1 < 30 &&
      b2 > 220 && r2 < 30 && g2 < 30
    let sc_ok = lod0_ok &&
      sr >= 115 &&
      sr <= 140 &&
      sg >= 115 &&
      sg <= 140 &&
      sb >= 115 &&
      sb <= 140
    let errs = dev.validation_errors()

    vbuf.destroy()
    for samp in samps {
      samp.destroy()
    }
    tex.destroy()
    dev.destroy()

    println(
      "[rhi/reflection-mipmaps] refl_ok=\{refl_ok} mip_levels=\{levels} mip4=(\{mr},\{mg},\{mb}) centre=(\{sr},\{sg},\{sb}) frames=\{frames}",
    )
    if refl_ok && mip_ok && sc_ok && errs == 0 {
      println(
        "[rhi/reflection-mipmaps] OK — auto-reflected pipeline + 5-level GPU mipmap chain + LOD-4 sampling, 0 validation errors",
      )
    } else {
      println(
        "[rhi/reflection-mipmaps] FAIL — refl_ok=\{refl_ok} mip_ok=\{mip_ok} sc_ok=\{sc_ok} errs=\{errs}",
      )
    }
  } catch {
    err => println("[rhi/reflection-mipmaps] FAIL — \{err}")
  }
}
