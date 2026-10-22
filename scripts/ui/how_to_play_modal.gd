# scripts/ui/how_to_play_modal.gd
extends Control

@onready var tab_container: TabContainer = $Panel/TabContainer
@onready var btn_close: Button = $Panel/BtnClose

func _ready() -> void:
	btn_close.pressed.connect(func():
		AudioManager.play_sfx("ui_click")
		queue_free()
	)
	_update_controls_tab_text()

func open_tab(idx: int) -> void:
	if tab_container:
		tab_container.current_tab = clampi(idx, 0, tab_container.get_tab_count() - 1)

func _update_controls_tab_text() -> void:
	var ctrl_node = tab_container.get_node_or_null("5. Controls/Desc")
	if ctrl_node is Label:
		ctrl_node.text = """MOBILE TOUCH CONTROLS (Thumbtip Optimized):
- Left Thumb: Dynamic Virtual Joystick
    • Inner circle: Silent Sneak (0 px noise)
    • Mid circle: Walk
    • Outer ring / Sprint Button: Sprint (Caution: noisy!)
- Right Thumb Cluster:
    • Primary Context Button: Auto-swaps to Knockout, Cuff, Hide in Locker, Vent Crawl, or Hold for Pickpocket!
    • Coin Toss Button: Throw distraction coin to lure guards
    • Gadget Button: Smoke Pellet / Marbles
    • Pause Button: Top-Right safe zone

KEYBOARD & MOUSE:
- WASD / Arrows: Move | Shift: Sprint | E: Interact / Knockout / Cuff
- Q: Toss Coin | F: Gadget | Esc: Pause

GAMEPAD:
- Left Stick: Move | RT: Sprint | A: Interact | X: Coin | RB: Gadget"""
