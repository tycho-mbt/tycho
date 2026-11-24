# 48-rhi-shadow-hdr

End-to-end 3D shadow-mapping and HDR tone-mapping verification using `@tycho`:

- Loads `examples/assets/scene.obj` in pure MoonBit (`v`/`vt`/`vn`/`f`)
- Loads `examples/assets/checker16.bmp` via `@tycho.load_image` into layer 0 of a `Texture2DArray`
- Patches layer 1 via `Texture::upload_subregion(4, 4, 8, 8, ...)`
- **Pass 1**: Depth-only shadow map into `Depth24Stencil8` (`depth_only=true`, `depth_bias=true`)
- **Pass 2**: HDR lighting into `RGBA16F` + `Depth32F` sampling `sampler2DShadow` with `ClampToBorder(OpaqueWhite)` + `CompareOp::LessEqual`
- **Pass 3**: Reinhard tone mapping into `RGBA8Srgb` with strict pixel assertions for shadowed, lit, out-of-frustum border, and subregion-textured occluder probes
