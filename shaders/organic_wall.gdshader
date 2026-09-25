// Optional shader for imported wall-kit PNGs. Adds subtle living tissue movement without UV tiling.
shader_type canvas_item;

uniform float movement_speed : hint_range(0.0, 1.0) = 0.08;
uniform float distortion_amount : hint_range(0.0, 0.05) = 0.008;
uniform vec4 tint_color : source_color = vec4(1.0);

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void fragment() {
    float n = hash21(floor(UV * 18.0 + TIME * movement_speed));
    vec2 offset = vec2(n - 0.5, sin(TIME * movement_speed + UV.y * 22.0) * 0.5) * distortion_amount;
    vec4 albedo = texture(TEXTURE, UV + offset) * COLOR;
    COLOR = albedo * tint_color;
}
