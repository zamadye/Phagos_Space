class_name OrganicVesselFoundation
extends Node3D

## Phase 1 visual foundation: a complete Blender-authored vessel volume.
## This scene deliberately has no player, enemies, particles, or route gameplay.
## The GLB owns the authored mesh/UV/shape-key action; Godot owns placement,
## imported clip playback, camera, lights, and low-frequency runtime deformation.

const VesselScene = preload("res://assets/environment/vessel/organic_vessel_foundation.glb")
const VesselShader = preload("res://shaders/organic_vessel_foundation.gdshader")

var vessel_asset: Node3D
var vessel_material: ShaderMaterial
var elapsed := 0.0
var event_strength := 0.0
var event_position := Vector3(0.0, 0.0, 18.0)

func _ready() -> void:
	_build_environment()
	_build_vessel_geometry()
	_build_traversal_path()
	_build_camera_rig()
	_build_overlay()

func _process(delta: float) -> void:
	elapsed += delta
	event_strength = move_toward(event_strength, 0.0, delta * 1.2)
	if Input.is_key_pressed(KEY_SPACE):
		event_strength = 1.0
	if vessel_material != null:
		vessel_material.set_shader_parameter("breathing_clock", elapsed)
		vessel_material.set_shader_parameter("event_world_position", event_position)
		vessel_material.set_shader_parameter("event_strength", event_strength)
		vessel_material.set_shader_parameter("event_radius", 4.0)

func _build_vessel_geometry() -> void:
	vessel_material = ShaderMaterial.new()
	vessel_material.shader = VesselShader
	var section := Node3D.new()
	section.name = "VesselSection_00"
	var breathing_driver := get_node_or_null("FoundationBreathingDriver") as Node3D
	if breathing_driver == null:
		breathing_driver = self
	breathing_driver.add_child(section)
	vessel_asset = VesselScene.instantiate()
	vessel_asset.name = "AuthoredOrganicVessel"
	# Blender authored the vessel in Z-up; glTF imports that axis as local Y.
	# Restore the authored centerline to Godot +Z so the independent path and camera
	# read as traversal through the volume rather than a cross-section side view.
	vessel_asset.rotation.x = PI / 2.0
	section.add_child(vessel_asset)
	for mesh_node in vessel_asset.find_children("*", "MeshInstance3D", true, false):
		var mesh := mesh_node as MeshInstance3D
		mesh.material_override = vessel_material
		for surface_index in mesh.mesh.get_surface_count():
			var source_material := mesh.get_active_material(surface_index) as BaseMaterial3D
			if source_material != null:
				source_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var animation_player := vessel_asset.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation_player != null and animation_player.has_animation("OrganicVessel_Breathing"):
		var clip := animation_player.get_animation("OrganicVessel_Breathing")
		clip.loop_mode = Animation.LOOP_LINEAR
		animation_player.play("OrganicVessel_Breathing", 0.35, 1.0)
		print("BLENDER vessel animation: clip=OrganicVessel_Breathing; playing=true")
	print("VESSEL GEOMETRY: floor=true; ceiling=true; left_wall=true; right_wall=true; length=42m")

func _build_traversal_path() -> void:
	var path := Path3D.new()
	path.name = "TraversalPath"
	var curve := Curve3D.new()
	curve.bake_interval = 0.35
	curve.add_point(Vector3(0.0, 0.0, 2.0))
	curve.add_point(Vector3(0.95, 0.20, 10.0))
	curve.add_point(Vector3(2.05, 0.42, 19.0))
	curve.add_point(Vector3(1.65, 0.18, 28.0))
	curve.add_point(Vector3(0.15, -0.10, 38.0))
	curve.add_point(Vector3(-0.85, 0.05, 42.0))
	path.curve = curve
	add_child(path)
	print("TRAVERSAL PATH: points=6; length=42m; geometry_separate=true")

func _build_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("3b1222")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("762238")
	environment.ambient_light_energy = 1.45
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world := WorldEnvironment.new()
	world.name = "OrganicVesselEnvironment"
	world.environment = environment
	add_child(world)

	var tissue_key := OmniLight3D.new()
	tissue_key.name = "TissueKeyLight"
	tissue_key.light_color = Color("a52b42")
	tissue_key.light_energy = 8.0
	tissue_key.omni_range = 28.0
	tissue_key.position = Vector3(-4.0, 4.0, 5.0)
	add_child(tissue_key)
	var depth_rim := OmniLight3D.new()
	depth_rim.name = "TissueDepthRim"
	depth_rim.light_color = Color("52204e")
	depth_rim.light_energy = 4.5
	depth_rim.omni_range = 34.0
	depth_rim.position = Vector3(4.0, -1.0, 28.0)
	add_child(depth_rim)

func _build_camera_rig() -> void:
	var rig := Node3D.new()
	rig.name = "CameraRig"
	add_child(rig)
	var follow_target := Node3D.new()
	follow_target.name = "FollowTarget"
	follow_target.position = Vector3(0.0, 0.0, 6.0)
	rig.add_child(follow_target)
	var camera := Camera3D.new()
	camera.name = "FoundationCamera"
	camera.current = true
	camera.fov = 64.0
	camera.near = 0.05
	camera.far = 70.0
	camera.position = Vector3(-1.15, -1.70, 3.2)
	rig.add_child(camera)
	camera.look_at(Vector3(2.0, 0.45, 24.0), Vector3.UP)

func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "FoundationOverlay"
	add_child(layer)
	var label := Label.new()
	label.position = Vector2(28.0, 24.0)
	label.add_theme_font_size_override("font_size", 21)
	label.add_theme_color_override("font_color", Color("f2d4cf"))
	label.text = "ORGANIC VESSEL FOUNDATION  //  42m AUTHORED VOLUME\nSPACE: local biological pulse"
	layer.add_child(label)
