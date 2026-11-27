// rhi/pipeline-instancing — RHI v0.4 pipeline state & instanced vertex layouts:
// - Multi-stream VertexBufferLayout (Vertex binding 0 + Instance binding 1)
// - BlendMode::Additive, Alpha, Premultiplied, Multiply (pixel-verified)
// - PrimitiveTopology::LineList (pixel-verified)
// - Reversed-Z depth test (CompareOp::GreaterEqual + Depth32F clear 0.0)
// - Device::pipeline_cache_data() round-trip

///|
fn sample_rgb(
  pixels : FixedArray[Byte],
  w : Int32,
  x : Int32,
  y : Int32,
) -> (Int32, Int32, Int32) {
  let i = (y * w + x) * 4
  (pixels[i].to_int(), pixels[i + 1].to_int(), pixels[i + 2].to_int())
}

///|
fn near_byte(v : Int32, expected : Int32, tol : Int32) -> Bool {
  let d = if v > expected { v - expected } else { expected - v }
  d <= tol
}

///|
fn main {
  try {
    let opts = @exwin.Options::parse("rhi/pipeline-instancing")
    let show_win = opts.window
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "Tycho RHI Instancing",
        validation=true,
        headless=!show_win,
      ),
    )
    let vert = @tycho.compile_glsl(
      "examples/rhi/pipeline-instancing/shader.vert",
      @tycho.ShaderStage::Vertex,
    )
    let frag = @tycho.compile_glsl(
      "examples/rhi/pipeline-instancing/shader.frag",
      @tycho.ShaderStage::Fragment,
    )

    let layouts = [
      @tycho.VertexBufferLayout::new(
        12,
        [@tycho.VertexAttribute::new(0, @tycho.VertexFormat::Float3, 0)],
        step_mode=@tycho.VertexStepMode::Vertex,
      ),
      @tycho.VertexBufferLayout::new(
        24,
        [
          @tycho.VertexAttribute::new(1, @tycho.VertexFormat::Float2, 0),
          @tycho.VertexAttribute::new(2, @tycho.VertexFormat::Float4, 8),
        ],
        step_mode=@tycho.VertexStepMode::Instance,
      ),
    ]

    let add_pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::from_spirv(
        vert,
        frag,
        blend_mode=@tycho.BlendMode::Additive,
        color_format=@tycho.TextureFormat::RGBA8,
        vertex_layouts=layouts,
      ),
    )
    let line_pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::from_spirv(
        vert,
        frag,
        topology=@tycho.PrimitiveTopology::LineList,
        color_format=@tycho.TextureFormat::RGBA8,
        vertex_layouts=layouts,
      ),
    )
    let alpha_pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::from_spirv(
        vert,
        frag,
        blend_mode=@tycho.BlendMode::Alpha,
        color_format=@tycho.TextureFormat::RGBA8,
        vertex_layouts=layouts,
      ),
    )
    let premul_pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::from_spirv(
        vert,
        frag,
        blend_mode=@tycho.BlendMode::Premultiplied,
        color_format=@tycho.TextureFormat::RGBA8,
        vertex_layouts=layouts,
      ),
    )
    let mult_pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::from_spirv(
        vert,
        frag,
        blend_mode=@tycho.BlendMode::Multiply,
        color_format=@tycho.TextureFormat::RGBA8,
        vertex_layouts=layouts,
      ),
    )
    let revz_pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::from_spirv(
        vert,
        frag,
        depth_test=true,
        depth_write=true,
        depth_compare=@tycho.CompareOp::GreaterEqual,
        depth_format=@tycho.TextureFormat::Depth32F,
        color_format=@tycho.TextureFormat::RGBA8,
        vertex_layouts=layouts,
      ),
    )

    // Pass 1: instanced triangles (Additive) + white horizontal line at y=-0.85 (LineList)
    let vbuf = dev.create_buffer_with(
      36,
      @tycho.BufferKind::Vertex,
      location=@tycho.MemoryLocation::GpuOnly,
    )
    vbuf.upload_floats([
      (-0.35 : Float),
      (-0.35 : Float),
      (0.5 : Float),
      (0.35 : Float),
      (-0.35 : Float),
      (0.5 : Float),
      (0.0 : Float),
      (0.35 : Float),
      (0.5 : Float),
    ])
    let ibuf = dev.create_buffer_with(
      72,
      @tycho.BufferKind::Vertex,
      location=@tycho.MemoryLocation::GpuOnly,
    )
    ibuf.upload_floats([
      (-0.5 : Float),
      (0.0 : Float),
      (0.8 : Float),
      (0.0 : Float),
      (0.0 : Float),
      (1.0 : Float),
      (0.5 : Float),
      (0.0 : Float),
      (0.0 : Float),
      (0.0 : Float),
      (0.8 : Float),
      (1.0 : Float),
      (0.5 : Float),
      (0.0 : Float),
      (0.0 : Float),
      (0.8 : Float),
      (0.0 : Float),
      (1.0 : Float),
    ])
    let line_vbuf = dev.create_buffer_with(
      24,
      @tycho.BufferKind::Vertex,
      location=@tycho.MemoryLocation::GpuOnly,
    )
    line_vbuf.upload_floats([
      (-0.7 : Float),
      (-0.85 : Float),
      (0.0 : Float),
      (0.7 : Float),
      (-0.85 : Float),
      (0.0 : Float),
    ])
    let line_ibuf = dev.create_buffer_with(
      24,
      @tycho.BufferKind::Vertex,
      location=@tycho.MemoryLocation::GpuOnly,
    )
    line_ibuf.upload_floats([
      (0.0 : Float),
      (0.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
    ])

    // Quad geometry in [-0.28, +0.28] x [-0.8, +0.8] (6 vertices)
    let quad_vbuf = dev.create_buffer_with(
      72,
      @tycho.BufferKind::Vertex,
      location=@tycho.MemoryLocation::GpuOnly,
    )
    quad_vbuf.upload_floats([
      (-0.28 : Float),
      (-0.8 : Float),
      (0.0 : Float),
      (0.28 : Float),
      (-0.8 : Float),
      (0.0 : Float),
      (0.28 : Float),
      (0.8 : Float),
      (0.0 : Float),
      (-0.28 : Float),
      (-0.8 : Float),
      (0.0 : Float),
      (0.28 : Float),
      (0.8 : Float),
      (0.0 : Float),
      (-0.28 : Float),
      (0.8 : Float),
      (0.0 : Float),
    ])
    let blend_ibuf = dev.create_buffer_with(
      72,
      @tycho.BufferKind::Vertex,
      location=@tycho.MemoryLocation::GpuOnly,
    )
    // dst = (0.8, 0.4, 0.2):
    //   0 Alpha:         src=(0.0, 0.0, 1.0, 0.5) -> (0.4, 0.2, 0.6) ~ (102, 51, 153)
    //   1 Premultiplied: src=(0.0, 0.5, 0.0, 0.5) -> (0.4, 0.7, 0.1) ~ (102, 178, 25)
    //   2 Multiply:      src=(0.5, 1.0, 0.5, 1.0) -> (0.4, 0.4, 0.1) ~ (102, 102, 25)
    blend_ibuf.upload_floats([
      (-0.66 : Float),
      (0.0 : Float),
      (0.0 : Float),
      (0.0 : Float),
      (1.0 : Float),
      (0.5 : Float),
      (0.0 : Float),
      (0.0 : Float),
      (0.0 : Float),
      (0.5 : Float),
      (0.0 : Float),
      (0.5 : Float),
      (0.66 : Float),
      (0.0 : Float),
      (0.5 : Float),
      (1.0 : Float),
      (0.5 : Float),
      (1.0 : Float),
    ])

    // Reversed-Z full-screen quads: near at z=0.8 (green) then far at z=0.3 (red)
    let revz_vbuf = dev.create_buffer_with(
      144,
      @tycho.BufferKind::Vertex,
      location=@tycho.MemoryLocation::GpuOnly,
    )
    revz_vbuf.upload_floats([
      (-0.8 : Float),
      (-0.8 : Float),
      (0.8 : Float),
      (0.8 : Float),
      (-0.8 : Float),
      (0.8 : Float),
      (0.8 : Float),
      (0.8 : Float),
      (0.8 : Float),
      (-0.8 : Float),
      (-0.8 : Float),
      (0.8 : Float),
      (0.8 : Float),
      (0.8 : Float),
      (0.8 : Float),
      (-0.8 : Float),
      (0.8 : Float),
      (0.8 : Float),
      (-0.8 : Float),
      (-0.8 : Float),
      (0.3 : Float),
      (0.8 : Float),
      (-0.8 : Float),
      (0.3 : Float),
      (0.8 : Float),
      (0.8 : Float),
      (0.3 : Float),
      (-0.8 : Float),
      (-0.8 : Float),
      (0.3 : Float),
      (0.8 : Float),
      (0.8 : Float),
      (0.3 : Float),
      (-0.8 : Float),
      (0.8 : Float),
      (0.3 : Float),
    ])
    let revz_ibuf = dev.create_buffer_with(
      48,
      @tycho.BufferKind::Vertex,
      location=@tycho.MemoryLocation::GpuOnly,
    )
    revz_ibuf.upload_floats([
      (0.0 : Float),
      (0.0 : Float),
      (0.0 : Float),
      (1.0 : Float),
      (0.0 : Float),
      (1.0 : Float),
      (0.0 : Float),
      (0.0 : Float),
      (1.0 : Float),
      (0.0 : Float),
      (0.0 : Float),
      (1.0 : Float),
    ])

    let rt = dev.create_render_target(200, 200, @tycho.TextureFormat::RGBA8)
    let rt_blend = dev.create_render_target(
      180,
      60,
      @tycho.TextureFormat::RGBA8,
    )
    let rt_revz = dev.create_render_target(
      100,
      100,
      @tycho.TextureFormat::RGBA8,
    )
    let depth_revz = dev.create_depth_texture_format(
      100,
      100,
      @tycho.TextureFormat::Depth32F,
    )

    let cmd = dev.begin_commands()
    cmd.begin_render_pass([
      @tycho.RenderTargetDesc::new(
        rt,
        clear_color=@tycho.ClearColor::rgba(0.0, 0.0, 0.0, 1.0),
      ),
    ])
    cmd.bind_pipeline(add_pipe)
    cmd.bind_vertex(0, vbuf)
    cmd.bind_vertex(1, ibuf)
    cmd.draw(3, 3)
    cmd.bind_pipeline(line_pipe)
    cmd.bind_vertex(0, line_vbuf)
    cmd.bind_vertex(1, line_ibuf)
    cmd.draw(2, 1)
    cmd.end_render_pass()

    cmd.begin_render_pass([
      @tycho.RenderTargetDesc::new(
        rt_blend,
        clear_color=@tycho.ClearColor::rgba(0.8, 0.4, 0.2, 1.0),
      ),
    ])
    cmd.bind_vertex(0, quad_vbuf)
    cmd.bind_pipeline(alpha_pipe)
    cmd.bind_vertex(1, blend_ibuf, offset=0)
    cmd.draw(6, 1)
    cmd.bind_pipeline(premul_pipe)
    cmd.bind_vertex(1, blend_ibuf, offset=24)
    cmd.draw(6, 1)
    cmd.bind_pipeline(mult_pipe)
    cmd.bind_vertex(1, blend_ibuf, offset=48)
    cmd.draw(6, 1)
    cmd.end_render_pass()

    cmd.begin_render_pass(
      [
        @tycho.RenderTargetDesc::new(
          rt_revz,
          clear_color=@tycho.ClearColor::black(),
        ),
      ],
      depth=
        @tycho.DepthTargetDesc::new(
          depth_revz,
          load_op=@tycho.LoadOp::Clear,
          store_op=@tycho.StoreOp::DontCare,
          clear_depth=(0.0 : Float),
        )
      ,
    )
    cmd.bind_pipeline(revz_pipe)
    cmd.bind_vertex(0, revz_vbuf, offset=0)
    cmd.bind_vertex(1, revz_ibuf, offset=0)
    cmd.draw(6, 1)
    cmd.bind_vertex(0, revz_vbuf, offset=72)
    cmd.bind_vertex(1, revz_ibuf, offset=24)
    cmd.draw(6, 1)
    cmd.end_render_pass()
    dev.end_commands(cmd)

    let px = rt.readback()
    opts.capture(200, 200, px)
    if show_win {
      let sc = @exwin_rhi.open(dev, opts)
      while @exwin_rhi.next_frame(sc) {
        sc.present_texture(rt)
      }
      sc.destroy()
    }
    let (lr, lg, lb) = sample_rgb(px, 200, 50, 100)
    let (rr, rg, rb) = sample_rgb(px, 200, 150, 100)
    let mut line_ok = false
    for ly = 12; ly <= 18; ly = ly + 1 {
      let (pr, pg, pb) = sample_rgb(px, 200, 100, ly)
      if pr > 200 && pg > 200 && pb > 200 {
        line_ok = true
      }
    }

    let bpx = rt_blend.readback()
    let (ar, ag, ab) = sample_rgb(bpx, 180, 30, 30)
    let (pr, pg, pb) = sample_rgb(bpx, 180, 90, 30)
    let (mr, mg, mb) = sample_rgb(bpx, 180, 150, 30)
    let alpha_ok = near_byte(ar, 102, 12) &&
      near_byte(ag, 51, 12) &&
      near_byte(ab, 153, 12)
    let premul_ok = near_byte(pr, 102, 12) &&
      near_byte(pg, 178, 12) &&
      near_byte(pb, 25, 12)
    let mult_ok = near_byte(mr, 102, 12) &&
      near_byte(mg, 102, 12) &&
      near_byte(mb, 25, 12)

    let zpx = rt_revz.readback()
    let (zr, zg, zb) = sample_rgb(zpx, 100, 50, 50)
    let revz_ok = zr < 20 && zg > 220 && zb < 20

    let cache_bytes = dev.pipeline_cache_data()
    let cache_ok = cache_bytes.length() > 0

    let dev2 = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "Tycho RHI Cache Warm",
        validation=true,
        headless=true,
        pipeline_cache=cache_bytes,
      ),
    )
    let warm_pipe = dev2.create_graphics_pipeline(
      @tycho.PipelineDesc::from_spirv(
        vert,
        frag,
        blend_mode=@tycho.BlendMode::Additive,
        color_format=@tycho.TextureFormat::RGBA8,
        vertex_layouts=layouts,
      ),
    )
    let errs2 = dev2.validation_errors()
    warm_pipe.destroy()
    dev2.destroy()

    let errs = dev.validation_errors()
    depth_revz.destroy()
    rt_revz.destroy()
    rt_blend.destroy()
    rt.destroy()
    revz_ibuf.destroy()
    revz_vbuf.destroy()
    blend_ibuf.destroy()
    quad_vbuf.destroy()
    line_ibuf.destroy()
    line_vbuf.destroy()
    ibuf.destroy()
    vbuf.destroy()
    revz_pipe.destroy()
    mult_pipe.destroy()
    premul_pipe.destroy()
    alpha_pipe.destroy()
    line_pipe.destroy()
    add_pipe.destroy()
    dev.destroy()

    let left_ok = lr > 150 && lg < 30 && lb < 30
    let right_ok = rr < 30 && rg > 150 && rb > 150
    println(
      "[rhi/pipeline-instancing] left=(\{lr},\{lg},\{lb}) right=(\{rr},\{rg},\{rb}) line=\{line_ok} alpha=(\{ar},\{ag},\{ab}) premul=(\{pr},\{pg},\{pb}) mult=(\{mr},\{mg},\{mb}) revz=(\{zr},\{zg},\{zb}) cache_bytes=\{cache_bytes.length()}",
    )
    if left_ok &&
      right_ok &&
      line_ok &&
      alpha_ok &&
      premul_ok &&
      mult_ok &&
      revz_ok &&
      cache_ok &&
      errs == 0 &&
      errs2 == 0 {
      println(
        "[rhi/pipeline-instancing] OK — instancing + all blend modes + line topology + reversed-Z + pipeline cache (\{cache_bytes.length()} B), 0 validation errors",
      )
    } else {
      println(
        "[rhi/pipeline-instancing] FAIL — left=\{left_ok} right=\{right_ok} line=\{line_ok} alpha=\{alpha_ok} premul=\{premul_ok} mult=\{mult_ok} revz=\{revz_ok} cache=\{cache_ok} errs=\{errs}/\{errs2}",
      )
    }
  } catch {
    err => println("[rhi/pipeline-instancing] FAIL — \{err}")
  }
}
