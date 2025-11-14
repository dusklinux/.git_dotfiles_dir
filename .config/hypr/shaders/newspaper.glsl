#version 300 es
precision mediump float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// --- CONFIGURATION ---
const float dot_spacing = 4.0;   // The size of each dot cell in pixels. 3.0-6.0 is a good range.
const int   color_levels = 4;    // Number of colors per channel for posterization.
const vec3  paper_color = vec3(0.95, 0.92, 0.85);
const float paper_texture_strength = 0.04;
// ---------------------

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

void main() {
    // 1. Posterize the original color to get that distinct comic/print look.
    vec3 original_color = texture(tex, v_texcoord).rgb;
    float levels = float(color_levels);
    vec3 posterized_color = floor(original_color * levels) / levels;

    // 2. Create the procedural paper texture.
    float paper_noise = random(v_texcoord * 700.0) * paper_texture_strength;
    vec3 textured_paper = paper_color - paper_noise;

    // 3. Create a resolution-aware grid based on pixels. THIS IS THE KEY FIX.
    vec2 screen_res = vec2(textureSize(tex, 0));
    vec2 pixel_coords = v_texcoord * screen_res;
    vec2 grid_uv = fract(pixel_coords / dot_spacing);

    // 4. Calculate the halftone dot based on the luminance of the posterized color.
    float lum = luminance(posterized_color);
    float dist_from_center = distance(grid_uv, vec2(0.5));
    float dot_radius = (1.0 - lum) * 0.707; // 0.707 is sqrt(2)/2, a good value for circular packing.

    float dot_mask = smoothstep(dot_radius - 0.1, dot_radius, dist_from_center);

    // 5. Combine everything.
    // The final color is a mix between the textured paper and the posterized ink color.
    vec3 final_color = mix(posterized_color, textured_paper, dot_mask);

    fragColor = vec4(final_color, 1.0);
}
