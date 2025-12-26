#version 300 es
// Pure Green Channel Shader - FIXED
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    float gray = dot(pixColor.rgb, LUMA);
    // FIXED: Now correctly outputs to GREEN channel
    fragColor = vec4(0.0, gray, 0.0, pixColor.a);
}
