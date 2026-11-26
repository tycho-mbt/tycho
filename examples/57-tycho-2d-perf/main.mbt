// Tycho 2D performance harness: 1080p scene with 5,000 SDF primitives,
// ~1,000 glyphs, 200 anti-aliased cubic paths and 20 frosted-glass panels.
// Prints per-frame statistics as JSON and asserts that batching is active.
// --window for live preview, --screenshot <path> for PNG.

///|
fn main {
  try {
    let show_win = @tycho.want_window()
    let shot = @tycho.screenshot_path()
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "57-tycho-2d-perf",
        validation=true,
        headless=!show_win,
      ),
    )
    let font_bytes = @tycho.read_file_bytes("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")
    let font = if font_bytes.length() > 0 {
      match @g2d.FontFace::from_ttf_bytes(font_bytes) {
        Some(f) => f
        None => @g2d.FontFace::builtin()
      }
    } else {
      @g2d.FontFace::builtin()
    }
    let w = 1920
    let h = 1080
    let c = @g2d.Canvas::new()
    c.clear(@g2d.Color::from_rgba8(18, 22, 34))

    // 5,000 Tier-1 SDF primitives (100 x 50 grid).
    for row = 0; row < 50; row = row + 1 {
      for col = 0; col < 100; col = col + 1 {
        let x = Float::from_int(40 + col * 18)
        let y = Float::from_int(40 + row * 18)
        let r = (col * 7) % 200 + 40
        let g = (row * 5) % 200 + 40
        let b = (col + row) % 120 + 80
        c.draw_rect(
          @g2d.Rect::new(x, y, (12.0 : Float), (12.0 : Float)),
          @g2d.Paint::fill(@g2d.Color::from_rgba8(r, g, b)),
        )
      }
    }

    // 200 anti-aliased cubic paths (20 x 10 grid), batched into shared MSAA passes.
    for row = 0; row < 10; row = row + 1 {
      for col = 0; col < 20; col = col + 1 {
        let x = Float::from_int(40 + col * 90)
        let y = Float::from_int(700 + row * 22)
        let pb = @g2d.PathBuilder::new()
        let _ = pb.move_to(x, y + (10.0 : Float))
        let _ = pb.cubic_to(
          x + (20.0 : Float),
          y,
          x + (40.0 : Float),
          y + (20.0 : Float),
          x + (60.0 : Float),
          y + (10.0 : Float),
        )
        let p = pb.build()
        c.draw_path(
          p,
          @g2d.Paint::stroke(
            @g2d.Color::from_rgba8(90, 200, 255),
            (3.0 : Float),
            cap=@g2d.StrokeCap::Round,
            join=@g2d.StrokeJoin::Round,
          ),
        )
      }
    }

    // ~1,040 glyphs across 10 paragraphs.
    let text = "TYCHO 2D PERF 0123456789 TYCHO 2D PERF 0123456789 TYCHO 2D PERF 0123456789 TYCHO 2D PERF 0123456789"
    for i = 0; i < 10; i = i + 1 {
      let para = @g2d.ParagraphBuilder::new()
        .add_text(
          text,
          style=@g2d.TextStyle::new(
            font~,
            font_size=(12.0 : Float),
            color=@g2d.Color::from_rgba8(220, 230, 250),
          ),
        )
        .build()
      c.draw_paragraph(
        para,
        @g2d.Point::new(
          Float::from_int(40 + (i % 5) * 360),
          Float::from_int(950 + (i / 5) * 22),
        ),
      )
    }

    // 20 frosted-glass backdrop panels.
    for row = 0; row < 4; row = row + 1 {
      for col = 0; col < 5; col = col + 1 {
        let px = Float::from_int(60 + col * 360)
        let py = Float::from_int(120 + row * 130)
        let r = @g2d.Rect::new(px, py, (220.0 : Float), (70.0 : Float))
        let rr = @g2d.RRect::uniform(r, (14.0 : Float))
        let _ = c.save()
        c.clip_rrect(rr)
        let _ = c.save_backdrop_layer(
          r,
          @g2d.ImageFilter::Blur((5.0 : Float), (5.0 : Float), @g2d.TileMode::Clamp),
        )
        c.draw_rrect(
          rr,
          @g2d.Paint::fill(
            @g2d.Color::rgba((0.10 : Float), (0.14 : Float), (0.24 : Float), (0.45 : Float)),
          ),
        )
        c.restore()
        c.restore()
      }
    }

    let dl = c.finish()
    let renderer = @g2d.Renderer2D::new(dev)
    let rt = dev.create_render_target(w, h, @tycho.TextureFormat::RGBA8)
    renderer.render_offscreen(dl, rt, clear_color=@g2d.Color::from_rgba8(18, 22, 34))
    if shot != "" {
      let px = rt.readback()
      let _ = @tycho.save_png(shot, w, h, px)
    }
    let st = renderer.stats()
    println(st.to_json())
    let errs = dev.validation_errors()
    let ok = st.prims >= 5000 &&
      st.draw_calls > 0 &&
      st.draw_calls < st.prims &&
      st.path_passes > 0 &&
      st.path_passes <= 80 &&
      st.upload_bytes > 0 &&
      st.glyph_entries > 0 &&
      errs == 0
    if ok {
      println(
        "[57-tycho-2d-perf] OK — \{st.prims} prims, \{st.draw_calls} draws, \{st.path_passes} path passes, \{st.upload_bytes} upload bytes, 0 validation errors",
      )
    } else {
      println(
        "[57-tycho-2d-perf] FAIL — draws=\{st.draw_calls} passes=\{st.path_passes} prims=\{st.prims} uploads=\{st.upload_bytes} glyphs=\{st.glyph_entries} errs=\{errs}",
      )
    }
    if show_win {
      let cc = @g2d.Color::from_rgba8(18, 22, 34)
      let sc = dev.create_swapchain_desc(
        @tycho.SwapchainDesc::new(
          "57-tycho-2d-perf",
          w,
          h,
          depth=true,
          depth_format=@tycho.TextureFormat::Depth24Stencil8,
          clear_color=cc.to_clear_color(),
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
        renderer.render_swapchain(
          sc,
          dl,
          clear_color=@g2d.Color::from_rgba8(18, 22, 34),
        )
      }
      sc.destroy()
    }

    rt.destroy()
    renderer.destroy()
    dev.destroy()
  } catch {
    err => println("[57-tycho-2d-perf] FAIL — \{err}")
  }
}
