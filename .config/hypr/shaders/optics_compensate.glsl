#version 300 es
precision mediump float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// --- CONFIGURATION ---
// Controls the strength of the inward curve/outward curve
// Good values are between -1.00(outward) and 1.00 (inward).
const float strength = 0.05;
// ---------------------

void main() {
    // Remap texture coordinates from [0,1] to [-1,1] range, with (0,0) in the center.
    vec2 centered_uv = v_texcoord * 2.0 - 1.0;

    // Calculate the squared distance from the center. It's a bit more efficient than length().
    float r2 = dot(centered_uv, centered_uv);

    // This is the core of the pincushion formula. We create a distortion factor
    // that gets stronger as we move away from the center.
    // By subtracting (strength * r2), we ensure that pixels at the edge
    // will be sampled from coordinates much farther away.
    float distortion_factor = 1.0 - strength * r2;

    // We find the source texture coordinate by dividing our current position
    // by the distortion factor. This "pulls" the image inwards.
    vec2 sample_uv = centered_uv / distortion_factor;

    // Remap the coordinates back to the [0,1] range for texture sampling.
    sample_uv = sample_uv * 0.5 + 0.5;

    // When the effect is strong, it can try to sample from outside the screen area.
    // This check prevents weird artifacts at the very edges by drawing black instead.
    if (sample_uv.x < 0.0 || sample_uv.x > 1.0 || sample_uv.y < 0.0 || sample_uv.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
    } else {
        fragColor = texture(tex, sample_uv);
    }
}
