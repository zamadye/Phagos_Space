// Compatibility-safe translucent membrane ridges with layered noise and slow breathing.
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 membrane_color : source_color = vec4(0.55, 0.18, 0.35, 1.0);
uniform float distortion_amount : hint_range(0.0, 0.12) = 0.028;
uniform float movement_speed : hint_range(0.0, 2.0) = 0.18;
uniform float ridge_density : hint_range(1.0, 28.0) = 10.0;
uniform float opacity : hint_range(0.0, 1.0) = 0.18;
uniform float breathing_strength : hint_range(0.0, 0.5) = 0.08;
uniform float breathing_speed : hint_range(0.0, 3.0) = 0.58;
uniform float phase_offset = 0.0;
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
               mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

float layered_noise(vec2 p) {
    float result = 0.0;
    float amplitude = 0.58;
    for (int octave = 0; octave < 3; octave++) {
        result += value_noise(p) * amplitude;
        p = p * 2.07 + vec2(17.1, 9.4);
        amplitude *= 0.5;
    }
    return result;
}

void fragment() {
    float breath = sin(TIME * breathing_speed + phase_offset + seed * 4.0) * breathing_strength;
    vec2 slow_flow = vec2(TIME * movement_speed, -TIME * movement_speed * 0.37);
    float broad_noise = layered_noise(UV * 4.0 + slow_flow * 0.32 + seed);
    float fine_noise = layered_noise(UV * 13.0 - slow_flow * 0.83 + seed * 2.3);
    vec2 distortion = vec2(broad_noise - 0.5, fine_noise - 0.5) * (distortion_amount + breath * 0.12);
    vec2 displaced_uv = UV + distortion;
    float broad_bands = sin((displaced_uv.x + displaced_uv.y * 0.41 + broad_noise * 0.72) * ridge_density * 6.28318 + breath);
    float fine_bands = sin((displaced_uv.x * 0.31 - displaced_uv.y + fine_noise) * ridge_density * 2.7 - TIME * movement_speed * 0.42);
    float ridge = smoothstep(0.69, 0.98, broad_bands) * (0.48 + broad_noise * 0.52);
    ridge += smoothstep(0.88, 0.99, fine_bands) * 0.24;
    float alpha = clamp(ridge, 0.0, 1.0) * opacity * COLOR.a;
    vec3 tissue_color = membrane_color.rgb * (0.58 + ridge * (1.04 + breath));
    COLOR = vec4(tissue_color, alpha * membrane_color.a);
}
