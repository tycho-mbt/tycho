#version 450
// Depth-only morph caster: the light VP and the two weights come per draw.
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
    vec4 extra;
    vec4 tint;  // per-instance base-colour multiplier (unused here)
};
layout(std430, binding = 1) readonly buffer ObjectBuf { ObjectGpu objects[]; };

layout(push_constant) uniform PC {
    mat4 lvp;
    vec4 weights;
} pc;

void main() {
    ObjectGpu o = objects[gl_InstanceIndex];
    vec3 lp = inPos + pc.weights.x * inMorph0 + pc.weights.y * inMorph1;
    gl_Position = pc.lvp * o.model * vec4(lp, 1.0);
}
