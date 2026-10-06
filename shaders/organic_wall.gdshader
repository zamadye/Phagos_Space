shader_type spatial;
render_mode cull_disabled, diffuse_burley;

uniform float breathing_clock = 0.0;
uniform vec3 event_world_position = vec3(0.0);
uniform float event_strength = 0.0;
uniform float event_radius = 2.8;
uniform vec3 layer_tint = vec3(1.0, 1.0, 1.0);
uniform float layer_emission = 1.0;

void vertex() {
    vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float breath = sin(breathing_clock * 0.82) * 0.5 + 0.5;
    // Slow muscular deformation: the membrane expands in place; no texture
    // scrolling or journey-time UV offset is used.
    float muscle_wave = sin(world_position.z * 0.19 + world_position.x * 0.11 + sin(world_position.y * 0.16) * 1.8) * 0.5 + 0.5;
    float local_ripple = sin(world_position.z * 0.43 + world_position.y * 0.24) * 0.5 + 0.5;
    float event_distance = distance(world_position, event_world_position);
    float event_influence = exp(-(event_distance * event_distance) / max(event_radius * event_radius, 0.001));
    float local_bulge = event_influence * event_strength;
    float breathing = 0.028 + breath * 0.055 + muscle_wave * 0.040 + local_ripple * 0.018 + local_bulge * 0.52;
    VERTEX += NORMAL * breathing;
}

void fragment() {
    float breath = sin(breathing_clock * 0.82) * 0.5 + 0.5;
    float broad_muscle = sin(VERTEX.z * 0.34 + sin(VERTEX.x * 0.22) * 2.0 + VERTEX.y * 0.13) * 0.5 + 0.5;
    float fine_fiber = sin(VERTEX.z * 1.35 + VERTEX.x * 0.52 + sin(VERTEX.y * 0.40) * 2.2) * 0.5 + 0.5;
    float pore_variation = sin(VERTEX.x * 2.2 + VERTEX.y * 1.3 + VERTEX.z * 0.7) * 0.5 + 0.5;
    float event_distance = distance((MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz, event_world_position);
    float event_glow = exp(-(event_distance * event_distance) / max(event_radius * event_radius, 0.001)) * event_strength;

    // Deep maroon tissue with a wet red-burgundy response.
    vec3 deep_maroon = vec3(0.065, 0.004, 0.008);
    vec3 flesh_maroon = vec3(0.245, 0.020, 0.028);
    vec3 warm_highlight = vec3(0.52, 0.055, 0.070);
    vec3 tissue = mix(deep_maroon, flesh_maroon, 0.42 + broad_muscle * 0.30);
    tissue += warm_highlight * pow(fine_fiber, 5.0) * 0.11;
    tissue += warm_highlight * pore_variation * 0.022;

    // A broad wet highlight keeps the material readable in Web-safe lighting.
    // It is view-dependent gloss, not a moving texture.
    float view_rim = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 2.5);
    float wet_facing = pow(abs(dot(normalize(NORMAL), normalize(VIEW))), 10.0);
    float wet_band = pow(max(sin(VERTEX.z * 0.22 + VERTEX.x * 0.18), 0.0), 12.0);
    vec3 glossy = vec3(0.72, 0.10, 0.14) * (view_rim * 0.08 + wet_facing * 0.13 + wet_band * 0.035);
    vec3 pulse_tint = vec3(0.08, 0.004, 0.008) * breath;
    vec3 event_tint = vec3(0.42, 0.025, 0.040) * event_glow;

    vec3 layered_tissue = tissue * layer_tint;
    ALBEDO = layered_tissue * (0.78 + breath * 0.08) + glossy * layer_tint * 0.45 + pulse_tint + event_tint;
    ROUGHNESS = 0.17 + broad_muscle * 0.15;
    SPECULAR = 0.88;
    EMISSION = layered_tissue * (0.030 + breath * 0.012) * layer_emission + glossy * layer_tint * 0.18 + event_tint * 0.20;
}
