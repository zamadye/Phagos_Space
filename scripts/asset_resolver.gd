class_name PhagosAssetResolver
extends RefCounted
## Optional final-art bridge. The procedural kit remains fully functional with an empty
## assets directory, while correctly named PNG imports are picked up automatically.

static var _texture_cache: Dictionary = {}

static func floor_overlay(biome_id: StringName, seed_value: int) -> Texture2D:
    var preferred := _variant_index(seed_value, 4)
    for offset in range(4):
        var index := ((preferred - 1 + offset) % 4) + 1
        var path := "res://assets/floor/biome_%s_floor_%02d.png" % [biome_id, index]
        var texture := _texture_at(path)
        if texture != null:
            return texture
    return null

static func prop_sprite(prop_kind: String, seed_value: int) -> Texture2D:
    var manifest_kind := {
        "protein_vesicle": "protein",
        "moving_vesicle": "protein",
        "cytokine_crystal": "cytokine_crystal",
        "immune_signal_light": "cytokine_crystal",
        "membrane_sac": "membrane_sac",
        "calcified_chunk": "calcified_chunk",
        "protein_pod": "protein",
        "atp_pool": "atp_pool",
    }.get(prop_kind, "")
    if manifest_kind.is_empty():
        return null
    var preferred := _variant_index(seed_value, 3)
    for offset in range(3):
        var index := ((preferred - 1 + offset) % 3) + 1
        var path := "res://assets/props/prop_%s_%02d.png" % [manifest_kind, index]
        var texture := _texture_at(path)
        if texture != null:
            return texture
    return null

static func _variant_index(seed_value: int, count: int) -> int:
    return posmod(seed_value, count) + 1

static func _texture_at(path: String) -> Texture2D:
    if _texture_cache.has(path):
        return _texture_cache[path]
    if not ResourceLoader.exists(path):
        _texture_cache[path] = null
        return null
    var texture := ResourceLoader.load(path) as Texture2D
    _texture_cache[path] = texture
    return texture
