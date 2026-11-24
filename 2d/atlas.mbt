// Skyline 2D rectangle bin-packer and GPU DynamicAtlas wrapper for glyphs & images.

///|
priv struct SkylineNode {
  mut x : Int
  y : Int
  mut width : Int
}

///|
pub struct SkylinePacker {
  width : Int
  height : Int
  priv nodes : Array[SkylineNode]
  priv mut used_area : Int
}

///|
pub fn SkylinePacker::new(width : Int, height : Int) -> SkylinePacker {
  let w = if width > 0 { width } else { 1 }
  let h = if height > 0 { height } else { 1 }
  { width: w, height: h, nodes: [{ x: 0, y: 0, width: w }], used_area: 0 }
}

///|
pub fn SkylinePacker::reset(self : SkylinePacker) -> Unit {
  self.nodes.clear()
  self.nodes.push({ x: 0, y: 0, width: self.width })
  self.used_area = 0
}

///|
pub fn SkylinePacker::used_area(self : SkylinePacker) -> Int {
  self.used_area
}

///|
fn SkylinePacker::fit_at(self : SkylinePacker, idx : Int, w : Int, h : Int) -> Int? {
  let x = self.nodes[idx].x
  if x + w > self.width {
    return None
  }
  let mut width_left = w
  let mut i = idx
  let mut y = self.nodes[idx].y
  while width_left > 0 {
    if i >= self.nodes.length() {
      return None
    }
    if self.nodes[i].y > y {
      y = self.nodes[i].y
    }
    if y + h > self.height {
      return None
    }
    width_left = width_left - self.nodes[i].width
    i = i + 1
  }
  Some(y)
}

///|
fn SkylinePacker::merge(self : SkylinePacker) -> Unit {
  let mut i = 0
  while i + 1 < self.nodes.length() {
    if self.nodes[i].y == self.nodes[i + 1].y {
      self.nodes[i].width = self.nodes[i].width + self.nodes[i + 1].width
      let _ = self.nodes.remove(i + 1)
    } else {
      i = i + 1
    }
  }
}

///|
fn SkylinePacker::add_level(
  self : SkylinePacker,
  idx : Int,
  x : Int,
  y : Int,
  w : Int,
  h : Int,
) -> Unit {
  self.nodes.insert(idx, { x, y: y + h, width: w })
  let i = idx + 1
  while i < self.nodes.length() {
    let prev = self.nodes[i - 1]
    let cur = self.nodes[i]
    let prev_right = prev.x + prev.width
    if cur.x < prev_right {
      let shrink = prev_right - cur.x
      if cur.width <= shrink {
        let _ = self.nodes.remove(i)
        continue
      } else {
        cur.x = cur.x + shrink
        cur.width = cur.width - shrink
        break
      }
    } else {
      break
    }
  }
  self.merge()
}

///|
pub fn SkylinePacker::alloc(self : SkylinePacker, w : Int, h : Int) -> (Int, Int)? {
  if w <= 0 || h <= 0 || w > self.width || h > self.height {
    return None
  }
  let mut best_y = 0x7FFFFFFF
  let mut best_w = 0x7FFFFFFF
  let mut best_idx = -1
  let mut best_x = 0
  for i = 0; i < self.nodes.length(); i = i + 1 {
    match self.fit_at(i, w, h) {
      Some(y) => {
        let node = self.nodes[i]
        if y < best_y || (y == best_y && node.width < best_w) {
          best_y = y
          best_idx = i
          best_w = node.width
          best_x = node.x
        }
      }
      None => ()
    }
  }
  if best_idx < 0 {
    return None
  }
  self.add_level(best_idx, best_x, best_y, w, h)
  self.used_area = self.used_area + w * h
  Some((best_x, best_y))
}

///|
pub struct DynamicAtlas {
  texture : @tycho.Texture
  width : Int
  height : Int
  packer : SkylinePacker
}

///|
pub fn DynamicAtlas::new(
  dev : @tycho.Device,
  width : Int,
  height : Int,
  format : @tycho.TextureFormat,
) -> DynamicAtlas raise @tycho.RhiError {
  let bpp = match format {
    @tycho.TextureFormat::R8 => 1
    _ => 4
  }
  let init_pixels = Bytes::makei(width * height * bpp, fn(_i) { (0 : Byte) })
  let texture = dev.create_texture_format(width, height, format, init_pixels)
  {
    texture,
    width,
    height,
    packer: SkylinePacker::new(width, height),
  }
}

///|
pub fn DynamicAtlas::alloc_and_upload(
  self : DynamicAtlas,
  w : Int,
  h : Int,
  pixels : Bytes,
  padding? : Int = 1,
) -> (Int, Int)? raise @tycho.RhiError {
  let pw = w + padding * 2
  let ph = h + padding * 2
  match self.packer.alloc(pw, ph) {
    Some((ax, ay)) => {
      let tx = ax + padding
      let ty = ay + padding
      if w > 0 && h > 0 {
        self.texture.upload_subregion(tx, ty, w, h, pixels)
      }
      Some((tx, ty))
    }
    None => None
  }
}

///|
pub fn DynamicAtlas::uv_rect(
  self : DynamicAtlas,
  x : Int,
  y : Int,
  w : Int,
  h : Int,
) -> (Float, Float, Float, Float) {
  let iw = (1.0 : Float) / Float::from_int(self.width)
  let ih = (1.0 : Float) / Float::from_int(self.height)
  (
    Float::from_int(x) * iw,
    Float::from_int(y) * ih,
    Float::from_int(x + w) * iw,
    Float::from_int(y + h) * ih,
  )
}

///|
pub fn DynamicAtlas::reset(self : DynamicAtlas) -> Unit {
  self.packer.reset()
}

///|
pub fn DynamicAtlas::destroy(self : DynamicAtlas) -> Unit {
  self.texture.destroy()
}
