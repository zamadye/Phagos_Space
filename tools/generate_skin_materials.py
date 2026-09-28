#!/usr/bin/env python3
"""Bake an original, clean PHAGOS skin cross-section from positional material strata.

This authoring script creates complete transparent layer maps rather than runtime decoration.
Each path is first merged into a single anatomical mask, then bands are derived by subtraction:
outer skin -> fat -> muscle -> blue fascia -> cavity. That keeps joints clean and ensures
layers wrap the same open cavity instead of becoming independent visual overlays.
"""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
MATERIAL_OUT = ROOT / "assets" / "materials"
ARENA_OUT = ROOT / "assets" / "arena"
PREVIEW = ROOT / "assets" / "preview" / "skin_cross_section_preview.png"
CANVAS_SIZE = (2048, 1152)
STRIP_SIZE = (512, 256)

# The nested widths are intentional: every visible wall always has the same physical order.
OUTER_SKIN_WIDTH = 924
FAT_WIDTH = 704
MUSCLE_WIDTH = 528
FASCIA_WIDTH = 382
INNER_MEMBRANE_WIDTH = 310
LUMEN_WIDTH = 282


def rgba(color: tuple[int, int, int], alpha: int = 255) -> tuple[int, int, int, int]:
    return (*color, alpha)


def soft_line(image: Image.Image, points: list[tuple[float, float]], color: tuple[int, int, int], width: int, alpha: int) -> None:
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    ImageDraw.Draw(overlay).line(points, fill=rgba(color, alpha), width=width, joint="curve")
    image.alpha_composite(overlay)


def sine_path(width: int, y: float, amplitude: float, phase: float, cycles: float, steps: int = 72) -> list[tuple[float, float]]:
    return [
        (
            width * index / steps,
            y + math.sin((index / steps) * math.tau * cycles + phase) * amplitude,
        )
        for index in range(steps + 1)
    ]


def deep_tissue_strip() -> Image.Image:
    width, _height = STRIP_SIZE
    image = Image.new("RGBA", STRIP_SIZE, rgba((29, 19, 39)))
    for lane in range(12):
        soft_line(
            image,
            sine_path(width, 10 + lane * 23, 4.5 + lane % 3, lane * 0.63, 0.72),
            (57, 32 + lane % 3 * 4, 68),
            2,
            80,
        )
    return image.filter(ImageFilter.GaussianBlur(radius=0.3))


def outer_skin_strip() -> Image.Image:
    width, _height = STRIP_SIZE
    image = Image.new("RGBA", STRIP_SIZE, rgba((133, 66, 65)))
    for lane in range(16):
        color = (157, 77, 72) if lane % 3 else (63, 31, 45)
        soft_line(image, sine_path(width, 7 + lane * 16, 3.0 + lane % 3, lane * 0.43, 0.82), color, 2, 112)
    for lane in range(4):
        soft_line(image, sine_path(width, 32 + lane * 57, 7.0, lane * 0.88, 0.42), (205, 105, 81), 2, 45)
    return image


def fat_strip() -> Image.Image:
    width, _height = STRIP_SIZE
    image = Image.new("RGBA", STRIP_SIZE, rgba((188, 144, 54)))
    draw = ImageDraw.Draw(image, "RGBA")
    # Ordered, connected lobules read as adipose tissue rather than random floating dots.
    for row, y in enumerate((30, 91, 154, 216)):
        for column in range(-1, 7):
            cx = column * 92 + (row % 2) * 45
            cy = y + math.sin(column * 1.23 + row) * 6
            polygon = [
                (cx - 39, cy - 13), (cx - 16, cy - 29), (cx + 24, cy - 22),
                (cx + 42, cy - 1), (cx + 27, cy + 23), (cx - 19, cy + 27),
                (cx - 43, cy + 7),
            ]
            fill = (222, 184, 73) if (row + column) % 3 else (202, 156, 58)
            draw.polygon(polygon, fill=rgba(fill, 216))
            draw.line(polygon + [polygon[0]], fill=rgba((124, 67, 49), 150), width=3, joint="curve")
    for lane in range(4):
        soft_line(image, sine_path(width, 28 + lane * 58, 2.0, lane, 0.76), (245, 209, 111), 1, 46)
    return image


def muscle_strip() -> Image.Image:
    width, _height = STRIP_SIZE
    image = Image.new("RGBA", STRIP_SIZE, rgba((127, 37, 48)))
    for lane in range(21):
        color = (205, 73, 67) if lane % 4 in (1, 2) else (78, 24, 40)
        soft_line(image, sine_path(width, 5 + lane * 12, 2.1 + lane % 4 * 0.7, lane * 0.39, 0.88), color, 3 if lane % 3 else 2, 122)
    for lane in range(7):
        soft_line(image, sine_path(width, 17 + lane * 35, 4.5, lane * 0.58, 0.55), (238, 112, 87), 1, 76)
    return image


def fascia_strip() -> Image.Image:
    width, _height = STRIP_SIZE
    image = Image.new("RGBA", STRIP_SIZE, rgba((38, 75, 120)))
    for lane in range(13):
        color = (74, 143, 184) if lane % 3 else (25, 46, 90)
        soft_line(image, sine_path(width, 10 + lane * 19, 3.8 + lane % 3, lane * 0.50, 0.72), color, 3, 132)
    for lane in range(4):
        soft_line(image, sine_path(width, 28 + lane * 60, 7.0, lane, 0.38), (151, 118, 194), 2, 96)
    return image


def inner_membrane_strip() -> Image.Image:
    width, _height = STRIP_SIZE
    image = Image.new("RGBA", STRIP_SIZE, rgba((104, 55, 92)))
    # A quiet warm inner seam separates the cool fascia from the open cavity. It is material,
    # not a bloom or animated outline.
    for lane in range(10):
        color = (188, 102, 151) if lane % 2 else (78, 39, 77)
        soft_line(image, sine_path(width, 12 + lane * 25, 2.2, lane * 0.61, 0.56), color, 2, 110)
    return image


def lumen_strip() -> Image.Image:
    width, _height = STRIP_SIZE
    image = Image.new("RGBA", STRIP_SIZE, rgba((48, 39, 56)))
    for lane in range(7):
        soft_line(image, sine_path(width, 24 + lane * 32, 2.0 + lane % 2, lane * 0.82, 0.48), (95, 61, 73), 2, 68)
    for lane in range(2):
        soft_line(image, sine_path(width, 72 + lane * 100, 4.0, lane, 0.28), (151, 99, 95), 1, 50)
    return image


def tile(texture: Image.Image, size: tuple[int, int]) -> Image.Image:
    result = Image.new("RGBA", size)
    for y in range(0, size[1], texture.height):
        for x in range(0, size[0], texture.width):
            result.alpha_composite(texture, (x, y))
    return result


def route_points() -> list[list[tuple[float, float]]]:
    # Endpoints deliberately run beyond the frame: the arena reads as an open tissue system,
    # not circular rooms joined by capped tubes.
    return [
        [(-180, 412), (180, 372), (470, 328), (760, 314), (1050, 340), (1360, 294), (1660, 205), (2240, 182)],
        [(-150, 1180), (178, 965), (422, 760), (615, 565), (774, 410), (950, 330), (1150, 280), (1410, 258)],
        [(-120, 1240), (235, 1082), (515, 900), (706, 758), (864, 605), (994, 460), (1105, 365), (1265, 282), (1530, 223)],
    ]


def union_mask(width: int) -> Image.Image:
    mask = Image.new("L", CANVAS_SIZE, 0)
    draw = ImageDraw.Draw(mask)
    for points in route_points():
        draw.line(points, fill=255, width=width, joint="curve")
    # A one-pixel blur/threshold removes raster stair-steps without soft, dirty edges.
    return mask.filter(ImageFilter.GaussianBlur(radius=0.55)).point(lambda value: 255 if value > 20 else 0)


def band_masks() -> dict[str, Image.Image]:
    outer = union_mask(OUTER_SKIN_WIDTH)
    fat = union_mask(FAT_WIDTH)
    muscle = union_mask(MUSCLE_WIDTH)
    fascia = union_mask(FASCIA_WIDTH)
    inner_membrane = union_mask(INNER_MEMBRANE_WIDTH)
    lumen = union_mask(LUMEN_WIDTH)
    return {
        "outer_skin": ImageChops.subtract(outer, fat),
        "fat": ImageChops.subtract(fat, muscle),
        "muscle": ImageChops.subtract(muscle, fascia),
        "fascia": ImageChops.subtract(fascia, inner_membrane),
        "inner_membrane": ImageChops.subtract(inner_membrane, lumen),
        "lumen": lumen,
    }


def position_tint(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int], east_shift: int = 0) -> Image.Image:
    # A smooth positional grade makes each route feel anatomically local while preserving
    # the material's base hue. There is no per-prop random tinting or animated overlay.
    low_resolution = (128, 72)
    field = Image.new("RGB", low_resolution)
    pixels = field.load()
    for y in range(low_resolution[1]):
        vertical = y / max(1, low_resolution[1] - 1)
        for x in range(low_resolution[0]):
            east = (x / max(1, low_resolution[0] - 1) - 0.5) * east_shift
            pixels[x, y] = tuple(
                max(0, min(255, round(top[channel] + (bottom[channel] - top[channel]) * vertical + east)))
                for channel in range(3)
            )
    return field.resize(size, Image.Resampling.BICUBIC).convert("RGBA")


def fat_field(size: tuple[int, int]) -> Image.Image:
    """One non-repeating adipose field for the finished map.

    Lobules are intentionally ordered and connected; their placement varies by map position
    instead of repeating as a visible decorative tile.
    """
    width, height = size
    image = Image.new("RGBA", size, rgba((188, 144, 54)))
    draw = ImageDraw.Draw(image, "RGBA")
    row_step, column_step = 94, 132
    for row in range(-1, height // row_step + 2):
        for column in range(-1, width // column_step + 2):
            cx = column * column_step + (row % 2) * 58 + math.sin(row * 0.81 + column * 0.53) * 15
            cy = row * row_step + 38 + math.sin(column * 0.72 + row * 0.47) * 11
            rx = 42 + int((math.sin(column * 1.71 + row * 0.33) + 1.0) * 8)
            ry = 26 + int((math.cos(column * 0.62 - row * 1.17) + 1.0) * 5)
            polygon = [
                (cx - rx, cy - ry * 0.40), (cx - rx * 0.45, cy - ry),
                (cx + rx * 0.47, cy - ry * 0.86), (cx + rx, cy - ry * 0.18),
                (cx + rx * 0.62, cy + ry * 0.80), (cx - rx * 0.42, cy + ry),
                (cx - rx, cy + ry * 0.32),
            ]
            bright = 0.5 + 0.5 * math.sin(column * 1.13 + row * 0.61)
            fill = (211 + int(bright * 16), 166 + int(bright * 18), 62 + int(bright * 12))
            draw.polygon(polygon, fill=rgba(fill, 214))
            draw.line(polygon + [polygon[0]], fill=rgba((123, 66, 48), 142), width=3, joint="curve")
    return image


def apply_material(strip: Image.Image, mask: Image.Image, grade: Image.Image, full_field: Image.Image | None = None) -> Image.Image:
    textured = (full_field if full_field is not None else tile(strip, CANVAS_SIZE)).convert("RGB")
    graded = ImageChops.multiply(textured, grade.convert("RGB")).convert("RGBA")
    result = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    result.paste(graded, (0, 0), mask)
    return result


def save_layers(strips: dict[str, Image.Image]) -> None:
    ARENA_OUT.mkdir(parents=True, exist_ok=True)
    masks = band_masks()
    backdrop = tile(strips["deep"], CANVAS_SIZE)
    grades = {
        "outer_skin": position_tint(CANVAS_SIZE, (255, 236, 225), (178, 194, 230), 16),
        "fat": position_tint(CANVAS_SIZE, (255, 239, 192), (220, 234, 190), -8),
        "muscle": position_tint(CANVAS_SIZE, (255, 224, 210), (218, 190, 224), 12),
        "fascia": position_tint(CANVAS_SIZE, (170, 226, 255), (212, 183, 255), -10),
        "inner_membrane": position_tint(CANVAS_SIZE, (255, 200, 221), (220, 174, 255), 4),
        "lumen": position_tint(CANVAS_SIZE, (224, 198, 188), (186, 201, 234), 4),
    }
    source_key = {
        "outer_skin": "outer_skin",
        "fat": "fat",
        "muscle": "muscle",
        "fascia": "fascia",
        "inner_membrane": "inner_membrane",
        "lumen": "lumen",
    }
    layer_names = {
        "outer_skin": "01_outer_skin.png",
        "fat": "02_fat.png",
        "muscle": "03_muscle.png",
        "fascia": "04_fascia.png",
        "inner_membrane": "05_inner_membrane.png",
        "lumen": "06_open_cavity.png",
    }
    backdrop.save(ARENA_OUT / "00_deep_tissue_backdrop.png", optimize=True)
    composite = backdrop.copy()
    for name in ("outer_skin", "fat", "muscle", "fascia", "inner_membrane", "lumen"):
        full_field = fat_field(CANVAS_SIZE) if name == "fat" else None
        layer = apply_material(strips[source_key[name]], masks[name], grades[name], full_field)
        layer.save(ARENA_OUT / layer_names[name], optimize=True)
        composite.alpha_composite(layer)
    composite.save(ARENA_OUT / "skin_cross_section_composite.png", optimize=True)
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    composite.save(PREVIEW, optimize=True)


def main() -> None:
    MATERIAL_OUT.mkdir(parents=True, exist_ok=True)
    strips = {
        "deep": deep_tissue_strip(),
        "outer_skin": outer_skin_strip(),
        "fat": fat_strip(),
        "muscle": muscle_strip(),
        "fascia": fascia_strip(),
        "inner_membrane": inner_membrane_strip(),
        "lumen": lumen_strip(),
    }
    filenames = {
        "deep": "deep_tissue_strip.png",
        "outer_skin": "outer_skin_strip.png",
        "fat": "fat_strip.png",
        "muscle": "muscle_strip.png",
        "fascia": "fascia_strip.png",
        "inner_membrane": "inner_membrane_strip.png",
        "lumen": "lumen_floor_strip.png",
    }
    for key, image in strips.items():
        image.save(MATERIAL_OUT / filenames[key], optimize=True)
    save_layers(strips)
    print(f"Wrote {len(strips)} original material strips to {MATERIAL_OUT}")
    print(f"Wrote layered arena maps and preview to {ARENA_OUT}")


if __name__ == "__main__":
    main()
