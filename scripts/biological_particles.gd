class_name BiologicalParticleField
extends Node2D
## One batched CanvasItem for cytokines, ATP sparks, plasma mist, and immune dust.
## This is intentionally not hundreds of animated Sprite2D nodes; all particles share
## one draw call path and deterministic turbulence for a stable 60 FPS desktop budget.

var biome: PhagosBiomeDefinition
var world_bounds := Rect2(-1800, -1200, 5200, 3000)
var particle_count := 128
var _particles: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _configured := false

func configure(definition: PhagosBiomeDefinition, seed_value: int, bounds: Rect2, count: int = 128) -> void:
    biome = definition
    world_bounds = bounds
    particle_count = clampi(count, 24, 220)
    _rng.seed = seed_value ^ 0xA71C1E
    _particles.clear()
    for index in range(particle_count):
        _particles.append(_new_particle(true))
    _configured = true
    var material := CanvasItemMaterial.new()
    material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    self.material = material
    queue_redraw()

func _process(delta: float) -> void:
    if not _configured:
        return
    for index in range(_particles.size()):
        var particle: Dictionary = _particles[index]
        particle["age"] = float(particle["age"]) + delta
        var turbulence := Vector2(
            sin(float(particle["age"]) * 0.71 + float(particle["phase"])),
            cos(float(particle["age"]) * 0.53 + float(particle["phase"]) * 0.61)
        ) * float(particle["turbulence"])
        particle["velocity"] = (particle["velocity"] + turbulence * delta).limit_length(float(particle["max_speed"]))
        particle["position"] = particle["position"] + particle["velocity"] * delta
        if float(particle["age"]) > float(particle["life"]) or not world_bounds.grow(180.0).has_point(particle["position"]):
            particle = _new_particle(false)
        _particles[index] = particle
    queue_redraw()

func _draw() -> void:
    if not _configured:
        return
    for particle in _particles:
        var life_progress := float(particle["age"]) / float(particle["life"])
        var envelope := sin(clampf(life_progress, 0.0, 1.0) * PI)
        var color: Color = particle["color"]
        color.a *= envelope * float(particle["opacity"])
        var position_value: Vector2 = particle["position"]
        var radius: float = float(particle["radius"])
        match particle["kind"]:
            "atp_spark":
                draw_line(position_value - particle["velocity"].normalized() * radius * 2.2, position_value + particle["velocity"].normalized() * radius * 0.8, color, 1.3, true)
                draw_circle(position_value, radius * 0.55, color.lightened(0.20), true, -1.0, true)
            "plasma_mist":
                draw_circle(position_value, radius * 2.3, color, true, -1.0, true)
            "plasma_bubble":
                draw_arc(position_value, radius, -2.8, -0.25, 9, color, 1.0, true)
            _:
                draw_circle(position_value, radius, color, true, -1.0, true)

func _new_particle(initial: bool) -> Dictionary:
    var kind := _choose_kind()
    var position_value := Vector2(
        _rng.randf_range(world_bounds.position.x, world_bounds.end.x),
        _rng.randf_range(world_bounds.position.y, world_bounds.end.y)
    )
    if not initial:
        # Re-enter from a random edge so the field retains a gentle directed circulation.
        match _rng.randi_range(0, 3):
            0: position_value.x = world_bounds.position.x - 80.0
            1: position_value.x = world_bounds.end.x + 80.0
            2: position_value.y = world_bounds.position.y - 80.0
            _: position_value.y = world_bounds.end.y + 80.0
    var speed := _rng.randf_range(4.0, 16.0)
    var direction := Vector2(cos(_rng.randf_range(0.0, TAU)), sin(_rng.randf_range(0.0, TAU)))
    return {
        "kind": kind,
        "position": position_value,
        "velocity": direction * speed,
        "max_speed": speed * 1.8,
        "radius": _particle_radius(kind),
        "color": _particle_color(kind),
        "opacity": _rng.randf_range(0.20, 0.68),
        "turbulence": _rng.randf_range(1.5, 9.0),
        "phase": _rng.randf_range(0.0, TAU),
        "age": _rng.randf_range(0.0, 4.0) if initial else 0.0,
        "life": _rng.randf_range(6.0, 18.0),
    }

func _choose_kind() -> String:
    var roll := _rng.randf()
    if biome.id == &"lung":
        return "plasma_mist" if roll < 0.42 else ("plasma_bubble" if roll < 0.70 else "immune_dust")
    if biome.id == &"brain":
        return "atp_spark" if roll < 0.40 else ("cytokine" if roll < 0.72 else "immune_dust")
    if biome.id == &"marrow":
        return "cytokine" if roll < 0.36 else ("plasma_bubble" if roll < 0.63 else "immune_dust")
    return "atp_spark" if roll < 0.35 else ("cytokine" if roll < 0.68 else "immune_dust")

func _particle_radius(kind: String) -> float:
    match kind:
        "plasma_mist": return _rng.randf_range(18.0, 54.0)
        "plasma_bubble": return _rng.randf_range(5.0, 18.0)
        "atp_spark": return _rng.randf_range(1.5, 3.8)
        "cytokine": return _rng.randf_range(3.0, 7.0)
        _: return _rng.randf_range(1.0, 3.2)

func _particle_color(kind: String) -> Color:
    match kind:
        "plasma_mist": return biome.fog
        "plasma_bubble": return biome.particle
        "atp_spark": return biome.emissive
        "cytokine": return biome.vein
        _: return biome.particle.darkened(0.10)
