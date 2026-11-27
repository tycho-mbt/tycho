# `laplaceliu/tycho_image`

Typed image IO for the Tycho stack, sitting on top of
`laplaceliu/tycho_shader` (bundled `stb_image` / `stb_image_write`).

## What it provides

- `Image { width, height, format, data : Bytes }` with `ImageFormat`
  (`RGBA8` / `RGBA8Srgb` / `R32Float`) — row-major, tightly packed pixels.
- `HdrImage { width, height, pixels : FixedArray[Float] }` for linear Radiance
  `.hdr` content.
- `ImageError` / `DecodeFailed` / `IoFailed` / `EncodeFailed` instead of
  `(Bytes, Int32, Int32)` tuples that silently return empty buffers.
- Decoding: `decode_rgba(bytes)` (PNG/JPEG from memory), `load_rgba(path)`,
  `load_image(path)` (PPM/BMP/TGA), `load_hdr(path)`.
- Encoding: `save_png(path, image, bgra?)` / `save_png_rgba(path, w, h, data)`.
- File access: `read_file_bytes(path)` (empty on failure) and
  `read_file_bytes_checked(path) raise ImageError`.

## Why a separate package

`laplaceliu/tycho` (the RHI) and `laplaceliu/tycho_2d` are meant to stay free of
image/asset helpers: the RHI used to re-export `load_image` / `decode_image` /
`save_png` / `load_hdr_image` / `read_file_bytes`, which mixed GPU API surface
with asset IO. Those live here now, behind one typed `Image` value.

## Example

```moonbit
let img = @image.load_rgba("assets/logo.png")
let tex = dev.create_texture_format(img.width, img.height, @tycho.TextureFormat::RGBA8, img.data)
```
