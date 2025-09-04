import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class RealtimeService extends ChangeNotifier {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  DatabaseReference? _fleetLocationsRef;
  DatabaseReference? _sosAlertsRef;
  Stream<DatabaseEvent>? _fleetLocationsStream;
  Stream<DatabaseEvent>? _sosAlertsStream;
  
  Map<String, Map<String, dynamic>> _fleetLocations = {};
  Map<String, Map<String, dynamic>> _sosAlerts = {};
  
  Map<String, Map<String, dynamic>> get fleetLocations => _fleetLocations;
  Map<String, Map<String, dynamic>> get sosAlerts => _sosAlerts;
  
  // Listen to fleet locations
  void startListeningToFleetLocations() {
    _fleetLocationsRef = _database.ref('fleet_locations');
    _fleetLocationsStream = _fleetLocationsRef!.onValue;
    
    _fleetLocationsStream!.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        _fleetLocations = Map<String, Map<String, dynamic>>.from(
          data.map((key, value) => MapEntry(
            key.toString(),
            Map<String, dynamic>.from(value as Map<dynamic, dynamic>),
          )),
        );
        notifyListeners();
      }
    });
  }
  
  // Listen to SOS alerts
  void startListeningToSOSAlerts() {
    _sosAlertsRef = _database.ref('sos_alerts');
    _sosAlertsStream = _sosAlertsRef!.onValue;
    
    _sosAlertsStream!.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        _sosAlerts = Map<String, Map<String, dynamic>>.from(
          data.map((key, value) => MapEntry(
            key.toString(),
            Map<String, dynamic>.from(value as Map<dynamic, dynamic>),
          )),
        );
        notifyListeners();
      }
    });
  }
  
  // Send SOS alert to realtime database
  Future<void> sendSOSAlert({
    required String driverId,
    required double latitude,
    required double longitude,
    String message = 'SOS - Driver needs help',
  }) async {
    try {
      final alertRef = _database.ref('sos_alerts').push();
      await alertRef.set({
        'driverId': driverId,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        },
        'message': message,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'status': 'active',
      });
    } catch (e) {
      debugPrint('Send SOS alert error: $e');
    }
  }
  
  // Update driver location in realtime database
  Future<void> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
  }) async {
    try {
      await _database.ref('fleet_locations/$driverId').set({
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'accuracy': accuracy ?? 0.0,
        'speed': speed ?? 0.0,
      });
    } catch (e) {
      debugPrint('Update driver location error: $e');
    }
  }
  
  // Get specific driver location
  Future<Map<String, dynamic>?> getDriverLocation(String driverId) async {
    try {
      final snapshot = await _database.ref('fleet_locations/$driverId').get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
      }
    } catch (e) {
      debugPrint('Get driver location error: $e');
    }
    return null;
  }
  
  // Get all active SOS alerts
  Future<List<Map<String, dynamic>>> getActiveSOSAlerts() async {
    try {
      final snapshot = await _database.ref('sos_alerts').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data.entries
            .where((entry) => entry.value['status'] == 'active')
            .map((entry) => {
              'id': entry.key,
              ...Map<String, dynamic>.from(entry.value as Map<dynamic, dynamic>),
            })
            .toList();
      }
    } catch (e) {
      debugPrint('Get active SOS alerts error: $e');
    }
    return [];
  }
  
  // Resolve SOS alert
  Future<void> resolveSOSAlert(String alertId) async {
    try {
      await _database.ref('sos_alerts/$alertId/status').set('resolved');
    } catch (e) {
      debugPrint('Resolve SOS alert error: $e');
    }
  }
  
  // Stop listening to streams
  void stopListening() {
    _fleetLocationsStream = null;
    _sosAlertsStream = null;
    _fleetLocationsRef = null;
    _sosAlertsRef = null;
  }
  
  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
