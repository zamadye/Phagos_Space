class_name CorridorBuilder
extends RefCounted
## Bezier/spline extrusion data builder. It only outputs geometry data; OrganicCorridor
## owns rendering, which keeps the generator usable for navigation or collision later.

static func build(edge: Dictionary, from_room: Dictionary, to_room: Dictionary, biome: PhagosBiomeDefinition) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = int(edge.get("seed", 1))
    var center_direction: Vector2 = (to_room["position"] - from_room["position"]).normalized()
    var start := _boundary_point(from_room, center_direction)
    var end := _boundary_point(to_room, -center_direction)
    var distance := start.distance_to(end)
    var normal := center_direction.orthogonal()
    var base_bend := float(edge.get("curve_bias", 0.0)) * distance * 0.32
    var organic_bend := rng.randf_range(-0.12, 0.12) * distance
    var bend := base_bend + organic_bend
    # A tiny deterministic bend is retained even at a zero random value: never a ruler-straight hall.
    if absf(bend) < 18.0:
        bend = 18.0 * (1.0 if rng.randf() > 0.5 else -1.0)
    var handle_length := clampf(distance * rng.randf_range(0.26, 0.36), 120.0, 420.0)
    var control_a := start + center_direction * handle_length + normal * bend
    var control_b := end - center_direction * handle_length + normal * bend * rng.randf_range(0.52, 0.86)
    var sample_count := clampi(int(distance / 42.0), 14, 42)
    var points := PackedVector2Array()
    var widths := PackedFloat32Array()
    var nominal_width := clampf(float(edge.get("width", 192.0)), 96.0, 192.0)
    var widening := float(edge.get("widening", 0.0))

    for i in range(sample_count + 1):
        var t := float(i) / float(sample_count)
        points.append(_cubic_bezier(start, control_a, control_b, end, t))
        var undulation := sin(t * TAU * rng.randf_range(0.75, 1.25) + rng.randf_range(0.0, TAU)) * 0.06
        var taper := lerpf(-widening, widening, t)
        # Ports are calm near rooms and the body is free to breathe in-between.
        var port_damping := smoothstep(0.0, 0.13, t) * smoothstep(1.0, 0.87, t)
        widths.append(clampf(nominal_width * (1.0 + (undulation + taper) * port_damping), 96.0, 224.0))

    return {
        "id": edge["id"],
        "seed": edge["seed"],
        "points": points,
        "widths": widths,
        "branches": _make_side_branches(points, widths, rng, bool(edge.get("branch", false))),
    }

static func _boundary_point(room: Dictionary, direction: Vector2) -> Vector2:
    var half_size: Vector2 = room["size"] * 0.5
    # Ray/ellipse intersection gives a clean organic room-to-corridor handoff.
    var denom := sqrt(
        (direction.x * direction.x) / maxf(half_size.x * half_size.x, 1.0)
        + (direction.y * direction.y) / maxf(half_size.y * half_size.y, 1.0)
    )
    var radius := 1.0 / maxf(denom, 0.001)
    return room["position"] + direction * radius * 0.86

static func _make_side_branches(points: PackedVector2Array, widths: PackedFloat32Array, rng: RandomNumberGenerator, enabled: bool) -> Array[Dictionary]:
    var branches: Array[Dictionary] = []
    if not enabled or points.size() < 8:
        return branches
    # A capped bronchiole/dendrite branch communicates living anatomy without creating a gameplay path.
    var index := rng.randi_range(3, points.size() - 4)
    var tangent := (points[index + 1] - points[index - 1]).normalized()
    var sign := 1.0 if rng.randf() > 0.5 else -1.0
    var direction := tangent.rotated(sign * rng.randf_range(0.70, 1.05))
    var start := points[index]
    var length := rng.randf_range(100.0, 210.0)
    var end := start + direction * length
    var c1 := start + direction.rotated(sign * 0.25) * length * 0.34
    var c2 := end - direction.rotated(sign * 0.18) * length * 0.24
    var branch_points := PackedVector2Array()
    var branch_widths := PackedFloat32Array()
    var count := 8
    for i in range(count + 1):
        var t := float(i) / float(count)
        branch_points.append(_cubic_bezier(start, c1, c2, end, t))
        branch_widths.append(maxf(44.0, widths[index] * lerpf(0.52, 0.24, t)))
    branches.append({"points": branch_points, "widths": branch_widths, "capped": true})
    return branches

static func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
    var inv_t := 1.0 - t
    return p0 * inv_t * inv_t * inv_t \
        + p1 * 3.0 * inv_t * inv_t * t \
        + p2 * 3.0 * inv_t * t * t \
        + p3 * t * t * t
