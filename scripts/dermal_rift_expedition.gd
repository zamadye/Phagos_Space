class_name DermalRiftExpedition
extends Node2D
## Playable exploration-adventure vertical slice for PHAGOS.
##
## This scene loads the authored Dermal Rift graph, constructs collidable cavities, gives
## the player a traversal controller, changes routes in response to organ states, and
## exposes native Godot UI for objective, discovery, map, and state warnings. It is the
## runtime implementation of the plan — not a static art board or browser simulation.

const TraversalCellScript = preload("res://scripts/traversal_cell.gd")
const WorldScript = preload("res://scripts/dermal_rift_world.gd")
const HudScript = preload("res://scripts/expedition_hud.gd")

const PLAN_PATH := "res://data/organ_biomes/dermal_rift.json"
const WORLD_RECT := Rect2(0.0, 0.0, 6400.0, 3600.0)
const GRID_CELL := 80.0
const AUTO_STATE_INTERVAL := 18.0
const TRANSITION_PREVIEW_SECONDS := 2.2
const INTERACTION_RADIUS := 190.0

var _plan: Dictionary = {}
var _nodes: Dictionary = {}
var _links: Array = []
var _states: Array = []
var _state_index := 0
var _current_layout: Dictionary = {}
var _player: TraversalCell
var _world: DermalRiftWorld
var _hud: ExpeditionHud
var _collision_root: Node2D
var _discovered: Dictionary = {}
var _cavity_attuned := false
var _completed := false
var _state_elapsed := 0.0
var _pending_state_index := -1
var _pending_seconds := 0.0
var _last_safe_anchor := "surface_breach"
var _collision_body_count := 0


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.025, 0.02, 0.07, 1.0))
	_load_plan()
	_index_plan()
	_create_world()
	_create_collision_root()
	_current_layout = _layout_for_state(_state_index)
	_world.set_layout(_current_layout)
	_rebuild_collision()
	_create_player()
	_create_hud()
	_refresh_exploration()
	_refresh_interface()
	_hud.announce("Explore the living dermis. Move with WASD or arrow keys.", 4.8)


func _process(delta: float) -> void:
	if _plan.is_empty() or _player == null:
		return
	_update_state_director(delta)
	_refresh_exploration()
	_refresh_interface()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_E, KEY_ENTER, KEY_SPACE:
			_try_interact()
		KEY_R:
			_request_next_state(true)
		KEY_TAB, KEY_M:
			_hud.toggle_map()


func _load_plan() -> void:
	var source := FileAccess.get_file_as_string(PLAN_PATH)
	var decoded := JSON.parse_string(source)
	if not (decoded is Dictionary):
		push_error("Dermal Rift plan could not be decoded.")
		return
	_plan = decoded


func _index_plan() -> void:
	var graph: Dictionary = _plan.get("anchor_graph", {})
	for raw_node in graph.get("nodes", []):
		var node: Dictionary = raw_node
		_nodes[str(node.get("id", ""))] = node
	_links = graph.get("links", [])
	_states = _plan.get("dynamic_states", [])
	if _states.is_empty():
		push_error("Dermal Rift needs at least one dynamic state.")


func _create_world() -> void:
	_world = WorldScript.new()
	_world.name = "DermalRiftWorld"
	_world.z_index = 0
	add_child(_world)
	_world.configure(_nodes, _links)


func _create_collision_root() -> void:
	_collision_root = Node2D.new()
	_collision_root.name = "DynamicCavityCollision"
	add_child(_collision_root)


func _create_player() -> void:
	_player = TraversalCellScript.new()
	_player.name = "TraversalCell"
	_player.position = _layout_position(_current_layout, "surface_breach")
	_player.position_changed.connect(_on_player_position_changed)
	add_child(_player)

	var camera := Camera2D.new()
	camera.name = "ExplorationCamera"
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.zoom = Vector2(0.84, 0.84)
	_player.add_child(camera)


func _create_hud() -> void:
	_hud = HudScript.new()
	_hud.name = "ExpeditionHUD"
	add_child(_hud)


func _update_state_director(delta: float) -> void:
	if _completed:
		return
	if _pending_state_index >= 0:
		_pending_seconds -= delta
		_hud.set_transition_warning(
			"TISSUE SHIFT IN %.1fs — remain in a discovered chamber" % maxf(0.0, _pending_seconds),
			maxf(0.1, _pending_seconds + 0.1)
		)
		if _pending_seconds <= 0.0:
			var pending := _pending_state_index
			_pending_state_index = -1
			if _can_transition_safely(pending):
				_commit_state(pending)
			else:
				_state_elapsed = 0.0
				_hud.announce("Tissue holds its shift — return to a stable chamber first.", 3.8)
		return

	_state_elapsed += delta
	if _state_elapsed >= AUTO_STATE_INTERVAL:
		_request_next_state(false)


func _request_next_state(manual_request: bool) -> void:
	if _pending_state_index >= 0 or _states.is_empty() or _completed:
		return
	var next_index := (_state_index + 1) % _states.size()
	if not _can_transition_safely(next_index):
		if manual_request:
			_hud.announce(
				"Route shift needs a safe chamber. Move into a landmark cavity first.", 3.4
			)
		else:
			_state_elapsed = 0.0
			_hud.announce("The organ delays its next pulse while you cross a living route.", 3.4)
		return
	_pending_state_index = next_index
	_pending_seconds = TRANSITION_PREVIEW_SECONDS
	var state: Dictionary = _states[next_index]
	_hud.set_transition_warning(
		"MEMBRANE PREVIEW — %s" % str(state.get("state_cue", "A route will move.")).to_upper(),
		TRANSITION_PREVIEW_SECONDS
	)


func _commit_state(next_index: int) -> void:
	var previous_layout := _current_layout.duplicate(true)
	_state_index = next_index
	_current_layout = _layout_for_state(_state_index)
	_rebuild_collision()
	_world.set_layout(_current_layout, previous_layout)
	_state_elapsed = 0.0
	var state: Dictionary = _states[_state_index]
	_hud.announce(
		"ORGAN STATE: %s" % str(state.get("id", "resting")).replace("_", " ").to_upper(), 2.8
	)


func _can_transition_safely(next_index: int) -> bool:
	if _player == null:
		return true
	var next_layout := _layout_for_state(next_index)
	if not _is_walkable(_player.global_position, next_layout):
		return false
	var anchor_id := _stable_anchor_at(_player.global_position, next_layout)
	if anchor_id.is_empty():
		return false
	return _is_connected_to_entry(anchor_id, next_layout)


func _rebuild_collision() -> void:
	for child in _collision_root.get_children():
		child.queue_free()
	_collision_body_count = 0

	var columns := int(ceil(WORLD_RECT.size.x / GRID_CELL))
	var rows := int(ceil(WORLD_RECT.size.y / GRID_CELL))
	for row in range(rows):
		var run_start := -1
		for column in range(columns + 1):
			var blocked := false
			if column < columns:
				var cell_center := Vector2(
					(float(column) + 0.5) * GRID_CELL, (float(row) + 0.5) * GRID_CELL
				)
				blocked = not _is_walkable(cell_center, _current_layout)
			if blocked and run_start < 0:
				run_start = column
			elif not blocked and run_start >= 0:
				_add_wall_run(run_start, column, row)
				run_start = -1


func _add_wall_run(start_column: int, end_column: int, row: int) -> void:
	var width := float(end_column - start_column) * GRID_CELL
	if width <= 0.0:
		return
	var body := StaticBody2D.new()
	body.name = "TissueWall_%d_%d" % [row, start_column]
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector2(
		(float(start_column) * GRID_CELL) + width * 0.5, (float(row) + 0.5) * GRID_CELL
	)
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, GRID_CELL)
	collider.shape = shape
	body.add_child(collider)
	_collision_root.add_child(body)
	_collision_body_count += 1


func _is_walkable(point: Vector2, layout: Dictionary) -> bool:
	if not WORLD_RECT.has_point(point):
		return false
	for node_id_variant in _nodes:
		var node_id := str(node_id_variant)
		var node: Dictionary = _nodes[node_id]
		var center := _layout_position(layout, node_id)
		var footprint := _array_to_vector(node.get("footprint", [600, 450])) * 0.43
		if footprint.x > 0.0 and footprint.y > 0.0:
			var normalized := (point - center) / footprint
			if normalized.length_squared() <= 1.0:
				return true

	for raw_link in _links:
		var link: Dictionary = raw_link
		if not _is_link_open(link, layout):
			continue
		var from_position := _layout_position(layout, str(link.get("from", "")))
		var to_position := _layout_position(layout, str(link.get("to", "")))
		var closest := Geometry2D.get_closest_point_to_segment(point, from_position, to_position)
		if point.distance_to(closest) <= _route_width(link, layout) * 0.5:
			return true
	return false


func _stable_anchor_at(point: Vector2, layout: Dictionary) -> String:
	var candidate := ""
	var nearest_distance := INF
	for node_id_variant in _nodes:
		var node_id := str(node_id_variant)
		var node: Dictionary = _nodes[node_id]
		var center := _layout_position(layout, node_id)
		var footprint := _array_to_vector(node.get("footprint", [600, 450])) * 0.28
		if footprint.x <= 0.0 or footprint.y <= 0.0:
			continue
		var normalized := (point - center) / footprint
		if normalized.length_squared() <= 1.0:
			var distance := point.distance_to(center)
			if distance < nearest_distance:
				nearest_distance = distance
				candidate = node_id
	return candidate


func _is_connected_to_entry(target_id: String, layout: Dictionary) -> bool:
	var queue: Array = ["surface_breach"]
	var visited: Dictionary = {"surface_breach": true}
	while not queue.is_empty():
		var current := str(queue.pop_front())
		if current == target_id:
			return true
		for raw_link in _links:
			var link: Dictionary = raw_link
			if not _is_link_open(link, layout):
				continue
			var from_id := str(link.get("from", ""))
			var to_id := str(link.get("to", ""))
			var neighbor := ""
			if from_id == current:
				neighbor = to_id
			elif to_id == current:
				neighbor = from_id
			if not neighbor.is_empty() and not visited.has(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)
	return false


func _refresh_exploration() -> void:
	var anchor_id := _stable_anchor_at(_player.global_position, _current_layout)
	if not anchor_id.is_empty():
		_last_safe_anchor = anchor_id
		if not _discovered.has(anchor_id):
			_discovered[anchor_id] = true
			var node: Dictionary = _nodes[anchor_id]
			_hud.announce(
				"LANDMARK DISCOVERED — %s" % str(node.get("landmark", anchor_id)).to_upper(), 3.2
			)
	_world.set_runtime_state(_discovered, _player.global_position, _cavity_attuned, _completed)


func _refresh_interface() -> void:
	var state: Dictionary = _states[_state_index]
	_hud.set_status(
		str(state.get("id", "resting")).replace("_", " "),
		str(state.get("state_cue", state.get("visual_direction", ""))),
		_discovered.size(),
		_nodes.size()
	)
	_hud.set_objective(_objective_text())
	_hud.set_prompt(_interaction_prompt())
	_hud.update_map(
		_nodes,
		_links,
		_current_layout,
		_discovered,
		_player.global_position,
		_cavity_attuned,
		_nodes.size()
	)


func _objective_text() -> String:
	if _completed:
		return "The Dermal Rift traversal is complete."
	if not _cavity_attuned:
		return "Find the Deep Cavity and read its pulse."
	return "Carry the cavity signal to the Organ Gate."


func _interaction_prompt() -> String:
	if _completed:
		return ""
	var nearby := _nearest_anchor(_player.global_position, INTERACTION_RADIUS)
	if nearby == "deep_cavity" and not _cavity_attuned:
		return "E / ENTER — read the cavity pulse"
	if nearby == "organ_gate" and _cavity_attuned:
		return "E / ENTER — cross the organ gate"
	if _pending_state_index >= 0:
		return "Route shift pending — stay in this chamber or retreat."
	return "TAB / M — discovered map     R — request a tissue pulse"


func _try_interact() -> void:
	if _completed:
		return
	var nearby := _nearest_anchor(_player.global_position, INTERACTION_RADIUS)
	if nearby == "deep_cavity" and not _cavity_attuned:
		_cavity_attuned = true
		_rebuild_collision()
		_world.set_runtime_state(_discovered, _player.global_position, _cavity_attuned, _completed)
		_hud.announce("CAVITY PULSE READ — the Organ Gate membrane has opened.", 4.2)
		return
	if nearby == "organ_gate" and _cavity_attuned:
		_completed = true
		_player.set_input_enabled(false)
		_world.set_runtime_state(_discovered, _player.global_position, _cavity_attuned, _completed)
		_hud.show_completion()
		return
	_hud.announce("No responsive membrane is within reach.", 2.0)


func _nearest_anchor(point: Vector2, radius: float) -> String:
	var nearest := ""
	var nearest_distance := radius
	for node_id_variant in _nodes:
		var node_id := str(node_id_variant)
		var distance := point.distance_to(_layout_position(_current_layout, node_id))
		if distance <= nearest_distance:
			nearest = node_id
			nearest_distance = distance
	return nearest


func _on_player_position_changed(_world_position: Vector2) -> void:
	# The state director reads the player position every frame. The signal keeps the
	# traversal controller independently reusable for later hero integration.
	pass


func _layout_for_state(index: int) -> Dictionary:
	if _states.is_empty():
		return {}
	var state: Dictionary = _states[index]
	var positions: Dictionary = {}
	for node_id_variant in _nodes:
		var node_id := str(node_id_variant)
		var node: Dictionary = _nodes[node_id]
		positions[node_id] = _array_to_vector(node.get("position", [0, 0]))
	var offsets: Dictionary = state.get("anchor_offsets", {})
	for node_id_variant in offsets:
		var node_id := str(node_id_variant)
		var current_position: Vector2 = positions.get(node_id, Vector2.ZERO)
		positions[node_id] = current_position + _array_to_vector(offsets[node_id])
	return {
		"state_id": str(state.get("id", "resting")),
		"positions": positions,
		"active_links": state.get("active_links", []).duplicate(),
		"width_scales": state.get("link_width_scales", {}).duplicate(),
		"state_cue": str(state.get("state_cue", state.get("visual_direction", ""))),
	}


func _is_link_open(link: Dictionary, layout: Dictionary) -> bool:
	var active_links: Array = layout.get("active_links", [])
	var link_id := str(link.get("id", ""))
	if not active_links.has(link_id):
		return false
	return link_id != "cavity_to_gate" or _cavity_attuned


func _route_width(link: Dictionary, layout: Dictionary) -> float:
	var scales: Dictionary = layout.get("width_scales", {})
	var scale := float(scales.get(str(link.get("id", "")), 1.0))
	return float(link.get("base_width", 300.0)) * scale


func _layout_position(layout: Dictionary, node_id: String) -> Vector2:
	var positions: Dictionary = layout.get("positions", {})
	return positions.get(node_id, Vector2.ZERO)


func _array_to_vector(value: Variant) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO


func get_runtime_contract() -> Dictionary:
	var active_links: Array = _current_layout.get("active_links", [])
	return {
		"mode": "playable_dynamic_expedition",
		"player_controller": _player is CharacterBody2D,
		"native_hud": _hud is CanvasLayer,
		"collision_body_count": _collision_body_count,
		"state_id": str(_current_layout.get("state_id", "")),
		"active_link_count": active_links.size(),
		"cavity_attuned": _cavity_attuned,
		"completed": _completed,
		"discovered_landmarks": _discovered.size(),
		"dynamic_states": _states.size(),
	}


func get_anchor_position(anchor_id: String) -> Vector2:
	return _layout_position(_current_layout, anchor_id)


func debug_attune_cavity() -> void:
	_cavity_attuned = true
	_rebuild_collision()


func debug_set_state(state_id: String) -> bool:
	for index in range(_states.size()):
		var state: Dictionary = _states[index]
		if str(state.get("id", "")) == state_id:
			if not _can_transition_safely(index):
				return false
			_commit_state(index)
			return true
	return false
