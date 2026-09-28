# PHAGOS — Skin Cross-Section Study

A clean, original Godot 4 arena study rebuilt from zero after the earlier renderer was discarded.

This project is **not a copy of Pathogenic assets or code**. It studies the useful visual principles visible in public material—clear anatomical strata, biome-local palettes, readable silhouettes, and restrained motion—then implements an original static skin cutaway in native Godot.

## What is currently built

- A top-down, no-HUD arena carved as a long open wound through a cross-section of tissue.
- Each corridor exposes nested, clean material bands in a consistent physical order:
  **outer skin → fat → muscle → blue fascia → warm inner membrane → open cavity**.
- Three connected, smooth routes use distinct local palette balances so the walls change by anatomical position without noisy random overlays.
- Baked, tileable material strips provide directional fibers and lobules. They are original generated source assets, not copied game art.
- There are no particles, floating circles, screen overlays, decorative props, HTML loading overlay, gameplay actors, or continuous environment animation.

## Run

Open `project.godot` in Godot 4.3 or newer and run the main scene. The main scene is intentionally a native Godot `Node2D` composition; no browser shell or HTML overlay is part of the presentation.

## Research and art decisions

See [`docs/REFERENCE_RESEARCH.md`](docs/REFERENCE_RESEARCH.md) for the public-reference findings, what is and is not being emulated, the rendering plan, palette roles, and review checklist.

## Regenerate original material strips

```bash
python3 -m pip install Pillow
python3 tools/generate_skin_materials.py
```

The generator creates only original assets under `assets/materials/` plus a local composition preview. It is an offline authoring step; the running Godot scene uses the baked PNGs.

## Verify

```bash
python3 tools/validate_cross_section.py
# With Godot installed:
# godot --headless --path . --script res://tools/runtime_cross_section_probe.gd
```

The static check verifies all layer maps, material colour roles, and exclusion of overlay/particle routes. The runtime probe instantiates the scene and verifies the actual `Sprite2D` stack.
