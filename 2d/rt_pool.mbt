// Pooled offscreen RenderTarget + Depth24Stencil8 management for save_layer, MSAA & blur passes.

///|
priv struct PooledTarget {
  width : Int
  height : Int
  has_depth_stencil : Bool
  samples : @tycho.SampleCount
  color : @tycho.Texture
  depth_stencil : @tycho.Texture?
  mut owner_slot : Int
  mut idle_frames : Int
}

///|
// Depth/stencil-only entries, used when rendering directly into a caller-owned
// color target (e.g. Renderer2D::render_offscreen). Kept separate so we do not
// allocate an unused color texture alongside every depth attachment.
priv struct PooledDepth {
  width : Int
  height : Int
  samples : @tycho.SampleCount
  tex : @tycho.Texture
  mut owner_slot : Int
  mut idle_frames : Int
}

///|
pub struct RenderTargetPool {
  priv dev : @tycho.Device
  priv entries : Array[PooledTarget]
  priv depths : Array[PooledDepth]
  priv mut max_bytes : Int
}

///|
pub fn RenderTargetPool::new(dev : @tycho.Device) -> RenderTargetPool {
  {
    dev,
    entries: [],
    depths: [],
    max_bytes: 256 * 1024 * 1024,
  }
}

///|
fn samples_mult(s : @tycho.SampleCount) -> Int {
  match s {
    @tycho.SampleCount::X1 => 1
    @tycho.SampleCount::X4 => 4
  }
}

///|
fn target_bytes(
  w : Int,
  h : Int,
  s : @tycho.SampleCount,
  with_ds : Bool,
) -> Int {
  let m = samples_mult(s)
  let color = w * h * 4 * m
  if with_ds {
    color + w * h * 4 * m
  } else {
    color
  }
}

///|
fn depth_bytes(w : Int, h : Int, s : @tycho.SampleCount) -> Int {
  w * h * 4 * samples_mult(s)
}

///|
pub fn RenderTargetPool::set_max_bytes(self : RenderTargetPool, bytes : Int) -> Unit {
  self.max_bytes = bytes
}

///|
pub fn RenderTargetPool::bytes_used(self : RenderTargetPool) -> Int {
  let mut total = 0
  for e in self.entries {
    total = total + target_bytes(e.width, e.height, e.samples, e.has_depth_stencil)
  }
  for d in self.depths {
    total = total + depth_bytes(d.width, d.height, d.samples)
  }
  total
}

///|
fn bucket_dim(v : Int) -> Int {
  let clamped = if v < 64 { 64 } else { v }
  ((clamped + 63) / 64) * 64
}

///|
// Evict the oldest idle attachments until allocating `needed` more bytes fits
// the budget. Only entries idle for more than 2 frames are eligible so we never
// destroy a target that may still be referenced by in-flight frames. If the
// budget cannot be met, we exceed it rather than fail rendering.
fn RenderTargetPool::trim_to_budget(self : RenderTargetPool, needed : Int) -> Unit {
  if self.max_bytes <= 0 {
    return
  }
  let mut used = self.bytes_used()
  while used + needed > self.max_bytes {
    let mut best_kind = 0
    let mut best_idx = -1
    let mut best_age = 2
    for i = 0; i < self.entries.length(); i = i + 1 {
      let e = self.entries[i]
      if e.owner_slot < 0 && e.idle_frames > best_age {
        best_age = e.idle_frames
        best_kind = 1
        best_idx = i
      }
    }
    for i = 0; i < self.depths.length(); i = i + 1 {
      let d = self.depths[i]
      if d.owner_slot < 0 && d.idle_frames > best_age {
        best_age = d.idle_frames
        best_kind = 2
        best_idx = i
      }
    }
    if best_idx < 0 {
      break
    }
    if best_kind == 1 {
      let e = self.entries[best_idx]
      used = used - target_bytes(e.width, e.height, e.samples, e.has_depth_stencil)
      e.color.destroy()
      match e.depth_stencil {
        Some(ds) => ds.destroy()
        None => ()
      }
      let _ = self.entries.remove(best_idx)
    } else {
      let d = self.depths[best_idx]
      used = used - depth_bytes(d.width, d.height, d.samples)
      d.tex.destroy()
      let _ = self.depths.remove(best_idx)
    }
  }
}

///|
pub fn RenderTargetPool::acquire(
  self : RenderTargetPool,
  width : Int,
  height : Int,
  with_depth_stencil? : Bool = false,
  samples? : @tycho.SampleCount = @tycho.SampleCount::X1,
  slot? : Int = 0,
) -> (@tycho.Texture, @tycho.Texture?) raise @tycho.RhiError {
  let bw = bucket_dim(width)
  let bh = bucket_dim(height)
  for e in self.entries {
    if e.owner_slot < 0 &&
      e.width == bw &&
      e.height == bh &&
      e.samples == samples &&
      (!with_depth_stencil || e.has_depth_stencil) {
      e.owner_slot = slot
      e.idle_frames = 0
      return (e.color, e.depth_stencil)
    }
  }
  self.trim_to_budget(target_bytes(bw, bh, samples, with_depth_stencil))
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
    owner_slot: slot,
    idle_frames: 0,
  })
  (color, depth_stencil)
}

///|
// Acquire only a depth/stencil attachment, for callers that already own the
// color target (render_offscreen).
pub fn RenderTargetPool::acquire_depth(
  self : RenderTargetPool,
  width : Int,
  height : Int,
  samples? : @tycho.SampleCount = @tycho.SampleCount::X1,
  slot? : Int = 0,
) -> @tycho.Texture raise @tycho.RhiError {
  let bw = bucket_dim(width)
  let bh = bucket_dim(height)
  for d in self.depths {
    if d.owner_slot < 0 && d.width == bw && d.height == bh && d.samples == samples {
      d.owner_slot = slot
      d.idle_frames = 0
      return d.tex
    }
  }
  self.trim_to_budget(depth_bytes(bw, bh, samples))
  let tex = self.dev.create_depth_texture_format(
    bw,
    bh,
    @tycho.TextureFormat::Depth24Stencil8,
    samples~,
  )
  self.depths.push({
    width: bw,
    height: bh,
    samples,
    tex,
    owner_slot: slot,
    idle_frames: 0,
  })
  tex
}

///|
fn RenderTargetPool::age_depths(
  self : RenderTargetPool,
  slot : Int,
  all_slots : Bool,
) -> Unit {
  let mut i = 0
  while i < self.depths.length() {
    let d = self.depths[i]
    let owned = if all_slots { d.owner_slot >= 0 } else { d.owner_slot == slot }
    if owned {
      d.owner_slot = -1
      d.idle_frames = 0
      i = i + 1
    } else if d.owner_slot < 0 {
      d.idle_frames = d.idle_frames + 1
      if d.idle_frames > 120 {
        d.tex.destroy()
        let _ = self.depths.remove(i)
      } else {
        i = i + 1
      }
    } else {
      i = i + 1
    }
  }
}

///|
pub fn RenderTargetPool::release_slot(self : RenderTargetPool, slot : Int) -> Unit {
  let mut i = 0
  while i < self.entries.length() {
    let e = self.entries[i]
    if e.owner_slot == slot {
      e.owner_slot = -1
      e.idle_frames = 0
      i = i + 1
    } else if e.owner_slot < 0 {
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
    } else {
      i = i + 1
    }
  }
  self.age_depths(slot, false)
}

///|
pub fn RenderTargetPool::release_all(self : RenderTargetPool) -> Unit {
  let mut i = 0
  while i < self.entries.length() {
    let e = self.entries[i]
    if e.owner_slot >= 0 {
      e.owner_slot = -1
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
  self.age_depths(0, true)
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
  for d in self.depths {
    d.tex.destroy()
  }
  self.depths.clear()
}
