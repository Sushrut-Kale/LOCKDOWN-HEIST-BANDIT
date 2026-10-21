# scripts/objects/coin_pickup.gd
class_name CoinPickup
extends Area2D

@export var value: int = 1
@onready var sprite: Sprite2D = $Sprite2D

var bob_timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	bob_timer = randf() * TAU

func _process(delta: float) -> void:
	bob_timer += delta * 4.0
	sprite.position.y = sin(bob_timer) * 2.5

func _on_body_entered(body: Node2D) -> void:
	if body is BanditPlayer:
		Events.coin_collected.emit(value, GameManager.level_total_coins)
		queue_free()
