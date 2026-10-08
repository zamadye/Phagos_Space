shader_type spatial;
render_mode cull_disabled, diffuse_burley;

uniform float breathing_clock = 0.0;
uniform vec3 event_world_position = vec3(0.0);
uniform float event_strength = 0.0;
uniform float event_radius = 3.0;

void vertex() {
    vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float breath = sin(breathing_clock * 0.72 + world_position.z * 0.055) * 0.5 + 0.5;
    float muscular_wave = sin(world_position.z * 0.24 + sin(world_position.x * 0.17) * 1.7 + world_position.y * 0.11) * 0.5 + 0.5;
    float event_distance = distance(world_position, event_world_position);
    float event_influence = exp(-(event_distance * event_distance) / max(event_radius * event_radius, 0.001));
    float deformation = 0.035 + breath * 0.045 + muscular_wave * 0.026 + event_influence * event_strength * 0.42;
    // The camera is inside the authored volume, so orient normals toward the
    // traversal space after the Blender-to-glTF axis conversion.
    NORMAL = -NORMAL;
    VERTEX += NORMAL * deformation;
}

void fragment() {
    // Use world space so the tissue grain follows the vessel's restored
    // centerline after the Blender Z-up to Godot Y-up conversion.
    vec3 tissue_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float breath = sin(breathing_clock * 0.72 + tissue_position.z * 0.055) * 0.5 + 0.5;
    float fascicle = sin(tissue_position.z * 0.31 + sin(tissue_position.x * 0.21 + tissue_position.y * 0.13) * 2.1 + sin(tissue_position.z * 0.17) * 1.3) * 0.5 + 0.5;
    float collagen = sin(tissue_position.z * 1.7 + tissue_position.x * 0.46 + sin(tissue_position.y * 0.31) * 1.8) * 0.5 + 0.5;
    float seam = pow(abs(sin(tissue_position.z * 0.31 + sin(tissue_position.x * 0.21 + tissue_position.y * 0.13) * 2.1 + sin(tissue_position.z * 0.17))), 10.0);
    float pore = sin(tissue_position.x * 3.7 + tissue_position.y * 2.4 + tissue_position.z * 0.9) * 0.5 + 0.5;
    float longitudinal_bundle = 0.5 + 0.5 * sin(tissue_position.z * 0.82 + sin(tissue_position.x * 0.28) * 3.4 + sin(tissue_position.y * 0.37) * 2.0);
    float connective_seam = pow(abs(sin(tissue_position.z * 0.82 + sin(tissue_position.x * 0.28) * 3.4 + sin(tissue_position.y * 0.37) * 2.0)), 18.0);

    // Burgundy connective tissue with broad fascicle bands, restrained enough
    // to remain wet material rather than a flat red or neon surface.
    vec3 deep_tissue = vec3(0.105, 0.006, 0.015);
    vec3 burgundy_tissue = vec3(0.46, 0.030, 0.065);
    vec3 warm_subsurface = vec3(0.66, 0.055, 0.095);
    vec3 tissue = mix(deep_tissue, burgundy_tissue, 0.16 + fascicle * 0.70);
    tissue += warm_subsurface * (1.0 - fascicle) * 0.20;
    tissue += vec3(0.34, 0.040, 0.065) * pow(collagen, 5.0) * 0.22;
    tissue += vec3(0.16, 0.012, 0.028) * pore * 0.08;
    tissue += vec3(0.24, 0.028, 0.050) * longitudinal_bundle * 0.16;
    tissue += vec3(0.58, 0.075, 0.105) * connective_seam * 0.12;
    tissue -= deep_tissue * seam * 0.32;

    vec3 view_direction = normalize(VIEW);
    float fresnel = pow(1.0 - max(dot(normalize(NORMAL), view_direction), 0.0), 2.0);
    float wet_facing = pow(abs(dot(normalize(NORMAL), view_direction)), 20.0);
    vec3 wet_specular = vec3(0.82, 0.19, 0.23) * (fresnel * 0.13 + wet_facing * 0.25);

    float event_distance = distance(tissue_position, event_world_position);
    float event_glow = exp(-(event_distance * event_distance) / max(event_radius * event_radius, 0.001)) * event_strength;

    ALBEDO = tissue * (0.95 + breath * 0.12) + wet_specular * 0.62 + vec3(0.30, 0.012, 0.025) * event_glow;
    ROUGHNESS = 0.18 + fascicle * 0.18;
    SPECULAR = 0.92;
    EMISSION = tissue * (0.14 + breath * 0.035) + wet_specular * 0.28 + vec3(0.32, 0.012, 0.020) * event_glow * 0.2;
}
