class_name DermalRiftMap
extends Control
## A native Godot map affordance. It reveals discovered anatomy rather than exposing the
## full graph from the start of the expedition.

var _nodes: Dictionary = {}
var _links: Array = []
var _layout: Dictionary = {}
var _discovered: Dictionary = {}
var _player_position := Vector2.ZERO
var _gate_awake := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func set_snapshot(
	nodes: Dictionary,
	links: Array,
	layout: Dictionary,
	discovered: Dictionary,
	player_position: Vector2,
	gate_awake: bool
) -> void:
	_nodes = nodes
	_links = links
	_layout = layout
	_discovered = discovered
	_player_position = player_position
	_gate_awake = gate_awake
	queue_redraw()


func _draw() -> void:
	if _nodes.is_empty() or _layout.is_empty():
		return

	var map_rect := Rect2(Vector2(14.0, 14.0), size - Vector2(28.0, 28.0))
	if map_rect.size.x <= 0.0 or map_rect.size.y <= 0.0:
		return

	draw_rect(map_rect, Color(0.025, 0.05, 0.11, 0.92), true)
	draw_rect(map_rect, Color(0.35, 0.82, 0.8, 0.52), false, 1.5)
	_draw_links(map_rect)
	_draw_nodes(map_rect)
	_draw_player_marker(map_rect)


func _draw_links(map_rect: Rect2) -> void:
	var active_links: Array = _layout.get("active_links", [])
	for raw_link in _links:
		var link: Dictionary = raw_link
		var from_id := str(link.get("from", ""))
		var to_id := str(link.get("to", ""))
		if not (_discovered.has(from_id) and _discovered.has(to_id)):
			continue
		var link_id := str(link.get("id", ""))
		var is_active := active_links.has(link_id)
		if link_id == "cavity_to_gate" and not _gate_awake:
			is_active = false
		var colour := Color(0.34, 0.92, 0.82, 0.92) if is_active else Color(0.32, 0.38, 0.54, 0.48)
		var width := 3.4 if is_active else 1.5
		draw_line(_map_point(from_id, map_rect), _map_point(to_id, map_rect), colour, width, true)


func _draw_nodes(map_rect: Rect2) -> void:
	for node_id_variant in _nodes:
		var node_id := str(node_id_variant)
		if not _discovered.has(node_id):
			continue
		var node: Dictionary = _nodes[node_id]
		var colour := _node_colour(str(node.get("type", "")))
		if node_id == "organ_gate" and not _gate_awake:
			colour = Color(0.32, 0.38, 0.54, 0.8)
		var point := _map_point(node_id, map_rect)
		draw_circle(point, 6.0, Color(0.02, 0.04, 0.09, 0.9))
		draw_circle(point, 4.2, colour)


func _draw_player_marker(map_rect: Rect2) -> void:
	var point := _world_to_map(_player_position, map_rect)
	var marker := PackedVector2Array(
		[
			point + Vector2(0.0, -7.0),
			point + Vector2(6.0, 6.0),
			point + Vector2(-6.0, 6.0),
		]
	)
	draw_colored_polygon(marker, Color(0.98, 1.0, 0.86, 1.0))


func _map_point(node_id: String, map_rect: Rect2) -> Vector2:
	var positions: Dictionary = _layout.get("positions", {})
	var point: Vector2 = positions.get(node_id, Vector2.ZERO)
	return _world_to_map(point, map_rect)


func _world_to_map(world_position: Vector2, map_rect: Rect2) -> Vector2:
	const WORLD_SIZE := Vector2(6400.0, 3600.0)
	var normalized := world_position / WORLD_SIZE
	return (
		map_rect.position + Vector2(normalized.x * map_rect.size.x, normalized.y * map_rect.size.y)
	)


func _node_colour(node_type: String) -> Color:
	match node_type:
		"entry":
			return Color(0.98, 0.69, 0.56, 1.0)
		"exit":
			return Color(0.82, 0.73, 1.0, 1.0)
		"hub_chamber":
			return Color(0.52, 0.9, 0.9, 1.0)
		"optional_branch":
			return Color(0.92, 0.76, 0.4, 1.0)
		_:
			return Color(0.67, 0.82, 0.84, 1.0)
