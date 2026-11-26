# laplaceliu/tycho_shader

Optional shader compilation and asset loading helpers for the Tycho graphics stack:

- GLSL → SPIR-V compilation by invoking `glslangValidator` (`compile_shader`, `compile_shader_file`, `compile_shader_env`, `compile_shader_file_env`)
- Slang → SPIR-V compilation by invoking `slangc` (`compile_slang`, `compile_slang_file`)
- Binary `.spv` file loader (`load_spirv`)
- Pure-MoonBit SPIR-V bytecode reflector (`reflect_spirv` — extracts stage, vertex inputs, descriptor bindings, push constant size, MRT output count with zero external C deps)
- PPM (P6) / BMP image decoding to RGBA8 (`load_image`)
- PNG encoding of RGBA8 readback buffers (`save_png`)
- Radiance `.hdr` decoding to linear `Float` RGB pixels (`load_hdr_image`)

Zero C link dependencies: compilers are resolved from `TYCHO_GLSLANG` / `TYCHO_SLANGC`,
beside the executable, or on `PATH`; images are decoded by a bundled minimal loader.
Decoupled from `laplaceliu/tycho_vulkan`, so core Vulkan users need neither
`libshaderc-dev` nor `libstb-dev`.

Runtime tools (only when you actually compile at runtime): `glslangValidator`
(`glslang-tools` on Debian/Ubuntu) and, for Slang, `slangc`.
