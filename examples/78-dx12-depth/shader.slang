// Example 78 — depth test on the DX12 backend. The uniform block carries both the
// tint and the clip-space depth, so one pipeline can draw the same triangle at
// two different z values with two UBOs.

struct Uniforms {
  float4 tint;
  float z;
  float3 pad;
};

[[vk::binding(0, 0)]]
ConstantBuffer<Uniforms> ubo : register(b0, space0);

struct VsOut {
  float4 color : TEXCOORD0;
  float4 position : SV_Position;
};

[shader("vertex")]
VsOut vertexMain(uint vertex_id : SV_VertexID) {
  float2 positions[3] = {float2(-0.9, -0.9), float2(0.9, -0.9), float2(0.0, 0.9)};
  VsOut out_value;
  out_value.position = float4(positions[vertex_id], ubo.z, 1.0);
  out_value.color = ubo.tint;
  return out_value;
}

[shader("fragment")]
float4 fragmentMain(VsOut input) : SV_Target {
  return input.color;
}
