import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

class StorageService extends ChangeNotifier {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isUploading = false;
  
  bool get isUploading => _isUploading;
  
  // Pick image from camera or gallery
  Future<XFile?> pickImage({ImageSource source = ImageSource.camera}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('Image picker error: $e');
      return null;
    }
  }
  
  // Upload expense photo
  Future<String?> uploadExpensePhoto({
    required String driverId,
    required String expenseId,
    required File imageFile,
  }) async {
    _isUploading = true;
    notifyListeners();
    
    try {
      final ref = _storage
          .ref()
          .child('expenses')
          .child(driverId)
          .child(expenseId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'driverId': driverId,
            'expenseId': expenseId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );
      
      final snapshot = await uploadTask;
      final downloadURL = await snapshot.ref.getDownloadURL();
      
      return downloadURL;
    } catch (e) {
      debugPrint('Upload expense photo error: $e');
      return null;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }
  
  // Upload expense photo (Web)
  Future<String?> uploadExpensePhotoWeb({
    required String driverId,
    required String expenseId,
    required XFile image,
  }) async {
    _isUploading = true;
    notifyListeners();
    
    try {
      // Try Firebase Storage first
      try {
        final ref = _storage
            .ref()
            .child('expenses')
            .child(driverId)
            .child(expenseId)
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        
        final Uint8List bytes = await image.readAsBytes();
        final uploadTask = ref.putData(
          bytes,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'driverId': driverId,
              'expenseId': expenseId,
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          ),
        );
        
        final snapshot = await uploadTask;
        final downloadURL = await snapshot.ref.getDownloadURL();
        
        return downloadURL;
      } catch (storageError) {
        debugPrint('Firebase Storage not available, using base64 fallback: $storageError');
        
        // Fallback: Convert to base64 and store in Firestore
        final Uint8List bytes = await image.readAsBytes();
        final String base64Image = base64Encode(bytes);
        return 'data:image/jpeg;base64,$base64Image';
      }
    } catch (e) {
      debugPrint('Upload expense photo (web) error: $e');
      return null;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }
  
  // Upload profile photo
  Future<String?> uploadProfilePhoto({
    required String driverId,
    required File imageFile,
  }) async {
    _isUploading = true;
    notifyListeners();
    
    try {
      final ref = _storage
          .ref()
          .child('profiles')
          .child(driverId)
          .child('profile.jpg');
      
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'driverId': driverId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );
      
      final snapshot = await uploadTask;
      final downloadURL = await snapshot.ref.getDownloadURL();
      
      return downloadURL;
    } catch (e) {
      debugPrint('Upload profile photo error: $e');
      return null;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }
  
  // Delete photo
  Future<bool> deletePhoto(String photoURL) async {
    try {
      final ref = _storage.refFromURL(photoURL);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Delete photo error: $e');
      return false;
    }
  }
  
  // Get photo metadata
  Future<Map<String, dynamic>?> getPhotoMetadata(String photoURL) async {
    try {
      final ref = _storage.refFromURL(photoURL);
      final metadata = await ref.getMetadata();
      
      return {
        'name': metadata.name,
        'size': metadata.size,
        'contentType': metadata.contentType,
        'timeCreated': metadata.timeCreated,
        'customMetadata': metadata.customMetadata,
      };
    } catch (e) {
      debugPrint('Get photo metadata error: $e');
      return null;
    }
  }
  
  // Upload multiple photos for an expense
  Future<List<String>> uploadMultipleExpensePhotos({
    required String driverId,
    required String expenseId,
    required List<File> imageFiles,
  }) async {
    _isUploading = true;
    notifyListeners();
    
    final List<String> downloadURLs = [];
    
    try {
      for (int i = 0; i < imageFiles.length; i++) {
        final ref = _storage
            .ref()
            .child('expenses')
            .child(driverId)
            .child(expenseId)
            .child('${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        
        final uploadTask = ref.putFile(
          imageFiles[i],
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'driverId': driverId,
              'expenseId': expenseId,
              'uploadedAt': DateTime.now().toIso8601String(),
              'index': i.toString(),
            },
          ),
        );
        
        final snapshot = await uploadTask;
        final downloadURL = await snapshot.ref.getDownloadURL();
        downloadURLs.add(downloadURL);
      }
      
      return downloadURLs;
    } catch (e) {
      debugPrint('Upload multiple photos error: $e');
      return downloadURLs; // Return partial results
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }
}
