// three.js-style ergonomics on top of the arena scene graph.
//
// `Scene` stays the single owner of node structure, so every convenience here
// is a thin, allocation-free wrapper over `create_node` / `set_transform` /
// `payload`. Nothing in this file introduces a second source of truth: a
// position setter writes the one `Transform` the renderer consumes, and
// `look_at` writes the same `Quat` an author would have built by hand.

///|
/// Rotation that maps the local -Z axis (camera / light forward) onto
/// `direction`. Zero input yields the identity.
fn direction_rotation(direction : @tmath.Vec3) -> @tmath.Quat {
  match direction.try_normalize() {
    Some(d) => @tmath.Quat::from_rotation_arc(@tmath.Vec3::neg_z(), d)
    None => @tmath.Quat::identity()
  }
}

///|
/// Rotation part of an affine matrix, with per-axis scale normalized away so a
/// scaled parent does not corrupt a child's `look_at`.
fn quat_of_affine_rotation(a : @tmath.Affine3) -> @tmath.Quat {
  let m = a.matrix3
  let x = m.x_axis.normalize()
  let y = m.y_axis.normalize()
  let z = m.z_axis.normalize()
  if x.length_sq() < (1.0e-12 : Float) ||
    y.length_sq() < (1.0e-12 : Float) ||
    z.length_sq() < (1.0e-12 : Float) {
    @tmath.Quat::identity()
  } else {
    @tmath.Quat::from_mat3(@tmath.Mat3::from_cols(x, y, z))
  }
}

// ---------------------------------------------------------------------------
// Structure
// ---------------------------------------------------------------------------

///|
/// Create an empty transform node (three.js `Group`). Useful as a pivot or as
/// the parent of a subtree that moves together.
pub fn Scene::add_group(
  self : Scene,
  parent? : NodeId,
  transform? : @tmath.Transform = @tmath.Transform::identity(),
  name? : String = "",
) -> NodeId {
  self.create_node(parent?=parent, transform=transform, name=name)
}

///|
/// Create a light node from any `Light` value.
pub fn Scene::add_light(
  self : Scene,
  light : Light,
  transform? : @tmath.Transform = @tmath.Transform::identity(),
  parent? : NodeId,
  name? : String = "",
) -> NodeId {
  self.create_node(
    parent?=parent,
    transform=transform,
    payload=NodePayload::Light(light),
    name=name,
  )
}

///|
/// Add a directional (sun) light whose -Z axis points along `direction`.
/// `shadow` opts into the shadow atlas; the default enables it.
pub fn Scene::add_directional_light(
  self : Scene,
  color? : @tmath.Vec3 = @tmath.Vec3::one(),
  intensity? : Float = 1.0,
  direction? : @tmath.Vec3 = @tmath.Vec3::new(-0.4, -1.0, -0.3),
  shadow? : Bool = true,
  parent? : NodeId,
  name? : String = "sun",
) -> NodeId {
  self.add_light(
    Light::directional(
      color,
      intensity,
      shadow?=if shadow { Some(ShadowDesc::default()) } else { None },
    ),
    transform=@tmath.Transform::from_rotation(direction_rotation(direction)),
    parent?=parent,
    name=name,
  )
}

///|
/// Add a point light at `position` (local to `parent`).
pub fn Scene::add_point_light(
  self : Scene,
  color? : @tmath.Vec3 = @tmath.Vec3::one(),
  intensity? : Float = 1.0,
  range? : Float = 10.0,
  decay? : Float = 2.0,
  shadow? : Bool = false,
  position? : @tmath.Vec3 = @tmath.Vec3::zero(),
  parent? : NodeId,
  name? : String = "",
) -> NodeId {
  self.add_light(
    Light::point(
      color,
      intensity,
      range~,
      decay~,
      shadow?=if shadow { Some(ShadowDesc::default()) } else { None },
    ),
    transform=@tmath.Transform::from_translation(position),
    parent?=parent,
    name=name,
  )
}

///|
/// Add a spot light at `position` aimed along `direction` (its -Z axis).
pub fn Scene::add_spot_light(
  self : Scene,
  color? : @tmath.Vec3 = @tmath.Vec3::one(),
  intensity? : Float = 1.0,
  range? : Float = 10.0,
  inner_angle? : Float = 0.35,
  outer_angle? : Float = 0.55,
  shadow? : Bool = false,
  position? : @tmath.Vec3 = @tmath.Vec3::zero(),
  direction? : @tmath.Vec3 = @tmath.Vec3::neg_y(),
  parent? : NodeId,
  name? : String = "",
) -> NodeId {
  self.add_light(
    Light::spot(
      color,
      intensity,
      range~,
      inner_angle~,
      outer_angle~,
      shadow?=if shadow { Some(ShadowDesc::default()) } else { None },
    ),
    transform=@tmath.Transform::new(
      position,
      direction_rotation(direction),
      @tmath.Vec3::one(),
    ),
    parent?=parent,
    name=name,
  )
}

///|
/// Add a uniform ambient term.
pub fn Scene::add_ambient_light(
  self : Scene,
  color? : @tmath.Vec3 = @tmath.Vec3::one(),
  intensity? : Float = 0.2,
  parent? : NodeId,
  name? : String = "",
) -> NodeId {
  self.add_light(Light::ambient(color, intensity), parent?=parent, name=name)
}

///|
/// Add a sky/ground hemisphere term.
pub fn Scene::add_hemisphere_light(
  self : Scene,
  sky : @tmath.Vec3,
  ground : @tmath.Vec3,
  intensity? : Float = 1.0,
  parent? : NodeId,
  name? : String = "",
) -> NodeId {
  self.add_light(Light::hemisphere(sky, ground, intensity), parent?=parent, name=name)
}

///|
/// Detach a node from its parent and keep it alive as a scene root
/// (three.js `Object3D.remove`). The subtree, payload and GPU resources are
/// untouched; use `destroy_node` to release the subtree.
pub fn Scene::remove(self : Scene, id : NodeId) -> Unit {
  let _ = self.set_parent(id, None)
}

///|
/// Destroy every node in the scene, parents before children.
/// Renderer-owned GPU resources are not affected.
pub fn Scene::clear(self : Scene) -> Unit {
  for r in self.roots() {
    self.destroy_node(r)
  }
}

///|
/// Snapshot of the current root nodes (roots change as nodes are reparented).
pub fn Scene::roots(self : Scene) -> Array[NodeId] {
  let out : Array[NodeId] = []
  for r in self.roots {
    out.push(r)
  }
  out
}

// ---------------------------------------------------------------------------
// Reads
// ---------------------------------------------------------------------------

///|
/// Local translation of a node.
pub fn Scene::position(self : Scene, id : NodeId) -> @tmath.Vec3 {
  self.transform(id).translation
}

///|
/// Local rotation of a node.
pub fn Scene::rotation(self : Scene, id : NodeId) -> @tmath.Quat {
  self.transform(id).rotation
}

///|
/// Local scale of a node.
pub fn Scene::scale(self : Scene, id : NodeId) -> @tmath.Vec3 {
  self.transform(id).scale
}

///|
/// The node's own visibility flag (not inherited).
pub fn Scene::visible(self : Scene, id : NodeId) -> Bool {
  match self.node(id) {
    Some(n) => n.visible
    None => false
  }
}

///|
/// Effective visibility: `false` when the node or any ancestor is hidden.
///
/// three.js hides a whole subtree by setting `group.visible = false`; the
/// renderer, picker and light collection all consult this function so the same
/// behaviour holds here.
pub fn Scene::is_visible_in_world(self : Scene, id : NodeId) -> Bool {
  let mut cursor : NodeId? = Some(id)
  while true {
    match cursor {
      Some(c) =>
        match self.node(c) {
          Some(n) =>
            if !n.visible {
              return false
            } else {
              cursor = n.parent
            }
          None => return false
        }
      None => return true
    }
  }
  false
}

///|
/// Layer mask used by frustum collection and picking.
pub fn Scene::layer_mask(self : Scene, id : NodeId) -> UInt {
  match self.node(id) {
    Some(n) => n.layer_mask
    None => (0 : UInt)
  }
}

///|
/// Node name (empty string when unnamed or dead).
pub fn Scene::name(self : Scene, id : NodeId) -> String {
  match self.node(id) {
    Some(n) => n.name
    None => ""
  }
}

///|
/// Number of direct children.
pub fn Scene::child_count(self : Scene, id : NodeId) -> Int {
  match self.node(id) {
    Some(n) => n.children.length()
    None => 0
  }
}

///|
/// The mesh drawable of a node, when it has one.
pub fn Scene::mesh_of(self : Scene, id : NodeId) -> MeshInstance? {
  match self.payload(id) {
    Some(NodePayload::Mesh(m)) => Some(m)
    _ => None
  }
}

///|
/// The line drawable of a node, when it has one.
pub fn Scene::lines_of(self : Scene, id : NodeId) -> LineInstance? {
  match self.payload(id) {
    Some(NodePayload::Lines(l)) => Some(l)
    _ => None
  }
}

///|
/// The light component of a node, when it has one.
pub fn Scene::light_of(self : Scene, id : NodeId) -> Light? {
  match self.payload(id) {
    Some(NodePayload::Light(l)) => Some(l)
    _ => None
  }
}

///|
/// The camera component of a node, when it has one.
pub fn Scene::camera_component(self : Scene, id : NodeId) -> Camera? {
  match self.payload(id) {
    Some(NodePayload::Camera(c)) => Some(c)
    _ => None
  }
}

///|
/// The camera component behind a typed handle.
pub fn Scene::camera(self : Scene, handle : CameraId) -> Camera? {
  self.camera_component(handle.node())
}

///|
/// Replace a camera component (e.g. after a resize: `cam.with_viewport(w, h)`).
/// A handle that no longer refers to a camera node is ignored.
pub fn Scene::set_camera(
  self : Scene,
  handle : CameraId,
  value : Camera,
) -> Unit {
  match self.camera_component(handle.node()) {
    Some(_) => self.set_payload(handle.node(), NodePayload::Camera(value))
    None => ()
  }
}

///|
/// Every live node carrying `name`, in arena order.
pub fn Scene::find_all_by_name(self : Scene, name : String) -> Array[NodeId] {
  let out : Array[NodeId] = []
  for i = 0; i < self.nodes.length(); i = i + 1 {
    let n = self.nodes[i]
    if n.alive && n.name == name {
      out.push(NodeId::new(i, n.generation))
    }
  }
  out
}

// ---------------------------------------------------------------------------
// Writes
// ---------------------------------------------------------------------------

///|
/// Write the local translation, preserving rotation and scale.
pub fn Scene::set_position(
  self : Scene,
  id : NodeId,
  p : @tmath.Vec3,
) -> Unit {
  let t = self.transform(id)
  self.set_transform(id, { ..t, translation: p })
}

///|
/// Write the local rotation, preserving translation and scale.
pub fn Scene::set_rotation(
  self : Scene,
  id : NodeId,
  q : @tmath.Quat,
) -> Unit {
  let t = self.transform(id)
  self.set_transform(id, { ..t, rotation: q.normalize() })
}

///|
/// Write the local rotation from Euler angles in radians.
/// `order` defaults to `XYZ`, matching three.js `Euler` / `Object3D.rotation`.
pub fn Scene::set_euler(
  self : Scene,
  id : NodeId,
  x : Float,
  y : Float,
  z : Float,
  order? : @tmath.EulerOrder = @tmath.EulerOrder::XYZ,
) -> Unit {
  self.set_rotation(id, @tmath.Quat::from_euler(order, x, y, z))
}

///|
/// Write the local scale, preserving translation and rotation.
pub fn Scene::set_scale(
  self : Scene,
  id : NodeId,
  s : @tmath.Vec3,
) -> Unit {
  let t = self.transform(id)
  self.set_transform(id, { ..t, scale: s })
}

///|
/// Set a uniform scale on all three axes.
pub fn Scene::set_uniform_scale(
  self : Scene,
  id : NodeId,
  s : Float,
) -> Unit {
  self.set_scale(id, @tmath.Vec3::splat(s))
}

///|
/// Offset the local translation by `delta` (parent space), preserving
/// rotation and scale.
pub fn Scene::translate(
  self : Scene,
  id : NodeId,
  delta : @tmath.Vec3,
) -> Unit {
  self.set_position(id, self.transform(id).translation + delta)
}

///|
/// Rotate around a local-space axis by `angle` radians (three.js
/// `Object3D.rotateOnAxis`).
pub fn Scene::rotate(
  self : Scene,
  id : NodeId,
  axis : @tmath.Vec3,
  angle : Float,
) -> Unit {
  let t = self.transform(id)
  self.set_rotation(
    id,
    t.rotation * @tmath.Quat::from_axis_angle(axis, angle),
  )
}

///|
/// Rotate around a world-space axis by `angle` radians (three.js
/// `Object3D.rotateOnWorldAxis`).
pub fn Scene::rotate_world(
  self : Scene,
  id : NodeId,
  axis : @tmath.Vec3,
  angle : Float,
) -> Unit {
  let t = self.transform(id)
  self.set_rotation(
    id,
    @tmath.Quat::from_axis_angle(axis, angle) * t.rotation,
  )
}

///|
/// Orient the node so its local -Z axis points at `target` and its local +Y
/// axis follows `up` (three.js `Object3D.lookAt`).
///
/// The node's world position is used, and the parent's world rotation is
/// divided out so the result is correct under transformed parents. A node at
/// `target` keeps its current rotation instead of producing NaNs.
pub fn Scene::look_at(
  self : Scene,
  id : NodeId,
  target : @tmath.Vec3,
  up? : @tmath.Vec3 = @tmath.Vec3::unit_y(),
) -> Unit {
  self.update()
  let pos = self.world_transform(id).translation
  let forward = match (target - pos).try_normalize() {
    Some(f) => f
    None => return
  }
  let backward = -forward
  let right = match up.cross(backward).try_normalize() {
    Some(r) => r
    None => backward.any_orthonormal()
  }
  let u = backward.cross(right)
  let world_q = @tmath.Quat::from_mat3(@tmath.Mat3::from_cols(right, u, backward))
  let local_q = match self.parent_of(id) {
    Some(p) =>
      (quat_of_affine_rotation(self.world_transform(p)).inverse() * world_q).normalize()
    None => world_q
  }
  self.set_rotation(id, local_q)
}

// ---------------------------------------------------------------------------
// Spaces
// ---------------------------------------------------------------------------

///|
/// Transform a point from the node's local space to world space.
/// Calls `update()` so the result is current even right after a transform write.
pub fn Scene::local_to_world(
  self : Scene,
  id : NodeId,
  p : @tmath.Vec3,
) -> @tmath.Vec3 {
  self.update()
  self.world_transform(id).transform_point3(p)
}

///|
/// Transform a world-space point into the node's local space.
pub fn Scene::world_to_local(
  self : Scene,
  id : NodeId,
  p : @tmath.Vec3,
) -> @tmath.Vec3? {
  self.update()
  match self.world_transform(id).inverse() {
    Some(inv) => Some(inv.transform_point3(p))
    None => None
  }
}

///|
/// Transform a direction (no translation) from local to world space,
/// including the node's scale.
pub fn Scene::direction_to_world(
  self : Scene,
  id : NodeId,
  dir : @tmath.Vec3,
) -> @tmath.Vec3 {
  self.update()
  self.world_transform(id).transform_vector3(dir)
}
