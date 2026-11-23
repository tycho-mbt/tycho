// Whitebox tests for the pure-MoonBit SPIR-V reflector (compiling live GLSL via glslangValidator).

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
  assert_eq(cr.push_constant_size, 16)
  assert_eq(cr.bindings.length(), 2)
  assert_eq(cr.bindings[0].binding, 0)
  assert_eq(cr.bindings[0].kind, ReflectedDescriptorKind::StorageBuffer)
  assert_eq(cr.bindings[1].binding, 1)
  assert_eq(cr.bindings[1].kind, ReflectedDescriptorKind::StorageImage)
}
