# tools/android/export_android.ps1
# Automates Android APK and AAB headless exports for Lockdown Heist: Bandit.

param(
    [ValidateSet("all", "apk", "aab")]
    [string]$Target = "all"
)

$ErrorActionPreference = "Continue"

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "  LOCKDOWN HEIST: BANDIT -- ANDROID EXPORT PIPELINE                             " -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

# 1. Locate Godot Executable
$GodotCandidates = @(
    "S:\godot setup\Godot_v4.7.1-stable_win64_console.exe",
    "S:\godot setup\Godot_v4.7.1-stable_win64.exe"
)

$GodotExe = $null
foreach ($c in $GodotCandidates) {
    if (Test-Path $c) {
        $GodotExe = $c
        break
    }
}

if (-not $GodotExe) {
    $found = Get-Command godot -ErrorAction SilentlyContinue
    if ($found) { $GodotExe = $found.Source }
}

if (-not $GodotExe) {
    Write-Error "Godot 4.7.1 executable not found!"
    exit 1
}

$GodotVer = (& $GodotExe --version 2>&1).Trim()
Write-Host "[OK] Godot binary: $GodotExe ($GodotVer)"

# 2. Check Export Templates
$TemplatesDir = "$env:APPDATA\Godot\export_templates"
$HasTemplates = $false
if (Test-Path $TemplatesDir) {
    $Matches = Get-ChildItem -Path $TemplatesDir | Where-Object { $_.Name -like "*4.7.1*" }
    if ($Matches) {
        $HasTemplates = $true
        Write-Host "[OK] Export templates found: $($Matches.Name)"
    }
}

# 3. Check JDK / Android SDK
$JavaCmd = Get-Command java -ErrorAction SilentlyContinue
$AdbCmd = Get-Command adb -ErrorAction SilentlyContinue
$AndroidSdk = $env:ANDROID_HOME
if (-not $AndroidSdk) { $AndroidSdk = $env:ANDROID_SDK_ROOT }
if (-not $AndroidSdk -and (Test-Path "$env:LOCALAPPDATA\Android\Sdk")) {
    $AndroidSdk = "$env:LOCALAPPDATA\Android\Sdk"
}

Write-Host "Environment Status:"
if ($JavaCmd) {
    Write-Host "  * Java / JDK    : Installed ($($JavaCmd.Source))"
} else {
    Write-Host "  * Java / JDK    : MISSING"
}

if ($AndroidSdk) {
    Write-Host "  * Android SDK   : Found ($AndroidSdk)"
} else {
    Write-Host "  * Android SDK   : MISSING"
}

if ($AdbCmd) {
    Write-Host "  * ADB           : Installed ($($AdbCmd.Source))"
} else {
    Write-Host "  * ADB           : MISSING"
}

if ($HasTemplates) {
    Write-Host "  * Templates     : Installed"
} else {
    Write-Host "  * Templates     : MISSING"
}

# 4. Prepare Output Directory
$BuildDir = Join-Path $PSScriptRoot "..\..\build\android"
if (-not (Test-Path $BuildDir)) {
    New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null
}

$ApkOut = Join-Path $BuildDir "LockdownHeistBandit-0.3.0.apk"
$AabOut = Join-Path $BuildDir "LockdownHeistBandit-0.3.0.aab"

# 5. Check if Export is Blocked
$Missing = @()
if (-not $HasTemplates) { $Missing += "Godot 4.7.1 Export Templates" }
if (-not $JavaCmd) { $Missing += "Java JDK 17" }
if (-not $AndroidSdk) { $Missing += "Android SDK (API 34/35)" }

if ($Missing.Count -gt 0) {
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Yellow
    Write-Host "EXPORT STATUS: BLOCKED -- MISSING ANDROID BUILD TOOLCHAIN" -ForegroundColor Yellow
    Write-Host "================================================================================" -ForegroundColor Yellow
    Write-Host "The following prerequisites are required before building Android packages:"
    foreach ($m in $Missing) {
        Write-Host "  - [ ] $m" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "SETUP INSTRUCTIONS FOR WINDOWS:" -ForegroundColor Cyan
    Write-Host "1. Install Godot 4.7.1 Export Templates:"
    Write-Host "   Open Godot -> Editor -> Manage Export Templates -> Download and Install '4.7.1.stable'"
    Write-Host "2. Install OpenJDK 17 (Microsoft Build or Temurin):"
    Write-Host "   winget install Microsoft.OpenJDK.17"
    Write-Host "3. Install Android Studio (or Command Line Tools):"
    Write-Host "   winget install Google.AndroidStudio"
    Write-Host "   In Android Studio -> SDK Manager -> Install SDK Platform 34 and Build-Tools 34.0.0"
    Write-Host "4. Set Environment Variables:"
    Write-Host '   $env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"'
    Write-Host "5. Re-run this export script:"
    Write-Host "   .\tools\android\export_android.ps1"
    Write-Host "================================================================================" -ForegroundColor Yellow
    exit 0
}

# 6. Execute Export
$Presets = @()
if ($Target -eq "all" -or $Target -eq "apk") {
    $Presets += @{ Name = "Android APK (sideload / testers)"; Out = $ApkOut; Type = "APK" }
}
if ($Target -eq "all" -or $Target -eq "aab") {
    $Presets += @{ Name = "Android AAB (Google Play)"; Out = $AabOut; Type = "AAB" }
}

foreach ($p in $Presets) {
    $pType = $p.Type
    $pName = $p.Name
    $pOut = $p.Out
    Write-Host "Exporting $pType with preset '$pName'..."
    & $GodotExe --headless --export-release "$pName" "$pOut"
    if (Test-Path $pOut) {
        $len = (Get-Item $pOut).Length
        $mb = [math]::Round($len / 1048576, 2)
        Write-Host "[SUCCESS] Exported $pType : $pOut ($mb MB)" -ForegroundColor Green
    } else {
        Write-Warning "[FAIL] Export failed to create: $pOut"
    }
}
