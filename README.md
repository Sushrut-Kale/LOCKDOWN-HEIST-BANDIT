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

## 📱 Android & Mobile Features (Prompt #3 Ship Pass)

- **Native Thumb Touch Scheme (`MobileTouchControls`):**
  - **Dynamic Left Virtual Joystick:** Thumb-down spawns the joystick base under the finger clamped within safe area. Inner ring sneaks (0 px noise ring), mid walks, outer ring or dedicated sprint button runs.
  - **Adaptive Right Context Button:** Automatically swaps icon and text depending on nearby entities: **Knockout** (Tap), **Pickpocket** (Hold 0.6s with visual radial fill), **Zip-Tie Cuff**, **Hide in Locker**, or **Vent Crawl**.
  - **Coin Toss & Gadget:** Quick-throw distraction coins and activate smoke pellets/marbles directly from the right thumb cluster.
  - **Opposite-Hand Support:** Invert layout in Settings (Joystick Right, Buttons Left).
- **Display Cutout / Notch Safe Area:**
  - Full safe-area boundary inset via `DisplayServer.get_display_safe_area()`.
  - Built-in notch simulation toggle in Settings (**None**, **Left Notch**, **Right Notch**, **Cutout**) for desk testing.
- **Robust Android Lifecycle & Audio Focus:**
  - Game automatically pauses tree and preserves mid-run state when losing focus (Home button, app switcher, incoming phone calls).
  - Audio stems cleanly mute/duck without losing sync upon resume.
  - Hardware **Back** button closes modals, opens pause menu in-game, and prompts "Quit Heist?" confirm dialog on Main Menu.
  - Keeps screen awake (`DisplayServer.screen_set_keep_on`) during levels; allows sleep on menus.
- **Battery Saver & Thermal Budgeting:**
  - Settings -> Quality: **High** (60 FPS, all dynamic shadows), **Medium** (caps shadow-casting lights to nearest 6 guards), **Low** (caps shadows to nearest 3 guards, reduces particles, saves battery).
  - Visual FPS counter hidden by default on mobile.
- **Zero Dangerous Permissions:**
  - No `INTERNET`, `STORAGE`, `LOCATION`, `CAMERA`, `MIC`, or `AD_ID`.
  - Only standard `android.permission.VIBRATE` for tactile pulses (respects Settings toggle).

---

## 🕹️ Controls

| Action | Keyboard / Mouse | Xbox / Gamepad | PlayStation | Mobile Touch |
|---|---|---|---|---|
| **Move** | `W / A / S / D` or Arrow Keys | Left Analog Stick | Left Analog Stick | Dynamic Left Virtual Joystick |
| **Sprint** | `Shift` (Hold) | Right Trigger `RT` | Right Trigger `R2` | Joystick Outer Drag / Sprint Button |
| **Interact / Bonk / Pickpocket** | `E` (Tap bonk / Hold pickpocket) | `X` Button | `Square` Button | Context Action Button (Adaptive) |
| **Coin Toss (Distraction)** | `Q` | `Y` Button | `Triangle` Button | Coin Toss Touch Button |
| **Use Gadget** | `F` | `B` Button | `Circle` Button | Gadget Touch Button |
| **Pause / Resume** | `Escape` | `Start` / Menu | `Options` | Pause Icon Top-Right |

*The game features real-time input device auto-detection, dynamically swapping button prompts on screen between Keyboard, Xbox, PlayStation, and Touch layouts.*

---

## 🛠️ Architecture & System Design

```
res://
├── assets/
│   ├── audio/               # SFX & Dual-stem music (explore vs lockdown)
│   ├── store/
│   │   ├── android/         # Adaptive launcher foreground/background, icons, splash card
│   │   └── play/            # 1024x500 Feature graphic, screenshots, Play listing kit
│   ├── tiles/               # Living Blueprint tileset and occluders
│   └── ui/                  # Touch icons, HUD icons, portraits
├── scenes/
│   ├── guards/              # GuardBase.tscn (Vision cones, PointLight2D shadows, raycast LOS)
│   ├── objects/             # MarblesHazard, SmokeCloud, FuseBox, TreasureGem, Coin, Key, Shutter
│   ├── player/              # BanditPlayer.tscn (Physics, state machine, stamina, bag tiers)
│   ├── ui/                  # MainMenu, LoadingScreen, PauseMenu, MobileTouchControls, Modals
│   └── world/               # ProceduralLevel.tscn (TileMapLayer, CanvasModulate, Y-sort, HUD)
├── scripts/
│   ├── autoload/            # Events (Event Bus), GameManager, AudioManager, SaveManager
│   ├── generation/          # level_generator.gd & level_validator.gd (Dual-Graph A*/BFS validation)
│   ├── guards/              # guard_base.gd (Patrol, Search, Chase, Radio, K9 scent aura)
│   ├── player/              # bandit_player.gd (Movement, bonk, pickpocket, gadgets)
│   └── systems/             # game_config.gd, juice_manager.gd, lockdown_manager.gd
├── tests/                   # verify_project.gd, playtest_harness.tscn, android_readiness.gd, touch_layout_probe.gd
└── tools/
    ├── android/             # export_android.ps1, make_keystore.ps1
    ├── android_perf_probe.gd # 8-second Floor 12 and 25 performance monitor logger
    └── balance_sim.gd       # 300-floor difficulty balance simulator
```

---

## 🧪 Automated Testing & Verification Suite

All tests run fully automated headlessly or windowed.

### 1. Verification Suite (Scenes, Audio & 100 Seeds)
```bash
godot --headless -s tests/verify_project.gd
```

### 2. Runtime Playtest Harness (20/20 Test Cases)
Simulates bot physics navigation across Floors 1–25, audits UI buttons, verifies stealth fairness rules, and checks node memory stability:
```bash
godot --headless tests/playtest_harness.tscn
```

### 3. Android Readiness Audit
Verifies export presets, zero dangerous permissions, icon/splash presence, MobileTouchControls scene, quality settings, lifecycle handlers, and security rules:
```bash
godot --headless -s tests/android_readiness.gd
```

### 4. Touch Layout & Safe Area Probe
Validates all touch button targets (>= 48px) and bounds across 1920×1080, 2400×1080, and 1280×720 viewports:
```bash
godot --headless -s tests/touch_layout_probe.gd
```

### 5. Android Performance Logger
Measures FPS, draw calls, 2D object count, and static memory on Floors 12 and 25:
```bash
godot --headless -s tools/android_perf_probe.gd
```

---

## 📦 Android Export & Deployment Guide

For complete instructions on building the Android APK or Google Play AAB, see [`docs/ANDROID_BUILD.md`](docs/ANDROID_BUILD.md).

### Quick Commands:

1. **Generate Local Cryptographic Release Keystore:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File tools/android/make_keystore.ps1
   ```

2. **Export APK and Google Play AAB:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File tools/android/export_android.ps1 -Target all
   ```

3. **Install on Phone via ADB:**
   ```powershell
   adb install -r build/android/LockdownHeistBandit-0.3.0.apk
   adb shell monkey -p com.sushrutkale.lockdownheist 1
   ```

See [`docs/PRIVACY.md`](docs/PRIVACY.md) and [`assets/store/play/LISTING.md`](assets/store/play/LISTING.md) for Google Play Store packaging assets and data safety documentation.
