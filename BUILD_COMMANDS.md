# Build Commands & Setup Guide

## Prerequisites

1. **Flutter SDK** (3.0.0 or higher)
2. **Firebase CLI** (`npm install -g firebase-tools`)
3. **Android Studio** (for Android development)
4. **VS Code** or **Android Studio** (for development)

## Firebase Setup

### 1. Create Firebase Project
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Create new project
firebase projects:create fleet-management-system

# Initialize Firebase in your project
firebase init
```

### 2. Enable Firebase Services
- Authentication (Phone & Email/Password)
- Firestore Database
- Cloud Storage
- Realtime Database
- Cloud Functions

### 3. Configure FlutterFire
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for Driver App
cd driver_app
flutterfire configure --project=fleet-management-system

# Configure Firebase for Manager Dashboard
cd ../manager_dashboard
flutterfire configure --project=fleet-management-system
```

## Driver App (Android APK)

### 1. Setup
```bash
cd driver_app

# Get dependencies
flutter pub get

# Generate Firebase options
flutterfire configure --project=fleet-management-system
```

### 2. Build APK
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Split APKs by ABI (smaller file size)
flutter build apk --split-per-abi --release
```

### 3. Install APK
```bash
# Install debug APK
flutter install

# Install release APK
flutter install --release
```

### 4. APK Location
- Debug: `build/app/outputs/flutter-apk/app-debug.apk`
- Release: `build/app/outputs/flutter-apk/app-release.apk`

## Manager Dashboard (Flutter Web)

### 1. Setup
```bash
cd manager_dashboard

# Get dependencies
flutter pub get

# Generate Firebase options
flutterfire configure --project=fleet-management-system
```

### 2. Run Web App
```bash
# Development server
flutter run -d chrome

# Production build
flutter build web --release
```

### 3. Deploy to Firebase Hosting
```bash
# Build for production
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

## Testing Commands

### Driver App Testing
```bash
cd driver_app

# Run tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart

# Run on device
flutter run
```

### Manager Dashboard Testing
```bash
cd manager_dashboard

# Run tests
flutter test

# Run on web
flutter run -d chrome
```

## Environment Setup

### 1. Create Environment Files

**Driver App (.env)**
```env
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id
```

**Manager Dashboard (.env)**
```env
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id
```

### 2. Firebase Security Rules
```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage

# Deploy Realtime Database rules
firebase deploy --only database
```

## Demo Data Setup

### 1. Create Test Manager Account
```javascript
// Run in Firebase Console > Authentication
// Create user with email: manager@fleet.com, password: manager123
```

### 2. Create Test Driver Data
```javascript
// Run in Firebase Console > Firestore
// Create document in 'drivers' collection
{
  name: "John Doe",
  phone: "+1234567890",
  status: "online",
  isActive: true,
  createdAt: new Date(),
  lastUpdate: new Date()
}
```

## Troubleshooting

### Common Issues

1. **Firebase Configuration Error**
   ```bash
   # Regenerate Firebase options
   flutterfire configure --project=your-project-id
   ```

2. **Build Errors**
   ```bash
   # Clean and rebuild
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

3. **Permission Errors**
   ```bash
   # Check Android permissions in android/app/src/main/AndroidManifest.xml
   # Ensure location, camera, and storage permissions are added
   ```

4. **Firebase Rules Issues**
   ```bash
   # Test rules in Firebase Console > Firestore > Rules
   # Use Rules Playground to test your rules
   ```

## Performance Optimization

### APK Size Optimization
```bash
# Enable ProGuard/R8
# In android/app/build.gradle, set:
minifyEnabled true
shrinkResources true

# Use split APKs
flutter build apk --split-per-abi --release
```

### Web Performance
```bash
# Enable tree shaking
flutter build web --release --tree-shake-icons

# Use web renderer
flutter run -d chrome --web-renderer html
```

## Deployment Checklist

### Driver App
- [ ] Firebase project configured
- [ ] All permissions added to AndroidManifest.xml
- [ ] Release APK built successfully
- [ ] APK tested on physical device
- [ ] Location services working
- [ ] Camera functionality working
- [ ] Firebase authentication working

### Manager Dashboard
- [ ] Firebase project configured
- [ ] Web app builds successfully
- [ ] Firebase hosting configured
- [ ] All features working in browser
- [ ] Real-time updates working
- [ ] Excel export functionality working

## Support

For issues or questions:
1. Check Firebase Console for errors
2. Review Flutter logs: `flutter logs`
3. Check Firebase logs: `firebase functions:log`
4. Verify security rules in Firebase Console
