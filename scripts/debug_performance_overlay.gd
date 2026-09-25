class_name PhagosDebugPerformanceOverlay
extends CanvasLayer
## Debug-only browser/native performance HUD. It is created by ArenaController only for
## debug builds and remains hidden until F3, so no gameplay UI is shipped in release.

var arena: Node
var _container: Control
var _label: Label
var _enabled := false

func configure(controller: Node) -> void:
    arena = controller

func _ready() -> void:
    if not OS.is_debug_build():
        queue_free()
        return
    layer = 100
    _build_controls()
    _set_enabled(false)

func _build_controls() -> void:
    _container = Control.new()
    _container.name = "PerformanceOverlay"
    _container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_container)

    var panel := ColorRect.new()
    panel.color = Color(0.025, 0.008, 0.05, 0.86)
    panel.position = Vector2(20, 20)
    panel.size = Vector2(355, 166)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _container.add_child(panel)

    var accent := ColorRect.new()
    accent.color = Color(0.31, 0.88, 1.0, 0.82)
    accent.position = Vector2(20, 20)
    accent.size = Vector2(3, 166)
    accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _container.add_child(accent)

    _label = Label.new()
    _label.position = Vector2(38, 34)
    _label.size = Vector2(320, 136)
    _label.add_theme_font_size_override("font_size", 13)
    _label.add_theme_color_override("font_color", Color(0.86, 0.94, 1.0, 1.0))
    _label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _container.add_child(_label)

func _unhandled_input(event: InputEvent) -> void:
    if not OS.is_debug_build():
        return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
        _set_enabled(not _enabled)
        get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
    if not _enabled or _label == null:
        return
    var snapshot: Dictionary = {}
    if arena != null and is_instance_valid(arena) and arena.has_method("get_performance_snapshot"):
        snapshot = arena.call("get_performance_snapshot")
    var draw_calls := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
    var fps := Engine.get_frames_per_second()
    var format_string := "PHAGOS WEB DEBUG  [F3]\n\nFPS              %3d\nDraw calls       %3d\nActive lights    %3d\n"
    format_string += "Active particles %3d  (%s)\nRoom             %s\nAsset fallback   %s"
    _label.text = format_string % [
        fps,
        draw_calls,
        int(snapshot.get("active_lights", 0)),
        int(snapshot.get("active_particles", 0)),
        String(snapshot.get("particle_backend", "cpu")).to_upper(),
        String(snapshot.get("room_id", "CONNECTIVE_TISSUE")),
        "ON" if bool(snapshot.get("asset_fallback", true)) else "OFF",
    ]

func _set_enabled(next_enabled: bool) -> void:
    _enabled = next_enabled
    if _container != null:
        _container.visible = _enabled
