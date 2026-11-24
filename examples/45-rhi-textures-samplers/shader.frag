#version 450
layout(binding = 0) uniform samplerCube uCube;
layout(binding = 1) uniform sampler2D uR8;
layout(location = 0) in vec2 vUV;
layout(location = 0) out vec4 outColor;
void main() {
    // Sample +Z face (blue=1.0) on left half, +X face (red=1.0) on right half
    vec3 dir = (vUV.x < 0.5) ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
    vec3 c = texture(uCube, dir).rgb;
    float r8 = texture(uR8, vUV).r;
    outColor = vec4(c.r, r8, c.b, 1.0);
}
