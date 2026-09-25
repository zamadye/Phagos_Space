class_name BreakableProp
extends Node2D
## Environment-only destructible visual. It intentionally has no health, combat, loot, or
## player dependency: a future interaction system can call break_open() when appropriate.

const BioGlowNode = preload("res://scripts/bio_glow.gd")
const AssetResolverScript = preload("res://scripts/asset_resolver.gd")
const BioLightFactoryScript = preload("res://scripts/bio_light_factory.gd")

var prop_kind := "membrane_sac"
var biome: PhagosBiomeDefinition
var prop_seed := 1
var can_break := true
var animated := false
var _broken := false
var _age := 0.0
var _phase := 0.0
var _debris: Array[Dictionary] = []
var _glow: BioGlow
var _prop_light: PointLight2D
var _prop_light_base_energy := 0.0
var _imported_art: Sprite2D
var _configured := false

func configure(new_kind: String, definition: PhagosBiomeDefinition, new_seed: int, breakable: bool = true, should_animate: bool = false) -> void:
    prop_kind = new_kind
    biome = definition
    prop_seed = new_seed
    can_break = breakable
    animated = should_animate
    var rng := RandomNumberGenerator.new()
    rng.seed = prop_seed
    _phase = rng.randf_range(0.0, TAU)
    _configured = true
    if is_inside_tree():
        _build_runtime_children()
        set_process(animated or _broken)
        queue_redraw()

func _ready() -> void:
    if _configured:
        _build_runtime_children()
        set_process(animated)
        queue_redraw()

func _build_runtime_children() -> void:
    for child in get_children():
        child.queue_free()
    _glow = null
    _prop_light = null
    _prop_light_base_energy = 0.0
    _imported_art = null
    if prop_kind in ["cytokine_crystal", "atp_pool", "immune_signal_light"]:
        _glow = BioGlowNode.new()
        _glow.name = "PropGlow"
        _glow.configure(biome.emissive, _nominal_radius() * 2.2, 0.72, biome.pulse_speed, _phase)
        _glow.z_index = -1
        add_child(_glow)
        # Only a deterministic minority owns a real Light2D; the rest retain a cheap
        # additive glow, preserving the global environment light budget.
        if posmod(prop_seed, 5) == 0:
            _prop_light = BioLightFactoryScript.create_point_light(biome.light_color, 0.24, 86.0, 1)
            _prop_light_base_energy = _prop_light.energy
            add_child(_prop_light)
    var imported_sprite := AssetResolverScript.prop_sprite(prop_kind, prop_seed)
    if imported_sprite != null:
        var sprite := Sprite2D.new()
        sprite.name = "ImportedPropArt"
        sprite.texture = imported_sprite
        var master_size := maxf(imported_sprite.get_size().x, imported_sprite.get_size().y)
        sprite.scale = Vector2.ONE * (_nominal_radius() * 2.65 / maxf(master_size, 1.0))
        sprite.z_index = 2
        add_child(sprite)
        _imported_art = sprite

func break_open() -> void:
    if _broken or not can_break:
        return
    _broken = true
    _age = 0.0
    if _imported_art != null and is_instance_valid(_imported_art):
        _imported_art.visible = false
    var rng := RandomNumberGenerator.new()
    rng.seed = prop_seed ^ 0xDEB215
    _debris.clear()
    for index in range(rng.randi_range(7, 13)):
        var angle := rng.randf_range(0.0, TAU)
        _debris.append({
            "position": Vector2.ZERO,
            "velocity": Vector2(cos(angle), sin(angle)) * rng.randf_range(48.0, 155.0),
            "radius": rng.randf_range(2.0, 7.0),
            "spin": rng.randf_range(-7.0, 7.0),
        })
    set_process(true)
    queue_redraw()

func _process(delta: float) -> void:
    if not _configured:
        return
    _age += delta
    if _broken:
        for index in range(_debris.size()):
            var particle: Dictionary = _debris[index]
            particle["position"] = particle["position"] + particle["velocity"] * delta
            particle["velocity"] = particle["velocity"] * pow(0.025, delta)
            _debris[index] = particle
        var break_fade := clampf(1.0 - _age * 1.55, 0.0, 1.0)
        if _glow != null and is_instance_valid(_glow):
            _glow.modulate.a = break_fade
        if _prop_light != null and is_instance_valid(_prop_light):
            _prop_light.energy = _prop_light_base_energy * break_fade
        if _age > 1.35:
            queue_free()
        queue_redraw()
    elif animated:
        queue_redraw()

func _draw() -> void:
    if not _configured:
        return
    if _broken:
        _draw_debris()
        return
    var bob := sin(Time.get_ticks_msec() * 0.001 * (0.65 + biome.pulse_speed * 0.20) + _phase) * (2.4 if animated else 0.5)
    draw_set_transform(Vector2(0.0, bob), 0.0, Vector2.ONE)
    match prop_kind:
        "collagen_fiber":
            _draw_collagen_fiber()
        "membrane_ridge":
            _draw_membrane_ridge()
        "tissue_chunk":
            _draw_tissue_chunk()
        "protein_vesicle", "moving_vesicle":
            _draw_protein_vesicle()
        "plasma_bubble", "oxygen_particle":
            _draw_plasma_bubble()
        "cytokine_crystal", "immune_signal_light":
            _draw_cytokine_crystal()
        "calcified_chunk":
            _draw_calcified_chunk()
        "protein_pod":
            _draw_protein_pod()
        "atp_pool":
            _draw_atp_pool()
        _:
            _draw_membrane_sac()
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_membrane_sac() -> void:
    var radius := _nominal_radius()
    draw_circle(Vector2.ZERO, radius * 1.16, biome.tissue_shadow, true, -1.0, true)
    draw_circle(Vector2.ZERO, radius, biome.tissue_base.lightened(0.08), true, -1.0, true)
    draw_circle(Vector2(-radius * 0.22, -radius * 0.22), radius * 0.43, biome.membrane.darkened(0.15), true, -1.0, true)

func _draw_collagen_fiber() -> void:
    var radius := _nominal_radius()
    draw_line(Vector2(-radius * 1.8, -radius * 0.34), Vector2(radius * 1.8, radius * 0.34), biome.membrane.darkened(0.18), radius * 0.34, true)
    draw_line(Vector2(-radius * 1.55, radius * 0.40), Vector2(radius * 1.55, -radius * 0.40), biome.tissue_base.lightened(0.10), radius * 0.17, true)

func _draw_membrane_ridge() -> void:
    var radius := _nominal_radius()
    for index in range(3):
        var offset := (float(index) - 1.0) * radius * 0.42
        var ridge_color := biome.membrane.darkened(0.16 + index * 0.08)
        draw_circle(Vector2(offset, 0), radius * 0.54, ridge_color, true, -1.0, true)

func _draw_tissue_chunk() -> void:
    var radius := _nominal_radius()
    draw_circle(Vector2(-radius * 0.24, radius * 0.12), radius * 0.72, biome.tissue_shadow, true, -1.0, true)
    draw_circle(Vector2(radius * 0.28, -radius * 0.17), radius * 0.66, biome.tissue_base, true, -1.0, true)
    draw_circle(Vector2(-radius * 0.16, -radius * 0.25), radius * 0.28, biome.floor_secondary.darkened(0.21), true, -1.0, true)

func _draw_protein_vesicle() -> void:
    var radius := _nominal_radius()
    draw_circle(Vector2.ZERO, radius, biome.floor_secondary.lightened(0.09), true, -1.0, true)
    draw_circle(Vector2(-radius * 0.25, -radius * 0.28), radius * 0.38, biome.membrane.lightened(0.10), true, -1.0, true)
    draw_line(Vector2(-radius * 0.58, -radius * 0.47), Vector2(radius * 0.62, -radius * 0.20), biome.particle, 1.5, true)

func _draw_plasma_bubble() -> void:
    var radius := _nominal_radius() * 0.75
    var bubble_color := biome.particle
    bubble_color.a = 0.28
    draw_circle(Vector2.ZERO, radius, bubble_color, true, -1.0, true)
    draw_circle(Vector2(-radius * 0.28, -radius * 0.31), radius * 0.23, biome.particle.lightened(0.20), true, -1.0, true)
    draw_line(Vector2(-radius * 0.62, -radius * 0.55), Vector2(radius * 0.08, -radius * 0.72), biome.particle, 1.5, true)

func _draw_cytokine_crystal() -> void:
    var radius := _nominal_radius()
    draw_circle(Vector2.ZERO, radius * 0.58, biome.emissive.darkened(0.18), true, -1.0, true)
    draw_line(Vector2(0, -radius), Vector2(radius * 0.46, radius * 0.78), biome.particle, 1.6, true)
    draw_line(Vector2(radius * 0.46, radius * 0.78), Vector2(-radius * 0.48, radius * 0.66), biome.particle, 1.6, true)

func _draw_calcified_chunk() -> void:
    var radius := _nominal_radius()
    draw_circle(Vector2(-radius * 0.20, radius * 0.10), radius * 0.72, biome.membrane.lightened(0.25), true, -1.0, true)
    draw_circle(Vector2(radius * 0.30, -radius * 0.20), radius * 0.54, biome.membrane.lightened(0.16), true, -1.0, true)
    draw_line(Vector2(-radius * 0.48, -radius * 0.52), Vector2(radius * 0.40, radius * 0.50), biome.tissue_shadow.lightened(0.12), 2.2, true)

func _draw_protein_pod() -> void:
    var radius := _nominal_radius()
    draw_circle(Vector2.ZERO, radius, biome.tissue_base, true, -1.0, true)
    draw_circle(Vector2.ZERO, radius * 0.70, biome.floor_secondary.darkened(0.08), true, -1.0, true)
    draw_circle(Vector2(cos(_phase), sin(_phase)) * radius * 0.46, radius * 0.22, biome.membrane.lightened(0.06), true, -1.0, true)

func _draw_atp_pool() -> void:
    var radius := _nominal_radius() * 1.35
    var pool_color := biome.emissive
    pool_color.a = 0.26
    draw_ellipse(Vector2.ZERO, Vector2(radius * 1.5, radius * 0.72), pool_color)
    draw_line(Vector2(-radius * 0.72, sin(_phase) * radius * 0.18), Vector2(radius * 0.72, sin(_phase + 1.6) * radius * 0.18), biome.particle, 1.4, true)

func _draw_debris() -> void:
    var fade := clampf(1.0 - _age / 1.35, 0.0, 1.0)
    for piece in _debris:
        var debris_color := biome.membrane
        debris_color.a = fade
        draw_circle(piece["position"], piece["radius"] * fade, debris_color, true, -1.0, true)
        var tail_color := biome.emissive
        tail_color.a = fade
        draw_line(piece["position"], piece["position"] - piece["velocity"].normalized() * 7.0, tail_color, 1.2, true)

func _nominal_radius() -> float:
    var rng := RandomNumberGenerator.new()
    rng.seed = prop_seed
    return rng.randf_range(9.0, 22.0)

func draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
    # A capsule is a safer WebGL/Compatibility fill than a dynamically triangulated polygon.
    # It still reads as a flattened ATP pool while avoiding tessellation edge cases on drivers.
    var radius := maxf(minf(radii.x, radii.y), 0.5)
    var half_span := maxf(radii.x - radius, 0.0)
    # Two overlapping discs make a soft organic capsule without a polygon or rectangle batch.
    draw_circle(center + Vector2(-half_span * 0.55, 0.0), radius, color, true, -1.0, true)
    draw_circle(center + Vector2(half_span * 0.55, 0.0), radius, color, true, -1.0, true)
