// Compatibility-safe procedural floor: dual scrolling cytoplasm noise plus slow tissue drift.
shader_type canvas_item;
render_mode unshaded;

uniform vec4 floor_color : source_color = vec4(0.24, 0.04, 0.08, 1.0);
uniform vec4 cell_color : source_color = vec4(0.48, 0.10, 0.19, 1.0);
uniform vec4 nucleus_color : source_color = vec4(0.08, 0.012, 0.03, 1.0);
uniform float flow_speed : hint_range(0.0, 2.0) = 0.11;
uniform float scale : hint_range(1.0, 24.0) = 8.0;
uniform vec2 uv_offset = vec2(0.0);
uniform float uv_rotation = 0.0;
uniform float low_frequency_strength : hint_range(0.0, 1.0) = 0.34;
uniform float seed = 0.0;

float hash21(vec2 p) {
    p = fract(p * vec2(443.897, 441.423));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

float value_noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
               mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
    float sum = 0.0;
    float amplitude = 0.5;
    for (int octave = 0; octave < 4; octave++) {
        sum += value_noise(p) * amplitude;
        p = p * 2.03 + vec2(17.3, 9.2);
        amplitude *= 0.5;
    }
    return sum;
}

void fragment() {
    mat2 rotation = mat2(cos(uv_rotation), -sin(uv_rotation), sin(uv_rotation), cos(uv_rotation));
    vec2 transformed_uv = rotation * (UV - vec2(0.5)) + vec2(0.5) + uv_offset;
    vec2 slow_drift = vec2(TIME * flow_speed * 0.13, -TIME * flow_speed * 0.08);
    vec2 flow_a = transformed_uv * scale + vec2(TIME * flow_speed, -TIME * flow_speed * 0.43) + seed;
    vec2 flow_b = transformed_uv * scale * 0.57 + vec2(-TIME * flow_speed * 0.31, TIME * flow_speed * 0.19) + seed * 2.71;
    float cytoplasm_a = fbm(flow_a);
    float cytoplasm_b = fbm(flow_b);
    float low_frequency = fbm(transformed_uv * 1.35 + slow_drift + seed * 0.17);
    float tissue = mix(cytoplasm_a, cytoplasm_b, 0.42);
    tissue = mix(tissue, low_frequency, low_frequency_strength);
    float folds = fbm(flow_a * 2.14 + cytoplasm_b * 0.8);
    float cells = sin((transformed_uv.x * 1.7 + transformed_uv.y * 2.1 + tissue) * 27.0 + low_frequency * 4.0) * 0.5 + 0.5;
    float cellular = smoothstep(0.64, 0.91, cells);
    vec3 color = mix(floor_color.rgb * 0.70, cell_color.rgb, tissue * 0.66);
    color = mix(color, cell_color.rgb * 1.14, folds * 0.26);
    color = mix(color, nucleus_color.rgb, cellular * 0.18);
    COLOR = vec4(color, COLOR.a);
}
