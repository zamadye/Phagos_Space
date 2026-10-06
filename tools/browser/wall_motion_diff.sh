#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE="$ROOT/evidence"
DIFF="$EVIDENCE/wall-study-breathing-diff.png"
METRICS="$EVIDENCE/wall-study-breathing-diff.txt"

compare -metric AE \
  "$EVIDENCE/wall-study-smoke.png" \
  "$EVIDENCE/wall-study-breathing-after.png" \
  "$DIFF" 2> "$METRICS" || true

changed_pixels="$(tr -d '[:space:]' < "$METRICS")"
printf 'Wall breathing image difference: changed_pixels=%s; diff=%s\n' "$changed_pixels" "${DIFF#$ROOT/}"
