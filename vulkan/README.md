# laplaceliu/tycho_vulkan

Pure-MoonBit Vulkan 1.4 native bindings generated directly from Khronos `vk.xml` (Vulkan SDK 1.4.363).

- **Zero user C**: write Vulkan applications in 100% pure MoonBit — all struct/union accessors, three-layer `FuncRef` dispatch tables (`Entry` / `InstanceFn` / `DeviceFn`), `pNext` pointer chaining, `FuncRef` callbacks, and GC array pinning live inside this module.
- **Self-contained for mooncakes.io**: Vulkan 1.4.363 C headers are vendored inside `include/vulkan/` and included relatively, requiring no external `-I` flags or Vulkan SDK installation for downstream users.
- **Minimal native dependency**: only links `-lvulkan` (no shaderc, stb, or GLFW coupling).
- **Compile-time ABI audited**: generated stubs include thousands of `_Static_assert` checks verifying every struct field and command scalar parameter width against MoonBit types.

## Usage

```moonbit
// moon.pkg
import {
  "laplaceliu/tycho_vulkan" @vk,
}
```

Executable packages on Linux should include `"-lvulkan"` in `link.native.cc-link-flags`.
