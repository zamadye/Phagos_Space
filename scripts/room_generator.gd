class_name RoomGenerator
extends RefCounted
## Produces a readable, non-rectilinear room graph. Geometry is intentionally separate
## from the graph so encounter design can swap layouts without touching rendering.

const ROOM_TYPES := {
    "spawn": {"size": Vector2(448, 410), "importance": 0.7},
    "combat": {"size": Vector2(560, 480), "importance": 0.9},
    "elite": {"size": Vector2(610, 550), "importance": 1.15},
    "shop": {"size": Vector2(420, 390), "importance": 0.55},
    "upgrade": {"size": Vector2(455, 430), "importance": 0.62},
    "boss": {"size": Vector2(1110, 970), "importance": 2.0},
    "secret": {"size": Vector2(390, 355), "importance": 0.38},
}

## A hand-authored topology gives good routing readability. Per-seed displacement and
## edge curvature stop it from becoming a fixed square dungeon.
const GRAPH_TEMPLATE := [
    {"id": "spawn", "type": "spawn", "anchor": Vector2(0, 0)},
    {"id": "combat_a", "type": "combat", "anchor": Vector2(800, -155)},
    {"id": "combat_b", "type": "combat", "anchor": Vector2(510, 760)},
    {"id": "upgrade", "type": "upgrade", "anchor": Vector2(-650, 590)},
    {"id": "secret", "type": "secret", "anchor": Vector2(-865, -430)},
    {"id": "elite", "type": "elite", "anchor": Vector2(1510, 460)},
    {"id": "shop", "type": "shop", "anchor": Vector2(1280, -620)},
    {"id": "boss", "type": "boss", "anchor": Vector2(2630, 75)},
]

const EDGE_TEMPLATE := [
    {"id": "spawn_to_combat_a", "from": "spawn", "to": "combat_a", "width": 192.0, "branch": false},
    {"id": "spawn_to_combat_b", "from": "spawn", "to": "combat_b", "width": 168.0, "branch": true},
    {"id": "spawn_to_upgrade", "from": "spawn", "to": "upgrade", "width": 144.0, "branch": true},
    {"id": "spawn_to_secret", "from": "spawn", "to": "secret", "width": 112.0, "branch": false},
    {"id": "secret_to_upgrade", "from": "secret", "to": "upgrade", "width": 96.0, "branch": true},
    {"id": "combat_a_to_elite", "from": "combat_a", "to": "elite", "width": 192.0, "branch": false},
    {"id": "combat_a_to_shop", "from": "combat_a", "to": "shop", "width": 154.0, "branch": true},
    {"id": "combat_b_to_elite", "from": "combat_b", "to": "elite", "width": 176.0, "branch": false},
    {"id": "combat_b_to_upgrade", "from": "combat_b", "to": "upgrade", "width": 128.0, "branch": true},
    {"id": "elite_to_boss", "from": "elite", "to": "boss", "width": 192.0, "branch": false},
    {"id": "shop_to_boss", "from": "shop", "to": "boss", "width": 160.0, "branch": false},
]

func generate(seed_value: int, biome: PhagosBiomeDefinition, world_scale: float = 1.0) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value if seed_value != 0 else 817391
    var rooms: Array[Dictionary] = []
    var index_by_id: Dictionary = {}

    for template in GRAPH_TEMPLATE:
        var room_type: String = template["type"]
        var type_settings: Dictionary = ROOM_TYPES[room_type]
        var base_size: Vector2 = type_settings["size"] * world_scale
        var is_spawn := room_type == "spawn"
        var jitter_amount := 0.0 if is_spawn else 84.0 * (0.75 + biome.room_jitter)
        var offset := Vector2(
            rng.randf_range(-jitter_amount, jitter_amount),
            rng.randf_range(-jitter_amount, jitter_amount)
        )
        var aspect_jitter := Vector2(rng.randf_range(0.91, 1.10), rng.randf_range(0.91, 1.10))
        var room := {
            "id": template["id"],
            "type": room_type,
            "position": (template["anchor"] * world_scale) + offset,
            "size": base_size * aspect_jitter,
            "importance": type_settings["importance"],
            "seed": rng.randi(),
            "entrances": [],
        }
        index_by_id[room["id"]] = rooms.size()
        rooms.append(room)

    var edges: Array[Dictionary] = []
    for edge_template in EDGE_TEMPLATE:
        var edge := edge_template.duplicate(true)
        edge["width"] = float(edge["width"]) * world_scale
        edge["seed"] = rng.randi()
        edge["curve_bias"] = rng.randf_range(-1.0, 1.0) * biome.corridor_curvature
        edge["widening"] = rng.randf_range(-0.19, 0.22)
        edges.append(edge)
        _register_entrances(rooms, index_by_id, edge)

    return {
        "seed": rng.seed,
        "rooms": rooms,
        "edges": edges,
        "bounds": _graph_bounds(rooms),
    }

func _register_entrances(rooms: Array[Dictionary], index_by_id: Dictionary, edge: Dictionary) -> void:
    var from_index: int = index_by_id[edge["from"]]
    var to_index: int = index_by_id[edge["to"]]
    var from_room: Dictionary = rooms[from_index]
    var to_room: Dictionary = rooms[to_index]
    var direction := (to_room["position"] - from_room["position"]).normalized()
    var reverse_direction := -direction

    var from_entrances: Array = from_room["entrances"]
    from_entrances.append({
        "edge_id": edge["id"],
        "angle": direction.angle(),
        "width": edge["width"],
        "outbound": true,
    })
    from_room["entrances"] = from_entrances
    rooms[from_index] = from_room

    var to_entrances: Array = to_room["entrances"]
    to_entrances.append({
        "edge_id": edge["id"],
        "angle": reverse_direction.angle(),
        "width": edge["width"],
        "outbound": false,
    })
    to_room["entrances"] = to_entrances
    rooms[to_index] = to_room

func _graph_bounds(rooms: Array[Dictionary]) -> Rect2:
    var bounds := Rect2()
    var first := true
    for room in rooms:
        var size: Vector2 = room["size"]
        var room_rect := Rect2(room["position"] - size * 0.68, size * 1.36)
        if first:
            bounds = room_rect
            first = false
        else:
            bounds = bounds.merge(room_rect)
    return bounds.grow(360.0)

static func room_type_settings(room_type: String) -> Dictionary:
    return ROOM_TYPES.get(room_type, ROOM_TYPES["combat"])
