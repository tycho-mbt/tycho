// Example 81 — real vertex and index buffers on the DX12 backend.
//
// Attributes come from the vertex buffer instead of SV_VertexID: location 0 is a
// float3 position, location 1 a float4 colour, which the RHI maps to
// TEXCOORD0 / TEXCOORD1 in the D3D12 input layout.

struct VsIn {
  float3 position : TEXCOORD0;
  float4 color : TEXCOORD1;
};

struct VsOut {
  float4 color : TEXCOORD0;
  float4 position : SV_Position;
};

[shader("vertex")]
VsOut vertexMain(VsIn input) {
  VsOut out_value;
  out_value.position = float4(input.position, 1.0);
  out_value.color = input.color;
  return out_value;
}

[shader("fragment")]
float4 fragmentMain(VsOut input) : SV_Target {
  return input.color;
}
