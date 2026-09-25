// Soft HDR-friendly additive glow. Pair with a small square Polygon2D or Sprite2D.
shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec4 glow_color : source_color = vec4(0.25, 0.9, 1.0, 1.0);
uniform float energy : hint_range(0.0, 8.0) = 2.0;
uniform float falloff : hint_range(0.25, 6.0) = 2.2;
uniform float flicker_amount : hint_range(0.0, 1.0) = 0.08;
uniform float phase_offset = 0.0;

void fragment() {
    vec2 p = UV * 2.0 - vec2(1.0);
    float radius = length(p);
    float soft_disc = pow(max(0.0, 1.0 - radius), falloff);
    float flicker = 1.0 + sin(TIME * 1.7 + phase_offset) * flicker_amount;
    COLOR = vec4(glow_color.rgb * energy * soft_disc * flicker, soft_disc * glow_color.a * COLOR.a);
}
