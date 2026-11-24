# Tycho — Pure-MoonBit Native Graphics Stack

> Write Vulkan & RHI graphics code directly in MoonBit with **zero user C**, packaged cleanly for [mooncakes.io](https://mooncakes.io) under the `laplaceliu/*` namespace.

## Architecture (Multi-Module Workspace)

| Module (`mooncakes.io`) | Directory | Purpose | Native Link Deps |
|---|---|---|---|
| `laplaceliu/tycho_vulkan` | `vulkan/` | Pure-MoonBit Vulkan bindings generated from `vk.xml` 1.4.363 (root package, headers vendored in-package: no Vulkan SDK needed; runtime needs a 1.3+ loader/driver) | `-lvulkan` |
| `laplaceliu/tycho_window` | `window/` | Thin native window + input events + Vulkan WSI surface helper (Xlib on Linux, zero GLFW dependency) | `-lX11 -lvulkan` |
| `laplaceliu/tycho_shader` | `shader/` | GLSL (`glslangValidator`), Slang (`slangc`), pure-MoonBit SPIR-V reflection (`reflect_spirv`), & PPM/BMP image helpers | *(none)* |
| `laplaceliu/tycho` | `tycho/` | Unified pure-MoonBit RHI over Vulkan 1.3 dynamic rendering, sync2, 2 frames-in-flight, free-list sub-allocator, auto-reflected pipelines (`from_spirv`), MRT, mipmaps, storage images, and GPU timestamps (zero C stubs) | `-lvulkan -lX11` |
| `laplaceliu/tycho_codegen` *(private)* | `codegen/` | Khronos `vk.xml` → MoonBit + C shim generator | *(none)* |
| `laplaceliu/tycho_vulkan_examples` *(private)* | `examples/` | 42 pure-MoonBit examples (31 low-level Vulkan API suites at **100.0%** reachable Linux coverage + 11 unified `@tycho` demos) | `-lvulkan` (`-lX11` for WSI) |

Planned next phase:
- Add `laplaceliu/tycho_metal` (macOS/iOS) and `laplaceliu/tycho_dx12` (Windows) backends under `laplaceliu/tycho`, plus cross-platform shader compilation.

## Key Design Improvements for `mooncakes.io`

1. **Clean root package import**: users import `"laplaceliu/tycho_vulkan" @vk` or `"laplaceliu/tycho" @tycho` directly (no `/generated` subpackage).
2. **Self-contained vendored headers**: Vulkan 1.4.363 C headers (including `vk_video/`) live inside `vulkan/include/vulkan/` and are included via relative `#include "include/vulkan/vulkan.h"` — requiring **zero `-I` flags** and **zero Vulkan SDK** for downstream consumers. `1.4.363` is only the Khronos header/spec revision shipped with the package: it never forces a matching loader, because every command is fetched through `vkGetInstanceProcAddr` / `vkGetDeviceProcAddr` and the RHI requests API version **1.3**.
3. **Minimal native coupling**: `laplaceliu/tycho_vulkan` links **only `-lvulkan`** (no `shaderc`, `stb`, `glfw`, or `X11` required). `vk.xml` stays in `codegen/registry/` so the published `laplaceliu/tycho_vulkan` tarball stays compact (~1.3 MB).
4. **Compile-time ABI audit**: generated stubs embed thousands of `_Static_assert` checks enforcing `sizeof(C type) <= MoonBit type width` across all generated struct fields and scalar command parameters.

## Runtime Requirements (downstream users)

The `1.4.363` number is the Khronos header/spec revision used **at generation time only**. It does not dictate what the end user must install:

| Requirement | Why | Not required |
|---|---|---|
| Vulkan loader (`libvulkan.so.1`) ≥ 1.3 | RHI creates the instance with `apiVersion = 1.3` (`tycho/vk_backend.mbt`) | LunarG **Vulkan SDK** |
| GPU driver supporting Vulkan 1.3 (`dynamicRendering` + `synchronization2`) | RHI core path; checked explicitly, missing support raises `DeviceFailed` instead of crashing | matching 1.4.363 headers on the system |
| `-lvulkan` at link time (`libvulkan-dev` on Debian/Ubuntu) | link flag declared in `vulkan/moon.pkg` | `-I`, `VULKAN_SDK`, or any SDK env var |

Bindings never reference 1.4-only entry points: all 813 commands go through `vkGetInstanceProcAddr` / `vkGetDeviceProcAddr`, so an older 1.3 loader is enough (verified against `libvulkan.so.1.3.204` on Ubuntu 22.04, which does not even export 1.4 or `NV` extension symbols). On a pre-1.3 loader the RHI reports `VK_ERROR_INCOMPATIBLE_DRIVER` with an explicit hint.

## Upgrading to a Newer Vulkan SDK / `vk.xml`

Bindings are generated, not hand-written, so an upstream bump is a regeneration rather than a port:

```bash
./tools/update-vulkan-headers.sh /path/to/VulkanSDK/<new>/x86_64   # headers + vk.xml
./generate.sh                                                      # vk.xml -> 6 generated files, rebuild
./check-generated.sh                                               # committed output must match
moon test --target native
./tools/run-all.sh both && ./tools/coverage.py
```

Automatic on upgrade:

| Area | Behaviour |
|---|---|
| New commands | `Entry` / `InstanceFn` / `DeviceFn` regenerate; pointers stay lazily resolved, so a new command adds no link-time dependency |
| New structs / members | accessors and `sType` auto-fill regenerate from `vk.xml` |
| ABI drift | regenerated `_Static_assert(sizeof(C field) <= MoonBit width)` fails the build loudly instead of corrupting memory |
| New enum / bitmask values | typed `UInt32` / `UInt64` constants; 64-bit groups are detected from the header typedefs |
| Types with platform-only members | skipped, not fatal — the rest of the binding still builds |

Still manual:

1. **New platform header**: the update script only refreshes the headers this package already vendors and *lists* the ones upstream adds; pass `--add-headers` to adopt them (this also widens the compilable surface that `tools/coverage.py` measures). If a backend needs one, add a matching `VK_USE_PLATFORM_*` entry to the `platforms` map in `codegen/main.mbt` (plus WSI wiring in `tycho_window`).
2. **The RHI is hand-written** and stays on Vulkan 1.3: header bumps do not move its runtime requirement. Adopting a newer core version is a deliberate change in `tycho/vk_backend.mbt` (`set_apiVersion`), not part of an upgrade.
3. **Doc numbers** (`813` commands, `5,520` constants, `664/664` coverage) are quoted for 1.4.363 and need a refresh; `tools/coverage.py` recomputes them from `vk.xml`.
4. **Package versions**: bump the four published `moon.mod` versions and republish in dependency order; dependents pin an exact version (`@0.2.1` today), so their `import` lines move too.

## Linux Vulkan API Coverage

All 42 examples pass on both `lavapipe` and `nvidia` drivers with zero validation errors.
`OK` always implies at least one executed command: an example whose extension batch a driver
cannot provide reports `SKIP` (exit 0, tallied separately by `tools/run-all.sh`), and an example
that advertises a group but executes none of it reports `FAIL`:
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

Link flags do **not** propagate from a dependency package in MoonBit, so the
consuming executable must declare them in its own `moon.pkg`:

```moonbit
options(
  "link": {
    "native": {
      "cc": "cc",
      "cc-link-flags": "-lvulkan -lX11", // drop -lX11 if you never create a window
    },
  },
)
```

(Every example under `examples/` does this; it is why they link without extra flags.)

Or publish from source in dependency order (after `moon login` as `laplaceliu`):

```bash
(cd vulkan && moon publish)
(cd shader && moon publish)
(cd window && moon publish)
(cd tycho && moon publish)
```

Use `moon publish --dry-run` to validate packaging and standalone `moon check` before releasing.
