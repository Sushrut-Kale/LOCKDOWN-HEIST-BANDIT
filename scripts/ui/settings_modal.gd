# scripts/ui/settings_modal.gd
extends Control

@onready var sld_master: HSlider = $Panel/VBox/MasterSlider
@onready var sld_music: HSlider = $Panel/VBox/MusicSlider
@onready var sld_sfx: HSlider = $Panel/VBox/SFXSlider
@onready var sld_shake: HSlider = $Panel/VBox/ShakeSlider
@onready var opt_touch: OptionButton = $Panel/VBox/TouchOption
@onready var chk_colorblind: CheckBox = $Panel/VBox/ColorblindCheck
@onready var chk_stats: CheckBox = $Panel/VBox/StatsCheck
@onready var btn_close: Button = $Panel/BtnClose

func _ready() -> void:
	btn_close.pressed.connect(func():
		AudioManager.play_sfx("ui_click")
		SaveManager.save_game()
		queue_free()
	)
	
	sld_master.value = SaveManager.master_volume * 100.0
	sld_music.value = SaveManager.music_volume * 100.0
	sld_sfx.value = SaveManager.sfx_volume * 100.0
	sld_shake.value = SaveManager.screen_shake_intensity * 100.0
	chk_colorblind.button_pressed = SaveManager.colorblind_mode
	chk_stats.button_pressed = SaveManager.show_hud_stats
	
	opt_touch.clear()
	opt_touch.add_item("Auto-Detect", 0)
	opt_touch.add_item("Force On", 1)
	opt_touch.add_item("Off", 2)
	
	match SaveManager.touch_controls_mode:
		"force_on": opt_touch.selected = 1
		"off": opt_touch.selected = 2
		_: opt_touch.selected = 0
		
	sld_master.value_changed.connect(func(v): SaveManager.master_volume = v / 100.0)
	sld_music.value_changed.connect(func(v): SaveManager.music_volume = v / 100.0)
	sld_sfx.value_changed.connect(func(v): SaveManager.sfx_volume = v / 100.0)
	sld_shake.value_changed.connect(func(v): SaveManager.screen_shake_intensity = v / 100.0)
	chk_colorblind.toggled.connect(func(b): SaveManager.colorblind_mode = b)
	chk_stats.toggled.connect(func(b): SaveManager.show_hud_stats = b)
	
	opt_touch.item_selected.connect(func(idx):
		match idx:
			1: SaveManager.touch_controls_mode = "force_on"
			2: SaveManager.touch_controls_mode = "off"
			_: SaveManager.touch_controls_mode = "auto"
	)
