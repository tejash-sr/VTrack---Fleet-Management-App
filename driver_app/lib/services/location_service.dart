import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class LocationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  Position? _currentPosition;
  String? _currentAddress;
  bool _isTracking = false;
  bool _isLoading = false;
  Stream<Position>? _positionStream;
  
  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  bool get isTracking => _isTracking;
  bool get isLoading => _isLoading;
  
  LocationService() {
    _initializeLocation();
  }
  
  Future<void> _initializeLocation() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          _isLoading = false;
          notifyListeners();
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied forever');
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      // Get address
      await _getAddressFromPosition(_currentPosition!);
      
    } catch (e) {
      debugPrint('Location initialization error: $e');
      // For web, try to get a mock location for testing
      if (kIsWeb) {
        _currentPosition = Position(
          latitude: 37.7749, // San Francisco coordinates for testing
          longitude: -122.4194,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        _currentAddress = 'San Francisco, CA (Test Location)';
      } else {
        // For mobile, set a default message
        _currentAddress = 'Location not available';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _getAddressFromPosition(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        final street = place.street ?? '';
        final locality = place.locality ?? '';
        final administrativeArea = place.administrativeArea ?? '';
        
        if (street.isNotEmpty || locality.isNotEmpty || administrativeArea.isNotEmpty) {
          _currentAddress = '${street.isNotEmpty ? '$street, ' : ''}${locality.isNotEmpty ? '$locality, ' : ''}$administrativeArea'.trim();
          if (_currentAddress!.endsWith(',')) {
            _currentAddress = _currentAddress!.substring(0, _currentAddress!.length - 1);
          }
        } else {
          _currentAddress = 'Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        }
      } else {
        _currentAddress = 'Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }
    } catch (e) {
      debugPrint('Address lookup error: $e');
      // Fallback to coordinates if address lookup fails
      _currentAddress = 'Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    }
  }
  
  Future<void> startLocationTracking(String driverId) async {
    if (_isTracking) return;
    
    _isTracking = true;
    notifyListeners();
    
    try {
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      );
      
      _positionStream!.listen((Position position) {
        _currentPosition = position;
        _updateLocationInFirebase(driverId, position);
        
        // Update address periodically
        if (_currentPosition != null) {
          _getAddressFromPosition(_currentPosition!);
        }
        
        notifyListeners();
      });
      
    } catch (e) {
      debugPrint('Location tracking error: $e');
      _isTracking = false;
      notifyListeners();
    }
  }

  // Add route point to current trip
  Future<void> addRoutePoint(String driverId, double latitude, double longitude) async {
    try {
      await _firestore.collection('trips')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get()
          .then((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          final tripDoc = querySnapshot.docs.first;
          tripDoc.reference.update({
            'route': FieldValue.arrayUnion([GeoPoint(latitude, longitude)]),
          });
        }
      });
    } catch (e) {
      debugPrint('Add route point error: $e');
    }
  }
  
  Future<void> stopLocationTracking() async {
    _isTracking = false;
    _positionStream = null;
    notifyListeners();
  }
  
  Future<void> _updateLocationInFirebase(String driverId, Position position) async {
    try {
      // Update Firestore
      await _firestore.collection('drivers').doc(driverId).update({
        'lastLocation': GeoPoint(position.latitude, position.longitude),
        'lastUpdate': FieldValue.serverTimestamp(),
      });
      
      // Update Realtime Database for real-time tracking
      await _database.ref('fleet_locations/$driverId').set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'accuracy': position.accuracy,
        'speed': position.speed,
      });
      
    } catch (e) {
      debugPrint('Firebase location update error: $e');
    }
  }
  
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Get current position error: $e');
      return null;
    }
  }
  
  Future<double> calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
  
  Future<void> updateLocation() async {
    try {
      _currentPosition = await getCurrentPosition();
      if (_currentPosition != null) {
        await _getAddressFromPosition(_currentPosition!);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Update location error: $e');
    }
  }
}
