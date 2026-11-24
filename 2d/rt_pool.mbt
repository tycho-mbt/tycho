// Pooled offscreen RenderTarget + Depth24Stencil8 management for save_layer & blur passes.

///|
priv struct PooledTarget {
  width : Int
  height : Int
  has_depth_stencil : Bool
  color : @tycho.Texture
  depth_stencil : @tycho.Texture?
  mut in_use : Bool
}

///|
pub struct RenderTargetPool {
  priv dev : @tycho.Device
  priv entries : Array[PooledTarget]
}

///|
pub fn RenderTargetPool::new(dev : @tycho.Device) -> RenderTargetPool {
  { dev, entries: [] }
}

///|
fn bucket_dim(v : Int) -> Int {
  let clamped = if v < 64 { 64 } else { v }
  ((clamped + 63) / 64) * 64
}

///|
pub fn RenderTargetPool::acquire(
  self : RenderTargetPool,
  width : Int,
  height : Int,
  with_depth_stencil? : Bool = false,
) -> (@tycho.Texture, @tycho.Texture?) raise @tycho.RhiError {
  let bw = bucket_dim(width)
  let bh = bucket_dim(height)
  for e in self.entries {
    if !e.in_use &&
      e.width == bw &&
      e.height == bh &&
      (!with_depth_stencil || e.has_depth_stencil) {
      e.in_use = true
      return (e.color, e.depth_stencil)
    }
  }
  let color = self.dev.create_render_target(bw, bh, @tycho.TextureFormat::RGBA8)
  let depth_stencil = if with_depth_stencil {
    Some(
      self.dev.create_depth_texture_format(
        bw,
        bh,
        @tycho.TextureFormat::Depth24Stencil8,
      ),
    )
  } else {
    None
  }
  self.entries.push({
    width: bw,
    height: bh,
    has_depth_stencil: with_depth_stencil,
    color,
    depth_stencil,
    in_use: true,
  })
  (color, depth_stencil)
}

///|
pub fn RenderTargetPool::release_all(self : RenderTargetPool) -> Unit {
  for e in self.entries {
    e.in_use = false
  }
}

///|
pub fn RenderTargetPool::destroy(self : RenderTargetPool) -> Unit {
  for e in self.entries {
    e.color.destroy()
    match e.depth_stencil {
      Some(ds) => ds.destroy()
      None => ()
    }
  }
  self.entries.clear()
}
