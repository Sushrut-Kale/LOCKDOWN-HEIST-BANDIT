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
@onready var lockdown_manager: LockdownManager = $LockdownManager

# HUD nodes
@onready var lbl_floor: Label = $HUD/TopBarPanel/HBox/FloorBadge
@onready var lbl_seed: Label = $HUD/TopBarPanel/HBox/SeedBadge
@onready var lbl_coins: Label = $HUD/TopBarPanel/HBox/CoinBox/CoinLabel
@onready var lbl_timer: Label = $HUD/TopBarPanel/HBox/TimerLabel
@onready var key_icon: TextureRect = $HUD/TopBarPanel/HBox/KeyBox/KeyIcon
@onready var key_label: Label = $HUD/TopBarPanel/HBox/KeyBox/KeyLabel
@onready var lbl_cuffs: Label = $HUD/TopBarPanel/HBox/CuffBox/CuffsLabel
@onready var banner_casing: PanelContainer = $HUD/CasingBanner
@onready var banner_lockdown: PanelContainer = $HUD/LockdownBanner
@onready var touch_controls: Control = $HUD/TouchControls

var player: BanditPlayer = null
var shake_intensity: float = 0.0
var shake_timer: float = 0.0

func _ready() -> void:
	banner_lockdown.visible = false
	banner_casing.visible = true
	
	_connect_signals()
	_generate_and_spawn()
	_setup_touch_controls()
	AudioManager.start_gameplay_stems()

var _on_coin_callable: Callable

func _connect_signals() -> void:
	_on_coin_callable = func(_amt, _tot): _update_hud()
	Events.coin_collected.connect(_on_coin_callable)
	Events.key_collected.connect(_on_key_collected)
	Events.lockdown_initiated.connect(_on_lockdown)
	Events.camera_shake_requested.connect(_on_camera_shake)
	Events.casing_phase_ended.connect(_on_casing_phase_ended)

func _exit_tree() -> void:
	if Events.coin_collected.is_connected(_on_coin_callable):
		Events.coin_collected.disconnect(_on_coin_callable)
	if Events.key_collected.is_connected(_on_key_collected):
		Events.key_collected.disconnect(_on_key_collected)
	if Events.lockdown_initiated.is_connected(_on_lockdown):
		Events.lockdown_initiated.disconnect(_on_lockdown)
	if Events.camera_shake_requested.is_connected(_on_camera_shake):
		Events.camera_shake_requested.disconnect(_on_camera_shake)
	if Events.casing_phase_ended.is_connected(_on_casing_phase_ended):
		Events.casing_phase_ended.disconnect(_on_casing_phase_ended)

func _generate_and_spawn() -> void:
	var fl = GameManager.current_floor
	var sd = GameManager.current_seed
	var data = LevelGenerator.generate_level(fl, sd)
	
	GameManager.level_total_coins = data["coins"].size()
	
	var maze_w_px = data["width"] * CELL_SIZE
	var maze_h_px = data["height"] * CELL_SIZE
	var maze_center = Vector2(maze_w_px / 2.0, maze_h_px / 2.0)

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
	var spawn_pos = Vector2(data["entrance"].x * CELL_SIZE + 32, data["entrance"].y * CELL_SIZE + 32)
	player.position = spawn_pos
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
	# Set camera limits to maze bounds
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(maze_w_px)
	camera.limit_bottom = int(maze_h_px)
	
	# Enable Y-sorting
	y_sort_enabled = true
	walls_node.y_sort_enabled = true
	objects_node.y_sort_enabled = true
	guards_node.y_sort_enabled = true

	# 10. Spawn Fuse Boxes
	var fuse_scene = load("res://scenes/objects/FuseBox.tscn")
	for f_pos in data.get("fuse_boxes", []):
		var fb = fuse_scene.instantiate()
		fb.position = Vector2(f_pos.x * CELL_SIZE + 32, f_pos.y * CELL_SIZE + 32)
		objects_node.add_child(fb)

	# 11. Spawn Treasure Gem in far dead end
	if data["coins"].size() > 5:
		var gem_scene = load("res://scenes/objects/TreasureGem.tscn")
		var gem = gem_scene.instantiate()
		var gem_pos = data["coins"][data["coins"].size() - 1]
		gem.position = Vector2(gem_pos.x * CELL_SIZE + 32, gem_pos.y * CELL_SIZE + 32)
		objects_node.add_child(gem)

	# 12. Floor 1 Contextual Chalk Callouts
	if fl == 1:
		_spawn_chalk_hints(data)

	# 13. Initialize Casing Mode with centered camera

	lockdown_manager.init_casing(maze_center, Vector2(maze_w_px, maze_h_px))

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
	var has_l = walls.has(p + Vector2i.LEFT)
	var has_r = walls.has(p + Vector2i.RIGHT)
	if has_l and has_r:
		sp.region_rect = Rect2(4 * 64, 0, 64, 64)
	else:
		sp.region_rect = Rect2(3 * 64, 0, 64, 64)
	sb.add_child(sp)
	
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
	_create_chalk_label("Master Key triggers LOCKDOWN!", Vector2(data["master_key"].x * CELL_SIZE + 32, data["master_key"].y * CELL_SIZE - 45))
	_create_chalk_label("Escape Route: Vault unlocks in Lockdown!", Vector2(data["exit_door"].x * CELL_SIZE + 32, data["exit_door"].y * CELL_SIZE - 45))

func _create_chalk_label(text: String, pos: Vector2) -> void:
	var panel = PanelContainer.new()
	panel.position = pos - Vector2(160, 16)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.12, 0.24, 0.8)
	style.border_color = Color(0, 0.85, 1, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)
	
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", Color(0.7, 0.95, 1.0, 0.95))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(lbl)
	
	chalk_node.add_child(panel)

func _process(delta: float) -> void:
	# Camera smoothly tracks player when not in casing overview
	if player and not lockdown_manager.casing_active:
		camera.global_position = lerp(camera.global_position, player.global_position, 12.0 * delta)
		
	# Trauma-based Screen Shake via JuiceManager
	var shake_t = JuiceManager.get_shake_transform()
	camera.offset = shake_t["offset"]
	camera.rotation = shake_t["rotation"]


	# Dynamic 2D shadow budgeting for thermals/battery
	_update_guard_shadow_budget(delta)

	# Update HUD Timer
	var sec = int(GameManager.level_elapsed_seconds)
	lbl_timer.text = "%02d:%02d" % [sec / 60, sec % 60]

var _shadow_budget_timer: float = 0.0

func _update_guard_shadow_budget(delta: float) -> void:
	_shadow_budget_timer += delta
	if _shadow_budget_timer < 0.25:
		return
	_shadow_budget_timer = 0.0
	
	if player == null or not is_instance_valid(player):
		return
		
	var guards = get_tree().get_nodes_in_group("guards")
	if guards.size() <= 3:
		return
		
	var max_shadows = SaveManager.get_max_shadow_casting_guards()
	var p_pos = player.global_position
	
	# Sort guards by distance to player
	guards.sort_custom(func(a, b):
		return p_pos.distance_squared_to(a.global_position) < p_pos.distance_squared_to(b.global_position)
	)
	
	for i in range(guards.size()):
		var g = guards[i]
		if g and is_instance_valid(g) and g.has_node("LightCone"):
			var lc = g.get_node("LightCone") as PointLight2D
			if lc:
				lc.shadow_enabled = (i < max_shadows)

func _on_casing_phase_ended() -> void:
	var tw = create_tween()
	tw.tween_property(banner_casing, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func(): banner_casing.visible = false)

func _on_key_collected() -> void:
	key_icon.modulate = Color(1.0, 0.9, 0.2, 1.0)
	key_label.text = "KEY: ESCAPING!"
	key_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))

func _on_lockdown() -> void:
	banner_lockdown.visible = true
	var tw = create_tween()
	tw.tween_property(banner_lockdown, "modulate:a", 1.0, 0.2)
	tw.tween_interval(3.5)
	tw.tween_property(banner_lockdown, "modulate:a", 0.0, 0.8)

func _on_camera_shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity * SaveManager.screen_shake_intensity
	shake_timer = duration

func _update_hud() -> void:
	lbl_floor.text = "FLOOR %02d" % GameManager.current_floor
	lbl_seed.text = "#%d" % GameManager.current_seed
	lbl_coins.text = "%d / %d" % [GameManager.level_coins_collected, GameManager.level_total_coins]
	lbl_cuffs.text = "CUFFS: %d" % GameManager.free_cuffs_remaining

func _setup_touch_controls() -> void:
	if not touch_controls.has_node("MobileTouchControls"):
		var mtc_scene = load("res://scenes/ui/MobileTouchControls.tscn")
		if mtc_scene:
			var mtc = mtc_scene.instantiate()
			touch_controls.add_child(mtc)
	var mode = SaveManager.touch_controls_mode
	if mode == "force_on":
		touch_controls.visible = true
	elif mode == "off":
		touch_controls.visible = false
	else:
		touch_controls.visible = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")

func _on_pause_button_pressed() -> void:
	if hud.has_node("PauseMenu"):
		return
	var pause_modal = load("res://scenes/ui/PauseMenu.tscn").instantiate()
	hud.add_child(pause_modal)
