import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String driverId;
  final String? tripId;
  final double amount;
  final String description;
  final String category;
  final String? photoURL;
  final DateTime timestamp;

  Expense({
    required this.id,
    required this.driverId,
    this.tripId,
    required this.amount,
    required this.description,
    required this.category,
    this.photoURL,
    required this.timestamp,
  });

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      driverId: data['driverId'] ?? '',
      tripId: data['tripId'],
      amount: (data['amount'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      photoURL: data['photoURL'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'tripId': tripId,
      'amount': amount,
      'description': description,
      'category': category,
      'photoURL': photoURL,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
