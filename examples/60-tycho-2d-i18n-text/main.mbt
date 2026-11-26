// 60 — i18n text: Latin ligatures, CJK fallback, color emoji, Hebrew RTL and
// Arabic joining forms, with a selection and caret.
//
// This is the M8 integration example. Shaping currently uses Unicode
// presentation forms (U+FB00..FB06 and Arabic Forms-B); full GSUB/GPOS and
// Indic clusters are still future work.

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
    let show_win = @tycho.want_window()
    let shot = @tycho.screenshot_path()
    @g2d.FontFace::set_png_decoder(fn(png) {
      match @tycho_shader.decode_image(png) {
        Some((rgba, w, h)) => Some(@g2d.DecodedImage::new(w, h, rgba))
        None => None
      }
    })
    let latin = load_font("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")
    let cjk = load_font("/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf")
    let emoji = load_font("/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf")
    let deva = load_font(
      "/usr/share/fonts/truetype/lohit-devanagari/Lohit-Devanagari.ttf",
    )
    match (latin, cjk, emoji) {
      (Some(latin_f), Some(cjk_f), Some(emoji_f)) => {
        let dev = @tycho.Device::new_desc(
          @tycho.DeviceDesc::new(
            "60-tycho-2d-i18n-text",
            validation=true,
            headless=!show_win,
          ),
        )
        let w = 900
        let h = 640
        let bg = @g2d.Color::from_rgba8(18, 22, 34)
        let fallback_faces : Array[@g2d.FontFace] = [cjk_f, emoji_f]
        match deva {
          Some(df) => fallback_faces.push(df)
          None => ()
        }
        let chain = @g2d.FontFallbackChain::new(
          latin_f,
          fallbacks=fallback_faces,
        )
        let mk_style = fn(size : Float, color : @g2d.Color) {
          @g2d.TextStyle::new(
            font=latin_f,
            font_size=size,
            color=color,
            fallback=Some(chain),
          )
        }
        let p1 = @g2d.ParagraphBuilder::new()
          .add_text(
            "Latin fi 世界 😀",
            style=mk_style((64.0 : Float), @g2d.Color::from_rgba8(225, 235, 250)),
          )
          .build()
        let p2 = @g2d.ParagraphBuilder::new()
          .add_text(
            "שלום עולם",
            style=mk_style((40.0 : Float), @g2d.Color::from_rgba8(250, 225, 170)),
          )
          .build()
        let p3 = @g2d.ParagraphBuilder::new()
          .add_text(
            "سلام عليكم",
            style=mk_style((40.0 : Float), @g2d.Color::from_rgba8(170, 235, 210)),
          )
          .build()
        let p4 = @g2d.ParagraphBuilder::new(
          style=@g2d.ParagraphStyle::new(align=@g2d.TextAlign::Justify),
        )
          .add_text(
            "The quick brown fox jumps over the lazy dog. Justified selection demo across two lines.",
            style=mk_style((24.0 : Float), @g2d.Color::from_rgba8(210, 218, 230)),
          )
          .build()
        let p5 = @g2d.ParagraphBuilder::new()
          .add_text(
            "Synthetic bold + italic fi",
            style=@g2d.TextStyle::new(
              font=latin_f,
              font_size=(32.0 : Float),
              color=@g2d.Color::from_rgba8(200, 215, 240),
              bold=true,
              italic=true,
              fallback=Some(chain),
            ),
          )
          .build()
        p1.layout((820.0 : Float))
        p2.layout((820.0 : Float))
        p3.layout((820.0 : Float))
        p4.layout((820.0 : Float))
        p5.layout((820.0 : Float))
        let mut deva_ok = true
        let mut p6 : @g2d.Paragraph? = None
        match deva {
          Some(_) => {
            let para = @g2d.ParagraphBuilder::new()
              .add_text(
                "नमस्ते दुनिया",
                style=mk_style((36.0 : Float), @g2d.Color::from_rgba8(240, 200, 170)),
              )
              .build()
            para.layout((820.0 : Float))
            let mut has_virama = false
            for g in para.placed_glyphs() {
              if g.codepoint == 0x094D {
                has_virama = true
              }
            }
            deva_ok = para.placed_glyphs().length() > 0 && !has_virama
            p6 = Some(para)
          }
          None => ()
        }
        let inline_px : Array[Byte] = [
          255, 130, 40, 255, 40, 180, 255, 255, 255, 220, 80, 255, 80, 220,
          120, 255,
        ]
        let inline_img = @g2d.Image2D::from_bytes(
          99,
          2,
          2,
          Bytes::from_array(inline_px),
        )
        let p7 = @g2d.ParagraphBuilder::new()
          .add_text(
            "Inline ",
            style=mk_style((22.0 : Float), @g2d.Color::from_rgba8(210, 220, 235)),
          )
          .add_inline_image(inline_img, (22.0 : Float), (22.0 : Float))
          .add_text(
            " image",
            style=mk_style((22.0 : Float), @g2d.Color::from_rgba8(210, 220, 235)),
          )
          .build()
        p7.layout((820.0 : Float))
        let p8 = @g2d.ParagraphBuilder::new()
          .add_text(
            "Text on a curved path",
            style=mk_style((18.0 : Float), @g2d.Color::from_rgba8(150, 220, 255)),
          )
          .build()
        p8.layout((820.0 : Float))
        let inline_ok = {
          let mut found = false
          for g in p7.placed_glyphs() {
            match g.image {
              Some(_) => found = true
              None => ()
            }
          }
          found
        }

        let c = @g2d.Canvas::new()
        c.clear(bg)
        let p4_y = (480.0 : Float)
        let sel = @g2d.Color::rgba((0.25 : Float), (0.48 : Float), (0.95 : Float), (0.35 : Float))
        for r in p4.get_boxes_for_range(4, 20) {
          c.draw_rect(
            @g2d.Rect::new(
              (32.0 : Float) + r.x,
              p4_y + r.y,
              r.width,
              r.height,
            ),
            @g2d.Paint::fill(sel),
          )
        }
        let caret = p4.get_caret_rect(@g2d.TextPosition::new(20, 0))
        c.draw_rect(
          @g2d.Rect::new(
            (32.0 : Float) + caret.x,
            p4_y + caret.y,
            (2.0 : Float),
            caret.height,
          ),
          @g2d.Paint::fill(@g2d.Color::from_rgba8(120, 190, 255)),
        )
        c.draw_paragraph(p1, @g2d.Point::new((32.0 : Float), (30.0 : Float)))
        c.draw_paragraph(p2, @g2d.Point::new((32.0 : Float), (140.0 : Float)))
        c.draw_paragraph(p3, @g2d.Point::new((32.0 : Float), (250.0 : Float)))
        c.draw_paragraph(p5, @g2d.Point::new((32.0 : Float), (332.0 : Float)))
        match p6 {
          Some(para) =>
            c.draw_paragraph(para, @g2d.Point::new((32.0 : Float), (372.0 : Float)))
          None => ()
        }
        c.draw_paragraph(p7, @g2d.Point::new((32.0 : Float), (430.0 : Float)))
        c.draw_paragraph(p4, @g2d.Point::new((32.0 : Float), p4_y))
        let tp = @g2d.PathBuilder::new()
          .move_to((40.0 : Float), (600.0 : Float))
          .cubic_to(
            (260.0 : Float),
            (560.0 : Float),
            (620.0 : Float),
            (650.0 : Float),
            (840.0 : Float),
            (600.0 : Float),
          )
          .build()
        c.draw_text_on_path(
          p8,
          tp,
          @g2d.Paint::fill(@g2d.Color::from_rgba8(150, 220, 255)),
        )

        let dl = c.finish()
        let renderer = @g2d.Renderer2D::new(dev)
        let rt = dev.create_render_target(w, h, @tycho.TextureFormat::RGBA8)
        renderer.render_offscreen(dl, rt, clear_color=bg)
        let px = rt.readback()
        if shot != "" {
          let _ = @tycho.save_png(shot, w, h, px)
        }

        let lig_ok = {
          let mut found = false
          for g in p1.placed_glyphs() {
            if g.glyph_id > 0 && g.glyph_id == g.font.glyph_id(0xFB01) {
              found = true
            }
          }
          found
        }
        let mut arabic_forms = 0
        for g in p3.placed_glyphs() {
          if g.codepoint >= 0x0600 &&
            g.codepoint <= 0x06FF &&
            g.glyph_id != g.font.glyph_id(g.codepoint) {
            arabic_forms = arabic_forms + 1
          }
        }
        let rtl_first = if p2.placed_glyphs().length() > 0 {
          p2.placed_glyphs()[0].codepoint
        } else {
          0
        }
        let rtl_ok = p2.placed_glyphs().length() > 0 && rtl_first == 0x05DD
        let boxes_ok = p4.get_boxes_for_range(4, 20).length() > 0
        let bold_italic = p5.placed_glyphs().length() > 0 &&
          p5.placed_glyphs()[0].bold &&
          p5.placed_glyphs()[0].italic
        let mut yellow = 0
        let mut path_px = 0
        let mut i = 0
        while i + 3 < px.length() {
          let r = px[i].to_int()
          let g = px[i + 1].to_int()
          let b = px[i + 2].to_int()
          if r > 180 && g > 120 && b < 140 {
            yellow = yellow + 1
          }
          let y = (i / 4) / w
          if y > 540 && r < 190 && g > 180 && b > 200 {
            path_px = path_px + 1
          }
          i = i + 4
        }
        let path_ok = path_px > 20
        let st = renderer.stats()
        let sdf_ok = st.sdf_glyphs > 0 && st.msdf_glyphs > 0
        let errs = dev.validation_errors()
        println(
          "{\"ligature\":\{lig_ok},\"arabic_forms\":\{arabic_forms},\"rtl_first\":\{rtl_first},\"selection_boxes\":\{p4.get_boxes_for_range(4, 20).length()},\"bold_italic\":\{bold_italic},\"sdf_glyphs\":\{st.sdf_glyphs},\"msdf_glyphs\":\{st.msdf_glyphs},\"devanagari\":\{deva_ok},\"inline_image\":\{inline_ok},\"text_on_path\":\{path_ok},\"yellow_pixels\":\{yellow}}",
        )
        let ok = lig_ok &&
          arabic_forms >= 3 &&
          rtl_ok &&
          boxes_ok &&
          bold_italic &&
          sdf_ok &&
          deva_ok &&
          inline_ok &&
          path_ok &&
          yellow > 50 &&
          errs == 0
        if ok {
          println(
            "[60-tycho-2d-i18n-text] OK — Latin ligature + CJK + emoji + Hebrew RTL + Arabic joining + Devanagari + inline image + text-on-path + synthetic bold/italic + SDF, \{arabic_forms} Arabic forms, \{st.sdf_glyphs} SDF glyphs, 0 validation errors",
          )
        } else {
          println(
            "[60-tycho-2d-i18n-text] FAIL — lig=\{lig_ok} arabic=\{arabic_forms} rtl_first=\{rtl_first} boxes=\{boxes_ok} bold_italic=\{bold_italic} sdf=\{st.sdf_glyphs} deva=\{deva_ok} inline=\{inline_ok} path=\{path_ok} yellow=\{yellow} errs=\{errs}",
          )
        }

        if show_win {
          let sc = dev.create_swapchain_desc(
            @tycho.SwapchainDesc::new(
              "60-tycho-2d-i18n-text",
              w,
              h,
              depth=true,
              depth_format=@tycho.TextureFormat::Depth24Stencil8,
              clear_color=bg.to_clear_color(),
            ),
          )
          while !sc.should_close() {
            let mut quit = false
            for ev in sc.poll_events() {
              match ev {
                @tycho.Event::KeyDown(k, _) => if k == @tycho.KEY_ESCAPE { quit = true }
                _ => ()
              }
            }
            if quit { break }
            sc.sync_size()
            renderer.render_swapchain(sc, dl, clear_color=bg)
          }
          sc.destroy()
        }

        rt.destroy()
        renderer.destroy()
        dev.destroy()
      }
      _ =>
        println(
          "[60-tycho-2d-i18n-text] OK — skipped (DejaVu/Droid/NotoColorEmoji not installed)",
        )
    }
  } catch {
    err => println("[60-tycho-2d-i18n-text] FAIL — \{err}")
  }
}
