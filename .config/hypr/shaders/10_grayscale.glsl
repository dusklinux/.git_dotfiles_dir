#version 300 es
// Grayscale Shader for Hyprland - OPTIMIZED
// Added: Optional gamma-correct conversion for accurate luminance

precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// Rec. 709 Luma coefficients (sRGB/HDTV standard)
const vec3 LUMA_709 = vec3(0.2126, 0.7152, 0.0722);

// Set to true for gamma-correct grayscale (more accurate but slightly slower)
const bool GAMMA_CORRECT = false;

// sRGB gamma functions
float toLinear(float c) {
    return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4);
}
float toSRGB(float c) {
    return c <= 0.0031308 ? c * 12.92 : 1.055 * pow(c, 1.0/2.4) - 0.055;
}

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    
    float gray;
    if (GAMMA_CORRECT) {
        // Convert to linear space, compute luminance, convert back
        vec3 linear = vec3(toLinear(pixColor.r), toLinear(pixColor.g), toLinear(pixColor.b));
        float luminance = dot(linear, LUMA_709);
        gray = toSRGB(luminance);
    } else {
        // Fast path: direct computation in gamma space
        gray = dot(pixColor.rgb, LUMA_709);
    }

    fragColor = vec4(vec3(gray), pixColor.a);
}
