extends SceneTree
## Instantiates the actual Godot scene and proves the expedition is an authored playable
## space rather than a screen overlay around a graph mock-up.

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
		if str(initial.get("mode", "")) != "hand_authored_playable_expedition":
			failures.append("main scene is not the hand-authored playable expedition")
		if not bool(initial.get("player_controller", false)):
			failures.append("no CharacterBody2D traversal controller was created")
		if int(initial.get("screen_overlay_count", -1)) != 0:
			failures.append("the exploration scene created a screen overlay")
		if int(initial.get("collision_body_count", 0)) < 20:
			failures.append("the anatomical lumen did not create meaningful collision boundaries")
		if not bool(initial.get("lower_route_open", false)):
			failures.append("the lower exploration route should start open")

	var player := expedition.get_node_or_null(NodePath("TraversalCell")) as CharacterBody2D
	if player == null:
		failures.append("TraversalCell runtime node is missing")
	var world := expedition.get_node_or_null(NodePath("DermalRiftWorld"))
	if world == null or world.get_node_or_null(NodePath("DermalRiftPlayfieldArt")) == null:
		failures.append("hand-authored Dermal Rift playfield art is missing")
	var collision_root := expedition.get_node_or_null(NodePath("DynamicCavityCollision"))
	if collision_root == null or collision_root.get_child_count() < 20:
		failures.append("DynamicCavityCollision runtime node is missing or empty")
	if expedition.get_node_or_null(NodePath("ExpeditionHUD")) != null:
		failures.append("retired dashboard HUD is still present in the runtime scene")

	if player != null and expedition.has_method("get_landmark_position"):
		player.global_position = expedition.call("get_landmark_position", "echo")
		expedition.call("debug_collect_echo")
		await process_frame
		var echo_result: Dictionary = expedition.call("get_runtime_contract")
		if not bool(echo_result.get("echo_collected", false)):
			failures.append("lower-loop landmark interaction did not register")

		player.global_position = expedition.call("get_landmark_position", "deep_cavity")
		expedition.call("debug_awaken_cavity")
		await process_frame
		var awakened: Dictionary = expedition.call("get_runtime_contract")
		if not bool(awakened.get("organ_gate_open", false)):
			failures.append("Deep Cavity did not open the organ gate")

	if expedition.has_method("debug_set_state"):
		var switched := bool(expedition.call("debug_set_state", "contraction"))
		await process_frame
		var changed: Dictionary = expedition.call("get_runtime_contract")
		if not switched or str(changed.get("state_id", "")) != "contraction":
			failures.append("contractile state did not commit")
		if bool(changed.get("lower_route_open", true)):
			failures.append("contraction did not close the local fascia valve")
	else:
		failures.append("main scene has no organ-state test route")

	if failures.is_empty():
		print(
			(
				"Runtime expedition probe passed: authored playfield, controller, collision, "
				+ "landmarks, gate, and tissue valve are live."
			)
		)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
		print("::error title=PHAGOS runtime probe::%s" % failure)
	quit(1)
