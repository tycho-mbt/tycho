#version 450
layout(push_constant) uniform Push {
    vec4 tint;
} pc;
layout(binding = 0) uniform sampler2D texSampler;
layout(location = 0) in vec2 fragUV;
layout(location = 0) out vec4 outColor;
void main() {
    outColor = texture(texSampler, fragUV) * pc.tint;
}
