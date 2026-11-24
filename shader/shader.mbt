// Tycho shader & asset helpers: GLSL->SPIR-V (glslangValidator), Slang->SPIR-V
// (slangc), binary SPIR-V loading, and PPM/BMP image decoding. No C link deps.
// Decoupled from laplaceliu/tycho_vulkan so core Vulkan users need only -lvulkan.

pub const SHADER_KIND_VERTEX : UInt32 = 0
pub const SHADER_KIND_FRAGMENT : UInt32 = 1
pub const SHADER_KIND_COMPUTE : UInt32 = 2
pub const SHADER_KIND_TASK : UInt32 = 3
pub const SHADER_KIND_MESH : UInt32 = 4
pub const SHADER_KIND_RAYGEN : UInt32 = 5
pub const SHADER_KIND_ANYHIT : UInt32 = 6
pub const SHADER_KIND_CLOSESTHIT : UInt32 = 7
pub const SHADER_KIND_MISS : UInt32 = 8
pub const SHADER_KIND_INTERSECTION : UInt32 = 9
pub const SHADER_KIND_CALLABLE : UInt32 = 10

pub const SHADER_ENV_VULKAN_1_0 : UInt32 = 0
pub const SHADER_ENV_VULKAN_1_1 : UInt32 = 1
pub const SHADER_ENV_VULKAN_1_2 : UInt32 = 2
pub const SHADER_ENV_VULKAN_1_3 : UInt32 = 3

#borrow(path, out_count)
extern "c" fn load_spirv_ffi(
  path : Bytes,
  len : Int32,
  out_count : FixedArray[Int32],
) -> FixedArray[UInt32] = "tycho_shader_load_spirv"

///|
pub fn load_spirv(path : String) -> FixedArray[UInt32] {
  let b = @utf8.encode(path)
  load_spirv_ffi(b, b.length(), FixedArray::make(1, (0 : Int32)))
}

#borrow(path, out_w, out_h)
extern "c" fn load_image_ffi(
  path : Bytes,
  len : Int32,
  out_w : FixedArray[Int32],
  out_h : FixedArray[Int32],
) -> FixedArray[Byte] = "tycho_shader_load_image"

///|
pub fn load_image(path : String) -> (FixedArray[Byte], Int32, Int32) {
  let b = @utf8.encode(path)
  let w = FixedArray::make(1, (0 : Int32))
  let h = FixedArray::make(1, (0 : Int32))
  let px = load_image_ffi(b, b.length(), w, h)
  (px, w[0], h[0])
}

#borrow(source)
extern "c" fn compile_shader_ffi(
  source : Bytes,
  len : Int32,
  kind : UInt32,
) -> FixedArray[UInt32] = "tycho_shader_compile"

///|
pub fn compile_shader(source : String, kind : UInt32) -> FixedArray[UInt32] {
  let b = @utf8.encode(source)
  compile_shader_ffi(b, b.length(), kind)
}

#borrow(path)
extern "c" fn compile_shader_file_ffi(
  path : Bytes,
  len : Int32,
  kind : UInt32,
) -> FixedArray[UInt32] = "tycho_shader_compile_file"

///|
pub fn compile_shader_file(path : String, kind : UInt32) -> FixedArray[UInt32] {
  let b = @utf8.encode(path)
  compile_shader_file_ffi(b, b.length(), kind)
}

#borrow(source)
extern "c" fn compile_shader_env_ffi(
  source : Bytes,
  len : Int32,
  kind : UInt32,
  env : UInt32,
) -> FixedArray[UInt32] = "tycho_shader_compile_env"

///|
pub fn compile_shader_env(
  source : String,
  kind : UInt32,
  env : UInt32,
) -> FixedArray[UInt32] {
  let b = @utf8.encode(source)
  compile_shader_env_ffi(b, b.length(), kind, env)
}

#borrow(path)
extern "c" fn compile_shader_file_env_ffi(
  path : Bytes,
  len : Int32,
  kind : UInt32,
  env : UInt32,
) -> FixedArray[UInt32] = "tycho_shader_compile_file_env"

///|
pub fn compile_shader_file_env(
  path : String,
  kind : UInt32,
  env : UInt32,
) -> FixedArray[UInt32] {
  let b = @utf8.encode(path)
  compile_shader_file_env_ffi(b, b.length(), kind, env)
}

#borrow(source, entry)
extern "c" fn compile_slang_ffi(
  source : Bytes,
  slen : Int32,
  entry : Bytes,
  elen : Int32,
) -> FixedArray[UInt32] = "tycho_shader_compile_slang"

///|
pub fn compile_slang(source : String, entry : String) -> FixedArray[UInt32] {
  let s = @utf8.encode(source)
  let e = @utf8.encode(entry)
  compile_slang_ffi(s, s.length(), e, e.length())
}

#borrow(path, entry)
extern "c" fn compile_slang_file_ffi(
  path : Bytes,
  plen : Int32,
  entry : Bytes,
  elen : Int32,
) -> FixedArray[UInt32] = "tycho_shader_compile_slang_file"

///|
pub fn compile_slang_file(path : String, entry : String) -> FixedArray[UInt32] {
  let p = @utf8.encode(path)
  let e = @utf8.encode(entry)
  compile_slang_file_ffi(p, p.length(), e, e.length())
}

#borrow(path)
extern "c" fn read_file_ffi(path : Bytes, plen : Int32) -> Bytes = "tycho_shader_read_file"

///|
pub fn read_file_bytes(path : String) -> Bytes {
  let p = @utf8.encode(path)
  read_file_ffi(p, p.length())
}
