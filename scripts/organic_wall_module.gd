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
		var destroyed_position := spot.global_position
		spot.visible = false
		_spawn_spot_destroy_burst(destroyed_position, spot)
		spot_destroyed.emit(self, spot_index)
		print("M1 wall spot destroyed: module=%02d; spot=%02d; alive=%d" % [module_index, spot_index, alive_spot_count()])
	else:
		spot.scale = spot_data.base_scale * 0.72
	return true

func _spawn_spot_destroy_burst(world_position: Vector3, spot: MeshInstance3D) -> void:
	var burst := GPUParticles3D.new()
	burst.name = "WallVirusDestroyBurst_%02d" % spot_entries.size()
	burst.amount = 28
	burst.lifetime = 0.85
	burst.one_shot = true
	burst.explosiveness = 0.92
	burst.randomness = 0.32
	burst.visibility_aabb = AABB(Vector3(-3.0, -3.0, -3.0), Vector3(6.0, 6.0, 6.0))
	var shard_mesh := SphereMesh.new()
	shard_mesh.radius = 0.075
	shard_mesh.height = 0.15
	shard_mesh.radial_segments = 8
	shard_mesh.rings = 4
	burst.draw_pass_1 = shard_mesh
	burst.draw_passes = 1
	var burst_visual := StandardMaterial3D.new()
	burst_visual.albedo_color = Color("ff5364")
	burst_visual.emission_enabled = true
	burst_visual.emission = Color("ff2038")
	burst_visual.emission_energy_multiplier = 1.6
	burst_visual.roughness = 0.28
	var source_material := spot.get_active_material(0) as BaseMaterial3D
	if source_material != null:
		burst_visual.albedo_color = source_material.albedo_color.lightened(0.16)
	burst.material_override = burst_visual
	var particle_material := ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = 0.16
	particle_material.direction = Vector3.UP
	particle_material.spread = 180.0
	particle_material.initial_velocity_min = 0.55
	particle_material.initial_velocity_max = 2.2
	particle_material.gravity = Vector3(0.0, -1.5, 0.0)
	particle_material.scale_min = 0.55
	particle_material.scale_max = 1.35
	particle_material.angular_velocity_min = -5.0
	particle_material.angular_velocity_max = 5.0
	burst.process_material = particle_material
	var owner := get_parent()
	if owner != null:
		owner.add_child(burst)
	else:
		add_child(burst)
	burst.global_position = world_position
	await get_tree().create_timer(1.15).timeout
	if is_instance_valid(burst):
		burst.queue_free()

func reset_spots() -> void:
	for spot_data in spot_entries:
		spot_data.health = 1.0
		var spot: MeshInstance3D = spot_data.node
		spot.visible = true
		spot.scale = spot_data.base_scale

func alive_spot_count() -> int:
	var count := 0
	for spot_data in spot_entries:
		if float(spot_data.health) > 0.0:
			count += 1
	return count

func _apply_authored_material() -> void:
	if not is_instance_valid(wall_asset):
		return
	for mesh_node in wall_asset.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := mesh_node as MeshInstance3D
		for surface_index in mesh_instance.mesh.get_surface_count():
			var source_material := mesh_instance.get_active_material(surface_index) as BaseMaterial3D
			if source_material != null:
				source_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		if mesh_instance.name == "VesselWallBreathing" and wall_material != null:
			mesh_instance.material_override = wall_material

func _collect_wall_spots() -> void:
	spot_entries.clear()
	if not is_instance_valid(wall_asset):
		return
	for mesh_node in wall_asset.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := mesh_node as MeshInstance3D
		if not mesh_instance.name.begins_with("WallVirusSpot_") or mesh_instance.name.ends_with("_Core"):
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
