#version 300 es
// Invert Colors Shader for Hyprland
// Author: Gemini
// Description: Negates all color channels (Negative effect).
// Excellent for high-contrast reading or checking color values.

precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    // 1. Sample the current pixel
    vec4 color = texture(tex, v_texcoord);

    // 2. Invert the RGB channels
    // We subtract the color from 1.0 (white) to get the opposite color.
    // We preserve the alpha channel (color.a) to ensure the window system draws correctly.
    fragColor = vec4(1.0 - color.rgb, color.a);
}
