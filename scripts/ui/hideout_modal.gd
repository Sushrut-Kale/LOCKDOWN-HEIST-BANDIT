# scripts/ui/hideout_modal.gd
extends Control

@onready var lbl_banked: Label = $Panel/Header/BankedLabel
@onready var lbl_stars: Label = $Panel/Header/StarsLabel
@onready var btn_close: Button = $Panel/BtnClose

# Suits buttons
@onready var btn_suit_classic: Button = $Panel/Grid/SuitClassic/Btn
@onready var btn_suit_velvet: Button = $Panel/Grid/SuitVelvet/Btn
@onready var btn_suit_silk: Button = $Panel/Grid/SuitSilk/Btn
@onready var btn_suit_sprinter: Button = $Panel/Grid/SuitSprinter/Btn

# Gadgets buttons
@onready var btn_gadget_smoke: Button = $Panel/Grid/GadgetSmoke/Btn
@onready var btn_gadget_cuff: Button = $Panel/Grid/GadgetCuff/Btn
@onready var btn_gadget_marbles: Button = $Panel/Grid/GadgetMarbles/Btn
@onready var btn_gadget_faraday: Button = $Panel/Grid/GadgetFaraday/Btn

func _ready() -> void:
	btn_close.pressed.connect(func():
		AudioManager.play_sfx("ui_click")
		queue_free()
	)
	_setup_shop_items()
	_refresh_ui()

func _setup_shop_items() -> void:
	btn_suit_classic.pressed.connect(func(): _select_item("suit", "classic_bandit", 0))
	btn_suit_velvet.pressed.connect(func(): _select_item("suit", "velvet_paws", 50))
	btn_suit_silk.pressed.connect(func(): _select_item("suit", "silk_sack", 80))
	btn_suit_sprinter.pressed.connect(func(): _select_item("suit", "lockdown_sprinter", 120))
	
	btn_gadget_smoke.pressed.connect(func(): _select_item("gadget", "smoke_pellet", 40))
	btn_gadget_cuff.pressed.connect(func(): _select_item("gadget", "extra_ziptie", 60))
	btn_gadget_marbles.pressed.connect(func(): _select_item("gadget", "bag_marbles", 70))
	btn_gadget_faraday.pressed.connect(func(): _select_item("gadget", "faraday_pouch", 100))

func _select_item(category: String, item_id: String, cost: int) -> void:
	if category == "suit":
		if SaveManager.unlocked_suits.has(item_id):
			SaveManager.equipped_suit = item_id
			SaveManager.save_game()
			AudioManager.play_sfx("ui_click")
		else:
			if SaveManager.unlock_item(category, item_id, cost):
				AudioManager.play_sfx("coin_pickup")
	elif category == "gadget":
		if SaveManager.unlocked_gadgets.has(item_id):
			SaveManager.equipped_gadget = item_id
			SaveManager.save_game()
			AudioManager.play_sfx("ui_click")
		else:
			if SaveManager.unlock_item(category, item_id, cost):
				AudioManager.play_sfx("coin_pickup")
	_refresh_ui()

func _refresh_ui() -> void:
	lbl_banked.text = "VAULT: %d COINS" % SaveManager.banked_coins
	lbl_stars.text = "STARS: %d" % SaveManager.total_stars
	
	_update_btn(btn_suit_classic, "suit", "classic_bandit", 0)
	_update_btn(btn_suit_velvet, "suit", "velvet_paws", 50)
	_update_btn(btn_suit_silk, "suit", "silk_sack", 80)
	_update_btn(btn_suit_sprinter, "suit", "lockdown_sprinter", 120)
	
	_update_btn(btn_gadget_smoke, "gadget", "smoke_pellet", 40)
	_update_btn(btn_gadget_cuff, "gadget", "extra_ziptie", 60)
	_update_btn(btn_gadget_marbles, "gadget", "bag_marbles", 70)
	_update_btn(btn_gadget_faraday, "gadget", "faraday_pouch", 100)

func _update_btn(btn: Button, cat: String, item_id: String, cost: int) -> void:
	var unlocked = SaveManager.unlocked_suits.has(item_id) if cat == "suit" else SaveManager.unlocked_gadgets.has(item_id)
	var equipped = (SaveManager.equipped_suit == item_id) if cat == "suit" else (SaveManager.equipped_gadget == item_id)
	
	if equipped:
		btn.text = "EQUIPPED"
		btn.disabled = true
	elif unlocked:
		btn.text = "EQUIP"
		btn.disabled = false
	else:
		btn.text = "BUY (%d)" % cost
		btn.disabled = (SaveManager.banked_coins < cost)
