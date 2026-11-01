# Organic vessel foundation — visual QA scorecard

Date: 2026-11-01
Checkpoint: `checkpoint-organic-vessel-foundation`
Evidence: `evidence/m1-web-smoke.png` (latest Web inspection; functional smoke only)

This scorecard is deliberately split from functional QA. The Web capture is a visual preview only; it is not authoritative proof of the Mobile renderer.

## Functional QA

| Check | Result | Evidence |
|---|---|---|
| Godot headless boot | PASS | `BLENDER vessel animation: clip=OrganicVessel_Breathing; playing=true` |
| Complete authored volume present | PASS | `floor=true; ceiling=true; left_wall=true; right_wall=true; length=42m` |
| Traversal path separate from geometry | PASS | `points=6; length=42m; geometry_separate=true` |
| Browser canvas | PASS | `canvas: true` |
| Browser console/page errors | PASS | `errors: []` |

## Static visual QA

Scale: 0 = absent/fail, 5 = ready for the next checkpoint. This is the static vessel gate, not the final vertical-slice score.

| Category | Score | Finding |
|---|---:|---|
| Organic geometry | 4/5 structural, 2/5 visual | Blender-authored closed volume now includes a curved S-centerline, continuous floor/ceiling/sidewalls, stronger fascicle relief, and an extended tapering throat. The capture still does not make those surfaces legible enough. |
| Volumetric depth | 2/5 | The far closure is real geometry, but the current view is dominated by near burgundy surfaces and does not yet communicate long-distance tunnel perspective. |
| Material quality | 2/5 | Wet-tissue shader, fascicle layers, seams, roughness, specular, and breathing are present; the Web capture remains too dark/flat and too red to pass biological-material inspection. |
| Camera composition | 2/5 | Perspective camera and separate path exist, but the current composition still reads as a red chamber/tunnel rather than a clear vessel traversal view. |
| Lighting | 2/5 | Controlled key/rim/fill/far-surface lights exist, but floor, walls, ceiling, and distant surface remain weakly separated in the evidence image. |
| Wall animation | 2/5 | Imported `OrganicVessel_Breathing` clip is playing and runtime shader breathing is active; visual deformation proof remains deferred until the static gate is accepted. |
| Blood flow | N/E | Deferred by scope. No blood or cells before this static vessel gate. |
| Environmental depth | 2/5 | The 42 m authored vessel and independent six-point path are represented, but the screenshot does not yet prove readable depth. |
| Hero integration | N/E | Deferred by scope. No player is added before the foundation gate. |
| Cinematic quality | 2/5 | Functional Web smoke passes, but visual acceptance is explicitly withheld because the image still reads closer to a dark red tunnel/chamber than a living vessel. |

## Gate decision

**HOLD / FAIL — static organic vessel foundation.** The asset and scene architecture are rebuilt and functional, but `evidence/m1-web-smoke.png` does not pass the visual gate. It still reads too much like a dark red chamber/tunnel: floor, walls, ceiling, curvature, tissue depth, and distant surface are not visually legible enough.

Do not add blood, cells, hero integration, enemies, progression, events, or gameplay polish until a new static capture clearly communicates a 3D living vessel. Functional boot, Web canvas, and `errors: []` are not visual acceptance.
