class_name BiomeLoader
extends RefCounted
## Central biome entry point. Environment systems receive the same immutable definition,
## so palette, fog, lighting, shader pulse, and procedural decoration never drift apart.

const BiomeDefinition = preload("res://scripts/biome_definition.gd")

static func load_biome(biome_id: StringName) -> PhagosBiomeDefinition:
    return BiomeDefinition.create(biome_id)

static func valid_biome_ids() -> PackedStringArray:
    return PackedStringArray(["heart", "lung", "brain", "marrow"])

static func normalize_biome_id(raw_id: String) -> StringName:
    var normalized := raw_id.strip_edges().to_lower().replace(" ", "_")
    if normalized == "bone_marrow":
        normalized = "marrow"
    if valid_biome_ids().find(normalized) == -1:
        return &"heart"
    return StringName(normalized)

static func make_canvas_modulate(biome: PhagosBiomeDefinition) -> CanvasModulate:
    var modulate := CanvasModulate.new()
    modulate.name = "BiomeAmbientTint"
    # Keep white close to neutral; the tint only joins assets that opt into lighting.
    modulate.color = Color(0.92, 0.90, 0.98, 1.0).lerp(biome.membrane.lightened(0.25), 0.08)
    return modulate
