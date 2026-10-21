# scripts/systems/juice_manager.gd
extends Node

var current_trauma: float = 0.0
var trauma_decay: float = 1.4
var max_shake_offset: float = 18.0
var max_shake_roll: float = 0.04

var speech_cooldowns: Dictionary = {}
var is_transitioning: bool = false
var transition_overlay: CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_transition_overlay()
	Events.camera_shake_requested.connect(add_trauma)
	Events.coin_collected.connect(func(_a, _t): add_trauma(0.12))
	Events.key_collected.connect(func():
		hitstop(GameConfig.LOCKDOWN_HITSTOP_SEC)
		add_trauma(0.65)
		duck_music(6.0, 2.0)
	)
	Events.guard_knocked_out.connect(func(_g):
		hitstop(GameConfig.KNOCKOUT_HITSTOP_SEC)
		add_trauma(0.35)
	)
	Events.player_caught.connect(func(_c):
		hitstop(GameConfig.CAPTURE_HITSTOP_SEC)
		add_trauma(0.7)
	)

func _setup_transition_overlay() -> void:
	transition_overlay = CanvasLayer.new()
	transition_overlay.layer = 120 # Above all HUDs
	add_child(transition_overlay)
	
	var rect = ColorRect.new()
	rect.name = "WipeRect"
	rect.color = Color(0.04, 0.09, 0.18, 1.0)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.anchor_right = 1.0
	rect.anchor_bottom = 1.0
	rect.modulate.a = 0.0
	transition_overlay.add_child(rect)

func add_trauma(amount: float) -> void:
	var intensity_setting = SaveManager.screen_shake_intensity if is_instance_valid(SaveManager) else 1.0
	current_trauma = clampf(current_trauma + amount * intensity_setting, 0.0, 1.0)

func get_shake_transform() -> Dictionary:
	var shake = current_trauma * current_trauma
	var offset = Vector2(
		randf_range(-max_shake_offset, max_shake_offset) * shake,
		randf_range(-max_shake_offset, max_shake_offset) * shake
	)
	var rot = randf_range(-max_shake_roll, max_shake_roll) * shake
	return {"offset": offset, "rotation": rot}

func _process(delta: float) -> void:
	if current_trauma > 0.0:
		current_trauma = maxf(0.0, current_trauma - trauma_decay * delta)
		
	# Clean speech cooldowns
	for key in speech_cooldowns.keys():
		speech_cooldowns[key] -= delta
		if speech_cooldowns[key] <= 0.0:
			speech_cooldowns.erase(key)

func hitstop(duration: float) -> void:
	Engine.time_scale = 0.05
	var timer = get_tree().create_timer(duration * 0.05, true, false, true)
	timer.timeout.connect(func(): Engine.time_scale = 1.0)

func duck_music(db_reduction: float, duration: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx < 0:
		return
	var orig_vol = AudioServer.get_bus_volume_db(bus_idx)
	AudioServer.set_bus_volume_db(bus_idx, orig_vol - db_reduction)
	var timer = get_tree().create_timer(duration, true, false, true)
	timer.timeout.connect(func():
		var tw = create_tween()
		tw.tween_method(func(v): AudioServer.set_bus_volume_db(bus_idx, v), orig_vol - db_reduction, orig_vol, 0.8)
	)

func show_speech_bubble(node: Node2D, text: String, color: Color = Color.WHITE) -> void:
	var id = node.get_instance_id()
	if speech_cooldowns.has(id):
		return
	speech_cooldowns[id] = 2.4 # Limit speech per entity
	
	var bubble = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.1, 0.2, 0.88)
	style.border_color = color
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	bubble.add_theme_stylebox_override("panel", style)
	
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 12)
	bubble.add_child(lbl)
	
	bubble.position = Vector2(-bubble.size.x / 2.0, -42.0)
	node.add_child(bubble)
	
	# Animate float and fade out
	var tw = create_tween()
	tw.tween_property(bubble, "position:y", -54.0, 1.4)
	tw.tween_property(bubble, "modulate:a", 0.0, 0.4)
	tw.tween_callback(bubble.queue_free)

func change_scene_with_wipe(scene_path: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	var rect = transition_overlay.get_node_or_null("WipeRect") as ColorRect
	if not rect:
		get_tree().change_scene_to_file(scene_path)
		is_transitioning = false
		return
		
	var tw = create_tween()
	tw.tween_property(rect, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(func():
		get_tree().change_scene_to_file(scene_path)
	)
	tw.tween_interval(0.05)
	tw.tween_property(rect, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(func(): is_transitioning = false)
