import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Map<String, dynamic>> _drivers = [];
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _alerts = [];
  
  List<Map<String, dynamic>> get drivers => _drivers;
  List<Map<String, dynamic>> get trips => _trips;
  List<Map<String, dynamic>> get expenses => _expenses;
  List<Map<String, dynamic>> get alerts => _alerts;
  
  // Load all drivers
  Future<void> loadDrivers() async {
    try {
      final querySnapshot = await _firestore
          .collection('drivers')
          .orderBy('lastUpdate', descending: true)
          .get();
      
      _drivers = querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Load drivers error: $e');
    }
  }
  
  // Load all trips
  Future<void> loadTrips() async {
    try {
      final querySnapshot = await _firestore
          .collection('trips')
          .orderBy('startTime', descending: true)
          .limit(100)
          .get();
      
      _trips = querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Load trips error: $e');
    }
  }
  
  // Load all expenses
  Future<void> loadExpenses() async {
    try {
      final querySnapshot = await _firestore
          .collection('expenses')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();
      
      _expenses = querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Load expenses error: $e');
    }
  }
  
  // Load all alerts
  Future<void> loadAlerts() async {
    try {
      final querySnapshot = await _firestore
          .collection('alerts')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      
      _alerts = querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Load alerts error: $e');
    }
  }
  
  // Get driver by ID
  Future<Map<String, dynamic>?> getDriver(String driverId) async {
    try {
      final doc = await _firestore.collection('drivers').doc(driverId).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data()!};
      }
    } catch (e) {
      debugPrint('Get driver error: $e');
    }
    return null;
  }
  
  // Get trip by ID
  Future<Map<String, dynamic>?> getTrip(String tripId) async {
    try {
      final doc = await _firestore.collection('trips').doc(tripId).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data()!};
      }
    } catch (e) {
      debugPrint('Get trip error: $e');
    }
    return null;
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
    }
    return [];
  }
  
  // Resolve alert
  Future<void> resolveAlert(String alertId) async {
    try {
      await _firestore.collection('alerts').doc(alertId).update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      
      // Reload alerts
      await loadAlerts();
    } catch (e) {
      debugPrint('Resolve alert error: $e');
    }
  }
  
  // Get fleet statistics
  Future<Map<String, dynamic>> getFleetStatistics() async {
    try {
      final driversSnapshot = await _firestore.collection('drivers').get();
      final tripsSnapshot = await _firestore
          .collection('trips')
          .where('startTime', isGreaterThan: DateTime.now().subtract(const Duration(days: 30)))
          .get();
      final expensesSnapshot = await _firestore
          .collection('expenses')
          .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(days: 30)))
          .get();
      final alertsSnapshot = await _firestore
          .collection('alerts')
          .where('status', isEqualTo: 'active')
          .get();
      
      double totalExpenses = 0.0;
      double totalDistance = 0.0;
      
      for (var expense in expensesSnapshot.docs) {
        totalExpenses += (expense.data()['amount'] ?? 0.0).toDouble();
      }
      
      for (var trip in tripsSnapshot.docs) {
        totalDistance += (trip.data()['totalDistance'] ?? 0.0).toDouble();
      }
      
      return {
        'totalDrivers': driversSnapshot.docs.length,
        'activeDrivers': driversSnapshot.docs.where((doc) => 
          doc.data()['status'] == 'online' || doc.data()['status'] == 'busy').length,
        'totalTrips': tripsSnapshot.docs.length,
        'totalExpenses': totalExpenses,
        'totalDistance': totalDistance,
        'activeAlerts': alertsSnapshot.docs.length,
      };
    } catch (e) {
      debugPrint('Get fleet statistics error: $e');
      return {};
    }
  }
  
  // Load all data
  Future<void> loadAllData() async {
    await Future.wait([
      loadDrivers(),
      loadTrips(),
      loadExpenses(),
      loadAlerts(),
    ]);
  }
}
