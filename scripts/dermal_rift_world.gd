class_name DermalRiftWorld
extends Node2D
## A hand-authored playable stage. The environment is a real Godot Sprite2D playfield;
## dynamic organ behavior appears as local tissue valves and landmarks inside that world,
## never as a full-screen diagram or dashboard overlay.

const PLAYFIELD: Texture2D = preload("res://assets/arena/dermal_rift_playfield.png")
const WORLD_SIZE := Vector2(1920.0, 1072.0)
const SOURCE_SIZE := Vector2(1376.0, 768.0)
const LOWER_VALVE := Vector2(790.0, 665.0)
const ECHO_POSITION := Vector2(1145.0, 815.0)
const DEEP_CAVITY := Vector2(1050.0, 445.0)
const ORGAN_GATE := Vector2(1665.0, 430.0)

var _state_id := "resting"
var _lower_route_open := true
var _echo_collected := false
var _cavity_awakened := false
var _organ_gate_open := false
var _completed := false
var _time := 0.0
var _lower_open_visual := 1.0
var _organ_open_visual := 0.0


func _ready() -> void:
	var background := Sprite2D.new()
	background.name = "DermalRiftPlayfieldArt"
	background.texture = PLAYFIELD
	background.position = WORLD_SIZE * 0.5
	background.scale = WORLD_SIZE / SOURCE_SIZE
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	background.z_index = -2
	add_child(background)
	queue_redraw()


func set_world_state(
	state_id: String,
	lower_route_open: bool,
	echo_collected: bool,
	cavity_awakened: bool,
	organ_gate_open: bool,
	completed: bool
) -> void:
	_state_id = state_id
	_lower_route_open = lower_route_open
	_echo_collected = echo_collected
	_cavity_awakened = cavity_awakened
	_organ_gate_open = organ_gate_open
	_completed = completed
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	var lower_target := 1.0 if _lower_route_open else 0.0
	var organ_target := 1.0 if _organ_gate_open else 0.0
	_lower_open_visual = move_toward(_lower_open_visual, lower_target, delta * 0.8)
	_organ_open_visual = move_toward(_organ_open_visual, organ_target, delta * 0.8)
	queue_redraw()


func _draw() -> void:
	_draw_lower_valve()
	_draw_echo_landmark()
	_draw_deep_cavity_landmark()
	_draw_organ_gate()


func _draw_lower_valve() -> void:
	# A local fascia valve controls the lower exploration loop. It retracts into the
	# wall when open and visibly pinches the passage only during a contractile state.
	var closure := 1.0 - _lower_open_visual
	var pulse := 1.0 + sin(_time * 2.4) * 0.04
	var upper_fold := PackedVector2Array(
		[
			LOWER_VALVE + Vector2(-125.0, -92.0),
			LOWER_VALVE + Vector2(118.0, -78.0),
			LOWER_VALVE + Vector2(94.0, -22.0 - closure * 56.0 * pulse),
			LOWER_VALVE + Vector2(-100.0, -18.0 - closure * 56.0 * pulse),
		]
	)
	var lower_fold := PackedVector2Array(
		[
			LOWER_VALVE + Vector2(-108.0, 82.0),
			LOWER_VALVE + Vector2(125.0, 76.0),
			LOWER_VALVE + Vector2(96.0, 20.0 + closure * 56.0 * pulse),
			LOWER_VALVE + Vector2(-92.0, 18.0 + closure * 56.0 * pulse),
		]
	)
	var fascia_colour := Color(0.08, 0.64, 0.7, 0.78)
	if _state_id == "contraction" or _state_id == "inflammation":
		fascia_colour = Color(0.72, 0.18, 0.29, 0.84)
	draw_colored_polygon(upper_fold, fascia_colour)
	draw_colored_polygon(lower_fold, fascia_colour)
	draw_polyline(upper_fold, Color(0.82, 0.95, 0.78, 0.85), 3.0, true)
	draw_polyline(lower_fold, Color(0.82, 0.95, 0.78, 0.85), 3.0, true)
	if closure > 0.08:
		draw_line(
			LOWER_VALVE + Vector2(-84.0, 0.0),
			LOWER_VALVE + Vector2(84.0, 0.0),
			Color(0.29, 0.05, 0.14, 0.78),
			20.0 + closure * 30.0,
			true
		)


func _draw_echo_landmark() -> void:
	if _echo_collected:
		return
	var pulse := 1.0 + sin(_time * 3.4) * 0.11
	_draw_living_landmark(
		ECHO_POSITION,
		Vector2(31.0, 40.0) * pulse,
		Color(0.18, 0.92, 0.86, 0.95),
		Color(0.68, 1.0, 0.83, 0.9)
	)


func _draw_deep_cavity_landmark() -> void:
	var pulse := 1.0 + sin(_time * 2.1) * 0.08
	var outer := Color(0.95, 0.62, 0.29, 0.94)
	var core := Color(1.0, 0.87, 0.57, 0.94)
	if not _echo_collected:
		outer = Color(0.28, 0.18, 0.35, 0.66)
		core = Color(0.43, 0.28, 0.48, 0.62)
	elif _cavity_awakened:
		outer = Color(0.56, 1.0, 0.73, 0.95)
		core = Color(0.92, 1.0, 0.81, 0.96)
	_draw_living_landmark(DEEP_CAVITY, Vector2(43.0, 48.0) * pulse, outer, core)


func _draw_organ_gate() -> void:
	var closure := 1.0 - _organ_open_visual
	var pulse := 1.0 + sin(_time * 2.8) * 0.035
	var top_membrane := PackedVector2Array(
		[
			ORGAN_GATE + Vector2(-64.0, -150.0),
			ORGAN_GATE + Vector2(64.0, -150.0),
			ORGAN_GATE + Vector2(78.0, -22.0 - closure * 90.0 * pulse),
			ORGAN_GATE + Vector2(-72.0, -22.0 - closure * 90.0 * pulse),
		]
	)
	var bottom_membrane := PackedVector2Array(
		[
			ORGAN_GATE + Vector2(-70.0, 150.0),
			ORGAN_GATE + Vector2(68.0, 150.0),
			ORGAN_GATE + Vector2(74.0, 22.0 + closure * 90.0 * pulse),
			ORGAN_GATE + Vector2(-76.0, 22.0 + closure * 90.0 * pulse),
		]
	)
	var membrane_colour := Color(0.76, 0.34, 0.48, 0.9)
	if _organ_gate_open:
		membrane_colour = Color(0.47, 0.92, 0.72, 0.82)
	draw_colored_polygon(top_membrane, membrane_colour)
	draw_colored_polygon(bottom_membrane, membrane_colour)
	draw_polyline(top_membrane, Color(1.0, 0.78, 0.65, 0.84), 3.0, true)
	draw_polyline(bottom_membrane, Color(1.0, 0.78, 0.65, 0.84), 3.0, true)
	if _organ_gate_open:
		draw_arc(
			ORGAN_GATE,
			94.0 + sin(_time * 3.0) * 8.0,
			0.0,
			TAU,
			32,
			Color(0.66, 1.0, 0.75, 0.68),
			3.0,
			true
		)
	if _completed:
		draw_circle(ORGAN_GATE, 62.0, Color(0.72, 1.0, 0.82, 0.24))


func _draw_living_landmark(center: Vector2, radii: Vector2, outer: Color, core: Color) -> void:
	var outer_points := _organic_blob(center, radii, 16, _time * 0.6)
	var inner_points := _organic_blob(center, radii * 0.52, 16, -_time * 0.9)
	draw_colored_polygon(outer_points, outer)
	draw_polyline(outer_points, Color(1.0, 0.91, 0.73, 0.86), 2.0, true)
	draw_colored_polygon(inner_points, core)


func _organic_blob(center: Vector2, radii: Vector2, count: int, phase: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(count):
		var angle := TAU * float(index) / float(count)
		var ripple := 1.0 + sin(angle * 3.0 + phase) * 0.08 + cos(angle * 5.0 - phase) * 0.04
		points.append(
			center + Vector2(cos(angle) * radii.x * ripple, sin(angle) * radii.y * ripple)
		)
	return points
