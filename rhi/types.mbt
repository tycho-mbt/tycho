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
  }
}

///|
#derive(Eq, Debug)
pub(all) enum BackendKind {
  Vulkan
}

///|
#derive(Eq, Debug)
pub(all) enum BufferKind {
  Vertex
  Index
  Uniform
  Storage
  Staging
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
  RGBA32F
  Depth32F
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
  address : AddressMode
}

///|
pub fn SamplerDesc::new(
  mag? : Filter = Filter::Linear,
  min? : Filter = Filter::Linear,
  address? : AddressMode = AddressMode::Repeat,
) -> SamplerDesc {
  { mag, min, address }
}

///|
pub(all) struct PipelineDesc {
  vert : FixedArray[UInt32]
  frag : FixedArray[UInt32]
  vertex_formats : Array[VertexFormat]
  uniform_slots : Int
  texture_slots : Int
  storage_slots : Int
  push_constant_size : Int
  depth_test : Bool
  depth_write : Bool
  cull_mode : CullMode
  front_face : FrontFace
  blend : Bool
  samples : SampleCount
  color_format : TextureFormat?
}

///|
pub fn PipelineDesc::new(
  vert : FixedArray[UInt32],
  frag : FixedArray[UInt32],
  vertex_formats? : Array[VertexFormat] = [],
  uniform_slots? : Int = 0,
  texture_slots? : Int = 0,
  storage_slots? : Int = 0,
  push_constant_size? : Int = 0,
  depth_test? : Bool = false,
  depth_write? : Bool = false,
  cull_mode? : CullMode = CullMode::None,
  front_face? : FrontFace = FrontFace::Clockwise,
  blend? : Bool = false,
  samples? : SampleCount = SampleCount::X1,
  color_format? : TextureFormat? = None,
) -> PipelineDesc {
  {
    vert,
    frag,
    vertex_formats,
    uniform_slots,
    texture_slots,
    storage_slots,
    push_constant_size,
    depth_test,
    depth_write,
    cull_mode,
    front_face,
    blend,
    samples,
    color_format,
  }
}

///|
pub(all) struct SwapchainDesc {
  title : String
  width : Int
  height : Int
  depth : Bool
  clear_color : ClearColor
}

///|
pub fn SwapchainDesc::new(
  title : String,
  width : Int,
  height : Int,
  depth? : Bool = false,
  clear_color? : ClearColor = ClearColor::black(),
) -> SwapchainDesc {
  { title, width, height, depth, clear_color }
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
  resolve_texture? : Texture? = None,
) -> RenderTargetDesc {
  { texture, load_op, store_op, clear_color, resolve_texture }
}

///|
pub(all) struct DepthTargetDesc {
  texture : Texture
  load_op : LoadOp
  store_op : StoreOp
  clear_depth : Float
}

///|
pub fn DepthTargetDesc::new(
  texture : Texture,
  load_op? : LoadOp = LoadOp::Clear,
  store_op? : StoreOp = StoreOp::DontCare,
  clear_depth? : Float = (1.0 : Float),
) -> DepthTargetDesc {
  { texture, load_op, store_op, clear_depth }
}

// Re-export window events and key codes so users only need `@rhi`.

///|
pub type Event = @win.Event

///|
pub const KEY_ESCAPE : Int = @win.KEY_ESCAPE

///|
pub const KEY_RETURN : Int = @win.KEY_RETURN

///|
pub const KEY_SPACE : Int = @win.KEY_SPACE

///|
pub const KEY_LEFT : Int = @win.KEY_LEFT

///|
pub const KEY_UP : Int = @win.KEY_UP

///|
pub const KEY_RIGHT : Int = @win.KEY_RIGHT

///|
pub const KEY_DOWN : Int = @win.KEY_DOWN

///|
pub const KEY_W : Int = @win.KEY_W

///|
pub const KEY_A : Int = @win.KEY_A

///|
pub const KEY_S : Int = @win.KEY_S

///|
pub const KEY_D : Int = @win.KEY_D

// Shader & image loading helpers (delegated to laplaceliu/tycho_shader).

///|
fn shader_kind(stage : ShaderStage) -> UInt32 {
  match stage {
    ShaderStage::Vertex => @shader.SHADER_KIND_VERTEX
    ShaderStage::Fragment => @shader.SHADER_KIND_FRAGMENT
    ShaderStage::Compute => @shader.SHADER_KIND_COMPUTE
  }
}

///|
pub fn compile_glsl(path : String, stage : ShaderStage) -> FixedArray[UInt32] {
  @shader.compile_shader_file(path, shader_kind(stage))
}

///|
pub fn compile_glsl_source(source : String, stage : ShaderStage) -> FixedArray[UInt32] {
  @shader.compile_shader(source, shader_kind(stage))
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
