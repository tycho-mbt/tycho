# 2d/emoji — color emoji + mixed-script fallback

Renders `Hi 😀 中` with a font fallback chain:

1. DejaVuSans (Latin)
2. DroidSansFallbackFull (CJK)
3. NotoColorEmoji (CBDT color bitmaps)

`tycho_2d` parses CBDT/CBLC and exposes a PNG-decoder hook; the host wires
`tycho_shader.decode_image` (stb_image) so the 2D core stays free of native
image dependencies. Color glyphs are uploaded to the RGBA color atlas and drawn
with the `kind=7` prim path.

## Run

```sh
cd tycho/examples
moon build --target native 2d/emoji
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/2d/emoji/emoji.exe
```

## Screenshot

![2d/emoji screenshot](./screenshot.png)

> Runs headless by default. Pass `--window` for interactive display or
> `--screenshot <path>` to capture PNG.

Sample output:

```json
{"bitmap":true,"yellow_pixels":2827,"glyphs":4}
[2d/emoji] OK — fallback Latin/CJK/CBDT emoji, yellow_pixels=2827, 0 validation errors
```
