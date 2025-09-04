# Fleet Management System - Setup Verification Script
# Run this script to check what's already installed on your system

Write-Host "=== Fleet Management System - Setup Verification ===" -ForegroundColor Green
Write-Host "Checking installed technologies..." -ForegroundColor Yellow
Write-Host ""

# Check Flutter
Write-Host "1. Checking Flutter SDK..." -ForegroundColor Cyan
try {
    $flutterVersion = flutter --version 2>$null
    if ($flutterVersion) {
        Write-Host "   ✓ Flutter is installed" -ForegroundColor Green
        $flutterVersion | Select-String "Flutter" | ForEach-Object { Write-Host "   Version: $_" -ForegroundColor Gray }
    } else {
        Write-Host "   ✗ Flutter is NOT installed" -ForegroundColor Red
    }
} catch {
    Write-Host "   ✗ Flutter is NOT installed" -ForegroundColor Red
}

# Check Android SDK
Write-Host "`n2. Checking Android SDK..." -ForegroundColor Cyan
try {
    $adbVersion = adb version 2>$null
    if ($adbVersion) {
        Write-Host "   ✓ Android SDK is installed" -ForegroundColor Green
        $adbVersion | Select-String "Android Debug Bridge" | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
    } else {
        Write-Host "   ✗ Android SDK is NOT installed" -ForegroundColor Red
    }
} catch {
    Write-Host "   ✗ Android SDK is NOT installed" -ForegroundColor Red
}

# Check Git
Write-Host "`n3. Checking Git..." -ForegroundColor Cyan
try {
    $gitVersion = git --version 2>$null
    if ($gitVersion) {
        Write-Host "   ✓ Git is installed" -ForegroundColor Green
        Write-Host "   $gitVersion" -ForegroundColor Gray
    } else {
        Write-Host "   ✗ Git is NOT installed" -ForegroundColor Red
    }
} catch {
    Write-Host "   ✗ Git is NOT installed" -ForegroundColor Red
}

# Check Node.js
Write-Host "`n4. Checking Node.js..." -ForegroundColor Cyan
try {
    $nodeVersion = node --version 2>$null
    if ($nodeVersion) {
        Write-Host "   ✓ Node.js is installed" -ForegroundColor Green
        Write-Host "   Version: $nodeVersion" -ForegroundColor Gray
    } else {
        Write-Host "   ✗ Node.js is NOT installed" -ForegroundColor Red
    }
} catch {
    Write-Host "   ✗ Node.js is NOT installed" -ForegroundColor Red
}

# Check npm
Write-Host "`n5. Checking npm..." -ForegroundColor Cyan
try {
    $npmVersion = npm --version 2>$null
    if ($npmVersion) {
        Write-Host "   ✓ npm is installed" -ForegroundColor Green
        Write-Host "   Version: $npmVersion" -ForegroundColor Gray
    } else {
        Write-Host "   ✗ npm is NOT installed" -ForegroundColor Red
    }
} catch {
    Write-Host "   ✗ npm is NOT installed" -ForegroundColor Red
}

# Check Firebase CLI
Write-Host "`n6. Checking Firebase CLI..." -ForegroundColor Cyan
try {
    $firebaseVersion = firebase --version 2>$null
    if ($firebaseVersion) {
        Write-Host "   ✓ Firebase CLI is installed" -ForegroundColor Green
        Write-Host "   Version: $firebaseVersion" -ForegroundColor Gray
    } else {
        Write-Host "   ✗ Firebase CLI is NOT installed" -ForegroundColor Red
    }
} catch {
    Write-Host "   ✗ Firebase CLI is NOT installed" -ForegroundColor Red
}

# Check VS Code
Write-Host "`n7. Checking VS Code..." -ForegroundColor Cyan
try {
    $codeVersion = code --version 2>$null
    if ($codeVersion) {
        Write-Host "   ✓ VS Code is installed" -ForegroundColor Green
        $codeVersion | Select-Object -First 1 | ForEach-Object { Write-Host "   Version: $_" -ForegroundColor Gray }
    } else {
        Write-Host "   ✗ VS Code is NOT installed" -ForegroundColor Red
    }
} catch {
    Write-Host "   ✗ VS Code is NOT installed" -ForegroundColor Red
}

# Check Chrome
Write-Host "`n8. Checking Chrome Browser..." -ForegroundColor Cyan
try {
    $chromePath = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe" -ErrorAction SilentlyContinue
    if ($chromePath) {
        Write-Host "   ✓ Chrome is installed" -ForegroundColor Green
        Write-Host "   Path: $($chromePath.'(Default)')" -ForegroundColor Gray
    } else {
        Write-Host "   ✗ Chrome is NOT installed" -ForegroundColor Red
    }
} catch {
    Write-Host "   ✗ Chrome is NOT installed" -ForegroundColor Red
}

# Check Environment Variables
Write-Host "`n9. Checking Environment Variables..." -ForegroundColor Cyan
$androidHome = $env:ANDROID_HOME
$flutterRoot = $env:FLUTTER_ROOT

if ($androidHome) {
    Write-Host "   ✓ ANDROID_HOME is set: $androidHome" -ForegroundColor Green
} else {
    Write-Host "   ✗ ANDROID_HOME is NOT set" -ForegroundColor Red
}

if ($flutterRoot) {
    Write-Host "   ✓ FLUTTER_ROOT is set: $flutterRoot" -ForegroundColor Green
} else {
    Write-Host "   ✗ FLUTTER_ROOT is NOT set" -ForegroundColor Red
}

# Check Flutter Doctor
Write-Host "`n10. Running Flutter Doctor..." -ForegroundColor Cyan
try {
    Write-Host "   Running flutter doctor (this may take a moment)..." -ForegroundColor Yellow
    flutter doctor 2>$null | ForEach-Object {
        if ($_ -match "✓") {
            Write-Host "   $_" -ForegroundColor Green
        } elseif ($_ -match "✗") {
            Write-Host "   $_" -ForegroundColor Red
        } else {
            Write-Host "   $_" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "   ✗ Could not run flutter doctor" -ForegroundColor Red
}

Write-Host "`n=== Setup Verification Complete ===" -ForegroundColor Green
Write-Host ""

# Summary and next steps
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Install missing technologies using the TECH_SETUP_GUIDE.md" -ForegroundColor White
Write-Host "2. Set up environment variables" -ForegroundColor White
Write-Host "3. Run 'flutter doctor' to resolve any issues" -ForegroundColor White
Write-Host "4. Follow the complete setup process in TECH_SETUP_GUIDE.md" -ForegroundColor White

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
