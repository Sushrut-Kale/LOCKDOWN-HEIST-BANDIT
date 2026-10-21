# scripts/guards/guard_base.gd
class_name GuardBase
extends CharacterBody2D

@export var archetype: String = "rookie" # "rookie", "veteran", "radio", "k9", "heavy", "drone"
@export var patrol_waypoints: Array[Vector2] = []

var current_state: String = "PATROL" # "PATROL", "INVESTIGATE", "SEARCH", "CHASE", "KNOCKED_OUT", "CUFFED"
var current_wp_idx: int = 0
var target_pos: Vector2 = Vector2.ZERO
var last_known_pos: Vector2 = Vector2.ZERO

# Vision parameters
var vision_radius: float = 230.0
var vision_half_angle: float = deg_to_rad(28.0) # 56 deg cone
var suspicion_meter: float = 0.0 # 0.0 to 1.0
var is_player_in_los: bool = false

# Timers
var search_timer: float = 0.0
var knockout_timer: float = 35.0
var patrol_wait_timer: float = 0.0
var radio_cooldown: float = 0.0

# Base speeds
var speed_patrol: float = 75.0
var speed_chase: float = 170.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var light_cone: PointLight2D = $LightCone
@onready var suspicion_bar: ProgressBar = $SuspicionBar
@onready var state_icon: Label = $StateIcon
@onready var catch_area: Area2D = $CatchArea

func _ready() -> void:
	add_to_group("guards")
	_configure_archetype()
	suspicion_bar.visible = false
	state_icon.visible = false
	
	if not patrol_waypoints.is_empty():
		target_pos = patrol_waypoints[0]
	else:
		target_pos = global_position
		
	Events.sound_emitted.connect(_on_sound_heard)
	Events.key_transponder_ping.connect(_on_radar_ping_heard)
	Events.lockdown_initiated.connect(_on_lockdown)

func _configure_archetype() -> void:
	match archetype:
		"veteran":
			speed_patrol = 85.0
			speed_chase = 180.0
			vision_radius = 260.0
			sprite.texture = load("res://assets/sprites/guard_veteran.png")
		"radio":
			speed_patrol = 70.0
			speed_chase = 160.0
			sprite.texture = load("res://assets/sprites/guard_radio.png")
		"k9":
			speed_patrol = 100.0
			speed_chase = 205.0
			vision_radius = 200.0
			sprite.texture = load("res://assets/sprites/guard_k9.png")
		"heavy":
			speed_patrol = 60.0
			speed_chase = 145.0
			sprite.texture = load("res://assets/sprites/guard_heavy.png")
		"drone":
			speed_patrol = 90.0
			speed_chase = 190.0
			vision_radius = 240.0
			sprite.texture = load("res://assets/sprites/guard_drone.png")
		_:
			sprite.texture = load("res://assets/sprites/guard_rookie.png")

func _physics_process(delta: float) -> void:
	if current_state == "CUFFED":
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	if current_state == "KNOCKED_OUT":
		_process_knockout(delta)
		return

	# Check Vision LOS
	_check_player_vision(delta)
	
	# Check Sleeping comrades in sight
	_check_sleeping_comrades()

	# State Machine
	match current_state:
		"PATROL":
			_process_patrol(delta)
		"INVESTIGATE":
			_process_investigate(delta)
		"SEARCH":
			_process_search(delta)
		"CHASE":
			_process_chase(delta)

	move_and_slide()
	_update_hud_indicators()

func _check_player_vision(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player") as BanditPlayer
	if not player or player.is_hidden:
		_decay_suspicion(delta)
		is_player_in_los = false
		return

	var to_player = player.global_position - global_position
	var dist = to_player.length()

	if dist > vision_radius:
		_decay_suspicion(delta)
		is_player_in_los = false
		return

	var forward = Vector2.RIGHT.rotated(rotation)
	var angle_diff = abs(forward.angle_to(to_player))

	if angle_diff > vision_half_angle:
		_decay_suspicion(delta)
		is_player_in_los = false
		return

	# Raycast to ensure walls do not block vision
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position, 1) # Layer 1 = Walls
	var result = space_state.intersect_ray(query)

	if result.is_empty():
		# Direct line of sight!
		is_player_in_los = true
		last_known_pos = player.global_position
		
		# Rate of suspicion rise: 0.12s point blank -> 0.40s at edge
		var dist_factor = clampf(dist / vision_radius, 0.0, 1.0)
		var fill_rate = lerpf(1.0 / 0.12, 1.0 / 0.40, dist_factor)
		
		suspicion_meter = minf(1.0, suspicion_meter + fill_rate * delta)
		AudioManager.play_sfx("heartbeat_pulse", 0.0)

		if suspicion_meter >= 1.0 and current_state != "CHASE":
			_trigger_chase()
	else:
		_decay_suspicion(delta)
		is_player_in_los = false

func _decay_suspicion(delta: float) -> void:
	if suspicion_meter > 0.0 and current_state != "CHASE":
		suspicion_meter = maxf(0.0, suspicion_meter - 1.2 * delta)

func _trigger_chase() -> void:
	current_state = "CHASE"
	GameManager.is_spotted_ever = true
	state_icon.text = "!"
	state_icon.modulate = Color(1.0, 0.2, 0.2)
	state_icon.visible = true
	AudioManager.play_sfx("spotted_sting")
	Events.camera_shake_requested.emit(5.0, 0.2)
	
	# Radio archetype alerts comrades
	if archetype == "radio":
		_radio_alert()

func _radio_alert() -> void:
	var guards = get_tree().get_nodes_in_group("guards")
	for g in guards:
		if g != self and g.current_state != "KNOCKED_OUT" and g.current_state != "CUFFED":
			if global_position.distance_to(g.global_position) < 380.0:
				g.investigate_position(last_known_pos)

func _process_patrol(delta: float) -> void:
	if patrol_waypoints.is_empty():
		return
	if patrol_wait_timer > 0.0:
		patrol_wait_timer -= delta
		velocity = Vector2.ZERO
		return

	target_pos = patrol_waypoints[current_wp_idx]
	var to_target = target_pos - global_position

	if to_target.length() < 12.0:
		patrol_wait_timer = 1.2 if archetype != "veteran" else 2.2
		current_wp_idx = (current_wp_idx + 1) % patrol_waypoints.size()
	else:
		var dir = to_target.normalized()
		velocity = dir * speed_patrol
		rotation = lerp_angle(rotation, dir.angle(), 8.0 * delta)

func _process_investigate(delta: float) -> void:
	var to_target = target_pos - global_position
	if to_target.length() < 16.0:
		current_state = "SEARCH"
		search_timer = 4.0
	else:
		var dir = to_target.normalized()
		velocity = dir * speed_patrol * 1.3
		rotation = lerp_angle(rotation, dir.angle(), 10.0 * delta)

func _process_search(delta: float) -> void:
	search_timer -= delta
	velocity = Vector2.ZERO
	# Sweep scan angles
	rotation += sin(search_timer * 4.0) * delta * 2.5
	if search_timer <= 0.0:
		current_state = "PATROL"
		state_icon.visible = false

func _process_chase(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if is_player_in_los and player:
		target_pos = player.global_position
		last_known_pos = player.global_position
	else:
		# Lost line of sight: run to last known position!
		target_pos = last_known_pos

	var to_target = target_pos - global_position
	if to_target.length() < 14.0 and not is_player_in_los:
		# Reached last known position without spotting player
		current_state = "SEARCH"
		search_timer = 5.0
		state_icon.text = "?"
		state_icon.modulate = Color(1.0, 0.8, 0.2)
	else:
		var speed = speed_chase
		if GameManager.is_lockdown_active:
			speed *= 1.3 # +30% guard speed in lockdown
		var dir = to_target.normalized()
		velocity = dir * speed
		rotation = lerp_angle(rotation, dir.angle(), 14.0 * delta)

func _check_sleeping_comrades() -> void:
	var guards = get_tree().get_nodes_in_group("guards")
	for g in guards:
		if g != self and g.current_state == "KNOCKED_OUT":
			if global_position.distance_to(g.global_position) < 80.0:
				# Wake comrade!
				g.wake_up()
				AudioManager.play_sfx("player_caughtwhistle")
				investigate_position(g.global_position)
				break

func _on_sound_heard(pos: Vector2, radius: float, is_distraction: bool) -> void:
	if current_state == "KNOCKED_OUT" or current_state == "CUFFED":
		return
	var dist = global_position.distance_to(pos)
	if dist <= radius:
		investigate_position(pos)
		if is_distraction:
			AudioManager.play_sfx("suspicion_hm")

func _on_radar_ping_heard(pos: Vector2) -> void:
	if current_state != "KNOCKED_OUT" and current_state != "CUFFED":
		if global_position.distance_to(pos) < 350.0:
			investigate_position(pos)

func investigate_position(pos: Vector2) -> void:
	if current_state != "CHASE":
		current_state = "INVESTIGATE"
		target_pos = pos
		state_icon.text = "?"
		state_icon.modulate = Color(1.0, 0.8, 0.2)
		state_icon.visible = true

func _on_lockdown() -> void:
	speed_patrol *= 1.25
	speed_chase *= 1.30
	# Light cone turns crimson during lockdown
	light_cone.color = Color(1.0, 0.45, 0.45, 1.0)

func apply_knockout() -> void:
	if archetype == "heavy":
		# Heavy guard resists bare knockout
		AudioManager.play_sfx("footstep_soft")
		return
	current_state = "KNOCKED_OUT"
	knockout_timer = 35.0
	velocity = Vector2.ZERO
	light_cone.enabled = false
	suspicion_bar.visible = false
	state_icon.text = "Zzz"
	state_icon.modulate = Color(0.6, 0.8, 1.0)
	state_icon.visible = true
	Events.guard_knocked_out.emit(self)

func apply_cuff() -> void:
	current_state = "CUFFED"
	light_cone.enabled = false
	state_icon.text = "CUFFED"
	state_icon.modulate = Color(1.0, 0.9, 0.3)
	state_icon.visible = true
	Events.guard_cuffed.emit(self)

func apply_pickpocket() -> void:
	Events.guard_pickpocketed.emit(self, 6)

func wake_up() -> void:
	current_state = "SEARCH"
	search_timer = 4.0
	light_cone.enabled = true
	state_icon.text = "?"
	state_icon.modulate = Color(1.0, 0.8, 0.2)
	state_icon.visible = true

func _process_knockout(delta: float) -> void:
	knockout_timer -= delta
	velocity = Vector2.ZERO
	if knockout_timer <= 0.0:
		wake_up()

func _update_hud_indicators() -> void:
	if current_state != "KNOCKED_OUT" and current_state != "CUFFED":
		if suspicion_meter > 0.05 and current_state != "CHASE":
			suspicion_bar.visible = true
			suspicion_bar.value = suspicion_meter * 100.0
			state_icon.text = "?"
			state_icon.modulate = Color(1.0, 0.8, 0.2)
			state_icon.visible = true
		elif current_state == "PATROL":
			suspicion_bar.visible = false
			state_icon.visible = false

func _on_catch_area_body_entered(body: Node2D) -> void:
	if body is BanditPlayer and current_state != "KNOCKED_OUT" and current_state != "CUFFED":
		Events.player_caught.emit(archetype.capitalize() + " Guard")
