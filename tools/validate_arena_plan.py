#!/usr/bin/env python3
"""Validate authored Dermal Rift data used by the playable Godot runtime."""
from __future__ import annotations

import json
import math
import sys
from collections import deque
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
PLAN_PATH = ROOT / "data" / "organ_biomes" / "dermal_rift.json"
REQUIRED_MATERIAL_ORDER = [
    "outer_skin",
    "fat",
    "muscle",
    "blue_fascia",
    "inner_membrane",
    "open_cavity",
]


def reachable(node_ids: set[str], links: list[dict[str, Any]], active_ids: set[str], start: str) -> set[str]:
    adjacency: dict[str, set[str]] = {node_id: set() for node_id in node_ids}
    for link in links:
        if link["id"] not in active_ids:
            continue
        start_id = str(link["from"])
        end_id = str(link["to"])
        adjacency[start_id].add(end_id)
        adjacency[end_id].add(start_id)
    seen = {start}
    queue: deque[str] = deque([start])
    while queue:
        current = queue.popleft()
        for neighbour in adjacency[current] - seen:
            seen.add(neighbour)
            queue.append(neighbour)
    return seen


def is_pair(value: object) -> bool:
    return (
        isinstance(value, list)
        and len(value) == 2
        and all(isinstance(component, (int, float)) for component in value)
    )


def main() -> int:
    errors: list[str] = []
    if not PLAN_PATH.is_file():
        print(f"Missing arena plan: {PLAN_PATH.relative_to(ROOT)}", file=sys.stderr)
        return 1

    try:
        plan: dict[str, Any] = json.loads(PLAN_PATH.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        print(f"Arena-plan validation failed: invalid JSON: {exc}", file=sys.stderr)
        return 1

    if plan.get("material_order") != REQUIRED_MATERIAL_ORDER:
        errors.append("material_order must preserve the authored anatomical stack")

    graph = plan.get("anchor_graph", {})
    nodes = graph.get("nodes", []) if isinstance(graph, dict) else []
    links = graph.get("links", []) if isinstance(graph, dict) else []
    if not isinstance(nodes, list) or not isinstance(links, list):
        errors.append("anchor_graph must contain node and link lists")
        nodes, links = [], []

    node_ids = {node.get("id") for node in nodes if isinstance(node, dict) and isinstance(node.get("id"), str)}
    link_ids = {link.get("id") for link in links if isinstance(link, dict) and isinstance(link.get("id"), str)}
    link_by_id = {str(link.get("id")): link for link in links if isinstance(link, dict)}

    entries = [node["id"] for node in nodes if isinstance(node, dict) and node.get("type") == "entry"]
    hubs = [node["id"] for node in nodes if isinstance(node, dict) and node.get("type") == "hub_chamber"]
    exits = [node["id"] for node in nodes if isinstance(node, dict) and node.get("type") == "exit"]
    if len(entries) != 1 or len(hubs) != 1 or len(exits) != 1:
        errors.append("plan must define exactly one entry, hub chamber, and exit")
    if len(nodes) < 9 or len(links) < 10:
        errors.append("Dermal Rift must retain its authored nine-anchor, ten-route exploration graph")

    safety = plan.get("safety_contract", {})
    if not isinstance(safety, dict):
        errors.append("safety_contract must be an object")
        safety = {}
    minimum_width = float(safety.get("minimum_traversable_width", 0))
    maximum_offset = float(safety.get("maximum_anchor_offset", 0))
    if safety.get("never_seal_active_player_cell") is not True:
        errors.append("dynamic arena must never seal the active player cell")
    if safety.get("always_keep_one_route_to_previous_stable_anchor") is not True:
        errors.append("dynamic arena must retain a retreat route")
    if safety.get("preview_transition_before_collision_commit") is not True:
        errors.append("route changes must preview before collision is committed")
    if minimum_width < 260:
        errors.append("safety contract must retain a 260px minimum route width")
    if maximum_offset <= 0 or maximum_offset > 72:
        errors.append("maximum anchor offset must be authored and cannot exceed 72px")
    if int(safety.get("max_topology_changes_per_transition", 0)) != 1:
        errors.append("each route transition must change at most one topology choice")
    if float(safety.get("minimum_seconds_between_topology_changes", 0)) < 12:
        errors.append("route changes need a 12-second minimum separation")

    for link in links:
        if not isinstance(link, dict):
            errors.append("link entry is not an object")
            continue
        link_id = str(link.get("id", "unknown"))
        if link.get("from") not in node_ids or link.get("to") not in node_ids:
            errors.append(f"link {link_id} references a missing node")
        if float(link.get("base_width", 0)) < minimum_width:
            errors.append(f"link {link_id} violates minimum traversable width")

    states = plan.get("dynamic_states", [])
    if not isinstance(states, list) or len(states) < 5:
        errors.append("Dermal Rift must define all five authored organ states")
        states = []

    if entries and hubs:
        for state in states:
            if not isinstance(state, dict):
                errors.append("dynamic state entry is not an object")
                continue
            state_id = str(state.get("id", "unknown"))
            active_ids = set(state.get("active_links", []))
            unknown = active_ids - link_ids
            if unknown:
                errors.append(f"state {state_id} references unknown links: {sorted(unknown)}")
                continue
            if not str(state.get("state_cue", "")).strip():
                errors.append(f"state {state_id} has no player-readable state cue")

            offsets = state.get("anchor_offsets", {})
            if not isinstance(offsets, dict):
                errors.append(f"state {state_id} anchor_offsets must be an object")
            else:
                for node_id, offset in offsets.items():
                    if node_id not in node_ids:
                        errors.append(f"state {state_id} offsets an unknown anchor: {node_id}")
                    elif not is_pair(offset):
                        errors.append(f"state {state_id} offset for {node_id} must be a numeric [x, y] pair")
                    elif math.hypot(float(offset[0]), float(offset[1])) > maximum_offset:
                        errors.append(f"state {state_id} moves {node_id} beyond its safe anchor envelope")

            scales = state.get("link_width_scales", {})
            if not isinstance(scales, dict):
                errors.append(f"state {state_id} link_width_scales must be an object")
            else:
                for link_id, scale in scales.items():
                    link = link_by_id.get(link_id)
                    if link is None:
                        errors.append(f"state {state_id} scales an unknown route: {link_id}")
                    elif not isinstance(scale, (int, float)) or scale <= 0:
                        errors.append(f"state {state_id} has an invalid width scale for {link_id}")
                    elif float(link["base_width"]) * float(scale) < minimum_width:
                        errors.append(f"state {state_id} narrows {link_id} below the safe width")

            connected = reachable(node_ids, links, active_ids, entries[0])
            if hubs[0] not in connected:
                errors.append(f"state {state_id} cannot reach the deep cavity")
            if exits and exits[0] not in connected:
                errors.append(f"state {state_id} cannot reach the organ gate")

    if errors:
        print("Arena-plan validation failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1
    print(
        "Arena-plan validation passed: every authored state preserves a safe route, bounded movement, readable cue, and entry-to-exit connectivity."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
