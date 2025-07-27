#version 300 es
precision mediump float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// --- CONFIGURATION ---
// Controls the intensity of the color separation.
// Good values are between 0.001 and 0.015
const float intensity = 0.015;
// ---------------------

void main() {
  // Vector pointing from the center of the screen to the current pixel
  vec2 direction = v_texcoord - vec2(0.5);

  // Sample the texture three times, offsetting the red and blue channels
  float r = texture(tex, v_texcoord - direction * intensity).r;
  float g = texture(tex, v_texcoord).g; // Green channel stays in the middle
  float b = texture(tex, v_texcoord + direction * intensity).b;

  // Combine the shifted channels into the final color
  fragColor = vec4(r, g, b, texture(tex, v_texcoord).a);
}
