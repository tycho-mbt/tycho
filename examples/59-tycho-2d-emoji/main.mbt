// 59 — color emoji + mixed-script fallback.
//
// Font fallback chain: DejaVuSans (Latin) -> DroidSansFallback (CJK) ->
// NotoColorEmoji (CBDT bitmaps). The host wires stb_image as the PNG decoder
// for CBDT glyphs, keeping tycho_2d itself free of native dependencies.

///|
fn load_font(path : String) -> @g2d.FontFace? {
  let bytes = @tycho.read_file_bytes(path)
  if bytes.length() == 0 {
    return None
  }
  @g2d.FontFace::from_ttf_bytes(bytes)
}

///|
fn main {
  try {
    @g2d.FontFace::set_png_decoder(fn(png) {
      match @tycho_shader.decode_image(png) {
        Some((rgba, w, h)) => Some(@g2d.DecodedImage::new(w, h, rgba))
        None => None
      }
    })
    let latin = load_font("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")
    let cjk = load_font("/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf")
    let emoji = load_font("/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf")
    match (latin, cjk, emoji) {
      (Some(latin_f), Some(cjk_f), Some(emoji_f)) => {
        let dev = @tycho.Device::new_desc(
          @tycho.DeviceDesc::new("59-tycho-2d-emoji", validation=true, headless=true),
        )
        let w = 360
        let h = 160
        let bg = @g2d.Color::from_rgba8(18, 22, 34)
        let chain = @g2d.FontFallbackChain::new(
          latin_f,
          fallbacks=[cjk_f, emoji_f],
        )
        let style = @g2d.TextStyle::new(
          font=latin_f,
          font_size=(48.0 : Float),
          color=@g2d.Color::white(),
          fallback=Some(chain),
        )
        let para = @g2d.ParagraphBuilder::new()
          .add_text("Hi 😀 中", style=style)
          .build()
        para.layout((400.0 : Float))
        let c = @g2d.Canvas::new()
        c.clear(bg)
        c.draw_paragraph(para, @g2d.Point::new((12.0 : Float), (30.0 : Float)))
        let renderer = @g2d.Renderer2D::new(dev)
        let rt = dev.create_render_target(w, h, @tycho.TextureFormat::RGBA8)
        renderer.render_offscreen(c.finish(), rt, clear_color=bg)
        let px = rt.readback()
        let mut yellow = 0
        let mut i = 0
        while i + 3 < px.length() {
          let r = px[i].to_int()
          let g = px[i + 1].to_int()
          let b = px[i + 2].to_int()
          if r > 180 && g > 120 && b < 140 {
            yellow = yellow + 1
          }
          i = i + 4
        }
        let bitmap_ok = match emoji_f.color_bitmap(0x1F600, (48.0 : Float)) {
          Some(cb) => cb.width > 0 && cb.height > 0 && cb.png.length() > 0
          None => false
        }

        let errs = dev.validation_errors()
        println(
          "{\"bitmap\":\{bitmap_ok},\"yellow_pixels\":\{yellow},\"glyphs\":\{para.placed_glyphs().length()}}",
        )
        let ok = bitmap_ok && yellow > 50 && errs == 0
        if ok {
          println(
            "[59-tycho-2d-emoji] OK — fallback Latin/CJK/CBDT emoji, yellow_pixels=\{yellow}, 0 validation errors",
          )
        } else {
          println(
            "[59-tycho-2d-emoji] FAIL — bitmap=\{bitmap_ok} yellow=\{yellow} errs=\{errs}",
          )
        }
        rt.destroy()
        renderer.destroy()
        dev.destroy()
      }
      _ =>
        println(
          "[59-tycho-2d-emoji] OK — skipped (DejaVu/Droid/NotoColorEmoji not installed)",
        )
    }
  } catch {
    err => println("[59-tycho-2d-emoji] FAIL — \{err}")
  }
}
