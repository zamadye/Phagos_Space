class_name TraversalCell
extends CharacterBody2D
## A small native-Godot traversal proxy used to prove exploration, collision, and
## moving-route safety before the final immune hero is introduced.

signal position_changed(world_position: Vector2)

const CELL_RADIUS := 24.0
const CRUISE_SPEED := 430.0
const SPRINT_SPEED := 570.0
const ACCELERATION := 2600.0

var _input_enabled := true
var _pulse_time := 0.0
var _last_reported_position := Vector2.INF


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	z_index = 20
	_create_collision_shape()
	queue_redraw()


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO


func _physics_process(delta: float) -> void:
	_pulse_time += delta
	if not _input_enabled:
		queue_redraw()
		return

	var desired_direction := _movement_direction()
	var desired_speed := SPRINT_SPEED if Input.is_key_pressed(KEY_SHIFT) else CRUISE_SPEED
	var desired_velocity := desired_direction * desired_speed
	velocity = velocity.move_toward(desired_velocity, ACCELERATION * delta)
	move_and_slide()

	if global_position.distance_squared_to(_last_reported_position) > 1.0:
		_last_reported_position = global_position
		position_changed.emit(global_position)
	queue_redraw()


func _movement_direction() -> Vector2:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	return direction.normalized()


func _create_collision_shape() -> void:
	var collider := CollisionShape2D.new()
	collider.name = "TraversalCollision"
	var shape := CircleShape2D.new()
	shape.radius = CELL_RADIUS
	collider.shape = shape
	add_child(collider)


func _draw() -> void:
	var breathing := sin(_pulse_time * 3.0) * 1.5
	draw_circle(Vector2.ZERO, CELL_RADIUS + 8.0 + breathing, Color(0.12, 0.78, 0.84, 0.15))
	draw_circle(Vector2.ZERO, CELL_RADIUS + breathing, Color(0.19, 0.92, 0.83, 0.96))
	draw_circle(Vector2(-5.0, -6.0), CELL_RADIUS * 0.48, Color(0.83, 1.0, 0.92, 0.9))
	draw_circle(Vector2(7.0, 8.0), CELL_RADIUS * 0.34, Color(0.08, 0.24, 0.31, 0.85))
	draw_arc(
		Vector2.ZERO, CELL_RADIUS + 5.0, 0.25, 2.4, 20, Color(0.95, 1.0, 0.82, 0.95), 2.5, true
	)
