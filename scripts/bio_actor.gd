class_name BioActor
extends Node3D

## Lightweight deterministic motion used by every visible biological actor.
## M1 uses procedural meshes; M2 attaches intact GLB scenes as visual children.
## Motion, skills, and response live in this wrapper and never edit the GLB source.

var base_position: Vector3
var base_scale: Vector3 = Vector3.ONE
var phase: float = 0.0
var bob_speed: float = 1.0
var bob_height: float = 0.15
var pulse_amount: float = 0.05
var spin_speed: float = 0.25
var drift_axis: Vector3 = Vector3.UP
var elapsed: float = 0.0

func configure(start_position: Vector3, actor_scale: Vector3, seed_value: float, speed: float, height: float, spin: float) -> void:
	base_position = start_position
	base_scale = actor_scale
	phase = seed_value
	bob_speed = speed
	bob_height = height
	spin_speed = spin
	position = base_position
	scale = base_scale

func _process(delta: float) -> void:
	elapsed += delta
	var wave := sin(elapsed * bob_speed + phase)
	var pulse := 1.0 + sin(elapsed * bob_speed * 1.37 + phase * 0.7) * pulse_amount
	position = base_position + drift_axis * wave * bob_height
	scale = base_scale * pulse
	rotate_y(delta * spin_speed)
