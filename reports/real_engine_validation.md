# Real-engine validation record

**Run date:** 2026-09-26 (Asia/Kuching)

**Scope:** local validation only; generated browser files and captures stay in ignored `build/web/`.

## 1. Godot 4.3 source validation

A real `Godot 4.3.stable.custom_build.77dcf97d8` executable was available locally for the validation run.

| Check | Command / result |
| --- | --- |
| Project import and script/shader compilation | `godot --headless --path . --editor --quit` → exit `0`; no `SCRIPT ERROR`, parse, compile, shader, or failed-script diagnostics |
| Real Web preset PCK | `godot --headless --path . --export-pack Web /tmp/phagos-production-4.3.pck` → exit `0` |
| Pack integrity spot-check | `GDPC` header; main scene and compiled arena controller present |

The native build intentionally has no desktop renderer integration, so its `No renderers available` startup notice is expected in this constrained headless environment and is not treated as visual validation.

The asset-manifest validator itself runs with Pillow installed, but the current repository intentionally has no imported source PNG art: it reports 98 missing optional art specs. The manifest-backed procedural fallback remains the visual source for these validation frames.

## 2. Browser engine smoke validation

A local WebGL validation harness ran the arena in a real Godot Web engine and observed rendered gameplay frames:

- Browser: npm-unpacked `@sparticuz/chromium` Chromium `153.0.8010.0`.
- Engine runtime: npm-unpacked Godot Web `4.7.2`, single-threaded, Compatibility / WebGL 2.
- Browser console confirmed WebGL 2 Compatibility, engine startup, arena generation completion, and GPU-particle backend (`131` particles).
- The forced CPU particle fallback was also run successfully (Bone Marrow, `132` particles) with the same 1920 × 1080 canvas and no errors.
- The custom loading screen completed and was removed.
- The canvas backing store and CSS size were both observed at **1920 × 1080**.
- No browser page errors, request failures, or Godot console errors were recorded for Heart, Lung, Brain, or Bone Marrow runs.
- Local captures: `build/web/real-web-{heart,lung,brain,marrow}-gpu-1920x1080.png` and `build/web/real-web-marrow-cpu-1920x1080.png`.

The browser harness uses a temporary source-compatible PCK for the cross-minor `4.3`-authoring / `4.7`-runtime test boundary: it exports scripts as text and removes only global-class type-resolution assumptions that are specific to Godot 4.3's class-cache format. It does **not** replace arena geometry, room generation, shaders, biome definitions, props, or runtime behavior. This is real engine execution and rendered-frame evidence, but it is **not an official Godot 4.3 Web release export**.

## 3. Known limits / remaining release gate

The production command remains:

```bash
GODOT_BIN=/path/to/godot ./scripts/export_web.sh
```

It still requires matching Godot 4.3 Web export templates. A direct 4.3 release-export attempt failed only because `web_nothreads_debug.zip` and `web_nothreads_release.zip` are absent at Godot's expected template path. The staging export script preserved the previous local preview byte-for-byte after that failure. Those templates could not be downloaded in this environment because the release/CDN route is blocked. Therefore this record does **not** claim that an official 4.3 `--export-release Web` artifact was produced.

The same environment has no runnable Firefox or Microsoft Edge executable. Chromium/WebGL validation is complete; Firefox and Edge remain explicitly unexecuted rather than inferred from Chromium.

The F3 overlay is intentionally compiled only for debug builds (`OS.is_debug_build()`); it is absent from the release Web runtime used for this smoke pass.
