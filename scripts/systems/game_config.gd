# scripts/systems/game_config.gd
class_name GameConfig
extends RefCounted

# --- SINGLE SOURCE OF TRUTH FOR ALL TUNABLES ---

# Player Movement Speeds (px/s)
const SPEED_SNEAK: float = 110.0
const SPEED_WALK: float = 180.0
const SPEED_SPRINT: float = 255.0
const PLAYER_ACCEL: float = 1400.0
const PLAYER_FRICTION: float = 1600.0

# Player Sound Radii (px)
const NOISE_RADIUS_SNEAK: float = 0.0
const NOISE_RADIUS_WALK: float = 34.0
const NOISE_RADIUS_SPRINT: float = 110.0
const NOISE_RADIUS_COIN_TOSS: float = 160.0
const NOISE_RADIUS_CREAKY: float = 140.0
const NOISE_RADIUS_GLASS: float = 180.0

# Greed Bag Slowdown
const BAG_TIER_LIGHT_MAX: int = 14
const BAG_TIER_MED_MAX: int = 34
const SPEED_MULT_LIGHT: float = 1.00
const SPEED_MULT_MEDIUM: float = 0.94
const SPEED_MULT_HEAVY: float = 0.88

# Vision & Detection
const VISION_CONE_ANGLE_DEG: float = 56.0
const VISION_CONE_HALF_ANGLE_RAD: float = deg_to_rad(28.0)
const VISION_RADIUS_ROOKIE: float = 230.0
const VISION_RADIUS_VETERAN: float = 260.0
const VISION_RADIUS_RADIO: float = 220.0
const VISION_RADIUS_K9: float = 190.0
const VISION_RADIUS_HEAVY: float = 210.0
const VISION_RADIUS_DRONE: float = 250.0

# Suspicion Fill Rates (seconds to fill meter from 0 to 1)
const SUSPICION_TIME_POINT_BLANK: float = 0.12
const SUSPICION_TIME_EDGE: float = 0.40
const SUSPICION_DECAY_RATE: float = 1.20

# Guard Speeds
const GUARD_SPEED_PATROL_BASE: float = 75.0
const GUARD_SPEED_CHASE_BASE: float = 170.0
const LOCKDOWN_GUARD_SPEED_MULT: float = 1.30

# Stealth & Takedown
const BACK_STAB_DOT_THRESHOLD: float = -0.35 # Dot product < -0.35 means behind guard
const INTERACTION_MAX_DIST: float = 52.0
const KNOCKOUT_DURATION_SEC: float = 35.0
const PICKPOCKET_HOLD_TIME: float = 0.60
const KNOCKOUT_COINS_AWARD: int = 3
const PICKPOCKET_COINS_AWARD: int = 6

# Lockdown Timings
const CASING_PREVIEW_DURATION: float = 3.5
const TRANSPONDER_PING_INTERVAL_BASE: float = 8.0
const TRANSPONDER_PING_INTERVAL_FARADAY: float = 13.0
const LOCKDOWN_HITSTOP_SEC: float = 0.15
const KNOCKOUT_HITSTOP_SEC: float = 0.12
const CAPTURE_HITSTOP_SEC: float = 0.25

# Gadgets
const SMOKE_CLOUD_DURATION: float = 3.5
const MARBLES_STUN_DURATION: float = 4.0
const K9_SCENT_RADIUS: float = 95.0

# Difficulty Scaling formulas
static func get_maze_dimension(floor_num: int) -> int:
	var w = clampi(15 + 2 * (floor_num - 1), 15, 45)
	if w % 2 == 0:
		w += 1
	return w

static func get_guard_count(floor_num: int) -> int:
	return clampi(2 + int(floor(0.12 * pow(floor_num - 1, 1.5))), 2, 26)

static func get_par_time(floor_num: int) -> float:
	return 45.0 + float(floor_num) * 5.0
