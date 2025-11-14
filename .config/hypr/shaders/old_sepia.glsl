#version 300 es
precision mediump float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const float strength = 1.0;

void main() {
  vec4 original_color = texture(tex, v_texcoord);
  float luminance = dot(original_color.rgb, vec3(0.2126, 0.7152, 0.0722));
  vec3 sepia_tinted = vec3(luminance * 1.0, luminance * 0.95, luminance * 0.82);
  vec3 final_color = mix(original_color.rgb, sepia_tinted, strength);
  fragColor = vec4(final_color, original_color.a);
}
