# Pathogenic reference research → original PHAGOS material plan

## Scope and ethics

The visual target is **not** a reconstruction of *Pathogenic*. No game texture, sprite, mesh, shader, screenshot crop, UI, PCK content, or proprietary implementation is imported or reproduced here. This document records only high-level observations from public material and converts them into an original, simpler Godot study.

The user correction is the controlling direction:

> Read the space as a physical cut through skin: outer skin, fat, muscle, and deeper membrane should be visible as clean, positional layers before the arena cavity begins. The scene must not be covered in incidental effects, circles, or HTML overlays.

## Public findings

1. The official game page describes *Pathogenic* as a 2D top-down game made around a detailed, colorful biological world and says its cells, enemies, and projectiles use soft-body physics. It also describes distinct organ biomes rather than one universal material palette. [Official game information](https://slugdisco.com/pathogenic-game-info/)
2. A developer/community post reports Godot as the engine and names `SoftBody2D`, `SmartShape2D`, `LimboAI`, normal maps, and a `WorldEnvironment` glow workflow. This is useful evidence for the **kind** of native-engine stack involved, but it is not a specification for this project and is not copied. [Public Godot discussion](https://www.reddit.com/r/godot/comments/1lcczic/i_quit_my_job_to_make_a_game_where_you_play_as_a/)
3. Public commentary consistently emphasizes a human-body environment with readable biome identity and tangible, deforming combat bodies. The rendering lesson for a static arena is not “add more VFX”; it is “make the material hierarchy legible first.” [GamingOnLinux overview](https://www.gamingonlinux.com/2026/08/cellular-roguelike-shooter-pathogenic-is-a-body-infecting-good-time/) · [NoobFeed visual discussion](https://www.noobfeed.com/reviews/pathogenic-review)

## UI decision

Public screenshots of the reference game include a combat HUD, minimap, boss bar, and build UI because it is a combat roguelite. The **current art-study scene** deliberately has no HUD or player, so its environmental hierarchy can be reviewed cleanly. The user has since expanded the next phase to UI/UX and then an immune hero. Those additions will be original native Godot `Control` and `CharacterBody2D` work; they will not copy the reference UI.

A Godot Web export is allowed as a browser/WebView delivery target. That is distinct from replacing the game with an HTML/Canvas implementation: the source scene, visual stack, UI, and future hero remain Godot nodes and GDScript.

## Screenshot observations translated into original rules

| Observation from public reference | Original PHAGOS response |
| --- | --- |
| A wall reads as a stack of materials, not one flat painted outline. | Bake six nested roles: skin, fat, muscle, blue fascia, warm inner membrane, and lumen. |
| Colours change by organ and location but stay organized. | Use a deliberate, limited positional grade. Do not randomize colours per prop or particle. |
| Material patterns follow the surface. | Bake directional fiber/lobule strips into transparent full-map layers. Muscle fibers remain in muscle; fascia folds remain in the narrow fascia band. |
| The playable opening is strong and uncluttered. | Use a large clean lumen with no floating decoration field. |
| Motion belongs to living entities and combat feedback. | The environment study starts completely static. Motion may be reconsidered only after a still screenshot is approved. |
| The original is a native Godot title. | The arena is a native Godot scene. There is no custom HTML loading layer, fullscreen web overlay, or screen-space post-process in the presentation. |

## Rendering architecture

```text
SkinCrossSectionArena (Node2D)
├── DeepTissueBackdrop      (Sprite2D + baked backdrop map)
├── OuterSkin               (Sprite2D + transparent baked band map)
├── Fat                     (Sprite2D + transparent baked band map)
├── MuscleFibers            (Sprite2D + transparent baked band map)
├── BlueFascia              (Sprite2D + transparent baked band map)
├── InnerMembrane           (Sprite2D + transparent baked seam map)
├── OpenCavityFloor         (Sprite2D + transparent baked lumen map)
└── Camera2D
```

The authoring script merges the three corridor routes into one anatomical mask, then derives each band by subtraction. A wide mask is baked first and each narrower mask removes its centre. The result is a physically ordered exposed cross-section around one shared open cavity, without procedural noise shaders, visual overlays, or hundreds of scene nodes.

`export_presets.cfg` adds a single-threaded Godot **Web** export for browser/WebView review. It generates the web payload from this same scene; it does not add a parallel HTML game implementation.

## Palette roles

The user explicitly requested a controlled mixture of red, yellow, and blue. This rebuild assigns every hue a physical role:

| Material | Base role | Permitted variation |
| --- | --- | --- |
| Deep tissue / contour | aubergine, dark burgundy | route-local cool or warm shadow |
| Outer skin | russet, muted rose-brown | warmer on the upper route, cooler on lower tissue |
| Fat | ochre, mustard, pale gold | sparse warm coral septa in the baked strip |
| Muscle | crimson, carmine, oxblood | red fiber direction follows each corridor |
| Fascia / membrane | cobalt, teal-blue, violet-blue | a narrow bright inner fold only |
| Lumen | muted plum, charcoal-violet | very low-contrast collagen traces |

Blue is therefore a defined deeper membrane/fascia material, not a random glow. Yellow is fat, not a generic particle colour. Red is muscle and vascular tissue, not a fullscreen tint.

## Explicit exclusions

- No copied Pathogenic game content.
- No HTML loader UI, fullscreen shader, bloom pass, parallax layer, or global colour overlay used to decorate the anatomical world.
- A later real UI may use native Godot `Control` nodes (and, if needed, `CanvasLayer`) for interface composition—not as a visual substitute for the world scene.
- No decorative particle systems, random dots, bubbles, circles, props, or glowing lines.
- No circular rooms, radial hubs, crack-shaped cave tunnels, or sharp V turns.
- No animation until the static cross-section has passed visual review.

## Acceptance checklist for the first rebuild

1. A screenshot instantly reads as a cutaway through skin, fat, muscle, fascia, and an open cavity.
2. Every visible corridor shows at least four distinct wall colours in the same anatomical order.
3. Route A/B/C differ in controlled palette balance, not random effect density.
4. The lumen remains clean enough to read as navigable space without a HUD or player sprite.
5. No unexplained circles, particles, overlays, or screen effects are visible.
6. The scene is readable as a still image before any animation is added.
