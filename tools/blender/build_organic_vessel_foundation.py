"""Build the Phase 1 organic vessel foundation in Blender.

This is intentionally separate from the retired wall-only tube generator.
The output is one authored 3D vessel section with a curved centerline,
continuous floor/ceiling/left/right walls, UVs, a Breath shape-key action,
and a native .blend source for inspection.
"""
from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "assets" / "environment" / "vessel"
ASSETS.mkdir(parents=True, exist_ok=True)
BLENDER_SOURCE_DIR = ROOT / "tools" / "blender" / "source"
BLENDER_SOURCE_DIR.mkdir(parents=True, exist_ok=True)
BLEND_PATH = BLENDER_SOURCE_DIR / "organic_vessel_foundation.blend"
GLB_PATH = ASSETS / "organic_vessel_foundation.glb"

STATIONS = 42
CROSS_SECTION = 48
LENGTH = 42.0
HALF_WIDTH = 8.4
HALF_HEIGHT = 5.8


def clear_scene() -> None:
    bpy.ops.object.mode_set(mode="OBJECT") if bpy.context.object and bpy.context.object.mode != "OBJECT" else None
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights, bpy.data.actions):
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)


def make_material() -> bpy.types.Material:
    mat = bpy.data.materials.new("OrganicVessel_Membrane")
    mat.diffuse_color = (0.115, 0.012, 0.022, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (0.115, 0.012, 0.022, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.38
        bsdf.inputs["Metallic"].default_value = 0.0
        coat = bsdf.inputs.get("Coat Weight")
        if coat:
            coat.default_value = 0.26
        coat_rough = bsdf.inputs.get("Coat Roughness")
        if coat_rough:
            coat_rough.default_value = 0.19
        spec = bsdf.inputs.get("Specular IOR Level")
        if spec:
            spec.default_value = 0.52
    return mat


def centerline(z: float) -> Vector:
    # A controlled authored curve: broad bends with a slow secondary drift,
    # not a procedural circular pipe.
    return Vector((
        math.sin(z * 0.145) * 2.4 + math.sin(z * 0.31 + 0.8) * 0.65,
        math.sin(z * 0.105 + 1.1) * 0.65 + math.sin(z * 0.22) * 0.22,
        z,
    ))


def tangent_at(z: float) -> Vector:
    before = centerline(max(0.0, z - 0.04))
    after = centerline(min(LENGTH, z + 0.04))
    return (after - before).normalized()


def build_vessel() -> bpy.types.Object:
    vertices: list[tuple[float, float, float]] = []
    faces: list[tuple[int, int, int, int]] = []

    for station in range(STATIONS):
        z = LENGTH * station / (STATIONS - 1)
        origin = centerline(z)
        tangent = tangent_at(z)
        up_reference = Vector((0.0, 1.0, 0.0))
        side = tangent.cross(up_reference).normalized()
        up = side.cross(tangent).normalized()
        for section in range(CROSS_SECTION):
            theta = math.tau * section / CROSS_SECTION
            # Three scales establish broad fascicle-like volume. The phase
            # drifts with the centerline so the cross-section never repeats.
            drift = math.sin(z * 0.27 + theta * 3.0) * 0.22 + math.sin(z * 0.61 - theta * 5.0) * 0.09
            irregular = math.sin(theta * 4.0 + z * 0.19) * 0.16 + math.sin(theta * 9.0 - z * 0.33) * 0.06
            # Broad, longitudinal fascicle folds are authored into the volume,
            # so the wall silhouette is biological even before the material is
            # applied. Small phase drift prevents a repeated pipe profile.
            fascicle_fold = math.sin(theta * 6.0 + z * 0.11) * 0.055 + math.sin(theta * 11.0 - z * 0.23) * 0.018
            fold_scale = 1.0 + fascicle_fold + drift * 0.032 + irregular * 0.018
            width = HALF_WIDTH * fold_scale
            height = HALF_HEIGHT * (1.0 + fascicle_fold * 0.78 + drift * 0.028 - irregular * 0.014)
            # A softened superellipse keeps broad floor and ceiling planes
            # readable while retaining rounded biological corners.
            profile_x = math.copysign(abs(math.cos(theta)) ** 0.64, math.cos(theta))
            profile_y = math.copysign(abs(math.sin(theta)) ** 0.64, math.sin(theta))
            radial = side * (profile_x * width) + up * (profile_y * height)
            point = origin + radial
            vertices.append(tuple(point))

    # Reverse winding for inward-facing vessel surfaces.
    for station in range(STATIONS - 1):
        for section in range(CROSS_SECTION):
            current = station * CROSS_SECTION + section
            next_section = station * CROSS_SECTION + ((section + 1) % CROSS_SECTION)
            next_station = (station + 1) * CROSS_SECTION + section
            next_both = (station + 1) * CROSS_SECTION + ((section + 1) % CROSS_SECTION)
            faces.append((current, next_section, next_both, next_station))

    mesh = bpy.data.meshes.new("OrganicVesselFoundationMesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    for poly in mesh.polygons:
        poly.use_smooth = True

    # Author longitudinal UVs for future baked tissue/blood layers.
    uv_layer = mesh.uv_layers.new(name="VesselLongitudinalUV")
    for loop in mesh.loops:
        station = loop.vertex_index // CROSS_SECTION
        section = loop.vertex_index % CROSS_SECTION
        uv_layer.data[loop.index].uv = (
            section / CROSS_SECTION,
            station / (STATIONS - 1),
        )

    wall = bpy.data.objects.new("OrganicVesselFoundation", mesh)
    bpy.context.collection.objects.link(wall)
    wall.data.materials.append(make_material())
    wall["asset_role"] = "phase_1_organic_vessel_volume"
    wall["centerline_length_m"] = LENGTH
    wall["cross_section_segments"] = CROSS_SECTION
    wall["surface_layers"] = "epimysium_perimysium_endomysium_proxy"

    basis = wall.shape_key_add(name="Basis")
    breath = wall.shape_key_add(name="Breath")
    for index, key_vertex in enumerate(breath.data):
        base = Vector(basis.data[index].co)
        station = index // CROSS_SECTION
        section = index % CROSS_SECTION
        z = LENGTH * station / (STATIONS - 1)
        theta = math.tau * section / CROSS_SECTION
        factor = 1.0 + 0.032 + 0.012 * math.sin(z * 0.44 + theta * 3.0)
        key_vertex.co = (base.x * factor, base.y * factor, base.z * factor if False else base.z)

    breath.value = 0.0
    breath.keyframe_insert(data_path="value", frame=1)
    breath.value = 1.0
    breath.keyframe_insert(data_path="value", frame=48)
    breath.value = 0.22
    breath.keyframe_insert(data_path="value", frame=72)
    breath.value = 1.0
    breath.keyframe_insert(data_path="value", frame=96)
    breath.value = 0.0
    breath.keyframe_insert(data_path="value", frame=144)
    if wall.data.shape_keys and wall.data.shape_keys.animation_data and wall.data.shape_keys.animation_data.action:
        wall.data.shape_keys.animation_data.action.name = "OrganicVessel_Breathing"
    return wall


def export_glb(wall: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    wall.select_set(True)
    bpy.context.view_layer.objects.active = wall
    bpy.ops.export_scene.gltf(
        filepath=str(GLB_PATH),
        export_format="GLB",
        use_selection=True,
        export_animations=True,
        export_morph=True,
        export_materials="EXPORT",
        export_apply=False,
    )
    print(f"BLENDER_VESSEL_GLB {GLB_PATH} {GLB_PATH.stat().st_size} bytes")


def main() -> None:
    bpy.ops.preferences.addon_enable(module="io_scene_gltf2")
    clear_scene()
    wall = build_vessel()
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))
    print(f"BLENDER_VESSEL_BLEND {BLEND_PATH} {BLEND_PATH.stat().st_size} bytes")
    export_glb(wall)
    print(f"BLENDER_VESSEL_READY length={LENGTH}; stations={STATIONS}; cross_section={CROSS_SECTION}; animation=OrganicVessel_Breathing")


if __name__ == "__main__":
    main()
