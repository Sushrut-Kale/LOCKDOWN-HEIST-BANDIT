# tools/android_perf_probe.gd
extends SceneTree

func _init() -> void:
	var godot_exe = OS.get_executable_path()
	var output: Array = []
	var exit_code = OS.execute(godot_exe, ["--headless", "res://tools/android_perf_probe_runner.tscn"], output, true)
	for line in output:
		print(line)
	quit(exit_code)
