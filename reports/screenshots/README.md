# Visual QA captures

CI generates the following 1920×1080 PNGs with `tools/capture_screenshots.gd`:

- `heart.png`
- `lung.png`
- `brain.png`
- `marrow.png`

Before it captures any biome, the script now asserts that every committed source-art
texture is both present in the exported PCK and loadable as a 2048² `Texture2D`. A
missing dynamic asset is therefore a QA failure rather than a silent procedural fallback.

The local source-art verification uses the same dimensions and writes its evidence as:

- `current_source_heart_1920x1080.png`
- `current_source_lung_1920x1080.png`
- `current_source_brain_1920x1080.png`
- `current_source_marrow_1920x1080.png`
- `current_source_art_contact_sheet_1920x1080.png`

Captures are intentionally not source-controlled because they are derived render output.
They are uploaded with the `phagos-quality-reports` workflow artifact after an official
Web export.
