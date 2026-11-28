# Example conventions

`examples/` is one MoonBit module (`laplaceliu/tycho_vulkan_examples`) that holds every runnable
example, grouped by layer (`rhi/`, `dx12/`, `vulkan/`, `3d/`, `2d/`, `ui/`, ...). An example is an
executable package `examples/<group>/<name>/` with a `README.md` and, when it renders a frame, a
committed 800x600 `screenshot.png`.

**If you are a coding agent, treat this file as the contract for window and screenshot behavior.**
The policy is implemented once and must not be copied into an example:

| Package | Owns |
|---|---|
| `examples/exwin` | CLI flags, `Options::parse`, `Options::capture`, the 800x600 frame size and letterbox math |
| `examples/exwin_rhi` | `@tycho` swapchain: open, event loop, resize, capture |
| `examples/exwin_native` | the native window used by raw `tycho_vulkan` / `tycho_dx12` examples |
| `examples/exwin_2d` | aspect-preserving fit of a fixed 2D canvas into the window |

The user-facing summary is the root README section `Example Window & CLI Policy` (`../README.md`).

## 1. Window and CLI contract

Every example that opens a window or writes a screenshot accepts exactly these flags, parsed by
`@exwin.Options::parse`. Do not parse `@env.args()` yourself and do not invent per-example flags.
Raw API/COM coverage suites (`dx12/raw-*`, most `vulkan/*` chapters) neither own a window nor
capture, so they take no flags and must not start parsing arguments.

| Flag | Meaning |
|---|---|
| `--window` | open the interactive window |
| `--screenshot <path>` | write the verified frame as an 800x600 PNG |
| `--size <W>x<H>` | window size, default 800x600 |
| `--help` | print usage and exit 0 |

Each option has exactly one spelling. The `TYCHO_WINDOW` / `TYCHO_SCREENSHOT`
environment variables are the no-argument equivalent for tooling, not extra
flag spellings (section 8).

```moonbit
fn main {
  let opts = @exwin.Options::parse("<group>/<name>")
  ...
}
```

- `opts.name` must be the folder path (`"dx12/triangle"`); it is the window title and the log tag.
- Parse once, as the first statement of `main`.
- Use `opts.width` / `opts.height` for the window and swapchain instead of hard-coded sizes, so
  `--size` keeps working.
- The offscreen verification canvas is 800x600 unless the example is one of the documented
  fixed-canvas exceptions (section 4.1).

## 2. Headless first, window second

An example is a test first and a demo second.

1. Render and verify **headless** by default (`headless = !opts.window`), assert the pixels or
   buffers, and print exactly one result line (section 3).
2. Only when `opts.window` is true, open a window and keep presenting until the user asks to quit.
   The verification frames have already run; the interactive loop is extra.

Never create a window on the headless path, and never make the verification result depend on the
window. Use the shared loops instead of a hand-written one:

```moonbit
// @tycho RHI examples: 800x600 by default, readback enabled
let sc = @exwin_rhi.open(dev, opts, depth=false, clear_color=...)
while @exwin_rhi.next_frame(sc) {
  ...
}
```

- `@exwin_rhi.next_frame` already handles Esc, the close button and `sync_size()` on resize. Use
  `@exwin_rhi.poll(sc)` only when the loop body needs the events (camera, hover, IME).
- Raw backend examples (`tycho_vulkan`, `tycho_dx12`) use `@exwin_native.open(opts)`,
  `native_handle`, `next_frame`, `size` and `destroy`.
- 2D examples author at a fixed logical canvas and call `@exwin_2d.fit(dl, w, h, sc)` in the window
  loop so the preview and the PNG letterbox identically.

Do not re-implement `should_close`, Esc handling, resize adoption or presentation in an example.

## 3. Result lines

Print exactly one final line, prefixed with `[` + `opts.name` + `]`:

```text
[<group>/<name>] OK — <what was verified> (..., 0 validation errors)
[<group>/<name>] FAIL — <what failed> (...)
[<group>/<name>] SKIP — <missing host capability>
```

- `tools/run-ci-suite.py` fails on any `FAIL` word or a non-zero exit code, counts `SKIP`
  separately, and rejects vacuous passes (`OK — 0 ...`). Keep the words uppercase on the result
  line.
- Because CI scans the whole stdout, do not use the words `FAIL` or `SKIP` in other log lines; a
  stray match changes how the example is classified.
- `SKIP` is only for a capability the host does not have (no `d3d12.dll`, no mesh-shader support,
  DXR tier below 1.1, no swapchain on a session-0 runner). It is never a substitute for an
  assertion you did not implement.
- Never print `OK` when a check was skipped or when nothing was verified.

The screenshot line (`[<group>/<name>] screenshot=<path> ok`) is printed by `Options::capture` and
is not the result line.

## 4. Screenshot contract

### 4.1 Size: 800x600, no letterbox bars

- Every committed `screenshot.png` under `examples/` is **800x600**. Frames written through
  `@shader.save_png` are opaque RGBA8 (the writer forces alpha to 255).
- A new example renders its verification frame at **800x600** (4:3) and passes exactly that size to
  the capture call, so the PNG fills the frame edge to edge.
- `Options::capture` still letterboxes any other canvas into 800x600 (aspect preserved,
  nearest-neighbour, centred on black). A few existing tests deliberately verify a smaller offscreen
  target (a 32x32 sampler grid, a 256x256 MSAA resolve, the fixed-size 2D scenes at 1920x1080 /
  960x320); their PNGs keep black bars. That is a legacy exception, not a template: for a new
  example choose 800x600 unless the canvas size itself is what the assertions are about. Never add
  letterboxing to an example, and do not crop or stretch to fill the frame.
- Do not pick a small canvas (64x64, 128x128, 480x320) to make a test cheaper. If a check only needs
  a few samples, sample fewer coordinates while still rendering 800x600.
- `--size` only changes the window/swapchain. Do not pass it when generating a committed
  screenshot; regenerate at the default 800x600.

### 4.2 Capture the verified frame

```moonbit
// raw backends and any headless frame
opts.capture(width, height, pixels)

// @tycho RHI examples: byte order is taken from the swapchain format
@exwin_rhi.capture(opts, sc, pixels)
```

- Capture the exact pixels the assertions ran on, before destroying the render target, readback
  buffer or swapchain. Never render a second frame just for the PNG.
- Pass `bgra=true` when the pixels come from a B8G8R8A8_UNORM target; `@exwin_rhi.capture` does
  this automatically.
- Call `capture` unconditionally: it is a no-op without `--screenshot`, and keeping the call site
  exercised is what the committed screenshots rely on.
- The helper prints `[<group>/<name>] screenshot=<path> ok`.

### 4.3 Commit the PNG and the README section

- Place `screenshot.png` next to the example's `main.mbt` and `README.md`.
- The example README starts with `# <group>/<name>` and contains this section:

```markdown
## Screenshot

![<group>/<name> screenshot](./screenshot.png)
```

- Regenerate the PNG after any change that can alter the image (shader, clear colour, canvas size,
  geometry, sampling):

```powershell
# Windows
moon build --target native examples/<group>/<name>
.\_build\native\debug\build\laplaceliu\tycho_vulkan_examples\<group>\<name>\<name>.exe --screenshot examples/<group>/<name>/screenshot.png
```

```bash
# Linux / macOS: same path without .exe
moon build --target native examples/<group>/<name>
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/<group>/<name>/<name> --screenshot examples/<group>/<name>/screenshot.png
```

- Only commit a screenshot produced by a run that printed `OK` and `screenshot=... ok`. If a failed
  or skipped run left a PNG behind, delete it.
- Commit the screenshot in the same change as the visual change it documents.
- Never hand-edit, crop, resize or recompress a committed screenshot.

## 5. Window-only examples

A few examples verify through a swapchain to prove presentation itself and therefore create a
window even without `--window` (`dx12/present`, `dx12/uniform`, `dx12/rhi-triangle`). They must say
so in their README, report `SKIP` when the host refuses a swapchain, and still produce an 800x600
PNG. Do not copy that shape for a new example unless presentation is the thing being verified.

## 6. Changing an existing example

- Changing the canvas size means updating the pixel helper stride, every sample coordinate,
  `size_ok`, and the expected output in the README. Then regenerate the screenshot.
- Changing a shader means regenerating the embedded artifact with the generator named in the
  example README (for example `tools/gen-dx12-shaders.py` for DX12 HLSL or
  `tools/gen-dual-shaders.py` for Slang) and passing its `--check` drift gate. Then regenerate the
  screenshot.
- Never leave a committed screenshot older than the rendering code it documents.

## 7. Checklist for a new rendering example

- [ ] `examples/<group>/<name>/` builds with `moon build --target native examples/<group>/<name>`.
- [ ] `main` starts with `@exwin.Options::parse("<group>/<name>")`; the name matches the folder.
- [ ] Headless run asserts real pixels or buffers, reports 0 validation errors, and prints one
      `OK` / `FAIL` line.
- [ ] Missing host capabilities report `SKIP`, not `OK`.
- [ ] `--window` uses the shared helper and quits on Esc, the close button and resize.
- [ ] Verified frame is 800x600 and captured with `Options::capture` (or `@exwin_rhi.capture`).
- [ ] `screenshot.png` is committed, 800x600, has no letterbox bars, and is linked from the
      example README under `## Screenshot`.
- [ ] `README.md` documents what the example proves, the run command and the expected output.
- [ ] Run all three modes before finishing: headless, `--window`, `--screenshot <path>`.

## 8. Environment variables

- `TYCHO_WINDOW=1` and `TYCHO_SCREENSHOT=<path>` mirror `--window` and `--screenshot`; CI uses them
  instead of rewriting command lines.
- Backend escape hatches stay in the backend documentation (`TYCHO_DX12_WARP=1`,
  `TYCHO_D3D12_LIB` / `TYCHO_DXGI_LIB`, `TYCHO_VULKAN_LIB`, ...). Do not add new environment
  variables for window or screenshot behavior.
