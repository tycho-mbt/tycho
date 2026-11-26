# `laplaceliu/tycho_3d`

three.js-inspired pure-MoonBit 3D rendering library over `laplaceliu/tycho`
(RHI), `laplaceliu/tycho_math`, and `laplaceliu/tycho_geometry`.

## What works today (M0–M1)

- `Scene`: arena-based scene graph with generation-checked `NodeId` handles,
  dirty-flag world-transform propagation, reparenting with `keep_world`,
  layers, traversal, subtree destruction, and frustum-culled collection.
- `AnimationClip` / `AnimationPlayer`: translation / rotation / scale keyframe
  tracks with linear (Vec3) or slerp (Quat) interpolation, per-channel node
  binding, looping or clamped playback, and `update(scene, dt)` that writes
  local transforms (example 76).
- `Camera`: perspective (infinite reversed-Z by default) / orthographic
  reversed-Z projections, view/view-projection matrices, screen rays, and an
  analytic sky ray matrix.
- Split-sum IBL: a 64x64 RG16F LUT is baked once by `brdf_lut.frag`
  (GGX + Smith visibility), so environment specular is
  `prefiltered * (F0 * A + B)` instead of an analytic Fresnel guess.
- Shadow atlas: one 2x2 depth atlas holds up to four shadow-casting lights
  (directional or spot, one tile each); `Light::spot(..., shadow=...)` opts a
  spot in. Each light carries its tile view-projection and tile rect in the
  light SSBO, and PCF clamps to the tile so taps never bleed across lights.
- Non-bindless fallback: `RendererDesc::with_bindless(false)` (or a device
  without descriptor indexing) switches to a PBR shader variant that binds
  albedo/normal per batch; identical output, exercised by example 74.
- `Renderer3D`: forward PBR metallic-roughness with linear-space materials,
  directional/point/spot/ambient/hemisphere lights, one directional PCF shadow
  map (two cascades: an inner half-radius fit at twice the density plus the
  full caster union), GGX-prefiltered (PMREM) environment IBL, HDR `RGBA16F`, separable
  bloom, and ACES tonemapping into `RGBA8Srgb`.
- glTF: `load_gltf` uploads `parse_gltf` meshes and materials, decoding
  embedded images through the RHI (base colour as sRGB, normal maps linear);
  `load_gltf_with_nodes` returns a glTF-node → `NodeId` map and
  `load_gltf_animations` converts TRS channels into `AnimationClip`s
  (examples 77/78).
- HDR environments: `decode_hdr` parses Radiance RGBE (RLE and flat
  scanlines, -Y/+Y and +X/-X), `encode_hdr` writes it, and
  `equirect_environment_cubemap` projects a linear equirect image into the
  GGX-prefiltered **RGBA16F** mip chain, so sun values above 1.0 survive
  (`f16_bits` packs half floats).
- `procedural_environment_cubemap(size=256, samples=128)`: linear sky baked
  into a full GGX mip chain by a GPU prefilter pass (one draw per face per
  mip, read back and uploaded via `create_cubemap_mipmapped`); 512^2 with 256
  samples is supported, and PBR samples
  `textureLod(uEnv, R, roughness * maxLod)` with no `pow(2.2)` approximation.
- Static batch cache: every mesh lives in a shared vertex/index arena, so a
  draw is just a range. Opaque batches upload one indirect command each and a
  single `draw_indexed_indirect_count` issues them all (compute culling fills
  instance counts); the non-bindless fallback keeps per-batch draws because it
  rebinds material textures.
- Distance LOD: `create_lod_node(scene, levels, switch_distances, material)`
  swaps meshes per camera distance, shares one material for instancing, and
  reports `stats.lod_switches` (example 86 selects 48x32 / 20x12 / 8x5 spheres).
- GPU skinning: `MeshData::set_skin` attaches four joint indices/weights per
  vertex (80-byte stream), `Renderer3D::create_skinned_node` binds a joint list
  plus inverse bind matrices, and the vertex shader applies the palette from a
  bone SSBO indexed through the object record; skinned nodes also cast into
  the shadow atlas through a depth-only skinned pipeline (example 79).
- Automatic instancing: visible mesh nodes are grouped by `(mesh, material)`
  and each run is drawn with `draw_indexed(..., instances=n)`. Shaders index
  the object SSBO as `firstObject + gl_InstanceIndex`, so 10k nodes collapse
  into one draw with no per-instance vertex layout.
- Material textures: `Renderer3D::create_texture` uploads RGBA8 (sRGB or
  linear) into a **bindless heap** (descriptor set 1); the material SSBO stores
  albedo/normal slot indices, so switching materials never rebinds samplers.
  Missing maps fall back to 1x1 white / flat-normal slots. Tangents are
  generated on upload, enabling world-space normal mapping, and
  `AlphaMode::Mask` discards against the sampled albedo alpha.
- `GpuMesh`: interleaved P3/N3/UV2/T4 upload from `@tgeo.MeshData` (16-bit indices
  when possible, CPU copy retained for picking).
- `Renderer3D::pick` + `ray_mesh_hit`: frustum-culled, world-space ray picking
  with Moller-Trumbore and normal-matrix-transformed normals.
- `OrbitCamera` / `FlyCamera`: drag-to-orbit, scroll-to-zoom and WASD/QE fly
  controllers that consume `@tycho.Event` and emit camera `Transform`s.
- 4x MSAA: the HDR pass renders into a multisampled `RGBA16F` target and
  resolves into a single-sample target consumed by bloom/tonemap;
  `RendererDesc.msaa=false` selects the single-sampled path.
- HUD composition: `Renderer3D::render_swapchain_into(cmd, sc, ...)` renders
  and blits without ending the frame, so `tycho_2d` can draw a HUD on top with
  `load_op = Load` before the app presents (example 72).
- Transparent pass: `AlphaMode::Blend` nodes are sorted back-to-front by
  camera distance and drawn with a depth-tested, depth-write-disabled pipeline.
- Debug lines: `add_debug_line` / `add_debug_aabb` queue world-space segments
  drawn through a depth-tested `LineList` pipeline after the transparent pass;
  `clear_debug_lines` resets them and `stats().line_segments` reports them.
- glTF 2.0 subset: `@tgeo.parse_gltf` handles base64 data-URI buffers,
  POSITION/NORMAL/TEXCOORD_0, 8/16/32-bit indices, node TRS/matrix hierarchy
  and pbrMetallicRoughness factors; `@t3d.load_gltf` uploads meshes/materials
  and instantiates the hierarchy. Material textures are not resolved yet.
- GPU-driven path (`RendererDesc.gpu_culling`): submits every mesh node, runs
  `cull.comp` per instanced batch (bounding-sphere vs frustum) to compact a
  visible index list and grow a `draw_indexed_indirect` command, then the PBR
  vertex shader remaps `gl_InstanceIndex` through that list. Example 70 shows
  the GPU-culled image is pixel-identical to the CPU-culled one.
- Ergonomics: `create_mesh_node` / `create_pbr_node` (mesh + material + bounds
  in one call), `add_sun` / `add_ambient`, and `set_procedural_environment`
  (renderer-owned PMREM env), which keep showcase apps around 150 lines.
- `RenderStats3D`: counters with `summary()` and `to_json()` for gates.

All pipelines are AOT SPIR-V (`shaders_spv.mbt`, generated by
`tools/compile-embedded-shaders.py`); material parameters travel through an
SSBO, so material count does not create pipelines.

## Usage

```moonbit
let renderer = @t3d.Renderer3D::new(dev)
let scene = @t3d.Scene::new()
let mesh = renderer.upload_mesh(@tgeo.sphere(radius=0.5))
let mat = renderer.create_material(
  @t3d.MaterialDesc::pbr(@t3d.srgb(1.0, 0.6, 0.2), metallic=0.0, roughness=0.4),
)
let node = scene.create_node(
  transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, 0.0, 0.0)),
  payload=@t3d.NodePayload::Mesh(@t3d.MeshInstance::new(mesh, mat)),
)
scene.set_local_bounds(node, renderer.mesh_bounds(mesh))
renderer.render_swapchain(sc, scene, camera_node)
```

See [`examples/62-tycho-3d-showcase`](../examples/62-tycho-3d-showcase).

## Conventions

- Right-handed, +Y up, -Z forward; lights and cameras look down local -Z.
- Linear working space; sRGB only at texture input and output encoding.
- One `Quat` source of truth in `Transform` (no Euler/quaternion dual state).
- Reversed-Z everywhere in the scene pass (`GreaterEqual`, depth clear 0).

## Test

```bash
moon test --target native
../tools/run-3d-gates.sh   # unit tests + examples 61/62 on every ICD
```
