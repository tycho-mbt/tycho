#version 450
// Skinned PBR vertex shader: four joint influences per vertex, palette indexed
// through the object record so instanced skinned meshes share one draw.
layout(location = 0) in vec3 inPos;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec2 inUV;
layout(location = 3) in vec4 inTangent;
layout(location = 4) in vec4 inJoints;
layout(location = 5) in vec4 inWeights;

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
    vec4 bounds; // xyz local centre, w radius
    vec4 extra;  // x material, y joint offset, z joint count, w skinned
    vec4 tint;   // per-instance base-colour multiplier
};
layout(std430, binding = 1) readonly buffer ObjectBuf { ObjectGpu objects[]; };

layout(std430, binding = 10) readonly buffer BoneBuf { mat4 bones[]; };

layout(location = 0) out vec3 vWorldPos;
layout(location = 1) out vec3 vNormal;
layout(location = 2) out vec2 vUV;
layout(location = 3) out vec4 vTangent;
layout(location = 4) flat out float vMaterial;
layout(location = 5) flat out vec4 vTint;

void main() {
    ObjectGpu o = objects[gl_InstanceIndex];
    int base = int(o.extra.y + 0.5);
    mat4 skin =
        inWeights.x * bones[base + int(inJoints.x + 0.5)] +
        inWeights.y * bones[base + int(inJoints.y + 0.5)] +
        inWeights.z * bones[base + int(inJoints.z + 0.5)] +
        inWeights.w * bones[base + int(inJoints.w + 0.5)];
    vec4 wp = o.model * skin * vec4(inPos, 1.0);
    mat3 nrm = mat3(o.normalMat) * mat3(skin);
    vWorldPos = wp.xyz;
    vNormal = nrm * inNormal;
    vUV = inUV;
    vTangent = vec4(nrm * inTangent.xyz, inTangent.w);
    vMaterial = o.extra.x;
    vTint = o.tint;
    gl_Position = frame.viewProj * wp;
}
