class_name BiomeAccentField
extends Node2D
## Biome-specific anatomy beyond palette. Kept as a batched field so Heart, Lung, Brain,
## and Marrow can have unique structural language without turning the arena into a tile set.

const AssetResolverScript = preload("res://scripts/asset_resolver.gd")

var biome: PhagosBiomeDefinition
var bounds := Rect2(-1800, -1200, 5200, 3000)
var accent_seed := 1
var _configured := false

func configure(definition: PhagosBiomeDefinition, seed_value: int, new_bounds: Rect2) -> void:
    biome = definition
    accent_seed = seed_value
    bounds = new_bounds
    _configured = true
    if biome.id in [&"heart", &"brain"]:
        var additive := CanvasItemMaterial.new()
        additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
        material = additive
    if is_inside_tree():
        _build_imported_overlay()
    queue_redraw()

func _ready() -> void:
    if _configured:
        _build_imported_overlay()

func _build_imported_overlay() -> void:
    for child in get_children():
        child.queue_free()
    var category := ""
    match biome.id:
        &"lung": category = "alveoli"
        &"brain": category = "neuron_network"
        &"marrow": category = "marrow_cavity"
        _: return
    var texture := AssetResolverScript.resolve_texture(category, biome.id, "", accent_seed)
    if texture == null:
        return
    var overlay := Sprite2D.new()
    overlay.name = "ImportedBiomeOverlay"
    overlay.texture = texture
    overlay.position = bounds.get_center()
    var texture_extent := maxf(texture.get_size().x, texture.get_size().y)
    overlay.scale = Vector2.ONE * (maxf(bounds.size.x, bounds.size.y) * 0.54 / maxf(texture_extent, 1.0))
    overlay.rotation = float(posmod(accent_seed, 628)) * 0.01
    overlay.modulate = Color(1.0, 1.0, 1.0, 0.34)
    overlay.z_index = -1
    add_child(overlay)

func _draw() -> void:
    if not _configured:
        return
    var rng := RandomNumberGenerator.new()
    rng.seed = accent_seed ^ 0xB10A11
    match biome.id:
        &"heart": _draw_heart_vessels(rng)
        &"lung": _draw_lung_alveoli(rng)
        &"brain": _draw_brain_network(rng)
        &"marrow": _draw_marrow_cavities(rng)

func _random_point(rng: RandomNumberGenerator) -> Vector2:
    return Vector2(rng.randf_range(bounds.position.x, bounds.end.x), rng.randf_range(bounds.position.y, bounds.end.y))

func _draw_heart_vessels(rng: RandomNumberGenerator) -> void:
    for index in range(22):
        var start := _random_point(rng)
        var direction := Vector2(cos(rng.randf_range(0.0, TAU)), sin(rng.randf_range(0.0, TAU)))
        var normal := direction.orthogonal()
        var length := rng.randf_range(220.0, 720.0)
        var mid := start + direction * length * 0.48 + normal * rng.randf_range(-120.0, 120.0)
        var end := start + direction * length
        var vessel_color := biome.vein
        vessel_color.a = rng.randf_range(0.10, 0.24)
        draw_line(start, mid, vessel_color, rng.randf_range(10.0, 24.0), true)
        draw_line(mid, end, vessel_color.darkened(0.20), rng.randf_range(7.0, 18.0), true)
        draw_arc(mid, rng.randf_range(50.0, 150.0), rng.randf_range(0.0, TAU), rng.randf_range(0.0, TAU) + 2.0, 14, biome.membrane.darkened(0.24), 4.0, true)

func _draw_lung_alveoli(rng: RandomNumberGenerator) -> void:
    for cluster in range(26):
        var center := _random_point(rng)
        var cluster_radius := rng.randf_range(65.0, 170.0)
        for cell in range(rng.randi_range(4, 9)):
            var angle := rng.randf_range(0.0, TAU)
            var radius := rng.randf_range(18.0, 47.0)
            var point := center + Vector2(cos(angle), sin(angle)) * rng.randf_range(0.0, cluster_radius)
            var fill := biome.floor_secondary
            fill.a = rng.randf_range(0.06, 0.16)
            draw_circle(point, radius, fill, true, -1.0, true)
            var membrane := biome.membrane
            membrane.a = 0.18
            draw_arc(point, radius * 0.88, 0.0, TAU, 14, membrane, 1.5, true)

func _draw_brain_network(rng: RandomNumberGenerator) -> void:
    for neuron in range(34):
        var soma := _random_point(rng)
        var soma_color := biome.emissive
        soma_color.a = 0.15
        draw_circle(soma, rng.randf_range(5.0, 13.0), soma_color, true, -1.0, true)
        for branch in range(rng.randi_range(2, 4)):
            var direction := Vector2(cos(rng.randf_range(0.0, TAU)), sin(rng.randf_range(0.0, TAU)))
            var joint := soma + direction * rng.randf_range(35.0, 105.0)
            var end := joint + direction.rotated(rng.randf_range(-0.68, 0.68)) * rng.randf_range(40.0, 140.0)
            var axon_color := biome.vein
            axon_color.a = 0.19
            draw_line(soma, joint, axon_color, rng.randf_range(1.2, 3.2), true)
            draw_line(joint, end, axon_color.darkened(0.12), 1.2, true)
            draw_circle(end, 3.0, biome.emissive, true, -1.0, true)

func _draw_marrow_cavities(rng: RandomNumberGenerator) -> void:
    for index in range(32):
        var center := _random_point(rng)
        var radius := rng.randf_range(30.0, 100.0)
        var fat_color := biome.membrane.lightened(0.10)
        fat_color.a = rng.randf_range(0.07, 0.16)
        draw_circle(center, radius, fat_color, true, -1.0, true)
        var cavity := biome.tissue_shadow
        cavity.a = 0.25
        draw_circle(center + Vector2(rng.randf_range(-12.0, 12.0), rng.randf_range(-12.0, 12.0)), radius * 0.34, cavity, true, -1.0, true)
        var rim := biome.particle
        rim.a = 0.20
        draw_arc(center, radius * 0.84, -2.6, 0.65, 14, rim, 2.3, true)
