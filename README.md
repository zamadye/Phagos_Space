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

## Development and preview workflow

The **source of truth remains native Godot**: `.tscn` scenes, Godot nodes, GDScript, and original PNG assets. A browser/WebView build is supported as an **export target**, not as a second HTML/Canvas implementation.

### Native desktop/editor loop

With Godot 4.3 or newer installed, launch the scene directly from the project root:

```bash
./scripts/preview_native.sh
```

To open the project in the editor instead:

```bash
./scripts/preview_native.sh --editor
```

### Browser/WebView loop

Use the normal local web-preview workflow:

```bash
./scripts/preview_web.sh
```

On its first run, this exports the same Godot project to `build/web/`, then serves it at [http://127.0.0.1:8008](http://127.0.0.1:8008). The generated folder is intentionally ignored by Git. It contains Godot's generated HTML, JavaScript, WebAssembly, and pack files; no arena or gameplay is implemented separately in browser code.

Use `WEB_PREVIEW_PORT=8010 ./scripts/preview_web.sh` to choose another port. `preview_web.sh` and `export_web.sh` detect `godot4`, `godot`, or an installed Godot Flatpak; set `GODOT_BIN=/path/to/godot` if your executable has a different name.

## Planned game-development sequence

1. Keep iterating the native arena/world presentation and readable tissue layers.
2. Add the requested UI/UX with Godot `Control` nodes and themes—not an HTML overlay.
3. Add the immune hero as a Godot `CharacterBody2D`, with input, collision, visual state, and animation.
4. Add only the gameplay systems needed after the UI and hero foundations are approved.
5. Re-export the same Godot project to WebView whenever a browser preview is needed.

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
