// rhi/bench — RHI throughput benchmark and memory-leak regression gate:
// 1. SubAllocator stress: 500 interleaved Buffer (256B..64KB) and Texture alloc/destroy cycles
// 2. Draw throughput: 500 push-constant draws in a single dynamic render pass (CPU record ms + GPU timestamp ms)
// 3. Deferred-deletion leak gate: 20 submit_commands + Fence::wait() frames creating/destroying transient resources

///|
fn main {
  try {
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("rhi/bench", validation=true, headless=true),
    )

    // 1. SubAllocator stress: 500 interleaved buffer + texture allocations (varying sizes, rolling live window)
    let alloc_t0 = @env.now()
    let live_bufs : Array[@tycho.Buffer?] = FixedArray::make(8, None) |> Array::from_fixed_array
    let live_texs : Array[@tycho.Texture?] = FixedArray::make(8, None) |> Array::from_fixed_array
    for i = 0; i < 500; i = i + 1 {
      let slot = i % 8
      match live_bufs[slot] {
        Some(b) => {
          b.destroy()
          live_bufs[slot] = None
        }
        None => ()
      }
      match live_texs[slot] {
        Some(t) => {
          t.destroy()
          live_texs[slot] = None
        }
        None => ()
      }
      let size = 256 + (i * 127) % 65280
      let b = dev.create_buffer_with(
        size,
        @tycho.BufferKind::Storage,
        location=@tycho.MemoryLocation::GpuOnly,
      )
      live_bufs[slot] = Some(b)
      let dim = 16 + (i % 4) * 16
      let t = dev.create_render_target(dim, dim, @tycho.TextureFormat::RGBA8)
      live_texs[slot] = Some(t)
      if i % 64 == 63 {
        dev.wait_idle()
      }
    }
    for slot = 0; slot < 8; slot = slot + 1 {
      match live_bufs[slot] {
        Some(b) => b.destroy()
        None => ()
      }
      match live_texs[slot] {
        Some(t) => t.destroy()
        None => ()
      }
    }
    dev.wait_idle()
    let alloc_ms = (@env.now() - alloc_t0).to_int()
    let used_after_alloc = dev.allocator_used_bytes()
    let alloc_ok = used_after_alloc == (0 : UInt64)

    // 2. 500-draw throughput in a single render pass with push constants
    let vert = @tycho.compile_glsl(
      "examples/rhi/bench/shader.vert",
      @tycho.ShaderStage::Vertex,
    )
    let frag = @tycho.compile_glsl(
      "examples/rhi/bench/shader.frag",
      @tycho.ShaderStage::Fragment,
    )
    let rt = dev.create_render_target(64, 64, @tycho.TextureFormat::RGBA8)
    let pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::from_spirv(
        vert,
        frag,
        color_format=@tycho.TextureFormat::RGBA8,
      ),
    )
    let ts = dev.create_timestamp_pool(2)

    let draw_t0 = @env.now()
    let cmd = dev.begin_commands()
    cmd.reset_timestamps(ts)
    cmd.write_timestamp(ts, 0, at_start=true)
    cmd.begin_render_pass(
      [
        @tycho.RenderTargetDesc::new(
          rt,
          load_op=@tycho.LoadOp::Clear,
          store_op=@tycho.StoreOp::Store,
          clear_color=@tycho.ClearColor::black(),
        ),
      ],
    )
    cmd.set_viewport(0.0, 0.0, 64.0, 64.0)
    cmd.set_scissor(0, 0, 64, 64)
    cmd.bind_pipeline(pipe)
    let pc : FixedArray[Float] = [(0.2 : Float), (0.8 : Float), (0.4 : Float), (1.0 : Float)]
    for i = 0; i < 500; i = i + 1 {
      let g = (Float::from_int(i + 1) / (500.0 : Float))
      pc[1] = g
      cmd.push_constants_floats(pipe, pc)
      cmd.draw(6, 1)
    }
    cmd.end_render_pass()
    cmd.write_timestamp(ts, 1)
    let draw_record_ms = (@env.now() - draw_t0).to_int()
    dev.end_commands(cmd)

    let draw_gpu_ms = ts.elapsed_ms(0, 1)
    let px = rt.readback()
    let pixel_ok = px.length() == 64 * 64 * 4 &&
      px[0].to_int() > 35 &&
      px[0].to_int() < 65 &&
      px[1].to_int() > 240 &&
      px[2].to_int() > 90 &&
      px[2].to_int() < 115
    pipe.destroy()
    rt.destroy()
    ts.destroy()
    dev.wait_idle()

    // 3. 20-frame deferred deletion leak gate across Fence::wait()
    let fence = dev.create_fence(false)
    let leak_t0 = @env.now()
    let mut peak_inflight : UInt64 = (0 : UInt64)
    for f = 0; f < 20; f = f + 1 {
      let _ = f
      let tb = dev.create_buffer_with(
        4096,
        @tycho.BufferKind::Storage,
        location=@tycho.MemoryLocation::GpuOnly,
      )
      let tt = dev.create_render_target(32, 32, @tycho.TextureFormat::RGBA8)
      let fcmd = dev.begin_commands()
      fcmd.barrier()
      dev.submit_commands(fcmd, fence)
      tb.destroy()
      tt.destroy()
      let cur = dev.allocator_used_bytes()
      if cur > peak_inflight {
        peak_inflight = cur
      }
      fence.wait()
      fence.reset()
    }
    fence.destroy()
    dev.wait_idle()
    let leak_ms = (@env.now() - leak_t0).to_int()
    let used_after_leak = dev.allocator_used_bytes()
    let leak_ok = peak_inflight > (0 : UInt64) && used_after_leak == (0 : UInt64)

    let (blocks, allocs) = dev.allocator_stats()
    let errs = dev.validation_errors()
    dev.destroy()

    if alloc_ok && pixel_ok && leak_ok && errs == 0 {
      println(
        "[rhi/bench] OK — 500 allocs (\{alloc_ms} ms), 500 draws (cpu=\{draw_record_ms} ms, gpu=\{draw_gpu_ms} ms), 20 deferred-delete frames (\{leak_ms} ms, blocks=\{blocks}, allocs=\{allocs}, used_bytes=\{used_after_leak}, \{errs} validation errors)",
      )
    } else {
      println(
        "[rhi/bench] FAIL — alloc_ok=\{alloc_ok} (used=\{used_after_alloc}) pixel_ok=\{pixel_ok} leak_ok=\{leak_ok} (peak=\{peak_inflight}, used=\{used_after_leak}) errs=\{errs}",
      )
    }
  } catch {
    e => println("[rhi/bench] FAIL — \{e}")
  }
}
