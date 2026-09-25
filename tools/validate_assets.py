#!/usr/bin/env python3
"""Validate Phagos source art before atlas import.

The validator checks the mechanical rules that are safe to automate: file name/path,
PNG format, master resolution, alpha availability, and floor edge continuity. Perspective,
biological readability, palette intent, and wall connectivity remain an explicit art-review
step; they are surfaced in the JSON report rather than faked by an unreliable classifier.

Examples:
  python3 tools/validate_assets.py
  python3 tools/validate_assets.py --strict --report reports/asset_validation.json
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

try:
    from PIL import Image
except ImportError:  # pragma: no cover - useful on fresh art workstations
    print("Pillow is required: python3 -m pip install Pillow", file=sys.stderr)
    raise SystemExit(2)

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MANIFEST = ROOT / "assets/manifest/asset_manifest.json"


def mean_edge_difference(image: Image.Image, axis: str) -> float:
    """Mean RGBA channel difference between opposite tile edges."""
    rgba = image.convert("RGBA")
    width, height = rgba.size
    if axis == "horizontal":
        a = list(rgba.crop((0, 0, 1, height)).getdata())
        b = list(rgba.crop((width - 1, 0, width, height)).getdata())
    else:
        a = list(rgba.crop((0, 0, width, 1)).getdata())
        b = list(rgba.crop((0, height - 1, width, height)).getdata())
    if not a:
        return 0.0
    total = sum(sum(abs(left[channel] - right[channel]) for channel in range(4)) for left, right in zip(a, b))
    return total / (len(a) * 4)


def validate_item(item: dict[str, Any]) -> dict[str, Any]:
    relative_path = item["path"]
    path = ROOT / relative_path
    result: dict[str, Any] = {
        "path": relative_path,
        "category": item.get("category", "unknown"),
        "state": "pass",
        "errors": [],
        "warnings": [],
        "metrics": {},
    }
    if not path.exists():
        result["state"] = "missing"
        result["errors"].append("Source PNG has not been imported yet.")
        return result
    if path.suffix.lower() != ".png":
        result["state"] = "fail"
        result["errors"].append("Asset must be a .png file.")
        return result

    try:
        with Image.open(path) as image:
            image.load()
            result["metrics"]["format"] = image.format
            result["metrics"]["mode"] = image.mode
            result["metrics"]["size"] = list(image.size)
            if image.format != "PNG":
                result["errors"].append("File extension is PNG but encoded format is not PNG.")
            expected_size = (int(item["width"]), int(item["height"]))
            if image.size != expected_size:
                result["errors"].append(f"Expected master {expected_size[0]}×{expected_size[1]}, got {image.size[0]}×{image.size[1]}.")
            if item.get("requires_alpha", False):
                if "A" not in image.getbands():
                    result["errors"].append("Missing alpha channel; transparent PNG is required.")
                else:
                    alpha = image.getchannel("A")
                    low, high = alpha.getextrema()
                    result["metrics"]["alpha_range"] = [low, high]
                    if high == 0:
                        result["errors"].append("Alpha channel is fully transparent (empty asset).")
                    if low == 255:
                        result["warnings"].append("Alpha is fully opaque; confirm no baked background remains.")
                    # Transparent RGB halos are often caused by a non-clean matte. This is
                    # intentionally a warning because pre-multiplied source workflows vary.
                    rgba = image.convert("RGBA")
                    corners = [rgba.getpixel(point) for point in [(0, 0), (rgba.width - 1, 0), (0, rgba.height - 1), (rgba.width - 1, rgba.height - 1)]]
                    result["metrics"]["corner_alpha"] = [pixel[3] for pixel in corners]
            if item.get("seamless", False):
                horizontal = mean_edge_difference(image, "horizontal")
                vertical = mean_edge_difference(image, "vertical")
                result["metrics"]["seam_delta_horizontal"] = round(horizontal, 3)
                result["metrics"]["seam_delta_vertical"] = round(vertical, 3)
                # A continuous texture can have a small painterly variance at the edge;
                # >18/255 should be inspected before import.
                if max(horizontal, vertical) > 18.0:
                    result["errors"].append("Floor edge mismatch is too high for a seamless texture.")
    except Exception as exc:  # noqa: BLE001 - report bad artist exports without crashing batch
        result["errors"].append(f"Unable to inspect image: {exc}")

    if result["errors"]:
        result["state"] = "fail"
    elif result["warnings"]:
        result["state"] = "review"
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate Phagos source asset exports.")
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST, help="Manifest JSON (default: assets/manifest/asset_manifest.json).")
    parser.add_argument("--strict", action="store_true", help="Return non-zero if a required source asset is missing or invalid.")
    parser.add_argument("--report", type=Path, help="Optional output JSON report path.")
    args = parser.parse_args()
    manifest_path = args.manifest if args.manifest.is_absolute() else ROOT / args.manifest
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    results = [validate_item(item) for item in manifest["assets"]]
    counts: dict[str, int] = {}
    for result in results:
        counts[result["state"]] = counts.get(result["state"], 0) + 1
    report = {
        "manifest": str(manifest_path.relative_to(ROOT)),
        "summary": counts,
        "manual_review": [
            "All assets are rendered from a 90-degree top-down perspective.",
            "No cartoon outline, pixel-art treatment, square silhouette, UI, character, or background is present.",
            "Emissive accents are consistent with the assigned biome while high saturation remains reserved for signals.",
            "Wall edges connect with the named straight / curve / T / X / end-cap / chamber-rim kit without seams.",
            "Each transparent alpha edge is clean at 100% and 400% zoom, including zero-RGB fringe cleanup when required by the target renderer.",
            "Assets pack into the atlas with the importer padding described in docs/ASSET_GENERATION_PROMPTS.md.",
        ],
        "results": results,
    }
    print(f"Asset validation: {len(results)} spec(s) — " + ", ".join(f"{key}={value}" for key, value in sorted(counts.items())))
    for result in results:
        if result["state"] in {"missing", "fail"}:
            print(f"[{result['state'].upper()}] {result['path']}: {'; '.join(result['errors'])}")
    if args.report:
        report_path = args.report if args.report.is_absolute() else ROOT / args.report
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        try:
            display_path = report_path.relative_to(ROOT)
        except ValueError:
            display_path = report_path
        print(f"Wrote report: {display_path}")
    failed = counts.get("missing", 0) + counts.get("fail", 0)
    return 1 if args.strict and failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
