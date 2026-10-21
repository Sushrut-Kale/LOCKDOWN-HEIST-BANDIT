# scripts/ui/level_complete.gd
extends Control

@onready var lbl_headline: Label = $PaperPanel/Headline
@onready var lbl_loot: Label = $PaperPanel/StatsBox/LootCount
@onready var lbl_time: Label = $PaperPanel/StatsBox/TimeCount
@onready var star1: TextureRect = $PaperPanel/StarsBox/Star1
@onready var star2: TextureRect = $PaperPanel/StarsBox/Star2
@onready var star3: TextureRect = $PaperPanel/StarsBox/Star3
@onready var ribbon_ghost: TextureRect = $PaperPanel/RibbonsBox/RibbonGhost
@onready var ribbon_sweep: TextureRect = $PaperPanel/RibbonsBox/RibbonSweep

@onready var btn_next: Button = $PaperPanel/ActionsBox/BtnNext
@onready var btn_copy_seed: Button = $PaperPanel/ActionsBox/BtnCopySeed
@onready var btn_menu: Button = $PaperPanel/ActionsBox/BtnMenu

func _ready() -> void:
	var fl = GameManager.current_floor
	lbl_headline.text = "BANDIT BAFFLES POLICE ON FLOOR %d!" % fl
	lbl_loot.text = "COINS BANKED: +%d COINS" % GameManager.level_coins_collected
	
	var sec = int(GameManager.level_elapsed_seconds)
	lbl_time.text = "ESCAPE TIME: %02d:%02d" % [sec / 60, sec % 60]
	
	# Determine badges
	var star_escape = true
	var star_coins = (float(GameManager.level_coins_collected) / float(max(1, GameManager.level_total_coins))) >= 0.70
	var star_stealth = (not GameManager.is_spotted_ever) or (GameManager.level_elapsed_seconds < GameManager.get_par_time(fl))
	
	var star_tex_filled = load("res://assets/ui/star_filled.png")
	var star_tex_empty = load("res://assets/ui/star_empty.png")
	
	star1.texture = star_tex_filled if star_escape else star_tex_empty
	star2.texture = star_tex_filled if star_coins else star_tex_empty
	star3.texture = star_tex_filled if star_stealth else star_tex_empty
	
	ribbon_ghost.visible = not GameManager.is_spotted_ever
	ribbon_sweep.visible = (GameManager.level_coins_collected >= GameManager.level_total_coins and GameManager.level_total_coins > 0)
	
	btn_next.pressed.connect(func():
		AudioManager.play_sfx("ui_click")
		GameManager.next_floor()
	)
	
	btn_copy_seed.pressed.connect(func():
		AudioManager.play_sfx("ui_click")
		DisplayServer.clipboard_set(str(GameManager.current_seed))
		btn_copy_seed.text = "COPIED!"
	)
	
	btn_menu.pressed.connect(func():
		AudioManager.play_sfx("ui_click")
		get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
	)
	
	_animate_newspaper_entry()

func _animate_newspaper_entry() -> void:
	var panel = $PaperPanel
	panel.scale = Vector2(0.2, 0.2)
	panel.rotation = deg_to_rad(-15.0)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "rotation", 0.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	AudioManager.play_sfx("star_stamp")
