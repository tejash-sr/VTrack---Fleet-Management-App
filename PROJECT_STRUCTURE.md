# Fleet Management System - Project Structure

## Complete Project Overview

```
fleet-management-system/
├── driver_app/                          # Flutter Android App
│   ├── android/
│   │   ├── app/
│   │   │   ├── src/main/
│   │   │   │   ├── AndroidManifest.xml
│   │   │   │   └── kotlin/
│   │   │   └── build.gradle
│   │   └── build.gradle
│   ├── lib/
│   │   ├── main.dart
│   │   ├── firebase_options.dart
│   │   ├── models/
│   │   │   └── expense.dart
│   │   ├── services/
│   │   │   ├── auth_service.dart
│   │   │   ├── location_service.dart
│   │   │   ├── firestore_service.dart
│   │   │   ├── storage_service.dart
│   │   │   └── realtime_service.dart
│   │   ├── screens/
│   │   │   ├── splash_screen.dart
│   │   │   ├── auth/
│   │   │   │   └── login_screen.dart
│   │   │   ├── home/
│   │   │   │   └── home_screen.dart
│   │   │   ├── trip/
│   │   │   │   └── trip_screen.dart
│   │   │   ├── expenses/
│   │   │   │   └── expenses_screen.dart
│   │   │   └── sos/
│   │   │       └── sos_screen.dart
│   │   └── utils/
│   │       └── app_theme.dart
│   ├── assets/
│   │   ├── images/
│   │   ├── icons/
│   │   ├── animations/
│   │   └── fonts/
│   └── pubspec.yaml
│
├── manager_dashboard/                   # Flutter Web App
│   ├── lib/
│   │   ├── main.dart
│   │   ├── firebase_options.dart
│   │   ├── services/
│   │   │   ├── auth_service.dart
│   │   │   ├── firestore_service.dart
│   │   │   ├── realtime_service.dart
│   │   │   └── excel_export_service.dart
│   │   ├── screens/
│   │   │   ├── splash_screen.dart
│   │   │   ├── auth/
│   │   │   │   └── login_screen.dart
│   │   │   ├── dashboard/
│   │   │   │   └── dashboard_screen.dart
│   │   │   ├── fleet_map/
│   │   │   │   └── fleet_map_screen.dart
│   │   │   ├── trip_history/
│   │   │   │   └── trip_history_screen.dart
│   │   │   └── expenses/
│   │   │       └── expenses_screen.dart
│   │   └── utils/
│   │       └── app_theme.dart
│   ├── assets/
│   │   ├── images/
│   │   ├── icons/
│   │   ├── animations/
│   │   └── fonts/
│   └── pubspec.yaml
│
├── firebase/                            # Firebase Configuration
│   ├── firestore.rules
│   ├── storage.rules
│   ├── database.rules
│   └── functions/
│       └── index.js
│
├── docs/                                # Documentation
│   ├── firebase_setup.md
│   ├── BUILD_COMMANDS.md
│   ├── DEMO_SCRIPT.md
│   └── PROJECT_STRUCTURE.md
│
└── README.md
```

## Driver App Structure

### Core Services
- **AuthService**: Phone authentication, user management
- **LocationService**: GPS tracking, location updates
- **FirestoreService**: Trip management, expense tracking
- **StorageService**: Photo uploads, file management
- **RealtimeService**: Real-time location sharing, SOS alerts

### Key Screens
- **SplashScreen**: App initialization and auth check
- **LoginScreen**: Phone authentication with OTP
- **HomeScreen**: Dashboard with quick actions
- **TripScreen**: Trip management (start/end)
- **ExpensesScreen**: Add expenses with photo receipts
- **SOSScreen**: Emergency alert functionality

### Features
- ✅ Phone authentication with Firebase Auth
- ✅ Real-time GPS tracking
- ✅ Trip management with route tracking
- ✅ Expense tracking with photo receipts
- ✅ SOS emergency alerts
- ✅ Offline data synchronization
- ✅ Clean, intuitive UI

## Manager Dashboard Structure

### Core Services
- **AuthService**: Email/password authentication
- **FirestoreService**: Data management and analytics
- **RealtimeService**: Real-time fleet monitoring
- **ExcelExportService**: Data export functionality

### Key Screens
- **SplashScreen**: App initialization
- **LoginScreen**: Manager authentication
- **DashboardScreen**: Overview with statistics
- **FleetMapScreen**: Real-time fleet map
- **TripHistoryScreen**: Trip analytics and history
- **ExpensesScreen**: Expense management and export

### Features
- ✅ Real-time fleet map with OpenStreetMap
- ✅ Live driver location tracking
- ✅ SOS alert notifications
- ✅ Trip history and analytics
- ✅ Expense management
- ✅ Excel export functionality
- ✅ Responsive web design

## Firebase Database Structure

### Firestore Collections

#### drivers/
```javascript
{
  name: string,
  phone: string,
  status: "online" | "offline" | "busy",
  currentTripId: string?,
  lastLocation: GeoPoint,
  lastUpdate: timestamp,
  isActive: boolean
}
```

#### trips/
```javascript
{
  tripId: string,
  driverId: string,
  startTime: timestamp,
  endTime: timestamp?,
  startLocation: GeoPoint,
  endLocation: GeoPoint?,
  route: GeoPoint[],
  status: "active" | "completed" | "cancelled",
  totalDistance: number,
  totalExpenses: number
}
```

#### expenses/
```javascript
{
  expenseId: string,
  tripId: string,
  driverId: string,
  amount: number,
  description: string,
  photoURL: string,
  category: string,
  timestamp: timestamp
}
```

#### alerts/
```javascript
{
  alertId: string,
  driverId: string,
  type: "SOS" | "emergency",
  location: GeoPoint,
  message: string,
  timestamp: timestamp,
  status: "active" | "resolved"
}
```

### Realtime Database Structure

#### fleet_locations/
```javascript
{
  [driverId]: {
    latitude: number,
    longitude: number,
    timestamp: number,
    accuracy: number,
    speed: number
  }
}
```

#### sos_alerts/
```javascript
{
  [alertId]: {
    driverId: string,
    location: {
      latitude: number,
      longitude: number
    },
    message: string,
    timestamp: number,
    status: "active" | "resolved"
  }
}
```

## Security Rules

### Firestore Rules
- Drivers can only access their own data
- Managers have full access to all collections
- Secure read/write operations based on user roles

### Storage Rules
- Drivers can upload photos to their own folders
- Managers can access all uploaded files
- Secure file access based on user authentication

### Realtime Database Rules
- Drivers can update their own location data
- Managers can read all location data
- Secure real-time data sharing

## Dependencies

### Driver App Dependencies
```yaml
# Firebase
firebase_core: ^2.24.2
firebase_auth: ^4.15.3
cloud_firestore: ^4.13.6
firebase_storage: ^11.5.6
firebase_database: ^10.4.0

# Location & Maps
geolocator: ^10.1.0
geocoding: ^2.1.1
flutter_map: ^6.1.0
latlong2: ^0.8.1

# Image & File handling
image_picker: ^1.0.4
path_provider: ^2.1.1

# State Management
provider: ^6.1.1

# UI & Utils
cupertino_icons: ^1.0.6
flutter_svg: ^2.0.9
lottie: ^2.7.0
permission_handler: ^11.1.0
url_launcher: ^6.2.2
```

### Manager Dashboard Dependencies
```yaml
# Firebase
firebase_core: ^2.24.2
firebase_auth: ^4.15.3
cloud_firestore: ^4.13.6
firebase_storage: ^11.5.6
firebase_database: ^10.4.0

# Maps
flutter_map: ^6.1.0
latlong2: ^0.8.1

# State Management
provider: ^6.1.1

# Excel Export
excel: ^4.0.6
path_provider: ^2.1.1

# Charts
fl_chart: ^0.66.0

# Data Tables
data_table_2: ^2.5.11
```

## Build & Deployment

### Driver App (Android APK)
```bash
cd driver_app
flutter build apk --release
```

### Manager Dashboard (Web)
```bash
cd manager_dashboard
flutter build web --release
firebase deploy --only hosting
```

## Testing Strategy

### Unit Tests
- Service layer testing
- Business logic validation
- Data model testing

### Integration Tests
- Firebase integration
- Location services
- Camera functionality

### End-to-End Tests
- Complete user flows
- Cross-platform compatibility
- Performance testing

## Performance Considerations

### Driver App
- Efficient location tracking
- Optimized image compression
- Offline data caching
- Battery usage optimization

### Manager Dashboard
- Real-time data updates
- Map rendering optimization
- Large dataset handling
- Responsive design

## Scalability Features

### Firebase Scaling
- Automatic scaling with user growth
- Real-time database optimization
- Cloud Functions for heavy processing
- CDN for static assets

### Application Scaling
- Modular architecture
- Efficient state management
- Optimized database queries
- Caching strategies

## Maintenance & Updates

### Regular Updates
- Flutter SDK updates
- Firebase service updates
- Security patches
- Feature enhancements

### Monitoring
- Firebase Analytics
- Crash reporting
- Performance monitoring
- User feedback collection
