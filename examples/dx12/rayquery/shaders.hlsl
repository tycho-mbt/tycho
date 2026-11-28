// Inline ray query (DXR Tier 1.1, SM 6.5) compute shader.
// Traces a primary ray per pixel against the TLAS at t0 and writes green on
// triangle hit, blue on miss into the 64x64 RWTexture2D at u0.

RaytracingAccelerationStructure scene : register(t0, space0);
RWTexture2D<float4> outTex : register(u0, space0);

[numthreads(8, 8, 1)]
void cs_main(uint3 tid : SV_DispatchThreadID) {
  if (tid.x >= 64 || tid.y >= 64) {
    return;
  }
  float2 uv = (float2(tid.xy) + 0.5) / 64.0 * 2.0 - 1.0;

  RayDesc ray;
  ray.Origin = float3(uv.x, -uv.y, -1.0);
  ray.Direction = float3(0.0, 0.0, 1.0);
  ray.TMin = 0.001;
  ray.TMax = 10.0;

  RayQuery<RAY_FLAG_FORCE_OPAQUE> q;
  q.TraceRayInline(scene, RAY_FLAG_NONE, 0xFF, ray);
  q.Proceed();

  if (q.CommittedStatus() == COMMITTED_TRIANGLE_HIT) {
    outTex[tid.xy] = float4(0.0, 1.0, 0.0, 1.0);
  } else {
    outTex[tid.xy] = float4(0.0, 0.0, 1.0, 1.0);
  }
}
