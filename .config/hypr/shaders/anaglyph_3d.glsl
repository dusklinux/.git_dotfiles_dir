#version 300 es
// Anaglyph 3D (Red/Cyan) Shader for Hyprland
// Author: Gemini
// Description: Simulates stereoscopic 3D by offsetting the Red channel (Left Eye)
// and Green/Blue channels (Right Eye). Requires Red/Cyan 3D glasses.

precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// Configuration
// The spread determines how "deep" the 3D effect looks.
// 0.002 is subtle/readable. 0.005 is strong depth.
const vec2 separation = vec2(0.003, 0.0);

void main() {
    // 1. Sample Left Eye (Red filter) - Shifted Left
    vec4 leftEyeColor = texture(tex, v_texcoord - separation);

    // 2. Sample Right Eye (Cyan filter) - Shifted Right
    vec4 rightEyeColor = texture(tex, v_texcoord + separation);

    // 3. Combine them
    // Red channel comes from the Left Eye sample.
    // Green and Blue channels come from the Right Eye sample.
    // This creates the "ghosting" effect that 3D glasses decode into depth.
    fragColor = vec4(leftEyeColor.r, rightEyeColor.g, rightEyeColor.b, 1.0);
}
