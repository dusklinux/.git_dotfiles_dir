#version 300 es
// Sepia Tone Shader - OPTIMIZED
// Fixes: Clamping to prevent overflow on bright pixels

precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// W3C standard Sepia Matrix (column-major for GLSL)
const mat3 SEPIA_MATRIX = mat3(
    0.393, 0.769, 0.189,  // Red output weights
    0.349, 0.686, 0.168,  // Green output weights
    0.272, 0.534, 0.131   // Blue output weights
);

// Sepia intensity (0.0 = no effect, 1.0 = full sepia)
const float INTENSITY = 1.0;

void main() {
    vec4 color = texture(tex, v_texcoord);
    
    vec3 sepia = color.rgb * SEPIA_MATRIX;
    
    // FIXED: Clamp to prevent overflow artifacts on bright pixels
    sepia = clamp(sepia, 0.0, 1.0);
    
    // Optional: blend with original for partial effect
    vec3 final = mix(color.rgb, sepia, INTENSITY);
    
    fragColor = vec4(final, color.a);
}
