#version 300 es
precision mediump float;

in vec2 v_texcoord;
uniform sampler2D tex;

out vec4 fragColor;

void main() {
  vec4 current_color = texture(tex, v_texcoord);
  float grey = (current_color.r + current_color.g + current_color.b) / 3.0;
  fragColor = vec4(grey, grey, grey, 1.0);
}
