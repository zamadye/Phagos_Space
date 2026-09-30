class_name ExpeditionHud
extends CanvasLayer
## Native Godot HUD for orientation and route-change readability. It is deliberately
## sparse: the world remains visible, while the player receives actionable information.

const MapScript = preload("res://scripts/dermal_rift_map.gd")

var _root: Control
var _state_label: Label
var _state_cue_label: Label
var _discovery_label: Label
var _objective_label: Label
var _prompt_label: Label
var _notice_label: Label
var _notice_panel: PanelContainer
var _map_panel: PanelContainer
var _map_label: Label
var _map: DermalRiftMap
var _completion_panel: PanelContainer
var _notice_time := 0.0


func _ready() -> void:
	layer = 20
	_root = Control.new()
	_root.name = "ExpeditionInterface"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_build_status_panel()
	_build_objective_panel()
	_build_notice_panel()
	_build_map_panel()
	_build_completion_panel()


func set_status(
	state_name: String, state_cue: String, discoveries: int, total_landmarks: int
) -> void:
	_state_label.text = "ORGAN STATE  /  %s" % state_name.to_upper()
	_state_cue_label.text = state_cue
	_discovery_label.text = "LANDMARKS  %d / %d" % [discoveries, total_landmarks]


func set_objective(objective: String) -> void:
	_objective_label.text = "OBJECTIVE\n%s" % objective


func set_prompt(prompt: String) -> void:
	_prompt_label.text = prompt
	_prompt_label.visible = not prompt.is_empty()


func announce(message: String, duration := 3.5) -> void:
	_notice_label.text = message
	_notice_time = duration
	_notice_panel.visible = true


func set_transition_warning(message: String, duration: float) -> void:
	_notice_label.text = message
	_notice_time = duration
	_notice_panel.visible = true


func update_map(
	nodes: Dictionary,
	links: Array,
	layout: Dictionary,
	discovered: Dictionary,
	player_position: Vector2,
	gate_awake: bool,
	total_landmarks: int
) -> void:
	_map_label.text = "RIFT MAP  /  %d OF %d MAPPED" % [discovered.size(), total_landmarks]
	_map.set_snapshot(nodes, links, layout, discovered, player_position, gate_awake)


func toggle_map() -> void:
	_map_panel.visible = not _map_panel.visible
	announce("Rift map %s" % ("opened" if _map_panel.visible else "folded"), 1.4)


func show_completion() -> void:
	_completion_panel.visible = true
	_notice_panel.visible = false


func _process(delta: float) -> void:
	if _notice_time <= 0.0:
		return
	_notice_time -= delta
	if _notice_time <= 0.0:
		_notice_panel.visible = false


func _build_status_panel() -> void:
	var panel := _new_panel(Color(0.025, 0.055, 0.11, 0.9), Color(0.34, 0.9, 0.82, 0.72))
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(24.0, 24.0)
	panel.size = Vector2(430.0, 158.0)
	_root.add_child(panel)
	var box := _new_box()
	panel.add_child(box)
	_state_label = _new_label(18, Color(0.8, 1.0, 0.9, 1.0))
	_state_cue_label = _new_label(14, Color(0.76, 0.86, 0.91, 1.0))
	_state_cue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_discovery_label = _new_label(13, Color(0.98, 0.83, 0.49, 1.0))
	box.add_child(_state_label)
	box.add_child(_state_cue_label)
	box.add_child(_discovery_label)


func _build_objective_panel() -> void:
	var panel := _new_panel(Color(0.07, 0.035, 0.13, 0.9), Color(0.82, 0.61, 0.95, 0.62))
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.position = Vector2(24.0, -143.0)
	panel.size = Vector2(430.0, 116.0)
	_root.add_child(panel)
	var box := _new_box()
	panel.add_child(box)
	_objective_label = _new_label(16, Color(0.96, 0.91, 1.0, 1.0))
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_objective_label)
	_prompt_label = _new_label(14, Color(0.72, 1.0, 0.88, 1.0))
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_prompt_label)


func _build_notice_panel() -> void:
	_notice_panel = _new_panel(Color(0.1, 0.055, 0.13, 0.94), Color(1.0, 0.75, 0.33, 0.88))
	_notice_panel.anchor_left = 0.5
	_notice_panel.anchor_right = 0.5
	_notice_panel.anchor_top = 0.0
	_notice_panel.anchor_bottom = 0.0
	_notice_panel.offset_left = -250.0
	_notice_panel.offset_right = 250.0
	_notice_panel.offset_top = 26.0
	_notice_panel.offset_bottom = 82.0
	_root.add_child(_notice_panel)
	_notice_label = _new_label(15, Color(1.0, 0.93, 0.76, 1.0))
	_notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice_panel.add_child(_notice_label)
	_notice_panel.visible = false


func _build_map_panel() -> void:
	_map_panel = _new_panel(Color(0.025, 0.055, 0.11, 0.94), Color(0.33, 0.79, 0.9, 0.74))
	_map_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_map_panel.position = Vector2(-382.0, -305.0)
	_map_panel.size = Vector2(356.0, 278.0)
	_root.add_child(_map_panel)
	var box := _new_box()
	_map_panel.add_child(box)
	_map_label = _new_label(13, Color(0.73, 0.94, 1.0, 1.0))
	box.add_child(_map_label)
	_map = MapScript.new()
	_map.name = "DiscoveredRiftMap"
	_map.custom_minimum_size = Vector2(324.0, 220.0)
	box.add_child(_map)


func _build_completion_panel() -> void:
	_completion_panel = _new_panel(Color(0.035, 0.08, 0.12, 0.96), Color(0.56, 1.0, 0.79, 0.94))
	_completion_panel.anchor_left = 0.5
	_completion_panel.anchor_right = 0.5
	_completion_panel.anchor_top = 0.5
	_completion_panel.anchor_bottom = 0.5
	_completion_panel.offset_left = -260.0
	_completion_panel.offset_right = 260.0
	_completion_panel.offset_top = -125.0
	_completion_panel.offset_bottom = 125.0
	_root.add_child(_completion_panel)
	var box := _new_box()
	_completion_panel.add_child(box)
	var title := _new_label(26, Color(0.86, 1.0, 0.91, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "ORGAN GATE CROSSED"
	var body := _new_label(16, Color(0.79, 0.92, 0.91, 1.0))
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var completion_message := "You read the cavity pulse and adapted to the organ shift."
	completion_message += " You carried the signal forward."
	completion_message += "\n\nThis traversal slice is complete."
	body.text = completion_message
	box.add_child(title)
	box.add_child(body)
	_completion_panel.visible = false


func _new_panel(background: Color, border: Color) -> PanelContainer:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 11.0
	style.content_margin_bottom = 11.0
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


func _new_box() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return box


func _new_label(font_size: int, colour: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
