# scripts/ui/how_to_play_modal.gd
extends Control

@onready var tab_container: TabContainer = $Panel/TabContainer
@onready var btn_close: Button = $Panel/BtnClose

func _ready() -> void:
	btn_close.pressed.connect(func():
		AudioManager.play_sfx("ui_click")
		queue_free()
	)
