// rhi/mrt-postprocess — Multiple Render Targets (MRT) G-Buffer + Deferred Lighting Composite
// using pure-MoonBit @tycho:
//   Pass 1: Offscreen MRT (albedo RGBA8 + world normal RGBA8 + Depth32F) timed via TimestampPool,
//           auto-reflected via PipelineDesc::from_spirv (3 vertex inputs, 64B push constant, 2 color targets).
//   Pass 2: Fullscreen deferred directional lighting sampling both G-Buffer textures to swapchain.

///|
/// Model-view-projection for the spinning cube, in Vulkan clip space.
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
    @tmath.Mat4::from_rotation_x(angle * 0.5)
  proj * view * model
}

///|
fn main {
  try {
    let opts = @exwin.Options::parse("rhi/mrt-postprocess")
    let show_win = opts.window
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "Tycho RHI MRT Deferred",
        validation=true,
        headless=!show_win,
      ),
    )

    let albedo_rt = dev.create_render_target(
      256,
      256,
      @tycho.TextureFormat::RGBA8,
    )
    let normal_rt = dev.create_render_target(
      256,
      256,
      @tycho.TextureFormat::RGBA8,
    )
    let depth_rt = dev.create_depth_texture(256, 256)
    let ts = dev.create_timestamp_pool(2)

    let gvert = @tycho.compile_glsl(
      "examples/rhi/mrt-postprocess/gbuffer.vert",
      @tycho.ShaderStage::Vertex,
    )
    let gfrag = @tycho.compile_glsl(
      "examples/rhi/mrt-postprocess/gbuffer.frag",
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
      "examples/rhi/mrt-postprocess/composite.vert",
      @tycho.ShaderStage::Vertex,
    )
    let cfrag = @tycho.compile_glsl(
      "examples/rhi/mrt-postprocess/composite.frag",
      @tycho.ShaderStage::Fragment,
    )
    let comp_desc = @tycho.PipelineDesc::from_spirv(cvert, cfrag)
    let comp_refl_ok = comp_desc.texture_slots == 2 &&
      comp_desc.texture_bindings.length() == 2 &&
      comp_desc.texture_bindings[0] == 0 &&
      comp_desc.texture_bindings[1] == 1
    let samp = dev.create_sampler()

    // 24 cube vertices: (vec3 pos, vec3 normal, vec3 albedo)
    let verts : FixedArray[Float] = [
      // +Z front (Red albedo, normal +Z)
      -0.5, -0.5, 0.5, 0.0, 0.0, 1.0, 1.0, 0.2, 0.2, 0.5, -0.5, 0.5, 0.0, 0.0, 1.0,
      1.0, 0.2, 0.2, 0.5, 0.5, 0.5, 0.0, 0.0, 1.0, 1.0, 0.2, 0.2, -0.5, 0.5, 0.5,
      0.0, 0.0, 1.0, 1.0, 0.2, 0.2,
      // -Z back (Blue albedo, normal -Z)
       0.5, -0.5, -0.5, 0.0, 0.0, -1.0, 0.2, 0.3, 1.0, -0.5, -0.5, -0.5, 0.0, 0.0,
      -1.0, 0.2, 0.3, 1.0, -0.5, 0.5, -0.5, 0.0, 0.0, -1.0, 0.2, 0.3, 1.0, 0.5, 0.5,
      -0.5, 0.0, 0.0, -1.0, 0.2, 0.3, 1.0,
      // +X right (Green albedo, normal +X)
       0.5, -0.5, 0.5, 1.0, 0.0, 0.0, 0.2, 0.9, 0.3, 0.5, -0.5, -0.5, 1.0, 0.0, 0.0,
      0.2, 0.9, 0.3, 0.5, 0.5, -0.5, 1.0, 0.0, 0.0, 0.2, 0.9, 0.3, 0.5, 0.5, 0.5,
      1.0, 0.0, 0.0, 0.2, 0.9, 0.3,
      // -X left (Yellow albedo, normal -X)
       -0.5, -0.5, -0.5, -1.0, 0.0, 0.0, 0.9, 0.9, 0.2, -0.5, -0.5, 0.5, -1.0, 0.0,
      0.0, 0.9, 0.9, 0.2, -0.5, 0.5, 0.5, -1.0, 0.0, 0.0, 0.9, 0.9, 0.2, -0.5, 0.5,
      -0.5, -1.0, 0.0, 0.0, 0.9, 0.9, 0.2,
      // +Y top (Cyan albedo, normal +Y)
       -0.5, 0.5, 0.5, 0.0, 1.0, 0.0, 0.2, 0.9, 0.9, 0.5, 0.5, 0.5, 0.0, 1.0, 0.0,
      0.2, 0.9, 0.9, 0.5, 0.5, -0.5, 0.0, 1.0, 0.0, 0.2, 0.9, 0.9, -0.5, 0.5, -0.5,
      0.0, 1.0, 0.0, 0.2, 0.9, 0.9,
      // -Y bottom (Magenta albedo, normal -Y)
       -0.5, -0.5, -0.5, 0.0, -1.0, 0.0, 0.9, 0.2, 0.9, 0.5, -0.5, -0.5, 0.0, -1.0,
      0.0, 0.9, 0.2, 0.9, 0.5, -0.5, 0.5, 0.0, -1.0, 0.0, 0.9, 0.2, 0.9, -0.5, -0.5,
      0.5, 0.0, -1.0, 0.0, 0.9, 0.2, 0.9,
    ]
    let indices : FixedArray[UInt16] = [
      0, 1, 2, 0, 2, 3, 4, 5, 6, 4, 6, 7, 8, 9, 10, 8, 10, 11, 12, 13, 14, 12, 14,
      15, 16, 17, 18, 16, 18, 19, 20, 21, 22, 20, 22, 23,
    ]
    let vbuf = dev.create_buffer(verts.length() * 4, @tycho.BufferKind::Vertex)
    vbuf.upload_floats(verts)
    let ibuf = dev.create_buffer(indices.length() * 2, @tycho.BufferKind::Index)
    ibuf.upload_uint16(indices)

    // Pass 1 + Pass 2 in a single command buffer per frame (no mid-frame vkQueueWaitIdle)
    let mvp0 = make_mvp((0.0 : Float), (1.0 : Float))
    let mut pixels : FixedArray[Byte] = []
    let mut gbuf_ms = 0.0
    let mut frames = 0
    let mut is_bgra = false
    if show_win {
      let sc = @exwin_rhi.open(dev, opts)
      is_bgra = sc.color_format() == @tycho.TextureFormat::BGRA8
      let comp_pipe = sc.create_pipeline_desc(comp_desc)
      while @exwin_rhi.next_frame(sc) {
        let angle : Float = if frames == 0 {
          (0.0 : Float)
        } else {
          Float::from_int(frames) * (0.03 : Float)
        }
        let mvp = make_mvp(angle, (1.0 : Float))
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
          depth=@tycho.DepthTargetDesc::new(depth_rt),
        )
        cmd.bind_pipeline(gbuf_pipe)
        cmd.push_constants_mat4(gbuf_pipe, mvp)
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
          opts.capture(800, 600, pixels, bgra=is_bgra)
        }
        frames = frames + 1
      }
      comp_pipe.destroy()
      sc.destroy()
    } else {
      let final_rt = dev.create_render_target(
        800,
        600,
        @tycho.TextureFormat::RGBA8,
      )
      let comp_pipe = dev.create_graphics_pipeline(
        @tycho.PipelineDesc::from_spirv(
          cvert,
          cfrag,
          color_format=@tycho.TextureFormat::RGBA8,
        ),
      )
      let cmd = dev.begin_commands()
      cmd.reset_timestamps(ts)
      cmd.write_timestamp(ts, 0, at_start=true)
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
        depth=@tycho.DepthTargetDesc::new(depth_rt),
      )
      cmd.bind_pipeline(gbuf_pipe)
      cmd.push_constants_mat4(gbuf_pipe, mvp0)
      cmd.bind_vertex(0, vbuf)
      cmd.bind_index(ibuf, @tycho.IndexType::Uint16)
      cmd.draw_indexed(36)
      cmd.end_render_pass()
      cmd.write_timestamp(ts, 1)
      cmd.begin_render_pass([@tycho.RenderTargetDesc::new(final_rt)])
      cmd.bind_pipeline(comp_pipe)
      cmd.bind_texture(comp_pipe, 0, albedo_rt, samp)
      cmd.bind_texture(comp_pipe, 1, normal_rt, samp)
      cmd.draw(6, 1)
      cmd.end_render_pass()
      dev.end_commands(cmd)
      pixels = final_rt.readback()
      gbuf_ms = ts.elapsed_ms(0, 1)
      frames = 1
      if opts.screenshot != "" {
        let mvp_s = make_mvp((0.55 : Float), (1.0 : Float))
        let cmd_s = dev.begin_commands()
        cmd_s.begin_render_pass(
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
          depth=@tycho.DepthTargetDesc::new(depth_rt),
        )
        cmd_s.bind_pipeline(gbuf_pipe)
        cmd_s.push_constants_mat4(gbuf_pipe, mvp_s)
        cmd_s.bind_vertex(0, vbuf)
        cmd_s.bind_index(ibuf, @tycho.IndexType::Uint16)
        cmd_s.draw_indexed(36)
        cmd_s.end_render_pass()
        cmd_s.begin_render_pass([@tycho.RenderTargetDesc::new(final_rt)])
        cmd_s.bind_pipeline(comp_pipe)
        cmd_s.bind_texture(comp_pipe, 0, albedo_rt, samp)
        cmd_s.bind_texture(comp_pipe, 1, normal_rt, samp)
        cmd_s.draw(6, 1)
        cmd_s.end_render_pass()
        dev.end_commands(cmd_s)
        opts.capture(800, 600, final_rt.readback())
        // Restore frame 0 G-buffer state so albedo_rt/normal_rt checks match
        let cmd_r = dev.begin_commands()
        cmd_r.begin_render_pass(
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
          depth=@tycho.DepthTargetDesc::new(depth_rt),
        )
        cmd_r.bind_pipeline(gbuf_pipe)
        cmd_r.push_constants_mat4(gbuf_pipe, mvp0)
        cmd_r.bind_vertex(0, vbuf)
        cmd_r.bind_index(ibuf, @tycho.IndexType::Uint16)
        cmd_r.draw_indexed(36)
        cmd_r.end_render_pass()
        dev.end_commands(cmd_r)
      }
      comp_pipe.destroy()
      final_rt.destroy()
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
    let (sr, sg, sb) = if is_bgra {
      (pixels[c + 2].to_int(), pixels[c + 1].to_int(), pixels[c].to_int())
    } else {
      (pixels[c].to_int(), pixels[c + 1].to_int(), pixels[c + 2].to_int())
    }
    let lit_ok = sr > 150 && sr > sg + 80 && sr > sb + 80
    let errs = dev.validation_errors()

    ibuf.destroy()
    vbuf.destroy()
    samp.destroy()
    gbuf_pipe.destroy()
    ts.destroy()
    depth_rt.destroy()
    normal_rt.destroy()
    albedo_rt.destroy()
    dev.destroy()

    println(
      "[rhi/mrt-postprocess] refl=(mrt:\{mrt_refl_ok},comp:\{comp_refl_ok}) gbuf_ms=\{gbuf_ms} albedo=(\{ar},\{ag},\{ab}) normal=(\{nr},\{ng},\{nb}) lit=(\{sr},\{sg},\{sb}) frames=\{frames}",
    )
    if mrt_refl_ok &&
      comp_refl_ok &&
      gbuf_ok &&
      lit_ok &&
      gbuf_ms >= 0.0 &&
      errs == 0 {
      println(
        "[rhi/mrt-postprocess] OK — 2-target MRT G-Buffer + deferred lighting composite in \{gbuf_ms} ms, 0 validation errors",
      )
    } else {
      println(
        "[rhi/mrt-postprocess] FAIL — mrt_refl=\{mrt_refl_ok} comp_refl=\{comp_refl_ok} gbuf_ok=\{gbuf_ok} lit_ok=\{lit_ok} errs=\{errs}",
      )
    }
  } catch {
    err => println("[rhi/mrt-postprocess] FAIL — \{err}")
  }
}
