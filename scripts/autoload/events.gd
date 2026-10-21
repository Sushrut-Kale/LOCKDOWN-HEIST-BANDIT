# scripts/autoload/events.gd
extends Node

# --- Signal Bus for Lockdown Heist: Bandit ---

# Loot & Objectives
signal coin_collected(amount: int, total_level_coins: int)
signal key_collected()
signal lockdown_initiated()
signal level_escaped()

# Guard Events
signal guard_state_changed(guard: Node2D, old_state: String, new_state: String)
signal guard_suspicion_changed(guard: Node2D, ratio: float)
signal guard_knocked_out(guard: Node2D)
signal guard_cuffed(guard: Node2D)
signal guard_pickpocketed(guard: Node2D, coins_stolen: int)
signal guard_alert_whistle(guard: Node2D, pos: Vector2)

# Player & Stealth
signal sound_emitted(pos: Vector2, radius: float, is_distraction: bool)
signal player_hidden_state_changed(is_hidden: bool)
signal player_caught(culprit: String)
signal coin_tossed(target_pos: Vector2)
signal gadget_used(gadget_name: String, pos: Vector2)

# World & FX
signal camera_shake_requested(intensity: float, duration: float)
signal key_transponder_ping(pos: Vector2)
signal casing_phase_ended()
signal chalk_hint_triggered(text: String, pos: Vector2)
