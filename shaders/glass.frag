#version 440
// Liquid Glass: refracts and frosts the backdrop behind a rounded rectangle, with a lit bezel,
// a specular rim and slight dispersion. Backdrop coordinates come from the item's mapped rect.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 itemSize;
    vec4 area;          // item rect in backdrop coordinates
    vec2 backdropSize;
    float radius;
    float bezel;        // width of the curved edge, px
    float refraction;   // edge displacement, px
    float frost;        // 0 clear .. 1 frosted
    float rim;          // specular strength
    float dispersion;   // chromatic split at the edge, px
    vec4 tint;          // rgb + amount (straight alpha)
    vec2 light;         // unit vector toward the light
    float magnify;      // lens magnification in the body
    float shade;        // darkening on the far bezel
    float hasBackdrop;  // 0: no backdrop to sample (overlay window), glass is lit tint only
    float inset;        // 1: recessed well, lit from below with an inner shadow on top
};
layout(binding = 1) uniform sampler2D sharp;
layout(binding = 2) uniform sampler2D frosted;

float roundedBox(vec2 p, vec2 halfSize, float r) {
    vec2 q = abs(p) - halfSize + vec2(r);
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
    vec2 p = qt_TexCoord0 * itemSize;
    vec2 halfSize = itemSize * 0.5;
    vec2 rel = p - halfSize;
    float r = min(radius, min(halfSize.x, halfSize.y));
    float d = roundedBox(rel, halfSize, r);
    float coverage = clamp(0.5 - d, 0.0, 1.0);
    if (coverage <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }
    const float e = 0.5;
    vec2 n = vec2(roundedBox(rel + vec2(e, 0.0), halfSize, r) - roundedBox(rel - vec2(e, 0.0), halfSize, r),
                  roundedBox(rel + vec2(0.0, e), halfSize, r) - roundedBox(rel - vec2(0.0, e), halfSize, r));
    float nl = length(n);
    n = nl > 1e-5 ? n / nl : vec2(0.0);
    float inner = max(-d, 0.0);
    float t = 1.0 - clamp(inner / max(bezel, 1.0), 0.0, 1.0);
    float curve = t * t;
    vec3 col;
    if (hasBackdrop > 0.5) {
        vec2 scale = area.zw / max(itemSize, vec2(1.0));
        float bend = inset > 0.5 ? -0.5 : 1.0;
        vec2 offset = (-n * refraction * curve * bend - rel * magnify) * scale;
        vec2 uv = (area.xy + p * scale + offset) / backdropSize;
        vec2 split = n * dispersion * curve * scale / backdropSize;
        vec3 clear = vec3(texture(sharp, uv + split).r, texture(sharp, uv).g, texture(sharp, uv - split).b);
        vec3 soft = vec3(texture(frosted, uv + split).r, texture(frosted, uv).g, texture(frosted, uv - split).b);
        col = mix(clear, soft, frost * (1.0 - 0.7 * curve));
        col = mix(col, tint.rgb, tint.a);
    } else {
        // Nothing behind to refract: the tint carries a soft vertical sheen instead.
        float y = qt_TexCoord0.y;
        col = tint.rgb + vec3(0.10 * (1.0 - y) * (1.0 - y)) - vec3(0.04 * y);
    }
    vec2 lightDir = inset > 0.5 ? -light : light;
    float facing = dot(n, lightDir);
    float rimLine = 1.0 - smoothstep(0.0, 1.6, inner);
    float spec = rimLine * (0.30 + 0.70 * pow(max(facing, 0.0), 1.2)) + rimLine * 0.45 * pow(max(-facing, 0.0), 2.0);
    float glow = curve * max(facing, 0.0) * 0.32;
    col += vec3(spec + glow) * rim;
    col *= 1.0 - shade * curve * max(-facing, 0.0);
    if (inset > 0.5)
        col *= 1.0 - 0.08 * curve * max(-facing, 0.0) - 0.02 * curve;
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0) * coverage * qt_Opacity;
}
