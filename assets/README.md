# Original PHAGOS anatomy studies

`arena/` contains the original seven baked maps from the accepted **skin-cutaway visual prototype**:

| File | Prototype material role |
| --- | --- |
| `00_deep_tissue_backdrop.png` | Deep quiet tissue beyond the cutaway |
| `01_outer_skin.png` | Outer skin / dermal band |
| `02_fat.png` | Controlled yellow adipose layer |
| `03_muscle.png` | Directional red muscle fibers |
| `04_fascia.png` | Narrow blue fascia layer |
| `05_inner_membrane.png` | Warm inner membrane seam |
| `06_open_cavity.png` | Clean open arena cavity |

Every map is 2048×1152 and original. The maps remain a material-language reference for PHAGOS, but they are no longer presented as the whole game or stacked as the runtime scene. The playable Dermal Rift now renders and collides with dynamic Godot geometry driven by `data/organ_biomes/dermal_rift.json`.

`materials/` contains the small authored strips used by the offline generator to bake these studies. `preview/skin_cross_section_preview.png` is a reference composite for art review, not a playable world screenshot.
