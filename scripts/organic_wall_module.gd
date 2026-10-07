class_name OrganicWallModule
extends Node3D

## One modular authored vessel-wall tile.
##
## Blender owns the membrane mesh, glossy materials, wall-virus spot meshes,
## and breathing clip. Godot only places the intact module, starts the clip,
## pulses spot scale, and exposes a damage API for the later wall-enemy pass.

signal spot_destroyed(module: OrganicWallModule, spot_index: int)

var wall_asset: Node3D
var wall_material: ShaderMaterial
var module_index: int = 0
var module_seed: float = 0.0
var elapsed: float = 0.0
var spot_entries: Array[Dictionary] = []

func configure(scene: PackedScene, authored_material: ShaderMaterial, index: int, seed_value: float) -> void:
	module_index = index
	module_seed = seed_value
	wall_material = authored_material
	wall_asset = scene.instantiate()
	wall_asset.name = "AuthoredVesselWallAsset"
	add_child(wall_asset)
	_initialize_authored_asset()

## Scene-authored variant used by WallStudy.tscn. The GLB is an explicit
## PackedScene child in scenes/OrganicWallModule.tscn rather than an HTML or
## JavaScript dependency.
func configure_existing(authored_material: ShaderMaterial, index: int, seed_value: float) -> void:
	module_index = index
	module_seed = seed_value
	wall_material = authored_material
	wall_asset = get_node_or_null("AuthoredVesselWallAsset") as Node3D
	if wall_asset == null:
		push_error("OrganicWallModule requires AuthoredVesselWallAsset")
		return
	_initialize_authored_asset()

func _initialize_authored_asset() -> void:
	_apply_authored_material()
	_collect_wall_spots()
	_start_breathing_clip()
	print("M1 wall module: index=%02d; spots=%d; breathing_clip=%s" % [module_index, spot_entries.size(), str(_has_breathing_clip())])

func _process(delta: float) -> void:
	elapsed += delta
	for spot_data in spot_entries:
		var spot: MeshInstance3D = spot_data.node
		if not is_instance_valid(spot) or not spot.visible:
			continue
		var phase: float = float(spot_data.phase)
		var base_scale: Vector3 = spot_data.base_scale
		var breath := sin(elapsed * (1.05 + float(spot_data.rate) * 0.12) + phase) * 0.5 + 0.5
		var irregular := sin(elapsed * 0.63 + phase * 1.7) * 0.05
		spot.scale = base_scale * (0.82 + breath * 0.30 + irregular)

func damage_spot(spot_index: int, damage: float = 1.0) -> bool:
	if spot_index < 0 or spot_index >= spot_entries.size():
		return false
	var spot_data: Dictionary = spot_entries[spot_index]
	if float(spot_data.health) <= 0.0:
		return false
	spot_data.health = maxf(0.0, float(spot_data.health) - maxf(damage, 0.0))
	var spot: MeshInstance3D = spot_data.node
	if spot_data.health <= 0.0:
		# Keep the socket alive for a short authored-feeling flash and squash;
		# disappearance follows the deformation instead of happening instantly.
		var flash_material := StandardMaterial3D.new()
		flash_material.albedo_color = Color("ff7380")
		flash_material.emission_enabled = true
		flash_material.emission = Color("ff1636")
		flash_material.emission_energy_multiplier = 3.2
		flash_material.roughness = 0.18
		spot.material_override = flash_material
		spot.scale = spot_data.base_scale
		var destruction_tween := create_tween()
		destruction_tween.tween_property(spot, "scale", spot_data.base_scale * 1.22, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		destruction_tween.tween_callback(func():
			_spawn_spot_destroy_burst(spot.global_position, spot)
		)
		destruction_tween.tween_property(spot, "scale", spot_data.base_scale * 0.035, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		destruction_tween.tween_callback(func():
			spot.visible = false
			spot.material_override = null
			spot_destroyed.emit(self, spot_index)
			print("M1 wall spot destroyed: module=%02d; spot=%02d; alive=%d" % [module_index, spot_index, alive_spot_count()])
		)
	else:
		spot.scale = spot_data.base_scale * 0.72
	return true

func _spawn_spot_destroy_burst(world_position: Vector3, spot: MeshInstance3D) -> void:
	var flash := OmniLight3D.new()
	flash.name = "WallVirusDestroyFlash"
	flash.light_color = Color("ff8290")
	flash.light_energy = 15.0
	flash.omni_range = 6.0
	var owner := get_parent()
	if owner != null:
		owner.add_child(flash)
	else:
		add_child(flash)
	flash.global_position = world_position
	var flash_tween := create_tween()
	flash_tween.tween_property(flash, "light_energy", 0.0, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	flash_tween.tween_callback(func():
		if is_instance_valid(flash):
			flash.queue_free()
	)

	var burst := GPUParticles3D.new()
	burst.name = "WallVirusDestroyBurst_%02d" % spot_entries.size()
	burst.amount = 42
	burst.lifetime = 0.95
	burst.one_shot = true
	burst.explosiveness = 0.96
	burst.randomness = 0.38
	burst.visibility_aabb = AABB(Vector3(-4.0, -4.0, -4.0), Vector3(8.0, 8.0, 8.0))
	var shard_mesh := BoxMesh.new()
	shard_mesh.size = Vector3(0.16, 0.07, 0.24)
	burst.draw_pass_1 = shard_mesh
	burst.draw_passes = 1
	var burst_visual := StandardMaterial3D.new()
	burst_visual.albedo_color = Color("ff7180")
	burst_visual.emission_enabled = true
	burst_visual.emission = Color("ff1638")
	burst_visual.emission_energy_multiplier = 2.2
	burst_visual.roughness = 0.22
	var source_material := spot.get_active_material(0) as BaseMaterial3D
	if source_material != null:
		burst_visual.albedo_color = source_material.albedo_color.lightened(0.16)
	burst.material_override = burst_visual
	var particle_material := ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = 0.18
	particle_material.direction = Vector3.UP
	particle_material.spread = 180.0
	particle_material.initial_velocity_min = 0.80
	particle_material.initial_velocity_max = 2.8
	particle_material.gravity = Vector3(0.0, -1.5, 0.0)
	particle_material.scale_min = 0.70
	particle_material.scale_max = 1.55
	particle_material.angular_velocity_min = -7.0
	particle_material.angular_velocity_max = 7.0
	burst.process_material = particle_material
	if owner != null:
		owner.add_child(burst)
	else:
		add_child(burst)
	burst.global_position = world_position
	await get_tree().create_timer(1.25).timeout
	if is_instance_valid(burst):
		burst.queue_free()

func reset_spots() -> void:
	for spot_data in spot_entries:
		spot_data.health = 1.0
		var spot: MeshInstance3D = spot_data.node
		spot.visible = true
		spot.material_override = null
		spot.scale = spot_data.base_scale

func alive_spot_count() -> int:
	var count := 0
	for spot_data in spot_entries:
		if float(spot_data.health) > 0.0:
			count += 1
	return count

func _apply_authored_material() -> void:
	if not is_instance_valid(wall_asset) or wall_material == null:
		return
	var fascicle_material: ShaderMaterial = wall_material.duplicate() as ShaderMaterial
	fascicle_material.set_shader_parameter("layer_tint", Vector3(1.04, 0.68, 0.74))
	fascicle_material.set_shader_parameter("layer_emission", 0.54)
	var fiber_material: ShaderMaterial = wall_material.duplicate() as ShaderMaterial
	fiber_material.set_shader_parameter("layer_tint", Vector3(0.76, 0.42, 0.50))
	fiber_material.set_shader_parameter("layer_emission", 0.30)
	for mesh_node in wall_asset.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := mesh_node as MeshInstance3D
		for surface_index in mesh_instance.mesh.get_surface_count():
			var source_material := mesh_instance.get_active_material(surface_index) as BaseMaterial3D
			if source_material != null:
				source_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		if wall_material == null:
			continue
		if mesh_instance.name == "VesselWallBreathing":
			mesh_instance.material_override = wall_material
		elif mesh_instance.name.begins_with("VesselFascicle_"):
			mesh_instance.material_override = fascicle_material
		elif mesh_instance.name.begins_with("VesselMuscleFold_"):
			mesh_instance.material_override = fascicle_material
		elif mesh_instance.name.begins_with("VesselFiber_"):
			mesh_instance.material_override = fiber_material

func _collect_wall_spots() -> void:
	spot_entries.clear()
	if not is_instance_valid(wall_asset):
		return
	for mesh_node in wall_asset.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := mesh_node as MeshInstance3D
		# A socket owns authored Core, Halo, and Spike children. Only the
		# exact WallVirusSpot_00 parent is a damage target; child meshes must
		# never inflate the modular spot count or receive a second damage call.
		var mesh_name := str(mesh_instance.name)
		var index_text := mesh_name.trim_prefix("WallVirusSpot_")
		if not mesh_name.begins_with("WallVirusSpot_") or not index_text.is_valid_int():
			continue
		spot_entries.append({
			"node": mesh_instance,
			"base_scale": mesh_instance.scale,
			"phase": module_seed + float(spot_entries.size()) * 1.73,
			"rate": 0.8 + fmod(float(spot_entries.size()), 4.0) * 0.35,
			"health": 1.0
		})

func _start_breathing_clip() -> void:
	var animation_player := wall_asset.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation_player == null or not animation_player.has_animation("VesselWall_Breathing"):
		return
	var clip := animation_player.get_animation("VesselWall_Breathing")
	clip.loop_mode = Animation.LOOP_LINEAR
	animation_player.play("VesselWall_Breathing", 0.28, 1.0)
	animation_player.seek(fmod(module_seed * 0.42, maxf(clip.length, 0.01)), true)

func _has_breathing_clip() -> bool:
	if not is_instance_valid(wall_asset):
		return false
	var animation_player := wall_asset.find_child("AnimationPlayer", true, false) as AnimationPlayer
	return animation_player != null and animation_player.has_animation("VesselWall_Breathing")
