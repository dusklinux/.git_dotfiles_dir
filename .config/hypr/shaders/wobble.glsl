#version 300 es
precision mediump float;

in vec2 v_texcoord;
uniform sampler2D tex;
uniform float TIME;
out vec4 fragColor;

// --- CONFIGURATION ---
const float wobble_speed = 3.0;     // How fast it wobbles
const float wobble_frequency = 15.0;  // How many waves are on screen
const float wobble_amplitude = 0.005; // How intense the wobble is
// ---------------------

void main() {
    vec2 new_uv = v_texcoord;

    // Calculate a horizontal offset using a sine wave based on the Y position and time
    float horizontal_wobble = sin(v_texcoord.y * wobble_frequency + TIME * wobble_speed) * wobble_amplitude;
    
    // Calculate a vertical offset using a cosine wave based on the X position and time
    float vertical_wobble = cos(v_texcoord.x * wobble_frequency + TIME * wobble_speed) * wobble_amplitude;

    // Apply both offsets to the texture coordinates
    new_uv.x += horizontal_wobble;
    new_uv.y += vertical_wobble;
    
    fragColor = texture(tex, new_uv);
}
