import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  
  // Trip Management
  String? _currentTripId;
  bool _isTripActive = false;
  
  String? get currentTripId => _currentTripId;
  bool get isTripActive => _isTripActive;
  
  // Start a new trip
  Future<String?> startTrip({
    required String driverId,
    required double latitude,
    required double longitude,
    double? destinationLat,
    double? destinationLng,
    String? destinationName,
  }) async {
    try {
      final tripId = _uuid.v4();
      
      final tripData = {
        'tripId': tripId,
        'driverId': driverId,
        'startTime': FieldValue.serverTimestamp(),
        'startLocation': GeoPoint(latitude, longitude),
        'route': [GeoPoint(latitude, longitude)],
        'status': 'active',
        'totalDistance': 0.0,
        'totalExpenses': 0.0,
      };
      
      // Add destination if provided
      if (destinationLat != null && destinationLng != null) {
        tripData['destination'] = GeoPoint(destinationLat, destinationLng);
        tripData['destinationName'] = destinationName ?? 'Custom Location';
      }
      
      await _firestore.collection('trips').doc(tripId).set(tripData);
      
      // Update driver status
      await _firestore.collection('drivers').doc(driverId).set({
        'status': 'busy',
        'currentTripId': tripId,
        'lastUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      _currentTripId = tripId;
      _isTripActive = true;
      notifyListeners();
      
      return tripId;
    } catch (e) {
      debugPrint('Start trip error: $e');
      return null;
    }
  }
  
  // End current trip
  Future<bool> endTrip({
    required double latitude,
    required double longitude,
    required double totalDistance,
    String? driverId,
  }) async {
    if (_currentTripId == null) return false;
    
    try {
      await _firestore.collection('trips').doc(_currentTripId!).update({
        'endTime': FieldValue.serverTimestamp(),
        'endLocation': GeoPoint(latitude, longitude),
        'status': 'completed',
        'totalDistance': totalDistance,
      });
      
      // Update driver status
      if (driverId != null) {
        await _firestore.collection('drivers').doc(driverId).update({
          'status': 'online',
          'currentTripId': null,
          'lastUpdate': FieldValue.serverTimestamp(),
        });
      }
      
      _currentTripId = null;
      _isTripActive = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('End trip error: $e');
      return false;
    }
  }
  
  // Add location to trip route
  Future<void> addLocationToTrip(double latitude, double longitude) async {
    if (_currentTripId == null) return;
    
    try {
      await _firestore.collection('trips').doc(_currentTripId!).update({
        'route': FieldValue.arrayUnion([GeoPoint(latitude, longitude)]),
      });
    } catch (e) {
      debugPrint('Add location to trip error: $e');
    }
  }
  

  
  // Create SOS alert
  Future<String?> createSOSAlert({
    required String driverId,
    required double latitude,
    required double longitude,
    String message = 'SOS - Driver needs help',
  }) async {
    try {
      final alertId = _uuid.v4();
      
      await _firestore.collection('alerts').doc(alertId).set({
        'alertId': alertId,
        'driverId': driverId,
        'type': 'SOS',
        'location': GeoPoint(latitude, longitude),
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
      });
      
      return alertId;
    } catch (e) {
      debugPrint('Create SOS alert error: $e');
      return null;
    }
  }
  
  // Get trip history
  Future<List<Map<String, dynamic>>> getTripHistory(String driverId) async {
    try {
      final querySnapshot = await _firestore
          .collection('trips')
          .where('driverId', isEqualTo: driverId)
          .orderBy('startTime', descending: true)
          .limit(50)
          .get();
      
      return querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Get trip history error: $e');
      return [];
    }
  }
  
  // Get expenses for a trip
  Future<List<Map<String, dynamic>>> getTripExpenses(String tripId) async {
    try {
      final querySnapshot = await _firestore
          .collection('expenses')
          .where('tripId', isEqualTo: tripId)
          .orderBy('timestamp', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Get trip expenses error: $e');
      return [];
    }
  }
  
  // Add expense
  Future<String?> addExpense({
    required String driverId,
    required double amount,
    required String description,
    required String photoURL,
    required String category,
    String? tripId,
  }) async {
    try {
      final expenseId = _uuid.v4();
      
      await _firestore.collection('expenses').doc(expenseId).set({
        'expenseId': expenseId,
        'driverId': driverId,
        'amount': amount,
        'description': description,
        'photoURL': photoURL,
        'category': category,
        'tripId': tripId ?? _currentTripId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      
      return expenseId;
    } catch (e) {
      debugPrint('Add expense error: $e');
      return null;
    }
  }

  // Get current driver ID (you might want to get this from AuthService)
  Future<String?> _getCurrentDriverId() async {
    // This should be implemented based on your auth service
    // For now, returning null - you'll need to integrate with AuthService
    return null;
  }
  
  // Set current driver ID (call this when user logs in)
  void setCurrentDriverId(String driverId) {
    // This method can be used to set the current driver ID
    // when the user logs in
  }
  
  // Load current trip if exists
  Future<void> loadCurrentTrip(String driverId) async {
    try {
      final querySnapshot = await _firestore
          .collection('trips')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final trip = querySnapshot.docs.first;
        _currentTripId = trip.id;
        _isTripActive = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Load current trip error: $e');
    }
  }
}
