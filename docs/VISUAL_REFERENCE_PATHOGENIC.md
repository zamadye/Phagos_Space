# Microscopic arena reference pass

This pass studies the **high-level environmental language** of the Pathogenic arena references supplied for Phagos: a dark cortical silhouette framing a luminous organic lumen, layered membrane texture, dense cellular wall detail, and a few deliberately bright biologic focal points.

It does **not** copy Pathogenic artwork, characters, HUD, combat telegraphs, layouts, assets, or gameplay. Phagos remains an arena-only Godot kit with no player, combat system, enemies, pickups, or in-game UI.

## Original Phagos translation

| Reference observation | Original Phagos implementation |
| --- | --- |
| Strong dark outer tissue silhouette | Thick tissue-shadow cortex and nested membrane/lumen rim lines in `OrganicRoom` and `OrganicCorridor` |
| Dense living wall edge | Seeded inward cilia / microvilli and procedural vesicle clusters, drawn with Compatibility-safe lines and circles |
| Clear bright-vs-dark readability | Biome-specific emissive signals remain focal; substrates stay restrained and organ-specific |
| Chambers feel like cellular spaces rather than rooms | Spawn, combat, elite, shop, secret, and boss graph nodes receive distinct environmental anatomy, never UI markers |
| Curved lumen routes | Existing seeded Bezier corridor graph is retained and its walls gain epithelial fringe detail |

## Safety and performance rules

- All additions are deterministic from the existing room/corridor seed.
- No external game art is imported.
- The pass uses static `CanvasItem` drawing for room/corridor anatomy; animated work remains limited to existing shaders, glow nodes, and capped lights.
- The active Web path uses line/circle detail rather than a new heavy mesh or texture batch.
- Saturated colors stay constrained to biome signals and room identity focal points.
