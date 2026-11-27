// Example 80 — compute on the DX12 backend: one UAV (RWTexture2D), one dispatch.
// The shader writes a red/green gradient into the storage texture so the readback
// can check both the UAV descriptor table and the dispatch id mapping.

[[vk::binding(0, 0)]]
RWTexture2D<float4> output_texture : register(u0, space0);

[shader("compute")]
[numthreads(8, 8, 1)]
void computeMain(uint3 thread_id : SV_DispatchThreadID) {
  float2 uv = float2(thread_id.xy) / 64.0;
  output_texture[thread_id.xy] = float4(uv.x, uv.y, 0.5, 1.0);
}
