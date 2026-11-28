// Unified window / CLI policy shared by every Tycho example.
//
// Before this package each example rolled its own argument handling, window
// size and event loop, so `--window` meant something slightly different in
// every folder (and a resize silently corrupted the presentation in the ones
// that forgot `sync_size`). Everything CLI-shaped now lives here, so one
// contract covers the low-level Vulkan suites, the unified RHI demos and the
// 2D/3D/UI layers on Linux, Windows and macOS:
//
//   --window                         open an interactive window (TYCHO_WINDOW=1)
//   --screenshot <path>              save the verified frame as PNG
//                                    (TYCHO_SCREENSHOT=<path>)
//   --size <W>x<H>                   override the window size
//   --help                           print the contract above and exit 0
//
// There is exactly one spelling per option; the two `TYCHO_*` variables are the
// no-argument equivalent for tooling, not additional flag spellings.
//
// Without `--window` an example runs headless: it renders offscreen, asserts
// the pixels and prints one `OK — …` / `FAIL — …` line, so a GPU-less CI runner
// can verify it. With `--window` it opens a `DEFAULT_WIDTH`x`DEFAULT_HEIGHT`
// window whose title is the example path, and closes on the window button or
// Esc.
//
// Every example therefore presents and captures the *same* 800x600 frame, even
// when its verification canvas has another size: `--screenshot` letterboxes the
// rendered pixels into 800x600 (aspect preserved, never cropped or stretched),
// so the committed `screenshot.png` files all share one size.

/// The one window and screenshot size every example uses.
pub const DEFAULT_WIDTH : Int = 800

///|
pub const DEFAULT_HEIGHT : Int = 600

///|
/// What an example learned from the command line.
///
/// `name` doubles as the window title and the log tag (`[rhi/triangle]`), so a
/// window can always be traced back to the folder it came from.
pub(all) struct Options {
  name : String
  width : Int
  height : Int
  window : Bool
  screenshot : String
}

///|
/// The contract above, ready to print.
pub fn usage(name : String) -> String {
  let dw = DEFAULT_WIDTH
  let dh = DEFAULT_HEIGHT
  "usage: \{name} [--window] [--screenshot <path>] [--size <W>x<H>]\n\n" +
  "  --window\n" +
  "      open an interactive window (window button or Esc closes it);\n" +
  "      env: TYCHO_WINDOW=1\n" +
  "  --screenshot <path>\n" +
  "      write the verified frame as a \{dw}x\{dh} PNG (letterboxed to that\n" +
  "      size when the canvas differs); env: TYCHO_SCREENSHOT=<path>\n" +
  "  --size <W>x<H>\n" +
  "      window size in pixels, default \{dw}x\{dh}\n" +
  "  --help\n" +
  "      print this help\n\n" +
  "Without --window the example runs headless: it renders offscreen, asserts\n" +
  "its pixels and prints a single `OK — …` or `FAIL — …` line."
}

///|
/// Parse the shared flags for `name`.
///
/// The window is always `DEFAULT_WIDTH`x`DEFAULT_HEIGHT`; `--size` is the only
/// way to change it, so every example opens the same window and every capture
/// has the same size.
pub fn Options::parse(name : String) -> Options {
  let base = {
    name,
    width: DEFAULT_WIDTH,
    height: DEFAULT_HEIGHT,
    window: env_truthy("TYCHO_WINDOW"),
    screenshot: env_var("TYCHO_SCREENSHOT"),
  }
  base.with_args(@env.args())
}

///|
/// The same flags, resolved from an explicit argument vector (tests and tools).
fn Options::with_args(self : Options, args : Array[String]) -> Options {
  let mut window = self.window
  let mut screenshot = self.screenshot
  let mut width = self.width
  let mut height = self.height
  let mut i = 1
  while i < args.length() {
    let a = args[i]
    if a == "--window" {
      window = true
    } else if a == "--help" {
      println(usage(self.name))
      @env.exit(0)
    } else if a == "--screenshot" {
      if i + 1 < args.length() {
        i = i + 1
        screenshot = args[i]
      } else {
        eprintln("[" + self.name + "] --screenshot needs a path; ignoring")
      }
    } else if a == "--size" {
      if i + 1 < args.length() {
        i = i + 1
        match parse_size(args[i]) {
          Some(size) => {
            width = size.0
            height = size.1
          }
          None => eprintln("[" + self.name + "] --size " + args[i] + " is not <W>x<H>; ignoring")
        }
      } else {
        eprintln("[" + self.name + "] --size needs <W>x<H>; ignoring")
      }
    }
    i = i + 1
  }
  { name: self.name, width, height, window, screenshot }
}

///|
/// Write `pixels` to the `--screenshot` path as a `DEFAULT_WIDTH`x
/// `DEFAULT_HEIGHT` PNG, as RGBA8 unless `bgra`.
///
/// `pixels` is the frame the example verified, so its size is the example's
/// canvas size, not necessarily 800x600. Scaling would distort and cropping
/// would hide part of the assertion target, so the frame is letterboxed:
/// aspect-preserving, nearest-neighbour, centred on black. That keeps every
/// committed screenshot the same size whatever the example renders internally.
///
/// A no-op when the flag is absent, so a call site is always one line and
/// every example reports captures the same way.
pub fn Options::capture(
  self : Options,
  width : Int,
  height : Int,
  pixels : FixedArray[Byte],
  bgra? : Bool = false,
) -> Unit {
  if self.screenshot == "" {
    return
  }
  let ok = @shader.save_png(
    self.screenshot,
    DEFAULT_WIDTH,
    DEFAULT_HEIGHT,
    letterbox(width, height, pixels, bgra=bgra),
  )
  let status = if ok { "ok" } else { "failed" }
  println("[" + self.name + "] screenshot=" + self.screenshot + " " + status)
}

///|
/// The size `width` x `height` occupies inside the canonical frame, aspect
/// preserved. `@exwin_2d` reuses the same math so the window preview and the
/// screenshot letterbox exactly the same way.
pub fn fit_size(width : Int, height : Int) -> (Int, Int) {
  fit_size_into(width, height, DEFAULT_WIDTH, DEFAULT_HEIGHT)
}

///|
/// The size `width` x `height` occupies inside a `box_w` x `box_h` frame,
/// aspect preserved and centred by the caller.
pub fn fit_size_into(width : Int, height : Int, box_w : Int, box_h : Int) -> (Int, Int) {
  if width <= 0 || height <= 0 || box_w <= 0 || box_h <= 0 {
    return (box_w, box_h)
  }
  let (dw, dh) = if width * box_h >= height * box_w {
    (box_w, height * box_w / width)
  } else {
    (width * box_h / height, box_h)
  }
  ((if dw < 1 { 1 } else { dw }), (if dh < 1 { 1 } else { dh }))
}

///|
/// Copy `pixels` into a `DEFAULT_WIDTH`x`DEFAULT_HEIGHT` RGBA8 frame, centred
/// with black bars, sampling nearest-neighbour so previews stay pixel-crisp.
fn letterbox(
  width : Int,
  height : Int,
  pixels : FixedArray[Byte],
  bgra? : Bool = false,
) -> FixedArray[Byte] {
  let cw = DEFAULT_WIDTH
  let ch = DEFAULT_HEIGHT
  let out = FixedArray::make(cw * ch * 4, (0 : Byte))
  if width <= 0 || height <= 0 || pixels.length() < width * height * 4 {
    return out
  }
  let (dw, dh) = fit_size(width, height)
  let off_x = (cw - dw) / 2
  let off_y = (ch - dh) / 2
  for y = 0; y < dh; y = y + 1 {
    let sy = y * height / dh
    for x = 0; x < dw; x = x + 1 {
      let sx = x * width / dw
      let si = (sy * width + sx) * 4
      let di = ((y + off_y) * cw + (x + off_x)) * 4
      let r = pixels[si].to_int()
      let b = pixels[si + 2].to_int()
      out[di] = (if bgra { b } else { r }).to_byte()
      out[di + 1] = pixels[si + 1]
      out[di + 2] = (if bgra { r } else { b }).to_byte()
      out[di + 3] = pixels[si + 3]
    }
  }
  out
}

///|
fn parse_size(s : String) -> (Int, Int)? {
  let mut width = 0
  let mut height = 0
  let mut in_height = false
  let mut digits = 0
  for c in s {
    let sep = c == 'x' || c == 'X' || c == '*'
    if sep {
      if in_height || digits == 0 {
        return None
      }
      in_height = true
      digits = 0
    } else {
      let d = c.to_int() - 48
      if d < 0 || d > 9 {
        return None
      }
      if in_height {
        height = height * 10 + d
      } else {
        width = width * 10 + d
      }
      digits = digits + 1
    }
  }
  if !in_height || digits == 0 || width <= 0 || height <= 0 {
    return None
  }
  Some((width, height))
}

///|
fn env_truthy(key : String) -> Bool {
  let v = env_var(key)
  v == "1" || v.equal_ignore_ascii_case("true") || v.equal_ignore_ascii_case("yes")
}

///|
fn env_var(key : String) -> String {
  match @env.get_env_var(key) {
    Some(v) => v
    None => ""
  }
}
