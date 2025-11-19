#version 300 es
// Pure Green Shader for Hyprland
// Author: Gemini
// Description: Converts the screen to grayscale using Rec. 601 luma coefficients, 
// then renders the result solely in the Green channel.
// This creates a classic "Matrix terminal" or Night Vision phosphor look.

precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// Standard Rec. 601 luma coefficients
const vec3 luma = vec3(0.299, 0.587, 0.114);

void main() {
    // 1. Sample the current pixel color
    vec4 pixColor = texture(tex, v_texcoord);

    // 2. Calculate luminance (grayscale value)
    float gray = dot(pixColor.rgb, luma);

    // 3. Output the color: Red = 0, Green = gray value, Blue = 0
    fragColor = vec4(0.0, gray, 0.0, pixColor.a);
}
