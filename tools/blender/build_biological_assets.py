"""Build authored biological environment assets with Blender's Python API.

Run through tools/blender/run_bpy.sh. The existing gameplay GLBs are never
opened or modified; these are additive environment/enemy wrapper assets.
"""
from __future__ import annotations

import math
import os
import sys
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "assets"
ASSETS.mkdir(parents=True, exist_ok=True)


def clear_scene() -> None:
    bpy.ops.object.mode_set(mode="OBJECT") if bpy.context.object and bpy.context.object.mode != "OBJECT" else None
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights, bpy.data.actions):
        # Keep Blender's built-in data handling simple; unused data is harmless
        # during this one-shot build.
        pass


def material(name: str, color: tuple[float, float, float, float], metallic=0.0, roughness=0.58, emission=None):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    principled = mat.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = color
    principled.inputs["Metallic"].default_value = metallic
    principled.inputs["Roughness"].default_value = roughness
    if emission:
        principled.inputs["Emission Color"].default_value = emission
        principled.inputs["Emission Strength"].default_value = 1.3
    return mat


def add_mesh_object(name: str, vertices, faces, mat):
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    for poly in mesh.polygons:
        poly.use_smooth = True
    return obj


def build_wall_mesh():
    name = "VesselWallBreathing"
    rings = 18
    slices = 64
    length = 12.0
    radius = 15.0
    vertices = []
    faces = []
    for ring in range(rings + 1):
        z = length * ring / rings
        for slice_index in range(slices):
            angle = 2.0 * math.pi * slice_index / slices
            fold = (
                0.30 * math.sin(angle * 5.0 + z * 0.25)
                + 0.12 * math.sin(angle * 13.0 - z * 0.55)
                + 0.06 * math.sin(angle * 23.0 + z * 1.10)
            )
            radial = radius + fold
            vertices.append((radial * math.cos(angle), radial * math.sin(angle), z))
    # Reverse winding so the authored asset is an inward-facing tube.
    for ring in range(rings):
        for slice_index in range(slices):
            current = ring * slices + slice_index
            next_slice = ring * slices + ((slice_index + 1) % slices)
            next_ring = (ring + 1) * slices + slice_index
            next_both = (ring + 1) * slices + ((slice_index + 1) % slices)
            faces.extend(((current, next_ring, next_slice), (next_slice, next_ring, next_both)))
    wall = add_mesh_object(name, vertices, faces, material("VesselMembrane", (0.36, 0.018, 0.035, 1.0), roughness=0.72))

    basis = wall.shape_key_add(name="Basis")
    breath = wall.shape_key_add(name="Breath")
    for index, vertex in enumerate(breath.data):
        base = Vector(basis.data[index].co)
        factor = 1.0 + 0.035 + 0.012 * math.sin(base.z * 0.75 + math.atan2(base.y, base.x) * 4.0)
        vertex.co = (base.x * factor, base.y * factor, base.z)
    breath.value = 0.0
    breath.keyframe_insert(data_path="value", frame=1)
    breath.value = 1.0
    breath.keyframe_insert(data_path="value", frame=48)
    breath.value = 0.18
    breath.keyframe_insert(data_path="value", frame=72)
    breath.value = 1.0
    breath.keyframe_insert(data_path="value", frame=96)
    breath.value = 0.0
    breath.keyframe_insert(data_path="value", frame=144)

    # Make the breathing clip loop in Blender and in glTF consumers that honor
    # the exported action range.
    if wall.data.shape_keys and wall.data.shape_keys.animation_data and wall.data.shape_keys.animation_data.action:
        # Blender 5 stores action curves in layered slots; default keyframe
        # interpolation is already suitable for a breathing loop.
        action = wall.data.shape_keys.animation_data.action
        action.name = "VesselWall_Breathing"

    ridge_mat = material("VesselFoldHighlight", (0.42, 0.018, 0.045, 1.0), roughness=0.68, emission=(0.06, 0.002, 0.006, 1.0))
    fiber_mat = material("VesselFiber", (0.54, 0.032, 0.065, 1.0), roughness=0.62, emission=(0.08, 0.004, 0.008, 1.0))

    # Broad transverse folds provide authored silhouette detail without
    # destroying the modular tile's clean ends.
    for fold_index in range(3):
        z = 1.2 + fold_index * 4.1
        bpy.ops.mesh.primitive_torus_add(major_radius=15.03, minor_radius=0.10 + (fold_index % 2) * 0.05, major_segments=64, minor_segments=8, location=(0.0, 0.0, z))
        torus = bpy.context.object
        torus.name = f"VesselFold_{fold_index:02d}"
        torus.data.materials.append(ridge_mat)
        for poly in torus.data.polygons:
            poly.use_smooth = True

    # Fine helical fibers are fixed to the wall; they do not scroll along the
    # tunnel. Their only motion comes from the wall's breathing morph.
    for fiber_index in range(5):
        angle_offset = 2.0 * math.pi * fiber_index / 5.0
        fiber_vertices = []
        fiber_faces = []
        tube_sides = 6
        points = 12
        tube_radius = 0.055 + (fiber_index % 3) * 0.018
        for point_index in range(points):
            z = length * point_index / (points - 1)
            angle = angle_offset + z * (0.10 + (fiber_index % 2) * 0.035)
            center = Vector(((radius - 0.18) * math.cos(angle), (radius - 0.18) * math.sin(angle), z))
            radial = Vector((math.cos(angle), math.sin(angle), 0.0))
            tangent = Vector((-math.sin(angle), math.cos(angle), 0.0))
            for side in range(tube_sides):
                a = 2.0 * math.pi * side / tube_sides
                offset = radial * math.cos(a) * tube_radius + Vector((0.0, 0.0, math.sin(a) * tube_radius))
                fiber_vertices.append(tuple(center + offset))
        for point_index in range(points - 1):
            for side in range(tube_sides):
                current = point_index * tube_sides + side
                next_side = point_index * tube_sides + ((side + 1) % tube_sides)
                next_point = (point_index + 1) * tube_sides + side
                next_both = (point_index + 1) * tube_sides + ((side + 1) % tube_sides)
                fiber_faces.extend(((current, next_point, next_side), (next_side, next_point, next_both)))
        fiber = add_mesh_object(f"VesselFiber_{fiber_index:02d}", fiber_vertices, fiber_faces, fiber_mat)
        for poly in fiber.data.polygons:
            poly.use_smooth = True

    return wall


def build_pathogen():
    root = bpy.data.objects.new("PathogenEmergence", None)
    bpy.context.collection.objects.link(root)
    root.location = (0.0, 0.0, 0.0)

    shell_mat = material("PathogenShell", (0.80, 0.018, 0.06, 1.0), roughness=0.40, emission=(0.18, 0.002, 0.008, 1.0))
    spike_mat = material("PathogenSpike", (0.18, 0.006, 0.025, 1.0), roughness=0.46)
    glow_mat = material("PathogenCore", (1.0, 0.43, 0.05, 1.0), roughness=0.28, emission=(1.0, 0.12, 0.015, 1.0))

    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=0.78, location=(0.0, 0.0, 0.15))
    core = bpy.context.object
    core.name = "PathogenCore"
    core.data.materials.append(shell_mat)
    core.parent = root
    for poly in core.data.polygons:
        poly.use_smooth = True

    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.26, location=(0.0, 0.0, 0.74))
    glow = bpy.context.object
    glow.name = "PathogenGlowCore"
    glow.data.materials.append(glow_mat)
    glow.parent = root
    for poly in glow.data.polygons:
        poly.use_smooth = True

    for index in range(12):
        angle = 2.0 * math.pi * index / 12.0
        tilt = 0.32 + 0.06 * math.sin(index * 2.3)
        direction = Vector((math.cos(angle) * math.cos(tilt), math.sin(angle) * math.cos(tilt), math.sin(tilt)))
        start = direction * 0.62
        end = direction * 1.42
        midpoint = (start + end) * 0.5
        vector = end - start
        bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.15, radius2=0.035, depth=vector.length, location=midpoint)
        spike = bpy.context.object
        spike.name = f"PathogenSpike_{index:02d}"
        spike.data.materials.append(spike_mat)
        spike.parent = root
        spike.rotation_mode = "QUATERNION"
        spike.rotation_quaternion = Vector((0.0, 0.0, 1.0)).rotation_difference(vector.normalized())
        for poly in spike.data.polygons:
            poly.use_smooth = True

    root.scale = (0.01, 0.01, 0.01)
    root.keyframe_insert(data_path="scale", frame=1)
    root.scale = (1.0, 1.0, 1.0)
    root.keyframe_insert(data_path="scale", frame=24)
    root.scale = (1.07, 0.96, 1.04)
    root.keyframe_insert(data_path="scale", frame=48)
    root.scale = (1.0, 1.0, 1.0)
    root.keyframe_insert(data_path="scale", frame=72)
    root.scale = (0.01, 0.01, 0.01)
    root.keyframe_insert(data_path="scale", frame=96)
    if root.animation_data and root.animation_data.action:
        action = root.animation_data.action
        action.name = "Pathogen_EmergeFromWall"
    return root


def export_selected(path: Path):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in bpy.context.scene.objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = bpy.context.scene.objects[0] if bpy.context.scene.objects else None
    bpy.ops.export_scene.gltf(
        filepath=str(path),
        export_format="GLB",
        use_selection=True,
        export_animations=True,
        export_morph=True,
        export_materials="EXPORT",
        export_apply=False,
    )
    print(f"BLENDER_EXPORT {path} {path.stat().st_size} bytes")


def main():
    bpy.ops.preferences.addon_enable(module="io_scene_gltf2")
    clear_scene()
    wall = build_wall_mesh()
    bpy.context.view_layer.objects.active = wall
    wall.select_set(True)
    export_selected(ASSETS / "vessel_wall_breathing.glb")

    clear_scene()
    build_pathogen()
    export_selected(ASSETS / "pathogen_emergence.glb")
    print(f"BLENDER_READY {bpy.app.version_string}")


if __name__ == "__main__":
    main()
