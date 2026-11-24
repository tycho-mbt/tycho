#version 450
layout(binding = 0) uniform sampler2D uSrc;
layout(push_constant) uniform BlurPC {
    vec4 dir;
} pc;
layout(location = 0) in vec2 vUV;
layout(location = 0) out vec4 outBlur;

void main() {
    float w[5] = float[](0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);
    vec3 res = texture(uSrc, vUV).rgb * w[0];
    for (int i = 1; i < 5; i++) {
        vec2 off = pc.dir.xy * float(i);
        res += texture(uSrc, vUV + off).rgb * w[i];
        res += texture(uSrc, vUV - off).rgb * w[i];
    }
    outBlur = vec4(res, 1.0);
}
