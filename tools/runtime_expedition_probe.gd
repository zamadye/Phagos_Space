extends SceneTree
## Instantiates the actual playable Godot scene and proves that it contains a controller,
## native UI, dynamic collision cavities, a locked-to-unlocked progression gate, and
## state-dependent route changes.

const EXPEDITION_SCENE = preload("res://scenes/main.tscn")


func _init() -> void:
	call_deferred("_probe")


func _probe() -> void:
	var expedition := EXPEDITION_SCENE.instantiate()
	root.add_child(expedition)
	await process_frame
	await process_frame

	var failures: PackedStringArray = []
	if not expedition.has_method("get_runtime_contract"):
		failures.append("main scene has no playable expedition runtime contract")
	else:
		var initial: Dictionary = expedition.call("get_runtime_contract")
		if str(initial.get("mode", "")) != "playable_dynamic_expedition":
			failures.append("main scene does not declare the dynamic exploration mode")
		if not bool(initial.get("player_controller", false)):
			failures.append("no CharacterBody2D traversal controller was created")
		if not bool(initial.get("native_hud", false)):
			failures.append("no native Godot HUD was created")
		if int(initial.get("collision_body_count", 0)) < 20:
			failures.append("dynamic arena did not create meaningful collision boundaries")
		if int(initial.get("dynamic_states", 0)) < 5:
			failures.append("Dermal Rift did not load every authored organ state")
		if bool(initial.get("cavity_attuned", true)):
			failures.append("goal route should begin locked until the Deep Cavity is read")

	var player := expedition.get_node_or_null(NodePath("TraversalCell")) as CharacterBody2D
	if player == null:
		failures.append("TraversalCell runtime node is missing")
	var collision_root := expedition.get_node_or_null(NodePath("DynamicCavityCollision"))
	if collision_root == null or collision_root.get_child_count() < 20:
		failures.append("DynamicCavityCollision runtime node is missing or empty")
	if expedition.get_node_or_null(NodePath("ExpeditionHUD")) == null:
		failures.append("ExpeditionHUD runtime node is missing")

	if (
		player != null
		and expedition.has_method("get_anchor_position")
		and expedition.has_method("debug_attune_cavity")
	):
		player.global_position = expedition.call("get_anchor_position", "deep_cavity")
		expedition.call("debug_attune_cavity")
		await process_frame
		var opened: Dictionary = expedition.call("get_runtime_contract")
		if not bool(opened.get("cavity_attuned", false)):
			failures.append("Deep Cavity interaction did not unlock the Organ Gate route")

	if expedition.has_method("debug_set_state"):
		var switched := bool(expedition.call("debug_set_state", "vascular_surge"))
		await process_frame
		var changed: Dictionary = expedition.call("get_runtime_contract")
		if not switched or str(changed.get("state_id", "")) != "vascular_surge":
			failures.append("safe organ-state route change could not be committed")
		if int(changed.get("active_link_count", 0)) < 6:
			failures.append("vascular surge lost the authored traversal route")
	else:
		failures.append("main scene has no state transition probe route")

	if failures.is_empty():
		print(
			(
				"Runtime expedition probe passed: controller, collision cavities, native HUD, "
				+ "gate progression, and dynamic state routing are live."
			)
		)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
