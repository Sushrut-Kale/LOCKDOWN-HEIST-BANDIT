# scripts/generation/level_generator.gd
class_name LevelGenerator
extends RefCounted

const LevelValidator = preload("res://scripts/generation/level_validator.gd")
const CELL_SIZE: int = 64


func generate(floor_num: int, base_seed: int) -> Dictionary:
	return generate_level(floor_num, base_seed)

# Generates complete level dictionary data with guaranteed dual-graph validation
static func generate_level(floor_num: int, base_seed: int) -> Dictionary:

	var width = GameManager.get_grid_width(floor_num)
	var height = width # Square maze
	var guard_count = GameManager.get_guard_count(floor_num)

	for attempt in range(25):
		var curr_seed = base_seed + attempt * 1013
		var data = _build_single_candidate(floor_num, curr_seed, width, height, guard_count)
		var val_res = LevelValidator.validate_level_data(
			width, height, data["walls"],
			data["entrance"], data["exit_door"], data["master_key"],
			data["shutters"], data["vents"]
		)
		if val_res["valid"]:
			data["attempt"] = attempt
			data["seed_used"] = curr_seed
			return data

	# Fallback guaranteed layout
	return _build_fallback_layout(floor_num, base_seed, width, height, guard_count)

static func _build_single_candidate(floor_num: int, seed_val: int, w: int, h: int, guards_needed: int) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val

	# 1. Initialize grid: all walls
	var walls: Dictionary = {}
	for y in range(h):
		for x in range(w):
			walls[Vector2i(x, y)] = true

	# 2. Randomized DFS Maze Carving (on odd cells)
	var start_cell = Vector2i(1, 1)
	walls.erase(start_cell)
	var stack: Array[Vector2i] = [start_cell]
	var visited: Dictionary = {start_cell: true}

	var dirs = [
		Vector2i(0, -2), Vector2i(0, 2),
		Vector2i(-2, 0), Vector2i(2, 0)
	]

	while not stack.is_empty():
		var curr = stack.back()
		var neighbors: Array[Vector2i] = []
		for d in dirs:
			var nxt = curr + d
			if nxt.x > 0 and nxt.x < w - 1 and nxt.y > 0 and nxt.y < h - 1:
				if not visited.has(nxt):
					neighbors.append(nxt)

		if not neighbors.is_empty():
			var chosen = neighbors[rng.randi() % neighbors.size()]
			var wall_between = curr + (chosen - curr) / 2
			walls.erase(wall_between)
			walls.erase(chosen)
			visited[chosen] = true
			stack.push_back(chosen)
		else:
			stack.pop_back()

	# 3. Controlled Loop Carving (remove 18% of inner walls to create flanking loops)
	var inner_walls: Array[Vector2i] = []
	for y in range(2, h - 2):
		for x in range(2, w - 2):
			var p = Vector2i(x, y)
			if walls.has(p):
				# Check if connecting two distinct floor corridors
				var horiz_open = (not walls.has(p + Vector2i.LEFT)) and (not walls.has(p + Vector2i.RIGHT))
				var vert_open = (not walls.has(p + Vector2i.UP)) and (not walls.has(p + Vector2i.DOWN))
				if horiz_open or vert_open:
					inner_walls.append(p)

	for p in inner_walls:
		if rng.randf() < 0.18:
			walls.erase(p)

	# 4. Identify open floors
	var open_floors: Array[Vector2i] = []
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var p = Vector2i(x, y)
			if not walls.has(p):
				open_floors.append(p)

	# 5. Smart BFS Placement for Entrance, Exit, Key
	var entrance = Vector2i(1, 1)
	if walls.has(entrance):
		walls.erase(entrance)

	# Safe spawn pocket around entrance
	for d in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i(1, 1)]:
		walls.erase(entrance + d)

	# BFS distances from entrance
	var dist_map: Dictionary = {entrance: 0}
	var bfs_q: Array[Vector2i] = [entrance]
	var max_dist = 0
	var farthest_cell = entrance

	while not bfs_q.is_empty():
		var c = bfs_q.pop_front()
		var d = dist_map[c]
		if d > max_dist:
			max_dist = d
			farthest_cell = c
		for off in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
			var nxt = c + off
			if not walls.has(nxt) and not dist_map.has(nxt):
				dist_map[nxt] = d + 1
				bfs_q.push_back(nxt)

	var exit_door = farthest_cell
	
	# Master Key in upper quartile distance (between 50% and 80% max distance)
	var candidate_key_cells: Array[Vector2i] = []
	for c in dist_map.keys():
		var d = dist_map[c]
		if d >= int(max_dist * 0.5) and d <= int(max_dist * 0.85):
			candidate_key_cells.append(c)

	var master_key = candidate_key_cells[rng.randi() % candidate_key_cells.size()] if not candidate_key_cells.is_empty() else farthest_cell

	# 6. Shutters and Vents placement
	# Find primary path from entrance to key to place shutters
	var primary_path = LevelValidator._find_bfs_path(entrance, master_key, func(p): return not walls.has(p))
	var shutters: Array[Vector2i] = []
	var vents: Array[Vector2i] = []

	if primary_path.size() > 6:
		# Place 1 or 2 shutters on corridor bottlenecks along primary path
		var shutter_idx = int(primary_path.size() * 0.45)
		var s_pos = primary_path[shutter_idx]
		shutters.append(s_pos)

	# Vents: Place adjacent to walls to provide secret bypasses
	for c in open_floors:
		if c != entrance and c != exit_door and c != master_key and not shutters.has(c):
			# If adjacent to a wall that separates two corridors, vent provides shortcut
			if rng.randf() < 0.04 and vents.size() < 4:
				vents.append(c)

	# 7. Coins and Loot (Place 12 to 30 coins depending on floor)
	var coins: Array[Vector2i] = []
	var total_coins_count = clampi(14 + floor_num * 2, 14, 45)
	var available_cells = open_floors.duplicate()
	available_cells.erase(entrance)
	available_cells.erase(exit_door)
	available_cells.erase(master_key)
	for s in shutters: available_cells.erase(s)
	for v in vents: available_cells.erase(v)

	available_cells.shuffle()
	for i in range(mini(total_coins_count, available_cells.size())):
		coins.append(available_cells[i])

	# 8. Lockers & Creaky floors
	var lockers: Array[Vector2i] = []
	var creaky_floors: Array[Vector2i] = []
	var fuse_boxes: Array[Vector2i] = []

	for c in open_floors:
		if c != entrance and c != exit_door and c != master_key:
			var rand_val = rng.randf()
			if rand_val < 0.03 and lockers.size() < 6:
				lockers.append(c)
			elif rand_val < 0.06 and creaky_floors.size() < 8:
				creaky_floors.append(c)
			elif rand_val < 0.08 and fuse_boxes.size() < 2:
				fuse_boxes.append(c)

	# 9. Guard Spawns and Patrol Waypoints
	var guards: Array[Dictionary] = []
	var guard_candidates = open_floors.duplicate()
	# Filter out entrance safe zone (minimum distance of 5 tiles from entrance)
	guard_candidates = guard_candidates.filter(func(c): return dist_map.get(c, 0) >= 5 and c != master_key and c != exit_door)

	for g_idx in range(mini(guards_needed, guard_candidates.size())):
		var g_pos = guard_candidates[g_idx]
		var arche = _select_archetype(floor_num, g_idx, rng)
		# Build 2-3 patrol waypoints near guard spawn
		var waypoints: Array[Vector2i] = [g_pos]
		for off in [Vector2i(2, 0), Vector2i(0, 2), Vector2i(-2, 0), Vector2i(0, -2)]:
			var wp = g_pos + off
			if not walls.has(wp) and dist_map.get(wp, 0) >= 4:
				waypoints.append(wp)
				if waypoints.size() >= 3:
					break

		guards.append({
			"type": arche,
			"spawn_cell": g_pos,
			"waypoints": waypoints
		})

	return {
		"width": w,
		"height": h,
		"walls": walls,
		"entrance": entrance,
		"exit_door": exit_door,
		"master_key": master_key,
		"shutters": shutters,
		"vents": vents,
		"coins": coins,
		"lockers": lockers,
		"creaky_floors": creaky_floors,
		"fuse_boxes": fuse_boxes,
		"guards": guards
	}

static func _select_archetype(fl: int, idx: int, rng: RandomNumberGenerator) -> String:
	# Introduce archetypes progressively
	var pool = ["rookie"]
	if fl >= 4:
		pool.append("veteran")
	if fl >= 7:
		pool.append("radio")
	if fl >= 11:
		pool.append("k9")
	if fl >= 15:
		pool.append("heavy")
	if fl >= 20:
		pool.append("drone")
		
	# First guard on floor 1-3 is always rookie
	if fl < 4 or idx == 0:
		return "rookie"
	return pool[rng.randi() % pool.size()]

static func _build_fallback_layout(floor_num: int, seed_val: int, w: int, h: int, guards_needed: int) -> Dictionary:
	# Simple guaranteed open loop layout
	var walls: Dictionary = {}
	# Border walls
	for x in range(w):
		walls[Vector2i(x, 0)] = true
		walls[Vector2i(x, h - 1)] = true
	for y in range(h):
		walls[Vector2i(0, y)] = true
		walls[Vector2i(w - 1, y)] = true

	# Central divider wall with two open passages
	for y in range(2, h - 2):
		if y != 3 and y != h - 4:
			walls[Vector2i(w / 2, y)] = true

	var entrance = Vector2i(1, 1)
	var exit_door = Vector2i(w - 2, h - 2)
	var master_key = Vector2i(w - 2, 2)
	var shutters: Array[Vector2i] = [Vector2i(w / 2, 3)]
	var vents: Array[Vector2i] = [Vector2i(w / 2, h - 4)]
	var coins: Array[Vector2i] = [Vector2i(2, 2), Vector2i(2, h - 3), Vector2i(w - 3, h - 3)]
	
	var guards: Array[Dictionary] = []
	for i in range(mini(guards_needed, 4)):
		guards.append({
			"type": "rookie",
			"spawn_cell": Vector2i(w - 3, 4 + i * 2),
			"waypoints": [Vector2i(w - 3, 4 + i * 2), Vector2i(w - 4, 4 + i * 2)]
		})

	return {
		"width": w,
		"height": h,
		"walls": walls,
		"entrance": entrance,
		"exit_door": exit_door,
		"master_key": master_key,
		"shutters": shutters,
		"vents": vents,
		"coins": coins,
		"lockers": [Vector2i(1, 3)],
		"creaky_floors": [Vector2i(3, 1)],
		"fuse_boxes": [],
		"guards": guards,
		"attempt": 999,
		"seed_used": seed_val
	}
