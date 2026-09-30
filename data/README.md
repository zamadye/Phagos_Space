# Organ-production authoring data

`organ_biomes/dermal_rift.json` is the **future multi-chamber production contract** for Dermal Rift. It records the nine-anchor, ten-route organ design, state safety limits, material order, movement envelopes, and state cues needed when the game expands beyond the first hand-authored traversal slice.

The current Godot slice intentionally does **not** draw this topology image as visible room graph geometry. Instead, it proves the visual/playability fundamentals with a hand-authored anatomical playfield, physical cavity collision, a local fascia valve, landmark interactions, and an organ gate. That prevents a planning graph from being mistaken for the finished arena.

`tools/validate_arena_plan.py` validates the production contract. `tools/render_arena_plan.py` creates `docs/preview/dermal_rift_layout_plan.png` for design review only. Neither file is a browser-game substitute or a runtime background.
