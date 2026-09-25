class_name PropSpawner
extends RefCounted
## Deterministic decoration placement. Categories are deliberately separated so art can
## tune readability without accidentally increasing animated or breakable prop costs.

const BreakablePropNode = preload("res://scripts/breakable_prop.gd")

const STATIC_KINDS := PackedStringArray(["collagen_fiber", "membrane_ridge", "tissue_chunk"])
const SEMI_ANIMATED_KINDS := PackedStringArray(["protein_vesicle", "plasma_bubble", "cytokine_crystal"])
const ANIMATED_KINDS := PackedStringArray(["moving_vesicle", "oxygen_particle", "immune_signal_light"])
const BREAKABLE_KINDS := PackedStringArray(["membrane_sac", "calcified_chunk", "protein_pod", "atp_pool"])

func populate(parent: Node2D, graph: Dictionary, biome: PhagosBiomeDefinition, seed_value: int) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value ^ 0x51A77E
    var counters := {"static": 0, "semi_animated": 0, "animated": 0, "breakable": 0}
    var rooms: Array = graph.get("rooms", [])

    for room in rooms:
        var room_type: String = room["type"]
        var importance: float = float(room["importance"])
        # Boss rooms get more static anatomy but no gameplay assumptions are encoded here.
        var static_count := clampi(int((3.0 + importance * 3.0) * biome.decoration_density), 3, 10)
        var semi_count := 1 if room_type in ["secret", "shop"] else clampi(int(1.0 + importance), 1, 3)
        var animated_count := 1 if room_type != "boss" else 2
        var breakable_count := 1 if room_type in ["spawn", "shop"] else clampi(int(1.0 + importance * 0.8), 1, 3)

        for index in range(static_count):
            _spawn_prop(parent, _pick_kind(STATIC_KINDS, biome, rng), _room_point(room, rng, 0.22, 0.67), biome, rng.randi(), false, false)
            counters["static"] += 1
        for index in range(semi_count):
            _spawn_prop(parent, _pick_kind(SEMI_ANIMATED_KINDS, biome, rng), _room_point(room, rng, 0.16, 0.61), biome, rng.randi(), false, true)
            counters["semi_animated"] += 1
        for index in range(animated_count):
            _spawn_prop(parent, _pick_kind(ANIMATED_KINDS, biome, rng), _room_point(room, rng, 0.22, 0.58), biome, rng.randi(), false, true)
            counters["animated"] += 1
        for index in range(breakable_count):
            _spawn_prop(parent, _pick_kind(BREAKABLE_KINDS, biome, rng), _room_point(room, rng, 0.28, 0.63), biome, rng.randi(), true, false)
            counters["breakable"] += 1

    _populate_corridor_edges(parent, graph.get("edges", []), biome, rng, counters)
    return counters

func _populate_corridor_edges(parent: Node2D, edges: Array, biome: PhagosBiomeDefinition, rng: RandomNumberGenerator, counters: Dictionary) -> void:
    # Corridor anatomy uses the exact spline produced by CorridorBuilder. It is sparse
    # enough to preserve movement lanes while ensuring no hall reads as empty.
    for edge in edges:
        if rng.randf() > 0.78:
            continue
        var geometry: Dictionary = edge.get("geometry", {})
        var points: PackedVector2Array = geometry.get("points", PackedVector2Array())
        var widths: PackedFloat32Array = geometry.get("widths", PackedFloat32Array())
        if points.size() < 3 or widths.is_empty():
            continue
        var point_index := rng.randi_range(1, points.size() - 2)
        var tangent := (points[point_index + 1] - points[point_index - 1]).normalized()
        var normal := tangent.orthogonal()
        var side := 1.0 if rng.randf() > 0.5 else -1.0
        var location := points[point_index] + normal * widths[point_index] * side * rng.randf_range(0.46, 0.62)
        _spawn_prop(parent, _pick_kind(STATIC_KINDS, biome, rng), location, biome, rng.randi(), false, false)
        counters["static"] += 1

func _spawn_prop(parent: Node2D, kind: String, location: Vector2, biome: PhagosBiomeDefinition, seed_value: int, is_breakable: bool, is_animated: bool) -> void:
    var prop := BreakablePropNode.new()
    prop.name = "Prop_%s" % kind
    prop.position = location
    prop.z_index = 6
    prop.configure(kind, biome, seed_value, is_breakable, is_animated)
    if is_breakable:
        prop.add_to_group("phagos_breakable_props")
    parent.add_child(prop)

func _room_point(room: Dictionary, rng: RandomNumberGenerator, min_radial: float, max_radial: float) -> Vector2:
    var angle := rng.randf_range(0.0, TAU)
    var radial := sqrt(rng.randf_range(min_radial * min_radial, max_radial * max_radial))
    var size: Vector2 = room["size"]
    return room["position"] + Vector2(cos(angle) * size.x * 0.5 * radial, sin(angle) * size.y * 0.5 * radial)

func _pick_kind(kinds: PackedStringArray, biome: PhagosBiomeDefinition, rng: RandomNumberGenerator) -> String:
    # Biome-weighted nudges retain a shared kit while making each organ legible.
    if biome.id == &"lung" and kinds.has("plasma_bubble") and rng.randf() < 0.45:
        return "plasma_bubble"
    if biome.id == &"brain" and kinds.has("cytokine_crystal") and rng.randf() < 0.45:
        return "cytokine_crystal"
    if biome.id == &"marrow" and kinds.has("calcified_chunk") and rng.randf() < 0.42:
        return "calcified_chunk"
    if biome.id == &"heart" and kinds.has("membrane_sac") and rng.randf() < 0.38:
        return "membrane_sac"
    return kinds[rng.randi_range(0, kinds.size() - 1)]
