# Organic vessel foundation — visual QA scorecard

Date: 2026-10-08  
Checkpoint: `checkpoint-organic-vessel-foundation`  
Evidence: `evidence/organic-vessel-foundation-web.png`

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
| Organic geometry | 4/5 | One Blender-authored closed volume with curved centerline, irregular longitudinal folds, softened floor/ceiling profile, and no rails or track. |
| Volumetric depth | 3/5 | Near tissue, layered wall folds, and a distant lumen opening read in the perspective capture; depth lighting can be refined later. |
| Material quality | 3/5 | Lit procedural wet-tissue shader with fascicle bands, connective seams, roughness, specular response, and restrained emission. More biological surface breakup belongs in the materials checkpoint. |
| Camera composition | 3/5 | Perspective camera is offset from the center and aims through the authored bend; a hero-facing composition is intentionally deferred. |
| Lighting | 3/5 | Warm ambient/key/rim setup gives readable wall volume without letterboxing; lighting polish is deferred to the cinematic-camera checkpoint. |
| Wall animation | 2/5 | Imported `OrganicVessel_Breathing` clip is playing and runtime shader breathing is active; motion proof is deferred until the static gate is accepted. |
| Blood flow | N/E | Deferred by scope. No blood or cells before this static foundation gate. |
| Environmental depth | 3/5 | 42 m vessel and independent six-point path are represented; blood/cell scale layers are deferred. |
| Hero integration | N/E | Deferred by scope. No player is added before the foundation gate. |
| Cinematic quality | 3/5 | The capture reads as a biological interior rather than a red track or primitive tunnel; final cinematic grading waits for camera/material checkpoints. |

## Gate decision

**PASS — static organic vessel foundation.** The image does not read as a character running on a red track: there is no track, side rail, decorative line system, or black letterbox. The connected floor/wall/ceiling volume and distant lumen establish the controlled vessel slice.

This does **not** claim the final vertical-slice gate. Blood flow, hero integration, biological emergence, and full cinematic proof remain explicitly deferred to their later checkpoints.
