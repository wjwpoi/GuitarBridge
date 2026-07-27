# GuitarBridge Build Script (Windows PowerShell)
# Usage: .\tool\build.ps1 [-Platform android|ios|windows|macos|web|all] [-Release]

param(
    [string]$Platform = "windows",
    [switch]$Release
)

$ErrorActionPreference = "Stop"
Push-Location $PSScriptRoot\..
$mode = if ($Release) { "release" } else { "debug" }

Write-Host "=== GuitarBridge Build ===" -ForegroundColor Cyan
Write-Host "Platform: $Platform | Mode: $mode" -ForegroundColor Yellow

function Build-Platform($p) {
    Write-Host "`n--- Building $p ($mode) ---" -ForegroundColor Green
    flutter build $p --$mode
    if ($LASTEXITCODE -ne 0) { throw "Build failed for $p" }
}

# Ensure Flutter is ready
flutter pub get
flutter analyze

$platforms = if ($Platform -eq "all") { @("android", "ios", "windows", "macos", "web") } else { @($Platform) }

foreach ($p in $platforms) {
    try {
        Build-Platform $p
        Write-Host "  [OK] $p build succeeded" -ForegroundColor Green
    } catch {
        Write-Host "  [FAIL] $p build failed: $_" -ForegroundColor Red
    }
}

Write-Host "`n=== Build Complete ===" -ForegroundColor Cyan

# Output locations
Write-Host "Artifacts:" -ForegroundColor Yellow
if ($platforms -contains "android") { Write-Host "  Android: build\app\outputs\flutter-apk\*.apk" }
if ($platforms -contains "windows") { Write-Host "  Windows: build\windows\x64\runner\Release\" }
if ($platforms -contains "macos")   { Write-Host "  macOS:   build\macos\Build\Products\Release\" }
if ($platforms -contains "web")     { Write-Host "  Web:     build\web\" }

Pop-Location
