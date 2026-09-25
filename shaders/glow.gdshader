// Compatibility-safe additive HDR-friendly signal glow.
// Values above 1.0 remain useful to Forward+/post-bloom hosts while GL Compatibility
// gracefully clamps them instead of requiring unsupported framebuffer features.
shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec4 glow_color : source_color = vec4(0.25, 0.9, 1.0, 1.0);
uniform float energy : hint_range(0.0, 8.0) = 2.0;
uniform float falloff : hint_range(0.25, 6.0) = 2.2;
uniform float core_sharpness : hint_range(0.2, 8.0) = 2.8;
uniform float flicker_amount : hint_range(0.0, 1.0) = 0.08;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.7;
uniform float phase_offset = 0.0;

void fragment() {
    vec2 p = UV * 2.0 - vec2(1.0);
    float radius = length(p);
    float halo = pow(max(0.0, 1.0 - radius), falloff);
    float core = pow(max(0.0, 1.0 - radius * 1.45), core_sharpness);
    float pulse = 1.0 + sin(TIME * pulse_speed + phase_offset) * flicker_amount;
    vec3 emission = glow_color.rgb * energy * pulse * (halo + core * 0.72);
    COLOR = vec4(emission, halo * glow_color.a * COLOR.a);
}
