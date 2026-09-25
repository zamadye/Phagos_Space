# Phagos — locked generator brief and source-art contract

This document is the direct prompt pack for Sora, Flux, SDXL, Ideogram, or Midjourney. Generate **one isolated source asset per image** unless a prompt explicitly requests a seamless texture. Do not request a collage, contact sheet, game screenshot, character, UI, or background plate.

The Godot kit already renders a complete procedural fallback; these exports are the final-art layer that swaps in without changing the room graph, spline corridors, lighting budget, or prop API.

---

## GLOBAL STYLE LOCK — paste into every generation prompt

> Create a professional AAA-quality 2D top-down microscopic immune-system environment for a roguelike shooter named Phagos. Produce original assets inspired by real human biology rather than existing game artwork. Every asset must use transparent PNG, clean alpha edges, soft painterly rendering with high-frequency biological details, emissive highlights, rounded organic silhouettes, and consistent 90° top-down perspective. No background, no UI, no characters, no text, no external-game imitation, no camera tilt, no isometric view, no pixel art, no cartoon outline.

### Technical lock

- Master export: **2048×2048 transparent PNG** for floor, wall, biome, prop, and decal art.
- Particle master export: **512×512 transparent PNG**.
- Directly overhead orthographic / 90° top-down view only. Do not use horizon, sidewall, drop shadow to a world plane, or perspective foreshortening.
- Use clean straight alpha. Edges must not retain white, black, or colored matte pixels outside the silhouette.
- Keep saturation restrained in tissue and high only on biological signals: emissive veins, cytokine crystals, ATP, oxygen, and synapses.
- All assets are original biology-inspired designs. Do not name, imitate, or reference any existing game or artist.
- Floor exports are **seamless transparent overlay textures**. Their left/right and top/bottom edge pixels must match exactly.
- For tools that cannot genuinely export alpha, use their transparent-background mode before export; reject a checkerboard or solid-color backdrop baked into the PNG.

### Negative prompt (append where supported)

> square dungeon room, RPG tile map, grid, brick, stone, metal hallway, isometric, side view, horizon, character, enemy, weapon, UI, text, logo, icon sheet, pixel art, cel shading, thick black outline, hard rectangular silhouette, opaque backdrop, checkerboard background, collage, contact sheet, photoreal blood gore.

### Biome color grammar

| Biome | Substrate | Important emissive signal | Readability rule |
|---|---|---|---|
| Heart | crimson, maroon, wine-red tissue | warm scarlet / rose | bright red reserved for flowing vessels and rhythmic nodes |
| Lung | cyan, teal, blue-green membrane | pale cyan / mint | mist stays low-contrast; oxygen particles carry the brightest cyan |
| Brain | violet, deep indigo, muted purple | electric blue / cyan | cyan only marks synapse activity and neural signal paths |
| Bone Marrow | ivory, soft pink, muted rose | warm cream / pale gold | ivory structure stays broad; pink signals stay sparse |

---

## Asset Pack A — seamless floor overlays (16 files)

**Goal:** non-repeating microscopic tissue substrate. These are texture overlays, not square RPG tiles.

**Base prompt:**

> Generate a seamless, tileable microscopic tissue floor overlay viewed directly from above: membrane folds, cytoplasm currents, protein gradients, soft biological noise, subtle cellular structures, and occasional dim emissive structures. The pattern must cross all four borders with no visible tile seam, no central focal object, no grid, no square-tile artifact, and no hard edge. Use the [BIOME] palette: [PALETTE]. Preserve quiet navigation readability in the center values and reserve high saturation for tiny biological signals. Export as a 2048 by 2048 transparent PNG overlay.

Generate four distinct files for each biome:

```text
biome_heart_floor_01.png … biome_heart_floor_04.png
biome_lung_floor_01.png  … biome_lung_floor_04.png
biome_brain_floor_01.png … biome_brain_floor_04.png
biome_marrow_floor_01.png … biome_marrow_floor_04.png
```

Variant direction:

- **Heart:** elastic striations, dark ventricular cytoplasm, dim crimson capillary trace.
- **Lung:** thin translucent septa, blue-green moisture pools, pale cyan diffusion haze.
- **Brain:** fine glial texture, purple neuropil, sparse cyan electrical flecks.
- **Bone Marrow:** ivory matrix grain, soft-pink hematopoietic fields, sparse round stem-cell residue.

**Acceptance check:** left/right and top/bottom borders must remain visually identical when tiled four-by-four. Run `tools/validate_assets.py --strict` after export.

---

## Asset Pack B — modular organic walls (24 files)

**Goal:** a complete rim kit that can decorate spline-extruded walls without a flat texture strip. Each source asset is an isolated, rounded piece of living tissue with five readable layers: base tissue, membrane folds, micro-cracks, vessels, and a restrained emissive highlight.

**Base prompt:**

> Generate one isolated modular organic wall piece viewed at a strict 90-degree top-down angle, made from living [BIOME] tissue. Build visible depth through concentric membrane folds, collagen ridges, hairline micro-cracks, branching biological veins, and a sparse emissive highlight. The outer silhouette is rounded and alive rather than architectural. Keep connection ends clean and aligned for seamless assembly with companion pieces. Transparent PNG only, 2048 by 2048, no floor plate, no background, no drop shadow beyond the object alpha.

Generate the following topology for each `heart`, `lung`, `brain`, and `marrow` biome:

```text
biome_[biome]_wall_straight_A.png
biome_[biome]_wall_curve_A.png
biome_[biome]_wall_t_A.png
biome_[biome]_wall_x_A.png
biome_[biome]_wall_end_cap_A.png
biome_[biome]_wall_chamber_rim_A.png
```

Topology direction:

- `straight`: continuous 192 px nominal passage-side section; organic width variation is inside the wall mass, not at the connector.
- `curve`: quarter-turn tissue rim with connector tangents matching `straight`.
- `t`: rounded three-way branch junction; no pinched center.
- `x`: soft four-way vascular junction; no square cross intersection.
- `end_cap`: bulbous closed membrane tip.
- `chamber_rim`: broad curved rim designed for 384–640 px chambers and scalable boss silhouettes.

Biome accents: Heart gets thick red elastic muscle and large vessels; Lung gets thin pale membranes and alveolar pores; Brain gets purple folds with cyan synaptic threads; Marrow gets ivory trabeculae with pink cellular cavities.

---

## Asset Pack C — emissive vein overlays

**Goal:** additive overlays, not opaque wall art. The source should contain only emissive vessel branches and their soft alpha glow.

**Prompt:**

> Generate a branching biological vein overlay seen directly from above. The image contains only thin and medium organic vessels with a bright emissive core, soft additive-ready glow, delicate bifurcations, and transparent empty space around every branch. No tissue backing, no background, no border, no object card. Use [COLOR] signal coloration while retaining subtle biological irregularity. Transparent 2048 by 2048 PNG.

Required files:

```text
biome_heart_vein_crimson_01.png … _03.png
biome_lung_vein_cyan_01.png … _03.png
biome_brain_vein_cyan_01.png … _03.png
biome_marrow_vein_crimson_01.png … _03.png
vein_cyan_generic_01.png … _02.png
```

In Godot, assign `materials/vein_pulse_default.tres` or create a palette-specific instance using `shaders/vein_pulse.gdshader`; use additive blending and a unique `phase_offset` per sprite.

---

## Asset Pack D — Lung alveoli (4 files)

**Prompt:**

> Create one isolated rounded cluster of microscopic lung alveoli viewed from directly above. Use softly translucent cyan-teal membranes, varied circular sacs, thin septa, subtle internal moisture gradients, and a delicate pale-cyan diffusion glow. The silhouette is soft and organic, never a flower, bubble icon, or regular hexagon. Transparent 2048 by 2048 PNG, no background, no characters.

```text
biome_lung_alveoli_01.png … biome_lung_alveoli_04.png
```

---

## Asset Pack E — Brain neuron network (4 files)

**Prompt:**

> Generate one isolated top-down neuron network overlay: branching dendrites, irregular neuron soma clusters, small electric-blue synapse points, and restrained purple support tissue residue. The network must be readable as a living biological path, with rounded branching and no circuit-board geometry. Transparent 2048 by 2048 PNG, no background, no text.

```text
biome_brain_neuron_network_01.png … biome_brain_neuron_network_04.png
```

---

## Asset Pack F — Bone Marrow cavities (4 files)

**Prompt:**

> Generate one isolated bone marrow cavity viewed from directly above. Include a rounded ivory trabecular rim, soft pink hematopoietic cell clusters, a few pale adipose cells, and warm cream micro-signals. Keep cavities organic, porous, and asymmetrical rather than architectural. Transparent 2048 by 2048 PNG, no background, no characters.

```text
biome_marrow_cavity_01.png … biome_marrow_cavity_04.png
```

---

## Asset Pack G — independent props (15 files)

Every file is a single centered object with 8–12% transparent safety margin. Generate three variants for each:

```text
prop_protein_01.png … _03.png
prop_cytokine_crystal_01.png … _03.png
prop_membrane_sac_01.png … _03.png
prop_calcified_chunk_01.png … _03.png
prop_atp_pool_01.png … _03.png
```

**Base prompt:**

> Generate one isolated microscopic biological environment prop viewed directly from above: [PROP TYPE]. It belongs in a AAA soft-painterly immune-system shooter environment, with high-frequency membrane detail, rounded organic silhouette, restrained biomaterial color, and only a small meaningful emissive accent. Make it readable at 16–64 px gameplay scale, while preserving 2048 px master detail. Transparent PNG, no floor patch, no cast shadow rectangle, no character or UI.

Type cues:

- **protein:** folded protein vesicle / protein cluster.
- **cytokine crystal:** translucent signalling crystal, brightest at a small internal core.
- **membrane sac:** tensioned rounded sac with a soft translucent membrane.
- **calcified chunk:** porous ivory mineral tissue, soft organic edges.
- **ATP pool:** shallow glowing biochemical energy pool, no hard circular icon rim.

`BreakableProp.break_open()` already handles debris, particle-like fragments, and glow fade. Imported assets only replace its drawing pass; do not encode combat, loot, or characters in the source art.

---

## Asset Pack H — decals (12 files)

Create three variants each:

```text
decal_scratch_01.png … _03.png
decal_membrane_tear_01.png … _03.png
decal_protein_stain_01.png … _03.png
decal_glow_residue_01.png … _03.png
```

**Prompt:**

> Generate one isolated, irregular microscopic biological decal viewed from directly above: [DECAL TYPE]. It is a subtle transparent overlay with feathered clean alpha, no rectangular background, no repeated stamp look, no text, and no black outline. Use organic asymmetry, membrane-scale detail, and palette-neutral tissue values; glow residue may use a sparse emissive [BIOME SIGNAL] fringe. Transparent 2048 by 2048 PNG.

---

## Asset Pack I — particle sprites (5 files)

Particles are deliberately small and uncluttered; high-frequency texture should survive downsampling without opaque boxes.

```text
particle_glow_orb_01.png
particle_plasma_bubble_01.png
particle_immune_dust_01.png
particle_atp_spark_01.png
particle_cytokine_mote_01.png
```

**Prompt:**

> Generate one isolated biological particle sprite, centered and viewed directly from above: [PARTICLE TYPE]. Use a compact rounded silhouette, smooth transparent falloff, clean alpha, and a tiny emissive core only if biologically meaningful. It must remain legible at 4–24 px in motion. Transparent PNG at 512 by 512, no floor, no background, no UI, no lens-flare star shape.

Runtime behavior is set by `scripts/biological_particles.gd`: slow drift, turbulence, random lifetime, ATP trails, plasma mist, cytokines, and immune dust.

---

## Naming and import contract

The canonical file list is [`assets/manifest/asset_manifest.json`](../assets/manifest/asset_manifest.json). Names must be lowercase, underscore-separated, and match exactly. Examples:

```text
biome_heart_wall_curve_A.png
biome_lung_floor_07.png
prop_protein_03.png
particle_atp_01.png
decal_membrane_tear_02.png
```

> Note: the manifest is authoritative for the currently planned production pack. The examples above remain valid naming patterns even where their ordinal is not part of this first batch.

Godot import target:

- Texture filter: linear with mipmaps for 2048 masters; particle atlas uses linear.
- Compression: lossless / VRAM compressed with alpha preserved; inspect very thin cyan vessels after compression.
- Atlas gutter: 16 px with edge extrusion, generated by `tools/atlas_assets.py`.
- Do not rotate an atlas entry; rotation changes directional lighting in top-down art.
- Use `organic_wall.gdshader` for slight imported-wall membrane movement, `vein_pulse.gdshader` for vessels, `membrane_distort.gdshader` for overlays, `cytoplasm_flow.gdshader` for procedural floor blending, and `glow.gdshader` for soft bloom-compatible signals.

---

## Style validation checklist — mandatory release gate

Run the mechanical validator first:

```bash
python3 -m pip install Pillow
python3 tools/validate_assets.py --strict --report reports/asset_validation.json
python3 tools/atlas_assets.py --page-size 8192 --padding 16
```

Then an art owner must sign off every item below at 100% and 400% zoom:

- [ ] Semua aset menggunakan perspektif top-down 90°.
- [ ] Tidak ada outline kartun atau gaya pixel art.
- [ ] Siluet organik dan membulat, tidak berbentuk kotak.
- [ ] Pencahayaan emissive konsisten per biome.
- [ ] Tekstur lantai benar-benar seamless.
- [ ] Wall kit dapat menyusun koridor melengkung tanpa celah.
- [ ] Variasi warna mengikuti biome: Heart, Lung, Brain, dan Bone Marrow.
- [ ] Semua PNG memiliki alpha bersih tanpa background.
- [ ] Asset siap di-atlas dan digunakan langsung di Godot tanpa editing manual.

Additional technical sign-off:

- [ ] Floor four-by-four preview does not reveal a repeating motif, seam, or central stamp.
- [ ] Straight/curve/T/X/end-cap/chamber-rim modules connect under Godot linear filtering with a 16 px gutter.
- [ ] Alpha halos are absent against both black and white checker previews.
- [ ] Maximum saturation is reserved for veins, crystals, ATP, oxygen, cytokines, and synapses.
- [ ] Imported assets preserve the readable 96–160 px small corridors, 192 px normal corridors, 384–640 px chambers, 896–1200 px boss chambers, and 16–64 px decor scale.
