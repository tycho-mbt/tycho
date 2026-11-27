#version 450
layout(binding = 0) uniform sampler2D gAlbedo;
layout(binding = 1) uniform sampler2D gNormal;
layout(location = 0) in vec2 fragUV;
layout(location = 0) out vec4 outColor;
void main() {
    vec4 alb = texture(gAlbedo, fragUV);
    vec4 encN = texture(gNormal, fragUV);
    if (alb.a < 0.1) {
        outColor = vec4(0.05, 0.06, 0.10, 1.0);
        return;
    }
    vec3 n = normalize(encN.xyz * 2.0 - 1.0);
    vec3 lightDir = normalize(vec3(0.3, 0.4, 0.85));
    float ndotl = max(dot(n, lightDir), 0.0);
    vec3 lit = alb.rgb * (0.2 + 0.8 * ndotl);
    outColor = vec4(lit, 1.0);
}
