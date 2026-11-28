#version 450
layout(location = 0) in vec3 inPos;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec2 inUV;
layout(location = 3) in vec4 inTangent;

layout(binding = 0) uniform FrameUBO {
    mat4 viewProj;
    mat4 lightVP;
    vec4 camPos;
    vec4 params;
} frame;

struct ObjectGpu {
    mat4 model;
    mat4 normalMat;
    vec4 bounds; // xyz local centre, w radius
    vec4 extra;  // x material index
    vec4 tint;   // per-instance base-colour multiplier
};
layout(std430, binding = 1) readonly buffer ObjectBuf { ObjectGpu objects[]; };

layout(location = 0) out vec3 vWorldPos;
layout(location = 1) out vec3 vNormal;
layout(location = 2) out vec2 vUV;
layout(location = 3) out vec4 vTangent;
layout(location = 4) flat out float vMaterial;
layout(location = 5) flat out vec4 vTint;

void main() {
    // firstInstance carries the batch's object-record base, so the instance
    // index addresses the object directly (no push constant per draw).
    ObjectGpu o = objects[gl_InstanceIndex];
    vMaterial = o.extra.x;
    vTint = o.tint;
    vec4 wp = o.model * vec4(inPos, 1.0);
    vWorldPos = wp.xyz;
    vNormal = mat3(o.normalMat) * inNormal;
    vUV = inUV;
    vTangent = vec4(mat3(o.normalMat) * inTangent.xyz, inTangent.w);
    gl_Position = frame.viewProj * wp;
}
