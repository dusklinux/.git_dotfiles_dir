#version 300 es
// Vignette Shader - OPTIMIZED  
// Fixes: Aspect ratio correction for circular vignette, safe smoothstep bounds

precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// --- CONFIGURATION ---
const float RADIUS = 0.65;
const float SOFTNESS = 0.45;
const float STRENGTH = 0.5;
// Set to your monitor's aspect ratio for circular vignette
const float ASPECT_RATIO = 16.0 / 9.0;

void main() {
    vec4 color = texture(tex, v_texcoord);
    
    // FIXED: Aspect-corrected distance for circular (not elliptical) vignette
    vec2 centered = v_texcoord - 0.5;
    centered.x *= ASPECT_RATIO;
    float dist = length(centered);
    // Normalize so corner distance is ~1.0 regardless of aspect ratio
    dist /= length(vec2(ASPECT_RATIO * 0.5, 0.5));
    
    // FIXED: Ensure smoothstep has valid bounds (edge1 > edge0)
    float innerEdge = RADIUS;
    float outerEdge = RADIUS + SOFTNESS;
    float vignette = 1.0 - smoothstep(innerEdge, outerEdge, dist);
    
    // Apply with strength control
    color.rgb = mix(color.rgb, color.rgb * vignette, STRENGTH);
    
    fragColor = color;
}
