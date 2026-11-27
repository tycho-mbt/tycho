// ui/gallery — Tycho UI Declarative Gallery (Flutter-inspired):
// Demonstrates:
// - Three trees (Widget -> Element -> RenderNode -> Layer) + reactive Signal[T]
// - Dark/Light ThemeData switcher, Filled/Outlined buttons, Switch, Checkbox, Slider, ProgressBar, TextField
// - Virtualized 100,000-row ListView::builder (constant active node count!)
// - Headless WidgetTester interaction & pixel verification + --screenshot + --window live GUI.

///|
fn build_gallery_ui(
  is_dark : @ui.Signal[Bool],
  counter : @ui.Signal[Int],
  switch_on : @ui.Signal[Bool],
  checked : @ui.Signal[Bool],
  radio_mode : @ui.Signal[Int],
  slider_val : @ui.Signal[Float],
  show_modal : @ui.Signal[Bool],
  text_ctrl : @ui.TextController,
  scroll_ctrl : @ui.ScrollController,
  font : @g2d.FontFace,
) -> @ui.Widget {
  @ui.builder(tag=1, fn(ctx) {
    let dark = is_dark.get(ctx)
    let th = if dark { @ui.ThemeData::dark(font~) } else { @ui.ThemeData::light(font~) }
    @ui.theme_provider(
      th,
      @ui.builder(tag=2, fn(inner_ctx) {
        let modal_open = show_modal.get(inner_ctx)
        let c = inner_ctx.colors()
        let header = @ui.card(
          pad=@ui.EdgeInsets::symmetric(horizontal=(18.0 : Float), vertical=(12.0 : Float)),
          @ui.row(
            main_axis=@ui.MainAxisAlignment::SpaceBetween,
            [
              @ui.column(gap=(4.0 : Float), main_size=@ui.MainAxisSize::Min, [
                @ui.text("TYCHO UI GALLERY", size=(18.0 : Float), color=Some(c.text_primary)),
                @ui.text("Three-Tree Widgets + Signals + 100K Virtual List", size=(12.0 : Float), color=Some(c.text_secondary)),
              ]),
              @ui.row(gap=(10.0 : Float), main_size=@ui.MainAxisSize::Min, [
                @ui.tooltip(
                  "Toggle Dark / Light Theme",
                  @ui.outlined_button(
                    if dark { "Light Theme" } else { "Dark Theme" },
                    fn() { is_dark.update(fn(v) { !v }) },
                  ),
                ),
                @ui.badge(
                  label="NEW",
                  @ui.filled_button("Frosted Modal", fn() { show_modal.set(true) }),
                ),
              ]),
            ],
          ),
        )

        let left_panel = @ui.sized_box(
          width=Some((390.0 : Float)),
          child=Some(
            @ui.card(
              @ui.column(gap=(14.0 : Float), [
                @ui.text("Reactive Controls", size=(16.0 : Float), color=Some(c.text_primary)),
                @ui.divider(),
                @ui.row(
                  main_axis=@ui.MainAxisAlignment::SpaceBetween,
                  [
                    @ui.builder(tag=3, fn(cctx) {
                      let n = counter.get(cctx)
                      @ui.text("Counter: \{n}", size=(16.0 : Float), color=Some(c.primary))
                    }),
                    @ui.filled_button("Increment +1", fn() {
                      counter.update(fn(n) { n + 1 })
                    }),
                  ],
                ),
                @ui.switch_toggle(switch_on, label="Enable GPU Batching"),
                @ui.checkbox(checked, label="Premultiplied Alpha AA"),
                @ui.row(gap=(12.0 : Float), [
                  @ui.radio(0, radio_mode, label="MSAA 4x"),
                  @ui.radio(1, radio_mode, label="SDF Fast"),
                ]),
                @ui.column(gap=(6.0 : Float), main_size=@ui.MainAxisSize::Min, [
                  @ui.builder(tag=4, fn(sctx) {
                    let v = slider_val.get(sctx)
                    let pct = (v * (100.0 : Float)).to_int()
                    @ui.column(gap=(6.0 : Float), main_size=@ui.MainAxisSize::Min, [
                      @ui.text("Progress / Slider: \{pct}%", size=(13.0 : Float), color=Some(c.text_secondary)),
                      @ui.slider(slider_val, width=(340.0 : Float)),
                      @ui.progress_bar(v, width=(340.0 : Float), color=Some(c.secondary)),
                    ])
                  }),
                ]),
                @ui.column(gap=(6.0 : Float), main_size=@ui.MainAxisSize::Min, [
                  @ui.text("Editable TextField:", size=(13.0 : Float), color=Some(c.text_secondary)),
                  @ui.text_field(text_ctrl, width=(340.0 : Float), placeholder="Enter text..."),
                ]),
              ]),
            ),
          ),
        )

        let right_panel = @ui.expanded(
          @ui.card(
            @ui.column(gap=(10.0 : Float), [
              @ui.row(
                main_axis=@ui.MainAxisAlignment::SpaceBetween,
                [
                  @ui.text("100,000-Row Virtual List", size=(16.0 : Float), color=Some(c.text_primary)),
                  @ui.builder(tag=5, fn(lctx) {
                    let sy = scroll_ctrl.offset.get(lctx).to_int()
                    @ui.text("y=\{sy}px", size=(12.0 : Float), color=Some(c.secondary))
                  }),
                ],
              ),
              @ui.divider(),
              @ui.expanded(
                @ui.scrollbar(
                  scroll_ctrl,
                  @ui.list_view_builder(100000, (44.0 : Float), scroll_ctrl, fn(_ictx, idx) {
                  let bg = if idx % 2 == 0 { c.surface_variant } else { c.surface }
                  let badge_col = if idx % 3 == 0 {
                    c.primary
                  } else if idx % 3 == 1 {
                    c.secondary
                  } else {
                    @g2d.Color::from_rgba8(245, 148, 56)
                  }
                  @ui.padding(
                    @ui.EdgeInsets::symmetric(vertical=(3.0 : Float)),
                    @ui.container(
                      pad=Some(@ui.EdgeInsets::symmetric(horizontal=(12.0 : Float), vertical=(6.0 : Float))),
                      color=Some(bg),
                      radius=(8.0 : Float),
                      child=Some(
                        @ui.row(gap=(10.0 : Float), [
                          @ui.container(
                            width=Some((24.0 : Float)),
                            height=Some((24.0 : Float)),
                            color=Some(badge_col),
                            radius=(6.0 : Float),
                          ),
                          @ui.text("Virtual Item #\{idx}", size=(14.0 : Float), color=Some(c.text_primary)),
                        ]),
                      ),
                    ),
                  )
                }),
                ),
              ),
            ]),
          ),
        )

        let main_shell = @ui.container(
          color=Some(c.background),
          pad=Some(@ui.EdgeInsets::all((18.0 : Float))),
          child=Some(
            @ui.column(gap=(16.0 : Float), [
              header,
              @ui.expanded(@ui.row(gap=(16.0 : Float), cross_axis=@ui.CrossAxisAlignment::Stretch, [left_panel, right_panel])),
            ]),
          ),
        )

        if modal_open {
          @ui.stack([
            main_shell,
            @ui.frosted_dialog(
              "Tycho Frosted Modal",
              @ui.text("Rendered via BackdropFilter Gaussian blur + Signal state!", size=(14.0 : Float)),
              fn() { show_modal.set(false) },
            ),
          ])
        } else {
          main_shell
        }
      }),
    )
  })
}

///|
fn px_at(px : FixedArray[Byte], w : Int, x : Int, y : Int) -> (Int, Int, Int, Int) {
  let i = (y * w + x) * 4
  (px[i].to_int(), px[i + 1].to_int(), px[i + 2].to_int(), px[i + 3].to_int())
}

///|
fn main {
  try {
    let opts = @exwin.Options::parse("ui/gallery")
    let show_win = opts.window
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("Tycho UI Gallery", validation=true, headless=!show_win),
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

    let is_dark = @ui.Signal::new(true)
    let counter = @ui.Signal::new(0)
    let switch_on = @ui.Signal::new(true)
    let checked = @ui.Signal::new(true)
    let radio_mode = @ui.Signal::new(0)
    let slider_val = @ui.Signal::new((0.68 : Float))
    let show_modal = @ui.Signal::new(false)
    let text_ctrl = @ui.TextController::new(initial="Hello Tycho UI")
    let scroll_ctrl = @ui.ScrollController::new()

    let root = build_gallery_ui(
      is_dark, counter, switch_on, checked, radio_mode, slider_val, show_modal, text_ctrl, scroll_ctrl, font,
    )

    let w = 800
    let h = 600
    let tester = @ui.WidgetTester::new(
      root,
      width=Float::from_int(w),
      height=Float::from_int(h),
      theme=@ui.ThemeData::dark(font~),
    )

    // Verify 100,000-row ListView virtualization keeps active Element count tiny
    let elem_before = tester.element_count()
    let virt_initial_ok = elem_before < 450

    // Synthetic interactions: tap Increment button inside left card (around x=320, y=188),
    // send keystroke into TextController, and jump scroll 22,000px deep into the 100k list
    tester.tap((320.0 : Float), (188.0 : Float))
    let tap_ok = counter.peek() == 1
    text_ctrl.insert_char('!')
    let text_ok = text_ctrl.text.peek() == "Hello Tycho UI!"

    // Verify slider local-coordinate alignment: slider width=340 starts at x=34 -> center is x=204.
    // Tapping/dragging at x=204 should set slider_val near 0.50 (within 0.05), then restore 0.68.
    tester.tap((204.0 : Float), (364.0 : Float))
    let slider_center_ok = (slider_val.peek() - (0.5 : Float)).abs() < (0.05 : Float)
    slider_val.set((0.68 : Float))
    let _ = tester.pump_frame()

    scroll_ctrl.jump_to((22000.0 : Float))
    let _ = tester.pump_frame()
    let elem_after = tester.element_count()
    let virt_scroll_ok = elem_after < 450 && scroll_ctrl.offset.peek() > (20000.0 : Float)

    // Reset scroll near top for clean visual screenshot
    scroll_ctrl.jump_to((0.0 : Float))
    let renderer = @g2d.Renderer2D::new(dev)
    let rt = dev.create_render_target(w, h, @tycho.TextureFormat::RGBA8)
    tester.render_to_texture(
      renderer,
      rt,
      clear_color=@ui.ColorScheme::dark().background,
    )

    let px = rt.readback()
    opts.capture(w, h, px)

    // Visual pixel checks on 800x600 rendered UI:
    // Header card background at (40, 40) is surface ~(24, 30, 48), distinct from pure black
    let (hr, hg, hb, ha) = px_at(px, w, 40, 40)
    let header_ok = ha > 240 && hb > hr && (hr + hg + hb) > 40
    // Filled button "Frosted Modal" near top-right (710, 48) is bright primary blue
    let (br, _bg, bb, _) = px_at(px, w, 710, 48)
    let button_ok = bb > 180 && bb > br
    // Progress bar filled left segment near (80, 428) shows secondary mint-green
    let (_pr, pg, pb, _) = px_at(px, w, 80, 428)
    let ui_rendered_ok = pg > 20 || pb > 20

    rt.destroy()

    if show_win {
      let runner = @ui.AppRunner::new(
        dev,
        root,
        theme=@ui.ThemeData::dark(font~),
      )
      runner.run_window(opts.name, w, h)
      runner.destroy()
    }

    renderer.destroy()
    dev.wait_idle()
    let errs = dev.validation_errors()
    let used = dev.allocator_used_bytes()
    dev.destroy()

    if virt_initial_ok && virt_scroll_ok && tap_ok && text_ok && slider_center_ok && header_ok && button_ok && ui_rendered_ok && errs == 0 && used == (0 : UInt64) {
      println(
        "[ui/gallery] OK — Signal tap=\{counter.peek()}, slider_center=\{slider_center_ok}, 100k ListView elements=\{elem_before}->\{elem_after}, text='\{text_ctrl.text.peek()}', 0 validation errors",
      )
    } else {
      println(
        "[ui/gallery] FAIL — virt=\{virt_initial_ok}/\{virt_scroll_ok}(e=\{elem_before}->\{elem_after}) tap=\{tap_ok}(\{counter.peek()}) text=\{text_ok} slider=\{slider_center_ok}(\{slider_val.peek()}) hdr=\{header_ok}(\{hr},\{hg},\{hb}) btn=\{button_ok}(\{br},\{bb}) errs=\{errs} used=\{used}",
      )
    }
  } catch {
    err => println("[ui/gallery] FAIL — \{err}")
  }
}
