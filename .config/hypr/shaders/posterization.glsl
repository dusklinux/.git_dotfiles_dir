#version 300 es
precision mediump float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// --- CONFIGURATION ---
// The number of color levels per channel.
// 2.0 is very harsh, 8.0 is subtle. Try 4.0.
const float color_levels = 4.0;
// ---------------------

void main() {
    vec4 original_color = texture(tex, v_texcoord);

    // This "snaps" each color channel to the nearest level.
    vec3 posterized_color = floor(original_color.rgb * color_levels) / color_levels;

    fragColor = vec4(posterized_color, original_color.a);
}
