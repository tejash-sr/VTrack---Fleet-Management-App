import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/firestore_service.dart';
import '../../services/realtime_service.dart';
import '../../services/auth_service.dart';
import '../fleet_map/fleet_map_screen.dart';
import '../trip_history/trip_history_screen.dart';
import '../expenses/expenses_screen.dart';
import '../../services/excel_export_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const OverviewTab(),
    const FleetMapTab(),
    const TripHistoryTab(),
    const ExpensesTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final realtimeService = Provider.of<RealtimeService>(context, listen: false);
    
    await firestoreService.loadAllData();
    realtimeService.startListeningToFleetLocations();
    realtimeService.startListeningToSOSAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Manager Dashboard'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          Consumer<AuthService>(
            builder: (context, authService, child) {
              return IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await authService.signOut();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Fleet Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Trip History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Expenses',
          ),
        ],
      ),
    );
  }
}

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<FirestoreService>(
        builder: (context, firestoreService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistics Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Drivers',
                        firestoreService.drivers.length.toString(),
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Active Drivers',
                        firestoreService.drivers
                            .where((d) => d['status'] == 'online' || d['status'] == 'busy')
                            .length
                            .toString(),
                        Icons.person,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Trips',
                        firestoreService.trips.length.toString(),
                        Icons.route,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Active Alerts',
                        firestoreService.alerts
                            .where((a) => a['status'] == 'active')
                            .length
                            .toString(),
                        Icons.warning,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Recent Alerts
                const Text(
                  'Recent Alerts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                ...firestoreService.alerts.take(5).map((alert) => 
                  _buildAlertCard(alert)
                ).toList(),
                
                const SizedBox(height: 24),
                
                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _exportExpenses(context, firestoreService),
                        icon: const Icon(Icons.download),
                        label: const Text('Export Expenses'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _exportTrips(context, firestoreService),
                        icon: const Icon(Icons.download),
                        label: const Text('Export Trips'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAlertCard(Map<String, dynamic> alert) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: alert['status'] == 'active' ? Colors.red : Colors.green,
          child: Icon(
            alert['type'] == 'SOS' ? Icons.warning : Icons.info,
            color: Colors.white,
          ),
        ),
        title: Text(alert['type'] ?? 'Alert'),
        subtitle: Text(alert['message'] ?? ''),
        trailing: Text(
          _formatTimestamp(alert['timestamp']),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }
  
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      // Handle error
    }
    
    return '';
  }
  
  Future<void> _exportExpenses(BuildContext context, FirestoreService firestoreService) async {
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
  
  Future<void> _exportTrips(BuildContext context, FirestoreService firestoreService) async {
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

class FleetMapTab extends StatelessWidget {
  const FleetMapTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const FleetMapScreen();
  }
}

class TripHistoryTab extends StatelessWidget {
  const TripHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const TripHistoryScreen();
  }
}

class ExpensesTab extends StatelessWidget {
  const ExpensesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExpensesScreen();
  }
}
