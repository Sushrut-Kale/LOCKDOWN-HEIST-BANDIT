# scripts/objects/master_key.gd
class_name MasterKey
extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var light_glow: PointLight2D = $PointLight2D

var bob_timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	bob_timer += delta * 3.0
	sprite.position.y = sin(bob_timer) * 4.0
	if light_glow:
		light_glow.energy = 1.0 + sin(bob_timer * 1.5) * 0.3

func _on_body_entered(body: Node2D) -> void:
	if body is BanditPlayer:
		Events.key_collected.emit()
		Events.lockdown_initiated.emit()
		queue_free()
