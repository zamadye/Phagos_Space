shader_type spatial;
render_mode cull_disabled, diffuse_burley;

uniform float breathing_clock = 0.0;
uniform vec3 event_world_position = vec3(0.0);
uniform float event_strength = 0.0;
uniform float event_radius = 2.8;

void vertex() {
    vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float breath = sin(breathing_clock * 0.82) * 0.5 + 0.5;
    // World-space low-frequency deformation: the authored membrane remains
    // fixed in place while the tissue expands and contracts.
    float travelling_wave = sin(world_position.z * 0.075 + world_position.x * 0.035 + breathing_clock * 0.52) * 0.5 + 0.5;
    float event_distance = distance(world_position, event_world_position);
    float event_influence = exp(-(event_distance * event_distance) / max(event_radius * event_radius, 0.001));
    float local_bulge = event_influence * event_strength;
    float breathing = 0.012 + breath * 0.024 + travelling_wave * 0.016 + local_bulge * 0.52;
    VERTEX += NORMAL * breathing;
}

void fragment() {
    float pulse = sin(breathing_clock * 0.82) * 0.5 + 0.5;
    float static_fold = sin(VERTEX.y * 0.43 + VERTEX.x * 0.19 + sin(VERTEX.z * 0.22) * 2.0) * 0.5 + 0.5;
    float travelling_light = sin(VERTEX.y * 0.25 + breathing_clock * 0.42) * 0.5 + 0.5;
    float event_distance = distance((MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz, event_world_position);
    float event_glow = exp(-(event_distance * event_distance) / max(event_radius * event_radius, 0.001)) * event_strength;
    vec3 deep = vec3(0.12, 0.014, 0.012);
    vec3 warm = vec3(0.32, 0.045, 0.035);
    vec3 base = mix(deep, warm, 0.30 + static_fold * 0.30 + travelling_light * 0.10);
    base += vec3(0.18, 0.020, 0.024) * event_glow;
    float glossy_rim = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 2.6);
    ALBEDO = base * (0.90 + pulse * 0.10) + glossy_rim * vec3(0.14, 0.018, 0.020);
    ROUGHNESS = 0.29 + static_fold * 0.10;
    METALLIC = 0.0;
    EMISSION = base * (0.018 + pulse * 0.012 + event_glow * 0.060);
}
