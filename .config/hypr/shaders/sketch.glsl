#version 300 es
precision mediump float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// --- CONFIGURATION ---
const float threshold = 0.2; // How sensitive the edge detection is. 0.1-0.5
const float line_color = 0.0; // 0.0 for black lines, 1.0 for white lines
// ---------------------

float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

void main() {
    // Get the size of one pixel
    vec2 pixel_size = 1.0 / vec2(textureSize(tex, 0));

    // Sample the luminance of the 8 pixels surrounding the current one
    float top_left = luminance(texture(tex, v_texcoord + vec2(-pixel_size.x, -pixel_size.y)).rgb);
    float top = luminance(texture(tex, v_texcoord + vec2(0.0, -pixel_size.y)).rgb);
    float top_right = luminance(texture(tex, v_texcoord + vec2(pixel_size.x, -pixel_size.y)).rgb);
    float left = luminance(texture(tex, v_texcoord + vec2(-pixel_size.x, 0.0)).rgb);
    float right = luminance(texture(tex, v_texcoord + vec2(pixel_size.x, 0.0)).rgb);
    float bottom_left = luminance(texture(tex, v_texcoord + vec2(-pixel_size.x, pixel_size.y)).rgb);
    float bottom = luminance(texture(tex, v_texcoord + vec2(0.0, pixel_size.y)).rgb);
    float bottom_right = luminance(texture(tex, v_texcoord + vec2(pixel_size.x, pixel_size.y)).rgb);

    // Sobel operator to detect edges
    float Gx = (top_right + 2.0 * right + bottom_right) - (top_left + 2.0 * left + bottom_left);
    float Gy = (bottom_left + 2.0 * bottom + bottom_right) - (top_left + 2.0 * top + top_right);
    float gradient = sqrt(Gx * Gx + Gy * Gy);

    if (gradient > threshold) {
        fragColor = vec4(vec3(line_color), 1.0); // Draw edge
    } else {
        fragColor = vec4(vec3(1.0 - line_color), 1.0); // Draw background
    }
}
