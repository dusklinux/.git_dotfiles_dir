#version 300 es
// Chromatic Aberration Shader for Hyprland
// Author: Gemini
// Description: Simulates lens distortion by separating RGB channels based on 
// distance from the center. Creates a dynamic "glitch" or "lens" effect.

precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// --- CONFIGURATION ---
// Strength of the separation.
// 0.002 = Subtle, professional lens look
// 0.005 = Noticeable effect
// 0.010 = Strong glitch
const float STRENGTH = 0.003;

void main() {
    // 1. Calculate the direction and distance from the center of the screen.
    // We want the effect to be stronger at the edges (lens distortion).
    vec2 distFromCenter = v_texcoord - 0.5;
    
    // 2. Calculate the offset vector.
    // We multiply by STRENGTH. 
    // You can multiply by length(distFromCenter) again to make the effect exponential at edges,
    // but linear is usually cleaner for UI text.
    vec2 offset = distFromCenter * STRENGTH;

    // 3. Sample the channels with different offsets.
    // Red is pulled slightly in one direction.
    float r = texture(tex, v_texcoord - offset).r;
    
    // Green stays perfectly in the center (anchor point).
    vec4 centerPixel = texture(tex, v_texcoord);
    float g = centerPixel.g;
    
    // Blue is pushed in the opposite direction.
    float b = texture(tex, v_texcoord + offset).b;

    // 4. Recombine the channels.
    fragColor = vec4(r, g, b, centerPixel.a);
}
