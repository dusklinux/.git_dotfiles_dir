#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// --- CONFIGURATION ---
const float edge_threshold = 0.15;      // Sensitivity (0.05-0.5) - lower = more edges
const float edge_softness = 0.08;       // Anti-aliasing amount
const float line_thickness = 1.0;       // 1.0 = normal, 2.0 = thicker
const float line_darkness = 0.05;       // 0.0 = pure black, higher = lighter
const float paper_brightness = 0.98;    // Paper color
const float paper_grain = 0.03;         // Paper texture intensity
const float noise_reduction = 0.5;      // Reduces speckles in smooth areas
// ---------------------

float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// Sample luminance with bounds checking
float sampleLum(vec2 uv) {
    vec2 safe_uv = clamp(uv, 0.0, 1.0);
    return luminance(texture(tex, safe_uv).rgb);
}

void main() {
    vec2 screen_res = vec2(textureSize(tex, 0));
    vec2 pixel_size = line_thickness / screen_res;
    vec2 pixel_coords = v_texcoord * screen_res;
    
    // Sobel kernel sampling with proper edge clamping
    float tl = sampleLum(v_texcoord + vec2(-pixel_size.x, -pixel_size.y));
    float t  = sampleLum(v_texcoord + vec2( 0.0,          -pixel_size.y));
    float tr = sampleLum(v_texcoord + vec2( pixel_size.x, -pixel_size.y));
    float l  = sampleLum(v_texcoord + vec2(-pixel_size.x,  0.0));
    float c  = sampleLum(v_texcoord);  // Center pixel
    float r  = sampleLum(v_texcoord + vec2( pixel_size.x,  0.0));
    float bl = sampleLum(v_texcoord + vec2(-pixel_size.x,  pixel_size.y));
    float b  = sampleLum(v_texcoord + vec2( 0.0,           pixel_size.y));
    float br = sampleLum(v_texcoord + vec2( pixel_size.x,  pixel_size.y));
    
    // Sobel operators
    float Gx = (tr + 2.0 * r + br) - (tl + 2.0 * l + bl);
    float Gy = (bl + 2.0 * b + br) - (tl + 2.0 * t + tr);
    float gradient = sqrt(Gx * Gx + Gy * Gy);
    
    // Calculate local variance for noise reduction
    // (reduces speckles in smooth areas while preserving real edges)
    float mean = (tl + t + tr + l + c + r + bl + b + br) / 9.0;
    float variance = 0.0;
    variance += (tl - mean) * (tl - mean);
    variance += (t - mean) * (t - mean);
    variance += (tr - mean) * (tr - mean);
    variance += (l - mean) * (l - mean);
    variance += (c - mean) * (c - mean);
    variance += (r - mean) * (r - mean);
    variance += (bl - mean) * (bl - mean);
    variance += (b - mean) * (b - mean);
    variance += (br - mean) * (br - mean);
    variance = sqrt(variance / 9.0);
    
    // Adaptive threshold: require stronger edges in noisy areas
    float adaptive_threshold = edge_threshold + variance * noise_reduction;
    
    // Smooth edge detection (anti-aliased)
    float edge = smoothstep(
        adaptive_threshold - edge_softness,
        adaptive_threshold + edge_softness,
        gradient
    );
    
    // Paper texture
    float paper = paper_brightness;
    paper -= hash12(pixel_coords * 0.4) * paper_grain;
    paper -= hash12(pixel_coords * 2.1) * paper_grain * 0.4;
    
    // Final blend
    float final_value = mix(paper, line_darkness, edge);
    
    fragColor = vec4(vec3(final_value), 1.0);
}
