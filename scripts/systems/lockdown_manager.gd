# scripts/systems/lockdown_manager.gd
class_name LockdownManager
extends Node2D

@export var canvas_modulate: CanvasModulate
@export var level_camera: Camera2D

var casing_active: bool = true
var casing_timer: float = 3.5
var transponder_interval: float = 8.0
var transponder_timer: float = 0.0

func _ready() -> void:
	if SaveManager.equipped_gadget == "faraday_pouch":
		transponder_interval = 13.0 # +5s delay
	
	Events.lockdown_initiated.connect(_on_lockdown)
	_start_casing_phase()

func _start_casing_phase() -> void:
	casing_active = true
	casing_timer = 3.5
	if level_camera:
		level_camera.zoom = Vector2(0.5, 0.5) # Zoomed out overview

func _process(delta: float) -> void:
	# Casing camera overview
	if casing_active:
		casing_timer -= delta
		if casing_timer <= 0.0 or Input.is_anything_pressed():
			_end_casing_phase()
		return

	# Key Transponder radar ping loop during lockdown
	if GameManager.is_lockdown_active:
		transponder_timer += delta
		if transponder_timer >= transponder_interval:
			transponder_timer = 0.0
			var player = get_tree().get_first_node_in_group("player")
			if player:
				Events.key_transponder_ping.emit(player.global_position)
				Events.camera_shake_requested.emit(3.0, 0.15)

func _end_casing_phase() -> void:
	casing_active = false
	if level_camera:
		var tw = create_tween()
		tw.tween_property(level_camera, "zoom", Vector2(1.2, 1.2), 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	Events.casing_phase_ended.emit()

func _on_lockdown() -> void:
	# Crossfade CanvasModulate to Crimson
	if canvas_modulate:
		var tw = create_tween()
		tw.tween_property(canvas_modulate, "color", Color("#3B101A"), 0.5)
	
	Events.camera_shake_requested.emit(8.0, 0.4)
