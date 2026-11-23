// Example 12 — RHI compute + copy + fence, headless (no window/swapchain).
// A compute shader fills a storage buffer; a copy moves it to a second buffer;
// a fence synchronizes; values are verified in MoonBit.

///|
fn float_at(data : Bytes, i : Int) -> Float {
  let bits = data[i * 4].to_int() |
    (data[i * 4 + 1].to_int() << 8) |
    (data[i * 4 + 2].to_int() << 16) |
    (data[i * 4 + 3].to_int() << 24)
  Float::reinterpret_from_int(bits)
}

///|
fn main {
  try {
    let dev = @rhi.Device::new("Tycho RHI Compute", true)
    let spv = @rhi.compile_glsl(
      "examples/12-rhi-compute/shader.comp",
      @rhi.ShaderStage::Compute,
    )
    let pipe = dev.create_compute_pipeline(spv, 0, 1)
    let src = dev.create_buffer(64, @rhi.BufferKind::Storage)
    let dst = dev.create_buffer(64, @rhi.BufferKind::Storage)
    let fence = dev.create_fence(false)
    let cmd = dev.begin_commands()
    cmd.bind_pipeline(pipe)
    cmd.bind_storage(pipe, 0, src)
    cmd.dispatch(16, 1, 1)
    cmd.barrier()
    cmd.copy_buffer(src, dst, 64)
    dev.submit_commands(cmd, fence)
    fence.wait()
    let data = dst.download()
    let mut ok = true
    for i = 0; i < 16; i = i + 1 {
      let expected = Float::from_int(i) * (2.0 : Float)
      if float_at(data, i) != expected {
        ok = false
      }
    }
    println(
      "[12-rhi-compute] values[0..3] = \{float_at(data, 0)}, \{float_at(data, 1)}, \{float_at(data, 2)}, \{float_at(data, 3)}",
    )
    let errs = dev.validation_errors()
    fence.destroy()
    dst.destroy()
    src.destroy()
    pipe.destroy()
    dev.destroy()
    if ok && errs == 0 {
      println(
        "[12-rhi-compute] OK — compute wrote, copy moved, fence synced, all 16 values match (0 validation errors)",
      )
    } else {
      println("[12-rhi-compute] FAIL — ok=\{ok} validation_errors=\{errs}")
    }
  } catch {
    err => println("[12-rhi-compute] FAIL — \{err}")
  }
}
