// Example 44 — RHI v0.4 pipeline state & instanced vertex layouts:
// - Multi-stream VertexBufferLayout (Vertex binding 0 + Instance binding 1)
// - BlendMode::Additive
// - PrimitiveTopology::LineList
// - Device::pipeline_cache_data() round-trip

///|
fn sample_rgb(pixels : FixedArray[Byte], w : Int, x : Int, y : Int) -> (Int, Int, Int) {
  let i = (y * w + x) * 4
  (pixels[i].to_int(), pixels[i + 1].to_int(), pixels[i + 2].to_int())
}

///|
fn main {
  try {
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("Tycho RHI Instancing", validation=true, headless=true),
    )
    let vert = @tycho.compile_glsl(
      "examples/44-rhi-pipeline-instancing/shader.vert",
      @tycho.ShaderStage::Vertex,
    )
    let frag = @tycho.compile_glsl(
      "examples/44-rhi-pipeline-instancing/shader.frag",
      @tycho.ShaderStage::Fragment,
    )

    let layouts = [
      @tycho.VertexBufferLayout::new(
        8,
        [@tycho.VertexAttribute::new(0, @tycho.VertexFormat::Float2, 0)],
        step_mode=@tycho.VertexStepMode::Vertex,
      ),
      @tycho.VertexBufferLayout::new(
        20,
        [
          @tycho.VertexAttribute::new(1, @tycho.VertexFormat::Float2, 0),
          @tycho.VertexAttribute::new(2, @tycho.VertexFormat::Float3, 8),
        ],
        step_mode=@tycho.VertexStepMode::Instance,
      ),
    ]

    let add_pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::from_spirv(
        vert,
        frag,
        blend_mode=Some(@tycho.BlendMode::Additive),
        color_format=Some(@tycho.TextureFormat::RGBA8),
        vertex_layouts=layouts,
      ),
    )
    let line_pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::from_spirv(
        vert,
        frag,
        topology=@tycho.PrimitiveTopology::LineList,
        color_format=Some(@tycho.TextureFormat::RGBA8),
        vertex_layouts=layouts,
      ),
    )

    // Full-quad-covering triangle around origin (in local [-0.4, 0.4])
    let vbuf = dev.create_buffer_with(
      24,
      @tycho.BufferKind::Vertex,
      location=@tycho.MemoryLocation::GpuOnly,
    )
    vbuf.upload_floats([
      (-0.35 : Float), (-0.35 : Float),
      (0.35 : Float), (-0.35 : Float),
      (0.0 : Float), (0.35 : Float),
    ])

    // 3 instances:
    //   0: left (-0.5, 0.0), red (0.8, 0.0, 0.0)
    //   1: right (+0.5, 0.0), blue (0.0, 0.0, 0.8)
    //   2: right (+0.5, 0.0), green (0.0, 0.8, 0.0) -> additive with inst 1 = cyan (0, ~204, ~204)!
    let ibuf = dev.create_buffer_with(
      60,
      @tycho.BufferKind::Vertex,
      location=@tycho.MemoryLocation::GpuOnly,
    )
    ibuf.upload_floats([
      (-0.5 : Float), (0.0 : Float), (0.8 : Float), (0.0 : Float), (0.0 : Float),
      (0.5 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float), (0.8 : Float),
      (0.5 : Float), (0.0 : Float), (0.0 : Float), (0.8 : Float), (0.0 : Float),
    ])

    let rt = dev.create_render_target(200, 200, @tycho.TextureFormat::RGBA8)
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

    // Also exercise LineList topology
    cmd.bind_pipeline(line_pipe)
    cmd.draw(2, 1)
    cmd.end_render_pass()
    dev.end_commands(cmd)

    let px = rt.readback()
    // Left triangle center (~x=50, y=100) should be red
    let (lr, lg, lb) = sample_rgb(px, 200, 50, 100)
    // Right overlapping triangles center (~x=150, y=100) should be additive cyan (G > 150, B > 150, R < 30)
    let (rr, rg, rb) = sample_rgb(px, 200, 150, 100)

    let cache_bytes = dev.pipeline_cache_data()
    let cache_ok = cache_bytes.length() > 0

    // Warm-start a second headless device using the exported pipeline cache
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
        blend_mode=Some(@tycho.BlendMode::Additive),
        color_format=Some(@tycho.TextureFormat::RGBA8),
        vertex_layouts=layouts,
      ),
    )
    let errs2 = dev2.validation_errors()
    warm_pipe.destroy()
    dev2.destroy()

    let errs = dev.validation_errors()
    rt.destroy()
    ibuf.destroy()
    vbuf.destroy()
    line_pipe.destroy()
    add_pipe.destroy()
    dev.destroy()

    let left_ok = lr > 150 && lg < 30 && lb < 30
    let right_ok = rr < 30 && rg > 150 && rb > 150
    println(
      "[44-rhi-pipeline-instancing] left=(\{lr},\{lg},\{lb}) right=(\{rr},\{rg},\{rb}) cache_bytes=\{cache_bytes.length()}",
    )
    if left_ok && right_ok && cache_ok && errs == 0 && errs2 == 0 {
      println(
        "[44-rhi-pipeline-instancing] OK — instanced multi-stream + additive blend + line topology + pipeline cache (\{cache_bytes.length()} B), 0 validation errors",
      )
    } else {
      println(
        "[44-rhi-pipeline-instancing] FAIL — left=\{left_ok} right=\{right_ok} cache=\{cache_ok} errs=\{errs}/\{errs2}",
      )
    }
  } catch {
    err => println("[44-rhi-pipeline-instancing] FAIL — \{err}")
  }
}
