# PHAGOS — Dermal Rift

PHAGOS is a native **Godot 4.3 2D exploration-adventure project**. Godot owns the world art, player movement, collision, camera, dynamic tissue behavior, interaction, and Web export.

```text
Godot scene + GDScript + authored arena art
                 ↓
playable exploration / collision / tissue-state runtime
                 ↓
Godot Web export → static HTTP server → WebView
```

There is no React shell, iframe game, standalone HTML recreation, or HTML-style dashboard layered over the arena.

## Current playable slice

**Dermal Rift** is a hand-authored anatomical space, not a generated graph diagram:

- A single illustrated cutaway playfield carries coherent dermis, adipose tissue, muscle, fascia, membrane, and lumen from left to right.
- Move the native Godot scout cell with **WASD** or **arrow keys**; hold **Shift** to sprint.
- The lower loop contains a living teal **Echo**. Reach it and press **E / Enter**.
- Return to the amber **Deep Cavity** in the central chamber and press **E / Enter** to wake it.
- The right-side membrane retracts; cross it to finish the route.
- Press **R** to request the next organ state. The local fascia valve visibly opens/closes the lower loop; it will not close while the explorer remains inside that loop.

All changing tissue is rendered inside the Godot world. The scene intentionally uses no full-screen HUD, map panel, status card, or browser overlay.

## Run in WebView

```bash
./scripts/preview_web.sh
# http://127.0.0.1:8008
```

The helper serves only `build/web/`, which is the direct Godot Web export.

To make a fresh payload after Godot changes:

```bash
./scripts/export_web.sh --release
```

## Develop and validate

```bash
bash tools/install_godot.sh 4.3-stable
export PATH="$HOME/.local/bin:$PATH"

godot --headless --path . --editor --quit
godot --headless --path . --script res://tools/runtime_expedition_probe.gd
python3 tools/validate_godot_setup.py
python3 tools/validate_arena_plan.py
python3 tools/validate_expedition_build.py
```

See [`docs/GODOT_SANDBOX_SETUP.md`](docs/GODOT_SANDBOX_SETUP.md) for the portable local/sandbox/CI/export workflow. The wider organ-production plan remains in [`docs/PRODUCTION_ROADMAP.md`](docs/PRODUCTION_ROADMAP.md); the present slice is deliberately proving visual traversal and tissue-state safety before a final immune hero or combat system.
