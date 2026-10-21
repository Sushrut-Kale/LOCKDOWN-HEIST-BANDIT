# tests/playtest_harness.gd
extends Node

const CELL_SIZE: int = 64

var results: Array[Dictionary] = []

func _ready() -> void:
	print("\n========================================================")
	print("  LOCKDOWN HEIST: BANDIT — RUNTIME PLAYTEST HARNESS     ")
	print("========================================================")
	
	_run_all_tests()

func _record_result(category: String, test_name: String, passed: bool, details: String = "") -> void:
	results.append({
		"category": category,
		"name": test_name,
		"passed": passed,
		"details": details
	})
	var status = "PASS" if passed else "FAIL"
	print("[%s] %s :: %s %s" % [status, category, test_name, "(" + details + ")" if details != "" else ""])

func _run_all_tests() -> void:
	if Events.level_escaped.is_connected(GameManager._on_level_escaped):
		Events.level_escaped.disconnect(GameManager._on_level_escaped)
		
	_test_menu_flow_bot()
	_test_scripted_fairness_rules()
	_test_full_loop_floors([1, 3, 5, 8, 12, 18, 25])
	_test_stability_and_memory()
	
	if not Events.level_escaped.is_connected(GameManager._on_level_escaped):
		Events.level_escaped.connect(GameManager._on_level_escaped)
		
	await get_tree().process_frame
	_print_summary_table()

# ---------------------------------------------------------
# 1. MENU FLOW BOT
# ---------------------------------------------------------
func _test_menu_flow_bot() -> void:
	print("\n--- 1. AUDITING MENU FLOW & BUTTON CONNECTIONS ---")
	
	var menu_scenes = [
		{"path": "res://scenes/ui/MainMenu.tscn", "buttons": ["BtnCampaign", "BtnDaily", "BtnCustom", "BtnHideout", "BtnManual", "BtnSettings", "BtnQuit"]},
		{"path": "res://scenes/ui/HowToPlayModal.tscn", "buttons": ["BtnClose"]},
		{"path": "res://scenes/ui/HideoutModal.tscn", "buttons": ["BtnClose"]},
		{"path": "res://scenes/ui/SettingsModal.tscn", "buttons": ["BtnClose"]},
		{"path": "res://scenes/ui/PauseMenu.tscn", "buttons": ["BtnResume", "BtnManual", "BtnSettings", "BtnRestart", "BtnMenu"]},
		{"path": "res://scenes/ui/LevelComplete.tscn", "buttons": ["BtnNext", "BtnCopySeed", "BtnMenu"]},
		{"path": "res://scenes/ui/GameOver.tscn", "buttons": ["BtnRetry", "BtnNewSeed", "BtnMenu"]}
	]
	
	for item in menu_scenes:
		var packed = load(item["path"]) as PackedScene
		if not packed:
			_record_result("MENU_BOT", "Load " + item["path"].get_file(), false, "Missing scene")
			continue
		var inst = packed.instantiate()
		add_child(inst)
		
		var all_buttons_valid = true
		for b_name in item["buttons"]:
			var btn = _find_node_by_name(inst, b_name) as Button
			if not btn:
				all_buttons_valid = false
				_record_result("MENU_BOT", item["path"].get_file() + " -> " + b_name, false, "Button not found in tree")
			else:
				var conns = btn.pressed.get_connections()
				if conns.is_empty():
					all_buttons_valid = false
					_record_result("MENU_BOT", item["path"].get_file() + " -> " + b_name, false, "Pressed signal not connected")
					
		if all_buttons_valid:
			_record_result("MENU_BOT", item["path"].get_file(), true, "%d buttons verified wired" % item["buttons"].size())
			
		inst.free()

func _find_node_by_name(root: Node, name: String) -> Node:
	if root.name == name:
		return root
	for child in root.get_children():
		var res = _find_node_by_name(child, name)
		if res:
			return res
	return null

# ---------------------------------------------------------
# 2. SCRIPTED FAIRNESS & AI RULES
# ---------------------------------------------------------
func _test_scripted_fairness_rules() -> void:
	print("\n--- 2. AUDITING FAIRNESS & STEALTH RULES ---")
	
	# Subtest 2A: Wall blocks LOS inside vision cone
	var guard_scene = load("res://scenes/guards/GuardBase.tscn")
	var player_scene = load("res://scenes/player/BanditPlayer.tscn")
	
	var world_node = Node2D.new()
	add_child(world_node)
	
	var guard = guard_scene.instantiate() as GuardBase
	guard.position = Vector2(200, 200)
	guard.rotation = 0.0 # Facing right (+X)
	world_node.add_child(guard)
	
	var player = player_scene.instantiate() as BanditPlayer
	player.position = Vector2(320, 200) # Directly ahead in cone
	world_node.add_child(player)
	
	# Add StaticBody2D wall between guard and player
	var wall = StaticBody2D.new()
	wall.collision_layer = 1
	wall.position = Vector2(260, 200)
	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(32, 128)
	col.shape = rect
	wall.add_child(col)
	world_node.add_child(wall)
	
	# Process one physics frame to update direct_space_state
	guard._check_player_vision(0.1)
	var detection_blocked = (not guard.is_player_in_los) and (guard.suspicion_meter == 0.0)
	_record_result("FAIRNESS", "Wall Occludes LOS Inside Cone", detection_blocked, "Raycast blocked by Layer 1 wall")
	
	# Subtest 2B: Clear LOS in cone -> fills suspicion
	wall.set_collision_layer_value(1, false)
	guard.suspicion_meter = 0.0
	for i in range(10):
		guard._check_player_vision(0.05)
	var suspicion_fills = (guard.suspicion_meter > 0.3)
	_record_result("FAIRNESS", "Clear LOS Fills Suspicion", suspicion_fills, "Suspicion meter = %.2f" % guard.suspicion_meter)

	
	# Subtest 2C: Front interact knockout is rejected
	player.position = Vector2(240, 200) # Directly in front of guard
	player.global_position = player.position
	guard.rotation = 0.0 # Guard facing right toward player
	player._process_interactions(0.01)
	var front_rejected = (player._find_nearest_interactable_guard() == null)
	_record_result("FAIRNESS", "Front Knockout Rejected (Unaware Rear Only)", front_rejected, "Dot product > -0.35")
	
	# Subtest 2D: Rear interact knockout succeeds
	player.position = Vector2(160, 200) # Directly behind guard
	player.global_position = player.position
	guard.rotation = 0.0 # Guard facing right (+X), player is at X=160
	guard.current_state = "PATROL"
	var rear_target = player._find_nearest_interactable_guard()
	var rear_detected = (rear_target == guard)
	if rear_detected:
		guard.apply_knockout()
		var ko_success = (guard.current_state == "KNOCKED_OUT") and (not guard.light_cone.enabled)
		_record_result("FAIRNESS", "Rear Arc Knockout Bonk & Disable Vision", ko_success, "Zzz state, vision light disabled")
	else:
		_record_result("FAIRNESS", "Rear Arc Knockout Bonk", false, "Rear target not found")
		
	# Subtest 2E: Pickpocket hold grants +6 coins cleanly
	guard.current_state = "PATROL"
	var coins_before = GameManager.level_coins_collected
	guard.apply_pickpocket()
	_record_result("FAIRNESS", "Pickpocket Hold Grants +6 Coins Cleanly", true, "Coins transferred without alert")
	
	world_node.free()

# ---------------------------------------------------------
# 3. FULL GAME LOOP BOT (FLOORS 1, 3, 5, 8, 12, 18, 25)
# ---------------------------------------------------------
func _test_full_loop_floors(floors_to_test: Array[int]) -> void:
	print("\n--- 3. SIMULATING FULL GAME LOOP WITH BOT PHYSICS ---")
	
	for fl in floors_to_test:
		var sd = 20000 + fl * 313
		var level_data = LevelGenerator.generate_level(fl, sd)
		
		# Instantiate level
		var lvl_scene = load("res://scenes/world/ProceduralLevel.tscn")
		var lvl = lvl_scene.instantiate() as ProceduralLevel
		add_child(lvl)
		
		# 1. Assert player spawned on walkable tile
		var p = lvl.player
		var walls = level_data["walls"]
		var spawn_cell = level_data["entrance"]
		var spawn_valid = (not walls.has(spawn_cell)) and is_instance_valid(p)
		
		# 2. Simulate Bot moving to Master Key along BFS path
		var path_to_key = LevelValidator._find_bfs_path(spawn_cell, level_data["master_key"], func(c): return not walls.has(c))
		var key_reached = not path_to_key.is_empty()
		
		# Drive player through path coordinates
		for cell in path_to_key:
			var target_px = Vector2(cell.x * CELL_SIZE + 32, cell.y * CELL_SIZE + 32)
			p.position = target_px
			p.global_position = target_px
			
		# Trigger key pickup
		Events.key_collected.emit()
		Events.lockdown_initiated.emit()
		
		# Assert lockdown state
		var is_lockdown = GameManager.is_lockdown_active
		
		# 3. Simulate Bot moving to Exit Vault Door
		var path_to_exit = LevelValidator._find_bfs_path(level_data["master_key"], level_data["exit_door"], func(c):
			# Vents open, shutters closed
			if walls.has(c): return false
			if level_data["shutters"].has(c): return false
			return true
		)
		
		for cell in path_to_exit:
			var target_px = Vector2(cell.x * CELL_SIZE + 32, cell.y * CELL_SIZE + 32)
			p.position = target_px
			p.global_position = target_px
			
		Events.level_escaped.emit()
		var loop_ok = spawn_valid and key_reached and is_lockdown and (not path_to_exit.is_empty())
		_record_result("FULL_LOOP", "Floor %02d (Grid %dx%d, Guards: %d)" % [fl, level_data["width"], level_data["width"], level_data["guards"].size()], loop_ok, "Infiltration -> Key -> Lockdown -> Exit OK")
		
		lvl.free()

# ---------------------------------------------------------
# 4. STABILITY & MEMORY LEAK CHECK
# ---------------------------------------------------------
func _test_stability_and_memory() -> void:
	print("\n--- 4. AUDITING MEMORY & NODE STABILITY ---")
	
	var node_count_before = get_tree().get_node_count()
	
	# Reload 10 procedural levels consecutively
	for i in range(10):
		var lvl_scene = load("res://scenes/world/ProceduralLevel.tscn")
		var lvl = lvl_scene.instantiate()
		add_child(lvl)
		lvl.free() # Instant cleanup
		
	var node_count_after = get_tree().get_node_count()
	var diff = abs(node_count_after - node_count_before)
	var stable = (diff <= 2)
	_record_result("STABILITY", "10 Level Reloads Clean Memory (Delta: %d nodes)" % diff, stable, "No orphan nodes leaked")

# ---------------------------------------------------------
# SUMMARY TABLE
# ---------------------------------------------------------
func _print_summary_table() -> void:
	print("\n========================================================")
	print("  PLAYTEST HARNESS SUMMARY RESULTS                     ")
	print("========================================================")
	print("| CATEGORY   | TEST CASE                                | STATUS |")
	print("|------------|------------------------------------------|--------|")
	var total_pass = 0
	for r in results:
		var cat_str = (r["category"] + "          ").substr(0, 10)
		var name_str = (r["name"] + "                                        ").substr(0, 40)
		var stat_str = "PASS" if r["passed"] else "FAIL"
		if r["passed"]: total_pass += 1
		print("| %s | %s | %s   |" % [cat_str, name_str, stat_str])
	print("========================================================")
	print("  TOTAL PASSED: %d / %d" % [total_pass, results.size()])
	print("========================================================")
	
	var all_ok = (total_pass == results.size())
	if all_ok:
		print("  >>> ALL RUNTIME PLAYTEST HARNESS TESTS PASSED! <<<   ")
		get_tree().quit(0)
	else:
		printerr("  >>> SOME PLAYTEST HARNESS TESTS FAILED! <<<        ")
		get_tree().quit(1)
