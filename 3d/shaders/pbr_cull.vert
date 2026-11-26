#version 450
// PBR vertex shader for GPU-culled batches: the instance index is remapped
// through the compacted visibility list written by `cull.comp`.
layout(location = 0) in vec3 inPos;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec2 inUV;
layout(location = 3) in vec4 inTangent;

layout(binding = 0) uniform FrameUBO {
    mat4 viewProj;
    mat4 lightVP0;
    mat4 lightVP1;
    vec4 camPos;
    vec4 params;
    vec4 cascade;
} frame;

struct ObjectGpu {
    mat4 model;
    mat4 normalMat;
    float c0;
    float c1;
    float c2;
    float radius;
};
layout(std430, binding = 1) readonly buffer ObjectBuf { ObjectGpu objects[]; };
layout(std430, binding = 8) readonly buffer VisBuf { uint visible[]; };

layout(push_constant) uniform PC {
    vec4 params; // firstObject, materialIndex, listOffset, unused
} pc;

layout(location = 0) out vec3 vWorldPos;
layout(location = 1) out vec3 vNormal;
layout(location = 2) out vec2 vUV;
layout(location = 3) out vec4 vTangent;

void main() {
    uint first = uint(pc.params.x + 0.5);
    uint list_offset = uint(pc.params.z + 0.5);
    uint inst = visible[list_offset + uint(gl_InstanceIndex)];
    ObjectGpu o = objects[first + inst];
    vec4 wp = o.model * vec4(inPos, 1.0);
    vWorldPos = wp.xyz;
    vNormal = mat3(o.normalMat) * inNormal;
    vUV = inUV;
    vTangent = vec4(mat3(o.normalMat) * inTangent.xyz, inTangent.w);
    gl_Position = frame.viewProj * wp;
}
