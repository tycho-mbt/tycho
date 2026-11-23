# laplaceliu/tycho_shader

Optional shader compilation and asset loading helpers for the Tycho graphics stack:

- In-process GLSL → SPIR-V compilation via `libshaderc` (`compile_shader`, `compile_shader_file`, `compile_shader_env`, `compile_shader_file_env`)
- Slang → SPIR-V compilation via `slangc` (`compile_slang`, `compile_slang_file`)
- Binary `.spv` file loader (`load_spirv`)
- Image decoding via `stb_image` (`load_image`)

Decoupled from `laplaceliu/tycho_vulkan` so core Vulkan users do not need `libshaderc-dev` or `libstb-dev`.
