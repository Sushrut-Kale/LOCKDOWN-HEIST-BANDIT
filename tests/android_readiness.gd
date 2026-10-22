# tests/android_readiness.gd
extends SceneTree

func _init() -> void:
	print("\n========================================================")
	print("  LOCKDOWN HEIST: BANDIT — ANDROID READINESS AUDIT      ")
	print("========================================================\n")
	
	var passed = 0
	var total = 0
	
	# 1. Check export_presets.cfg
	total += 1
	var preset_file = FileAccess.open("res://export_presets.cfg", FileAccess.READ)
	if preset_file:
		var content = preset_file.get_as_text()
		preset_file.close()
		
		var has_pkg = content.find("com.sushrutkale.lockdownheist") != -1
		var has_vcode = content.find("version/code=3") != -1
		var has_no_internet = content.find("permissions/internet=false") != -1
		var has_no_loc = content.find("permissions/access_fine_location=false") != -1
		var has_no_cam = content.find("permissions/camera=false") != -1
		var has_no_mic = content.find("permissions/record_audio=false") != -1
		
		if has_pkg and has_vcode and has_no_internet and has_no_loc and has_no_cam and has_no_mic:
			print("[PASS] PRESETS: Package 'com.sushrutkale.lockdownheist', versionCode 3, 0 dangerous permissions.")
			passed += 1
		else:
			print("[FAIL] PRESETS: Configuration missing package name or permission flags.")
	else:
		print("[FAIL] PRESETS: export_presets.cfg not found.")

	# 2. Check icon and splash assets
	total += 1
	var required_assets = [
		"res://assets/store/android/ic_launcher_background.png",
		"res://assets/store/android/ic_launcher_foreground.png",
		"res://assets/store/android/icon_512.png",
		"res://assets/store/android/icon_1024.png",
		"res://assets/store/android/icon_round_512.png",
		"res://assets/store/android/notification_icon_96.png",
		"res://assets/store/android/splash_card.png",
		"res://assets/store/play/feature_graphic_1024x500.png"
	]
	var all_assets_exist = true
	for path in required_assets:
		if not FileAccess.file_exists(path) and not ResourceLoader.exists(path):
			all_assets_exist = false
			print("  Missing asset: %s" % path)
			
	if all_assets_exist:
		print("[PASS] ASSETS: All %d Android launcher, notification, splash, and store assets exist." % required_assets.size())
		passed += 1
	else:
		print("[FAIL] ASSETS: One or more Android store assets are missing.")

	# 3. Check MobileTouchControls scene file
	total += 1
	if FileAccess.file_exists("res://scenes/ui/MobileTouchControls.tscn"):
		var f = FileAccess.open("res://scenes/ui/MobileTouchControls.tscn", FileAccess.READ)
		var tscn_text = f.get_as_text() if f else ""
		if f: f.close()
		if tscn_text.find("JoystickBase") != -1 and tscn_text.find("ActionCluster") != -1 and tscn_text.find("BtnContext") != -1:
			print("[PASS] TOUCH_HUD: MobileTouchControls.tscn verified with JoystickBase, ActionCluster, and BtnContext.")
			passed += 1
		else:
			print("[FAIL] TOUCH_HUD: MobileTouchControls.tscn missing expected control nodes.")
	else:
		print("[FAIL] TOUCH_HUD: MobileTouchControls.tscn does not exist.")

	# 4. Check Quality settings enum on SaveManager
	total += 1
	var save_file = FileAccess.open("res://scripts/autoload/save_manager.gd", FileAccess.READ)
	if save_file:
		var code = save_file.get_as_text()
		save_file.close()
		if code.find("enum QualityTier") != -1 and code.find("quality_tier") != -1:
			print("[PASS] QUALITY_TIERS: SaveManager.QualityTier enum exists.")
			passed += 1
		else:
			print("[FAIL] QUALITY_TIERS: QualityTier constant/enum missing in save_manager.gd.")
	else:
		print("[FAIL] QUALITY_TIERS: Could not read save_manager.gd.")

	# 5. Check Pause-on-unfocus and back button handlers on GameManager
	total += 1
	var gm_file = FileAccess.open("res://scripts/autoload/game_manager.gd", FileAccess.READ)
	if gm_file:
		var code = gm_file.get_as_text()
		gm_file.close()
		var has_notification = code.find("func _notification") != -1
		var has_pause_out = code.find("NOTIFICATION_APPLICATION_PAUSED") != -1
		var has_back = code.find("handle_back_request") != -1
		if has_notification and has_pause_out and has_back:
			print("[PASS] LIFECYCLE: GameManager implements _notification, NOTIFICATION_APPLICATION_PAUSED, and handle_back_request.")
			passed += 1
		else:
			print("[FAIL] LIFECYCLE: GameManager missing lifecycle handlers.")
	else:
		print("[FAIL] LIFECYCLE: Could not read game_manager.gd.")

	# 6. Check Keystores and keystore.properties are gitignored
	total += 1
	var gitignore_file = FileAccess.open("res://.gitignore", FileAccess.READ)
	if gitignore_file:
		var gi_content = gitignore_file.get_as_text()
		gitignore_file.close()
		if gi_content.find("*.keystore") != -1 and gi_content.find("keystore.properties") != -1:
			print("[PASS] SECURITY: Keystores and keystore.properties are explicitly gitignored.")
			passed += 1
		else:
			print("[FAIL] SECURITY: .gitignore missing keystore exclusion patterns.")
	else:
		print("[FAIL] SECURITY: .gitignore file not found.")

	print("\n========================================================")
	print("  TOTAL PASSED: %d / %d" % [passed, total])
	print("========================================================")
	if passed == total:
		print("  >>> ALL ANDROID READINESS GATES PASSED! <<<\n")
		quit(0)
	else:
		print("  >>> SOME ANDROID READINESS GATES FAILED! <<<\n")
		quit(1)
