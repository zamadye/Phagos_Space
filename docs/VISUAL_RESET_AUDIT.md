# Phagos Space — visual foundation reset audit

Date: 2026-10-07
Branch: `arena/01a107da-phagos-space`

This is the forensic checkpoint before rebuilding the failed red-tunnel presentation. The current browser export is treated as failure evidence, not as a visual baseline.

## Inventory

| System | Current purpose | Decision | Reason |
|---|---|---|---|
| `scripts/main.gd` | Builds the route, player, track, procedural tunnel, rails, hazards, blood actors, and gameplay HUD in one monolithic runtime scene | **KEEP movement/gameplay infrastructure, REBUILD visual entry path** | Player/path logic may be reusable later, but `_build_tunnel`, `_build_track`, `_build_route_branch_geometry`, and procedural tunnel materials are the failed presentation |
| `scenes/Main.tscn` | Main runtime entry scene | **KEEP as legacy gameplay checkpoint, disconnect from Phase 1 visual slice** | Phase 1 needs a controlled handcrafted vessel scene, not the current arena boot |
| `scripts/wall_study.gd` | Isolated wall-only preview with dynamic module placement and review overlay | **DELETE/REPLACE** | It validates a tunnel wall ring rather than a complete vessel volume with floor, ceiling, and unified biological surface |
| `scripts/organic_wall_module.gd` | Runtime GLB instantiation, wall shader override, spot pulsing, damage burst | **REBUILD as `VesselSection` runtime wrapper** | The spot API can return later, but the current module is attached to the failed tube/ring architecture |
| `scenes/OrganicWallModule.tscn` | Single authored wall tile scene | **REBUILD** | Replace wall tile with complete vessel section containing floor, ceiling, left/right walls, and continuous interior volume |
| `assets/vessel_wall_breathing.glb` | Existing generated wall tube with helical ridges and sockets | **REBUILD in Blender** | Current silhouette reads as rails/strips and is not a complete vessel section |
| `tools/blender/build_biological_assets.py` | Generates current wall/pathogen GLBs through `bpy` | **REBUILD** | Replace the ring/tube generator with a handcrafted centerline/cross-section vessel builder and native `.blend` source |
| `shaders/organic_wall.gdshader` | Current unshaded red procedural wall material | **DELETE/REPLACE** | Unshaded sine bands are the wrong material foundation; new shader must support lit wet tissue, roughness, normals, seams, and controlled deformation |
| `scripts/organic_activity_manager.gd` | GPU blood/organism/mote emitters | **KEEP dormant for Phase 1; integrate in Phase 2** | Particles cannot substitute for vessel geometry; blood/cells return only after static vessel passes |
| `scripts/bio_actor.gd` | Small runtime biological actor controller | **KEEP for later** | Independent utility, not part of the new vessel foundation |
| `assets/*blood-cell*.glb` and converted cell GLBs | Authored biological actor meshes | **KEEP; defer integration** | Reusable after the vessel and depth composition pass |
| `scenes/WallStudy.tscn` | Current web wall validation scene | **REBUILD as `OrganicVesselFoundation.tscn`** | The new first milestone must validate the whole 30–50m vessel volume, not only a wall study |
| `tools/browser/*` | Browser/Web evidence and smoke scripts | **KEEP as QA only** | Browser is a preview/output path; it is not the source implementation |
| `index.html`, `index.js`, `index.wasm`, `wall-study.*` | Generated Godot Web exports | **REGENERATE; never hand-author** | These are generated delivery artifacts and must not be mistaken for the implementation |

## Phase 1 reset scope

Delete or disconnect from the new foundation:

- procedural red track and side rails
- current procedural tunnel shell
- current helical wall-only presentation
- unshaded sine-band wall material
- current camera framing and debug letterbox assumptions
- decorative particle-first presentation

Build first, before player/enemies/progression:

- `OrganicVesselFoundation.tscn`
- `VesselSection` Blender source and GLB
- unified floor/wall/ceiling interior
- controlled 30–50m handcrafted curved sequence
- perspective `CameraRig`
- lit wet tissue material
- visible static 3D depth scorecard screenshots

Phase 1 gate: if the screenshot reads as a red track, rails, or neon tunnel, stop and rebuild again. Do not add gameplay systems to compensate.
