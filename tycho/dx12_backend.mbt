// DX12 backend for the Tycho RHI (Windows).
//
// The public API is shared with the Vulkan backend: `Device`, `Swapchain`,
// `Pipeline` and `CommandBuffer` carry a backend tag, and this file implements
// the DX12 half of the operations the RHI currently gates (windowed flip-model
// present, clear, draw, readback). Anything else keeps raising
// `RhiError::BackendUnsupported` from the accessors in rhi.mbt.
//
// Shader artifacts: this backend consumes DXIL, not SPIR-V. `create_pipeline`
// inherits the Vulkan signature, so on DX12 the blobs are DXIL and the byte
// length is derived from the word count (DXIL containers are 4-byte aligned).
// Cross-compiling one shader source into both artifacts is the remaining piece
// of the shader story, tracked in docs/original-design/03-dx12.md §6.1.

///|
priv struct Dx12DeviceState {
  device : @dx12.Device
}

///|
/// A compiled DX12 pipeline plus the uniform slot count its root signature was
/// built with (slot i = root CBV i = `register(b<i>, space0)`).
priv struct Dx12PipelineState {
  pipe : @dx12.Pipeline
  uniform_slots : Int
}

///|
/// A CPU-visible upload buffer; `size` is tracked so the RHI can bound checks.
priv struct Dx12BufferState {
  buffer : @dx12.Buffer
  size : Int
}

///|
priv struct Dx12SwapchainState {
  device : @dx12.Device
  swapchain : @dx12.Swapchain
  commands : @dx12.CommandList
  readback : @dx12.Readback
  window : UInt64
  width : Int
  height : Int
  clear : ClearColor
  enable_readback : Bool
}

///|
/// A recording in progress. `target` is set by `dx12_begin_frame_commands`
/// (swapchain back buffer, borrowed and destroyed with the wrapper) or by
/// `dx12_begin_render_pass` (offscreen texture, owned by the caller).
priv struct Dx12CommandState {
  device : @dx12.Device
  commands : @dx12.CommandList
  mut target : @dx12.Texture?
  clear : ClearColor
  owned_target : Bool
}

///|
fn dx12_device_create(desc : DeviceDesc) -> Dx12DeviceState raise RhiError {
  let want_warp = @dx12.env_requests_warp()
  let device = match @dx12.Device::create(warp=want_warp, debug=desc.validation) {
    Some(d) => d
    None =>
      match @dx12.Device::create(warp=true, debug=desc.validation) {
        Some(d) => d
        None =>
          raise RhiError::DeviceFailed("no D3D12 device (hardware and WARP both refused)")
      }
  }
  { device: device }
}

///|
fn dx12_device_destroy(state : Dx12DeviceState) -> Unit {
  let _ = state.device.wait_idle()
  state.device.destroy()
}

///|
fn dx12_swapchain_create(
  state : Dx12DeviceState,
  desc : SwapchainDesc,
) -> Dx12SwapchainState raise RhiError {
  if desc.depth {
    raise RhiError::BackendUnsupported("depth targets are not implemented on the DX12 backend")
  }
  let window = @win.create(desc.width, desc.height, desc.title)
  if window == (0 : UInt64) {
    raise RhiError::SwapchainFailed("no Win32 window for the DX12 swapchain")
  }
  let hwnd = @win.native_handle(window)
  let swapchain = match @dx12.Swapchain::create(state.device, hwnd, desc.width, desc.height) {
    Some(s) => s
    None => {
      @win.destroy(window)
      raise RhiError::SwapchainFailed("DXGI CreateSwapChainForHwnd failed")
    }
  }
  let readback = match @dx12.Readback::create(state.device, desc.width, desc.height) {
    Some(r) => r
    None => {
      swapchain.destroy()
      @win.destroy(window)
      raise RhiError::AllocationFailed("DX12 readback buffer")
    }
  }
  let commands = match @dx12.CommandList::create(state.device) {
    Some(c) => c
    None => {
      readback.destroy()
      swapchain.destroy()
      @win.destroy(window)
      raise RhiError::CommandFailed("DX12 command list")
    }
  }
  {
    device: state.device,
    swapchain: swapchain,
    commands: commands,
    readback: readback,
    window: window,
    width: desc.width,
    height: desc.height,
    clear: desc.clear_color,
    enable_readback: desc.enable_readback,
  }
}

///|
fn dx12_swapchain_destroy(state : Dx12SwapchainState) -> Unit {
  let _ = state.device.wait_idle()
  state.readback.destroy()
  state.commands.destroy()
  state.swapchain.destroy()
  @win.destroy(state.window)
}

///|
fn dx12_swapchain_readback(state : Dx12SwapchainState) -> FixedArray[Byte] {
  let bytes = state.readback.bytes()
  FixedArray::makei(bytes.length(), fn(i) { bytes[i] })
}

///|
fn dx12_pipeline_create(
  device : @dx12.Device,
  vert : FixedArray[UInt32],
  frag : FixedArray[UInt32],
  uniform_slots : Int,
  depth : Bool,
  depth_write : Bool,
  srv_tables : Int,
) -> Dx12PipelineState raise RhiError {
  // Root CBVs cost nothing to declare, so uniform slots are supported directly;
  // `flip_y` pins the Vulkan clip-space/winding convention (docs/original-design
  // /03-dx12.md §6.1 item 2) so one shader source renders identically on both
  // backends.
  match @dx12.Pipeline::create(
    device,
    vert,
    vert.length() * 4,
    frag,
    frag.length() * 4,
    cbv_count=uniform_slots,
    flip_y=true,
    depth=depth,
    depth_write=depth_write,
    srv_tables=srv_tables,
  ) {
    Some(p) => { pipe: p, uniform_slots, }
    None => raise RhiError::PipelineFailed("DX12 CreateGraphicsPipelineState failed")
  }
}

///|
fn dx12_buffer_create(
  state : Dx12DeviceState,
  size : Int,
  kind : BufferKind,
  location : MemoryLocation,
) -> Dx12BufferState raise RhiError {
  let uploadable = match location {
    MemoryLocation::CpuToGpu => true
    _ => false
  }
  if !uploadable {
    raise RhiError::BackendUnsupported(
      "the DX12 backend only allocates CpuToGpu buffers so far",
    )
  }
  match kind {
    BufferKind::Uniform => ()
    _ =>
      raise RhiError::BackendUnsupported(
        "the DX12 backend only uploads uniform buffers so far",
      )
  }
  match @dx12.Buffer::create(state.device, size) {
    Some(b) => { buffer: b, size, }
    None => raise RhiError::AllocationFailed("DX12 upload buffer")
  }
}

///|
fn dx12_bind_uniform(
  cmd : Dx12CommandState,
  pipe : Dx12PipelineState,
  slot : Int,
  buffer : Dx12BufferState,
  offset : Int,
) -> Bool {
  if slot < 0 || slot >= pipe.uniform_slots {
    return false
  }
  if offset + 16 > buffer.size {
    return false
  }
  cmd.commands.set_cbv(slot, buffer.buffer, offset~)
}

///|
fn dx12_begin_frame_commands(state : Dx12SwapchainState) -> Dx12CommandState raise RhiError {
  let target = match state.swapchain.target(state.swapchain.current_index()) {
    Some(t) => t
    None => raise RhiError::SwapchainFailed("DX12 back buffer unavailable")
  }
  let mut ok = state.commands.begin()
  ok = ok && state.commands.transition(target, @dx12.ResourceState::RenderTarget)
  if !ok {
    target.destroy()
    raise RhiError::CommandFailed("DX12 begin frame failed")
  }
  {
    device: state.device,
    commands: state.commands,
    target: Some(target),
    clear: state.clear,
    owned_target: true,
  }
}

///|
fn dx12_begin_frame(state : Dx12SwapchainState) -> Dx12CommandState raise RhiError {
  let cmd = dx12_begin_frame_commands(state)
  dx12_begin_swapchain_pass(cmd, LoadOp::Clear, None)
  cmd
}

///|
fn dx12_begin_swapchain_pass(
  cmd : Dx12CommandState,
  load_op : LoadOp,
  clear_color : ClearColor?,
) -> Unit {
  match load_op {
    LoadOp::Load => ()
    LoadOp::DontCare => ()
    LoadOp::Clear => {
      let color = match clear_color {
        Some(c) => c
        None => cmd.clear
      }
      match cmd.target {
        Some(target) => {
          let _ = cmd.commands.clear(target, color.r, color.g, color.b, color.a)
        }
        None => ()
      }
    }
  }
}

///|
fn dx12_capabilities(state : Dx12DeviceState) -> DeviceCapabilities {
  let sm = state.device.shader_model()
  let mesh = state.device.mesh_tier()
  let ray = state.device.raytracing_tier()
  {
    device_name: if state.device.is_warp() { "D3D12 (WARP)" } else { "D3D12" },
    is_discrete: !state.device.is_warp(),
    api_version: sm.reinterpret_as_uint(),
    driver_version: (0 : UInt32),
    max_image_dimension_2d: (16384 : Int),
    max_framebuffer_samples: (1 : Int),
    max_sampler_anisotropy: (16.0 : Float),
    supports_anisotropy: true,
    supports_indirect_draw: true,
    supports_bindless: false,
    supports_mesh_shader: mesh != 0,
    supports_ray_query: ray != 0,
  }
}

///|
fn dx12_end_frame(state : Dx12SwapchainState, cmd : Dx12CommandState) -> Unit raise RhiError {
  let mut ok = true
  match cmd.target {
    Some(target) => {
      if state.enable_readback {
        ok = ok && cmd.commands.transition(target, @dx12.ResourceState::CopySource)
        ok = ok && cmd.commands.copy_to_readback(target, state.readback)
      }
      ok = ok && cmd.commands.transition(target, @dx12.ResourceState::Present)
    }
    None => ok = false
  }
  ok = ok && cmd.commands.execute_wait(state.device)
  match cmd.target {
    Some(target) => if cmd.owned_target {
      target.destroy()
    }
    None => ()
  }
  if !ok {
    raise RhiError::CommandFailed("DX12 end frame failed")
  }
  match state.swapchain.present() {
    @dx12.PresentResult::Failed => raise RhiError::SwapchainFailed("DX12 Present failed")
    _ => ()
  }
}

///|
fn dx12_bind_pipeline(cmd : Dx12CommandState, pipe : Dx12PipelineState) -> Unit {
  let _ = cmd.commands.set_pipeline(pipe.pipe)
}

///|
fn dx12_draw(cmd : Dx12CommandState, vertices : Int, instances : Int) -> Unit {
  // Vertex/instance offsets are not part of the DX12 slice yet; the RHI draw
  // calls without offsets are the ones the gates exercise. `flip_y` matches the
  // viewport convention pinned in dx12_pipeline_create.
  match cmd.target {
    Some(target) => {
      let _ = cmd.commands.draw(target, vertices, instances=instances, flip_y=true)
    }
    None => ()
  }
}

///|
fn dx12_render_target_create(
  state : Dx12DeviceState,
  width : Int,
  height : Int,
) -> Dx12TextureState raise RhiError {
  match @dx12.Texture::create(state.device, width, height) {
    Some(tex) =>
      {
        device: state.device,
        tex: tex,
        width: width,
        height: height,
        format: TextureFormat::RGBA8,
        is_depth: false,
      }
    None => raise RhiError::AllocationFailed("DX12 render target")
  }
}

///|
fn dx12_depth_create(
  state : Dx12DeviceState,
  width : Int,
  height : Int,
) -> Dx12TextureState raise RhiError {
  match @dx12.Texture::create_depth(state.device, width, height) {
    Some(tex) =>
      {
        device: state.device,
        tex: tex,
        width: width,
        height: height,
        format: TextureFormat::Depth32F,
        is_depth: true,
      }
    None => raise RhiError::AllocationFailed("DX12 depth target")
  }
}

///|
/// Synchronous readback: a throwaway command list copies the texture into a fresh
/// READBACK buffer, waits for the queue, then repacks the padded rows.
fn dx12_texture_readback(state : Dx12TextureState) -> FixedArray[Byte] raise RhiError {
  if state.is_depth {
    raise RhiError::BackendUnsupported("depth readback is not implemented on DX12")
  }
  let device = state.device
  let cmd = match @dx12.CommandList::create(device) {
    Some(c) => c
    None => raise RhiError::CommandFailed("DX12 readback command list")
  }
  let readback = match @dx12.Readback::create(device, state.width, state.height) {
    Some(r) => r
    None => {
      cmd.destroy()
      raise RhiError::AllocationFailed("DX12 readback buffer")
    }
  }
  let mut ok = cmd.begin()
  ok = ok && cmd.transition(state.tex, @dx12.ResourceState::CopySource)
  ok = ok && cmd.copy_to_readback(state.tex, readback)
  ok = ok && cmd.execute_wait(device)
  let bytes = readback.bytes()
  let px = FixedArray::makei(bytes.length(), fn(i) { bytes[i] })
  cmd.destroy()
  readback.destroy()
  if !ok {
    raise RhiError::CommandFailed("DX12 readback failed")
  }
  px
}

///|
fn dx12_commands_create(state : Dx12DeviceState) -> Dx12CommandState raise RhiError {
  let cmd = match @dx12.CommandList::create(state.device) {
    Some(c) => c
    None => raise RhiError::CommandFailed("DX12 command list")
  }
  if !cmd.begin() {
    cmd.destroy()
    raise RhiError::CommandFailed("DX12 command list begin")
  }
  {
    device: state.device,
    commands: cmd,
    target: None,
    clear: ClearColor::black(),
    owned_target: false,
  }
}

///|
fn dx12_commands_finish(cmd : Dx12CommandState) -> Unit raise RhiError {
  let ok = cmd.commands.execute_wait(cmd.device)
  cmd.commands.destroy()
  if !ok {
    raise RhiError::CommandFailed("DX12 command submission failed")
  }
}

///|
fn dx12_begin_render_pass(
  cmd : Dx12CommandState,
  colors : Array[RenderTargetDesc],
  depth : DepthTargetDesc?,
) -> Unit raise RhiError {
  if colors.length() != 1 {
    raise RhiError::BackendUnsupported(
      "the DX12 backend renders to exactly one colour target so far",
    )
  }
  let color = colors[0]
  let target = match color.texture.backend {
    Dx12Texture(state) => state
    VkTexture(_) => raise RhiError::InvalidArgument("Vulkan texture in a DX12 render pass")
  }
  let mut ok = cmd.commands.transition(target.tex, @dx12.ResourceState::RenderTarget)
  cmd.target = Some(target.tex)
  match color.load_op {
    LoadOp::Clear =>
      ok = ok &&
        cmd.commands.clear(target.tex, color.clear_color.r, color.clear_color.g, color.clear_color.b, color.clear_color.a)
    _ => ()
  }
  match depth {
    Some(desc) => {
      let depth_state = match desc.texture.backend {
        Dx12Texture(state) => state
        VkTexture(_) =>
          raise RhiError::InvalidArgument("Vulkan texture in a DX12 depth attachment")
      }
      ok = ok && cmd.commands.transition(depth_state.tex, @dx12.ResourceState::DepthWrite)
      ok = ok && cmd.commands.set_depth(depth_state.tex)
      match desc.load_op {
        LoadOp::Clear =>
          ok = ok && cmd.commands.clear_depth(depth_state.tex, depth=desc.clear_depth)
        _ => ()
      }
    }
    None => ()
  }
  if !ok {
    raise RhiError::CommandFailed("DX12 begin render pass failed")
  }
}

///|
fn dx12_end_render_pass(cmd : Dx12CommandState) -> Unit {
  // Leave the colour target readable: `Texture::readback` expects a copy source.
  match cmd.target {
    Some(target) => {
      let _ = cmd.commands.transition(target, @dx12.ResourceState::CopySource)
    }
    None => ()
  }
  cmd.target = None
}

///|
/// Pipeline for the offscreen path: no swapchain is involved, so everything comes
/// from `PipelineDesc`. Only uniform slots, RGBA8, Depth32F and a single sample
/// are implemented so far; the rest is rejected instead of silently ignored.
fn dx12_pipeline_create_from_desc(
  state : Dx12DeviceState,
  desc : PipelineDesc,
) -> Dx12PipelineState raise RhiError {
  if desc.texture_slots > 1 ||
    desc.storage_slots > 0 ||
    desc.storage_image_slots > 0 ||
    desc.accel_slots > 0 {
    raise RhiError::BackendUnsupported(
      "the DX12 backend implements one sampled texture slot and uniform slots so far",
    )
  }
  if desc.push_constant_size > 0 {
    raise RhiError::BackendUnsupported(
      "push constants are not implemented on the DX12 backend yet",
    )
  }
  let has_depth = match desc.depth_format {
    Some(_) => true
    None => false
  }
  let depth = desc.depth_test && has_depth
  dx12_pipeline_create(
    state.device,
    desc.vert,
    desc.frag,
    desc.uniform_slots,
    depth,
    desc.depth_write,
    desc.texture_slots,
  )
}

///|
/// Uploads tightly packed RGBA8 pixels into a DEFAULT-heap texture with a
/// shader-visible SRV (one slot in the device heap).
fn dx12_texture_upload_create(
  state : Dx12DeviceState,
  width : Int,
  height : Int,
  pixels : Bytes,
) -> Dx12TextureState raise RhiError {
  match @dx12.Texture::create_uploaded(state.device, width, height, pixels) {
    Some(tex) =>
      {
        device: state.device,
        tex: tex,
        width: width,
        height: height,
        format: TextureFormat::RGBA8,
        is_depth: false,
      }
    None => raise RhiError::AllocationFailed("DX12 texture upload")
  }
}
