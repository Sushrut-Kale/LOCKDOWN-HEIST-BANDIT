# tools/android_perf_probe_runner.gd
extends Node

func _ready() -> void:
	print("\n========================================================")
	print("  LOCKDOWN HEIST: BANDIT — ANDROID PERF PROBE           ")
	print("========================================================\n")
	_run_probe()

func _run_probe() -> void:
	var floors_to_test = [12, 25]
	var results = []

	for fl in floors_to_test:
		var metrics = await _probe_floor(fl, 4.0)
		results.append(metrics)

	print("\n========================================================")
	print("  PERFORMANCE PROBE RESULTS TABLE                       ")
	print("========================================================")
	print("| Floor | Grid Size | Guards | Avg FPS | Min FPS | Draw Calls | 2D Objects | Mem (MB) | Status |")
	print("|-------|-----------|--------|---------|---------|------------|------------|----------|--------|")
	for r in results:
		var status = "PASS (60fps)" if r["avg_fps"] >= 58.0 else ("PASS (30+fps)" if r["min_fps"] >= 30.0 else "WARN")
		print("| Fl %02d | %02dx%02d   | %02d     | %6.1f  | %6.1f  | %10d | %10d | %8.2f | %-6s |" % [
			r["floor"], r["grid_w"], r["grid_w"], r["guards"],
			r["avg_fps"], r["min_fps"], r["draw_calls"], r["objects"], r["mem_mb"], status
		])
	print("========================================================\n")
	get_tree().quit(0)

func _probe_floor(floor_num: int, duration_sec: float) -> Dictionary:
	var grid_w = GameManager.get_grid_width(floor_num)
	var guard_count = GameManager.get_guard_count(floor_num)
	var seed_val = 1337 + floor_num * 777
	
	print("[PROBE] Testing Floor %02d (Grid: %dx%d, Guards: %d, Seed: #%d)..." % [floor_num, grid_w, grid_w, guard_count, seed_val])
	
	GameManager.current_floor = floor_num
	GameManager.current_seed = seed_val
	GameManager.is_lockdown_active = false
	
	var level_scene = load("res://scenes/world/ProceduralLevel.tscn")
	var level = level_scene.instantiate()
	add_child(level)
	
	var fps_samples = []
	var draw_call_samples = []
	var obj_samples = []
	var mem_samples = []
	
	var total_frames = int(duration_sec * 60.0)
	
	for i in range(total_frames):
		var t_start = Time.get_ticks_usec()
		await get_tree().process_frame
		var frame_dur = Time.get_ticks_usec() - t_start
		var est_fps = clampf(1000000.0 / float(max(1, frame_dur)), 10.0, 60.0)
		fps_samples.append(est_fps)
		
		# Mid-test lockdown trigger
		if i == (total_frames / 2) and not GameManager.is_lockdown_active:
			Events.lockdown_initiated.emit()
			
		var draws = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		draw_call_samples.append(draws)
		
		var objs = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		obj_samples.append(objs)
		
		var mem = Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0)
		mem_samples.append(mem)
		
	var sum_fps = 0.0
	var min_fps = 999.0
	for f in fps_samples:
		sum_fps += f
		if f < min_fps: min_fps = f
	var avg_fps = sum_fps / float(max(1, fps_samples.size()))
	
	var max_draws = 0
	for d in draw_call_samples:
		if d > max_draws: max_draws = d
		
	var avg_objs = 0
	for o in obj_samples:
		avg_objs += o
	avg_objs = int(float(avg_objs) / float(max(1, obj_samples.size())))
	
	var max_mem = 0.0
	for m in mem_samples:
		if m > max_mem: max_mem = m

	level.queue_free()
	
	return {
		"floor": floor_num,
		"grid_w": grid_w,
		"guards": guard_count,
		"avg_fps": avg_fps,
		"min_fps": min_fps,
		"draw_calls": max_draws,
		"objects": avg_objs,
		"mem_mb": max_mem
	}
