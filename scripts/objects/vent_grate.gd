# scripts/objects/vent_grate.gd
class_name VentGrate
extends StaticBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var col_shape: CollisionShape2D = $CollisionShape2D

var is_open: bool = false

func _ready() -> void:
	# Starts sealed: frame 0, blocks all
	sprite.frame = 0
	col_shape.set_deferred("disabled", false)
	# Collision mask: Layer 2 (Player) and Layer 3 (Guards)
	Events.lockdown_initiated.connect(_on_lockdown)

func _on_lockdown() -> void:
	is_open = true
	sprite.frame = 1 # Glowing green vent
	# Allow Bandit (Layer 2) to pass, but keep blocking Guards (Layer 3)
	# By clearing collision with Player (Layer 2)
	set_collision_layer_value(2, false)
	set_collision_mask_value(2, false)
	# Still blocks Layer 3 (Guards)
	set_collision_layer_value(3, true)
	set_collision_mask_value(3, true)
