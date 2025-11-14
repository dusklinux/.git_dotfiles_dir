#version 300 es
precision mediump float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// --- CONFIGURATION ---
const float vignette_intensity = 1.0; // How dark the corners are. 0.0-1.0
const float vignette_smoothness = 0.1; // How soft the transition is. 0.1-1.0
// ---------------------

void main() {
  vec4 original_color = texture(tex, v_texcoord);

  // Calculate the distance of the pixel from the center of the screen (0.5, 0.5)
  float dist = distance(v_texcoord, vec2(0.5)) * vignette_intensity;

  // Use smoothstep to create a soft, non-linear fade
  float vignette_factor = 1.0 - smoothstep(vignette_smoothness, 1.0, dist);

  // Apply the darkening factor to the original color
  vec3 final_color = original_color.rgb * vignette_factor;

  fragColor = vec4(final_color, original_color.a);
}
