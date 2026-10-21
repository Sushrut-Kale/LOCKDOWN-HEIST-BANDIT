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
	Events.coin_collected.connect(func(amt, _tot): level_coins_collected += amt)
	Events.lockdown_initiated.connect(func(): is_lockdown_active = true)
	Events.player_caught.connect(_on_player_caught)
	Events.level_escaped.connect(_on_level_escaped)

func start_campaign(floor_num: int = 1) -> void:
	current_floor = floor_num
	is_daily = false
	current_seed = randi() % 1000000 + current_floor * 777
	_load_game_scene()

func start_daily_heist() -> void:
	is_daily = true
	current_floor = 1
	var d = Time.get_date_dict_from_system()
	daily_date_str = "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]
	# Deterministic seed from date
	current_seed = hash(daily_date_str) & 0x7FFFFFFF
	_load_game_scene()

func start_custom_seed(seed_val: int, floor_num: int = 1) -> void:
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
	caught_culprit = culprit
	# 0.1s instant reload capability
	get_tree().change_scene_to_file("res://scenes/ui/GameOver.tscn")

func _on_level_escaped() -> void:
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
	
	get_tree().change_scene_to_file("res://scenes/ui/LevelComplete.tscn")

func get_par_time(fl: int) -> float:
	return 45.0 + float(fl) * 5.0

func get_grid_width(fl: int) -> int:
	var w = clampi(15 + 2 * (fl - 1), 15, 45)
	if w % 2 == 0:
		w += 1
	return w

func get_guard_count(fl: int) -> int:
	return clampi(2 + int(floor(0.12 * pow(fl - 1, 1.5))), 2, 26)

# Weight slowdown for greed bag
# Light 0-14, Medium 15-34 (-6%), Heavy 35+ (-12%)
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
