# scripts/ui/game_over.gd
extends Control

@onready var lbl_cause: Label = $Panel/VBox/CauseLabel
@onready var lbl_lost: Label = $Panel/VBox/LostLabel
@onready var btn_retry: Button = $Panel/VBox/BtnRetry
@onready var btn_new_seed: Button = $Panel/VBox/BtnNewSeed
@onready var btn_menu: Button = $Panel/VBox/BtnMenu

func _ready() -> void:
	lbl_cause.text = "CAPTURED BY: %s!" % GameManager.caught_culprit.to_upper()
	lbl_lost.text = "LOST IN THE SACK: %d COINS" % GameManager.level_coins_collected
	
	btn_retry.pressed.connect(_on_retry)
	btn_new_seed.pressed.connect(_on_new_seed)
	btn_menu.pressed.connect(_on_menu)

func _unhandled_input(event: InputEvent) -> void:
	# 0.1s rapid instant retry on space or enter or tap
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_on_retry()

func _on_retry() -> void:
	AudioManager.play_sfx("ui_click")
	GameManager.restart_level()

func _on_new_seed() -> void:
	AudioManager.play_sfx("ui_click")
	GameManager.current_seed = randi() % 1000000
	GameManager.restart_level()

func _on_menu() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
