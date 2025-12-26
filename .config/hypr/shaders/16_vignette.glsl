#version 300 es
// Vignette Shader for Hyprland
// Description: Darkens the edges of the screen to draw focus to the center.
// Uses smoothstep for a high-quality, organic falloff.

precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// --- CONFIGURATION ---
// The radius where the darkening begins (0.0 is center, 0.8 is near corners)
const float RADIUS = 0.85;
// How soft the transition is (higher = smoother gradient)
const float SOFTNESS = 0.85;
// The strength of the darkness (0.0 = no vignette, 1.0 = pitch black corners)
const float STRENGTH = 0.8;

void main() {
    // 1. Sample the original screen color
    vec4 color = texture(tex, v_texcoord);

    // 2. Calculate distance from center (0.5, 0.5)
    float dist = distance(v_texcoord, vec2(0.5));

    // 3. Calculate vignette factor using smoothstep for high-quality falloff
    // We invert the smoothstep range so 1.0 is center and 0.0 is edges
    float vignette = smoothstep(RADIUS, RADIUS - SOFTNESS, dist);

    // 4. Apply the vignette strength
    // Mix between the original color and the darkened version
    // This allows us to control intensity without changing the geometry of the falloff
    color.rgb = mix(color.rgb, color.rgb * vignette, STRENGTH);

    fragColor = color;
}
