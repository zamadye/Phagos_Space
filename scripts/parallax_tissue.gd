class_name BiologicalParallaxLayer
extends Node2D
## Lightweight world-space parallax. Each layer is a single CanvasItem and is intentionally
## decoupled from the room graph so it can extend beyond generated navigation geometry.

var biome: PhagosBiomeDefinition
var layer_kind := "background"
var parallax_factor := 0.08
var field_extent := 4200.0
var layer_seed := 1
var target_camera: Camera2D
var _configured := false

func configure(definition: PhagosBiomeDefinition, new_layer_kind: String, factor: float, seed_value: int, extent: float = 4200.0) -> void:
    biome = definition
    layer_kind = new_layer_kind
    parallax_factor = factor
    layer_seed = seed_value
    field_extent = extent
    _configured = true
    z_index = _z_for_kind()
    if layer_kind == "mid":
        var additive_material := CanvasItemMaterial.new()
        additive_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
        material = additive_material
    queue_redraw()

func set_camera(camera: Camera2D) -> void:
    target_camera = camera

func _process(_delta: float) -> void:
    if target_camera != null and is_instance_valid(target_camera):
        # Camera motion of 1.0 becomes only factor motion for this field.
        global_position = target_camera.global_position * (1.0 - parallax_factor)
    if layer_kind == "foreground":
        queue_redraw()

func _draw() -> void:
    if not _configured:
        return
    var rng := RandomNumberGenerator.new()
    rng.seed = layer_seed
    match layer_kind:
        "background": _draw_background_tissue(rng)
        "mid": _draw_mid_veins(rng)
        "foreground": _draw_foreground_cells(rng)

func _draw_background_tissue(rng: RandomNumberGenerator) -> void:
    var count := 44
    for index in range(count):
        var point := Vector2(rng.randf_range(-field_extent, field_extent), rng.randf_range(-field_extent, field_extent))
        var radius := rng.randf_range(130.0, 470.0)
        var color := biome.tissue_base.darkened(rng.randf_range(0.25, 0.55))
        color.a = rng.randf_range(0.09, 0.22)
        draw_circle(point, radius, color, true, -1.0, true)
        if index % 2 == 0:
            var fold_color := biome.membrane.darkened(0.45)
            fold_color.a = color.a * 0.62
            var fold_radius := radius * rng.randf_range(0.62, 0.88)
            var fold_start := rng.randf_range(0.0, TAU)
            var fold_end := fold_start + rng.randf_range(1.8, 4.0)
            draw_arc(point, fold_radius, fold_start, fold_end, 18, fold_color, rng.randf_range(7.0, 18.0), true)

func _draw_mid_veins(rng: RandomNumberGenerator) -> void:
    for index in range(36):
        var start := Vector2(rng.randf_range(-field_extent, field_extent), rng.randf_range(-field_extent, field_extent))
        var direction := Vector2(cos(rng.randf_range(0.0, TAU)), sin(rng.randf_range(0.0, TAU)))
        var normal := direction.orthogonal()
        var length := rng.randf_range(120.0, 500.0)
        var middle := start + direction * length * 0.48 + normal * rng.randf_range(-80.0, 80.0)
        var end := start + direction * length
        var color := biome.vein.darkened(0.32)
        color.a = rng.randf_range(0.13, 0.31)
        draw_line(start, middle, color, rng.randf_range(2.0, 5.0), true)
        draw_line(middle, end, color, rng.randf_range(1.2, 3.5), true)
        if rng.randf() > 0.45:
            var branch_end := middle + normal * rng.randf_range(-90.0, 90.0) + direction * rng.randf_range(10.0, 80.0)
            draw_line(middle, branch_end, color.darkened(0.18), 1.4, true)

func _draw_foreground_cells(rng: RandomNumberGenerator) -> void:
    var time := Time.get_ticks_msec() * 0.001
    for index in range(34):
        var base := Vector2(rng.randf_range(-field_extent, field_extent), rng.randf_range(-field_extent, field_extent))
        var offset := Vector2(sin(time * 0.18 + index * 1.7), cos(time * 0.16 + index * 0.93)) * 8.0
        var radius := rng.randf_range(12.0, 45.0)
        var color := biome.floor_secondary.lightened(0.12)
        color.a = rng.randf_range(0.08, 0.22)
        draw_circle(base + offset, radius, color, true, -1.0, true)
        var rim := biome.particle
        rim.a = color.a * 0.85
        draw_arc(base + offset, radius * 0.80, -2.5, 0.65, 12, rim, 1.4, true)

func _z_for_kind() -> int:
    match layer_kind:
        "background": return -20
        "mid": return -10
        _: return 12
