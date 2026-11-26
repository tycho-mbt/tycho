# laplaceliu/tycho_vulkan

Pure-MoonBit Vulkan bindings generated directly from Khronos `vk.xml` (Vulkan-Headers 1.4.363).

`1.4.363` is the Khronos header/spec revision used at **generation time**, not a requirement on the machine that consumes this package: headers are vendored in-package and every command is resolved at runtime via `vkGetInstanceProcAddr` / `vkGetDeviceProcAddr`, so any Vulkan loader ≥ 1.0 works and no LunarG Vulkan SDK is needed. Applications built on `laplaceliu/tycho` additionally need a Vulkan **1.3+** driver (dynamic rendering + synchronization2).

- **Zero user C**: write Vulkan applications in 100% pure MoonBit — all struct/union accessors, three-layer `FuncRef` dispatch tables (`Entry` / `InstanceFn` / `DeviceFn`), `pNext` pointer chaining, `FuncRef` callbacks, and GC array pinning live inside this module.
- **Self-contained for mooncakes.io**: Vulkan 1.4.363 C headers are vendored inside `include/vulkan/` and included relatively, requiring no external `-I` flags or Vulkan SDK installation for downstream users.
- **Minimal native dependency**: zero link-time flags (`-lvulkan` / `vulkan-1.lib` are not needed; the Vulkan loader is resolved at runtime via `dlopen` / `LoadLibraryA`).
- **Compile-time ABI audited**: generated stubs include thousands of static-assert checks verifying every struct field and command scalar parameter width against MoonBit types.

## Usage

```moonbit
// moon.pkg
import {
  "laplaceliu/tycho_vulkan" @vk,
}
```

No `cc-link-flags` are required on Linux, Windows, or macOS.
