# scripts/autoload/audio_manager.gd
extends Node

var stem_explore: AudioStreamPlayer
var stem_lockdown: AudioStreamPlayer
var music_menu: AudioStreamPlayer

var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_players: int = 12

var sfx_streams: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_players()
	_load_sfx()
	_connect_events()

func _setup_audio_players() -> void:
	stem_explore = AudioStreamPlayer.new()
	stem_explore.bus = "Music"
	add_child(stem_explore)
	
	stem_lockdown = AudioStreamPlayer.new()
	stem_lockdown.bus = "Music"
	stem_lockdown.volume_db = -80.0
	add_child(stem_lockdown)
	
	music_menu = AudioStreamPlayer.new()
	music_menu.bus = "Music"
	add_child(music_menu)
	
	for i in range(max_sfx_players):
		var p = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		sfx_players.append(p)
		
	# Load music streams
	var exp_res = load("res://assets/audio/music_stem_explore.wav")
	var lck_res = load("res://assets/audio/music_stem_lockdown.wav")
	var mnu_res = load("res://assets/audio/music_menu_noir.wav")
	
	if exp_res:
		stem_explore.stream = exp_res
	if lck_res:
		stem_lockdown.stream = lck_res
	if mnu_res:
		music_menu.stream = mnu_res

func _load_sfx() -> void:
	var sfx_names = [
		"coin_pickup", "coin_toss_clink", "loot_bag_jingle", "footstep_soft",
		"footstep_creak", "knockout_bonk", "ziptie_ratchet", "pickpocket_zip",
		"guard_snore", "suspicion_hm", "spotted_sting", "lockdown_siren",
		"shutter_slam", "vent_open", "transponder_ping", "heartbeat_pulse",
		"player_caughtwhistle", "level_escape_fanfare", "ui_click", "ui_hover", "star_stamp"
	]
	for s_name in sfx_names:
		var path = "res://assets/audio/sfx/" + s_name + ".wav"
		if ResourceLoader.exists(path):
			sfx_streams[s_name] = load(path)

func _connect_events() -> void:
	Events.lockdown_initiated.connect(_on_lockdown_initiated)
	Events.coin_collected.connect(func(_amt, _tot): play_sfx("coin_pickup", 0.05))
	Events.key_collected.connect(func(): play_sfx("transponder_ping"))
	Events.level_escaped.connect(func():
		stop_gameplay_music()
		play_sfx("level_escape_fanfare")
	)
	Events.player_caught.connect(func(_culprit):
		stop_gameplay_music()
		play_sfx("player_caughtwhistle")
	)
	Events.guard_knocked_out.connect(func(_g): play_sfx("knockout_bonk"))
	Events.guard_cuffed.connect(func(_g): play_sfx("ziptie_ratchet"))
	Events.guard_pickpocketed.connect(func(_g, _c): play_sfx("pickpocket_zip"))
	Events.sound_emitted.connect(func(_pos, _rad, is_dist):
		if is_dist:
			play_sfx("coin_toss_clink")
	)
	Events.key_transponder_ping.connect(func(_pos): play_sfx("transponder_ping", 0.0))

func play_sfx(name: String, pitch_rand: float = 0.08) -> void:
	if not sfx_streams.has(name):
		return
	var stream = sfx_streams[name]
	for p in sfx_players:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = 1.0 + randf_range(-pitch_rand, pitch_rand) if pitch_rand > 0.0 else 1.0
			p.play()
			return
	# Steal first player if all busy
	var fallback = sfx_players[0]
	fallback.stream = stream
	fallback.pitch_scale = 1.0 + randf_range(-pitch_rand, pitch_rand) if pitch_rand > 0.0 else 1.0
	fallback.play()

func play_menu_music() -> void:
	stop_gameplay_music()
	if not music_menu.playing:
		music_menu.play()

func start_gameplay_stems() -> void:
	if music_menu.playing:
		music_menu.stop()
	
	stem_explore.volume_db = 0.0
	stem_lockdown.volume_db = -80.0
	
	# Start precisely together
	stem_explore.play(0.0)
	stem_lockdown.play(0.0)

func _on_lockdown_initiated() -> void:
	play_sfx("lockdown_siren")
	play_sfx("shutter_slam")
	# Crossfade stems
	var tw = create_tween().set_parallel(true)
	tw.tween_property(stem_lockdown, "volume_db", 0.0, 0.4)
	tw.tween_property(stem_explore, "volume_db", -3.0, 0.4)

func stop_gameplay_music() -> void:
	stem_explore.stop()
	stem_lockdown.stop()

func _process(_delta: float) -> void:
	# Synchronize loop positions if active
	if stem_explore.playing and stem_lockdown.playing:
		var diff = abs(stem_explore.get_playback_position() - stem_lockdown.get_playback_position())
		if diff > 0.04:
			stem_lockdown.seek(stem_explore.get_playback_position())
		# Loop handling
		if stem_explore.get_playback_position() >= stem_explore.stream.get_length() - 0.08:
			stem_explore.seek(0.0)
			stem_lockdown.seek(0.0)
