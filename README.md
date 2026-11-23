# Tycho — Pure-MoonBit Native Graphics Stack

> Write Vulkan graphics code directly in MoonBit with **zero user C**, packaged cleanly for [mooncakes.io](https://mooncakes.io) under the `laplaceliu/*` namespace.

## Architecture (Multi-Module Workspace)

| Module (`mooncakes.io`) | Directory | Purpose | Native Link Deps |
|---|---|---|---|
| `laplaceliu/tycho_vulkan` | `vulkan/` | Pure Vulkan 1.4.363 bindings generated from `vk.xml` (root package, self-contained vendored headers) | `-lvulkan` |
| `laplaceliu/tycho_window` | `window/` | Thin native window + Vulkan WSI surface helper (Xlib on Linux, zero GLFW dependency) | `-lX11 -lvulkan` |
| `laplaceliu/tycho_shader` | `shader/` | GLSL (`glslangValidator`), Slang (`slangc`), SPIR-V & PPM image helpers | *(none)* |
| `laplaceliu/tycho_codegen` *(private)* | `codegen/` | Khronos `vk.xml` → MoonBit + C shim generator | *(none)* |
| `laplaceliu/tycho_vulkan_examples` *(private)* | `examples/` | 26 pure-MoonBit Vulkan examples & Linux API verification batches | `-lvulkan` (`-lX11` for WSI) |

Planned next phase:
- `laplaceliu/tycho`: Unified cross-backend RHI (renamed from `rhi`), built atop `laplaceliu/tycho_vulkan`, `laplaceliu/tycho_metal`, and `laplaceliu/tycho_dx12`.

## Key Design Improvements for `mooncakes.io`

1. **Clean root package import**: users import `"laplaceliu/tycho_vulkan" @vk` directly (no `/generated` subpackage).
2. **Self-contained vendored headers**: Vulkan 1.4.363 C headers (including `vk_video/`) live inside `vulkan/include/vulkan/` and are included via relative `#include "include/vulkan/vulkan.h"` — requiring **zero `-I` flags** and **zero Vulkan SDK** for downstream consumers.
3. **Minimal native coupling**: `laplaceliu/tycho_vulkan` links **only `-lvulkan`** (no `shaderc`, `stb`, `glfw`, or `X11` required). `vk.xml` stays in `codegen/registry/` so the published `laplaceliu/tycho_vulkan` tarball stays compact (~1.3 MB).
4. **Compile-time ABI audit**: generated stubs embed thousands of `_Static_assert` checks enforcing `sizeof(C type) <= MoonBit type width` across all generated struct fields and scalar command parameters.

## Quick Start (Linux)

```bash
# 1. Setup C99 compiler toolchain & check native dependencies
./setup-linux.sh

# 2. Build all modules and verification suites
./build.sh

# 3. Run all 26 pure-MoonBit verification examples on lavapipe + NVIDIA
./tools/run-all.sh both

# 4. Measure reproducible Linux Vulkan API coverage
./tools/coverage.py

# 5. CI gates
./check-generated.sh       # codegen zero-diff check
./check-examples-pure.sh   # assert zero .c / native-stub in examples
```

## Publishing to `mooncakes.io`

Publish in dependency order (after `moon login` as `laplaceliu`):

```bash
(cd vulkan && moon publish)
(cd shader && moon publish)
(cd window && moon publish)
```

Use `moon publish --dry-run` to validate packaging and standalone `moon check` before releasing.
