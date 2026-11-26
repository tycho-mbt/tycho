// Per-frame renderer counters consumed by HUDs and CI gates
// (`tools/run-3d-gates.sh` parses `to_json`).

///|
pub(all) struct RenderStats3D {
  mut draw_calls : Int
  mut triangles : Int
  mut visible_nodes : Int
  mut culled_nodes : Int
  mut shadow_passes : Int
  mut upload_bytes : Int
  mut instance_batches : Int
  mut line_segments : Int
}

///|
pub fn RenderStats3D::new() -> RenderStats3D {
  {
    draw_calls: 0,
    triangles: 0,
    visible_nodes: 0,
    culled_nodes: 0,
    shadow_passes: 0,
    upload_bytes: 0,
    instance_batches: 0,
    line_segments: 0,
  }
}

///|
pub fn RenderStats3D::summary(self : RenderStats3D) -> String {
  "draws=\{self.draw_calls} tris=\{self.triangles} visible=\{self.visible_nodes} culled=\{self.culled_nodes} shadow_passes=\{self.shadow_passes} upload_bytes=\{self.upload_bytes} instance_batches=\{self.instance_batches} lines=\{self.line_segments}"
}

///|
pub fn RenderStats3D::to_json(self : RenderStats3D) -> String {
  "{\"draw_calls\":\{self.draw_calls},\"triangles\":\{self.triangles},\"visible_nodes\":\{self.visible_nodes},\"culled_nodes\":\{self.culled_nodes},\"shadow_passes\":\{self.shadow_passes},\"upload_bytes\":\{self.upload_bytes},\"instance_batches\":\{self.instance_batches},\"line_segments\":\{self.line_segments}}"
}
