# scripts/ui/loading_screen.gd
extends Control

@onready var lbl_floor: Label = $CenterContainer/VBoxContainer/FloorLabel
@onready var lbl_specs: Label = $CenterContainer/VBoxContainer/SpecsLabel
@onready var lbl_tip: Label = $CenterContainer/VBoxContainer/TipLabel
@onready var progress_bar: ProgressBar = $CenterContainer/VBoxContainer/ProgressBar

var tips: Array[String] = [
	"Tip: Guards wake up after 35 seconds—save your Zip-Tie for Radio Officers!",
	"Tip: Sneaking emits ZERO noise ripples, even on creaky floorboards.",
	"Tip: Vents are sealed until Lockdown—then they become your fastest shortcuts!",
	"Tip: Toss a single coin [Q] to lure a guard away from an exit chokepoint.",
	"Tip: Heavy Riot Guards resist bare punches! Use Pickpocket or Marbles instead.",
	"Tip: Unbanked coins are lost if caught! Escape to lock your fortune into the Vault.",
	"Tip: During Lockdown, the Key Transponder pings your location every 8 seconds!"
]

var fake_progress: float = 0.0

func _ready() -> void:
	var fl = GameManager.current_floor
	var sd = GameManager.current_seed
	var w = GameManager.get_grid_width(fl)
	
	lbl_floor.text = "UNROLLING BLUEPRINT — FLOOR %02d" % fl
	lbl_specs.text = "GRID: %d×%d | SEED: #%d | PATROLS: %d" % [w, w, sd, GameManager.get_guard_count(fl)]
	lbl_tip.text = tips[randi() % tips.size()]
	progress_bar.value = 0

func _process(delta: float) -> void:
	fake_progress += delta * 180.0
	progress_bar.value = fake_progress
	if fake_progress >= 100.0:
		get_tree().change_scene_to_file("res://scenes/world/ProceduralLevel.tscn")
