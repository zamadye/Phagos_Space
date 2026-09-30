# Godot universal setup — local desktop, sandbox, CI, and WebView

This is the reusable setup contract for PHAGOS and other Godot projects. Godot is the engine. Scenes and scripts remain text files, so a headless sandbox can validate and export a project even without a GUI or GPU.

> **PHAGOS note:** this project is a Godot 4.3 **2D** project. The generic 3D camera, GLB, and collision examples used by other games do not belong here unless the project scope later adds 3D content.

## Core workflow

```text
project.godot + .tscn + .gd + assets
            ↓
Godot Standard / headless Godot
            ↓
Godot Web export: build/web/index.html + .wasm + .pck
            ↓
static HTTP server
            ↓
WebView / browser preview
```

The WebView opens the exported game at `build/web/`. It is not a repository URL, a React wrapper, or a separate HTML recreation of the game.

## Desktop installation

Download the matching **Godot 4.3 Standard** build from the [Godot archive](https://godotengine.org/download/archive/), then install the matching export templates through:

```text
Editor → Manage Export Templates → Download
```

On Linux, a portable installation is enough:

```bash
unzip Godot_v4.3-stable_linux.x86_64.zip
chmod +x Godot_v4.3-stable_linux.x86_64
./Godot_v4.3-stable_linux.x86_64 --editor --path /path/to/Phagos_Space
```

## Headless sandbox / CI installation

Run the versioned installer committed with the project:

```bash
bash tools/install_godot.sh 4.3-stable
export PATH="$HOME/.local/bin:$PATH"
godot --version
```

The script installs the Standard Linux executable in `~/.local/bin/godot` and templates in:

```text
~/.local/share/godot/export_templates/4.3.stable/
```

These locations are intentionally outside Git. Sandboxes may need to run the installer again in a new session. CI uses `chickensoft-games/setup-godot` with the same 4.3 version and export templates.

## Validate without the editor

```bash
# Parse/import the project.
godot --headless --path . --editor --quit

# Instantiate the actual playable main scene and validate controller, collision,
# native HUD, progression gate, and dynamic organ-state routing.
godot --headless --path . --script res://tools/runtime_expedition_probe.gd

# Validate portable project/export contracts and authored arena behavior.
python3 tools/validate_godot_setup.py
python3 tools/validate_arena_plan.py
python3 tools/validate_expedition_build.py
```

`project.godot`, `.tscn`, and `.gd` are text and can be reviewed or edited in a headless environment. The editor remains the preferred tool for visual scene authoring on a desktop machine.

## Export and run in WebView

```bash
# Generate build/web/ from the same Godot project.
./scripts/export_web.sh --release

# Serve only the generated export directory.
./scripts/preview_web.sh
```

Then open:

```text
http://127.0.0.1:8008
```

The equivalent direct server command is:

```bash
python3 -m http.server 8008 --bind 0.0.0.0 --directory build/web
```

Do not serve the repository root as the game page. If you do, use `/build/web/` explicitly; the supported command above serves the export as `/`.

## Project layout

```text
Phagos_Space/
├── project.godot                 engine configuration and main scene
├── export_presets.cfg            Web export contract
├── scenes/                       Godot scenes
├── scripts/                      GDScript and run/export helpers
├── assets/                       original game assets
├── tools/
│   ├── install_godot.sh          portable installer
│   ├── validate_godot_setup.py   engine/export contract checks
│   ├── runtime_expedition_probe.gd
│   ├── validate_arena_plan.py
│   └── validate_expedition_build.py
├── build/web/                    generated Godot Web payload
└── docs/
    └── GODOT_SANDBOX_SETUP.md    this guide
```

## When a non-Godot preview is appropriate

A standalone HTML/Canvas or Three.js page can be useful for **asset inspection or art prototyping** when an engine viewport cannot run in a sandbox. It must be explicitly labelled as an approximation. It does not replace the Godot game runtime, scene behavior, input, collision, or export validation.

## Git discipline

- Keep source and generated Web payload aligned with `./scripts/export_web.sh`.
- Use normal commits and fast-forward pulls on `arena/01a0d899-phagos-space`.
- Do not use force-push for normal iteration.
- Run the validation commands before pushing engine or export changes.
