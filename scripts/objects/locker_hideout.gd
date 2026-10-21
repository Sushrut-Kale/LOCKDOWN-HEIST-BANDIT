# scripts/objects/locker_hideout.gd
class_name LockerHideout
extends Area2D

@onready var prompt_label: Label = $PromptLabel
var player_inside: BanditPlayer = null
var is_occupying: bool = false

func _ready() -> void:
	prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_inside:
		if Input.is_action_just_pressed("interact"):
			toggle_hide()

func toggle_hide() -> void:
	if not player_inside:
		return
	is_occupying = not is_occupying
	player_inside.is_hidden = is_occupying
	player_inside.visible = not is_occupying
	Events.player_hidden_state_changed.emit(is_occupying)
	AudioManager.play_sfx("vent_open")
	prompt_label.text = "[E] Exit Locker" if is_occupying else "[E] Hide in Locker"

func _on_body_entered(body: Node2D) -> void:
	if body is BanditPlayer:
		player_inside = body
		prompt_label.visible = true
		prompt_label.text = "[E] Hide in Locker"

func _on_body_exited(body: Node2D) -> void:
	if body == player_inside:
		if is_occupying:
			toggle_hide()
		player_inside = null
		prompt_label.visible = false
