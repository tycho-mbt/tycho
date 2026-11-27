// 59 — color emoji + mixed-script fallback.
//
// Font fallback chain: DejaVuSans (Latin) -> DroidSansFallback (CJK) ->
// NotoColorEmoji (CBDT bitmaps). The host wires stb_image as the PNG decoder
// for CBDT glyphs, keeping tycho_2d itself free of native dependencies.
// --window for live preview, --screenshot <path> for PNG.

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
    let opts = @exwin.Options::parse("2d/emoji")
    let show_win = opts.window
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
          @tycho.DeviceDesc::new(
            "2d/emoji",
            validation=true,
            headless=!show_win,
          ),
        )
        let w = 640
        let h = 240
        let bg = @g2d.Color::from_rgba8(18, 22, 34)
        let chain = @g2d.FontFallbackChain::new(
          latin_f,
          fallbacks=[cjk_f, emoji_f],
        )
        let style = @g2d.TextStyle::new(
          font=latin_f,
          font_size=(64.0 : Float),
          color=@g2d.Color::white(),
          fallback=Some(chain),
        )
        let para = @g2d.ParagraphBuilder::new()
          .add_text("Hi 😀 中", style=style)
          .build()
        para.layout((600.0 : Float))
        let c = @g2d.Canvas::new()
        c.clear(bg)
        c.draw_paragraph(para, @g2d.Point::new((24.0 : Float), (60.0 : Float)))
        let dl = c.finish()
        let renderer = @g2d.Renderer2D::new(dev)
        let rt = dev.create_render_target(w, h, @tycho.TextureFormat::RGBA8)
        renderer.render_offscreen(dl, rt, clear_color=bg)
        let px = rt.readback()
        opts.capture(w, h, px)
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
        let bitmap_ok = match emoji_f.color_bitmap(0x1F600, (64.0 : Float)) {
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
            "[2d/emoji] OK — fallback Latin/CJK/CBDT emoji, yellow_pixels=\{yellow}, 0 validation errors",
          )
        } else {
          println(
            "[2d/emoji] FAIL — bitmap=\{bitmap_ok} yellow=\{yellow} errs=\{errs}",
          )
        }
        if show_win {
          let sc = @exwin_rhi.open(
            dev,
            opts,
            depth=true,
            depth_format=@tycho.TextureFormat::Depth24Stencil8,
            clear_color=bg.to_clear_color(),
          )
          while @exwin_rhi.next_frame(sc) {
            renderer.render_swapchain(sc, @exwin_2d.fit(dl, w, h, sc), clear_color=bg)
          }
          sc.destroy()
        }

        rt.destroy()
        renderer.destroy()
        dev.destroy()
      }
      _ =>
        println(
          "[2d/emoji] OK — skipped (DejaVu/Droid/NotoColorEmoji not installed)",
        )
    }
  } catch {
    err => println("[2d/emoji] FAIL — \{err}")
  }
}
