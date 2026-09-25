// Additive emissive vessel shader. Apply to Line2D / Sprite2D vein overlays.
shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec4 vein_color : source_color = vec4(0.18, 0.90, 1.0, 1.0);
uniform float pulse_speed = 1.35;
uniform float pulse_strength : hint_range(0.0, 3.0) = 1.2;
uniform float phase_offset = 0.0;
uniform float core_intensity : hint_range(0.0, 8.0) = 2.4;

void fragment() {
    vec4 source = texture(TEXTURE, UV) * COLOR;
    // UV.x travels along a Line2D, giving each vessel a travelling biological pulse.
    float travelling_wave = sin((UV.x * 9.0) - TIME * pulse_speed + phase_offset) * 0.5 + 0.5;
    float pulse = 1.0 + travelling_wave * pulse_strength;
    float alpha = max(source.a, COLOR.a * 0.85);
    vec3 emission = vein_color.rgb * core_intensity * pulse * source.rgb;
    COLOR = vec4(emission, alpha * vein_color.a);
}
