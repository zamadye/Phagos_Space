class_name BiologicalParticleField
extends Node2D
## Browser-first biological ambience. GPUParticles2D is used when available on the
## Compatibility/WebGL renderer; a deterministic batched CanvasItem simulation remains a
## zero-crash fallback for constrained GPUs, headless capture, and QA reproduction.

@export var prefer_gpu_particles := true
@export var force_cpu_particles := false

var biome: PhagosBiomeDefinition
var world_bounds := Rect2(-1800, -1200, 5200, 3000)
var particle_count := 128
var _particles: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _configured := false
var _backend := "cpu"
var _particle_texture: Texture2D

func configure(definition: PhagosBiomeDefinition, seed_value: int, bounds: Rect2, count: int = 128, allow_gpu_particles: bool = true) -> void:
    biome = definition
    world_bounds = bounds
    particle_count = clampi(count, 24, 220)
    _rng.seed = seed_value ^ 0xA71C1E
    _configured = true
    add_to_group("phagos_particle_fields")
    _clear_gpu_layers()
    if _should_use_gpu(allow_gpu_particles):
        _backend = "gpu"
        _particles.clear()
        _build_gpu_layers()
        set_process(false)
    else:
        _backend = "cpu"
        _particles.clear()
        for index in range(particle_count):
            _particles.append(_new_particle(true))
        var material := CanvasItemMaterial.new()
        material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
        self.material = material
        set_process(true)
    queue_redraw()

func get_backend_name() -> String:
    return _backend

func get_active_particle_count() -> int:
    if _backend == "gpu":
        var total := 0
        for child in get_children():
            var emitter := child as GPUParticles2D
            if emitter != null and emitter.emitting:
                total += emitter.amount
        return total
    return _particles.size()

func _should_use_gpu(allow_gpu_particles: bool) -> bool:
    if not allow_gpu_particles or not prefer_gpu_particles or force_cpu_particles:
        return false
    if bool(ProjectSettings.get_setting("phagos/particles/force_cpu", false)):
        return false
    # Headless does not have a display backend. On native and WebGL displays, GPUParticles2D
    # remains the preferred path; the exported force_cpu flag retains a deterministic fallback.
    return DisplayServer.get_name().to_lower() != "headless"

func _clear_gpu_layers() -> void:
    for child in get_children():
        child.queue_free()

func _build_gpu_layers() -> void:
    var dust_color := biome.fog
    dust_color.a = maxf(0.16, biome.fog.a + 0.12)
    _add_gpu_layer("PlasmaDust", {
        "amount": int(particle_count * 0.48), "lifetime": 8.5, "color": dust_color,
        "min_velocity": 4.0, "max_velocity": 14.0, "min_scale": 0.22,
        "max_scale": 0.78, "min_orbit": 0.0, "max_orbit": 0.0, "burst": false,
    })
    _add_gpu_layer("Cytokines", {
        "amount": int(particle_count * 0.32), "lifetime": 6.8, "color": biome.vein,
        "min_velocity": 5.0, "max_velocity": 12.0, "min_scale": 0.10,
        "max_scale": 0.28, "min_orbit": -0.035, "max_orbit": 0.035, "burst": false,
    })
    _add_gpu_layer("ATPSparks", {
        "amount": max(12, int(particle_count * 0.20)), "lifetime": 1.45, "color": biome.emissive,
        "min_velocity": 34.0, "max_velocity": 88.0, "min_scale": 0.06,
        "max_scale": 0.18, "min_orbit": 0.0, "max_orbit": 0.0, "burst": true,
    })

func _add_gpu_layer(layer_name: String, settings: Dictionary) -> void:
    var amount := int(settings["amount"])
    var lifetime := float(settings["lifetime"])
    var particle_color: Color = settings["color"]
    var min_velocity := float(settings["min_velocity"])
    var max_velocity := float(settings["max_velocity"])
    var min_scale := float(settings["min_scale"])
    var max_scale := float(settings["max_scale"])
    var min_orbit := float(settings["min_orbit"])
    var max_orbit := float(settings["max_orbit"])
    var burst := bool(settings["burst"])
    var particles := GPUParticles2D.new()
    particles.name = layer_name
    particles.amount = max(1, amount)
    particles.lifetime = lifetime
    particles.lifetime_randomness = 0.38
    particles.randomness = 0.55
    particles.explosiveness = 0.84 if burst else 0.0
    particles.preprocess = lifetime
    particles.position = world_bounds.get_center()
    particles.visibility_rect = world_bounds.grow(240.0)
    particles.local_coords = false
    particles.texture = _get_particle_texture()
    particles.emitting = true

    var process := ParticleProcessMaterial.new()
    process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    process.emission_box_extents = Vector3(world_bounds.size.x * 0.5, world_bounds.size.y * 0.5, 0.0)
    process.direction = Vector3(1.0, 0.0, 0.0)
    process.spread = 180.0
    process.gravity = Vector3.ZERO
    process.initial_velocity_min = min_velocity
    process.initial_velocity_max = max_velocity
    process.damping_min = 0.28 if burst else 0.65
    process.damping_max = 1.4 if burst else 2.2
    process.scale_min = min_scale
    process.scale_max = max_scale
    process.angular_velocity_min = -45.0
    process.angular_velocity_max = 45.0
    process.orbit_velocity_min = min_orbit
    process.orbit_velocity_max = max_orbit
    if layer_name == "PlasmaDust":
        # One low-strength turbulence field supplies drift without the cost of per-node CPU motion.
        process.turbulence_enabled = true
        process.turbulence_noise_strength = 0.18
        process.turbulence_noise_scale = 16.0
        process.turbulence_noise_speed = Vector3(0.10, -0.06, 0.0)
        process.turbulence_influence_min = 0.05
        process.turbulence_influence_max = 0.13
    process.color_ramp = _make_color_ramp(particle_color, burst)
    particles.process_material = process

    var additive := CanvasItemMaterial.new()
    additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    particles.material = additive
    particles.z_index = 9
    add_child(particles)

func _get_particle_texture() -> Texture2D:
    if _particle_texture != null:
        return _particle_texture
    var size := 64
    var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
    var center := Vector2(size - 1, size - 1) * 0.5
    for y in range(size):
        for x in range(size):
            var distance := Vector2(x, y).distance_to(center) / (size * 0.5)
            var alpha := pow(maxf(0.0, 1.0 - distance), 2.25)
            image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
    _particle_texture = ImageTexture.create_from_image(image)
    return _particle_texture

func _make_color_ramp(color: Color, burst: bool) -> GradientTexture1D:
    var gradient := Gradient.new()
    var hot := color.lightened(0.36)
    var middle := color
    var tail := color.darkened(0.18)
    hot.a = 0.0
    middle.a = 0.84 if burst else 0.48
    tail.a = 0.0
    gradient.offsets = PackedFloat32Array([0.0, 0.14, 0.72, 1.0])
    gradient.colors = PackedColorArray([hot, color, middle, tail])
    var texture := GradientTexture1D.new()
    texture.gradient = gradient
    return texture

func _process(delta: float) -> void:
    if not _configured or _backend != "cpu":
        return
    for index in range(_particles.size()):
        var particle: Dictionary = _particles[index]
        particle["age"] = float(particle["age"]) + delta
        var turbulence := Vector2(
            sin(float(particle["age"]) * 0.71 + float(particle["phase"])),
            cos(float(particle["age"]) * 0.53 + float(particle["phase"]) * 0.61)
        ) * float(particle["turbulence"])
        var orbit := Vector2(-particle["velocity"].y, particle["velocity"].x).normalized() * float(particle["orbit"]) * delta
        particle["velocity"] = (particle["velocity"] + turbulence * delta + orbit).limit_length(float(particle["max_speed"]))
        particle["position"] = particle["position"] + particle["velocity"] * delta
        if float(particle["age"]) > float(particle["life"]) or not world_bounds.grow(180.0).has_point(particle["position"]):
            particle = _new_particle(false)
        _particles[index] = particle
    queue_redraw()

func _draw() -> void:
    if not _configured or _backend != "cpu":
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
                var direction: Vector2 = particle["velocity"].normalized()
                draw_line(position_value - direction * radius * 2.2, position_value + direction * radius * 0.8, color, 1.3, true)
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
        match _rng.randi_range(0, 3):
            0: position_value.x = world_bounds.position.x - 80.0
            1: position_value.x = world_bounds.end.x + 80.0
            2: position_value.y = world_bounds.position.y - 80.0
            _: position_value.y = world_bounds.end.y + 80.0
    var speed := _rng.randf_range(4.0, 16.0)
    if kind == "atp_spark":
        speed = _rng.randf_range(34.0, 82.0)
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
        "orbit": _rng.randf_range(-0.3, 0.3) if kind == "cytokine" else 0.0,
        "phase": _rng.randf_range(0.0, TAU),
        "age": _rng.randf_range(0.0, 4.0) if initial else 0.0,
        "life": _rng.randf_range(6.0, 18.0) if kind != "atp_spark" else _rng.randf_range(0.8, 1.8),
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
