import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/firestore_service.dart';
import 'services/storage_service.dart';
import 'services/realtime_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  
  runApp(const FleetDriverApp());
}

class FleetDriverApp extends StatelessWidget {
  const FleetDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => FirestoreService()),
        ChangeNotifierProvider(create: (_) => StorageService()),
        ChangeNotifierProvider(create: (_) => RealtimeService()),
      ],
      child: MaterialApp(
        title: 'VTrack Fleet Driver',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          // Responsive design
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const ResponsiveWrapper(
          child: SplashScreen(),
        ),
        routes: {
          '/login': (context) => const ResponsiveWrapper(child: LoginScreen()),
          '/home': (context) => const ResponsiveWrapper(child: HomeScreen()),
        },
      ),
    );
  }
}

// Responsive wrapper for different screen sizes
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  
  const ResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: MediaQuery.of(context).size.width > 1200 ? 1.2 : 1.0,
      ),
      child: child,
    );
  }
}
