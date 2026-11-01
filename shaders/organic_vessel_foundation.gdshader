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
    // Broad fascicles run along the vessel direction with slow, irregular
    // drift. The low-frequency layers avoid the looped/logo-like pattern of
    // the retired tunnel material.
    float fascicle_phase = tissue_position.z * 0.38 + tissue_position.x * 0.18 + tissue_position.y * 0.10 + sin(tissue_position.z * 0.14 + tissue_position.y * 0.22) * 1.2;
    float fascicle = sin(fascicle_phase) * 0.5 + 0.5;
    float collagen = sin(tissue_position.z * 1.7 + tissue_position.x * 0.46 + sin(tissue_position.y * 0.31) * 1.8) * 0.5 + 0.5;
    float seam = pow(abs(sin(fascicle_phase)), 12.0);
    float pore = sin(tissue_position.x * 3.7 + tissue_position.y * 2.4 + tissue_position.z * 0.9) * 0.5 + 0.5;
    float longitudinal_phase = tissue_position.z * 0.90 + tissue_position.x * 0.24 + tissue_position.y * 0.20 + sin(tissue_position.z * 0.21) * 1.1;
    float longitudinal_bundle = 0.5 + 0.5 * sin(longitudinal_phase);
    float connective_seam = pow(abs(sin(longitudinal_phase)), 16.0);
    float section_angle = UV.x * 6.2831853;
    float section_belly = 0.5 + 0.5 * sin(section_angle - 0.55);
    float section_vertical = sin(section_angle);
    float floor_factor = smoothstep(0.12, 0.88, section_vertical);
    float ceiling_factor = smoothstep(0.12, 0.88, -section_vertical);
    float section_recess = pow(1.0 - section_belly, 3.0);
    float floor_plane = 1.0 - smoothstep(-5.8, -1.8, tissue_position.y);
    float ceiling_plane = smoothstep(1.8, 5.8, tissue_position.y);

    // Burgundy connective tissue with broad fascicle bands, restrained enough
    // to remain wet material rather than a flat red or neon surface.
    vec3 deep_tissue = vec3(0.025, 0.006, 0.028);
    vec3 burgundy_tissue = vec3(0.43, 0.055, 0.15);
    vec3 warm_subsurface = vec3(0.64, 0.13, 0.26);
    vec3 tissue = mix(deep_tissue, burgundy_tissue, 0.08 + fascicle * 0.84);
    tissue += warm_subsurface * (1.0 - fascicle) * 0.18;
    tissue += vec3(0.40, 0.09, 0.19) * pow(collagen, 5.0) * 0.26;
    tissue += vec3(0.15, 0.024, 0.075) * pore * 0.10;
    tissue += vec3(0.31, 0.060, 0.15) * longitudinal_bundle * 0.19;
    tissue += vec3(0.62, 0.16, 0.30) * connective_seam * 0.11;
    tissue -= deep_tissue * seam * 0.30;
    tissue *= 0.78 + section_belly * 0.34;
    tissue += vec3(0.10, 0.028, 0.070) * floor_factor;
    tissue -= vec3(0.014, 0.004, 0.022) * ceiling_factor;
    tissue += vec3(0.12, 0.035, 0.085) * floor_plane;
    tissue += vec3(0.018, 0.006, 0.035) * ceiling_plane;
    tissue -= vec3(0.018, 0.004, 0.014) * section_recess;

    // A restrained orientation lift keeps the near floor, sidewalls, and
    // ceiling separated in the enclosed volume even on the Web/Mobile path.
    vec3 surface_normal = normalize(NORMAL);
    float orientation_lift = 0.78 + 0.22 * abs(surface_normal.y);
    float upward_surface = clamp(surface_normal.y * 0.5 + 0.5, 0.0, 1.0);
    tissue *= orientation_lift * (0.84 + upward_surface * 0.24);
    tissue += vec3(0.10, 0.035, 0.10) * upward_surface;

    vec3 view_direction = normalize(VIEW);
    float fresnel = pow(1.0 - max(dot(normalize(NORMAL), view_direction), 0.0), 2.0);
    float wet_facing = pow(abs(dot(normalize(NORMAL), view_direction)), 20.0);
    vec3 wet_specular = vec3(0.78, 0.32, 0.52) * (fresnel * 0.16 + wet_facing * 0.28);

    float event_distance = distance(tissue_position, event_world_position);
    float event_glow = exp(-(event_distance * event_distance) / max(event_radius * event_radius, 0.001)) * event_strength;

    ALBEDO = tissue * (1.02 + breath * 0.12) + wet_specular * 0.56 + vec3(0.24, 0.028, 0.08) * event_glow;
    ROUGHNESS = 0.24 + fascicle * 0.17;
    SPECULAR = 0.86;
    EMISSION = tissue * (0.20 + breath * 0.035) + wet_specular * 0.18 + vec3(0.25, 0.025, 0.07) * event_glow * 0.2;
}
