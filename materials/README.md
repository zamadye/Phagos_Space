# Material presets

These `ShaderMaterial` resources are neutral defaults for imported atlas sprites. Runtime procedural geometry creates per-biome material instances so pulse phase, palette, and noise seed do not repeat.

- `vein_pulse_default.tres`: additive vessel overlay.
- `membrane_overlay_default.tres`: translucent moving membrane ridges.
- `soft_glow_default.tres`: additive HDR-friendly signal glow.

For a production atlas sprite, duplicate the appropriate preset, set its palette uniforms from `PhagosBiomeDefinition`, then assign it to the imported `Sprite2D`, `Line2D`, or `Polygon2D`.
