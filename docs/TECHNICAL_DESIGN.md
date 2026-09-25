# Phagos Organic Arena Kit — technical design

## 1. Intent and non-goals

This package is an environment foundation for a top-down microscopic shooter. It owns arena topology, organic geometry, visual biome treatment, environmental props, particle ambience, and camera integration points.

It does **not** spawn or render a player, virus, enemy, weapon, projectile, combat effect, reward, UI, or room-clear logic. The room type labels are semantic environment metadata only, so encounter designers can attach their own systems later.

## 2. Coordinate contract

- Godot 2D units are treated as **pixels at the 1920×1080 design viewport**.
- Camera view is 90° top-down with `rotation = 0` and `ignore_rotation = true`.
- `project.godot` uses `canvas_items` stretch and `expand` aspect behavior. Do not use hard-coded screen-space positions for environment content.
- `world_scale` (0.75–1.35) applies to all room and corridor values at generation time; props and shaders are placed from resulting geometry.
- Small navigation corridors are 96–160 px; normal corridors are 192 px nominal; chambers are 384–640 px; the boss chamber is 1110×970 px; decor is authored for 16–64 px gameplay reading.

## 3. Generation data flow

```text
BiomeLoader
    │ produces immutable PhagosBiomeDefinition
    ▼
RoomGenerator.generate(seed, biome, world_scale)
    │ rooms + semantic edges + multi-entrance metadata
    ├───────────────► OrganicRoom (radial chamber contour + floor shaders)
    ▼
CorridorBuilder.build(edge, from_room, to_room, biome)
    │ cubic Bezier samples + variable widths + anatomy side branch
    ├───────────────► OrganicCorridor (spline extrusion and wall stack)
    └───────────────► PropSpawner (wall-adjacent placement anchors)
                              │
                              ▼
                       BreakableProp / decoration categories
```

`PhagosArenaController` is the only assembly class. It sets the clear color, `CanvasModulate`, parallax, organ accents, geometry, props, particles, light budget, and camera bounds.

### Graph output schema

`RoomGenerator.generate()` returns this shape:

```gdscript
{
    "seed": 8142026,
    "bounds": Rect2(...),
    "rooms": [
        {
            "id": "combat_a",
            "type": "combat",
            "position": Vector2(...),
            "size": Vector2(560, 480),
            "seed": 123,
            "entrances": [
                {"edge_id": "spawn_to_combat_a", "angle": 0.2, "width": 192.0, "outbound": false}
            ]
        }
    ],
    "edges": [
        {
            "id": "spawn_to_combat_a", "from": "spawn", "to": "combat_a",
            "width": 192.0, "seed": 456, "curve_bias": 0.18,
            "widening": -0.08,
            "geometry": {"points": PackedVector2Array(), "widths": PackedFloat32Array(), "branches": []}
        }
    ]
}
```

`geometry` is attached after `CorridorBuilder` runs. Keep that separation: the exact same graph can later feed navigation polygons, minimap reveal, ambient audio zones, or a combat encounter director without querying renderer nodes.

## 4. Organic rooms and corridor construction

### Rooms

`OrganicRoom` turns a room size into a deterministic 26-point contour (34 points for Boss). Each radius receives a seeded macro wave and jitter. There are no rectangle primitives in room construction. It draws:

1. **Base tissue:** dark outer mass plus lighter wall mass.
2. **Membrane folds:** contours, localized ridges, and moving `membrane_distort.gdshader` overlay.
3. **Micro-cracks:** low-contrast branching cracks, kept away from high-importance signals.
4. **Veins:** `Line2D` overlays with `vein_pulse.gdshader` and unique phase seeds.
5. **Emissive highlights:** additive `BioGlow` plus limited `PointLight2D` sources.

The floor is a `Polygon2D` filled by `cytoplasm_flow.gdshader`; each polygon has generated UVs plus deterministic UV offset and rotation, then receives an individual flow seed. This prevents a visibly repeated flat tile without relying on a square tile map.

### Corridors

`CorridorBuilder` obtains a ray/ellipse boundary point from both connected rooms, then samples a cubic Bezier with asymmetric control handles. A guaranteed minimum bend prevents ruler-straight halls. For each sample it records a width with both port damping and body variation. `OrganicCorridor` extrudes ribbons from that centerline:

```text
outer shadow shell (width + 100)
  └─ base tissue shell (width + 56)
       └─ cytoplasm floor (width)
          + membrane edge rails / folds / cracks
          + separate pulsing vessel children
          + optional branch cap / small signal light
```

An edge flagged `branch` receives one capped anatomical side branch. It is visual anatomy, not a route/encounter edge; host gameplay can ignore it safely.

## 5. Biome system

`PhagosBiomeDefinition` is a compact immutable palette/behavior object. Every system receives the same instance, so shader color, particle hue, fog, glow, decor density, contour variation, and pulse speed cannot accidentally conflict.

| Field | Used by |
|---|---|
| `floor`, `floor_secondary`, `tissue_base`, `tissue_shadow`, `membrane` | room/corridor tissue layers and props |
| `vein`, `emissive`, `particle`, `light_color` | shader uniforms, particles, glows, PointLight2D |
| `pulse_speed`, `ambient_energy` | vein travel, glow/light motion, room breathing |
| `fog_density`, `decoration_density` | particle / prop density tuning |
| `room_jitter`, `corridor_curvature` | geometry language |

`BiomeAccentField` adds anatomy that palette alone cannot convey:

- Heart: wide elastic vessel channels and ventricular arc accents.
- Lung: low-contrast alveoli clusters and translucent septa.
- Brain: dendrite/soma fields with cyan synapse points.
- Marrow: rounded trabecular/fat cavities with soft cellular residue.

## 6. Shader package

| File | Purpose | Runtime assignment |
|---|---|---|
| `vein_pulse.gdshader` | travelling sine-wave brightness with unique phase per vessel | `Line2D` veins, imported vein overlay sprites |
| `membrane_distort.gdshader` | slow procedural UV/noise distortion and translucent ridge bands | room membrane overlay / imported membrane pass |
| `cytoplasm_flow.gdshader` | scrolling FBM cytoplasm, cellular gradient, non-repeating noise | room `Polygon2D` floor |
| `glow.gdshader` | additive radial HDR-friendly soft glow | `BioGlow` quad; compatible with a host bloom pass |
| `organic_wall.gdshader` | optional subtle imported wall UV motion | final atlas wall sprite pass |

### Material rule

Never share one mutable `ShaderMaterial` between all vessels or rooms: phase and seed would synchronize the whole organ. Runtime code creates per-instance materials. `.tres` material files are neutral art-import presets only.

## 7. Lighting and glow

`BioLightFactory` creates one 128 px radial `ImageTexture` and reuses it for every additive `PointLight2D`. This avoids per-light texture allocation. `PhagosArenaController.point_light_budget` defaults to 20 and is consumed in semantic order:

1. Boss chamber (up to 4)
2. Elite chambers (up to 2 each)
3. Combat/spawn/shop/upgrade rooms (1 each)
4. Every third corridor (1)

Glows can exceed lights because a `BioGlow` is a cheap shader quad. Emitters are used for visible immune crystals, cytokine-like nodes, energy pools, and selected vessel points; not for every decoration.

The project uses GL Compatibility by default for broad desktop preview support. `glow.gdshader` can output intensity above standard albedo, so a host project using Forward+ and a compositor/bloom pipeline can add post-process bloom without replacing source art.

## 8. Decorations, particles, and breakable props

### Decoration categories

| Category | Implemented samples | Cost strategy |
|---|---|---|
| Static | collagen fiber, membrane ridge, tissue chunk | no `_process`, one draw per prop |
| Semi-animated | protein vesicle, plasma bubble, cytokine crystal | low-amplitude bob only |
| Animated | moving vesicle, oxygen particle, immune signal light | limited prop count plus batched ambient particles |

`PropSpawner` uses room-local polar placement to keep a readable center/movement lane. It adds sparse wall-adjacent props from true spline geometry after `CorridorBuilder` runs.

### Ambient particles

`BiologicalParticleField` is one custom `CanvasItem`, not a node tree of particles. It runs deterministic drift, turbulence, randomized lifetime, respawn from world edges, and additive drawing. Its types include cytokines, ATP sparks, plasma mist/bubbles, and immune dust. Use `atmospheric_particle_budget` rather than making ad-hoc particle nodes.

### Breakable props

`BreakableProp` is intentionally only environmental:

```gdscript
for prop in get_tree().get_nodes_in_group("phagos_breakable_props"):
    prop.break_open() # host combat may call this; no combat dependency exists here
```

`break_open()` seeds 7–13 debris fragments, starts a short drag/fade simulation, fades an optional glow, and frees the prop after 1.35 seconds. It creates no loot, damage, score, or interaction UI.

## 9. Parallax

`BiologicalParallaxLayer` supplies three world-space layers and follows camera movement by a fraction:

| Node | Factor | Content |
|---|---:|---|
| `BackgroundTissue` | 0.055 | broad blurred-looking tissue masses and membrane folds |
| `MidVeins` | 0.125 | dim additive vessel network |
| `ForegroundCells` | 0.22 | slow drifting translucent cells |

The layer position is `camera_position * (1 - factor)`, so a normal world movement of one unit becomes only `factor` visual movement. Do not use screen-space `Control` nodes for these layers.

## 10. Camera integration

`PhagosFollowCamera` follows any `Node2D`; no player node is part of this repository.

```gdscript
arena.set_player_target(player_cell)
# later, for a static art preview:
arena.reset_camera_to_spawn()
```

The script locks rotation every frame, has optional exponential smoothing, makes itself current, and gets graph bounds from `PhagosArenaController`. A host that wants a dead-zone camera can replace only `follow_camera.gd`; all environment positions are world-space.

## 11. Final-art replacement path

Procedural art is both a working fallback and a layout/lighting reference. To bring in generated painterly art:

1. Export files named in `assets/manifest/asset_manifest.json`.
2. Run strict validation and complete the human sign-off report.
3. Build padded atlas pages using `tools/atlas_assets.py`; atlas files are intentionally ignored by Git.
4. Add an art adapter that maps a manifest entry to a `Sprite2D`/`Polygon2D` overlay in `OrganicRoom`, `OrganicCorridor`, or `BreakableProp`. Preserve the existing spline centerline and contour geometry.
5. Use per-biome material instances and randomized `phase_offset`, UV offset, and optional 90° rotation for decals/floor overlays.

A final art adapter must not replace room geometry with a repeat tile grid or a rectangular dungeon layout.

## 12. Quality and performance release checklist

### Visual

- No room silhouette resolves as a square or conventional RPG tile.
- Each biome is identifiable at a glance from palette **and** anatomy.
- Corridors have smooth curved centerlines, organic width variation, and sealed/capped side branches.
- Core signals have high saturation; substrate remains readable and lower saturation.
- Wall stack visibly includes tissue mass, fold, crack, vessel, and glow depth.
- Parallax is detectable but small enough not to affect aiming readability.

### Technical

- Run scenes in debug with Godot’s frame-time monitor at the intended 1920×1080 target.
- Keep `point_light_budget <= 32`, particle budget <= 220, and do not attach per-frame scripts to static prop categories.
- Verify all imported transparent assets under linear filtering, mipmaps, and 16 px atlas gutters.
- Run `python3 tools/validate_assets.py --strict` before an art import branch is merged.
- Keep source masters outside generated atlas outputs; only required source art should enter version control.
