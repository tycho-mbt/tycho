// Image IO for the Tycho stack: one typed entry point for decoding
// PNG/JPEG/BMP/TGA/GIF/PSD/HDR/PNM in pure MoonBit (a faithful port of
// stb_image v2.34), reading raw files, and encoding PNG.

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
pub fn Image::new(
  width : Int,
  height : Int,
  format : ImageFormat,
  data : Bytes,
) -> Image {
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
/// Radiance HDR image: linear RGBA float pixels, row-major.
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
/// Decode any stb_image-supported format (PNG/JPEG/BMP/TGA/GIF/PSD/HDR/PNM)
/// from memory to straight-alpha RGBA8 in pure MoonBit.
pub fn decode_rgba(bytes : Bytes) -> Image raise ImageError {
  if bytes.length() == 0 {
    raise ImageError::DecodeFailed("empty image data")
  }
  match stbi_load_from_memory(bytes, desired_channels=4) {
    Some(img) => Image::rgba8(img.width, img.height, img.data)
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
/// Load an image file (PNG/JPEG/BMP/TGA/GIF/PSD/HDR/PNM) to RGBA8 in pure MoonBit.
pub fn load_image(path : String) -> Image raise ImageError {
  let bytes = read_file_bytes(path)
  if bytes.length() == 0 {
    raise ImageError::DecodeFailed(path)
  }
  match stbi_load_from_memory(bytes, desired_channels=4) {
    Some(img) => Image::rgba8(img.width, img.height, img.data)
    None => raise ImageError::DecodeFailed(path)
  }
}

///|
/// Decode a Radiance `.hdr` (or LDR converted to linear float) image from memory
/// to linear RGBA float pixels in pure MoonBit.
pub fn decode_hdr(bytes : Bytes) -> HdrImage raise ImageError {
  if bytes.length() == 0 {
    raise ImageError::DecodeFailed("empty image data")
  }
  match stbi_loadf_from_memory(bytes, desired_channels=4) {
    Some(img) => { width: img.width, height: img.height, pixels: img.data }
    None => raise ImageError::DecodeFailed("unsupported or corrupt HDR data")
  }
}

///|
/// Read a Radiance `.hdr` file as linear RGBA float pixels in pure MoonBit.
pub fn load_hdr(path : String) -> HdrImage raise ImageError {
  let bytes = read_file_bytes(path)
  if bytes.length() == 0 {
    raise ImageError::DecodeFailed(path)
  }
  match stbi_loadf_from_memory(bytes, desired_channels=4) {
    Some(img) => { width: img.width, height: img.height, pixels: img.data }
    None => raise ImageError::DecodeFailed(path)
  }
}

///|
/// Encode `image` as PNG. `bgra=true` swaps red/blue first, which Vulkan
/// swapchain readbacks on some drivers need.
pub fn save_png(
  path : String,
  image : Image,
  bgra? : Bool = false,
) -> Unit raise ImageError {
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
