#version 450
#extension GL_ARB_enhanced_layouts : require

layout(location = 0, xfb_buffer = 0, xfb_offset = 0, xfb_stride = 16) out vec4 outPos;

void main() {
    vec2 pos[3] = vec2[](
        vec2( 0.0, -0.5),
        vec2( 0.5,  0.5),
        vec2(-0.5,  0.5)
    );
    outPos = vec4(pos[gl_VertexIndex], 0.0, 1.0);
    gl_Position = outPos;
}
