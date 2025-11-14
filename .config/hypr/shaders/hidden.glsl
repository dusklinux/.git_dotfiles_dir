#version 300 es
precision mediump float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// --- CONFIGURATION ---
// Higher numbers mean smaller pixels (less pixelated).
// Try values between 64.0 and 512.0
const float pixel_size = 350.0;
// ---------------------

void main() {
  // Calculate the dimensions of a single "pixel"
  vec2 pixel_dimensions = 1.0 / vec2(pixel_size);

  // Round the texture coordinate down to the nearest "pixel" corner
  vec2 rounded_coord = floor(v_texcoord / pixel_dimensions) * pixel_dimensions;

  // Use the rounded coordinate to sample the color
  vec4 final_color = texture(tex, rounded_coord);

  fragColor = final_color;
}
