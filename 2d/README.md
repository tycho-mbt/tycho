# `laplaceliu/tycho_2d`

Skia / Impeller-inspired pure-MoonBit 2D vector, text, and compositing graphics engine built on `laplaceliu/tycho` and `laplaceliu/tycho_math`.

## Highlights
- **Canvas & DisplayList**: Declarative `Canvas` (`save`/`restore`, `save_layer`, `save_backdrop_layer`, transforms, clipping) recording immutable `DisplayList`s, plus paired helpers `with_save(fn)` / `with_layer(fn)` so scopes cannot leak a missing `restore()`.
- **Scoped passes**: every self-contained pass records through `cmd.render_pass(…)` / `cmd.swapchain_pass(…)` (downsample, blur H/V, MSAA resolve, batched path flush, present). The frame pass is the one exception: `draw_path_gpu` suspends it to render an offscreen effect and `begin_target_pass` resumes it, so that pass keeps the explicit `begin_render_pass` / `end_render_pass` pair.
- **Ergonomic API**: every optional argument uses native MoonBit optional parameters (`shader? : Shader2D`, `bounds? : Rect`, `fallback? : FontFallbackChain`, …), `Image2D::from_bytes(w, h, pixels)` allocates its own cache id, `BoxShadow::new(color, dx=…, dy=…, blur=…, spread=…)` replaces the anonymous float shadow arguments, and both render entries take the target first: `render_offscreen(target, dl)` / `render_swapchain(sc, dl)`.
- **Offscreen Target First**: `Renderer2D::render_offscreen(target, display_list, …)` and `Renderer2D::render_swapchain(swapchain, display_list, …)` share one argument order.
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
