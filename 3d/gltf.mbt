// Maps a parsed `@tgeo.GltfScene` into renderer resources and scene nodes.

///|
fn add_gltf_node(
  renderer : Renderer3D,
  scene : Scene,
  gltf : @tgeo.GltfScene,
  materials : Array[MaterialHandle],
  meshes : Array[MeshHandle],
  index : Int,
  parent : NodeId?,
  out : Array[NodeId?],
) -> Unit raise {
  if index < 0 || index >= gltf.nodes.length() {
    return
  }
  let n = gltf.nodes[index]
  let mut payload = NodePayload::Empty
  let mut bounds : @tmath.Aabb3? = None
  if n.mesh >= 0 && n.mesh < meshes.length() {
    let md = gltf.meshes[n.mesh]
    let slot = if md.groups.length() > 0 {
      md.groups[0].material_slot
    } else {
      0
    }
    let mat = if slot >= 0 && slot < materials.length() {
      materials[slot]
    } else {
      materials[0]
    }
    payload = NodePayload::Mesh(MeshInstance::new(meshes[n.mesh], mat))
    bounds = renderer.mesh_bounds(meshes[n.mesh])
  }
  let node = scene.create_node(
    parent?=parent,
    transform=@tmath.Transform::new(n.translation, n.rotation, n.scale),
    payload=payload,
    name=n.name,
  )
  scene.set_local_bounds(node, bounds)
  out[index] = Some(node)
  for c in n.children {
    add_gltf_node(renderer, scene, gltf, materials, meshes, c, Some(node), out)
  }
}

///|
fn upload_gltf_texture(
  renderer : Renderer3D,
  gltf : @tgeo.GltfScene,
  index : Int,
  srgb : Bool,
) -> TextureHandle? raise {
  if index < 0 || index >= gltf.textures.length() {
    return None
  }
  let src = gltf.textures[index].source
  if src < 0 || src >= gltf.images.length() {
    return None
  }
  let decoded = try {
    Some(@image.decode_rgba(gltf.images[src]))
  } catch {
    _ => None
  }
  match decoded {
    Some(img) => {
      let px = FixedArray::make(img.data.length(), (0 : Byte))
      for i = 0; i < img.data.length(); i = i + 1 {
        px[i] = img.data[i]
      }
      Some(renderer.create_texture(img.width, img.height, px, srgb~))
    }
    None => None
  }
}

///|
/// Everything a glTF import produced: instantiated nodes (indexed by glTF node
/// index), the uploaded meshes/materials, the scene roots, and the animation
/// clips already bound to the instantiated nodes.
pub(all) struct GltfInstance {
  roots : Array[NodeId]
  nodes : Array[NodeId?]
  meshes : Array[MeshHandle]
  materials : Array[MaterialHandle]
  animations : Array[AnimationClip]
}

///|
/// GPU resources shared by every instantiated node of one import.
priv struct GltfAssets {
  meshes : Array[MeshHandle]
  materials : Array[MaterialHandle]
  nodes : Array[NodeId?]
}

///|
fn load_gltf_assets(
  renderer : Renderer3D,
  scene : Scene,
  gltf : @tgeo.GltfScene,
  parent : NodeId?,
) -> GltfAssets raise {
  let materials : Array[MaterialHandle] = []
  for m in gltf.materials {
    let mut desc = MaterialDesc::pbr(
      m.base_color,
      metallic=m.metallic,
      roughness=m.roughness,
    )
    desc = match m.alpha_mode {
      @tgeo.GltfAlphaMode::Opaque => desc
      @tgeo.GltfAlphaMode::Mask(c) => desc.with_alpha(AlphaMode::Mask(c))
      @tgeo.GltfAlphaMode::Blend => desc.with_alpha(AlphaMode::Blend)
    }
    match upload_gltf_texture(renderer, gltf, m.base_color_tex, true) {
      Some(h) => desc = desc.with_albedo_tex(h)
      None => ()
    }
    match upload_gltf_texture(renderer, gltf, m.normal_tex, false) {
      Some(h) => desc = desc.with_normal_tex(h)
      None => ()
    }
    materials.push(renderer.create_material(desc))
  }
  if materials.length() == 0 {
    materials.push(
      renderer.create_material(MaterialDesc::pbr(@tmath.Vec4::new(1.0, 1.0, 1.0, 1.0))),
    )
  }
  let meshes : Array[MeshHandle] = []
  for md in gltf.meshes {
    meshes.push(renderer.upload_mesh(md))
  }
  let out : Array[NodeId?] = []
  for i = 0; i < gltf.nodes.length(); i = i + 1 {
    out.push(None)
  }
  for r in gltf.roots {
    add_gltf_node(renderer, scene, gltf, materials, meshes, r, parent, out)
  }
  { meshes, materials, nodes: out }
}

///|
/// Upload every glTF mesh/material, instantiate its node hierarchy under
/// `parent`, and return a single `GltfInstance` that ties the nodes, GPU
/// resources, and animation clips together. This is the entry point most
/// callers want; `load_gltf` / `load_gltf_with_nodes` remain thin wrappers.
pub fn load_gltf_instance(
  renderer : Renderer3D,
  scene : Scene,
  gltf : @tgeo.GltfScene,
  parent? : NodeId,
) -> GltfInstance raise {
  let assets = load_gltf_assets(renderer, scene, gltf, parent)
  let roots : Array[NodeId] = []
  for entry in assets.nodes {
    match entry {
      Some(id) => roots.push(id)
      None => ()
    }
  }
  {
    roots,
    nodes: assets.nodes,
    meshes: assets.meshes,
    materials: assets.materials,
    animations: load_gltf_animations(gltf, assets.nodes),
  }
}

///|
/// Node map indexed by glTF node index (None for nodes that are not
/// instantiated), which `load_gltf_animations` uses to bind channels.
pub fn load_gltf_with_nodes(
  renderer : Renderer3D,
  scene : Scene,
  gltf : @tgeo.GltfScene,
  parent? : NodeId,
) -> Array[NodeId?] raise {
  (load_gltf_instance(renderer, scene, gltf, parent?=parent)).nodes
}

///|
/// Upload every glTF mesh/material and instantiate its node hierarchy under
/// `parent`. Returns the created nodes in pre-order.
pub fn load_gltf(
  renderer : Renderer3D,
  scene : Scene,
  gltf : @tgeo.GltfScene,
  parent? : NodeId,
) -> Array[NodeId] raise {
  (load_gltf_instance(renderer, scene, gltf, parent?=parent)).roots
}

///|
/// Convert glTF animation channels into engine clips. Channels sharing a node
/// merge into one transform track; cubic-spline keys use their value key.
pub fn load_gltf_animations(
  gltf : @tgeo.GltfScene,
  node_map : Array[NodeId?],
) -> Array[AnimationClip] {
  let clips : Array[AnimationClip] = []
  for anim in gltf.animations {
    let ids : Array[NodeId] = []
    let tracks : Array[TransformTrack] = []
    for ch in anim.channels {
      if ch.node < 0 || ch.node >= node_map.length() {
        continue
      }
      let id = match node_map[ch.node] {
        Some(x) => x
        None => continue
      }
      let interp : Interpolation = match ch.interpolation {
        @tgeo.GltfAnimationInterpolation::Step => Interpolation::Step
        _ => Interpolation::Linear
      }
      let mut slot = -1
      for i = 0; i < ids.length(); i = i + 1 {
        if ids[i].index() == id.index() {
          slot = i
        }
      }
      let base = if slot >= 0 {
        tracks[slot]
      } else {
        TransformTrack::new()
      }
      let track = match ch.path {
        @tgeo.GltfAnimationPath::Translation => {
          let values : Array[@tmath.Vec3] = []
          for v in ch.values {
            values.push(@tmath.Vec3::new(v.x, v.y, v.z))
          }
          TransformTrack::new(
            translation=Vec3Track::new(ch.times, values, interpolation=interp),
            rotation?=base.rotation,
            scale?=base.scale,
          )
        }
        @tgeo.GltfAnimationPath::Rotation => {
          let values : Array[@tmath.Quat] = []
          for v in ch.values {
            values.push(@tmath.Quat::from_xyzw(v.x, v.y, v.z, v.w))
          }
          TransformTrack::new(
            translation?=base.translation,
            rotation=QuatTrack::new(ch.times, values, interpolation=interp),
            scale?=base.scale,
          )
        }
        @tgeo.GltfAnimationPath::Scale => {
          let values : Array[@tmath.Vec3] = []
          for v in ch.values {
            values.push(@tmath.Vec3::new(v.x, v.y, v.z))
          }
          TransformTrack::new(
            translation?=base.translation,
            rotation?=base.rotation,
            scale=Vec3Track::new(ch.times, values, interpolation=interp),
          )
        }
      }
      if slot >= 0 {
        tracks[slot] = track
      } else {
        ids.push(id)
        tracks.push(track)
      }
    }
    let channels : Array[AnimationChannel] = []
    for i = 0; i < ids.length(); i = i + 1 {
      channels.push(AnimationChannel::new(ids[i], tracks[i]))
    }
    clips.push(AnimationClip::new(anim.name, channels))
  }
  clips
}
