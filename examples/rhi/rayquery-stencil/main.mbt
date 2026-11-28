// rhi/rayquery-stencil — StencilState + draw_indirect_count + Inline Ray Query (BLAS/TLAS):
// 1. Stencil masking: write stencil=1 on center quad, then masked fullscreen quad via set_stencil_reference(1)
// 2. draw_indirect_count: 2 commands in Indirect buffer, count_buffer=1 -> draws only command #0
// 3. Inline Ray Query (capability-gated): BLAS + TLAS + auto-reflected compute shader tracing rays

///|
fn main {
  try {
    let opts = @exwin.Options::parse("rhi/rayquery-stencil")
    let show_win = opts.window
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "rhi/rayquery-stencil",
        validation=true,
        headless=!show_win,
      ),
    )

    // --- 1. Stencil masking test (800x600 RGBA8 + Depth24Stencil8) ---
    let vert = @tycho.compile_glsl(
      "examples/rhi/rayquery-stencil/tri.vert",
      @tycho.ShaderStage::Vertex,
    )
    let frag = @tycho.compile_glsl(
      "examples/rhi/rayquery-stencil/tri.frag",
      @tycho.ShaderStage::Fragment,
    )
    let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8)
    let ds = dev.create_depth_texture_format(
      800,
      600,
      @tycho.TextureFormat::Depth24Stencil8,
    )

    // Quad 0..5: center mask [-0.5, 0.5], Quad 6..11: fullscreen [-1, 1]
    // Plus triangle 12..14 (left) & 15..17 (right) for draw_indirect_count
    let vdata : FixedArray[Float] = [
      -0.5, -0.5, 0.5, -0.5, 0.5, 0.5, -0.5, -0.5, 0.5, 0.5, -0.5, 0.5,
      -1.0, -1.0, 1.0, -1.0, 1.0, 1.0, -1.0, -1.0, 1.0, 1.0, -1.0, 1.0,
      -0.9, -0.2, -0.4, -0.2, -0.65, 0.4,
       0.4, -0.2,  0.9, -0.2,  0.65, 0.4,
    ]
    let vbuf = dev.create_buffer_with(
      vdata.length() * 4,
      @tycho.BufferKind::Vertex,
      location=@tycho.MemoryLocation::GpuOnly,
    )
    vbuf.upload_floats(vdata)

    let st_write = @tycho.StencilState::new(
      front=@tycho.StencilFaceState::new(
        pass_op=@tycho.StencilOp::Replace,
        compare_op=@tycho.CompareOp::Always,
      ),
      back=@tycho.StencilFaceState::new(
        pass_op=@tycho.StencilOp::Replace,
        compare_op=@tycho.CompareOp::Always,
      ),
      reference=(1 : UInt32),
    )
    let pipe_write = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::from_spirv(
        vert,
        frag,
        color_format=@tycho.TextureFormat::RGBA8,
        depth_format=@tycho.TextureFormat::Depth24Stencil8,
        stencil=st_write,
      ),
    )

    let st_test = @tycho.StencilState::new(
      front=@tycho.StencilFaceState::new(
        compare_op=@tycho.CompareOp::Equal,
      ),
      back=@tycho.StencilFaceState::new(
        compare_op=@tycho.CompareOp::Equal,
      ),
      write_mask=(0 : UInt32),
      reference=(0 : UInt32),
    )
    let pipe_test = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::from_spirv(
        vert,
        frag,
        color_format=@tycho.TextureFormat::RGBA8,
        depth_format=@tycho.TextureFormat::Depth24Stencil8,
        stencil=st_test,
      ),
    )

    let cmd = dev.begin_commands()
    cmd.begin_render_pass(
      [
        @tycho.RenderTargetDesc::new(
          rt,
          load_op=@tycho.LoadOp::Clear,
          store_op=@tycho.StoreOp::Store,
          clear_color=@tycho.ClearColor::black(),
        ),
      ],
      depth=
        @tycho.DepthTargetDesc::new(
          ds,
          load_op=@tycho.LoadOp::Clear,
          store_op=@tycho.StoreOp::DontCare,
          stencil_load_op=@tycho.LoadOp::Clear,
          stencil_store_op=@tycho.StoreOp::Store,
          clear_stencil=0,
        )
      ,
    )
    cmd.set_viewport(0.0, 0.0, 800.0, 600.0)
    cmd.set_scissor(0, 0, 800, 600)
    cmd.bind_vertex(0, vbuf)
    cmd.bind_pipeline(pipe_write)
    cmd.push_constants_floats(pipe_write, [(0.0 : Float), (0.0 : Float), (0.0 : Float), (1.0 : Float)])
    cmd.draw_instanced(6, 1, 0, 0)
    cmd.bind_pipeline(pipe_test)
    cmd.set_stencil_reference(1)
    cmd.push_constants_floats(pipe_test, [(0.95 : Float), (0.55 : Float), (0.15 : Float), (1.0 : Float)])
    cmd.draw_instanced(6, 1, 6, 0)
    cmd.end_render_pass()
    dev.end_commands(cmd)

    let st_px = rt.readback()
    let center_idx = (300 * 800 + 400) * 4
    let corner_idx = (10 * 800 + 10) * 4
    let stencil_ok = st_px[center_idx].to_int() > 220 &&
      st_px[center_idx + 1].to_int() > 110 &&
      st_px[corner_idx].to_int() < 5 &&
      st_px[corner_idx + 1].to_int() < 5

    // --- 2. draw_indirect_count test ---
    let ind_buf = dev.create_buffer(32, @tycho.BufferKind::Indirect)
    ind_buf.upload_uint32([
      (3 : UInt32), (1 : UInt32), (12 : UInt32), (0 : UInt32),
      (3 : UInt32), (1 : UInt32), (15 : UInt32), (0 : UInt32),
    ])
    let cnt_buf = dev.create_buffer(4, @tycho.BufferKind::Indirect)
    cnt_buf.upload_uint32([(1 : UInt32)])
    let pipe_plain = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::from_spirv(
        vert,
        frag,
        color_format=@tycho.TextureFormat::RGBA8,
      ),
    )
    let mut indirect_count_ok = true
    let mut ic_ran = false
    if dev.capabilities().supports_indirect_draw {
      ic_ran = true
      let cmd2 = dev.begin_commands()
      cmd2.begin_render_pass([
        @tycho.RenderTargetDesc::new(
          rt,
          load_op=@tycho.LoadOp::Clear,
          store_op=@tycho.StoreOp::Store,
          clear_color=@tycho.ClearColor::black(),
        ),
      ])
      cmd2.set_viewport(0.0, 0.0, 800.0, 600.0)
      cmd2.set_scissor(0, 0, 800, 600)
      cmd2.bind_vertex(0, vbuf)
      cmd2.bind_pipeline(pipe_plain)
      cmd2.push_constants_floats(pipe_plain, [(0.2 : Float), (0.9 : Float), (0.3 : Float), (1.0 : Float)])
      cmd2.draw_indirect_count(ind_buf, cnt_buf, 2)
      cmd2.end_render_pass()
      dev.end_commands(cmd2)

      let ic_px = rt.readback()
      // Left triangle centroid ~(x=-0.65, y=0.0) -> px ~ (140, 300); Right ~(x=0.65, y=0.0) -> px ~ (660, 300)
      let left_idx = (300 * 800 + 140) * 4
      let right_idx = (300 * 800 + 660) * 4
      indirect_count_ok = ic_px[left_idx + 1].to_int() > 200 &&
        ic_px[right_idx + 1].to_int() < 5
    }

    // --- 3. Inline Ray Query (BLAS + TLAS + Compute) ---
    let mut rq_ok = true
    let mut rq_ran = false
    let present_tex = if dev.capabilities().supports_ray_query {
      rq_ran = true
      let comp = @tycho.compile_glsl(
        "examples/rhi/rayquery-stencil/rq.comp",
        @tycho.ShaderStage::Compute,
      )
      let rq_pipe = dev.create_compute_pipeline_auto(comp)
      let rq_vbuf = dev.create_buffer_with(
        36,
        @tycho.BufferKind::Vertex,
        location=@tycho.MemoryLocation::GpuOnly,
      )
      rq_vbuf.upload_floats([
        (-0.7 : Float), (-0.6 : Float), (0.0 : Float),
        ( 0.7 : Float), (-0.6 : Float), (0.0 : Float),
        ( 0.0 : Float), ( 0.7 : Float), (0.0 : Float),
      ])
      let rq_ibuf = dev.create_buffer_with(
        12,
        @tycho.BufferKind::Index,
        location=@tycho.MemoryLocation::GpuOnly,
      )
      rq_ibuf.upload_uint32([(0 : UInt32), (1 : UInt32), (2 : UInt32)])
      let blas = dev.create_blas([
        @tycho.RayGeometryDesc::new(
          rq_vbuf,
          3,
          index_buffer=rq_ibuf,
          index_count=3,
        ),
      ])
      let tlas = dev.create_tlas([@tycho.RayInstanceDesc::from_affine3(blas, @tmath.Affine3::identity())])
      let rq_img = dev.create_storage_texture(800, 600, @tycho.TextureFormat::RGBA8)

      let ccmd = dev.begin_commands()
      ccmd.bind_pipeline(rq_pipe)
      ccmd.bind_accel_struct(rq_pipe, 0, tlas)
      ccmd.bind_storage_image(rq_pipe, 0, rq_img)
      ccmd.dispatch(100, 75, 1)
      ccmd.transition_for_sampling(rq_img)
      dev.end_commands(ccmd)

      let rpx = rq_img.readback()
      let rq_mid = (300 * 800 + 400) * 4
      let rq_cor = (8 * 800 + 8) * 4
      // Triangle hit has barycentric RGB > 50, miss corner is dark blue (b > r && r < 40)
      rq_ok = rpx[rq_mid].to_int() + rpx[rq_mid + 1].to_int() + rpx[rq_mid + 2].to_int() > 200 &&
        rpx[rq_cor].to_int() < 35 &&
        rpx[rq_cor + 2].to_int() > rpx[rq_cor].to_int()
      opts.capture(800, 600, rpx)
      tlas.destroy()
      blas.destroy()
      rq_ibuf.destroy()
      rq_vbuf.destroy()
      rq_pipe.destroy()
      Some(rq_img)
    } else {
      opts.capture(800, 600, st_px)
      None
    }

    if show_win {
      let sc = @exwin_rhi.open(dev, opts)
      let disp_tex = match present_tex {
        Some(t) => t
        None => rt
      }
      while @exwin_rhi.next_frame(sc) {
        sc.present_texture(disp_tex)
      }
      sc.destroy()
    }

    match present_tex {
      Some(t) => t.destroy()
      None => ()
    }
    pipe_plain.destroy()
    cnt_buf.destroy()
    ind_buf.destroy()
    pipe_test.destroy()
    pipe_write.destroy()
    vbuf.destroy()
    ds.destroy()
    rt.destroy()
    dev.wait_idle()

    let errs = dev.validation_errors()
    let used = dev.allocator_used_bytes()
    dev.destroy()

    if stencil_ok && indirect_count_ok && rq_ok && errs == 0 && used == (0 : UInt64) {
      let ic_str = if ic_ran { "draw_indirect_count=OK" } else { "draw_indirect_count=skipped" }
      let rq_str = if rq_ran { "ray_query=OK" } else { "ray_query=skipped" }
      println(
        "[rhi/rayquery-stencil] OK — stencil=OK, \{ic_str}, \{rq_str} (0 validation errors)",
      )
    } else {
      println(
        "[rhi/rayquery-stencil] FAIL — stencil_ok=\{stencil_ok} indirect_count_ok=\{indirect_count_ok} rq_ok=\{rq_ok} errs=\{errs} used=\{used}",
      )
    }
  } catch {
    e => println("[rhi/rayquery-stencil] FAIL — \{e}")
  }
}
