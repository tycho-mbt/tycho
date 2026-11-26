// Tycho shader & asset helpers: GLSL->SPIR-V (glslangValidator), Slang->SPIR-V
// (slangc), binary SPIR-V loading, PPM/BMP/HDR/PNG image decoding, and filtered
// (deflate) PNG encoding. No C link deps.
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

#borrow(data, out_w, out_h)
extern "c" fn decode_image_ffi(
  data : Bytes,
  len : Int32,
  out_w : FixedArray[Int32],
  out_h : FixedArray[Int32],
) -> FixedArray[Byte] = "tycho_shader_decode_image"

///|
// Decode PNG/JPEG bytes to straight-alpha RGBA8. Returns None for unsupported
// or corrupt data.
pub fn decode_image(data : Bytes) -> (Bytes, Int, Int)? {
  let w = FixedArray::make(1, (0 : Int32))
  let h = FixedArray::make(1, (0 : Int32))
  let px = decode_image_ffi(data, data.length(), w, h)
  if w[0] <= 0 || h[0] <= 0 || px.length() == 0 {
    return None
  }
  Some((Bytes::from_array(px[:]), w[0].to_int(), h[0].to_int()))
}

///|
// Read and decode a PNG/JPEG file to straight-alpha RGBA8.
pub fn load_image_rgba(path : String) -> (Bytes, Int, Int)? {
  let bytes = read_file_bytes(path)
  if bytes.length() == 0 {
    return None
  }
  decode_image(bytes)
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

extern "c" fn want_window_ffi() -> Int32 = "tycho_shader_want_window"

///|
pub fn want_window() -> Bool {
  want_window_ffi() != 0
}

extern "c" fn screenshot_path_ffi() -> Bytes = "tycho_shader_screenshot_path"

///|
pub fn screenshot_path() -> String {
  let b = screenshot_path_ffi()
  if b.length() == 0 {
    return ""
  }
  @utf8.decode_lossy(b[:])
}

#borrow(path, rgba)
extern "c" fn save_png_ffi(
  path : Bytes,
  plen : Int32,
  w : Int32,
  h : Int32,
  rgba : FixedArray[Byte],
  bgra : Int32,
) -> Int32 = "tycho_shader_save_png"

///|
pub fn save_png(
  path : String,
  width : Int,
  height : Int,
  rgba : FixedArray[Byte],
  bgra? : Bool = false,
) -> Bool {
  let p = @utf8.encode(path)
  save_png_ffi(
    p,
    p.length(),
    width,
    height,
    rgba,
    if bgra { 1 } else { 0 },
  ) != 0
}

#borrow(path, out_w, out_h)
extern "c" fn load_hdr_ffi(
  path : Bytes,
  plen : Int32,
  out_w : FixedArray[Int32],
  out_h : FixedArray[Int32],
) -> FixedArray[Float] = "tycho_shader_load_hdr"

///|
pub fn load_hdr_image(path : String) -> (FixedArray[Float], Int32, Int32) {
  let p = @utf8.encode(path)
  let w = FixedArray::make(1, (0 : Int32))
  let h = FixedArray::make(1, (0 : Int32))
  let px = load_hdr_ffi(p, p.length(), w, h)
  (px, w[0], h[0])
}
