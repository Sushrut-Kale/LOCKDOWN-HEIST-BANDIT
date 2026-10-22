# scripts/ui/settings_modal.gd
extends Control

@onready var sld_master: HSlider = $Panel/Scroll/VBox/MasterSlider
@onready var sld_music: HSlider = $Panel/Scroll/VBox/MusicSlider
@onready var sld_sfx: HSlider = $Panel/Scroll/VBox/SFXSlider
@onready var sld_shake: HSlider = $Panel/Scroll/VBox/ShakeSlider
@onready var opt_quality: OptionButton = $Panel/Scroll/VBox/QualityOption
@onready var opt_touch: OptionButton = $Panel/Scroll/VBox/TouchOption
@onready var opt_hand: OptionButton = $Panel/Scroll/VBox/HandOption
@onready var sld_joy_opacity: HSlider = $Panel/Scroll/VBox/JoystickOpacitySlider
@onready var chk_haptics: CheckBox = $Panel/Scroll/VBox/HapticsCheck
@onready var chk_colorblind: CheckBox = $Panel/Scroll/VBox/ColorblindCheck
@onready var chk_stats: CheckBox = $Panel/Scroll/VBox/StatsCheck
@onready var opt_notch: OptionButton = $Panel/Scroll/VBox/NotchOption
@onready var btn_close: Button = $Panel/BtnClose

func _ready() -> void:
	btn_close.pressed.connect(func():
		AudioManager.play_sfx("ui_click")
		SaveManager.save_game()
		queue_free()
	)
	
	# Sliders
	sld_master.value = SaveManager.master_volume * 100.0
	sld_music.value = SaveManager.music_volume * 100.0
	sld_sfx.value = SaveManager.sfx_volume * 100.0
	sld_shake.value = SaveManager.screen_shake_intensity * 100.0
	sld_joy_opacity.value = SaveManager.touch_joystick_opacity * 100.0
	
	chk_haptics.button_pressed = SaveManager.haptics_enabled
	chk_colorblind.button_pressed = SaveManager.colorblind_mode
	chk_stats.button_pressed = SaveManager.show_hud_stats
	
	# Quality Option
	opt_quality.clear()
	opt_quality.add_item("High (60 FPS, Full Dynamic Shadows)", 0)
	opt_quality.add_item("Medium (Balanced Shadows & FX)", 1)
	opt_quality.add_item("Low (Battery Saver / Older Devices)", 2)
	match SaveManager.quality_tier:
		"high": opt_quality.selected = 0
		"low": opt_quality.selected = 2
		_: opt_quality.selected = 1
	
	# Touch Option
	opt_touch.clear()
	opt_touch.add_item("Auto-Detect", 0)
	opt_touch.add_item("Force On", 1)
	opt_touch.add_item("Off", 2)
	match SaveManager.touch_controls_mode:
		"force_on": opt_touch.selected = 1
		"off": opt_touch.selected = 2
		_: opt_touch.selected = 0
		
	# Handedness Option
	opt_hand.clear()
	opt_hand.add_item("Right-Handed (Joystick Left, Buttons Right)", 0)
	opt_hand.add_item("Left-Handed (Joystick Right, Buttons Left)", 1)
	opt_hand.selected = 1 if SaveManager.touch_cluster_hand == "left" else 0

	# Notch Simulation Option
	opt_notch.clear()
	opt_notch.add_item("None (Default Device Safe Area)", 0)
	opt_notch.add_item("Left Notch (Cutout left)", 1)
	opt_notch.add_item("Right Notch (Cutout right)", 2)
	opt_notch.add_item("Punch Hole / Top Center", 3)
	match SaveManager.simulate_notch:
		"left": opt_notch.selected = 1
		"right": opt_notch.selected = 2
		"cutout": opt_notch.selected = 3
		_: opt_notch.selected = 0
		
	# Event wiring
	sld_master.value_changed.connect(func(v):
		SaveManager.master_volume = v / 100.0
		SaveManager.update_audio_buses()
	)
	sld_music.value_changed.connect(func(v):
		SaveManager.music_volume = v / 100.0
		SaveManager.update_audio_buses()
	)
	sld_sfx.value_changed.connect(func(v):
		SaveManager.sfx_volume = v / 100.0
		SaveManager.update_audio_buses()
	)
	sld_shake.value_changed.connect(func(v): SaveManager.screen_shake_intensity = v / 100.0)
	sld_joy_opacity.value_changed.connect(func(v): SaveManager.touch_joystick_opacity = v / 100.0)
	
	chk_haptics.toggled.connect(func(b):
		SaveManager.haptics_enabled = b
		if b: SaveManager.trigger_haptic(40)
	)
	chk_colorblind.toggled.connect(func(b): SaveManager.colorblind_mode = b)
	chk_stats.toggled.connect(func(b): SaveManager.show_hud_stats = b)
	
	opt_quality.item_selected.connect(func(idx):
		match idx:
			0: SaveManager.quality_tier = "high"
			2: SaveManager.quality_tier = "low"
			_: SaveManager.quality_tier = "medium"
		SaveManager.apply_quality_settings()
	)
	
	opt_touch.item_selected.connect(func(idx):
		match idx:
			1: SaveManager.touch_controls_mode = "force_on"
			2: SaveManager.touch_controls_mode = "off"
			_: SaveManager.touch_controls_mode = "auto"
	)

	opt_hand.item_selected.connect(func(idx):
		SaveManager.touch_cluster_hand = "left" if idx == 1 else "right"
	)

	opt_notch.item_selected.connect(func(idx):
		match idx:
			1: SaveManager.simulate_notch = "left"
			2: SaveManager.simulate_notch = "right"
			3: SaveManager.simulate_notch = "cutout"
			_: SaveManager.simulate_notch = "none"
	)
