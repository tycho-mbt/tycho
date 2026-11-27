// Example 77 — one Slang source, two artifacts (SPIR-V for Vulkan, DXIL for DX12).
//
// The uniform block is declared once: `[[vk::binding(0, 0)]]` places it at
// descriptor set 0 / binding 0 for Vulkan, and `register(b0, space0)` places it
// at root CBV 0 for DX12. That pair is the mapping the RHI relies on: uniform
// slot i == set 0, binding i == root CBV i.

struct Uniforms {
  float4 tint;
};

[[vk::binding(0, 0)]]
ConstantBuffer<Uniforms> ubo : register(b0, space0);

struct VsOut {
  float4 color : TEXCOORD0;
  float4 position : SV_Position;
};

[shader("vertex")]
VsOut vertexMain(uint vertex_id : SV_VertexID) {
  float2 positions[3] = {float2(0.0, -0.5), float2(0.5, 0.5), float2(-0.5, 0.5)};
  VsOut out_value;
  out_value.position = float4(positions[vertex_id], 0.0, 1.0);
  out_value.color = float4(1.0, 1.0, 1.0, 1.0);
  return out_value;
}

[shader("fragment")]
float4 fragmentMain(VsOut input) : SV_Target {
  return ubo.tint;
}
