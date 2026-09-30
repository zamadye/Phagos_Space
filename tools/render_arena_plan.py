#!/usr/bin/env python3
"""Render the authored Dermal Rift topology as a review-only arena plan."""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
PLAN_PATH = ROOT / "data" / "organ_biomes" / "dermal_rift.json"
OUTPUT_PATH = ROOT / "docs" / "preview" / "dermal_rift_layout_plan.png"
CANVAS = (1920, 1080)
PADDING = 80

PALETTE = {
    "background": (19, 11, 29, 255),
    "skin": (145, 67, 74, 255),
    "fat": (201, 147, 45, 255),
    "muscle": (164, 43, 51, 255),
    "fascia": (43, 104, 170, 255),
    "membrane": (145, 63, 126, 255),
    "lumen": (38, 25, 47, 255),
    "line": (239, 219, 230, 220),
    "muted": (173, 147, 175, 255),
}


def project(point: list[int], world: dict[str, int]) -> tuple[int, int]:
    x = PADDING + point[0] / world["width"] * (CANVAS[0] - PADDING * 2)
    y = PADDING + point[1] / world["height"] * (CANVAS[1] - PADDING * 2)
    return round(x), round(y)


def width(value: int, world: dict[str, int], multiplier: float) -> int:
    scale = (CANVAS[0] - PADDING * 2) / world["width"]
    return max(2, round(value * scale * multiplier))


def main() -> None:
    plan = json.loads(PLAN_PATH.read_text(encoding="utf-8"))
    world = plan["world_bounds"]
    nodes = {node["id"]: node for node in plan["anchor_graph"]["nodes"]}
    image = Image.new("RGBA", CANVAS, PALETTE["background"])
    draw = ImageDraw.Draw(image, "RGBA")

    # All corridors keep the same material order as the runtime contract.
    band_spec = [
        ("skin", 1.75),
        ("fat", 1.53),
        ("muscle", 1.30),
        ("fascia", 1.12),
        ("membrane", 1.04),
        ("lumen", 0.92),
    ]
    for link in plan["anchor_graph"]["links"]:
        start = project(nodes[link["from"]]["position"], world)
        end = project(nodes[link["to"]]["position"], world)
        for color, multiplier in band_spec:
            draw.line([start, end], fill=PALETTE[color], width=width(link["base_width"], world, multiplier), joint="curve")

    label_font = ImageFont.load_default()
    for node in plan["anchor_graph"]["nodes"]:
        center = project(node["position"], world)
        node_w, node_h = node["footprint"]
        radius_x = max(20, width(node_w, world, 0.45))
        radius_y = max(16, width(node_h, world, 0.45))
        for color, multiplier in band_spec:
            rx = int(radius_x * multiplier)
            ry = int(radius_y * multiplier)
            draw.ellipse((center[0] - rx, center[1] - ry, center[0] + rx, center[1] + ry), fill=PALETTE[color])
        title = node["landmark"].upper()
        text_box = draw.textbbox((0, 0), title, font=label_font)
        text_x = center[0] - (text_box[2] - text_box[0]) // 2
        draw.text((text_x, center[1] - 5), title, fill=PALETTE["line"], font=label_font)
        draw.text((text_x, center[1] + 9), node["type"].replace("_", " "), fill=PALETTE["muted"], font=label_font)

    draw.text((PADDING, 28), "PHAGOS / DERMAL RIFT / AUTHORING PLAN", fill=PALETTE["line"], font=label_font)
    draw.text((PADDING, 45), "Topology review only — runtime geometry will be generated from the same data.", fill=PALETTE["muted"], font=label_font)
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUTPUT_PATH)
    print(f"Wrote {OUTPUT_PATH.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
