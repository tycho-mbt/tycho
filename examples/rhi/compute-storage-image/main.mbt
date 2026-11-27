// rhi/compute-storage-image — Auto-reflected compute pipeline (`create_compute_pipeline_auto`),
// storage image (`create_storage_texture` / `bind_storage_image` / `transition_for_sampling`),
// and GPU timestamp queries (`TimestampPool`). Default headless; pass `--window` for screen.

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
        "Tycho RHI Compute Storage Image",
        validation=true,
        headless=!show_win,
      ),
    )

    let comp_spv = @tycho.compile_glsl(
      "examples/rhi/compute-storage-image/gen.comp",
      @tycho.ShaderStage::Compute,
    )
    let cr = @tycho.reflect_spirv(comp_spv)
    let refl_ok = cr.bindings.length() == 1 &&
      cr.bindings[0].binding == 0 &&
      cr.bindings[0].kind == @tycho.ReflectedDescriptorKind::StorageImage &&
      cr.push_constant_size == 16

    let cpipe = dev.create_compute_pipeline_auto(comp_spv)
    let storage_tex = dev.create_storage_texture(
      128,
      128,
      @tycho.TextureFormat::RGBA8,
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
    if shot != "" {
      let _ = @tycho.save_png(shot, 128, 128, px)
    }
    let p00_r = px[0].to_int()
    let p00_g = px[1].to_int()
    let p00_b = px[2].to_int()
    let i_tr = 127 * 4
    let p10_r = px[i_tr].to_int()
    let p10_g = px[i_tr + 1].to_int()
    let i_bl = 127 * 128 * 4
    let p01_r = px[i_bl].to_int()
    let p01_g = px[i_bl + 1].to_int()
    let grad_ok = p00_r < 15 &&
      p00_g < 15 &&
      p00_b >= 115 &&
      p00_b <= 140 &&
      p10_r > 240 &&
      p10_g < 15 &&
      p01_r < 15 &&
      p01_g > 240

    let mut frames = 0
    if show_win {
      let sc = dev.create_swapchain("rhi/compute-storage-image", 800, 600)
      while !should_quit(sc) {
        sc.present_texture(storage_tex)
        frames = frames + 1
      }
      sc.destroy()
    }

    let errs = dev.validation_errors()
    ts.destroy()
    storage_tex.destroy()
    cpipe.destroy()
    dev.destroy()

    println(
      "[rhi/compute-storage-image] refl_ok=\{refl_ok} gpu_ms=\{gpu_ms} corners=[(0,0)=(\{p00_r},\{p00_g},\{p00_b}), (127,0)=(\{p10_r},\{p10_g}), (0,127)=(\{p01_r},\{p01_g})] frames=\{frames}",
    )
    if refl_ok && grad_ok && gpu_ms >= 0.0 && errs == 0 {
      println(
        "[rhi/compute-storage-image] OK — auto-reflected compute shader wrote 128x128 storage image in \{gpu_ms} ms, 0 validation errors",
      )
    } else {
      println(
        "[rhi/compute-storage-image] FAIL — refl_ok=\{refl_ok} grad_ok=\{grad_ok} gpu_ms=\{gpu_ms} errs=\{errs}",
      )
    }
  } catch {
    err => println("[rhi/compute-storage-image] FAIL — \{err}")
  }
}
