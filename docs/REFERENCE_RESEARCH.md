# Pathogenic reference boundary → original PHAGOS exploration direction

## Scope and ethics

PHAGOS is **not** a reconstruction of *Pathogenic*. No game texture, sprite, mesh, shader, screenshot crop, UI, PCK content, source code, room layout, enemy, upgrade, or proprietary implementation is imported or reproduced here.

The public reference is useful only at a high level: a microscopic biological world can be colorful, readable, biome-specific, and active without becoming medically photorealistic. PHAGOS turns that observation into its own anatomy, traversal rules, landmark names, material system, objectives, and Godot implementation.

The user's controlling direction remains:

> Read the space as a physical cut through coherent anatomy—surface skin, fat, muscle/fibrous depth, then cavity—while making that space an actual exploration adventure whose routes change with organ behavior.

## Confirmed public observations

1. The official game information describes *Pathogenic* as a 2D top-down biological world with distinct organ biomes and soft-body-driven cells, enemies, and projectiles. It does **not** disclose proprietary rendering or map-generation implementation. [Official game information](https://slugdisco.com/pathogenic-game-info/)
2. Its Steam page publicly frames the game around infecting a host, collecting organelles, and exploring a procedurally generated microscopic world. This supports the high-level idea that exploration can be central in a cellular setting; it supplies no PHAGOS content. [Steam page](https://store.steampowered.com/app/3808690/Pathogenic/)
3. A public developer/community post reports Godot and mentions tools such as `SoftBody2D`, `SmartShape2D`, normal maps, and glow. It is secondary context, not a specification and not implementation access. [Public Godot discussion](https://www.reddit.com/r/godot/comments/1lcczic/i_quit_my_job_to_make-a-game-where-you-play-as-a/)
4. Independent public coverage discusses readable organ identity and tangible biological action. The safe design lesson is **material hierarchy and active topology**, not copying art or adding arbitrary VFX. [GamingOnLinux](https://www.gamingonlinux.com/2026/08/cellular-roguelike-shooter-pathogenic-is-a-body-infecting-good-time/) · [NoobFeed](https://www.noobfeed.com/reviews/pathogenic-review)

## PHAGOS design translation

| High-level observation | Original PHAGOS decision |
| --- | --- |
| Organ regions must be recognizable. | Each PHAGOS biome owns material roles, landmarks, topology, and behavior. Dermal Rift uses Surface Breach, Dermal Gallery, Adipose Saddle, Myofiber Fork, Fascia Valve, Lymph Pocket, Deep Cavity, and Organ Gate. |
| Biological environments should be active. | Dermal Rift changes between resting, contraction, vascular surge, inflammation, and recovery. These states alter actual route availability, anchor positions, width envelopes, and collision—not decorative screen motion. |
| Exploration needs legibility. | The player discovers landmarks, reads route-state warnings, chooses branches, reaches the Deep Cavity, performs an interaction, then exits through a gated organ transition. |
| Navigation must be safe during deformation. | State shifts preview before collision commit, occur only while the explorer is in a safe connected chamber, never narrow an authored path under 260 px, and retain a route to entry. |
| The environment must have anatomy, not generic caves. | Route bands render from outer tissue through fat, muscle, fascia, membrane, and clean cavity. Red/yellow/blue have physical tissue roles rather than being effect colors. |

## Engine boundary

The playable world is native Godot:

```text
DermalRiftExpedition (Node2D)
├── DermalRiftWorld          dynamic anatomy renderer from authored JSON
├── DynamicCavityCollision   rebuilt StaticBody2D cavity boundaries
├── TraversalCell            CharacterBody2D exploration controller
│   └── ExplorationCamera    Camera2D
└── ExpeditionHUD            native Godot CanvasLayer / Control UI
```

The WebView is a direct Godot Web export served over HTTP. There is no React shell, iframe, custom HTML game, or browser-side duplicate renderer.

## Visual rules

- **Outer skin / dermis:** muted rose and russet; entry orientation.
- **Fat / subcutaneous tissue:** ochre, mustard, and pale gold; compressed at the Adipose Saddle.
- **Muscle:** crimson and oxblood directional fibers; visibly contracts at the Myofiber Fork.
- **Fascia / membrane:** cobalt, teal-blue, and violet-blue; readable state gate rather than glow.
- **Cavity:** plum / charcoal-violet navigable lumen; kept clear enough to read player movement and interaction.

Motion must communicate organ function: contraction shifts a lower passage, vascular surge opens an upper route, inflammation redirects through lymph, and recovery visibly restores choices. It must not be random wobble, camera shake, incidental particle noise, or an overlay hiding the arena.

## Explicit exclusions

- No copied Pathogenic content or inferred proprietary implementation claims.
- No HTML/Canvas layer that redraws the Godot world.
- No generic static anatomical poster presented as the game.
- No random particles, noise circles, debris fields, or arbitrary glow used to simulate activity.
- No final immune hero/combat claim before the traversal/runtime safety gates are complete.

## Acceptance criteria for the live slice

1. The player can move, collide with tissue walls, explore, discover landmarks, interact with the Deep Cavity, and exit through the Organ Gate.
2. A state change visibly affects routes and collision geometry, but never seals the active explorer.
3. The same authored data drives validator, map, rendered anatomy, collision, and route state.
4. A still frame identifies its tissue hierarchy; in motion, a player can understand why the map changed.
5. The same scene works in native Godot and its direct Godot Web export.
