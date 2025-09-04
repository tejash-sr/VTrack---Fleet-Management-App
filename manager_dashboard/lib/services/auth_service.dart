import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  Map<String, dynamic>? _managerData;
  bool _isLoading = false;
  
  User? get user => _user;
  Map<String, dynamic>? get managerData => _managerData;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  
  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }
  
  void _onAuthStateChanged(User? user) {
    _user = user;
    if (user != null) {
      _loadManagerData();
    } else {
      _managerData = null;
    }
    notifyListeners();
  }
  
  Future<void> _loadManagerData() async {
    if (_user == null) return;
    
    try {
      final doc = await _firestore
          .collection('managers')
          .doc(_user!.uid)
          .get();
      
      if (doc.exists) {
        _managerData = doc.data();
      }
    } catch (e) {
      debugPrint('Error loading manager data: $e');
    }
  }
  
  Future<String?> signInWithEmailAndPassword(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create manager document if it doesn't exist
      if (userCredential.user != null) {
        await _createManagerDocument(userCredential.user!);
      }
      
      return null; // Success
    } catch (e) {
      debugPrint('Email sign in error: $e');
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _createManagerDocument(User user) async {
    try {
      final managerRef = _firestore.collection('managers').doc(user.uid);
      final doc = await managerRef.get();
      
      if (!doc.exists) {
        await managerRef.set({
          'name': user.displayName ?? 'Manager',
          'email': user.email,
          'role': 'manager',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        // Update last login
        await managerRef.update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error creating manager document: $e');
    }
  }
  
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }
}
