import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import 'dart:async';
import 'package:geocoding/geocoding.dart';
import '../../services/location_service.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class TripScreen extends StatefulWidget {
  const TripScreen({super.key});

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  double _totalDistance = 0.0;
  DateTime? _tripStartTime;
  final TextEditingController _destinationController = TextEditingController();
  LatLng? _destination;
  List<LatLng> _routePoints = [];
  bool _showDestinationInput = false;
  Timer? _timer;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Listen to location updates to track route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationService = Provider.of<LocationService>(context, listen: false);
      locationService.addListener(_onLocationUpdate);
    });
  }

  @override
  void dispose() {
    final locationService = Provider.of<LocationService>(context, listen: false);
    locationService.removeListener(_onLocationUpdate);
    _destinationController.dispose();
    _mapController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _onLocationUpdate() async {
    final locationService = Provider.of<LocationService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (firestoreService.isTripActive && locationService.currentPosition != null) {
      final position = locationService.currentPosition!;
      final newPoint = LatLng(position.latitude, position.longitude);
      
      setState(() {
        if (_routePoints.isEmpty || _routePoints.last != newPoint) {
          _routePoints.add(newPoint);
        }
        
        // Calculate distance if we have multiple points
        if (_routePoints.length > 1) {
          _totalDistance = _calculateTotalDistance();
        }
      });
      
      // Add route point to Firestore
      if (authService.user != null) {
        await locationService.addRoutePoint(authService.user!.uid, position.latitude, position.longitude);
      }
    }
  }

  double _calculateTotalDistance() {
    double total = 0.0;
    for (int i = 0; i < _routePoints.length - 1; i++) {
      total += _calculateDistance(
        _routePoints[i].latitude,
        _routePoints[i].longitude,
        _routePoints[i + 1].latitude,
        _routePoints[i + 1].longitude,
      );
    }
    return total;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        (sin(_degreesToRadians(lat1)) * sin(_degreesToRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2));
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  // Center map on the route between current location and destination
  void _centerMapOnRoute() {
    final locationService = Provider.of<LocationService>(context, listen: false);
    if (locationService.currentPosition != null && _destination != null) {
      final currentLat = locationService.currentPosition!.latitude;
      final currentLng = locationService.currentPosition!.longitude;
      final destLat = _destination!.latitude;
      final destLng = _destination!.longitude;
      
      // Calculate center point
      final centerLat = (currentLat + destLat) / 2;
      final centerLng = (currentLng + destLng) / 2;
      
      // Move map to center
      _mapController.move(LatLng(centerLat, centerLng), 13.0);
    }
  }

  // Search for place and get coordinates
  Future<void> _searchPlace(String query) async {
    if (query.trim().isEmpty) return;
    
    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Searching for location...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        setState(() {
          _destination = LatLng(location.latitude, location.longitude);
        });
        
        // Center map on route
        _centerMapOnRoute();
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Destination set: $query'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location not found: $query'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Get place suggestions with better formatting
  Future<List<Map<String, dynamic>>> _getPlaceSuggestions(String query) async {
    if (query.length < 3) return [];
    
    try {
      List<Location> locations = await locationFromAddress(query);
      List<Map<String, dynamic>> suggestions = [];
      
      for (int i = 0; i < locations.length && i < 5; i++) {
        final location = locations[i];
        try {
          // Get address from coordinates for better display
          List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude, 
            location.longitude
          );
          
          String displayName = query;
          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            displayName = [
              placemark.name,
              placemark.locality,
              placemark.administrativeArea,
              placemark.country
            ].where((e) => e != null && e.isNotEmpty).join(', ');
          }
          
          suggestions.add({
            'name': displayName,
            'location': LatLng(location.latitude, location.longitude),
            'query': query,
          });
        } catch (e) {
          // Fallback to coordinates if address lookup fails
          suggestions.add({
            'name': '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
            'location': LatLng(location.latitude, location.longitude),
            'query': query,
          });
        }
      }
      
      return suggestions;
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Management'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          if (!Provider.of<FirestoreService>(context, listen: false).isTripActive)
            IconButton(
              icon: const Icon(Icons.add_location),
              onPressed: () {
                setState(() {
                  _showDestinationInput = !_showDestinationInput;
                });
              },
              tooltip: 'Add Destination',
            ),
        ],
      ),
      body: Consumer3<LocationService, FirestoreService, AuthService>(
        builder: (context, locationService, firestoreService, authService, child) {
          final currentPosition = locationService.currentPosition;
          final center = currentPosition != null 
              ? LatLng(currentPosition.latitude, currentPosition.longitude)
              : const LatLng(37.7749, -122.4194); // Default to San Francisco

          return Column(
            children: [
              // Map Section
              Expanded(
                flex: firestoreService.isTripActive ? 5 : 3,
                child: Card(
                  margin: const EdgeInsets.all(16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: 15.0,
                        minZoom: 5.0,
                        maxZoom: 18.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.fleet_driver_app',
                        ),
                        
                        // Current Location Marker
                        if (currentPosition != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(currentPosition.latitude, currentPosition.longitude),
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.blue,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        
                        // Destination Marker
                        if (_destination != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _destination!,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.flag,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        
                        // Route Line (from start to destination) - Blue
                        if (_destination != null && currentPosition != null)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: [
                                  LatLng(currentPosition.latitude, currentPosition.longitude),
                                  _destination!,
                                ],
                                strokeWidth: 3,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        
                        // Trip Route Line (actual path taken) - Green
                        if (_routePoints.length > 1)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints,
                                strokeWidth: 2,
                                color: Colors.green,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Destination Input Section
              if (_showDestinationInput && !firestoreService.isTripActive)
                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width > 600 ? 32.0 : 16.0,
                  ),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Set Destination',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _destinationController,
                                      decoration: const InputDecoration(
                                        labelText: 'Destination Name',
                                        hintText: 'e.g., Mumbai Airport, Office',
                                        border: OutlineInputBorder(),
                                        suffixIcon: Icon(Icons.search),
                                      ),
                                      onChanged: (value) {
                                        if (value.length >= 3) {
                                          setState(() {});
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _destinationController.text.isNotEmpty
                                        ? () => _searchPlace(_destinationController.text)
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Search'),
                                  ),
                                ],
                              ),
                              if (_destinationController.text.length >= 3)
                                FutureBuilder<List<Map<String, dynamic>>>(
                                  future: _getPlaceSuggestions(_destinationController.text),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return Container(
                                        margin: const EdgeInsets.only(top: 8),
                                        padding: const EdgeInsets.all(16),
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }
                                    
                                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                      return Container(
                                        margin: const EdgeInsets.only(top: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade300),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.2),
                                              spreadRadius: 1,
                                              blurRadius: 3,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: snapshot.data!.length,
                                          itemBuilder: (context, index) {
                                            final suggestion = snapshot.data![index];
                                            return ListTile(
                                              title: Text(
                                                suggestion['name'],
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                              subtitle: Text(
                                                '${suggestion['location'].latitude.toStringAsFixed(4)}, ${suggestion['location'].longitude.toStringAsFixed(4)}',
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                              leading: const Icon(Icons.location_on, color: Colors.blue, size: 20),
                                              dense: true,
                                              onTap: () {
                                                _destinationController.text = suggestion['name'];
                                                setState(() {
                                                  _destination = suggestion['location'];
                                                });
                                                
                                                // Center map on route
                                                _centerMapOnRoute();
                                                
                                                // Show success message
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Destination set: ${suggestion['name']}'),
                                                    backgroundColor: Colors.green,
                                                    duration: const Duration(seconds: 2),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Type destination name and click search to set location',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _showDestinationInput = false;
                                      _destination = null;
                                      _destinationController.clear();
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _destination != null ? () {
                                    setState(() {
                                      _showDestinationInput = false;
                                    });
                                  } : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Set Destination'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Trip Status Card
              Container(
                margin: EdgeInsets.all(
                  MediaQuery.of(context).size.width > 600 ? 24.0 : 16.0,
                ),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: firestoreService.isTripActive 
                                    ? Colors.green 
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              firestoreService.isTripActive 
                                  ? 'Trip Active' 
                                  : 'No Active Trip',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        
                        if (firestoreService.isTripActive) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Trip ID: ${firestoreService.currentTripId}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          if (_tripStartTime != null) ...[
                            Text(
                              'Started: ${_formatTime(_tripStartTime!)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                          if (_destination != null) ...[
                            Text(
                              'Destination: ${_destinationController.text.isNotEmpty ? _destinationController.text : 'Custom Location'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                        
                        if (locationService.currentAddress != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Current Location: ${locationService.currentAddress}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Trip Statistics
              if (firestoreService.isTripActive) ...[
                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width > 600 ? 24.0 : 16.0,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 400) {
                        // Mobile layout - cards stacked
                        return Column(
                          children: [
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.timer,
                                      color: Colors.blue,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _tripStartTime != null 
                                          ? _formatDuration(DateTime.now().difference(_tripStartTime!))
                                          : '00:00:00',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Duration',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.straighten,
                                      color: Colors.green,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${_totalDistance.toStringAsFixed(1)} km',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Distance',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        // Desktop layout - cards side by side
                        return Row(
                          children: [
                            Expanded(
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.timer,
                                        color: Colors.blue,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _tripStartTime != null 
                                            ? _formatDuration(DateTime.now().difference(_tripStartTime!))
                                            : '00:00:00',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'Duration',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.straighten,
                                        color: Colors.green,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${_totalDistance.toStringAsFixed(1)} km',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'Distance',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ),
              ],

              // Action Buttons
              Container(
                margin: EdgeInsets.all(
                  MediaQuery.of(context).size.width > 600 ? 24.0 : 16.0,
                ),
                child: Column(
                  children: [
                    if (!firestoreService.isTripActive) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: locationService.currentPosition != null 
                              ? () => _startTrip(locationService, firestoreService, authService)
                              : null,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Trip'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: locationService.currentPosition != null 
                              ? () => _endTrip(locationService, firestoreService, authService)
                              : null,
                          icon: const Icon(Icons.stop),
                          label: const Text('End Trip'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Future<void> _startTrip(
    LocationService locationService,
    FirestoreService firestoreService,
    AuthService authService,
  ) async {
    if (authService.user == null) return;
    
    final position = locationService.currentPosition!;
    final tripId = await firestoreService.startTrip(
      driverId: authService.user!.uid,
      latitude: position.latitude,
      longitude: position.longitude,
      destinationLat: _destination?.latitude,
      destinationLng: _destination?.longitude,
      destinationName: _destinationController.text.isNotEmpty ? _destinationController.text : null,
    );
    
    if (!mounted) return;
    
    if (tripId != null) {
      setState(() {
        _tripStartTime = DateTime.now();
        _totalDistance = 0.0;
        _routePoints = [LatLng(position.latitude, position.longitude)];
      });
      
      // Start timer for real-time updates
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {});
        }
      });
      
      // Start location tracking
      await locationService.startLocationTracking(authService.user!.uid);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip started successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start trip'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _endTrip(
    LocationService locationService,
    FirestoreService firestoreService,
    AuthService authService,
  ) async {
    final position = locationService.currentPosition!;
    
    // Stop location tracking
    await locationService.stopLocationTracking();
    
    final success = await firestoreService.endTrip(
      latitude: position.latitude,
      longitude: position.longitude,
      totalDistance: _totalDistance,
      driverId: authService.user?.uid,
    );
    
    if (!mounted) return;
    
    if (success) {
      setState(() {
        _tripStartTime = null;
        _totalDistance = 0.0;
        _routePoints.clear();
        _destination = null;
        _destinationController.clear();
      });
      
      // Stop timer
      _timer?.cancel();
      _timer = null;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip ended successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to end trip'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }
}
