# 75-dx12-present

Verifies the DXGI presentation path of `laplaceliu/tycho_dx12`: a real Win32 window
(`laplaceliu/tycho_window`) → flip-model swapchain → render into the current back buffer →
`Present`, plus a back-buffer readback and a `ResizeBuffers` cycle.

Each frame goes through the resource-state machine: `Present -> RenderTarget` for the clear and
the draw, `RenderTarget -> CopySource` for the readback copy, and back to `Present` before
presenting. A wrong state fails with `E_ILLEGAL_METHOD_CALL` instead of producing a silently
corrupt frame.

## Run

```powershell
moon build --target native examples/75-dx12-present
.\_build\native\debug\build\laplaceliu\tycho_vulkan_examples\75-dx12-present\75-dx12-present.exe
```

Expected:

```
[75-dx12-present] OK — DXGI flip-model presented 4 frames (480x320, occluded=0, adapter=hardware, resize ok, back-buffer readback verified, 0 validation errors)
```

`TYCHO_DX12_WARP=1` forces the WARP software adapter. Non-Windows hosts and windows the desktop
cannot present report `SKIP`, so the Linux gate stays green.

## Notes

- The swapchain cannot be released while the GPU still reads its back buffers. `Device::wait_idle()`
  runs before teardown; without it the debug layer reports
  `OBJECT_DELETED_WHILE_STILL_IN_USE` (and raises `0x87d`, which looks like a silent crash when no
  debugger is attached).
- The shader is a full-screen triangle in flat orange, so four samples across the readback frame
  must all match; that covers the viewport, the scissor and the flip-model copy in one check.
- DXIL for `shaders.hlsl` comes from `tools/gen-dx12-shaders.py` and is committed.
