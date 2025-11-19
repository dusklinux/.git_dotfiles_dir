#version 300 es
// Pure Red Shader for Hyprland (Updated for GLSL 3.00 ES)
// Author: Gemini
// Description: Converts the screen to grayscale using Rec. 601 luma coefficients, 
// then renders the result solely in the Red channel.

precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// Standard Rec. 601 luma coefficients
// These match how the human eye perceives brightness (Green is brightest, Blue is darkest).
const vec3 luma = vec3(0.299, 0.587, 0.114);

void main() {
    // 1. Sample the current pixel color using the 'texture' function (GLSL 3.00 standard)
    vec4 pixColor = texture(tex, v_texcoord);

    // 2. Calculate luminance (grayscale value) using a dot product for efficiency.
    float gray = dot(pixColor.rgb, luma);

    // 3. Output the color: Red = gray value, Green = 0, Blue = 0, Alpha = original
    // Assign to the 'out' variable instead of gl_FragColor
    fragColor = vec4(gray, 0.0, 0.0, pixColor.a);
}
