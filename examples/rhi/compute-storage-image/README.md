# rhi/compute-storage-image

Generates a 128x128 RGBA8 gradient texture on the GPU via an auto-reflected compute pipeline (`create_compute_pipeline_auto`) writing to a storage image (`create_storage_texture` / `bind_storage_image`), measures GPU execution time with `TimestampPool`, transitions it for sampling (`transition_for_sampling`), and presents it to the swapchain.

## Run

```bash
./build.sh
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/rhi/compute-storage-image/compute-storage-image.exe
```

## Screenshot

![rhi/compute-storage-image screenshot](./screenshot.png)

> Runs headless by default for automated verification. Pass `--window` (or `TYCHO_WINDOW=1`) to render on screen.
