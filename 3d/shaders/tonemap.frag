#version 450
layout(binding = 0) uniform sampler2D uHDR;
layout(binding = 1) uniform sampler2D uBloom;
layout(location = 0) in vec2 vUV;
layout(location = 0) out vec4 outSRGB;

vec3 aces(vec3 x) {
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

void main() {
    vec3 hdr = texture(uHDR, vUV).rgb + texture(uBloom, vUV).rgb * 0.7;
    outSRGB = vec4(aces(hdr * 0.9), 1.0);
}
