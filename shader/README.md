# laplaceliu/tycho_shader

Optional shader compilation and asset loading helpers for the Tycho graphics stack:

- In-process GLSL → SPIR-V compilation via `libshaderc` (`compile_shader`, `compile_shader_file`, `compile_shader_env`, `compile_shader_file_env`)
- Slang → SPIR-V compilation via `slangc` (`compile_slang`, `compile_slang_file`)
- Binary `.spv` file loader (`load_spirv`)
- Pure-MoonBit SPIR-V bytecode reflector (`reflect_spirv` — extracts stage, vertex inputs, descriptor bindings, push constant size, MRT output count with zero external C deps)
- Image decoding (`load_image`)

Decoupled from `laplaceliu/tycho_vulkan` so core Vulkan users do not need `libshaderc-dev` or `libstb-dev`.
