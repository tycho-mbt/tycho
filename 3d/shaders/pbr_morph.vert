#version 450
// Morph-target PBR vertex shader: up to two additive position deltas with
// weights supplied per draw through a push constant.
layout(location = 0) in vec3 inPos;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec2 inUV;
layout(location = 3) in vec4 inTangent;
layout(location = 6) in vec3 inMorph0;
layout(location = 7) in vec3 inMorph1;

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
    vec4 bounds;
    vec4 extra; // x material, y/z/w skinning
};
layout(std430, binding = 1) readonly buffer ObjectBuf { ObjectGpu objects[]; };

layout(push_constant) uniform PC { vec4 weights; } pc;

layout(location = 0) out vec3 vWorldPos;
layout(location = 1) out vec3 vNormal;
layout(location = 2) out vec2 vUV;
layout(location = 3) out vec4 vTangent;
layout(location = 4) flat out float vMaterial;

void main() {
    ObjectGpu o = objects[gl_InstanceIndex];
    vec3 lp = inPos + pc.weights.x * inMorph0 + pc.weights.y * inMorph1;
    vec4 wp = o.model * vec4(lp, 1.0);
    vec3 nrm = mat3(o.normalMat) * inNormal;
    vWorldPos = wp.xyz;
    vNormal = nrm;
    vUV = inUV;
    vTangent = vec4(mat3(o.normalMat) * inTangent.xyz, inTangent.w);
    vMaterial = o.extra.x;
    gl_Position = frame.viewProj * wp;
}
