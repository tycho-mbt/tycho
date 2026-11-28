# `laplaceliu/tycho_image`

Typed image IO and pure MoonBit `stb_image` v2.34 decoder for the Tycho stack.

## What it provides

- **Pure MoonBit `stb_image` v2.34 decoder** (no C FFI for decoding):
  - Formats: **PNG** (1/2/4/8/16-bit, all color types, PLTE, tRNS, all 5 filters, Adam7 interlacing, iPhone CgBI), **JPEG** (baseline & progressive, 1/3/4 components, YCbCr, Adobe RGB, CMYK, YCCK, restart markers, arbitrary integer subsampling), **BMP** (1/4/8/16/24/32-bit, OS/2 & Windows v1/v3/v4/v5 headers, `BI_RGB` & `BI_BITFIELDS`), **TGA** (uncompressed & RLE, grayscale/truecolor/color-mapped, 8/15/16/24/32-bit), **GIF** (87a/89a, LZW, transparency, interlacing, single-frame & multi-frame animation with disposal modes), **PSD** (8/16-bit raw & 8-bit PackBits RLE), **HDR** (Radiance RGBE raw & RLE), **PNM** (P2/P3 ASCII and P5/P6 binary PGM/PPM, 8/16-bit), plus **zlib/DEFLATE**.
  - `stbi_*` entry points: `stbi_load_from_memory`, `stbi_load_16_from_memory`, `stbi_loadf_from_memory`, `stbi_load_gif_from_memory`, `stbi_info_from_memory`, `stbi_is_16_bit_from_memory`, `stbi_is_hdr_from_memory`, `stbi_zlib_decode`, `stbi_zlib_decode_noheader`.
  - Behavior is locked down against upstream C `stb_image.h` v2.34 via binary golden data (`testdata/golden.bin`).
- **High-level Tycho image API**:
  - `Image { width, height, format, data : Bytes }` with `ImageFormat` (`RGBA8` / `RGBA8Srgb` / `R32Float`) — row-major, tightly packed pixels.
  - `HdrImage { width, height, pixels : FixedArray[Float] }` for linear Radiance `.hdr` content.
  - `ImageError` (`DecodeFailed` / `IoFailed` / `EncodeFailed`).
  - Decoding: `decode_rgba(bytes)`, `load_rgba(path)`, `load_image(path)`, `decode_hdr(bytes)`, `load_hdr(path)`.
  - Encoding: `save_png(path, image, bgra?)` / `save_png_rgba(path, w, h, data)` (via `laplaceliu/tycho_shader`).
  - File access: `read_file_bytes(path)` and `read_file_bytes_checked(path) raise ImageError`.

## Example

```moonbit
let img = @image.load_rgba("assets/logo.png")
let tex = dev.create_texture_format(img.width, img.height, @tycho.TextureFormat::RGBA8, img.data)
```
