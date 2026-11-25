// Pooled offscreen RenderTarget + Depth24Stencil8 management for save_layer, MSAA & blur passes.

///|
priv struct PooledTarget {
  width : Int
  height : Int
  has_depth_stencil : Bool
  samples : @tycho.SampleCount
  color : @tycho.Texture
  depth_stencil : @tycho.Texture?
  mut in_use : Bool
  mut idle_frames : Int
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
  samples? : @tycho.SampleCount = @tycho.SampleCount::X1,
) -> (@tycho.Texture, @tycho.Texture?) raise @tycho.RhiError {
  let bw = bucket_dim(width)
  let bh = bucket_dim(height)
  for e in self.entries {
    if !e.in_use &&
      e.width == bw &&
      e.height == bh &&
      e.samples == samples &&
      (!with_depth_stencil || e.has_depth_stencil) {
      e.in_use = true
      e.idle_frames = 0
      return (e.color, e.depth_stencil)
    }
  }
  let color = self.dev.create_render_target(
    bw,
    bh,
    @tycho.TextureFormat::RGBA8,
    samples~,
  )
  let depth_stencil = if with_depth_stencil {
    Some(
      self.dev.create_depth_texture_format(
        bw,
        bh,
        @tycho.TextureFormat::Depth24Stencil8,
        samples~,
      ),
    )
  } else {
    None
  }
  self.entries.push({
    width: bw,
    height: bh,
    has_depth_stencil: with_depth_stencil,
    samples,
    color,
    depth_stencil,
    in_use: true,
    idle_frames: 0,
  })
  (color, depth_stencil)
}

///|
pub fn RenderTargetPool::release_all(self : RenderTargetPool) -> Unit {
  let mut i = 0
  while i < self.entries.length() {
    let e = self.entries[i]
    if e.in_use {
      e.in_use = false
      e.idle_frames = 0
      i = i + 1
    } else {
      e.idle_frames = e.idle_frames + 1
      if e.idle_frames > 120 {
        e.color.destroy()
        match e.depth_stencil {
          Some(ds) => ds.destroy()
          None => ()
        }
        let _ = self.entries.remove(i)
      } else {
        i = i + 1
      }
    }
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
