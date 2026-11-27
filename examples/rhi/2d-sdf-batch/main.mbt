// rhi/2d-sdf-batch — 2D SDF Rounded Rect + Texture Atlas Batcher & High-Frequency UI Benchmark:
// 1. Visual dashboard (800x600): analytical per-corner SDF rounded rects, borders, soft drop shadows,
//    procedural 256x256 RGBA8 icon atlas (4x2 tiles), and hardware scissor clipping.
// 2. High-frequency UI stress test: 30 frames x 2,000 animated quads (60,000 instances total) using
//    double-buffered CpuToGpu SSBOs, Dynamic Rendering, and TimestampPool profiling.
// 3. Optional interactive `--window` mode with hover highlight; `--screenshot <path>` for PNG capture.

const QUAD_FLOATS : Int = 24
const QUAD_BYTES : Int = 96

///|
priv struct DrawBatch {
  first : Int
  count : Int
  cx : Int
  cy : Int
  cw : Int
  ch : Int
}

///|
priv struct UiBatcher {
  data : FixedArray[Float]
  max_quads : Int
  mut count : Int
  batches : Array[DrawBatch]
  mut clip_x : Int
  mut clip_y : Int
  mut clip_w : Int
  mut clip_h : Int
  mut batch_start : Int
}

///|
fn UiBatcher::new(max_quads : Int) -> UiBatcher {
  {
    data: FixedArray::make(max_quads * QUAD_FLOATS, (0.0 : Float)),
    max_quads,
    count: 0,
    batches: [],
    clip_x: 0,
    clip_y: 0,
    clip_w: 800,
    clip_h: 600,
    batch_start: 0,
  }
}

///|
fn UiBatcher::reset(self : UiBatcher, vp_w : Int, vp_h : Int) -> Unit {
  self.count = 0
  self.batches.clear()
  self.clip_x = 0
  self.clip_y = 0
  self.clip_w = vp_w
  self.clip_h = vp_h
  self.batch_start = 0
}

///|
fn UiBatcher::flush_current_batch(self : UiBatcher) -> Unit {
  let n = self.count - self.batch_start
  if n > 0 {
    self.batches.push({
      first: self.batch_start,
      count: n,
      cx: self.clip_x,
      cy: self.clip_y,
      cw: self.clip_w,
      ch: self.clip_h,
    })
    self.batch_start = self.count
  }
}

///|
fn UiBatcher::set_clip(self : UiBatcher, x : Int, y : Int, w : Int, h : Int) -> Unit {
  if x == self.clip_x && y == self.clip_y && w == self.clip_w && h == self.clip_h {
    return
  }
  self.flush_current_batch()
  self.clip_x = x
  self.clip_y = y
  self.clip_w = w
  self.clip_h = h
}

///|
fn UiBatcher::push_quad(
  self : UiBatcher,
  x : Float,
  y : Float,
  w : Float,
  h : Float,
  r_tl : Float,
  r_tr : Float,
  r_br : Float,
  r_bl : Float,
  fr : Float,
  fg : Float,
  fb : Float,
  fa : Float,
  br : Float,
  bg : Float,
  bb : Float,
  ba : Float,
  u0 : Float,
  v0 : Float,
  u1 : Float,
  v1 : Float,
  border_w : Float,
  softness : Float,
  kind : Float,
) -> Unit {
  if self.count >= self.max_quads {
    return
  }
  let base = self.count * QUAD_FLOATS
  let d = self.data
  d[base + 0] = x
  d[base + 1] = y
  d[base + 2] = w
  d[base + 3] = h
  d[base + 4] = r_tl
  d[base + 5] = r_tr
  d[base + 6] = r_br
  d[base + 7] = r_bl
  d[base + 8] = fr
  d[base + 9] = fg
  d[base + 10] = fb
  d[base + 11] = fa
  d[base + 12] = br
  d[base + 13] = bg
  d[base + 14] = bb
  d[base + 15] = ba
  d[base + 16] = u0
  d[base + 17] = v0
  d[base + 18] = u1
  d[base + 19] = v1
  d[base + 20] = border_w
  d[base + 21] = softness
  d[base + 22] = kind
  d[base + 23] = (0.0 : Float)
  self.count = self.count + 1
}

///|
fn UiBatcher::push_shadow(
  self : UiBatcher,
  x : Float,
  y : Float,
  w : Float,
  h : Float,
  r_tl : Float,
  r_tr : Float,
  r_br : Float,
  r_bl : Float,
  softness : Float,
  alpha : Float,
) -> Unit {
  self.push_quad(
    x, y, w, h, r_tl, r_tr, r_br, r_bl,
    (0.0 : Float), (0.0 : Float), (0.02 : Float), alpha,
    (0.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float),
    (0.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float),
    (0.0 : Float), softness, (1.0 : Float),
  )
}

///|
fn UiBatcher::push_rect(
  self : UiBatcher,
  x : Float,
  y : Float,
  w : Float,
  h : Float,
  r_tl : Float,
  r_tr : Float,
  r_br : Float,
  r_bl : Float,
  fr : Float,
  fg : Float,
  fb : Float,
  fa : Float,
  border_w? : Float = (0.0 : Float),
  br? : Float = (0.0 : Float),
  bg? : Float = (0.0 : Float),
  bb? : Float = (0.0 : Float),
  ba? : Float = (1.0 : Float),
) -> Unit {
  self.push_quad(
    x, y, w, h, r_tl, r_tr, r_br, r_bl,
    fr, fg, fb, fa,
    br, bg, bb, ba,
    (0.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float),
    border_w, (0.0 : Float), (0.0 : Float),
  )
}

///|
fn atlas_uv(tile : Int) -> (Float, Float, Float, Float) {
  let col = tile % 4
  let row = tile / 4
  let pad = 2.0 / 256.0
  let u0 = Float::from_double(col.to_double() * 0.25 + pad)
  let v0 = Float::from_double(row.to_double() * 0.5 + pad)
  let u1 = Float::from_double((col + 1).to_double() * 0.25 - pad)
  let v1 = Float::from_double((row + 1).to_double() * 0.5 - pad)
  (u0, v0, u1, v1)
}

///|
fn UiBatcher::push_icon(
  self : UiBatcher,
  x : Float,
  y : Float,
  w : Float,
  h : Float,
  tile : Int,
  tr : Float,
  tg : Float,
  tb : Float,
  ta : Float,
  radius? : Float = (0.0 : Float),
) -> Unit {
  let (u0, v0, u1, v1) = atlas_uv(tile)
  self.push_quad(
    x, y, w, h, radius, radius, radius, radius,
    tr, tg, tb, ta,
    (0.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float),
    u0, v0, u1, v1,
    (0.0 : Float), (0.0 : Float), (2.0 : Float),
  )
}

///|
fn UiBatcher::record(
  self : UiBatcher,
  cmd : @tycho.CommandBuffer,
  pipe : @tycho.Pipeline,
  ssbo : @tycho.Buffer,
  atlas : @tycho.Texture,
  sampler : @tycho.Sampler,
  vp_w : Int,
  vp_h : Int,
  ssbo_offset? : Int = 0,
  ssbo_size? : Int = -1,
) -> Unit {
  self.flush_current_batch()
  if self.batches.length() == 0 {
    return
  }
  cmd.bind_pipeline(pipe)
  cmd.bind_storage(pipe, 0, ssbo, offset=ssbo_offset, size=ssbo_size)
  cmd.bind_texture(pipe, 0, atlas, sampler)
  let fw = Float::from_int(vp_w)
  let fh = Float::from_int(vp_h)
  cmd.push_constants_floats(pipe, [fw, fh, (1.0 : Float) / fw, (1.0 : Float) / fh])
  for b in self.batches {
    cmd.set_scissor(b.cx, b.cy, b.cw, b.ch)
    cmd.draw_instanced(6, b.count, 0, b.first)
  }
}

///|
fn clamp01(v : Double) -> Double {
  v.clamp(min=0.0, max=1.0)
}

///|
fn smooth_cov(d : Double) -> Double {
  clamp01(0.5 - d)
}

///|
// Procedural 256x256 RGBA8 atlas: 4x2 grid of 64x64 crisp vector-SDF UI icons + swatches.
fn build_ui_atlas() -> Bytes {
  let w = 256
  let h = 128
  let bytes = Array::make(w * h * 4, (0 : Byte))
  for py = 0; py < h; py = py + 1 {
    for px = 0; px < w; px = px + 1 {
      let col = px / 64
      let row = py / 64
      let tile = row * 4 + col
      let lx = (px % 64).to_double() - 31.5
      let ly = (py % 64).to_double() - 31.5
      let r_len = (lx * lx + ly * ly).sqrt()
      let mut cr = 255.0
      let mut cg = 255.0
      let mut cb = 255.0
      let mut ca = 0.0

      if tile == 0 {
        // Tile 0: solid white swatch
        ca = 1.0
      } else if tile == 1 {
        // Tile 1: crisp rounded badge + inner diamond star
        let outer = r_len - 24.0
        let diamond = lx.abs() + ly.abs() - 13.0
        let cross = if lx.abs() < 11.0 && ly.abs() < 11.0 {
          if lx.abs() > ly.abs() { lx.abs() - 11.0 } else { ly.abs() - 11.0 }
        } else {
          1.0
        }
        let icon_d = if diamond < cross { diamond } else { cross }
        let ring = smooth_cov(outer.abs() - 2.2)
        let star = smooth_cov(icon_d)
        ca = if ring > star { ring } else { star }
      } else if tile == 2 {
        // Tile 2: ring gauge + center dot
        let ring_d = (r_len - 19.0).abs() - 3.5
        let dot_d = r_len - 7.5
        let a1 = smooth_cov(ring_d)
        let a2 = smooth_cov(dot_d)
        ca = if a1 > a2 { a1 } else { a2 }
      } else if tile == 3 {
        // Tile 3: play triangle inside circle
        let half_h = (13.0 - lx) * 0.65
        let tri = lx >= -8.0 && lx <= 13.0 && ly.abs() <= half_h
        if tri {
          ca = 1.0
        } else {
          ca = smooth_cov((r_len - 23.0).abs() - 2.5)
        }
      } else if tile == 4 {
        // Tile 4: equalizer bars
        let bar1 = (lx + 14.0).abs() < 4.5 && (ly - 4.0).abs() < 14.0
        let bar2 = lx.abs() < 4.5 && ly.abs() < 20.0
        let bar3 = (lx - 14.0).abs() < 4.5 && (ly + 3.0).abs() < 12.0
        if bar1 || bar2 || bar3 {
          ca = 1.0
        }
      } else if tile == 5 {
        // Tile 5: rounded grid 2x2 tiles
        let ax = (lx.abs() - 11.0).abs() - 7.0
        let ay = (ly.abs() - 11.0).abs() - 7.0
        let box_d = if ax > ay { ax } else { ay }
        ca = smooth_cov(box_d)
      } else if tile == 6 {
        // Tile 6: radial gradient orb
        let g = clamp01(1.0 - r_len / 26.0)
        cr = 255.0 * (0.6 + 0.4 * g)
        cg = 255.0 * (0.85 * g + 0.15)
        cb = 255.0
        ca = smooth_cov(r_len - 24.0)
      } else {
        // Tile 7: 8x8 UI checkerboard swatch
        let chk = ((px / 8) + (py / 8)) % 2 == 0
        if chk {
          cr = 235.0; cg = 240.0; cb = 255.0; ca = 1.0
        } else {
          cr = 95.0; cg = 115.0; cb = 155.0; ca = 1.0
        }
      }

      let idx = (py * w + px) * 4
      bytes[idx + 0] = cr.to_int().to_byte()
      bytes[idx + 1] = cg.to_int().to_byte()
      bytes[idx + 2] = cb.to_int().to_byte()
      bytes[idx + 3] = (clamp01(ca) * 255.0).to_int().to_byte()
    }
  }
  Bytes::from_array(bytes)
}

///|
fn populate_dashboard(
  b : UiBatcher,
  w : Int,
  h : Int,
  hover_x : Float,
  hover_y : Float,
  tick : Int,
) -> Unit {
  b.reset(w, h)
  // 1. Background canvas + subtle top ambient glow bar
  b.push_rect(
    (0.0 : Float), (0.0 : Float), Float::from_int(w), Float::from_int(h),
    (0.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float),
    (0.07 : Float), (0.08 : Float), (0.12 : Float), (1.0 : Float),
  )

  // Header bar (rounded bottom corners)
  b.push_shadow(
    (24.0 : Float), (26.0 : Float), (752.0 : Float), (68.0 : Float),
    (16.0 : Float), (16.0 : Float), (16.0 : Float), (16.0 : Float),
    (14.0 : Float), (0.55 : Float),
  )
  b.push_rect(
    (24.0 : Float), (22.0 : Float), (752.0 : Float), (68.0 : Float),
    (16.0 : Float), (16.0 : Float), (16.0 : Float), (16.0 : Float),
    (0.13 : Float), (0.15 : Float), (0.22 : Float), (1.0 : Float),
    border_w=(2.0 : Float),
    br=(0.24 : Float), bg=(0.30 : Float), bb=(0.45 : Float), ba=(1.0 : Float),
  )
  // Pill status badges in header
  b.push_icon(
    (44.0 : Float), (36.0 : Float), (40.0 : Float), (40.0 : Float),
    1, (0.35 : Float), (0.78 : Float), (1.0 : Float), (1.0 : Float),
  )
  b.push_rect(
    (560.0 : Float), (38.0 : Float), (192.0 : Float), (36.0 : Float),
    (18.0 : Float), (18.0 : Float), (18.0 : Float), (18.0 : Float),
    (0.16 : Float), (0.48 : Float), (0.95 : Float), (1.0 : Float),
    border_w=(1.5 : Float),
    br=(0.55 : Float), bg=(0.82 : Float), bb=(1.0 : Float), ba=(1.0 : Float),
  )

  // 2. Three elevated asymmetric SDF cards with borders + icons
  let accents : Array[(Float, Float, Float)] = [
    ((0.28 : Float), (0.68 : Float), (1.0 : Float)),
    ((0.30 : Float), (0.88 : Float), (0.62 : Float)),
    ((0.96 : Float), (0.56 : Float), (0.25 : Float)),
  ]
  for i = 0; i < 3; i = i + 1 {
    let cx = Float::from_int(28 + i * 252)
    let cy = (118.0 : Float)
    let cw = (232.0 : Float)
    let ch = (196.0 : Float)
    let hovered = hover_x >= cx && hover_x <= cx + cw && hover_y >= cy && hover_y <= cy + ch
    let (ar, ag, ab) = accents[i]
    let bw = if hovered { (3.5 : Float) } else { (2.5 : Float) }

    // Shadow offset slightly downward
    b.push_shadow(
      cx + (2.0 : Float), cy + (10.0 : Float), cw, ch,
      (28.0 : Float), (8.0 : Float), (28.0 : Float), (8.0 : Float),
      (16.0 : Float), (0.65 : Float),
    )
    // Asymmetric rounded card + colored border
    b.push_rect(
      cx, cy, cw, ch,
      (28.0 : Float), (8.0 : Float), (28.0 : Float), (8.0 : Float),
      (0.14 : Float), (0.17 : Float), (0.25 : Float), (1.0 : Float),
      border_w=bw,
      br=ar, bg=ag, bb=ab, ba=(1.0 : Float),
    )
    // Icon avatar tile inside card
    b.push_rect(
      cx + (20.0 : Float), cy + (20.0 : Float), (56.0 : Float), (56.0 : Float),
      (14.0 : Float), (14.0 : Float), (14.0 : Float), (14.0 : Float),
      ar * (0.22 : Float), ag * (0.22 : Float), ab * (0.22 : Float), (1.0 : Float),
    )
    b.push_icon(
      cx + (24.0 : Float), cy + (24.0 : Float), (48.0 : Float), (48.0 : Float),
      i + 2, ar, ag, ab, (1.0 : Float),
    )
    // Simulated skeleton text bars inside card
    let pulse = Float::from_int((tick + i * 20) % 40)
    let bar_w = (128.0 : Float) + (if pulse > (20.0 : Float) { (40.0 : Float) - pulse } else { pulse }) * (1.2 : Float)
    b.push_rect(
      cx + (20.0 : Float), cy + (102.0 : Float), bar_w, (14.0 : Float),
      (7.0 : Float), (7.0 : Float), (7.0 : Float), (7.0 : Float),
      (0.80 : Float), (0.86 : Float), (0.95 : Float), (0.85 : Float),
    )
    b.push_rect(
      cx + (20.0 : Float), cy + (130.0 : Float), (186.0 : Float), (10.0 : Float),
      (5.0 : Float), (5.0 : Float), (5.0 : Float), (5.0 : Float),
      (0.45 : Float), (0.52 : Float), (0.65 : Float), (0.75 : Float),
    )
    // Progress track + active bar
    b.push_rect(
      cx + (20.0 : Float), cy + (156.0 : Float), (192.0 : Float), (12.0 : Float),
      (6.0 : Float), (6.0 : Float), (6.0 : Float), (6.0 : Float),
      (0.08 : Float), (0.10 : Float), (0.15 : Float), (1.0 : Float),
    )
    b.push_rect(
      cx + (20.0 : Float), cy + (156.0 : Float), Float::from_int(90 + i * 38), (12.0 : Float),
      (6.0 : Float), (6.0 : Float), (6.0 : Float), (6.0 : Float),
      ar, ag, ab, (1.0 : Float),
    )
  }

  // 3. Lower clipped scroll-list container (x=28, y=342, w=744, h=226)
  b.push_shadow(
    (28.0 : Float), (350.0 : Float), (744.0 : Float), (226.0 : Float),
    (20.0 : Float), (20.0 : Float), (20.0 : Float), (20.0 : Float),
    (16.0 : Float), (0.60 : Float),
  )
  b.push_rect(
    (28.0 : Float), (342.0 : Float), (744.0 : Float), (226.0 : Float),
    (20.0 : Float), (20.0 : Float), (20.0 : Float), (20.0 : Float),
    (0.11 : Float), (0.13 : Float), (0.19 : Float), (1.0 : Float),
    border_w=(2.0 : Float),
    br=(0.24 : Float), bg=(0.28 : Float), bb=(0.40 : Float), ba=(1.0 : Float),
  )

  // Hardware scissor clip region inside container:
  b.set_clip(40, 354, 720, 202)
  for row = 0; row < 4; row = row + 1 {
    let ry = Float::from_int(362 + row * 52)
    b.push_rect(
      (48.0 : Float), ry, (704.0 : Float), (42.0 : Float),
      (10.0 : Float), (10.0 : Float), (10.0 : Float), (10.0 : Float),
      (0.16 : Float), (0.19 : Float), (0.27 : Float), (1.0 : Float),
    )
    b.push_icon(
      (60.0 : Float), ry + (5.0 : Float), (32.0 : Float), (32.0 : Float),
      (row % 4) + 4, (0.85 : Float), (0.90 : Float), (1.0 : Float), (1.0 : Float),
      radius=(6.0 : Float),
    )
  }
  // Deliberate overflow red bar extending below clip rect (row=3 -> y=518..598).
  // Scissor clip ends at y = 354 + 202 = 556, so y = 576 MUST remain dark canvas!
  b.push_rect(
    (120.0 : Float), (540.0 : Float), (560.0 : Float), (58.0 : Float),
    (8.0 : Float), (8.0 : Float), (8.0 : Float), (8.0 : Float),
    (0.95 : Float), (0.20 : Float), (0.25 : Float), (1.0 : Float),
  )
  // Negative-origin clip test: rect & clip at x=-8, w=20 -> visible in [0..12), clipped at x=16
  b.set_clip(-8, 576, 20, 16)
  b.push_rect(
    (-8.0 : Float), (576.0 : Float), (20.0 : Float), (16.0 : Float),
    (0.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float),
    (0.20 : Float), (0.85 : Float), (0.45 : Float), (1.0 : Float),
  )
  b.set_clip(0, 0, w, h)
}

///|
fn populate_stress_frame(b : UiBatcher, frame : Int, w : Int, h : Int) -> Unit {
  b.reset(w, h)
  let total = 2000
  let phase = (frame * 7) % 64
  let tri = Float::from_int(if phase > 32 { 64 - phase } else { phase })
  let hw = w / 2
  let hh = h / 2
  for i = 0; i < total; i = i + 1 {
    // Emit 4 scissor-clipped quadrants (500 quads each) to exercise dynamic clip batches
    let q = i / 500
    let local_i = i % 500
    let qx = (q % 2) * hw
    let qy = (q / 2) * hh
    if local_i == 0 {
      b.set_clip(qx, qy, hw, hh)
    }
    let gx = local_i % 20
    let gy = local_i / 20
    let ox = Float::from_int(qx + gx * 12) + tri * (0.25 : Float)
    let oy = Float::from_int(qy + gy * 10)
    let c0 = Float::from_int((i * 37 + frame * 11) % 255) / (255.0 : Float)
    let c1 = Float::from_int((i * 73 + frame * 5) % 255) / (255.0 : Float)
    if i % 5 == 0 {
      let tile = (i + frame) % 8
      let (u0, v0, u1, v1) = atlas_uv(tile)
      b.push_quad(
        ox, oy, (11.0 : Float), (9.0 : Float),
        (2.5 : Float), (2.5 : Float), (2.5 : Float), (2.5 : Float),
        (0.9 : Float), c0, c1, (1.0 : Float),
        (0.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float),
        u0, v0, u1, v1,
        (0.0 : Float), (0.0 : Float), (2.0 : Float),
      )
    } else {
      b.push_rect(
        ox, oy, (11.0 : Float), (9.0 : Float),
        (3.0 : Float), (1.0 : Float), (3.0 : Float), (1.0 : Float),
        (0.15 : Float) + (0.75 : Float) * c0, (0.20 : Float) + (0.70 : Float) * c1, (0.75 : Float), (0.90 : Float),
        border_w=(1.0 : Float),
        br=(0.95 : Float), bg=(0.95 : Float), bb=(1.0 : Float), ba=(0.85 : Float),
      )
    }
  }
}

///|
fn px_at(px : FixedArray[Byte], w : Int, x : Int, y : Int) -> (Int, Int, Int) {
  let idx = (y * w + x) * 4
  (px[idx].to_int(), px[idx + 1].to_int(), px[idx + 2].to_int())
}

///|
fn poll_ui_events(sc : @tycho.Swapchain) -> Bool {
  if sc.should_close() {
    return true
  }
  for ev in sc.poll_events() {
    match ev {
      @tycho.Event::KeyDown(k, _) => if k == @tycho.KEY_ESCAPE { return true }
      _ => ()
    }
  }
  false
}

///|
fn main {
  try {
    let show_win = @tycho.want_window()
    let shot = @tycho.screenshot_path()
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "Tycho 2D SDF Atlas Batcher",
        validation=true,
        headless=!show_win,
      ),
    )

    let vert_spv = @tycho.compile_glsl(
      "examples/rhi/2d-sdf-batch/sdf2d.vert",
      @tycho.ShaderStage::Vertex,
    )
    let frag_spv = @tycho.compile_glsl(
      "examples/rhi/2d-sdf-batch/sdf2d.frag",
      @tycho.ShaderStage::Fragment,
    )
    let atlas = dev.create_texture(256, 128, build_ui_atlas())
    let sampler = dev.create_sampler_desc(
      @tycho.SamplerDesc::new(
        mag=@tycho.Filter::Linear,
        min=@tycho.Filter::Linear,
        address=@tycho.AddressMode::ClampToEdge,
      ),
    )

    // --- Phase 1: Visual 2D UI Dashboard + SDF / Atlas / Scissor Verification ---
    let dash_w = 800
    let dash_h = 600
    let dash_rt = dev.create_render_target(dash_w, dash_h, @tycho.TextureFormat::RGBA8)
    let dash_pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::from_spirv(
        vert_spv,
        frag_spv,
        blend_mode=Some(@tycho.BlendMode::Premultiplied),
        cull_mode=@tycho.CullMode::None,
        color_format=Some(@tycho.TextureFormat::RGBA8),
      ),
    )
    let dash_batcher = UiBatcher::new(64)
    let dash_ssbo = dev.create_buffer_with(
      64 * QUAD_BYTES,
      @tycho.BufferKind::Storage,
      location=@tycho.MemoryLocation::CpuToGpu,
    )
    populate_dashboard(dash_batcher, dash_w, dash_h, (-1.0 : Float), (-1.0 : Float), 0)
    dash_ssbo.upload_floats(dash_batcher.data, count=dash_batcher.count * QUAD_FLOATS)

    let cmd = dev.begin_commands()
    cmd.begin_render_pass([
      @tycho.RenderTargetDesc::new(
        dash_rt,
        load_op=@tycho.LoadOp::Clear,
        store_op=@tycho.StoreOp::Store,
        clear_color=@tycho.ClearColor::black(),
      ),
    ])
    cmd.set_viewport(0.0, 0.0, Float::from_int(dash_w), Float::from_int(dash_h))
    dash_batcher.record(cmd, dash_pipe, dash_ssbo, atlas, sampler, dash_w, dash_h)
    cmd.end_render_pass()
    dev.end_commands(cmd)

    let px = dash_rt.readback()
    if shot != "" {
      let _ = @tycho.save_png(shot, dash_w, dash_h, px)
    }

    // Pixel assertions:
    let (bg_r, bg_g, bg_b) = px_at(px, dash_w, 10, 10)
    let bg_ok = bg_r < 30 && bg_g < 35 && bg_b > bg_r
    // Card 0 center (x=140, y=200) -> dark slate fill ~(36, 43, 64)
    let (cd_r, _cd_g, cd_b) = px_at(px, dash_w, 140, 200)
    let card_ok = cd_b > cd_r && cd_r > bg_r
    // Card 0 top border midpoint (x=144, y=119) -> bright cyan-blue accent
    let (_bd_r, bd_g, bd_b) = px_at(px, dash_w, 144, 119)
    let border_ok = bd_b > 200 && bd_g > 130
    // Shadow below Card 0 (x=144, y=322) -> darkened compared to pure background at (10, 10)
    let (sh_r, sh_g, sh_b) = px_at(px, dash_w, 144, 322)
    let shadow_ok = sh_b < bg_b && sh_r <= bg_r
    // Header star diamond center (tile 1) inside (x=44..84, y=36..76) -> pixel (64, 56)
    let (ic_r, ic_g, ic_b) = px_at(px, dash_w, 64, 56)
    let icon_ok = ic_r >= 0 && ic_b > 180 && ic_g > 150
    // Clipped red bar: visible at y=548 inside clip_h (354..556), clipped at y=580 outside container
    let (vis_r, vis_g, _) = px_at(px, dash_w, 300, 548)
    let (clp_r, clp_g, clp_b) = px_at(px, dash_w, 300, 580)
    // Negative-origin clip bar (-8, 576, 20, 16) -> clamped to [0..12): green at x=6, bg at x=16
    let (nv_r, nv_g, _) = px_at(px, dash_w, 6, 584)
    let (nc_r, nc_g, nc_b) = px_at(px, dash_w, 16, 584)
    let clip_ok = vis_r > 200 && vis_g < 80 && clp_r < 30 && clp_g < 35 && clp_b < 45 &&
      nv_g > 180 && nv_r < 90 && nc_r < 30 && nc_g < 35 && nc_b < 45

    dash_pipe.destroy()
    dash_ssbo.destroy()
    dash_rt.destroy()

    // --- Phase 2: High-Frequency UI Stress Benchmark (30 frames x 2,000 animated quads) ---
    // Uses a single double-buffered ring SSBO with sub-range offset/size binding + slice upload.
    let stress_w = 512
    let stress_h = 512
    let stress_quads = 2000
    let frame_bytes = stress_quads * QUAD_BYTES
    let frames = 30
    let stress_rt = dev.create_render_target(stress_w, stress_h, @tycho.TextureFormat::RGBA8)
    let stress_pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::from_spirv(
        vert_spv,
        frag_spv,
        blend_mode=Some(@tycho.BlendMode::Premultiplied),
        cull_mode=@tycho.CullMode::None,
        color_format=Some(@tycho.TextureFormat::RGBA8),
      ),
    )
    let stress_batcher = UiBatcher::new(stress_quads)
    let ring_ssbo = dev.create_buffer_with(
      2 * frame_bytes,
      @tycho.BufferKind::Storage,
      location=@tycho.MemoryLocation::CpuToGpu,
    )
    let fences : FixedArray[@tycho.Fence] = [
      dev.create_fence(true),
      dev.create_fence(true),
    ]
    let ts = dev.create_timestamp_pool(2)

    let mut total_pack_ms = 0
    let mut total_upload_ms = 0
    let mut total_record_ms = 0
    let mut total_gpu_ms = 0.0

    for f = 0; f < frames; f = f + 1 {
      let slot = f % 2
      let slot_off = slot * frame_bytes
      fences[slot].wait()
      fences[slot].reset()

      let t_pack0 = @env.now()
      populate_stress_frame(stress_batcher, f, stress_w, stress_h)
      let t_pack1 = @env.now()
      total_pack_ms = total_pack_ms + (t_pack1 - t_pack0).to_int()

      let t_up0 = @env.now()
      ring_ssbo.upload_floats(
        stress_batcher.data,
        offset=slot_off,
        count=stress_batcher.count * QUAD_FLOATS,
      )
      let t_up1 = @env.now()
      total_upload_ms = total_upload_ms + (t_up1 - t_up0).to_int()

      let t_rec0 = @env.now()
      let scmd = dev.begin_commands()
      scmd.reset_timestamps(ts)
      scmd.write_timestamp(ts, 0, at_start=true)
      scmd.begin_render_pass([
        @tycho.RenderTargetDesc::new(
          stress_rt,
          load_op=@tycho.LoadOp::Clear,
          store_op=@tycho.StoreOp::Store,
          clear_color=@tycho.ClearColor::black(),
        ),
      ])
      scmd.set_viewport(0.0, 0.0, Float::from_int(stress_w), Float::from_int(stress_h))
      stress_batcher.record(
        scmd,
        stress_pipe,
        ring_ssbo,
        atlas,
        sampler,
        stress_w,
        stress_h,
        ssbo_offset=slot_off,
        ssbo_size=frame_bytes,
      )
      scmd.end_render_pass()
      scmd.write_timestamp(ts, 1)
      dev.submit_commands(scmd, fences[slot])
      let t_rec1 = @env.now()
      total_record_ms = total_record_ms + (t_rec1 - t_rec0).to_int()

      if f == frames - 1 {
        fences[slot].wait()
        total_gpu_ms = ts.elapsed_ms(0, 1)
      }
    }
    fences[0].wait()
    fences[1].wait()

    let stress_px = stress_rt.readback()
    let (q0r, q0g, q0b) = px_at(stress_px, stress_w, 100, 100)
    let (q1r, q1g, q1b) = px_at(stress_px, stress_w, 350, 100)
    let (q2r, q2g, q2b) = px_at(stress_px, stress_w, 100, 350)
    let (q3r, q3g, q3b) = px_at(stress_px, stress_w, 350, 350)
    let stress_ok = q0r + q0g + q0b > 20 &&
      q1r + q1g + q1b > 20 &&
      q2r + q2g + q2b > 20 &&
      q3r + q3g + q3b > 20 &&
      total_gpu_ms >= 0.0

    ts.destroy()
    fences[0].destroy()
    fences[1].destroy()
    ring_ssbo.destroy()
    stress_pipe.destroy()
    stress_rt.destroy()

    // --- Phase 3: Optional Interactive Window Mode ---
    if show_win {
      let sc = dev.create_swapchain_desc(
        @tycho.SwapchainDesc::new(
          "rhi/2d-sdf-batch — Skia/Flutter UI Batching",
          dash_w,
          dash_h,
        ),
      )
      let win_pipe = dev.create_graphics_pipeline(
        @tycho.PipelineDesc::from_spirv(
          vert_spv,
          frag_spv,
          blend_mode=Some(@tycho.BlendMode::Premultiplied),
          cull_mode=@tycho.CullMode::None,
          color_format=Some(sc.color_format()),
        ),
      )
      let win_batcher = UiBatcher::new(64)
      let win_frame_bytes = 64 * QUAD_BYTES
      let win_ring_ssbo = dev.create_buffer_with(
        2 * win_frame_bytes,
        @tycho.BufferKind::Storage,
        location=@tycho.MemoryLocation::CpuToGpu,
      )
      let mut tick = 0
      while !poll_ui_events(sc) {
        let slot = tick % 2
        let slot_off = slot * win_frame_bytes
        let vw = sc.width().to_int()
        let vh = sc.height().to_int()
        let (mx, my) = sc.mouse_pos()
        populate_dashboard(
          win_batcher,
          vw,
          vh,
          Float::from_double(mx),
          Float::from_double(my),
          tick,
        )
        win_ring_ssbo.upload_floats(
          win_batcher.data,
          offset=slot_off,
          count=win_batcher.count * QUAD_FLOATS,
        )
        let wcmd = sc.begin_frame_commands()
        wcmd.begin_swapchain_pass(sc)
        win_batcher.record(
          wcmd,
          win_pipe,
          win_ring_ssbo,
          atlas,
          sampler,
          vw,
          vh,
          ssbo_offset=slot_off,
          ssbo_size=win_frame_bytes,
        )
        wcmd.end_swapchain_pass()
        sc.end_frame(wcmd)
        tick = tick + 1
      }
      win_ring_ssbo.destroy()
      win_pipe.destroy()
      sc.destroy()
    }

    sampler.destroy()
    atlas.destroy()
    dev.wait_idle()

    let errs = dev.validation_errors()
    let used = dev.allocator_used_bytes()
    dev.destroy()

    if bg_ok && card_ok && border_ok && shadow_ok && icon_ok && clip_ok &&
      stress_ok && errs == 0 && used == (0 : UInt64) {
      let kb_per_frame = (stress_quads * QUAD_BYTES) / 1024
      println(
        "[rhi/2d-sdf-batch] OK — dashboard SDF+atlas+scissor verified; 30f x 2000 quads (\{kb_per_frame} KB/f CpuToGpu): pack=\{total_pack_ms}ms upload=\{total_upload_ms}ms record=\{total_record_ms}ms last_gpu=\{total_gpu_ms}ms, 0 validation errors",
      )
    } else {
      println(
        "[rhi/2d-sdf-batch] FAIL — bg=\{bg_ok} card=\{card_ok} border=\{border_ok} shadow=\{shadow_ok} icon=\{icon_ok} clip=\{clip_ok} stress=\{stress_ok} errs=\{errs} used=\{used} (bg=(\{bg_r},\{bg_g},\{bg_b}) sh=(\{sh_r},\{sh_g},\{sh_b}) ic=(\{ic_r},\{ic_g},\{ic_b}) vis=(\{vis_r},\{vis_g}) clp=(\{clp_r},\{clp_g},\{clp_b}))",
      )
    }
  } catch {
    err => println("[rhi/2d-sdf-batch] FAIL — \{err}")
  }
}
