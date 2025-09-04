import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  Map<String, dynamic>? _driverData;
  bool _isLoading = false;
  
  User? get user => _user;
  Map<String, dynamic>? get driverData => _driverData;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  
  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }
  
  void _onAuthStateChanged(User? user) {
    _user = user;
    if (user != null) {
      _loadDriverData();
    } else {
      _driverData = null;
    }
    notifyListeners();
  }
  
  Future<void> _loadDriverData() async {
    if (_user == null) return;
    
    try {
      final doc = await _firestore
          .collection('drivers')
          .doc(_user!.uid)
          .get();
      
      if (doc.exists) {
        _driverData = doc.data();
      }
    } catch (e) {
      debugPrint('Error loading driver data: $e');
    }
  }
  
  Future<String?> signUp(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateDisplayName(username);
        
        // Create driver document
        await _createDriverDocument(userCredential.user!, username, email);
      }
      
      return null; // Success
    } catch (e) {
      debugPrint('Sign up error: $e');
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<String?> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        await _loadDriverData();
        // Set driver status to online when signing in
        await updateDriverStatus('online');
      }
      
      return null; // Success
    } catch (e) {
      debugPrint('Sign in error: $e');
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _createDriverDocument(User user, String username, String email) async {
    try {
      final driverRef = _firestore.collection('drivers').doc(user.uid);
      final doc = await driverRef.get();
      
      if (!doc.exists) {
        await driverRef.set({
          'username': username,
          'email': email,
          'name': username,
          'status': 'online',
          'isActive': true,
          'points': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error creating driver document: $e');
    }
  }
  
  Future<void> updateDriverStatus(String status) async {
    if (_user == null) return;
    
    try {
      await _firestore.collection('drivers').doc(_user!.uid).update({
        'status': status,
        'lastUpdate': FieldValue.serverTimestamp(),
      });
      
      if (_driverData != null) {
        _driverData!['status'] = status;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating driver status: $e');
    }
  }

  Future<void> updateDriverPoints(int points) async {
    if (_user == null) return;
    
    try {
      await _firestore.collection('drivers').doc(_user!.uid).update({
        'points': points,
        'lastUpdate': FieldValue.serverTimestamp(),
      });
      
      if (_driverData != null) {
        _driverData!['points'] = points;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating driver points: $e');
    }
  }
  
  Future<void> signOut() async {
    try {
      await updateDriverStatus('offline');
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }
}
