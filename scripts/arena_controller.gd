class_name PhagosArenaController
extends Node2D
## Main assembly point for the arena-only deliverable. It intentionally creates no player,
## combat, HUD, pickup, or encounter logic. A host game only needs set_player_target() to
## bind its player cell to the camera after this environment has been generated.

const BiomeLoaderScript = preload("res://scripts/biome_loader.gd")
const RoomGeneratorScript = preload("res://scripts/room_generator.gd")
const CorridorBuilderScript = preload("res://scripts/corridor_builder.gd")
const OrganicRoomNode = preload("res://scripts/organic_room.gd")
const OrganicCorridorNode = preload("res://scripts/organic_corridor.gd")
const PropSpawnerScript = preload("res://scripts/prop_spawner.gd")
const ParticleFieldNode = preload("res://scripts/biological_particles.gd")
const ParallaxLayerNode = preload("res://scripts/parallax_tissue.gd")
const AccentFieldNode = preload("res://scripts/biome_accents.gd")
const AssetResolverScript = preload("res://scripts/asset_resolver.gd")
const DebugOverlayNode = preload("res://scripts/debug_performance_overlay.gd")

@export_enum("heart", "lung", "brain", "marrow") var preview_biome := "heart"
@export var generation_seed := 8142026
@export_range(0.75, 1.35, 0.05) var world_scale := 1.0
@export_range(48, 220, 1) var atmospheric_particle_budget := 132
@export_range(8, 32, 1) var point_light_budget := 20
@export var prefer_gpu_particles := true

var biome: PhagosBiomeDefinition
var room_graph: Dictionary = {}
var _runtime: Node2D
var _camera: Camera2D
var _camera_focus: Node2D
var _room_generator := RoomGeneratorScript.new()
var _prop_spawner := PropSpawnerScript.new()

func _ready() -> void:
    _camera = get_node_or_null("Camera2D") as Camera2D
    _camera_focus = get_node_or_null("CameraFocus") as Node2D
    if _camera_focus == null:
        _camera_focus = Node2D.new()
        _camera_focus.name = "CameraFocus"
        add_child(_camera_focus)
    if _camera == null:
        push_warning("PhagosArenaController needs a Camera2D child. Arena generation still completed.")
    AssetResolverScript.warmup()
    if OS.is_debug_build():
        _install_debug_overlay()
    call_deferred("generate_arena")

func _install_debug_overlay() -> void:
    var overlay := DebugOverlayNode.new()
    overlay.name = "DebugPerformanceOverlay"
    overlay.configure(self)
    add_child(overlay)

func generate_arena(requested_biome: StringName = &"") -> void:
    var biome_id := requested_biome
    if biome_id == &"":
        biome_id = BiomeLoaderScript.normalize_biome_id(preview_biome)
    biome = BiomeLoaderScript.load_biome(biome_id)
    RenderingServer.set_default_clear_color(biome.backdrop)
    _apply_ambient_tint()

    if _runtime != null and is_instance_valid(_runtime):
        _runtime.queue_free()
    _runtime = Node2D.new()
    _runtime.name = "ArenaRuntime"
    add_child(_runtime)

    room_graph = _room_generator.generate(generation_seed, biome, world_scale)
    var graph_bounds: Rect2 = room_graph["bounds"]
    _build_parallax(graph_bounds)
    _build_biome_accents(graph_bounds)
    _build_rooms_and_corridors()
    _build_decorations_and_particles(graph_bounds)
    _configure_camera(graph_bounds)

func set_player_target(player_node: Node2D) -> void:
    ## Host-game integration API. The arena never instantiates a character itself.
    if _camera != null and _camera.has_method("set_follow_target"):
        _camera.call("set_follow_target", player_node)

func reset_camera_to_spawn() -> void:
    if _camera != null and _camera.has_method("set_follow_target"):
        _camera.call("set_follow_target", _camera_focus)

func get_spawn_position() -> Vector2:
    for room in room_graph.get("rooms", []):
        if room["type"] == "spawn":
            return room["position"]
    return Vector2.ZERO

func get_room_graph() -> Dictionary:
    return room_graph.duplicate(true)

func get_performance_snapshot() -> Dictionary:
    var active_lights := 0
    for node in get_tree().get_nodes_in_group("phagos_active_lights"):
        var light_node := node as CanvasItem
        if light_node != null and light_node.visible:
            active_lights += 1
    var active_particles := 0
    var particle_backend := "cpu"
    for field in get_tree().get_nodes_in_group("phagos_particle_fields"):
        if not is_instance_valid(field):
            continue
        if field.has_method("get_active_particle_count"):
            active_particles += int(field.call("get_active_particle_count"))
        if field.has_method("get_backend_name"):
            particle_backend = String(field.call("get_backend_name"))
    var camera_position := _camera.global_position if _camera != null else _camera_focus.global_position
    var asset_status := AssetResolverScript.get_status()
    return {
        "active_lights": active_lights,
        "active_particles": active_particles,
        "particle_backend": particle_backend,
        "room_id": _room_id_at_position(camera_position),
        "asset_fallback": bool(asset_status.get("fallback_active", true)),
    }

func _room_id_at_position(world_position: Vector2) -> String:
    for room in room_graph.get("rooms", []):
        var center: Vector2 = room["position"]
        var size: Vector2 = room["size"]
        var local := world_position - center
        var ellipse_distance := (local.x * local.x) / maxf(size.x * size.x * 0.30, 1.0) + (local.y * local.y) / maxf(size.y * size.y * 0.30, 1.0)
        if ellipse_distance <= 1.0:
            return "%s · %s" % [String(room["id"]).to_upper(), String(room["type"]).to_upper()]
    return "CONNECTIVE TISSUE"

func _apply_ambient_tint() -> void:
    var ambient := get_node_or_null("BiomeAmbientTint") as CanvasModulate
    if ambient == null:
        ambient = BiomeLoaderScript.make_canvas_modulate(biome)
        add_child(ambient)
    else:
        ambient.color = BiomeLoaderScript.make_canvas_modulate(biome).color

func _build_parallax(graph_bounds: Rect2) -> void:
    var expanded_extent := maxf(graph_bounds.size.x, graph_bounds.size.y) * 1.25
    var background := ParallaxLayerNode.new()
    background.name = "BackgroundTissue"
    background.configure(biome, "background", 0.05, generation_seed ^ 0x101, expanded_extent)
    background.set_camera(_camera)
    _runtime.add_child(background)

    var mid := ParallaxLayerNode.new()
    mid.name = "MidVeins"
    mid.configure(biome, "mid", 0.15, generation_seed ^ 0x202, expanded_extent)
    mid.set_camera(_camera)
    _runtime.add_child(mid)

func _build_biome_accents(graph_bounds: Rect2) -> void:
    var accents := AccentFieldNode.new()
    accents.name = "%sAnatomy" % biome.display_name.replace(" ", "")
    accents.configure(biome, generation_seed, graph_bounds.grow(520.0))
    accents.z_index = -2
    _runtime.add_child(accents)

func _build_rooms_and_corridors() -> void:
    var room_layer := Node2D.new()
    room_layer.name = "OrganicRooms"
    _runtime.add_child(room_layer)
    var corridor_layer := Node2D.new()
    corridor_layer.name = "SplineCorridors"
    _runtime.add_child(corridor_layer)

    var room_by_id: Dictionary = {}
    var remaining_lights := point_light_budget
    for room_data in room_graph["rooms"]:
        room_by_id[room_data["id"]] = room_data
        var room := OrganicRoomNode.new()
        room.name = "Room_%s" % room_data["id"]
        var desired_lights := _room_light_count(room_data["type"])
        var allocated_lights := mini(desired_lights, remaining_lights)
        remaining_lights -= allocated_lights
        room.configure(room_data, biome, allocated_lights)
        room_layer.add_child(room)

    var edges: Array = room_graph["edges"]
    for edge_index in range(edges.size()):
        var edge: Dictionary = edges[edge_index]
        var from_room: Dictionary = room_by_id[edge["from"]]
        var to_room: Dictionary = room_by_id[edge["to"]]
        var geometry := CorridorBuilderScript.build(edge, from_room, to_room, biome)
        edge["geometry"] = geometry
        edges[edge_index] = edge
        var corridor := OrganicCorridorNode.new()
        corridor.name = "Corridor_%s" % edge["id"]
        var corridor_lights := 1 if remaining_lights > 0 and edge_index % 3 == 0 else 0
        remaining_lights -= corridor_lights
        corridor.configure(geometry, biome, corridor_lights)
        corridor.z_index = 2
        corridor_layer.add_child(corridor)
    room_graph["edges"] = edges

func _build_decorations_and_particles(graph_bounds: Rect2) -> void:
    var prop_layer := Node2D.new()
    prop_layer.name = "ProceduralDecorations"
    _runtime.add_child(prop_layer)
    _prop_spawner.populate(prop_layer, room_graph, biome, generation_seed)

    var particles := ParticleFieldNode.new()
    particles.name = "BiologicalParticles"
    particles.z_index = 9
    particles.prefer_gpu_particles = prefer_gpu_particles
    particles.configure(biome, generation_seed, graph_bounds.grow(480.0), atmospheric_particle_budget, prefer_gpu_particles)
    _runtime.add_child(particles)

    var foreground := ParallaxLayerNode.new()
    foreground.name = "ForegroundProteins"
    foreground.configure(biome, "foreground", 0.30, generation_seed ^ 0x303, maxf(graph_bounds.size.x, graph_bounds.size.y) * 1.25)
    foreground.set_camera(_camera)
    _runtime.add_child(foreground)

func _configure_camera(graph_bounds: Rect2) -> void:
    var spawn_position := get_spawn_position()
    _camera_focus.global_position = spawn_position
    if _camera == null:
        return
    _camera.limit_left = int(graph_bounds.position.x)
    _camera.limit_top = int(graph_bounds.position.y)
    _camera.limit_right = int(graph_bounds.end.x)
    _camera.limit_bottom = int(graph_bounds.end.y)
    if _camera.has_method("set_follow_target"):
        _camera.call("set_follow_target", _camera_focus)
    else:
        _camera.global_position = spawn_position

func _room_light_count(room_type: String) -> int:
    match room_type:
        "boss": return 4
        "elite": return 2
        "combat": return 1
        "spawn", "shop", "upgrade": return 1
        _: return 0
