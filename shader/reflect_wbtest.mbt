// Whitebox tests for the pure-MoonBit SPIR-V reflector (compiling live GLSL via glslangValidator).

#borrow(suffix)
extern "c" fn temp_path_ffi(suffix : Bytes, len : Int32) -> Bytes = "tycho_shader_temp_path"

///|
/// Unique path in the platform temp directory ("TMPDIR", then "TEMP"/"TMP" on
/// Windows). Tests must not hardcode "/tmp": it does not exist on Windows, so
/// save_png would fail to open the file there.
fn temp_path(suffix : String) -> String {
  let s = @utf8.encode(suffix)
  @utf8.decode_lossy(temp_path_ffi(s, s.length())[:])
}

///|
test "reflect vertex and mrt fragment shaders" {
  let vert_src =
    #|#version 450
    #|layout(push_constant) uniform Push {
    #|  mat4 mvp;
    #|  vec4 tint;
    #|} pc;
    #|layout(binding = 0) uniform UBO { mat4 view; } ubo;
    #|layout(location = 0) in vec3 inPos;
    #|layout(location = 1) in vec2 inUV;
    #|layout(location = 2) in vec4 inColor;
    #|layout(location = 0) out vec2 outUV;
    #|void main() {
    #|  gl_Position = ubo.view * pc.mvp * vec4(inPos, 1.0) + pc.tint;
    #|  outUV = inUV + inColor.xy;
    #|}
  let vert_spv = compile_shader(vert_src, SHADER_KIND_VERTEX)
  let vr = reflect_spirv(vert_spv)
  assert_eq(vr.stage, ReflectedStage::Vertex)
  assert_eq(vr.entry_point, "main")
  assert_eq(vr.push_constant_size, 80)
  assert_eq(vr.vertex_inputs.length(), 3)
  assert_eq(vr.vertex_inputs[0].location, 0)
  assert_eq(vr.vertex_inputs[0].format, ReflectedVertexFormat::Float3)
  assert_eq(vr.vertex_inputs[1].location, 1)
  assert_eq(vr.vertex_inputs[1].format, ReflectedVertexFormat::Float2)
  assert_eq(vr.vertex_inputs[2].location, 2)
  assert_eq(vr.vertex_inputs[2].format, ReflectedVertexFormat::Float4)
  assert_eq(vr.bindings.length(), 1)
  assert_eq(vr.bindings[0].binding, 0)
  assert_eq(vr.bindings[0].kind, ReflectedDescriptorKind::UniformBuffer)

  let frag_src =
    #|#version 450
    #|layout(binding = 1) uniform sampler2D albedoTex;
    #|layout(location = 0) in vec2 inUV;
    #|layout(location = 0) out vec4 outAlbedo;
    #|layout(location = 1) out vec4 outNormal;
    #|void main() {
    #|  outAlbedo = texture(albedoTex, inUV);
    #|  outNormal = vec4(0.5, 0.5, 1.0, 1.0);
    #|}
  let frag_spv = compile_shader(frag_src, SHADER_KIND_FRAGMENT)
  let fr = reflect_spirv(frag_spv)
  assert_eq(fr.stage, ReflectedStage::Fragment)
  assert_eq(fr.color_output_count, 2)
  assert_eq(fr.bindings.length(), 1)
  assert_eq(fr.bindings[0].binding, 1)
  assert_eq(fr.bindings[0].kind, ReflectedDescriptorKind::CombinedImageSampler)
}

///|
test "reflect compute shader with storage buffer and storage image" {
  let comp_src =
    #|#version 450
    #|layout(local_size_x = 8, local_size_y = 8) in;
    #|layout(push_constant) uniform Params { vec4 scale; } p;
    #|layout(binding = 0) buffer Data { float vals[]; } buf;
    #|layout(binding = 1, rgba8) uniform writeonly image2D outImg;
    #|void main() {
    #|  ivec2 xy = ivec2(gl_GlobalInvocationID.xy);
    #|  buf.vals[xy.x] = p.scale.x;
    #|  imageStore(outImg, xy, p.scale);
    #|}
  let comp_spv = compile_shader(comp_src, SHADER_KIND_COMPUTE)
  let cr = reflect_spirv(comp_spv)
  assert_eq(cr.stage, ReflectedStage::Compute)
  assert_eq(cr.local_size, (8, 8, 1))
  assert_eq(cr.push_constant_size, 16)
  assert_eq(cr.bindings.length(), 2)
  assert_eq(cr.bindings[0].binding, 0)
  assert_eq(cr.bindings[0].count, 1)
  assert_eq(cr.bindings[0].kind, ReflectedDescriptorKind::StorageBuffer)
  assert_eq(cr.bindings[1].binding, 1)
  assert_eq(cr.bindings[1].kind, ReflectedDescriptorKind::StorageImage)
}

///|
test "reflect multi-set, descriptor arrays, and separate texture/sampler" {
  let frag_src =
    #|#version 450
    #|layout(set = 0, binding = 0) uniform texture2D texArr[4];
    #|layout(set = 1, binding = 2) uniform sampler samp;
    #|layout(location = 0) in vec2 vUV;
    #|layout(location = 0) out vec4 outColor;
    #|void main() {
    #|  outColor = texture(sampler2D(texArr[1], samp), vUV);
    #|}
  let spv = compile_shader(frag_src, SHADER_KIND_FRAGMENT)
  let r = reflect_spirv(spv)
  assert_eq(r.bindings.length(), 2)
  assert_eq(r.bindings[0].set, 0)
  assert_eq(r.bindings[0].binding, 0)
  assert_eq(r.bindings[0].count, 4)
  assert_eq(r.bindings[0].kind, ReflectedDescriptorKind::SampledImage)
  assert_eq(r.bindings[1].set, 1)
  assert_eq(r.bindings[1].binding, 2)
  assert_eq(r.bindings[1].count, 1)
  assert_eq(r.bindings[1].kind, ReflectedDescriptorKind::Sampler)
}

///|
test "load_image 24-bit padded BMP, 32-bit top-down BMP, 32-bit TGA, and P6 PPM" {
  // 1. 5x3 24-bit bottom-up BMP (15-byte row + 1-byte padding = 16-byte stride)
  let (bmp24, w1, h1) = load_image("shader/testdata/test_5x3_24bit.bmp")
  assert_eq(w1, 5)
  assert_eq(h1, 3)
  assert_eq(bmp24.length(), 5 * 3 * 4)
  for y = 0; y < 3; y = y + 1 {
    for x = 0; x < 5; x = x + 1 {
      let i = (y * 5 + x) * 4
      assert_eq(bmp24[i].to_int(), 10 + x * 40)
      assert_eq(bmp24[i + 1].to_int(), 20 + y * 60)
      assert_eq(bmp24[i + 2].to_int(), 30 + x * 25 + y * 30)
      assert_eq(bmp24[i + 3].to_int(), 255)
    }
  }

  // 2. 4x2 32-bit top-down BMP with non-255 alpha
  let (bmp32, w2, h2) = load_image("shader/testdata/test_4x2_32bit_topdown.bmp")
  assert_eq(w2, 4)
  assert_eq(h2, 2)
  let expected_4x2 : Array[Int] = [
    255, 0, 0, 255, 0, 255, 0, 128, 0, 0, 255, 64, 200, 150, 100, 10,
    12, 34, 56, 200, 78, 90, 123, 255, 250, 240, 230, 50, 0, 0, 0, 0,
  ]
  assert_eq(bmp32.length(), expected_4x2.length())
  for i = 0; i < expected_4x2.length(); i = i + 1 {
    assert_eq(bmp32[i].to_int(), expected_4x2[i])
  }

  // 3. 3x2 32-bit bottom-up TGA
  let (tga, w3, h3) = load_image("shader/testdata/test_3x2_32bit.tga")
  assert_eq(w3, 3)
  assert_eq(h3, 2)
  let expected_3x2 : Array[Int] = [
    255, 10, 20, 255, 30, 255, 40, 180, 50, 60, 255, 90,
    11, 22, 33, 44, 55, 66, 77, 88, 99, 110, 121, 132,
  ]
  assert_eq(tga.length(), expected_3x2.length())
  for i = 0; i < expected_3x2.length(); i = i + 1 {
    assert_eq(tga[i].to_int(), expected_3x2[i])
  }

  // 4. 2x2 P6 PPM
  let (ppm, w4, h4) = load_image("shader/testdata/test_2x2.ppm")
  assert_eq(w4, 2)
  assert_eq(h4, 2)
  let expected_2x2 : Array[Int] = [
    255, 0, 0, 255, 0, 255, 0, 255,
    0, 0, 255, 255, 255, 255, 0, 255,
  ]
  for i = 0; i < expected_2x2.length(); i = i + 1 {
    assert_eq(ppm[i].to_int(), expected_2x2[i])
  }
}

///|
test "compile_shader disk cache hits identically and separates stages" {
  let src =
    #|#version 450
    #|layout(location = 0) out vec4 outColor;
    #|void main() { outColor = vec4(0.25, 0.5, 0.75, 1.0); }
  let spv1 = compile_shader(src, SHADER_KIND_FRAGMENT)
  let spv2 = compile_shader(src, SHADER_KIND_FRAGMENT)
  assert_true(spv1.length() > 5)
  assert_eq(spv1.length(), spv2.length())
  for i = 0; i < spv1.length(); i = i + 1 {
    assert_eq(spv1[i], spv2[i])
  }
  let vsrc =
    #|#version 450
    #|void main() { gl_Position = vec4(0.0, 0.0, 0.0, 1.0); }
  let vspv = compile_shader(vsrc, SHADER_KIND_VERTEX)
  assert_eq(reflect_spirv(vspv).stage, ReflectedStage::Vertex)
  assert_eq(reflect_spirv(spv2).stage, ReflectedStage::Fragment)
}

///|
test "load_hdr_image decodes Radiance RGBE floats accurately" {
  let (hdr, w, h) = load_hdr_image("shader/testdata/test_2x2.hdr")
  assert_eq(w, 2)
  assert_eq(h, 2)
  assert_eq(hdr.length(), 16)
  // Pixel 0: (4.0, 0, 0, 1.0)
  assert_true(hdr[0] > (3.9 : Float) && hdr[0] < (4.1 : Float))
  assert_eq(hdr[1], (0.0 : Float))
  assert_eq(hdr[3], (1.0 : Float))
  // Pixel 1: (0, 2.0, 0, 1.0)
  assert_true(hdr[5] > (1.9 : Float) && hdr[5] < (2.1 : Float))
  // Pixel 2: (0, 0, 8.0, 1.0)
  assert_true(hdr[10] > (7.8 : Float) && hdr[10] < (8.2 : Float))
  // Pixel 3: (1.0, 1.0, 1.0, 1.0)
  assert_true(hdr[12] > (0.95 : Float) && hdr[12] < (1.05 : Float))
  assert_true(hdr[13] > (0.95 : Float) && hdr[13] < (1.05 : Float))
  assert_true(hdr[14] > (0.95 : Float) && hdr[14] < (1.05 : Float))
}

///|
test "save_png compresses and stays pixel-exact" {
  let w = 64
  let h = 64
  // A per-row gradient: highly filterable, so a real deflate stream has to land
  // far below the raw pixel size.
  let rgba : FixedArray[Byte] = FixedArray::make(w * h * 4, (0 : Byte))
  for y = 0; y < h; y = y + 1 {
    for x = 0; x < w; x = x + 1 {
      let i = (y * w + x) * 4
      rgba[i] = (x * 4).to_byte()
      rgba[i + 1] = (y * 4).to_byte()
      rgba[i + 2] = (40 : Byte)
      rgba[i + 3] = (255 : Byte)
    }
  }
  let path = temp_path(".png")
  assert_true(save_png(path, w, h, rgba))
  let bytes = read_file_bytes(path)
  assert_true(bytes.length() > 0)
  // The previous writer emitted stored blocks, which made this exactly
  // w*h*4 + ~400 bytes; require a quarter of the raw size to catch a regression.
  assert_true(bytes.length() < w * h * 4 / 4)
  match decode_image(bytes) {
    Some((px, dw, dh)) => {
      assert_eq(dw, w)
      assert_eq(dh, h)
      let mid = ((h / 2) * w + w / 2) * 4
      assert_eq(px[mid].to_int(), (w / 2) * 4)
      assert_eq(px[mid + 1].to_int(), (h / 2) * 4)
      assert_eq(px[mid + 2].to_int(), 40)
      assert_eq(px[mid + 3].to_int(), 255)
    }
    None => assert_true(false)
  }
}

test "save_png swaps bgra into rgba" {
  let w = 2
  let h = 2
  let px : FixedArray[Byte] = FixedArray::make(w * h * 4, (0 : Byte))
  for i = 0; i < w * h; i = i + 1 {
    px[i * 4] = (200 : Byte) // B
    px[i * 4 + 1] = (100 : Byte) // G
    px[i * 4 + 2] = (50 : Byte) // R
    px[i * 4 + 3] = (255 : Byte)
  }
  let path = temp_path(".png")
  assert_true(save_png(path, w, h, px, bgra=true))
  match decode_image(read_file_bytes(path)) {
    Some((out, _, _)) => {
      assert_eq(out[0].to_int(), 50)
      assert_eq(out[1].to_int(), 100)
      assert_eq(out[2].to_int(), 200)
    }
    None => assert_true(false)
  }
}

test "decode_image roundtrips png" {
  let w = 3
  let h = 2
  let rgba : FixedArray[Byte] = FixedArray::make(w * h * 4, (0 : Byte))
  rgba[0] = (255 : Byte)
  rgba[1] = (128 : Byte)
  rgba[2] = (64 : Byte)
  rgba[3] = (200 : Byte)
  rgba[4] = (10 : Byte)
  rgba[5] = (20 : Byte)
  rgba[6] = (30 : Byte)
  rgba[7] = (255 : Byte)
  let path = temp_path(".png")
  assert_true(save_png(path, w, h, rgba))
  let bytes = read_file_bytes(path)
  assert_true(bytes.length() > 0)
  match decode_image(bytes) {
    Some((px, dw, dh)) => {
      assert_eq(dw, w)
      assert_eq(dh, h)
      assert_eq(px[0].to_int(), 255)
      assert_eq(px[1].to_int(), 128)
      assert_eq(px[2].to_int(), 64)
      assert_eq(px[4].to_int(), 10)
    }
    None => assert_true(false)
  }
}
