# scripts/systems/procedural_level.gd
class_name ProceduralLevel
extends Node2D

const LevelGenerator = preload("res://scripts/generation/level_generator.gd")
const CELL_SIZE: int = 64


@onready var walls_node: Node2D = $Walls
@onready var floors_node: Node2D = $Floors
@onready var objects_node: Node2D = $Objects
@onready var guards_node: Node2D = $Guards
@onready var chalk_node: Node2D = $ChalkHints
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var canvas_modulate: CanvasModulate = $CanvasModulate

# HUD nodes
@onready var lbl_floor: Label = $HUD/TopBar/FloorLabel
@onready var lbl_coins: Label = $HUD/TopBar/CoinLabel
@onready var lbl_timer: Label = $HUD/TopBar/TimerLabel
@onready var key_icon: TextureRect = $HUD/TopBar/KeyIcon
@onready var lbl_cuffs: Label = $HUD/TopBar/CuffsLabel
@onready var banner_lockdown: Panel = $HUD/LockdownBanner
@onready var touch_controls: Control = $HUD/TouchControls

var player: BanditPlayer = null
var shake_intensity: float = 0.0
var shake_timer: float = 0.0

func _ready() -> void:
	banner_lockdown.visible = false
	key_icon.modulate = Color(0.3, 0.3, 0.4, 0.7)
	
	_connect_signals()
	_generate_and_spawn()
	_setup_touch_controls()
	AudioManager.start_gameplay_stems()

func _connect_signals() -> void:
	Events.coin_collected.connect(func(_amt, _tot): _update_hud())
	Events.key_collected.connect(_on_key_collected)
	Events.lockdown_initiated.connect(_on_lockdown)
	Events.camera_shake_requested.connect(_on_camera_shake)

func _generate_and_spawn() -> void:
	var fl = GameManager.current_floor
	var sd = GameManager.current_seed
	var data = LevelGenerator.generate_level(fl, sd)
	
	GameManager.level_total_coins = data["coins"].size()
	
	# 1. Spawn Blueprint Floor Tiles
	var floor_tex = load("res://assets/sprites/tileset_blueprint.png")
	for y in range(data["height"]):
		for x in range(data["width"]):
			var p = Vector2i(x, y)
			if not data["walls"].has(p):
				var s = Sprite2D.new()
				s.texture = floor_tex
				s.region_enabled = true
				s.region_rect = Rect2(0, 0, 64, 64)
				s.position = Vector2(x * CELL_SIZE + 32, y * CELL_SIZE + 32)
				floors_node.add_child(s)

	# 2. Spawn Double-Lined Blueprint Walls with StaticBody2D
	for p in data["walls"].keys():
		_spawn_wall(p, data["walls"])

	# 3. Spawn Player at Entrance
	var p_scene = load("res://scenes/player/BanditPlayer.tscn")
	player = p_scene.instantiate() as BanditPlayer
	player.position = Vector2(data["entrance"].x * CELL_SIZE + 32, data["entrance"].y * CELL_SIZE + 32)
	add_child(player)

	# 4. Spawn Exit Vault Door
	var exit_scene = load("res://scenes/objects/ExitVaultDoor.tscn")
	var exit_obj = exit_scene.instantiate()
	exit_obj.position = Vector2(data["exit_door"].x * CELL_SIZE + 32, data["exit_door"].y * CELL_SIZE + 32)
	objects_node.add_child(exit_obj)

	# 5. Spawn Master Key
	var key_scene = load("res://scenes/objects/MasterKey.tscn")
	var key_obj = key_scene.instantiate()
	key_obj.position = Vector2(data["master_key"].x * CELL_SIZE + 32, data["master_key"].y * CELL_SIZE + 32)
	objects_node.add_child(key_obj)

	# 6. Spawn Shutters & Vents
	var shutter_scene = load("res://scenes/objects/ShutterDoor.tscn")
	for s_pos in data["shutters"]:
		var sh = shutter_scene.instantiate()
		sh.position = Vector2(s_pos.x * CELL_SIZE + 32, s_pos.y * CELL_SIZE + 32)
		objects_node.add_child(sh)

	var vent_scene = load("res://scenes/objects/VentGrate.tscn")
	for v_pos in data["vents"]:
		var vt = vent_scene.instantiate()
		vt.position = Vector2(v_pos.x * CELL_SIZE + 32, v_pos.y * CELL_SIZE + 32)
		objects_node.add_child(vt)

	# 7. Spawn Coins
	var coin_scene = load("res://scenes/objects/CoinPickup.tscn")
	for c_pos in data["coins"]:
		var cn = coin_scene.instantiate()
		cn.position = Vector2(c_pos.x * CELL_SIZE + 32, c_pos.y * CELL_SIZE + 32)
		objects_node.add_child(cn)

	# 8. Spawn Lockers
	var locker_scene = load("res://scenes/objects/LockerHideout.tscn")
	for l_pos in data["lockers"]:
		var lk = locker_scene.instantiate()
		lk.position = Vector2(l_pos.x * CELL_SIZE + 32, l_pos.y * CELL_SIZE + 32)
		objects_node.add_child(lk)

	# 9. Spawn Guards
	var guard_scene = load("res://scenes/guards/GuardBase.tscn")
	for g_info in data["guards"]:
		var gd = guard_scene.instantiate() as GuardBase
		gd.archetype = g_info["type"]
		gd.position = Vector2(g_info["spawn_cell"].x * CELL_SIZE + 32, g_info["spawn_cell"].y * CELL_SIZE + 32)
		var wps: Array[Vector2] = []
		for wp in g_info["waypoints"]:
			wps.append(Vector2(wp.x * CELL_SIZE + 32, wp.y * CELL_SIZE + 32))
		gd.patrol_waypoints = wps
		guards_node.add_child(gd)

	# 10. Floor 1 Contextual Chalk Callouts
	if fl == 1:
		_spawn_chalk_hints(data)

	_update_hud()

func _spawn_wall(p: Vector2i, walls: Dictionary) -> void:
	var sb = StaticBody2D.new()
	sb.collision_layer = 1
	sb.collision_mask = 0
	sb.position = Vector2(p.x * CELL_SIZE + 32, p.y * CELL_SIZE + 32)
	
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(64, 64)
	col.shape = shape
	sb.add_child(col)
	
	var sp = Sprite2D.new()
	sp.texture = load("res://assets/sprites/tileset_blueprint.png")
	sp.region_enabled = true
	# Select wall frame: 3 (Solid), 4 (Horiz double), 5 (Vert double)
	var has_l = walls.has(p + Vector2i.LEFT)
	var has_r = walls.has(p + Vector2i.RIGHT)
	if has_l and has_r:
		sp.region_rect = Rect2(4 * 64, 0, 64, 64)
	else:
		sp.region_rect = Rect2(3 * 64, 0, 64, 64)
	sb.add_child(sp)
	
	# Light Occluder so flashlight cones cast crisp shadows!
	var occluder = LightOccluder2D.new()
	var occ_poly = OccluderPolygon2D.new()
	occ_poly.polygon = PackedVector2Array([
		Vector2(-32, -32), Vector2(32, -32),
		Vector2(32, 32), Vector2(-32, 32)
	])
	occluder.occluder = occ_poly
	sb.add_child(occluder)
	
	walls_node.add_child(sb)

func _spawn_chalk_hints(data: Dictionary) -> void:
	_create_chalk_label("Sneak behind guard -> Tap [E] Knockout", Vector2(data["entrance"].x * CELL_SIZE + 32, data["entrance"].y * CELL_SIZE + 100))
	_create_chalk_label("Master Key triggers LOCKDOWN!", Vector2(data["master_key"].x * CELL_SIZE + 32, data["master_key"].y * CELL_SIZE - 40))
	_create_chalk_label("Escape Route: Vault unlocks in Lockdown!", Vector2(data["exit_door"].x * CELL_SIZE + 32, data["exit_door"].y * CELL_SIZE - 40))

func _create_chalk_label(text: String, pos: Vector2) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.position = pos - Vector2(120, 10)
	lbl.modulate = Color(0.4, 0.8, 1.0, 0.6)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chalk_node.add_child(lbl)

func _process(delta: float) -> void:
	# Camera follow player
	if player:
		camera.global_position = lerp(camera.global_position, player.global_position, 8.0 * delta)
		
	# Screen shake
	if shake_timer > 0.0:
		shake_timer -= delta
		var offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		camera.offset = offset
	else:
		camera.offset = Vector2.ZERO

	# Update HUD Timer
	var sec = int(GameManager.level_elapsed_seconds)
	lbl_timer.text = "%02d:%02d" % [sec / 60, sec % 60]

func _on_key_collected() -> void:
	key_icon.modulate = Color(1.0, 0.9, 0.2, 1.0) # Glowing gold

func _on_lockdown() -> void:
	banner_lockdown.visible = true
	var tw = create_tween()
	tw.tween_property(banner_lockdown, "modulate:a", 1.0, 0.2)
	tw.tween_interval(3.0)
	tw.tween_property(banner_lockdown, "modulate:a", 0.0, 0.8)

func _on_camera_shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity * SaveManager.screen_shake_intensity
	shake_timer = duration

func _update_hud() -> void:
	lbl_floor.text = "FLOOR %02d (SEED: #%d)" % [GameManager.current_floor, GameManager.current_seed]
	lbl_coins.text = "LOOT: %d / %d" % [GameManager.level_coins_collected, GameManager.level_total_coins]
	lbl_cuffs.text = "CUFFS: %d" % GameManager.free_cuffs_remaining

func _setup_touch_controls() -> void:
	var mode = SaveManager.touch_controls_mode
	if mode == "force_on":
		touch_controls.visible = true
	elif mode == "off":
		touch_controls.visible = false
	else:
		# Auto: detect touchscreen
		touch_controls.visible = DisplayServer.is_touchscreen_available()

func _on_pause_button_pressed() -> void:
	var pause_modal = load("res://scenes/ui/PauseMenu.tscn").instantiate()
	hud.add_child(pause_modal)
