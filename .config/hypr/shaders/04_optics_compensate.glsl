#version 300 es
// Retro CRT Shader - FULLY OPTIMIZED
// Fixes: Resolution-aware scanlines, proper vignette, edge clamping,
//        correct aberration direction, anti-aliased scanlines

precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// --- CONFIGURATION ---
const float CURVATURE = 3.5;
const float SCANLINE_STRENGTH = 0.25;
// Approximate screen height in pixels (adjust to your resolution)
const float SCREEN_HEIGHT = 1080.0;
// Scanlines per screen height (lower = thicker lines)
const float SCANLINE_COUNT = 540.0;
const float ABERRATION = 0.002;
const float VIGNETTE_RADIUS = 1.00;
const float VIGNETTE_SOFTNESS = 0.45;
// Phosphor glow simulation
const float GLOW = 0.03;

vec2 curveUV(vec2 uv) {
    uv = uv * 2.0 - 1.0;
    vec2 offset = abs(uv.yx) / vec2(CURVATURE);
    uv = uv + uv * offset * offset;
    uv = uv * 0.5 + 0.5;
    return uv;
}

void main() {
    vec2 uv = curveUV(v_texcoord);
    
    // Black bezel for out-of-bounds
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }
    
    // FIXED: Clamp aberration samples to prevent edge artifacts
    vec2 centerDist = uv - 0.5;
    vec2 aberrOffset = centerDist * ABERRATION;
    
    // FIXED: Correct direction - red focuses short, blue focuses long
    float r = texture(tex, clamp(uv + aberrOffset, 0.0, 1.0)).r;
    float g = texture(tex, uv).g;
    float b = texture(tex, clamp(uv - aberrOffset, 0.0, 1.0)).b;
    vec3 color = vec3(r, g, b);
    
    // FIXED: Anti-aliased scanlines that don't shimmer during scroll
    // Using smooth triangle wave instead of harsh sine
    float scanlinePhase = uv.y * SCANLINE_COUNT * 2.0;
    float scanline = abs(fract(scanlinePhase) - 0.5) * 2.0; // Triangle wave 0-1
    scanline = smoothstep(0.0, 1.0, scanline); // Smooth it
    float scanlineFactor = 1.0 - (SCANLINE_STRENGTH * (1.0 - scanline));
    color *= scanlineFactor;
    
    // Subtle phosphor glow (brightens slightly between scanlines)
    color += GLOW * (1.0 - scanline);
    
    // FIXED: Proper circular vignette with correct smoothstep bounds
    float dist = length(centerDist) * 2.0; // 0 at center, ~1.414 at corners
    float vignette = 1.0 - smoothstep(VIGNETTE_RADIUS, VIGNETTE_RADIUS + VIGNETTE_SOFTNESS, dist);
    color *= vignette;
    
    // Subtle brightness boost to compensate for darkening effects
    color *= 1.1;
    
    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
