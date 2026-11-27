// The flag contract is the only thing every example agrees on, so it is tested
// rather than documented twice.

///|
test "size parsing accepts the documented forms" {
  assert_eq(parse_size("1280x720"), Some((1280, 720)))
  assert_eq(parse_size("800X600"), Some((800, 600)))
  assert_eq(parse_size("640*480"), Some((640, 480)))
}

///|
test "size parsing rejects malformed values" {
  assert_eq(parse_size(""), None)
  assert_eq(parse_size("800"), None)
  assert_eq(parse_size("800x"), None)
  assert_eq(parse_size("x600"), None)
  assert_eq(parse_size("800x600x2"), None)
  assert_eq(parse_size("800px600"), None)
  assert_eq(parse_size("0x600"), None)
}

///|
test "defaults are the shared 800x600 policy" {
  let opts = Options::parse("rhi/triangle")
  assert_eq(opts.name, "rhi/triangle")
  assert_eq(opts.width, DEFAULT_WIDTH)
  assert_eq(opts.height, DEFAULT_HEIGHT)
}

///|
test "--size overrides the canonical window size" {
  let base = Options::parse("2d/msdf")
  assert_eq(base.width, DEFAULT_WIDTH)
  assert_eq(base.height, DEFAULT_HEIGHT)
  let opts = base.with_args(["exe", "--size", "1920x1080"])
  assert_eq(opts.width, 1920)
  assert_eq(opts.height, 1080)
}

///|
test "--size=<W>x<H> is accepted too" {
  let opts = Options::parse("rhi/triangle").with_args(["exe", "--size=1024x768"])
  assert_eq(opts.width, 1024)
  assert_eq(opts.height, 768)
}

///|
test "--screenshot takes the next argument or =value" {
  let spaced = Options::parse("rhi/triangle").with_args(["exe", "--screenshot", "out.png"])
  assert_eq(spaced.screenshot, "out.png")
  let joined = Options::parse("rhi/triangle").with_args(["exe", "--screenshot=out2.png"])
  assert_eq(joined.screenshot, "out2.png")
}

///|
test "every accepted --window spelling opens a window" {
  for flag in ["--window", "-w", "--show", "--screen"] {
    let opts = Options::parse("rhi/triangle").with_args(["exe", flag])
    assert_true(opts.window)
  }
}

///|
test "headless is the default and unknown flags are ignored" {
  let opts = Options::parse("rhi/triangle").with_args(["exe", "--frames", "3"])
  assert_false(opts.window)
  assert_eq(opts.screenshot, "")
  assert_eq(opts.width, DEFAULT_WIDTH)
}

///|
test "every screenshot size fits the canonical frame" {
  // Already canonical: untouched.
  assert_eq(fit_size(800, 600), (800, 600))
  // Wider than 4:3: width-bound, bars above and below.
  assert_eq(fit_size(1920, 1080), (800, 450))
  assert_eq(fit_size(960, 320), (800, 266))
  // Taller than 4:3: height-bound, bars left and right.
  assert_eq(fit_size(128, 128), (600, 600))
  assert_eq(fit_size(480, 320), (800, 533))
  // Same aspect as the frame: fills it exactly.
  assert_eq(fit_size(400, 300), (800, 600))
  // Degenerate sizes never produce a zero-width band.
  assert_eq(fit_size(0, 0), (800, 600))
  assert_eq(fit_size(2000, 1), (800, 1))
}

///|
test "letterbox centres a 16:9 frame with black bars" {
  let w = 1920
  let h = 1080
  let px = FixedArray::make(w * h * 4, (0 : Byte))
  for i = 0; i < w * h; i = i + 1 {
    px[i * 4] = (200 : Byte)
    px[i * 4 + 1] = (100 : Byte)
    px[i * 4 + 2] = (50 : Byte)
    px[i * 4 + 3] = (255 : Byte)
  }
  let out = letterbox(w, h, px)
  assert_eq(out.length(), DEFAULT_WIDTH * DEFAULT_HEIGHT * 4)
  // 800x450 centred in 800x600 -> 75 black rows, then content.
  let top = (10 * DEFAULT_WIDTH + 400) * 4
  assert_eq(out[top].to_int(), 0)
  let mid = (300 * DEFAULT_WIDTH + 400) * 4
  assert_eq(out[mid].to_int(), 200)
  assert_eq(out[mid + 1].to_int(), 100)
  assert_eq(out[mid + 3].to_int(), 255)
}

///|
test "letterbox pills a square frame sideways and honours bgra" {
  let w = 128
  let h = 128
  let px = FixedArray::make(w * h * 4, (0 : Byte))
  for i = 0; i < w * h; i = i + 1 {
    // BGRA source: byte0 is blue.
    px[i * 4] = (10 : Byte)
    px[i * 4 + 2] = (240 : Byte)
    px[i * 4 + 3] = (255 : Byte)
  }
  let out = letterbox(w, h, px, bgra=true)
  let left_bar = (300 * DEFAULT_WIDTH + 40) * 4
  assert_eq(out[left_bar].to_int(), 0)
  // 600x600 centred -> content starts at x=100; red and blue are swapped back.
  let mid = (300 * DEFAULT_WIDTH + 400) * 4
  assert_eq(out[mid].to_int(), 240)
  assert_eq(out[mid + 2].to_int(), 10)
}

///|
test "letterbox keeps an undersized buffer black" {
  let out = letterbox(10, 10, FixedArray::make(4, (0 : Byte)))
  assert_eq(out.length(), DEFAULT_WIDTH * DEFAULT_HEIGHT * 4)
  let mut lit = 0
  for i = 0; i < out.length(); i = i + 1 {
    if out[i] != (0 : Byte) {
      lit = lit + 1
    }
  }
  assert_eq(lit, 0)
}

///|
test "the help text names every flag and the default size" {
  let text = usage("rhi/triangle")
  assert_true(text.contains("rhi/triangle"))
  assert_true(text.contains("--window"))
  assert_true(text.contains("--screenshot"))
  assert_true(text.contains("--size"))
  assert_true(text.contains("--help"))
  assert_true(text.contains("800x600"))
}
