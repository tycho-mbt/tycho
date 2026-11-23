// Example 41 — Auto-reflected compute pipeline (`create_compute_pipeline_auto`),
// storage image (`create_storage_texture` / `bind_storage_image` / `transition_for_sampling`),
// GPU timestamp queries (`TimestampPool`), and graphics presentation.

///|
fn main {
  try {
    let dev = @rhi.Device::new("Tycho RHI Compute Storage Image", true)
    let sc = dev.create_swapchain("Tycho RHI Compute Storage Image", 800, 600)

    let comp_spv = @rhi.compile_glsl(
      "examples/41-rhi-compute-storage-image/gen.comp",
      @rhi.ShaderStage::Compute,
    )
    let cr = @rhi.reflect_spirv(comp_spv)
    let refl_ok = cr.bindings.length() == 1 &&
      cr.bindings[0].binding == 0 &&
      cr.bindings[0].kind == @rhi.ReflectedDescriptorKind::StorageImage &&
      cr.push_constant_size == 16

    let cpipe = dev.create_compute_pipeline_auto(comp_spv)
    let storage_tex = dev.create_storage_texture(
      128,
      128,
      @rhi.TextureFormat::RGBA8,
    )
    let ts = dev.create_timestamp_pool(2)

    let params : FixedArray[Float] = [128.0, 128.0, 0.5, 1.0]
    let ccmd = dev.begin_commands()
    ccmd.reset_timestamps(ts)
    ccmd.write_timestamp(ts, 0, at_start=true)
    ccmd.bind_pipeline(cpipe)
    ccmd.bind_storage_image(cpipe, 0, storage_tex)
    ccmd.push_constants_floats(cpipe, params)
    ccmd.dispatch(16, 16, 1)
    ccmd.write_timestamp(ts, 1)
    ccmd.transition_for_sampling(storage_tex)
    dev.end_commands(ccmd)

    let gpu_ms = ts.elapsed_ms(0, 1)
    let px = storage_tex.readback()
    let p00_r = px[0].to_int()
    let p00_g = px[1].to_int()
    let p00_b = px[2].to_int()
    let i_tr = 127 * 4
    let p10_r = px[i_tr].to_int()
    let p10_g = px[i_tr + 1].to_int()
    let i_bl = 127 * 128 * 4
    let p01_r = px[i_bl].to_int()
    let p01_g = px[i_bl + 1].to_int()
    let i_br = (127 * 128 + 127) * 4
    let p11_r = px[i_br].to_int()
    let p11_g = px[i_br + 1].to_int()
    let grad_ok = p00_r < 15 &&
      p00_g < 15 &&
      p00_b >= 115 &&
      p00_b <= 140 &&
      p10_r > 240 &&
      p10_g < 15 &&
      p01_r < 15 &&
      p01_g > 240 &&
      p11_r > 240 &&
      p11_g > 240

    // Present computed image onto the window via auto-reflected graphics pipeline
    let qvert = @rhi.compile_glsl(
      "examples/41-rhi-compute-storage-image/quad.vert",
      @rhi.ShaderStage::Vertex,
    )
    let qfrag = @rhi.compile_glsl(
      "examples/41-rhi-compute-storage-image/quad.frag",
      @rhi.ShaderStage::Fragment,
    )
    let gpipe = sc.create_pipeline_desc(@rhi.PipelineDesc::from_spirv(qvert, qfrag))
    let samp = dev.create_sampler()

    let start = @rhi.Swapchain::time()
    let mut frames = 0
    while !sc.should_close() && frames < 10 && @rhi.Swapchain::time() - start < 0.8 {
      let cmd = sc.begin_frame()
      cmd.bind_pipeline(gpipe)
      cmd.bind_texture(gpipe, 0, storage_tex, samp)
      cmd.draw(6, 1)
      sc.end_frame(cmd)
      frames = frames + 1
    }

    let errs = dev.validation_errors()
    samp.destroy()
    gpipe.destroy()
    ts.destroy()
    storage_tex.destroy()
    cpipe.destroy()
    sc.destroy()
    dev.destroy()

    println(
      "[41-rhi-compute-storage-image] refl_ok=\{refl_ok} gpu_ms=\{gpu_ms} corners=[(0,0)=(\{p00_r},\{p00_g},\{p00_b}), (127,0)=(\{p10_r},\{p10_g}), (0,127)=(\{p01_r},\{p01_g})] frames=\{frames}",
    )
    if refl_ok && grad_ok && gpu_ms >= 0.0 && errs == 0 {
      println(
        "[41-rhi-compute-storage-image] OK — auto-reflected compute shader wrote 128x128 storage image in \{gpu_ms} ms, 0 validation errors",
      )
    } else {
      println(
        "[41-rhi-compute-storage-image] FAIL — refl_ok=\{refl_ok} grad_ok=\{grad_ok} gpu_ms=\{gpu_ms} errs=\{errs}",
      )
    }
  } catch {
    err => println("[41-rhi-compute-storage-image] FAIL — \{err}")
  }
}
