#version 450
layout(location = 0) in vec3 inPos;
layout(location = 1) in vec2 inUV;
layout(location = 2) in vec3 inNormal;

layout(binding = 0) uniform SceneUBO {
    mat4 viewProj;
    mat4 lightVP;
    vec4 lightDir;
} ubo;

layout(location = 0) out vec3 vWorldPos;
layout(location = 1) out vec2 vUV;
layout(location = 2) out vec3 vNormal;

void main() {
    vWorldPos = inPos;
    vUV = inUV;
    vNormal = inNormal;
    gl_Position = ubo.viewProj * vec4(inPos, 1.0);
}
