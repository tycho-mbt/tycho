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
  local transforms (`3d/animation`).
- `AnimationMixer` / `AnimationAction`: any number of clips blended by
  normalized weight (a lone action at weight 0.5 plays its full pose), crossfade,
  `LoopRepeat` / `LoopOnce` / `LoopPingPong`, per-action speed/pause/seek/fade,
  a global time scale, and channels bound to destroyed nodes are skipped.
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
- TAA: `RendererDesc::with_taa(true)` rasterises with an 8-phase Halton
  sub-pixel jitter and resolves against a reprojected history buffer
  (camera-only reprojection, 3x3 neighbourhood clamp, residual guard). Call
  `reset_taa()` after a camera cut. There are no per-object motion vectors yet,
  so fast-moving geometry can ghost (`3d/taa`).
- SSAO: `RendererDesc::with_ssao(true)` reconstructs world positions from the
  single-sample depth buffer (no G-buffer), accumulates a 12-sample rotated
  hemisphere and box-blurs the result; the tonemap pass multiplies it in before
  ACES. SSAO needs a single-sample depth attachment, so enabling it forces MSAA
  off; `set_ssao_intensity(0)` toggles it off at runtime (`3d/ssao`).
- Non-bindless fallback: `RendererDesc::with_bindless(false)` (or a device
  without descriptor indexing) switches to a PBR shader variant that binds
  albedo/normal per batch; identical output, exercised by `3d/brdf-fallback`.
- `Renderer3D`: forward PBR metallic-roughness with linear-space materials,
  directional/point/spot/ambient/hemisphere lights, one directional PCF shadow
  map (two cascades: an inner half-radius fit at twice the density plus the
  full caster union), GGX-prefiltered (PMREM) environment IBL, HDR `RGBA16F`, separable
  bloom, and ACES tonemapping into `RGBA8Srgb`.
- glTF: `load_gltf_instance` uploads `parse_gltf` meshes and materials
  (decoding embedded images through the RHI, base colour as sRGB / normal maps
  linear) and returns one `GltfInstance` aggregating `roots`, the
  glTF-node → `NodeId` map, `meshes`, `materials`, and the `AnimationClip`s
  already bound to the instantiated nodes. `load_gltf` / `load_gltf_with_nodes`
  / `load_gltf_animations` remain as thin specialisations
  (`3d/gltf-viewer` / `3d/gltf-animation`).
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
- Physical clearcoat: `MaterialDesc::with_clearcoat(1.0, roughness=0.2)`
  adds a second GGX lobe in the direct and environment terms (`3d/clearcoat`).
- Physical sheen: `MaterialDesc::with_sheen(color, roughness=...)` adds the
  glTF `KHR_materials_sheen` Charlie/Ashikhmin grazing lobe to the direct and
  environment terms; a zero colour disables it (material SSBO 64 → 80 bytes).
- Screen-space transmission: `MaterialDesc::with_transmission(0.92, ior=1.45)`
  draws the mesh in a second pass against a copy of the already-shaded scene and
  refracts that view by `ior`, so the background is genuinely displaced instead
  of merely alpha-blended (`3d/transmission`). The pass only runs when a
  transmissive object is visible; static meshes only, and it does not use the
  ray-shadow shader variant (material SSBO 80 → 96 bytes).
- Morph targets: `MeshData::add_morph_target` stores up to two position-delta
  sets, `create_morph_node`/`set_morph_weights` animate them through a 72-byte
  stream with per-draw push-constant weights (`3d/morph`).
- Point cube shadows: point lights with a `ShadowDesc` render six faces into a
  4x2 atlas; the fragment shader selects the face from the dominant axis and
  reads the shared tile table (`3d/point-shadow`).
- Ray-traced sun shadows: `set_ray_shadows(true)` swaps in a VK_KHR_ray_query
  fragment variant that traces one shadow ray per pixel against a per-mesh
  BLAS/TLAS (`3d/ray-shadow`; opt-in, no-op without ray query support).
- Distance LOD: `create_lod_node(scene, levels, switch_distances, material)`
  swaps meshes per camera distance, shares one material for instancing, and
  reports `stats.lod_switches` (`3d/lod` selects 48x32 / 20x12 / 8x5 spheres).
- GPU skinning: `MeshData::set_skin` attaches four joint indices/weights per
  vertex (80-byte stream), `Renderer3D::create_skinned_node` binds a joint list
  plus inverse bind matrices, and the vertex shader applies the palette from a
  bone SSBO indexed through the object record; skinned nodes also cast into
  the shadow atlas through a depth-only skinned pipeline (`3d/skinning`).
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
- Picking BVH: `MeshBvh` builds a median-split hierarchy per mesh; `pick` /
  `pick_pixels` lazily build and cache one per uploaded mesh, so a pointer ray
  no longer touches every triangle. `ray_mesh_hit` stays as the brute-force
  reference used by tests.
- Fog: `Renderer3D::set_fog(fog_linear(...))` / `fog_exp2(...)` mix linear or
  exponential-squared distance fog before tone mapping. Fog parameters ride in
  the frame UBO, so toggling fog creates no pipeline variant and applies to
  unlit materials too.
- `OrbitCamera` / `FlyCamera`: drag-to-orbit, scroll-to-zoom and WASD/QE fly
  controllers that consume `@tycho.Event` and emit camera `Transform`s.
- 4x MSAA: the HDR pass renders into a multisampled `RGBA16F` target and
  resolves into a single-sample target consumed by bloom/tonemap;
  `RendererDesc.msaa=false` selects the single-sampled path.
- HUD composition: `Renderer3D::render_swapchain_into(cmd, sc, ...)` renders
  and blits without ending the frame, so `tycho_2d` can draw a HUD on top with
  `load_op = Load` before the app presents (`general/3d-hud`).
- Transparent pass: `AlphaMode::Blend` nodes are sorted back-to-front by
  camera distance and drawn with a depth-tested, depth-write-disabled pipeline.
- Debug lines: `add_debug_line` / `add_debug_aabb` queue world-space segments
  drawn through a depth-tested `LineList` pipeline after the transparent pass;
  `clear_debug_lines` resets them and `stats().line_segments` reports them.
- Line nodes: `upload_lines(@tgeo.LineData)` keeps an edge/wireframe line list
  in local space on the GPU, and `create_line_node(scene, handle, material,
  transform)` draws it through the shared `LineList` pipeline with the node's
  world transform plus a `LineMaterial` colour (push constants). Line nodes are
  frustum-culled and pickable (`LINE_PICK_RADIUS`), but cast no shadows and are
  not ray-tracing geometry.
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
  Skinned/morph nodes come in both flavours: `create_skinned_node` /
  `create_morph_node` allocate a material from a `MaterialDesc`, while
  `create_skinned_mesh_node` / `create_morph_mesh_node` take an existing
  `MaterialHandle` so materials can be shared and freed explicitly.
- Safety: `MeshHandle` / `MaterialHandle` / `TextureHandle` can only be created
  by the renderer (no public `from_id`), so a scene cannot reference a slot the
  renderer never allocated. `Scene::add_camera` returns a typed `CameraId`
  (`Scene::camera_of(node)` validates an existing node), and the render entries
  take it — `render_offscreen(target, scene, camera)` /
  `render_swapchain(sc, scene, camera)` share one target-first argument order.
- Passes: `render_frame` records the shadow atlas, the main opaque/transparent
  pass, the bloom extract/blur pair and the tonemap through `cmd.render_pass(…)`
  scopes, so every pass is closed even when recording fails.
  and cannot be handed a mesh node.
- Typed failures: renderer and scene helpers raise `Render3DError`
  (`InvalidMesh` / `InvalidMaterial` / `InvalidTexture` / `InvalidCamera` /
  `CapacityExceeded` / `Unsupported`) instead of bare `fail(...)` messages.
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

See [`examples/3d/hello`](../examples/3d/hello) for the smallest complete scene
written with this layer, and [`examples/3d/showcase`](../examples/3d/showcase)
for the full PBR showcase.

## three.js-style authoring layer

The renderer keeps the arena + handle core (generation-checked `NodeId`, AOT
pipeline family, SSBO-packed materials), while the authoring surface follows
three.js so a scene reads like the one you would write in JS.

```moonbit
let renderer = @t3d.Renderer3D::new(dev)
let scene = @t3d.Scene::new()

// `new Mesh(geometry, material)` + `scene.add(mesh)` in one call.
let ball = renderer.add(
  scene,
  @tgeo.sphere(radius=0.5),
  @t3d.MaterialDesc::standard(@t3d.hex(0xFF8800), roughness=0.35),
)
scene.set_position(ball, 0.0, 1.0, 0.0)
scene.set_uniform_scale(ball, 0.8)

// Grouping, orientation and inherited visibility.
let pivot = scene.add_group(name="pivot")
let _child = renderer.add(scene, @tgeo.box(), @t3d.MaterialDesc::basic(@t3d.hex(0x88CCFF)), parent=pivot)
scene.look_at(_child, @tmath.Vec3::zero())

// Lights, grid and axes.
let _sun = scene.add_directional_light(
  direction=@tmath.Vec3::new(-0.4, -1.0, -0.3),
  intensity=4.0,
)
let _ambient = scene.add_ambient_light(intensity=0.2)
let _grid = renderer.add_grid(scene, size=20.0, divisions=20)
let _axes = renderer.add_axes(scene, size=1.0)

// Degrees are accepted where three.js uses degrees.
let camera = scene.add_camera(
  @t3d.Camera::perspective_deg(60.0, 800.0 / 600.0, near=0.1),
)

// Frame loop: the platform owns the monotonic timestamp.
let clock = @t3d.Clock::new()
// per frame: let dt = clock.tick(now_seconds)
//            renderer.render_offscreen(target, scene, camera)

// Pointer picking in pixel space (top-left origin, any ClipSpace).
// match renderer.pick_pixels(scene, camera, px, py, 800.0, 600.0) { ... }
```

| three.js | `tycho_3d` |
|---|---|
| `new Scene()` | `Scene::new()` |
| `new Mesh(g, m)` + `scene.add` | `Renderer3D::add(scene, geometry, desc)` |
| `new BoxGeometry(...)` / `SphereGeometry` | `@tgeo.box(...)` / `@tgeo.sphere(...)` |
| `new MeshStandardMaterial({ color: 0xff8800 })` | `MaterialDesc::standard(hex(0xFF8800))` |
| `new MeshBasicMaterial(...)` | `MaterialDesc::basic(...)` |
| `material.transmission = 0.9; material.ior = 1.45` | `MaterialDesc::with_transmission(0.9, ior=1.45)` |
| `SSAOPass` (addon) | `RendererDesc::with_ssao(true)` + `set_ssao_intensity` |
| `TAARenderPass` (addon) | `RendererDesc::with_taa(true)` + `reset_taa` |
| `new Color(0xff8800)` / `setHSL` | `hex(0xFF8800)` / `hsl(deg, s, l)` → linear `Vec4` |
| `mesh.position.set(x, y, z)` | `Scene::set_position(id, v)` / `translate` |
| `mesh.rotation.set(x, y, z)` | `Scene::set_euler(id, x, y, z)` |
| `mesh.scale.setScalar(s)` | `Scene::set_uniform_scale(id, s)` |
| `mesh.lookAt(v)` | `Scene::look_at(id, v)` |
| `parent.add(child)` | `Scene::set_parent(child, Some(parent))` |
| `mesh.removeFromParent()` | `Scene::remove(id)` (stays alive, becomes a root) |
| `object.visible = false` | `Scene::set_visible(id, false)` — inherited by the subtree |
| `new DirectionalLight` / `PointLight` / `SpotLight` | `Scene::add_directional_light` / `add_point_light` / `add_spot_light` |
| `new PerspectiveCamera(60, ...)` | `Camera::perspective_deg(60.0, aspect)` |
| `camera.aspect = w / h` on resize | `scene.set_camera(cam, scene.camera(cam).with_viewport(w, h))` |
| `scene.background = new Color(...)` | `Renderer3D::set_background(hex(...))` / `clear_background()` |
| `scene.fog = new Fog(c, near, far)` | `Renderer3D::set_fog(fog_linear(c, near=..., far=...))` |
| `scene.fog = new FogExp2(c, density)` | `Renderer3D::set_fog(fog_exp2(c, density=...))` |
| `GridHelper` / `AxesHelper` | `Renderer3D::add_grid` / `add_axes` |
| `Raycaster` | `Renderer3D::pick_pixels` (pixels) or `pick` (NDC) |
| `Clock.getDelta()` | `Clock::tick(now_seconds)` |
| `GLTFLoader` | `@tgeo.parse_gltf` + `Renderer3D::load_gltf_instance` |
| `AnimationMixer` / `clipAction` | `AnimationMixer::add` / `action` (`AnimationPlayer` for one clip) |

Design notes:

- `Renderer3D::add` uploads a fresh geometry per call, mirroring
  `new Mesh(new BoxGeometry())`. For a shared mesh (10k instanced nodes), call
  `upload_mesh` / `create_material` once and use `create_mesh_node`; equal
  `(mesh, material)` pairs still collapse into one instanced draw.
- Colors stay linear `Vec3`/`Vec4`; `hex` / `hsl` / `linear` are authoring
  converters only, so there is still one color source of truth.
- `set_background` skips the sky draw and clears the HDR target to a flat
  authoring color; the environment cubemap stays bound for IBL. `clear_background`
  returns to the procedural sky. Fog is applied to geometry only, matching the
  three.js split between `scene.fog` and `scene.background`.
- Every `create_*_node` helper accepts `parent?`, so a mesh / LOD / skinned /
  morph node can join a group in the same call (`create_mesh_node(..., parent=g)`).
- Visibility, frustum collection, light collection and picking all use
  `Scene::is_visible_in_world`, so hiding a group hides its whole subtree.
- LOD / skin / morph registrations are matched by the full generation-checked
  `NodeId` and pruned for dead nodes each frame; `Renderer3D::release_node`
  drops them deterministically before an arena slot is reused.
- `Clock` clamps long frames (`max_delta`, 0.25 s by default) and returns `0` on
  the first tick, so pausing a debugger never teleports animation.

## Conventions

- Right-handed, +Y up, -Z forward; lights and cameras look down local -Z.
- Linear working space; sRGB only at texture input and output encoding.
- One `Quat` source of truth in `Transform` (no Euler/quaternion dual state).
- Reversed-Z everywhere in the scene pass (`GreaterEqual`, depth clear 0).

## Test

```bash
moon test --target native
../tools/run-3d-gates.sh   # unit tests + the 3D examples on every ICD
```
