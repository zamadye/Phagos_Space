class_name PhagosFollowCamera
extends Camera2D
## Arena-only camera. It follows any future player Node2D without representing or drawing
## a player itself, keeps a locked 90° top-down view, and uses frame-rate independent easing.

@export var target_path: NodePath
@export var smoothing_enabled := true
@export_range(1.0, 20.0, 0.25) var smoothing_speed := 8.0

var _target: Node2D

func _ready() -> void:
    enabled = true
    ignore_rotation = true
    rotation = 0.0
    if not target_path.is_empty():
        _target = get_node_or_null(target_path) as Node2D
    make_current()

func set_follow_target(target: Node2D) -> void:
    _target = target
    if _target != null and not smoothing_enabled:
        global_position = _target.global_position

func _process(delta: float) -> void:
    rotation = 0.0
    if _target == null or not is_instance_valid(_target):
        return
    if smoothing_enabled:
        var weight := 1.0 - exp(-smoothing_speed * delta)
        global_position = global_position.lerp(_target.global_position, weight)
    else:
        global_position = _target.global_position
