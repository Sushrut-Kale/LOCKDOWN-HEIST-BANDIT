# scripts/ui/pause_menu.gd
extends Control

@onready var btn_resume: Button = $Panel/VBox/BtnResume
@onready var btn_manual: Button = $Panel/VBox/BtnManual
@onready var btn_settings: Button = $Panel/VBox/BtnSettings
@onready var btn_restart: Button = $Panel/VBox/BtnRestart
@onready var btn_menu: Button = $Panel/VBox/BtnMenu

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	
	btn_resume.pressed.connect(_on_resume)
	btn_manual.pressed.connect(_on_manual)
	btn_settings.pressed.connect(_on_settings)
	btn_restart.pressed.connect(_on_restart)
	btn_menu.pressed.connect(_on_menu)

func _on_resume() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().paused = false
	queue_free()

func _on_manual() -> void:
	AudioManager.play_sfx("ui_click")
	var m = load("res://scenes/ui/HowToPlayModal.tscn").instantiate()
	add_child(m)

func _on_settings() -> void:
	AudioManager.play_sfx("ui_click")
	var s = load("res://scenes/ui/SettingsModal.tscn").instantiate()
	add_child(s)

func _on_restart() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().paused = false
	GameManager.restart_level()

func _on_menu() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
