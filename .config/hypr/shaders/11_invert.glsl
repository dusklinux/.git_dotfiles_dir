#version 300 es
// Invert Colors Shader - OPTIMIZED
// Added: Optional luminance-preserving mode

precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// Set true for "smart invert" that preserves relative brightness
const bool PRESERVE_LUMINANCE = false;
const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

void main() {
    vec4 color = texture(tex, v_texcoord);
    vec3 inverted = 1.0 - color.rgb;
    
    if (PRESERVE_LUMINANCE) {
        // Adjust inverted colors to match original luminance
        float origLuma = dot(color.rgb, LUMA);
        float invLuma = dot(inverted, LUMA);
        if (invLuma > 0.001) {
            inverted *= origLuma / invLuma;
            inverted = clamp(inverted, 0.0, 1.0);
        }
    }
    
    fragColor = vec4(inverted, color.a);
}
