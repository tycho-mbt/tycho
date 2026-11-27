// Example 79 — sampled texture on the DX12 backend. One SRV descriptor table
// (t0, space 0) plus the root signature's static sampler (s0, linear/clamp).

[[vk::binding(0, 0)]]
Texture2D<float4> albedo : register(t0, space0);

[[vk::binding(1, 0)]]
SamplerState linear_sampler : register(s0, space0);

struct VsOut {
  float2 uv : TEXCOORD0;
  float4 position : SV_Position;
};

// Full-screen triangle: uv covers the viewport so the whole 2x2 texture is
// visible as four quadrants.
[shader("vertex")]
VsOut vertexMain(uint vertex_id : SV_VertexID) {
  float2 positions[3] = {float2(-1.0, -1.0), float2(3.0, -1.0), float2(-1.0, 3.0)};
  VsOut out_value;
  out_value.position = float4(positions[vertex_id], 0.0, 1.0);
  out_value.uv = positions[vertex_id] * 0.5 + 0.5;
  return out_value;
}

[shader("fragment")]
float4 fragmentMain(VsOut input) : SV_Target {
  return albedo.Sample(linear_sampler, input.uv);
}
