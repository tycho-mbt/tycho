#version 450
layout(binding = 0) uniform SkyUBO {
    mat4 invRotProj;
    vec4 sunDir;   // xyz direction, w intensity
} ubo;

layout(location = 0) out vec3 vDir;

void main() {
    vec2 p = vec2((gl_VertexIndex << 1) & 2, gl_VertexIndex & 2);
    vec2 ndc = p * 2.0 - 1.0;
    vec4 ray = ubo.invRotProj * vec4(ndc, 1.0, 1.0);
    vDir = ray.xyz / ray.w;
    gl_Position = vec4(ndc, 0.0, 1.0);
}
