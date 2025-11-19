#version 300 es
// Pure Blue Shader for Hyprland
// Author: Gemini
// Description: Converts the screen to grayscale using Rec. 601 luma coefficients, 
// then renders the result solely in the Blue channel.

precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// Standard Rec. 601 luma coefficients
// These ensure that brightness is perceived correctly by the human eye.
const vec3 luma = vec3(0.299, 0.587, 0.114);

void main() {
    // 1. Sample the current pixel color
    vec4 pixColor = texture(tex, v_texcoord);

    // 2. Calculate luminance (grayscale value)
    float gray = dot(pixColor.rgb, luma);

    // 3. Output the color: Red = 0, Green = 0, Blue = gray value
    fragColor = vec4(0.0, 0.0, gray, pixColor.a);
}
