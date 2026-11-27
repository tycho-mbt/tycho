#version 450
layout(binding = 0) uniform sampler2D uHDR;
layout(location = 0) in vec2 vUV;
layout(location = 0) out vec4 outBright;

void main() {
    vec3 c = texture(uHDR, vUV).rgb;
    float lum = dot(c, vec3(0.2126, 0.7152, 0.0722));
    vec3 bright = max(c - vec3(1.15), vec3(0.0));
    outBright = vec4(bright * smoothstep(0.9, 1.8, lum), 1.0);
}
