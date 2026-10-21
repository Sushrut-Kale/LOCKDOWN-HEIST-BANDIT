# scripts/generation/level_validator.gd
class_name LevelValidator
extends RefCounted

# Dual-Graph Lock-Proof Validator:
# Evaluates Graph A (Infiltration) and Graph B (Lockdown) using BFS grid pathfinding.

static func validate_level_data(grid_w: int, grid_h: int, walls: Dictionary,
	entrance: Vector2i, exit_door: Vector2i, key_pos: Vector2i,
	shutters: Array, vents: Array) -> Dictionary:
	
	var shutter_dict: Dictionary = {}
	for s in shutters:
		shutter_dict[Vector2i(s.x, s.y)] = true
		
	var vent_dict: Dictionary = {}
	for v in vents:
		vent_dict[Vector2i(v.x, v.y)] = true

	# --- STATE A (Pre-Key: Shutters OPEN, Vents CLOSED) ---
	# Can we reach Master Key from Entrance?
	# Passable: not a wall, and not a closed vent
	var is_passable_a = func(p: Vector2i) -> bool:
		if p.x < 0 or p.x >= grid_w or p.y < 0 or p.y >= grid_h:
			return false
		if walls.has(p):
			return false
		if vent_dict.has(p): # Vents closed in state A
			return false
		return true

	var path_a = _find_bfs_path(entrance, key_pos, is_passable_a)
	if path_a.is_empty():
		return {"valid": false, "reason": "Graph A failed: No path from Entrance to Key"}

	# --- STATE B (Post-Key Lockdown: Shutters CLOSED, Vents OPEN) ---
	# Can we reach Exit Door from Key Position?
	# Passable: not a wall, and not a closed shutter
	var is_passable_b = func(p: Vector2i) -> bool:
		if p.x < 0 or p.x >= grid_w or p.y < 0 or p.y >= grid_h:
			return false
		if walls.has(p):
			return false
		if shutter_dict.has(p): # Shutters closed in state B
			return false
		return true

	var path_b = _find_bfs_path(key_pos, exit_door, is_passable_b)
	if path_b.is_empty():
		return {"valid": false, "reason": "Graph B failed: No path from Key to Exit"}

	return {
		"valid": true,
		"path_a_len": path_a.size(),
		"path_b_len": path_b.size()
	}

static func _find_bfs_path(start: Vector2i, goal: Vector2i, is_passable: Callable) -> Array[Vector2i]:
	if start == goal:
		return [start]
		
	var queue: Array[Vector2i] = [start]
	var came_from: Dictionary = {start: start}
	var dirs = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
	
	while not queue.is_empty():
		var curr = queue.pop_front()
		if curr == goal:
			break
			
		for d in dirs:
			var nxt = curr + d
			if not came_from.has(nxt) and is_passable.call(nxt):
				came_from[nxt] = curr
				queue.push_back(nxt)
				
	if not came_from.has(goal):
		return [] # No path found
		
	# Reconstruct path
	var path: Array[Vector2i] = []
	var step = goal
	while step != start:
		path.push_back(step)
		step = came_from[step]
	path.push_back(start)
	path.reverse()
	return path
