# scripts/guards/guard_base.gd
class_name GuardBase
extends CharacterBody2D

@export var archetype: String = "rookie" # "rookie", "veteran", "radio", "k9", "heavy", "drone"
@export var patrol_waypoints: Array[Vector2] = []

var current_state: String = "PATROL" # "PATROL", "INVESTIGATE", "SEARCH", "CHASE", "KNOCKED_OUT", "CUFFED", "STUNNED"
var current_wp_idx: int = 0
var target_pos: Vector2 = Vector2.ZERO
var last_known_pos: Vector2 = Vector2.ZERO

# Vision parameters (from GameConfig)
var vision_radius: float = GameConfig.VISION_RADIUS_ROOKIE
var vision_half_angle: float = GameConfig.VISION_CONE_HALF_ANGLE_RAD
var suspicion_meter: float = 0.0 # 0.0 to 1.0
var is_player_in_los: bool = false

# Timers
var search_timer: float = 0.0
var knockout_timer: float = GameConfig.KNOCKOUT_DURATION_SEC
var patrol_wait_timer: float = 0.0
var stun_timer: float = 0.0
var turn_telegraph_timer: float = 0.0
var pending_turn_dir: float = 0.0

# Base speeds
var speed_patrol: float = GameConfig.GUARD_SPEED_PATROL_BASE
var speed_chase: float = GameConfig.GUARD_SPEED_CHASE_BASE

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
			vision_radius = GameConfig.VISION_RADIUS_VETERAN
			sprite.texture = load("res://assets/sprites/guard_veteran.png")
		"radio":
			speed_patrol = 70.0
			speed_chase = 160.0
			vision_radius = GameConfig.VISION_RADIUS_RADIO
			sprite.texture = load("res://assets/sprites/guard_radio.png")
		"k9":
			speed_patrol = 100.0
			speed_chase = 205.0
			vision_radius = GameConfig.VISION_RADIUS_K9
			sprite.texture = load("res://assets/sprites/guard_k9.png")
		"heavy":
			speed_patrol = 60.0
			speed_chase = 145.0
			vision_radius = GameConfig.VISION_RADIUS_HEAVY
			sprite.texture = load("res://assets/sprites/guard_heavy.png")
		"drone":
			speed_patrol = 90.0
			speed_chase = 190.0
			vision_radius = GameConfig.VISION_RADIUS_DRONE
			sprite.texture = load("res://assets/sprites/guard_drone.png")
		_:
			vision_radius = GameConfig.VISION_RADIUS_ROOKIE
			sprite.texture = load("res://assets/sprites/guard_rookie.png")

func _physics_process(delta: float) -> void:
	if current_state == "CUFFED":
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	if current_state == "STUNNED":
		_process_stun(delta)
		return
		
	if current_state == "KNOCKED_OUT":
		_process_knockout(delta)
		return

	# Vision LOS check
	_check_player_vision(delta)
	
	# K9 Scent Aura check
	if archetype == "k9":
		_check_k9_scent()

	# Sleeping comrade detection
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

	# 1. Check Smoke Cloud Occlusion
	if _is_blocked_by_smoke(global_position, player.global_position):
		_decay_suspicion(delta)
		is_player_in_los = false
		return

	# 2. Raycast to ensure walls do not block vision
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position, 1) # Layer 1 = Walls
	var result = space_state.intersect_ray(query)

	if result.is_empty():
		# Direct line of sight!
		is_player_in_los = true
		last_known_pos = player.global_position
		
		# Rate of suspicion rise from GameConfig
		var dist_factor = clampf(dist / vision_radius, 0.0, 1.0)
		var fill_rate = lerpf(1.0 / GameConfig.SUSPICION_TIME_POINT_BLANK, 1.0 / GameConfig.SUSPICION_TIME_EDGE, dist_factor)
		
		suspicion_meter = minf(1.0, suspicion_meter + fill_rate * delta)
		AudioManager.play_sfx("heartbeat_pulse", 0.0)

		if suspicion_meter >= 1.0 and current_state != "CHASE":
			_trigger_chase()
	else:
		_decay_suspicion(delta)
		is_player_in_los = false

func _is_blocked_by_smoke(p1: Vector2, p2: Vector2) -> bool:
	var clouds = get_tree().get_nodes_in_group("smoke_clouds")
	for c in clouds:
		# Check distance from line segment p1-p2 to cloud center
		var c_pos = c.global_position
		var line_vec = p2 - p1
		var t = clampf((c_pos - p1).dot(line_vec) / max(0.001, line_vec.length_squared()), 0.0, 1.0)
		var nearest = p1 + line_vec * t
		if nearest.distance_to(c_pos) < 65.0:
			return true
	return false

func _check_k9_scent() -> void:
	var player = get_tree().get_first_node_in_group("player") as BanditPlayer
	if not player or current_state == "CHASE" or current_state == "KNOCKED_OUT":
		return
	if global_position.distance_to(player.global_position) < GameConfig.K9_SCENT_RADIUS:
		JuiceManager.show_speech_bubble(self, "Sniff... GRRR!", Color(1.0, 0.7, 0.2))
		investigate_position(player.global_position)

func _decay_suspicion(delta: float) -> void:
	if suspicion_meter > 0.0 and current_state != "CHASE":
		suspicion_meter = maxf(0.0, suspicion_meter - GameConfig.SUSPICION_DECAY_RATE * delta)

func _trigger_chase() -> void:
	current_state = "CHASE"
	GameManager.is_spotted_ever = true
	state_icon.text = "!"
	state_icon.modulate = Color(1.0, 0.2, 0.2)
	state_icon.visible = true
	AudioManager.play_sfx("spotted_sting")
	Events.camera_shake_requested.emit(5.0, 0.2)
	JuiceManager.show_speech_bubble(self, "FREEZE, RACCOON!", Color(1.0, 0.2, 0.2))
	
	# Radio alert to 2 nearest guards
	if archetype == "radio":
		_radio_alert()

func _radio_alert() -> void:
	JuiceManager.show_speech_bubble(self, "10-4! Suspect spotted!", Color(0.2, 0.9, 1.0))
	var guards = get_tree().get_nodes_in_group("guards")
	var others: Array = []
	for g in guards:
		if g != self and g.current_state != "KNOCKED_OUT" and g.current_state != "CUFFED":
			others.append(g)
	# Sort by distance
	others.sort_custom(func(a, b): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
	# Alert top 2
	for i in range(mini(2, others.size())):
		others[i].investigate_position(last_known_pos)

func _process_patrol(delta: float) -> void:
	if patrol_waypoints.is_empty():
		return
		
	# Veteran turn telegraph check
	if turn_telegraph_timer > 0.0:
		turn_telegraph_timer -= delta
		velocity = Vector2.ZERO
		rotation = lerp_angle(rotation, pending_turn_dir, 6.0 * delta)
		return
		
	if patrol_wait_timer > 0.0:
		patrol_wait_timer -= delta
		velocity = Vector2.ZERO
		return

	target_pos = patrol_waypoints[current_wp_idx]
	var to_target = target_pos - global_position

	if to_target.length() < 12.0:
		patrol_wait_timer = 1.2
		var nxt_idx = (current_wp_idx + 1) % patrol_waypoints.size()
		var nxt_dir = (patrol_waypoints[nxt_idx] - global_position).angle()
		
		# Veteran 0.8s turn telegraph
		if archetype == "veteran" and abs(angle_difference(rotation, nxt_dir)) > 2.0:
			turn_telegraph_timer = 0.8
			pending_turn_dir = nxt_dir
			state_icon.text = "?"
			state_icon.visible = true
			state_icon.modulate = Color(1.0, 0.9, 0.4)
		
		current_wp_idx = nxt_idx
	else:
		var dir = to_target.normalized()
		velocity = dir * speed_patrol
		rotation = lerp_angle(rotation, dir.angle(), 8.0 * delta)

func _process_investigate(delta: float) -> void:
	var to_target = target_pos - global_position
	if to_target.length() < 16.0:
		current_state = "SEARCH"
		search_timer = 4.0
		JuiceManager.show_speech_bubble(self, "Must be rats...", Color(0.8, 0.85, 0.9))
	else:
		var dir = to_target.normalized()
		velocity = dir * speed_patrol * 1.3
		rotation = lerp_angle(rotation, dir.angle(), 10.0 * delta)

func _process_search(delta: float) -> void:
	search_timer -= delta
	velocity = Vector2.ZERO
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
		# Lost LOS: run to last known position only (never cheat through walls!)
		target_pos = last_known_pos

	var to_target = target_pos - global_position
	if to_target.length() < 14.0 and not is_player_in_los:
		current_state = "SEARCH"
		search_timer = 5.0
		state_icon.text = "?"
		state_icon.modulate = Color(1.0, 0.8, 0.2)
		JuiceManager.show_speech_bubble(self, "Where'd he go?!", Color(1.0, 0.8, 0.2))
	else:
		var speed = speed_chase
		if GameManager.is_lockdown_active:
			speed *= GameConfig.LOCKDOWN_GUARD_SPEED_MULT
		var dir = to_target.normalized()
		velocity = dir * speed
		rotation = lerp_angle(rotation, dir.angle(), 14.0 * delta)

func _check_sleeping_comrades() -> void:
	var guards = get_tree().get_nodes_in_group("guards")
	for g in guards:
		if g != self and g.current_state == "KNOCKED_OUT":
			if global_position.distance_to(g.global_position) < 80.0:
				g.wake_up()
				JuiceManager.show_speech_bubble(self, "Officer down! Wake up!", Color(1.0, 0.3, 0.3))
				AudioManager.play_sfx("player_caughtwhistle")
				investigate_position(g.global_position)
				break

func _on_sound_heard(pos: Vector2, radius: float, is_distraction: bool) -> void:
	if current_state == "KNOCKED_OUT" or current_state == "CUFFED" or current_state == "STUNNED":
		return
	var dist = global_position.distance_to(pos)
	if dist <= radius:
		investigate_position(pos)
		if is_distraction:
			JuiceManager.show_speech_bubble(self, "Ooh, shiny!", Color(1.0, 0.9, 0.4))
			AudioManager.play_sfx("suspicion_hm")

func _on_radar_ping_heard(pos: Vector2) -> void:
	if current_state != "KNOCKED_OUT" and current_state != "CUFFED" and current_state != "STUNNED":
		if global_position.distance_to(pos) < 360.0:
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
	speed_chase *= GameConfig.LOCKDOWN_GUARD_SPEED_MULT
	light_cone.color = Color(1.0, 0.45, 0.45, 1.0)

func apply_knockout() -> void:
	current_state = "KNOCKED_OUT"
	knockout_timer = GameConfig.KNOCKOUT_DURATION_SEC
	velocity = Vector2.ZERO
	light_cone.enabled = false
	suspicion_bar.visible = false
	state_icon.text = "Zzz"
	state_icon.modulate = Color(0.6, 0.8, 1.0)
	state_icon.visible = true
	Events.guard_knocked_out.emit(self)

func apply_stun(duration: float) -> void:
	current_state = "STUNNED"
	stun_timer = duration
	velocity = Vector2.ZERO
	light_cone.enabled = false
	suspicion_bar.visible = false
	state_icon.text = "*!*"
	state_icon.modulate = Color(1.0, 0.9, 0.2)
	state_icon.visible = true

func _process_stun(delta: float) -> void:
	stun_timer -= delta
	velocity = Vector2.ZERO
	if stun_timer <= 0.0:
		wake_up()

func apply_cuff() -> void:
	current_state = "CUFFED"
	light_cone.enabled = false
	state_icon.text = "CUFFED"
	state_icon.modulate = Color(1.0, 0.9, 0.3)
	state_icon.visible = true
	Events.guard_cuffed.emit(self)

func apply_pickpocket() -> void:
	Events.guard_pickpocketed.emit(self, GameConfig.PICKPOCKET_COINS_AWARD)

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
	if current_state != "KNOCKED_OUT" and current_state != "CUFFED" and current_state != "STUNNED":
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
	# Drone spotlights but doesn't catch physically
	if archetype == "drone":
		if body is BanditPlayer:
			_trigger_chase()
		return
	if body is BanditPlayer and current_state != "KNOCKED_OUT" and current_state != "CUFFED" and current_state != "STUNNED":
		Events.player_caught.emit(archetype.capitalize() + " Guard")
