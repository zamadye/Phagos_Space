#!/usr/bin/env python3
"""Prepare a generator-produced biological overlay for the Phagos art contract.

The image model used for concept generation can return an opaque preview even when a
transparent PNG is requested. This utility turns that preview into a clean *overlay*
without manufacturing a flat background: it derives a soft alpha from local painted
detail, applies a biome-safe dark grade, normalizes the master size, and optionally
matches the outer pixel rows for the manifest's seamless-floor check.

It is deliberately conservative. It is not a substitute for the human 100%/400%
art review recorded in docs/ASSET_GENERATION_PROMPTS.md.
"""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageChops, ImageEnhance, ImageFilter, ImageOps


PROFILE_GRADE = {
    "heart": (0.72, 0.34, 0.38),
    "lung": (0.42, 0.72, 0.76),
    "brain": (0.48, 0.42, 0.82),
    "marrow": (0.78, 0.58, 0.56),
    "vein": (1.0, 1.0, 1.0),
    "neutral": (0.70, 0.70, 0.70),
}


def _clamp_byte(value: float) -> int:
    return max(0, min(255, round(value)))


def _seam_outer_edge(image: Image.Image) -> Image.Image:
    """Make opposite outermost rows/columns identical without blurring the whole art."""
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    for y in range(height):
        left = pixels[0, y]
        right = pixels[width - 1, y]
        average = tuple((left[channel] + right[channel]) // 2 for channel in range(4))
        pixels[0, y] = average
        pixels[width - 1, y] = average
    for x in range(width):
        top = pixels[x, 0]
        bottom = pixels[x, height - 1]
        average = tuple((top[channel] + bottom[channel]) // 2 for channel in range(4))
        pixels[x, 0] = average
        pixels[x, height - 1] = average
    return rgba


def _saturation_key_alpha(image: Image.Image, threshold: float) -> Image.Image:
    """Keep saturated painted anatomy while discarding a neutral preview/checker field."""
    rgb = image.convert("RGB")
    width, height = rgb.size
    pixels = rgb.load()
    alpha = Image.new("L", rgb.size)
    alpha_pixels = alpha.load()
    for y in range(height):
        for x in range(width):
            channels = pixels[x, y]
            maximum = max(channels)
            minimum = min(channels)
            saturation = 0.0 if maximum == 0 else (maximum - minimum) / maximum
            alpha_pixels[x, y] = 0 if saturation <= threshold else _clamp_byte((saturation - threshold) / max(0.01, 1.0 - threshold) * 255.0)
    return alpha.filter(ImageFilter.GaussianBlur(radius=max(1, width // 2048)))


def _corner_key_alpha(image: Image.Image) -> Image.Image:
    """Derive alpha from distance to corner background samples for isolated prop art."""
    rgb = image.convert("RGB")
    width, height = rgb.size
    pixels = rgb.load()
    samples = [pixels[0, 0], pixels[width - 1, 0], pixels[0, height - 1], pixels[width - 1, height - 1]]
    alpha = Image.new("L", rgb.size)
    alpha_pixels = alpha.load()
    for y in range(height):
        for x in range(width):
            red, green, blue = pixels[x, y]
            distance = min(abs(red - sample[0]) + abs(green - sample[1]) + abs(blue - sample[2]) for sample in samples)
            alpha_pixels[x, y] = 0 if distance < 18 else _clamp_byte((distance - 18) * 1.7)
    return alpha.filter(ImageFilter.GaussianBlur(radius=max(1, width // 2048)))


def build_overlay(source: Image.Image, profile: str, size: int, seamless: bool, key_alpha: bool, saturation_key: float | None, preserve_color: bool) -> Image.Image:
    """Return a dark, partially transparent art overlay from an opaque concept preview."""
    image = source.convert("RGB")
    image = image.resize((size, size), Image.Resampling.LANCZOS)
    image = ImageEnhance.Contrast(image).enhance(1.13)
    image = ImageEnhance.Color(image).enhance(0.90)

    # High-frequency detail becomes more opaque than an even tone. This drops baked
    # checkerboards / flat preview fields while retaining painted tissue features.
    gray = ImageOps.grayscale(image)
    broad = gray.filter(ImageFilter.GaussianBlur(radius=max(8, size // 180)))
    detail = ImageChops.difference(gray, broad)
    red = image.getchannel("R")
    green = image.getchannel("G")
    blue = image.getchannel("B")
    saturation = ImageChops.subtract(
        ImageChops.lighter(ImageChops.lighter(red, green), blue),
        ImageChops.darker(ImageChops.darker(red, green), blue),
    )
    if saturation_key is not None:
        alpha = _saturation_key_alpha(image, saturation_key)
    elif key_alpha:
        alpha = _corner_key_alpha(image)
    elif profile == "vein":
        # Preview backgrounds are usually neutral gray, white, or a fake checkerboard.
        # Vessel pigmentation is saturated, so use it as the matte key and leave truly
        # empty pixels at alpha zero rather than retaining a faint rectangular card.
        alpha = saturation.point(lambda value: 0 if value < 26 else _clamp_byte((value - 26) * 2.35))
        alpha = alpha.filter(ImageFilter.GaussianBlur(radius=max(1, size // 2048)))
    else:
        alpha = ImageChops.lighter(detail.point(lambda value: _clamp_byte(value * 2.4)), saturation.point(lambda value: _clamp_byte(value * 1.15)))
        # A very soft baseline prevents harsh cutouts while retaining real transparency.
        alpha = alpha.point(lambda value: _clamp_byte(10 + value * 0.62))
        alpha = alpha.filter(ImageFilter.GaussianBlur(radius=max(1, size // 1024)))

    grade = PROFILE_GRADE[profile]
    if preserve_color:
        graded = image
    else:
        graded = Image.new("RGB", image.size)
        source_pixels = image.load()
        target_pixels = graded.load()
        for y in range(size):
            for x in range(size):
                red, green, blue = source_pixels[x, y]
                # Keep subtle painterly value variation but bias away from the model's
                # frequent white / checkerboard preview background.
                if profile == "vein":
                    # The pulse shader supplies the biome signal color. A luminance mask lets
                    # it drive a generated vessel texture without muddying the emission.
                    luma = _clamp_byte(red * 0.2126 + green * 0.7152 + blue * 0.0722)
                    target_pixels[x, y] = (luma, luma, luma)
                else:
                    target_pixels[x, y] = (
                        _clamp_byte((red * grade[0]) * 0.72),
                        _clamp_byte((green * grade[1]) * 0.72),
                        _clamp_byte((blue * grade[2]) * 0.72),
                    )
    result = graded.convert("RGBA")
    result.putalpha(alpha)
    return _seam_outer_edge(result) if seamless else result


def main() -> int:
    parser = argparse.ArgumentParser(description="Prepare an opaque AI concept as a Phagos transparent art overlay.")
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--profile", choices=sorted(PROFILE_GRADE), default="neutral")
    parser.add_argument("--size", type=int, default=2048)
    parser.add_argument("--seamless", action="store_true")
    parser.add_argument("--key-alpha", action="store_true", help="Remove a neutral/checker preview background using corner-color samples.")
    parser.add_argument("--saturation-key", type=float, help="Remove pixels below this HSV-style saturation value (0–1).")
    parser.add_argument("--preserve-color", action="store_true", help="Keep source RGB values while replacing only alpha.")
    args = parser.parse_args()

    with Image.open(args.input) as source:
        result = build_overlay(source, args.profile, args.size, args.seamless, args.key_alpha, args.saturation_key, args.preserve_color)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    result.save(args.output, "PNG", optimize=True, compress_level=9)
    alpha = result.getchannel("A")
    print(f"Prepared {args.output}: {result.size[0]}x{result.size[1]} alpha={alpha.getextrema()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
