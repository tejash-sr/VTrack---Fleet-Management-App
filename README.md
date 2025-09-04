# 🚛 Fleet Management System

A comprehensive Fleet Management System built with **Flutter** and **Firebase**, featuring real-time GPS tracking, expense management, and SOS alerts.

## 🛠 Tech Stack

- **Backend**: Firebase (Firestore, Authentication, Storage, Cloud Functions, Realtime Database)
- **Driver App**: Flutter (Android APK)
- **Manager Dashboard**: Flutter Web
- **Maps**: OpenStreetMap (free)
- **Real-time**: Firebase Realtime Database + Firestore

## 📱 Features

### Driver App (Android)
- ✅ Phone authentication with OTP
- ✅ Real-time GPS tracking
- ✅ Trip management (start/end with route tracking)
- ✅ Expense tracking with photo receipts
- ✅ SOS emergency alerts
- ✅ Offline data synchronization
- ✅ Clean, intuitive UI

### Manager Dashboard (Web)
- ✅ Real-time fleet map with OpenStreetMap
- ✅ Live driver location tracking
- ✅ SOS alert notifications with sound
- ✅ Trip history and analytics
- ✅ Expense management and export
- ✅ Excel export functionality
- ✅ Responsive web design

## 🚀 Quick Start

### 1. Firebase Setup
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login and create project
firebase login
firebase projects:create fleet-management-system

# Initialize Firebase
firebase init
```

### 2. Driver App
```bash
cd driver_app
flutter pub get
flutterfire configure --project=fleet-management-system
flutter build apk --release
```

### 3. Manager Dashboard
```bash
cd manager_dashboard
flutter pub get
flutterfire configure --project=fleet-management-system
flutter run -d chrome
```

## 📁 Project Structure

```
fleet-management-system/
├── driver_app/                    # Flutter Android App
├── manager_dashboard/             # Flutter Web App
├── firebase/                      # Firebase Configuration
├── docs/                          # Documentation
└── README.md
```

## 🔧 Configuration

### Firebase Services Required
- **Authentication** (Phone & Email/Password)
- **Firestore Database**
- **Cloud Storage**
- **Realtime Database**
- **Cloud Functions**

### Environment Setup
1. Create Firebase project
2. Enable required services
3. Configure FlutterFire for both apps
4. Deploy security rules
5. Set up test data

## 📊 Database Structure

### Firestore Collections
- `drivers/` - Driver profiles and status
- `trips/` - Trip records with routes
- `expenses/` - Expense tracking with photos
- `alerts/` - SOS and emergency alerts

### Realtime Database
- `fleet_locations/` - Real-time driver locations
- `sos_alerts/` - Live SOS notifications

## 🔐 Security

- Firebase Security Rules for data access control
- Role-based authentication (Driver/Manager)
- Secure file uploads with validation
- Encrypted data transmission

## 📈 Demo

### Test Accounts
**Manager:**
- Email: `manager@fleet.com`
- Password: `manager123`

**Driver:**
- Phone: `+1234567890`
- OTP: `123456`

### Demo Flow
1. Manager Dashboard overview
2. Driver login and trip start
3. Real-time location tracking
4. Expense addition with photo
5. SOS alert and response
6. Data export functionality

## 🏗 Build & Deploy

### Driver App (APK)
```bash
flutter build apk --release
# APK location: build/app/outputs/flutter-apk/app-release.apk
```

### Manager Dashboard (Web)
```bash
flutter build web --release
firebase deploy --only hosting
```

## 📋 Documentation

- [Firebase Setup Guide](firebase_setup.md)
- [Build Commands](BUILD_COMMANDS.md)
- [Demo Script](DEMO_SCRIPT.md)
- [Project Structure](PROJECT_STRUCTURE.md)

## 🧪 Testing

### Driver App Testing
- Phone authentication flow
- GPS location accuracy
- Camera functionality
- Offline synchronization
- SOS alert system

### Manager Dashboard Testing
- Real-time map updates
- Data export functionality
- Responsive design
- Cross-browser compatibility

## 🔄 Development Workflow

1. **Setup**: Clone repo and configure Firebase
2. **Development**: Use Flutter hot reload for rapid development
3. **Testing**: Run on physical devices for accurate testing
4. **Build**: Generate APK and web builds
5. **Deploy**: Deploy to Firebase Hosting

## 📱 Supported Platforms

- **Android**: API 21+ (Android 5.0+)
- **Web**: Modern browsers (Chrome, Firefox, Safari, Edge)
- **iOS**: Compatible (requires iOS configuration)

## 🚨 SOS Alert System

- Real-time emergency notifications
- Automatic location sharing
- Manager dashboard alerts with sound
- Emergency contact integration
- Alert resolution tracking

## 💰 Cost Considerations

- **Firebase**: Pay-as-you-go with generous free tier
- **OpenStreetMap**: Free map tiles
- **Development**: Flutter is free and open-source
- **Hosting**: Firebase Hosting with free tier

## 🔮 Future Enhancements

- Push notifications
- Advanced analytics dashboard
- Route optimization
- Fuel efficiency tracking
- Maintenance scheduling
- Driver performance metrics

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
1. Check the documentation
2. Review Firebase Console logs
3. Check Flutter logs: `flutter logs`
4. Create an issue in the repository

## 🎯 Key Benefits

- **Real-time Tracking**: Live fleet monitoring
- **Cost Effective**: Free map tiles, Firebase free tier
- **Scalable**: Firebase auto-scaling
- **Secure**: Enterprise-grade security
- **Offline Ready**: Works without internet
- **Easy Deployment**: One-click deployment
- **Cross-platform**: Android + Web

---

**Built with ❤️ using Flutter & Firebase**
