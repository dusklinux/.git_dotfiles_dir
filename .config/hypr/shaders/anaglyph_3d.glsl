#version 300 es
precision mediump float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// --- CONFIGURATION ---
// Controls the horizontal separation, which dictates the perceived depth.
// Values between 0.004 and 0.012 work well.
const float depth_strength = 0.009;
// ---------------------

void main() {
    vec2 shift = vec2(depth_strength, 0.0);

    // 1. Calculate the coordinates for the left and right "eyes".
    vec2 left_uv = v_texcoord - shift;
    vec2 right_uv = v_texcoord + shift;

    // 2. ROBUST EDGE HANDLING: Sample the source textures.
    // We sample the original color first as a fallback. Then, only if the shifted
    // coordinates are safely within the screen, we sample the left/right colors.
    // This completely eliminates glitches and weird artifacts at the screen edges.
    vec3 center_color = texture(tex, v_texcoord).rgb;
    vec3 left_color = center_color;
    vec3 right_color = center_color;

    if (left_uv.x > 0.0) {
        left_color = texture(tex, left_uv).rgb;
    }
    if (right_uv.x < 1.0) {
        right_color = texture(tex, right_uv).rgb;
    }

    // 3. THE DUBOIS ALGORITHM: The core of the "pro" effect.
    // This is a highly optimized color matrix that produces superior, low-ghosting
    // results compared to a simple channel split.
    // Calculate the final Red, Green, and Blue values by combining the
    // contributions from the left and right eye images.
    float final_r = dot(left_color, vec3(0.437955, 0.449201, 0.164478)) +
                    dot(right_color, vec3(-0.0434706, -0.0450325, -0.0176463));

    float final_g = dot(left_color, vec3(-0.0625861, -0.0631843, -0.0242279)) +
                    dot(right_color, vec3(0.378476, 0.385399, 0.142493));

    float final_b = dot(left_color, vec3(-0.0484583, -0.0492932, -0.0182312)) +
                    dot(right_color, vec3(-0.026983, -0.0279316, 0.463935));

    // 4. Assemble the final color and preserve the original transparency.
    fragColor = vec4(final_r, final_g, final_b, texture(tex, v_texcoord).a);
}
