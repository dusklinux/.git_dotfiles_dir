#version 300 es
precision mediump float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
  vec4 original_color = texture(tex, v_texcoord);

  // Subtract the color from 1.0 to get its inverse
  vec3 inverted_color = 1.0 - original_color.rgb;

  fragColor = vec4(inverted_color, original_color.a);
}
