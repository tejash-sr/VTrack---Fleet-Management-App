import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/firestore_service.dart';
import '../trip/trip_screen.dart';
import '../expenses/expenses_screen.dart';
import '../sos/sos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const DashboardTab(),
    const TripTab(),
    const ExpensesTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route),
            label: 'Trip',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final MapController _mapController = MapController();
  
  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
                 title: const Text('Dashboard'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
                 actions: [
           Consumer<AuthService>(
             builder: (context, authService, child) {
               return Row(
                 children: [
                   if (authService.driverData != null)
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                       decoration: BoxDecoration(
                         color: Colors.white.withOpacity(0.2),
                         borderRadius: BorderRadius.circular(20),
                       ),
                       child: Text(
                         'Welcome, ${authService.driverData!['name'] ?? 'Driver'}',
                         style: const TextStyle(
                           fontSize: 14,
                           fontWeight: FontWeight.w500,
                           color: Colors.white,
                         ),
                       ),
                     ),
                   const SizedBox(width: 8),
                   IconButton(
                     icon: const Icon(Icons.logout),
                     onPressed: () async {
                       await authService.signOut();
                       if (!mounted) return;
                       Navigator.pushReplacementNamed(context, '/login');
                     },
                   ),
                 ],
               );
             },
           ),
         ],
      ),
      body: Consumer2<LocationService, FirestoreService>(
        builder: (context, locationService, firestoreService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Status Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Driver Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: firestoreService.isTripActive 
                                    ? Colors.green 
                                    : Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              firestoreService.isTripActive 
                                  ? 'Trip Active' 
                                  : 'Available',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Map Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: locationService.currentPosition != null
                                ? FlutterMap(
                                    mapController: _mapController,
                                    options: MapOptions(
                                      initialCenter: LatLng(
                                        locationService.currentPosition!.latitude,
                                        locationService.currentPosition!.longitude,
                                      ),
                                      initialZoom: 15.0,
                                      minZoom: 5.0,
                                      maxZoom: 18.0,
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.example.fleet_driver_app',
                                        maxZoom: 18,
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: LatLng(
                                              locationService.currentPosition!.latitude,
                                              locationService.currentPosition!.longitude,
                                            ),
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
                                    ],
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.location_off,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Location not available',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (locationService.currentAddress != null)
                          Text(
                            locationService.currentAddress!,
                            style: const TextStyle(fontSize: 14),
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                                 LayoutBuilder(
                   builder: (context, constraints) {
                     if (constraints.maxWidth < 600) {
                       // Mobile layout - buttons stacked
                       return Column(
                         children: [
                           SizedBox(
                             width: double.infinity,
                             child: ElevatedButton.icon(
                               onPressed: () {
                                 Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                     builder: (context) => const TripScreen(),
                                   ),
                                 );
                               },
                               icon: const Icon(Icons.play_arrow),
                               label: const Text('Start Trip'),
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: Colors.green,
                                 foregroundColor: Colors.white,
                                 padding: const EdgeInsets.symmetric(vertical: 16),
                               ),
                             ),
                           ),
                           const SizedBox(height: 16),
                           SizedBox(
                             width: double.infinity,
                             child: ElevatedButton.icon(
                               onPressed: () {
                                 Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                     builder: (context) => const ExpensesScreen(),
                                   ),
                                 );
                               },
                               icon: const Icon(Icons.add),
                               label: const Text('Add Expense'),
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: Colors.blue,
                                 foregroundColor: Colors.white,
                                 padding: const EdgeInsets.symmetric(vertical: 16),
                               ),
                             ),
                           ),
                         ],
                       );
                     } else {
                       // Desktop layout - buttons side by side
                       return Row(
                         children: [
                           Expanded(
                             child: ElevatedButton.icon(
                               onPressed: () {
                                 Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                     builder: (context) => const TripScreen(),
                                   ),
                                 );
                               },
                               icon: const Icon(Icons.play_arrow),
                               label: const Text('Start Trip'),
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
                               onPressed: () {
                                 Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                     builder: (context) => const ExpensesScreen(),
                                   ),
                                 );
                               },
                               icon: const Icon(Icons.add),
                               label: const Text('Add Expense'),
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: Colors.blue,
                                 foregroundColor: Colors.white,
                                 padding: const EdgeInsets.symmetric(vertical: 16),
                               ),
                             ),
                           ),
                         ],
                       );
                     }
                   },
                 ),
                
                const SizedBox(height: 16),
                
                // SOS Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SOSScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.warning),
                    label: const Text('SOS Alert'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TripTab extends StatelessWidget {
  const TripTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const TripScreen();
  }
}

class ExpensesTab extends StatelessWidget {
  const ExpensesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExpensesScreen();
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                                 // Profile Picture
                 CircleAvatar(
                   radius: 50,
                   backgroundColor: Colors.blue[100],
                   child: Text(
                     authService.driverData?['name']?.substring(0, 1).toUpperCase() ?? 'D',
                     style: const TextStyle(
                       fontSize: 32,
                       fontWeight: FontWeight.bold,
                       color: Colors.blue,
                     ),
                   ),
                 ),
                
                const SizedBox(height: 20),
                
                // Driver Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('Name'),
                          subtitle: Text(authService.driverData?['name'] ?? 'N/A'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.phone),
                          title: const Text('Phone'),
                          subtitle: Text(authService.driverData?['phone'] ?? 'N/A'),
                        ),
                                                 ListTile(
                           leading: const Icon(Icons.info),
                           title: const Text('Status'),
                           subtitle: Row(
                             children: [
                               Container(
                                 width: 8,
                                 height: 8,
                                 decoration: const BoxDecoration(
                                   color: Colors.green,
                                   shape: BoxShape.circle,
                                 ),
                               ),
                               const SizedBox(width: 8),
                               const Text('Online'),
                             ],
                           ),
                         ),
                         ListTile(
                           leading: const Icon(Icons.stars),
                           title: const Text('Points Earned'),
                           subtitle: Text('${authService.driverData?['points'] ?? 0} points'),
                         ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await authService.signOut();
                      if (!mounted) return;
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
