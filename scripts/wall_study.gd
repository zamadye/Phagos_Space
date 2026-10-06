extends Node3D

## Isolated wall-first calibration scene.
## This deliberately omits the route, player, blood track, and hazards so the
## Blender-authored membrane, glossy response, breathing clip, and wall-virus
## spots can be judged as a modular environment asset on their own.

const WallModuleScript = preload("res://scripts/organic_wall_module.gd")
const WallScene = preload("res://assets/vessel_wall_breathing.glb")
const WallShader = preload("res://shaders/organic_wall.gdshader")

var wall_material: ShaderMaterial
var wall_modules: Array[OrganicWallModule] = []
var elapsed: float = 0.0
var pulse_strength: float = 0.0
var pulse_position := Vector3(0.0, 20.6, -16.0)

func _ready() -> void:
	_build_environment()
	_build_wall_modules()
	_build_camera()
	_build_overlay()

func _process(delta: float) -> void:
	elapsed += delta
	pulse_strength = move_toward(pulse_strength, 0.0, delta * 1.4)
	if Input.is_key_pressed(KEY_SPACE):
		pulse_strength = 1.0
	if is_instance_valid(wall_material):
		wall_material.set_shader_parameter("breathing_clock", elapsed)
		wall_material.set_shader_parameter("event_world_position", pulse_position)
		wall_material.set_shader_parameter("event_strength", pulse_strength)
		wall_material.set_shader_parameter("event_radius", 3.2)

func _build_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("160207")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("8a2037")
	environment.ambient_light_energy = 1.15
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world := WorldEnvironment.new()
	world.name = "WallStudyEnvironment"
	world.environment = environment
	add_child(world)
	var red_light := OmniLight3D.new()
	red_light.name = "WallGlossLight"
	red_light.light_color = Color("ff526c")
	red_light.light_energy = 11.0
	red_light.omni_range = 28.0
	red_light.position = Vector3(-5.0, 10.0, 1.0)
	add_child(red_light)
	var rim_light := OmniLight3D.new()
	rim_light.name = "WallRimLight"
	rim_light.light_color = Color("7c2c78")
	rim_light.light_energy = 5.0
	rim_light.omni_range = 22.0
	rim_light.position = Vector3(5.0, 5.0, -18.0)
	add_child(rim_light)

func _build_wall_modules() -> void:
	wall_material = ShaderMaterial.new()
	wall_material.shader = WallShader
	var placement_root := get_node_or_null("GodotBreathingDriver") as Node3D
	if placement_root == null:
		placement_root = Node3D.new()
		placement_root.name = "GodotBreathingDriver"
		add_child(placement_root)
	var module_basis := Basis(Vector3.RIGHT, Vector3(0.0, 0.0, -1.0), Vector3.UP)
	for index in 5:
		var module: OrganicWallModule = WallModuleScript.new()
		module.name = "WallStudyModule_%02d" % index
		module.position = Vector3(0.0, 5.8, -float(index) * 10.0)
		module.basis = module_basis
		module.scale = Vector3.ONE
		placement_root.add_child(module)
		module.configure(WallScene, wall_material, index, float(index) * 1.7)
		wall_modules.append(module)
	print("GODOT wall animation: clip=WallStudy_Breathing; driver=GodotBreathingDriver")
	print("WALL STUDY ready: modules=5; authored_spots=45; space=isolated")

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_D:
		_damage_next_spot()

func _damage_next_spot() -> void:
	# The isolated preview damages the nearest socket in the camera frustum so
	# the flash, deformation, burst, and disappearance are directly judgeable.
	var camera := get_viewport().get_camera_3d()
	var camera_position := camera.global_position if camera != null else Vector3.ZERO
	var camera_forward := -camera.global_transform.basis.z if camera != null else Vector3.FORWARD
	var nearest_module: OrganicWallModule = null
	var nearest_index := -1
	var nearest_distance := INF
	for module in wall_modules:
		for spot_index in module.spot_entries.size():
			var spot_data: Dictionary = module.spot_entries[spot_index]
			if float(spot_data.health) <= 0.0:
				continue
			var spot: MeshInstance3D = spot_data.node
			var to_spot := spot.global_position - camera_position
			if camera != null and camera_forward.dot(to_spot.normalized()) <= 0.0:
				continue
			var distance := camera_position.distance_squared_to(spot.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_module = module
				nearest_index = spot_index
	if nearest_module != null and nearest_index >= 0:
		var target: MeshInstance3D = nearest_module.spot_entries[nearest_index].node
		pulse_position = target.global_position
		pulse_strength = 1.0
		nearest_module.damage_spot(nearest_index)

func _build_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "WallStudyCamera"
	camera.current = true
	camera.fov = 62.0
	camera.near = 0.05
	camera.far = 90.0
	# Wall-first framing: stay inside the lumen but close to the membrane so
	# gloss, authored folds, breathing deformation, and virus spots are legible.
	camera.position = Vector3(-10.8, 7.6, 3.8)
	add_child(camera)
	camera.look_at(Vector3(-13.8, 7.0, -21.0), Vector3.UP)

func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "WallStudyOverlay"
	add_child(layer)
	var label := Label.new()
	label.position = Vector2(28.0, 24.0)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("ffe2d8"))
	label.text = "WALL STUDY  //  MODULAR AUTHORED MEMBRANE\nSPACE: local wall pulse   D: destroy next wall spot"
	layer.add_child(label)
