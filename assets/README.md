# Original PHAGOS arena assets

`arena/` contains the seven baked maps displayed by the native Godot scene:

| File | Role |
| --- | --- |
| `00_deep_tissue_backdrop.png` | Deep quiet tissue beyond the cutaway |
| `01_outer_skin.png` | Outer skin / dermal band |
| `02_fat.png` | Controlled yellow adipose layer |
| `03_muscle.png` | Directional red muscle fibers |
| `04_fascia.png` | Narrow blue fascia layer |
| `05_inner_membrane.png` | Warm inner membrane seam |
| `06_open_cavity.png` | Clean open arena cavity |

Every map is 2048×1152 and is original. All maps after the backdrop are transparent except for their named anatomical band. `SkinCrossSectionArena` stacks the maps in order with seven `Sprite2D` nodes.

`materials/` contains the small authored strips used by the offline generator to bake the complete maps. They are source material, not runtime overlays. `preview/skin_cross_section_preview.png` is a direct composite of the same runtime maps for art review.
