#version 300 es
// Saturation & Contrast Shader for Hyprland
// Description: Allows fine-tuning of screen vibrancy and dynamic range.
// Efficiently applies saturation followed by contrast.

precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// --- CONFIGURATION ---
// 0.0 = Grayscale, 1.0 = Normal, 1.5 = Vibrant, 2.0 = Deep Fried
const float SATURATION = 3.0;

// 1.0 = Normal, 1.2 = High Contrast, 0.8 = Low Contrast (Faded)
const float CONTRAST = 1.0;
// ---------------------

// Rec. 709 Luma coefficients for accurate saturation calculations
const vec3 luma = vec3(0.2126, 0.7152, 0.0722);

void main() {
    // 1. Sample texture
    vec4 color = texture(tex, v_texcoord);
    
    // 2. Apply Saturation
    // Calculate the grayscale value (luminance)
    float gray = dot(color.rgb, luma);
    // Interpolate between grayscale and original color
    vec3 satColor = mix(vec3(gray), color.rgb, SATURATION);
    
    // 3. Apply Contrast
    // We shift color values so 0.5 is the "pivot" point.
    // Values > 0.5 get pushed up, values < 0.5 get pushed down.
    vec3 finalColor = (satColor - 0.5) * CONTRAST + 0.5;
    
    // 4. Output
    fragColor = vec4(finalColor, color.a);
}
