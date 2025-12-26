#version 300 es
// Pixelation Shader - OPTIMIZED
// Fixes: Sample from pixel CENTER (not corner), aspect ratio support

precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// --- CONFIGURATION ---
// Pixels across the shorter dimension (height usually)
const float PIXEL_COUNT = 350.0;
// Set to your aspect ratio, or 1.0 for square pixels
const float ASPECT_RATIO = 16.0 / 9.0;

void main() {
    // Calculate pixel dimensions accounting for aspect ratio
    vec2 pixelCount = vec2(PIXEL_COUNT * ASPECT_RATIO, PIXEL_COUNT);
    vec2 pixelSize = 1.0 / pixelCount;
    
    // FIXED: Sample from pixel CENTER, not corner
    // This prevents the "swimming" artifact when content moves
    vec2 pixelCoord = floor(v_texcoord * pixelCount) + 0.5;
    vec2 sampleCoord = pixelCoord / pixelCount;
    
    fragColor = texture(tex, sampleCoord);
}
