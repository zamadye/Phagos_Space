class_name OrganicCorridor
extends Node2D
## Draws a spline extrusion as layered living tissue. Main and side branches share the
## same code path, so a lung bronchiole or brain dendrite cannot develop seams.

const VEIN_SHADER = preload("res://shaders/vein_pulse.gdshader")
const BioGlowNode = preload("res://scripts/bio_glow.gd")
const BioLightFactoryScript = preload("res://scripts/bio_light_factory.gd")
const AssetResolverScript = preload("res://scripts/asset_resolver.gd")

var corridor_data: Dictionary
var biome: PhagosBiomeDefinition
var _tracks: Array[Dictionary] = []
var _lights: Array[PointLight2D] = []
var _base_light_energy: Array[float] = []
var _light_phase: Array[float] = []
var _configured := false

func configure(data: Dictionary, definition: PhagosBiomeDefinition, light_count: int = 0) -> void:
    corridor_data = data
    biome = definition
    _tracks = [{"points": corridor_data["points"], "widths": corridor_data["widths"], "capped": false}]
    for branch in corridor_data.get("branches", []):
        _tracks.append(branch)
    _configured = true
    if is_inside_tree():
        _build_runtime_children(light_count)
        queue_redraw()
    else:
        set_meta("pending_light_count", light_count)

func _ready() -> void:
    if not _configured:
        return
    _build_runtime_children(int(get_meta("pending_light_count", 0)))
    queue_redraw()

func _build_runtime_children(light_count: int) -> void:
    for child in get_children():
        child.queue_free()
    _lights.clear()
    _base_light_energy.clear()
    _light_phase.clear()
    _add_vein_overlays()
    _add_imported_wall_rims()
    _add_signal_lights(light_count)

func _add_vein_overlays() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = int(corridor_data["seed"]) ^ 0x7E1A5E
    for track_index in range(_tracks.size()):
        var track: Dictionary = _tracks[track_index]
        var points: PackedVector2Array = track["points"]
        var widths: PackedFloat32Array = track["widths"]
        if points.size() < 2:
            continue
        var line := Line2D.new()
        line.name = "PulsingVessel"
        line.points = _offset_path(points, widths, 0.31 if track_index == 0 else -0.24)
        line.width = rng.randf_range(2.8, 5.2)
        line.default_color = Color.WHITE
        line.antialiased = true
        var material := ShaderMaterial.new()
        material.shader = VEIN_SHADER
        material.set_shader_parameter("vein_color", biome.vein)
        material.set_shader_parameter("travel_speed", biome.pulse_speed)
        material.set_shader_parameter("travel_frequency", rng.randf_range(7.0, 13.0))
        material.set_shader_parameter("pulse_strength", 0.76 + biome.ambient_energy * 0.86)
        material.set_shader_parameter("amplitude_random", rng.randf_range(0.18, 0.46))
        material.set_shader_parameter("phase_offset", rng.randf_range(0.0, TAU))
        material.set_shader_parameter("core_intensity", 1.1 + biome.ambient_energy * 1.4)
        line.material = material
        line.z_index = 5
        add_child(line)

func _add_imported_wall_rims() -> void:
    var texture := AssetResolverScript.wall_piece(biome.id, "straight", int(corridor_data["seed"]))
    if texture == null or _tracks.is_empty():
        return
    var main_track: Dictionary = _tracks[0]
    var points: PackedVector2Array = main_track["points"]
    var widths: PackedFloat32Array = main_track["widths"]
    var texture_extent := maxf(texture.get_size().x, texture.get_size().y)
    for index in range(3, points.size() - 3, 6):
        var tangent := (points[index + 1] - points[index - 1]).normalized()
        var normal := tangent.orthogonal()
        for side in [-1.0, 1.0]:
            var rim := Sprite2D.new()
            rim.name = "ImportedWallRim"
            rim.texture = texture
            rim.position = points[index] + normal * widths[index] * side * 0.69
            rim.rotation = tangent.angle() + (PI if side < 0.0 else 0.0)
            rim.scale = Vector2.ONE * (widths[index] * 1.65 / maxf(texture_extent, 1.0))
            rim.modulate = Color(1.0, 1.0, 1.0, 0.28)
            rim.z_index = 3
            add_child(rim)

func _add_signal_lights(light_count: int) -> void:
    if light_count <= 0 or _tracks.is_empty():
        return
    var rng := RandomNumberGenerator.new()
    rng.seed = int(corridor_data["seed"]) ^ 0x1A77E5
    var main_track: Dictionary = _tracks[0]
    var points: PackedVector2Array = main_track["points"]
    for index in range(clampi(light_count, 0, 2)):
        var sample_index := clampi(int(float(points.size() - 1) * rng.randf_range(0.25, 0.75)), 0, points.size() - 1)
        var glow := BioGlowNode.new()
        glow.name = "CorridorSignal"
        glow.position = points[sample_index]
        glow.configure(biome.emissive, rng.randf_range(24.0, 44.0), 0.7 + biome.ambient_energy * 0.45, biome.pulse_speed, rng.randf_range(0.0, TAU))
        glow.z_index = 5
        add_child(glow)
        var point_light := BioLightFactoryScript.create_point_light(biome.light_color, 0.20 + biome.ambient_energy * 0.25, 100.0, 4)
        point_light.position = points[sample_index]
        point_light.add_to_group("phagos_active_lights")
        add_child(point_light)
        _lights.append(point_light)
        _base_light_energy.append(point_light.energy)
        _light_phase.append(rng.randf_range(0.0, TAU))

func _process(_delta: float) -> void:
    var time := Time.get_ticks_msec() * 0.001
    for index in range(_lights.size()):
        if is_instance_valid(_lights[index]):
            _lights[index].energy = _base_light_energy[index] * (0.92 + sin(time * biome.pulse_speed + _light_phase[index]) * 0.08)

func _draw() -> void:
    if not _configured:
        return
    for track in _tracks:
        _draw_track(track)

func _draw_track(track: Dictionary) -> void:
    var points: PackedVector2Array = track["points"]
    var widths: PackedFloat32Array = track["widths"]
    if points.size() < 2:
        return
    # Wall system: base tissue -> membrane folds -> micro cracks -> vessel overlays
    # (children) -> emissive highlights (children). The order deliberately avoids a
    # flat painted wall silhouette.
    draw_colored_polygon(_ribbon_polygon(points, widths, 50.0), biome.tissue_shadow)
    draw_colored_polygon(_ribbon_polygon(points, widths, 28.0), biome.tissue_base)
    draw_colored_polygon(_ribbon_polygon(points, widths, 0.0), biome.floor.darkened(0.10))
    var left := _edge_path(points, widths, 0.5)
    var right := _edge_path(points, widths, -0.5)
    # Dark outer cortex plus a narrow membrane highlight keeps every branching lumen
    # legible at a glance without turning it into a hard-edged dungeon hallway.
    draw_polyline(left, biome.tissue_shadow.darkened(0.10), 14.0, true)
    draw_polyline(right, biome.tissue_shadow.darkened(0.10), 14.0, true)
    draw_polyline(left, biome.membrane.darkened(0.30), 8.0, true)
    draw_polyline(right, biome.membrane.darkened(0.30), 8.0, true)
    draw_polyline(_edge_path(points, widths, 0.69), biome.tissue_shadow.lightened(0.12), 3.0, true)
    draw_polyline(_edge_path(points, widths, -0.69), biome.tissue_shadow.lightened(0.12), 3.0, true)
    _draw_membrane_folds(points, widths)
    _draw_cortical_fringe(points, widths)
    _draw_rim_organelle_clusters(points, widths)
    _draw_floor_cells(points, widths)
    _draw_micro_cracks(points, widths)
    if bool(track.get("capped", false)):
        draw_circle(points[points.size() - 1], widths[widths.size() - 1] * 0.25, biome.tissue_base, true, -1.0, true)

func _draw_membrane_folds(points: PackedVector2Array, widths: PackedFloat32Array) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = int(corridor_data["seed"]) ^ int(points.size() * 977)
    for index in range(2, points.size() - 2, 3):
        var tangent := (points[index + 1] - points[index - 1]).normalized()
        var normal := tangent.orthogonal()
        var side := 1.0 if rng.randf() > 0.5 else -1.0
        var center := points[index] + normal * widths[index] * side * rng.randf_range(0.43, 0.62)
        draw_line(center - tangent * widths[index] * 0.16, center + tangent * widths[index] * 0.16, biome.membrane.darkened(0.2), rng.randf_range(1.8, 4.2), true)

func _draw_cortical_fringe(points: PackedVector2Array, widths: PackedFloat32Array) -> void:
    # Short inward cilia break up the corridor rim into a living epithelial boundary.
    var rng := RandomNumberGenerator.new()
    rng.seed = int(corridor_data["seed"]) ^ int(points.size() * 0x41A7)
    for index in range(1, points.size() - 1, 2):
        var tangent := (points[index + 1] - points[index - 1]).normalized()
        var normal := tangent.orthogonal()
        for side in [-1.0, 1.0]:
            var rim := points[index] + normal * widths[index] * side * 0.48
            var toward_lumen := -normal * side
            var tuft_count := 2 if index % 4 == 1 else 1
            for tuft in range(tuft_count):
                var start := rim + tangent * rng.randf_range(-8.0, 8.0)
                var end := start + toward_lumen * rng.randf_range(7.0, 18.0) + tangent * rng.randf_range(-3.0, 3.0)
                var cilium := biome.membrane.lightened(rng.randf_range(0.03, 0.17))
                cilium.a = rng.randf_range(0.28, 0.56)
                draw_line(start, end, cilium, rng.randf_range(1.1, 2.4), true)
                var tip := biome.floor_secondary.lightened(0.14)
                tip.a = cilium.a * 0.82
                draw_circle(end, rng.randf_range(1.2, 2.8), tip, true, -1.0, true)

func _draw_rim_organelle_clusters(points: PackedVector2Array, widths: PackedFloat32Array) -> void:
    # Sparse vesicle groups imply biological density along the wall while leaving the
    # central path readable for the host game's future player/combat systems.
    var rng := RandomNumberGenerator.new()
    rng.seed = int(corridor_data["seed"]) ^ 0x0A71C
    for index in range(3, points.size() - 2, 5):
        var tangent := (points[index + 1] - points[index - 1]).normalized()
        var normal := tangent.orthogonal()
        var side := 1.0 if rng.randf() > 0.5 else -1.0
        var anchor := points[index] + normal * widths[index] * side * rng.randf_range(0.32, 0.43)
        for pod in range(rng.randi_range(2, 4)):
            var offset := tangent * rng.randf_range(-11.0, 11.0) + normal * side * rng.randf_range(-5.0, 8.0)
            var radius := rng.randf_range(2.5, 6.5)
            var pod_color := biome.floor_secondary.lightened(rng.randf_range(0.02, 0.19))
            pod_color.a = rng.randf_range(0.20, 0.48)
            draw_circle(anchor + offset, radius, pod_color, true, -1.0, true)
            if pod % 2 == 0:
                var core_color := biome.emissive
                core_color.a = pod_color.a * 0.56
                draw_circle(anchor + offset, radius * 0.33, core_color, true, -1.0, true)

func _draw_floor_cells(points: PackedVector2Array, widths: PackedFloat32Array) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = int(corridor_data["seed"]) ^ 0xCA117E
    for index in range(1, points.size() - 1, 2):
        var tangent := (points[index + 1] - points[index - 1]).normalized()
        var normal := tangent.orthogonal()
        var center := points[index] + normal * rng.randf_range(-0.22, 0.22) * widths[index]
        var radius := rng.randf_range(3.0, 9.0)
        var cell_color := biome.floor_secondary.darkened(rng.randf_range(0.10, 0.45))
        cell_color.a = 0.32
        draw_circle(center, radius, cell_color, true, -1.0, true)
        if rng.randf() > 0.60:
            draw_line(center - tangent * radius * 1.6, center + tangent * radius * 1.6, biome.membrane.darkened(0.42), 1.0, true)

func _draw_micro_cracks(points: PackedVector2Array, widths: PackedFloat32Array) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = int(corridor_data["seed"]) ^ 0xC2A5
    for index in range(2, points.size() - 2, 4):
        var tangent := (points[index + 1] - points[index - 1]).normalized()
        var normal := tangent.orthogonal()
        var side := 1.0 if rng.randf() > 0.5 else -1.0
        var start := points[index] + normal * widths[index] * side * rng.randf_range(0.57, 0.77)
        var end := start + tangent.rotated(side * rng.randf_range(0.35, 0.8)) * rng.randf_range(7.0, 19.0)
        draw_line(start, end, biome.tissue_shadow.lightened(0.11), 1.1, true)

func _ribbon_polygon(points: PackedVector2Array, widths: PackedFloat32Array, extra_half_width: float) -> PackedVector2Array:
    var left := _edge_path(points, widths, 0.5, extra_half_width)
    var right := _edge_path(points, widths, -0.5, extra_half_width)
    var polygon := PackedVector2Array()
    for point in left:
        polygon.append(point)
    for index in range(right.size() - 1, -1, -1):
        polygon.append(right[index])
    return polygon

func _edge_path(points: PackedVector2Array, widths: PackedFloat32Array, side: float, extra_half_width: float = 0.0) -> PackedVector2Array:
    var result := PackedVector2Array()
    for index in range(points.size()):
        var tangent: Vector2
        if index == 0:
            tangent = (points[1] - points[0]).normalized()
        elif index == points.size() - 1:
            tangent = (points[index] - points[index - 1]).normalized()
        else:
            tangent = (points[index + 1] - points[index - 1]).normalized()
        var normal := tangent.orthogonal()
        result.append(points[index] + normal * (widths[index] * side + extra_half_width * sign(side)))
    return result

func _offset_path(points: PackedVector2Array, widths: PackedFloat32Array, normalized_offset: float) -> PackedVector2Array:
    return _edge_path(points, widths, normalized_offset)
