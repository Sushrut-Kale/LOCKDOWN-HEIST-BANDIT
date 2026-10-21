# scripts/player/bandit_player.gd
class_name BanditPlayer
extends CharacterBody2D

const GameConfig = preload("res://scripts/systems/game_config.gd")


@export var is_hidden: bool = false

var move_state: String = "walk" # "sneak", "walk", "sprint"
var face_dir: Vector2 = Vector2.DOWN
var is_cuffed_animation: bool = false
var interact_hold_time: float = 0.0
var target_guard: Node2D = null

# Bot simulation support for Runtime Playtest Harness
var is_bot_controlled: bool = false
var bot_input: Vector2 = Vector2.ZERO
var bot_sprint: bool = false
var bot_interact_tap: bool = false
var bot_interact_hold: bool = false

# Footstep and sound ring timers
var step_timer: float = 0.0
var sound_ring_radius: float = 0.0
var sound_ring_alpha: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var bag_sprite: Sprite2D = $BagSprite
@onready var interaction_area: Area2D = $InteractionArea
@onready var prompt_label: Label = $PromptLabel
@onready var interact_progress: ProgressBar = $InteractProgress

func _ready() -> void:
	prompt_label.visible = false
	interact_progress.visible = false
	bag_sprite.visible = false
	Events.coin_collected.connect(_on_coin_collected)

func _physics_process(delta: float) -> void:
	if is_hidden or is_cuffed_animation:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# 1. Input Direction (Player or Bot)
	var input_vec = Vector2.ZERO
	if is_bot_controlled:
		input_vec = bot_input
	else:
		input_vec = Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
		)
		
	if input_vec.length() > 1.0:
		input_vec = input_vec.normalized()

	# 2. Movement Mode (Sneak / Walk / Sprint)
	var is_sprinting = bot_sprint if is_bot_controlled else Input.is_action_pressed("sprint")
	if is_sprinting and input_vec.length() > 0.1:
		move_state = "sprint"
	elif input_vec.length() > 0.1:
		move_state = "walk"
	else:
		move_state = "sneak"

	# Calculate Target Speed from GameConfig
	var base_spd = GameConfig.SPEED_WALK
	if move_state == "sneak":
		base_spd = GameConfig.SPEED_SNEAK
	elif move_state == "sprint":
		base_spd = GameConfig.SPEED_SPRINT

	# Apply Greed Bag weight slowdown & Suit perks
	var speed_mult = GameManager.get_bag_speed_multiplier()
	if GameManager.is_lockdown_active and SaveManager.equipped_suit == "lockdown_sprinter":
		speed_mult *= 1.10

	var target_vel = input_vec * (base_spd * speed_mult)
	if input_vec.length() > 0.1:
		velocity = velocity.move_toward(target_vel, GameConfig.PLAYER_ACCEL * delta)
		face_dir = input_vec.normalized()
		rotation = lerp_angle(rotation, face_dir.angle() + PI / 2.0, 14.0 * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, GameConfig.PLAYER_FRICTION * delta)

	move_and_slide()

	# 3. Sound rings & Footsteps
	_handle_movement_audio_and_noise(delta)

	# 4. Check back-interactions & hold pickpocketing
	_process_interactions(delta)

	# 5. Toss Coin / Use Gadget inputs
	if not is_bot_controlled:
		if Input.is_action_just_pressed("toss_coin"):
			toss_distraction_coin()
		if Input.is_action_just_pressed("use_gadget"):
			use_active_gadget()

	queue_redraw()

func _handle_movement_audio_and_noise(delta: float) -> void:
	if velocity.length() > 15.0:
		step_timer += delta
		var step_interval = 0.38 if move_state == "walk" else 0.24
		if step_timer >= step_interval:
			step_timer = 0.0
			var noise_rad = 0.0
			if move_state == "walk":
				noise_rad = GameConfig.NOISE_RADIUS_WALK
				AudioManager.play_sfx("footstep_soft", 0.1)
			elif move_state == "sprint":
				noise_rad = GameConfig.NOISE_RADIUS_SPRINT
				AudioManager.play_sfx("footstep_soft", 0.1)
				AudioManager.play_sfx("loot_bag_jingle", 0.15)

			# Suit noise dampener
			if SaveManager.equipped_suit == "velvet_paws":
				noise_rad *= 0.65

			if noise_rad > 0.0:
				Events.sound_emitted.emit(global_position, noise_rad, false)
				sound_ring_radius = 14.0
				sound_ring_alpha = 0.9

	if sound_ring_alpha > 0.0:
		sound_ring_radius += 180.0 * delta
		sound_ring_alpha -= 2.2 * delta

func _process_interactions(delta: float) -> void:
	target_guard = _find_nearest_interactable_guard()

	if target_guard == null:
		prompt_label.visible = false
		interact_progress.visible = false
		interact_hold_time = 0.0
		return

	var is_asleep = target_guard.current_state == "KNOCKED_OUT"
	var is_cuffed = target_guard.current_state == "CUFFED"

	if is_cuffed:
		prompt_label.visible = false
		interact_progress.visible = false
		return

	prompt_label.visible = true

	var act_tap = bot_interact_tap if is_bot_controlled else Input.is_action_just_pressed("interact")
	var act_hold = bot_interact_hold if is_bot_controlled else Input.is_action_pressed("interact")

	if is_asleep:
		prompt_label.text = "[E] Zip-Tie Cuff (%d)" % GameManager.free_cuffs_remaining
		if act_tap:
			if GameManager.free_cuffs_remaining > 0:
				GameManager.free_cuffs_remaining -= 1
				target_guard.apply_cuff()
				AudioManager.play_sfx("ziptie_ratchet")
				prompt_label.visible = false
	else:
		prompt_label.text = "Tap [E] Knockout | Hold [E] Pickpocket"

		if act_hold:
			interact_hold_time += delta
			interact_progress.visible = true
			interact_progress.value = (interact_hold_time / GameConfig.PICKPOCKET_HOLD_TIME) * 100.0

			if interact_hold_time >= GameConfig.PICKPOCKET_HOLD_TIME:
				# Completed Pickpocket!
				interact_hold_time = 0.0
				interact_progress.visible = false
				target_guard.apply_pickpocket()
				Events.coin_collected.emit(GameConfig.PICKPOCKET_COINS_AWARD, GameManager.level_total_coins)
				AudioManager.play_sfx("pickpocket_zip")
				JuiceManager.show_speech_bubble(target_guard, "Hey! My wallet?!", Color(1.0, 0.8, 0.2))
		else:
			if (interact_hold_time > 0.05 and interact_hold_time < GameConfig.PICKPOCKET_HOLD_TIME) or act_tap:
				interact_progress.visible = false
				interact_hold_time = 0.0
				
				# Check Heavy armor immunity
				if target_guard.archetype == "heavy":
					AudioManager.play_sfx("shutter_slam", 0.2)
					JuiceManager.show_speech_bubble(target_guard, "CLANG! Armor resists punch!", Color(1.0, 0.3, 0.3))
					JuiceManager.add_trauma(0.2)
				else:
					target_guard.apply_knockout()
					Events.coin_collected.emit(GameConfig.KNOCKOUT_COINS_AWARD, GameManager.level_total_coins)
					JuiceManager.show_speech_bubble(target_guard, "BONK!", Color(0.6, 0.8, 1.0))

func _find_nearest_interactable_guard() -> Node2D:
	var guards = get_tree().get_nodes_in_group("guards")
	var nearest: Node2D = null
	var min_dist = GameConfig.INTERACTION_MAX_DIST

	for g in guards:
		var d = global_position.distance_to(g.global_position)
		if d < min_dist:
			if g.current_state == "KNOCKED_OUT":
				return g
			# Back Angle check: dot product < -0.35 means player is behind guard!
			var guard_forward = Vector2.RIGHT.rotated(g.rotation)
			var to_player = (global_position - g.global_position).normalized()
			var dot = guard_forward.dot(to_player)
			if dot < GameConfig.BACK_STAB_DOT_THRESHOLD and g.current_state != "CHASE" and g.current_state != "CUFFED":
				nearest = g
				min_dist = d

	return nearest

func toss_distraction_coin() -> void:
	if GameManager.level_coins_collected <= 0:
		return
	GameManager.level_coins_collected -= 1
	var toss_dist = 140.0
	var target = global_position + face_dir * toss_dist
	Events.coin_tossed.emit(target)
	Events.sound_emitted.emit(target, GameConfig.NOISE_RADIUS_COIN_TOSS, true)
	AudioManager.play_sfx("coin_toss_clink")
	JuiceManager.add_trauma(0.15)

func use_active_gadget() -> void:
	var g = SaveManager.equipped_gadget
	if g == "smoke_pellet" and GameManager.smoke_pellets_remaining > 0:
		GameManager.smoke_pellets_remaining -= 1
		var smoke_scene = load("res://scenes/objects/SmokeCloud.tscn")
		var s = smoke_scene.instantiate()
		s.global_position = global_position
		get_parent().add_child(s)
		Events.gadget_used.emit("smoke_pellet", global_position)
		Events.sound_emitted.emit(global_position, 180.0, true)
	elif g == "bag_marbles" and GameManager.marbles_remaining > 0:
		GameManager.marbles_remaining -= 1
		var marble_scene = load("res://scenes/objects/MarblesHazard.tscn")
		var m = marble_scene.instantiate()
		m.global_position = global_position - face_dir * 32.0
		get_parent().add_child(m)
		Events.gadget_used.emit("bag_marbles", global_position)

func _on_coin_collected(_amount: int, _tot: int) -> void:
	_update_bag_display()

func _update_bag_display() -> void:
	var c = GameManager.level_coins_collected
	if c <= 0:
		bag_sprite.visible = false
	elif c <= GameConfig.BAG_TIER_LIGHT_MAX:
		bag_sprite.texture = load("res://assets/sprites/bag_light.png")
		bag_sprite.visible = true
	elif c <= GameConfig.BAG_TIER_MED_MAX:
		bag_sprite.texture = load("res://assets/sprites/bag_medium.png")
		bag_sprite.visible = true
	else:
		bag_sprite.texture = load("res://assets/sprites/bag_heavy.png")
		bag_sprite.visible = true

func _draw() -> void:
	if sound_ring_alpha > 0.0:
		draw_arc(Vector2.ZERO, sound_ring_radius, 0.0, TAU, 32, Color(1, 1, 1, sound_ring_alpha * 0.45), 2.5)
