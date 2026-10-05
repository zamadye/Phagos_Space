extends Node3D

## M1 playable biological arena.
## The arena is built from procedural 3D geometry so the player moves through a
## real world-space tunnel. M1 uses a procedural gameplay placeholder; M2 imports
## the intact Pokemon player and biological enemy/boss GLBs as visual children.
## Skills, collision, and behavior are added by wrapper/controller nodes without
## unpacking or changing the source GLB geometry, materials, or skeletons.

const BioActorScript = preload("res://scripts/bio_actor.gd")
const SiderocyteScene = preload("res://assets/siderocyte.glb")
const PokemonPackScene = preload("res://low_poly_animated_pokemon_cartoon_character_pack.glb")

const TRACK_WIDTH := 5.4
const RAIL_RADIUS := 0.34
const TUNNEL_RADIUS := 15.0
const TUNNEL_CENTER_HEIGHT := 5.8
const START_DISTANCE := 2.0
const RUN_SPEED := 7.0
const MAX_LANE_OFFSET := 1.85

var path_curve: Curve3D
var path_length: float = 0.0
var player_distance: float = START_DISTANCE
var lane_offset: float = 0.0
var run_speed: float = RUN_SPEED
var session_finished: bool = false
var elapsed_run_time: float = 0.0
var hazard_cooldown: float = 0.0
var hazard_message_time: float = 0.0
var slowdown_time: float = 0.0
var hit_count: int = 0
var hazards: Array[Dictionary] = []

var actors_root: Node3D
var player: Node3D
var camera: Camera3D
var tunnel_material: ShaderMaterial
var track_material: ShaderMaterial
var rail_material: StandardMaterial3D
var player_parts: Dictionary = {}
var pokemon_visual: Node3D

var hud_layer: CanvasLayer
var hud_label: Label
var finish_panel: ColorRect
var finish_label: Label
var reference_overlay: TextureRect
var reference_overlay_enabled: bool = false

func _ready() -> void:
	_build_environment()
	_build_path()
	_build_tunnel()
	_build_track()
	_build_biological_field()
	_build_hazards()
	_build_player()
	_build_camera()
	_build_hud()
	_update_world(0.0)
	print("M1 arena ready: path_length=", snappedf(path_length, 0.1), "m; hazards=", hazards.size())

func _process(delta: float) -> void:
	if not session_finished:
		elapsed_run_time += delta
		hazard_cooldown = maxf(0.0, hazard_cooldown - delta)
		hazard_message_time = maxf(0.0, hazard_message_time - delta)
		slowdown_time = maxf(0.0, slowdown_time - delta)
		run_speed = RUN_SPEED if slowdown_time <= 0.0 else RUN_SPEED * 0.42
		var steer := Input.get_axis("move_left", "move_right")
		if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
			steer -= 1.0
		if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
			steer += 1.0
		steer = clampf(steer, -1.0, 1.0)
		lane_offset = clampf(lane_offset + steer * delta * 4.8, -MAX_LANE_OFFSET, MAX_LANE_OFFSET)
		player_distance += run_speed * delta
		_check_hazards()
		if player_distance >= path_length - 3.0:
			player_distance = path_length - 3.0
			session_finished = true
			_finish_session()
		_update_world(delta)
	else:
		if Input.is_action_just_pressed("restart_run") or Input.is_key_pressed(KEY_R):
			_restart_session()
		_update_world(delta)

func _build_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("3b0b16")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b84f5b")
	environment.ambient_light_energy = 0.72
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("6d202d")
	environment.fog_light_energy = 0.55
	environment.fog_density = 0.012
	environment.fog_sky_affect = 0.0

	var world := WorldEnvironment.new()
	world.name = "BiologicalWorldEnvironment"
	world.environment = environment
	add_child(world)

	var key_light := DirectionalLight3D.new()
	key_light.name = "WarmVesselLight"
	key_light.light_color = Color("ff8390")
	key_light.light_energy = 0.72
	key_light.shadow_enabled = false
	key_light.rotation_degrees = Vector3(-42.0, -25.0, 0.0)
	add_child(key_light)

	var blue_light := OmniLight3D.new()
	blue_light.name = "CoolCellLight"
	blue_light.light_color = Color("4e9fd0")
	blue_light.light_energy = 2.4
	blue_light.omni_range = 28.0
	blue_light.position = Vector3(-5.0, 5.0, -28.0)
	add_child(blue_light)

	var gold_light := OmniLight3D.new()
	gold_light.name = "GoldParticleLight"
	gold_light.light_color = Color("ffd86a")
	gold_light.light_energy = 2.0
	gold_light.omni_range = 24.0
	gold_light.position = Vector3(4.0, 4.0, -62.0)
	add_child(gold_light)

func _build_path() -> void:
	path_curve = Curve3D.new()
	path_curve.bake_interval = 0.45
	var points := [
		Vector3(0.0, 0.0, 7.0),
		Vector3(-0.8, 0.0, -18.0),
		Vector3(2.8, 0.1, -49.0),
		Vector3(4.4, 0.0, -76.0),
		Vector3(-3.4, 0.2, -106.0),
		Vector3(-4.3, 0.0, -139.0),
		Vector3(2.4, 0.0, -170.0),
		Vector3(3.2, 0.2, -202.0),
		Vector3(-1.0, 0.0, -234.0),
		Vector3(-3.8, 0.0, -265.0)
	]
	for index in points.size():
		var incoming := Vector3.ZERO
		var outgoing := Vector3.ZERO
		if index > 0:
			incoming = (points[index - 1] - points[index]) * 0.22
		if index < points.size() - 1:
			outgoing = (points[index + 1] - points[index]) * 0.22
		path_curve.add_point(points[index], incoming, outgoing)
	path_length = path_curve.get_baked_length()

	var path_node := Path3D.new()
	path_node.name = "BloodstreamPath"
	path_node.curve = path_curve
	add_child(path_node)

func _path_frame(distance: float) -> Dictionary:
	var safe_distance := clampf(distance, 0.0, path_length)
	var position := path_curve.sample_baked(safe_distance)
	var look_distance := minf(safe_distance + 0.6, path_length)
	var tangent := (path_curve.sample_baked(look_distance) - position).normalized()
	if tangent.length_squared() < 0.001:
		tangent = Vector3(0.0, 0.0, -1.0)
	var right := tangent.cross(Vector3.UP).normalized()
	if right.length_squared() < 0.001:
		right = Vector3.RIGHT
	var up := right.cross(tangent).normalized()
	return {"position": position, "tangent": tangent, "right": right, "up": up}

func _build_tunnel() -> void:
	tunnel_material = _make_tunnel_material()
	var tunnel := MeshInstance3D.new()
	tunnel.name = "AnimatedVesselShell"
	tunnel.mesh = _make_tunnel_mesh(64, 24)
	tunnel.material_override = tunnel_material
	add_child(tunnel)

	var tunnel_cap := MeshInstance3D.new()
	tunnel_cap.name = "VesselFarEndCap"
	tunnel_cap.mesh = _make_tunnel_cap_mesh(24)
	var cap_material := _material(Color("7b1b2b"), Color("5a101e"), 0.62)
	tunnel_cap.material_override = cap_material
	add_child(tunnel_cap)

func _make_tunnel_mesh(rings: int, ring_vertices: int) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for ring in rings + 1:
		var ratio := float(ring) / float(rings)
		var frame := _path_frame(path_length * ratio)
		var center: Vector3 = frame.position + frame.up * TUNNEL_CENTER_HEIGHT
		var right: Vector3 = frame.right
		var up: Vector3 = frame.up
		for slice in ring_vertices:
			var around := TAU * float(slice) / float(ring_vertices)
			var normal := (right * cos(around) + up * sin(around)).normalized()
			vertices.append(center + normal * TUNNEL_RADIUS)
			normals.append(normal)
			uvs.append(Vector2(float(slice) / float(ring_vertices), ratio))
	for ring in rings:
		for slice in ring_vertices:
			var current := ring * ring_vertices + slice
			var next_slice := ring * ring_vertices + ((slice + 1) % ring_vertices)
			var next_ring := (ring + 1) * ring_vertices + slice
			var next_both := (ring + 1) * ring_vertices + ((slice + 1) % ring_vertices)
			indices.append(current)
			indices.append(next_ring)
			indices.append(next_slice)
			indices.append(next_slice)
			indices.append(next_ring)
			indices.append(next_both)
	return _array_mesh(vertices, normals, uvs, indices)

func _make_tunnel_cap_mesh(ring_vertices: int) -> ArrayMesh:
	var frame := _path_frame(path_length)
	var center: Vector3 = frame.position + frame.up * TUNNEL_CENTER_HEIGHT
	var vertices := PackedVector3Array([center])
	var normals := PackedVector3Array([-frame.tangent])
	var uvs := PackedVector2Array([Vector2(0.5, 0.5)])
	var indices := PackedInt32Array()
	for slice in ring_vertices:
		var around := TAU * float(slice) / float(ring_vertices)
		var radial: Vector3 = (frame.right * cos(around) + frame.up * sin(around)).normalized()
		vertices.append(center + radial * TUNNEL_RADIUS)
		normals.append(-frame.tangent)
		uvs.append(Vector2(0.5 + cos(around) * 0.5, 0.5 + sin(around) * 0.5))
	for slice in ring_vertices:
		indices.append(0)
		indices.append(1 + slice)
		indices.append(1 + ((slice + 1) % ring_vertices))
	return _array_mesh(vertices, normals, uvs, indices)

func _build_track() -> void:
	track_material = _make_track_material()
	rail_material = StandardMaterial3D.new()
	rail_material.albedo_color = Color("8d6baa")
	rail_material.roughness = 0.44
	rail_material.metallic = 0.05
	rail_material.emission_enabled = true
	rail_material.emission = Color("3b214f")
	rail_material.emission_energy_multiplier = 0.48

	var track := MeshInstance3D.new()
	track.name = "SalmonPathSurface"
	track.mesh = _make_ribbon_mesh(TRACK_WIDTH, 0.12)
	track.material_override = track_material
	add_child(track)

	for side in [-1, 1]:
		var rail := MeshInstance3D.new()
		rail.name = "LavenderRail" + str(side)
		rail.mesh = _make_rail_mesh(side, RAIL_RADIUS)
		rail.material_override = rail_material
		add_child(rail)

func _make_ribbon_mesh(width: float, height: float) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var steps := maxi(2, int(path_length / 1.25))
	for step in steps + 1:
		var ratio := float(step) / float(steps)
		var frame := _path_frame(path_length * ratio)
		var center: Vector3 = frame.position + frame.up * height
		vertices.append(center - frame.right * width * 0.5)
		vertices.append(center + frame.right * width * 0.5)
		normals.append(frame.up)
		normals.append(frame.up)
		uvs.append(Vector2(ratio * 6.0, 0.0))
		uvs.append(Vector2(ratio * 6.0, 1.0))
	for step in steps:
		var a := step * 2
		var b := a + 1
		var c := a + 2
		var d := a + 3
		indices.append(a)
		indices.append(c)
		indices.append(b)
		indices.append(b)
		indices.append(c)
		indices.append(d)
	return _array_mesh(vertices, normals, uvs, indices)

func _make_rail_mesh(side: int, radius: float) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var steps := maxi(2, int(path_length / 1.25))
	var ring_vertices := 8
	for step in steps + 1:
		var ratio := float(step) / float(steps)
		var frame := _path_frame(path_length * ratio)
		var center: Vector3 = frame.position + frame.right * (side * (TRACK_WIDTH * 0.5 + radius * 0.55)) + frame.up * 0.45
		for slice in ring_vertices:
			var around := TAU * float(slice) / float(ring_vertices)
			var normal: Vector3 = (frame.right * cos(around) + frame.up * sin(around)).normalized()
			vertices.append(center + normal * radius)
			normals.append(normal)
			uvs.append(Vector2(ratio * 6.0, float(slice) / float(ring_vertices)))
	for step in steps:
		for slice in ring_vertices:
			var current := step * ring_vertices + slice
			var next_slice := step * ring_vertices + ((slice + 1) % ring_vertices)
			var next_ring := (step + 1) * ring_vertices + slice
			var next_both := (step + 1) * ring_vertices + ((slice + 1) % ring_vertices)
			indices.append(current)
			indices.append(next_ring)
			indices.append(next_slice)
			indices.append(next_slice)
			indices.append(next_ring)
			indices.append(next_both)
	return _array_mesh(vertices, normals, uvs, indices)

func _array_mesh(vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, indices: PackedInt32Array) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _build_biological_field() -> void:
	actors_root = Node3D.new()
	actors_root.name = "LivingBiologicalActors"
	add_child(actors_root)

	var blue_material := _material(Color("2c78ad"), Color("1e73aa"), 0.95)
	var yellow_material := _material(Color("f3c64c"), Color("f8ba3c"), 0.88)
	var red_material := _material(Color("d85e64"), Color("4c101d"), 0.18)
	var virus_material := _material(Color("9d2939"), Color("3d0711"), 0.24)
	var vesicle_material := _material(Color("d26b91"), Color("7d1d4d"), 0.3)
	var dark_material := _material(Color("36101d"), Color("120208"), 0.05)

	var blue_angles := [0.9, 2.2, 3.4, 4.7, 5.5, 1.4, 3.9, 5.9]
	for index in blue_angles.size():
		var distance := 12.0 + float(index) * 28.0
		var frame := _path_frame(minf(distance, path_length - 5.0))
		var angle: float = blue_angles[index]
		var shell_center: Vector3 = frame.position + frame.up * TUNNEL_CENTER_HEIGHT
		var normal: Vector3 = (frame.right * cos(angle) + frame.up * sin(angle)).normalized()
		var actor := _actor_with_mesh("BlueMembraneCell_%02d" % index, _sphere_mesh(), blue_material)
		actor.configure(shell_center + normal * (TUNNEL_RADIUS - 1.1), Vector3(1.65, 0.6, 1.1), float(index) * 1.31, 0.75, 0.12, 0.08)
		actor.drift_axis = frame.tangent
		actors_root.add_child(actor)

	for index in 24:
		var distance := 8.0 + float(index) * 10.2
		var frame := _path_frame(minf(distance, path_length - 4.0))
		var side := -1.0 if index % 2 == 0 else 1.0
		var offset := sin(float(index) * 2.14) * 1.8
		var actor := _actor_with_mesh("GoldenParticle_%02d" % index, _sphere_mesh(), yellow_material)
		actor.configure(frame.position + frame.right * (offset + side * 2.0) + frame.up * (1.3 + fmod(float(index) * 0.81, 4.5)), Vector3.ONE * (0.12 + fmod(float(index), 3.0) * 0.035), float(index) * 0.73, 0.6 + fmod(float(index), 4.0) * 0.17, 0.3, 0.15)
		actor.drift_axis = Vector3.UP
		actors_root.add_child(actor)

	for index in 15:
		var distance := 18.0 + float(index) * 15.5
		var frame := _path_frame(minf(distance, path_length - 5.0))
		var offset := sin(float(index) * 1.8) * 1.8
		var actor: BioActor = BioActorScript.new()
		actor.name = "RedBloodCell_%02d" % index
		if index % 3 == 0:
			var siderocyte: Node3D = SiderocyteScene.instantiate()
			siderocyte.name = "SiderocyteGLBVisual"
			siderocyte.scale = Vector3.ONE * 0.34
			actor.add_child(siderocyte)
		else:
			var visual := MeshInstance3D.new()
			visual.name = "ProceduralRedCellVisual"
			visual.mesh = _sphere_mesh()
			visual.material_override = red_material
			actor.add_child(visual)
		actor.configure(frame.position + frame.right * offset + frame.up * 0.7, Vector3(0.95 + fmod(float(index), 3.0) * 0.22, 0.24, 0.82), float(index) * 0.9, 0.9, 0.22, 0.25)
		actor.drift_axis = frame.tangent
		actors_root.add_child(actor)

	for index in 8:
		var distance := 30.0 + float(index) * 29.0
		var frame := _path_frame(minf(distance, path_length - 5.0))
		var offset := sin(float(index) * 2.7) * 1.6
		var virus := _make_virus("Pathogen_%02d" % index, virus_material, dark_material)
		virus.configure(frame.position + frame.right * offset + frame.up * 0.9, Vector3.ONE * (0.72 + fmod(float(index), 3.0) * 0.1), float(index) * 1.22, 1.2, 0.16, 0.34)
		actors_root.add_child(virus)

	for index in 4:
		var distance := 48.0 + float(index) * 47.0
		var frame := _path_frame(minf(distance, path_length - 6.0))
		var side := -1.0 if index % 2 == 0 else 1.0
		var amoeba := _make_vesicle("LivingVesicle_%02d" % index, vesicle_material, yellow_material)
		amoeba.configure(frame.position + frame.right * (side * 4.7) + frame.up * (2.8 + fmod(float(index), 2.0)), Vector3.ONE * 1.2, float(index) * 2.2, 0.55, 0.28, 0.12)
		amoeba.drift_axis = frame.tangent
		actors_root.add_child(amoeba)

func _build_hazards() -> void:
	var hazard_root := Node3D.new()
	hazard_root.name = "TrackHazards"
	add_child(hazard_root)
	var hazard_material := _material(Color("ef465b"), Color("ff193f"), 0.9)
	var core_material := _material(Color("ffd36b"), Color("ff9e38"), 1.25)
	var hazard_data := [
		{"distance": 34.0, "lane": -1.25, "phase": 0.3},
		{"distance": 72.0, "lane": 0.0, "phase": 1.7},
		{"distance": 111.0, "lane": 1.3, "phase": 2.9},
		{"distance": 154.0, "lane": -0.8, "phase": 4.2},
		{"distance": 201.0, "lane": 1.15, "phase": 5.4},
		{"distance": 244.0, "lane": -1.4, "phase": 6.5}
	]
	for index in hazard_data.size():
		var data: Dictionary = hazard_data[index]
		var frame := _path_frame(float(data.distance))
		var area := Area3D.new()
		area.name = "HazardCollision_%02d" % index
		area.position = frame.position + frame.right * float(data.lane) + frame.up * 0.78
		area.collision_layer = 2
		area.collision_mask = 1
		var collision := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.78
		collision.shape = shape
		area.add_child(collision)
		var shell := MeshInstance3D.new()
		shell.name = "HazardShell"
		shell.mesh = _sphere_mesh()
		shell.scale = Vector3(0.72, 0.42, 0.72)
		shell.material_override = hazard_material
		area.add_child(shell)
		var core := MeshInstance3D.new()
		core.name = "HazardCore"
		core.mesh = _sphere_mesh()
		core.scale = Vector3.ONE * 0.22
		core.material_override = core_material
		area.add_child(core)
		hazard_root.add_child(area)
		hazards.append({"distance": float(data.distance), "lane": float(data.lane), "phase": float(data.phase), "node": area})

func _check_hazards() -> void:
	if hazard_cooldown > 0.0:
		return
	for hazard in hazards:
		var distance_gap := absf(player_distance - float(hazard.distance))
		var lane_gap := absf(lane_offset - float(hazard.lane))
		if distance_gap < 1.35 and lane_gap < 0.72:
			hazard_cooldown = 2.0
			slowdown_time = 1.25
			hazard_message_time = 1.5
			hit_count += 1
			print("M1 hazard collision: index=", hazards.find(hazard), " hit_count=", hit_count)
			player_distance = maxf(START_DISTANCE, player_distance - 4.5)
			lane_offset = clampf(lane_offset - signf(float(hazard.lane)) * 0.35, -MAX_LANE_OFFSET, MAX_LANE_OFFSET)
			break

func _actor_with_mesh(actor_name: String, mesh: Mesh, material: Material) -> BioActor:
	var actor: BioActor = BioActorScript.new()
	actor.name = actor_name
	var visual := MeshInstance3D.new()
	visual.name = "Procedural3DVisual"
	visual.mesh = mesh
	visual.material_override = material
	actor.add_child(visual)
	return actor

func _make_virus(actor_name: String, core_material: Material, spike_material: Material) -> BioActor:
	var virus: BioActor = BioActorScript.new()
	virus.name = actor_name
	var core := MeshInstance3D.new()
	core.name = "VirusCore3D"
	core.mesh = _sphere_mesh()
	core.material_override = core_material
	virus.add_child(core)
	var spike_mesh := BoxMesh.new()
	spike_mesh.size = Vector3(0.18, 0.18, 0.75)
	for index in 8:
		var spike := MeshInstance3D.new()
		spike.name = "Spike_%02d" % index
		spike.mesh = spike_mesh
		spike.material_override = spike_material
		var angle := TAU * float(index) / 8.0
		spike.position = Vector3(cos(angle) * 0.48, sin(angle) * 0.48, 0.0)
		spike.rotation_degrees = Vector3(0.0, 0.0, -rad_to_deg(angle))
		virus.add_child(spike)
	return virus

func _make_vesicle(actor_name: String, membrane_material: Material, dot_material: Material) -> BioActor:
	var vesicle: BioActor = BioActorScript.new()
	vesicle.name = actor_name
	var body := MeshInstance3D.new()
	body.name = "VesicleMembrane"
	body.mesh = _sphere_mesh()
	body.material_override = membrane_material
	vesicle.add_child(body)
	for index in 5:
		var dot := MeshInstance3D.new()
		dot.name = "VesicleDot_%02d" % index
		dot.mesh = _sphere_mesh()
		dot.material_override = dot_material
		var angle := TAU * float(index) / 5.0
		dot.position = Vector3(cos(angle) * 0.5, sin(angle * 1.7) * 0.4, sin(angle) * 0.5)
		dot.scale = Vector3.ONE * 0.09
		vesicle.add_child(dot)
	return vesicle

func _sphere_mesh() -> SphereMesh:
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	return sphere

func _material(color: Color, emission: Color, emission_energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.48
	material.metallic = 0.02
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = emission_energy
	return material

func _make_tunnel_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled, unshaded, specular_disabled;

uniform vec3 red_deep : source_color = vec3(0.20, 0.015, 0.028);
uniform vec3 red_mid : source_color = vec3(0.46, 0.045, 0.075);
uniform vec3 red_hot : source_color = vec3(0.76, 0.12, 0.16);
uniform float journey_phase = 0.0;

void vertex() {
    VERTEX += NORMAL * sin(journey_phase * 0.35) * 0.0;
    float breathing = sin(TIME * 0.72 + UV.y * 18.0 + UV.x * 4.0) * 0.07;
    VERTEX += NORMAL * breathing;
}

void fragment() {
    float fibers = sin(UV.x * 72.0 + sin(UV.y * 14.0) * 4.0 + TIME * 0.22) * 0.5 + 0.5;
    float flow = sin(UV.y * 34.0 - TIME * 0.8 + UV.x * 9.0) * 0.5 + 0.5;
    float zone = sin(UV.y * 11.0 + TIME * 0.035) * 0.5 + 0.5;
    vec3 zone_color = mix(red_mid, red_hot, smoothstep(0.58, 0.96, zone));
    vec3 color = mix(red_deep, zone_color, 0.48 + fibers * 0.24);
    color += red_hot * pow(flow, 7.0) * 0.13;
    ALBEDO = color;
    ROUGHNESS = 0.62 - flow * 0.12;
    EMISSION = color * (0.045 + flow * 0.035);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material

func _make_track_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_disabled;
uniform float journey_phase = 0.0;

void vertex() {
    VERTEX.y += sin(UV.x * 16.0 + TIME * 1.8) * 0.035;
}

void fragment() {
    float current = sin(UV.x * 42.0 - TIME * 2.4) * 0.5 + 0.5;
    float zone = sin(UV.x * 4.2) * 0.5 + 0.5;
    vec3 salmon_a = vec3(0.70, 0.34, 0.40);
    vec3 salmon_b = vec3(0.96, 0.62, 0.58);
    vec3 color = mix(salmon_a, salmon_b, zone * 0.38 + current * 0.12);
    ALBEDO = color;
    ROUGHNESS = 0.54;
    EMISSION = color * (0.025 + current * 0.025);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material

func _attach_pokemon_player_visual() -> void:
	# The repository GLB is a multi-character pack. Keep the imported scene
	# intact and select the contained Pikachu armature as the M2 player visual.
	# No mesh, material, skeleton, or source GLB data is edited here.
	var pack: Node3D = PokemonPackScene.instantiate()
	pack.name = "PokemonCharacterPackGLB_Intact"
	# Integration scale only; mesh/material/skeleton data remain untouched.
	pack.scale = Vector3.ONE * 1.8
	player.add_child(pack)
	var model_root := pack.get_node_or_null("Sketchfab_model/root/GLTF_SceneRootNode") as Node3D
	if model_root == null:
		push_warning("Pokemon pack model root was not found; keeping M1 fallback visual")
		return
	for child in model_root.get_children():
		if child is Node3D:
			(child as Node3D).visible = child.name == "Armature_34"
	pokemon_visual = model_root.get_node_or_null("Armature_34") as Node3D
	if pokemon_visual == null:
		push_warning("Pokemon armature Armature_34 was not found; keeping M1 fallback visual")
		return
	pokemon_visual.name = "PokemonPlayerVisual_Intact"

func _build_player() -> void:
	player = Node3D.new()
	player.name = "PlayerCharacter3D"
	add_child(player)
	_attach_pokemon_player_visual()

	var body_material := _material(Color("6f7780"), Color("202830"), 0.08)
	var helmet_material := _material(Color("c8cdd2"), Color("8b9aa2"), 0.18)
	var dark_material := _material(Color("20252c"), Color("07090b"), 0.02)

	var body := MeshInstance3D.new()
	body.name = "Body"
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.42
	capsule.height = 1.35
	capsule.radial_segments = 12
	capsule.rings = 4
	body.mesh = capsule
	body.material_override = body_material
	body.position = Vector3(0.0, 1.05, 0.0)
	player.add_child(body)
	player_parts["body"] = body

	var helmet := MeshInstance3D.new()
	helmet.name = "Helmet"
	helmet.mesh = _sphere_mesh()
	helmet.material_override = helmet_material
	helmet.position = Vector3(0.0, 1.95, -0.04)
	helmet.scale = Vector3(0.5, 0.58, 0.5)
	player.add_child(helmet)
	player_parts["helmet"] = helmet

	var backpack := MeshInstance3D.new()
	backpack.name = "Backpack"
	var backpack_mesh := BoxMesh.new()
	backpack_mesh.size = Vector3(0.8, 0.92, 0.34)
	backpack.mesh = backpack_mesh
	backpack.material_override = dark_material
	backpack.position = Vector3(0.0, 1.15, 0.4)
	player.add_child(backpack)

	for side in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		leg.name = "Leg" + str(side)
		var leg_mesh := BoxMesh.new()
		leg_mesh.size = Vector3(0.23, 0.78, 0.3)
		leg.mesh = leg_mesh
		leg.material_override = dark_material
		leg.position = Vector3(side * 0.23, 0.38, 0.0)
		player.add_child(leg)
		player_parts["leg" + str(side)] = leg

		var arm := MeshInstance3D.new()
		arm.name = "Arm" + str(side)
		var arm_mesh := BoxMesh.new()
		arm_mesh.size = Vector3(0.22, 0.78, 0.25)
		arm.mesh = arm_mesh
		arm.material_override = body_material
		arm.position = Vector3(side * 0.58, 1.1, 0.0)
		arm.rotation_degrees = Vector3(0.0, 0.0, side * -12.0)
		player.add_child(arm)
		player_parts["arm" + str(side)] = arm

	if is_instance_valid(pokemon_visual):
		# Hide every procedural direct mesh, including the old fallback backpack.
		# The imported GLB remains the only visible player visual.
		for child in player.get_children():
			if child is MeshInstance3D:
				(child as MeshInstance3D).visible = false
		# Preserve the GLB's authored scale; only the player wrapper positions it.

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "Camera3D_ThirdPersonChase"
	camera.current = true
	camera.fov = 55.0
	camera.near = 0.05
	camera.far = 190.0
	add_child(camera)

func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "MinimalHUD"
	add_child(hud_layer)

	if OS.is_debug_build():
		var reference_texture := load("res://Gameplay-Arena.jpg") as Texture2D
		if reference_texture != null:
			reference_overlay = TextureRect.new()
			reference_overlay.name = "ReferenceCalibrationOverlay"
			reference_overlay.texture = reference_texture
			reference_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			reference_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			reference_overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			reference_overlay.modulate = Color(1.0, 1.0, 1.0, 0.32)
			reference_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			reference_overlay.visible = false
			reference_overlay.z_index = 5
			hud_layer.add_child(reference_overlay)

	hud_label = Label.new()
	hud_label.name = "RunStatus"
	hud_label.position = Vector2(28.0, 24.0)
	hud_label.add_theme_font_size_override("font_size", 18)
	hud_label.add_theme_color_override("font_color", Color("ffe7d6"))
	hud_label.text = "PHAGOS SPACE  •  RUN 01"
	hud_layer.add_child(hud_label)

	finish_panel = ColorRect.new()
	finish_panel.name = "SessionFinished"
	finish_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	finish_panel.color = Color(0.06, 0.008, 0.015, 0.84)
	finish_panel.visible = false
	hud_layer.add_child(finish_panel)

	finish_label = Label.new()
	finish_label.name = "FinishMessage"
	finish_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	finish_label.position = Vector2(-210.0, -70.0)
	finish_label.size = Vector2(420.0, 140.0)
	finish_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finish_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	finish_label.add_theme_font_size_override("font_size", 24)
	finish_label.add_theme_color_override("font_color", Color("ffe7d6"))
	finish_label.text = "SESSION COMPLETE\nPress R to run again"
	finish_panel.add_child(finish_label)

func _update_world(delta: float) -> void:
	var frame := _path_frame(player_distance)
	var player_position: Vector3 = frame.position + frame.right * lane_offset + frame.up * 0.82
	player.global_position = player_position
	player.look_at(player_position + frame.tangent, frame.up)

	var camera_position: Vector3 = player_position - frame.tangent * 10.0 + frame.up * 3.8
	camera.global_position = camera_position
	camera.look_at(player_position + frame.tangent * 12.0 + frame.up * 0.55, frame.up)

	var run_phase := elapsed_run_time * 7.0
	if player_parts.has("body"):
		var body: Node3D = player_parts["body"]
		body.position.y = 1.05 + sin(run_phase) * 0.035
	if player_parts.has("helmet"):
		var helmet: Node3D = player_parts["helmet"]
		helmet.rotation.z = sin(run_phase * 0.5) * 0.018
	for hazard in hazards:
		var hazard_node: Node3D = hazard.node
		var hazard_phase := elapsed_run_time * 4.0 + float(hazard.phase)
		hazard_node.position.y = 0.78 + sin(hazard_phase) * 0.1
		hazard_node.rotation.y = hazard_phase * 0.6

	for side in [-1.0, 1.0]:
		var leg_key := "leg" + str(side)
		if player_parts.has(leg_key):
			var leg: Node3D = player_parts[leg_key]
			leg.rotation.x = sin(run_phase + side * 1.5) * 0.16
		var arm_key := "arm" + str(side)
		if player_parts.has(arm_key):
			var arm: Node3D = player_parts[arm_key]
			arm.rotation.x = sin(run_phase + side * 1.5) * 0.14

	if is_instance_valid(hud_label):
		var progress_ratio := clampf(player_distance / maxf(path_length, 1.0), 0.0, 1.0)
		var run_state := "ACTIVE"
		if session_finished:
			run_state = "FINISH"
		elif hazard_message_time > 0.0:
			run_state = "HAZARD HIT"
		hud_label.text = "PHAGOS SPACE  •  RUN 01  •  %03d%%  •  %s  •  HITS %02d" % [int(progress_ratio * 100.0), run_state, hit_count]
	if is_instance_valid(tunnel_material):
		tunnel_material.set_shader_parameter("journey_phase", player_distance / 55.0)
	if is_instance_valid(track_material):
		track_material.set_shader_parameter("journey_phase", player_distance / 55.0)

func _finish_session() -> void:
	run_speed = 0.0
	finish_panel.visible = true
	finish_label.text = "SESSION COMPLETE\nDistance: %03dm\nPress R to run again" % int(player_distance)
	print("M1 session complete: distance=", snappedf(player_distance, 0.1), "m; hits=", hit_count)

func _restart_session() -> void:
	player_distance = START_DISTANCE
	lane_offset = 0.0
	run_speed = RUN_SPEED
	elapsed_run_time = 0.0
	hazard_cooldown = 0.0
	hazard_message_time = 0.0
	slowdown_time = 0.0
	hit_count = 0
	session_finished = false
	finish_panel.visible = false

func _toggle_reference_overlay() -> void:
	if not is_instance_valid(reference_overlay):
		return
	reference_overlay_enabled = not reference_overlay_enabled
	reference_overlay.visible = reference_overlay_enabled
	print("M1 reference overlay: ", "ON" if reference_overlay_enabled else "OFF")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F2:
		_toggle_reference_overlay()
	if event.is_action_pressed("restart_run") and session_finished:
		_restart_session()
