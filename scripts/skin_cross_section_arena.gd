class_name SkinCrossSectionArena
extends Node2D
## Native Godot presentation of one static skin cutaway. Every visible wall band is an
## original baked layer map; no procedural floor clutter, post-process, CanvasLayer, or
## ambient overlay is created at runtime.

const DEEP_TISSUE = preload("res://assets/arena/00_deep_tissue_backdrop.png")
const OUTER_SKIN = preload("res://assets/arena/01_outer_skin.png")
const FAT = preload("res://assets/arena/02_fat.png")
const MUSCLE = preload("res://assets/arena/03_muscle.png")
const FASCIA = preload("res://assets/arena/04_fascia.png")
const INNER_MEMBRANE = preload("res://assets/arena/05_inner_membrane.png")
const OPEN_CAVITY = preload("res://assets/arena/06_open_cavity.png")

var _built := false


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.125, 0.082, 0.173, 1.0))
	_build_baked_cross_section()


func _build_baked_cross_section() -> void:
	if _built:
		return
	_add_baked_layer("DeepTissueBackdrop", DEEP_TISSUE, 0)
	_add_baked_layer("OuterSkin", OUTER_SKIN, 1)
	_add_baked_layer("Fat", FAT, 2)
	_add_baked_layer("MuscleFibers", MUSCLE, 3)
	_add_baked_layer("BlueFascia", FASCIA, 4)
	_add_baked_layer("InnerMembrane", INNER_MEMBRANE, 5)
	_add_baked_layer("OpenCavityFloor", OPEN_CAVITY, 6)
	_built = true


func _add_baked_layer(layer_name: String, texture: Texture2D, layer_z: int) -> void:
	var sprite := Sprite2D.new()
	sprite.name = layer_name
	sprite.texture = texture
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.z_index = layer_z
	add_child(sprite)


func get_material_report() -> Dictionary:
	return {
		"native_godot_only": true,
		"baked_layers":
		[
			"outer_skin",
			"fat",
			"muscle_fibers",
			"blue_fascia",
			"inner_membrane",
			"open_cavity_floor",
		],
		"runtime_particles": 0,
		"runtime_overlays": 0,
		"environment_animation": false,
		"html_presentation": false,
	}


func get_arena_bounds() -> Rect2:
	return Rect2(-1024.0, -576.0, 2048.0, 1152.0)
