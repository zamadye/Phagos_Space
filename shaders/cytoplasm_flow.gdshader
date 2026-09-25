// Procedural non-repeating floor treatment: flow, cellular noise, and membrane gradients.
shader_type canvas_item;
render_mode unshaded;

uniform vec4 floor_color : source_color = vec4(0.24, 0.04, 0.08, 1.0);
uniform vec4 cell_color : source_color = vec4(0.48, 0.10, 0.19, 1.0);
uniform vec4 nucleus_color : source_color = vec4(0.08, 0.012, 0.03, 1.0);
uniform float flow_speed : hint_range(0.0, 2.0) = 0.11;
uniform float scale : hint_range(1.0, 24.0) = 8.0;
uniform vec2 uv_offset = vec2(0.0);
uniform float uv_rotation = 0.0;
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
               mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0)), f.x), f.y);
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
    vec2 p = transformed_uv * scale + vec2(TIME * flow_speed, -TIME * flow_speed * 0.43) + seed;
    float tissue = fbm(p);
    float folds = fbm(p * 2.3 + tissue);
    float cellular = smoothstep(0.60, 0.90, sin((transformed_uv.x * 1.7 + transformed_uv.y * 2.1 + tissue) * 27.0) * 0.5 + 0.5);
    vec3 color = mix(floor_color.rgb * 0.72, cell_color.rgb, tissue * 0.64);
    color = mix(color, cell_color.rgb * 1.18, folds * 0.25);
    color = mix(color, nucleus_color.rgb, cellular * 0.18);
    COLOR = vec4(color, COLOR.a);
}
