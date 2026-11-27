# vulkan/queries

Example 16 — physical-device query/enumeration coverage (headless).

Sweeps the reachable vkGetPhysicalDevice* / vkEnumerate* surface, including
the promoted core/KHR alias pairs, which are separate dispatch slots.
Extension-gated queries run only where the driver advertises them.

## Windowing

This example runs headless (offscreen compute/graphics/API verification) and does not open a window.

## Run

```bash
./build.sh
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/vulkan/queries/queries.exe
```

## Output

```text
[16-query] commands exercised=38 tools=1 groupCount=3
[16-query] OK — 38 query commands, validation layer visible via tool properties
```
