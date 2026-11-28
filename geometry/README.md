# `laplaceliu/tycho_geometry`

Zero-dependency pure-MoonBit **mesh data, parametric primitive generators, and
geometry-only format IO**, built on `laplaceliu/tycho_math` and nothing else.

This module is the CPU content layer of the Tycho graphics stack (see
[ADR-003](../../roadmap/adr-003-standalone-geometry-module.md)):

- **No GPU / RHI dependency** — compiles on `native`, `wasm`, and `js`, and all
  tests run headless.
- **Mesh data** — `MeshData` with a fixed canonical layout: `positions`,
  `normals`, `uvs`, `indices`, plus optional `tangents` / vertex `colors`,
  skinning and multi-material `groups`. The fields are private; read them with
  `positions()` / `normals()` / `uvs()` / `indices()` / `tangents()` /
  `colors()` / `skin_joints()` / `skin_weights()` / `morph_targets()` /
  `groups()`, and replace the length-coupled arrays through the validated
  setters `set_normals` / `set_tangents` / `set_colors` / `add_group`, which
  reject anything that breaks the vertex-count or index-range invariant.
- **Line data** — `LineData` for segment lists (`positions` + paired
  `indices`), plus `edges` (boundary + crease edges by dihedral angle, like
  `EdgesGeometry`) and `wireframe` (every unique triangle edge).
- **Generators** — `box`, `plane`, `circle`, `ring`, `sphere`, `cylinder`,
  `cone`, `capsule`, `torus`, `torus_knot`, the polyhedron family
  (`polyhedron` + `tetrahedron` / `octahedron` / `dodecahedron` /
  `icosahedron`, with `detail` subdivision), `lathe`, and `tube` (a
  `catmull_rom_chain` helper turns control points into a tube path).
  `circle` / `ring` accept `theta_start` / `theta_length` (sectors) and
  `ring` a `phi_segments` radial split.
- **Shapes** — `Shape2D` (outer contour + holes, polylines only), `shape` /
  `shapes` (flat ear-cut triangulation), and `extrude` / `extrude_shapes`
  (lids + walls, either along `depth` or along a sampled `extrude_path`,
  with an optional three.js-style bevel: `bevel_enabled` / `bevel_thickness` /
  `bevel_size` / `bevel_offset` / `bevel_segments`; opt-in unlike three.js and
  ignored on path extrusion). The ear-cut kernel is a pure-MoonBit port of
  mapbox/earcut and lives in `earcut.mbt`.
- **Operations** — `bounds`, `compute_vertex_normals`, `compute_tangents`,
  `transformed`, `merge`, `to_non_indexed`, `flipped`; `LineData` mirrors
  `bounds` / `transformed` / `merge` / `to_non_indexed`.
- **Typed errors** — `GeometryError` (`InvalidMesh` / `InvalidGltf` /
  `UnsupportedExtension`) instead of bare `fail(...)`, so callers can
  distinguish a bad mesh, a bad document and a document that needs a decoder
  this build does not ship.
- **IO** — `parse_obj` / `parse_obj_text` (v/vt/vn, polygons, `o`/`g` parts,
  positive and negative indices), `parse_gltf` (glTF 2.0 JSON with embedded
  base64 buffers) and `parse_glb` (the same documents delivered as a binary
  container: 12-byte header, JSON chunk, BIN chunk backing buffer 0, images in
  buffer views instead of `data:` URIs). Both entry points cover
  POSITION/NORMAL/TEXCOORD_0, sparse accessors, TRS/matrix nodes, and node TRS
  animation channels with LINEAR/STEP/CUBICSPLINE samplers. Materials carry
  base colour, emissive, normal and metallic-roughness texture references plus
  the extensions `tycho_3d` can render: `KHR_materials_transmission`,
  `KHR_materials_ior`, `KHR_materials_iridescence` (the thickness range's
  midpoint, since the thickness texture is not sampled yet),
  `KHR_materials_clearcoat` and `KHR_materials_emissive_strength`.
  Compressed assets are rejected instead of silently mis-parsed: any
  `extensionsRequired` entry the loader does not implement (for example
  `KHR_draco_mesh_compression`, `EXT_meshopt_compression`,
  `KHR_texture_basisu`) raises `UnsupportedExtension(name)`, and the same check
  runs per primitive in case the exporter forgot the top-level declaration.
  `extensionsUsed` alone is informational and never blocks loading.

## Conventions

- Right-handed, +Y up, -Z forward.
- **CCW is the front face** (`tycho_3d` always sets `FrontFace::CounterClockwise`).
- UV `(0, 0)` is the **top-left** of the image (glTF / Vulkan convention).
- Units are meters; default primitive size is 1.
- `MeshData` indices are always 32-bit; renderers may narrow to 16-bit on upload.

## Usage

```moonbit
let cube = @tgeo.box(width=1.0, height=1.0, depth=1.0)
let ball = @tgeo.sphere(radius=0.5, width_segments=32, height_segments=16)
let parts = @tgeo.parse_obj_text(text) // Array[(String, MeshData)]

// 2D shape -> flat mesh / solid / wireframe
let square = @tgeo.Shape2D::new([
  @tmath.Vec2::new(-0.5, -0.5), @tmath.Vec2::new(0.5, -0.5),
  @tmath.Vec2::new(0.5, 0.5), @tmath.Vec2::new(-0.5, 0.5),
])
let flat = @tgeo.shape(square)
let solid = @tgeo.extrude(square, options=@tgeo.ExtrudeOptions::new(depth=0.4))
let outline = @tgeo.edges(solid)   // LineData
```

GPU residency (`GpuMesh`) and everything scene/material-related live in
`laplaceliu/tycho_3d`, not here.

## Test

```bash
moon test --target native
```
