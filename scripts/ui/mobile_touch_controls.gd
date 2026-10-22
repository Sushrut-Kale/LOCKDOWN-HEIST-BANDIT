# scripts/ui/mobile_touch_controls.gd
class_name MobileTouchControls
extends Control

signal pause_requested

@onready var joystick_base: Control = $JoystickBase
@onready var joystick_ring: TextureRect = $JoystickBase/Ring
@onready var joystick_knob: TextureRect = $JoystickBase/Knob

@onready var action_cluster: Control = $ActionCluster
@onready var btn_context: TextureButton = $ActionCluster/BtnContext
@onready var context_radial: Control = $ActionCluster/BtnContext/RadialProgress
@onready var context_label: Label = $ActionCluster/BtnContext/Label
@onready var btn_coin: TextureButton = $ActionCluster/BtnCoin
@onready var btn_gadget: TextureButton = $ActionCluster/BtnGadget
@onready var gadget_pips: Label = $ActionCluster/BtnGadget/Pips
@onready var btn_sprint: TextureButton = $ActionCluster/BtnSprint
@onready var btn_pause: TextureButton = $ActionCluster/BtnPause

# Multi-touch tracking
var joystick_touch_id: int = -1
var joystick_origin: Vector2 = Vector2.ZERO
var joystick_current: Vector2 = Vector2.ZERO
var joystick_radius: float = 85.0
var joystick_deadzone: float = 0.12

var context_touch_id: int = -1
var is_holding_context: bool = false
var context_hold_timer: float = 0.0

var sprint_touch_id: int = -1
var is_sprint_button_pressed: bool = false

var coin_touch_id: int = -1
var gadget_touch_id: int = -1

var player_ref: BanditPlayer = null
var is_active: bool = false

# Textures
var tex_knockout: Texture2D
var tex_cuff: Texture2D
var tex_pickpocket: Texture2D
var tex_hide: Texture2D
var tex_vent: Texture2D
var tex_unlock: Texture2D
var tex_default: Texture2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_textures()
	_update_visibility()
	_apply_layout_and_safe_area()
	get_viewport().size_changed.connect(_apply_layout_and_safe_area)

func _load_textures() -> void:
	tex_knockout = load("res://assets/ui/touch_context_knockout.png")
	tex_cuff = load("res://assets/ui/touch_context_cuff.png")
	tex_pickpocket = load("res://assets/ui/touch_context_pickpocket.png")
	tex_hide = load("res://assets/ui/touch_context_hide.png")
	tex_vent = load("res://assets/ui/touch_context_vent.png")
	tex_unlock = load("res://assets/ui/touch_context_unlock.png")
	tex_default = load("res://assets/ui/touch_context_default.png")

func _update_visibility() -> void:
	match SaveManager.touch_controls_mode:
		"force_on":
			visible = true
			is_active = true
		"off":
			visible = false
			is_active = false
		_:
			var has_touch = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
			visible = has_touch
			is_active = has_touch

func _apply_layout_and_safe_area() -> void:
	var vp_size = get_viewport_rect().size
	if vp_size.x <= 0 or vp_size.y <= 0:
		return
	
	# Determine safe area
	var safe_rect = DisplayServer.get_display_safe_area()
	var safe_left = float(safe_rect.position.x)
	var safe_top = float(safe_rect.position.y)
	var safe_right = float(vp_size.x - (safe_rect.position.x + safe_rect.size.x))
	var safe_bottom = float(vp_size.y - (safe_rect.position.y + safe_rect.size.y))
	
	# Apply simulation if configured in Settings
	match SaveManager.simulate_notch:
		"left":
			safe_left = maxf(safe_left, 80.0)
		"right":
			safe_right = maxf(safe_right, 80.0)
		"cutout":
			safe_top = maxf(safe_top, 50.0)

	var is_left_hand = (SaveManager.touch_cluster_hand == "left")
	
	# Scaling based on viewport height relative to 1080p
	var scale_factor = clampf(minf(vp_size.x / 1920.0, vp_size.y / 1080.0), 0.75, 1.35)
	
	# Layout Joystick
	var joy_margin_x = (safe_right if is_left_hand else safe_left) + 40.0 * scale_factor
	var joy_margin_y = safe_bottom + 40.0 * scale_factor
	
	if is_left_hand:
		joystick_origin = Vector2(vp_size.x - joy_margin_x - 120.0 * scale_factor, vp_size.y - joy_margin_y - 120.0 * scale_factor)
	else:
		joystick_origin = Vector2(joy_margin_x + 120.0 * scale_factor, vp_size.y - joy_margin_y - 120.0 * scale_factor)
		
	joystick_base.position = joystick_origin
	joystick_base.scale = Vector2(scale_factor, scale_factor)
	_reset_joystick_visuals()

	# Layout Action Cluster
	action_cluster.scale = Vector2(scale_factor, scale_factor)
	var cluster_w = 340.0 * scale_factor
	var cluster_h = 300.0 * scale_factor
	
	if is_left_hand:
		# Place cluster on Left
		action_cluster.position = Vector2(safe_left + 24.0, vp_size.y - safe_bottom - cluster_h)
		# Place pause on Top-Right
		btn_pause.position = Vector2(vp_size.x - safe_right - 70.0 * scale_factor, safe_top + 18.0)
	else:
		# Place cluster on Right
		action_cluster.position = Vector2(vp_size.x - safe_right - cluster_w, vp_size.y - safe_bottom - cluster_h)
		# Place pause on Top-Left or Top-Right
		btn_pause.position = Vector2(vp_size.x - safe_right - 70.0 * scale_factor, safe_top + 18.0)

	btn_pause.scale = Vector2(scale_factor, scale_factor)

func _process(delta: float) -> void:
	if not is_active:
		return
		
	_find_player()
	_update_context_button(delta)
	_update_gadget_button()

func _find_player() -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		var p = get_tree().get_first_node_in_group("player")
		if p is BanditPlayer:
			player_ref = p

func _update_context_button(_delta: float) -> void:
	if not btn_context:
		return
		
	var ctx: Dictionary = {"type": "none", "label": "ACTION", "active": false, "hold_progress": 0.0}
	if player_ref != null and is_instance_valid(player_ref) and player_ref.has_method("get_interaction_context"):
		ctx = player_ref.get_interaction_context()
		
	var c_type = ctx.get("type", "none")
	var c_label = ctx.get("label", "ACTION")
	var c_active = ctx.get("active", false)
	var hold_prog = ctx.get("hold_progress", 0.0)
	
	context_label.text = c_label
	
	# Swap Icon Texture
	match c_type:
		"knockout":
			btn_context.texture_normal = tex_knockout
		"cuff":
			btn_context.texture_normal = tex_cuff
		"steal":
			btn_context.texture_normal = tex_pickpocket
		"hide":
			btn_context.texture_normal = tex_hide
		"vent":
			btn_context.texture_normal = tex_vent
		"unlock":
			btn_context.texture_normal = tex_unlock
		_:
			btn_context.texture_normal = tex_default

	# Dim when no active interaction target
	if c_active:
		btn_context.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		btn_context.modulate = Color(1.0, 1.0, 1.0, 0.45)
		
	# Update Hold Radial Progress
	if context_radial:
		context_radial.set_meta("progress", hold_prog)
		context_radial.queue_redraw()

func _update_gadget_button() -> void:
	if not btn_gadget:
		return
	var g = SaveManager.equipped_gadget
	var count = 0
	if g == "smoke_pellet":
		count = GameManager.smoke_pellets_remaining
	elif g == "bag_marbles":
		count = GameManager.marbles_remaining
	elif g == "extra_ziptie":
		count = GameManager.free_cuffs_remaining
		
	if gadget_pips:
		gadget_pips.text = "x%d" % count
	btn_gadget.modulate = Color(1.0, 1.0, 1.0, 1.0) if count > 0 else Color(1.0, 1.0, 1.0, 0.4)

func _input(event: InputEvent) -> void:
	if not is_active or not visible:
		return
		
	# Multi-touch event handling
	if event is InputEventScreenTouch:
		if event.pressed:
			_handle_touch_down(event.index, event.position)
		else:
			_handle_touch_up(event.index, event.position)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event.index, event.position)
	# Mouse support for desk testing with Force On
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_handle_touch_down(0, event.position)
			else:
				_handle_touch_up(0, event.position)
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_handle_touch_drag(0, event.position)

func _handle_touch_down(touch_id: int, pos: Vector2) -> void:
	var vp_w = get_viewport_rect().size.x
	var is_left_hand = (SaveManager.touch_cluster_hand == "left")
	
	# Check Pause button
	if btn_pause and btn_pause.get_global_rect().has_point(pos):
		_on_pause_pressed()
		return
		
	# Check Action buttons first
	if btn_context and btn_context.get_global_rect().has_point(pos):
		context_touch_id = touch_id
		is_holding_context = true
		Input.action_press("interact", 1.0)
		return
		
	if btn_coin and btn_coin.get_global_rect().has_point(pos):
		coin_touch_id = touch_id
		Input.action_press("toss_coin", 1.0)
		SaveManager.trigger_haptic(20)
		return
		
	if btn_gadget and btn_gadget.get_global_rect().has_point(pos):
		gadget_touch_id = touch_id
		Input.action_press("use_gadget", 1.0)
		SaveManager.trigger_haptic(25)
		return
		
	if btn_sprint and btn_sprint.get_global_rect().has_point(pos):
		sprint_touch_id = touch_id
		is_sprint_button_pressed = true
		Input.action_press("sprint", 1.0)
		SaveManager.trigger_haptic(20)
		return

	# Otherwise, check if touch falls into Joystick hemisphere
	var in_joystick_zone = (pos.x > vp_w * 0.52) if is_left_hand else (pos.x < vp_w * 0.48)
	if in_joystick_zone and joystick_touch_id == -1:
		joystick_touch_id = touch_id
		joystick_origin = pos
		joystick_base.global_position = pos
		joystick_current = pos
		_update_joystick_vector(Vector2.ZERO)

func _handle_touch_drag(touch_id: int, pos: Vector2) -> void:
	if touch_id == joystick_touch_id:
		joystick_current = pos
		var delta_pos = pos - joystick_origin
		var dist = delta_pos.length()
		var max_dist = joystick_radius * joystick_base.scale.x
		if dist > max_dist:
			delta_pos = delta_pos.normalized() * max_dist
			
		joystick_knob.position = delta_pos / joystick_base.scale.x
		var norm_vec = delta_pos / max_dist
		_update_joystick_vector(norm_vec)

func _handle_touch_up(touch_id: int, _pos: Vector2) -> void:
	if touch_id == joystick_touch_id:
		joystick_touch_id = -1
		_reset_joystick_visuals()
		_release_movement_actions()
		
	if touch_id == context_touch_id:
		context_touch_id = -1
		is_holding_context = false
		Input.action_release("interact")
		
	if touch_id == coin_touch_id:
		coin_touch_id = -1
		Input.action_release("toss_coin")
		
	if touch_id == gadget_touch_id:
		gadget_touch_id = -1
		Input.action_release("use_gadget")
		
	if touch_id == sprint_touch_id:
		sprint_touch_id = -1
		is_sprint_button_pressed = false
		if not _is_stick_sprinting():
			Input.action_release("sprint")

func _update_joystick_vector(vec: Vector2) -> void:
	var l = vec.length()
	if l < joystick_deadzone:
		_release_movement_actions()
		return

	var angle = vec.angle()
	# Analog strengths
	var sx = absf(vec.x)
	var sy = absf(vec.y)
	
	if vec.x > 0.05:
		Input.action_press("move_right", sx)
		Input.action_release("move_left")
	elif vec.x < -0.05:
		Input.action_press("move_left", sx)
		Input.action_release("move_right")
	else:
		Input.action_release("move_left")
		Input.action_release("move_right")

	if vec.y > 0.05:
		Input.action_press("move_down", sy)
		Input.action_release("move_up")
	elif vec.y < -0.05:
		Input.action_press("move_up", sy)
		Input.action_release("move_down")
	else:
		Input.action_release("move_up")
		Input.action_release("move_down")

	# Speed tier easing:
	# inner 0-0.35 -> sneak
	# 0.35-0.78 -> walk
	# outer ring > 0.78 -> sprint
	if l > 0.78 or is_sprint_button_pressed:
		Input.action_press("sprint", 1.0)
	else:
		if not is_sprint_button_pressed:
			Input.action_release("sprint")

	# Visual opacity boost during active touch
	var base_op = SaveManager.touch_joystick_opacity
	joystick_base.modulate = Color(1.0, 1.0, 1.0, base_op)

func _is_stick_sprinting() -> bool:
	return (joystick_current - joystick_origin).length() / (joystick_radius * joystick_base.scale.x) > 0.78

func _release_movement_actions() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_up")
	Input.action_release("move_down")
	if not is_sprint_button_pressed:
		Input.action_release("sprint")

func _reset_joystick_visuals() -> void:
	joystick_knob.position = Vector2.ZERO
	# Idle opacity is 0.35 * user opacity setting
	var idle_op = 0.35 * SaveManager.touch_joystick_opacity
	joystick_base.modulate = Color(1.0, 1.0, 1.0, idle_op)

func _on_pause_pressed() -> void:
	SaveManager.trigger_haptic(30)
	pause_requested.emit()
	var level = get_tree().current_scene
	if level and level.has_method("_on_pause_button_pressed"):
		level._on_pause_button_pressed()
