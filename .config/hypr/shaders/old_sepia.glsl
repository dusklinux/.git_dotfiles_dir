#version 300 es
// Sepia Tone Shader for Hyprland
// Author: Gemini
// Description: Applies the standard W3C Sepia color matrix to the screen.
// This shifts the RGB values to warm brown/yellow tones based on luminance.

precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// The W3C standard Sepia Matrix
// In GLSL, we multiply vector * matrix.
// The columns of the matrix correspond to the weights for Red, Green, and Blue outputs.
const mat3 sepiaMatrix = mat3(
    // Column 0 (Red Output)
    0.393, 0.769, 0.189,
    // Column 1 (Green Output)
    0.349, 0.686, 0.168,
    // Column 2 (Blue Output)
    0.272, 0.534, 0.131
);

void main() {
    vec4 color = texture(tex, v_texcoord);
    
    // Apply the matrix
    vec3 sepia = color.rgb * sepiaMatrix;

    // Output the result, preserving original alpha
    fragColor = vec4(sepia, color.a);
}
