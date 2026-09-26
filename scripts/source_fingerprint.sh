#!/usr/bin/env bash
# Prints a deterministic fingerprint of files that can affect the Web arena payload.
# Kept separate so preview_web.sh never silently serves a PCK made before source art changed.
set -euo pipefail

PROJECT_ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

(
    cd "$PROJECT_ROOT"
    {
        printf '%s\0' project.godot export_presets.cfg
        for directory in assets materials scenes scripts shaders web; do
            if [[ -d "$directory" ]]; then
                find "$directory" -type f -print0
            fi
        done
    } | sort -z | xargs -0 sha256sum
) | sha256sum | awk '{print $1}'
