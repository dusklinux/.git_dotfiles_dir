#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
uniform float TIME;
out vec4 fragColor;

// --- CONFIGURATION ---
const float wobble_speed = 3.0;         // Animation speed
const float wobble_frequency = 15.0;    // Wave density
const float wobble_amplitude = 0.025;   // Displacement amount
const float edge_fade = 0.1;            // Fade near edges (0.0 to disable)
const bool  organic_motion = true;      // Multi-frequency for natural look
const bool  prevent_edge_artifacts = true;
// ---------------------

void main() {
    // Use local time to prevent floating point precision issues with large TIME values
    float t = mod(TIME, 628.318);  // Wrap at 2*PI*100
    
    vec2 new_uv = v_texcoord;
    
    // Calculate edge fade mask (reduces artifacts at screen borders)
    float edge_mask = 1.0;
    if (edge_fade > 0.0) {
        vec2 dist_to_edge = min(v_texcoord, 1.0 - v_texcoord);
        float min_dist = min(dist_to_edge.x, dist_to_edge.y);
        edge_mask = smoothstep(0.0, edge_fade, min_dist);
    }
    
    float amplitude = wobble_amplitude * edge_mask;
    
    float h_offset, v_offset;
    
    if (organic_motion) {
        // Layer multiple frequencies for organic, natural motion
        // Different speeds prevent repetitive patterns
        
        // Horizontal wobble (based on Y position)
        h_offset = 0.0;
        h_offset += sin(v_texcoord.y * wobble_frequency * 1.0 + t * wobble_speed * 1.00) * 0.50;
        h_offset += sin(v_texcoord.y * wobble_frequency * 2.1 + t * wobble_speed * 1.37) * 0.30;
        h_offset += sin(v_texcoord.y * wobble_frequency * 0.5 + t * wobble_speed * 0.71) * 0.20;
        
        // Vertical wobble (based on X position)
        v_offset = 0.0;
        v_offset += cos(v_texcoord.x * wobble_frequency * 0.9 + t * wobble_speed * 1.13) * 0.50;
        v_offset += cos(v_texcoord.x * wobble_frequency * 1.7 + t * wobble_speed * 0.83) * 0.30;
        v_offset += cos(v_texcoord.x * wobble_frequency * 0.4 + t * wobble_speed * 1.41) * 0.20;
        
        // Add subtle interaction between axes
        h_offset += sin(v_texcoord.x * wobble_frequency * 0.3 + t * wobble_speed * 0.5) * 0.1;
        v_offset += cos(v_texcoord.y * wobble_frequency * 0.3 + t * wobble_speed * 0.6) * 0.1;
        
    } else {
        // Simple single-frequency wobble
        h_offset = sin(v_texcoord.y * wobble_frequency + t * wobble_speed);
        v_offset = cos(v_texcoord.x * wobble_frequency + t * wobble_speed);
    }
    
    new_uv.x += h_offset * amplitude;
    new_uv.y += v_offset * amplitude;
    
    // Prevent sampling outside texture bounds
    if (prevent_edge_artifacts) {
        // Clamp with small margin to prevent edge bleeding
        new_uv = clamp(new_uv, 0.002, 0.998);
    }
    
    fragColor = texture(tex, new_uv);
}
