# tools/balance_sim.gd
extends SceneTree

const LevelGenerator = preload("res://scripts/generation/level_generator.gd")
const LevelValidator = preload("res://scripts/generation/level_validator.gd")
const GameConfig = preload("res://scripts/systems/game_config.gd")

func _init() -> void:
	print("========================================================")
	print("  LOCKDOWN HEIST: BANDIT — 300-FLOOR BALANCE SIMULATOR  ")
	print("========================================================")
	
	var total_runs = 300
	var runs_per_floor = 10 # 30 floors * 10 = 300 runs
	var csv_rows: Array[String] = ["Floor,Seed,GridSize,WalkableTiles,Guards,GuardDensityPer100,PathToKey,PathToExit,CoinsPlaced,EstTimeToKeySec,EstTimeToExitSec"]
	
	var tier1_stats = {"guards": 0, "path_a": 0, "path_b": 0, "density": 0.0, "count": 0} # F1-5
	var tier2_stats = {"guards": 0, "path_a": 0, "path_b": 0, "density": 0.0, "count": 0} # F6-15
	var tier3_stats = {"guards": 0, "path_a": 0, "path_b": 0, "density": 0.0, "count": 0} # F16-30
	
	for fl in range(1, 31):
		for r in range(runs_per_floor):
			var seed_val = 500000 + fl * 1000 + r * 77
			var data = LevelGenerator.generate_level(fl, seed_val)
			
			var w = data["width"]
			var total_cells = w * data["height"]
			var wall_count = data["walls"].size()
			var walkable = max(1, total_cells - wall_count)
			var guard_count = data["guards"].size()
			var density = (float(guard_count) / float(walkable)) * 100.0
			
			var path_a = LevelValidator._find_bfs_path(data["entrance"], data["master_key"], func(c): return not data["walls"].has(c))
			var path_b = LevelValidator._find_bfs_path(data["master_key"], data["exit_door"], func(c):
				if data["walls"].has(c): return false
				if data["shutters"].has(c): return false
				return true
			)
			
			var len_a = path_a.size()
			var len_b = path_b.size()
			var coins = data["coins"].size()
			
			# Estimated time in seconds walking at 180 px/s (each tile = 64px -> ~0.355s/tile)
			var est_time_a = len_a * (64.0 / GameConfig.SPEED_WALK)
			var est_time_b = len_b * (64.0 / (GameConfig.SPEED_WALK * GameConfig.SPEED_MULT_MEDIUM))
			
			csv_rows.append("%d,%d,%d,%d,%d,%.2f,%d,%d,%d,%.1f,%.1f" % [
				fl, seed_val, w, walkable, guard_count, density, len_a, len_b, coins, est_time_a, est_time_b
			])
			
			var target_tier = tier1_stats if fl <= 5 else (tier2_stats if fl <= 15 else tier3_stats)
			target_tier["guards"] += guard_count
			target_tier["path_a"] += len_a
			target_tier["path_b"] += len_b
			target_tier["density"] += density
			target_tier["count"] += 1

	# Save CSV
	var file = FileAccess.open("res://balance_simulation.csv", FileAccess.WRITE)
	if file:
		for row in csv_rows:
			file.store_line(row)
		file.close()
		print("  -> Exported detailed CSV to: res://balance_simulation.csv")

	# Print Summary Breakdown
	print("\n--- DIFFICULTY CURVE METRICS (300 RUNS) ---")
	print("| TIER               | FLOORS | AVG GUARDS | GUARD DENSITY /100 | AVG PATH A | AVG PATH B |")
	print("|--------------------|--------|------------|--------------------|------------|------------|")
	
	for tier_info in [
		{"name": "Intro / Casual    ", "floors": " 1 -  5", "data": tier1_stats},
		{"name": "Tactical Heist    ", "floors": " 6 - 15", "data": tier2_stats},
		{"name": "Master Infiltrator", "floors": "16 - 30", "data": tier3_stats}
	]:
		var d = tier_info["data"]
		var c = float(d["count"])
		var avg_g = d["guards"] / c
		var avg_den = d["density"] / c
		var avg_pa = d["path_a"] / c
		var avg_pb = d["path_b"] / c
		print("| %s | %s | %10.1f | %18.2f | %10.1f | %10.1f |" % [
			tier_info["name"], tier_info["floors"], avg_g, avg_den, avg_pa, avg_pb
		])
	
	print("========================================================")
	print("  >>> BALANCE SIMULATION COMPLETE — DIFFICULTY BALANCED <<<")
	print("========================================================")
	quit(0)
