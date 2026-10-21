# scripts/systems/lockdown_manager.gd
class_name LockdownManager
extends Node2D

@export var canvas_modulate: CanvasModulate
@export var level_camera: Camera2D

var casing_active: bool = false
var casing_timer: float = 3.5
var transponder_interval: float = 8.0
var transponder_timer: float = 0.0
var maze_center: Vector2 = Vector2.ZERO

func _ready() -> void:
	var save_mgr = get_node_or_null("/root/SaveManager")
	if save_mgr and save_mgr.equipped_gadget == "faraday_pouch":
		transponder_interval = 13.0 # +5s delay
	
	if has_node("/root/Events"):
		Events.lockdown_initiated.connect(_on_lockdown)

func _exit_tree() -> void:
	if has_node("/root/Events") and Events.lockdown_initiated.is_connected(_on_lockdown):
		Events.lockdown_initiated.disconnect(_on_lockdown)

func init_casing(center: Vector2, size: Vector2) -> void:
	maze_center = center
	casing_active = true
	casing_timer = 3.5
	if level_camera:
		var fit_zoom = clampf(minf(1100.0 / max(size.x, 100.0), 580.0 / max(size.y, 100.0)), 0.35, 1.0)
		level_camera.global_position = center
		level_camera.zoom = Vector2(fit_zoom, fit_zoom)

func _unhandled_input(event: InputEvent) -> void:
	if casing_active:
		if (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton) and event.is_pressed():
			end_casing_phase()

func _process(delta: float) -> void:
	# Casing camera overview timer
	if casing_active:
		casing_timer -= delta
		# Also check if player pressed movement keys
		var mv = Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
		)
		if casing_timer <= 0.0 or mv.length() > 0.1:
			end_casing_phase()
		return

	# Key Transponder radar ping loop during lockdown
	if GameManager.is_lockdown_active:
		transponder_timer += delta
		if transponder_timer >= transponder_interval:
			transponder_timer = 0.0
			var player = get_tree().get_first_node_in_group("player")
			if player:
				Events.key_transponder_ping.emit(player.global_position)
				Events.camera_shake_requested.emit(4.0, 0.2)

func end_casing_phase() -> void:
	if not casing_active:
		return
	casing_active = false
	var player = get_tree().get_first_node_in_group("player")
	if level_camera and player:
		var tw = create_tween().set_parallel(true)
		tw.tween_property(level_camera, "global_position", player.global_position, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(level_camera, "zoom", Vector2(1.5, 1.5), 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	Events.casing_phase_ended.emit()

func _on_lockdown() -> void:
	# Crossfade CanvasModulate to Crimson
	if canvas_modulate:
		var tw = create_tween()
		tw.tween_property(canvas_modulate, "color", Color(0.70, 0.25, 0.30, 1.0), 0.5)
	
	Events.camera_shake_requested.emit(8.0, 0.4)
