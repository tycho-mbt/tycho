#version 450
layout(location = 0) in vec3 fragNormal;
layout(location = 1) in vec3 fragColor;
layout(location = 0) out vec4 outAlbedo;
layout(location = 1) out vec4 outNormal;
void main() {
    outAlbedo = vec4(fragColor, 1.0);
    vec3 n = normalize(fragNormal) * 0.5 + 0.5;
    outNormal = vec4(n, 1.0);
}
