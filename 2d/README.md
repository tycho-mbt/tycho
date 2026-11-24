# `laplaceliu/tycho_2d`

Skia / Impeller-inspired pure-MoonBit 2D vector, text, and compositing graphics engine built on `laplaceliu/tycho`.

## Highlights
- **Canvas & DisplayList**: Declarative `Canvas` (`save`/`restore`, `save_layer`, `save_backdrop_layer`, transforms, clipping) recording immutable `DisplayList`s.
- **Tier-1 SDF & Atlas Batching**: Instanced per-corner rounded rectangles, borders, analytical drop shadows, multi-stop linear/radial/sweep gradients, `R8` glyph & `RGBA8` image atlases (`SkylinePacker`).
- **Tier-2 Vector Paths**: Adaptive Bézier flattening, `Depth24Stencil8` Stencil-then-Cover (`NonZero` & `EvenOdd`), and `Butt`/`Round`/`Square` + `Miter`/`Round`/`Bevel` stroke expansion.
- **Tier-3 Layers & Blur**: Pooled offscreen `RenderTargetPool` for group opacity, blend modes (`SrcOver`, `Multiply`, `DstIn`, `SrcIn`), and Gaussian `BackdropFilter` blur.
- **Pure-MoonBit Text**: Built-in fallback font + TrueType `.ttf` parser & scanline AA rasterizer + `Paragraph` layout (`get_position_for_offset`, `get_caret_rect`, `get_boxes_for_range`).
- **Zero Runtime Shader Compiler Dependency**: AOT embedded SPIR-V (`shaders_spv.mbt`) and zero `.c` stubs or `cc-link-flags`.
