// Tycho RHI public types, descriptors, errors, and shader/window re-exports.

///|
pub suberror RhiError {
  InitFailed(String)
  DeviceFailed(String)
  SwapchainFailed(String)
  PipelineFailed(String)
  AllocationFailed(String)
  CommandFailed(String)
  InvalidArgument(String)
  /// The selected backend does not implement this operation yet.
  BackendUnsupported(String)
}

///|
pub impl Show for RhiError with output(self, logger) {
  match self {
    InitFailed(msg) => logger.write_string("InitFailed(\{msg})")
    DeviceFailed(msg) => logger.write_string("DeviceFailed(\{msg})")
    SwapchainFailed(msg) => logger.write_string("SwapchainFailed(\{msg})")
    PipelineFailed(msg) => logger.write_string("PipelineFailed(\{msg})")
    AllocationFailed(msg) => logger.write_string("AllocationFailed(\{msg})")
    CommandFailed(msg) => logger.write_string("CommandFailed(\{msg})")
    InvalidArgument(msg) => logger.write_string("InvalidArgument(\{msg})")
    BackendUnsupported(msg) => logger.write_string("BackendUnsupported(\{msg})")
  }
}

///|
#derive(Eq, Debug)
pub(all) enum BackendKind {
  Vulkan
  Dx12
}

///|
#derive(Eq, Debug)
pub(all) enum PresentMode {
  Fifo
  Mailbox
  Immediate
}

///|
#derive(Eq, Debug)
pub(all) enum MemoryLocation {
  GpuOnly
  CpuToGpu
  GpuToCpu
}

///|
pub(all) struct DeviceDesc {
  app_name : String
  validation : Bool
  headless : Bool
  pipeline_cache : Bytes
  backend : BackendKind
}

///|
pub fn DeviceDesc::new(
  app_name : String,
  validation? : Bool = false,
  headless? : Bool = false,
  pipeline_cache? : Bytes = b"",
  backend? : BackendKind = BackendKind::Vulkan,
) -> DeviceDesc {
  { app_name, validation, headless, pipeline_cache, backend }
}

///|
pub(all) struct DeviceCapabilities {
  device_name : String
  is_discrete : Bool
  api_version : UInt32
  driver_version : UInt32
  max_image_dimension_2d : Int
  max_framebuffer_samples : Int
  max_sampler_anisotropy : Float
  supports_anisotropy : Bool
  supports_indirect_draw : Bool
  supports_bindless : Bool
  supports_mesh_shader : Bool
  supports_ray_query : Bool
}

///|
#derive(Eq, Debug)
pub(all) enum BufferKind {
  Vertex
  Index
  Uniform
  Storage
  Staging
  Indirect
}

///|
#derive(Eq, Debug)
pub(all) enum IndexType {
  Uint16
  Uint32
}

///|
#derive(Eq, Debug)
pub(all) enum ShaderStage {
  Vertex
  Fragment
  Compute
  Task
  Mesh
}

///|
#derive(Eq, Debug)
pub(all) enum VertexFormat {
  Float2
  Float3
  Float4
}

///|
#derive(Eq, Debug)
pub(all) enum TextureFormat {
  RGBA8
  BGRA8
  RGBA8Srgb
  BGRA8Srgb
  RGBA16F
  RG16F
  R8
  RGBA32F
  Depth32F
  Depth24Stencil8
}

///|
#derive(Eq, Debug)
pub(all) enum Filter {
  Nearest
  Linear
}

///|
#derive(Eq, Debug)
pub(all) enum AddressMode {
  Repeat
  ClampToEdge
  ClampToBorder
}

///|
#derive(Eq, Debug)
pub(all) enum BorderColor {
  TransparentBlack
  OpaqueBlack
  OpaqueWhite
}

///|
#derive(Eq, Debug)
pub(all) enum CullMode {
  None
  Back
  Front
}

///|
#derive(Eq, Debug)
pub(all) enum FrontFace {
  Clockwise
  CounterClockwise
}

///|
#derive(Eq, Debug)
pub(all) enum LoadOp {
  Clear
  Load
  DontCare
}

///|
#derive(Eq, Debug)
pub(all) enum StoreOp {
  Store
  DontCare
}

///|
#derive(Eq, Debug)
pub(all) enum SampleCount {
  X1
  X4
}

///|
#derive(Eq, Debug)
pub(all) enum PrimitiveTopology {
  TriangleList
  TriangleStrip
  LineList
  LineStrip
  PointList
}

///|
#derive(Eq, Debug)
pub(all) enum CompareOp {
  Never
  Less
  Equal
  LessEqual
  Greater
  NotEqual
  GreaterEqual
  Always
}

///|
#derive(Eq, Debug)
pub(all) enum BlendMode {
  Opaque
  Alpha
  Additive
  Premultiplied
  Multiply
  DstIn
  SrcIn
  Clear
}

///|
#derive(Eq, Debug)
pub(all) enum BlendFactor {
  Zero
  One
  SrcColor
  OneMinusSrcColor
  DstColor
  OneMinusDstColor
  SrcAlpha
  OneMinusSrcAlpha
  DstAlpha
  OneMinusDstAlpha
}

///|
#derive(Eq, Debug)
pub(all) enum BlendOp {
  Add
  Subtract
  ReverseSubtract
  Min
  Max
}

///|
// Explicit blend equation, used for Porter-Duff and separable modes that the
// preset `BlendMode` values do not cover.
#derive(Eq, Debug)
pub(all) struct BlendState {
  src_color : BlendFactor
  dst_color : BlendFactor
  color_op : BlendOp
  src_alpha : BlendFactor
  dst_alpha : BlendFactor
  alpha_op : BlendOp
}

///|
pub fn BlendState::new(
  src_color : BlendFactor,
  dst_color : BlendFactor,
  src_alpha : BlendFactor,
  dst_alpha : BlendFactor,
  color_op? : BlendOp = BlendOp::Add,
  alpha_op? : BlendOp = BlendOp::Add,
) -> BlendState {
  { src_color, dst_color, color_op, src_alpha, dst_alpha, alpha_op }
}

///|
#derive(Eq, Debug)
pub(all) enum VertexStepMode {
  Vertex
  Instance
}

///|
pub(all) struct VertexAttribute {
  location : Int
  format : VertexFormat
  offset : Int
}

///|
pub fn VertexAttribute::new(
  location : Int,
  format : VertexFormat,
  offset : Int,
) -> VertexAttribute {
  { location, format, offset }
}

///|
pub(all) struct VertexBufferLayout {
  stride : Int
  step_mode : VertexStepMode
  attributes : Array[VertexAttribute]
}

///|
pub fn VertexBufferLayout::new(
  stride : Int,
  attributes : Array[VertexAttribute],
  step_mode? : VertexStepMode = VertexStepMode::Vertex,
) -> VertexBufferLayout {
  { stride, step_mode, attributes }
}

///|
pub(all) struct ClearColor {
  r : Float
  g : Float
  b : Float
  a : Float
}

///|
pub fn ClearColor::rgba(r : Float, g : Float, b : Float, a : Float) -> ClearColor {
  { r, g, b, a }
}

///|
pub fn ClearColor::black() -> ClearColor {
  { r: (0.0 : Float), g: (0.0 : Float), b: (0.0 : Float), a: (1.0 : Float) }
}

///|
pub(all) struct SamplerDesc {
  mag : Filter
  min : Filter
  mipmap : Filter
  address : AddressMode
  border_color : BorderColor
  min_lod : Float
  max_lod : Float
  mip_lod_bias : Float
  anisotropy : Float
  compare_op : CompareOp?
}

///|
pub fn SamplerDesc::new(
  mag? : Filter = Filter::Linear,
  min? : Filter = Filter::Linear,
  mipmap? : Filter = Filter::Linear,
  address? : AddressMode = AddressMode::Repeat,
  border_color? : BorderColor = BorderColor::TransparentBlack,
  min_lod? : Float = (0.0 : Float),
  max_lod? : Float = (1000.0 : Float),
  mip_lod_bias? : Float = (0.0 : Float),
  anisotropy? : Float = (1.0 : Float),
  compare_op? : CompareOp,
) -> SamplerDesc {
  {
    mag,
    min,
    mipmap,
    address,
    border_color,
    min_lod,
    max_lod,
    mip_lod_bias,
    anisotropy,
    compare_op,
  }
}

///|
pub(all) struct PipelineDesc {
  vert : FixedArray[UInt32]
  frag : FixedArray[UInt32]
  vert_entry : String
  frag_entry : String
  vertex_formats : Array[VertexFormat]
  vertex_layouts : Array[VertexBufferLayout]
  uniform_slots : Int
  texture_slots : Int
  storage_slots : Int
  storage_image_slots : Int
  accel_slots : Int
  uniform_bindings : Array[Int]
  texture_bindings : Array[Int]
  storage_bindings : Array[Int]
  storage_image_bindings : Array[Int]
  accel_bindings : Array[Int]
  push_constant_size : Int
  topology : PrimitiveTopology
  depth_test : Bool
  depth_write : Bool
  depth_compare : CompareOp
  depth_format : TextureFormat?
  depth_only : Bool
  depth_bias : Bool
  depth_bias_constant : Float
  depth_bias_slope : Float
  stencil : StencilState?
  cull_mode : CullMode
  front_face : FrontFace
  blend : Bool
  blend_mode : BlendMode?
  blend_state : BlendState?
  color_write : Bool
  samples : SampleCount
  color_format : TextureFormat?
  color_formats : Array[TextureFormat]
  bindless_heap : BindlessHeap?
}

///|
#derive(Eq, Debug)
pub(all) enum StencilOp {
  Keep
  Zero
  Replace
  IncrementAndClamp
  DecrementAndClamp
  Invert
  IncrementAndWrap
  DecrementAndWrap
}

///|
pub(all) struct StencilFaceState {
  fail_op : StencilOp
  pass_op : StencilOp
  depth_fail_op : StencilOp
  compare_op : CompareOp
}

///|
pub fn StencilFaceState::new(
  fail_op? : StencilOp = StencilOp::Keep,
  pass_op? : StencilOp = StencilOp::Keep,
  depth_fail_op? : StencilOp = StencilOp::Keep,
  compare_op? : CompareOp = CompareOp::Always,
) -> StencilFaceState {
  { fail_op, pass_op, depth_fail_op, compare_op }
}

///|
pub(all) struct StencilState {
  front : StencilFaceState
  back : StencilFaceState
  compare_mask : UInt32
  write_mask : UInt32
  reference : UInt32
}

///|
pub fn StencilState::new(
  front? : StencilFaceState = StencilFaceState::new(),
  back? : StencilFaceState = StencilFaceState::new(),
  compare_mask? : UInt32 = (0xFF : UInt32),
  write_mask? : UInt32 = (0xFF : UInt32),
  reference? : UInt32 = (0 : UInt32),
) -> StencilState {
  { front, back, compare_mask, write_mask, reference }
}

///|
pub(all) struct RayGeometryDesc {
  vertex_buffer : Buffer
  vertex_count : Int
  vertex_stride : Int
  index_buffer : Buffer?
  index_count : Int
  index_type : IndexType
  is_opaque : Bool
}

///|
pub fn RayGeometryDesc::new(
  vertex_buffer : Buffer,
  vertex_count : Int,
  vertex_stride? : Int = 12,
  index_buffer? : Buffer,
  index_count? : Int = 0,
  index_type? : IndexType = IndexType::Uint32,
  is_opaque? : Bool = true,
) -> RayGeometryDesc {
  {
    vertex_buffer,
    vertex_count,
    vertex_stride,
    index_buffer,
    index_count,
    index_type,
    is_opaque,
  }
}

///|
pub(all) struct RayInstanceDesc {
  blas : AccelStruct
  transform : FixedArray[Float]
  custom_index : Int
  mask : Int
}

///|
pub fn RayInstanceDesc::new(
  blas : AccelStruct,
  transform? : FixedArray[Float] = @tmath.Affine3::identity().to_vk_transform_3x4(),
  custom_index? : Int = 0,
  mask? : Int = 0xFF,
) -> RayInstanceDesc {
  { blas, transform, custom_index, mask }
}

///|
/// Instance descriptor whose TLAS transform comes from an affine transform
/// (row-major 3x4, the same layout as `VkTransformMatrixKHR`).
pub fn RayInstanceDesc::from_affine3(
  blas : AccelStruct,
  affine : @tmath.Affine3,
  custom_index? : Int = 0,
  mask? : Int = 0xFF,
) -> RayInstanceDesc {
  {
    blas,
    transform: affine.to_vk_transform_3x4(),
    custom_index,
    mask,
  }
}

///|
pub fn PipelineDesc::new(
  vert : FixedArray[UInt32],
  frag : FixedArray[UInt32],
  vert_entry? : String = "main",
  frag_entry? : String = "main",
  vertex_formats? : Array[VertexFormat] = [],
  vertex_layouts? : Array[VertexBufferLayout] = [],
  uniform_slots? : Int = 0,
  texture_slots? : Int = 0,
  storage_slots? : Int = 0,
  storage_image_slots? : Int = 0,
  accel_slots? : Int = 0,
  uniform_bindings? : Array[Int] = [],
  texture_bindings? : Array[Int] = [],
  storage_bindings? : Array[Int] = [],
  storage_image_bindings? : Array[Int] = [],
  accel_bindings? : Array[Int] = [],
  push_constant_size? : Int = 0,
  topology? : PrimitiveTopology = PrimitiveTopology::TriangleList,
  depth_test? : Bool = false,
  depth_write? : Bool = false,
  depth_compare? : CompareOp = CompareOp::Less,
  depth_format? : TextureFormat,
  depth_only? : Bool = false,
  depth_bias? : Bool = false,
  depth_bias_constant? : Float = (0.0 : Float),
  depth_bias_slope? : Float = (0.0 : Float),
  stencil? : StencilState,
  cull_mode? : CullMode = CullMode::None,
  front_face? : FrontFace = FrontFace::Clockwise,
  blend? : Bool = false,
  blend_mode? : BlendMode,
  blend_state? : BlendState,
  color_write? : Bool = true,
  samples? : SampleCount = SampleCount::X1,
  color_format? : TextureFormat,
  color_formats? : Array[TextureFormat] = [],
  bindless_heap? : BindlessHeap,
) -> PipelineDesc {
  {
    vert,
    frag,
    vert_entry,
    frag_entry,
    vertex_formats,
    vertex_layouts,
    uniform_slots,
    texture_slots,
    storage_slots,
    storage_image_slots,
    accel_slots,
    uniform_bindings,
    texture_bindings,
    storage_bindings,
    storage_image_bindings,
    accel_bindings,
    push_constant_size,
    topology,
    depth_test,
    depth_write,
    depth_compare,
    depth_format,
    depth_only,
    depth_bias,
    depth_bias_constant,
    depth_bias_slope,
    stencil,
    cull_mode,
    front_face,
    blend,
    blend_mode,
    blend_state,
    color_write,
    samples,
    color_format,
    color_formats,
    bindless_heap,
  }
}

///|
fn push_unique_int(arr : Array[Int], v : Int) -> Unit {
  for x in arr {
    if x == v {
      return
    }
  }
  arr.push(v)
}

///|
// Builds a PipelineDesc by automatically reflecting SPIR-V bytecode for vertex
// inputs, entry points, descriptor bindings, push constant byte size, and MRT color targets.
pub fn PipelineDesc::from_spirv(
  vert : FixedArray[UInt32],
  frag : FixedArray[UInt32],
  topology? : PrimitiveTopology = PrimitiveTopology::TriangleList,
  depth_test? : Bool = false,
  depth_write? : Bool = false,
  depth_compare? : CompareOp = CompareOp::Less,
  depth_format? : TextureFormat,
  depth_only? : Bool = false,
  depth_bias? : Bool = false,
  depth_bias_constant? : Float = (0.0 : Float),
  depth_bias_slope? : Float = (0.0 : Float),
  stencil? : StencilState,
  cull_mode? : CullMode = CullMode::None,
  front_face? : FrontFace = FrontFace::Clockwise,
  blend? : Bool = false,
  blend_mode? : BlendMode,
  blend_state? : BlendState,
  color_write? : Bool = true,
  samples? : SampleCount = SampleCount::X1,
  color_format? : TextureFormat,
  color_formats? : Array[TextureFormat] = [],
  vertex_layouts? : Array[VertexBufferLayout] = [],
  bindless_heap? : BindlessHeap,
) -> PipelineDesc {
  let vr = @shader.reflect_spirv(vert)
  let fr = @shader.reflect_spirv(frag)
  let vert_entry = if vr.entry_point != "" { vr.entry_point } else { "main" }
  let frag_entry = if fr.entry_point != "" { fr.entry_point } else { "main" }
  let vertex_formats : Array[VertexFormat] = []
  for vi in vr.vertex_inputs {
    match vi.format {
      @shader.ReflectedVertexFormat::Float2 =>
        vertex_formats.push(VertexFormat::Float2)
      @shader.ReflectedVertexFormat::Float3 =>
        vertex_formats.push(VertexFormat::Float3)
      @shader.ReflectedVertexFormat::Float4 =>
        vertex_formats.push(VertexFormat::Float4)
      _ => ()
    }
  }
  let u_binds : Array[Int] = []
  let t_binds : Array[Int] = []
  let s_binds : Array[Int] = []
  let si_binds : Array[Int] = []
  let a_binds : Array[Int] = []
  let all_b : Array[@shader.ReflectedBinding] = []
  for b in vr.bindings {
    all_b.push(b)
  }
  for b in fr.bindings {
    all_b.push(b)
  }
  for b in all_b {
    if b.set != 0 {
      continue
    }
    match b.kind {
      @shader.ReflectedDescriptorKind::UniformBuffer =>
        push_unique_int(u_binds, b.binding)
      @shader.ReflectedDescriptorKind::CombinedImageSampler |
      @shader.ReflectedDescriptorKind::SampledImage =>
        push_unique_int(t_binds, b.binding)
      @shader.ReflectedDescriptorKind::StorageBuffer =>
        push_unique_int(s_binds, b.binding)
      @shader.ReflectedDescriptorKind::StorageImage =>
        push_unique_int(si_binds, b.binding)
      @shader.ReflectedDescriptorKind::AccelerationStructure =>
        push_unique_int(a_binds, b.binding)
      @shader.ReflectedDescriptorKind::Sampler => ()
    }
  }
  u_binds.sort_by(fn(a, b) { a - b })
  t_binds.sort_by(fn(a, b) { a - b })
  s_binds.sort_by(fn(a, b) { a - b })
  si_binds.sort_by(fn(a, b) { a - b })
  a_binds.sort_by(fn(a, b) { a - b })
  let push_constant_size = if vr.push_constant_size > fr.push_constant_size {
    vr.push_constant_size
  } else {
    fr.push_constant_size
  }
  let resolved_formats : Array[TextureFormat] = []
  if color_formats.length() > 0 {
    for f in color_formats {
      resolved_formats.push(f)
    }
  } else if color_format is None && fr.color_output_count > 1 {
    for i = 0; i < fr.color_output_count; i = i + 1 {
      let _ = i
      resolved_formats.push(TextureFormat::RGBA8)
    }
  }
  PipelineDesc::new(
    vert,
    frag,
    vert_entry~,
    frag_entry~,
    vertex_formats~,
    vertex_layouts~,
    uniform_slots=u_binds.length(),
    texture_slots=t_binds.length(),
    storage_slots=s_binds.length(),
    storage_image_slots=si_binds.length(),
    accel_slots=a_binds.length(),
    uniform_bindings=u_binds,
    texture_bindings=t_binds,
    storage_bindings=s_binds,
    storage_image_bindings=si_binds,
    accel_bindings=a_binds,
    push_constant_size~,
    topology~,
    depth_test~,
    depth_write~,
    depth_compare~,
    depth_format?=depth_format,
    depth_only~,
    depth_bias~,
    depth_bias_constant~,
    depth_bias_slope~,
    stencil?=stencil,
    cull_mode~,
    front_face~,
    blend~,
    blend_mode?=blend_mode,
    blend_state?=blend_state,
    color_write~,
    samples~,
    color_format?=color_format,
    color_formats=resolved_formats,
    bindless_heap?=bindless_heap,
  )
}

///|
pub(all) struct MeshPipelineDesc {
  task : FixedArray[UInt32]?
  mesh : FixedArray[UInt32]
  frag : FixedArray[UInt32]
  task_entry : String
  mesh_entry : String
  frag_entry : String
  uniform_slots : Int
  texture_slots : Int
  storage_slots : Int
  storage_image_slots : Int
  uniform_bindings : Array[Int]
  texture_bindings : Array[Int]
  storage_bindings : Array[Int]
  storage_image_bindings : Array[Int]
  push_constant_size : Int
  depth_test : Bool
  depth_write : Bool
  depth_compare : CompareOp
  depth_format : TextureFormat?
  cull_mode : CullMode
  front_face : FrontFace
  blend : Bool
  blend_mode : BlendMode?
  color_write : Bool
  samples : SampleCount
  color_format : TextureFormat?
  color_formats : Array[TextureFormat]
  bindless_heap : BindlessHeap?
}

///|
pub fn MeshPipelineDesc::new(
  mesh : FixedArray[UInt32],
  frag : FixedArray[UInt32],
  task? : FixedArray[UInt32],
  task_entry? : String = "main",
  mesh_entry? : String = "main",
  frag_entry? : String = "main",
  uniform_slots? : Int = 0,
  texture_slots? : Int = 0,
  storage_slots? : Int = 0,
  storage_image_slots? : Int = 0,
  uniform_bindings? : Array[Int] = [],
  texture_bindings? : Array[Int] = [],
  storage_bindings? : Array[Int] = [],
  storage_image_bindings? : Array[Int] = [],
  push_constant_size? : Int = 0,
  depth_test? : Bool = false,
  depth_write? : Bool = false,
  depth_compare? : CompareOp = CompareOp::Less,
  depth_format? : TextureFormat,
  cull_mode? : CullMode = CullMode::None,
  front_face? : FrontFace = FrontFace::Clockwise,
  blend? : Bool = false,
  blend_mode? : BlendMode,
  color_write? : Bool = true,
  samples? : SampleCount = SampleCount::X1,
  color_format? : TextureFormat,
  color_formats? : Array[TextureFormat] = [],
  bindless_heap? : BindlessHeap,
) -> MeshPipelineDesc {
  {
    task,
    mesh,
    frag,
    task_entry,
    mesh_entry,
    frag_entry,
    uniform_slots,
    texture_slots,
    storage_slots,
    storage_image_slots,
    uniform_bindings,
    texture_bindings,
    storage_bindings,
    storage_image_bindings,
    push_constant_size,
    depth_test,
    depth_write,
    depth_compare,
    depth_format,
    cull_mode,
    front_face,
    blend,
    blend_mode,
    color_write,
    samples,
    color_format,
    color_formats,
    bindless_heap,
  }
}

///|
pub(all) struct SwapchainDesc {
  title : String
  width : Int
  height : Int
  depth : Bool
  depth_format : TextureFormat
  clear_color : ClearColor
  enable_readback : Bool
  present_mode : PresentMode
}

///|
pub fn SwapchainDesc::new(
  title : String,
  width : Int,
  height : Int,
  depth? : Bool = false,
  depth_format? : TextureFormat = TextureFormat::Depth32F,
  clear_color? : ClearColor = ClearColor::black(),
  enable_readback? : Bool = false,
  present_mode? : PresentMode = PresentMode::Fifo,
) -> SwapchainDesc {
  {
    title,
    width,
    height,
    depth,
    depth_format,
    clear_color,
    enable_readback,
    present_mode,
  }
}

///|
pub(all) struct RenderTargetDesc {
  texture : Texture
  load_op : LoadOp
  store_op : StoreOp
  clear_color : ClearColor
  resolve_texture : Texture?
}

///|
pub fn RenderTargetDesc::new(
  texture : Texture,
  load_op? : LoadOp = LoadOp::Clear,
  store_op? : StoreOp = StoreOp::Store,
  clear_color? : ClearColor = ClearColor::black(),
  resolve_texture? : Texture,
) -> RenderTargetDesc {
  { texture, load_op, store_op, clear_color, resolve_texture }
}

///|
pub(all) struct DepthTargetDesc {
  texture : Texture
  load_op : LoadOp
  store_op : StoreOp
  clear_depth : Float
  stencil_load_op : LoadOp
  stencil_store_op : StoreOp
  clear_stencil : Int
}

///|
pub fn DepthTargetDesc::new(
  texture : Texture,
  load_op? : LoadOp = LoadOp::Clear,
  store_op? : StoreOp = StoreOp::DontCare,
  clear_depth? : Float = (1.0 : Float),
  stencil_load_op? : LoadOp = LoadOp::DontCare,
  stencil_store_op? : StoreOp = StoreOp::DontCare,
  clear_stencil? : Int = 0,
) -> DepthTargetDesc {
  {
    texture,
    load_op,
    store_op,
    clear_depth,
    stencil_load_op,
    stencil_store_op,
    clear_stencil,
  }
}

// Re-export window events, cursor mode, and key codes so users only need `@tycho`.

///|
pub type Event = @win.Event

///|
pub type CursorMode = @win.CursorMode

///|
pub type CursorShape = @win.CursorShape

///|
pub type KeyCode = @win.KeyCode

///|
pub type Modifiers = @win.Modifiers

///|
pub type MouseButton = @win.MouseButton

// Shader compilation, SPIR-V reflection & image loading helpers (via laplaceliu/tycho_shader).

///|
pub type ReflectedStage = @shader.ReflectedStage

///|
pub type ReflectedDescriptorKind = @shader.ReflectedDescriptorKind

///|
pub type ReflectedVertexFormat = @shader.ReflectedVertexFormat

///|
pub type ReflectedBinding = @shader.ReflectedBinding

///|
pub type ReflectedVertexInput = @shader.ReflectedVertexInput

///|
pub type SpirvReflection = @shader.SpirvReflection

///|
pub fn reflect_spirv(spv : FixedArray[UInt32]) -> SpirvReflection {
  @shader.reflect_spirv(spv)
}

///|
fn shader_kind(stage : ShaderStage) -> UInt32 {
  match stage {
    ShaderStage::Vertex => @shader.SHADER_KIND_VERTEX
    ShaderStage::Fragment => @shader.SHADER_KIND_FRAGMENT
    ShaderStage::Compute => @shader.SHADER_KIND_COMPUTE
    ShaderStage::Task => @shader.SHADER_KIND_TASK
    ShaderStage::Mesh => @shader.SHADER_KIND_MESH
  }
}

///|
pub fn compile_glsl(path : String, stage : ShaderStage) -> FixedArray[UInt32] {
  match stage {
    ShaderStage::Task | ShaderStage::Mesh =>
      @shader.compile_shader_file_env(
        path,
        shader_kind(stage),
        @shader.SHADER_ENV_VULKAN_1_3,
      )
    _ => @shader.compile_shader_file(path, shader_kind(stage))
  }
}

///|
pub fn compile_glsl_source(source : String, stage : ShaderStage) -> FixedArray[UInt32] {
  match stage {
    ShaderStage::Task | ShaderStage::Mesh =>
      @shader.compile_shader_env(
        source,
        shader_kind(stage),
        @shader.SHADER_ENV_VULKAN_1_3,
      )
    _ => @shader.compile_shader(source, shader_kind(stage))
  }
}

///|
pub fn compile_slang(path : String, entry : String) -> FixedArray[UInt32] {
  @shader.compile_slang_file(path, entry)
}

///|
pub fn load_spirv(path : String) -> FixedArray[UInt32] {
  @shader.load_spirv(path)
}

///|
pub fn load_image(path : String) -> (FixedArray[Byte], Int, Int) {
  let (px, w, h) = @shader.load_image(path)
  (px, w.to_int(), h.to_int())
}

///|
pub fn read_file_bytes(path : String) -> Bytes {
  @shader.read_file_bytes(path)
}

///|
pub fn want_window() -> Bool {
  @shader.want_window()
}

///|
pub fn screenshot_path() -> String {
  @shader.screenshot_path()
}

///|
pub fn save_png(
  path : String,
  width : Int,
  height : Int,
  rgba : FixedArray[Byte],
  bgra? : Bool = false,
) -> Bool {
  @shader.save_png(path, width, height, rgba, bgra~)
}

///|
pub fn load_hdr_image(path : String) -> (FixedArray[Float], Int, Int) {
  let (px, w, h) = @shader.load_hdr_image(path)
  (px, w.to_int(), h.to_int())
}

///|
/// Decode PNG/JPEG bytes into tight RGBA8 (`Some((pixels, width, height))`).
pub fn decode_image(bytes : Bytes) -> (Bytes, Int, Int)? {
  match @shader.decode_image(bytes) {
    Some((px, w, h)) => Some((px, w.to_int(), h.to_int()))
    None => None
  }
}

///|
/// Load a PNG/JPEG file as tight RGBA8.
pub fn load_image_rgba(path : String) -> (Bytes, Int, Int)? {
  match @shader.load_image_rgba(path) {
    Some((px, w, h)) => Some((px, w.to_int(), h.to_int()))
    None => None
  }
}
