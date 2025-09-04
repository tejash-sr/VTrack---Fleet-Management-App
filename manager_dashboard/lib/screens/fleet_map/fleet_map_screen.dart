import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../services/realtime_service.dart';

class FleetMapScreen extends StatefulWidget {
  const FleetMapScreen({super.key});

  @override
  State<FleetMapScreen> createState() => _FleetMapScreenState();
}

class _FleetMapScreenState extends State<FleetMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _center;
  
  @override
  void initState() {
    super.initState();
    _center = const LatLng(40.7128, -74.0060); // Default to NYC
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Map'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final firestoreService = Provider.of<FirestoreService>(context, listen: false);
              firestoreService.loadDrivers();
            },
          ),
        ],
      ),
      body: Consumer2<FirestoreService, RealtimeService>(
        builder: (context, firestoreService, realtimeService, child) {
          return Stack(
            children: [
              // Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center ?? const LatLng(20.5937, 78.9629), // Default to India center
                  initialZoom: 10.0,
                ),
                children: [
                  // OpenStreetMap tiles
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.fleetmanagement.manager',
                  ),
                  
                  // Driver markers
                  MarkerLayer(
                    markers: _buildDriverMarkers(firestoreService, realtimeService),
                  ),
                ],
              ),
              
              // Fleet status panel
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Fleet Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildStatusIndicator('Online', Colors.green, 
                                firestoreService.drivers.where((d) => d['status'] == 'online').length),
                            const SizedBox(width: 16),
                            _buildStatusIndicator('Busy', Colors.orange, 
                                firestoreService.drivers.where((d) => d['status'] == 'busy').length),
                            const SizedBox(width: 16),
                            _buildStatusIndicator('Offline', Colors.grey, 
                                firestoreService.drivers.where((d) => d['status'] == 'offline').length),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // SOS alerts panel
              if (realtimeService.sosAlerts.isNotEmpty)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red[700]),
                              const SizedBox(width: 8),
                              Text(
                                'SOS Alerts (${realtimeService.sosAlerts.length})',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...realtimeService.sosAlerts.values.take(3).map((alert) => 
                            _buildSOSAlertItem(alert)
                          ).toList(),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
  
  List<Marker> _buildDriverMarkers(FirestoreService firestoreService, RealtimeService realtimeService) {
    final markers = <Marker>[];
    
    for (final driver in firestoreService.drivers) {
      final driverId = driver['id'];
      final realtimeLocation = realtimeService.fleetLocations[driverId];
      
      if (realtimeLocation != null) {
        final lat = realtimeLocation['latitude'] as double?;
        final lng = realtimeLocation['longitude'] as double?;
        
        if (lat != null && lng != null) {
          final status = driver['status'] as String? ?? 'offline';
          final color = _getStatusColor(status);
          
          markers.add(
            Marker(
              point: LatLng(lat, lng),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _showDriverInfo(driver, realtimeLocation),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          );
        }
      }
    }
    
    return markers;
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'online':
        return Colors.green;
      case 'busy':
        return Colors.orange;
      case 'offline':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
  
  Widget _buildStatusIndicator(String label, Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text('$count $label'),
      ],
    );
  }
  
  Widget _buildSOSAlertItem(Map<String, dynamic> alert) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.warning, size: 16, color: Colors.red[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              alert['message'] ?? 'SOS Alert',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showDriverInfo(Map<String, dynamic> driver, Map<String, dynamic> location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(driver['name'] ?? 'Driver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone: ${driver['phone'] ?? 'N/A'}'),
            Text('Status: ${driver['status'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Location:'),
            Text('Lat: ${location['latitude']?.toStringAsFixed(6) ?? 'N/A'}'),
            Text('Lng: ${location['longitude']?.toStringAsFixed(6) ?? 'N/A'}'),
            if (location['timestamp'] != null)
              Text('Last Update: ${_formatTimestamp(location['timestamp'])}'),
          ],
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
  
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }
}
