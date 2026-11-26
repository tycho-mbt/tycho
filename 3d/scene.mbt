// Arena-based scene graph.
//
// three.js models the scene as an `Object3D` inheritance tree; MoonBit has no
// inheritance and struct references can form cycles, so nodes live in an arena
// and are referenced by generation-checked `NodeId` handles. A node stores its
// local TRS, a cached world `Affine3`, and an ADT payload (mesh / light /
// camera). World transforms are propagated with a dirty flag in one iterative
// depth-first pass.

///|
/// Renderer-owned GPU mesh. The scene only carries the handle.
#derive(Eq, Debug)
pub(all) struct MeshHandle {
  priv id : Int
}

///|
pub fn MeshHandle::from_id(id : Int) -> MeshHandle {
  { id, }
}

///|
pub fn MeshHandle::id(self : MeshHandle) -> Int {
  self.id
}

///|
/// Generation-checked arena index. Destroying a node bumps its generation, so
/// stale handles can never alias a reused slot.
#derive(Eq, Debug)
pub(all) struct NodeId {
  priv index : Int
  priv generation : UInt
}

///|
fn NodeId::new(index : Int, generation : UInt) -> NodeId {
  { index, generation }
}

///|
pub fn NodeId::index(self : NodeId) -> Int {
  self.index
}

///|
pub(all) enum NodePayload {
  Empty
  Mesh(MeshHandle)
  Light(Light)
  Camera(Camera)
}

///|
priv struct SceneNode {
  mut transform : @tmath.Transform
  mut world : @tmath.Affine3
  mut world_dirty : Bool
  mut visible : Bool
  mut layer_mask : UInt
  mut name : String
  mut payload : NodePayload
  mut parent : NodeId?
  children : Array[NodeId]
  mut local_bounds : @tmath.Aabb3?
  mut alive : Bool
  mut generation : UInt
}

///|
fn SceneNode::empty() -> SceneNode {
  {
    transform: @tmath.Transform::identity(),
    world: @tmath.Affine3::identity(),
    world_dirty: true,
    visible: true,
    layer_mask: (0xFFFFFFFF : UInt),
    name: "",
    payload: NodePayload::Empty,
    parent: None,
    children: [],
    local_bounds: None,
    alive: false,
    generation: 0,
  }
}

///|
pub struct Scene {
  priv nodes : Array[SceneNode]
  priv roots : Array[NodeId]
  priv free : Array[Int]
  priv mut alive_count : Int
}

///|
pub fn Scene::new() -> Scene {
  { nodes: [], roots: [], free: [], alive_count: 0 }
}

///|
fn Scene::node(self : Scene, id : NodeId) -> SceneNode? {
  if id.index < 0 || id.index >= self.nodes.length() {
    return None
  }
  let n = self.nodes[id.index]
  if !n.alive || n.generation != id.generation {
    return None
  }
  Some(n)
}

///|
/// Create a node (optionally parented) and return its handle.
pub fn Scene::create_node(
  self : Scene,
  parent? : NodeId? = None,
  transform? : @tmath.Transform = @tmath.Transform::identity(),
  payload? : NodePayload = NodePayload::Empty,
  name? : String = "",
  layer_mask? : UInt = (0xFFFFFFFF : UInt),
) -> NodeId {
  let mut index = -1
  if self.free.length() > 0 {
    match self.free.pop() {
      Some(i) => index = i
      None => ()
    }
  }
  if index < 0 {
    index = self.nodes.length()
    self.nodes.push(SceneNode::empty())
  }
  let n = self.nodes[index]
  n.generation = n.generation + (1 : UInt)
  n.transform = transform
  n.world = @tmath.Affine3::identity()
  n.world_dirty = true
  n.visible = true
  n.layer_mask = layer_mask
  n.name = name
  n.payload = payload
  n.parent = None
  n.children.clear()
  n.local_bounds = None
  n.alive = true
  self.alive_count = self.alive_count + 1
  let id = NodeId::new(index, n.generation)
  match parent {
    Some(p) =>
      match self.node(p) {
        Some(pn) => {
          pn.children.push(id)
          n.parent = Some(p)
        }
        None => self.roots.push(id)
      }
    None => self.roots.push(id)
  }
  id
}

///|
fn remove_id(arr : Array[NodeId], id : NodeId) -> Unit {
  let mut i = 0
  while i < arr.length() {
    if arr[i] == id {
      let _ = arr.remove(i)
      return
    }
    i = i + 1
  }
}

///|
fn Scene::detach(self : Scene, id : NodeId) -> Unit {
  match self.node(id) {
    Some(n) => {
      match n.parent {
        Some(p) =>
          match self.node(p) {
            Some(pn) => remove_id(pn.children, id)
            None => ()
          }
        None => remove_id(self.roots, id)
      }
      n.parent = None
    }
    None => ()
  }
}

///|
fn Scene::is_ancestor(self : Scene, candidate : NodeId, of : NodeId) -> Bool {
  let mut cursor : NodeId? = Some(of)
  while true {
    match cursor {
      Some(c) => {
        if c == candidate {
          return true
        }
        cursor = match self.node(c) {
          Some(n) => n.parent
          None => None
        }
      }
      None => return false
    }
  }
  false
}

///|
/// Reparent a node. With `keep_world` the node keeps its current world
/// transform by adjusting the local TRS (three.js `attach`).
pub fn Scene::set_parent(
  self : Scene,
  id : NodeId,
  parent : NodeId?,
  keep_world? : Bool = false,
) -> Bool {
  match self.node(id) {
    Some(n) => {
      match parent {
        Some(p) => {
          if p == id || self.is_ancestor(id, p) {
            return false
          }
          match self.node(p) {
            Some(_) => ()
            None => return false
          }
        }
        None => ()
      }
      if keep_world {
        self.update()
      }
      let old_world = n.world
      self.detach(id)
      match parent {
        Some(p) =>
          match self.node(p) {
            Some(pn) => {
              pn.children.push(id)
              n.parent = Some(p)
            }
            None => self.roots.push(id)
          }
        None => self.roots.push(id)
      }
      if keep_world {
        let parent_world = match parent {
          Some(p) => self.world_transform(p)
          None => @tmath.Affine3::identity()
        }
        match parent_world.inverse() {
          Some(inv) =>
            match @tmath.Transform::from_affine3(inv * old_world) {
              Some(t) => n.transform = t
              None => ()
            }
          None => ()
        }
      }
      n.world_dirty = true
      true
    }
    None => false
  }
}

///|
pub fn Scene::set_transform(self : Scene, id : NodeId, t : @tmath.Transform) -> Unit {
  match self.node(id) {
    Some(n) => {
      n.transform = t
      n.world_dirty = true
    }
    None => ()
  }
}

///|
pub fn Scene::transform(self : Scene, id : NodeId) -> @tmath.Transform {
  match self.node(id) {
    Some(n) => n.transform
    None => @tmath.Transform::identity()
  }
}

///|
pub fn Scene::set_payload(self : Scene, id : NodeId, p : NodePayload) -> Unit {
  match self.node(id) {
    Some(n) => n.payload = p
    None => ()
  }
}

///|
pub fn Scene::payload(self : Scene, id : NodeId) -> NodePayload? {
  match self.node(id) {
    Some(n) => Some(n.payload)
    None => None
  }
}

///|
pub fn Scene::set_visible(self : Scene, id : NodeId, visible : Bool) -> Unit {
  match self.node(id) {
    Some(n) => n.visible = visible
    None => ()
  }
}

///|
pub fn Scene::set_layer_mask(self : Scene, id : NodeId, mask : UInt) -> Unit {
  match self.node(id) {
    Some(n) => n.layer_mask = mask
    None => ()
  }
}

///|
pub fn Scene::set_name(self : Scene, id : NodeId, name : String) -> Unit {
  match self.node(id) {
    Some(n) => n.name = name
    None => ()
  }
}

///|
/// Local AABB used for frustum culling (normally `MeshData::bounds`).
pub fn Scene::set_local_bounds(self : Scene, id : NodeId, bounds : @tmath.Aabb3?) -> Unit {
  match self.node(id) {
    Some(n) => n.local_bounds = bounds
    None => ()
  }
}

///|
pub fn Scene::is_alive(self : Scene, id : NodeId) -> Bool {
  match self.node(id) {
    Some(_) => true
    None => false
  }
}

///|
pub fn Scene::alive_count(self : Scene) -> Int {
  self.alive_count
}

///|
pub fn Scene::parent_of(self : Scene, id : NodeId) -> NodeId? {
  match self.node(id) {
    Some(n) => n.parent
    None => None
  }
}

///|
pub fn Scene::children_of(self : Scene, id : NodeId) -> Array[NodeId] {
  let out : Array[NodeId] = []
  match self.node(id) {
    Some(n) =>
      for c in n.children {
        out.push(c)
      }
    None => ()
  }
  out
}

///|
/// Propagate local TRS into world `Affine3` with one iterative DFS. Only
/// nodes whose own or ancestor transform is dirty are recomputed.
pub fn Scene::update(self : Scene) -> Unit {
  let ids : Array[NodeId] = []
  let worlds : Array[@tmath.Affine3] = []
  let dirty : Array[Bool] = []
  for r in self.roots {
    ids.push(r)
    worlds.push(@tmath.Affine3::identity())
    dirty.push(true)
  }
  while ids.length() > 0 {
    let id_opt = ids.pop()
    let world_opt = worlds.pop()
    let dirty_opt = dirty.pop()
    match (id_opt, world_opt, dirty_opt) {
      (Some(id), Some(parent_world), Some(parent_dirty)) =>
        match self.node(id) {
          Some(n) => {
            let mut child_dirty = false
            if parent_dirty || n.world_dirty {
              n.world = parent_world * n.transform.to_affine3()
              n.world_dirty = false
              child_dirty = true
            }
            for c in n.children {
              ids.push(c)
              worlds.push(n.world)
              dirty.push(child_dirty)
            }
          }
          None => ()
        }
      _ => ()
    }
  }
}

///|
pub fn Scene::world_transform(self : Scene, id : NodeId) -> @tmath.Affine3 {
  match self.node(id) {
    Some(n) => n.world
    None => @tmath.Affine3::identity()
  }
}

///|
/// World-space AABB, or `None` when no local bounds were registered.
pub fn Scene::world_bounds(self : Scene, id : NodeId) -> @tmath.Aabb3? {
  match self.node(id) {
    Some(n) =>
      match n.local_bounds {
        Some(b) => Some(b.transform(n.world))
        None => None
      }
    None => None
  }
}

///|
/// Iterative pre-order traversal. `None` starts from every root.
pub fn Scene::traverse(
  self : Scene,
  f : (NodeId) -> Unit,
  root? : NodeId? = None,
) -> Unit {
  let stack : Array[NodeId] = []
  match root {
    Some(r) => stack.push(r)
    None =>
      for r in self.roots {
        stack.push(r)
      }
  }
  while stack.length() > 0 {
    match stack.pop() {
      Some(id) =>
        match self.node(id) {
          Some(n) => {
            f(id)
            for c in n.children {
              stack.push(c)
            }
          }
          None => ()
        }
      None => ()
    }
  }
}

///|
/// Mesh nodes that pass the layer mask and frustum test. Call `update()` first
/// so world matrices are current. Nodes without local bounds are kept.
pub fn Scene::collect_visible(
  self : Scene,
  frustum : @tmath.Frustum,
  camera_mask : UInt,
) -> Array[NodeId] {
  let out : Array[NodeId] = []
  for i = 0; i < self.nodes.length(); i = i + 1 {
    let n = self.nodes[i]
    if n.alive &&
      n.visible &&
      (n.layer_mask & camera_mask) != (0 : UInt) {
      match n.payload {
        Mesh(_) =>
          match n.local_bounds {
            Some(b) => if frustum.intersects_aabb(b.transform(n.world)) {
              out.push(NodeId::new(i, n.generation))
            }
            None => out.push(NodeId::new(i, n.generation))
          }
        _ => ()
      }
    }
  }
  out
}

///|
pub fn Scene::find_by_name(self : Scene, name : String) -> NodeId? {
  for i = 0; i < self.nodes.length(); i = i + 1 {
    let n = self.nodes[i]
    if n.alive && n.name == name {
      return Some(NodeId::new(i, n.generation))
    }
  }
  None
}

///|
/// Destroy a node and its subtree. Handles become invalid immediately.
pub fn Scene::destroy_node(self : Scene, id : NodeId) -> Unit {
  match self.node(id) {
    Some(_) => {
      let victims : Array[NodeId] = []
      let stack : Array[NodeId] = [id]
      while stack.length() > 0 {
        match stack.pop() {
          Some(cur) =>
            match self.node(cur) {
              Some(n) => {
                victims.push(cur)
                for c in n.children {
                  stack.push(c)
                }
              }
              None => ()
            }
          None => ()
        }
      }
      for v in victims {
        self.detach(v)
        match self.node(v) {
          Some(n) => {
            n.alive = false
            n.generation = n.generation + (1 : UInt)
            n.children.clear()
            n.parent = None
            self.alive_count = self.alive_count - 1
            self.free.push(v.index)
          }
          None => ()
        }
      }
    }
    None => ()
  }
}
