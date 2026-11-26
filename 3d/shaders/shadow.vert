#version 450
layout(location = 0) in vec3 inPos;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec2 inUV;

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
    vec4 extra;  // x material index
};
layout(std430, binding = 1) readonly buffer ObjectBuf { ObjectGpu objects[]; };

layout(push_constant) uniform PC { mat4 lvp; } pc;

void main() {
    // firstInstance supplies the batch's object-record base.
    ObjectGpu o = objects[gl_InstanceIndex];
    gl_Position = pc.lvp * o.model * vec4(inPos, 1.0);
}
