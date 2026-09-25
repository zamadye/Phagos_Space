// Compatibility-safe additive vessel shader.
// Intended for Line2D and imported transparent vein overlays.
shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec4 vein_color : source_color = vec4(0.18, 0.90, 1.0, 1.0);
uniform float travel_speed : hint_range(0.0, 6.0) = 1.35;
uniform float travel_frequency : hint_range(1.0, 24.0) = 9.0;
uniform float pulse_strength : hint_range(0.0, 3.0) = 1.2;
uniform float amplitude_random : hint_range(0.0, 1.0) = 0.34;
uniform float phase_offset = 0.0;
uniform float core_intensity : hint_range(0.0, 8.0) = 2.4;
uniform float aura_intensity : hint_range(0.0, 4.0) = 0.55;

float hash11(float value) {
    return fract(sin(value * 91.173) * 43758.5453);
}

void fragment() {
    vec4 source = texture(TEXTURE, UV) * COLOR;
    // UV.x gives directional, travelling flow along the vessel instead of synchronized flash.
    float variation = mix(1.0 - amplitude_random, 1.0 + amplitude_random, hash11(floor(UV.x * 12.0) + phase_offset));
    float travel = sin(UV.x * travel_frequency - TIME * travel_speed + phase_offset) * 0.5 + 0.5;
    float secondary = sin(UV.x * travel_frequency * 0.43 + TIME * travel_speed * 0.37 + phase_offset * 1.71) * 0.5 + 0.5;
    float pulse = (1.0 + travel * pulse_strength) * variation * mix(0.82, 1.12, secondary);
    float edge = 1.0 - abs(UV.y * 2.0 - 1.0);
    float core = smoothstep(0.24, 0.96, edge);
    float alpha = max(source.a, COLOR.a * 0.82) * vein_color.a;
    vec3 emission = vein_color.rgb * source.rgb * (core * core_intensity * pulse + aura_intensity * pulse);
    COLOR = vec4(emission, alpha);
}
