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
