class_name PhagosAssetResolver
extends RefCounted
## Final-art bridge for the procedural arena. It is deliberately manifest-led: only files
## declared in assets/manifest/asset_manifest.json are injected, while absent/malformed
## source art cleanly returns null and leaves the procedural renderer active.

const MANIFEST_PATH := "res://assets/manifest/asset_manifest.json"

static var _initialized := false
static var _manifest_entries: Array[Dictionary] = []
static var _entries_by_resource_path: Dictionary = {}
static var _discovered_pngs: Dictionary = {}
static var _texture_cache: Dictionary = {}
static var _status: Dictionary = {}

static func warmup() -> Dictionary:
    if _initialized:
        return get_status()
    _initialized = true
    _load_manifest()
    _scan_png_directory("res://assets")
    _reconcile_manifest()
    return get_status()

static func get_status() -> Dictionary:
    return _status.duplicate(true)

static func floor_overlay(biome_id: StringName, seed_value: int) -> Texture2D:
    return resolve_texture("floor", biome_id, "", seed_value)

static func vein_overlay(biome_id: StringName, seed_value: int) -> Texture2D:
    return resolve_texture("vein", biome_id, "", seed_value)

static func wall_piece(biome_id: StringName, topology: String, seed_value: int) -> Texture2D:
    return resolve_texture("wall", biome_id, "wall_%s" % topology, seed_value)

static func prop_sprite(prop_kind: String, seed_value: int) -> Texture2D:
    var manifest_kind: String = String({
        "protein_vesicle": "protein",
        "moving_vesicle": "protein",
        "protein_pod": "protein",
        "cytokine_crystal": "cytokine_crystal",
        "immune_signal_light": "cytokine_crystal",
        "membrane_sac": "membrane_sac",
        "calcified_chunk": "calcified_chunk",
        "atp_pool": "atp_pool",
    }.get(prop_kind, ""))
    if String(manifest_kind).is_empty():
        return null
    return resolve_texture("prop", &"", String(manifest_kind), seed_value)

static func decal_overlay(keyword: String, seed_value: int) -> Texture2D:
    return resolve_texture("decal", &"", keyword, seed_value)

static func resolve_texture(category: String, biome_id: StringName, keyword: String, seed_value: int) -> Texture2D:
    warmup()
    var candidates: Array[Dictionary] = []
    var normalized_keyword := keyword.to_lower()
    for entry in _manifest_entries:
        if String(entry.get("category", "")) != category:
            continue
        if not bool(entry.get("available", false)):
            continue
        var entry_biome := String(entry.get("biome", ""))
        if biome_id != &"" and not entry_biome.is_empty() and entry_biome != String(biome_id):
            continue
        var asset_path := String(entry.get("path", "")).to_lower()
        if not normalized_keyword.is_empty() and not asset_path.contains(normalized_keyword):
            continue
        candidates.append(entry)
    if candidates.is_empty():
        return null
    var index := posmod(seed_value, candidates.size())
    return _texture_at(String(candidates[index].get("resource_path", "")))

static func has_final_art(category: String, biome_id: StringName = &"") -> bool:
    return resolve_texture(category, biome_id, "", 0) != null

static func _load_manifest() -> void:
    _manifest_entries.clear()
    _entries_by_resource_path.clear()
    if not FileAccess.file_exists(MANIFEST_PATH):
        _status = _blank_status("Manifest file is not present; procedural fallback remains active.")
        return
    var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
    if file == null:
        _status = _blank_status("Manifest could not be opened; procedural fallback remains active.")
        return
    var parser := JSON.new()
    var parse_error := parser.parse(file.get_as_text())
    if parse_error != OK or typeof(parser.data) != TYPE_DICTIONARY:
        _status = _blank_status("Manifest JSON is invalid; procedural fallback remains active.")
        return
    var document: Dictionary = parser.data
    var assets: Array = document.get("assets", [])
    for raw_entry in assets:
        if typeof(raw_entry) != TYPE_DICTIONARY:
            continue
        var entry: Dictionary = raw_entry.duplicate(true)
        var declared_path := String(entry.get("path", ""))
        if declared_path.is_empty() or not declared_path.to_lower().ends_with(".png"):
            continue
        entry["resource_path"] = "res://" + declared_path
        entry["available"] = false
        _manifest_entries.append(entry)

static func _scan_png_directory(directory_path: String) -> void:
    var directory := DirAccess.open(directory_path)
    if directory == null:
        return
    directory.list_dir_begin()
    var item_name := directory.get_next()
    while not item_name.is_empty():
        if not item_name.begins_with("."):
            var item_path := directory_path.path_join(item_name)
            if directory.current_is_dir():
                _scan_png_directory(item_path)
            elif item_name.get_extension().to_lower() == "png":
                _discovered_pngs[item_path] = true
        item_name = directory.get_next()
    directory.list_dir_end()

static func _reconcile_manifest() -> void:
    var available_count := 0
    var missing_paths: PackedStringArray = []
    for index in range(_manifest_entries.size()):
        var entry: Dictionary = _manifest_entries[index]
        var resource_path := String(entry.get("resource_path", ""))
        var available := ResourceLoader.exists(resource_path)
        entry["available"] = available
        _manifest_entries[index] = entry
        _entries_by_resource_path[resource_path] = entry
        if available:
            available_count += 1
        else:
            missing_paths.append(String(entry.get("path", "")))
    _status = {
        "manifest_loaded": not _manifest_entries.is_empty(),
        "declared_assets": _manifest_entries.size(),
        "available_assets": available_count,
        "missing_assets": missing_paths.size(),
        "discovered_pngs": _discovered_pngs.size(),
        "missing_paths": missing_paths,
        "fallback_active": available_count < _manifest_entries.size(),
    }

static func _texture_at(resource_path: String) -> Texture2D:
    if resource_path.is_empty():
        return null
    if _texture_cache.has(resource_path):
        return _texture_cache[resource_path]
    if not ResourceLoader.exists(resource_path):
        _texture_cache[resource_path] = null
        return null
    var texture := ResourceLoader.load(resource_path) as Texture2D
    _texture_cache[resource_path] = texture
    return texture

static func _blank_status(reason: String) -> Dictionary:
    return {
        "manifest_loaded": false,
        "declared_assets": 0,
        "available_assets": 0,
        "missing_assets": 0,
        "discovered_pngs": 0,
        "missing_paths": PackedStringArray(),
        "fallback_active": true,
        "reason": reason,
    }
