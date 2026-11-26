#version 450
// Depth-only skinned shadow caster: same palette as pbr_skin.vert.
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
    vec4 bounds;
    vec4 extra; // x material, y joint offset, z joint count, w skinned
};
layout(std430, binding = 1) readonly buffer ObjectBuf { ObjectGpu objects[]; };

layout(std430, binding = 10) readonly buffer BoneBuf { mat4 bones[]; };

layout(push_constant) uniform PC { mat4 lvp; } pc;

void main() {
    ObjectGpu o = objects[gl_InstanceIndex];
    int base = int(o.extra.y + 0.5);
    mat4 skin =
        inWeights.x * bones[base + int(inJoints.x + 0.5)] +
        inWeights.y * bones[base + int(inJoints.y + 0.5)] +
        inWeights.z * bones[base + int(inJoints.z + 0.5)] +
        inWeights.w * bones[base + int(inJoints.w + 0.5)];
    gl_Position = pc.lvp * o.model * skin * vec4(inPos, 1.0);
}
