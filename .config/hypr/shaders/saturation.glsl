// This MUST be the very first line.
#version 300 es

// Set the default precision for floating-point numbers.
precision mediump float;

/*
 * A simple GLSL 3.0 ES fragment shader for Hyprland/hyprshade
 * to adjust saturation and contrast.
 */

// --- USER CONFIGURABLES ---
// Set your desired values here.
// 1.0 is "normal" (no change).
// > 1.0 increases the effect (e.g., 1.5 is 50% more).
// < 1.0 decreases the effect.
const float SATURATION = 2.0; // 1.0 is normal, > 1.0 is oversaturated
const float CONTRAST = 1.0; // 1.0 is normal, > 1.0 is higher contrast
// --------------------------

// Input from the vertex shader (texture coordinate)
in vec2 v_texcoord;

// The screen texture provided by Hyprland
uniform sampler2D tex;

// The final output color for the pixel
out vec4 fragColor;

// Luminance constants for grayscale conversion (based on BT.709 standard)
const vec3 W = vec3(0.2126, 0.7152, 0.0722);

void main() {
    // Get the original pixel color from the screen texture
    // (using 'texture' instead of 'texture2D')
    vec4 original_color = texture(tex, v_texcoord);

    // We only want to affect the RGB channels, not the alpha (transparency)
    vec3 color = original_color.rgb;

    // 1. Apply Contrast
    // This formula scales the color away from the 0.5 midpoint
    color = (color - 0.5) * CONTRAST + 0.5;

    // 2. Apply Saturation
    // This formula finds the grayscale (luminance) value of the pixel
    // and then mixes it with the original color based on the SATURATION value.
    float luminance = dot(color, W);
    vec3 grayscale = vec3(luminance);
    color = mix(grayscale, color, SATURATION);

    // 3. Final Output
    // Clamp the color values to the valid 0.0 - 1.0 range to prevent
    // "blowout" (unintended artifacts where colors wrap around).
    color = clamp(color, 0.0, 1.0);

    // Assign the new, modified color to the pixel, keeping the original alpha
    // (using 'fragColor' instead of 'gl_FragColor')
    fragColor = vec4(color, original_color.a);
}
