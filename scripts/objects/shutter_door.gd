# scripts/objects/shutter_door.gd
class_name ShutterDoor
extends StaticBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var col_shape: CollisionShape2D = $CollisionShape2D

var is_closed: bool = false

func _ready() -> void:
	# Starts open: frame 0, collision disabled
	sprite.frame = 0
	col_shape.set_deferred("disabled", true)
	Events.lockdown_initiated.connect(_on_lockdown)

func _on_lockdown() -> void:
	is_closed = true
	# Animate closing to frame 2
	var tw = create_tween()
	tw.tween_property(sprite, "frame", 1, 0.15)
	tw.tween_property(sprite, "frame", 2, 0.15)
	col_shape.set_deferred("disabled", false)
