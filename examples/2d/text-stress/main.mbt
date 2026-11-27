// Text stress test: ~8,000 glyphs across 40 fractional sizes per script,
// Latin (DejaVu Sans) and CJK (Droid Sans Fallback). Verifies that the enlarged
// glyph atlas plus LRU compaction never falls back to a full cache reset.
// Headless assertions by default; --window for live preview, --screenshot <path> for PNG.

///|
fn load_font(path : String) -> @g2d.FontFace {
  let bytes = @tycho.read_file_bytes(path)
  if bytes.length() == 0 {
    return @g2d.FontFace::builtin()
  }
  match @g2d.FontFace::from_ttf_bytes(bytes) {
    Some(f) => f
    None => @g2d.FontFace::builtin()
  }
}

///|
fn main {
  try {
    let opts = @exwin.Options::parse("2d/text-stress")
    let show_win = opts.window
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "2d/text-stress",
        validation=true,
        headless=!show_win,
      ),
    )
    let font_en = load_font("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")
    let font_zh = load_font("/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf")
    let en = "The quick brown fox jumps over the lazy dog 0123456789 The quick brown fox jumps over the lazy dog 0123456789"
    let zh = "永和九年岁在癸丑暮春之初会于会稽山阴之兰亭修禊事也群贤毕至少长咸集此地有崇山峻岭茂林修竹又有清流激湍映带左右引以为流觞曲水列坐其次虽无丝竹管弦之盛一觞一咏亦足以畅叙幽情是日也天朗气清惠风和畅仰观宇宙之大俯察品类之盛"
    let w = 1920
    let h = 1080
    let c = @g2d.Canvas::new()
    c.clear(@g2d.Color::from_rgba8(16, 20, 30))
    for i = 0; i < 40; i = i + 1 {
      let size = (8.0 : Float) + Float::from_int(i) * (0.5 : Float)
      let para = @g2d.ParagraphBuilder::new()
        .add_text(
          en,
          style=@g2d.TextStyle::new(
            font=font_en,
            font_size=size,
            color=@g2d.Color::from_rgba8(220, 230, 245),
          ),
        )
        .build()
      para.layout((440.0 : Float))
      c.draw_paragraph(
        para,
        @g2d.Point::new(
          Float::from_int(40 + (i % 4) * 460),
          Float::from_int(30 + (i / 4) * 50),
        ),
      )
    }
    for i = 0; i < 40; i = i + 1 {
      let size = (8.0 : Float) + Float::from_int(i) * (0.5 : Float)
      let para = @g2d.ParagraphBuilder::new()
        .add_text(
          zh,
          style=@g2d.TextStyle::new(
            font=font_zh,
            font_size=size,
            color=@g2d.Color::from_rgba8(240, 225, 200),
          ),
        )
        .build()
      para.layout((440.0 : Float))
      c.draw_paragraph(
        para,
        @g2d.Point::new(
          Float::from_int(40 + (i % 4) * 460),
          Float::from_int(560 + (i / 4) * 50),
        ),
      )
    }
    let dl = c.finish()
    let renderer = @g2d.Renderer2D::new(dev)
    let rt = dev.create_render_target(w, h, @tycho.TextureFormat::RGBA8)
    renderer.render_offscreen( rt,dl, clear_color=@g2d.Color::from_rgba8(16, 20, 30))
    if opts.screenshot != "" {
      let px = rt.readback()
      opts.capture(w, h, px)
    }
    let st = renderer.stats()
    println(
      "{\"glyphs\":\{st.glyph_entries},\"resets\":\{st.atlas_resets},\"overflows\":\{st.atlas_overflows},\"prims\":\{st.prims}}",
    )
    let errs = dev.validation_errors()
    let ok = st.glyph_entries > 2500 &&
      st.atlas_resets == 0 &&
      st.atlas_overflows == 0 &&
      st.prims >= 6000 &&
      errs == 0
    if ok {
      println(
        "[2d/text-stress] OK — \{st.glyph_entries} glyph entries, \{st.prims} prims, 0 atlas resets/overflows, 0 validation errors",
      )
    } else {
      println(
        "[2d/text-stress] FAIL — glyphs=\{st.glyph_entries} resets=\{st.atlas_resets} overflows=\{st.atlas_overflows} prims=\{st.prims} errs=\{errs}",
      )
    }
    if show_win {
      let cc = @g2d.Color::from_rgba8(16, 20, 30)
      let sc = @exwin_rhi.open(
        dev,
        opts,
        depth=true,
        depth_format=@tycho.TextureFormat::Depth24Stencil8,
        clear_color=cc.to_clear_color(),
      )
      while @exwin_rhi.next_frame(sc) {
        renderer.render_swapchain(
          sc,
          @exwin_2d.fit(dl, w, h, sc),
          clear_color=@g2d.Color::from_rgba8(16, 20, 30),
        )
      }
      sc.destroy()
    }

    rt.destroy()
    renderer.destroy()
    dev.destroy()
  } catch {
    err => println("[2d/text-stress] FAIL — \{err}")
  }
}
