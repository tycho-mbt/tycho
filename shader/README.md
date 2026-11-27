# laplaceliu/tycho_shader

Optional shader compilation and asset loading helpers for the Tycho graphics stack:

- GLSL → SPIR-V compilation by invoking `glslangValidator` (`compile_shader`,
  `compile_shader_file`, `compile_shader_env`, `compile_shader_file_env`), with
  `ShaderStage` / `ShaderTarget` enums instead of raw `UInt32` magic numbers
- Slang → SPIR-V compilation by invoking `slangc` (`compile_slang`,
  `compile_slang_file`)
- `*_checked` variants raise `ShaderError` (`CompileFailed(stage, diagnostics)` /
  `SlangFailed(entry, diagnostics)`): the C shim keeps the last tool output, so
  `last_error()` and the raised payload carry the real compiler message instead
  of an empty array
- Binary `.spv` file loader (`load_spirv`)
- Pure-MoonBit SPIR-V bytecode reflector (`reflect_spirv` — extracts stage, vertex inputs, descriptor bindings, push constant size, MRT output count with zero external C deps)
- PPM (P6) / BMP image decoding to RGBA8 (`load_image`)
- PNG encoding of RGBA8 readback buffers (`save_png`); rows are filtered per row
  (None/Sub/Up/Average/Paeth, chosen by minimum absolute sum) and compressed with a
  real deflate stream, so a 480x320 screenshot is a few KB instead of `w*h*4 + ~400`
  bytes. `bgra=true` swaps the red/blue channels first, which Vulkan swapchain
  readbacks on Windows need
- Radiance `.hdr` decoding to linear `Float` RGB pixels (`load_hdr_image`)

Zero C link dependencies: compilers are resolved from `TYCHO_GLSLANG` / `TYCHO_SLANGC`,
beside the executable, or on `PATH`; images are decoded by bundled `stb_image.h` and
encoded by bundled `stb_image_write.h` (both public domain, compiled into the shim).
Decoupled from `laplaceliu/tycho_vulkan`, so core Vulkan users need neither
`libshaderc-dev` nor `libstb-dev`.

Runtime tools (only when you actually compile at runtime): `glslangValidator`
(`glslang-tools` on Debian/Ubuntu) and, for Slang, `slangc`.
