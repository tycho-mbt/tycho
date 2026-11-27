// Example 83 — push constants, storage buffers and GPU-side draw counts.
//
// Push constants map to root constants at `b15, space0`: Slang would otherwise
// place `[[vk::push_constant]]` at cb0 and collide with uniform slot 0, so the
// register is pinned here and the D3D12 root signature declares the same slot.

struct Push {
  float4 tint;
};

[[vk::push_constant]]
ConstantBuffer<Push> push_data : register(b15, space0);

struct VsOut {
  float4 color : TEXCOORD0;
  float4 position : SV_Position;
};

[shader("vertex")]
VsOut vertexMain(uint vertex_id : SV_VertexID) {
  float2 positions[3] = {float2(-1.0, -1.0), float2(3.0, -1.0), float2(-1.0, 3.0)};
  VsOut out_value;
  out_value.position = float4(positions[vertex_id], 0.0, 1.0);
  out_value.color = push_data.tint;
  return out_value;
}

[shader("fragment")]
float4 fragmentMain(VsOut input) : SV_Target {
  return input.color;
}

// Storage buffer (RWStructuredBuffer): 32-bit floats, one per thread.
[[vk::binding(0, 0)]]
RWStructuredBuffer<float> output_buffer : register(u0, space0);

[shader("compute")]
[numthreads(64, 1, 1)]
void computeMain(uint3 thread_id : SV_DispatchThreadID) {
  output_buffer[thread_id.x] = float(thread_id.x) * 2.0;
}
