#version 300 es
// Pure Red Channel Shader - OPTIMIZED
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// Using Rec. 709 for consistency
const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    float gray = dot(pixColor.rgb, LUMA);
    fragColor = vec4(gray, 0.0, 0.0, pixColor.a);
}
