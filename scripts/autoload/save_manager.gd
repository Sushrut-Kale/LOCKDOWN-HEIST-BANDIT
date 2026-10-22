# scripts/autoload/save_manager.gd
extends Node

const SAVE_PATH: String = "user://save_data.json"

enum QualityTier { LOW = 0, MEDIUM = 1, HIGH = 2 }

var banked_coins: int = 0
var highest_floor: int = 1
var total_stars: int = 0
var unlocked_suits: Array = ["classic_bandit"]
var equipped_suit: String = "classic_bandit"
var unlocked_gadgets: Array = ["smoke_pellet"]
var equipped_gadget: String = "smoke_pellet"

# Android & Gameplay Settings
var master_volume: float = 0.7
var music_volume: float = 0.7
var sfx_volume: float = 0.7
var screen_shake_intensity: float = 1.0
var touch_controls_mode: String = "auto" # "auto", "force_on", "off"
var touch_cluster_hand: String = "right" # "right", "left"
var touch_joystick_opacity: float = 0.85
var colorblind_mode: bool = false
var show_hud_stats: bool = false # hidden by default on Android
var haptics_enabled: bool = true
var quality_tier: String = "medium" # "low", "medium", "high"
var simulate_notch: String = "none" # "none", "left", "right", "cutout"
var seen_tutorial: bool = false

# Process Death / Mid-run persistence
var interrupted_run: Dictionary = {}

func _ready() -> void:
	load_game()
	update_audio_buses()
	apply_quality_settings()

func save_game() -> void:
	var data: Dictionary = {
		"banked_coins": banked_coins,
		"highest_floor": highest_floor,
		"total_stars": total_stars,
		"unlocked_suits": unlocked_suits,
		"equipped_suit": equipped_suit,
		"unlocked_gadgets": unlocked_gadgets,
		"equipped_gadget": equipped_gadget,
		"seen_tutorial": seen_tutorial,
		"interrupted_run": interrupted_run,
		"settings": {
			"master_volume": master_volume,
			"music_volume": music_volume,
			"sfx_volume": sfx_volume,
			"screen_shake_intensity": screen_shake_intensity,
			"touch_controls_mode": touch_controls_mode,
			"touch_cluster_hand": touch_cluster_hand,
			"touch_joystick_opacity": touch_joystick_opacity,
			"colorblind_mode": colorblind_mode,
			"show_hud_stats": show_hud_stats,
			"haptics_enabled": haptics_enabled,
			"quality_tier": quality_tier,
			"simulate_notch": simulate_notch
		}
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		# Default quality for mobile
		if OS.has_feature("mobile") or OS.has_feature("android"):
			quality_tier = "medium"
			show_hud_stats = false
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text = file.get_as_text()
	file.close()
	var json = JSON.new()
	var err = json.parse(text)
	if err == OK and json.data is Dictionary:
		var d = json.data
		banked_coins = d.get("banked_coins", banked_coins)
		highest_floor = d.get("highest_floor", highest_floor)
		total_stars = d.get("total_stars", total_stars)
		unlocked_suits = d.get("unlocked_suits", unlocked_suits)
		equipped_suit = d.get("equipped_suit", equipped_suit)
		unlocked_gadgets = d.get("unlocked_gadgets", unlocked_gadgets)
		equipped_gadget = d.get("equipped_gadget", equipped_gadget)
		seen_tutorial = d.get("seen_tutorial", seen_tutorial)
		interrupted_run = d.get("interrupted_run", interrupted_run)
		
		var s = d.get("settings", {})
		master_volume = s.get("master_volume", master_volume)
		music_volume = s.get("music_volume", music_volume)
		sfx_volume = s.get("sfx_volume", sfx_volume)
		screen_shake_intensity = s.get("screen_shake_intensity", screen_shake_intensity)
		touch_controls_mode = s.get("touch_controls_mode", touch_controls_mode)
		touch_cluster_hand = s.get("touch_cluster_hand", touch_cluster_hand)
		touch_joystick_opacity = s.get("touch_joystick_opacity", touch_joystick_opacity)
		colorblind_mode = s.get("colorblind_mode", colorblind_mode)
		show_hud_stats = s.get("show_hud_stats", show_hud_stats)
		haptics_enabled = s.get("haptics_enabled", haptics_enabled)
		quality_tier = s.get("quality_tier", quality_tier)
		simulate_notch = s.get("simulate_notch", simulate_notch)

func add_banked_coins(amount: int) -> void:
	banked_coins = clampi(banked_coins + amount, 0, 999999)
	save_game()

func record_level_clear(floor_num: int, stars: int) -> void:
	if floor_num >= highest_floor:
		highest_floor = floor_num + 1
	total_stars += stars
	save_game()

func unlock_item(category: String, item_id: String, cost: int) -> bool:
	if banked_coins < cost:
		return false
	if category == "suit":
		if not unlocked_suits.has(item_id):
			banked_coins -= cost
			unlocked_suits.append(item_id)
			equipped_suit = item_id
			save_game()
			return true
	elif category == "gadget":
		if not unlocked_gadgets.has(item_id):
			banked_coins -= cost
			unlocked_gadgets.append(item_id)
			equipped_gadget = item_id
			save_game()
			return true
	return false

# Audio volume conversion and update
func update_audio_buses() -> void:
	var master_idx = AudioServer.get_bus_index("Master")
	var music_idx = AudioServer.get_bus_index("Music")
	var sfx_idx = AudioServer.get_bus_index("SFX")
	
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(clampf(master_volume, 0.0001, 1.0)))
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(clampf(music_volume, 0.0001, 1.0)))
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(clampf(sfx_volume, 0.0001, 1.0)))

# Haptics
func trigger_haptic(duration_ms: int = 40) -> void:
	if not haptics_enabled:
		return
	if OS.has_feature("android") or OS.has_feature("mobile"):
		Input.vibrate_handheld(duration_ms)

# Performance & Quality tiers
func apply_quality_settings() -> void:
	match quality_tier:
		"low":
			Engine.max_fps = 45 if OS.has_feature("mobile") else 60
		"medium":
			Engine.max_fps = 60
		"high":
			Engine.max_fps = 60

func get_max_shadow_casting_guards() -> int:
	match quality_tier:
		"low": return 3
		"medium": return 6
		"high": return 12
		_: return 6

func get_particle_multiplier() -> float:
	match quality_tier:
		"low": return 0.4
		"medium": return 0.75
		"high": return 1.0
		_: return 0.75

# Interrupted Run Persistence (Phase 1.4)
func save_interrupted_run(fl: int, sd: int, coins: int, loadout: Dictionary, is_d: bool) -> void:
	interrupted_run = {
		"floor": fl,
		"seed": sd,
		"coins": coins,
		"loadout": loadout,
		"is_daily": is_d,
		"timestamp": Time.get_unix_time_from_system()
	}
	save_game()

func clear_interrupted_run() -> void:
	interrupted_run = {}
	save_game()

func has_interrupted_run() -> bool:
	return interrupted_run != null and not interrupted_run.is_empty() and interrupted_run.get("floor", 0) > 0
