# Runtime-authoring data

`organ_biomes/dermal_rift.json` is the first playable PHAGOS arena contract. It separates **topology and dynamic organ state** from visual implementation:

- `scripts/dermal_rift_expedition.gd` reads nodes, links, active-route sets, anchor offsets, and route-width scales to build the playable cavity/collision layout;
- `scripts/dermal_rift_world.gd` renders the same route and chamber data as layered anatomy;
- artists retain material profiles and landmarks as authored data;
- QA can validate every state and later replay a matching `run_seed` / state sequence;
- `tools/validate_arena_plan.py` proves state connectivity, safe widths, bounded anchor motion, and player-readable state cues.

The file is a production design contract, not a generated room layout and not a copied reference-game map. `tools/render_arena_plan.py` creates `docs/preview/dermal_rift_layout_plan.png` from this same data for topology review.
