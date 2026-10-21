# scripts/objects/exit_vault_door.gd
class_name ExitVaultDoor
extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
var is_unlocked: bool = false

func _ready() -> void:
	sprite.frame = 0 # Locked red
	body_entered.connect(_on_body_entered)
	Events.lockdown_initiated.connect(_on_lockdown)

func _on_lockdown() -> void:
	is_unlocked = true
	sprite.frame = 1 # Unlocked green escape route
	AudioManager.play_sfx("vent_open")

func _on_body_entered(body: Node2D) -> void:
	if body is BanditPlayer and is_unlocked:
		Events.level_escaped.emit()
