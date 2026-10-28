#version 440
// Light clicker mark: a four-point star with eight rays, split down the middle. Left of `split`
// it is Liquid Glass (refracts the backdrop, lit bezel, specular rim, a travelling glint, glowing
// rays); right of it the same shape is plain solid ink. `tile` adds the app-icon squircle, split
// the same way (frosted glass | white).
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 itemSize;
    vec4 area;          // item rect in backdrop coordinates
    vec2 backdropSize;
    float split;        // 0..1 across the item
    float progress;     // rays lit, 0..1 (loading)
    float time;         // seconds
    float tile;         // 1 = app-icon tile
    float hasBackdrop;  // 0 = synthesise a neutral backdrop
    vec4 ink;           // solid colour
};
layout(binding = 1) uniform sampler2D sharp;
layout(binding = 2) uniform sampler2D frosted;

const float PI = 3.14159265;

float sdStar4(vec2 p, float r, float m) {
    const float an = PI / 4.0;
    float en = PI / m;
    vec2 acs = vec2(cos(an), sin(an));
    vec2 ecs = vec2(cos(en), sin(en));
    float bn = mod(atan(p.x, p.y), 2.0 * an) - an;
    p = length(p) * vec2(cos(bn), abs(sin(bn)));
    p -= r * acs;
    p += ecs * clamp(-dot(p, ecs), 0.0, r * acs.y / ecs.y);
    return length(p) * sign(p.x);
}
float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}
float roundedBox(vec2 p, vec2 halfSize, float r) {
    vec2 q = abs(p) - halfSize + vec2(r);
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}
// Four-point sparkle: a concave superellipse (|x|^k + |y|^k)^(1/k) = r with k < 1, tips on the
// axes and the vertical pair a little longer. Distance is first-order: (F - r) / |grad F|.
// `small` (0..1) is the simplified form for title-bar and sidebar sizes: a fuller star and four
// diagonal rays instead of eight.
float small;
float sparkleF(vec2 q) {
    float k = mix(0.62, 0.74, small);
    vec2 a = max(abs(q * vec2(1.0, 0.86)), vec2(1e-6));
    return pow(pow(a.x, k) + pow(a.y, k), 1.0 / k);
}
float star(vec2 q) {
    float r = mix(0.295, 0.33, small);
    const float e = 0.0015;
    float f = sparkleF(q);
    vec2 g = vec2(sparkleF(q + vec2(e, 0.0)) - sparkleF(q - vec2(e, 0.0)),
                  sparkleF(q + vec2(0.0, e)) - sparkleF(q - vec2(0.0, e))) / (2.0 * e);
    // |grad F| blows up next to the axes for k < 1; clamping keeps the distance usable there.
    return (f - r) / clamp(length(g), 0.35, 1.6);
}
// Eight rays at 22.5 degrees off the axes, so the split never runs along one; long and short
// alternate. `lit` is the nearest ray's loading progress, `shine` its shimmer.
float rays(vec2 q, float w, out float lit, out float shine) {
    float d = 1e3;
    lit = 0.0;
    shine = 1.0;
    bool simple = small > 0.5;
    int count = simple ? 4 : 8;
    for (int i = 0; i < count; ++i) {
        float a = simple ? (float(i) + 0.5) * PI * 0.5 : (float(i) + 0.5) * PI * 0.25;
        vec2 dir = vec2(sin(a), -cos(a));
        bool longRay = simple || (i % 2) == 0;
        float r0 = simple ? 0.31 : longRay ? 0.225 : 0.235;
        float r1 = simple ? 0.47 : longRay ? 0.455 : 0.37;
        float on = clamp(progress * float(count) - float(i), 0.0, 1.0);
        if (on <= 0.0)
            continue;
        float di = sdSegment(q, dir * r0, dir * mix(r0 + 0.001, r1, on)) - w;
        if (di < d) {
            d = di;
            lit = on;
            shine = 0.72 + 0.28 * sin(time * 2.2 + float(i) * 1.3);
        }
    }
    return d;
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
    float scale = tile > 0.5 ? 0.80 : 1.0;
    vec2 q = p / scale;
    float qpx = px / scale;
    vec2 light = normalize(vec2(-0.55, -0.83));
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
                vec2 n = normalize(p + 1e-5) * vec2(1.0);
                vec3 f = backdrop(frosted, uv, -n * 0.03 * tt * tt);
                t = mix(f, vec3(1.0), 0.30);
                float facing = dot(normalize(p + 1e-5), light);
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
    float rayLit, rayShine;
    float w = max(mix(0.019, 0.042, small), 0.8 * qpx);
    float dR = rays(q, w, rayLit, rayShine);

    if (glass) {
        // Soft halo behind the glass star and rays: they shine.
        float halo = (exp(-length(q) / 0.20) * 0.55 * (0.4 + 0.6 * progress) + exp(-max(dR, 0.0) / 0.03) * 0.35 * rayLit * rayShine)
                   * smoothstep(0.5, 0.3, length(q)) * (1.0 - small);
        col = over(col, vec3(1.0), clamp(halo, 0.0, 1.0) * (1.0 - clamp(0.5 - dS / qpx, 0.0, 1.0)));
        // Contact shadow so clear glass still reads on light surfaces.
        float dShadow = star(q - vec2(0.0, 0.022));
        float shadow = (1.0 - smoothstep(0.0, 0.07, dShadow)) * 0.30 * step(0.0, dS);
        col = over(col, vec3(0.10, 0.11, 0.14), shadow);
        // Rays: glass rods with a white core and a cool rim.
        float cR = clamp(0.5 - dR / qpx, 0.0, 1.0) * rayLit;
        vec3 rod = mix(vec3(0.46, 0.49, 0.56), vec3(1.0), smoothstep(-w * 0.95, -w * 0.25, dR) * rayShine);
        rod = mix(rod, vec3(0.45, 0.47, 0.53), 0.55 * small);
        col = over(col, rod, cR);
        // Star: refracting lens.
        float cS = clamp(0.5 - dS / qpx, 0.0, 1.0);
        if (cS > 0.0) {
            const float e = 0.002;
            vec2 n = vec2(star(q + vec2(e, 0.0)) - star(q - vec2(e, 0.0)), star(q + vec2(0.0, e)) - star(q - vec2(0.0, e)));
            n = length(n) > 1e-6 ? normalize(n) : vec2(0.0);
            float inner = max(-dS, 0.0);
            float t = 1.0 - clamp(inner / 0.06, 0.0, 1.0);
            float curve = t * t;
            vec2 offset = (-n * 0.09 * curve - q * 0.30) * scale * side / itemSize;
            vec3 seen = backdrop(sharp, uv, offset);
            vec3 s = mix(seen, vec3(0.97, 0.975, 0.985), 0.30);
            float facing = dot(n, light);
            float rimLine = 1.0 - smoothstep(0.0, 1.6 * qpx, inner);
            s += vec3(rimLine * (0.35 + 0.65 * pow(max(facing, 0.0), 1.2)) + rimLine * 0.4 * pow(max(-facing, 0.0), 2.0));
            s += vec3(curve * max(facing, 0.0) * 0.35);
            s *= 1.0 - 0.45 * curve * max(-facing, 0.0);
            s = mix(s, vec3(0.30, 0.32, 0.37), 0.35 * (1.0 - smoothstep(0.0, 1.2 * qpx, inner)) * max(-facing, 0.0));
            // Travelling glint across the glass.
            float sweep = fract(time * 0.22) * 1.6 - 0.8;
            float band = dot(q, normalize(vec2(1.0, -1.0))) - sweep;
            s += vec3(0.55 * exp(-band * band / 0.0025));
            // Small sizes: a graphite outline so the clear half still reads as a shape.
            s = mix(s, vec3(0.36, 0.38, 0.43), 0.75 * small * (1.0 - smoothstep(0.0, 1.4 * qpx, inner)));
            col = over(col, clamp(s, 0.0, 1.0), cS);
        }
    } else {
        float cR = clamp(0.5 - dR / qpx, 0.0, 1.0) * rayLit;
        col = over(col, ink.rgb, cR * ink.a);
        float cS = clamp(0.5 - dS / qpx, 0.0, 1.0);
        col = over(col, ink.rgb, cS * ink.a);
    }
    fragColor = col * qt_Opacity;
}
