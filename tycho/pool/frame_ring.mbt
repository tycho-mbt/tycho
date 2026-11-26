// Double-slot (per frame-in-flight) bump allocator over one `CpuToGpu` buffer.
//
// The RHI deliberately has no map/ring API; this is the shared utility that
// tycho_2d pioneered (per-frame slot offsets + one upload per batch) and that
// tycho_3d uses for its Frame/Object/Light/Material SSBOs.

///|
pub struct FrameRing {
  priv buffer : @tycho.Buffer
  priv slot_bytes : Int
  priv slots : Int
  priv mut slot : Int
  priv mut cursor : Int
}

///|
fn align16(n : Int) -> Int {
  ((n + 15) / 16) * 16
}

///|
/// Create a ring with `bytes_per_slot` bytes per frame slot. `slots` should
/// normally match the RHI frame-slot count (2).
pub fn FrameRing::new(
  dev : @tycho.Device,
  bytes_per_slot : Int,
  slots? : Int = 2,
  kind? : @tycho.BufferKind = @tycho.BufferKind::Storage,
) -> FrameRing raise @tycho.RhiError {
  let n = if slots < 1 { 1 } else { slots }
  let per = if bytes_per_slot < 16 { 16 } else { bytes_per_slot }
  let buffer = dev.create_buffer_with(
    per * n,
    kind,
    location=@tycho.MemoryLocation::CpuToGpu,
  )
  { buffer, slot_bytes: per, slots: n, slot: 0, cursor: 0 }
}

///|
/// Select the frame slot (`slot` is usually `cmd.frame_slot()`) and rewind the
/// bump cursor to that slot's base.
pub fn FrameRing::begin_frame(self : FrameRing, slot : Int) -> Unit {
  self.slot = slot % self.slots
  self.cursor = self.slot * self.slot_bytes
}

///|
/// Reserve `bytes` (16-byte aligned) in the current slot. Returns the byte
/// offset to pass to `bind_storage(..., offset=...)` or `upload_*`, or `None`
/// when this slot is exhausted (callers fall back to an overflow allocation).
pub fn FrameRing::alloc(self : FrameRing, bytes : Int) -> Int? {
  let aligned = align16(bytes)
  let end = (self.slot + 1) * self.slot_bytes
  if self.cursor + aligned > end {
    return None
  }
  let offset = self.cursor
  self.cursor = self.cursor + aligned
  Some(offset)
}

///|
/// Allocate and upload `count` floats; returns the byte offset, or `None` when
/// the current slot is exhausted.
pub fn FrameRing::upload_floats(
  self : FrameRing,
  data : FixedArray[Float],
  count : Int,
) -> Int? raise @tycho.RhiError {
  match self.alloc(count * 4) {
    Some(offset) => {
      self.buffer.upload_floats(data, offset=offset, count=count)
      Some(offset)
    }
    None => None
  }
}

///|
pub fn FrameRing::buffer(self : FrameRing) -> @tycho.Buffer {
  self.buffer
}

///|
pub fn FrameRing::slot_bytes(self : FrameRing) -> Int {
  self.slot_bytes
}

///|
pub fn FrameRing::used_bytes(self : FrameRing) -> Int {
  self.cursor - self.slot * self.slot_bytes
}

///|
pub fn FrameRing::reset(self : FrameRing) -> Unit {
  self.cursor = self.slot * self.slot_bytes
}

///|
pub fn FrameRing::destroy(self : FrameRing) -> Unit {
  self.buffer.destroy()
}
