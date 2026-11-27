// Example 75 — full-screen triangle in a flat color, so a presented frame can be
// checked with a single pixel readback from the swapchain back buffer.

struct VsOut {
  float4 color : TEXCOORD0;
  float4 position : SV_Position;
};

VsOut vs_main(uint vertex_id : SV_VertexID) {
  // Covers the whole viewport without a vertex buffer.
  float2 positions[3] = {float2(-1.0, -1.0), float2(3.0, -1.0), float2(-1.0, 3.0)};
  VsOut out_value;
  out_value.color = float4(1.0, 0.5, 0.0, 1.0);
  out_value.position = float4(positions[vertex_id], 0.0, 1.0);
  return out_value;
}

float4 ps_main(float4 color : TEXCOORD0) : SV_Target {
  return color;
}
