# Tycho — Pure-MoonBit Native Graphics Stack

> Write Vulkan & RHI graphics code directly in MoonBit with **zero user C**, packaged cleanly for [mooncakes.io](https://mooncakes.io) under the `laplaceliu/*` namespace.

## Architecture (Multi-Module Workspace)

| Module (`mooncakes.io`) | Directory | Purpose | Native Link Deps |
|---|---|---|---|
| `laplaceliu/tycho_vulkan` | `vulkan/` | Pure Vulkan 1.4.363 bindings generated from `vk.xml` (root package, self-contained vendored headers) | `-lvulkan` |
| `laplaceliu/tycho_window` | `window/` | Thin native window + input events + Vulkan WSI surface helper (Xlib on Linux, zero GLFW dependency) | `-lX11 -lvulkan` |
| `laplaceliu/tycho_shader` | `shader/` | GLSL (`glslangValidator`), Slang (`slangc`), pure-MoonBit SPIR-V reflection (`reflect_spirv`), & PPM/BMP image helpers | *(none)* |
| `laplaceliu/tycho` | `tycho/` | Unified pure-MoonBit RHI over Vulkan 1.3 dynamic rendering, sync2, 2 frames-in-flight, free-list sub-allocator, auto-reflected pipelines (`from_spirv`), MRT, mipmaps, storage images, and GPU timestamps (zero C stubs) | `-lvulkan -lX11` |
| `laplaceliu/tycho_codegen` *(private)* | `codegen/` | Khronos `vk.xml` → MoonBit + C shim generator | *(none)* |
| `laplaceliu/tycho_vulkan_examples` *(private)* | `examples/` | 42 pure-MoonBit examples (31 low-level Vulkan API suites at **100.0%** reachable Linux coverage + 11 unified `@rhi` demos) | `-lvulkan` (`-lX11` for WSI) |

Planned next phase:
- Add `laplaceliu/tycho_metal` (macOS/iOS) and `laplaceliu/tycho_dx12` (Windows) backends under `laplaceliu/tycho`, plus cross-platform shader compilation.

## Key Design Improvements for `mooncakes.io`

1. **Clean root package import**: users import `"laplaceliu/tycho_vulkan" @vk` or `"laplaceliu/tycho" @rhi` directly (no `/generated` subpackage).
2. **Self-contained vendored headers**: Vulkan 1.4.363 C headers (including `vk_video/`) live inside `vulkan/include/vulkan/` and are included via relative `#include "include/vulkan/vulkan.h"` — requiring **zero `-I` flags** and **zero Vulkan SDK** for downstream consumers.
3. **Minimal native coupling**: `laplaceliu/tycho_vulkan` links **only `-lvulkan`** (no `shaderc`, `stb`, `glfw`, or `X11` required). `vk.xml` stays in `codegen/registry/` so the published `laplaceliu/tycho_vulkan` tarball stays compact (~1.3 MB).
4. **Compile-time ABI audit**: generated stubs embed thousands of `_Static_assert` checks enforcing `sizeof(C type) <= MoonBit type width` across all generated struct fields and scalar command parameters.

## Linux Vulkan API Coverage

All 42 examples pass on both `lavapipe` and `nvidia` drivers with zero validation errors:
- Desktop Vulkan commands in `vk.xml`: **813 / 813** exercised in pure MoonBit
- Host-reachable commands on Linux (`lavapipe` + `nvidia`): **664 / 664 (100.0%)**

## Quick Start (Linux)

```bash
# 1. Setup C99 compiler toolchain & check native dependencies
./setup-linux.sh

# 2. Build all modules and verification suites
./build.sh

# 3. Run unit tests
moon test --target native

# 4. Run all 42 pure-MoonBit verification examples on lavapipe + NVIDIA
./tools/run-all.sh both

# 5. Measure reproducible Linux Vulkan API coverage
./tools/coverage.py

# 6. CI gates
./check-generated.sh       # codegen zero-diff check
./check-examples-pure.sh   # assert zero .c / native-stub in examples
```

## Publishing to `mooncakes.io`

Install in downstream MoonBit packages with:

```bash
moon add laplaceliu/tycho_vulkan
moon add laplaceliu/tycho_shader
moon add laplaceliu/tycho_window
moon add laplaceliu/tycho
```

Or publish from source in dependency order (after `moon login` as `laplaceliu`):

```bash
(cd vulkan && moon publish)
(cd shader && moon publish)
(cd window && moon publish)
(cd tycho && moon publish)
```

Use `moon publish --dry-run` to validate packaging and standalone `moon check` before releasing.
