#!/usr/bin/env python3
"""Pack validated Phagos PNG source art into padded atlas pages.

The tool does not rotate sprites (important for 90° top-down lighting) and writes a JSON
map consumable by a Godot import/build step. Run validation with --strict first.

Example:
  python3 tools/atlas_assets.py --category prop --padding 16
"""
from __future__ import annotations

import argparse
import json
import math
from collections import defaultdict
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    raise SystemExit("Pillow is required: python3 -m pip install Pillow")

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "assets/manifest/asset_manifest.json"


def pack_category(items: list[dict], output: Path, page_size: int, padding: int) -> None:
    """Simple deterministic shelf packing; predictable layouts aid review and cache diffs."""
    source_items = []
    for item in items:
        path = ROOT / item["path"]
        if not path.exists():
            continue
        image = Image.open(path).convert("RGBA")
        source_items.append((item, image))
    source_items.sort(key=lambda entry: (-entry[1].height, entry[0]["path"]))
    if not source_items:
        print(f"Skipping {items[0]['category']}: no imported PNGs.")
        return

    pages: list[Image.Image] = []
    maps: list[dict] = []
    page = Image.new("RGBA", (page_size, page_size), (0, 0, 0, 0))
    page_index = 0
    cursor_x = padding
    cursor_y = padding
    shelf_height = 0
    page_map: dict[str, dict] = {}

    def flush_page() -> None:
        nonlocal page, page_index, cursor_x, cursor_y, shelf_height, page_map
        pages.append(page)
        maps.append(page_map)
        page_index += 1
        page = Image.new("RGBA", (page_size, page_size), (0, 0, 0, 0))
        cursor_x = padding
        cursor_y = padding
        shelf_height = 0
        page_map = {}

    for item, image in source_items:
        width, height = image.size
        required_w = width + padding * 2
        required_h = height + padding * 2
        if required_w > page_size or required_h > page_size:
            raise ValueError(f"{item['path']} ({width}×{height}) exceeds page {page_size} with {padding}px padding")
        if cursor_x + required_w > page_size:
            cursor_x = padding
            cursor_y += shelf_height
            shelf_height = 0
        if cursor_y + required_h > page_size:
            flush_page()
        # Edge extrusion guards linear filtering at the atlas border without modifying art.
        x, y = cursor_x + padding, cursor_y + padding
        page.alpha_composite(image, (x, y))
        if padding:
            left = image.crop((0, 0, 1, height)).resize((padding, height))
            right = image.crop((width - 1, 0, width, height)).resize((padding, height))
            top = image.crop((0, 0, width, 1)).resize((width, padding))
            bottom = image.crop((0, height - 1, width, height)).resize((width, padding))
            page.alpha_composite(left, (x - padding, y))
            page.alpha_composite(right, (x + width, y))
            page.alpha_composite(top, (x, y - padding))
            page.alpha_composite(bottom, (x, y + height))
        page_map[item["path"]] = {
            "page": page_index,
            "region": [x, y, width, height],
            "uv": [round(x / page_size, 8), round(y / page_size, 8), round(width / page_size, 8), round(height / page_size, 8)],
        }
        cursor_x += required_w
        shelf_height = max(shelf_height, required_h)
    flush_page()

    output.mkdir(parents=True, exist_ok=True)
    atlas_map: dict[str, dict] = {}
    for index, atlas_page in enumerate(pages):
        atlas_name = f"{items[0]['category']}_atlas_{index:02d}.png"
        atlas_page.save(output / atlas_name, optimize=True)
        atlas_map.update(maps[index])
    (output / f"{items[0]['category']}_atlas_map.json").write_text(json.dumps({"page_size": page_size, "padding": padding, "sprites": atlas_map}, indent=2) + "\n")
    print(f"Packed {len(source_items)} {items[0]['category']} sprites into {len(pages)} page(s): {output.relative_to(ROOT)}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Pack transparent Phagos art into non-rotated atlas pages.")
    parser.add_argument("--category", action="append", help="Category to pack; repeat flag for multiple. Defaults to every category.")
    parser.add_argument("--page-size", type=int, default=8192, choices=[2048, 4096, 8192], help="Square atlas page size.")
    parser.add_argument("--padding", type=int, default=16, help="Transparent/extruded gutter in pixels.")
    parser.add_argument("--output", type=Path, default=ROOT / "assets/atlas", help="Atlas output directory.")
    args = parser.parse_args()
    manifest = json.loads(MANIFEST.read_text())
    categories: dict[str, list[dict]] = defaultdict(list)
    selected = set(args.category or [])
    for item in manifest["assets"]:
        if not selected or item["category"] in selected:
            categories[item["category"]].append(item)
    output = args.output if args.output.is_absolute() else ROOT / args.output
    for items in categories.values():
        pack_category(items, output, args.page_size, args.padding)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
