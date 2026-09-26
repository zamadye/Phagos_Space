extends SceneTree
## Headless visual QA capture invoked by CI:
## godot --headless --path . --rendering-driver opengl3 --script res://tools/capture_screenshots.gd

const CAPTURES := [
    {"id": "heart", "scene": "res://scenes/biome_heart.tscn"},
    {"id": "lung", "scene": "res://scenes/biome_lung.tscn"},
    {"id": "brain", "scene": "res://scenes/biome_brain.tscn"},
    {"id": "marrow", "scene": "res://scenes/biome_marrow.tscn"},
]
const OUTPUT_DIRECTORY := "res://reports/screenshots"
const TARGET_SIZE := Vector2i(1920, 1080)
const AssetResolverScript = preload("res://scripts/asset_resolver.gd")
const REQUIRED_SOURCE_ART: PackedStringArray = [
    "res://assets/floor/biome_heart_floor_01.png",
    "res://assets/floor/biome_lung_floor_01.png",
    "res://assets/floor/biome_brain_floor_01.png",
    "res://assets/floor/biome_marrow_floor_01.png",
    "res://assets/biome/biome_heart_vein_crimson_01.png",
    "res://assets/biome/biome_lung_vein_cyan_01.png",
    "res://assets/biome/biome_brain_vein_cyan_01.png",
    "res://assets/biome/biome_marrow_vein_crimson_01.png",
    "res://assets/walls/biome_heart_wall_straight_A.png",
    "res://assets/walls/biome_lung_wall_straight_A.png",
    "res://assets/walls/biome_brain_wall_straight_A.png",
    "res://assets/walls/biome_marrow_wall_straight_A.png",
    "res://assets/props/prop_membrane_sac_01.png",
    "res://assets/props/prop_protein_01.png",
    "res://assets/props/prop_cytokine_crystal_01.png",
    "res://assets/props/prop_calcified_chunk_01.png",
]

func _init() -> void:
    call_deferred("_capture_all")

func _capture_all() -> void:
    var absolute_output := ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
    DirAccess.make_dir_recursive_absolute(absolute_output)
    root.size = TARGET_SIZE
    var failures: PackedStringArray = []
    _verify_required_source_art(failures)
    if not failures.is_empty():
        _finish_with_failures(failures)
        return

    for capture in CAPTURES:
        var capture_data: Dictionary = capture
        var capture_id: String = String(capture_data["id"])
        var scene_path: String = String(capture_data["scene"])
        var error: Error = change_scene_to_file(scene_path)
        if error != OK:
            failures.append("%s: scene change failed (%s)" % [capture_id, error_string(error)])
            continue
        # Let deferred arena generation, shader warmup, particles, and two render frames settle.
        await process_frame
        await process_frame
        await create_timer(0.75).timeout
        await RenderingServer.frame_post_draw

        var image: Image = root.get_texture().get_image() as Image
        if image == null or image.is_empty():
            failures.append("%s: viewport image was empty" % capture_id)
            continue
        if image.get_size() != TARGET_SIZE:
            image.resize(TARGET_SIZE.x, TARGET_SIZE.y, Image.INTERPOLATE_LANCZOS)
        var output_path := absolute_output.path_join("%s.png" % capture_id)
        var save_error: Error = image.save_png(output_path)
        if save_error != OK:
            failures.append("%s: could not write PNG (%s)" % [capture_id, error_string(save_error)])
        else:
            print("Captured visual QA: %s" % output_path)

    if not failures.is_empty():
        _finish_with_failures(failures)
        return
    quit(0)

func _verify_required_source_art(failures: PackedStringArray) -> void:
    var status: Dictionary = AssetResolverScript.warmup()
    var available_assets: int = int(status.get("available_assets", 0))
    print("Source-art QA: resolver reports %d available manifest assets." % available_assets)
    for resource_path in REQUIRED_SOURCE_ART:
        if not ResourceLoader.exists(resource_path):
            failures.append("Source-art QA: exported resource is missing: %s" % resource_path)
            continue
        var texture: Texture2D = ResourceLoader.load(resource_path) as Texture2D
        if texture == null:
            failures.append("Source-art QA: resource did not load as Texture2D: %s" % resource_path)
            continue
        if texture.get_size() != Vector2(2048.0, 2048.0):
            failures.append("Source-art QA: unexpected dimensions for %s: %s" % [resource_path, texture.get_size()])
    if available_assets < REQUIRED_SOURCE_ART.size():
        failures.append("Source-art QA: resolver found only %d/%d required assets." % [available_assets, REQUIRED_SOURCE_ART.size()])

func _finish_with_failures(failures: PackedStringArray) -> void:
    for failure in failures:
        push_error(failure)
    quit(1)
