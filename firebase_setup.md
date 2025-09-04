# Firebase Setup Guide

## 1. Firebase Project Creation

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project named "FleetManagementSystem"
3. Enable Google Analytics (optional)
4. Add Android app with package name: `com.fleetmanagement.driver`
5. Add Web app for Manager Dashboard

## 2. Firebase Services to Enable

### Authentication
- Enable Phone Authentication
- Add test phone numbers for development

### Firestore Database
- Create database in production mode
- Set up security rules (provided in firestore.rules)

### Storage
- Enable Cloud Storage
- Set up security rules (provided in storage.rules)

### Realtime Database
- Create Realtime Database
- Set up security rules (provided in database.rules)

### Cloud Functions
- Enable Cloud Functions
- Deploy functions for SOS alerts and notifications

## 3. Configuration Files

Download and place these files in your Flutter projects:
- `google-services.json` (Android) → `android/app/`
- `firebase_options.dart` (Web) → `lib/firebase_options.dart`

## 4. Database Structure

### Firestore Collections

```
drivers/
  {driverId}/
    - name: string
    - phone: string
    - status: string (online/offline/busy)
    - currentTripId: string?
    - lastLocation: GeoPoint
    - lastUpdate: timestamp
    - isActive: boolean

trips/
  {tripId}/
    - driverId: string
    - startTime: timestamp
    - endTime: timestamp?
    - startLocation: GeoPoint
    - endLocation: GeoPoint?
    - route: array of GeoPoints
    - status: string (active/completed/cancelled)
    - totalDistance: number
    - totalExpenses: number

expenses/
  {expenseId}/
    - tripId: string
    - driverId: string
    - amount: number
    - description: string
    - photoURL: string
    - timestamp: timestamp
    - category: string

alerts/
  {alertId}/
    - driverId: string
    - type: string (SOS/emergency)
    - location: GeoPoint
    - timestamp: timestamp
    - status: string (active/resolved)
    - message: string
```

### Realtime Database Structure

```
fleet_locations/
  {driverId}/
    - latitude: number
    - longitude: number
    - timestamp: number
    - accuracy: number
    - speed: number
```

## 5. Environment Variables

Create `.env` files for both projects:

### Driver App (.env)
```
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id
```

### Manager Dashboard (.env)
```
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id
```
