#!/usr/bin/env python3
"""Portable structural checks for the Godot engine + WebView export workflow."""
from __future__ import annotations

import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def require_file(errors: list[str], relative: str) -> Path:
    path = ROOT / relative
    if not path.is_file():
        errors.append(f"missing required file: {relative}")
    return path


def main() -> int:
    errors: list[str] = []
    project = require_file(errors, "project.godot")
    main_scene = require_file(errors, "scenes/main.tscn")
    preset = require_file(errors, "export_presets.cfg")
    _ = main_scene

    for relative in ("tools/install_godot.sh", "scripts/export_web.sh", "scripts/preview_web.sh"):
        path = require_file(errors, relative)
        if path.is_file() and not os.access(path, os.X_OK):
            errors.append(f"launcher is not executable: {relative}")

    if project.is_file():
        source = project.read_text(encoding="utf-8")
        for expected in ('run/main_scene="res://scenes/main.tscn"', '"4.3"', '"GL Compatibility"'):
            if expected not in source:
                errors.append(f"project.godot missing expected engine contract: {expected}")

    if preset.is_file():
        source = preset.read_text(encoding="utf-8")
        for expected in ('name="Web"', 'platform="Web"', 'export_path="build/web/index.html"', 'variant/thread_support=false'):
            if expected not in source:
                errors.append(f"export_presets.cfg missing expected Web export contract: {expected}")

    for relative in ("build/web/index.html", "build/web/index.wasm", "build/web/index.pck"):
        path = require_file(errors, relative)
        if path.is_file() and path.stat().st_size == 0:
            errors.append(f"generated Web payload is empty: {relative}")

    if (ROOT / "web").exists():
        errors.append("unexpected standalone web-app layer: WebView must serve the Godot Web export")

    if errors:
        print("Godot setup validation failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    print("Godot setup validation passed: native project, portable installer, Web export preset, and WebView payload are present.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
