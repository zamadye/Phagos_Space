# Visual QA captures

CI generates the following 1920×1080 PNGs with `tools/capture_screenshots.gd`:

- `heart.png`
- `lung.png`
- `brain.png`
- `marrow.png`

They are generated after every production Web export and uploaded as the `phagos-quality-reports` workflow artifact. They are intentionally not source-controlled because they are derived render output.
