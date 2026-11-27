#version 450
#extension GL_EXT_nonuniform_qualifier : require
layout(set = 1, binding = 0) uniform sampler2D uTextures[];
layout(location = 0) flat in int vTexIdx;
layout(location = 0) out vec4 outColor;
void main() {
    outColor = texture(uTextures[nonuniformEXT(vTexIdx)], vec2(0.5, 0.5));
}
