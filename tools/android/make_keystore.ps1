# tools/android/make_keystore.ps1
# Script to safely generate Android release keystore and example properties.

$ErrorActionPreference = "Continue"

$AndroidDir = Join-Path $PSScriptRoot "..\..\android"
if (-not (Test-Path $AndroidDir)) {
    New-Item -ItemType Directory -Path $AndroidDir -Force | Out-Null
}

$KeystorePath = Join-Path $AndroidDir "lockdown-heist-release.keystore"
$PropsExamplePath = Join-Path $AndroidDir "keystore.properties.example"

# Write properties example
$PropsExampleContent = @"
# Local Android Release Keystore Configuration
# Copy this file to keystore.properties and fill in your secure credentials.
# NEVER commit keystore.properties or *.keystore to git!

keystore_path=android/lockdown-heist-release.keystore
keystore_alias=lockdownheist
keystore_password=CHANGE_ME_SECURE_PASSWORD
key_password=CHANGE_ME_SECURE_PASSWORD
"@
Set-Content -Path $PropsExamplePath -Value $PropsExampleContent -Encoding UTF8
Write-Host "[OK] Wrote keystore properties template: $PropsExamplePath"

# Check keytool
$KeytoolCmd = Get-Command keytool -ErrorAction SilentlyContinue

if ($null -ne $KeytoolCmd) {
    if (-not (Test-Path $KeystorePath)) {
        Write-Host "Generating release keystore via keytool..."
        & keytool -genkeypair -v -keystore $KeystorePath -alias lockdownheist -keyalg RSA -keysize 2048 -validity 10000 `
            -dname "CN=Lockdown Heist, OU=Games, O=Sushrut Kale, L=Metropolis, ST=State, C=US" `
            -storepass "LockdownBandit2026!" -keypass "LockdownBandit2026!"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[SUCCESS] Generated release keystore at: $KeystorePath"
        } else {
            Write-Warning "keytool command returned exit code $LASTEXITCODE"
        }
    } else {
        Write-Host "[OK] Release keystore already exists at: $KeystorePath"
    }
} else {
    Write-Warning "[BLOCKED: needs JDK] 'keytool' not found in PATH."
    Write-Host "Once OpenJDK 17 is installed, run the following command to generate the release keystore:"
    Write-Host "keytool -genkeypair -v -keystore `"$KeystorePath`" -alias lockdownheist -keyalg RSA -keysize 2048 -validity 10000"
}

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Yellow
Write-Host "CRITICAL SECURITY WARNING:" -ForegroundColor Red
Write-Host "NEVER commit the keystore or passwords to git repository." -ForegroundColor Yellow
Write-Host "Losing this keystore file means you CANNOT update the Google Play listing forever." -ForegroundColor Yellow
Write-Host "Backup this keystore file to an encrypted offline drive." -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Yellow
