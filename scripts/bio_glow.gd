class_name BioGlow
extends Node2D
## Shader-backed additive visual glow. The actual 2D light is created separately through
## BioLightFactory so expensive lights can remain capped independently from glow sprites.

const GLOW_SHADER = preload("res://shaders/glow.gdshader")

var glow_color: Color = Color.WHITE
var radius: float = 64.0
var base_energy: float = 1.0
var pulse_speed: float = 1.0
var phase_offset: float = 0.0
var _material: ShaderMaterial

func configure(new_color: Color, new_radius: float, new_energy: float, new_pulse_speed: float, new_phase: float) -> void:
    glow_color = new_color
    radius = new_radius
    base_energy = new_energy
    pulse_speed = new_pulse_speed
    phase_offset = new_phase

func _ready() -> void:
    var quad := Polygon2D.new()
    quad.name = "SoftGlowQuad"
    quad.polygon = PackedVector2Array([
        Vector2(-radius, -radius), Vector2(radius, -radius),
        Vector2(radius, radius), Vector2(-radius, radius),
    ])
    quad.uv = PackedVector2Array([
        Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1),
    ])
    _material = ShaderMaterial.new()
    _material.shader = GLOW_SHADER
    _material.set_shader_parameter("glow_color", glow_color)
    _material.set_shader_parameter("energy", base_energy)
    _material.set_shader_parameter("phase_offset", phase_offset)
    _material.set_shader_parameter("pulse_speed", pulse_speed)
    _material.set_shader_parameter("flicker_amount", 0.06)
    quad.material = _material
    quad.z_index = -1
    add_child(quad)

func _process(_delta: float) -> void:
    if _material == null:
        return
    var organic_pulse := 0.92 + sin(Time.get_ticks_msec() * 0.001 * pulse_speed + phase_offset) * 0.08
    _material.set_shader_parameter("energy", base_energy * organic_pulse)
