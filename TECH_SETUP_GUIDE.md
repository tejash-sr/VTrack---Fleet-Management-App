# Tech Setup Guide for Fleet Management System

## Required Technologies & Installation Guide

### 1. Flutter SDK
**Purpose**: Cross-platform development framework for Driver App (Android) and Manager Dashboard (Web)

**Check if installed**:
```powershell
flutter --version
```

**Install if not present**:
1. Download from: https://docs.flutter.dev/get-started/install/windows
2. Extract to: `C:\flutter` (recommended path)
3. Add to PATH: `C:\flutter\bin`
4. Verify installation:
```powershell
flutter doctor
```

**Required Flutter version**: 3.16.0 or higher

### 2. Android Studio & Android SDK
**Purpose**: Android development, emulator, and APK building

**Check if installed**:
```powershell
where adb
where flutter
```

**Install if not present**:
1. Download from: https://developer.android.com/studio
2. Install to: `C:\Users\%USERNAME%\AppData\Local\Android\Sdk`
3. Set environment variables:
```powershell
$env:ANDROID_HOME = "C:\Users\$env:USERNAME\AppData\Local\Android\Sdk"
$env:PATH += ";$env:ANDROID_HOME\platform-tools;$env:ANDROID_HOME\tools"
```

**Verify setup**:
```powershell
flutter doctor --android-licenses
```

### 3. Git
**Purpose**: Version control and project management

**Check if installed**:
```powershell
git --version
```

**Install if not present**:
1. Download from: https://git-scm.com/download/win
2. Install to: `C:\Program Files\Git`
3. Verify installation:
```powershell
git --version
```

### 4. Node.js & npm
**Purpose**: Firebase CLI and Cloud Functions development

**Check if installed**:
```powershell
node --version
npm --version
```

**Install if not present**:
1. Download from: https://nodejs.org/
2. Install to: `C:\Program Files\nodejs`
3. Verify installation:
```powershell
node --version
npm --version
```

### 5. Firebase CLI
**Purpose**: Firebase project management and deployment

**Check if installed**:
```powershell
firebase --version
```

**Install if not present**:
```powershell
npm install -g firebase-tools
```

**Login to Firebase**:
```powershell
firebase login
```

### 6. VS Code (Recommended Editor)
**Purpose**: Code editing with Flutter extensions

**Check if installed**:
```powershell
code --version
```

**Install if not present**:
1. Download from: https://code.visualstudio.com/
2. Install to: `C:\Users\%USERNAME%\AppData\Local\Programs\Microsoft VS Code`
3. Install Flutter extensions:
   - Flutter
   - Dart
   - Firebase Explorer

### 7. Chrome Browser
**Purpose**: Flutter web development and testing

**Check if installed**:
```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe" -ErrorAction SilentlyContinue
```

**Install if not present**:
1. Download from: https://www.google.com/chrome/
2. Install to: `C:\Program Files\Google\Chrome\Application`

## Complete Setup Process

### Step 1: Environment Setup
```powershell
# Set up environment variables permanently
[Environment]::SetEnvironmentVariable("ANDROID_HOME", "C:\Users\$env:USERNAME\AppData\Local\Android\Sdk", "User")
[Environment]::SetEnvironmentVariable("FLUTTER_ROOT", "C:\flutter", "User")
[Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";C:\flutter\bin;C:\Users\$env:USERNAME\AppData\Local\Android\Sdk\platform-tools", "User")

# Refresh current session
$env:ANDROID_HOME = "C:\Users\$env:USERNAME\AppData\Local\Android\Sdk"
$env:FLUTTER_ROOT = "C:\flutter"
$env:PATH += ";C:\flutter\bin;C:\Users\$env:USERNAME\AppData\Local\Android\Sdk\platform-tools"
```

### Step 2: Flutter Setup
```powershell
# Navigate to Flutter directory
cd C:\flutter

# Run Flutter doctor to check setup
flutter doctor

# Accept Android licenses
flutter doctor --android-licenses

# Enable web support
flutter config --enable-web

# Verify all platforms
flutter doctor
```

### Step 3: Firebase Setup
```powershell
# Login to Firebase
firebase login

# Create new Firebase project (if needed)
firebase projects:create your-project-name

# Initialize Firebase in project directory
cd D:\vtrack
firebase init

# Select services: Firestore, Storage, Functions, Realtime Database
# Select project: your-project-name
# Use default rules and indexes
```

### Step 4: Project Setup
```powershell
# Navigate to project directory
cd D:\vtrack

# Get Flutter dependencies for Driver App
cd driver_app
flutter pub get

# Get Flutter dependencies for Manager Dashboard
cd ..\manager_dashboard
flutter pub get

# Return to root
cd ..
```

### Step 5: Verify Complete Setup
```powershell
# Check Flutter setup
flutter doctor -v

# Check Firebase CLI
firebase --version

# Check Android SDK
adb version

# Check Node.js
node --version
npm --version

# Check Git
git --version
```

## Deployment Commands

### Driver App APK Build
```powershell
cd D:\vtrack\driver_app

# Build debug APK
flutter build apk --debug

# Build release APK (for production)
flutter build apk --release

# APK location: build\app\outputs\flutter-apk\app-release.apk
```

### Manager Dashboard Web Build
```powershell
cd D:\vtrack\manager_dashboard

# Build for web
flutter build web

# Web files location: build\web\
```

### Firebase Deploy
```powershell
cd D:\vtrack

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage

# Deploy Realtime Database rules
firebase deploy --only database

# Deploy Cloud Functions
firebase deploy --only functions

# Deploy everything
firebase deploy
```

## Testing Commands

### Driver App Testing
```powershell
cd D:\vtrack\driver_app

# Run on connected Android device
flutter run

# Run on Android emulator
flutter emulators --launch <emulator_id>
flutter run

# Run tests
flutter test
```

### Manager Dashboard Testing
```powershell
cd D:\vtrack\manager_dashboard

# Run web app locally
flutter run -d chrome

# Run tests
flutter test
```

## Troubleshooting Commands

### Flutter Issues
```powershell
# Clean build cache
flutter clean

# Get packages again
flutter pub get

# Upgrade Flutter
flutter upgrade

# Check for issues
flutter doctor --verbose
```

### Firebase Issues
```powershell
# Clear Firebase cache
firebase logout
firebase login

# Check Firebase project
firebase projects:list

# Switch Firebase project
firebase use <project-id>
```

### Android Issues
```powershell
# Check connected devices
adb devices

# Restart ADB server
adb kill-server
adb start-server

# Check Android SDK location
echo $env:ANDROID_HOME
```

## File Locations Summary

| Component | Installation Path | Purpose |
|-----------|-------------------|---------|
| Flutter SDK | `C:\flutter` | Flutter framework |
| Android SDK | `C:\Users\%USERNAME%\AppData\Local\Android\Sdk` | Android development |
| Git | `C:\Program Files\Git` | Version control |
| Node.js | `C:\Program Files\nodejs` | JavaScript runtime |
| VS Code | `C:\Users\%USERNAME%\AppData\Local\Programs\Microsoft VS Code` | Code editor |
| Chrome | `C:\Program Files\Google\Chrome\Application` | Web development |
| Project | `D:\vtrack` | Your Fleet Management System |

## Next Steps After Setup

1. **Verify all tools are working**:
   ```powershell
   flutter doctor
   firebase --version
   ```

2. **Test with sample project**:
   ```powershell
   flutter create test_app
   cd test_app
   flutter run
   ```

3. **Start building your Fleet Management System**:
   ```powershell
   cd D:\vtrack
   # Follow the project structure and implementation guides
   ```

## System Requirements

- **OS**: Windows 10/11 (64-bit)
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 10GB free space minimum
- **Processor**: Intel i5 or equivalent
- **Internet**: Required for Flutter packages and Firebase

## Performance Tips

1. **Use SSD** for Flutter and Android SDK installation
2. **Close unnecessary applications** during builds
3. **Use physical device** instead of emulator for faster testing
4. **Enable Windows Developer Mode** for better Flutter performance
5. **Use VS Code Flutter extensions** for better development experience
