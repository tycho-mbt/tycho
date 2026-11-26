// DisplayList immutable draw op stream (inspired by Flutter DisplayList / SkPicture).

///|
#derive(Eq, Debug)
pub(all) enum ClipOp {
  Intersect
  Difference
}

///|
pub(all) enum DrawOp {
  Clear(Color)
  Save
  Restore
  SaveLayer(Rect?, Paint)
  SaveBackdropLayer(Rect, ImageFilter)
  Concat(Matrix3)
  ClipRect(Rect, ClipOp)
  ClipRRect(RRect, ClipOp)
  ClipPath(Path, ClipOp)
  DrawRect(Rect, Paint)
  DrawRRect(RRect, Paint)
  DrawCircle(Point, Float, Paint)
  DrawLine(Point, Point, Paint)
  DrawRRectShadow(RRect, Float, Float, Float, Float, Color)
  DrawPath(Path, Paint)
  DrawImage(Image2D, Rect, Rect, Paint)
  DrawParagraph(Paragraph, Point)
  DrawDisplayList(DisplayList)
}

///|
pub struct DisplayList {
  ops : FixedArray[DrawOp]
  bounds : Rect
}

///|
pub fn DisplayList::op_count(self : DisplayList) -> Int {
  self.ops.length()
}

///|
pub fn DisplayList::bounds(self : DisplayList) -> Rect {
  self.bounds
}

///|
// True when replaying this display list requires an offscreen color target:
// group/backdrop layers need a texture to composite, and path rendering uses an
// offscreen MSAA target for anti-aliasing plus a source texture for filters.
// Stencil-only clips and Tier-1 primitives can render straight into a swapchain
// pass that carries a depth/stencil attachment.
pub fn DisplayList::needs_offscreen(self : DisplayList) -> Bool {
  for op in self.ops {
    match op {
      DrawOp::DrawPath(_, _) => return true
      DrawOp::ClipPath(_, _) => return true
      DrawOp::ClipRRect(_, _) => return true
      DrawOp::ClipRect(_, ClipOp::Difference) => return true
      DrawOp::SaveLayer(_, _) => return true
      DrawOp::SaveBackdropLayer(_, _) => return true
      DrawOp::DrawDisplayList(sub) => if sub.needs_offscreen() { return true }
      _ => ()
    }
  }
  false
}
