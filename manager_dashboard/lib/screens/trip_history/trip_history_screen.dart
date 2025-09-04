import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';

import '../../services/firestore_service.dart';
import '../../services/excel_export_service.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportTrips(context),
          ),
        ],
      ),
      body: Consumer<FirestoreService>(
        builder: (context, firestoreService, child) {
          if (firestoreService.trips.isEmpty) {
            return const Center(
              child: Text('No trips found'),
            );
          }

          return DataTable2(
            columnSpacing: 12,
            horizontalMargin: 12,
            minWidth: 800,
            columns: const [
              DataColumn2(
                label: Text('Trip ID'),
                size: ColumnSize.S,
              ),
              DataColumn2(
                label: Text('Driver ID'),
                size: ColumnSize.S,
              ),
              DataColumn2(
                label: Text('Start Time'),
                size: ColumnSize.M,
              ),
              DataColumn2(
                label: Text('End Time'),
                size: ColumnSize.M,
              ),
              DataColumn2(
                label: Text('Distance'),
                size: ColumnSize.S,
              ),
              DataColumn2(
                label: Text('Expenses'),
                size: ColumnSize.S,
              ),
              DataColumn2(
                label: Text('Status'),
                size: ColumnSize.S,
              ),
            ],
            rows: firestoreService.trips.map((trip) {
              return DataRow2(
                cells: [
                  DataCell(Text(trip['tripId'] ?? '')),
                  DataCell(Text(trip['driverId'] ?? '')),
                  DataCell(Text(_formatTimestamp(trip['startTime']))),
                  DataCell(Text(_formatTimestamp(trip['endTime']))),
                  DataCell(Text('${(trip['totalDistance'] ?? 0.0).toStringAsFixed(2)} km')),
                  DataCell(Text('\$${(trip['totalExpenses'] ?? 0.0).toStringAsFixed(2)}')),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(trip['status']),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        trip['status'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
                onTap: () => _showTripDetails(trip),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
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

  void _showTripDetails(Map<String, dynamic> trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Trip Details - ${trip['tripId']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Driver ID', trip['driverId'] ?? 'N/A'),
              _buildDetailRow('Start Time', _formatTimestamp(trip['startTime'])),
              _buildDetailRow('End Time', _formatTimestamp(trip['endTime'])),
              _buildDetailRow('Distance', '${(trip['totalDistance'] ?? 0.0).toStringAsFixed(2)} km'),
              _buildDetailRow('Total Expenses', '\$${(trip['totalExpenses'] ?? 0.0).toStringAsFixed(2)}'),
              _buildDetailRow('Status', trip['status'] ?? 'N/A'),
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

  Future<void> _exportTrips(BuildContext context) async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    try {
      final filePath = await ExcelExportService.exportFleetReport();
      
      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trips exported to: $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export trips'),
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
