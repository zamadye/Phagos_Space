class_name TraversalCell
extends CharacterBody2D
## A small living scout cell. It is a traversal instrument for the current vertical slice,
## not a substitute for the final immune hero.

signal position_changed(world_position: Vector2)

const CELL_RADIUS := 22.0
const CRUISE_SPEED := 360.0
const SPRINT_SPEED := 500.0
const ACCELERATION := 2200.0

var _input_enabled := true
var _life_time := 0.0
var _facing := Vector2.RIGHT
var _last_reported_position := Vector2(100000.0, 100000.0)


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	z_index = 10
	_create_collision_shape()
	queue_redraw()


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO


func _physics_process(delta: float) -> void:
	_life_time += delta
	if not _input_enabled:
		queue_redraw()
		return

	var direction := _movement_direction()
	if not direction.is_zero_approx():
		_facing = direction
	var target_speed := SPRINT_SPEED if Input.is_key_pressed(KEY_SHIFT) else CRUISE_SPEED
	velocity = velocity.move_toward(direction * target_speed, ACCELERATION * delta)
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
	var body := PackedVector2Array()
	for index in range(14):
		var angle := TAU * float(index) / 14.0
		var pulse := sin(_life_time * 3.0 + angle * 4.0) * 1.7
		var contour := CELL_RADIUS + pulse
		body.append(Vector2(cos(angle) * contour, sin(angle) * contour))
	draw_colored_polygon(body, Color(0.54, 0.94, 0.76, 0.96))
	draw_polyline(body, Color(0.88, 1.0, 0.78, 0.9), 2.0, true)
	draw_circle(Vector2(-4.0, -3.0), 8.0, Color(0.08, 0.22, 0.27, 0.9))
	draw_circle(Vector2(-6.0, -5.0), 3.0, Color(0.91, 1.0, 0.87, 0.95))

	var tail_normal := Vector2(-_facing.y, _facing.x)
	var tail_start := -_facing * CELL_RADIUS * 0.7
	var tail_mid := tail_start - _facing * 22.0 + tail_normal * sin(_life_time * 5.0) * 7.0
	var tail_end := tail_start - _facing * 42.0 - tail_normal * sin(_life_time * 5.0) * 6.0
	draw_polyline(
		PackedVector2Array([tail_start, tail_mid, tail_end]),
		Color(0.37, 0.86, 0.77, 0.85),
		3.0,
		true
	)
