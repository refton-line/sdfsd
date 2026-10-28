#version 440
// Material switch: the previous look stays outside a growing circle; a bright liquid front
// bends it outward as it passes.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 itemSize;
    vec2 center;
    float reach;
    float band;
};
layout(binding = 1) uniform sampler2D snapshot;

void main() {
    vec2 p = qt_TexCoord0 * itemSize;
    vec2 v = p - center;
    float dist = length(v);
    float edge = dist - reach;
    if (edge < -band) {
        fragColor = vec4(0.0);
        return;
    }
    vec2 dir = dist > 1e-3 ? v / dist : vec2(0.0);
    float t = 1.0 - clamp(abs(edge) / band, 0.0, 1.0);
    vec2 uv = (p - dir * band * 0.5 * t * t) / itemSize;
    vec4 previous = texture(snapshot, uv);
    float keep = smoothstep(-2.0, 2.0, edge);
    float ring = pow(t, 5.0) * 0.7;
    vec4 col = previous * keep;
    col += vec4(1.0) * ring * (1.0 - col.a);
    fragColor = col * qt_Opacity;
}
