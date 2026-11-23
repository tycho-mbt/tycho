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
  mipmap : Filter
  address : AddressMode
  min_lod : Float
  max_lod : Float
  mip_lod_bias : Float
}

///|
pub fn SamplerDesc::new(
  mag? : Filter = Filter::Linear,
  min? : Filter = Filter::Linear,
  mipmap? : Filter = Filter::Linear,
  address? : AddressMode = AddressMode::Repeat,
  min_lod? : Float = (0.0 : Float),
  max_lod? : Float = (1000.0 : Float),
  mip_lod_bias? : Float = (0.0 : Float),
) -> SamplerDesc {
  { mag, min, mipmap, address, min_lod, max_lod, mip_lod_bias }
}

///|
pub(all) struct PipelineDesc {
  vert : FixedArray[UInt32]
  frag : FixedArray[UInt32]
  vertex_formats : Array[VertexFormat]
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
  cull_mode : CullMode
  front_face : FrontFace
  blend : Bool
  samples : SampleCount
  color_format : TextureFormat?
  color_formats : Array[TextureFormat]
}

///|
pub fn PipelineDesc::new(
  vert : FixedArray[UInt32],
  frag : FixedArray[UInt32],
  vertex_formats? : Array[VertexFormat] = [],
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
  cull_mode? : CullMode = CullMode::None,
  front_face? : FrontFace = FrontFace::Clockwise,
  blend? : Bool = false,
  samples? : SampleCount = SampleCount::X1,
  color_format? : TextureFormat? = None,
  color_formats? : Array[TextureFormat] = [],
) -> PipelineDesc {
  {
    vert,
    frag,
    vertex_formats,
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
    cull_mode,
    front_face,
    blend,
    samples,
    color_format,
    color_formats,
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
// inputs, descriptor bindings, push constant byte size, and MRT color targets.
pub fn PipelineDesc::from_spirv(
  vert : FixedArray[UInt32],
  frag : FixedArray[UInt32],
  depth_test? : Bool = false,
  depth_write? : Bool = false,
  cull_mode? : CullMode = CullMode::None,
  front_face? : FrontFace = FrontFace::Clockwise,
  blend? : Bool = false,
  samples? : SampleCount = SampleCount::X1,
  color_format? : TextureFormat? = None,
  color_formats? : Array[TextureFormat] = [],
) -> PipelineDesc {
  let vr = @shader.reflect_spirv(vert)
  let fr = @shader.reflect_spirv(frag)
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
      @shader.ReflectedDescriptorKind::CombinedImageSampler =>
        push_unique_int(t_binds, b.binding)
      @shader.ReflectedDescriptorKind::StorageBuffer =>
        push_unique_int(s_binds, b.binding)
      @shader.ReflectedDescriptorKind::StorageImage =>
        push_unique_int(si_binds, b.binding)
    }
  }
  u_binds.sort_by(fn(a, b) { a - b })
  t_binds.sort_by(fn(a, b) { a - b })
  s_binds.sort_by(fn(a, b) { a - b })
  si_binds.sort_by(fn(a, b) { a - b })
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
    vertex_formats~,
    uniform_slots=u_binds.length(),
    texture_slots=t_binds.length(),
    storage_slots=s_binds.length(),
    storage_image_slots=si_binds.length(),
    uniform_bindings=u_binds,
    texture_bindings=t_binds,
    storage_bindings=s_binds,
    storage_image_bindings=si_binds,
    push_constant_size~,
    depth_test~,
    depth_write~,
    cull_mode~,
    front_face~,
    blend~,
    samples~,
    color_format~,
    color_formats=resolved_formats,
  )
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
