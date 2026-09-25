// Translucent moving membrane ridges. Apply as an overlay Polygon2D.
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 membrane_color : source_color = vec4(0.55, 0.18, 0.35, 1.0);
uniform float distortion_amount : hint_range(0.0, 0.12) = 0.028;
uniform float movement_speed : hint_range(0.0, 2.0) = 0.18;
uniform float ridge_density : hint_range(1.0, 28.0) = 10.0;
uniform float opacity : hint_range(0.0, 1.0) = 0.18;
uniform float seed = 0.0;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

float value_noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
               mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0)), f.x), f.y);
}

void fragment() {
    vec2 flow = vec2(TIME * movement_speed, -TIME * movement_speed * 0.37);
    float n = value_noise(UV * 8.0 + flow + seed);
    vec2 displaced_uv = UV + (n - 0.5) * distortion_amount;
    float bands = sin((displaced_uv.x + displaced_uv.y * 0.41 + n * 0.72) * ridge_density * 6.28318);
    float ridge = smoothstep(0.72, 0.98, bands) * (0.45 + n * 0.55);
    float alpha = ridge * opacity * COLOR.a;
    COLOR = vec4(membrane_color.rgb * (0.65 + ridge * 1.2), alpha * membrane_color.a);
}
