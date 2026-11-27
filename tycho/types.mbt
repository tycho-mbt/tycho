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
/// Composable buffer usage flags. `BufferKind` remains the shortcut for the
/// common single-purpose cases; this type expresses the combinations GPU-driven
/// pipelines need (`Storage | Indirect`, `Storage | Vertex`, ...).
pub(all) struct BufferUsage {
  priv bits : UInt32
}

///|
pub fn BufferUsage::none() -> BufferUsage {
  { bits: (0 : UInt32) }
}

///|
pub fn BufferUsage::vertex() -> BufferUsage {
  { bits: (1 : UInt32) }
}

///|
pub fn BufferUsage::index() -> BufferUsage {
  { bits: (2 : UInt32) }
}

///|
pub fn BufferUsage::uniform() -> BufferUsage {
  { bits: (4 : UInt32) }
}

///|
pub fn BufferUsage::storage() -> BufferUsage {
  { bits: (8 : UInt32) }
}

///|
pub fn BufferUsage::indirect() -> BufferUsage {
  { bits: (16 : UInt32) }
}

///|
pub fn BufferUsage::copy_src() -> BufferUsage {
  { bits: (32 : UInt32) }
}

///|
pub fn BufferUsage::copy_dst() -> BufferUsage {
  { bits: (64 : UInt32) }
}

///|
pub fn BufferUsage::combine(self : BufferUsage, other : BufferUsage) -> BufferUsage {
  { bits: self.bits | other.bits }
}

///|
pub fn BufferUsage::contains(self : BufferUsage, other : BufferUsage) -> Bool {
  (self.bits & other.bits) == other.bits
}

///|
pub fn BufferUsage::bits(self : BufferUsage) -> UInt32 {
  self.bits
}

///|
/// The usage set the legacy `BufferKind` implies (including the transfer bits
/// the backends used to add implicitly).
pub fn BufferUsage::from_kind(kind : BufferKind) -> BufferUsage {
  let u = match kind {
    BufferKind::Vertex => BufferUsage::vertex().combine(BufferUsage::copy_dst())
    BufferKind::Index => BufferUsage::index().combine(BufferUsage::copy_dst())
    BufferKind::Uniform => BufferUsage::uniform()
    BufferKind::Storage =>
      BufferUsage::storage().combine(BufferUsage::copy_src()).combine(BufferUsage::copy_dst())
    BufferKind::Staging => BufferUsage::copy_src().combine(BufferUsage::copy_dst())
    BufferKind::Indirect =>
      BufferUsage::indirect()
      .combine(BufferUsage::storage())
      .combine(BufferUsage::copy_src())
      .combine(BufferUsage::copy_dst())
  }
  u
}

///|
/// The single-purpose kind that best describes `usage`, for backends that only
/// distinguish storage from everything else.
pub fn BufferUsage::as_kind(self : BufferUsage) -> BufferKind {
  if self.contains(BufferUsage::indirect()) {
    BufferKind::Indirect
  } else if self.contains(BufferUsage::storage()) {
    BufferKind::Storage
  } else if self.contains(BufferUsage::uniform()) {
    BufferKind::Uniform
  } else if self.contains(BufferUsage::index()) {
    BufferKind::Index
  } else if self.contains(BufferUsage::vertex()) {
    BufferKind::Vertex
  } else {
    BufferKind::Staging
  }
}

///|
#derive(Eq, Debug)
pub(all) enum IndexType {
  Uint16
  Uint32
}

///|
/// Shader stage identity, re-exported from `laplaceliu/tycho_shader` so the RHI
/// and the compiler helpers agree on one enum (including ray-tracing stages).
pub type ShaderStage = @shader.ShaderStage

///|
/// `glslangValidator --target-env` selection.
pub type ShaderTarget = @shader.ShaderTarget

///|
#derive(Eq, Debug)
pub(all) enum VertexFormat {
  Float2
  Float3
  Float4
  Float1
  Int1
  Uint1
  Unorm8x4
  Uint16x4
}

///|
/// Backend-neutral encoding index. The DX12 shim uses the same numbering for
/// its `DXGI_FORMAT` table, so keep the two in sync.
pub fn VertexFormat::code(self : VertexFormat) -> Int {
  match self {
    Float2 => 0
    Float3 => 1
    Float4 => 2
    Float1 => 3
    Int1 => 4
    Uint1 => 5
    Unorm8x4 => 6
    Uint16x4 => 7
  }
}

///|
/// Bytes consumed per vertex attribute.
pub fn VertexFormat::bytes(self : VertexFormat) -> Int {
  match self {
    Float1 | Int1 | Uint1 | Unorm8x4 => 4
    Float2 | Uint16x4 => 8
    Float3 => 12
    Float4 => 16
  }
}

///|
/// Composable texture usage flags.
pub(all) struct TextureUsage {
  priv bits : UInt32
}

///|
pub fn TextureUsage::none() -> TextureUsage {
  { bits: (0 : UInt32) }
}

///|
pub fn TextureUsage::sampled() -> TextureUsage {
  { bits: (1 : UInt32) }
}

///|
pub fn TextureUsage::storage() -> TextureUsage {
  { bits: (2 : UInt32) }
}

///|
pub fn TextureUsage::render_attachment() -> TextureUsage {
  { bits: (4 : UInt32) }
}

///|
pub fn TextureUsage::copy_src() -> TextureUsage {
  { bits: (8 : UInt32) }
}

///|
pub fn TextureUsage::copy_dst() -> TextureUsage {
  { bits: (16 : UInt32) }
}

///|
pub fn TextureUsage::combine(self : TextureUsage, other : TextureUsage) -> TextureUsage {
  { bits: self.bits | other.bits }
}

///|
pub fn TextureUsage::contains(self : TextureUsage, other : TextureUsage) -> Bool {
  (self.bits & other.bits) == other.bits
}

///|
pub fn TextureUsage::bits(self : TextureUsage) -> UInt32 {
  self.bits
}

///|
pub(all) enum TextureDimension {
  D2
  D2Array(Int)
  Cube
}

///|
/// One descriptor for every texture shape: 2D, 2D array and cubemap, with
/// composable usage flags instead of a factory per combination.
pub(all) struct TextureDesc {
  width : Int
  height : Int
  format : TextureFormat
  usage : TextureUsage
  dimension : TextureDimension
  /// `1` for a single level; `0` asks the backend for the full chain when the
  /// backend supports generating it.
  mip_levels : Int
  samples : SampleCount
}

///|
pub fn TextureDesc::new(
  width : Int,
  height : Int,
  format : TextureFormat,
  usage? : TextureUsage = TextureUsage::sampled(),
  dimension? : TextureDimension = TextureDimension::D2,
  mip_levels? : Int = 1,
  samples? : SampleCount = SampleCount::X1,
) -> TextureDesc {
  { width, height, format, usage, dimension, mip_levels, samples }
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
  // Drawing state is grouped: rasterisation, depth/stencil and one entry per
  // colour attachment, instead of 20 flat mirror fields.
  raster : RasterState
  // `None` when the pipeline has no depth/stencil attachment at all.
  depth_stencil : DepthStencilState?
  color_targets : Array[ColorTargetState]
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
/// Rasterisation state, grouped out of the flat `PipelineDesc`.
pub(all) struct RasterState {
  topology : PrimitiveTopology
  cull_mode : CullMode
  front_face : FrontFace
  samples : SampleCount
}

///|
pub fn RasterState::new(
  topology? : PrimitiveTopology = PrimitiveTopology::TriangleList,
  cull_mode? : CullMode = CullMode::None,
  front_face? : FrontFace = FrontFace::Clockwise,
  samples? : SampleCount = SampleCount::X1,
) -> RasterState {
  { topology, cull_mode, front_face, samples }
}

///|
/// Depth/stencil state, grouped out of the flat `PipelineDesc`.
pub(all) struct DepthStencilState {
  depth_test : Bool
  write : Bool
  compare : CompareOp
  format : TextureFormat?
  depth_only : Bool
  bias : Bool
  bias_constant : Float
  bias_slope : Float
  stencil : StencilState?
}

///|
pub fn DepthStencilState::new(
  depth_test? : Bool = false,
  write? : Bool = false,
  compare? : CompareOp = CompareOp::Less,
  format? : TextureFormat,
  depth_only? : Bool = false,
  bias? : Bool = false,
  bias_constant? : Float = (0.0 : Float),
  bias_slope? : Float = (0.0 : Float),
  stencil? : StencilState,
) -> DepthStencilState {
  {
    depth_test,
    write,
    compare,
    format,
    depth_only,
    bias,
    bias_constant,
    bias_slope,
    stencil,
  }
}

///|
/// One colour attachment: format plus its write mask and blend state.
pub(all) struct ColorTargetState {
  format : TextureFormat?
  write : Bool
  blend_mode : BlendMode?
  blend_state : BlendState?
}

///|
pub fn ColorTargetState::new(
  format? : TextureFormat,
  write? : Bool = true,
  blend_mode? : BlendMode,
  blend_state? : BlendState,
) -> ColorTargetState {
  { format, write, blend_mode, blend_state }
}

///|
/// The rasterisation half of a pipeline description.
pub fn PipelineDesc::raster_state(self : PipelineDesc) -> RasterState {
  self.raster
}

///|
/// The depth/stencil state with defaults filled in, for backends that always
/// need a value.
pub fn PipelineDesc::depth_or_default(self : PipelineDesc) -> DepthStencilState {
  match self.depth_stencil {
    Some(d) => d
    None => DepthStencilState::new()
  }
}

///|
/// The depth/stencil half, or `None` when the pipeline has no depth or stencil
/// state at all.
pub fn PipelineDesc::depth_stencil_state(self : PipelineDesc) -> DepthStencilState? {
  self.depth_stencil
}

///|
/// The colour attachments, one entry per target. A single target is reported
/// through `color_format`, an MRT list through `color_formats`.
pub fn PipelineDesc::color_target_states(self : PipelineDesc) -> Array[ColorTargetState] {
  self.color_targets
}


///|
/// The colour target at `index`, falling back to a default when the descriptor
/// has no explicit target (single-target pipelines without a format).
pub fn PipelineDesc::color_target(self : PipelineDesc, index : Int) -> ColorTargetState {
  if index < self.color_targets.length() {
    self.color_targets[index]
  } else {
    ColorTargetState::new()
  }
}

///|
/// The resolved blend mode, `Opaque` when the target does not ask for blending.
pub fn ColorTargetState::effective_blend_mode(self : ColorTargetState) -> BlendMode {
  match self.blend_mode {
    Some(m) => m
    None => BlendMode::Opaque
  }
}

///|
/// The depth/stencil state of a mesh pipeline, with defaults filled in.
pub fn MeshPipelineDesc::depth_or_default(self : MeshPipelineDesc) -> DepthStencilState {
  match self.depth_stencil {
    Some(d) => d
    None => DepthStencilState::new()
  }
}

///|
/// The colour target at `index`, falling back to a default when the mesh
/// pipeline descriptor has no explicit target.
pub fn MeshPipelineDesc::color_target(self : MeshPipelineDesc, index : Int) -> ColorTargetState {
  if index < self.color_targets.length() {
    self.color_targets[index]
  } else {
    ColorTargetState::new()
  }
}

///|
/// Build a graphics pipeline from grouped state instead of 38 flat arguments.
/// The result is the same `PipelineDesc` the flat constructor produces, so the
/// two styles interoperate.
pub fn PipelineDesc::graphics(
  vert : FixedArray[UInt32],
  frag : FixedArray[UInt32],
  vert_entry? : String = "main",
  frag_entry? : String = "main",
  raster? : RasterState = RasterState::new(),
  depth_stencil? : DepthStencilState,
  color_targets? : Array[ColorTargetState] = [],
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
  bindless_heap? : BindlessHeap,
) -> PipelineDesc {
  // Depth/stencil: absent means "no depth attachment".
  let (d_test, d_write, d_compare, d_format, d_only, d_bias, d_bc, d_bs, d_stencil) =
    match depth_stencil {
      Some(d) => (
        d.depth_test,
        d.write,
        d.compare,
        d.format,
        d.depth_only,
        d.bias,
        d.bias_constant,
        d.bias_slope,
        d.stencil,
      )
      None => (
        false,
        false,
        CompareOp::Less,
        None,
        false,
        false,
        (0.0 : Float),
        (0.0 : Float),
        (None : StencilState?),
      )
    }
  // Colour: one target maps to `color_format`, several to the MRT list.
  let formats : Array[TextureFormat] = []
  for t in color_targets {
    match t.format {
      Some(f) => formats.push(f)
      None => ()
    }
  }
  let single = color_targets.length() <= 1
  let primary = if single && formats.length() > 0 {
    Some(formats[0])
  } else {
    None
  }
  let mrt = if single { [] } else { formats }
  let color_write = if color_targets.length() > 0 { color_targets[0].write } else { true }
  let blend_mode = if color_targets.length() > 0 {
    color_targets[0].blend_mode
  } else {
    None
  }
  let blend_state = if color_targets.length() > 0 {
    color_targets[0].blend_state
  } else {
    None
  }
  let blend = blend_mode is Some(_) || blend_state is Some(_)
  PipelineDesc::new(
    vert,
    frag,
    vert_entry~,
    frag_entry~,
    vertex_formats~,
    vertex_layouts~,
    uniform_slots~,
    texture_slots~,
    storage_slots~,
    storage_image_slots~,
    accel_slots~,
    uniform_bindings~,
    texture_bindings~,
    storage_bindings~,
    storage_image_bindings~,
    accel_bindings~,
    push_constant_size~,
    topology=raster.topology,
    depth_test=d_test,
    depth_write=d_write,
    depth_compare=d_compare,
    depth_format?=d_format,
    depth_only=d_only,
    depth_bias=d_bias,
    depth_bias_constant=d_bc,
    depth_bias_slope=d_bs,
    stencil?=d_stencil,
    cull_mode=raster.cull_mode,
    front_face=raster.front_face,
    blend=blend,
    blend_mode?=blend_mode,
    blend_state?=blend_state,
    color_write=color_write,
    samples=raster.samples,
    color_format?=primary,
    color_formats=mrt,
    bindless_heap?=bindless_heap,
  )
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
    raster: { topology, cull_mode, front_face, samples },
    depth_stencil: make_depth_stencil(
      depth_test,
      depth_write,
      depth_compare,
      depth_format,
      depth_only,
      depth_bias,
      depth_bias_constant,
      depth_bias_slope,
      stencil,
    ),
    color_targets: make_color_targets(
      color_format,
      color_formats,
      color_write,
      blend,
      blend_mode,
      blend_state,
    ),
    bindless_heap,
  }
}

///|
/// Keeps a flat constructor but stores the depth/stencil state as one value.
fn make_depth_stencil(
  depth_test : Bool,
  depth_write : Bool,
  depth_compare : CompareOp,
  depth_format : TextureFormat?,
  depth_only : Bool,
  depth_bias : Bool,
  depth_bias_constant : Float,
  depth_bias_slope : Float,
  stencil : StencilState?,
) -> DepthStencilState? {
  let has_state = depth_test ||
    depth_write ||
    depth_only ||
    depth_bias ||
    depth_format is Some(_) ||
    stencil is Some(_)
  if !has_state {
    return None
  }
  Some({
    depth_test,
    write: depth_write,
    compare: depth_compare,
    format: depth_format,
    depth_only,
    bias: depth_bias,
    bias_constant: depth_bias_constant,
    bias_slope: depth_bias_slope,
    stencil,
  })
}

///|
/// Keeps a flat constructor but stores one target per colour attachment. The
/// legacy `blend` flag is folded into the resolved blend mode.
fn make_color_targets(
  color_format : TextureFormat?,
  color_formats : Array[TextureFormat],
  color_write : Bool,
  blend : Bool,
  blend_mode : BlendMode?,
  blend_state : BlendState?,
) -> Array[ColorTargetState] {
  let resolved_blend : BlendMode? = match blend_mode {
    Some(m) => Some(m)
    None => if blend { Some(BlendMode::Alpha) } else { None }
  }
  let out : Array[ColorTargetState] = []
  if color_formats.length() > 0 {
    for f in color_formats {
      out.push({ format: Some(f), write: color_write, blend_mode: resolved_blend, blend_state })
    }
  } else {
    match color_format {
      Some(f) =>
        out.push({ format: Some(f), write: color_write, blend_mode: resolved_blend, blend_state })
      None => ()
    }
  }
  out
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
      @shader.ReflectedVertexFormat::Float1 =>
        vertex_formats.push(VertexFormat::Float1)
      @shader.ReflectedVertexFormat::Float2 =>
        vertex_formats.push(VertexFormat::Float2)
      @shader.ReflectedVertexFormat::Float3 =>
        vertex_formats.push(VertexFormat::Float3)
      @shader.ReflectedVertexFormat::Float4 =>
        vertex_formats.push(VertexFormat::Float4)
      @shader.ReflectedVertexFormat::Int1 =>
        vertex_formats.push(VertexFormat::Int1)
      @shader.ReflectedVertexFormat::Uint1 =>
        vertex_formats.push(VertexFormat::Uint1)
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
  raster : RasterState
  depth_stencil : DepthStencilState?
  color_targets : Array[ColorTargetState]
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
    raster: { topology: PrimitiveTopology::TriangleList, cull_mode, front_face, samples },
    depth_stencil: make_depth_stencil(
      depth_test,
      depth_write,
      depth_compare,
      depth_format,
      false,
      false,
      (0.0 : Float),
      (0.0 : Float),
      (None : StencilState?),
    ),
    color_targets: make_color_targets(
      color_format,
      color_formats,
      color_write,
      blend,
      blend_mode,
      (None : BlendState?),
    ),
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
pub fn compile_glsl(path : String, stage : ShaderStage) -> FixedArray[UInt32] {
  match stage {
    ShaderStage::Task | ShaderStage::Mesh =>
      @shader.compile_shader_file_env(path, stage, @shader.ShaderTarget::Vulkan13)
    _ => @shader.compile_shader_file(path, stage)
  }
}

///|
pub fn compile_glsl_source(source : String, stage : ShaderStage) -> FixedArray[UInt32] {
  match stage {
    ShaderStage::Task | ShaderStage::Mesh =>
      @shader.compile_shader_env(source, stage, @shader.ShaderTarget::Vulkan13)
    _ => @shader.compile_shader(source, stage)
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
/// Load a `.spv` file, raising `ShaderError::LoadFailed` when it is missing or
/// holds no code.
pub fn load_spirv_checked(path : String) -> FixedArray[UInt32] raise @shader.ShaderError {
  @shader.load_spirv_checked(path)
}

