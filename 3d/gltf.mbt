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
) -> Array[NodeId] raise {
  if index < 0 || index >= gltf.nodes.length() {
    return []
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
    parent=parent,
    transform=@tmath.Transform::new(n.translation, n.rotation, n.scale),
    payload=payload,
    name=n.name,
  )
  scene.set_local_bounds(node, bounds)
  let out : Array[NodeId] = [node]
  for c in n.children {
    for id in add_gltf_node(renderer, scene, gltf, materials, meshes, c, Some(node)) {
      out.push(id)
    }
  }
  out
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
  match @tycho.decode_image(gltf.images[src]) {
    Some((rgba, w, h)) => {
      let px = FixedArray::make(rgba.length(), (0 : Byte))
      for i = 0; i < rgba.length(); i = i + 1 {
        px[i] = rgba[i]
      }
      Some(renderer.create_texture(w, h, px, srgb~))
    }
    None => None
  }
}

///|
/// Upload every glTF mesh/material and instantiate its node hierarchy under
/// `parent`. Returns the created nodes in pre-order.
pub fn load_gltf(
  renderer : Renderer3D,
  scene : Scene,
  gltf : @tgeo.GltfScene,
  parent? : NodeId? = None,
) -> Array[NodeId] raise {
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
  let out : Array[NodeId] = []
  for r in gltf.roots {
    for id in add_gltf_node(renderer, scene, gltf, materials, meshes, r, parent) {
      out.push(id)
    }
  }
  out
}
