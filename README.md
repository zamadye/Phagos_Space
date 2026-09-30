# PHAGOS — Skin Cross-Section Study

PHAGOS is a native **Godot 4.3 2D game project**. Godot is the source of truth for the arena, future hero, input, collision, animation, and gameplay. The browser/WebView preview runs the **same Godot project** after a Web export.

```text
Godot scenes + GDScript + assets
             ↓
Godot Web export
             ↓
build/web/index.html + index.wasm + index.pck
             ↓
static server → WebView
```

The top-level game page is the Godot export. It is not a GitHub repository page, a React wrapper, or a separate HTML recreation of the arena.

## Current world study

- A clean cavity cut through ordered anatomy:
  **outer skin → fat → muscle → blue fascia → warm inner membrane → open cavity**.
- Three connected routes use controlled positional palette changes instead of a single repeated wall treatment.
- Original baked tissue maps supply visible fat lobules, directional muscle fibers, fascia, and a clean lumen.
- The current phase intentionally contains no mock UI, hero, combat, particles, random circles, or decorative animation.

## Run in WebView

A current Godot Web payload is committed under `build/web/` for immediate preview:

```bash
./scripts/preview_web.sh
```

Open:

```text
http://127.0.0.1:8008
```

The helper serves **only** `build/web/`. Do not open the repository URL as the game, and do not serve the repository root unless you navigate to `/build/web/` manually.

To create a fresh export after Godot changes:

```bash
./scripts/export_web.sh --release
```

## Develop with Godot

On a desktop machine with Godot 4.3 installed:

```bash
./scripts/preview_native.sh --editor
```

In a headless sandbox or CI, install the reproducible engine/toolchain:

```bash
bash tools/install_godot.sh 4.3-stable
export PATH="$HOME/.local/bin:$PATH"

godot --headless --path . --editor --quit
godot --headless --path . --script res://tools/runtime_cross_section_probe.gd
```

See [`docs/GODOT_SANDBOX_SETUP.md`](docs/GODOT_SANDBOX_SETUP.md) for the universal local, sandbox, CI, export, and WebView workflow.

## Planned implementation order

1. Iterate the Godot world/arena.
2. Design and implement the real UI/UX after the world foundation is approved.
3. Add the immune hero as a native Godot `CharacterBody2D`.
4. Add interaction and gameplay systems only after the UI and hero direction are defined.
5. Re-export Godot for every WebView review.

## Production roadmap and actual arena plan

The static skin cutaway is now treated as the visual prototype for the first real dynamic exploration biome. Read:

- [`docs/PRODUCTION_ROADMAP.md`](docs/PRODUCTION_ROADMAP.md) — milestones, dynamic-organ rules, UI/hero sequencing, and production gates;
- [`data/organ_biomes/dermal_rift.json`](data/organ_biomes/dermal_rift.json) — the authored first-biome graph, organ states, motion envelopes, and route safety contract.

## Research and art decisions

[`docs/REFERENCE_RESEARCH.md`](docs/REFERENCE_RESEARCH.md) records public-reference findings, confirmed-vs-inferred boundaries, original material rules, and visual exclusions.

## Validate

```bash
python3 tools/validate_godot_setup.py
python3 tools/validate_cross_section.py
python3 tools/validate_arena_plan.py
```

GitHub Actions validates the Godot project, material stack, GDScript, runtime scene contract, and exported Web payload.
