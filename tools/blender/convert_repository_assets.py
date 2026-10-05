"""Convert repository FBX/OBJ biological sources to additive GLB scenes.

The source archives are never edited. Outputs are new Godot-ready visual
scenes and retain their imported mesh/material data as far as the source
format provides it.
"""
from __future__ import annotations

import shutil
import tempfile
import zipfile
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "assets"


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def export_scene(output: Path) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    for obj in bpy.context.scene.objects:
        obj.select_set(True)
    bpy.ops.export_scene.gltf(
        filepath=str(output),
        export_format="GLB",
        use_selection=True,
        export_animations=True,
        export_materials="EXPORT",
        export_apply=False,
    )
    print(f"REPOSITORY_ASSET_EXPORT {output} {output.stat().st_size} bytes")


def convert_fbx(source_zip: Path, source_name: str, output_name: str) -> None:
    with tempfile.TemporaryDirectory(prefix="phagos_fbx_") as temp:
        temp_path = Path(temp)
        with zipfile.ZipFile(source_zip) as archive:
            archive.extractall(temp_path)
        source = next(temp_path.rglob(source_name))
        clear_scene()
        bpy.ops.import_scene.fbx(filepath=str(source), automatic_bone_orientation=True)
        export_scene(ASSETS / output_name)


def convert_nested_obj(source_zip: Path, nested_name: str, obj_name: str, output_name: str) -> None:
    with tempfile.TemporaryDirectory(prefix="phagos_obj_") as temp:
        temp_path = Path(temp)
        with zipfile.ZipFile(source_zip) as outer:
            nested_target = temp_path / "nested.zip"
            with outer.open(nested_name) as source, nested_target.open("wb") as target:
                shutil.copyfileobj(source, target)
        with zipfile.ZipFile(nested_target) as nested:
            nested.extractall(temp_path / "obj")
        source = next((temp_path / "obj").rglob(obj_name))
        clear_scene()
        bpy.ops.wm.obj_import(filepath=str(source), forward_axis="NEGATIVE_Z", up_axis="Y")
        export_scene(ASSETS / output_name)


def main() -> None:
    bpy.ops.preferences.addon_enable(module="io_scene_gltf2")
    convert_fbx(ROOT / "lynphocyte.zip", "Lynphocyte.fbx", "lynphocyte.glb")
    convert_nested_obj(ROOT / "white-blood-cell-development-metamyelocyte.zip", "source/neutrophil.zip", "metamyelocyte.obj", "metamyelocyte.glb")
    convert_nested_obj(ROOT / "white-blood-cell-development-mylocyte.zip", "source/neutrophil.zip", "myelocyte.obj", "myelocyte.glb")
    print(f"REPOSITORY_ASSET_CONVERSION_READY {bpy.app.version_string}")


if __name__ == "__main__":
    main()
