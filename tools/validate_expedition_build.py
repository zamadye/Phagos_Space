#!/usr/bin/env python3
"""Structural checks for the playable native-Godot Dermal Rift expedition."""
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
    "hud": "scripts/expedition_hud.gd",
    "map": "scripts/dermal_rift_map.gd",
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
    sources = {label: require_text(errors, label, relative) for label, relative in REQUIRED_FILES.items()}

    scene = sources["scene"]
    if 'res://scripts/dermal_rift_expedition.gd' not in scene:
        errors.append("main scene does not use the playable Dermal Rift runtime")
    if "skin_cross_section_arena.gd" in scene:
        errors.append("main scene still points at the retired static cross-section script")

    for required in (
        "CharacterBody2D",
        "StaticBody2D",
        "DynamicCavityCollision",
        "_rebuild_collision",
        "_is_walkable",
        "_request_next_state",
        "_try_interact",
        "get_runtime_contract",
    ):
        if required not in sources["expedition"]:
            errors.append(f"expedition runtime is missing playable contract: {required}")

    for required in ("move_and_slide", "CollisionShape2D", "KEY_W", "KEY_LEFT"):
        if required not in sources["player"]:
            errors.append(f"traversal controller is missing input/collision behavior: {required}")

    for required in ("CanvasLayer", "OBJECTIVE", "toggle_map", "show_completion"):
        if required not in sources["hud"]:
            errors.append(f"native HUD is missing exploration behavior: {required}")

    for required in ("_draw_route", "_draw_chamber", "_draw_collapsed_link", "set_layout"):
        if required not in sources["world"]:
            errors.append(f"dynamic world renderer is missing organ-state behavior: {required}")

    try:
        plan = json.loads(sources["plan"])
    except json.JSONDecodeError as exc:
        errors.append(f"Dermal Rift plan is invalid JSON: {exc}")
        plan = {}

    graph = plan.get("anchor_graph", {}) if isinstance(plan, dict) else {}
    nodes = graph.get("nodes", []) if isinstance(graph, dict) else []
    links = graph.get("links", []) if isinstance(graph, dict) else []
    states = plan.get("dynamic_states", []) if isinstance(plan, dict) else []
    node_ids = {node.get("id") for node in nodes if isinstance(node, dict)}
    link_ids = {link.get("id") for link in links if isinstance(link, dict)}
    if len(nodes) < 9:
        errors.append("Dermal Rift has fewer than nine explorable anchors")
    if len(links) < 10:
        errors.append("Dermal Rift has fewer than ten authored routes")
    if len(states) < 5:
        errors.append("Dermal Rift has fewer than five organ states")
    for expected_node in ("surface_breach", "deep_cavity", "organ_gate"):
        if expected_node not in node_ids:
            errors.append(f"Dermal Rift lacks required exploration landmark: {expected_node}")
    if "cavity_to_gate" not in link_ids:
        errors.append("Dermal Rift lacks the progression gate route")

    safety = plan.get("safety_contract", {}) if isinstance(plan, dict) else {}
    if safety.get("never_seal_active_player_cell") is not True:
        errors.append("arena data does not explicitly protect the active player cell")
    if safety.get("always_keep_one_route_to_previous_stable_anchor") is not True:
        errors.append("arena data does not require a retreat route")

    for state in states:
        if not isinstance(state, dict):
            errors.append("arena contains a non-object state")
            continue
        state_id = str(state.get("id", "unknown"))
        if not isinstance(state.get("anchor_offsets", {}), dict):
            errors.append(f"{state_id}: lacks authored anchor offsets")
        if not isinstance(state.get("link_width_scales", {}), dict):
            errors.append(f"{state_id}: lacks authored route-width behavior")
        if not str(state.get("state_cue", "")).strip():
            errors.append(f"{state_id}: lacks a player-readable state cue")

    if (ROOT / "scripts" / "skin_cross_section_arena.gd").exists():
        errors.append("retired static-only arena script is still present")
    if (ROOT / "tools" / "runtime_cross_section_probe.gd").exists():
        errors.append("retired static-only runtime probe is still present")
    if (ROOT / "web").exists():
        errors.append("unexpected standalone web-app layer: WebView must serve the Godot export")

    if errors:
        print("Expedition build validation failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    print(
        "Expedition build validation passed: native controller, collision cavity, dynamic organ states, progression gate, and Godot HUD are present."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
