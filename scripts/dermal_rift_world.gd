class_name DermalRiftWorld
extends Node2D
## Rendered anatomy for the playable Dermal Rift. The same layout data that drives
## collision also drives the visible cavities, tissue bands, state-specific openings,
## and moving anchors. Nothing is drawn by a browser-side substitute.

const WORLD_RECT := Rect2(0.0, 0.0, 6400.0, 3600.0)
const TRANSITION_SECONDS := 1.25

var _nodes: Dictionary = {}
var _links: Array = []
var _layout: Dictionary = {}
var _previous_layout: Dictionary = {}
var _discovered: Dictionary = {}
var _player_position := Vector2.ZERO
var _gate_awake := false
var _completed := false
var _transition := 1.0


func configure(nodes: Dictionary, links: Array) -> void:
	_nodes = nodes
	_links = links
	queue_redraw()


func set_layout(layout: Dictionary, previous_layout: Dictionary = {}) -> void:
	_layout = layout
	_previous_layout = previous_layout
	_transition = 0.0 if not previous_layout.is_empty() else 1.0
	queue_redraw()


func set_runtime_state(
	discovered: Dictionary, player_position: Vector2, gate_awake: bool, completed: bool
) -> void:
	_discovered = discovered
	_player_position = player_position
	_gate_awake = gate_awake
	_completed = completed
	queue_redraw()


func _process(delta: float) -> void:
	if _transition < 1.0:
		_transition = minf(1.0, _transition + delta / TRANSITION_SECONDS)
		queue_redraw()


func _draw() -> void:
	draw_rect(WORLD_RECT, Color(0.035, 0.027, 0.09, 1.0), true)
	_draw_background_anatomy()

	if not _previous_layout.is_empty() and _transition < 1.0:
		_draw_layout(_previous_layout, 1.0 - _transition)
	_draw_layout(_layout, 1.0 if _previous_layout.is_empty() else _transition)
	_draw_landmark_cues()


func _draw_background_anatomy() -> void:
	# Deliberate broad tissue strata make the entire map feel like one cut organ rather
	# than a collection of isolated rooms. They are stable anatomical context, not noise.
	var bands := [
		[0.0, 620.0, Color(0.25, 0.08, 0.14, 0.44)],
		[620.0, 700.0, Color(0.34, 0.2, 0.08, 0.34)],
		[1320.0, 820.0, Color(0.22, 0.06, 0.1, 0.32)],
		[2140.0, 620.0, Color(0.05, 0.14, 0.25, 0.28)],
		[2760.0, 840.0, Color(0.1, 0.06, 0.2, 0.38)],
	]
	for raw_band in bands:
		var band: Array = raw_band
		draw_rect(Rect2(0.0, float(band[0]), WORLD_RECT.size.x, float(band[1])), band[2], true)
	for stripe_index in range(13):
		var y := float(120 + stripe_index * 270)
		var colour := (
			Color(0.46, 0.19, 0.27, 0.10)
			if stripe_index % 2 == 0
			else Color(0.16, 0.36, 0.48, 0.08)
		)
		draw_line(Vector2(0.0, y), Vector2(WORLD_RECT.size.x, y - 90.0), colour, 32.0, true)


func _draw_layout(layout: Dictionary, opacity: float) -> void:
	if layout.is_empty() or opacity <= 0.01:
		return
	for raw_link in _links:
		var link: Dictionary = raw_link
		if not _is_link_active(link, layout):
			_draw_collapsed_link(link, layout, opacity)
	for raw_link in _links:
		var link: Dictionary = raw_link
		if _is_link_active(link, layout):
			_draw_route(link, layout, opacity)
	for node_id_variant in _nodes:
		var node_id := str(node_id_variant)
		var node: Dictionary = _nodes[node_id]
		_draw_chamber(node_id, node, layout, opacity)


func _draw_route(link: Dictionary, layout: Dictionary, opacity: float) -> void:
	var from_position := _layout_position(layout, str(link.get("from", "")))
	var to_position := _layout_position(layout, str(link.get("to", "")))
	var cavity_width := _route_width(link, layout)
	var family := str(link.get("route_family", ""))
	var outer := Color(0.42, 0.12, 0.22, opacity)
	var fat := Color(0.77, 0.47, 0.14, opacity)
	var muscle := Color(0.61, 0.14, 0.21, opacity)
	var fascia := Color(0.11, 0.39, 0.57, opacity)
	var membrane := Color(0.79, 0.42, 0.45, opacity)
	var cavity := Color(0.08, 0.075, 0.19, opacity)

	if family.contains("capillary"):
		fascia = Color(0.08, 0.61, 0.72, opacity)
		membrane = Color(0.34, 0.77, 0.8, opacity)
	elif family.contains("myofiber") or family.contains("lower"):
		muscle = Color(0.76, 0.11, 0.19, opacity)
	elif family.contains("immune") or family.contains("reservoir"):
		fascia = Color(0.48, 0.31, 0.69, opacity)
		membrane = Color(0.75, 0.53, 0.84, opacity)
	elif family.contains("transition"):
		fascia = Color(0.47, 0.34, 0.76, opacity)
		membrane = Color(0.8, 0.68, 0.93, opacity)

	draw_line(from_position, to_position, outer, cavity_width + 440.0, true)
	draw_line(from_position, to_position, fat, cavity_width + 330.0, true)
	draw_line(from_position, to_position, muscle, cavity_width + 224.0, true)
	draw_line(from_position, to_position, fascia, cavity_width + 122.0, true)
	draw_line(from_position, to_position, membrane, cavity_width + 48.0, true)
	draw_line(from_position, to_position, cavity, cavity_width, true)
	_draw_route_fibers(from_position, to_position, cavity_width, muscle, family, opacity)


func _draw_route_fibers(
	from_position: Vector2,
	to_position: Vector2,
	cavity_width: float,
	muscle_colour: Color,
	family: String,
	opacity: float
) -> void:
	if not (family.contains("myofiber") or family.contains("lower") or family.contains("dermal")):
		return
	var direction := (to_position - from_position).normalized()
	var perpendicular := Vector2(-direction.y, direction.x)
	var length := from_position.distance_to(to_position)
	for stripe in range(6):
		var fraction := float(stripe + 1) / 7.0
		var center := from_position.lerp(to_position, fraction)
		var offset := perpendicular * (cavity_width * 0.63)
		var segment := minf(130.0, length * 0.12)
		var colour := Color(
			muscle_colour.r + 0.1, muscle_colour.g + 0.03, muscle_colour.b + 0.04, opacity * 0.72
		)
		draw_line(
			center - direction * segment + offset,
			center + direction * segment + offset,
			colour,
			7.0,
			true
		)
		draw_line(
			center - direction * segment - offset,
			center + direction * segment - offset,
			colour,
			7.0,
			true
		)


func _draw_collapsed_link(link: Dictionary, layout: Dictionary, opacity: float) -> void:
	var from_position := _layout_position(layout, str(link.get("from", "")))
	var to_position := _layout_position(layout, str(link.get("to", "")))
	var center := from_position.lerp(to_position, 0.5)
	var direction := (to_position - from_position).normalized()
	var perpendicular := Vector2(-direction.y, direction.x)
	draw_line(from_position, to_position, Color(0.16, 0.08, 0.2, opacity * 0.55), 78.0, true)
	for fold in range(-2, 3):
		var offset := perpendicular * float(fold * 24)
		draw_line(
			center - direction * 82.0 + offset,
			center + direction * 82.0 + offset,
			Color(0.7, 0.29, 0.43, opacity * 0.8),
			8.0,
			true
		)


func _draw_chamber(node_id: String, node: Dictionary, layout: Dictionary, opacity: float) -> void:
	var center := _layout_position(layout, node_id)
	var footprint := _array_to_vector(node.get("footprint", [600, 450]))
	var profile := str(node.get("material_profile", ""))
	var phase := float(abs(node_id.hash()) % 360) * 0.01745
	var palette := _chamber_palette(profile, opacity)
	var layers := [1.0, 0.84, 0.69, 0.56, 0.45]
	for index in range(layers.size()):
		var scale: float = layers[index]
		var radii := footprint * 0.53 * scale
		draw_colored_polygon(
			_organic_blob(center, radii, phase + float(index) * 0.23), palette[index]
		)

	var inner_radii := footprint * 0.53 * 0.38
	var inner_colour := Color(0.075, 0.07, 0.18, opacity)
	if node_id == "deep_cavity":
		inner_colour = Color(0.09, 0.04, 0.18, opacity)
	if node_id == "organ_gate" and _gate_awake:
		inner_colour = Color(0.16, 0.11, 0.3, opacity)
	draw_colored_polygon(_organic_blob(center, inner_radii, phase + 1.6), inner_colour)
	_draw_chamber_detail(center, footprint, profile, opacity)


func _draw_chamber_detail(
	center: Vector2, footprint: Vector2, profile: String, opacity: float
) -> void:
	var short_axis := minf(footprint.x, footprint.y)
	if profile.contains("muscle"):
		for fiber in range(-3, 4):
			var offset := float(fiber) * short_axis * 0.09
			draw_line(
				center + Vector2(-footprint.x * 0.28, offset - footprint.y * 0.17),
				center + Vector2(footprint.x * 0.28, offset + footprint.y * 0.17),
				Color(0.96, 0.32, 0.37, opacity * 0.42),
				8.0,
				true
			)
	elif profile.contains("adipose"):
		for lobe in range(5):
			var angle := float(lobe) * TAU / 5.0
			var point := (
				center + Vector2(cos(angle) * footprint.x * 0.2, sin(angle) * footprint.y * 0.2)
			)
			draw_circle(point, short_axis * 0.07, Color(0.98, 0.75, 0.31, opacity * 0.42))
	elif profile.contains("fascia") or profile.contains("vascular"):
		draw_arc(
			center,
			short_axis * 0.28,
			0.25,
			5.55,
			24,
			Color(0.28, 0.82, 0.89, opacity * 0.48),
			7.0,
			true
		)


func _draw_landmark_cues() -> void:
	if _layout.is_empty():
		return
	var deep_position := _layout_position(_layout, "deep_cavity")
	var gate_position := _layout_position(_layout, "organ_gate")
	var pulse_alpha := 0.8 + sin(Time.get_ticks_msec() * 0.004) * 0.16
	if _discovered.has("deep_cavity") and not _gate_awake:
		draw_arc(
			deep_position, 178.0, 0.0, TAU, 42, Color(0.96, 0.78, 0.43, pulse_alpha), 5.0, true
		)
	if _gate_awake:
		draw_arc(
			gate_position, 136.0, 0.0, TAU, 42, Color(0.71, 0.95, 0.78, pulse_alpha), 5.0, true
		)
	if _completed:
		draw_circle(gate_position, 78.0, Color(0.64, 1.0, 0.75, 0.22))


func _chamber_palette(profile: String, opacity: float) -> Array:
	if profile.contains("adipose"):
		return [
			Color(0.42, 0.18, 0.14, opacity),
			Color(0.71, 0.36, 0.14, opacity),
			Color(0.88, 0.62, 0.19, opacity),
			Color(0.95, 0.77, 0.32, opacity),
			Color(0.93, 0.54, 0.23, opacity),
		]
	if profile.contains("muscle"):
		return [
			Color(0.35, 0.07, 0.14, opacity),
			Color(0.56, 0.1, 0.18, opacity),
			Color(0.76, 0.14, 0.22, opacity),
			Color(0.88, 0.27, 0.28, opacity),
			Color(0.74, 0.12, 0.25, opacity),
		]
	if profile.contains("fascia") or profile.contains("vascular"):
		return [
			Color(0.04, 0.15, 0.28, opacity),
			Color(0.08, 0.28, 0.43, opacity),
			Color(0.12, 0.48, 0.59, opacity),
			Color(0.25, 0.69, 0.72, opacity),
			Color(0.38, 0.82, 0.79, opacity),
		]
	if profile.contains("immune"):
		return [
			Color(0.18, 0.08, 0.32, opacity),
			Color(0.32, 0.14, 0.5, opacity),
			Color(0.49, 0.28, 0.67, opacity),
			Color(0.67, 0.43, 0.8, opacity),
			Color(0.83, 0.63, 0.93, opacity),
		]
	if profile.contains("deep") or profile.contains("transition"):
		return [
			Color(0.12, 0.05, 0.24, opacity),
			Color(0.22, 0.08, 0.36, opacity),
			Color(0.36, 0.16, 0.5, opacity),
			Color(0.52, 0.28, 0.64, opacity),
			Color(0.68, 0.45, 0.75, opacity),
		]
	return [
		Color(0.35, 0.09, 0.17, opacity),
		Color(0.55, 0.16, 0.23, opacity),
		Color(0.74, 0.26, 0.31, opacity),
		Color(0.86, 0.42, 0.43, opacity),
		Color(0.92, 0.6, 0.52, opacity),
	]


func _organic_blob(center: Vector2, radii: Vector2, phase: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	const SEGMENTS := 28
	for index in range(SEGMENTS):
		var angle := TAU * float(index) / float(SEGMENTS)
		var contour := 1.0 + sin(angle * 3.0 + phase) * 0.055 + cos(angle * 5.0 - phase) * 0.035
		points.append(
			center + Vector2(cos(angle) * radii.x * contour, sin(angle) * radii.y * contour)
		)
	return points


func _is_link_active(link: Dictionary, layout: Dictionary) -> bool:
	var active_links: Array = layout.get("active_links", [])
	var link_id := str(link.get("id", ""))
	if not active_links.has(link_id):
		return false
	return link_id != "cavity_to_gate" or _gate_awake


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
