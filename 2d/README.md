# `laplaceliu/tycho_2d`

Skia / Impeller-inspired pure-MoonBit 2D vector, text, and compositing graphics engine built on `laplaceliu/tycho` and `laplaceliu/tycho_math`.

## Highlights
- **Canvas & DisplayList**: Declarative `Canvas` (`save`/`restore`, `save_layer`, `save_backdrop_layer`, transforms, clipping) recording immutable `DisplayList`s.
- **Tier-1 SDF & Atlas Batching**: Instanced per-corner rounded rectangles, borders, analytical drop shadows, multi-stop linear/radial/sweep gradients, `R8` glyph & `RGBA8` image atlases (`SkylinePacker`).
- **Tier-2 Vector Paths**: Adaptive Bézier flattening, `Depth24Stencil8` Stencil-then-Cover (`NonZero` & `EvenOdd`), and `Butt`/`Round`/`Square` + `Miter`/`Round`/`Bevel` stroke expansion.
- **Overlay Composition**: `render_swapchain(..., load_op=Load)` and
  `render_swapchain_pass(cmd, sc, dl)` draw a display list over an existing
  swapchain image (e.g. a 3D frame) with premultiplied blending, enabling
  3D + HUD composition without an intermediate copy.
- **Tier-3 Layers & Blur**: Pooled offscreen `RenderTargetPool` for group opacity, blend modes (`SrcOver`, `Multiply`, `DstIn`, `SrcIn`), and Gaussian `BackdropFilter` blur.
- **Pure-MoonBit Text**: Built-in fallback font + TrueType `.ttf` parser & scanline AA rasterizer + `Paragraph` layout (`get_position_for_offset`, `get_caret_rect`, `get_boxes_for_range`).
- **Zero Runtime Shader Compiler Dependency**: AOT embedded SPIR-V (`shaders_spv.mbt`) and zero `.c` stubs or `cc-link-flags`.
- **Shared math kernel**: scalar/trigonometry helpers (`clamp_f`, `lerp_f`, `sin_cos`, `atan2`) come from `laplaceliu/tycho_math` instead of local approximations, and `Matrix3` converts losslessly to/from `Affine2` (`to_affine2` / `from_affine2`) so a 2D UI transform can be promoted into a 3D scene.
