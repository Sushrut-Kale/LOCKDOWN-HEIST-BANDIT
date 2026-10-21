# scripts/objects/fuse_box.gd
class_name FuseBox
extends Area2D

@onready var prompt_label: Label = $PromptLabel
@onready var sprite: Sprite2D = $Sprite2D

var is_tripped: bool = false
var repair_timer: float = 0.0

func _ready() -> void:
	prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if is_tripped:
		repair_timer -= delta
		if repair_timer <= 0.0:
			is_tripped = false
			sprite.modulate = Color.WHITE
			prompt_label.text = "[E] Sabotage Fuse Box"

func _unhandled_input(event: InputEvent) -> void:
	if prompt_label.visible and not is_tripped:
		if event.is_action_pressed("interact"):
			trip_fuses()

func trip_fuses() -> void:
	is_tripped = true
	repair_timer = 12.0
	sprite.modulate = Color(0.5, 0.5, 0.5, 1.0)
	prompt_label.text = "FUSE BLOWN (12s)"
	AudioManager.play_sfx("ui_click")
	JuiceManager.add_trauma(0.3)
	
	# Emit loud spark noise to attract nearest guard to fix it!
	Events.sound_emitted.emit(global_position, 220.0, true)

func _on_body_entered(body: Node2D) -> void:
	if body is BanditPlayer:
		prompt_label.visible = true
		prompt_label.text = "FUSE BLOWN" if is_tripped else "[E] Sabotage Fuse Box"

func _on_body_exited(body: Node2D) -> void:
	if body is BanditPlayer:
		prompt_label.visible = false
