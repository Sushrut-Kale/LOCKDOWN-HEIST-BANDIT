# tests/verify_project.gd
extends SceneTree

const LevelGenerator = preload("res://scripts/generation/level_generator.gd")
const LevelValidator = preload("res://scripts/generation/level_validator.gd")

func _init() -> void:

	print("====================================================")
	print("  LOCKDOWN HEIST: BANDIT — AUTOMATED TEST SUITE    ")
	print("====================================================")
	
	var all_passed = true
	
	# TEST 1: Verify Audio Resources
	print("\n[TEST 1] Verifying Audio & Music Files...")
	var audio_files = [
		"res://assets/audio/music_menu_noir.wav",
		"res://assets/audio/music_stem_explore.wav",
		"res://assets/audio/music_stem_lockdown.wav",
		"res://assets/audio/sfx/coin_pickup.wav",
		"res://assets/audio/sfx/coin_toss_clink.wav",
		"res://assets/audio/sfx/loot_bag_jingle.wav",
		"res://assets/audio/sfx/footstep_soft.wav",
		"res://assets/audio/sfx/footstep_creak.wav",
		"res://assets/audio/sfx/knockout_bonk.wav",
		"res://assets/audio/sfx/ziptie_ratchet.wav",
		"res://assets/audio/sfx/pickpocket_zip.wav",
		"res://assets/audio/sfx/guard_snore.wav",
		"res://assets/audio/sfx/suspicion_hm.wav",
		"res://assets/audio/sfx/spotted_sting.wav",
		"res://assets/audio/sfx/lockdown_siren.wav",
		"res://assets/audio/sfx/shutter_slam.wav",
		"res://assets/audio/sfx/vent_open.wav",
		"res://assets/audio/sfx/transponder_ping.wav",
		"res://assets/audio/sfx/heartbeat_pulse.wav",
		"res://assets/audio/sfx/player_caughtwhistle.wav",
		"res://assets/audio/sfx/level_escape_fanfare.wav",
		"res://assets/audio/sfx/ui_click.wav",
		"res://assets/audio/sfx/ui_hover.wav",
		"res://assets/audio/sfx/star_stamp.wav"
	]
	
	var missing_audio = 0
	for path in audio_files:
		if not ResourceLoader.exists(path):
			printerr("  MISSING AUDIO: ", path)
			missing_audio += 1
	if missing_audio == 0:
		print("  -> PASS: All 24 music & SFX files verified!")
	else:
		all_passed = false
		printerr("  -> FAIL: ", missing_audio, " audio files missing!")

	# TEST 2: Verify Scene Instantiation
	print("\n[TEST 2] Verifying Scene Instantiations...")
	var scenes = [
		"res://scenes/ui/MainMenu.tscn",
		"res://scenes/ui/LoadingScreen.tscn",
		"res://scenes/ui/HowToPlayModal.tscn",
		"res://scenes/ui/HideoutModal.tscn",
		"res://scenes/ui/SettingsModal.tscn",
		"res://scenes/ui/PauseMenu.tscn",
		"res://scenes/ui/LevelComplete.tscn",
		"res://scenes/ui/GameOver.tscn",
		"res://scenes/player/BanditPlayer.tscn",
		"res://scenes/guards/GuardBase.tscn",
		"res://scenes/objects/MasterKey.tscn",
		"res://scenes/objects/CoinPickup.tscn",
		"res://scenes/objects/ShutterDoor.tscn",
		"res://scenes/objects/VentGrate.tscn",
		"res://scenes/objects/ExitVaultDoor.tscn",
		"res://scenes/objects/LockerHideout.tscn",
		"res://scenes/world/ProceduralLevel.tscn"
	]
	
	var failed_scenes = 0
	for s_path in scenes:
		var packed = load(s_path) as PackedScene
		if not packed:
			printerr("  FAILED TO LOAD: ", s_path)
			failed_scenes += 1
			continue
		var inst = packed.instantiate()
		if not inst:
			printerr("  FAILED TO INSTANTIATE: ", s_path)
			failed_scenes += 1
		else:
			inst.free()
			
	if failed_scenes == 0:
		print("  -> PASS: All 17 scenes instantiated with 0 errors!")
	else:
		all_passed = false
		printerr("  -> FAIL: ", failed_scenes, " scenes failed to instantiate!")

	# TEST 3: Stress-Test 100 Consecutive Procedural Seeds (Levels 1 to 30)
	print("\n[TEST 3] Stress-Testing 100 Consecutive Procedural Seeds...")
	var total_tested = 100
	var pass_count = 0
	var total_time_ms = 0.0
	var gen = LevelGenerator.new()
	var val = LevelValidator.new()
	
	for i in range(total_tested):
		var floor_num = (i % 30) + 1
		var seed_val = 100000 + i * 9973
		
		var t0 = Time.get_ticks_usec()
		var level_data = gen.generate(floor_num, seed_val)
		var t_elapsed_ms = (Time.get_ticks_usec() - t0) / 1000.0
		total_time_ms += t_elapsed_ms
		
		# Validate Graph A & Graph B
		var res = val.validate_level_data(
			level_data["width"], level_data["height"], level_data["walls"],
			level_data["entrance"], level_data["exit_door"], level_data["master_key"],
			level_data["shutters"], level_data["vents"]
		)

		
		if res["valid"]:
			pass_count += 1
		else:
			printerr("  SEED FAILED: Floor ", floor_num, " Seed #", seed_val, " Reason: ", res["reason"])
			
	var avg_ms = total_time_ms / float(total_tested)
	print("  -> Result: ", pass_count, "/", total_tested, " seeds passed dual-graph validation!")
	print("  -> Average Generation Time: ", "%.2f" % avg_ms, " ms per level (Target: < 50ms)")
	
	if pass_count == total_tested and avg_ms < 50.0:
		print("  -> PASS: 100/100 procedural seeds passed under budget!")
	else:
		all_passed = false
		printerr("  -> FAIL: Quality gate not met!")

	print("\n====================================================")
	if all_passed:
		print("  >>> ALL QUALITY GATES PASSED SUCCESSFULLY! <<<   ")
		print("====================================================")
		quit(0)
	else:
		printerr("  >>> SOME TESTS FAILED! PLEASE CHECK LOGS. <<<    ")
		print("====================================================")
		quit(1)
