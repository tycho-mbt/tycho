// Compositing Layer tree (Offset, Transform, Clip, Opacity, BackdropFilter, Picture)
// flattening into a single tycho_2d::DisplayList.

///|
pub enum Layer {
  Container(Array[Layer])
  Offset(Float, Float, Array[Layer])
  Transform(@g2d.Matrix3, Array[Layer])
  ClipRect(@g2d.Rect, Array[Layer])
  ClipRRect(@g2d.RRect, Array[Layer])
  Opacity(Float, Array[Layer])
  BackdropFilter(@g2d.Rect, @g2d.ImageFilter, Array[Layer])
  Picture(@g2d.DisplayList)
}

///|
pub fn Layer::emit_to_canvas(self : Layer, canvas : @g2d.Canvas) -> Unit {
  match self {
    Container(children) =>
      for c in children {
        c.emit_to_canvas(canvas)
      }
    Offset(dx, dy, children) => {
      let _ = canvas.save()
      canvas.translate(dx, dy)
      for c in children {
        c.emit_to_canvas(canvas)
      }
      canvas.restore()
    }
    Transform(mat, children) => {
      let _ = canvas.save()
      canvas.concat(mat)
      for c in children {
        c.emit_to_canvas(canvas)
      }
      canvas.restore()
    }
    ClipRect(r, children) => {
      let _ = canvas.save()
      canvas.clip_rect(r)
      for c in children {
        c.emit_to_canvas(canvas)
      }
      canvas.restore()
    }
    ClipRRect(rr, children) => {
      let _ = canvas.save()
      canvas.clip_rrect(rr)
      for c in children {
        c.emit_to_canvas(canvas)
      }
      canvas.restore()
    }
    Opacity(alpha, children) => {
      let _ = canvas.save_layer(
        paint=@g2d.Paint::fill(@g2d.Color::rgba((1.0 : Float), (1.0 : Float), (1.0 : Float), alpha)),
      )
      for c in children {
        c.emit_to_canvas(canvas)
      }
      canvas.restore()
    }
    BackdropFilter(bounds, filter, children) => {
      let _ = canvas.save_backdrop_layer(bounds, filter)
      for c in children {
        c.emit_to_canvas(canvas)
      }
      canvas.restore()
    }
    Picture(dl) => canvas.draw_display_list(dl)
  }
}

///|
pub fn Layer::to_display_list(self : Layer) -> @g2d.DisplayList {
  let c = @g2d.Canvas::new()
  self.emit_to_canvas(c)
  c.finish()
}
