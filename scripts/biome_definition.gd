class_name PhagosBiomeDefinition
extends RefCounted
## Immutable visual contract for an organ biome.
## Color values are intentionally low-saturation in the substrate; only signals are vivid.

var id: StringName
var display_name: String
var backdrop: Color
var floor: Color
var floor_secondary: Color
var tissue_base: Color
var tissue_shadow: Color
var membrane: Color
var vein: Color
var emissive: Color
var particle: Color
var fog: Color
var light_color: Color
var pulse_speed: float
var decoration_density: float
var fog_density: float
var room_jitter: float
var corridor_curvature: float
var ambient_energy: float
var organ_notes: String

static func create(biome_id: StringName) -> PhagosBiomeDefinition:
    var definition := PhagosBiomeDefinition.new()
    definition.id = biome_id

    match biome_id:
        &"heart":
            definition.display_name = "Heart"
            definition.backdrop = Color("#11040d")
            definition.floor = Color("#3b0718")
            definition.floor_secondary = Color("#7a152c")
            definition.tissue_base = Color("#65162c")
            definition.tissue_shadow = Color("#19040e")
            definition.membrane = Color("#c44962")
            definition.vein = Color("#ff315c")
            definition.emissive = Color("#ff6c7c")
            definition.particle = Color("#ff99a5")
            definition.fog = Color(0.30, 0.018, 0.08, 0.15)
            definition.light_color = Color("#ff3e62")
            definition.pulse_speed = 1.18
            definition.decoration_density = 1.18
            definition.fog_density = 0.16
            definition.room_jitter = 0.16
            definition.corridor_curvature = 0.32
            definition.ambient_energy = 0.88
            definition.organ_notes = "Elastic ventricular chambers, thick vascular walls, and rhythmic crimson signalling."
        &"lung":
            definition.display_name = "Lung"
            definition.backdrop = Color("#03151a")
            definition.floor = Color("#073a43")
            definition.floor_secondary = Color("#16717a")
            definition.tissue_base = Color("#236b73")
            definition.tissue_shadow = Color("#021a20")
            definition.membrane = Color("#6dc8cb")
            definition.vein = Color("#36ddea")
            definition.emissive = Color("#8ceff2")
            definition.particle = Color("#d0ffff")
            definition.fog = Color(0.09, 0.65, 0.68, 0.12)
            definition.light_color = Color("#5ee7e5")
            definition.pulse_speed = 0.32
            definition.decoration_density = 1.04
            definition.fog_density = 0.32
            definition.room_jitter = 0.22
            definition.corridor_curvature = 0.48
            definition.ambient_energy = 0.62
            definition.organ_notes = "Branching bronchioles, translucent alveolar membranes, and thin cyan mist."
        &"brain":
            definition.display_name = "Brain"
            definition.backdrop = Color("#0d061f")
            definition.floor = Color("#21103f")
            definition.floor_secondary = Color("#4f2e78")
            definition.tissue_base = Color("#563b83")
            definition.tissue_shadow = Color("#11091f")
            definition.membrane = Color("#a675db")
            definition.vein = Color("#3dc9ff")
            definition.emissive = Color("#7fe4ff")
            definition.particle = Color("#bd9cff")
            definition.fog = Color(0.27, 0.10, 0.55, 0.12)
            definition.light_color = Color("#43cfff")
            definition.pulse_speed = 1.8
            definition.decoration_density = 0.90
            definition.fog_density = 0.11
            definition.room_jitter = 0.25
            definition.corridor_curvature = 0.58
            definition.ambient_energy = 0.95
            definition.organ_notes = "Dendrite pathways, neuron clusters, and fast electric cyan synapse pulses."
        &"marrow", &"bone_marrow":
            definition.id = &"marrow"
            definition.display_name = "Bone Marrow"
            definition.backdrop = Color("#1d101a")
            definition.floor = Color("#6f4658")
            definition.floor_secondary = Color("#bd7f92")
            definition.tissue_base = Color("#d3aa9d")
            definition.tissue_shadow = Color("#3b202c")
            definition.membrane = Color("#ffe0c4")
            definition.vein = Color("#ff99b3")
            definition.emissive = Color("#ffe0a8")
            definition.particle = Color("#fff2dc")
            definition.fog = Color(0.95, 0.57, 0.67, 0.10)
            definition.light_color = Color("#ffd7aa")
            definition.pulse_speed = 0.58
            definition.decoration_density = 1.30
            definition.fog_density = 0.14
            definition.room_jitter = 0.19
            definition.corridor_curvature = 0.38
            definition.ambient_energy = 0.68
            definition.organ_notes = "Ivory cavities, soft pink hematopoietic fields, stem cells, and fat tissue."
        _:
            push_warning("Unknown biome '%s'; falling back to Heart." % biome_id)
            return create(&"heart")

    return definition

func shader_floor_parameters(seed_value: float) -> Dictionary:
    return {
        "floor_color": floor,
        "cell_color": floor_secondary,
        "nucleus_color": tissue_shadow,
        "flow_speed": max(0.04, pulse_speed * 0.09),
        "scale": 7.0 + decoration_density * 2.0,
        "seed": seed_value,
    }
