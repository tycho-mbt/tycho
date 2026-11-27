// Example 85 — mesh shader pipeline on DX12.
//
// The mesh shader generates all three vertices itself, so the pipeline carries no
// input layout and no vertex buffer: `DispatchMesh(1,1,1)` launches one workgroup
// that writes one triangle.
//
// Note the parameter syntax: Slang adds `out` itself when lowering to HLSL, so
// writing `out vertices` here makes dxc reject the duplicated usage
// ("duplicate HLSL parameter usages 'out'"). Slang only warns about the missing
// keyword here and emits a correct signature.

struct MeshOut {
  float4 position : SV_Position;
  float4 color : TEXCOORD0;
};

[shader("mesh")]
[outputtopology("triangle")]
[numthreads(3, 1, 1)]
void meshMain(vertices MeshOut output_vertices[3], indices uint3 output_triangles[1]) {
  SetMeshOutputCounts(3, 1);
  float2 positions[3] = {float2(0.0, -0.8), float2(0.8, 0.8), float2(-0.8, 0.8)};
  float4 colors[3] = {
    float4(1.0, 0.0, 0.0, 1.0),
    float4(0.0, 1.0, 0.0, 1.0),
    float4(0.0, 0.0, 1.0, 1.0),
  };
  for (uint i = 0; i < 3; i++) {
    output_vertices[i].position = float4(positions[i], 0.0, 1.0);
    output_vertices[i].color = colors[i];
  }
  output_triangles[0] = uint3(0, 1, 2);
}

[shader("fragment")]
float4 fragmentMain(MeshOut input) : SV_Target {
  return input.color;
}
