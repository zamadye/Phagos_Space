# Phagos source-art pipeline

The running Godot demo is a **hybrid art pipeline**: procedural anatomy preserves organic spline geometry, while manifest-led transparent PNG layers supply painterly surface variation. The first authored pass currently includes four biome floor overlays, four biome vessel overlays, and Heart/Lung cortical rim art; it is loaded by `PhagosAssetResolver` at runtime. The remaining manifest entries intentionally retain a procedural fallback until their source art has passed review.

Keeping source art separate lets the environment remain runnable during look development and avoids committing generated atlas output. The supplied masters are original biology-inspired work, not imported or traced external-game art.

```text
assets/
├── biome/       organ-specific overlays: veins, alveoli, neuron networks, marrow cavities
├── walls/       modular organic wall kit (straight / curve / T / X / end cap / chamber rim)
├── floor/       seamless 2048×2048 tissue textures
├── props/       independent transparent gameplay-environment props
├── particles/   512×512 particle masters
├── decals/      transparent tears, stains, scratches, residue
└── manifest/    exact source-art contract used by tools/validate_assets.py
```

## Import sequence

1. Generate/export art from the locked prompts in [`docs/ASSET_GENERATION_PROMPTS.md`](../docs/ASSET_GENERATION_PROMPTS.md).
2. Name every file exactly as listed in `manifest/asset_manifest.json`; retain straight alpha PNG, 2048×2048 masters (512×512 particles).
3. Run:
   ```bash
   python3 -m pip install Pillow
   python3 tools/validate_assets.py --strict --report reports/asset_validation.json
   ```
4. Complete the human checklist in the generated report, especially the top-down perspective and wall-kit seam review.
5. Build atlas pages (generated output is ignored by Git):
   ```bash
   python3 tools/atlas_assets.py --page-size 8192 --padding 16
   ```
6. In Godot, enable mipmaps for floor/wall atlas textures, use linear filtering, and duplicate shader materials per biome so pulse phase and palette remain unique.

## Runtime fallback versus final art

`OrganicRoom`, `OrganicCorridor`, `BreakableProp`, `BiologicalParticleField`, and the supplied shaders create the arena immediately with zero external textures. Final source art can replace these procedural layers selectively: use imported floor textures for `CytoplasmFlow`, wall sprites for a high-detail rim pass, and prop/particle atlases for production content. Do not replace the spline geometry with a square tile map.
