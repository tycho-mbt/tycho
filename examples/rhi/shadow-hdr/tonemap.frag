#version 450
layout(binding = 0) uniform sampler2D uHDR;
layout(location = 0) in vec2 vUV;
layout(location = 0) out vec4 outColor;

void main() {
    vec3 hdr = texture(uHDR, vUV).rgb;
    vec3 mapped = hdr / (hdr + vec3(1.0));
    outColor = vec4(mapped, 1.0);
}
