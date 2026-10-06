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
BLENDER_SOURCE_DIR = ROOT / "tools" / "blender" / "source"
BLENDER_SOURCE_DIR.mkdir(parents=True, exist_ok=True)
BLEND_SOURCE = BLENDER_SOURCE_DIR / "vessel_wall_breathing.blend"


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
            # Broad wandering membrane folds provide volume under the
            # authored ridges. Their phase drifts along the vessel instead of
            # repeating as transverse rings or a regular helix.
            phase_drift = math.sin(z * 0.23) * 0.72 + math.sin(z * 0.51 + 1.4) * 0.34
            fold = (
                0.38 * math.sin(angle * 3.0 + z * 0.18 + phase_drift)
                + 0.16 * math.sin(angle * 7.0 - z * 0.37 + math.sin(z * 0.27) * 0.5)
                + 0.07 * math.sin(angle * 11.0 + z * 0.73 + math.sin(z * 0.14))
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
    wall_material = material("VesselMembraneGlossy", (0.20, 0.006, 0.018, 1.0), roughness=0.32, emission=(0.035, 0.001, 0.004, 1.0))
    principled = wall_material.node_tree.nodes.get("Principled BSDF")
    if principled is not None:
        for socket_name, value in (("Specular IOR Level", 0.62), ("Coat Weight", 0.28), ("Coat Roughness", 0.20)):
            socket = principled.inputs.get(socket_name)
            if socket is not None:
                socket.default_value = value
    wall = add_mesh_object(name, vertices, faces, wall_material)

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

    # Folds support the membrane; they stay one shade family darker so the
    # authored silhouette does not turn into a stack of glowing red wires.
    ridge_mat = material("VesselMuscleFold", (0.19, 0.006, 0.018, 1.0), roughness=0.46, emission=(0.014, 0.001, 0.002, 1.0))
    fiber_mat = material("VesselFiber", (0.27, 0.010, 0.030, 1.0), roughness=0.52, emission=(0.018, 0.001, 0.003, 1.0))

    def add_helical_ridge(object_name: str, ridge_index: int, tube_radius: float, material_slot):
        angle_offset = 2.0 * math.pi * ridge_index / 7.0
        ridge_vertices = []
        ridge_faces = []
        tube_sides = 8
        points = 18
        for point_index in range(points):
            z = length * point_index / (points - 1)
            angle = angle_offset + z * (0.075 + (ridge_index % 3) * 0.018) + math.sin(z * 0.43 + ridge_index) * 0.08
            local_radius = radius - 0.12 + math.sin(z * 0.62 + ridge_index * 1.7) * 0.08
            center = Vector((local_radius * math.cos(angle), local_radius * math.sin(angle), z))
            radial = Vector((math.cos(angle), math.sin(angle), 0.0))
            for side in range(tube_sides):
                around = 2.0 * math.pi * side / tube_sides
                offset = radial * math.cos(around) * tube_radius + Vector((0.0, 0.0, math.sin(around) * tube_radius))
                ridge_vertices.append(tuple(center + offset))
        for point_index in range(points - 1):
            for side in range(tube_sides):
                current = point_index * tube_sides + side
                next_side = point_index * tube_sides + ((side + 1) % tube_sides)
                next_point = (point_index + 1) * tube_sides + side
                next_both = (point_index + 1) * tube_sides + ((side + 1) % tube_sides)
                ridge_faces.extend(((current, next_point, next_side), (next_side, next_point, next_both)))
        ridge = add_mesh_object(object_name, ridge_vertices, ridge_faces, material_slot)
        for poly in ridge.data.polygons:
            poly.use_smooth = True

    # Broad longitudinal muscle folds preserve a soft, fleshy silhouette.
    # They are not transverse rings, so repeated modules read as one breathing
    # vessel rather than a stack of mechanical hoops.
    for fold_index in range(7):
        add_helical_ridge(f"VesselMuscleFold_{fold_index:02d}", fold_index, 0.13 + (fold_index % 3) * 0.035, ridge_mat)

    # Fine fixed fibers remain authored detail; no texture or UV time offset is
    # used to fake motion along the wall.
    for fiber_index in range(10):
        add_helical_ridge(f"VesselFiber_{fiber_index:02d}", fiber_index + 7, 0.038 + (fiber_index % 3) * 0.012, fiber_mat)

    spot_materials = [
        material("WallVirus_Maroon", (0.42, 0.008, 0.030, 1.0), roughness=0.28, emission=(0.12, 0.001, 0.008, 1.0)),
        material("WallVirus_Violet", (0.24, 0.025, 0.22, 1.0), roughness=0.30, emission=(0.08, 0.004, 0.10, 1.0)),
        material("WallVirus_Amber", (0.72, 0.22, 0.035, 1.0), roughness=0.25, emission=(0.20, 0.035, 0.004, 1.0)),
        material("WallVirus_Cyan", (0.025, 0.30, 0.42, 1.0), roughness=0.28, emission=(0.008, 0.08, 0.14, 1.0)),
    ]
    spot_specs = [
        (0, 1.3, 0.25, 0.72), (1, 3.8, 2.15, 0.45), (2, 5.2, 4.5, 0.62),
        (3, 7.6, 5.8, 0.38), (0, 8.9, 1.4, 0.54), (1, 10.4, 3.4, 0.82),
        (2, 2.4, 5.35, 0.32), (3, 6.4, 0.8, 0.50), (0, 11.2, 4.8, 0.66),
    ]
    for spot_index, (palette_index, z, angle, size) in enumerate(spot_specs):
        normal = Vector((math.cos(angle), math.sin(angle), 0.0))
        center = normal * (radius - 0.58) + Vector((0.0, 0.0, z))
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.62, location=center)
        spot = bpy.context.object
        spot.name = f"WallVirusSpot_{spot_index:02d}"
        # Local Z is the authored outward normal. Keeping the socket oriented
        # to the cylindrical membrane makes child cores, halos, and spikes
        # read as raised growths instead of flat decals.
        spot.rotation_mode = "QUATERNION"
        spot.rotation_quaternion = Vector((0.0, 0.0, 1.0)).rotation_difference(normal)
        spot.scale = (size * 1.18, size * (0.62 + (spot_index % 3) * 0.11), size * 0.86)
        spot.data.materials.append(spot_materials[palette_index])
        spot["role"] = "wall_enemy_socket"
        spot["palette_index"] = palette_index
        spot["base_size"] = size
        spot["health"] = 1.0
        for poly in spot.data.polygons:
            poly.use_smooth = True
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.19 + (spot_index % 2) * 0.04, location=center + normal * 0.48)
        core = bpy.context.object
        core.name = f"WallVirusSpot_{spot_index:02d}_Core"
        core.data.materials.append(spot_materials[palette_index])
        core.scale = (1.0, 0.72, 0.82)
        core.parent = spot
        core.location = (0.0, 0.0, 0.48)
        for poly in core.data.polygons:
            poly.use_smooth = True

        # Authored irregular enemy silhouette: short biological spikes and a
        # membrane halo travel with the spot and disappear with its parent in
        # the Godot damage wrapper. These are real Blender mesh children, not
        # runtime primitives.
        spike_color = tuple(max(channel * 0.42, 0.008) for channel in spot_materials[palette_index].diffuse_color[:3]) + (1.0,)
        spike_material = material(
            f"WallVirus_{spot_index:02d}_Spike",
            spike_color,
            metallic=0.0,
            roughness=0.24,
            emission=(spike_color[0] * 0.50, spike_color[1] * 0.50, spike_color[2] * 0.50, 1.0),
        )
        for spike_index in range(5 + (spot_index % 3)):
            spike_angle = 2.0 * math.pi * spike_index / float(5 + (spot_index % 3)) + spot_index * 0.37
            direction = Vector((math.cos(spike_angle) * 0.24, math.sin(spike_angle) * 0.24, 0.62)).normalized()
            bpy.ops.mesh.primitive_cone_add(
                vertices=7,
                radius1=0.085 + (spike_index % 2) * 0.018,
                radius2=0.012,
                depth=0.42 + (spot_index % 3) * 0.07,
                location=(0.0, 0.0, 0.0),
            )
            spike = bpy.context.object
            spike.name = f"WallVirusSpot_{spot_index:02d}_Spike_{spike_index:02d}"
            spike.data.materials.append(spike_material)
            spike.parent = spot
            spike.location = Vector((math.cos(spike_angle) * 0.27, math.sin(spike_angle) * 0.27, 0.22))
            spike.rotation_mode = "QUATERNION"
            spike.rotation_quaternion = Vector((0.0, 0.0, 1.0)).rotation_difference(direction)
            for poly in spike.data.polygons:
                poly.use_smooth = True

        halo_material = material(
            f"WallVirus_{spot_index:02d}_Halo",
            (spike_color[0], spike_color[1], spike_color[2], 1.0),
            metallic=0.0,
            roughness=0.18,
            emission=(spike_color[0] * 0.75, spike_color[1] * 0.75, spike_color[2] * 0.75, 1.0),
        )
        bpy.ops.mesh.primitive_torus_add(
            major_radius=0.56,
            minor_radius=0.035,
            major_segments=24,
            minor_segments=6,
            location=(0.0, 0.0, 0.0),
        )
        halo = bpy.context.object
        halo.name = f"WallVirusSpot_{spot_index:02d}_Halo"
        halo.data.materials.append(halo_material)
        halo.parent = spot
        halo.location = (0.0, 0.0, 0.20)
        halo.rotation_euler = (0.0, 0.0, 0.0)
        for poly in halo.data.polygons:
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
    # Keep a real Blender source file beside the interchange GLB. The .blend
    # contains the membrane mesh, materials, socket hierarchy, and authored
    # shape-key action; GLB is only the Godot delivery export.
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_SOURCE))
    print(f"BLENDER_SOURCE {BLEND_SOURCE} {BLEND_SOURCE.stat().st_size} bytes")
    export_selected(ASSETS / "vessel_wall_breathing.glb")

    clear_scene()
    build_pathogen()
    export_selected(ASSETS / "pathogen_emergence.glb")
    print(f"BLENDER_READY {bpy.app.version_string}")


if __name__ == "__main__":
    main()
