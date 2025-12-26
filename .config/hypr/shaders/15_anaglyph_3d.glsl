#version 300 es
// Anaglyph 3D Shader - OPTIMIZED
// Fixes: Edge clamping, alpha preservation, depth-aware separation

precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// --- CONFIGURATION ---
const float SEPARATION = 0.003;
// Make separation stronger at edges (simulates depth from screen curvature)
const bool DEPTH_AWARE = true;

void main() {
    vec2 offset = vec2(SEPARATION, 0.0);
    
    // Optional: Increase separation toward screen edges for more depth
    if (DEPTH_AWARE) {
        float edgeFactor = abs(v_texcoord.x - 0.5) * 2.0; // 0 at center, 1 at edges
        offset.x *= 1.0 + edgeFactor * 0.5;
    }
    
    // Clamp coordinates to prevent edge sampling artifacts
    vec2 leftCoord = clamp(v_texcoord - offset, 0.0, 1.0);
    vec2 rightCoord = clamp(v_texcoord + offset, 0.0, 1.0);
    
    vec4 leftEye = texture(tex, leftCoord);
    vec4 rightEye = texture(tex, rightCoord);
    vec4 center = texture(tex, v_texcoord);
    
    // Combine: Red from left, Cyan (GB) from right
    fragColor = vec4(leftEye.r, rightEye.g, rightEye.b, center.a);
}
