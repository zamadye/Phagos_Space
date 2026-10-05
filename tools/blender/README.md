# Blender biological asset pipeline

Tanggal validasi: **2026-10-05**

Sandbox Blender runtime sudah terpasang dan berhasil digunakan melalui paket `bpy`:

```text
Blender Python API: 5.0.1
background mode: True
```

Runtime ini berada di `.local/blender_python` dan sengaja di-ignore karena merupakan toolchain lokal, bukan dependency game. Bootstrap yang dapat diulang:

```bash
tools/blender/bootstrap_bpy.sh
```

Wrapper yang dipakai:

```bash
tools/blender/run_bpy.sh tools/blender/build_biological_assets.py
```

## Asset yang dibangun

Script membuat asset additive, tanpa membuka atau mengubah GLB player/enemy repository:

| Output | Isi | Animation clip |
|---|---|---|
| `assets/vessel_wall_breathing.glb` | Modular inner vessel wall, organic folds, helical fibers, membrane shape key | `VesselWall_Breathing` |
| `assets/pathogen_emergence.glb` | Pathogen core, glow core, 12 biological spikes | `Pathogen_EmergeFromWall` |

Hasil export dan import dua arah sudah diverifikasi melalui Blender. Godot juga berhasil mengimpor kedua GLB dan menemukan `AnimationPlayer` serta clip masing-masing.

## Runtime integration

- Wall tile dipasang sepanjang main route dan branch route.
- Wall menggunakan `VesselWall_Breathing` dalam loop; material tidak melakukan UV scrolling.
- Player tidak mengubah atau meretopology GLB player.
- Pathogen authored asset dipakai oleh hazard wrapper.
- Hazard memiliki mode spawn `road`, `wall_left`, dan `wall_right`.
- Untuk mode wall, collision/visual bergerak dari membrane wall ke lane jalan menggunakan interpolation gameplay; animasi mesh pathogen tetap berasal dari Blender.

Repository asset conversion juga tersedia:

```bash
tools/blender/run_bpy.sh tools/blender/convert_repository_assets.py
```

Script ini membuat GLB additive dari source yang sudah ada di repository:

```text
lynphocyte.zip → assets/lynphocyte.glb
metamyelocyte source → assets/metamyelocyte.glb
myelocyte source → assets/myelocyte.glb
```

Ketiga output tersebut sekarang dipakai sebagai visual blood-cell actors. Source archive/FBX/OBJ tidak diubah.

Semua transform placement, collision, route selection, AI behavior, dan VFX tetap berada di Godot wrapper layer.
