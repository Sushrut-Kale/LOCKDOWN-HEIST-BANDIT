# scripts/ui/main_menu.gd
extends Control

@onready var btn_campaign: Button = $VBoxContainer/BtnCampaign
@onready var btn_daily: Button = $VBoxContainer/BtnDaily
@onready var btn_custom: Button = $VBoxContainer/BtnCustom
@onready var btn_hideout: Button = $VBoxContainer/BtnHideout
@onready var btn_manual: Button = $VBoxContainer/BtnManual
@onready var btn_settings: Button = $VBoxContainer/BtnSettings
@onready var btn_quit: Button = $VBoxContainer/BtnQuit

@onready var custom_seed_dialog: ConfirmationDialog = $CustomSeedDialog
@onready var seed_input: LineEdit = $CustomSeedDialog/VBox/SeedInput
@onready var flashlight_cone: Node2D = $Background/FlashlightBeams
@onready var bandit_peek: Sprite2D = $Background/BanditPeek

var sweep_angle: float = 0.0

func _ready() -> void:
	AudioManager.play_menu_music()
	
	btn_campaign.pressed.connect(_on_campaign_pressed)
	btn_daily.pressed.connect(_on_daily_pressed)
	btn_custom.pressed.connect(_on_custom_pressed)
	btn_hideout.pressed.connect(_on_hideout_pressed)
	btn_manual.pressed.connect(_on_manual_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	
	custom_seed_dialog.confirmed.connect(_on_custom_seed_confirmed)

func _process(delta: float) -> void:
	# Live animated sweeping flashlight beams on main menu
	sweep_angle += delta * 1.2
	if flashlight_cone:
		flashlight_cone.rotation = sin(sweep_angle) * 0.45
	if bandit_peek:
		bandit_peek.position.y = 520 + sin(sweep_angle * 0.8) * 8.0

func _on_campaign_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	GameManager.start_campaign(SaveManager.highest_floor)

func _on_daily_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	GameManager.start_daily_heist()

func _on_custom_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	custom_seed_dialog.popup_centered()

func _on_custom_seed_confirmed() -> void:
	var text = seed_input.text.strip_edges()
	var val = text.to_int() if text.is_valid_int() else hash(text) & 0x7FFFFFFF
	GameManager.start_custom_seed(val, 1)

func _on_hideout_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	var modal = load("res://scenes/ui/HideoutModal.tscn").instantiate()
	add_child(modal)

func _on_manual_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	var modal = load("res://scenes/ui/HowToPlayModal.tscn").instantiate()
	add_child(modal)

func _on_settings_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	var modal = load("res://scenes/ui/SettingsModal.tscn").instantiate()
	add_child(modal)

func _on_quit_pressed() -> void:
	get_tree().quit()
