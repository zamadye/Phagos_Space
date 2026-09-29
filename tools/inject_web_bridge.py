#!/usr/bin/env python3
"""Inject the app-owned UI bridge into a generated Godot Web HTML shell."""
from __future__ import annotations

import sys
from pathlib import Path

MARKER = '<script src="ui_bridge.js"></script>'
ANCHOR = '<script src="index.js"></script>'


def main() -> int:
    if len(sys.argv) != 2:
        print(f"Usage: {Path(sys.argv[0]).name} PATH/TO/index.html", file=sys.stderr)
        return 64

    output = Path(sys.argv[1])
    if not output.is_file():
        print(f"Generated Godot HTML shell not found: {output}", file=sys.stderr)
        return 1

    source = output.read_text(encoding="utf-8")
    if MARKER in source:
        return 0
    if ANCHOR not in source:
        print(f"Cannot locate Godot loader script in {output}", file=sys.stderr)
        return 1
    output.write_text(source.replace(ANCHOR, f"{MARKER}\n\t\t{ANCHOR}", 1), encoding="utf-8")
    print(f"Injected web UI bridge into {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
