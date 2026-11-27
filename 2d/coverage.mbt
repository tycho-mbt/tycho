// CPU coverage rasterizer for arbitrary filled paths (NonZero / EvenOdd).
// Outputs an 8-bit antialiased bitmap in device pixel space, cached by the
// caller in the shared R8 atlas and drawn as a single textured quad.

///|
pub(all) struct CoverageBitmap {
  width : Int
  height : Int
  // Device-pixel origin of the bitmap (top-left).
  origin_x : Int
  origin_y : Int
  pixels : Bytes
}

///|
fn coverage_edges(
  path : Path,
  xform : Matrix3,
  tolerance : Float,
) -> Array[RasterEdge] {
  let contours = flatten_path_contours(path, xform, tolerance~)
  let edges : Array[RasterEdge] = []
  for pair in contours {
    let pts = pair.0
    let n = pts.length()
    if n < 2 {
      continue
    }
    for i = 0; i < n; i = i + 1 {
      let a = pts[i]
      let b = pts[(i + 1) % n]
      if a.y != b.y {
        edges.push({
          x0: a.x.to_double(),
          y0: a.y.to_double(),
          x1: b.x.to_double(),
          y1: b.y.to_double(),
        })
      }
    }
  }
  edges
}

///|
// Rasterize a filled path. Returns None when the path is empty, degenerate,
// or larger than `max_area` device pixels (the caller falls back to MSAA).
pub fn rasterize_coverage(
  path : Path,
  xform : Matrix3,
  fill_rule? : FillRule,
  tolerance? : Float = (0.25 : Float),
  max_area? : Int = 262144,
) -> CoverageBitmap? {
  let rule = match fill_rule {
    Some(r) => r
    None => path.fill_rule()
  }
  let edges = coverage_edges(path, xform, tolerance)
  if edges.length() == 0 {
    return None
  }
  let mut min_x = 1.0e30
  let mut min_y = 1.0e30
  let mut max_x = -1.0e30
  let mut max_y = -1.0e30
  for e in edges {
    if e.x0 < min_x {
      min_x = e.x0
    }
    if e.x1 < min_x {
      min_x = e.x1
    }
    if e.x0 > max_x {
      max_x = e.x0
    }
    if e.x1 > max_x {
      max_x = e.x1
    }
    if e.y0 < min_y {
      min_y = e.y0
    }
    if e.y1 < min_y {
      min_y = e.y1
    }
    if e.y0 > max_y {
      max_y = e.y0
    }
    if e.y1 > max_y {
      max_y = e.y1
    }
  }
  // One pixel of margin so the 4x4 sample grid fully covers the edges.
  let ix0 = min_x.floor().to_int() - 1
  let iy0 = min_y.floor().to_int() - 1
  let ix1 = max_x.ceil().to_int() + 1
  let iy1 = max_y.ceil().to_int() + 1
  let w = ix1 - ix0
  let h = iy1 - iy0
  if w <= 0 || h <= 0 || w * h > max_area {
    return None
  }
  let pixels = Array::make(w * h, (0 : Byte))
  let subs = 4
  let inv_sub = 1.0 / subs.to_double()
  let xs : Array[Double] = []
  let dirs : Array[Int] = []
  for py = 0; py < h; py = py + 1 {
    let row_acc = Array::make(w, 0)
    for sy = 0; sy < subs; sy = sy + 1 {
      let sample_y = (iy0 + py).to_double() + (sy.to_double() + 0.5) * inv_sub
      xs.clear()
      dirs.clear()
      for e in edges {
        let up = e.y0 <= sample_y && e.y1 > sample_y
        let dn = e.y1 <= sample_y && e.y0 > sample_y
        if up || dn {
          let x_hit = e.x0 + (sample_y - e.y0) * (e.x1 - e.x0) / (e.y1 - e.y0)
          xs.push(x_hit)
          dirs.push(if up { 1 } else { -1 })
        }
      }
      // Insertion sort by x (few intersections per scanline).
      for i = 1; i < xs.length(); i = i + 1 {
        let kx = xs[i]
        let kd = dirs[i]
        let mut j = i - 1
        while j >= 0 && xs[j] > kx {
          xs[j + 1] = xs[j]
          dirs[j + 1] = dirs[j]
          j = j - 1
        }
        xs[j + 1] = kx
        dirs[j + 1] = kd
      }
      for px = 0; px < w; px = px + 1 {
        for sx = 0; sx < subs; sx = sx + 1 {
          let sample_x = (ix0 + px).to_double() + (sx.to_double() + 0.5) * inv_sub
          let mut winding = 0
          let mut crossings = 0
          for k = 0; k < xs.length(); k = k + 1 {
            if xs[k] <= sample_x {
              winding = winding + dirs[k]
              crossings = crossings + 1
            } else {
              break
            }
          }
          let inside = match rule {
            FillRule::NonZero => winding != 0
            FillRule::EvenOdd => crossings % 2 == 1
          }
          if inside {
            row_acc[px] = row_acc[px] + 1
          }
        }
      }
    }
    for px = 0; px < w; px = px + 1 {
      let a = (row_acc[px] * 255) / (subs * subs)
      pixels[py * w + px] = (if a > 255 { 255 } else { a }).to_byte()
    }
  }
  Some({
    width: w,
    height: h,
    origin_x: ix0,
    origin_y: iy0,
    pixels: Bytes::from_array(pixels[:]),
  })
}
