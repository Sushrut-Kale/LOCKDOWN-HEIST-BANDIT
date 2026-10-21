# scripts/objects/smoke_cloud.gd
class_name SmokeCloud
extends Area2D

const GameConfig = preload("res://scripts/systems/game_config.gd")


var lifetime: float = GameConfig.SMOKE_CLOUD_DURATION
var cloud_radius: float = 85.0

func _ready() -> void:
	add_to_group("smoke_clouds")
	AudioManager.play_sfx("vent_open")
	JuiceManager.add_trauma(0.25)
	
	# Scale animation
	scale = Vector2(0.2, 0.2)
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)

func _process(delta: float) -> void:
	lifetime -= delta
	queue_redraw()
	if lifetime <= 0.0:
		var tw = create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.4)
		tw.tween_callback(queue_free)

func _draw() -> void:
	var alpha = clampf(lifetime / GameConfig.SMOKE_CLOUD_DURATION, 0.0, 1.0) * 0.85
	# Overlapping soft smoke puffs
	var puffs = [
		Vector2(0, 0), Vector2(-25, -15), Vector2(25, -10),
		Vector2(-15, 20), Vector2(20, 18), Vector2(0, -30)
	]
	for p in puffs:
		draw_circle(p, 42.0, Color(0.85, 0.9, 0.95, alpha * 0.5))
		draw_circle(p, 28.0, Color(0.95, 0.98, 1.0, alpha * 0.7))
