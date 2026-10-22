# Android Build & Deployment Guide

This document describes how to set up the build environment, generate cryptographic release keystores, export installable Android APKs and Google Play AABs, and test on physical devices.

---

## 1. Prerequisites (Windows)

To build APK/AAB packages for **Lockdown Heist: Bandit** (Godot 4.7.1), the following tools must be installed:

### A. Godot 4.7.1 Console Executable
- Expected path: `S:\godot setup\Godot_v4.7.1-stable_win64_console.exe` (or in PATH)
- Verify in PowerShell:
  ```powershell
  & "S:\godot setup\Godot_v4.7.1-stable_win64_console.exe" --version
  ```

### B. Godot 4.7.1 Export Templates
1. Open Godot 4.7.1.
2. Navigate to **Editor -> Manage Export Templates**.
3. Click **Download and Install** for version `4.7.1.stable`.
4. Templates are saved to: `%APPDATA%\Godot\export_templates\4.7.1.stable\`

### C. Java Development Kit (JDK 17)
Install OpenJDK 17 using Windows Package Manager (`winget`):
```powershell
winget install Microsoft.OpenJDK.17
```
Restart PowerShell and verify:
```powershell
java -version
keytool
```

### D. Android SDK & Build Tools (API 34)
Install Android Studio:
```powershell
winget install Google.AndroidStudio
```
1. Open Android Studio -> **More Actions -> SDK Manager**.
2. Under **SDK Platforms**, install:
   - **Android 14.0 ("UpsideDownCake") / API Level 34**
3. Under **SDK Tools**, install:
   - **Android SDK Build-Tools 34.0.0**
   - **Android SDK Platform-Tools** (includes `adb`)
   - **Android SDK Command-line Tools (latest)**
4. Set environment variables:
   ```powershell
   [System.Environment]::SetEnvironmentVariable('ANDROID_HOME', "$env:LOCALAPPDATA\Android\Sdk", 'User')
   [System.Environment]::SetEnvironmentVariable('Path', $env:Path + ";$env:LOCALAPPDATA\Android\Sdk\platform-tools", 'User')
   ```

---

## 2. Release Keystore Generation

Android packages submitted to Google Play or signed for release must be cryptographically signed.

Run the automated keystore generator:
```powershell
powershell -ExecutionPolicy Bypass -File tools/android/make_keystore.ps1
```

This creates:
- `android/lockdown-heist-release.keystore` (Protected RSA 2048-bit key)
- `android/keystore.properties.example` (Template for secure local passwords)

> **CRITICAL SECURITY NOTE:**
> Never commit `*.keystore` or `keystore.properties` to source control. They are ignored in `.gitignore`.
> Keep an offline backup of your keystore; losing it means you cannot update your Google Play listing.

---

## 3. Automated Export Pipeline

Run the export script to produce both APK and AAB:

```powershell
powershell -ExecutionPolicy Bypass -File tools/android/export_android.ps1 -Target all
```

Outputs:
- **Tester / Sideload APK:** `build/android/LockdownHeistBandit-0.3.0.apk`
- **Google Play AAB:** `build/android/LockdownHeistBandit-0.3.0.aab`

To build only APK:
```powershell
powershell -ExecutionPolicy Bypass -File tools/android/export_android.ps1 -Target apk
```

To build only Google Play AAB:
```powershell
powershell -ExecutionPolicy Bypass -File tools/android/export_android.ps1 -Target aab
```

---

## 4. Sideload & Physical Phone Smoke Testing

Connect your Android phone via USB and enable **Developer options -> USB debugging**.

1. Verify device connection:
   ```powershell
   adb devices
   ```

2. Install the APK:
   ```powershell
   adb install -r build/android/LockdownHeistBandit-0.3.0.apk
   ```

3. Launch the game:
   ```powershell
   adb shell monkey -p com.sushrutkale.lockdownheist 1
   ```

### 10-Minute Device Checklist
- [ ] **Touch Joystick:** Left thumb spawns dynamic joystick under finger; inner circle sneaks (0 px noise ring), outer sprint.
- [ ] **Context Button:** Swaps automatically to BONK, CUFF, HIDE, VENT, or STEAL (Hold radial).
- [ ] **Simultaneous Multi-Touch:** Joystick + Context + Sprint work with 3 thumbs concurrently.
- [ ] **Safe Area & Notches:** UI elements stay strictly inside display cutout in both landscape directions.
- [ ] **Interrupt / Lifecycle:** Press Home button during chase; resume returns to Pause menu without position skips or audio glitches.
- [ ] **Hardware Back Button:** Closes open modals, pauses active game, prompts confirm on main menu.
- [ ] **Battery & Thermals:** Runs cool at 60 FPS without overheating or thermal throttling.
