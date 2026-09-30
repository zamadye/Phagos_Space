# Runtime-authoring data

`organ_biomes/dermal_rift.json` is the first production arena plan. It intentionally separates **topology and dynamic state** from visual art:

- Godot runtime code will read graph nodes and links;
- artists retain material profiles and landmarks as authored data;
- QA can replay a matching `run_seed` and state sequence;
- `tools/validate_arena_plan.py` proves every declared state has a safe entry-to-exit path before runtime implementation starts.

The file is a production design contract, not a generated room layout and not a copied reference-game map. `tools/render_arena_plan.py` creates `docs/preview/dermal_rift_layout_plan.png` from this same data for topology review.
