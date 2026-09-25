class_name OrganicRoom
extends Node2D
## A radial, irregular room renderer. No tiles or orthogonal wall modules are used at
## runtime: a shared graph creates living chamber silhouettes from a seeded contour.

const CYTOPLASM_SHADER = preload("res://shaders/cytoplasm_flow.gdshader")
const MEMBRANE_SHADER = preload("res://shaders/membrane_distort.gdshader")
const VEIN_SHADER = preload("res://shaders/vein_pulse.gdshader")
const BioGlowNode = preload("res://scripts/bio_glow.gd")
const BioLightFactoryScript = preload("res://scripts/bio_light_factory.gd")
const AssetResolverScript = preload("res://scripts/asset_resolver.gd")

var room_data: Dictionary
var biome: PhagosBiomeDefinition
var _outer_contour := PackedVector2Array()
var _wall_contour := PackedVector2Array()
var _inner_contour := PackedVector2Array()
var _lights: Array[PointLight2D] = []
var _base_light_energy: Array[float] = []
var _light_phase: Array[float] = []
var _configured := false

func configure(data: Dictionary, definition: PhagosBiomeDefinition, light_count: int = 1) -> void:
    room_data = data
    biome = definition
    position = room_data["position"]
    _build_contours()
    _configured = true
    if is_inside_tree():
        _build_runtime_children(light_count)
        queue_redraw()
    else:
        set_meta("pending_light_count", light_count)

func _ready() -> void:
    if not _configured:
        return
    _build_runtime_children(int(get_meta("pending_light_count", 1)))
    queue_redraw()

func _build_contours() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = int(room_data["seed"])
    var size: Vector2 = room_data["size"]
    var point_count := 34 if room_data["type"] == "boss" else 26
    var phase := rng.randf_range(0.0, TAU)
    _outer_contour = PackedVector2Array()
    for index in range(point_count):
        var t := float(index) / float(point_count)
        var angle := t * TAU + phase
        var macro_wave := sin(t * TAU * rng.randi_range(2, 4) + phase) * 0.055
        var jitter := rng.randf_range(-biome.room_jitter, biome.room_jitter) * 0.19
        var breathing := 1.0 + macro_wave + jitter
        var point := Vector2(cos(angle) * size.x * 0.5, sin(angle) * size.y * 0.5) * breathing
        _outer_contour.append(point)
    _wall_contour = _scale_contour(_outer_contour, 0.925)
    _inner_contour = _scale_contour(_outer_contour, 0.770)

func _build_runtime_children(light_count: int) -> void:
    # Configure can be called more than once by a level streamer.
    for child in get_children():
        child.queue_free()
    _lights.clear()
    _base_light_energy.clear()
    _light_phase.clear()
    _add_floor_layers()
    _add_vein_overlays()
    _add_biological_lights(light_count)

func _add_floor_layers() -> void:
    var floor_polygon := Polygon2D.new()
    floor_polygon.name = "CytoplasmFlow"
    floor_polygon.polygon = _inner_contour
    floor_polygon.uv = _contour_uv(_inner_contour)
    var floor_material := ShaderMaterial.new()
    floor_material.shader = CYTOPLASM_SHADER
    var floor_parameters := biome.shader_floor_parameters(float(int(room_data["seed"]) % 10000) * 0.0001)
    for parameter in floor_parameters:
        floor_material.set_shader_parameter(parameter, floor_parameters[parameter])
    var uv_rng := RandomNumberGenerator.new()
    uv_rng.seed = int(room_data["seed"]) ^ 0xF1002
    floor_material.set_shader_parameter("uv_offset", Vector2(uv_rng.randf(), uv_rng.randf()))
    floor_material.set_shader_parameter("uv_rotation", uv_rng.randf_range(0.0, TAU))
    floor_polygon.material = floor_material
    floor_polygon.z_index = 1
    add_child(floor_polygon)

    var membrane_overlay := Polygon2D.new()
    membrane_overlay.name = "MembraneDistortion"
    membrane_overlay.polygon = _scale_contour(_inner_contour, 0.985)
    membrane_overlay.uv = _contour_uv(_inner_contour)
    var membrane_material := ShaderMaterial.new()
    membrane_material.shader = MEMBRANE_SHADER
    membrane_material.set_shader_parameter("membrane_color", biome.membrane)
    membrane_material.set_shader_parameter("movement_speed", biome.pulse_speed * 0.13)
    membrane_material.set_shader_parameter("ridge_density", 8.0 + biome.decoration_density * 3.0)
    membrane_material.set_shader_parameter("opacity", 0.16)
    membrane_material.set_shader_parameter("seed", float(int(room_data["seed"]) % 5000) * 0.001)
    membrane_overlay.material = membrane_material
    membrane_overlay.z_index = 2
    add_child(membrane_overlay)

    # Final art is optional: correctly named seamless PNGs are clipped by the same
    # organic contour, so importing them never converts the room into a square tile.
    var imported_floor := AssetResolverScript.floor_overlay(biome.id, int(room_data["seed"]))
    if imported_floor != null:
        var art_overlay := Polygon2D.new()
        art_overlay.name = "ImportedFloorOverlay"
        art_overlay.polygon = _scale_contour(_inner_contour, 0.975)
        art_overlay.uv = _contour_texture_uv(_inner_contour, imported_floor.get_size())
        art_overlay.texture = imported_floor
        art_overlay.modulate = Color(1.0, 1.0, 1.0, 0.52)
        art_overlay.z_index = 3
        add_child(art_overlay)

func _add_vein_overlays() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = int(room_data["seed"]) ^ 0x5F3759DF
    var vein_count := 3 if room_data["type"] == "boss" else 2
    for vein_index in range(vein_count):
        var points := PackedVector2Array()
        var start_index := rng.randi_range(0, _outer_contour.size() - 1)
        var length := rng.randi_range(5, 10)
        for offset in range(length):
            var contour_index := (start_index + offset) % _outer_contour.size()
            var inward := rng.randf_range(0.81, 0.93)
            points.append(_outer_contour[contour_index] * inward)
        var vein := Line2D.new()
        vein.name = "EmissiveVein"
        vein.points = points
        vein.width = rng.randf_range(3.0, 6.5)
        vein.default_color = Color.WHITE
        vein.antialiased = true
        var material := ShaderMaterial.new()
        material.shader = VEIN_SHADER
        material.set_shader_parameter("vein_color", biome.vein)
        material.set_shader_parameter("pulse_speed", biome.pulse_speed)
        material.set_shader_parameter("pulse_strength", 0.8 + biome.ambient_energy * 0.8)
        material.set_shader_parameter("phase_offset", rng.randf_range(0.0, TAU))
        material.set_shader_parameter("core_intensity", 1.3 + biome.ambient_energy * 1.6)
        vein.material = material
        vein.z_index = 4
        add_child(vein)

func _add_biological_lights(light_count: int) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = int(room_data["seed"]) ^ 0xB10F00D
    var cap := clampi(light_count, 0, 5)
    var size: Vector2 = room_data["size"]
    for light_index in range(cap):
        var angle := rng.randf_range(0.0, TAU)
        var radial := sqrt(rng.randf()) * 0.46
        var local_position := Vector2(cos(angle) * size.x * radial, sin(angle) * size.y * radial)
        var glow := BioGlowNode.new()
        glow.name = "SignalGlow"
        glow.position = local_position
        glow.configure(biome.emissive, rng.randf_range(34.0, 72.0), 1.2 + biome.ambient_energy, biome.pulse_speed, rng.randf_range(0.0, TAU))
        glow.z_index = 5
        add_child(glow)

        var point_light := BioLightFactoryScript.create_point_light(
            biome.light_color,
            0.35 + biome.ambient_energy * 0.45,
            rng.randf_range(145.0, 235.0),
            3
        )
        point_light.position = local_position
        add_child(point_light)
        _lights.append(point_light)
        _base_light_energy.append(point_light.energy)
        _light_phase.append(rng.randf_range(0.0, TAU))

func _process(_delta: float) -> void:
    if _lights.is_empty():
        return
    var time := Time.get_ticks_msec() * 0.001
    for index in range(_lights.size()):
        if not is_instance_valid(_lights[index]):
            continue
        var pulse := 0.90 + sin(time * biome.pulse_speed + _light_phase[index]) * 0.10
        _lights[index].energy = _base_light_energy[index] * pulse

func _draw() -> void:
    if not _configured:
        return
    # Layer 1: living tissue mass. Layer 2+ draw only stochastic details; the shader
    # children supply the moving cytoplasm and membranes above this safe fallback floor.
    draw_colored_polygon(_outer_contour, biome.tissue_shadow)
    draw_colored_polygon(_wall_contour, biome.tissue_base)
    draw_colored_polygon(_inner_contour, biome.floor.darkened(0.14))
    draw_polyline(_closed(_outer_contour), biome.tissue_shadow.lightened(0.18), 18.0, true)
    draw_polyline(_closed(_wall_contour), biome.membrane.darkened(0.36), 8.0, true)
    _draw_membrane_folds()
    _draw_micro_cracks()
    _draw_static_tissue_decoration()
    _draw_entrance_handoffs()

func _draw_membrane_folds() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = int(room_data["seed"]) ^ 0xA53C91
    for index in range(20):
        var angle := rng.randf_range(0.0, TAU)
        var radial := rng.randf_range(0.80, 0.93)
        var tangent := Vector2(cos(angle), sin(angle)).orthogonal()
        var center := Vector2(cos(angle) * room_data["size"].x * 0.5 * radial, sin(angle) * room_data["size"].y * 0.5 * radial)
        var half_length := rng.randf_range(15.0, 42.0)
        draw_line(center - tangent * half_length, center + tangent * half_length, biome.membrane.darkened(rng.randf_range(0.18, 0.42)), rng.randf_range(2.0, 5.0), true)

func _draw_micro_cracks() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = int(room_data["seed"]) ^ 0xC0FFEE
    for index in range(30):
        var point := _random_inner_point(rng, 0.73)
        var angle := rng.randf_range(0.0, TAU)
        var length := rng.randf_range(5.0, 18.0)
        var end := point + Vector2(cos(angle), sin(angle)) * length
        draw_line(point, end, biome.tissue_shadow.lightened(0.11), rng.randf_range(0.7, 1.4), true)
        if rng.randf() > 0.58:
            var split := point.lerp(end, 0.55)
            draw_line(split, split + (end - point).rotated(rng.randf_range(-0.85, 0.85)) * 0.45, biome.tissue_shadow.lightened(0.08), 0.8, true)

func _draw_static_tissue_decoration() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = int(room_data["seed"]) ^ 0xD3C0A7
    var decoration_count := int(18.0 * biome.decoration_density)
    for index in range(decoration_count):
        var point := _random_inner_point(rng, 0.69)
        var radius := rng.randf_range(3.0, 12.0)
        var color := biome.floor_secondary.darkened(rng.randf_range(0.12, 0.45))
        color.a = rng.randf_range(0.24, 0.58)
        draw_circle(point, radius, color, true, -1.0, true)
        if index % 3 == 0:
            draw_arc(point, radius * 1.55, rng.randf_range(0.0, TAU), rng.randf_range(0.0, TAU) + 1.4, 8, biome.membrane.darkened(0.35), 1.1, true)

func _draw_entrance_handoffs() -> void:
    var entrances: Array = room_data.get("entrances", [])
    for entrance in entrances:
        var angle: float = entrance["angle"]
        var direction := Vector2(cos(angle), sin(angle))
        var normal := direction.orthogonal()
        var room_radius := _radius_to_edge(direction)
        var width := minf(float(entrance["width"]) * 0.46, room_radius * 0.55)
        var center := direction * room_radius * 0.90
        draw_line(center - normal * width, center + normal * width, biome.floor_secondary.darkened(0.12), 20.0, true)
        draw_line(center - normal * width, center + normal * width, biome.membrane.darkened(0.34), 3.0, true)

func _random_inner_point(rng: RandomNumberGenerator, max_radial: float) -> Vector2:
    var angle := rng.randf_range(0.0, TAU)
    var radial := sqrt(rng.randf()) * max_radial
    var size: Vector2 = room_data["size"]
    return Vector2(cos(angle) * size.x * 0.5 * radial, sin(angle) * size.y * 0.5 * radial)

func _radius_to_edge(direction: Vector2) -> float:
    var size: Vector2 = room_data["size"]
    var half_size := size * 0.5
    var denom := sqrt((direction.x * direction.x) / (half_size.x * half_size.x) + (direction.y * direction.y) / (half_size.y * half_size.y))
    return 1.0 / maxf(denom, 0.001)

func _scale_contour(source: PackedVector2Array, scale: float) -> PackedVector2Array:
    var result := PackedVector2Array()
    for point in source:
        result.append(point * scale)
    return result

func _contour_uv(source: PackedVector2Array) -> PackedVector2Array:
    var size: Vector2 = room_data["size"]
    var result := PackedVector2Array()
    for point in source:
        result.append(Vector2(point.x / size.x + 0.5, point.y / size.y + 0.5))
    return result

func _contour_texture_uv(source: PackedVector2Array, texture_size: Vector2) -> PackedVector2Array:
    var size: Vector2 = room_data["size"]
    var result := PackedVector2Array()
    for point in source:
        var normalized := Vector2(point.x / size.x + 0.5, point.y / size.y + 0.5)
        result.append(normalized * texture_size)
    return result

func _closed(source: PackedVector2Array) -> PackedVector2Array:
    var result := PackedVector2Array()
    for point in source:
        result.append(point)
    if not source.is_empty():
        result.append(source[0])
    return result
