// Shape dump for HarfBuzz comparison.
// Usage: shape-dump <font.ttf> <text>   (size fixed at 48px for now)

///|
fn parse_uint(s : String) -> Int {
  let mut v = 0
  for c in s {
    let d = c.to_int()
    if d >= 48 && d <= 57 {
      v = v * 10 + (d - 48)
    }
  }
  v
}

///|
fn main {
  let args = @env.args()
  if args.length() < 3 {
    println("usage: shape-dump <font.ttf> <text> [size_px] [wght]")
    return
  }
  let font_path = args[1]
  let text = args[2]
  let size = if args.length() >= 4 {
    Float::from_int(parse_uint(args[3]))
  } else {
    (48.0 : Float)
  }
  let bytes = @image.read_file_bytes(font_path)
  let font = match @g2d.FontFace::from_ttf_bytes(bytes) {
    Some(f) => f
    None => {
      println("{\"error\":\"failed to parse font\"}")
      return
    }
  }
  // Optional 5th argument: wght axis value (variable fonts).
  if args.length() >= 5 {
    font.set_variation("wght", Float::from_int(parse_uint(args[4])))
  }
  let para = @g2d.ParagraphBuilder::new()
    .add_text(
      text,
      style=@g2d.TextStyle::new(font=font, font_size=size),
    )
    .build()
  para.layout((1.0e9 : Float))
  let glyphs : Array[String] = []
  for g in para.placed_glyphs() {
    glyphs.push(
      "{\"gid\":\{g.glyph_id},\"cp\":\{g.codepoint},\"cluster\":\{g.char_index},\"advance\":\{g.advance},\"x\":\{g.x},\"y\":\{g.baseline_y}}",
    )
  }
  println(
    "{\"font\":\"\{font_path}\",\"text\":\"\{text}\",\"size\":\{size},\"glyphs\":[\{glyphs.join(",")}]}",
  )
}
