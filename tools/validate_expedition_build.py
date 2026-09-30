#!/usr/bin/env python3
"""Structural checks for the hand-authored playable Dermal Rift Godot scene."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = {
    "scene": "scenes/main.tscn",
    "expedition": "scripts/dermal_rift_expedition.gd",
    "world": "scripts/dermal_rift_world.gd",
    "player": "scripts/traversal_cell.gd",
    "playfield": "assets/arena/dermal_rift_playfield.png",
    "plan": "data/organ_biomes/dermal_rift.json",
    "runtime_probe": "tools/runtime_expedition_probe.gd",
}


def require_text(errors: list[str], label: str, relative: str) -> str:
    path = ROOT / relative
    if not path.is_file():
        errors.append(f"missing {label}: {relative}")
        return ""
    return path.read_text(encoding="utf-8")


def main() -> int:
    errors: list[str] = []
    sources: dict[str, str] = {}
    for label, relative in REQUIRED_FILES.items():
        path = ROOT / relative
        if label == "playfield":
            if not path.is_file() or path.stat().st_size < 10_000:
                errors.append(f"missing or implausibly small authored playfield: {relative}")
            continue
        sources[label] = require_text(errors, label, relative)

    scene = sources.get("scene", "")
    if "res://scripts/dermal_rift_expedition.gd" not in scene:
        errors.append("main scene does not use the playable Dermal Rift runtime")

    expedition = sources.get("expedition", "")
    for required in (
        "CharacterBody2D",
        "StaticBody2D",
        "DynamicCavityCollision",
        "_rebuild_collision",
        "_is_walkable",
        "_try_interact",
        "_request_next_state",
        "debug_collect_echo",
        "debug_awaken_cavity",
        "get_runtime_contract",
    ):
        if required not in expedition:
            errors.append(f"expedition runtime is missing playable contract: {required}")
    for forbidden in ("CanvasLayer", "ExpeditionHUD", "DermalRiftMap", "toggle_map"):
        if forbidden in expedition:
            errors.append(f"expedition runtime still contains dashboard-overlay route: {forbidden}")

    player = sources.get("player", "")
    for required in ("move_and_slide", "CollisionShape2D", "KEY_W", "KEY_LEFT"):
        if required not in player:
            errors.append(f"traversal controller is missing input/collision behavior: {required}")

    world = sources.get("world", "")
    for required in (
        "dermal_rift_playfield.png",
        "Sprite2D",
        "_draw_lower_valve",
        "_draw_echo_landmark",
        "_draw_organ_gate",
        "set_world_state",
    ):
        if required not in world:
            errors.append(f"playfield renderer is missing authored-world behavior: {required}")
    for forbidden in ("CanvasLayer", "Control.new()", "PanelContainer.new()"):
        if forbidden in world:
            errors.append(f"playfield renderer contains a screen-overlay route: {forbidden}")

    try:
        plan = json.loads(sources.get("plan", "{}"))
    except json.JSONDecodeError as exc:
        errors.append(f"Dermal Rift plan is invalid JSON: {exc}")
        plan = {}

    graph = plan.get("anchor_graph", {}) if isinstance(plan, dict) else {}
    nodes = graph.get("nodes", []) if isinstance(graph, dict) else []
    links = graph.get("links", []) if isinstance(graph, dict) else []
    states = plan.get("dynamic_states", []) if isinstance(plan, dict) else []
    if len(nodes) < 9 or len(links) < 10 or len(states) < 5:
        errors.append("production arena plan lost its authored topology/state contract")

    if (ROOT / "scripts" / "expedition_hud.gd").exists():
        errors.append("retired dashboard HUD script is still present")
    if (ROOT / "scripts" / "dermal_rift_map.gd").exists():
        errors.append("retired dashboard map script is still present")
    if (ROOT / "web").exists():
        errors.append("unexpected standalone web-app layer: WebView must serve the Godot export")

    if errors:
        print("Expedition build validation failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    print(
        "Expedition build validation passed: a native controller explores an authored playfield with collision, landmarks, tissue valve, and no dashboard overlay."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
