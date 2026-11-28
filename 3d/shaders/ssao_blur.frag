#version 450
// 3x3 box blur for the noisy SSAO buffer.
layout(binding = 0) uniform sampler2D uAO;
layout(push_constant) uniform BlurPC { vec4 texel; } pc;

layout(location = 0) in vec2 vUV;
layout(location = 0) out vec4 outAO;

void main() {
    float sum = 0.0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            sum += texture(uAO, vUV + vec2(float(x), float(y)) * pc.texel.xy).r;
        }
    }
    outAO = vec4(vec3(sum / 9.0), 1.0);
}
