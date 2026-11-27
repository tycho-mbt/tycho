// Example 74 — one HLSL source, two entry points, compiled to DXIL by dxc.
// The vertex shader generates its triangle from SV_VertexID (no vertex buffer)
// and passes per-vertex colors so the readback can assert three distinct regions.

// Declaration order matters: the vertex-stage output registers are packed in
// field order, while pixel-stage input registers always start at 0, so the
// inter-stage semantic has to be declared before SV_Position (which lives in
// the POS register class) for the two signatures to line up.
struct VsOut {
  float4 color : TEXCOORD0;
  float4 position : SV_Position;
};

VsOut vs_main(uint vertex_id : SV_VertexID) {
  float2 positions[3] = {float2(0.0, -0.5), float2(0.5, 0.5), float2(-0.5, 0.5)};
  float4 colors[3] = {float4(1.0, 0.0, 0.0, 1.0), float4(0.0, 1.0, 0.0, 1.0),
                      float4(0.0, 0.0, 1.0, 1.0)};
  VsOut out_value;
  out_value.position = float4(positions[vertex_id], 0.0, 1.0);
  out_value.color = colors[vertex_id];
  return out_value;
}

float4 ps_main(float4 color : TEXCOORD0) : SV_Target {
  return color;
}
