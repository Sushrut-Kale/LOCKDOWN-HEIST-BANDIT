# scripts/autoload/game_manager.gd
extends Node

var current_floor: int = 1
var current_seed: int = 1337
var is_daily: bool = false
var daily_date_str: String = ""

var level_coins_collected: int = 0
var level_total_coins: int = 0
var level_start_ticks: int = 0
var level_elapsed_seconds: float = 0.0

var is_spotted_ever: bool = false
var is_lockdown_active: bool = false
var free_cuffs_remaining: int = 1
var marbles_remaining: int = 0
var smoke_pellets_remaining: int = 0

var caught_culprit: String = "Police Officer"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input_map()
	Events.coin_collected.connect(func(amt, _tot): level_coins_collected += amt)
	Events.lockdown_initiated.connect(func(): is_lockdown_active = true)
	Events.player_caught.connect(_on_player_caught)
	Events.level_escaped.connect(_on_level_escaped)

func _setup_input_map() -> void:
	var key_binds = {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"sprint": [KEY_SHIFT],
		"interact": [KEY_E],
		"toss_coin": [KEY_Q],
		"use_gadget": [KEY_F],
		"pause": [KEY_ESCAPE]
	}
	for action in key_binds:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in key_binds[action]:
			var ev = InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			# Duck or mute audio to respect OS audio focus
			var master_idx = AudioServer.get_bus_index("Master")
			if master_idx >= 0:
				AudioServer.set_bus_mute(master_idx, true)
			
			# Pause in-game action & persist mid-level progress
			if is_in_level() and not get_tree().paused:
				_pause_and_save_run()
		
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			var master_idx = AudioServer.get_bus_index("Master")
			if master_idx >= 0:
				AudioServer.set_bus_mute(master_idx, false)
			# Refresh volume
			SaveManager.update_audio_buses()

		NOTIFICATION_WM_GO_BACK_REQUEST:
			handle_back_request()

func handle_back_request() -> void:
	var root = get_tree().root
	var modals = ["SettingsModal", "HowToPlayModal", "HideoutModal", "PauseMenu", "ConfirmationDialog"]
	for m_name in modals:
		var found = root.find_child(m_name, true, false)
		if found and is_instance_valid(found) and found.is_inside_tree() and found.visible:
			if found is ConfirmationDialog:
				found.hide()
			elif found.has_method("_on_resume"):
				found._on_resume()
			else:
				found.queue_free()
			return

	# If in level, toggle pause
	if is_in_level():
		var level = get_tree().current_scene
		if level and level.has_method("_on_pause_button_pressed"):
			level._on_pause_button_pressed()
		return

	# If on MainMenu, show quit confirm dialog
	var current = get_tree().current_scene
	if current and current.name == "MainMenu":
		if current.has_method("show_quit_confirm_dialog"):
			current.show_quit_confirm_dialog()
		else:
			_show_fallback_quit_dialog()

func _show_fallback_quit_dialog() -> void:
	var dlg = ConfirmationDialog.new()
	dlg.title = "QUIT HEIST?"
	dlg.dialog_text = "Are you sure you want to exit the game?"
	dlg.ok_button_text = "Quit"
	dlg.cancel_button_text = "Stay"
	dlg.confirmed.connect(func(): get_tree().quit())
	get_tree().root.add_child(dlg)
	dlg.popup_centered()

func is_in_level() -> bool:
	var cur = get_tree().current_scene
	return cur != null and cur.name == "ProceduralLevel"

func _pause_and_save_run() -> void:
	# Persist floor, seed, coins so Android process kill is not a wipe
	SaveManager.save_interrupted_run(
		current_floor,
		current_seed,
		level_coins_collected,
		{"suit": SaveManager.equipped_suit, "gadget": SaveManager.equipped_gadget},
		is_daily
	)
	
	# Open PauseMenu if in level
	var level = get_tree().current_scene
	if level and level.has_node("HUD"):
		var hud = level.get_node("HUD")
		if not hud.has_node("PauseMenu"):
			var pause_modal = load("res://scenes/ui/PauseMenu.tscn").instantiate()
			hud.add_child(pause_modal)

func resume_interrupted_run() -> void:
	if not SaveManager.has_interrupted_run():
		return
	var r = SaveManager.interrupted_run
	current_floor = r.get("floor", 1)
	current_seed = r.get("seed", 1337)
	is_daily = r.get("is_daily", false)
	level_coins_collected = r.get("coins", 0)
	var loadout = r.get("loadout", {})
	if loadout.has("suit"):
		SaveManager.equipped_suit = loadout["suit"]
	if loadout.has("gadget"):
		SaveManager.equipped_gadget = loadout["gadget"]
	
	_load_game_scene()

func start_campaign(floor_num: int = 1) -> void:
	SaveManager.clear_interrupted_run()
	current_floor = floor_num
	is_daily = false
	current_seed = randi() % 1000000 + current_floor * 777
	_load_game_scene()

func start_daily_heist() -> void:
	SaveManager.clear_interrupted_run()
	is_daily = true
	current_floor = 1
	var d = Time.get_date_dict_from_system()
	daily_date_str = "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]
	# Deterministic seed from local date
	current_seed = hash(daily_date_str) & 0x7FFFFFFF
	_load_game_scene()

func start_custom_seed(seed_val: int, floor_num: int = 1) -> void:
	SaveManager.clear_interrupted_run()
	is_daily = false
	current_floor = floor_num
	current_seed = seed_val
	_load_game_scene()

func restart_level() -> void:
	_load_game_scene()

func next_floor() -> void:
	current_floor += 1
	current_seed = (current_seed * 1103515245 + 12345) & 0x7FFFFFFF
	_load_game_scene()

func _load_game_scene() -> void:
	# Keep screen active while playing
	DisplayServer.screen_set_keep_on(true)
	
	# Reset state
	level_coins_collected = 0
	level_total_coins = 0
	level_elapsed_seconds = 0.0
	is_spotted_ever = false
	is_lockdown_active = false
	level_start_ticks = Time.get_ticks_msec()
	
	# Apply gadgets
	free_cuffs_remaining = 1
	if SaveManager.equipped_gadget == "extra_ziptie":
		free_cuffs_remaining = 2
	marbles_remaining = 3 if SaveManager.equipped_gadget == "bag_marbles" else 0
	smoke_pellets_remaining = 1 if SaveManager.equipped_gadget == "smoke_pellet" else 0
	
	get_tree().change_scene_to_file("res://scenes/ui/LoadingScreen.tscn")

func _process(delta: float) -> void:
	if not get_tree().paused and level_start_ticks > 0:
		level_elapsed_seconds += delta

func _on_player_caught(culprit: String) -> void:
	DisplayServer.screen_set_keep_on(false)
	SaveManager.clear_interrupted_run()
	SaveManager.trigger_haptic(70)
	caught_culprit = culprit
	get_tree().change_scene_to_file("res://scenes/ui/GameOver.tscn")

func _on_level_escaped() -> void:
	DisplayServer.screen_set_keep_on(false)
	SaveManager.clear_interrupted_run()
	SaveManager.trigger_haptic(50)
	
	# Calculate stars
	var star_escape = true
	var star_coins = (float(level_coins_collected) / float(max(1, level_total_coins))) >= 0.70
	var star_stealth = (not is_spotted_ever) or (level_elapsed_seconds < get_par_time(current_floor))
	
	var stars = 0
	if star_escape: stars += 1
	if star_coins: stars += 1
	if star_stealth: stars += 1
	
	SaveManager.add_banked_coins(level_coins_collected)
	SaveManager.record_level_clear(current_floor, stars)
	
	get_tree().change_scene_to_file.call_deferred("res://scenes/ui/LevelComplete.tscn")

func get_par_time(fl: int) -> float:
	return 45.0 + float(fl) * 5.0

func get_grid_width(fl: int) -> int:
	var w = clampi(15 + 2 * (fl - 1), 15, 45)
	if w % 2 == 0:
		w += 1
	return w

func get_guard_count(fl: int) -> int:
	return clampi(2 + int(floor(0.12 * pow(fl - 1, 1.5))), 2, 26)

func get_bag_speed_multiplier() -> float:
	var c = level_coins_collected
	if SaveManager.equipped_suit == "silk_sack":
		c = int(c * 0.75) # 25% capacity bonus
	if c < 15:
		return 1.0
	elif c < 35:
		return 0.94
	else:
		return 0.88
