extends SceneTree
## Builds the native arena scene and verifies the actual Sprite2D stack after _ready().

const ARENA_SCENE = preload("res://scenes/main.tscn")
const EXPECTED_LAYERS: PackedStringArray = [
	"DeepTissueBackdrop",
	"OuterSkin",
	"Fat",
	"MuscleFibers",
	"BlueFascia",
	"InnerMembrane",
	"OpenCavityFloor",
]


func _init() -> void:
	call_deferred("_probe")


func _probe() -> void:
	var arena := ARENA_SCENE.instantiate()
	root.add_child(arena)
	await process_frame
	await process_frame

	var failures: PackedStringArray = []
	if not arena.has_method("get_material_report"):
		failures.append("arena has no material report")
	else:
		var report: Dictionary = arena.call("get_material_report")
		if not bool(report.get("native_godot_only", false)):
			failures.append("arena no longer declares native Godot presentation")
		if (
			int(report.get("runtime_particles", -1)) != 0
			or int(report.get("runtime_overlays", -1)) != 0
		):
			failures.append("arena created particles or overlays")
		if bool(report.get("environment_animation", true)):
			failures.append("static material study unexpectedly animates")

	for layer_name in EXPECTED_LAYERS:
		var node := arena.get_node_or_null(NodePath(layer_name))
		if node == null:
			failures.append("missing runtime layer %s" % layer_name)
			continue
		if not (node is Sprite2D):
			failures.append("%s is not a Sprite2D" % layer_name)
			continue
		var sprite := node as Sprite2D
		if sprite.texture == null:
			failures.append("%s has no baked texture" % layer_name)

	var non_camera_children := 0
	for child in arena.get_children():
		if child.name != "Camera2D":
			non_camera_children += 1
	if non_camera_children != EXPECTED_LAYERS.size():
		failures.append("runtime created unexpected non-camera children")

	if failures.is_empty():
		print(
			"Runtime cross-section probe passed: seven baked Sprite2D layers, no effects, no overlays."
		)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
