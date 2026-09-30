#!/usr/bin/env python3
"""Validate the authored dynamic-organ graph before it becomes runtime geometry."""
from __future__ import annotations

import json
import sys
from collections import deque
from pathlib import Path

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


def reachable(node_ids: set[str], links: list[dict[str, object]], active_ids: set[str], start: str) -> set[str]:
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


def main() -> int:
    errors: list[str] = []
    if not PLAN_PATH.is_file():
        print(f"Missing arena plan: {PLAN_PATH.relative_to(ROOT)}", file=sys.stderr)
        return 1

    plan = json.loads(PLAN_PATH.read_text(encoding="utf-8"))
    if plan.get("material_order") != REQUIRED_MATERIAL_ORDER:
        errors.append("material_order must preserve the authored anatomical stack")

    graph = plan.get("anchor_graph", {})
    nodes = graph.get("nodes", [])
    links = graph.get("links", [])
    node_ids = {node.get("id") for node in nodes if isinstance(node.get("id"), str)}
    link_ids = {link.get("id") for link in links if isinstance(link.get("id"), str)}

    entries = [node["id"] for node in nodes if node.get("type") == "entry"]
    hubs = [node["id"] for node in nodes if node.get("type") == "hub_chamber"]
    exits = [node["id"] for node in nodes if node.get("type") == "exit"]
    if len(entries) != 1 or len(hubs) != 1 or len(exits) != 1:
        errors.append("plan must define exactly one entry, hub chamber, and exit")

    for link in links:
        if link.get("from") not in node_ids or link.get("to") not in node_ids:
            errors.append(f"link {link.get('id')} references a missing node")
        if int(link.get("base_width", 0)) < 260:
            errors.append(f"link {link.get('id')} violates minimum traversable width")

    safety = plan.get("safety_contract", {})
    if safety.get("never_seal_active_player_cell") is not True:
        errors.append("dynamic arena must never seal the active player cell")
    if safety.get("always_keep_one_route_to_previous_stable_anchor") is not True:
        errors.append("dynamic arena must retain a retreat route")
    if int(safety.get("minimum_traversable_width", 0)) < 260:
        errors.append("safety contract must retain a 260px minimum route width")

    if entries and hubs:
        for state in plan.get("dynamic_states", []):
            active_ids = set(state.get("active_links", []))
            unknown = active_ids - link_ids
            if unknown:
                errors.append(f"state {state.get('id')} references unknown links: {sorted(unknown)}")
                continue
            connected = reachable(node_ids, links, active_ids, entries[0])
            if hubs[0] not in connected:
                errors.append(f"state {state.get('id')} cannot reach the deep cavity")
            if exits and exits[0] not in connected:
                errors.append(f"state {state.get('id')} cannot reach the organ gate")

    if errors:
        print("Arena-plan validation failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1
    print("Arena-plan validation passed: all authored organ states retain a safe entry-to-exit route.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
