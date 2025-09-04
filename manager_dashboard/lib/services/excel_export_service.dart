import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ExcelExportService {
  static Future<String> exportFleetReport() async {
    final excel = Excel.createExcel();
    final sheet = excel['Fleet Report'];
    
    // Header
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .value = TextCellValue('Fleet Management Report');
    
    // Summary section
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value = TextCellValue('Total Drivers:');
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        .value = TextCellValue('Active Drivers:');
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6))
        .value = TextCellValue('Total Trips:');
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 8))
        .value = TextCellValue('Total Expenses:');
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 10))
        .value = TextCellValue('Total Distance:');
    
    // Get data from Firestore
    final driversSnapshot = await FirebaseFirestore.instance.collection('drivers').get();
    final tripsSnapshot = await FirebaseFirestore.instance.collection('trips').get();
    final expensesSnapshot = await FirebaseFirestore.instance.collection('expenses').get();
    
    // Calculate totals
    final totalDrivers = driversSnapshot.docs.length;
    final activeDrivers = driversSnapshot.docs.where((doc) => doc.data()['status'] == 'active').length;
    final totalTrips = tripsSnapshot.docs.length;
    final totalExpenses = expensesSnapshot.docs.length;
    
    double totalDistance = 0;
    for (final trip in tripsSnapshot.docs) {
      final data = trip.data();
      if (data['distance'] != null) {
        totalDistance += (data['distance'] as num).toDouble();
      }
    }
    
    // Fill in values
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
        .value = TextCellValue(totalDrivers.toString());
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4))
        .value = TextCellValue(activeDrivers.toString());
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6))
        .value = TextCellValue(totalTrips.toString());
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 8))
        .value = TextCellValue(totalExpenses.toString());
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 10))
        .value = TextCellValue('${totalDistance.toStringAsFixed(2)} km');
    
    // Drivers table
    _addDriversTable(sheet, driversSnapshot.docs, 15);
    
    // Trips table
    _addTripsTable(sheet, tripsSnapshot.docs, 25);
    
    // Expenses table
    _addExpensesTable(sheet, expensesSnapshot.docs, 35);
    
    // Save file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'fleet_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(excel.encode()!);
    
    return file.path;
  }
  
  static void _addDriversTable(Sheet sheet, List<QueryDocumentSnapshot> drivers, int startRow) {
    // Headers
    final headers = ['Driver ID', 'Name', 'Phone', 'Status', 'Vehicle', 'Join Date'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: startRow))
          .value = TextCellValue(headers[i]);
    }
    
    // Data
    for (int i = 0; i < drivers.length; i++) {
      final driver = drivers[i].data() as Map<String, dynamic>;
      final row = startRow + 1 + i;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(drivers[i].id);
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(driver['name'] ?? 'N/A');
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = TextCellValue(driver['phone'] ?? 'N/A');
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = TextCellValue(driver['status'] ?? 'N/A');
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = TextCellValue(driver['vehicle'] ?? 'N/A');
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .value = TextCellValue(_formatTimestamp(driver['joinDate']));
    }
  }
  
  static void _addTripsTable(Sheet sheet, List<QueryDocumentSnapshot> trips, int startRow) {
    // Headers
    final headers = ['Trip ID', 'Driver ID', 'Start Location', 'End Location', 'Distance', 'Duration', 'Status', 'Date'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: startRow))
          .value = TextCellValue(headers[i]);
    }
    
    // Data
    for (int i = 0; i < trips.length; i++) {
      final trip = trips[i].data() as Map<String, dynamic>;
      final row = startRow + 1 + i;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(trips[i].id);
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(trip['driverId'] ?? 'N/A');
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = TextCellValue(_formatLocation(trip['startLocation']));
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = TextCellValue(_formatLocation(trip['endLocation']));
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = TextCellValue('${(trip['distance'] ?? 0.0).toStringAsFixed(2)} km');
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .value = TextCellValue(trip['duration'] ?? 'N/A');
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
          .value = TextCellValue(trip['status'] ?? 'N/A');
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
          .value = TextCellValue(_formatTimestamp(trip['startTime']));
    }
  }
  
  static void _addExpensesTable(Sheet sheet, List<QueryDocumentSnapshot> expenses, int startRow) {
    // Headers
    final headers = ['Expense ID', 'Driver ID', 'Trip ID', 'Amount', 'Description', 'Category', 'Date'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: startRow))
          .value = TextCellValue(headers[i]);
    }
    
    // Data
    for (int i = 0; i < expenses.length; i++) {
      final expense = expenses[i].data() as Map<String, dynamic>;
      final row = startRow + 1 + i;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(expenses[i].id);
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(expense['driverId'] ?? 'N/A');
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = TextCellValue(expense['tripId'] ?? 'N/A');
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = TextCellValue('\$${(expense['amount'] ?? 0.0).toStringAsFixed(2)}');
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = TextCellValue(expense['description'] ?? 'N/A');
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .value = TextCellValue(expense['category'] ?? 'N/A');
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
          .value = TextCellValue(_formatTimestamp(expense['timestamp']));
    }
  }
  
  static String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return DateFormat('dd/MM/yyyy HH:mm').format(date);
      }
    } catch (e) {
      // Handle error
    }
    
    return 'N/A';
  }
  
  static String _formatLocation(dynamic location) {
    if (location == null) return 'N/A';
    
    try {
      if (location is GeoPoint) {
        return '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
      }
    } catch (e) {
      // Handle error
    }
    
    return 'N/A';
  }
}
