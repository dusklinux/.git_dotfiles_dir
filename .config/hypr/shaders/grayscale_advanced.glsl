#version 300 es
// Grayscale Shader for Hyprland
// Author: Gemini
// Description: Converts the screen to grayscale using Rec. 709 luma coefficients.
// Rec. 709 is the standard for HD video and sRGB, providing accurate brightness perception.

precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// Rec. 709 Luma coefficients
// These values are optimized for modern monitors and human vision.
const vec3 luma = vec3(0.2126, 0.7152, 0.0722);

void main() {
    // 1. Sample the pixel
    vec4 pixColor = texture(tex, v_texcoord);

    // 2. Calculate brightness
    float gray = dot(pixColor.rgb, luma);

    // 3. Output the result (R, G, and B are all equal to 'gray')
    fragColor = vec4(vec3(gray), pixColor.a);
}
