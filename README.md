# PHAGOS — Skin Cross-Section Study

An original biological-arena study with a deliberately split game-app architecture:

- **Godot 4 is the game engine**: world rendering, traversable arena, future immune hero, input, collision, animation, and gameplay live in Godot scenes and GDScript.
- **The HTML/CSS/TypeScript web app is the WebView application layer**: it owns the browser page, UI/UX, menus, HUD, application flow, and the bridge to the engine.

The top-level WebView is therefore a web app—not a GitHub repository page and not a raw Godot export page. The Godot Web payload is embedded inside the app at `/engine/`.

This project is **not a copy of Pathogenic assets or code**. It applies only high-level public visual principles to original art and implementation.

## Current engine study

- A top-down cavity cut through ordered anatomy:
  **outer skin → fat → muscle → blue fascia → warm inner membrane → open cavity**.
- Three connected, smooth routes use controlled positional palettes rather than a repeated monochrome wall.
- Original baked tissue art provides legible fat lobules, directional muscle fibers, fascia, and a clean lumen.
- The current arena intentionally has no fake HUD, hero, combat, particles, random circles, or decorative animation. Those systems belong to later implementation stages.

## Architecture

```text
Browser / WebView
└── web/                           HTML, CSS, TypeScript application
    ├── src/                       UI/UX and application-flow source
    ├── engineBridge.ts            typed UI ↔ engine message protocol
    └── public/engine/             generated Godot engine payload
        └── index.html             embedded iframe, never the app entry page
             ↓
Godot project root
├── scenes/main.tscn               arena scene
├── scripts/*.gd                   engine/game code
└── assets/                        original game art
```

The web application may present real UI/UX over the engine viewport. It does **not** redraw or imitate the arena in HTML; the world remains Godot-rendered. `web/engine_bridge.js` is the browser half of the future bridge. A later Godot `JavaScriptBridge` adapter can emit game state and receive deliberate UI commands.

## Run the application WebView

From the project root:

```bash
./scripts/preview_web.sh
```

Then open:

```text
http://127.0.0.1:5173
```

This starts the **HTML/JS application**, which embeds the Godot engine under `/engine/`. The script installs the web dependencies on first use. Use another port when necessary:

```bash
WEB_PREVIEW_PORT=8010 ./scripts/preview_web.sh
```

Do not open the repository URL as a game preview. Do not open `/engine/index.html` directly except when debugging the engine in isolation.

## Develop the two layers

### Godot game-engine work

```bash
./scripts/preview_native.sh --editor
```

Use Godot for the arena, hero, movement, physics, animation, combat, and world interaction. To refresh the embedded engine output after Godot changes:

```bash
./scripts/export_web.sh --release
```

### Web application / UI-UX work

```bash
cd web
npm install
npm run dev -- --host 0.0.0.0
```

Build the complete web application bundle with:

```bash
./scripts/build_web_app.sh
```

## Planned implementation sequence

1. Iterate the Godot arena/world presentation.
2. Build the actual UI/UX in `web/src/` using HTML, CSS, and TypeScript.
3. Add the immune hero in Godot as a `CharacterBody2D`.
4. Connect real UI state and engine state through the defined bridge.
5. Add only the gameplay systems approved after UI and hero foundations are in place.

## Research and art decisions

See [`docs/REFERENCE_RESEARCH.md`](docs/REFERENCE_RESEARCH.md) for public-reference findings, confirmed-vs-inferred limits, material rules, and exclusions.

## Regenerate original materials

```bash
python3 -m pip install Pillow
python3 tools/generate_skin_materials.py
```

The generator creates original source strips and baked arena maps. It is an offline authoring step; Godot presents the semantic PNG layers.

## Verify

```bash
python3 tools/validate_cross_section.py
# With Godot installed:
godot --headless --path . --script res://tools/runtime_cross_section_probe.gd
```

CI validates the material stack, GDScript, exported embedded Godot engine, and the production HTML/JS application build.
