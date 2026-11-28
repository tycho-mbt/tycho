// Renderer-facing conveniences: one-call object creation, pixel-space picking,
// resource introspection and node-scoped GPU binding release.
//
// `Renderer3D` still owns every GPU allocation; these helpers only collapse the
// common "upload + create material + create node" sequence into the single call
// a three.js `new Mesh(geometry, material)` is, and expose the small amount of
// read-back state an editor or debug HUD needs.

///|
/// Upload a geometry, allocate a material and attach the resulting mesh node in
/// one call — the closest equivalent of three.js `scene.add(new Mesh(...))`.
///
/// ```moonbit
/// let ball = renderer.add(scene, @tgeo.sphere(radius=0.5),
///   @t3d.MaterialDesc::standard(@t3d.hex(0x2E7DFF), roughness=0.35))
/// scene.set_position(ball, 0.0, 1.0, 0.0)
/// ```
///
/// Each call uploads a fresh geometry copy. When many nodes share one mesh,
/// call `upload_mesh` / `create_material` once and use `create_mesh_node`.
pub fn Renderer3D::add(
  self : Renderer3D,
  scene : Scene,
  geometry : @tgeo.MeshData,
  material : MaterialDesc,
  transform? : @tmath.Transform = @tmath.Transform::identity(),
  parent? : NodeId,
  name? : String = "",
) -> NodeId raise {
  let mesh = self.upload_mesh(geometry)
  let mat = self.create_material(material)
  let node = scene.create_node(
    parent?=parent,
    transform=transform,
    payload=NodePayload::Mesh(MeshInstance::new(mesh, mat)),
    name=name,
  )
  scene.set_local_bounds(node, self.mesh_bounds(mesh))
  node
}

///|
/// Upload a line list and attach it in one call.
pub fn Renderer3D::add_lines(
  self : Renderer3D,
  scene : Scene,
  lines : @tgeo.LineData,
  color? : @tmath.Vec4 = @tmath.Vec4::one(),
  transform? : @tmath.Transform = @tmath.Transform::identity(),
  parent? : NodeId,
  name? : String = "",
) -> NodeId raise {
  let handle = self.upload_lines(lines)
  let node = scene.create_node(
    parent?=parent,
    transform=transform,
    payload=NodePayload::Lines(
      LineInstance::new(handle, LineMaterial::new(color=color.truncate())),
    ),
    name=name,
  )
  scene.set_local_bounds(node, self.lines_bounds(handle))
  node
}

///|
/// Nearest mesh or line node under a **pixel** coordinate with a top-left
/// origin, matching pointer-event coordinates (three.js `Raycaster` usage).
/// `width` / `height` are the viewport size the event was measured in.
///
/// Both NDC conventions are handled: a Vulkan camera (y-down NDC) and a
/// Metal/WebGPU camera (y-up NDC) put the top-left pixel at the top-left of the
/// image.
pub fn Renderer3D::pick_pixels(
  self : Renderer3D,
  scene : Scene,
  camera : CameraId,
  x : Float,
  y : Float,
  width : Float,
  height : Float,
  layer_mask? : UInt = (0xFFFFFFFF : UInt),
) -> PickHit? {
  if width <= 0.0 || height <= 0.0 {
    return None
  }
  let cam = match scene.camera_component(camera.node()) {
    Some(c) => c
    None => return None
  }
  let flip : Float = if cam.clip.is_y_down() { 1.0 } else { -1.0 }
  let ndc_x = (2.0 : Float) * x / width - 1.0
  let ndc_y = flip * ((2.0 : Float) * y / height - 1.0)
  self.pick(scene, camera.node(), ndc_x, ndc_y, layer_mask~)
}

///|
/// Draw a flat linear background instead of the environment sky
/// (three.js `scene.background = new Color(...)`).
///
/// The environment cubemap stays bound for image-based lighting, so the
/// material response is unchanged; only the pixels that no geometry covers are
/// affected. The clear value goes through the same HDR → bloom → ACES chain, so
/// author it with `hex(...)` / `linear(...)` like any other color.
pub fn Renderer3D::set_background(
  self : Renderer3D,
  color : @tmath.Vec4,
) -> Unit {
  self.background = Some(color)
}

///|
/// Restore the environment sky as the background.
pub fn Renderer3D::clear_background(self : Renderer3D) -> Unit {
  self.background = None
}

///|
/// The flat background override, when one is set.
pub fn Renderer3D::background(self : Renderer3D) -> @tmath.Vec4? {
  self.background
}

///|
/// Enable linear or exp2 distance fog (three.js `scene.fog`).
///
/// Fog is mixed in linear space before tone mapping and applies to lit and
/// unlit materials alike; the sky/background layer is left untouched, matching
/// three.js. Switching fog needs no pipeline change — the parameters ride in the
/// frame UBO.
pub fn Renderer3D::set_fog(self : Renderer3D, fog : Fog) -> Unit {
  self.fog = Some(fog)
}

///|
/// Disable fog.
pub fn Renderer3D::clear_fog(self : Renderer3D) -> Unit {
  self.fog = None
}

///|
/// The active fog model, when one is set.
pub fn Renderer3D::fog(self : Renderer3D) -> Fog? {
  self.fog
}

///|
/// `true` when the renderer was created with `RendererDesc::with_ssao(true)`.
pub fn Renderer3D::ssao_enabled(self : Renderer3D) -> Bool {
  self.ssao
}

///|
/// World-space sampling radius of the SSAO hemisphere (default 0.6).
pub fn Renderer3D::set_ssao_radius(self : Renderer3D, radius : Float) -> Unit {
  self.ssao_radius = if radius <= 0.0 { 0.05 } else { radius }
}

///|
/// SSAO strength in `[0, 2]`; `0` renders without occlusion (useful for
/// toggling the effect at runtime).
pub fn Renderer3D::set_ssao_intensity(self : Renderer3D, intensity : Float) -> Unit {
  self.ssao_intensity = @tmath.clamp_f(intensity, 0.0, 2.0)
}

///|
/// Depth bias that keeps self-occlusion from darkening flat surfaces.
pub fn Renderer3D::set_ssao_bias(self : Renderer3D, bias : Float) -> Unit {
  self.ssao_bias = if bias < 0.0 { 0.0 } else { bias }
}

///|
pub fn Renderer3D::ssao_intensity(self : Renderer3D) -> Float {
  self.ssao_intensity
}

///|
/// The material description behind a handle, for editors and debug UIs.
pub fn Renderer3D::material(
  self : Renderer3D,
  handle : MaterialHandle,
) -> MaterialDesc? {
  let i = handle.id()
  if i >= 0 && i < self.materials.length() {
    Some(self.materials[i])
  } else {
    None
  }
}

///|
/// Number of materials allocated so far.
pub fn Renderer3D::material_count(self : Renderer3D) -> Int {
  self.materials.length()
}

///|
/// Number of uploaded meshes.
pub fn Renderer3D::mesh_count(self : Renderer3D) -> Int {
  self.meshes.length()
}

///|
/// Number of uploaded textures.
pub fn Renderer3D::texture_count(self : Renderer3D) -> Int {
  self.textures.length()
}

///|
/// Drop the renderer-side bindings a node owns: its LOD group, its skin
/// palette entry and its morph weights. The scene node itself is untouched, so
/// call this before or after `Scene::destroy_node` to release per-node state
/// deterministically instead of waiting for the next frame's lazy prune.
///
/// GPU meshes, materials and textures are arena-owned and are released by
/// `Renderer3D::destroy` — a destroyed node never frees a mesh other nodes may
/// still share.
pub fn Renderer3D::release_node(self : Renderer3D, node : NodeId) -> Unit {
  self.drop_bindings_for(node)
}

///|
/// Remove LOD / skin / morph registrations whose node handles no longer refer
/// to `target`.
fn Renderer3D::drop_bindings_for(self : Renderer3D, target : NodeId) -> Unit {
  let lods : Array[LodGroup] = []
  for g in self.lods {
    if g.node != target {
      lods.push(g)
    }
  }
  if lods.length() != self.lods.length() {
    self.lods.clear()
    for g in lods {
      self.lods.push(g)
    }
  }
  let skins : Array[SkinBinding] = []
  for s in self.skins {
    if s.node != target {
      skins.push(s)
    }
  }
  if skins.length() != self.skins.length() {
    self.skins.clear()
    for s in skins {
      self.skins.push(s)
    }
  }
  let weights : Array[(NodeId, Array[Float])] = []
  for entry in self.morph_weights {
    if entry.0 != target {
      weights.push(entry)
    }
  }
  if weights.length() != self.morph_weights.length() {
    self.morph_weights.clear()
    for entry in weights {
      self.morph_weights.push(entry)
    }
  }
}

///|
/// Lazily forget bindings whose scene node was destroyed. A destroyed node's
/// arena slot may be reused by a later `create_node`; registrations are matched
/// by full generation-checked `NodeId`, so a stale entry can never drive a new
/// node, and this prune keeps the palette and weight tables from growing
/// without bound in long-running editors.
fn Renderer3D::prune_dead_bindings(self : Renderer3D, scene : Scene) -> Unit {
  // Fast path: scenes that never destroy bound nodes pay no allocation at all.
  let mut dead = false
  for g in self.lods {
    if !scene.is_alive(g.node) {
      dead = true
    }
  }
  if !dead {
    for s in self.skins {
      if !scene.is_alive(s.node) {
        dead = true
      }
    }
  }
  if !dead {
    for entry in self.morph_weights {
      if !scene.is_alive(entry.0) {
        dead = true
      }
    }
  }
  if !dead {
    return
  }
  let lods : Array[LodGroup] = []
  for g in self.lods {
    if scene.is_alive(g.node) {
      lods.push(g)
    }
  }
  if lods.length() != self.lods.length() {
    self.lods.clear()
    for g in lods {
      self.lods.push(g)
    }
  }
  let skins : Array[SkinBinding] = []
  for s in self.skins {
    if scene.is_alive(s.node) {
      skins.push(s)
    }
  }
  if skins.length() != self.skins.length() {
    self.skins.clear()
    for s in skins {
      self.skins.push(s)
    }
  }
  let weights : Array[(NodeId, Array[Float])] = []
  for entry in self.morph_weights {
    if scene.is_alive(entry.0) {
      weights.push(entry)
    }
  }
  if weights.length() != self.morph_weights.length() {
    self.morph_weights.clear()
    for entry in weights {
      self.morph_weights.push(entry)
    }
  }
}
