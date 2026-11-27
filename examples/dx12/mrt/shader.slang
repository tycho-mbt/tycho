// Example 84 — two texture slots and two render targets (MRT) on DX12.
//
// Slot 0 and slot 1 sample different textures; the fragment writes them to two
// targets, the second of which is an sRGB format so the stored bytes differ from
// the linear target.

[[vk::binding(0, 0)]]
Texture2D<float4> texture_a : register(t0, space0);

[[vk::binding(1, 0)]]
Texture2D<float4> texture_b : register(t1, space0);

[[vk::binding(2, 0)]]
SamplerState linear_sampler : register(s0, space0);

struct VsOut {
  float2 uv : TEXCOORD0;
  float4 position : SV_Position;
};

[shader("vertex")]
VsOut vertexMain(uint vertex_id : SV_VertexID) {
  float2 positions[3] = {float2(-1.0, -1.0), float2(3.0, -1.0), float2(-1.0, 3.0)};
  VsOut out_value;
  out_value.position = float4(positions[vertex_id], 0.0, 1.0);
  out_value.uv = positions[vertex_id] * 0.5 + 0.5;
  return out_value;
}

struct PsOut {
  float4 target0 : SV_Target0;
  float4 target1 : SV_Target1;
};

[shader("fragment")]
PsOut fragmentMain(VsOut input) {
  PsOut out_value;
  out_value.target0 = texture_a.Sample(linear_sampler, input.uv);
  out_value.target1 = texture_b.Sample(linear_sampler, input.uv);
  return out_value;
}
