// Shape dump for HarfBuzz comparison.
// Usage: shape-dump <font.ttf> <text>   (size fixed at 48px for now)

///|
fn main {
  let args = @env.args()
  if args.length() < 3 {
    println("usage: shape-dump <font.ttf> <text> [size_px]")
    return
  }
  let font_path = args[1]
  let text = args[2]
  let size = (48.0 : Float)
  let bytes = @tycho.read_file_bytes(font_path)
  let font = match @g2d.FontFace::from_ttf_bytes(bytes) {
    Some(f) => f
    None => {
      println("{\"error\":\"failed to parse font\"}")
      return
    }
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
