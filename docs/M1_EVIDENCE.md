# M1 validation evidence

Tanggal validasi: **2026-10-06**  
Branch: `arena/01a107da-phagos-space`

M1 masih **IN PROGRESS**. Evidence di bawah membuktikan runtime, export, root-server contract, browser WebGL boot, debug reference overlay, Pokemon player GLB, authored blood-flow MultiMesh, GPU ambient activity, wall-event uniforms, dan satu sesi browser start → active → hazard → finish → retry. Reference visual gate tetap belum lulus; screenshot overlay terbaru dipakai untuk iterasi berikutnya.

## Reproducible commands

Toolchain lokal disiapkan dari arsip yang sudah ada di repository:

```bash
./scripts/prepare_toolchain.sh
```

Godot editor/headless parse and import validation:

```bash
.local/godot/Godot_v4.6.2-stable_linux.x86_64 \
  --headless --path . --editor --quit
```

Result: exit code `0`, no GDScript parse error.

## Gameplay smoke run

```bash
.local/godot/Godot_v4.6.2-stable_linux.x86_64 \
  --headless --path . --quit-after 7000
```

Observed deterministic runtime log:

```text
M1 arena ready: path_length=274.4m; hazards=6
M1 hazard collision: index=1 hit_count=1
M1 session complete: distance=271.4m; hits=1
```

This exercises scene boot, procedural 3D construction, intact Pokemon GLB player visual, Curve3D forward movement, hazard proximity/collision response, and automatic finish without login or external services.

## Web export evidence

```bash
.local/godot/Godot_v4.6.2-stable_linux.x86_64 \
  --headless --path . --export-debug Web index.html
```

Canonical root files produced:

| File | Size at validation |
|---|---:|
| `index.html` | 5,298 bytes |
| `index.js` | 279,925 bytes |
| `index.wasm` | 35,749,181 bytes |
| `index.pck` | 8,800,372 bytes |

Additional Web runtime files (`index.png`, audio worklets) are kept because the generated HTML references them.

Release template validation was also run to a temporary directory (without replacing the canonical debug files):

```bash
.local/godot/Godot_v4.6.2-stable_linux.x86_64 \
  --headless --path . --export-release Web /tmp/phagos-web-release/index.html
```

Result: release `index.html`, `index.js`, `index.wasm`, and `index.pck` were all generated successfully.

Root server check:

```bash
python3 -m http.server 8000 --bind 0.0.0.0
curl -fsSI http://127.0.0.1:8000/index.html
curl -fsSI http://127.0.0.1:8000/index.wasm
```

Observed: both responses were `200 OK`; `.wasm` was served as `application/wasm`.

## Browser WebGL smoke evidence

The browser smoke test uses Puppeteer Core and `@sparticuz/chromium`. The important workaround is implemented in `tools/browser/smoke.mjs`: it sets the package's AL2023 compatibility path before dynamically importing Chromium. The package then extracts its bundled `al2023.tar.br` libraries and sets `LD_LIBRARY_PATH`, so the test does not depend on system-installed `libnspr4.so`, `libnss3.so`, or `libnssutil3.so`.

Reproducible command after the root server is running:

```bash
cd tools/browser
npm ci --ignore-scripts
npm run smoke
```

Observed result:

```json
{
  "title": "Phagos Space (DEBUG)",
  "canvas": true,
  "canvasBox": { "width": 1024, "height": 1024 },
  "errors": []
}
```

Screenshot evidence: `evidence/m1-web-smoke.png`.

Asset-driven field check after repository FBX/OBJ conversion:

```text
AUTHORED_BLOOD_CELL_ACTORS=34
TOTAL_BIO_ACTORS=149
M1 blood multimesh: red_instances=66; purple_instances=16; actors=82
M1 blue cell multimesh: instances=26; mesh_source=lynphocyte.glb
```

Screenshot evidence: `evidence/m1-assets-active.png` and `evidence/m1-web-smoke.png`. The runtime bloodstream now uses two `MultiMeshInstance3D` nodes with the authored `siderocyte.glb` mesh as the primary source; procedural `SphereMesh` is only the missing-asset fallback. Wall-bound blue membrane cells now use a third `MultiMeshInstance3D` with `lynphocyte.glb`; route frame placement, surface orientation, bob, pulse, lateral wave, and per-instance rotation remain runtime-controlled.

GPU ambient activity check:

```text
M1 organic activity: blood_emitters=5; organism_emitters=5; mote_emitters=5; gpu_particles=true
```

`OrganicActivityManager` owns five route-aligned blood-flow emitters, five authored pathogen-organism emitters, five golden-mote emitters, and one emergence burst. Each emitter is a `GPUParticles3D`; the blood and organism draw passes use imported authored meshes. Wall emergence calls the manager with the strongest socket event so the burst follows the same scripted event as the wall bulge.

## Route graph and branch evidence

The route graph now contains five main segment types and two branch curves:

```text
main_straight_intro → main_left_turn → main_s_curve
→ main_right_turn → main_exit_straight
junction_01 → branch_left | branch_right
```

Deterministic headless route check:

```text
ROUTE_GRAPH_MAIN_SEGMENTS=5
ROUTE_BRANCH_CURVES=["left", "right"]
ROUTE_STATE={ current_route: "branch_right", selected_branch: "right", junction_entered: true, branch_collision: true }
TRAVERSAL_BRANCH_MID=(6.635485, 0.150688, -201.3434)
```

The default branch is derived from seed `20261005`; `Q`/left can request the left branch and `E`/right can request the right branch before the junction. Player/camera now sample the selected branch Curve3D after the junction; the branch tunnel shell, path, rails, and collision gates are active.

## Blender authored asset and enemy spawn evidence

Blender Python API `5.0.1` was installed in the sandbox and executed in background mode. The following exports were created and then re-imported in Blender and Godot:

```text
assets/vessel_wall_breathing.glb
  AnimationPlayer: VesselWall_Breathing
assets/pathogen_emergence.glb
  AnimationPlayer: Pathogen_EmergeFromWall
```

The wall animation is a keyed membrane shape deformation loop; its material has no journey/UV scrolling. Wall modules are placed at 10m intervals with a 2m overlap and deterministic radial/twist variation to hide seams through turns. The six hazards now use authored pathogen geometry. Their spawn modes are:

```text
road, wall_left, road, wall_right, wall_left, road
```

Wall-origin hazards interpolate from a tunnel-wall socket to the lane while retaining their collision wrapper and Blender-authored emergence visual. Three explicit `WallEmergenceSocket` nodes are created for the two left-wall and one right-wall spawn events; their side selection is validated against the route frame.

## Full M1 debug QA sequence

The longer browser QA script is `tools/browser/m1_qa.mjs` and is exposed as:

```bash
cd tools/browser
npm run qa:m1
```

For a deterministic reference comparison, the QA script presses `F3` to reset and lock `distance_s` at the canonical start zone, then presses `F2` for the overlay. `F3` is debug-only and is released before the active/finish/retry sequence.

The intended sequence is:

- `evidence/m1-web-boot.png` — boot/start state.
- `evidence/m1-reference-overlay.png` — F2 debug overlay with `Gameplay-Arena.jpg` at 32% opacity.
- `evidence/m1-web-active.png` — active movement state.
- `evidence/m1-web-finish.png` — `SESSION COMPLETE`, distance, and retry prompt.
- `evidence/m1-web-retry.png` — `R` resets the run to the active start state.

After the MultiMesh and wall-event integration, the current short smoke validation is PASS (`canvas=true`, `errors=[]`). The full finish/retry browser sequence was also executed from `tools/browser` with `canvas=true` and `errors=[]`; it produced all five evidence screenshots. The test takes about five minutes in software-rendered Chromium, so the command timeout must allow for the authored wall tiles.

## Visual gate review

The detailed current-vs-reference review is recorded in `docs/M1_VISUAL_GAP_REVIEW.md`. The review confirms that the current visual gate is **NOT PASS** even though runtime/export/gameplay gates pass.

## Remaining evidence before M1 can be marked DONE

- Use the captured overlay to calibrate vanishing point, foreground rail width, path width, and avatar position against `Gameplay-Arena.jpg`.
- Increase tunnel fiber/depth density, blue/yellow actor density, glass bloodstream density, foreground biological props, and red-pink lighting until the overlay is materially closer.
- The previous Roblox-like procedural player was replaced in the current Web debug build by the selected Pokemon character from `low_poly_animated_pokemon_cartoon_character_pack.glb`, imported intact through a wrapper. Enemy/virus/boss GLB integration and skill layers remain in Fase 4A/M2.
