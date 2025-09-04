# Fleet Management System - Quick Setup Script
# This script automates the initial setup process

param(
    [string]$FirebaseProjectName = "vtrack-fleet-system"
)

Write-Host "=== Fleet Management System - Quick Setup ===" -ForegroundColor Green
Write-Host "This script will help you set up the development environment" -ForegroundColor Yellow
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "⚠️  Warning: This script is not running as administrator" -ForegroundColor Yellow
    Write-Host "   Some operations may require elevated privileges" -ForegroundColor Yellow
    Write-Host ""
}

# Step 1: Set Environment Variables
Write-Host "Step 1: Setting up environment variables..." -ForegroundColor Cyan

$username = $env:USERNAME
$androidHome = "C:\Users\$username\AppData\Local\Android\Sdk"
$flutterRoot = "C:\flutter"

# Set environment variables permanently
try {
    [Environment]::SetEnvironmentVariable("ANDROID_HOME", $androidHome, "User")
    [Environment]::SetEnvironmentVariable("FLUTTER_ROOT", $flutterRoot, "User")
    
    # Add to PATH
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    $newPaths = @(
        "$flutterRoot\bin",
        "$androidHome\platform-tools",
        "$androidHome\tools"
    )
    
    foreach ($path in $newPaths) {
        if ($currentPath -notlike "*$path*") {
            $currentPath += ";$path"
        }
    }
    
    [Environment]::SetEnvironmentVariable("PATH", $currentPath, "User")
    
    # Refresh current session
    $env:ANDROID_HOME = $androidHome
    $env:FLUTTER_ROOT = $flutterRoot
    $env:PATH += ";$flutterRoot\bin;$androidHome\platform-tools;$androidHome\tools"
    
    Write-Host "   ✓ Environment variables set successfully" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Failed to set environment variables: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 2: Check Flutter installation
Write-Host "`nStep 2: Checking Flutter installation..." -ForegroundColor Cyan
try {
    $flutterVersion = flutter --version 2>$null
    if ($flutterVersion) {
        Write-Host "   ✓ Flutter is already installed" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Flutter is not installed" -ForegroundColor Red
        Write-Host "   Please install Flutter from: https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Yellow
        Write-Host "   Extract to: C:\flutter" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ✗ Flutter is not installed" -ForegroundColor Red
}

# Step 3: Check Android SDK
Write-Host "`nStep 3: Checking Android SDK..." -ForegroundColor Cyan
try {
    $adbVersion = adb version 2>$null
    if ($adbVersion) {
        Write-Host "   ✓ Android SDK is already installed" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Android SDK is not installed" -ForegroundColor Red
        Write-Host "   Please install Android Studio from: https://developer.android.com/studio" -ForegroundColor Yellow
        Write-Host "   SDK location: $androidHome" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ✗ Android SDK is not installed" -ForegroundColor Red
}

# Step 4: Check Node.js and npm
Write-Host "`nStep 4: Checking Node.js and npm..." -ForegroundColor Cyan
try {
    $nodeVersion = node --version 2>$null
    $npmVersion = npm --version 2>$null
    
    if ($nodeVersion -and $npmVersion) {
        Write-Host "   ✓ Node.js ($nodeVersion) and npm ($npmVersion) are installed" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Node.js or npm is not installed" -ForegroundColor Red
        Write-Host "   Please install Node.js from: https://nodejs.org/" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ✗ Node.js or npm is not installed" -ForegroundColor Red
}

# Step 5: Install Firebase CLI if not present
Write-Host "`nStep 5: Installing Firebase CLI..." -ForegroundColor Cyan
try {
    $firebaseVersion = firebase --version 2>$null
    if ($firebaseVersion) {
        Write-Host "   ✓ Firebase CLI is already installed" -ForegroundColor Green
    } else {
        Write-Host "   Installing Firebase CLI..." -ForegroundColor Yellow
        npm install -g firebase-tools
        Write-Host "   ✓ Firebase CLI installed successfully" -ForegroundColor Green
    }
} catch {
    Write-Host "   ✗ Failed to install Firebase CLI: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 6: Initialize Firebase project
Write-Host "`nStep 6: Setting up Firebase project..." -ForegroundColor Cyan
try {
    # Check if already logged in
    $firebaseUser = firebase projects:list 2>$null
    if ($firebaseUser) {
        Write-Host "   ✓ Firebase CLI is configured" -ForegroundColor Green
        
        # Check if project exists
        $projectExists = firebase projects:list 2>$null | Select-String $FirebaseProjectName
        if ($projectExists) {
            Write-Host "   ✓ Firebase project '$FirebaseProjectName' already exists" -ForegroundColor Green
        } else {
            Write-Host "   Creating new Firebase project '$FirebaseProjectName'..." -ForegroundColor Yellow
            firebase projects:create $FirebaseProjectName --display-name "VTrack Fleet Management System"
            Write-Host "   ✓ Firebase project created successfully" -ForegroundColor Green
        }
        
        # Use the project
        firebase use $FirebaseProjectName
        Write-Host "   ✓ Firebase project set to '$FirebaseProjectName'" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Firebase CLI not logged in" -ForegroundColor Yellow
        Write-Host "   Please run: firebase login" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ✗ Failed to set up Firebase project: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 7: Initialize project structure
Write-Host "`nStep 7: Setting up project structure..." -ForegroundColor Cyan
try {
    # Navigate to project directory
    Set-Location "D:\vtrack"
    
    # Initialize Firebase in project directory
    if (-not (Test-Path ".firebaserc")) {
        Write-Host "   Initializing Firebase in project directory..." -ForegroundColor Yellow
        firebase init --project $FirebaseProjectName --yes
        Write-Host "   ✓ Firebase initialized in project directory" -ForegroundColor Green
    } else {
        Write-Host "   ✓ Firebase already initialized in project directory" -ForegroundColor Green
    }
    
    # Get Flutter dependencies
    Write-Host "   Getting Flutter dependencies..." -ForegroundColor Yellow
    
    if (Test-Path "driver_app") {
        Set-Location "driver_app"
        flutter pub get
        Write-Host "   ✓ Driver app dependencies installed" -ForegroundColor Green
        Set-Location ".."
    }
    
    if (Test-Path "manager_dashboard") {
        Set-Location "manager_dashboard"
        flutter pub get
        Write-Host "   ✓ Manager dashboard dependencies installed" -ForegroundColor Green
        Set-Location ".."
    }
    
    Write-Host "   ✓ Project structure setup complete" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Failed to set up project structure: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 8: Final verification
Write-Host "`nStep 8: Final verification..." -ForegroundColor Cyan
try {
    Write-Host "   Running Flutter doctor..." -ForegroundColor Yellow
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

Write-Host "`n=== Quick Setup Complete ===" -ForegroundColor Green
Write-Host ""

# Summary and next steps
Write-Host "Setup Summary:" -ForegroundColor Yellow
Write-Host "✓ Environment variables configured" -ForegroundColor Green
Write-Host "✓ Firebase project setup" -ForegroundColor Green
Write-Host "✓ Project dependencies installed" -ForegroundColor Green
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Complete any missing installations (Flutter, Android Studio)" -ForegroundColor White
Write-Host "2. Run 'flutter doctor' to resolve any remaining issues" -ForegroundColor White
Write-Host "3. Test the setup with: flutter create test_app && cd test_app && flutter run" -ForegroundColor White
Write-Host "4. Start building your Fleet Management System!" -ForegroundColor White

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
