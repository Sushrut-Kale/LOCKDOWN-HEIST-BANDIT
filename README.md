# LOCKDOWN HEIST: BANDIT

> **"Stealth in. Grab the Key. Survive the Lockdown."**  
> A top-down stealth-action heist roguelite built in **Godot 4.7.1**. Play as **Bandit the Raccoon**, infiltrating high-security procedural museum vaults, snatching loot, outsmarting dynamic police patrols, and escaping through closing blast shutters before the transponder siren gives away your position!

---

## 🎮 Game Overview & Mechanics

### The Core Loop: Two-Phase Heists
Every floor is divided into two distinct, tension-filled phases:

1. **Infiltration Phase (Casing & Stealth):**
   - **Casing Overview:** The floor begins with an aerial camera zoom over the blueprint maze, allowing you to plan your route.
   - **Stealth Infiltration:** Guard vision cones cut through the gloom. Guards patrol predictable waypoints and investigate noise.
   - **Sneak & Bonk:** Approach guards from behind (rear 180° arc) to perform a silent knockout (+3 coins, 35s zzz nap) or hold interact to pickpocket (+6 coins without alerting). Front attacks are rejected!
   - **Greed Mechanic:** Every coin collected adds weight to your Loot Bag. Heavy bags (35+ coins) reduce your sprint speed by up to 12%.

2. **Lockdown Phase (Survival & Escape):**
   - **The Heist Alarm:** Grabbing the Master Key triggers instant Lockdown!
   - **Blast Shutters & Vents:** Heavy security blast shutters slam shut across main corridors, while secret escape vents open up.
   - **Transponder Radar:** The Master Key's emergency transponder emits a periodic broadcast ping (every 8.0s, or 13.0s with Faraday Pouch). It broadcasts a *snapshot* of your location to all guards, who immediately converge on that coordinate.
   - **Siren & Pursuit:** Guard patrol speeds increase by 1.30×. Reach the designated Vault Exit Door to bank your loot and advance!

---

## 🕹️ Controls

| Action | Keyboard / Mouse | Xbox / Gamepad | PlayStation | Mobile Touch |
|---|---|---|---|---|
| **Move** | `W / A / S / D` or Arrow Keys | Left Analog Stick | Left Analog Stick | Dynamic Left Virtual Joystick |
| **Sprint** | `Shift` (Hold) | Right Trigger `RT` | Right Trigger `R2` | Joystick Outer Drag / Sprint Button |
| **Interact / Bonk / Pickpocket** | `E` (Tap bonk / Hold pickpocket) | `X` Button | `Square` Button | Context Action Button |
| **Coin Toss (Distraction)** | `Q` | `Y` Button | `Triangle` Button | Coin Toss Touch Button |
| **Use Gadget** | `F` | `B` Button | `Circle` Button | Gadget Touch Button |
| **Pause / Resume** | `Escape` | `Start` / Menu | `Options` | Pause Icon Top-Right |

*The game features real-time input device auto-detection, dynamically swapping button prompts on screen between Keyboard, Xbox, PlayStation, and Touch layouts.*

---

## 🛠️ Architecture & System Design

```
res://
├── assets/                  # Audio (SFX & Dual-stem music), Living Blueprint tiles, UI portraits
├── scenes/
│   ├── guards/              # GuardBase.tscn (Vision cones, PointLight2D shadows, raycast LOS)
│   ├── objects/             # MarblesHazard, SmokeCloud, FuseBox, TreasureGem, Coin, Key, Shutter
│   ├── player/              # BanditPlayer.tscn (Physics, state machine, stamina, bag tiers)
│   ├── ui/                  # MainMenu, LoadingScreen, PauseMenu, LevelComplete, GameOver, Modals
│   └── world/               # ProceduralLevel.tscn (TileMapLayer, CanvasModulate, Y-sort, HUD)
├── scripts/
│   ├── autoload/            # Events (Event Bus), GameManager, AudioManager, SaveManager
│   ├── generation/          # level_generator.gd & level_validator.gd (Dual-Graph A*/BFS validation)
│   ├── guards/              # guard_base.gd (Patrol, Search, Chase, Radio, K9 scent aura)
│   ├── player/              # bandit_player.gd (Movement, bonk, pickpocket, gadgets)
│   └── systems/             # game_config.gd (Central config single source of truth), juice_manager.gd
├── tests/                   # verify_project.gd & playtest_harness.tscn (Automated test suites)
└── tools/                   # balance_sim.gd (300-floor difficulty balance simulator)
```

### 1. Centralized Single-Source Configuration (`scripts/systems/game_config.gd`)
All gameplay constants are strictly defined in `GameConfig`:
- **Bandit Speeds:** Sneak (110 px/s), Walk (160 px/s), Sprint (240 px/s), Max Stamina (4.0s).
- **Vision Math:** Guard cone angle (70°), range (260 px), investigation grace time (0.45s), alert speed multiplier (1.30×).
- **Noise Radii:** Coin toss (180 px), sprint footstep (120 px), fuse box flip (220 px).
- **Bag Slowdown:** Light (<15 coins, 1.0×), Medium (15–34 coins, 0.94×), Heavy (35+ coins, 0.88×).

### 2. Living Blueprint Aesthetics & Lighting
- **CanvasModulate:** Ambient blue-dark tone (`#12263F`), smoothly transitioning to an intense crimson tint (`#3B101A`) during active alarm lockdowns.
- **Dynamic 2D Lighting:** Smooth flashlight cones using `PointLight2D` with hardware shadow occluders on wall tiles, preventing guards from seeing through walls.
- **Personal Player Ambience:** Bandit carries a subtle point light ensuring high character contrast against dark tile floors.
- **Glassmorphic Blueprint HUD:** Translucent blueprint top-bar displaying real-time loot counters, bag weight icons, zip-ties, equipped gadget charges, and floor stats.

### 3. Commercial Game Feel & "Juice" (`scripts/systems/juice_manager.gd`)
- **Hitstop:** 0.12s on knockouts, 0.15s on key pickup, 0.25s on capture.
- **Camera Shake:** Non-linear trauma-squared falloff, scaled by user settings.
- **Comic Speech Bubbles:** Rate-limited reactions above guards (`?` "Hm?", `!` "There!", "Must be rats...", "Officer down!").
- **Sample-Locked Audio Ducking:** Adaptive music bus ducking under siren alerts and victory fanfares.

---

## 🧪 Automated Testing & Verification Suite

All tests run fully automated headlessly or windowed.

### 1. Headless Structural & Seed Verification
Validates 24 audio files, 17 UI & world scenes, and executes 100 consecutive procedural seeds through dual-graph solvability checks:
```bash
godot --headless -s tests/verify_project.gd
```

### 2. Runtime Playtest Harness (20/20 Test Cases)
Simulates real physics bot navigation across Floors 1, 3, 5, 8, 12, 18, and 25 using `move_and_slide()`, audits all UI menu buttons, verifies stealth fairness rules (LOS wall occlusion, suspicion meters, rear bonk arc, pickpocketing), and checks node memory stability:
```bash
godot --headless tests/playtest_harness.tscn
```

### 3. 300-Floor Balance Simulation
Simulates 300 procedural layouts across Floors 1–30, measuring path lengths, guard densities per 100 walkable tiles, and exporting a CSV:
```bash
godot --headless -s tools/balance_sim.gd
```

---

## 🎨 Asset Swap Guide

The project is structured to make swapping placeholder or procedural assets with Kenney CC0 or custom production assets frictionless:

1. **Character Sprites:**
   - Bandit: Replace `assets/sprites/bandit_raccoon.png` (or frames) with 64×64 top-down sprites.
   - Guards: Replace `assets/sprites/guard_police.png` with archetype variations (Rookie, Veteran, Radio, K9, Heavy).
2. **Tilemap Art:**
   - Wall and Floor tiles: Update `assets/tiles/tileset_blueprint.png` (64×64 grid). The `TileMapLayer` will automatically inherit the new artwork while preserving physics collisions and light occluders.
3. **Audio & Music Stems:**
   - Dual-stem Explore & Lockdown music: Drop new `.wav` / `.ogg` files into `assets/audio/music/` using matching names (`stem_explore.wav`, `stem_lockdown.wav`).
   - Foley & Sound Effects: Replace files under `assets/audio/sfx/` (e.g., `coin_pickup.wav`, `siren_alarm.wav`, `bonk_takedown.wav`).

---

## 🚀 How to Run the Game

1. Download or clone this repository:
   ```bash
   git clone https://github.com/Sushrut-Kale/LOCKDOWN-HEIST-BANDIT.git
   ```
2. Open **Godot Engine 4.3+ (or 4.7.1)**.
3. Click **Import**, navigate to the repository directory, and select `project.godot`.
4. Press **F5** (or click the Play button in the top-right corner) to launch the Main Menu!
