# Google Play Store Listing Kit — Lockdown Heist: Bandit

---

## 1. App Details & Metadata

- **Application Title:** Lockdown Heist: Bandit
- **Package Name:** `com.sushrutkale.lockdownheist`
- **Default Language:** English (United States) (en-US)
- **App Category:** Games / Arcade (Sub-category: Action / Stealth)
- **Content Rating:** Everyone (ESRB E / PEGI 3 / IARC 3+)
  - Cartoon violence: Non-lethal stealth bonks with humorous stars/Zzz
  - Blood / Gore: None
  - In-game purchases: None
  - User interaction / Social: None
  - Ads: None

---

## 2. Store Descriptions

### Short Description (Max 80 chars)
> Outsmart patrols, steal the Master Key, and escape the crimson lockdown!

*(Character count: 75 / 80)*

### Full Description
```text
Slip into the velvet paws of Bandit, the master raccoon thief, in a stylish top-down tactical heist thriller built with Living Blueprint aesthetics!

TWO HIGH-STAKES HEIST PHASES:
1. Infiltration: Study sweeping flashlight cones, monitor guard patrol routes, and silently pocket golden loot while tracking the glowing Master Key.
2. Crimson Lockdown: Grabbing the key triggers facility alarms! Security shutters slam shut, green emergency vents open, patrols accelerate, and the Key Transponder broadcasts your position every 8 seconds. Can you reach the Vault Door in time?

PURE NON-LETHAL STEALTH:
★ Silent Sneaking: Tread lightly to stay silent, or sprint when you need speed—at the cost of loud acoustic noise rings!
★ Rear Bonk & Zip-Tie: Sneak behind unaware guards for a cartoon knockout, then zip-tie them before they wake up.
★ Master Pickpocket: Hold from the shadows to pickpocket extra gold right under their noses.
★ Tactical Distractions: Clink a coin across the floor to lure guards away from your escape path.
★ Gadget Loadouts: Deploy thick smoke screens, roll slippery marble traps, or equip noise-dampening Velvet Paws.

THE GREED BAG DILEMMA:
The more gold you hoard, the heavier your loot bag becomes, slowing your escape speed. Bank your coins only by escaping alive!

DESIGNED FOR THUMBS & PHONES:
• Dynamic Virtual Joystick: Intuitive thumb tracking with inner sneak, mid walk, and outer sprint zones.
• Smart Context Button: Dynamically morphs between Knockout, Cuff, Hide, Vent, and Pickpocket.
• Safe Area & Notch Support: Clean responsive layouts tailored for 16:9, 19.5:9, and 20:9 edge-to-edge displays.
• Pause on Interrupt: Incoming phone calls or app switching instantly freeze the game safely.
• 100% Offline & Private: Zero ads, zero trackers, and zero unnecessary permissions. Just pure stealth fun!
```

---

## 3. What's New (Version 0.3.0 / versionCode 3)

```text
- Full Android Ship Pass release!
- Native multi-touch controls with dynamic virtual joystick and adaptive context actions.
- Safe area notch integration for all widescreen phones and tablets.
- Automatic pause and audio ducking on incoming notifications, home button, and screen sleep.
- Battery saver quality tiers (High / Medium / Low) with dynamic 2D shadow budgeting.
- Procedural seeds, Daily Heist challenges, and Hideout loadout customization.
```

---

## 4. Google Play Data Safety Form Answers

| Section | Question | Answer |
|---|---|---|
| **Data Collection** | Does your app collect or share any user data? | **No**, the app collects and shares 0 user data. |
| **Data Transfer** | Is data encrypted in transit? | **N/A** (No network transfer occurs; no internet permission). |
| **Data Deletion** | Do you provide a way for users to request data deletion? | **Yes** (Deleting the app clears local `user://` storage). |
| **Target Audience** | Does your app target children under 13? | **Yes / Families Allowed** (Design compliant with COPPA / Families Policy). |
| **Permissions** | Dangerous permissions requested | **None** (Only standard `VIBRATE` for tactile pulses). |

---

## 5. Store Graphics Checklist

All assets are located in `assets/store/play/` and `assets/store/android/`:

- [x] **High-Res App Icon:** `assets/store/play/store_icon_512.png` (512×512 PNG, 32-bit)
- [x] **Feature Graphic:** `assets/store/play/feature_graphic_1024x500.png` (1024×500 PNG)
- [x] **Phone Screenshots (16:9 / Landscape 1920×1080):**
  - `screenshot_01_main_menu.png` (Main Menu & Loadout)
  - `screenshot_02_infiltration_flashlights.png` (Stealth vision cones & patrol evasion)
  - `screenshot_03_crimson_lockdown.png` (Crimson alarm sirens & radar transponder)
  - `screenshot_04_vault_victory.png` (Vault escape newspaper score summary)
- [x] **Tablet Screenshot:** `screenshot_tablet_2560x1600.png` (2560×1600)
- [x] **Adaptive Launcher Icon:**
  - Foreground: `assets/store/android/ic_launcher_foreground.png` (1024×1024)
  - Background: `assets/store/android/ic_launcher_background.png` (1024×1024)
- [x] **Status Bar Notification Icon:** `assets/store/android/notification_icon_96.png` (White silhouette on transparent)
