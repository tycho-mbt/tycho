// rhi/3d-cube — Rotating 3D cube using pure-MoonBit @tycho:
// depth testing, back-face culling, index buffers, push constants, event queue,
// and GPU memory sub-allocator block sharing.

///|
/// Model-view-projection for a spinning cube, in Vulkan clip space.
fn make_mvp(angle : Float, aspect : Float) -> @tmath.Mat4 {
  let proj = @tmath.perspective_rh(
    @tmath.deg_to_rad(60.0),
    aspect,
    0.1,
    10.0,
    clip=@tmath.ClipSpace::Vulkan,
  )
  let view = @tmath.Mat4::from_translation(@tmath.Vec3::new(0.0, 0.0, -2.2))
  let model = @tmath.Mat4::from_rotation_y(angle) *
    @tmath.Mat4::from_rotation_x(angle * 0.6)
  proj * view * model
}

///|
fn main {
  try {
    let opts = @exwin.Options::parse("rhi/3d-cube")
    let show_win = opts.window
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("Tycho RHI 3D Cube", validation=true, headless=!show_win),
    )
    let vert = @tycho.compile_glsl(
      "examples/rhi/3d-cube/shader.vert",
      @tycho.ShaderStage::Vertex,
    )
    let frag = @tycho.compile_glsl(
      "examples/rhi/3d-cube/shader.frag",
      @tycho.ShaderStage::Fragment,
    )

    // 24 vertices (4 per face, unique normals/colors), CCW winding when viewed from outside
    let verts : FixedArray[Float] = [
      // +Z front face (Red)
      -0.5, -0.5, 0.5, 1.0, 0.1, 0.1,
      0.5, -0.5, 0.5, 1.0, 0.1, 0.1,
      0.5, 0.5, 0.5, 1.0, 0.1, 0.1,
      -0.5, 0.5, 0.5, 1.0, 0.1, 0.1,
      // -Z back face (Blue)
      0.5, -0.5, -0.5, 0.1, 0.1, 1.0,
      -0.5, -0.5, -0.5, 0.1, 0.1, 1.0,
      -0.5, 0.5, -0.5, 0.1, 0.1, 1.0,
      0.5, 0.5, -0.5, 0.1, 0.1, 1.0,
      // +X right face (Green)
      0.5, -0.5, 0.5, 0.1, 0.9, 0.2,
      0.5, -0.5, -0.5, 0.1, 0.9, 0.2,
      0.5, 0.5, -0.5, 0.1, 0.9, 0.2,
      0.5, 0.5, 0.5, 0.1, 0.9, 0.2,
      // -X left face (Yellow)
      -0.5, -0.5, -0.5, 0.9, 0.9, 0.1,
      -0.5, -0.5, 0.5, 0.9, 0.9, 0.1,
      -0.5, 0.5, 0.5, 0.9, 0.9, 0.1,
      -0.5, 0.5, -0.5, 0.9, 0.9, 0.1,
      // +Y top face (Cyan)
      -0.5, 0.5, 0.5, 0.1, 0.9, 0.9,
      0.5, 0.5, 0.5, 0.1, 0.9, 0.9,
      0.5, 0.5, -0.5, 0.1, 0.9, 0.9,
      -0.5, 0.5, -0.5, 0.1, 0.9, 0.9,
      // -Y bottom face (Magenta)
      -0.5, -0.5, -0.5, 0.9, 0.1, 0.9,
      0.5, -0.5, -0.5, 0.9, 0.1, 0.9,
      0.5, -0.5, 0.5, 0.9, 0.1, 0.9,
      -0.5, -0.5, 0.5, 0.9, 0.1, 0.9,
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

    let mut blocks = 0
    let mut allocs = 0
    let mut pixels : FixedArray[Byte] = []
    let mut frames = 0
    let mut is_bgra = false
    if show_win {
      let sc = @exwin_rhi.open(dev, opts, depth=true)
      is_bgra = sc.color_format() == @tycho.TextureFormat::BGRA8
      let pipe = sc.create_pipeline_desc(
        @tycho.PipelineDesc::new(
          vert,
          frag,
          vertex_formats=[@tycho.VertexFormat::Float3, @tycho.VertexFormat::Float3],
          push_constant_size=64,
          depth_test=true,
          depth_write=true,
          cull_mode=@tycho.CullMode::Back,
          front_face=@tycho.FrontFace::CounterClockwise,
        ),
      )
      while @exwin_rhi.next_frame(sc) {
        let angle : Float = if frames == 0 {
          (0.0 : Float)
        } else {
          Float::from_int(frames) * (0.03 : Float)
        }
        let aspect = Float::from_int(sc.width()) / Float::from_int(sc.height())
        let mvp = make_mvp(angle, aspect)
        let cmd = sc.begin_frame()
        cmd.bind_pipeline(pipe)
        cmd.push_constants_mat4(pipe, mvp)
        cmd.bind_vertex(0, vbuf)
        cmd.bind_index(ibuf, @tycho.IndexType::Uint16)
        cmd.draw_indexed(36)
        sc.end_frame(cmd)
        if frames == 0 {
          pixels = sc.readback()
          opts.capture(800, 600, pixels, bgra=is_bgra)
        }
        frames = frames + 1
      }
      let (sb, sa) = dev.allocator_stats()
      blocks = sb
      allocs = sa
      pipe.destroy()
      sc.destroy()
    } else {
      let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8)
      let depth_rt = dev.create_depth_texture_format(800, 600, @tycho.TextureFormat::Depth32F)
      let pipe = dev.create_graphics_pipeline(
        @tycho.PipelineDesc::new(
          vert,
          frag,
          vertex_formats=[@tycho.VertexFormat::Float3, @tycho.VertexFormat::Float3],
          push_constant_size=64,
          depth_test=true,
          depth_write=true,
          depth_format=Some(@tycho.TextureFormat::Depth32F),
          cull_mode=@tycho.CullMode::Back,
          front_face=@tycho.FrontFace::CounterClockwise,
          color_format=Some(@tycho.TextureFormat::RGBA8),
        ),
      )
      let mvp0 = make_mvp((0.0 : Float), (800.0 : Float) / (600.0 : Float))
      let cmd = dev.begin_commands()
      cmd.begin_render_pass(
        [@tycho.RenderTargetDesc::new(rt, clear_color=@tycho.ClearColor::rgba(0.08, 0.08, 0.12, 1.0))],
        depth=Some(@tycho.DepthTargetDesc::new(depth_rt)),
      )
      cmd.bind_pipeline(pipe)
      cmd.push_constants_mat4(pipe, mvp0)
      cmd.bind_vertex(0, vbuf)
      cmd.bind_index(ibuf, @tycho.IndexType::Uint16)
      cmd.draw_indexed(36)
      cmd.end_render_pass()
      dev.end_commands(cmd)
      pixels = rt.readback()
      frames = 1
      if opts.screenshot != "" {
        let mvp_s = make_mvp((0.55 : Float), (800.0 : Float) / (600.0 : Float))
        let cmd_s = dev.begin_commands()
        cmd_s.begin_render_pass(
          [@tycho.RenderTargetDesc::new(rt, clear_color=@tycho.ClearColor::rgba(0.08, 0.08, 0.12, 1.0))],
          depth=Some(@tycho.DepthTargetDesc::new(depth_rt)),
        )
        cmd_s.bind_pipeline(pipe)
        cmd_s.push_constants_mat4(pipe, mvp_s)
        cmd_s.bind_vertex(0, vbuf)
        cmd_s.bind_index(ibuf, @tycho.IndexType::Uint16)
        cmd_s.draw_indexed(36)
        cmd_s.end_render_pass()
        dev.end_commands(cmd_s)
        opts.capture(800, 600, rt.readback())
      }
      let (hb, ha) = dev.allocator_stats()
      blocks = hb
      allocs = ha
      pipe.destroy()
      depth_rt.destroy()
      rt.destroy()
    }

    let c = (300 * 800 + 400) * 4
    let (r, g, b) = if is_bgra {
      (pixels[c + 2].to_int(), pixels[c + 1].to_int(), pixels[c].to_int())
    } else {
      (pixels[c].to_int(), pixels[c + 1].to_int(), pixels[c + 2].to_int())
    }
    let errs = dev.validation_errors()
    ibuf.destroy()
    vbuf.destroy()
    dev.destroy()
    println(
      "[rhi/3d-cube] centre RGB=(\{r},\{g},\{b}) allocator=(blocks=\{blocks}, allocs=\{allocs}) frames=\{frames}",
    )
    if r > 200 && g < 60 && b < 60 && blocks <= 2 && allocs >= 3 && errs == 0 {
      println(
        "[rhi/3d-cube] OK — 3D cube rendered with depth+cull+index+push_constants, shared sub-allocator blocks, 0 validation errors",
      )
    } else {
      println(
        "[rhi/3d-cube] FAIL — rgb=(\{r},\{g},\{b}) blocks=\{blocks} allocs=\{allocs} errs=\{errs}",
      )
    }
  } catch {
    err => println("[rhi/3d-cube] FAIL — \{err}")
  }
}
