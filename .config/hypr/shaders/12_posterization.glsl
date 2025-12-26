#version 300 es
// Posterization Shader - OPTIMIZED
// Fixes: Proper rounding, optional dithering to reduce banding

precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// --- CONFIGURATION ---
const float COLOR_LEVELS = 4.0;
// Enable dithering to reduce visible banding
const bool DITHER = true;

// Simple dither pattern
float dither(vec2 pos) {
    // 4x4 Bayer matrix approximation
    vec2 p = fract(pos * 0.5);
    float d = fract(dot(p, vec2(0.75, 0.5)));
    return (d - 0.5) / COLOR_LEVELS;
}

void main() {
    vec4 color = texture(tex, v_texcoord);
    
    vec3 posterized;
    if (DITHER) {
        // Add dither noise before quantization
        float ditherValue = dither(gl_FragCoord.xy);
        posterized = floor((color.rgb + ditherValue) * COLOR_LEVELS + 0.5) / COLOR_LEVELS;
    } else {
        // FIXED: Use round() behavior instead of floor() for better color accuracy
        posterized = floor(color.rgb * COLOR_LEVELS + 0.5) / COLOR_LEVELS;
    }
    
    posterized = clamp(posterized, 0.0, 1.0);
    fragColor = vec4(posterized, color.a);
}
