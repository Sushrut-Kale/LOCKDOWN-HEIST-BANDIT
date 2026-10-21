# scripts/objects/marbles_hazard.gd
class_name MarblesHazard
extends Area2D

const GameConfig = preload("res://scripts/systems/game_config.gd")


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Draw little scattered blue/white marbles
	queue_redraw()

func _draw() -> void:
	var offsets = [Vector2(-8, -4), Vector2(6, -6), Vector2(-4, 6), Vector2(8, 4), Vector2(0, 0)]
	for off in offsets:
		draw_circle(off, 3.5, Color(0.2, 0.8, 1.0, 0.9))
		draw_circle(off + Vector2(-1, -1), 1.2, Color(1, 1, 1, 0.95))

func _on_body_entered(body: Node2D) -> void:
	if body is GuardBase and body.current_state != "KNOCKED_OUT" and body.current_state != "CUFFED":
		AudioManager.play_sfx("knockout_bonk")
		JuiceManager.show_speech_bubble(body, "Whoa, whoa, BONK!", Color(1.0, 0.4, 0.4))
		body.apply_stun(GameConfig.MARBLES_STUN_DURATION)
		queue_free()
