# scripts/objects/treasure_gem.gd
class_name TreasureGem
extends Area2D

@export var value: int = 15
@onready var sprite: Sprite2D = $Sprite2D

var bob_timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	bob_timer += delta * 5.0
	sprite.position.y = sin(bob_timer) * 3.0
	sprite.scale = Vector2.ONE * (1.0 + sin(bob_timer * 2.0) * 0.08)

func _on_body_entered(body: Node2D) -> void:
	if body is BanditPlayer:
		Events.coin_collected.emit(value, GameManager.level_total_coins)
		AudioManager.play_sfx("coin_pickup", 0.0)
		JuiceManager.add_trauma(0.3)
		queue_free()
