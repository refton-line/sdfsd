#version 440
// Light clicker mark: a five-point star split down the middle. Left of `split` it is Liquid Glass
// (refracts the backdrop, bezel lit from above, crisp edge); right of it the same star is solid ink, which
// fills from the bottom up with `progress` while the app loads. `tile` adds the app-icon squircle,
// split the same way (frosted glass | white).
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 itemSize;
    vec4 area;          // item rect in backdrop coordinates
    vec2 backdropSize;
    float split;        // 0..1 across the item
    float progress;     // solid half filled, 0..1 (loading)
    float tile;         // 1 = app-icon tile
    float hasBackdrop;  // 0 = synthesise a neutral backdrop
    vec4 ink;           // solid colour
};
layout(binding = 1) uniform sampler2D sharp;
layout(binding = 2) uniform sampler2D frosted;

float roundedBox(vec2 p, vec2 halfSize, float r) {
    vec2 q = abs(p) - halfSize + vec2(r);
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}
// Five-point star, point up (p has y up). Exact distance (after Inigo Quilez's sdStar5): `r` is the
// tip radius, `rf` the notch radius as a fraction of it.
float sdStar5(vec2 p, float r, float rf) {
    const vec2 k1 = vec2(0.809016994375, -0.587785252292);
    const vec2 k2 = vec2(-k1.x, k1.y);
    p.x = abs(p.x);
    p -= 2.0 * max(dot(k1, p), 0.0) * k1;
    p -= 2.0 * max(dot(k2, p), 0.0) * k2;
    p.x = abs(p.x);
    p.y -= r;
    vec2 ba = rf * vec2(-k1.y, k1.x) - vec2(0.0, 1.0);
    float h = clamp(dot(p, ba) / dot(ba, ba), 0.0, r);
    return length(p - ba * h) * sign(p.y * ba.x - p.x * ba.y);
}
// `small` (0..1): title-bar and sidebar sizes get a chubbier star with softer tips.
float small;
const float TIP = 0.40;
// The lower tips sit at cos(36°) of the tip radius, so the star is lowered to centre it.
const float DROP = 0.0955 * TIP;
float star(vec2 q) {
    return sdStar5(vec2(q.x, DROP - q.y), TIP, mix(0.50, 0.56, small)) - mix(0.03, 0.045, small);
}
vec3 synthetic(vec2 uv) {
    vec3 top = vec3(0.95, 0.955, 0.965), bottom = vec3(0.78, 0.80, 0.84);
    vec3 c = mix(top, bottom, uv.y);
    c = mix(c, vec3(0.30, 0.32, 0.36), 0.55 * exp(-12.0 * dot(uv - vec2(0.72, 0.78), uv - vec2(0.72, 0.78))));
    return c;
}
vec3 backdrop(sampler2D tex, vec2 uvItem, vec2 offsetItem) {
    vec2 uv = uvItem + offsetItem;
    if (hasBackdrop < 0.5)
        return synthetic(clamp(uv, 0.0, 1.0));
    vec2 b = (area.xy + uv * area.zw) / backdropSize;
    return texture(tex, b).rgb;
}
vec4 over(vec4 dst, vec3 rgb, float a) {
    return vec4(rgb * a + dst.rgb * (1.0 - a), a + dst.a * (1.0 - a));
}

void main() {
    vec2 uv = qt_TexCoord0;
    float side = min(itemSize.x, itemSize.y);
    vec2 p = (uv - 0.5) * itemSize / side;
    float px = 1.0 / side;
    small = clamp((60.0 - side) / 24.0, 0.0, 1.0);
    bool glass = uv.x < split;
    float scale = tile > 0.5 ? mix(0.78, 0.88, small) : 1.0;
    vec2 q = p / scale;
    float qpx = px / scale;
    vec2 tileLight = normalize(vec2(-0.55, -0.83));
    vec4 col = vec4(0.0);

    // App-icon tile
    if (tile > 0.5) {
        float dT = roundedBox(p, vec2(0.5 - px), 0.225);
        float cT = clamp(0.5 - dT / px, 0.0, 1.0);
        if (cT > 0.0) {
            vec3 t;
            if (glass) {
                float inner = max(-dT, 0.0);
                float tt = 1.0 - clamp(inner / 0.07, 0.0, 1.0);
                vec2 n = normalize(p + 1e-5);
                vec3 f = backdrop(frosted, uv, -n * 0.03 * tt * tt);
                t = mix(f, vec3(1.0), 0.30);
                float facing = dot(n, tileLight);
                float rimLine = 1.0 - smoothstep(0.0, 2.0 * px, inner);
                t += vec3(rimLine * (0.35 + 0.65 * max(facing, 0.0)) + tt * tt * max(facing, 0.0) * 0.25);
                t *= 1.0 - 0.10 * tt * tt * max(-facing, 0.0);
            } else {
                t = mix(vec3(1.0), vec3(0.95, 0.95, 0.97), uv.y);
                float edge = 1.0 - smoothstep(0.0, 1.5 * px, max(-dT, 0.0));
                t = mix(t, vec3(0.84, 0.84, 0.86), edge * 0.6);
            }
            col = over(col, clamp(t, 0.0, 1.0), cT);
        }
    }

    float dS = star(q);
    float cS = clamp(0.5 - dS / qpx, 0.0, 1.0);
    // One soft shadow under the whole star, so both halves sit on the surface the same way.
    float dShadow = star(q - vec2(0.0, 0.018));
    float shadow = (1.0 - smoothstep(-0.01, 0.06, dShadow)) * 0.16 * (1.0 - small);
    col = over(col, vec3(0.10, 0.11, 0.14), shadow * (1.0 - cS));
    if (glass) {
        if (cS > 0.0) {
            const float e = 0.002;
            vec2 n = vec2(star(q + vec2(e, 0.0)) - star(q - vec2(e, 0.0)), star(q + vec2(0.0, e)) - star(q - vec2(0.0, e)));
            n = length(n) > 1e-6 ? normalize(n) : vec2(0.0);
            float inner = max(-dS, 0.0);
            float t = 1.0 - clamp(inner / mix(0.06, 0.08, small), 0.0, 1.0);
            float curve = t * t;
            vec2 offset = (-n * 0.05 * curve - q * 0.10) * scale * side / itemSize;
            // Frosted body, sharp refraction only in the bezel: a calm surface without smudges.
            vec3 seen = mix(backdrop(frosted, uv, offset), backdrop(sharp, uv, offset), curve);
            // Grey-tinted glass: light at large sizes, a mid grey at small ones so the glass half
            // carries the same visual weight as the ink half.
            vec3 s = mix(seen, mix(vec3(0.93, 0.94, 0.96), vec3(0.66, 0.69, 0.74), small), mix(0.30, 0.55, small));
            // Lit from above, so the bezel reads the same on every point of the half.
            vec2 light = normalize(vec2(-0.3, -1.0));
            float facing = dot(n, light);
            s += vec3(curve * max(facing, 0.0) * 0.30);
            s *= 1.0 - 0.30 * curve * max(-facing, 0.0);
            float rimLine = 1.0 - smoothstep(0.0, 1.3 * qpx, inner);
            s = mix(s, vec3(1.0), rimLine * 0.7 * max(facing, 0.0));
            // The outermost pixel is a graphite edge: the glass silhouette is as crisp as the ink one.
            float edge = 1.0 - smoothstep(0.0, qpx, inner);
            s = mix(s, vec3(0.40, 0.43, 0.48), edge * mix(0.45, 0.8, small));
            col = over(col, clamp(s, 0.0, 1.0), cS);
        }
    } else {
        // Loading: ink rises from the lowest tips to the top tip; the rest waits as a faint star.
        float level = mix(0.44, -0.44, clamp(progress, 0.0, 1.0));
        float filled = smoothstep(level - qpx, level + qpx, q.y);
        col = over(col, ink.rgb, cS * ink.a * mix(0.16, 1.0, filled));
    }
    fragColor = col * qt_Opacity;
}
