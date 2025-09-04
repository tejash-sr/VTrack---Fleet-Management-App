import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';

import '../../services/firestore_service.dart';
import '../../services/excel_export_service.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportExpenses(context),
          ),
        ],
      ),
      body: Consumer<FirestoreService>(
        builder: (context, firestoreService, child) {
          if (firestoreService.expenses.isEmpty) {
            return const Center(
              child: Text('No expenses found'),
            );
          }

          return DataTable2(
            columnSpacing: 12,
            horizontalMargin: 12,
            minWidth: 800,
            columns: const [
              DataColumn2(
                label: Text('Date'),
                size: ColumnSize.M,
              ),
              DataColumn2(
                label: Text('Driver ID'),
                size: ColumnSize.S,
              ),
              DataColumn2(
                label: Text('Trip ID'),
                size: ColumnSize.S,
              ),
              DataColumn2(
                label: Text('Amount'),
                size: ColumnSize.S,
              ),
              DataColumn2(
                label: Text('Description'),
                size: ColumnSize.L,
              ),
              DataColumn2(
                label: Text('Category'),
                size: ColumnSize.S,
              ),
              DataColumn2(
                label: Text('Photo'),
                size: ColumnSize.S,
              ),
            ],
            rows: firestoreService.expenses.map((expense) {
              return DataRow2(
                cells: [
                  DataCell(Text(_formatTimestamp(expense['timestamp']))),
                  DataCell(Text(expense['driverId'] ?? '')),
                  DataCell(Text(expense['tripId'] ?? '')),
                  DataCell(Text('\$${(expense['amount'] ?? 0.0).toStringAsFixed(2)}')),
                  DataCell(Text(expense['description'] ?? '')),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(expense['category']),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        expense['category'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    expense['photoURL'] != null
                        ? IconButton(
                            icon: const Icon(Icons.image),
                            onPressed: () => _showPhoto(expense['photoURL']),
                          )
                        : const Icon(Icons.no_photography, color: Colors.grey),
                  ),
                ],
                onTap: () => _showExpenseDetails(expense),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'fuel':
        return Colors.orange;
      case 'maintenance':
        return Colors.blue;
      case 'tolls':
        return Colors.green;
      case 'parking':
        return Colors.purple;
      case 'food':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      // Handle error
    }
    
    return 'N/A';
  }

  void _showExpenseDetails(Map<String, dynamic> expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Expense Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Driver ID', expense['driverId'] ?? 'N/A'),
              _buildDetailRow('Trip ID', expense['tripId'] ?? 'N/A'),
              _buildDetailRow('Amount', '\$${(expense['amount'] ?? 0.0).toStringAsFixed(2)}'),
              _buildDetailRow('Description', expense['description'] ?? 'N/A'),
              _buildDetailRow('Category', expense['category'] ?? 'N/A'),
              _buildDetailRow('Date', _formatTimestamp(expense['timestamp'])),
              if (expense['photoURL'] != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Receipt Photo:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Image.network(
                  expense['photoURL'],
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error, size: 50);
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showPhoto(String photoURL) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Receipt Photo'),
        content: Image.network(
          photoURL,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.error, size: 100);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportExpenses(BuildContext context) async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    try {
      final filePath = await ExcelExportService.exportFleetReport();
      
      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expenses exported to: $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export expenses'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
