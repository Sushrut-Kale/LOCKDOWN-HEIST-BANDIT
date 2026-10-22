# scripts/ui/radial_progress.gd
extends Control

func _draw() -> void:
	var prog = get_meta("progress", 0.0)
	if prog > 0.01:
		var center = size * 0.5
		var r = minf(size.x, size.y) * 0.5 + 4.0
		var sweep = clampf(prog, 0.0, 1.0) * TAU
		draw_arc(center, r, -PI * 0.5, -PI * 0.5 + sweep, 36, Color(1.0, 0.85, 0.2, 0.95), 5.0)
