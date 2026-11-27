# rhi/bench

Headless throughput benchmark and memory-leak regression gate for `@tycho`:

1. **SubAllocator Stress**: 500 interleaved `Buffer` (`256B..64KB`) and `Texture` allocations and destructions with a rolling 8-slot live window, verifying `allocator_used_bytes() == 0` afterwards.
2. **Draw-Call Throughput**: 500 push-constant draws inside a single dynamic render pass, measuring CPU command recording time and GPU execution time via `TimestampPool`, plus readback verification.
3. **Deferred Deletion Leak Gate**: 20 `submit_commands` + `Fence::wait()` frames creating and destroying transient buffers and render targets while in-flight, asserting non-zero peak in-flight allocation followed by `allocator_used_bytes() == 0` and `validation_errors() == 0`.

## Run

```bash
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/rhi/bench/bench.exe
```
