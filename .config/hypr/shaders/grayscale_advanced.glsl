#version 300 es
precision mediump float;

// Input from the vertex shader: the texture coordinate
in vec2 v_texcoord;

// The screen texture provided by Hyprland
uniform sampler2D tex;

// The final output color for the pixel
out vec4 fragColor;

// --- CONFIGURATION ---
// Set the strength of the grayscale effect.
// 1.0 = fully grayscale
// 0.0 = original color (no effect)
const float strength = 1.0;
// ---------------------

void main() {
  // Get the original color from the screen texture
  vec4 original_color = texture(tex, v_texcoord);

  // Calculate luminance using a weighted average for perceptual accuracy (BT.709).
  // This looks more natural than a simple (R+G+B)/3 average.
  // Using a dot product is a clean and efficient way to do the multiplication and addition.
  float luminance = dot(original_color.rgb, vec3(0.2126, 0.7152, 0.0722));

  // Create the full grayscale color from the calculated luminance
  vec3 grayscale_color = vec3(luminance);

  // Linearly interpolate between the original color and the grayscale color.
  // The 'mix' function handles this: mix(original, target, strength)
  vec3 final_color = mix(original_color.rgb, grayscale_color, strength);

  // Set the final fragment color, making sure to preserve the original alpha (transparency)
  fragColor = vec4(final_color, original_color.a);
}
