class_name DermalRiftExpedition
extends Node2D
## A playable, hand-authored Godot exploration slice. The player moves through one
## anatomical space, follows living landmarks, opens a real tissue gate, and adapts to
## a local fascia valve. There is intentionally no dashboard-style screen overlay.

const TraversalCellScript = preload("res://scripts/traversal_cell.gd")
const WorldScript = preload("res://scripts/dermal_rift_world.gd")

const WORLD_RECT := Rect2(0.0, 0.0, 1920.0, 1072.0)
const GRID_CELL := 32.0
const AUTO_STATE_INTERVAL := 15.0
const INTERACTION_RADIUS := 92.0
const ECHO_POSITION := Vector2(1145.0, 815.0)
const DEEP_CAVITY := Vector2(1050.0, 445.0)
const ORGAN_GATE := Vector2(1665.0, 430.0)
const LOWER_VALVE := Vector2(790.0, 665.0)
const STATE_IDS := ["resting", "contraction", "vascular_surge", "inflammation", "recovery"]

var _player: TraversalCell
var _world: DermalRiftWorld
var _collision_root: Node2D
var _state_index := 0
var _state_elapsed := 0.0
var _lower_route_open := true
var _echo_collected := false
var _cavity_awakened := false
var _organ_gate_open := false
var _completed := false
var _collision_body_count := 0


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.015, 0.025, 0.04, 1.0))
	_create_world()
	_create_collision_root()
	_rebuild_collision()
	_create_player()
	_sync_world()


func _process(delta: float) -> void:
	if _completed:
		return
	_state_elapsed += delta
	if _state_elapsed >= AUTO_STATE_INTERVAL:
		_request_next_state()


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
			_request_next_state()


func _create_world() -> void:
	_world = WorldScript.new()
	_world.name = "DermalRiftWorld"
	add_child(_world)


func _create_collision_root() -> void:
	_collision_root = Node2D.new()
	_collision_root.name = "DynamicCavityCollision"
	add_child(_collision_root)


func _create_player() -> void:
	_player = TraversalCellScript.new()
	_player.name = "TraversalCell"
	_player.position = Vector2(160.0, 495.0)
	add_child(_player)

	var camera := Camera2D.new()
	camera.name = "ExplorationCamera"
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = int(WORLD_RECT.position.x)
	camera.limit_top = int(WORLD_RECT.position.y)
	camera.limit_right = int(WORLD_RECT.end.x)
	camera.limit_bottom = int(WORLD_RECT.end.y)
	camera.zoom = Vector2(1.0, 1.0)
	_player.add_child(camera)


func _request_next_state() -> void:
	var next_index := (_state_index + 1) % STATE_IDS.size()
	var next_lower_open := _lower_route_for_state(next_index)
	if not next_lower_open and _player_is_in_lower_loop():
		# The organ refuses to close around the explorer. The valve only commits after
		# the player returns to the central lumen, making the change readable and safe.
		_state_elapsed = AUTO_STATE_INTERVAL - 2.0
		return
	_state_index = next_index
	_lower_route_open = next_lower_open
	_state_elapsed = 0.0
	_rebuild_collision()
	_sync_world()


func _try_interact() -> void:
	if _completed:
		return
	if (
		not _echo_collected
		and _player.global_position.distance_to(ECHO_POSITION) <= INTERACTION_RADIUS
	):
		_echo_collected = true
		_sync_world()
		return
	if (
		_echo_collected
		and not _cavity_awakened
		and _player.global_position.distance_to(DEEP_CAVITY) <= INTERACTION_RADIUS
	):
		_cavity_awakened = true
		_organ_gate_open = true
		_rebuild_collision()
		_sync_world()
		return
	if _organ_gate_open and _player.global_position.distance_to(ORGAN_GATE) <= INTERACTION_RADIUS:
		_completed = true
		_player.set_input_enabled(false)
		_sync_world()


func _sync_world() -> void:
	_world.set_world_state(
		_state_id(),
		_lower_route_open,
		_echo_collected,
		_cavity_awakened,
		_organ_gate_open,
		_completed
	)


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
				var center := Vector2(
					(float(column) + 0.5) * GRID_CELL, (float(row) + 0.5) * GRID_CELL
				)
				blocked = not _is_walkable(center)
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
		float(start_column) * GRID_CELL + width * 0.5, (float(row) + 0.5) * GRID_CELL
	)
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, GRID_CELL)
	collider.shape = shape
	body.add_child(collider)
	_collision_root.add_child(body)
	_collision_body_count += 1


func _is_walkable(point: Vector2) -> bool:
	if not WORLD_RECT.has_point(point):
		return false
	if not _organ_gate_open and _inside_ellipse(point, ORGAN_GATE, Vector2(76.0, 168.0)):
		return false
	if not _lower_route_open and _inside_ellipse(point, LOWER_VALVE, Vector2(120.0, 98.0)):
		return false

	var in_main_lumen := (
		_inside_capsule(point, Vector2(-40.0, 500.0), Vector2(600.0, 500.0), 168.0)
		or _inside_ellipse(point, Vector2(1040.0, 460.0), Vector2(425.0, 274.0))
		or _inside_capsule(point, Vector2(1280.0, 462.0), Vector2(1935.0, 430.0), 155.0)
	)
	if in_main_lumen:
		return true
	if not _lower_route_open:
		return false
	return (
		_inside_capsule(point, Vector2(710.0, 555.0), Vector2(850.0, 748.0), 104.0)
		or _inside_capsule(point, Vector2(850.0, 748.0), Vector2(1175.0, 830.0), 106.0)
		or _inside_capsule(point, Vector2(1175.0, 830.0), Vector2(1450.0, 603.0), 106.0)
		or _inside_capsule(point, Vector2(1450.0, 603.0), Vector2(1320.0, 510.0), 112.0)
	)


func _inside_capsule(point: Vector2, start: Vector2, finish: Vector2, radius: float) -> bool:
	var closest := Geometry2D.get_closest_point_to_segment(point, start, finish)
	return point.distance_to(closest) <= radius


func _inside_ellipse(point: Vector2, center: Vector2, radii: Vector2) -> bool:
	var normalized := (point - center) / radii
	return normalized.length_squared() <= 1.0


func _player_is_in_lower_loop() -> bool:
	return _player.global_position.y > 610.0 and _player.global_position.x > 650.0


func _lower_route_for_state(index: int) -> bool:
	var state_id := str(STATE_IDS[index])
	return state_id != "contraction" and state_id != "inflammation"


func _state_id() -> String:
	return str(STATE_IDS[_state_index])


func get_runtime_contract() -> Dictionary:
	return {
		"mode": "hand_authored_playable_expedition",
		"player_controller": _player is CharacterBody2D,
		"screen_overlay_count": 0,
		"collision_body_count": _collision_body_count,
		"state_id": _state_id(),
		"lower_route_open": _lower_route_open,
		"echo_collected": _echo_collected,
		"cavity_awakened": _cavity_awakened,
		"organ_gate_open": _organ_gate_open,
		"completed": _completed,
	}


func get_landmark_position(landmark_id: String) -> Vector2:
	match landmark_id:
		"echo":
			return ECHO_POSITION
		"deep_cavity":
			return DEEP_CAVITY
		"organ_gate":
			return ORGAN_GATE
	return Vector2.ZERO


func debug_collect_echo() -> void:
	_echo_collected = true
	_sync_world()


func debug_awaken_cavity() -> void:
	_echo_collected = true
	_cavity_awakened = true
	_organ_gate_open = true
	_rebuild_collision()
	_sync_world()


func debug_set_state(state_id: String) -> bool:
	for index in range(STATE_IDS.size()):
		if str(STATE_IDS[index]) == state_id:
			_state_index = index
			_lower_route_open = _lower_route_for_state(index)
			_rebuild_collision()
			_sync_world()
			return true
	return false
