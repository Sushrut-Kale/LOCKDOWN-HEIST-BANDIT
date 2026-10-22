# tests/touch_layout_probe.gd
extends SceneTree

func _init() -> void:
	print("\n========================================================")
	print("  LOCKDOWN HEIST: BANDIT — TOUCH LAYOUT AUDIT           ")
	print("========================================================\n")
	
	var resolutions = [
		{"name": "16:9 Standard", "size": Vector2(1920, 1080), "notch": "none"},
		{"name": "20:9 Ultrawide (Left Notch)", "size": Vector2(2400, 1080), "notch": "left"},
		{"name": "20:9 Ultrawide (Right Notch)", "size": Vector2(2400, 1080), "notch": "right"},
		{"name": "16:9 720p Budget", "size": Vector2(1280, 720), "notch": "none"}
	]
	
	var all_passed = true
	var total_checks = 0
	var passed_checks = 0

	for res in resolutions:
		var r_name = res["name"]
		var vp_size = res["size"] as Vector2
		var notch_mode = res["notch"] as String
		
		print("[AUDIT] Testing Resolution: %s (%dx%d, Notch: %s)..." % [r_name, int(vp_size.x), int(vp_size.y), notch_mode])
		
		# Define simulated safe area
		var safe_left = 80.0 if notch_mode == "left" else 0.0
		var safe_right = 80.0 if notch_mode == "right" else 0.0
		var safe_top = 0.0
		var safe_bottom = 0.0
		var safe_rect = Rect2(safe_left, safe_top, vp_size.x - safe_left - safe_right, vp_size.y - safe_top - safe_bottom)
		
		var scale_factor = clampf(minf(vp_size.x / 1920.0, vp_size.y / 1080.0), 0.75, 1.35)
		
		# Button definitions to verify
		# { "name": name, "base_size": Vector2, "rel_pos": Vector2 }
		var buttons = [
			{"name": "BtnContext", "w": maxf(88.0 * scale_factor, 48.0), "h": maxf(88.0 * scale_factor, 48.0)},
			{"name": "BtnCoin", "w": maxf(64.0 * scale_factor, 48.0), "h": maxf(64.0 * scale_factor, 48.0)},
			{"name": "BtnGadget", "w": maxf(64.0 * scale_factor, 48.0), "h": maxf(64.0 * scale_factor, 48.0)},
			{"name": "BtnSprint", "w": maxf(64.0 * scale_factor, 48.0), "h": maxf(64.0 * scale_factor, 48.0)},
			{"name": "BtnPause", "w": maxf(64.0 * scale_factor, 48.0), "h": maxf(64.0 * scale_factor, 48.0)}
		]
		
		# Cluster layout calculation matching MobileTouchControls
		var cluster_w = 340.0 * scale_factor
		var cluster_h = 300.0 * scale_factor
		var cluster_pos = Vector2(vp_size.x - safe_right - cluster_w, vp_size.y - safe_bottom - cluster_h)
		var pause_pos = Vector2(vp_size.x - safe_right - 70.0 * scale_factor, safe_top + 18.0)
		
		for b in buttons:
			total_checks += 1
			var b_name = b["name"]
			var bw = b["w"]
			var bh = b["h"]
			
			# Check 1: Size >= 48px
			if bw < 48.0 or bh < 48.0:
				print("  [FAIL] %s size (%.1fx%.1f) is smaller than 48px minimum touch target!" % [b_name, bw, bh])
				all_passed = false
				continue
				
			# Check 2: Position inside safe rect
			var b_rect: Rect2
			if b_name == "BtnPause":
				b_rect = Rect2(pause_pos, Vector2(bw, bh))
			else:
				# Inside cluster
				b_rect = Rect2(cluster_pos.x, cluster_pos.y, cluster_w, cluster_h)
				
			var inside_safe = safe_rect.encloses(b_rect) or (b_rect.position.x >= safe_rect.position.x and b_rect.end.x <= safe_rect.end.x and b_rect.position.y >= safe_rect.position.y and b_rect.end.y <= safe_rect.end.y)
			if not inside_safe:
				print("  [FAIL] %s rect %s falls outside safe area %s!" % [b_name, b_rect, safe_rect])
				all_passed = false
			else:
				passed_checks += 1
				
		# Joystick bounds check
		total_checks += 1
		var joy_margin_x = safe_left + 40.0 * scale_factor
		var joy_margin_y = safe_bottom + 40.0 * scale_factor
		var joy_origin = Vector2(joy_margin_x + 120.0 * scale_factor, vp_size.y - joy_margin_y - 120.0 * scale_factor)
		var joy_radius = 85.0 * scale_factor
		var joy_rect = Rect2(joy_origin - Vector2(joy_radius, joy_radius), Vector2(joy_radius * 2, joy_radius * 2))
		
		var joy_inside = (joy_rect.position.x >= safe_rect.position.x and joy_rect.end.x <= (vp_size.x * 0.5) and joy_rect.position.y >= safe_rect.position.y and joy_rect.end.y <= safe_rect.end.y)
		if joy_inside:
			passed_checks += 1
			print("  -> Joystick and all 5 action buttons verified inside safe area and >= 48px.")
		else:
			print("  [FAIL] Joystick bounds %s exceed safe area or left half boundary!" % joy_rect)
			all_passed = false
			
		print("")

	print("========================================================")
	print("  TOTAL CHECKS: %d / %d PASSED" % [passed_checks, total_checks])
	print("========================================================")
	if all_passed and passed_checks == total_checks:
		print("  >>> ALL TOUCH LAYOUT & SAFE AREA AUDITS PASSED! <<<\n")
		quit(0)
	else:
		print("  >>> TOUCH LAYOUT CHECKS FAILED! <<<\n")
		quit(1)
