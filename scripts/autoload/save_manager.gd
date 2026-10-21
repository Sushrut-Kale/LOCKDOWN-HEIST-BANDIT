# scripts/autoload/save_manager.gd
extends Node

const SAVE_PATH: String = "user://save_data.json"

var banked_coins: int = 0
var highest_floor: int = 1
var total_stars: int = 0
var unlocked_suits: Array = ["classic_bandit"]
var equipped_suit: String = "classic_bandit"
var unlocked_gadgets: Array = ["smoke_pellet"]
var equipped_gadget: String = "smoke_pellet"

# Settings
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 0.9
var screen_shake_intensity: float = 1.0
var touch_controls_mode: String = "auto" # "auto", "force_on", "off"
var colorblind_mode: bool = false
var show_hud_stats: bool = true

func _ready() -> void:
	load_game()

func save_game() -> void:
	var data: Dictionary = {
		"banked_coins": banked_coins,
		"highest_floor": highest_floor,
		"total_stars": total_stars,
		"unlocked_suits": unlocked_suits,
		"equipped_suit": equipped_suit,
		"unlocked_gadgets": unlocked_gadgets,
		"equipped_gadget": equipped_gadget,
		"settings": {
			"master_volume": master_volume,
			"music_volume": music_volume,
			"sfx_volume": sfx_volume,
			"screen_shake_intensity": screen_shake_intensity,
			"touch_controls_mode": touch_controls_mode,
			"colorblind_mode": colorblind_mode,
			"show_hud_stats": show_hud_stats
		}
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
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
		
		var s = d.get("settings", {})
		master_volume = s.get("master_volume", master_volume)
		music_volume = s.get("music_volume", music_volume)
		sfx_volume = s.get("sfx_volume", sfx_volume)
		screen_shake_intensity = s.get("screen_shake_intensity", screen_shake_intensity)
		touch_controls_mode = s.get("touch_controls_mode", touch_controls_mode)
		colorblind_mode = s.get("colorblind_mode", colorblind_mode)
		show_hud_stats = s.get("show_hud_stats", show_hud_stats)

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
