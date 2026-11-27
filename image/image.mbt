// Image IO for the Tycho stack: one typed entry point for decoding
// PNG/JPEG/PPM/BMP to RGBA8, decoding Radiance HDR to linear float pixels,
// reading raw files, and encoding PNG. The heavy lifting stays in
// `laplaceliu/tycho_shader` (bundled stb_image / stb_image_write), so callers
// get `Image` / `ImageError` instead of `(Bytes, Int32, Int32)` tuples.

///|
#derive(Eq, Debug)
pub(all) enum ImageFormat {
  RGBA8
  RGBA8Srgb
  R32Float
}

///|
/// A decoded image: row-major, tightly packed pixels in `format`.
pub(all) struct Image {
  width : Int
  height : Int
  format : ImageFormat
  data : Bytes
}

///|
pub fn Image::new(width : Int, height : Int, format : ImageFormat, data : Bytes) -> Image {
  { width, height, format, data }
}

///|
pub fn Image::rgba8(width : Int, height : Int, data : Bytes) -> Image {
  { width, height, format: ImageFormat::RGBA8, data }
}

///|
pub fn Image::is_empty(self : Image) -> Bool {
  self.width <= 0 || self.height <= 0 || self.data.length() == 0
}

///|
/// Expected pixel byte count for the pitched layout (`RGBA8` / `R32Float`).
pub fn Image::byte_size(self : Image) -> Int {
  self.width * self.height * 4
}

///|
/// Radiance HDR image: linear RGB triples, row-major.
pub(all) struct HdrImage {
  width : Int
  height : Int
  pixels : FixedArray[Float]
}

///|
pub fn HdrImage::is_empty(self : HdrImage) -> Bool {
  self.width <= 0 || self.height <= 0 || self.pixels.length() == 0
}

///|
pub suberror ImageError {
  DecodeFailed(String)
  IoFailed(String)
  EncodeFailed(String)
}

///|
/// Decode PNG/JPEG (and the PPM/BMP variants stb_image accepts) from memory.
pub fn decode_rgba(bytes : Bytes) -> Image raise ImageError {
  if bytes.length() == 0 {
    raise ImageError::DecodeFailed("empty image data")
  }
  match @shader.decode_image(bytes) {
    Some((px, w, h)) => Image::rgba8(w, h, px)
    None => raise ImageError::DecodeFailed("unsupported or corrupt image data")
  }
}

///|
/// Read and decode an image file to straight-alpha RGBA8.
pub fn load_rgba(path : String) -> Image raise ImageError {
  decode_rgba(read_file_bytes_checked(path))
}

///|
/// Read raw bytes, raising `IoFailed` when the file is missing or empty.
pub fn read_file_bytes_checked(path : String) -> Bytes raise ImageError {
  let bytes = @shader.read_file_bytes(path)
  if bytes.length() == 0 {
    raise ImageError::IoFailed(path)
  }
  bytes
}

///|
/// Read raw bytes, returning an empty `Bytes` when the file cannot be read.
/// The `_checked` variant is preferred when the caller must distinguish a
/// missing file from an empty one.
pub fn read_file_bytes(path : String) -> Bytes {
  @shader.read_file_bytes(path)
}

///|
/// Load an image file through the PPM/BMP/TGA path stb_image exposes by name
/// (PNG/JPEG go through `load_rgba`).
pub fn load_image(path : String) -> Image raise ImageError {
  let (pixels, w, h) = @shader.load_image(path)
  if w <= 0 || h <= 0 || pixels.length() == 0 {
    raise ImageError::DecodeFailed(path)
  }
  Image::rgba8(w.to_int(), h.to_int(), Bytes::from_array(pixels[:]))
}

///|
/// Read a Radiance `.hdr` file as linear float pixels.
pub fn load_hdr(path : String) -> HdrImage raise ImageError {
  let (pixels, w, h) = @shader.load_hdr_image(path)
  if w <= 0 || h <= 0 || pixels.length() == 0 {
    raise ImageError::DecodeFailed(path)
  }
  { width: w.to_int(), height: h.to_int(), pixels }
}

///|
/// Encode `image` as PNG. `bgra=true` swaps red/blue first, which Vulkan
/// swapchain readbacks on some drivers need.
pub fn save_png(path : String, image : Image, bgra? : Bool = false) -> Unit raise ImageError {
  match image.format {
    ImageFormat::R32Float =>
      raise ImageError::EncodeFailed("save_png expects an 8-bit RGBA image")
    _ => ()
  }
  if image.is_empty() {
    raise ImageError::EncodeFailed("cannot encode an empty image")
  }
  let rgba : FixedArray[Byte] = FixedArray::make(image.data.length(), (0 : Byte))
  for i = 0; i < image.data.length(); i = i + 1 {
    rgba[i] = image.data[i]
  }
  if !@shader.save_png(path, image.width, image.height, rgba, bgra~) {
    raise ImageError::EncodeFailed(path)
  }
}

///|
/// Convenience overload of `save_png` for raw readback buffers.
pub fn save_png_rgba(
  path : String,
  width : Int,
  height : Int,
  data : Bytes,
  bgra? : Bool = false,
) -> Unit raise ImageError {
  save_png(path, Image::rgba8(width, height, data), bgra~)
}
