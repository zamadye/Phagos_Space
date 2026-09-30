#!/usr/bin/env python3
"""Static acceptance checks for the clean PHAGOS skin cutaway."""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
EXPECTED_SIZE = (2048, 1152)
LAYERS = {
    "deep_tissue": "assets/arena/00_deep_tissue_backdrop.png",
    "outer_skin": "assets/arena/01_outer_skin.png",
    "fat": "assets/arena/02_fat.png",
    "muscle": "assets/arena/03_muscle.png",
    "fascia": "assets/arena/04_fascia.png",
    "inner_membrane": "assets/arena/05_inner_membrane.png",
    "lumen": "assets/arena/06_open_cavity.png",
}


def visible_pixels(image: Image.Image) -> list[tuple[int, int, int, int]]:
    return [pixel for pixel in image.convert("RGBA").resize((256, 144), Image.Resampling.BILINEAR).get_flattened_data() if pixel[3] > 16]


def main() -> int:
    errors: list[str] = []
    report: dict[str, object] = {"valid": False, "layers": {}, "palette": {}}
    for role, relative in LAYERS.items():
        path = ROOT / relative
        if not path.is_file():
            errors.append(f"missing baked layer: {relative}")
            continue
        with Image.open(path) as source:
            image = source.convert("RGBA")
            if image.size != EXPECTED_SIZE:
                errors.append(f"{relative}: expected {EXPECTED_SIZE}, got {image.size}")
            pixels = visible_pixels(image)
            coverage = len(pixels) / (256 * 144)
            report["layers"][role] = {"path": relative, "coverage": coverage, "size": list(image.size)}
            if coverage < 0.002:
                errors.append(f"{relative}: layer has no meaningful visible coverage")

    def palette_fraction(role: str, matcher: object) -> float:
        layer = report["layers"].get(role, {})
        relative = layer.get("path") if isinstance(layer, dict) else None
        if not relative:
            return 0.0
        with Image.open(ROOT / relative) as source:
            pixels = visible_pixels(source)
        return sum(1 for red, green, blue, _alpha in pixels if matcher(red, green, blue)) / max(1, len(pixels))

    palette = {
        "fat_yellow": palette_fraction("fat", lambda r, g, b: r > 120 and g > 85 and b < 100),
        "muscle_red": palette_fraction("muscle", lambda r, g, b: r > g * 1.35 and r > b * 1.35),
        "fascia_blue": palette_fraction("fascia", lambda r, g, b: b > r * 1.35 and b > g * 1.15),
    }
    report["palette"] = palette
    for role, fraction in palette.items():
        if fraction < 0.35:
            errors.append(f"{role}: positional material colour is not legible ({fraction:.1%})")

    script_path = ROOT / "scripts" / "skin_cross_section_arena.gd"
    if not script_path.is_file():
        errors.append("missing native Godot arena script")
    else:
        source = script_path.read_text(encoding="utf-8")
        for required in ("Sprite2D", "OuterSkin", "Fat", "MuscleFibers", "BlueFascia", "InnerMembrane", "OpenCavityFloor"):
            if required not in source:
                errors.append(f"arena script missing required layer contract: {required}")
        for forbidden in (
            "extends CanvasLayer",
            "CanvasLayer.new()",
            "CanvasModulate.new()",
            "GPUParticles2D.new()",
            "PointLight2D.new()",
            "func _process(",
        ):
            if forbidden in source:
                errors.append(f"arena script contains forbidden overlay/effect route: {forbidden}")
    if (ROOT / "web").exists():
        errors.append("web overlay directory must not exist in the native-only rebuild")

    report["errors"] = errors
    report["valid"] = not errors
    report_path = ROOT / "reports" / "cross_section_validation.json"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    if errors:
        print("Cross-section validation failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1
    print("Cross-section validation passed: six exposed anatomical roles, clean native Godot stack, no overlays or particles.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
