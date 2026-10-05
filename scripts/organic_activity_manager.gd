class_name OrganicActivityManager
extends Node3D

## GPU-driven ambient activity for the vessel slice.
##
## Route placement and event timing remain controlled by main.gd, while the
## repeated ambient field lives in GPUParticles3D instead of one Node3D per
## particle. Authored mesh resources are used as draw passes; this controller
## never changes the source GLB geometry or materials.

var route_curve: Curve3D
var route_length: float = 0.0
var authored_cell_mesh: Mesh
var authored_organism_mesh: Mesh
var blood_material: Material
var organism_material: Material
var mote_material: Material
var activity_clock: float = 0.0
var pulse_position: Vector3 = Vector3.ZERO
var pulse_strength: float = 0.0

var blood_emitters: Array[GPUParticles3D] = []
var organism_emitters: Array[GPUParticles3D] = []
var mote_emitters: Array[GPUParticles3D] = []
var emergence_burst: GPUParticles3D
var emitter_phases: Dictionary = {}

func configure(curve: Curve3D, curve_length: float, cell_mesh: Mesh, organism_mesh: Mesh, blood_mat: Material, organism_mat: Material, mote_mat: Material) -> void:
	route_curve = curve
	route_length = curve_length
	authored_cell_mesh = cell_mesh if cell_mesh != null else _fallback_cell_mesh()
	authored_organism_mesh = organism_mesh if organism_mesh != null else _fallback_organism_mesh()
	blood_material = blood_mat
	organism_material = organism_mat
	mote_material = mote_mat
	_build_ambient_emitters()
	_build_emergence_burst()

func _process(delta: float) -> void:
	activity_clock += delta
	pulse_strength = move_toward(pulse_strength, 0.0, delta * 1.35)
	var global_wave := sin(activity_clock * 0.72) * 0.5 + 0.5
	for emitter in blood_emitters:
		var phase: float = float(emitter_phases.get(emitter, 0.0))
		emitter.amount_ratio = clampf(0.76 + global_wave * 0.14 + sin(activity_clock * 0.41 + phase) * 0.08 + pulse_strength * 0.10, 0.42, 1.0)
	for emitter in organism_emitters:
		var phase: float = float(emitter_phases.get(emitter, 0.0))
		emitter.amount_ratio = clampf(0.42 + global_wave * 0.20 + sin(activity_clock * 0.59 + phase) * 0.16 + pulse_strength * 0.32, 0.12, 1.0)
	for emitter in mote_emitters:
		var phase: float = float(emitter_phases.get(emitter, 0.0))
		emitter.amount_ratio = clampf(0.50 + sin(activity_clock * 0.86 + phase) * 0.22, 0.18, 0.92)
	if is_instance_valid(emergence_burst):
		emergence_burst.amount_ratio = clampf(0.035 + pulse_strength * 0.965, 0.02, 1.0)

func set_activity_clock(clock: float) -> void:
	activity_clock = clock

func set_emergence_event(world_position: Vector3, strength: float) -> void:
	if strength <= pulse_strength and pulse_strength > 0.05:
		return
	pulse_position = world_position
	pulse_strength = clampf(strength, 0.0, 1.0)
	if is_instance_valid(emergence_burst):
		emergence_burst.global_position = world_position
		emergence_burst.restart()

func _build_ambient_emitters() -> void:
	if route_curve == null or route_length <= 0.0:
		return
	var zone_distances := [18.0, 78.0, 140.0, 202.0, 254.0]
	for index in zone_distances.size():
		var distance := minf(float(zone_distances[index]), maxf(route_length - 5.0, 0.0))
		var frame := _curve_frame(distance)
		var blood := _make_flow_emitter("AmbientBloodFlow_%02d" % index, frame, 86, 10.5, Vector3(4.7, 1.45, 7.5), authored_cell_mesh, blood_material, 0.055, 0.13, 1.8, 3.0, 14.0, float(index) * 1.37)
		blood_emitters.append(blood)
		var organism := _make_flow_emitter("AmbientOrganisms_%02d" % index, frame, 14, 8.0, Vector3(5.2, 4.5, 6.0), authored_organism_mesh, organism_material, 0.035, 0.085, 0.35, 1.2, 28.0, float(index) * 2.11 + 0.8)
		organism.position += frame.up * 2.0
		organism_emitters.append(organism)
		var mote := _make_flow_emitter("AmbientGoldenMotes_%02d" % index, frame, 30, 7.5, Vector3(5.5, 4.8, 7.0), _mote_mesh(), mote_material, 0.55, 1.1, 0.35, 0.95, 42.0, float(index) * 1.91 + 1.4)
		mote.position += frame.up * 1.7
		mote_emitters.append(mote)
	print("M1 organic activity: blood_emitters=%d; organism_emitters=%d; mote_emitters=%d; gpu_particles=true" % [blood_emitters.size(), organism_emitters.size(), mote_emitters.size()])

func _make_flow_emitter(emitter_name: String, frame: Dictionary, count: int, lifetime: float, extents: Vector3, mesh: Mesh, material: Material, scale_min: float, scale_max: float, speed_min: float, speed_max: float, spread_degrees: float, phase: float) -> GPUParticles3D:
	var emitter := GPUParticles3D.new()
	emitter.name = emitter_name
	emitter.amount = count
	emitter.amount_ratio = 0.75
	emitter.lifetime = lifetime
	emitter.preprocess = minf(lifetime * 0.45, 4.0)
	emitter.randomness = 0.22
	emitter.local_coords = true
	emitter.draw_order = GPUParticles3D.DRAW_ORDER_LIFETIME
	emitter.visibility_aabb = AABB(Vector3(-10.0, -10.0, -18.0), Vector3(20.0, 20.0, 36.0))
	emitter.draw_pass_1 = mesh
	emitter.draw_passes = 1
	emitter.material_override = material
	emitter.process_material = _make_particle_material(extents, scale_min, scale_max, speed_min, speed_max, spread_degrees, phase)
	var frame_position: Vector3 = frame.position + frame.up * 0.72
	emitter.position = frame_position
	emitter.basis = Basis(frame.right, frame.up, frame.tangent)
	add_child(emitter)
	emitter_phases[emitter] = phase
	return emitter

func _make_particle_material(extents: Vector3, scale_min: float, scale_max: float, speed_min: float, speed_max: float, spread_degrees: float, phase: float) -> ParticleProcessMaterial:
	var particle_material := ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	particle_material.emission_box_extents = extents
	particle_material.direction = Vector3(0.0, 0.0, -1.0)
	particle_material.spread = spread_degrees
	particle_material.initial_velocity_min = speed_min
	particle_material.initial_velocity_max = speed_max
	particle_material.gravity = Vector3.ZERO
	particle_material.scale_min = scale_min
	particle_material.scale_max = scale_max
	particle_material.angular_velocity_min = -0.45 - phase * 0.03
	particle_material.angular_velocity_max = 0.45 + phase * 0.03
	particle_material.turbulence_enabled = true
	particle_material.turbulence_noise_strength = 0.18
	particle_material.turbulence_noise_scale = 1.4
	return particle_material

func _build_emergence_burst() -> void:
	emergence_burst = GPUParticles3D.new()
	emergence_burst.name = "EmergenceAmbientBurst"
	emergence_burst.amount = 42
	emergence_burst.amount_ratio = 0.035
	emergence_burst.lifetime = 1.8
	emergence_burst.preprocess = 0.2
	emergence_burst.randomness = 0.42
	emergence_burst.local_coords = false
	emergence_burst.visibility_aabb = AABB(Vector3(-8.0, -8.0, -8.0), Vector3(16.0, 16.0, 16.0))
	emergence_burst.draw_pass_1 = authored_organism_mesh
	emergence_burst.draw_passes = 1
	emergence_burst.material_override = organism_material
	var burst_material := ParticleProcessMaterial.new()
	burst_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	burst_material.emission_sphere_radius = 0.6
	burst_material.direction = Vector3(0.0, 0.35, -1.0)
	burst_material.spread = 62.0
	burst_material.initial_velocity_min = 0.18
	burst_material.initial_velocity_max = 1.15
	burst_material.gravity = Vector3(0.0, -0.05, 0.0)
	burst_material.scale_min = 0.028
	burst_material.scale_max = 0.10
	burst_material.angular_velocity_min = -1.2
	burst_material.angular_velocity_max = 1.2
	emergence_burst.process_material = burst_material
	add_child(emergence_burst)

func _curve_frame(distance: float) -> Dictionary:
	var safe_distance := clampf(distance, 0.0, route_length)
	var position := route_curve.sample_baked(safe_distance)
	var look_distance := minf(safe_distance + 0.8, route_length)
	var tangent := (route_curve.sample_baked(look_distance) - position).normalized()
	if tangent.length_squared() < 0.001:
		tangent = Vector3(0.0, 0.0, -1.0)
	var right := tangent.cross(Vector3.UP).normalized()
	if right.length_squared() < 0.001:
		right = Vector3.RIGHT
	var up := right.cross(tangent).normalized()
	return {"position": position, "tangent": tangent, "right": right, "up": up}

func _mote_mesh() -> SphereMesh:
	var sphere := SphereMesh.new()
	sphere.radius = 0.10
	sphere.height = 0.20
	sphere.radial_segments = 8
	sphere.rings = 4
	return sphere

func _fallback_cell_mesh() -> SphereMesh:
	var sphere := SphereMesh.new()
	sphere.radius = 0.32
	sphere.height = 0.64
	sphere.radial_segments = 12
	sphere.rings = 6
	return sphere

func _fallback_organism_mesh() -> SphereMesh:
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	sphere.radial_segments = 10
	sphere.rings = 5
	return sphere
