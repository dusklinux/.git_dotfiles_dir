#version 300 es
// Retro CRT Shader for Hyprland
// Author: Gemini
// Description: A complete 1990s monitor simulation.
// Features: Screen curvature, heavy vignetting, scanlines, and edge aberration.
// "Mindblowingly Cool" factor: High.

precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// --- CONFIGURATION ---
// Curvature strength. Higher = more curved.
// 4.0 is a good balance. 10.0 is flatter. 2.0 is a fish-eye lens.
const float CURVATURE = 3.5; 

// Scanline opacity (0.0 to 1.0)
const float SCANLINE_STRENGTH = 0.25;

// Scanline frequency (simulated vertical resolution)
const float SCANLINE_FREQ = 800.0;

// Chromatic aberration offset (Red/Blue separation at edges)
const float ABERRATION = 0.002;

// Vignette strength
const float VIGNETTE_STRENGTH = 1.2;
// ---------------------

// Function to apply the tube curvature to the UV coordinates
vec2 curveUV(vec2 uv) {
    uv = uv * 2.0 - 1.0; // Center origin
    vec2 offset = abs(uv.yx) / vec2(CURVATURE);
    uv = uv + uv * offset * offset;
    uv = uv * 0.5 + 0.5; // Restore origin
    return uv;
}

void main() {
    // 1. Warp the coordinates to simulate curved glass
    vec2 uv = curveUV(v_texcoord);

    // 2. Check if the warped coordinates are outside the screen bounds
    // This creates the black "bezel" around the curved image
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // 3. Apply Chromatic Aberration (Simulating electron beam misalignment)
    // We offset Red and Blue in opposite directions based on distance from center
    vec2 centerDist = uv - 0.5;
    
    float r = texture(tex, uv + centerDist * ABERRATION).r;
    float g = texture(tex, uv).g;
    float b = texture(tex, uv - centerDist * ABERRATION).b;
    
    vec3 color = vec3(r, g, b);

    // 4. Apply Scanlines
    // Uses a sine wave based on the Y coordinate to create horizontal stripes
    float scanline = sin(uv.y * SCANLINE_FREQ * 6.28318); // 2*PI
    // Map sine wave (-1 to 1) to a darkening factor
    float scanlineFactor = 1.0 - (SCANLINE_STRENGTH * (scanline * 0.5 + 0.5));
    color *= scanlineFactor;

    // 5. Apply Vignette
    // Darkens the corners heavily to simulate tube depth
    float dist = distance(uv, vec2(0.5));
    float vignette = 1.0 - smoothstep(0.5, 1.5, dist * VIGNETTE_STRENGTH);
    color *= vignette;

    fragColor = vec4(color, 1.0);
}
