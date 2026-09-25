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

func _init() -> void:
    call_deferred("_capture_all")

func _capture_all() -> void:
    var absolute_output := ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
    DirAccess.make_dir_recursive_absolute(absolute_output)
    root.size = TARGET_SIZE
    var failures: PackedStringArray = []

    for capture in CAPTURES:
        var error := change_scene_to_file(capture["scene"])
        if error != OK:
            failures.append("%s: scene change failed (%s)" % [capture["id"], error_string(error)])
            continue
        # Let deferred arena generation, shader warmup, particles, and two render frames settle.
        await process_frame
        await process_frame
        await create_timer(0.75).timeout
        await RenderingServer.frame_post_draw

        var image := root.get_texture().get_image()
        if image == null or image.is_empty():
            failures.append("%s: viewport image was empty" % capture["id"])
            continue
        if image.get_size() != TARGET_SIZE:
            image.resize(TARGET_SIZE.x, TARGET_SIZE.y, Image.INTERPOLATE_LANCZOS)
        var output_path := absolute_output.path_join("%s.png" % capture["id"])
        var save_error := image.save_png(output_path)
        if save_error != OK:
            failures.append("%s: could not write PNG (%s)" % [capture["id"], error_string(save_error)])
        else:
            print("Captured visual QA: %s" % output_path)

    if not failures.is_empty():
        for failure in failures:
            push_error(failure)
        quit(1)
        return
    quit(0)
