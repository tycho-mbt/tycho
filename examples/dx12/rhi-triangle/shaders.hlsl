// Example 76 — the RHI on the DX12 backend. Same triangle as the Vulkan RHI
// example: positions from SV_VertexID, per-vertex colors so the readback can
// assert three distinct regions.

struct VsOut {
  float4 color : TEXCOORD0;
  float4 position : SV_Position;
};

VsOut vs_main(uint vertex_id : SV_VertexID) {
  float2 positions[3] = {float2(0.0, -0.5), float2(0.5, 0.5), float2(-0.5, 0.5)};
  float4 colors[3] = {float4(1.0, 0.0, 0.0, 1.0), float4(0.0, 1.0, 0.0, 1.0),
                      float4(0.0, 0.0, 1.0, 1.0)};
  VsOut out_value;
  out_value.color = colors[vertex_id];
  out_value.position = float4(positions[vertex_id], 0.0, 1.0);
  return out_value;
}

float4 ps_main(float4 color : TEXCOORD0) : SV_Target {
  return color;
}
